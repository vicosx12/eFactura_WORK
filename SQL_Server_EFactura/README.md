# Soluție Completă: Automatizare RO e-Factura din SQL Server cu Chilkat

## Prezentare Generală

Această soluție oferă o **automatizare completă, robustă și idempotentă** pentru transmiterea facturilor către sistemul RO e-Factura (ANAF) direct din Microsoft SQL Server, folosind biblioteca Chilkat invocată din T-SQL.

### Caracteristici Principale

✅ **Procesare automată** - Job SQL Server Agent rulează la fiecare 5-10 minute  
✅ **Idempotentă** - Reluare sigură după întreruperi, fără duplicări  
✅ **Multi-firmă** - Suport pentru multiple baze de date  
✅ **Trasabilitate completă** - Logging detaliat pentru audit  
✅ **Respectare deadline legal** - T+5 zile calendaristice cu alerte  
✅ **Retry automat** - Exponential backoff pentru erori tranzitorii  
✅ **Validare XSD** - Verificare strictă contra specificații oficiale  
✅ **OAuth2** - Autentificare sigură cu ANAF  

## Arhitectură

```
SQL Server ──► SQL Agent Job ──► T-SQL Procedures ──► EFAgent.exe (Chilkat) ──► ANAF API
                                         │
                                         ▼
                                  efactura_logger (audit trail)
```

### Fluxul de Procesare

1. **SCANARE** - Identifică bazele active și facturile candidate
2. **GENERARE** - Creează XML UBL și validează contra XSD
3. **TRANSMITERE** - Upload către ANAF cu OAuth2
4. **STATUS** - Verifică acceptare/respingere
5. **DESCĂRCARE** - Descarcă ZIP cu recipisa

## Structura Repository

```
eFactura_WORK/
│
├── SQL_Server_EFactura/
│   ├── DDL/
│   │   ├── 01_Create_efactura_logger.sql
│   │   └── 02_Alter_Iesiri_Export_Tables.sql
│   │
│   ├── StoredProcedures/
│   │   ├── 01_Helper_Functions.sql
│   │   ├── 02_Agent_Wrapper.sql
│   │   ├── 03_ProcessOne.sql
│   │   └── 04_ProcessDb_ScanAll.sql
│   │
│   ├── Jobs/
│   │   └── 01_Create_EFA_Job.sql
│   │
│   └── Documentation/
│       ├── 01_Arhitectura_si_Rationament.md
│       ├── 02_Instalare_si_Configurare.md
│       └── 03_Operare_si_Testare.md
│
├── EFAgent_Chilkat/
│   ├── src/
│   │   ├── EFAgent.csproj
│   │   ├── Program.cs
│   │   ├── Models.cs
│   │   ├── XmlGenerator.cs
│   │   └── Operations.cs
│   │
│   └── config/
│       └── settings.json
│
└── README.md (acest fișier)
```

## Cerințe

### Software
- **SQL Server** 2012 SP1+ (2014+ recomandat, 2019+ optimal)
- **SQL Server Agent** (activat)
- **.NET 6.0 SDK** sau mai nou
- **Chilkat Library** cu licență validă
- **Visual Studio** 2022 sau VS Code (pentru compilare)

**NOTĂ IMPORTANTĂ:** Această versiune este compatibilă cu **SQL Server 2012 SP1+**. Folosește implementări custom pentru funcționalitate JSON (ISJSON, JSON_VALUE, STRING_AGG) care au fost introduse nativ în SQL Server 2016+.

### Credențiale
- **Client ID** și **Client Secret** pentru OAuth2 ANAF
- Cont activ pe portal RO e-Factura

### Permisiuni
- Acces `sysadmin` pe SQL Server (pentru instalare)
- Drepturi `xp_cmdshell` (pentru invocare EFAgent)

## Instalare Rapidă (Quick Start)

### 1. Instalare Chilkat
```bash
# Descarcă de la: https://www.chilkatsoft.com/downloads.asp
# Instalează în C:\Chilkat\
```

### 2. Compilare EFAgent
```bash
cd EFAgent_Chilkat/src
dotnet build -c Release
copy bin\Release\net6.0\* C:\EFAgent\
```

### 3. Configurare EFAgent
```bash
# Editează C:\EFAgent\config\settings.json
# Adaugă Client ID și Client Secret
```

### 4. Instalare SQL Server
```sql
-- Rulează în ordine:
:r SQL_Server_EFactura\DDL\01_Create_efactura_logger.sql
:r SQL_Server_EFactura\DDL\02_Alter_Iesiri_Export_Tables.sql
:r SQL_Server_EFactura\StoredProcedures\01_Helper_Functions.sql
:r SQL_Server_EFactura\StoredProcedures\02_Agent_Wrapper.sql
:r SQL_Server_EFactura\StoredProcedures\03_ProcessOne.sql
:r SQL_Server_EFactura\StoredProcedures\04_ProcessDb_ScanAll.sql
:r SQL_Server_EFactura\Jobs\01_Create_EFA_Job.sql
```

### 5. Test
```sql
-- Dry run
EXEC dbo.EFA_ScanAndProcessAll @batch_size = 10, @dry_run = 1

-- Test pe mediu test
EXEC dbo.EFA_ScanAndProcessAll @environment = 'test'
```

### 6. Activare Producție
```sql
EXEC msdb.dbo.sp_update_job 
    @job_name = 'EFA_Background_Processor', 
    @enabled = 1
```

## Documentație Detaliată

### 📘 [Arhitectură și Raționament](SQL_Server_EFactura/Documentation/01_Arhitectura_si_Rationament.md)
- Diagrame fluxuri
- Mașină de stări
- Idempotență și concurență
- Decizii de design

### 📗 [Instalare și Configurare](SQL_Server_EFactura/Documentation/02_Instalare_si_Configurare.md)
- Pași detaliați de instalare
- Configurare OAuth2
- Securitate și proxy accounts
- Troubleshooting

### 📙 [Operare și Testare](SQL_Server_EFactura/Documentation/03_Operare_si_Testare.md)
- Monitorizare zilnică
- Scenarii de testare
- Query-uri utile
- Escalare probleme

## Comenzi Utile

### Monitorizare
```sql
-- Dashboard rapid
SELECT efact_Stare, COUNT(*) AS Total
FROM Iesiri
WHERE Is_EF = 1 AND DataDoc >= DATEADD(MONTH, -1, GETDATE())
GROUP BY efact_Stare

-- Facturi aproape de deadline
SELECT Nir, BT_11, DataDoc, 
       master.dbo.EFA_CalculateDeadline(DataDoc) AS Deadline,
       DATEDIFF(HOUR, GETDATE(), master.dbo.EFA_CalculateDeadline(DataDoc)) AS HoursRemaining
FROM Iesiri
WHERE Is_EF = 1 
  AND efact_Stare NOT IN ('COMPLETED', 'RESPINSA')
  AND DATEDIFF(HOUR, GETDATE(), master.dbo.EFA_CalculateDeadline(DataDoc)) < 48

-- Erori recente
SELECT TOP 50 * 
FROM efactura_logger
WHERE status = 'ERR' AND log_dt_utc > DATEADD(HOUR, -24, GETUTCDATE())
ORDER BY log_dt_utc DESC
```

### Operare
```sql
-- Reprocesare factură
EXEC dbo.EFA_ProcessOne
    @db_name = 'YourDB',
    @table_name = 'Iesiri',
    @id_unic = 'FAC001',
    @run_id = NEWID()

-- Resetare factură blocată
UPDATE Iesiri
SET efact_Stare = 'PENDING',
    efact_Processing_Host = NULL,
    efact_Attempt_Count = 0
WHERE Nir = 'FAC001'
```

### EFAgent Manual
```bash
# Generare XML
EFAgent.exe generate --db=TestDB --table=Iesiri --id=FAC001 --connString="..." --env=prod

# Upload
EFAgent.exe upload --db=TestDB --table=Iesiri --id=FAC001 --connString="..." --env=prod

# Status
EFAgent.exe status --db=TestDB --table=Iesiri --id=FAC001 --id_descarcare=<ID> --env=prod

# Download
EFAgent.exe download --db=TestDB --table=Iesiri --id=FAC001 --id_descarcare=<ID> --env=prod
```

## Mașina de Stări

```
NULL/PENDING → IN_PROGRES → GENERATA → TRANSMISA → IN_ASTEPTARE_STATUS → ACCEPTATA → DESCARCARE_READY → COMPLETED
                    │            │            │                               │
                    ↓            ↓            ↓                               ↓
              NEGNERATA  TRANSMITERE_ES  RESPINSA                    DESCARCARE_ES
```

## Trasabilitate

Fiecare factură are:
- **Id_Solicitare** - Identificator unic ANAF la upload
- **Id_Descarcare** - Link la mesaj ANAF
- **Recipisa** - Dovadă acceptare
- **efactura_logger** - Istoric complet cu toate tranzițiile

## Securitate

- ✅ OAuth2 cu token auto-refresh
- ✅ Connection string-uri criptate
- ✅ xp_cmdshell activat doar în timpul jobului
- ✅ Proxy account cu privilegii minime
- ✅ TLS 1.2+ pentru comunicare ANAF
- ✅ Validare input strict

## Performanță

- **Throughput**: ~5-10 facturi/secundă (depinde de ANAF)
- **Batch size**: Configurabil (default 100)
- **Retry**: Max 3 încercări cu exponential backoff
- **Timeout**: 60s per upload, 30s per status check
- **Concurență**: Optimistic locking, fără deadlock-uri

## Conformitate și Audit

- ✅ Respectare deadline legal T+5 zile
- ✅ Alerte automate pentru facturi apropiate de deadline
- ✅ Logging complet pentru audit ANAF
- ✅ Raportare conformitate săptămânală
- ✅ Backup și retention log-uri

## Suport și Contribuție

### Raportare Probleme
Deschide un issue pe GitHub cu:
- Descriere problemă
- Query-uri relevante din `efactura_logger`
- Versiune SQL Server și .NET
- Environment (prod/test)

### Contribuție
Pull request-uri acceptate pentru:
- Bug fixes
- Îmbunătățiri performanță
- Documentație
- Teste

## Licență

Acest proiect este disponibil sub licența specificată în fișierul [LICENSE](LICENSE).

## Referințe

- [ANAF RO e-Factura](https://www.anaf.ro/efactura)
- [Specificații UBL 2.1](http://docs.oasis-open.org/ubl/UBL-2.1.html)
- [CIUS-RO](https://mfinante.gov.ro/documents/35673/243799/CIUS-RO_v1.0.1.pdf)
- [Chilkat Documentation](https://www.chilkatsoft.com/documentation.asp)
- [SQL Server Agent Jobs](https://learn.microsoft.com/en-us/sql/ssms/agent/)

## Contact

Pentru suport, contactează echipa de dezvoltare sau consultă documentația detaliată în directorul `Documentation/`.

---

**Versiune:** 1.0.0  
**Data:** 2024-12-04  
**Autor:** vicosx12  
**Repository:** [vicosx12/eFactura_WORK](https://github.com/vicosx12/eFactura_WORK)
