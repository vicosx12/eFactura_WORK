/*******************************************************************************
 * Helper Functions for RO e-Factura Automation
 * SQL Server 2012 Compatible Version
 * Data: 2025-12-04
 * Versiune: 1.1 (SQL Server 2012 compatibility)
 ******************************************************************************/

USE [master]
GO

/*******************************************************************************
 * Function: dbo.EFA_ParseJsonValue
 * Descriere: Extrage o valoare simplă dintr-un JSON string (SQL Server 2012 compatible)
 * Data: 2025-12-04
 * Versiune: 1.0
 *
 * NOTĂ: Aceasta este o implementare simplificată pentru SQL Server 2012.
 *       Pentru JSON complex, considerați upgrade la SQL Server 2016+
 ******************************************************************************/

IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[EFA_ParseJsonValue]') AND type = 'FN')
    DROP FUNCTION [dbo].[EFA_ParseJsonValue]
GO

CREATE FUNCTION [dbo].[EFA_ParseJsonValue]
(
    @json NVARCHAR(MAX),
    @key NVARCHAR(100)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @value NVARCHAR(MAX)
    DECLARE @startPos INT
    DECLARE @endPos INT
    DECLARE @searchKey NVARCHAR(110)
    
    -- Construiește pattern-ul de căutare: "key":"value" sau "key":value sau "key":null
    SET @searchKey = '"' + @key + '":'
    SET @startPos = CHARINDEX(@searchKey, @json)
    
    IF @startPos = 0
        RETURN NULL
    
    -- Treci peste cheie și ":"
    SET @startPos = @startPos + LEN(@searchKey)
    
    -- Sări peste spații
    WHILE SUBSTRING(@json, @startPos, 1) IN (' ', CHAR(9), CHAR(10), CHAR(13))
        SET @startPos = @startPos + 1
    
    -- Verifică dacă valoarea este null
    IF SUBSTRING(@json, @startPos, 4) = 'null'
        RETURN NULL
    
    -- Verifică dacă valoarea este string (începe cu ")
    IF SUBSTRING(@json, @startPos, 1) = '"'
    BEGIN
        SET @startPos = @startPos + 1
        SET @endPos = CHARINDEX('"', @json, @startPos)
        
        -- Găsește închiderea string-ului (ține cont de escape-uri)
        WHILE @endPos > 0 AND SUBSTRING(@json, @endPos - 1, 1) = '\'
        BEGIN
            SET @endPos = CHARINDEX('"', @json, @endPos + 1)
        END
        
        IF @endPos > 0
            SET @value = SUBSTRING(@json, @startPos, @endPos - @startPos)
    END
    ELSE
    BEGIN
        -- Valoare non-string (număr, boolean)
        -- Găsește primul separator: , } ] sau spațiu/newline
        SET @endPos = @startPos
        WHILE @endPos <= LEN(@json) 
              AND SUBSTRING(@json, @endPos, 1) NOT IN (',', '}', ']', ' ', CHAR(9), CHAR(10), CHAR(13))
        BEGIN
            SET @endPos = @endPos + 1
        END
        
        SET @value = SUBSTRING(@json, @startPos, @endPos - @startPos)
        SET @value = RTRIM(LTRIM(@value))
    END
    
    RETURN @value
END
GO

PRINT 'Funcție dbo.EFA_ParseJsonValue creată cu succes (SQL Server 2012 compatible).'
GO

/*******************************************************************************
 * Stored Procedure: dbo.EFA_CalculateDeadline
 * Descriere: Calculează deadline-ul legal pentru transmitere e-Factura (T+5 zile)
 * Data: 2025-12-04
 * Versiune: 1.0
 *
 * Parametri:
 *   @DataEmitere - Data emiterii facturii
 *
 * Return:
 *   Deadline (T+5 zile calendaristice de la data emiterii)
 ******************************************************************************/

USE [master]
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[EFA_CalculateDeadline]') AND type = 'FN')
    DROP FUNCTION [dbo].[EFA_CalculateDeadline]
GO

CREATE FUNCTION [dbo].[EFA_CalculateDeadline]
(
    @DataEmitere DATETIME
)
RETURNS DATETIME
AS
BEGIN
    -- Deadline = Data emitere + 5 zile calendaristice
    -- Ex: Emis 5 august → Deadline 10 august 23:59:59
    DECLARE @Deadline DATETIME
    
    SET @Deadline = DATEADD(DAY, 5, CAST(@DataEmitere AS DATE))
    SET @Deadline = DATEADD(SECOND, -1, DATEADD(DAY, 1, @Deadline)) -- 23:59:59
    
    RETURN @Deadline
END
GO

PRINT 'Funcție dbo.EFA_CalculateDeadline creată cu succes.'
GO

/*******************************************************************************
 * Stored Procedure: dbo.EFA_GetDeadlineStatus
 * Descriere: Determină statusul deadline-ului (CRITICAL/WARNING/INFO)
 * Data: 2025-12-04
 * Versiune: 1.0
 ******************************************************************************/

IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[EFA_GetDeadlineStatus]') AND type = 'FN')
    DROP FUNCTION [dbo].[EFA_GetDeadlineStatus]
GO

CREATE FUNCTION [dbo].[EFA_GetDeadlineStatus]
(
    @DataEmitere DATETIME,
    @DataCurenta DATETIME = NULL
)
RETURNS NVARCHAR(10)
AS
BEGIN
    DECLARE @Deadline DATETIME
    DECLARE @HoursRemaining INT
    DECLARE @Status NVARCHAR(10)
    
    -- Folosește data curentă dacă nu e specificată
    IF @DataCurenta IS NULL
        SET @DataCurenta = GETDATE()
    
    -- Calculează deadline
    SET @Deadline = dbo.EFA_CalculateDeadline(@DataEmitere)
    
    -- Calculează ore rămase
    SET @HoursRemaining = DATEDIFF(HOUR, @DataCurenta, @Deadline)
    
    -- Determină status
    IF @HoursRemaining < 24
        SET @Status = 'CRITICAL'
    ELSE IF @HoursRemaining < 48
        SET @Status = 'WARNING'
    ELSE
        SET @Status = 'INFO'
    
    RETURN @Status
END
GO

PRINT 'Funcție dbo.EFA_GetDeadlineStatus creată cu succes.'
GO

/*******************************************************************************
 * Stored Procedure: dbo.EFA_LogMessage
 * Descriere: Înregistrează mesaj în efactura_logger
 * Data: 2025-12-04
 * Versiune: 1.0
 ******************************************************************************/

IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[EFA_LogMessage]') AND type = 'P')
    DROP PROCEDURE [dbo].[EFA_LogMessage]
GO

CREATE PROCEDURE [dbo].[EFA_LogMessage]
    @db_name SYSNAME,
    @table_name SYSNAME,
    @id_unic NVARCHAR(50),
    @step NVARCHAR(20),
    @action NVARCHAR(100) = NULL,
    @code_ref NVARCHAR(50) = NULL,
    @http_status INT = NULL,
    @anaf_status NVARCHAR(50) = NULL,
    @id_solicitare CHAR(10) = NULL,
    @id_descarcare CHAR(10) = NULL,
    @recipisa CHAR(10) = NULL,
    @message_short NVARCHAR(500) = NULL,
    @message_detail NVARCHAR(MAX) = NULL,
    @payload_ref NVARCHAR(MAX) = NULL,
    @status CHAR(10),
    @attempt_no INT = 1,
    @job_name SYSNAME = NULL,
    @run_id UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON
    
    -- Default values
    IF @job_name IS NULL
        SET @job_name = 'MANUAL'
    
    -- Insert log
    INSERT INTO [dbo].[efactura_logger] (
        [db_name],
        [table_name],
        [id_unic],
        [step],
        [action],
        [code_ref],
        [http_status],
        [anaf_status],
        [id_solicitare],
        [id_descarcare],
        [recipisa],
        [message_short],
        [message_detail],
        [payload_ref],
        [status],
        [attempt_no],
        [job_name],
        [host_name],
        [run_id]
    )
    VALUES (
        @db_name,
        @table_name,
        @id_unic,
        @step,
        @action,
        @code_ref,
        @http_status,
        @anaf_status,
        @id_solicitare,
        @id_descarcare,
        @recipisa,
        @message_short,
        @message_detail,
        @payload_ref,
        @status,
        @attempt_no,
        @job_name,
        HOST_NAME(),
        @run_id
    )
    
    RETURN 0
END
GO

PRINT 'Procedură dbo.EFA_LogMessage creată cu succes.'
GO

/*******************************************************************************
 * Instalare completă
 * 
 * NOTĂ PRODUCȚIE: Testele au fost eliminate pentru deployment producție.
 * Pentru testare, consultă documentația din SQL_Server_EFactura/Documentation/
 ******************************************************************************/

PRINT ''
PRINT '========================================='
PRINT 'Funcții helper instalate cu succes!'
PRINT '- EFA_ParseJsonValue (SQL Server 2012 compatible)'
PRINT '- EFA_CalculateDeadline'
PRINT '- EFA_GetDeadlineStatus'
PRINT '- EFA_LogMessage'
PRINT '========================================='
GO
