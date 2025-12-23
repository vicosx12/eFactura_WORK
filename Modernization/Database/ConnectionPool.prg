*====================================================================
* Program: ConnectionPool.prg
* Scop: Pool de conexiuni pentru SQL Server cu management automat
* Data: 2024-12-23
* Autor: Modernizare VFP 9.0
*====================================================================
* Versiune production-ready pentru:
* - SQL Server Native Client 11.0
* - Database: SCUnicProdcomSRL
* - Server: localhost\ICAS_2019
*====================================================================

*====================================================================
* DEFINE CLASS: ConnectionPool
* Scop: Gestionare pool de conexiuni pentru performanță optimă
*====================================================================
DEFINE CLASS ConnectionPool AS Custom
    DIMENSION aConnections[1]
    nPoolSize = 5
    nCurrentConnections = 0
    cConnectionString = ""
    nMaxRetries = 3
    lDebugMode = .F.
    cLogFile = ""
    
    *================================================================
    * Metodă: Init
    *================================================================
    PROCEDURE Init(tcConnectionString, tnPoolSize)
        LOCAL i
        
        IF !EMPTY(tcConnectionString)
            THIS.cConnectionString = tcConnectionString
        ENDIF
        
        IF !EMPTY(tnPoolSize) AND tnPoolSize > 0
            THIS.nPoolSize = tnPoolSize
        ENDIF
        
        * Inițializare array
        DIMENSION THIS.aConnections[THIS.nPoolSize, 4]
        * Coloana 1: Connection Handle
        * Coloana 2: In Use (logical)
        * Coloana 3: Last Used (datetime)
        * Coloana 4: Total Uses (integer)
        
        FOR i = 1 TO THIS.nPoolSize
            THIS.aConnections[i, 1] = .NULL.
            THIS.aConnections[i, 2] = .F.
            THIS.aConnections[i, 3] = DATETIME()
            THIS.aConnections[i, 4] = 0
        ENDFOR
        
        * Setup log file
        THIS.cLogFile = ADDBS(SYS(5)+SYS(2003)) + "ConnectionPool_" + DTOS(DATE()) + ".log"
        
        IF THIS.lDebugMode
            THIS.LogMessage("Connection Pool inițializat - Pool Size: " + TRANSFORM(THIS.nPoolSize))
        ENDIF
        
        RETURN .T.
    ENDPROC
    
    *================================================================
    * Metodă: GetConnection
    *================================================================
    PROCEDURE GetConnection()
        LOCAL lnHandle, i, llFound, lnAttempt
        
        llFound = .F.
        lnAttempt = 0
        
        DO WHILE !llFound AND lnAttempt < THIS.nMaxRetries
            lnAttempt = lnAttempt + 1
            
            FOR i = 1 TO THIS.nPoolSize
                IF !THIS.aConnections[i, 2]
                    IF ISNULL(THIS.aConnections[i, 1])
                        lnHandle = THIS.CreateNewConnection()
                        
                        IF lnHandle > 0
                            THIS.aConnections[i, 1] = lnHandle
                            THIS.aConnections[i, 2] = .T.
                            THIS.aConnections[i, 3] = DATETIME()
                            THIS.aConnections[i, 4] = 1
                            THIS.nCurrentConnections = THIS.nCurrentConnections + 1
                            llFound = .T.
                            
                            IF THIS.lDebugMode
                                THIS.LogMessage("Conexiune nouă - Handle: " + TRANSFORM(lnHandle))
                            ENDIF
                            
                            RETURN lnHandle
                        ENDIF
                    ELSE
                        lnHandle = THIS.aConnections[i, 1]
                        
                        IF THIS.IsConnectionValid(lnHandle)
                            THIS.aConnections[i, 2] = .T.
                            THIS.aConnections[i, 3] = DATETIME()
                            THIS.aConnections[i, 4] = THIS.aConnections[i, 4] + 1
                            llFound = .T.
                            
                            IF THIS.lDebugMode
                                THIS.LogMessage("Reutilizată - Handle: " + TRANSFORM(lnHandle))
                            ENDIF
                            
                            RETURN lnHandle
                        ELSE
                            SQLDISCONNECT(lnHandle)
                            THIS.aConnections[i, 1] = .NULL.
                            THIS.nCurrentConnections = THIS.nCurrentConnections - 1
                        ENDIF
                    ENDIF
                ENDIF
            ENDFOR
            
            IF !llFound
                DECLARE INTEGER Sleep IN Win32API INTEGER nMilliseconds
                Sleep(100)
            ENDIF
        ENDDO
        
        IF !llFound
            THIS.LogMessage("EROARE: Pool epuizat după " + TRANSFORM(lnAttempt) + " încercări")
            RETURN -1
        ENDIF
    ENDPROC
    
    *================================================================
    * Metodă: ReleaseConnection
    *================================================================
    PROCEDURE ReleaseConnection(tnHandle)
        LOCAL i
        
        FOR i = 1 TO THIS.nPoolSize
            IF THIS.aConnections[i, 1] = tnHandle
                THIS.aConnections[i, 2] = .F.
                THIS.aConnections[i, 3] = DATETIME()
                RETURN .T.
            ENDIF
        ENDFOR
        
        RETURN .F.
    ENDPROC
    
    *================================================================
    * Metodă: CreateNewConnection
    *================================================================
    PROTECTED PROCEDURE CreateNewConnection()
        LOCAL lnHandle, lnResult
        
        lnHandle = SQLSTRINGCONNECT(THIS.cConnectionString)
        
        IF lnHandle > 0
            SQLSETPROP(lnHandle, "QueryTimeOut", 30)
            SQLSETPROP(lnHandle, "Transactions", 2)
            SQLSETPROP(lnHandle, "BatchMode", .T.)
            SQLSETPROP(lnHandle, "PacketSize", 8192)
            RETURN lnHandle
        ELSE
            LOCAL ARRAY laError[1]
            AERROR(laError)
            THIS.LogMessage("EROARE: " + laError[2])
            RETURN -1
        ENDIF
    ENDPROC
    
    *================================================================
    * Metodă: IsConnectionValid
    *================================================================
    PROTECTED PROCEDURE IsConnectionValid(tnHandle)
        LOCAL lnResult
        
        TRY
            lnResult = SQLEXEC(tnHandle, "SELECT 1 AS Test", "curPoolTest")
            IF lnResult > 0
                USE IN SELECT("curPoolTest")
                RETURN .T.
            ENDIF
            RETURN .F.
        CATCH
            RETURN .F.
        ENDTRY
    ENDPROC
    
    *================================================================
    * Metodă: CloseAll
    *================================================================
    PROCEDURE CloseAll()
        LOCAL i
        
        FOR i = 1 TO THIS.nPoolSize
            IF !ISNULL(THIS.aConnections[i, 1])
                SQLDISCONNECT(THIS.aConnections[i, 1])
                THIS.aConnections[i, 1] = .NULL.
                THIS.aConnections[i, 2] = .F.
            ENDIF
        ENDFOR
        
        THIS.nCurrentConnections = 0
    ENDPROC
    
    *================================================================
    * Metodă: GetPoolStatus
    *================================================================
    PROCEDURE GetPoolStatus()
        LOCAL i, lnInUse, lnAvailable, lcStatus
        
        lnInUse = 0
        lnAvailable = 0
        
        FOR i = 1 TO THIS.nPoolSize
            IF THIS.aConnections[i, 2]
                lnInUse = lnInUse + 1
            ELSE
                lnAvailable = lnAvailable + 1
            ENDIF
        ENDFOR
        
        TEXT TO lcStatus NOSHOW TEXTMERGE
        ===== POOL STATUS =====
        Size: <<THIS.nPoolSize>>
        In Use: <<lnInUse>>
        Available: <<lnAvailable>>
        Created: <<THIS.nCurrentConnections>>
        =======================
        ENDTEXT
        
        RETURN lcStatus
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
    * Metodă: Destroy
    *================================================================
    PROCEDURE Destroy()
        THIS.CloseAll()
    ENDPROC
ENDDEFINE

*====================================================================
* Funcție: GetGlobalConnectionPool
*====================================================================
FUNCTION GetGlobalConnectionPool(tcConnectionString, tnPoolSize)
    LOCAL loPool
    
    IF TYPE('_SCREEN.oGlobalConnectionPool') = 'O' AND ;
       !ISNULL(_SCREEN.oGlobalConnectionPool)
        RETURN _SCREEN.oGlobalConnectionPool
    ENDIF
    
    IF EMPTY(tcConnectionString)
        TEXT TO tcConnectionString NOSHOW
        Driver=SQL Server Native Client 11.0;
        Database=SCUnicProdcomSRL;
        Server=localhost\ICAS_2019;
        UID=sa;
        PWD=016049;
        Connection Timeout=30;
        ENDTEXT
    ENDIF
    
    IF EMPTY(tnPoolSize)
        tnPoolSize = 5
    ENDIF
    
    loPool = CREATEOBJECT("ConnectionPool", tcConnectionString, tnPoolSize)
    
    IF !ISNULL(loPool)
        ADDPROPERTY(_SCREEN, 'oGlobalConnectionPool', loPool)
    ENDIF
    
    RETURN loPool
ENDFUNC
