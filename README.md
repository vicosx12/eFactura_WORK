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
