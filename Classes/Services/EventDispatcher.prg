*---------------------------------------------------------------------------
* Clasa: EventDispatcher
* Descriere: Sistem de evenimente pentru decuplarea componentelor
*            Suporta evenimente sincrone si asincrone
* Pattern: Event Dispatcher / Mediator
* Autor: Copilot
* Data: 2024
*---------------------------------------------------------------------------

Define Class EventDispatcher As Custom
	
	*-- Proprietati
	Dimension aListeners[1, 3]    && [eventName, handler, priority]
	nListenerCount = 0
	lAsyncEnabled = .F.          && Mod asincron (experimental)
	oLogger = .Null.
	lStopPropagation = .F.       && Flag pentru oprirea propagarii
	
	*-- Evenimente predefinite
	cEvent_InvoiceValidated = "invoice.validated"
	cEvent_InvoiceUploaded = "invoice.uploaded"
	cEvent_InvoiceFailed = "invoice.failed"
	cEvent_ValidationFailed = "validation.failed"
	cEvent_XmlGenerated = "xml.generated"
	cEvent_ApiError = "api.error"
	cEvent_ProcessStarted = "process.started"
	cEvent_ProcessCompleted = "process.completed"
	
	*---------------------------------------------------------------------------
	* Procedura: Init
	* Descriere: Initializeaza dispatcher-ul
	*---------------------------------------------------------------------------
	Procedure Init()
		This.nListenerCount = 0
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: AddListener
	* Descriere: Adauga un listener pentru un eveniment
	* Parametri: 
	*   tcEventName - Numele evenimentului
	*   toHandler - Handler-ul (obiect cu metoda Handle)
	*   tnPriority - Prioritatea (default 0, mai mare = executat primul)
	*---------------------------------------------------------------------------
	Procedure AddListener(tcEventName, toHandler, tnPriority)
		Local lnPriority
		lnPriority = Iif(Empty(tnPriority), 0, tnPriority)
		
		This.nListenerCount = This.nListenerCount + 1
		Dimension This.aListeners[This.nListenerCount, 3]
		This.aListeners[This.nListenerCount, 1] = Lower(AllTrim(tcEventName))
		This.aListeners[This.nListenerCount, 2] = toHandler
		This.aListeners[This.nListenerCount, 3] = lnPriority
		
		*-- Sorteaza dupa prioritate (descrescator)
		This.SortListeners()
		
		This.Log("Listener added for: " + tcEventName)
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: RemoveListener
	* Descriere: Sterge un listener
	* Parametri: 
	*   tcEventName - Numele evenimentului
	*   toHandler - Handler-ul de sters
	*---------------------------------------------------------------------------
	Procedure RemoveListener(tcEventName, toHandler)
		Local i, lcEventName
		lcEventName = Lower(AllTrim(tcEventName))
		
		i = 1
		Do While i <= This.nListenerCount
			If This.aListeners[i, 1] == lcEventName And ;
			   This.aListeners[i, 2] == toHandler
				*-- Sterge
				This.RemoveAtIndex(i)
			Else
				i = i + 1
			EndIf
		EndDo
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Dispatch
	* Descriere: Dispatches un eveniment catre toti listenerii
	* Parametri: 
	*   tcEventName - Numele evenimentului
	*   toEventData - Datele evenimentului (optional)
	* Returneaza: EventData - Datele evenimentului (posibil modificate)
	*---------------------------------------------------------------------------
	Function Dispatch(tcEventName, toEventData)
		Local i, lcEventName, loHandler, loEventData
		lcEventName = Lower(AllTrim(tcEventName))
		
		*-- Creaza event data daca nu exista
		If VarType(toEventData) <> 'O'
			loEventData = CreateObject("EventData")
			loEventData.cEventName = lcEventName
		Else
			loEventData = toEventData
			If Not PemStatus(loEventData, "cEventName", 5)
				AddProperty(loEventData, "cEventName", lcEventName)
			Else
				loEventData.cEventName = lcEventName
			EndIf
		EndIf
		
		This.lStopPropagation = .F.
		This.Log("Dispatching event: " + lcEventName)
		
		*-- Notifica listenerii
		For i = 1 To This.nListenerCount
			If This.aListeners[i, 1] == lcEventName Or This.aListeners[i, 1] == "*"
				loHandler = This.aListeners[i, 2]
				
				If VarType(loHandler) = 'O' And Not IsNull(loHandler)
					Try
						If PemStatus(loHandler, "Handle", 5)
							loHandler.Handle(loEventData)
						ElseIf PemStatus(loHandler, "OnEvent", 5)
							loHandler.OnEvent(lcEventName, loEventData)
						EndIf
					Catch To loException
						This.Log("Error in listener: " + loException.Message)
					EndTry
				EndIf
				
				*-- Verifica stop propagation
				If This.lStopPropagation
					This.Log("Event propagation stopped")
					Exit
				EndIf
			EndIf
		EndFor
		
		Return loEventData
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: DispatchAsync
	* Descriere: Dispatches un eveniment asincron (experimental)
	* Parametri: 
	*   tcEventName - Numele evenimentului
	*   toEventData - Datele evenimentului
	*---------------------------------------------------------------------------
	Procedure DispatchAsync(tcEventName, toEventData)
		*-- In VFP nu avem async real, dar putem folosi timer
		*-- Aceasta e o implementare simplificata
		This.Dispatch(tcEventName, toEventData)
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: StopPropagation
	* Descriere: Opreste propagarea evenimentului
	*---------------------------------------------------------------------------
	Procedure StopPropagation()
		This.lStopPropagation = .T.
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: SortListeners
	* Descriere: Sorteaza listenerii dupa prioritate
	*---------------------------------------------------------------------------
	Protected Procedure SortListeners()
		Local i, j, lvTemp1, lvTemp2, lvTemp3
		
		*-- Bubble sort (descrescator dupa prioritate)
		For i = 1 To This.nListenerCount - 1
			For j = i + 1 To This.nListenerCount
				If This.aListeners[j, 3] > This.aListeners[i, 3]
					*-- Swap
					lvTemp1 = This.aListeners[i, 1]
					lvTemp2 = This.aListeners[i, 2]
					lvTemp3 = This.aListeners[i, 3]
					
					This.aListeners[i, 1] = This.aListeners[j, 1]
					This.aListeners[i, 2] = This.aListeners[j, 2]
					This.aListeners[i, 3] = This.aListeners[j, 3]
					
					This.aListeners[j, 1] = lvTemp1
					This.aListeners[j, 2] = lvTemp2
					This.aListeners[j, 3] = lvTemp3
				EndIf
			EndFor
		EndFor
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: RemoveAtIndex
	* Descriere: Sterge listener la index
	*---------------------------------------------------------------------------
	Protected Procedure RemoveAtIndex(tnIndex)
		Local i
		
		For i = tnIndex To This.nListenerCount - 1
			This.aListeners[i, 1] = This.aListeners[i + 1, 1]
			This.aListeners[i, 2] = This.aListeners[i + 1, 2]
			This.aListeners[i, 3] = This.aListeners[i + 1, 3]
		EndFor
		
		This.nListenerCount = This.nListenerCount - 1
		If This.nListenerCount > 0
			Dimension This.aListeners[This.nListenerCount, 3]
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: HasListeners
	* Descriere: Verifica daca exista listeneri pentru un eveniment
	* Parametri: 
	*   tcEventName - Numele evenimentului
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Function HasListeners(tcEventName)
		Local i, lcEventName
		lcEventName = Lower(AllTrim(tcEventName))
		
		For i = 1 To This.nListenerCount
			If This.aListeners[i, 1] == lcEventName Or This.aListeners[i, 1] == "*"
				Return .T.
			EndIf
		EndFor
		
		Return .F.
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetListenerCount
	* Descriere: Returneaza numarul de listeneri pentru un eveniment
	* Parametri: 
	*   tcEventName - Numele evenimentului
	* Returneaza: Integer
	*---------------------------------------------------------------------------
	Function GetListenerCount(tcEventName)
		Local i, lnCount, lcEventName
		lcEventName = Lower(AllTrim(tcEventName))
		lnCount = 0
		
		For i = 1 To This.nListenerCount
			If This.aListeners[i, 1] == lcEventName Or This.aListeners[i, 1] == "*"
				lnCount = lnCount + 1
			EndIf
		EndFor
		
		Return lnCount
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: ClearListeners
	* Descriere: Sterge toti listenerii
	* Parametri: 
	*   tcEventName - Numele evenimentului (optional, sterge doar pentru acest eveniment)
	*---------------------------------------------------------------------------
	Procedure ClearListeners(tcEventName)
		If Empty(tcEventName)
			*-- Sterge tot
			This.nListenerCount = 0
			Dimension This.aListeners[1, 3]
		Else
			*-- Sterge doar pentru evenimentul specificat
			Local i, lcEventName
			lcEventName = Lower(AllTrim(tcEventName))
			
			i = 1
			Do While i <= This.nListenerCount
				If This.aListeners[i, 1] == lcEventName
					This.RemoveAtIndex(i)
				Else
					i = i + 1
				EndIf
			EndDo
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Log
	* Descriere: Scrie in log
	*---------------------------------------------------------------------------
	Protected Procedure Log(tcMessage)
		If VarType(This.oLogger) = 'O' And Not IsNull(This.oLogger)
			This.oLogger.Debug("[EventDispatcher] " + tcMessage)
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: SetLogger
	* Descriere: Seteaza logger-ul
	*---------------------------------------------------------------------------
	Procedure SetLogger(toLogger)
		This.oLogger = toLogger
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Destroy
	* Descriere: Curata resursele
	*---------------------------------------------------------------------------
	Procedure Destroy()
		This.ClearListeners()
		This.oLogger = .Null.
	EndProc
	
EndDefine


*---------------------------------------------------------------------------
* Clasa: EventData
* Descriere: Container pentru datele unui eveniment
*---------------------------------------------------------------------------
Define Class EventData As Custom
	cEventName = ""
	tTimestamp = .Null.
	oSource = .Null.
	lHandled = .F.
	
	*-- Proprietati dinamice pentru date
	Procedure Init()
		This.tTimestamp = DateTime()
	EndProc
	
	Procedure SetData(tcName, tvValue)
		If Not PemStatus(This, tcName, 5)
			AddProperty(This, tcName, tvValue)
		Else
			Store tvValue To ("This." + tcName)
		EndIf
	EndProc
	
	Function GetData(tcName, tvDefault)
		If PemStatus(This, tcName, 5)
			Return Evaluate("This." + tcName)
		EndIf
		Return tvDefault
	EndFunc
EndDefine


*---------------------------------------------------------------------------
* Clasa: BaseEventHandler
* Descriere: Clasa de baza pentru handleri de evenimente
*---------------------------------------------------------------------------
Define Class BaseEventHandler As Custom
	cName = "BaseEventHandler"
	oDispatcher = .Null.
	
	Procedure Handle(toEventData)
		*-- Suprascris in clase derivate
	EndProc
	
	Procedure OnEvent(tcEventName, toEventData)
		This.Handle(toEventData)
	EndProc
EndDefine
