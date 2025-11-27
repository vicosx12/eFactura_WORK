******************************************************************************************
*  CLASS: HandlerChainBuilder
*
*  AUTHOR: Refactored OOP Architecture
*
*  DESCRIPTION:
*     Builder pentru construirea chain-ului de handleri.
*     Permite configurarea flexibila a ordinii si componentelor chain-ului.
*
*  DESIGN PATTERN: Builder Pattern
*
*  USAGE:
*     loBuilder = CreateObject("HandlerChainBuilder")
*     loBuilder.AddValidation().AddTaxCalculation().AddXmlBuilder()
*     loChain = loBuilder.Build()
*
******************************************************************************************

Define Class HandlerChainBuilder As Custom
	
	*-- Lista de handleri in ordinea de adaugare
	Dimension aHandlers[1]
	nHandlerCount = 0
	
	*-- Configurari comune pentru toti handlerii
	oProgressSubject = .Null.
	oLogger = .Null.
	oConfig = .Null.
	
	*-- Primul handler din chain
	oFirstHandler = .Null.
	
	*---------------------------------------------------------------------------
	* Procedura: Init
	* Descriere: Initializeaza builder-ul
	*---------------------------------------------------------------------------
	Procedure Init()
		This.Reset()
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Reset
	* Descriere: Reseteaza builder-ul
	*---------------------------------------------------------------------------
	Procedure Reset()
		This.nHandlerCount = 0
		Dimension This.aHandlers[1]
		This.oFirstHandler = .Null.
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: AddHandler
	* Descriere: Adauga un handler generic in chain
	* Parametri: 
	*   toHandler - Obiectul handler
	* Returneaza: HandlerChainBuilder - This (fluent interface)
	*---------------------------------------------------------------------------
	Function AddHandler(toHandler)
		If VarType(toHandler) = 'O' And Not IsNull(toHandler)
			This.nHandlerCount = This.nHandlerCount + 1
			Dimension This.aHandlers[This.nHandlerCount]
			This.aHandlers[This.nHandlerCount] = toHandler
			
			*-- Configureaza handler-ul
			This.ConfigureHandler(toHandler)
		EndIf
		
		Return This
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: AddValidation
	* Descriere: Adauga ValidationHandler in chain
	* Returneaza: HandlerChainBuilder - This (fluent interface)
	*---------------------------------------------------------------------------
	Function AddValidation()
		Local loHandler
		loHandler = CreateObject("ValidationHandler")
		Return This.AddHandler(loHandler)
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: AddTaxCalculation
	* Descriere: Adauga TaxCalculationHandler in chain
	* Returneaza: HandlerChainBuilder - This (fluent interface)
	*---------------------------------------------------------------------------
	Function AddTaxCalculation()
		Local loHandler
		loHandler = CreateObject("TaxCalculationHandler")
		Return This.AddHandler(loHandler)
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: AddXmlBuilder
	* Descriere: Adauga XmlBuilderHandler in chain
	* Returneaza: HandlerChainBuilder - This (fluent interface)
	*---------------------------------------------------------------------------
	Function AddXmlBuilder()
		Local loHandler
		loHandler = CreateObject("XmlBuilderHandler")
		Return This.AddHandler(loHandler)
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: AddApiUploader
	* Descriere: Adauga ApiUploaderHandler in chain
	* Returneaza: HandlerChainBuilder - This (fluent interface)
	*---------------------------------------------------------------------------
	Function AddApiUploader()
		Local loHandler
		loHandler = CreateObject("ApiUploaderHandler")
		Return This.AddHandler(loHandler)
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: AddPersistence
	* Descriere: Adauga PersistenceHandler in chain
	* Returneaza: HandlerChainBuilder - This (fluent interface)
	*---------------------------------------------------------------------------
	Function AddPersistence()
		Local loHandler
		loHandler = CreateObject("PersistenceHandler")
		Return This.AddHandler(loHandler)
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: ConfigureHandler
	* Descriere: Configureaza un handler cu referintele comune
	* Parametri: 
	*   toHandler - Handler-ul de configurat
	*---------------------------------------------------------------------------
	Protected Procedure ConfigureHandler(toHandler)
		*-- Seteaza ProgressSubject
		If VarType(This.oProgressSubject) = 'O' And Not IsNull(This.oProgressSubject)
			toHandler.SetProgressSubject(This.oProgressSubject)
		EndIf
		
		*-- Seteaza Logger
		If VarType(This.oLogger) = 'O' And Not IsNull(This.oLogger)
			toHandler.SetLogger(This.oLogger)
		EndIf
		
		*-- Seteaza Config
		If VarType(This.oConfig) = 'O' And Not IsNull(This.oConfig)
			toHandler.SetConfig(This.oConfig)
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: WithProgressSubject
	* Descriere: Seteaza ProgressSubject pentru toti handlerii
	* Parametri: 
	*   toSubject - Obiectul ProgressSubject
	* Returneaza: HandlerChainBuilder - This (fluent interface)
	*---------------------------------------------------------------------------
	Function WithProgressSubject(toSubject)
		This.oProgressSubject = toSubject
		Return This
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: WithLogger
	* Descriere: Seteaza LoggerService pentru toti handlerii
	* Parametri: 
	*   toLogger - Obiectul LoggerService
	* Returneaza: HandlerChainBuilder - This (fluent interface)
	*---------------------------------------------------------------------------
	Function WithLogger(toLogger)
		This.oLogger = toLogger
		Return This
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: WithConfig
	* Descriere: Seteaza ConfigProvider pentru toti handlerii
	* Parametri: 
	*   toConfig - Obiectul ConfigProvider
	* Returneaza: HandlerChainBuilder - This (fluent interface)
	*---------------------------------------------------------------------------
	Function WithConfig(toConfig)
		This.oConfig = toConfig
		Return This
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: Build
	* Descriere: Construieste chain-ul de handleri
	* Returneaza: AbstractHandler - Primul handler din chain
	*---------------------------------------------------------------------------
	Function Build()
		Local i, loPrevHandler, loHandler
		
		If This.nHandlerCount = 0
			Return .Null.
		EndIf
		
		*-- Conecteaza handlerii
		loPrevHandler = .Null.
		For i = 1 To This.nHandlerCount
			loHandler = This.aHandlers[i]
			
			If i = 1
				This.oFirstHandler = loHandler
			Else
				If VarType(loPrevHandler) = 'O' And Not IsNull(loPrevHandler)
					loPrevHandler.SetNext(loHandler)
				EndIf
			EndIf
			
			loPrevHandler = loHandler
		EndFor
		
		Return This.oFirstHandler
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: BuildDefault
	* Descriere: Construieste chain-ul standard cu toti handlerii
	* Returneaza: AbstractHandler - Primul handler din chain
	*---------------------------------------------------------------------------
	Function BuildDefault()
		This.Reset()
		This.AddValidation()
		This.AddTaxCalculation()
		This.AddXmlBuilder()
		This.AddApiUploader()
		This.AddPersistence()
		Return This.Build()
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: BuildWithoutUpload
	* Descriere: Construieste chain-ul fara upload (doar generare XML)
	* Returneaza: AbstractHandler - Primul handler din chain
	*---------------------------------------------------------------------------
	Function BuildWithoutUpload()
		This.Reset()
		This.AddValidation()
		This.AddTaxCalculation()
		This.AddXmlBuilder()
		Return This.Build()
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetHandlerCount
	* Descriere: Returneaza numarul de handleri
	* Returneaza: Numeric
	*---------------------------------------------------------------------------
	Function GetHandlerCount()
		Return This.nHandlerCount
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: Destroy
	* Descriere: Curata resursele
	*---------------------------------------------------------------------------
	Procedure Destroy()
		This.oProgressSubject = .Null.
		This.oLogger = .Null.
		This.oConfig = .Null.
		This.oFirstHandler = .Null.
		This.Reset()
	EndProc
	
EndDefine
