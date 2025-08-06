*!* ============================================================================
*!* FISIER: SAFT_Compatibility_Bridge.prg
*!* ============================================================================
*!* AUTOR: Alex (Engineer) - MGX Team
*!* DATA:  28.07.2025
*!* SCOP:  Bridge pentru compatibilitatea intre codul original si imbunatatirile
*!* Permite folosirea graduala a noilor componente
*!* ============================================================================

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_Legacy_Adapter
*!* SCOP:  Adaptor pentru integrarea graduala cu codul existent
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_Legacy_Adapter AS Custom
    OriginalContext = .NULL.
    EnhancedContext = .NULL.
    DIContainer = .NULL.
    ConfigManager = .NULL.
    
    FUNCTION Init(toOriginalContext AS Object)
        THIS.OriginalContext = toOriginalContext
        THIS.InitializeEnhancements()
    ENDFUNC
    
    *-- Initializeaza noile componente cu backward compatibility
    FUNCTION InitializeEnhancements()
        TRY
            *-- Creaza DI Container doar daca nu exista
            IF VARTYPE(THIS.DIContainer) != "O"
                THIS.DIContainer = CREATEOBJECT("SAFT_DIContainer")
            ENDIF
            
            *-- Creaza Config Manager cu setari default din context original
            IF VARTYPE(THIS.ConfigManager) != "O"
                THIS.ConfigManager = CREATEOBJECT("SAFT_ConfigManager")
                THIS.MigrateOriginalSettings()
            ENDIF
            
            *-- Creaza Enhanced Context care wrapeaza originalul
            THIS.EnhancedContext = CREATEOBJECT("SAFT_Enhanced_Context_Wrapper")
            THIS.EnhancedContext.SetOriginalContext(THIS.OriginalContext)
            THIS.EnhancedContext.SetDIContainer(THIS.DIContainer)
            THIS.EnhancedContext.SetConfigManager(THIS.ConfigManager)
            
        CATCH TO oException
            *-- Daca nu putem initializa componentele noi, continuam cu originalul
            THIS.EnhancedContext = THIS.OriginalContext
        ENDTRY
    ENDFUNC
    
    *-- Migreaza setarile din contextul original in Config Manager
    PROTECTED FUNCTION MigrateOriginalSettings()
        IF VARTYPE(THIS.OriginalContext) != "O" OR VARTYPE(THIS.ConfigManager) != "O"
            RETURN
        ENDIF
        
        *-- Migreaza setarile cunoscute
        IF PEMSTATUS(THIS.OriginalContext, "StartDate", 5)
            THIS.ConfigManager.SetSetting("Process.StartDate", THIS.OriginalContext.StartDate)
        ENDIF
        
        IF PEMSTATUS(THIS.OriginalContext, "EndDate", 5)
            THIS.ConfigManager.SetSetting("Process.EndDate", THIS.OriginalContext.EndDate)
        ENDIF
        
        IF PEMSTATUS(THIS.OriginalContext, "DeclarationType", 5)
            THIS.ConfigManager.SetSetting("SAFT.DeclarationType", THIS.OriginalContext.DeclarationType)
        ENDIF
        
        *-- Migreaza alte setari daca exista
        IF TYPE("CUI_Raportor") = "C"
            THIS.ConfigManager.SetSetting("Company.CUI", CUI_Raportor)
        ENDIF
        
        IF TYPE("vTipConta") = "C"
            THIS.ConfigManager.SetSetting("SAFT.AccountType", vTipConta)
        ENDIF
        
        IF TYPE("lnCalupInregGLE") = "N"
            THIS.ConfigManager.SetSetting("Database.BatchSize", lnCalupInregGLE)
        ENDIF
    ENDFUNC
    
    *-- Obtine contextul potrivit (enhanced sau original)
    FUNCTION GetContext() AS Object
        RETURN THIS.EnhancedContext
    ENDFUNC
    
    *-- Verifica daca imbunatatirile sunt disponibile
    FUNCTION AreEnhancementsAvailable() AS Boolean
        RETURN VARTYPE(THIS.DIContainer) = "O" AND VARTYPE(THIS.ConfigManager) = "O"
    ENDFUNC
ENDDEFINE

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_Enhanced_Context_Wrapper
*!* SCOP:  Wrapper care extinde contextul original cu functionalitati noi
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_Enhanced_Context_Wrapper AS Custom
    OriginalContext = .NULL.
    DIContainer = .NULL.
    ConfigManager = .NULL.
    PerformanceMonitor = .NULL.
    
    FUNCTION SetOriginalContext(toContext AS Object)
        THIS.OriginalContext = toContext
    ENDFUNC
    
    FUNCTION SetDIContainer(toDIContainer AS Object)
        THIS.DIContainer = toDIContainer
    ENDFUNC
    
    FUNCTION SetConfigManager(toConfigManager AS Object)
        THIS.ConfigManager = toConfigManager
        
        *-- Initializeaza Performance Monitor daca e activat
        IF toConfigManager.GetSetting("Performance.EnableMonitoring", .F.)
            TRY
                THIS.PerformanceMonitor = CREATEOBJECT("SAFT_PerformanceMonitor")
            CATCH
                THIS.PerformanceMonitor = .NULL.
            ENDTRY
        ENDIF
    ENDFUNC
    
    *-- Delegate toate proprietatile si metodele la contextul original
    FUNCTION GetProperty(tcPropertyName AS String) AS Variant
        IF VARTYPE(THIS.OriginalContext) = "O" AND PEMSTATUS(THIS.OriginalContext, tcPropertyName, 5)
            RETURN GETPEM(THIS.OriginalContext, tcPropertyName)
        ENDIF
        RETURN .NULL.
    ENDFUNC
    
    FUNCTION SetProperty(tcPropertyName AS String, tvValue AS Variant)
        IF VARTYPE(THIS.OriginalContext) = "O" AND PEMSTATUS(THIS.OriginalContext, tcPropertyName, 5)
            RETURN PUTPEM(THIS.OriginalContext, tcPropertyName, tvValue)
        ENDIF
        RETURN .F.
    ENDFUNC
    
    FUNCTION CallMethod(tcMethodName AS String, tvParam1 AS Variant, tvParam2 AS Variant, tvParam3 AS Variant)
        IF VARTYPE(THIS.OriginalContext) = "O" AND PEMSTATUS(THIS.OriginalContext, tcMethodName, 5)
            DO CASE
                CASE PCOUNT() = 1
                    RETURN THIS.OriginalContext.&tcMethodName()
                CASE PCOUNT() = 2  
                    RETURN THIS.OriginalContext.&tcMethodName(tvParam1)
                CASE PCOUNT() = 3
                    RETURN THIS.OriginalContext.&tcMethodName(tvParam1, tvParam2)
                CASE PCOUNT() = 4
                    RETURN THIS.OriginalContext.&tcMethodName(tvParam1, tvParam2, tvParam3)
            ENDCASE
        ENDIF
        RETURN .NULL.
    ENDFUNC
    
    *-- Metode noi care extind functionalitatea
    FUNCTION GetService(tcInterface AS String) AS Object
        IF VARTYPE(THIS.DIContainer) = "O"
            RETURN THIS.DIContainer.Resolve(tcInterface)
        ENDIF
        RETURN .NULL.
    ENDFUNC
    
    FUNCTION GetSetting(tcPath AS String, tvDefault AS Variant) AS Variant
        IF VARTYPE(THIS.ConfigManager) = "O"
            RETURN THIS.ConfigManager.GetSetting(tcPath, tvDefault)
        ENDIF
        RETURN tvDefault
    ENDFUNC
    
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
ENDDEFINE

*!*-----------------------------------------------------------------------------
*!* FUNCTION: SAFT_Migrate_To_Enhanced
*!* SCOP:  Functie helper pentru migrarea de la codul original la cel imbunatatit
*!*-----------------------------------------------------------------------------
FUNCTION SAFT_Migrate_To_Enhanced(tdData1 AS Date, tdData2 AS Date, tcTipDeclaratie AS String, tnSegmente AS Integer)
    LOCAL llUseEnhanced AS Boolean, llSuccess AS Boolean
    LOCAL loOriginalContext AS Object, loAdapter AS Object
    
    *-- Verifica daca componentele imbunatatite sunt disponibile
    llUseEnhanced = .T.
    
    TRY
        *-- Incearca sa creeze componentele imbunatatite
        LOCAL loDIContainer AS Object
        loDIContainer = CREATEOBJECT("SAFT_DIContainer")
        loDIContainer = .NULL.  && Release pentru test
        
    CATCH
        llUseEnhanced = .F.
    ENDTRY
    
    IF llUseEnhanced
        *-- Foloseste arhitectura imbunatatita
        ? "Using Enhanced SAFT Architecture..."
        SET PROCEDURE TO SAFT_Enhanced_Main.prg ADDITIVE
        llSuccess = SAFT_Enhanced_Main(tdData1, tdData2, tcTipDeclaratie, tnSegmente)
    ELSE
        *-- Fallback la arhitectura originala
        ? "Falling back to Original SAFT Architecture..."
        SET PROCEDURE TO SAFT_Main_Advanced.prg ADDITIVE
        llSuccess = SAFT_Main_Advanced(tdData1, tdData2, tcTipDeclaratie, tnSegmente)
    ENDIF
    
    RETURN llSuccess
ENDFUNC

*!*-----------------------------------------------------------------------------
*!* FUNCTION: SAFT_Check_Enhancement_Compatibility
*!* SCOP:  Verifica compatibilitatea cu imbunatatirile
*!*-----------------------------------------------------------------------------
FUNCTION SAFT_Check_Enhancement_Compatibility()
    LOCAL llCompatible AS Boolean, lcReport AS String
    LOCAL ARRAY aRequiredFiles[7]
    LOCAL i AS Integer, lcFile AS String
    
    aRequiredFiles[1] = "SAFT_DI_Container.prg"
    aRequiredFiles[2] = "SAFT_ConfigManager.prg"
    aRequiredFiles[3] = "SAFT_Exception_Hierarchy.prg"
    aRequiredFiles[4] = "SAFT_HandlerFactory.prg"
    aRequiredFiles[5] = "SAFT_PerformanceMonitor.prg"
    aRequiredFiles[6] = "SAFT_AsyncProcessor.prg"
    aRequiredFiles[7] = "SAFT_Enhanced_Main.prg"
    
    llCompatible = .T.
    lcReport = "SAFT Enhancement Compatibility Check:" + CHR(13) + CHR(10)
    
    FOR i = 1 TO ALEN(aRequiredFiles)
        lcFile = aRequiredFiles[i]
        IF FILE(lcFile)
            lcReport = lcReport + "✓ " + lcFile + " - Found" + CHR(13) + CHR(10)
        ELSE
            lcReport = lcReport + "✗ " + lcFile + " - Missing" + CHR(13) + CHR(10)
            llCompatible = .F.
        ENDIF
    ENDFOR
    
    lcReport = lcReport + CHR(13) + CHR(10)
    lcReport = lcReport + "Compatibility Status: " + IIF(llCompatible, "COMPATIBLE", "NOT COMPATIBLE") + CHR(13) + CHR(10)
    
    ? lcReport
    
    RETURN llCompatible
ENDFUNC