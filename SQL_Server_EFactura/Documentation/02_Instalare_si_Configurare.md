# Ghid de Instalare și Configurare: RO e-Factura Automation

## 1. Cerințe Preliminare

### 1.1 Software
- **SQL Server**: 2012 SP1+ sau mai nou (2014+ recomandat, 2019+ optimal)
- **SQL Server Agent**: Activat și rulând
- **.NET SDK**: 6.0 sau mai nou (pentru compilare EFAgent)
- **Chilkat Library**: Licență validă și DLL instalat
- **Visual Studio**: 2022 sau VS Code (opțional, pentru dezvoltare)

**⚠️ NOTĂ IMPORTANTĂ - Compatibilitate SQL Server 2012:**
Această versiune este compatibilă cu **SQL Server 2012 SP1+**. Soluția include implementări custom pentru funcționalitate JSON (parsare, validare) și concatenare string-uri, care au fost introduse nativ în SQL Server 2016+. Funcția `dbo.EFA_ParseJsonValue` înlocuiește `JSON_VALUE()`, iar concatenarea XML PATH înlocuiește `STRING_AGG()`.

### 1.2 Permisiuni
- Acces **sysadmin** pe SQL Server (pentru instalare)
- Cont Windows cu drepturi de execuție `xp_cmdshell`
- Acces la bazele de date Firme, Iesiri, Export

### 1.3 Credențiale ANAF
- **Client ID** pentru OAuth2
- **Client Secret** pentru OAuth2
- Cont activ pe portal ANAF RO e-Factura

## 2. Instalare Pas cu Pas

### Pasul 1: Instalare Chilkat

1. Descarcă Chilkat pentru .NET de la: https://www.chilkatsoft.com/downloads.asp
2. Alege versiunea corespunzătoare (.NET Framework 4.8 sau .NET 6.0)
3. Instalează biblioteca:
   ```
   - Extrage arhiva în C:\Chilkat\
   - Adaugă C:\Chilkat\ la PATH (opțional)
   ```
4. Activează licența Chilkat (dacă ai una comercială)

### Pasul 2: Compilare EFAgent

1. Navighează la directorul `EFAgent_Chilkat/src/`:
   ```bash
   cd C:\path\to\eFactura_WORK\EFAgent_Chilkat\src
   ```

2. Editează `EFAgent.csproj` și adaugă referința Chilkat:
   ```xml
   <ItemGroup>
     <Reference Include="ChilkatDotNet48">
       <HintPath>C:\Chilkat\ChilkatDotNet48.dll</HintPath>
     </Reference>
   </ItemGroup>
   ```

3. Compilează proiectul:
   ```bash
   dotnet build -c Release
   ```

4. Copiază executabilul în locația dorită:
   ```bash
   mkdir C:\EFAgent
   copy bin\Release\net6.0\* C:\EFAgent\
   ```

### Pasul 3: Configurare EFAgent

1. Editează `C:\EFAgent\config\settings.json`:
   ```json
   {
     "oauth2": {
       "clientId": "YOUR_ACTUAL_CLIENT_ID",
       "clientSecret": "YOUR_ACTUAL_SECRET",
       "tokenUrl": "https://logincert.anaf.ro/anaf-oauth2/v1/token",
       "tokenStore": "C:\\EFAgent\\tokens",
       "refreshBeforeExpiry": 300
     },
     "endpoints": {
       "prod": "https://api.anaf.ro/prod/FCTEL/rest/",
       "test": "https://api.anaf.ro/test/FCTEL/rest/"
     },
     "xsdSchemaPath": "C:\\EFAgent\\schemas\\UBL-Invoice-2.1.xsd",
     "maxRetries": 3,
     "retryDelaySeconds": 30
   }
   ```

2. Creează directoarele necesare:
   ```bash
   mkdir C:\EFAgent\tokens
   mkdir C:\EFAgent\logs
   mkdir C:\EFAgent\schemas
   ```

3. Copiază XSD-urile oficiale RO e-Factura în `C:\EFAgent\schemas\`
   - Descarcă de la: https://www.anaf.ro/efactura
   - Asigură-te că ai `UBL-Invoice-2.1.xsd` și dependențele

### Pasul 4: Instalare SQL Server - DDL

1. Conectează-te la SQL Server cu SSMS sau Azure Data Studio

2. Rulează scripturile DDL în ordine:
   ```sql
   -- A. Creează tabela de logging
   :r C:\path\to\SQL_Server_EFactura\DDL\01_Create_efactura_logger.sql
   
   -- B. Modifică tabelele Iesiri și Export în fiecare bază
   -- NOTĂ: Editează scriptul pentru fiecare bază de date
   -- Înlocuiește: USE [NumeBazaDeDate]
   :r C:\path\to\SQL_Server_EFactura\DDL\02_Alter_Iesiri_Export_Tables.sql
   ```

### Pasul 5: Instalare SQL Server - Stored Procedures

Rulează procedurile în ordine:

```sql
-- 1. Funcții helper
:r C:\path\to\SQL_Server_EFactura\StoredProcedures\01_Helper_Functions.sql

-- 2. Wrapper EFAgent
:r C:\path\to\SQL_Server_EFactura\StoredProcedures\02_Agent_Wrapper.sql

-- 3. ProcessOne
:r C:\path\to\SQL_Server_EFactura\StoredProcedures\03_ProcessOne.sql

-- 4. ProcessDb și ScanAll
:r C:\path\to\SQL_Server_EFactura\StoredProcedures\04_ProcessDb_ScanAll.sql
```

### Pasul 6: Creare SQL Server Agent Job

1. Asigură-te că SQL Server Agent rulează:
   ```sql
   -- Verificare status
   EXEC xp_servicecontrol 'QueryState', 'SQLServerAgent'
   ```

2. Creează job-ul:
   ```sql
   :r C:\path\to\SQL_Server_EFactura\Jobs\01_Create_EFA_Job.sql
   ```

3. Verifică job-ul creat:
   ```sql
   SELECT * FROM msdb.dbo.sysjobs WHERE name = 'EFA_Background_Processor'
   ```

### Pasul 7: Configurare xp_cmdshell și Securitate

1. **Opțiunea 1: Enable xp_cmdshell global** (mai puțin sigur)
   ```sql
   EXEC sp_configure 'show advanced options', 1
   RECONFIGURE
   EXEC sp_configure 'xp_cmdshell', 1
   RECONFIGURE
   ```

2. **Opțiunea 2: Enable doar în job** (recomandat)
   - Job-ul activează/dezactivează automat
   - Vezi Step 1 din job

3. **Creează proxy account** (opțional, pentru securitate suplimentară):
   ```sql
   -- Creează credential
   CREATE CREDENTIAL [EFAgentCredential]
   WITH IDENTITY = 'DOMAIN\EFAgentUser',
   SECRET = 'StrongPassword123!'
   
   -- Creează proxy
   USE msdb
   EXEC sp_add_proxy 
       @proxy_name = 'EFAgentProxy',
       @credential_name = 'EFAgentCredential',
       @enabled = 1
   
   -- Acordă permisiuni subsistem
   EXEC sp_grant_proxy_to_subsystem 
       @proxy_name = 'EFAgentProxy',
       @subsystem_id = 3 -- CmdExec
   
   -- Asociază proxy la job (manual în job steps)
   ```

## 3. Configurare per Bază de Date

Pentru fiecare bază de date care va trimite facturi:

1. **Activează e-Factura în SystemParameters**:
   ```sql
   USE [NumeBaza]
   GO
   
   INSERT INTO Configurari.SystemParameters (sKey, sValue)
   VALUES ('Send_Efactura', 'Da')
   ```

2. **Configurează credențiale OAuth2** (criptat):
   ```sql
   -- TODO: Implementare criptare cu Chilkat
   INSERT INTO Configurari.SystemParameters (sKey, sValue)
   VALUES 
       ('eFactura_ClientID', '<ID_criptat>'),
       ('eFactura_SecretID', '<Secret_criptat>')
   ```

3. **Marchează facturile pentru e-Factura**:
   ```sql
   UPDATE Iesiri
   SET Is_EF = 1
   WHERE DataDoc >= '2024-01-01'
     AND eFactura = 1
   ```

## 4. Testare

### 4.1 Test Dry Run

```sql
-- Test fără modificări reale
EXEC dbo.EFA_ScanAndProcessAll 
    @batch_size = 10,
    @dry_run = 1
```

### 4.2 Test pe Mediu Test ANAF

```sql
EXEC dbo.EFA_ScanAndProcessAll 
    @batch_size = 5,
    @environment = 'test',
    @dry_run = 0
```

### 4.3 Test EFAgent Manual

```bash
# Test generare XML
C:\EFAgent\EFAgent.exe generate ^
    --db="TestDB" ^
    --table="Iesiri" ^
    --id="TEST001" ^
    --connString="Server=localhost;Database=TestDB;Trusted_Connection=True;" ^
    --env=test

# Test upload
C:\EFAgent\EFAgent.exe upload ^
    --db="TestDB" ^
    --table="Iesiri" ^
    --id="TEST001" ^
    --connString="Server=localhost;Database=TestDB;Trusted_Connection=True;" ^
    --env=test
```

### 4.4 Monitorizare Logging

```sql
-- Verifică ultimele 100 log-uri
SELECT TOP 100 *
FROM efactura_logger
ORDER BY log_dt_utc DESC

-- Verifică erori
SELECT *
FROM efactura_logger
WHERE status = 'ERR'
  AND log_dt_utc > DATEADD(HOUR, -24, GETUTCDATE())
ORDER BY log_dt_utc DESC
```

## 5. Pornire în Producție

1. **Activează job-ul**:
   ```sql
   EXEC msdb.dbo.sp_update_job 
       @job_name = 'EFA_Background_Processor', 
       @enabled = 1
   ```

2. **Monitorizează prima rulare**:
   ```sql
   -- Verifică istoricul job
   SELECT TOP 10 
       jh.run_date,
       jh.run_time,
       jh.run_status,
       jh.run_duration,
       jh.message
   FROM msdb.dbo.sysjobhistory jh
   INNER JOIN msdb.dbo.sysjobs j ON jh.job_id = j.job_id
   WHERE j.name = 'EFA_Background_Processor'
   ORDER BY jh.instance_id DESC
   ```

3. **Verifică facturi procesate**:
   ```sql
   SELECT 
       db_name,
       efact_Stare,
       COUNT(*) AS Total
   FROM Iesiri
   WHERE Is_EF = 1
   GROUP BY db_name, efact_Stare
   ORDER BY db_name, efact_Stare
   ```

## 6. Troubleshooting

### Problemă: xp_cmdshell nu funcționează

**Soluție**:
```sql
-- Verifică configurația
SELECT * FROM sys.configurations WHERE name = 'xp_cmdshell'

-- Activează dacă e necesar
EXEC sp_configure 'show advanced options', 1
RECONFIGURE
EXEC sp_configure 'xp_cmdshell', 1
RECONFIGURE
```

### Problemă: EFAgent returnează eroare OAuth2

**Soluție**:
1. Verifică credențialele în `settings.json`
2. Testează manual token-ul:
   ```bash
   curl -X POST https://logincert.anaf.ro/anaf-oauth2/v1/token ^
        -H "Content-Type: application/x-www-form-urlencoded" ^
        -d "grant_type=client_credentials&client_id=YOUR_ID&client_secret=YOUR_SECRET"
   ```
3. Verifică expirarea licenței Chilkat

### Problemă: Validare XSD eșuează

**Soluție**:
1. Verifică XSD-urile în `C:\EFAgent\schemas\`
2. Asigură-te că sunt versiunea corectă (CIUS-RO)
3. Verifică XML generat manual

### Problemă: Job nu apare în SQL Server Agent

**Soluție**:
```sql
-- Verifică serviciul
EXEC xp_servicecontrol 'QueryState', 'SQLServerAgent'

-- Start serviciu dacă e oprit
EXEC xp_servicecontrol 'Start', 'SQLServerAgent'
```

## 7. Mentenanță

### Curățare Log-uri Vechi

```sql
-- Păstrează doar ultimele 90 zile
DELETE FROM efactura_logger
WHERE log_dt_utc < DATEADD(DAY, -90, GETUTCDATE())
```

### Backup Configurații

```sql
-- Backup SystemParameters
SELECT * 
INTO Configurari.SystemParameters_Backup_20241204
FROM Configurari.SystemParameters
WHERE sKey LIKE 'eFactura%'
```

### Update EFAgent

1. Oprește job-ul
2. Compilează noua versiune
3. Înlocuiește `C:\EFAgent\EFAgent.exe`
4. Testează manual
5. Repornește job-ul

---

**Suport**: Pentru probleme, contactează echipa de suport sau consultă documentația la:
- ANAF RO e-Factura: https://www.anaf.ro/efactura
- Chilkat Documentation: https://www.chilkatsoft.com/documentation.asp
