******************************************************************************************
*  CLASS: EFacturaFacade
*
*  AUTHOR: Refactored OOP Architecture
*
*  DESCRIPTION:
*     Facade principal pentru procesarea e-Factura.
*     Simplifica interfata cu sistemul oferind o singura metoda de intrare.
*     Coordoneaza toate componentele: Context, Builder, Handlers, Observers.
*
*  DESIGN PATTERN: Facade Pattern
*
*  USAGE:
*     loFacade = CreateObject("EFacturaFacade")
*     lcResult = loFacade.Process(lnIdUnicFactura, "Iesiri", .F., "", .F., .F.)
*
******************************************************************************************

Define Class EFacturaFacade As Custom
	
	*-- Componente
	oContext = .Null.
	oConfig = .Null.
	oLogger = .Null.
	oProgressSubject = .Null.
	oStatsCollector = .Null.
	oChainBuilder = .Null.
	
	*-- Handler chain
	oFirstHandler = .Null.
	
	*-- Setari
	lEnableLogging = .T.
	lEnableProgress = .T.
	lEnableStats = .T.
	lUploadToAnaf = .T.
	
	*-- Referinta la ICAS (daca exista)
	lIsICAS = .F.
	oICAS = .Null.
	
	*---------------------------------------------------------------------------
	* Procedura: Init
	* Descriere: Initializeaza facade-ul
	*---------------------------------------------------------------------------
	Procedure Init()
		*-- Detecteaza ICAS
		This.lIsICAS = (VarType(ICAS) = 'O' And Not IsNull(ICAS))
		If This.lIsICAS
			This.oICAS = ICAS
		EndIf
		
		*-- Initializeaza componentele
		This.InitComponents()
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: InitComponents
	* Descriere: Initializeaza toate componentele necesare
	*---------------------------------------------------------------------------
	Protected Procedure InitComponents()
		*-- Creeaza ConfigProvider
		This.oConfig = CreateObject("ConfigProvider")
		
		*-- Creeaza LoggerService
		This.oLogger = CreateObject("LoggerService")
		This.oLogger.SetConfig(This.oConfig)
		
		*-- Creeaza ProgressSubject
		This.oProgressSubject = CreateObject("ProgressSubject")
		
		*-- Creeaza StatsCollector
		This.oStatsCollector = CreateObject("StatsCollector")
		
		*-- Creeaza HandlerChainBuilder
		This.oChainBuilder = CreateObject("HandlerChainBuilder")
		This.oChainBuilder.WithLogger(This.oLogger)
		This.oChainBuilder.WithConfig(This.oConfig)
		This.oChainBuilder.WithProgressSubject(This.oProgressSubject)
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: Process
	* Descriere: Proceseaza o factura - punct de intrare principal
	* Parametri: 
	*   tnIdUnicFactura - ID-ul unic al facturii
	*   tcAlias - Alias-ul cursorului (Iesiri/Export/Docum)
	*   tlRectificativa - Flag pentru factura rectificativa
	*   tcDetaliiCL - Detalii client
	*   tlIsExport - Flag pentru export
	*   tlIsAutoFactura - Flag pentru autofactura
	* Returneaza: String - Rezultatul procesarii sau mesaj de eroare
	*---------------------------------------------------------------------------
	Function Process(tnIdUnicFactura, tcAlias, tlRectificativa, tcDetaliiCL, tlIsExport, tlIsAutoFactura)
		Local lcResult, loContext
		
		*-- Incepe colectarea statisticilor
		If This.lEnableStats
			This.oStatsCollector.Start("eFactura Process")
		EndIf
		
		*-- Log incepere
		If This.lEnableLogging
			This.oLogger.LogSeparator("PROCESARE E-FACTURA")
			This.oLogger.Info("Incepe procesarea facturii ID=" + Transform(tnIdUnicFactura))
		EndIf
		
		*-- Notifica start
		If This.lEnableProgress
			This.oProgressSubject.NotifyStart("Initializare procesare e-Factura...")
		EndIf
		
		Try
			*-- Creeaza contextul
			loContext = This.CreateContext(tnIdUnicFactura, tcAlias, tlRectificativa, tcDetaliiCL, tlIsExport, tlIsAutoFactura)
			
			If loContext.HasCriticalError()
				lcResult = loContext.cErrorMessage
			Else
				*-- Construieste chain-ul de handleri
				This.BuildHandlerChain()
				
				*-- Proceseaza prin chain
				loContext = This.oFirstHandler.Handle(loContext)
				
				*-- Obtine rezultatul
				lcResult = loContext.GetResult()
			EndIf
			
		Catch To loException
			lcResult = "Eroare neprevazuta: " + loException.Message
			If This.lEnableLogging
				This.oLogger.Error(lcResult)
			EndIf
		EndTry
		
		*-- Stop statistici
		If This.lEnableStats
			This.oStatsCollector.Stop()
			If This.lEnableLogging
				This.oLogger.Info(This.oStatsCollector.GetSummary())
			EndIf
		EndIf
		
		*-- Notifica sfarsit
		If This.lEnableProgress
			If Left(lcResult, 7) = "_error:" Or Left(lcResult, 6) = "Eroare"
				This.oProgressSubject.NotifyError(lcResult)
			Else
				This.oProgressSubject.NotifyComplete("Procesare finalizata!")
			EndIf
		EndIf
		
		*-- Log sfarsit
		If This.lEnableLogging
			This.oLogger.Info("Rezultat: " + Left(lcResult, 200))
			This.oLogger.LogSeparator()
		EndIf
		
		Return lcResult
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: CreateContext
	* Descriere: Creeaza si initializeaza contextul
	* Parametri: (aceiasi ca la Process)
	* Returneaza: EFacturaContext
	*---------------------------------------------------------------------------
	Protected Function CreateContext(tnIdUnicFactura, tcAlias, tlRectificativa, tcDetaliiCL, tlIsExport, tlIsAutoFactura)
		Local loContext
		
		*-- Creeaza contextul
		loContext = CreateObject("EFacturaContext")
		loContext.Initialize(tnIdUnicFactura, tcAlias, tlRectificativa, tcDetaliiCL, tlIsExport, tlIsAutoFactura)
		
		*-- Incarca datele din cursor (daca exista)
		This.LoadContextFromCursor(loContext)
		
		Return loContext
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: LoadContextFromCursor
	* Descriere: Incarca datele din cursor in context
	* Parametri: 
	*   toContext - Contextul de populat
	*---------------------------------------------------------------------------
	Protected Procedure LoadContextFromCursor(toContext)
		If Not Used("crsEFactura")
			toContext.SetError("Cursorul crsEFactura nu este disponibil")
			Return
		EndIf
		
		If RecCount("crsEFactura") = 0
			toContext.SetError("Nu am reusit sa culeg datele pentru generarea XML-ului")
			Return
		EndIf
		
		Select crsEFactura
		Go Top
		
		*-- Populeaza contextul din cursor
		toContext.cNumarFactura = AllTrim(crsEFactura.Nr)
		toContext.dDataFactura = crsEFactura.Data
		toContext.cMoneda = AllTrim(crsEFactura.Moneda)
		toContext.cCodFiscal = AllTrim(crsEFactura.Cod_Fiscal)
		toContext.cTara = AllTrim(crsEFactura.Tara)
		toContext.cTipFactura = AllTrim(crsEFactura.Tip)
		toContext.cRecipisa = AllTrim(crsEFactura.Recipisa)
		
		*-- Determina tipul tertului
		Local lcTipTert
		lcTipTert = AllTrim(Iif(IsNull(crsEFactura.Tip_Tert) Or Empty(crsEFactura.Tip_Tert), '', crsEFactura.Tip_Tert))
		toContext.cTipTert = ICase(;
			Empty(lcTipTert) Or InList(lcTipTert, '', '1'), '', ;
			lcTipTert = '2', 'I', ;
			'E')
		
		*-- Determina modul TVA
		If This.lIsICAS
			toContext.nTipTvaCurent = GetModPlataTva(crsEFactura.Data)
		Else
			toContext.nTipTvaCurent = 1
		EndIf
		
		*-- Upload param extern
		toContext.cUploadParamExtern = Iif(crsEFactura.Is_Extern, '&extern=DA', '')
		
		*-- Cale si nume fisier
		toContext.cCaleFisier = This.GetInvoiceFolder(crsEFactura.Data)
		toContext.cNumeFisier = StrTran(AllTrim(crsEFactura.Nr), "/", "") + "_" + ;
			Transform(DToS(crsEFactura.Data), '@R ####-##-##')
		
		*-- Verifica daca a fost deja transmisa
		If Not Empty(crsEFactura.Recipisa) And Not toContext.lIsRectificativa
			Local lcTipDoc
			lcTipDoc = Iif(toContext.lIsAutoFactura, "Autofactura", "Factura")
			toContext.SetError(lcTipDoc + " figureaza ca fiind generata si transmisa deja.")
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: BuildHandlerChain
	* Descriere: Construieste chain-ul de handleri
	*---------------------------------------------------------------------------
	Protected Procedure BuildHandlerChain()
		If This.lUploadToAnaf
			This.oFirstHandler = This.oChainBuilder.BuildDefault()
		Else
			This.oFirstHandler = This.oChainBuilder.BuildWithoutUpload()
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: GetInvoiceFolder
	* Descriere: Returneaza folder-ul pentru salvarea facturii
	* Parametri: 
	*   tdData - Data facturii
	* Returneaza: String - Calea catre folder
	*---------------------------------------------------------------------------
	Protected Function GetInvoiceFolder(tdData)
		Local lcPath
		
		If This.lIsICAS
			*-- Foloseste functia din ICAS daca exista
			Try
				lcPath = GetFolder_EFactura(tdData, 1)
			Catch
				lcPath = This.oConfig.GetXmlFolder(tdData, 1)
			EndTry
		Else
			lcPath = This.oConfig.GetXmlFolder(tdData, 1)
		EndIf
		
		If Not Directory(lcPath)
			Md (lcPath)
		EndIf
		
		Return lcPath
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: AttachProgressObserver
	* Descriere: Ataseaza un observator pentru progres
	* Parametri: 
	*   toObserver - Obiectul observator
	*---------------------------------------------------------------------------
	Procedure AttachProgressObserver(toObserver)
		If VarType(This.oProgressSubject) = 'O' And Not IsNull(This.oProgressSubject)
			This.oProgressSubject.Attach(toObserver)
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: DetachProgressObserver
	* Descriere: Dezataseaza un observator
	* Parametri: 
	*   toObserver - Obiectul observator
	*---------------------------------------------------------------------------
	Procedure DetachProgressObserver(toObserver)
		If VarType(This.oProgressSubject) = 'O' And Not IsNull(This.oProgressSubject)
			This.oProgressSubject.Detach(toObserver)
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: SetUploadEnabled
	* Descriere: Activeaza/dezactiveaza upload-ul la ANAF
	* Parametri: 
	*   tlEnabled - Flag pentru activare
	*---------------------------------------------------------------------------
	Procedure SetUploadEnabled(tlEnabled)
		This.lUploadToAnaf = tlEnabled
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: SetLoggingEnabled
	* Descriere: Activeaza/dezactiveaza logging-ul
	* Parametri: 
	*   tlEnabled - Flag pentru activare
	*---------------------------------------------------------------------------
	Procedure SetLoggingEnabled(tlEnabled)
		This.lEnableLogging = tlEnabled
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: SetProgressEnabled
	* Descriere: Activeaza/dezactiveaza notificarile de progres
	* Parametri: 
	*   tlEnabled - Flag pentru activare
	*---------------------------------------------------------------------------
	Procedure SetProgressEnabled(tlEnabled)
		This.lEnableProgress = tlEnabled
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: SetStatsEnabled
	* Descriere: Activeaza/dezactiveaza colectarea statisticilor
	* Parametri: 
	*   tlEnabled - Flag pentru activare
	*---------------------------------------------------------------------------
	Procedure SetStatsEnabled(tlEnabled)
		This.lEnableStats = tlEnabled
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: GetStatistics
	* Descriere: Returneaza statisticile ultimei procesari
	* Returneaza: Object - Obiect cu statistici
	*---------------------------------------------------------------------------
	Function GetStatistics()
		If VarType(This.oStatsCollector) = 'O' And Not IsNull(This.oStatsCollector)
			Return This.oStatsCollector.ToObject()
		EndIf
		Return .Null.
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetConfig
	* Descriere: Returneaza configuratia
	* Returneaza: ConfigProvider
	*---------------------------------------------------------------------------
	Function GetConfig()
		Return This.oConfig
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetLogger
	* Descriere: Returneaza logger-ul
	* Returneaza: LoggerService
	*---------------------------------------------------------------------------
	Function GetLogger()
		Return This.oLogger
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: Destroy
	* Descriere: Curata resursele
	*---------------------------------------------------------------------------
	Procedure Destroy()
		This.oContext = .Null.
		This.oConfig = .Null.
		This.oLogger = .Null.
		This.oProgressSubject = .Null.
		This.oStatsCollector = .Null.
		This.oChainBuilder = .Null.
		This.oFirstHandler = .Null.
		This.oICAS = .Null.
	EndProc
	
EndDefine
