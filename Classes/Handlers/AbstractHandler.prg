******************************************************************************************
*  CLASS: AbstractHandler
*
*  AUTHOR: Refactored OOP Architecture
*
*  DESCRIPTION:
*     Clasa abstracta de baza pentru toti handlerii din chain-ul de procesare.
*     Implementeaza pattern-ul Chain of Responsibility.
*
*  DESIGN PATTERN: Chain of Responsibility
*
*  USAGE:
*     Define Class MyHandler As AbstractHandler
*         Protected Procedure DoHandle(toContext)
*             * Implementare specifica
*         EndProc
*     EndDefine
*
******************************************************************************************

Define Class AbstractHandler As Custom
	
	*-- Referinta la urmatorul handler din chain
	oNext = .Null.
	
	*-- Numele handler-ului
	cName = "AbstractHandler"
	
	*-- Ordinea in chain (pentru sortare)
	nOrder = 0
	
	*-- Flag daca handler-ul este activ
	lEnabled = .T.
	
	*-- Referinta la ProgressSubject pentru notificari
	oProgressSubject = .Null.
	
	*-- Referinta la LoggerService
	oLogger = .Null.
	
	*-- Referinta la ConfigProvider
	oConfig = .Null.
	
	*-- Statistici
	nStartTime = 0
	nEndTime = 0
	nProcessedCount = 0
	
	*---------------------------------------------------------------------------
	* Procedura: Init
	* Descriere: Initializeaza handler-ul
	*---------------------------------------------------------------------------
	Procedure Init()
		This.cName = This.Class
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: Handle
	* Descriere: Proceseaza contextul si trece la urmatorul handler
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	* Returneaza: EFacturaContext - Contextul procesat
	*---------------------------------------------------------------------------
	Function Handle(toContext)
		*-- Verifica daca handler-ul este activ
		If Not This.lEnabled
			Return This.PassToNext(toContext)
		EndIf
		
		*-- Inregistreaza timpul de start
		This.nStartTime = Seconds()
		
		*-- Seteaza pasul de procesare in context
		toContext.SetProcessingStep(This.nOrder, This.cName)
		
		*-- Log incepere procesare
		This.LogInfo("Incepere procesare: " + This.cName)
		
		*-- Notifica observatorii despre progres
		This.NotifyProgress(This.nOrder * 10, "Procesare: " + This.cName)
		
		*-- Verifica daca acest handler poate procesa
		If This.CanHandle(toContext)
			*-- Proceseaza
			Try
				This.DoHandle(toContext)
				This.nProcessedCount = This.nProcessedCount + 1
			Catch To loException
				*-- Seteaza eroarea in context
				toContext.SetError("Eroare in " + This.cName + ": " + loException.Message)
				This.LogError("Exceptie: " + loException.Message)
			EndTry
		EndIf
		
		*-- Inregistreaza timpul de sfarsit
		This.nEndTime = Seconds()
		
		*-- Log finalizare
		This.LogInfo("Finalizare procesare: " + This.cName + " (" + Transform(This.GetDuration()) + "s)")
		
		*-- Continua chain-ul daca nu sunt erori critice
		If Not toContext.HasCriticalError() And Not IsNull(This.oNext)
			Return This.oNext.Handle(toContext)
		EndIf
		
		Return toContext
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: CanHandle
	* Descriere: Verifica daca handler-ul poate procesa contextul
	*            Poate fi suprascris in clasele derivate
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	* Returneaza: Logical - .T. daca poate procesa
	*---------------------------------------------------------------------------
	Protected Function CanHandle(toContext)
		Return .T.
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: DoHandle
	* Descriere: Metoda abstracta - trebuie implementata in clasele derivate
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	*---------------------------------------------------------------------------
	Protected Procedure DoHandle(toContext)
		Error "DoHandle trebuie implementat in clasa derivata: " + This.cName
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: PassToNext
	* Descriere: Trece procesarea la urmatorul handler fara a procesa
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	* Returneaza: EFacturaContext
	*---------------------------------------------------------------------------
	Protected Function PassToNext(toContext)
		If Not IsNull(This.oNext)
			Return This.oNext.Handle(toContext)
		EndIf
		Return toContext
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: SetNext
	* Descriere: Seteaza urmatorul handler din chain (fluent interface)
	* Parametri: 
	*   toHandler - Handler-ul urmator
	* Returneaza: AbstractHandler - Handler-ul setat (pentru chaining)
	*---------------------------------------------------------------------------
	Function SetNext(toHandler)
		This.oNext = toHandler
		Return toHandler
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: SetProgressSubject
	* Descriere: Seteaza referinta la ProgressSubject
	* Parametri: 
	*   toSubject - Obiectul ProgressSubject
	*---------------------------------------------------------------------------
	Procedure SetProgressSubject(toSubject)
		This.oProgressSubject = toSubject
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: SetLogger
	* Descriere: Seteaza referinta la LoggerService
	* Parametri: 
	*   toLogger - Obiectul LoggerService
	*---------------------------------------------------------------------------
	Procedure SetLogger(toLogger)
		This.oLogger = toLogger
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: SetConfig
	* Descriere: Seteaza referinta la ConfigProvider
	* Parametri: 
	*   toConfig - Obiectul ConfigProvider
	*---------------------------------------------------------------------------
	Procedure SetConfig(toConfig)
		This.oConfig = toConfig
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: NotifyProgress
	* Descriere: Notifica observatorii despre progres
	* Parametri: 
	*   tnPercent - Procentul de progres
	*   tcMessage - Mesajul de progres
	*---------------------------------------------------------------------------
	Protected Procedure NotifyProgress(tnPercent, tcMessage)
		If VarType(This.oProgressSubject) = 'O' And Not IsNull(This.oProgressSubject)
			This.oProgressSubject.Notify(tnPercent, tcMessage)
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: LogInfo
	* Descriere: Scrie un mesaj informativ in log
	* Parametri: 
	*   tcMessage - Mesajul
	*---------------------------------------------------------------------------
	Protected Procedure LogInfo(tcMessage)
		If VarType(This.oLogger) = 'O' And Not IsNull(This.oLogger)
			This.oLogger.Info(tcMessage, This.cName)
		Else
			? "[INFO] [" + This.cName + "] " + tcMessage
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: LogWarning
	* Descriere: Scrie un avertisment in log
	* Parametri: 
	*   tcMessage - Mesajul
	*---------------------------------------------------------------------------
	Protected Procedure LogWarning(tcMessage)
		If VarType(This.oLogger) = 'O' And Not IsNull(This.oLogger)
			This.oLogger.Warning(tcMessage, This.cName)
		Else
			? "[WARNING] [" + This.cName + "] " + tcMessage
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: LogError
	* Descriere: Scrie o eroare in log
	* Parametri: 
	*   tcMessage - Mesajul
	*---------------------------------------------------------------------------
	Protected Procedure LogError(tcMessage)
		If VarType(This.oLogger) = 'O' And Not IsNull(This.oLogger)
			This.oLogger.Error(tcMessage, This.cName)
		Else
			? "[ERROR] [" + This.cName + "] " + tcMessage
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: LogDebug
	* Descriere: Scrie un mesaj de debug in log
	* Parametri: 
	*   tcMessage - Mesajul
	*---------------------------------------------------------------------------
	Protected Procedure LogDebug(tcMessage)
		If VarType(This.oLogger) = 'O' And Not IsNull(This.oLogger)
			This.oLogger.Debug(tcMessage, This.cName)
		Else
			? "[DEBUG] [" + This.cName + "] " + tcMessage
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: GetDuration
	* Descriere: Returneaza durata procesarii
	* Returneaza: Numeric - Durata in secunde
	*---------------------------------------------------------------------------
	Function GetDuration()
		Local lnEnd
		lnEnd = Iif(This.nEndTime > 0, This.nEndTime, Seconds())
		Return lnEnd - This.nStartTime
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetChainLength
	* Descriere: Returneaza lungimea chain-ului de la acest handler
	* Returneaza: Numeric - Numarul de handleri in chain
	*---------------------------------------------------------------------------
	Function GetChainLength()
		If IsNull(This.oNext)
			Return 1
		EndIf
		Return 1 + This.oNext.GetChainLength()
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: Enable
	* Descriere: Activeaza handler-ul
	*---------------------------------------------------------------------------
	Procedure Enable()
		This.lEnabled = .T.
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Disable
	* Descriere: Dezactiveaza handler-ul
	*---------------------------------------------------------------------------
	Procedure Disable()
		This.lEnabled = .F.
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Destroy
	* Descriere: Curata resursele la distrugerea obiectului
	*---------------------------------------------------------------------------
	Procedure Destroy()
		This.oNext = .Null.
		This.oProgressSubject = .Null.
		This.oLogger = .Null.
		This.oConfig = .Null.
	EndProc
	
EndDefine
