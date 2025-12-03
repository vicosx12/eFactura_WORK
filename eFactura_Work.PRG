#if .f.
	DownloadInvoiceResponse
	DownloadInvoiceResponseError
	DownloadInvoiceParseZipResponse
	GeneratePDFResponse
	GeneratePDFResponseError
	GetMessageStateCode
	GetDownloadID
	GetFirstErrorMessage
	IsInvalidXML
	IsNok
	IsOk
	IsProcessing
	UploadResponse
	GetMessageStateCode
	GetMessageStateResponse

	// InvoiceErrorMessage is the type corresponding to an Invoice message
	// error from the download zip.
	InvoiceErrorMessage struct {
		UploadIndex int64  `xml:"Index_incarcare,attr,omitempty"`
		CIFSeller   string `xml:"Cif_emitent,attr,omitempty"`
		Errors      []struct {
			ErrorMessage string `xml:"errorMessage,attr"`
		} `xml:"Error,omitempty"`

// IsError returns true if message type is ERORI FACTURA
func (m Message) IsError() bool {
	return m.Type == MessageTypeError
}

// IsSentInvoice returns true if message type is FACTURA TRIMISA
func (m Message) IsSentInvoice() bool {
	return m.Type == MessageTypeSentInvoice
}

// IsReceivedInvoice returns true if message type is FACTURA PRIMITA
func (m Message) IsReceivedInvoice() bool {
	return m.Type == MessageTypeReceivedInvoice
}

// IsBuyerMessage returns true if message type is MESAJ CUMPARATOR PRIMIT / MESAJ CUMPARATOR TRANSMIS
func (m Message) IsBuyerMessage() bool {
	return m.Type == MessageTypeBuyerMessage
}

package constants

const (
	ApiBaseURL       = "https://api.anaf.ro/"
	PublicApiBaseURL = "https://webservicesp.anaf.ro/"

	// ApiBaseSandbox points to the sandbox (testing) version of the API
	ApiBasePathSandbox = "test/"
	ApiBaseSandbox     = ApiBaseURL + ApiBasePathSandbox

	// ApiBaseProd points to the production version of the API
	ApiBasePathProd = "prod/"
	ApiBaseProd     = ApiBaseURL + ApiBasePathProd

	// ApiPublicBaseProd points to the production version of the public
	// (unprotected) API.
	PublicApiBasePathProd = "prod/"
	PublicApiBaseProd     = PublicApiBaseURL + PublicApiBasePathProd
)

const (
	apiBase                      = "FCTEL/rest/"
	apiPathUpload                = apiBase + "upload"
	apiPathMessageState          = apiBase + "stareMesaj"
	apiPathMessageList           = apiBase + "listaMesajeFactura"
	apiPathMessagePaginationList = apiBase + "listaMesajePaginatieFactura"
	apiPathDownload              = apiBase + "descarcare"

	publicApiBase         = "FCTEL/rest/"
	publicApiPathValidate = publicApiBase + "validare/%s"
	publicApiPathXMLToPDF = publicApiBase + "transformare/%s"
)	
	
	GetUploadIndex()
	IsSelfBilledInvoice()
	GetSellerCIF()
	GetBuyerCIF()
	GetCreationDate()
	ResponseBodyIsJSON()
	GetMessagesListPagination()

	parseInvoiceZip()
	parseDownloadedInvoiceXML()
	LimitExceededError
	
#endif

*!*	  ______           _____                      _
*!*	 |  ____|         / ____|                    | |
*!*	 | |__ _____  __ | |     ___  _ __  ___  ___ | | ___
*!*	 |  __/ _ \ \/ / | |    / _ \| '_ \/ __|/ _ \| |/ _ \
*!*	 | | | (_) >  <  | |___| (_) | | | \__ \ (_) | |  __/
*!*	 |_|  \___/_/\_\  \_____\___/|_| |_|___/\___/|_|\___|
 
&& ========================================================================&&
&&                                                                         &&
&&                   ______                                                &&
&&           ___    |  ____| __________                                    &&
&&         /  _ \   | |__   | /  _  \ |                                    &&
&&        |______|  | ___|  | | |_| | |                                    &&
&&        |         | |     | |     | |                                    &&
&&         \_____|  |_|     |_\_____/_|_                                   &&
&&                                                                         &&
&&                                                                         && 
&& https://mfinante.gov.ro/web/efactura/aplicatii-web-ro-efactura		   &&
&& https://mfinante.gov.ro/ro/web/efactura								   &&
&& ========================================================================&&
*
* Trimite automat e-Factura in SPV?	4 zile, 5 zile, 1 zi de la emiterea facturii fiscale
*
* Token-urile de tip OPAQUE vor putea fi folosite p�na la data de 15.04.2024. 
*	�ncep�nd de la acea data, toti utilizatorii vor folosi doar token-uri de tip JWT
*
*    <cac:PayeeParty>
*        <cac:PartyIdentification>
*            <cbc:ID>IDENTIF BENEFICIAR BT-60</cbc:ID>
*        </cac:PartyIdentification>
*        <cac:PartyName>
*            <cbc:Name>NUME BENEFICIAR BT-59</cbc:Name>
*        </cac:PartyName>
*        <cac:PartyLegalEntity>
*            <cbc:CompanyID>IDENTIF INREG FISC BENEF BT-61</cbc:CompanyID>
*        </cac:PartyLegalEntity>
*    </cac:PayeeParty>
*    
*IF pIsExecutare .AND. (EMPTY(crsEFactura.BT59) .OR. EMPTY(crsEFactura.BT60))
*	IF EMPTY(crsEFactura.BT59)
*		MESSAGEBOX("Pentru facturile de executare silita trebuie sa completati denumirea beneficiarului platii.", 64, "Date incomplete...")
*		EXIT
*	ENDIF
*	IF EMPTY(crsEFactura.BT60)
*		MESSAGEBOX("Pentru facturile de executare silita trebuie sa completati identificatorul beneficiarului platii.", 64, "Date incomplete...")
*		EXIT
*	ENDIF
*	IF EMPTY(crsEFactura.BT60) .AND. EMPTY(crsEFactura.BT61)
*		MESSAGEBOX("Daca ati completati denumirea beneficiarului platii, trebuie sa completati si identificatorul sau identificatorul legal al acestuia.", 64, "Date incomplete...")
*		THIS.PARENT.mylonlygrid1.columnbt60.SETFOCUS()
*		EXIT
*	ENDIF
*ENDIF

*	LoadIstoricEFacturiPrimiteFromIntrari()
*	LoadIstoricEFacturiTransmiseFromIesiri()

&& Limite accesari api.anaf.ro VECHI
&& - 100 Requests pe 1 minut
&& - 50 Spike arrest la 10 secunde
*
&& Limite la apelarea API eFactura
&&	=============================

&& LImita pentru toate metodele
&& - max. 1000 apeluri/minut

&& Limite specifice/ metoda
&& 1. /upload
&& - max. 1000 fisiere tip RASP (raspuns la factura)/ zi /CUI
&& - NU exista limita la upload fisiere tip factura

&& 2. /stare
&& - max 10 interogari/ un anumit mesaj/ zi
&& - NU exista limitari la numarul total de interogari/ zi/ CUI

&& 3. /lista
&& - max 1500 interogari/ zi/ CUI la lista simpla
&& - max 100.000 interogari/zi/CUI la lista cu paginatie

&& 4. /descarcare
&& - max 10 descarcari/ zi/ un anumit mesaj
&& - NU exista limitari la numarul total de descarcari /zi/ CUI

&& Obs.
&& 1. Limitele pot fi modificate. Daca primiti eroare de depasire a numarului maxim de apeluri si considerati ca ar trebui sa puteti interoga peste valorile stabilite, va rugam sa ne scrieti pe formularul de contact din SPV sau www.anaf.ro pentru revizuirea acestora.
&& 2. Ignorarea repetata a mesajelor de depasire a limitelor maxime poate duce la blocarea accesului la API pentru respectivul utilizator si, in cazurile grave, la blocarea accesului aplicatiei.
*
*
&& Documentele justificative ale facturii sau ata.amentele, pot sa fie �ncorporate �n structura de
&& date a facturii .i nu pot fi trimise separat prin sistemul RO e-Factura (acestea nu sunt obligatorii
&& din perspectiva standardului de facturare electronica). Suma dimensiunilor tuturor fi.ierelor
&& ata.ate nu trebuie sa depa.easca 3Mb.
&& Numarul maxim de documente �ncorporate care sus.in factura este limitat la 50.
&& Codurile MIME ale documentelor ata.ate permise:
&& - Aplicatie/pdf;
&& - Imagine/png;
&& - Imagine/jpeg;
&& - Text/csv;
&& - Aplicatie/vnd.openxmlformats-officedocument.spreadsheetml.sheet;
&& - Aplicatie/vnd.oasis.opendocument.spreadsheet.

#if .f.
C�mpurile obligatorii e-Factura contin datele relevante despre o factura, din punct de vedere fiscal, legal si juridic. 
Aceste date se trimit catre SPV �n formatul XML UBL.  


Iar daca lucrezi cu aplicatiile web ANAF (versiunea extinsa sau cea simplificata), 
e cu at�t mai recomandat sa �ntelegi c�mpurile obligatorii e-Factura.

Cum completezi c�mpurile obligatorii e-Factura utiliz�nd aplicatiile web ANAF
Majoritatea acestor c�mpuri obligatorii sunt evidente, dar sa le luam pe r�nd.

C�mpuri care tin de identificarea facturii
Numarul facturii (BT-1): completezi cu seria si numarul facturii.

Data emiterii facturii (BT-2): completezi cu data la care ai emis factura.

Codul tipului facturii (BT-3): alegi

380 pentru orice factura de v�nzare-cumparare
***381 pentru orice factura storno sau pentru o nota de credit
*384 pentru orice factura care corecteaza o alta factura emisa anterior cu greseli

*........................................................
389 pentru autofactura (citeste aici ce este autofactura)

Autofactura se transmite �n SPV ANAF la fel ca oricare alta factura, cu o singura diferen?a. �n c�mpul Tip de factura alegi 389 � Autofactura.
Autofactura nu primeste un numar secvential, asa cum primeste o factura orginala. 
Se emite �ntr-un singur exemplar.
Cum spuneam mai sus, rolul autofacturii este legat strict de raportarea TVA-ului. 
Nu poti folosi autofactura ca document justificativ al unei cheltuieli sau ca sa receptionezi marfa �n gestiune.

In conformitate cu art. 319 alin. 18 din Codul fiscal si Normele metodologice (redate mai jos) 
beneficiarul poate emite facturi in numele si in contul furnizorului/prestatorului, 
	daca exista un acord prealabil intre parti, 
	o procedura stabilita de acceptare a facturilor 
	si facturile sunt emise conform specificatiilor legale si inregistrate corespunzator.

In contextul utilizarii sistemului national privind factura electronica RO e-Factura, 
responsabilitatea pentru transmiterea facturii electronice catre ANAF 
revine emitentului autofacturii, 
adica clientului care a emis autofactura.

Ordonanta de urgenta nr. 120/2021
Art. 2. -(1) In sensul prezentului capitol, termenii si expresiile de mai jos au urmatoarele semnificatii:
c) emitent al facturii electronice - operatorul economic care emite factura electronica catre destinatar si o transmite in sistemul national privind factura electronica RO e-Factura;
Art. 4. -(3) Factura electronica se transmite de catre emitent in sistemul national privind factura electronica RO e-Factura.

Conform OUG 120/2021, art. 4 alin. 3) 
	factura electronica se transmite de catre emitent in sistemul national privind factura electronica RO e-Factura. 
Acesta trebuie sa transmita factura in sistemul RO e-Factura, 
marcand corespunzator ca este o autofactura, 
fie prin setarea parametrului "AUTOFACTURA=DA" in cazul transmiterii automate, 
fie prin bifarea campului de autofactura in interfata SPV.
*........................................................


751 pentru transmiterea facturilor la bonuri fiscale
Daca alegi 381 sau 384, 
�ti recomandam sa completezi si c�mpul Referinta factura anterioara, 
unde treci numarul si data facturii precedente (cea care este corectata sau stornata).

Codul monedei (BT-5): alegi din lista moneda �n care ai emis factura

C�mpuri care tin de identificarea v�nzatorului
Numele v�nzatorului (BT-27): completezi cu denumirea firmei tale

Codul tarii V�nzatorului (BT-40): completezi cu RO � Rom�nia

Localitatea V�nzatorului (BT-37): completezi localitatea unde ai sediul social. 
Atentie: daca esti din Bucuresti, aici vei trece sectorul (ex: SECTOR 1).

Adresa V�nzatorului (BT-35): completezi adresa sediului social.

C�mpuri care tin de identificarea cumparatorului
Asa cum ai completat datele despre firma ta la V�nzator, tot la fel vei completa datele despre clientul tau la Cumparator.

C�mpuri care tin de produsele sau serviciile v�ndute
Numele articolului (BT-153): completezi cu denumirea produselor sau serviciilor v�ndute

Cantitatea facturata (BT-129): completezi cu numarul produselor sau serviciilor v�ndute

Unitatea de masura (BT-130): alegi din lista unitatea de masura (cel mai frecvent, aici vei trece bucati, dar lista de unitati de masura este exhaustiva)

Pretul Net (BT-146): completezi cu pretul unitar fara TVA

Valoarea neta (BT-131): completezi cu rezultatul �nmultirii pretului unitar fara TVA cu cantitatea

Categoria de TVA (BT-151): alegi

S: daca esti platitor de TVA
O: daca esti neplatitor de TVA
E: daca esti platitor de TVA si emiti o factura pentru produse sau servicii scutite de TVA. 
	Atentie: pentru E, trebuie sa mentionezi si motivul scutirii 
	(alegi dintr-o lista predefinita de scutiri sau scrii tu un text liber)
AE: daca emiti o factura cu TVA cu taxare inversa
K: daca emiti o factura cu TVA pentru livrari intracomunitare
G: daca emiti o factura cu TVA pentru exporturi
L: taxele din Insulele Canare
M: taxele din Ceuta si Melilla

Cota de TVA (BT-152): 
	daca ai ales S, completezi cu 19% sau, daca vinzi produse la cota redusa, completezi cu 9% sau cu 5%.

Detalierea TVA
C�mpurile de aici se autocompleteaza �n aplicatia web ANAF. Nu e nevoie sa intervii �n aceasta sectiune.

Totalurile documentului
Si aici vei observa ca majoritatea c�mpurilor obligatorii e-Factura sunt deja completate. Mai trebuie doar sa treci:

Suma platita (BT-113): daca factura a fost achitata partial sau integral, aici treci suma achitata
Valoarea de rotunjire (BT-114): pentru o factura cu un total cu trei sau mai multe zecimale, aici trebuie sa treci suma rotunjita la doua zecimale
Valoarea TVA totala a facturii �n moneda de contabilizare (BT-111): 
	daca factura este �n RON, aici treci aceeasi valoare din c�mpul Valoarea totala a facturii cu TVA (BT-112); 
	daca factura este �n valuta, aici treci valoarea totala a facturii cu TVA �n RON la cursul agreat cu clientul.

#endif

******************************************************************************************
*  PROGRAM: EFACTURA
*
*  AUTHOR: Vicos, 2023
*
*  COPYRIGHT � 2023 All Rights Reserved.
*
*     vicosx12#gmail.com
*
*  EXPLICIT LICENSE:
*     ICAS ERP grants a perpetual, non-transferable, non-exclusive, 
*     royalty free, worldwide license to use and employ such materials within 
*     their business to other developers, with full derivative rights.
*
*  DISCLAIMER OF WARRANTIES. 
*     The Software is provided "AS IS" and "WITH ALL FAULTS," without warranty of any kind,
*     including without limitation the warranties of merchantability, fitness for a 
*     particular purpose and non-infringement. 
*
*  PROGRAM DESCRIPTION:
*
*  �n Monitorul Oficial nr. 977 din 27 octombrie 2023 a fost publicata Legea nr.296/2023 
*  privind unele masuri fiscal-bugetare pentru asigurarea sustenabilitatii
*  financiare a Rom�niei pe termen lung prin care s-au adus modificari referitoare la
*  facturarea electronica.
*  Aceste modificari au ca scop implementarea etapizata a Deciziei de punere �n
*  aplicare (UE) 2023/1553 a Consiliului din 25 iulie 2023 de autorizare a Rom�niei sa
*  introduca o masura speciala de derogare de la articolele 218 si 232 din Directiva
*  2006/112/CE privind sistemul comun al taxei pe valoarea adaugata. 
*  Decizia permite Rom�niei, �ncep�nd cu data de 1 ianuarie 2024, sa instituie facturarea electronica
*  obligatorie pentru toate tranzactiile efectuate �ntre persoanele impozabile stabilite pe teritoriul Rom�niei.
*
*  Procesul de implementare va fi realizat �n doua etape, astfel:
*
*  I. �n prima etapa, �n perioada 1 ianuarie 2024 - 30 iunie 2024,
*   operatorii economici - persoane impozabile stabilite �n Rom�nia, 
*  indiferent daca sunt sau nu �nregistrate �n scopuri de TVA
*  au obligatia sa raporteze �n sistemul national privind factura electronica
*  RO e-Factura toate facturile emise �n relatia B2B si �n relatia cu institutiile publice,
*  altele dec�t cele efectuate �n relatia B2G, pentru care exista obligatia utilizarii Ro eFactura
*  �ncep�nd cu data de 01 iulie 2022.
*
*  De asemenea, operatorii economici persoane impozabile nestabilite, 
*  dar �nregistrate �n scopuri de TVA �n Rom�nia au obligatia, 
*  �ncep�nd cu 1 ianuarie 2024,
*  sa raporteze �n sistemul na?ional privind factura electronica RO e-Factura toate facturile
*  emise �n relatia B2B pentru livrari de bunuri si prestari de servicii care au locul livrarii
*  sau prestarii �n Rom�nia.
*
*  Urmatoarele operatiuni sunt exceptate de la obligatia utilizarii sistemului
*  national privind factura electronica RO e-Factura:
*  - livrarile de bunuri expediate sau transportate �n afara Uniunii Europene de catre
*  furnizor sau de alta persoana �n contul sau;
*  - livrarile de bunuri expediate sau transportate �n afara Uniunii Europene de catre
*  cumparatorul care nu este stabilit �n Rom�nia sau de alta persoana �n contul sau, cu
*  exceptia bunurilor transportate de cumparatorul �nsusi si care sunt folosite la echiparea
*  ori alimentarea ambarcatiunilor si a avioanelor de agrement sau a oricarui altui mijloc
*  de transport de uz privat;
*  - livrarile intracomunitare de bunuri.
*
*  Facturarea electronica nu se aplica �n situatia prevazuta de 
*  art. 6 din OUG nr.120/2021, cu modificarile si completarile ulterioare.
*  
*  Furnizorii, persoane impozabile stabilite �n Rom�nia, pentru operatiunile
*  efectuate �n relatia B2B, persoane impozabile stabilite �n Rom�nia pentru operatiunile
*  efectuate �n relatia cu institutii publice, altele dec�t cele efectuate �n relatia B2G, 
*  si persoane impozabile nestabilite, dar �nregistrate �n scopuri de TVA �n Rom�nia, 
*  sunt obligati sa transmita facturile emise catre destinatari conform prevederilor 
*  art. 319 din Legea nr.227/2015 privind Codul fiscal, cu modificarile si completarile ulterioare, 
*  cu excepia situatiei �n care at�t furnizorul/prestatorul, c�t si destinatarul sunt �nregistrati
*  �n Registrul RO e-Factura.
*  Termenul-limita pentru transmiterea facturilor emise, pentru livrarile de
*  bunuri si prestarile de servicii care au locul livrarii sau prestarii �n Rom�nia, 
*  �n sistemul national privind factura electronica RO e-Factura 
*  este de 5 zile lucratoare de la data emiterii facturii, 
*  dar nu mai t�rziu de 5 zile lucratoare de la data-limita prevazuta pentru emiterea facturii 
*  la art.319 alin.(16) din Codul fiscal.
*  
*  Nerespectarea termenului limita pentru transmiterea facturilor �n sistemul
*  national privind factura electronica RO e-Factura constituie contraventie si se
*  sanctioneaza cu amenda de la 5.000 lei la 10.000 lei, pentru persoanele juridice
*  �ncadrate �n categoria contribuabililor mari, definiti potrivit legii, cu amenda de la 2.500
*  lei la 5.000 lei, pentru persoanele juridice �ncadrate �n categoria contribuabililor
*  mijlocii, definiti potrivit legii, si cu amenda de la 1.000 lei la 2.500 lei, pentru celelalte
*  persoane juridice, precum si pentru persoanele fizice.
*  
*  Prin exceptie, 
*  �n perioada 1 ianuarie - 31 martie 2024, 
*  nerespectarea termenului limita pentru transmiterea facturilor �n sistemul national
*  privind factura electronica RO e-Factura nu se sanctioneaza.
*  
*  II. �n a doua etapa, 
*  �ncep�nd cu data de 01.07.2024, 
*  emitentii facturilor electronice au obligatia de transmitere a acestora catre destinatari 
*   utiliz�nd sistemul national privind factura electronica RO e-Factura, 
*  cu respectarea prevederilor art. 4 alin. (1) din OUG nr.120/2021.
*  
*  �ncep�nd cu data de 1 iulie 2024
*  pentru operatiunile realizate �ntre persoane impozabile stabilite �n Rom�nia 
*  conform art. 266 alin. (2), 
*  sunt considerate facturi numai facturile care �ndeplinesc conditiile prevazute de 
*  Ordonanta de urgenta a Guvernului nr. 120/2021. 
*  Utilizarea facturii electronice face obiectul acceptarii de catre destinatar, 
*  cu exceptia facturilor care �ndeplinesc conditiile prevazute de 
*  Ordonana de urgenta a Guvernului nr. 120/2021, cu modificarile si completarile ulterioare.
*  Totodata, primirea si �nregistrarea de catre destinatari - persoane impozabile
*  stabilite �n Rom�nia conform art. 266 alin. (2) din Codul fiscal, a unei facturi emise
*  de operatori economici stabiliti �n Rom�nia, �n relatia B2B, fara a fi transmisa prin
*  sistemul national privind factura electronica RO e-Factura, 
*  constituie contraventie si se sanctioneaza cu o amenda egala 
* (cu cuantumul TVA �nscris �n factura) <= OUG15/14.12.2023 => 15% din valoarea facturii.
*  
*
*  CALLING SYNTAX:
*     Do eFactura With IdUnicFactura
*	  eFactura(IdUnicFactura)
*
*     Call from Thor Iesiri, Export, Monitorizare eFactura
*
*  INPUT PARAMETERS:
*     IdUnicFactura = ID-ul unic al facturii.
*
*  OUTPUT PARAMETERS:
*     fisier XML
*
*  DATABASES ACCESSED:
*     None
* 
*  GLOBAL PROCEDURES REQUIRED:
*     meniu, envlib
* 
*  CODING STANDARDS:
*     Version 5.2 compliant with no exceptions
*  
*   
*  SPECIAL REQUIREMENTS/DEVICES:
*     libraria Chilkat
*
*  FUTURE ENHANCEMENTS:
*     None
*
*  LANGUAGE/VERSION:
*     Visual FoxPro 09.00.0000.7423 or higher
* 
******************************************************************************************
*                             C H A N G E    L O G                              
*
*    Date     Developer               Version  Description
* ----------  ----------------------  -------  ---------------------------------
* 03/19/2023  Vilciu Constantin Vicos 1.0      Created Program
* ----------------------------------------------------------------------------------------
* 09/20/2023  Vicos 			      1.1      Adaugare parametri si imbunatatiri 
*                                              ale performantei
* ----------------------------------------------------------------------------------------
* 01/27/2024  vicos 				  1.2      TODO:
*
*												GENERARE:
*												---------
*											   - Observatii factura
*											   - Informatii suplimentare articol
*												IMPORT facturi intrare
*												---------
*                                              - "IsTvaIncasare" 
*                                              - "TAXARE INVERSA"
*                                              - Inainte de import sa verifice:
*												FURNIZOR:
*													Daca nu exista sa adauge
*												pe ANTET:
*													Tip:
														&& 1,  " ","Factura",1,380	
														&& 2,  "A","Aviz",1
														&& 3,  "T","Taxare inversa",1,380, "AE", 'VATEX-EU-AE'
														&& 4,  "G","Factura pe mai multe gestiuni",1,380
														&& 5,  "F","Factura imobilizari",1,380	
														&& 6,  "P","Fara drept de deducere partial (pro-rata)",1
														&& 7,  "I","Fara drept de deducere integral (pro-rata)",1
														&& 8,  "B","Bonuri Fiscale FARA CIF",1
														&& 9,  "C","Bonuri Fiscale CU CIF (cu valoare de factura simplificata)",1
														&& 10, "e","Exceptii utilizare AMEF",1
														&& 11, "U","TURISM - Servicii cf. art. 311",1
														&& 12, "H","SECOND HAND - Achizitii cf. art. 312",1
														&& 13, "O","Borderouri de achizitii",1
														&& 14, "Z","File carnete de comercializare",1
														&& 15, "Q","Contracte",1
														&& 16, "M","Factura simplificata (exceptand bonuri fiscale)",1
														&& 17, "L", "Factura emisa in numele furnizorului", 1
														&& 18, "n","Operatiuni neimpozabile",1
*													FURNIZOR.Cont si Denumire, NumarDoc, DataDoc,IsTvaIncasare
*												pe LINII:
*													Denumire, Buc, Cantitate, Pret, TVA, CONT
*                                              - Sa importe din ecranul monitorizare
*												dar sa aiba ei ecranul "IntCJ" deschis
*												cu bifa pe "Autorefresh"
*                                              - Sa nu importe decat o singura data
* ----------------------------------------------------------------------------------------
*
*!*					Case (cParentName="Amount" .And. cParentParentName="AllowanceCharge")
*!*						m.Discount_Linie = Val(cValue)
*!*					Case (cParentName="ChargeIndicator" .And. cParentParentName="AllowanceCharge")
*!*						lcChargeIndicator = AllTrim(cValue)
*!*	If m.Discount_Linie>0 .And. Lower(lcChargeIndicator)="false"
*!*		lnIdUnicGlobal = lnIdUnicGlobal+1
*!*		Insert Into C_FXML_DET (Id, Id_Unic, Den_Tip, Gestiune, Gen_Gest, Cod, Denumire, Um, Tva_Art, Cantitate, Pret_Unitar, Valoare, Tva_Ded, Text_Supl, InIe, Categorie, Cont);
*!*			Values (lnIdDoc, lnIdUnicGlobal, "Nedef", "", "", "", "Discount "+AllTrim(m.Denumire), m.Um, lnTvaArt, -1, -m.Discount_Linie, -m.Discount_Linie, Round(-m.Discount_Linie*m.lnTvaArt/100, 2), "", lnTipImport, m.Categorie, m.Cont)
*!*	EndIf
*	Tip_F	=>	Tip
*	Tip		=>	Tip_EFactura
*
* Diferenta de apel intre un token Opaque si unul JWT este in linia de mai jos:
* -H "Authorization: Bearer 0c9c.."
* 
* pentru un token JWT apelul fiind:
* -H "Authorization: JWT 0c9c.."
* 
* Post by mrapi � 30 Jan 2024, 15:37
* nu cred,lasi codul de apel acelasi
*
* C�mpuri noi pentru medicii platiti de Casele de Sanatate
* 
* Incepand cu date de 1 iulie 2024, Casele de Sanatate obliga medicii de familie sa parcurga un proces mai complex de validare a decontarilor si de transmitere a faptelor pentru plata serviciilor prestate.
* 
* Inainte de a emite e-Factura catre CANS, medicii de familie trebuie sa obtina, prin intermediul aplicatiei SIUI, urmatoarele:
* 
*	1. Validarea raportarii si obtinerea decontului;
	2. Intocmirea unei facturi proforma in aplicatia SIUI, pe baza decontului, moment la care va selecta codul activitatii;
	3. Daca proforma este corecta, Casa de Sanatate o valideaza si va genera un cod unic;
* 	
* Pasul urmator este transmiterea e-facturii catre casa, care trebuie sa contina doua informatii noi (campuri noi):
* 	campul "BT-11 referinta proiect" care se completeaza cu codul activitatii de la pct 2 de mai sus.
* 	campul "BT-13 referinta comenzii" care se completeaza cu codul unic aferent fiecarei proforme - pct. 3 de mai sus.
* Prin urmare, pe factura vei gasi si campurile de mai sus, unde completezi cu cele doua coduri.

* BT-11 codul activitatii prestate;
* BT-13 referinta comenzii;

******************************************************************************************




LParameters tnIdUnicFactura, tlRectificativa, tcDetalii_CL, tlIsExporteFact, tcAlias;
	, tlIsAutoFactura			&& Vicos.12.02.2024
*
If Empty(tlIsAutoFactura)
	tlIsAutoFactura = .F.
EndIf
*
*-- ============================================================================
*-- OOP ARCHITECTURE INTEGRATION (v2.0)
*-- Set glUseNewArchitecture to .T. to use the refactored OOP classes
*-- Default is .F. for backward compatibility
*-- ============================================================================
If Type('glUseNewArchitecture') = 'U'
	Public glUseNewArchitecture
	glUseNewArchitecture = .F.  && Set to .T. to use new architecture
EndIf
*
*-- Use new OOP architecture if enabled
If glUseNewArchitecture
	Local loFacade, lcResult
	
	*-- Load class procedures
	Set Procedure To Classes\Core\EFacturaFacade Additive
	Set Procedure To Classes\Core\EFacturaContext Additive
	Set Procedure To Classes\Core\ConfigProvider Additive
	Set Procedure To Classes\Handlers\AbstractHandler Additive
	Set Procedure To Classes\Handlers\ValidationHandler Additive
	Set Procedure To Classes\Handlers\TaxCalculationHandler Additive
	Set Procedure To Classes\Handlers\XmlBuilderHandler Additive
	Set Procedure To Classes\Handlers\ApiUploaderHandler Additive
	Set Procedure To Classes\Handlers\PersistenceHandler Additive
	Set Procedure To Classes\Builders\HandlerChainBuilder Additive
	Set Procedure To Classes\Observers\ProgressSubject Additive
	Set Procedure To Classes\Observers\ProgressBarObserver Additive
	Set Procedure To Classes\Services\LoggerService Additive
	Set Procedure To Classes\Services\StatsCollector Additive
	
	*-- Create facade and process
	loFacade = CreateObject("EFacturaFacade")
	lcResult = loFacade.Process(tnIdUnicFactura, tcAlias, tlRectificativa, tcDetalii_CL, tlIsExporteFact, tlIsAutoFactura)
	
	*-- Release facade
	loFacade = .Null.
	Release loFacade
	
	Return lcResult
EndIf
*-- ============================================================================
*-- END OOP ARCHITECTURE INTEGRATION
*-- ============================================================================
*
If _Vfp.StartMode=0 And ICAS.oSETTINGS.eFactura_Prod And Type('m.DevMode')='U'
	*
	If MessageBox(;
			'ATENTIE!!!'+Chr(13)+Chr(13)+;
			'e-Factura este setata pe mod = PRODUCTIE.'+Chr(13)+;
			'Continuati?',;
			4+256+16,;
			'PRODUCTIE e-Factura???')=7
			*
		lcReturn = 'e-Factura este setata pe mod = PRODUCTIE in _Vfp.StartMode=0.'
		Set Step On
		Return lcReturn
	EndIf
	*
EndIf	
*
lcCale_LOG = Get_LOG_EFA()
*Local oSetAlternate As Object, oSetConsole As Object, oSetSafety As Object, oSetCentury As Object
oSetConsole=CreateObject("SetConsole", 'Off')
oSetAlternate=CreateObject("SetAlternate", "On", lcCale_LOG+Program()+".log")
*
? "==============================="
? Program()
*
lnIdUnicFactura = tnIdUnicFactura
*
If IsNullOrEmpty(tcDetalii_CL)
	tcDetalii_CL=''
EndIf
*
*!*	ff=Structura_eFactura()
*
If Empty(tcAlias)
	*
	lc_ActiveForm_Name = _Screen.ActiveForm.Name
	? "lc_ActiveForm_Name ",	Transform(lc_ActiveForm_Name)
	*
	Do Case
		*
		Case IsNullOrEmpty(lc_ActiveForm_Name)
			lcAlias=Proper(Alias())
		*
		Case 'frmies'$Lower(lc_ActiveForm_Name)
			lcAlias='Iesiri'
		*
		Case 'frmexp'$Lower(lc_ActiveForm_Name)
			lcAlias='Export'
		*
		OtherWise	
			lcAlias=Proper(Alias())
	EndCase
	*
	If Not InList(lcAlias, 'Iesiri', 'Export', 'Docum')
		lcReturn = "Variabila [ lcAlias ] nu este setata corect!"
		MessageBox(lcReturn, 16, "Eroare", 3000)
		? "lcReturn ",	Transform(lcReturn)
		Return lcReturn
	EndIf
	*
Else
	lcAlias=Proper(tcAlias)
EndIf	
*
? "--------------------------------"
? "PARAMETERS:"
? "--------------------------------"
? "tnIdUnicFactura ",	Transform(tnIdUnicFactura)
? "tlRectificativa ",	Transform(tlRectificativa)
? "tcDetalii_CL ",		Transform(tcDetalii_CL)
? "tlIsExporteFact ",	Transform(tlIsExporteFact)
? "tcAlias",			Transform(tcAlias)
? "lcAlias",			Transform(lcAlias)
? "tlIsAutoFactura",	Transform(tlIsAutoFactura)
?
*
&& SCOS 10.11.2024
*!*	If IsNullOrEmpty(Is_EF)
*!*		MessageBox("Nu este bifat flagule [eFactura].", 16, "Eroare", 3000)
*!*		Return "Nu este bifat flagule [eFactura]."
*!*	EndIf
*
If IsObject([EFactura_Import]) And Used('Sel_eFactura')
	lc_ID_Solicitare = Sel_eFactura.Id_Solicitare
Else	
	lc_ID_Solicitare = Evaluate(lcAlias+".Id_Solicitare")
EndIf
*
? "lc_ID_Solicitare ",	Transform(lc_ID_Solicitare)
*!*	*If Not IsNullOrEmpty(Id_Solicitare) && Not tlRectificativa And BFTiparit=9	&& And Not IsNullOrEmpty(Recipisa)
*!*	*If Not tlRectificativa And BFTiparit=9	&& And Not IsNullOrEmpty(Recipisa)
*!*	If Not IsNullOrEmpty(lc_ID_Solicitare) && Not tlRectificativa And BFTiparit=9	&& And Not IsNullOrEmpty(Recipisa)
*!*		*
*!*		If  MessageBox(;
*!*			"Factura a fost generata si Incarcata deja."+Chr(13)+;
*!*			"cu ID_SOLICITARE: "+lc_ID_Solicitare+Chr(13)+;
*!*			"Sunteti sigur ca nu doriti generarea unei facturi rectificative?", 0292, "Atentie...")=7
*!*			Return "Factura generata si Incarcata deja."
*!*		EndIf
*!*		*
*!*	EndIf
*!*	*
If Type('ll_Is_ICAS')='U'
	Public ll_Is_ICAS
	ll_Is_ICAS = ( VarType(ICAS)='O' And Not IsNull(ICAS) ) And PemStatus(ICAS, 'oCfgSALARII', 5)
EndIf
*
If Not ll_Is_ICAS
	*
	&& creez obiectul ICAS in main.prg sau meniu.prg in EStoc-uri
	=Create_Cursor_Judete()
	=Get_Cursor_crsEFactura_eSTOC(lnIdUnicFactura, lcAlias)				&& EStocFB sau eStoc
	*
Else		If Not ( VarType(ICAS)='O' And Not IsNull(ICAS) )
	*
	=Get_Cursor_crsEFactura(lnIdUnicFactura, lcAlias)					&& ICAS
	*	
EndIf		If Not ( VarType(ICAS)='O' And Not IsNull(ICAS) )
*
If RecCount([crsEFactura])=0
	lcReturn = "Nu am reusit sa culeg datele pentru generarea XML-ului"
	Set Step On
	MessageBox(lcReturn, 16, "Eroare", 3000)
	? "lcReturn ",	Transform(lcReturn)
	Return lcReturn
EndIf
*
&& 12.03.2024
*
If  .Not. IsNullOrEmpty(crsEFactura.Recipisa) .And. tlRectificativa=.F.
	*
	lcReturn = IIf(tlIsAutoFactura, "Autofactura", "Factura")+" figureaza ca fiind generata si transmisa deja."
	* +Chr(13)+ "Sunteti sigur ca nu doriti generarea unei facturi rectificative?	
	MessageBox(lcReturn, 16, "Eroare")
	? "lcReturn ",	Transform(lcReturn)
	Return lcReturn
	*
EndIf
*
&& 12.03.2024
*
lcCaleFacturi = GetFolder_EFactura(crsEFactura.Data, 1)		&& folder recipise IESIRI
*// 31Martie2022
If  .Not. Directory(lcCaleFacturi)
	Md (lcCaleFacturi)
EndIf
*
lcNumeFisier = StrTran(AllTrim(crsEFactura.Nr), "/", "")+"_"+Transform(DToS(crsEFactura.Data), '@R ####-##-##')
*&& 03.01.2024
Get_Log_EFA()
*// 31Martie2022
*Update crsEFactura SET Indice = Iif(InList(Cont, '667', '709', '609'), -1, 0)
Update crsEFactura SET Indice = Iif(InList(Cont, '667', '709', '609') And Cantitate<0, -1, 0)
Update crsEFactura SET ProcTva = 0 Where InList(Tip, "U", "H")
*
*****	IsRectif = 0
*-- 12.07.2024
*
If tlRectificativa And Type('m.DevMode') = 'U'
	MessageBox("Trimiterea unei rectificative se poate face doar de developer!", 16, "Eroare")
	RETURN
EndIf
*
IsRectif = Iif(tlRectificativa, 1, 0)			&& 12.07.2024
*
lcReturn='!!!'
lcReturn=Create_XML_UBL_File_For_eFactura;
	(;
	IsRectif, lcNumeFisier, lcCaleFacturi, tlIsExporteFact, tcDetalii_CL;
	, lnIdUnicFactura;
	)
*
Return lcReturn
*
*
* __________________________________________________________________________________________________________
Procedure Create_XML_UBL_File_For_eFactura(tnRectificativa, tcNumeFisier, tcCaleFacturi, tlIsExport, tcDetalii_CL, tnIdUnicFactura, tlIsAutoFactura)
	*
	If Type('ll_Is_ICAS')='U'
		Public ll_Is_ICAS
		ll_Is_ICAS = ( VarType(ICAS)='O' And Not IsNull(ICAS) ) And PemStatus(ICAS, 'oCfgSALARII', 5)
	EndIf
	*
	If Empty(tnIdUnicFactura)
		ln_IdUnic_Factura  = 0
		lcReturn = 'Nu ati setat parametrul [ tnIdUnicFactura ]'
		MessageBox(lcReturn, 16, "Eroare", 3000)
		Return lcReturn
	Else	
		ln_IdUnic_Factura = tnIdUnicFactura
	EndIf	
	*
	If IsNullOrEmpty(tcDetalii_CL)
		tcDetalii_CL=''
	EndIf
	*
*!*		lcCale_LOG = Get_LOG_EFA()
*!*		Local oSetAlternate As Object, oSetConsole As Object
*!*		oSetConsole=CreateObject("SetConsole", 'Off')
*!*		oSetAlternate=CreateObject("SetAlternate", "On", lcCale_LOG+Program()+".log")
	*
	? "==============================="
	? Program()
	? "--------------------------------"
	? "PARAMETERS:"
	? "--------------------------------"
	? "tnRectificativa ",	Transform(tnRectificativa)
	? "tcNumeFisier ",		Transform(tcNumeFisier)
	? "tcCaleFacturi ",		Transform(tcCaleFacturi)
	? "tlIsExport ",		Transform(tlIsExport)
	? "tcDetalii_CL ",		Transform(tcDetalii_CL)
	? "ln_IdUnic_Factura ",	Transform(ln_IdUnic_Factura)
	?
	*
	Local lcTipFactura, i, lnLinii, lnLiniiReducere, lnLiniiStornare, lnAccize, lnTotalCharges, lnTotalAllowances, lcMoneda, lcInvoiceType, lcCodFiscal, lcComanda, lcTara, lcTipTert, lnTipTvaCurent, lnTvaI, lnIncasat, mExpliIesiriLot
	*, lnIdUnicFactura
	Store 1 To i
	Store 0 To lnAccize, lnLiniiReducere, lnTotalCharges, lnTotalAllowances, lnTvaI, lnIncasat
	Store "" TO mExpliIesiriLot
	*
	If Empty(ICAS.oSoc.CodFiscal)
		lcReturn = "Completati codul fiscal al societatii, in ecranul 'Setari => Firme...'."
		MessageBox(lcReturn, "Date incomplete...", 3000)
		? "lcReturn ",		Transform(lcReturn)
		Return lcReturn 
	EndIf
	*
*!*		If (Empty(crsEFactura.Tara) .Or. crsEFactura.Tara='RO') .And. (Empty(crsEFactura.Cod_Fiscal) .Or. Len(AllTrim(crsEFactura.Cod_Fiscal))=13 .Or.  .Not. VerifCF(crsEFactura.Cod_Fiscal))
*!*			=MessageBox("Factura electronica se genereaza doar pentru persoane jurifice.", 48, "Operatiune abandonata...", 3000)
*!*			Return
*!*		EndIf
	*

	lc_Upload_Param_Extern = Iif(crsEFactura.Is_Extern, '&extern=DA', '')		&& 05.09.2024
	
	Delete From crsEFactura Where Empty(IdUnic)
	*
*!*		Text To lcSQL NoShow TextMerge
*!*			Select
*!*				Contracte.NrContract As Nr
*!*				, Contracte.Data
*!*				-- , ContracteTip.Recurenta
*!*			FROM Contracte
*!*			INNER JOIN ContracteDetaliat ON Contracte.ID = ContracteDetaliat.IDContract 
*!*			JOIN ContracteTip ON Contracte.IdTipContract=ContracteTip.ID
*!*			WHERE
*!*				ContracteDetaliat.Id_Factura=?ln_IdUnic_Factura
*!*		EndText
*!*		=mySQLExec(lcSQL, [crs_Contract_EFactura]) 
	*

	*, Round(Sum(Valoare)*ProcTva/100, 2) As Tva;
	
	Select;
		ProcTva;
		, Sum(Tva)				As Tva;
		, Sum(TvaLei)			As TvaLei;
		, Sum(Valoare)			As Valoare;
		, '  '					As Tip;
		, Replicate(' ', 50)	As Explicatie;
		, Replicate(' ', 30)	As Motiv;
		, Curs;
		, CodTva;
	From crsEFactura;
	Group By;
		ProcTva, CodTva, Curs;
	Into Cursor crsTva_EFactura ReadWrite
	*
	? "Cursor crsTva_EFactura"
	Select crsTva_EFactura
	Sum Tva To lnTotalTva
	Index On ProcTva Tag Procent
	? "lnTotalTva ", Transform(lnTotalTva )
	*
*!*		Text To lcSQL NoShow TextMerge
*!*			Select DISTINCT
*!*				IesiriDetaliat.IDUnic As IdUnic
*!*				, ComenziTerti.NumarComanda As Nr
*!*				, ComenziTerti.Data
*!*			FROM Iesiri
*!*			INNER JOIN IesiriDetaliat ON Iesiri.IDDoc=IesiriDetaliat.IDDoc
*!*			JOIN ComenziFactura ON IesiriDetaliat.IdUnic=ComenziFactura.IdFactura
*!*			JOIN ComenziAntet ON ComenziFactura.IdComandaAntet = ComenziAntet.Id
*!*			JOIN ComenziTerti ON ComenziAntet.IdComandaTert=ComenziTerti.Id
*!*			WHERE
*!*				Iesiri.IdUnic=?ln_IdUnic_Factura
*!*		EndText
*!*		=mySQLExec(lcSQL, [crs_Comenzi_EFactura])
*!*		*
*!*		Select Distinct;
*!*			Nr;
*!*			, Data;
*!*		From crs_Comenzi_EFactura;
*!*		Into Cursor crs_Comenzi_Idividuale
*!*		*
*!*		If RecCount("crs_Comenzi_Idividuale")=1
*!*			lcComanda = AllTrim(crs_Comenzi_Idividuale.Nr)+"/"+AllTrim(DToC(crs_Comenzi_Idividuale.Data))
*!*		Else
*!*			lcComanda = ""
*!*		EndIf
*!*		*
	*#-- 17IUNIE2022
	***	lnIncasat		=	GetIncasariFactura(ln_IdUnic_Factura)
	&& AICI tb. mai defalcat????
	*#-- 17IUNIE2022
	*

	*// 31Martie2022  este la inceputul programului
	*Update crsEFactura Set Indice = IIf(InList(Cont, '667', '709', '609'), -1, 0)
	*// 31Martie2022
	*
	Select CodTva From crsEFactura Where CodTva='10' Into Array aGetIsTaxareInversa
	lIsTaxareInversa=Iif(_Tally>0, .T., .F.)
	*	
	Select crsEFactura
	lcNumarFactura	=	AllTrim(crsEFactura.Nr)
	lcMoneda		=	AllTrim(crsEFactura.Moneda)		&& 15.01.2024	Tb numai 'RON' in crsEFactura
	lcCodFiscal		=	crsEFactura.Cod_Fiscal
	*
	lcTipFactura	=	crsEFactura.Tip
	lcTara			=	crsEFactura.Tara
	ldData			=	crsEFactura.Data
	*
	lc_EFA_TipRaportare = 'B2B'
	*
	If crsEFactura.Data>={31.03.2025}
		*
		If VerifCF(lcCodFiscal)
			lc_EFA_TipRaportare = 'B2B'
		Else
			lc_EFA_TipRaportare = 'B2C'
		EndIf
	*	
	EndIf
	*	
	lcTipTert		=	ICase(IsNullOrEmpty(crsEFactura.Tip_Tert) Or InList(crsEFactura.Tip_Tert, '', '1'), '', crsEFactura.Tip_Tert='2', 'I', 'E')
	*lnTipTvaCurent	=	GetModPlataTva(crsEFactura.Data)
	lnTipTvaCurent	=	Iif(ll_Is_ICAS, GetModPlataTva(crsEFactura.Data), 1)
	*lnTvaI			=	ICase(crsEFactura.TvaI=.T., 1, 0)
	lnTvaI			=	Iif(ll_Is_ICAS, ICase(crsEFactura.TvaI=.T., 1, 0), crsEFactura.TvaI)
	mInf_Suplm		=	crsEFactura.Inf_Suplm
	mInf_Supl		=	crsEFactura.Inf_Supl
	mTiparit		= 	Iif(IsNull(crsEFactura.Tiparit), 0, crsEFactura.Tiparit)
	*
	? "lIsTaxareInversa ",	Transform(lIsTaxareInversa)	
	? "lcNumarFactura ",	Transform(lcNumarFactura)
	? "lcMoneda ",			Transform(lcMoneda)
	? "lcCodFiscal ",		Transform(lcCodFiscal)
	? "lcTipFactura ",		Transform(lcTipFactura)
	? "lcTara ",			Transform(lcTara)
	? "ldData ",			Transform(ldData)
	? "lcTipTert ",			Transform(lcTipTert)
	? "lnTipTvaCurent ",	Transform(lnTipTvaCurent)
	? "lnTvaI ",			Transform(lnTvaI)
	? "mInf_Suplm ",		Transform(mInf_Suplm)
	? "mInf_Supl ",			Transform(mInf_Supl)
	? "mTiparit ",			Transform(mTiparit)
	? "lc_EFA_TipRaportare ",Transform(lc_EFA_TipRaportare )
	
	
	*If  .Not. InList(lcTipFactura, ' ', 'T', 'S', 'U', 'H', 'M')
	*If  .Not. InList(lcTipFactura, ' ', 'S', 'M', 'U', 'H', 'T')						&& 05Ianuarie2021
	*If  .Not. InList(lcTipFactura, ' ', 'f', 'S', 'D', 'd', 'M', 'U', 'H', 'T', 'n')	&& 22August2021
	If  .Not. InList(lcTipFactura, ' ', 'f', 'S', 'D', 'd', 'U', 'H', 'T', 'n')			&& 08Ianuarie2025  'f'=751
		lcReturn = "Pentru acest document nu se genereaza factura electronica."
		MessageBox(lcReturn, 64, "Atentie...")
		? "lcReturn ",			Transform(lcReturn)
		Return lcReturn
		Return
	EndIf
	*
	lnIncasat=0
	*
	If ll_Is_ICAS
		*
		If tlIsExport		&& aici cred ca trebuia Ecran='Export'
			*
			Text To lcSQL NoShow TextMerge
	      		Select DISTINCT 
	      			[Ndp]=NumarDoc
	      			, [Data]=e.DataDoc
	      			, [Id_Solicit] = Id_Solicitare
	      		From Export e
	      		Inner Join NoteFacturiValuta n On e.IdUnic=n.IdFactura
	      		Where
	      			IdNota=?ln_IdUnic_Factura
	      			And IsStorno=1
			EndText
			mySQLExec(lcSQL, [C_EFACTURA_STORNO_VAL_VAL]) 
			*
			Text To lcSQL NoShow TextMerge
	      		Select DISTINCT
	      			[Ndp]=NumarDoc
	      			, [Data]=e.DataDoc
	      			, [Id_Solicit] = Id_Solicitare
	      		From Export e
	      		Inner Join NoteFacturi n On e.IdUnic=n.IdFactura
	      		Where
	      			IdNota=?ln_IdUnic_Factura
	      			And IsStorno=1
			EndText
			mySQLExec(lcSQL, [C_EFACTURA_STORNO_VAL_LEI])
			*
			Select * From C_EFACTURA_STORNO_VAL_VAL Union Select * From C_EFACTURA_STORNO_VAL_LEI Into Cursor C_EFACTURA_STORNO
			*
		Else
			*
			Text To lcSQL NoShow TextMerge
				Select DISTINCT
					[Ndp]=i.NumarDoc
					, [Data]=i.DataDoc
					, [Id_Solicit] = Id_Solicitare
				From Iesiri i
				Inner Join NoteFacturi n On i.IdUnic=n.Idfactura
				Where
					IdNota=?ln_IdUnic_Factura
					And IsStorno=1
			EndText
			mySQLExec(lcSQL, [C_EFACTURA_STORNO])
			*
		EndIf
		*
	Else
		*
		Text To lcSQL NoShow TextMerge
			Select DISTINCT
				Factura As Ndp
				, Data_Doc As Data
				, Id_Solicitare As Id_Solicit
			From Docum
			Where
				1=0
		EndText
		mySQLExec(lcSQL, [C_EFACTURA_STORNO])
		*
	EndIf
	*
	? "Cursor C_EFACTURA_STORNO"
	*
	If ll_Is_ICAS
		*
		Text To lcSQL NoShow TextMerge
			Select
				r.Ndp
				, r.Explicatie
				, r.Data
				, r.Curs
				, r.Suma AS Suma_Lei
				, r.Cod_Valuta
				, n.Suma
				, r.ContC
				, r.ContD
			From Registru r
			Inner Join NoteFacturi n On r.Id_Nota=n.IdNota
			Where
				n.IdFactura=?ln_IdUnic_Factura
				And r.ContC Not Like '442%'
		EndText
		mySQLExec(lcSQL, [crsIncasariLei])
		*
		Text To lcSQL NoShow TextMerge
			Select
				r.Ndp
				, r.Explicatie
				, r.Data
				, r.Curs
				, r.Suma AS Suma_Lei
				, r.Cod_Valuta
				, n.Suma
				, r.ContC
				, r.ContD
			From Registru r
			Inner Join NoteFacturi n On r.Id_Nota=n.IdNota
			Where
				n.IdFactura=?ln_IdUnic_Factura
				And r.ContC Not Like '442%'
		EndText
		mySQLExec(lcSQL, [crsIncasariValuta])
		*
		Update crsIncasariValuta Set Suma_Lei = Round(Suma*Iif(Curs>0, Curs, 1.0000 ), 2)
		*
		Select * From crsIncasariLei Union Select * From crsIncasariValuta Into Cursor C_INCASARI_EFACT
		*
	Else
		*
		Text To lcSQL NoShow TextMerge
			Select
				Factura As Ndp
				, '' As Explicatie
				, Data_Doc As Data
				, 1.0000 As Curs
				, 9999999999.99-9999999999.99 As Suma_Lei
				, 'RON' As Cod_Valuta
				, 9999999999.99-9999999999.99 As Suma
				, '          ' As ContC
				, '          ' As ContD
			From Docum
			Where
				1=0
		EndText
		mySQLExec(lcSQL, [C_INCASARI_EFACT])
		*
	EndIf
	*
	? "Cursor C_INCASARI_EFACT"
	*
	If RecCount("C_INCASARI_EFACT")>0
		*
		Select Sum(Suma_Lei) From C_INCASARI_EFACT Where Data<=ldData Into Array aTestIncasareEFactura
		*
		If _TALLY>0 .AND.  .NOT. IsNull(aTestIncasareEFactura)
			lnIncasat = aTestIncasareEFactura(1)
		EndIf
		*
	EndIf
	*
	Select crsEFactura
	Count To lnLinii
	Count For Indice=-1					To lnLiniiReducere
	Count For Indice>=0 .And. Valoare<0	To lnLiniiStornare
	Count For Cont='419'				To mNrLiniiAvans
	Sum Abs(Valoare)					To mDiscounturi For Indice=-1
	lnTotalAllowances = lnTotalAllowances+mDiscounturi
	Locate
	? "lnIncasat  ",		Transform(lnIncasat)
	? "lnLinii ",			Transform(lnLinii)
	? "lnLiniiReducere ",	Transform(lnLiniiReducere)
	? "lnLiniiStornare ",	Transform(lnLiniiStornare)
	? "mNrLiniiAvans ",		Transform(mNrLiniiAvans)
	? "mDiscounturi ",		Transform(mDiscounturi)
	? "lnTotalAllowances ",	Transform(lnTotalAllowances)
	*
	*
	&& Arrays.sort((Object[])this._UNCL4461);
	&& /*     */     
	&& /* 175 */     this._listID = new String[] { "S", "Z", "E", "AE", "K", "G", "O", "L", "M", "B" };
	&&  nomenclator 5305: 
	&& S=Standard rate,														�Cota normala�
	&& Z=Zero rated goods,													"Cota zero"
	&& E=Exempt from tax,													�Scutit de TVA�
	&& AE=VAT Reverse charge,												"Taxare inversa"
	&& K=VAT exempt for EEA intra-community supply of goods and services,	"Livrare intracomunitara"
	&& G=Free export item, tax not charged,									�Export �n afara UE�
	&& O=Service outside scope of tax,										"Nu face obiectul TVA"
	&& L=Canary Islands general indirect tax,								�IGIC�
	&& M=Tax for production, services and importation in Ceuta and Melilla	"IPSI"
	
	&& this._CEFVATEX = new String[] { 
	&& "VATEX-EU-79-C", "VATEX-EU-132", "VATEX-EU-132-1A", "VATEX-EU-132-1B", "VATEX-EU-132-1C",
	&& "VATEX-EU-132-1D", "VATEX-EU-132-1E", "VATEX-EU-132-1F", "VATEX-EU-132-1G", "VATEX-EU-132-1H",
	&& "VATEX-EU-132-1I", "VATEX-EU-132-1J", "VATEX-EU-132-1K", "VATEX-EU-132-1L", "VATEX-EU-132-1M",
	&& "VATEX-EU-132-1N", "VATEX-EU-132-1O", "VATEX-EU-132-1P", "VATEX-EU-132-1Q", "VATEX-EU-143", 
	&& "VATEX-EU-143-1A", "VATEX-EU-143-1B", "VATEX-EU-143-1C", "VATEX-EU-143-1D", "VATEX-EU-143-1E",
	&& "VATEX-EU-143-1F", "VATEX-EU-143-1FA", "VATEX-EU-143-1G", "VATEX-EU-143-1H", "VATEX-EU-143-1I",
	&& "VATEX-EU-143-1J", "VATEX-EU-143-1K", "VATEX-EU-143-1L", "VATEX-EU-309", "VATEX-EU-148", 
	&& "VATEX-EU-148-A", "VATEX-EU-148-B", "VATEX-EU-148-C", "VATEX-EU-148-D", "VATEX-EU-148-E", 
	&& "VATEX-EU-148-F", "VATEX-EU-148-G", "VATEX-EU-151", "VATEX-EU-151-1A", "VATEX-EU-151-1AA", 
	&& "VATEX-EU-151-1B", "VATEX-EU-151-1C", "VATEX-EU-151-1D", "VATEX-EU-151-1E", "VATEX-EU-G", 
	&& "VATEX-EU-O", "VATEX-EU-IC", "VATEX-EU-AE", "VATEX-EU-D", "VATEX-EU-F", 
	&& "VATEX-EU-I", "VATEX-EU-J" };
	*
	&& Vicos.03.10.2023
	lHasFacturiCuTva= .F.
	Select Count(*) From crsTva_EFactura Where Tva<>0 Into Array aGetHasTVA
	*
	If _TALLY>0 .AND.  .NOT. IsNull(aGetHasTVA(1)) .AND. aGetHasTVA(1)>0
    	lHasFacturiCuTva = .T.
	EndIf
	&& Vicos.03.10.2023
	*
	? "lHasFacturiCuTva ",	Transform(lHasFacturiCuTva)
	Select crsTva_EFactura
	*
	Scan
		*
		DO CASE
				*

				*Case lcTipFactura='T' .Or. lcTipTert='I' Or lIsTaxareInversa											&& Vicos.03.10.2023
			CASE lIsTaxareInversa OR lcTipFactura='T' .OR. (lcTipTert='I' .AND.  .NOT. EMPTY(lcCodFiscal) .AND.  .NOT. lHasFacturiCuTva)			&& Vicos.03.10.2023
				REPLACE Tip WITH 'AE', Explicatie WITH 'Taxare inversa', Motiv WITH 'VATEX-EU-AE'
				*
				*Case lcTipFactura='S'
			CASE INLIST(lcTipFactura, 'S', 'D', 'd')
				REPLACE Tip WITH 'E', Explicatie WITH 'Scutit cu drept de deducere', Motiv WITH 'VATEX-EU-O'		&& ? tb si motiv?
				*
			CASE (EMPTY(lcTipFactura) .OR. INLIST(lcTipFactura, 'n')) .AND. crsTva_EFactura.ProcTva=0
				*If "RO"$ICAS.oSoc.CodFiscal
				IF lnTipTvaCurent<3
					*Replace Tip With 'Z'	&&, Explicatie With 'Accize', Motiv With 'VATEX-EU-O'
					&&-- 13.09.2024
					*Replace Tip With 'E', Explicatie With 'Scutit de TVA'
					REPLACE Tip WITH 'E', Explicatie WITH 'Scutit de TVA', Motiv WITH 'VATEX-EU-O'	&& 19.09.2024
					&&-- 13.09.2024
				ELSE
					*Replace Tip With 'Z'	&&, Explicatie With 'Accize', Motiv With 'VATEX-EU-O'
					REPLACE Tip WITH 'O', Explicatie WITH 'Entitatea nu este inregistrata in scopuri de TVA', Motiv WITH 'VATEX-EU-O'
				ENDIF
				*
			CASE lcTipFactura='H'
				REPLACE Tip WITH 'E', Explicatie WITH 'Bunuri second-hand', Motiv WITH 'VATEX-EU-F'
				*
			CASE lcTipFactura='U'
				REPLACE Tip WITH 'E', Explicatie WITH 'Regim special agentii de turism', Motiv WITH 'VATEX-EU-309'
				*
			CASE ProcTva=0																			&& 19.09.2024	
				#IF .F.
					ProcTva	= 0
					CodTva	Denumire
					10		Bunuri cu taxare inversa
					11		Bunuri/servicii cu regim SPECIAL cf. art 152
					12		Livari externe cu drept de deducere
					13		Livari externe fara drept de deducere
					14		LIC scutite (art. 294 ALIN. (2) lit a) si d))
					15		LIC scutite (art. 294 ALIN. (2) lit b) si c)) sau Prestari de servicii intracomunitare
					16		ALTE livrari scutite cu drept de deducere
					17		livrari scutite fara drept de deducere
					18		Operatiuni neimpozabile
					27-28	servicii intracomunitare cf. art.278 ALIN.(1) cu locul prestarii �n Rom�nia
				#ENDIF
				IF lnTipTvaCurent<3
					DO CASE
						CASE CodTva = '17'	&& .NOT. IsNullOrEmpty(lcVatEx)
							REPLACE Tip WITH 'E', Explicatie WITH 'Scutit fara drept de deducere', Motiv WITH 'VATEX-EU-O'
						CASE CodTva = '16'
							REPLACE Tip WITH 'E', Explicatie WITH 'Scutit cu drept de deducere', Motiv WITH 'VATEX-EU-O'
						CASE CodTva = '18'
							REPLACE Tip WITH 'O', Explicatie WITH 'Entitatea nu este inregistrata in scopuri de TVA', Motiv WITH 'VATEX-EU-O'
						OTHERWISE
							REPLACE Tip WITH 'Z'
					ENDCASE
				ELSE
					REPLACE Tip WITH 'O', Explicatie WITH 'Entitatea nu este inregistrata in scopuri de TVA', Motiv WITH 'VATEX-EU-O'
				ENDIF

			OTHERWISE
				REPLACE Tip WITH 'S'
				*
		ENDCASE
		*
	EndScan
	*
	? "crsTva_EFactura.Tip ",			Transform(crsTva_EFactura.Tip)
	? "crsTva_EFactura.Explicatie ",	Transform(crsTva_EFactura.Explicatie)
	? "crsTva_EFactura.Motiv ",			Transform(crsTva_EFactura.Motiv)
	*
	If crsEFactura.Accize>0
		*
		lnAccize = crsEFactura.Accize
		lnTotalCharges = lnTotalCharges+lnAccize
		*
		If lnTipTvaCurent<3
			Select Count(*) From crsTva_EFactura Where Tip='E' Into Array aGetCotaZ
			If _Tally>0 .And.  .Not. IsNull(aGetCotaZ(1)) .And. aGetCotaZ(1)>0
				Update crsTva_EFactura Set Valoare = Valoare+lnAccize  Where Tip='E'
			Else
				Insert Into crsTva_EFactura (ProcTva, Tva, Valoare, Tip, Explicatie, Motiv, Curs) Values (0, 0, lnAccize , 'E', 'Acciza', 'VATEX-EU-O', 1)
			EndIf
		Else
			Select Count(*) From crsTva_EFactura Where Tip='O' Into Array aGetCotaZ
			If _Tally>0 .And.  .Not. IsNull(aGetCotaZ(1)) .And. aGetCotaZ(1)>0
				Update crsTva_EFactura Set Valoare = Valoare+lnAccize  Where Tip='O'
			Else
				Insert Into crsTva_EFactura (ProcTva, Tva, Valoare, Tip, Explicatie, Motiv, Curs) Values (0, 0, lnAccize , 'O', 'Acciza', 'VATEX-EU-O', 1)
			EndIf
		EndIf
			*
	EndIf
	*
	? "crsTva_EFactura.Accize ",			Transform(crsEFactura.Accize)
	*
	Select crsEFactura
	Locate
	*
	*oXML = CreateObject("msxml2.DOMDocument.6.0")
	oXML = CreateObject("msxml2.DOMDocument")
	? "oXML ", Transform(oXML)
	*oXML.AppendChild(oXML.CreateNode("PROCESSINGINSTRUCTION", "xml", ""))				&& 19OCTOMBRIE2022
	oPI = oXML.CreateProcessingInstruction("xml", "version='1.0' encoding='UTF-8'")
	oXML.AppendChild(oPI)
	oInvoice = oXML.AppendChild(oXML.CreateElement("Invoice"))
	oInvoice.SetAttribute("xmlns:cbc", "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2")
	oInvoice.SetAttribute("xmlns:udt", "urn:oasis:names:specification:ubl:schema:xsd:UnqualifiedDataTypes-2")
	oInvoice.SetAttribute("xmlns:cac", "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2")
	oInvoice.SetAttribute("xmlns:ccts", "urn:un:unece:uncefact:documentation:2")
	oInvoice.SetAttribute("xmlns", "urn:oasis:names:specification:ubl:schema:xsd:Invoice-2")
	*oInvoice.SetAttribute("xmlns", "urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2")
	oInvoice.SetAttribute("xmlns:qdt", "urn:oasis:names:specification:ubl:schema:xsd:QualifiedDataTypes-2")
	*oInvoice.SetAttribute("xsi:schemaLocation", "urn:oasis:names:specification:ubl:schema:xsd:Invoice-2 ../../UBL-2.1(1)/xsd/maindoc/UBL-Invoice-2.1.xsd")		&&19.09.2023
	oInvoice.SetAttribute("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance")
	oInvoice.AppendChild(oXML.CreateElement("cbc:UBLVersionID"))
	oInvoice.LastChild.Text = "2.1"
	oInvoice.AppendChild(oXML.CreateElement("cbc:CustomizationID"))	&& <!--BT-24-->
	*
	&& BT-24
	*If Date()>={29.12.2022}
	*If crsEFactura.Data>={29.12.2022}
		oInvoice.LastChild.Text = "urn:cen.eu:en16931:2017#compliant#urn:efactura.mfinante.ro:CIUS-RO:1.0.1"
	*Else
	*	oInvoice.LastChild.Text = "urn:cen.eu:en16931:2017#compliant#urn:efactura.mfinante.ro:CIUS-RO:1.0.0"	
	*EndIf
	*
	&& BT-1		Numarul facturii
	loNode = oInvoice.AppendChild(oXML.CreateElement("cbc:ID"))				&& <!--BT-1-->
	*oInvoice.LastChild.Text = AllTrim(crsEFactura.Nr)
	loNode.Text = AllTrim(crsEFactura.Nr)
	XML_CreateComment("BT-1", loNode)
	&& BT-2		Data emiterii facturii
	oInvoice.AppendChild(oXML.CreateElement("cbc:IssueDate"))		&& <!--BT-2-->
	oInvoice.LastChild.Text = AllTrim(Str(Year(crsEFactura.Data)))+"-"+PadL(AllTrim(Str(Month(crsEFactura.Data))), 2, "0")+"-"+PadL(AllTrim(Str(Day(crsEFactura.Data))), 2, "0")
	XML_CreateComment("BT-2", oInvoice.LastChild)
	*
	If IsNullOrEmpty(crsEFactura.Scadent)
		Replace Scadent With Data In crsEFactura
	EndIf	
	*
	&& BT-9		Data scadentei 
	oInvoice.AppendChild(oXML.CreateElement("cbc:DueDate"))			&& <!--BT-9-->
	oInvoice.LastChild.Text = AllTrim(Str(Year(crsEFactura.Scadent)))+"-"+PadL(AllTrim(Str(Month(crsEFactura.Scadent))), 2, "0")+"-"+PadL(AllTrim(Str(Day(crsEFactura.Scadent))), 2, "0")
	XML_CreateComment("BT-9", oInvoice.LastChild)
	*
	#if .f.
		mOperatiune = "Transmitere"
		mRecipisaLaTransmitere = Sel_EFactura.Recipisa
		mIndexLaTransmitere = Sel_EFactura.Id_Solicit
		If IsNull(mIndexLaTransmitere) .Or. Empty(mIndexLaTransmitere)
			*mIndex = pBridge.GetProperty(tResultSend, "Message")
			mIndexLaTransmitere = mIndex
		EndIf
		If Sel_EFactura.Is_AutoF=1
			Do Case
			Case IsNullOrEmpty(Sel_EFactura.Id_Solicit) .And. IsNullOrEmpty(Sel_EFactura.Recipisa)
				mOperatiune = "Transmitere autofactura"
			Case  .Not. IsNullOrEmpty(Sel_EFactura.Recipisa) .And. Sel_EFactura.Rectif=1
				mOperatiune = "Rectificativa autofactura"
			Case  .Not. IsNullOrEmpty(Sel_EFactura.Id_Solicit) .And.  .Not. IsNullOrEmpty(Sel_EFactura.Recipisa) .And. Sel_EFactura.Rectif=0
				mOperatiune = "Retransmitere autofactura"
			Case  .Not. IsNullOrEmpty(Sel_EFactura.Id_Solicit) .And. IsNullOrEmpty(Sel_EFactura.Recipisa)
				mOperatiune = "Retransmitere autofactura proc"
			EndCase
		Else
			Do Case
			Case IsNullOrEmpty(Sel_EFactura.Id_Solicit) .And. IsNullOrEmpty(Sel_EFactura.Recipisa)
				mOperatiune = "Transmitere factura"
			Case  .Not. IsNullOrEmpty(Sel_EFactura.Recipisa) .And. Sel_EFactura.Rectif=1
				mOperatiune = "Rectificativa"
			Case  .Not. IsNullOrEmpty(Sel_EFactura.Id_Solicit) .And.  .Not. IsNullOrEmpty(Sel_EFactura.Recipisa) .And. Sel_EFactura.Rectif=0
				mOperatiune = "Retransmitere"
			Case  .Not. IsNullOrEmpty(Sel_EFactura.Id_Solicit) .And. IsNullOrEmpty(Sel_EFactura.Recipisa)
				mOperatiune = "Retransmitere in procesare"
			EndCase
		EndIf
		SaveIstoriceFactura(plId, mOperatiune, mIndexLaTransmitere, mRecipisaLaTransmitere, "")	
	#endif

	lcInvoiceType = ""
	*# -- InvoiceType
	*�Cod tip factura� (BT-3) trebuie sa fie unul dintre urmatoarele coduri din lista de coduri UNTDID 1001: 
	* 380 (Factura), 
	* 389 (Autofactura),
	* 384 (Factura corectata),
	* 381 (Nota de creditare),	&& Nu mai se foloseste
	* 751 (Factura � informatii �n scopuri contabile). 	
	*     ( Factura achitata cu bonfiscal sau bonuri fiscale indiferent de valoare si daca au CIF sau NU si facturate)
	*
	*Am o �ntrebare legata de codul de facturare 751 care este �n scopuri contabile. 
	*�nteleg ca orice are legatura cu un bon fiscal, daca se emite factura pentru un bon fiscal ar trebui sa poarte acest cod, 
	*indiferent daca valoarea achizitiei este mai mare de 100 euro?
	*ANAF:	Codul 751 se foloseste �n momentul �n care au fost emise unul sau mai multe bonuri fiscale, 
	*		indiferent daca e sub 100 euro si ulterior se emite si factura.
	*
	Do Case
		*
		Case tnRectificativa=1
			lcInvoiceType = "384"			&& Factura corectata
			* .NOT. IsNullOrEmpty(Sel_EFactura.Recipisa) .AND. Sel_Efactura.Rectif=1
            *                    mOperatiune = "Rectificativa"
			
		*
		Case AllTrim(GetNrFromString(lcCodFiscal))==AllTrim(ICAS.oSoc.CodFiscal) Or tlIsAutoFactura
			lcInvoiceType = "389"			&& Autofactura
		*
    	Case lcTipFactura='L'
        	lcInvoiceType = "389"			&& Autofactura
		
		Case lnLiniiStornare=lnLinii
			*lcInvoiceType = "381"			&& Nota de creditare
			lcInvoiceType = "380"
		*
	    Case (lcTipFactura=' ' .AND. mTiparit=1) .OR. lcTipFactura='f'
	        lcInvoiceType = "751"			&& * 751 (Factura � informatii �n scopuri contabile - Factura achita cu bonfiscal )

		OtherWise
			lcInvoiceType = "380"			&& Factura
		*
	EndCase
	*
	&& BT-3		Codul tipului facturii
	oInvoice.AppendChild(oXML.CreateElement("cbc:InvoiceTypeCode"))		&& <!--BT-3-->
	oInvoice.LastChild.Text = lcInvoiceType
	XML_CreateComment("BT-3", oInvoice.LastChild)
	? "lcInvoiceType (BT-3) ", Transform(lcInvoiceType)	
	*
	&& BT-22		Comentariu in factura
	*
	If lnTvaI=1
		oInvoice.AppendChild(oXML.CreateElement("cbc:Note"))			&& <!--BT-22-->
		oInvoice.LastChild.Text = "TVA la incasare"
		? "lnTvaI ", Transform(lnTvaI)
		XML_CreateComment("BT-22", oInvoice.LastChild)
		
		If _VFP.StartMode = 0
		    comment = oXML.createComment("BT-22")
	    	oInvoice.LastChild.appendChild(comment)
	    	*? oInvoice.XML
	    EndIf	
		
	EndIf
	*
	*If  .Not. Empty(lcTipFactura='T' .Or. lcTipTert='I')
	*If lIsTaxareInversa Or lcTipFactura='T' Or lcTipTert='I'
	If (lIsTaxareInversa Or lcTipFactura='T' .OR. (lcTipTert='I' .AND.  .NOT. EMPTY(lcCodFiscal) .AND.  .NOT. lHasFacturiCuTva))			&& Vicos.03.10.2023
		oInvoice.AppendChild(oXML.CreateElement("cbc:Note"))
		oInvoice.LastChild.Text = "Taxare inversa"
	EndIf
	*
	? "BT-22		Comentariu in factura ", Transform(oInvoice.LastChild.Text)	
	*	
	lcInformatiiFactura=AllTrim(crsEFactura.Inf_Suplm)
	*
	If  .Not. IsNullOrEmpty(lcInformatiiFactura)
		*
		If ParseDiacritics(lcInformatiiFactura, 1)>0
			lcInformatiiFactura=ReplaceDiacritics(lcInformatiiFactura)
		EndIf
		*	
		oInvoice.AppendChild(oXML.CreateElement("cbc:Note"))
		oInvoice.LastChild.Text = lcInformatiiFactura
		? "lcInformatiiFactura ", Transform(oInvoice.LastChild.Text)
		
	EndIf
	*
	lcInformatiiClient=AllTrim(crsEFactura.Inf_Supl)
	*
	If  .Not. IsNullOrEmpty(lcInformatiiClient)
		*
		If ParseDiacritics(lcInformatiiClient, 1)>0
			lcInformatiiClient=ReplaceDiacritics(lcInformatiiClient)
		EndIf
		*	
		oInvoice.AppendChild(oXML.CreateElement("cbc:Note"))
		oInvoice.LastChild.Text = lcInformatiiClient
		? "lcInformatiiClient ", Transform(oInvoice.LastChild.Text)
		
	EndIf
	*	
	IF  .NOT. tlIsAutoFactura			&& Vicos.12.02.2024
		*
		If .NOT. IsNullOrEmpty(AllTrim(tcDetalii_CL))
		   lcInformatiiClient = AllTrim(StrTran(tcDetalii_CL, CHR(13), ';'))
		   oInvoice.AppendChild(oXML.CreateElement("cbc:Note"))
		   oInvoice.LastChild.Text = AllTrim(SubStr(lcInformatiiClient, 1, Min(Len(lcInformatiiClient), 300)))
		   ? "tcDetalii_CL ", Transform(oInvoice.LastChild.Text)
		EndIf
		*
	EndIf
	*
	*
	&& IDEM pentru:		infoSupl1, infoSupl2, infoSupl3
	*
	* Data exigibilitate TVA (BT-7)
	*	<cbc:TaxPointDate>2009-11-13</cbc:TaxPointDate><!--BT-7-->
	*
	&& BT-5		Codul monedei
	oInvoice.AppendChild(oXML.CreateElement("cbc:DocumentCurrencyCode"))
	oInvoice.LastChild.Text = AllTrim(Moneda)
	XML_CreateComment("BT-5", oInvoice.LastChild)
	? "BT-5		Codul monedei ", Transform(oInvoice.LastChild.Text)
	&& BT-6
	oInvoice.AppendChild(oXML.CreateElement("cbc:TaxCurrencyCode"))
	oInvoice.LastChild.Text = "RON"										&& AICI clar trebuie numai "RON"
	XML_CreateComment("BT-6", oInvoice.LastChild)
	? "BT-6 ", Transform(oInvoice.LastChild.Text)
	*
*!*		If  .Not. Empty(lcComanda)
*!*			oOrderReference = oInvoice.AppendChild(oXML.CreateElement("cac:OrderReference"))
*!*			&& BT-13		Referinta comenzii
*!*			oOrderReference.AppendChild(oXML.CreateElement("cbc:ID"))
*!*			oOrderReference.LastChild.Text = lcComanda
*!*			? "BT-13		Referinta comenzii", Transform(oInvoice.LastChild.Text)
*!*		EndIf
	*
	
*F: OrderReference (1)
* eroare structura: ordine incorecta a descendentilor elementului 'Invoice': elementul 'OrderReference' trebuie sa preceada elementul 'AdditionalDocumentReference'	
	*///////////////////////////////////////////////////////////////////////////////////////
	*	
	* Campuri NOI MEDICI
	*
    *\	<cac:OrderReference>
    *\		<cbc:ID><<get_tag("BT-13")>></cbc:ID><!--BT-13-->
    *\	</cac:OrderReference>
    *
    
	*F: AdditionalDocumentReference (1)
	*	eroare structura: ordine incorecta a descendentilor elementului 'Invoice': elementul 'AdditionalDocumentReference' trebuie sa preceada elementul 'ProjectReference'
 
	*F: OrderReference (1)
	* eroare structura: ordine incorecta a descendentilor elementului 'Invoice': elementul 'OrderReference' trebuie sa preceada elementul 'ProjectReference'	
	If Not IsNullOrEmpty(crsEFactura.BT_13)
		*
		oOrderReference = oInvoice.AppendChild(oXML.CreateElement("cac:OrderReference"))
		&& BT-13		Referinta comenzii
		oOrderReference.AppendChild(oXML.CreateElement("cbc:ID"))
		oOrderReference.LastChild.Text = crsEFactura.BT_13
		XML_CreateComment("BT-13", oInvoice.LastChild)
		*? "BT-13		Referinta comenzii", Transform(oInvoice.LastChild.Text)
		*
    EndIf
	*
	&& 05.08.2024
	*
	*F: BillingReference (1)
	* eroare structura: ordine incorecta a descendentilor elementului 'Invoice': 
	* elementul 'BillingReference' trebuie sa preceada elementul 'ProjectReference'
	*
	*F: BillingReference (1)
	* eroare structura: ordine incorecta a descendentilor elementului 'Invoice': 
	* elementul 'BillingReference' trebuie sa preceada elementul 'AdditionalDocumentReference'
	*
	If lcInvoiceType='384'		&& Rectificativa, 384 (Factura corectata)
		*
		oBillingReference						= oInvoice.AppendChild(oXML.CreateElement("cac:BillingReference"))
		oOrderDocumentReference					= oBillingReference.AppendChild(oXML.CreateElement("cac:InvoiceDocumentReference"))
		oOrderDocumentReference.AppendChild(oXML.CreateElement("cbc:ID"))
		oOrderDocumentReference.LastChild.Text	= AllTrim(crsEFactura.Nr)
		XML_CreateComment("BT-25", oOrderDocumentReference.LastChild)
		oOrderDocumentReference.AppendChild(oXML.CreateElement("cbc:IssueDate"))
		oOrderDocumentReference.LastChild.Text	= AllTrim(Str(Year(crsEFactura.Data)))+"-"+PadL(AllTrim(Str(Month(crsEFactura.Data))), 2, "0")+"-"+PadL(AllTrim(Str(Day(crsEFactura.Data))), 2, "0")
		XML_CreateComment("BT-26", oOrderDocumentReference.LastChild)
		*
	EndIf
	*
	&& 05.08.2024
	*
	*___________________________________________________________________________________________________________________________________________
	*
	*&& 03IUNIE2024
	*
	If ll_Is_ICAS
		Set Procedure To Efactura_EmbeddedDocumentBinaryObject_Test Additive
		&& <!--BG-24-->		Documente atasate
		oADR						= oInvoice.AppendChild(oXML.CreateElement("cac:AdditionalDocumentReference"))
		oADR_cbc_ID					= oADR.AppendChild(oXML.CreateElement("cbc:ID"))
		oADR_cbc_ID.Text			= '1'
		XML_CreateComment("BT-18", oADR_cbc_ID)
		*
		oADR_DD						= oADR.AppendChild(oXML.CreateElement("cbc:DocumentDescription"))
		oADR_DD.Text				= 'pdf'
		*
		oADR_Attachment 			= oADR.AppendChild(oXML.CreateElement("cac:Attachment"))
		oADR_Attachment_EDBO		= oADR_Attachment.AppendChild(oXML.CreateElement("cbc:EmbeddedDocumentBinaryObject"))
		oADR_Attachment_EDBO.SetAttribute("mimeCode", "application/pdf")
		lcPdfFileName = EFactura_EmbeddedDocumentBinaryObject_Test( crsEFactura.IdDoc, Iif(lcAlias='Iesiri', 0, 1), 1)
		oADR_Attachment_EDBO.SetAttribute("filename", JustFname( lcPdfFileName ) )
		&& <!--BT-125-->
		oADR_Attachment_EDBO.Text	= Pdf2Base64( lcPDFFileName )
	EndIf
	*
	*&& 03IUNIE2024
	*
	*___________________________________________________________________________________________________________________________________________
	*

	*///////////////////////////////////////////////////////////////////////////////////////
	*	
	* Campuri NOI MEDICI
	*
    *\    <cac:ProjectReference>
    *\        <cbc:ID>4304449001847</cbc:ID>  <!--BT-11-->
    *\    </cac:ProjectReference>
	*
	*	
    If Not IsNullOrEmpty(crsEFactura.BT_11)
		*
		oProjectReference = oInvoice.AppendChild(oXML.CreateElement("cac:ProjectReference"))
		&& BT-11		ProjectReference
		oProjectReference.AppendChild(oXML.CreateElement("cbc:ID"))
		oProjectReference.LastChild.Text = crsEFactura.BT_11
		XML_CreateComment("BT-11", oProjectReference.LastChild)
		*
    EndIf
	*
	*///////////////////////////////////////////////////////////////////////////////////////
	*	
	*
*!*		If lcInvoiceType='384'		&& Rectificativa, 384 (Factura corectata)
*!*			*
*!*			oBillingReference = oInvoice.AppendChild(oXML.CreateElement("cac:BillingReference"))
*!*			oOrderDocumentReference = oBillingReference.AppendChild(oXML.CreateElement("cac:InvoiceDocumentReference"))
*!*			oOrderDocumentReference.AppendChild(oXML.CreateElement("cbc:ID"))
*!*			oOrderDocumentReference.LastChild.Text = AllTrim(crsEFactura.Nr)
*!*			oOrderDocumentReference.AppendChild(oXML.CreateElement("cbc:IssueDate"))
*!*			oOrderDocumentReference.LastChild.Text = AllTrim(Str(Year(crsEFactura.Data)))+"-"+PadL(AllTrim(Str(Month(crsEFactura.Data))), 2, "0")+"-"+PadL(AllTrim(Str(Day(crsEFactura.Data))), 2, "0")
*!*			*
*!*		Else
	If lcInvoiceType<>'384'			&& Rectificativa, 384 (Factura corectata)
		*
		If Used("C_EFACTURA_STORNO") .And. RecCount("C_EFACTURA_STORNO")>0
			Select c_EFactura_Storno
			Scan
				lcNumarDoc = AllTrim(c_EFactura_Storno.Ndp)
				ldDataDocStorno = AllTrim(Str(Year(c_EFactura_Storno.Data)))+"-"+PadL(AllTrim(Str(Month(c_EFactura_Storno.Data))), 2, "0")+"-"+PadL(AllTrim(Str(Day(c_EFactura_Storno.Data))), 2, "0")
				oBillingReference = oInvoice.AppendChild(oXML.CreateElement("cac:BillingReference"))
				oOrderDocumentReference = oBillingReference.AppendChild(oXML.CreateElement("cac:InvoiceDocumentReference"))
				oOrderDocumentReference.AppendChild(oXML.CreateElement("cbc:ID"))
				oOrderDocumentReference.LastChild.Text = lcNumarDoc
				XML_CreateComment("BT-25", oOrderDocumentReference.LastChild)
				oOrderDocumentReference.AppendChild(oXML.CreateElement("cbc:IssueDate"))
				oOrderDocumentReference.LastChild.Text = ldDataDocStorno
				XML_CreateComment("BT-26", oOrderDocumentReference.LastChild)
				&& 29.08.2024
	            IF IsNullOrEmpty(c_EFactura_Storno.Id_Solicit)=.F.
	                oBillingReferenceIndexSpv					= oInvoice.AppendChild(oXML.CreateElement("cac:BillingReference"))
	                oOrderDocumentReferenceSpv					= oBillingReferenceIndexSpv.AppendChild(oXML.CreateElement("cac:InvoiceDocumentReference"))
	                oOrderDocumentReferenceSpv.AppendChild(oXML.CreateElement("cbc:ID"))
	                oOrderDocumentReferenceSpv.LastChild.Text	= "Index incarcare SPV: "+AllTrim(c_EFactura_Storno.Id_Solicit)
	                XML_CreateComment("BT-25", oOrderDocumentReferenceSpv.LastChild)
	            ENDIF
				&&
			EndScan
		EndIf
		*
	EndIf
	*
	
	
	
*!*		lcContracte	= crsEFactura.Contract
*!*		lcAvizIn	= crsEFactura.Aviz_In
*!*		lcAvize		= crsEFactura.Aviz

*!*		If  .Not. Empty(AllTrim(lcAvize))
*!*			oDespatchReference							= oInvoice.AppendChild(oXML.CreateElement("cac:DespatchDocumentReference"))
*!*			oDespatchReference.AppendChild(oXML.CreateElement("cbc:ID"))
*!*			oDespatchReference.LastChild.Text			= AllTrim(lcAvize)
*!*		EndIf
*!*		If  .Not. Empty(AllTrim(lcAvizIn))
*!*			oReceiptDocumentReference					= oInvoice.AppendChild(oXML.CreateElement("cac:ReceiptDocumentReference"))
*!*			oReceiptDocumentReference.AppendChild(oXML.CreateElement("cbc:ID"))
*!*			oReceiptDocumentReference.LastChild.Text	= AllTrim(lcAvizIn)
*!*		EndIf
*!*		If  .Not. Empty(AllTrim(lcContracte))
*!*			oContractReference							= oInvoice.AppendChild(oXML.CreateElement("cac:ContractDocumentReference"))
*!*			oContractReference.AppendChild(oXML.CreateElement("cbc:ID"))
*!*			oContractReference.LastChild.Text			= AllTrim(lcContracte)
*!*		EndIf	
	
	
	
*!*		If RecCount("crs_Contract_EFactura")>0
*!*			oContractReference = oInvoice.AppendChild(oXML.CreateElement("cac:ContractDocumentReference"))
*!*			&& BT-12	Referinta contractului 
*!*			oContractReference.AppendChild(oXML.CreateElement("cbc:ID"))
*!*			ocontractreferente.LastChild.Text = AllTrim(crs_Contract_EFactura.Nr)+"/"+AllTrim(DToC(crs_Contract_EFactura.Data))
*!*		EndIf
	*
	Select crsEFactura
	&& 
	? "--BG-4 SUPPLIER VANZATOR--"
	oSupplier = oInvoice.AppendChild(oXML.CreateElement("cac:AccountingSupplierParty"))
	oParty = oSupplier.AppendChild(oXML.CreateElement("cac:Party"))
	*// 31Martie2022
	*If Empty(ICAS.oSoc.Email)
		* MessageBox("Completati adresa de email a societatii in ecranul 'Configurare societati'."+Chr(13)+"Aceasta este necesara pentru primirea raspunsului facturii electronice.", 48, "Date incomplete...", 3000)
		* Return "Completati adresa de email a societatii in ecranul 'Configurare societati'."
		* Return
	*EndIf
	*// 31Martie2022
	*
	If Not Empty(AllTrim(ICAS.oSoc.Email))
		&& BT-34
		oEndpointId = oParty.AppendChild(oXML.CreateElement("cbc:EndpointID"))
		oEndpointId.SetAttribute("schemeID", "EM")
		oEndpointId.Text = AllTrim(ICAS.oSoc.Email)
		XML_CreateComment("BT-34", oEndpointId)
		? "BT-34 Email", Transform(oEndpointId.Text)
	EndIf	
	*
	If  .Not. Empty(crsEFactura.Cod_Fiscal) .AND. VerifCF(crsEFactura.Cod_Fiscal)
		oPartyIdentification = oParty.AppendChild(oXML.CreateElement("cac:PartyIdentification"))
		&& BT-29 BT-29-1
		oIdParty = oPartyIdentification.AppendChild(oXML.CreateElement("cbc:ID"))
		oIdParty.Text = ICAS.oSoc.CodFiscal
		? "BT-29 BT-29-1 Cod fiscal FURNIZOR ", Transform(oIdParty.Text)
		XML_CreateComment("BT-29", oIdParty)
	EndIf
	*
	&& <cac:PartyName>
	&& 			<cbc:Name>Salescompany ltd.</cbc:Name><!--BT-28-->
	&& </cac:PartyName>	
	*
	&& BG-5
	oAdresa = oParty.AppendChild(oXML.CreateElement("cac:PostalAddress"))
	If Empty(ICAS.oSoc.Strada)
		MessageBox("Completati strada in ecranul 'Configurare societati'.", 48, "Date incomplete...",3000)
		Return "Completati strada in ecranul 'Configurare societati'."
		Return
	EndIf
	&& BT-35		Strada, numarul
	oAdresa.AppendChild(oXML.CreateElement("cbc:StreetName"))
	*
	If ICAS.cBackEnd='MySQL'
		oAdresa.LastChild.Text = AllTrim(ICAS.oSoc.Strada)
	Else	
		&& STANIMIR::	23.09.2024
		*oAdresa.LastChild.Text = GetAdresa('', '', '', ICAS.oSoc.Strada, ICAS.oSoc.NumarStrada, ICAS.oSoc.Bloc, ICAS.oSoc.Scara, ICAS.oSoc.Etaj, ICAS.oSoc.Apartament, ICAS.oSoc.CodPostal, ICAS.oSoc.Telefon)
		&& Fara judet, localitate, sector
		&& Iau numai strada, NumarStrada, Bloc, Scara, Etaj, Apartament
		&& Sediu social: Municipiul Oltenita, Strada PESCARILOR, Nr.23, Bloc M6, Scara A, Etaj PARTER, Ap.3, Judet Calarasi
		oAdresa.LastChild.Text = GetAdresa('', '', '', ICas.oSoc.Strada, ICas.oSoc.NumarStrada, ICas.oSoc.Bloc, ICas.oSoc.Scara, ICas.oSoc.Etaj, ICas.oSoc.Apartament)
		XML_CreateComment("BT-35", oAdresa.LastChild)
		*
	EndIf
	&& <cbc:AdditionalStreetName>Suite 123</cbc:AdditionalStreetName><!--BT-36-->
	*
	If Empty(ICAS.oSoc.Localitate)
		MessageBox("Completati localitatea in ecranul 'Configurare societati'.", 48, "Date incomplete...",3000)
		Return "Completati localitatea in ecranul 'Configurare societati'."
		Return
	EndIf
	*
	If Empty(ICAS.oSoc.Judet)
		MessageBox("Alegeti judetul in ecranul 'Configurare societati'.", 48, "Date incomplete...", 3000)
		Return "Alegeti judetul in ecranul 'Configurare societati'."
		Return
	Else
		If ICAS.oSoc.Judet="BUCURESTI" .And. Empty(ICAS.oSoc.Sector)
			MessageBox("Completati sectorul in ecranul 'Configurare societati'.", 48, "Date incomplete...",3000)
			Return "Completati sectorul in ecranul 'Configurare societati'."
			Return
		EndIf
	EndIf
	*
	&& BT-37		Localitatea
	oAdresa.AppendChild(oXML.CreateElement("cbc:CityName"))
	*oAdresa.LastChild.Text = AllTrim(Upper(ICAS.oSoc.Localitate))+IIf(ICAS.oSoc.Judet="BUCURESTI" .And.  .Not. ("SECT"$Upper(ICAS.oSoc.Localitate)), " SECTOR"+AllTrim(ICAS.oSoc.Sector), "")
	oAdresa.LastChild.Text = IIf(ICAS.oSoc.Judet="BUCURESTI" .And.  .Not. ("SECT"$Upper(ICAS.oSoc.Localitate)), " SECTOR"+AllTrim(ICAS.oSoc.Sector), AllTrim(Upper(ICAS.oSoc.Localitate)))
	XML_CreateComment("BT-37", oAdresa.LastChild)
	*
	&& <cbc:PostalZone>54321</cbc:PostalZone><!--BT-38-->		Codul postal
	*
	If ll_Is_ICAS
		*
		Text To lcSQL NoShow TextMerge
			Select
				Cod
			From Configurari.Judete 
			Where
				DenJud=?ICAS.oSoc.Judet
		EndText
		=mySQLExec(lcSQL, [crsSQLJudete])
		*
	Else
		Select Cod From Judete Where DenJud=ICAS.oSoc.Judet Into Cursor crsSQLJudete
	EndIf
	*
	Select * From crsSQLJudete Into Array aGetJudAdresa
	mCodJudet = ""
	*
	If _Tally>0 .And.  .Not. IsNull(aGetJudAdresa(1))
		mCodJudet = aGetJudAdresa(1)
	EndIf
	*
	&& BT-39		Subdiviziunea tarii
	oAdresa.AppendChild(oXML.CreateElement("cbc:CountrySubentity"))
	*oAdresa.LastChild.Text = AllTrim(mCodJudet)
	oAdresa.LastChild.Text = 'RO-'+AllTrim(mCodJudet)
	XML_CreateComment("BT-39", oAdresa.LastChild)
	&& <cac:AddressLine>
	&& 		<cbc:Line>Block 212</cbc:Line><!--BT-162-->
	&& </cac:AddressLine>	
	oTara = oAdresa.AppendChild(oXML.CreateElement("cac:Country"))
	&& BT-40		Codul tarii
	oTara.AppendChild(oXML.CreateElement("cbc:IdentificationCode"))
	oTara.LastChild.Text = "RO"
	XML_CreateComment("BT-40", oTara.LastChild)
	&& </cac:PostalAddress>	BG-5
	*
	*Select Count(*) From crsTva_EFactura Where Tip='E' Into Array aGetExceptiiTva										&& 12Iunie2023
	Select Count(*) From crsTva_EFactura Where Tip='E' OR (Tip='S' And ProcTva=8) Into Array aGetExceptiiTva			&& 12Iunie2023
	lIsExceptii = .F.
	If _TALLY>0 .AND. aGetExceptiiTva(1)>0
		   lIsExceptii=.T.
	EndIf
	*	
*!*		oTaxe = oParty.AppendChild(oXML.CreateElement("cac:PartyTaxScheme"))
*!*		&& BT-31		identificatorul de TVA
*!*		If lnTipTvaCurent<3	Or lIsExceptii
*!*			oTaxe.AppendChild(oXML.CreateElement("cbc:CompanyID"))
*!*			oTaxe.LastChild.Text = "RO"+OnlyNumber(ICAS.oSoc.CodFiscal)
*!*		EndIf
*!*		*	
*!*		oSchemaTaxe = oTaxe.AppendChild(oXML.CreateElement("cac:TaxScheme"))
*!*		oSchemaTaxe.AppendChild(oXML.CreateElement("cbc:ID"))
*!*		oSchemaTaxe.LastChild.Text = "VAT"
	*
	oTaxe = oParty.AppendChild(oXML.CreateElement("cac:PartyTaxScheme"))
	oTaxe.AppendChild(oXML.CreateElement("cbc:CompanyID"))
	oTaxe.LastChild.Text = AllTrim("RO"+OnlyNumber(ICAS.oSoc.CodFiscal))
	XML_CreateComment("BT-31", oTaxe.LastChild)
	oSchemaTaxe = oTaxe.AppendChild(oXML.CreateElement("cac:TaxScheme"))
	*	
	If lnTipTvaCurent<3 .Or. (lIsExceptii)							&& 28.10.2024
		oSchemaTaxe.AppendChild(oXML.CreateElement("cbc:ID"))
		oSchemaTaxe.LastChild.Text = "VAT"
		XML_CreateComment("BT-29", oSchemaTaxe.LastChild)
	EndIf
	*
	oFormaLegala = oParty.AppendChild(oXML.CreateElement("cac:PartyLegalEntity"))
	*____________________
	*
	* DETALII VANZATOR
	*____________________
	&& BT-27		Numele/ Denumirea
	oFormaLegala.AppendChild(oXML.CreateElement("cbc:RegistrationName"))
	m.DenumireSocietate=AllTrim(ICAS.oSoc.Denumire)
	*
	If ParseDiacritics(m.DenumireSocietate, 1)=1
   		m.DenumireSocietate=ReplaceDiacritics(m.DenumireSocietate, 0)
   	EndIf
   	*	
	oFormaLegala.LastChild.Text = m.DenumireSocietate
	XML_CreateComment("BT-27", oFormaLegala.LastChild)
	*
	&& BT-30 BT-30-1		Identificatorul de inregistrare legala
	oIdentificatorFormaLegala = oFormaLegala.AppendChild(oXML.CreateElement("cbc:CompanyID"))
	*If  .Not. Empty(ICAS.oSoc.RegistruComertului)
	*
	If lnTipTvaCurent<3 And Not IsNullOrEmpty(ICAS.oSoc.RegistruComertului)
		oIdentificatorFormaLegala.Text = AllTrim(ICAS.oSoc.RegistruComertului)
	Else
		*oIdentificatorFormaLegala.Text = AllTrim(ICAS.oSoc.CodFiscal)
		oIdentificatorFormaLegala.Text = AllTrim(Nvl(ICAS.oSoc.RegistruComertului, ''))	&& 28.06.2024 STANIMIR
	EndIf
	XML_CreateComment("BT-30", oIdentificatorFormaLegala)
	*&& 30.07.2024
    IF Not IsNullOrEmpty(ICAS.oSoc.CapitalSocial)
        oFormaLegala.AppendChild(oXML.CreateElement("cbc:CompanyLegalForm"))
        oFormaLegala.LastChild.Text = "Capital social: "+AllTrim(Str(ICAS.oSoc.CapitalSocial, 15, 0))
        XML_CreateComment("BT-33", oFormaLegala.LastChild)
    ENDIF
	*&& 30.07.2024
	mDenSoc = Upper(ICAS.oSoc.Denumire)+" "
*!*		mPrefix = ""
*!*		mSufix = ""
*!*		*
*!*		mPrefix=GetSupplierCompanyLegalForm_Prefix()
*!*		mSufix=GetSupplierCompanyLegalForm_Sufix()
*!*		*
*!*		&& BT-33	Informatii juridice suplimentare
*!*		oFormaLegala.AppendChild(oXML.CreateElement("cbc:CompanyLegalForm"))
*!*		*oFormaLegala.LastChild.Text = IIf( .Not. Empty(mPrefix), mPrefix+", ", "")+IIf( .Not. Empty(mSufix), mSufix+", ", "")+IIf( .Not. Empty(ICAS.oSoc.CapitalSocial), "Capital social: "+AllTrim(Str(ICAS.oSoc.CapitalSocial, 15, 0)), "")
*!*		If Not Empty(mPrefix)
*!*			*// 31Martie20222
*!*			oFormaLegala.LastChild.Text = AllTrim(mPrefix)
*!*			*// 31Martie20222
*!*		EndIf	
	*
	If  .Not. Empty(ICAS.oSoc.NumePersoanaAutorizata) .Or.  .Not. Empty(ICAS.oSoc.PrenumePersoanaAutorizata) .Or.  .Not. Empty(ICAS.oSoc.Email) .Or.  .Not. Empty(ICAS.oSoc.Telefon)
		&& BG-6
		oContact = oParty.AppendChild(oXML.CreateElement("cac:Contact"))
		*
		If  .Not. Empty(ICAS.oSoc.NumePersoanaAutorizata) .Or.  .Not. Empty(ICAS.oSoc.PrenumePersoanaAutorizata)
			&& BT-41
			oContact.AppendChild(oXML.CreateElement("cbc:Name"))
			oContact.LastChild.Text = AllTrim(ICAS.oSoc.NumePersoanaAutorizata)+" "+AllTrim(ICAS.oSoc.PrenumePersoanaAutorizata)
			XML_CreateComment("BT-41", oContact.LastChild)
		EndIf
		*
		If  .Not. Empty(ICAS.oSoc.Telefon)
			&& BT-42
			oContact.AppendChild(oXML.CreateElement("cbc:Telephone"))
			oContact.LastChild.Text = AllTrim(ICAS.oSoc.Telefon)
			XML_CreateComment("BT-42", oContact.LastChild)
		EndIf
		*
		If  .Not. Empty(ICAS.oSoc.Email)
			&& BT-43
			oContact.AppendChild(oXML.CreateElement("cbc:ElectronicMail"))
			oContact.LastChild.Text = AllTrim(ICAS.oSoc.Email)
			XML_CreateComment("BT-43", oContact.LastChild)
		EndIf
		*
	EndIf
	*
	* TODO
	*oDelivery = oInvoice.AppendChild(oXML.CreateElement("cac:Delivery"))
	*oDeliveryLocation = oDelivery.AppendChild(oXML.CreateElement("cac:DeliveryLocation"))
	* TODO
	*
	Select crsEFactura
	Locate
	&& --BG-7 CUMPARATOR--
	oCustomer = oInvoice.AppendChild(oXML.CreateElement("cac:AccountingCustomerParty"))
	*
	*If Empty(crsEFactura.Email)
	*	MessageBox("Completati adresa de email a clientului."+Chr(13)+"Aceasta este necesara pentru primirea raspunsului facturii electronice.", 48, "Date incomplete...", 3000)
	*	Return "Completati adresa de email a clientului."	
	*	*** Return
	*EndIf
	*
	oPartys = oCustomer.AppendChild(oXML.CreateElement("cac:Party"))
	&& BT-49 BT-49-1
	If Not Empty(AllTrim(crsEFactura.Email))
		* NIC
		oEndpointId = oPartys.AppendChild(oXML.CreateElement("cbc:EndpointID"))
		oEndpointId.SetAttribute("schemeID", "EM")
		oEndpointId.Text = AllTrim(crsEFactura.Email)
		XML_CreateComment("BT-49", oEndpointId)
	EndIf
	*	
	oPartyIdentifications = oPartys.AppendChild(oXML.CreateElement("cac:PartyIdentification"))
	&& BT-46 BT-46-1
	oIdPartys = oPartyIdentifications.AppendChild(oXML.CreateElement("cbc:ID"))

*!*	Pt AUTOFACTURARE?
*!*		If  .Not. IsNullOrEmpty(crsEFactura.ID_eFact)
*!*			mCodGlnIdEfact = ChrTran(crsEFactura.Id_EFact, "/-,. ", "")
*!*			If Len(AllTrim(crsEFactura.Id_Efact))=13 .And. IsOnlyDigit(mCodGlnIdEfact) .And. CheckCB(mCodGlnIdEfact)
*!*				oIdPartys.SetAttribute("schemeID", "0088")
*!*			EndIf
*!*			oIdPartys.Text = AllTrim(crsEFactura.Id_EFact)
*!*		Else
*!*			oIdPartys.Text = AllTrim(crsEFactura.Cod_Fiscal)
*!*		EndIf

	*
	* WinMENTOR - Configurari cumparator
	*
	*Denumire partener (BT-45);
	*? Cod Fiscal (BT-48);
	*? Nr. reg. comertului (BT-46);
	* Adresa: localitate, judet, tara, strada completata at�t pe sediul principal, c�t si pe
	*sediul de livrare, daca acesta difera. (BT-50, BT-52, BT-54, BT-55)

	*https://docs.peppol.eu/poacc/billing/3.0/2024-Q2/syntax/ubl-invoice/cac-AccountingCustomerParty/cac-Party/cac-PartyIdentification/cbc-ID/
	*
	If ICAS.oSoc.MODPLATATVA = 3								&& emitent Neplatitor TVA
		oIdPartys.Text = OnlyNumber(crsEFactura.Cod_Fiscal)		&& Daca are "RO" in fata si emitetnul nu este platitor de TVA, da EROARE din Decembrie.2024
	Else
		oIdPartys.Text = crsEFactura.Cod_Fiscal
	EndIf
	*	
	XML_CreateComment("BT-46", oIdPartys)

	
	*
	&& <cac:PartyName>
	&&		<cbc:Name>Ministerul Finantelor</cbc:Name><!--BT-45-->
	&& </cac:PartyName>
	*
	&& BG-8
	oAdresas = oPartys.AppendChild(oXML.CreateElement("cac:PostalAddress"))
	***	oAdresas.Text = AllTrim(crsEFactura.CodPostal)		EROARE, nu se trece nimic
	*
	lcAdresa = GetAdresa('', '', '', Nvl(crsEFactura.Strada, ''), Nvl(crsEFactura.Nr_Str, ''), Nvl(crsEFactura.Bloc, ''), Nvl(crsEFactura.Scara, ''), Nvl(crsEFactura.Etaj, ''), Nvl(crsEFactura.Ap, ''),'', '')
	*If Empty(crsEFactura.Adresa)
	If Empty(lcAdresa)
		MessageBox("Completati adresa clientului.", 48, "Date incomplete...",3000)
		Return "Completati adresa clientului."
		Return
	EndIf
	*
	&& BT-50		Strada, numarul CUMPARATOR
	oAdresas.AppendChild(oXML.CreateElement("cbc:StreetName"))
	*oAdresas.LastChild.Text = AllTrim(crsEFactura.Adresa)
	oAdresas.LastChild.Text = AllTrim(lcAdresa)
	XML_CreateComment("BT-50", oAdresas.LastChild)
	*
	&& <cbc:AdditionalStreetName>Corpul A</cbc:AdditionalStreetName><!--BT-51-->
	*
	If Empty(crsEFactura.Localitate)
		MessageBox("Completati localitatea in adresa clientului.", 48, "Date incomplete...",3000)
		Return "Completati localitatea in adresa clientului."
		Return
	EndIf
	*
	&& BT-52		Localitatea CUMPARATOR
	If crsEFactura.Tara="RO"
		oAdresas.AppendChild(oXML.CreateElement("cbc:CityName"))
		*
		If crsEFactura.Judet="B " Or crsEFactura.Judet="BUCURESTI" OR crsEFactura.Judet="MUNICIPIUL BUCURESTI" 
			*
			Do Case
				*
				Case Not IsNullOrEmpty(AllTrim(crsEFactura.Sector))
					lcSector = 'SECTOR'+AllTrim(crsEFactura.Sector)
				*
				Case "SECTOR"$Upper(crsEFactura.Localitate)
					lcSector = AllTrim(crsEFactura.Localitate)
				*
				OtherWise
					lcSector = ''+AllTrim(crsEFactura.Sector)
				*	
			EndCase
			*
*!*				If  .Not. "SECTOR"$Upper(lcSector)
*!*					*MessageBox("Alegeti un sector valid pentru Bucuresti in adresa clientului.", 3000)
*!*					*Return "Alegeti un sector valid pentru Bucuresti in adresa clientului."				
*!*					lcSector = "SECTOR"+Right(AllTrim(crsEFactura.Localitate), 1)
*!*				EndIf
			*oAdresas.LastChild.Text = "SECTOR"+Right(AllTrim(crsEFactura.Localitate), 1)
			oAdresas.LastChild.Text = Upper(lcSector)
		Else
			oAdresas.LastChild.Text = AllTrim(crsEFactura.Localitate)
		EndIf
	Else
		If  .Not. Empty(crsEFactura.Localitate)
			oAdresas.AppendChild(oXML.CreateElement("cbc:CityName"))
			oAdresas.LastChild.Text = AllTrim(crsEFactura.Localitate)
		EndIf
	EndIf
	*
	XML_CreateComment("BT-52", oAdresas.LastChild)
	*
	If Empty(crsEFactura.Judet)
		MessageBox("Alegeti judetul clientului.", 48, "Date incomplete...", 3000)
		Return "Alegeti judetul clientului."		
		Return
	EndIf
	*
	&& <cbc:PostalZone>54321</cbc:PostalZone><!--BT-53-->		Codul postal CUMPARATOR
	*
	&& -BT-54		Subdiviziunea tarii  CUMPARATOR
	*
	If ll_Is_ICAS
		*
		Text To lcSQL NoShow TextMerge
			Select
				Cod
			From Configurari.Judete 
			Where
				DenJud=?crsEFactura.Judet
		EndText
		=mySQLExec(lcSQL, [crsSQLJudetePartener])
	Else
		Select Cod From Judete Where DenJud=crsEFactura.Judet Into Cursor crsSQLJudetePartener
	EndIf
	*
	Select * From crsSQLJudetePartener Into Array aGetJudAdresaPartener
	lcCodJudetPartener = ""
	*
	If _Tally>0 .And.  .Not. IsNull(aGetJudAdresaPartener(1))
		lcCodJudetPartener = aGetJudAdresaPartener(1)
	EndIf
	*	
	If crsEFactura.Tara="RO"
		oAdresas.AppendChild(oXML.CreateElement("cbc:CountrySubentity"))
		oAdresas.LastChild.Text = 'RO-'+AllTrim(lcCodJudetPartener)
	EndIf	
	*
	XML_CreateComment("BT-54", oAdresas.LastChild)
	*
	&& <cac:AddressLine>
	&& 	<cbc:Line>Camera212</cbc:Line><!--BT-163-->
	&& </cac:AddressLine>	
	*
	oTaras = oAdresas.AppendChild(oXML.CreateElement("cac:Country"))
	&& BT-55		Codul tarii	CUMPARATOR
	oTaras.AppendChild(oXML.CreateElement("cbc:IdentificationCode"))
	oTaras.LastChild.Text = IIf( .Not. Empty(crsEFactura.Tara), crsEFactura.Tara, "RO")
	XML_CreateComment("BT-55", oTaras.LastChild)
	*
*!*		If (Empty(crsEFactura.Tara) .Or. crsEFactura.Tara='RO') .And.  .Not. Empty(crsEFactura.Cod_Fiscal) .And. Len(AllTrim(crsEFactura.Cod_Fiscal))<12 .And. VerifCF(crsEFactura.Cod_Fiscal)
*!*			oTaxes = oPartys.AppendChild(oXML.CreateElement("cac:PartyTaxScheme"))
*!*			&& BT-48		Identificatorul de TVA CUMPARATOR
*!*			If lnTipTvaCurent<3
*!*				oTaxes.AppendChild(oXML.CreateElement("cbc:CompanyID"))
*!*				oTaxes.LastChild.Text = "RO"+GetNrFromString(crsEFactura.Cod_Fiscal)
*!*			EndIf	
*!*			*
*!*			oSchemaTaxes = oTaxes.AppendChild(oXML.CreateElement("cac:TaxScheme"))		&& ???
*!*			oSchemaTaxes.AppendChild(oXML.CreateElement("cbc:ID"))						&& ???
*!*			oSchemaTaxes.LastChild.Text = "VAT"											&& ???
*!*		Else
*!*			MessageBox("Momentan, factura electronica nu se emite catre persoane fizice.", 64, "Atentie...", 3000)
*!*			Return "Momentan, factura electronica nu se emite catre persoane fizice."
*!*			Return
*!*		EndIf
	*
	If crsEFactura.Tara='RO' .And.  .Not. IsNullOrEmpty(crsEFactura.Cod_Fiscal) .And. VerifCF(crsEFactura.Cod_Fiscal)
		If Len(AllTrim(crsEFactura.Cod_Fiscal))<12
			*oTaxes = oPartys.AppendChild(oXML.CreateElement("cac:PartyTaxScheme"))									&& 23Iunie2023
			*If lnTipTvaCurent<3		&& Deci nu trebuie trecut in cazul in care nu este platitor de tva
			IF (lnTipTvaCurent<3 .OR. lIsExceptii) .AND. "RO"$crsEFactura.Cod_Fiscal								&& 23Iunie2023
				oTaxes = oPartys.AppendChild(oXML.CreateElement("cac:PartyTaxScheme"))
				oTaxes.AppendChild(oXML.CreateElement("cbc:CompanyID"))
				oTaxes.LastChild.Text = AllTrim("RO"+OnlyNumber(crsEFactura.Cod_Fiscal))
				XML_CreateComment("BT-47", oTaxes.LastChild)
			*EndIf																									&& 23Iunie2023
				oSchemaTaxes = oTaxes.AppendChild(oXML.CreateElement("cac:TaxScheme"))
				oSchemaTaxes.AppendChild(oXML.CreateElement("cbc:ID"))
				oSchemaTaxes.LastChild.Text = "VAT"
				XML_CreateComment("BT-46", oSchemaTaxes.LastChild)
			EndIf																									&& 23Iunie2023
		EndIf
	Else
		oTaxes = oPartys.AppendChild(oXML.CreateElement("cac:PartyTaxScheme"))
		If crsEFactura.Tara<>'RO' .And.  .Not. IsNullOrEmpty(crsEFactura.Cod_Fiscal)
			oTaxes.AppendChild(oXML.CreateElement("cbc:CompanyID"))
			oTaxes.LastChild.Text = AllTrim(crsEFactura.Tara+StrTran(Upper(crsEFactura.Cod_Fiscal), crsEFactura.Tara, ""))
			XML_CreateComment("BT-47", oTaxes.LastChild)
		EndIf
		oSchemaTaxes = oTaxes.AppendChild(oXML.CreateElement("cac:TaxScheme"))
		If lnTipTvaCurent<3
			oSchemaTaxes.AppendChild(oXML.CreateElement("cbc:ID"))
			oSchemaTaxes.LastChild.Text = "VAT"
			XML_CreateComment("BT-46", oSchemaTaxes.LastChild)
		EndIf	
	EndIf
	*	
	oFormaLegalas = oPartys.AppendChild(oXML.CreateElement("cac:PartyLegalEntity"))
	*______________________
	*
	*	DETALII CUMPARATOR
	*______________________
	&& BT-44		Numele/ Denumirea
	oFormaLegalas.AppendChild(oXML.CreateElement("cbc:RegistrationName"))
	oFormaLegalas.LastChild.Text = AllTrim(crsEFactura.Den_Cli)
	XML_CreateComment("BT-44", oFormaLegalas.LastChild)
	*
	*If  .Not. Empty(crsEFactura.Reg_Com)
		&& BT-47 BT-47-1		Identificatorul de inregistrare legala  CUMPARATOR
	oIdentificatorFormaLegalas = oFormaLegalas.AppendChild(oXML.CreateElement("cbc:CompanyID"))
	*oIdentificatorFormaLegalas.Text = AllTrim(crsEFactura.Reg_Com)
	*oIdentificatorFormaLegalas.Text = AllTrim(crsEFactura.Cod_Fiscal)
	
	&&-- 26.11.2024
	If crsEFactura.Tara="RO"

        IF "RO" $ crsEFactura.Cod_Fiscal And Not IsNullOrEmpty(crsEFactura.Reg_Com)
        	*
        	If ICAS.oSoc.MODPLATATVA = 3											&& emitent Neplatitor TVA
        		oIdentificatorFormaLegalas.Text = OnlyNumber(crsEFactura.Cod_Fiscal)
        	Else
	            oIdentificatorFormaLegalas.Text = AllTrim(crsEFactura.Reg_Com)		&& eroare Cornelia la emitenti Neplatitori de TVA
	        EndIf
	        *
        ELSE
            oIdentificatorFormaLegalas.Text = AllTrim(crsEFactura.Cod_Fiscal)
        ENDIF

    ELSE

		*oIdentificatorFormaLegalas.SetAttribute("schemeID", "0028")				&& 17Octombrie2022
		oIdentificatorFormaLegalas.Text = AllTrim(crsEFactura.Tara+StrTran(Upper(crsEFactura.Cod_Fiscal), crsEFactura.Tara, ""))

    ENDIF	
	
	*
	*EndIf
	*
	XML_CreateComment("BT-47", oIdentificatorFormaLegalas)
	
	mDenSoc = AllTrim(crsEFactura.Den_Cli)+" "
*!*		mPrefix = ""
*!*		mSufix = ""
*!*		mPrefix=GetCustomerCompanyLegalForm_Prefix()
*!*		mSufix=GetCustomerCompanyLegalForm_Sufix()
*!*		*
*!*		*oFormaLegalas.AppendChild(oXML.CreateElement("cbc:CompanyLegalForm"))			&& ???
*!*		**oFormaLegalas.LastChild.Text = IIf( .Not. Empty(mPrefix), mPrefix+", ", "")+IIf( .Not. Empty(mSufix), mSufix+", ", "")+IIf( .Not. Empty(ICAS.oSoc.CapitalSocial), "Capital social: "+AllTrim(Str(ICAS.oSoc.CapitalSocial, 15, 0)), "")		&& ????
*!*		If .NOT. Empty(mPrefix)
*!*			*// 31Martie20222
*!*			oFormaLegalas.AppendChild(oXML.CreateElement("cbc:CompanyLegalForm"))			&& ???
*!*			*oFormaLegalas.LastChild.Text = IIf( .Not. Empty(mPrefix), mPrefix+", ", "")+IIf( .Not. Empty(mSufix), mSufix+", ", "")+IIf( .Not. Empty(ICAS.oSoc.CapitalSocial), "Capital social: "+AllTrim(Str(ICAS.oSoc.CapitalSocial, 15, 0)), "")		&& ????
*!*			oFormaLegalas.LastChild.Text = mPrefix
*!*			*// 31Martie20222
*!*		EndIf	
*!*		*
	If  .Not. Empty(crsEFactura.Telefon) .Or.  .Not. Empty(crsEFactura.Email) .Or.  .Not. Empty(crsEFactura.Delegat)
		*
		oContacts = oPartys.AppendChild(oXML.CreateElement("cac:Contact"))
		*
		If  .Not. Empty(crsEFactura.Delegat)
			&& BT-56
			oContacts.AppendChild(oXML.CreateElement("cbc:Name"))
			oContacts.LastChild.Text = AllTrim(crsEFactura.Delegat)
			XML_CreateComment("BT-56", oContacts.LastChild)
		EndIf
		If  .Not. Empty(crsEFactura.telefon)
			&& BT-57
			oContacts.AppendChild(oXML.CreateElement("cbc:Telephone"))
			oContacts.LastChild.Text = AllTrim(crsEFactura.Telefon)
			XML_CreateComment("BT-57", oContacts.LastChild)
		EndIf
		If  .Not. Empty(crsEFactura.Email)
			&& BT-58
			oContacts.AppendChild(oXML.CreateElement("cbc:ElectronicMail"))
			oContacts.LastChild.Text = AllTrim(crsEFactura.Email)
			XML_CreateComment("BT-58", oContacts.LastChild)
		EndIf
		*
	EndIf
	*
	* Adrese de livrare
	*
	*#-- 17IUNIE2022
	*
	Select crsEFactura
	*
	If RecCount("C_INCASARI_EFACT")>0 .And. ICas.oSettings.IsPS=.F.
		*
		Select c_Incasari_eFact
		*
		Scan
			*
			mCodInstrumentPlata			= ""
			mDenumireInstrumentPlata	= ""
			mExplicatie					= AllTrim(c_Incasari_eFact.Explicatie)
			mExplicatieInstrumentPlata	= ""
			mNumarDocument				= AllTrim(c_Incasari_eFact.Ndp)
			*
			Do Case
					*
				Case c_Incasari_eFact.ContD='532' .Or. c_Incasari_eFact.ContC='532'
					mCodInstrumentPlata = "26"
					mDenumireInstrumentPlata = "Local cheque"
					mExplicatieInstrumentPlata = "VOUCHER"
					*
				Case c_Incasari_eFact.ContD='5125' .Or. c_Incasari_eFact.ContC='5125'
					mCodInstrumentPlata = "48"
					mDenumireInstrumentPlata = "Bank card"
					mExplicatieInstrumentPlata = "Virament bancar"
					*
				Case c_Incasari_eFact.ContD='512' .Or. c_Incasari_eFact.ContC='512'
					mCodInstrumentPlata = "42"
					mDenumireInstrumentPlata = "Bank"
					mExplicatieInstrumentPlata = "Virament bancar"
					*
				Case c_Incasari_eFact.ContD='531' .Or. c_Incasari_eFact.ContC='531'
					mCodInstrumentPlata = "10"
					mDenumireInstrumentPlata = "In cash"
					mExplicatieInstrumentPlata = "Numerar"
					*
				Case c_Incasari_eFact.ContD='413' .Or. c_Incasari_eFact.ContC='413'
					mCodInstrumentPlata = "20"
					mDenumireInstrumentPlata = "Cheque "
					*
				Case c_Incasari_eFact.ContD='401'
					mCodInstrumentPlata = "97"
					mDenumireInstrumentPlata = "Clearing between partners"
					mExplicatieInstrumentPlata = "Compensare"
			EndCase
			*
			#if .f.
			E: validari globale
			 SCHEMATRON 
			 eroare: [UBL-CR-414]-A UBL invoice should not include the PaymentMeans InstructionID
			E: validari globale
			 SCHEMATRON 
			 eroare: [UBL-CR-681]-A UBL invoice should not include the PaymentMeans InstructionNote			
			#endif
			*	###   TODO
			*	###   si pt tlIsAutoFactura
*!*				If  .Not. Empty(mCodInstrumentPlata) .And.  .Not. Empty(c_Incasari_eFact.Ndp)
*!*					oPaymentMeans = oInvoice.AppendChild(oXML.CreateElement("cac:PaymentMeans"))
*!*					PaymentMeansCode = oPaymentMeans.AppendChild(oXML.CreateElement("cbc:PaymentMeansCode"))
*!*					PaymentMeansCode.SetAttribute("name", mDenumireInstrumentPlata)
*!*					PaymentMeansCode.Text = mCodInstrumentPlata
*!*					oPaymentMeans.AppendChild(oXML.CreateElement("cbc:InstructionNote"))
*!*					oPaymentMeans.LastChild.Text = mExplicatieInstrumentPlata
*!*					oPaymentMeans.AppendChild(oXML.CreateElement("cbc:PaymentID"))
*!*					oPaymentMeans.LastChild.Text = AllTrim(c_Incasari_eFact.Ndp)
*!*				EndIf
			*
		EndScan
		*
	EndIf
	*
	*--	27.06.2024 STANIMIR		
	*	Detalii Cont Banca
	*
	If ll_Is_ICAS
		*
		mySQLExec([Select * From vBanci], [vBanci])	
		Select c.ID As IdBanca, c.Denumire, c.ContBanca From crsEFactura e Inner Join vBanci c On e.IdBanca1 = c.Id Where IdBanca1>0;
		Union All;
		Select c.ID As IdBanca, c.Denumire, c.ContBanca	From crsEFactura e Inner Join vBanci c On e.IdBanca2 = c.Id Where IdBanca2>0;
		Union All;
		Select c.ID As IdBanca, c.Denumire, c.ContBanca From crsEFactura e Inner Join vBanci c On e.IdBanca3 = c.Id Where IdBanca3>0;
		Union All;
		Select c.ID As IdBanca, c.Denumire, c.ContBanca From crsEFactura e Inner Join vBanci c On e.IdBanca4 = c.Id Where IdBanca4>0;
		Into Cursor cGetBanciVANZATOR
	Else
		Create Cursor cGetBanciVANZATOR( Id Int, Denumire C(50), ContBanca C(24) )
		Insert Into cGetBanciVANZATOR( Id, Denumire, ContBanca) Values (1, _cBanca1,  _cContu1)
		Insert Into cGetBanciVANZATOR( Id, Denumire, ContBanca) Values (1, _cBanca2,  _cContu2)
	EndIf	
	*
	If _Tally>0
		*
		Scan
			*
			mContBanca = AllTrim(cGetBanciVANZATOR.ContBanca)
			*
			If IsNullOrEmpty(mContBanca)
				mIbanValid =''
			Else	
				mIbanValid = GetIbanFromString(mContBanca, 1)
			EndIf	
			*
			If  .Not. IsNullOrEmpty(AllTrim(mIbanValid))
				*
				mContBanca								= SubStr(mContBanca, At(mIbanValid, mContBanca)+Len(mIbanValid))
				mBanca									= GetBanca(mIbanValid)		&& cGetBanciVANZATOR.Denumire
				oPaymentMeans							= oInvoice.AppendChild(oXML.CreateElement("cac:PaymentMeans"))
				oPaymentMeansCode						= oPaymentMeans.AppendChild(oXML.CreateElement("cbc:PaymentMeansCode"))
				*oPaymentMeansCode.Text					= 48		&& CARD
				
				*If Type('mCodInstrumentPlata')='U'
					oPaymentMeansCode.Text					= 42		&& Plata in cont bancar (10 plata in casa)
				*Else	
				*	PaymentMeansCode.Text					= Iif( !Empty(mCodInstrumentPlata), mCodInstrumentPlata, 42 )	&& 06.05.2025
				*EndIf
				*	
				XML_CreateComment("BT-81", oPaymentMeansCode)
				oPayeeFinancialAccount					= oPaymentMeans.AppendChild(oXML.CreateElement("cac:PayeeFinancialAccount"))
				oPayeeFinancialAccount.AppendChild(oXML.CreateElement("cbc:ID"))
				oPayeeFinancialAccount.LastChild.Text	= AllTrim(mIbanValid)
				XML_CreateComment("BT-84", oPayeeFinancialAccount.LastChild)
				*
				If  .Not. Empty(AllTrim(mBanca))
					oPayeeFinancialAccount.AppendChild(oXML.CreateElement("cbc:Name"))
					oPayeeFinancialAccount.LastChild.Text = AllTrim(mBanca)
					XML_CreateComment("BT-85", oPayeeFinancialAccount.LastChild)
				EndIf
				*
			EndIf
			*
		EndScan
		*
	EndIf
	*
	*--	27.06.2024 STANIMIR
	*
	*#-- 17IUNIE2022
	*
	Select crsEFactura
	*
	If lnLiniiReducere>0
		Select crsEFactura
		Scan For Indice=-1
			&& <!-- BG-21 TAXE SUPLIMENTARE-->
			oAllowanceCharge = oInvoice.AppendChild(oXML.CreateElement("cac:AllowanceCharge"))
			oAllowanceCharge.AppendChild(oXML.CreateElement("cbc:ChargeIndicator"))
			oAllowanceCharge.LastChild.Text = "false"
			XML_CreateComment("CI-92", oAllowanceCharge.LastChild)
			&& BT-105
			oAllowanceCharge.AppendChild(oXML.CreateElement("cbc:AllowanceChargeReasonCode"))
			oAllowanceCharge.LastChild.Text = "95"
			XML_CreateComment("BT-105", oAllowanceCharge.LastChild)
			&& BT-104
			oAllowanceCharge.AppendChild(oXML.CreateElement("cbc:AllowanceChargeReason"))
			*
			&& Vicos.12.02.2024
			*
			*oAllowanceCharge.LastChild.Text = IIf(crsEFactura.Cont="667", "Scont", IIf(crsEFactura.Cont="709", "Reducere comerciala", "Discount"))
			If tlIsAutoFactura
				oAllowanceCharge.LastChild.Text = IIf(crsEFactura.Cont="767", "Scont", IIf(crsEFactura.Cont="609", "Reducere comerciala", "Discount"))
			Else
				oAllowanceCharge.LastChild.Text = IIf(crsEFactura.Cont="667", "Scont", IIf(crsEFactura.Cont="709", "Reducere comerciala", "Discount"))
			EndIf	
			*
			XML_CreateComment("BT-104", oAllowanceCharge.LastChild)
			*
			&& Vicos.12.02.2024
			*
			*
			&& <cbc:MultiplierFactorNumeric>10.00</cbc:MultiplierFactorNumeric><!--BT-101-->
			*
			oDocAllowanceCharge = oAllowanceCharge.AppendChild(oXML.CreateElement("cbc:Amount"))
			&& BT-99
			oDocAllowanceCharge.SetAttribute("currencyID", lcMoneda)
			*oDocAllowanceCharge.Text = AllTrim(Str(Abs(crsEFactura.Valoare), 15, 2))
			oDocAllowanceCharge.Text = AllTrim(Str(Abs(crsEFactura.Valoare), 15, 2))			&&-- 05.11.2024 
			XML_CreateComment("BT-99", oDocAllowanceCharge)
			*
			&& <cbc:BaseAmount currencyID="RON">1500</cbc:BaseAmount><!--BT-100-->
			*
			oTaxCategoryAllowance = oAllowanceCharge.AppendChild(oXML.CreateElement("cac:TaxCategory"))
			&& BT-102
			oTaxCategoryAllowance.AppendChild(oXML.CreateElement("cbc:ID"))
			
			*
			Select Tip From crsTva_EFactura Where ProcTva=crsEFactura.ProcTva Into Array aGetTipCota
			*
			oTaxCategoryAllowance.LastChild.Text = AllTrim(aGetTipCota(1))
			XML_CreateComment("BT-102", oTaxCategoryAllowance.LastChild)
			*
			&& BT-103
			If aGetTipCota(1)<>'O'
				oTaxCategoryAllowance.AppendChild(oXML.CreateElement("cbc:Percent"))
				oTaxCategoryAllowance.LastChild.Text = AllTrim(Str(crsEFactura.ProcTva, 2, 0))
				XML_CreateComment("BT-103", oTaxCategoryAllowance.LastChild)
			EndIf
			*
			oTaxSchemeAllowance = oTaxCategoryAllowance.AppendChild(oXML.CreateElement("cac:TaxScheme"))
			oTaxSchemeAllowance.AppendChild(oXML.CreateElement("cbc:ID"))
			oTaxSchemeAllowance.LastChild.Text = "VAT"
			*???XML_CreateComment("BT-???", oTaxCategoryAllowance.LastChild)
		EndScan
	EndIf
	*
	&& !-- BG-20 DEDUCERI--
	*
	Select crsEFactura
	*
	If lnAccize>0
		&& BG-20
		oAllowanceCharge = oInvoice.AppendChild(oXML.CreateElement("cac:AllowanceCharge"))
		oAllowanceCharge.AppendChild(oXML.CreateElement("cbc:ChargeIndicator"))
		oAllowanceCharge.LastChild.Text = "true"
		XML_CreateComment("CI-92", oAllowanceCharge.LastChild)
		&& BT-98
		oAllowanceCharge.AppendChild(oXML.CreateElement("cbc:AllowanceChargeReason"))
		oAllowanceCharge.LastChild.Text = "Acciza"
		XML_CreateComment("BT-98", oAllowanceCharge.LastChild)
		*
		&& <cbc:AllowanceChargeReason>Loyal customer</cbc:AllowanceChargeReason><!--BT-97-->
		&& <cbc:MultiplierFactorNumeric>10.00</cbc:MultiplierFactorNumeric><!--BT-94-->
		&& BT-92
		oDocAllowanceCharge = oAllowanceCharge.AppendChild(oXML.CreateElement("cbc:Amount"))
		oDocAllowanceCharge.SetAttribute("currencyID", lcMoneda)
		oDocAllowanceCharge.Text = AllTrim(Str(lnAccize, 15, 2))
		*XML_CreateComment("BT-92", oAllowanceCharge.LastChild)
		*
		oTaxCategoryCharge = oAllowanceCharge.AppendChild(oXML.CreateElement("cac:TaxCategory"))
		&& BT-95
		oTaxCategoryCharge.AppendChild(oXML.CreateElement("cbc:ID"))
		If lnTipTvaCurent<3
			oTaxCategoryCharge.LastChild.Text = "Z"
			XML_CreateComment("BT-95", oTaxCategoryCharge.LastChild)
			&& BT-96
			oTaxCategoryCharge.AppendChild(oXML.CreateElement("cbc:Percent"))
			oTaxCategoryCharge.LastChild.Text = "0"
			XML_CreateComment("BT-96", oTaxCategoryCharge.LastChild)
		Else
			oTaxCategoryCharge.LastChild.Text = "O"
			XML_CreateComment("BT-95", oTaxCategoryCharge.LastChild)
		EndIf
		*
		oTaxSchemeAllowance = oTaxCategoryCharge.AppendChild(oXML.CreateElement("cac:TaxScheme"))
		oTaxSchemeAllowance.AppendChild(oXML.CreateElement("cbc:ID"))
		oTaxSchemeAllowance.LastChild.Text = "VAT"
	EndIf
	*
*!*		XML_CreateComment("BT-96", oTaxCategoryCharge.LastChild)
*!*	AICI AM RAMAS
	*
	If RecCount("crsTva_EFactura")>0
		oTaxTotal		= oInvoice.AppendChild(oXML.CreateElement("cac:TaxTotal"))
		mTvaTotal		= 000000000.00
		mTvaTotalLei	= 000000000.00 
		Select crsTva_EFactura
		*If  .NOT. InList(lcTipFactura, "U", "H")
		*	*Sum (Round(Valoare*ProcTva/100, 2)) To mTvaTotal
		*	Sum (Tva) TO mTvaTotal 
		*Else
		*	Sum (Tva) TO mTvaTotal 
		*EndIf
		*
		Sum Tva, TvaLei  TO mTvaTotal,  mTvaTotalLei
		oTotal = oTaxTotal.AppendChild(oXML.CreateElement("cbc:TaxAmount"))
		&& BT-110 /	BT-111		Valoare totala TVA	/	Moneda
		oTotal.SetAttribute("currencyID", lcMoneda)
		*oTotal.Text = AllTrim(Str(Round(mTvaTotal*1, 2), 15, 2))
		oTotal.Text = AllTrim(Str(mTvaTotal, 15, 2))
		*
		Select crsTva_EFactura
		Set Order To procent
		Locate
		*
		Scan
			&& BG-23(1)		DETALIERE TVA (BG-23)
			oTaxableSubTotal = oTaxTotal.AppendChild(oXML.CreateElement("cac:TaxSubtotal"))
			oSubTotal = oTaxableSubTotal.AppendChild(oXML.CreateElement("cbc:TaxableAmount"))
			&& BT-116		Baza de calcul pentru categoria de TVA
			oSubTotal.SetAttribute("currencyID", lcMoneda)
			oSubTotal.Text = AllTrim(Str(crsTva_EFactura.Valoare, 15, 2))
			oSubTotalTaxa = oTaxableSubTotal.AppendChild(oXML.CreateElement("cbc:TaxAmount"))
			&& BT-117		Valoarea TVA pentru fiecare categorie de TVA 
			oSubTotalTaxa.SetAttribute("currencyID", lcMoneda)
			oSubTotalTaxa.Text = AllTrim(Str(crsTva_EFactura.Tva, 15, 2))
			*
			oTaxCategoryTotals = oTaxableSubTotal.AppendChild(oXML.CreateElement("cac:TaxCategory"))
			&& BT-118		Categoria de TVA 
			oTaxCategoryTotals.AppendChild(oXML.CreateElement("cbc:ID"))
			oTaxCategoryTotals.LastChild.Text = AllTrim(crsTva_EFactura.Tip)
			&& BT-119		Cota TVA
			*If  .NOT. InList(crsTva_EFactura.Tip, "O", "Z")
			If  .NOT. InList(crsTva_EFactura.Tip, "O")
				oTaxCategoryTotals.AppendChild(oXML.CreateElement("cbc:Percent"))
				oTaxCategoryTotals.LastChild.Text = AllTrim(Str(crsTva_EFactura.ProcTva, 2, 0))
			EndIf	
			*
			If  .Not. Empty(crsTva_EFactura.Explicatie)
				&& BT-121			Motiv scutire TVA 									NU E OBLIGATORIU
				* VATEX-EU-79-C		- Exempt based on article 79, point c of Coun
				* VATEX-EU-132		- Exempt based on article 132 of Counc
				* VATEX-EU-132-1A	- Exempt based on article 132, secti
				* VATEX-EU-132-1B	- Exempt based on article 132, section
				* etc, https://www.anaf.ro/CompletareFactura/faces/factura/produse.xhtml
				oTaxCategoryTotals.AppendChild(oXML.CreateElement("cbc:TaxExemptionReasonCode"))
				oTaxCategoryTotals.LastChild.Text = AllTrim(crsTva_EFactura.Motiv)
			EndIf
			*
			If  .Not. Empty(crsTva_EFactura.Motiv)
				&& BT-120
				oTaxCategoryTotals.AppendChild(oXML.CreateElement("cbc:TaxExemptionReason"))
				oTaxCategoryTotals.LastChild.Text = AllTrim(crsTva_EFactura.Explicatie)
			EndIf
			*s
			oTaxSchemeTotals = oTaxCategoryTotals.AppendChild(oXML.CreateElement("cac:TaxScheme"))
			oTaxSchemeTotals.AppendChild(oXML.CreateElement("cbc:ID"))
			oTaxSchemeTotals.LastChild.Text = "VAT"
		EndScan
		*
		Select crsEFactura
		Locate
		If lcMoneda<>"RON"
			oTaxTotal = oInvoice.AppendChild(oXML.CreateElement("cac:TaxTotal"))		&& ???? TVA-ul trebuie raportat in lei
			&& BT-117
			oTotal = oTaxTotal.AppendChild(oXML.CreateElement("cbc:TaxAmount"))
			oTotal.SetAttribute("currencyID", "RON")
			oTotal.Text = Str(mTvaTotalLei, 15, 2)
			*oTotal.Text = AllTrim(Str(Round(mTvaTotal*crsEFactura.Curs, 2), 15, 2))
			
		EndIf
		*
	EndIf
	*
	Select crsEFactura
	Locate
	*Sum Valoare To lnTotalNet
	Sum Valoare To lnTotalNet For Indice>=0		&& 05Ianuarie2021
	Locate
	lnTotalNetLiniiFactura = lnTotalNet
	lnTotalNet = lnTotalNet+lnTotalCharges-lnTotalAllowances
	lnTotalBrut = lnTotalNet+lnTotalTva
	&& BG-22
	oMonetaryTotal = oInvoice.AppendChild(oXML.CreateElement("cac:LegalMonetaryTotal"))
	oTotalNet = oMonetaryTotal.AppendChild(oXML.CreateElement("cbc:LineExtensionAmount"))
	&& BT-106
	oTotalNet.SetAttribute("currencyID", lcMoneda)
	oTotalNet.Text = AllTrim(Str(lnTotalNetLiniiFactura, 15, 2))
	oTotalNetFaraTva = oMonetaryTotal.AppendChild(oXML.CreateElement("cbc:TaxExclusiveAmount"))
	&& BT-109		Total baza calcul TVA
	oTotalNetFaraTva.SetAttribute("currencyID", lcMoneda)
	oTotalNetFaraTva.Text = AllTrim(Str(lnTotalNet, 15, 2))
	oTotalBrut = oMonetaryTotal.AppendChild(oXML.CreateElement("cbc:TaxInclusiveAmount"))
	&& BT-112		Valoare totala
	oTotalBrut.SetAttribute("currencyID", lcMoneda)
	oTotalBrut.Text = AllTrim(Str(lnTotalBrut, 15, 2))
	If lnTotalAllowances>0
		oTotalDeduceri = oMonetaryTotal.AppendChild(oXML.CreateElement("cbc:AllowanceTotalAmount"))
		&& BT-107
		oTotalDeduceri.SetAttribute("currencyID", lcMoneda)
		oTotalDeduceri.Text = AllTrim(Str(lnTotalAllowances, 15, 2))
	EndIf
	*
	If lnTotalCharges>0
		oTotalTaxe = oMonetaryTotal.AppendChild(oXML.CreateElement("cbc:ChargeTotalAmount"))
		&& BT-108
		oTotalTaxe.SetAttribute("currencyID", lcMoneda)
		oTotalTaxe.Text = AllTrim(Str(lnTotalCharges, 15, 2))
	EndIf
	*
	If lnTotalBrut >= 0
		lnIncasat = 0
	EndIf	
	*
	If lnIncasat<>0
		oTotalIncasat = oMonetaryTotal.AppendChild(oXML.CreateElement("cbc:PrepaidAmount"))
		&& BT-113
		oTotalIncasat.SetAttribute("currencyID", lcMoneda)
		oTotalIncasat.Text = AllTrim(Str(lnIncasat, 15, 2))
	EndIf
	*
	&& <cbc:PayableRoundingAmount currencyID="RON">0.30</cbc:PayableRoundingAmount><!--BT-114-->
	*
	oTotalPlata = oMonetaryTotal.AppendChild(oXML.CreateElement("cbc:PayableAmount"))
	&& BT-115		Total de plata 
	oTotalPlata.SetAttribute("currencyID", lcMoneda)
	oTotalPlata.Text = AllTrim(Str(lnTotalBrut-lnIncasat, 15, 2))
	*
	* Check_CoduriArticole_ERR()																						&& 12Iunie2023
	*
	Select crsEFactura
	Count For Indice=0 TO LiniiProduse
	*
	If LiniiProduse=0
		*
		oInvoiceLine = oInvoice.AppendChild(oXML.CreateElement("cac:InvoiceLine"))
		*
	Else
		*
		&& <!--BG-25(1)-->
		Scan For Indice=0
			&& BG-25(1)
			oInvoiceLine = oInvoice.AppendChild(oXML.CreateElement("cac:InvoiceLine"))
			&& BT-126
			oInvoiceLine.AppendChild(oXML.CreateElement("cbc:ID"))
			oInvoiceLine.LastChild.Text = AllTrim(Str(i, 5, 0))
			If  .Not. IsNullOrEmpty(AllTrim(crsEFactura.Text_Supl))
				&& BT-127		Nota liniei facturii
				oInvoiceLine.AppendChild(oXML.CreateElement("cbc:Note"))
				*oInvoiceLine.LastChild.Text = AllTrim(crsEFactura.Text_Supl)
				oInvoiceLine.LastChild.Text = SubStr(AllTrim(crsEFactura.Text_Supl), 1, Min(Len(AllTrim(crsEFactura.Text_Supl)), 300))
				*lcNote_InvoiceLine = AllTrim(StrTran(crsEFactura.Text_Supl, CHR(13), ';'))
	            *If ParseDiacritics(lcNote_InvoiceLine, 1)=1
	            *    lcNote_InvoiceLine = ReplaceDiacritics(lcNote_InvoiceLine)
	            *EndIf
	            *oInvoiceLine.LastChild.Text = lcNote_InvoiceLine
            				
			EndIf
			*
			If ll_Is_ICAS
				*
				Text To lcSQL NoShow TextMerge
					Select * From UM
				EndText
				=mySQLExec(lcSQL, [crsUM]) 
				*
			Else
				*
				If Not File(ExpDir+'UM_EFA.csv')
					*
					*cod,cod_ro,denumire,indice,indivizib
					Text To lcSQL NoShow TextMerge
"H87","BUC","Bucata",2,1
"KGM","KG","Kilogram",4,0
"LTR","LITRI","Litru",6,0
"MTR","M","Metru",8,0
"GRM","GRAME","Gram",10,0
"XBX","CUTII","Cutie",12,1
"XPK","PAC","Pachet",14,1
"XPO","PUNGI","Punga",15,1
"SET","SET","Set",16,1
"MTK","MP","Metru patrat",18,0
"MTQ","MC","Metru cub",20,0
"MMT","MM","Milimetru",22,0
"CMT","CM","Centimetru",23,0
"TNE","TONE","Tona",24,0
"PR","PER","Pereche",26,1
"XSA","SACI","Sac",28,1
"MLT","ML","Mililitru",30,0
"KWH","KWH","Kilowatt ora",32,0
"HUR","ORE","Ora",34,0
"MIN","MIN","Minut",36,0
"DAY","ZILE","Zi de lucru",38,0
"MON","LUNI","Luni de lucru",39,0
"E27","DOZE","Doza",40,1
"E48","SERV","Unitate de service",44,0
"T3","1000B","O mie de bucati",50,0
"QTR","TRIM","Trimestru",52,1
"P1","PROC","Procent",54,0
"KMT","KM","Kilometru",56,0
"XCR","LADA","Lada",58,0
					EndText
					*
					StrToFile(lcSQL, ExpDir+'UM_EFA.csv')
				EndIf	
				*
				*Create Cursor crsUm(Um C(5), Specificatie C(20), Indice N(5), Cod C(3), Indivizib L(1))
				Create Cursor crsUM(Cod C(3), UM C(5), Denumire C(20),	Indice N(3), Indivizib  N(1))				
				Append From (ExpDir+'UM_EFA.csv') Delimited With Char ','
				*
			EndIf
			*	
			Select Cod From crsUM Where Um=crsEFactura.Um Into Array aGetUmFact
			mUm = "H87"
			If _Tally>0 .And.  .Not. IsNull(aGetUmFact(1))
				mUm = AllTrim(aGetUmFact(1))
			EndIf
			&& BT-129 /	BT-130			Cantitatea facturata	/	Unitatea de masura
			oUm = oInvoiceLine.AppendChild(oXML.CreateElement("cbc:InvoicedQuantity"))
			oUm.SetAttribute("unitCode", mUm)
			oUm.Text = AllTrim(Str(crsEFactura.Cantitate, 15, 3))
			&& BT-131		Valoarea neta
			oAmount = oInvoiceLine.AppendChild(oXML.CreateElement("cbc:LineExtensionAmount"))
			oAmount.SetAttribute("currencyID", lcMoneda)
			oAmount.Text = AllTrim(Str(crsEFactura.Valoare, 15, 2))
			*
			&& <cbc:AccountingCost>BookingCode001</cbc:AccountingCost><!--BT-133-->		Referinta contabila
			&& <cac:InvoicePeriod><!--BG-26-->
			&& 		<cbc:StartDate>2021-09-05</cbc:StartDate><!--BT-134-->
			&& 		<cbc:EndDate>2021-10-05</cbc:EndDate><!--BT-135-->
			&& </cac:InvoicePeriod>
			*		
	*!*			Select * From crs_Comenzi_EFactura Where IdUnic=crsEFactura.IdUnic Into Array aGetComenziLinie
	*!*			If _Tally>0 .And.  .Not. IsNull(aGetComenziLinie(1, 2)) .And.  .Not. IsNull(aGetComenziLinie(1, 3))
	*!*				oOrderLineReference = oInvoiceLine.AppendChild(oXML.CreateElement("cac:OrderLineReference"))
	*!*				&&BT-132-
	*!*				oOrderLineReference.AppendChild(oXML.CreateElement("cbc:LineID"))
	*!*				oOrderLineReference.LastChild.Text = AllTrim(aGetComenziLinie(1, 2))+"/"+AllTrim(DToC(aGetComenziLinie(1, 3)))
	*!*			EndIf
			*
			&& <cac:DocumentReference>
			&& 	<cbc:ID schemeID="AAA">11234</cbc:ID><!--BT-128-->
			&& </cac:DocumentReference>
			&& <cac:AllowanceCharge><!--BG-27 deducere-->
			&& 	<cbc:ChargeIndicator>false</cbc:ChargeIndicator>
			&& 	<cbc:AllowanceChargeReasonCode>100</cbc:AllowanceChargeReasonCode><!--BT-140-->
			&& 	<cbc:AllowanceChargeReason>Loyal customer</cbc:AllowanceChargeReason><!--BT-139-->
			&& 	<cbc:MultiplierFactorNumeric>10.00</cbc:MultiplierFactorNumeric><!--BT-138-->
			&& 	<cbc:Amount currencyID="RON">150</cbc:Amount><!--BT-136-->
			&& 	<cbc:BaseAmount currencyID="RON">1500</cbc:BaseAmount><!--BT-137-->
			&& </cac:AllowanceCharge>
			&& <cac:AllowanceCharge><!--BG-28 taxa suplimentara-->
			&& 	<cbc:ChargeIndicator>true</cbc:ChargeIndicator>
			&& 	<cbc:AllowanceChargeReasonCode>ABL</cbc:AllowanceChargeReasonCode><!--BT-145-->
			&& 	<cbc:AllowanceChargeReason>Packing cost</cbc:AllowanceChargeReason><!--BT-144-->
			&& 	<cbc:MultiplierFactorNumeric>10.00</cbc:MultiplierFactorNumeric><!--BT-143-->
			&& 	<cbc:Amount currencyID="RON">150</cbc:Amount><!--BT-141-->
			&& 	<cbc:BaseAmount currencyID="RON">1500</cbc:BaseAmount><!--BT-142-->
			&& </cac:AllowanceCharge>
			*
			&& BG-31
			oItem = oInvoiceLine.AppendChild(oXML.CreateElement("cac:Item"))
			If  .Not. Empty(crsEFactura.Is_A)
				&& BT-154		Descrierea articolului
				oItem.AppendChild(oXML.CreateElement("cbc:Description"))
				oItem.LastChild.Text = AllTrim(crsEFactura.Is_A)
			EndIf
			*
			If  .Not. Empty(crsEFactura.Denumire)
				&& BT-153		Numele articolului
				oItem.AppendChild(oXML.CreateElement("cbc:Name"))
				oItem.LastChild.Text = AllTrim(crsEFactura.Denumire)
			Else
				MessageBox("Completati denumirea produselor/serviciilor din factura.", 48, "Date incomplete...",3000)
				Return "Completati denumirea produselor/serviciilor din factura."
				Return
			EndIf
			*
			*If  .Not. Empty(crsEFactura.Cod_Art_Cl)
			If  .Not. Empty(crsEFactura.Cod_Art_Cl) And Not tlIsAutoFactura			&& Vicos.12.02.2024
				oBuyerItem = oItem.AppendChild(oXML.CreateElement("cac:BuyersItemIDentification"))
				&& BT-156
				oBuyerItem.AppendChild(oXML.CreateElement("cbc:ID"))
				oBuyerItem.LastChild.Text = crsEFactura.Cod_Art_Cl
			EndIf
			*
			If  .Not. Empty(crsEFactura.Cod)
				&& 	<cac:Item> 
				&& 		<cbc:Name>Returned "Advanced computing" book</cbc:Name> 
				&& 		<cac:SellersItemIdentification> 
				&& 			<cbc:ID>JB008</cbc:ID> 
				&& 		</cac:SellersItemIdentification> 
				&& 		<cac:StandardItemIdentification> 
				&& 			<cbc:ID schemeID="0088">1234567890135</cbc:ID> 
				&& 		</cac:StandardItemIdentification> 
				&& 		<cac:CommodityClassification> 
				&& 			<cbc:ItemClassificationCode listID="ZZZ">32344324</cbc:ItemClassificationCode> 
				&& 		</cac:CommodityClassification> 
				&& 		<cac:CommodityClassification> 
				&& 			<cbc:ItemClassificationCode listID="STI">65434567</cbc:ItemClassificationCode> 
				&& 		</cac:CommodityClassification> 
				&& 		<cac:ClassifiedTaxCategory> 
				&& 			<cbc:ID>S</cbc:ID> 
				&& 			<cbc:Percent>20</cbc:Percent> 
				&& 			<cac:TaxScheme> 
				&& 				<cbc:ID>VAT</cbc:ID> 
				&& 			</cac:TaxScheme> 
				&& 		</cac:ClassifiedTaxCategory> 
				&& 	</cac:Item>
				oSellerItem = oItem.AppendChild(oXML.CreateElement("cac:SellersItemIdentification"))	&& Posibil COD de BARE
				&& BT-155
				oSellerItem.AppendChild(oXML.CreateElement("cbc:ID"))
				If ll_Is_ICAS
					oSellerItem.LastChild.Text = AllTrim(Str(crsEFactura.Cod))
				Else
					oSellerItem.LastChild.Text = AllTrim(crsEFactura.Cod)
				EndIf
				*				
			EndIf
			*
			If ICAS.oSettings.lIsi
				*
				cListIdArticole='0'
				ln_IdDoc_EFactura = crsEFactura.IdDoc
				*
				If lcAlias='IESIRI'
					Text To lcSQL NoShow TextMerge
						Select
							IdArticol
						From IesiriDetaliat
						Where
							IdDoc=?ln_IdDoc_EFactura
							And IsNull(IdArticol, 0)>0
					EndText
				Else
					Text To lcSQL NoShow TextMerge
						Select
							IdArticol
						From ExportDetaliat
						Where
							IdDoc=?ln_IdDoc_EFactura
							And IsNull(IdArticol, 0)>0
					EndText
				EndIf
				=mySQLExec(lcSQL, [SQL_IesiriDetaliat])
				*
				Select Distinct IdArticol From SQL_IesiriDetaliat Into Cursor crsGetIDuriArticoleIesiri
				&& ArrayToString(aGetIDuriArticoleIesiri)
				*
				cListIdArticole = '('
				If _Tally>0
					
					*
					Select crsGetIDuriArticoleIesiri
					Scan
						cListIdArticole = cListIdArticole + AllTrim(Transform(IdArticol))+ICase(RecCount()=RecNo(), '', ', ')
					EndScan
					*
					cListIdArticole = cListIdArticole + ')'	
				Else
					cListIdArticole = cListIdArticole + '9999999999)'	
				EndIf
				*
				Text To lcSQL NoShow TextMerge
					Select
						ID As Cod
						, [Cod_Bare]=Cast(CodBare As Numeric(13, 0))
						, Greutate
						, Space(50) As Text_Supl
						, IsLot As Is_Lot
						, Tva
						, [Cod_NC8]=Articole.NC8
						, [Cod_CPV]=Articole.CPV
					From Articole
					Where
						Id IN <<cListIdArticole>>
				EndText
				mySQLExec(lcSQL, [c_Get_CBare])
				*
				Select c_Get_CBare
				Locate For Cod=crsEFactura.Cod .And. c_Get_CBare.Cod_Bare<>0
				If Found()
					oStandardItem = oItem.AppendChild(oXML.CreateElement("cac:StandardItemIdentification"))
					oIdStandard = oStandardItem.AppendChild(oXML.CreateElement("cbc:ID"))
					&& BT-157 BT-157-1
					oIdStandard.SetAttribute("schemeID", "0160")
					lc_Cod_Bare = AllTrim(Str(c_Get_CBare.Cod_Bare, 13, 0))
					If Len(lc_Cod_Bare)=12
						lc_Cod_Bare = "0"+lc_Cod_Bare
					EndIf	
					oIdStandard.Text = lc_Cod_Bare
				EndIf
				*
				*#-- TODO Loturi
				*
				&& <cac:OriginCountry>
				&& 	<cbc:IdentificationCode>DK</cbc:IdentificationCode><!--BT-159-->
				&& </cac:OriginCountry>
				*			
				*	Codurile NC sunt exclusiv pentru B2B.
				*	Pentru B2G se folosesc codurile CPV.
				*	At�t codurile NC c�t si cele CPV sunt necesare si obligatorii la produse cu risc fiscal, �n rest nu.			
				*
				*---------------------------------------
				* Produse cu risc fiscal OPANAF 12/2022.
				*---------------------------------------
				#if .f.
	Cele cinci categorii de produse sunt:

	1. Legume, fructe, radacini si tuberculi alimentari, alte plante comestibile:
	� COD NC de la 0701 � 0714 inclusiv Legume comestibile si anumite radacini si tuberculi.
	� COD NC de la 0801 � 0814 inclusiv Fructe comestibile si fructe cu coaja lemnoasa; coaja de citrice sau de pepeni.

	2. Bauturi alcoolice
	� COD NC de la 2203 � 2208 inclusiv Bauturi, bauturi spirtoase.

	3. Constructii noi
	Constructiile noi sunt cele mentionate la art. 292 alin. (2) lit. f) din Codul fiscal. 
	Adica cele a caror livrare este efectuata cel t�rziu p�na la data de 31 decembrie a anului urmator anului primei ocupari ori utilizari a constructiei sau a unei parti a acesteia, dupa caz. Inclusiv orice construc?ie transformata sau parte transformata a unei construc?ii, daca costul transformarii, exclusiv taxa, se ridica la minimum 50% din valoarea construc?iei sau a par?ii din construc?ie, exclusiv valoarea terenului, ulterior transformarii.

	4. Produse minerale (apa minerala naturala, nisip si pietris).
	� COD NC de la 2201 � 2202 inclusiv Ape, inclusiv ape minerale naturale sau artificiale si ape gazeificate care nu contin zahar sau alti �ndulcitori si nici aromatizanti.
	� COD NC 2505 � Nisipuri naturale de orice fel, chiar colorate.
	� COD NC 2517 � Prundis, pietris, pietre concasate, din cele folosite �n general ca agregate pentru betoane sau pietruirea drumurilor, pentru caile ferate sau alt balast, pietri? ?i silex, chiar tratate termic; macadam de zgura, de zgura metalurgica, de de?euri industriale similare, care con?ine chiar materiale cuprinse �n prima parte a pozi?iei; macadam gudronat pentru ?osele; granule, sparturi ?i praf din pietre de la pozi?iile 2515 sau 2516, chiar tratate termic.

	5. �mbracaminte si �ncaltaminte (inclusiv accesorii)

	� COD NC 6401 � �ncaltaminte etansa cu talpi exterioare si fete din cauciuc sau din material plastic, a carei faza nu a fost nici fixata de talpa exterioara prin coasere sau prin nituri, cuie, ?uruburi, ?tifturi sau dispozitive similare, nici formata din diferite par?i asamblate prin procedee similare.
	� COD NC 6402 � Alta �ncaltaminte cu talpi exterioare si fete din cauciuc sau din material plastic.
	� COD NC 6403 � �ncaltaminte cu talpi exterioare din cauciuc, material plastic, piele naturala sau reconstituita ?i cu fe?e din piele naturala.
	� COD NC 6404 � �ncaltaminte cu talpi exterioare din cauciuc, material plastic, piele naturala sau reconstituita ?i cu fe?e din materiale textile.
	� COD NC 6405 � Alta �ncaltaminte.
	� COD NC 6101 � Paltoane, scurte, pelerine, hanorace, bluzoane ?i articole similare, tricotate sau cro?etate, pentru barba?i sau pentru baie?i, cu excep?ia articolelor de la pozi?ia 6103.
	� COD NC 6102 � Paltoane, scurte, pelerine, hanorace, bluzoane ?i articole similare, tricotate sau cro?etate, pentru femei sau fete, cu excep?ia articolelor de lapozi?ia 6104.
	� COD NC 6103 � Costume sau compleuri, ansambluri, jachete, sacouri, pantaloni, salopete cu bretele, pantaloni scur?i ?i ?orturi (altele dec�t cele pentru baie), tricotate sau cro?etate, pentru barba?i sau baie?i.
	� COD NC 6104 � Taioare, ansambluri, jachete, sacouri, rochii, fuste, fuste-pantalon, pantaloni, salopete cu bretele, pantaloni scur?i ?i ?orturi (altele dec�t cele de baie), tricotate sau cro?etate, pentru femei sau fete.
	� COD NC 6105 � Cama?i ?i bluze, tricotate sau cro?etate, pentru barba?i sau baie?i.
	� COD NC 6106 � Cama?i, bluze, bluze-cama?a, tricotate sau cro?etate, pentru femei sau fete.
	� COD NC 6107 � Chilo?i, indispensabili, cama?i de noapte, pijamale, halate de baie, halate de casa ?i articole similare, tricotate sau cro?etate, pentru barba?i sau baie?i.
	� COD NC 6108 � Combinezoane sau furouri, jupoane, chilo?i, cama?i de noapte, pijamale, dezabieuri, halate de baie, halate de casa ?i articole similare, tricotate sau cro?etate, pentru femei ?i fete.
	� COD NC 6109 � Tricouri (T-shirts), bluze ?i maiouri de corp, tricotate sau cro?etate.
	� COD NC 6110 � Jerseuri, pulovere, cardigane ?i articole similare, veste ?i articole similare, inclusiv tricotajele sub?iri care se poarta sub pulovere, tricotate sau cro?etate.
	� COD NC 6111 � �mbracaminte ?i accesorii de �mbracaminte, tricotate sau cro?etate, pentru sugari.
	� COD NC 6112 � Treninguri, combinezoane ?i costume de schi ?i costume, chilo?i ?i slipuri de baie, tricotate sau cro?etate.
	� COD NC 6113 � �mbracaminte confec?ionata din materiale tricotate sau cro?etate de la pozi?iile 5903, 5906 sau 5907.
	� COD NC 6114 � Alte articole de �mbracaminte din materiale tricotate sau cro?etate.
	� COD NC 6115 � Ciorapi-chilot, dresuri, ciorapi, ?osete ?i alte articole similare, inclusiv ciorapii cu compresie progresiva (spre exemplu, pentru varice) ?i �ncal?aminte fara talpa aplicata, tricotate sau cro?etate.
	� COD NC 6116 � Manu?i, mitene ?i manu?i cu un deget, tricotate sau cro?etate.
	� COD NC 6117 � Alte accesorii confec?ionate de �mbracaminte, tricotate sau cro?etate; par?i de �mbracaminte sau accesorii de �mbracaminte, tricotate sau cro?etate.
	� COD NC 6201 � Paltoane, scurte, pelerine, hanorace (inclusiv geci de ski), geci de v�nt ?i alte articole similare, pentru barba?i sau baie?i, cu excep?ia articolelor de la pozi?ia 6203.
	� COD NC 6202 � Paltoane, scurte, pelerine, hanorace (inclusiv geci de ski), geci de v�nt ?i articole similare, pentru femei sau fete, cu excep?ia articolelor de la pozi?ia 6204.
	� COD NC 6203 � Costume sau compleuri, ansambluri, jachete, sacouri, pantaloni, salopete cu bretele, pantaloni scur?i ?i ?orturi (altele dec�t cele pentru baie), pentru barba?i sau baie?i.
	� COD NC 6204 � Taioare, ansambluri, jachete, sacouri, rochii, fuste, fuste-pantalon, pantaloni, salopete cu bretele, pantaloni scur?i ?i ?orturi (altele dec�t pentru baie), pentru femei ?i fete.
	� COD NC 6205 � Cama?i ?i cama?i cu m�neca scurta pentru barba?i sau baie?i.
	� COD NC 6206 � Cama?i, bluze, bluze-cama?i ?i cama?i cu m�neca scurta pentru femei sau fete.
	� COD NC 6207 � Bluze si maiouri de corp, chilo?i, indispensabili, cama?i de noapte, pijamale, halate de baie, halate de casa ?i articole similare, pentru barba?i sau pentru baie?i.
	� COD NC 6208 � Bluze de corp ?i cama?i de zi, combinezoane sau furouri, jupoane, chilo?i, cama?i de noapte, pijamale, neglijeuri, halate de baie, halate de casa ?i articole similare, pentru femei sau fete.
	� COD NC 6209 � �mbracaminte ?i accesorii de �mbracaminte pentru sugari.
	� COD NC 6210 � �mbracaminte confec?ionata din produsele de la pozi?iile 5602, 5603, 5903, 5906 sau 5907.
	� COD NC 6211 � �mbracaminte de sport (treninguri), combinezoane ?i costume de schi, costume, chilo?i ?i slipuri, de baie; alte articole de �mbracaminte.
	� COD NC 6212 � Sutiene, br�uri, corsete, bretele, suspensoare, jartiere ?i articole similare ?i par?ile lor, chiar tricotate sau cro?etate.
	� COD NC 6214 � ?aluri, e?arfe, fulare, mantile, voaluri, voalete ?i articole similare.
	� COD NC 6215 � Cravate, papioane ?i fulare cravata.
	� COD NC 6216 � Manu?i, mitene ?i manu?i cu un deget.
	� COD NC 6217 � Alte accesorii de �mbracaminte confec?ionate; par?i de �mbracaminte sau de accesorii de �mbracaminte, altele dec�t cele de la pozi?ia 6212.

	e-factura
				#endif
				*
				&& BT-158 BT-158-1 BT-158-2
				*
				Select c_Get_CBare
				Locate For Cod=crsEFactura.Cod .And. c_Get_CBare.Cod_Bare<>0
				If Found()
					oClassification = oItem.AppendChild(oXML.CreateElement("cac:CommodityClassification"))
					oClassificationStandardId = oClassification.AppendChild(oXML.CreateElement("cbc:ItemClassificationCode"))
					oClassificationStandardId.SetAttribute("listID", "EN")						&& Coduri de bara		--OPTIONAL
					oClassificationStandardId.Text = AllTrim(Str(c_Get_CBare.Cod_Bare, 13, 0))
				EndIf
				*
				*https://docs.peppol.eu/poacc/billing/3.0/codelist/UNCL7143/
	            *<cac:CommodityClassification><cbc:ItemClassificationCode listID="TSP">{NC }</cbc:ItemClassificationCode></cac:CommodityClassification>
       		    *<cac:CommodityClassification><cbc:ItemClassificationCode listID="STI">{CPV}</cbc:ItemClassificationCode></cac:CommodityClassification>					
					*
				lCladiriNoi = .F.
				Select c_Get_CBare
				Locate For Cod=crsEFactura.Cod .And. !IsNullOrEmpty(c_Get_CBare.Cod_CPV)
				*
				If Found()
					*
					oClassificationCPV = oItem.AppendChild(oXML.CreateElement("cac:CommodityClassification"))
					&& BT-158 BT-158-1 BT-158-2
					oClassificationStandardIdCPV = oClassificationCPV.AppendChild(oXML.CreateElement("cbc:ItemClassificationCode"))
					oClassificationStandardIdCPV.SetAttribute("listID", Iif(c_Get_CBare.Cod_CPV="1111 ", "ZZZ", "STI"))	&& && CPV		B2G
					oClassificationStandardIdCPV.Text = AllTrim(c_Get_CBare.Cod_CPV)
					*
					If c_Get_CBare.Cod_CPV="1111 "
	            		lCladiriNoi = .T.
	            	EndIf	
					*				
				EndIf
				*
				Select c_Get_CBare
				Locate For Cod=crsEFactura.Cod .And. !IsNullOrEmpty(c_Get_CBare.Cod_NC8)
				*
				If Found() And ((c_Get_CBare.Cod_NC8<>"1111 ") Or (c_Get_CBare.Cod_NC8="1111 " And Not lCladiriNoi))
					*
					oClassificationNC = oItem.AppendChild(oXML.CreateElement("cac:CommodityClassification"))
					oClassificationStandardIdNC = oClassificationNC.AppendChild(oXML.CreateElement("cbc:ItemClassificationCode"))
					oClassificationStandardIdNC.SetAttribute("listID", Iif(c_Get_CBare.Cod_NC8="1111 ", "ZZZ", "TSP"))	&& NC8 sau	B2B
					oClassificationStandardIdNC.Text = AllTrim(c_Get_CBare.Cod_NC8)
					*
				EndIf
				*
			EndIf
			*
			&& BG-30
			oItemTaxCategory = oItem.AppendChild(oXML.CreateElement("cac:ClassifiedTaxCategory"))
			*
			Select Tip From crsTva_EFactura Where ProcTva=crsEFactura.ProcTva Into Array aGetTipCota
			*
			&& BT-151		Categoria de TVA		
			*	S - Cota normala si cota redusa a TVA
			*	Z - TVA cota zero
			*	E - Scutire de TVA
			*	AE - TVA cu taxare inversa
			*	K - TVA pentru livrari intracomunitare
			*	G - TVA pentru exporturi
			*	O - Nu face obiectul TVA
			*	L - Taxele din Insulele Canare
			*	M - Taxele din Ceuta si Melilla
			oItemTaxCategory.AppendChild(oXML.CreateElement("cbc:ID"))
			oItemTaxCategory.LastChild.Text = AllTrim(aGetTipCota(1))
			&& BT-152		Cota TVA
			If aGetTipCota(1)<>'O'
				oItemTaxCategory.AppendChild(oXML.CreateElement("cbc:Percent"))
				oItemTaxCategory.LastChild.Text = AllTrim(Str(crsEFactura.ProcTva, 2, 0))
			EndIf
			*	
			oItemTaxScheme = oItemTaxCategory.AppendChild(oXML.CreateElement("cac:TaxScheme"))
			oItemTaxScheme.AppendChild(oXML.CreateElement("cbc:ID"))
			oItemTaxScheme.LastChild.Text = "VAT"
			*
			&& <cac:AdditionalItemProperty>
			&& 	<cbc:Name>Color</cbc:Name>
			&& 	<cbc:Value>black</cbc:Value>
			&& </cac:AdditionalItemProperty>		
			*&& BG-29
			oItemPrice = oInvoiceLine.AppendChild(oXML.CreateElement("cac:Price"))
			oItemAmount = oItemPrice.AppendChild(oXML.CreateElement("cbc:PriceAmount"))
			&& BT-146		Pretul net 
			oItemAmount.SetAttribute("currencyID", lcMoneda)
			oItemAmount.Text = AllTrim(Str(crsEFactura.Pret_Vanz, 15, 4))
			*
			&& <cbc:BaseQuantity unitCode="C62">1</cbc:BaseQuantity><!--BT-149 BT-150-->
			&& <cac:AllowanceCharge>
			&& 	<cbc:ChargeIndicator>false</cbc:ChargeIndicator>
			&& 	<cbc:Amount currencyID="RON">225</cbc:Amount><!--BT-147-->
			&& 	<cbc:BaseAmount currencyID="RON">1500</cbc:BaseAmount><!--BT-148-->
			&& </cac:AllowanceCharge>
			*
			i = i+1
		EndScan
	*
	EndIf
	*
	&& <cac:InvoiceLine> 
	&& 	<cbc:ID>2</cbc:ID> 
	&& 	<cbc:Note>Cover is slightly damaged.</cbc:Note> 
	&& 	<cbc:InvoicedQuantity unitCode="EA">-1</cbc:InvoicedQuantity> 
	&& 	<cbc:LineExtensionAmount currencyID="NOK">-3.96</cbc:LineExtensionAmount><!--BT-131-->
	&& 	<cbc:AccountingCost>BookingCode002</cbc:AccountingCost> 
	&& 	<cac:OrderLineReference> 
	&& 		<cbc:LineID>5</cbc:LineID> 
	&& 	</cac:OrderLineReference> 
	&& 	<cac:Item> 
	&& 		<cbc:Name>Returned "Advanced computing" book</cbc:Name> 
	&& 		<cac:SellersItemIdentification> 
	&& 			<cbc:ID>JB008</cbc:ID> 
	&& 		</cac:SellersItemIdentification> 
	&& 		<cac:StandardItemIdentification> 
	&& 			<cbc:ID schemeID="0088">1234567890135</cbc:ID> 
	&& 		</cac:StandardItemIdentification> 
	&& 		<cac:CommodityClassification> 
	&& 			<cbc:ItemClassificationCode listID="ZZZ">32344324</cbc:ItemClassificationCode> 
	&& 		</cac:CommodityClassification> 
	&& 		<cac:CommodityClassification> 
	&& 			<cbc:ItemClassificationCode listID="STI">65434567</cbc:ItemClassificationCode> 
	&& 		</cac:CommodityClassification> 
	&& 		<cac:ClassifiedTaxCategory> 
	&& 			<cbc:ID>S</cbc:ID> 
	&& 			<cbc:Percent>20</cbc:Percent> 
	&& 			<cac:TaxScheme> 
	&& 				<cbc:ID>VAT</cbc:ID> 
	&& 			</cac:TaxScheme> 
	&& 		</cac:ClassifiedTaxCategory> 
	&& 	</cac:Item> 
	&& 	<cac:Price> 
	&& 	<cbc:PriceAmount currencyID="NOK">3.96</cbc:PriceAmount> 
	&& 	<cbc:BaseQuantity unitCode="EA">1</cbc:BaseQuantity> 
	&& 	</cac:Price> 
	&& </cac:InvoiceLine> 	
	*
	lcRaspunsDUK = ""
	*
	lcDenumireCompletaFisier=tcCaleFacturi+tcNumeFisier+".xml"
	lcDenFisierRaspuns=tcCaleFacturi+tcNumeFisier+'.txt'
	
	lcDenFisierRaspunsLOG=tcCaleFacturi+tcNumeFisier+'.log'
	*
	
	*Set Step On
	
	oXML.Save(lcDenumireCompletaFisier)
	*
	*	&& Vicos.12.02.2024
	*
*!*		lcFacturaText = "Factura "
*!*		*
*!*		IF tlIsAutoFactura
*!*		    lcFacturaText = "Autofactura "
*!*		EndIf
*!*		*
*!*		RETURN IIF(lcTara<>"RO", lcFacturaText+"externa generata corect.", lcFacturaText+"generata corect.")
	*
	*	&& Vicos.12.02.2024
	*
	*If _Vfp.StartMode=0
	*	MessageBox([Salvare ok pt fisierul xml ]+ lcDenumireCompletaFisier)
	*EndIf	
	*RETURN "Factura generata corect."
	*
	&& Beautify XML		16.01.2024
	&& Asta imi sterge comentariile
	*

	*If _VFP.StartMode=0	
	*	lcXMLFileUggly = lcDenumireCompletaFisier+'.uggly'
	*	Copy FILE (lcDenumireCompletaFisier) To (lcXMLFileUggly)
	*	lcCmd = 'xml fo ' + (lcXMLFileUggly) + ' >' +(lcDenumireCompletaFisier)
	*	Run &lcCmd			&& trebuie sa astepti sa intoarca rezultatul, NU MERGE cu WScript.Shell	
	*ELSE	
		lcXml_To_Formated	= FileToStr(lcDenumireCompletaFisier)
		lo_Chilkat_Xml		= CreateObject('Chilkat_9_5_0.Xml')
		lo_Chilkat_Xml.LoadXml(lcXml_To_Formated)
		m.lcStrFormattedXml	= lo_Chilkat_Xml.GetXml()
		Release lo_Chilkat_Xml
		StrToFile(m.lcStrFormattedXml, m.lcDenumireCompletaFisier)
	*EndIf
	*
	If File(lcDenFisierRaspuns)
		Delete File (lcDenFisierRaspuns)
	EndIf
	*
	Try
		If File(lcDenFisierRaspunsLOG)
			Delete File (lcDenFisierRaspunsLOG)
		EndIf
	Catch
	EndTry
	*
	If ICAS.oSettings.eFactura_ValidareXMLOnline		&&-- 09Ianuarie2025
		*
		ValidareXMLOnline(lcDenumireCompletaFisier, 'FACT1', @lcRaspunsDUK)
		*
        IF lcRaspunsDUK<>"ok"
            FOR jj = 1 TO 2
                WAIT WINDOW TIMEOUT 0.5 *jj "Revalidare XML factura: "+ALLTRIM(crsEFactura.NR)
                ValidareXMLOnline(lcDenumireCompletaFisier, 'FACT1', @lcRaspunsDUK)
                lcRaspunsDUK		= InterpretareRaspunsValidatorEfactura(lcRaspunsDUK)
                IF lcRaspunsDUK="ok"
                    EXIT
                ENDIF
            ENDFOR
        ENDIF
		*
		StrToFile(lcRaspunsDUK, lcDenFisierRaspuns)
		*
	Else												&&-- 09Ianuarie2025
	*
	vExt = FindExec('jar')
	&& "C:\Program Files\Java\jdk-11.0.16\bin\javaw.exe" -jar "%1" %*
	If IsNullOrEmpty(vExt) Or Not File(vExt)
		StrToFile(Chr(13)+'-FindExec() a esuat: '+Chr(13)+vExt, ExpDir+'\Log\'+'Java.log',1)
		vExt = Extensie('jar')
	EndIf
	*
	If IsNullOrEmpty(vExt) Or Not File(vExt)
		*
		StrToFile(Chr(13)+'Extensie() a esuat: '+Chr(13)+vExt, ExpDir+'\Log\'+'Java.log',1)
		*
		vExt = ExpDir + '\dist\eFactura\jre8\bin\java.exe'
		*
		If IsNullOrEmpty(vExt) Or Not File(vExt)
			StrToFile(Chr(13)+'-JRE8 folder inexistent: '+Chr(13)+vExt, ExpDir+'\Log\'+'Java.log',1)
		EndIf
		*	
	EndIf
	*
	If Len(vExt)=0 .OR.  .NOT. 'java'$Lower(vExt)
		MessageBox(	"Am generat fisierul "+lcDenumireCompletaFisier+". Deoarece aplicatia nu a gasit Java pe calculatorul dvs, va trebui sa-l validati manual in DukIntegrator", 48, "Validati manual xml", 3000)
		Return		"Am generat fisierul "+lcDenumireCompletaFisier+". Deoarece aplicatia nu a gasit Java pe calculatorul dvs, va trebui sa-l validati manual in DukIntegrator"
	EndIf
	*
	vCale = '"'+JUSTPATH(vExt)+'\java.exe"'			&& javaw.exe ???
	oWsShell = CreateObject("WScript.Shell")
	oWsShell.Run(vCale+' -jar "'+Sys(5)+CurDir()+'Dist\EFactura\DUKIntegrator.jar"'	+' -v FACT1 "'+lcDenumireCompletaFisier+'" "'+lcDenFisierRaspuns+'"', 0, .T.)
	Release oWsShell
	*
	EndIf												&&-- 09Ianuarie2025
	*
	If ICAS.cBackEnd='MySQL'
		llNewRecord	= lnIdUnicFactura=0
		cWhere		= ICase(llNewRecord=.F., Conditie_mySQL+" AND Id=?m.DocumentId", '')
	Else
		Store .F.	To llNewRecord	
		Store ''	To cWhere
	EndIf	
	*
	If File(lcDenFisierRaspuns)
		*
		lcRaspunsDUK  = FileToStr(lcDenFisierRaspuns)
		*
		If lcRaspunsDUK ="ok"
			*
			If Used('SEL_EFACTURA')
				*Replace id_solicitare With ln_Index_Incarcare, Data_Liv With ltDateTime In SEL_EFACTURA
				Replace;
						Stare	With 'XML: '+lcRaspunsDUK;
					,	Fisier	With lcDenumireCompletaFisier;
				IN SEL_EFACTURA
			EndIf 
			*
			*MessageBox("Factura este valida. Poate fi �ncarcata prin SPV, la sectiunea 'Factura electronica' (optiunea de sintaxa XML - UBL).", 64, "Validare declaratie", 3000)
			*
			*	-	Daca transmite din Iesiri, Export, Vanzari 
			*	Aliasul "IESIRI", "EXPORT" sau "DOCUM" este deschis
			*	si este pozitionat pe factura pe care vrea sa o transmita.  NU NEAPARAT!!!!
			*
			lc_Field_ID = Iif(ll_Is_ICAS, 'IdUnic', 'Id')
			? "lc_Field_ID ",	Transform(lc_Field_ID)
			*
			If Used(lcAlias) And IsField('BFTiparit', lcAlias)
				*
				Text To lcSQL NoShow TextMerge
					Update;
						<<lcAlias>>;
					Set;
						BFTiparit		= 9;
					Where;
						<<lc_Field_ID>>	= ln_IdUnic_Factura
				EndText
				lOk = ExecScript(lcSQL) 
				*	
				If ICAS.cBackEnd='MySQL'
					Salvare_MySQL('Docum', cWhere, llNewRecord)
				Else
					=TableUpdate(.T., .T., lcAlias)
				EndIf
				*
			Else
				*
				Text To lcSQL NoShow TextMerge
					Update
						<<lcAlias>>
					Set
						BFTiparit		= 9
					Where
						<<lc_Field_ID>>	= ?ln_IdUnic_Factura
				EndText
				=mySQLExec(lcSQL)
				*
			EndIf
			*	
			*This.myGrid2.GridOp.Column12.DynamicBackColor = "IIF(tiparit=8,RGB(233,233,233),IIF(tiparit=7,RGB(0,128,255),IIF(tiparit=9,RGB(200,230,255),RGB(252,252,225))))"
			*
			lUpload_EFA = .T.
			*
			*//////////////////////////////////////////////////////
			*
			If Not IsNullOrEmpty(ICAS.oSettings.eFactura_TokenAcces) And Not ICAS.oSettings.eFactura_Only_XML
				*
				lcErr_SPV = ''
				*
				Try
					*
					* dateResponse not found la CORNELIA
					oReturn_eFactura_API_Upload=eFactura_API_Upload(lcDenumireCompletaFisier, ICAS.oSettings.eFactura_TokenAcces, ICAS.oSettings.eFactura_Prod, lc_Upload_Param_Extern, .F., AllTrim(ICAS.oSoc.CodFiscal), lc_EFA_TipRaportare)
					*
					If VarType(oReturn_eFactura_API_Upload)<>'O'
                    	Wait WINDOW TIMEOUT 0.5 "Retrimitere factura "+AllTrim(Sel_eFactura.Nr_Iesire)
                    	oReturn_eFactura_API_Upload=eFactura_API_Upload(lcDenumireCompletaFisier, ICAS.oSettings.eFactura_TokenAcces, ICAS.oSettings.eFactura_Prod, lc_Upload_Param_Extern, .F., AllTrim(ICAS.oSoc.CodFiscal), lc_EFA_TipRaportare)
					EndIf
					*
					If VarType(oReturn_eFactura_API_Upload)<>'O'
						MessageBox('Serverul ANAF e-Factura nu functioneaza.',64, 'ANAF is down', 3000)
						lUpload_EFA = .F.
					Else
						lc_Index_Incarcare	= oReturn_eFactura_API_Upload.index_incarcare		&& property INDEX_INCARCARE is not found
						ltDateTime			=;
							DateTime(;
									Val(SubStr(oReturn_eFactura_API_Upload.dateResponse, 1, 4)),;
									Val(SubStr(oReturn_eFactura_API_Upload.dateResponse, 5, 2)),;
									Val(SubStr(oReturn_eFactura_API_Upload.dateResponse, 7, 2)),;
									Val(SubStr(oReturn_eFactura_API_Upload.dateResponse, 9, 2)),;
									Val(SubStr(oReturn_eFactura_API_Upload.dateResponse, 11, 2));
									)					
						lcDateTime=TToC(ltDateTime)
						lcMsg1='Data incarcarii:'+lcDateTime
						lcMsg2='Index incarcare:'+oReturn_eFactura_API_Upload.index_incarcare
						MessageBox(;
							"Factura: "+Chr(13)+lcNumarFactura+" din data de: "+DToC(ldData)+Chr(13)+;
							"este valida si a fost �ncarcata prin SPV."+Chr(13)+lcMsg1+Chr(13)+lcMsg2, 64, "Validare declaratie";
							, 3000)
						*
						If Used(lcAlias) And IsField('id_solicitare', lcAlias)
							*
							Text To lcSQL NoShow TextMerge
								Update;
									<<lcAlias>>;
								Set;
										id_solicitare		= lc_Index_Incarcare;
									,	efact_DataIncarcare	= ltDateTime;	
								Where;
									<<lc_Field_ID>>			= ln_IdUnic_Factura
							EndText
							lOk = ExecScript(lcSQL)
							*
							If ICAS.cBackEnd='MySQL'
								Salvare_MySQL('Docum', cWhere, llNewRecord)
							Else
								=TableUpdate(.T., .T., lcAlias)
							EndIf
							*
						Else
							*	
							Text To lcSQL NoShow TextMerge
								Update
									<<lcAlias>>
								Set
										id_solicitare		= ?lc_Index_Incarcare
									,	efact_DataIncarcare	= ?ltDateTime
								Where
									<<lc_Field_ID>>			= ?ln_IdUnic_Factura
							EndText
							=mySQLExec(lcSQL)
							*
						EndIf
						*	
						If Used('SEL_EFACTURA')
							*Replace id_solicitare With lc_Index_Incarcare, Data_Liv With ltDateTime In SEL_EFACTURA
							Replace;
									id_solicitare	With lc_Index_Incarcare;
								,	Data_Liv		With ltDateTime;
								,	dEF_Upload		With ltDateTime;
								,	Mesaj			With "Factura a fost incarcata cu succes. index_incarcare: "+lc_Index_Incarcare;
								,	Depus			With 1;
								,	Stare			With 'Incarcata';
								,	Preluat			With 0;
							IN SEL_EFACTURA
							*
						EndIf 
						*
					EndIf	
					*
				Catch To loErr
					*
					If VarType(oReturn_eFactura_API_Upload)="O"
						lcXML_SPV_ERR			= oReturn_eFactura_API_Upload.xml
					Else
						lcXML_SPV_ERR			= ''
					EndIf
					*
					llErr_SPV_Mentenanta		= Occurs('Mentenanta sistem', lcXML_SPV_ERR)>0
					lcErr_SPV					= ""
					*
					Do Case
						*
						Case Not Empty(llErr_SPV_Mentenanta)
							*
							lcErr_SPV1		= StrExtract(lcXML_SPV_ERR, '<title>', '</title>')
							lcErr_SPV2		= StrExtract(lcXML_SPV_ERR, '<H3>', '<br>')
							lcErr_SPV_Title	= StrExtract(lcXML_SPV_ERR, '<td align="center" >', '<br />')
							*
							lcErr_SPV		= lcErr_SPV2
							*MessageBox(lcErr_SPV1+Chr(13)+lcErr_SPV2, 16, "Eroare-"+lcErr_SPV_Title)
						*
						Case "A connection attempt failed because the connected party did not properly respond after a period of time, or established connection failed because connected host has failed to respond." $ m.lcXML_SPV_ERR
							m.lcErr_SPV = "Serverele ANAF nu raspund. Incercati mai tarziu" + Chr(13) + m.lcXML_SPV_ERR
						*
						Case "The remote name could not be resolved: 'api.anaf.ro'"$lcXML_SPV_ERR
							lcErr_SPV = "Conexiunea cu ANAF nu poate fi efectuata."+Chr(13)+"Asigurati-va ca aveti conexiune stabila la internet si ca antivirusul sau alte programe nu blocheaza accesul la site-ul ANAF sau la SPV."
						*
						Case "The remote server returned an error: (502) Bad Gateway."$lcXML_SPV_ERR
							lcErr_SPV = "Serverele ANAF nu raspund. Incercati mai tarziu."
						*
						Case "The remote server returned an error: (500) Internal Server Error." $ m.lcXML_SPV_ERR
							m.lcErr_SPV = "Serverele ANAF nu raspund. Incercati mai tarziu" + Chr(13) + m.lcXML_SPV_ERR
						*
						Case "connection was forcibly closed" $ m.lcXML_SPV_ERR .Or. "failed to respond" $ m.lcXML_SPV_ERR .Or. ("operation " $ m.lcXML_SPV_ERR .And. ("timeout" $ m.lcXML_SPV_ERR .Or. ("timed out" $ m.lcXML_SPV_ERR)))
							m.lcErr_SPV = "Serverele ANAF nu raspund." + Chr(13) + "Incercati mai tarziu." + Chr(13) + m.lcXML_SPV_ERR
					    *
					    Case "A aparut o eroare tehnica. Cod: 204" $ m.lcXML_SPV_ERR .OR. "A aparut o eroare tehnica. Cod: 104"  $ m.lcXML_SPV_ERR
				        	m.Raspuns = "Serverele ANAF nu raspund."+CHR(13)+"Incercati mai tarziu."
						*
						Case "Forbidden" $ m.lcXML_SPV_ERR .Or. ("403" $ m.lcXML_SPV_ERR .And. Len(m.lcXML_SPV_ERR < 30))
							m.lcErr_SPV = "Nu aveti drepturi de �ncarcare pe acest cod fiscal sau tokenul ICAS pentru SPV este expirat. Reinoiti tokenul ICAS sau generati unul nou." + Chr(13) + m.lcXML_SPV_ERR
					    *Case "The remote server returned an error:"$lcXML_SPV_ERR .AND. "(401)"$lcXML_SPV_ERR .AND. "Unauthorized."$lcXML_SPV_ERR
					    *
					    *Case "(401)"$lcXML_SPV_ERR
					    Case "Unauthorized"$lcXML_SPV_ERR AND ["401"]$lcXML_SPV_ERR
				        	lcErr_SPV = "Nu aveti drepturi de �ncarcare pe acest cod fiscal sau tokenul ICAS pentru SPV este expirat. Reinoiti tokenul ICAS sau generati unul nou."+CHR(13)+lcXML_SPV_ERR
						*
						Case "Nu aveti drept in SPV pentru CIF" $ m.lcXML_SPV_ERR
							m.lcErr_SPV = "Nu aveti acces in SPV acum, pentru acest cod fiscal." + Chr(13) + "Daca inregistrarea in SPV a fost efectuata de curand, incercati mai tarziu sau luati legatura cu ANAF."
						*
						Case "Nu exista niciun CIF petru care sa aveti drept in SPV" $ m.lcXML_SPV_ERR .And.  .Not. m.mIsTransmitere
							m.lcErr_SPV = "OK"
						*
						Case StrTran(m.lcXML_SPV_ERR, " ", "") = "UBLVersionID(1)eroarestructura:ordineincorectaadescendentilor" .And.  .Not. m.mIsTransmitere
							m.lcErr_SPV = "OK"
						*
						Case m.lcXML_SPV_ERR = "F: UBLVersionID (1)  eroare structura: ordine incorecta a descendentilor elementului 'Invoice': elementul 'UBLVersionID'" .Or. "eroare structura: elementul 'CustomizationID'" $ m.lcXML_SPV_ERR .And.  .Not. m.mIsTransmitere
							m.lcErr_SPV = "OK"
						*
						OtherWise
							m.lcErr_SPV = m.lcXML_SPV_ERR
						
							*lcErr_SPV = StrExtract(lcXML_SPV_ERR, '<Errors errorMessage="', '"/>') && + Chr(13) + loErr.Message
							llErr_errorMessage	= Occurs('errorMessagesistem', lcXML_SPV_ERR)>0
							*
							If llErr_errorMessage
								lcErr_SPV = StrExtract(lcXML_SPV_ERR, '<Errors errorMessage="', '"/>') + Chr(13) + loErr.Message
							EndIf
							*
					EndCase
					*	
					MessageBox("Factura: "+Chr(13)+lcNumarFactura+" din data de: "+DToC(ldData)+Chr(13)+;
						"este valida dar NU a reusit �ncarcarea prin SPV."+Chr(13)+Chr(13)+;
						'Mesaj eroare ANAF:' + Chr(13)+;
						'[ ' + lcErr_SPV + ' ]' + Chr(13)+ Chr(13)+;
						"Poate fi �ncarcata manual prin SPV, la sectiunea 'Factura electronica' (optiunea de sintaxa XML - UBL).";
						, 64, "Validare declaratie", 3000)
					*
					Set Step On
					lUpload_EFA = .F.
					*
				EndTry
				*
				If Not lUpload_EFA
					*Return 'Serverul ANAF e-Factura nu functioneaza.'
					Return lcErr_SPV
				EndIf
				*		
			Else
				*
				lcReturn=;
					"Factura: "+Chr(13)+lcNumarFactura+" din data de: "+DToC(ldData)+Chr(13)+;
					"este valida."+Chr(13)+Chr(13)+;
					"Fisierul XML pentru e-Factura a fost generat si salvat, dar nu a fost trimis in SPV."+Chr(13)+;
					"Poate fi �ncarcata prin SPV, la sectiunea 'Factura electronica' (optiunea de sintaxa XML - UBL)."
				*	
				If ICAS.oSettings.eFactura_Only_XML
					*oWsShell = CreateObject("WScript.Shell")
					*oWsShell.Run(lcDenumireCompletaFisier)
					*Release oWsShell
					lcReturn=;
						"Factura: "+Chr(13)+lcNumarFactura+" din data de: "+DToC(ldData)+Chr(13)+;
						"este valida."+Chr(13)+Chr(13)+;
						"Fisierul XML pentru e-Factura a fost generat si salvat, dar nu a fost trimis in SPV,"+Chr(13)+;
						"deoarece a fost bifat flagul [ONLY_XML]."						
					MessageBox(lcReturn, 64, "Validare declaratie")
					*
					oWsShell = CreateObject("WScript.Shell")
					oWsShell.Run(lcDenumireCompletaFisier)
					Release oWsShell
					*
				Else
					*
					MessageBox(lcReturn, 64, "Validare declaratie", Iif(ICAS.oSettings.eFactura_Only_XML, 0, 3000))
					*
				EndIf	
				*
				If Used('SEL_EFACTURA')
					Replace;
							Mesaj	With lcReturn;
						,	Depus	With -1;
						,	Stare	With 'XML: Generat, nedepus in SPV';
					In SEL_EFACTURA
				EndIf 
				*
				Return lcReturn					
				*
			EndIf		If Not IsNullOrEmpty(ICAS.oSettings.eFactura_TokenAcces) And Not ICAS.oSettings.eFactura_Only_XML
			*
			*//////////////////////////////////////////////////////
			*
            *lcOperatiune			= "Transmitere"
            *lcRecipisaLaTransmitere	= SEL_EFACTURA.Recipisa
            *lcIndexLaTransmitere	= SEL_EFACTURA.id_solicitare
            **
            *If IsNullOrEmpty(lcIndexLaTransmitere)
            *    lcIndexLaTransmitere = lc_Index_Incarcare
            *EndIf
            **
            *Do Case
            *	*
            *    *Case  .NOT. IsNullOrEmpty(SEL_EFACTURA.Recipisa) .AND. SEL_EFACTURA.Tiparit=9 .AND. SEL_EFACTURA.Rectif=1
            *    *    lcOperatiune = "Rectificativa"
            *    Case  .NOT. IsNullOrEmpty(SEL_EFACTURA.Recipisa) .AND. SEL_EFACTURA.Tiparit=9 .AND. SEL_EFACTURA.Rectif=0
            *        lcOperatiune = "Retransmitere"
            *    Case  .NOT. IsNullOrEmpty(SEL_EFACTURA.Recipisa) .AND. IsNullOrEmpty(SEL_EFACTURA.Recipisa) .AND. SEL_EFACTURA.Tiparit=9
            *        lcOperatiune = "Retransmitere in procesare"
            *EndCase
            **
			*=SaveIstoricEFactura(lnIdUnicFactura, lcOoperatiune, lcIndexLaTransmitere, lcRecipisaLaTransmitere, "")			
			*
		Else		If lcRaspunsDUK ="ok"
			*
			If IsObject([EFactura_Import])
				*
				If Used('SEL_EFACTURA')
					*
					lcReturn = lcRaspunsDUK
					*
					Replace;
							Mesaj	With lcReturn;
						,	Depus	With -1;
						,	Stare	With 'eroare XML';
					In SEL_EFACTURA
					*MessageBox(lcReturn, 16, "Eroare", 3000)
					Return lcReturn	
					*
				EndIf
				*				
			Else
				ShowHideScreen(.T.)						&& la EstocFB imi ascunde ecranul
				*Delete File(lcDenumireCompletaFisier)
				Modify File (lcDenFisierRaspuns)
				ShowHideScreen(.F.)
			EndIf
			*
		EndIf
		*
	Else
		*
		*MessageBox("Nu s-a creat fisierul de raspuns "+lcDenFisierRaspuns+'.'+Chr(13)+'Mariti progresiv nr. de secunde necesare validarii fisierului xml de tip eFactura, in Setari->Editare INI->parametru "Wait_Seconds_Validare_eFactura"', 16, "Eroare", 3000)
		*
		lcReturn = "Nu s-a creat fisierul de raspuns "+lcDenFisierRaspuns+'.'
		*
		If Used('SEL_EFACTURA')
			Replace;
					Mesaj	With lcReturn;
				,	Depus	With -1;
				,	Stare	With 'eroare XML';
			In SEL_EFACTURA
		EndIf 
		*
		MessageBox(lcReturn, 16, "Eroare", 3000)
		Return lcReturn
		*
	EndIf	
	*
	RETURN "Factura generata corect."

*!*		If Empty(ReadIniString( [Application Name], [Wait_Seconds_Validare_eFactura] ) )
*!*			WriteIniString([Application Name], [Wait_Seconds_Validare_eFactura], [2])
*!*		EndIf
*!*	*	*
*!*		lnSecondsWait=Val(ReadIniString( [Application Name], [Wait_Seconds_Validare_eFactura] ))
*!*		*

	*
EndProc
*
*
*&&&&&
*
*
* __________________________________________________________________________________________________________
Function eFactura_API_Upload(XMLFileName, Token, tlProd, tc_Upload_Param_Extern, tlcURL, tcCIF, tc_Tip_Raportare)
	
	If Empty(tc_Upload_Param_Extern)
		tc_Upload_Param_Extern = ''
	EndIf	
	
	*Return EFA__Chilkat_Publicare(XMLFileName, Token, tlProd, tc_Tip_Raportare)
	
	
	
	Local oSetAlternate As Object, oSetConsole As Object, oSetSafety As Object, oSetCentury As Object
	oSetConsole=CreateObject("SetConsole", 'Off')
	oSetAlternate=CreateObject("SetAlternate", "On", lcCale_LOG+Program()+".log")	&& , "ADDITIVE"
	?"==============================="
	? Program()
	? "PARAMETERS:"
	? "XMLFileName", XMLFileName
	? "tlcURL ", Transform(tlcURL)
	? "tcCIF", tcCIF
	?
	*
	If tlcURL
		=StrToFile('curl -k -s --location --request POST "https://api.anaf.ro/'+IIf(ICAS.oSettings.eFactura_Prod,'prod','test')+'/FCTEL/rest/upload?standard=UBL&cif='+OnlyNumber(ICAS.oSoc.CodFiscal)+tc_Upload_Param_Extern+ '" --header "Authorization: Bearer '+AllTrim(m.Token)+'" --header "Content-Type: application/xml" -d @"'+m.XMLFileName+'" -o rasp.txt 2>&1','eFacturaUpload.bat')
		Run eFacturaUpload.bat
		* Delete File eFacturaUpload.bat
		If  .Not. File('rasp.txt')
			= MessageBox('Conectarea la srv. ANAF a esuat, asigurati-va ca aveti conexiunea la internet functionala !', 16, 'Eroare', 3000)
			Return
		EndIf
		*
		m.lcXml = FileToStr('rasp.txt')
		? "m.lcXml", m.lcXml
		*
	Else
		*
		If tlProd
			*lcServer=https://webserviceapl.anaf.ro/prod/FCTEL/rest/upload?standard=UBL
			lcServer='https://api.anaf.ro/prod/FCTEL/rest/upload?standard=UBL'
		Else
			*lcServer=https://webserviceapl.anaf.ro/test/FCTEL/rest/upload?standard=UBL
			lcServer='https://api.anaf.ro/test/FCTEL/rest/upload?standard=UBL'
		EndIf
		*
		If tc_Tip_Raportare = 'B2C'
			lcServer = StrTran(lcServer, 'upload', 'uploadb2c')
		EndIf
		*
		If Not Empty(tcCIF)
			lcServer=lcServer+'&cif='+OnlyNumber(AllTrim(tcCIF))+tc_Upload_Param_Extern
		Else
			lcServer=lcServer+'&cif='+OnlyNumber(AllTrim(ICAS.oSoc.CodFiscal))+tc_Upload_Param_Extern
		EndIf
		*
		*if (isExtern)
		*{
		*	text += "&extern=DA";
		*}
		? "tlProd ", Transform(tlProd)
		? "lcServer ", lcServer
		m.lcXml=''
		lcSend=FileToStr(XMLFileName)
		loHttp=_GetObject('http')
		*
		With loHttp
			.Open('POST', lcServer, .F.)
			.SetRequestHeader("Authorization","Bearer " + Token)
			.Send(lcSend)				&& cand este cazut e-Factura da eroare
			lc_Status=.StatusText
			lc_Response=.GetAllResponseHeaders()
			m.lcXml=.ResponseText
			? "loHttp.StatusText ", lc_Status
			? "loHttp.GetAllResponseHeaders() ", lc_Response
			? "loHttp.ResponseText ", m.lcXml
		EndWith	
		*
	EndIf
	*
	Local loReturn As Object
	loReturn=CreateObject('SmallClass')
	? "loReturn ", Transform(loReturn)
	loReturn.AddProperty('xml', m.lcXml)
	*
	If '<?xml'$m.lcXml
		Local loXmlDom As Microsoft.XMLDOM, oheader As Object
		
		loXmlDom = CreateObject("Microsoft.XMLDOM")
		loXmlDom.ASync = .F.
		loXmlDom.LoadXML(m.lcXml)
		oheader=loXmlDom.SelectSingleNode("//header")
		*
		For Each oAttribute In oheader.Attributes
			?oAttribute.NodeName, oAttribute.Text
			loReturn.AddProperty(oAttribute.NodeName, oAttribute.Text)
		Next
		*?oheader.Attributes.GetNamedItem("index_incarcare").Text
	EndIf	
	*
	If _VFP.StartMode=0
		*Activate Screen
		? "loReturn.xml ", loReturn.xml
		?
		*DebugOut Program(), 'loReturn.xml', loReturn.xml
	EndIf
	*
	?"==============================="
	?
	Return loReturn
EndFunc
* __________________________________________________________________________________________________________
Function eFactura_API_StareMesaj(id_incarcare, Token, tlProd)
	*
	lcCale_LOG = Get_LOG_EFA()
	Local oSetAlternate As Object, oSetConsole As Object
	oSetConsole=CreateObject("SetConsole", 'Off')
	oSetAlternate=CreateObject("SetAlternate", "On", lcCale_LOG+Program()+".log", "ADDITIVE")
	?
	? Program()
	? TToC(DateTime())
	? 'id_incarcare: ', id_incarcare
	*
	*If tlProd
	If ICAS.oSettings.eFactura_Prod
		lcServer='https://api.anaf.ro/prod/FCTEL/rest/stareMesaj?id_incarcare='+Transform(id_incarcare)
	Else
		lcServer='https://api.anaf.ro/test/FCTEL/rest/stareMesaj?id_incarcare='+Transform(id_incarcare)
	EndIf
	*
	lcXML=''
	lcSend=''
	loHttp=_GetObject('http')
	With loHttp
		.Open('GET', lcServer, .F.)
		.SetRequestHeader("Authorization","Bearer " + Token)
		.Send(lcSend)
		lc_Status=.StatusText
		lc_Response=.GetAllResponseHeaders()
		lcXML=.ResponseText
		? 'loHttp.StatusText: ', lc_Status
		? 'loHttp.GetAllResponseHeaders(): ', lc_Response
		? 'loHttp.ResponseText: ', lcXML
	EndWith	
	*
	Local loReturn As Object
	loReturn=CreateObject('SmallClass')
	loReturn.AddProperty('xml', lcXml)
	*
	If '<?xml'$m.lcXml
		Local loXmlDom As Microsoft.XMLDOM, oheader As Object
		
		loXmlDom = CreateObject("Microsoft.XMLDOM")
		loXmlDom.ASync = .F.
		loXmlDom.LoadXML(m.lcXml)
		oheader=loXmlDom.SelectSingleNode("//header")
		*
		For Each oAttribute In oheader.Attributes
			*?oAttribute.NodeName, oAttribute.Text
			loReturn.AddProperty(oAttribute.NodeName, oAttribute.Text)
			If _VFP.StartMode=0
				*Activate Screen
				? 'oAttribute.NodeName ', oAttribute.NodeName
				? 'oAttribute.Text     ', oAttribute.Text
				*DebugOut 'oAttribute.NodeName ', oAttribute.NodeName, 'oAttribute.Text     ', oAttribute.Text
			EndIf	
			*			
		Next
		*?oheader.Attributes.GetNamedItem("id_descarcare").Text
	EndIf	
	*
	If _VFP.StartMode=0
		*Activate Screen
		? 'loReturn.xml'
		? loReturn.xml
		?
		*DebugOut 'oAttribute.NodeName ', 'loReturn.xml', loReturn.xml
	EndIf
	*	
	Return loReturn
EndFunc
* __________________________________________________________________________________________________________
Function eFactura_API_ListaMesajeFactura(tcCUI, tcToken, tlProd, tnDataSessionID, tlCopy2Xls)
	*
	*			=eFactura_API_listaMesajePaginatieFactura(tcCUI, tcToken, tlProd)
	*
	*	E = ERORI FACTURA
	*	T = FACTURA TRIMISA
	*	P = FACTURA PRIMITA
	*	R = MESAJ CUMPARATOR PRIMIT / MESAJ CUMPARATOR TRANSMIS	
	*
	Return Iif(eFactura_API_listaMesajePaginatieFactura(tcCUI, tcToken, tlProd), 'OK', 'NOK')
	*
	
	
	
	lcCale_LOG = Get_LOG_EFA()
	Local oSetAlternate As Object, oSetConsole As Object, oSetSafety As Object
	oSetConsole=CreateObject("SetConsole", 'Off')
	oSetAlternate=CreateObject("SetAlternate", "On", lcCale_Log+Program()+".log")
	oSetSafety=CreateObject("SetSafety", "Off")
	*
	Local loSaveSelect As Object
	loSaveSelect=Create("SaveSelect")
	*
	If PCount()<4
		tnDataSessionID=0
	EndIf
	*
	If Empty(tcCUI)
		tcCUI = ICAS.oSoc.CodFiscal
	EndIf
	*
	If Empty(tcToken)
		tcToken = ICAS.oSettings.eFactura_TokenAcces
	EndIf
	*
	If Empty(tlProd)
		tlProd = ICAS.oSettings.eFactura_Prod
	EndIf
	*
	Local lcReturn As String
	lcReturn = "OK"	
	lcCUI = tcCUI
	*
	Local loResponse
	*=================================================
	loResponse = CreateObject('Chilkat_9_5_0.StringBuilder')
	__Consola( [loResponse = CreateObject('Chilkat_9_5_0.StringBuilder'): ( ] + Transform(loResponse) + [ )] )
	*=================================================
	IF tlProd
		lcURL_mesaje_SPV = '/prod/FCTEL/rest/listaMesajeFactura?zile='
	Else
		lcURL_mesaje_SPV = '/test/FCTEL/rest/listaMesajeFactura?zile='
	ENDIF
	*
	__Consola( [lcURL_mesaje_SPV: ] + Transform(lcURL_mesaje_SPV) )
	lnSuccess = ICAS.oRest_ANAF.FullRequestNoBodySb;
		(;
		"GET",;
		lcURL_mesaje_SPV+AllTrim(ICAS.oSettings.eFactura_zileDescarcareListaMesaje)+'&cif='+lcCUI,;
		loResponse;
		)
	__Consola( [lnSuccess : ] + Transform(lnSuccess) ) 
	*
	IF (lnSuccess <> 1) THEN
	    __Consola("EFA_IN_Mesaje: Nu se poate efectua GET/listaMesajeFactura > api.anaf.ro" + STR(ICAS.oRest_ANAF.ConnectFailReason))
		***RETURN .F.
		Return "NOK"
	EndIf
	*
	lnResponseStatusCode = ICAS.oRest_ANAF.ResponseStatusCode
	__Consola( [lnSuccess : ] + Transform(lnSuccess) ) 
	*
	IF lnResponseStatusCode = 200
		*
		lcJSon = loResponse.GetAsString()
		__Consola( [lcJSon: ] + Transform(lcJSon) ) 
		*=================================================
		loReturn = InCursor_ListaMesajeFactura( lcJSon )
		*=================================================
		__Consola( [loReturn = InCursor_ListaMesajeFactura( lcJSon ): ] + Transform(loReturn) ) 
		EFA_Consola("anaf - lista mesaje - " + lcCUI + " - ", lcJSon)
		*
	Else
		*
		*If (lnResponseStatusCode >= 400) 
		If (lnResponseStatusCode > 200) 
		    __Consola("EFA_IN_Mesaje: Nu se poate efectua Stare > api.anaf.ro: " )
		    __Consola(" ICAS.oRest_ANAF.ConnectFailReason: "	+ Transform(ICAS.oRest_ANAF.ConnectFailReason) )
		    __Consola(" ICAS.oRest_ANAF.responseheader: "		+ Transform(ICAS.oRest_ANAF.responseheader) )
		    __Consola(" ICAS.oRest_ANAF.responsestatuscode: "	+ Transform(ICAS.oRest_ANAF.responsestatuscode) )
		    __Consola(" ICAS.oRest_ANAF.responsestatustext: "	+ Transform(ICAS.oRest_ANAF.responsestatustext) )
		    *__Consola(" ICAS.oRest_ANAF.lasterrortext: "		+ Transform(ICAS.oRest_ANAF.lasterrortext) )
		    Set Step On
			***RETURN .F.
			Return "NOK"
		EndIf
		*
	EndIf
	* 	
	*=================================================
	RETURN lcReturn
	*=================================================
	*
EndFunc
* __________________________________________________________________________________________________________
Procedure InCursor_ListaMesajeFactura(tcJSON)
	*DO DeschidereFisiere
	If !Used("c_Get_Mesaje_SPV")
		*Create Cursor c_Get_Mesaje_SPV (Data_R T, Id_Solicit C(10), Recipisa C(10), Detalii C(250), Tip C(30), Cif C(13))
		Create Cursor c_Get_Mesaje_SPV;
			(;
			Data_R			T,;
			Id_Solicit		C(10),;
			Recipisa		C(10),;
			Detalii			C(250),;
			Tip				C(30),;
			CIF				C(13),;
			Id_Iesire		N(10, 0),;
			Nr_Iesire		C(20),;
			Data			D,;
			Cod				C(20),;
			Denumire		C(64),;
			Ecran			C(6),;
			PDF				M NOCPTRANS;
			)
	Else
		Select c_Get_Mesaje_SPV	
		If Alias() = Upper("c_Get_Mesaje_SPV")
			ZAP
		EndIf
	EndIf
	*
	*=================================================
	loListaMesaje = CreateObject('Chilkat_9_5_0.JsonArray')
	*=================================================
	loListaMesaje.Load(tcJSON)
	*
	LOCAL lcTitlu, lcCnp, lcCui, lcSerial
	LOCAL i, j

	*=================================================
	loJson = CreateObject('Chilkat_9_5_0.JsonObject')
	*=================================================
	loJson.Load(tcJSON)

	lcTitlu 	= loJson.StringOf("titlu")
	lcCnp 		= loJson.StringOf("cnp")
	lcCui 		= loJson.StringOf("cui")
	lcSerial 	= loJson.StringOf("serial")
	
	Local loReturn As Object
	loReturn=CreateObject('SmallClass')
	
	With loReturn
		.AddProperty('json',	tcJSON)
		.AddProperty('serial',	lcSerial)
		.AddProperty('cui',		lcCui)
		.AddProperty('titlu',	lcTitlu)
	EndWith	
	
	i 			= 0
	j 			= loJson.SizeOfArray("mesaje")

	DO WHILE i < j
		SELECT c_Get_Mesaje_SPV
		SCATTER NAME loListaMesaje BLANK 
	    loJson.I = i
	    lcData_Creare				= loJson.StringOf("mesaje[i].data_creare")
	    loListaMesaje.Data_R	 	= CToD(SubStr(m.lcData_Creare, 7, 2)+"."+SubStr(m.lcData_Creare, 5, 2)+"."+SubStr(m.lcData_Creare, 1, 4))
	    loListaMesaje.Id_Solicit	= loJson.StringOf("mesaje[i].id_solicitare")
	    loListaMesaje.Recipisa		= loJson.StringOf("mesaje[i].id")
	    loListaMesaje.Detalii 		= loJson.StringOf("mesaje[i].detalii")
	    loListaMesaje.Tip 			= loJson.StringOf("mesaje[i].tip")
	    loListaMesaje.Cif 			= loJson.StringOf("mesaje[i].cif")
	    INSERT INTO c_Get_Mesaje_SPV FROM NAME loListaMesaje
	    i = i + 1
	EndDo
	*
	Return loReturn
EndProc	
* __________________________________________________________________________________________________________
Function eFactura_API_DescarcareRaspuns(tc_id_descarcare, tcToken, tlProd);
HelpString 'Intoarce fisierul zip descarcat de pe serverul ANAF'
	*
	******************************************************
	*
	**** OBSOLETE		!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	*
	* apelata din meniu.eFactura_toolbar_handle
	*
	* folosesc:
	*	!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 
	*	Descarca_eFactura_Client()
	*	!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	*
	*
	&& RETURN Descarca_eFactura_Client(tc_id_descarcare)
	******************************************************
	*As putea sa verific daca exista descarcat fisierul zip, sa-l nu mai downloadez inca odata.
	*tc_id_descarcare = '3006834037'
	*C:\ICAS\declaratii\e-factura\expert_software_company_srl\trimise\2023\12\15\3006834037.zip
	*
	lcCale_LOG = Get_LOG_EFA()
	Local oSetAlternate As Object, oSetConsole As Object
	oSetConsole=CreateObject("SetConsole", 'Off')
	oSetAlternate=CreateObject("SetAlternate", "On", lcCale_LOG+Program()+".log")
	*
	__Consola([--------------------------------------------------------]			)
	__Consola([Sys(16)() :			( ]		+ Transform(Sys(16))			+ [ )]	)
	__Consola( [] )
	__Consola( [PARAMETERS:  ]														)
	__Consola( [tc_id_descarcare:	( ]		+ Transform(tc_id_descarcare)	+ [ )]	)
	*__Consola( [tcToken:			( ]		+ Transform(tcToken)			+ [ )]	)		&& Nu afisez
	__Consola( [tlProd:				( ]		+ Transform(tlProd)				+ [ )]	)
	__Consola([--------------------------------------------------------]			)
	*
	o_EFA = GetInfo_EFA_From_RECIPISA(AllTrim(Transform(tc_id_descarcare)))	&& Cauta recipisa in Iesiri, Export, Docum
	*	o_EFA: Id_Solicitare,Recipisa,NumarDoc,DataDoc,Ecran,IdDoc
	*
	If VarType(o_EFA)<>'O'
		*o_EFA = GetInfo_EFA_FromZip(tc_id_descarcare)
		o_EFA = .NULL.
		*
		If VarType(o_EFA)<>'O'
			lcErr = "EROARE DE PROGRAMARE GRAVA, nu am gasit datele pt. eFactura cu RECIPISA: " + tc_id_descarcare
			MessageBox(lcErr, 16, "Eroare", 3000)
			__Consola( [lcErr:				( ]		+ Transform(lcErr)				+ [ )]	)
			Return lcErr
		EndIf
		*
	EndIf
	*
	*Local lcFileName As String	nu mai merge MySQL
	lcFolder	= GetFolder_EFactura(o_EFA.DataDoc, Iif(InList(o_EFA.Ecran, 'Iesiri', 'Export'), 1, 2))		&& folder recipise
	*lcFileName	= o_EFA.Id_Solicitare+'.zip'
	lcFileName	= tc_id_descarcare+'.zip'
	lcFileName	= lcFolder+lcFileName
	? 'lcFolder: ', lcFolder
	? 'lcFileName: ', lcFileName
	*
	If File(lcFileName)
		lcErr = 'Fisierul '+lcFileName+' a fost deja descarcat pe PC'
		*MessageBox(lcErr,64, 'Informare', 3000)
		__Consola( [lcErr:				( ]		+ Transform(lcErr)				+ [ )]	)
		*Return lcErr
		*:: Normal ar trebui sa fie deja salvat in SQL
		EFa2SQL(o_EFA.Ecran, lcFileName, CreateBinary(FileToStr(lcFileName)), o_EFA.IdDoc)
		__Consola( [EFa2SQL(o_EFA.Ecran, lcFileName, CreateBinary(FileToStr(lcFileName)), o_EFA.IdDoc)]	)
		*::
		__Consola( [Return lcFileName:	( ]		+ Transform(lcFileName)			+ [ )]	)
		Return lcFileName
	EndIf	
	*
	If Empty(tcToken)
		tcToken = ICAS.oSettings.eFactura_TokenAcces
	EndIf
	*
	If Empty(tlProd)
		tlProd	= ICAS.oSettings.eFactura_Prod
	EndIf
	*
	If tlProd
		lcServer='https://api.anaf.ro/prod/FCTEL/rest/descarcare?id='+AllTrim(Transform(tc_id_descarcare))
	Else
		lcServer='https://api.anaf.ro/test/FCTEL/rest/descarcare?id='+AllTrim(Transform(tc_id_descarcare))
	EndIf
	*
	__Consola( [tlProd:				( ]		+ Transform(tlProd)				+ [ )]	)
	__Consola( [lcServer:			( ]		+ Transform(lcServer)			+ [ )]	)
	lcFileName = ''
	lc_Text=''
	lcSend=''
	loHttp=_GetObject('http')
	lcFile=''
	With loHttp
		.Open('GET', lcServer, .F.)
		.SetRequestHeader("content-type", "application/zip")
		.SetRequestHeader("Authorization","Bearer " + tcToken)
		.Send(lcSend)
		lc_Status	= .StatusText
		lc_Response	= .GetAllResponseHeaders()
		lc_Text		= .ResponseText
		*//////////////////////////////////////////////////////////////////////////////
		lcFileName	= StrExtract(.getResponseHeader('content-disposition'),'filename=','')
		*//////////////////////////////////////////////////////////////////////////////
		lcFile		= .ResponseBody
	EndWith	
	*
	__Consola( [loHttp.StatusText:				( ]		+ Transform(lc_Status)	+ [ )]	)
	__Consola( [loHttp..GetAllResponseHeaders():( ]		+ Transform(lc_Response)+ [ )]	)
	__Consola( [loHttp.ResponseText:			( ]		+ Transform(lc_Text)	+ [ )]	)
	*
	If Occurs("eroare", lc_Text)>0
		*=================================================
		loJson = CreateObject('Chilkat_9_5_0.JsonObject')
		*=================================================
		loJson.Load(lc_Text)
		*	loHttp.ResponseText: 
		* {
		* "eroare":"Pentru id=3006834037 nu exista inregistrata nici o factura",
		* "titlu":"Descarcare mesaj"
		* }	
		lcTitlu 	= loJson.StringOf("titlu")
		lcEroare 	= loJson.StringOf("eroare")
		__Consola( [loHttp.EROARE_titlu:	( ]	+ Transform(lcTitlu)	+ [ )]	)
		__Consola( [loHttp.EROARE_eroare:	( ]	+ Transform(lcEroare)	+ [ )]	)
		Return lcTitlu + Chr(13) + lcEroare 
	EndIf	
	*
	*__Consola( [lcFile: ( ] + Transform(lcFile) + [ )]	)		&& Zip, nu are rost sa afisez.
	&& Daca stare eFactura NU ESTE OK e ok atunci ar trebui sa le salvezi in folderul [ERORI]
	*
	lcFileName	= lcFolder + lcFileName
	StrToFile(lcFile, lcFileName)
	*
	lcFileBinary = CreateBinary(lcFile)
	EFa2SQL(o_EFA.Ecran, lcFileName, CreateBinary(FileToStr(lcFileName)), o_EFA.IdDoc)
	__Consola( [EFa2SQL(o_EFA.Ecran, lcFileName, lcFileBinary , o_EFA.IdDoc)]	)
	*	o_EFA: Id_Solicitare,Recipisa,NumarDoc,DataDoc,Ecran.IdDoc
	TextMerge("Update <<o_EFA.Ecran>> Set EFA_Zip_FileName	= ?lcFileName, EFA_Zip_Content = ?lcFile Where IdDoc = ?o_EFA.IdDoc")

	__Consola( [Return lcFileName:				( ]	+ Transform(lcFileName)				+ [ )]	)			
	__Consola( [] )
	Return lcFileName		&& lcFile
EndFunc
* __________________________________________________________________________________________________________
Function EFa2SQL HelpString "Salveaza EFA_Zip_FileName si EFA_Zip_Content in tabelele Iesiri, Export sau Intrari"
	LParameters tcTabela, tcFullPathFileName, tcBinaryFile, tnIdDoc
	*
	__Consola([--------------------------------------------------------]			)
	__Consola([Sys(16)() :			( ]		+ Transform(Sys(16))			+ [ )]	)
	__Consola( [] 																	)
	__Consola( [PARAMETERS:  ]														)
	__Consola( [tcTabela:			( ]		+ Transform(tcTabela)			+ [ )]	)
	__Consola( [tcFullPathFileName:	( ]		+ Transform(tcFullPathFileName)	+ [ )]	)
	*__Consola( [tcBinaryFile:			( ]	+ Transform(tcBinaryFile)		+ [ )]	)
	__Consola( [tnIdDoc:			( ]		+ Transform(tnIdDoc)			+ [ )]	)
	__Consola([--------------------------------------------------------]			)	
	*
	If IsNullOrEmpty(tcTabela)
		__Consola( [Parametru tcTabela este GOL: ( ] + Transform(tcTabela) + [ )] )
		Return
	EndIf
	*
	Do Case
	&&-- 1)
	Case ll_Is_ICAS
		*
		lcTabela			= tcTabela
		lcFullPathFileName	= tcFullPathFileName
		lcBinaryFile		= tcBinaryFile
		lnIdDoc				= tnIdDoc
		*lcFullPathFileName	= StrTran(lcFullPathFileName, StrExtract(lcFullPathFileName, ':\', '\'), SYS(2003))
		*lcFullPathFileName	= StrTran(lcFullPathFileName, Left(lcFullPathFileName, 2), Sys(5) )
		&&:: Cale RELATIVA
		&& Poate fi: C:\ICAS\, C:\EXE_ICAS\, d:\ICAS, d:\EXE_ICAS, e:\ICAS etc.
		lcFullPathFileName	= StrTran;
								(;
									lcFullPathFileName,;
									SubStr(lcFullPathFileName, 1, At('\', lcFullPathFileName, 2)),;
									Sys(5)+CurDir();
								)
		*
		Text To lcSQL_OLD NoShow TextMerge
			Update
				<<lcTabela>>
			Set
					EFA_Zip_FileName	= ?lcFullPathFileName
				,	EFA_Zip_Content		= ?lcBinaryFile
			Where
					IdDoc				= ?lnIdDoc

		EndText
		*
		Text To lcSQL NoShow TextMerge
			Merge Into <<lcTabela>> i
			Using
				(
			    Select 
			        	[IdDoc] 			= ?lnIdDoc
			        ,	[EFA_Zip_FileName]	= ?lcFullPathFileName
			        ,	[EFA_Zip_Content]	= ?lcBinaryFile
				) f On
						f.IdDoc				= i.IdDoc
			WHEN MATCHED
				AND		f.EFA_Zip_FileName	<> i.EFA_Zip_FileName 
			Then Update Set
						EFA_Zip_FileName	= f.EFA_Zip_FileName,
						EFA_Zip_Content		= f.EFA_Zip_Content;
		EndText
		__Consola( [lcSQL: ( ] + Transform(lcSQL) + [ )] )
		llOk = mySQLExec(lcSQL)
		__Consola( TextMerge("llOk = mySQLExec(Update <<lcTabela>> Set EFA_Zip_FileName	= ?lcFullPathFileName', EFA_Zip_Content = ?lcBinaryFile Where IdDoc = ?lnIdDoc)") + [: ( ] + Transform(llOk) + [ )]	)
		*
	&&-- 2)	
	Case ICAS.cBackEnd='FirebirdSQL'
	*
		lcTabela			= 'DOCUM'
		lcFullPathFileName	= tcFullPathFileName
		lcBinaryFile		= tcBinaryFile
		lnIdDoc				= tnIdDoc
		*lcFullPathFileName	= StrTran(lcFullPathFileName, StrExtract(lcFullPathFileName, ':\', '\'), SYS(2003))
		*lcFullPathFileName	= StrTran(lcFullPathFileName, Left(lcFullPathFileName, 2), Sys(5) )
		&&:: Cale RELATIVA
		&& Poate fi: C:\ICAS\, C:\EXE_ICAS\, d:\ICAS, d:\EXE_ICAS, e:\ICAS etc.
		lcFullPathFileName	= StrTran;
								(;
									lcFullPathFileName,;
									SubStr(lcFullPathFileName, 1, At('\', lcFullPathFileName, 2)),;
									Sys(5)+CurDir();
								)
		*
		Text To lcSQL_OLD NoShow TextMerge
			Update
				<<lcTabela>>
			Set
					EFA_Zip_FileName	= ?lcFullPathFileName
				,	EFA_Zip_Content		= ?lcBinaryFile
			Where
					ID					= ?lnIdDoc

		EndText
		*
		Text To lcSQL NoShow TextMerge
			Merge Into <<lcTabela>> i
			Using
				(
			    Select 
			        	Cast(?lnIdDoc As INTEGER)					 As ID
			        ,	Cast(?lcFullPathFileName As VarChar(254))	 As EFA_Zip_FileName
			        ,	Cast(?lcBinaryFile As BLOB)					 As EFA_Zip_Content
			    From rdb$database    
				) f On
							f.ID				= i.ID
					AND		f.EFA_Zip_FileName	<> Coalesce(i.EFA_Zip_FileName, '') 
			WHEN MATCHED THEN UPDATE SET
						EFA_Zip_FileName	= f.EFA_Zip_FileName,
						EFA_Zip_Content		= f.EFA_Zip_Content;
		EndText
		__Consola( [lcSQL: ( ] + Transform(lcSQL) + [ )] )
		*StrToFile(lcSQL, 'lcSQL.txt')
		llOk = mySQLExec(lcSQL)
		__Consola( TextMerge("llOk = mySQLExec(Update <<lcTabela>> Set EFA_Zip_FileName	= ?lcFullPathFileName', EFA_Zip_Content = ?lcBinaryFile Where IdDoc = ?lnIdDoc)") + [: ( ] + Transform(llOk) + [ )]	)
		*
	&&-- 3)			
	Case ICAS.cBackEnd='MySQL'
		*
	*
		lcTabela			= 'DOCUM'
		lcFullPathFileName	= tcFullPathFileName
		lcBinaryFile		= tcBinaryFile
		lnIdDoc				= tnIdDoc
		*lcFullPathFileName	= StrTran(lcFullPathFileName, StrExtract(lcFullPathFileName, ':\', '\'), SYS(2003))
		*lcFullPathFileName	= StrTran(lcFullPathFileName, Left(lcFullPathFileName, 2), Sys(5) )
		&&:: Cale RELATIVA
		&& Poate fi: C:\ICAS\, C:\EXE_ICAS\, d:\ICAS, d:\EXE_ICAS, e:\ICAS etc.
		lcFullPathFileName	= StrTran;
								(;
									lcFullPathFileName,;
									SubStr(lcFullPathFileName, 1, At('\', lcFullPathFileName, 2)),;
									Sys(5)+CurDir();
								)
		*
		Text To lcSQL NoShow TextMerge
			Update
				<<lcTabela>>
			Set
					EFA_Zip_FileName	= ?lcFullPathFileName
				,	EFA_Zip_Content		= ?lcBinaryFile
			Where
						ID								= ?lnIdDoc
					And	Coalesce(EFA_Zip_FileName, '') <> ?lcFullPathFileName

		EndText
		__Consola( [lcSQL: ( ] + Transform(lcSQL) + [ )] )
		*StrToFile(lcSQL, 'lcSQL.txt')
		llOk = mySQLExec(lcSQL)
		__Consola( TextMerge("llOk = mySQLExec(Update <<lcTabela>> Set EFA_Zip_FileName	= ?lcFullPathFileName', EFA_Zip_Content = ?lcBinaryFile Where IdDoc = ?lnIdDoc)") + [: ( ] + Transform(llOk) + [ )]	)
		*
	EndCase
	*
EndFunc
* __________________________________________________________________________________________________________

Function GetAdditionalFolder(tcAlias)	
	*
	Do Case
			Case tcAlias='Documente' Or tcAlias='Import'
				lcAdditionalFolder='PRIMITE\'
			Case tcAlias='c_eFacturi_Trimise'
				lcAdditionalFolder='TRIMISE\'
			OtherWise
				lcAdditionalFolder=''
	EndCase
	*
	Return lcAdditionalFolder
EndFunc
* __________________________________________________________________________________________________________
Function GetSupplierCompanyLegalForm_Prefix()
	lcPrefix=''
	lcFormaProprietate=ICAS.oSoc.FormaProprietate
	*
	#if .f.
	https://static.anaf.ro/static/10/Anaf/AsistentaContribuabili_r/Nomenclator_forme_juridice.htm
	
		NOMENCLATORUL FORMELOR JURIDICE
	(Utilizat la declaratiile de �nregistrare)
	COD			DENUMIRE
	AFJ			Alte forme juridice
	ASF			Asociatie familial�
	CON			Concesiune
	CRL			Soc civil� profesionala cu pers. juridica si r�spundere limitata (SPRL)
	INC			�nchiriere
	LOC			Locatie de gestiune
	OC1			Organizatie cooperatist� mestesug�reasc�
	OC2			Organizatie cooperatist� de consum
	OC3			Organizatie cooperatist� de credit
	PFA			Persoan� fizic� independent�
	RA			Regie autonom�
	SA			Societate comercial� pe actiuni
	SCS			Societate comercial� �n comandit� simpl�
	SNC			Societate comercial� �n nume colectiv
	SPI			Societate profesionala practicieni in insolventa (SPPI)
	SRL			Societate comercial� cu r�spundere limitat�
	URL			Intreprindere profesionala unipersonala cu r�spundere limitata (IPURL)

	NOMENCLATORUL FORMELOR DE PROPRIETATE
	COD			DENUMIRE
	10			PROPRIETATE DE STAT
	11			Regii autonome
	12			Societati comerciale cu capital integral de stat
	13			Alte unitati economice de stat netransformate �n societati comerciale sau regii autonome
	14			Companii si societati nationale
	20			PROPRIETATE MIXTA (cu capital de stat si privat)
				PROPRIETATE MIXTA (cu capital de stat - sub 50%)
	21			Societati comerciale cu capital de stat autohton si de stat strain
	22			Societati comerciale cu capital de stat si privat autohton si strain
	23			Societati comerciale cu capital de stat si privat autohton
	24			Societati comerciale cu capital de stat si privat strain
	25			Societati comerciale cu capital de stat autohton si de stat strain
	26			Societati comerciale cu capital de stat si privat autohton si strain
	27			Societati comerciale cu capital de stat si privat autohton
	28			Societati comerciale cu capital de stat si privat strain
	30			PROPRIETATE INDIVIDUALA � PRIVATA (cu capital: privat autohton, privat autohton si strain, privat strain, societati agricole)
	31			Societati comerciale �n nume colectiv
	32			Societati comerciale �n comandita simpla
	33			Societati comerciale �n comandita pe actiuni
	34			Societati comerciale pe actiuni
	35			Societati comerciale cu raspundere limitata
	36			Societati agricole
	37			Societati comerciale cu capital de stat, privatizate �n cursul anului 2007
	40			PROPRIETATE COOPERATISTA
	41			Cooperative de consum
	42			Cooperative mestesugaresti
	43			Cooperative si asociatii agricole netransformate
	44			Cooperative de credit
	50			PROPRIETATE OBSTEASCA (societati comerciale apartin�nd organizatiilor si institutiilor politice si obstesti)
	#endif
*	
	Do Case
		Case lcFormaProprietate='11'
			lcPrefix='Regii autonome'
		Case lcFormaProprietate='12'
			lcPrefix='Societati comerciale cu capital integral de stat'
		Case lcFormaProprietate='13'
			lcPrefix='Alte unitati economice de stat netransformate �n societati comerciale sau regii autonome'
		Case lcFormaProprietate='14'
			lcPrefix='Companii si societati nationale'
		Case lcFormaProprietate='15'
			lcPrefix='Societati comerciale reprezentand filiale ale unor societati comerciale cu capital integral de stat'
		Case lcFormaProprietate='16'
			lcPrefix='Societati comerciale reprezentand filiale ale unor societati comerciale cu capital majoritar de stat'
		Case lcFormaProprietate='21'
			lcPrefix='Societati comerciale cu capital de stat autohton si de stat strain'
		Case lcFormaProprietate='22'
			lcPrefix='Societati comerciale cu capital de stat si privat autohton si strain'
		Case lcFormaProprietate='23'
			lcPrefix='Societati comerciale cu capital de stat si privat autohton'
		Case lcFormaProprietate='24'
			lcPrefix='Societati comerciale cu capital de stat si privat strain'
		Case lcFormaProprietate='25'
			lcPrefix='Societati comerciale cu capital de stat autohton si de stat strain'
		Case lcFormaProprietate='26'
			lcPrefix='Societati comerciale cu capital de stat si privat autohton si strain'
		Case lcFormaProprietate='27'
			lcPrefix='Societati comerciale cu capital de stat si privat autohton'
		Case lcFormaProprietate='28'
			lcPrefix='Societati comerciale cu capital de stat si privat strain'
		Case lcFormaProprietate='31'
			lcPrefix='Societati comerciale in nume colectiv'
		Case lcFormaProprietate='32'
			lcPrefix='Societati comerciale in comandita simpla'
		Case lcFormaProprietate='33'
			lcPrefix='Societati comerciale in comandita pe actiuni'
		Case lcFormaProprietate='34'
			lcPrefix='Societati comerciale pe actiuni'
		Case lcFormaProprietate='35'
			lcPrefix='Societati comerciale cu raspundere limitata'
		Case lcFormaProprietate='36'
			lcPrefix='Societati agricole'
		Case lcFormaProprietate='37'
			lcPrefix='Societati comerciale cu capital de stat privatizate �n cursul anului de raportare'
		Case lcFormaProprietate='41'
			lcPrefix='Cooperative de consum'
		Case lcFormaProprietate='42'
			lcPrefix='Cooperative mestesugaresti'
		Case lcFormaProprietate='43'
			lcPrefix='Cooperative si asociatii agricole netransformate'
		Case lcFormaProprietate='44'
			lcPrefix='Cooperative de credit'
		Case lcFormaProprietate='50'
			lcPrefix='Societati comerciale apartinand organizatiilor si institutiilor politice si obstesti'
		OtherWise	
			lcPrefix=''
	EndCase
	*
	If Empty(lcPrefix)
		Do Case
			Case mDenSoc="S.C. " .Or. mDenSoc="SC "
				lcPrefix = "Societate comerciala"
			Case mDenSoc="P.F. " .Or. mDenSoc="PF "
				lcPrefix = "Persoana fizica"
			Case mDenSoc="P.F.A. " .Or. mDenSoc="PFA "
				lcPrefix = "Persoana fizica autorizata"
			Case mDenSoc="A.F. " .Or. mDenSoc="AF "
				lcPrefix = "Asociatie familiala"
			Case " S.R.L."$mDenSoc .Or. " SRL "$mDenSoc
				lcPrefix = "Societate cu raspundere limitata"
			Case " AFJ"$mDenSoc 
				lcPrefix = 'Alte forme juridice'
			Case " AFJ"$mDenSoc 
				lcPrefix = 'Asociatie familiala'
			Case " RA"$mDenSoc 
				lcPrefix = 'Regie autonom�'
		EndCase
		*
	EndIf
	*
	Return lcPrefix
EndFunc
* __________________________________________________________________________________________________________
Function GetSupplierCompanyLegalForm_Sufix()
	lcSufix=''
	Do Case
		Case " S.R.L."$mDenSoc .Or. " SRL "$mDenSoc
			lcSufix = "Societate cu raspundere limitata"
		Case " S.A."$mDenSoc .Or. " SA "$mDenSoc
			lcSufix = "Societate pe actiuni"
	EndCase
	*
	Return lcSufix
EndFunc	
* __________________________________________________________________________________________________________
Function GetCustomerCompanyLegalForm_Prefix()
	lcPrefix=''
	*
	Do Case
		Case mDenSoc="S.C. " .Or. mDenSoc="SC "
			lcPrefix = "Societate comerciala"
		Case mDenSoc="P.F. " .Or. mDenSoc="PF "
			lcPrefix = "Persoana fizica"
		Case mDenSoc="P.F.A. " .Or. mDenSoc="PFA "
			lcPrefix = "Persoana fizica autorizata"
		Case mDenSoc="A.F. " .Or. mDenSoc="AF "
			lcPrefix = "Asociatie familiala"
		OtherWise
			lcPrefix = ""
	EndCase
	*
	Return lcPrefix
EndFunc
* __________________________________________________________________________________________________________	
Function GetCustomerCompanyLegalForm_Sufix()
	Return GetSupplierCompanyLegalForm_Sufix()
EndFunc
* __________________________________________________________________________________________________________	
Function ValidareXMLOnline	(tcFisier, tcStandard, lcRaspunsDUK)
	
	******************************************************
	RETURN EFA_VALIDARE		(tcFisier, tcStandard, @lcRaspunsDUK)
	******************************************************
	
	
	Local lcToken, lcURL, lcStandard
	lcStandard = "FACT1"
	If  .Not. IsNull(tcStandard) .And. VarType(tcStandard)='C'
		lcStandard = tcStandard
	EndIf
	lcURL		= ""
	If IsNullOrEmpty(lcToken)
		lcToken = ICAS.oSettings.eFactura_TokenAcces
		*lcURL = "https://webservicesp.anaf.ro"+"/prod/FCTEL/rest/validare/"+lcStandard
	*Else
		lcURL = "https://api.anaf.ro" + "/prod/FCTEL/rest/validare/"+lcStandard
	EndIf
	lcData = FileToStr(tcFisier)
	oHttp = _GetObject()
	oHttp.Open("POST", lcURL, .F.)
	oHttp.SetRequestHeader('Content-Type', 'text/plain')
	If  .Not. IsNullOrEmpty(lcToken)
		oHttp.SetRequestHeader('Authorization', "Bearer "+lcToken)
	EndIf
	oHttp.Send((lcData))
	oHttp.Status
	lcRaspuns = ""
	If oHttp.Status=200 .Or. oHttp.Status=201
		lcRaspunsBrut = oHttp.ResponseText
		lcStare = StrTran(StrExtract(lcRaspunsBrut, '"stare":', ","), '"', '')
		Do Case
			Case lcStare="ok"
				lcRaspuns = "ok"
			Case lcStare="nok"
				If "Messages"$lcRaspunsBrut .And. "message"$lcRaspunsBrut
					lcRaspuns = StrExtract(lcRaspunsBrut, '[{"message":"', "}],")
				Else
					lcRaspuns = lcRaspunsBrut
				EndIf
			OtherWise
				lcRaspuns = lcRaspunsBrut
		EndCase
	Else
		lcMesaj = ""
		If Empty(oHttp.ResponseText)
			If Lower(AllTrim(oHttp.StatusText))="forbidden"
				lcMesaj = "Nu aveti drepturi de incarcare pe acest cod fiscal, sau codul SPV a expirat. Anulati codul curent, si generati-l din nou."
			EndIf
		Else
			lcMesaj = AllTrim(oHttp.StatusText)
		EndIf
		lcRaspuns = lcMesaj
	EndIf
	lcRaspunsDUK = lcRaspuns
	RETURN lcRaspunsDUK
EndFunc
* __________________________________________________________________________________________________________
Function GenPDFeFacturaOnline
	LParameters tcToken, tcXmlString, tcFisierPDF, tcStandard
	*
	lcCale_LOG = Get_LOG_EFA()
	Local oSetAlternate As Object, oSetConsole As Object, oSetSafety As Object
	oSetConsole=CreateObject("SetConsole", 'Off')
	oSetAlternate=CreateObject("SetAlternate", "On", lcCale_LOG+Program()+".log")		&& +"_"+AllTrim(tcFisierPDF)
	oSetSafety=CreateObject("SetSafety", "Off")
	*
	*__Consola("tcXmlString: ( "	+ Transform(tcXmlString) + [ )] )
	__Consola("tcFisierPDF: ( "	+ Transform(tcFisierPDF) + [ )] )
	__Consola("tcStandard: ( "	+ Transform(tcStandard) + [ )] )
	*
	Local lcUrl, lcStandard
	lcStandard = "FACT1"
	If  .Not. IsNull(tcStandard) .And. VarType(tcStandard)='C'
		lcStandard = tcStandard
	EndIf
	*
	&& 17.07.2024
	*
	IF "CreditNoteLine>"$tcXmlString .AND. "<CreditNote"$tcXmlString
		lcStandard	= "FCN"
	EndIf
	*
	lcUrl = ""
	*
	* && 17.07.2024
	*
*!*		lcRaspuns = GenPDFeFacturaOnline_webservicesp(tcXmlString, tcFisierPDF, tcStandard)
*!*		If lcRaspuns = 'ok' And File(tcFisierPDF)
*!*			Return lcRaspuns
*!*		EndIf
	*	
	* && 17.07.2024
	*
	If IsNullOrEmpty(tcToken)
		tcToken = ICAS.oSettings.eFactura_TokenAcces
		*lcUrl = "https://webservicesp.anaf.ro/prod/FCTEL/rest/transformare/"+lcStandard+"/DA"
	*Else
		*lcUrl = "https://api.anaf.ro/prod/FCTEL/rest/transformare/"+lcStandard
	EndIf
	*
	*lcUrl = "https://api.anaf.ro/prod/FCTEL/rest/transformare/"+lcStandard
	lcUrl = "https://api.anaf.ro/prod/FCTEL/rest/transformare/"+lcStandard+"/DA"		&& 19.07.2024
	*
	*lcData = StrTran(tcXmlString, "urn:oasis:names:specification:ubl:schema:xsd:Invoice-2 ../../UBL-2.1(1)/xsd/maindoc/UBL-Invoice-2.1.xsd", "")
	lcData = tcXmlString
	*
	Try
		oHTTP=_GetObject('http')
		oHttp.Open("POST", lcUrl, .F.)
		oHttp.SetRequestHeader('Content-Type', 'text/plain')
		If  .Not. IsNullOrEmpty(tcToken)
			oHttp.SetRequestHeader('Authorization', "Bearer "+tcToken)
		EndIf
		oHttp.Send((lcData))
		oHttp.Status
		lcRaspuns = ""
		If oHttp.Status=200 .Or. oHttp.Status=201
			lcRaspunsText = oHttp.ResponseText
			Do Case
				Case '{"stare":"nok"'$lcRaspunsText
					lcRaspunsParsat = StrExtract(lcRaspunsText, '"message":"', '"')
					If  .Not. IsNull(lcRaspunsParsat) .And.  .Not. Empty(lcRaspunsParsat)
						If StrTran(lcRaspunsParsat, " ", "")="F:validariglobaleeroarestructura:elementnecunoscut('Invoice')innames" .Or. StrTran(lcRaspunsParsat, " ", "")="UBLVersionID(1)eroarestructura:ordineincorectaadescendentilor"
							lcRaspuns = "nok: Factura PDF nu a fost generata. Eroare server ANAF."+Chr(13)+"Reaccesati ecranul mai tarziu."
						Else
							lcRaspuns = "nok: Eroare de generare PDF."+lcRaspunsParsat
						EndIf
					EndIf
				Case "The requested URL was rejected. Please consult with your administrator."$lcRaspunsText
					lcRaspuns = "nok: Eroare XML e-Factura. Contactati furnizorul programului care a EMIS documentul."
				OtherWise
					lcRaspunsBrut = oHttp.ResponseBody
					= StrToFile(lcRaspunsBrut, tcFisierPDF)
					lcRaspuns = "ok"
			EndCase
		Else
			*lcRaspuns = "nok"
			lcRaspuns = ohttp.responsetext+Chr(13)+ohttp.statustext
		EndIf
	Catch To oErr
		lcRaspuns = "nok:"+AllTrim(oErr.Message)
	EndTry
	*
	Return lcRaspuns
EndFunc
* __________________________________________________________________________________________________________
Function GenPDFeFacturaOnline_webservicesp(tcXmlString, tcFisierPDF, tcStandard)
	lcUrl = "https://webservicesp.anaf.ro/prod/FCTEL/rest/transformare/"+lcStandard+"/DA"
	*
	lcData = tcXmlString
	*
	Try
		oHTTP=_GetObject('http')
		oHttp.Open("POST", lcUrl, .F.)
		oHttp.SetRequestHeader('Content-Type', 'text/plain')
		oHttp.Send((lcData))
		oHttp.Status
		lcRaspuns = ""
		*
		If oHttp.Status=200 .Or. oHttp.Status=201
			*
			lcRaspunsText = oHttp.ResponseText
			Set Step On
			*
			Do Case
				*
				Case '{"stare":"nok"'$lcRaspunsText
					lcRaspunsParsat = StrExtract(lcRaspunsText, '"message":"', '"')
					If  .Not. IsNull(lcRaspunsParsat) .And.  .Not. Empty(lcRaspunsParsat)
						If StrTran(lcRaspunsParsat, " ", "")="F:validariglobaleeroarestructura:elementnecunoscut('Invoice')innames" .Or. StrTran(lcRaspunsParsat, " ", "")="UBLVersionID(1)eroarestructura:ordineincorectaadescendentilor"
							lcRaspuns = "nok: Factura PDF nu a fost generata. Eroare server ANAF."+Chr(13)+"Reaccesati ecranul mai tarziu."
						Else
							lcRaspuns = "nok: Eroare de generare PDF."+lcRaspunsParsat
						EndIf
					EndIf
				*
				Case "The requested URL was rejected. Please consult with your administrator."$lcRaspunsText
					lcRaspuns = "nok: Eroare XML e-Factura. Contactati furnizorul programului care a EMIS documentul."
				*
				OtherWise
					lcRaspunsBrut = oHttp.ResponseBody
					*
					If Not IsNullOrEmpty(lcRaspunsBrut)
						StrToFile(lcRaspunsBrut, tcFisierPDF)
						If Not File(tcFisierPDF)
							lcRaspuns = "nok:Nu aveti drepturi de scriere in folderul de e-Facturi."
						Else
							lcRaspuns = "ok"
						EndIf	
					Else
						lcRaspuns = "nok: Eroare de generare PDF."+lcRaspunsParsat
						Set Step On
					EndIf	
			EndCase
			*
		Else
			*
			*lcRaspuns = "nok"
			lcRaspuns = ohttp.responsetext+Chr(13)+ohttp.statustext
			*
		EndIf
		*
	Catch To oErr
		*
		lcRaspuns = "nok:"+AllTrim(oErr.Message)
		Set Step On
		*
	EndTry
	*
	Return lcRaspuns
	*
EndFunc
* __________________________________________________________________________________________________________	
Function Get_Folder_EFactura_BASE(tnTipFacturi);
HelpString 'Seteaza folderul de baza pentru-eFactura'
	RETURN ExpDir+"Declaratii\E-Factura\"+GetNumeDir()+"\" + ICase(	tnTipFacturi=1, 'TRIMISE', tnTipFacturi=2, 'PRIMITE', '' )
EndFunc
* __________________________________________________________________________________________________________	
Function GetFolder_EFactura(tdDataFactura, tnTipFacturi);
HelpString 'Seteaza folderul unde vor fi descarcate recipisele'
	*
	lcFolderEFactura_Base	= GetFolder_EFactura_InvoiceType(tdDataFactura, tnTipFacturi)
	*
	If IsNullOrEmpty(tdDataFactura)
		*lcFolderEFactura	= lcFolderEFactura_Base + lcTipFacturi + "_RECIPISE_ALTE_APLICATII\"
		lcFolderEFactura	= lcFolderEFactura_Base + "_RECIPISE_ALTE_APLICATII\"
	Else
		*
		If Empty(tnTipFacturi)
			tnTipFacturi=1
		EndIf
		lcYear				= AllTrim(	Transform(Year	(tdDataFactura))		)
		lcMonth				= PadL(		Transform(Month	(tdDataFactura)), 2, '0')
		lcDay				= PadL(		Transform(Day	(tdDataFactura)), 2, '0')
		lcFolderEFactura	= lcFolderEFactura_Base+"\"+lcYear+"\"+lcMonth+"\"+lcDay+"\"
		*
		If lcMonth = '00' Or lcDay = '00'
			Set Step On
		EndIf
		*
		If Not Directory(lcFolderEFactura)
			Md (lcFolderEFactura)
		EndIf
		*
	EndIf
	*	
	Return lcFolderEFactura
EndFunc
* __________________________________________________________________________________________________________
Function GetFolder_EFactura_InvoiceType(tdDataFactura, tnTipFacturi);
HelpString 'Seteaza folderul de baza unde vor fi descarcate recipisele in functie de tipul facturii'
	lcFolderEFactura_Base			= ExpDir+"Declaratii\E-Factura\"+GetNumeDir()+"\"
	lcTipFacturi					= ICase(	tnTipFacturi=1, 'TRIMISE', tnTipFacturi=2, 'PRIMITE' )
	lcFolderEFactura_InvoiceType	= lcFolderEFactura_Base +"\"+ lcTipFacturi+"\"
	Return 							lcFolderEFactura_InvoiceType
EndFunc
* __________________________________________________________________________________________________________
Procedure GetInfo_EFA_From_ID_DEPUNERE(tcID_Depunere)
	*
	lcID_SOLICITARE = tcID_Depunere
	*
	Local lo_EFA As Object
	lo_EFA = Create('SmallClass')
	With lo_EFA
		.AddProperty('Id_Solicitare', '')
		.AddProperty('NumarDoc', '')
		.AddProperty('DataDoc', {})
		.AddProperty('Ecran', '')
	EndWith
	*
	If Type('ll_Is_ICAS')='U'
		Public ll_Is_ICAS
		ll_Is_ICAS = ( VarType(ICAS)='O' And Not IsNull(ICAS) ) And PemStatus(ICAS, 'oCfgSALARII', 5)
	EndIf
	*
	If ll_Is_ICAS
		*
		Text To lcSQL NoShow TextMerge
			Select Id_Solicitare, NumarDoc, DataDoc, Ecran='Iesiri' From Iesiri Where IsNull(Id_Solicitare, '')=?lcID_SOLICITARE And IsNull(Anulat, 0)=0
			Union All
			Select Id_Solicitare, NumarDoc, DataDoc, Ecran='Export' From Export Where IsNull(Id_Solicitare, '')=?lcID_SOLICITARE And IsNull(Anulat, 0)=0
		EndText
		*
	Else
		Text To lcSQL NoShow TextMerge
			Select
				Id_Solicitare
				, Factura As NumarDoc
				, Data_Doc As DataDoc
				, 'Iesiri' As Ecran
			From Docum
			Where
				Coalesce(Id_Solicitare, '')=?lcID_SOLICITARE
		EndText
		*And Tip_Doc = 'FcAviz'
	EndIf	
	*
	mySQLExec(lcSQL, [cGet_EFA])
	*
	If aCountInfo(2)>0
		lo_EFA.Id_Solicitare	= cGet_EFA.Id_Solicitare
		lo_EFA.NumarDoc			= cGet_EFA.NumarDoc
		lo_EFA.DataDoc			= cGet_EFA.DataDoc
		lo_EFA.Ecran			= cGet_EFA.Ecran
	Else
		lo_EFA.Id_Solicitare	= cGet_EFA.Id_Solicitare
		lo_EFA.NumarDoc			= ''
		lo_EFA.DataDoc			= {}
		lo_EFA.Ecran			= ''
		*
		lcReturn = "EROARE DE PROGRAMARE GRAVA, nu am gasit datele pt. eFactura cu indexul de depunere: " + lcID_SOLICITARE
		*MessageBox(lcReturn, 16, "Eroare", 3000)
		*__Consola( [lcReturn:  ] + Transform(lcReturn)  )
		*
	EndIf
	*
	Return lo_EFA
EndProc
* __________________________________________________________________________________________________________
Function GetInfo_EFA_From_RECIPISA(tcRecipisa);
HelpString 'Creeaza un obiect EFA (:Id_Solicitare,Recipisa,NumarDoc,DataDoc,Ecran,IdDoc) daca gaseste recipisa in Iesiri, Export sau DOCUM'
	*
	__Consola([--------------------------------------------------------])
	__Consola( [Program(): ( ] + Transform(Program()) + [ )] )
	__Consola([--------------------------------------------------------])
	*
	&& La facturile primite trebuie sa preiau numarul si data din XML-ul aflat in Zip, daca este posibil
	*
	lcRecipisa = tcRecipisa
	*
	Local lo_EFA As Object
	lo_EFA = Create('SmallClass')
	With lo_EFA
		.AddProperty('Id_Solicitare', '')
		.AddProperty('Recipisa', '')
		.AddProperty('NumarDoc', '')
		.AddProperty('DataDoc', {})
		.AddProperty('Ecran', '')
		.AddProperty('IdDoc', 0)
	EndWith
	*
	If Type('ll_Is_ICAS')='U'
		Public ll_Is_ICAS
		ll_Is_ICAS = ( VarType(ICAS)='O' And Not IsNull(ICAS) ) And PemStatus(ICAS, 'oCfgSALARII', 5)
	EndIf
	*
	Local loSaveSelect As Object
	loSaveSelect=Create("SaveSelect")
	*
	&& In Import nu am campul "Recipisa"	
	*
	If ll_Is_ICAS
		*
		Text To lcSQL NoShow TextMerge
			Select
				Id_Solicitare, Recipisa, NumarDoc, DataDoc, IdDoc, Ecran='Iesiri'
			From Iesiri
			Where
				( IsNull(Recipisa, '')=?lcRecipisa
				Or IsNull(Id_Descarcare, '')=?lcRecipisa
				)
				And IsNull(Anulat, 0)=0
			Union All
			Select
				Id_Solicitare, Recipisa, NumarDoc, DataDoc, IdDoc, Ecran='Export'
			From Export
			Where
				( IsNull(Recipisa, '')=?lcRecipisa
				Or IsNull(Id_Descarcare, '')=?lcRecipisa
				)
				And IsNull(Anulat, 0)=0
			Union All
			Select ''
				As Id_Solicitare, Recipisa, NumarDoc, DataDoc, IdDoc, Ecran='Intrari'
			From Intrari
			Where
				IsNull(Recipisa, '')=?lcRecipisa
				And IsNull(Sters, 0)=0
			Select ''
				As Id_Solicitare, Recipisa, NumarDoc, DataDoc, IdDoc, Ecran='Import'
			From Import
			Where
				IsNull(Recipisa, '')=?lcRecipisa
				And IsNull(Sters, 0)=0
		EndText
		*
	Else
		*
		Text To lcSQL NoShow TextMerge
			Select
					Id_Solicitare
				, 	Recipisa
				,	Factura As NumarDoc
				,	Data_Doc As DataDoc
				,	'Iesiri' As Ecran
				,	Id As IdDoc
			From Docum
			Where
				Coalesce(Recipisa, '')=?lcRecipisa
		EndText
		*And Tip_Doc In ('FcAviz', 'FcFurn')
		*
	EndIf
	*
	llOk = mySQLExec(lcSQL, [cGet_EFA]) 
	__Consola("llOk = mySQLExec(lcSQL, [cGet_EFA]): (" + Transform(llOk) + [)])
	*
	If Not llOk
		__Consola("lcSQL: (" + Transform(lcSQL) + [)])
	EndIf
	*
	If aCountInfo(2)>0
		*
		lo_EFA.Id_Solicitare	= AllTrim(cGet_EFA.Id_Solicitare)
		lo_EFA.Recipisa			= AllTrim(cGet_EFA.Recipisa)
		lo_EFA.NumarDoc			= AllTrim(cGet_EFA.NumarDoc)
		lo_EFA.DataDoc			= cGet_EFA.DataDoc
		lo_EFA.Ecran			= AllTrim(cGet_EFA.Ecran)
		lo_EFA.IdDoc			= cGet_EFA.IdDoc
		__Consola("lo_EFA.Id_Solicit:	( "	+ Transform(lo_EFA.Id_Solicitare)	+ [ )] )		
		__Consola("lo_EFA.Recipisa:		( "	+ Transform(lo_EFA.Recipisa)		+ [ )] )		
		__Consola("lo_EFA.cNumarDoc:	( "	+ Transform(lo_EFA.NumarDoc)		+ [ )] )
		__Consola("lo_EFA.dDataDoc:		( "	+ Transform(lo_EFA.DataDoc)		+ [ )] )	
		__Consola("lo_EFA.Ecran:		( "	+ Transform(lo_EFA.Ecran)		+ [ )] )	
		__Consola("lo_EFA.IdDoc:		( "	+ Transform(lo_EFA.IdDoc)		+ [ )] )	
		*
		Use In (Select([cGet_EFA]))
		*
	Else
		*MessageBox("EROARE DE PROGRAMARE GRAVA, nu am gasit datele pt. eFactura cu RECIPISA: " + tcRecipisa, 16, "Eroare", 3000)
		*Return .F.
		lo_EFA = .F.
	EndIf
	*
	__Consola([Return lo_EFA])
	__Consola([--------------------------------------------------------])
	*	
	Return lo_EFA
EndFunc
* __________________________________________________________________________________________________________
Procedure GetInfo_EFA_From_ZIP(tcIdSolicitare, tcRecipisa, tcNumarDoc, tdDataDoc, tcCod_Fiscal, tcPartener, tnTipFacturi)
	*
	__Consola( [Program():  ] + Transform(Program())  )
	*
	***	Local lo_EFA As Object			&& nu mai face query in MySQLExec()
	lo_EFA = Create('SmallClass')
	*
	With lo_EFA
		.AddProperty('Id_Solicitare',	tcIdSolicitare)
		.AddProperty('Recipisa',		tcRecipisa)
		.AddProperty('NumarDoc',		tcNumarDoc)
		.AddProperty('DataDoc',			tdDataDoc)
		*.AddProperty('Cod_Fiscal',		OnlyNumber(tcCod_Fiscal))
		.AddProperty('Cod_Fiscal',		tcCod_Fiscal)
		.AddProperty('Cod_Fiscal2',		'RO'+tcCod_Fiscal)
		.AddProperty('Partener',		tcPartener)
		.AddProperty('IdDoc',			0)
		.AddProperty('IdUnic',			0)
		.AddProperty('Cont',			'')
		.AddProperty('Ecran',			'')
	EndWith
	*
	If Type('ll_Is_ICAS')='U'
		Public ll_Is_ICAS
		ll_Is_ICAS = ( VarType(ICAS)='O' And Not IsNull(ICAS) ) And PemStatus(ICAS, 'oCfgSALARII', 5)
	EndIf
	*
	If ll_Is_ICAS
		*
		Text To lcSQL NoShow TextMerge
			Select
				i.NumarDoc,
				i.DataDoc,
				i.Cont,
				i.DenumireClient,
				i.IdDoc,
				i.IdUnic,
				Ecran='Iesiri'
			From Iesiri i
			Inner Join Conturi c
				On c.Cont = i.Cont
			Where
				IsNull(i.Anulat, 0)		= 0
				And IsNull(c.Sters, 0)	= 0
				And i.NumarDoc			= ?lo_EFA.NumarDoc
				And i.DataDoc			= ?lo_EFA.DataDoc
				And ( c.Cod_Fiscal		= ?lo_EFA.Cod_Fiscal Or c.Cod_Fiscal = ?lo_EFA.Cod_Fiscal2 )
				-- And i.Is_EF				= 1
			Union All
			Select
				e.NumarDoc,
				e.DataDoc,
				e.Cont,
				e.DenumireClient,
				e.IdDoc,
				e.IdUnic,
				Ecran='Export'
			From Export e
			Inner Join Conturi c
				On c.Cont = e.Cont
			Where
				IsNull(e.Anulat, 0)		= 0
				And IsNull(c.Sters, 0)	= 0
				And e.NumarDoc			= ?lo_EFA.NumarDoc
				And e.DataDoc			= ?lo_EFA.DataDoc
				And ( c.Cod_Fiscal		= ?lo_EFA.Cod_Fiscal Or c.Cod_Fiscal = ?lo_EFA.Cod_Fiscal2 )
				-- And e.Is_EF				= 1
		EndText
		*
	Else
		*
		Text To lcSQL NoShow TextMerge
			Select
				Factura As NumarDoc,
				Data_Doc As DataDoc,
				Cod_Furn As Cont,
				Denum_Furn As DenumireClient,
				ID As IdDoc,
				ID As IdUnic,
				'Iesiri' As Ecran
			From Docum 
			Where
				Factura			= '<<lo_EFA.NumarDoc>>'
				And Data_Doc	= '<<Date2ISO(lo_EFA.DataDoc)>>'
				And ( Cod_Fisc	= '<<lo_EFA.Cod_Fiscal>>' Or Cod_Fisc = '<<lo_EFA.Cod_Fiscal2>>' )
		EndText	
		*
		*-- And Coalesce(Is_EF, 0)	= 1
		*	Where
		*		Factura			= ?lo_EFA.NumarDoc
		*		And Data_Doc	= ?lo_EFA.DataDoc
		*		And ( Cod_Fisc	= ?lo_EFA.Cod_Fiscal Or Cod_Fisc = ?lo_EFA.Cod_Fiscal2 )
		
		*		Factura			= '<<lo_EFA.NumarDoc>>'
		*		And Data_Doc	= '<<Date2ISO(lo_EFA.DataDoc)>>'
		*		And ( Cod_Fisc	= '<<lo_EFA.Cod_Fiscal>>' Or Cod_Fisc = '<<lo_EFA.Cod_Fiscal2>>' )
	EndIf	
	*
	*StrToFile(lcSQL, 'lcSQL.txt') 
	*Modify file lcSQL
	*SQLExec(m.nSQLHandle, lcSQL, [cGet_EFA])
	mySQLExec(lcSQL, [cGet_EFA])
	*
	If aCountInfo(2)>0
		lo_EFA.IdDoc			= cGet_EFA.IdDoc
		lo_EFA.IdUnic			= cGet_EFA.IdUnic
		lo_EFA.Cont				= cGet_EFA.Cont
		lo_EFA.Ecran			= cGet_EFA.Ecran
	Else
		*
		lcReturn = ;
			"Nu am gasit datele pt. eFactura cu indexul de depunere: " + tcIdSolicitare+;
			Chr(13)+;
			'Factura: '+lo_EFA.NumarDoc+' din '+DToS(lo_EFA.DataDoc)
		*MessageBox(lcReturn, 16, "Eroare", 3000)
		*Wait Window NoWait;
			"Nu am gasit datele pt. eFactura cu indexul de depunere: " + tcIdSolicitare+;
			Chr(13)+;
			'Factura: '+lo_EFA.NumarDoc+' din '+DToS(lo_EFA.DataDoc)
		__Consola( [lcReturn:  ] + Transform(lcReturn)  )
		*Set Step On
		*
	EndIf
	*
	Return lo_EFA
EndProc
* __________________________________________________________________________________________________________
Function AlreadyDownloadedZip(tcRecipisa, tnTypeInvoice)
	*-------------------------------------------------------------------------------------------------------
	*
	* -	Apelate de :
	*		DescarcareeFactura
	*		Descarca_eFactura_Client
	*
	* -	Proceduri utilizate:
	*		GetInfo_EFA_From_RECIPISA		&& Cauta recipisa in Iesiri, Export, Docum		OBSOLETE
	*		GetFolder_EFactura				&& folder recipise								OBSOLETE
	*
	*-------------------------------------------------------------------------------------------------------
	__Consola([--------------------------------------------------------])
	__Consola( [Program(): ( ] + Transform(Program()) + [ )] )
	__Consola( [] )
	__Consola( [PARAMETERS: ( ])
	__Consola( [tcRecipisa(): ( ] + Transform(tcRecipisa) + [ )] )
	__Consola( [tnTypeInvoice(): ( ] + Transform(tnTypeInvoice) + [ )] )
	__Consola([--------------------------------------------------------])
	*
	If Empty(tnTypeInvoice)
		tnTypeInvoice = 0
	EndIf
	*
	*=============================================================
	lcFileName = Get_FullPath_Zip_File(tcRecipisa, tnTypeInvoice)
	*=============================================================	
	__Consola( [lcFileName = Get_FullPath_Zip_File(tcRecipisa, tnTypeInvoice)] )
	__Consola( [lcFileName :] + Transform( lcFileName ) )
	*
	If File(lcFileName)
		*
		lcErr = 'Fisierul '+lcFileName+' a fost deja descarcat pe PC'
		__Consola( [lcErr: ( ] + Transform(lcErr) + [ )] )
		*
	Else
		*
		lcErr = 'Fisierul '+lcFileName+' nu a fost descarcat pe PC'
		__Consola( [lcErr: ( ] + Transform(lcErr) + [ )] )
		lcFileName = lcErr
		*
	EndIf	
	*
	__Consola([Return lcFileName])
	__Consola([--------------------------------------------------------])
	*
	Return lcFileName
	*
	*****
	*****
	*****
	*****
	*****
	*
	&& VERIFIC daca nu este descarcata deja
	o_EFA = GetInfo_EFA_From_RECIPISA(AllTrim(Transform(tcRecipisa)))		&& Cauta recipisa
	*
	*-- Pentru intrari nu o sa gasesc recipisa daca nu a fost deja salvata in ICAS sau STOCURI !
	*
	If VarType(o_EFA)<>'O'
		o_EFA = .NULL.
		*
		If VarType(o_EFA)<>'O'
			*MessageBox("EROARE DE PROGRAMARE GRAVA, nu am gasit datele pt. eFactura cu RECIPISA: " + tcRecipisa, 16, "Eroare", 3000)
			lcErr =;
				"Nu am gasit datele pt. eFactura cu RECIPISA: " + tcRecipisa+Chr(13)+;
				"Cel mai probabil a fost transmisa cu alta aplicatie."
			Return lcErr
		EndIf
		*
	EndIf	
	*
	Local lcFileName As String
	lcFolder	= GetFolder_EFactura(o_EFA.DataDoc, Iif(InList(o_EFA.Ecran, 'Iesiri', 'Export'), 1, 2))		&& folder recipise
	***lcFileName	= tcRecipisa+'.zip'
	&& 27.02.2024
	lcFileName	= Iif(InList(o_EFA.Ecran, 'Iesiri', 'Export'), o_EFA.Id_Solicitare, tcRecipisa)+'.zip'
	&& 27.02.2024
	lcFileName	= lcFolder+lcFileName
	__Consola( [lcFolder : ( ] + Transform(lcFolder) + [ )] )
	__Consola( [lcFileName: ( ] + Transform(lcFileName) + [ )] )
	*
	If File(lcFileName)
		lcErr = 'Fisierul '+lcFileName+' a fost deja descarcat pe PC'
		*MessageBox(lcErr,64, 'Informare', 3000)
		__Consola( [lcErr: ( ] + Transform(lcErr) + [ )] )
		*Return lcErr
		*Wait Window lcErr NoWait
		Return lcFileName
	Else
		*
		lcErr = 'Fisierul '+lcFileName+' nu a fost descarcat pe PC'
		*MessageBox(lcErr,64, 'Informare', 3000)
		__Consola( [lcErr: ( ] + Transform(lcErr) + [ )] )
		Return lcErr
	*
	EndIf
	*
EndFunc
* __________________________________________________________________________________________________________
Function DescarcareeFactura(tcRecipisa, tcAlias, tlShowFolder);
HelpString 'Descarca recipisa pentru facturi trimise sau primite'
	*
	lcCale_LOG = Get_LOG_EFA()
	Local oSetAlternate_2 As Object, oSetConsole_2 As Object
	oSetConsole_2=CreateObject("SetConsole", 'Off')
	oSetAlternate_2=CreateObject("SetAlternate", "On", lcCale_LOG+Program()+".log")
	*
	tcRecipisa=AllTrim(tcRecipisa)
	*
	__Consola( [tcRecipisa : ( ] + Transform(tcRecipisa ) + [ )] )		
	__Consola( [tcAlias : ( ] + Transform(tcAlias) + [ )] )
	*	
	If IsNullOrEmpty(tcRecipisa)
		Set Step On
		lcReturn = "Parametrul [tcRecipisa] este gol"
		__Consola( [lcReturn : ( ] + Transform(lcReturn) + [ )] )
		Return lcReturn
	EndIf
	*
	*Daca este "FACTURA PRIMITA" o sa o citesc din ZIP-ul din memorie 
	* sau din cel temporar	"C:\ICAS\DECLARATII\E-Factura\GetNumeDir()\PRIMITE\TEMP\"
	*
	Local lcZipFileName As String
	lcZipFileName = ''
	*
	If InList(tcAlias, 'c_eFacturi_Trimise', 'Sel_EFactura', 'c_Sel_EFact')
		*
		*-- TRIMISE
		*
		lcZipFileName = AlreadyDownloadedZip(tcRecipisa, 1)
		*
		If File( lcZipFileName )
			*ShellExecuteExC(ShortPath(lcZipFileName), 'open')
			__Consola( [lcZipFileName = AlreadyDownloadedZip(tcRecipisa, 1): ( ] + Transform(lcZipFileName) + [ )] )
			RETURN lcZipFileName 
		EndIf
		*
		lo_EFA_Client = Descarca_eFactura_Client(tcRecipisa, tcAlias, tlShowFolder, Evaluate(tcAlias+'.Data') )
		*lcZipFileName = lo_EFA_Client.cZipFileName
		lcZipFileName = GetNumeFisierSafe(	lo_EFA_Client.cZipFileName	)		&&-- 05.11.2024
		
		__Consola( [Descarca_eFactura_Client(tcRecipisa)()] )
		*
	Else	&& Documente
		*
		*-- PRIMITE
		*
		If Occurs("<Invoice xmlns=", Documente.Continut)>0
			*
			lcZipFileName = AllTrim(Documente.Continut)
			__Consola( [lcZipFileName = AllTrim(Documente.Continut)] )
			*
		Else
			*
			lcZipFileName = AlreadyDownloadedZip(tcRecipisa, 2)
			*
			If File( lcZipFileName )
				*ShellExecuteExC(ShortPath(lcZipFileName), 'open')
				__Consola( [lcZipFileName = AlreadyDownloadedZip(tcRecipisa, 2): ( ] + Transform(lcZipFileName) + [ )] )
				RETURN lcZipFileName 
			EndIf
			*
			lcZipFileName = Descarca_eFactura_Furnizor(tcRecipisa)	&& de fapt intoarce obiectul "lo_EFA_Furnizor"
			__Consola( [lcZipFileName=Descarca_eFactura_Furnizor(tcRecipisa)] )
			*
		EndIf	
		*
	EndIf
	*
	__Consola( [lcZipFileName: ( ] + Transform(lcZipFileName) + [ )] )
	*
	Return lcZipFileName
	*
EndFunc
* __________________________________________________________________________________________________________
Function Descarca_eFactura_Client(tcRecipisa, tcAlias, tlShowFolder, tdData_Factura);
	HelpString;
		'Daca nu a fost depasit termenul de 60 zile, Intoarce un OBIECT eFactura cu proprietatile: ;
		Id_Solicit, Recipisa, cZipFileName, cXmlString, cNumarDoc, dDataDoc)'
	*
	If Empty(tdData_Factura)
		*
		tdData_Factura = {}
		*
	Else
		*
		If Date()-tdData_Factura>60
				*
			lcErr =;
				'Factura cu recipisa ' + tcRecipisa + ' nu mai poate fi descarcata de le serverele ANAF' + Chr(13)+;
				'deoarece a fost depasit temernul de 60 de zile impus de ANAF.'
			MessageBox(lcErr, 16, "Eroare")
			Return lcErr
			*
		EndIf
		*
	EndIf
	*
	If Empty(tlShowFolder)
		tlShowFolder = .F.
	EndIf
	*
	If Empty(tcAlias)
		lcErr = 'Parametrul tcAlias lipseste'
		MessageBox(lcErr, 16, "Eroare")
		tcAlias = ''
		Return lcErr
	EndIf
	*
	Local oSetAlternate_1 As Object, oSetConsole_1 As Object, oSetSafety_1 As Object
	lcCale_LOG		= Get_LOG_EFA()
	oSetConsole_1	= CreateObject("SetConsole", 'Off')
	oSetAlternate_1	= CreateObject("SetAlternate", "On", lcCale_Log+Program()+'_'+AllTrim(tcRecipisa)+".log")
	oSetSafety_1	= CreateObject("SetSafety", "Off")
	*
	LOCAL lcCUI, lcToken, lcIndex, llProductie
	llProductie = ICAS.oSettings.eFactura_Prod
	lcCUI   	= ICAS.oSoc.CodFiscal
	lcToken 	= ICAS.oSettings.eFactura_TokenAcces
	lcIndex 	= tcRecipisa
	*
	__Consola("tcRecipisa:	( " + Transform(tcRecipisa) + [ )] )
	__Consola("tcAlias:		( " + Transform(tcAlias)	+ [ )] )
	*
	__Consola([--------------------------------------------------------])
	*****	lc_ID_Solicit	= Get_ID_Solicit(tcRecipisa, 'c_Get_Mesaje_SPV')		&& 24.10.2024
	lc_ID_Solicit	= Get_ID_Solicit(tcRecipisa, tcAlias)							&& 24.10.2024
	__Consola("lc_ID_Solicit	= Get_ID_Solicit(tcRecipisa, 'c_Get_Mesaje_SPV'): " + Transform(lc_ID_Solicit) + [ )] )
	__Consola("lc_ID_Solicit: ( " + Transform(lc_ID_Solicit) + [ )] )
	__Consola([--------------------------------------------------------])
	*
	If IsNullOrEmpty(lc_ID_Solicit)						&& 23.02.2024
		lcErr = 'Nu a reusit identificarea indexului de incarcare pentru recipisa: ' + Transform(tcRecipisa)
		__Consola("lcErr: ( " + Transform(lcErr) + [ )] )
		MessageBox(lcErr, 16, "Eroare", 1000)
		Set Step On
		Return lcErr
	EndIf												&& 23.02.2024
	*
	Local lcZipFileName As String
	Store '' To lcZipFileName
	*
	&& NU o sa gaseasca nici cu tcRecipisa nici cu lc_ID_Solicit
	&& DACA NU a fost transmisa din ICAS
	*

	*-- 13.03.2024
	*-- la facturile TRIMISE o sa descarce un fisier zip de forma lc_ID_Solicit.zip
	*--
	*****	lcZipFileName = AlreadyDownloadedZip( tcRecipisa, 1 )
	lcZipFileName = AlreadyDownloadedZip( lc_ID_Solicit, 1 )
	*--
	*-- 13.03.2024
	
	
	__Consola("lcZipFileName = AlreadyDownloadedZip( tcRecipisa, 1): ( " + Transform(lcZipFileName) + [ )] )
	Assert VarType( lcZipFileName )='C' Message 'Variabila trebuie sa fie de tip string.'
	*
	ll_Exist_FileName = File ( lcZipFileName )
	__Consola("ll_Exist_FileName: ( " + Transform(ll_Exist_FileName) + [ )] )
	*
	If ll_Exist_FileName
		*
		If tlShowFolder
			ShellExecuteExC(ShortPath(lcZipFileName), 'open')
		EndIf
		*
		&& CUM FAC aici sa intorc un OBIECT loEFA ?
		*
		&& 27.02.2024
		*
		lnInvoiceType			= 1
		lo_EFA_CLIENT_From_ZIP	= Get_EFA_From_Zip(lcZipFileName, lc_ID_Solicit, tcRecipisa, lnInvoiceType )
		*****	__Consola("RETURN lcZipFileName: ( " + Transform(lcZipFileName) + [ )] )		
		****	RETURN lcZipFileName
		*
		*Set STEP ON		&& la 'EROARI FACTURA'		nu scrie nimic in c_EFacturi_TRIMISE
		*
		__Consola("tcAlias: ( " + Transform(tcAlias) + [ )] )
		*
		If tcAlias = 'C_EFACTURI_TRIMISE'
			*
			lc_Mesaj_SPV = Get_Mesaj_SPV(tcRecipisa, tcAlias)
			__Consola("lc_Mesaj_SPV: ( " + Transform(lc_Mesaj_SPV) + [ )] )
			*
			*If lc_Mesaj_SPV = "ERORI FACTURA" 
			If lc_Mesaj_SPV = "ERORI FACTURA" OR lc_Mesaj_SPV = 'MESAJ CUMPARATOR TRANSMIS'
				*
				lcXmlString		= lo_EFA_CLIENT_From_ZIP.cXmlString
				llWriteFile		= .F.
				lcErrZIP		= lcZipFileName
				llReturn_oEFA	= .F.
				lcRecipisa		= tcRecipisa
				lcID_Solicitare	= lc_ID_Solicit
				= Get_ERORI_FACTURA( lcXmlString, llWriteFile, lcErrZIP, llReturn_oEFA, lcRecipisa, lcID_Solicitare, lcZipFileName)
			EndIf
			*
		EndIf
		*
		&&:: Nu mai salvez in tabele deoarece sigur a fost salvat la descarcarea fisierului ZIP
		__Consola("Return lo_EFA_CLIENT_From_ZIP: ( " + Transform(lo_EFA_CLIENT_From_ZIP) + [ )] )
		Return lo_EFA_CLIENT_From_ZIP
		*
		&& 27.02.2024
		*
	EndIf
	*	
	Local lcZip As String
	Store '' To lcZip
	LOCAL lnSuccess, loResponse		&&, loRest
	*=================================================
	loResponse = CreateObject('Chilkat_9_5_0.BinData')
	*=================================================
	__Consola([loResponse = " + "CreateObject('Chilkat_9_5_0.BinData'): ( ] + Transform(loResponse) + [ )] )		
	*
	IF llProductie
		lcURL_descarcare = 	'/prod/FCTEL/rest/descarcare?id='
	Else
		lcURL_descarcare = 	'/test/FCTEL/rest/descarcare?id='
	ENDIF 
	*
	__Consola([llProductie: ( ] + Transform(llProductie) + [ )] )
	__Consola( [lcURL_descarcare: ( ]+Transform(lcURL_descarcare) + [ )] )
	lnSuccess = ICAS.oRest_ANAF.FullRequestNoBodyBd("GET",lcURL_descarcare+lcIndex,loResponse)
	__Consola( [ICAS.oRest_ANAF.FullRequestNoBodyBd("GET",]+lcURL_descarcare+lcIndex+[,loResponse): ( ]+Transform(lnSuccess) + [ )] )
	*
	IF (lnSuccess <> 1) THEN
		*
		lcEroare_ICAS_oRest_ANAF	= ICAS.oRest_ANAF.LastErrorText
		lnConnectFailReason			= ICAS.oRest_ANAF.ConnectFailReason
		__Consola( [lnConnectFailReason: ( ]+Transform(lnConnectFailReason) + [ )] )
		*
		If 'The connection already exists, as far as we know..'$lcEroare_ICAS_oRest_ANAF
			*	
			Wait Window TimeOut 0.1 " SpikeArrest, asteptam 1 secunda..."
			lnSuccess = ICAS.oRest_ANAF.FullRequestNoBodyBd("GET",lcURL_descarcare+lcIndex,loResponse)
			*
			IF (lnSuccess <> 1) THEN
				*
				lcEroare_ICAS_oRest_ANAF	= ICAS.oRest_ANAF.LastErrorText
				lnConnectFailReason			= ICAS.oRest_ANAF.ConnectFailReason
			    __Consola("EFA_Descarcare: Nu se poate efectua GET/descarcare > api.anaf.ro: ( " + GetErr_Chilkat_Rest(lnConnectFailReason) +[; ]+lcEroare_ICAS_oRest_ANAF+ [ )] ) 
				RELEASE loResponse
				RETURN "EFA_Descarcare: Nu se poate efectua GET/descarcare > api.anaf.ro" + GetErr_Chilkat_Rest(lnConnectFailReason)+[; ]+lcEroare_ICAS_oRest_ANAF
				*
			EndIf
			*			
		ELSE
			*
		    __Consola("EFA_Descarcare: Nu se poate efectua GET/descarcare > api.anaf.ro: ( " + GetErr_Chilkat_Rest(lnConnectFailReason)+[; ]+lcEroare_ICAS_oRest_ANAF + [ )] ) 
			RELEASE loResponse
			RETURN "EFA_Descarcare: Nu se poate efectua GET/descarcare > api.anaf.ro" + GetErr_Chilkat_Rest(lnConnectFailReason)+[; ]+lcEroare_ICAS_oRest_ANAF
			*
		EndIf
		*	
	ENDIF
	*
	lnResponseStatusCode = ICAS.oRest_ANAF.ResponseStatusCode
	__Consola("ICAS.oRest_ANAF.ResponseStatusCode: ( " + Transform(lnResponseStatusCode) + [ )] )		
	*
	IF lnResponseStatusCode = 200
		*=================================================
		lcTip = Evaluate(tcAlias + '.Tip')
		lo_EFA_CLIENT = Descarc_EFA_CLIENT_ZIP(loResponse, lcIndex, tcAlias, tlShowFolder, lcTip)
		*=================================================
		__Consola("lcTip: ( " + Transform(lcTip) + [ )] )
		__Consola("lo_EFA_CLIENT = Descarc_EFA_CLIENT_ZIP(loResponse, lcIndex, tcAlias, tlShowFolder, lcTip): ( " + Transform(lo_EFA_CLIENT) + [ )] )		
	ELSE
		*IF (lnResponseStatusCode >= 400) 
		IF (lnResponseStatusCode > 200) 
		    __Consola("EFA_Descarcare: Nu se poate efectua Stare > api.anaf.ro" + STR(ICAS.oRest_ANAF.ConnectFailReason))
		    RETURN ''
		ENDIF
	ENDIF
	*
	*Return lcZip
	Return lo_EFA_CLIENT
EndFunc
* __________________________________________________________________________________________________________
Function Descarc_EFA_CLIENT_ZIP(toResponse, tcIndex, tcAlias, tlShowFolder, tcTip)
	*
	__Consola([--------------------------------------------------------])
	__Consola([Program() :	( ]		+ Transform(Program())		+ [ )] )		
	__Consola( [] )
	__Consola( [PARAMETERS:  ])
	__Consola( [toResponse:	( ]		+ Transform(toResponse)		+ [ )] )
	__Consola( [tcIndex:	( ]		+ Transform(tcIndex)		+ [ )] )
	__Consola( [tcAlias:	( ]		+ Transform(tcAlias)		+ [ )] )
	__Consola( [tlShowFolder:( ]	+ Transform(tlShowFolder)	+ [ )] )
	__Consola( [tcTip:( ]			+ Transform(tcTip)			+ [ )] )
	__Consola([--------------------------------------------------------])
		*
	If Empty(tcAlias)
		tcAlias = ''
		lcErr = 'Lipseste parametrul [ tcAlias ]'
		__Consola([lcErr : ( ] + Transform(lcErr) + [ )] )		
		MessageBox(lcErr, 16, "Eroare")
		Return lcErr
	EndIf
	*
	If Empty(tlShowFolder)
		tlShowFolder = .F.
	EndIf
	*
	If IsNullOrEmpty(tcIndex)
		lcEroare_MsgBox = "Parametrul [tcIndex:] este gol."+Chr(13)+Program()
		MessageBox(lcEroare_MsgBox, 16, "Eroare", 3000)
		__Consola([lcEroare_MsgBox : ( ] + Transform(lcEroare_MsgBox) + [ )] )		
		Return lcEroare_MsgBox
	EndIf
	*	
	LOCAL loJSON, lcDescRaspuns, lcTitlu, lcEroare, lnSuccess, loZip, loZipEntry, llGasit, i, lcXML, llXML, llDescErr, llDescOK
	*
	__Consola([--------------------------------------------------------])
	*=============================================================
	lc_ID_Solicit	= Get_ID_Solicit(tcIndex, "c_Get_Mesaje_SPV")
	*=============================================================
	__Consola( [lc_ID_Solicit: ( ]	+ Transform(lc_ID_Solicit) + [ )] )			
	__Consola([--------------------------------------------------------])
	*
	lcXML			= lc_ID_Solicit+".xml"
	o_EFA			= GetInfo_EFA_From_RECIPISA(tcIndex)		&& Cauta recipisa in Iesiri, Export, Docum
	__Consola( [lcXML: ( ]	+ Transform(lcXML) + [ )] )		
	__Consola( [o_EFA: ( ]	+ Transform(o_EFA) + [ )] )
	*
	Store .T. To ll_EFA_By_VICOS
	__Consola( [ll_EFA_By_VICOS: ( ]			+ Transform(ll_EFA_By_VICOS) + [ )] )
	*
	If Not ( Vartype(m.o_EFA)='O' And Not IsNull(m.o_EFA) )		&& obiectul "o_EFA" nu s-a initializat
		*
		*If AllTrim(tcTip)=='FACTURA TRIMISA'					&& 08August2024	Poate fi "ERORI FACTURA", 'MESAJ CUMPARATOR TRANSMIS', 'MESAJ CUMPARATOR PRIMIT'
		If InList(AllTrim(tcTip), 'FACTURA TRIMISA', "ERORI FACTURA", 'MESAJ CUMPARATOR TRANSMIS', 'MESAJ CUMPARATOR PRIMIT')
			*
			lcDescRaspuns =;
				"Nu a reusit initializarea obiectului o_EFA pentru Indexul: "+tcIndex+Chr(13)+;
				'Probabil XML-ul  a fost depus cu alta aplicatie...'
				
			__Consola( lcDescRaspuns )
			
			*Wait Window lcDescRaspuns NoWait
			MessageBox(lcDescRaspuns, 16, "Eroare")
			Set Step On
			
			&& Vicos.12.04.2024
			lcFolder		= GetFolder_EFactura({}, 1)			&& TRIMISE\trimise_recipise_alte_aplicatii
			lcFolder_ERORI	= lcFolder+'\ERORI\'
			lc_ID_Solicit	= c_EFacturi_Trimise.ID_Solicit
			Store .F. To ll_EFA_By_VICOS
			__Consola( [ll_EFA_By_VICOS: ( ]			+ Transform(ll_EFA_By_VICOS) + [ )] )
			*&& Vicos.12.04.2024
			*
		EndIf													&& 08August2024
		*
				
	*EndIf	&& Vicos.12.04.2024
	*
	Else	&& Vicos.12.04.2024
		lcFolder		= GetFolder_EFactura				(o_EFA.DataDoc, 1)	
		lcFolder_ERORI	= GetFolder_EFactura_InvoiceType	(o_EFA.DataDoc, 1) + 'ERORI\'		&& TRIMISE\ERORI\
	EndIf	&& Vicos.12.04.2024
	*
	__Consola( [lcFolder: ( ] + Transform(lcFolder) + [ )] )
	ll_lcFolder_Exist = Directory(lcFolder)
	*
	If Not ll_lcFolder_Exist
		Md (lcFolder)
		__Consola( [Md (lcFolder): ( ] + Transform(lcFolder) + [ )] )
	EndIf
	*
	__Consola( [lcFolder_ERORI: ( ] + Transform(lcFolder_ERORI) + [ )] )
	ll_lcFolder_Erori_Exist = Directory(lcFolder_ERORI)
	*
	If Not ll_lcFolder_Erori_Exist
		Md (lcFolder_ERORI)
		__Consola( [Md (lcFolder_ERORI): ( ] + Transform(lcFolder_ERORI) + [ )] )
	EndIf
	*
	lcZip		= lcFolder					+ lc_ID_Solicit + ".zip"
	*lcErrZIP	= lcFolder		+ "\ERORI\"	+ lc_ID_Solicit + ".zip"
	lcErrZIP	= lcFolder_ERORI			+ lc_ID_Solicit + ".zip"
	__Consola( [lcZip): ( ]		+ Transform(lcZip)		+ [ )] )
	__Consola( [lcErrZIP): ( ]	+ Transform(lcErrZIP)	+ [ )] )
	*
	*If Not Directory(lcFolder + "\ERORI\")
	*	Md (lcFolder + "\ERORI\")
	*	__Consola( [Md (lcFolder + "\ERORI\"): ( ] + Transform(lcFolder + "\ERORI\") + [ )] )
	*EndIf	
	*
	*=================================================
	loZip = CreateObject('Chilkat_9_5_0.Zip')
	*=================================================
	lnSuccess = loZip.OpenBd(toResponse)
	__Consola( [loZip): ( ]									+ Transform(loZip)		+ [ )] )
	__Consola( [lnSuccess = loZip.OpenBd(toResponse)] )
	__Consola( [lnSuccess : ( ]	+ Transform(lnSuccess)	+ [ )] )
	*
	IF (lnSuccess = 0) THEN
		*{"eroare":"S-au facut deja 10 descarcari la mesajul cu id_descarcare=3220104370  in cursul zilei","titlu":"Descarcare mesaj"}		
		Set Step On
		
		*lcDescRaspuns = "ZIP incorect"
		lcDescRaspuns = toResponse.GetString("utf-8")
		__Consola( [lcDescRaspuns : ( ]	+ Transform(lcDescRaspuns)	+ [ )] )
		*
		If tcAlias = 'c_EFacturi_TRIMISE'
			Replace Detalii With lcDescRaspuns  In c_EFacturi_TRIMISE
		EndIf
		*
		*REPLACE DescRaspuns WITH lcDescRaspuns, DescOK WITH .F. IN EFA_Descarcare_Note
		toResponse.WriteFile		(				lc_ID_Solicit + '_EROARE_ZIP_INCORECT.txt'	)
		lcEroare_toResponse		=	FileToStr(		lc_ID_Solicit + '_EROARE_ZIP_INCORECT.txt'	)
		lcEroare_loRest			=	ICAS.oRest_ANAF.LastErrorText
		lcEroare_loZip			=	loZip.LastErrorText
	    __Consola("api.anaf.ro: zip incorect: "+ lcDescRaspuns + Chr(13) + lcEroare_toResponse+Chr(13)+lcEroare_loRest+Chr(13)+lcEroare_loZip)
	    *Set Step ON
		RELEASE loZip 
		*RETURN lcDescRaspuns 
		*RETURN "api.anaf.ro: zip incorect "+lcEroare_toResponse+Chr(13)+lcEroare_loRest+Chr(13)+lcEroare_loZip
		If ( Vartype(m.o_EFA)='O' And Not IsNull(m.o_EFA) )	
			Return m.o_EFA
		Else	
			Return Get_EFA_4RETURN ( tcIndex, lc_ID_Solicit, lcZip, lcErrZIP, FileToStr(lcZip), '', {} )	&& creeaza un obiect EFA din ce exista
		EndIf	
	ENDIF
	*	
	lcDescRaspuns = ""
	llDescOK = .F.
	llDescErr = .F.
	llXML = .F.
	lc_Recipisa			= tcIndex
	lcNumarDoc				= ''
	ldDataDoc				= {}
	__Consola( [lc_Recipisa): ( ]	+ Transform(lc_Recipisa)	+ [ )] )
	__Consola( [lcNumarDoc): ( ]	+ Transform(lcNumarDoc)	+ [ )] )
	__Consola( [ldDataDoc): ( ]		+ Transform(ldDataDoc)	+ [ )] )
	
	*
*!*		
*!*		*		&& ALTA VARIANTA
*!*		If Upper(Justext(vFis))='ZIP'
*!*			oShell = Createobject("WScript.Shell")
*!*			oShell.Run('7za x "'+vFis+'" -o"'+Justpath(vFis)+'" -x!"semnatura*.xml" -y', 0, .T.)
*!*			NrFis = Adir(arrD, vDirector+'\*.xml')
*!*			If NrFis<1
*!*				Return
*!*			Endif
*!*			vFis = vDirector+'\'+arrD(1)
*!*		EndIf
*!*		*		&& ALTA VARIANTA
*!*		
	*=================================================
	loXml = CreateObject('Chilkat_9_5_0.Xml')		
	*=================================================
	lnNumEntries = loZip.NumEntries
	__Consola( [loXml): ( ]			+ Transform(loXml)			+ [ )] )
	__Consola( [lnNumEntries): ( ]	+ Transform(lnNumEntries)	+ [ )] )
	*
	FOR i = 0 TO lnNumEntries-1
	    loEntry			= loZip.GetEntryByIndex(i)
	    ll_Found_XML	= loEntry.FileName = lcXML
		__Consola( [i): ( ]					+ Transform(i)					+ [ )] )
	    __Consola( [loEntry.FileName): ( ]	+ Transform(loEntry.FileName)		+ [ )] )
	    __Consola( [ll_Found_XML: ( ]		+ Transform(ll_Found_XML)		+ [ )] )
	    *
		IF .NOT. llXML AND ll_Found_XML
			llXML = .T.
			*IF EFA_Descarcare_Note.DescStare = "nok"
			*=================================================
			lc_Mesaj_SPV = Get_Mesaj_SPV(tcIndex, tcAlias)			&& FACTURA PRIMITA,FACTURA TRIMISA,ERORI FACTURA,MESAJ CUMPARATOR PRIMIT / MESAJ CUMPARATOR TRANSMIS
			*
			*	Lista Mesaje � lista de raspunsuri disponibile pentru descarcare:
			*
			* Parametrii raspuns:
			* - data_creare = data raspunsului
			* - cif = cif-ul pentru care este raspunsul descarcabil
			* - id_solicitare = indexul de incarcare primit la upload-ul fisierului
			* - detalii � amanunte despre r�spuns
			* - cif_emitent = cif-ul emitentului facturii (v�nz�tor)
			* - cif_beneficiar = cif-ul beneficiarului facturii (cumparator)
			* - tip:
			* 	. FACTURA TRIMISA = raspuns cu factura originala si semnatura MF, transmis in urma transmiterii unei facturi, daca este validata de sistem
			* 	. FACTURA PRIMITA = factura primita in calitate de cunparator de la un emitent care a folosit sistemul national privind factura electronica RO e-factura
			* 	. ERORI FACTURA = raspuns cu erorile si semnatura MF, livrat in urma transmiterii unei facturi, daca NU este validata de sistem
			*	. MESAJ CUMPARATOR PRIMIT / MESAJ CUMPARATOR TRANSMIS
			
			# if .f.
			{
            "data_creare": "202207061644",
            "cif": "14916343",
            "id_solicitare": "573117",
            "detalii": "Erori de validare identificate la factura primita cu id_incarcare=573117",
            "tip": "ERORI FACTURA",
            "id": "9868551"
            }
            #endif			
			*=================================================
			__Consola( [tcIndex: ( ] + Transform(tcIndex) + [ )] )
			__Consola( [lc_Mesaj_SPV = Get_Mesaj_SPV(tcIndex, tcAlias)): ( ] + Transform(lc_Mesaj_SPV) + [ )] )
			__Consola( [ll_EFA_By_VICOS: ( ] + Transform(ll_EFA_By_VICOS) + [ )] )
			*
			ll_Continue = InList(lc_Mesaj_SPV , "FACTURA TRIMISA") Or ll_EFA_By_VICOS=.F.
			__Consola( [ll_Continue: ( ] + Transform(ll_Continue) + [ )] )
			*
			lcDescRaspuns	= CleanXMLPrefix( loEntry.UnzipToString(0,"utf-8") )		&& OpenFromMemory
			*
			*__Consola( [OpenFromMemory: lcDescRaspuns = loEntry.UnzipToString(0,"utf-8") : ( ] + Transform(lcDescRaspuns) + [ )] )
			__Consola( [OpenFromMemory: lcDescRaspuns = loEntry.UnzipToString(0,"utf-8") : ( ] )
			*			
			
			*If lc_Mesaj_SPV = "ERORI FACTURA"
			If lc_Mesaj_SPV = "ERORI FACTURA" Or lc_Mesaj_SPV = 'MESAJ CUMPARATOR TRANSMIS'
				*
				loXml_ERR		= Createobject('Chilkat_9_5_0.Xml')
				lcMesajEroare	= ""
				lnSucces		= loXml_ERR.LoadXml(lcDescRaspuns)
				? "lnSucces		= loXml_ERR.LoadXml(lcDescRaspuns)"
				? "lnSucces",	Transform(lnSucces)
				*
				If lnSucces		= 1
					*
					* Citeste atributele radacinii 'header'
					*lcHeader_xmlns				= loXml_ERR.GetAttrValue("xmlns")
					lcHeader_Index_incarcare	= loXml_ERR.GetAttrValue("Index_incarcare")
					lcHeader_Cif_emitent		= loXml_ERR.GetAttrValue("Cif_emitent")
					*? "lcHeader_xmlns ", lcHeader_xmlns
					? "Index_incarcare ",		lcHeader_Index_incarcare
					? "Cif_emitent ",			lcHeader_Cif_emitent
					*
					lnCount_i = loXml_ERR.NumChildrenHavingTag("Error")
					*
					For i=0 To lnCount_i-1
					    loXml_ERR.I = i
					    lcError_errorMessage = loXml_ERR.ChilkatPath("Error[i]|(errorMessage)")
					    ? "Mesaj eroare ("+Transform(i)+"): ", lcError_errorMessage
					    lcMesajEroare = lcMesajEroare + "Mesaj eroare ("+Transform(i)+"): " + lcError_errorMessage  + Chr(13)
					EndFor
					*
				EndIf
				*
				IF !EMPTY(lcMesajEroare)
					__Consola( [lcMesajEroare: ( ] + Transform(lcMesajEroare) + [ )] )
					*REPLACE DescRaspuns WITH lcDescRaspuns, DescOK WITH .F. IN EFA_Descarcare_Note
					*
					If tcAlias = 'C_EFACTURI_TRIMISE'
						Replace; 
							Detalii		With lcMesajEroare,;
							Continut	With lcDescRaspuns;
						In C_EFACTURI_TRIMISE
					EndIf
					*
					_Screen.ActiveForm.Refresh()
					*
					toResponse.WriteFile(lcErrZIP)
					loZip.CloseZip()
					*
					*RETURN .F.
					Return Get_EFA_4RETURN ( tcIndex, lc_ID_Solicit, lcZip, lcErrZIP, lcDescRaspuns, '', {} )	&& creeaza un obiect EFA din ce exista					
				ENDIF 
				*
			Else				If lc_Mesaj_SPV = "ERORI FACTURA", MESAJ CUMPARATOR PRIMIT / MESAJ CUMPARATOR TRANSMIS
				*
				If ll_Continue		&& Vicos.12.02.2024
					*
					lcRecipisa		= tcIndex
					llDescOK		= .F.
					llDescErr		= .T.
					&&Vicos12.02.2024
					*=================================================
					loXml.LoadXml(CleanXMLPrefix( lcDescRaspuns ) )
					*
					*=================================================
					lcNumarDoc				= loXml.GetChildContent("*:ID") 
					ldDataDoc_ReadFromXML	= loXml.GetChildContent("*:IssueDate")
					ldDataDoc				= CToD( ANSI2MDY( loXml.GetChildContent("*:IssueDate") ) )
					__Consola("ldDataDoc_ReadFromXML: ( "	+ Transform(ldDataDoc_ReadFromXML) + [ )] )
					__Consola("lcNumarDoc: ( "	+ lcNumarDoc)
					__Consola("ldDataDoc: ( "	+ Transform(ldDataDoc ) + [ )] )
					*
					If Empty(ldDataDoc)
						*
						lcMesaj			= loXml.GetAttrValue("message")
						*
						If IsNullOrEmpty(lcMesaj)
							MessageBox(Program() + Chr(13) + 'Nu a reusit extragerea elementului [Data factura] din fisierul XML.', 16, "Eroare", 1500)
							Set Step On
						EndIf
						*
					EndIf
					&&  Am aflat numarul si data facturii
					&& deci pot sa setez CORECT folderul de descarcare a fisierului ZIP
					*
					lcFolder				= GetFolder_EFactura(ldDataDoc , 1)
					ll_lcFolder_Exist		= Directory(lcFolder)
					*
					If Not ll_lcFolder_Exist
						Md (lcFolder)
						__Consola( [Md (lcFolder): ( ] + Transform(lcFolder) + [ )] )
					EndIf
					*
					lcZip					= lcFolder					+ lc_ID_Solicit + ".zip"
					__Consola( [lcZip):				( ]	+ Transform(lcZip)		+ [ )] )
					*
					lcFolder_ERORI			= GetFolder_EFactura_InvoiceType(o_EFA.DataDoc, 1) + 'ERORI\'		&& TRIMISE\ERORI\
					ll_lcFolder_Erori_Exist = Directory(lcFolder_ERORI)
					*
					If Not ll_lcFolder_Erori_Exist
						Md (lcFolder_ERORI)
						__Consola( [Md (lcFolder_ERORI): ( ] + Transform(lcFolder_ERORI) + [ )] )
					EndIf
					*
					*lcErrZIP				= lcFolder		+ "\ERORI\"	+ lc_ID_Solicit + ".zip"
					lcErrZIP				= lcFolder_ERORI + lc_ID_Solicit + ".zip"
					__Consola( [lcFolder): 			( ]	+ Transform(lcFolder)		+ [ )] )
					__Consola( [lcErrZIP): 			( ]	+ Transform(lcErrZIP)	+ [ )] )
					__Consola( [lcFolder_ERORI:		( ] + Transform(lcFolder_ERORI) + [ )] )
					*
					*
					lcCodFiscalFactura		= loXml.GetChildContent("*:AccountingCustomerParty|*:Party|*:PartyTaxScheme|*:CompanyID")
					__Consola("lcCodFiscalFactura: ( "	+ Transform(lcCodFiscalFactura) + [ )] )
					*
					ll_IsNullOrEmpty_lcCodFiscalFactura = IsNullOrEmpty(lcCodFiscalFactura)
					*
					If ll_IsNullOrEmpty_lcCodFiscalFactura 
						__Consola("lcCodFiscalFactura: ( "	+ Transform(ll_IsNullOrEmpty_lcCodFiscalFactura ) + [ )] )
						*
						lcCodFiscalFactura	= loXml.GetChildContent("*:AccountingCustomerParty|*:Party|*:PartyLegalEntity|*:CompanyID")
						__Consola("lcCodFiscalFactura: ( "	+ Transform(lcCodFiscalFactura) + [ )] )
					EndIf
					*
					lcCodFiscalFactura = OnlyNumber(lcCodFiscalFactura)
					*
					lcDenumireClient = loXml.GetChildContent("*:AccountingCustomerParty|*:Party|*:PartyLegalEntity|*:RegistrationName")
					__Consola("lcDenumireClient: ( "	+ Transform(lcDenumireClient) + [ )] )	
					*								
					*lcAliasFacturi = 'c_eFacturi_Trimise'
					lcAliasFacturi		= tcAlias
					lc_Recipisa_Alias	= AllTrim(Evaluate(tcAlias+'.Recipisa'))
					ll_SEEK				= Used(tcAlias) And lc_Recipisa_Alias==AllTrim(tcIndex)
					*
					If ll_SEEK
						*
						__Consola("ll_SEEK = Used(tcAlias) And lc_Recipisa_Alias==AllTrim(tcIndex): ( " + Transform(ll_SEEK) + [ )] )
						__Consola('')
						*
						lc_Id_Solicitare	= lc_ID_Solicit
						lc_Recipisa			= tcIndex
						lc_NumarDoc			= lcNumarDoc
						ld_DataDoc			= ldDataDoc
						lc_Cod_Fiscal		= lcCodFiscalFactura
						lc_Partener			= lcDenumireClient
						ln_TipFacturi		= 1						&& FACTURI TRIMISE
						__Consola("lc_ID_Solicit: ( "	+ Transform(lc_ID_Solicit) + [ )] )
						__Consola("lc_Recipisa: ( "		+ Transform(lc_Recipisa) + [ )] )
						__Consola("lc_NumarDoc: ( "		+ Transform(lc_NumarDoc) + [ )] )
						__Consola("ld_DataDoc: ( "		+ Transform(ld_DataDoc) + [ )] )
						__Consola("lc_Cod_Fiscal: ( "	+ Transform(lc_Cod_Fiscal) + [ )] )
						__Consola("lc_Partener: ( "		+ Transform(lc_Partener) + [ )] )
						__Consola("			: ( "	+ Transform(ln_TipFacturi) + [ )] )
						*
						If Not IsNullOrEmpty(lcNumarDoc) And Not IsNullOrEmpty(ldDataDoc) And Not IsNullOrEmpty(lcCodFiscalFactura)
							*
							lo_EFA_From_ZIP		= GetInfo_EFA_From_ZIP(lc_Id_Solicitare, lc_Recipisa, lc_NumarDoc, ld_DataDoc, lc_Cod_Fiscal, lc_Partener, ln_TipFacturi)
							__Consola("tcAlias: ( "			+ Transform(tcAlias) + [ )] )
							*
							Do Case
								*
								Case tcAlias = 'C_E_RASP'
									Replace; 
										Cod_Fiscal	With lcCodFiscalFactura,;
										Denumire	With lcDenumireClient,;	
										Data		With ldDataDoc,;
										Nr_Iesire	With lcNumarDoc;
										, Id_Iesire	With lo_EFA_From_ZIP.IdDoc;
										, Ecran		With lo_EFA_From_ZIP.Ecran;
									In (tcAlias)
								*
								Case tcAlias = 'C_EFACTURI_TRIMISE'
									Replace; 
										Continut	With lcDescRaspuns,;
										Cale		With lcZip,;
										Cod_Fiscal	With lcCodFiscalFactura,;
										Denumire	With lcDenumireClient,;	
										Data		With ldDataDoc,;
										Nr_Iesire	With lcNumarDoc;
										, Id_Iesire	With lo_EFA_From_ZIP.IdDoc;
										, Ecran		With lo_EFA_From_ZIP.Ecran;
									In C_EFACTURI_TRIMISE
									*Select C_EFACTURI_TRIMISE
									*Browse Normal
								*
								Case tcAlias = 'Sel_eFactura'
									Replace; 
										Continut	With lcDescRaspuns,;
										Cale		With lcZip;
										, Ecran		With lo_EFA_From_ZIP.Ecran;
									In Sel_eFactura
								*	
								OtherWise
									*
							EndCase	
							*
							__Consola("Replace NumarDoc, DataDoc, Id_Iesire... In (tcAlias)")
							*
							*&& Actualizez datele pe server cu cele din RO-EFactura care au fost transmise cu alte aplicatii
							*
							*Is_EF
							*Id_Solicitare
							*Recipisa
							*efact_Detalii
							*efact_Tip
							*efact_Stare
							*efact_DataIncarcare	= ?ld_Data_R
							*EF_Data_Validare
							ln_Is_EF			= 1
							lc_efact_Detalii	= Iif(tcAlias = 'C_EFACTURI_TRIMISE', C_EFACTURI_TRIMISE.Detalii, '')
							lc_efact_Stare		= ''
							ld_Data_R			= Iif(tcAlias = 'C_EFACTURI_TRIMISE', C_EFACTURI_TRIMISE.Data_R, {})
							lcTabela 			= Iif(ll_Is_Icas, lo_EFA_From_ZIP.Ecran, 'DOCUM')
							lcFieldID			= Iif(ll_Is_ICAS, 'IdDoc', 'ID')
							*
							If IsNullOrEmpty(lcTabela)
								*MessageBox("variabila [lcTabela] este goala", 16, "Eroare", 2000)
								*Set Step On
							Else
								*
								Text To lcSQL NoShow TextMerge
									Update
										<<lcTabela>>	
									Set
										Is_EF				= <<ln_Is_EF>>,
										Id_Solicitare		= '<<lc_Id_Solicitare>>',
										Recipisa			= '<<lc_Recipisa>>',
										efact_Detalii		= '<<lc_efact_Detalii>>',
										efact_Stare			= '<<lc_efact_Stare>>'
									Where
											<<lcFieldID>>				= <<lo_EFA_From_ZIP.IdDoc>>
										And Coalesce(Is_EF, 0)			= 1
										And Coalesce(Id_Solicitare, '')	= ''
										And Coalesce(Recipisa, '')		= ''
								EndText
								*, efact_DataIncarcare	= '<<Date2ISO(ld_Data_R)>>'
								*StrToFile(lcSQL, 'lcSQL.txt') 
								*Modify file lcSQL
								mySQLExec(lcSQL)
								__Consola("Actualizez datele pe server cu cele din RO-EFactura care au fost transmise cu alte aplicatii...")
								__Consola("mySQLExec( Update Is_EF, Id_Solicitare, Recipisa...Where IdDoc=?lo_EFA_From_ZIP.IdDoc And IsNull(Is_EF, 0) = 1) And IsNull(Id_Solicitare, '') = '' And IsNull(Recipisa, '')		= ''")
								__Consola("aCountInfo(2): ( "			+ Transform(aCountInfo(2)) + [ )] )
								*
							EndIf
							*	
							llDescOK = .T.
							llDescErr = .F.
							*
						Else	If Not IsNullOrEmpty(lcNumarDoc) And Not IsNullOrEmpty(ldDataDoc) And Not IsNullOrEmpty(lcCodFiscalFactura)
							*	'ERORI FACTURA'
							*
							If tcAlias = 'C_EFACTURI_TRIMISE'
								Replace; 
									Continut	With lcDescRaspuns,;
									Cale		With lcErrZIP;
								In C_EFACTURI_TRIMISE
							EndIf
							*
							*=====================================================================================
							lc_Err_From_ZIP=ReadErrorsFromZip(lc_ID_Solicit, tcIndex, '', {}, 0, lcDescRaspuns, '')
							*=====================================================================================
							*
							If tcAlias = 'C_EFACTURI_TRIMISE'
								Replace Detalii	With lc_Err_From_ZIP In C_EFACTURI_TRIMISE							
							EndIf
							*
							_Screen.ActiveForm.Name.Refresh()			&& sa afiseze Detalii in c_EFacturi_TRIMISE
							
							MessageBox(lc_Err_From_ZIP, 16, "Eroare")
							*
						EndIf	If Not IsNullOrEmpty(lcNumarDoc) And Not IsNullOrEmpty(ldDataDoc) And Not IsNullOrEmpty(lcCodFiscalFactura)
						*
					EndIf		If llSEEK
					*	
					&&Vicos12.02.2024
				Else			If ll_Continue
					lcDescRaspuns = "OK"
					llDescOK = .T.
				ENDIF			If ll_Continue 
				*
			EndIf				If lc_Mesaj_SPV = "ERORI FACTURA"
			*
		EndIf
		* 
	EndFor
	* 
	*REPLACE DescRaspuns WITH lcDescRaspuns, DescOK WITH llDescOK, DescErr WITH llDescErr IN EFA_Descarcare_Note
	EFA_Consola("anaf - descarcare - " + tcIndex + " - " , lcDescRaspuns)
	__Consola( "anaf - descarcare - " + tcIndex + " - " , lcDescRaspuns )
	__Consola( [llDescErr: ( ] + Transform(llDescErr) + [ )] )
	*
	IF llDescErr
		toResponse.WriteFile(lcErrZIP)
		lcXMLString = FileToStr(lcErrZIP)
		*__Consola( [lcXMLString = FileToStr(lcErrZIP): ( ] + Transform(lcXMLString) + [ )] )
		__Consola( [lcXMLString = FileToStr(lcErrZIP): ( ] )
		*=================================================
		lcXMLFile = ExtractZIP(lcErrZIP,  1, lc_Id_Solicit, lc_Recipisa)
		*=================================================		
	ELSE 	
		toResponse.WriteFile(lcZip)
		lcXMLString = FileToStr(lcZip)
		*__Consola( [lcXMLString = FileToStr(lcZip): ( ] + Transform(lcXMLString) + [ )] )
		__Consola( [lcXMLString = FileToStr(lcZip): ( ] )
		*=================================================
		lcXMLFile = ExtractZIP(lcZip,  1, lc_Id_Solicit, lc_Recipisa)
		*=================================================		
	ENDIF 
	*	
	__Consola( [lcXMLFile: ( ] + Transform(lcXMLFile) + [ )] )	
	loZip.CloseZip()
	__Consola( [loZip.CloseZip()] )		
	*
	If tlShowFolder
		*
		If  File(lcZip)
			ShellExecuteExC(ShortPath(lcZip), 'open')
			MessageBox('Fisierul '+FullPath(lcZip) + ' a fost descarcat.', 64, Program(), 3000)
		Else
			MessageBox('Nu a reusit descarcarea facturii '+Chr(13)+lcZip, 16, "Eroare", 3000)
			*Set Step On
		EndIf
		*
	EndIf
	*
	*****Return lcZip
	*
	Local lo_EFA_CLIENT_ZIP As Object
	lo_EFA_CLIENT_ZIP = CreateObject('SmallClass')
	__Consola( [lo_EFA_CLIENT_ZIP=CreateObject('SmallClass'): ] + Transform(lo_EFA_CLIENT_ZIP) + [ )] )
	*
	lcXMLFromMemory=lcDescRaspuns
	*__Consola( [lcXMLFromMemory=lcDescRaspuns: ( ] + Transform(lcDescRaspuns) + [ )] )
	__Consola( [lcXMLFromMemory=lcDescRaspuns: ( ] )
	*
	lcAlias_Tabela = ICase(;
		tcAlias='Sel_eFactura', Sel_eFactura.Ecran,;
		tcAlias='c_EFacturi_Trimise', c_EFacturi_Trimise.Ecran,;
		'???')
	*
	With lo_EFA_CLIENT_ZIP
		.AddProperty('Id_Solicit',		lc_Id_Solicit)
		.AddProperty('Recipisa',		lc_Recipisa)
		.AddProperty('cZipFileName',	lcZip)
		.AddProperty('cXmlString',		lcXMLFromMemory)
		.AddProperty('cNumarDoc',		lcNumarDoc)
		.AddProperty('dDataDoc',		ldDataDoc )
		.AddProperty('Ecran',			lcAlias_Tabela )
		__Consola("lo_EFA_CLIENT_ZIP.Id_Solicit:	( "	+ Transform(lo_EFA_CLIENT_ZIP.Id_Solicit)	+ [ )] )		
		__Consola("lo_EFA_CLIENT_ZIP.Recipisa:		( "	+ Transform(lo_EFA_CLIENT_ZIP.Recipisa)		+ [ )] )		
		__Consola("lo_EFA_CLIENT_ZIP.cZipFileName:	( "	+ Transform(lo_EFA_CLIENT_ZIP.cZipFileName)	+ [ )] )		
		*__Consola("lo_EFA_CLIENT_ZIP.cXmlString:	( "	+ Transform(lo_EFA_CLIENT_ZIP.cXmlString)	+ [ )] )		
		__Consola("lo_EFA_CLIENT_ZIP.cNumarDoc:		( "	+ Transform(lo_EFA_CLIENT_ZIP.cNumarDoc)		+ [ )] )
		__Consola("lo_EFA_CLIENT_ZIP.dDataDoc:		( "	+ Transform(lo_EFA_CLIENT_ZIP.dDataDoc)		+ [ )] )		
	EndWith
	*
	Return lo_EFA_CLIENT_ZIP
	*
EndFunc
* __________________________________________________________________________________________________________
Function Descarca_eFactura_Furnizor(tcRecipisa, tcAlias, tlSkip_Insert);
HelpString "Daca reuseste intoarce un obiect EFA_Furnizor (:Id_Solicit,Recipisa,cZipFileName,cXmlString,cNumarDoc,dDataDoc ), altfel sirul de eroare"
	*
	If Empty(tcAlias)
		lcAlias = 'c_Get_Mesaje_SPV'
	Else
		lcAlias = tcAlias
	EndIf	
	*
	lcCale_LOG = Get_LOG_EFA()
	Local oSetAlternate As Object, oSetConsole As Object, oSetSafety As Object
	oSetConsole=CreateObject("SetConsole", 'Off')
	*
	lcFisierLog = lcCale_Log+Program()+"_"+AllTrim(tcRecipisa)+".log"
	__Consola( [lcFisierLog: ( ] + Transform(lcFisierLog) + [ )] )
	oSetAlternate=CreateObject("SetAlternate", "On", lcFisierLog)
	*
	oSetSafety=CreateObject("SetSafety", "Off")
	*
	If PCount()<2
		tnReturnType = 1
	EndIf
	*
	lcID_Solicitare	= AllTrim( Get_ID_Solicit(tcRecipisa, lcAlias) )
	*
	If Empty(lcID_Solicitare)
		lcID_Solicitare='LIPSA_ID_Solicitare_la_Recipisa_'+AllTrim(tcRecipisa)
		Set Step On
	EndIf	
	*
	lcRecipisa		= AllTrim(tcRecipisa)
	*
	If Used('Documente')
		*
		If Seek((tcRecipisa), "Documente", "Recipisa")
			*
			__Consola( [Recipisa deja exista in tabela "Documente": ( ] + Transform(tcRecipisa) + [ )] )
			ldDataDoc		= Documente.DataDoc
			lcNumarDoc		= Documente.NumarDoc
			lcXMLFromMemory = Documente.Continut
			lcZip			= Documente.Cale
			*
			Local o_EFA_Furnizor As Object
			o_EFA_Furnizor=CreateObject('SmallClass')
			__Consola( [o_EFA_Furnizor=CreateObject('SmallClass'): ] + Transform(o_EFA_Furnizor) + [ )] )
					
			With o_EFA_Furnizor
				.AddProperty( 'Id_Solicit',		lcID_Solicitare	)
				.AddProperty( 'Recipisa',		lcRecipisa		)
				.AddProperty( 'cZipFileName',	lcZip			)
				.AddProperty( 'cXmlString',		lcXMLFromMemory	)
				.AddProperty( 'cNumarDoc',		lcNumarDoc		)
				.AddProperty( 'dDataDoc',		ldDataDoc		)
				__Consola("o_EFA_Furnizor.Id_Solicit:	( " + Transform(o_EFA_Furnizor.Id_Solicit)		+ [ )] )		
				__Consola("o_EFA_Furnizor.Recipisa:		( " + Transform(o_EFA_Furnizor.Recipisa)		+ [ )] )		
				__Consola("o_EFA_Furnizor.cZipFileName:	( " + Transform(o_EFA_Furnizor.cZipFileName)	+ [ )] )		
				*__Consola("o_EFA_Furnizor.cXmlString:	( " + Transform(o_EFA_Furnizor.cXmlString)		+ [ )] )		
				__Consola("o_EFA_Furnizor.cNumarDoc:	( " + Transform(o_EFA_Furnizor.cNumarDoc)		+ [ )] )
				__Consola("o_EFA_Furnizor.dDataDoc:		( " + Transform(o_EFA_Furnizor.dDataDoc)		+ [ )] )		
			EndWith
			*
			Return o_EFA_Furnizor
			*
		Else
			__Consola( [Recipisa nu exista in tabela "Documente": ( ] + Transform(tcRecipisa) + [ )] )	
		EndIf
		*
	Else
		__Consola( [Tabela "Documente" nu este creata ] )
	EndIf
	*
	
	LOCAL lcCUI, lcToken, llProductie	&& , lcIndex
	llProductie = ICAS.oSettings.eFactura_Prod
	lcCUI   	= ICAS.oSoc.CodFiscal
	lcToken 	= ICAS.oSettings.eFactura_TokenAcces
	lcIndex 	= tcRecipisa
	__Consola( [tcRecipisa: ( ]			+ tcRecipisa		+ [ )] )
	__Consola( [lcID_Solicitare: ( ]	+ lcID_Solicitare	+ [ )] )
	*
	*-- Verific daca deja este descarcat fisierul zip
	*
	lcZipFileName = AlreadyDownloadedZip(tcRecipisa, 2)
	*
	If File( lcZipFileName )
		__Consola( [lcZipFileName = AlreadyDownloadedZip(tcRecipisa, 2): ( ] + Transform(lcZipFileName) + [ )] )
		
		*=================================================
		loResponse = CreateObject('Chilkat_9_5_0.BinData')
		loResponse.LoadFile(lcZipFileName)
		*=================================================
		__Consola( "loResponse = " + "CreateObject('Chilkat_9_5_0.BinData')" + Transform(loResponse) )
		
		llSkipWriteZipFile = .T.
		Return Create_EFA_Furnizor ( lcZipFileName, lcID_Solicitare, tlSkip_Insert, llSkipWriteZipFile)
		
		*RETURN lcZipFileName
		*** AICI tb sa citesc din zipul local
		*		
	EndIf
	*
	LOCAL lnSuccess, loResponse	&&,loRest
	__Consola( "ICAS.oRest_ANAF: ( " + Transform(ICAS.oRest_ANAF) + [ )] )
	*
	*=================================================
	loResponse = CreateObject('Chilkat_9_5_0.BinData')
	*=================================================
	__Consola( "loResponse = " + "CreateObject('Chilkat_9_5_0.BinData')" + Transform(loResponse) )
	*
	IF llProductie
		lcURL_descarcare = 	'/prod/FCTEL/rest/descarcare?id='
	Else
		lcURL_descarcare = 	'/test/FCTEL/rest/descarcare?id='
	ENDIF 
	*
	__Consola([llProductie: ( ] + Transform(llProductie) + [ )] )
	__Consola( [lcURL_descarcare: ( ]+Transform(lcURL_descarcare) + [ )] )
	*=========================================================================================
	lnSuccess = ICAS.oRest_ANAF.FullRequestNoBodyBd("GET",lcURL_descarcare+lcIndex,loResponse)
	*=========================================================================================
	__Consola( [ICAS.oRest_ANAF.FullRequestNoBodyBd("GET",]+lcURL_descarcare+lcIndex+[,loResponse): ( ]+Transform(lnSuccess) + [ )] )
	*
	IF (lnSuccess <> 1) THEN
		*
		lcEroare_ICAS_oRest_ANAF	= ICAS.oRest_ANAF.LastErrorText
		lnConnectFailReason			= ICAS.oRest_ANAF.ConnectFailReason
		__Consola( [lnConnectFailReason: ( ]+Transform(lnConnectFailReason) + [ )] )
		*
		If 'The connection already exists, as far as we know..'$lcEroare_ICAS_oRest_ANAF
			*	
			Wait Window TimeOut 0.1 " SpikeArrest, asteptam 1 secunda..."
			lnSuccess = ICAS.oRest_ANAF.FullRequestNoBodyBd("GET", lcURL_descarcare+lcIndex,loResponse)
			*
			IF (lnSuccess <> 1) THEN
				*
				lcEroare_ICAS_oRest_ANAF	= ICAS.oRest_ANAF.LastErrorText
				lnConnectFailReason			= ICAS.oRest_ANAF.ConnectFailReason
			    __Consola("EFA_Descarcare: Nu se poate efectua GET/descarcare > api.anaf.ro: ( " + GetErr_Chilkat_Rest(lnConnectFailReason) +[; ]+lcEroare_ICAS_oRest_ANAF+ [ )] ) 
				RELEASE loResponse
				RETURN "EFA_Descarcare: Nu se poate efectua GET/descarcare > api.anaf.ro" + GetErr_Chilkat_Rest(lnConnectFailReason)+[; ]+lcEroare_ICAS_oRest_ANAF
				*
			EndIf
			*			
		ELSE
			*
		    __Consola("EFA_Descarcare: Nu se poate efectua GET/descarcare > api.anaf.ro: ( " + GetErr_Chilkat_Rest(lnConnectFailReason)+[; ]+lcEroare_ICAS_oRest_ANAF + [ )] ) 
			RELEASE loResponse
			RETURN "EFA_Descarcare: Nu se poate efectua GET/descarcare > api.anaf.ro" + GetErr_Chilkat_Rest(lnConnectFailReason)+[; ]+lcEroare_ICAS_oRest_ANAF
			*
		EndIf
		*	
	ENDIF
	*
	Local lcZip As String, lcXMLFromMemory As String
	Store '' To lcZip, lcXMLFromMemory
	*
	IF ICAS.oRest_ANAF.ResponseStatusCode = 200
		*
		__Consola( [ICAS.oRest_ANAF.ResponseStatusCode = 200: ]+Transform(ICAS.oRest_ANAF.ResponseStatusCode = 200) + [ )] )
		*
		
		*=================================================
		*=================================================
		*=================================================
		*=================================================
		*=================================================
		*-- de verificat:
		*
		*	llSkipWriteZipFile = .F.
		*	Return Create_EFA_Furnizor ( lcZipFileName, lcID_Solicitare, tlSkip_Insert, llSkipWriteZipFile )
		*=================================================
		*=================================================
		*=================================================
		*=================================================
		

		lcXML = lcID_Solicitare+".xml"
		__Consola( [lcXML: ]+Transform(lcXML) + [ )] )
		*=================================================
		loZip = CreateObject('Chilkat_9_5_0.Zip')
		*=================================================
		__Consola( [loZip = CreateObject('Chilkat_9_5_0.Zip'): ]+Transform(loZip) + [ )] )
		*		
		lnSuccess = loZip.OpenBd(loResponse)
		__Consola( [loZip.OpenBd(loResponse): ]+Transform(lnSuccess) + [ )] )
		*
		If (lnSuccess = 0) THEN
			lcDescRaspuns = "ZIP incorect"
			__Consola( [lcDescRaspuns: ]+Transform(lcDescRaspuns) + [ )] )
			*REPLACE DescRaspuns WITH lcDescRaspuns, DescOK WITH .F. IN EFA_Descarcare_Note
			loResponse.WriteFile(lcID_Solicitare + '_EROARE_ZIP incorect.txt')
			__Consola( [loResponse.WriteFile(lcID_Solicitare + '_EROARE_ZIP incorect.txt')] )
			lcEroare_loResponse = FileToStr(lcID_Solicitare + '_EROARE_ZIP incorect.txt')
			lcEroare_loRest = ICAS.oRest_ANAF.LastErrorText
			lcEroare_loZip = loZip.LastErrorText
		    __Consola("api.anaf.ro: zip incorect: "+ lcEroare_loResponse+Chr(13)+lcEroare_loRest+Chr(13)+lcEroare_loZip)
		    *Set Step ON
			RELEASE loResponse, loZip 
			RETURN "api.anaf.ro: zip incorect "+lcEroare_loResponse+Chr(13)+lcEroare_loRest+Chr(13)+lcEroare_loZip
		EndIf
		*
		Local lcNumarDoc As String, ldDataDoc As Date
		Store '' To lcNumarDoc
		Store {} To ldDataDoc
		*
		*=================================================
		loXml = CreateObject('Chilkat_9_5_0.Xml')
		*=================================================
		__Consola( [loXml = CreateObject('Chilkat_9_5_0.Xml'): ]+Transform(loXML) + [ )] )			
		lnNumEntries = loZip.NumEntries
		__Consola( [loZip.NumEntries: ]+Transform(lnNumEntries) + [ )] )
		*
		For i = 0 TO lnNumEntries-1
			*
		    loEntry = loZip.GetEntryByIndex(i)
		    __Consola( [i: ]+Transform(i) + [ )] )
		    __Consola( [loEntry = loZip.GetEntryByIndex(i): ]+Transform(loEntry) + [ )] )
		    *
		    ll_Found_lcXML = loEntry.FileName = lcXML
		    *
			IF ll_Found_lcXML
				__Consola( [loEntry.FileName = lcXML: ]+Transform(ll_Found_lcXML) + [ )] )
				lcXMLFromMemory = CleanXMLPrefix( loEntry.UnzipToString(0,"utf-8"))	&& OpenFromMemory
				*
				 *__Consola("lcXMLFromMemory: ( " + lcXMLFromMemory)
				loXml.LoadXml(lcXMLFromMemory)
				__Consola( [loXml.LoadXml(lcXMLFromMemory)] )
				*lcNumarDoc	= Transform( loXml.GetChildIntValue("ID") )
				*lcNumarDoc	= loXml.GetChildContent("*:ID")
				lcNumarDoc	= GetNumeFisierSafe( Transform( loXml.GetChildContent("*:ID") ) )	&&-- 05.11.2024
				
				ldDataDoc_ReadFromXML = loXml.GetChildContent("*:IssueDate")
				__Consola("ldDataDoc_ReadFromXML: ( "	+ Transform(ldDataDoc_ReadFromXML) + [ )] )
				ldDataDoc = CToD( ANSI2MDY( loXml.GetChildContent("*:IssueDate") ) )
				__Consola("lcNumarDoc: ( "+ lcNumarDoc)
				__Consola("ldDataDoc: ( "	+ Transform(ldDataDoc ) + [ )] )
				*
				If Empty(ldDataDoc)
					*
					lcMesaj			= loXml.GetAttrValue("message")
					*
					If IsNullOrEmpty(lcMesaj)
						MessageBox(Program() + Chr(13) + 'Nu a reusit extragerea elementului [Data factura] din fisierul XML.', 16, "Eroare", 1500)
						Set Step On
					EndIf
					*
				EndIf
				*
				lcZip = GetFolder_EFactura(ldDataDoc, 2) + lcNumarDoc + '_'+lcRecipisa+'_'+Transform(DToS(ldDataDoc), '@R ####-##-##')+".zip"
				__Consola("lcZip: ( "	+ Transform(lcZip) + [ )] )
				*
				lcCodFiscalFactura= loXml.GetChildContent("*:AccountingSupplierParty|*:Party|*:PartyTaxScheme|*:CompanyID")
				__Consola("lcCodFiscalFactura: ( "	+ Transform(lcCodFiscalFactura) + [ )] )
				*
				ll_IsNullOrEmpty_lcCodFiscalFactura = IsNullOrEmpty(lcCodFiscalFactura)
				*
				If ll_IsNullOrEmpty_lcCodFiscalFactura 
					__Consola("lcCodFiscalFactura: ( "	+ Transform(ll_IsNullOrEmpty_lcCodFiscalFactura ) + [ )] )
					lcCodFiscalFactura	= loXml.GetChildContent("*:AccountingSupplierParty|*:Party|*:PartyLegalEntity|*:CompanyID")
					__Consola("lcCodFiscalFactura: ( "	+ Transform(lcCodFiscalFactura) + [ )] )
				EndIf
				*
				lcCodFiscalFactura = OnlyNumber(lcCodFiscalFactura)
				lcDenumireFurnizor = loXml.GetChildContent("*:AccountingSupplierParty|*:Party|*:PartyLegalEntity|*:RegistrationName")
				__Consola("lcDenumireFurnizor: ( "	+ Transform(lcDenumireFurnizor) + [ )] )
				*
				If Not tlSkip_Insert
					*
					ll_SEEK = Seek(lcINDEX, 'Documente', 'Recipisa')
					*Inserez in FORM
					*				
					If ll_SEEK
						__Consola("Seek(lcINDEX, 'Documente', 'Recipisa'): ( " + Transform(ll_SEEK) + [ )] )
						*
						Update;
							Documente;
						Set;
							Continut	= lcXMLFromMemory,;
							Cale		= lcZip,;
							DataDoc		= ldDataDoc,;
							NumarDoc	= lcNumarDoc;
						Where;
							Recipisa=lcINDEX
						*
						__Consola("Update Documente Set Continut..., Cale... Where Recipisa=lcINDEX")
					Else		If ll_SEEK
						*
						__Consola("ll_SEEK: ( " + Transform(ll_SEEK) + [ )] )
						Store 0 To lnImportat, lnIdDoc
						*
						If Used('EFA_INTRARI')
							*
							*If EFA_INTRARI.Tip='MESAJ CUMPARATOR PRIMIT'
							*	Set Step On
							*EndIf	
							*
							Insert Into Documente ;
							(Data_R, Tip_ANAF, Id_Solicit, Recipisa,;
							 DataDoc, NumarDoc, Continut, Cod_Fiscal, Partener, Cale, Preluat, Importat, IdDoc, _PROGRAM);
							Values;
							(;
							EFA_INTRARI.Data_R,;
							EFA_INTRARI.Tip, EFA_INTRARI.Id_Solicitare, EFA_INTRARI.Recipisa,;
							ldDataDoc, lcNumarDoc,  lcXMLFromMemory, lcCodFiscalFactura, lcDenumireFurnizor, lcZip, 0, lnImportat, lnIdDoc, Program())
							*
						Else
							*
							*If c_Get_Mesaje_SPV.Tip='MESAJ CUMPARATOR PRIMIT'
							*	Set Step On
							*EndIf
							*					
							Insert Into Documente ;
							(Data_R, Tip_ANAF, Id_Solicit, Recipisa,;
							 DataDoc, NumarDoc, Continut, Cod_Fiscal, Partener, Cale, Preluat, Importat, IdDoc, _PROGRAM);
							Values;
							(c_Get_Mesaje_SPV.Data_R, c_Get_Mesaje_SPV.Tip, c_Get_Mesaje_SPV.Id_Solicit, c_Get_Mesaje_SPV.Recipisa,;
							 ldDataDoc, lcNumarDoc,  lcXMLFromMemory, lcCodFiscalFactura, lcDenumireFurnizor, lcZip, 0, lnImportat, lnIdDoc, Program())
						EndIf	 
						*
						__Consola("Insert Into Documente (DataDoc,NumarDoc,Continut,Cale ...")
						*
					EndIf	If ll_SEEK
					*
				EndIf		If Not tlSkip_Insert
				*	
			EndIf
			*
		EndFor
		*
	Else	IF ICAS.oRest_ANAF.ResponseStatusCode = 200
		*
		__Consola("Else	IF ICAS.oRest_ANAF.ResponseStatusCode = 200: ( " + Transform(ICAS.oRest_ANAF.ResponseStatusCode) + [ )] )
		*
*!*			If (ICAS.oRest_ANAF.ResponseStatusCode >= 400) 
*!*			    __Consola("EFA_Descarcare: Nu se poate efectua Stare > api.anaf.ro" + STR(ICAS.oRest_ANAF.ConnectFailReason) + [ )] )
*!*				RELEASE loResponse, loZip 		    
*!*				RETURN "EFA_Descarcare: Nu se poate efectua Stare > api.anaf.ro" + STR(ICAS.oRest_ANAF.ConnectFailReason)
*!*			EndIf
		*
		If (ICAS.oRest_ANAF.ResponseStatusCode > 200) 
		    __Consola("EFA_IN_Mesaje: Nu se poate efectua Stare > api.anaf.ro: " )
		    __Consola(" ICAS.oRest_ANAF.ConnectFailReason: "	+ Transform(ICAS.oRest_ANAF.ConnectFailReason) )
		    __Consola(" ICAS.oRest_ANAF.responseheader: "		+ Transform(ICAS.oRest_ANAF.responseheader) )
		    __Consola(" ICAS.oRest_ANAF.responsestatuscode: "	+ Transform(ICAS.oRest_ANAF.responsestatuscode) )
		    __Consola(" ICAS.oRest_ANAF.responsestatustext: "	+ Transform(ICAS.oRest_ANAF.responsestatustext) )
		    *__Consola(" ICAS.oRest_ANAF.lasterrortext: "		+ Transform(ICAS.oRest_ANAF.lasterrortext) )
		    Set Step On
			***RETURN .F.
			RETURN "EFA_Descarcare: Nu se poate efectua Stare > api.anaf.ro" + STR(ICAS.oRest_ANAF.ConnectFailReason)
		EndIf
		
	EndIf 
	*
	If Not Empty(lcZip)
		loResponse.WriteFile(lcZip)
		__Consola( [loResponse.WriteFile(lcZip): ] + Transform(lcZip) + [ )] )
	EndIf	
	*
	loZip.CloseZip()
	__Consola( [loZip.CloseZip()] )
	*
	RELEASE loResponse, loZip
	*
	Local o_EFA_Furnizor As Object
	o_EFA_Furnizor=CreateObject('SmallClass')
	__Consola( [o_EFA_Furnizor=CreateObject('SmallClass'): ] + Transform(o_EFA_Furnizor) + [ )] )
	*		
	With o_EFA_Furnizor
		.AddProperty('Id_Solicit',		lcID_Solicitare)
		.AddProperty('Recipisa',		lcRecipisa)
		.AddProperty('cZipFileName',	lcZip)
		.AddProperty('cXmlString',		lcXMLFromMemory)
		.AddProperty('cNumarDoc',		lcNumarDoc)
		.AddProperty('dDataDoc',		ldDataDoc )
		__Consola("o_EFA_Furnizor.Id_Solicit:	( "	+ Transform(o_EFA_Furnizor.Id_Solicit)		+ [ )] )		
		__Consola("o_EFA_Furnizor.Recipisa:		( "	+ Transform(o_EFA_Furnizor.Recipisa)		+ [ )] )		
		__Consola("o_EFA_Furnizor.cZipFileName:	( "	+ Transform(o_EFA_Furnizor.cZipFileName)	+ [ )] )		
		*__Consola("o_EFA_Furnizor.cXmlString:	( "	+ Transform(o_EFA_Furnizor.cXmlString)		+ [ )] )		
		__Consola("o_EFA_Furnizor.cNumarDoc:	( "	+ Transform(o_EFA_Furnizor.cNumarDoc)		+ [ )] )
		__Consola("o_EFA_Furnizor.dDataDoc:		( "	+ Transform(o_EFA_Furnizor.dDataDoc)		+ [ )] )		
	EndWith
	*
	Return o_EFA_Furnizor
	*
EndFunc
* __________________________________________________________________________________________________________
Function ANSI2MDY (tcAnsiDate)
	lcYear	= GetWordNum(tcAnsiDate, 1, '-')
	lcMonth	= GetWordNum(tcAnsiDate, 2, '-')
	lcDay	= GetWordNum(tcAnsiDate, 3, '-')
	Return lcDay + '-'+lcMonth+'-'+lcYear
EndFunc
* __________________________________________________________________________________________________________
*!*	Function Send_Mesaj_EFactura(tcToken, tcCodFiscal, tlProd, tcFisier)
*!*		mUrl=IIf(tlProd=1,"https://api.anaf.ro/test/FCTEL/rest/upload?standard=UBL&cif=","https://api.anaf.ro/prod/FCTEL/rest/upload?standard=UBL&cif=")+AllTrim(pcodfiscal)
*!*		lcData = ""
*!*		oHttp = _GetObject('http')		&& GetXmlHttp()
*!*		oHttp.Open("POST", mUrl, .F.)
*!*		oHttp.SetRequestHeader('Content-Type', 'text/xml')
*!*		oHttp.SetRequestHeader('Authorization', "Bearer "+tcToken)
*!*		lcData = FileToStr(tcFisier)
*!*		oHttp.Send((lcData))
*!*		lcRaspuns = ""
*!*		If oHttp.Status=200 .Or. oHttp.Status=201
*!*			lcRaspunsBrut = oHttp.ResponseText
*!*			If 'index_incarcare='$lcRaspunsBrut
*!*				lcRaspuns = "_index: "+StrExtract(lcRaspunsBrut, 'index_incarcare="', '"')
*!*			Else
*!*				If 'errorMessage='$lcRaspunsBrut
*!*					lcRaspuns = "_error: "+StrExtract(lcRaspunsBrut, 'errorMessage="', '"')
*!*				Else
*!*					lcRaspuns = lcRaspunsBrut
*!*				EndIf
*!*			EndIf
*!*		Else
*!*			lcMesajRaspuns	= oHttp.ResponseText
*!*			lcStatusText	= AllTrim(oHttp.StatusText)
*!*			*
*!*	        Do Case
*!*	        	*
*!*	        	Case "failed to respond"$lcMesajRaspuns.OR. ("operation "$lcMesajRaspuns.AND. ("timeout"$lcMesajRaspuns.OR. ("timed out"$lcMesajRaspuns)))
*!*	            	lcMesajRaspuns = "Serverele ANAF nu raspund."+CHR(13)+"Incercati mai tarziu."+CHR(13)+lcMesajRaspuns
*!*		        *
*!*		        Case "Forbidden"$lcMesajRaspuns .OR. "403"$lcMesajRaspuns
*!*	    	        lcMesajRaspuns = "Nu aveti drepturi de �ncarcare pe acest cod fiscal sau tokenul SPV a expirat. Generati alt token."+CHR(13)+lcMesajRaspuns
*!*				*
*!*				Case lcMesajRaspuns<>"Operatia a fost anulata." .AND. lcMesajRaspuns<>"Nu exista mesaje"
*!*	            	MessageBox(lcMesajRaspuns, 48, "Atentie...", 3000)
*!*	        EndCase
*!*	        *      
*!*			lcRaspuns = lcMesajRaspuns
*!*		EndIf
*!*		*
*!*		Return lcRaspuns
*!*	EndFunc
*!*	* __________________________________________________________________________________________________________
Function GetTaskResultStareMesajFromZip(tcRecipisa, tcZipFile, tnInvoiceType)
	*
	lcCale_LOG = Get_LOG_EFA()
	Local oSetAlternate As Object, oSetConsole As Object, oSetSafety As Object
	oSetConsole=CreateObject("SetConsole", 'Off')
	oSetAlternate=CreateObject("SetAlternate", "On", lcCale_Log+Program()+".log")
	oSetSafety=CreateObject("SetSafety", "Off")
	*
	If Empty(tnInvoiceType)
		tnInvoiceType = 1
	EndIf
	*
	lcAliasFacturi	= Iif(tnInvoiceType=1, 'c_eFacturi_Trimise', 'Documente')
	lcINDEX			= tcRecipisa
	lcRecipisa		= lcINDEX
	lcID_Solicitare	= ""
	__Consola( [tcRecipisa: ( ]		+ Transform(tcRecipisa) + [ )] )
	__Consola( [tcZipFile: ( ]		+ Transform(tcZipFile) + [ )] )
	__Consola( [tnInvoiceType: ( ]	+ Transform(tnInvoiceType) + [ )] )
	__Consola( [lcAliasFacturi: ( ]	+ Transform(lcAliasFacturi) + [ )] )
	__Consola( [lcINDEX: ( ]		+ Transform(lcINDEX) + [ )] )
	__Consola( [lcRecipisa: ( ]		+ Transform(lcRecipisa) + [ )] )
	*	
	Local lcZip As String, lcXMLFromMemory As String
	Store '' To lcZip, lcXMLFromMemory
	*
	*=================================================
	lcID_Solicitare =  Get_ID_Solicit(tcRecipisa, IIF(tnInvoiceType = 1, 'c_Get_Mesaje_SPV', 'EFA_INTRARI') )
	*=================================================
	__Consola( [lcID_Solicitare: ( ] + Transform(lcID_Solicitare) + [ )] )
	*
	If Empty(lcID_Solicitare)
	    __Consola("Variabila lcID_Solicitare este EMPTY")
		RETURN ''	
	EndIf
	*
	lcXML = lcID_Solicitare +".xml"
	__Consola( [lcXML: ( ] + Transform(lcXML) + [ )] )
	*=================================================
	loZip = CreateObject('Chilkat_9_5_0.Zip')
	*=================================================
	__Consola( [loZip: ( ] + Transform(loZip) + [ )] )
	*
	*=================================================
	loResponse = CreateObject('Chilkat_9_5_0.BinData')
	*=================================================
	__Consola( [loResponse: ( ] + Transform(loResponse) + [ )] )
	loResponse.LoadFile(tcZipFile)
	__Consola( [loResponse.LoadFile(tcZipFile)] )
	*		
	lnSuccess = loZip.OpenBd(loResponse)
	__Consola( [lnSuccess = loZip.OpenBd(loResponse): ( ] + Transform(lnSuccess) + [ )] )
	*
	If (lnSuccess = 0) THEN
		lcDescRaspuns = "ZIP incorect"
		__Consola( [lcDescRaspuns: ]+Transform(lcDescRaspuns) + [ )] )
		*REPLACE DescRaspuns WITH lcDescRaspuns, DescOK WITH .F. IN EFA_Descarcare_Note
		loResponse.WriteFile(lcID_Solicitare + '_EROARE.txt')
		__Consola( [loResponse.WriteFile(lcID_Solicitare + '_EROARE.txt')] )
		lcEroare_loResponse = FileToStr(lcID_Solicitare + '_EROARE.txt')
		lcEroare_loRest = ICAS.oRest_ANAF.LastErrorText
		lcEroare_loZip = loZip.LastErrorText
	    __Consola("api.anaf.ro: zip incorect: "+ lcEroare_loResponse+Chr(13)+lcEroare_loRest+Chr(13)+lcEroare_loZip)
		RELEASE loResponse, loZip 
		RETURN "api.anaf.ro: zip incorect "+lcEroare_loResponse+Chr(13)+lcEroare_loRest+Chr(13)+lcEroare_loZip
	EndIf
	*
	Local lcNumarDoc As String, ldDataDoc As Date
	Store '' To lcNumarDoc
	Store {} To ldDataDoc
	*
	*=================================================
	loXml = CreateObject('Chilkat_9_5_0.Xml')	
	*=================================================
	__Consola( [loXml: ( ] + Transform(loXml) + [ )] )	
	*
	lnNumEntries = loZip.NumEntries
	__Consola( [lnNumEntries: ( ] + Transform(lnNumEntries) + [ )] )	
	*
	For i = 0 TO lnNumEntries-1
		__Consola( [i: ( ] + Transform(i) + [ )] )	
		*=================================================
	    loEntry = loZip.GetEntryByIndex(i)
	    *=================================================
	    __Consola( [loEntry: ( ] + Transform(loEntry) + [ )] )
		    *
	    ll_Found_lcXML = loEntry.FileName = lcXML
	    *
		IF ll_Found_lcXML
			__Consola( [loEntry.FileName = lcXML: ]+Transform(ll_Found_lcXML) + [ )] )
			lcXMLFromMemory = CleanXMLPrefix( loEntry.UnzipToString(0,"utf-8") )		&& OpenFromMemory
			*__Consola( [lcXMLFromMemory: ]+Transform(lcXMLFromMemory) + [ )] )
			*=================================================
			loXml.LoadXml(lcXMLFromMemory)
			*=================================================
			lcNumarDoc	= loXml.GetChildContent("*:ID")
			ldDataDoc_ReadFromXML = loXml.GetChildContent("*:IssueDate")
			ldDataDoc = CToD( ANSI2MDY( loXml.GetChildContent("*:IssueDate") ) )
			__Consola("ldDataDoc_ReadFromXML: ( "	+ Transform(ldDataDoc_ReadFromXML) + [ )] )
			__Consola("lcNumarDoc: ( "+ lcNumarDoc)
			__Consola("ldDataDoc: ( "	+ Transform(ldDataDoc ) + [ )] )
			lcXMLFile = GetFolder_EFactura(ldDataDoc, 2) + lcNumarDoc + '_'+lcRecipisa+'_'+Transform(DToS(ldDataDoc), '@R ####-##-##')+".zip"
			*
			If Empty(ldDataDoc)
				*
				lcMesaj			= loXml.GetAttrValue("message")
				*
				If IsNullOrEmpty(lcMesaj)
					MessageBox(Program() + Chr(13) + 'Nu a reusit extragerea elementului [Data factura] din fisierul XML.', 16, "Eroare", 1500)
					Set Step On
				EndIf
				*
			EndIf
			*
			__Consola("lcZip: ( "	+ Transform(lcZip) + [ )] )
			*
			If tnInvoiceType=1		&& c_eFacturi_Trimise
				lcCodFiscalFactura= loXml.GetChildContent("*:AccountingCustomerParty|*:Party|*:PartyTaxScheme|*:CompanyID")
			Else					&& Documente
				lcCodFiscalFactura= loXml.GetChildContent("*:AccountingSupplierParty|*:Party|*:PartyTaxScheme|*:CompanyID")
			EndIf
			*	
			__Consola("lcCodFiscalFactura: ( "	+ Transform(lcCodFiscalFactura) + [ )] )
			*
			ll_IsNullOrEmpty_lcCodFiscalFactura = IsNullOrEmpty(lcCodFiscalFactura)
			*
			If ll_IsNullOrEmpty_lcCodFiscalFactura 
				__Consola("lcCodFiscalFactura: ( "	+ Transform(ll_IsNullOrEmpty_lcCodFiscalFactura ) + [ )] )
				*
				If tnInvoiceType=1		&& c_eFacturi_Trimise
					lcCodFiscalFactura	= loXml.GetChildContent("*:AccountingCustomerParty|*:Party|*:PartyLegalEntity|*:CompanyID")
				Else					&& Documente
					lcCodFiscalFactura	= loXml.GetChildContent("*:AccountingSupplierParty|*:Party|*:PartyLegalEntity|*:CompanyID")
				EndIf
				*
				__Consola("lcCodFiscalFactura: ( "	+ Transform(lcCodFiscalFactura) + [ )] )
			EndIf
			*
			lcCodFiscalFactura = OnlyNumber(lcCodFiscalFactura)
			*
			If tnInvoiceType=1		&& c_eFacturi_Trimise
				lcDenumireFurnizor = loXml.GetChildContent("*:AccountingCustomerParty|*:Party|*:PartyLegalEntity|*:RegistrationName")
			Else					&& Documente
				lcDenumireFurnizor = loXml.GetChildContent("*:AccountingSupplierParty|*:Party|*:PartyLegalEntity|*:RegistrationName")
			EndIf
			*
			__Consola("lcDenumireFurnizor: ( "	+ Transform(lcDenumireFurnizor) + [ )] )			
			*	Inserarea o fac in FORM
			*		???
			If Used(lcAliasFacturi)
				*
				If tnInvoiceType=2
					*
					*=================================================
					&& Documente
					*=================================================
					*
					ll_SEEK = Seek(lcRecipisa, 'Documente', 'Recipisa')
					*				
					If ll_SEEK
						__Consola("Seek(lcRecipisa, 'Documente', 'Recipisa'): ( " + Transform(ll_SEEK) + [ )] )
						*
						Update;
							Documente;
						Set;
							Continut	= lcXMLFromMemory,;
							Cale		= lcZip,;
							DataDoc		= ldDataDoc,;
							NumarDoc	= lcNumarDoc;
						Where;
							Recipisa=lcRecipisa
						*
						__Consola("Update Documente Set Continut..., Cale... Where Recipisa=lcRecipisa")
						*
					Else
						*
						__Consola("ll_SEEK: ( " + Transform(ll_SEEK) + [ )] )
						*
						*If c_Get_Mesaje_SPV.Tip = 'MESAJ CUMPARATOR PRIMIT'
						*	Set Step On
						*EndIf
						*	
						Store 0 To lnImportat, lnIdDoc
						Insert Into Documente ;
							(Data_R, Tip_ANAF, Id_Solicit, Recipisa,;
							 DataDoc, NumarDoc, Continut, Cod_Fiscal, Partener, Cale, Preluat, Importat, IdDoc, _PROGRAM);
						Values;
							(c_Get_Mesaje_SPV.Data_R, c_Get_Mesaje_SPV.Tip, c_Get_Mesaje_SPV.Id_Solicit, c_Get_Mesaje_SPV.Recipisa,;
							 ldDataDoc, lcNumarDoc, lcXMLFromMemory, lcCodFiscalFactura, lcDenumireFurnizor, lcXMLFile, 0, lnImportat, lnIdDoc, Program())
						*
						__Consola("Insert Into Documente (Data_R,Continut,Cale ...")
						*
					EndIf
					*
				Else				If tnInvoiceType=2	
					*
					*=================================================
					&& c_eFacturi_Trimise
					*=================================================
					ll_SEEK = Seek(lcRecipisa, 'c_eFacturi_Trimise', 'Recipisa')
					*
					If ll_SEEK
						__Consola("Seek(lcRecipisa, 'c_eFacturi_Trimise', 'Recipisa'): ( " + Transform(ll_SEEK) + [ )] )
						*
						Update;
							c_eFacturi_Trimise;
						Set;
							Cale =lcZip,;
							Data = ldDataDoc,;
							NumarDoc = lcNumarDoc;
						Where;
							Recipisa=lcRecipisa
						__Consola("Update c_eFacturi_Trimise Set Continut, Cale ... Where Recipisa=lcRecipisa")							
						*
					Else
						*
						Insert Into c_eFacturi_TRIMISE;
							(Data_R, Tip, Id_Solicit, Recipisa,;
							DataDoc, Nr_Iesire, Cod_Fiscal, Partener, Continut, Cale, Preluat, Importat, Id_Iesire);
						Values;
							(c_Get_Mesaje_SPV.Data_R, c_Get_Mesaje_SPV.Tip, c_Get_Mesaje_SPV.Id_Solicit, c_Get_Mesaje_SPV.Recipisa,;
							ldDataDoc, lcNumarDoc,  lcCodFiscalFactura, lcDenumireFurnizor, lcXMLFromMemory, lcXMLFile, 1, lnImportat, lnIdDoc)
						__Consola("Insert Into c_eFacturi_TRIMISE (Data_R,Continut,Cale ...")							
						*
					EndIf
					*		
				EndIf				If tnInvoiceType=2
				*
			EndIf			If Used(lcAliasFacturi)	
			*
		EndIf			IF ll_Found_lcXML
		*
	EndFor		For i = 0 TO lnNumEntries-1
	*
	loZip.CloseZip()
	__Consola( [loZip.CloseZip()] )
	*
	Local o_EFA As Object
	o_EFA=CreateObject('SmallClass')
	__Consola("o_EFA: ( " + Transform(o_EFA) + [ )] )
	*		
	With o_EFA
		.AddProperty('Id_Solicit',		lcID_Solicitare)
		.AddProperty('Recipisa',		lcRecipisa)
		*.AddProperty('cZipFileName',	lcZip)
		.AddProperty('cXMLFile',		lcXMLFile)
		.AddProperty('cXmlString',		lcXMLFromMemory)
		.AddProperty('cNumarDoc',		lcNumarDoc)
		.AddProperty('dDataDoc',		ldDataDoc )
		*
		__Consola("Id_Solicit: ( " + Transform(lcID_Solicitare) + [ )] )
		__Consola("Recipisa: ( " + Transform(lcRecipisa) + [ )] )
		*__Consola("cZipFileName: ( " + Transform(lcZip) + [ )] )
		__Consola("cXMLFile: ( " + Transform(lcXMLFile) + [ )] )
		*__Consola("cXmlString: ( " + Transform(lcXMLFromMemory) + [ )] )
		__Consola("cNumarDoc: ( " + Transform(lcNumarDoc) + [ )] )
		__Consola("dDataDoc: ( " + Transform(ldDataDoc ) + [ )] )
		*
	EndWith
	*
	__Consola( [Return o_EFA] )
	Return o_EFA
	*
EndFunc
* __________________________________________________________________________________________________________	
Function GetEFacturiDeTrimis(tdData)
	ldData=tdData
	*
	If Type('ll_Is_ICAS')='U'
		Public ll_Is_ICAS
		ll_Is_ICAS = ( VarType(ICAS)='O' And Not IsNull(ICAS) ) And PemStatus(ICAS, 'oCfgSALARII', 5)
	EndIf
	*	
	If ll_Is_ICAS
		*
		Text To lcSQL NoShow TextMerge
			Select
				IdDoc
			From Iesiri i
			-- Inner Join (Select * From Conturi Where Left(Cont,3) In('411', '461') And Len(Cont)>3 And IsNull(Sters, 0)=0) c On i.Cont=c.Cont
			Where
				i.Tip Not In ('B','C','A', 'e')
				And i.DataDoc<=?ldData
				-- And IsNull(BFTiparit, 0)<>9
				And IsNull(i.Is_EF, 0)=1
				And IsNull(Id_Solicitare, Space(1))=Space(1)
				And IsNull(Anulat, 0)=0
			Union
			Select
				IdDoc
			From Export e
			-- Inner Join (Select * From Conturi Where Left(Cont,3) In('411', '461') And Len(Cont)>3 And IsNull(Sters, 0)=0) c On e.Cont=c.Cont
			Where
				e.Tip Not In ('B','C','A', 'e', 'W','X','Y')
				And e.DataDoc<=?ldData
				-- And IsNull(BFTiparit, 0)<>9
				And IsNull(e.Is_EF, 0)=1
				And IsNull(Id_Solicitare, Space(1))=Space(1)
				And IsNull(Anulat, 0)=0
		EndText
		*
	Else
		*
		Text To lcSQL NoShow TextMerge
			Select
				ID As IdDoc
			From Docum
			Where
				Is_EF=1
				And Tip_Doc='FcAviz'
				And Tip_Fact In(1, 2, 4, 7)
				And Data_Doc<=?ldData
				-- And Coalesce(BFTiparit, 0)<>9
				And Coalesce(Id_Solicitare, '')=''
		EndText		
		*
	EndIf
	*
	mySQLExec(lcSQL, [NrFacturiNetrimise])
	Return aCountInfo(2)
EndFunc
* __________________________________________________________________________________________________________
Function Get_ID_Solicit(tcRecipisa, tcAlias)
	*
	*	c_eFACTURI_MESAJE Contine Id_Solicitare, Recipisa pentru toate facturile
	*
	Local lc_ID_Solicitare As String
	Store '' To lc_ID_Solicitare
	External ARRAY aGet_Id_Solicit
	Select ID_Solicitare From c_eFACTURI_MESAJE  Where Recipisa = tcRecipisa Into Array aGet_Id_Solicit
	lc_ID_Solicitare = Iif(_Tally>0, AllTrim(aGet_Id_Solicit(1)), '')
	*
	If Not IsNullOrEmpty(lc_ID_Solicitare)
		Return lc_ID_Solicitare
	EndIf	
	*
	***
	*	OBSOLETE
	*	OBSOLETE
	*	OBSOLETE
	***
	*
	If Not Empty(tcAlias)
		lcAlias = tcAlias
	Else
		If Used('EFA_INTRARI')
			lcAlias = 'EFA_INTRARI'
		Else
			lcAlias = 'c_Get_Mesaje_SPV'
		EndIf
	EndIf
	*
	If Not Used(lcAlias)
		__Consola("lcAlias:  " + Transform(lcAlias) )
		Return ''
	EndIf
	*
	lcField_Solicitare = Iif(lcAlias = 'c_Get_Mesaje_SPV', 'ID_Solicit', 'ID_Solicitare')
	External ARRAY aGet_Id_Solicit
	Select AllTrim(&lcField_Solicitare) From (lcAlias) Where Recipisa = tcRecipisa Into Array aGet_Id_Solicit
	*
	lc_ID_Solicitare = Iif(_Tally>0, aGet_Id_Solicit(1), '')
	RETURN lc_ID_Solicitare
EndFunc
* __________________________________________________________________________________________________________
Function Get_Mesaj_SPV(tcRecipisa, tcAlias)
	*
	If Empty(tcAlias)
		tcAlias = 'c_Get_Mesaje_SPV'
	EndIf
	*	
	*If Used('EFA_INTRARI')
	Do Case
		Case tcAlias = 'EFA_INTRARI'
			Select AllTrim(Tip) From EFA_INTRARI		Where AllTrim(Recipisa) == AllTrim(tcRecipisa) Into Array aGet_Id_Mesaj_SPV_Tip
		Case tcAlias = 'c_Get_Mesaje_SPV'
			Select AllTrim(Tip) From c_Get_Mesaje_SPV	Where AllTrim(Recipisa) == AllTrim(tcRecipisa) Into Array aGet_Id_Mesaj_SPV_Tip
		OtherWise
			Select AllTrim(Tip) From (tcAlias)			Where AllTrim(Recipisa) == AllTrim(tcRecipisa) Into Array aGet_Id_Mesaj_SPV_Tip
	EndCase
	*
	Return Iif(_Tally>0, aGet_Id_Mesaj_SPV_Tip(1), '')
EndFunc
* __________________________________________________________________________________________________________
Function Get_LOG_EFA()
	Local lcCale_LOG As String
	lcCale_LOG = ExpDir+"Declaratii\E-Factura\"+GetNumeDir()+"\LOG\"
	*
	If Not Directory(lcCale_LOG)
		Md (lcCale_LOG)
	EndIf
	*
	Return lcCale_LOG
EndFunc
* __________________________________________________________________________________________________________
Function GetErr_Chilkat_Rest(tnConnectFailReason)
	Local lcMesaj As String
	Store '' to lcMesaj
	*
	Do Case
		Case tnConnectFailReason=0
			lcMesaj=AllTrim(Transform(tnConnectFailReason))+'.'+'success'
		&& Normal (non-SSL) sockets:
		Case tnConnectFailReason=1
			lcMesaj=AllTrim(Transform(tnConnectFailReason))+'.'+'empty hostname' 
		Case tnConnectFailReason=2
			lcMesaj=AllTrim(Transform(tnConnectFailReason))+'.'+'DNS lookup failed'
		Case tnConnectFailReason=3
			lcMesaj=AllTrim(Transform(tnConnectFailReason))+'.'+'DNS timeout'
		Case tnConnectFailReason=4
			lcMesaj=AllTrim(Transform(tnConnectFailReason))+'.'+'Aborted by application.'
		Case tnConnectFailReason=5
			lcMesaj=AllTrim(Transform(tnConnectFailReason))+'.'+'Internal failure.'
		Case tnConnectFailReason=6
			lcMesaj=AllTrim(Transform(tnConnectFailReason))+'.'+'Connect Timed Out'
		Case tnConnectFailReason=7
			lcMesaj=AllTrim(Transform(tnConnectFailReason))+'.'+'Connect Rejected (or failed for some other reason)'
		Case tnConnectFailReason=99
			lcMesaj=AllTrim(Transform(tnConnectFailReason))+'.'+'Chilkat not unlocked / trial expired.'
		&& SSL/TLS:
		Case tnConnectFailReason=100
			lcMesaj=AllTrim(Transform(tnConnectFailReason))+'.'+'TLS internal error'
		Case tnConnectFailReason=101
			lcMesaj=AllTrim(Transform(tnConnectFailReason))+'.'+'Failed to send client hello.'
		Case tnConnectFailReason=102
			lcMesaj=AllTrim(Transform(tnConnectFailReason))+'.'+'Unexpected handshake message.'
		Case tnConnectFailReason=103
			lcMesaj=AllTrim(Transform(tnConnectFailReason))+'.'+'Failed to read server hello.'
		Case tnConnectFailReason=104
			lcMesaj=AllTrim(Transform(tnConnectFailReason))+'.'+'No server certificate.'
		Case tnConnectFailReason=105
			lcMesaj=AllTrim(Transform(tnConnectFailReason))+'.'+'Unexpected TLS protocol version.'
		Case tnConnectFailReason=106
			lcMesaj=AllTrim(Transform(tnConnectFailReason))+'.'+[Server certificate verify failed (the server certificate is expired or the cert's signature verification failed).]
		Case tnConnectFailReason=107
			lcMesaj=AllTrim(Transform(tnConnectFailReason))+'.'+'Unacceptable TLS protocol version.'
		Case tnConnectFailReason=108
			lcMesaj=AllTrim(Transform(tnConnectFailReason))+'.'+' NU EXISTA MEXSAJ DE EROARE, just in case'
		Case tnConnectFailReason=109
			lcMesaj=AllTrim(Transform(tnConnectFailReason))+'.'+'Failed to read handshake messages.'
		Case tnConnectFailReason=110
			lcMesaj=AllTrim(Transform(tnConnectFailReason))+'.'+'Failed to send client certificate handshake message.'
		Case tnConnectFailReason=111
			lcMesaj=AllTrim(Transform(tnConnectFailReason))+'.'+'Failed to send client key exchange handshake message.'
		Case tnConnectFailReason=112
			lcMesaj=AllTrim(Transform(tnConnectFailReason))+'.'+[Client certificate's private key not accessible.]
		Case tnConnectFailReason=113
			lcMesaj=AllTrim(Transform(tnConnectFailReason))+'.'+'Failed to send client cert verify handshake message.'
		Case tnConnectFailReason=114
			lcMesaj=AllTrim(Transform(tnConnectFailReason))+'.'+'Failed to send change cipher spec handshake message.'
		Case tnConnectFailReason=115
			lcMesaj=AllTrim(Transform(tnConnectFailReason))+'.'+'Failed to send finished handshake message.'
		Case tnConnectFailReason=116
			lcMesaj=AllTrim(Transform(tnConnectFailReason))+'.'+[Server's Finished message is invalid.]
	EndCase
	*
	Return lcMesaj
EndFunc
* __________________________________________________________________________________________________________
Procedure Chilkat_Diacritice (lcSursa)
	loStringBuilder = CreateObject('Chilkat_9_5_0.StringBuilder')
	loStringBuilder.LoadFile(lcSursa,"utf-8")

	loStringBuilder.Replace("\u0102","A") &&&&& �
	loStringBuilder.Replace("\u0103","a") &&&&& �

	loStringBuilder.Replace("\u00c2","A") &&&&& �
	loStringBuilder.Replace("\u00e2","a") &&&&& �

	loStringBuilder.Replace("\u00ce","I") &&&&& �
	loStringBuilder.Replace("\u00ee","i") &&&&& �

	loStringBuilder.Replace("\u0218","S") 
	loStringBuilder.Replace("\u0219","s")

	loStringBuilder.Replace("\u015e","S") 
	loStringBuilder.Replace("\u015f","s")

	loStringBuilder.Replace("\u0536","S") 
	loStringBuilder.Replace("\u0537","s")

	loStringBuilder.Replace("\u021a","T")
	loStringBuilder.Replace("\u021b","t")

	loStringBuilder.Replace("\u0538","T")
	loStringBuilder.Replace("\u0539","t")

	loStringBuilder.Replace("\u0327","")
	loStringBuilder.Replace("\u0326","")

	loStringBuilder.WriteFile(lcSursa, "utf-8", 0)
EndProc
* __________________________________________________________________________________________________________
Procedure base64_encode(lcText, lcRaspuns)
	#if .f.
	IF !base64_encode(loConexiune.apiUserName+":"+loConexiune.apiPassword, @lcAutorization)
		__Consola("API_Emag_Courier_Accounts: base64_encode: eroare")
	    RETURN .F.
	ENDIF	
	#endif
	LOCAL loBinData, lcString, lnSuccess
	loBinData = CreateObject('Chilkat_9_5_0.BinData')
	IF loBinData.AppendString(lcText,"utf-8") # 1
		RETURN .F.
	ENDIF 	
	lcRaspuns = loBinData.GetEncoded("base64")
EndProc
*_________________________________________________________________________________________________________	
Procedure Eroare_EFA(tcRaspuns)
	loRaspuns = CreateObject('Chilkat_9_5_0.JsonObject')
	loRaspuns.Load(tcRaspuns)
	llisError      = (loRaspuns.StringOf("isError") = "true")
	*
	If llisError
		loMessages = oRaspuns.ArrayOf("messages")
		lcMesaj    = loMessages.StringAt(0)
		__Consola("EFA : " + "Raspuns = " + lcMesaj)
		RETURN .F.
	EndIf
	*
EndProc
* __________________________________________________________________________________________________________
Function Check_CoduriArticole_ERR()																					&& 12Iunie2023
	If m.ISI
		*
		mCoduriNcERR = ""
		mCoduriCpvERR = ""
		If  .Not. Used("CODURI_NC")
			mySQLExec([Select Cod, Denumire From Articole_Coduri_eFactura Order By Denumire], [CODURI_NC] )
		EndIf
		*
		If  .Not. Used("CODURI_CPV")
			mySQLExec([Select Cod, Denumire From Cpv Order by Denumire], [CODURI_CPV] )
		EndIf
		*
		If  .Not. Used("c_Get_CBare")
			Text To lcSQL NoShow TextMerge
				Select
					ID As Cod
					, [Cod_Bare]=Cast(CodBare As Numeric(13, 0))
					, Greutate
					, Space(50) As Text_Supl
					, IsLot As Is_Lot
					, Tva
					, [Cod_NC8]=Articole.NC8
					, [Cod_CPV]=Articole.CPV
				From Articole
				Where
					Id IN <<cListIdArticole>>
			EndText
			mySQLExec(lcSQL, [c_Get_CBare])
		EndIf
		*	
		Select Distinct;
			c_Get_cBare.Cod_NC8, c_Get_cBare.Cod;
		From crsEFactura;
			Inner Join c_Get_cBare On crsEFactura.Cod=c_Get_cBare.Cod;
		Where;
			Not Empty(c_Get_cBare.Cod_NC8);
		Into Cursor C_EFACT_CODURI_NC
		*
		Select Distinct;
			c_Get_cBare.Cod_CPV, c_Get_cBare.Cod;
		From crsEFactura;
			Inner Join c_Get_cBare On crsEFactura.Cod=c_Get_cBare.Cod;
		Where;
			Not Empty(c_Get_cBare.Cod_CPV);
		Into Cursor C_EFACT_CODURI_CPV
		*
		If RecCount("C_EFACT_CODURI_NC")>0
			Select;
				Cod_NC8, Cod;
			From C_EFACT_CODURI_NC;
			Where;
				Cod_NC8 Not In(Select Cod From CODURI_NC);
			Into Cursor C_EFACT_CODURI_NC_ERR
			*
			If RecCount("C_EFACT_CODURI_NC_ERR")>0
				mCoduriNcERR = mCoduriNcERR+"Cod articol: "+AllTrim(C_EFACT_CODURI_NC_ERR.Cod)+" "+"Cod NC incorect: "+AllTrim(C_EFACT_CODURI_NC_ERR.Cod_NC8)+Chr(13)
			EndIf
			*
			If Year(mdata)>2022
				Select;
					Cod_NC8, Cod;
				From C_EFACT_CODURI_NC;
				Where;
					Cod_NC8 In(Select Cod From CODURI_NC );		&& Where An=2022
				Into Cursor C_EFACT_CODURI_NC_ERR_DATA
				*
				If RecCount("C_EFACT_CODURI_NC_ERR_DATA")>0
					mCoduriNcERR = mCoduriNcERR+"Cod articol: "+AllTrim(C_EFACT_CODURI_NC_ERR_DATA.Cod)+" "+"Codul NC nu este valabil in data curenta : "+AllTrim(C_EFACT_CODURI_NC_ERR_DATA.Cod_NC8)+Chr(13)
				EndIf
				*
			EndIf
			*
		EndIf
		*
		If RecCount("C_EFACT_CODURI_CPV")>0
			Select;
				Cod_CPV, Cod;
			From C_EFACT_CODURI_CPV;
			Where;
				Cod_CPV Not In(Select Cod From CODURI_CPV);
			Into Cursor C_EFACT_CODURI_CPV_ERR
			*
			If RecCount("C_EFACT_CODURI_CPV_ERR")>0
				mCoduriCpvERR = mCoduriCpvERR+"Cod articol: "+AllTrim(C_EFACT_CODURI_CPV_ERR.Cod)+" "+"Cod CPV incorect: "+AllTrim(C_EFACT_CODURI_CPV_ERR.Cod_CPV)+Chr(13)
			EndIf
			*
		EndIf
		*
		If  .Not. Empty(mCoduriNcERR) .Or.  .Not. Empty(mCoduriCpvERR)
			Return "Erori de validare articole: "+Chr(13)+IIf( .Not. Empty(mCoduriNcERR), mCoduriNcERR+Chr(13), "")+mCoduriCpvERR
		EndIf
		*
	EndIf
EndFunc
* __________________________________________________________________________________________________________	
Function GetIncasariFactura(tnIDNota)
	lnIdNota = tnIdNota
	*
	If Type('ll_Is_ICAS')='U'
		Public ll_Is_ICAS
		ll_Is_ICAS = ( VarType(ICAS)='O' And Not IsNull(ICAS) ) And PemStatus(ICAS, 'oCfgSALARII', 5)
	EndIf
	*
	If ll_Is_ICAS
		*
		Text To lcSQL NoShow TextMerge
			Select
				[Suma]=Sum(Suma)
			From NoteFacturi
			Where
				IDNota=?lnIdNota
		EndText
		*
	Else
		*
		Text To lcSQL NoShow TextMerge
			Select
				999999999.99-999999999.99 As Suma
			From Docum
			Where
				1=0
		EndText
		*
	EndIf
	*			
	=mySQLExec(lcSQL, [crsGetIncasariFactura]) 
	*
	If aCountInfo(2)>0
		lnSuma = Nvl(crsGetIncasariFactura.Suma, 0)
	Else
		lnSuma = 0
	EndIf
	*
	Return lnSuma
EndFunc
* __________________________________________________________________________________________________________
Function GetContIntrari_eFactura(tcDenArticol)
	lcAdditiveWhere		= ""
	*
	If !IsNullOrEmpty(tcDenArticol) And VarType(tcDenArticol)='C'
		lcDenArticol	= tcDenArticol
		lcAdditiveWhere = lcAdditiveWhere + ' And  dl.Denumire=?lcDenArticol'
	EndIf
	*	
	Text To lcSQL NoShow TextMerge
		Select
			dl.Cont
			, [Denumire]=dl.Denumire
			, DenTipArt
			, IdTipArt
			, DenGest
			, IdGest
			, IdArticol
			, [Nr_Aparitii]=Count(dl.Cont)
		From IntrariDetaliat dl
		Inner Join Conturi c On c.Cont=dl.Cont
		Where
			IsNull(c.Sters, 0)=0
			And IsNull(dl.Sters, 0)=0
			And dl.IdDoc<>?Documente.IdDoc
			<<lcAdditiveWhere>>
		Group By dl.Cont, dl.Denumire, DenTipArt, IdTipArt, DenGest, IdGest,IdArticol
		Order By dl.Cont
	EndText
	mySQLExec(lcSQL, [cGetCont]) 
	*
	Select;
		Cont, Max(Nr_Aparitii) As Nr_Aparitii ;
	From cGetCont ;
	Group By Cont ;
	Into Cursor cMax
	*
	Delete From cGetCont Where Cont+Str(Nr_Aparitii) Not In(Select Cont+Str(Nr_Aparitii) From cMax)
	*
	Select cGetCont
	*mNrAparitii=0
	Calculate Max(Nr_Aparitii) To mNrAparitii
	Locate For Nr_Aparitii=mNrAparitii
EndFunc
* __________________________________________________________________________________________________________
Procedure Insert_Note (toNode, tcText, tnDimensiune)
	*
	Local jj, mlTextNone, mlLenText
	tcText = AllTrim(StrTran(tcText, Chr(13), ';'))
	*
	If ParseDiacritics(tcText, 1)=1
		tcText = ReplaceDiacritics(tcText)		&&, 0)
	EndIf
	*
	mlLenText = Len(tcText)
	jj = 0
	*
	Do While .T.
		*
		mlTextNone = AllTrim(SubStr(tcText, jj*tnDimensiune+1, tnDimensiune))
			*
		If  .Not. Empty(mlTextNone)
			toNode.AppendChild(oXML.CreateElement("Note"))
			toNode.LastChild.Text = mlTextNone
		EndIf
		*
		jj = jj+1
		mlLenText = mlLenText-tnDimensiune
		*
		If mlLenText<0
			Exit
		EndIf
		*
	EndDo
	*
EndProc
* __________________________________________________________________________________________________________	
Procedure Create_Cursor_Judete()
	Text To lcSQL NoShow TextMerge
	"JUDET", "COD"
	"ALBA","AB"
	"ARAD","AR"
	"ARGES","AG"
	"BACAU","BC"
	"BIHOR","BH"
	"BISTRITA-NASAUD","BN"
	"BOTOSANI","BT"
	"BRASOV","BV"
	"BRAILA","BR"
	"BUZAU","BZ"
	"CARAS-SEVERIN","CS"
	"CLUJ","CJ"
	"CONSTANTA","CT"
	"COVASNA","CV"
	"DAMBOVITA","DB"
	"DOLJ","DJ"
	"GALATI","GL"
	"GORJ","GJ"
	"HARGHITA","HR"
	"HUNEDOARA","HD"
	"IALOMITA","IL"
	"IASI","IS"
	"GIURGIU","GR"
	"MARAMURES","MM"
	"MEHEDINTI","MH"
	"MURES","MS"
	"NEAMT","NT"
	"OLT","OT"
	"PRAHOVA","PH"
	"SATU MARE","SM"
	"SALAJ","SJ"
	"SIBIU","SB"
	"SUCEAVA","SV"
	"TELEORMAN","TR"
	"TIMIS","TM"
	"TULCEA","TL"
	"VASLUI","VS"
	"VALCEA","VL"
	"VRANCEA","VN"
	"CALARASI","CL"
	"BUCURESTI","B"
	"ILFOV","IF"
	EndText
	StrToFile(lcSQL, 'judete.csv')
	Create Cursor Judete (DenJud C(15), Cod C(2))
	Append From ('judete.csv') CSV
	*
EndProc	
* __________________________________________________________________________________________________________
Procedure Get_Cursor_crsEFactura_eSTOC(tnIdUnicFactura, tcAlias)
	lnIdUnicFactura		= tnIdUnicFactura
	lcAlias				= tcAlias
	lc_RPad_3Parameter	= Iif(ICAS.cBackEnd='MySQL', [, ''], [])
	*
	Text To lcSQL NoShow TextMerge	
		Select
			Cast(0 As Decimal(2,0))					As Indice
			, Coalesce(i.Factura, i.Avizul)			As Nr
			, i.Data_Doc							As Data
			, i.Data_Scad							As Scadent
			, i.Denum_Furn							As Den_Cli
			, ' '									As Tip
			-- , Is_EF								As TvaI
			, i.Id									As TvaI
			, 1										As Curs_Ref
			, i.Cod_Furn							As Cont_Cli
			, i.Obs1 								As Inf_Suplm
			, c.Cod_Fisc							As Cod_Fiscal
			, Coalesce(c.RegistrulComertului, '')	As Reg_Com
			, Coalesce(c.Tara, 'RO')				As Tara
			, c.Judet								As Judet
			-- , c.CodPostal						As CodPostal
			, c.Localitate							As Localitate
			, ''									As Sector
			, c.Sediu								As Strada
			, ''									As Nr_Str
			, ''									As Bloc
			, ''									As Scara
			, ''									As Etaj
			, ''									As Ap
			, c.Sediu								As Adresa
			, Coalesce(c.Tel, '')					As Telefon
			, Coalesce(c.Email, '')					As Email
			, c.Cont_B								As Cont_Banca
			, Coalesce(c.Banca, '')					As Banca
			, i.Obs2								As Inf_Supl
	        , RPad('', 20 <<lc_RPad_3Parameter>>)	As Delegat
			, '1'									As Tip_Tert
			-- , c.Is_Tva							As Is_Tva
			, i.ID									As IdUnic
			-- , i.Gesti_Ies						As Gestiune
			, Coalesce(d.Cod_Prod, 0)				As Cod
			, RPad('',13 <<lc_RPad_3Parameter>>)	As Cod_CPV
			, RPad('',13 <<lc_RPad_3Parameter>>)	As Cod_NC8
			, d.Den_Produs							As Denumire
			, Cast('' As Char(4000))				As Text_Supl
			, d.Tva_Neex							As ProcTva
			, Case d.Tva_Neex 
				When 19 Then '6-7'
				When 9 Then '8-9'
				When 5 Then '19-20'
				Else '18'
			End										As CodTva	
			, d.Um									As Um
			, d.Cantitate							As Cantitate
			, d.Pret_Vanz							As Pret_Vanz
			, Round(d.Cantitate*d.Pret_Vanz, 2)		As Valoare
			, d.Val_Tva								As Tva
			, Round(d.Cantitate*d.Pret_Vanz, 2)		As ValoareLei
			, d.Val_Tva								As TvaLei
			, Cast(0 As Decimal(14,2))				As Accize
			, 'RON'									As Moneda
			, RPad('',36  <<lc_RPad_3Parameter>>)	As Cod_Art_Cl
			, RPad('',250 <<lc_RPad_3Parameter>>)	As Is_A
			, Cont_1								As Cont
			, 1.0000								As Curs
			, BFTiparit								As Tiparit
			, i.Id									As Id
			, Recipisa								As Recipisa
			, Cast(0 As Decimal(5,0)) As IdBanca1
			, Cast(0 As Decimal(5,0)) As IdBanca2
			, Cast(0 As Decimal(5,0)) As IdBanca3
			, Cast(0 As Decimal(5,0)) As IdBanca7
			, Cast('' As Char(30))	  As BT_11
			, Cast('' As Char(30))	  As BT_13
			, i.Tip_Fact								As Tip_Fact
		From  Docum i
		Inner Join D_Docum d On i.ID=d.IDDocum
		Inner Join Produs p On p.Cod_Prod=d.Cod_Prod
		Inner Join Furnizor c On c.Cod_Furn=i.Cod_Furn
		Where
			i.ID=?lnIdUnicFactura
	EndText
	mySQLExec(lcSQL, [crsEFactura_SQL_ESTOC])
	*
	Select *;
		, .F. As Is_Extern;
	From crsEFactura_SQL_ESTOC;
	Into Cursor crsEFactura ReadWrite
	*
	*=========  14Ianuarie2025 =================
	Update crsEFactura Set Tiparit = 1 Where Tip_Fact = 7
	*=========  14Ianuarie2025 =================
	*	
	Update crsEFactura Set TvaI = 0
	Update crsEFactura Set Judet="DAMBOVITA" Where Judet='DIMBOVITA'
	Update crsEFactura Set Judet="DAMBOVITA" Where Judet='DMBOVITA'
	*Update crsEFactura Set Cod_Fiscal = Replicate('0', 13) Where IsNullOrEmpty(Cod_Fiscal) Or Not VerifCF(Cod_Fiscal) And Not ValidCNP(Cod_Fiscal)	&& 23.12.2024
	Update;
		crsEFactura;
	Set;
		Cod_Fiscal = Replicate('0', 13);
	Where;
		(;
			Tara='RO';
		And	IsNullOrEmpty(Cod_Fiscal);
		);
		Or;
		(;
				Tara='RO';
		And Not VerifCF	(Cod_Fiscal);
		And Not	ValidCNP(Cod_Fiscal);
		)	&& 08.01.2025
	*
EndProc
* ____________________________________________________________________________________________________
Procedure Get_Cursor_crsEFactura(tnIdUnicFactura, tcAlias)
	lnIdUnicFactura	= tnIdUnicFactura
	lcAlias			= tcAlias
	*
	If lcAlias='Iesiri'
		*	Tip NOT IN ('B','C','A','e')
		Text To lcSQL NoShow TextMerge
			Select
				[Indice]		= 0
				, [Nr]			= i.NumarDoc
				, [Data]		= i.DataDoc
				, [Scadent]		= i.Scadenta
				, [Den_Cli]		= i.DenumireClient
				, [Tip]			= i.Tip
				, [TvaI]		= i.IsTvaIncasare
				, [Curs_Ref]	= i.CursReferinta
				, [Cont_Cli]	= i.Cont
				, [Inf_Suplm]	= Cast(i.InfSupl As VarChar(300))
				, [Cod_Fiscal]	= c.Cod_Fiscal
				, [Reg_Com]		= c.Registru
				, [Tara]		= c.Tara
				, [Judet]		= c.Judet
				, [CodPostal]	= IsNull(c.CodPostal, '')
				, [Localitate]	= IsNull(c.Localitate, '')
				, [Sector]		= IsNull(c.Sector, '')
				, [Strada]		= IsNull(c.Strada, '')
				, [Nr_Str]		= IsNull(c.Nr_Str, '')
				, [Bloc]		= IsNull(c.Bloc, '')
				, [Scara]		= IsNull(c.Scara, '')
				, [Etaj]		= IsNull(c.Etaj, '')
				, [Ap]			= IsNull(c.Ap, '')
				, [Adresa]		= Space(50)
				, [Telefon]		= IsNull(c.Telefon, '')
				, [Email]		= IsNull(c.Email, '')
				, [Cont_Banca]	= c.ContBanca
				, [Banca]		= IsNull(c.Banca, '')
				, [Inf_Supl]	= c.Informatii
				, [Delegat]		= Space(20)
				, [Tip_Tert]	= IsNull(c.Tip_Tert, '')
				, [Is_Tva]		= c.Is_Tva
				, [IdUnic]		= i.IdUnic
				, [Gestiune]	= IsNull(d.IdGest, 0)
				, [Cod]			= IsNull(d.IdArticol, 0)
				, [Denumire]	= d.Denumire
				, [Text_Supl]	= Cast(d.InformatiiSuplimentareArticol As VarChar(200))
				, [CodTva]		= d.CodTva
				, [ProcTva]		= d.ProcTva
				, [Um]			= d.Um
				, [Cantitate]	= d.Cantitate
				, [Pret_Vanz]	= PretUnitar
				, [Valoare]		= d.Valoare
				, [Tva]			= d.Tva
				, [ValoareLei]	= d.Valoare
				, [TvaLei]		= d.Tva
				, [Accize]		= i.Accize
				, [Moneda]		= 'RON'
				, [Curs]		= 1
				, [Cod_Art_Cl]	= Replicate(' ', 36)
				, [Is_A]		= Replicate(' ', 250)
				, [Cont]		= d.Cont
				, [IdDoc]		= i.IdDoc
				, [Cod_NC8]		= IsNull(a.NC8, Space(8))
				, [Cod_CPV]		= IsNull(a.CPV, Space(10))
				, [Tiparit]		= i.BFTiparit
				, [Recipisa]	= Recipisa
				, [IdBanca1]	= i.IdBanca1
				, [IdBanca2]	= i.IdBanca2
				, [IdBanca3]	= i.IdBanca3
				, [IdBanca4]	= i.IdBanca4
				, [BT_11]		= i.BT_11
				, [BT_13]		= i.BT_13
				, [Is_Extern]	= Cast(0 As Bit)
			From  Iesiri i
			Inner Join IesiriDetaliat d On i.IDDoc=d.IDDoc
			Left Join Articole a On a.Id=d.IdArticol
			Left Join
				(
				Select *
				From Conturi 
				Where 
					SubString(Cont, 1, 3) In('411', '418', '461') 
					And Len(Cont)>=3 
					And IsNull(Sters,0)=0
				) c On i.Cont=c.Cont
			Where
				i.IDUnic=?lnIdUnicFactura
				And IsNull(Anulat, 0)=0
		EndText
		*
	Else		If lcAlias='Iesiri'
		* Tip NOT IN ('B','C','A','e','W','X','Y')
		Text To lcSQL NoShow TextMerge
			Select
				[Indice]=0
				, [Nr]=i.NumarDoc
				, [Data]=i.DataDoc
				, [Scadent]=i.Scadenta
				, [Den_Cli]=i.DenumireClient
				, [Tip]=i.Tip
				, [TvaI]=i.IsTvaIncasare
				, [Curs_Ref]=i.CursReferinta
				, [Cont_Cli]=i.Cont
				, [Inf_Suplm]=Cast(i.InfSupl As VarChar(300))
				, [Cod_Fiscal]=c.Cod_Fiscal
				, [Reg_Com]=c.Registru
				, [Tara]=c.Tara
				, [Judet]=c.Judet
				, [CodPostal] = IsNull(c.CodPostal, '')
				, [Localitate]=IsNull(c.Localitate, '')
				, [Sector]=IsNull(c.Sector, '')
				, [Strada]=IsNull(c.Strada, '')
				, [Nr_Str]=IsNull(c.Nr_Str, '')
				, [Bloc]=IsNull(c.Bloc, '')
				, [Scara]=IsNull(c.Scara, '')
				, [Etaj]=IsNull(c.Etaj, '')
				, [Ap]=IsNull(c.Ap, '')
				, [Adresa]=Space(50)
				, [Telefon]=IsNull(c.Telefon, '')
				, [Email]=IsNull(c.Email, '')
				, [Cont_Banca]=c.ContBanca
				, [Banca]=IsNull(c.Banca, '')
				, [Inf_Supl]=c.Informatii
				, [Delegat]=Space(20)
				, [Tip_Tert]=IsNull(c.Tip_Tert, '')
				, [Is_Tva]=c.Is_Tva
				, [IdUnic]=i.IdUnic
				, [Gestiune]=IsNull(d.IdGest, 0)
				, [Cod]=IsNull(d.IdArticol, 0)
				, [Denumire]=d.Denumire
				, [Text_Supl]=Cast(d.InformatiiSuplimentareArticol As VarChar(200))
				, [CodTva]=d.CodTva
				, [ProcTva]=d.ProcTva
				, [Um]=d.Um
				, [Cantitate]=d.Cantitate
				-- , [Pret_Vanz]=PretUnitar
				, [Pret_Vanz]=PretUnitarValuta
				-- , [Valoare]=d.Valoare
				-- , [Tva]=d.Tva
				, [Valoare]		= d.ValoareValuta
				, [Tva]			= d.TvaValuta
				, [ValoareLei]	= d.Valoare
				, [TvaLei]		= d.Tva
				, [Accize]=0
				-- , [Moneda]='RON'
				, [Moneda]=i.CodValuta
				, [Curs]=i.Curs
				, [Cod_Art_Cl]=Replicate(' ', 36)
				, [Is_A]=Replicate(' ', 250)
				, [Cont]=d.Cont
				, [IdDoc]=i.IdDoc
				, [Cod_NC8]=IsNull(a.NC8, Space(8))
				, [Cod_CPV]=IsNull(a.CPV, Space(10))
				, [Tiparit]=i.BFTiparit
				, Recipisa
				, [IdBanca1]	= i.IdBanca1
				, [IdBanca2]	= i.IdBanca2
				, [IdBanca3]	= i.IdBanca3
				, [IdBanca4]	= i.IdBanca4
				, [BT_11]		= Cast('' As Char(30))
				, [BT_13]		= Cast('' As Char(30))
				, [Is_Extern]	= Cast(0 As Bit)
			From  Export i
			Inner Join ExportDetaliat d On i.IDDoc=d.IDDoc
			Left Join Articole a On a.Id=d.IdArticol
			Left Join
				(
				Select *
				From Conturi 
				Where 
					SubString(Cont, 1, 3) In('411', '418', '461') 
					And Len(Cont)>=3 
					And IsNull(Sters,0)=0
				) c On i.Cont=c.Cont
			Where
				i.IDUnic=?lnIdUnicFactura
				And IsNull(Anulat, 0)=0
		EndText
		*
	EndIf
	=mySQLExec(lcSQL, [crsEFactura]) 
	*
	Update crsEFactura Set Judet="DAMBOVITA" Where Judet='DIMBOVITA'
	Update crsEFactura Set Judet="DAMBOVITA" Where Judet='DMBOVITA'
	*
	UPDATE crsEFactura Set Is_Extern = .T. Where .NOT. IsNullOrEmpty(Tara) .AND. UPPER(Tara)<>"RO"
	*Update crsEFactura Set Cod_Fiscal = Replicate('0', 13) Where IsNullOrEmpty(Cod_Fiscal) Or Not VerifCF(Cod_Fiscal) And Not ValidCNP(Cod_Fiscal)	&& 23.12.2024
	* Daca este vorba despre o persoana fizica, CompanyID trebuie sa fie un CNP valid sau, �n varianta anonimizata, 0000000000000.
	Update;
		crsEFactura;
	Set;
		Cod_Fiscal = Replicate('0', 13);
	Where;
		(;
			Tara='RO';
		And	IsNullOrEmpty(Cod_Fiscal);
		);
		Or;
		(;
				Tara='RO';
		And Not VerifCF	(Cod_Fiscal);
		And Not	ValidCNP(Cod_Fiscal);
		)	&& 08.01.2025
	*
	*
EndProc	
* __________________________________________________________________________________________________________
Procedure Update_eFactura_API_StareMesaj(tnIdDoc, tcId_Descarcare, tcStare, tcTabela)
	*
	lnIdDoc			= tnIdDoc
	lcId_Descarcare = tcId_Descarcare
	lcStare			= tcStare
	lcTabela		= tcTabela
	*
	If Type('ll_Is_ICAS')='U'
		Public ll_Is_ICAS
		ll_Is_ICAS = ( VarType(ICAS)='O' And Not IsNull(ICAS) ) And PemStatus(ICAS, 'oCfgSALARII', 5)
	EndIf
	*
	If Not ll_Is_ICAS
		*
		lcTabela = 'Docum'
		*
		Text To lcSQL NoShow TextMerge
			Update <<lcTabela>>
			Set
					recipisa		= ?lcId_Descarcare
				,	id_descarcare	= ?lcId_Descarcare
				,	eFact_Detalii	= ?lcStare
				,	eFact_stare		= ?lcStare
			Where
				ID					= ?lnIdDoc
		EndText
		mySQLExec(lcSQL)
		*
		*		
	Else	
		*
		Text To lcSQL NoShow TextMerge
			Update <<lcTabela>>
			Set
					recipisa		= ?lcId_Descarcare
				,	id_descarcare	= ?lcId_Descarcare
				,	eFact_Detalii	= ?lcStare
				,	eFact_stare		= ?lcStare
			Where
				IdDoc				= ?lnIdDoc
		EndText
		mySQLExec(lcSQL)
		*
	EndIf
	*
EndProc	
* __________________________________________________________________________________________________________	
Procedure ReadErrorsFromZip(tcId_Solicitare, tcId_Descarcare, tcNumarDoc, tdDataDoc, tnIdDoc, tcXML_For_Test, tcAlias)
	*
	If Empty(tcAlias)
		tcAlias = 'Sel_eFactura'
	EndIf
	*	
	loXml				= Createobject('Chilkat_9_5_0.Xml')
	*
	If Empty(tcXML_For_Test)
		*
		lcId_Solicitare	= tcId_Solicitare
		lcId_Descarcare	= tcId_Descarcare
		lcNumarDoc		= tcNumarDoc
		ldDataDoc		= tdDataDoc
		lnIdDoc			= tnIdDoc
		*descarcare zip si afisare eroare
		lo_EFA_CLIENT = Descarca_eFactura_Client(lcId_Descarcare, tcAlias, .F., tdDataDoc)
		lcZipFile = lo_EFA_CLIENT.cZipFileName
		lcDirUnZip = JustPath(lcZipFile)+'\ERORI\'
		*
		If Not Directory(lcDirUnZip)
			Md (lcDirUnZip)
		EndIf
		*
		*loResponse = Createobject('Chilkat_9_5_0.BinData')
		*loResponse.LoadFile(lcZipFile)
		*
		lcXML = lcID_Solicitare +".xml"
		loZip = Createobject('Chilkat_9_5_0.Zip')
		lnSuccess = loZip.OpenZip(lcZipFile)
		*				*
		loEntry = loZip.GetEntryByName(lcXML)
		* Assume entry is non-null.  If GetEntryByName failed
		* to find the entry, it returns a null reference.
		lcErrXML	= lcID_Solicitare + '_' + lcNumarDoc + '_' + Transform(DToS(ldDataDoc), '@R ####-##-##')+".xml"
		loEntry.FileName = 	lcErrXML
		*
		lnNumFilesUnzipped = loZip.Unzip(lcDirUnZip+lcId_Descarcare)
		IF (lnNumFilesUnzipped < 0) THEN
		    ? loZip.LastErrorText
		    RELEASE loZip
		    *CANCEL
		EndIf 		
		*
		lcXMLFileUnzipped	= lcDirUnZip+lcId_Descarcare+"\"+lcErrXML
		lnSucces			= loXml.LoadXmlFile(lcXMLFileUnzipped)
		*
	Else
		*
		lnSucces			= loXml.LoadXml(tcXML_For_Test)
		*
	EndIf
	*
	lcMesajEroare = ""
	*
	If lnSucces = 1
		*
		* Citeste atributele radacinii 'header'
		*lcHeader_xmlns				= loXml.GetAttrValue("xmlns")
		lcHeader_Index_incarcare	= loXml.GetAttrValue("Index_incarcare")
		lcHeader_Cif_emitent		= loXml.GetAttrValue("Cif_emitent")
		*? "lcHeader_xmlns ", lcHeader_xmlns
		? "Index_incarcare ",	lcHeader_Index_incarcare
		? "Cif_emitent ",		lcHeader_Cif_emitent
		*
		lnCount_i = loXml.NumChildrenHavingTag("Error")
		*
		For i=0 To lnCount_i-1
		    loXml.I = i
		    lcError_errorMessage = loXml.ChilkatPath("Error[i]|(errorMessage)")
		    ? "Mesaj eroare ("+Transform(i)+"): ", lcError_errorMessage
		    lcMesajEroare = lcMesajEroare + "Mesaj eroare ("+Transform(i)+"): " + lcError_errorMessage  + Chr(13)
		EndFor
		*
		*!*		If lnSucces = 1
		*!*			* Prinde elementul radacina 'header'
		*!*			loNode = loXml.GetRoot()
		*!*			*
		*!*			If Not Isnull(loNode)
		*!*				* Citeste atributele radacinii 'header'
		*!*				lc_Index_incarcare	= loNode.GetAttrValue("Index_incarcare")
		*!*				lc_CIF_emitent		= loNode.GetAttrValue("Cif_emitent")
		*!*				? "Index �ncarcare:",	lc_Index_Incarcare
		*!*				? "CIF emitent:",		lc_CIF_emitent
		*!*				*lcMesajEroare = lcMesajEroare + Chr(13) +;
		*!*					 "index_incarcare = "	+ lc_Index_incarcare + ", " +;
		*!*					 "Cif_emitent= "		+ lc_CIF_emitent
		*!*				*
		*!*				* Gaseste primul nod 'Error'
		*!*				loNode = loNode.FirstChild()
		*!*				lnI = 0
		*!*				*
		*!*				Do While Not Isnull(loNode)
		*!*					*
		*!*					If loNode.Tag = "Error"
		*!*						*
		*!*						lnI = lnI + 1 
		*!*						lc_errorMessage = loNode.GetAttributeValue(0)
		*!*						? "Mesaj eroare ("+Transform(lnI)+"): ", lc_errorMessage
		*!*						*
		*!*						lcMesajEroare = lcMesajEroare + "Mesaj eroare ("+Transform(lnI)+"): " + lc_errorMessage + Chr(13)
		*!*						* Mergi la urmatorul nod frate
		*!*						loNode = loNode.NextSibling()
		*!*					Endif
		*!*					*
		*!*				Enddo
			*
		If Empty(tcXML_For_Test)
			*
			Replace;
				Mesaj	With Mesaj+"; "+lcMesajEroare ;
			In Sel_eFactura
			*
			&& Update IESIRI,EXPORT  SAU DOCUM
			*
			*
			&& Declarate in SCAN Sel_eFactura
			*
			*lcTabela		= Iif(ll_Is_ICAS, AllTrim(Sel_eFactura.Ecran), 'DOCUM')
			*lc_Field_ID		= Iif(ll_Is_ICAS, 'IdDoc', 'Id')
			*
			If Used(lcTabela) And IsField('BFTiparit', lcTabela)
				*
				Text To lcSQL NoShow TextMerge
					Update;
						<<lcTabela>>;
					Set;
						eFact_Detalii	= lcMesajEroare;
					Where;
						<<lc_Field_ID>>		= lnIdDoc
				EndText
				lOk = ExecScript(lcSQL) 
				*	
				If ICAS.cBackEnd='MySQL'
					Salvare_MySQL('Docum', cWhere, llNewRecord)
				Else
					=TableUpdate(.T., .T., lcTabela)
				EndIf
				*
			Else
				*
				Text To lcSQL NoShow TextMerge
					Update
						<<lcTabela>>
					Set
						eFact_Detalii	= ?lcMesajEroare
					Where
						<<lc_Field_ID>>		= ?lnIdDoc
				EndText
				=mySQLExec(lcSQL)
				*
			EndIf						If Used(lcTabela) And IsField('BFTiparit', lcTabela)
            *	
		*Else							If Not Isnull(loNode)
		*	? "Nu s-a gasit elementul radacina."
		*Endif							If Not Isnull(loNode)
		*
		Endif							If Empty(tcXML_For_Test)
		
	EndIf								If lnSucces = 1
	*
	Return lcMesajEroare
	*
EndProc	
* __________________________________________________________________________________________________________
Function eFactura_API_listaMesajePaginatieFactura(tcCUI, tcToken, tlProd)
	*
	*	E = ERORI FACTURA
	*	T = FACTURA TRIMISA
	*	P = FACTURA PRIMITA
	*	R = MESAJ CUMPARATOR PRIMIT / MESAJ CUMPARATOR TRANSMIS
	*
	Use In Select('c_eFacturi_Mesaje')			&& Vicos.12.02.2024 ca sa preiau toate mesajele SPV in cursorul 'c_eFacturi_Mesaje'

	*
	#if .f.
	*-----------------*
	Response code 200
	*-----------------*
	Media type	application/json
	Examples:
	- cif returneaza mesaje 
	{
	  "mesaje": [
	    {
	      "data_creare": "202210311452",
	      "cif": "8000000000",
	      "id_solicitare": "5001120362",
	      "detalii": "Erori de validare identificate la factura primita cu id_incarcare=5001120362",
	      "tip": "ERORI FACTURA",
	      "id": "3001474425"
	    },
	    {
	      "data_creare": "202210311452",
	      "cif": "8000000000",
	      "id_solicitare": "5001120366",
	      "detalii": "Erori de validare identificate la factura primita cu id_incarcare=5001120366",
	      "tip": "ERORI FACTURA",
	      "id": "3001474424"
	    }
	  ],
	  "numar_inregistrari_in_pagina": 2,
	  "numar_total_inregistrari_per_pagina": 500,
	  "numar_total_inregistrari": 14130,
	  "numar_total_pagini": 29,
	  "index_pagina_curenta": 29,
	  "serial": "1234AA456",
	  "cui": "8000000000",
	  "titlu": "Lista Mesaje disponibile din intervalul 06-09-2022 09:48:20 - 02-11-2022 11:49:24"
	}
	- cif este non numeric
	{
	  "eroare": "CIF introdus= aaa nu este un numar sau nu are o valoare acceptata de sistem",
	  "titlu": "Lista Mesaje"
	}
	- startTime nu este un numar sau nu are o valoare acceptata de sistem
	{
	  "eroare": "startTime = aaa nu este un numar sau nu are o valoare acceptata de sistem",
	  "titlu": "Lista Mesaje"
	}
	- endTime nu este un numar sau nu are o valoare acceptata de sistem
	{
	  "eroare": "endTime = aaa nu este un numar sau nu are o valoare acceptata de sistem",
	  "titlu": "Lista Mesaje"
	}
	- pagina nu este un numar sau nu are o valoare acceptata de sistem
	{
	  "eroare": "pagina = aa nu este un numar sau nu are o valoare acceptata de sistem",
	  "titlu": "Lista Mesaje"
	}
	- startTime mai vechi de 60 de zile
	{
	  "eroare": "startTime = 09-07-2022 10:41:11 nu poate fi mai vechi de 60 de zile fata de momentul requestului",
	  "titlu": "Lista Mesaje"
	}
	- endTime inainte de startTime
	{
	  "eroare": "endTime = 09-08-2022 10:41:11 nu poate fi <= startTime = 06-09-2022 09:48:20",
	  "titlu": "Lista Mesaje"
	}
	- endTime in viitor
	{
	  "eroare": "endTime = 02-12-2022 11:49:24 nu poate in viitor fata de momentul requestului",
	  "titlu": "Lista Mesaje"
	}
	- parametrul filtru invalid
	{
	  "eroare": "Valorile acceptate pentru parametrul filtru sunt E, T, P sau R",
	  "titlu": "Lista Mesaje"
	}
	- nu aveti drept pentru acest cif
	{
	  "eroare": "Nu aveti drept in SPV pentru CIF=8000000000",
	  "titlu": "Lista Mesaje"
	}
	- lipsa drepturi SPV
	{
	  "eroare": "Nu exista niciun CIF pentru care sa aveti drept in SPV",
	  "titlu": "Lista Mesaje"
	}
	- paginia mai mare decat total pagini
	{
	  "eroare": "Pagina solicitata 50 este mai mare decat numarul toatal de pagini 29",
	  "titlu": "Lista Mesaje"
	}
	- nu exista mesaje
	{
	  "eroare": "Nu exista mesaje in intervalul selectat",
	  "titlu": "Lista Mesaje"
	}
	- limita apeluri zilnice atinsa
	{
	  "eroare": "S-au facut deja 1000 interogari de lista mesaje de catre utilizator in cursul zilei",
	  "titlu": "Lista Mesaje"
	}
	*-----------------*
	Response code 400
	*-----------------*
	Media type
	application/json
	Examples:
	- lipsa startTime, endTime, cif sau pagina
	{
	  "timestamp": "19-08-2021 11:59:29",
	  "status": 400,
	  "error": "Bad Request",
	  "message": "Parametrii startTime, endTime, cif si pagina sunt obligatorii"
	}
	*-----------------*
	500	Internal Server Error
	*-----------------*
	Media type
	*/*
	Example Value
	{
	  "timestamp": "2024-02-12T06:40:11.522Z",
	  "status": 0,
	  "error": "string",
	  "message": "string"
	}
	*-----------------*
	CustomErrorMessage
	*-----------------*
	{
	timestamp	string($date-time)
	status	integer($int32)
	error	string
	message	string
	}
	*-----------------*
	Mesaj
	*-----------------*
	{
	data_creare		string
	cif				string
	id_solicitare	string
	detalii			string
	tip				string
	id				string
	}	
	#endif
	*
	
	lcCale_LOG = Get_LOG_EFA()
	Local oSetAlternate As Object, oSetConsole As Object, oSetSafety As Object
	oSetAlternate=CreateObject("SetAlternate", "On", lcCale_Log+Program()+".log")
	oSetConsole=CreateObject("SetConsole", 'Off')
	oSetSafety=CreateObject("SetSafety", "Off")
	*
	Local loSaveSelect As Object
	loSaveSelect=Create("SaveSelect")
	*
	Private Sec_Start
	Store Seconds() to Sec_Start
	LOCAL lcCUI, lcToken, llProductie
	lcCUI   	= Iif( Empty(tcCUI),	ICAS.oSoc.CodFiscal,				tcCUI )
	lcToken 	= Iif( Empty(tcToken),	ICAS.oSettings.eFactura_TokenAcces,	tcToken )
	llProductie = Iif( Empty(tlProd),	ICAS.oSettings.eFactura_Prod,		tlProd )
	*
	IF EMPTY(lcToken)
	    __Consola("Token-ul nu exista")
		RETURN .F.
	ENDIF 
	*
	LOCAL loDateTime, lnBLocal
	loDateTime	= CreateObject('Chilkat_9_5_0.CkDateTime')
	loDateTime.SetFromCurrentSystemTime()
	
	lnBLocal	= 0	&& bLocal indicates whether the date/time returned is local or UTC.
	*lnBLocal	= 1	&& bLocal indicates whether the date/time returned is local or UTC.
	* Cu lnBLocal	= 1 da eroare: ;
		endTime = 05-07-2024 11:34:40 nu poate in viitor fata de momentul requestului = 05-07-2024 08:35:40
	*	
	*{"eroare":"endTime
	* = 05-02-2024 10:06:08 nu poate in viitor fata de momentul requestului
	* = 05-02-2024 10:05:44","titlu":"Lista Mesaje"}	
	loDateTime.AddSeconds(-60)
	lcEndTime	= loDateTime.GetAsUnixTimeStr(lnBLocal) + "000"
	*
	loDateTime.AddSeconds(60 * 60 * 24 * 60 * -1)
	***loDateTime.AddDays(-60)
	lcStartTime	= loDateTime.GetAsUnixTimeStr(lnBLocal) + "000"
	*
	loRest = ICAS.oRest_ANAF
	loRest.AddHeader("Authorization","Bearer " + lcToken)
	loResponse = CreateObject('Chilkat_9_5_0.StringBuilder')
	*
	PRIVATE lnPagini, lnPagina, llBucla, lcURL
	lnPagini = 0
	lnPagina = 1
	llBucla = .T.
	*
	__Consola('lcStartTime  ' + Chr(9)+Transform(lcStartTime) 	+ Chr(9)+Transform(DATETIME(1970, 1, 1, 0, 0, 0) + Val(lcStartTime)	/1000) )
	__Consola('lcEndTime	' + Transform(lcEndTime) 			+ Chr(9)+Transform(DATETIME(1970, 1, 1, 0, 0, 0) + Val(lcEndTime)	/1000) )
	__Consola('lnPagini 	' + Transform(lnPagini ) )
	*
	IF llProductie
		lcURL = '/prod/FCTEL/rest/listaMesajePaginatieFactura?startTime='
	ELSE
		lcURL = '/test/FCTEL/rest/listaMesajePaginatieFactura?startTime='
	ENDIF
 	*
	__Consola('lcURL		' + Transform(lcURL) )
	*
	Local ll_ANAF_Interogare_OK
	ll_ANAF_Interogare_OK = .T.
	*
	DO WHILE llBucla
		*
		lcPagina = ALLTRIM(STR(lnPagina,10,0))
		__Consola('lnPagina		' + Transform(lnPagina) )
		__Consola('llBucla		' + Transform(llBucla) )

	 	lnSuccess = loRest.FullRequestNoBodySb("GET",lcURL+lcStartTime+'&endTime='+lcEndTime+'&cif='+lcCUI+'&pagina='+lcPagina,loResponse)
	 	__Consola('lnSuccess		' + Transform(lnSuccess) )
	 	*
		IF (lnSuccess <> 1) THEN
		    __Consola("Nu se poate efectua GET/listaMesajePaginatieFactura > api.anaf.ro ";
		    														+ STR(loRest.ConnectFailReason))
		    __Consola(" > api.anaf.ro > ResponseStatusCode: "		+ Transform(loRest.ResponseStatusCode) )
		    __Consola(" ICAS.oRest_ANAF.responsestatustext: "		+ Transform(loRest.ResponseStatusText) )
	    	__Consola(" ICAS.oRest_ANAF.responseheader: "			+ Transform(loRest.ResponseHeader) )
	    	*
		    If 'mentenanta'$loRest.ResponseHeader
		    	MessageBox(Transform(loRest.ResponseHeader)+Chr(13)+Transform(loRest.ResponseStatusCode), 16, "Server ANAF")
		    EndIf
		    *
		    Store .F. To ll_ANAF_Interogare_OK
		    Set Step On
			*RETURN .F.
		ENDIF
		*
		If Not ll_ANAF_Interogare_OK
			Set Step On
			Exit
		EndIf
		*
		lnResponseStatusCode = loRest.ResponseStatusCode
		__Consola('loRest.ResponseStatusCode	' + Transform(lnResponseStatusCode) )
		*
		IF lnResponseStatusCode = 200
			=InCursor_c_eFacturi_Mesaje(loResponse.GetAsString())
			*EFA_Consola("ANAF - lista mesaje paginatie - " + lcCUI + " - " + lcPagina + " - " , loResponse.GetAsString())
			EFA_Consola("ANAF - lista mesaje paginatie - " + lcCUI + " - " + lcPagina + " - " , loResponse.GetAsString(), Get_LOG_EFA())
		ELSE
			*IF (loRest.ResponseStatusCode >= 400) 
			    __Consola("Nu se poate efectua Stare > api.anaf.ro "	+ Transform(loRest.ConnectFailReason) )
			    __Consola(" > api.anaf.ro > ResponseStatusCode: "		+ Transform(loRest.ResponseStatusCode) )
			    __Consola(" ICAS.oRest_ANAF.responsestatustext: "		+ Transform(loRest.ResponseStatusText) )
		    	__Consola(" ICAS.oRest_ANAF.responseheader: "			+ Transform(loRest.ResponseHeader) )
		    	*
			    If 'mentenanta'$loRest.ResponseHeader
			    	MessageBox(Transform(loRest.ResponseHeader)+Chr(13)+Transform(loRest.ResponseStatusCode), 16, "Server ANAF")
			    EndIf
			    *
			    Set Step On
			    Store .F. To ll_ANAF_Interogare_OK
				*RETURN .F.
			*ENDIF
		ENDIF 	
		*
		If Not ll_ANAF_Interogare_OK
			Set Step On
			Exit
		EndIf
		*
		IF lnPagina > lnPagini
			llBucla = .F.
		ENDIF 	
		*
	ENDDO 
	*
	If Not ll_ANAF_Interogare_OK
		Return .F.
	EndIf
	*
	ln_Cnt_Mesaje = RecCount("c_eFacturi_Mesaje")
	*
	If Type('ll_Is_ICAS')='U'
		Public ll_Is_ICAS
		ll_Is_ICAS = ( VarType(ICAS)='O' And Not IsNull(ICAS) ) And PemStatus(ICAS, 'oCfgSALARII', 5)
	EndIf
	*
	If Not ll_Is_ICAS
		*
		Text To lcSQL NoShow TextMerge
			Select
					Id_Solicitare
				,	Factura As NumarDoc
				,	Data_Doc As DataDoc
				,	'Iesiri' As Ecran
			From Docum
			Where
				Coalesce(Id_Solicitare, '')<>''
		EndText
		*
	Else
		*
		Text To lcSQL NoShow TextMerge
			Select
					Id_Solicitare
				,	NumarDoc
				,	DataDoc
				,	'Iesiri' As Ecran
			From Iesiri
			Where
				IsNull(Id_Solicitare, '')<>''
				And IsNull(Anulat, 0)=0
			Union All
			Select
					Id_Solicitare
				,	NumarDoc
				,	DataDoc
				,	'Export' As Ecran
			From Export
			Where
				IsNull(Id_Solicitare, '')<>''
				And IsNull(Anulat, 0)=0
		EndText
		*
	EndIf
	*
	mySQLExec(lcSQL, [crs_EFA_Depuse])
	__Consola( "cursor [crs_EFA_Depuse]" )
	*
	Update m;
	Set;
			Nr_Iesire	= f.NumarDoc;
		,	Data		= f.DataDoc;
		,	Ecran		= f.Ecran;
	From c_eFacturi_Mesaje m;
	Inner Join crs_EFA_Depuse f on f.Id_Solicitare=m.Id_Solicitare
	*
	__Consola( "Update m Set Nr_Iesire=f.NumarDoc, Data=f.DataDoc, Ecran= f.Ecran From c_eFacturi_Mesaje m Inner Join crs_EFA_Depuse f on f.Id_Solicitare=m.Id_Solicitare" )	
	Sec_End = Seconds()
	__Consola( "Au fost descarcate " + Transform(ln_Cnt_Mesaje)+ " mesaje. Procesul a durat: " + Transform(Sec_End-Sec_Start, "9 999.9999") )
EndProc	
* __________________________________________________________________________________________________________
Procedure InCursor_c_eFacturi_Mesaje(lcJSON)
	*
	Local loSetDate As Object
	loSetDate=CreateObject("SetDate", "YMD")
	*
	&& NU CUMVA aici ar trebui sa colecteze toate inregistrarile ?
	&& ???????????????????????????????????????????????????????????
	*
	*****	Use In Select('c_eFacturi_Mesaje')
	IF !USED("c_eFacturi_Mesaje")
		*Create Cursor c_Get_Mesaje_SPV;
			(;
			Data_R			T,;
			Id_Solicit		C(10),;
			Recipisa		C(10),;
			Detalii			C(250),;
			Tip				C(30),;
			CIF				C(13),;
			Id_Iesire		N(10, 0),;
			Nr_Iesire		C(20),;
			Data			D,;
			Cod				C(20),;
			Denumire		C(64),;
			Ecran			C(6),;
			PDF				M NOCPTRANS;
			)
		*Select Data_R, Id_Solicitare As Id_Solicit, Recipisa, Detalii, Tip, Cod_Fiscal As Cif, Id_Iesire, Nr_Iesire, Data, Ecran, Cod, Denumire, PDF From c_eFacturi_Mesaje Into Cursor c_Get_Mesaje_SPV_Tmp
		
		CREATE CURSOR c_eFacturi_Mesaje;
			(;
			ID C(20), Detalii C(100), Cod_Fiscal C(20), Data_R T, Id_Solicitare C(20);
			, Recipisa C (20);
			, Tip C(30), PDF M NOCPTRANS;
			, Id_Iesire N (10, 0), Nr_Iesire C (20), Data D, Ecran C (6);
			, Cod C (20), Denumire C (64), Procesat N (1), Preluat N (1);
			)
	*ELSE		Daca era deschis cursorul la comanda ZAP nu mai aveam nici o inregistrare
	*	SELECT c_eFacturi_Mesaje	
	*	IF ALIAS() = UPPER("c_eFacturi_Mesaje")
	*		ZAP
	*	ENDIF 
	ENDIF 
	*
	loListaMesaje = CreateObject('Chilkat_9_5_0.JsonArray')
	loListaMesaje.Load(lcJSON)
	*
	LOCAL lcTitlu, lcCnp, lcCui, lcSerial
	LOCAL i, j
	LOCAL lcId, lcDetalii, lcCif, lcData_creare, lcId_solicitare, lcTip
	*
	loJson = CreateObject('Chilkat_9_5_0.JsonObject')
	loJson.Load(lcJSON)
	*
	lcTitlu 	= loJson.StringOf("titlu")
	lcCnp 		= loJson.StringOf("cnp")
	lcCui 		= loJson.StringOf("cui")
	lcSerial 	= loJson.StringOf("serial")
	i 			= 0
	j 			= loJson.SizeOfArray("mesaje")
	*
	DO WHILE i < j
		*
		SELECT c_eFacturi_Mesaje
		SCATTER NAME loListaMesaje BLANK 
	    loJson.I = i
	    loListaMesaje.Id 			= loJson.StringOf("mesaje[i].id")			&& Recipisa
	    loListaMesaje.Recipisa		= loJson.StringOf("mesaje[i].id")
	    loListaMesaje.Detalii 		= loJson.StringOf("mesaje[i].detalii")
	    *loListaMesaje.Cif 			= loJson.StringOf("mesaje[i].cif")
	    loListaMesaje.Cod_Fiscal	= loJson.StringOf("mesaje[i].cif")
	    *loListaMesaje.Data_creare 	= loJson.StringOf("mesaje[i].data_creare")
	    *loListaMesaje.Data_R	 	= loJson.StringOf("mesaje[i].data_creare")
	    *loListaMesaje.Data_R	 	= SetDateGerman(loJson.StringOf("mesaje[i].data_creare"))
	    loListaMesaje.Data_R	 	= CToT( Transform(loJson.StringOf("mesaje[i].data_creare"), '@R 9999-99-99 99:99:99') )
	    loListaMesaje.Id_solicitare = loJson.StringOf("mesaje[i].id_solicitare")
	    loListaMesaje.Tip 			= loJson.StringOf("mesaje[i].tip")
	    *
	    INSERT INTO c_eFacturi_Mesaje FROM NAME loListaMesaje
	    *
	    i = i + 1
	    *
	ENDDO
	*
	lnPagini = VAL(loJson.StringOf("numar_total_pagini"))
	lnPagina = VAL(loJson.StringOf("index_pagina_curenta"))+1
	lnTotal  = VAL(loJson.StringOf("numar_total_inregistrari"))
	*
	__Consola('lnPagini	' + Transform(lnPagini) )	
	__Consola('lnPagina	' + Transform(lnPagina) )	
	__Consola('lnTotal	' + Transform(lnTotal) )	
	*
	lcEroare = loJson.StringOf("eroare")
	*
	IF TYPE("lcEroare") = "C"
		__Consola(lcEroare)
	ENDIF 
	*
EndProc	
* __________________________________________________________________________________________________________
Function eFactura_Parse(toXml)
	*
	If !Used("EFA_INVOICE_ANTET")
		*
		Create Cursor EFA_INVOICE_ANTET1(;
			AccountingCost														C(35),;	
			AdditionalDocumentReference_ID										C(35),;	
			AdditionalDocumentReference_Attachment_EmbeddedDocumentBinaryObject	M,;	
			AdditionalDocumentReference_Attachment_EmbeddedDocumentBinaryObject_mimeCode C(50),;	
			AdditionalDocumentReference_Attachment_EmbeddedDocumentBinaryObject_fileName C(50),;	
			AccountingSupplierParty_Party_PartyIdentification_ID				C(35),;
			AccountingSupplierParty_Party_PartyLegalEntity_CompanyID        	C(35),;
			AccountingSupplierParty_Party_PartyLegalEntity_CompanyLegalForm		C(35),;
			AccountingSupplierParty_Party_PartyLegalEntity_RegistrationName		C(70),;	
			AccountingSupplierParty_Party_PartyName_Name						C(70),;
			AccountingSupplierParty_Party_PartyTaxScheme_CompanyID_0			C(20),;
			AccountingSupplierParty_Party_PartyTaxScheme_CompanyID_1			C(20),;
			AccountingSupplierParty_Party_PartyTaxScheme_TaxScheme_Id_0			C(35),;
			AccountingSupplierParty_Party_PartyTaxScheme_TaxScheme_Id_1			C(35),;
			AccountingSupplierParty_Party_PostalAddress_CityName          		C(70),;
			AccountingSupplierParty_Party_PostalAddress_CountrySubentity    	C(35),;
			AccountingSupplierParty_Party_PostalAddress_IdentificationCode  	C(2),;
			AccountingSupplierParty_Party_PostalAddress_PostalZone          	C(20),;
			AccountingSupplierParty_Party_PostalAddress_StreetName          	C(70),;
			AccountingSupplierParty_Party_Contact_ElectronicMail            	C(35),;
			AccountingSupplierParty_Party_Contact_Name                      	C(70),;
			AccountingSupplierParty_Party_Contact_Telephone                 	C(35),;
			BillingReference_InvoiceDocumentReference_ID						C(35),;	
			BillingReference_InvoiceDocumentReference_IssueDate					C(10),;	
			BuyerReference                                     					C(35),;
			ContractDocumentReference_ID										C(35),;
			AccountingCustomerParty_Party_PartyIdentification_ID				C(35),;
			AccountingCustomerParty_Party_Contact_ElectronicMail				C(70),;
			AccountingCustomerParty_Party_Contact_Name							C(70),;
			AccountingCustomerParty_Party_Contact_Telephone                     C(35),;
			AccountingCustomerParty_Party_PostalAddress_CityName				C(70),;
			AccountingCustomerParty_Party_PostalAddress_CountrySubentity		C(70),;
			AccountingCustomerParty_Party_PostalAddress_IdentificationCode		C(70),;
			AccountingCustomerParty_Party_PostalAddress_PostalZone              C(20),;
			AccountingCustomerParty_Party_PostalAddress_StreetName              C(70),;
			AccountingCustomerParty_Party_PartyLegalEntity_CompanyID			C(35),;
			AccountingCustomerParty_Party_PartyLegalEntity_RegistrationName     C(70),;
			AccountingCustomerParty_Party_PartyName_Name                        C(70),;
			AccountingCustomerParty_Party_PartyTaxScheme_CompanyID              C(35),;
			AccountingCustomerParty_Party_PartyTaxScheme_TaxScheme_ID           C(35),;
			;
			PayeeParty_PartyIdentification_ID									C(35),;
			PayeeParty_PartyName_Name											C(70),;
			PayeeParty_PartyLegalEntity_CompanyID        						C(35),;
			;
			TaxRepresentativeParty_PartyName_Name								C(70),;
			TaxRepresentativeParty_PostalAddress_StreetName						C(70),;
			TaxRepresentativeParty_PostalAddress_CityName        		  		C(70),;
			TaxRepresentativeParty_PostalAddress_PostalZone        		  		C(20),;
			TaxRepresentativeParty_PostalAddress_CountrySubentity				C(35),;
			TaxRepresentativeParty_PostalAddress_Country_IdentificationCode		C(70),;
			TaxRepresentativeParty_PartyTaxScheme_CompanyID						C(35),;
			TaxRepresentativeParty_PartyTaxScheme_TaxScheme_ID					C(35),;
			;
			Delivery_ActualDeliveryDate											C(10),;
			Delivery_DeliveryLocation_Address_CityName							C(70),;
			Delivery_DeliveryLocation_Address_CountrySubentity					C(35),;
			Delivery_DeliveryLocation_Address_Country_IdentificationCode		C(2),;
			Delivery_DeliveryLocation_Address_PostalZone 						C(20),;
			Delivery_DeliveryLocation_Address_StreetName						C(70),;
			Delivery_DeliveryParty_PartyName_Name								C(70),;
			DespatchDocumentReference_ID										C(35),;
			DocumentCurrencyCode												C(3),;
			DueDate																C(10),;
			Id																	C(35),;
			InvoicePeriod_DescriptionCode										C(35),;	
			InvoiceTypeCode														C(3),;
			IssueDate															C(10),;
			LegalMonetaryTotal_LineExtensionAmount								C(35),;
			LegalMonetaryTotal_LineExtensionAmount_CurrencyId					C(3),;
			LegalMonetaryTotal_PayableAmount									C(35),;
			LegalMonetaryTotal_PayableAmount_CurrencyId							C(3),;
			LegalMonetaryTotal_TaxExclusiveAmount								C(35),;
			LegalMonetaryTotal_TaxExclusiveAmount_CurrencyId					C(3),;
			LegalMonetaryTotal_TaxInclusiveAmount								C(35),;
			LegalMonetaryTotal_TaxInclusiveAmount_CurrencyId					C(3);
			, Note																M(4),;
			OrderReference_ID													C(35),;
			OrderReference_SalesOrderID											C(35),;
			OriginatorDocumentReference_ID										C(35),;
			;
			PaymentMeans_CardAccount_HolderName									C(70),;
			PaymentMeans_CardAccount_NetworkID									C(35),;
			PaymentMeans_CardAccount_PrimaryAccountNumberID						C(35),;
			PaymentMeans_PayeeFinancialAccount_ID								C(35),;
			PaymentMeans_PayeeFinancialAccount_Name								C(70),;
			PaymentMeans_PayeeFinancialAccount_FinancialInstitutionBranch_ID	C(35),;
			PaymentMeans_PaymentID												C(35),;
			PaymentMeans_PaymentMandate_ID										C(35),;
			PaymentMeans_PaymentMandate_PayerFinancialAccount_ID				C(35),;
			PaymentMeans_PaymentMeansCode										C(35),;
			PaymentMeans_PaymentMeansCode_name									C(75),;
			;
			PaymentTerms_Note													M(4),;
			AllowanceCharge_ChargeIndicator										C(5),;
			AllowanceCharge_AllowanceChargeReason								C(35),;
			AllowanceCharge_Amount												C(35),;
			AllowanceCharge_Amount_CurrencyId									C(3),;
			AllowanceCharge_TaxCategory_ID_0									C(35),;
			AllowanceCharge_TaxCategory_ID_19									C(35),;
			AllowanceCharge_TaxCategory_ID_20									C(35),;
			AllowanceCharge_TaxCategory_ID_24									C(35),;
			AllowanceCharge_TaxCategory_ID_5									C(35),;
			AllowanceCharge_TaxCategory_ID_9									C(35),;
			AllowanceCharge_TaxCategory_Percent_0								C(5),;
			AllowanceCharge_TaxCategory_Percent_19								C(5),;
			AllowanceCharge_TaxCategory_Percent_20								C(5),;
			AllowanceCharge_TaxCategory_Percent_24								C(5),;
			AllowanceCharge_TaxCategory_Percent_5								C(5),;
			AllowanceCharge_TaxCategory_Percent_9								C(5),;
			AllowanceCharge_TaxCategory_TaxScheme_0                    		    C(3),;
			AllowanceCharge_TaxCategory_TaxScheme_19							C(3),;
			AllowanceCharge_TaxCategory_TaxScheme_20							C(3),;
			AllowanceCharge_TaxCategory_TaxScheme_24							C(3),;
			AllowanceCharge_TaxCategory_TaxScheme_5								C(3),;
			AllowanceCharge_TaxCategory_TaxScheme_9								C(3))
		*
*!*				TaxTotal_TaxAmount_EUR												C(35),;
*!*				TaxTotal_TaxAmount_CurrencyId_EUR									C(3),;
*!*				TaxTotal_TaxAmount_USD												C(35),;
*!*				TaxTotal_TaxAmount_CurrencyId_USD									C(3),;
*!*				TaxTotal_TaxAmount_GBP												C(35),;
*!*				TaxTotal_TaxAmount_CurrencyId_GBP									C(3),;
*!*				TaxTotal_TaxAmount_HUF												C(35),;
*!*				TaxTotal_TaxAmount_CurrencyId_HUF									C(3),;
		*
		Create Cursor EFA_INVOICE_ANTET2(;
			ProjectReference_ID													C(35),;
			ReceiptDocumentReference_ID											C(35),;
			TaxCurrencyCode														C(3),;
			TaxTotal_TaxAmount													C(35),;
			TaxTotal_TaxAmount_CurrencyId										C(3),;
			TaxTotal_TaxAmount_RON												C(35),;
			TaxTotal_TaxAmount_CurrencyId_RON									C(3),;
			TaxTotal_TaxSubtotal_TaxableAmount_CurrencyId_0						C(3),;
			TaxTotal_TaxSubtotal_TaxableAmount_CurrencyId_19					C(3),;
			TaxTotal_TaxSubtotal_TaxableAmount_CurrencyId_20					C(3),;
			TaxTotal_TaxSubtotal_TaxableAmount_CurrencyId_24					C(3),;
			TaxTotal_TaxSubtotal_TaxableAmount_CurrencyId_5						C(3),;
			TaxTotal_TaxSubtotal_TaxableAmount_CurrencyId_9						C(3),;
			TaxTotal_TaxSubtotal_TaxableAmount_0								C(35),;
			TaxTotal_TaxSubtotal_TaxableAmount_19								C(35),;
			TaxTotal_TaxSubtotal_TaxableAmount_20								C(35),;
			TaxTotal_TaxSubtotal_TaxableAmount_24								C(35),;
			TaxTotal_TaxSubtotal_TaxableAmount_5								C(35),;
			TaxTotal_TaxSubtotal_TaxableAmount_9								C(35),;
			TaxTotal_TaxSubtotal_TaxAmount_CurrencyId_0							C(3),;
			TaxTotal_TaxSubtotal_TaxAmount_CurrencyId_19						C(3),;
			TaxTotal_TaxSubtotal_TaxAmount_CurrencyId_20						C(3),;
			TaxTotal_TaxSubtotal_TaxAmount_CurrencyId_24						C(3),;
			TaxTotal_TaxSubtotal_TaxAmount_CurrencyId_5							C(3),;
			TaxTotal_TaxSubtotal_TaxAmount_CurrencyId_9							C(3),;
			TaxTotal_TaxSubtotal_TaxAmount_0									C(20),;
			TaxTotal_TaxSubtotal_TaxAmount_19									C(20),;
			TaxTotal_TaxSubtotal_TaxAmount_20									C(20),;
			TaxTotal_TaxSubtotal_TaxAmount_24									C(20),;
			TaxTotal_TaxSubtotal_TaxAmount_5									C(20),;
			TaxTotal_TaxSubtotal_TaxAmount_9									C(20),;
			TaxTotal_TaxSubtotal_TaxCategory_ID_0								C(35),;
			TaxTotal_TaxSubtotal_TaxCategory_ID_19								C(35),;
			TaxTotal_TaxSubtotal_TaxCategory_ID_20								C(35),;
			TaxTotal_TaxSubtotal_TaxCategory_ID_24								C(35),;
			TaxTotal_TaxSubtotal_TaxCategory_ID_5								C(35),;
			TaxTotal_TaxSubtotal_TaxCategory_ID_9								C(35),;
			TaxTotal_TaxSubtotal_TaxCategory_Percent_0							C(5),;
			TaxTotal_TaxSubtotal_TaxCategory_Percent_19							C(5),;
			TaxTotal_TaxSubtotal_TaxCategory_Percent_20							C(5),;
			TaxTotal_TaxSubtotal_TaxCategory_Percent_24							C(5),;
			TaxTotal_TaxSubtotal_TaxCategory_Percent_5							C(5),;
			TaxTotal_TaxSubtotal_TaxCategory_Percent_9							C(5),;
			TaxTotal_TaxSubtotal_TaxCategory_TaxExemptionReason_0				C(70),;
			TaxTotal_TaxSubtotal_TaxCategory_TaxExemptionReason_19				C(70),;
			TaxTotal_TaxSubtotal_TaxCategory_TaxExemptionReason_20				C(70),;
			TaxTotal_TaxSubtotal_TaxCategory_TaxExemptionReason_24				C(70),;
			TaxTotal_TaxSubtotal_TaxCategory_TaxExemptionReason_5				C(70),;
			TaxTotal_TaxSubtotal_TaxCategory_TaxExemptionReason_9				C(70),;
			TaxTotal_TaxSubtotal_TaxCategory_TaxExemptionReasonCode_0			C(70),;
			TaxTotal_TaxSubtotal_TaxCategory_TaxExemptionReasonCode_19			C(70),;
			TaxTotal_TaxSubtotal_TaxCategory_TaxExemptionReasonCode_20			C(70),;
			TaxTotal_TaxSubtotal_TaxCategory_TaxExemptionReasonCode_24			C(70),;
			TaxTotal_TaxSubtotal_TaxCategory_TaxExemptionReasonCode_5			C(70),;
			TaxTotal_TaxSubtotal_TaxCategory_TaxExemptionReasonCode_9			C(70),;
			TaxTotal_TaxSubtotal_TaxCategory_TaxScheme_0                        C(3),;
			TaxTotal_TaxSubtotal_TaxCategory_TaxScheme_19                       C(3),;
			TaxTotal_TaxSubtotal_TaxCategory_TaxScheme_20                       C(3),;
			TaxTotal_TaxSubtotal_TaxCategory_TaxScheme_24                       C(3),;
			TaxTotal_TaxSubtotal_TaxCategory_TaxScheme_5                        C(3),;
			TaxTotal_TaxSubtotal_TaxCategory_TaxScheme_9                        C(3))
		*
		Select * From EFA_INVOICE_ANTET1, EFA_INVOICE_ANTET2 Into cursor EFA_INVOICE_ANTET READWRITE
		
		#if .f.
<?xml version="1.0" encoding="UTF-8"?>
<Invoice xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" xmlns:qdt="urn:oasis:names:specification:ubl:schema:xsd:QualifiedDataTypes-2" xmlns:udt="urn:oasis:names:specification:ubl:schema:xsd:UnqualifiedDataTypes-2" xmlns:ccts="urn:un:unece:uncefact:documentation:2" xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2 http://docs.oasis-open.org/ubl/os-UBL-2.1/xsd/maindoc/UBL-Invoice-2.1.xsd">
	<CustomizationID>urn:cen.eu:en16931:2017#compliant#urn:efactura.mfinante.ro:CIUS-RO:1.0.1</CustomizationID>
	<ProfileID>1</ProfileID>
	<!--BT-1-->
	<ID>DCN1-R2 2505965</ID>
	<!--BT-2-->
	<IssueDate>2024-02-16</IssueDate>
	<!--BT-9-->
	<DueDate>2024-02-16</DueDate>
	<!--BT-3-->
	<InvoiceTypeCode>380</InvoiceTypeCode>
	<!--BT-5-->
	<DocumentCurrencyCode>RON</DocumentCurrencyCode>
	<!--BT-6-->
	<TaxCurrencyCode>RON</TaxCurrencyCode>
	<InvoicePeriod><!--BT-73-->
		<StartDate>2024-02-16</StartDate>
		<!--BT-74-->
		<EndDate>2024-02-16</EndDate>
		<DescriptionCode>3</DescriptionCode>
	</InvoicePeriod>
	<AccountingSupplierParty>
		<Party>
			<EndpointID schemeID="EM">office@kontas.ro</EndpointID>
			<PartyIdentification>
				<ID schemeID="0206">J23/60/14.01.2014</ID>
			</PartyIdentification>
			<PartyName><!--BT-28-->
				<Name>DCN EU RETAIL SRL</Name>
			</PartyName>
			<PostalAddress><!--BT-35-->
				<StreetName>Sos. Bucuresti-Urziceni 16, P7 Nr.A33</StreetName>
				<!--BT-37-->
				<CityName>AFUMATI</CityName>
				<!--BT-39-->
				<CountrySubentity>RO-IF</CountrySubentity>
				<Country><!--BT-40-->
					<IdentificationCode>RO</IdentificationCode>
				</Country>
			</PostalAddress>
			<PartyTaxScheme><!--BT-31-->
				<CompanyID>RO32648575</CompanyID>
				<TaxScheme>
					<ID>VAT</ID>
				</TaxScheme>
			</PartyTaxScheme>
			<PartyLegalEntity><!--BT-27-->
				<RegistrationName>DCN EU RETAIL SRL</RegistrationName>
				<!--BT-30  -->
				<CompanyID schemeID="0210">RO32648575</CompanyID>
				<CompanyLegalForm>J23/60/14.01.2014</CompanyLegalForm>
			</PartyLegalEntity>
			<Contact><!--BT-41-->
				<Name>Moldoveanu  Laurentiu</Name>
				<Telephone>0756036060</Telephone>
				<ElectronicMail>Laurentiu.moldoveanu@dcneu.ro</ElectronicMail>
			</Contact>
		</Party>
	</AccountingSupplierParty>
	<AccountingCustomerParty>
		<Party>
			<PartyIdentification>
				<ID schemeID="0206">J51/446/2003</ID>
			</PartyIdentification>
			<PartyName><!--BT-45-->
				<Name>Expert Software Company S.R.L.</Name>
			</PartyName>
			<PostalAddress><!--BT-50-->
				<StreetName>ARGESULUI Nr. 52 58</StreetName>
				<!--BT-52-->
				<CityName>OLTENITA</CityName>
				<!--BT-54-->
				<CountrySubentity>RO-CL</CountrySubentity>
				<Country><!--BT-55-->
					<IdentificationCode>RO</IdentificationCode>
				</Country>
			</PostalAddress>
			<PartyTaxScheme><!--BT-48-->
				<CompanyID>RO14916343</CompanyID>
				<TaxScheme>
					<ID>VAT</ID>
				</TaxScheme>
			</PartyTaxScheme>
			<PartyLegalEntity>
				<RegistrationName>Expert Software Company S.R.L.</RegistrationName>
				<CompanyID schemeID="0210">RO14916343</CompanyID>
			</PartyLegalEntity>
		</Party>
	</AccountingCustomerParty>
	<Delivery><!--BT-72-->
		<ActualDeliveryDate>2024-02-16</ActualDeliveryDate>
		<DeliveryLocation><!--BT-71-->
			<ID schemeID="0088">100629</ID>
			<Address><!--BT-75-->
				<StreetName>ARGESULUI Nr. 52 58</StreetName>
				<!--BT-77-->
				<CityName>OLTENITA</CityName>
				<!--BT-79-->
				<CountrySubentity>RO-CL</CountrySubentity>
				<Country><!--BT-80-->
					<IdentificationCode>RO</IdentificationCode>
				</Country>
			</Address>
		</DeliveryLocation>
		<DeliveryParty>
			<PartyName><!--BT-70-->
				<Name>Expert Software Company S.R.L.</Name>
			</PartyName>
		</DeliveryParty>
	</Delivery>
	<PaymentMeans><!--BT-81-->
		<PaymentMeansCode name="Mutually defined">ZZZ</PaymentMeansCode>
		<PayeeFinancialAccount><!--BT-84-->
			<ID>RO48BTRLRONCRT0242136401</ID>
		</PayeeFinancialAccount>
	</PaymentMeans>
	<PaymentTerms><!--BT-20-->
		<Note>100% 16.02.2024;</Note>
	</PaymentTerms>
    <AllowanceCharge>															<!--BG-20-->
        <ChargeIndicator>false</ChargeIndicator>
        <AllowanceChargeReason>Discount factura</AllowanceChargeReason>		<!--BT-97-->Motivul deducerii la nivelul documentului
        <Amount currencyID="RON">506.40</Amount>							<!--BT-92-->Valoarea  deducerilor la nivelul documentului
        <TaxCategory>
            <ID>S</ID>														<!--BT-95-->Codul categoriei de TVA pentru deduceri la nivelul doc
            <Percent>19.00</Percent>										<!--BT-96-->Cota de TVA pentru deduceri la nivelul documentului
            <TaxScheme>
                <ID>VAT</ID>
            </TaxScheme>
        </TaxCategory>
    </AllowanceCharge>
	<TaxTotal><!--BT-111-->
		<TaxAmount currencyID="RON">47.75</TaxAmount>
		<TaxSubtotal><!--BT-116-->
			<TaxableAmount currencyID="RON">251.35</TaxableAmount>
			<!--BT-117-->
			<TaxAmount currencyID="RON">47.75</TaxAmount>
			<TaxCategory><!--BT-118-->
				<ID>S</ID>
				<!--BT-119-->
				<Percent>19</Percent>
				<TaxScheme>
					<ID>VAT</ID>
				</TaxScheme>
			</TaxCategory>
		</TaxSubtotal>
	</TaxTotal>
	<LegalMonetaryTotal><!--BT-106-->
		<LineExtensionAmount currencyID="RON">251.35</LineExtensionAmount>
		<!--BT-109-->
		<TaxExclusiveAmount currencyID="RON">251.35</TaxExclusiveAmount>
		<!--BT-112-->
		<TaxInclusiveAmount currencyID="RON">299.1</TaxInclusiveAmount>
		<!--BT-107-->
		<AllowanceTotalAmount currencyID="RON">0</AllowanceTotalAmount>
		<!--BT-108-->
		<ChargeTotalAmount currencyID="RON">0</ChargeTotalAmount>
		<!--BT-113-->
		<PrepaidAmount currencyID="RON">0</PrepaidAmount>
		<!--BT-114-->
		<PayableRoundingAmount currencyID="RON">0</PayableRoundingAmount>
		<!--BT-115-->
		<PayableAmount currencyID="RON">299.1</PayableAmount>
	</LegalMonetaryTotal>
	<InvoiceLine><!--BT-126-->
		<ID>2</ID>
		<!--BT-129 BT-130-->
		<InvoicedQuantity unitCode="XPP">1</InvoicedQuantity>
		<!--BT-131-->
		<LineExtensionAmount currencyID="RON">20.16</LineExtensionAmount>
		<Item><!--BT-153-->
			<Name>SENZA CASETA CADOU (SPUMANT1L+SG500+SAP300) ARGAN</Name>
			<SellersItemIdentification>
				<ID>5949033015351</ID>
			</SellersItemIdentification>
			<StandardItemIdentification>
				<ID schemeID="0005">5949033015351</ID>
			</StandardItemIdentification>
			<OriginCountry><!--BT-159-->
				<IdentificationCode>RO</IdentificationCode>
			</OriginCountry>
			<CommodityClassification>
				<ItemClassificationCode listID="TSP">5949033015351</ItemClassificationCode>
			</CommodityClassification>
			<ClassifiedTaxCategory><!--BT-151-->
				<ID>S</ID>
				<!--BT-152-->
				<Percent>19</Percent>
				<TaxScheme>
					<ID>VAT</ID>
				</TaxScheme>
			</ClassifiedTaxCategory>
		</Item>
		<Price><!--BT-146-->
			<PriceAmount currencyID="RON">20.164</PriceAmount>
			<!--BT-149 BT-150-->
			<BaseQuantity unitCode="XPP">1</BaseQuantity>
		</Price>
	</InvoiceLine>
	<InvoiceLine><!--BT-126-->
		<ID>1</ID>
		<!--BT-129 BT-130-->
		<InvoicedQuantity unitCode="XPP">1</InvoicedQuantity>
		<!--BT-131-->
		<LineExtensionAmount currencyID="RON">15.81</LineExtensionAmount>
		<Item><!--BT-153-->
			<Name>SET 4 CESTI CAFEA CU SUPORT WEI A-12815</Name>
			<BuyersItemIdentification>
				<ID>570624 - 435/50R19.5 160J 3PSF</ID>
			</BuyersItemIdentification>
			<SellersItemIdentification>
				<ID>2015518128151</ID>
			</SellersItemIdentification>
			<StandardItemIdentification>
				<ID schemeID="0005">2015518128151</ID>
			</StandardItemIdentification>
			<StandardItemIdentification>
				<ID schemeID="0160">5940000001148</ID>
			</StandardItemIdentification>
			<CommodityClassification>
				<ItemClassificationCode listID="EN">5940000001148</ItemClassificationCode>
			</CommodityClassification>
			<CommodityClassification>
				<ItemClassificationCode listID="TSP">22021000</ItemClassificationCode>
			</CommodityClassification>
            <CommodityClassification>
            	<ItemClassificationCode listID="STI">87089997</ItemClassificationCode>
            </CommodityClassification>
            <CommodityClassification>
            	<ItemClassificationCode listID="STI" listVersionID="2022">64200000-8</ItemClassificationCode>
            </CommodityClassification>
			<OriginCountry><!--BT-159-->
				<IdentificationCode>RO</IdentificationCode>
			</OriginCountry>
			<ClassifiedTaxCategory><!--BT-151-->
				<ID>S</ID>
				<!--BT-152-->
				<Percent>19</Percent>
				<TaxScheme>
					<ID>VAT</ID>
				</TaxScheme>
			</ClassifiedTaxCategory>
		</Item>
		<Price><!--BT-146-->
			<PriceAmount currencyID="RON">15.81</PriceAmount>
			<!--BT-149 BT-150-->
			<BaseQuantity unitCode="XPP">1</BaseQuantity>
		</Price>
	</InvoiceLine>
</Invoice>
		#endif
		Create Cursor EFA_INVOICE_LINII(;
			ID											C(35);
			, Note										M,;
			InvoicedQuantity_UnitCode					C(5),;
			InvoicedQuantity							C(35),;
			LineExtensionAmount_CurrencyId				C(3),;
			LineExtensionAmount							C(35),;
			AccountingCost								C(35),;
			InvoicePeriod_StartDate						C(10),;
			InvoicePeriod_EndDate						C(10),;
			AllowanceCharge_ChargeIndicator				C(10),;
			AllowanceCharge_AllowanceChargeReasonCode	C(35),;
			AllowanceCharge_AllowanceChargeReason		C(35),;
			AllowanceCharge_MultiplierFactorNumeric		C(35),;
			AllowanceCharge_Amount_CurrencyId			C(3),;
			AllowanceCharge_Amount						C(35),;
			AllowanceCharge_BaseAmount_CurrencyId		C(3),;
			AllowanceCharge_BaseAmount					C(35),;
			Item_Description							C(70),;
			Item_Name									C(70),;
			Item_ClassifiedTaxCategory_ID				C(70),;
			Item_ClassifiedTaxCategory_Percent			C(35),;
			Item_ClassifiedTaxCategory_TaxScheme_ID		C(35),;
			Item_AdditionalItemProperty_Name			C(70),;
			Item_AdditionalItemProperty_Value			C(70),;
			Price_PriceAmount_CurrencyId				C(3),;
			Price_PriceAmount							C(35),;
			Price_BaseQuantity_UnitCode					C(5),;
			Price_BaseQuantity							C(35),;
			Price_AllowanceCharge_ChargeIndicator		C(35),;
			Price_AllowanceCharge_Amount_CurrencyId		C(3),;
			Price_AllowanceCharge_Amount				C(35),;
			Price_AllowanceCharge_BaseAmount_CurrencyId	C(3),;
			Price_AllowanceCharge_BaseAmount			C(35);
			, CodBARE									C(13);
			, codNC										C(13);
			, codCPV									C(13);
			, codFurnizor								C(13);
			)
		*
		Create Cursor EFA_INVOICE_TAXE(;
			AllowanceCharge_ChargeIndicator				C(10),;
			AllowanceCharge_Amount						C(35),;
			AllowanceCharge_Amount_CurrencyId			C(3) ,;
			AllowanceCharge_BaseAmount					C(35),;
			AllowanceCharge_BaseAmount_CurrencyId		C(3) ,;
			AllowanceCharge_MultiplierFactorNumeric		C(35),;
			AllowanceCharge_TaxCategory_Percent         C(5) ,;
			AllowanceCharge_AllowanceChargeReason		C(35),;			
			AllowanceCharge_AllowanceChargeReasonCode	C(35) ;
			)
		*		
	Else
		*
		Select EFA_INVOICE_ANTET	
		If Alias() = Upper("EFA_INVOICE_ANTET")
			Zap In Select("EFA_INVOICE_ANTET")
		EndIf
		*
		Select EFA_INVOICE_LINII	
		If Alias() = Upper("EFA_INVOICE_LINII")
			Zap In Select("EFA_INVOICE_LINII")
		EndIf
		*
		Select EFA_INVOICE_TAXE	
		If Alias() = Upper("EFA_INVOICE_TAXE")
			Zap In Select("EFA_INVOICE_TAXE")
		EndIf
		*
	EndIf
	*
	Local i As Integer, j As Integer, k As Integer
	*
	loXML = toXml
	Select EFA_INVOICE_LINII
	Scatter Name oEFA_L Blank Memo
	Select EFA_INVOICE_ANTET
	Scatter Name oEFA Blank Memo
	Select EFA_INVOICE_TAXE
	Scatter Name oEFA_T Blank Memo
	*
	With loXml
		m.oEFA.Id																= .GetChildContent("*:ID")						&& Numar Factura
		*lcCbc_ID																= .GetChildWithTag("*:ID").Content
		*
		m.oEFA.IssueDate														= .GetChildContent("*:IssueDate")																					&& Data Facturii
		m.oEFA.DueDate															= .GetChildContent("*:DueDate")																					&& Scadenta
		m.oEFA.InvoiceTypeCode													= .GetChildContent("*:InvoiceTypeCode")																			&& Cod Tip Factura
		If IsNullOrEmpty(m.oEFA.InvoiceTypeCode)
			m.oEFA.InvoiceTypeCode												= .GetChildContent("*:CreditNoteTypeCode")																			&& Cod Tip Factura
		EndIf
		i = 0
		*m.oEFA.Note															= .GetChildContent("*:Note")																						&& Comentarii Factura
		Store '' To lcCbc_Note
		lnCount_i = loXml.NumChildrenHavingTag("*:Note")
		DO WHILE i < lnCount_i
		    loXml.I = i
		    lcCbc_Note = lcCbc_Note + Chr(13)+loXml.GetChildContent("*:Note[i]")
		    i = i + 1
		ENDDO		
		m.oEFA.Note																= lcCbc_Note																										&& Comentarii Factura
        ***	ll_IsTvaIncasare = "TVA"$UPPER(m.oEFA.Note) .AND. ("INCASARE"$UPPER(m.oEFA.Note) .OR. "�NCASARE"$UPPER(m.oEFA.Note))		
		m.oEFA.DocumentCurrencyCode												= .GetChildContent("*:DocumentCurrencyCode")																		&& Moneda
		m.oEFA.TaxCurrencyCode													= .GetChildContent("*:TaxCurrencyCode")																			&& Moneda Tva
		m.oEFA.AccountingCost													= .GetChildContent("*:AccountingCost")
		m.oEFA.BuyerReference 													= .GetChildContent("*:BuyerReference")
		m.oEFA.InvoicePeriod_DescriptionCode 									= .GetChildContent("*:InvoicePeriod|*:DescriptionCode")
		m.oEFA.OrderReference_ID												= .GetChildContent("*:OrderReference|*:ID")
		m.oEFA.OrderReference_SalesOrderID										= .GetChildContent("*:OrderReference|*:SalesOrderID")
		m.oEFA.BillingReference_InvoiceDocumentReference_ID						= .GetChildContent("*:BillingReference|*:InvoiceDocumentReference|*:ID")
		m.oEFA.BillingReference_InvoiceDocumentReference_IssueDate				= .GetChildContent("*:BillingReference|*:InvoiceDocumentReference|*:IssueDate")
		m.oEFA.DespatchDocumentReference_ID										= .GetChildContent("*:DespatchDocumentReference|*:ID")
		m.oEFA.ReceiptDocumentReference_ID										= .GetChildContent("*:ReceiptDocumentReference|*:ID")
		m.oEFA.OriginatorDocumentReference_ID									= .GetChildContent("*:OriginatorDocumentReference|*:ID")
		m.oEFA.ContractDocumentReference_ID										= .GetChildContent("*:ContractDocumentReference|*:ID")
		&& Attachment
		m.oEFA.AdditionalDocumentReference_ID												= .GetChildContent("*:AdditionalDocumentReference|*:ID")
		m.oEFA.AdditionalDocumentReference_Attachment_EmbeddedDocumentBinaryObject			= .GetChildContent("*:AdditionalDocumentReference|*:Attachment|*:EmbeddedDocumentBinaryObject")
		m.oEFA.AdditionalDocumentReference_Attachment_EmbeddedDocumentBinaryObject_mimeCode	= .ChilkatPath	  ("*:AdditionalDocumentReference|*:Attachment|*:EmbeddedDocumentBinaryObject|(mimeCode)")
		m.oEFA.AdditionalDocumentReference_Attachment_EmbeddedDocumentBinaryObject_filename	= .ChilkatPath	  ("*:AdditionalDocumentReference|*:Attachment|*:EmbeddedDocumentBinaryObject|(filename)")
		
		m.oEFA.ProjectReference_ID												= .GetChildContent("*:ProjectReference|*:ID")
		*____________________________________________________ AccountingSupplierParty - FURNIZOR _______________________________________________________________
		*lcCbc_Supplier_EndpointID_schemeID										= .ChilkatPath("*:AccountingSupplierParty|*:Party|*:EndpointID|(schemeID)")
		m.oEFA.AccountingSupplierParty_Party_PartyName_Name						= .GetChildContent("*:AccountingSupplierParty|*:Party|*:PartyName|*:Name")
		*/Invoice/cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID
		m.oEFA.AccountingSupplierParty_Party_PartyIdentification_ID				= .GetChildContent("*:AccountingSupplierParty|*:Party|*:PartyIdentification|*:ID")
		
		*
		&& - PostalAddress
		*
		m.oEFA.AccountingSupplierParty_Party_PostalAddress_StreetName			= .GetChildContent("*:AccountingSupplierParty|*:Party|*:PostalAddress|*:StreetName")						&& :Stada
		m.oEFA.AccountingSupplierParty_Party_PostalAddress_CityName				= .GetChildContent("*:AccountingSupplierParty|*:Party|*:PostalAddress|*:CityName")							&& :Oras
		m.oEFA.AccountingSupplierParty_Party_PostalAddress_PostalZone			= .GetChildContent("*:AccountingSupplierParty|*:Party|*:PostalAddress|*:PostalZone")						&& Cod Postal
		m.oEFA.AccountingSupplierParty_Party_PostalAddress_CountrySubentity		= .GetChildContent("*:AccountingSupplierParty|*:Party|*:PostalAddress|*:CountrySubentity")					&& :Judet
		m.oEFA.AccountingSupplierParty_Party_PostalAddress_IdentificationCode	= .GetChildContent("*:AccountingSupplierParty|*:Party|*:PostalAddress|*:Country|*:IdentificationCode")	&& :Tara
		*
		&& - PartyLegalEntity
		*
		m.oEFA.AccountingSupplierParty_Party_PartyLegalEntity_CompanyID			= .GetChildContent("*:AccountingSupplierParty|*:Party|*:PartyLegalEntity|*:CompanyID")
		m.oEFA.AccountingSupplierParty_Party_PartyLegalEntity_CompanyLegalForm 	= .GetChildContent("*:AccountingSupplierParty|*:Party|*:PartyLegalEntity|*:CompanyLegalForm")
		m.oEFA.AccountingSupplierParty_Party_PartyLegalEntity_RegistrationName	= .GetChildContent("*:AccountingSupplierParty|*:Party|*:PartyLegalEntity|*:RegistrationName")				&& : Denumire
		*
		&& - TaxRepresentativeParty
		lcCbc_Name					= .GetChildContent("*:TaxRepresentativeParty|*:PartyName|*:Name")
		lcCbc_StreetName			= .GetChildContent("*:TaxRepresentativeParty|*:PostalAddress|*:StreetName")
		lcCbc_CityName				= .GetChildContent("*:TaxRepresentativeParty|*:PostalAddress|*:CityName")
		lcCbc_PostalZone			= .GetChildContent("*:TaxRepresentativeParty|*:PostalAddress|*:PostalZone")
		lcCbc_CountrySubentity		= .GetChildContent("*:TaxRepresentativeParty|*:PostalAddress|*:CountrySubentity")
		lcCbc_IdentificationCode	= .GetChildContent("*:TaxRepresentativeParty|*:PostalAddress|*:Country|*:IdentificationCode")
		lcCbc_CompanyID				= .GetChildContent("*:TaxRepresentativeParty|*:PartyTaxScheme|*:CompanyID")
		lcCbc_ID					= .GetChildContent("*:TaxRepresentativeParty|*:PartyTaxScheme|*:TaxScheme|*:ID")

		&& - Contact
		*
		m.oEFA.AccountingSupplierParty_Party_Contact_Name						= .GetChildContent("*:AccountingSupplierParty|*:Party|*:Contact|*:Name")									&& Nume+Prenume persoana autorizata
		m.oEFA.AccountingSupplierParty_Party_Contact_Telephone					= .GetChildContent("*:AccountingSupplierParty|*:Party|*:Contact|*:Telephone")								&& : Telefon
		m.oEFA.AccountingSupplierParty_Party_Contact_ElectronicMail				= .GetChildContent("*:AccountingSupplierParty|*:Party|*:Contact|*:ElectronicMail")							&& : Mail
		*
		&& - PartyTaxScheme
		*
		*If IsNullOrEmpty(m.oEFA.Supplier_Id) Or Not VerifCF(m.oEFA.Supplier_Id)
		*
		lnCount_i = .NumChildrenHavingTag("*:AccountingSupplierParty|*:Party|*:PartyTaxScheme")
		For i = 0 To lnCount_i -1
			.i = i
			lcSuffix = AllTrim(Str(i))
			lcVar_Supplier_PartyTaxScheme_CompanyID		= "m.oEFA.AccountingSupplierParty_Party_PartyTaxScheme_CompanyID_"+lcSuffix
			&lcVar_Supplier_PartyTaxScheme_CompanyID	= .GetChildContent("*:AccountingSupplierParty|*:Party|*:PartyTaxScheme[i]|*:CompanyID")
			lcVar_Supplier_TaxScheme_ID					= "m.oEFA.AccountingSupplierParty_Party_PartyTaxScheme_TaxScheme_Id_"+lcSuffix
			&lcVar_Supplier_TaxScheme_ID				= .GetChildContent("*:AccountingSupplierParty|*:Party|*:PartyTaxScheme[i]|*:TaxScheme|*:ID")
		Next
		*______________________________________________________________ AccountingCustomerParty CLIENT _________________________________________________________
		*
		*	-	 Party
		*
		*If IsNullOrEmpty(m.oEFA.Customer_Id)
		
		&& 06.08.2024
		m.oEFA.AccountingCustomerParty_Party_PartyIdentification_ID				= .GetChildContent("*:AccountingCustomerParty|*:Party|*:PartyIdentification|*:ID")
		&& 06.08.2024
		
		m.oEFA.AccountingCustomerParty_Party_PartyName_Name						= .GetChildContent("*:AccountingCustomerParty|*:Party|*:PartyName|*:Name")
		*
		*	- ADRESA
		*
		m.oEFA.AccountingCustomerParty_Party_PostalAddress_StreetName			= .GetChildContent("*:AccountingCustomerParty|*:Party|*:PostalAddress|*:StreetName")						&& Strada
		m.oEFA.AccountingCustomerParty_Party_PostalAddress_CityName				= .GetChildContent("*:AccountingCustomerParty|*:Party|*:PostalAddress|*:CityName")							&& Oras
		m.oEFA.AccountingCustomerParty_Party_PostalAddress_PostalZone			= .GetChildContent("*:AccountingCustomerParty|*:Party|*:PostalAddress|*:PostalZone")
		m.oEFA.AccountingCustomerParty_Party_PostalAddress_CountrySubentity		= .GetChildContent("*:AccountingCustomerParty|*:Party|*:PostalAddress|*:CountrySubentity")					&& Judet
		m.oEFA.AccountingCustomerParty_Party_PostalAddress_IdentificationCode	= .GetChildContent("*:AccountingCustomerParty|*:Party|*:PostalAddress|*:Country|*:IdentificationCode")		&& Tara
		*
		*	- PartyTaxScheme
		*
		m.oEFA.AccountingCustomerParty_Party_PartyTaxScheme_CompanyID  			= .GetChildContent("*:AccountingCustomerParty|*:Party|*:PartyTaxScheme|*:CompanyID")						&& RO+CIF
		m.oEFA.AccountingCustomerParty_Party_PartyTaxScheme_TaxScheme_ID		= .GetChildContent("*:AccountingCustomerParty|*:Party|*:PartyTaxScheme|*:TaxScheme|*:ID")					&& VAT ID
		*
		*	- PayeeParty
		*
		m.oEFA.PayeeParty_PartyIdentification_ID  								= .GetChildContent("*:PayeeParty|*:PartyIdentification|*:ID")
		m.oEFA.PayeeParty_PartyName_Name		 								= .GetChildContent("*:PayeeParty|*:PartyName|*:Name")
		m.oEFA.PayeeParty_PartyLegalEntity_CompanyID							= .GetChildContent("*:PayeeParty|*:PartyLegalEntity|*:CompanyID")

		*
		*	- TaxRepresentativeParty
		*
		m.oEFA.TaxRepresentativeParty_PartyName_Name		 					= .GetChildContent("*:TaxRepresentativeParty|*:PartyName|*:Name")
		m.oEFA.TaxRepresentativeParty_PostalAddress_StreetName					= .GetChildContent("*:TaxRepresentativeParty|*:PostalAddress|*:StreetName")
		m.oEFA.TaxRepresentativeParty_PostalAddress_CityName					= .GetChildContent("*:TaxRepresentativeParty|*:PostalAddress|*:CityName")
		m.oEFA.TaxRepresentativeParty_PostalAddress_PostalZone					= .GetChildContent("*:TaxRepresentativeParty|*:PostalAddress|*:PostalZone")
		m.oEFA.TaxRepresentativeParty_PostalAddress_CountrySubentity			= .GetChildContent("*:TaxRepresentativeParty|*:PostalAddress|*:CountrySubentity")
		m.oEFA.TaxRepresentativeParty_PostalAddress_Country_IdentificationCode	= .GetChildContent("*:TaxRepresentativeParty|*:PostalAddress|*:Country|*:IdentificationCode")
		m.oEFA.TaxRepresentativeParty_PartyTaxScheme_CompanyID					= .GetChildContent("*:TaxRepresentativeParty|*:PartyTaxScheme|*:CompanyID")
		m.oEFA.TaxRepresentativeParty_PartyTaxScheme_TaxScheme_ID				= .GetChildContent("*:TaxRepresentativeParty|*:PartyTaxScheme|*:TaxScheme|*:ID")
		*
		*	- CONTACT
		*
		m.oEFA.AccountingCustomerParty_Party_Contact_Name						= .GetChildContent("*:AccountingCustomerParty|*:Party|*:Contact|*:Name")
		m.oEFA.AccountingCustomerParty_Party_Contact_Telephone					= .GetChildContent("*:AccountingCustomerParty|*:Party|*:Contact|*:Telephone")
		m.oEFA.AccountingCustomerParty_Party_Contact_ElectronicMail				= .GetChildContent("*:AccountingCustomerParty|*:Party|*:Contact|*:ElectronicMail")
		*
		*	- PartyLegalEntity
		*
		m.oEFA.AccountingCustomerParty_Party_PartyLegalEntity_CompanyID			= .GetChildContent("*:AccountingCustomerParty|*:Party|*:PartyLegalEntity|*:CompanyID")
		m.oEFA.AccountingCustomerParty_Party_PartyLegalEntity_RegistrationName	= .GetChildContent("*:AccountingCustomerParty|*:Party|*:PartyLegalEntity|*:RegistrationName")
		m.oEFA.AccountingCustomerParty_Party_PartyLegalEntity_CompanyID			= .GetChildContent("*:AccountingCustomerParty|*:Party|*:PartyLegalEntity|*:CompanyID")						&& RO + CIF
		*_______________________________________________________________________________________________________________________________________________________
		*
		&&	- TaxAmount
		*
		&& 12.08.2024
		*
*!*			m.oEFA.TaxTotal_TaxAmount												= .GetChildContent("*:TaxTotal|*:TaxAmount")
*!*			m.oEFA.TaxTotal_TaxAmount_CurrencyId 									= .ChilkatPath("*:TaxTotal|*:TaxAmount|(currencyID)")
		*
		lnCount_i = .NumChildrenHavingTag("*:TaxTotal")
		*
		For i = 0 To lnCount_i - 1
		    .I = i
			lcMoneda = .ChilkatPath("*:TaxTotal[i]|*:TaxAmount|(currencyID)")
			lcSuffix = Iif(InList(lcMoneda, 'RON', 'LEI'), '_'+lcMoneda, '')
			*
		    lcVar_TaxTotal_TaxAmount				= "m.oEFA.TaxTotal_TaxAmount"					+ lcSuffix
		    &lcVar_TaxTotal_TaxAmount				= .GetChildContent("*:TaxTotal[i]|*:TaxAmount")
		    
		    lcVar_TaxTotal_TaxAmount_CurrencyId		= "m.oEFA.TaxTotal_TaxAmount_CurrencyId"		+ lcSuffix
		    &lcVar_TaxTotal_TaxAmount_CurrencyId	= lcMoneda
		NEXT
		*
		&& 12.08.2024
		*
		* Recursive  <TaxTotal>
		*
		*i = 0
		lnCount_i = .NumChildrenHavingTag("*:TaxTotal|*:TaxSubtotal")
		*
		For i = 0 To lnCount_i - 1
			.i = i
			lcCbc_TaxTotal_TaxSubtotal_TaxableAmount_CurrencyId					= .ChilkatPath	  ("*:TaxTotal|*:TaxSubtotal[i]|*:TaxableAmount|(currencyID)")
			lcCbc_TaxTotal_TaxSubtotal_TaxableAmount							= .GetChildContent("*:TaxTotal|*:TaxSubtotal[i]|*:TaxableAmount")
			lcCbc_TaxTotal_TaxSubtotal_TaxAmount_CurrencyId						= .ChilkatPath	  ("*:TaxTotal|*:TaxSubtotal[i]|*:TaxAmount|(currencyID)")
			lcCbc_TaxTotal_TaxSubtotal_TaxAmount								= .GetChildContent("*:TaxTotal|*:TaxSubtotal[i]|*:TaxAmount")
			lcCbc_TaxTotal_TaxSubtotal_TaxCategory_ID							= .GetChildContent("*:TaxTotal|*:TaxSubtotal[i]|*:TaxCategory|*:ID")
			lcCbc_TaxTotal_TaxSubtotal_TaxCategory_Percent						= .GetChildContent("*:TaxTotal|*:TaxSubtotal[i]|*:TaxCategory|*:Percent")
			lcCbc_TaxTotal_TaxSubtotal_TaxCategory_TaxExemptionReason			= .GetChildContent("*:TaxTotal|*:TaxSubtotal[i]|*:TaxCategory|*:TaxExemptionReason")
			lcCbc_TaxTotal_TaxSubtotal_TaxCategory_TaxExemptionReasonCode		= .GetChildContent("*:TaxTotal|*:TaxSubtotal[i]|*:TaxCategory|*:TaxExemptionReasonCode")
			lcCbc_TaxTotal_TaxSubtotal_TaxCategory_TaxScheme					= .GetChildContent("*:TaxTotal|*:TaxSubtotal[i]|*:TaxCategory|*:TaxScheme|*:ID")
			*
			lcSuffix = AllTrim(Str(Val(lcCbc_TaxTotal_TaxSubtotal_TaxCategory_Percent)))
			&& Suma Tva si moneda
			lcVar_TaxTotal_TaxSubtotal_TaxableAmount_CurrencyId					= "m.oEFA.TaxTotal_TaxSubtotal_TaxableAmount_CurrencyId_"+lcSuffix
			&lcVar_TaxTotal_TaxSubtotal_TaxableAmount_CurrencyId				= lcCbc_TaxTotal_TaxSubtotal_TaxableAmount_CurrencyId
			lcVar_TaxTotal_TaxSubtotal_TaxableAmount							= "m.oEFA.TaxTotal_TaxSubtotal_TaxableAmount_"+lcSuffix
			&lcVar_TaxTotal_TaxSubtotal_TaxableAmount							= lcCbc_TaxTotal_TaxSubtotal_TaxableAmount
			lcVar_TaxTotal_TaxSubtotal_TaxAmount_CurrencyId						= "m.oEFA.TaxTotal_TaxSubtotal_TaxAmount_CurrencyId_"+lcSuffix
			&lcVar_TaxTotal_TaxSubtotal_TaxAmount_CurrencyId					= lcCbc_TaxTotal_TaxSubtotal_TaxAmount_CurrencyId
			lcVar_TaxTotal_TaxSubtotal_TaxAmount								= "m.oEFA.TaxTotal_TaxSubtotal_TaxAmount_"+lcSuffix
			&lcVar_TaxTotal_TaxSubtotal_TaxAmount								= lcCbc_TaxTotal_TaxSubtotal_TaxAmount
			&& Categoria de TVA
			lcVar_TaxTotal_TaxSubtotal_TaxCategory_ID							= "m.oEFA.TaxTotal_TaxSubtotal_TaxCategory_ID_"+lcSuffix
			&lcVar_TaxTotal_TaxSubtotal_TaxCategory_ID							= lcCbc_TaxTotal_TaxSubtotal_TaxCategory_ID
			lcVar_TaxTotal_TaxSubtotal_TaxCategory_Percent						= "m.oEFA.TaxTotal_TaxSubtotal_TaxCategory_Percent_"+lcSuffix
			&lcVar_TaxTotal_TaxSubtotal_TaxCategory_Percent						= lcCbc_TaxTotal_TaxSubtotal_TaxCategory_Percent
			lcVar_TaxTotal_TaxSubtotal_TaxCategory_TaxExemptionReason			= "m.oEFA.TaxTotal_TaxSubtotal_TaxCategory_TaxExemptionReason_"+lcSuffix
			&lcVar_TaxTotal_TaxSubtotal_TaxCategory_TaxExemptionReason			= lcCbc_TaxTotal_TaxSubtotal_TaxCategory_TaxExemptionReason
			lcVar_TaxTotal_TaxSubtotal_TaxCategory_TaxExemptionReasonCode		= "m.oEFA.TaxTotal_TaxSubtotal_TaxCategory_TaxExemptionReasonCode_"+lcSuffix
			&lcVar_TaxTotal_TaxSubtotal_TaxCategory_TaxExemptionReasonCode		= lcCbc_TaxTotal_TaxSubtotal_TaxCategory_TaxExemptionReasonCode
			lcVar_TaxTotal_TaxSubtotal_TaxCategory_TaxScheme					= "m.oEFA.TaxTotal_TaxSubtotal_TaxCategory_TaxScheme_"+lcSuffix
			&lcVar_TaxTotal_TaxSubtotal_TaxCategory_TaxScheme					= lcCbc_TaxTotal_TaxSubtotal_TaxCategory_TaxScheme
			*	
			*ShowXMLValue("lcCbc_TaxTotal_TaxSubtotal_TaxableAmount_CurrencyId")
		Next
		*
		m.oEFA.PaymentTerms_Note												= .GetChildContent("*:Invoice|*:PaymentTerms|*:Note")									&& Comentarii Plata
		*
		&&	- LegalMonetaryTotal		
		*
		m.oEFA.LegalMonetaryTotal_LineExtensionAmount							= .GetChildContent("*:LegalMonetaryTotal|*:LineExtensionAmount")				&& LiniiFacturaA: Total NET
		m.oEFA.LegalMonetaryTotal_LineExtensionAmount_CurrencyId				= .ChilkatPath	  ("*:LegalMonetaryTotal|*:LineExtensionAmount|(currencyID)")	&& LiniiFacturaA: Moneda Baza TVA
		m.oEFA.LegalMonetaryTotal_TaxExclusiveAmount			 				= .GetChildContent('*:LegalMonetaryTotal|*:TaxExclusiveAmount')					&& LiniiFacturaA: Total NET fara TVA
		m.oEFA.LegalMonetaryTotal_TaxExclusiveAmount_CurrencyId					= .ChilkatPath	  ("*:LegalMonetaryTotal|*:TaxExclusiveAmount|(currencyID)")	&& LiniiFacturaA: Moneda Total NET fara TVA
		m.oEFA.LegalMonetaryTotal_TaxInclusiveAmount							= .GetChildContent("*:LegalMonetaryTotal|*:TaxInclusiveAmount")					&& LiniiFacturaA: Total BRUT
		m.oEFA.LegalMonetaryTotal_TaxInclusiveAmount_CurrencyId					= .ChilkatPath	  ("*:LegalMonetaryTotal|*:TaxInclusiveAmount|(currencyID)")	&& LiniiFacturaA: Mondea Total BRUT
		m.oEFA.LegalMonetaryTotal_PayableAmount									= .GetChildContent("*:LegalMonetaryTotal|*:PayableAmount")
		m.oEFA.LegalMonetaryTotal_PayableAmount_CurrencyId 						= .ChilkatPath	  ("*:LegalMonetaryTotal|*:PayableAmount|(currencyID)")
		*
		&&	- Delivery
		*
		m.oEFA.Delivery_ActualDeliveryDate										= .GetChildContent("*:Delivery|*:ActualDeliveryDate")
		****m.oEFA.ActualDeliveryDate											= ISO2Date(lcCbc_ActualDeliveryDate)
		m.oEFA.Delivery_DeliveryLocation_Address_CityName 						= .GetChildContent("*:Delivery|*:DeliveryLocation|*:Address|*:CityName")
		m.oEFA.Delivery_DeliveryLocation_Address_CountrySubentity 				= .GetChildContent("*:Delivery|*:DeliveryLocation|*:Address|*:CountrySubentity")
		m.oEFA.Delivery_DeliveryLocation_Address_Country_IdentificationCode		= .GetChildContent("*:Delivery|*:DeliveryLocation|*:Address|*:Country|*:IdentificationCode")
		m.oEFA.Delivery_DeliveryLocation_Address_PostalZone 					= .GetChildContent("*:Delivery|*:DeliveryLocation|*:Address|*:PostalZone")
		m.oEFA.Delivery_DeliveryLocation_Address_StreetName						= .GetChildContent("*:Delivery|*:DeliveryLocation|*:Address|*:StreetName")
		m.oEFA.Delivery_DeliveryParty_PartyName_Name							= .GetChildContent("*:Delivery|*:DeliveryParty|*:PartyName|*:Name")
		*
		&&	- PaymentMeans
		*
		m.oEFA.PaymentMeans_CardAccount_HolderName								= .GetChildContent("*:PaymentMeans|*:CardAccount|*:HolderName")
		m.oEFA.PaymentMeans_CardAccount_NetworkID								= .GetChildContent("*:PaymentMeans|*:CardAccount|*:NetworkID")
		m.oEFA.PaymentMeans_CardAccount_PrimaryAccountNumberID					= .GetChildContent("*:PaymentMeans|*:CardAccount|*:PrimaryAccountNumberID")
		m.oEFA.PaymentMeans_PayeeFinancialAccount_ID							= .GetChildContent("*:PaymentMeans|*:PayeeFinancialAccount|*:ID")
		m.oEFA.PaymentMeans_PayeeFinancialAccount_Name							= .GetChildContent("*:PaymentMeans|*:PayeeFinancialAccount|*:Name")
		m.oEFA.PaymentMeans_PayeeFinancialAccount_FinancialInstitutionBranch_ID = .GetChildContent("*:PaymentMeans|*:PayeeFinancialAccount|*:FinancialInstitutionBranch|*:ID")
		m.oEFA.PaymentMeans_PaymentID											= .GetChildContent("*:PaymentMeans|*:PaymentID")
		m.oEFA.PaymentMeans_PaymentMandate_ID									= .GetChildContent("*:PaymentMeans|*:PaymentMandate|*:ID")
		m.oEFA.PaymentMeans_PaymentMandate_PayerFinancialAccount_ID				= .GetChildContent("*:PaymentMeans|*:PaymentMandate|*:PayerFinancialAccount|*:ID")
		m.oEFA.PaymentMeans_PaymentMeansCode									= .GetChildContent("*:PaymentMeans|*:PaymentMeansCode")
		m.oEFA.PaymentMeans_PaymentMeansCode_name								= .ChilkatPath	  ("*:PaymentMeans|*:PaymentMeansCode|(name)")
		*
		*lc_TAXARE_INVERSA =;
			TaxTotal_TaxSubtotal_TaxCategory_ID_0	=	'AE' Or ;
			TaxTotal_TaxSubtotal_TaxCategory_ID_5	=	'AE' Or ;
			TaxTotal_TaxSubtotal_TaxCategory_ID_9	=	'AE' Or ;
			TaxTotal_TaxSubtotal_TaxCategory_ID_19	=	'AE' Or ;
			TaxTotal_TaxSubtotal_TaxCategory_ID_20	=	'AE'
		*
		*/////////////////////////////////////////////////////////////////////////
		*					DISCOUNT la nivel de document
		*/////////////////////////////////////////////////////////////////////////
*!*			m.oEFA.AllowanceCharge_ChargeIndicator									= .GetChildContent("*:AllowanceCharge|*:ChargeIndicator")
*!*			m.oEFA.AllowanceCharge_AllowanceChargeReason							= .GetChildContent("*:AllowanceCharge|*:AllowanceChargeReason")
*!*			m.oEFA.AllowanceCharge_Amount											= .GetChildContent("*:AllowanceCharge|*:Amount")
*!*			m.oEFA.AllowanceCharge_Amount_currencyID 								= .ChilkatPath	  ("*:AllowanceCharge|*:Amount|(currencyID)")
*!*			lcCbc_AllowanceCharge_Percent											= .GetChildContent("*:AllowanceCharge|*:TaxCategory|*:Percent")
*!*			*
*!*		    lcCbc_AllowanceCharge_TaxCategory_Percent								= .GetChildContent("*:AllowanceCharge|*:TaxCategory|*:Percent")
*!*		    lcSuffix = AllTrim(Str(Val(lcCbc_AllowanceCharge_TaxCategory_Percent)))
*!*			*
*!*			lcCbc_AllowanceCharge_TaxCategory_ID									= .GetChildContent("*:AllowanceCharge|*:TaxCategory|*:ID")
*!*			lcVar_AllowanceCharge_TaxCategory_ID									= "m.oEFA.AllowanceCharge_TaxCategory_ID_"+lcSuffix
*!*			&lcVar_AllowanceCharge_TaxCategory_ID									= lcCbc_AllowanceCharge_TaxCategory_ID
*!*			*
*!*			lcVar_AllowanceCharge_TaxCategory_Percent								= "m.oEFA.AllowanceCharge_TaxCategory_Percent_"+lcSuffix
*!*			&lcVar_AllowanceCharge_TaxCategory_Percent								= lcCbc_AllowanceCharge_TaxCategory_Percent		
*!*			*
*!*			lcCbc_AllowanceCharge_TaxCategory_TaxScheme_ID							= .GetChildContent("*:AllowanceCharge|*:TaxCategory|*:TaxScheme|*:ID")	    
*!*			lcVar_AllowanceCharge_TaxCategory_TaxScheme								= "m.oEFA.AllowanceCharge_TaxCategory_TaxScheme_"+lcSuffix
*!*			&lcVar_AllowanceCharge_TaxCategory_TaxScheme							= lcCbc_AllowanceCharge_TaxCategory_TaxScheme_ID
		*
		*

	    lnCount_i = .NumChildrenHavingTag("*:AllowanceCharge")
		*
		For i=0 To  lnCount_i - 1	
			.i = i
			m.oEFA_T.AllowanceCharge_ChargeIndicator			= .ChilkatPath("*:AllowanceCharge[i]|*:ChargeIndicator|*")				&& <!--CI-92 -->		
			m.oEFA_T.AllowanceCharge_AllowanceChargeReasonCode	= .ChilkatPath("*:AllowanceCharge[i]|*:AllowanceChargeReasonCode|*")	&& <!--BT-98-->		sau	<!--BT-105-->
			m.oEFA_T.AllowanceCharge_AllowanceChargeReason		= .ChilkatPath("*:AllowanceCharge[i]|*:AllowanceChargeReason|*")		&& <!--BT-97-->		sau	<!--BT-104-->		
			m.oEFA_T.AllowanceCharge_MultiplierFactorNumeric	= .ChilkatPath("*:AllowanceCharge[i]|*:MultiplierFactorNumeric|*")		&& <!--BT-94-->		sau	<!--BT-101-->
		    m.oEFA_T.AllowanceCharge_Amount						= .ChilkatPath("*:AllowanceCharge[i]|*:Amount|*")						
		    m.oEFA_T.AllowanceCharge_Amount_CurrencyId			= .ChilkatPath("*:AllowanceCharge[i]|*:Amount|(currencyID)")			&& <!--BT-92-->		sau	<!--BT-99 -->
			m.oEFA_T.AllowanceCharge_BaseAmount					= .ChilkatPath("*:AllowanceCharge[i]|*:BaseAmount|*")
			m.oEFA_T.AllowanceCharge_BaseAmount_CurrencyId		= .ChilkatPath("*:AllowanceCharge[i]|*:BaseAmount|(currencyID)")		&& <!--BT-93-->		sau	<!--BT-100-->
			m.oEFA_T.AllowanceCharge_TaxCategory_Percent		= .ChilkatPath("*:AllowanceCharge[i]|*:TaxCategory|*:Percent|*")    
			*================================================	
			Select EFA_INVOICE_TAXE
			Insert Into EFA_INVOICE_TAXE From Name m.oEFA_T
			*================================================
		EndFor
		*
		*
		*/////////////////////////////////////////////////////////////////////////		
	    
		*================================================	
		Insert Into EFA_INVOICE_ANTET From Name m.oEFA
		*================================================
		*
		*Varianta Chilakt.parseXml.Online
		*------------
		&& 25.05.2024
		*------------
		If m.oEFA.InvoiceTypeCode = '381'
			lcTag_InvoiceLine = '*:CreditNoteLine'
		Else
			lcTag_InvoiceLine = '*:InvoiceLine'
		EndIf
		*------------	04.10.2024
		If m.oEFA.InvoiceTypeCode	= '381'
			lcTag_InvoicedQuantity	= '*:CreditedQuantity'
		Else
			lcTag_InvoicedQuantity	= '*:InvoicedQuantity'
		EndIf
		*------------	04.10.2024
		*
		*lnCount_i = .NumChildrenHavingTag("*:InvoiceLine")
		*? ' lnCount_i = .NumChildrenHavingTag("*:InvoiceLine"): ', lnCount_i
		lnCount_i = .NumChildrenHavingTag(lcTag_InvoiceLine)
		*Set Step On
		For i=0 To  lnCount_i - 1									&& "InvoiceLine"
			.i = i
			m.oEFA_L.Id												= .GetChildContent(lcTag_InvoiceLine+"[i]|*:ID")
			m.oEFA_L.Note											= .GetChildContent(lcTag_InvoiceLine+"[i]|*:Note")
			*
			&&-- 04.10.2024
			*
			*m.oEFA_L.InvoicedQuantity_UnitCode						= .ChilkatPath	  (lcTag_InvoiceLine+"[i]|*:InvoicedQuantity|(unitCode)")
			*m.oEFA_L.InvoicedQuantity								= .GetChildContent(lcTag_InvoiceLine+"[i]|*:InvoicedQuantity")
			m.oEFA_L.InvoicedQuantity_UnitCode						= .ChilkatPath	  (lcTag_InvoiceLine+"[i]|"+lcTag_InvoicedQuantity+"|(unitCode)")
			m.oEFA_L.InvoicedQuantity								= .GetChildContent(lcTag_InvoiceLine+"[i]|"+lcTag_InvoicedQuantity)
			*
			&&-- 04.10.2024
			*
			m.oEFA_L.LineExtensionAmount_CurrencyId					= .ChilkatPath	  (lcTag_InvoiceLine+"[i]|*:LineExtensionAmount|(currencyID)")
			m.oEFA_L.LineExtensionAmount							= .GetChildContent(lcTag_InvoiceLine+"[i]|*:LineExtensionAmount")
			m.oEFA_L.AccountingCost									= .GetChildContent(lcTag_InvoiceLine+"[i]|*:AccountingCost")
			m.oEFA_L.InvoicePeriod_StartDate						= .GetChildContent(lcTag_InvoiceLine+"[i]|*:InvoicePeriod|*:StartDate")
			m.oEFA_L.InvoicePeriod_EndDate							= .GetChildContent(lcTag_InvoiceLine+"[i]|*:InvoicePeriod|*:EndDate")
			*-- Tb. linie noua
			&& <AllowanceCharge>												<!--BG-27 deducere-->
			&& 	<ChargeIndicator>false</ChargeIndicator>
			&& 	<AllowanceChargeReasonCode>100</AllowanceChargeReasonCode>		<!--BT-140-->
			&& 	<AllowanceChargeReason>Loyal customer</AllowanceChargeReason>	<!--BT-139-->
			&& 	<MultiplierFactorNumeric>10.00</MultiplierFactorNumeric>		<!--BT-138-->
			&& 	<Amount currencyID="RON">150</Amount>							<!--BT-136-->
			&& 	<BaseAmount currencyID="RON">1500</BaseAmount>					<!--BT-137-->
			&& </AllowanceCharge>
			&& <AllowanceCharge>												<!--BG-28 taxa suplimentara-->
			&& 	<ChargeIndicator>true</ChargeIndicator>
			&& 	<AllowanceChargeReasonCode>ABL</AllowanceChargeReasonCode>		<!--BT-145-->
			&& 	<AllowanceChargeReason>Packing cost</AllowanceChargeReason>		<!--BT-144-->
			&& 	<MultiplierFactorNumeric>10.00</MultiplierFactorNumeric>		<!--BT-143-->
			&& 	<Amount currencyID="RON">150</Amount>							<!--BT-141-->
			&& 	<BaseAmount currencyID="RON">1500</BaseAmount>					<!--BT-142-->
			&& </AllowanceCharge>
			m.oEFA_L.AllowanceCharge_ChargeIndicator				= .GetChildContent(lcTag_InvoiceLine+"[i]|*:AllowanceCharge|*:ChargeIndicator")
			m.oEFA_L.AllowanceCharge_AllowanceChargeReasonCode		= .GetChildContent(lcTag_InvoiceLine+"[i]|*:AllowanceCharge|*:AllowanceChargeReasonCode")
			m.oEFA_L.AllowanceCharge_AllowanceChargeReason			= .GetChildContent(lcTag_InvoiceLine+"[i]|*:AllowanceCharge|*:AllowanceChargeReason")
			m.oEFA_L.AllowanceCharge_MultiplierFactorNumeric		= .GetChildContent(lcTag_InvoiceLine+"[i]|*:AllowanceCharge|*:MultiplierFactorNumeric")
			m.oEFA_L.AllowanceCharge_Amount_CurrencyId				= .ChilkatPath	  (lcTag_InvoiceLine+"[i]|*:AllowanceCharge|*:Amount|(currencyID)")
			m.oEFA_L.AllowanceCharge_Amount							= .GetChildContent(lcTag_InvoiceLine+"[i]|*:AllowanceCharge|*:Amount")
			m.oEFA_L.AllowanceCharge_BaseAmount_CurrencyId			= .ChilkatPath	  (lcTag_InvoiceLine+"[i]|*:AllowanceCharge|*:BaseAmount|(currencyID)")
			m.oEFA_L.AllowanceCharge_BaseAmount						= .GetChildContent(lcTag_InvoiceLine+"[i]|*:AllowanceCharge|*:BaseAmount")
			*		
			m.oEFA_L.Item_Description								= .GetChildContent(lcTag_InvoiceLine+"[i]|*:Item|*:Description")
			m.oEFA_L.Item_Name										= .GetChildContent(lcTag_InvoiceLine+"[i]|*:Item|*:Name")
			m.oEFA_L.Item_ClassifiedTaxCategory_ID					= .GetChildContent(lcTag_InvoiceLine+"[i]|*:Item|*:ClassifiedTaxCategory|*:ID")
			m.oEFA_L.Item_ClassifiedTaxCategory_Percent				= .GetChildContent(lcTag_InvoiceLine+"[i]|*:Item|*:ClassifiedTaxCategory|*:Percent")
			*
*!*				If Not Used('C_ALLOWANCE_CHARGES')
*!*					CREATE CURSOR C_ALLOWANCE_CHARGES (invoiceLine i, reason C (64), charge L, suma N (15, 2), cota N (5, 2))
*!*				EndIf
*!*				*
*!*	            mDiscountFDen		= Nvl(m.oEFA_L.AllowanceCharge_AllowanceChargeReason, '')
*!*	            mDiscountIndicator	= m.oEFA_L.AllowanceCharge_ChargeIndicator
*!*	            mDiscountValoare	= Val(m.oEFA_L.AllowanceCharge_Amount)
*!*	            mDiscountPTva		= Val(m.oEFA_L.Item_ClassifiedTaxCategory_Percent)
*!*	            *
*!*	            IF mDiscountValoare<>0
*!*	                INSERT INTO C_ALLOWANCE_CHARGES (invoiceLine, reason, charge, suma, cota) VALUES (i+1, AllTrim(mDiscountFDen), IIF(mDiscountIndicator="FALSE", .F., .T.), mDiscountValoare, mDiscountPTva)
*!*	            EndIf
            *			
			m.oEFA_L.Item_ClassifiedTaxCategory_TaxScheme_ID		= .GetChildContent(lcTag_InvoiceLine+"[i]|*:Item|*:ClassifiedTaxCategory|*:TaxScheme|*:ID")
			m.oEFA_L.Item_AdditionalItemProperty_Name				= .GetChildContent(lcTag_InvoiceLine+"[i]|*:Item|*:AdditionalItemProperty|*:Name")
			m.oEFA_L.Item_AdditionalItemProperty_Value				= .GetChildContent(lcTag_InvoiceLine+"[i]|*:Item|*:AdditionalItemProperty|*:Value")
			m.oEFA_L.Price_PriceAmount_CurrencyId					= .ChilkatPath	  (lcTag_InvoiceLine+"[i]|*:Price|*:PriceAmount|(currencyID)")
			m.oEFA_L.Price_PriceAmount								= .GetChildContent(lcTag_InvoiceLine+"[i]|*:Price|*:PriceAmount")
			m.oEFA_L.Price_BaseQuantity_UnitCode					= .ChilkatPath	  (lcTag_InvoiceLine+"[i]|*:Price|*:BaseQuantity|(unitCode)")
			m.oEFA_L.Price_BaseQuantity								= .GetChildContent(lcTag_InvoiceLine+"[i]|*:Price|*:BaseQuantity")
			m.oEFA_L.Price_AllowanceCharge_ChargeIndicator			= .GetChildContent(lcTag_InvoiceLine+"[i]|*:Price|*:AllowanceCharge|*:ChargeIndicator")
			m.oEFA_L.Price_AllowanceCharge_Amount_CurrencyId		= .ChilkatPath	  (lcTag_InvoiceLine+"[i]|*:Price|*:AllowanceCharge|*:Amount|(currencyID)")
			m.oEFA_L.Price_AllowanceCharge_Amount					= .GetChildContent(lcTag_InvoiceLine+"[i]|*:Price|*:AllowanceCharge|*:Amount")
			m.oEFA_L.Price_AllowanceCharge_BaseAmount_CurrencyId	= .ChilkatPath	  (lcTag_InvoiceLine+"[i]|*:Price|*:AllowanceCharge|*:BaseAmount|(currencyID)")
			m.oEFA_L.Price_AllowanceCharge_BaseAmount				= .GetChildContent(lcTag_InvoiceLine+"[i]|*:Price|*:AllowanceCharge|*:BaseAmount")
			*
	        Store '' To CodBARE, codNC, codCPV, codFurnizor
	        *
		    lcCbc_ID_SellersItemIdentification	= .GetChildContent(lcTag_InvoiceLine+"[i]|*:Item|*:SellersItemIdentification|*:ID")
	        *
	        If IsValidEAN(lcCbc_ID_SellersItemIdentification)
	        	m.codBARE		= Left(lcCbc_ID_SellersItemIdentification, 13)
	        Else
	        	m.codFurnizor	= Left(lcCbc_ID_SellersItemIdentification, 13)
	        EndIf
	        *
		    lcCbc_ID_BuyersItemIdentification	= .GetChildContent(lcTag_InvoiceLine+"[i]|*:Item|*:BuyersItemIdentification|*:ID")
	        *
	        If IsValidEAN(lcCbc_ID_BuyersItemIdentification)  And Empty(m.CodBARE)
	        	m.codBARE		= Left(lcCbc_ID_BuyersItemIdentification, 13)
	        EndIf	
	        If Empty(m.codFurnizor)
	        	m.codFurnizor	= Left(lcCbc_ID_BuyersItemIdentification, 13)
	        EndIf
			*	        
	        *ShowXMLValue("m.codBARE")
	        *
		    lnCount_j					= .NumChildrenHavingTag(lcTag_InvoiceLine+"[i]|*:Item|*:StandardItemIdentification")
		    *? ' lnCount_j				= .NumChildrenHavingTag(lcTag_InvoiceLine+"[i]|*:Item|*:StandardItemIdentification"): ', lnCount_j
		    For j						= 0 To lnCount_j - 1
		        .J						= j
		        lcCbc_ID_schemeID		= .ChilkatPath	  (lcTag_InvoiceLine+"[i]|*:Item|*:StandardItemIdentification[j]|*:ID|(schemeID)")
		        lcCbc_ID_schemeID_ID	= .GetChildContent(lcTag_InvoiceLine+"[i]|*:Item|*:StandardItemIdentification[j]|*:ID")
		        *
		        If InList(lcCbc_ID_schemeID, "0160", "0005") And IsValidEAN(lcCbc_ID_schemeID_ID) And Empty(m.CodBARE)
		        	m.codBARE			= Left(lcCbc_ID_schemeID_ID, 13)
		        EndIf
		        *		        
		    Next
		    *
		    lnCount_k										= .NumChildrenHavingTag(lcTag_InvoiceLine+"[i]|*:Item|*:CommodityClassification")
		    *? ' lnCount_k									= .NumChildrenHavingTag(lcTag_InvoiceLine+"[i]|*:Item|*:CommodityClassification"): ', lnCount_k
		    For k											= 0 To lnCount_k - 1
		        .J 											= k
		        lcCbc_ItemClassificationCode_listID			= .ChilkatPath	  (lcTag_InvoiceLine+"[i]|*:Item|*:CommodityClassification[k]|*:ItemClassificationCode|(listID)")
		        lcCbc_ItemClassificationCode_listVersionID	= .ChilkatPath	  (lcTag_InvoiceLine+"[i]|*:Item|*:CommodityClassification[k]|*:ItemClassificationCode|(listVersionID)")
		        lcCbc_ItemClassificationCode				= .GetChildContent(lcTag_InvoiceLine+"[i]|*:Item|*:CommodityClassification[k]|*:ItemClassificationCode")
	            *
	            Do Case
	            	Case lcCbc_ItemClassificationCode_listID = "EN" And IsValidEAN(lcCbc_ItemClassificationCode) And Empty(m.CodBARE)
	            		m.CodBARE	= Left(lcCbc_ItemClassificationCode, 13)
	            	Case lcCbc_ItemClassificationCode_listID = "STI"
	            		m.codCPV	= Left(lcCbc_ItemClassificationCode, 13)
	            	Case lcCbc_ItemClassificationCode_listID = "STI"
	            		m.codNC		= Left(lcCbc_ItemClassificationCode, 13)
	            	OtherWise
	            		&& justincase for future	
	            EndCase
	            *
		    Next
			*
			m.oEFA_L.codBARE	= m.CodBARE
			m.oEFA_L.codCPV		= m.CodCPV
			m.oEFA_L.codNC		= m.CodNC
			m.oEFA_L.codFurnizor= m.CodFurnizor
			*
			*ShowXMLValue("m.oEFA_L.ID")
			*ShowXMLValue("m.oEFA_L.InvoicedQuantity_unitCode")
			*
			*================================================
			Insert Into EFA_INVOICE_LINII From Name m.oEFA_L
			*================================================
			*
		EndFor												&& "InvoiceLine"
		*
	EndWith
	*
	*RELEASE loXml
EndFunc
* __________________________________________________________________________________________________________
Function Incarcare_EFA_Intrare(tcRecipisa)
	*
	If Not Used('crs_SQL_TERTI')
		*
		If ll_Is_ICAS
			mySQLExec([ Select Cod, DenJud From Configurari.Judete ], [crs_SQL_TERTI])
		Else
			*
			If Not Used('Judete')
				Create_Cursor_Judete()
			EndIf
			*
			Select Cod, DenJud From Judete Into Cursor crs_SQL_TERTI
			*
		EndIf
		*	
	EndIf
	*
	m.Recipisa		= tcRecipisa
	*
	*=CheckDownloadLimit_ANAF()
	*
	Store'' To lcXmlFactura, lcCaleXML
	Store .F. To ll_SEEK_PRIMITE
	*
	&& Nu ar trebui sa gaseasca deoarece cursorul Documente este GOL si acum il incarc cu date
	*
	If Seek(m.Recipisa, 'Documente', 'Recipisa') And Occurs("<Invoice xmlns=", Documente.Continut)>0
		*
		lcXmlFactura		= Documente.Continut
		lcCaleXML			= Documente.Cale
		ll_SEEK_PRIMITE		= .T.
		lcErrMSG			= "Recipisa: "+m.Recipisa+ " deja a fost importata in INTRARI"
		Return lcErrMSG			&& Loop
		*
	Else
		*
		*-- Daca exista nu mai descarca de pe serverul ANAF.			OARE ???????????????????????
		*
		lo_EFA_Furnizor	= Descarca_eFactura_Furnizor( m.Recipisa, 'EFA_INTRARI' )
		*
		If Not ( VarType(lo_EFA_Furnizor)='O' And Not IsNull(lo_EFA_Furnizor) )
			lcErrMSG = ;
				"Nu a reusit initializarea obiectului [lo_EFA_Furnizor]."+Chr(13)+;
				"pentru recipisa: "+m.Recipisa+Chr(13)+;
				Program()
			*MessageBox(lcErrMSG, 16, "Eroare")
			*Set Step On
			Return lcErrMSG			&& Loop
		EndIf
		*
		lcXmlFactura		= lo_EFA_Furnizor.cXmlString
		*lcCaleXML			= lo_EFA_Furnizor.cZipFileName
		lcCaleXML			= GetNumeFisierSafe(	lo_EFA_Furnizor.cZipFileName	)		&&-- 05.11.2024
		*
		If IsNullOrEmpty(lcXmlFactura)
			lcErrMSG = "Nu a reusit descarcarea facturii primite de la furnizor cu recipisa "+m.Recipisa
			MessageBox(lcErrMSG, 16, "Eroare: " + Program())
			Set Step On
			Return lcErrMSG			&& Loop
		EndIf
		*
	EndIf
	*
	llResult			= Not IsNullOrEmpty(lcXmlFactura)
	*
	If llResult
		*
		loXml = CreateObject("Chilkat_9_5_0.Xml")
		* �ncarcare document XML
		llSuccess = loXml.LoadXML(	CleanXMLPrefix( lcXmlFactura ) )
		*
		If llSuccess = 0
			lcEroare_loXML = "Eroare la �ncarcarea documentului XML: "  +Chr(13)+ loXml.LastErrorText
			MessageBox(lcEroare_loXML, 16, "Eroare")
			Select EFA_INTRARI
			Loop
		Else
			*//////////////////////
			=eFactura_Parse(loXml)			&& tb tratat si DISCOUNTUL la nivel de document !!!!!!!	-- 05.07.2024
			*//////////////////////
			*
			lcCodFiscal_Furnizor	= Documente.Cod_Fiscal
			ldDataDoc				= Documente.DataDoc
			ldScadenta				= SetDateGerman(EFA_Invoice_Antet.DueDate)
			*lcCodValuta			= EFA_Invoice_Antet.LegalMonetaryTotal_PayableAmount_CurrencyId
			lcCodValuta				= EFA_Invoice_Antet.DocumentCurrencyCode
			*lnTotal				= Val(EFA_Invoice_Antet.LegalMonetaryTotal_PayableAmount)
			lnTotal					= Val(EFA_Invoice_Antet.LegalMonetaryTotal_TaxInclusiveAmount)
			lnSuma					= Val(EFA_Invoice_Antet.LegalMonetaryTotal_TaxExclusiveAmount)
			&& 12.08.2024
			*lnTva					= Val(EFA_Invoice_Antet.TaxTotal_TaxAmount)
			lnTva					= lnTotal - lnSuma
			lnTva_RON				= Val(EFA_Invoice_Antet.TaxTotal_TaxAmount_RON)		&& BT-111
			&& 12.08.2024
			lcNote					= EFA_Invoice_Antet.Note
			lnNeachitat				= lnTotal
			ll_TAXARE_INVERSA =;
				EFA_Invoice_Antet.TaxTotal_TaxSubtotal_TaxCategory_ID_0		=	'AE' Or ;
				EFA_Invoice_Antet.TaxTotal_TaxSubtotal_TaxCategory_ID_5		=	'AE' Or ;
				EFA_Invoice_Antet.TaxTotal_TaxSubtotal_TaxCategory_ID_9		=	'AE' Or ;
				EFA_Invoice_Antet.TaxTotal_TaxSubtotal_TaxCategory_ID_19	=	'AE' Or ;
				EFA_Invoice_Antet.TaxTotal_TaxSubtotal_TaxCategory_ID_20	=	'AE'
			&& 1, " ","Factura",1
			&& 2, "A","Aviz",1
			&& 3, "T","Taxare inversa",1
			&& 4, "G","Factura pe mai multe gestiuni",1
			&& 5, "F","Factura imobilizari",1
			&& 6, "P","Fara drept de deducere partial (pro-rata)",1
			&& 7, "I","Fara drept de deducere integral (pro-rata)",1
			&& 8, "B","Bonuri Fiscale FARA CIF",1
			&& 9, "C","Bonuri Fiscale CU CIF (cu valoare de factura simplificata)",1
			&& 10, "e","Exceptii utilizare AMEF",1
			&& 11, "U","TURISM - Servicii cf. art. 311",1
			&& 12, "H","SECOND HAND - Achizitii cf. art. 312",1
			&& 13, "O","Borderouri de achizitii",1
			&& 14, "Z","File carnete de comercializare",1
			&& 15, "Q","Contracte",1
			&& 16, "M","Factura simplificata (exceptand bonuri fiscale)",1
			&& 17, "L", "Factura emisa in numele furnizorului", 1
			&& 18, "n","Operatiuni neimpozabile",1
			*
			*	- FACTURA achitata cu bon fiscal = 751
			*
			lnTipFactura			= ICase(ll_TAXARE_INVERSA, 3, EFA_Invoice_Antet.InvoiceTypeCode='380', 4, 4)
			*
			*AICI Tara, Judet, Localitate, Strada, Tip_Tert
			#if .f.
				Tara='RO' intotdeauna
				Tip_Tert '1'
						
				Judet			C(15)		
				Localitate		C(70)
				Strada			C(30)
				Sector			C(1)
					
			AccountingSupplierParty_Party_PostalAddress_CountrySubentity	Judet			RO-B  		TB. parsare
			AccountingSupplierParty_Party_PostalAddress_CityName			Localitate		SECTOR4		Loc.BUCURESTI, sector 4
			AccountingSupplierParty_Party_PostalAddress_StreetName			Strada			Calea Serban Voda 206   
			#endif			
			*
			lc_CountrySubentity_Judet	= GetWordNum(AllTrim(EFA_Invoice_Antet.AccountingSupplierParty_Party_PostalAddress_CountrySubentity), 2, '-')
			Select DenJud From crs_SQL_TERTI Where AllTrim(Cod)==AllTrim(lc_CountrySubentity_Judet) Into Array aGetJudet_Furnizor
			lcJudet_Furnizor			= Iif(_Tally>0, aGetJudet_Furnizor(1), '')
			lcLocalitate_CityName		= AllTrim(EFA_Invoice_Antet.AccountingSupplierParty_Party_PostalAddress_CityName)
			lcLocalitate				= lcLocalitate_CityName
			lcSector=''
			*'Reg.Com.: J40/6468/2002 #Capital Social: 22.486.460 RON'
			lcRCom						= AllTrim(EFA_Invoice_Antet.AccountingSupplierParty_Party_PartyLegalEntity_CompanyLegalForm)
			lcRegistru					= AllTrim(SubStr(lcRCom, Atc('J', lcRCom), 14))
			*
			If 'SECTOR' $ Upper(lcLocalitate_CityName)
				lcLocalitate			= 'BUCURESTI'
				lcSector				= Right(lcLocalitate_CityName, 1)
			EndIf
			*
			*lcNumarStrada				= OnlyNumber (AllTrim(EFA_Invoice_Antet.AccountingSupplierParty_Party_PostalAddress_StreetName))
			*lcStrada					= GetStrFromStr(AllTrim(EFA_Invoice_Antet.AccountingSupplierParty_Party_PostalAddress_StreetName))
			*lcStrada					= StrTran(AllTrim(EFA_Invoice_Antet.AccountingSupplierParty_Party_PostalAddress_StreetName), lcNumarStrada, '')
			lcStrada					= AllTrim(EFA_Invoice_Antet.AccountingSupplierParty_Party_PostalAddress_StreetName)
			*
			&&-- 04.10.2024
			*
			lcInvoiceTypeCode			= EFA_Invoice_Antet.InvoiceTypeCode
			*
			&&-- 04.10.2024
			*
			Update;
				Documente;
			Set;
				Tip			= lnTipFactura,;	
				Scadenta	= ldScadenta,;
				Cod_Valuta	= lcCodValuta,;		
				Total		= lnTotal,;
				Suma		= lnSuma,;
				Tva			= lnTva,;
				Tva_RON		= lnTva_RON,;
				Neachitat 	= lnTotal,;
				Cont		= AllTrim(GetContFromCodFiscalAndSintetic(lcCodFiscal_Furnizor, '401')),;
				Observatii	= lcNote,;
				AnT			= Year(ldDataDoc),;
				LunaT		= Month(ldDataDoc),;
				cFile		= Documente.Cale,;
				Judet		= lcJudet_Furnizor,;
				Localitate	= lcLocalitate,;
				Strada		= lcStrada,;
				Sector		= lcSector,;
				Registru	= lcRegistru;
				, InvoiceTypeCode = lcInvoiceTypeCode;	&&-- 04.10.2024
			Where;
				Recipisa	= m.Recipisa	
			*
			*		======= >   Scan LINII	
			*
			Select EFA_Invoice_Linii
			Scan
				*
				Select DocumenteLinii
				SCATTER NAME oInvoiceLines BLANK 
				*
				Select EFA_Invoice_Linii
				*
				*InsertLiniiIntrare(toForm, tnIdDOC)
				With oInvoiceLines
					*If .Item_ClassifiedTaxCategory_ID=='AE'
					*	.Tip			= 'T		&&Taxare Inversa'
					*EndIf		
					.IdPozitie			= Val(Id)
					.Recipisa			= m.Recipisa
					.Denumire			= Item_Name					&& Item_Description
					.Um					= InvoicedQuantity_UnitCode
					*.Cantitate			= Val(InvoicedQuantity)
					.Cantitate			= Iif(lcInvoiceTypeCode='381', -Val(InvoicedQuantity), Val(InvoicedQuantity))	&&-- 04.10.2024 CREDIT NOTE
					*
					*.TaxScheme			= Item_ClassifiedTaxCategory_TaxScheme_ID
					.ProcTva			= Val(Item_ClassifiedTaxCategory_Percent)
					=GetTvaInfoFromProcent	(.ProcTva,	oInvoiceLines)
					.PretStoc			= Val(Price_PriceAmount)
					.Valoare			= Iif(lcInvoiceTypeCode='381', -Val(LineExtensionAmount), Val(LineExtensionAmount))
					.Tva				= Round( .Valoare * .ProcTva /100, 2)
					.Total				= .Valoare + .Tva
					.IsPromo			= .F.
					.CodBARE			= codBare
					.codNC				= codNC
					.codCPV				= codCPV
					.codFurnizor		= codFurnizor
					*
				EndWith
				*
				INSERT INTO DocumenteLINII FROM NAME oInvoiceLines
				*
			EndScan
			*
			*		======= >   Discounturi ANTET
			*/////////////////////////////////////////////////////////////
			*				DISCOUNT linie factura
			*	numai daca exista AllowanceCharge in ANTET
			*/////////////////////////////////////////////////////////////
			*
			&&:: 19.09.2024
			*
			Select EFA_INVOICE_TAXE
			Scan
			
				*If m.Recipisa = '3664707346'
				*	Set Step On
				*EndIf	
				
				ll_Is_Discount		= EFA_INVOICE_TAXE.AllowanceCharge_ChargeIndicator = 'false'
				lcDen_Disc_Taxe		= EFA_INVOICE_TAXE.AllowanceCharge_AllowanceChargeReason
				lcMoneda_Disc_Taxe	= EFA_INVOICE_TAXE.AllowanceCharge_Amount_CurrencyId
				lnCotaTVA_Disc_Taxe	= Val(EFA_INVOICE_TAXE.AllowanceCharge_TaxCategory_Percent)
				lnProc_Disc_Taxe	= Val(EFA_INVOICE_TAXE.AllowanceCharge_MultiplierFactorNumeric)
				lnSuma_Disc_Taxe	= Val(EFA_INVOICE_TAXE.AllowanceCharge_Amount)
				lnBaza_Disc_Taxe	= Val(EFA_INVOICE_TAXE.AllowanceCharge_BaseAmount)

				If lnSuma_Disc_Taxe <> 0
					*
			        lcTipAllowance = ""
			        Do Case
			        	Case "discount"$Lower(lcDen_Disc_Taxe)
			        		lcTipAllowance = "Discount"
			        	Case "reducere comerciala"$Lower(lcDen_Disc_Taxe) .Or. ('reducer'$Lower(lcDen_Disc_Taxe) .And.  .Not. ll_Is_Discount)
			        		lcTipAllowance = "Reducere comerciala"
			        	Case "transport"$Lower(lcDen_Disc_Taxe)
			        		lcTipAllowance = "Transport"
			        	Case "acciza"$Lower(lcDen_Disc_Taxe) .Or. "accize"$Lower(lcDen_Disc_Taxe)
			        		lcTipAllowance = "Acciza"
			        EndCase
					*
			        Do Case
			        	Case lcTipAllowance="Discount"
		        			m.Cont = "767"
			        	Case lcTipAllowance="Reducere comerciala"
			        		m.Cont = "609"
			        	Case lcTipAllowance="Transport"
			        			m.Cont = "624"
			        	Case lcTipAllowance="Acciza"
			        		*lnSumaAcciza = lnSumaAcciza+lnSuma_Disc_Taxe
			        		m.Cont = ""
			        	OtherWise
			        		m.Cont = ""
			        EndCase
	            	*
        			Select DocumenteLinii
					SCATTER NAME oInvoiceLines_Discount_Taxe BLANK
					Select EFA_Invoice_Linii
					*
					With oInvoiceLines_Discount_Taxe
						*If .Item_ClassifiedTaxCategory_ID=='AE'
						*	.Tip			= 'T		&&Taxare Inversa'
						*EndIf		
						.IdPozitie			= Val(Id)+1
						.Recipisa			= m.Recipisa
						.Denumire			= lcDen_Disc_Taxe
						.Um					= "H87"
						.Cantitate			= Iif(ll_Is_Discount, -1, 1)
						.ProcTva			= lnCotaTVA_Disc_Taxe
						=GetTvaInfoFromProcent	(.ProcTva,	oInvoiceLines_Discount_Taxe)
						.PretStoc			= Iif(ll_Is_Discount, -1, 1) * lnSuma_Disc_Taxe
						.Valoare			= .PretStoc
						.Tva				= Round( .Valoare * .ProcTva /100, 2)
						.Total				= .Valoare + .Tva
						.IsPromo			= .F.
						.CodBARE			= ""
						.codNC				= ""
						.codCPV				= ""
						.codFurnizor		= ""
						*
					EndWith
					*
					INSERT INTO DocumenteLINII FROM NAME oInvoiceLines_Discount_Taxe
					*
				EndIf
				*
			EndScan
			*	
			*/////////////////////////////////////////////////////////////
			*
			&&:: 19.09.2024
			*
			Select DocumenteLINII
			Locate For IsNullOrEmpty(Cont)
			*
			If Found()
				*
				Select DocumenteLINII
				Scan For IsNullOrEmpty(Cont)
					*
					If Seek(DocumenteLINII.Denumire, [cGetCont], [Denumire])
						*
						If ll_Is_ICAS
							*
							Replace;
									Cont		With cGetCont.Cont;
								,	IdArticol	With cGetCont.IdArticol;
								,	IdTipArt	With cGetCont.IdTipArt;
								,	DenTipArt	With cGetCont.DenTipArt;
								,	IdGest		With cGetCont.IdGest;
								,	DenGest		With cGetCont.DenGest;
							In DocumenteLINII
							*
						Else	
							*
							Replace;
									Cod_Prod	With cGetCont.Cont;
								,	IdArticol	With cGetCont.IdArticol;
								,	IdTipArt	With cGetCont.IdTipArt;
								,	DenTipArt	With cGetCont.DenTipArt;
								,	IdGest		With cGetCont.IdGest;
								,	DenGest		With cGetCont.DenGest;
							In DocumenteLINII
							*
						EndIf
						*	
					Else
						*
						m.Cont_Intrari_Uzual = GetCommontArticolIntrareInfo(DocumenteLINII.Denumire)
						*
						If Seek(m.Cont_Intrari_Uzual, [cGetCont], [Cont]) And ll_Is_ICAS
							*
							Replace;
									Cont		With cGetCont.Cont;
								,	IdArticol	With cGetCont.IdArticol;
								,	IdTipArt	With cGetCont.IdTipArt;
								,	DenTipArt	With cGetCont.DenTipArt;
								,	IdGest		With cGetCont.IdGest;
								,	DenGest		With cGetCont.DenGest;
							In DocumenteLINII
							*
						Else
							*
							If ll_Is_ICAS
								Replace Cont With m.Cont_Intrari_Uzual In DocumenteLINII
							EndIf
							*
						EndIf
						*	
					EndIf	
					*
				EndScan
				*
			EndIf
			*
			**-- 06.11.2024
			Select DocumenteLINII
			Replace All Cont_Original With Cont In DocumenteLINII
			**-- 06.11.2024
			*
		EndIf
		*
	EndIf
	*
EndFunc
* __________________________________________________________________________________________________________
Function Incarcare_EFA_Iesire(tcRecipisa)
	*
*!*		Local _StartBegin, _Start, lcLogFile As String, lcProgram As String 
*!*		_StartBegin	= Seconds()
*!*		_Start		= _StartBegin
*!*		lcProgram	= Program()
*!*		lcLogFile	= Get_Log_EFA()+lcProgram+'_'+tcRecipisa+'.log'
*!*		Erase (lcLogFile)
	*
	If Not Used('IesiriANTET')
		CreareCursoare_IESIRI()
	EndIf
	*	
	If Not Used('crs_SQL_TERTI')
		*
		If ll_Is_ICAS
			mySQLExec([ Select Cod, DenJud From Configurari.Judete ], [crs_SQL_TERTI])
		Else
			*
			If Not Used('Judete')
				Create_Cursor_Judete()
			EndIf
			*
			Select Cod, DenJud From Judete Into Cursor crs_SQL_TERTI
			*
		EndIf
		*	
	EndIf
	*
	m.Recipisa		= tcRecipisa
	Store 0 To lnIdDoc, lnImportat
	*
	*AddToLog(Transform(Seconds()-_Start, [999.9999])+[ mySQLExec(lcSQL, 'c_Iesiri_Recipisa') ], lcLogFile, .T., .T.)
	*
	If Seek(m.Recipisa, [c_Iesiri_Recipisa], 'Recipisa')
		*
		lnIdDoc		= C_Iesiri_Recipisa.Id_Iesire			&& Deja factura primita a fost salvata in ICAS.IESIRI
		lnIdUnic	= C_Iesiri_Recipisa.IdUNIC
		lnImportat	= 1
		*lnPreluat	= 1
		lnPreluat	= 0
		&& TODO: Afisez si pe cele deja importate sau o sa fac un checkbox, dar nu o sa permit sa mai fie importate in Intrari
		&&	NU AR FI CAZUL ACUM pt. ca nu am facut rutina de preluare facturi emise de Estoc sau alte surse in ICAS.IESIRI
		lcXmlFactura= ''
		lcCaleXML	= ''
		*
		Replace;
			 Preluat	With lnPreluat,;
			 Importat	With lnImportat,;
			 IdDoc		With lnIdDoc;
			 IdUnic		With lnIdUnic;
		In IesiriANTET
		*
		Select EFA_IESIRI
		*Return .F.	&& Loop
		*
	EndIf
	*
	*=CheckDownloadLimit_ANAF()
	*
	Store'' To lcXmlFactura, lcCaleXML
	Store .F. To ll_SEEK_PRIMITE
	*
	If Seek(m.Recipisa, 'IesiriANTET', 'Recipisa') And Occurs("<Invoice xmlns=", IesiriANTET.Continut)>0
		*
		lcXmlFactura		= IesiriANTET.Continut
		lcCaleXML			= IesiriANTET.Cale
		ll_SEEK_PRIMITE		= .T.
		lcErrMSG			= "Recipisa: "+m.Recipisa+ " deja a fost importata in IESIRI"
		Return lcErrMSG			&& Loop
		*
	Else
		*
		lo_EFA_Client	= Descarca_eFactura_Client( m.Recipisa, 'EFA_IESIRI', .F.,  EFA_IESIRI.Data)		
		&& Daca exista nu mai descarca de pe serverul ANAF
		*
		If Not ( VarType(lo_EFA_Client)='O' And Not IsNull(lo_EFA_Client) )
			lcErrMSG = ;
				"Nu a reusit initializarea obiectului [lo_EFA_Client]."+Chr(13)+;
				"pentru recipisa: "+m.Recipisa+Chr(13)+;
				Program()
			*MessageBox(lcErrMSG, 16, "Eroare")
			*Set Step On
			Return lcErrMSG			&& Loop
		EndIf
		*
		lcXmlFactura		= lo_EFA_Client.cXmlString
		lcCaleXML			= lo_EFA_Client.cZipFileName
		*
		If IsNullOrEmpty(lcXmlFactura)
			lcErrMSG = "Nu a reusit descarcarea facturii primite de la furnizor cu recipisa "+m.Recipisa
			MessageBox(lcErrMSG, 16, "Eroare: " + Program())
			Set Step On
			Return lcErrMSG			&& Loop
		EndIf
		*
	EndIf
	*
	llResult			= Not IsNullOrEmpty(lcXmlFactura)
	*AddToLog(Transform(Seconds()-_Start, [999.9999])+[ llResult			= Not IsNullOrEmpty(lcXmlFactura) ], lcLogFile, .T., .T.)
	*
	If llResult
		*
		loXml = CreateObject("Chilkat_9_5_0.Xml")
		* �ncarcare document XML
		llSuccess = loXml.LoadXML( CleanXMLPrefix( lcXmlFactura ) )
		*
		If llSuccess = 0
			lcEroare_loXML = "Eroare la �ncarcarea documentului XML: "  +Chr(13)+ loXml.LastErrorText
			MessageBox(lcEroare_loXML, 16, "Eroare")
			Select EFA_IESIRI
			Loop
		Else
			*
			=eFactura_Parse(loXml)	
			*
			#if .f.
				" ","Factura",2
				"B","Bon de casa FARA cod fiscal",2
				"C","Bon de casa CU cod fiscal",2
				"e","Exceptii utilizare AMEF",2
				"S","Scutit cu drept de deducere",2
				"D","Scutit cu drept de deducere cf.art. 294 (5 lit. a si b)",2
				"d","Scutit cu drept de deducere cf.art. 294 (5 lit. c si d)",2
				"U","TURISM - Servicii cf. art. 311",2
				"H","SECOND HAND - Vanzari cf. art. 312",2
				"n","Operatiuni Neimpozabile",2
			"L","Factura emisa de client",2
			#endif
			lcNumarDoc				= EFA_Invoice_Antet.ID
			ldDataDoc				= SetDateGerman(EFA_Invoice_Antet.IssueDate)
			ldScadenta				= SetDateGerman(EFA_Invoice_Antet.DueDate)
			lcDenumire				= EFA_Invoice_Antet.AccountingCustomerParty_Party_PartyLegalEntity_RegistrationName
			lcCodFiscal				= EFA_Invoice_Antet.AccountingCustomerParty_Party_PartyTaxScheme_CompanyID
			*lcCodValuta			= EFA_Invoice_Antet.LegalMonetaryTotal_PayableAmount_CurrencyId
			lcCodValuta				= EFA_Invoice_Antet.DocumentCurrencyCode
			*lnTotal				= Val(EFA_Invoice_Antet.LegalMonetaryTotal_PayableAmount)
			lnTotal					= Val(EFA_Invoice_Antet.LegalMonetaryTotal_TaxInclusiveAmount)
			lnSuma					= Val(EFA_Invoice_Antet.LegalMonetaryTotal_TaxExclusiveAmount)
			*
			&& 12.08.2024
			*
			*lnTva					= Val(EFA_Invoice_Antet.TaxTotal_TaxAmount)
			lnTva					= lnTotal - lnSuma
			lnTva_RON				= Val(EFA_Invoice_Antet.TaxTotal_TaxAmount_RON)		&& BT-111
			&& 12.08.2024
			*
			lcNote					= EFA_Invoice_Antet.Note
			lnNeachitat				= lnTotal
			ll_TAXARE_INVERSA =;
				EFA_Invoice_Antet.TaxTotal_TaxSubtotal_TaxCategory_ID_0		=	'AE' Or ;
				EFA_Invoice_Antet.TaxTotal_TaxSubtotal_TaxCategory_ID_5		=	'AE' Or ;
				EFA_Invoice_Antet.TaxTotal_TaxSubtotal_TaxCategory_ID_9		=	'AE' Or ;
				EFA_Invoice_Antet.TaxTotal_TaxSubtotal_TaxCategory_ID_19	=	'AE' Or ;
				EFA_Invoice_Antet.TaxTotal_TaxSubtotal_TaxCategory_ID_20	=	'AE'
			* FACTURA achitata cu bon fiscal = 751
			lcTipFactura				= ICase(ll_TAXARE_INVERSA, '', EFA_Invoice_Antet.InvoiceTypeCode='380', '', '')
			*
			lc_CountrySubentity_Judet	= GetWordNum(AllTrim(EFA_Invoice_Antet.AccountingCustomerParty_Party_PostalAddress_CountrySubentity), 2, '-')
			Select DenJud From crs_SQL_TERTI Where AllTrim(Cod)==AllTrim(lc_CountrySubentity_Judet) Into Array aGetJudet_Furnizor
			lcJudet_Client				= Iif(_Tally>0, aGetJudet_Furnizor(1), '')
			lcLocalitate_CityName		= AllTrim(EFA_Invoice_Antet.AccountingCustomerParty_Party_PostalAddress_CityName)
			lcLocalitate				= lcLocalitate_CityName
			lcSector=''
			*lcRCom						= AllTrim(EFA_Invoice_Antet.AccountingCustomerParty_Party_PartyLegalEntity_CompanyLegalForm)
			*lcRegistru					= AllTrim(SubStr(lcRCom, Atc('J', lcRCom), 14))
			lcRegistru					=''
			*
			If 'SECTOR' $ Upper(lcLocalitate_CityName)
				lcLocalitate			= 'BUCURESTI'
				lcSector				= Right(lcLocalitate_CityName, 1)
			EndIf
			*
			lcStrada					= AllTrim(EFA_Invoice_Antet.AccountingCustomerParty_Party_PostalAddress_StreetName)
			llIs_EF = .T.

			*
			Insert Into IesiriANTET;
				(;
				Tip,;
				NumarDoc, DataDoc, DenumireClient, Cod_Fiscal, Is_EF,;
				Scadenta,;
				Cod_Valuta,;		
				Total,;
				Suma,;
				Tva,;
				Tva_RON,;
				Neachitat,;
				Cont,;
				Observatii,;
				AnT,;
				LunaT,;
				cFile,;
				Judet,;
				Localitate,;
				Strada,;
				Sector,;
				Registru;
				, Recipisa;
				);
			Values;
				(;
				lcTipFactura,;
				lcNumarDoc, ldDataDoc, lcDenumire, lcCodFiscal, llIs_EF,;
				ldScadenta,;
				lcCodValuta,;		
				lnTotal,;
				lnSuma,;
				lnTva,;
				lnTva_RON,;
				lnTotal,;
				AllTrim(GetContFromCodFiscalAndSintetic(lcCodFiscal, '411')),;
				lcNote,;
				Year(ldDataDoc),;
				Month(ldDataDoc),;
				IesiriANTET.Cale,;
				lcJudet_Client,;
				lcLocalitate,;
				lcStrada,;
				lcSector,;
				lcRegistru;
				, m.Recipisa;
				)
			*
			*		======= >   Scan LINII	
			*
			Select EFA_Invoice_Linii
			Scan
				*
				Select IesiriLINII
				SCATTER NAME oInvoiceLines BLANK 
				*
				Select EFA_Invoice_Linii
				*
				*InsertLiniiIntrare(toForm, tnIdDOC)
				With oInvoiceLines
					*If .Item_ClassifiedTaxCategory_ID=='AE'
					*	.Tip			= 'T		&&Taxare Inversa'
					*EndIf		
					.IdPozitie			= Val(Id)
					.Recipisa			= m.Recipisa
					.Denumire			= Item_Name					&& Item_Description
					.Um					= InvoicedQuantity_UnitCode
					.Cantitate			= Val(InvoicedQuantity)
					*.TaxScheme			= Item_ClassifiedTaxCategory_TaxScheme_ID
					.ProcTva			= Val(Item_ClassifiedTaxCategory_Percent)
					=GetTvaInfoFromProcent	(.ProcTva,	oInvoiceLines)
					.PretUnitar			= Val(Price_PriceAmount)
					.Valoare			= Val(LineExtensionAmount)
					.Tva				= Round( .Valoare * .ProcTva /100, 2)
					.Total				= .Valoare + .Tva
					.IsPromo			= .F.
					*
				EndWith
				*
				INSERT INTO IesiriLINII FROM NAME oInvoiceLines
				*Set Step On
				*
			EndScan
			*
			Select IesiriLINII
			Locate For IsNullOrEmpty(Cont)
			*
			If Found()
				*
				Select IesiriLINII
				Scan For IsNullOrEmpty(Cont)
					*
					If Seek(IesiriLINII.Denumire, [cGetCont_Iesiri], [Denumire])
						Replace;
								Cont		With cGetCont_Iesiri.Cont;
							,	IdArticol	With cGetCont_Iesiri.IdArticol;
							,	IdTipArt	With cGetCont_Iesiri.IdTipArt;
							,	DenTipArt	With cGetCont_Iesiri.DenTipArt;
							,	IdGest		With cGetCont_Iesiri.IdGest;
							,	DenGest		With cGetCont_Iesiri.DenGest;
						In IesiriLINII
						*
					Else
						*
						m.Cont_Iesiri_Uzual = GetCommontArticolIesireInfo(IesiriLINII.Denumire)
						*
						If Seek(m.Cont_Iesiri_Uzual, [cGetCont_Iesiri], [Cont])
							*
							Replace;
									Cont		With cGetCont_Iesiri.Cont;
								,	IdArticol	With cGetCont_Iesiri.IdArticol;
								,	IdTipArt	With cGetCont_Iesiri.IdTipArt;
								,	DenTipArt	With cGetCont_Iesiri.DenTipArt;
								,	IdGest		With cGetCont_Iesiri.IdGest;
								,	DenGest		With cGetCont_Iesiri.DenGest;
							In IesiriLINII
							*
						Else
							*	
							Replace Cont With m.Cont_Iesiri_Uzual In IesiriLINII
							*
						EndIf
						*	
					EndIf	
					*
				EndScan
				*
			EndIf
			*	
		EndIf
		*
	EndIf
	*
	*=AddToLog(Chr(13)+Chr(10)+Replicate( "-", 80 ), lcLogFile, .T., .T.)
	*=AddToLog(Transform(Seconds()-_StartBegin, [999.9999])+[ *** TOTAL: ]+Chr(13)+Chr(10)+Replicate( "-", 80 ), lcLogFile, .T., .T.)
EndFunc
* __________________________________________________________________________________________________________
Procedure CreareCursoare_INTRARI()
	*
	If Not Used('Documente')
		*
		Create Cursor Documente;
			(;
			Id				I,;
			Data_R			T,;
			Tip				N(2),;
			Tip_ANAF		C(30),;
			Id_Solicit		C(10),;
			Recipisa		C(10),;
			NumarDoc		C(30),;
			DataDoc			D,;
			Scadenta		D,;
			Continut		M,;
			Cod_Fiscal		C(20),;
			Partener		C(64),;
			Cont			C(20),;
			Cale			M,;
			DirPDF			M,;
			CalePDF			M,;
			Importat		N(1),;
			Anulat			N(1),;
			Preluat			N(1),;
			_PROGRAM		C(50),;
			Cod_Valuta		C(3),;
			Suma			N(15, 2),;
			Tva				N(15, 2),;
			Tva_RON			N(15, 2),;
			Total			N(15, 2),;
			Neachitat		N(15, 2),;
			Nir				I,;
			IdGest			I,;
			DenGest			C(60),;
			IdDoc			I,;
			IdUnic			I,;
			Stornat			L,;
			IdDocStorno		I,;
			IsTvaIncasare	L,;
			IsTvaIncasareByUser	L,;			
			NumarOrdine		I,;
			LunaT			N(2, 0) NULL,;
			AnT				N(4, 0) NULL,;		
			Observatii		C(254),;
			DataDocReala	D,;
			cFile			M,;
			Judet			C(15),;
			Localitate		C(70),;
			Strada			C(30),;
			Sector			C(1),;
			Registru		C(15);
			,  InvoiceTypeCode	C(3);
			)
		*Set Filter To Importat=0
		Index On AllTrim(Id_Solicit) Tag Id_Solicit
		Index On AllTrim(Recipisa) Tag Recipisa
		*Index On Data_R Tag Data_R
		Index On DataDoc Tag DataDoc
		Set Order To DataDoc
		*
	EndIf
	*
	If Not Used('DocumenteLinii')
		*
		Create Cursor DocumenteLinii(;
			Recipisa		 C (10),;
			Id               I(4),;
			IdUnic           I(4),;
			IdDoc            I(4),;
			IdPozitie        I(4),;
			IdTipArt         I(4)	NULL,;
			DenTipArt        C(36)	NULL,;
			IdGest           I(4)	NULL,;
			DenGest          C(60)	NULL,;
			Cont             C(20)	NULL,;
			Cont_ORIGINAL    C(20)	NULL,;
			Denumire         C(60),;
			IdArticol        I(4)	NULL,;
			Um               C(5),;
			ProcTva          I(4),;
			CodTva           C(5)	NULL,;
			IdTva            I(4)	NULL,;
			DenumireTva      C(80)	NULL,;
			Cantitate        N(16,4),;
			PretStoc         N(15,5),;
			Valoare          N(13,2),;
			Tva              N(13,2),;
			Total            N(13,2),;
			PretVanzare      N(12,4),;
			PretAmanunt      N(12,4),;
			ProcAdaos        N(7,2),;
			SumaAdaos        N(13,2),;
			ProcDisc         N(13,2),;
			SumaDiscount     N(13,2),;
			PTva_Vanz        N(6,2),;
			Neded            L(1),;
			IdCategorie      I(4) Null,;
			Categorie        C(50) Null,;
			IdBonConsum      I(4),;
			Tip_Ded          C(4),;
			IsPromo          L(1),;
			IdLot            I(4),;
			DenLot           C(50),;
			ExpirareArticol  D(8),;
			Id_SGR           I(4),;
			Ignora           I(4),;
			Sters            L(1);
			, CodBARE									C(13);
			, codNC										C(13);
			, codCPV									C(13);
			, codFurnizor								C(13);
			, Cod_Prod									C(13);
			, Echivalare								C(20);
			)
		Index On Recipisa Tag Recipisa
		*
		Select DocumenteLinii
		Set Filter To Recipisa=Documente.Recipisa
		*
	EndIf
	*
	If Not Used('c_Get_Mesaje_SPV')
		*////////////////////////////////////////////////////////////////
		*// Lista Mesaje
		*
		*=================================================
		
			*	Lista Mesaje � lista de raspunsuri disponibile pentru descarcare:
			*
			* Parametrii raspuns:
			* - data_creare = data raspunsului
			* - cif					= cif-ul pentru care este raspunsul descarcabil
			* - id_solicitare		= indexul de incarcare primit la upload-ul fisierului
			* - detalii				� amanunte despre r�spuns
			* - cif_emitent			= cif-ul emitentului facturii (v�nz�tor)
			* - cif_beneficiar		= cif-ul beneficiarului facturii (cumparator)
			* - tip:
			* 	. FACTURA TRIMISA	= raspuns cu factura originala si semnatura MF, transmis in urma transmiterii unei facturi, daca este validata de sistem
			* 	. FACTURA PRIMITA	= factura primita in calitate de cumparator de la un emitent care a folosit sistemul national privind factura electronica RO e-factura
			* 	. ERORI FACTURA		= raspuns cu erorile si semnatura MF, livrat in urma transmiterii unei facturi, daca NU este validata de sistem
			*	. MESAJ CUMPARATOR PRIMIT / MESAJ CUMPARATOR TRANSMIS
		*=================================================
		*
		*////////////////////////////////////////////////////////////////
		Create Cursor c_Get_Mesaje_SPV;
			(;
			Data_R			T,;
			Id_Solicit		C(10),;
			Recipisa		C(10),;
			Detalii			C(250),;
			Tip				C(30),;
			CIF				C(13),;
			Id_Iesire		N(10, 0),;
			Nr_Iesire		C(20),;
			Data			D,;
			Cod				C(20),;
			Denumire		C(64),;
			Ecran			C(6),;
			PDF				M NOCPTRANS;
			)
	EndIf
	*
EndProc
* __________________________________________________________________________________________________________
Procedure CreareCursoare_IESIRI()
	*
	If Not Used('IesiriANTET')
		*
		Create Cursor IesiriANTET(;
			Tip                  C(1),;
			NumarDoc             C(20),;
			DenumireClient       C(60),;
			DataDoc              D(8),;
			Scadenta             D(8),;
			Suma                 N(16,2),;
			Cod_Valuta			 C(3),;
			LunaT				 N(2, 0) NULL,;
			AnT					 N(4, 0) NULL,;		
			Tva                  N(16,2),;
			Total                N(16,2),;
			Neachitat            N(16,2),;
			DenAgent             V(50),;
			Adaos                N(16,2),;
			Accize               N(16,2),;
			ContDAccize          C(20),;
			ContCAccize          C(20),;
			Comanda              C(16),;
			CursReferinta        N(16,4),;
			IUserWorking         I(4),;
			IdDoc                I(4),;
			Anulat               L(1),;
			Cont                 C(20),;
			Stornat              L(1),;
			IdAgent              I(4),;
			IdUnic               I(4),;
			INumarDoc            I(4),;
			IsWithAutoNumber     L(1),;
			Delegat              V(30),;
			SerieBI              V(2),;
			NumarBI              V(6),;
			EliberatBI           V(20),;
			AutoTip              V(20),;
			AutoNr               V(20),;
			DataExpedierii       D(8),;
			OraeEpedierii        V(5),;
			IdBanca1             I(4),;
			IdBanca2             I(4),;
			IdBanca3             I(4),;
			IdBanca4             I(4),;
			IdBancaClient        I(4),;
			InfSupl              M(4),;
			A4A5                 L(1),;
			IsChitanta           L(1),;
			Observatii           C(254),;
			Inlucru              C(20),;
			CreatDe              V(128),;
			Created              T(8),;
			Modified             T(8),;
			ModifiedBy           V(128),;
			DataDocReala         D(8),;
			NumarOrdine          I(4),;
			IdDocStorno          I(4),;
			IsTvaIncasare        L(1),;
			IsTransfer           L(1),;
			BfTiparit            I(4),;
			TipOp                C(3),;
			Caen                 C(4),;
			BfFacturat           L(1),;
			EmailSent            L(1),;
			Recipisa             C(10),;
			Id_Solicitare        C(10),;
			Id_Descarcare        C(10),;
			Efact_Detalii        C(100),;
			Efact_Tip            C(20),;
			Efact_Stare          C(20),;
			Efact_DataIncarcare  T(8),;
			Is_EF                L(1),;
			Ef_Data_Validare     T(8),;
			cFile				 M,;
			_PROGRAM			 C(50),;
			Cod_Fiscal			 C(20),;
			Judet				 C(15),;
			Localitate			 C(70),;
			Strada				 C(30),;
			Sector				 C(1),;
			Registru			 C(15),;
			Continut			 M,;
			Cale				 M,;
			DirPDF				 M,;
			CalePDF				 M,;
			Importat			 N(1),;
			Preluat				 N(1);
			)
		Index On AllTrim(Id_Solicitare) Tag Id_Solicit
		Index On AllTrim(Recipisa) Tag Recipisa
		Index On DataDoc Tag DataDoc
		Set Order To DataDoc
		*
	EndIf
	*
	If Not Used('IesiriLINII')
		*
		Create Cursor IesiriLINII(;
			IdUnic                         I(4),;
			IdDoc                          I(4),;
			IdPozitie        				I(4),;
			Recipisa             			C(10),;
			IdGest                         I(4) NULL,;
			DenGest                        V(60) NULL,;
			IdArticol                      I(4) NULL,;
			Denumire                       C(60),;
			IdTipArt                       I(4) NULL,;
			DenTipArt                      C(36) NULL,;
			Um                             C(5),;
			ProcTva                        N(3),;
			Cantitate                      N(14,4),;
			PretUnitar                     N(17,4),;
			Valoare                        N(16,2),;
			Tva                            N(16,2),;
			Total                          N(16,2),;
			Adaos                          N(16,2),;
			Cont                           C(20),;
			InformatiiSuplimentareArticol  C(200),;
			Discount                       N(11,5),;
			IdCategorie                    I(4),;
			Categorie                      V(50),;
			IdDocStorno                    I(4),;
			Id                             I(4),;
			IdTva                          I(4),;
			DenumireTva                    V(80),;
			CodTva                         C(5),;
			IdNotaPredare                  I(4),;
			IdLot                          I(4),;
			IsPromo                        L(1),;
			IsTvaIncasare                  L(1),;
			Id_SGR                         I(4);
			)
		Index On Recipisa Tag Recipisa
		*
		If ll_Is_ICAS
			*
			Text To lcSQL NoShow TextMerge
				Select
					i.IdDoc			As Id_Iesire,
					i.Recipisa,
					i.DataDoc,
					i.NumarDoc,
					c.Cod_Fiscal,
					c.Denumire,
					i.IdUnic
				From Iesiri i
					Inner Join Conturi c On c.Cont=i.Cont
				Where
					IsNull(i.Recipisa,'')<>''
					And IsNull(i.Anulat, 0)=0
					And IsNull(c.Sters, 0)=0
			EndText
			*
		Else
			*
			Text To lcSQL NoShow TextMerge
				Select
					ID				As Id_Iesire
					, Recipisa
					, Data_Doc		As DataDoc
					, Factura		As NumarDoc
					, Cod_Fisc		As Cod_Fiscal
					, Denum_Furn	As Denumire
					, Id			As IdUnic
				From Docum
				Where
					Coalesce(Recipisa,'')<>''
			EndText
			*
		EndIf
		=mySQLExec(lcSQL, [c_Iesiri_Recipisa])
		Index On Recipisa Tag Recipisa
		*		
	EndIf
	*
EndProc
* __________________________________________________________________________________________________________
Procedure GetTvaInfoFromProcent(tnProcTva, toInvoiceLines)
	Select;
		CodTva, Denumire, Id;
	From cGetProcTvaIntrari;
	Where;
		ProcTva=tnProcTva;
	Into Array aGetTva
	If _Tally>0
		With toInvoiceLines
			.CodTva=aGetTva(1)
			.DenumireTva=aGetTva(2)
			.IdTva=aGetTva(3)
		EndWith	
	Else
		With toInvoiceLines
			.CodTva=''
			.DenumireTva=''
			.IdTva=Null
		EndWith	
	EndIf
EndProc
* __________________________________________________________________________________________________________
Function GetCommontArticolIntrareInfo(tcDenumireArticol)
	Local lcDenumireArticol, lcContUZUALIntrari
	m.lcContUZUALIntrari	= "6028"
	*
	If Empty(m.tcDenumireArticol)
		Return m.lcContUZUALIntrari
	EndIf	
	*
	m.lcDenumireArticol		= Lower(tcDenumireArticol)
	*
	Do Case
		*
		Case 'rata leasing'			$m.lcDenumireArticol
			m.lcContUZUALIntrari = "167.1"
		*
		Case 'rata dobanda'			$m.lcDenumireArticol
			m.lcContUZUALIntrari = "666"
		*
		Case 'auxiliare'		$m.lcDenumireArticol
			m.lcContUZUALIntrari = "6021"
		*
		Case;
					'combustibil'	$m.lcDenumireArticol;
				Or	'motorina'		$m.lcDenumireArticol;
				Or	'moto. std.'	$m.lcDenumireArticol;
				Or	'moto. p'		$m.lcDenumireArticol;
				Or	'benzina'		$m.lcDenumireArticol;
				Or	'disesel'		$m.lcDenumireArticol;
				Or	'euroluk'		$m.lcDenumireArticol;
				Or	' gpl '			$m.lcDenumireArticol;
				Or	'taxa ulei'		$m.lcDenumireArticol;
				Or	'taxa mediu ulei'$m.lcDenumireArticol;
				Or	'adlue'		$m.lcDenumireArticol
			m.lcContUZUALIntrari = "6022"
		*
		Case 'ambalate'		$m.lcDenumireArticol
			m.lcContUZUALIntrari = "6023"
		*
		Case;
					'piese'			$m.lcDenumireArticol;
				Or	'filtru'		$m.lcDenumireArticol;
				Or	'disc frana'	$m.lcDenumireArticol;
				Or	'placute frana'	$m.lcDenumireArticol;
				Or	'ulei '			$m.lcDenumireArticol;
				Or	'garnitura'		$m.lcDenumireArticol;
				Or	'garnitura'		$m.lcDenumireArticol;
				Or	'perna aer'		$m.lcDenumireArticol;
				Or	'colier '		$m.lcDenumireArticol;
				Or	'pompa apa'		$m.lcDenumireArticol;
				Or	'parbriz'		$m.lcDenumireArticol;
				Or	'stergator'		$m.lcDenumireArticol;
				Or	'chinga'		$m.lcDenumireArticol;
				Or	'suport roata'	$m.lcDenumireArticol;
				Or	'clema fixare'	$m.lcDenumireArticol;
				Or	'curea tr'		$m.lcDenumireArticol
			m.lcContUZUALIntrari = "6024"
		*
		Case;
					'seminte'	$m.lcDenumireArticol;
				Or	'plantat'	$m.lcDenumireArticol
			m.lcContUZUALIntrari = "6025"
		*
		Case 'furaje'			$m.lcDenumireArticol
			m.lcContUZUALIntrari = "6026"
		*
		Case;
					'materiale'	$m.lcDenumireArticol;
				Or	'imbuteliat'$m.lcDenumireArticol;
				Or	'screnwash'	$m.lcDenumireArticol;
				Or	'ciment'	$m.lcDenumireArticol;
				Or	'spray'		$m.lcDenumireArticol;
				Or	'nisip'		$m.lcDenumireArticol;
				Or	'diverse'	$m.lcDenumireArticol				
			m.lcContUZUALIntrari = "6028"
		*
		Case;
					'energie'	$m.lcDenumireArticol;
				Or	'electrica'	$m.lcDenumireArticol				
			m.lcContUZUALIntrari = "6051"
		*
		Case 'apa'				$m.lcDenumireArticol
			m.lcContUZUALIntrari = "6052"
		*
		Case 'gaze'				$m.lcDenumireArticol
			m.lcContUZUALIntrari = "6053"
		*
		Case 'biologice'		$m.lcDenumireArticol
			m.lcContUZUALIntrari = "606"
		*
		Case 'cheltuieli cu marfuri'$m.lcDenumireArticol
			m.lcContUZUALIntrari = "607"
		*
		Case 'ambalaje'				$m.lcDenumireArticol
			m.lcContUZUALIntrari = "608"
		*
		Case;
					'reducere comerciala'	$m.lcDenumireArticol;
				Or	'reduceri comerciala'	$m.lcDenumireArticol
			m.lcContUZUALIntrari = "609"
		*
		Case;
					'intretinere'	$m.lcDenumireArticol;
				Or	'reparatii'		$m.lcDenumireArticol
			m.lcContUZUALIntrari = "611"
		*
		Case;
					'redevent'		$m.lcDenumireArticol;
				Or	'de gestiune'	$m.lcDenumireArticol;
				Or	'chirie'		$m.lcDenumireArticol
			m.lcContUZUALIntrari = "612"
		*
		Case;
					'primele'		$m.lcDenumireArticol;
				Or	'asigurare'		$m.lcDenumireArticol
			m.lcContUZUALIntrari = "613"
		*
		Case;
					'studii'		$m.lcDenumireArticol;
				Or	'cercetar'		$m.lcDenumireArticol
			m.lcContUZUALIntrari = "614"
		*
		Case 'pregatirea personalului'	$m.lcDenumireArticol
			m.lcContUZUALIntrari = "614"
		*
		Case;
					'comisioanele'	$m.lcDenumireArticol;
				Or	'onorari'		$m.lcDenumireArticol
			m.lcContUZUALIntrari = "622"
		*
		Case 'protocol'	$m.lcDenumireArticol
			m.lcContUZUALIntrari = "6231"
		*
		Case;
					'reclma'		$m.lcDenumireArticol;
				Or	'publicitate'	$m.lcDenumireArticol
			m.lcContUZUALIntrari = "6232"
		*
		Case 'transportul de bunuri si personal'$m.lcDenumireArticol
			m.lcContUZUALIntrari = "624"
		*
		Case;
					'deplasari'		$m.lcDenumireArticol;
				Or	'detasari'		$m.lcDenumireArticol;
				Or	'transferuri'	$m.lcDenumireArticol
			m.lcContUZUALIntrari = "625"
		*
		Case;
					'postale'		$m.lcDenumireArticol;
				Or	'telecomunic'	$m.lcDenumireArticol
			m.lcContUZUALIntrari = "626"
		*
		Case;
					'servicii'		$m.lcDenumireArticol;
				Or	'executate'		$m.lcDenumireArticol;
				Or	'terti'			$m.lcDenumireArticol;
				Or	'abonament'		$m.lcDenumireArticol;
				Or	'prestari'		$m.lcDenumireArticol;
				Or	'curierat'		$m.lcDenumireArticol;
				Or	'verificare'	$m.lcDenumireArticol;
				Or	'colectare'		$m.lcDenumireArticol;
				Or	'transport'		$m.lcDenumireArticol;
				Or	'manopera'		$m.lcDenumireArticol;
				Or	'mentenanta'	$m.lcDenumireArticol;
				Or	'montat'		$m.lcDenumireArticol;
				Or	'onorariu'		$m.lcDenumireArticol;
				Or	'itp '			$m.lcDenumireArticol;
				Or	' itp'			$m.lcDenumireArticol;
				Or	'comision'		$m.lcDenumireArticol;
				Or	'consult'		$m.lcDenumireArticol;
				Or	'cheltuieli transport'$m.lcDenumireArticol;
				Or	'rovinieta'		$m.lcDenumireArticol
			m.lcContUZUALIntrari = "628"
		*
		Case;
					'impozit'		$m.lcDenumireArticol;
				Or	'taxe'			$m.lcDenumireArticol				
			m.lcContUZUALIntrari = "635"
		*
		Case 'rovigneta'	$m.lcDenumireArticol
			m.lcContUZUALIntrari = "635.4"
		*
		Case;
					'despagubiri'	$m.lcDenumireArticol;
				Or	'amenzi'		$m.lcDenumireArticol;
				Or	'amenda'		$m.lcDenumireArticol;
				Or	'penalitati'	$m.lcDenumireArticol;
				Or	'penalizari'	$m.lcDenumireArticol
			m.lcContUZUALIntrari = "6581"
		*
		Case 'donati'	$m.lcDenumireArticol
			m.lcContUZUALIntrari = "6582"
		*
		Case 'sponsoriz'	$m.lcDenumireArticol
			m.lcContUZUALIntrari = "6584"
		*
		Case;
					'sconturi'	$m.lcDenumireArticol;
				Or	'discount'	$m.lcDenumireArticol
			m.lcContUZUALIntrari = "767"				&&609
		*
		Case 'tichete'			$m.lcDenumireArticol
			m.lcContUZUALIntrari = "5328"
		*
	EndCase
	*
	If IsNullOrEmpty( m.lcContUZUALIntrari )
		m.lcContUZUALIntrari	= "6028"
	EndIf
	*	
	Return m.lcContUZUALIntrari
	*
EndFunc
* __________________________________________________________________________________________________________
Function GetCommontArticolIesireInfo(tcDenumireArticol)
	Local lcDenumireArticol, lcContUZUALIntrari
	m.lcContUZUALIesiri	= "704"
	*
	If Empty(m.tcDenumireArticol)
		Return m.lcContUZUALIesiri
	EndIf
	*	
	m.lcDenumireArticol	= Lower(tcDenumireArticol)
	*
	Do Case
		*
		Case 'finite'			$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7015"
		*
		Case 'agricole'			$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7017"
		*
		Case 'biologice'		$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7018"
		*
		Case 'semifabricate'	$m.lcDenumireArticol
			m.lcContUZUALIesiri = "702"
		*
		Case 'reziduale'		$m.lcDenumireArticol
			m.lcContUZUALIesiri = "703"
		*
		Case 'prestari'			$m.lcDenumireArticol
			m.lcContUZUALIesiri = "704"
		*
		Case 'studii'			$m.lcDenumireArticol Or 'cercetari'			$m.lcDenumireArticol
			m.lcContUZUALIesiri = "705"
		*
		Case 'redevent'			$m.lcDenumireArticol Or 'gestiune'			$m.lcDenumireArticol Or 'chiri'			$m.lcDenumireArticol
			m.lcContUZUALIesiri = "706"
		*
		Case 'marfa'			$m.lcDenumireArticol
			m.lcContUZUALIesiri = "707"
		*
		Case 'diverse'			$m.lcDenumireArticol
			m.lcContUZUALIesiri = "708"
		*
		Case 'reduceri comerciale'	$m.lcDenumireArticol
			m.lcContUZUALIesiri = "709"
		*
		Case 'necorporale'		$m.lcDenumireArticol
			m.lcContUZUALIesiri = "721"
		*
		Case 'corporale'		$m.lcDenumireArticol
			m.lcContUZUALIesiri = "722"
		*
		Case 'imobiliare'		$m.lcDenumireArticol
			m.lcContUZUALIesiri = "725"
		*
		Case 'subventii'		$m.lcDenumireArticol And 'cifrei de afaceri'			$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7411"
		*
		Case 'subventii'		$m.lcDenumireArticol And 'materii prime si materiale'	$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7412"
		*
		Case 'subventii'		$m.lcDenumireArticol And 'alte cheltuieli externe'		$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7413"
		*
		Case 'subventii'		$m.lcDenumireArticol And 'plata personalului'			$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7414"
		*
		Case 'subventii'		$m.lcDenumireArticol And 'protectie sociala'			$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7415"
		*
		Case 'subventii'		$m.lcDenumireArticol And 'alte cheltuieli de exploatare'$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7416"
		*
		Case 'subventii'		$m.lcDenumireArticol And 'calamitatai'					$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7417"
		*
		Case 'subventii'		$m.lcDenumireArticol And 'dob�nda datorata'				$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7418"
		*
		Case 'subventii'		$m.lcDenumireArticol And 'altor cvenituri'				$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7419"
		*
		Case 'fiduciei'			$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7511"
		*
		Case 'constituirea fiduciei'				$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7511"
		*
		Case 'derularea operatiunilor de fiducie'	$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7512"
		*
		Case 'lichidarea operatiunilor de fiducie'	$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7513"
		*
		Case 'creante reactivate si debitori diversi'	$m.lcDenumireArticol
			m.lcContUZUALIesiri = "754"
		*
		Case 'reevaluate'		$m.lcDenumireArticol
			m.lcContUZUALIesiri = "755"
		*
		Case 'despagubiri'		$m.lcDenumireArticol Or 'amenzi'		$m.lcDenumireArticol Or 'penalitati'		$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7581"
		*
		Case 'donatii'			$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7582"
		*
		Case 'activelor'		$m.lcDenumireArticol Or 'capital'		$m.lcDenumireArticol 
			m.lcContUZUALIesiri = "7583"
		*
		Case 'subventii'		$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7584"
		*
		Case 'speciale'			$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7586"
		*
		Case 'venituri exploatare'	$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7588"
		*
		Case 'entitati afiliate'	$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7611"
		*
		Case 'entitati asociate'	$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7612"
		*
		Case 'controlate in comun'	$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7613"
		*
		Case 'alte imobilizari financiare'	$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7615"
		*
		Case 'investitii financiare pe termen scurt'	$m.lcDenumireArticol
			m.lcContUZUALIesiri = "762"
		*
		Case 'imobilizari financiare cedate'	$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7641"
		*
		Case 'investitii pe termen scurt cedate'$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7642"
		*
		Case 'monetare exprimate �n valuta'$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7651"
		*
		Case 'investitia neta �ntr-o entitate straina'$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7652"
		*
		Case 'Venituri din dob�nzi'$m.lcDenumireArticol
			m.lcContUZUALIesiri = "766"
		*
		Case 'sconturi'$			m.lcDenumireArticol
			m.lcContUZUALIesiri = "767"
		*
		Case 'alte venituri financiare'$m.lcDenumireArticol
			m.lcContUZUALIesiri = "768"
		*
		Case 'provizioane'$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7812"
		*
		Case 'deprecierea imobilizarilor'$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7813"
		*
		Case 'deprecierea activelor circulante'$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7814"
		*
		Case 'fondul comercial'$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7815"
		*
		Case 'avansuri acordate furnizorilor'$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7818"
		*
		Case 'pierderea de valoare a imobilizarilor financiare'$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7863"
		*
		Case 'pierderea de valoare a activelor circulante'$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7864"
		*
		Case 'aferente titlurilor de stat'$m.lcDenumireArticol
			m.lcContUZUALIesiri = "7865"
		*
		Case 'impozitul pe profit'	$	m.lcDenumireArticol
			m.lcContUZUALIesiri = "794"
		*
	EndCase
	*
	If IsNullOrEmpty( m.lcContUZUALIesiri )
		m.lcContUZUALIesiri = "704"
	EndIf
	*
	Return m.lcContUZUALIesiri
	*
EndFunc
* __________________________________________________________________________________________________________
Function CheckDownloadLimit_ANAF()
	*	 50	/	secunda
	*	100	/	minut
	lnSpikeArrestCounter = lnSpikeArrestCounter+1
	lnTotalCallCounter = lnTotalCallCounter+1
	If lnSpikeArrestCounter=50
		*Wait Window TimeOut 0.1 " SpikeArrest, asteptam 1 secunda..."
		lnSpikeArrestCounter = 1
	EndIf
EndFunc
* __________________________________________________________________________________________________________
Function Send_Mesaj_EFA( tcStandard, tcToken, tcCodFiscal, tlIsProd, tcFisier, tlIsExtern)
	lcURL=IIf(tlIsProd,"https://api.anaf.ro/prod/FCTEL/rest/upload?standard=","https://api.anaf.ro/test/FCTEL/rest/upload?standard=")+AllTrim(tcStandard)+"&cif="+AllTrim(tcCodFiscal)+IIf(tlIsExtern,"&Extern=DA","")
	*MessageBox(lcURL)
	lcData = ""
	oHttp = _GetObject('http')
	oHttp.Open("POST", lcURL, .F.)
	oHttp.SetRequestHeader('Content-Type', 'text/xml')
	oHttp.SetRequestHeader('Authorization', "Bearer "+tcToken)
	lcData = FileToStr(tcFisier)
	oHttp.Send((lcData))
	lcRaspuns = ""
	*
	If oHttp.Status=200 .Or. oHttp.Status=201
		*
		lcRaspunsBrut = oHttp.ResponseText
		*
		If 'index_incarcare='$lcRaspunsBrut
			lcRaspuns = "_index:"+StrExtract(lcRaspunsBrut, 'index_incarcare="', '"')
		Else
			If 'errorMessage='$lcRaspunsBrut
				lcRaspuns = "_error:"+StrExtract(lcRaspunsBrut, 'errorMessage="', '"')
			Else
				lcRaspuns = lcRaspunsBrut
			EndIf
		EndIf
		*
	Else
		*
		lcMesaj = ""
		*
		If Empty(oHttp.ResponseText)
			If Lower(AllTrim(oHttp.StatusText))="forbidden"
				lcMesaj = "_error:Nu aveti drepturi de incarcare pe acest cod fiscal, sau codul SPV este expirat. Anulati codul curent si generati-l din nou."
			EndIf
		Else
			lcMesaj = "_error:"+AllTrim(oHttp.StatusText)
		EndIf
		*
		lcRaspuns = lcMesaj
		*
	EndIf
	*
	Return lcRaspuns
	*
EndFunc
* __________________________________________________________________________________________________________
Procedure Save_EFA_History(lnIdFactura, lcOperatiune, lcIdSolicit, lcRecipisa, lcCale)
	ldData = DateTime()
	lnID = GetIdUnicSoc()
	*
	Text To lcSQL NoShow TextMerge
		INSERT INTO EFA_History
		(Id,	Id_Factura,		Data,		Operatiune,		Id_Solicit,		Recipisa,		Cale)
		VALUES 
		(?lnID,	?lnIdFactura,	?ldData,	?lcOperatiune,	?lcIdSolicit,	?lcRecipisa,	?lcCale)
	EndText
	mySQLExec(lcSQL)
	*
EndProc
* __________________________________________________________________________________________________________
Function MakeDirectory(tcFolder)
	If Directory(tcFolder)
		Return .T.
	Else
		Md (tcFolder)
	EndIf
	If  .Not. Directory(tcFolder)
		MessageBox("Directorul "+AllTrim(tcFolder)+" nu a putut fi creat in mod automat."+Chr(13)+"Definiti manual acest director."+Chr(13)+Chr(13)+"Verificati drepturile asupra acestui director, din setarile sistemului de operare.", 016, "Eroare...")
		Return .F.
	EndIf
	Return .T.
EndFunc
* __________________________________________________________________________________________________________
Function Get_EFA_From_Zip(tcZipFile, tcID_Solicitare, tcRecipisa, tnInvoiceType )
	*
	__Consola( '--------------------------------------------------------')
	__Consola( [Program(): ( ]		+ Transform(Program())			+ [ )] )
	__Consola( [] )
	__Consola( [PARAMETERS:  ])	
	__Consola( [tcZipFile: ( ]		+ Transform(tcZipFile)			+ [ )] )
	__Consola( [tcID_Solicitare: ( ]+ Transform(tcID_Solicitare)	+ [ )] )
	__Consola( [tcRecipisa: ( ]		+ Transform(tcRecipisa)			+ [ )] )
	__Consola( [tnInvoiceType : ( ]	+ Transform(tnInvoiceType )		+ [ )] )
	__Consola( '--------------------------------------------------------')
	*	
	If Empty(tcID_Solicitare)
		lcErr = "Variabila tcID_Solicitare este EMPTY"
	    __Consola(lcERR)
		Return lcErr
	EndIf
	*
	*=================================================
	lcXMLFile = ExtractZIP(tcZipFile,  tnInvoiceType, tcID_Solicitare, tcRecipisa)
	__Consola( [lcXMLFile: ( ] + Transform(lcXMLFile) + [ )] )
	lcXMLFromMemory = CleanXMLPrefix( FileToStr(lcXMLFile) )
	*__Consola( [lcXMLFromMemory: ( ] + Transform(lcXMLFromMemory) + [ )] )
	__Consola( [lcXMLFromMemory: ( ] )
	*	
	*=================================================
	*
	Local lcNumarDoc As String, ldDataDoc As Date
	Store '' To lcNumarDoc
	Store {} To ldDataDoc
	*
	*=================================================
	loXml = CreateObject('Chilkat_9_5_0.Xml')	
	__Consola( [loXml: ( ] + Transform(loXml) + [ )] )	
	*=================================================
	*
	loXml.LoadXml(lcXMLFromMemory)
	*=================================================
	lcNumarDoc								= loXml.GetChildContent("*:ID")
	ldDataDoc_ReadFromXML					= loXml.GetChildContent("*:IssueDate")
	ldDataDoc								= CToD( ANSI2MDY( loXml.GetChildContent("*:IssueDate") ) )
	__Consola("ldDataDoc_ReadFromXML: ( "	+ Transform(ldDataDoc_ReadFromXML) + [ )] )
	__Consola("lcNumarDoc: ( "				+ lcNumarDoc)
	__Consola("ldDataDoc: ( "				+ Transform(ldDataDoc ) + [ )] )
	*
	Local lo_EFA As Object
	lo_EFA = CreateObject('SmallClass')
	__Consola("lo_EFA: ( " + Transform(lo_EFA) + [ )] )
	*		
	With lo_EFA
		.AddProperty('Id_Solicit',		tcID_Solicitare)
		.AddProperty('Recipisa',		tcRecipisa)
		.AddProperty('cZipFileName',	tcZipFile)
		.AddProperty('cXMLFile',		lcXMLFile)
		.AddProperty('cXmlString',		lcXMLFromMemory)
		.AddProperty('cNumarDoc',		lcNumarDoc)
		.AddProperty('dDataDoc',		ldDataDoc )
		*
	EndWith
	*
	__Consola( [Return lo_EFA] )
	__Consola( '--------------------------------------------------------')	
	Return lo_EFA
	*
EndFunc
* __________________________________________________________________________________________________________
Function Get_FullPath_Zip_File( tcRecipisa, tnTypeInvoice )
	*
	__Consola([--------------------------------------------------------])
	__Consola( [Program():		( ] + Transform(Program()) + [ )] )
	__Consola( [] )
	__Consola( [PARAMETERS:  ])
	__Consola( [tcRecipisa:		( ] + Transform(tcRecipisa) + [ )] )
	__Consola( [tnTypeInvoice:	( ] + Transform(tnTypeInvoice) + [ )] )
	__Consola([--------------------------------------------------------])
	*
	LOCAL loDirTree, lnSuccess, lnDoneIterating, lc_FullPath_Zip_File
	lc_FullPath_Zip_File = ''
	*
	loDirTree = CreateObject('Chilkat_9_5_0.DirTree')
	* Specify the root of the directory tree to be traversed.
	lc_Folder_eFactura = Get_Folder_EFactura_BASE(	tnTypeInvoice 	)
	__Consola( [lc_Folder_eFactura = Get_Folder_EFactura_BASE(	tnTypeInvoice 	)] )
	__Consola( [lc_Folder_eFactura: ( ] + Transform(lc_Folder_eFactura) + [ )] )
	loDirTree.BaseDir = lc_Folder_eFactura
	
	* Indicate that we want to recursively traverse the tree.
	loDirTree.Recurse = 1
	*loDirTree.Recurse = 0

	* Begin the directory tree traversal.
	lnSuccess = loDirTree.BeginIterate()
	__Consola( [lnSuccess = loDirTree.BeginIterate()] )
	IF (lnSuccess <> 1) THEN
		lcErr = loDirTree.LastErrorText
	    ? lcErr
	    RELEASE loDirTree
	    
		__Consola([Return lc_FullPath_Zip_File])
		__Consola([--------------------------------------------------------])
	    Return lc_FullPath_Zip_File
	    
	    *CANCEL
	ENDIF

	lnDoneIterating = loDirTree.DoneIterating
	__Consola( [lnDoneIterating = loDirTree.DoneIterating] )
	DO WHILE lnDoneIterating <> 1

	    * Examine the file or directory at the current traversal position:
	    IF (loDirTree.IsDirectory = 1) THEN
			*? "(sub-directory)"
	    ELSE
			*
			*
			If Lower(tcRecipisa) $ Lower(loDirTree.RelativePath) And Lower(JustExt(loDirTree.RelativePath))='zip'
				*
				__Consola( [If Lower(tcRecipisa) $ Lower(loDirTree.RelativePath) And Lower(JustExt(loDirTree.RelativePath))='zip'] )
				lc_FullPath_Zip_File = loDirTree.FullPath
				__Consola( [loDirTree.RelativePath(): ( ] + Transform(loDirTree.RelativePath) + [ )] )
				__Consola( [lc_FullPath_Zip_File = loDirTree.FullPath] )
				__Consola( [lc_FullPath_Zip_File: ( ] + Transform(lc_FullPath_Zip_File) + [ )] )
				*? "Absolute Path: "	+ lc_FullPath_Zip_File
				EXIT
				*	
			EndIf
			*
			*? "Size in bytes: " + STR(loDirTree.FileSize32)
			** If the file size is larger than 2GB, then get the size as a decimal string.
			** (Chilkat provides a FileSize64 method in *some* programming languages. 
			** The FileSizeStr property is added in Chilkat v9.5.0.88)
			*? "Size in bytes: " + loDirTree.FileSizeStr
	    ENDIF

		*? "Relative Path: "		+ loDirTree.RelativePath
		*? "Absolute Path: "		+ loDirTree.FullPath
		*? "Absolute UNC Path: "	+ loDirTree.FullUncPath

	    * Advance to the next file or sub-directory in the tree traversal.
	    lnSuccess = loDirTree.AdvancePosition()
	    IF (lnSuccess <> 1) THEN
	        IF (loDirTree.DoneIterating <> 1) THEN
	            ? loDirTree.LastErrorText
	            RELEASE loDirTree
	            Return lc_FullPath_Zip_File
	            
	            *CANCEL
	        ENDIF

	    ENDIF

	    lnDoneIterating = loDirTree.DoneIterating
	ENDDO

	RELEASE loDirTree

	__Consola( [lc_FullPath_Zip_File: ]+Transform(lc_FullPath_Zip_File) + [ )] )
	__Consola( [Return lc_FullPath_Zip_File])
	__Consola( '--------------------------------------------------------')
	Return lc_FullPath_Zip_File
	*
EndFunc
* __________________________________________________________________________________________________________
Function Create_EFA_Furnizor ( tcZipFileName, tcID_Solicitare, tlSkip_Insert, tlSkipWriteZipFile )
	*
	Local lcZip As String, lcXMLFromMemory As String
	Store '' To lcZip, lcXMLFromMemory
	*
	lcXML = tcID_Solicitare+".xml"
	__Consola( [lcXML: ]+Transform(lcXML) + [ )] )
	*
	*=================================================
	loZip = CreateObject('Chilkat_9_5_0.Zip')
	*=================================================
	__Consola( [loZip = CreateObject('Chilkat_9_5_0.Zip'): ]+Transform(loZip) + [ )] )
	*		
	lnSuccess = loZip.OpenBd(loResponse)
	__Consola( [loZip.OpenBd(loResponse): ]+Transform(lnSuccess) + [ )] )
	*
	If (lnSuccess = 0) THEN
		lcDescRaspuns = "ZIP incorect"
		__Consola( [lcDescRaspuns: ]+Transform(lcDescRaspuns) + [ )] )
		loResponse.WriteFile(lcID_Solicitare + '_EROARE_ZIP incorect.txt')
		__Consola( [loResponse.WriteFile(lcID_Solicitare + '_EROARE_ZIP incorect.txt')] )
		lcEroare_loResponse = FileToStr(lcID_Solicitare + '_EROARE_ZIP incorect.txt')
		lcEroare_loRest = ICAS.oRest_ANAF.LastErrorText
		lcEroare_loZip = loZip.LastErrorText
	    __Consola("api.anaf.ro: zip incorect: "+ lcEroare_loResponse+Chr(13)+lcEroare_loRest+Chr(13)+lcEroare_loZip)
	    *
		RELEASE loResponse, loZip 
		RETURN "api.anaf.ro: zip incorect "+lcEroare_loResponse+Chr(13)+lcEroare_loRest+Chr(13)+lcEroare_loZip
	EndIf
	*
	Local lcNumarDoc As String, ldDataDoc As Date
	Store '' To lcNumarDoc
	Store {} To ldDataDoc
	*
	*=================================================
	loXml = CreateObject('Chilkat_9_5_0.Xml')
	*=================================================
	__Consola( [loXml = CreateObject('Chilkat_9_5_0.Xml'): ]+Transform(loXML) + [ )] )			
	lnNumEntries = loZip.NumEntries
	__Consola( [loZip.NumEntries: ]+Transform(lnNumEntries) + [ )] )
	*
	For i = 0 TO lnNumEntries-1
		*
	    loEntry = loZip.GetEntryByIndex(i)
	    __Consola( [i: ]+Transform(i) + [ )] )
	    __Consola( [loEntry = loZip.GetEntryByIndex(i): ]+Transform(loEntry) + [ )] )
	    *
	    ll_Found_lcXML = loEntry.FileName = lcXML
	    *
		IF ll_Found_lcXML
			*
			__Consola( [loEntry.FileName = lcXML: ]+Transform(ll_Found_lcXML) + [ )] )
			*
			lcXMLFromMemory = CleanXMLPrefix( loEntry.UnzipToString(0,"utf-8") )		&& OpenFromMemory
			 *__Consola("lcXMLFromMemory: ( " + lcXMLFromMemory)
			loXml.LoadXml(lcXMLFromMemory)
			*
			__Consola( [loXml.LoadXml(lcXMLFromMemory)] )
			*
			*lcNumarDoc	= loXml.GetChildContent("*:ID")
			lcNumarDoc	= GetNumeFisierSafe(	loXml.GetChildContent("*:ID")	)	&&-- 05.11.2024
			ldDataDoc_ReadFromXML = loXml.GetChildContent("*:IssueDate")
			*
			__Consola("ldDataDoc_ReadFromXML: ( "	+ Transform(ldDataDoc_ReadFromXML) + [ )] )
			*
			ldDataDoc = CToD( ANSI2MDY( loXml.GetChildContent("*:IssueDate") ) )
			*
			__Consola("lcNumarDoc: ( "+ lcNumarDoc)
			__Consola("ldDataDoc: ( "	+ Transform(ldDataDoc ) + [ )] )
			*
			lcZip = GetFolder_EFactura(ldDataDoc, 2) + lcNumarDoc + '_'+lcRecipisa+'_'+Transform(DToS(ldDataDoc), '@R ####-##-##')+".zip"
			*
			If Empty(ldDataDoc)
				*
				lcMesaj			= loXml.GetAttrValue("message")
				*
				If IsNullOrEmpty(lcMesaj)
					MessageBox(Program() + Chr(13) + 'Nu a reusit extragerea elementului [Data factura] din fisierul XML.', 16, "Eroare", 1500)
					Set Step On
				EndIf
				*
			EndIf
			*			
			__Consola("lcZip: ( "	+ Transform(lcZip) + [ )] )
			*
			lcCodFiscalFactura= loXml.GetChildContent("*:AccountingSupplierParty|*:Party|*:PartyTaxScheme|*:CompanyID")
			__Consola("lcCodFiscalFactura: ( "	+ Transform(lcCodFiscalFactura) + [ )] )
			*
			ll_IsNullOrEmpty_lcCodFiscalFactura = IsNullOrEmpty(lcCodFiscalFactura)
			*
			If ll_IsNullOrEmpty_lcCodFiscalFactura 
				__Consola("lcCodFiscalFactura: ( "	+ Transform(ll_IsNullOrEmpty_lcCodFiscalFactura ) + [ )] )
				lcCodFiscalFactura	= loXml.GetChildContent("*:AccountingSupplierParty|*:Party|*:PartyLegalEntity|*:CompanyID")
				__Consola("lcCodFiscalFactura: ( "	+ Transform(lcCodFiscalFactura) + [ )] )
			EndIf
			*
			lcCodFiscalFactura = OnlyNumber(lcCodFiscalFactura)
			lcDenumireFurnizor = loXml.GetChildContent("*:AccountingSupplierParty|*:Party|*:PartyLegalEntity|*:RegistrationName")
			__Consola("lcDenumireFurnizor: ( "	+ Transform(lcDenumireFurnizor) + [ )] )
			*
			If Not tlSkip_Insert
				*
				ll_SEEK = Seek(lcINDEX, 'Documente', 'Recipisa')
				*Inserez in FORM
				*				
				If ll_SEEK
					__Consola("Seek(lcINDEX, 'Documente', 'Recipisa'): ( " + Transform(ll_SEEK) + [ )] )
					*
					Update;
						Documente;
					Set;
						Continut	= lcXMLFromMemory,;
						Cale		= lcZip,;
						DataDoc		= ldDataDoc,;
						NumarDoc	= lcNumarDoc;
					Where;
						Recipisa=lcINDEX
					*
					__Consola("Update Documente Set Continut..., Cale... Where Recipisa=lcINDEX")
				Else		If ll_SEEK
					*
					__Consola("ll_SEEK: ( " + Transform(ll_SEEK) + [ )] )
					Store 0 To lnImportat, lnIdDoc
					*
					If Used('EFA_INTRARI')
						*
						*If EFA_INTRARI.Tip='MESAJ CUMPARATOR PRIMIT'
						*	Set Step On
						*EndIf	
						*
						Insert Into Documente ;
						(Data_R, Tip_ANAF, Id_Solicit, Recipisa,;
						 DataDoc, NumarDoc, Continut, Cod_Fiscal, Partener, Cale, Preluat, Importat, IdDoc, _PROGRAM);
						Values;
						(;
						EFA_INTRARI.Data_R,;
						EFA_INTRARI.Tip, EFA_INTRARI.Id_Solicitare, EFA_INTRARI.Recipisa,;
						ldDataDoc, lcNumarDoc,  lcXMLFromMemory, lcCodFiscalFactura, lcDenumireFurnizor, lcZip, 0, lnImportat, lnIdDoc, Program())
						*
					Else
						*
						*If c_Get_Mesaje_SPV.Tip='MESAJ CUMPARATOR PRIMIT'
						*	Set Step On
						*EndIf
						*					
						Insert Into Documente ;
						(Data_R, Tip_ANAF, Id_Solicit, Recipisa,;
						 DataDoc, NumarDoc, Continut, Cod_Fiscal, Partener, Cale, Preluat, Importat, IdDoc, _PROGRAM);
						Values;
						(c_Get_Mesaje_SPV.Data_R, c_Get_Mesaje_SPV.Tip, c_Get_Mesaje_SPV.Id_Solicit, c_Get_Mesaje_SPV.Recipisa,;
						 ldDataDoc, lcNumarDoc,  lcXMLFromMemory, lcCodFiscalFactura, lcDenumireFurnizor, lcZip, 0, lnImportat, lnIdDoc, Program())
					EndIf	 
					*
					__Consola("Insert Into Documente (DataDoc,NumarDoc,Continut,Cale ...")
					*
				EndIf	If ll_SEEK
				*
			EndIf		If Not tlSkip_Insert
			*	
		EndIf
		*
	EndFor
	*
	If Not Empty(lcZip)	And tlSkipWriteZipFile=.F.
		loResponse.WriteFile(lcZip)
		__Consola( [loResponse.WriteFile(lcZip): ] + Transform(lcZip) + [ )] )
	EndIf	
	*
	loZip.CloseZip()
	__Consola( [loZip.CloseZip()] )
	*
	RELEASE loResponse, loZip
	*
	Local o_EFA_Furnizor As Object
	o_EFA_Furnizor=CreateObject('SmallClass')
	__Consola( [o_EFA_Furnizor=CreateObject('SmallClass'): ] + Transform(o_EFA_Furnizor) + [ )] )
	*		
	With o_EFA_Furnizor
		.AddProperty('Id_Solicit',		lcID_Solicitare)
		.AddProperty('Recipisa',		lcRecipisa)
		.AddProperty('cZipFileName',	lcZip)
		.AddProperty('cXmlString',		lcXMLFromMemory)
		.AddProperty('cNumarDoc',		lcNumarDoc)
		.AddProperty('dDataDoc',		ldDataDoc )
		__Consola("o_EFA_Furnizor.Id_Solicit:	( "	+ Transform(o_EFA_Furnizor.Id_Solicit)		+ [ )] )		
		__Consola("o_EFA_Furnizor.Recipisa:		( "	+ Transform(o_EFA_Furnizor.Recipisa)		+ [ )] )		
		__Consola("o_EFA_Furnizor.cZipFileName:	( "	+ Transform(o_EFA_Furnizor.cZipFileName)	+ [ )] )		
		*__Consola("o_EFA_Furnizor.cXmlString:	( "	+ Transform(o_EFA_Furnizor.cXmlString)		+ [ )] )		
		__Consola("o_EFA_Furnizor.cNumarDoc:	( "	+ Transform(o_EFA_Furnizor.cNumarDoc)		+ [ )] )
		__Consola("o_EFA_Furnizor.dDataDoc:		( "	+ Transform(o_EFA_Furnizor.dDataDoc)		+ [ )] )		
	EndWith
	*
	Return o_EFA_Furnizor
	*	
EndFunc
* __________________________________________________________________________________________________________
Function Get_EFA_4RETURN ( tcRecipisa, tcID_Solicitare, tcZip, tcErrZIP, tcXMLString, tcNumarDoc, tdDataDoc )
	Local o_EFA_RETURN As Object
	o_EFA_RETURN	= CreateObject('SmallClass')
	__Consola( [o_EFA_RETURN = CreateObject('SmallClass'): ] + Transform(o_EFA_RETURN) + [ )] )
	*		
	With o_EFA_RETURN
		.AddProperty('Id_Solicit',			tcID_Solicitare	)
		.AddProperty('Recipisa',			tcRecipisa		)
		.AddProperty('cZipFileName',		tcZip			)
		.AddProperty('cZip_ERR_FileName',	tcErrZIP		)
		.AddProperty('cXmlString',			tcXMLString		)
		.AddProperty('cNumarDoc',			tcNumarDoc		)
		.AddProperty('dDataDoc',			tdDataDoc		)
		__Consola("o_EFA_RETURN.Id_Solicit:		( "	+ Transform(o_EFA_RETURN.Id_Solicit)		+ [ )] )		
		__Consola("o_EFA_RETURN.Recipisa:		( "	+ Transform(o_EFA_RETURN.Recipisa)		+ [ )] )		
		__Consola("o_EFA_RETURN.cZipFileName:	( "	+ Transform(o_EFA_RETURN.cZipFileName)	+ [ )] )		
		*__Consola("o_EFA_RETURN.cXmlString:	( "	+ Transform(o_EFA_RETURN.cXmlString)		+ [ )] )		
		__Consola("o_EFA_RETURN.cNumarDoc:		( "	+ Transform(o_EFA_RETURN.cNumarDoc)		+ [ )] )
		__Consola("o_EFA_RETURN.dDataDoc:		( "	+ Transform(o_EFA_RETURN.dDataDoc)		+ [ )] )		
	EndWith
	*
	Return o_EFA_RETURN
EndFunc
* __________________________________________________________________________________________________________
Function Get_ERORI_FACTURA( tcXmlString, tlWriteFile, tcErrZIP, tlReturn_oEFA, tcIndex, tcID_Solicitare, tcZip);
HelpString 'Scrie in c_EFacturi_TRIMISE.Detalii si c_EFacturi_TRIMISE.Continut eroare din tcXmlString'
	*
	__Consola([--------------------------------------------------------])
	__Consola( [Program():  ( ] + Transform(Program()) + [ )] )
	__Consola( [] )
	__Consola( [PARAMETERS:  ])
	__Consola( [tcXmlString:	( ] + Transform(tcXmlString)	+ [ )] )
	__Consola( [tlWriteFile:	( ] + Transform(tlWriteFile)	+ [ )] )
	__Consola( [tcErrZIP:		( ] + Transform(tcErrZIP)		+ [ )] )
	__Consola( [tlReturn_oEFA :	( ] + Transform(tlReturn_oEFA )	+ [ )] )
	__Consola( [tcIndex:		( ] + Transform(tcIndex)		+ [ )] )
	__Consola( [tcID_Solicitare:( ] + Transform(tcID_Solicitare)+ [ )] )
	__Consola( [tcZip:			( ] + Transform(tcZip)		+ [ )] )
	__Consola([--------------------------------------------------------])
	*
	Local lcMesajEroare, loXml_ERR, lnSucces
	lcMesajEroare	= ""
	loXml_ERR		= Createobject('Chilkat_9_5_0.Xml')
	lnSucces		= loXml_ERR.LoadXml(tcXmlString)
	? "lnSucces		= loXml_ERR.LoadXml(tcXmlString)"
	? "lnSucces",	Transform(lnSucces)
	*
	If lnSucces		= 1
		*
		lcHeader_Index_incarcare	= loXml_ERR.GetAttrValue("Index_incarcare")
		lcHeader_Cif_emitent		= loXml_ERR.GetAttrValue("Cif_emitent")
		? "Index_incarcare ",		lcHeader_Index_incarcare
		? "Cif_emitent ",			lcHeader_Cif_emitent
		*
		lnCount_i = loXml_ERR.NumChildrenHavingTag("Error")
		*
		For i=0 To lnCount_i-1
		    loXml_ERR.I = i
		    lcError_errorMessage = loXml_ERR.ChilkatPath("Error[i]|(errorMessage)")
		    ? "Mesaj eroare ("+Transform(i)+"): ", lcError_errorMessage
		    lcMesajEroare = lcMesajEroare + "Mesaj eroare ("+Transform(i)+"): " + lcError_errorMessage  + Chr(13)
		EndFor
		*
	EndIf
	*
	If !Empty(lcMesajEroare)
		__Consola( [lcMesajEroare: ( ] + Transform(lcMesajEroare) + [ )] )
		*
		Replace; 
			Detalii		With lcMesajEroare,;
			Continut	With tcXmlString;
		In C_EFACTURI_TRIMISE
		*
		_Screen.ActiveForm.Refresh()
		*
		If tlWriteFile
			toResponse.WriteFile(tcErrZIP)
			loZip.CloseZip()
		EndIf	
		*
		If tlReturn_oEFA
			__Consola([Return Get_EFA_4RETURN ( tcIndex, tcID_Solicitare, tcZip, tcErrZIP, tcXmlString, '', {} )])
			__Consola([--------------------------------------------------------])
			Return Get_EFA_4RETURN ( tcIndex, tcID_Solicitare, tcZip, tcErrZIP, tcXmlString, '', {} )	&& creeaza un obiect EFA din ce exista
		Else
			__Consola([Return .T.])
			__Consola([--------------------------------------------------------])
			Return .T.
		EndIf
		*
	EndIf
	*
	__Consola([Return .T.])
	__Consola([--------------------------------------------------------])
	Return .T.		
EndFunc
* __________________________________________________________________________________________________________
Function ExtractZIP(tcZipFile,  tnInvoiceType, tcID_Solicitare, tcRecipisa)
	*=================================================
	loZip					= CreateObject('Chilkat_9_5_0.Zip')
	__Consola( [loZip: ( ]	+ Transform(loZip) + [ )] )
	lnSuccess = loZip.OpenZip(tcZipFile)
	*=================================================
	*
	IF (lnSuccess <> 1) THEN
	    lcErr_OpenZip = loZip.LastErrorText
	    __Consola( [lcErr_OpenZip: ( ]	+ Transform(lcErr_OpenZip) + [ )] )
	    RELEASE loZip
	    Return lcErr_OpenZip
	EndIf
	*
	*=================================================
	*
	lcNumeFisier	= Iif(tnInvoiceType=1, tcID_Solicitare, tcRecipisa)
	lcFolder_EFA	= JustPath(tcZipFile)	+ '\'	+ lcNumeFisier	+ '\'
	loZip.Extract	( lcFolder_EFA )
	__Consola( [loZip.Extract	( lcFolder_EFA )] )

*!*		lnUnzipCount = loZip.Unzip( lcFolder_EFA )
*!*		__Consola( [lnUnzipCount = loZip.Unzip( lcFolder_EFA )] )
*!*		IF (lnUnzipCount < 0) THEN
*!*		    __Consola( loZip.LastErrorText )
*!*		Else
*!*			__Consola( "Success!" )
*!*		ENDIF
*!*		*
	lnNumEntries = loZip.NumEntries
	i=0	
	
	For i = 0 To lnNumEntries
	
	    loEntry = loZip.GetEntryByIndex(i)
	    IF (loEntry.IsDirectory=1) THEN
	        ? STR(i) + ": " + loEntry.FileName + " (directory)"
	    ELSE
	        ? STR(i) + ": " + loEntry.FileName
	        If Not 'semnatura'$Lower(loEntry.FileName)
		        lcXMLFile		= lcFolder_EFA + AllTrim(loEntry.FileName)
		        Exit
	      	EndIf  
	    ENDIF

	    RELEASE loEntry
	Next
	*
	loZip.CloseZip()
	__Consola( [loZip.CloseZip()] )
	*
*!*		lcXMLFile		= lcFolder_EFA + lcNumeFisier+'.xml'
	lcXMLFromMemory = FileToStr(lcXMLFile)
	__Consola( [lcNumeFisier:		( ]	+ Transform(lcNumeFisier)		+ [ )] )	
	__Consola( [lcFolder_EFA:		( ]	+ Transform(lcFolder_EFA)		+ [ )] )	
	__Consola( [lcXMLFile:			( ]	+ Transform(lcXMLFile)			+ [ )] )	
	*__Consola( [lcXMLFromMemory :	( ]	+ Transform(lcXMLFromMemory )	+ [ )] )	
	*
	Return lcXMLFile
	*
EndFunc
* __________________________________________________________________________________________________________
Procedure InsertNote(toNode, tcText, tnSize)
	Local jj, lcTextNote, lnLenText
	tcText = Alltrim(Strtran(tcText, Chr(13), ';'))
	If ParseDiacritics(tcText, 1)=1
		tcText = ReplaceDiacritics(tcText, 0)
	Endif
	lnLenText = Len(tcText)
	jj = 0
	Do While .T.
		lcTextNote = Alltrim(Substr(tcText, jj*tnSize+1, tnSize))
		If  .Not. Empty(lcTextNote)
			toNode.AppendChild(oXML.CreateElement("Note"))
			toNode.LastChild.Text = lcTextNote
		Endif
		jj = jj+1
		lnLenText = lnLenText-tnSize
		If lnLenText<0
			Exit
		Endif
	Enddo
EndProc
* __________________________________________________________________________________________________________
Function CleanXMLPrefix( tcXmlString )

	RETURN tcXmlString					&& 20August2024



	*RETURN CleanXMLPrefixAndNameSpaces( tcXmlString )


	If File( tcXmlString )
		lcXmlString = FileToStr(tcXmlString)
	Else
		tcXmlString	= tcXmlString
	EndIf	
	&& 02.08.2024
	lcXmlString = StrTran(tcXmlString, 'cac:', '')
	lcXmlString = StrTran(lcXmlString, 'cbc:', '')
	&& 02.08.2024
	Return lcXmlString
EndProc
* __________________________________________________________________________________________________________
Function CleanXMLPrefixAndNameSpaces( tcXmlString )
	*
	RETURN RemoveNamespaces(tcXmlString)
	*
	*
	*
* __________________________________________________________________________________________________________
	If File( tcXmlString )
		lcXmlString = FileToStr(tcXmlString)
	Else
		tcXmlString	= tcXmlString
	EndIf
	*
	Create Cursor All_Prefix_From_Xml ( Prefix C(20), TextSupl C(254), Sirtag M )
	lcXmlString = tcXmlString
	cContorPrefixTag = Occurs( '<', lcXmlString )
	*
	?
	For a = 1 To cContorPrefixTag
		*
		cSirTag   = StrExtract( lcXmlString, '<', '>', a)
		&& wstxns102:InvoicedQuantity xmlns:wstxns102="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" unitCode="EA"
		*
		If Left(AllT(cSirTag), 1) <> "/"   			  && elimin tagul de inchidere, preiau doar tagul de inceput fiind complet
			*
			? 'cSirTag: ', cSirTag
			cPrefix   = StrExtract( cSirTag, '', ":") && wstxns102
			cTextSupl = ""
			? 'cPrefix: ', cPrefix
			* wstxns102:ItemClassificationCode listID="BG-158A 0%" listVersionID="STI" xmlns:wstxns102="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
			nOccurs = Occurs( '"', cSirTag)
			? 'nOccurs: ', nOccurs
			
			For nOccurrence = 1 To nOccurs
				*
				? 'nOccurrence: ', nOccurrence
				afluSir = StrExtract( cSirTag, '"', '"', nOccurrence )
				? 'afluSir: ', afluSir

				&& wstxns102:InvoicedQuantity xmlns:wstxns102="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2
				*
				If Occurs( ':', afluSir) >= 2
					
					nPozitieInceput 	= Atc			(	afluSir,	cSirTag				) - 1
					cSirPinaLaTextSupl 	= SubStr		(	cSirTag,	1, nPozitieInceput	) &&& wstxns102:ItemClassificationCode listID="BG-158A 0%" listVersionID="STI" xmlns:wstxns102=
					nSpatii 			= Occurs		(	' ',		cSirPinaLaTextSupl	)		&&& spatii in sir
					cTextSupl			= StrExtract	(	cSirTag,	' ', '"', nSpatii	) + '"'+afluSir+'"'	 &&& xmlns:wstxns102=
					? 'nPozitieInceput: ', nPozitieInceput
					? 'cSirPinaLaTextSupl: ', cSirPinaLaTextSupl
					? 'nSpatii : ', nSpatii 
					? 'cTextSupl: ', cTextSupl
					*MessageBox('afluSir='     +Chr(13)+afluSir      + Chr(13)+;
					'afluTextSupl='+Chr(13)+afluTextSupl + Chr(13)+;
					'cTextSupl='   +Chr(13)+cTextSupl;
					)
					Exit
				EndIf
				*
			EndFor
			*
			If Len(AllTrim(cPrefix))>0 And Occurs( ' ', AllTrim(cPrefix) )=0
				*
				Select * From All_Prefix_From_Xml Where Prefix=cPrefix And TextSupl=cTextSupl Into Cursor Exista_Prefix
				*
				If RecCount('Exista_Prefix')=0
					Insert Into All_Prefix_From_Xml ( Prefix , TextSupl , Sirtag  );
					Values ( cPrefix, cTextSupl, cSirTag )
				EndIf
				*
			EndIf
			*
		EndIf
		*
		*
	EndFor
	*
	?
	Select All_Prefix_From_Xml
	*
	Scan
		*
		lcXmlString = StrTran( lcXmlString, AllTrim(All_Prefix_From_Xml.Prefix)+":"  , '')
		*
		If Len(AllTrim(All_Prefix_From_Xml.TextSupl))>0
			lcXmlString = StrTran( lcXmlString, " "+AllTrim(All_Prefix_From_Xml.TextSupl), '')
		EndIf
		*
	EndScan
	*
	?
	&& 02.08.2024
	Return lcXmlString
EndProc
* __________________________________________________________________________________________________________
Function RemoveNamespaces
	LParameters lcXML
	Local loXml, loNewXML, loRoot, loNode, loNodes, lcResult, lcRootName

	loXml = CreateObject("MSXML2.DOMDocument.6.0")
	*loXml.SetProperty("SelectionNamespaces", "xmlns:inv='urn:oasis:names:specification:ubl:schema:xsd:Invoice-2' "+"xmlns:cbc='urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2' "+"xmlns:cac='urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2'")
	loXml.LoadXML(lcXML)
	loXml.setProperty("SelectionLanguage", "XPath")

	loNewXML = CreateObject("MSXML2.DOMDocument.6.0")
	loNewXML.preserveWhiteSpace = .F.
	loNewXML.AppendChild(loNewXML.createProcessingInstruction("xml", 'version="1.0"'))

	* Get the root element name without namespace
	lcRootName = IIf(At(":", loXml.documentElement.NodeName) > 0, SubStr(loXml.documentElement.NodeName, At(":", loXml.documentElement.NodeName) + 1), loXml.documentElement.NodeName)

	* Create a new root element with the same name
	loRoot = loNewXML.CreateElement(lcRootName)
	loNewXML.AppendChild(loRoot)

	* Copy nodes without namespaces
	loNodes = loXml.documentElement.ChildNodes
	For Each loNode In loNodes
		AddNodeWithoutNamespace(loRoot, loNode)
	EndFor

	*loNewXML.formatting = 1  && Enable pretty print	
	*lcResult = loNewXML.XML
	
	If Not File("prettyprint.xslt")	
		Text To lcSQL NoShow TextMerge
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xalan="http://xml.apache.org/xslt" version="1.0">
    <xsl:output method="xml" encoding="UTF-8" indent="yes" xalan:indent-amount="4"/>
    <!--Important!  Remove existing whitespace in DOM elements.-->
    <xsl:strip-space elements="*"/>
    <!--Identity transformation (see http://www.w3.org/TR/xslt#copying).-->
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
		EndText
	EndIf
	* Apply XSLT for pretty print
	loXSLT = CREATEOBJECT("MSXML2.FreeThreadedDOMDocument.6.0")
	loXSLT.async = .F.
	loXSLT.load("prettyprint.xslt")

	loTransformedXML = CREATEOBJECT("MSXML2.DOMDocument.6.0")
	loNewXML.transformNodeToObject(loXSLT, loTransformedXML)

	lcResult = loTransformedXML.XML	
	Return lcResult
EndFunc
* __________________________________________________________________________________________________________
Procedure AddNodeWithoutNamespace
	LParameters loParent, loNode
	Local loNewNode, loChildNode, lcNodeName

	If loNode.NodeType = 1 && Element node
		* Remove prefix from node name
		lcNodeName = IIf(At(":", loNode.NodeName) > 0, SubStr(loNode.NodeName, At(":", loNode.NodeName) + 1), loNode.NodeName)
		loNewNode = loParent.ownerDocument.CreateNode(1, lcNodeName, "")
		loParent.AppendChild(loNewNode)

		For Each loChildNode In loNode.ChildNodes
			AddNodeWithoutNamespace(loNewNode, loChildNode)
		EndFor
	Else
		If loNode.NodeType = 3 && Text node
			loNewNode = loParent.ownerDocument.createTextNode(loNode.nodeValue)
			loParent.AppendChild(loNewNode)
		EndIf
	EndIf
EndProc
* __________________________________________________________________________________________________________
Function XML_CreateComment(tcComment, toNode)
	
	If _VFP.StartMode = 0
	    lo_newComment = oXML.createComment(tcComment)
    	*oInvoice.appendChild(lo_newComment)
    	toNode.parentNode.insertBefore(lo_newComment, toNode)
    EndIf	
EndFunc
* __________________________________________________________________________________________________________
Function InterpretareRaspunsValidatorEFactura(tcMesaj)
	Local lcMesaj
	lcMesaj = "ok"
	
	Do Case
		
		Case "[BR-RO-110]-Daca Codul tarii Cumparatorului"$tcMesaj
			lcMesaj = "Alegeti un judet valid in ecranul 'Clienti'."
		
		Case "[BR-RO-110]-Daca Codul tarii Vanzatorului"$tcMesaj
			lcMesaj = "Alegeti un judet valid in ecranul 'Configurare societati'."
		
		Case "[BR-RO-100]"$tcMesaj
			lcMesaj = "Pentru Bucuresti, alegeti un sector corect in campul 'Localitate' din ecranul 'Clienti'."
		
		Case StrTran(tcMesaj, " ", "")="F:TaxCurrencyCode(1)eroarestructura:elementnecunoscut"
			lcMesaj = "ok"
		
		Case tcMesaj="F: validari globale  eroare structura: element necunoscut ('Invoice')"
			lcMesaj = "ok"
		
		Case "F:elementul'UBLVersionID'trebuiesapreceadaelementul'InvoiceLine'"$StrTran(tcMesaj, " ", "")
			lcMesaj = "ok"
		
		Case "eroare structura: elementul 'CustomizationID'"$tcMesaj
			lcMesaj = "ok"
		
		Case "F: UBLVersionID (1)  eroare structura: ordine incorecta a descendentilor elementului 'Invoice':"$tcMesaj
			lcMesaj = "ok"
		
		Case "F: CustomizationID (1)  eroare structura: elementul 'UBLVersionID'"$tcMesaj
			lcMesaj = "ok"
		
		Case "F: UBLVersionID (1)  eroare structura: element necunoscut ('UBLVersionID') in namesapace"$tcMesaj
			lcMesaj = "ok"
		
		Case "Subdiviziunea tarii Cumparatorului (BT-54) trebuie sa fie codificata folosind lista de coduri ISO 3166-2"$tcMesaj
			lcMesaj = "Alegeti un judet valid in ecranul 'Clienti'."
		
		OtherWise
			lcMesaj = AllTrim(tcMesaj)
	EndCase
	
	RETURN lcMesaj
EndFunc
* __________________________________________________________________________________________________________