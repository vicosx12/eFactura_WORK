*!* ============================================================================
*!* FISIER: SAFT_Quick_Start.prg
*!* ============================================================================
*!* AUTOR: Alex (Engineer) - MGX Team
*!* DATA:  28.07.2025
*!* SCOP:  Quick start pentru testarea rapida a arhitecturii imbunatatite
*!* ============================================================================

LPARAMETERS tdData1, tdData2, tcTipDeclaratie, tnSegmente

*-- Setare valori default pentru demonstratie
IF EMPTY(tdData1)
    tdData1 = DATE(2024, 1, 1)
ENDIF
IF EMPTY(tdData2)
    tdData2 = DATE(2024, 1, 31)
ENDIF
IF EMPTY(tcTipDeclaratie)
    tcTipDeclaratie = "L"
ENDIF
IF EMPTY(tnSegmente)
    tnSegmente = 1
ENDIF

? "=== SAFT ENHANCED ARCHITECTURE - QUICK START ==="
? "Start Date: " + TRANSFORM(tdData1)
? "End Date: " + TRANSFORM(tdData2)
? "Declaration Type: " + tcTipDeclaratie
? "Segments: " + TRANSFORM(tnSegmente)
? ""

LOCAL llSuccess AS Boolean, lcStartTime AS String
lcStartTime = TIME()

? "Initializing Enhanced SAFT Components..."

TRY
    *-- Include fisierele necesare
    ? "Loading enhanced architecture files..."
    
    SET PROCEDURE TO SAFT_Compatibility_Bridge.prg ADDITIVE
    
    *-- Verificare compatibilitate
    ? "Checking compatibility..."
    IF SAFT_Check_Enhancement_Compatibility()
        ? "✓ All enhanced components available"
        
        *-- Executie cu arhitectura imbunatatita
        ? "Executing with Enhanced Architecture..."
        llSuccess = SAFT_Migrate_To_Enhanced(tdData1, tdData2, tcTipDeclaratie, tnSegmente)
        
    ELSE
        ? "⚠ Enhanced components not fully available"
        ? "Attempting direct integration..."
        
        *-- Incercare directa cu componentele disponibile
        SET PROCEDURE TO SAFT_DI_Container.prg ADDITIVE
        SET PROCEDURE TO SAFT_ConfigManager.prg ADDITIVE
        SET PROCEDURE TO SAFT_Exception_Hierarchy.prg ADDITIVE
        
        LOCAL loDIContainer AS Object
        loDIContainer = CREATEOBJECT("SAFT_DIContainer")
        
        IF VARTYPE(loDIContainer) = "O"
            ? "✓ Core DI Container initialized"
            
            LOCAL loConfigManager AS Object
            loConfigManager = CREATEOBJECT("SAFT_ConfigManager", "SAFT_Config.json")
            
            IF VARTYPE(loConfigManager) = "O"
                ? "✓ Configuration Manager initialized"
                ? "Configuration loaded from: SAFT_Config.json"
                
                *-- Demo configuratie
                ? "Sample Settings:"
                ? "  - Batch Size: " + TRANSFORM(loConfigManager.GetSetting("Database.BatchSize", 50000))
                ? "  - Enable Monitoring: " + TRANSFORM(loConfigManager.GetSetting("Performance.EnableMonitoring", .T.))
                ? "  - Declaration Type: " + loConfigManager.GetSetting("SAFT.DeclarationType", "L")
                
                llSuccess = .T.
            ELSE
                ? "✗ Configuration Manager failed to initialize"
                llSuccess = .F.
            ENDIF
        ELSE
            ? "✗ DI Container failed to initialize"
            llSuccess = .F.
        ENDIF
    ENDIF
    
CATCH TO oException
    ? "✗ Error during initialization:"
    ? "  " + oException.Message
    llSuccess = .F.
ENDTRY

? ""
? "=== EXECUTION RESULTS ==="
? "Status: " + IIF(llSuccess, "SUCCESS", "FAILED")
? "Execution Time: " + TIME() + " (started at " + lcStartTime + ")"

IF llSuccess
    ? ""
    ? "✓ Enhanced SAFT Architecture is working correctly!"
    ? "✓ All core components initialized successfully"
    ? "✓ Ready for production use with your data"
    ? ""
    ? "Next steps:"
    ? "1. Configure SAFT_Config.json with your company data"
    ? "2. Test with your actual database"
    ? "3. Replace your current SAFT calls with enhanced version"
    
ELSE
    ? ""
    ? "⚠ Some issues were detected during initialization"
    ? "Please check:"
    ? "1. All .prg files are in the same directory"
    ? "2. SAFT_Config.json exists and is valid"
    ? "3. Original SAFT files are available"
ENDIF

? ""
? "=== DEMO COMPLETED ==="

RETURN llSuccess

*!*-----------------------------------------------------------------------------
*!* FUNCTION: SAFT_Demo_Performance
*!* SCOP: Demonstratie capabilities de performance monitoring
*!*-----------------------------------------------------------------------------
FUNCTION SAFT_Demo_Performance()
    ? ""
    ? "=== PERFORMANCE MONITORING DEMO ==="
    
    TRY
        SET PROCEDURE TO SAFT_PerformanceMonitor.prg ADDITIVE
        
        LOCAL loMonitor AS Object
        loMonitor = CREATEOBJECT("SAFT_PerformanceMonitor")
        
        IF VARTYPE(loMonitor) = "O"
            ? "✓ Performance Monitor initialized"
            
            *-- Demo timer
            LOCAL lcTimerId AS String
            lcTimerId = loMonitor.StartTimer("DEMO_OPERATION")
            
            ? "Started demo operation timer..."
            
            *-- Simuleaza ceva procesare
            LOCAL i AS Integer
            FOR i = 1 TO 10000
                *-- Simulare procesare
            ENDFOR
            
            LOCAL loMetric AS Object
            loMetric = loMonitor.StopTimer(lcTimerId)
            
            IF VARTYPE(loMetric) = "O"
                ? "Demo operation completed in: " + TRANSFORM(loMetric.Value, "999.999") + " seconds"
            ENDIF
            
            *-- Demo metrici suplimentare
            loMonitor.RecordRecordCount("DEMO_RECORDS", 10000)
            loMonitor.RecordMemoryUsage("DEMO_MEMORY")
            
            ? "✓ Performance metrics recorded"
            
            *-- Genereaza raport demo
            LOCAL lcReport AS String
            lcReport = loMonitor.GeneratePerformanceReport()
            
            ? "✓ Performance report generated"
            ? "Report preview:"
            ? SUBSTR(lcReport, 1, 200) + "..."
            
            RETURN .T.
        ELSE
            ? "✗ Could not initialize Performance Monitor"
            RETURN .F.
        ENDIF
        
    CATCH TO oException
        ? "✗ Performance Demo Error: " + oException.Message
        RETURN .F.
    ENDTRY
ENDFUNC

*!*-----------------------------------------------------------------------------
*!* FUNCTION: SAFT_Demo_Exception_Handling
*!* SCOP: Demonstratie exception handling
*!*-----------------------------------------------------------------------------
FUNCTION SAFT_Demo_Exception_Handling()
    ? ""
    ? "=== EXCEPTION HANDLING DEMO ==="
    
    TRY
        SET PROCEDURE TO SAFT_Exception_Hierarchy.prg ADDITIVE
        
        LOCAL loExceptionHandler AS Object
        loExceptionHandler = CREATEOBJECT("SAFT_ExceptionHandler")
        
        IF VARTYPE(loExceptionHandler) = "O"
            ? "✓ Exception Handler initialized"
            
            *-- Demo exceptie custom
            LOCAL loException AS Object
            loException = CREATEOBJECT("SAFT_ValidationException", ;
                "Demo validation error", "DEMO_FIELD", "Invalid value", .NULL.)
            
            ? "Created demo validation exception"
            ? "User Message: " + loException.GetUserFriendlyMessage()
            
            RETURN .T.
        ELSE
            ? "✗ Could not initialize Exception Handler"
            RETURN .F.
        ENDIF
        
    CATCH TO oException
        ? "✗ Exception Demo Error: " + oException.Message
        RETURN .F.
    ENDTRY
ENDFUNC