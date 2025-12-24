*====================================================================
* Program: API_Integration_Examples.prg
* Scop: Exemple de integrare API moderne în Visual FoxPro 9.0
* Data: 2025
*====================================================================

*====================================================================
* EXEMPLU 1: Apel REST API cu wwDotNetBridge
*====================================================================
PROCEDURE Example_RestAPI_wwDotNetBridge
    LOCAL loBridge, lcJson, lcResponse
    
    * Inițializare bridge
    loBridge = CREATEOBJECT("wwDotNetBridge", "V4")
    
    IF ISNULL(loBridge)
        MESSAGEBOX("Nu s-a putut inițializa wwDotNetBridge", 16, "Eroare")
        RETURN
    ENDIF
    
    * Încărcare assembly pentru HTTP client
    * (presupunem că avem un wrapper .NET custom)
    lcAssemblyPath = FULLPATH(".\Modernization\API\HTTPClientWrapper.dll")
    
    IF FILE(lcAssemblyPath)
        IF loBridge.LoadAssembly(lcAssemblyPath)
            * Creare instanță client
            loClient = loBridge.CreateInstance("HTTPClientWrapper.RestClient")
            
            * Configurare endpoint
            loBridge.SetProperty(loClient, "BaseUrl", "https://api.anaf.ro/prod/FCTEL/rest")
            
            * Adăugare header autentificare
            loBridge.InvokeMethod(loClient, "AddHeader", "Authorization", "Bearer YOUR_TOKEN")
            
            * Preparare JSON pentru upload
            lcJson = GetInvoiceJSON()  && Funcție helper pentru generare JSON factură
            
            * Apel POST
            lcResponse = loBridge.InvokeMethod(loClient, "Post", "/upload", lcJson)
            
            ? "Răspuns API ANAF:"
            ? lcResponse
        ELSE
            MESSAGEBOX("Nu s-a putut încărca assembly-ul HTTP", 16, "Eroare")
        ENDIF
    ELSE
        MESSAGEBOX("Assembly-ul nu există: " + lcAssemblyPath, 16, "Eroare")
    ENDIF
ENDPROC

*====================================================================
* EXEMPLU 2: Apel REST API cu Chilkat ActiveX
*====================================================================
PROCEDURE Example_RestAPI_Chilkat
    LOCAL loHttp, lcJson, lcResponse, llUnlock
    
    * Creare obiect Chilkat HTTP
    loHttp = CREATEOBJECT("Chilkat.Http")
    
    * Unlock component (necesită licență)
    llUnlock = loHttp.UnlockComponent("YOUR_CHILKAT_LICENSE_KEY")
    
    IF !llUnlock
        MESSAGEBOX("Nu s-a putut debloca Chilkat", 16, "Eroare")
        RETURN
    ENDIF
    
    * Configurare TLS 1.2+
    loHttp.RequireTlsVersion = "1.2"
    
    * Configurare timeout (30 secunde)
    loHttp.ConnectTimeout = 30
    loHttp.ReadTimeout = 30
    
    * Adăugare headers
    loHttp.SetRequestHeader("Content-Type", "application/json")
    loHttp.SetRequestHeader("Authorization", "Bearer YOUR_TOKEN")
    
    * Preparare JSON
    lcJson = GetInvoiceJSON()
    
    * Apel POST
    lcUrl = "https://api.anaf.ro/prod/FCTEL/rest/upload"
    lcResponse = loHttp.PostJson(lcUrl, lcJson)
    
    * Verificare status
    lnStatus = loHttp.LastStatus
    
    IF lnStatus = 200 OR lnStatus = 201
        ? "Upload factură reușit!"
        ? "Răspuns:"
        ? lcResponse
    ELSE
        ? "Eroare upload factură. Status: " + TRANSFORM(lnStatus)
        ? "Detalii: " + loHttp.LastErrorText
    ENDIF
ENDPROC

*====================================================================
* EXEMPLU 3: Retry Logic cu Exponential Backoff
*====================================================================
PROCEDURE CallAPIWithRetry(tcUrl, tcMethod, tcJson, tnMaxRetries)
    LOCAL lnAttempt, lnDelay, lcResponse, llSuccess
    
    * Valori default
    tnMaxRetries = IIF(EMPTY(tnMaxRetries), 3, tnMaxRetries)
    lnDelay = 1  && Delay inițial în secunde
    
    FOR lnAttempt = 1 TO tnMaxRetries
        TRY
            * Încearcă apel API
            lcResponse = CallRestAPI(tcUrl, tcMethod, tcJson)
            llSuccess = .T.
            EXIT
            
        CATCH TO loException
            llSuccess = .F.
            
            ? "Tentativa " + TRANSFORM(lnAttempt) + " eșuată: " + loException.Message
            
            IF lnAttempt < tnMaxRetries
                ? "Reîncearcă în " + TRANSFORM(lnDelay) + " secunde..."
                
                * Wait (sleep) folosind API Windows
                DECLARE INTEGER Sleep IN Win32API INTEGER nMilliseconds
                Sleep(lnDelay * 1000)
                
                * Exponential backoff
                lnDelay = lnDelay * 2
            ENDIF
        ENDTRY
    ENDFOR
    
    IF !llSuccess
        MESSAGEBOX("Apel API eșuat după " + TRANSFORM(tnMaxRetries) + " încercări", 16, "Eroare")
        RETURN .NULL.
    ENDIF
    
    RETURN lcResponse
ENDPROC

*====================================================================
* EXEMPLU 4: Circuit Breaker Pattern (simplificat)
*====================================================================
DEFINE CLASS CircuitBreaker AS Custom
    * Proprietăți
    nFailureCount = 0
    nThreshold = 5
    nTimeout = 60  && secunde
    tLastFailure = .NULL.
    cState = "CLOSED"  && CLOSED, OPEN, HALF_OPEN
    
    *================================================================
    * Metodă: Call
    * Scop: Execută apel cu circuit breaker protection
    *================================================================
    PROCEDURE Call(tcUrl, tcMethod, tcJson)
        LOCAL lcResponse, llSuccess
        
        * Verifică starea circuitului
        DO CASE
            CASE THIS.cState = "OPEN"
                * Circuit deschis - verifică dacă a trecut timeout-ul
                IF (DATETIME() - THIS.tLastFailure) >= THIS.nTimeout
                    THIS.cState = "HALF_OPEN"
                    ? "Circuit breaker: HALF_OPEN"
                ELSE
                    MESSAGEBOX("Circuit breaker OPEN - serviciu indisponibil", 48, "Avertisment")
                    RETURN .NULL.
                ENDIF
                
            CASE THIS.cState = "HALF_OPEN"
                * Testare după timeout
                ? "Circuit breaker: Testare conexiune..."
        ENDCASE
        
        * Încearcă apelul
        TRY
            lcResponse = CallRestAPI(tcUrl, tcMethod, tcJson)
            llSuccess = .T.
            
            * Reset la succes
            IF THIS.cState = "HALF_OPEN"
                THIS.cState = "CLOSED"
                THIS.nFailureCount = 0
                ? "Circuit breaker: CLOSED (recuperat)"
            ENDIF
            
        CATCH TO loException
            llSuccess = .F.
            THIS.RecordFailure()
            
            ? "Circuit breaker: Eșec - " + loException.Message
        ENDTRY
        
        IF llSuccess
            RETURN lcResponse
        ELSE
            RETURN .NULL.
        ENDIF
    ENDPROC
    
    *================================================================
    * Metodă: RecordFailure
    * Scop: Înregistrează eșec și actualizează starea
    *================================================================
    PROCEDURE RecordFailure
        THIS.nFailureCount = THIS.nFailureCount + 1
        THIS.tLastFailure = DATETIME()
        
        IF THIS.nFailureCount >= THIS.nThreshold
            THIS.cState = "OPEN"
            ? "Circuit breaker: OPEN (prea multe eșecuri)"
        ENDIF
    ENDPROC
ENDDEFINE

*====================================================================
* EXEMPLU 5: Helper pentru generare JSON factură
*====================================================================
FUNCTION GetInvoiceJSON()
    LOCAL lcJson, loInvoice
    
    * Creare obiect JSON (simplificat)
    TEXT TO lcJson NOSHOW TEXTMERGE
    {
        "invoice_id": "<<ALLTRIM(crsEFactura.Nr)>>",
        "issue_date": "<<DTOC(crsEFactura.Data, 1)>>",
        "supplier": {
            "cui": "<<ALLTRIM(ICAS.oSoc.CodFiscal)>>",
            "name": "<<ALLTRIM(ICAS.oSoc.Denumire)>>",
            "address": "<<ALLTRIM(ICAS.oSoc.Adresa)>>"
        },
        "customer": {
            "cui": "<<ALLTRIM(crsEFactura.Cod_Fiscal)>>",
            "name": "<<ALLTRIM(crsEFactura.NumeTert)>>"
        },
        "total_amount": <<TRANSFORM(crsEFactura.Total, "999999.99")>>,
        "vat_amount": <<TRANSFORM(crsEFactura.TotalTva, "999999.99")>>,
        "currency": "<<ALLTRIM(crsEFactura.Moneda)>>"
    }
    ENDTEXT
    
    RETURN lcJson
ENDFUNC

*====================================================================
* EXEMPLU 6: Apel helper intern
*====================================================================
FUNCTION CallRestAPI(tcUrl, tcMethod, tcJson)
    LOCAL lcResponse
    
    * Aici puteți folosi fie Chilkat fie wwDotNetBridge
    * bazat pe disponibilitate
    
    IF IsChilkatAvailable()
        lcResponse = CallAPI_Chilkat(tcUrl, tcMethod, tcJson)
    ELSE
        lcResponse = CallAPI_wwDotNet(tcUrl, tcMethod, tcJson)
    ENDIF
    
    RETURN lcResponse
ENDFUNC

*====================================================================
* EXEMPLU 7: Verificare disponibilitate Chilkat
*====================================================================
FUNCTION IsChilkatAvailable()
    LOCAL loTest, llAvailable
    
    TRY
        loTest = CREATEOBJECT("Chilkat.Http")
        llAvailable = !ISNULL(loTest)
        loTest = .NULL.
    CATCH
        llAvailable = .F.
    ENDTRY
    
    RETURN llAvailable
ENDFUNC

*====================================================================
* EXEMPLU 8: Wrapper pentru Chilkat
*====================================================================
FUNCTION CallAPI_Chilkat(tcUrl, tcMethod, tcJson)
    LOCAL loHttp, lcResponse
    
    loHttp = CREATEOBJECT("Chilkat.Http")
    
    * Configurare
    loHttp.RequireTlsVersion = "1.2"
    loHttp.ConnectTimeout = 30
    loHttp.ReadTimeout = 30
    
    * Headers
    loHttp.SetRequestHeader("Content-Type", "application/json")
    
    * Apel bazat pe metodă
    DO CASE
        CASE UPPER(tcMethod) = "GET"
            lcResponse = loHttp.QuickGetStr(tcUrl)
            
        CASE UPPER(tcMethod) = "POST"
            lcResponse = loHttp.PostJson(tcUrl, tcJson)
            
        CASE UPPER(tcMethod) = "PUT"
            lcResponse = loHttp.PutText(tcUrl, tcJson, "utf-8", "application/json", .F., .F.)
            
        CASE UPPER(tcMethod) = "DELETE"
            lcResponse = loHttp.QuickDeleteStr(tcUrl)
    ENDCASE
    
    * Verificare erori
    IF loHttp.LastMethodSuccess = .F.
        THROW "Eroare HTTP: " + loHttp.LastErrorText
    ENDIF
    
    RETURN lcResponse
ENDFUNC

*====================================================================
* EXEMPLU 9: Wrapper pentru wwDotNetBridge
*====================================================================
FUNCTION CallAPI_wwDotNet(tcUrl, tcMethod, tcJson)
    * Implementare folosind wwDotNetBridge
    * Vezi wwDotNetBridge_Integration.md pentru detalii complete
    
    LOCAL loBridge, loHttp, lcResponse
    
    loBridge = CREATEOBJECT("wwDotNetBridge", "V4")
    loHttp = loBridge.CreateInstance("System.Net.Http.HttpClient")
    
    * Setare timeout
    loBridge.SetProperty(loHttp, "Timeout", ;
        loBridge.CreateInstance("System.TimeSpan").FromSeconds(30))
    
    * Apel bazat pe metodă
    DO CASE
        CASE UPPER(tcMethod) = "GET"
            loResponse = loBridge.InvokeMethod(loHttp, "GetAsync", tcUrl)
            
        CASE UPPER(tcMethod) = "POST"
            loContent = loBridge.CreateInstance("System.Net.Http.StringContent", ;
                tcJson, ;
                loBridge.CreateInstance("System.Text.Encoding").UTF8, ;
                "application/json")
            loResponse = loBridge.InvokeMethod(loHttp, "PostAsync", tcUrl, loContent)
    ENDCASE
    
    * Citire răspuns
    loResponse = loBridge.GetProperty(loResponse, "Result")
    loTask = loBridge.InvokeMethod(loResponse, "Content.ReadAsStringAsync")
    lcResponse = loBridge.GetProperty(loTask, "Result")
    
    RETURN lcResponse
ENDFUNC

*====================================================================
* EXEMPLU 10: Testare integrare API
*====================================================================
PROCEDURE Test_API_Integration
    ? "====================================="
    ? "TEST: Integrare API"
    ? "====================================="
    
    * Test 1: Chilkat availability
    ? "1. Verificare Chilkat..."
    IF IsChilkatAvailable()
        ? "   ✓ Chilkat disponibil"
    ELSE
        ? "   ✗ Chilkat nu este disponibil"
    ENDIF
    
    * Test 2: Circuit Breaker
    ? ""
    ? "2. Test Circuit Breaker..."
    LOCAL loBreaker
    loBreaker = CREATEOBJECT("CircuitBreaker")
    ? "   ✓ Circuit Breaker inițializat"
    ? "   Stare: " + loBreaker.cState
    
    * Test 3: Retry logic
    ? ""
    ? "3. Test Retry Logic..."
    ? "   (Simulare - verificați implementarea)"
    
    ? ""
    ? "====================================="
    ? "Teste finalizate"
    ? "====================================="
ENDPROC

*====================================================================
* Program principal pentru testare
*====================================================================
IF .T.  && Schimbați în .F. pentru a dezactiva auto-run
    Test_API_Integration()
ENDIF
