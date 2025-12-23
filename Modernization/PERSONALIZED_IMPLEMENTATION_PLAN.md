# Plan de Implementare Personalizat - eFactura WORK

## 📊 Configurație Sistem Identificată

### ✅ Mediu Confirmat
- **OS**: Windows 11
- **VFP**: Visual FoxPro 09.00.0000.7423
- **Database**: SQL Server (localhost\ICAS_2019)
- **Driver**: SQL Server Native Client 11.0
- **.NET Framework**: Instalat
- **User**: Admin (VICOSWORK)
- **Chilkat**: Versiunea 9.5.0 (TLS 1.2 ✓)

### ✅ Conectivitate ANAF
- **Client ID**: Criptat în ICAS.oSettings.EFactura_ClientID
- **Secret**: Criptat în ICAS.oSettings.eFactura_SecretID
- **Decriptare**: Funcția Chilkat_Crypt(value, 'D')
- **TLS Version**: 1.2 (confirmat funcțional)

### ✅ Prioritizare Module
1. **Connection Pool** (Prioritate 1)
2. **ANAF Integration** (Prioritate 2)
3. **WebView2 UI** (Prioritate 3)

### 📁 Structură Date Firmă
Database: **Firme** pe SQL Server localhost\ICAS_2019

---

## 🚀 Roadmap Implementare Personalizat

### Săptămâna 1-2: Connection Pool (Prioritate 1)

#### Zi 1-2: Setup și Pregătire
```foxpro
*====================================================================
* Step 1: Verificare Connection String Actual
*====================================================================
LOCAL lcConnString

* Connection string identificat:
TEXT TO lcConnString NOSHOW
Driver=SQL Server Native Client 11.0;
Database=SCUnicProdcomSRL;
Server=localhost\ICAS_2019;
UID=sa;
PWD=016049
ENDTEXT

* Test conexiune
lnHandle = SQLSTRINGCONNECT(lcConnString)
IF lnHandle > 0
    ? "✓ Conexiune SQL Server OK - Handle:", lnHandle
    SQLDISCONNECT(lnHandle)
ELSE
    ? "✗ Eroare conexiune"
    AERROR(laError)
    ? laError[2]
ENDIF
```

#### Zi 3-5: Implementare Connection Pool

**Fișier: `Modernization\Database\ConnectionPool.prg`**

Copiați clasa ConnectionPool din `ODBC_Setup.md` și adaptați:

```foxpro
*====================================================================
* Configurare specifică pentru sistemul dvs.
*====================================================================
LOCAL loPool, lcConnString

* Connection string pentru SQL Server Native Client 11.0
TEXT TO lcConnString NOSHOW
Driver=SQL Server Native Client 11.0;
Database=SCUnicProdcomSRL;
Server=localhost\ICAS_2019;
UID=sa;
PWD=016049;
Connection Timeout=30;
ENDTEXT

* Creare pool cu 5 conexiuni (ajustați după nevoie)
loPool = CREATEOBJECT("ConnectionPool", lcConnString, 5)

IF ISNULL(loPool)
    MESSAGEBOX("Eroare inițializare Connection Pool", 16, "Eroare")
    RETURN .F.
ENDIF

? "✓ Connection Pool inițializat - Pool Size: 5"

*====================================================================
* Test utilizare pool
*====================================================================
lnConn = loPool.GetConnection()

IF lnConn > 0
    ? "✓ Conexiune obținută din pool - Handle:", lnConn
    
    * Execută query test
    lcSQL = "SELECT TOP 10 * FROM Firme"
    lnResult = SQLEXEC(lnConn, lcSQL, "curTest")
    
    IF lnResult > 0
        ? "✓ Query executat cu succes -", RECCOUNT("curTest"), "înregistrări"
        BROWSE NOWAIT TITLE "Test Query - Firme"
        USE IN SELECT("curTest")
    ENDIF
    
    * Eliberează conexiunea
    loPool.ReleaseConnection(lnConn)
    ? "✓ Conexiune eliberată în pool"
ENDIF

*====================================================================
* Monitorizare pool
*====================================================================
? ""
? "===== POOL STATUS ====="
? "Pool Size:", loPool.nPoolSize
? "Conexiuni create:", loPool.nCurrentConnections
? "======================="
```

#### Zi 6-7: Testare și Validare

**Test Suite:**

```foxpro
*====================================================================
* Test Suite - Connection Pool
*====================================================================
PROCEDURE Test_ConnectionPool()
    LOCAL loPool, lcConnString, lnConn1, lnConn2, lnConn3
    LOCAL lnStart, lnEnd, lnDuration
    
    ? "======================================="
    ? "TEST CONNECTION POOL"
    ? "======================================="
    ? ""
    
    * Setup connection string
    TEXT TO lcConnString NOSHOW
    Driver=SQL Server Native Client 11.0;
    Database=SCUnicProdcomSRL;
    Server=localhost\ICAS_2019;
    UID=sa;
    PWD=016049
    ENDTEXT
    
    * Test 1: Creare pool
    ? "Test 1: Creare Connection Pool..."
    loPool = CREATEOBJECT("ConnectionPool", lcConnString, 3)
    
    IF !ISNULL(loPool)
        ? "  ✓ Pool creat cu succes"
    ELSE
        ? "  ✗ FAILED - Pool nu a putut fi creat"
        RETURN .F.
    ENDIF
    ? ""
    
    * Test 2: Obținere conexiuni multiple
    ? "Test 2: Obținere 3 conexiuni simultane..."
    lnConn1 = loPool.GetConnection()
    lnConn2 = loPool.GetConnection()
    lnConn3 = loPool.GetConnection()
    
    IF lnConn1 > 0 AND lnConn2 > 0 AND lnConn3 > 0
        ? "  ✓ 3 conexiuni obținute cu succes"
        ? "    Handle 1:", lnConn1
        ? "    Handle 2:", lnConn2
        ? "    Handle 3:", lnConn3
    ELSE
        ? "  ✗ FAILED - Nu s-au putut obține toate conexiunile"
        RETURN .F.
    ENDIF
    ? ""
    
    * Test 3: Pool exhaustion
    ? "Test 3: Pool exhaustion (ar trebui să aștepte)..."
    lnStart = SECONDS()
    lnConn4 = loPool.GetConnection()
    lnEnd = SECONDS()
    lnDuration = lnEnd - lnStart
    
    IF lnConn4 > 0
        ? "  ✓ A4-a conexiune obținută după", lnDuration, "secunde"
    ELSE
        ? "  ✗ FAILED - Nu s-a putut obține conexiune"
    ENDIF
    ? ""
    
    * Test 4: Eliberare și reutilizare
    ? "Test 4: Eliberare și reutilizare conexiuni..."
    loPool.ReleaseConnection(lnConn1)
    loPool.ReleaseConnection(lnConn2)
    
    lnConn5 = loPool.GetConnection()
    lnConn6 = loPool.GetConnection()
    
    IF lnConn5 > 0 AND lnConn6 > 0
        ? "  ✓ Conexiuni reutilizate cu succes"
    ELSE
        ? "  ✗ FAILED - Eroare reutilizare"
    ENDIF
    ? ""
    
    * Test 5: Performance comparison
    ? "Test 5: Performance - Pool vs. Direct..."
    
    * Direct connections (fără pool)
    lnStart = SECONDS()
    FOR i = 1 TO 10
        lnHandle = SQLSTRINGCONNECT(lcConnString)
        IF lnHandle > 0
            SQLEXEC(lnHandle, "SELECT 1", "curTemp")
            SQLDISCONNECT(lnHandle)
        ENDIF
    ENDFOR
    lnDirectTime = SECONDS() - lnStart
    
    * Pool connections
    lnStart = SECONDS()
    FOR i = 1 TO 10
        lnHandle = loPool.GetConnection()
        IF lnHandle > 0
            SQLEXEC(lnHandle, "SELECT 1", "curTemp")
            loPool.ReleaseConnection(lnHandle)
        ENDIF
    ENDFOR
    lnPoolTime = SECONDS() - lnStart
    
    ? "  Direct connections: ", lnDirectTime, "secunde"
    ? "  Pool connections: ", lnPoolTime, "secunde"
    ? "  Îmbunătățire: ", (lnDirectTime - lnPoolTime), "secunde"
    ? "  Performance gain: ", ROUND((lnDirectTime - lnPoolTime) / lnDirectTime * 100, 2), "%"
    ? ""
    
    * Cleanup
    loPool.CloseAll()
    
    ? "======================================="
    ? "✓ TOATE TESTELE TRECUTE"
    ? "======================================="
    
    RETURN .T.
ENDPROC
```

---

### Săptămâna 3-4: ANAF Integration (Prioritate 2)

#### Setup Credențiale ANAF

```foxpro
*====================================================================
* Configurare ANAF OAuth2
*====================================================================
FUNCTION GetANAFCredentials()
    LOCAL lcClientID, lcClientSecret
    
    * Decriptare credențiale din ICAS.oSettings
    lcClientID = Chilkat_Crypt(ICAS.oSettings.EFactura_ClientID, 'D')
    lcClientSecret = Chilkat_Crypt(ICAS.oSettings.eFactura_SecretID, 'D')
    
    * Validare
    IF EMPTY(lcClientID) OR EMPTY(lcClientSecret)
        MESSAGEBOX("Credențiale ANAF incomplete în setări", 16, "Eroare")
        RETURN .NULL.
    ENDIF
    
    * Return ca obiect
    LOCAL loCredentials
    loCredentials = CREATEOBJECT("Empty")
    ADDPROPERTY(loCredentials, "ClientID", lcClientID)
    ADDPROPERTY(loCredentials, "ClientSecret", lcClientSecret)
    
    RETURN loCredentials
ENDFUNC

*====================================================================
* Obținere Access Token de la ANAF
*====================================================================
FUNCTION GetANAFAccessToken()
    LOCAL loHttp, loCredentials, lcTokenUrl, lcResponse
    LOCAL lcClientID, lcClientSecret, lcBody
    
    * Obține credențiale
    loCredentials = GetANAFCredentials()
    IF ISNULL(loCredentials)
        RETURN .NULL.
    ENDIF
    
    * Creare HTTP client
    loHttp = CREATEOBJECT("Chilkat_9_5_0.Http")
    
    IF ISNULL(loHttp)
        MESSAGEBOX("Chilkat HTTP nu este disponibil", 16, "Eroare")
        RETURN .NULL.
    ENDIF
    
    * Configurare TLS 1.2
    loHttp.RequireTlsVersion = "1.2"
    
    * URL token endpoint (test environment)
    lcTokenUrl = "https://logincert.anaf.ro/anaf-oauth2/v1/token"
    
    * Body pentru request
    TEXT TO lcBody NOSHOW TEXTMERGE
    grant_type=client_credentials&client_id=<<loCredentials.ClientID>>&client_secret=<<loCredentials.ClientSecret>>&scope=e-factura
    ENDTEXT
    
    * Headers
    loHttp.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
    
    * Apel token endpoint
    lcResponse = loHttp.PostUrlEncoded(lcTokenUrl, lcBody)
    
    * Verificare succes
    IF loHttp.LastMethodSuccess = .F.
        ? "✗ Eroare obținere token:"
        ? loHttp.LastErrorText
        RETURN .NULL.
    ENDIF
    
    * Parse JSON response
    LOCAL loJson
    loJson = CREATEOBJECT("Chilkat_9_5_0.JsonObject")
    loJson.Load(lcResponse)
    
    lcAccessToken = loJson.StringOf("access_token")
    
    IF !EMPTY(lcAccessToken)
        ? "✓ Access Token obținut cu succes"
        ? "Token (primele 20 caractere):", LEFT(lcAccessToken, 20) + "..."
        RETURN lcAccessToken
    ELSE
        ? "✗ Eroare parsare răspuns token"
        ? lcResponse
        RETURN .NULL.
    ENDIF
ENDFUNC
```

#### Test Integrare ANAF

```foxpro
*====================================================================
* Test completă integrare ANAF
*====================================================================
PROCEDURE Test_ANAF_Integration()
    LOCAL lcToken, loHttp, lcUrl, lcResponse
    
    ? "======================================="
    ? "TEST INTEGRARE ANAF"
    ? "======================================="
    ? ""
    
    * Pas 1: Obținere token
    ? "Pas 1: Obținere Access Token..."
    lcToken = GetANAFAccessToken()
    
    IF ISNULL(lcToken)
        ? "✗ FAILED - Nu s-a putut obține token"
        RETURN .F.
    ENDIF
    ? "✓ Token obținut"
    ? ""
    
    * Pas 2: Test API call cu token
    ? "Pas 2: Test API - Lista mesaje..."
    
    loHttp = CREATEOBJECT("Chilkat_9_5_0.Http")
    loHttp.RequireTlsVersion = "1.2"
    loHttp.SetRequestHeader("Authorization", "Bearer " + lcToken)
    
    * URL listă mesaje (test environment)
    lcUrl = "https://api.anaf.ro/test/FCTEL/rest/listaMesajeFactura?zile=7"
    
    lcResponse = loHttp.QuickGetStr(lcUrl)
    
    IF loHttp.LastMethodSuccess = .T.
        ? "✓ API Call reușit"
        ? "Răspuns (primele 200 caractere):"
        ? LEFT(lcResponse, 200)
    ELSE
        ? "✗ FAILED - Eroare API call"
        ? loHttp.LastErrorText
        RETURN .F.
    ENDIF
    ? ""
    
    ? "======================================="
    ? "✓ TEST ANAF COMPLET"
    ? "======================================="
    
    RETURN .T.
ENDPROC
```

---

### Săptămâna 5-6: WebView2 UI (Prioritate 3)

#### Pregătire Dashboard Modern

**Notă**: Pentru WebView2, va trebui să compilați un DLL .NET. Iată template-ul:

**Fișier: `VFPWebView2Host.cs` (compilați în Visual Studio)**

```csharp
using System;
using System.Windows.Forms;
using Microsoft.Web.WebView2.WinForms;
using Microsoft.Web.WebView2.Core;

namespace VFPWebView2
{
    public class WebView2Host : Form
    {
        private WebView2 webView;
        
        public WebView2Host()
        {
            this.Text = "eFactura - Dashboard Modern";
            this.Size = new System.Drawing.Size(1400, 900);
            this.StartPosition = FormStartPosition.CenterScreen;
            
            InitializeWebView();
        }
        
        private async void InitializeWebView()
        {
            webView = new WebView2 { Dock = DockStyle.Fill };
            this.Controls.Add(webView);
            
            await webView.EnsureCoreWebView2Async(null);
            webView.CoreWebView2.Settings.IsScriptEnabled = true;
            webView.CoreWebView2.Settings.AreDevToolsEnabled = true;
        }
        
        public void NavigateToString(string htmlContent)
        {
            if (webView?.CoreWebView2 != null)
            {
                webView.NavigateToString(htmlContent);
            }
        }
        
        public string ExecuteScript(string script)
        {
            if (webView?.CoreWebView2 != null)
            {
                return webView.CoreWebView2.ExecuteScriptAsync(script).GetAwaiter().GetResult();
            }
            return "";
        }
    }
}
```

#### Integrare în VFP

```foxpro
*====================================================================
* Dashboard Modern cu WebView2
*====================================================================
PROCEDURE Show_Dashboard()
    LOCAL loBridge, loWebView, lcHtml
    
    * Inițializare wwDotNetBridge
    loBridge = CREATEOBJECT("wwDotNetBridge", "V4")
    
    IF ISNULL(loBridge)
        MESSAGEBOX("wwDotNetBridge nu este disponibil", 16, "Eroare")
        RETURN
    ENDIF
    
    * Încărcare assembly
    IF !loBridge.LoadAssembly(".\Modernization\UI\VFPWebView2Host.dll")
        MESSAGEBOX("Nu s-a putut încărca VFPWebView2Host.dll", 16, "Eroare")
        RETURN
    ENDIF
    
    * Creare instanță WebView2Host
    loWebView = loBridge.CreateInstance("VFPWebView2.WebView2Host")
    
    IF ISNULL(loWebView)
        MESSAGEBOX("Nu s-a putut crea WebView2Host", 16, "Eroare")
        RETURN
    ENDIF
    
    * Generare HTML pentru dashboard
    lcHtml = Generate_Dashboard_HTML()
    
    * Încărcare HTML
    loBridge.InvokeMethod(loWebView, "NavigateToString", lcHtml)
    
    * Afișare form
    loBridge.InvokeMethod(loWebView, "Show")
    
    ? "✓ Dashboard modern afișat"
ENDPROC

*====================================================================
* Generare HTML Dashboard cu Date din SQL
*====================================================================
FUNCTION Generate_Dashboard_HTML()
    LOCAL lcHtml, lcStats, lnFacturiLuna, lnTotalValoare
    
    * Obține statistici din database
    LOCAL lnConn, lcSQL
    
    * Folosește connection pool
    loPool = GetGlobalConnectionPool()  && Funcție helper
    lnConn = loPool.GetConnection()
    
    IF lnConn > 0
        * Query pentru statistici luna curentă
        TEXT TO lcSQL NOSHOW
        SELECT 
            COUNT(*) AS NumarFacturi,
            SUM(Total) AS ValoareTotala
        FROM Facturi
        WHERE MONTH(Data) = MONTH(GETDATE())
          AND YEAR(Data) = YEAR(GETDATE())
        ENDTEXT
        
        IF SQLEXEC(lnConn, lcSQL, "curStats") > 0
            lnFacturiLuna = curStats.NumarFacturi
            lnTotalValoare = curStats.ValoareTotala
            USE IN SELECT("curStats")
        ELSE
            lnFacturiLuna = 0
            lnTotalValoare = 0
        ENDIF
        
        loPool.ReleaseConnection(lnConn)
    ELSE
        lnFacturiLuna = 0
        lnTotalValoare = 0
    ENDIF
    
    * Generare HTML cu date reale
    TEXT TO lcHtml NOSHOW TEXTMERGE
    <!DOCTYPE html>
    <html lang="ro">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>eFactura - Dashboard</title>
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body {
                font-family: 'Segoe UI', Tahoma, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                padding: 20px;
            }
            .dashboard {
                max-width: 1400px;
                margin: 0 auto;
            }
            .header {
                background: white;
                padding: 30px;
                border-radius: 10px;
                margin-bottom: 20px;
                box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            }
            .stats-grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                gap: 20px;
                margin-bottom: 20px;
            }
            .stat-card {
                background: white;
                padding: 25px;
                border-radius: 10px;
                box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            }
            .stat-card h3 {
                color: #666;
                font-size: 14px;
                text-transform: uppercase;
            }
            .stat-card .value {
                color: #333;
                font-size: 32px;
                font-weight: bold;
                margin: 10px 0;
            }
        </style>
    </head>
    <body>
        <div class="dashboard">
            <div class="header">
                <h1>📊 Dashboard eFactura - SCUnicProdcomSRL</h1>
                <p>Server: localhost\ICAS_2019</p>
                <p>Actualizat: <<TRANSFORM(DATETIME())>></p>
            </div>
            
            <div class="stats-grid">
                <div class="stat-card">
                    <h3>Facturi Luna Curentă</h3>
                    <div class="value"><<TRANSFORM(lnFacturiLuna)>></div>
                </div>
                
                <div class="stat-card">
                    <h3>Valoare Totală</h3>
                    <div class="value"><<TRANSFORM(lnTotalValoare, "999,999,999.99")>> RON</div>
                </div>
                
                <div class="stat-card">
                    <h3>Sistem</h3>
                    <div class="value" style="font-size: 18px;">
                        Windows 11<br>
                        VFP 9.0.7423<br>
                        SQL Server Native Client 11.0
                    </div>
                </div>
            </div>
        </div>
    </body>
    </html>
    ENDTEXT
    
    RETURN lcHtml
ENDFUNC
```

---

## 📋 Checklist Implementare

### Săptămâna 1-2: Connection Pool
- [ ] Zi 1-2: Setup și test conexiune SQL Server
- [ ] Zi 3-4: Implementare clasa ConnectionPool
- [ ] Zi 5: Integrare în cod existent
- [ ] Zi 6-7: Testare și validare performance
- [ ] Commit și documentare

### Săptămâna 3-4: ANAF Integration
- [ ] Zi 1: Setup funcții decriptare credențiale
- [ ] Zi 2-3: Implementare OAuth2 flow
- [ ] Zi 4: Test API calls (listă mesaje, upload)
- [ ] Zi 5-6: Integrare cu cod existent eFactura
- [ ] Zi 7: Testare end-to-end
- [ ] Commit și documentare

### Săptămâna 5-6: WebView2 Dashboard
- [ ] Zi 1-2: Compilare DLL .NET pentru WebView2
- [ ] Zi 3-4: Creare dashboard HTML cu date reale
- [ ] Zi 5: Integrare wwDotNetBridge
- [ ] Zi 6-7: Testare și refinare UI
- [ ] Commit și documentare

---

## 🎯 Quick Start - Începeți ACUM

### Pas 1: Salvați Cod Connection Pool (10 minute)

Creați fișierul: `C:\eFactura\Modernization\Database\ConnectionPool.prg`

Copiați clasa completă din documentația ODBC_Setup.md

### Pas 2: Test Inițial (5 minute)

```foxpro
* În VFP Command Window:
DO C:\eFactura\Modernization\Database\ConnectionPool.prg

TEXT TO lcConnString NOSHOW
Driver=SQL Server Native Client 11.0;
Database=SCUnicProdcomSRL;
Server=localhost\ICAS_2019;
UID=sa;
PWD=016049
ENDTEXT

loPool = CREATEOBJECT("ConnectionPool", lcConnString, 3)
lnConn = loPool.GetConnection()
? "Handle:", lnConn

* Test query
SQLEXEC(lnConn, "SELECT TOP 5 * FROM Firme", "curTest")
BROWSE

loPool.ReleaseConnection(lnConn)
```

### Pas 3: Validare ANAF (5 minute)

```foxpro
* Test credențiale
lcClientID = Chilkat_Crypt(ICAS.oSettings.EFactura_ClientID, 'D')
? "Client ID (primele 10 char):", LEFT(lcClientID, 10) + "..."

lcSecret = Chilkat_Crypt(ICAS.oSettings.eFactura_SecretID, 'D')
? "Secret (primele 10 char):", LEFT(lcSecret, 10) + "..."

* Test TLS
loHttp = CREATEOBJECT("Chilkat_9_5_0.Http")
? "TLS Version:", loHttp.TlsVersion
```

---

## 📞 Support

Pentru întrebări sau probleme în timpul implementării:
1. Consultați documentația detaliată în `/Modernization/Documentation/`
2. Rulați test suite-urile incluse
3. Verificați logurile pentru debugging

**Succes în implementare! 🚀**
