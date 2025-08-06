*!* ============================================================================
*!* FISIER: SAFT_Main_Advanced.prg
*!* ============================================================================
*!* AUTOR: Gemini AI
*!* DATA:  26.06.2025
*!* SCOP:  Punct de intrare pentru arhitectura avansata.
*!* Orchestreaza crearea componentelor (Context, Repository, Logger, Builder)
*!* si porneste executia lantului de responsabilitati.
*!* ============================================================================
LPARAMETERS tdData1, tdData2, tcTipDeclaratie, tnSegmente


*#DEFINE FORCE_REFRESH		.T.
*PUBLIC FORCE_REFRESH
FORCE_REFRESH = .T.

IF TYPE('glForceVIES')='U'
	glForceVIES = .F.
ENDIF 

PUBLIC DEBUG_SAFT
DEBUG_SAFT			= VarType(m.DebugSAFT)#'U'


*-- Se asigura ca functiile ajutatoare sunt disponibile
SET PROCEDURE TO SAFT_Advanced_Classes.prg ADDITIVE
SET PROCEDURE TO SAFT_Helpers.prg ADDITIVE

CLOSE DATABASES ALL

LOCAL loContext AS SAFT_Context
LOCAL loRepo AS SAFT_Repository
LOCAL loLogger AS SAFT_Logger
LOCAL loBuilder AS SAFT_ChainBuilder
LOCAL loChainHead AS Handler_Base
LOCAL llSuccess AS Boolean

*-- Validare parametri
IF EMPTY(tdData1) OR EMPTY(tdData2)
    MESSAGEBOX("Perioada (Data1, Data2) este obligatorie!", 16, "Eroare Parametri")
    RETURN .F.
ENDIF
tcTipDeclaratie = IIF(EMPTY(tcTipDeclaratie), "L", UPPER(ALLTRIM(tcTipDeclaratie)))
tnSegmente = IIF(EMPTY(tnSegmente), 1, tnSegmente)

TRY
    *-- 1. Initializare componente decuplate
    loRepo				= CREATEOBJECT("SAFT_Repository")
    loLogger			= CREATEOBJECT("SAFT_Logger")
    loProgressUI		= CREATEOBJECT("SAFT_Progress_UI_Console")
    loSummaryCollector	= CREATEOBJECT("SAFT_Summary_Collector")
    
    


    *-- 2. Creare Context. Acesta va fi singurul obiect pasat între handlere.
    loContext			= CREATEOBJECT("SAFT_Context", tdData1, tdData2, tcTipDeclaratie, tnSegmente)
    *-- Atasare observatori
    loContext.AttachObserver(loLogger)
    loContext.AttachObserver(loProgressUI)
    loContext.AttachObserver(loSummaryCollector)
    *-- Notifica observatorii ca procesul începe (Logger-ul va scrie în fisier)
    loContext.Notify("PROCESS_START", "Initiere generare SAF-T...")

    lcLogFile			= loContext.LogFile
    lcTipDeclaratie		= loContext.DeclarationType
    CUI_Raportor		= '00'+ICAS.oSoc.CodFiscal
    vTipConta			= IIF(IsNullOrEmpty(ALLTRIM(ICAS.oSoc.SaFT_TipConta)), 'A', ALLTRIM(ICAS.oSoc.SaFT_TipConta))
    lcDirectorSAFT		= AddBs(JustPath(loContext.FinalFileName))
    Data1				= loContext.StartDate
    Data2				= loContext.EndDate
    lnCalupInregGLE		= 50000
    
	lcModPlataTva=GetModPlataTva(tdData2)
	gcTaxType='000'
	*
	Do Case
		Case lcModPlataTva=1		&& Lunar
			*lcTaxType='301'
			gcTaxType='300'
		Case lcModPlataTva=2		&& Trimestrial
			*lcTaxType='302'
			gcTaxType='300'
		Case lcModPlataTva=3		&& Semestrial
			*lcTaxType='303'
			gcTaxType='300'
		Case lcModPlataTva=4		&& Anual
			*lcTaxType='304'
			gcTaxType='300'
		OtherWise					&& Neplatitor
			gcTaxType='000'
	EndCase
	*    
	Tabela_Erori_Saft('Creare_Tabela_Erori')
	loContext.Notify("ENVIRONMENT", "Initializare environment...")
	
	SAFT_Mapare()
	loContext.Notify("ENVIRONMENT", "SAFT_Mapare...")
	CreareCursoare(loContext.StartDate, loContext.EndDate)
	Saft_Ecoaqua_Preluare_All_DB('CreareCursoare')
	Saft_Ecosal_Preluare_Dbf	('CreareCursoare')
	loContext.Notify("ENVIRONMENT", "CreareCursoare(loContext.StartDate, loContext.EndDate)...")
    

    loContext.SetRepository(loRepo)

    *-- 3. Construire lant de handlere folosind un Builder
    loBuilder	= CREATEOBJECT("SAFT_ChainBuilder")
    loChainHead	= loBuilder.BuildChain(loContext)

    IF VARTYPE(loChainHead) != "O"
        loContext.Notify("FATAL_ERROR", "Tip de declaratie nerecunoscut: " + tcTipDeclaratie)
        RETURN .F.
    ENDIF

    *-- 4. Notifica observatorii despre startul procesului (trimite lista de pasi)
    *LOCAL ARRAY aSteps[1]
    *loBuilder.GetHandlerList(loChainHead, @aSteps)
    *loContext.Notify("PROCESS_START", @aSteps)
    loSteps = loBuilder.GetHandlerList(loChainHead)
    loContext.Notify("PROCESS_START", loSteps)

    *-- 5. Executia lantului. Apelam doar primul handler.
    llSuccess = loChainHead.Execute(loContext)
    loContext.Notify("PROCESS_END", llSuccess)
    
    
    llSuccess = !loContext.HasErrors
    
CATCH TO oException
    MESSAGEBOX("Eroare neasteptata în procesul principal: " + oException.Message, 16, "Eroare Fatala")

    IF VARTYPE(loContext) = "O"
        loContext.Notify("FATAL_ERROR", "Eroare: " + oException.Message + " în " + oException.Procedure + " la linia " + TRANSFORM(oException.LineNo))
    ENDIF
    
    Set Step On
    llSuccess = .F.
ENDTRY

*-- Afisare rezultat final
IF llSuccess
	loSummaryCollector.DisplaySummary(loContext)
    MESSAGEBOX("Generarea fisierului SAF-T a fost finalizata cu succes!", 64, "Proces Finalizat")
ELSE
    MESSAGEBOX("Generarea fisierului SAF-T a esuat. Verificati fisierul de log pentru detalii.", 16, "Proces Esuat")
ENDIF

*!*	RELEASE ALL LIKE lo*
RETURN llSuccess


#if .f.
Am pregatit o rescriere completa a codului, aplicând principiile de proiectare orientata-obiect (OOP) 
si design pattern-urile mentionate de dumneavoastra. 
Am transformat scriptul procedural într-o arhitectura robusta, bazata pe clase, care este mult mai flexibila
si mai usor de înteles.
Noua arhitectura se bazeaza pe Solutia 1 (Refactorizare Pragmatica Orientata pe Obiecte) pe care am discutat-o anterior, 
deoarece ofera cel mai bun echilibru între ingineria software moderna si specificul platformei Visual FoxPro.
Am încredere în aceasta solutie în proportie de 95%, deoarece rezolva problemele fundamentale ale codului original 
si introduce o structura curata, logica si extensibila.
Structura Solutiei Implementate
Factory Method & Strategy Pattern: 
	Am eliminat complet blocul DO CASE stufos. 
	Acum, un obiect "Factory" (SAFT_Factory) decide ce strategie de generare sa foloseasca (Lunar, Anual, etc.) s
	i creeaza un obiect specializat pentru acea sarcina. 
	Adaugarea unui nou tip de declaratie devine o operatiune simpla, fara a modifica codul existent.
Template Method Pattern & Inheritance:
	 Am creat o clasa de baza (SAFT_Generator_Base) care defineste "sablonul" procesului de generare (patii comuni). 
	 Clasele specializate (SAFT_Generator_Periodic, SAFT_Generator_Anual) mostenesc acest sablon 
	 si implementeaza doar detaliile specifice tipului lor de declaratie.
Encapsulation: 
	Toata logica si datele (fostele variabile PRIVATE si PUBLIC) sunt acum încapsulate 
	ca proprietati si metode în interiorul claselor. 
	Acest lucru previne modificarile accidentale si face codul mult mai sigur si mai predictibil.
Separation of Concerns:
	Fiecare clasa are o singura responsabilitate clara. 
	Exista clase pentru generarea logica, o clasa pentru creare (factory) si un program principal care doar coordoneaza procesul.
	Mai jos veti gasi codul rescris si complet documentat. 
	L-am structurat ca o serie de fisiere .prg si .vcx (reprezentate prin cod) pentru a ilustra cum ar arata proiectul final.


Justificarea Patilor si a Alegerilor
Decuplarea prin Factory (SAFT_Factory): 
	În loc ca programul principal sa stie cum sa construiasca fiecare tip de declaratie, el doar cere fabricii un "generator". 
	Fabrica este singurul loc care cunoaste implementarile concrete (SAFT_Generator_Periodic, SAFT_Generator_Anual). 
	Acest lucru respecta principiul "Dependency Inversion" si face sistemul mult mai usor de extins.
	Definirea unui sablon de Proces (SAFT_Generator_Base): 
		Metoda Run() din clasa de baza este un exemplu perfect de "Template Method Pattern". 
		Ea defineste patii algoritmului (curatare, preparare date, generare sectiuni, asamblare) 
		si lasa subclasele sa implementeze detaliile fiecarui pas. 
		Astfel, asiguram o secventa corecta a operatiunilor pentru toate tipurile de declaratii, evitând duplicarea codului.
	Specializarea prin Mostenire:
		Clasele SAFT_Generator_Periodic si SAFT_Generator_Anual mostenesc toata functionalitatea comuna (logging, configurare mediu, generare header) 
		si se concentreaza doar pe ceea ce fac ele diferit. 
		Acest lucru respecta principiul "Don't Repeat Yourself" (DRY).
	Încapsulare si Lizibilitate:
		Prin transformarea variabilelor globale în proprietati ale obiectului (ex: THIS.StartDate), 
		starea programului devine controlata si predictibila. 
		Codul din interiorul unei metode precum GenerateCompanyHeader este acum mult mai clar, 
		deoarece se vede exact de ce date depinde (THIS.CompanyCUI, THIS.DeclarationType).
Pasii Urmatori
	Completarea Logica:
		Am furnizat structura completa si exemple de implementare. 
		Urmatorul pas este sa mutati codul din functiile originale (_05Customers, _06Suppliers, etc.) 
		în metodele private corespunzatoare din clasele derivate.
	Tratarea Erorilor:
		Am inclus un bloc TRY...CATCH general. 
		Ar fi ideal sa adaugati mecanisme mai granulare de tratare a erorilor în interiorul fiecarei metode de generare.
	Refactorizarea Interogarilor SQL:
		Interogarile SQL pot fi, de asemenea, extrase în metode dedicate pentru a creste lizibilitatea, 
		conform exemplului din Solutia 2 (Repository Pattern), 
		daca se doreste un nivel si mai avansat de abstractizare.
	Aceasta noua arhitectura nu numai ca rezolva problemele codului initial, 
	dar va ofera o fundatie solida si profesionala pe care puteti construi în siguranta în anii urmatori.


Prezentarea Solutiei 2: 
Arhitectura Avansata
Aceasta solutie redeseneaza complet aplicatia, decuplând responsabilitatile în componente specializate. 
Este o implementare de manual a mai multor design pattern-uri, rezultând un sistem extrem de robust si flexibil.
Confidenta: 90% - Aceasta solutie este tehnic superioara si reprezinta standardul de aur în proiectarea software.
Este "the right way to do it" pentru sisteme complexe.
Singurul motiv pentru care încrederea nu este 100% este ca introducerea atâtor straturi de abstractizare 
poate parea complexa la început pentru un proiect care, în esenta, urmeaza un flux liniar.
Totusi, beneficiile pe termen lung sunt imense.

Design Patterns Utilizate:
Chain of Responsibility:
	Nucleul acestei arhitecturi.
	Fiecare pas al generarii (creare header, procesare clienti, etc.) este o clasa separata ("handler").
	Acestea sunt înlantuite, iar fiecare handler îsi executa logica si apoi paseaza controlul urmatorului din lant. 
	Acest lucru permite reconfigurarea dinamica a întregului proces de generare fara a modifica codul existent.
Repository Pattern:
	Toata logica de acces la date (interogari SQL, comenzi USE) este complet izolata într-o singura clasa, SAFT_Repository. 
	Clasele de generare nu mai "stiu" de unde vin datele; ele doar cer repository-ului: "da-mi clientii", "da-mi furnizorii".
	Daca mâine doriti sa mutati datele pe un server SQL, modificati doar clasa Repository.
Observer Pattern:
	Am decuplat complet mecanismul de logging de logica de business.
	Generatoarele "notifica" atunci când se întâmpla ceva important (ex: "încep generarea clientilor"), 
	iar un obiect Logger (care este un "observator") primeste notificarea si o scrie în fisier.
	Se poate adauga la fel de usor un alt observator care sa actualizeze o bara de progres, 
	fara a modifica nicio linie din codul de generare.
Builder Pattern:
	Am creat o clasa SAFT_ChainBuilder a carei unica responsabilitate este
	sa "construiasca" lantul corect de handlere în functie de tipul de declaratie.

Cum Functioneaza Aceasta Arhitectura
SAFT_Main_Advanced.prg este punctul de pornire.
El nu face nicio munca de procesare.
Doar creeaza obiectele necesare:
	un Repository pentru date,
	un Logger pentru mesaje si
	un Context care sa le tina pe toate la un loc.
Apoi, creeaza un SAFT_ChainBuilder.
	Acestuia i se cere sa construiasca lantul de operatiuni (BuildChain) pentru tipul de declaratie dorit.
	Builder-ul returneaza primul handler din lant (ex: Handler_Setup).
	Programul principal apeleaza metoda Execute() a acestui prim handler, pasându-i obiectul Context.
	Fiecare handler:Îsi executa sarcina specifica (ex: Handler_Setup creeaza directoarele).
	Foloseste obiectul Context pentru a accesa resurse (ex: toContext.Repository.GetCustomers())
	sau pentru a stoca rezultate.
	Trimite notificari prin toContext.Notify(), fara sa stie cine le asculta.
	SAFT_Logger le va prinde si le va scrie în fisier.
	La final, apeleaza NextHandler.Execute(toContext), pasând controlul mai departe în lant.
	Procesul continua pâna când ultimul handler din lant îsi termina executia.
	Aceasta abordare este extrem de puternica.
	Daca în viitor doriti ca generarea clientilor sa se faca înaintea planului de conturi, 
	pur si simplu rearanjati ordinea în care SAFT_ChainBuilder le înlantuie.
	Daca un pas devine optional, poate fi scos din lant fara a afecta celelalte componente.

Este chintesenta design-ului software modern, aplicata în mediul Visual FoxPro.

#endif
