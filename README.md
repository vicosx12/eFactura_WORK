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
