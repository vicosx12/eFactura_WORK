*====================================================================
* Program: Test_ConnectionPool.prg
* Scop: Test Suite pentru Connection Pool
* Data: 2024-12-23
*====================================================================

*====================================================================
* Procedură: RunAllTests
*====================================================================
PROCEDURE RunAllTests()
    LOCAL llSuccess
    
    ? "======================================="
    ? "CONNECTION POOL TEST SUITE"
    ? "======================================="
    ? ""
    
    llSuccess = .T.
    
    * Test 1: Creare Pool
    IF !Test_CreatePool()
        llSuccess = .F.
    ENDIF
    ? ""
    
    * Test 2: Get și Release Connection
    IF !Test_GetReleaseConnection()
        llSuccess = .F.
    ENDIF
    ? ""
    
    * Test 3: Conexiuni Multiple
    IF !Test_MultipleConnections()
        llSuccess = .F.
    ENDIF
    ? ""
    
    * Test 4: Performance Comparison
    IF !Test_PerformanceComparison()
        llSuccess = .F.
    ENDIF
    ? ""
    
    * Test 5: Validare Conexiuni
    IF !Test_ConnectionValidation()
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
* Test 1: Creare Pool
*====================================================================
PROCEDURE Test_CreatePool()
    LOCAL loPool, lcConnString, llSuccess
    
    ? "Test 1: Creare Connection Pool..."
    
    llSuccess = .T.
    
    TEXT TO lcConnString NOSHOW
    Driver=SQL Server Native Client 11.0;
    Database=SCUnicProdcomSRL;
    Server=localhost\ICAS_2019;
    UID=sa;
    PWD=016049
    ENDTEXT
    
    TRY
        SET PROCEDURE TO Modernization\Database\ConnectionPool.prg ADDITIVE
        loPool = CREATEOBJECT("ConnectionPool", lcConnString, 3)
        
        IF !ISNULL(loPool)
            ? "  ✓ Pool creat cu succes"
            ? "    Pool Size:", loPool.nPoolSize
        ELSE
            ? "  ✗ FAILED - Pool NULL"
            llSuccess = .F.
        ENDIF
        
        * Cleanup
        IF !ISNULL(loPool)
            loPool.CloseAll()
        ENDIF
        
    CATCH TO loEx
        ? "  ✗ FAILED - Excepție:", loEx.Message
        llSuccess = .F.
    ENDTRY
    
    RETURN llSuccess
ENDPROC

*====================================================================
* Test 2: Get și Release Connection
*====================================================================
PROCEDURE Test_GetReleaseConnection()
    LOCAL loPool, lcConnString, lnConn, llSuccess
    
    ? "Test 2: Get și Release Connection..."
    
    llSuccess = .T.
    
    TEXT TO lcConnString NOSHOW
    Driver=SQL Server Native Client 11.0;
    Database=SCUnicProdcomSRL;
    Server=localhost\ICAS_2019;
    UID=sa;
    PWD=016049
    ENDTEXT
    
    TRY
        loPool = CREATEOBJECT("ConnectionPool", lcConnString, 3)
        
        * Get connection
        lnConn = loPool.GetConnection()
        
        IF lnConn > 0
            ? "  ✓ Conexiune obținută - Handle:", lnConn
            
            * Test query
            LOCAL lnResult
            lnResult = SQLEXEC(lnConn, "SELECT 1 AS Test", "curTest")
            
            IF lnResult > 0
                ? "  ✓ Query executat cu succes"
                USE IN SELECT("curTest")
            ELSE
                ? "  ✗ FAILED - Query eșuat"
                llSuccess = .F.
            ENDIF
            
            * Release connection
            IF loPool.ReleaseConnection(lnConn)
                ? "  ✓ Conexiune eliberată"
            ELSE
                ? "  ✗ FAILED - Release eșuat"
                llSuccess = .F.
            ENDIF
        ELSE
            ? "  ✗ FAILED - Nu s-a putut obține conexiune"
            llSuccess = .F.
        ENDIF
        
        * Cleanup
        loPool.CloseAll()
        
    CATCH TO loEx
        ? "  ✗ FAILED - Excepție:", loEx.Message
        llSuccess = .F.
    ENDTRY
    
    RETURN llSuccess
ENDPROC

*====================================================================
* Test 3: Conexiuni Multiple
*====================================================================
PROCEDURE Test_MultipleConnections()
    LOCAL loPool, lcConnString, llSuccess
    LOCAL lnConn1, lnConn2, lnConn3
    
    ? "Test 3: Conexiuni Multiple..."
    
    llSuccess = .T.
    
    TEXT TO lcConnString NOSHOW
    Driver=SQL Server Native Client 11.0;
    Database=SCUnicProdcomSRL;
    Server=localhost\ICAS_2019;
    UID=sa;
    PWD=016049
    ENDTEXT
    
    TRY
        loPool = CREATEOBJECT("ConnectionPool", lcConnString, 3)
        
        * Obține 3 conexiuni
        lnConn1 = loPool.GetConnection()
        lnConn2 = loPool.GetConnection()
        lnConn3 = loPool.GetConnection()
        
        IF lnConn1 > 0 AND lnConn2 > 0 AND lnConn3 > 0
            ? "  ✓ 3 conexiuni obținute simultan"
            ? "    Handle 1:", lnConn1
            ? "    Handle 2:", lnConn2
            ? "    Handle 3:", lnConn3
            
            * Afișare status pool
            ? loPool.GetPoolStatus()
            
            * Eliberare
            loPool.ReleaseConnection(lnConn1)
            loPool.ReleaseConnection(lnConn2)
            loPool.ReleaseConnection(lnConn3)
            ? "  ✓ Toate conexiunile eliberate"
        ELSE
            ? "  ✗ FAILED - Nu s-au putut obține toate conexiunile"
            llSuccess = .F.
        ENDIF
        
        * Cleanup
        loPool.CloseAll()
        
    CATCH TO loEx
        ? "  ✗ FAILED - Excepție:", loEx.Message
        llSuccess = .F.
    ENDTRY
    
    RETURN llSuccess
ENDPROC

*====================================================================
* Test 4: Performance Comparison
*====================================================================
PROCEDURE Test_PerformanceComparison()
    LOCAL loPool, lcConnString, llSuccess
    LOCAL lnStart, lnDirectTime, lnPoolTime, i
    
    ? "Test 4: Performance Comparison (10 iterații)..."
    
    llSuccess = .T.
    
    TEXT TO lcConnString NOSHOW
    Driver=SQL Server Native Client 11.0;
    Database=SCUnicProdcomSRL;
    Server=localhost\ICAS_2019;
    UID=sa;
    PWD=016049
    ENDTEXT
    
    TRY
        * Test 1: Direct connections
        ? "  Testare conexiuni directe..."
        lnStart = SECONDS()
        
        FOR i = 1 TO 10
            LOCAL lnHandle
            lnHandle = SQLSTRINGCONNECT(lcConnString)
            IF lnHandle > 0
                SQLEXEC(lnHandle, "SELECT 1", "curTemp")
                USE IN SELECT("curTemp")
                SQLDISCONNECT(lnHandle)
            ENDIF
        ENDFOR
        
        lnDirectTime = SECONDS() - lnStart
        ? "    Timp direct:", TRANSFORM(lnDirectTime, "999.999"), "secunde"
        
        * Test 2: Pool connections
        ? "  Testare conexiuni pool..."
        loPool = CREATEOBJECT("ConnectionPool", lcConnString, 3)
        
        lnStart = SECONDS()
        
        FOR i = 1 TO 10
            LOCAL lnConn
            lnConn = loPool.GetConnection()
            IF lnConn > 0
                SQLEXEC(lnConn, "SELECT 1", "curTemp")
                USE IN SELECT("curTemp")
                loPool.ReleaseConnection(lnConn)
            ENDIF
        ENDFOR
        
        lnPoolTime = SECONDS() - lnStart
        ? "    Timp pool:", TRANSFORM(lnPoolTime, "999.999"), "secunde"
        
        * Calcul îmbunătățire
        LOCAL lnImprovement
        lnImprovement = ((lnDirectTime - lnPoolTime) / lnDirectTime) * 100
        
        ? ""
        ? "  ✓ Rezultate:"
        ? "    Îmbunătățire:", TRANSFORM(lnImprovement, "999.99"), "%"
        ? "    Timp salvat:", TRANSFORM(lnDirectTime - lnPoolTime, "999.999"), "secunde"
        
        * Cleanup
        loPool.CloseAll()
        
    CATCH TO loEx
        ? "  ✗ FAILED - Excepție:", loEx.Message
        llSuccess = .F.
    ENDTRY
    
    RETURN llSuccess
ENDPROC

*====================================================================
* Test 5: Validare Conexiuni
*====================================================================
PROCEDURE Test_ConnectionValidation()
    LOCAL loPool, lcConnString, lnConn, llSuccess
    
    ? "Test 5: Validare Conexiuni..."
    
    llSuccess = .T.
    
    TEXT TO lcConnString NOSHOW
    Driver=SQL Server Native Client 11.0;
    Database=SCUnicProdcomSRL;
    Server=localhost\ICAS_2019;
    UID=sa;
    PWD=016049
    ENDTEXT
    
    TRY
        loPool = CREATEOBJECT("ConnectionPool", lcConnString, 3)
        
        * Obține conexiune
        lnConn = loPool.GetConnection()
        
        IF lnConn > 0
            ? "  ✓ Conexiune obținută"
            
            * Validare
            IF loPool.IsConnectionValid(lnConn)
                ? "  ✓ Conexiune validă"
            ELSE
                ? "  ✗ FAILED - Conexiune invalidă"
                llSuccess = .F.
            ENDIF
            
            * Release
            loPool.ReleaseConnection(lnConn)
            
            * Obține aceeași conexiune din nou (ar trebui reutilizată)
            LOCAL lnConn2
            lnConn2 = loPool.GetConnection()
            
            IF lnConn2 = lnConn
                ? "  ✓ Conexiune reutilizată corect"
            ELSE
                ? "  ⚠ Conexiune nouă creată (handle diferit)"
            ENDIF
            
            loPool.ReleaseConnection(lnConn2)
        ELSE
            ? "  ✗ FAILED - Nu s-a putut obține conexiune"
            llSuccess = .F.
        ENDIF
        
        * Cleanup
        loPool.CloseAll()
        
    CATCH TO loEx
        ? "  ✗ FAILED - Excepție:", loEx.Message
        llSuccess = .F.
    ENDTRY
    
    RETURN llSuccess
ENDPROC

*====================================================================
* Main Entry Point
*====================================================================
IF PROGRAM() = "TEST_CONNECTIONPOOL"
    RunAllTests()
ENDIF
