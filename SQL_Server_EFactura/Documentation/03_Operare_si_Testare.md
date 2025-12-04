# Ghid de Operare și Testare: RO e-Factura Automation

## 1. Operare Zilnică

### 1.1 Monitorizare Job

**Verificare status job:**
```sql
-- Status curent job
SELECT 
    name AS JobName,
    enabled AS IsEnabled,
    date_created,
    date_modified
FROM msdb.dbo.sysjobs
WHERE name = 'EFA_Background_Processor'

-- Ultima rulare
SELECT TOP 1
    CONVERT(VARCHAR(8), run_date) AS RunDate,
    STUFF(STUFF(RIGHT('000000' + CONVERT(VARCHAR(6), run_time), 6), 5, 0, ':'), 3, 0, ':') AS RunTime,
    CASE run_status
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 2 THEN 'Retry'
        WHEN 3 THEN 'Canceled'
        WHEN 4 THEN 'In Progress'
    END AS Status,
    run_duration,
    message
FROM msdb.dbo.sysjobhistory jh
INNER JOIN msdb.dbo.sysjobs j ON jh.job_id = j.job_id
WHERE j.name = 'EFA_Background_Processor'
  AND jh.step_id = 0  -- Job outcome
ORDER BY jh.instance_id DESC
```

**Alerte automate:**
```sql
-- Configurează SQL Server Agent Alert pentru erori job
USE msdb
GO

EXEC sp_add_alert 
    @name = N'EFA Job Failed',
    @message_id = 0,
    @severity = 0,
    @enabled = 1,
    @delay_between_responses = 900,
    @include_event_description_in = 1,
    @job_name = N'EFA_Background_Processor'
```

### 1.2 Dashboard Rapid

**Sumar status facturi:**
```sql
SELECT 
    efact_Stare AS Status,
    COUNT(*) AS Total,
    MIN(DataDoc) AS OldestDate,
    MAX(DataDoc) AS NewestDate,
    AVG(DATEDIFF(HOUR, efact_DataIncarcare, EF_Data_Validare)) AS AvgHoursToComplete
FROM Iesiri
WHERE Is_EF = 1
  AND DataDoc >= DATEADD(MONTH, -1, GETDATE())
GROUP BY efact_Stare
ORDER BY 
    CASE efact_Stare
        WHEN 'COMPLETED' THEN 1
        WHEN 'ACCEPTATA' THEN 2
        WHEN 'TRANSMISA' THEN 3
        WHEN 'GENERATA' THEN 4
        WHEN 'PENDING' THEN 5
        ELSE 6
    END
```

**Facturi aproape de deadline:**
```sql
SELECT 
    Nir,
    BT_11 AS NumarFactura,
    DataDoc,
    master.dbo.EFA_CalculateDeadline(DataDoc) AS Deadline,
    DATEDIFF(HOUR, GETDATE(), master.dbo.EFA_CalculateDeadline(DataDoc)) AS HoursRemaining,
    efact_Stare,
    efact_Attempt_Count
FROM Iesiri
WHERE Is_EF = 1
  AND efact_Stare NOT IN ('COMPLETED', 'RESPINSA')
  AND DATEDIFF(HOUR, GETDATE(), master.dbo.EFA_CalculateDeadline(DataDoc)) < 48
ORDER BY HoursRemaining ASC
```

**Erori recente:**
```sql
SELECT TOP 50
    log_dt_utc,
    db_name,
    table_name,
    id_unic,
    step,
    message_short,
    attempt_no
FROM efactura_logger
WHERE status = 'ERR'
  AND log_dt_utc > DATEADD(HOUR, -24, GETUTCDATE())
ORDER BY log_dt_utc DESC
```

### 1.3 Acțiuni Manuale

**Reprocesare factură specifică:**
```sql
DECLARE @run_id UNIQUEIDENTIFIER = NEWID()

EXEC dbo.EFA_ProcessOne
    @db_name = 'YourDB',
    @table_name = 'Iesiri',
    @id_unic = 'FAC001',
    @run_id = @run_id,
    @efagent_path = 'C:\EFAgent\EFAgent.exe',
    @conn_string = 'Server=localhost;Database=YourDB;Trusted_Connection=True;',
    @environment = 'prod'

-- Verifică rezultatul
SELECT *
FROM efactura_logger
WHERE run_id = @run_id
ORDER BY log_dt_utc DESC
```

**Resetare factură blocată:**
```sql
-- Resetează o factură blocată în IN_PROGRES
UPDATE Iesiri
SET efact_Stare = 'PENDING',
    efact_Processing_Host = NULL,
    efact_Processing_Time = NULL,
    efact_Attempt_Count = 0
WHERE Nir = 'FAC001'
  AND efact_Stare = 'IN_PROGRES'
```

**Forțare reîncercare după eroare:**
```sql
-- Resetează contor de încercări pentru reîncercare
UPDATE Iesiri
SET efact_Attempt_Count = 0,
    efact_Stare = 'PENDING'
WHERE Nir = 'FAC001'
  AND efact_Stare IN ('NEGNERATA', 'TRANSMITERE_ES')
```

## 2. Scenarii de Testare

### 2.1 Test Complete Flow (Happy Path)

**Pregătire:**
```sql
-- Creează factură de test
INSERT INTO TestDB.dbo.Iesiri (
    Nir, BT_11, BT_13, DataDoc, Is_EF, eFactura,
    Furnizor, CIF_Furnizor, Client, CIF_Client,
    Total, Valuta
)
VALUES (
    'TEST001', 'FAC-TEST-001', '2024-12-04', '2024-12-04', 1, 1,
    'Test Furnizor SRL', 'RO12345678', 'Test Client SRL', 'RO87654321',
    1000.00, 'RON'
)
```

**Execuție:**
```bash
# 1. Generare
C:\EFAgent\EFAgent.exe generate --db=TestDB --table=Iesiri --id=TEST001 --connString="..." --env=test

# 2. Upload
C:\EFAgent\EFAgent.exe upload --db=TestDB --table=Iesiri --id=TEST001 --connString="..." --env=test

# 3. Status (după câteva minute)
C:\EFAgent\EFAgent.exe status --db=TestDB --table=Iesiri --id=TEST001 --id_descarcare=<ID> --env=test

# 4. Download
C:\EFAgent\EFAgent.exe download --db=TestDB --table=Iesiri --id=TEST001 --id_descarcare=<ID> --env=test
```

**Verificare:**
```sql
SELECT 
    Nir,
    efact_Stare,
    Id_Solicitare,
    Id_Descarcare,
    Recipisa,
    efact_DataIncarcare,
    EF_Data_Validare,
    DATALENGTH(EFA_Zip_Content) AS ZipSizeBytes
FROM TestDB.dbo.Iesiri
WHERE Nir = 'TEST001'

-- Log-uri
SELECT *
FROM efactura_logger
WHERE db_name = 'TestDB'
  AND id_unic = 'TEST001'
ORDER BY log_dt_utc DESC
```

**Rezultat așteptat:**
- `efact_Stare` = 'COMPLETED'
- `Recipisa` != NULL
- `EFA_Zip_Content` != NULL
- Toate pașii logați cu status = 'OK'

### 2.2 Test Eroare Validare XSD

**Pregătire:**
```sql
-- Creează factură cu date invalide
INSERT INTO TestDB.dbo.Iesiri (
    Nir, BT_11, BT_13, DataDoc, Is_EF,
    Furnizor, CIF_Furnizor,  -- CIF invalid
    Total
)
VALUES (
    'TEST_INVALID', 'FAC-INV', '2024-12-04', '2024-12-04', 1,
    'Test', 'INVALID_CIF',
    NULL  -- Total NULL (invalid)
)
```

**Execuție:**
```bash
C:\EFAgent\EFAgent.exe generate --db=TestDB --table=Iesiri --id=TEST_INVALID --connString="..." --env=test
```

**Rezultat așteptat:**
- Exit code != 0
- JSON output cu `ok: false`
- `efact_Stare` = 'NEGNERATA'
- Log cu detalii eroare XSD

### 2.3 Test Retry Logic

**Simulare eroare tranzitorie:**
```sql
-- Marcă factură pentru retry
UPDATE TestDB.dbo.Iesiri
SET efact_Stare = 'TRANSMITERE_ES',
    efact_Attempt_Count = 1
WHERE Nir = 'TEST001'
```

**Rulare automată:**
```sql
EXEC dbo.EFA_ProcessOne
    @db_name = 'TestDB',
    @table_name = 'Iesiri',
    @id_unic = 'TEST001',
    @run_id = NEWID(),
    @efagent_path = 'C:\EFAgent\EFAgent.exe',
    @conn_string = '...',
    @environment = 'test'
```

**Verificare:**
```sql
-- Verifică număr de încercări
SELECT 
    Nir,
    efact_Attempt_Count,
    efact_Stare,
    efact_Detalii
FROM TestDB.dbo.Iesiri
WHERE Nir = 'TEST001'

-- Verifică log-uri retry
SELECT *
FROM efactura_logger
WHERE db_name = 'TestDB'
  AND id_unic = 'TEST001'
  AND status = 'RETRY'
ORDER BY log_dt_utc DESC
```

### 2.4 Test Concurență

**Simulare rulări paralele:**
```sql
-- Session 1
EXEC dbo.EFA_ProcessOne
    @db_name = 'TestDB',
    @table_name = 'Iesiri',
    @id_unic = 'TEST001',
    @run_id = NEWID()

-- Session 2 (imediat după)
EXEC dbo.EFA_ProcessOne
    @db_name = 'TestDB',
    @table_name = 'Iesiri',
    @id_unic = 'TEST001',
    @run_id = NEWID()
```

**Rezultat așteptat:**
- Doar o sesiune procesează
- Cealaltă primește "Document deja în procesare"
- Log cu "SKIP" pentru sesiunea 2

### 2.5 Test Deadline Alert

**Simulare factură aproape de deadline:**
```sql
-- Creează factură cu data veche
INSERT INTO TestDB.dbo.Iesiri (
    Nir, BT_11, DataDoc, Is_EF
)
VALUES (
    'TEST_LATE', 'FAC-LATE', DATEADD(DAY, -4, GETDATE()), 1
)
```

**Verificare alertă:**
```sql
SELECT 
    Nir,
    DataDoc,
    master.dbo.EFA_CalculateDeadline(DataDoc) AS Deadline,
    master.dbo.EFA_GetDeadlineStatus(DataDoc, GETDATE()) AS DeadlineStatus
FROM TestDB.dbo.Iesiri
WHERE Nir = 'TEST_LATE'
```

**Rezultat așteptat:**
- `DeadlineStatus` = 'CRITICAL' sau 'WARNING'
- Log în efactura_logger cu "DEADLINE_WARNING"

### 2.6 Test Performance (Load)

**Pregătire 100 facturi:**
```sql
DECLARE @i INT = 1
WHILE @i <= 100
BEGIN
    INSERT INTO TestDB.dbo.Iesiri (
        Nir, BT_11, DataDoc, Is_EF, eFactura,
        Furnizor, CIF_Furnizor, Total
    )
    VALUES (
        'LOAD_' + RIGHT('000' + CAST(@i AS VARCHAR(3)), 3),
        'FAC-' + CAST(@i AS VARCHAR(3)),
        GETDATE(),
        1, 1,
        'Test Furnizor', 'RO12345678', 100.00
    )
    SET @i = @i + 1
END
```

**Rulare batch:**
```sql
DECLARE @start DATETIME2 = SYSUTCDATETIME()

EXEC dbo.EFA_ProcessDb
    @db_name = 'TestDB',
    @run_id = NEWID(),
    @batch_size = 100,
    @environment = 'test'

DECLARE @duration INT = DATEDIFF(SECOND, @start, SYSUTCDATETIME())
PRINT 'Durată: ' + CAST(@duration AS VARCHAR(10)) + ' secunde'
PRINT 'Throughput: ' + CAST(100.0 / @duration AS VARCHAR(10)) + ' facturi/secundă'
```

**Metrici așteptate:**
- Throughput: ~5-10 facturi/secundă (depinde de network, ANAF)
- Fără deadlock-uri sau timeout-uri
- Toate facturile procesate sau în retry

## 3. Exemple de Monitoring Queries

### 3.1 Raport Conformitate Săptămânal

```sql
SELECT 
    DATEPART(WEEK, DataDoc) AS Saptamana,
    COUNT(*) AS TotalFacturi,
    SUM(CASE WHEN efact_Stare = 'COMPLETED' THEN 1 ELSE 0 END) AS Transmise,
    SUM(CASE WHEN efact_Stare = 'RESPINSA' THEN 1 ELSE 0 END) AS Respinse,
    SUM(CASE WHEN DATEDIFF(DAY, DataDoc, GETDATE()) > 5 
             AND efact_Stare NOT IN ('COMPLETED', 'RESPINSA') 
             THEN 1 ELSE 0 END) AS PesteDeadline,
    CAST(SUM(CASE WHEN efact_Stare = 'COMPLETED' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS ProcentTransmise
FROM Iesiri
WHERE Is_EF = 1
  AND DataDoc >= DATEADD(WEEK, -4, GETDATE())
GROUP BY DATEPART(WEEK, DataDoc)
ORDER BY Saptamana DESC
```

### 3.2 Audit Trail pentru Factură

```sql
-- Istoricul complet al unei facturi
SELECT 
    log_dt_utc AS Timestamp,
    step AS Pas,
    action AS Actiune,
    status AS Status,
    http_status AS HTTP_Status,
    anaf_status AS ANAF_Status,
    message_short AS Mesaj,
    attempt_no AS Incercare
FROM efactura_logger
WHERE db_name = 'YourDB'
  AND table_name = 'Iesiri'
  AND id_unic = 'FAC001'
ORDER BY log_dt_utc ASC
```

### 3.3 Rate Erori pe Oră

```sql
SELECT 
    DATEPART(HOUR, log_dt_utc) AS Ora,
    COUNT(*) AS TotalOperatii,
    SUM(CASE WHEN status = 'ERR' THEN 1 ELSE 0 END) AS Erori,
    CAST(SUM(CASE WHEN status = 'ERR' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS ProcentErori
FROM efactura_logger
WHERE log_dt_utc >= CAST(CAST(GETDATE() AS DATE) AS DATETIME)
GROUP BY DATEPART(HOUR, log_dt_utc)
ORDER BY Ora
```

### 3.4 Timp Mediu de Procesare

```sql
WITH ProcessingTimes AS (
    SELECT 
        db_name,
        id_unic,
        MIN(CASE WHEN step = 'GENERARE' THEN log_dt_utc END) AS StartTime,
        MAX(CASE WHEN step = 'DESCARCARE' AND status = 'OK' THEN log_dt_utc END) AS EndTime
    FROM efactura_logger
    WHERE log_dt_utc >= DATEADD(DAY, -7, GETUTCDATE())
    GROUP BY db_name, id_unic
    HAVING MAX(CASE WHEN step = 'DESCARCARE' AND status = 'OK' THEN log_dt_utc END) IS NOT NULL
)
SELECT 
    AVG(DATEDIFF(MINUTE, StartTime, EndTime)) AS AvgMinutes,
    MIN(DATEDIFF(MINUTE, StartTime, EndTime)) AS MinMinutes,
    MAX(DATEDIFF(MINUTE, StartTime, EndTime)) AS MaxMinutes,
    COUNT(*) AS CompletedInvoices
FROM ProcessingTimes
```

## 4. Checklist Operațional Zilnic

- [ ] Verifică status job (rulează fără erori?)
- [ ] Verifică facturi aproape de deadline (<48h)
- [ ] Verifică erori în ultimele 24h
- [ ] Verifică facturi blocate (IN_PROGRES > 1h)
- [ ] Verifică throughput (facturi procesate/oră)
- [ ] Backup log-uri (dacă > 1M înregistrări)

## 5. Escalare Probleme

### Nivel 1: Self-Service
- Verifică log-uri în `efactura_logger`
- Consultă documentația
- Retry manual cu `EFA_ProcessOne`

### Nivel 2: Admin SQL Server
- Verifică job history
- Verifică xp_cmdshell enabled
- Verifică permisiuni

### Nivel 3: Developer
- Analiză cod EFAgent
- Debug Chilkat
- Update XSD schemas

### Nivel 4: ANAF Support
- Probleme OAuth2
- Downtime API
- Schimbări specificații

---

**Ultima actualizare:** 2024-12-04  
**Versiune document:** 1.0
