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
| **Builder** | `HandlerChainBuilder` | Construcție flexibilă a chain-ului de procesare |
| **Strategy** | `XmlStrategyFactory` | Strategii diferite pentru generare XML |
| **Repository** | `IInvoiceRepository` | Abstractizare acces date |

### Structura Directoarelor

```
/eFactura_WORK/
├── eFactura_Work.PRG                 # Fișier principal (compatibilitate înapoi)
├── /Classes/
│   ├── /Core/
│   │   ├── EFacturaContext.prg       # Container date și stare procesare
│   │   ├── EFacturaFacade.prg        # Facade principal
│   │   └── ConfigProvider.prg        # Configurări centralizate
│   ├── /Handlers/
│   │   ├── AbstractHandler.prg       # Clasă abstractă handler
│   │   ├── ValidationHandler.prg     # Validare date
│   │   ├── TaxCalculationHandler.prg # Calcul TVA
│   │   ├── XmlBuilderHandler.prg     # Generare XML UBL
│   │   ├── ApiUploaderHandler.prg    # Upload ANAF
│   │   └── PersistenceHandler.prg    # Salvare în BD
│   ├── /Builders/
│   │   └── HandlerChainBuilder.prg   # Builder pentru chain
│   ├── /Observers/
│   │   ├── ProgressSubject.prg       # Subject Observer
│   │   └── ProgressBarObserver.prg   # Observer pentru UI
│   └── /Services/
│       ├── LoggerService.prg         # Logging centralizat
│       └── StatsCollector.prg        # Colector statistici
├── /Tests/                           # Teste unitare
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
