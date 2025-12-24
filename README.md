# eFactura_WORK
RO-eFactura snippets - Visual FoxPro 9.0 Application

## 📋 Despre Proiect

Aplicație Visual FoxPro 9.0 pentru gestionarea facturilor electronice conform standardelor ANAF România, inclusiv generare XML UBL, semnare digitală, și integrare cu API-ul e-Factura.

## 🚀 Modernizare VFP 9.0

**📚 [Documentație Completă de Modernizare](Modernization/README.md)**

Documentație comprehensivă pentru modernizarea aplicației VFP 9.0:
- ✅ **UI Modern** - WebView2, HTML5, Dashboard interactiv
- ✅ **Database** - ODBC Driver 18, Connection Pooling, TLS 1.2+
- ✅ **API Integration** - wwDotNetBridge, Chilkat, OAuth2
- ✅ **ANAF e-Factura** - XML UBL, Semnare digitală, Upload/Download
- ✅ **Reconciliere Bancară** - CAMT.053, MT940, Auto-matching
- ✅ **Securitate** - TLS 1.2+, UAC, GDPR, Audit Trail

**[→ Citește Ghidul Complet de Modernizare](Modernization/README.md)**

## 📂 Structură Proiect

- `/SAFT_Enhanced/` - Componente SAFT (Standard Audit File for Tax)
- `/Modernization/` - **Documentație și exemple modernizare**
  - `/Documentation/` - Ghiduri complete (9 documente)
  - `/Examples/` - Exemple cod practice
- `eFactura_Work.PRG` - Program principal
- `eFactura_Copilot_De_Optimizat.prg` - Generare XML UBL
- `/CACHE_ANAF/` - Cache local pentru comunicări ANAF

## 🔧 Cerințe Sistem

### Minim
- Windows 10/11 (64-bit)
- Visual FoxPro 9.0 SP2
- .NET Framework 4.7.2+
- SQL Server sau MySQL

### Pentru Modernizare
- Microsoft ODBC Driver 18 for SQL Server
- WebView2 Runtime
- wwDotNetBridge
- Certificate digitale calificate (pentru semnare)

## 📖 Quick Start

1. **Clone repository**
   ```bash
   git clone https://github.com/vicosx12/eFactura_WORK.git
   ```

2. **Consultă documentația de modernizare**
   - [Ghid de Implementare](Modernization/Documentation/Implementation_Guide.md)
   - [Configurare ODBC](Modernization/Documentation/ODBC_Setup.md)
   - [Integrare ANAF](Modernization/Documentation/ANAF_Integration.md)

3. **Rulează teste inițiale**
   ```foxpro
   * Test componente modernizare
   DO Technical_Audit
   DO Test_ODBC_Connections
   ```

## 📜 Licență

Vezi [LICENSE](LICENSE) pentru detalii.

## 🤝 Contribuții

Contribuțiile sunt binevenite! Pentru sugestii de îmbunătățire, deschide un issue sau pull request.

---

**Status:** ✅ Documentație completă | ⏳ Implementare în progres
