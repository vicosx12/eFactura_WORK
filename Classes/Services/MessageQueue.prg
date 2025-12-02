*---------------------------------------------------------------------------
* Clasa: MessageQueue
* Descriere: Coada de mesaje pentru procesare asincrona
*            Suporta prioritati si persistenta
* Pattern: Message Queue
* Autor: Copilot
* Data: 2024
*---------------------------------------------------------------------------

Define Class MessageQueue As Custom
	
	*-- Proprietati
	cQueueName = "default"
	Dimension aMessages[1, 5]     && [id, payload, priority, timestamp, status]
	nMessageCount = 0
	nNextId = 1
	cStoragePath = ""            && Calea pentru persistenta
	lPersistent = .F.            && Daca salveaza pe disk
	oLogger = .Null.
	
	*-- Status-uri
	cStatus_Pending = "PENDING"
	cStatus_Processing = "PROCESSING"
	cStatus_Completed = "COMPLETED"
	cStatus_Failed = "FAILED"
	
	*---------------------------------------------------------------------------
	* Procedura: Init
	* Descriere: Initializeaza coada
	*---------------------------------------------------------------------------
	Procedure Init()
		This.nMessageCount = 0
		This.nNextId = 1
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: Enqueue
	* Descriere: Adauga un mesaj in coada
	* Parametri: 
	*   tvPayload - Continutul mesajului
	*   tnPriority - Prioritatea (0 = normal, mai mare = mai urgent)
	* Returneaza: String - ID-ul mesajului
	*---------------------------------------------------------------------------
	Function Enqueue(tvPayload, tnPriority)
		Local lcId, lnPriority
		
		lnPriority = Iif(Empty(tnPriority), 0, tnPriority)
		lcId = This.cQueueName + "_" + Transform(This.nNextId)
		This.nNextId = This.nNextId + 1
		
		This.nMessageCount = This.nMessageCount + 1
		Dimension This.aMessages[This.nMessageCount, 5]
		This.aMessages[This.nMessageCount, 1] = lcId
		This.aMessages[This.nMessageCount, 2] = tvPayload
		This.aMessages[This.nMessageCount, 3] = lnPriority
		This.aMessages[This.nMessageCount, 4] = DateTime()
		This.aMessages[This.nMessageCount, 5] = This.cStatus_Pending
		
		*-- Sorteaza dupa prioritate
		This.SortByPriority()
		
		*-- Persista daca e configurat
		If This.lPersistent
			This.Persist()
		EndIf
		
		This.Log("Message enqueued: " + lcId)
		
		Return lcId
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: Dequeue
	* Descriere: Scoate urmatorul mesaj din coada
	* Returneaza: Object cu Id si Payload sau .Null.
	*---------------------------------------------------------------------------
	Function Dequeue()
		Local i, loMessage
		
		*-- Gaseste primul mesaj pending
		For i = 1 To This.nMessageCount
			If This.aMessages[i, 5] == This.cStatus_Pending
				*-- Marcheaza ca processing
				This.aMessages[i, 5] = This.cStatus_Processing
				
				*-- Creaza obiect rezultat
				loMessage = CreateObject("Empty")
				AddProperty(loMessage, "Id", This.aMessages[i, 1])
				AddProperty(loMessage, "Payload", This.aMessages[i, 2])
				AddProperty(loMessage, "Priority", This.aMessages[i, 3])
				AddProperty(loMessage, "Timestamp", This.aMessages[i, 4])
				AddProperty(loMessage, "Index", i)
				
				This.Log("Message dequeued: " + This.aMessages[i, 1])
				
				Return loMessage
			EndIf
		EndFor
		
		Return .Null.
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: Peek
	* Descriere: Vizualizeaza urmatorul mesaj fara a-l scoate
	* Returneaza: Object sau .Null.
	*---------------------------------------------------------------------------
	Function Peek()
		Local i, loMessage
		
		For i = 1 To This.nMessageCount
			If This.aMessages[i, 5] == This.cStatus_Pending
				loMessage = CreateObject("Empty")
				AddProperty(loMessage, "Id", This.aMessages[i, 1])
				AddProperty(loMessage, "Payload", This.aMessages[i, 2])
				AddProperty(loMessage, "Priority", This.aMessages[i, 3])
				AddProperty(loMessage, "Timestamp", This.aMessages[i, 4])
				Return loMessage
			EndIf
		EndFor
		
		Return .Null.
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: Complete
	* Descriere: Marcheaza un mesaj ca completat
	* Parametri: 
	*   tcMessageId - ID-ul mesajului
	*---------------------------------------------------------------------------
	Procedure Complete(tcMessageId)
		Local lnIndex
		lnIndex = This.FindMessageIndex(tcMessageId)
		
		If lnIndex > 0
			This.aMessages[lnIndex, 5] = This.cStatus_Completed
			This.Log("Message completed: " + tcMessageId)
			
			If This.lPersistent
				This.Persist()
			EndIf
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Fail
	* Descriere: Marcheaza un mesaj ca esuat
	* Parametri: 
	*   tcMessageId - ID-ul mesajului
	*---------------------------------------------------------------------------
	Procedure Fail(tcMessageId)
		Local lnIndex
		lnIndex = This.FindMessageIndex(tcMessageId)
		
		If lnIndex > 0
			This.aMessages[lnIndex, 5] = This.cStatus_Failed
			This.Log("Message failed: " + tcMessageId)
			
			If This.lPersistent
				This.Persist()
			EndIf
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Requeue
	* Descriere: Repune un mesaj esuat in coada
	* Parametri: 
	*   tcMessageId - ID-ul mesajului
	*---------------------------------------------------------------------------
	Procedure Requeue(tcMessageId)
		Local lnIndex
		lnIndex = This.FindMessageIndex(tcMessageId)
		
		If lnIndex > 0
			This.aMessages[lnIndex, 5] = This.cStatus_Pending
			This.Log("Message requeued: " + tcMessageId)
			
			If This.lPersistent
				This.Persist()
			EndIf
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: GetPendingCount
	* Descriere: Returneaza numarul de mesaje pending
	* Returneaza: Integer
	*---------------------------------------------------------------------------
	Function GetPendingCount()
		Local i, lnCount
		lnCount = 0
		
		For i = 1 To This.nMessageCount
			If This.aMessages[i, 5] == This.cStatus_Pending
				lnCount = lnCount + 1
			EndIf
		EndFor
		
		Return lnCount
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: IsEmpty
	* Descriere: Verifica daca coada e goala
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Function IsEmpty()
		Return This.GetPendingCount() = 0
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: Clear
	* Descriere: Goleste coada
	*---------------------------------------------------------------------------
	Procedure Clear()
		This.nMessageCount = 0
		Dimension This.aMessages[1, 5]
		
		If This.lPersistent
			This.Persist()
		EndIf
		
		This.Log("Queue cleared")
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: ClearCompleted
	* Descriere: Sterge mesajele completate
	*---------------------------------------------------------------------------
	Procedure ClearCompleted()
		Local i
		
		i = 1
		Do While i <= This.nMessageCount
			If This.aMessages[i, 5] == This.cStatus_Completed
				This.RemoveAtIndex(i)
			Else
				i = i + 1
			EndIf
		EndDo
		
		If This.lPersistent
			This.Persist()
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: FindMessageIndex
	* Descriere: Gaseste indexul unui mesaj
	* Parametri: 
	*   tcMessageId - ID-ul mesajului
	* Returneaza: Integer - Indexul sau 0
	*---------------------------------------------------------------------------
	Protected Function FindMessageIndex(tcMessageId)
		Local i
		
		For i = 1 To This.nMessageCount
			If This.aMessages[i, 1] == tcMessageId
				Return i
			EndIf
		EndFor
		
		Return 0
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: RemoveAtIndex
	* Descriere: Sterge un mesaj la index
	*---------------------------------------------------------------------------
	Protected Procedure RemoveAtIndex(tnIndex)
		Local i
		
		For i = tnIndex To This.nMessageCount - 1
			This.aMessages[i, 1] = This.aMessages[i + 1, 1]
			This.aMessages[i, 2] = This.aMessages[i + 1, 2]
			This.aMessages[i, 3] = This.aMessages[i + 1, 3]
			This.aMessages[i, 4] = This.aMessages[i + 1, 4]
			This.aMessages[i, 5] = This.aMessages[i + 1, 5]
		EndFor
		
		This.nMessageCount = This.nMessageCount - 1
		If This.nMessageCount > 0
			Dimension This.aMessages[This.nMessageCount, 5]
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: SortByPriority
	* Descriere: Sorteaza mesajele dupa prioritate (descrescator)
	*---------------------------------------------------------------------------
	Protected Procedure SortByPriority()
		Local i, j
		Local lvTemp1, lvTemp2, lvTemp3, lvTemp4, lvTemp5
		
		For i = 1 To This.nMessageCount - 1
			For j = i + 1 To This.nMessageCount
				If This.aMessages[j, 3] > This.aMessages[i, 3]
					*-- Swap
					lvTemp1 = This.aMessages[i, 1]
					lvTemp2 = This.aMessages[i, 2]
					lvTemp3 = This.aMessages[i, 3]
					lvTemp4 = This.aMessages[i, 4]
					lvTemp5 = This.aMessages[i, 5]
					
					This.aMessages[i, 1] = This.aMessages[j, 1]
					This.aMessages[i, 2] = This.aMessages[j, 2]
					This.aMessages[i, 3] = This.aMessages[j, 3]
					This.aMessages[i, 4] = This.aMessages[j, 4]
					This.aMessages[i, 5] = This.aMessages[j, 5]
					
					This.aMessages[j, 1] = lvTemp1
					This.aMessages[j, 2] = lvTemp2
					This.aMessages[j, 3] = lvTemp3
					This.aMessages[j, 4] = lvTemp4
					This.aMessages[j, 5] = lvTemp5
				EndIf
			EndFor
		EndFor
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Persist
	* Descriere: Salveaza coada pe disk
	*---------------------------------------------------------------------------
	Protected Procedure Persist()
		If Empty(This.cStoragePath)
			Return
		EndIf
		
		Try
			Local lcFile
			lcFile = AddBs(This.cStoragePath) + This.cQueueName + ".queue"
			
			*-- Salveaza ca cursor temporar
			Create Cursor _TempQueue (;
				MsgId C(50), ;
				Payload M, ;
				Priority I, ;
				Timestamp T, ;
				Status C(20))
			
			Local i
			For i = 1 To This.nMessageCount
				Insert Into _TempQueue Values (;
					This.aMessages[i, 1], ;
					Transform(This.aMessages[i, 2]), ;
					This.aMessages[i, 3], ;
					This.aMessages[i, 4], ;
					This.aMessages[i, 5])
			EndFor
			
			Copy To (lcFile) Type Fox2
			Use In _TempQueue
			
		Catch To loException
			This.Log("Error persisting queue: " + loException.Message)
		EndTry
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Restore
	* Descriere: Restaureaza coada de pe disk
	*---------------------------------------------------------------------------
	Procedure Restore()
		If Empty(This.cStoragePath)
			Return
		EndIf
		
		Local lcFile
		lcFile = AddBs(This.cStoragePath) + This.cQueueName + ".queue"
		
		If Not File(lcFile)
			Return
		EndIf
		
		Try
			Use (lcFile) Alias _TempQueue In 0 Shared
			
			This.nMessageCount = 0
			
			Select _TempQueue
			Scan
				This.nMessageCount = This.nMessageCount + 1
				Dimension This.aMessages[This.nMessageCount, 5]
				This.aMessages[This.nMessageCount, 1] = AllTrim(_TempQueue.MsgId)
				This.aMessages[This.nMessageCount, 2] = _TempQueue.Payload
				This.aMessages[This.nMessageCount, 3] = _TempQueue.Priority
				This.aMessages[This.nMessageCount, 4] = _TempQueue.Timestamp
				This.aMessages[This.nMessageCount, 5] = AllTrim(_TempQueue.Status)
			EndScan
			
			Use In _TempQueue
			
			This.Log("Queue restored: " + Transform(This.nMessageCount) + " messages")
			
		Catch To loException
			This.Log("Error restoring queue: " + loException.Message)
		EndTry
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: GetStats
	* Descriere: Returneaza statisticile cozii
	* Returneaza: Object
	*---------------------------------------------------------------------------
	Function GetStats()
		Local loStats, i
		Local lnPending, lnProcessing, lnCompleted, lnFailed
		
		lnPending = 0
		lnProcessing = 0
		lnCompleted = 0
		lnFailed = 0
		
		For i = 1 To This.nMessageCount
			Do Case
				Case This.aMessages[i, 5] == This.cStatus_Pending
					lnPending = lnPending + 1
				Case This.aMessages[i, 5] == This.cStatus_Processing
					lnProcessing = lnProcessing + 1
				Case This.aMessages[i, 5] == This.cStatus_Completed
					lnCompleted = lnCompleted + 1
				Case This.aMessages[i, 5] == This.cStatus_Failed
					lnFailed = lnFailed + 1
			EndCase
		EndFor
		
		loStats = CreateObject("Empty")
		AddProperty(loStats, "Total", This.nMessageCount)
		AddProperty(loStats, "Pending", lnPending)
		AddProperty(loStats, "Processing", lnProcessing)
		AddProperty(loStats, "Completed", lnCompleted)
		AddProperty(loStats, "Failed", lnFailed)
		
		Return loStats
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: Log
	* Descriere: Scrie in log
	*---------------------------------------------------------------------------
	Protected Procedure Log(tcMessage)
		If VarType(This.oLogger) = 'O' And Not IsNull(This.oLogger)
			This.oLogger.Debug("[MessageQueue:" + This.cQueueName + "] " + tcMessage)
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: SetLogger
	* Descriere: Seteaza logger-ul
	*---------------------------------------------------------------------------
	Procedure SetLogger(toLogger)
		This.oLogger = toLogger
	EndProc
	
EndDefine
