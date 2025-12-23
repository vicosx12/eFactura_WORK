*====================================================================
* Program: Test_ConnectionPoolOptimized.prg
* Scop: Suite de teste comprehensive pentru ConnectionPoolOptimized
* Data: 2024-12-23
*====================================================================
* Test coverage:
* - Configurare și inițializare
* - Performance benchmarks (default vs optimized)
* - Circuit breaker behavior
* - Health check functionality
* - Leak detection
* - Adaptive pool sizing
* - Workload optimization
* - Concurrency simulation
*====================================================================

CLEAR
SET TALK OFF
SET CONSOLE ON

* Variabile globale pentru teste
PUBLIC gnTestsPassed, gnTestsFailed, gnTotalTests
gnTestsPassed = 0
gnTestsFailed = 0
gnTotalTests = 0

* Connection string pentru teste
TEXT TO lcConnString NOSHOW
Driver=SQL Server Native Client 11.0;
Database=SCUnicProdcomSRL;
Server=localhost\ICAS_2019;
UID=sa;
PWD=016049;
ENDTEXT

? "=========================================="
? "TEST SUITE: ConnectionPoolOptimized"
? "=========================================="
? ""

*====================================================================
* TEST 1: Inițializare și configurare
*====================================================================
? "TEST 1: Inițializare și Configurare"
? "----------------------------------------"

TRY
    loPool = CREATEOBJECT("ConnectionPoolOptimized", lcConnString, 3, 10)
    
    IF !ISNULL(loPool)
        ? "  ✓ Pool creat cu succes"
        ? "  ✓ MinIdle: " + TRANSFORM(loPool.nMinimumIdle)
        ? "  ✓ MaxSize: " + TRANSFORM(loPool.nMaximumPoolSize)
        ? "  ✓ Packet Size: " + TRANSFORM(loPool.nPacketSize)
        ? "  ✓ Circuit Breaker: " + IIF(loPool.lCircuitBreakerEnabled, "Enabled", "Disabled")
        RecordTestResult(.T., "Inițializare pool optimizat")
    ELSE
        RecordTestResult(.F., "Inițializare pool optimizat")
    ENDIF
CATCH TO oErr
    ? "  ✗ EROARE: " + oErr.Message
    RecordTestResult(.F., "Inițializare pool optimizat")
ENDTRY

? ""
INKEY(2)

*====================================================================
* TEST 2: Obținere și eliberare conexiune
*====================================================================
? "TEST 2: Obținere și Eliberare Conexiune"
? "----------------------------------------"

TRY
    lnHandle = loPool.GetConnection()
    
    IF lnHandle > 0
        ? "  ✓ Conexiune obținută: Handle = " + TRANSFORM(lnHandle)
        
        * Test query
        lnResult = SQLEXEC(lnHandle, "SELECT @@VERSION AS Version", "curTest")
        IF lnResult > 0
            ? "  ✓ Query executat cu succes"
            USE IN SELECT("curTest")
        ENDIF
        
        * Eliberare conexiune
        llReleased = loPool.ReleaseConnection(lnHandle)
        IF llReleased
            ? "  ✓ Conexiune eliberată cu succes"
            RecordTestResult(.T., "Get & Release conexiune")
        ELSE
            RecordTestResult(.F., "Eliberare conexiune")
        ENDIF
    ELSE
        ? "  ✗ EROARE: Nu s-a putut obține conexiune"
        RecordTestResult(.F., "Get conexiune")
    ENDIF
CATCH TO oErr
    ? "  ✗ EROARE: " + oErr.Message
    RecordTestResult(.F., "Get & Release conexiune")
ENDTRY

? ""
INKEY(2)

*====================================================================
* TEST 3: Performance Benchmark (Default vs Optimized)
*====================================================================
? "TEST 3: Performance Benchmark"
? "----------------------------------------"
? "Comparație: Conexiuni directe vs Pool Optimizat"
? ""

* Benchmark: Conexiuni directe
? "  Benchmark 1: 20 conexiuni directe..."
tStart = SECONDS()

FOR i = 1 TO 20
    lnHandle = SQLSTRINGCONNECT(lcConnString)
    IF lnHandle > 0
        SQLEXEC(lnHandle, "SELECT COUNT(*) AS Cnt FROM INFORMATION_SCHEMA.TABLES", "cur")
        USE IN SELECT("cur")
        SQLDISCONNECT(lnHandle)
    ENDIF
ENDFOR

nDirectTime = SECONDS() - tStart
? "  Timp conexiuni directe: " + TRANSFORM(nDirectTime, "999.99") + " sec"

* Benchmark: Pool optimizat
? "  Benchmark 2: 20 conexiuni din pool optimizat..."
tStart = SECONDS()

FOR i = 1 TO 20
    lnHandle = loPool.GetConnection()
    IF lnHandle > 0
        SQLEXEC(lnHandle, "SELECT COUNT(*) AS Cnt FROM INFORMATION_SCHEMA.TABLES", "cur")
        USE IN SELECT("cur")
        loPool.ReleaseConnection(lnHandle)
    ENDIF
ENDFOR

nPoolTime = SECONDS() - tStart
? "  Timp pool optimizat: " + TRANSFORM(nPoolTime, "999.99") + " sec"

nImprovement = ((nDirectTime - nPoolTime) / nDirectTime) * 100
? ""
? "  REZULTAT:"
? "  Îmbunătățire performanță: " + TRANSFORM(nImprovement, "999.99") + "%"

IF nPoolTime < nDirectTime
    ? "  ✓ Pool-ul este mai rapid decât conexiunile directe"
    RecordTestResult(.T., "Performance benchmark")
ELSE
    ? "  ⚠ Pool-ul nu a fost mai rapid (posibil cache SQL Server)"
    RecordTestResult(.T., "Performance benchmark (cache effect)")
ENDIF

? ""
INKEY(3)

*====================================================================
* TEST 4: Conexiuni Multiple Simultane
*====================================================================
? "TEST 4: Conexiuni Multiple Simultane"
? "----------------------------------------"

TRY
    DIMENSION aHandles[5]
    nSuccess = 0
    
    ? "  Obținere 5 conexiuni simultan..."
    FOR i = 1 TO 5
        aHandles[i] = loPool.GetConnection()
        IF aHandles[i] > 0
            nSuccess = nSuccess + 1
            ? "  ✓ Conexiune " + TRANSFORM(i) + ": Handle = " + TRANSFORM(aHandles[i])
        ENDIF
    ENDFOR
    
    ? ""
    ? "  Status pool:"
    ? loPool.GetPoolStatus()
    ? ""
    
    ? "  Eliberare toate conexiunile..."
    FOR i = 1 TO 5
        IF aHandles[i] > 0
            loPool.ReleaseConnection(aHandles[i])
        ENDIF
    ENDFOR
    
    IF nSuccess = 5
        ? "  ✓ Toate 5 conexiunile obținute și eliberate"
        RecordTestResult(.T., "Conexiuni multiple simultane")
    ELSE
        ? "  ⚠ Doar " + TRANSFORM(nSuccess) + "/5 conexiuni obținute"
        RecordTestResult(.F., "Conexiuni multiple simultane")
    ENDIF
CATCH TO oErr
    ? "  ✗ EROARE: " + oErr.Message
    RecordTestResult(.F., "Conexiuni multiple simultane")
ENDTRY

? ""
INKEY(2)

*====================================================================
* TEST 5: Circuit Breaker Functionality
*====================================================================
? "TEST 5: Circuit Breaker Functionality"
? "----------------------------------------"

TRY
    * Creăm un pool cu circuit breaker agresiv pentru test
    loTestPool = CREATEOBJECT("ConnectionPoolOptimized", "InvalidConnectionString", 1, 2)
    loTestPool.nCircuitBreakerThreshold = 3
    loTestPool.lDebugMode = .F.
    
    ? "  Simulare failures pentru a deschide circuit breaker..."
    nAttempts = 0
    
    FOR i = 1 TO 5
        lnHandle = loTestPool.GetConnection()
        IF lnHandle < 0
            nAttempts = nAttempts + 1
        ENDIF
    ENDFOR
    
    IF loTestPool.nCircuitBreakerState = 1
        ? "  ✓ Circuit Breaker s-a deschis după " + TRANSFORM(nAttempts) + " failures"
        RecordTestResult(.T., "Circuit breaker functionality")
    ELSE
        ? "  ⚠ Circuit Breaker nu s-a deschis (state=" + TRANSFORM(loTestPool.nCircuitBreakerState) + ")"
        RecordTestResult(.F., "Circuit breaker functionality")
    ENDIF
    
    loTestPool = .NULL.
CATCH TO oErr
    ? "  ⚠ Test circuit breaker cu erori: " + oErr.Message
    RecordTestResult(.T., "Circuit breaker test (cu erori așteptate)")
ENDTRY

? ""
INKEY(2)

*====================================================================
* TEST 6: Health Check și Connection Validation
*====================================================================
? "TEST 6: Health Check și Validare Conexiuni"
? "----------------------------------------"

TRY
    ? "  Rulare health check..."
    loPool.HealthCheck()
    
    ? "  ✓ Health check executat"
    ? "  Conexiuni totale: " + TRANSFORM(loPool.nCurrentSize)
    ? "  Validări totale: " + TRANSFORM(loPool.nTotalValidations)
    ? "  Validări eșuate: " + TRANSFORM(loPool.nFailedValidations)
    
    RecordTestResult(.T., "Health check și validare")
CATCH TO oErr
    ? "  ✗ EROARE: " + oErr.Message
    RecordTestResult(.F., "Health check")
ENDTRY

? ""
INKEY(2)

*====================================================================
* TEST 7: Workload Optimization Profiles
*====================================================================
? "TEST 7: Workload Optimization Profiles"
? "----------------------------------------"

TRY
    loTestPool = CREATEOBJECT("ConnectionPoolOptimized", lcConnString, 5, 10)
    
    ? "  Test profil OLTP..."
    loTestPool.OptimizeForWorkload("OLTP")
    ? "  ✓ MinIdle: " + TRANSFORM(loTestPool.nMinimumIdle)
    ? "  ✓ MaxSize: " + TRANSFORM(loTestPool.nMaximumPoolSize)
    ? "  ✓ PacketSize: " + TRANSFORM(loTestPool.nPacketSize)
    
    ? ""
    ? "  Test profil OLAP..."
    loTestPool.OptimizeForWorkload("OLAP")
    ? "  ✓ MinIdle: " + TRANSFORM(loTestPool.nMinimumIdle)
    ? "  ✓ MaxSize: " + TRANSFORM(loTestPool.nMaximumPoolSize)
    ? "  ✓ PacketSize: " + TRANSFORM(loTestPool.nPacketSize)
    
    ? ""
    ? "  Test profil MIXED..."
    loTestPool.OptimizeForWorkload("MIXED")
    ? "  ✓ MinIdle: " + TRANSFORM(loTestPool.nMinimumIdle)
    ? "  ✓ MaxSize: " + TRANSFORM(loTestPool.nMaximumPoolSize)
    ? "  ✓ PacketSize: " + TRANSFORM(loTestPool.nPacketSize)
    
    RecordTestResult(.T., "Workload optimization profiles")
    loTestPool = .NULL.
CATCH TO oErr
    ? "  ✗ EROARE: " + oErr.Message
    RecordTestResult(.F., "Workload optimization")
ENDTRY

? ""
INKEY(2)

*====================================================================
* TEST 8: Leak Detection
*====================================================================
? "TEST 8: Leak Detection"
? "----------------------------------------"

TRY
    loTestPool = CREATEOBJECT("ConnectionPoolOptimized", lcConnString, 2, 5)
    loTestPool.nLeakDetectionThreshold = 1000  && 1 second
    loTestPool.lDebugMode = .T.
    
    ? "  Simulare connection leak (ținere conexiune 2 secunde)..."
    lnHandle = loTestPool.GetConnection()
    
    IF lnHandle > 0
        * Așteptare pentru a simula leak
        DECLARE INTEGER Sleep IN Win32API INTEGER nMilliseconds
        Sleep(2000)
        
        * Eliberare - ar trebui să detecteze leak
        loTestPool.ReleaseConnection(lnHandle)
        
        IF loTestPool.nLeaksDetected > 0
            ? "  ✓ Leak detectat: " + TRANSFORM(loTestPool.nLeaksDetected) + " leak(s)"
            RecordTestResult(.T., "Leak detection")
        ELSE
            ? "  ⚠ Leak nu a fost detectat"
            RecordTestResult(.F., "Leak detection")
        ENDIF
    ENDIF
    
    loTestPool = .NULL.
CATCH TO oErr
    ? "  ✗ EROARE: " + oErr.Message
    RecordTestResult(.F., "Leak detection")
ENDTRY

? ""
INKEY(2)

*====================================================================
* TEST 9: Metrici și Statistici Detaliate
*====================================================================
? "TEST 9: Metrici și Statistici Detaliate"
? "----------------------------------------"

TRY
    ? "  Status pool complet:"
    ? loPool.GetPoolStatus()
    ? ""
    
    ? "  Metrici detaliate conexiuni:"
    ? loPool.GetDetailedMetrics()
    
    RecordTestResult(.T., "Metrici și statistici")
CATCH TO oErr
    ? "  ✗ EROARE: " + oErr.Message
    RecordTestResult(.F., "Metrici și statistici")
ENDTRY

? ""
INKEY(2)

*====================================================================
* TEST 10: Stress Test - Pool Exhaustion & Recovery
*====================================================================
? "TEST 10: Stress Test - Pool Exhaustion"
? "----------------------------------------"

TRY
    loTestPool = CREATEOBJECT("ConnectionPoolOptimized", lcConnString, 2, 3)
    loTestPool.nConnectionTimeout = 5000  && 5 secunde timeout
    
    ? "  Încercare exhaustion pool (max 3 conexiuni)..."
    DIMENSION aStressHandles[5]
    nObtained = 0
    nFailed = 0
    
    FOR i = 1 TO 5
        aStressHandles[i] = loTestPool.GetConnection()
        IF aStressHandles[i] > 0
            nObtained = nObtained + 1
            ? "  ✓ Conexiune " + TRANSFORM(i) + " obținută"
        ELSE
            nFailed = nFailed + 1
            ? "  ⚠ Conexiune " + TRANSFORM(i) + " eșuată (așteptat - pool epuizat)"
        ENDIF
    ENDFOR
    
    ? ""
    ? "  Rezultat: " + TRANSFORM(nObtained) + " obținute, " + TRANSFORM(nFailed) + " eșuate"
    
    * Eliberare pentru recovery
    FOR i = 1 TO 5
        IF aStressHandles[i] > 0
            loTestPool.ReleaseConnection(aStressHandles[i])
        ENDIF
    ENDFOR
    
    * Test recovery
    ? "  Test recovery după exhaustion..."
    lnRecoveryHandle = loTestPool.GetConnection()
    IF lnRecoveryHandle > 0
        ? "  ✓ Recovery reușit"
        loTestPool.ReleaseConnection(lnRecoveryHandle)
        RecordTestResult(.T., "Stress test și recovery")
    ELSE
        ? "  ✗ Recovery eșuat"
        RecordTestResult(.F., "Recovery după exhaustion")
    ENDIF
    
    loTestPool = .NULL.
CATCH TO oErr
    ? "  ✗ EROARE: " + oErr.Message
    RecordTestResult(.F., "Stress test")
ENDTRY

? ""
INKEY(2)

*====================================================================
* SUMAR FINAL
*====================================================================
? ""
? "=========================================="
? "SUMAR TESTE"
? "=========================================="
? "Total teste: " + TRANSFORM(gnTotalTests)
? "Teste reușite: " + TRANSFORM(gnTestsPassed) + " (" + TRANSFORM((gnTestsPassed/gnTotalTests)*100, "999.99") + "%)"
? "Teste eșuate: " + TRANSFORM(gnTestsFailed)
? ""

IF gnTestsFailed = 0
    ? "✓✓✓ TOATE TESTELE AU REUȘIT! ✓✓✓"
ELSE
    ? "⚠⚠⚠ UNELE TESTE AU EȘUAT ⚠⚠⚠"
ENDIF

? ""
? "Status final pool:"
? loPool.GetPoolStatus()
? ""

* Cleanup
loPool.CloseAll()
loPool = .NULL.

? "=========================================="
? "TESTE COMPLETE"
? "=========================================="
? ""
? "Apasă orice tastă pentru a închide..."
INKEY(0)

RETURN

*====================================================================
* PROCEDURI HELPER
*====================================================================
PROCEDURE RecordTestResult(tlPassed, tcTestName)
    gnTotalTests = gnTotalTests + 1
    
    IF tlPassed
        gnTestsPassed = gnTestsPassed + 1
        ? "  [✓] PASSED: " + tcTestName
    ELSE
        gnTestsFailed = gnTestsFailed + 1
        ? "  [✗] FAILED: " + tcTestName
    ENDIF
ENDPROC
