/*******************************************************************************
 * Stored Procedure: dbo.EFA_ProcessDb
 * Descriere: Procesează toate facturile din Iesiri și Export pentru o bază
 * Data: 2025-12-04
 * Versiune: 1.0
 ******************************************************************************/

USE [master]
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[EFA_ProcessDb]') AND type = 'P')
    DROP PROCEDURE [dbo].[EFA_ProcessDb]
GO

CREATE PROCEDURE [dbo].[EFA_ProcessDb]
    @db_name SYSNAME,
    @run_id UNIQUEIDENTIFIER,
    @batch_size INT = 100,
    @efagent_path NVARCHAR(500) = 'C:\EFAgent\EFAgent.exe',
    @environment NVARCHAR(10) = 'prod',
    @dry_run BIT = 0
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE @sql NVARCHAR(MAX)
    DECLARE @params NVARCHAR(MAX)
    DECLARE @conn_string NVARCHAR(1000)
    DECLARE @candidate_count INT
    DECLARE @processed_count INT = 0
    
    -- Tabela temporară pentru candidați
    CREATE TABLE #Candidates (
        table_name SYSNAME,
        id_unic NVARCHAR(50),
        DataDoc DATETIME,
        Deadline DATETIME,
        efact_Stare NVARCHAR(20),
        efact_Attempt_Count INT
    )
    
    BEGIN TRY
        -- Construiește connection string
        SET @conn_string = 'Server=' + @@SERVERNAME + ';Database=' + @db_name + ';Trusted_Connection=True;'
        
        EXEC dbo.EFA_LogMessage
            @db_name = @db_name,
            @table_name = 'N/A',
            @id_unic = 'N/A',
            @step = 'SCANARE',
            @action = 'START_DB',
            @message_short = 'Începere procesare bază: ' + @db_name,
            @status = 'OK',
            @run_id = @run_id
        
        -- 1. SELECTARE CANDIDAȚI DIN IESIRI
        SET @sql = N'
            INSERT INTO #Candidates (table_name, id_unic, DataDoc, Deadline, efact_Stare, efact_Attempt_Count)
            SELECT TOP (@batch_size)
                ''Iesiri'' AS table_name,
                Nir AS id_unic,
                DataDoc,
                master.dbo.EFA_CalculateDeadline(DataDoc) AS Deadline,
                efact_Stare,
                ISNULL(efact_Attempt_Count, 0) AS efact_Attempt_Count
            FROM [' + @db_name + N'].[dbo].[Iesiri]
            WHERE Is_EF = 1
              AND (
                  efact_Stare IS NULL
                  OR efact_Stare = ''PENDING''
                  OR efact_Stare = ''GENERATA''
                  OR efact_Stare = ''TRANSMISA''
                  OR efact_Stare = ''IN_ASTEPTARE_STATUS''
                  OR efact_Stare = ''DESCARCARE_READY''
                  OR efact_Stare = ''ACCEPTATA''
                  OR (efact_Stare = ''IN_PROGRES'' 
                      AND DATEDIFF(HOUR, efact_Processing_Time, SYSUTCDATETIME()) > 1)
              )
              AND (Recipisa IS NULL OR efact_Stare != ''COMPLETED'')
              AND ISNULL(efact_Attempt_Count, 0) < 3
            ORDER BY 
                CASE 
                    WHEN DATEDIFF(DAY, DataDoc, GETDATE()) >= 4 THEN 1
                    WHEN DATEDIFF(DAY, DataDoc, GETDATE()) >= 3 THEN 2
                    ELSE 3
                END,
                DataDoc ASC'
        
        SET @params = N'@batch_size INT'
        EXEC sp_executesql @sql, @params, @batch_size = @batch_size
        
        -- 2. SELECTARE CANDIDAȚI DIN EXPORT
        SET @sql = N'
            INSERT INTO #Candidates (table_name, id_unic, DataDoc, Deadline, efact_Stare, efact_Attempt_Count)
            SELECT TOP (@batch_size)
                ''Export'' AS table_name,
                Nir AS id_unic,
                DataDoc,
                master.dbo.EFA_CalculateDeadline(DataDoc) AS Deadline,
                efact_Stare,
                ISNULL(efact_Attempt_Count, 0) AS efact_Attempt_Count
            FROM [' + @db_name + N'].[dbo].[Export]
            WHERE Is_EF = 1
              AND (
                  efact_Stare IS NULL
                  OR efact_Stare = ''PENDING''
                  OR efact_Stare = ''GENERATA''
                  OR efact_Stare = ''TRANSMISA''
                  OR efact_Stare = ''IN_ASTEPTARE_STATUS''
                  OR efact_Stare = ''DESCARCARE_READY''
                  OR efact_Stare = ''ACCEPTATA''
                  OR (efact_Stare = ''IN_PROGRES'' 
                      AND DATEDIFF(HOUR, efact_Processing_Time, SYSUTCDATETIME()) > 1)
              )
              AND (Recipisa IS NULL OR efact_Stare != ''COMPLETED'')
              AND ISNULL(efact_Attempt_Count, 0) < 3
            ORDER BY 
                CASE 
                    WHEN DATEDIFF(DAY, DataDoc, GETDATE()) >= 4 THEN 1
                    WHEN DATEDIFF(DAY, DataDoc, GETDATE()) >= 3 THEN 2
                    ELSE 3
                END,
                DataDoc ASC'
        
        EXEC sp_executesql @sql, @params, @batch_size = @batch_size
        
        -- Numără candidații
        SELECT @candidate_count = COUNT(*) FROM #Candidates
        
        EXEC dbo.EFA_LogMessage
            @db_name = @db_name,
            @table_name = 'N/A',
            @id_unic = 'N/A',
            @step = 'SCANARE',
            @action = 'CANDIDATES',
            @message_short = 'Identificați ' + CAST(@candidate_count AS VARCHAR(10)) + ' candidați pentru procesare',
            @status = 'OK',
            @run_id = @run_id
        
        -- Verificare deadline apropiat
        IF EXISTS (
            SELECT 1 FROM #Candidates 
            WHERE DATEDIFF(HOUR, GETDATE(), Deadline) < 48
        )
        BEGIN
            DECLARE @critical_count INT
            SELECT @critical_count = COUNT(*) 
            FROM #Candidates 
            WHERE DATEDIFF(HOUR, GETDATE(), Deadline) < 48
            
            EXEC dbo.EFA_LogMessage
                @db_name = @db_name,
                @table_name = 'N/A',
                @id_unic = 'N/A',
                @step = 'SCANARE',
                @action = 'DEADLINE_WARNING',
                @message_short = 'ATENȚIE: ' + CAST(@critical_count AS VARCHAR(10)) + ' facturi cu deadline < 48h',
                @status = 'ERR',
                @run_id = @run_id
        END
        
        -- Dry run - doar afișează candidații
        IF @dry_run = 1
        BEGIN
            SELECT * FROM #Candidates
            PRINT 'DRY RUN: Nu se procesează documentele'
            RETURN 0
        END
        
        -- 3. PROCESARE CANDIDAȚI
        DECLARE @current_table SYSNAME
        DECLARE @current_id NVARCHAR(50)
        DECLARE @result INT
        
        DECLARE candidate_cursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT table_name, id_unic
            FROM #Candidates
            ORDER BY 
                CASE 
                    WHEN DATEDIFF(DAY, DataDoc, GETDATE()) >= 4 THEN 1
                    WHEN DATEDIFF(DAY, DataDoc, GETDATE()) >= 3 THEN 2
                    ELSE 3
                END,
                DataDoc ASC
        
        OPEN candidate_cursor
        
        FETCH NEXT FROM candidate_cursor INTO @current_table, @current_id
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Procesează documentul
            EXEC @result = dbo.EFA_ProcessOne
                @db_name = @db_name,
                @table_name = @current_table,
                @id_unic = @current_id,
                @run_id = @run_id,
                @efagent_path = @efagent_path,
                @conn_string = @conn_string,
                @environment = @environment
            
            IF @result = 0
                SET @processed_count = @processed_count + 1
            
            FETCH NEXT FROM candidate_cursor INTO @current_table, @current_id
        END
        
        CLOSE candidate_cursor
        DEALLOCATE candidate_cursor
        
        EXEC dbo.EFA_LogMessage
            @db_name = @db_name,
            @table_name = 'N/A',
            @id_unic = 'N/A',
            @step = 'SCANARE',
            @action = 'END_DB',
            @message_short = 'Finalizare procesare bază: ' + @db_name + ', procesate: ' + CAST(@processed_count AS VARCHAR(10)),
            @status = 'OK',
            @run_id = @run_id
        
        DROP TABLE #Candidates
        RETURN 0
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE()
        
        EXEC dbo.EFA_LogMessage
            @db_name = @db_name,
            @table_name = 'N/A',
            @id_unic = 'N/A',
            @step = 'SCANARE',
            @action = 'ERROR_DB',
            @message_short = @ErrorMessage,
            @status = 'ERR',
            @run_id = @run_id
        
        IF OBJECT_ID('tempdb..#Candidates') IS NOT NULL
            DROP TABLE #Candidates
        
        PRINT 'Eroare procesare bază ' + @db_name + ': ' + @ErrorMessage
        RETURN -1
    END CATCH
END
GO

PRINT 'Procedură dbo.EFA_ProcessDb creată cu succes.'
GO

/*******************************************************************************
 * Stored Procedure: dbo.EFA_ScanAndProcessAll
 * Descriere: Orchestrator principal - scanează toate bazele și procesează facturile
 * Data: 2025-12-04
 * Versiune: 1.0
 ******************************************************************************/

IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[EFA_ScanAndProcessAll]') AND type = 'P')
    DROP PROCEDURE [dbo].[EFA_ScanAndProcessAll]
GO

CREATE PROCEDURE [dbo].[EFA_ScanAndProcessAll]
    @batch_size INT = 100,
    @efagent_path NVARCHAR(500) = 'C:\EFAgent\EFAgent.exe',
    @environment NVARCHAR(10) = 'prod',
    @dry_run BIT = 0,
    @firme_db SYSNAME = 'Firme'
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE @run_id UNIQUEIDENTIFIER = NEWID()
    DECLARE @sql NVARCHAR(MAX)
    DECLARE @params NVARCHAR(MAX)
    DECLARE @db_count INT
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME()
    
    -- Tabela temporară pentru baze active
    CREATE TABLE #ActiveDatabases (
        db_name SYSNAME,
        is_online BIT
    )
    
    BEGIN TRY
        PRINT '========================================='
        PRINT 'EFA Background Processor'
        PRINT 'Run ID: ' + CAST(@run_id AS VARCHAR(50))
        PRINT 'Start: ' + CAST(@start_time AS VARCHAR(30))
        PRINT '========================================='
        
        EXEC dbo.EFA_LogMessage
            @db_name = 'master',
            @table_name = 'N/A',
            @id_unic = 'N/A',
            @step = 'SCANARE',
            @action = 'START_JOB',
            @message_short = 'Început job EFA_Background_Processor',
            @status = 'OK',
            @run_id = @run_id
        
        -- 1. SCANARE BAZE ACTIVE
        SET @sql = N'
            SELECT 
                CAST(Baza AS SYSNAME) AS db_name,
                1 AS is_online
            FROM [' + @firme_db + N'].[dbo].[Soc]
            WHERE Online = 1
              AND Baza IS NOT NULL
              AND LEN(RTRIM(Baza)) > 0
              AND EXISTS (
                  SELECT 1 
                  FROM [' + @firme_db + N'].[dbo].[Configurari].[SystemParameters] sp
                  WHERE sp.sKey = ''Send_Efactura''
                    AND sp.sValue = ''Da''
              )'
        
        -- Verifică dacă baza Firme există
        IF EXISTS (SELECT 1 FROM sys.databases WHERE name = @firme_db)
        BEGIN
            INSERT INTO #ActiveDatabases (db_name, is_online)
            EXEC sp_executesql @sql
        END
        ELSE
        BEGIN
            PRINT 'AVERTISMENT: Baza ' + @firme_db + ' nu există. Se folosește fallback la baze din sys.databases.'
            
            -- Fallback: Toate bazele care au tabela Iesiri
            INSERT INTO #ActiveDatabases (db_name, is_online)
            SELECT name, 1
            FROM sys.databases
            WHERE state = 0 -- ONLINE
              AND name NOT IN ('master', 'tempdb', 'model', 'msdb')
              AND name <> @firme_db
        END
        
        SELECT @db_count = COUNT(*) FROM #ActiveDatabases
        
        PRINT 'Identificate ' + CAST(@db_count AS VARCHAR(10)) + ' baze active pentru procesare'
        
        EXEC dbo.EFA_LogMessage
            @db_name = 'master',
            @table_name = 'N/A',
            @id_unic = 'N/A',
            @step = 'SCANARE',
            @action = 'DB_LIST',
            @message_short = 'Identificate ' + CAST(@db_count AS VARCHAR(10)) + ' baze active',
            @status = 'OK',
            @run_id = @run_id
        
        IF @db_count = 0
        BEGIN
            PRINT 'Nicio bază activă găsită. Job terminat.'
            RETURN 0
        END
        
        -- 2. PROCESARE BAZE
        DECLARE @current_db SYSNAME
        DECLARE @result INT
        
        DECLARE db_cursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT db_name
            FROM #ActiveDatabases
            ORDER BY db_name
        
        OPEN db_cursor
        
        FETCH NEXT FROM db_cursor INTO @current_db
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            PRINT 'Procesare bază: ' + @current_db
            
            EXEC @result = dbo.EFA_ProcessDb
                @db_name = @current_db,
                @run_id = @run_id,
                @batch_size = @batch_size,
                @efagent_path = @efagent_path,
                @environment = @environment,
                @dry_run = @dry_run
            
            FETCH NEXT FROM db_cursor INTO @current_db
        END
        
        CLOSE db_cursor
        DEALLOCATE db_cursor
        
        -- 3. FINALIZARE
        DECLARE @end_time DATETIME2 = SYSUTCDATETIME()
        DECLARE @duration_seconds INT = DATEDIFF(SECOND, @start_time, @end_time)
        
        PRINT '========================================='
        PRINT 'End: ' + CAST(@end_time AS VARCHAR(30))
        PRINT 'Duration: ' + CAST(@duration_seconds AS VARCHAR(10)) + ' seconds'
        PRINT '========================================='
        
        EXEC dbo.EFA_LogMessage
            @db_name = 'master',
            @table_name = 'N/A',
            @id_unic = 'N/A',
            @step = 'SCANARE',
            @action = 'END_JOB',
            @message_short = 'Finalizare job, durată: ' + CAST(@duration_seconds AS VARCHAR(10)) + 's',
            @status = 'OK',
            @run_id = @run_id
        
        DROP TABLE #ActiveDatabases
        RETURN 0
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE()
        
        EXEC dbo.EFA_LogMessage
            @db_name = 'master',
            @table_name = 'N/A',
            @id_unic = 'N/A',
            @step = 'SCANARE',
            @action = 'ERROR_JOB',
            @message_short = @ErrorMessage,
            @status = 'ERR',
            @run_id = @run_id
        
        IF OBJECT_ID('tempdb..#ActiveDatabases') IS NOT NULL
            DROP TABLE #ActiveDatabases
        
        PRINT 'EROARE JOB: ' + @ErrorMessage
        RETURN -1
    END CATCH
END
GO

PRINT 'Procedură dbo.EFA_ScanAndProcessAll creată cu succes.'
GO
