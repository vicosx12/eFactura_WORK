*!* ============================================================================
*!* FISIER: SAFT_HandlerFactory.prg
*!* ============================================================================
*!* AUTOR: Alex (Engineer) - MGX Team
*!* DATA:  28.07.2025
*!* SCOP:  Factory pentru crearea dinamica de handlere cu auto-registration
*!* Permite extensibilitatea sistemului fara modificarea codului existent
*!* ============================================================================

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_HandlerFactory
*!* SCOP:  Factory pentru crearea si inregistrarea handlerelor
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_HandlerFactory AS Custom
    RegisteredHandlers = .NULL.
    DefaultHandlers = .NULL.
    
    FUNCTION Init()
        THIS.RegisteredHandlers = CREATEOBJECT("Collection")
        THIS.DefaultHandlers = CREATEOBJECT("Collection")
        THIS.RegisterDefaultHandlers()
    ENDFUNC
    
    *-- Inregistreaza un handler pentru un tip de declaratie
    FUNCTION RegisterHandler(tcDeclarationType AS String, tcStep AS String, tcHandlerClass AS String, tnOrder AS Integer)
        LOCAL lcKey AS String, loHandlerInfo AS Object
        
        IF EMPTY(tcDeclarationType) OR EMPTY(tcStep) OR EMPTY(tcHandlerClass)
            ERROR "Parametri obligatorii: DeclarationType, Step, HandlerClass"
        ENDIF
        
        lcKey = UPPER(tcDeclarationType) + "." + UPPER(tcStep)
        
        loHandlerInfo = CREATEOBJECT("SAFT_HandlerInfo")
        loHandlerInfo.DeclarationType = UPPER(tcDeclarationType)
        loHandlerInfo.Step = UPPER(tcStep)
        loHandlerInfo.HandlerClass = tcHandlerClass
        loHandlerInfo.Order = IIF(EMPTY(tnOrder), 100, tnOrder)
        loHandlerInfo.IsActive = .T.
        
        IF THIS.RegisteredHandlers.GetKey(lcKey) > 0
            THIS.RegisteredHandlers.Remove(lcKey)
        ENDIF
        
        THIS.RegisteredHandlers.Add(loHandlerInfo, lcKey)
        
        RETURN THIS && Fluent interface
    ENDFUNC
    
    *-- Inregistreaza handler cu conditii custom
    FUNCTION RegisterConditionalHandler(tcDeclarationType AS String, tcStep AS String, tcHandlerClass AS String, toCondition AS Object, tnOrder AS Integer)
        LOCAL lcKey AS String, loHandlerInfo AS Object
        
        lcKey = UPPER(tcDeclarationType) + "." + UPPER(tcStep) + ".CONDITIONAL"
        
        loHandlerInfo = CREATEOBJECT("SAFT_ConditionalHandlerInfo")
        loHandlerInfo.DeclarationType = UPPER(tcDeclarationType)
        loHandlerInfo.Step = UPPER(tcStep)
        loHandlerInfo.HandlerClass = tcHandlerClass
        loHandlerInfo.Order = IIF(EMPTY(tnOrder), 100, tnOrder)
        loHandlerInfo.Condition = toCondition
        loHandlerInfo.IsActive = .T.
        
        THIS.RegisteredHandlers.Add(loHandlerInfo, lcKey)
        
        RETURN THIS
    ENDFUNC
    
    *-- Creaza un handler specific
    FUNCTION CreateHandler(tcDeclarationType AS String, tcStep AS String, toContext AS Object) AS Object
        LOCAL lcKey AS String, loHandlerInfo AS Object, loHandler AS Object
        
        lcKey = UPPER(tcDeclarationType) + "." + UPPER(tcStep)
        
        IF THIS.RegisteredHandlers.GetKey(lcKey) = 0
            *-- Incearca sa gaseasca un handler default
            IF THIS.DefaultHandlers.GetKey(UPPER(tcStep)) > 0
                lcKey = UPPER(tcStep)
                loHandlerInfo = THIS.DefaultHandlers.Item(lcKey)
            ELSE
                ERROR "Handler nu este inregistrat: " + lcKey
            ENDIF
        ELSE
            loHandlerInfo = THIS.RegisteredHandlers.Item(lcKey)
        ENDIF
        
        *-- Verifica conditiile pentru handlere conditionale
        IF loHandlerInfo.Class = "SAFT_ConditionalHandlerInfo"
            IF VARTYPE(loHandlerInfo.Condition) = "O" AND !loHandlerInfo.Condition.IsMet(toContext)
                RETURN .NULL. && Handler-ul nu trebuie creat
            ENDIF
        ENDIF
        
        TRY
            loHandler = CREATEOBJECT(loHandlerInfo.HandlerClass)
            
            *-- Seteaza proprietati suplimentare daca handlerul le suporta
            IF PEMSTATUS(loHandler, "SetFactory", 5)
                loHandler.SetFactory(THIS)
            ENDIF
            
            IF PEMSTATUS(loHandler, "SetContext", 5)
                loHandler.SetContext(toContext)
            ENDIF
            
            RETURN loHandler
            
        CATCH TO oException
            ERROR "Nu s-a putut crea handlerul " + loHandlerInfo.HandlerClass + ": " + oException.Message
        ENDTRY
    ENDFUNC
    
    *-- Obtine lista de handlere pentru un tip de declaratie
    FUNCTION GetHandlersForDeclarationType(tcDeclarationType AS String, toContext AS Object) AS Collection
        LOCAL loHandlers AS Collection, i AS Integer, lcKey AS String, loHandlerInfo AS Object
        LOCAL loHandler AS Object
        
        loHandlers = CREATEOBJECT("Collection")
        
        *-- Cauta toate handlerele pentru tipul de declaratie
        FOR i = 1 TO THIS.RegisteredHandlers.Count
            lcKey = THIS.RegisteredHandlers.GetKey(i)
            loHandlerInfo = THIS.RegisteredHandlers.Item(i)
            
            IF loHandlerInfo.DeclarationType = UPPER(tcDeclarationType) AND loHandlerInfo.IsActive
                loHandler = THIS.CreateHandler(tcDeclarationType, loHandlerInfo.Step, toContext)
                
                IF VARTYPE(loHandler) = "O"
                    loHandlers.Add(loHandler, loHandlerInfo.Step + "_" + TRANSFORM(loHandlerInfo.Order))
                ENDIF
            ENDIF
        ENDFOR
        
        *-- Sorteaza dupa ordinea specificata
        RETURN THIS.SortHandlersByOrder(loHandlers)
    ENDFUNC
    
    *-- Construieste lantul de handlere pentru un tip de declaratie
    FUNCTION BuildHandlerChain(tcDeclarationType AS String, toContext AS Object) AS Object
        LOCAL loHandlers AS Collection, loFirstHandler AS Object, loPreviousHandler AS Object
        LOCAL i AS Integer, loCurrentHandler AS Object
        
        loHandlers = THIS.GetHandlersForDeclarationType(tcDeclarationType, toContext)
        
        IF loHandlers.Count = 0
            RETURN .NULL.
        ENDIF
        
        loFirstHandler = loHandlers.Item(1)
        loPreviousHandler = loFirstHandler
        
        FOR i = 2 TO loHandlers.Count
            loCurrentHandler = loHandlers.Item(i)
            loPreviousHandler.SetNext(loCurrentHandler)
            loPreviousHandler = loCurrentHandler
        ENDFOR
        
        RETURN loFirstHandler
    ENDFUNC
    
    *-- Dezactiveaza un handler
    FUNCTION DeactivateHandler(tcDeclarationType AS String, tcStep AS String)
        LOCAL lcKey AS String, loHandlerInfo AS Object
        
        lcKey = UPPER(tcDeclarationType) + "." + UPPER(tcStep)
        
        IF THIS.RegisteredHandlers.GetKey(lcKey) > 0
            loHandlerInfo = THIS.RegisteredHandlers.Item(lcKey)
            loHandlerInfo.IsActive = .F.
        ENDIF
        
        RETURN THIS
    ENDFUNC
    
    *-- Activeaza un handler
    FUNCTION ActivateHandler(tcDeclarationType AS String, tcStep AS String)
        LOCAL lcKey AS String, loHandlerInfo AS Object
        
        lcKey = UPPER(tcDeclarationType) + "." + UPPER(tcStep)
        
        IF THIS.RegisteredHandlers.GetKey(lcKey) > 0
            loHandlerInfo = THIS.RegisteredHandlers.Item(lcKey)
            loHandlerInfo.IsActive = .T.
        ENDIF
        
        RETURN THIS
    ENDFUNC
    
    *-- Inregistreaza handlerele default
    PROTECTED FUNCTION RegisterDefaultHandlers()
        *-- Handlere comune pentru toate tipurile de declaratii
        THIS.RegisterHandler("*", "SETUP", "Handler_Setup", 10)
        THIS.RegisterHandler("*", "HEADER", "Handler_Generate_Header", 20)
        THIS.RegisterHandler("*", "CLEANUP", "Handler_Cleanup", 999)
        
        *-- Handlere pentru declaratii periodice (L, T, S)
        THIS.RegisterHandler("L", "SOURCEDOCUMENTS", "Handler_Generate_SourceDocuments", 30)
        THIS.RegisterHandler("L", "GENERALLEDGER", "Handler_Generate_GeneralLedgerEntries", 40)
        THIS.RegisterHandler("L", "MASTERFILES", "Handler_Generate_MasterFiles_Periodic", 50)
        THIS.RegisterHandler("L", "ASSEMBLE", "Handler_AssembleXML_Periodic", 90)
        
        THIS.RegisterHandler("T", "SOURCEDOCUMENTS", "Handler_Generate_SourceDocuments", 30)
        THIS.RegisterHandler("T", "GENERALLEDGER", "Handler_Generate_GeneralLedgerEntries", 40)
        THIS.RegisterHandler("T", "MASTERFILES", "Handler_Generate_MasterFiles_Periodic", 50)
        THIS.RegisterHandler("T", "ASSEMBLE", "Handler_AssembleXML_Periodic", 90)
        
        THIS.RegisterHandler("S", "SOURCEDOCUMENTS", "Handler_Generate_SourceDocuments", 30)
        THIS.RegisterHandler("S", "GENERALLEDGER", "Handler_Generate_GeneralLedgerEntries", 40)
        THIS.RegisterHandler("S", "MASTERFILES", "Handler_Generate_MasterFiles_Periodic", 50)
        THIS.RegisterHandler("S", "ASSEMBLE", "Handler_AssembleXML_Periodic", 90)
        
        *-- Handlere pentru declaratie anuala (A)
        THIS.RegisterHandler("A", "MASTERFILES", "Handler_Generate_MasterFiles_Annual", 30)
        THIS.RegisterHandler("A", "SOURCEDOCUMENTS", "Handler_Generate_SourceDocuments_Annual", 40)
        THIS.RegisterHandler("A", "ASSEMBLE", "Handler_AssembleXML_Annual", 90)
        
        *-- Handlere pentru cerere (C)
        THIS.RegisterHandler("C", "MASTERFILES", "Handler_Generate_MasterFiles_Request", 30)
        THIS.RegisterHandler("C", "ASSEMBLE", "Handler_AssembleXML_Request", 90)
        
        *-- Salvez handlerele default separat pentru fallback
        THIS.DefaultHandlers.Add(CREATEOBJECT("SAFT_HandlerInfo", "*", "SETUP", "Handler_Setup", 10), "SETUP")
        THIS.DefaultHandlers.Add(CREATEOBJECT("SAFT_HandlerInfo", "*", "HEADER", "Handler_Generate_Header", 20), "HEADER")
        THIS.DefaultHandlers.Add(CREATEOBJECT("SAFT_HandlerInfo", "*", "CLEANUP", "Handler_Cleanup", 999), "CLEANUP")
    ENDFUNC
    
    *-- Sorteaza handlerele dupa order
    PROTECTED FUNCTION SortHandlersByOrder(toHandlers AS Collection) AS Collection
        LOCAL loSortedHandlers AS Collection, i AS Integer, j AS Integer
        LOCAL loCurrentHandler AS Object, loCompareHandler AS Object
        LOCAL lnCurrentOrder AS Integer, lnCompareOrder AS Integer
        
        *-- Sortare simpla prin bubble sort (pentru VFP)
        loSortedHandlers = CREATEOBJECT("Collection")
        
        *-- Copiaza handlerele cu ordinea lor
        FOR i = 1 TO toHandlers.Count
            loSortedHandlers.Add(toHandlers.Item(i))
        ENDFOR
        
        *-- Bubble sort dupa Order
        FOR i = 1 TO loSortedHandlers.Count - 1
            FOR j = i + 1 TO loSortedHandlers.Count
                loCurrentHandler = loSortedHandlers.Item(i)
                loCompareHandler = loSortedHandlers.Item(j)
                
                lnCurrentOrder = THIS.GetHandlerOrder(loCurrentHandler)
                lnCompareOrder = THIS.GetHandlerOrder(loCompareHandler)
                
                IF lnCurrentOrder > lnCompareOrder
                    *-- Swap
                    loSortedHandlers.Remove(i)
                    loSortedHandlers.Add(loCurrentHandler, , j)
                ENDIF
            ENDFOR
        ENDFOR
        
        RETURN loSortedHandlers
    ENDFUNC
    
    *-- Obtine ordinea unui handler
    PROTECTED FUNCTION GetHandlerOrder(toHandler AS Object) AS Integer
        IF PEMSTATUS(toHandler, "Order", 5)
            RETURN toHandler.Order
        ELSE
            RETURN 100 && Default order
        ENDIF
    ENDFUNC
    
    *-- Obtine informatii despre toate handlerele inregistrate
    FUNCTION GetRegistrationInfo() AS Collection
        LOCAL loInfo AS Collection, i AS Integer, lcKey AS String, loHandlerInfo AS Object
        LOCAL loInfoItem AS Object
        
        loInfo = CREATEOBJECT("Collection")
        
        FOR i = 1 TO THIS.RegisteredHandlers.Count
            lcKey = THIS.RegisteredHandlers.GetKey(i)
            loHandlerInfo = THIS.RegisteredHandlers.Item(i)
            
            loInfoItem = CREATEOBJECT("Empty")
            ADDPROPERTY(loInfoItem, "Key", lcKey)
            ADDPROPERTY(loInfoItem, "DeclarationType", loHandlerInfo.DeclarationType)
            ADDPROPERTY(loInfoItem, "Step", loHandlerInfo.Step)
            ADDPROPERTY(loInfoItem, "HandlerClass", loHandlerInfo.HandlerClass)
            ADDPROPERTY(loInfoItem, "Order", loHandlerInfo.Order)
            ADDPROPERTY(loInfoItem, "IsActive", loHandlerInfo.IsActive)
            
            loInfo.Add(loInfoItem, lcKey)
        ENDFOR
        
        RETURN loInfo
    ENDFUNC
    
    FUNCTION Dispose()
        THIS.RegisteredHandlers = .NULL.
        THIS.DefaultHandlers = .NULL.
    ENDFUNC
ENDDEFINE

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_HandlerInfo
*!* SCOP:  Informatii despre un handler inregistrat
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_HandlerInfo AS Custom
    DeclarationType = ""
    Step = ""
    HandlerClass = ""
    Order = 100
    IsActive = .T.
    
    FUNCTION Init(tcDeclarationType AS String, tcStep AS String, tcHandlerClass AS String, tnOrder AS Integer)
        IF !EMPTY(tcDeclarationType)
            THIS.DeclarationType = tcDeclarationType
        ENDIF
        IF !EMPTY(tcStep)
            THIS.Step = tcStep
        ENDIF
        IF !EMPTY(tcHandlerClass)
            THIS.HandlerClass = tcHandlerClass
        ENDIF
        IF !EMPTY(tnOrder)
            THIS.Order = tnOrder
        ENDIF
    ENDFUNC
ENDDEFINE

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_ConditionalHandlerInfo
*!* SCOP:  Informatii despre un handler conditional
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_ConditionalHandlerInfo AS SAFT_HandlerInfo
    Condition = .NULL.
    
    FUNCTION Init(tcDeclarationType AS String, tcStep AS String, tcHandlerClass AS String, toCondition AS Object, tnOrder AS Integer)
        DODEFAULT(tcDeclarationType, tcStep, tcHandlerClass, tnOrder)
        THIS.Condition = toCondition
    ENDFUNC
ENDDEFINE

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_HandlerCondition
*!* SCOP:  Conditie pentru activarea unui handler
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_HandlerCondition AS Custom
    ConditionType = ""
    ParameterName = ""
    ExpectedValue = ""
    ComparisonOperator = "="
    
    FUNCTION Init(tcType AS String, tcParameter AS String, tvExpectedValue AS Variant, tcOperator AS String)
        THIS.ConditionType = tcType
        THIS.ParameterName = tcParameter
        THIS.ExpectedValue = TRANSFORM(tvExpectedValue)
        THIS.ComparisonOperator = IIF(EMPTY(tcOperator), "=", tcOperator)
    ENDFUNC
    
    FUNCTION IsMet(toContext AS Object) AS Boolean
        LOCAL lvActualValue AS Variant
        
        DO CASE
            CASE THIS.ConditionType = "CONTEXT_PROPERTY"
                IF PEMSTATUS(toContext, THIS.ParameterName, 5)
                    lvActualValue = GETPEM(toContext, THIS.ParameterName)
                    RETURN THIS.CompareValues(lvActualValue, THIS.ExpectedValue)
                ENDIF
                
            CASE THIS.ConditionType = "CONFIG_SETTING"
                IF VARTYPE(toContext.ConfigManager) = "O"
                    lvActualValue = toContext.ConfigManager.GetSetting(THIS.ParameterName, "")
                    RETURN THIS.CompareValues(lvActualValue, THIS.ExpectedValue)
                ENDIF
                
            CASE THIS.ConditionType = "CUSTOM"
                *-- Pentru conditii custom, se poate suprascrie aceasta metoda
                RETURN .T.
        ENDCASE
        
        RETURN .F.
    ENDFUNC
    
    PROTECTED FUNCTION CompareValues(tvActual AS Variant, tvExpected AS Variant) AS Boolean
        LOCAL lcActual AS String, lcExpected AS String
        
        lcActual = TRANSFORM(tvActual)
        lcExpected = TRANSFORM(tvExpected)
        
        DO CASE
            CASE THIS.ComparisonOperator = "="
                RETURN lcActual = lcExpected
            CASE THIS.ComparisonOperator = "!="
                RETURN lcActual != lcExpected
            CASE THIS.ComparisonOperator = ">"
                RETURN VAL(lcActual) > VAL(lcExpected)
            CASE THIS.ComparisonOperator = "<"
                RETURN VAL(lcActual) < VAL(lcExpected)
            CASE THIS.ComparisonOperator = "CONTAINS"
                RETURN lcExpected $ UPPER(lcActual)
            OTHERWISE
                RETURN .F.
        ENDCASE
    ENDFUNC
ENDDEFINE