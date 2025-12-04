/*******************************************************************************
 * Stored Procedure: dbo.EFA_ProcessOne
 * Descriere: Procesează o singură factură prin toate etapele (GENERARE → COMPLETED)
 * Data: 2025-12-04
 * Versiune: 1.0
 *
 * Parametri:
 *   @db_name - Numele bazei de date
 *   @table_name - Numele tabelei (Iesiri sau Export)
 *   @id_unic - ID-ul facturii (Nir)
 *   @run_id - ID unic de rulare
 *   @efagent_path - Calea către EFAgent.exe
 *   @conn_string - Connection string pentru baza de date
 *   @environment - Mediu ANAF (prod sau test)
 ******************************************************************************/

USE [master]
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[EFA_ProcessOne]') AND type = 'P')
    DROP PROCEDURE [dbo].[EFA_ProcessOne]
GO

CREATE PROCEDURE [dbo].[EFA_ProcessOne]
    @db_name SYSNAME,
    @table_name SYSNAME,
    @id_unic NVARCHAR(50),
    @run_id UNIQUEIDENTIFIER,
    @efagent_path NVARCHAR(500) = 'C:\EFAgent\EFAgent.exe',
    @conn_string NVARCHAR(1000),
    @environment NVARCHAR(10) = 'prod'
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE @cmd NVARCHAR(MAX)
    DECLARE @json_out NVARCHAR(MAX)
    DECLARE @exit_code INT
    DECLARE @current_stare NVARCHAR(20)
    DECLARE @attempt_count INT
    DECLARE @max_attempts INT = 3
    DECLARE @backoff_seconds INT
    DECLARE @sql NVARCHAR(MAX)
    DECLARE @params NVARCHAR(MAX)
    DECLARE @success BIT
    DECLARE @id_descarcare CHAR(10)
    
    BEGIN TRY
        -- 1. LOCK DOCUMENT (Optimistic Locking)
        SET @sql = N'
            UPDATE [' + @db_name + N'].[dbo].[' + @table_name + N']
            SET efact_Stare = ''IN_PROGRES'',
                efact_Processing_Host = HOST_NAME(),
                efact_Processing_Time = SYSUTCDATETIME(),
                efact_Attempt_Count = ISNULL(efact_Attempt_Count, 0) + 1
            WHERE Nir = @id_unic
              AND (efact_Stare IS NULL 
                   OR efact_Stare = ''PENDING''
                   OR (efact_Stare = ''IN_PROGRES'' 
                       AND DATEDIFF(HOUR, efact_Processing_Time, SYSUTCDATETIME()) > 1)
                   OR efact_Stare IN (''GENERATA'', ''TRANSMISA'', ''IN_ASTEPTARE_STATUS'', ''DESCARCARE_READY'')
              )'
        
        SET @params = N'@id_unic NVARCHAR(50)'
        EXEC sp_executesql @sql, @params, @id_unic = @id_unic
        
        IF @@ROWCOUNT = 0
        BEGIN
            -- Document deja procesat sau locked de alt proces
            EXEC dbo.EFA_LogMessage
                @db_name = @db_name,
                @table_name = @table_name,
                @id_unic = @id_unic,
                @step = 'SCANARE',
                @action = 'SKIP',
                @message_short = 'Document deja în procesare sau finalizat',
                @status = 'OK',
                @run_id = @run_id
            
            RETURN 0
        END
        
        -- Obține stare curentă și număr de încercări
        SET @sql = N'
            SELECT @current_stare = efact_Stare, 
                   @attempt_count = efact_Attempt_Count,
                   @id_descarcare = Id_Descarcare
            FROM [' + @db_name + N'].[dbo].[' + @table_name + N']
            WHERE Nir = @id_unic'
        
        SET @params = N'@id_unic NVARCHAR(50), @current_stare NVARCHAR(20) OUTPUT, 
                        @attempt_count INT OUTPUT, @id_descarcare CHAR(10) OUTPUT'
        EXEC sp_executesql @sql, @params, 
            @id_unic = @id_unic, 
            @current_stare = @current_stare OUTPUT,
            @attempt_count = @attempt_count OUTPUT,
            @id_descarcare = @id_descarcare OUTPUT
        
        EXEC dbo.EFA_LogMessage
            @db_name = @db_name,
            @table_name = @table_name,
            @id_unic = @id_unic,
            @step = 'SCANARE',
            @action = 'LOCK_ACQUIRED',
            @message_short = 'Document locked pentru procesare, stare=' + ISNULL(@current_stare, 'NULL'),
            @status = 'OK',
            @attempt_no = @attempt_count,
            @run_id = @run_id
        
        -- 2. GENERARE XML (dacă nu e deja generat)
        IF @current_stare NOT IN ('GENERATA', 'TRANSMISA', 'ACCEPTATA', 'COMPLETED')
        BEGIN
            SET @cmd = '"' + @efagent_path + '" generate '
            SET @cmd = @cmd + '--db="' + @db_name + '" '
            SET @cmd = @cmd + '--table="' + @table_name + '" '
            SET @cmd = @cmd + '--id="' + @id_unic + '" '
            SET @cmd = @cmd + '--connString="' + @conn_string + '" '
            SET @cmd = @cmd + '--env=' + @environment + ' '
            SET @cmd = @cmd + '--out-json'
            
            EXEC dbo.EFA_InvokeAgent @cmd, @json_out OUTPUT, @exit_code OUTPUT
            
            IF @exit_code = 0
            BEGIN
                EXEC dbo.EFA_UpdateFromResponse 
                    @db_name = @db_name,
                    @table_name = @table_name,
                    @id_unic = @id_unic,
                    @json = @json_out,
                    @step = 'GENERARE',
                    @run_id = @run_id
                
                -- Verifică dacă generarea a reușit (SQL Server 2012 compatible)
                SELECT @success = CASE WHEN dbo.EFA_ParseJsonValue(@json_out, 'ok') = 'true' THEN 1 ELSE 0 END
                
                IF @success = 0
                BEGIN
                    PRINT 'Eroare la generare XML pentru ' + @id_unic
                    RETURN -1
                END
            END
            ELSE
            BEGIN
                PRINT 'Eroare invocare EFAgent generate pentru ' + @id_unic
                RETURN -1
            END
            
            SET @current_stare = 'GENERATA'
        END
        
        -- 3. TRANSMITERE (dacă nu e deja transmis)
        IF @current_stare NOT IN ('TRANSMISA', 'ACCEPTATA', 'COMPLETED')
        BEGIN
            SET @cmd = '"' + @efagent_path + '" upload '
            SET @cmd = @cmd + '--db="' + @db_name + '" '
            SET @cmd = @cmd + '--table="' + @table_name + '" '
            SET @cmd = @cmd + '--id="' + @id_unic + '" '
            SET @cmd = @cmd + '--connString="' + @conn_string + '" '
            SET @cmd = @cmd + '--env=' + @environment + ' '
            SET @cmd = @cmd + '--out-json'
            
            EXEC dbo.EFA_InvokeAgent @cmd, @json_out OUTPUT, @exit_code OUTPUT
            
            IF @exit_code = 0
            BEGIN
                EXEC dbo.EFA_UpdateFromResponse 
                    @db_name = @db_name,
                    @table_name = @table_name,
                    @id_unic = @id_unic,
                    @json = @json_out,
                    @step = 'TRANSMITERE',
                    @run_id = @run_id
                
                SELECT @success = CASE WHEN dbo.EFA_ParseJsonValue(@json_out, 'ok') = 'true' THEN 1 ELSE 0 END
                SELECT @id_descarcare = dbo.EFA_ParseJsonValue(@json_out, 'id_descarcare')
                
                IF @success = 0
                BEGIN
                    PRINT 'Eroare la transmitere pentru ' + @id_unic
                    RETURN -1
                END
            END
            ELSE
            BEGIN
                PRINT 'Eroare invocare EFAgent upload pentru ' + @id_unic
                RETURN -1
            END
            
            SET @current_stare = 'TRANSMISA'
        END
        
        -- 4. VERIFICARE STATUS (dacă avem Id_Descarcare)
        IF @current_stare IN ('TRANSMISA', 'IN_ASTEPTARE_STATUS') AND @id_descarcare IS NOT NULL
        BEGIN
            SET @cmd = '"' + @efagent_path + '" status '
            SET @cmd = @cmd + '--db="' + @db_name + '" '
            SET @cmd = @cmd + '--table="' + @table_name + '" '
            SET @cmd = @cmd + '--id="' + @id_unic + '" '
            SET @cmd = @cmd + '--id_descarcare="' + @id_descarcare + '" '
            SET @cmd = @cmd + '--env=' + @environment + ' '
            SET @cmd = @cmd + '--out-json'
            
            EXEC dbo.EFA_InvokeAgent @cmd, @json_out OUTPUT, @exit_code OUTPUT
            
            IF @exit_code = 0
            BEGIN
                EXEC dbo.EFA_UpdateFromResponse 
                    @db_name = @db_name,
                    @table_name = @table_name,
                    @id_unic = @id_unic,
                    @json = @json_out,
                    @step = 'STATUS',
                    @run_id = @run_id
                
                -- Actualizează starea bazată pe răspuns
                SET @sql = N'SELECT @current_stare = efact_Stare 
                            FROM [' + @db_name + N'].[dbo].[' + @table_name + N']
                            WHERE Nir = @id_unic'
                SET @params = N'@id_unic NVARCHAR(50), @current_stare NVARCHAR(20) OUTPUT'
                EXEC sp_executesql @sql, @params, 
                    @id_unic = @id_unic, 
                    @current_stare = @current_stare OUTPUT
            END
        END
        
        -- 5. DESCĂRCARE ZIP (dacă e ACCEPTATA sau DESCARCARE_READY)
        IF @current_stare IN ('ACCEPTATA', 'DESCARCARE_READY') AND @id_descarcare IS NOT NULL
        BEGIN
            SET @cmd = '"' + @efagent_path + '" download '
            SET @cmd = @cmd + '--db="' + @db_name + '" '
            SET @cmd = @cmd + '--table="' + @table_name + '" '
            SET @cmd = @cmd + '--id="' + @id_unic + '" '
            SET @cmd = @cmd + '--id_descarcare="' + @id_descarcare + '" '
            SET @cmd = @cmd + '--env=' + @environment + ' '
            SET @cmd = @cmd + '--out-json'
            
            EXEC dbo.EFA_InvokeAgent @cmd, @json_out OUTPUT, @exit_code OUTPUT
            
            IF @exit_code = 0
            BEGIN
                EXEC dbo.EFA_UpdateFromResponse 
                    @db_name = @db_name,
                    @table_name = @table_name,
                    @id_unic = @id_unic,
                    @json = @json_out,
                    @step = 'DESCARCARE',
                    @run_id = @run_id
            END
        END
        
        -- 6. UNLOCK DOCUMENT (chiar dacă nu e finalizat complet)
        SET @sql = N'
            UPDATE [' + @db_name + N'].[dbo].[' + @table_name + N']
            SET efact_Processing_Host = NULL,
                efact_Processing_Time = NULL
            WHERE Nir = @id_unic
              AND efact_Processing_Host = HOST_NAME()'
        
        SET @params = N'@id_unic NVARCHAR(50)'
        EXEC sp_executesql @sql, @params, @id_unic = @id_unic
        
        RETURN 0
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE()
        
        -- Log eroarea
        EXEC dbo.EFA_LogMessage
            @db_name = @db_name,
            @table_name = @table_name,
            @id_unic = @id_unic,
            @step = 'PROCESARE',
            @action = 'EXCEPTION',
            @message_short = @ErrorMessage,
            @status = 'ERR',
            @run_id = @run_id
        
        -- Unlock document
        SET @sql = N'
            UPDATE [' + @db_name + N'].[dbo].[' + @table_name + N']
            SET efact_Processing_Host = NULL,
                efact_Processing_Time = NULL
            WHERE Nir = @id_unic'
        
        SET @params = N'@id_unic NVARCHAR(50)'
        EXEC sp_executesql @sql, @params, @id_unic = @id_unic
        
        PRINT 'Eroare procesare ' + @id_unic + ': ' + @ErrorMessage
        RETURN -1
    END CATCH
END
GO

PRINT 'Procedură dbo.EFA_ProcessOne creată cu succes.'
GO
