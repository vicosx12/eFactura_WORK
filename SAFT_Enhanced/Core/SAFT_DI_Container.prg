*!* ============================================================================
*!* FISIER: SAFT_DI_Container.prg
*!* ============================================================================
*!* AUTOR: Alex (Engineer) - MGX Team
*!* DATA:  28.07.2025
*!* SCOP:  Dependency Injection Container pentru arhitectura SAFT
*!* Elimina cuplarea tare si permite injectarea de dependinte
*!* ============================================================================

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_DIContainer
*!* SCOP:  Container pentru gestionarea dependintelor si injectarea lor automata
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_DIContainer AS Custom
    Dependencies = .NULL.
    Singletons = .NULL.
    
    FUNCTION Init()
        THIS.Dependencies = CREATEOBJECT("Collection")
        THIS.Singletons = CREATEOBJECT("Collection")
        THIS.RegisterDefaults()
    ENDFUNC
    
    *-- Inregistrare dependinta ca clasa
    FUNCTION Register(tcInterface AS String, tcImplementationClass AS String, tlSingleton AS Boolean)
        LOCAL loRegistration AS Object
        
        IF EMPTY(tcInterface) OR EMPTY(tcImplementationClass)
            ERROR "Interface si implementarea nu pot fi goale"
        ENDIF
        
        loRegistration = CREATEOBJECT("SAFT_DI_Registration")
        loRegistration.Interface = tcInterface
        loRegistration.ImplementationClass = tcImplementationClass
        loRegistration.IsSingleton = IIF(VARTYPE(tlSingleton) = "L", tlSingleton, .F.)
        
        IF THIS.Dependencies.GetKey(tcInterface) > 0
            THIS.Dependencies.Remove(tcInterface)
        ENDIF
        
        THIS.Dependencies.Add(loRegistration, tcInterface)
        
        RETURN THIS && Fluent interface
    ENDFUNC
    
    *-- Inregistrare dependinta ca instanta
    FUNCTION RegisterInstance(tcInterface AS String, toInstance AS Object)
        IF EMPTY(tcInterface) OR VARTYPE(toInstance) != "O"
            ERROR "Interface si instanta trebuie sa fie valide"
        ENDIF
        
        IF THIS.Singletons.GetKey(tcInterface) > 0
            THIS.Singletons.Remove(tcInterface)
        ENDIF
        
        THIS.Singletons.Add(toInstance, tcInterface)
        RETURN THIS
    ENDFUNC
    
    *-- Rezolvare dependinta
    FUNCTION Resolve(tcInterface AS String) AS Object
        LOCAL loRegistration AS Object, loInstance AS Object
        
        IF EMPTY(tcInterface)
            ERROR "Interface-ul nu poate fi gol"
        ENDIF
        
        *-- Verifica daca exista o instanta singleton
        IF THIS.Singletons.GetKey(tcInterface) > 0
            RETURN THIS.Singletons.Item(tcInterface)
        ENDIF
        
        *-- Verifica daca exista o inregistrare
        IF THIS.Dependencies.GetKey(tcInterface) = 0
            ERROR "Dependinta nu este inregistrata: " + tcInterface
        ENDIF
        
        loRegistration = THIS.Dependencies.Item(tcInterface)
        
        *-- Creaza instanta
        TRY
            loInstance = CREATEOBJECT(loRegistration.ImplementationClass)
            
            *-- Daca este singleton, salveaza instanta
            IF loRegistration.IsSingleton
                THIS.Singletons.Add(loInstance, tcInterface)
            ENDIF
            
            RETURN loInstance
            
        CATCH TO oException
            ERROR "Nu s-a putut crea instanta pentru " + tcInterface + ": " + oException.Message
        ENDTRY
    ENDFUNC
    
    *-- Verifica daca o dependinta este inregistrata
    FUNCTION IsRegistered(tcInterface AS String) AS Boolean
        RETURN THIS.Dependencies.GetKey(tcInterface) > 0 OR THIS.Singletons.GetKey(tcInterface) > 0
    ENDFUNC
    
    *-- Inregistrare dependinte implicite
    PROTECTED FUNCTION RegisterDefaults()
        *-- Inregistreaza componentele de baza ale sistemului SAFT
        THIS.Register("SAFT_Repository", "SAFT_Repository", .T.)
        THIS.Register("SAFT_Logger", "SAFT_Logger", .T.)
        THIS.Register("SAFT_ConfigManager", "SAFT_ConfigManager", .T.)
        THIS.Register("SAFT_PerformanceMonitor", "SAFT_PerformanceMonitor", .T.)
        THIS.Register("SAFT_HandlerFactory", "SAFT_HandlerFactory", .T.)
        
        *-- Progress UI
        THIS.Register("SAFT_Progress_UI", "SAFT_Progress_UI_Console", .F.)
        THIS.Register("SAFT_Summary_Collector", "SAFT_Summary_Collector", .F.)
        
        *-- Handlere
        THIS.Register("Handler_Setup", "Handler_Setup", .F.)
        THIS.Register("Handler_Generate_Header", "Handler_Generate_Header", .F.)
        THIS.Register("Handler_Generate_MasterFiles_Periodic", "Handler_Generate_MasterFiles_Periodic", .F.)
        THIS.Register("Handler_Generate_SourceDocuments", "Handler_Generate_SourceDocuments", .F.)
        THIS.Register("Handler_Generate_GeneralLedgerEntries", "Handler_Generate_GeneralLedgerEntries", .F.)
        THIS.Register("Handler_AssembleXML_Periodic", "Handler_AssembleXML_Periodic", .F.)
    ENDFUNC
    
    *-- Obtine lista tuturor dependintelor inregistrate
    FUNCTION GetRegisteredInterfaces() AS Collection
        LOCAL loResult AS Collection, i AS Integer
        loResult = CREATEOBJECT("Collection")
        
        FOR i = 1 TO THIS.Dependencies.Count
            loResult.Add(THIS.Dependencies.GetKey(i))
        ENDFOR
        
        FOR i = 1 TO THIS.Singletons.Count
            IF loResult.GetKey(THIS.Singletons.GetKey(i)) = 0
                loResult.Add(THIS.Singletons.GetKey(i))
            ENDIF
        ENDFOR
        
        RETURN loResult
    ENDFUNC
    
    *-- Cleanup - elibereaza toate resursele
    FUNCTION Dispose()
        LOCAL i AS Integer, loInstance AS Object
        
        *-- Elibereaza singletons
        FOR i = 1 TO THIS.Singletons.Count
            loInstance = THIS.Singletons.Item(i)
            IF VARTYPE(loInstance) = "O" AND PEMSTATUS(loInstance, "Dispose", 5)
                loInstance.Dispose()
            ENDIF
        ENDFOR
        
        THIS.Dependencies = .NULL.
        THIS.Singletons = .NULL.
    ENDFUNC
ENDDEFINE

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_DI_Registration
*!* SCOP:  Obiect pentru stocarea informatiilor despre o dependinta inregistrata
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_DI_Registration AS Custom
    Interface = ""
    ImplementationClass = ""
    IsSingleton = .F.
    
    FUNCTION Init(tcInterface AS String, tcImplementationClass AS String, tlSingleton AS Boolean)
        IF !EMPTY(tcInterface)
            THIS.Interface = tcInterface
        ENDIF
        IF !EMPTY(tcImplementationClass)
            THIS.ImplementationClass = tcImplementationClass
        ENDIF
        IF VARTYPE(tlSingleton) = "L"
            THIS.IsSingleton = tlSingleton
        ENDIF
    ENDFUNC
ENDDEFINE

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_ServiceLocator (Alternative sau complement la DI Container)
*!* SCOP:  Service Locator pattern pentru acces usor la servicii
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_ServiceLocator AS Custom
    Container = .NULL.
    
    FUNCTION Init(toDIContainer AS SAFT_DIContainer)
        IF VARTYPE(toDIContainer) = "O"
            THIS.Container = toDIContainer
        ELSE
            THIS.Container = CREATEOBJECT("SAFT_DIContainer")
        ENDIF
    ENDFUNC
    
    FUNCTION GetService(tcInterface AS String) AS Object
        RETURN THIS.Container.Resolve(tcInterface)
    ENDFUNC
    
    FUNCTION GetRepository() AS Object
        RETURN THIS.GetService("SAFT_Repository")
    ENDFUNC
    
    FUNCTION GetLogger() AS Object
        RETURN THIS.GetService("SAFT_Logger")
    ENDFUNC
    
    FUNCTION GetConfigManager() AS Object
        RETURN THIS.GetService("SAFT_ConfigManager")
    ENDFUNC
    
    FUNCTION GetPerformanceMonitor() AS Object
        RETURN THIS.GetService("SAFT_PerformanceMonitor")
    ENDFUNC
ENDDEFINE