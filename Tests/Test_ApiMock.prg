*---------------------------------------------------------------------------
* Teste: Test_ApiMock
* Descriere: Teste cu mock pentru API ANAF
* Autor: Copilot
* Data: 2024
*---------------------------------------------------------------------------

Define Class Test_ApiMock As Custom
	
	*-- Proprietati
	nTestsPassed = 0
	nTestsFailed = 0
	Dimension aTestResults[1, 3]
	nResultCount = 0
	
	*---------------------------------------------------------------------------
	* Procedura: Run
	* Descriere: Ruleaza toate testele
	*---------------------------------------------------------------------------
	Procedure Run()
		? "========================================"
		? "Running API Mock Tests"
		? "========================================"
		?
		
		*-- Ruleaza testele
		This.Test_MockApiClient_Upload()
		This.Test_MockApiClient_Download()
		This.Test_MockApiClient_Status()
		This.Test_RetryPolicy_ExponentialBackoff()
		This.Test_RetryPolicy_CircuitBreaker()
		
		*-- Afiseaza rezultatele
		?
		? "========================================"
		? "Results: " + Transform(This.nTestsPassed) + " passed, " + ;
			Transform(This.nTestsFailed) + " failed"
		? "========================================"
		
		Return This.nTestsFailed = 0
	EndProc
	
	*---------------------------------------------------------------------------
	* Test: Mock API Client - Upload
	*---------------------------------------------------------------------------
	Procedure Test_MockApiClient_Upload()
		Local loMock, lcResult
		
		Try
			loMock = CreateObject("MockAnafApiClient")
			loMock.SetResponse("upload", '{"id_incarcare": "12345", "ExecutionStatus": 0}')
			
			lcResult = loMock.Upload("test.xml", "RO123456")
			
			If "12345" $ lcResult
				This.RecordPass("MockApiClient_Upload", "Mock upload returned expected response")
			Else
				This.RecordFail("MockApiClient_Upload", "Unexpected response: " + lcResult)
			EndIf
		Catch To loException
			This.RecordFail("MockApiClient_Upload", loException.Message)
		EndTry
	EndProc
	
	*---------------------------------------------------------------------------
	* Test: Mock API Client - Download
	*---------------------------------------------------------------------------
	Procedure Test_MockApiClient_Download()
		Local loMock, lcResult
		
		Try
			loMock = CreateObject("MockAnafApiClient")
			loMock.SetResponse("download", '{"stare": "ok", "id": "12345"}')
			
			lcResult = loMock.Download("12345")
			
			If "ok" $ lcResult
				This.RecordPass("MockApiClient_Download", "Mock download returned expected response")
			Else
				This.RecordFail("MockApiClient_Download", "Unexpected response: " + lcResult)
			EndIf
		Catch To loException
			This.RecordFail("MockApiClient_Download", loException.Message)
		EndTry
	EndProc
	
	*---------------------------------------------------------------------------
	* Test: Mock API Client - Status
	*---------------------------------------------------------------------------
	Procedure Test_MockApiClient_Status()
		Local loMock, lcResult
		
		Try
			loMock = CreateObject("MockAnafApiClient")
			loMock.SetResponse("status", '{"stare": "validat", "id_descarcare": "67890"}')
			
			lcResult = loMock.GetStatus("12345")
			
			If "validat" $ lcResult
				This.RecordPass("MockApiClient_Status", "Mock status returned expected response")
			Else
				This.RecordFail("MockApiClient_Status", "Unexpected response: " + lcResult)
			EndIf
		Catch To loException
			This.RecordFail("MockApiClient_Status", loException.Message)
		EndTry
	EndProc
	
	*---------------------------------------------------------------------------
	* Test: Retry Policy - Exponential Backoff
	*---------------------------------------------------------------------------
	Procedure Test_RetryPolicy_ExponentialBackoff()
		Try
			Set Procedure To Classes\Services\RetryPolicy Additive
			
			Local loPolicy
			loPolicy = CreateObject("RetryPolicy")
			loPolicy.nInitialDelay = 100
			loPolicy.nMultiplier = 2
			loPolicy.lUseExponentialBackoff = .T.
			
			*-- Verifica calculul delay-ului
			Local lnDelay1, lnDelay2, lnDelay3
			lnDelay1 = loPolicy.CalculateDelay(1)
			lnDelay2 = loPolicy.CalculateDelay(2)
			lnDelay3 = loPolicy.CalculateDelay(3)
			
			*-- Delay-ul ar trebui sa creasca exponential (cu jitter)
			If lnDelay2 > lnDelay1 And lnDelay3 > lnDelay2
				This.RecordPass("RetryPolicy_ExponentialBackoff", ;
					"Delays increase: " + Transform(lnDelay1) + " < " + ;
					Transform(lnDelay2) + " < " + Transform(lnDelay3))
			Else
				This.RecordFail("RetryPolicy_ExponentialBackoff", "Delays not increasing correctly")
			EndIf
		Catch To loException
			This.RecordFail("RetryPolicy_ExponentialBackoff", loException.Message)
		EndTry
	EndProc
	
	*---------------------------------------------------------------------------
	* Test: Retry Policy - Circuit Breaker
	*---------------------------------------------------------------------------
	Procedure Test_RetryPolicy_CircuitBreaker()
		Try
			Set Procedure To Classes\Services\RetryPolicy Additive
			
			Local loPolicy
			loPolicy = CreateObject("RetryPolicy")
			loPolicy.lCircuitBreakerEnabled = .T.
			loPolicy.nFailureThreshold = 3
			
			*-- Initial circuit ar trebui sa fie CLOSED
			If loPolicy.cCircuitState = "CLOSED" And loPolicy.CanExecute()
				*-- Simuleaza esecuri
				loPolicy.RecordFailure()
				loPolicy.RecordFailure()
				loPolicy.RecordFailure()
				
				*-- Acum circuit ar trebui sa fie OPEN
				If loPolicy.cCircuitState = "OPEN"
					This.RecordPass("RetryPolicy_CircuitBreaker", ;
						"Circuit opened after " + Transform(loPolicy.nFailureThreshold) + " failures")
				Else
					This.RecordFail("RetryPolicy_CircuitBreaker", ;
						"Circuit state is " + loPolicy.cCircuitState + " instead of OPEN")
				EndIf
			Else
				This.RecordFail("RetryPolicy_CircuitBreaker", "Initial state not CLOSED")
			EndIf
		Catch To loException
			This.RecordFail("RetryPolicy_CircuitBreaker", loException.Message)
		EndTry
	EndProc
	
	*---------------------------------------------------------------------------
	* Proceduri helper pentru inregistrare rezultate
	*---------------------------------------------------------------------------
	Protected Procedure RecordPass(tcTestName, tcMessage)
		This.nTestsPassed = This.nTestsPassed + 1
		This.nResultCount = This.nResultCount + 1
		Dimension This.aTestResults[This.nResultCount, 3]
		This.aTestResults[This.nResultCount, 1] = tcTestName
		This.aTestResults[This.nResultCount, 2] = "PASS"
		This.aTestResults[This.nResultCount, 3] = tcMessage
		? "[PASS] " + tcTestName + ": " + tcMessage
	EndProc
	
	Protected Procedure RecordFail(tcTestName, tcMessage)
		This.nTestsFailed = This.nTestsFailed + 1
		This.nResultCount = This.nResultCount + 1
		Dimension This.aTestResults[This.nResultCount, 3]
		This.aTestResults[This.nResultCount, 1] = tcTestName
		This.aTestResults[This.nResultCount, 2] = "FAIL"
		This.aTestResults[This.nResultCount, 3] = tcMessage
		? "[FAIL] " + tcTestName + ": " + tcMessage
	EndProc
	
EndDefine


*---------------------------------------------------------------------------
* Clasa: MockAnafApiClient
* Descriere: Mock pentru API ANAF pentru testare
*---------------------------------------------------------------------------
Define Class MockAnafApiClient As Custom
	
	Dimension aResponses[1, 2]
	nResponseCount = 0
	nCallCount = 0
	Dimension aCallLog[1, 3]
	
	Procedure SetResponse(tcOperation, tcResponse)
		This.nResponseCount = This.nResponseCount + 1
		Dimension This.aResponses[This.nResponseCount, 2]
		This.aResponses[This.nResponseCount, 1] = Lower(tcOperation)
		This.aResponses[This.nResponseCount, 2] = tcResponse
	EndProc
	
	Function GetResponse(tcOperation)
		Local i
		For i = 1 To This.nResponseCount
			If This.aResponses[i, 1] == Lower(tcOperation)
				Return This.aResponses[i, 2]
			EndIf
		EndFor
		Return ""
	EndFunc
	
	Function Upload(tcFile, tcCui)
		This.LogCall("upload", tcFile, tcCui)
		Return This.GetResponse("upload")
	EndFunc
	
	Function Download(tcId)
		This.LogCall("download", tcId, "")
		Return This.GetResponse("download")
	EndFunc
	
	Function GetStatus(tcId)
		This.LogCall("status", tcId, "")
		Return This.GetResponse("status")
	EndFunc
	
	Protected Procedure LogCall(tcOperation, tcParam1, tcParam2)
		This.nCallCount = This.nCallCount + 1
		Dimension This.aCallLog[This.nCallCount, 3]
		This.aCallLog[This.nCallCount, 1] = tcOperation
		This.aCallLog[This.nCallCount, 2] = tcParam1
		This.aCallLog[This.nCallCount, 3] = tcParam2
	EndProc
	
EndDefine
