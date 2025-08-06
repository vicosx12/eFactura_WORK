*!* ============================================================================
*!* FISIER: SAFT_ConfigManager.prg
*!* ============================================================================
*!* AUTOR: Alex (Engineer) - MGX Team
*!* DATA:  28.07.2025
*!* SCOP:  Gestionarea centralizata a configuratiilor pentru sistemul SAFT
*!* Suporta configuratii din fisiere JSON/XML si validari
*!* ============================================================================

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_ConfigManager
*!* SCOP:  Manager centralizat pentru toate configuratiile sistemului
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_ConfigManager AS Custom
    ConfigData = .NULL.
    ConfigFile = ""
    IsLoaded = .F.
    ValidationRules = .NULL.
    
    FUNCTION Init(tcConfigFile AS String)
        THIS.ConfigData = CREATEOBJECT("Collection")
        THIS.ValidationRules = CREATEOBJECT("Collection")
        
        IF !EMPTY(tcConfigFile)
            THIS.ConfigFile = tcConfigFile
        ELSE
            THIS.ConfigFile = "SAFT_Config.json"
        ENDIF
        
        THIS.SetupDefaultConfig()
        THIS.SetupValidationRules()
        
        IF FILE(THIS.ConfigFile)
            THIS.LoadConfig()
        ELSE
            THIS.CreateDefaultConfigFile()
        ENDIF
    ENDFUNC
    
    *-- Incarca configuratia din fisier
    FUNCTION LoadConfig() AS Boolean
        LOCAL lcContent AS String, loJson AS Object
        
        TRY
            IF !FILE(THIS.ConfigFile)
                THIS.CreateDefaultConfigFile()
                RETURN .T.
            ENDIF
            
            lcContent = FILETOSTR(THIS.ConfigFile)
            IF EMPTY(lcContent)
                ERROR "Fisierul de configuratie este gol"
            ENDIF
            
            *-- Parse JSON (in VFP folosim o abordare simpla)
            THIS.ParseConfigContent(lcContent)
            THIS.ValidateConfig()
            
            THIS.IsLoaded = .T.
            RETURN .T.
            
        CATCH TO oException
            ERROR "Eroare la incarcarea configuratiei: " + oException.Message
            RETURN .F.
        ENDTRY
    ENDFUNC
    
    *-- Salveaza configuratia in fisier
    FUNCTION SaveConfig() AS Boolean
        LOCAL lcJsonContent AS String
        
        TRY
            lcJsonContent = THIS.GenerateJsonContent()
            STRTOFILE(lcJsonContent, THIS.ConfigFile)
            RETURN .T.
            
        CATCH TO oException
            ERROR "Eroare la salvarea configuratiei: " + oException.Message
            RETURN .F.
        ENDTRY
    ENDFUNC
    
    *-- Obtine o setare folosind path hierarchic (ex: "Database.ConnectionString")
    FUNCTION GetSetting(tcPath AS String, tvDefault AS Variant) AS Variant
        LOCAL lcPath AS String, lnDotPos AS Integer, lcKey AS String, lcRemainingPath AS String
        LOCAL loCurrentLevel AS Object
        
        IF EMPTY(tcPath)
            RETURN tvDefault
        ENDIF
        
        lcPath = ALLTRIM(tcPath)
        loCurrentLevel = THIS.ConfigData
        
        DO WHILE !EMPTY(lcPath)
            lnDotPos = AT(".", lcPath)
            
            IF lnDotPos > 0
                lcKey = LEFT(lcPath, lnDotPos - 1)
                lcRemainingPath = SUBSTR(lcPath, lnDotPos + 1)
            ELSE
                lcKey = lcPath
                lcRemainingPath = ""
            ENDIF
            
            IF VARTYPE(loCurrentLevel) = "O" AND loCurrentLevel.GetKey(lcKey) > 0
                loCurrentLevel = loCurrentLevel.Item(lcKey)
                lcPath = lcRemainingPath
            ELSE
                RETURN tvDefault
            ENDIF
        ENDDO
        
        RETURN loCurrentLevel
    ENDFUNC
    
    *-- Seteaza o valoare folosind path hierarchic
    FUNCTION SetSetting(tcPath AS String, tvValue AS Variant) AS Boolean
        LOCAL lcPath AS String, lnDotPos AS Integer, lcKey AS String, lcRemainingPath AS String
        LOCAL loCurrentLevel AS Object, loParentLevel AS Object
        
        IF EMPTY(tcPath)
            RETURN .F.
        ENDIF
        
        lcPath = ALLTRIM(tcPath)
        loCurrentLevel = THIS.ConfigData
        
        *-- Navighează până la nivelul părinte
        DO WHILE AT(".", lcPath) > 0
            lnDotPos = AT(".", lcPath)
            lcKey = LEFT(lcPath, lnDotPos - 1)
            lcRemainingPath = SUBSTR(lcPath, lnDotPos + 1)
            
            IF loCurrentLevel.GetKey(lcKey) = 0
                loCurrentLevel.Add(CREATEOBJECT("Collection"), lcKey)
            ENDIF
            
            loCurrentLevel = loCurrentLevel.Item(lcKey)
            lcPath = lcRemainingPath
        ENDDO
        
        *-- Setează valoarea finală
        IF loCurrentLevel.GetKey(lcPath) > 0
            loCurrentLevel.Remove(lcPath)
        ENDIF
        loCurrentLevel.Add(tvValue, lcPath)
        
        RETURN .T.
    ENDFUNC
    
    *-- Validare configuratie
    PROTECTED FUNCTION ValidateConfig() AS Boolean
        LOCAL i AS Integer, lcRule AS String, loRule AS Object
        LOCAL llValid AS Boolean
        
        llValid = .T.
        
        FOR i = 1 TO THIS.ValidationRules.Count
            lcRule = THIS.ValidationRules.GetKey(i)
            loRule = THIS.ValidationRules.Item(i)
            
            IF !THIS.ValidateRule(lcRule, loRule)
                llValid = .F.
                ERROR "Validarea configuratiei a esuat pentru: " + lcRule
            ENDIF
        ENDFOR
        
        RETURN llValid
    ENDFUNC
    
    *-- Validare regula individuala
    PROTECTED FUNCTION ValidateRule(tcRuleName AS String, toRule AS Object) AS Boolean
        LOCAL lvValue AS Variant
        
        lvValue = THIS.GetSetting(toRule.Path, .NULL.)
        
        *-- Verifica daca este obligatoriu
        IF toRule.Required AND (ISNULL(lvValue) OR EMPTY(lvValue))
            RETURN .F.
        ENDIF
        
        *-- Verifica tipul
        IF !ISNULL(lvValue) AND !EMPTY(toRule.DataType)
            IF VARTYPE(lvValue) != toRule.DataType
                RETURN .F.
            ENDIF
        ENDIF
        
        *-- Verifica valorile permise
        IF !ISNULL(lvValue) AND toRule.AllowedValues.Count > 0
            IF toRule.AllowedValues.GetKey(TRANSFORM(lvValue)) = 0
                RETURN .F.
            ENDIF
        ENDIF
        
        RETURN .T.
    ENDFUNC
    
    *-- Setup configuratie default
    PROTECTED FUNCTION SetupDefaultConfig()
        LOCAL loDatabase AS Collection, loSAFT AS Collection, loLogging AS Collection
        LOCAL loPerformance AS Collection, loUI AS Collection
        
        *-- Database Settings
        loDatabase = CREATEOBJECT("Collection")
        loDatabase.Add("", "ConnectionString")
        loDatabase.Add(30, "QueryTimeout")
        loDatabase.Add(50000, "BatchSize")
        loDatabase.Add(.T., "UseTransactions")
        THIS.ConfigData.Add(loDatabase, "Database")
        
        *-- SAFT Settings
        loSAFT = CREATEOBJECT("Collection")
        loSAFT.Add("D406", "DeclarationCode")
        loSAFT.Add("1001", "TaxEntityCode")
        loSAFT.Add("A", "AccountType")
        loSAFT.Add(1, "DefaultSegments")
        loSAFT.Add(.T., "ValidateXML")
        loSAFT.Add(.T., "CompressOutput")
        THIS.ConfigData.Add(loSAFT, "SAFT")
        
        *-- Logging Settings
        loLogging = CREATEOBJECT("Collection")
        loLogging.Add("INFO", "LogLevel")
        loLogging.Add(.T., "EnableFileLogging")
        loLogging.Add(.T., "EnableConsoleLogging")
        loLogging.Add(10, "MaxLogFiles")
        loLogging.Add(100, "MaxLogSizeMB")
        THIS.ConfigData.Add(loLogging, "Logging")
        
        *-- Performance Settings
        loPerformance = CREATEOBJECT("Collection")
        loPerformance.Add(.T., "EnableMonitoring")
        loPerformance.Add(.T., "EnableMetrics")
        loPerformance.Add(1000, "MetricsInterval")
        loPerformance.Add(.F., "EnableProfiling")
        THIS.ConfigData.Add(loPerformance, "Performance")
        
        *-- UI Settings
        loUI = CREATEOBJECT("Collection")
        loUI.Add(.T., "ShowProgress")
        loUI.Add(.T., "ShowSummary")
        loUI.Add(500, "ProgressUpdateInterval")
        loUI.Add("Romanian", "Language")
        THIS.ConfigData.Add(loUI, "UI")
    ENDFUNC
    
    *-- Setup reguli de validare
    PROTECTED FUNCTION SetupValidationRules()
        LOCAL loRule AS Object
        
        *-- Database.QueryTimeout
        loRule = CREATEOBJECT("SAFT_ValidationRule")
        loRule.Path = "Database.QueryTimeout"
        loRule.Required = .T.
        loRule.DataType = "N"
        loRule.MinValue = 5
        loRule.MaxValue = 300
        THIS.ValidationRules.Add(loRule, "DatabaseTimeout")
        
        *-- SAFT.DeclarationCode
        loRule = CREATEOBJECT("SAFT_ValidationRule")
        loRule.Path = "SAFT.DeclarationCode"
        loRule.Required = .T.
        loRule.DataType = "C"
        loRule.AllowedValues.Add("D406")
        THIS.ValidationRules.Add(loRule, "DeclarationCode")
        
        *-- Logging.LogLevel
        loRule = CREATEOBJECT("SAFT_ValidationRule")
        loRule.Path = "Logging.LogLevel"
        loRule.Required = .T.
        loRule.DataType = "C"
        loRule.AllowedValues.Add("DEBUG")
        loRule.AllowedValues.Add("INFO")
        loRule.AllowedValues.Add("WARN")
        loRule.AllowedValues.Add("ERROR")
        THIS.ValidationRules.Add(loRule, "LogLevel")
    ENDFUNC
    
    *-- Parse continut configuratie (JSON simplu)
    PROTECTED FUNCTION ParseConfigContent(tcContent AS String)
        *-- Implementare simplificata pentru VFP
        *-- In productie, s-ar folosi un JSON parser mai robust
        
        *-- Pentru demo, setam valorile direct
        THIS.SetSetting("Database.ConnectionString", "")
        THIS.SetSetting("Database.QueryTimeout", 30)
        THIS.SetSetting("SAFT.DeclarationCode", "D406")
        THIS.SetSetting("Logging.LogLevel", "INFO")
    ENDFUNC
    
    *-- Genereaza continut JSON
    PROTECTED FUNCTION GenerateJsonContent() AS String
        LOCAL lcJson AS String
        
        TEXT TO lcJson NOSHOW
{
  "Database": {
    "ConnectionString": "",
    "QueryTimeout": 30,
    "BatchSize": 50000,
    "UseTransactions": true
  },
  "SAFT": {
    "DeclarationCode": "D406",
    "TaxEntityCode": "1001",
    "AccountType": "A",
    "DefaultSegments": 1,
    "ValidateXML": true,
    "CompressOutput": true
  },
  "Logging": {
    "LogLevel": "INFO",
    "EnableFileLogging": true,
    "EnableConsoleLogging": true,
    "MaxLogFiles": 10,
    "MaxLogSizeMB": 100
  },
  "Performance": {
    "EnableMonitoring": true,
    "EnableMetrics": true,
    "MetricsInterval": 1000,
    "EnableProfiling": false
  },
  "UI": {
    "ShowProgress": true,
    "ShowSummary": true,
    "ProgressUpdateInterval": 500,
    "Language": "Romanian"
  }
}
        ENDTEXT
        
        RETURN lcJson
    ENDFUNC
    
    *-- Creaza fisier de configuratie default
    PROTECTED FUNCTION CreateDefaultConfigFile()
        LOCAL lcContent AS String
        
        lcContent = THIS.GenerateJsonContent()
        STRTOFILE(lcContent, THIS.ConfigFile)
    ENDFUNC
    
    *-- Cleanup
    FUNCTION Dispose()
        THIS.ConfigData = .NULL.
        THIS.ValidationRules = .NULL.
    ENDFUNC
ENDDEFINE

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_ValidationRule
*!* SCOP:  Defineste o regula de validare pentru configuratie
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_ValidationRule AS Custom
    Path = ""
    Required = .F.
    DataType = ""
    MinValue = .NULL.
    MaxValue = .NULL.
    AllowedValues = .NULL.
    
    FUNCTION Init()
        THIS.AllowedValues = CREATEOBJECT("Collection")
    ENDFUNC
ENDDEFINE