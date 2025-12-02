# eFactura_WORK

RO-eFactura - Sistem de facturare electronică pentru România (Visual FoxPro 9 SP2)

## Descriere

Acest proiect implementează un sistem complet de facturare electronică compatibil cu sistemul RO e-Factura al ANAF. Codul a fost refactorizat folosind principii OOP și design patterns moderne pentru a obține o arhitectură curată, robustă și ușor de extins.

## Arhitectura

### Design Patterns Implementate

| Pattern | Clasă/Componente | Scop |
|---------|------------------|------|
| **Facade** | `EFacturaFacade` | Punct unic de intrare pentru procesarea facturilor |
| **Chain of Responsibility** | `AbstractHandler`, `ValidationHandler`, etc. | Procesare în etape cu posibilitate de întrerupere |
| **Observer** | `ProgressSubject`, `ProgressBarObserver` | Notificări de progres către UI |
| **Builder** | `HandlerChainBuilder`, `InvoiceBuilder` | Construcție flexibilă a chain-ului și facturilor |
| **Strategy** | `XmlStrategyFactory`, `B2BXmlStrategy`, etc. | Strategii diferite pentru generare XML |
| **Repository** | `IInvoiceRepository`, `IesiriRepository` | Abstractizare acces date |
| **Dependency Injection** | `ServiceContainer` | Container pentru gestionarea dependențelor |
| **Unit of Work** | `UnitOfWork` | Coordonarea tranzacțiilor |
| **Event Dispatcher** | `EventDispatcher` | Sistem de evenimente pentru decuplare |
| **Retry/Circuit Breaker** | `RetryPolicy` | Reziliență pentru apeluri API |
| **Cache** | `CacheService` | Caching pentru reducerea apelurilor repetate |
| **Message Queue** | `MessageQueue`, `AsyncProcessor` | Procesare asincronă batch |

### Structura Directoarelor

```
/eFactura_WORK/
├── eFactura_Work.PRG                 # Fișier principal (compatibilitate înapoi)
├── /Classes/
│   ├── /Core/
│   │   ├── EFacturaContext.prg       # Container date și stare procesare
│   │   ├── EFacturaFacade.prg        # Facade principal
│   │   ├── ConfigProvider.prg        # Configurări centralizate
│   │   └── ServiceContainer.prg      # Dependency Injection Container
│   ├── /Handlers/
│   │   ├── AbstractHandler.prg       # Clasă abstractă handler
│   │   ├── ValidationHandler.prg     # Validare date
│   │   ├── TaxCalculationHandler.prg # Calcul TVA
│   │   ├── XmlBuilderHandler.prg     # Generare XML UBL
│   │   ├── ApiUploaderHandler.prg    # Upload ANAF
│   │   └── PersistenceHandler.prg    # Salvare în BD
│   ├── /Builders/
│   │   ├── HandlerChainBuilder.prg   # Builder pentru chain
│   │   └── InvoiceBuilder.prg        # Builder pentru Invoice
│   ├── /Observers/
│   │   ├── ProgressSubject.prg       # Subject Observer
│   │   └── ProgressBarObserver.prg   # Observer pentru UI
│   ├── /Repositories/
│   │   ├── IInvoiceRepository.prg    # Interfață abstractă
│   │   ├── IesiriRepository.prg      # Repository Iesiri
│   │   ├── ExportRepository.prg      # Repository Export
│   │   └── RepositoryFactory.prg     # Factory pentru repositories
│   ├── /Strategies/
│   │   ├── XmlGeneratorStrategy.prg  # Strategie abstractă
│   │   ├── B2BXmlStrategy.prg        # Strategie B2B
│   │   ├── ExportXmlStrategy.prg     # Strategie Export
│   │   └── XmlStrategyFactory.prg    # Factory pentru strategii
│   ├── /Domain/
│   │   ├── Invoice.prg               # Entitate Invoice
│   │   └── InvoiceLine.prg           # Entitate linie factură
│   └── /Services/
│       ├── LoggerService.prg         # Logging centralizat
│       ├── StatsCollector.prg        # Colector statistici
│       ├── CacheService.prg          # Cache pentru rezultate API
│       ├── RetryPolicy.prg           # Politică retry cu circuit breaker
│       ├── EventDispatcher.prg       # Sistem de evenimente
│       ├── XmlSchemaValidator.prg    # Validator XSD
│       ├── UnitOfWork.prg            # Unit of Work pattern
│       ├── MessageQueue.prg          # Coadă de mesaje
│       └── AsyncProcessor.prg        # Procesare asincronă
├── /Tests/                           # Teste unitare și de performanță
│   ├── Test_ValidationHandler.prg
│   ├── Test_TaxCalculation.prg
│   ├── Test_Integration.prg
│   ├── Test_XmlStrategies.prg
│   ├── Test_ApiMock.prg
│   └── Test_Performance.prg
└── README.md                         # Documentație
```

## Pipeline de Procesare

```
┌─────────────────────────────────────────────────────────────────────┐
│                      INVOICE REQUEST                                 │
└───────────────────────────┬─────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    HANDLER CHAIN                                     │
│                                                                      │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐          │
│  │ Validation   │───▶│ Tax          │───▶│ XML          │          │
│  │ Handler      │    │ Calculation  │    │ Builder      │          │
│  └──────────────┘    └──────────────┘    └──────────────┘          │
│         │                                        │                   │
│         ▼                                        ▼                   │
│  ┌──────────────┐    ┌──────────────┐                               │
│  │ API          │───▶│ Persistence  │                               │
│  │ Uploader     │    │ Handler      │                               │
│  └──────────────┘    └──────────────┘                               │
└─────────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│              RESPONSE (Success/Error + Stats)                        │
└─────────────────────────────────────────────────────────────────────┘
```

## Utilizare

### Modul Clasic (Compatibilitate Înapoi)

```foxpro
* Apel clasic - funcționează ca înainte
Do eFactura_Work With lnIdUnicFactura, .F., "", .F., "Iesiri", .F.
```

### Modul Nou (OOP)

```foxpro
* Încarcă clasele
Set Procedure To Classes\Core\EFacturaFacade Additive
Set Procedure To Classes\Core\EFacturaContext Additive
Set Procedure To Classes\Core\ConfigProvider Additive
Set Procedure To Classes\Handlers\AbstractHandler Additive
Set Procedure To Classes\Handlers\ValidationHandler Additive
Set Procedure To Classes\Handlers\TaxCalculationHandler Additive
Set Procedure To Classes\Handlers\XmlBuilderHandler Additive
Set Procedure To Classes\Handlers\ApiUploaderHandler Additive
Set Procedure To Classes\Handlers\PersistenceHandler Additive
Set Procedure To Classes\Builders\HandlerChainBuilder Additive
Set Procedure To Classes\Observers\ProgressSubject Additive
Set Procedure To Classes\Observers\ProgressBarObserver Additive
Set Procedure To Classes\Services\LoggerService Additive
Set Procedure To Classes\Services\StatsCollector Additive

* Creează facade-ul
loFacade = CreateObject("EFacturaFacade")

* Atașează un observer pentru progress bar
loProgressObserver = CreateObject("ProgressBarObserver")
loProgressObserver.SetProgressBar(ThisForm.oProgressBar)
loFacade.AttachProgressObserver(loProgressObserver)

* Procesează factura
lcResult = loFacade.Process(lnIdUnicFactura, "Iesiri", .F., "", .F., .F.)

* Verifică rezultatul
If Left(lcResult, 7) = "_index:"
    lcIdSolicitare = SubStr(lcResult, 8)
    MessageBox("Factură transmisă cu succes! Index: " + lcIdSolicitare)
Else
    MessageBox("Eroare: " + lcResult)
EndIf
```

### Configurare

```foxpro
loFacade = CreateObject("EFacturaFacade")

* Dezactivează upload-ul (doar generare XML)
loFacade.SetUploadEnabled(.F.)

* Activează/dezactivează logging
loFacade.SetLoggingEnabled(.T.)

* Activează/dezactivează notificări progres
loFacade.SetProgressEnabled(.T.)

* Obține configurația
loConfig = loFacade.GetConfig()
loConfig.SetProduction(.T.)  && Mod producție
```

## Clase Principale

### EFacturaContext
Container pentru datele facturii și starea procesării.

**Proprietăți:**
- `nIdUnicFactura` - ID-ul unic al facturii
- `cAlias` - Alias-ul cursorului (Iesiri/Export/Docum)
- `cNumarFactura` - Numărul facturii
- `dDataFactura` - Data facturii
- `lHasCriticalError` - Flag eroare critică
- `cXmlFilePath` - Calea XML generat
- `cIdSolicitare` - ID solicitare ANAF

### AbstractHandler
Clasă abstractă pentru handleri (Chain of Responsibility).

**Metode:**
- `Handle(toContext)` - Procesează și trimite la următorul
- `SetNext(toHandler)` - Setează următorul handler
- `CanHandle(toContext)` - Verifică dacă poate procesa
- `DoHandle(toContext)` - Implementare specifică (abstractă)

### ProgressSubject
Subiect Observer pentru notificări progres.

**Metode:**
- `Attach(toObserver)` - Înregistrează observator
- `Detach(toObserver)` - Dezînregistrează
- `Notify(tnPercent, tcMessage)` - Notifică toți observatorii

## Tipuri de Factură Suportate

| Cod | Descriere |
|-----|-----------|
| 380 | Factură standard |
| 381 | Notă de creditare (deprecated) |
| 384 | Factură corectată (rectificativă) |
| 389 | Autofactură |
| 751 | Factură în scopuri contabile (bon fiscal) |

## Categorii TVA

| Cod | Descriere |
|-----|-----------|
| S | Cotă normală/redusă |
| Z | TVA cota zero |
| E | Scutire de TVA |
| AE | Taxare inversă |
| K | Livrări intracomunitare |
| G | Export |
| O | Nu face obiectul TVA |

## Limite API ANAF

| Metodă | Limită |
|--------|--------|
| Toate metodele | max 1000 apeluri/minut |
| /upload | max 1000 fișiere RASP/zi/CUI |
| /stare | max 10 interogări/mesaj/zi |
| /lista simplă | max 1500 interogări/zi/CUI |
| /lista paginație | max 100.000 interogări/zi/CUI |
| /descărcare | max 10 descărcări/mesaj/zi |

## Cerințe Sistem

- Visual FoxPro 9 SP2
- Windows 7/8/10/11
- Conexiune Internet pentru API ANAF
- Librăria Chilkat (opțional, pentru operații ZIP)

## Licență

Copyright © 2023-2024 Vicos. Toate drepturile rezervate.

Licență perpetuă, netransferabilă, neexclusivă pentru utilizare în aplicații ERP.

## Autor

Vilciu Constantin Vicos
vicosx12@gmail.com

## Istoric Versiuni

- **v1.0** (03/2023) - Versiune inițială
- **v1.1** (09/2023) - Îmbunătățiri performanță
- **v1.2** (01/2024) - Suport B2C, optimizări
- **v2.0** (11/2024) - Refactorizare OOP completă
- **v2.1** (12/2024) - Servicii avansate: DI Container, Events, Cache, Async
- **v2.2** (12/2024) - Health Check, Audit, Notifications, Rate Limiter, Batch Processing, Config Hot Reload, Metrics, PDF Generator, Multi-tenancy, Plugin Architecture
- **v2.3** (12/2024) - Saga Pattern, Feature Flags, Encryption, Webhooks, Query Builder, State Machine, Localization, Backup/Recovery, API Gateway, Distributed Tracing, Schema Migration, Report Templates

---

## Servicii Avansate

### ServiceContainer (Dependency Injection)

```foxpro
*-- Creează container
loContainer = CreateObject("ServiceContainer")

*-- Înregistrează servicii
loContainer.Register("Logger", "LoggerService", .T.)      && Singleton
loContainer.Register("Cache", "CacheService", .T.)        && Singleton
loContainer.Register("Validator", "ValidationHandler")    && Transient

*-- Rezolvă dependențe
loLogger = loContainer.Resolve("Logger")
loCache = loContainer.Resolve("Cache")

*-- Creează scope copil
loScopedContainer = loContainer.CreateScope()
```

### CacheService

```foxpro
*-- Creează cache
loCache = CreateObject("CacheService")
loCache.SetDefaultTtl(300)  && 5 minute TTL

*-- Set/Get valori
loCache.Set("api_status_123", '{"stare": "ok"}', 60)  && TTL 60 sec
lcStatus = loCache.Get("api_status_123", "")

*-- GetOrSet cu factory
lcResult = loCache.GetOrSet("key", "GetApiResult()", 120)

*-- Statistici
loStats = loCache.GetStats()
? "Hit ratio: " + Transform(loStats.HitRatio * 100) + "%"
```

### RetryPolicy (cu Circuit Breaker)

```foxpro
*-- Creează politică retry
loPolicy = CreateObject("RetryPolicy")
loPolicy.nMaxRetries = 3
loPolicy.nInitialDelay = 1000      && 1 secunda
loPolicy.lUseExponentialBackoff = .T.

*-- Circuit Breaker
loPolicy.lCircuitBreakerEnabled = .T.
loPolicy.nFailureThreshold = 5     && Deschide circuit după 5 eșecuri
loPolicy.nCircuitOpenDuration = 60000  && 60 secunde pauză

*-- Execută cu retry
lcResult = loPolicy.Execute("CallAnafApi()")

*-- Verifică starea circuit breaker
? "Circuit state: " + loPolicy.cCircuitState  && CLOSED/OPEN/HALF_OPEN
```

### EventDispatcher

```foxpro
*-- Creează dispatcher
loDispatcher = CreateObject("EventDispatcher")

*-- Definește handler
Define Class MyEventHandler As BaseEventHandler
    Procedure Handle(toEventData)
        ? "Invoice uploaded: " + Transform(toEventData.IdFactura)
    EndProc
EndDefine

*-- Înregistrează listener
loHandler = CreateObject("MyEventHandler")
loDispatcher.AddListener("invoice.uploaded", loHandler, 10)  && prioritate 10

*-- Dispatch eveniment
loEventData = CreateObject("EventData")
loEventData.SetData("IdFactura", 12345)
loDispatcher.Dispatch("invoice.uploaded", loEventData)

*-- Evenimente predefinite
* invoice.validated, invoice.uploaded, invoice.failed
* validation.failed, xml.generated, api.error
* process.started, process.completed
```

### XmlSchemaValidator

```foxpro
*-- Creează validator
loValidator = CreateObject("XmlSchemaValidator")

*-- Validează XML
llValid = loValidator.Validate(lcXmlContent)

If Not llValid
    ? "Erori:"
    ? loValidator.GetErrors()
EndIf

If loValidator.HasWarnings()
    ? "Atenționări:"
    ? loValidator.GetWarnings()
EndIf

*-- Validare reguli business CIUS-RO
llValid = loValidator.ValidateBusinessRules(lcXmlContent)
```

### UnitOfWork

```foxpro
*-- Creează Unit of Work
loUoW = CreateObject("UnitOfWork")

*-- Înregistrează repositories
loUoW.RegisterRepository("Iesiri", loIesiriRepo)
loUoW.RegisterRepository("Export", loExportRepo)

*-- Marchează entități pentru salvare
loUoW.MarkNew("Iesiri", loNewInvoice)
loUoW.MarkDirty("Export", loModifiedInvoice, loOriginalData)
loUoW.MarkDeleted("Iesiri", loDeletedInvoice)

*-- Commit tranzacție atomică
loUoW.BeginTransaction()
If loUoW.Commit()
    ? "Succes!"
Else
    ? "Rollback efectuat"
EndIf
```

### AsyncProcessor (Message Queue)

```foxpro
*-- Creează coada și procesorul
loQueue = CreateObject("MessageQueue")
loQueue.cQueueName = "efactura"

loProcessor = CreateObject("AsyncProcessor")
loProcessor.SetQueue(loQueue)
loProcessor.SetFacade(loFacade)

*-- Adaugă facturi în coadă
loProcessor.EnqueueInvoice(101, "Iesiri", .F., 5)  && Prioritate 5
loProcessor.EnqueueInvoice(102, "Iesiri", .F., 0)
loProcessor.EnqueueInvoice(103, "Iesiri", .F., 10) && Prioritate mare

*-- Batch enqueue
Dimension laIds[3]
laIds[1] = 201
laIds[2] = 202
laIds[3] = 203
loProcessor.EnqueueBatch(@laIds, "Export")

*-- Procesează batch
loProcessor.nBatchSize = 20
loProcessor.Start()

*-- Sau procesează tot
loProcessor.ProcessAll()

*-- Statistici
loStats = loProcessor.GetStats()
? "Procesate: " + Transform(loStats.Processed)
? "Esuate: " + Transform(loStats.Failed)
? "Throughput: " + Transform(loStats.ThroughputPerSecond) + " facturi/sec"
```

---

## Rulare Teste

```foxpro
*-- Teste validare
Do Tests\Test_ValidationHandler

*-- Teste calcul TVA  
Do Tests\Test_TaxCalculation

*-- Teste integrare
Do Tests\Test_Integration

*-- Teste strategii XML
Do Tests\Test_XmlStrategies

*-- Teste mock API
Do Tests\Test_ApiMock

*-- Teste performanță
Do Tests\Test_Performance
```

---

## Servicii Extinse (v2.2)

### HealthChecker - Diagnosticare Sistem

```foxpro
*-- Creează health checker
loHealth = CreateObject("HealthChecker")

*-- Rulează toate verificările
loReport = loHealth.RunAllChecks()

? "Status general: " + loReport.OverallStatus
? "Healthy: " + Transform(loReport.HealthyCount)
? "Warning: " + Transform(loReport.WarningCount)
? "Critical: " + Transform(loReport.CriticalCount)

*-- Verificare rapidă
If loHealth.IsHealthy()
    ? "Sistemul este sănătos"
EndIf

*-- Export JSON (pentru dashboard-uri externe)
lcJson = loHealth.GetReportAsJson()
```

### AuditService - Audit Trail

```foxpro
*-- Creează serviciul de audit
loAudit = CreateObject("AuditService")
loAudit.SetUser("user1", "Ion Popescu")

*-- Logare acțiuni
loAudit.LogCreate("Invoice", 12345, "Factură nouă creată", lcInvoiceData)
loAudit.LogUpdate("Invoice", 12345, "Status actualizat", "DRAFT", "SENT")
loAudit.LogUpload("Invoice", 12345, "Încărcat ANAF", lcResponse)
loAudit.LogError("Invoice", 12345, "Eroare validare", lcErrorDetails)

*-- Interogare istoric
loAudit.Query("Invoice", "12345", Date() - 30, Date(), "")
Browse
Use In AuditResults

*-- Export istoric la JSON
lcHistoryJson = loAudit.ExportToJson("Invoice", "12345", Date() - 7, Date())

*-- Cleanup vechi (după 365 zile implicit)
lnDeleted = loAudit.Cleanup()
```

### NotificationService - Notificări Email/SMS

```foxpro
*-- Creează serviciul
loNotify = CreateObject("NotificationService")

*-- Configurare SMTP
loNotify.cSmtpServer = "smtp.example.com"
loNotify.nSmtpPort = 587
loNotify.cSmtpUser = "user@example.com"
loNotify.cSmtpPassword = "password"
loNotify.cFromEmail = "noreply@example.com"

*-- Adaugă destinatari
loNotify.AddEmailRecipient("admin@company.ro", "Administrator")
loNotify.AddSmsRecipient("+40712345678")

*-- Trimite notificări
loNotify.NotifyError("Eroare critică API", "Conexiune ANAF eșuată", .T.)  && Urgent
loNotify.NotifySuccess("Upload reușit", "Factură #123 trimisă cu succes")
loNotify.NotifyWarning("Atenție", "Spațiu disk scăzut")

*-- Notificare rezultat batch
loNotify.NotifyBatchResult(100, 95, 5, 45.5)  && Total, Success, Failed, Duration

*-- Notificare upload
loNotify.NotifyUploadConfirmation("FAC-2024-001", "ABC123XYZ", "OK")
```

### RateLimiter - Protecție API

```foxpro
*-- Creează rate limiter
loLimiter = CreateObject("RateLimiter")

*-- Configurare endpoint-uri
loLimiter.SetEndpointLimit("upload", 60, 60)    && 60 req/min
loLimiter.SetEndpointLimit("status", 120, 60)   && 120 req/min

*-- Verificare înainte de request
If loLimiter.CanMakeRequest("upload")
    * Face request
    loLimiter.RecordRequest("upload")
Else
    * Așteaptă sau răspunde cu eroare
EndIf

*-- Sau atomic: verifică + înregistrează
If loLimiter.AcquirePermit("upload")
    * Face request
EndIf

*-- Așteaptă până se poate (cu timeout)
If loLimiter.WaitForPermit("upload", 30)  && Max 30 secunde
    * Face request
Else
    * Timeout
EndIf

*-- Status
loStatus = loLimiter.GetStatus()
? "Tokens: " + Transform(loStatus.Tokens) + "/" + Transform(loStatus.MaxTokens)

*-- Request-uri rămase pentru endpoint
? loLimiter.GetRemainingRequests("upload")
```

### BatchProcessor - Procesare CSV/Bulk

```foxpro
*-- Creează procesor batch
loBatch = CreateObject("BatchProcessor")
loBatch.SetFacade(loFacade)

*-- Import din CSV
loBatch.ImportFromCsv("facturi_ianuarie.csv")

*-- Procesare
loBatch.ProcessBatch()

*-- Sau procesare după ID-uri
loBatch.ProcessByIds("101,102,103,104", "Iesiri")

*-- Sau procesare interval date
loBatch.ProcessByDateRange(Date() - 30, Date(), "Iesiri")

*-- Export rezultate la CSV
lcCsvFile = loBatch.ExportResultsToCsv("rezultate.csv")

*-- Raport text
? loBatch.GetSummaryReportAsText()

*-- Retry failed
loBatch.RetryFailed("Iesiri")

*-- Statistici
loReport = loBatch.GetSummaryReport()
? "Total: " + Transform(loReport.TotalRecords)
? "Success: " + Transform(loReport.SuccessCount)
? "Failed: " + Transform(loReport.FailedCount)
? "Success Rate: " + Transform(loReport.SuccessRate) + "%"
```

### ConfigHotReload - Reîncărcare Configurație

```foxpro
*-- Creează serviciul
loConfigReload = CreateObject("ConfigHotReload")
loConfigReload.SetConfigFile("efactura.config")

*-- Pornește monitorizarea
loConfigReload.StartWatching()

*-- Observer pentru schimbări
Define Class MyConfigObserver As ConfigChangeObserver
    Procedure OnConfigChanged(toConfigService)
        ? "Configurație reîncărcată la " + Time()
        * Reîncarcă setările în aplicație
    EndProc
EndDefine

loObserver = CreateObject("MyConfigObserver")
loConfigReload.AttachObserver(loObserver)

*-- Poll manual (apelat din timer)
loConfigReload.Poll()

*-- Get/Set valori
lcValue = loConfigReload.GetValue("ApiUrl", "https://default.url")
loConfigReload.SetValue("DebugMode", "true")

*-- Salvează configurația
loConfigReload.SaveConfiguration()

*-- Forțează reload
loConfigReload.Reload()

*-- Oprește monitorizarea
loConfigReload.StopWatching()
```

### MetricsCollector - Dashboard și Metrici

```foxpro
*-- Creează colector
loMetrics = CreateObject("MetricsCollector")

*-- Contoare
loMetrics.CounterInc("invoices_processed_total")
loMetrics.CounterInc("invoices_uploaded_total")
loMetrics.CounterInc("api_requests_total", 1, 'endpoint="upload"')

*-- Gauge-uri
loMetrics.GaugeSet("invoices_pending", 45)
loMetrics.GaugeInc("queue_depth", 1)
loMetrics.GaugeDec("cache_size", 10)

*-- Histograme (durată)
loTimer = loMetrics.Timer()
* ... procesare ...
lnDuration = loTimer.ObserveDuration("invoice_processing_duration_seconds")

*-- Export format Prometheus
lcPrometheusOutput = loMetrics.ExportPrometheus()

*-- Date pentru dashboard
loData = loMetrics.GetDashboardData()
? "Procesate: " + Transform(loData.InvoicesProcessed)
? "Uploadate: " + Transform(loData.InvoicesUploaded)
? "Eșuate: " + Transform(loData.InvoicesFailed)
? "Rată succes: " + Transform(loData.SuccessRate) + "%"
? "Timp mediu: " + Transform(loData.AvgProcessingTime) + " sec"
```

### PdfGenerator - Generare PDF din XML

```foxpro
*-- Creează generator
loPdf = CreateObject("PdfGenerator")

*-- Generare din conținut XML
lcXmlContent = FileToStr("factura.xml")
lcPdfFile = loPdf.GenerateFromXml(lcXmlContent, "factura_output.pdf")

*-- Sau din fișier
lcPdfFile = loPdf.GenerateFromFile("factura.xml", "")

*-- Preview în browser
loPdf.PreviewInvoice(lcXmlContent)

*-- Doar HTML (pentru conversie externă)
lcHtml = loPdf.GenerateHtml(loInvoice)
```

### TenantManager - Multi-tenancy (Multi-firmă)

```foxpro
*-- Creează manager
loTenant = CreateObject("TenantManager")

*-- Înregistrează firme
loTenant.RegisterTenant("firma1", "SC Firma 1 SRL", "RO12345678", "DB_Firma1", .Null.)
loTenant.RegisterTenant("firma2", "SC Firma 2 SA", "RO87654321", "DB_Firma2", .Null.)

*-- Setează tenant activ
loTenant.SetCurrentTenant("firma1")

*-- Obține tenant curent
loCurrentTenant = loTenant.GetCurrentTenant()
? loCurrentTenant.Name
? loCurrentTenant.CUI

*-- Configurație per tenant
loTenant.SetTenantConfig("AnafApiUrl", "https://api.anaf.ro/prod")
lcUrl = loTenant.GetTenantConfig("AnafApiUrl", "")

*-- Execută pentru tenant specific
loCallback = CreateObject("TenantCallback")
loResult = loTenant.ExecuteForTenant("firma2", loCallback)

*-- Execută pentru toți tenanții
laResults = loTenant.ExecuteForAllTenants(loCallback)

*-- Validare acces
If loTenant.ValidateTenantAccess("RO12345678")
    * CUI valid pentru context
EndIf

*-- Lista tenanți
loTenant.GetAllTenants()
Browse
```

### PluginManager - Arhitectură Plugin

```foxpro
*-- Creează manager
loPluginMgr = CreateObject("PluginManager")
loPluginMgr.cPluginsPath = "C:\App\Plugins\"

*-- Auto-descoperire plugin-uri
loPluginMgr.DiscoverPlugins()

*-- Sau încărcare manuală
loPluginMgr.LoadPlugin("C:\App\Plugins\MyPlugin.prg")

*-- Activare/Dezactivare
loPluginMgr.EnablePlugin("MyPlugin")
loPluginMgr.DisablePlugin("MyPlugin")

*-- Executare hooks
loContext = CreateObject("EFacturaContext")
loPluginMgr.ExecuteHooks("BeforeValidation", loContext)
loPluginMgr.ExecuteHooks("AfterXmlGeneration", loContext)

*-- Obține informații plugin
loInfo = loPluginMgr.GetPluginInfo("MyPlugin")
? loInfo.Name + " v" + loInfo.Version

*-- Lista plugin-uri
loPluginMgr.GetAllPlugins()
Browse

*-- Creare plugin custom
Define Class MyCustomPlugin As BasePlugin
    cName = "My Custom Plugin"
    cVersion = "1.0.0"
    cDescription = "Procesare custom factură"
    nPriority = 50
    
    Procedure OnBeforeValidation(toContext)
        * Adaugă validări custom
        ? "Custom validation for invoice " + Transform(toContext.nIdUnicFactura)
    EndProc
    
    Procedure OnAfterUpload(toContext)
        * Acțiuni post-upload
        ? "Upload completed: " + toContext.cIdSolicitare
    EndProc
EndDefine
```

## Extension Points pentru Plugin-uri

| Extension Point | Descriere |
|-----------------|-----------|
| `BeforeValidation` | Înainte de validare factură |
| `AfterValidation` | După validare factură |
| `BeforeXmlGeneration` | Înainte de generare XML |
| `AfterXmlGeneration` | După generare XML |
| `BeforeUpload` | Înainte de upload ANAF |
| `AfterUpload` | După upload ANAF |
| `BeforePersist` | Înainte de salvare |
| `AfterPersist` | După salvare |
| `OnStartup` | La pornirea aplicației |
| `OnShutdown` | La închiderea aplicației |
| `OnError` | La apariția unei erori |
| `OnConfigChange` | La modificarea configurației |

---

## Servicii Avansate (v2.3)

### SagaOrchestrator - Orchestrare Fluxuri Multi-Step

```foxpro
*-- Creează saga
loSaga = CreateObject("SagaOrchestrator")
loSaga.SetLogger(loLogger)

*-- Definește saga pentru upload factură
loSaga.BeginSaga("InvoiceUpload_" + Transform(lnId))
loSaga.AddStep("Validate", "DoValidate", "")
loSaga.AddStep("GenerateXml", "DoGenerateXml", "DoDeleteXml")
loSaga.AddStep("Upload", "DoUpload", "DoCancelUpload")
loSaga.AddStep("SaveReceipt", "DoSaveReceipt", "DoDeleteReceipt")

*-- Execută cu compensare automată la eșec
loSaga.SetExecutor(loInvoiceProcessor)
llSuccess = loSaga.Execute(toContext)

*-- Raport execuție
? loSaga.GetReport()
```

### FeatureFlagService - Feature Flags

```foxpro
*-- Creează serviciul
loFlags = CreateObject("FeatureFlagService")

*-- Definește flag-uri
loFlags.DefineFlag("NewXmlFormat", .F., "Folosește noul format XML")
loFlags.DefineFlag("ParallelUpload", .T., "Upload în paralel")
loFlags.DefineFlag("ApiTimeout", 30, "Timeout pentru API")

*-- Condiții temporale
loFlags.SetDateRange("BetaFeature", {^2024-01-01}, {^2024-06-30})

*-- Restricții per tenant/user
loFlags.SetTenants("NewXmlFormat", "TENANT1,TENANT2")
loFlags.SetUsers("DebugMode", "admin,developer")

*-- Verifică flag
If loFlags.IsEnabled("NewXmlFormat")
    * Folosește noul format
EndIf

*-- Obține valoare
lnTimeout = loFlags.GetValue("ApiTimeout", 30)

*-- Override pentru dezvoltare
loFlags.SetOverride("NewXmlFormat", .T.)
```

### EncryptionService - Criptare Date Sensibile

```foxpro
*-- Creează serviciul
loEncrypt = CreateObject("EncryptionService")
loEncrypt.SetMasterKey("MySecretPassword123")

*-- Criptare/Decriptare string
lcEncrypted = loEncrypt.Encrypt("CUI: RO12345678")
lcDecrypted = loEncrypt.Decrypt(lcEncrypted)

*-- Hash pentru verificări integritate
lcHash = loEncrypt.Hash(lcXmlContent)
llValid = loEncrypt.VerifyHash(lcXmlContent, lcHash)

*-- Criptare fișier
loEncrypt.EncryptFile("factura.xml", "factura.enc")
loEncrypt.DecryptFile("factura.enc", "factura_decrypted.xml")

*-- Rotație cheie
loEncrypt.RotateKey("NewPassword456")

*-- Token securizat
lcToken = loEncrypt.GenerateSecureToken(32)
```

### WebhookManager - Webhook-uri

```foxpro
*-- Creează manager
loWebhook = CreateObject("WebhookManager")

*-- Înregistrează endpoint
loWebhook.RegisterEndpoint("AnafNotify", "https://myapp.com/webhook/anaf", "secret123")
loWebhook.RegisterEndpoint("ERPSync", "https://erp.com/api/invoice", "")

*-- Trimite webhook
loWebhook.Send("AnafNotify", lcPayloadJson)

*-- Adaugă la coadă pentru trimitere async
loWebhook.QueueSend("ERPSync", lcPayloadJson)
loWebhook.ProcessQueue()

*-- Handler pentru incoming webhooks
loWebhook.RegisterHandler("invoice.uploaded", loMyHandler)
loWebhook.ProcessIncoming("invoice.uploaded", lcPayload, lcSignature, lcTimestamp, "secret")
```

### QueryBuilder - Interogări Flexibile

```foxpro
*-- Creează query builder
loQuery = CreateObject("QueryBuilder")

*-- Query fluent
loQuery.From("Iesiri") ;
       .Select("IdIesire, NumarDoc, DataDoc, ValoareTotala") ;
       .Where("DataDoc", ">=", Date() - 30) ;
       .Where("Stare", "=", "A") ;
       .OrderBy("DataDoc", "DESC") ;
       .Limit(100)

*-- Obține SQL
lcSql = loQuery.ToSql()

*-- Execută
loQuery.Execute("rezultat")
Browse

*-- Paginare
loQuery.Paginate(2, 25, "rezultat")  && Pagina 2, 25 per pagină

*-- Agregări
loQuery.From("Iesiri").Count("*", "total").GroupBy("TipDoc")
loQuery.Execute()
```

### InvoiceStateMachine - State Machine

```foxpro
*-- Creează state machine
loSM = CreateObject("InvoiceStateMachine")
loSM.Initialize("DRAFT")

*-- Verifică tranziții posibile
laTransitions = loSM.GetPossibleTransitions()

*-- Efectuează tranziție
If loSM.CanTransitionTo("VALIDATED")
    loSM.TransitionTo("VALIDATED", "user123")
EndIf

*-- Verifică starea curentă
? loSM.GetCurrentState()  && "VALIDATED"
? loSM.IsInState("DRAFT")  && .F.
? loSM.IsInFinalState()    && .F.

*-- Rollback
loSM.Rollback()

*-- Istoric
laHistory = loSM.GetHistory()

*-- Diagramă text
? loSM.GetDiagram()
```

### LocalizationService - Multi-limbă

```foxpro
*-- Creează serviciul
loLoc = CreateObject("LocalizationService")

*-- Schimbă limba
loLoc.SetLocale("EN")

*-- Traduce
lcMsg = loLoc.Translate("invoice.created", "invoiceNumber", "123")
* Result: "Invoice 123 has been created"

*-- Shortcut
lcMsg = loLoc.T("error.network")

*-- Pluralizare
lcMsg = loLoc.TranslatePlural("invoice.count", 5)
* Result: "5 invoices"

*-- Formatare locale-specific
? loLoc.FormatDate(Date())        && "12/02/2024" (EN) sau "02.12.2024" (RO)
? loLoc.FormatNumber(12345.67, 2) && "12,345.67" (EN)
? loLoc.FormatNumber(12345.67, 2, .T.)  && "12,345.67 RON"

*-- Încarcă traduceri din fișier
loLoc.LoadFromFile("translations.json")
```

### BackupService - Backup și Recovery

```foxpro
*-- Creează serviciul
loBackup = CreateObject("BackupService")
loBackup.SetBackupPath("D:\Backups\eFactura")

*-- Backup XML-uri
loBackup.BackupXmlFiles("C:\eFactura\XML\", "XML")

*-- Backup bază de date
loBackup.BackupDatabase("IESIRI")

*-- Backup complet
loBackup.BackupFull("C:\eFactura\")

*-- Restore
loBackup.RestoreFromBackup("D:\Backups\eFactura\FULL_20241202_143000.zip", "C:\Restore\")

*-- Programare automată
loBackup.Schedule("DAILY", "02:00", "")
loBackup.Schedule("WEEKLY", "03:00", "1,7")  && Duminică și Luni

*-- Curățare backup-uri vechi
loBackup.CleanupOldBackups()  && Șterge backup-uri mai vechi de 30 zile

*-- Statistici
loStats = loBackup.GetStats()
? "Success rate: " + Transform(loStats.SuccessRate) + "%"
```

### ApiGateway - Gateway API

```foxpro
*-- Creează gateway
loGateway = CreateObject("ApiGateway")

*-- Înregistrează rute
loGateway.RegisterRoute("/invoice/*", "InvoiceHandler", "GET,POST", .T., 100)
loGateway.RegisterRoute("/status/*", "StatusHandler", "GET", .F., 200)

*-- Procesează request
lcResponse = loGateway.HandleRequest("GET", "/invoice/123", "", "", "client1")

*-- Rate limiting
loGateway.nDefaultRateLimit = 100  && 100 requests/minut

*-- Cache
loGateway.lCacheEnabled = .T.
loGateway.nDefaultCacheTTL = 60

*-- Statistici
loStats = loGateway.GetStats()
? "Cache hit rate: " + Transform(loStats.CacheHitRate) + "%"
```

### DistributedTracer - Distributed Tracing

```foxpro
*-- Creează tracer
loTracer = CreateObject("DistributedTracer")
loTracer.SetService("eFactura", "2.3")

*-- Începe trace
loSpan = loTracer.StartTrace("ProcessInvoice")
loSpan.SetTag("invoice.id", "123")
loSpan.SetTag("invoice.type", "B2B")

*-- Child span
loChildSpan = loSpan.StartChildSpan("GenerateXML")
* ... procesare ...
loChildSpan.Finish()

*-- Altul
loUploadSpan = loSpan.StartChildSpan("UploadToANAF")
loUploadSpan.SetTag("api.endpoint", "/upload")
loUploadSpan.Finish()

*-- Finalizează
loSpan.Finish()

*-- Export spans (pentru Jaeger/Zipkin)
lcJson = loTracer.ExportSpans()

*-- Context propagation
lcHeaders = loTracer.GetTraceContext()
```

### SchemaMigrator - Migrare Schemă BD

```foxpro
*-- Creează migrator
loMigrator = CreateObject("SchemaMigrator")
loMigrator.SetDatabasePath("C:\Data\")
loMigrator.SetMigrationsPath("C:\Migrations\")

*-- Înregistrează migrări
loMigrator.RegisterMigration("001", "CreateAuditTable")
loMigrator.RegisterMigration("002", "AddEfacturaFields")
loMigrator.RegisterMigration("003", "CreateCacheTable")

*-- Rulează toate migrările pending
loMigrator.Migrate()

*-- Rollback ultima migrare
loMigrator.Rollback()

*-- Status
? loMigrator.GetStatus()

*-- Creează o migrare nouă
loMigrator.CreateMigration("AddNewColumn")  && Generează fișier template
```

### ReportTemplateEngine - Șabloane Rapoarte

```foxpro
*-- Creează engine
loEngine = CreateObject("ReportTemplateEngine")
loEngine.SetTemplatesPath("C:\Templates\")

*-- Încarcă template
loEngine.LoadTemplate("invoice_report.html")

*-- Setează date
loEngine.SetData("company", loCompany)
loEngine.SetData("invoice", loInvoice)
loEngine.SetData("lines", @laLines)

*-- Renderizează
lcOutput = loEngine.Render()

*-- Salvează
loEngine.SaveToFile("raport.html", lcOutput)

*-- Template syntax:
* {{variableName}} - Variabilă simplă
* {{object.property}} - Proprietate obiect
* {{#each lines}}...{{/each}} - Loop
* {{#if condition}}...{{else}}...{{/if}} - Condiție
* {{variableName|filter}} - Filtru (upper, lower, date, number, currency)
* {{> partialName}} - Include parțial
```

## Arhitectura Completă v2.3

```
/Classes/
├── /Core/
│   ├── EFacturaContext.prg
│   ├── EFacturaFacade.prg
│   ├── ConfigProvider.prg
│   ├── ServiceContainer.prg
│   ├── TenantManager.prg
│   └── PluginManager.prg
├── /Handlers/
│   ├── AbstractHandler.prg
│   ├── ValidationHandler.prg
│   ├── TaxCalculationHandler.prg
│   ├── XmlBuilderHandler.prg
│   ├── ApiUploaderHandler.prg
│   └── PersistenceHandler.prg
├── /Repositories/
│   ├── IInvoiceRepository.prg
│   ├── IesiriRepository.prg
│   ├── ExportRepository.prg
│   └── RepositoryFactory.prg
├── /Strategies/
│   ├── XmlGeneratorStrategy.prg
│   ├── B2BXmlStrategy.prg
│   ├── ExportXmlStrategy.prg
│   └── XmlStrategyFactory.prg
├── /Builders/
│   ├── HandlerChainBuilder.prg
│   └── InvoiceBuilder.prg
├── /Observers/
│   ├── ProgressSubject.prg
│   └── ProgressBarObserver.prg
├── /Domain/
│   ├── Invoice.prg
│   └── InvoiceLine.prg
└── /Services/
    ├── LoggerService.prg
    ├── StatsCollector.prg
    ├── CacheService.prg
    ├── RetryPolicy.prg
    ├── EventDispatcher.prg
    ├── XmlSchemaValidator.prg
    ├── UnitOfWork.prg
    ├── MessageQueue.prg
    ├── AsyncProcessor.prg
    ├── HealthChecker.prg
    ├── AuditService.prg
    ├── NotificationService.prg
    ├── RateLimiter.prg
    ├── BatchProcessor.prg
    ├── ConfigHotReload.prg
    ├── MetricsCollector.prg
    ├── PdfGenerator.prg
    ├── SagaOrchestrator.prg        # NEW v2.3
    ├── FeatureFlagService.prg      # NEW v2.3
    ├── EncryptionService.prg       # NEW v2.3
    ├── WebhookManager.prg          # NEW v2.3
    ├── QueryBuilder.prg            # NEW v2.3
    ├── InvoiceStateMachine.prg     # NEW v2.3
    ├── LocalizationService.prg     # NEW v2.3
    ├── BackupService.prg           # NEW v2.3
    ├── ApiGateway.prg              # NEW v2.3
    ├── DistributedTracer.prg       # NEW v2.3
    ├── SchemaMigrator.prg          # NEW v2.3
    └── ReportTemplateEngine.prg    # NEW v2.3
```
