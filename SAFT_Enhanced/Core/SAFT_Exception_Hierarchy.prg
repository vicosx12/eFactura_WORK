*!* ============================================================================
*!* FISIER: SAFT_Exception_Hierarchy.prg
*!* ============================================================================
*!* AUTOR: Alex (Engineer) - MGX Team
*!* DATA:  28.07.2025
*!* SCOP:  Ierarhie de exceptii custom pentru sistemul SAFT
*!* Imbunatateste debugging-ul si gestionarea erorilor
*!* ============================================================================

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_Exception_Base
*!* SCOP:  Clasa de baza pentru toate exceptiile SAFT
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_Exception_Base AS Exception
    ErrorCode = ""
    Context = .NULL.
    InnerException = .NULL.
    Timestamp = {}
    ProcessStep = ""
    UserMessage = ""
    TechnicalMessage = ""
    
    FUNCTION Init(tcMessage AS String, tcErrorCode AS String, toContext AS Object, toInnerException AS Object)
        DODEFAULT(tcMessage)
        
        THIS.ErrorCode = IIF(EMPTY(tcErrorCode), "SAFT_GENERAL_ERROR", tcErrorCode)
        THIS.Context = toContext
        THIS.InnerException = toInnerException
        THIS.Timestamp = DATETIME()
        THIS.TechnicalMessage = tcMessage
        THIS.UserMessage = THIS.GetUserFriendlyMessage()
    ENDFUNC
    
    *-- Mesaj prietenos pentru utilizator
    FUNCTION GetUserFriendlyMessage() AS String
        DO CASE
            CASE THIS.ErrorCode = "SAFT_VALIDATION_ERROR"
                RETURN "S-a detectat o eroare de validare în datele SAF-T."
            CASE THIS.ErrorCode = "SAFT_DATA_ERROR"
                RETURN "S-a detectat o problemă cu datele din baza de date."
            CASE THIS.ErrorCode = "SAFT_CONFIG_ERROR"
                RETURN "Configurația sistemului SAF-T nu este validă."
            CASE THIS.ErrorCode = "SAFT_XML_ERROR"
                RETURN "S-a detectat o eroare la generarea fișierului XML."
            OTHERWISE
                RETURN "S-a produs o eroare în procesul de generare SAF-T."
        ENDCASE
    ENDFUNC
    
    *-- Mesaj detaliat pentru log
    FUNCTION GetDetailedMessage() AS String
        LOCAL lcMessage AS String
        
        lcMessage = "=== SAFT EXCEPTION DETAILS ===" + CHR(13) + CHR(10)
        lcMessage = lcMessage + "Error Code: " + THIS.ErrorCode + CHR(13) + CHR(10)
        lcMessage = lcMessage + "Timestamp: " + TRANSFORM(THIS.Timestamp) + CHR(13) + CHR(10)
        lcMessage = lcMessage + "Process Step: " + THIS.ProcessStep + CHR(13) + CHR(10)
        lcMessage = lcMessage + "Technical Message: " + THIS.TechnicalMessage + CHR(13) + CHR(10)
        lcMessage = lcMessage + "User Message: " + THIS.UserMessage + CHR(13) + CHR(10)
        
        IF VARTYPE(THIS.Context) = "O"
            lcMessage = lcMessage + "Context: " + THIS.GetContextInfo() + CHR(13) + CHR(10)
        ENDIF
        
        IF VARTYPE(THIS.InnerException) = "O"
            lcMessage = lcMessage + "Inner Exception: " + THIS.InnerException.Message + CHR(13) + CHR(10)
        ENDIF
        
        lcMessage = lcMessage + "================================" + CHR(13) + CHR(10)
        
        RETURN lcMessage
    ENDFUNC
    
    *-- Informatii despre context
    PROTECTED FUNCTION GetContextInfo() AS String
        LOCAL lcInfo AS String
        
        IF VARTYPE(THIS.Context) = "O" AND PEMSTATUS(THIS.Context, "Class", 5)
            lcInfo = "Class: " + THIS.Context.Class
            
            IF PEMSTATUS(THIS.Context, "StartDate", 5) AND PEMSTATUS(THIS.Context, "EndDate", 5)
                lcInfo = lcInfo + ", Period: " + TRANSFORM(THIS.Context.StartDate) + " - " + TRANSFORM(THIS.Context.EndDate)
            ENDIF
            
            IF PEMSTATUS(THIS.Context, "DeclarationType", 5)
                lcInfo = lcInfo + ", Type: " + THIS.Context.DeclarationType
            ENDIF
        ELSE
            lcInfo = "Unknown context"
        ENDIF
        
        RETURN lcInfo
    ENDFUNC
ENDDEFINE

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_ValidationException
*!* SCOP:  Exceptie pentru erorile de validare a datelor
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_ValidationException AS SAFT_Exception_Base
    ValidationField = ""
    ValidationValue = ""
    ValidationRule = ""
    
    FUNCTION Init(tcMessage AS String, tcField AS String, tvValue AS Variant, tcRule AS String, toContext AS Object)
        DODEFAULT(tcMessage, "SAFT_VALIDATION_ERROR", toContext)
        
        THIS.ValidationField = tcField
        THIS.ValidationValue = TRANSFORM(tvValue)
        THIS.ValidationRule = tcRule
        THIS.ProcessStep = "Data Validation"
    ENDFUNC
    
    FUNCTION GetUserFriendlyMessage() AS String
        RETURN "Câmpul '" + THIS.ValidationField + "' nu respectă regula de validare: " + THIS.ValidationRule
    ENDFUNC
ENDDEFINE

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_DataException
*!* SCOP:  Exceptie pentru problemele cu accesul la date
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_DataException AS SAFT_Exception_Base
    SQLStatement = ""
    TableName = ""
    RecordCount = 0
    
    FUNCTION Init(tcMessage AS String, tcSQL AS String, tcTable AS String, tnRecords AS Integer, toContext AS Object)
        DODEFAULT(tcMessage, "SAFT_DATA_ERROR", toContext)
        
        THIS.SQLStatement = tcSQL
        THIS.TableName = tcTable
        THIS.RecordCount = tnRecords
        THIS.ProcessStep = "Data Access"
    ENDFUNC
    
    FUNCTION GetUserFriendlyMessage() AS String
        RETURN "S-a detectat o problemă la accesarea datelor din tabela: " + THIS.TableName
    ENDFUNC
ENDDEFINE

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_ConfigurationException
*!* SCOP:  Exceptie pentru problemele de configuratie
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_ConfigurationException AS SAFT_Exception_Base
    ConfigurationKey = ""
    ConfigurationValue = ""
    
    FUNCTION Init(tcMessage AS String, tcKey AS String, tvValue AS Variant, toContext AS Object)
        DODEFAULT(tcMessage, "SAFT_CONFIG_ERROR", toContext)
        
        THIS.ConfigurationKey = tcKey
        THIS.ConfigurationValue = TRANSFORM(tvValue)
        THIS.ProcessStep = "Configuration"
    ENDFUNC
    
    FUNCTION GetUserFriendlyMessage() AS String
        RETURN "Configurația '" + THIS.ConfigurationKey + "' nu este validă sau lipsește."
    ENDFUNC
ENDDEFINE

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_XMLException
*!* SCOP:  Exceptie pentru problemele de generare XML
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_XMLException AS SAFT_Exception_Base
    XMLElement = ""
    XMLContent = ""
    LineNumber = 0
    
    FUNCTION Init(tcMessage AS String, tcElement AS String, tcContent AS String, tnLine AS Integer, toContext AS Object)
        DODEFAULT(tcMessage, "SAFT_XML_ERROR", toContext)
        
        THIS.XMLElement = tcElement
        THIS.XMLContent = tcContent
        THIS.LineNumber = tnLine
        THIS.ProcessStep = "XML Generation"
    ENDFUNC
    
    FUNCTION GetUserFriendlyMessage() AS String
        LOCAL lcMessage AS String
        lcMessage = "S-a detectat o eroare la generarea elementului XML"
        IF !EMPTY(THIS.XMLElement)
            lcMessage = lcMessage + ": " + THIS.XMLElement
        ENDIF
        RETURN lcMessage
    ENDFUNC
ENDDEFINE

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_BusinessException
*!* SCOP:  Exceptie pentru erorile de logica de business
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_BusinessException AS SAFT_Exception_Base
    BusinessRule = ""
    ExpectedValue = ""
    ActualValue = ""
    
    FUNCTION Init(tcMessage AS String, tcRule AS String, tvExpected AS Variant, tvActual AS Variant, toContext AS Object)
        DODEFAULT(tcMessage, "SAFT_BUSINESS_ERROR", toContext)
        
        THIS.BusinessRule = tcRule
        THIS.ExpectedValue = TRANSFORM(tvExpected)
        THIS.ActualValue = TRANSFORM(tvActual)
        THIS.ProcessStep = "Business Logic"
    ENDFUNC
    
    FUNCTION GetUserFriendlyMessage() AS String
        RETURN "Regula de business '" + THIS.BusinessRule + "' nu este respectată."
    ENDFUNC
ENDDEFINE

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_SecurityException
*!* SCOP:  Exceptie pentru problemele de securitate si access control
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_SecurityException AS SAFT_Exception_Base
    UserContext = ""
    RequestedResource = ""
    RequiredPermission = ""
    
    FUNCTION Init(tcMessage AS String, tcUser AS String, tcResource AS String, tcPermission AS String, toContext AS Object)
        DODEFAULT(tcMessage, "SAFT_SECURITY_ERROR", toContext)
        
        THIS.UserContext = tcUser
        THIS.RequestedResource = tcResource
        THIS.RequiredPermission = tcPermission
        THIS.ProcessStep = "Security Check"
    ENDFUNC
    
    FUNCTION GetUserFriendlyMessage() AS String
        RETURN "Nu aveți permisiunea necesară pentru a executa această operațiune."
    ENDFUNC
ENDDEFINE

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_ExceptionHandler
*!* SCOP:  Handler centralizat pentru gestionarea exceptiilor SAFT
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_ExceptionHandler AS Custom
    Logger = .NULL.
    NotificationService = .NULL.
    
    FUNCTION Init(toLogger AS Object, toNotificationService AS Object)
        THIS.Logger = toLogger
        THIS.NotificationService = toNotificationService
    ENDFUNC
    
    *-- Gestioneaza o exceptie SAFT
    FUNCTION HandleException(toException AS SAFT_Exception_Base, tlShowUser AS Boolean, tlLogException AS Boolean)
        LOCAL lcDetailedMessage AS String, lcUserMessage AS String
        
        IF VARTYPE(toException) != "O"
            RETURN .F.
        ENDIF
        
        *-- Log exceptia
        IF tlLogException AND VARTYPE(THIS.Logger) = "O"
            lcDetailedMessage = toException.GetDetailedMessage()
            THIS.Logger.LogError(lcDetailedMessage)
        ENDIF
        
        *-- Afiseaza mesaj utilizator
        IF tlShowUser
            lcUserMessage = toException.GetUserFriendlyMessage()
            MESSAGEBOX(lcUserMessage, 16, "Eroare SAF-T")
        ENDIF
        
        *-- Notifica serviciul de monitorizare
        IF VARTYPE(THIS.NotificationService) = "O"
            THIS.NotificationService.NotifyException(toException)
        ENDIF
        
        RETURN .T.
    ENDFUNC
    
    *-- Wrapper pentru try-catch cu exceptii custom
    FUNCTION ExecuteWithExceptionHandling(toOperation AS Object, tcOperationName AS String, toContext AS Object)
        LOCAL llSuccess AS Boolean, loException AS Object
        
        llSuccess = .F.
        
        TRY
            llSuccess = toOperation.Execute(toContext)
            
        CATCH TO oVFPException
            *-- Converteste exceptia VFP la exceptie SAFT custom
            loException = THIS.ConvertToSAFTException(oVFPException, tcOperationName, toContext)
            THIS.HandleException(loException, .T., .T.)
            llSuccess = .F.
        ENDTRY
        
        RETURN llSuccess
    ENDFUNC
    
    *-- Converteste exceptie VFP la exceptie SAFT
    PROTECTED FUNCTION ConvertToSAFTException(toVFPException AS Exception, tcOperation AS String, toContext AS Object) AS SAFT_Exception_Base
        LOCAL loSAFTException AS SAFT_Exception_Base
        LOCAL lcMessage AS String
        
        lcMessage = "Eroare în " + tcOperation + ": " + toVFPException.Message
        
        *-- Determina tipul de exceptie bazat pe mesajul de eroare
        DO CASE
            CASE "SQL" $ UPPER(toVFPException.Message) OR "TABLE" $ UPPER(toVFPException.Message)
                loSAFTException = CREATEOBJECT("SAFT_DataException", lcMessage, "", "", 0, toContext)
                
            CASE "XML" $ UPPER(toVFPException.Message)
                loSAFTException = CREATEOBJECT("SAFT_XMLException", lcMessage, "", "", 0, toContext)
                
            CASE "CONFIG" $ UPPER(toVFPException.Message) OR "SETTING" $ UPPER(toVFPException.Message)
                loSAFTException = CREATEOBJECT("SAFT_ConfigurationException", lcMessage, "", "", toContext)
                
            OTHERWISE
                loSAFTException = CREATEOBJECT("SAFT_Exception_Base", lcMessage, "SAFT_GENERAL_ERROR", toContext)
        ENDCASE
        
        loSAFTException.InnerException = toVFPException
        loSAFTException.ProcessStep = tcOperation
        
        RETURN loSAFTException
    ENDFUNC
ENDDEFINE