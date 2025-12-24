*====================================================================
* Program: Init_Modernization.prg
* Scop: Inițializare globală pentru componente modernizare
* Data: 2024-12-23
*====================================================================
* Usage: DO Modernization\Init_Modernization.prg
*====================================================================

*====================================================================
* Procedură: Init_Modernization_Environment
*====================================================================
PROCEDURE Init_Modernization_Environment()
    LOCAL llSuccess
    
    ? "======================================="
    ? "INIȚIALIZARE MEDIU MODERNIZARE"
    ? "======================================="
    ? ""
    
    llSuccess = .T.
    
    * 1. Setare căi
    ? "1. Setare căi..."
    IF !SetupPaths()
        llSuccess = .F.
    ENDIF
    ? ""
    
    * 2. Verificare componente necesare
    ? "2. Verificare componente..."
    IF !CheckRequiredComponents()
        llSuccess = .F.
    ENDIF
    ? ""
    
    * 3. Inițializare Connection Pool global
    ? "3. Inițializare Connection Pool..."
    IF !InitGlobalConnectionPool()
        llSuccess = .F.
    ENDIF
    ? ""
    
    * 4. Inițializare ANAF Client global
    ? "4. Inițializare ANAF Client..."
    IF !InitGlobalANAFClient()
        llSuccess = .F.
    ENDIF
    ? ""
    
    * Rezultat
    ? "======================================="
    IF llSuccess
        ? "✓ INIȚIALIZARE COMPLETĂ"
        ? ""
        ? "Componente disponibile:"
        ? "  - _SCREEN.oOptimizedConnectionPool"
        ? "  - _SCREEN.oGlobalANAFClient"
        ? ""
        ? "Funcții helper:"
        ? "  - GetOptimizedConnectionPool()"
        ? "  - GetGlobalANAFClient()"
    ELSE
        ? "✗ INIȚIALIZARE INCOMPLETĂ"
        ? "Verificați log-urile pentru detalii"
    ENDIF
    ? "======================================="
    
    RETURN llSuccess
ENDPROC

*====================================================================
* Procedură: SetupPaths
*====================================================================
PROCEDURE SetupPaths()
    LOCAL lcBasePath, llSuccess
    
    llSuccess = .F.
    
    TRY
        * Calea de bază
        lcBasePath = ADDBS(JUSTPATH(SYS(16,1)))
        
        * Adaugă căi în SET PROCEDURE
        SET PROCEDURE TO (lcBasePath + "Database\ConnectionPool.prg") ADDITIVE
        SET PROCEDURE TO (lcBasePath + "Database\ConnectionPoolOptimized.prg") ADDITIVE
        SET PROCEDURE TO (lcBasePath + "API\ANAF_Client.prg") ADDITIVE
        
        ? "  ✓ Căi setate"
        llSuccess = .T.
        
    CATCH TO loEx
        ? "  ✗ EROARE SetupPaths:", loEx.Message
        llSuccess = .F.
    ENDTRY
    
    RETURN llSuccess
ENDPROC

*====================================================================
* Procedură: CheckRequiredComponents
*====================================================================
PROCEDURE CheckRequiredComponents()
    LOCAL llSuccess
    
    llSuccess = .T.
    
    * Verificare Chilkat
    TRY
        LOCAL loHttp
        loHttp = CREATEOBJECT("Chilkat_9_5_0.Http")
        
        IF ISNULL(loHttp)
            ? "  ✗ Chilkat 9.5.0 nu este disponibil"
            llSuccess = .F.
        ELSE
            ? "  ✓ Chilkat 9.5.0 disponibil"
            ? "    TLS Version:", loHttp.TlsVersion
        ENDIF
        
    CATCH TO loEx
        ? "  ✗ Chilkat indisponibil:", loEx.Message
        llSuccess = .F.
    ENDTRY
    
    * Verificare SQL Server Native Client
    TRY
        LOCAL lcConnString, lnHandle
        
        TEXT TO lcConnString NOSHOW
        Driver=SQL Server Native Client 11.0;
        Database=SCUnicProdcomSRL;
        Server=localhost\ICAS_2019;
        UID=sa;
        PWD=016049
        ENDTEXT
        
        lnHandle = SQLSTRINGCONNECT(lcConnString)
        
        IF lnHandle > 0
            ? "  ✓ SQL Server Native Client 11.0 disponibil"
            ? "    Database: SCUnicProdcomSRL conectat"
            SQLDISCONNECT(lnHandle)
        ELSE
            ? "  ✗ SQL Server Native Client 11.0 indisponibil"
            LOCAL ARRAY laError[1]
            AERROR(laError)
            ? "    Eroare:", laError[2]
            llSuccess = .F.
        ENDIF
        
    CATCH TO loEx
        ? "  ✗ SQL Server indisponibil:", loEx.Message
        llSuccess = .F.
    ENDTRY
    
    * Verificare ICAS.oSettings
    IF TYPE('ICAS.oSettings') = 'O'
        ? "  ✓ ICAS.oSettings disponibil"
    ELSE
        ? "  ⚠ ICAS.oSettings nu există (ANAF client va eșua)"
    ENDIF
    
    RETURN llSuccess
ENDPROC

*====================================================================
* Procedură: InitGlobalConnectionPool
*====================================================================
PROCEDURE InitGlobalConnectionPool()
    LOCAL loPool, llSuccess
    
    llSuccess = .F.
    
    TRY
        loPool = GetOptimizedConnectionPool()
        
        IF !ISNULL(loPool)
            ? "  ✓ Connection Pool creat"
            ? loPool.GetPoolStatus()
            llSuccess = .T.
        ELSE
            ? "  ✗ Connection Pool eșuat"
            llSuccess = .F.
        ENDIF
        
    CATCH TO loEx
        ? "  ✗ EROARE InitGlobalConnectionPool:", loEx.Message
        llSuccess = .F.
    ENDTRY
    
    RETURN llSuccess
ENDPROC

*====================================================================
* Procedură: InitGlobalANAFClient
*====================================================================
PROCEDURE InitGlobalANAFClient()
    LOCAL loClient, llSuccess
    
    llSuccess = .F.
    
    TRY
        * Verifică dacă există ICAS.oSettings
        IF TYPE('ICAS.oSettings') != 'O'
            ? "  ⚠ SKIP - ICAS.oSettings nu există"
            llSuccess = .T.  && Nu e eroare critică
        ELSE
            * Creare client (test environment)
            loClient = GetGlobalANAFClient(.T.)
            
            IF !ISNULL(loClient)
                ? "  ✓ ANAF Client creat"
                ? "    Environment: Test"
                ? "    Base URL:", loClient.cTestURL
                llSuccess = .T.
            ELSE
                ? "  ✗ ANAF Client eșuat"
                llSuccess = .F.
            ENDIF
        ENDIF
        
    CATCH TO loEx
        ? "  ✗ EROARE InitGlobalANAFClient:", loEx.Message
        llSuccess = .F.
    ENDTRY
    
    RETURN llSuccess
ENDPROC

*====================================================================
* Procedură: Cleanup_Modernization_Environment
*====================================================================
PROCEDURE Cleanup_Modernization_Environment()
    ? "Cleanup mediu modernizare..."
    
    * Închide Connection Pool
    IF TYPE('_SCREEN.oOptimizedConnectionPool') = 'O'
        _SCREEN.oOptimizedConnectionPool.CloseAll()
        ? "  ✓ Connection Pool închis"
    ENDIF
    
    ? "✓ Cleanup complet"
ENDPROC

*====================================================================
* Main Entry Point
*====================================================================
IF PROGRAM() = "INIT_MODERNIZATION"
    Init_Modernization_Environment()
ENDIF
