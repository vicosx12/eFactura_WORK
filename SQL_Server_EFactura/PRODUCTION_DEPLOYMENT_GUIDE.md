# Ghid de Deployment Producție: RO e-Factura Automation

## Versiune: 1.2 - PRODUCTION READY
**Data:** 2025-12-04  
**Compatibilitate:** SQL Server 2012 SP1+

---

## ⚠️ PRE-REQUISITE CRITICE PENTRU PRODUCȚIE

### 1. Chilkat Library - OBLIGATORIU
**Status:** ❌ **NU ESTE INCLUS** - Trebuie instalat manual

**Pași pentru instalare:**
1. Cumpără licență Chilkat de la: https://www.chilkatsoft.com/purchase.asp
2. Descarcă DLL pentru .NET 6.0: https://www.chilkatsoft.com/downloads.asp
3. Extrage arhiva în `C:\Chilkat\`
4. Copie `ChilkatDotNet6.dll` în `C:\EFAgent\` (după compilare)
5. Activează licența conform instrucțiunilor Chilkat

**⚠️ NOTĂ IMPORTANTĂ:** Fără Chilkat DLL instalat, aplicația va arunca excepții la runtime. Toate operațiile OAuth2 și HTTP necesită Chilkat.

### 2. Decomentează Codul Chilkat în Operations.cs

După instalarea Chilkat DLL, edită `EFAgent_Chilkat/src/Operations.cs` și:

```csharp
// Găsește toate secțiunile marcate cu:
/* PRODUCȚIE: Uncomment și configurează Chilkat
...
*/

// Și decomentează codul Chilkat, de exemplu:

// ÎNAINTE (cu comentarii):
/* PRODUCȚIE: Uncomment și configurează Chilkat
var http = new Chilkat.Http();
http.AuthToken = token;
*/

// DUPĂ (decommentat):
var http = new Chilkat.Http();
http.AuthToken = token;
http.Accept = "application/json";
```

### 3. Credențiale OAuth2 ANAF

**Obținere credențiale:**
1. Acesează portalul ANAF: https://www.anaf.ro/efactura
2. Creează cont organizație (dacă nu există)
3. Generează Client ID și Client Secret pentru OAuth2
4. Notează credențialele într-un loc sigur

**Configurare în settings.json:**
```json
{
  "oauth2": {
    "clientId": "YOUR_REAL_CLIENT_ID_HERE",
    "clientSecret": "YOUR_REAL_CLIENT_SECRET_HERE",
    "tokenStore": "C:\\EFAgent\\tokens"
  }
}
```

### 4. Schema XSD Oficiale

**Descărcare:**
1. Vizitează: https://www.anaf.ro/efactura (secțiunea Documentație)
2. Descarcă pachetul complet de scheme XSD pentru CIUS-RO
3. Extrage în `C:\EFAgent\schemas\`
4. Verifică că există: `C:\EFAgent\schemas\UBL-Invoice-2.1.xsd`

---

## CHECKLIST DEPLOYMENT PRODUCȚIE

### Faza 1: Pregătire Environment

- [ ] **SQL Server 2012 SP1+ instalat și verificat**
  ```sql
  SELECT @@VERSION
  -- Verifică că este 2012 SP1+ sau mai nou
  ```

- [ ] **SQL Server Agent activat și rulând**
  ```sql
  EXEC xp_servicecontrol 'QueryState', 'SQLServerAgent'
  -- Trebuie să returneze 'Running'
  ```

- [ ] **Chilkat DLL cumpărat și instalat**
  - Licență activată
  - DLL copiat în director aplicație

- [ ] **Credențiale OAuth2 ANAF obținute**
  - Client ID
  - Client Secret
  - Testate manual (ex: Postman)

- [ ] **XSD-uri oficiale descărcate**
  - Toate fișierele .xsd în `C:\EFAgent\schemas\`
  - Verificat UBL-Invoice-2.1.xsd

### Faza 2: Compilare EFAgent

```powershell
# 1. Navighează la directorul proiect
cd C:\path\to\eFactura_WORK\EFAgent_Chilkat\src

# 2. Verifică că ai .NET 6.0 SDK
dotnet --version

# 3. Adaugă referința Chilkat în EFAgent.csproj
# Editează EFAgent.csproj și adaugă:
<ItemGroup>
  <Reference Include="ChilkatDotNet6">
    <HintPath>C:\Chilkat\ChilkatDotNet6.dll</HintPath>
  </Reference>
</ItemGroup>

# 4. Decomentează codul Chilkat în Operations.cs
# (Vezi secțiunea 2 de mai sus)

# 5. Compilează în Release mode
dotnet build -c Release

# 6. Verifică că nu sunt erori
# Output-ul trebuie să arate: Build succeeded. 0 Warning(s). 0 Error(s).

# 7. Copiază fișierele în locația finală
mkdir C:\EFAgent
copy bin\Release\net6.0\* C:\EFAgent\
copy C:\Chilkat\ChilkatDotNet6.dll C:\EFAgent\
```

### Faza 3: Configurare EFAgent

```powershell
# 1. Creează directoarele necesare
mkdir C:\EFAgent\config
mkdir C:\EFAgent\tokens
mkdir C:\EFAgent\logs
mkdir C:\EFAgent\schemas

# 2. Editează C:\EFAgent\config\settings.json cu credențiale reale
notepad C:\EFAgent\config\settings.json

# 3. Copiază XSD-urile în C:\EFAgent\schemas\

# 4. Testează EFAgent manual
cd C:\EFAgent
.\EFAgent.exe --help
```

### Faza 4: Deployment SQL Server

```sql
-- 1. Conectare ca sysadmin
-- Use SSMS sau Azure Data Studio

-- 2. Rulează DDL în ordine (pe master database)
USE [master]
GO
:r C:\path\to\SQL_Server_EFactura\DDL\01_Create_efactura_logger.sql
GO

-- 3. Rulează DDL pe fiecare bază de date care va trimite facturi
-- !!! IMPORTANT: Editează __NUMELE_BAZEI_DE_DATE__ cu numele real !!!
USE [NumeBazaRealaTa]
GO
:r C:\path\to\SQL_Server_EFactura\DDL\02_Alter_Iesiri_Export_Tables.sql
GO

-- 4. Rulează Stored Procedures în ordine (pe master)
USE [master]
GO
:r C:\path\to\SQL_Server_EFactura\StoredProcedures\01_Helper_Functions.sql
:r C:\path\to\SQL_Server_EFactura\StoredProcedures\02_Agent_Wrapper.sql
:r C:\path\to\SQL_Server_EFactura\StoredProcedures\03_ProcessOne.sql
:r C:\path\to\SQL_Server_EFactura\StoredProcedures\04_ProcessDb_ScanAll.sql
GO

-- 5. Verificare instalare
SELECT name, create_date 
FROM sys.objects 
WHERE type = 'P' AND name LIKE 'EFA_%'
ORDER BY name
GO
```

### Faza 5: Configurare SQL Server Agent Job

```sql
-- 1. Enable xp_cmdshell (dacă nu e deja activat)
EXEC sp_configure 'show advanced options', 1
RECONFIGURE
EXEC sp_configure 'xp_cmdshell', 1
RECONFIGURE
GO

-- 2. Creează job
:r C:\path\to\SQL_Server_EFactura\Jobs\01_Create_EFA_Job.sql
GO

-- 3. IMPORTANT: Editează job-ul cu parametri corecți
-- În SSMS → SQL Server Agent → Jobs → EFA_Background_Processor → Properties
-- Step 2 "Procesare Facturi" → Edit Command
-- Setează:
--   @efagent_path = 'C:\EFAgent\EFAgent.exe'
--   @environment = 'prod'  -- sau 'test' pentru testing

-- 4. Nu activa job-ul încă! Testează mai întâi manual
```

### Faza 6: Testare Pre-Producție

```sql
-- 1. Creează factură de test în baza ta
INSERT INTO [YourDB].[dbo].[Iesiri] (
    Nir, BT_11, BT_13, DataDoc, Is_EF, eFactura,
    Furnizor, CIF_Furnizor, Client, CIF_Client,
    Total, Valuta
)
VALUES (
    'TEST_PROD_001', 'FAC-TEST-PROD-001', GETDATE(), GETDATE(), 1, 1,
    'Compania Ta SRL', 'RO12345678', 'Client Test SRL', 'RO87654321',
    1000.00, 'RON'
)
GO

-- 2. Testează manual procesarea
DECLARE @TestRunId UNIQUEIDENTIFIER = NEWID()

EXEC dbo.EFA_ProcessOne
    @db_name = 'YourDB',
    @table_name = 'Iesiri',
    @id_unic = 'TEST_PROD_001',
    @run_id = @TestRunId,
    @efagent_path = 'C:\EFAgent\EFAgent.exe',
    @conn_string = 'Server=localhost;Database=YourDB;Trusted_Connection=True;',
    @environment = 'test'  -- Folosește 'test' pentru început!
GO

-- 3. Verifică rezultatul
SELECT * FROM efactura_logger 
WHERE run_id = @TestRunId 
ORDER BY log_dt_utc DESC
GO

SELECT Nir, efact_Stare, efact_Detalii, Id_Solicitare, Id_Descarcare, Recipisa
FROM [YourDB].[dbo].[Iesiri]
WHERE Nir = 'TEST_PROD_001'
GO

-- 4. Dacă totul merge bine, șterge testul
DELETE FROM [YourDB].[dbo].[Iesiri] WHERE Nir = 'TEST_PROD_001'
GO
```

### Faza 7: Go-Live Producție

```sql
-- 1. Setează environment la 'prod' în job
-- SSMS → Jobs → EFA_Background_Processor → Properties → Step 2
-- Schimbă @environment = 'prod'

-- 2. Activează job-ul
EXEC msdb.dbo.sp_update_job 
    @job_name = 'EFA_Background_Processor',
    @enabled = 1
GO

-- 3. Monitorizează prima rulare
SELECT TOP 10 * 
FROM msdb.dbo.sysjobhistory 
WHERE job_id = (
    SELECT job_id 
    FROM msdb.dbo.sysjobs 
    WHERE name = 'EFA_Background_Processor'
)
ORDER BY instance_id DESC
GO

-- 4. Verifică log-urile
SELECT TOP 100 *
FROM efactura_logger
ORDER BY log_dt_utc DESC
GO
```

---

## MONITORIZARE POST-DEPLOYMENT

### Dashboard Operațional (Rulează zilnic)

```sql
-- 1. Health Check General
SELECT 
    COUNT(*) AS TotalFacturi,
    SUM(CASE WHEN efact_Stare = 'COMPLETED' THEN 1 ELSE 0 END) AS Finalizate,
    SUM(CASE WHEN efact_Stare = 'RESPINSA' THEN 1 ELSE 0 END) AS Respinse,
    SUM(CASE WHEN efact_Stare IN ('NEGNERATA', 'TRANSMITERE_ES') THEN 1 ELSE 0 END) AS Erori,
    SUM(CASE WHEN DATEDIFF(DAY, DataDoc, GETDATE()) > 4 AND efact_Stare NOT IN ('COMPLETED', 'RESPINSA') THEN 1 ELSE 0 END) AS AlertaDeadline
FROM Iesiri
WHERE Is_EF = 1
  AND DataDoc >= DATEADD(DAY, -7, GETDATE())

-- 2. Erori ultimele 24h
SELECT TOP 20
    log_dt_utc,
    db_name,
    id_unic,
    step,
    message_short
FROM efactura_logger
WHERE status = 'ERR'
  AND log_dt_utc > DATEADD(HOUR, -24, GETUTCDATE())
ORDER BY log_dt_utc DESC

-- 3. Facturi aproape de deadline
SELECT 
    Nir,
    BT_11,
    DataDoc,
    master.dbo.EFA_CalculateDeadline(DataDoc) AS Deadline,
    DATEDIFF(HOUR, GETDATE(), master.dbo.EFA_CalculateDeadline(DataDoc)) AS OreRamase,
    efact_Stare
FROM Iesiri
WHERE Is_EF = 1
  AND efact_Stare NOT IN ('COMPLETED', 'RESPINSA')
  AND DATEDIFF(HOUR, GETDATE(), master.dbo.EFA_CalculateDeadline(DataDoc)) < 48
ORDER BY OreRamase ASC
```

### Alerting

Configurează alerte pentru:
- ❌ Job failed (immediate)
- ⚠️ Facturi cu deadline < 24h (2x pe zi)
- ⚠️ Rate erori > 10% (orar)
- ℹ️ Queue size > 100 facturi (zilnic)

---

## ROLLBACK PLAN

Dacă ceva merge prost:

```sql
-- 1. STOP job imediat
EXEC msdb.dbo.sp_stop_job @job_name = 'EFA_Background_Processor'
GO

-- 2. Disable job
EXEC msdb.dbo.sp_update_job 
    @job_name = 'EFA_Background_Processor',
    @enabled = 0
GO

-- 3. Analizează problemele
SELECT * FROM efactura_logger 
WHERE status = 'ERR' 
  AND log_dt_utc > DATEADD(HOUR, -1, GETUTCDATE())
ORDER BY log_dt_utc DESC

-- 4. Resetează facturi blocate (dacă e cazul)
UPDATE Iesiri
SET efact_Stare = 'PENDING',
    efact_Processing_Host = NULL,
    efact_Processing_Time = NULL
WHERE efact_Stare = 'IN_PROGRES'
  AND DATEDIFF(HOUR, efact_Processing_Time, GETDATE()) > 1

-- 5. După fix, re-enable job
EXEC msdb.dbo.sp_update_job 
    @job_name = 'EFA_Background_Processor',
    @enabled = 1
```

---

## SUPORT ȘI CONTACTE

### Documentație
- **Arhitectură**: `SQL_Server_EFactura/Documentation/01_Arhitectura_si_Rationament.md`
- **Instalare**: `SQL_Server_EFactura/Documentation/02_Instalare_si_Configurare.md`
- **Operare**: `SQL_Server_EFactura/Documentation/03_Operare_si_Testare.md`

### Resurse Externe
- **ANAF e-Factura**: https://www.anaf.ro/efactura
- **Chilkat Documentation**: https://www.chilkatsoft.com/documentation.asp
- **CIUS-RO Specifications**: https://mfinante.gov.ro/documents/35673/243799/CIUS-RO_v1.0.1.pdf

### Troubleshooting Rapid

| Problemă | Soluție |
|----------|---------|
| "Chilkat library nu este disponibilă" | Instalează Chilkat DLL și decomentează codul în Operations.cs |
| "OAuth2 failed" | Verifică credențiale în settings.json |
| "Schema XSD nu a fost găsită" | Descarcă XSD-uri oficiale în C:\EFAgent\schemas\ |
| "xp_cmdshell nu este activat" | Rulează: `EXEC sp_configure 'xp_cmdshell', 1; RECONFIGURE` |
| Job nu rulează | Verifică SQL Server Agent service: `EXEC xp_servicecontrol 'QueryState', 'SQLServerAgent'` |

---

## CHECKLIST FINAL

### Înainte de Go-Live:
- [ ] Chilkat DLL instalat și licență activată
- [ ] Cod Chilkat decommentat în Operations.cs
- [ ] Credențiale OAuth2 ANAF reale în settings.json
- [ ] XSD-uri oficiale descărcate
- [ ] EFAgent compilat în Release mode
- [ ] DDL rulat pe toate bazele de date
- [ ] Stored procedures instalate
- [ ] Job creat și configurat (DAR NU ACTIVAT încă)
- [ ] Test manual executat cu succes pe environment 'test'
- [ ] Monitorizare și alerting configurate
- [ ] Plan de rollback pregătit
- [ ] Echipa notificată despre go-live

### După Go-Live:
- [ ] Job activat
- [ ] Prima rulare monitorizată în timp real
- [ ] Verificat că facturile ajung la ANAF
- [ ] Dashboard monitorizat primele 24h
- [ ] Raportare către management

---

**Deployment completat cu succes! 🎉**

**Versiune:** 1.2 PRODUCTION  
**Data:** 2025-12-04  
**Status:** ✅ GATA PENTRU PRODUCȚIE (după completare Chilkat)
