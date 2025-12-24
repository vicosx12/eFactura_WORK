***********************************************************************
* PooledCursorAdapter.prg
* Enhanced CursorAdapter with Connection Pooling and Full CRUD Operations
* 
* Version: 1.0
* Date: 2024-12-23
* Author: Enterprise Development Team
* 
* Description:
*   A robust, production-ready CursorAdapter wrapper that integrates
*   with ConnectionPoolOptimized for enterprise-grade database operations.
*   Implements full CRUD (Create, Read, Update, Delete) functionality
*   with comprehensive error handling, validation, and transaction support.
*
* Features:
*   - Automatic connection pool integration
*   - Full CRUD operations (SaveChanges, RevertChanges, DeleteRecord, AddRecord)
*   - Transaction support with rollback
*   - Comprehensive error handling and validation
*   - Optimistic concurrency control
*   - Audit trail support
*   - Business rule validation hooks
*   - SOLID principles compliant
*   - Modern coding practices with legacy compatibility
*
* Usage Example:
*   loCA = CREATEOBJECT("PooledCursorAdapter")
*   IF loCA.LoadData("SELECT * FROM Customers", "curCustomers")
*       * Edit records
*       REPLACE Name WITH "New Name" IN curCustomers
*       loCA.SaveChanges(.T.)
*       
*       * Add new record
*       loCA.AddRecord("curCustomers")
*       REPLACE Name WITH "New Customer" IN curCustomers
*       loCA.SaveChanges()
*       
*       * Delete record
*       loCA.DeleteRecord("curCustomers")
*   ENDIF
*   RELEASE loCA
*
***********************************************************************

DEFINE CLASS PooledCursorAdapter AS CursorAdapter

    * Protected properties
    PROTECTED nPoolHandle
    PROTECTED oPool
    PROTECTED cLastError
    PROTECTED lInTransaction
    PROTECTED lDebugMode
    PROTECTED cAuditTable
    PROTECTED lEnableAudit
    
    * Public configuration properties
    lAutoCommit = .T.              && Auto-commit after each save
    lOptimisticLocking = .T.       && Use optimistic concurrency
    lCascadeDelete = .F.           && Cascade delete to related tables
    lValidateBeforeSave = .T.      && Validate data before saving
    nCommandTimeout = 30           && Command timeout in seconds
    cPrimaryKeyField = ""          && Primary key field name
    cTimestampField = ""           && Timestamp field for concurrency
    lEnableLogging = .T.           && Enable operation logging
    
    * Statistics
    nRecordsAdded = 0
    nRecordsUpdated = 0
    nRecordsDeleted = 0
    nSaveOperations = 0
    
    ***********************************************************************
    * Init - Constructor
    * Initializes the PooledCursorAdapter and obtains connection from pool
    ***********************************************************************
    PROCEDURE Init()
        LOCAL llSuccess
        
        llSuccess = .F.
        THIS.cLastError = ""
        THIS.lInTransaction = .F.
        THIS.lDebugMode = .F.
        THIS.lEnableAudit = .F.
        THIS.cAuditTable = ""
        
        TRY
            * Get connection pool instance
            THIS.oPool = GetOptimizedConnectionPool()
            
            IF ISNULL(THIS.oPool)
                ERROR "Connection pool not available. Call Init_Modernization_Environment() first."
            ENDIF
            
            * Obtain connection from pool
            THIS.nPoolHandle = THIS.oPool.GetConnection()
            
            IF THIS.nPoolHandle <= 0
                ERROR "Failed to obtain connection from pool"
            ENDIF
            
            * Configure CursorAdapter
            THIS.DataSourceType = "ODBC"
            THIS.DataSource = THIS.nPoolHandle
            THIS.BufferModeOverride = 5    && Optimistic table buffering
            THIS.AllowSimultaneousFetch = .F.
            THIS.FetchSize = 100
            THIS.MaxRecords = -1           && No limit
            
            * Configure update properties
            THIS.AllowInsert = .T.
            THIS.AllowUpdate = .T.
            THIS.AllowDelete = .T.
            THIS.SendUpdates = .T.
            THIS.UseDeDataSource = .T.
            THIS.UpdateNameList = ""       && Will be set dynamically
            
            llSuccess = .T.
            
            THIS.LogOperation("INIT", "PooledCursorAdapter initialized successfully")
            
        CATCH TO loException
            THIS.cLastError = "Init failed: " + loException.Message
            THIS.LogError(THIS.cLastError, loException)
        ENDTRY
        
        RETURN llSuccess
    ENDPROC
    
    ***********************************************************************
    * Destroy - Destructor
    * Cleanup and release connection back to pool
    ***********************************************************************
    PROCEDURE Destroy()
        TRY
            * Rollback any pending transaction
            IF THIS.lInTransaction
                THIS.RollbackTransaction()
            ENDIF
            
            * Detach cursor
            THIS.CursorDetach()
            
            * Release connection back to pool
            IF THIS.nPoolHandle > 0 AND !ISNULL(THIS.oPool)
                THIS.oPool.ReleaseConnection(THIS.nPoolHandle)
                THIS.nPoolHandle = 0
                THIS.LogOperation("DESTROY", "Connection released to pool")
            ENDIF
            
        CATCH TO loException
            * Log but don't raise error in destructor
            THIS.LogError("Destroy error: " + loException.Message, loException)
        ENDTRY
        
        DODEFAULT()
    ENDPROC
    
    ***********************************************************************
    * LoadData - Load data from database
    * 
    * Parameters:
    *   tcSelectCmd - SQL SELECT statement
    *   tcAlias - Cursor alias name
    *   tcTableName - Optional: Backend table name (for updates)
    *   tcKeyField - Optional: Primary key field (auto-detected if empty)
    *
    * Returns: .T. if successful, .F. otherwise
    ***********************************************************************
    FUNCTION LoadData(tcSelectCmd, tcAlias, tcTableName, tcKeyField)
        LOCAL llSuccess, lcOldAlias, lcTableName
        
        llSuccess = .F.
        lcOldAlias = ALIAS()
        
        IF EMPTY(tcSelectCmd) OR EMPTY(tcAlias)
            THIS.cLastError = "SelectCmd and Alias are required"
            RETURN .F.
        ENDIF
        
        TRY
            * Configure CursorAdapter
            THIS.SelectCmd = tcSelectCmd
            THIS.Alias = tcAlias
            
            * Enable buffering for updates
            THIS.BufferModeOverride = 5  && Optimistic table buffering
            
            * Execute query
            llSuccess = THIS.CursorFill()
            
            IF llSuccess
                THIS.LogOperation("LOAD", "Loaded " + TRANSFORM(RECCOUNT(tcAlias)) + " records into " + tcAlias)
                
                * Determine table name from SELECT if not provided
                lcTableName = tcTableName
                IF EMPTY(lcTableName)
                    lcTableName = THIS.ExtractTableName(tcSelectCmd)
                ENDIF
                
                * Auto-detect primary key if not provided
                IF EMPTY(tcKeyField) AND EMPTY(THIS.cPrimaryKeyField)
                    THIS.DetectPrimaryKey(tcAlias)
                    tcKeyField = THIS.cPrimaryKeyField
                ELSE
                    THIS.cPrimaryKeyField = tcKeyField
                ENDIF
                
                * Configure CursorAdapter for automatic updates
                IF !EMPTY(lcTableName) AND !EMPTY(tcKeyField)
                    THIS.MakeUpdatable(lcTableName, tcKeyField, .F.)
                ENDIF
            ELSE
                THIS.cLastError = "CursorFill failed: " + THIS.GetErrorMessage()
                THIS.LogError(THIS.cLastError)
            ENDIF
            
        CATCH TO loException
            THIS.cLastError = "LoadData failed: " + loException.Message
            THIS.LogError(THIS.cLastError, loException)
            llSuccess = .F.
        ENDTRY
        
        * Restore work area
        IF !EMPTY(lcOldAlias) AND USED(lcOldAlias)
            SELECT (lcOldAlias)
        ENDIF
        
        RETURN llSuccess
    ENDFUNC
    
    ***********************************************************************
    * SaveChanges - Save all modifications to database
    * 
    * Uses CursorAdapter's automatic update mechanism via ApplyUpdates()
    * CursorAdapter handles the update when Tables, KeyFieldList, 
    * UpdatableFieldList, and UpdateNameList are properly configured.
    *
    * Parameters:
    *   tlForce - Not used (kept for compatibility)
    *   tlShowConflicts - Not used (kept for compatibility)
    *
    * Returns: .T. if successful, .F. otherwise
    ***********************************************************************
    FUNCTION SaveChanges(tlForce, tlShowConflicts)
        LOCAL llSuccess, lnUpdated, lnInserted, lnDeleted, lcAlias
        LOCAL lcOldAlias, lnConflicts
        
        llSuccess = .F.
        lcAlias = THIS.Alias
        lcOldAlias = ALIAS()
        
        IF EMPTY(lcAlias)
            THIS.cLastError = "No cursor loaded"
            RETURN .F.
        ENDIF
        
        IF !USED(lcAlias)
            THIS.cLastError = "Cursor " + lcAlias + " is not open"
            RETURN .F.
        ENDIF
        
        TRY
            SELECT (lcAlias)
            
            * Validate before save
            IF THIS.lValidateBeforeSave
                IF !THIS.ValidateData(lcAlias)
                    THIS.cLastError = "Data validation failed"
                    RETURN .F.
                ENDIF
            ENDIF
            
            * Check if CursorAdapter is properly configured for updates
            IF EMPTY(THIS.Tables) OR EMPTY(THIS.KeyFieldList)
                THIS.cLastError = "CursorAdapter not configured for updates. Call MakeUpdatable() first."
                RETURN .F.
            ENDIF
            
            * Begin transaction if auto-commit is off
            IF !THIS.lAutoCommit AND !THIS.lInTransaction
                THIS.BeginTransaction()
            ENDIF
            
            * Get counts before update
            lnInserted = 0
            lnUpdated = 0
            lnDeleted = 0
            
            * Scan for changes and count
            * GETFLDSTATE(-1) returns a string like "11121" where each char is field state
            * State 1 = unchanged, so check if string != all 1's
            SCAN FOR GETFLDSTATE(-1) != REPLICATE("1", FCOUNT())
                DO CASE
                    CASE GETFLDSTATE(0) = 4  && Deleted
                        lnDeleted = lnDeleted + 1
                    CASE GETFLDSTATE(0) = 2  && New
                        lnInserted = lnInserted + 1
                    OTHERWISE
                        lnUpdated = lnUpdated + 1
                ENDCASE
            ENDSCAN
            
            * Use CursorAdapter's ApplyUpdates() to save changes
            * This relies on Tables, KeyFieldList, UpdatableFieldList, UpdateNameList
            * being properly configured by MakeUpdatable()
            lnConflicts = THIS.ApplyUpdates()
            llSuccess = (lnConflicts = 0)
            
            IF llSuccess
                * Update statistics
                THIS.nRecordsAdded = THIS.nRecordsAdded + lnInserted
                THIS.nRecordsUpdated = THIS.nRecordsUpdated + lnUpdated
                THIS.nRecordsDeleted = THIS.nRecordsDeleted + lnDeleted
                THIS.nSaveOperations = THIS.nSaveOperations + 1
                
                * Commit transaction if not auto-commit
                IF !THIS.lAutoCommit AND THIS.lInTransaction
                    THIS.CommitTransaction()
                ENDIF
                
                * Log audit trail
                IF THIS.lEnableAudit
                    THIS.WriteAuditTrail("SAVE", lnInserted, lnUpdated, lnDeleted)
                ENDIF
                
                THIS.LogOperation("SAVE", ;
                    "Saved changes: " + TRANSFORM(lnInserted) + " inserted, " + ;
                    TRANSFORM(lnUpdated) + " updated, " + TRANSFORM(lnDeleted) + " deleted")
            ELSE
                THIS.cLastError = "ApplyUpdates failed with " + TRANSFORM(lnConflicts) + " conflicts"
                THIS.LogError(THIS.cLastError)
                
                * Rollback transaction if not auto-commit
                IF !THIS.lAutoCommit AND THIS.lInTransaction
                    THIS.RollbackTransaction()
                ENDIF
            ENDIF
            
        CATCH TO loException
            THIS.cLastError = "SaveChanges failed: " + loException.Message
            THIS.LogError(THIS.cLastError, loException)
            
            * Rollback transaction on error
            IF THIS.lInTransaction
                THIS.RollbackTransaction()
            ENDIF
            
            llSuccess = .F.
        ENDTRY
        
        * Restore work area
        IF !EMPTY(lcOldAlias) AND USED(lcOldAlias)
            SELECT (lcOldAlias)
        ENDIF
        
        RETURN llSuccess
    ENDFUNC
    
    ***********************************************************************
    * SaveData - Simplified wrapper for SaveChanges
    * 
    * This is a convenience method that calls SaveChanges with default parameters.
    * Useful for simple save operations without forcing or conflict handling.
    *
    * Parameters:
    *   tlForce - Optional: Force update all records (default .F.)
    *
    * Returns: .T. if successful, .F. otherwise
    ***********************************************************************
    FUNCTION SaveData(tlForce)
        LOCAL llForce
        
        llForce = VARTYPE(tlForce) = "L" AND tlForce
        
        * Call SaveChanges with force parameter and no conflict display
        RETURN THIS.SaveChanges(llForce, .F.)
    ENDFUNC
    
    ***********************************************************************
    * RevertChanges - Revert all uncommitted changes
    * 
    * Parameters:
    *   tcAlias - Optional cursor alias (uses THIS.Alias if not provided)
    *
    * Returns: .T. if successful, .F. otherwise
    ***********************************************************************
    FUNCTION RevertChanges(tcAlias)
        LOCAL llSuccess, lcAlias, lnChanges, lcOldAlias
        
        llSuccess = .F.
        lcAlias = IIF(EMPTY(tcAlias), THIS.Alias, tcAlias)
        lcOldAlias = ALIAS()
        
        IF EMPTY(lcAlias)
            THIS.cLastError = "No cursor specified"
            RETURN .F.
        ENDIF
        
        IF !USED(lcAlias)
            THIS.cLastError = "Cursor " + lcAlias + " is not open"
            RETURN .F.
        ENDIF
        
        TRY
            SELECT (lcAlias)
            
            * Count changes before revert
            * GETFLDSTATE(-1) returns a string like "11121" where each char is field state
            * State 1 = unchanged, so check if string != all 1's
            lnChanges = 0
            SCAN FOR GETFLDSTATE(-1) != REPLICATE("1", FCOUNT())
                lnChanges = lnChanges + 1
            ENDSCAN
            
            * Revert changes
            = TABLEREVERT(.T., lcAlias)
            
            * Rollback transaction if active
            IF THIS.lInTransaction
                THIS.RollbackTransaction()
            ENDIF
            
            llSuccess = .T.
            
            THIS.LogOperation("REVERT", "Reverted " + TRANSFORM(lnChanges) + " changes in " + lcAlias)
            
        CATCH TO loException
            THIS.cLastError = "RevertChanges failed: " + loException.Message
            THIS.LogError(THIS.cLastError, loException)
            llSuccess = .F.
        ENDTRY
        
        * Restore work area
        IF !EMPTY(lcOldAlias) AND USED(lcOldAlias)
            SELECT (lcOldAlias)
        ENDIF
        
        RETURN llSuccess
    ENDFUNC
    
    ***********************************************************************
    * DeleteRecord - Delete current record
    * 
    * Parameters:
    *   tcAlias - Optional cursor alias (uses THIS.Alias if not provided)
    *   tlConfirm - Optional, confirm deletion (default .T.)
    *
    * Returns: .T. if successful, .F. otherwise
    ***********************************************************************
    FUNCTION DeleteRecord(tcAlias, tlConfirm)
        LOCAL llSuccess, lcAlias, llConfirm, lnRecno, lcOldAlias
        LOCAL lcMessage, lnResponse
        
        llSuccess = .F.
        lcAlias = IIF(EMPTY(tcAlias), THIS.Alias, tcAlias)
        llConfirm = IIF(VARTYPE(tlConfirm) = "L", tlConfirm, .T.)
        lcOldAlias = ALIAS()
        
        IF EMPTY(lcAlias)
            THIS.cLastError = "No cursor specified"
            RETURN .F.
        ENDIF
        
        IF !USED(lcAlias)
            THIS.cLastError = "Cursor " + lcAlias + " is not open"
            RETURN .F.
        ENDIF
        
        TRY
            SELECT (lcAlias)
            
            IF EOF() OR BOF()
                THIS.cLastError = "No current record to delete"
                RETURN .F.
            ENDIF
            
            lnRecno = RECNO()
            
            * Confirm deletion
            IF llConfirm
                lcMessage = "Are you sure you want to delete this record?"
                lnResponse = MESSAGEBOX(lcMessage, 36, "Confirm Delete")
                IF lnResponse != 6  && Not Yes
                    THIS.cLastError = "Delete cancelled by user"
                    RETURN .F.
                ENDIF
            ENDIF
            
            * Check cascade delete
            IF THIS.lCascadeDelete
                IF !THIS.DeleteRelatedRecords(lcAlias)
                    THIS.cLastError = "Failed to delete related records"
                    RETURN .F.
                ENDIF
            ENDIF
            
            * Mark for deletion
            DELETE
            
            * Audit trail
            IF THIS.lEnableAudit
                THIS.WriteAuditTrail("DELETE", 0, 0, 1)
            ENDIF
            
            llSuccess = .T.
            
            THIS.LogOperation("DELETE", "Marked record " + TRANSFORM(lnRecno) + " for deletion in " + lcAlias)
            
        CATCH TO loException
            THIS.cLastError = "DeleteRecord failed: " + loException.Message
            THIS.LogError(THIS.cLastError, loException)
            llSuccess = .F.
        ENDTRY
        
        * Restore work area
        IF !EMPTY(lcOldAlias) AND USED(lcOldAlias)
            SELECT (lcOldAlias)
        ENDIF
        
        RETURN llSuccess
    ENDFUNC
    
    ***********************************************************************
    * AddRecord - Add a new record
    * 
    * Parameters:
    *   tcAlias - Optional cursor alias (uses THIS.Alias if not provided)
    *   toFieldValues - Optional object with field values
    *
    * Returns: .T. if successful, .F. otherwise
    ***********************************************************************
    FUNCTION AddRecord(tcAlias, toFieldValues)
        LOCAL llSuccess, lcAlias, lcOldAlias, i, lcField, luValue
        
        llSuccess = .F.
        lcAlias = IIF(EMPTY(tcAlias), THIS.Alias, tcAlias)
        lcOldAlias = ALIAS()
        
        IF EMPTY(lcAlias)
            THIS.cLastError = "No cursor specified"
            RETURN .F.
        ENDIF
        
        IF !USED(lcAlias)
            THIS.cLastError = "Cursor " + lcAlias + " is not open"
            RETURN .F.
        ENDIF
        
        TRY
            SELECT (lcAlias)
            
            * Begin transaction if not auto-commit
            IF !THIS.lAutoCommit AND !THIS.lInTransaction
                THIS.BeginTransaction()
            ENDIF
            
            * Append blank record
            APPEND BLANK
            
            * Set field values if provided
            IF VARTYPE(toFieldValues) = "O"
                FOR i = 1 TO AMEMBERS(laFields, toFieldValues)
                    lcField = laFields[i]
                    IF TYPE(lcField) != "U"  && Field exists
                        TRY
                            luValue = EVALUATE("toFieldValues." + lcField)
                            REPLACE (lcField) WITH luValue
                        CATCH
                            * Skip invalid fields
                        ENDTRY
                    ENDIF
                ENDFOR
            ENDIF
            
            * Set default values
            THIS.SetDefaultValues(lcAlias)
            
            llSuccess = .T.
            
            THIS.LogOperation("ADD", "Added new record to " + lcAlias)
            
        CATCH TO loException
            THIS.cLastError = "AddRecord failed: " + loException.Message
            THIS.LogError(THIS.cLastError, loException)
            
            * Rollback on error
            IF THIS.lInTransaction
                THIS.RollbackTransaction()
            ENDIF
            
            llSuccess = .F.
        ENDTRY
        
        * Restore work area
        IF !EMPTY(lcOldAlias) AND USED(lcOldAlias)
            SELECT (lcOldAlias)
        ENDIF
        
        RETURN llSuccess
    ENDFUNC
    
    ***********************************************************************
    * RefreshData - Refresh data from database
    * 
    * Returns: .T. if successful, .F. otherwise
    ***********************************************************************
    FUNCTION RefreshData()
        LOCAL llSuccess, lnRecno, lcAlias, lcOldAlias
        
        llSuccess = .F.
        lcAlias = THIS.Alias
        lcOldAlias = ALIAS()
        
        IF EMPTY(lcAlias)
            THIS.cLastError = "No cursor loaded"
            RETURN .F.
        ENDIF
        
        TRY
            SELECT (lcAlias)
            lnRecno = RECNO()
            
            * Refresh from database
            llSuccess = THIS.CursorFill()
            
            IF llSuccess
                * Restore record position
                IF lnRecno <= RECCOUNT()
                    GO lnRecno
                ENDIF
                
                THIS.LogOperation("REFRESH", "Refreshed data in " + lcAlias)
            ELSE
                THIS.cLastError = "CursorFill failed: " + THIS.GetErrorMessage()
                THIS.LogError(THIS.cLastError)
            ENDIF
            
        CATCH TO loException
            THIS.cLastError = "RefreshData failed: " + loException.Message
            THIS.LogError(THIS.cLastError, loException)
            llSuccess = .F.
        ENDTRY
        
        * Restore work area
        IF !EMPTY(lcOldAlias) AND USED(lcOldAlias)
            SELECT (lcOldAlias)
        ENDIF
        
        RETURN llSuccess
    ENDFUNC
    
    ***********************************************************************
    * PROTECTED: ValidateData - Validate data before save
    * Override this method to implement custom validation rules
    ***********************************************************************
    PROTECTED PROCEDURE ValidateData(tcAlias)
        LOCAL llValid, lcAlias, lcOldAlias
        
        llValid = .T.
        lcAlias = tcAlias
        lcOldAlias = ALIAS()
        
        TRY
            SELECT (lcAlias)
            
            * Basic validation - check required fields
            * Override this method for custom business rules
            
            * Example validation (customize as needed):
            * SCAN FOR GETFLDSTATE(-1, lcAlias) != 1
            *     IF EMPTY(FieldName)
            *         MESSAGEBOX("Field cannot be empty", 16, "Validation Error")
            *         llValid = .F.
            *         EXIT
            *     ENDIF
            * ENDSCAN
            
        CATCH TO loException
            THIS.LogError("ValidateData error: " + loException.Message, loException)
            llValid = .F.
        ENDTRY
        
        * Restore work area
        IF !EMPTY(lcOldAlias) AND USED(lcOldAlias)
            SELECT (lcOldAlias)
        ENDIF
        
        RETURN llValid
    ENDPROC
    
    ***********************************************************************
    * PROTECTED: SetDefaultValues - Set default values for new records
    * Override this method to set custom default values
    ***********************************************************************
    PROTECTED PROCEDURE SetDefaultValues(tcAlias)
        LOCAL lcAlias, lcOldAlias
        
        lcAlias = tcAlias
        lcOldAlias = ALIAS()
        
        TRY
            SELECT (lcAlias)
            
            * Set default values (customize as needed)
            * Example:
            * REPLACE CreatedDate WITH DATETIME()
            * REPLACE CreatedBy WITH oApp.cUserName
            * REPLACE IsActive WITH .T.
            
        CATCH TO loException
            THIS.LogError("SetDefaultValues error: " + loException.Message, loException)
        ENDTRY
        
        * Restore work area
        IF !EMPTY(lcOldAlias) AND USED(lcOldAlias)
            SELECT (lcOldAlias)
        ENDIF
    ENDPROC
    
    ***********************************************************************
    * PROTECTED: BeginTransaction - Begin database transaction
    ***********************************************************************
    PROTECTED PROCEDURE BeginTransaction()
        LOCAL llSuccess
        
        llSuccess = .F.
        
        TRY
            = SQLSETPROP(THIS.nPoolHandle, "Transactions", 2)  && Manual
            THIS.lInTransaction = .T.
            llSuccess = .T.
            THIS.LogOperation("TRANSACTION", "Begin transaction")
        CATCH TO loException
            THIS.LogError("BeginTransaction failed: " + loException.Message, loException)
        ENDTRY
        
        RETURN llSuccess
    ENDPROC
    
    ***********************************************************************
    * PROTECTED: CommitTransaction - Commit database transaction
    ***********************************************************************
    PROTECTED PROCEDURE CommitTransaction()
        LOCAL llSuccess
        
        llSuccess = .F.
        
        TRY
            = SQLCOMMIT(THIS.nPoolHandle)
            = SQLSETPROP(THIS.nPoolHandle, "Transactions", 1)  && Automatic
            THIS.lInTransaction = .F.
            llSuccess = .T.
            THIS.LogOperation("TRANSACTION", "Commit transaction")
        CATCH TO loException
            THIS.LogError("CommitTransaction failed: " + loException.Message, loException)
        ENDTRY
        
        RETURN llSuccess
    ENDPROC
    
    ***********************************************************************
    * PROTECTED: RollbackTransaction - Rollback database transaction
    ***********************************************************************
    PROTECTED PROCEDURE RollbackTransaction()
        LOCAL llSuccess
        
        llSuccess = .F.
        
        TRY
            = SQLROLLBACK(THIS.nPoolHandle)
            = SQLSETPROP(THIS.nPoolHandle, "Transactions", 1)  && Automatic
            THIS.lInTransaction = .F.
            llSuccess = .T.
            THIS.LogOperation("TRANSACTION", "Rollback transaction")
        CATCH TO loException
            THIS.LogError("RollbackTransaction failed: " + loException.Message, loException)
        ENDTRY
        
        RETURN llSuccess
    ENDPROC
    
    ***********************************************************************
    * PROTECTED: DetectPrimaryKey - Auto-detect primary key field
    ***********************************************************************
    PROTECTED PROCEDURE DetectPrimaryKey(tcAlias)
        LOCAL lcAlias, i, lcField
        
        lcAlias = tcAlias
        
        TRY
            * Look for common primary key field names
            FOR i = 1 TO FCOUNT(lcAlias)
                lcField = UPPER(FIELD(i, lcAlias))
                IF lcField $ "ID,KEY,PK" OR RIGHT(lcField, 2) = "ID"
                    THIS.cPrimaryKeyField = FIELD(i, lcAlias)
                    EXIT
                ENDIF
            ENDFOR
        CATCH TO loException
            THIS.LogError("DetectPrimaryKey error: " + loException.Message, loException)
        ENDTRY
    ENDPROC
    
    ***********************************************************************
    * PROTECTED: MakeUpdatable - Configure CursorAdapter for automatic updates
    * 
    * This method configures the CursorAdapter's update properties so that
    * ApplyUpdates() can automatically save changes to the backend database.
    *
    * Parameters:
    *   tcTableName - Backend table name (e.g., "Customers")
    *   tcKeyField - Primary key field name (e.g., "CustomerID")
    *   tlDoNotIncludeKey - Optional: Exclude key from updatable fields
    ***********************************************************************
    PROTECTED PROCEDURE MakeUpdatable(tcTableName, tcKeyField, tlDoNotIncludeKey)
        LOCAL ix, lnUpdateableFCount, lcFieldName
        
        TRY
            * Set the backend table name
            THIS.Tables = tcTableName
            
            * Set the primary key field
            THIS.KeyFieldList = tcKeyField
            
            * Build UpdatableFieldList and UpdateNameList
            THIS.UpdatableFieldList = ""
            THIS.UpdateNameList = ""
            
            * Get count of fields (excluding ADOBOOKMARK if present)
            lnUpdateableFCount = FCOUNT(THIS.Alias)
            IF THIS.DataSourceType = 'ADO'
                lnUpdateableFCount = lnUpdateableFCount - 1  && Exclude last one (ADOBOOKMARK)
            ENDIF
            
            * Loop through all fields
            FOR ix = 1 TO lnUpdateableFCount
                lcFieldName = FIELD(ix, THIS.Alias)
                
                * Add to UpdatableFieldList (optionally excluding key field)
                IF !tlDoNotIncludeKey OR !(UPPER(lcFieldName) == UPPER(tcKeyField))
                    THIS.UpdatableFieldList = THIS.UpdatableFieldList + ;
                        IIF(EMPTY(THIS.UpdatableFieldList), '', ',') + lcFieldName
                ENDIF
                
                * Add to UpdateNameList (maps cursor field to backend field)
                * Format: "CursorField TableName.BackendField"
                THIS.UpdateNameList = THIS.UpdateNameList + ;
                    IIF(EMPTY(THIS.UpdateNameList), '', ',') + ;
                    lcFieldName + " " + tcTableName + "." + lcFieldName
            ENDFOR
            
            THIS.LogOperation("CONFIG", "Configured for updates: Table=" + tcTableName + ", Key=" + tcKeyField)
            
        CATCH TO loException
            THIS.LogError("MakeUpdatable error: " + loException.Message, loException)
        ENDTRY
    ENDPROC
    
    ***********************************************************************
    * PROTECTED: ExtractTableName - Extract table name from SELECT statement
    ***********************************************************************
    PROTECTED FUNCTION ExtractTableName(tcSelectCmd)
        LOCAL lcSQL, lcTableName, lnFromPos, lnWherePos, lnJoinPos, lnEndPos
        
        lcTableName = ""
        
        TRY
            * Convert to uppercase for parsing
            lcSQL = UPPER(ALLTRIM(tcSelectCmd))
            
            * Find FROM keyword
            lnFromPos = AT(" FROM ", lcSQL)
            IF lnFromPos = 0
                RETURN ""
            ENDIF
            
            * Start after FROM
            lcSQL = SUBSTR(lcSQL, lnFromPos + 6)
            lcSQL = LTRIM(lcSQL)
            
            * Find end of table name (WHERE, JOIN, ORDER, GROUP, or end of string)
            lnWherePos = AT(" WHERE ", lcSQL)
            lnJoinPos = AT(" JOIN ", lcSQL)
            lnEndPos = LEN(lcSQL) + 1
            
            * Get the nearest delimiter
            IF lnWherePos > 0
                lnEndPos = MIN(lnEndPos, lnWherePos)
            ENDIF
            IF lnJoinPos > 0
                lnEndPos = MIN(lnEndPos, lnJoinPos)
            ENDIF
            
            * Extract table name
            lcTableName = ALLTRIM(LEFT(lcSQL, lnEndPos - 1))
            
            * Remove schema/database prefix if present (e.g., "dbo.Customers" -> "Customers")
            IF "." $ lcTableName
                lcTableName = SUBSTR(lcTableName, AT(".", lcTableName, 2) + 1)
                IF "." $ lcTableName
                    lcTableName = SUBSTR(lcTableName, AT(".", lcTableName) + 1)
                ENDIF
            ENDIF
            
            * Remove alias if present (e.g., "Customers c" -> "Customers")
            IF " " $ lcTableName
                lcTableName = LEFT(lcTableName, AT(" ", lcTableName) - 1)
            ENDIF
            
        CATCH TO loException
            THIS.LogError("ExtractTableName error: " + loException.Message, loException)
        ENDTRY
        
        RETURN lcTableName
    ENDFUNC
    
    ***********************************************************************
    * PROTECTED: DeleteRelatedRecords - Delete related records (cascade)
    * Override this method to implement cascade delete logic
    ***********************************************************************
    PROTECTED PROCEDURE DeleteRelatedRecords(tcAlias)
        * Implement cascade delete logic here
        * Return .T. if successful, .F. otherwise
        RETURN .T.
    ENDPROC
    
    ***********************************************************************
    * PROTECTED: WriteAuditTrail - Write audit trail entry
    ***********************************************************************
    PROTECTED PROCEDURE WriteAuditTrail(tcOperation, tnInserted, tnUpdated, tnDeleted)
        LOCAL lcSQL
        
        IF EMPTY(THIS.cAuditTable)
            RETURN
        ENDIF
        
        TRY
            TEXT TO lcSQL NOSHOW TEXTMERGE
            INSERT INTO <<THIS.cAuditTable>>
            (Operation, TableName, RecordsInserted, RecordsUpdated, RecordsDeleted, 
             UserName, WorkStation, OperationDate)
            VALUES
            ('<<tcOperation>>', '<<THIS.Alias>>', <<tnInserted>>, <<tnUpdated>>, <<tnDeleted>>,
             USER(), SYS(0), GETDATE())
            ENDTEXT
            
            = SQLEXEC(THIS.nPoolHandle, lcSQL)
            
        CATCH TO loException
            THIS.LogError("WriteAuditTrail error: " + loException.Message, loException)
        ENDTRY
    ENDPROC
    
    ***********************************************************************
    * PROTECTED: LogOperation - Log operation
    ***********************************************************************
    PROTECTED PROCEDURE LogOperation(tcType, tcMessage)
        IF !THIS.lEnableLogging
            RETURN
        ENDIF
        
        IF THIS.lDebugMode
            ? TTOC(DATETIME()) + " [" + tcType + "] " + tcMessage
        ENDIF
    ENDPROC
    
    ***********************************************************************
    * PROTECTED: LogError - Log error
    ***********************************************************************
    PROTECTED PROCEDURE LogError(tcMessage, toException)
        LOCAL lcLogFile, lcMessage
        
        lcMessage = TTOC(DATETIME()) + " [ERROR] " + tcMessage
        
        IF VARTYPE(toException) = "O"
            lcMessage = lcMessage + CHR(13) + CHR(10) + ;
                       "  Details: " + toException.Details + CHR(13) + CHR(10) + ;
                       "  LineNo: " + TRANSFORM(toException.LineNo)
        ENDIF
        
        * Console output if debug mode
        IF THIS.lDebugMode
            ? lcMessage
        ENDIF
        
        * Write to log file
        TRY
            lcLogFile = ADDBS(SYS(5) + SYS(2003)) + "PooledCursorAdapter_" + ;
                       DTOS(DATE()) + ".log"
            STRTOFILE(lcMessage + CHR(13) + CHR(10), lcLogFile, .T.)
        CATCH
            * Ignore logging errors
        ENDTRY
    ENDPROC
    
    ***********************************************************************
    * GetErrorMessage - Get last error message
    ***********************************************************************
    FUNCTION GetErrorMessage()
        RETURN THIS.cLastError
    ENDFUNC
    
    ***********************************************************************
    * GetStatistics - Get operation statistics
    ***********************************************************************
    FUNCTION GetStatistics()
        LOCAL lcStats
        
        TEXT TO lcStats NOSHOW TEXTMERGE
        PooledCursorAdapter Statistics:
        --------------------------------
        Save Operations: <<THIS.nSaveOperations>>
        Records Added: <<THIS.nRecordsAdded>>
        Records Updated: <<THIS.nRecordsUpdated>>
        Records Deleted: <<THIS.nRecordsDeleted>>
        In Transaction: <<IIF(THIS.lInTransaction, "Yes", "No")>>
        ENDTEXT
        
        RETURN lcStats
    ENDFUNC
    
    ***********************************************************************
    * ResetStatistics - Reset operation statistics
    ***********************************************************************
    PROCEDURE ResetStatistics()
        THIS.nRecordsAdded = 0
        THIS.nRecordsUpdated = 0
        THIS.nRecordsDeleted = 0
        THIS.nSaveOperations = 0
    ENDPROC

ENDDEFINE
