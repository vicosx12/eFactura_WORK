# Checklist Securitate și Conformitate - Modernizare VFP 9.0

## Introducere

Acest document conține checklist-ul complet de securitate și conformitate pentru modernizarea aplicației Visual FoxPro 9.0, inclusiv cerințe TLS 1.2+, UAC, GDPR și best practices pentru securitatea datelor.

## 1. Securitate Comunicații

### TLS 1.2+ Implementation

#### ✅ Componente HTTP/HTTPS
- [ ] Upgrade la Microsoft ODBC Driver 18 (suport TLS 1.2/1.3)
- [ ] Configurare Chilkat ActiveX cu `RequireTlsVersion = "1.2"`
- [ ] Configurare HttpClient .NET cu SecurityProtocol minimă TLS 1.2
- [ ] Dezactivare protocoale nesigure (SSL 2.0, SSL 3.0, TLS 1.0, TLS 1.1)

#### Exemplu configurare:
```foxpro
* Chilkat HTTP cu TLS 1.2+
loHttp = CREATEOBJECT("Chilkat.Http")
loHttp.RequireTlsVersion = "1.2"  && Forțează TLS 1.2 sau superior

* Verificare versiune TLS suportată
lcTlsVersion = loHttp.TlsVersion
? "TLS Version: " + lcTlsVersion
```

```csharp
// .NET HttpClient cu TLS 1.2+
ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12 | SecurityProtocolType.Tls13;
```

#### ✅ Registry Settings (Windows)
- [ ] Dezactivare SSL 2.0: `HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client\Enabled = 0`
- [ ] Dezactivare SSL 3.0: `HKLM\...\SSL 3.0\Client\Enabled = 0`
- [ ] Dezactivare TLS 1.0: `HKLM\...\TLS 1.0\Client\Enabled = 0`
- [ ] Dezactivare TLS 1.1: `HKLM\...\TLS 1.1\Client\Enabled = 0`
- [ ] Activare TLS 1.2: `HKLM\...\TLS 1.2\Client\Enabled = 1`
- [ ] Activare TLS 1.3: `HKLM\...\TLS 1.3\Client\Enabled = 1`

### Certificate Digitale

#### ✅ Management Certificate
- [ ] Utilizare certificate digitale calificate pentru semnare
- [ ] Validare certificate înainte de utilizare
- [ ] Verificare dată expirare certificate
- [ ] Stocare securizată certificate (protejate cu parolă)
- [ ] Backup certificate în locație securizată
- [ ] Rotație periodică certificate (conform politica CA)

#### ✅ Validare Certificate Server
- [ ] Verificare chain-ul de certificate
- [ ] Validare CN (Common Name) vs. hostname
- [ ] Verificare revocate (CRL/OCSP)
- [ ] Pin certificate pentru API-uri critice (certificate pinning)

## 2. User Access Control (UAC) - Windows 10/11

### Compatibilitate UAC

#### ✅ Manifest Application
- [ ] Creare manifest XML pentru aplicație VFP
- [ ] Setare `requestedExecutionLevel` = "asInvoker" (preferabil)
- [ ] Evitare `requireAdministrator` dacă nu e necesar
- [ ] Testare cu utilizatori non-admin

#### Exemplu manifest (app.exe.manifest):
```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
  <assemblyIdentity
    version="1.0.0.0"
    processorArchitecture="x86"
    name="eFactura.Application"
    type="win32"/>
  <trustInfo xmlns="urn:schemas-microsoft-com:asm.v2">
    <security>
      <requestedPrivileges>
        <requestedExecutionLevel level="asInvoker" uiAccess="false"/>
      </requestedPrivileges>
    </security>
  </trustInfo>
  <compatibility xmlns="urn:schemas-microsoft-com:compatibility.v1">
    <application>
      <!-- Windows 10/11 -->
      <supportedOS Id="{8e0f7a12-bfb3-4fe8-b9a5-48fd50a15a9a}"/>
    </application>
  </compatibility>
</assembly>
```

#### ✅ Locații Fișiere
- [ ] Utilizare `%APPDATA%` pentru date utilizator
- [ ] Utilizare `%PROGRAMDATA%` pentru date partajate
- [ ] Evitare scriere în `Program Files` după instalare
- [ ] Permisiuni corecte pentru directoare create

```foxpro
* Funcție helper pentru obținere cale AppData
FUNCTION GetAppDataPath()
    LOCAL lcAppData
    
    DECLARE INTEGER SHGetFolderPath IN shell32.dll ;
        INTEGER hwndOwner, INTEGER nFolder, ;
        INTEGER hToken, INTEGER dwFlags, ;
        STRING @pszPath
    
    lcAppData = SPACE(260)
    SHGetFolderPath(0, 26, 0, 0, @lcAppData)  && CSIDL_APPDATA = 26
    
    RETURN RTRIM(lcAppData, CHR(0))
ENDFUNC

* Utilizare
lcConfigPath = ADDBS(GetAppDataPath()) + "eFactura\Config\"
IF !DIRECTORY(lcConfigPath)
    MKDIR (lcConfigPath)
ENDIF
```

### Virtualizare Fișiere și Registry

#### ✅ Evitare Virtualizare
- [ ] Nu scrieți în `HKEY_LOCAL_MACHINE` la runtime
- [ ] Utilizați `HKEY_CURRENT_USER` pentru setări utilizator
- [ ] Testare cu UAC activat
- [ ] Verificare că virtualizarea nu afectează funcționalitatea

## 3. GDPR și Protecția Datelor

### Date Personale

#### ✅ Identificare Date
- [ ] Inventar date personale procesate (nume, CNP, adrese, etc.)
- [ ] Clasificare date după sensibilitate
- [ ] Documentare scopuri procesare
- [ ] Stabilire bază legală procesare

#### ✅ Minimizare Date
- [ ] Colectare doar date necesare
- [ ] Eliminare date redundante
- [ ] Anonimizare/pseudonimizare unde posibil
- [ ] Definire perioade retenție

### Drepturi Subiecți

#### ✅ Implementare Drepturi
- [ ] Drept de acces - rapoarte date personale
- [ ] Drept la rectificare - corectare date
- [ ] Drept la ștergere - "dreptul de a fi uitat"
- [ ] Drept la portabilitate - export date structurate
- [ ] Drept de opoziție - opt-out procesare

```foxpro
*====================================================================
* Procedură: GDPR_Export_Personal_Data
* Scop: Export date personale pentru subiect (portabilitate GDPR)
*====================================================================
PROCEDURE GDPR_Export_Personal_Data(tcCNP)
    LOCAL lcJson, lcFileName
    
    * Colectare date personale
    SELECT ;
        Nume, ;
        Prenume, ;
        CNP, ;
        Email, ;
        Telefon, ;
        Adresa ;
    FROM Clienti ;
    WHERE CNP = tcCNP ;
    INTO CURSOR curPersonalData
    
    * Export la JSON
    lcJson = CursorToJSON("curPersonalData")
    
    * Salvare fișier
    lcFileName = "GDPR_Export_" + tcCNP + "_" + DTOS(DATE()) + ".json"
    STRTOFILE(lcJson, lcFileName)
    
    ? "Date exportate: " + lcFileName
    
    USE IN SELECT("curPersonalData")
ENDPROC

*====================================================================
* Procedură: GDPR_Delete_Personal_Data
* Scop: Ștergere date personale (dreptul de a fi uitat)
*====================================================================
PROCEDURE GDPR_Delete_Personal_Data(tcCNP, tlConfirmed)
    IF !tlConfirmed
        IF MESSAGEBOX("Confirmați ștergerea definitivă a datelor personale?", 36, "Confirmare GDPR") != 6
            RETURN .F.
        ENDIF
    ENDIF
    
    * Audit log
    INSERT INTO GDPR_AuditLog (CNP, Action, ActionDate, User) ;
        VALUES (tcCNP, "DELETE_PERSONAL_DATA", DATETIME(), SYS(0))
    
    * Anonimizare în loc de ștergere (păstrare istoricul tranzacțiilor)
    UPDATE Clienti ;
        SET Nume = "DELETED_" + SYS(2015), ;
            Prenume = "DELETED", ;
            CNP = "", ;
            Email = "", ;
            Telefon = "", ;
            Adresa = "DELETED", ;
            GDPR_Deleted = .T., ;
            GDPR_DeleteDate = DATETIME() ;
        WHERE CNP = tcCNP
    
    ? "Date personale anonimizate pentru CNP: " + tcCNP
    RETURN .T.
ENDPROC
```

### Criptare Date

#### ✅ Date în Tranzit
- [ ] TLS 1.2+ pentru toate comunicațiile externe
- [ ] VPN pentru acces remote la baze de date
- [ ] HTTPS pentru toate API-urile
- [ ] SSH/SFTP pentru transfer fișiere

#### ✅ Date în Repaus (At Rest)
- [ ] Criptare bază de date (TDE - Transparent Data Encryption)
- [ ] Criptare fișiere sensibile (certificate, configurări)
- [ ] Criptare backup-uri
- [ ] Protecție parole (hash + salt, bcrypt/PBKDF2)

```foxpro
*====================================================================
* Funcție: EncryptSensitiveData
* Scop: Criptare date sensibile cu AES
*====================================================================
FUNCTION EncryptSensitiveData(tcPlainText, tcKey)
    LOCAL loBridge, loAES, loEncrypted, lcCipherText
    
    TRY
        loBridge = CREATEOBJECT("wwDotNetBridge", "V4")
        
        * Utilizare AES din .NET
        loAES = loBridge.CreateInstance("System.Security.Cryptography.AesManaged")
        
        * Configurare AES
        loBridge.SetProperty(loAES, "KeySize", 256)
        loBridge.SetProperty(loAES, "BlockSize", 128)
        
        * Setare cheie (hash SHA256 al cheii)
        loSHA256 = loBridge.CreateInstance("System.Security.Cryptography.SHA256Managed")
        loKeyBytes = loBridge.InvokeMethod(loSHA256, "ComputeHash", ;
            loBridge.CreateInstance("System.Text.Encoding").UTF8.GetBytes(tcKey))
        loBridge.SetProperty(loAES, "Key", loKeyBytes)
        
        * Generare IV random
        loBridge.InvokeMethod(loAES, "GenerateIV")
        
        * Criptare
        loEncryptor = loBridge.InvokeMethod(loAES, "CreateEncryptor")
        loPlainBytes = loBridge.CreateInstance("System.Text.Encoding").UTF8.GetBytes(tcPlainText)
        
        loEncryptedBytes = loBridge.InvokeMethod(loEncryptor, "TransformFinalBlock", ;
            loPlainBytes, 0, loBridge.GetProperty(loPlainBytes, "Length"))
        
        * Convert la Base64
        lcCipherText = loBridge.InvokeStaticMethod("System.Convert", ;
            "ToBase64String", loEncryptedBytes)
        
        RETURN lcCipherText
        
    CATCH TO loException
        ? "Eroare criptare: " + loException.Message
        RETURN .NULL.
    ENDTRY
ENDFUNC
```

### Audit și Logging

#### ✅ Audit Trail
- [ ] Log acces date personale
- [ ] Log modificări date sensibile
- [ ] Log operațiuni critice (export, ștergere)
- [ ] Păstrare loguri minim 2 ani
- [ ] Protecție loguri (read-only, criptate)

```foxpro
*====================================================================
* Procedură: AuditLog
* Scop: Înregistrare evenimente pentru audit
*====================================================================
PROCEDURE AuditLog(tcAction, tcDetails, tcUserId)
    LOCAL lcUser, lcComputer, lcIP
    
    lcUser = IIF(EMPTY(tcUserId), SYS(0), tcUserId)
    lcComputer = SYS(0)
    
    * Obținere IP (simplificat)
    lcIP = GetLocalIP()
    
    INSERT INTO AuditLog (;
        ActionDate, ;
        Action, ;
        Details, ;
        UserId, ;
        Computer, ;
        IPAddress;
    ) VALUES (;
        DATETIME(), ;
        tcAction, ;
        tcDetails, ;
        lcUser, ;
        lcComputer, ;
        lcIP;
    )
    
    * Log și în fișier text pentru backup
    lcLogFile = ADDBS(GetAppDataPath()) + "eFactura\Logs\audit_" + DTOS(DATE()) + ".log"
    lcLogEntry = TTOC(DATETIME()) + " | " + tcAction + " | " + tcDetails + " | " + lcUser + CHR(13)+CHR(10)
    STRTOFILE(lcLogEntry, lcLogFile, .T.)  && .T. = append
ENDPROC
```

## 4. Autentificare și Autorizare

### Autentificare Utilizatori

#### ✅ Politici Parole
- [ ] Minim 8 caractere (recomandat 12+)
- [ ] Combinație litere mari/mici, cifre, caractere speciale
- [ ] Expirare parole (90-180 zile)
- [ ] Istoric parole (nu reutilizare ultimele 5)
- [ ] Blocare după 5 încercări eșuate
- [ ] Timeout sesiune după inactivitate (15-30 min)

```foxpro
*====================================================================
* Funcție: ValidatePasswordComplexity
*====================================================================
FUNCTION ValidatePasswordComplexity(tcPassword)
    LOCAL llHasUpper, llHasLower, llHasDigit, llHasSpecial
    LOCAL i, lcChar
    
    IF LEN(tcPassword) < 12
        MESSAGEBOX("Parola trebuie să aibă minim 12 caractere", 48, "Parolă nesigură")
        RETURN .F.
    ENDIF
    
    llHasUpper = .F.
    llHasLower = .F.
    llHasDigit = .F.
    llHasSpecial = .F.
    
    FOR i = 1 TO LEN(tcPassword)
        lcChar = SUBSTR(tcPassword, i, 1)
        
        IF ISALPHA(lcChar) AND ISUPPER(lcChar)
            llHasUpper = .T.
        ENDIF
        
        IF ISALPHA(lcChar) AND ISLOWER(lcChar)
            llHasLower = .T.
        ENDIF
        
        IF ISDIGIT(lcChar)
            llHasDigit = .T.
        ENDIF
        
        IF INLIST(lcChar, "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "-", "_", "=", "+")
            llHasSpecial = .T.
        ENDIF
    ENDFOR
    
    IF !llHasUpper OR !llHasLower OR !llHasDigit OR !llHasSpecial
        MESSAGEBOX("Parola trebuie să conțină: litere mari, litere mici, cifre și caractere speciale", 48, "Parolă nesigură")
        RETURN .F.
    ENDIF
    
    RETURN .T.
ENDFUNC
```

### OAuth2 pentru API-uri Externe

#### ✅ Implementare OAuth2
- [ ] Utilizare librării .NET pentru OAuth2
- [ ] Stocare securizată token-uri (criptate)
- [ ] Refresh automat token-uri expirate
- [ ] Revocate token-uri la logout
- [ ] Utilizare PKCE pentru aplicații publice

### Management Secrete

#### ✅ Stocare Securizată
- [ ] Nu stocare parole plain text în cod
- [ ] Nu stocare parole în fișiere configurare necriptate
- [ ] Utilizare Azure Key Vault / HashiCorp Vault pentru producție
- [ ] Criptare connection string-uri
- [ ] Segregare secrete per mediu (dev/test/prod)

```foxpro
*====================================================================
* Funcție: GetSecureConfig
* Scop: Obținere configurare securizată (ex: API keys)
*====================================================================
FUNCTION GetSecureConfig(tcKeyName)
    LOCAL lcConfigFile, lcEncryptedValue, lcDecryptedValue
    
    * Citire din fișier criptat
    lcConfigFile = ADDBS(GetAppDataPath()) + "eFactura\Config\secure.dat"
    
    IF !FILE(lcConfigFile)
        MESSAGEBOX("Fișier configurare lipsă", 16, "Eroare")
        RETURN ""
    ENDIF
    
    * Decriptare (implementați funcția de decriptare)
    lcEncryptedValue = ReadConfigValue(lcConfigFile, tcKeyName)
    lcDecryptedValue = DecryptSensitiveData(lcEncryptedValue, GetMasterKey())
    
    RETURN lcDecryptedValue
ENDFUNC
```

## 5. Securitate Aplicație

### Validare Input

#### ✅ Prevenire SQL Injection
- [ ] Utilizare parametrizate queries (SQLEXEC cu parametri)
- [ ] Validare și sanitizare toate input-urile utilizator
- [ ] Evitare concatenare SQL dinamic cu input utilizator
- [ ] Whitelist pentru caractere permise

```foxpro
*====================================================================
* Exemplu: Query Parametrizat (SIGUR)
*====================================================================
FUNCTION GetClientByCUI_Safe(tcCUI)
    LOCAL lnResult, lcSQL
    
    * SIGUR - cu parametri
    TEXT TO lcSQL NOSHOW
    SELECT * FROM Clienti WHERE CUI = ?m.tcCUI
    ENDTEXT
    
    lnResult = SQLEXEC(gnHandle, lcSQL, "curClient")
    
    RETURN (lnResult > 0)
ENDFUNC

*====================================================================
* Anti-pattern: NESIGUR (SQL Injection)
*====================================================================
FUNCTION GetClientByCUI_Unsafe(tcCUI)
    * NESIGUR - concatenare directă (NU FOLOSIȚI!)
    lcSQL = "SELECT * FROM Clienti WHERE CUI = '" + tcCUI + "'"
    * Dacă tcCUI = "'; DROP TABLE Clienti; --" => DEZASTRU!
ENDFUNC
```

#### ✅ Prevenire XSS (pentru WebView2)
- [ ] Sanitizare HTML output
- [ ] Escape caractere speciale HTML
- [ ] Content Security Policy
- [ ] Validare input înainte de afișare în browser

### Actualizări și Patching

#### ✅ Mentenanță Securitate
- [ ] Plan actualizări regulate componente
- [ ] Monitorizare vulnerabilități (CVE database)
- [ ] Testare actualizări în mediu non-producție
- [ ] Backup înainte de actualizări majore
- [ ] Rollback plan pentru actualizări eșuate

## 6. Backup și Disaster Recovery

### Backup

#### ✅ Strategie Backup
- [ ] Backup zilnic bază de date
- [ ] Backup săptămânal complet sistem
- [ ] Backup lunar arhivat (long-term)
- [ ] Testare restore periodic (lunar)
- [ ] Stocare backup off-site sau cloud
- [ ] Criptare backup-uri
- [ ] Versionare backup-uri (păstrare ultimele 30 zile)

### Disaster Recovery

#### ✅ Plan DR
- [ ] Documentare proceduri recovery
- [ ] RTO (Recovery Time Objective) < 4 ore
- [ ] RPO (Recovery Point Objective) < 24 ore
- [ ] Testare plan DR anual
- [ ] Responsabilități definite
- [ ] Contact list actualizată

## 7. Monitorizare și Alerting

### Monitorizare Securitate

#### ✅ Monitorizare Continuă
- [ ] Log accese eșuate
- [ ] Alert la activitate suspicioasă
- [ ] Monitorizare utilizare resurse
- [ ] Detectare anomalii pattern-uri acces
- [ ] Review periodic loguri securitate

### Incident Response

#### ✅ Plan Răspuns Incidente
- [ ] Proceduri raportare incidente
- [ ] Echipă răspuns incidente
- [ ] Comunicare cu părțile afectate
- [ ] Post-mortem și lessons learned
- [ ] Actualizare măsuri securitate

## 8. Conformitate și Certificare

### Standarde

#### ✅ Conformitate Standarde
- [ ] ISO 27001 (Security Management) - recomandat
- [ ] ISO 27002 (Security Controls) - recomandat
- [ ] PCI DSS (dacă procesați carduri) - obligatoriu
- [ ] GDPR (protecție date personale) - obligatoriu

### Documentație

#### ✅ Documentație Obligatorie
- [ ] Politică securitate informații
- [ ] Proceduri operaționale securitate
- [ ] Plan management incidente
- [ ] Plan continuitate business
- [ ] Evidență processing activități (GDPR)
- [ ] Privacy policy
- [ ] Terms and conditions

## Checklist Final

### Pre-Deployment
- [ ] Audit securitate complet
- [ ] Penetration testing
- [ ] Code review security-focused
- [ ] Validare conformitate GDPR
- [ ] Testare cu UAC activat
- [ ] Validare TLS 1.2+ pe toate conexiunile

### Post-Deployment
- [ ] Monitorizare 24/7 prima săptămână
- [ ] Review loguri zilnic prima lună
- [ ] Feedback utilizatori re: securitate
- [ ] Ajustare politici pe bază feedback
- [ ] Documentare lessons learned

## Resurse

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [GDPR Official Text](https://gdpr-info.eu/)
- [Microsoft Security Best Practices](https://docs.microsoft.com/en-us/security/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)

## Contact

Pentru consultanță securitate, contactați departamentul IT Security sau consultați documentația generală de modernizare.
