# Informații Necesare pentru Începerea Implementării

## 📋 Checklist Pre-Implementare

Pentru a începe implementarea modernizării, am nevoie de următoarele informații despre sistemul și infrastructura curentă:

---

## 1. 🏢 Informații despre Companie și Sistem

### Date Firmă
- [ ] **CUI/CIF** complet (pentru integrare ANAF)
- [ ] **Denumire completă** societate
- [ ] **Adresă completă** (pentru generare XML facturi)
- [ ] **Date contact**: Email, telefon pentru notificări
- [ ] **Tip activitate**: Cod CAEN principal

### Certificate Digitale
- [ ] **Există certificat digital calificat?** (Da/Nu)
  - Dacă DA: Furnizor (ex: CertSign, TransSign)?
  - Format: PFX/PKCS#12?
  - Locație stocare actuală?
  - Parolă disponibilă securizat?
- [ ] **Data expirare certificat**
- [ ] **Certificat de test disponibil** pentru sandbox ANAF?

---

## 2. 💾 Infrastructură Database Actuală

### Tip Database
- [ ] **Ce database folosiți?**
  - SQL Server (ce versiune?)
  - MySQL/MariaDB (ce versiune?)
  - DBF/FoxPro tables (local)
  - Altele (specificați)

### Connection Details
- [ ] **Server name/IP**: _____________
- [ ] **Database name**: _____________
- [ ] **Port**: _____________ (default: SQL Server 1433, MySQL 3306)
- [ ] **Autentificare**:
  - Windows Authentication
  - SQL Server Authentication (user/pass)
  - Mixed mode

### Volumetrie Date
- [ ] **Număr mediu facturi/lună**: _____________
- [ ] **Număr total facturi în DB**: _____________
- [ ] **Mărime bază de date**: _____________ GB
- [ ] **Număr utilizatori concurenți**: _____________

### Structură Tabele Critice
Am nevoie de structura tabelelor principale:
- [ ] **Tabela Facturi**: Lista coloane și tipuri
- [ ] **Tabela Clienti**: Lista coloane și tipuri
- [ ] **Tabela Plati**: Lista coloane și tipuri (dacă există)

**Exemplu format dorit:**
```sql
-- Tabela Facturi
IdFactura INT PRIMARY KEY
NumarFactura VARCHAR(20)
Data DATETIME
IdClient INT
Total DECIMAL(10,2)
TVA DECIMAL(10,2)
...
```

---

## 3. 🖥️ Mediu de Lucru

### Sisteme de Operare
- [ ] **Windows versiune** pe stațiile client: _____________ (Win 10/11?)
- [ ] **Windows versiune** pe server: _____________
- [ ] **Număr stații de lucru**: _____________

### Software Instalat
- [ ] **Visual FoxPro versiune**: 9.0 SP? (SP1, SP2?)
- [ ] **.NET Framework versiuni instalate**: _____________
- [ ] **ODBC Drivers actuali**: _____________
- [ ] **Chilkat ActiveX** - instalat? (Da/Nu)
- [ ] **wwDotNetBridge** - instalat? (Da/Nu)

### Drepturi și Permisiuni
- [ ] **Utilizatorii au drepturi administrator?** (Da/Nu)
- [ ] **UAC activat?** (Da/Nu)
- [ ] **Politici grupuri restrictive?** (Da/Nu - dacă da, detalii)
- [ ] **Antivirus/Firewall corporate**: _____________ (care?)

---

## 4. 🌐 Conectivitate și Rețea

### Internet și Firewall
- [ ] **Tip conexiune internet**: _____________ (dedicat/partajat)
- [ ] **Viteză download/upload**: _____________ Mbps
- [ ] **Firewall corporate**: Da/Nu
  - Dacă DA: Trebuie whitelisted IP-uri ANAF?
  - Port-uri blocate?
- [ ] **Proxy server**: Da/Nu
  - Dacă DA: Necesită autentificare?

### API ANAF
- [ ] **Aveți cont ANAF e-Factura?** (Da/Nu)
- [ ] **Client ID și Client Secret obținute?** (Da/Nu)
- [ ] **Mediu de test accesat cu succes?** (Da/Nu)
- [ ] **URL API production**: https://api.anaf.ro/prod/FCTEL/rest
- [ ] **URL API test**: https://api.anaf.ro/test/FCTEL/rest

---

## 5. 📦 Cod și Aplicație Curentă

### Structură Aplicație
- [ ] **Locație cod sursă principal**: _____________
- [ ] **Format**: EXE/APP compilat sau PRG-uri loose?
- [ ] **Fișiere principale** (nume):
  - Main program: _____________
  - Generat facturi: _____________ (ex: eFactura_Work.PRG)
  - Generare XML: _____________ (ex: eFactura_Copilot_De_Optimizat.prg)

### Funcționalități Critice Actuale
Marchați ce funcționează deja:
- [ ] Generare XML UBL pentru ANAF
- [ ] Validare XML cu XSD
- [ ] Semnare digitală XML
- [ ] Upload automat la ANAF
- [ ] Download răspunsuri ANAF
- [ ] Reconciliere bancară
- [ ] Raportare SAFT D406

### Probleme/Limitări Curente
Descrieți orice probleme:
- [ ] **Erori TLS/SSL** la conectare API ANAF? (Da/Nu - detalii)
- [ ] **Performance issues** la volume mari? (Da/Nu - când?)
- [ ] **Probleme UAC** la scriere fișiere? (Da/Nu - unde?)
- [ ] **Alte probleme**: _____________

---

## 6. 🎯 Prioritizare Module

**Ce module doriți implementate PRIMUL?** (ordonați 1-5):

- [ ] __ UI modern cu WebView2 (Dashboard nou)
- [ ] __ Connection Pooling database (Performanță)
- [ ] __ Integrare ANAF îmbunătățită (Upload/Download)
- [ ] __ Reconciliere bancară automată (CAMT/MT940)
- [ ] __ Securitate TLS 1.2+ și GDPR compliance

---

## 7. 🔧 Mediu de Dezvoltare

### Pentru Dezvoltare .NET
- [ ] **Visual Studio instalat?** Versiune: _____________
- [ ] **.NET SDK instalat?** Versiune: _____________
- [ ] **Acces la NuGet pentru pachete**: Da/Nu

### Pentru Testing
- [ ] **Mediu de test dedicat**: Da/Nu
  - Database test separată?
  - Stație test dedicată?
- [ ] **Date test disponibile**: Da/Nu
  - Facturi test pentru ANAF?
  - Certificate test?

### Git și Version Control
- [ ] **Folosiți Git/GitHub**: Da/Nu
- [ ] **Branch-uri protejate**: Da/Nu
- [ ] **CI/CD configurat**: Da/Nu

---

## 8. 💰 Bugete și Licențe

### Componente Comerciale
Disponibilitate pentru achiziție:
- [ ] **Chilkat ActiveX** (~$289 per developer)
- [ ] **CodeJock Toolkit** (~$599 per developer)
- [ ] **Microsoft Visual Studio** (Community gratis, Professional ~$500/an)

### Resurse Umane
- [ ] **Dezvoltatori VFP disponibili**: _____________ (număr)
- [ ] **Experiență .NET în echipă**: Da/Nu
- [ ] **Administrator sistem disponibil**: Da/Nu
- [ ] **Timp alocat proiect**: _____________ (ore/săpt)

---

## 9. 📅 Timeline și Așteptări

### Urgență
- [ ] **Deadline pentru prima versiune**: _____________
- [ ] **Motiv urgență**: 
  - Conformitate ANAF (obligatoriu de la _______)
  - Probleme securitate
  - Cerințe client
  - Altele: _____________

### Milestone-uri Dorite
- [ ] **Prima funcționalitate dorită până la**: _____________
- [ ] **Pilot cu utilizatori**: Când? _____________
- [ ] **Go-live complet**: Când? _____________

---

## 10. 📞 Contact și Suport

### Persoane Responsabile
- [ ] **Project Manager**: _____________ (email/telefon)
- [ ] **Lead Developer**: _____________ (email/telefon)
- [ ] **DBA/Admin Sistem**: _____________ (email/telefon)
- [ ] **Contact ANAF/Suport**: _____________ (dacă există)

### Disponibilitate
- [ ] **Program lucru**: _____________ (ore zi/săpt)
- [ ] **Timezone**: _____________ (Romania EET/EEST)
- [ ] **Preferred communication**: Email/Teams/Phone/Altele

---

## 📝 Pași Imediat Următori

Odată ce am aceste informații, pot să:

### Săptămâna 1 - Audit și Setup
1. **Rulare audit tehnic** pe sistemul actual
   ```foxpro
   DO Technical_Audit  && Din Implementation_Guide.md
   ```
2. **Testare conexiuni** database existente
3. **Verificare access** API ANAF (test environment)
4. **Identificare gaps** între starea actuală și cerințe

### Săptămâna 2 - Quick Win #1
**Alegem împreună primul modul** bazat pe:
- Urgență business
- Impact maxim
- Complexitate minimă
- Risc minim

**Opțiuni recomandate pentru start:**
1. **Connection Pool** (risc minim, impact imediat performanță)
2. **Retry Logic pentru API** (risc minim, robustețe mare)
3. **Dashboard WebView2** (vizibilitate mare, wow factor)

---

## 📋 Format Răspuns Dorit

Vă rog să completați informațiile de mai sus și să trimiteți:

1. **Document text** cu răspunsurile la checklist-uri
2. **Scripturi SQL** cu structura tabelelor principale
3. **Sample fisier config** (dacă există - ex: app.config, connection strings)
4. **Screenshots** cu erori curente (dacă există)

**Alternativ**, putem avea un **call de 30-60 minute** pentru a colecta aceste informații interactiv.

---

## 🚀 Ce Pregătesc Eu Între Timp

În timp ce aștept informațiile:
1. ✅ Pregătesc **template-uri** pentru fiecare modul
2. ✅ Creez **script-uri de instalare** personalizate
3. ✅ Setup **mediu de test** local (dacă pot replica)
4. ✅ Documentez **best practices** specifice setup-ului vostru

---

## ⚡ Start Rapid (Dacă Vreți să Începeți IMEDIAT)

Puteți începe chiar acum cu:

### Pas 1: Verificare Componente (5 minute)
```foxpro
* Rulați în VFP Command Window:
? VERSION()        && Verifică versiune VFP
? SYS(0)          && Machine name și user
? FULLPATH(".")   && Cale curentă

* Test database connection
lnHandle = SQLSTRINGCONNECT("DSN=YourDSN")
? "Connection:", lnHandle
IF lnHandle > 0
    ? "✓ Database OK"
    SQLDISCONNECT(lnHandle)
ELSE
    ? "✗ Database error"
    AERROR(laError)
    ? laError[2]
ENDIF
```

### Pas 2: Download Componente Necesare (10 minute)
1. **Microsoft ODBC Driver 18**: https://go.microsoft.com/fwlink/?linkid=2168524
2. **WebView2 Runtime**: https://developer.microsoft.com/microsoft-edge/webview2/
3. **wwDotNetBridge**: https://github.com/RickStrahl/wwDotnetBridge/releases

### Pas 3: Primul Test (5 minute)
```foxpro
* Test conexiune ANAF (fără autentificare - doar ping)
LOCAL loHttp
TRY
    loHttp = CREATEOBJECT("Chilkat.Http")
    IF ISNULL(loHttp)
        ? "✗ Chilkat nu este instalat"
    ELSE
        ? "✓ Chilkat disponibil"
        loHttp.RequireTlsVersion = "1.2"
        lcResp = loHttp.QuickGetStr("https://api.anaf.ro/test/FCTEL/rest/listaMesajeFactura")
        ? "Response length:", LEN(lcResp)
    ENDIF
CATCH TO loEx
    ? "Eroare:", loEx.Message
ENDTRY
```

---

**Aștept informațiile pentru a putea începe implementarea personalizată! 🚀**
