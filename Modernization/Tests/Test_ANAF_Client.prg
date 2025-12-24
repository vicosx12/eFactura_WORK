*====================================================================
* Program: Test_ANAF_Client.prg
* Scop: Test Suite pentru ANAF Client
* Data: 2024-12-23
*====================================================================

*====================================================================
* Procedură: RunAllTests
*====================================================================
PROCEDURE RunAllTests()
    LOCAL llSuccess
    
    ? "======================================="
    ? "ANAF CLIENT TEST SUITE"
    ? "======================================="
    ? ""
    
    llSuccess = .T.
    
    * Test 1: Creare Client
    IF !Test_CreateClient()
        llSuccess = .F.
    ENDIF
    ? ""
    
    * Test 2: Load Credentials
    IF !Test_LoadCredentials()
        llSuccess = .F.
    ENDIF
    ? ""
    
    * Test 3: Get Access Token
    IF !Test_GetAccessToken()
        llSuccess = .F.
    ENDIF
    ? ""
    
    * Test 4: Get Messages List
    IF !Test_GetMessagesList()
        llSuccess = .F.
    ENDIF
    ? ""
    
    * Rezultat final
    ? "======================================="
    IF llSuccess
        ? "✓ TOATE TESTELE AU TRECUT"
    ELSE
        ? "✗ UNELE TESTE AU EȘUAT"
    ENDIF
    ? "======================================="
    
    RETURN llSuccess
ENDPROC

*====================================================================
* Test 1: Creare Client
*====================================================================
PROCEDURE Test_CreateClient()
    LOCAL loClient, llSuccess
    
    ? "Test 1: Creare ANAF Client..."
    
    llSuccess = .T.
    
    TRY
        SET PROCEDURE TO Modernization\API\ANAF_Client.prg ADDITIVE
        loClient = CREATEOBJECT("ANAFClient", .T.)  && Test environment
        
        IF !ISNULL(loClient)
            ? "  ✓ Client creat cu succes"
            ? "    Test URL:", loClient.cTestURL
            ? "    Token URL:", loClient.cTokenURL
        ELSE
            ? "  ✗ FAILED - Client NULL"
            llSuccess = .F.
        ENDIF
        
    CATCH TO loEx
        ? "  ✗ FAILED - Excepție:", loEx.Message
        llSuccess = .F.
    ENDTRY
    
    RETURN llSuccess
ENDPROC

*====================================================================
* Test 2: Load Credentials
*====================================================================
PROCEDURE Test_LoadCredentials()
    LOCAL loClient, llSuccess
    
    ? "Test 2: Load Credentials..."
    
    llSuccess = .T.
    
    TRY
        * Notă: Acest test necesită ICAS.oSettings să existe
        IF TYPE('ICAS.oSettings') != 'O'
            ? "  ⚠ SKIPPED - ICAS.oSettings nu există (test manual necesar)"
            RETURN .T.
        ENDIF
        
        loClient = CREATEOBJECT("ANAFClient", .T.)
        
        IF !ISNULL(loClient)
            IF !EMPTY(loClient.cClientID) AND !EMPTY(loClient.cClientSecret)
                ? "  ✓ Credențiale încărcate"
                ? "    Client ID (primele 10 char):", LEFT(loClient.cClientID, 10) + "..."
            ELSE
                ? "  ✗ FAILED - Credențiale goale"
                llSuccess = .F.
            ENDIF
        ELSE
            ? "  ✗ FAILED - Client NULL"
            llSuccess = .F.
        ENDIF
        
    CATCH TO loEx
        ? "  ✗ FAILED - Excepție:", loEx.Message
        llSuccess = .F.
    ENDTRY
    
    RETURN llSuccess
ENDPROC

*====================================================================
* Test 3: Get Access Token
*====================================================================
PROCEDURE Test_GetAccessToken()
    LOCAL loClient, lcToken, llSuccess
    
    ? "Test 3: Get Access Token..."
    
    llSuccess = .T.
    
    TRY
        IF TYPE('ICAS.oSettings') != 'O'
            ? "  ⚠ SKIPPED - ICAS.oSettings nu există"
            RETURN .T.
        ENDIF
        
        loClient = CREATEOBJECT("ANAFClient", .T.)
        
        IF !ISNULL(loClient)
            ? "  Obținere token de la ANAF..."
            lcToken = loClient.GetAccessToken()
            
            IF !EMPTY(lcToken)
                ? "  ✓ Token obținut cu succes"
                ? "    Token (primele 20 char):", LEFT(lcToken, 20) + "..."
                ? "    Token expiry:", TTOC(loClient.dTokenExpiry)
            ELSE
                ? "  ✗ FAILED - Token gol"
                llSuccess = .F.
            ENDIF
        ELSE
            ? "  ✗ FAILED - Client NULL"
            llSuccess = .F.
        ENDIF
        
    CATCH TO loEx
        ? "  ✗ FAILED - Excepție:", loEx.Message
        llSuccess = .F.
    ENDTRY
    
    RETURN llSuccess
ENDPROC

*====================================================================
* Test 4: Get Messages List
*====================================================================
PROCEDURE Test_GetMessagesList()
    LOCAL loClient, lcResponse, llSuccess
    
    ? "Test 4: Get Messages List..."
    
    llSuccess = .T.
    
    TRY
        IF TYPE('ICAS.oSettings') != 'O'
            ? "  ⚠ SKIPPED - ICAS.oSettings nu există"
            RETURN .T.
        ENDIF
        
        loClient = CREATEOBJECT("ANAFClient", .T.)
        
        IF !ISNULL(loClient)
            ? "  Obținere listă mesaje (ultimele 7 zile)..."
            lcResponse = loClient.GetMessagesList(7)
            
            IF !ISNULL(lcResponse)
                ? "  ✓ Listă mesaje obținută"
                ? "    Response length:", LEN(lcResponse), "bytes"
                ? "    Primele 100 caractere:"
                ? "    " + LEFT(lcResponse, 100)
            ELSE
                ? "  ✗ FAILED - Response NULL"
                llSuccess = .F.
            ENDIF
        ELSE
            ? "  ✗ FAILED - Client NULL"
            llSuccess = .F.
        ENDIF
        
    CATCH TO loEx
        ? "  ✗ FAILED - Excepție:", loEx.Message
        llSuccess = .F.
    ENDTRY
    
    RETURN llSuccess
ENDPROC

*====================================================================
* Main Entry Point
*====================================================================
IF PROGRAM() = "TEST_ANAF_CLIENT"
    RunAllTests()
ENDIF
