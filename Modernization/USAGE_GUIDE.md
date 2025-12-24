# Usage Guide - Modernization Components

## 🚀 Quick Start

### Inițializare Completă (1 Comandă)

```foxpro
* În VFP Command Window sau din cod:
DO Modernization\Init_Modernization.prg
```

Această comandă va:
- ✅ Seta toate căile necesare
- ✅ Verifica componente (Chilkat, SQL Server)
- ✅ Crea Connection Pool global (5 conexiuni)
- ✅ Crea ANAF Client global (test environment)

---

## 📊 Connection Pool - Usage

### Utilizare Simplă

```foxpro
* Obține pool-ul global
loPool = GetGlobalConnectionPool()

* Obține o conexiune
lnConn = loPool.GetConnection()

IF lnConn > 0
    * Execută query
    SQLEXEC(lnConn, "SELECT * FROM Firme", "curFirme")
    
    * Procesează rezultate
    SELECT curFirme
    BROWSE
    
    * Eliberează conexiune în pool
    loPool.ReleaseConnection(lnConn)
ENDIF
```

### Utilizare în Funcții/Proceduri

```foxpro
PROCEDURE ProcessInvoices()
    LOCAL loPool, lnConn
    
    * Obține pool
    loPool = GetGlobalConnectionPool()
    lnConn = loPool.GetConnection()
    
    IF lnConn > 0
        TRY
            * Transacție
            SQLEXEC(lnConn, "BEGIN TRANSACTION")
            
            * Operații DB
            SQLEXEC(lnConn, "INSERT INTO Facturi ...", "curResult")
            SQLEXEC(lnConn, "UPDATE Clienti ...", "curResult")
            
            * Commit
            SQLEXEC(lnConn, "COMMIT TRANSACTION")
            
        CATCH TO loEx
            * Rollback la eroare
            SQLEXEC(lnConn, "ROLLBACK TRANSACTION")
            ? "Eroare:", loEx.Message
            
        FINALLY
            * IMPORTANT: Eliberează conexiunea
            loPool.ReleaseConnection(lnConn)
        ENDTRY
    ENDIF
ENDPROC
```

### Verificare Status Pool

```foxpro
loPool = GetGlobalConnectionPool()
? loPool.GetPoolStatus()

* Output:
* ===== POOL STATUS =====
* Size: 5
* In Use: 2
* Available: 3
* Created: 5
* =======================
```

### Debug Mode

```foxpro
loPool = GetGlobalConnectionPool()
loPool.lDebugMode = .T.

* Toate operațiile vor fi loggate în:
* ConnectionPool_YYYYMMDD.log
```

---

## 🌐 ANAF Client - Usage

### Obținere Access Token

```foxpro
* Obține client-ul global
loANAF = GetGlobalANAFClient(.T.)  && .T. = test environment

* Obține token (automat cached pentru 1 oră)
lcToken = loANAF.GetAccessToken()

IF !EMPTY(lcToken)
    ? "✓ Token obținut:", LEFT(lcToken, 20) + "..."
ELSE
    ? "✗ Eroare obținere token"
ENDIF
```

### Listă Mesaje ANAF

```foxpro
loANAF = GetGlobalANAFClient(.T.)

* Obține mesaje ultimele 7 zile
lcResponse = loANAF.GetMessagesList(7)

IF !ISNULL(lcResponse)
    ? "✓ Listă mesaje obținută"
    ? lcResponse
    
    * Parse JSON response
    loJson = CREATEOBJECT("Chilkat_9_5_0.JsonObject")
    loJson.Load(lcResponse)
    
    * Procesează mesaje
    * ...
ELSE
    ? "✗ Eroare obținere mesaje"
ENDIF
```

### Upload Factură

```foxpro
loANAF = GetGlobalANAFClient(.T.)

* Citește XML factură
lcXmlContent = FILETOSTR("factura_123.xml")

* CIF firmă
lcCIF = "RO12345678"

* Upload la ANAF
lcResponse = loANAF.UploadInvoice(lcXmlContent, lcCIF)

IF !ISNULL(lcResponse)
    ? "✓ Factură uploadată"
    ? lcResponse
    
    * Parse response pentru upload_index
    loJson = CREATEOBJECT("Chilkat_9_5_0.JsonObject")
    loJson.Load(lcResponse)
    lcUploadIndex = loJson.StringOf("upload_index")
    ? "Upload Index:", lcUploadIndex
ELSE
    ? "✗ Eroare upload"
ENDIF
```

### Download Mesaj

```foxpro
loANAF = GetGlobalANAFClient(.T.)

* Download mesaj specific
lcMessageID = "1234567890"
lcResponse = loANAF.DownloadMessage(lcMessageID)

IF !ISNULL(lcResponse)
    ? "✓ Mesaj descărcat"
    
    * Salvează ZIP
    STRTOFILE(lcResponse, "mesaj_" + lcMessageID + ".zip")
ELSE
    ? "✗ Eroare download"
ENDIF
```

### Switch între Test și Production

```foxpro
* Test environment
loANAF_Test = CREATEOBJECT("ANAFClient", .T.)

* Production environment
loANAF_Prod = CREATEOBJECT("ANAFClient", .F.)
```

### Debug Mode

```foxpro
loANAF = GetGlobalANAFClient(.T.)
loANAF.lDebugMode = .T.

* Toate operațiile vor fi loggate în:
* ANAF_Client_YYYYMMDD.log
```

---

## 🧪 Rulare Teste

### Test Connection Pool

```foxpro
DO Modernization\Tests\Test_ConnectionPool.prg

* Sau specific:
SET PROCEDURE TO Modernization\Tests\Test_ConnectionPool.prg
RunAllTests()
```

### Test ANAF Client

```foxpro
DO Modernization\Tests\Test_ANAF_Client.prg

* Sau specific:
SET PROCEDURE TO Modernization\Tests\Test_ANAF_Client.prg
RunAllTests()
```

---

## 📝 Exemple Complete End-to-End

### Exemplu 1: Procesare Facturi cu Pool

```foxpro
* Inițializare
DO Modernization\Init_Modernization.prg

* Procesare facturi
PROCEDURE ProcessDailyInvoices()
    LOCAL loPool, lnConn, lcSQL, lnResult
    
    loPool = GetGlobalConnectionPool()
    lnConn = loPool.GetConnection()
    
    IF lnConn > 0
        TRY
            * Query pentru facturi de procesat
            TEXT TO lcSQL NOSHOW
            SELECT TOP 100 
                IdFactura, NumarFactura, Data, IdClient, Total
            FROM Facturi
            WHERE StatusANAF IS NULL
            ORDER BY Data DESC
            ENDTEXT
            
            lnResult = SQLEXEC(lnConn, lcSQL, "curFacturi")
            
            IF lnResult > 0
                SELECT curFacturi
                SCAN
                    * Procesează fiecare factură
                    ? "Procesare factură:", curFacturi.NumarFactura
                    
                    * Aici: generare XML, upload ANAF, etc.
                    * ...
                ENDSCAN
                
                USE IN SELECT("curFacturi")
                ? "✓ Procesate", RECCOUNT("curFacturi"), "facturi"
            ENDIF
            
        CATCH TO loEx
            ? "✗ Eroare:", loEx.Message
            
        FINALLY
            loPool.ReleaseConnection(lnConn)
        ENDTRY
    ENDIF
ENDPROC

ProcessDailyInvoices()
```

### Exemplu 2: Upload Factură la ANAF

```foxpro
* Inițializare
DO Modernization\Init_Modernization.prg

PROCEDURE UploadInvoiceToANAF(tnIdFactura)
    LOCAL loPool, loANAF, lnConn, lcXML, lcCIF, lcResponse
    
    * Obține pool și ANAF client
    loPool = GetGlobalConnectionPool()
    loANAF = GetGlobalANAFClient(.T.)  && Test environment
    
    lnConn = loPool.GetConnection()
    
    IF lnConn > 0
        TRY
            * 1. Citește date factură din DB
            LOCAL lcSQL
            TEXT TO lcSQL NOSHOW TEXTMERGE
            SELECT 
                f.NumarFactura, f.Data, f.Total,
                c.CUI, c.Denumire
            FROM Facturi f
            INNER JOIN Clienti c ON f.IdClient = c.IdClient
            WHERE f.IdFactura = <<tnIdFactura>>
            ENDTEXT
            
            IF SQLEXEC(lnConn, lcSQL, "curFactura") > 0
                SELECT curFactura
                IF !EOF()
                    * 2. Generează XML (funcție existentă)
                    lcXML = Create_XML_UBL_File_For_eFactura(;
                        0, ;  && tnRectificativa
                        curFactura.NumarFactura, ;
                        "C:\eFactura\", ;
                        .F., ;  && tlIsExport
                        "", ;
                        tnIdFactura, ;
                        .F.)  && tlIsAutoFactura
                    
                    * 3. Upload la ANAF
                    lcCIF = curFactura.CUI
                    lcResponse = loANAF.UploadInvoice(lcXML, lcCIF)
                    
                    IF !ISNULL(lcResponse)
                        * 4. Parse response
                        LOCAL loJson, lcUploadIndex
                        loJson = CREATEOBJECT("Chilkat_9_5_0.JsonObject")
                        loJson.Load(lcResponse)
                        lcUploadIndex = loJson.StringOf("upload_index")
                        
                        * 5. Update DB cu upload_index
                        TEXT TO lcSQL NOSHOW TEXTMERGE
                        UPDATE Facturi
                        SET StatusANAF = 'Uploaded',
                            UploadIndex = '<<lcUploadIndex>>',
                            DataUpload = GETDATE()
                        WHERE IdFactura = <<tnIdFactura>>
                        ENDTEXT
                        
                        SQLEXEC(lnConn, lcSQL)
                        
                        ? "✓ Factură uploadată cu succes"
                        ? "  Upload Index:", lcUploadIndex
                    ELSE
                        ? "✗ Eroare upload ANAF"
                    ENDIF
                ENDIF
                
                USE IN SELECT("curFactura")
            ENDIF
            
        CATCH TO loEx
            ? "✗ Eroare:", loEx.Message
            
        FINALLY
            loPool.ReleaseConnection(lnConn)
        ENDTRY
    ENDIF
ENDPROC

* Test
UploadInvoiceToANAF(12345)
```

---

## 🔧 Troubleshooting

### Connection Pool Issues

**Problem**: "Pool epuizat"
```foxpro
* Soluție: Verifică că toate conexiunile sunt eliberate
loPool = GetGlobalConnectionPool()
? loPool.GetPoolStatus()

* Dacă toate sunt "In Use", caută ReleaseConnection() lipsă
```

**Problem**: "Conexiune invalidă"
```foxpro
* Pool-ul va recrea automat conexiunea
* Verifică log-ul pentru detalii:
TYPE ConnectionPool_20241223.log
```

### ANAF Client Issues

**Problem**: "Token gol"
```foxpro
* Verifică credențiale
? ICAS.oSettings.EFactura_ClientID
? ICAS.oSettings.eFactura_SecretID

* Verifică decriptare
lcClientID = Chilkat_Crypt(ICAS.oSettings.EFactura_ClientID, 'D')
? "Client ID:", lcClientID
```

**Problem**: "TLS error"
```foxpro
* Verifică versiune Chilkat
loHttp = CREATEOBJECT("Chilkat_9_5_0.Http")
? "TLS Version:", loHttp.TlsVersion  && Ar trebui "1.2"
```

---

## 📊 Performance Tips

1. **Refolosește pool-ul global** - Nu crea pool-uri noi
2. **Eliberează întotdeauna conexiunile** - Folosește TRY/FINALLY
3. **Batch operations** - Grupează query-urile
4. **Monitor log-urile** - Activează debug mode în dezvoltare

---

## 🎯 Next Steps

După implementarea acestor componente:

1. **Săptămâna 1-2**: Integrează Connection Pool în cod existent
2. **Săptămâna 3-4**: Integrează ANAF Client în workflow-ul de facturare
3. **Săptămâna 5-6**: Implementează WebView2 Dashboard (vezi documentația)

---

**Documentație completă:** `/Modernization/Documentation/`  
**Support:** Vezi log-urile pentru debugging detaliat
