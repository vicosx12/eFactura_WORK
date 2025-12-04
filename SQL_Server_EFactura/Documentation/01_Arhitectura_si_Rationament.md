# Arhitectură și Raționament: Automatizare RO e-Factura din SQL Server

**Versiune:** 1.1 (SQL Server 2012 Compatible)  
**Compatibilitate:** SQL Server 2012 SP1+, 2014, 2016, 2017, 2019, 2022

## 1. Prezentare Generală

### 1.1 Obiectiv
Soluție robustă, idempotentă și ușor de operat pentru transmiterea automată a facturilor către RO e-Factura (ANAF) direct din Microsoft SQL Server, folosind biblioteca Chilkat invocată din T-SQL.

**🔧 Compatibilitate SQL Server 2012:** Soluția include implementări custom pentru funcționalitate JSON și concatenare string-uri, compatibile cu SQL Server 2012 SP1+, eliminând dependența de funcții native introduse în SQL Server 2016+ (JSON_VALUE, ISJSON, STRING_AGG).

### 1.2 Componente Principale
1. **Baza de date SQL Server** - Stocare date și orchestrare
2. **Proceduri T-SQL** - Logică de procesare și control
3. **EFAgent.exe (Chilkat)** - Utilitar C# pentru comunicare cu ANAF
4. **SQL Server Agent Job** - Planificare automată

## 2. Arhitectura Sistemului

### 2.1 Diagrama de Flux Principal

```
┌─────────────────────────────────────────────────────────────┐
│               SQL Server Agent Job                          │
│         (EFA_Background_Processor - la 5-10 min)            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│           dbo.EFA_ScanAndProcessAll                         │
│  - Scanare Firme.dbo.Soc (baze online)                      │
│  - Verificare Send_Efactura='Da'                            │
│  - Logging: SCANARE                                         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼ (pentru fiecare bază activată)
┌─────────────────────────────────────────────────────────────┐
│              dbo.EFA_ProcessDb(@db)                         │
│  - Selectare candidați din Iesiri/Export                    │
│  - Verificare deadline (T+5 zile)                           │
│  - Batch processing (100 doc/run)                           │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼ (pentru fiecare factură)
┌─────────────────────────────────────────────────────────────┐
│          dbo.EFA_ProcessOne(@table, @id)                    │
│                                                              │
│  ┌──────────────────────────────────────┐                   │
│  │ 1. GENERARE                          │                   │
│  │    - Invocare EFAgent generate       │                   │
│  │    - Validare XSD                    │                   │
│  │    - Stare: GENERATA / NEGNERATA     │                   │
│  └──────────────┬───────────────────────┘                   │
│                 │                                            │
│  ┌──────────────▼───────────────────────┐                   │
│  │ 2. TRANSMITERE                       │                   │
│  │    - OAuth2 authentication           │                   │
│  │    - Invocare EFAgent upload         │                   │
│  │    - Salvare Id_Solicitare           │                   │
│  │    - Stare: TRANSMISA / TRANSMITERE_ES│                  │
│  └──────────────┬───────────────────────┘                   │
│                 │                                            │
│  ┌──────────────▼───────────────────────┐                   │
│  │ 3. VERIFICARE STATUS                 │                   │
│  │    - Invocare EFAgent status         │                   │
│  │    - Verificare Id_Descarcare        │                   │
│  │    - Stare: ACCEPTATA / RESPINSA     │                   │
│  └──────────────┬───────────────────────┘                   │
│                 │                                            │
│  ┌──────────────▼───────────────────────┐                   │
│  │ 4. DESCĂRCARE ZIP                    │                   │
│  │    - Invocare EFAgent download       │                   │
│  │    - Stocare în EFA_Zip_Content      │                   │
│  │    - Salvare Recipisa                │                   │
│  │    - Stare: COMPLETED                │                   │
│  └──────────────────────────────────────┘                   │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Integrare cu EFAgent (Chilkat)

```
┌─────────────────────────────────────────────────────────────┐
│                 dbo.EFA_InvokeAgent                         │
│  - Construire linie de comandă                              │
│  - Invocare xp_cmdshell                                     │
│  - Capturare stdout JSON                                    │
│  - Validare ISJSON                                          │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              EFAgent.exe (C#/Chilkat)                       │
│                                                              │
│  Comenzi:                                                    │
│  • generate  - Generare XML UBL + validare XSD              │
│  • upload    - Upload factură cu OAuth2                     │
│  • status    - Interogare status cu Id_Descarcare           │
│  • download  - Descărcare ZIP și returnare base64           │
│                                                              │
│  Parametri:                                                  │
│  --db, --table, --id, --connString, --env (prod/test)       │
│  --id_descarcare, --out-json, --log-level                   │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                  ANAF RO e-Factura API                      │
│  - OAuth2 authentication                                    │
│  - Upload endpoint                                          │
│  - Status endpoint                                          │
│  - Download endpoint                                        │
└─────────────────────────────────────────────────────────────┘
```

## 3. Model de Date

### 3.1 Tabela efactura_logger

Tabela centrală de logging pentru trasabilitate completă.

```sql
CREATE TABLE dbo.efactura_logger (
    log_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    log_dt_utc DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    db_name SYSNAME NOT NULL,
    table_name SYSNAME NOT NULL,  -- 'Iesiri' sau 'Export'
    id_unic NVARCHAR(50) NOT NULL,
    step NVARCHAR(20) NOT NULL,   -- SCANARE|GENERARE|TRANSMITERE|STATUS|DESCARCARE
    action NVARCHAR(100) NULL,
    code_ref NVARCHAR(50) NULL,
    http_status INT NULL,
    anaf_status NVARCHAR(50) NULL,
    id_solicitare CHAR(10) NULL,
    id_descarcare CHAR(10) NULL,
    recipisa CHAR(10) NULL,
    message_short NVARCHAR(500) NULL,
    message_detail NVARCHAR(MAX) NULL,
    payload_ref NVARCHAR(MAX) NULL,
    status CHAR(10) NOT NULL,     -- OK|ERR|RETRY
    attempt_no INT NOT NULL DEFAULT 1,
    job_name SYSNAME NULL,
    host_name SYSNAME NULL,
    run_id UNIQUEIDENTIFIER NULL
);
```

**Indexe:**
- `IX_efactura_logger_lookup`: `(db_name, table_name, id_unic, log_dt_utc DESC)`
- `IX_efactura_logger_step_status`: `(step, status, log_dt_utc DESC)`

### 3.2 Modificări la Iesiri și Export

Coloane adiționale pentru tracking:

```sql
-- Existente (presupuse)
eFactura BIT,
Is_EF BIT,
DataDoc DATETIME,
BT_11 CHAR(30),     -- Număr factură
BT_13 CHAR(30),     -- Data emitere

-- Noi / actualizate
Id_Solicitare CHAR(10),
Recipisa CHAR(10),
Id_Descarcare CHAR(10),
efact_Detalii NVARCHAR(100),
efact_Tip NVARCHAR(20),
efact_Stare NVARCHAR(20),       -- Stare curentă (vezi mașină de stări)
efact_DataIncarcare DATETIME2,
EF_Data_Validare DATETIME2,
EFA_Zip_FileName NVARCHAR(254),
EFA_Zip_Content VARBINARY(MAX),
efact_Processing_Host SYSNAME,
efact_Processing_Time DATETIME2,
efact_Attempt_Count INT DEFAULT 0
```

**Indexe:**
- `IX_Iesiri_EF_Processing`: `(Is_EF, efact_Stare, DataDoc) INCLUDE (BT_11, BT_13)`
- Similar pentru `Export`

## 4. Mașina de Stări (efact_Stare)

### 4.1 Tranziții Normale

```
NULL/PENDING
    ↓
IN_PROGRES (lock cu timestamp + host + run_id)
    ↓
GENERATA (XML creat și validat)
    ↓
TRANSMISA (Id_Solicitare + Id_Descarcare setate)
    ↓
IN_ASTEPTARE_STATUS (verificare periodică)
    ↓
ACCEPTATA (Recipisa != NULL)
    ↓
DESCARCARE_READY (ZIP disponibil)
    ↓
COMPLETED (ZIP descărcat și stocat, EF_Data_Validare setată)
```

### 4.2 Tranziții de Eroare

- **NEGNERATA**: Eroare la generare XML sau validare XSD
- **TRANSMITERE_ES**: Eroare la upload (retry posibil)
- **RESPINSA**: ANAF a respins factura
- **DESCARCARE_ES**: Eroare la descărcare ZIP (retry posibil)

### 4.3 Reguli de Tranziție

1. **Idempotență**: Verificare stare curentă înainte de fiecare acțiune
2. **Lock optimistic**: UPDATE cu WHERE condiționat pe stare
3. **Retry**: Max 3 încercări cu backoff exponențial (30s, 2m, 5m)
4. **Timeout**: IN_PROGRES mai vechi de 1h sunt resetate la PENDING

## 5. Idempotență și Control Concurență

### 5.1 Strategii de Idempotență

**A. Lock la nivel de document:**
```sql
UPDATE Iesiri
SET efact_Stare = 'IN_PROGRES',
    efact_Processing_Host = HOST_NAME(),
    efact_Processing_Time = SYSUTCDATETIME(),
    efact_Attempt_Count = efact_Attempt_Count + 1
WHERE Nir = @id_unic
  AND (efact_Stare IS NULL OR efact_Stare = 'PENDING' 
       OR (efact_Stare = 'IN_PROGRES' AND DATEDIFF(HOUR, efact_Processing_Time, SYSUTCDATETIME()) > 1))
  
IF @@ROWCOUNT = 0
    RETURN -- Document deja preluat de alt proces
```

**B. Verificare la fiecare pas:**
- Înainte de GENERARE: verifică dacă nu e deja GENERATA
- Înainte de TRANSMITERE: verifică dacă nu e deja TRANSMISA
- Înainte de STATUS: verifică dacă nu e deja ACCEPTATA
- Înainte de DESCARCARE: verifică dacă nu e deja COMPLETED

**C. Retry logic:**
```sql
IF @http_status IN (408, 429, 500, 502, 503, 504) 
   AND @attempt_no < 3
THEN
    -- Retry cu backoff exponențial
    WAITFOR DELAY @backoff_time
    -- Re-încercare
ELSE
    -- Marcă ca eroare finală
    SET efact_Stare = 'TRANSMITERE_ES'
```

### 5.2 Prevenirea Race Conditions

1. **Tranzacții scurte**: Commit rapid după UPDATE
2. **Optimistic concurrency**: Verificare stare în WHERE clause
3. **Run ID unic**: Fiecare rulare job are GUID unic
4. **Host tracking**: Identificare process care procesează

## 6. Calculul Deadline-ului (T+5 Zile Calendaristice)

### 6.1 Logica de Calcul

```
Data emitere: T (ex: 5 august)
Ziua următoare: T+1 (6 august) - Start numărătoare
Deadline: T+5 zile calendaristice (10 august 23:59:59)
```

**Funcție T-SQL:**
```sql
CREATE FUNCTION dbo.EFA_CalculateDeadline(@DataEmitere DATETIME)
RETURNS DATETIME
AS
BEGIN
    RETURN DATEADD(DAY, 5, CAST(@DataEmitere AS DATE))
END
```

**Alert levels:**
- CRITICAL: deadline < 1 zi
- WARNING: deadline < 2 zile
- INFO: deadline >= 2 zile

## 7. Securitate și OAuth2

### 7.1 Stocare Secrete

**În SQL Server (criptat cu Chilkat):**
```sql
-- Tabela Configurari.SystemParameters
sKey = 'eFactura_ClientID'     → sValue = '<ID_criptat>'
sKey = 'eFactura_SecretID'     → sValue = '<Secret_criptat>'
sKey = 'eFactura_Environment'  → sValue = 'prod' sau 'test'
sKey = 'eFactura_CryptKey'     → sValue = '<Cheie_master>'
```

**În EFAgent (config file):**
```json
{
  "oauth2": {
    "tokenStore": "C:\\EFAgent\\tokens",
    "refreshBeforeExpiry": 300
  },
  "endpoints": {
    "prod": "https://api.anaf.ro/prod/FCTEL/rest/",
    "test": "https://api.anaf.ro/test/FCTEL/rest/"
  }
}
```

### 7.2 Flux OAuth2

```
1. EFAgent verifică token local (tokenStore)
2. Dacă token valid și nu expiră în <5 min → folosește-l
3. Dacă expirat sau inexistent:
   a. Citește client_id/secret din config
   b. Apel la ANAF OAuth2 endpoint
   c. Salvează token nou în tokenStore
   d. Continuă cu operația
```

## 8. Logging și Monitorizare

### 8.1 Niveluri de Logging

- **SCANARE**: Baze identificate și activate
- **GENERARE**: XML generat și validat
- **TRANSMITERE**: Upload și Id_Solicitare
- **STATUS**: Verificare status și Recipisa
- **DESCARCARE**: Descărcare ZIP

### 8.2 Monitorizare și Alerte

**Metrici cheie:**
1. Facturi peste 4 zile fără COMPLETED
2. Rate erori (>10% în ultima oră)
3. Timp mediu de procesare (target: <5 min de la PENDING la COMPLETED)
4. Queue size (facturi în așteptare)

**Query-uri de monitorizare:**
```sql
-- Facturi aproape de deadline
SELECT db_name, table_name, id_unic, DataDoc,
       dbo.EFA_CalculateDeadline(DataDoc) AS Deadline,
       DATEDIFF(HOUR, GETDATE(), dbo.EFA_CalculateDeadline(DataDoc)) AS Hours_Remaining
FROM Iesiri
WHERE Is_EF = 1 
  AND efact_Stare NOT IN ('COMPLETED', 'RESPINSA')
  AND DATEDIFF(HOUR, GETDATE(), dbo.EFA_CalculateDeadline(DataDoc)) < 48
ORDER BY Deadline;

-- Erori recente
SELECT TOP 100 *
FROM efactura_logger
WHERE status = 'ERR'
  AND log_dt_utc > DATEADD(HOUR, -1, GETUTCDATE())
ORDER BY log_dt_utc DESC;
```

## 9. Performanță și Optimizare

### 9.1 Batch Processing

- Procesare în loturi de 100 documente
- Timeout per document: 60s
- Timeout per batch: 10 minute

### 9.2 Limitare Rată

- Max 10 request-uri/secundă către ANAF
- Backoff exponențial la erori 429 (Too Many Requests)
- Circuit breaker: stop după 10 erori consecutive

### 9.3 Optimizare Query-uri

```sql
-- Index covering pentru selecție candidați
CREATE INDEX IX_Iesiri_EF_Candidates 
ON Iesiri(Is_EF, efact_Stare, DataDoc)
INCLUDE (Nir, BT_11, BT_13, Id_Descarcare);
```

## 10. Testare și Validare

### 10.1 Mod Dry-Run

```sql
EXEC dbo.EFA_ScanAndProcessAll @DryRun = 1;
-- Nu face UPDATE-uri, doar SELECT și logging
```

### 10.2 Scenarii de Test

1. **Happy path**: Factură nouă → COMPLETED
2. **Retry logic**: Simulare eroare 503 → retry → succes
3. **Validare XSD**: XML invalid → NEGNERATA
4. **Respingere ANAF**: Factură cu erori → RESPINSA
5. **Concurență**: 2 job-uri paralele → doar unul procesează
6. **Recovery**: Job întrerupt → reluare de unde a rămas

### 10.3 Validare XSD

```csharp
// În EFAgent
public ValidationResult ValidateXML(string xmlPath) {
    var schemaSet = new XmlSchemaSet();
    schemaSet.Add("", "UBL-Invoice-2.1.xsd");
    
    var doc = XDocument.Load(xmlPath);
    var errors = new List<string>();
    
    doc.Validate(schemaSet, (o, e) => {
        errors.Add($"{e.Severity}: {e.Message}");
    });
    
    return new ValidationResult {
        IsValid = errors.Count == 0,
        Errors = errors
    };
}
```

## 11. Diagrama Deployment

```
┌────────────────────────────────────────────────────────────┐
│                   SQL Server Instance                      │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ Firme.dbo.Soc (lista baze)                          │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ DB1.dbo.Iesiri + Export                             │  │
│  │ DB1.dbo.Configurari.SystemParameters                │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ DB2.dbo.Iesiri + Export                             │  │
│  │ DB2.dbo.Configurari.SystemParameters                │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ Master.dbo.efactura_logger                          │  │
│  │ Master.dbo.EFA_* (stored procedures)                │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ SQL Server Agent                                     │  │
│  │   Job: EFA_Background_Processor (la 5 min)          │  │
│  └─────────────────────────────────────────────────────┘  │
└────────────────┬───────────────────────────────────────────┘
                 │
                 │ xp_cmdshell (proxy account)
                 ▼
┌────────────────────────────────────────────────────────────┐
│          C:\EFAgent\EFAgent.exe                            │
│                                                             │
│  Config: C:\EFAgent\config\settings.json                   │
│  Tokens: C:\EFAgent\tokens\                                │
│  Logs:   C:\EFAgent\logs\                                  │
│  XSD:    C:\EFAgent\schemas\*.xsd                          │
└────────────────┬───────────────────────────────────────────┘
                 │
                 │ HTTPS + OAuth2
                 ▼
┌────────────────────────────────────────────────────────────┐
│              ANAF RO e-Factura API                         │
│          https://api.anaf.ro/prod/FCTEL/rest/              │
└────────────────────────────────────────────────────────────┘
```

## 12. Decizii de Design și Raționament

### 12.1 De ce SQL Server Agent Job?

**Avantaje:**
- Integrare nativă cu SQL Server
- Logging automat în msdb
- Retry policies configurabile
- Alerting built-in

**Alternative considerate:**
- Windows Service: Mai complex de implementat
- Task Scheduler: Mai puțin control

### 12.2 De ce xp_cmdshell?

**Avantaje:**
- Singura metodă de invocare executabile din T-SQL
- Capturare stdout în variabilă

**Măsuri de securitate:**
- Enable doar în timpul execuției jobului
- Proxy account cu privilegii minime
- Validare input strict

**Alternative:**
- CLR în SQL Server: Limitări .NET Framework
- Ole Automation: Depreciat

### 12.3 De ce Chilkat?

**Avantaje:**
- OAuth2 built-in
- TLS 1.2+ support
- HTTP retry policies
- Criptare/decriptare
- ZIP handling

**Alternative:**
- .NET HttpClient: OAuth2 manual
- RestSharp: Lipsește criptare

### 12.4 De ce JSON pentru răspunsuri?

**Avantaje:**
- ISJSON() pentru validare
- OPENJSON() pentru parsing
- Human-readable în logging

**Alternative:**
- XML: Mai verbos
- Binar: Mai greu de debug

## 13. Riscuri și Mitigare

| Risc | Impact | Probabilitate | Mitigare |
|------|--------|---------------|----------|
| Token OAuth2 expirat | HIGH | MEDIUM | Auto-refresh cu 5 min înainte de expirare |
| xp_cmdshell dezactivat | HIGH | LOW | Check și enable în job; disable după |
| Erori ANAF (downtime) | MEDIUM | MEDIUM | Retry cu exponential backoff; alerting |
| Race condition (2+ jobs) | MEDIUM | LOW | Optimistic locking cu efact_Stare |
| Depășire deadline | HIGH | LOW | Alerting la 2 zile înainte; prioritizare |
| ZIP prea mare (>100MB) | LOW | LOW | Streaming save; limită în validare |
| Validare XSD eșuată | MEDIUM | MEDIUM | Logging detaliat; alerting pentru review |
| Connection string compromis | HIGH | LOW | Criptare în SystemParameters; audit logs |

## 14. Conformitate și Audit

### 14.1 Trasabilitate Completă

Fiecare factură are:
- Id_Solicitare (identificator ANAF)
- Id_Descarcare (link la mesaj)
- Recipisa (dovadă acceptare)
- efactura_logger (istoric complet)

### 14.2 Raportare

```sql
-- Raport conformitate
SELECT 
    db_name,
    COUNT(*) AS Total_Facturi,
    SUM(CASE WHEN efact_Stare = 'COMPLETED' THEN 1 ELSE 0 END) AS Transmise,
    SUM(CASE WHEN DATEDIFF(DAY, DataDoc, GETDATE()) > 5 
             AND efact_Stare NOT IN ('COMPLETED', 'RESPINSA') 
             THEN 1 ELSE 0 END) AS Peste_Deadline
FROM Iesiri
WHERE Is_EF = 1
  AND DataDoc >= DATEADD(MONTH, -1, GETDATE())
GROUP BY db_name;
```

## 15. Roadmap și Extensii Viitoare

### Versiunea 1.0 (MVP)
- Upload facturi Iesiri și Export
- Verificare status
- Descărcare ZIP și Recipisa
- Logging complet

### Versiunea 1.1
- Descărcare facturi primite
- Notificări email la erori
- Dashboard web pentru monitorizare

### Versiunea 2.0
- Procesare avize însoțitoare
- Integrare cu avize transport e-Transport
- API REST pentru interogări externe

---

**Document creat:** 2025-12-04  
**Versiune:** 1.0  
**Autor:** Copilot AI pentru vicosx12/eFactura_WORK
