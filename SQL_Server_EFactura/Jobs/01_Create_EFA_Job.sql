/*******************************************************************************
 * SQL Server Agent Job: EFA_Background_Processor
 * Descriere: Job pentru procesare automată RO e-Factura
 * Data: 2025-12-04
 * Versiune: 1.0
 *
 * Acest script creează job-ul SQL Server Agent care rulează periodic
 * pentru a procesa facturile din toate bazele de date active.
 ******************************************************************************/

USE [msdb]
GO

-- 1. Șterge job existent (dacă există)
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'EFA_Background_Processor')
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = N'EFA_Background_Processor', @delete_unused_schedule = 1
    PRINT 'Job existent șters.'
END
GO

-- 2. Creează job nou
BEGIN TRANSACTION

DECLARE @ReturnCode INT = 0
DECLARE @jobId BINARY(16)

-- Adaugă categoria de job (dacă nu există)
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.syscategories WHERE name = N'RO e-Factura' AND category_class = 1)
BEGIN
    EXEC @ReturnCode = msdb.dbo.sp_add_category 
        @class = N'JOB', 
        @type = N'LOCAL', 
        @name = N'RO e-Factura'
    
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
        GOTO QuitWithRollback
END

-- Creează job
EXEC @ReturnCode = msdb.dbo.sp_add_job 
    @job_name = N'EFA_Background_Processor', 
    @enabled = 1, 
    @notify_level_eventlog = 2, 
    @notify_level_email = 2, 
    @notify_level_netsend = 0, 
    @notify_level_page = 0, 
    @delete_level = 0, 
    @description = N'Procesează automat facturile pentru RO e-Factura (ANAF)', 
    @category_name = N'RO e-Factura', 
    @owner_login_name = N'sa', 
    @job_id = @jobId OUTPUT

IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
    GOTO QuitWithRollback

-- 3. Step 1: Enable xp_cmdshell (dacă e necesar)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
    @job_id = @jobId, 
    @step_name = N'Enable xp_cmdshell', 
    @step_id = 1, 
    @cmdexec_success_code = 0, 
    @on_success_action = 3, -- Go to next step
    @on_success_step_id = 0, 
    @on_fail_action = 2, -- Quit with failure
    @on_fail_step_id = 0, 
    @retry_attempts = 0, 
    @retry_interval = 0, 
    @os_run_priority = 0, 
    @subsystem = N'TSQL', 
    @command = N'
-- Verifică dacă xp_cmdshell este activat
DECLARE @xp_enabled INT
SELECT @xp_enabled = CAST(value_in_use AS INT)
FROM sys.configurations
WHERE name = ''xp_cmdshell''

IF @xp_enabled = 0
BEGIN
    EXEC sp_configure ''show advanced options'', 1
    RECONFIGURE
    EXEC sp_configure ''xp_cmdshell'', 1
    RECONFIGURE
    PRINT ''xp_cmdshell activat''
END
ELSE
BEGIN
    PRINT ''xp_cmdshell este deja activat''
END
', 
    @database_name = N'master', 
    @flags = 0

IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
    GOTO QuitWithRollback

-- 4. Step 2: Procesare Facturi
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
    @job_id = @jobId, 
    @step_name = N'Procesare Facturi', 
    @step_id = 2, 
    @cmdexec_success_code = 0, 
    @on_success_action = 3, -- Go to next step
    @on_success_step_id = 0, 
    @on_fail_action = 3, -- Go to next step (cleanup oricum)
    @on_fail_step_id = 0, 
    @retry_attempts = 0, 
    @retry_interval = 0, 
    @os_run_priority = 0, 
    @subsystem = N'TSQL', 
    @command = N'
-- Parametri configurabili
DECLARE @batch_size INT = 100
DECLARE @efagent_path NVARCHAR(500) = ''C:\EFAgent\EFAgent.exe''
DECLARE @environment NVARCHAR(10) = ''prod'' -- sau ''test''
DECLARE @dry_run BIT = 0

-- Execută procesarea
EXEC dbo.EFA_ScanAndProcessAll
    @batch_size = @batch_size,
    @efagent_path = @efagent_path,
    @environment = @environment,
    @dry_run = @dry_run
', 
    @database_name = N'master', 
    @flags = 0

IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
    GOTO QuitWithRollback

-- 5. Step 3: Cleanup și disable xp_cmdshell (opțional)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
    @job_id = @jobId, 
    @step_name = N'Cleanup (optional disable xp_cmdshell)', 
    @step_id = 3, 
    @cmdexec_success_code = 0, 
    @on_success_action = 1, -- Quit with success
    @on_success_step_id = 0, 
    @on_fail_action = 2, -- Quit with failure
    @on_fail_step_id = 0, 
    @retry_attempts = 0, 
    @retry_interval = 0, 
    @os_run_priority = 0, 
    @subsystem = N'TSQL', 
    @command = N'
-- Opțional: Dezactivează xp_cmdshell după procesare
-- NOTĂ: Comentează aceste linii dacă vrei să rămână activat
/*
EXEC sp_configure ''xp_cmdshell'', 0
RECONFIGURE
EXEC sp_configure ''show advanced options'', 0
RECONFIGURE
PRINT ''xp_cmdshell dezactivat''
*/

-- Cleanup: Șterge XML-uri temporare mai vechi de 7 zile
-- (Implementare în viitor dacă e necesar)
PRINT ''Cleanup finalizat''
', 
    @database_name = N'master', 
    @flags = 0

IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
    GOTO QuitWithRollback

-- 6. Setează step de start
EXEC @ReturnCode = msdb.dbo.sp_update_job 
    @job_id = @jobId, 
    @start_step_id = 1

IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
    GOTO QuitWithRollback

-- 7. Creează schedule (la fiecare 5 minute)
DECLARE @schedule_uid UNIQUEIDENTIFIER

EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule 
    @job_id = @jobId, 
    @name = N'Every 5 Minutes', 
    @enabled = 1, 
    @freq_type = 4, -- Daily
    @freq_interval = 1, 
    @freq_subday_type = 4, -- Minutes
    @freq_subday_interval = 5, -- La 5 minute
    @freq_relative_interval = 0, 
    @freq_recurrence_factor = 0, 
    @active_start_date = 20241204, 
    @active_end_date = 99991231, 
    @active_start_time = 0, -- 00:00:00
    @active_end_time = 235959, -- 23:59:59
    @schedule_uid = @schedule_uid OUTPUT

IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
    GOTO QuitWithRollback

-- 8. Setează server țintă
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver 
    @job_id = @jobId, 
    @server_name = N'(local)'

IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
    GOTO QuitWithRollback

COMMIT TRANSACTION

PRINT '========================================='
PRINT 'Job EFA_Background_Processor creat cu succes!'
PRINT 'Schedule: La fiecare 5 minute'
PRINT 'Status: Activat'
PRINT '========================================='
GOTO EndSave

QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
    PRINT 'EROARE: Job nu a putut fi creat.'
    
EndSave:
GO

-- Verificare job creat
SELECT 
    j.name AS JobName,
    j.enabled AS IsEnabled,
    s.name AS ScheduleName,
    CASE s.freq_type
        WHEN 4 THEN 'Daily'
        WHEN 8 THEN 'Weekly'
        ELSE 'Other'
    END AS Frequency,
    'Every ' + CAST(s.freq_subday_interval AS VARCHAR(5)) + ' minutes' AS Interval
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.sysjobschedules js ON j.job_id = js.job_id
INNER JOIN msdb.dbo.sysschedules s ON js.schedule_id = s.schedule_id
WHERE j.name = 'EFA_Background_Processor'
GO

-- Informații pentru rulare manuală
PRINT ''
PRINT 'Pentru a rula job-ul manual:'
PRINT 'EXEC msdb.dbo.sp_start_job @job_name = ''EFA_Background_Processor'''
PRINT ''
PRINT 'Pentru a opri job-ul:'
PRINT 'EXEC msdb.dbo.sp_stop_job @job_name = ''EFA_Background_Processor'''
PRINT ''
PRINT 'Pentru a dezactiva job-ul:'
PRINT 'EXEC msdb.dbo.sp_update_job @job_name = ''EFA_Background_Processor'', @enabled = 0'
GO
