/*******************************************************************************
 * Stored Procedure: dbo.EFA_InvokeAgent
 * Descriere: Invocă EFAgent.exe (Chilkat utility) și capturează răspuns JSON
 * Data: 2025-12-04
 * Versiune: 1.0
 *
 * Parametri:
 *   @cmd - Comanda completă pentru EFAgent.exe
 *   @json_out - OUTPUT: JSON returnat de EFAgent
 *   @exit_code - OUTPUT: Exit code al procesului
 ******************************************************************************/

USE [master]
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[EFA_InvokeAgent]') AND type = 'P')
    DROP PROCEDURE [dbo].[EFA_InvokeAgent]
GO

CREATE PROCEDURE [dbo].[EFA_InvokeAgent]
    @cmd NVARCHAR(MAX),
    @json_out NVARCHAR(MAX) OUTPUT,
    @exit_code INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE @ErrorMessage NVARCHAR(MAX)
    DECLARE @TempTable TABLE (OutputLine NVARCHAR(MAX))
    
    BEGIN TRY
        -- Verificare xp_cmdshell activat
        IF NOT EXISTS (
            SELECT 1 
            FROM sys.configurations 
            WHERE name = 'xp_cmdshell' AND value_in_use = 1
        )
        BEGIN
            SET @ErrorMessage = 'xp_cmdshell nu este activat. Execută: EXEC sp_configure ''xp_cmdshell'', 1; RECONFIGURE;'
            RAISERROR(@ErrorMessage, 16, 1)
            RETURN -1
        END
        
        -- Execută comanda și capturează output
        INSERT INTO @TempTable (OutputLine)
        EXEC xp_cmdshell @cmd
        
        -- Concatenează output-ul (SQL Server 2012 compatible)
        SELECT @json_out = COALESCE(@json_out + CHAR(10), '') + OutputLine
        FROM @TempTable 
        WHERE OutputLine IS NOT NULL
        
        -- Verificare dacă output-ul este JSON valid (SQL Server 2012 compatible)
        -- Încearcă să parseze JSON-ul pentru validare
        DECLARE @json_test NVARCHAR(MAX)
        BEGIN TRY
            -- Test simplu: verifică dacă începe cu { sau [
            IF LEFT(LTRIM(@json_out), 1) NOT IN ('{', '[')
            BEGIN
                SET @ErrorMessage = 'Output-ul nu este JSON valid: ' + ISNULL(LEFT(@json_out, 500), 'NULL')
                RAISERROR(@ErrorMessage, 16, 1)
                SET @exit_code = -2
                RETURN -2
            END
        END TRY
        BEGIN CATCH
            SET @ErrorMessage = 'Output-ul nu este JSON valid: ' + ISNULL(LEFT(@json_out, 500), 'NULL')
            RAISERROR(@ErrorMessage, 16, 1)
            SET @exit_code = -2
            RETURN -2
        END CATCH
        
        SET @exit_code = 0
        RETURN 0
        
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = 'Eroare invocare EFAgent: ' + ERROR_MESSAGE()
        -- SQL Server 2012 compatible JSON string construction
        SET @json_out = '{"error":"' + REPLACE(@ErrorMessage, '"', '\"') + '"}'
        SET @exit_code = ERROR_NUMBER()
        
        PRINT @ErrorMessage
        RETURN @exit_code
    END CATCH
END
GO

PRINT 'Procedură dbo.EFA_InvokeAgent creată cu succes.'
GO

/*******************************************************************************
 * Stored Procedure: dbo.EFA_UpdateFromResponse
 * Descriere: Parsează JSON răspuns de la EFAgent și actualizează tabela
 * Data: 2025-12-04
 * Versiune: 1.0
 *
 * Parametri:
 *   @db_name - Numele bazei de date
 *   @table_name - Numele tabelei (Iesiri sau Export)
 *   @id_unic - ID-ul facturii
 *   @json - JSON răspuns de la EFAgent
 *   @step - Pasul curent (GENERARE, TRANSMITERE, STATUS, DESCARCARE)
 ******************************************************************************/

IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[EFA_UpdateFromResponse]') AND type = 'P')
    DROP PROCEDURE [dbo].[EFA_UpdateFromResponse]
GO

CREATE PROCEDURE [dbo].[EFA_UpdateFromResponse]
    @db_name SYSNAME,
    @table_name SYSNAME,
    @id_unic NVARCHAR(50),
    @json NVARCHAR(MAX),
    @step NVARCHAR(20),
    @run_id UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE @ok BIT
    DECLARE @http_status INT
    DECLARE @anaf_status NVARCHAR(50)
    DECLARE @id_solicitare CHAR(10)
    DECLARE @id_descarcare CHAR(10)
    DECLARE @recipisa CHAR(10)
    DECLARE @message NVARCHAR(500)
    DECLARE @zip_base64 NVARCHAR(MAX)
    DECLARE @new_stare NVARCHAR(20)
    DECLARE @sql NVARCHAR(MAX)
    DECLARE @params NVARCHAR(MAX)
    
    BEGIN TRY
        -- Parse JSON (SQL Server 2012 compatible)
        SELECT 
            @ok = CASE WHEN dbo.EFA_ParseJsonValue(@json, 'ok') = 'true' THEN 1 ELSE 0 END,
            @http_status = CAST(dbo.EFA_ParseJsonValue(@json, 'http_status') AS INT),
            @anaf_status = dbo.EFA_ParseJsonValue(@json, 'anaf_status'),
            @id_solicitare = dbo.EFA_ParseJsonValue(@json, 'id_solicitare'),
            @id_descarcare = dbo.EFA_ParseJsonValue(@json, 'id_descarcare'),
            @recipisa = dbo.EFA_ParseJsonValue(@json, 'recipisa'),
            @message = dbo.EFA_ParseJsonValue(@json, 'message'),
            @zip_base64 = dbo.EFA_ParseJsonValue(@json, 'zip_base64')
        
        -- Determină starea nouă bazată pe step și rezultat
        IF @ok = 1
        BEGIN
            SET @new_stare = CASE @step
                WHEN 'GENERARE' THEN 'GENERATA'
                WHEN 'TRANSMITERE' THEN 'TRANSMISA'
                WHEN 'STATUS' THEN 
                    CASE 
                        WHEN @recipisa IS NOT NULL THEN 'ACCEPTATA'
                        WHEN @anaf_status = 'REJECTED' THEN 'RESPINSA'
                        ELSE 'IN_ASTEPTARE_STATUS'
                    END
                WHEN 'DESCARCARE' THEN 'COMPLETED'
                ELSE 'PENDING'
            END
        END
        ELSE
        BEGIN
            SET @new_stare = CASE @step
                WHEN 'GENERARE' THEN 'NEGNERATA'
                WHEN 'TRANSMITERE' THEN 'TRANSMITERE_ES'
                WHEN 'STATUS' THEN 'TRANSMISA' -- Păstrează starea
                WHEN 'DESCARCARE' THEN 'DESCARCARE_ES'
                ELSE 'PENDING'
            END
        END
        
        -- Construiește UPDATE dinamic
        SET @sql = N'UPDATE [' + @db_name + N'].[dbo].[' + @table_name + N'] SET '
        SET @sql = @sql + N'efact_Stare = @new_stare, '
        SET @sql = @sql + N'efact_Detalii = @message '
        
        -- Adaugă câmpuri specifice bazate pe step
        IF @step = 'TRANSMITERE' AND @ok = 1
        BEGIN
            SET @sql = @sql + N', Id_Solicitare = @id_solicitare '
            SET @sql = @sql + N', Id_Descarcare = @id_descarcare '
            SET @sql = @sql + N', efact_DataIncarcare = SYSUTCDATETIME() '
        END
        
        IF @step = 'STATUS' AND @recipisa IS NOT NULL
        BEGIN
            SET @sql = @sql + N', Recipisa = @recipisa '
        END
        
        IF @step = 'DESCARCARE' AND @ok = 1 AND @zip_base64 IS NOT NULL
        BEGIN
            -- Conversie base64 la varbinary folosind XML
            SET @sql = @sql + N', EFA_Zip_Content = CAST(CAST(N'''' AS XML).value(''xs:base64Binary(sql:variable("@zip_base64"))'', ''varbinary(max)'') AS VARBINARY(MAX)) '
            SET @sql = @sql + N', EFA_Zip_FileName = @id_descarcare + ''.zip'' '
            SET @sql = @sql + N', EF_Data_Validare = SYSUTCDATETIME() '
        END
        
        -- Resetează lock
        SET @sql = @sql + N', efact_Processing_Host = NULL '
        SET @sql = @sql + N', efact_Processing_Time = NULL '
        
        -- WHERE clause
        SET @sql = @sql + N'WHERE Nir = @id_unic'
        
        -- Parametri
        SET @params = N'@new_stare NVARCHAR(20), @message NVARCHAR(500), '
        SET @params = @params + N'@id_solicitare CHAR(10), @id_descarcare CHAR(10), '
        SET @params = @params + N'@recipisa CHAR(10), @zip_base64 NVARCHAR(MAX), @id_unic NVARCHAR(50)'
        
        -- Execută UPDATE
        EXEC sp_executesql @sql, @params,
            @new_stare = @new_stare,
            @message = @message,
            @id_solicitare = @id_solicitare,
            @id_descarcare = @id_descarcare,
            @recipisa = @recipisa,
            @zip_base64 = @zip_base64,
            @id_unic = @id_unic
        
        -- Log succesul
        EXEC dbo.EFA_LogMessage
            @db_name = @db_name,
            @table_name = @table_name,
            @id_unic = @id_unic,
            @step = @step,
            @action = 'UPDATE',
            @http_status = @http_status,
            @anaf_status = @anaf_status,
            @id_solicitare = @id_solicitare,
            @id_descarcare = @id_descarcare,
            @recipisa = @recipisa,
            @message_short = @message,
            @payload_ref = @json,
            @status = CASE WHEN @ok = 1 THEN 'OK' ELSE 'ERR' END,
            @run_id = @run_id
        
        RETURN 0
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE()
        
        -- Log eroarea
        EXEC dbo.EFA_LogMessage
            @db_name = @db_name,
            @table_name = @table_name,
            @id_unic = @id_unic,
            @step = @step,
            @action = 'UPDATE_ERROR',
            @message_short = @ErrorMessage,
            @message_detail = @json,
            @status = 'ERR',
            @run_id = @run_id
        
        PRINT 'Eroare UPDATE: ' + @ErrorMessage
        RETURN -1
    END CATCH
END
GO

PRINT 'Procedură dbo.EFA_UpdateFromResponse creată cu succes.'
GO

/*******************************************************************************
 * Test funcționalitate
 ******************************************************************************/

/*******************************************************************************
 * Instalare completă
 * 
 * NOTĂ PRODUCȚIE: Testele au fost eliminate pentru deployment producție.
 * Pentru testare, consultă documentația din SQL_Server_EFactura/Documentation/
 ******************************************************************************/

PRINT ''
PRINT '========================================='
PRINT 'Proceduri Agent Wrapper instalate cu succes!'
PRINT '- EFA_InvokeAgent'
PRINT '- EFA_UpdateFromResponse'
PRINT '========================================='
GO
