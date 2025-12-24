# Configurare ODBC și Connection Pooling pentru VFP 9.0

## Introducere

Acest ghid descrie configurarea driverelor ODBC moderne și implementarea connection pooling pentru optimizarea performanței aplicațiilor Visual FoxPro 9.0.

## Drivere ODBC Recomandate

### SQL Server

**Driver recomandat: Microsoft ODBC Driver 18 for SQL Server**

#### Caracteristici:
- Suport nativ pentru TLS 1.2+ și TLS 1.3
- Compatibilitate cu Windows 10/11
- Performanță optimizată
- Suport pentru Always Encrypted
- Connection pooling nativ

#### Descărcare și Instalare:
```
URL: https://docs.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server

Pași:
1. Descărcați ODBC Driver 18 (64-bit și 32-bit)
2. Instalați ambele versiuni (VFP rulează 32-bit dar poate accesa resurse 64-bit)
3. Verificați instalarea în Control Panel > Administrative Tools > ODBC Data Sources
```

#### Configurare DSN:
```
1. Deschideți "ODBC Data Source Administrator (32-bit)"
2. Tab "System DSN" > Add
3. Selectați "ODBC Driver 18 for SQL Server"
4. Configurați:
   - Name: eFactura_SQL
   - Server: localhost\SQLEXPRESS (sau server-ul dvs.)
   - Authentication: SQL Server sau Windows
5. Test Connection pentru verificare
```

### MySQL

**Driver recomandat: MySQL Connector/ODBC 8.0**

#### Caracteristici:
- Suport pentru TLS/SSL
- Compatibilitate cu MySQL 5.7+ și 8.0+
- Connection pooling
- Performanță îmbunătățită

#### Descărcare și Instalare:
```
URL: https://dev.mysql.com/downloads/connector/odbc/

Pași:
1. Descărcați MySQL Connector/ODBC 8.0 (32-bit pentru VFP)
2. Instalați folosind installer-ul MSI
3. Verificați instalarea în ODBC Data Sources
```

#### Configurare DSN:
```
1. ODBC Data Source Administrator (32-bit)
2. System DSN > Add
3. Selectați "MySQL ODBC 8.0 Unicode Driver"
4. Configurați:
   - Data Source Name: eFactura_MySQL
   - TCP/IP Server: localhost
   - Port: 3306
   - Database: efactura_db
   - User: root
   - Password: [parola]
5. Test Connection
```

## Connection String Examples

### SQL Server cu ODBC Driver 18

```foxpro
*====================================================================
* Connection String pentru SQL Server - ODBC Driver 18
*====================================================================
LOCAL lcConnectionString

* Variant 1: Cu DSN
lcConnectionString = "DSN=eFactura_SQL;UID=sa;PWD=your_password;"

* Variant 2: Fără DSN (Connection String complet)
TEXT TO lcConnectionString NOSHOW
Driver={ODBC Driver 18 for SQL Server};
Server=localhost\SQLEXPRESS;
Database=eFacturaDB;
UID=sa;
PWD=your_password;
Encrypt=yes;
TrustServerCertificate=no;
Connection Timeout=30;
ENDTEXT

* Variant 3: Windows Authentication
TEXT TO lcConnectionString NOSHOW
Driver={ODBC Driver 18 for SQL Server};
Server=localhost\SQLEXPRESS;
Database=eFacturaDB;
Trusted_Connection=yes;
Encrypt=yes;
TrustServerCertificate=yes;
ENDTEXT
```

### MySQL cu ODBC 8.0

```foxpro
*====================================================================
* Connection String pentru MySQL - ODBC 8.0
*====================================================================
LOCAL lcConnectionString

* Variant 1: Cu DSN
lcConnectionString = "DSN=eFactura_MySQL;UID=root;PWD=your_password;"

* Variant 2: Fără DSN
TEXT TO lcConnectionString NOSHOW
Driver={MySQL ODBC 8.0 Unicode Driver};
Server=localhost;
Port=3306;
Database=efactura_db;
User=root;
Password=your_password;
Option=3;
ENDTEXT

* Variant 3: Cu SSL/TLS
TEXT TO lcConnectionString NOSHOW
Driver={MySQL ODBC 8.0 Unicode Driver};
Server=localhost;
Database=efactura_db;
User=root;
Password=your_password;
sslca=C:\certs\ca.pem;
sslcert=C:\certs\client-cert.pem;
sslkey=C:\certs\client-key.pem;
ENDTEXT
```

## Implementare Connection Pooling

### Variantă 1: Connection Pool Manual în VFP

```foxpro
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
    
    *================================================================
    * Metodă: Init
    *================================================================
    PROCEDURE Init(tcConnectionString, tnPoolSize)
        IF !EMPTY(tcConnectionString)
            THIS.cConnectionString = tcConnectionString
        ENDIF
        
        IF !EMPTY(tnPoolSize) AND tnPoolSize > 0
            THIS.nPoolSize = tnPoolSize
        ENDIF
        
        * Inițializare array
        DIMENSION THIS.aConnections[THIS.nPoolSize, 3]
        * Coloana 1: Connection Handle
        * Coloana 2: In Use (logical)
        * Coloana 3: Last Used (datetime)
        
        LOCAL i
        FOR i = 1 TO THIS.nPoolSize
            THIS.aConnections[i, 1] = .NULL.
            THIS.aConnections[i, 2] = .F.
            THIS.aConnections[i, 3] = DATETIME()
        ENDFOR
        
        ? "Connection Pool inițializat - Pool Size: " + TRANSFORM(THIS.nPoolSize)
    ENDPROC
    
    *================================================================
    * Metodă: GetConnection
    * Scop: Obține o conexiune din pool
    *================================================================
    PROCEDURE GetConnection()
        LOCAL lnHandle, i, llFound, lnAttempt
        
        llFound = .F.
        lnAttempt = 0
        
        DO WHILE !llFound AND lnAttempt < THIS.nMaxRetries
            lnAttempt = lnAttempt + 1
            
            * Caută conexiune disponibilă
            FOR i = 1 TO THIS.nPoolSize
                IF !THIS.aConnections[i, 2]  && Nu e în uz
                    * Verifică dacă conexiunea există și e validă
                    IF ISNULL(THIS.aConnections[i, 1])
                        * Creare conexiune nouă
                        lnHandle = THIS.CreateNewConnection()
                        
                        IF lnHandle > 0
                            THIS.aConnections[i, 1] = lnHandle
                            THIS.aConnections[i, 2] = .T.
                            THIS.aConnections[i, 3] = DATETIME()
                            THIS.nCurrentConnections = THIS.nCurrentConnections + 1
                            llFound = .T.
                            
                            ? "Conexiune nouă creată - Handle: " + TRANSFORM(lnHandle)
                            RETURN lnHandle
                        ENDIF
                    ELSE
                        * Reutilizare conexiune existentă
                        lnHandle = THIS.aConnections[i, 1]
                        
                        * Verifică dacă conexiunea e validă
                        IF THIS.IsConnectionValid(lnHandle)
                            THIS.aConnections[i, 2] = .T.
                            THIS.aConnections[i, 3] = DATETIME()
                            llFound = .T.
                            
                            ? "Conexiune reutilizată - Handle: " + TRANSFORM(lnHandle)
                            RETURN lnHandle
                        ELSE
                            * Conexiune invalidă, recreează
                            SQLCLOSE(lnHandle)
                            THIS.aConnections[i, 1] = .NULL.
                            THIS.nCurrentConnections = THIS.nCurrentConnections - 1
                        ENDIF
                    ENDIF
                ENDIF
            ENDFOR
            
            IF !llFound
                * Pool plin, așteaptă scurt
                ? "Pool plin, așteptare... (Tentativa " + TRANSFORM(lnAttempt) + ")"
                
                DECLARE INTEGER Sleep IN Win32API INTEGER nMilliseconds
                Sleep(100)  && 100ms
            ENDIF
        ENDDO
        
        IF !llFound
            MESSAGEBOX("Nu s-a putut obține conexiune din pool", 16, "Eroare")
            RETURN -1
        ENDIF
    ENDPROC
    
    *================================================================
    * Metodă: ReleaseConnection
    * Scop: Eliberează o conexiune înapoi în pool
    *================================================================
    PROCEDURE ReleaseConnection(tnHandle)
        LOCAL i
        
        FOR i = 1 TO THIS.nPoolSize
            IF THIS.aConnections[i, 1] = tnHandle
                THIS.aConnections[i, 2] = .F.
                THIS.aConnections[i, 3] = DATETIME()
                
                ? "Conexiune eliberată - Handle: " + TRANSFORM(tnHandle)
                RETURN .T.
            ENDIF
        ENDFOR
        
        ? "Conexiune nu a fost găsită în pool: " + TRANSFORM(tnHandle)
        RETURN .F.
    ENDPROC
    
    *================================================================
    * Metodă: CreateNewConnection
    * Scop: Creare conexiune ODBC nouă
    *================================================================
    PROTECTED PROCEDURE CreateNewConnection()
        LOCAL lnHandle, lnResult
        
        lnHandle = SQLSTRINGCONNECT(THIS.cConnectionString)
        
        IF lnHandle > 0
            * Setare timeout query
            lnResult = SQLSETPROP(lnHandle, "QueryTimeOut", 30)
            
            * Setare transaction mode
            lnResult = SQLSETPROP(lnHandle, "Transactions", 2)  && Manual
            
            * Setare batch mode
            lnResult = SQLSETPROP(lnHandle, "BatchMode", .T.)
            
            RETURN lnHandle
        ELSE
            ? "Eroare creare conexiune: " + TRANSFORM(AERROR(laError))
            RETURN -1
        ENDIF
    ENDPROC
    
    *================================================================
    * Metodă: IsConnectionValid
    * Scop: Verifică validitatea unei conexiuni
    *================================================================
    PROTECTED PROCEDURE IsConnectionValid(tnHandle)
        LOCAL lnResult
        
        TRY
            * Test simplu - execută query trivial
            lnResult = SQLEXEC(tnHandle, "SELECT 1 AS Test", "curTest")
            
            IF lnResult > 0
                USE IN SELECT("curTest")
                RETURN .T.
            ELSE
                RETURN .F.
            ENDIF
            
        CATCH
            RETURN .F.
        ENDTRY
    ENDPROC
    
    *================================================================
    * Metodă: CloseAll
    * Scop: Închide toate conexiunile din pool
    *================================================================
    PROCEDURE CloseAll()
        LOCAL i
        
        FOR i = 1 TO THIS.nPoolSize
            IF !ISNULL(THIS.aConnections[i, 1])
                SQLCLOSE(THIS.aConnections[i, 1])
                THIS.aConnections[i, 1] = .NULL.
                THIS.aConnections[i, 2] = .F.
            ENDIF
        ENDFOR
        
        THIS.nCurrentConnections = 0
        ? "Toate conexiunile au fost închise"
    ENDPROC
    
    *================================================================
    * Metodă: Destroy
    *================================================================
    PROCEDURE Destroy()
        THIS.CloseAll()
    ENDPROC
ENDDEFINE
```

### Utilizare Connection Pool

```foxpro
*====================================================================
* Exemplu utilizare Connection Pool
*====================================================================
PROCEDURE Example_ConnectionPool()
    LOCAL loPool, lnConn, lnResult
    
    * Creare pool cu 5 conexiuni
    TEXT TO lcConnStr NOSHOW
    Driver={ODBC Driver 18 for SQL Server};
    Server=localhost\SQLEXPRESS;
    Database=eFacturaDB;
    Trusted_Connection=yes;
    Encrypt=yes;
    TrustServerCertificate=yes;
    ENDTEXT
    
    loPool = CREATEOBJECT("ConnectionPool", lcConnStr, 5)
    
    * Obține conexiune
    lnConn = loPool.GetConnection()
    
    IF lnConn > 0
        * Execută query
        TEXT TO lcSQL NOSHOW
        SELECT TOP 100 
            IdFactura,
            NumarFactura,
            Data,
            Total
        FROM Facturi
        WHERE Data >= ?DATE() - 30
        ORDER BY Data DESC
        ENDTEXT
        
        lnResult = SQLEXEC(lnConn, lcSQL, "curFacturi")
        
        IF lnResult > 0
            ? "Query executat cu succes - " + TRANSFORM(RECCOUNT("curFacturi")) + " înregistrări"
            
            * Procesare date
            SELECT curFacturi
            BROWSE NOWAIT
            
            USE IN SELECT("curFacturi")
        ELSE
            ? "Eroare execuție query"
            AERROR(laError)
            ? laError[2]
        ENDIF
        
        * Eliberează conexiunea înapoi în pool
        loPool.ReleaseConnection(lnConn)
    ENDIF
    
    * Cleanup
    loPool.CloseAll()
    loPool = .NULL.
ENDPROC
```

### Variantă 2: Connection Pooling la nivel ODBC

```
Configurare în Registry pentru ODBC Connection Pooling:

1. Deschideți ODBC Data Source Administrator
2. Tab "Connection Pooling"
3. Selectați driver-ul (ex: "ODBC Driver 18 for SQL Server")
4. Setați "Pool Timeout" (ex: 60 secunde)
5. Enable pooling = "Yes"

Sau editare Registry:
HKEY_LOCAL_MACHINE\SOFTWARE\ODBC\ODBCINST.INI\ODBC Driver 18 for SQL Server
CPTimeout = REG_DWORD: 60
```

## Best Practices

### 1. Gestionare Timeout-uri
```foxpro
* Query timeout
SQLSETPROP(lnHandle, "QueryTimeOut", 30)

* Connection timeout - în connection string
"Connection Timeout=30;"
```

### 2. Transaction Management
```foxpro
* Manual transactions pentru control complet
SQLSETPROP(lnHandle, "Transactions", 2)

* Început tranzacție
SQLEXEC(lnHandle, "BEGIN TRANSACTION")

* Commit
SQLEXEC(lnHandle, "COMMIT TRANSACTION")

* Rollback
SQLEXEC(lnHandle, "ROLLBACK TRANSACTION")
```

### 3. Batch Processing
```foxpro
* Enable batch mode pentru performanță
SQLSETPROP(lnHandle, "BatchMode", .T.)
SQLSETPROP(lnHandle, "PacketSize", 8192)
```

### 4. Error Handling
```foxpro
LOCAL laError[1]

lnResult = SQLEXEC(lnHandle, lcSQL, "curResult")

IF lnResult < 0
    AERROR(laError)
    ? "SQL Error: " + laError[2]
    ? "ODBC Error: " + laError[3]
ENDIF
```

## Troubleshooting

### Problemă: "Driver not found"
**Soluție**: Instalați versiunea 32-bit a driverului ODBC

### Problemă: "Connection timeout"
**Soluție**: 
- Verificați conectivitatea la server
- Măriți timeout în connection string
- Verificați firewall și permisiuni

### Problemă: "SSL/TLS errors"
**Soluție**:
- Pentru SQL Server: Adăugați `TrustServerCertificate=yes` pentru testing
- Pentru producție, configurați certificate valide
- Verificați că TLS 1.2+ este activat pe server

### Problemă: "Pool exhausted"
**Soluție**:
- Măriți pool size
- Verificați că conexiunile sunt eliberate corect
- Implementați timeout pentru conexiuni abandonate

## Monitorizare Performanță

```foxpro
*====================================================================
* Monitorizare utilizare pool
*====================================================================
PROCEDURE MonitorPool(toPool)
    LOCAL i, lnInUse, lnAvailable
    
    lnInUse = 0
    lnAvailable = 0
    
    FOR i = 1 TO toPool.nPoolSize
        IF toPool.aConnections[i, 2]
            lnInUse = lnInUse + 1
        ELSE
            lnAvailable = lnAvailable + 1
        ENDIF
    ENDFOR
    
    ? "===== POOL STATUS ====="
    ? "Pool Size: " + TRANSFORM(toPool.nPoolSize)
    ? "In Use: " + TRANSFORM(lnInUse)
    ? "Available: " + TRANSFORM(lnAvailable)
    ? "Total Created: " + TRANSFORM(toPool.nCurrentConnections)
    ? "======================="
ENDPROC
```

## Resurse Suplimentare

- [Microsoft ODBC Driver Documentation](https://docs.microsoft.com/en-us/sql/connect/odbc/)
- [MySQL Connector/ODBC Documentation](https://dev.mysql.com/doc/connector-odbc/en/)
- [VFP SQLEXEC() Function](https://docs.microsoft.com/en-us/previous-versions/visualstudio/foxpro/)

## Contact

Pentru suport suplimentar, consultați documentația generală de modernizare.
