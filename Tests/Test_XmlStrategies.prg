*---------------------------------------------------------------------------
* Teste: Test_XmlStrategies
* Descriere: Teste unitare pentru strategiile XML
* Autor: Copilot
* Data: 2024
*---------------------------------------------------------------------------

Define Class Test_XmlStrategies As Custom
	
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
		? "Running XML Strategies Tests"
		? "========================================"
		?
		
		*-- Incarca clasele
		Set Procedure To Classes\Strategies\XmlStrategyFactory Additive
		Set Procedure To Classes\Strategies\XmlGeneratorStrategy Additive
		Set Procedure To Classes\Strategies\B2BXmlStrategy Additive
		Set Procedure To Classes\Strategies\ExportXmlStrategy Additive
		
		*-- Ruleaza testele
		This.Test_XmlStrategyFactory_CreateB2B()
		This.Test_XmlStrategyFactory_CreateExport()
		This.Test_XmlStrategyFactory_CreateReverseCharge()
		This.Test_B2BStrategy_TaxCategory()
		This.Test_ExportStrategy_TaxCategory()
		
		*-- Afiseaza rezultatele
		?
		? "========================================"
		? "Results: " + Transform(This.nTestsPassed) + " passed, " + ;
			Transform(This.nTestsFailed) + " failed"
		? "========================================"
		
		Return This.nTestsFailed = 0
	EndProc
	
	*---------------------------------------------------------------------------
	* Test: XmlStrategyFactory creaza B2B corect
	*---------------------------------------------------------------------------
	Procedure Test_XmlStrategyFactory_CreateB2B()
		Local loFactory, loStrategy, lcResult
		
		Try
			loFactory = CreateObject("XmlStrategyFactory")
			loStrategy = loFactory.Create("N", "RO", .F.)
			
			If VarType(loStrategy) = 'O' And loStrategy.Class == "b2bxmlstrategy"
				This.RecordPass("XmlStrategyFactory_CreateB2B", "B2B strategy created correctly")
			Else
				This.RecordFail("XmlStrategyFactory_CreateB2B", "Wrong strategy type: " + loStrategy.Class)
			EndIf
		Catch To loException
			This.RecordFail("XmlStrategyFactory_CreateB2B", loException.Message)
		EndTry
	EndProc
	
	*---------------------------------------------------------------------------
	* Test: XmlStrategyFactory creaza Export corect
	*---------------------------------------------------------------------------
	Procedure Test_XmlStrategyFactory_CreateExport()
		Local loFactory, loStrategy
		
		Try
			loFactory = CreateObject("XmlStrategyFactory")
			loStrategy = loFactory.Create("N", "DE", .F.)  && Tara != RO
			
			If VarType(loStrategy) = 'O' And loStrategy.Class == "exportxmlstrategy"
				This.RecordPass("XmlStrategyFactory_CreateExport", "Export strategy created correctly")
			Else
				This.RecordFail("XmlStrategyFactory_CreateExport", "Wrong strategy type")
			EndIf
		Catch To loException
			This.RecordFail("XmlStrategyFactory_CreateExport", loException.Message)
		EndTry
	EndProc
	
	*---------------------------------------------------------------------------
	* Test: XmlStrategyFactory creaza ReverseCharge corect
	*---------------------------------------------------------------------------
	Procedure Test_XmlStrategyFactory_CreateReverseCharge()
		Local loFactory, loStrategy
		
		Try
			loFactory = CreateObject("XmlStrategyFactory")
			loStrategy = loFactory.Create("T", "RO", .F.)  && Tip T = taxare inversa
			
			If VarType(loStrategy) = 'O'
				This.RecordPass("XmlStrategyFactory_CreateReverseCharge", "ReverseCharge strategy created")
			Else
				This.RecordFail("XmlStrategyFactory_CreateReverseCharge", "Strategy not created")
			EndIf
		Catch To loException
			This.RecordFail("XmlStrategyFactory_CreateReverseCharge", loException.Message)
		EndTry
	EndProc
	
	*---------------------------------------------------------------------------
	* Test: B2B Strategy - Tax Category
	*---------------------------------------------------------------------------
	Procedure Test_B2BStrategy_TaxCategory()
		Local loStrategy, lcCategory, loContext
		
		Try
			loStrategy = CreateObject("B2BXmlStrategy")
			
			*-- Creaza context minimal
			loContext = CreateObject("Empty")
			AddProperty(loContext, "cTipFactura", "N")
			
			*-- Testeaza categorii
			lcCategory = loStrategy.GetTaxCategoryForLine(loContext, 19, "")
			
			If lcCategory = "S"
				This.RecordPass("B2BStrategy_TaxCategory", "Standard category (S) returned for 19%")
			Else
				This.RecordFail("B2BStrategy_TaxCategory", "Expected S, got: " + lcCategory)
			EndIf
		Catch To loException
			This.RecordFail("B2BStrategy_TaxCategory", loException.Message)
		EndTry
	EndProc
	
	*---------------------------------------------------------------------------
	* Test: Export Strategy - Tax Category
	*---------------------------------------------------------------------------
	Procedure Test_ExportStrategy_TaxCategory()
		Local loStrategy, lcCategory, loContext
		
		Try
			loStrategy = CreateObject("ExportXmlStrategy")
			
			*-- Creaza context pentru export
			loContext = CreateObject("Empty")
			AddProperty(loContext, "cTipFactura", "E")
			AddProperty(loContext, "cTara", "DE")
			
			*-- Testeaza categorie export (G = export)
			lcCategory = loStrategy.GetTaxCategoryForLine(loContext, 0, "")
			
			If InList(lcCategory, "G", "K", "O")
				This.RecordPass("ExportStrategy_TaxCategory", "Export category returned: " + lcCategory)
			Else
				This.RecordFail("ExportStrategy_TaxCategory", "Unexpected category: " + lcCategory)
			EndIf
		Catch To loException
			This.RecordFail("ExportStrategy_TaxCategory", loException.Message)
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
