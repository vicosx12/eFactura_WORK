# Integrare WebView2 pentru UI Modern în VFP 9.0

## Introducere

WebView2 este componenta Microsoft bazată pe Chromium Edge care permite încapsularea unui browser modern în aplicații desktop. Pentru aplicații Visual FoxPro 9.0, WebView2 oferă posibilitatea de a crea interfețe moderne, responsive, bazate pe tehnologii web (HTML5, CSS3, JavaScript) fără a fi nevoie să renunțați la codul VFP existent.

## Avantaje WebView2

### 1. UI Modern
- Design responsive și atractiv
- Suport pentru framework-uri moderne (React, Vue, Angular)
- Teme personalizabile (dark mode, light mode)
- Animații și tranziții fluide

### 2. Compatibilitate
- Suport nativ pentru Windows 10/11
- High DPI scaling automat
- Accessibility features integrate
- Touch și stylus support

### 3. Funcționalitate
- JavaScript interop cu VFP
- Stocare locală (localStorage, IndexedDB)
- WebSocket pentru comunicare real-time
- Suport pentru PDF, media playback

### 4. Performanță
- Rendering hardware-accelerat
- Multi-process architecture
- Memory management eficient
- Actualizări automate prin Windows Update

## Arhitectură Integrare

```
VFP Application
    ↓
wwDotNetBridge
    ↓
.NET WinForms Host
    ↓
WebView2 Control
    ↓
HTML/CSS/JavaScript UI
```

## Cerințe

### Software
- Windows 10/11
- WebView2 Runtime (instalat automat de Windows Update sau manual)
- wwDotNetBridge
- .NET Framework 4.7.2+

### Componente
1. **Microsoft.Web.WebView2** NuGet package
2. **.NET WinForms wrapper** (host pentru WebView2)
3. **VFP integration layer** (prin wwDotNetBridge)

## Implementare

### 1. Clasa .NET pentru WebView2 Host (C#)

Salvați ca `WebView2Host.cs` și compilați în DLL:

```csharp
using System;
using System.Threading.Tasks;
using System.Windows.Forms;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;

namespace VFPWebView2
{
    public class WebView2Host : Form
    {
        private WebView2 webView;
        private bool isInitialized = false;
        
        public WebView2Host()
        {
            this.Text = "eFactura - Modern UI";
            this.Size = new System.Drawing.Size(1200, 800);
            this.StartPosition = FormStartPosition.CenterScreen;
            
            InitializeWebView();
        }
        
        private async void InitializeWebView()
        {
            webView = new WebView2
            {
                Dock = DockStyle.Fill
            };
            
            this.Controls.Add(webView);
            
            try
            {
                await webView.EnsureCoreWebView2Async(null);
                isInitialized = true;
                
                // Configurare settings
                webView.CoreWebView2.Settings.IsScriptEnabled = true;
                webView.CoreWebView2.Settings.AreDefaultScriptDialogsEnabled = true;
                webView.CoreWebView2.Settings.IsWebMessageEnabled = true;
                webView.CoreWebView2.Settings.AreDevToolsEnabled = true; // Pentru debugging
                
                // Event handlers pentru comunicare VFP <-> JavaScript
                webView.CoreWebView2.WebMessageReceived += CoreWebView2_WebMessageReceived;
                
                Console.WriteLine("WebView2 initialized successfully");
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error initializing WebView2: {ex.Message}", 
                    "Initialization Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
        
        /// <summary>
        /// Navighează la un URL
        /// </summary>
        public void Navigate(string url)
        {
            if (!isInitialized)
            {
                Task.Run(async () =>
                {
                    while (!isInitialized)
                    {
                        await Task.Delay(100);
                    }
                    webView.Invoke(new Action(() => webView.Source = new Uri(url)));
                });
            }
            else
            {
                webView.Source = new Uri(url);
            }
        }
        
        /// <summary>
        /// Încarcă HTML direct
        /// </summary>
        public void NavigateToString(string htmlContent)
        {
            if (!isInitialized)
            {
                Task.Run(async () =>
                {
                    while (!isInitialized)
                    {
                        await Task.Delay(100);
                    }
                    webView.Invoke(new Action(() => webView.NavigateToString(htmlContent)));
                });
            }
            else
            {
                webView.NavigateToString(htmlContent);
            }
        }
        
        /// <summary>
        /// Execută JavaScript și returnează rezultat
        /// </summary>
        public async Task<string> ExecuteScriptAsync(string script)
        {
            if (!isInitialized)
            {
                throw new InvalidOperationException("WebView2 not initialized");
            }
            
            return await webView.CoreWebView2.ExecuteScriptAsync(script);
        }
        
        /// <summary>
        /// Execută JavaScript (sincron pentru VFP)
        /// </summary>
        public string ExecuteScript(string script)
        {
            return ExecuteScriptAsync(script).GetAwaiter().GetResult();
        }
        
        /// <summary>
        /// Trimite mesaj către JavaScript
        /// </summary>
        public void PostWebMessage(string message)
        {
            if (isInitialized)
            {
                webView.CoreWebView2.PostWebMessageAsString(message);
            }
        }
        
        /// <summary>
        /// Event handler pentru mesaje primite din JavaScript
        /// </summary>
        private void CoreWebView2_WebMessageReceived(object sender, 
            CoreWebView2WebMessageReceivedEventArgs e)
        {
            string message = e.TryGetWebMessageAsString();
            
            // Trigger event care poate fi interceptat din VFP
            OnMessageReceived(message);
        }
        
        /// <summary>
        /// Event pentru mesaje JavaScript -> VFP
        /// </summary>
        public event EventHandler<string> MessageReceived;
        
        protected virtual void OnMessageReceived(string message)
        {
            MessageReceived?.Invoke(this, message);
            
            // Log pentru debugging
            Console.WriteLine($"Message from JavaScript: {message}");
        }
        
        /// <summary>
        /// Configurare pentru debugging
        /// </summary>
        public void EnableDevTools(bool enable)
        {
            if (isInitialized)
            {
                webView.CoreWebView2.Settings.AreDevToolsEnabled = enable;
            }
        }
        
        /// <summary>
        /// Deschide DevTools (F12)
        /// </summary>
        public void OpenDevTools()
        {
            if (isInitialized)
            {
                webView.CoreWebView2.OpenDevToolsWindow();
            }
        }
    }
}
```

### 2. Wrapper VFP pentru WebView2

```foxpro
*====================================================================
* Program: WebView2_Wrapper.prg
* Scop: Wrapper VFP pentru utilizare WebView2
*====================================================================

*====================================================================
* Clasa: WebView2Form
* Scop: Încapsulare WebView2 pentru UI modern
*====================================================================
DEFINE CLASS WebView2Form AS Custom
    oBridge = .NULL.
    oWebView = .NULL.
    cCurrentUrl = ""
    lInitialized = .F.
    
    *================================================================
    * Metodă: Init
    *================================================================
    PROCEDURE Init()
        LOCAL llSuccess, lcAssemblyPath
        
        TRY
            * Inițializare wwDotNetBridge
            THIS.oBridge = CREATEOBJECT("wwDotNetBridge", "V4")
            
            IF ISNULL(THIS.oBridge)
                MESSAGEBOX("Nu s-a putut inițializa wwDotNetBridge", 16, "Eroare")
                RETURN .F.
            ENDIF
            
            * Încărcare assembly WebView2
            lcAssemblyPath = FULLPATH(".\Modernization\UI\VFPWebView2.dll")
            
            IF !FILE(lcAssemblyPath)
                MESSAGEBOX("Assembly VFPWebView2.dll nu există", 16, "Eroare")
                RETURN .F.
            ENDIF
            
            IF !THIS.oBridge.LoadAssembly(lcAssemblyPath)
                MESSAGEBOX("Nu s-a putut încărca VFPWebView2.dll", 16, "Eroare")
                RETURN .F.
            ENDIF
            
            * Creare instanță WebView2Host
            THIS.oWebView = THIS.oBridge.CreateInstance("VFPWebView2.WebView2Host")
            
            IF ISNULL(THIS.oWebView)
                MESSAGEBOX("Nu s-a putut crea instanța WebView2Host", 16, "Eroare")
                RETURN .F.
            ENDIF
            
            * Așteptare inițializare (WebView2 se inițializează async)
            THIS.WaitForInitialization()
            
            THIS.lInitialized = .T.
            ? "WebView2 inițializat cu succes"
            
            llSuccess = .T.
            
        CATCH TO loException
            MESSAGEBOX("Eroare inițializare: " + loException.Message, 16, "Eroare")
            llSuccess = .F.
        ENDTRY
        
        RETURN llSuccess
    ENDPROC
    
    *================================================================
    * Metodă: WaitForInitialization
    *================================================================
    PROTECTED PROCEDURE WaitForInitialization()
        LOCAL lnAttempts, lnMaxAttempts
        
        lnMaxAttempts = 50  && 5 secunde (50 * 100ms)
        
        FOR lnAttempts = 1 TO lnMaxAttempts
            DECLARE INTEGER Sleep IN Win32API INTEGER nMilliseconds
            Sleep(100)
            
            * Verificare dacă e inițializat (tentativă simplă)
            TRY
                THIS.oBridge.GetProperty(THIS.oWebView, "Text")
                EXIT
            CATCH
                * Încă nu e gata
            ENDTRY
        ENDFOR
    ENDPROC
    
    *================================================================
    * Metodă: Show
    * Scop: Afișează form-ul WebView2
    *================================================================
    PROCEDURE Show()
        IF ISNULL(THIS.oWebView)
            RETURN .F.
        ENDIF
        
        TRY
            THIS.oBridge.InvokeMethod(THIS.oWebView, "Show")
            RETURN .T.
        CATCH TO loException
            MESSAGEBOX("Eroare afișare: " + loException.Message, 16, "Eroare")
            RETURN .F.
        ENDTRY
    ENDPROC
    
    *================================================================
    * Metodă: Navigate
    * Scop: Navighează la un URL
    *================================================================
    PROCEDURE Navigate(tcUrl)
        IF ISNULL(THIS.oWebView)
            RETURN .F.
        ENDIF
        
        TRY
            ? "Navigare la: " + tcUrl
            THIS.oBridge.InvokeMethod(THIS.oWebView, "Navigate", tcUrl)
            THIS.cCurrentUrl = tcUrl
            RETURN .T.
        CATCH TO loException
            MESSAGEBOX("Eroare navigare: " + loException.Message, 16, "Eroare")
            RETURN .F.
        ENDTRY
    ENDPROC
    
    *================================================================
    * Metodă: NavigateToString
    * Scop: Încarcă HTML direct
    *================================================================
    PROCEDURE NavigateToString(tcHtml)
        IF ISNULL(THIS.oWebView)
            RETURN .F.
        ENDIF
        
        TRY
            THIS.oBridge.InvokeMethod(THIS.oWebView, "NavigateToString", tcHtml)
            RETURN .T.
        CATCH TO loException
            MESSAGEBOX("Eroare încărcare HTML: " + loException.Message, 16, "Eroare")
            RETURN .F.
        ENDTRY
    ENDPROC
    
    *================================================================
    * Metodă: ExecuteScript
    * Scop: Execută JavaScript și returnează rezultat
    *================================================================
    PROCEDURE ExecuteScript(tcScript)
        LOCAL lcResult
        
        IF ISNULL(THIS.oWebView)
            RETURN .NULL.
        ENDIF
        
        TRY
            lcResult = THIS.oBridge.InvokeMethod(THIS.oWebView, "ExecuteScript", tcScript)
            RETURN lcResult
        CATCH TO loException
            ? "Eroare execuție script: " + loException.Message
            RETURN .NULL.
        ENDTRY
    ENDPROC
    
    *================================================================
    * Metodă: PostMessage
    * Scop: Trimite mesaj către JavaScript
    *================================================================
    PROCEDURE PostMessage(tcMessage)
        IF ISNULL(THIS.oWebView)
            RETURN .F.
        ENDIF
        
        TRY
            THIS.oBridge.InvokeMethod(THIS.oWebView, "PostWebMessage", tcMessage)
            RETURN .T.
        CATCH TO loException
            ? "Eroare trimitere mesaj: " + loException.Message
            RETURN .F.
        ENDTRY
    ENDPROC
    
    *================================================================
    * Metodă: OpenDevTools
    * Scop: Deschide Developer Tools pentru debugging
    *================================================================
    PROCEDURE OpenDevTools()
        IF ISNULL(THIS.oWebView)
            RETURN
        ENDIF
        
        TRY
            THIS.oBridge.InvokeMethod(THIS.oWebView, "OpenDevTools")
        CATCH TO loException
            ? "Eroare deschidere DevTools: " + loException.Message
        ENDTRY
    ENDPROC
    
    *================================================================
    * Metodă: Close
    *================================================================
    PROCEDURE Close()
        IF !ISNULL(THIS.oWebView)
            TRY
                THIS.oBridge.InvokeMethod(THIS.oWebView, "Close")
            CATCH
            ENDTRY
        ENDIF
    ENDPROC
    
    *================================================================
    * Metodă: Destroy
    *================================================================
    PROCEDURE Destroy()
        THIS.Close()
        THIS.oWebView = .NULL.
        THIS.oBridge = .NULL.
    ENDPROC
ENDDEFINE
```

### 3. Exemplu de utilizare - Dashboard modern

```foxpro
*====================================================================
* Procedură: Show_Modern_Dashboard
* Scop: Afișează dashboard modern pentru facturi
*====================================================================
PROCEDURE Show_Modern_Dashboard()
    LOCAL loWebView, lcHtml
    
    * Creare WebView2
    loWebView = CREATEOBJECT("WebView2Form")
    
    IF !loWebView.lInitialized
        MESSAGEBOX("Nu s-a putut inițializa WebView2", 16, "Eroare")
        RETURN
    ENDIF
    
    * Generare HTML pentru dashboard
    lcHtml = Generate_Dashboard_HTML()
    
    * Încărcare HTML
    loWebView.NavigateToString(lcHtml)
    
    * Afișare form
    loWebView.Show()
    
    * Opțional: Deschide DevTools pentru debugging
    * loWebView.OpenDevTools()
    
    ? "Dashboard afișat cu succes"
ENDPROC

*====================================================================
* Funcție: Generate_Dashboard_HTML
* Scop: Generează HTML pentru dashboard modern
*====================================================================
FUNCTION Generate_Dashboard_HTML()
    LOCAL lcHtml, lcData
    
    * Obține date pentru dashboard
    lcData = GetDashboardData()  && Funcție helper care returnează JSON
    
    TEXT TO lcHtml NOSHOW TEXTMERGE
    <!DOCTYPE html>
    <html lang="ro">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>eFactura - Dashboard</title>
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }
            
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
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
            
            .header h1 {
                color: #333;
                margin-bottom: 10px;
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
                transition: transform 0.3s ease;
            }
            
            .stat-card:hover {
                transform: translateY(-5px);
            }
            
            .stat-card h3 {
                color: #666;
                font-size: 14px;
                margin-bottom: 10px;
                text-transform: uppercase;
            }
            
            .stat-card .value {
                color: #333;
                font-size: 32px;
                font-weight: bold;
                margin-bottom: 5px;
            }
            
            .stat-card .trend {
                color: #4caf50;
                font-size: 14px;
            }
            
            .stat-card .trend.negative {
                color: #f44336;
            }
            
            .table-container {
                background: white;
                padding: 25px;
                border-radius: 10px;
                box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            }
            
            table {
                width: 100%;
                border-collapse: collapse;
            }
            
            th {
                background: #f5f5f5;
                padding: 15px;
                text-align: left;
                font-weight: 600;
                color: #333;
                border-bottom: 2px solid #ddd;
            }
            
            td {
                padding: 15px;
                border-bottom: 1px solid #eee;
            }
            
            tr:hover {
                background: #f9f9f9;
            }
            
            .status {
                display: inline-block;
                padding: 5px 15px;
                border-radius: 20px;
                font-size: 12px;
                font-weight: 600;
            }
            
            .status.success {
                background: #e8f5e9;
                color: #4caf50;
            }
            
            .status.pending {
                background: #fff3e0;
                color: #ff9800;
            }
            
            .status.error {
                background: #ffebee;
                color: #f44336;
            }
            
            .btn {
                padding: 10px 20px;
                border: none;
                border-radius: 5px;
                cursor: pointer;
                font-size: 14px;
                transition: all 0.3s ease;
            }
            
            .btn-primary {
                background: #667eea;
                color: white;
            }
            
            .btn-primary:hover {
                background: #5568d3;
            }
        </style>
    </head>
    <body>
        <div class="dashboard">
            <div class="header">
                <h1>📊 Dashboard eFactura</h1>
                <p>Actualizat: <<TRANSFORM(DATETIME())>></p>
            </div>
            
            <div class="stats-grid">
                <div class="stat-card">
                    <h3>Facturi Luna Curentă</h3>
                    <div class="value" id="currentMonthInvoices">0</div>
                    <div class="trend">↑ 12% față de luna trecută</div>
                </div>
                
                <div class="stat-card">
                    <h3>Valoare Totală</h3>
                    <div class="value" id="totalValue">0 RON</div>
                    <div class="trend">↑ 8% creștere</div>
                </div>
                
                <div class="stat-card">
                    <h3>Upload ANAF Astăzi</h3>
                    <div class="value" id="uploadedToday">0</div>
                    <div class="trend">✓ Toate procesate</div>
                </div>
                
                <div class="stat-card">
                    <h3>Erori</h3>
                    <div class="value" id="errors">0</div>
                    <div class="trend negative" id="errorTrend">Necesită atenție</div>
                </div>
            </div>
            
            <div class="table-container">
                <h2 style="margin-bottom: 20px;">Facturi Recente</h2>
                <table id="invoicesTable">
                    <thead>
                        <tr>
                            <th>Număr</th>
                            <th>Client</th>
                            <th>Data</th>
                            <th>Valoare</th>
                            <th>Status ANAF</th>
                            <th>Acțiuni</th>
                        </tr>
                    </thead>
                    <tbody id="invoicesBody">
                        <!-- Populated by JavaScript -->
                    </tbody>
                </table>
            </div>
        </div>
        
        <script>
            // Date din VFP (injectat dinamic)
            const dashboardData = <<lcData>>;
            
            // Populare statistici
            document.getElementById('currentMonthInvoices').textContent = 
                dashboardData.stats.currentMonth;
            document.getElementById('totalValue').textContent = 
                dashboardData.stats.totalValue.toLocaleString('ro-RO') + ' RON';
            document.getElementById('uploadedToday').textContent = 
                dashboardData.stats.uploadedToday;
            document.getElementById('errors').textContent = 
                dashboardData.stats.errors;
            
            // Populare tabel
            const tbody = document.getElementById('invoicesBody');
            dashboardData.invoices.forEach(invoice => {
                const row = tbody.insertRow();
                row.innerHTML = `
                    <td>${invoice.number}</td>
                    <td>${invoice.client}</td>
                    <td>${invoice.date}</td>
                    <td>${invoice.value.toLocaleString('ro-RO')} RON</td>
                    <td><span class="status ${invoice.statusClass}">${invoice.status}</span></td>
                    <td>
                        <button class="btn btn-primary" onclick="viewInvoice(${invoice.id})">
                            Vizualizare
                        </button>
                    </td>
                `;
            });
            
            // Funcție pentru vizualizare factură
            function viewInvoice(invoiceId) {
                // Trimite mesaj către VFP
                window.chrome.webview.postMessage({
                    action: 'viewInvoice',
                    invoiceId: invoiceId
                });
            }
            
            // Listener pentru mesaje de la VFP
            window.chrome.webview.addEventListener('message', event => {
                console.log('Message from VFP:', event.data);
                
                // Procesare comenzi de la VFP
                if (event.data.command === 'refresh') {
                    location.reload();
                }
            });
        </script>
    </body>
    </html>
    ENDTEXT
    
    RETURN lcHtml
ENDFUNC

*====================================================================
* Funcție: GetDashboardData
* Scop: Obține date pentru dashboard în format JSON
*====================================================================
FUNCTION GetDashboardData()
    LOCAL lcJson, lnCurrentMonth, lnTotalValue, lnUploadedToday, lnErrors
    
    * Query date
    SELECT COUNT(*) AS nCount FROM Facturi ;
        WHERE MONTH(Data) = MONTH(DATE()) ;
        INTO CURSOR curStats
    lnCurrentMonth = curStats.nCount
    USE IN SELECT("curStats")
    
    * Construire JSON
    TEXT TO lcJson NOSHOW TEXTMERGE
    {
        "stats": {
            "currentMonth": <<lnCurrentMonth>>,
            "totalValue": 150000.00,
            "uploadedToday": 25,
            "errors": 2
        },
        "invoices": [
            {
                "id": 1,
                "number": "FAC001",
                "client": "SC Test SRL",
                "date": "12.12.2024",
                "value": 1000.00,
                "status": "Trimis",
                "statusClass": "success"
            }
        ]
    }
    ENDTEXT
    
    RETURN lcJson
ENDFUNC
```

## Best Practices

### 1. Comunicare VFP ↔ JavaScript
- Folosiți JSON pentru transfer de date
- Implementați validare pe ambele părți
- Folosiți message passing pentru evenimente

### 2. Performanță
- Încărcați resurse local când e posibil
- Minimizați traficul de mesaje
- Folosiți caching pentru date frecvent accesate

### 3. Securitate
- Validați toate input-urile din JavaScript
- Sanitizați HTML pentru a preveni XSS
- Folosiți Content Security Policy

### 4. Debugging
- Activați DevTools în development
- Log-ați mesajele între VFP și JavaScript
- Testați pe diferite rezoluții

## Alternative

### CEF (Chromium Embedded Framework)
- Mai complex de integrat
- Mai mult control
- Necesită mai multe resurse

### Electron
- Pentru aplicații complet noi
- Nu pentru migrare VFP
- Arhitectură diferită

## Resurse

- [WebView2 Documentation](https://docs.microsoft.com/en-us/microsoft-edge/webview2/)
- [WebView2 Samples](https://github.com/MicrosoftEdge/WebView2Samples)
- [wwDotNetBridge](https://github.com/RickStrahl/wwDotnetBridge)

## Contact

Pentru suport suplimentar, consultați documentația generală de modernizare.
