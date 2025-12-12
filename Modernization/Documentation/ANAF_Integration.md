# Integrare ANAF e-Factura - Ghid Complet

## Introducere

Acest ghid descrie integrarea cu sistemul ANAF e-Factura pentru generare, validare, semnare digitală și upload facturi electronice conform standardelor românești.

## Componente Necesare

### 1. Librării .NET pentru e-Factura
- **e-Factura .NET Utilities** (open source sau comerciale)
- **System.Security.Cryptography** pentru semnare digitală
- **System.Xml** pentru generare și validare XML
- **Newtonsoft.Json** pentru parsare răspunsuri API

### 2. Certificate Digitale
- Certificat digital calificat pentru semnare
- Format: PFX/PKCS#12
- Emis de autoritate certificare recunoscută (ex: CertSign)

### 3. Acces API ANAF
- Credențiale OAuth2
- Client ID și Client Secret
- Access token pentru autentificare

## Arhitectură Integrare

```
VFP Application
    ↓
wwDotNetBridge
    ↓
.NET Assembly (ANAFIntegration.dll)
    ↓
ANAF API (https://api.anaf.ro/prod/FCTEL/rest/)
```

## Fluxul de Lucru

1. **Generare XML UBL** - Format standard e-Factura
2. **Validare XSD** - Conform schema ANAF
3. **Semnare digitală** - Cu certificat calificat
4. **Upload la ANAF** - Prin API REST
5. **Verificare status** - Download index mesaje
6. **Procesare răspuns** - Validare și confirmare

## Implementare

### 1. Clasa .NET pentru ANAF Integration (C#)

Aceasta ar fi salvată ca `ANAFIntegration.cs` și compilată în DLL:

```csharp
using System;
using System.IO;
using System.Net.Http;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Security.Cryptography.Xml;
using System.Text;
using System.Threading.Tasks;
using System.Xml;
using Newtonsoft.Json;

namespace ANAFIntegration
{
    public class EFacturaClient
    {
        private readonly string _baseUrl;
        private readonly HttpClient _httpClient;
        private string _accessToken;
        
        public EFacturaClient(string baseUrl = "https://api.anaf.ro/prod/FCTEL/rest")
        {
            _baseUrl = baseUrl;
            _httpClient = new HttpClient();
            _httpClient.Timeout = TimeSpan.FromSeconds(30);
        }
        
        /// <summary>
        /// Setează token-ul de autentificare OAuth2
        /// </summary>
        public void SetAccessToken(string token)
        {
            _accessToken = token;
            _httpClient.DefaultRequestHeaders.Clear();
            _httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {token}");
        }
        
        /// <summary>
        /// Upload factură XML către ANAF
        /// </summary>
        public async Task<string> UploadInvoiceAsync(string xmlContent, string cif)
        {
            try
            {
                var endpoint = $"{_baseUrl}/upload";
                
                // Creare multipart content pentru XML
                var multipart = new MultipartFormDataContent();
                var xmlBytes = Encoding.UTF8.GetBytes(xmlContent);
                var xmlContent = new ByteArrayContent(xmlBytes);
                xmlContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue("text/xml");
                
                multipart.Add(xmlContent, "file", $"factura_{DateTime.Now:yyyyMMddHHmmss}.xml");
                multipart.Add(new StringContent(cif), "cif");
                
                var response = await _httpClient.PostAsync(endpoint, multipart);
                var result = await response.Content.ReadAsStringAsync();
                
                if (!response.IsSuccessStatusCode)
                {
                    throw new Exception($"Upload failed: {response.StatusCode} - {result}");
                }
                
                return result;
            }
            catch (Exception ex)
            {
                throw new Exception($"Error uploading invoice: {ex.Message}", ex);
            }
        }
        
        /// <summary>
        /// Upload factură XML (sincron - pentru VFP)
        /// </summary>
        public string UploadInvoice(string xmlContent, string cif)
        {
            return UploadInvoiceAsync(xmlContent, cif).GetAwaiter().GetResult();
        }
        
        /// <summary>
        /// Download index mesaje pentru o anumită zi
        /// </summary>
        public string DownloadMessagesIndex(DateTime date, string cif)
        {
            try
            {
                var dateStr = date.ToString("yyyy-MM-dd");
                var endpoint = $"{_baseUrl}/listaMesajeFactura?cif={cif}&zile={dateStr}";
                
                var response = _httpClient.GetAsync(endpoint).GetAwaiter().GetResult();
                var result = response.Content.ReadAsStringAsync().GetAwaiter().GetResult();
                
                if (!response.IsSuccessStatusCode)
                {
                    throw new Exception($"Download failed: {response.StatusCode}");
                }
                
                return result;
            }
            catch (Exception ex)
            {
                throw new Exception($"Error downloading messages: {ex.Message}", ex);
            }
        }
        
        /// <summary>
        /// Download mesaj specific
        /// </summary>
        public string DownloadMessage(string messageId)
        {
            try
            {
                var endpoint = $"{_baseUrl}/descarcare?id={messageId}";
                
                var response = _httpClient.GetAsync(endpoint).GetAwaiter().GetResult();
                var result = response.Content.ReadAsStringAsync().GetAwaiter().GetResult();
                
                return result;
            }
            catch (Exception ex)
            {
                throw new Exception($"Error downloading message: {ex.Message}", ex);
            }
        }
        
        /// <summary>
        /// Validare XML conform XSD schema
        /// </summary>
        public ValidationResult ValidateXML(string xmlContent, string xsdPath)
        {
            var result = new ValidationResult { IsValid = true };
            
            try
            {
                var settings = new XmlReaderSettings();
                settings.ValidationType = ValidationType.Schema;
                settings.Schemas.Add(null, xsdPath);
                
                settings.ValidationEventHandler += (sender, args) =>
                {
                    result.IsValid = false;
                    result.Errors.Add(args.Message);
                };
                
                using (var reader = XmlReader.Create(new StringReader(xmlContent), settings))
                {
                    while (reader.Read()) { }
                }
            }
            catch (Exception ex)
            {
                result.IsValid = false;
                result.Errors.Add($"Validation error: {ex.Message}");
            }
            
            return result;
        }
        
        /// <summary>
        /// Semnare XML cu certificat digital
        /// </summary>
        public string SignXML(string xmlContent, string certificatePath, string password)
        {
            try
            {
                // Încărcare certificat
                var cert = new X509Certificate2(certificatePath, password, 
                    X509KeyStorageFlags.MachineKeySet | X509KeyStorageFlags.Exportable);
                
                // Încărcare XML
                var xmlDoc = new XmlDocument();
                xmlDoc.PreserveWhitespace = true;
                xmlDoc.LoadXml(xmlContent);
                
                // Creare SignedXml
                var signedXml = new SignedXml(xmlDoc);
                signedXml.SigningKey = cert.GetRSAPrivateKey();
                
                // Creare referință
                var reference = new Reference("");
                reference.AddTransform(new XmlDsigEnvelopedSignatureTransform());
                signedXml.AddReference(reference);
                
                // Adăugare informații cheie
                var keyInfo = new KeyInfo();
                keyInfo.AddClause(new KeyInfoX509Data(cert));
                signedXml.KeyInfo = keyInfo;
                
                // Compute signature
                signedXml.ComputeSignature();
                
                // Obține elementul semnăturii
                var signatureElement = signedXml.GetXml();
                
                // Append la documentul original
                xmlDoc.DocumentElement.AppendChild(xmlDoc.ImportNode(signatureElement, true));
                
                return xmlDoc.OuterXml;
            }
            catch (Exception ex)
            {
                throw new Exception($"Error signing XML: {ex.Message}", ex);
            }
        }
        
        /// <summary>
        /// Verificare semnătură XML
        /// </summary>
        public bool VerifySignature(string signedXmlContent)
        {
            try
            {
                var xmlDoc = new XmlDocument();
                xmlDoc.PreserveWhitespace = true;
                xmlDoc.LoadXml(signedXmlContent);
                
                var signedXml = new SignedXml(xmlDoc);
                var signatureNode = xmlDoc.GetElementsByTagName("Signature")[0];
                signedXml.LoadXml((XmlElement)signatureNode);
                
                return signedXml.CheckSignature();
            }
            catch
            {
                return false;
            }
        }
    }
    
    public class ValidationResult
    {
        public bool IsValid { get; set; }
        public List<string> Errors { get; set; } = new List<string>();
        
        public string GetErrorsAsString()
        {
            return string.Join("\n", Errors);
        }
    }
}
```

### 2. Wrapper VFP pentru ANAF Integration

```foxpro
*====================================================================
* Program: ANAF_Integration_Wrapper.prg
* Scop: Wrapper VFP pentru integrare ANAF e-Factura
*====================================================================

*====================================================================
* Clasa: ANAFClient
* Scop: Client pentru comunicare cu API ANAF
*====================================================================
DEFINE CLASS ANAFClient AS Custom
    oBridge = .NULL.
    oClient = .NULL.
    cBaseUrl = "https://api.anaf.ro/prod/FCTEL/rest"
    cAccessToken = ""
    cCertificatePath = ""
    cCertificatePassword = ""
    
    *================================================================
    * Metodă: Init
    *================================================================
    PROCEDURE Init()
        LOCAL llSuccess
        
        TRY
            * Inițializare wwDotNetBridge
            THIS.oBridge = CREATEOBJECT("wwDotNetBridge", "V4")
            
            IF ISNULL(THIS.oBridge)
                MESSAGEBOX("Nu s-a putut inițializa wwDotNetBridge", 16, "Eroare")
                RETURN .F.
            ENDIF
            
            * Încărcare assembly ANAF
            lcAssemblyPath = FULLPATH(".\Modernization\ANAF\ANAFIntegration.dll")
            
            IF !FILE(lcAssemblyPath)
                MESSAGEBOX("Assembly-ul ANAFIntegration.dll nu există", 16, "Eroare")
                RETURN .F.
            ENDIF
            
            IF !THIS.oBridge.LoadAssembly(lcAssemblyPath)
                MESSAGEBOX("Nu s-a putut încărca ANAFIntegration.dll", 16, "Eroare")
                RETURN .F.
            ENDIF
            
            * Creare instanță client
            THIS.oClient = THIS.oBridge.CreateInstance("ANAFIntegration.EFacturaClient", THIS.cBaseUrl)
            
            IF ISNULL(THIS.oClient)
                MESSAGEBOX("Nu s-a putut crea instanța EFacturaClient", 16, "Eroare")
                RETURN .F.
            ENDIF
            
            ? "ANAF Client inițializat cu succes"
            llSuccess = .T.
            
        CATCH TO loException
            MESSAGEBOX("Eroare inițializare: " + loException.Message, 16, "Eroare")
            llSuccess = .F.
        ENDTRY
        
        RETURN llSuccess
    ENDPROC
    
    *================================================================
    * Metodă: SetAccessToken
    *================================================================
    PROCEDURE SetAccessToken(tcToken)
        IF ISNULL(THIS.oClient)
            RETURN .F.
        ENDIF
        
        TRY
            THIS.cAccessToken = tcToken
            THIS.oBridge.InvokeMethod(THIS.oClient, "SetAccessToken", tcToken)
            ? "Access token setat"
            RETURN .T.
        CATCH TO loException
            MESSAGEBOX("Eroare setare token: " + loException.Message, 16, "Eroare")
            RETURN .F.
        ENDTRY
    ENDPROC
    
    *================================================================
    * Metodă: UploadInvoice
    *================================================================
    PROCEDURE UploadInvoice(tcXmlContent, tcCIF)
        LOCAL lcResult, lcError
        
        IF ISNULL(THIS.oClient)
            MESSAGEBOX("Client neinițializat", 16, "Eroare")
            RETURN .NULL.
        ENDIF
        
        IF EMPTY(THIS.cAccessToken)
            MESSAGEBOX("Access token lipsă - apelați SetAccessToken()", 16, "Eroare")
            RETURN .NULL.
        ENDIF
        
        TRY
            ? "Upload factură pentru CIF: " + tcCIF
            
            lcResult = THIS.oBridge.InvokeMethod(THIS.oClient, "UploadInvoice", ;
                tcXmlContent, tcCIF)
            
            ? "Upload reușit!"
            ? "Răspuns:"
            ? lcResult
            
            RETURN lcResult
            
        CATCH TO loException
            lcError = "Eroare upload: " + loException.Message
            MESSAGEBOX(lcError, 16, "Eroare")
            RETURN .NULL.
        ENDTRY
    ENDPROC
    
    *================================================================
    * Metodă: DownloadMessagesIndex
    *================================================================
    PROCEDURE DownloadMessagesIndex(tdDate, tcCIF)
        LOCAL lcResult, loDate
        
        IF ISNULL(THIS.oClient)
            RETURN .NULL.
        ENDIF
        
        TRY
            * Conversie date VFP la .NET DateTime
            loDate = THIS.oBridge.CreateInstance("System.DateTime", ;
                YEAR(tdDate), MONTH(tdDate), DAY(tdDate))
            
            lcResult = THIS.oBridge.InvokeMethod(THIS.oClient, "DownloadMessagesIndex", ;
                loDate, tcCIF)
            
            ? "Index mesaje descărcat pentru: " + DTOC(tdDate)
            
            RETURN lcResult
            
        CATCH TO loException
            MESSAGEBOX("Eroare download: " + loException.Message, 16, "Eroare")
            RETURN .NULL.
        ENDTRY
    ENDPROC
    
    *================================================================
    * Metodă: DownloadMessage
    *================================================================
    PROCEDURE DownloadMessage(tcMessageId)
        LOCAL lcResult
        
        IF ISNULL(THIS.oClient)
            RETURN .NULL.
        ENDIF
        
        TRY
            lcResult = THIS.oBridge.InvokeMethod(THIS.oClient, "DownloadMessage", tcMessageId)
            
            ? "Mesaj descărcat: " + tcMessageId
            
            RETURN lcResult
            
        CATCH TO loException
            MESSAGEBOX("Eroare download mesaj: " + loException.Message, 16, "Eroare")
            RETURN .NULL.
        ENDTRY
    ENDPROC
    
    *================================================================
    * Metodă: SignXML
    *================================================================
    PROCEDURE SignXML(tcXmlContent)
        LOCAL lcSignedXml, lcError
        
        IF ISNULL(THIS.oClient)
            RETURN .NULL.
        ENDIF
        
        IF EMPTY(THIS.cCertificatePath) OR !FILE(THIS.cCertificatePath)
            MESSAGEBOX("Certificat digital lipsă sau invalid", 16, "Eroare")
            RETURN .NULL.
        ENDIF
        
        TRY
            ? "Semnare XML cu certificat: " + THIS.cCertificatePath
            
            lcSignedXml = THIS.oBridge.InvokeMethod(THIS.oClient, "SignXML", ;
                tcXmlContent, ;
                THIS.cCertificatePath, ;
                THIS.cCertificatePassword)
            
            ? "XML semnat cu succes"
            
            RETURN lcSignedXml
            
        CATCH TO loException
            lcError = "Eroare semnare XML: " + loException.Message
            MESSAGEBOX(lcError, 16, "Eroare")
            RETURN .NULL.
        ENDTRY
    ENDPROC
    
    *================================================================
    * Metodă: ValidateXML
    *================================================================
    PROCEDURE ValidateXML(tcXmlContent, tcXsdPath)
        LOCAL loResult, llValid, lcErrors
        
        IF ISNULL(THIS.oClient)
            RETURN .F.
        ENDIF
        
        IF !FILE(tcXsdPath)
            MESSAGEBOX("Fișier XSD nu există: " + tcXsdPath, 16, "Eroare")
            RETURN .F.
        ENDIF
        
        TRY
            ? "Validare XML cu schema: " + tcXsdPath
            
            loResult = THIS.oBridge.InvokeMethod(THIS.oClient, "ValidateXML", ;
                tcXmlContent, tcXsdPath)
            
            llValid = THIS.oBridge.GetProperty(loResult, "IsValid")
            
            IF llValid
                ? "✓ XML valid conform schema XSD"
            ELSE
                lcErrors = THIS.oBridge.InvokeMethod(loResult, "GetErrorsAsString")
                ? "✗ XML invalid!"
                ? "Erori:"
                ? lcErrors
            ENDIF
            
            RETURN llValid
            
        CATCH TO loException
            MESSAGEBOX("Eroare validare: " + loException.Message, 16, "Eroare")
            RETURN .F.
        ENDTRY
    ENDPROC
    
    *================================================================
    * Metodă: VerifySignature
    *================================================================
    PROCEDURE VerifySignature(tcSignedXml)
        LOCAL llValid
        
        IF ISNULL(THIS.oClient)
            RETURN .F.
        ENDIF
        
        TRY
            llValid = THIS.oBridge.InvokeMethod(THIS.oClient, "VerifySignature", tcSignedXml)
            
            IF llValid
                ? "✓ Semnătură validă"
            ELSE
                ? "✗ Semnătură invalidă"
            ENDIF
            
            RETURN llValid
            
        CATCH TO loException
            MESSAGEBOX("Eroare verificare semnătură: " + loException.Message, 16, "Eroare")
            RETURN .F.
        ENDTRY
    ENDPROC
    
    *================================================================
    * Metodă: Destroy
    *================================================================
    PROCEDURE Destroy()
        THIS.oClient = .NULL.
        THIS.oBridge = .NULL.
    ENDPROC
ENDDEFINE
```

### 3. Exemplu de utilizare completă

```foxpro
*====================================================================
* Procedură: Upload_Factura_ANAF
* Scop: Exemplu complet upload factură la ANAF
*====================================================================
PROCEDURE Upload_Factura_ANAF(tnIdFactura)
    LOCAL loClient, lcXml, lcSignedXml, lcResponse
    LOCAL lcCIF, lcToken, lcCertPath, lcCertPass, lcXsdPath
    
    * Configurare
    lcCIF = ALLTRIM(ICAS.oSoc.CodFiscal)
    lcToken = GetANAFAccessToken()  && Funcție helper pentru OAuth2
    lcCertPath = "C:\Certificates\company_cert.pfx"
    lcCertPass = GetCertificatePassword()  && Din configurare securizată
    lcXsdPath = ".\Modernization\ANAF\Schemas\UBL-Invoice-2.1.xsd"
    
    * Creare client ANAF
    loClient = CREATEOBJECT("ANAFClient")
    
    IF ISNULL(loClient.oClient)
        MESSAGEBOX("Nu s-a putut inițializa clientul ANAF", 16, "Eroare")
        RETURN .F.
    ENDIF
    
    * Setare configurare
    loClient.cCertificatePath = lcCertPath
    loClient.cCertificatePassword = lcCertPass
    loClient.SetAccessToken(lcToken)
    
    * Generare XML UBL
    ? "Generare XML pentru factură ID: " + TRANSFORM(tnIdFactura)
    lcXml = Generate_UBL_XML(tnIdFactura)  && Funcție existentă
    
    IF EMPTY(lcXml)
        MESSAGEBOX("Eroare generare XML", 16, "Eroare")
        RETURN .F.
    ENDIF
    
    * Salvare XML pentru debugging
    STRTOFILE(lcXml, ".\CACHE_ANAF\factura_" + TRANSFORM(tnIdFactura) + ".xml")
    
    * Validare XML
    ? ""
    ? "Validare XML..."
    IF !loClient.ValidateXML(lcXml, lcXsdPath)
        MESSAGEBOX("XML invalid - verificați erorile", 16, "Eroare")
        RETURN .F.
    ENDIF
    
    * Semnare XML
    ? ""
    ? "Semnare XML..."
    lcSignedXml = loClient.SignXML(lcXml)
    
    IF ISNULL(lcSignedXml)
        MESSAGEBOX("Eroare semnare XML", 16, "Eroare")
        RETURN .F.
    ENDIF
    
    * Salvare XML semnat
    STRTOFILE(lcSignedXml, ".\CACHE_ANAF\factura_" + TRANSFORM(tnIdFactura) + "_signed.xml")
    
    * Verificare semnătură
    ? ""
    ? "Verificare semnătură..."
    IF !loClient.VerifySignature(lcSignedXml)
        MESSAGEBOX("Semnătură invalidă", 16, "Eroare")
        RETURN .F.
    ENDIF
    
    * Upload la ANAF
    ? ""
    ? "Upload la ANAF..."
    lcResponse = loClient.UploadInvoice(lcSignedXml, lcCIF)
    
    IF ISNULL(lcResponse)
        MESSAGEBOX("Eroare upload la ANAF", 16, "Eroare")
        RETURN .F.
    ENDIF
    
    * Parsare răspuns
    ? ""
    ? "Procesare răspuns..."
    IF ProcessANAFResponse(lcResponse, tnIdFactura)
        MESSAGEBOX("Factură uploadată cu succes la ANAF!", 64, "Succes")
        RETURN .T.
    ELSE
        MESSAGEBOX("Eroare procesare răspuns ANAF", 48, "Avertisment")
        RETURN .F.
    ENDIF
ENDPROC

*====================================================================
* Procedură: ProcessANAFResponse
* Scop: Procesare răspuns de la ANAF după upload
*====================================================================
FUNCTION ProcessANAFResponse(tcResponse, tnIdFactura)
    LOCAL loJson, lcStatus, lcUploadIndex
    
    TRY
        * Parsare JSON răspuns
        loJson = ParseJSON(tcResponse)  && Funcție helper
        
        * Extragere informații
        lcStatus = GetJSONValue(loJson, "status")
        lcUploadIndex = GetJSONValue(loJson, "index_incarcare")
        
        ? "Status: " + lcStatus
        ? "Index încărcare: " + lcUploadIndex
        
        * Actualizare bază de date
        UPDATE Facturi ;
            SET ANAF_Status = lcStatus, ;
                ANAF_UploadIndex = lcUploadIndex, ;
                ANAF_UploadDate = DATETIME() ;
            WHERE IdFactura = tnIdFactura
        
        RETURN (lcStatus = "ok" OR lcStatus = "success")
        
    CATCH TO loException
        ? "Eroare procesare răspuns: " + loException.Message
        RETURN .F.
    ENDTRY
ENDFUNC
```

## OAuth2 Authentication

Pentru autentificare la API-ul ANAF, este necesar un flux OAuth2. Documentația completă este disponibilă pe portalul ANAF.

### Obținere Access Token (simplificat)

```foxpro
FUNCTION GetANAFAccessToken()
    LOCAL loHttp, lcClientId, lcClientSecret, lcTokenUrl, lcResponse
    
    * Credențiale OAuth2 (stocate securizat!)
    lcClientId = GetSecureConfig("ANAF_CLIENT_ID")
    lcClientSecret = GetSecureConfig("ANAF_CLIENT_SECRET")
    lcTokenUrl = "https://logincert.anaf.ro/anaf-oauth2/v1/token"
    
    * Apel pentru obținere token
    * (implementare completă necesită librării OAuth2)
    
    RETURN lcAccessToken
ENDFUNC
```

## Resurse și Documentație

- [Portal ANAF e-Factura](https://www.anaf.ro/efactura)
- [Documentație API ANAF](https://static.anaf.ro/static/10/Anaf/Informatii_R/API_eFactura.htm)
- [Standard UBL 2.1](http://docs.oasis-open.org/ubl/UBL-2.1.html)
- [XSD Schemas pentru validare](https://www.anaf.ro/efactura/schemas)

## Contact

Pentru suport suplimentar, consultați documentația generală de modernizare.
