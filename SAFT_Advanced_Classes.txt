
*!* ============================================================================
*!* FISIER: SAFT_Advanced_Classes.prg (contine toate clasele necesare)
*!* ============================================================================

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_Context
*!* SCOP:  Un obiect container care transporta starea si resursele partajate
*!* (Repository, Logger, etc.) de-a lungul lantului de handlere.
*!* De asemenea, actioneaza ca "Subject" în Observer Pattern.
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_Context AS Custom
    *-- Datele de intrare
    StartDate = {}
    EndDate = {}
    DeclarationType = ""
    SegmentCount = 1
    
    *-- Resurse partajate
    Repository = NULL
    
    *-- Stare interna
    WorkDir = ""
    FinalFileName = ""
    LogFile = ""
    CompanyCUI = ""
    HasErrors = .F.
    
    *-- Container pentru datele intermediare (ex: cursoare generate)
    DataBag = NULL
    
    *-- Observer Pattern
    oObservers=NULL && Proprietate pentru a tine colectia de observatori
    *nObserverCount = 0
    oTimings=NULL
    oRecordCounts=NULL
    

    FUNCTION Init(tdStart, tdEnd, tcType, tnSegments)
       * DIMENSION THIS.aObservers[1] && Initializare proprietate ca tablou
   
        THIS.StartDate		= tdStart
        THIS.EndDate		= tdEnd
        THIS.DeclarationType= tcType
        THIS.SegmentCount	= tnSegments
        THIS.DataBag		= CREATEOBJECT("Collection")
        *-- Initializare corecta a colectiei de observatori
        THIS.oObservers		= CREATEOBJECT("Collection")       
        THIS.oTimings		= CREATEOBJECT("Collection")
        THIS.oRecordCounts	= CREATEOBJECT("Collection")
        
    ENDFUNC
    
    FUNCTION SetRepository(toRepo AS SAFT_Repository)
        THIS.Repository = toRepo
    ENDFUNC
    
    FUNCTION AttachObserver(toObserver AS Notifier_Observer_Base)

    	THIS.oObservers.Add(toObserver)

    ENDFUNC

    FUNCTION Notify(tcEventName AS String, tvEventData1 AS Collection, tvEventData2 AS Collection)
        LOCAL loObserver AS Notifier_Observer_Base
        FOR EACH loObserver IN THIS.oObservers
            IF VARTYPE(loObserver) = "O"
                loObserver.Update(THIS, tcEventName, tvEventData1, tvEventData2)
            ENDIF
        ENDFOR
    ENDFUNC


ENDDEFINE


*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_Repository
*!* SCOP:  Implementeaza "Repository Pattern". Centralizeaza tot accesul la date.
*!* Nici o alta clasa nu contine interogari SQL.
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_Repository AS Custom
    
    FUNCTION Get_04GeneralLedgerAccounts(tdStart AS Date, tdEnd AS Date) AS Boolean
        THIS.NotifyStatus("Repository: Extragere plan de conturi...")
        Get_GLA()
    ENDFUNC
    
    FUNCTION Get_05Customers(tdStart AS Date, tdEnd AS Date) AS Boolean
        THIS.NotifyStatus("Repository: Extragere clienti...")
        *-- Logica din `_05Customers()` pentru extragerea datelor
        Get_Customers()
    ENDFUNC

    FUNCTION Get_06Suppliers(tdStart AS Date, tdEnd AS Date) AS Boolean
        THIS.NotifyStatus("Repository: Extragere furnizori...")
        Get_Suppliers()
	ENDFUNC

    FUNCTION Get_07TaxTable(tdStart AS Date, tdEnd AS Date) AS Boolean
        THIS.NotifyStatus("Repository: Extragere tipuri de taxa...")
        * Tb dupa _16GLE
        Get_TaxTable()
	ENDFUNC


    FUNCTION Get_08UOMTable(tdStart AS Date, tdEnd AS Date) AS Boolean
        THIS.NotifyStatus("Repository: Extragere unitati de masura...")
		mySQLExec([Select Um As UnitOfMeasure, Specificatie As Description From Um Where IsNull(Cod, '')<>''], [crsUM])
		Saft_Ecoaqua_Preluare_All_DB('UOMTable')		
	ENDFUNC

    FUNCTION Get_09AnalysisTypeTable(tdStart AS Date, tdEnd AS Date) AS Boolean
        THIS.NotifyStatus("Repository: Extragere centre de cost...")

		SELECT MasterFiles_AnalysisTypeTable
		IF RECCOUNT()=0
			AnalysisType			=	'CC'
			AnalysisTypeDescription	=	'Centru de cost'
			AnalysisID				=	'C1'
			AnalysisIDDescription	=	'Diverse'
			INSERT INTO MasterFiles_AnalysisTypeTable FROM MEMVAR
		ENDIF
		Saft_Ecoaqua_Preluare_All_DB('AnalysisTypeTable')
	ENDFUNC

    FUNCTION Get_10MovementTypeTable(tdStart AS Date, tdEnd AS Date) AS Boolean
        THIS.NotifyStatus("Repository: Extragere tipuri de miscari...")
		*
	ENDFUNC


    FUNCTION Get_11Products(tdStart AS Date, tdEnd AS Date) AS Boolean
        THIS.NotifyStatus("Repository: Extragere produse...")
		Get_Products()
	ENDFUNC

    FUNCTION Get_12PhysicalStock(tdStart AS Date, tdEnd AS Date) AS Boolean
        THIS.NotifyStatus("Repository: Extragere stocurile...")
        Get_PhysicalStock()
	ENDFUNC

    FUNCTION Get_13Owners(tdStart AS Date, tdEnd AS Date) AS Boolean
        THIS.NotifyStatus("Repository: Extragere _13Owners...")
        Get_Owners()
    ENDFUNC  
    
    FUNCTION Get_14Assets(tdStart AS Date, tdEnd AS Date) AS Boolean
        THIS.NotifyStatus("Repository: Extragere mijloacele fixe...")
		Get_Assets()
    ENDFUNC    
        
    FUNCTION Get_18SalesInvoices(tdStart AS Date, tdEnd AS Date) AS Boolean
        THIS.NotifyStatus("Repository: Extragere facturi vânzare...")
        *-- Interogarea SQL complexa din `_18SalesInvoices()`
        Get_SalesInvoices()
    ENDFUNC
    
    FUNCTION Get_19PurchaseInvoices(tdStart AS Date, tdEnd AS Date) AS Boolean
        THIS.NotifyStatus("Repository: Extragere facturi de intrare...")
        Get_PurchaseInvoices()
    ENDFUNC    
    *... si asa mai departe pentru FIECARE interactiune cu baza de date
    * GetSuppliers(), GetPayments(), GetAssets(), etc.
    FUNCTION Get_20Payments(tdStart AS Date, tdEnd AS Date) AS Boolean
        THIS.NotifyStatus("Repository: Extragere plati si incasari...")
        Get_Payments()
    ENDFUNC

    FUNCTION Get_21MovementOfGoods(tdStart AS Date, tdEnd AS Date) AS Boolean
        THIS.NotifyStatus("Repository: Extragere miscarile de stocuri...")
        Get_MovementOfGoods()
    ENDFUNC

    FUNCTION Get_22AssetTransactions(tdStart AS Date, tdEnd AS Date) AS Boolean
        THIS.NotifyStatus("Repository: Extragere miscarile de mijloace fixe...")
        Get_AssetTransactions()
    ENDFUNC

    FUNCTION Get_16GeneralLedgerEntries(tdStart AS Date, tdEnd AS Date) AS Boolean
        THIS.NotifyStatus("Repository: Extragere registrul jurnal...")
        && Trebuie facut dupa ce se colecteaza facturile de intrare si iesire
        && pentru ca apeleaza functia GetTipFactura(tnId_Nota, tcJournalId)
        Get_GeneralLedgerEntries()
    ENDFUNC

    PROTECTED FUNCTION NotifyStatus(tcMessage AS String)
        *-- O metoda helper pentru a trimite statusul înapoi, daca este necesar.
        *-- O implementare mai complexa ar folosi propriul sau mecanism de notificare.
        WAIT WINDOW tcMessage NOWAIT NOCLEAR
    ENDFUNC

ENDDEFINE


*!*-----------------------------------------------------------------------------
*!* CLASS: Handler_Base (Clasa Abstracta)
*!* SCOP:  Defineste interfata pentru toti "handlerii" din "Chain of Responsibility".
*!*-----------------------------------------------------------------------------
DEFINE CLASS Handler_Base AS Custom
    *PROTECTED NextHandler
    NextHandler = NULL

    FUNCTION Init
        THIS.NextHandler = NULL
    ENDFUNC

    FUNCTION SetNext(toHandler AS Handler_Base) AS Handler_Base
        THIS.NextHandler = toHandler
        RETURN toHandler && Permite înlantuirea: h1.SetNext(h2).SetNext(h3)
    ENDFUNC

    FUNCTION Execute(toContext AS SAFT_Context) AS Boolean
        LOCAL llSuccess AS Boolean, nStartTime, nDuration
        
        *-- Notifica despre începerea acestui pas
        toContext.Notify("HANDLER_START", THIS.Class)
        nStartTime = SECONDS()

        *-- Executa logica specifica handler-ului
        llSuccess = THIS.Process(toContext)
        
        nDuration = SECONDS() - nStartTime
        toContext.Notify("HANDLER_END", THIS.Class, nDuration)

        IF !llSuccess
            toContext.HasErrors = .T.
            toContext.Notify("HANDLER_ERROR", "Eroare în handler-ul: " + THIS.Class)
            RETURN .F.
        ENDIF
        
        *-- Paseaza controlul urmatorului handler, daca exista
        IF VARTYPE(THIS.NextHandler) = "O"
            RETURN THIS.NextHandler.Execute(toContext)
        ENDIF

        RETURN .T.
    ENDFUNC
    
    *-- Metoda abstracta care trebuie implementata de fiecare handler concret.
    PROTECTED FUNCTION Process(toContext AS SAFT_Context) AS Boolean
        ERROR "Metoda Process() trebuie implementata de subclasa " + THIS.Class
        RETURN .F.
    ENDFUNC
ENDDEFINE


*!*-----------------------------------------------------------------------------
*!* CLASS: Handler_Setup
*!* SCOP:  Primul handler din lant. Configureaza mediul de lucru.
*!*-----------------------------------------------------------------------------
DEFINE CLASS Handler_Setup AS Handler_Base
    

    PROTECTED FUNCTION Process(toContext AS SAFT_Context) AS Boolean
        toContext.Notify("INFO", "Configurare mediu de lucru...")

        LOCAL lcAppPath, lcLogDir
        
        *-- Setare cale fisier de log, conform cerintelor
        lcAppPath = GetAppStartPath()
        lcLogDir = ADDBS(lcAppPath) + "LOG"
        IF !DIRECTORY(lcLogDir)
            MD (lcLogDir)
        ENDIF
			
        toContext.LogFile = ADDBS(lcLogDir) + "SAFT_Generator.log"
        ERASE (toContext.LogFile)
        
        *-- Setare cale fisier final si director de lucru, conform cerintelor
        *PUBLIC m.DenumireSoc && Asigura-te ca variabila este disponibila pentru functiile vechi
        *m.DenumireSoc = ICAS.oSoc.Denumire
        
        *-- Se apeleaza functia originala pentru a obtine calea completa
        toContext.FinalFileName = Get_FullPath_SAFT_File(toContext.StartDate, toContext.EndDate, toContext.DeclarationType, toContext.SegmentCount)
        toContext.WorkDir = AddBs(JUSTPATH(toContext.FinalFileName))
										  
														
        
        toContext.Notify("INFO", "Director de lucru setat la: "	+ toContext.WorkDir)
        toContext.Notify("INFO", "Fisierul final va fi: "		+ toContext.FinalFileName)
        toContext.Notify("INFO", "Fisierul de log va fi: "		+ toContext.LogFile)
        
        toContext.Notify("SETUP_COMPLETE", "Mediul de lucru a fost configurat.")

        RETURN .T.
    ENDFUNC

ENDDEFINE

*!*-----------------------------------------------------------------------------
*!* CLASS: Handler_Generate_Header
*!* SCOP:  Genereaza sectiunea Header a fisierului SAF-T.
*!*-----------------------------------------------------------------------------
DEFINE CLASS Handler_Generate_Header AS Handler_Base
    PROTECTED FUNCTION Process(toContext AS SAFT_Context) AS Boolean

        toContext.Notify("INFO", "Generare 01.AuditFile.xml si 02.Header.xml...")
        
*!*	        LOCAL lcXML
*!*	        *-- Generare 01.AuditFile.xml
*!*	        TEXT TO lcXML NOSHOW TEXTMERGE PRETEXT 15
*!*	            <?xml version="1.0"?>
*!*	            <AuditFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="mfp:anaf:dgti:d406:declaratie:v1" xsi:schemaLocation="urn:StandardAuditFile-Taxation-Financial:RO Romanian_SAF-T_Financial_Schema_v_2_4_6_09032022.xsd">
*!*	        ENDTEXT
*!*	        STRTOFILE(lcXML, toContext.WorkDir + "01.AuditFile.xml")

		SET TEXTMERGE ON TO lcDirectorSAFT+'01.AuditFile.xml' NOSHOW
\\<?xml version="1.0"?>
\<AuditFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="mfp:anaf:dgti:d406:declaratie:v1" xsi:schemaLocation="urn:StandardAuditFile-Taxation-Financial:RO Romanian_SAF-T_Financial_Schema_v_2.1.xsd">
		SET TEXTMERGE TO
		SET TEXTMERGE OFF
		AddToLog(TRANSFORM(SECONDS()-_LastTime, [999.9999])+[ lcDirectorSAFT+'01.AuditFile.xml'...], lcLogFile, .T., .T.)
		__Consola_Timing("SAFT.prg : Generare XML : " + [ ]+lcDirectorSAFT+'01.AuditFile.xml'+[...])

*!*	        *-- Generare 02.Header.xml
*!*	        *-- Se folosesc datele din `toContext`
*!*	        TEXT TO lcXML NOSHOW TEXTMERGE PRETEXT 15
*!*	            <Header>
*!*	                <HeaderComment><< ALLTRIM(toContext.DeclarationType) >></HeaderComment>
*!*	            </Header>
*!*	        ENDTEXT
*!*	        STRTOFILE(lcXML, toContext.WorkDir + "02.Header.xml")

		lnLunaStart = MONTH(toContext.StartDate)
		lnLunaend	= MONTH(toContext.EndDate)
		lnAnul_SAFT	= YEAR(toContext.StartDate)

		SELECT Header_Structure
		AuditFileVersion		=	'2.0'
		AuditFileCountry		=	'RO'
		AuditFileRegion			=	'RO-'+GetCodJudet(3, ICAS.oSoc.Judet)
		AuditFileDateCreated	=	DATE()			&& Transform(DToS(Date()), '@R ####-##-##')
		SoftwareCompanyName		=	'EXPERT SOFTWARE COMPANY SRL'
		SoftwareID				=	'ICAS'
		SoftwareVersion			=	ICAS.cVERSIUNE
		RegistrationNumber		=	CUI_Raportor
		NAME					=	ICAS.oSoc.Denumire
		StreetName				=	GetOptionalXMLValue(ICAS.oSoc.Strada)
		NUMBER					=	GetOptionalXMLValue(ICAS.oSoc.NumarStrada)
		City					=	ICAS.oSoc.Localitate
		PostalCode				=	GetOptionalXMLValue(ICAS.oSoc.CodPostal)
		REGION					=	GetOptionalXMLValue('RO-'+GetCodJudet(3, ICAS.oSoc.Judet))
		Country					=	'RO'
		AddressType				=	GetOptionalXMLValue('StreetAddress')
		TITLE					=	''
		FirstName				=	ICAS.oSoc.NumePersoanaAutorizata
		INITIALS				=	''
		LastNamePrefix			=	''
		BirthName				=	ICAS.oSoc.PreNumePersoanaAutorizata
		Salutation				=	''
		OtherTitles				=	''
		Telephone				=	ICAS.oSoc.Telefon
		Fax						=	''
		Email					=	ICAS.oSoc.Email
		Website					=	''
		TaxRegistrationNumber	=	ICAS.oSoc.CodFiscal
		TaxType					=	GetRegimFiscal(toContext.EndDate)
		TaxNumber				=	''
		TaxAuthority			=	''
		TaxVerificationDate		=	{}
		IBANNumber				=	IIF(VerifIBAN(cGetBanca1.ContBanca), cGetBanca1.ContBanca, '')	&& Numar de cont bancar interna?ional, ISO 13616
		BankAccountNumber		=	'Fara cont bancar'	&& Numarul alocat contului de catre banca proprie a persoanei fizice sau a companiei. CRED ca aici tb completat in loc de IBANNumber
		BankAccountName			=	''
		SortCode				=	''
		DefaultCurrencyCode		=	'RON'
		TaxReportingJurisdiction=	''
		CompanyEntity			=	''
		SelectionStartDate		=	{}
		SelectionEndDate		=	{}
		PeriodStart				=	IIF( lcTipDeclaratie='A', 1, lnLunaStart )	&& AllTrim(Str(lnLunaStart))
		PeriodStartYear			=	lnAnul_SAFT		&& AllTrim(Str(lnAnul_SAFT))
		PeriodEnd				=	lnLunaEnd		&& AllTrim(Str(lnLunaEnd))
		PeriodEndYear			=	lnAnul_SAFT		&& AllTrim(Str(lnAnul_SAFT))
		DocumentType			=	''
		OtherCriteria			=	''
		HeaderComment			=	ICASE( lcTipDeclaratie='A', 'A',;
			lcTipDeclaratie='C', 'C',;
			lcTipDeclaratie='T', 'T',;
			'L')
		SegmentIndex			=	'1'
		TotalSegmentsInsequence	=	'1'
		TaxAccountingBasis		=	vTipConta
		INSERT INTO Header_Structure FROM MEMVAR
		*
		SELECT Header_Structure
		SET TEXTMERGE ON TO lcDirectorSAFT+'02.Header.xml' NOSHOW
\	<Header>
\		<AuditFileVersion><<AuditFileVersion>></AuditFileVersion>
\		<AuditFileCountry><<AuditFileCountry>></AuditFileCountry>
\		<AuditFileRegion><<AuditFileRegion>></AuditFileRegion>
\		<AuditFileDateCreated><<Transform(DToS(AuditFileDateCreated), '@R ####-##-##')>></AuditFileDateCreated>
\		<SoftwareCompanyName><<AllTrim(SoftwareCompanyName)>></SoftwareCompanyName>
\		<SoftwareID><<AllTrim(SoftwareID)>></SoftwareID>
\		<SoftwareVersion><<AllTrim(SoftwareVersion)>></SoftwareVersion>
\		<Company>
\			<RegistrationNumber><<AllTrim(RegistrationNumber)>></RegistrationNumber>
\			<Name><<AllTrim(Name)>></Name>
\			<Address>
\				<StreetName><<GetOptionalXMLValue(AllTrim(StreetName))>></StreetName>
\				<Number><<GetOptionalXMLValue(AllTrim(Number))>></Number>
\				<City><<AllTrim(City)>></City>
\				<PostalCode><<GetOptionalXMLValue(AllTrim(PostalCode))>></PostalCode>
\				<Region><<GetOptionalXMLValue(AllTrim(Region))>></Region>
\				<Country><<AllTrim(Country)>></Country>
\				<AddressType><<GetOptionalXMLValue(AllTrim(AddressType))>></AddressType>
\			</Address>
		PUBLIC laContactPerson(8)
		laContactPerson(1)=''										&& tcTitle 			- OPTIONAL
		laContactPerson(2)=ICAS.oSoc.NumePersoanaAutorizata
		laContactPerson(3)=''										&& Initials			- OPTIONAL
		laContactPerson(4)=''										&& LastNamePrefix	- OPTIONAL
		laContactPerson(5)=ICAS.oSoc.PreNumePersoanaAutorizata		&& LastName
		laContactPerson(6)=''
		laContactPerson(7)=''										&& Salutation		- OPTIONAL
		laContactPerson(8)=''										&& OtherTitles		- OPTIONAL
		lcTelephone = ICAS.oSoc.Telefon
		lcFax=''
		lcEmail=ICAS.oSoc.Email
		lcWebsite=''
		*
		GetContactHeaderStructure( 'laContactPerson', lcTelephone, lcFax, lcEmail, lcWebsite )
		*
\			<TaxRegistration>
\				<TaxRegistrationNumber><<AllTrim(TaxRegistrationNumber)>></TaxRegistrationNumber>
\			</TaxRegistration>
\			<BankAccount>
			IF VerifIBAN(STRTRAN(IBANNumber, ' ', ''))
\				<IBANNumber><<AllTrim(IBANNumber)>></IBANNumber>
			ELSE
\				<BankAccountNumber><<AllTrim(BankAccountNumber)>></BankAccountNumber>
			ENDIF
\			</BankAccount>
\		</Company>
\		<DefaultCurrencyCode><<AllTrim(DefaultCurrencyCode)>></DefaultCurrencyCode>
\		<SelectionCriteria>
\			<PeriodStart><<AllTrim(Str(PeriodStart))>></PeriodStart>
\			<PeriodStartYear><<AllTrim(Str(PeriodStartYear))>></PeriodStartYear>
\			<PeriodEnd><<AllTrim(Str(PeriodEnd))>></PeriodEnd>
\			<PeriodEndYear><<AllTrim(Str(PeriodEndYear))>></PeriodEndYear>
\		</SelectionCriteria>
\		<HeaderComment><<AllTrim(HeaderComment)>></HeaderComment>
\		<SegmentIndex><<AllTrim(SegmentIndex)>></SegmentIndex>
\		<TotalSegmentsInsequence><<AllTrim(TotalSegmentsInsequence)>></TotalSegmentsInsequence>
\		<TaxAccountingBasis><<AllTrim(TaxAccountingBasis)>></TaxAccountingBasis>
\	</Header>
		SET TEXTMERGE TO
		SET TEXTMERGE OFF
		AddToLog(TRANSFORM(SECONDS()-_LastTime, [999.9999])+[ lcDirectorSAFT+'02.Header.xml' ...], lcLogFile, .T., .T.)
		__Consola_Timing("SAFT.prg : Generare XML : " + [ ]+lcDirectorSAFT+'02.Header.xml'+[...])
        
        RETURN .T.
    ENDFUNC
ENDDEFINE

*!*-----------------------------------------------------------------------------
*!* CLASS: Handler_Generate_MasterFiles_Periodic
*!* SCOP:  Genereaza toate sectiunile din MasterFiles pentru o declaratie periodica.
*!* Utilizeaza repository-ul din context pentru a obtine datele.
*!*-----------------------------------------------------------------------------
DEFINE CLASS Handler_Generate_MasterFiles_Periodic AS Handler_Base
	*2.[MasterFiles] Fisiere Master cu anumite subsectiuni:
	*	2.1 [GeneralLedgerAccounts]	Balanta contabila inclusiv clasa 8 
	*	2.3 [Customers]				Balanta de clienti 
	*	2.4 [Suppliers]				Balanta de furnizori
	*	2.5	[TaxTable]				Vectorul fiscal.
	*	2.6 [UOMTable]				Unitati de masura standardizate
	*	2.7 [AnalysisTypeTable]		Analiza pe centre de cost
	*	2.9	[Products]				Produse

    PROTECTED FUNCTION Process(toContext AS SAFT_Context) AS Boolean
        toContext.Notify("INFO", "Generare sectiune MasterFiles (Periodic)...")

        *-- Fiecare apel este acum curat si clar.
        WITH THIS
	        .Generate_GLAccounts		(toContext)
        	.Generate_Customers			(toContext)
        	.Generate_Suppliers			(toContext)
        	.Generate_UOMTable			(toContext)
        	.Generate_AnalysisTypeTable	(toContext)
        	.Generate_MovementTypeTable	(toContext)
        	.Generate_Products			(toContext)
        	
        	*.Generate_PhysicalStock(toContext)						&& CERERE
        	*.Generate_Owners(toContext)							&& CERERE
        	*.Generate_Assets(toContext)							&& ANUAL
        	*... etc.
        	
		ENDWITH
		
		STRTOFILE(;
			"<MasterFiles>";
			+FileToStr(lcDirectorSAFT+"04.GeneralLedgerAccounts.xml");
			+FileToStr(lcDirectorSAFT+"05.Customers.xml");
			+FileToStr(lcDirectorSAFT+"06.Suppliers.xml");
			+FileToStr(lcDirectorSAFT+"07.TaxTable.xml");
			+FileToStr(lcDirectorSAFT+"08.UOMTable.xml");
			+FileToStr(lcDirectorSAFT+"09.AnalysisTypeTable.xml");
			+FileToStr(lcDirectorSAFT+"10.MovementTypeTable.xml");
			+FileToStr(lcDirectorSAFT+"11.Products.xml");
			+"</MasterFiles>", toContext.WorkDir + "03.MasterFiles.xml")
        
    ENDFUNC

    PROTECTED FUNCTION Generate_GLAccounts(toContext AS SAFT_Context)
    	*-- Logica de generare XML pentru GLA...
    	*-- Aici urmeaza logica de procesare a cursorului si generare XML din _04GeneralLedgerAccounts()...
        toContext.Notify("INFO", "  - Generare 04.GeneralLedgerAccounts.xml")
        toContext.Repository.Get_04GeneralLedgerAccounts(toContext.StartDate, toContext.EndDate)
		toContext.Notify("RECORD_COUNT", "GeneralLedgerAccounts", RECCOUNT('crsGeneralLedgerAccounts'))        
        
        Select MasterFiles_GeneralLedgerAccounts
		Append From Dbf('crsGeneralLedgerAccounts')

        *SET TEXTMERGE ON TO (toContext.WorkDir + "04.GeneralLedgerAccounts.xml") NOSHOW
		SET TEXTMERGE ON TO  lcDirectorSAFT+'04.GeneralLedgerAccounts.xml' NOSHOW
		
\		<GeneralLedgerAccounts>
		SELECT MasterFiles_GeneralLedgerAccounts
		SCAN
\			<Account>
\				<AccountID><<AllTrim(AccountId)>></AccountID>
\				<AccountDescription><<AllTrim(AccountDescription)>></AccountDescription>
\				<StandardAccountID><<AllTrim(StandardAccountID)>></StandardAccountID>
\				<AccountType><<AllTrim(AccountType)>></AccountType>
			*IF OpeningDebitBalance<>0 Or (OpeningDebitBalance=0 And OpeningCreditBalance=0 And InList(AllTrim(AccountType), 'Activ', 'Bifunctional'))
			IF;
					OpeningDebitBalance<>0;
					Or (OpeningCreditBalance=0 And OpeningDebitBalance=0 And InList(AllTrim(AccountType), 'Activ', 'Bifunctional'))
\				<OpeningDebitBalance><<AllTrim(Transform(OpeningDebitBalance))>></OpeningDebitBalance>
			ELSE
\				<OpeningCreditBalance><<AllTrim(Transform(OpeningCreditBalance))>></OpeningCreditBalance>
			ENDIF
			IF;
					ClosingDebitBalance<>0;
					Or (ClosingDebitBalance=0 And ClosingCreditBalance=0 And InList(AllTrim(AccountType), 'Activ', 'Bifunctional'))
\				<ClosingDebitBalance><<AllTrim(Transform(ClosingDebitBalance))>></ClosingDebitBalance>
			ELSE
\				<ClosingCreditBalance><<AllTrim(Transform(ClosingCreditBalance))>></ClosingCreditBalance>
			ENDIF
\			</Account>
		ENDSCAN
\		</GeneralLedgerAccounts>
        SET TEXTMERGE TO
        SET TEXTMERGE OFF
		AddToLog(Transform(Seconds()-_LastTime, [999.9999])+[ lcDirectorSAFT+'04.GeneralLedgerAccounts.xml' ...], lcLogFile, .T., .T.)
		__Consola_Timing("SAFT.prg : Generare XML : " + [ ]+lcDirectorSAFT+'04.GeneralLedgerAccounts.xml'+[...])
		IF FORCE_REFRESH
			DoEvents FORCE
		ENDIF

        
    ENDFUNC

   PROTECTED FUNCTION Generate_Customers(toContext AS SAFT_Context)
	   *-- Logica de generare XML pentru Customers...
	   *-- Aici urmeaza logica de procesare a cursorului si generare XML din _05Customers()
        toContext.Notify("INFO", "  - Generare 05.Customers.xml")
        toContext.Repository.Get_05Customers(toContext.StartDate, toContext.EndDate)
		toContext.Notify("RECORD_COUNT", "Customers", RECCOUNT('crsBalCustomers'))        
        
		SELECT MasterFiles_Customers
		APPEND FROM DBF('crsBalCustomers')
		*Saft_Ecoaqua_Preluare_All_DB('Customers')
		*Saft_Ecosal_Preluare_Dbf	('Customers')
        SET TEXTMERGE ON TO (toContext.WorkDir + "05.Customers.xml") NOSHOW
        SET TEXTMERGE ON
\		<Customers>
		SELECT MasterFiles_Customers
		SCAN
\			<Customer>
\				<CompanyStructure>
\					<RegistrationNumber><<AllTrim(RegistrationNumber)>></RegistrationNumber>
\					<Name><<AllTrim(Name)>></Name>
\					<Address>
\						<City><<AllTrim(City)>></City>
\						<Country><<AllTrim(Country)>></Country>
\					</Address>
*		lcIBAN = ICase( .Not. IsNullOrEmpty(ContB1) .And. VerifIBAN(AllTrim(ContB1)), AllTrim(ALLTRIM(ContB1)), 'RO62RNCB0099007787650033')	&& penru testare
*\					<BankAccount>
*\						<IBANNumber><<lcIBAN>></IBANNumber>
*\					</BankAccount>
\				</CompanyStructure>
\				<CustomerID><<AllTrim(CustomerID)>></CustomerID>
\				<AccountID><<AllTrim(AccountID)>></AccountID>
			IF ! EMPTY(OpeningCreditBalance)
\				<OpeningCreditBalance><<AllTrim(Transform(OpeningCreditBalance))>></OpeningCreditBalance>
			ELSE
\				<OpeningDebitBalance><<AllTrim(Transform(OpeningDebitBalance))>></OpeningDebitBalance>
			ENDIF
			If ! EMPTY(ClosingCreditBalance)
\				<ClosingCreditBalance><<AllTrim(Transform(ClosingCreditBalance))>></ClosingCreditBalance>
			ELSE
\				<ClosingDebitBalance><<AllTrim(Transform(ClosingDebitBalance))>></ClosingDebitBalance>
			ENDIF
\			</Customer>
		ENDSCAN
\		</Customers>
		SET TEXTMERGE TO
		SET TEXTMERGE OFF
		
		AddToLog(Transform(Seconds()-_LastTime, [999.9999])+[ lcDirectorSAFT+'05.Customers.xml' ...], lcLogFile, .T., .T.)
		__Consola_Timing("SAFT.prg : Generare XML : " + [ ]+lcDirectorSAFT+'05.Customers.xml'+[...])

    ENDFUNC
    
    PROTECTED FUNCTION Generate_Suppliers(toContext AS SAFT_Context)
        toContext.Notify("INFO", "  - Generare 06.Suppliers.xml")
        toContext.Repository.Get_06Suppliers(toContext.StartDate, toContext.EndDate)
		toContext.Notify("RECORD_COUNT", "Suppliers", RECCOUNT('crsBalSuppliers'))         
        *-- ...
		SELECT MasterFiles_Suppliers
		APPEND FROM DBF('crsBalSuppliers')
		SET TEXTMERGE ON TO lcDirectorSAFT+'06.Suppliers.xml' NOSHOW
\		<Suppliers>
		SELECT MasterFiles_Suppliers
		SCAN
\			<Supplier>
\				<CompanyStructure>
\					<RegistrationNumber><<AllTrim(RegistrationNumber)>></RegistrationNumber>
\					<Name><<AllTrim(Name)>></Name>
\					<Address>
\						<City><<AllTrim(City)>></City>
\						<Country><<AllTrim(Country)>></Country>
\					</Address>
*!*			lcIBAN = ICase( .Not. IsNullOrEmpty(ContB1) .And. VerifIBAN(AllTrim(ContB1)), AllTrim(ALLTRIM(ContB1)), 'RO62RNCB0099007787650033')	&& penru testare
*!*	\					<BankAccount>
*!*	\						<IBANNumber><<lcIBAN>></IBANNumber>
*!*	\					</BankAccount>
\				</CompanyStructure>
\				<SupplierID><<AllTrim(SupplierID)>></SupplierID>
\				<AccountID><<AllTrim(AccountID)>></AccountID>
			IF ! EMPTY(OpeningDebitBalance)
\				<OpeningDebitBalance><<AllTrim(Transform(OpeningDebitBalance))>></OpeningDebitBalance>
			ELSE
\				<OpeningCreditBalance><<AllTrim(Transform(OpeningCreditBalance))>></OpeningCreditBalance>
			ENDIF
			IF ! EMPTY(ClosingDebitBalance)
\				<ClosingDebitBalance><<AllTrim(Transform(ClosingDebitBalance))>></ClosingDebitBalance>
			ELSE
\				<ClosingCreditBalance><<AllTrim(Transform(ClosingCreditBalance))>></ClosingCreditBalance>
			ENDIF
\			</Supplier>
		ENDSCAN
\		</Suppliers>
		SET TEXTMERGE TO
		SET TEXTMERGE OFF
		AddToLog(TRANSFORM(SECONDS()-_LastTime, [999.9999])+[ lcDirectorSAFT+'06.Suppliers.xml' ...], lcLogFile, .T., .T.)
		__Consola_Timing("SAFT.prg : Generare XML : " + [ ]+lcDirectorSAFT+'06.Suppliers.xml'+[...])
    ENDFUNC

	PROTECTED FUNCTION Generate_UOMTable(toContext AS SAFT_Context)
        toContext.Notify("INFO", "  - Generare 08UOMTable.xml")
        toContext.Repository.Get_08UOMTable(toContext.StartDate, toContext.EndDate)
		toContext.Notify("RECORD_COUNT", "Unitati de masura", RECCOUNT('crsUM'))         

		SELECT MasterFiles_UomTable
		APPEND FROM DBF('crsUM')
	SET TEXTMERGE ON TO lcDirectorSAFT+'08.UOMTable.xml' NOSHOW
\		<UOMTable>
		SELECT MasterFiles_UomTable
		SCAN
\			<UOMTableEntry>
\				<UnitOfMeasure><<GetUnitOfMeasure(AllTrim(UnitOfMeasure))>></UnitOfMeasure>
\				<Description><<AllTrim(Description)>></Description>
\			</UOMTableEntry>
		ENDSCAN
\		</UOMTable>
		SET TEXTMERGE TO
		SET TEXTMERGE OFF
		AddToLog(TRANSFORM(SECONDS()-_LastTime, [999.9999])+[ lcDirectorSAFT+'08.UOMTable.xml' ...], lcLogFile, .T., .T.)
		__Consola_Timing("SAFT.prg : Generare XML : " + [ ]+lcDirectorSAFT+'08.UOMTable.xml'+[...])

	ENDFUNC

	PROTECTED FUNCTION Generate_AnalysisTypeTable(toContext AS SAFT_Context)
        toContext.Notify("INFO", "  - Generare _09AnalysisTypeTable.xml")
        toContext.Repository.Get_09AnalysisTypeTable(toContext.StartDate, toContext.EndDate)
		toContext.Notify("RECORD_COUNT", "Centre de cost", RECCOUNT('MasterFiles_AnalysisTypeTable'))
	
		SELECT MasterFiles_AnalysisTypeTable
		SET TEXTMERGE ON TO lcDirectorSAFT+'09.AnalysisTypeTable.xml' NOSHOW
\		<AnalysisTypeTable>
\			<AnalysisTypeTableEntry>
\				<AnalysisType><<AllTrim(AnalysisType)>></AnalysisType>
\				<AnalysisTypeDescription><<AllTrim(AnalysisTypeDescription)>></AnalysisTypeDescription>
\				<AnalysisID><<AllTrim(AnalysisID)>></AnalysisID>
\				<AnalysisIDDescription><<AllTrim(AnalysisIDDescription)>></AnalysisIDDescription>
\			</AnalysisTypeTableEntry>
\		</AnalysisTypeTable>
		SET TEXTMERGE TO
		SET TEXTMERGE OFF
		AddToLog(TRANSFORM(SECONDS()-_LastTime, [999.9999])+[ lcDirectorSAFT+'09.AnalysisTypeTable.xml' ...], lcLogFile, .T., .T.)
		__Consola_Timing("SAFT.prg : Generare XML : " + [ ]+lcDirectorSAFT+'09.AnalysisTypeTable.xml'+[...])
	ENDFUNC

	PROTECTED FUNCTION Generate_MovementTypeTable(toContext AS SAFT_Context)
        toContext.Notify("INFO", "  - Generare 10MovementTypeTable.xml")
        toContext.Repository.Get_10MovementTypeTable(toContext.StartDate, toContext.EndDate)
		toContext.Notify("RECORD_COUNT", "Tipuri de miscari", IIF(USED('MasterFiles_MovementTypeTable'), RECCOUNT('MasterFiles_MovementTypeTable'), 0) )


		IF lcTipDeclaratie = 'C'  AND glPreluareDinEstoc = .T.
			*
			SELECT;
				MovementTy AS MovementType,;
				DESCRIPTIO AS DESCRIPTION  ;
			FROM Movement_Estoc;
			INTO CURSOR Movement_Estoc_Temp
			*
			SELECT MasterFiles_MovementTypeTable
			ZAP
			APPEND FROM DBF('Movement_Estoc_Temp')
		ENDIF

		SET TEXTMERGE ON TO lcDirectorSAFT+'10.MovementTypeTable.xml' NOSHOW
		*
\		<MovementTypeTable>
		*
		SELECT MasterFiles_MovementTypeTable
		SCAN
\			<MovementTypeTableEntry>
\				<MovementType><<AllTrim(MovementType)>></MovementType>
\				<Description><<AllTrim(Description)>></Description>
\			</MovementTypeTableEntry>
		ENDSCAN
		*
\		</MovementTypeTable>
		SET TEXTMERGE TO
		SET TEXTMERGE OFF
		*
		AddToLog(TRANSFORM(SECONDS()-_LastTime, [999.9999])+[ lcDirectorSAFT+'10.MovementTypeTable.xml' ...], lcLogFile, .T., .T.)
		__Consola_Timing("SAFT.prg : Generare XML : " + [ ]+lcDirectorSAFT+'10.MovementTypeTable.xml'+[...])
		*
	ENDFUNC

	PROTECTED FUNCTION Generate_Products(toContext AS SAFT_Context)
        toContext.Notify("INFO", "  - Generare 11Products.xml")
        toContext.Repository.Get_11Products(toContext.StartDate, toContext.EndDate)
		toContext.Notify("RECORD_COUNT", "Produse", RECCOUNT('crsProducts'))
	
		SELECT MasterFiles_Products
		ZAP
		APPEND FROM DBF([crsProducts])
		*
		SET TEXTMERGE ON TO lcDirectorSAFT+'11.Products.xml' NOSHOW
				\		<Products>
		SELECT MasterFiles_Products
		SCAN
\			<Product>
\				<ProductCode><<AllTrim(ProductCode)>></ProductCode>
\				<Description><<AllTrim(Description)>></Description>
\				<ProductCommodityCode><<AllTrim(ProductCommodityCode)>></ProductCommodityCode>
*!*		If !IsNullOrEmpty(CodBare)
*!*	\				<ProductNumberCode><<AllTrim(CodBare)>></ProductNumberCode>
*!*		EndIf
\				<UOMBase><<Evl(GetUnitOfMeasure(UomBase), 'H87')>></UOMBase>
\				<UOMStandard><<Evl(GetUnitOfMeasure(UOMStandard), 'H87')>></UOMStandard>
\				<UOMToUOMBaseConversionFactor><<AllTrim(Transform(UOMToUOMBaseConversionFactor))>></UOMToUOMBaseConversionFactor>
\			</Product>
		ENDSCAN
\		</Products>
		SET TEXTMERGE TO
		SET TEXTMERGE OFF
		AddToLog(TRANSFORM(SECONDS()-_LastTime, [999.9999])+[ lcDirectorSAFT+'11.Products.xml' ...], lcLogFile, .T., .T.)
		__Consola_Timing("SAFT.prg : Generare XML : " + [ ]+lcDirectorSAFT+'11.Products.xml'+[...])
	
	ENDFUNC

	PROTECTED FUNCTION Generate_PhysicalStock(toContext AS SAFT_Context)
        toContext.Notify("INFO", "  - Generare 12PhysicalStock.xml")
        toContext.Repository.Get_11Products(toContext.StartDate, toContext.EndDate)
		toContext.Notify("RECORD_COUNT", "Produse", RECCOUNT('PhysicalStock'))

		SELECT PhysicalStock
		SCAN
\			<PhysicalStockEntry>
\				<WarehouseID><<AllTrim(WareHouseId)>></WarehouseID>
\				<ProductCode><<AllTrim(ProductCode)>></ProductCode>
\				<ProductType><<AllTrim(ProductType)>></ProductType>
\				<StockAccountCommodityCode>0</StockAccountCommodityCode>
\				<OwnerID><<AllTrim(OwnerID)>></OwnerID>
\				<UOMPhysicalStock><<AllTrim(UOMPhysicalStock)>></UOMPhysicalStock>
\				<UOMToUOMBaseConversionFactor><<AllTrim(Str(UOMToUOMBaseConversionFactor))>></UOMToUOMBaseConversionFactor>
\				<UnitPrice><<AllTrim(Str(UnitPrice,15,2))>></UnitPrice>
\				<OpeningStockQuantity><<AllTrim(Str(OpeningStockQuantity,15,2))>></OpeningStockQuantity>
\				<OpeningStockValue><<AllTrim(Str(OpeningStockValue,15,2))>></OpeningStockValue>
\				<ClosingStockQuantity><<AllTrim(Str(ClosingStockQuantity,15,2))>></ClosingStockQuantity>
\				<ClosingStockValue><<AllTrim(Str(ClosingStockValue,15,2))>></ClosingStockValue>
\				<StockCharacteristics>
\					<StockCharacteristic><<AllTrim(StockCharacteristic)>></StockCharacteristic>
\					<StockCharacteristicValue><<AllTrim(StockCharacteristicValue)>></StockCharacteristicValue>
\				</StockCharacteristics>
\			</PhysicalStockEntry>
		ENDSCAN
\		</PhysicalStock>
		SET TEXTMERGE TO
		SET TEXTMERGE OFF
		AddToLog(TRANSFORM(SECONDS()-_LastTime, [999.9999])+[ lcDirectorSAFT+'12.PhysicalStock.xml' ...], lcLogFile, .T., .T.)
		__Consola_Timing("SAFT.prg : Generare XML : " + [ ]+lcDirectorSAFT+'12.PhysicalStock.xml'+[...])
			
		ENDFUNC

	PROTECTED FUNCTION Generate_Owners(toContext AS SAFT_Context)
        toContext.Notify("INFO", "  - Generare 13Owners.xml")
        toContext.Repository.Get_13Owners(toContext.StartDate, toContext.EndDate)
		toContext.Notify("RECORD_COUNT", "Owners", 0)

		SET TEXTMERGE ON TO lcDirectorSAFT+'13.Owners.xml' NOSHOW
\		<Owners/>
		SET TEXTMERGE TO
		SET TEXTMERGE OFF
		AddToLog(TRANSFORM(SECONDS()-_LastTime, [999.9999])+[ lcDirectorSAFT+'13.Owners.xml' ...], lcLogFile, .T., .T.)
		__Consola_Timing("SAFT.prg : Generare XML : " + [ ]+lcDirectorSAFT+'13.Owners.xml'+[...])

	ENDFUNC

	PROTECTED FUNCTION Generate_Assets(toContext AS SAFT_Context)
        toContext.Notify("INFO", "  - Generare _14Assets.xml")
        toContext.Repository.Get_14Assets(toContext.StartDate, toContext.EndDate)
		toContext.Notify("RECORD_COUNT", "Mijloace fixe", RECCOUNT('Assets'))

		SELECT Assets
		ZAP
		APPEND FROM DBF('Mf_Unice')
		REPLACE ALL NrCrt WITH RECNO()
		*
		SET TEXTMERGE ON TO lcDirectorSAFT+'14.Assets.xml' NOSHOW
\		<Assets>
		*
		SCAN
			*
\			<Asset>
\				<AssetID><<AllTrim(AssetId)>></AssetID>
\				<AccountID><<AllTrim(AccountID)>></AccountID>
\				<Description><<ALLTRIM(Description)>></Description>
\				<DateOfAcquisition><<Transform(DToS(DateOfAcquisition), '@R ####-##-##')>></DateOfAcquisition>
\				<StartUpDate><<Transform(DToS(StartUpDate), '@R ####-##-##')>></StartUpDate>
\				<Valuations>
\					<Valuation>
\						<AssetValuationType><<ALLTRIM(AssetValuationType)>></AssetValuationType>
\						<ValuationClass><<ALLTRIM(ValuationClass)>></ValuationClass>
\						<AcquisitionAndProductionCostsBegin><<Allt(STR(AcquisitionAndProductionCostsBegin,18,2))>></AcquisitionAndProductionCostsBegin>
\						<AcquisitionAndProductionCostsEnd><<Allt(STR(AcquisitionAndProductionCostsEnd,18,2))>></AcquisitionAndProductionCostsEnd>
\						<InvestmentSupport><<Allt(STR(InvestmentSupport,18,2))>></InvestmentSupport>
***\						<AssetLifeYear><<Allt(STR(AssetLifeYear,18,2))>></AssetLifeYear>
\						<AssetLifeMonth><<Allt(STR(AssetLifeMonth,18,2))>></AssetLifeMonth>
\						<AssetAddition><<Allt(STR(AssetAddition,18,2))>></AssetAddition>
\						<Transfers><<ALLTRIM(STR(Transfers,18,2))>></Transfers>
\						<AssetDisposal><<Allt(STR(AssetDisposal,18,2))>></AssetDisposal>
\						<BookValueBegin><<Allt(STR(BookValueBegin,18,2))>></BookValueBegin>
\						<DepreciationMethod><<ALLTRIM(DepreciationMethod)>></DepreciationMethod>
\						<DepreciationPercentage><<Allt(STR(DepreciationPercentage,18,2))>></DepreciationPercentage>
\						<DepreciationForPeriod><<Allt(STR(DepreciationForPeriod,18,2))>></DepreciationForPeriod>
\						<AppreciationForPeriod><<Allt(STR(AppreciationForPeriod,18,2))>></AppreciationForPeriod>
\						<ExtraordinaryDepreciationsForPeriod>
\							<ExtraordinaryDepreciationForPeriod>
\								<ExtraordinaryDepreciationMethod><<Allt(ExtraordinaryDepreciationMethod)>></ExtraordinaryDepreciationMethod>
\								<ExtraordinaryDepreciationAmountForPeriod><<Allt(STR(ExtraordinaryDepreciationAmountForPeriod,18,2))>></ExtraordinaryDepreciationAmountForPeriod>
\							</ExtraordinaryDepreciationForPeriod>
\						</ExtraordinaryDepreciationsForPeriod>
\						<AccumulatedDepreciation><<Allt(STR(AccumulatedDepreciation,18,2))>></AccumulatedDepreciation>
\						<BookValueEnd><<Allt(STR(BookValueEnd,18,2))>></BookValueEnd>
\					</Valuation>
\				</Valuations>
\			</Asset>
			*
		ENDSCAN
		*
\		</Assets>

		SET TEXTMERGE TO
		SET TEXTMERGE OFF
		AddToLog(TRANSFORM(SECONDS()-_LastTime, [999.9999])+[ lcDirectorSAFT+'14.Assets.xml' ...], lcLogFile, .T., .T.)
		__Consola_Timing("SAFT.prg : Generare XML : " + [ ]+lcDirectorSAFT+'14.Assets.xml'+[...])
		IF FORCE_REFRESH
			DOEVENTS FORCE
		ENDIF
	ENDFUNC

ENDDEFINE

*!*-----------------------------------------------------------------------------
*!* CLASS: Handler_Generate_SourceDocuments
*!* SCOP:  Genereaza toate sectiunile din SourceDocuments pentru o declaratie periodica.
*!* Utilizeaza repository-ul din context pentru a obtine datele.
*!*-----------------------------------------------------------------------------
DEFINE CLASS Handler_Generate_SourceDocuments AS Handler_Base
	*4.[SourceDocuments] Documentele sursa cu urmatoarea subsectiune:
	*	4.1 [SalesInvoices] Facturi de vanzare
	*	4.1 [PurchaseInvoices] Facturi de cumparare
	*	4.3 [Payments] Incasari si plati

    PROTECTED FUNCTION Process(toContext AS SAFT_Context) AS Boolean
        toContext.Notify("INFO", "Generare sectiune SourceDocuments (Periodic)...")
        
        WITH THIS
        	.Generate_SalesInvoices(toContext)
        	.Generate_PurchaseInvoices(toContext)
        	.Generate_Payments(toContext)
		ENDWITH

		STRTOFILE(;
			"<SourceDocuments>";
			+ FILETOSTR(lcDirectorSAFT+'18.SalesInvoices.xml');
			+ FILETOSTR(lcDirectorSAFT+'19.PurchaseInvoices.xml');
			+ FILETOSTR(lcDirectorSAFT+'20.Payments.xml');
        	+"</SourceDocuments>", toContext.WorkDir + "17.SourceDocuments.xml")
        RETURN .T.
    ENDFUNC

	PROTECTED FUNCTION Generate_SalesInvoices(toContext AS SAFT_Context)
        toContext.Notify("INFO", "  - Generare _18SalesInvoice.xml")
        toContext.Repository.Get_18SalesInvoices(toContext.StartDate, toContext.EndDate)
		toContext.Notify("RECORD_COUNT", "Facturi de vanzare", RECCOUNT('crsSalesInvoices'))
		
		IF m.NumeDB <> "ecuaqua"
			SELECT DISTINCT InvoiceNo, InvoiceDate, AccountID FROM crsSalesInvoices INTO ARRAY aGetNumberOfEntries
		ELSE
			SELECT DISTINCT InvoiceNo, InvoiceDate			  FROM crsSalesInvoices INTO ARRAY aGetNumberOfEntries
		ENDIF
		*
		lnNumberOfEntries=ICASE(_TALLY>0, _TALLY, 0)
		Tabela_Erori_Saft("SalesInvoices")
		*
		SELECT SourceDocuments_SalesInvoices
		&& 28.08.2024
		*Append From Dbf([crsSalesInvoices])
		&& 28.08.2024

		*!*	Append From Dbf([crsSalesInvoices]) For Not InList(crsSalesInvoices.TipFactura, 'A', 'B', 'C', 'E', 'n')
		IF m.NumeDB <> "ecuaqua"    &&& 27.05.2025
			APPEND FROM DBF([crsSalesInvoices]) FOR NOT INLIST(crsSalesInvoices.TipFactura, 'A', 'B', 'C', 'E', 'n')
		ELSE
			APPEND FROM DBF([crsSalesInvoices])
		ENDIF
		*
		SELECT;
			SUM(IIF( TaxBase+TaxAmount>=0, TaxBase+TaxAmount, 00000000000.00 )) AS Total_C,;
			SUM(IIF( TaxBase+TaxAmount< 0, TaxBase+TaxAmount, 00000000000.00 )) AS Total_D;
		FROM SourceDocuments_SalesInvoices;
		INTO CURSOR cGetTotaluri_SourceDocuments_SalesInvoices
		*
		lnTotal_Credit 	=	Total_C
		lnTotal_Debit 	=	Total_D
		*
		SELECT SourceDocuments_SalesInvoices
		*
		*** la 1000 inreg cistig ~15 sec., la ~22333 vreo 300 sec.
		*
		*Update SourceDocuments_SalesInvoices Set Index_V = AllTrim(InvoiceNo)+'#'+AllTrim(DToC(InvoiceDate))+'#'+ AllTrim(AccountID)
		*Update SourceDocuments_SalesInvoices Set Index_V = ID	&& Vicos.18.07.2023
		*Index On Index_V Tag Viteza
		*Index On ID Tag Viteza										&& Vicos.18.07.2023
		INDEX ON IdFactura TAG Viteza										&& Vicos.18.07.2023
		SET ORDER TO Viteza
		*
		LOCATE
		*Replace NumberOfEntries With lnNumberOfEntries, TotalDebit With 0, TotalCredit With lnTotalSuma
		REPLACE NumberOfEntries WITH lnNumberOfEntries, TotalDebit WITH lnTotal_Debit, TotalCredit WITH lnTotal_Credit
		*
		*Select Distinct Id From crsSalesInvoices Into Cursor cIDuri
		***	Select Distinct InvoiceNo, InvoiceDate, AccountID From SourceDocuments_SalesInvoices Into Cursor cIDuri
		*Select Distinct ID, InvoiceNo, InvoiceDate, AccountID From SourceDocuments_SalesInvoices Order By Id Into Cursor cIDuri_SourceDocuments_SalesInvoices	&& Vicos.18.07.2023
		*Select Distinct ID, InvoiceNo, InvoiceDate, AccountID From SourceDocuments_SalesInvoices Order By InvoiceDate, Id Into Cursor cIDuri_SourceDocuments_SalesInvoices	&& Vicos.18.07.2023
		*
		IF m.NumeDB <> "ecuaqua"
			*
			SELECT DISTINCT;
				IdFactura,;
				InvoiceNo,;
				InvoiceDate,;
				AccountID,;
				TipDocument;
				FROM SourceDocuments_SalesInvoices;
				ORDER BY;
				TipDocument, InvoiceDate, ID;
				INTO CURSOR cIDuri_SourceDocuments_SalesInvoices	&& Vicos.18.07.2023
			*
		ELSE
			**** idfactura ( nrfact+id in firebird) este unic la mine in programele de facturare pe fiecare localitate (bloc/case/firme si diverse)
			SELECT DISTINCT;
				IdFactura;
			FROM SourceDocuments_SalesInvoices;
			ORDER BY InvoiceNo;
			INTO CURSOR cIDuri_SourceDocuments_SalesInvoices	&& nic.28.07.2023
		ENDIF
		*
		SET TEXTMERGE ON TO lcDirectorSAFT+'18.SalesInvoices.xml' NOSHOW
\		<SalesInvoices>
		&& 28Feb2025
		IF lnNumberOfEntries>0

\			<NumberOfEntries><<Transform(lnNumberOfEntries)>></NumberOfEntries>
\			<TotalDebit><<Str(lnTotal_Debit, 18, 2)>></TotalDebit>
\			<TotalCredit><<Str(lnTotal_Credit, 18, 2)>></TotalCredit>

		ENDIF
		&& 28Feb2025
		SELECT cIDuri_SourceDocuments_SalesInvoices	&& Vicos.18.07.2023
		lnNrCrt = 0
		*
		SCAN  &&&& For RecNo()< 50
			*
			SELECT SourceDocuments_SalesInvoices
			***Locate For AllTrim(InvoiceNo)==AllTrim(cIDuri_SourceDocuments_SalesInvoices.InvoiceNo) And InvoiceDate=cIDuri_SourceDocuments_SalesInvoices.InvoiceDate And AllTrim(AccountID)==AllTrim(cIDuri_SourceDocuments_SalesInvoices.AccountID)
			*Seek( AllTrim(cIDuri_SourceDocuments_SalesInvoices.InvoiceNo)+'#'+ ALLTRIM(DTOC(cIDuri_SourceDocuments_SalesInvoices.InvoiceDate)) +'#'+AllTrim(cIDuri_SourceDocuments_SalesInvoices.AccountID) )
			***Seek( cIDuri_SourceDocuments_SalesInvoices.IDFactura)	&& Vicos.18.07.2023
			***cIndex_V_Seek = SourceDocuments_SalesInvoices.IDFactura	&& Vicos.18.07.2023		???
			*
			lnNrCrt	= lnNrCrt + 1
			***Replace NrCrt With lnNrCrt In SourceDocuments_SalesInvoices  &&& scos de nic pe 25-09-2024 poate avea 2 pozitii factura si se punea doar pe una
			REPLACE NrCrt WITH lnNrCrt FOR IdFactura = cIDuri_SourceDocuments_SalesInvoices.IdFactura  IN SourceDocuments_SalesInvoices
			SEEK( cIDuri_SourceDocuments_SalesInvoices.IdFactura) && se repune pe una pt. a pune date in antet

			*
\			<Invoice>
\				<InvoiceNo><<AllTrim(InvoiceNo)>></InvoiceNo>
\				<CustomerInfo>
\					<CustomerID><<AllTrim(CustomerID)>></CustomerID>
\					<BillingAddress>
\						<City><<AllTrim(City)>></City>
\						<Country><<Country>></Country>
\					</BillingAddress>
\				</CustomerInfo>
\				<AccountID><<AllTrim(AccountID)>></AccountID>
\				<InvoiceDate><<Transform(DToS(InvoiceDate), '@R ####-##-##')>></InvoiceDate>
\				<InvoiceType><<AllTrim(InvoiceType)>></InvoiceType>
\				<SelfBillingIndicator><<AllTrim(SelfBillingIndicator)>></SelfBillingIndicator>
			lnLineNumber=0
			*
			*Scan For Id=cIDuri_SourceDocuments_SalesInvoices.ID
			***Scan For AllTrim(InvoiceNo)==AllTrim(cIDuri_SourceDocuments_SalesInvoices.InvoiceNo) And InvoiceDate=cIDuri_SourceDocuments_SalesInvoices.InvoiceDate And AllTrim(AccountID)==AllTrim(cIDuri_SourceDocuments_SalesInvoices.AccountID)
			****Scan For Index_V = cIndex_V_Seek  &&& ~ de 10 ori mai rapida
			*Scan For Id=cIDuri_SourceDocuments_SalesInvoices.ID		&& Vicos.18.07.2023
			SCAN FOR IdFactura=cIDuri_SourceDocuments_SalesInvoices.IdFactura		&& Vicos.18.07.2023
				*
				lnLineNumber = lnLineNumber + 1
				REPLACE LineNumber WITH lnLineNumber
				*
				&& Vicos.31.08.2023
				*
\				<InvoiceLine>
\					<LineNumber><<Transform(LineNumber)>></LineNumber>
\					<AccountID><<AllTrim(LineAccountID)>></AccountID>
				IF m.NumeDB <> "ecuaqua" 
\					<ProductCode><<AllTrim(ProductCode)>></ProductCode>
				ENDIF	
*\					<ProductDescription><<AllTrim(Description)>></ProductDescription>
\					<Quantity><<Transform(Quantity)>></Quantity>
\					<UnitPrice><<Transform(Round(UnitPrice, 2))>></UnitPrice>
\					<TaxPointDate><<Transform(DToS(TaxPointDate), '@R ####-##-##')>></TaxPointDate>
\					<Description><<AllTrim(Description)>></Description>
\					<InvoiceLineAmount>
\						<Amount><<Transform(Round(Amount,2))>></Amount>
\						<CurrencyCode><<Upper(CurrencyCode)>></CurrencyCode>
\						<CurrencyAmount><<Transform(Round(Nvl(CurrencyAmount, 0), 2))>></CurrencyAmount>
\						<ExchangeRate><<Transform(ExchangeRate)>></ExchangeRate>
\					</InvoiceLineAmount>
\					<DebitCreditIndicator><<AllTrim(DebitCreditIndicator)>></DebitCreditIndicator>
\					<TaxInformation>
\						<TaxType><<AllTrim(TaxType)>></TaxType>
\						<TaxCode><<AllTrim(TaxCode)>></TaxCode>
\						<TaxPercentage><<Transform(TaxPercentage)>></TaxPercentage>
\						<TaxBase><<Transform(TaxBase)>></TaxBase>
\						<TaxBaseDescription><<AllTrim(TaxBaseDescription)>></TaxBaseDescription>
\						<TaxAmount>
\							<Amount><<Transform(TaxAmount)>></Amount>
\							<CurrencyCode><<Upper(TaxCurrencyCode)>></CurrencyCode>
\							<CurrencyAmount><<Transform(TaxCurrencyAmount)>></CurrencyAmount>
\							<ExchangeRate><<Transform(TaxExchangeRate)>></ExchangeRate>
\						</TaxAmount>
\					</TaxInformation>
\				</InvoiceLine>
			ENDSCAN
			*
\			</Invoice>
		ENDSCAN
\		</SalesInvoices>
		SET TEXTMERGE TO
		SET TEXTMERGE OFF
		*
		AddToLog(TRANSFORM(SECONDS()-_LastTime, [999.9999])+[ lcDirectorSAFT+'18.SalesInvoices.xml' ...], lcLogFile, .T., .T.)
		__Consola_Timing("SAFT.prg : Generare XML : " + [ ]+lcDirectorSAFT+'18.SalesInvoices.xml'+[...])
		IF FORCE_REFRESH
			DOEVENTS FORCE
		ENDIF
	ENDFUNC	

	PROTECTED FUNCTION Generate_PurchaseInvoices(toContext AS SAFT_Context)
        toContext.Notify("INFO", "  - Generare _19PurchaseInvoices.xml")
        toContext.Repository.Get_19PurchaseInvoices(toContext.StartDate, toContext.EndDate)
		toContext.Notify("RECORD_COUNT", "Facturi de intrare", RECCOUNT('crsPurchaseInvoices'))

		SELECT;
			SUM(IIF( Amount+TaxAmount>=0, ICASE(TipFactura='T' AND Tip_Tert='1', Amount, Amount+TaxAmount), 00000000000.00 )) AS Facturi_D,;
			SUM(IIF( Amount+TaxAmount< 0, ICASE(TipFactura='T' AND Tip_Tert='1', Amount, Amount+TaxAmount), 00000000000.00 )) AS Facturi_C,;
			SUM(Amount+TaxAmount) AS Facturi_All;
		FROM crsPurchaseInvoices;
		INTO CURSOR cGetTotaluriPurchaseInvoices
		*
		SELECT DISTINCT InvoiceNo, InvoiceDate, AccountID FROM crsPurchaseInvoices INTO ARRAY aGetNumberOfEntries
		lnNumberOfEntries=ICASE(_TALLY>0, _TALLY, 0)
		*
		UPDATE crsPurchaseInvoices SET TaxCode		= 'Necompletat' WHERE ISNULL(TaxCode)
		UPDATE crsPurchaseInvoices SET Furnizor		= Elimin_Dia(Furnizor), City=Elimin_Dia(City)
		UPDATE crsPurchaseInvoices SET DESCRIPTION	= Elimin_Dia(DESCRIPTION)
		UPDATE crsPurchaseInvoices SET DESCRIPTION	= ReplaceDiacritics(DESCRIPTION)							&& 03.12.2024
		&&-27.06.2025
		UPDATE crsPurchaseInvoices;
		SET TaxType='300';
		WHERE;
			LEN(TaxCode)>0;
			AND;
				(;
				TaxCode<>'000000';
				OR;
				TaxCode<>'#TaxCode';
				)

		UPDATE crsPurchaseInvoices;
		SET TaxType='000';
		WHERE;
			LEN(TaxCode)>0;
			AND;
				(;
				TaxCode='000000';
				OR;
				TaxCode='#TaxCode';
			)
		&&-27.06.2025

		SELECT SourceDocuments_PurchaseInvoices
		APPEND FROM DBF('crsPurchaseInvoices')		&& Field TAXPERCENTAGE does not accept null values.
		*
		&&-- 27.06.2025
		*!*	*-- 27.03.2025
		*!*	If Icas.oSoc.ModPlataTva=3  &&& neplatitori tva
		*!*		Update;
		*!*			SourceDocuments_PurchaseInvoices;
		*!*		Set;
		*!*				TaxType	= '000';
		*!*			,	TaxCode	= '000000';
		*!*		Where;
		*!*				TaxType = '300'
		*!*	EndIf
		*!*	*-- 27.03.2025
		*-- 27.06.2025
		*
		INDEX ON IDFactura TAG IDFactura		&& Vicos.18.07.2023
		SET ORDER TO TAG IDFactura				&& Vicos.18.07.2023
		*
		LOCATE
		REPLACE NumberOfEntries WITH lnNumberOfEntries, TotalDebit WITH cGetTotaluriPurchaseInvoices.Facturi_D, TotalCredit WITH cGetTotaluriPurchaseInvoices.Facturi_C
		*
		*
		SET TEXTMERGE ON TO lcDirectorSAFT+'19.PurchaseInvoices.xml' NOSHOW
\		<PurchaseInvoices>

		&& 28Feb2025
		*
		IF lnNumberOfEntries>0
\			<NumberOfEntries><<Transform(lnNumberOfEntries)>></NumberOfEntries>
\			<TotalDebit><<Str(TotalDebit, 18, 2)>></TotalDebit>
\			<TotalCredit><<Str(TotalCredit, 18, 2)>></TotalCredit>
		ENDIF
		*
		&& 28Feb2025
		*!*	Select Distinct;
		*!*		IdFactura, InvoiceNo, InvoiceDate, AccountID, TipDocument;
		*!*	From SourceDocuments_PurchaseInvoices;
		*!*	Where;
		*!*		TipFactura<>'C';					&& Intrari.Tip=9, "C","Bonuri Fiscale CU CIF (cu valoare de factura simplificata)",1
		*!*	Order By TipDocument, InvoiceDate, Id;
		*!*	Into Cursor cIDuri	&& Vicos18.07.2023
		*
		&&*-- Vicos.23.06.2026 - nu dadea Nrcrt pentru bonuri fiscale operate pe intrari
		*
		&&& Bon Fiscal cu CIF nu se trece in PurchaseInvoices;
		&&& il las totusi aici pt. ca ulterior GLE face update la DataDocReala cu ce exista in PurchaseInvoices
		**
		&&*-- Vicos.23.06.2026 - nu dadea Nrcrt pentru bonuri fiscale operate pe intrari
		SELECT DISTINCT;
			IDFactura, InvoiceNo, InvoiceDate, AccountID, TipDocument;
		FROM SourceDocuments_PurchaseInvoices;
		ORDER BY TipDocument, InvoiceDate, ID;
		INTO CURSOR cIDuri	&& Vicos18.07.2023
		*
		SELECT cIDuri
		lnNrCrt = 0
		SCAN
			*
			SELECT SourceDocuments_PurchaseInvoices
			***Seek (cIDuri.IDFactura)	&& Vicos.18.07.2023 scos nic pe 25-09-2024 poate avea 2 conturi deci > 1 pozitie
			lnNrCrt = lnNrCrt + 1
			***Replace NrCrt With lnNrCrt In SourceDocuments_PurchaseInvoices	scos nic pe 25-09-2024
			REPLACE NrCrt WITH lnNrCrt FOR IDFactura=cIDuri.IDFactura  IN SourceDocuments_PurchaseInvoices
			SEEK (cIDuri.IDFactura) && se repune pe oricare pt. a pune date in antet
			*

\			<Invoice>
\				<InvoiceNo><<AllTrim(InvoiceNo)>></InvoiceNo>
\				<SupplierInfo>
\					<SupplierID><<AllTrim(SupplierID)>></SupplierID>
\					<BillingAddress>
\						<City><<AllTrim(City)>></City>
\						<Country><<AllTrim(Country)>></Country>
\					</BillingAddress>
\				</SupplierInfo>
\				<AccountID><<Cont_SAFT(AccountID)>></AccountID>
\				<InvoiceDate><<Transform(DToS(InvoiceDate), '@R ####-##-##')>></InvoiceDate>
\				<InvoiceType>380</InvoiceType>
\				<SelfBillingIndicator>0</SelfBillingIndicator>
			lnLineNumber=0
			*
			LOCAL cSir_Servicii
			*cSir_Servicii= InList( Left(AllTrim(Nvl(LineAccountId,'')),2), '62','63','64','65','66','67','68','69', '46')
			cSir_Servicii= INLIST( LEFT(ALLTRIM(NVL(LineAccountId,'')), 2), '62','63','64','65','66','67','68','69', '46') OR LEFT(ALLTRIM(NVL(LineAccountId,'')), 3)='409'
			SELECT SourceDocuments_PurchaseInvoices
			SCAN FOR IDFactura=cIDuri.IDFactura		&& Vicos.18.07.2023
				lnLineNumber = lnLineNumber + 1
\				<InvoiceLine>
\					<LineNumber><<Transform(lnLineNumber)>></LineNumber>
\					<AccountID><<Cont_SAFT(LineAccountId)>></AccountID>
				IF m.NumeDB <> "ecuaqua" 
\					<ProductCode><<AllTrim(ProductCode)>></ProductCode>
				ENDIF
*\					<ProductDescription><<AllTrim(Description)>></ProductDescription>
\					<Quantity><<Transform(Quantity)>></Quantity>
\					<UnitPrice><<Transform(Round(UnitPrice,2))>></UnitPrice>
\					<TaxPointDate><<Date2ISO(TaxPointDate)>></TaxPointDate>
\					<Description><<AllTrim(Description)>></Description>
\					<InvoiceLineAmount>
\						<Amount><<Transform(Round(Amount,2))>></Amount>
\						<CurrencyCode><<Upper(CurrencyCode)>></CurrencyCode>
\						<CurrencyAmount><<Transform(CurrencyAmount)>></CurrencyAmount>
\						<ExchangeRate><<Transform(Round(ExchangeRate, 4))>></ExchangeRate>
\					</InvoiceLineAmount>
\					<DebitCreditIndicator><<AllTrim(DebitCreditIndicator)>></DebitCreditIndicator>
				*
				FOR Pozitie_Factura_Se_Duce_In_Mai_Multe_Rinduri_In_D300=1 TO 2
\					<TaxInformation>
\						<TaxType><<AllTrim(TaxType)>></TaxType>
\						<TaxCode><<ICase(TaxType = '000', '000000', Pozitie_Factura_Se_Duce_In_Mai_Multe_Rinduri_In_D300=1,AllTrim(TaxCode),AllTrim(cAlDoileaTaxCode))>></TaxCode>
\						<TaxPercentage><<Transform(TaxPercentage)>></TaxPercentage>
\						<TaxBase><<Transform(TaxBase)>></TaxBase>
\						<TaxBaseDescription><<AllTrim(TaxBaseDescription)>></TaxBaseDescription>
\						<TaxAmount>
\							<Amount><<Transform(Round(TaxAmount,2))>></Amount>
\							<CurrencyCode><<Upper(CurrencyCode)>></CurrencyCode>
\							<CurrencyAmount><<Transform(TaxCurrencyAmount)>></CurrencyAmount>
\							<ExchangeRate><<Transform(Round(ExchangeRate,4))>></ExchangeRate>
\						</TaxAmount>
\					</TaxInformation>
					DO CASE
							*
						CASE CodTva='13'
							IF cSir_Servicii
								cAlDoileaTaxCode = '308303'
							ELSE
								cAlDoileaTaxCode = '308302'
							ENDIF
							*!*						cAlDoileaTaxCode = ICase( cTip_Ded= '100', '308303',;	 				&&& Rd. 30.1 Achizitii de servicii intracomunitare scutite de taxa
							*!*												  cTip_Ded=  '50', '348303',;
							*!*												  cTip_Ded=  '00', '358303' )
							*
						CASE CodTva='11-12' AND Vies=.T.   &&& cIsPlatitorTVa='da'						&& AIC taxabile
							cAlDoileaTaxCode = ICASE( cTip_Ded= '100' AND TaxPercentage= 5, '300203',;  &&& Rd. 5.1 Bunuri intracomunitare-furnizor   platitor de tva
							cTip_Ded=  '50' AND TaxPercentage= 5, '390203',;
								cTip_Ded=  '00' AND TaxPercentage= 5, '350203',;
								cTip_Ded= '100' AND TaxPercentage= 9, '300202',;  &&& Rd. 5.1 Bunuri intracomunitare-furnizor   platitor de tva
							cTip_Ded=  '50' AND TaxPercentage= 9, '390202',;
								cTip_Ded=  '00' AND TaxPercentage= 9, '350202',;
								cTip_Ded= '100' AND TaxPercentage=19, '300201',;  &&& Rd. 5.1 Bunuri intracomunitare-furnizor   platitor de tva
							cTip_Ded=  '50' AND TaxPercentage=19, '390201',;
								cTip_Ded=  '00' AND TaxPercentage=19, '350201' ;
								)
							*
						CASE CodTva='15-16' &&& pe rind factura poate fi cu bunuri sau servicii( nu pot fi simultan)
							cAlDoileaTaxCode = ICASE( cTip_Ded= '100' AND TaxPercentage= 5 AND NOT cSir_Servicii, '300603',;  &&& Rd. 7 Import de bunuri 5% (TVA supusa  masurilor de simplificare)
							cTip_Ded=  '50' AND TaxPercentage= 5 AND NOT cSir_Servicii, '390603',;
								cTip_Ded=  '00' AND TaxPercentage= 5 AND NOT cSir_Servicii, '350603',;
								cTip_Ded= '100' AND TaxPercentage= 9 AND NOT cSir_Servicii, '300602',;  &&& Rd. 7	Import de bunuri 9% (TVA supusa masurilor de simplificare)
							cTip_Ded=  '50' AND TaxPercentage= 9 AND NOT cSir_Servicii, '390602',;
								cTip_Ded=  '00' AND TaxPercentage= 9 AND NOT cSir_Servicii, '350602',;
								cTip_Ded= '100' AND TaxPercentage=19 AND NOT cSir_Servicii, '300601',;  &&& Rd. 7 Import de bunuri 19% (TVA supusa  masurilor de simplificare)
							cTip_Ded=  '50' AND TaxPercentage=19 AND NOT cSir_Servicii, '390601',;
								cTip_Ded=  '00' AND TaxPercentage=19 AND NOT cSir_Servicii, '350601',;
								cTip_Ded= '100' AND TaxPercentage= 5 AND     cSir_Servicii, '300703',;  &&& Rd. 7.1 DOAR Achizitii de servicii intracomunitare (AIC de servicii cf reg B2B) 5%
							cTip_Ded=  '50' AND TaxPercentage= 5 AND     cSir_Servicii, '390703',;
								cTip_Ded=  '00' AND TaxPercentage= 5 AND     cSir_Servicii, '350703',;
								cTip_Ded= '100' AND TaxPercentage= 9 AND     cSir_Servicii, '300702',;  &&& Rd. 7.1 DOAR Achizi?ii de servicii intracomunitare  (AIC de servicii cf reg B2B) 9%
							cTip_Ded=  '50' AND TaxPercentage= 9 AND     cSir_Servicii, '390702',;
								cTip_Ded=  '00' AND TaxPercentage= 9 AND     cSir_Servicii, '350702',;
								cTip_Ded= '100' AND TaxPercentage=19 AND     cSir_Servicii, '300701',;  &&& Rd. 7.1  DOAR Achizitii de servicii intracomunitare (AIC de servicii cf reg B2B) 19%
							cTip_Ded=  '50' AND TaxPercentage=19 AND     cSir_Servicii, '390701',;
								cTip_Ded=  '00' AND TaxPercentage=19 AND     cSir_Servicii, '350701' ;
								)
							*
						OTHERWISE
							EXIT
							*
					ENDCASE
					*
				ENDFOR
\				</InvoiceLine>
			ENDSCAN
\			</Invoice>
		ENDSCAN
\		</PurchaseInvoices>
		SET TEXTMERGE TO
		SET TEXTMERGE OFF
		AddToLog(TRANSFORM(SECONDS()-_LastTime, [999.9999])+[ lcDirectorSAFT+'19.PurchaseInvoices.xml' ...], lcLogFile, .T., .T.)
		__Consola_Timing("SAFT.prg : Generare XML : " + [ ]+lcDirectorSAFT+'19.PurchaseInvoices.xml'+[...])
		IF FORCE_REFRESH
			DOEVENTS FORCE
		ENDIF

	ENDFUNC


	PROTECTED FUNCTION Generate_Payments(toContext AS SAFT_Context)
        toContext.Notify("INFO", "  - Generare _20Payments.xml")
        toContext.Repository.Get_20Payments(toContext.StartDate, toContext.EndDate)
		toContext.Notify("RECORD_COUNT", "Incasari si plati", RECCOUNT('crsPayments'))

		SELECT SUM(IIF( DebitCreditIndicator='D', Amount, 00000000.00 )) AS Payments_D,; &&& nu e corect - asta e doar catre furnizori / clienti dar poate fi si altfel
		SUM(IIF( DebitCreditIndicator='C', Amount, 00000000.00 )) AS Payments_C ;
		FROM crsPayments;
		INTO CURSOR cGetTotaluricrsPayments
		*
		SELECT SUM(Amount) AS Suma_Compensare ;
		FROM crsPayments;
		WHERE;
			INLIST( LEFT(crsPayments.ContD,3),'401','403','404')  AND LEN(crsPayments.ContD)>3 AND ;
			LEFT(crsPayments.ContC,3)='411' AND LEN(crsPayments.ContC)>3 ;
		INTO CURSOR SumaCompensari
		LOCATE
		*compensarea a 2 parte este inclusa in acelasi document cu prima parte >>>> 1 singura plata
		SELECT SourceDocuments_Payments
		APPEND FROM DBF('crsPayments')

		SET TEXTMERGE ON TO lcDirectorSAFT+'20.Payments.xml' NOSHOW
\		<Payments>

*!*	\			<NumberOfEntries><<Transform(Reccount('SourceDocuments_Payments'))>></NumberOfEntries>
*!*	\			<TotalDebit><<Str(cGetTotaluricrsPayments.Payments_D + Nvl(SumaCompensari.Suma_Compensare,0), 18, 2)>></TotalDebit>
*!*	\			<TotalCredit><<Str(cGetTotaluricrsPayments.Payments_C, 18, 2)>></TotalCredit>

		lnNumberOfEntries__Payments = RECCOUNT('SourceDocuments_Payments')
		*
		IF lnNumberOfEntries__Payments >0

\			<NumberOfEntries><<Transform(lnNumberOfEntries__Payments)>></NumberOfEntries>
\			<TotalDebit><<Str(cGetTotaluricrsPayments.Payments_D + Nvl(SumaCompensari.Suma_Compensare,0), 18, 2)>></TotalDebit>
\			<TotalCredit><<Str(cGetTotaluricrsPayments.Payments_C, 18, 2)>></TotalCredit>

		ENDIF

		*lnLineNumber=0

		SELECT SourceDocuments_Payments
		SCAN
			*lnLineNumber= lnLineNumber+1
			*
\			<Payment>
\				<PaymentRefNo><<AllTrim(Transform(PaymentRefNo))>></PaymentRefNo>
\				<TransactionDate><<Transform(DToS(TransactionDate), '@R ####-##-##')>></TransactionDate>
\				<PaymentMethod><<AllTrim(PaymentMethod)>></PaymentMethod>
\				<Description><<AllTrim(Description)>></Description>

			STORE '' TO cAccountID2, cCustomerID2, cSupplierID2, cDebitCreditIndicator2
			FOR compensarea_egal_2_plati= 1 TO 2 &&& 1 normal , 2-compensare/ SAU EX. 4315-4316 AMBELE CONTURI AU TAXTYPE (CAS SI SANATATE)

\				<PaymentLine>
*\					<LineNumber><<TRANSFORM(lnLineNumber)>></LineNumber>
\					<AccountID><< AllTrim(Iif( compensarea_egal_2_plati= 1, AccountId , cAccountID2 ))>></AccountID>
\					<CustomerID><<AllTrim(Iif( compensarea_egal_2_plati= 1, CustomerID, cCustomerID2))>></CustomerID>
\					<SupplierID><<AllTrim(Iif( compensarea_egal_2_plati= 1, SupplierID, cSupplierID2))>></SupplierID>
\					<DebitCreditIndicator><<Iif( compensarea_egal_2_plati= 1, AllTrim(DebitCreditIndicator), cDebitCreditIndicator2)>></DebitCreditIndicator>
\					<PaymentLineAmount>
\						<Amount><<AllTrim(Str(Amount,15,2))>></Amount>
\						<CurrencyCode><<AllTrim(Upper(CurrencyCode))>></CurrencyCode>
\						<CurrencyAmount><<AllTrim(Str(CurrencyAmount,15,2))>></CurrencyAmount>
\						<ExchangeRate><<AllTrim(Str(ExchangeRate,10,4)))>></ExchangeRate>
\					</PaymentLineAmount>
\					<TaxInformation>
\						<TaxType><<AllTrim(TaxType)>></TaxType>
\						<TaxCode><<AllTrim(TaxCode)>></TaxCode>
\						<TaxAmount>
\							<Amount><<AllTrim(Str(TaxAmount,15,2))>></Amount>
\							<CurrencyCode><<AllTrim(Upper(TaxCurrencyCode))>></CurrencyCode>
\							<CurrencyAmount><<AllTrim(Str(TaxCurrencyAmount,15,2))>></CurrencyAmount>
\							<ExchangeRate><<AllTrim(Str(TaxExchangeRate,10,4))>></ExchangeRate>
\						</TaxAmount>
\					</TaxInformation>
\				</PaymentLine>

				IF compensarea_egal_2_plati=1 AND ;
						( ( INLIST( LEFT(ContD,3),'401','403','404')  AND LEN(ContD)>3 AND LEFT(ContC,3)='411' AND LEN(ContC)>3;
						) OR ; &&& caz 1 :zz= compensare
					(LEN(ALLTRIM(NVL(TaxType_CR,'')))=3 AND ALLTRIM(NVL(TaxType_CR,''))<>'000') ;
						)
					&&& caz 2: contD si ContC ambele cu TaxCode
					*    D     C    suma
					*zz 401   411    15  compensare				CustomerID =411		SupplierID =401
					*** la prima trecere  CustomerID= cCod_Fiscal si SupllierID='0' (Get_CustomerID_Payments/Get_SupllierID_Payments)
					*411, customerid,C  =creditdebitindicator
					*401,  suplierid,D	=creditdebitindicator

					cAccountID2  = Cont_Saft(ContC)
					cSupplierID2 = '0'
					cDebitCreditIndicator2 = 'D'
					cCustomerID2 = Get_SupplierID_Payments( ContD, ContC, CUI_2_Comp, Amount )
					*WAIT WINDOW 'CUI_2_Comp='+CUI_2_Comp+CHR(13)+;
					'ContD='+ContD+CHR(13)+;
					'ContC='+ContC+CHR(13)+;
					'cCustomerID2='+cCustomerID2
					SELECT Terti
					LOCATE FOR ALLTRIM(Cod_Fiscal)==ALLTRIM(cCustomerID2 )
					IF FOUND()
						cCustomerID2 = Terti.RegistrationNumber
					ENDIF
					&&&
					SELECT SourceDocuments_Payments
				ELSE
					EXIT
				ENDIF
			ENDFOR
\			</Payment>
			*
		ENDSCAN
		*
\		</Payments>
		SET TEXTMERGE TO
		SET TEXTMERGE OFF
		AddToLog(TRANSFORM(SECONDS()-_LastTime, [999.9999])+[ lcDirectorSAFT+'20.Payments.xml' ...], lcLogFile, .T., .T.)
		__Consola_Timing("SAFT.prg : Generare XML : " + [ ]+lcDirectorSAFT+'20.Payments.xml'+[...])
		IF FORCE_REFRESH
			DOEVENTS FORCE
		ENDIF

	ENDFUNC		

ENDDEFINE
*!*-----------------------------------------------------------------------------
*!* CLASS: Handler_Generate_GeneralLedgerEntries
*!* SCOP:  Genereaza registrul jurnal
*!* Utilizeaza repository-ul din context pentru a obtine datele.
*!*-----------------------------------------------------------------------------
DEFINE CLASS Handler_Generate_GeneralLedgerEntries AS Handler_Base

    PROTECTED FUNCTION Process(toContext AS SAFT_Context) AS Boolean
        toContext.Notify("INFO", "  - Generare _16GeneralLedgerEntries.xml")
        toContext.Repository.Get_16GeneralLedgerEntries(toContext.StartDate, toContext.EndDate)
		toContext.Notify("RECORD_COUNT", "Registru Jurnal", RECCOUNT('cGeneralLedgerEntries_Linii'))
		    
		SELECT cGeneralLedgerEntries_Linii
		INDEX ON Id_Nota TAG Id_Nota
		SELECT cGeneralLedgerEntries
		INDEX ON Id_Nota TAG Id_Nota
		SET RELATION TO Id_Nota INTO cGeneralLedgerEntries_Linii ADDITIVE
		*
		SELECT cGeneralLedgerEntries_Linii
		lnNumberOfEntries	=	RECCOUNT()
		lcType				=	ALLTRIM(cGeneralLedgerEntries_Linii.TYPE)
		SUM Amount			TO	lnTotalSuma
		lnTotalSuma			=	lnTotalSuma/2
		*
		SELECT cGeneralLedgerEntries_Linii
		LOCATE FOR ISNULL(TAXPERCENTAGE)
		IF FOUND()
			ShowHideScreen(.T.)
			BROWSE NORMAL FOR ISNULL(TAXPERCENTAGE) TITLE 'TAXPERCENTAGE NULL in cGeneralLedgerEntries_Linii'
			ShowHideScreen(.F.)
		ENDIF
		*
		Tabela_Erori_Saft('cGeneralLedgerEntries_Linii')
		UPDATE cGeneralLedgerEntries_Linii SET TAXPERCENTAGE = -1, DenumireTva = 'Necompletat' WHERE ISNULL(TAXPERCENTAGE)
		*
		*/////////////////////////////////////////////
		*
		*-- 25.04.2024
		SELECT cGeneralLedgerEntries_Linii
		BLANK FIELDS;
			TaxType, TaxCode, TaxBase, TaxAmount, TaxCurrencyAmount, TaxExchangeRate, CodTva, TipTva, ProcTva, TaxDCA, DenumireTva;
			FOR;
			AccountID <> CeCont		&& And Not InList(Type, 'TVA - platita', 'TVA - incasata')
		BLANK FIELDS;
			TaxType_9, TaxCode_9, TaxBase_9, TaxAmount_9, TaxCurrencyAmount_9, TaxExchangeRate_9, CodTva_9, TipTva_9, ProcTva_9, TaxDCA_9, DenumireTva_9;
			FOR;
			AccountID <> CeCont_9	&& And Not InList(Type, 'TVA - platita', 'TVA - incasata')
		BLANK FIELDS;
			TaxType_5, TaxCode_5, TaxBase_5, TaxAmount_5, TaxCurrencyAmount_5, TaxExchangeRate_5, CodTva_5, TipTva_5, ProcTva_5, TaxDCA_5, DenumireTva_5;
			FOR;
			AccountID <> CeCont_5	&& And Not InList(Type, 'TVA - platita', 'TVA - incasata')

		*!*	*******************************
		*!*	&&	LUENCOM.28.04.2025
		*!*	* Fiedl TaxCode does not accept NULL values
		*!*	*-----------------------------
		*!*	Blank FIELDS TaxCode	For IsNull(TaxCode)
		*!*	Blank FIELDS TaxCode_9	For IsNull(TaxCode_9)
		*!*	Blank FIELDS TaxCode_5	For IsNull(TaxCode_5)
		*!*	*******************************
	
		SELECT GLE_GeneralLedgerEntries
		&& aici as putea prelucra TaxCurrencyAmount_9 (TaxExchangeRate_9*TaxBase_9), TaxCurrencyAmount_5(TaxExchangeRate_5*TaxBase_5) si Amount_9, Amount_5
		APPEND FROM DBF('cGeneralLedgerEntries_Linii')
		IF RecCount('GLE_GeneralLedgerEntries')=0
			Tabela_Erori_Saft('lipsa_GLE')
		ENDIF
		*/////////////////////////////////////////////
		&&--27.06.2025
		*!*	*-- 27.03.2025
		*!*	If Icas.oSoc.ModPlataTva=3	&&& neplatitori tva
		*!*		Update;
		*!*			cGeneralLedgerEntries_Linii;
		*!*		Set;
		*!*				TaxType	= '000';
		*!*			,	TaxCode	= '000000';
		*!*		Where;
		*!*				TaxType = '300'
		*!*	EndIf
		*!*	*-- 27.03.2025
		&&--27.06.2025
		*/////////////////////////////////////////////
		*Update GeneralLedgerEntries Set RecordID=Transform(RecNo([GeneralLedgerEntries]))
		INDEX ON Id_Nota TAG Id_Nota
		LOCATE
		REPLACE NumberOfEntries WITH lnNumberOfEntries, TotalDebit WITH lnTotalSuma, TotalCredit WITH lnTotalSuma
		*
		__Consola_Timing(PROGRAM() + [Creez '16.1.GeneralLedgerEntries.xml'])

		*
		SET TEXTMERGE ON TO lcDirectorSAFT+'16.1.GeneralLedgerEntries.xml' NOSHOW
		\<GeneralLedgerEntries>
		\		<NumberOfEntries><<Transform(NumberOfEntries)>></NumberOfEntries>
		\		<TotalDebit><<Str(TotalDebit, 18, 2)>></TotalDebit>
		\		<TotalCredit><<Str(TotalCredit, 18, 2)>></TotalCredit>
		\		<Journal>
		*\			<JournalID><<AllTrim(JournalID)>></JournalID>
		*\			<Description><<AllTrim(Description)>></Description>
		*\			<Type><<AllTrim(Type)>></Type>
		\			<JournalID>Registru jurnal</JournalID>
		\			<Description>Registru jurnal</Description>
		\			<Type>RegJurnal</Type>

		FOR nrFisiere = 1 TO CEILING( RECCOUNT('cGeneralLedgerEntries_Linii') / lnCalupInregGLE )
			* inreg. 241192 >>> 268 MB
			IF nrFisiere > 1
				SET TEXTMERGE ON TO lcDirectorSAFT+'16.' +ALLTRIM(STR(nrFisiere)) +'.GeneralLedgerEntries.xml' NOSHOW
			ENDIF
			*
			SCAN  FOR BETWEEN( RECNO(), nrFisiere*lnCalupInregGLE-lnCalupInregGLE+1 , nrFisiere*lnCalupInregGLE )
				*SCAN
		\			<Transaction>
		\				<TransactionID><<AllTrim(Transform(TransactionID))>></TransactionID>
		\				<Period><<Transform(Period)>></Period>
		\				<PeriodYear><<Transform(PeriodYear)>></PeriodYear>
		\				<TransactionDate><<Transform(DToS(TransactionDate), '@R ####-##-##')>></TransactionDate>
		\				<Description><<AllTrim(TransactionDescription)>></Description>
		\				<SystemEntryDate><<Transform(DToS(SystemEntryDate), '@R ####-##-##')>></SystemEntryDate>
		\				<GLPostingDate><<Transform(DToS(GLPostingDate), '@R ####-##-##')>></GLPostingDate>
		\				<CustomerID><<CUI_Raportor>></CustomerID>
		\				<SupplierID><<CUI_Raportor>></SupplierID>
		\				<TransactionLine>
		\					<RecordID><<AllTrim(RecordID)>></RecordID>
		\					<AccountID><<AllTrim(AccountID)>></AccountID>
				IF IsNullOrEmpty(CustomerID) AND IsNullOrEmpty(SupplierID)
		\					<CustomerID><<CUI_Raportor>></CustomerID>
		\					<SupplierID><<CUI_Raportor>></SupplierID>
				ELSE
		\					<CustomerID><<AllTrim(CustomerID)>></CustomerID>
		\					<SupplierID><<AllTrim(SupplierID)>></SupplierID>
				ENDIF
		\					<Description><<AllTrim(TransactionDescription)>></Description>
				IF DebitCreditIndicator='D'
		\					<DebitAmount>
				ELSE
		\					<CreditAmount>
				ENDIF
		\						<Amount><<Transform(Amount)>></Amount>
		\						<CurrencyCode><<ICase(IsNullOrEmpty(CurrencyCode), 'RON', Upper(CurrencyCode))>></CurrencyCode>
		\						<CurrencyAmount><<Transform(ICase(IsNullOrEmpty(CurrencyAmount), Amount, CurrencyAmount))>></CurrencyAmount>
		\						<ExchangeRate><<ICase(IsNullOrEmpty(ExchangeRate), '1.0', Transform(ExchangeRate))>></ExchangeRate>
				IF DebitCreditIndicator='D'
		\					</DebitAmount>
				ELSE
		\					</CreditAmount>
				ENDIF
				*
				* \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
				*
				* CE FAC cand am 2 sau 3 cote de tva pe facturile cu TVA la INCASARE?
				*
				* ///////////////////////////////////////////////////////////////////
				*
				*	19%
				IF (ALLTRIM(AccountID)==ALLTRIM(CeCont) AND !IsNullOrEmpty(CodTva))
					*
					lcTaxType				= TaxType
					lcTaxCode				= TaxCode
					lcTaxPercentage			= TRANSFORM(TaxPercentage)
					lcTaxBase				= TRANSFORM(TaxBase)
					lcTaxBaseDescription	= DenumireTva
					lcTaxAmount				= ''
					lnAmount				= TaxAmount
					lcAmount				= TRANSFORM(lnAmount)
					lcCurrencyCode			= ICASE(IsNullOrEmpty(CurrencyCode), 'RON', CurrencyCode)
					*lcCurrencyAmount		= Transform(Iif(IsNullOrEmpty(CurrencyAmount), lnAmount, CurrencyAmount))
					lcCurrencyAmount		= TRANSFORM(lnAmount)
					lcExchangeRate			= ICASE(IsNullOrEmpty(ExchangeRate), '1.0', TRANSFORM(ExchangeRate))
					lcTaxDeclarationPeriod	= TRANSFORM(lcModPlataTva)
					*
		\					<TaxInformation>
		\						<TaxType><<AllTrim(lcTaxType)>></TaxType>
		\						<TaxCode><<AllTrim(lcTaxCode)>></TaxCode>
					IF NOT lcTaxCode='000000' AND NOT EMPTY(lcTaxPercentage)
		\						<TaxPercentage><<lcTaxPercentage>></TaxPercentage>
		\						<TaxBase><<lcTaxBase>></TaxBase>
					ENDIF
		\						<TaxAmount>
		\							<Amount><<lcAmount>></Amount>
		\							<CurrencyCode><<Upper(lcCurrencyCode)>></CurrencyCode>
		\							<CurrencyAmount><<lcCurrencyAmount>></CurrencyAmount>
		\						</TaxAmount>
		\					</TaxInformation>
					*
				ENDIF
				*
				*	9%
				*
				IF (ALLTRIM(AccountID)==ALLTRIM(CeCont_9) AND !IsNullOrEmpty(CodTva_9))
					*
					lcTaxType_9				= TaxType_9
					lcTaxCode_9				= TaxCode_9
					lcTaxPercentage_9		= TRANSFORM(TaxPercentage_9)
					lcTaxBase_9				= TRANSFORM(TaxBase_9)
					lcTaxBaseDescription_9	= DenumireTva_9
					lcTaxAmount_9			= ''
					lnAmount_9				= TaxAmount_9
					lcAmount_9				= TRANSFORM(lnAmount_9)
					lcCurrencyCode			= ICASE(IsNullOrEmpty(CurrencyCode), 'RON', CurrencyCode)
					*lcCurrencyAmount		= Transform(Iif(IsNullOrEmpty(CurrencyAmount), TaxAmount, CurrencyAmount))
					lcCurrencyAmount		= TRANSFORM(lnAmount_9)
					lcExchangeRate			= ICASE(IsNullOrEmpty(ExchangeRate), '1.0', TRANSFORM(ExchangeRate))
					lcTaxDeclarationPeriod	= TRANSFORM(lcModPlataTva)
					*
		\					<TaxInformation>
		\						<TaxType><<AllTrim(lcTaxType_9)>></TaxType>
		\						<TaxCode><<AllTrim(lcTaxCode_9)>></TaxCode>
					IF NOT lcTaxCode_9='000000' AND NOT EMPTY(lcTaxPercentage_9)
		\						<TaxPercentage><<lcTaxPercentage_9>></TaxPercentage>
		\						<TaxBase><<lcTaxBase_9>></TaxBase>
					ENDIF
		\						<TaxAmount>
		\							<Amount><<lcAmount_9>></Amount>
		\							<CurrencyCode><<Upper(lcCurrencyCode)>></CurrencyCode>
		\							<CurrencyAmount><<lcCurrencyAmount>></CurrencyAmount>
		\						</TaxAmount>
		\					</TaxInformation>
					*
				ENDIF
				*
				*	5%
				*
				IF (ALLTRIM(AccountID)==ALLTRIM(CeCont_5) AND !IsNullOrEmpty(CodTva_5))
					*
					lcTaxType_5				= TaxType_5
					lcTaxCode_5				= TaxCode_5
					lcTaxPercentage_5		= TRANSFORM(ProcTva_5)
					lcTaxBase_5				= TRANSFORM(TaxBase_5)
					lcTaxBaseDescription_5	= DenumireTva_5
					lcTaxAmount_5			= ''
					lnAmount_5				= TaxAmount_5
					lcAmount_5				= TRANSFORM(lnAmount_5)
					lcCurrencyCode			= ICASE(IsNullOrEmpty(CurrencyCode), 'RON', CurrencyCode)
					*lcCurrencyAmount		= Transform(Iif(IsNullOrEmpty(CurrencyAmount), TaxAmount, CurrencyAmount))
					lcCurrencyAmount		= TRANSFORM(lnAmount_5)
					lcExchangeRate			= ICASE(IsNullOrEmpty(ExchangeRate), '1.0', TRANSFORM(ExchangeRate))
					lcTaxDeclarationPeriod	= TRANSFORM(lcModPlataTva)
					*
		\					<TaxInformation>
		\						<TaxType><<AllTrim(lcTaxType_5)>></TaxType>
		\						<TaxCode><<AllTrim(lcTaxCode_5)>></TaxCode>
					IF NOT lcTaxCode_5='000000' AND NOT EMPTY(lcTaxPercentage_5)
		\						<TaxPercentage><<lcTaxPercentage_5>></TaxPercentage>
		\						<TaxBase><<lcTaxBase_5>></TaxBase>
					ENDIF
		\						<TaxAmount>
		\							<Amount><<lcAmount_5>></Amount>
		\							<CurrencyCode><<Upper(lcCurrencyCode)>></CurrencyCode>
		\							<CurrencyAmount><<lcCurrencyAmount>></CurrencyAmount>
		\						</TaxAmount>
		\					</TaxInformation>
					*
				ENDIF
				*
				IF NOT (ALLTRIM(AccountID)==ALLTRIM(CeCont) AND !IsNullOrEmpty(CodTva));
						AND NOT (ALLTRIM(AccountID)==ALLTRIM(CeCont_9) AND !IsNullOrEmpty(CodTva_9));
						AND NOT (ALLTRIM(AccountID)==ALLTRIM(CeCont_5) AND !IsNullOrEmpty(CodTva_5))
					*
					IF EMPTY(TaxType) OR TaxType='300'
						lcTaxType			= '000'
					ELSE
						lcTaxType			= TaxType
					ENDIF
					*
					lcTaxCode				= '000000'
					lcTaxPercentage			= ''
					lcTaxBase				= ''
					lcTaxBaseDescription	= ''
					lcTaxAmount				= ''
					lcAmount				= '0'
					lcCurrencyCode			= 'RON'
					lcCurrencyAmount		= '0'
					lcExchangeRate			= '1.0'
					lcTaxDeclarationPeriod	= ''
					*
		\					<TaxInformation>
		\						<TaxType><<AllTrim(lcTaxType)>></TaxType>
		\						<TaxCode><<AllTrim(lcTaxCode)>></TaxCode>
					IF NOT lcTaxCode='000000' AND NOT EMPTY(lcTaxPercentage)
		\						<TaxPercentage><<lcTaxPercentage>></TaxPercentage>
		\						<TaxBase><<lcTaxBase>></TaxBase>
					ENDIF
		\						<TaxAmount>
		\							<Amount><<lcAmount>></Amount>
		\							<CurrencyCode><<Upper(lcCurrencyCode)>></CurrencyCode>
		\							<CurrencyAmount><<lcCurrencyAmount>></CurrencyAmount>
		\						</TaxAmount>
		\					</TaxInformation>
					*
				ENDIF
				*
		\				</TransactionLine>
		\			</Transaction>
			ENDSCAN

			IF nrFisiere = CEILING( RECCOUNT('cGeneralLedgerEntries_Linii') / lnCalupInregGLE )
		\		</Journal>
		\	</GeneralLedgerEntries>
			ENDIF
			SET TEXTMERGE TO
			SET TEXTMERGE OFF
		ENDFOR
		************************************************
		AddToLog(TRANSFORM(SECONDS()-_LastTime, [999.9999])+[ lcDirectorSAFT+'16.GeneralLedgerEntries.xml'], lcLogFile, .T., .T.)
		__Consola_Timing("SAFT.prg : Generare XML : " + [ ]+lcDirectorSAFT+'16.GeneralLedgerEntries.xml')
		IF FORCE_REFRESH
			DOEVENTS FORCE
		ENDIF

		THIS.Generate_TaxTable(toContext)
		
	ENDFUNC
	
	PROTECTED FUNCTION Generate_TaxTable(toContext AS SAFT_Context)
        toContext.Notify("INFO", "  - Generare 07.TaxTable.xml")
        toContext.Repository.Get_07TaxTable(toContext.StartDate, toContext.EndDate)
		toContext.Notify("RECORD_COUNT", "TaxTable", RECCOUNT('MasterFiles_TaxTable'))        
	
		SET TEXTMERGE ON TO lcDirectorSAFT+'07.TaxTable.xml' NOSHOW
		SELECT MasterFiles_TaxTable

		&& 28Feb2025
		*

		\<TaxTable>
		IF RECCOUNT('MasterFiles_TaxTable')>0
			SCAN
		\			<TaxTableEntry>
		\				<TaxType><<TaxType>></TaxType>
		\				<Description><<AllTrim(Description)>></Description>
		\				<TaxCodeDetails>
		\					<TaxCode><<TaxCode>></TaxCode>
				*\					<Description><<AllTrim(Descriere_TaxCode)>></Description>
		\					<TaxPercentage><<Transform(TaxPercentage)>></TaxPercentage>
		\					<BaseRate><<AllTrim(Transform(BaseRate))>></BaseRate>
		\					<Country><<AllTrim(Country)>></Country>
		\				</TaxCodeDetails>
		\			</TaxTableEntry>
			ENDSCAN
		ELSE
		\			<TaxTableEntry>
		\				<TaxType>000</TaxType>
		\				<Description>FARA</Description>
		\				<TaxCodeDetails>
		\					<TaxCode>000000</TaxCode>
		\					<TaxPercentage>0</TaxPercentage>
		\					<BaseRate>1</BaseRate>
		\					<Country>RO</Country>
		\				</TaxCodeDetails>
		\			</TaxTableEntry>
		ENDIF
		\		</TaxTable>

		SET TEXTMERGE TO
		SET TEXTMERGE OFF
		AddToLog(TRANSFORM(SECONDS()-_LastTime, [999.9999])+[ lcDirectorSAFT+'07.TaxTable.xml' ...], lcLogFile, .T., .T.)
		__Consola_Timing("SAFT.prg : Generare XML : " + [ ]+lcDirectorSAFT+'07.TaxTable.xml'+[...])
	ENDFUNC

ENDDEFINE
    
    *!*-----------------------------------------------------------------------------
*!* CLASS: Handler_AssembleXML_Periodic
*!* SCOP:  Asambleaza fi?ierul XML final pentru o declara?ie periodica.
*!*-----------------------------------------------------------------------------
DEFINE CLASS Handler_AssembleXML_Periodic AS Handler_Base
    PROTECTED FUNCTION Process(toContext AS SAFT_Context) AS Boolean
        toContext.Notify("INFO", "Asamblare fi?ier XML final (Periodic)...")
        
        LOCAL lcFinalFile AS String
        lcFinalFile = toContext.FinalFileName
        
        STRTOFILE(FILETOSTR(toContext.WorkDir + "01.AuditFile.xml"), lcFinalFile)
        STRTOFILE(FILETOSTR(toContext.WorkDir + "02.Header.xml"), lcFinalFile, .T.)
        STRTOFILE(FILETOSTR(toContext.WorkDir + "03.MasterFiles.xml"), lcFinalFile, .T.)
		FOR nrFisiere = 1 TO CEILING( RECCOUNT('cGeneralLedgerEntries_Linii') / lnCalupInregGLE )
			* inreg. 241192 >>> 268 MB
			STRTOFILE(FILETOSTR(toContext.WorkDir + "16."+ALLTRIM(STR(nrFisiere))+".GeneralLedgerEntries.xml"), lcFinalFile, .T.)			
		ENDFOR
        STRTOFILE(FILETOSTR(toContext.WorkDir + "17.SourceDocuments.xml"), lcFinalFile, .T.)
        
        * ... etc.
        STRTOFILE("</AuditFile>", lcFinalFile, .T.)
        
        RETURN .T.
    ENDFUNC
ENDDEFINE


*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_ChainBuilder
*!* SCOP:  Implementeaza "Builder Pattern". 
*!* Construieste lantul de handlere
*!* în functie de tipul declaratiei, asigurând ordinea corecta de executie.
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_ChainBuilder AS Custom

    FUNCTION BuildChain(toContext AS SAFT_Context) AS Handler_Base
        LOCAL loHead AS Handler_Base, lcType, loCurrentHandler AS Handler_Base
        lcType = toContext.DeclarationType
        
        loHead = CREATEOBJECT("Handler_Setup")
        loCurrentHandler = loHead
        
        DO CASE
            CASE INLIST(lcType, "L", "T", "S")
                loCurrentHandler = loCurrentHandler.SetNext(CREATEOBJECT("Handler_Generate_Header"))

				*-- Aici sunt nevoit sa schimb cumva ordinea
				*-- GLE trebuie generat dupa ce se genereaza facturile de vanzare si intrare
				*-- TaxTable din MasterFiles se construieste din cGeneralLedgerEntries_Linii
                loCurrentHandler = loCurrentHandler.SetNext(CREATEOBJECT("Handler_Generate_SourceDocuments"))
                loCurrentHandler = loCurrentHandler.SetNext(CREATEOBJECT("Handler_Generate_GeneralLedgerEntries"))
               
                loCurrentHandler = loCurrentHandler.SetNext(CREATEOBJECT("Handler_Generate_MasterFiles_Periodic"))
                *-- Aici s-ar adauga toate celelalte handlere: GLE, SourceDocuments, etc.
                
                *loCurrentHandler = loCurrentHandler.SetNext(CREATEOBJECT("Handler_Generate_GeneralLedgerEntries"))
                loCurrentHandler = loCurrentHandler.SetNext(CREATEOBJECT("Handler_AssembleXML_Periodic"))
            
            *-- cazurile pentru 'A' si 'C'
            
            OTHERWISE
                loHead = NULL
        ENDCASE
        
        RETURN loHead
    ENDFUNC

    FUNCTION GetHandlerList(toHead AS Handler_Base) AS Collection
        LOCAL loCurrent AS Handler_Base
        LOCAL loHandlers AS Collection
        loHandlers = CREATEOBJECT("Collection")
        loCurrent = toHead
        DO WHILE VARTYPE(loCurrent) = "O"
            loHandlers.Add(loCurrent.Class)
            loCurrent = loCurrent.NextHandler
        ENDDO
        RETURN loHandlers
    ENDFUNC
ENDDEFINE


*!*-----------------------------------------------------------------------------
*!* CLASS: Notifier_Observer_Base (Clasa Abstracta)
*!* SCOP:  Defineste interfata pentru toti Observatorii.
*!*-----------------------------------------------------------------------------
DEFINE CLASS Notifier_Observer_Base AS Custom

    FUNCTION Update(toSender AS OBJECT, tcEventName AS String, tvEventData1 AS Variant, tvEventData2 AS Variant)
        ERROR "Metoda Update trebuie implementata de subclasa observer."
    ENDFUNC

ENDDEFINE


*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_Logger
*!* SCOP:  Un observator CONCRET. Când este notificat, scrie un mesaj
*!* într-un fisier de log. Este complet decuplat de procesul de generare.
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_Logger AS Notifier_Observer_Base
    FUNCTION Update(toSender AS OBJECT, tcEventName AS String, tvEventData1 AS Variant, tvEventData2 AS Variant)
        LOCAL lcLogFile AS String, lcMessage AS String
		
        IF VARTYPE(toSender) = "O" AND PEMSTATUS(toSender, "LogFile", 5) AND !EMPTY(toSender.LogFile)
            lcLogFile = toSender.LogFile
            lcMessage = TTOC(DATETIME()) + " [" + tcEventName + "] - " + TRANSFORM(tvEventData1)
            IF !ISNULL(tvEventData2) AND !EMPTY(TRANSFORM(tvEventData2))
                lcMessage = lcMessage + " | " + TRANSFORM(tvEventData2)
            ENDIF
            STRTOFILE(lcMessage + CHR(13)+CHR(10), lcLogFile, .T.)
        ENDIF
    ENDFUNC
ENDDEFINE

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_Progress_UI_Console (Formular avansat de progres)
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_Progress_UI_Console AS Form
    Caption = "Generare SAF-T în curs..."
    Width = 600
    Height = 400
    AutoCenter = .T.
    WindowType = 0 && Modeless
    nTotalSteps = 0
    nCurrentStep = 0
    
    ADD OBJECT lblStatus AS Label WITH Top = 10, Left = 10, Width = 580, Caption = "Ini?ializare...", FontBold = .T.
    ADD OBJECT shpProgressBack AS Shape WITH Top=35, Left=10, Width=580, Height=25, BackColor=RGB(220,220,220), BorderWidth=1
    ADD OBJECT shpProgressFront AS Shape WITH Top=36, Left=11, Width=0, Height=23, BackColor=RGB(0,128,192)
    ADD OBJECT edtConsole AS EditBox WITH Top=70, Left=10, Width=580, Height=320, Anchor=15, ReadOnly=.T., ScrollBars=2, FontName="Courier New"

    FUNCTION Update(toSender, tcEventName, tvEventData1, tvEventData2)
        DO CASE
            CASE tcEventName == "PROCESS_START"
                IF VARTYPE(tvEventData1) = "O" AND PEMSTATUS(tvEventData1, "Count", 5)
                    THIS.nTotalSteps = tvEventData1.Count
                ENDIF
                THIS.Show()
                THIS.AddConsoleLine("Procesul de generare a început...")

            CASE tcEventName == "HANDLER_START"
                THIS.nCurrentStep = THIS.nCurrentStep + 1
                THIS.lblStatus.Caption = "Pas " + TRANSFORM(THIS.nCurrentStep) + "/" + TRANSFORM(THIS.nTotalSteps) + ": " + tvEventData1
                THIS.shpProgressFront.Width = (THIS.nCurrentStep / IIF(THIS.nTotalSteps>0,THIS.nTotalSteps,1)) * THIS.shpProgressBack.Width
                THIS.AddConsoleLine(CHR(13) + "==> Pornire pas: " + tvEventData1)
                
            CASE tcEventName == "INFO"
                THIS.AddConsoleLine("    " + tvEventData1)

            CASE tcEventName == "HANDLER_END"
                THIS.AddConsoleLine("    >> Finalizat în " + TRANSFORM(tvEventData2, "999.99") + " secunde.")

            CASE INLIST(tcEventName, "PROCESS_END", "FATAL_ERROR")
                IF THIS.Visible
                    THIS.AddConsoleLine(CHR(13) + "=====================================")
                    THIS.AddConsoleLine("PROCES FINALIZAT. Fereastra se va închide.")
                    WAIT "" TIMEOUT 2
                    THIS.Release()
                ENDIF
        ENDCASE
    ENDFUNC
    
    PROCEDURE AddConsoleLine(tcMessage AS String)
        THIS.edtConsole.Value = THIS.edtConsole.Value + tcMessage + CHR(13)+CHR(10)
        THIS.edtConsole.CurLine = THIS.edtConsole.LineCount
        DOEVENTS
    ENDPROC
EndDefine

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_Progress_UI_Console (Formular avansat de progres)
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_Progress_UI_Console AS Form
    Caption = "Generare SAF-T în curs..."
    Width = 600
    Height = 400
    AutoCenter = .T.
    WindowType = 0 && Modeless
    nTotalSteps = 0
    nCurrentStep = 0
    
    ADD OBJECT lblStatus AS Label WITH Top = 10, Left = 10, Width = 580, Caption = "Ini?ializare...", FontBold = .T.
    ADD OBJECT shpProgressBack AS Shape WITH Top=35, Left=10, Width=580, Height=25, BackColor=RGB(220,220,220), BorderWidth=1
    ADD OBJECT shpProgressFront AS Shape WITH Top=36, Left=11, Width=0, Height=23, BackColor=RGB(0,128,192)
    ADD OBJECT edtConsole AS EditBox WITH Top=70, Left=10, Width=580, Height=320, Anchor=15, ReadOnly=.T., ScrollBars=2, FontName="Courier New"

    FUNCTION Update(toSender, tcEventName, tvEventData1, tvEventData2)
        DO CASE
            CASE tcEventName == "PROCESS_START"
                IF VARTYPE(tvEventData1) = "O" AND PEMSTATUS(tvEventData1, "Count", 5)
                    THIS.nTotalSteps = tvEventData1.Count
                ENDIF
                THIS.Show()
                THIS.AddConsoleLine("Procesul de generare a început...")

            CASE tcEventName == "HANDLER_START"
                THIS.nCurrentStep = THIS.nCurrentStep + 1
                THIS.lblStatus.Caption = "Pas " + TRANSFORM(THIS.nCurrentStep) + "/" + TRANSFORM(THIS.nTotalSteps) + ": " + tvEventData1
                THIS.shpProgressFront.Width = (THIS.nCurrentStep / IIF(THIS.nTotalSteps>0,THIS.nTotalSteps,1)) * THIS.shpProgressBack.Width
                THIS.AddConsoleLine(CHR(13) + "==> Pornire pas: " + tvEventData1)
                
            CASE tcEventName == "INFO"
                THIS.AddConsoleLine("    " + tvEventData1)

            CASE tcEventName == "HANDLER_END"
                THIS.AddConsoleLine("    >> Finalizat în " + TRANSFORM(tvEventData2, "999.99") + " secunde.")

            CASE INLIST(tcEventName, "PROCESS_END", "FATAL_ERROR")
                IF THIS.Visible
                    THIS.AddConsoleLine(CHR(13) + "=====================================")
                    THIS.AddConsoleLine("PROCES FINALIZAT. Fereastra se va închide.")
                    WAIT "" TIMEOUT 2
                    THIS.Release()
                ENDIF
        ENDCASE
    ENDFUNC
    
    PROCEDURE AddConsoleLine(tcMessage AS String)
        THIS.edtConsole.Value = THIS.edtConsole.Value + tcMessage + CHR(13)+CHR(10)
        *-- Corectie: Se seteaza SelStart la lungimea textului pentru a forta scroll-ul la final
        THIS.edtConsole.SelStart = LEN(THIS.edtConsole.Value)
        DOEVENTS
    ENDPROC
ENDDEFINE


*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_Summary_Collector
*!* SCOP:  Colecteaza statistici si afiseaza rezumatul final.
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_Summary_Collector AS Notifier_Observer_Base
    nStartTime = 0

    FUNCTION Update(toSender, tcEventName, tvEventData1, tvEventData2)
        DO CASE
            CASE tcEventName == "PROCESS_START"
                THIS.nStartTime = SECONDS()
            CASE tcEventName == "HANDLER_END"
                toSender.oTimings.Add(tvEventData2, tvEventData1)
            CASE tcEventName == "RECORD_COUNT"
                toSender.oRecordCounts.Add(tvEventData2, tvEventData1)
        ENDCASE
    ENDFUNC
    
    FUNCTION DisplaySummary(toContext AS SAFT_Context)
        LOCAL lcSummary, i, lcKey, nValue, nTotalTime
        lcSummary = "REZUMAT GENERARE FISIER SAF-T" + CHR(13)+CHR(10)
        lcSummary = lcSummary + "==============================" + CHR(13)+CHR(10)

        lcSummary = lcSummary + "Durata pasilor de procesare:" + CHR(13)
        FOR i = 1 TO toContext.oTimings.Count
            lcKey = toContext.oTimings.GetKey(i)
            nValue = toContext.oTimings.Item(i)
            lcSummary = lcSummary + "  - " + PADR(lcKey, 40) + ": " + TRANSFORM(nValue, "999.99") + " secunde" + CHR(13)
        ENDFOR
        lcSummary = lcSummary + CHR(13)

        IF toContext.oRecordCounts.Count > 0
            lcSummary = lcSummary + "Înregistrari generate pe sectiune:" + CHR(13)
			FOR i = 1 TO toContext.oRecordCounts.Count
				lcKey = toContext.oRecordCounts.GetKey(i)
				nValue = toContext.oRecordCounts.Item(i)
				lcSummary = lcSummary + "  - " + PADR(lcKey, 40) + ": " + TRANSFORM(nValue) + " înregistrari" + CHR(13)
			ENDFOR
            lcSummary = lcSummary + CHR(13)
        ENDIF
        
        nTotalTime = SECONDS() - THIS.nStartTime
        lcSummary = lcSummary + "==============================" + CHR(13)
        lcSummary = lcSummary + "Timp total de executie: " + TRANSFORM(nTotalTime, "9,999.99") + " secunde" + CHR(13)

       * MESSAGEBOX(lcSummary, 64, "Rezumat Procesare")
        *-- Creare ?i afi?are formular de rezumat
        loSummaryForm = CREATEOBJECT("SAFT_Summary_UI")
        loSummaryForm.cSummaryText = lcSummary
        loSummaryForm.ShowSummary()       
		Wait CLEAR
    ENDFUNC
ENDDEFINE

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_Summary_UI
*!* SCOP:  Formular pentru afisarea rezumatului final.
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_Summary_UI AS Form
    Width = 550
    Height = 400+100
    AutoCenter = .T.
    Caption = "Rezumat Generare Fiier SAF-T"
    WindowType = 1 && Modal
    Icon = 'Computer.ico'
    
    cSummaryText = ""

    ADD OBJECT edtSummary AS EditBox WITH ;
        Top = 10, Left = 10, Width = 530, Height = 320+100,;
        ReadOnly = .T., FontName = "Courier New", FontSize = 9
        
    ADD OBJECT cmdClose AS CommandButton WITH ;
        Top = 345+100, Left = 225, Width = 100, Height = 27,;
        Caption = "Închide", Cancel = .T.
        
    FUNCTION Init
        THIS.edtSummary.ScrollBars = 2 && Vertical
    ENDFUNC
        
    FUNCTION ShowSummary()
        THIS.edtSummary.Value = THIS.cSummaryText
        THIS.Show()
    ENDFUNC
    
    PROCEDURE cmdClose.Click
        THISFORM.Release()
    ENDPROC
ENDDEFINE

*!*	*!* ============================================================================
*!*	*!* FISIER: SAFT_Main.prg
*!*	*!* ============================================================================
*!*	*!* AUTOR: Gemini AI (pe baza codului original)
*!*	*!* DATA:  26.06.2025
*!*	*!* SCOP:  Acesta este programul principal (entry point) pentru generarea
*!*	*!* fi?ierului SAF-T. Responsabilitatea sa este de a valida parametrii
*!*	*!* de intrare, de a folosi un Factory pentru a ob?ine generatorul
*!*	*!* corect ?i de a ini?ia procesul.
*!*	*!* MOD DE UTILIZARE: DO SAFT_Main.prg WITH dDataStart, dDataSfarsit, cTip, nSegmente
*!*	*!* ============================================================================
*!*	LPARAMETERS tdData1, tdData2, tcTipDeclaratie, tnSegmente

*!*	LOCAL loGenerator AS SAFT_Generator_Base
*!*	LOCAL loFactory AS SAFT_Factory
*!*	LOCAL llSuccess AS Boolean

*!*	*-- Validare parametri initiali
*!*	IF EMPTY(tdData1) OR EMPTY(tdData2)
*!*	    MESSAGEBOX("Perioada (Data1, Data2) este obligatorie!", 16, "Eroare Parametri")
*!*	    RETURN .F.
*!*	ENDIF

*!*	*-- Setare valori implicite
*!*	tcTipDeclaratie = IIF(EMPTY(tcTipDeclaratie), "L", UPPER(ALLTRIM(tcTipDeclaratie)))
*!*	tnSegmente = IIF(EMPTY(tnSegmente), 1, tnSegmente)

*!*	*-- Creare Factory ?i ob?inere Generator specific
*!*	*-- Acest pas elimina complet necesitatea unui `DO CASE` mare în programul principal.
*!*	loFactory = CREATEOBJECT("SAFT_Factory")
*!*	loGenerator = loFactory.CreateGenerator(tcTipDeclaratie)

*!*	IF VARTYPE(loGenerator) != "O"
*!*	    MESSAGEBOX("Tipul de declara?ie '" + tcTipDeclaratie + "' nu este un tip suportat.", 16, "Eroare")
*!*	    RETURN .F.
*!*	ENDIF

*!*	*-- Ini?ializare ?i rulare proces de generare. Toata complexitatea este ascunsa
*!*	*-- în spatele metodei `Run()` a obiectului generator.
*!*	llSuccess = loGenerator.Run(tdData1, tdData2, tnSegmente)

*!*	*-- Afi?are rezultat final
*!*	IF llSuccess
*!*	    MESSAGEBOX("Generarea fi?ierului SAF-T a fost finalizata cu succes!", 64, "Proces Finalizat")
*!*	ELSE
*!*	    MESSAGEBOX("Generarea fi?ierului SAF-T a e?uat. Verifica?i fi?ierul de log pentru detalii.", 16, "Proces E?uat")
*!*	ENDIF

*!*	RELEASE loGenerator, loFactory
*!*	RETURN llSuccess


*!*	*!* ============================================================================
*!*	*!* FI?IER: SAFT_Classes.vcx (con?ine defini?iile claselor)
*!*	*!* ============================================================================

*!*	*!*-----------------------------------------------------------------------------
*!*	*!* CLASS: SAFT_Factory
*!*	*!* SCOP:  Implementeaza design pattern-ul "Factory Method". Responsabilitatea
*!*	*!* sa unica este de a crea ?i returna un obiect generator specific
*!*	*!* pe baza tipului de declara?ie solicitat. Decupleaza clientul (SAFT_Main.prg)
*!*	*!* de implementarile concrete ale generatoarelor.
*!*	*!*-----------------------------------------------------------------------------
*!*	DEFINE CLASS SAFT_Factory AS Custom

*!*	    *--- Creeaza un obiect generator specific pe baza tipului de declara?ie.
*!*	    * @param tcTip (String): Tipul declara?iei ('L', 'A', 'C', etc.).
*!*	    * @return (Object): O instan?a a unei clase generator sau NULL daca tipul nu e valid.
*!*	    FUNCTION CreateGenerator(tcTip AS String) AS OBJECT
*!*	        LOCAL loGenerator AS OBJECT
*!*	        tcTip = UPPER(ALLTRIM(tcTip))

*!*	        DO CASE
*!*	            CASE INLIST(tcTip, "L", "T", "S") && Lunar, Trimestrial, Semestrial
*!*	                loGenerator = CREATEOBJECT("SAFT_Generator_Periodic")
*!*	                loGenerator.DeclarationType = tcTip

*!*	            CASE tcTip == "A" && Anual
*!*	                loGenerator = CREATEOBJECT("SAFT_Generator_Anual")

*!*	            CASE tcTip == "C" && La Cerere
*!*	                loGenerator = CREATEOBJECT("SAFT_Generator_Cerere")

*!*	            OTHERWISE
*!*	                loGenerator = NULL
*!*	        ENDCASE

*!*	        RETURN loGenerator
*!*	    ENDFUNC

*!*	ENDDEFINE


*!*	*!*-----------------------------------------------------------------------------
*!*	*!* CLASS: SAFT_Generator_Base
*!*	*!* SCOP:  Clasa de baza ABSTRACTA pentru toate tipurile de generatoare SAF-T.
*!*	*!* - Implementeaza "Template Method Pattern" prin metoda `Run`, care define?te
*!*	*!* scheletul algoritmului de generare.
*!*	*!* - Con?ine logica ?i proprieta?ile comune tuturor tipurilor de declara?ii.
*!*	*!* - Metodele care variaza între tipuri sunt definite ca abstracte (goale,
*!*	*!* cu o eroare) ?i trebuie suprascrise în clasele derivate.
*!*	*!*-----------------------------------------------------------------------------
*!*	DEFINE CLASS SAFT_Generator_Base AS Custom

*!*	    *-- Proprieta?i comune, încapsulate. Se elimina variabilele globale.
*!*	    StartDate = {}
*!*	    EndDate = {}
*!*	    SegmentCount = 1
*!*	    DeclarationType = ""
*!*	    SAFT_WorkDir = ""
*!*	    SAFT_FileName = ""
*!*	    CompanyCUI = ""
*!*	    LogFile = ""
*!*	    IsVATPayer = .F.
*!*	    VATPaymentSystem = 1  && 1-lunar, 2-trim, etc.
*!*	    AccountingStandard = "A" && 'A' - OMFP 1802/2014, 'IFRS', etc.

*!*	    *-- Constante
*!*	    #DEFINE LOG_FILENAME "SAFT_Generator.log"
*!*	    #DEFINE XML_VERSION "1.0"
*!*	    #DEFINE SAFT_XMLNS "mfp:anaf:dgti:d406:declaratie:v1"
*!*	    #DEFINE SAFT_SCHEMA_LOCATION "urn:StandardAuditFile-Taxation-Financial:RO Romanian_SAF-T_Financial_Schema_v_2_4_6_09032022.xsd"

*!*	    *--- Metoda principala care orchestreaza întregul proces (Template Method).
*!*	    FUNCTION Run(tdData1 AS Date, tdData2 AS Date, tnSegmente AS Number) AS Boolean
*!*	        THIS.Init(tdData1, tdData2, tnSegmente)
*!*	        THIS.Log("***** START PROCES GENERARE SAFT *****")
*!*	        THIS.Log("Tip declara?ie: " + THIS.DeclarationType + ", Perioada: " + DTOC(THIS.StartDate) + " - " + DTOC(THIS.EndDate))

*!*	        TRY
*!*	            THIS.CleanupPreviousFiles()
*!*	            THIS.PrepareData()
*!*	            THIS.GenerateXMLSections()
*!*	            THIS.AssembleFinalXML()
*!*	            THIS.Log("***** PROCES GENERARE FINALIZAT CU SUCCES *****")
*!*	            THIS.DisplayErrors()

*!*	        CATCH TO oException
*!*	            THIS.Log("!!! EROARE FATALA: " + oException.Message + " (Linia: " + TRANSFORM(oException.LineNo) + ")")
*!*	            MESSAGEBOX("A aparut o eroare fatala: " + oException.Message, 16, "Eroare Proces Generare")
*!*	            RETURN .F.
*!*	        ENDTRY

*!*	        RETURN .T.
*!*	    ENDFUNC

*!*	    *--- Ini?ializeaza proprieta?ile obiectului.
*!*	    PROTECTED FUNCTION Init(tdData1 AS Date, tdData2 AS Date, tnSegmente AS Number)
*!*	        THIS.StartDate = tdData1
*!*	        THIS.EndDate = tdData2
*!*	        THIS.SegmentCount = tnSegmente
*!*	        
*!*	        THIS.SetupEnvironment()
*!*	    ENDFUNC

*!*	    *--- Metode "abstracte" (schelet) care trebuie implementate de subclase ---
*!*	    PROTECTED FUNCTION CleanupPreviousFiles()
*!*	        ERROR "Metoda CleanupPreviousFiles trebuie suprascrisa în clasa derivata: " + THIS.Class
*!*	    ENDFUNC

*!*	    PROTECTED FUNCTION GenerateXMLSections()
*!*	        ERROR "Metoda GenerateXMLSections trebuie suprascrisa în clasa derivata: " + THIS.Class
*!*	    ENDFUNC

*!*	    PROTECTED FUNCTION AssembleFinalXML()
*!*	        ERROR "Metoda AssembleFinalXML trebuie suprascrisa în clasa derivata: " + THIS.Class
*!*	    ENDFUNC
*!*	    *-----------------------------------------------------------------------

*!*	    *--- Metode comune, implementate o singura data în clasa de baza ---
*!*	    PROTECTED FUNCTION SetupEnvironment()
*!*	        THIS.Log("Configurare mediu de lucru...")
*!*	        *-- Aici vine logica din `Get_FullPath_SAFT_File` ?i alte setari ini?iale
*!*	        *-- Exemplu de implementare:
*!*	        LOCAL lcMonthYear, lcDeclType, lcSubDir
*!*	        lcMonthYear = ALLTRIM(CMONTH(THIS.StartDate)) + ALLTRIM(STR(YEAR(THIS.StartDate)))
*!*	        lcSubDir = SYS(2023) + "\" + "Declaratii\D406\" + lcMonthYear + "\" + GETNUDEDIR() + "\"
*!*	        
*!*	        IF !DIRECTORY(lcSubDir)
*!*	            MD (lcSubDir)
*!*	        ENDIF
*!*	        THIS.SAFT_WorkDir = lcSubDir
*!*	        
*!*	        lcDeclType = IIF(THIS.DeclarationType = 'A', "Active", IIF(THIS.DeclarationType = 'C', 'Cerere', 'Inf'))
*!*	        THIS.SAFT_FileName = THIS.SAFT_WorkDir + 'D406_' + ALLTRIM(ICAS.oSoc.CodFiscal) + '_' + DTOS(THIS.EndDate) + '_' + lcDeclType + '.xml'
*!*	        
*!*	        THIS.LogFile = THIS.SAFT_WorkDir + LOG_FILENAME
*!*	        THIS.CompanyCUI = '00' + ICAS.oSoc.CodFiscal
*!*	        THIS.IsVATPayer = IsInVATCollectionSystem(THIS.EndDate)
*!*	        THIS.VATPaymentSystem = GetModPlataTva(THIS.EndDate)
*!*	        
*!*	        ERASE (THIS.LogFile)
*!*	        THIS.Log("Director de lucru: " + THIS.SAFT_WorkDir)
*!*	        THIS.Log("Fi?ier final: " + THIS.SAFT_FileName)
*!*	    ENDFUNC

*!*	    PROTECTED FUNCTION PrepareData()
*!*	        THIS.Log("Pregatire date ?i creare cursoare...")
*!*	        *-- Logica centralizata din `CreareCursoare()` ?i `SAFT_Mapare()`
*!*	        SAFT_Mapare()
*!*	        CreareCursoare()
*!*	        *-- Alte opera?iuni de pregatire a datelor
*!*	    ENDFUNC

*!*	    PROTECTED FUNCTION GenerateAuditFileHeader()
*!*	        THIS.Log("Generare 01.AuditFile.xml...")
*!*	        LOCAL lcXML AS String
*!*	        TEXT TO lcXML NOSHOW TEXTMERGE PRETEXT 15
*!*	            <?xml version="<<XML_VERSION>>"?>
*!*	            <AuditFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="<<SAFT_XMLNS>>" xsi:schemaLocation="<<SAFT_SCHEMA_LOCATION>>">
*!*	        ENDTEXT
*!*	        STRTOFILE(lcXML, THIS.SAFT_WorkDir + "01.AuditFile.xml")
*!*	    ENDFUNC

*!*	    PROTECTED FUNCTION GenerateCompanyHeader()
*!*	        THIS.Log("Generare 02.Header.xml...")
*!*	        *-- Logica din `_02Header()`. Folose?te proprieta?ile `THIS`
*!*	        *-- Exemplu simplificat:
*!*	        LOCAL lcXML AS String
*!*	        TEXT TO lcXML NOSHOW TEXTMERGE PRETEXT 15
*!*	            <Header>
*!*	                <AuditFileVersion>2.0</AuditFileVersion>
*!*	                <AuditFileCountry>RO</AuditFileCountry>
*!*	                <Company>
*!*	                    <RegistrationNumber><< ALLTRIM(THIS.CompanyCUI) >></RegistrationNumber>
*!*	                    <Name><< ALLTRIM(ICAS.oSoc.Denumire) >></Name>
*!*	                </Company>
*!*	                <DefaultCurrencyCode>RON</DefaultCurrencyCode>
*!*	                <HeaderComment><< ALLTRIM(THIS.DeclarationType) >></HeaderComment>
*!*	            </Header>
*!*	        ENDTEXT
*!*	        STRTOFILE(lcXML, THIS.SAFT_WorkDir + "02.Header.xml")
*!*	    ENDFUNC

*!*	    PROTECTED FUNCTION Generate_GLAccounts()
*!*	        THIS.Log("Generare 04.GeneralLedgerAccounts.xml...")
*!*	        *-- Logica din `_04GeneralLedgerAccounts()`
*!*	    ENDFUNC

*!*	    PROTECTED FUNCTION FinalizeXML(tcFinalFile AS String)
*!*	        THIS.Log("Finalizare fisier XML...")
*!*	        STRTOFILE("</AuditFile>", tcFinalFile, .T.)
*!*	    ENDFUNC

*!*	    PROTECTED FUNCTION DisplayErrors()
*!*	        THIS.Log("Afi?are erori ?i avertismente...")
*!*	        *-- Logica din `Display_Saft_ERR()`
*!*	    ENDFUNC

*!*	    PROTECTED FUNCTION Log(tcMessage AS String)
*!*	        STRTOFILE(TTOC(DATETIME()) + " - " + tcMessage + CHR(13)+CHR(10), THIS.LogFile, .T.)
*!*	    ENDFUNC

*!*	ENDDEFINE

*!*	*!*-----------------------------------------------------------------------------
*!*	*!* CLASS: SAFT_Generator_Periodic
*!*	*!* SCOP:  Implementare CONCRETA pentru declaratiile periodice (L, T, S).
*!*	*!* Mosteneste din clasa de baza si suprascrie metodele pentru a
*!*	*!* implementa logica specifica acestui tip de declaratie.
*!*	*!*-----------------------------------------------------------------------------
*!*	DEFINE CLASS SAFT_Generator_Periodic AS SAFT_Generator_Base
*!*	    
*!*	    PROTECTED FUNCTION CleanupPreviousFiles()
*!*	        THIS.Log("Curatare fisiere vechi pentru declaratie periodica...")
*!*	        ERASE FILE(THIS.SAFT_WorkDir + "01.AuditFile.xml")
*!*	        ERASE FILE(THIS.SAFT_WorkDir + "02.Header.xml")
*!*	        ERASE FILE(THIS.SAFT_WorkDir + "03.MasterFiles.xml")
*!*	        ERASE FILE(THIS.SAFT_WorkDir + "04.GeneralLedgerAccounts.xml")
*!*	        ERASE FILE(THIS.SAFT_WorkDir + "05.Customers.xml")
*!*	        ERASE FILE(THIS.SAFT_WorkDir + "06.Suppliers.xml")
*!*	        ERASE FILE(THIS.SAFT_WorkDir + "07.TaxTable.xml")
*!*	        *... etc. pentru toate cele 24 de fisiere
*!*	    ENDFUNC

*!*	    PROTECTED FUNCTION GenerateXMLSections()
*!*	        THIS.GenerateAuditFileHeader()
*!*	        THIS.GenerateCompanyHeader()
*!*	        
*!*	        *-- MasterFiles
*!*	        STRTOFILE("<MasterFiles>", THIS.SAFT_WorkDir + "03.MasterFiles.xml")
*!*	        THIS.Generate_GLAccounts()
*!*	        THIS.Generate_Customers()
*!*	        THIS.Generate_Suppliers()
*!*	        THIS.GenerateTaxTable()
*!*	        THIS.Generate_UOMTable()
*!*	        * ... etc
*!*	        STRTOFILE("</MasterFiles>", THIS.SAFT_WorkDir + "15.MasterFiles.xml")

*!*	        *-- GeneralLedger
*!*	        THIS.GenerateGLEntries()
*!*	        
*!*	        *-- SourceDocuments
*!*	        STRTOFILE("<SourceDocuments>", THIS.SAFT_WorkDir + "17.SourceDocuments.xml")
*!*	        THIS.Generate_SalesInvoices()
*!*	        THIS.Generate_PurchaseInvoices()
*!*	        THIS.Generate_Payments()
*!*	        * ... etc
*!*	        STRTOFILE("</SourceDocuments>", THIS.SAFT_WorkDir + "23.SourceDocuments.xml")
*!*	    ENDFUNC

*!*	    PROTECTED FUNCTION AssembleFinalXML()
*!*	        THIS.Log("Asamblare fisier XML final pentru declara?ie periodica...")
*!*	        LOCAL lcFinalFile AS String
*!*	        lcFinalFile = THIS.SAFT_FileName

*!*	        *-- Concatenare fi?iere în ordinea corecta
*!*	        STRTOFILE(FILETOSTR(THIS.SAFT_WorkDir + "01.AuditFile.xml"), lcFinalFile)
*!*	        STRTOFILE(FILETOSTR(THIS.SAFT_WorkDir + "02.Header.xml"), lcFinalFile, .T.)
*!*	        STRTOFILE(FILETOSTR(THIS.SAFT_WorkDir + "03.MasterFiles.xml"), lcFinalFile, .T.)
*!*	        STRTOFILE(FILETOSTR(THIS.SAFT_WorkDir + "04.GeneralLedgerAccounts.xml"), lcFinalFile, .T.)
*!*	        STRTOFILE(FILETOSTR(THIS.SAFT_WorkDir + "05.Customers.xml"), lcFinalFile, .T.)
*!*	        * ... etc. pentru toate sec?iunile, în ordinea corecta
*!*	        STRTOFILE(FILETOSTR(THIS.SAFT_WorkDir + "16.GeneralLedgerEntries.xml"), lcFinalFile, .T.)
*!*	        STRTOFILE(FILETOSTR(THIS.SAFT_WorkDir + "17.SourceDocuments.xml"), lcFinalFile, .T.)
*!*	        STRTOFILE(FILETOSTR(THIS.SAFT_WorkDir + "18.SalesInvoices.xml"), lcFinalFile, .T.)
*!*	        * ... etc.
*!*	        STRTOFILE(FILETOSTR(THIS.SAFT_WorkDir + "23.SourceDocuments.xml"), lcFinalFile, .T.)
*!*	        
*!*	        THIS.FinalizeXML(lcFinalFile)
*!*	    ENDFUNC
*!*	    
*!*	    *--- Metode private specifice acestei clase
*!*	    PROTECTED FUNCTION Generate_Customers()
*!*	        THIS.Log("Generare 05.Customers.xml...")
*!*	        *-- Logica din `_05Customers()`
*!*	    ENDFUNC
*!*	    
*!*	    PRIVATE FUNCTION Generate_Suppliers()
*!*	        THIS.Log("Generare 06.Suppliers.xml...")
*!*	        *-- Logica din `_06Suppliers()`
*!*	    ENDFUNC
*!*	    
*!*	    PRIVATE FUNCTION GenerateTaxTable()
*!*	        THIS.Log("Generare 07.TaxTable.xml...")
*!*	        *-- Logica din `_07TaxTable()`
*!*	    ENDFUNC
*!*	    
*!*	    PRIVATE FUNCTION Generate_UOMTable()
*!*	        THIS.Log("Generare 08.UOMTable.xml...")
*!*	        *-- Logica din `_08UOMTable()`
*!*	    ENDFUNC
*!*	    
*!*	    PRIVATE FUNCTION GenerateGLEntries()
*!*	        THIS.Log("Generare 16.GeneralLedgerEntries.xml...")
*!*	        *-- Logica din `_16GeneralLedgerEntries()`
*!*	    ENDFUNC

*!*	    PRIVATE FUNCTION Generate_SalesInvoices()
*!*	        THIS.Log("Generare 18.SalesInvoices.xml...")
*!*	        *-- Logica din `_18SalesInvoices()`
*!*	    ENDFUNC

*!*	    PRIVATE FUNCTION Generate_PurchaseInvoices()
*!*	        THIS.Log("Generare 19.PurchaseInvoices.xml...")
*!*	        *-- Logica din `_19PurchaseInvoices()`
*!*	    ENDFUNC
*!*	    
*!*	    PRIVATE FUNCTION Generate_Payments()
*!*	        THIS.Log("Generare 20.Payments.xml...")
*!*	        *-- Logica din `_20Payments()`
*!*	    ENDFUNC

*!*	ENDDEFINE


*!*	*!*-----------------------------------------------------------------------------
*!*	*!* CLASS: SAFT_Generator_Anual
*!*	*!* SCOP:  Implementare CONCRETA pentru declara?ia Anuala (A).
*!*	*!*-----------------------------------------------------------------------------
*!*	DEFINE CLASS SAFT_Generator_Anual AS SAFT_Generator_Base

*!*	    FUNCTION Init
*!*	        DODEFAULT()
*!*	        THIS.DeclarationType = "A"
*!*	    ENDFUNC

*!*	    PROTECTED FUNCTION CleanupPreviousFiles()
*!*	        THIS.Log("Cura?are fi?iere vechi pentru declara?ie anuala...")
*!*	        *-- Lista de fi?iere de ?ters specifica pentru 'A'
*!*	        ERASE FILE(THIS.SAFT_WorkDir + "01.AuditFile.xml")
*!*	        ERASE FILE(THIS.SAFT_WorkDir + "02.Header.xml")
*!*	        ERASE FILE(THIS.SAFT_WorkDir + "03.MasterFiles.xml")
*!*	        ERASE FILE(THIS.SAFT_WorkDir + "04.GeneralLedgerAccounts.xml")
*!*	        ERASE FILE(THIS.SAFT_WorkDir + "09.AnalysisTypeTable.xml")
*!*	        ERASE FILE(THIS.SAFT_WorkDir + "14.Assets.xml")
*!*	        ERASE FILE(THIS.SAFT_WorkDir + "22.AssetTransactions.xml")
*!*	    ENDFUNC

*!*	    PROTECTED FUNCTION GenerateXMLSections()
*!*	        THIS.GenerateAuditFileHeader()
*!*	        THIS.GenerateCompanyHeader()

*!*	        *-- MasterFiles (sec?iunile specifice declara?iei anuale)
*!*	        STRTOFILE("<MasterFiles>", THIS.SAFT_WorkDir + "03.MasterFiles.xml")
*!*	        THIS.Generate_GLAccounts()
*!*	        THIS.Generate_AnalysisTypeTable()
*!*	        THIS.Generate_Assets()
*!*	        STRTOFILE("</MasterFiles>", THIS.SAFT_WorkDir + "15.MasterFiles.xml")
*!*	        
*!*	        *-- SourceDocuments
*!*	        STRTOFILE("<SourceDocuments>", THIS.SAFT_WorkDir + "17.SourceDocuments.xml")
*!*	        THIS.GenerateAssetTransactions()
*!*	        STRTOFILE("</SourceDocuments>", THIS.SAFT_WorkDir + "23.SourceDocuments.xml")
*!*	    ENDFUNC

*!*	    PROTECTED FUNCTION AssembleFinalXML()
*!*	        THIS.Log("Asamblare fi?ier XML final pentru declara?ie anuala...")
*!*	        LOCAL lcXML AS String
*!*	        lcXML = FILETOSTR(THIS.SAFT_WorkDir + "01.AuditFile.xml")
*!*	        lcXML = lcXML + FILETOSTR(THIS.SAFT_WorkDir + "02.Header.xml")
*!*	        lcXML = lcXML + FILETOSTR(THIS.SAFT_WorkDir + "03.MasterFiles.xml")
*!*	        lcXML = lcXML + FILETOSTR(THIS.SAFT_WorkDir + "04.GeneralLedgerAccounts.xml")
*!*	        
*!*	        *-- Adauga tag-uri goale pentru sec?iunile neaplicabile
*!*	        lcXML = lcXML + "<Customers></Customers><Suppliers></Suppliers><TaxTable></TaxTable><UOMTable></UOMTable>"
*!*	        
*!*	        lcXML = lcXML + FILETOSTR(THIS.SAFT_WorkDir + "09.AnalysisTypeTable.xml")
*!*	        
*!*	        *-- Adauga tag-uri goale
*!*	        lcXML = lcXML + "<MovementTypeTable></MovementTypeTable><Products></Products><Owners></Owners>"
*!*	        
*!*	        lcXML = lcXML + FILETOSTR(THIS.SAFT_WorkDir + "14.Assets.xml")
*!*	        lcXML = lcXML + FILETOSTR(THIS.SAFT_WorkDir + "15.MasterFiles.xml") && </MasterFiles>
*!*	        
*!*	        *-- Adauga tag-uri goale
*!*	        lcXML = lcXML + "<GeneralLedgerEntries></GeneralLedgerEntries>"
*!*	        lcXML = lcXML + FILETOSTR(THIS.SAFT_WorkDir + "17.SourceDocuments.xml")
*!*	        lcXML = lcXML + "<SalesInvoices></SalesInvoices><PurchaseInvoices></PurchaseInvoices><Payments></Payments><MovementOfGoods></MovementOfGoods>"

*!*	        lcXML = lcXML + FILETOSTR(THIS.SAFT_WorkDir + "22.AssetTransactions.xml")
*!*	        lcXML = lcXML + FILETOSTR(THIS.SAFT_WorkDir + "23.SourceDocuments.xml") && </SourceDocuments>
*!*	        
*!*	        STRTOFILE(lcXML, THIS.SAFT_FileName)
*!*	        THIS.FinalizeXML(THIS.SAFT_FileName)
*!*	    ENDFUNC

*!*	    PRIVATE FUNCTION Generate_AnalysisTypeTable()
*!*	        THIS.Log("Generare 09.AnalysisTypeTable.xml...")
*!*	        *-- Logica din `_09AnalysisTypeTable()`
*!*	    ENDFUNC
*!*	    
*!*	    PRIVATE FUNCTION Generate_Assets()
*!*	        THIS.Log("Generare 14.Assets.xml...")
*!*	        *-- Logica din `_14Assets()`
*!*	    ENDFUNC

*!*	    PRIVATE FUNCTION GenerateAssetTransactions()
*!*	        THIS.Log("Generare 22.AssetTransactions.xml...")
*!*	        *-- Logica din `_22AssetTransactions()`
*!*	    ENDFUNC

*!*	ENDDEFINE


*!*	*!*-----------------------------------------------------------------------------
*!*	*!* CLASS: SAFT_Generator_Cerere
*!*	*!* SCOP:  Implementare CONCRETA pentru declara?ia la Cerere (C).
*!*	*!*-----------------------------------------------------------------------------
*!*	DEFINE CLASS SAFT_Generator_Cerere AS SAFT_Generator_Periodic
*!*	    *-- Aceasta clasa poate mo?teni din cea periodica daca logica este similara,
*!*	    *-- sau direct din cea de baza daca este foarte diferita.
*!*	    *-- Aici se vor suprascrie metodele pentru a reflecta logica specifica
*!*	    *-- declara?iei de tip 'C' din codul original.

*!*	    FUNCTION Init
*!*	        DODEFAULT()
*!*	        THIS.DeclarationType = "C"
*!*	    ENDFUNC
*!*	    
*!*	    PROTECTED FUNCTION GenerateXMLSections()
*!*	         *-- Aici se va implementa secven?a specifica pentru tipul 'C',
*!*	         *-- care în codul original pare a fi un hibrid între cea periodica
*!*	         *-- ?i cea anuala, cu anumite sec?iuni omise.
*!*	    ENDFUNC
*!*	    
*!*	    PROTECTED FUNCTION AssembleFinalXML()
*!*	        *-- Aici se va implementa asamblarea specifica pentru tipul 'C'.
*!*	    ENDFUNC

*!*	ENDDEFINE
