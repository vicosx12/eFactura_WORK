******************************************************************************************
*  CLASS: EFacturaContext
*
*  AUTHOR: Refactored OOP Architecture
*
*  DESCRIPTION:
*     Container pentru datele facturii si starea procesarii.
*     Stocheaza toate informatiile necesare pentru procesarea e-Factura
*     si mentine starea curenta a procesarii prin chain-ul de handleri.
*
*  DESIGN PATTERN: Context Object Pattern
*
*  USAGE:
*     loContext = CreateObject("EFacturaContext")
*     loContext.Initialize(lnIdUnicFactura, lcAlias)
*
******************************************************************************************

Define Class EFacturaContext As Custom
	
	*-- Identificare factura
	nIdUnicFactura = 0
	cAlias = ""
	cNumarFactura = ""
	dDataFactura = {}
	cMoneda = "RON"
	
	*-- Informatii despre tipul facturii
	cTipFactura = ""
	cTipRaportare = "B2B"
	cInvoiceType = "380"
	lIsRectificativa = .F.
	lIsAutoFactura = .F.
	lIsExport = .F.
	lIsTaxareInversa = .F.
	
	*-- Informatii vanzator/cumparator
	cCodFiscal = ""
	cTara = "RO"
	cTipTert = ""
	
	*-- Stare procesare
	lHasCriticalError = .F.
	cErrorMessage = ""
	nProcessingStep = 0
	cCurrentHandler = ""
	
	*-- Rezultate procesare
	cXmlContent = ""
	cXmlFilePath = ""
	cIdSolicitare = ""
	cRecipisa = ""
	cCaleFisier = ""
	cNumeFisier = ""
	
	*-- Cursoare si date temporare
	oCrsEFactura = .Null.
	oCrsTva = .Null.
	
	*-- Totaluri calculate
	nTotalNet = 0
	nTotalTva = 0
	nTotalBrut = 0
	nTotalCharges = 0
	nTotalAllowances = 0
	nIncasat = 0
	nLinii = 0
	nLiniiReducere = 0
	nLiniiStornare = 0
	
	*-- Parametri suplimentari
	cDetaliiClient = ""
	cUploadParamExtern = ""
	nTipTvaCurent = 1
	lHasFacturiCuTva = .F.
	
	*-- Statistici
	nStartTime = 0
	nEndTime = 0
	nRecordCount = 0
	nErrorCount = 0
	
	*-- Colectie de erori
	Dimension aErrors[1]
	nErrorsCount = 0
	
	*-- Colectie de avertismente
	Dimension aWarnings[1]
	nWarningsCount = 0
	
	*---------------------------------------------------------------------------
	* Procedura: Init
	* Descriere: Initializeaza contextul
	*---------------------------------------------------------------------------
	Procedure Init()
		This.nStartTime = Seconds()
		This.dDataFactura = Date()
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Initialize
	* Descriere: Initializeaza contextul cu parametrii de baza
	* Parametri: 
	*   tnIdUnicFactura - ID-ul unic al facturii
	*   tcAlias - Alias-ul cursorului (Iesiri/Export/Docum)
	*   tlRectificativa - Flag pentru factura rectificativa
	*   tcDetaliiCL - Detalii client
	*   tlIsExport - Flag pentru export
	*   tlIsAutoFactura - Flag pentru autofactura
	*---------------------------------------------------------------------------
	Procedure Initialize(tnIdUnicFactura, tcAlias, tlRectificativa, tcDetaliiCL, tlIsExport, tlIsAutoFactura)
		*
		This.nIdUnicFactura = tnIdUnicFactura
		This.cAlias = Proper(Iif(Empty(tcAlias), "Iesiri", tcAlias))
		This.lIsRectificativa = tlRectificativa
		This.cDetaliiClient = Iif(IsNullOrEmpty(tcDetaliiCL), "", tcDetaliiCL)
		This.lIsExport = tlIsExport
		This.lIsAutoFactura = Iif(Empty(tlIsAutoFactura), .F., tlIsAutoFactura)
		*
		Return .T.
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: SetError
	* Descriere: Seteaza o eroare critica care opreste procesarea
	* Parametri: 
	*   tcMessage - Mesajul de eroare
	*---------------------------------------------------------------------------
	Procedure SetError(tcMessage)
		This.lHasCriticalError = .T.
		This.cErrorMessage = tcMessage
		This.AddError(tcMessage)
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: AddError
	* Descriere: Adauga o eroare in lista de erori
	* Parametri: 
	*   tcMessage - Mesajul de eroare
	*---------------------------------------------------------------------------
	Procedure AddError(tcMessage)
		This.nErrorsCount = This.nErrorsCount + 1
		This.nErrorCount = This.nErrorsCount
		Dimension This.aErrors[This.nErrorsCount]
		This.aErrors[This.nErrorsCount] = tcMessage
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: AddWarning
	* Descriere: Adauga un avertisment in lista
	* Parametri: 
	*   tcMessage - Mesajul de avertisment
	*---------------------------------------------------------------------------
	Procedure AddWarning(tcMessage)
		This.nWarningsCount = This.nWarningsCount + 1
		Dimension This.aWarnings[This.nWarningsCount]
		This.aWarnings[This.nWarningsCount] = tcMessage
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: ClearErrors
	* Descriere: Sterge toate erorile
	*---------------------------------------------------------------------------
	Procedure ClearErrors()
		This.nErrorsCount = 0
		This.nErrorCount = 0
		This.lHasCriticalError = .F.
		This.cErrorMessage = ""
		Dimension This.aErrors[1]
		This.aErrors[1] = ""
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: GetErrors
	* Descriere: Returneaza toate erorile ca string
	* Returneaza: String cu toate erorile separate prin Chr(13)
	*---------------------------------------------------------------------------
	Function GetErrors()
		Local lcErrors, i
		lcErrors = ""
		For i = 1 To This.nErrorsCount
			lcErrors = lcErrors + This.aErrors[i] + Chr(13)
		EndFor
		Return lcErrors
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetWarnings
	* Descriere: Returneaza toate avertismentele ca string
	* Returneaza: String cu toate avertismentele separate prin Chr(13)
	*---------------------------------------------------------------------------
	Function GetWarnings()
		Local lcWarnings, i
		lcWarnings = ""
		For i = 1 To This.nWarningsCount
			lcWarnings = lcWarnings + This.aWarnings[i] + Chr(13)
		EndFor
		Return lcWarnings
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: HasCriticalError
	* Descriere: Verifica daca exista erori critice
	* Returneaza: Logical - .T. daca exista erori critice
	*---------------------------------------------------------------------------
	Function HasCriticalError()
		Return This.lHasCriticalError
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: SetProcessingStep
	* Descriere: Seteaza pasul curent de procesare
	* Parametri: 
	*   tnStep - Numarul pasului
	*   tcHandlerName - Numele handler-ului curent
	*---------------------------------------------------------------------------
	Procedure SetProcessingStep(tnStep, tcHandlerName)
		This.nProcessingStep = tnStep
		This.cCurrentHandler = tcHandlerName
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: GetDuration
	* Descriere: Returneaza durata procesarii
	* Returneaza: Numeric - Durata in secunde
	*---------------------------------------------------------------------------
	Function GetDuration()
		If This.nEndTime = 0
			This.nEndTime = Seconds()
		EndIf
		Return This.nEndTime - This.nStartTime
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: Finalize
	* Descriere: Marcheaza finalizarea procesarii
	*---------------------------------------------------------------------------
	Procedure Finalize()
		This.nEndTime = Seconds()
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: GetResult
	* Descriere: Returneaza rezultatul procesarii
	* Returneaza: String - Rezultatul sau mesajul de eroare
	*---------------------------------------------------------------------------
	Function GetResult()
		If This.lHasCriticalError
			Return This.cErrorMessage
		EndIf
		If Not Empty(This.cIdSolicitare)
			Return "_index:" + This.cIdSolicitare
		EndIf
		If Not Empty(This.cXmlFilePath)
			Return This.cXmlFilePath
		EndIf
		Return "OK"
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: Destroy
	* Descriere: Curata resursele la distrugerea obiectului
	*---------------------------------------------------------------------------
	Procedure Destroy()
		This.oCrsEFactura = .Null.
		This.oCrsTva = .Null.
	EndProc
	
EndDefine
