/*******************************************************************************
 * Script: 01_Create_efactura_logger.sql
 * Descriere: Creare tabelă centrală de logging pentru RO e-Factura
 * Data: 2025-12-04
 * Versiune: 1.0
 ******************************************************************************/

USE [master]
GO

-- Verificare și ștergere tabel existent (doar pentru reinstalare)
IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[efactura_logger]') AND type = 'U')
BEGIN
    PRINT 'Tabela efactura_logger există deja. Șterge manual dacă vrei reinstalare.'
    -- DROP TABLE [dbo].[efactura_logger]
END
GO

-- Creare tabelă efactura_logger
CREATE TABLE [dbo].[efactura_logger] (
    -- Identificare unică
    [log_id] BIGINT IDENTITY(1,1) NOT NULL,
    [log_dt_utc] DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    
    -- Context factură
    [db_name] SYSNAME NOT NULL,                    -- Bază de date (ex: 'ERPDB')
    [table_name] SYSNAME NOT NULL,                 -- Tabelă sursă: 'Iesiri' sau 'Export'
    [id_unic] NVARCHAR(50) NOT NULL,               -- ID factură (Nir din Iesiri/Export)
    
    -- Context procesare
    [step] NVARCHAR(20) NOT NULL,                  -- SCANARE|GENERARE|TRANSMITERE|STATUS|DESCARCARE
    [action] NVARCHAR(100) NULL,                   -- Descriere acțiune specifică
    [code_ref] NVARCHAR(50) NULL,                  -- Cod de referință intern
    
    -- Status HTTP și ANAF
    [http_status] INT NULL,                        -- HTTP status code (200, 400, 500, etc.)
    [anaf_status] NVARCHAR(50) NULL,               -- Status ANAF (ACCEPTED, REJECTED, etc.)
    
    -- Identificatori ANAF
    [id_solicitare] CHAR(10) NULL,                 -- ID solicitare ANAF
    [id_descarcare] CHAR(10) NULL,                 -- ID descărcare ANAF
    [recipisa] CHAR(10) NULL,                      -- Recipisa ANAF
    
    -- Mesaje
    [message_short] NVARCHAR(500) NULL,            -- Mesaj scurt
    [message_detail] NVARCHAR(MAX) NULL,           -- Detalii complete (stack trace, JSON, etc.)
    [payload_ref] NVARCHAR(MAX) NULL,              -- Payload JSON pentru debug
    
    -- Status și retry
    [status] CHAR(10) NOT NULL,                    -- OK|ERR|RETRY
    [attempt_no] INT NOT NULL DEFAULT 1,           -- Număr încercare
    
    -- Tracking job
    [job_name] SYSNAME NULL,                       -- Nume job SQL Agent
    [host_name] SYSNAME NULL,                      -- Host care procesează
    [run_id] UNIQUEIDENTIFIER NULL,                -- ID unic de rulare
    
    -- Constrângeri
    CONSTRAINT [PK_efactura_logger] PRIMARY KEY CLUSTERED ([log_id] ASC),
    CONSTRAINT [CK_efactura_logger_step] CHECK ([step] IN ('SCANARE', 'GENERARE', 'TRANSMITERE', 'STATUS', 'DESCARCARE')),
    CONSTRAINT [CK_efactura_logger_status] CHECK ([status] IN ('OK', 'ERR', 'RETRY')),
    CONSTRAINT [CK_efactura_logger_table] CHECK ([table_name] IN ('Iesiri', 'Export'))
)
GO

-- Index pentru lookup rapid by factură
CREATE NONCLUSTERED INDEX [IX_efactura_logger_lookup]
ON [dbo].[efactura_logger] (
    [db_name] ASC,
    [table_name] ASC,
    [id_unic] ASC,
    [log_dt_utc] DESC
)
INCLUDE ([step], [status], [message_short])
GO

-- Index pentru monitorizare și alerte
CREATE NONCLUSTERED INDEX [IX_efactura_logger_step_status]
ON [dbo].[efactura_logger] (
    [step] ASC,
    [status] ASC,
    [log_dt_utc] DESC
)
INCLUDE ([db_name], [table_name], [id_unic], [message_short])
GO

-- Index pentru tracking job-uri
CREATE NONCLUSTERED INDEX [IX_efactura_logger_run_id]
ON [dbo].[efactura_logger] (
    [run_id] ASC,
    [log_dt_utc] DESC
)
INCLUDE ([step], [status], [db_name], [id_unic])
GO

-- Index pentru identificatori ANAF
CREATE NONCLUSTERED INDEX [IX_efactura_logger_anaf_ids]
ON [dbo].[efactura_logger] (
    [id_solicitare] ASC
)
WHERE [id_solicitare] IS NOT NULL
INCLUDE ([id_descarcare], [recipisa], [anaf_status])
GO

PRINT 'Tabelă efactura_logger creată cu succes.'
PRINT 'Indexe create:'
PRINT '  - IX_efactura_logger_lookup (db_name, table_name, id_unic)'
PRINT '  - IX_efactura_logger_step_status (step, status)'
PRINT '  - IX_efactura_logger_run_id (run_id)'
PRINT '  - IX_efactura_logger_anaf_ids (id_solicitare)'
GO

-- Exemplu de verificare
SELECT 
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
WHERE t.name = 'efactura_logger'
ORDER BY i.index_id
GO
