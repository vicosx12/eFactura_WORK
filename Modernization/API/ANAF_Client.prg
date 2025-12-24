*====================================================================
* Program: ANAF_Client.prg
* Scop: Client pentru API ANAF e-Factura cu OAuth2
* Data: 2024-12-23
* Autor: Modernizare VFP 9.0
*====================================================================
* Production-ready pentru:
* - Chilkat 9.5.0 (TLS 1.2)
* - ANAF API OAuth2
* - Credențiale criptate în ICAS.oSettings
*====================================================================

*====================================================================
* DEFINE CLASS: ANAFClient
*====================================================================
DEFINE CLASS ANAFClient AS Custom
    cClientID = ""
    cClientSecret = ""
    cAccessToken = ""
    dTokenExpiry = {}
    cBaseURL = "https://api.anaf.ro/prod/FCTEL/rest"
    cTestURL = "https://api.anaf.ro/test/FCTEL/rest"
    cTokenURL = "https://logincert.anaf.ro/anaf-oauth2/v1/token"
    lUseTestEnvironment = .F.
    lDebugMode = .F.
    cLogFile = ""
    
    *================================================================
    * Metodă: Init
    *================================================================
    PROCEDURE Init(tlUseTestEnv)
        IF !EMPTY(tlUseTestEnv)
            THIS.lUseTestEnvironment = tlUseTestEnv
        ENDIF
        
        THIS.cLogFile = ADDBS(SYS(5)+SYS(2003)) + "ANAF_Client_" + DTOS(DATE()) + ".log"
        
        * Încarcă credențiale
        IF !THIS.LoadCredentials()
            RETURN .F.
        ENDIF
        
        RETURN .T.
    ENDPROC
    
    *================================================================
    * Metodă: LoadCredentials
    *================================================================
    PROTECTED PROCEDURE LoadCredentials()
        LOCAL llSuccess
        
        llSuccess = .F.
        
        TRY
            * Verifică existența ICAS.oSettings
            IF TYPE('ICAS.oSettings') != 'O'
                THIS.LogMessage("EROARE: ICAS.oSettings nu există")
            ELSE
                * Decriptează credențiale
                THIS.cClientID = Chilkat_Crypt(ICAS.oSettings.EFactura_ClientID, 'D')
                THIS.cClientSecret = Chilkat_Crypt(ICAS.oSettings.eFactura_SecretID, 'D')
                
                IF EMPTY(THIS.cClientID) OR EMPTY(THIS.cClientSecret)
                    THIS.LogMessage("EROARE: Credențiale ANAF incomplete")
                ELSE
                    IF THIS.lDebugMode
                        THIS.LogMessage("Credențiale încărcate cu succes")
                    ENDIF
                    llSuccess = .T.
                ENDIF
            ENDIF
            
        CATCH TO loEx
            THIS.LogMessage("EROARE LoadCredentials: " + loEx.Message)
            llSuccess = .F.
        ENDTRY
        
        RETURN llSuccess
    ENDPROC
    
    *================================================================
    * Metodă: GetAccessToken
    *================================================================
    PROCEDURE GetAccessToken()
        LOCAL loHttp, lcBody, lcResponse, loJson, lcToken
        
        * Verifică dacă token-ul actual e valid
        IF !EMPTY(THIS.cAccessToken) AND THIS.IsTokenValid()
            RETURN THIS.cAccessToken
        ENDIF
        
        lcToken = ""
        
        TRY
            * Creare HTTP client
            loHttp = CREATEOBJECT("Chilkat_9_5_0.Http")
            
            IF ISNULL(loHttp)
                THIS.LogMessage("EROARE: Chilkat HTTP indisponibil")
            ELSE
                * Configurare TLS 1.2
                loHttp.RequireTlsVersion = "1.2"
                
                * Body pentru request
                TEXT TO lcBody NOSHOW TEXTMERGE
                grant_type=client_credentials&client_id=<<THIS.cClientID>>&client_secret=<<THIS.cClientSecret>>&scope=e-factura
                ENDTEXT
                
                * Headers
                loHttp.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
                
                * Apel token endpoint
                lcResponse = loHttp.PostUrlEncoded(THIS.cTokenURL, lcBody)
                
                IF loHttp.LastMethodSuccess = .F.
                    THIS.LogMessage("EROARE token request: " + loHttp.LastErrorText)
                ELSE
                    * Parse JSON response
                    loJson = CREATEOBJECT("Chilkat_9_5_0.JsonObject")
                    loJson.Load(lcResponse)
                    
                    lcToken = loJson.StringOf("access_token")
                    
                    IF !EMPTY(lcToken)
                        THIS.cAccessToken = lcToken
                        THIS.dTokenExpiry = DATETIME() + (3600 - 300)  && 1 oră - 5 min buffer
                        
                        IF THIS.lDebugMode
                            THIS.LogMessage("Access Token obținut")
                        ENDIF
                    ELSE
                        THIS.LogMessage("EROARE: Token gol în răspuns")
                        THIS.LogMessage(lcResponse)
                    ENDIF
                ENDIF
            ENDIF
            
        CATCH TO loEx
            THIS.LogMessage("EROARE GetAccessToken: " + loEx.Message)
            lcToken = ""
        ENDTRY
        
        RETURN lcToken
    ENDPROC
    
    *================================================================
    * Metodă: IsTokenValid
    *================================================================
    PROTECTED PROCEDURE IsTokenValid()
        IF EMPTY(THIS.cAccessToken)
            RETURN .F.
        ENDIF
        
        IF EMPTY(THIS.dTokenExpiry)
            RETURN .F.
        ENDIF
        
        RETURN (DATETIME() < THIS.dTokenExpiry)
    ENDPROC
    
    *================================================================
    * Metodă: GetMessagesList
    *================================================================
    PROCEDURE GetMessagesList(tnDays)
        LOCAL loHttp, lcUrl, lcToken, lcResponse
        
        IF EMPTY(tnDays)
            tnDays = 7
        ENDIF
        
        * Obține token
        lcToken = THIS.GetAccessToken()
        IF EMPTY(lcToken)
            RETURN .NULL.
        ENDIF
        
        lcResponse = .NULL.
        
        TRY
            loHttp = CREATEOBJECT("Chilkat_9_5_0.Http")
            loHttp.RequireTlsVersion = "1.2"
            loHttp.SetRequestHeader("Authorization", "Bearer " + lcToken)
            
            * URL pentru listă mesaje
            lcUrl = IIF(THIS.lUseTestEnvironment, THIS.cTestURL, THIS.cBaseURL) + ;
                    "/listaMesajeFactura?zile=" + TRANSFORM(tnDays)
            
            lcResponse = loHttp.QuickGetStr(lcUrl)
            
            IF loHttp.LastMethodSuccess = .T.
                IF THIS.lDebugMode
                    THIS.LogMessage("Listă mesaje obținută")
                ENDIF
            ELSE
                THIS.LogMessage("EROARE GetMessagesList: " + loHttp.LastErrorText)
                lcResponse = .NULL.
            ENDIF
            
        CATCH TO loEx
            THIS.LogMessage("EROARE GetMessagesList: " + loEx.Message)
            lcResponse = .NULL.
        ENDTRY
        
        RETURN lcResponse
    ENDPROC
    
    *================================================================
    * Metodă: UploadInvoice
    *================================================================
    PROCEDURE UploadInvoice(tcXmlContent, tcCIF)
        LOCAL loHttp, lcToken, lcUrl, lcResponse
        LOCAL loMultipart, loXmlContent
        
        * Obține token
        lcToken = THIS.GetAccessToken()
        IF EMPTY(lcToken)
            RETURN .NULL.
        ENDIF
        
        lcResponse = .NULL.
        
        TRY
            loHttp = CREATEOBJECT("Chilkat_9_5_0.Http")
            loHttp.RequireTlsVersion = "1.2"
            loHttp.SetRequestHeader("Authorization", "Bearer " + lcToken)
            
            * Creare multipart form data
            loMultipart = CREATEOBJECT("Chilkat_9_5_0.HttpRequest")
            loMultipart.HttpVerb = "POST"
            loMultipart.ContentType = "multipart/form-data"
            
            * Adaugă fișier XML
            loMultipart.AddStringForUpload("file", "factura.xml", tcXmlContent, "utf-8", "text/xml")
            loMultipart.AddParam("cif", tcCIF)
            
            * URL pentru upload
            lcUrl = IIF(THIS.lUseTestEnvironment, THIS.cTestURL, THIS.cBaseURL) + "/upload"
            
            * Upload
            LOCAL loResp
            loResp = loHttp.PostMultipart(lcUrl, loMultipart)
            
            IF !ISNULL(loResp)
                lcResponse = loResp.BodyStr
                
                IF THIS.lDebugMode
                    THIS.LogMessage("Upload factură - Status: " + TRANSFORM(loResp.StatusCode))
                ENDIF
            ELSE
                THIS.LogMessage("EROARE UploadInvoice: " + loHttp.LastErrorText)
                lcResponse = .NULL.
            ENDIF
            
        CATCH TO loEx
            THIS.LogMessage("EROARE UploadInvoice: " + loEx.Message)
            lcResponse = .NULL.
        ENDTRY
        
        RETURN lcResponse
    ENDPROC
    
    *================================================================
    * Metodă: DownloadMessage
    *================================================================
    PROCEDURE DownloadMessage(tcMessageID)
        LOCAL loHttp, lcToken, lcUrl, lcResponse
        
        * Obține token
        lcToken = THIS.GetAccessToken()
        IF EMPTY(lcToken)
            RETURN .NULL.
        ENDIF
        
        lcResponse = .NULL.
        
        TRY
            loHttp = CREATEOBJECT("Chilkat_9_5_0.Http")
            loHttp.RequireTlsVersion = "1.2"
            loHttp.SetRequestHeader("Authorization", "Bearer " + lcToken)
            
            * URL pentru download
            lcUrl = IIF(THIS.lUseTestEnvironment, THIS.cTestURL, THIS.cBaseURL) + ;
                    "/descarcare?id=" + tcMessageID
            
            lcResponse = loHttp.QuickGetStr(lcUrl)
            
            IF loHttp.LastMethodSuccess = .T.
                IF THIS.lDebugMode
                    THIS.LogMessage("Mesaj descărcat: " + tcMessageID)
                ENDIF
            ELSE
                THIS.LogMessage("EROARE DownloadMessage: " + loHttp.LastErrorText)
                lcResponse = .NULL.
            ENDIF
            
        CATCH TO loEx
            THIS.LogMessage("EROARE DownloadMessage: " + loEx.Message)
            lcResponse = .NULL.
        ENDTRY
        
        RETURN lcResponse
    ENDPROC
    
    *================================================================
    * Metodă: LogMessage
    *================================================================
    PROTECTED PROCEDURE LogMessage(tcMessage)
        LOCAL lcLogEntry
        lcLogEntry = TTOC(DATETIME()) + " | " + tcMessage + CHR(13)+CHR(10)
        TRY
            STRTOFILE(lcLogEntry, THIS.cLogFile, .T.)
        CATCH
        ENDTRY
    ENDPROC
ENDDEFINE

*====================================================================
* Funcție: GetGlobalANAFClient
*====================================================================
FUNCTION GetGlobalANAFClient(tlUseTestEnv)
    LOCAL loClient
    
    IF TYPE('_SCREEN.oGlobalANAFClient') = 'O' AND ;
       !ISNULL(_SCREEN.oGlobalANAFClient)
        RETURN _SCREEN.oGlobalANAFClient
    ENDIF
    
    loClient = CREATEOBJECT("ANAFClient", tlUseTestEnv)
    
    IF !ISNULL(loClient)
        ADDPROPERTY(_SCREEN, 'oGlobalANAFClient', loClient)
    ENDIF
    
    RETURN loClient
ENDFUNC
