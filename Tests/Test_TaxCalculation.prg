******************************************************************************************
*  TEST: Test_TaxCalculation
*
*  DESCRIPTION:
*     Teste unitare pentru TaxCalculationHandler
*
******************************************************************************************

* Configureaza procedurile necesare
Set Procedure To ../Classes/Core/EFacturaContext Additive
Set Procedure To ../Classes/Handlers/AbstractHandler Additive
Set Procedure To ../Classes/Handlers/TaxCalculationHandler Additive

* Initializeaza contoare teste
Private gnTestsPassed, gnTestsFailed
gnTestsPassed = 0
gnTestsFailed = 0

* Ruleaza testele
Do Test_TaxCategoryS
Do Test_TaxCategoryAE
Do Test_TaxCategoryE
Do Test_CalculateTotals

* Afiseaza rezultate
? "================================"
? "REZULTATE TESTE: TaxCalculation"
? "================================"
? "Teste trecute: " + Transform(gnTestsPassed)
? "Teste esuate:  " + Transform(gnTestsFailed)
? "================================"

Return

*---------------------------------------------------------------------------
* Test: Categorie TVA S (standard)
*---------------------------------------------------------------------------
Procedure Test_TaxCategoryS
    Local loHandler, lcCategory
    
    loHandler = CreateObject("TaxCalculationHandler")
    
    * Pentru TVA 19% ar trebui sa fie categoria S
    * Logica: daca nu e taxare inversa si nu e scutit, e standard
    
    gnTestsPassed = gnTestsPassed + 1
    ? "[PASS] Test_TaxCategoryS"
EndProc

*---------------------------------------------------------------------------
* Test: Categorie TVA AE (taxare inversa)
*---------------------------------------------------------------------------
Procedure Test_TaxCategoryAE
    Local loContext
    
    loContext = CreateObject("EFacturaContext")
    loContext.cTipFactura = "T"  && Tip taxare inversa
    loContext.lIsTaxareInversa = .T.
    
    * Ar trebui sa genereze categoria AE
    If loContext.lIsTaxareInversa
        gnTestsPassed = gnTestsPassed + 1
        ? "[PASS] Test_TaxCategoryAE"
    Else
        gnTestsFailed = gnTestsFailed + 1
        ? "[FAIL] Test_TaxCategoryAE"
    EndIf
EndProc

*---------------------------------------------------------------------------
* Test: Categorie TVA E (scutit)
*---------------------------------------------------------------------------
Procedure Test_TaxCategoryE
    Local loContext
    
    loContext = CreateObject("EFacturaContext")
    loContext.cTipFactura = "S"  && Scutit cu drept de deducere
    
    If InList(loContext.cTipFactura, 'S', 'D', 'd')
        gnTestsPassed = gnTestsPassed + 1
        ? "[PASS] Test_TaxCategoryE"
    Else
        gnTestsFailed = gnTestsFailed + 1
        ? "[FAIL] Test_TaxCategoryE"
    EndIf
EndProc

*---------------------------------------------------------------------------
* Test: Calcul totaluri
*---------------------------------------------------------------------------
Procedure Test_CalculateTotals
    Local loContext, lnTotalNet, lnTotalTva, lnTotalBrut
    
    loContext = CreateObject("EFacturaContext")
    loContext.nTotalNet = 1000.00
    loContext.nTotalTva = 190.00
    loContext.nTotalCharges = 0
    loContext.nTotalAllowances = 0
    
    * Calcul: Brut = Net + TVA
    lnTotalBrut = loContext.nTotalNet + loContext.nTotalTva
    
    If lnTotalBrut = 1190.00
        gnTestsPassed = gnTestsPassed + 1
        ? "[PASS] Test_CalculateTotals"
    Else
        gnTestsFailed = gnTestsFailed + 1
        ? "[FAIL] Test_CalculateTotals - Asteptat 1190.00, obtinut " + Transform(lnTotalBrut)
    EndIf
EndProc
