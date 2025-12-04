-- ============================================================================
-- Exemple de Query-uri și Rapoarte pentru RO e-Factura
-- Data: 2024-12-04
-- Versiune: 1.0
-- ============================================================================

USE master
GO

-- ============================================================================
-- 1. MONITORIZARE ȘI DASHBOARD
-- ============================================================================

-- 1.1 Status Global - Toate Bazele
SELECT 
    DB_NAME() AS CurrentDB,
    'Cross-Database' AS ReportType,
    GETDATE() AS ReportDate
GO

-- 1.2 Sumar pe Stare (ultima lună)
-- NOTĂ: Adaptează pentru fiecare bază de date
USE YourDB
GO

SELECT 
    DB_NAME() AS DatabaseName,
    efact_Stare AS Status,
    COUNT(*) AS TotalFacturi,
    COUNT(DISTINCT CAST(DataDoc AS DATE)) AS ZileDistincte,
    MIN(DataDoc) AS DataCeaMaiVeche,
    MAX(DataDoc) AS DataCeaMaiNoua,
    SUM(CASE WHEN DATEDIFF(DAY, DataDoc, GETDATE()) > 5 THEN 1 ELSE 0 END) AS PesteDeadline
FROM Iesiri
WHERE Is_EF = 1
  AND DataDoc >= DATEADD(MONTH, -1, GETDATE())
GROUP BY efact_Stare
ORDER BY 
    CASE efact_Stare
        WHEN 'COMPLETED' THEN 1
        WHEN 'ACCEPTATA' THEN 2
        WHEN 'DESCARCARE_READY' THEN 3
        WHEN 'IN_ASTEPTARE_STATUS' THEN 4
        WHEN 'TRANSMISA' THEN 5
        WHEN 'GENERATA' THEN 6
        WHEN 'IN_PROGRES' THEN 7
        WHEN 'PENDING' THEN 8
        ELSE 9
    END
GO

-- 1.3 Facturi Critice (deadline < 24h)
SELECT 
    Nir AS ID_Factura,
    BT_11 AS NumarFactura,
    BT_13 AS DataEmitere,
    DataDoc,
    master.dbo.EFA_CalculateDeadline(DataDoc) AS Deadline,
    DATEDIFF(HOUR, GETDATE(), master.dbo.EFA_CalculateDeadline(DataDoc)) AS OreRamase,
    master.dbo.EFA_GetDeadlineStatus(DataDoc, GETDATE()) AS StatusUrgenta,
    efact_Stare AS StareActuala,
    efact_Attempt_Count AS NumarIncercari,
    efact_Detalii AS Detalii
FROM Iesiri
WHERE Is_EF = 1
  AND efact_Stare NOT IN ('COMPLETED', 'RESPINSA')
  AND master.dbo.EFA_CalculateDeadline(DataDoc) > GETDATE()
  AND DATEDIFF(HOUR, GETDATE(), master.dbo.EFA_CalculateDeadline(DataDoc)) < 24
ORDER BY OreRamase ASC
GO

-- 1.4 Rate de Succes (ultimele 7 zile)
SELECT 
    CAST(DataDoc AS DATE) AS Data,
    COUNT(*) AS TotalFacturi,
    SUM(CASE WHEN efact_Stare = 'COMPLETED' THEN 1 ELSE 0 END) AS Finalizate,
    SUM(CASE WHEN efact_Stare = 'RESPINSA' THEN 1 ELSE 0 END) AS Respinse,
    SUM(CASE WHEN efact_Stare IN ('NEGNERATA', 'TRANSMITERE_ES', 'DESCARCARE_ES') THEN 1 ELSE 0 END) AS Erori,
    CAST(SUM(CASE WHEN efact_Stare = 'COMPLETED' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS ProcentSucces
FROM Iesiri
WHERE Is_EF = 1
  AND DataDoc >= DATEADD(DAY, -7, GETDATE())
GROUP BY CAST(DataDoc AS DATE)
ORDER BY Data DESC
GO

-- ============================================================================
-- 2. LOGGING ȘI AUDIT
-- ============================================================================

-- 2.1 Ultimele 100 Evenimente
USE master
GO

SELECT TOP 100
    log_dt_utc AS Timestamp_UTC,
    DATEADD(HOUR, 2, log_dt_utc) AS Timestamp_RO, -- Ajustare timezone (UTC+2 pentru Romania)
    db_name AS Baza,
    table_name AS Tabel,
    id_unic AS ID_Factura,
    step AS Pas,
    action AS Actiune,
    status AS Status,
    http_status AS HTTP_Status,
    anaf_status AS ANAF_Status,
    message_short AS Mesaj,
    attempt_no AS Incercare,
    job_name AS Job
FROM efactura_logger
ORDER BY log_dt_utc DESC
GO

-- 2.2 Istoric Complet pentru o Factură
DECLARE @IdFactura NVARCHAR(50) = 'FAC001'
DECLARE @Baza SYSNAME = 'YourDB'

SELECT 
    log_dt_utc AS Timestamp,
    step AS Pas,
    action AS Actiune,
    status AS Status,
    CASE status
        WHEN 'OK' THEN '✓'
        WHEN 'ERR' THEN '✗'
        WHEN 'RETRY' THEN '⟳'
        ELSE '?'
    END AS Icon,
    http_status AS HTTP,
    anaf_status AS ANAF,
    id_solicitare AS ID_Solicitare,
    id_descarcare AS ID_Descarcare,
    recipisa AS Recipisa,
    message_short AS Mesaj,
    attempt_no AS Incercare
FROM efactura_logger
WHERE db_name = @Baza
  AND id_unic = @IdFactura
ORDER BY log_dt_utc ASC
GO

-- 2.3 Erori pe Categorie (ultimele 24h)
-- SQL Server 2012 compatible: folosește XML PATH pentru concatenare
SELECT 
    step AS Pas,
    COUNT(*) AS NumarErori,
    COUNT(DISTINCT id_unic) AS FacturiAfectate,
    STUFF((
        SELECT DISTINCT '; ' + message_short
        FROM efactura_logger e2
        WHERE e2.step = e1.step
          AND e2.status = 'ERR'
          AND e2.log_dt_utc > DATEADD(HOUR, -24, GETUTCDATE())
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS MesajeUnice
FROM efactura_logger e1
WHERE status = 'ERR'
  AND log_dt_utc > DATEADD(HOUR, -24, GETUTCDATE())
GROUP BY step
ORDER BY NumarErori DESC
GO

-- 2.4 Performanță Job-uri (ultimele 10 rulări)
SELECT TOP 10
    run_id AS Job_Run_ID,
    MIN(log_dt_utc) AS Start_Time,
    MAX(log_dt_utc) AS End_Time,
    DATEDIFF(SECOND, MIN(log_dt_utc), MAX(log_dt_utc)) AS Durata_Secunde,
    COUNT(DISTINCT id_unic) AS Facturi_Procesate,
    SUM(CASE WHEN status = 'ERR' THEN 1 ELSE 0 END) AS Erori,
    job_name AS Job_Name
FROM efactura_logger
WHERE run_id IS NOT NULL
GROUP BY run_id, job_name
ORDER BY MIN(log_dt_utc) DESC
GO

-- ============================================================================
-- 3. RAPOARTE CONFORMITATE
-- ============================================================================

-- 3.1 Raport Lunar Conformitate
DECLARE @Luna INT = MONTH(GETDATE())
DECLARE @An INT = YEAR(GETDATE())

SELECT 
    DB_NAME() AS Baza,
    @An AS An,
    @Luna AS Luna,
    COUNT(*) AS TotalFacturi,
    SUM(CASE WHEN efact_Stare = 'COMPLETED' THEN 1 ELSE 0 END) AS Transmise,
    SUM(CASE WHEN efact_Stare = 'RESPINSA' THEN 1 ELSE 0 END) AS Respinse,
    SUM(CASE WHEN DATEDIFF(DAY, DataDoc, ISNULL(EF_Data_Validare, GETDATE())) > 5 THEN 1 ELSE 0 END) AS IntirziatePesteDeadline,
    CAST(SUM(CASE WHEN efact_Stare = 'COMPLETED' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS ProcentConformitate
FROM Iesiri
WHERE Is_EF = 1
  AND MONTH(DataDoc) = @Luna
  AND YEAR(DataDoc) = @An
GO

-- 3.2 Top 10 Facturi cu Cel Mai Lung Timp de Procesare
USE master
GO

WITH ProcessingTimes AS (
    SELECT 
        l1.db_name,
        l1.id_unic,
        MIN(l1.log_dt_utc) AS Start_Time,
        MAX(l2.log_dt_utc) AS End_Time,
        DATEDIFF(MINUTE, MIN(l1.log_dt_utc), MAX(l2.log_dt_utc)) AS Durata_Minute
    FROM efactura_logger l1
    INNER JOIN efactura_logger l2 ON l1.db_name = l2.db_name AND l1.id_unic = l2.id_unic
    WHERE l1.step = 'GENERARE' 
      AND l2.step = 'DESCARCARE' 
      AND l2.status = 'OK'
      AND l1.log_dt_utc >= DATEADD(DAY, -7, GETUTCDATE())
    GROUP BY l1.db_name, l1.id_unic
)
SELECT TOP 10
    db_name AS Baza,
    id_unic AS ID_Factura,
    Start_Time,
    End_Time,
    Durata_Minute,
    CASE 
        WHEN Durata_Minute < 5 THEN 'Rapid'
        WHEN Durata_Minute < 30 THEN 'Normal'
        WHEN Durata_Minute < 120 THEN 'Lent'
        ELSE 'Foarte Lent'
    END AS Clasificare
FROM ProcessingTimes
ORDER BY Durata_Minute DESC
GO

-- 3.3 Raport Săptămânal pentru Management
DECLARE @DataStart DATE = DATEADD(DAY, -7, GETDATE())
DECLARE @DataEnd DATE = GETDATE()

SELECT 
    'Perioada' AS Indicator,
    CAST(@DataStart AS VARCHAR(10)) + ' - ' + CAST(@DataEnd AS VARCHAR(10)) AS Valoare
UNION ALL
SELECT 'Total Facturi', CAST(COUNT(*) AS VARCHAR(20))
FROM Iesiri WHERE Is_EF = 1 AND DataDoc >= @DataStart AND DataDoc < @DataEnd
UNION ALL
SELECT 'Transmise cu Succes', CAST(SUM(CASE WHEN efact_Stare = 'COMPLETED' THEN 1 ELSE 0 END) AS VARCHAR(20))
FROM Iesiri WHERE Is_EF = 1 AND DataDoc >= @DataStart AND DataDoc < @DataEnd
UNION ALL
SELECT 'Respinse de ANAF', CAST(SUM(CASE WHEN efact_Stare = 'RESPINSA' THEN 1 ELSE 0 END) AS VARCHAR(20))
FROM Iesiri WHERE Is_EF = 1 AND DataDoc >= @DataStart AND DataDoc < @DataEnd
UNION ALL
SELECT 'În Procesare', CAST(SUM(CASE WHEN efact_Stare NOT IN ('COMPLETED', 'RESPINSA') THEN 1 ELSE 0 END) AS VARCHAR(20))
FROM Iesiri WHERE Is_EF = 1 AND DataDoc >= @DataStart AND DataDoc < @DataEnd
UNION ALL
SELECT 'Erori Tehnice', CAST(COUNT(*) AS VARCHAR(20))
FROM efactura_logger 
WHERE status = 'ERR' AND log_dt_utc >= CAST(@DataStart AS DATETIME)
UNION ALL
SELECT 'Rate de Conformitate (%)', 
    CAST(CAST(SUM(CASE WHEN efact_Stare = 'COMPLETED' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS VARCHAR(20))
FROM Iesiri WHERE Is_EF = 1 AND DataDoc >= @DataStart AND DataDoc < @DataEnd
GO

-- ============================================================================
-- 4. DIAGNOSTICARE ȘI TROUBLESHOOTING
-- ============================================================================

-- 4.1 Facturi Blocate (IN_PROGRES > 1h)
SELECT 
    DB_NAME() AS Baza,
    Nir AS ID_Factura,
    BT_11 AS NumarFactura,
    efact_Stare AS Stare,
    efact_Processing_Host AS Host,
    efact_Processing_Time AS Locked_Since,
    DATEDIFF(MINUTE, efact_Processing_Time, GETDATE()) AS Minute_Blocat,
    efact_Attempt_Count AS Incercari
FROM Iesiri
WHERE efact_Stare = 'IN_PROGRES'
  AND DATEDIFF(MINUTE, efact_Processing_Time, GETDATE()) > 60
ORDER BY efact_Processing_Time ASC
GO

-- 4.2 Facturi cu Multe Încercări Eșuate
SELECT 
    DB_NAME() AS Baza,
    Nir AS ID_Factura,
    BT_11 AS NumarFactura,
    efact_Stare AS Stare,
    efact_Attempt_Count AS NumarIncercari,
    efact_Detalii AS UltimaEroare,
    DataDoc
FROM Iesiri
WHERE efact_Attempt_Count >= 3
  AND efact_Stare NOT IN ('COMPLETED', 'RESPINSA')
ORDER BY efact_Attempt_Count DESC, DataDoc ASC
GO

-- 4.3 Health Check Complet
USE master
GO

PRINT '========================================='
PRINT 'HEALTH CHECK: RO e-Factura Automation'
PRINT '========================================='
PRINT ''

-- Job Status
PRINT '1. SQL Server Agent Job Status:'
SELECT 
    name AS JobName,
    CASE enabled WHEN 1 THEN 'ENABLED' ELSE 'DISABLED' END AS Status,
    date_modified AS LastModified
FROM msdb.dbo.sysjobs
WHERE name = 'EFA_Background_Processor'

PRINT ''
PRINT '2. xp_cmdshell Status:'
SELECT 
    CASE value_in_use WHEN 1 THEN 'ENABLED' ELSE 'DISABLED' END AS xp_cmdshell_Status
FROM sys.configurations
WHERE name = 'xp_cmdshell'

PRINT ''
PRINT '3. Ultima Rulare Job:'
SELECT TOP 1
    CONVERT(VARCHAR(8), run_date) AS RunDate,
    STUFF(STUFF(RIGHT('000000' + CONVERT(VARCHAR(6), run_time), 6), 5, 0, ':'), 3, 0, ':') AS RunTime,
    CASE run_status
        WHEN 1 THEN 'SUCCESS'
        ELSE 'FAILED'
    END AS Status,
    message AS Message
FROM msdb.dbo.sysjobhistory jh
INNER JOIN msdb.dbo.sysjobs j ON jh.job_id = j.job_id
WHERE j.name = 'EFA_Background_Processor'
  AND step_id = 0
ORDER BY instance_id DESC

PRINT ''
PRINT '4. Facturi în Așteptare (Top 5 Baze):'
-- Notă: Această parte necesită dynamic SQL pentru cross-database
PRINT '(Rulează manual pe fiecare bază)'

PRINT ''
PRINT '5. Erori în Ultimele 24h:'
SELECT COUNT(*) AS NumarErori
FROM efactura_logger
WHERE status = 'ERR'
  AND log_dt_utc > DATEADD(HOUR, -24, GETUTCDATE())

PRINT ''
PRINT '========================================='
PRINT 'Health Check Complet'
PRINT '========================================='
GO

-- ============================================================================
-- 5. ACȚIUNI DE MENTENANȚĂ
-- ============================================================================

-- 5.1 Cleanup Log-uri Vechi (>90 zile)
-- RULEAZĂ MANUAL CU PRECAUȚIE
/*
DELETE FROM efactura_logger
WHERE log_dt_utc < DATEADD(DAY, -90, GETUTCDATE())

PRINT 'Log-uri șterse: ' + CAST(@@ROWCOUNT AS VARCHAR(20))
*/

-- 5.2 Resetare Facturi Blocate
-- RULEAZĂ MANUAL DUPĂ INVESTIGARE
/*
UPDATE Iesiri
SET efact_Stare = 'PENDING',
    efact_Processing_Host = NULL,
    efact_Processing_Time = NULL
WHERE efact_Stare = 'IN_PROGRES'
  AND DATEDIFF(HOUR, efact_Processing_Time, GETDATE()) > 2

PRINT 'Facturi resetate: ' + CAST(@@ROWCOUNT AS VARCHAR(20))
*/

-- 5.3 Re-index Tabele
-- RULEAZĂ LUNAR
/*
ALTER INDEX ALL ON efactura_logger REBUILD
ALTER INDEX ALL ON Iesiri REBUILD
ALTER INDEX ALL ON Export REBUILD
*/

GO

PRINT ''
PRINT '========================================='
PRINT 'Exemple de Query-uri Încheiate'
PRINT 'Pentru alte rapoarte, consultă documentația'
PRINT '========================================='
GO
