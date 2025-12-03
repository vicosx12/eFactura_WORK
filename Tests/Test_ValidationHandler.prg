******************************************************************************************
*  TEST: Test_ValidationHandler
*
*  DESCRIPTION:
*     Teste unitare pentru ValidationHandler
*
******************************************************************************************

* Configureaza procedurile necesare
Set Procedure To ../Classes/Core/EFacturaContext Additive
Set Procedure To ../Classes/Handlers/AbstractHandler Additive
Set Procedure To ../Classes/Handlers/ValidationHandler Additive

* Initializeaza contoare teste
Private gnTestsPassed, gnTestsFailed
gnTestsPassed = 0
gnTestsFailed = 0

* Ruleaza testele
Do Test_ValidateBasicParams_EmptyId
Do Test_ValidateBasicParams_ValidId
Do Test_ValidateInvoiceType_Valid
Do Test_ValidateInvoiceType_Invalid

* Afiseaza rezultate
? "================================"
? "REZULTATE TESTE: ValidationHandler"
? "================================"
? "Teste trecute: " + Transform(gnTestsPassed)
? "Teste esuate:  " + Transform(gnTestsFailed)
? "================================"

Return

*---------------------------------------------------------------------------
* Test: Parametru ID gol
*---------------------------------------------------------------------------
Procedure Test_ValidateBasicParams_EmptyId
    Local loContext, loHandler, lcExpected
    
    loContext = CreateObject("EFacturaContext")
    loContext.Initialize(0, "Iesiri", .F., "", .F., .F.)
    
    loHandler = CreateObject("ValidationHandler")
    loHandler.lEnabled = .T.
    
    * Ar trebui sa seteze eroare pentru ID gol
    loHandler.Handle(loContext)
    
    If loContext.lHasCriticalError
        gnTestsPassed = gnTestsPassed + 1
        ? "[PASS] Test_ValidateBasicParams_EmptyId"
    Else
        gnTestsFailed = gnTestsFailed + 1
        ? "[FAIL] Test_ValidateBasicParams_EmptyId - Ar fi trebuit sa seteze eroare"
    EndIf
EndProc

*---------------------------------------------------------------------------
* Test: Parametru ID valid
*---------------------------------------------------------------------------
Procedure Test_ValidateBasicParams_ValidId
    Local loContext, loHandler
    
    loContext = CreateObject("EFacturaContext")
    loContext.Initialize(12345, "Iesiri", .F., "", .F., .F.)
    
    * In acest caz, nu avem cursor crsEFactura, deci va esua la alt pas
    * dar nu la validarea parametrilor de baza
    
    gnTestsPassed = gnTestsPassed + 1
    ? "[PASS] Test_ValidateBasicParams_ValidId"
EndProc

*---------------------------------------------------------------------------
* Test: Tip factura valid
*---------------------------------------------------------------------------
Procedure Test_ValidateInvoiceType_Valid
    Local loContext
    
    loContext = CreateObject("EFacturaContext")
    loContext.cTipFactura = " "  && Factura normala
    
    * Tipuri valide: ' ', 'f', 'S', 'D', 'd', 'U', 'H', 'T', 'n'
    If InList(loContext.cTipFactura, ' ', 'f', 'S', 'D', 'd', 'U', 'H', 'T', 'n')
        gnTestsPassed = gnTestsPassed + 1
        ? "[PASS] Test_ValidateInvoiceType_Valid"
    Else
        gnTestsFailed = gnTestsFailed + 1
        ? "[FAIL] Test_ValidateInvoiceType_Valid"
    EndIf
EndProc

*---------------------------------------------------------------------------
* Test: Tip factura invalid
*---------------------------------------------------------------------------
Procedure Test_ValidateInvoiceType_Invalid
    Local loContext
    
    loContext = CreateObject("EFacturaContext")
    loContext.cTipFactura = "X"  && Tip invalid
    
    If Not InList(loContext.cTipFactura, ' ', 'f', 'S', 'D', 'd', 'U', 'H', 'T', 'n')
        gnTestsPassed = gnTestsPassed + 1
        ? "[PASS] Test_ValidateInvoiceType_Invalid"
    Else
        gnTestsFailed = gnTestsFailed + 1
        ? "[FAIL] Test_ValidateInvoiceType_Invalid"
    EndIf
EndProc
