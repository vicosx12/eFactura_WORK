/*******************************************************************************
 * Script: 02_Alter_Iesiri_Export_Tables.sql
 * Descriere: Adaugă coloane de tracking pentru RO e-Factura în Iesiri și Export
 * Data: 2025-12-04
 * Versiune: 1.0
 * 
 * NOTĂ: Acest script trebuie rulat pe FIECARE bază de date care conține Iesiri/Export
 *       Adaptează numele bazei de date la linia USE [NumeBaza]
 ******************************************************************************/

-- !!! IMPORTANT: Înlocuiește [__NUMELE_BAZEI_DE_DATE__] cu numele bazei tale de date !!!
-- Exemplu: USE [ExpertSoftwareCompany]
USE [__NUMELE_BAZEI_DE_DATE__]
GO

PRINT 'Procesare bază de date: ' + DB_NAME()
GO

/*******************************************************************************
 * PARTEA 1: Modificări Iesiri
 ******************************************************************************/

-- Verificare existență tabelă Iesiri
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Iesiri]') AND type = 'U')
BEGIN
    PRINT 'EROARE: Tabela Iesiri nu există în această bază de date!'
    RAISERROR('Tabela Iesiri nu există.', 16, 1)
    RETURN
END
GO

PRINT 'Modificare tabelă Iesiri...'
GO

-- Adăugare coloane noi (dacă nu există deja)

-- Coloane identificatori ANAF
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Iesiri]') AND name = 'Id_Solicitare')
BEGIN
    ALTER TABLE [dbo].[Iesiri] ADD [Id_Solicitare] CHAR(10) NULL
    PRINT '  + Coloană Id_Solicitare adăugată'
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Iesiri]') AND name = 'Id_Descarcare')
BEGIN
    ALTER TABLE [dbo].[Iesiri] ADD [Id_Descarcare] CHAR(10) NULL
    PRINT '  + Coloană Id_Descarcare adăugată'
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Iesiri]') AND name = 'Recipisa')
BEGIN
    ALTER TABLE [dbo].[Iesiri] ADD [Recipisa] CHAR(10) NULL
    PRINT '  + Coloană Recipisa adăugată'
END

-- Coloane status și detalii
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Iesiri]') AND name = 'efact_Stare')
BEGIN
    ALTER TABLE [dbo].[Iesiri] ADD [efact_Stare] NVARCHAR(20) NULL
    PRINT '  + Coloană efact_Stare adăugată'
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Iesiri]') AND name = 'efact_Tip')
BEGIN
    ALTER TABLE [dbo].[Iesiri] ADD [efact_Tip] NVARCHAR(20) NULL
    PRINT '  + Coloană efact_Tip adăugată'
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Iesiri]') AND name = 'efact_Detalii')
BEGIN
    ALTER TABLE [dbo].[Iesiri] ADD [efact_Detalii] NVARCHAR(100) NULL
    PRINT '  + Coloană efact_Detalii adăugată'
END

-- Coloane timestamp
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Iesiri]') AND name = 'efact_DataIncarcare')
BEGIN
    ALTER TABLE [dbo].[Iesiri] ADD [efact_DataIncarcare] DATETIME2 NULL
    PRINT '  + Coloană efact_DataIncarcare adăugată'
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Iesiri]') AND name = 'EF_Data_Validare')
BEGIN
    ALTER TABLE [dbo].[Iesiri] ADD [EF_Data_Validare] DATETIME2 NULL
    PRINT '  + Coloană EF_Data_Validare adăugată'
END

-- Coloane ZIP content
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Iesiri]') AND name = 'EFA_Zip_FileName')
BEGIN
    ALTER TABLE [dbo].[Iesiri] ADD [EFA_Zip_FileName] NVARCHAR(254) NULL
    PRINT '  + Coloană EFA_Zip_FileName adăugată'
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Iesiri]') AND name = 'EFA_Zip_Content')
BEGIN
    ALTER TABLE [dbo].[Iesiri] ADD [EFA_Zip_Content] VARBINARY(MAX) NULL
    PRINT '  + Coloană EFA_Zip_Content adăugată'
END

-- Coloane pentru control concurență
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Iesiri]') AND name = 'efact_Processing_Host')
BEGIN
    ALTER TABLE [dbo].[Iesiri] ADD [efact_Processing_Host] SYSNAME NULL
    PRINT '  + Coloană efact_Processing_Host adăugată'
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Iesiri]') AND name = 'efact_Processing_Time')
BEGIN
    ALTER TABLE [dbo].[Iesiri] ADD [efact_Processing_Time] DATETIME2 NULL
    PRINT '  + Coloană efact_Processing_Time adăugată'
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Iesiri]') AND name = 'efact_Attempt_Count')
BEGIN
    ALTER TABLE [dbo].[Iesiri] ADD [efact_Attempt_Count] INT NOT NULL DEFAULT 0
    PRINT '  + Coloană efact_Attempt_Count adăugată'
END
GO

-- Creare index pentru selecție candidați e-Factura (Iesiri)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Iesiri]') AND name = 'IX_Iesiri_EF_Processing')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Iesiri_EF_Processing]
    ON [dbo].[Iesiri] ([Is_EF] ASC, [efact_Stare] ASC, [DataDoc] ASC)
    INCLUDE ([Nir], [BT_11], [BT_13], [Id_Descarcare], [efact_Attempt_Count])
    PRINT '  + Index IX_Iesiri_EF_Processing creat'
END
GO

PRINT 'Tabelă Iesiri modificată cu succes.'
GO

/*******************************************************************************
 * PARTEA 2: Modificări Export
 ******************************************************************************/

-- Verificare existență tabelă Export
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Export]') AND type = 'U')
BEGIN
    PRINT 'AVERTISMENT: Tabela Export nu există în această bază de date. Se omite.'
END
ELSE
BEGIN
    PRINT 'Modificare tabelă Export...'

    -- Adăugare coloane noi (dacă nu există deja) - Export

    -- Coloane identificatori ANAF
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Export]') AND name = 'Id_Solicitare')
    BEGIN
        ALTER TABLE [dbo].[Export] ADD [Id_Solicitare] CHAR(10) NULL
        PRINT '  + Coloană Id_Solicitare adăugată'
    END

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Export]') AND name = 'Id_Descarcare')
    BEGIN
        ALTER TABLE [dbo].[Export] ADD [Id_Descarcare] CHAR(10) NULL
        PRINT '  + Coloană Id_Descarcare adăugată'
    END

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Export]') AND name = 'Recipisa')
    BEGIN
        ALTER TABLE [dbo].[Export] ADD [Recipisa] CHAR(10) NULL
        PRINT '  + Coloană Recipisa adăugată'
    END

    -- Coloane status și detalii
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Export]') AND name = 'efact_Stare')
    BEGIN
        ALTER TABLE [dbo].[Export] ADD [efact_Stare] NVARCHAR(20) NULL
        PRINT '  + Coloană efact_Stare adăugată'
    END

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Export]') AND name = 'efact_Tip')
    BEGIN
        ALTER TABLE [dbo].[Export] ADD [efact_Tip] NVARCHAR(20) NULL
        PRINT '  + Coloană efact_Tip adăugată'
    END

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Export]') AND name = 'efact_Detalii')
    BEGIN
        ALTER TABLE [dbo].[Export] ADD [efact_Detalii] NVARCHAR(100) NULL
        PRINT '  + Coloană efact_Detalii adăugată'
    END

    -- Coloane timestamp
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Export]') AND name = 'efact_DataIncarcare')
    BEGIN
        ALTER TABLE [dbo].[Export] ADD [efact_DataIncarcare] DATETIME2 NULL
        PRINT '  + Coloană efact_DataIncarcare adăugată'
    END

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Export]') AND name = 'EF_Data_Validare')
    BEGIN
        ALTER TABLE [dbo].[Export] ADD [EF_Data_Validare] DATETIME2 NULL
        PRINT '  + Coloană EF_Data_Validare adăugată'
    END

    -- Coloane ZIP content
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Export]') AND name = 'EFA_Zip_FileName')
    BEGIN
        ALTER TABLE [dbo].[Export] ADD [EFA_Zip_FileName] NVARCHAR(254) NULL
        PRINT '  + Coloană EFA_Zip_FileName adăugată'
    END

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Export]') AND name = 'EFA_Zip_Content')
    BEGIN
        ALTER TABLE [dbo].[Export] ADD [EFA_Zip_Content] VARBINARY(MAX) NULL
        PRINT '  + Coloană EFA_Zip_Content adăugată'
    END

    -- Coloane pentru control concurență
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Export]') AND name = 'efact_Processing_Host')
    BEGIN
        ALTER TABLE [dbo].[Export] ADD [efact_Processing_Host] SYSNAME NULL
        PRINT '  + Coloană efact_Processing_Host adăugată'
    END

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Export]') AND name = 'efact_Processing_Time')
    BEGIN
        ALTER TABLE [dbo].[Export] ADD [efact_Processing_Time] DATETIME2 NULL
        PRINT '  + Coloană efact_Processing_Time adăugată'
    END

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Export]') AND name = 'efact_Attempt_Count')
    BEGIN
        ALTER TABLE [dbo].[Export] ADD [efact_Attempt_Count] INT NOT NULL DEFAULT 0
        PRINT '  + Coloană efact_Attempt_Count adăugată'
    END

    -- Creare index pentru selecție candidați e-Factura (Export)
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Export]') AND name = 'IX_Export_EF_Processing')
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Export_EF_Processing]
        ON [dbo].[Export] ([Is_EF] ASC, [efact_Stare] ASC, [DataDoc] ASC)
        INCLUDE ([Nir], [BT_11], [BT_13], [Id_Descarcare], [efact_Attempt_Count])
        PRINT '  + Index IX_Export_EF_Processing creat'
    END

    PRINT 'Tabelă Export modificată cu succes.'
END
GO

PRINT '========================================='
PRINT 'Script executat cu succes!'
PRINT 'Bază de date: ' + DB_NAME()
PRINT '========================================='
GO

-- Verificare coloane adăugate
SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length AS MaxLength,
    c.is_nullable AS IsNullable
FROM sys.columns c
INNER JOIN sys.tables t ON c.object_id = t.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name IN ('Iesiri', 'Export')
  AND c.name LIKE 'efact%' OR c.name LIKE 'EFA_%' OR c.name LIKE 'Id_%' OR c.name = 'Recipisa'
ORDER BY t.name, c.column_id
GO
