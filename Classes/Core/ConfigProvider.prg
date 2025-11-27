******************************************************************************************
*  CLASS: ConfigProvider
*
*  AUTHOR: Refactored OOP Architecture
*
*  DESCRIPTION:
*     Gestioneaza setarile aplicatiei e-Factura.
*     Centralizeaza configurarile pentru URL API, mod productie/test,
*     cai de salvare, optiuni de logging, etc.
*
*  DESIGN PATTERN: Singleton-like Provider Pattern
*
*  USAGE:
*     loConfig = CreateObject("ConfigProvider")
*     lcUrl = loConfig.GetApiUrl()
*
******************************************************************************************

Define Class ConfigProvider As Custom
	
	*-- API URLs
	cApiBaseUrl = "https://api.anaf.ro/"
	cApiBaseProd = "https://api.anaf.ro/prod/FCTEL/rest/"
	cApiBaseTest = "https://api.anaf.ro/test/FCTEL/rest/"
	cPublicApiBaseUrl = "https://webservicesp.anaf.ro/"
	
	*-- API Endpoints
	cApiUploadPath = "upload"
	cApiMessageStatePath = "stareMesaj"
	cApiMessageListPath = "listaMesajeFactura"
	cApiMessagePaginationListPath = "listaMesajePaginatieFactura"
	cApiDownloadPath = "descarcare"
	cApiValidatePath = "validare"
	cApiXmlToPdfPath = "transformare"
	
	*-- Mode settings
	lIsProduction = .F.
	lUseNewArchitecture = .T.
	lEnableLogging = .T.
	lEnableProgress = .T.
	
	*-- Directories
	cBasePath = ""
	cLogPath = ""
	cXmlPath = ""
	cPdfPath = ""
	cZipPath = ""
	
	*-- Limita API (conform ANAF)
	nMaxRequestsPerMinute = 1000
	nMaxUploadsPerDay = 1000
	nMaxStateQueriesPerDay = 10
	nMaxListQueriesPerDay = 1500
	nMaxDownloadsPerDay = 10
	
	*-- Referinta la ICAS (daca exista)
	oICAS = .Null.
	lIsICAS = .F.
	
	*-- Standard e-Factura
	cStandard = "UBL"
	cCustomizationId = "urn:cen.eu:en16931:2017#compliant#urn:efactura.mfinante.ro:CIUS-RO:1.0.1"
	cUblVersion = "2.1"
	
	*---------------------------------------------------------------------------
	* Procedura: Init
	* Descriere: Initializeaza configurarile
	*---------------------------------------------------------------------------
	Procedure Init()
		*-- Detecteaza daca ruleaza in ICAS
		This.lIsICAS = (VarType(ICAS) = 'O' And Not IsNull(ICAS))
		
		If This.lIsICAS
			This.oICAS = ICAS
			*-- Preia setarile din ICAS
			If PemStatus(ICAS, 'oSETTINGS', 5)
				This.lIsProduction = ICAS.oSETTINGS.eFactura_Prod
			EndIf
		EndIf
		
		This.InitializePaths()
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: InitializePaths
	* Descriere: Initializeaza caile de salvare
	*---------------------------------------------------------------------------
	Protected Procedure InitializePaths()
		Local lcBasePath
		
		If This.lIsICAS And PemStatus(This.oICAS, 'cPathDocumente', 5)
			lcBasePath = This.oICAS.cPathDocumente
		Else
			lcBasePath = AddBs(SYS(5) + CurDir())
		EndIf
		
		This.cBasePath = lcBasePath
		This.cLogPath = AddBs(lcBasePath) + "LOG\"
		This.cXmlPath = AddBs(lcBasePath) + "eFactura\"
		This.cPdfPath = AddBs(lcBasePath) + "PDF\"
		This.cZipPath = AddBs(lcBasePath) + "eFactura\ZIP\"
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: GetApiUrl
	* Descriere: Returneaza URL-ul API-ului in functie de mod
	* Parametri: 
	*   tcEndpoint - Endpoint-ul dorit (upload, stareMesaj, etc.)
	* Returneaza: String - URL-ul complet
	*---------------------------------------------------------------------------
	Function GetApiUrl(tcEndpoint)
		Local lcBaseUrl, lcUrl
		
		lcBaseUrl = Iif(This.lIsProduction, This.cApiBaseProd, This.cApiBaseTest)
		
		Do Case
			Case Upper(tcEndpoint) = "UPLOAD"
				lcUrl = lcBaseUrl + This.cApiUploadPath
			Case Upper(tcEndpoint) = "STARE" Or Upper(tcEndpoint) = "STAREMESAJ"
				lcUrl = lcBaseUrl + This.cApiMessageStatePath
			Case Upper(tcEndpoint) = "LISTA"
				lcUrl = lcBaseUrl + This.cApiMessageListPath
			Case Upper(tcEndpoint) = "PAGINATIE"
				lcUrl = lcBaseUrl + This.cApiMessagePaginationListPath
			Case Upper(tcEndpoint) = "DESCARCARE" Or Upper(tcEndpoint) = "DOWNLOAD"
				lcUrl = lcBaseUrl + This.cApiDownloadPath
			Otherwise
				lcUrl = lcBaseUrl + tcEndpoint
		EndCase
		
		Return lcUrl
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetUploadUrl
	* Descriere: Returneaza URL-ul pentru upload cu parametrii necesari
	* Parametri: 
	*   tcCodFiscal - Codul fiscal al emitentului
	*   tlIsExtern - Flag daca este factura externa
	* Returneaza: String - URL-ul complet pentru upload
	*---------------------------------------------------------------------------
	Function GetUploadUrl(tcCodFiscal, tlIsExtern)
		Local lcUrl
		
		lcUrl = This.GetApiUrl("upload") + "?"
		lcUrl = lcUrl + "standard=" + This.cStandard
		lcUrl = lcUrl + "&cif=" + AllTrim(tcCodFiscal)
		
		If tlIsExtern
			lcUrl = lcUrl + "&extern=DA"
		EndIf
		
		Return lcUrl
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetDownloadUrl
	* Descriere: Returneaza URL-ul pentru descarcare
	* Parametri: 
	*   tcIdSolicitare - ID-ul solicitarii
	* Returneaza: String - URL-ul complet pentru descarcare
	*---------------------------------------------------------------------------
	Function GetDownloadUrl(tcIdSolicitare)
		Return This.GetApiUrl("descarcare") + "?id=" + AllTrim(tcIdSolicitare)
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetStateUrl
	* Descriere: Returneaza URL-ul pentru verificare stare
	* Parametri: 
	*   tcIdSolicitare - ID-ul solicitarii
	* Returneaza: String - URL-ul complet pentru verificare stare
	*---------------------------------------------------------------------------
	Function GetStateUrl(tcIdSolicitare)
		Return This.GetApiUrl("stareMesaj") + "?id_incarcare=" + AllTrim(tcIdSolicitare)
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetXmlFolder
	* Descriere: Returneaza folder-ul pentru salvare XML
	* Parametri: 
	*   tdData - Data facturii
	*   tnTip - Tipul (1=Iesiri, 2=Intrari)
	* Returneaza: String - Calea catre folder
	*---------------------------------------------------------------------------
	Function GetXmlFolder(tdData, tnTip)
		Local lcPath, lcYear, lcMonth
		
		lcYear = AllTrim(Str(Year(tdData)))
		lcMonth = PadL(AllTrim(Str(Month(tdData))), 2, "0")
		
		lcPath = AddBs(This.cXmlPath)
		lcPath = lcPath + Iif(tnTip = 1, "IESIRI\", "INTRARI\")
		lcPath = lcPath + lcYear + "\" + lcMonth + "\"
		
		If Not Directory(lcPath)
			Md (lcPath)
		EndIf
		
		Return lcPath
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetLogFolder
	* Descriere: Returneaza folder-ul pentru loguri
	* Returneaza: String - Calea catre folder
	*---------------------------------------------------------------------------
	Function GetLogFolder()
		If Not Directory(This.cLogPath)
			Md (This.cLogPath)
		EndIf
		Return This.cLogPath
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetSetting
	* Descriere: Returneaza o setare generica
	* Parametri: 
	*   tcSettingName - Numele setarii
	*   tvDefault - Valoarea default
	* Returneaza: Valoarea setarii sau default
	*---------------------------------------------------------------------------
	Function GetSetting(tcSettingName, tvDefault)
		Local lvValue
		
		Do Case
			Case Upper(tcSettingName) = "ISPRODUCTION"
				lvValue = This.lIsProduction
			Case Upper(tcSettingName) = "USENEWARCHITECTURE"
				lvValue = This.lUseNewArchitecture
			Case Upper(tcSettingName) = "ENABLELOGGING"
				lvValue = This.lEnableLogging
			Case Upper(tcSettingName) = "ENABLEPROGRESS"
				lvValue = This.lEnableProgress
			Case Upper(tcSettingName) = "STANDARD"
				lvValue = This.cStandard
			Case Upper(tcSettingName) = "CUSTOMIZATIONID"
				lvValue = This.cCustomizationId
			Otherwise
				lvValue = tvDefault
		EndCase
		
		Return lvValue
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: SetProduction
	* Descriere: Seteaza modul productie/test
	* Parametri: 
	*   tlIsProduction - .T. pentru productie, .F. pentru test
	*---------------------------------------------------------------------------
	Procedure SetProduction(tlIsProduction)
		This.lIsProduction = tlIsProduction
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: IsProduction
	* Descriere: Verifica daca este mod productie
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Function IsProduction()
		Return This.lIsProduction
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetCodFiscalSocietate
	* Descriere: Returneaza codul fiscal al societatii
	* Returneaza: String - Codul fiscal
	*---------------------------------------------------------------------------
	Function GetCodFiscalSocietate()
		If This.lIsICAS And PemStatus(This.oICAS, 'oSoc', 5)
			Return AllTrim(This.oICAS.oSoc.CodFiscal)
		EndIf
		Return ""
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetDenumireSocietate
	* Descriere: Returneaza denumirea societatii
	* Returneaza: String - Denumirea
	*---------------------------------------------------------------------------
	Function GetDenumireSocietate()
		If This.lIsICAS And PemStatus(This.oICAS, 'oSoc', 5)
			Return AllTrim(This.oICAS.oSoc.Denumire)
		EndIf
		Return ""
	EndFunc
	
EndDefine
