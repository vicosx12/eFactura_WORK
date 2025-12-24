*====================================================================
* Program: ConnectionPoolOptimized.prg
* Scop: Pool de conexiuni optimizat inspirat de HikariCP
* Data: 2024-12-23
* Autor: Modernizare VFP 9.0
* Versiune: 2.0 - Production-Grade Optimized
*====================================================================
* Caracteristici avansate:
* - Configurare dinamică inspirată HikariCP
* - Monitoring performanță în timp real
* - Connection leak detection
* - Health check automat
* - Circuit breaker pattern
* - Adaptive pool sizing
* - Connection lifetime management
* - Statistici comprehensive
*====================================================================

*====================================================================
* DEFINE CLASS: ConnectionPoolOptimized
* Pool de conexiuni de înaltă performanță pentru SQL Server
*====================================================================
DEFINE CLASS ConnectionPoolOptimized AS Custom
    *================================================================
    * PROPRIETĂȚI POOL
    *================================================================
    DIMENSION aConnections[1, 10]  && Initialize as 2D array, will be redimensioned in Init
    
    * Core Configuration (HikariCP inspired)
    nMinimumIdle = 5                && Minim conexiuni idle (HikariCP: minimumIdle)
    nMaximumPoolSize = 10           && Maxim conexiuni în pool (HikariCP: maximumPoolSize)
    nConnectionTimeout = 30000      && Timeout conexiune nouă (ms) (HikariCP: connectionTimeout)
    nIdleTimeout = 600000           && Timeout conexiune idle (ms) - 10 min (HikariCP: idleTimeout)
    nMaxLifetime = 1800000          && Viață maximă conexiune (ms) - 30 min (HikariCP: maxLifetime)
    nValidationTimeout = 5000       && Timeout validare conexiune (ms)
    nLeakDetectionThreshold = 0     && 0 = disabled, >0 = ms pentru leak warning
    
    * Advanced Configuration
    lAutoCommit = .T.               && Auto-commit mode
    lReadOnly = .F.                 && Read-only mode
    nIsolationLevel = 2             && Transaction isolation (1=ReadUncommitted, 2=ReadCommitted, 3=RepeatableRead, 4=Serializable)
    
    * SQL Server Optimization
    nPacketSize = 16384             && Packet size (8192, 16384, 32768) - optimal: 16384
    nQueryTimeout = 30              && Query timeout (seconds)
    nConnectionRetryCount = 3       && Connection retry attempts
    nConnectionRetryInterval = 1    && Retry interval (seconds)
    lBatchMode = .T.                && Batch mode pentru performanță
    lAsynchronousProcessing = .F.   && Async processing
    lMultipleActiveResultSets = .F. && MARS (Multiple Active Result Sets)
    
    * Pool Management
    cConnectionString = ""
    nCurrentSize = 0                && Număr curent de conexiuni create
    nActiveConnections = 0          && Număr conexiuni în uz
    lShutdown = .F.                 && Flag pentru shutdown
    
    * Health Check & Monitoring
    lHealthCheckEnabled = .T.       && Enable health check
    nHealthCheckInterval = 30000    && Health check interval (ms)
    tLastHealthCheck = NULL         && Timestamp ultimul health check
    
    * Performance Metrics
    nTotalConnections = 0           && Total conexiuni create
    nTotalAcquisitions = 0          && Total achiziții conexiuni
    nTotalReleases = 0              && Total eliberări conexiuni
    nTotalValidations = 0           && Total validări
    nFailedAcquisitions = 0         && Achiziții eșuate
    nFailedValidations = 0          && Validări eșuate
    nConnectionTimeouts = 0         && Timeout-uri
    nLeaksDetected = 0              && Connection leaks detectate
    
    * Timing Statistics
    nTotalAcquisitionTime = 0       && Timp total achiziție (ms)
    nTotalValidationTime = 0        && Timp total validare (ms)
    nMaxAcquisitionTime = 0         && Timp maxim achiziție (ms)
    nMinAcquisitionTime = 999999    && Timp minim achiziție (ms)
    
    * Circuit Breaker
    lCircuitBreakerEnabled = .T.    && Enable circuit breaker
    nCircuitBreakerThreshold = 5    && Failures până la open
    nCircuitBreakerTimeout = 60000  && Timeout până la half-open (ms)
    nCircuitBreakerFailures = 0     && Failures curente
    nCircuitBreakerState = 0        && 0=Closed, 1=Open, 2=Half-Open
    tCircuitBreakerOpenTime = NULL  && Când s-a deschis
    
    * Logging & Debug
    lDebugMode = .F.
    lMetricsEnabled = .T.
    cLogFile = ""
    cMetricsFile = ""
    
    *================================================================
    * Metodă: Init
    *================================================================
    PROCEDURE Init(tcConnectionString, tnMinIdle, tnMaxSize)
        LOCAL i
        
        IF !EMPTY(tcConnectionString)
            THIS.cConnectionString = tcConnectionString
        ENDIF
        
        IF !EMPTY(tnMinIdle) AND tnMinIdle > 0
            THIS.nMinimumIdle = tnMinIdle
        ENDIF
        
        IF !EMPTY(tnMaxSize) AND tnMaxSize >= THIS.nMinimumIdle
            THIS.nMaximumPoolSize = tnMaxSize
        ENDIF
        
        * Validare configurație
        IF THIS.nMinimumIdle > THIS.nMaximumPoolSize
            THIS.nMinimumIdle = THIS.nMaximumPoolSize
        ENDIF
        
        * Inițializare array conexiuni
        DIMENSION THIS.aConnections[THIS.nMaximumPoolSize, 10]
        * Col 1: Connection Handle
        * Col 2: In Use (logical)
        * Col 3: Created Time (datetime)
        * Col 4: Last Used (datetime)
        * Col 5: Total Uses (integer)
        * Col 6: Last Validation (datetime)
        * Col 7: Acquisition Time (datetime) - pentru leak detection
        * Col 8: Thread ID (pentru leak detection)
        * Col 9: Validation Failures (integer)
        * Col 10: Is Valid (logical)
        
        FOR i = 1 TO THIS.nMaximumPoolSize
            THIS.aConnections[i, 1] = .NULL.
            THIS.aConnections[i, 2] = .F.
            THIS.aConnections[i, 3] = .NULL.  && Consistent .NULL. usage
            THIS.aConnections[i, 4] = .NULL.  && Consistent .NULL. usage
            THIS.aConnections[i, 5] = 0
            THIS.aConnections[i, 6] = .NULL.  && Consistent .NULL. usage
            THIS.aConnections[i, 7] = .NULL.  && Consistent .NULL. usage
            THIS.aConnections[i, 8] = ""
            THIS.aConnections[i, 9] = 0
            THIS.aConnections[i, 10] = .F.
        ENDFOR
        
        * Setup log files
        THIS.cLogFile = ADDBS(SYS(5)+SYS(2003)) + "ConnectionPool_" + DTOS(DATE()) + ".log"
        THIS.cMetricsFile = ADDBS(SYS(5)+SYS(2003)) + "ConnectionPool_Metrics_" + DTOS(DATE()) + ".csv"
        
        * Inițializare metrici CSV header
        IF THIS.lMetricsEnabled AND !FILE(THIS.cMetricsFile)
            THIS.WriteMetricsHeader()
        ENDIF
        
        * Pre-populate pool cu minimum idle connections
        THIS.FillPool(THIS.nMinimumIdle)
        
        IF THIS.lDebugMode
            THIS.LogMessage("ConnectionPoolOptimized inițializat")
            THIS.LogMessage("Config: MinIdle=" + TRANSFORM(THIS.nMinimumIdle) + ;
                           ", MaxSize=" + TRANSFORM(THIS.nMaximumPoolSize))
        ENDIF
        
        RETURN .T.
    ENDPROC
    
    *================================================================
    * Metodă: GetConnection
    * Returnează o conexiune din pool sau creează una nouă
    *================================================================
    PROCEDURE GetConnection()
        LOCAL lnHandle, i, llFound, lnAttempt, tStart, tEnd, nElapsed
        LOCAL lcThreadID
        
        * Verificare circuit breaker
        IF THIS.lCircuitBreakerEnabled
            IF !THIS.CheckCircuitBreaker()
                THIS.LogMessage("Circuit Breaker OPEN - conexiuni refuzate")
                RETURN -1
            ENDIF
        ENDIF
        
        tStart = DATETIME()
        llFound = .F.
        lnAttempt = 0
        lcThreadID = SYS(0)
        
        * Incrementare metrici
        THIS.nTotalAcquisitions = THIS.nTotalAcquisitions + 1
        
        * Timeout în milisecunde
        nTimeoutMs = THIS.nConnectionTimeout
        
        DO WHILE !llFound AND (DATETIME() - tStart) * 86400000 < nTimeoutMs
            lnAttempt = lnAttempt + 1
            
            * 1. Căutare conexiune idle validă
            FOR i = 1 TO THIS.nMaximumPoolSize
                IF !THIS.aConnections[i, 2] AND !ISNULL(THIS.aConnections[i, 1])
                    * Verificare vârstă conexiune
                    IF THIS.IsConnectionExpired(i)
                        THIS.CloseConnection(i)
                        LOOP
                    ENDIF
                    
                    * Validare conexiune
                    IF THIS.ValidateConnection(i)
                        lnHandle = THIS.aConnections[i, 1]
                        THIS.AcquireConnection(i, lcThreadID)
                        llFound = .T.
                        
                        IF THIS.lDebugMode
                            THIS.LogMessage("Reutilizare Handle: " + TRANSFORM(lnHandle) + " Slot: " + TRANSFORM(i))
                        ENDIF
                        
                        EXIT
                    ELSE
                        * Conexiune invalidă - închidere și recreare
                        THIS.CloseConnection(i)
                    ENDIF
                ENDIF
            ENDFOR
            
            IF llFound
                EXIT
            ENDIF
            
            * 2. Creare conexiune nouă dacă pool-ul nu e plin
            IF THIS.nCurrentSize < THIS.nMaximumPoolSize
                FOR i = 1 TO THIS.nMaximumPoolSize
                    IF ISNULL(THIS.aConnections[i, 1])
                        lnHandle = THIS.CreateNewConnection()
                        
                        IF lnHandle > 0
                            THIS.aConnections[i, 1] = lnHandle
                            THIS.aConnections[i, 3] = DATETIME()
                            THIS.AcquireConnection(i, lcThreadID)
                            THIS.nCurrentSize = THIS.nCurrentSize + 1
                            THIS.nTotalConnections = THIS.nTotalConnections + 1
                            llFound = .T.
                            
                            * Circuit breaker - reset pe success
                            IF THIS.lCircuitBreakerEnabled
                                THIS.nCircuitBreakerFailures = 0
                            ENDIF
                            
                            IF THIS.lDebugMode
                                THIS.LogMessage("Conexiune nouă Handle: " + TRANSFORM(lnHandle) + " Slot: " + TRANSFORM(i))
                            ENDIF
                            
                            EXIT
                        ELSE
                            * Circuit breaker - increment pe failure
                            IF THIS.lCircuitBreakerEnabled
                                THIS.RecordCircuitBreakerFailure()
                            ENDIF
                        ENDIF
                    ENDIF
                ENDFOR
            ENDIF
            
            IF !llFound
                * Wait before retry
                DECLARE INTEGER Sleep IN Win32API INTEGER nMilliseconds
                Sleep(100)
            ENDIF
        ENDDO
        
        tEnd = DATETIME()
        nElapsed = (tEnd - tStart) * 86400000  && Convert to milliseconds
        
        * Update timing statistics
        THIS.nTotalAcquisitionTime = THIS.nTotalAcquisitionTime + nElapsed
        THIS.nMaxAcquisitionTime = MAX(THIS.nMaxAcquisitionTime, nElapsed)
        THIS.nMinAcquisitionTime = MIN(THIS.nMinAcquisitionTime, nElapsed)
        
        IF !llFound
            THIS.nFailedAcquisitions = THIS.nFailedAcquisitions + 1
            THIS.nConnectionTimeouts = THIS.nConnectionTimeouts + 1
            THIS.LogMessage("TIMEOUT: Pool epuizat după " + TRANSFORM(nElapsed) + "ms")
            RETURN -1
        ENDIF
        
        * Log metrics
        IF THIS.lMetricsEnabled
            THIS.LogMetrics("ACQUIRE", nElapsed)
        ENDIF
        
        RETURN lnHandle
    ENDPROC
    
    *================================================================
    * Metodă: ReleaseConnection
    * Returnează conexiune în pool
    *================================================================
    PROCEDURE ReleaseConnection(tnHandle)
        LOCAL i, nHoldTime
        
        THIS.nTotalReleases = THIS.nTotalReleases + 1
        
        FOR i = 1 TO THIS.nMaximumPoolSize
            IF THIS.aConnections[i, 1] = tnHandle
                * Verificare leak detection
                IF THIS.nLeakDetectionThreshold > 0 AND !ISNULL(THIS.aConnections[i, 7])
                    nHoldTime = (DATETIME() - THIS.aConnections[i, 7]) * 86400000
                    IF nHoldTime > THIS.nLeakDetectionThreshold
                        THIS.nLeaksDetected = THIS.nLeaksDetected + 1
                        THIS.LogMessage("LEAK WARNING: Handle " + TRANSFORM(tnHandle) + ;
                                      " ținut " + TRANSFORM(nHoldTime) + "ms (Thread: " + ;
                                      THIS.aConnections[i, 8] + ")")
                    ENDIF
                ENDIF
                
                THIS.aConnections[i, 2] = .F.
                THIS.aConnections[i, 4] = DATETIME()
                THIS.aConnections[i, 7] = NULL
                THIS.aConnections[i, 8] = ""
                THIS.nActiveConnections = THIS.nActiveConnections - 1
                
                IF THIS.lDebugMode
                    THIS.LogMessage("Eliberare Handle: " + TRANSFORM(tnHandle))
                ENDIF
                
                RETURN .T.
            ENDIF
        ENDFOR
        
        THIS.LogMessage("WARNING: Handle " + TRANSFORM(tnHandle) + " nu găsit în pool")
        RETURN .F.
    ENDPROC
    
    *================================================================
    * Metodă: CreateNewConnection
    * Creează o conexiune nouă cu setări optimizate
    *================================================================
    PROTECTED PROCEDURE CreateNewConnection()
        LOCAL lnHandle, lnResult, lcConnString, i
        
        * Adaugă parametri optimizați la connection string
        lcConnString = THIS.cConnectionString
        
        * Asigură că avem packet size optimizat
        IF AT("Packet Size=", lcConnString) = 0
            lcConnString = lcConnString + ";Packet Size=" + TRANSFORM(THIS.nPacketSize)
        ENDIF
        
        * Connection timeout
        IF AT("Connection Timeout=", lcConnString) = 0
            lcConnString = lcConnString + ";Connection Timeout=" + TRANSFORM(THIS.nConnectionTimeout/1000)
        ENDIF
        
        * Retry logic pentru crearea conexiunii
        FOR i = 1 TO THIS.nConnectionRetryCount
            lnHandle = SQLSTRINGCONNECT(lcConnString)
            
            IF lnHandle > 0
                * Configurare connection properties optimizate
                SQLSETPROP(lnHandle, "QueryTimeOut", THIS.nQueryTimeout)
                SQLSETPROP(lnHandle, "Transactions", THIS.nIsolationLevel)
                SQLSETPROP(lnHandle, "BatchMode", THIS.lBatchMode)
                
                * PacketSize - Some drivers don't allow this after connection
                * Wrap in TRY/CATCH to suppress warning if not supported
                TRY
                    SQLSETPROP(lnHandle, "PacketSize", THIS.nPacketSize)
                CATCH
                    * Ignore - PacketSize already set in connection string
                ENDTRY
                
                * Additional properties
                IF THIS.lAsynchronousProcessing
                    SQLSETPROP(lnHandle, "Asynchronous", .T.)
                ENDIF
                
                * Dispatchable
                SQLSETPROP(lnHandle, "DispLogin", 1)  && No login dialog
                SQLSETPROP(lnHandle, "DispWarnings", .F.)  && No warnings
                
                IF THIS.lDebugMode
                    THIS.LogMessage("Conexiune creată cu succes - Handle: " + TRANSFORM(lnHandle))
                ENDIF
                
                RETURN lnHandle
            ELSE
                LOCAL ARRAY laError[1]
                AERROR(laError)
                THIS.LogMessage("EROARE Conexiune (încercare " + TRANSFORM(i) + "): " + laError[2])
                
                IF i < THIS.nConnectionRetryCount
                    DECLARE INTEGER Sleep IN Win32API INTEGER nMilliseconds
                    Sleep(THIS.nConnectionRetryInterval * 1000)
                ENDIF
            ENDIF
        ENDFOR
        
        RETURN -1
    ENDPROC
    
    *================================================================
    * Metodă: ValidateConnection
    * Validează că o conexiune este funcțională
    *================================================================
    PROTECTED PROCEDURE ValidateConnection(tnSlot)
        LOCAL lnHandle, lnResult, llValid, tStart, tEnd, nElapsed
        
        tStart = DATETIME()
        llValid = .F.
        lnHandle = THIS.aConnections[tnSlot, 1]
        
        THIS.nTotalValidations = THIS.nTotalValidations + 1
        
        * Skip validare dacă a fost validată recent (< 5 secunde)
        IF !ISNULL(THIS.aConnections[tnSlot, 6])
            IF (DATETIME() - THIS.aConnections[tnSlot, 6]) * 86400 < 5
                RETURN .T.
            ENDIF
        ENDIF
        
        TRY
            * Validare rapidă cu SELECT 1
            lnResult = SQLEXEC(lnHandle, "SELECT 1 AS Test", "curPoolValidation")
            
            IF lnResult > 0
                USE IN SELECT("curPoolValidation")
                llValid = .T.
                THIS.aConnections[tnSlot, 6] = DATETIME()
                THIS.aConnections[tnSlot, 9] = 0  && Reset failure count
                THIS.aConnections[tnSlot, 10] = .T.
            ELSE
                THIS.aConnections[tnSlot, 9] = THIS.aConnections[tnSlot, 9] + 1
                THIS.aConnections[tnSlot, 10] = .F.
                THIS.nFailedValidations = THIS.nFailedValidations + 1
            ENDIF
        CATCH
            llValid = .F.
            THIS.aConnections[tnSlot, 9] = THIS.aConnections[tnSlot, 9] + 1
            THIS.aConnections[tnSlot, 10] = .F.
            THIS.nFailedValidations = THIS.nFailedValidations + 1
        ENDTRY
        
        tEnd = DATETIME()
        nElapsed = (tEnd - tStart) * 86400000
        THIS.nTotalValidationTime = THIS.nTotalValidationTime + nElapsed
        
        * Dacă validarea durează prea mult, considerăm conexiunea suspectă
        IF nElapsed > THIS.nValidationTimeout
            llValid = .F.
            THIS.LogMessage("WARNING: Validare lentă " + TRANSFORM(nElapsed) + "ms pentru Handle: " + TRANSFORM(lnHandle))
        ENDIF
        
        RETURN llValid
    ENDPROC
    
    *================================================================
    * Metodă: AcquireConnection
    * Marchează o conexiune ca fiind în uz
    *================================================================
    PROTECTED PROCEDURE AcquireConnection(tnSlot, tcThreadID)
        THIS.aConnections[tnSlot, 2] = .T.
        THIS.aConnections[tnSlot, 4] = DATETIME()
        THIS.aConnections[tnSlot, 5] = THIS.aConnections[tnSlot, 5] + 1
        THIS.aConnections[tnSlot, 7] = DATETIME()  && Pentru leak detection
        THIS.aConnections[tnSlot, 8] = tcThreadID
        THIS.nActiveConnections = THIS.nActiveConnections + 1
    ENDPROC
    
    *================================================================
    * Metodă: IsConnectionExpired
    * Verifică dacă conexiunea a depășit max lifetime
    *================================================================
    PROTECTED PROCEDURE IsConnectionExpired(tnSlot)
        LOCAL tCreated, nAge, lcType
        
        tCreated = THIS.aConnections[tnSlot, 3]
        lcType = VARTYPE(tCreated)
        
        * Verificare tip de date - trebuie să fie datetime (type "T")
        * Acceptăm doar DATETIME valid, orice altceva (NULL, .F., .NULL., etc) = nu expirat
        IF lcType != "T"
            * Dacă nu e datetime valid, re-inițializăm slotul pentru siguranță
            IF lcType = "L" OR lcType = "X"  && Logical (.F.) sau Undefined (.NULL.)
                THIS.aConnections[tnSlot, 3] = .NULL.
            ENDIF
            RETURN .F.
        ENDIF
        
        * Verificare suplimentară că datetime e valid
        IF ISNULL(tCreated) OR EMPTY(tCreated)
            RETURN .F.
        ENDIF
        
        TRY
            nAge = (DATETIME() - tCreated) * 86400000  && milliseconds
        CATCH
            * În caz de eroare la calcul, considerăm că nu e expirată
            * Re-inițializăm pentru a preveni erori viitoare
            THIS.aConnections[tnSlot, 3] = .NULL.
            RETURN .F.
        ENDTRY
        
        RETURN (nAge > THIS.nMaxLifetime)
    ENDPROC
    
    *================================================================
    * Metodă: CloseConnection
    * Închide o conexiune și resetează slot-ul
    *================================================================
    PROTECTED PROCEDURE CloseConnection(tnSlot)
        LOCAL lnHandle
        
        lnHandle = THIS.aConnections[tnSlot, 1]
        
        IF !ISNULL(lnHandle) AND lnHandle > 0
            SQLDISCONNECT(lnHandle)
            
            IF THIS.lDebugMode
                THIS.LogMessage("Conexiune închisă Handle: " + TRANSFORM(lnHandle))
            ENDIF
        ENDIF
        
        THIS.aConnections[tnSlot, 1] = .NULL.
        THIS.aConnections[tnSlot, 2] = .F.
        THIS.aConnections[tnSlot, 3] = .NULL.  && Consistent .NULL. usage
        THIS.aConnections[tnSlot, 4] = .NULL.  && Consistent .NULL. usage
        THIS.aConnections[tnSlot, 5] = 0
        THIS.aConnections[tnSlot, 6] = .NULL.  && Consistent .NULL. usage
        THIS.aConnections[tnSlot, 7] = .NULL.  && Consistent .NULL. usage
        THIS.aConnections[tnSlot, 8] = ""
        THIS.aConnections[tnSlot, 9] = 0
        THIS.aConnections[tnSlot, 10] = .F.
        
        THIS.nCurrentSize = THIS.nCurrentSize - 1
    ENDPROC
    
    *================================================================
    * Metodă: FillPool
    * Pre-populează pool-ul cu conexiuni
    *================================================================
    PROTECTED PROCEDURE FillPool(tnCount)
        LOCAL i, lnHandle, nCreated
        
        nCreated = 0
        
        FOR i = 1 TO THIS.nMaximumPoolSize
            IF nCreated >= tnCount
                EXIT
            ENDIF
            
            IF ISNULL(THIS.aConnections[i, 1])
                lnHandle = THIS.CreateNewConnection()
                
                IF lnHandle > 0
                    THIS.aConnections[i, 1] = lnHandle
                    THIS.aConnections[i, 3] = DATETIME()
                    THIS.aConnections[i, 6] = DATETIME()
                    THIS.aConnections[i, 10] = .T.
                    THIS.nCurrentSize = THIS.nCurrentSize + 1
                    THIS.nTotalConnections = THIS.nTotalConnections + 1
                    nCreated = nCreated + 1
                ENDIF
            ENDIF
        ENDFOR
        
        IF THIS.lDebugMode
            THIS.LogMessage("Pool pre-populat cu " + TRANSFORM(nCreated) + " conexiuni")
        ENDIF
    ENDPROC
    
    *================================================================
    * Metodă: HealthCheck
    * Verificare sănătate pool
    *================================================================
    PROCEDURE HealthCheck()
        LOCAL i, nExpired, nInvalid
        
        IF !THIS.lHealthCheckEnabled
            RETURN .T.
        ENDIF
        
        * Verifică dacă e timpul pentru health check
        IF !ISNULL(THIS.tLastHealthCheck)
            IF (DATETIME() - THIS.tLastHealthCheck) * 86400000 < THIS.nHealthCheckInterval
                RETURN .T.
            ENDIF
        ENDIF
        
        THIS.tLastHealthCheck = DATETIME()
        nExpired = 0
        nInvalid = 0
        
        FOR i = 1 TO THIS.nMaximumPoolSize
            IF !ISNULL(THIS.aConnections[i, 1]) AND !THIS.aConnections[i, 2]
                * Verificare vârstă
                IF THIS.IsConnectionExpired(i)
                    THIS.CloseConnection(i)
                    nExpired = nExpired + 1
                    LOOP
                ENDIF
                
                * Verificare idle timeout
                IF !ISNULL(THIS.aConnections[i, 4])
                    nIdleTime = (DATETIME() - THIS.aConnections[i, 4]) * 86400000
                    IF nIdleTime > THIS.nIdleTimeout
                        THIS.CloseConnection(i)
                        nExpired = nExpired + 1
                        LOOP
                    ENDIF
                ENDIF
                
                * Validare periodică
                IF !THIS.ValidateConnection(i)
                    THIS.CloseConnection(i)
                    nInvalid = nInvalid + 1
                ENDIF
            ENDIF
        ENDFOR
        
        * Menține minimum idle connections
        IF THIS.nCurrentSize < THIS.nMinimumIdle
            THIS.FillPool(THIS.nMinimumIdle - THIS.nCurrentSize)
        ENDIF
        
        IF THIS.lDebugMode AND (nExpired > 0 OR nInvalid > 0)
            THIS.LogMessage("Health Check: Expirate=" + TRANSFORM(nExpired) + ;
                           ", Invalide=" + TRANSFORM(nInvalid))
        ENDIF
        
        RETURN .T.
    ENDPROC
    
    *================================================================
    * Metodă: CheckCircuitBreaker
    * Verifică starea circuit breaker
    *================================================================
    PROTECTED PROCEDURE CheckCircuitBreaker()
        IF THIS.nCircuitBreakerState = 0  && Closed
            RETURN .T.
        ENDIF
        
        IF THIS.nCircuitBreakerState = 1  && Open
            * Verifică dacă putem trece în Half-Open
            IF (DATETIME() - THIS.tCircuitBreakerOpenTime) * 86400000 > THIS.nCircuitBreakerTimeout
                THIS.nCircuitBreakerState = 2  && Half-Open
                THIS.LogMessage("Circuit Breaker: HALF-OPEN")
                RETURN .T.
            ENDIF
            RETURN .F.
        ENDIF
        
        IF THIS.nCircuitBreakerState = 2  && Half-Open
            RETURN .T.
        ENDIF
        
        RETURN .F.
    ENDPROC
    
    *================================================================
    * Metodă: RecordCircuitBreakerFailure
    * Înregistrează un failure pentru circuit breaker
    *================================================================
    PROTECTED PROCEDURE RecordCircuitBreakerFailure()
        THIS.nCircuitBreakerFailures = THIS.nCircuitBreakerFailures + 1
        
        IF THIS.nCircuitBreakerFailures >= THIS.nCircuitBreakerThreshold
            THIS.nCircuitBreakerState = 1  && Open
            THIS.tCircuitBreakerOpenTime = DATETIME()
            THIS.LogMessage("Circuit Breaker: OPEN după " + TRANSFORM(THIS.nCircuitBreakerFailures) + " failures")
        ENDIF
    ENDPROC
    
    *================================================================
    * Metodă: GetPoolStatus
    * Returnează status detaliat pool
    *================================================================
    PROCEDURE GetPoolStatus()
        LOCAL i, lnInUse, lnIdle, lnTotal, lcStatus, nAvgAcqTime
        
        lnInUse = 0
        lnIdle = 0
        lnTotal = 0
        
        FOR i = 1 TO THIS.nMaximumPoolSize
            IF !ISNULL(THIS.aConnections[i, 1])
                lnTotal = lnTotal + 1
                IF THIS.aConnections[i, 2]
                    lnInUse = lnInUse + 1
                ELSE
                    lnIdle = lnIdle + 1
                ENDIF
            ENDIF
        ENDFOR
        
        nAvgAcqTime = IIF(THIS.nTotalAcquisitions > 0, ;
                         THIS.nTotalAcquisitionTime / THIS.nTotalAcquisitions, 0)
        
        TEXT TO lcStatus NOSHOW TEXTMERGE
        ========== CONNECTION POOL STATUS ==========
        Pool Configuration:
          Minimum Idle: <<THIS.nMinimumIdle>>
          Maximum Size: <<THIS.nMaximumPoolSize>>
          Current Size: <<lnTotal>>
        
        Current State:
          Active: <<lnInUse>>
          Idle: <<lnIdle>>
          Circuit Breaker: <<IIF(THIS.nCircuitBreakerState=0,"CLOSED",IIF(THIS.nCircuitBreakerState=1,"OPEN","HALF-OPEN"))>>
        
        Performance Metrics:
          Total Acquisitions: <<THIS.nTotalAcquisitions>>
          Total Releases: <<THIS.nTotalReleases>>
          Failed Acquisitions: <<THIS.nFailedAcquisitions>>
          Timeouts: <<THIS.nConnectionTimeouts>>
          Leaks Detected: <<THIS.nLeaksDetected>>
        
        Timing Statistics:
          Avg Acquisition Time: <<TRANSFORM(nAvgAcqTime,"999.99")>> ms
          Min Acquisition Time: <<TRANSFORM(THIS.nMinAcquisitionTime,"999.99")>> ms
          Max Acquisition Time: <<TRANSFORM(THIS.nMaxAcquisitionTime,"999.99")>> ms
        
        Connection Quality:
          Total Created: <<THIS.nTotalConnections>>
          Validations: <<THIS.nTotalValidations>>
          Failed Validations: <<THIS.nFailedValidations>>
        
        Configuration Tuning:
          Packet Size: <<THIS.nPacketSize>> bytes
          Query Timeout: <<THIS.nQueryTimeout>> sec
          Connection Timeout: <<THIS.nConnectionTimeout/1000>> sec
          Idle Timeout: <<THIS.nIdleTimeout/1000>> sec
          Max Lifetime: <<THIS.nMaxLifetime/1000>> sec
        ===========================================
        ENDTEXT
        
        RETURN lcStatus
    ENDPROC
    
    *================================================================
    * Metodă: GetDetailedMetrics
    * Returnează metrici detaliate pentru fiecare conexiune
    *================================================================
    PROCEDURE GetDetailedMetrics()
        LOCAL i, lcMetrics, lcLine
        
        TEXT TO lcMetrics NOSHOW
        === CONEXIUNI DETALIATE ===
        ENDTEXT
        
        FOR i = 1 TO THIS.nMaximumPoolSize
            IF !ISNULL(THIS.aConnections[i, 1])
                TEXT TO lcLine NOSHOW TEXTMERGE
                [<<i>>] Handle=<<THIS.aConnections[i,1]>> InUse=<<IIF(THIS.aConnections[i,2],"Da","Nu")>> Uses=<<THIS.aConnections[i,5]>> Valid=<<IIF(THIS.aConnections[i,10],"Da","Nu")>> Failures=<<THIS.aConnections[i,9]>>
                ENDTEXT
                lcMetrics = lcMetrics + CHR(13)+CHR(10) + lcLine
            ENDIF
        ENDFOR
        
        RETURN lcMetrics
    ENDPROC
    
    *================================================================
    * Metodă: OptimizeForWorkload
    * Auto-tuning bazat pe workload
    *================================================================
    PROCEDURE OptimizeForWorkload(tcWorkloadType)
        LOCAL lcType, lnOldMaxSize, lnNewMaxSize, i
        lcType = UPPER(tcWorkloadType)
        lnOldMaxSize = THIS.nMaximumPoolSize
        
        DO CASE
            CASE lcType = "OLTP"
                * Optimizare pentru OLTP (multe tranzacții scurte)
                THIS.nMinimumIdle = 10
                THIS.nMaximumPoolSize = 20
                THIS.nPacketSize = 8192
                THIS.nIdleTimeout = 300000  && 5 min
                THIS.nMaxLifetime = 900000  && 15 min
                THIS.lBatchMode = .F.
                THIS.LogMessage("Optimizat pentru OLTP")
                
            CASE lcType = "OLAP"
                * Optimizare pentru OLAP (query-uri lungi)
                THIS.nMinimumIdle = 3
                THIS.nMaximumPoolSize = 8
                THIS.nPacketSize = 32768
                THIS.nQueryTimeout = 300  && 5 min
                THIS.nIdleTimeout = 1800000  && 30 min
                THIS.nMaxLifetime = 3600000  && 60 min
                THIS.lBatchMode = .T.
                THIS.LogMessage("Optimizat pentru OLAP")
                
            CASE lcType = "MIXED"
                * Balanced pentru workload mixt
                THIS.nMinimumIdle = 5
                THIS.nMaximumPoolSize = 15
                THIS.nPacketSize = 16384
                THIS.nQueryTimeout = 60
                THIS.nIdleTimeout = 600000  && 10 min
                THIS.nMaxLifetime = 1800000  && 30 min
                THIS.lBatchMode = .T.
                THIS.LogMessage("Optimizat pentru MIXED")
                
            OTHERWISE
                THIS.LogMessage("Workload type necunoscut: " + tcWorkloadType)
        ENDCASE
        
        * Redimensionare array dacă pool size s-a schimbat
        lnNewMaxSize = THIS.nMaximumPoolSize
        IF lnNewMaxSize != lnOldMaxSize
            DIMENSION THIS.aConnections[lnNewMaxSize, 10]
            
            * Inițializare toate elementele pentru a preveni type mismatch
            * DIMENSION poate lăsa valori .F. în unele elemente
            FOR i = 1 TO lnNewMaxSize
                * Păstrăm conexiunile existente, inițializăm doar cele noi sau invalide
                IF i > lnOldMaxSize OR VARTYPE(THIS.aConnections[i, 3]) != "T"
                    THIS.aConnections[i, 1] = .NULL.
                    THIS.aConnections[i, 2] = .F.
                    THIS.aConnections[i, 3] = .NULL.  && Consistent .NULL. usage
                    THIS.aConnections[i, 4] = .NULL.  && Consistent .NULL. usage
                    THIS.aConnections[i, 5] = 0
                    THIS.aConnections[i, 6] = .NULL.  && Consistent .NULL. usage
                    THIS.aConnections[i, 7] = .NULL.  && Consistent .NULL. usage
                    THIS.aConnections[i, 8] = ""
                    THIS.aConnections[i, 9] = 0
                    THIS.aConnections[i, 10] = .F.
                ENDIF
            ENDFOR
            
            THIS.LogMessage("Pool redimensionat: " + TRANSFORM(lnOldMaxSize) + " -> " + TRANSFORM(lnNewMaxSize))
        ENDIF
    ENDPROC
    
    *================================================================
    * Metodă: CloseAll
    *================================================================
    PROCEDURE CloseAll()
        LOCAL i
        
        THIS.lShutdown = .T.
        
        FOR i = 1 TO THIS.nMaximumPoolSize
            IF !ISNULL(THIS.aConnections[i, 1])
                SQLDISCONNECT(THIS.aConnections[i, 1])
                THIS.aConnections[i, 1] = .NULL.
            ENDIF
        ENDFOR
        
        THIS.nCurrentSize = 0
        THIS.nActiveConnections = 0
        
        IF THIS.lDebugMode
            THIS.LogMessage("Toate conexiunile închise")
        ENDIF
    ENDPROC
    
    *================================================================
    * Metodă: LogMessage
    *================================================================
    PROTECTED PROCEDURE LogMessage(tcMessage)
        LOCAL lcLogEntry
        lcLogEntry = TTOC(DATETIME()) + " | " + tcMessage + CHR(13)+CHR(10)
        TRY
            STRTOFILE(lcLogEntry, THIS.cLogFile, .T.)
        CATCH
        ENDTRY
    ENDPROC
    
    *================================================================
    * Metodă: WriteMetricsHeader
    *================================================================
    PROTECTED PROCEDURE WriteMetricsHeader()
        LOCAL lcHeader
        TEXT TO lcHeader NOSHOW
        Timestamp,Operation,Duration_ms,PoolSize,ActiveConnections,IdleConnections
        ENDTEXT
        TRY
            STRTOFILE(lcHeader + CHR(13)+CHR(10), THIS.cMetricsFile, .F.)
        CATCH
        ENDTRY
    ENDPROC
    
    *================================================================
    * Metodă: LogMetrics
    *================================================================
    PROTECTED PROCEDURE LogMetrics(tcOperation, tnDuration)
        LOCAL lcLine, nIdle
        
        nIdle = THIS.nCurrentSize - THIS.nActiveConnections
        
        TEXT TO lcLine NOSHOW TEXTMERGE
        <<TTOC(DATETIME())>>,<<tcOperation>>,<<TRANSFORM(tnDuration,"999999.99")>>,<<THIS.nCurrentSize>>,<<THIS.nActiveConnections>>,<<nIdle>>
        ENDTEXT
        
        TRY
            STRTOFILE(lcLine + CHR(13)+CHR(10), THIS.cMetricsFile, .T.)
        CATCH
        ENDTRY
    ENDPROC
    
    *================================================================
    * Metodă: Destroy
    *================================================================
    PROCEDURE Destroy()
        THIS.CloseAll()
        
        IF THIS.lMetricsEnabled
            THIS.LogMessage("=== FINAL METRICS ===")
            THIS.LogMessage(THIS.GetPoolStatus())
        ENDIF
    ENDPROC
ENDDEFINE

*====================================================================
* Funcție: GetOptimizedConnectionPool
* Singleton pattern pentru pool optimizat
*====================================================================
FUNCTION GetOptimizedConnectionPool(tcConnectionString, tnMinIdle, tnMaxSize)
    LOCAL loPool
    
    IF TYPE('_SCREEN.oOptimizedConnectionPool') = 'O' AND ;
       !ISNULL(_SCREEN.oOptimizedConnectionPool)
        RETURN _SCREEN.oOptimizedConnectionPool
    ENDIF
    
    IF EMPTY(tcConnectionString)
        TEXT TO tcConnectionString NOSHOW
        Driver=SQL Server Native Client 11.0;
        Database=SCUnicProdcomSRL;
        Server=localhost\ICAS_2019;
        UID=sa;
        PWD=016049;
        ENDTEXT
    ENDIF
    
    IF EMPTY(tnMinIdle)
        tnMinIdle = 5
    ENDIF
    
    IF EMPTY(tnMaxSize)
        tnMaxSize = 10
    ENDIF
    
    loPool = CREATEOBJECT("ConnectionPoolOptimized", tcConnectionString, tnMinIdle, tnMaxSize)
    
    IF !ISNULL(loPool)
        ADDPROPERTY(_SCREEN, 'oOptimizedConnectionPool', loPool)
    ENDIF
    
    RETURN loPool
ENDFUNC
