*---------------------------------------------------------------------------
* Clasa: RetryPolicy
* Descriere: Politica de retry configurabila pentru operatii
*            Suporta exponential backoff si circuit breaker
* Pattern: Retry Policy / Circuit Breaker
* Autor: Copilot
* Data: 2024
*---------------------------------------------------------------------------

Define Class RetryPolicy As Custom
	
	*-- Proprietati configurabile
	nMaxRetries = 3               && Numar maxim de incercari
	nInitialDelay = 1000          && Delay initial in ms
	nMaxDelay = 30000             && Delay maxim in ms
	nMultiplier = 2               && Factor de multiplicare pentru backoff
	lUseExponentialBackoff = .T.  && Foloseste exponential backoff
	
	*-- Circuit Breaker
	lCircuitBreakerEnabled = .T.
	nFailureThreshold = 5         && Numar de esecuri pentru deschidere circuit
	nCircuitOpenDuration = 60000  && Durata circuit deschis (ms)
	nFailureCount = 0
	nCircuitOpenTime = 0
	cCircuitState = "CLOSED"      && CLOSED, OPEN, HALF_OPEN
	
	*-- Statistici
	nTotalAttempts = 0
	nSuccessfulAttempts = 0
	nFailedAttempts = 0
	
	*-- Exceptii retryable
	Dimension aRetryableErrors[1]
	nRetryableErrorCount = 0
	
	*-- Logger
	oLogger = .Null.
	
	*---------------------------------------------------------------------------
	* Procedura: Init
	* Descriere: Initializeaza politica
	*---------------------------------------------------------------------------
	Procedure Init()
		This.AddRetryableError(-2147024891)  && Network error
		This.AddRetryableError(-2147012867)  && Timeout
		This.AddRetryableError(-2147012889)  && Connection reset
		This.AddRetryableError(500)          && Server error
		This.AddRetryableError(502)          && Bad gateway
		This.AddRetryableError(503)          && Service unavailable
		This.AddRetryableError(504)          && Gateway timeout
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: AddRetryableError
	* Descriere: Adauga un cod de eroare retryable
	* Parametri: 
	*   tnErrorCode - Codul de eroare
	*---------------------------------------------------------------------------
	Procedure AddRetryableError(tnErrorCode)
		This.nRetryableErrorCount = This.nRetryableErrorCount + 1
		Dimension This.aRetryableErrors[This.nRetryableErrorCount]
		This.aRetryableErrors[This.nRetryableErrorCount] = tnErrorCode
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: Execute
	* Descriere: Executa o operatie cu retry
	* Parametri: 
	*   tcExpression - Expresia de executat
	* Returneaza: Rezultatul sau eroare
	*---------------------------------------------------------------------------
	Function Execute(tcExpression)
		Local lnAttempt, lvResult, loException, lnDelay
		
		*-- Verifica circuit breaker
		If This.lCircuitBreakerEnabled And Not This.CanExecute()
			Error "Circuit breaker is OPEN"
			Return .Null.
		EndIf
		
		lnAttempt = 0
		
		Do While lnAttempt < This.nMaxRetries
			lnAttempt = lnAttempt + 1
			This.nTotalAttempts = This.nTotalAttempts + 1
			
			This.Log("Attempt " + Transform(lnAttempt) + "/" + Transform(This.nMaxRetries))
			
			Try
				lvResult = Evaluate(tcExpression)
				
				*-- Succes
				This.nSuccessfulAttempts = This.nSuccessfulAttempts + 1
				This.RecordSuccess()
				This.Log("Attempt " + Transform(lnAttempt) + " succeeded")
				
				Return lvResult
				
			Catch To loException
				This.nFailedAttempts = This.nFailedAttempts + 1
				This.Log("Attempt " + Transform(lnAttempt) + " failed: " + loException.Message)
				
				*-- Verifica daca e retryable
				If Not This.IsRetryable(loException)
					This.RecordFailure()
					Throw
				EndIf
				
				*-- Daca nu mai sunt incercari
				If lnAttempt >= This.nMaxRetries
					This.RecordFailure()
					Throw
				EndIf
				
				*-- Calculeaza delay
				lnDelay = This.CalculateDelay(lnAttempt)
				This.Log("Waiting " + Transform(lnDelay) + " ms before retry")
				
				*-- Asteapta
				This.Wait(lnDelay)
			EndTry
		EndDo
		
		Return .Null.
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: ExecuteWithCallback
	* Descriere: Executa o operatie cu callback pentru retry
	* Parametri: 
	*   toCallback - Obiectul cu metoda Execute()
	* Returneaza: Rezultatul
	*---------------------------------------------------------------------------
	Function ExecuteWithCallback(toCallback)
		Local lnAttempt, lvResult, loException, lnDelay
		
		*-- Verifica circuit breaker
		If This.lCircuitBreakerEnabled And Not This.CanExecute()
			Error "Circuit breaker is OPEN"
			Return .Null.
		EndIf
		
		lnAttempt = 0
		
		Do While lnAttempt < This.nMaxRetries
			lnAttempt = lnAttempt + 1
			This.nTotalAttempts = This.nTotalAttempts + 1
			
			Try
				lvResult = toCallback.Execute()
				This.nSuccessfulAttempts = This.nSuccessfulAttempts + 1
				This.RecordSuccess()
				Return lvResult
				
			Catch To loException
				This.nFailedAttempts = This.nFailedAttempts + 1
				
				If Not This.IsRetryable(loException) Or lnAttempt >= This.nMaxRetries
					This.RecordFailure()
					Throw
				EndIf
				
				lnDelay = This.CalculateDelay(lnAttempt)
				This.Wait(lnDelay)
			EndTry
		EndDo
		
		Return .Null.
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: CalculateDelay
	* Descriere: Calculeaza delay-ul pentru retry
	* Parametri: 
	*   tnAttempt - Numarul incercarii
	* Returneaza: Integer - Delay in ms
	*---------------------------------------------------------------------------
	Protected Function CalculateDelay(tnAttempt)
		Local lnDelay
		
		If This.lUseExponentialBackoff
			lnDelay = This.nInitialDelay * (This.nMultiplier ^ (tnAttempt - 1))
		Else
			lnDelay = This.nInitialDelay
		EndIf
		
		*-- Aplica jitter (10% variatie)
		Local lnJitter
		lnJitter = (Rand() - 0.5) * 0.2 * lnDelay
		lnDelay = lnDelay + lnJitter
		
		*-- Limiteaza la maxim
		Return Min(lnDelay, This.nMaxDelay)
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: IsRetryable
	* Descriere: Verifica daca exceptia e retryable
	* Parametri: 
	*   toException - Exceptia
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Protected Function IsRetryable(toException)
		Local i
		
		For i = 1 To This.nRetryableErrorCount
			If toException.ErrorNo = This.aRetryableErrors[i]
				Return .T.
			EndIf
		EndFor
		
		*-- Verifica mesajul pentru erori de retea
		Local lcMessage
		lcMessage = Lower(toException.Message)
		
		If "timeout" $ lcMessage Or "connection" $ lcMessage Or ;
		   "network" $ lcMessage Or "unavailable" $ lcMessage
			Return .T.
		EndIf
		
		Return .F.
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: Wait
	* Descriere: Asteapta un numar de milisecunde
	* Parametri: 
	*   tnMilliseconds - Milisecunde
	*---------------------------------------------------------------------------
	Protected Procedure Wait(tnMilliseconds)
		Local lnEnd
		lnEnd = Seconds() + (tnMilliseconds / 1000)
		Do While Seconds() < lnEnd
			DoEvents
		EndDo
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: CanExecute
	* Descriere: Verifica daca se poate executa (circuit breaker)
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Function CanExecute()
		Do Case
			Case This.cCircuitState = "CLOSED"
				Return .T.
				
			Case This.cCircuitState = "OPEN"
				*-- Verifica daca a trecut timpul
				If (Seconds() * 1000) - This.nCircuitOpenTime >= This.nCircuitOpenDuration
					This.cCircuitState = "HALF_OPEN"
					This.Log("Circuit breaker: HALF_OPEN")
					Return .T.
				EndIf
				Return .F.
				
			Case This.cCircuitState = "HALF_OPEN"
				Return .T.
		EndCase
		
		Return .T.
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: RecordSuccess
	* Descriere: Inregistreaza un succes (pentru circuit breaker)
	*---------------------------------------------------------------------------
	Protected Procedure RecordSuccess()
		This.nFailureCount = 0
		
		If This.cCircuitState = "HALF_OPEN"
			This.cCircuitState = "CLOSED"
			This.Log("Circuit breaker: CLOSED (recovered)")
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: RecordFailure
	* Descriere: Inregistreaza un esec (pentru circuit breaker)
	*---------------------------------------------------------------------------
	Protected Procedure RecordFailure()
		This.nFailureCount = This.nFailureCount + 1
		
		If This.lCircuitBreakerEnabled And This.nFailureCount >= This.nFailureThreshold
			This.cCircuitState = "OPEN"
			This.nCircuitOpenTime = Seconds() * 1000
			This.Log("Circuit breaker: OPEN (threshold reached)")
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Reset
	* Descriere: Reseteaza starea
	*---------------------------------------------------------------------------
	Procedure Reset()
		This.nFailureCount = 0
		This.cCircuitState = "CLOSED"
		This.nCircuitOpenTime = 0
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: GetStats
	* Descriere: Returneaza statisticile
	* Returneaza: Object
	*---------------------------------------------------------------------------
	Function GetStats()
		Local loStats
		loStats = CreateObject("Empty")
		AddProperty(loStats, "TotalAttempts", This.nTotalAttempts)
		AddProperty(loStats, "SuccessfulAttempts", This.nSuccessfulAttempts)
		AddProperty(loStats, "FailedAttempts", This.nFailedAttempts)
		AddProperty(loStats, "SuccessRate", Iif(This.nTotalAttempts > 0, ;
			This.nSuccessfulAttempts / This.nTotalAttempts, 0))
		AddProperty(loStats, "CircuitState", This.cCircuitState)
		AddProperty(loStats, "FailureCount", This.nFailureCount)
		Return loStats
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: Log
	* Descriere: Scrie in log
	*---------------------------------------------------------------------------
	Protected Procedure Log(tcMessage)
		If VarType(This.oLogger) = 'O' And Not IsNull(This.oLogger)
			This.oLogger.Debug("[RetryPolicy] " + tcMessage)
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
