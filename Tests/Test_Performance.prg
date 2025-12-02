*---------------------------------------------------------------------------
* Teste: Test_Performance
* Descriere: Teste de performanta pentru facturi mari
* Autor: Copilot
* Data: 2024
*---------------------------------------------------------------------------

Define Class Test_Performance As Custom
	
	*-- Proprietati
	nTestsPassed = 0
	nTestsFailed = 0
	Dimension aTestResults[1, 4]  && [name, status, message, duration]
	nResultCount = 0
	
	*-- Praguri de performanta (in secunde)
	nThreshold_XmlGeneration = 5.0   && Max 5 secunde pentru generare XML
	nThreshold_Validation = 1.0      && Max 1 secunda pentru validare
	nThreshold_LargeInvoice = 10.0   && Max 10 secunde pentru factura mare
	
	*---------------------------------------------------------------------------
	* Procedura: Run
	* Descriere: Ruleaza toate testele de performanta
	*---------------------------------------------------------------------------
	Procedure Run()
		? "========================================"
		? "Running Performance Tests"
		? "========================================"
		?
		
		*-- Ruleaza testele
		This.Test_ValidationPerformance()
		This.Test_LargeInvoiceLines()
		This.Test_CachePerformance()
		This.Test_MessageQueuePerformance()
		
		*-- Afiseaza rezultatele
		?
		? "========================================"
		? "Results: " + Transform(This.nTestsPassed) + " passed, " + ;
			Transform(This.nTestsFailed) + " failed"
		? "========================================"
		
		Return This.nTestsFailed = 0
	EndProc
	
	*---------------------------------------------------------------------------
	* Test: Performanta validare
	*---------------------------------------------------------------------------
	Procedure Test_ValidationPerformance()
		Local lnStart, lnEnd, lnDuration
		
		Try
			Set Procedure To Classes\Handlers\ValidationHandler Additive
			Set Procedure To Classes\Handlers\AbstractHandler Additive
			
			*-- Creaza cursor de test cu 100 linii
			This.CreateTestCursor(100)
			
			Local loHandler, loContext
			loHandler = CreateObject("ValidationHandler")
			
			loContext = CreateObject("Empty")
			AddProperty(loContext, "cAlias", "crsEFactura")
			AddProperty(loContext, "lHasError", .F.)
			AddProperty(loContext, "cErrorMessage", "")
			AddProperty(loContext, "lIsRectificativa", .F.)
			AddProperty(loContext, "lIsAutoFactura", .F.)
			
			lnStart = Seconds()
			
			*-- Ruleaza validarea de 10 ori
			Local i
			For i = 1 To 10
				loHandler.CanHandle(loContext)
			EndFor
			
			lnEnd = Seconds()
			lnDuration = lnEnd - lnStart
			
			If lnDuration < This.nThreshold_Validation
				This.RecordPass("ValidationPerformance", ;
					"10 validations in " + Transform(lnDuration, "999.999") + " sec", lnDuration)
			Else
				This.RecordFail("ValidationPerformance", ;
					"Too slow: " + Transform(lnDuration, "999.999") + " sec (max: " + ;
					Transform(This.nThreshold_Validation) + ")", lnDuration)
			EndIf
			
			*-- Cleanup
			Use In Select("crsEFactura")
			
		Catch To loException
			This.RecordFail("ValidationPerformance", loException.Message, 0)
		EndTry
	EndProc
	
	*---------------------------------------------------------------------------
	* Test: Factura mare cu multe linii
	*---------------------------------------------------------------------------
	Procedure Test_LargeInvoiceLines()
		Local lnStart, lnEnd, lnDuration, lnLines
		lnLines = 500  && Testeaza cu 500 linii
		
		Try
			*-- Creaza cursor de test
			This.CreateTestCursor(lnLines)
			
			lnStart = Seconds()
			
			*-- Simuleaza procesarea liniilor
			Select crsEFactura
			Local lnTotal
			lnTotal = 0
			
			Scan
				lnTotal = lnTotal + (crsEFactura.Cantitate * crsEFactura.Pret)
			EndScan
			
			lnEnd = Seconds()
			lnDuration = lnEnd - lnStart
			
			If lnDuration < This.nThreshold_LargeInvoice
				This.RecordPass("LargeInvoiceLines", ;
					Transform(lnLines) + " lines processed in " + ;
					Transform(lnDuration, "999.999") + " sec", lnDuration)
			Else
				This.RecordFail("LargeInvoiceLines", ;
					"Too slow: " + Transform(lnDuration, "999.999") + " sec", lnDuration)
			EndIf
			
			*-- Cleanup
			Use In Select("crsEFactura")
			
		Catch To loException
			This.RecordFail("LargeInvoiceLines", loException.Message, 0)
		EndTry
	EndProc
	
	*---------------------------------------------------------------------------
	* Test: Performanta cache
	*---------------------------------------------------------------------------
	Procedure Test_CachePerformance()
		Local lnStart, lnEnd, lnDuration
		
		Try
			Set Procedure To Classes\Services\CacheService Additive
			
			Local loCache
			loCache = CreateObject("CacheService")
			
			lnStart = Seconds()
			
			*-- Adauga 1000 de iteme
			Local i
			For i = 1 To 1000
				loCache.Set("key_" + Transform(i), "value_" + Transform(i))
			EndFor
			
			*-- Citeste 1000 de iteme
			For i = 1 To 1000
				loCache.Get("key_" + Transform(i))
			EndFor
			
			lnEnd = Seconds()
			lnDuration = lnEnd - lnStart
			
			Local loStats
			loStats = loCache.GetStats()
			
			If lnDuration < 2.0  && Max 2 secunde pentru 2000 operatii
				This.RecordPass("CachePerformance", ;
					"2000 cache ops in " + Transform(lnDuration, "999.999") + " sec. " + ;
					"Hit ratio: " + Transform(loStats.HitRatio * 100, "999.9") + "%", lnDuration)
			Else
				This.RecordFail("CachePerformance", ;
					"Too slow: " + Transform(lnDuration, "999.999") + " sec", lnDuration)
			EndIf
			
		Catch To loException
			This.RecordFail("CachePerformance", loException.Message, 0)
		EndTry
	EndProc
	
	*---------------------------------------------------------------------------
	* Test: Performanta coada de mesaje
	*---------------------------------------------------------------------------
	Procedure Test_MessageQueuePerformance()
		Local lnStart, lnEnd, lnDuration
		
		Try
			Set Procedure To Classes\Services\MessageQueue Additive
			
			Local loQueue
			loQueue = CreateObject("MessageQueue")
			loQueue.cQueueName = "perf_test"
			
			lnStart = Seconds()
			
			*-- Adauga 500 mesaje
			Local i
			For i = 1 To 500
				loQueue.Enqueue("payload_" + Transform(i), Mod(i, 10))
			EndFor
			
			*-- Proceseaza 500 mesaje
			Local loMsg
			For i = 1 To 500
				loMsg = loQueue.Dequeue()
				If Not IsNull(loMsg)
					loQueue.Complete(loMsg.Id)
				EndIf
			EndFor
			
			lnEnd = Seconds()
			lnDuration = lnEnd - lnStart
			
			If lnDuration < 3.0  && Max 3 secunde pentru 1000 operatii
				This.RecordPass("MessageQueuePerformance", ;
					"1000 queue ops in " + Transform(lnDuration, "999.999") + " sec", lnDuration)
			Else
				This.RecordFail("MessageQueuePerformance", ;
					"Too slow: " + Transform(lnDuration, "999.999") + " sec", lnDuration)
			EndIf
			
		Catch To loException
			This.RecordFail("MessageQueuePerformance", loException.Message, 0)
		EndTry
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: CreateTestCursor
	* Descriere: Creaza un cursor de test cu numarul specificat de linii
	*---------------------------------------------------------------------------
	Protected Procedure CreateTestCursor(tnLines)
		*-- Creaza cursor minimal pentru teste
		Create Cursor crsEFactura (;
			Nr C(20), ;
			Data D, ;
			Cod_Fiscal C(20), ;
			Den_Firma C(100), ;
			Tara C(3), ;
			Moneda C(3), ;
			Tip C(3), ;
			Recipisa C(50), ;
			Cantitate N(12,3), ;
			Pret N(12,4), ;
			ProcTva N(5,2), ;
			Cont C(10))
		
		*-- Adauga linii
		Local i
		For i = 1 To tnLines
			Insert Into crsEFactura (Nr, Data, Cod_Fiscal, Den_Firma, Tara, Moneda, ;
				Tip, Cantitate, Pret, ProcTva, Cont) ;
			Values ("F" + Transform(i), Date(), "RO12345678", "Test SRL", "RO", "RON", ;
				"N", i * 1.5, 100.00 + i, 19, "707")
		EndFor
		
		Go Top
	EndProc
	
	*---------------------------------------------------------------------------
	* Proceduri helper pentru inregistrare rezultate
	*---------------------------------------------------------------------------
	Protected Procedure RecordPass(tcTestName, tcMessage, tnDuration)
		This.nTestsPassed = This.nTestsPassed + 1
		This.nResultCount = This.nResultCount + 1
		Dimension This.aTestResults[This.nResultCount, 4]
		This.aTestResults[This.nResultCount, 1] = tcTestName
		This.aTestResults[This.nResultCount, 2] = "PASS"
		This.aTestResults[This.nResultCount, 3] = tcMessage
		This.aTestResults[This.nResultCount, 4] = tnDuration
		? "[PASS] " + tcTestName + ": " + tcMessage
	EndProc
	
	Protected Procedure RecordFail(tcTestName, tcMessage, tnDuration)
		This.nTestsFailed = This.nTestsFailed + 1
		This.nResultCount = This.nResultCount + 1
		Dimension This.aTestResults[This.nResultCount, 4]
		This.aTestResults[This.nResultCount, 1] = tcTestName
		This.aTestResults[This.nResultCount, 2] = "FAIL"
		This.aTestResults[This.nResultCount, 3] = tcMessage
		This.aTestResults[This.nResultCount, 4] = tnDuration
		? "[FAIL] " + tcTestName + ": " + tcMessage
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: GetReport
	* Descriere: Genereaza raport de performanta
	* Returneaza: String
	*---------------------------------------------------------------------------
	Function GetReport()
		Local lcReport, i
		lcReport = "Performance Test Report" + Chr(13) + Chr(10)
		lcReport = lcReport + "========================" + Chr(13) + Chr(10)
		
		For i = 1 To This.nResultCount
			lcReport = lcReport + This.aTestResults[i, 2] + ": " + ;
				This.aTestResults[i, 1] + " - " + ;
				Transform(This.aTestResults[i, 4], "999.999") + " sec" + Chr(13) + Chr(10)
		EndFor
		
		Return lcReport
	EndFunc
	
EndDefine
