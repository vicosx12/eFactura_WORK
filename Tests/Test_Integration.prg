******************************************************************************************
*  TEST: Test_Integration
*
*  DESCRIPTION:
*     Teste de integrare pentru fluxul complet e-Factura
*
******************************************************************************************

* Configureaza procedurile necesare
Set Procedure To ../Classes/Core/EFacturaContext Additive
Set Procedure To ../Classes/Core/EFacturaFacade Additive
Set Procedure To ../Classes/Core/ConfigProvider Additive
Set Procedure To ../Classes/Handlers/AbstractHandler Additive
Set Procedure To ../Classes/Handlers/ValidationHandler Additive
Set Procedure To ../Classes/Handlers/TaxCalculationHandler Additive
Set Procedure To ../Classes/Handlers/XmlBuilderHandler Additive
Set Procedure To ../Classes/Handlers/ApiUploaderHandler Additive
Set Procedure To ../Classes/Handlers/PersistenceHandler Additive
Set Procedure To ../Classes/Builders/HandlerChainBuilder Additive
Set Procedure To ../Classes/Observers/ProgressSubject Additive
Set Procedure To ../Classes/Observers/ProgressBarObserver Additive
Set Procedure To ../Classes/Services/LoggerService Additive
Set Procedure To ../Classes/Services/StatsCollector Additive

* Initializeaza contoare teste
Private gnTestsPassed, gnTestsFailed
gnTestsPassed = 0
gnTestsFailed = 0

* Ruleaza testele
Do Test_HandlerChainBuilder
Do Test_ProgressSubject
Do Test_StatsCollector
Do Test_ConfigProvider

* Afiseaza rezultate
? "================================"
? "REZULTATE TESTE: Integration"
? "================================"
? "Teste trecute: " + Transform(gnTestsPassed)
? "Teste esuate:  " + Transform(gnTestsFailed)
? "================================"

Return

*---------------------------------------------------------------------------
* Test: HandlerChainBuilder
*---------------------------------------------------------------------------
Procedure Test_HandlerChainBuilder
    Local loBuilder, loChain
    
    loBuilder = CreateObject("HandlerChainBuilder")
    loBuilder.AddValidation()
    loBuilder.AddTaxCalculation()
    loBuilder.AddXmlBuilder()
    
    If loBuilder.GetHandlerCount() = 3
        gnTestsPassed = gnTestsPassed + 1
        ? "[PASS] Test_HandlerChainBuilder"
    Else
        gnTestsFailed = gnTestsFailed + 1
        ? "[FAIL] Test_HandlerChainBuilder - Asteptat 3 handleri, obtinut " + Transform(loBuilder.GetHandlerCount())
    EndIf
EndProc

*---------------------------------------------------------------------------
* Test: ProgressSubject
*---------------------------------------------------------------------------
Procedure Test_ProgressSubject
    Local loSubject, loObserver
    
    loSubject = CreateObject("ProgressSubject")
    loObserver = CreateObject("ProgressBarObserver")
    loObserver.lShowInConsole = .F.
    
    loSubject.Attach(loObserver)
    
    If loSubject.GetObserverCount() = 1
        gnTestsPassed = gnTestsPassed + 1
        ? "[PASS] Test_ProgressSubject"
    Else
        gnTestsFailed = gnTestsFailed + 1
        ? "[FAIL] Test_ProgressSubject - Asteptat 1 observator"
    EndIf
EndProc

*---------------------------------------------------------------------------
* Test: StatsCollector
*---------------------------------------------------------------------------
Procedure Test_StatsCollector
    Local loStats
    
    loStats = CreateObject("StatsCollector")
    loStats.Start("Test")
    
    loStats.IncrementRecords(10)
    loStats.IncrementErrors(2)
    loStats.IncrementSuccess(8)
    
    loStats.Stop()
    
    If loStats.nRecordCount = 10 And loStats.nErrorCount = 2 And loStats.nSuccessCount = 8
        gnTestsPassed = gnTestsPassed + 1
        ? "[PASS] Test_StatsCollector"
    Else
        gnTestsFailed = gnTestsFailed + 1
        ? "[FAIL] Test_StatsCollector - Contoare incorecte"
    EndIf
EndProc

*---------------------------------------------------------------------------
* Test: ConfigProvider
*---------------------------------------------------------------------------
Procedure Test_ConfigProvider
    Local loConfig, lcUrl
    
    loConfig = CreateObject("ConfigProvider")
    loConfig.SetProduction(.F.)  && Mod test
    
    lcUrl = loConfig.GetApiUrl("upload")
    
    If "test" $ Lower(lcUrl)
        gnTestsPassed = gnTestsPassed + 1
        ? "[PASS] Test_ConfigProvider"
    Else
        gnTestsFailed = gnTestsFailed + 1
        ? "[FAIL] Test_ConfigProvider - URL nu contine 'test'"
    EndIf
EndProc
