*---------------------------------------------------------------------------
* Clasa: AsyncProcessor
* Descriere: Procesor asincron pentru facturi
*            Proceseaza facturi din coada in background
* Pattern: Async Processing / Worker
* Autor: Copilot
* Data: 2024
*---------------------------------------------------------------------------

Define Class AsyncProcessor As Custom
	
	*-- Proprietati
	oMessageQueue = .Null.       && Coada de mesaje
	oFacade = .Null.             && Facade pentru procesare
	oLogger = .Null.
	oEventDispatcher = .Null.    && Event dispatcher
	
	*-- Configurare
	nBatchSize = 10              && Numar de facturi pe batch
	nPollingInterval = 5000      && Interval polling in ms
	nMaxConcurrent = 1           && Procesari concurente (1 in VFP)
	lIsRunning = .F.
	lShouldStop = .F.
	
	*-- Statistici
	nProcessed = 0
	nFailed = 0
	nStartTime = 0
	
	*---------------------------------------------------------------------------
	* Procedura: Init
	* Descriere: Initializeaza procesorul
	*---------------------------------------------------------------------------
	Procedure Init()
		This.nProcessed = 0
		This.nFailed = 0
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: SetQueue
	* Descriere: Seteaza coada de mesaje
	* Parametri: 
	*   toQueue - Coada de mesaje
	*---------------------------------------------------------------------------
	Procedure SetQueue(toQueue)
		This.oMessageQueue = toQueue
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: SetFacade
	* Descriere: Seteaza facade-ul pentru procesare
	* Parametri: 
	*   toFacade - Facade-ul
	*---------------------------------------------------------------------------
	Procedure SetFacade(toFacade)
		This.oFacade = toFacade
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: EnqueueInvoice
	* Descriere: Adauga o factura in coada
	* Parametri: 
	*   tnIdFactura - ID-ul facturii
	*   tcAlias - Alias-ul tabelei
	*   tlRectificativa - Daca e rectificativa
	*   tnPriority - Prioritatea
	* Returneaza: String - ID-ul mesajului
	*---------------------------------------------------------------------------
	Function EnqueueInvoice(tnIdFactura, tcAlias, tlRectificativa, tnPriority)
		If IsNull(This.oMessageQueue)
			Error "Message queue not configured"
			Return ""
		EndIf
		
		*-- Creaza payload
		Local loPayload
		loPayload = CreateObject("Empty")
		AddProperty(loPayload, "IdFactura", tnIdFactura)
		AddProperty(loPayload, "Alias", Iif(Empty(tcAlias), "Iesiri", tcAlias))
		AddProperty(loPayload, "IsRectificativa", Iif(Empty(tlRectificativa), .F., tlRectificativa))
		AddProperty(loPayload, "DetaliiCL", "")
		AddProperty(loPayload, "IsExport", .F.)
		AddProperty(loPayload, "IsAutoFactura", .F.)
		AddProperty(loPayload, "EnqueueTime", DateTime())
		
		Local lcMessageId
		lcMessageId = This.oMessageQueue.Enqueue(loPayload, tnPriority)
		
		This.Log("Invoice enqueued: " + Transform(tnIdFactura) + " as " + lcMessageId)
		
		*-- Dispatch event
		If VarType(This.oEventDispatcher) = 'O' And Not IsNull(This.oEventDispatcher)
			Local loEventData
			loEventData = CreateObject("Empty")
			AddProperty(loEventData, "MessageId", lcMessageId)
			AddProperty(loEventData, "IdFactura", tnIdFactura)
			This.oEventDispatcher.Dispatch("invoice.queued", loEventData)
		EndIf
		
		Return lcMessageId
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: EnqueueBatch
	* Descriere: Adauga un batch de facturi in coada
	* Parametri: 
	*   taIdFacturi - Array cu ID-uri
	*   tcAlias - Alias-ul
	* Returneaza: Integer - Numarul de facturi adaugate
	*---------------------------------------------------------------------------
	Function EnqueueBatch(taIdFacturi, tcAlias)
		Local i, lnCount
		lnCount = 0
		
		For i = 1 To ALen(taIdFacturi)
			If Not Empty(taIdFacturi[i])
				This.EnqueueInvoice(taIdFacturi[i], tcAlias, .F., 0)
				lnCount = lnCount + 1
			EndIf
		EndFor
		
		This.Log("Batch enqueued: " + Transform(lnCount) + " invoices")
		
		Return lnCount
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: Start
	* Descriere: Porneste procesarea
	*---------------------------------------------------------------------------
	Procedure Start()
		If This.lIsRunning
			This.Log("Processor already running")
			Return
		EndIf
		
		If IsNull(This.oMessageQueue)
			Error "Message queue not configured"
			Return
		EndIf
		
		If IsNull(This.oFacade)
			Error "Facade not configured"
			Return
		EndIf
		
		This.lIsRunning = .T.
		This.lShouldStop = .F.
		This.nStartTime = Seconds()
		
		This.Log("Processor started")
		
		*-- Procesare batch
		This.ProcessBatch()
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Stop
	* Descriere: Opreste procesarea
	*---------------------------------------------------------------------------
	Procedure Stop()
		This.lShouldStop = .T.
		This.Log("Processor stop requested")
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: ProcessBatch
	* Descriere: Proceseaza un batch de mesaje
	*---------------------------------------------------------------------------
	Protected Procedure ProcessBatch()
		Local lnProcessed, loMessage
		lnProcessed = 0
		
		Do While Not This.lShouldStop And lnProcessed < This.nBatchSize
			loMessage = This.oMessageQueue.Dequeue()
			
			If IsNull(loMessage)
				*-- Coada goala
				Exit
			EndIf
			
			This.ProcessMessage(loMessage)
			lnProcessed = lnProcessed + 1
			
			DoEvents
		EndDo
		
		This.lIsRunning = .F.
		This.Log("Batch completed: " + Transform(lnProcessed) + " processed")
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: ProcessMessage
	* Descriere: Proceseaza un singur mesaj
	* Parametri: 
	*   toMessage - Mesajul
	*---------------------------------------------------------------------------
	Protected Procedure ProcessMessage(toMessage)
		Local loPayload, lcResult
		loPayload = toMessage.Payload
		
		This.Log("Processing message: " + toMessage.Id + " (Invoice: " + ;
			Transform(loPayload.IdFactura) + ")")
		
		Try
			*-- Proceseaza prin facade
			lcResult = This.oFacade.Process(;
				loPayload.IdFactura, ;
				loPayload.Alias, ;
				loPayload.IsRectificativa, ;
				loPayload.DetaliiCL, ;
				loPayload.IsExport, ;
				loPayload.IsAutoFactura)
			
			*-- Verifica rezultatul
			If Empty(lcResult) Or Left(lcResult, 6) <> "_error"
				This.oMessageQueue.Complete(toMessage.Id)
				This.nProcessed = This.nProcessed + 1
				
				*-- Dispatch success event
				If VarType(This.oEventDispatcher) = 'O' And Not IsNull(This.oEventDispatcher)
					Local loEventData
					loEventData = CreateObject("Empty")
					AddProperty(loEventData, "MessageId", toMessage.Id)
					AddProperty(loEventData, "IdFactura", loPayload.IdFactura)
					AddProperty(loEventData, "Result", lcResult)
					This.oEventDispatcher.Dispatch("invoice.uploaded", loEventData)
				EndIf
			Else
				This.oMessageQueue.Fail(toMessage.Id)
				This.nFailed = This.nFailed + 1
				
				*-- Dispatch failure event
				If VarType(This.oEventDispatcher) = 'O' And Not IsNull(This.oEventDispatcher)
					Local loEventData
					loEventData = CreateObject("Empty")
					AddProperty(loEventData, "MessageId", toMessage.Id)
					AddProperty(loEventData, "IdFactura", loPayload.IdFactura)
					AddProperty(loEventData, "Error", lcResult)
					This.oEventDispatcher.Dispatch("invoice.failed", loEventData)
				EndIf
			EndIf
			
		Catch To loException
			This.oMessageQueue.Fail(toMessage.Id)
			This.nFailed = This.nFailed + 1
			This.Log("Error processing message " + toMessage.Id + ": " + loException.Message)
			
			*-- Dispatch error event
			If VarType(This.oEventDispatcher) = 'O' And Not IsNull(This.oEventDispatcher)
				Local loEventData
				loEventData = CreateObject("Empty")
				AddProperty(loEventData, "MessageId", toMessage.Id)
				AddProperty(loEventData, "Error", loException.Message)
				This.oEventDispatcher.Dispatch("invoice.failed", loEventData)
			EndIf
		EndTry
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: ProcessAll
	* Descriere: Proceseaza toate mesajele din coada
	*---------------------------------------------------------------------------
	Procedure ProcessAll()
		If IsNull(This.oMessageQueue)
			Error "Message queue not configured"
			Return
		EndIf
		
		This.lIsRunning = .T.
		This.lShouldStop = .F.
		This.nStartTime = Seconds()
		
		Local loMessage
		
		Do While Not This.lShouldStop
			loMessage = This.oMessageQueue.Dequeue()
			
			If IsNull(loMessage)
				Exit
			EndIf
			
			This.ProcessMessage(loMessage)
			DoEvents
		EndDo
		
		This.lIsRunning = .F.
		This.Log("All messages processed")
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: RetryFailed
	* Descriere: Repune mesajele esuate in coada
	*---------------------------------------------------------------------------
	Procedure RetryFailed()
		If IsNull(This.oMessageQueue)
			Return
		EndIf
		
		Local i, lnRetried
		lnRetried = 0
		
		For i = 1 To This.oMessageQueue.nMessageCount
			If This.oMessageQueue.aMessages[i, 5] == This.oMessageQueue.cStatus_Failed
				This.oMessageQueue.aMessages[i, 5] = This.oMessageQueue.cStatus_Pending
				lnRetried = lnRetried + 1
			EndIf
		EndFor
		
		This.Log("Retried " + Transform(lnRetried) + " failed messages")
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: GetStats
	* Descriere: Returneaza statisticile procesorului
	* Returneaza: Object
	*---------------------------------------------------------------------------
	Function GetStats()
		Local loStats, lnDuration
		lnDuration = Iif(This.nStartTime > 0, Seconds() - This.nStartTime, 0)
		
		loStats = CreateObject("Empty")
		AddProperty(loStats, "Processed", This.nProcessed)
		AddProperty(loStats, "Failed", This.nFailed)
		AddProperty(loStats, "Duration", lnDuration)
		AddProperty(loStats, "IsRunning", This.lIsRunning)
		AddProperty(loStats, "ThroughputPerSecond", ;
			Iif(lnDuration > 0, This.nProcessed / lnDuration, 0))
		
		If VarType(This.oMessageQueue) = 'O' And Not IsNull(This.oMessageQueue)
			Local loQueueStats
			loQueueStats = This.oMessageQueue.GetStats()
			AddProperty(loStats, "QueuePending", loQueueStats.Pending)
			AddProperty(loStats, "QueueTotal", loQueueStats.Total)
		EndIf
		
		Return loStats
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: ResetStats
	* Descriere: Reseteaza statisticile
	*---------------------------------------------------------------------------
	Procedure ResetStats()
		This.nProcessed = 0
		This.nFailed = 0
		This.nStartTime = 0
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: SetEventDispatcher
	* Descriere: Seteaza event dispatcher-ul
	* Parametri: 
	*   toDispatcher - Event dispatcher
	*---------------------------------------------------------------------------
	Procedure SetEventDispatcher(toDispatcher)
		This.oEventDispatcher = toDispatcher
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Log
	* Descriere: Scrie in log
	*---------------------------------------------------------------------------
	Protected Procedure Log(tcMessage)
		If VarType(This.oLogger) = 'O' And Not IsNull(This.oLogger)
			This.oLogger.Info("[AsyncProcessor] " + tcMessage)
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
		This.Stop()
		This.oMessageQueue = .Null.
		This.oFacade = .Null.
		This.oLogger = .Null.
		This.oEventDispatcher = .Null.
	EndProc
	
EndDefine
