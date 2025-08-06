*!* ============================================================================
*!* FISIER: SAFT_Enhanced_Main.prg
*!* ============================================================================
*!* AUTOR: Alex (Engineer) - MGX Team
*!* DATA:  28.07.2025
*!* SCOP:  Punct de intrare IMBUNATATIT pentru arhitectura SAFT
*!* Integreaza toate noile componente: DI Container, Config Manager,
*!* Exception Hierarchy, Handler Factory si Performance Monitor
*!* ============================================================================

LPARAMETERS tdData1, tdData2, tcTipDeclaratie, tnSegmente

*-- Include toate fisierele necesare
SET PROCEDURE TO SAFT_DI_Container.prg ADDITIVE
SET PROCEDURE TO SAFT_ConfigManager.prg ADDITIVE  
SET PROCEDURE TO SAFT_Exception_Hierarchy.prg ADDITIVE
SET PROCEDURE TO SAFT_HandlerFactory.prg ADDITIVE
SET PROCEDURE TO SAFT_PerformanceMonitor.prg ADDITIVE
SET PROCEDURE TO SAFT_Advanced_Classes.prg ADDITIVE
SET PROCEDURE TO SAFT_Helpers.prg ADDITIVE

CLOSE DATABASES ALL

*-- Variabile pentru noua arhitectura
LOCAL loDIContainer AS SAFT_DIContainer
LOCAL loConfigManager AS SAFT_ConfigManager
LOCAL loExceptionHandler AS SAFT_ExceptionHandler
LOCAL loHandlerFactory AS SAFT_HandlerFactory
LOCAL loPerformanceMonitor AS SAFT_PerformanceMonitor
LOCAL loServiceLocator AS SAFT_ServiceLocator

LOCAL loContext AS SAFT_Context
LOCAL loFirstHandler AS Object
LOCAL llSuccess AS Boolean
LOCAL lcTimerId AS String

*-- Validare parametri
IF EMPTY(tdData1) OR EMPTY(tdData2)
    MESSAGEBOX("Perioada (Data1, Data2) este obligatorie!", 16, "Eroare Parametri")
    RETURN .F.
ENDIF
tcTipDeclaratie = IIF(EMPTY(tcTipDeclaratie), "L", UPPER(ALLTRIM(tcTipDeclaratie)))
tnSegmente = IIF(EMPTY(tnSegmente), 1, tnSegmente)

TRY
    *-- === PASUL 1: INITIALIZARE DEPENDENCY INJECTION CONTAINER ===
    loDIContainer = CREATEOBJECT("SAFT_DIContainer")
    
    *-- === PASUL 2: INITIALIZARE CONFIG MANAGER ===
    loConfigManager = CREATEOBJECT("SAFT_ConfigManager", "SAFT_Config.json")
    loDIContainer.RegisterInstance("SAFT_ConfigManager", loConfigManager)
    
    *-- === PASUL 3: INITIALIZARE PERFORMANCE MONITOR ===
    loPerformanceMonitor = CREATEOBJECT("SAFT_PerformanceMonitor")
    loPerformanceMonitor.IsEnabled = loConfigManager.GetSetting("Performance.EnableMonitoring", .T.)
    loDIContainer.RegisterInstance("SAFT_PerformanceMonitor", loPerformanceMonitor)
    
    *-- Porneste timer-ul principal
    lcTimerId = loPerformanceMonitor.StartTimer("SAFT_TOTAL_PROCESS")
    
    *-- === PASUL 4: INITIALIZARE EXCEPTION HANDLER ===
    loExceptionHandler = CREATEOBJECT("SAFT_ExceptionHandler")
    loExceptionHandler.Logger = loDIContainer.Resolve("SAFT_Logger")
    
    *-- === PASUL 5: INITIALIZARE HANDLER FACTORY ===
    loHandlerFactory = CREATEOBJECT("SAFT_HandlerFactory")
    loDIContainer.RegisterInstance("SAFT_HandlerFactory", loHandlerFactory)
    
    *-- === PASUL 6: INITIALIZARE SERVICE LOCATOR ===
    loServiceLocator = CREATEOBJECT("SAFT_ServiceLocator", loDIContainer)
    
    *-- === PASUL 7: CREARE CONTEXT IMBUNATATIT ===
    loContext = CREATEOBJECT("SAFT_Enhanced_Context", tdData1, tdData2, tcTipDeclaratie, tnSegmente)
    loContext.SetDIContainer(loDIContainer)
    loContext.SetConfigManager(loConfigManager)
    loContext.SetPerformanceMonitor(loPerformanceMonitor)
    loContext.SetExceptionHandler(loExceptionHandler)
    
    *-- Atasare observatori
    loContext.AttachObserver(loDIContainer.Resolve("SAFT_Logger"))
    loContext.AttachObserver(loDIContainer.Resolve("SAFT_Progress_UI"))
    loContext.AttachObserver(loDIContainer.Resolve("SAFT_Summary_Collector"))
    
    *-- Notifica inceputul procesului
    loContext.Notify("PROCESS_START", "Initiere generare SAF-T cu arhitectura imbunatatita...")
    
    *-- === PASUL 8: INITIALIZARE ENVIRONMENT (din codul original) ===
    lcLogFile = loContext.LogFile
    lcTipDeclaratie = loContext.DeclarationType
    CUI_Raportor = '00'+ICAS.oSoc.CodFiscal
    vTipConta = IIF(IsNullOrEmpty(ALLTRIM(ICAS.oSoc.SaFT_TipConta)), 'A', ALLTRIM(ICAS.oSoc.SaFT_TipConta))
    lcDirectorSAFT = AddBs(JustPath(loContext.FinalFileName))
    Data1 = loContext.StartDate
    Data2 = loContext.EndDate
    lnCalupInregGLE = loConfigManager.GetSetting("Database.BatchSize", 50000)
    
    *-- Setari TVA din configuratie sau calcul dinamic
    lcModPlataTva = GetModPlataTva(tdData2)
    gcTaxType = loConfigManager.GetSetting("SAFT.TaxType", "000")
    
    Do Case
        Case lcModPlataTva=1    && Lunar
            gcTaxType='300'
        Case lcModPlataTva=2    && Trimestrial
            gcTaxType='300'
        Case lcModPlataTva=3    && Semestrial
            gcTaxType='300'
        Case lcModPlataTva=4    && Anual
            gcTaxType='300'
        OtherWise               && Neplatitor
            gcTaxType='000'
    EndCase
    
    *-- Initializare tabele si environment
    Tabela_Erori_Saft('Creare_Tabela_Erori')
    loContext.Notify("ENVIRONMENT", "Initializare environment...")
    
    SAFT_Mapare()
    loContext.Notify("ENVIRONMENT", "SAFT_Mapare...")
    
    CreareCursoare(loContext.StartDate, loContext.EndDate)
    Saft_Ecoaqua_Preluare_All_DB('CreareCursoare')
    Saft_Ecosal_Preluare_Dbf('CreareCursoare')
    loContext.Notify("ENVIRONMENT", "CreareCursoare completat...")
    
    *-- Seteaza repository-ul
    loContext.SetRepository(loDIContainer.Resolve("SAFT_Repository"))
    
    *-- === PASUL 9: CONSTRUIRE LANT PRIN HANDLER FACTORY ===
    loPerformanceMonitor.StartTimer("HANDLER_CHAIN_BUILD")
    
    loFirstHandler = loHandlerFactory.BuildHandlerChain(tcTipDeclaratie, loContext)
    
    loPerformanceMonitor.StopTimer("HANDLER_CHAIN_BUILD")
    
    IF VARTYPE(loFirstHandler) != "O"
        loException = CREATEOBJECT("SAFT_ConfigurationException", ;
            "Tip de declaratie nerecunoscut sau lant de handlere invalid", ;
            "DeclarationType", tcTipDeclaratie, loContext)
        loExceptionHandler.HandleException(loException, .T., .T.)
        RETURN .F.
    ENDIF
    
    *-- === PASUL 10: NOTIFICARE START PROCES ===
    loHandlerInfo = loHandlerFactory.GetRegistrationInfo()
    loContext.Notify("PROCESS_START", loHandlerInfo)
    
    *-- === PASUL 11: EXECUTIE LANT CU EXCEPTION HANDLING ===
    loPerformanceMonitor.StartTimer("HANDLER_CHAIN_EXECUTION")
    
    llSuccess = loExceptionHandler.ExecuteWithExceptionHandling(loFirstHandler, "Handler Chain Execution", loContext)
    
    loPerformanceMonitor.StopTimer("HANDLER_CHAIN_EXECUTION")
    loContext.Notify("PROCESS_END", llSuccess)
    
    *-- Verifica daca au aparut erori in context
    llSuccess = llSuccess AND !loContext.HasErrors
    
CATCH TO oException
    *-- Converteste exceptia VFP la exceptie SAFT custom
    LOCAL loSAFTException AS SAFT_Exception_Base
    
    loSAFTException = CREATEOBJECT("SAFT_Exception_Base", ;
        "Eroare neasteptata in procesul principal: " + oException.Message, ;
        "SAFT_FATAL_ERROR", loContext, oException)
    
    IF VARTYPE(loExceptionHandler) = "O"
        loExceptionHandler.HandleException(loSAFTException, .T., .T.)
    ELSE
        MESSAGEBOX("Eroare fatala: " + oException.Message, 16, "Eroare Fatala SAFT")
    ENDIF
    
    llSuccess = .F.
ENDTRY

*-- === FINALIZARE SI RAPORTARE ===
IF VARTYPE(loPerformanceMonitor) = "O"
    loPerformanceMonitor.StopTimer(lcTimerId)
    
    *-- Genereaza si salveaza raportul de performanta
    IF loConfigManager.GetSetting("Performance.EnableMetrics", .T.)
        loPerformanceMonitor.SavePerformanceReport("SAFT_Performance_" + TRANSFORM(DATETIME(), "@Y") + ".txt")
    ENDIF
ENDIF

*-- Afisare rezultat final
IF llSuccess
    IF VARTYPE(loContext) = "O" AND VARTYPE(loContext.SummaryCollector) = "O"
        loContext.SummaryCollector.DisplaySummary(loContext)
    ENDIF
    
    LOCAL lcSuccessMessage AS String
    lcSuccessMessage = "Generarea fisierului SAF-T a fost finalizata cu succes!" + CHR(13) + CHR(10)
    
    IF VARTYPE(loPerformanceMonitor) = "O"
        LOCAL loTotalStats AS Object
        loTotalStats = loPerformanceMonitor.GetOperationStatistics("SAFT_TOTAL_PROCESS")
        lcSuccessMessage = lcSuccessMessage + "Timp total: " + TRANSFORM(loTotalStats.AverageDuration, "999.999") + " secunde"
    ENDIF
    
    MESSAGEBOX(lcSuccessMessage, 64, "Proces Finalizat")
ELSE
    MESSAGEBOX("Generarea fisierului SAF-T a esuat. Verificati fisierul de log pentru detalii.", 16, "Proces Esuat")
ENDIF

*-- Cleanup
IF VARTYPE(loDIContainer) = "O"
    loDIContainer.Dispose()
ENDIF
IF VARTYPE(loConfigManager) = "O"
    loConfigManager.Dispose()
ENDIF
IF VARTYPE(loPerformanceMonitor) = "O"
    loPerformanceMonitor.Dispose()
ENDIF

RETURN llSuccess

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_Enhanced_Context
*!* SCOP: Context imbunatatit cu suport pentru noile componente
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_Enhanced_Context AS SAFT_Context
    DIContainer = .NULL.
    ConfigManager = .NULL.
    PerformanceMonitor = .NULL.
    ExceptionHandler = .NULL.
    
    FUNCTION SetDIContainer(toDIContainer AS SAFT_DIContainer)
        THIS.DIContainer = toDIContainer
    ENDFUNC
    
    FUNCTION SetConfigManager(toConfigManager AS SAFT_ConfigManager)
        THIS.ConfigManager = toConfigManager
    ENDFUNC
    
    FUNCTION SetPerformanceMonitor(toMonitor AS SAFT_PerformanceMonitor)
        THIS.PerformanceMonitor = toMonitor
    ENDFUNC
    
    FUNCTION SetExceptionHandler(toHandler AS SAFT_ExceptionHandler)
        THIS.ExceptionHandler = toHandler
    ENDFUNC
    
    *-- Metoda helper pentru obtinerea unui serviciu
    FUNCTION GetService(tcInterface AS String) AS Object
        IF VARTYPE(THIS.DIContainer) = "O"
            RETURN THIS.DIContainer.Resolve(tcInterface)
        ENDIF
        RETURN .NULL.
    ENDFUNC
    
    *-- Metoda helper pentru obtinerea unei setari
    FUNCTION GetSetting(tcPath AS String, tvDefault AS Variant) AS Variant
        IF VARTYPE(THIS.ConfigManager) = "O"
            RETURN THIS.ConfigManager.GetSetting(tcPath, tvDefault)
        ENDIF
        RETURN tvDefault
    ENDFUNC
    
    *-- Metoda helper pentru monitorizarea performantei
    FUNCTION StartTimer(tcOperationName AS String) AS String
        IF VARTYPE(THIS.PerformanceMonitor) = "O"
            RETURN THIS.PerformanceMonitor.StartTimer(tcOperationName)
        ENDIF
        RETURN ""
    ENDFUNC
    
    FUNCTION StopTimer(tcTimerId AS String) AS Object
        IF VARTYPE(THIS.PerformanceMonitor) = "O"
            RETURN THIS.PerformanceMonitor.StopTimer(tcTimerId)
        ENDIF
        RETURN .NULL.
    ENDFUNC
    
    *-- Metoda helper pentru gestionarea exceptiilor
    FUNCTION HandleException(toException AS SAFT_Exception_Base, tlShowUser AS Boolean, tlLogException AS Boolean)
        IF VARTYPE(THIS.ExceptionHandler) = "O"
            RETURN THIS.ExceptionHandler.HandleException(toException, tlShowUser, tlLogException)
        ENDIF
        RETURN .F.
    ENDFUNC
ENDDEFINE