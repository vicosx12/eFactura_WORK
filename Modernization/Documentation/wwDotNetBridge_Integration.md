# Ghid de Integrare wwDotNetBridge

## Introducere

wwDotNetBridge este o componentă esențială pentru modernizarea aplicațiilor Visual FoxPro 9.0, oferind acces la librării .NET 64-bit din mediul VFP 32-bit.

## Instalare

### Pasul 1: Descărcare
```
Descărcați wwDotNetBridge de la:
https://github.com/RickStrahl/wwDotnetBridge
sau
https://webconnection.west-wind.com/
```

### Pasul 2: Instalare Componente
```
1. Copiați wwDotNetBridge.dll în directorul aplicației
2. Copiați ClrHost.dll în același director
3. Înregistrați componentele COM (dacă e necesar)
```

### Pasul 3: Referințe în VFP
```foxpro
* Setare cale către librării
SET PROCEDURE TO wwDotNetBridge.prg ADDITIVE

* Sau folosiți SET PATH
SET PATH TO (SYS(5)+SYS(2003)+"\Modernization\API") ADDITIVE
```

## Utilizare de Bază

### Inițializare Bridge

```foxpro
*====================================================================
* Procedură: InitializeDotNetBridge
* Scop: Inițializează wwDotNetBridge pentru acces la librării .NET
*====================================================================
FUNCTION InitializeDotNetBridge()
    LOCAL loBridge, llSuccess, lcError
    
    TRY
        * Creare instanță wwDotNetBridge
        loBridge = CREATEOBJECT("wwDotNetBridge", "V4")
        
        IF ISNULL(loBridge)
            lcError = "Nu s-a putut crea instanța wwDotNetBridge"
            MESSAGEBOX(lcError, 16, "Eroare Inițializare")
            RETURN .NULL.
        ENDIF
        
        * Verificare versiune .NET Framework
        lcVersion = loBridge.GetDotnetVersion()
        ? "Versiune .NET Framework: " + lcVersion
        
        llSuccess = .T.
        
    CATCH TO loException
        lcError = "Eroare la inițializare wwDotNetBridge: " + loException.Message
        MESSAGEBOX(lcError, 16, "Eroare")
        loBridge = .NULL.
        llSuccess = .F.
    ENDTRY
    
    RETURN loBridge
ENDFUNC

*====================================================================
* Exemplu utilizare
*====================================================================
LOCAL loBridge
loBridge = InitializeDotNetBridge()

IF !ISNULL(loBridge)
    ? "wwDotNetBridge inițializat cu succes!"
ENDIF
```

### Încărcare Assembly .NET

```foxpro
*====================================================================
* Procedură: LoadNetAssembly
* Scop: Încarcă un assembly .NET pentru utilizare
*====================================================================
FUNCTION LoadNetAssembly(toBridge, tcAssemblyPath)
    LOCAL llSuccess, lcError
    
    IF ISNULL(toBridge)
        MESSAGEBOX("Bridge-ul nu este inițializat", 16, "Eroare")
        RETURN .F.
    ENDIF
    
    TRY
        * Încărcare assembly
        llSuccess = toBridge.LoadAssembly(tcAssemblyPath)
        
        IF !llSuccess
            lcError = "Nu s-a putut încărca assembly-ul: " + tcAssemblyPath
            lcError = lcError + CHR(13) + toBridge.cErrorMsg
            MESSAGEBOX(lcError, 16, "Eroare")
            RETURN .F.
        ENDIF
        
        ? "Assembly încărcat: " + tcAssemblyPath
        
    CATCH TO loException
        lcError = "Eroare la încărcare assembly: " + loException.Message
        MESSAGEBOX(lcError, 16, "Eroare")
        RETURN .F.
    ENDTRY
    
    RETURN .T.
ENDFUNC

*====================================================================
* Exemplu utilizare
*====================================================================
LOCAL loBridge, lcAssemblyPath
loBridge = InitializeDotNetBridge()

IF !ISNULL(loBridge)
    lcAssemblyPath = FULLPATH(".\Modernization\API\MyCustomAPI.dll")
    
    IF LoadNetAssembly(loBridge, lcAssemblyPath)
        ? "Assembly pregătit pentru utilizare"
    ENDIF
ENDIF
```

## Integrare cu HttpClient .NET

### Apeluri HTTP/REST prin .NET

```foxpro
*====================================================================
* Procedură: CallRestAPIviaNet
* Scop: Apel API REST folosind HttpClient .NET
*====================================================================
FUNCTION CallRestAPIviaNet(tcUrl, tcMethod, tcJsonBody, tcAuthToken)
    LOCAL loBridge, loHttp, loResponse, lcResult, lcError
    LOCAL loHeaders, lcJson
    
    * Valori default
    tcMethod = IIF(EMPTY(tcMethod), "GET", UPPER(tcMethod))
    
    TRY
        * Inițializare bridge
        loBridge = InitializeDotNetBridge()
        
        IF ISNULL(loBridge)
            RETURN .NULL.
        ENDIF
        
        * Creare instanță HttpClient
        loHttp = loBridge.CreateInstance("System.Net.Http.HttpClient")
        
        IF ISNULL(loHttp)
            MESSAGEBOX("Nu s-a putut crea HttpClient", 16, "Eroare")
            RETURN .NULL.
        ENDIF
        
        * Setare timeout (30 secunde)
        loBridge.SetProperty(loHttp, "Timeout", ;
            loBridge.CreateInstance("System.TimeSpan").FromSeconds(30))
        
        * Adăugare header pentru autentificare
        IF !EMPTY(tcAuthToken)
            loHeaders = loBridge.GetProperty(loHttp, "DefaultRequestHeaders")
            loBridge.InvokeMethod(loHeaders, "Add", "Authorization", "Bearer " + tcAuthToken)
        ENDIF
        
        * Apel HTTP bazat pe metodă
        DO CASE
            CASE tcMethod = "GET"
                loResponse = loBridge.InvokeMethod(loHttp, "GetAsync", tcUrl)
                loResponse = loBridge.GetProperty(loResponse, "Result")
                
            CASE tcMethod = "POST"
                * Creare content JSON
                loContent = loBridge.CreateInstance("System.Net.Http.StringContent", ;
                    tcJsonBody, ;
                    loBridge.CreateInstance("System.Text.Encoding").UTF8, ;
                    "application/json")
                
                loResponse = loBridge.InvokeMethod(loHttp, "PostAsync", tcUrl, loContent)
                loResponse = loBridge.GetProperty(loResponse, "Result")
                
            CASE tcMethod = "PUT"
                loContent = loBridge.CreateInstance("System.Net.Http.StringContent", ;
                    tcJsonBody, ;
                    loBridge.CreateInstance("System.Text.Encoding").UTF8, ;
                    "application/json")
                
                loResponse = loBridge.InvokeMethod(loHttp, "PutAsync", tcUrl, loContent)
                loResponse = loBridge.GetProperty(loResponse, "Result")
                
            CASE tcMethod = "DELETE"
                loResponse = loBridge.InvokeMethod(loHttp, "DeleteAsync", tcUrl)
                loResponse = loBridge.GetProperty(loResponse, "Result")
                
            OTHERWISE
                MESSAGEBOX("Metodă HTTP nesuportată: " + tcMethod, 16, "Eroare")
                RETURN .NULL.
        ENDCASE
        
        * Verificare status code
        lnStatusCode = loBridge.GetProperty(loResponse, "StatusCode")
        ? "Status Code: " + TRANSFORM(lnStatusCode)
        
        * Citire răspuns
        loTask = loBridge.InvokeMethod(loResponse, "Content.ReadAsStringAsync")
        lcResult = loBridge.GetProperty(loTask, "Result")
        
        * Verificare succes
        llSuccess = loBridge.GetProperty(loResponse, "IsSuccessStatusCode")
        
        IF !llSuccess
            lcError = "Eroare API - Status: " + TRANSFORM(lnStatusCode)
            ? lcError
            ? "Răspuns: " + lcResult
        ENDIF
        
    CATCH TO loException
        lcError = "Eroare la apel API: " + loException.Message
        MESSAGEBOX(lcError, 16, "Eroare")
        RETURN .NULL.
    ENDTRY
    
    RETURN lcResult
ENDFUNC

*====================================================================
* Exemplu utilizare
*====================================================================
LOCAL lcUrl, lcMethod, lcJson, lcToken, lcResponse

lcUrl = "https://api.anaf.ro/prod/FCTEL/rest/upload"
lcMethod = "POST"
lcJson = '{"invoice_id": "123", "amount": 1000.00}'
lcToken = "your_oauth_token_here"

lcResponse = CallRestAPIviaNet(lcUrl, lcMethod, lcJson, lcToken)

IF !ISNULL(lcResponse)
    ? "Răspuns API:"
    ? lcResponse
ENDIF
```

## Parsare JSON cu .NET

```foxpro
*====================================================================
* Procedură: ParseJsonWithNet
* Scop: Parsare JSON folosind Newtonsoft.Json (Json.NET)
*====================================================================
FUNCTION ParseJsonWithNet(tcJsonString)
    LOCAL loBridge, loJson, loResult
    
    TRY
        loBridge = InitializeDotNetBridge()
        
        IF ISNULL(loBridge)
            RETURN .NULL.
        ENDIF
        
        * Încărcare Newtonsoft.Json (trebuie să fie disponibil)
        IF !loBridge.LoadAssembly("Newtonsoft.Json.dll")
            MESSAGEBOX("Nu s-a putut încărca Newtonsoft.Json.dll", 16, "Eroare")
            RETURN .NULL.
        ENDIF
        
        * Parsare JSON
        loJson = loBridge.InvokeStaticMethod(;
            "Newtonsoft.Json.JsonConvert", ;
            "DeserializeObject", ;
            tcJsonString)
        
        RETURN loJson
        
    CATCH TO loException
        MESSAGEBOX("Eroare parsare JSON: " + loException.Message, 16, "Eroare")
        RETURN .NULL.
    ENDTRY
ENDFUNC

*====================================================================
* Exemplu utilizare
*====================================================================
LOCAL lcJson, loObject
lcJson = '{"name":"Test Company","cui":"RO12345678","active":true}'

loObject = ParseJsonWithNet(lcJson)

IF !ISNULL(loObject)
    ? "JSON parsat cu succes"
    * Acces la proprietăți
    * lcName = loBridge.GetProperty(loObject, "name")
ENDIF
```

## Lucrul cu Colecții .NET

```foxpro
*====================================================================
* Procedură: WorkWithNetCollections
* Scop: Demonstrează lucrul cu List<T> și alte colecții .NET
*====================================================================
FUNCTION CreateNetList(tcTypeName)
    LOCAL loBridge, loList
    
    TRY
        loBridge = InitializeDotNetBridge()
        
        IF ISNULL(loBridge)
            RETURN .NULL.
        ENDIF
        
        * Creare List<string> sau alt tip
        lcListType = "System.Collections.Generic.List`1[[" + tcTypeName + "]]"
        loList = loBridge.CreateInstance(lcListType)
        
        RETURN loList
        
    CATCH TO loException
        MESSAGEBOX("Eroare creare listă: " + loException.Message, 16, "Eroare")
        RETURN .NULL.
    ENDTRY
ENDFUNC

*====================================================================
* Exemplu utilizare
*====================================================================
LOCAL loBridge, loList
loBridge = InitializeDotNetBridge()
loList = CreateNetList("System.String")

IF !ISNULL(loList)
    * Adăugare elemente
    loBridge.InvokeMethod(loList, "Add", "Element 1")
    loBridge.InvokeMethod(loList, "Add", "Element 2")
    
    * Citire count
    lnCount = loBridge.GetProperty(loList, "Count")
    ? "Număr elemente: " + TRANSFORM(lnCount)
ENDIF
```

## Best Practices

### 1. Gestionare Resurse
```foxpro
* Întotdeauna eliberați resursele .NET când terminați
IF !ISNULL(loBridge)
    loBridge = .NULL.
ENDIF
```

### 2. Gestionare Erori
```foxpro
* Folosiți TRY/CATCH pentru toate apelurile .NET
TRY
    * Cod .NET aici
CATCH TO loException
    * Log erori și gestionare
    LogError(loException.Message)
ENDTRY
```

### 3. Timeout și Resilience
```foxpro
* Setați timeout-uri adecvate pentru operații I/O
* Implementați retry logic pentru operații critice
```

### 4. Testare
```foxpro
* Testați cu versiuni diferite de .NET Framework
* Verificați compatibilitatea cu Windows 10/11
```

## Troubleshooting

### Problemă: "Cannot create wwDotNetBridge instance"
**Soluție**: 
- Verificați că wwDotNetBridge.dll și ClrHost.dll sunt în directory
- Verificați că .NET Framework 4.x este instalat
- Rulați VFP ca Administrator pentru prima configurare

### Problemă: "Assembly not found"
**Soluție**:
- Verificați calea completă către assembly
- Asigurați-vă că toate dependențele sunt disponibile
- Folosiți LoadAssembly cu cale absolută

### Problemă: "Type not found"
**Soluție**:
- Verificați numele complet al tipului (namespace + class)
- Pentru tipuri generice, folosiți sintaxa corectă (backtick pentru arity)

## Resurse Suplimentare

- [wwDotNetBridge GitHub](https://github.com/RickStrahl/wwDotnetBridge)
- [West Wind Documentation](https://webconnection.west-wind.com/)
- [.NET Framework Documentation](https://docs.microsoft.com/en-us/dotnet/)

## Contact

Pentru suport suplimentar, consultați documentația generală de modernizare.
