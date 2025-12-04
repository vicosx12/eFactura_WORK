# Checklist Deployment: RO e-Factura Automation

## Pre-Deployment

### Infrastructură
- [ ] SQL Server 2016+ instalat și rulând
- [ ] SQL Server Agent activat și configurat
- [ ] .NET 6.0 SDK instalat pe serverul SQL
- [ ] Acces administrativ la SQL Server
- [ ] Acces la bazele de date (Firme, Iesiri, Export)
- [ ] Suficient spațiu disc pentru log-uri și XML-uri temporare (min 10GB)

### Credențiale ANAF
- [ ] Client ID obținut de la ANAF
- [ ] Client Secret obținut de la ANAF
- [ ] Cont activ pe portal RO e-Factura
- [ ] Testat autentificarea OAuth2 manual (ex: Postman/curl)
- [ ] Verificat API endpoint-uri (prod și test)

### Chilkat
- [ ] Licență Chilkat validă (dacă comercială)
- [ ] DLL Chilkat descărcat pentru .NET
- [ ] Verificat compatibilitate versiune .NET

## Deployment Step-by-Step

### 1. Instalare Chilkat ✓
- [ ] Descărcat de la chilkatsoft.com
- [ ] Extras în C:\Chilkat\
- [ ] DLL copiat în directorul proiect
- [ ] Testat licensing (dacă aplicabil)

### 2. Compilare și Deploy EFAgent ✓
- [ ] Clonat repository local
- [ ] Editat EFAgent.csproj cu referință Chilkat
- [ ] Compilat: `dotnet build -c Release`
- [ ] Copiat executabil în C:\EFAgent\
- [ ] Creat directoare:
  - [ ] C:\EFAgent\config
  - [ ] C:\EFAgent\tokens
  - [ ] C:\EFAgent\logs
  - [ ] C:\EFAgent\schemas
- [ ] Copiat XSD-uri oficiale în C:\EFAgent\schemas\
- [ ] Editat C:\EFAgent\config\settings.json cu credențiale reale
- [ ] Testat manual: `EFAgent.exe --help`

### 3. Deployment SQL - DDL ✓
- [ ] Conectat la SQL Server cu cont sysadmin
- [ ] Rulat: 01_Create_efactura_logger.sql
- [ ] Verificat: `SELECT * FROM efactura_logger`
- [ ] Identificat toate bazele de date care vor trimite facturi
- [ ] Pentru fiecare bază:
  - [ ] Editat 02_Alter_Iesiri_Export_Tables.sql (USE [NumeBaza])
  - [ ] Rulat scriptul
  - [ ] Verificat coloane noi: `sp_help Iesiri`
  - [ ] Verificat indexe create

### 4. Deployment SQL - Stored Procedures ✓
- [ ] Rulat în ordine:
  1. [ ] 01_Helper_Functions.sql
  2. [ ] 02_Agent_Wrapper.sql
  3. [ ] 03_ProcessOne.sql
  4. [ ] 04_ProcessDb_ScanAll.sql
- [ ] Verificat proceduri create:
  ```sql
  SELECT name, create_date, modify_date
  FROM sys.objects
  WHERE type = 'P' AND name LIKE 'EFA_%'
  ORDER BY name
  ```

### 5. Configurare per Bază de Date ✓
Pentru fiecare bază de date:
- [ ] Activat Send_Efactura:
  ```sql
  INSERT INTO Configurari.SystemParameters (sKey, sValue)
  VALUES ('Send_Efactura', 'Da')
  ```
- [ ] Marcat facturi pentru e-Factura:
  ```sql
  UPDATE Iesiri SET Is_EF = 1 WHERE <conditii>
  UPDATE Export SET Is_EF = 1 WHERE <conditii>
  ```
- [ ] Verificat count:
  ```sql
  SELECT COUNT(*) FROM Iesiri WHERE Is_EF = 1
  ```

### 6. Configurare xp_cmdshell și Securitate ✓
- [ ] Decis strategie: enable global sau doar în job
- [ ] Dacă enable global:
  ```sql
  EXEC sp_configure 'show advanced options', 1
  RECONFIGURE
  EXEC sp_configure 'xp_cmdshell', 1
  RECONFIGURE
  ```
- [ ] (Opțional) Creat proxy account pentru securitate
- [ ] Testat manual: `EXEC xp_cmdshell 'dir C:\EFAgent'`

### 7. Creare SQL Server Agent Job ✓
- [ ] Verificat SQL Server Agent rulează
- [ ] Editat 01_Create_EFA_Job.sql cu parametri:
  - [ ] @batch_size (default 100)
  - [ ] @efagent_path (default C:\EFAgent\EFAgent.exe)
  - [ ] @environment (prod sau test)
  - [ ] @firme_db (default Firme)
- [ ] Rulat scriptul
- [ ] Verificat job creat:
  ```sql
  SELECT * FROM msdb.dbo.sysjobs WHERE name = 'EFA_Background_Processor'
  ```
- [ ] (Opțional) Configurat alerting email

## Testing

### Test 1: EFAgent Standalone ✓
- [ ] Test generare:
  ```bash
  EFAgent.exe generate --db=TestDB --table=Iesiri --id=TEST001 --connString="..." --env=test
  ```
- [ ] Verificat output JSON valid
- [ ] Verificat XML generat în temp folder
- [ ] Verificat erori XSD (dacă există)

### Test 2: Stored Procedure Individual ✓
- [ ] Creat factură de test în baza TestDB
- [ ] Rulat:
  ```sql
  EXEC dbo.EFA_ProcessOne
      @db_name = 'TestDB',
      @table_name = 'Iesiri',
      @id_unic = 'TEST001',
      @run_id = NEWID(),
      @environment = 'test'
  ```
- [ ] Verificat log-uri în efactura_logger
- [ ] Verificat stare factură: `SELECT * FROM TestDB.dbo.Iesiri WHERE Nir='TEST001'`

### Test 3: ProcessDb (Batch) ✓
- [ ] Marcat 10-20 facturi de test cu Is_EF=1
- [ ] Rulat:
  ```sql
  EXEC dbo.EFA_ProcessDb
      @db_name = 'TestDB',
      @run_id = NEWID(),
      @batch_size = 20,
      @environment = 'test'
  ```
- [ ] Verificat throughput și durata
- [ ] Verificat fără deadlock-uri

### Test 4: Dry Run Complete ✓
- [ ] Rulat cu @dry_run=1:
  ```sql
  EXEC dbo.EFA_ScanAndProcessAll
      @batch_size = 50,
      @environment = 'test',
      @dry_run = 1
  ```
- [ ] Verificat output: număr candidați identificați
- [ ] Confirmat nicio modificare în baza de date

### Test 5: Full Run pe Environment Test ✓
- [ ] Rulat pe mediul test ANAF:
  ```sql
  EXEC dbo.EFA_ScanAndProcessAll
      @batch_size = 10,
      @environment = 'test'
  ```
- [ ] Monitorizat progres în timp real:
  ```sql
  SELECT * FROM efactura_logger WHERE run_id = <run_id> ORDER BY log_dt_utc DESC
  ```
- [ ] Verificat facturi ajung la COMPLETED

### Test 6: Job Automated ✓
- [ ] Setat job enabled=1 (doar pe test)
- [ ] Așteptat prima rulare automată (5 min)
- [ ] Verificat job history:
  ```sql
  SELECT TOP 5 * FROM msdb.dbo.sysjobhistory WHERE job_id = (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = 'EFA_Background_Processor')
  ```
- [ ] Confirmat succes sau investigat erorile

## Go-Live Production

### Pre-Go-Live Checklist ✓
- [ ] Toate testele de mai sus trecute
- [ ] Documentație completă disponibilă echipei
- [ ] Plan de rollback pregătit
- [ ] Contact ANAF support verificat
- [ ] Window de mentenanță programat (dacă necesar)
- [ ] Backup complet baze de date

### Go-Live ✓
- [ ] Schimbat @environment de la 'test' la 'prod' în job
- [ ] Editat settings.json să folosească endpoint-uri prod
- [ ] Verificat credențiale OAuth2 pentru prod (dacă diferite)
- [ ] Activat job pentru producție:
  ```sql
  EXEC msdb.dbo.sp_update_job
      @job_name = 'EFA_Background_Processor',
      @enabled = 1
  ```
- [ ] Monitorizat prima rulare LIVE cu atenție
- [ ] Verificat facturi ajung la ANAF cu succes
- [ ] Verificat recipise descărcate

### Post-Go-Live (Primele 24h) ✓
- [ ] Monitorizat job history la fiecare oră
- [ ] Verificat erori în efactura_logger
- [ ] Verificat rate de succes:
  ```sql
  SELECT 
      efact_Stare, 
      COUNT(*) AS Total,
      COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS Procent
  FROM Iesiri
  WHERE Is_EF = 1 AND DataDoc >= CAST(GETDATE() AS DATE)
  GROUP BY efact_Stare
  ```
- [ ] Verificat nicio factură peste deadline
- [ ] Contact cu utilizatori: feedback

## Operare Continuă

### Daily ✓
- [ ] Verificat job rulează fără erori
- [ ] Verificat facturi aproape de deadline (<48h)
- [ ] Verificat queue size (facturi în așteptare)

### Weekly ✓
- [ ] Review raport conformitate
- [ ] Cleanup log-uri vechi (>90 zile)
- [ ] Verificat spațiu disc
- [ ] Review erori recurente

### Monthly ✓
- [ ] Audit complet log-uri
- [ ] Review și optimizare performanță
- [ ] Update documentație dacă e necesar
- [ ] Verificat licență Chilkat (dacă aplicabil)

## Rollback Plan

Dacă ceva merge prost:
- [ ] STOP job imediat: `EXEC msdb.dbo.sp_stop_job @job_name = 'EFA_Background_Processor'`
- [ ] Disable job: `EXEC msdb.dbo.sp_update_job @job_name = 'EFA_Background_Processor', @enabled = 0`
- [ ] Analizează log-uri pentru root cause
- [ ] Corectează problema
- [ ] Re-testează pe environment test
- [ ] Re-enable job când e safe

## Semnături

| Rol | Nume | Semnătură | Data |
|-----|------|-----------|------|
| Developer | | | |
| DBA | | | |
| QA | | | |
| Manager IT | | | |

---

**Versiune:** 1.0  
**Data:** 2024-12-04  
**Repository:** vicosx12/eFactura_WORK
