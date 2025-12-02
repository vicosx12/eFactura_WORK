*====================================================================
* TenantManager - Multi-tenancy Support
* 
* Features:
* - Multiple company/CUI support in single instance
* - Tenant isolation
* - Tenant-specific configuration
* - Cross-tenant operations
*
* Visual FoxPro 9 SP2 Compatible
*====================================================================

Define Class TenantManager As Custom
    
    * Current tenant
    cCurrentTenantId = ""
    oCurrentTenant = .Null.
    
    * Registered tenants
    Dimension aTenants[1, 5]  && Id, Name, CUI, Database, Config
    nTenantCount = 0
    
    * Configuration
    lMultiTenantEnabled = .T.
    cDefaultTenantId = "default"
    lIsolateData = .T.
    
    * Logger
    oLogger = .Null.
    
    *----------------------------------------------------------------
    * Init
    *----------------------------------------------------------------
    Procedure Init
        This.oLogger = CreateObject("LoggerService")
        
        * Register default tenant
        This.RegisterTenant(This.cDefaultTenantId, "Default", "", "", .Null.)
        This.SetCurrentTenant(This.cDefaultTenantId)
    EndProc
    
    *----------------------------------------------------------------
    * RegisterTenant - Register a new tenant
    *----------------------------------------------------------------
    Procedure RegisterTenant(tcTenantId, tcName, tcCUI, tcDatabase, toConfig)
        Local lnIndex
        
        lnIndex = This.FindTenant(tcTenantId)
        
        If lnIndex = 0
            This.nTenantCount = This.nTenantCount + 1
            lnIndex = This.nTenantCount
            Dimension This.aTenants[This.nTenantCount, 5]
        EndIf
        
        This.aTenants[lnIndex, 1] = tcTenantId
        This.aTenants[lnIndex, 2] = tcName
        This.aTenants[lnIndex, 3] = tcCUI
        This.aTenants[lnIndex, 4] = tcDatabase
        This.aTenants[lnIndex, 5] = toConfig
        
        This.oLogger.LogInfo("Tenant înregistrat: " + tcName + " (CUI: " + tcCUI + ")")
        
        Return lnIndex
    EndProc
    
    *----------------------------------------------------------------
    * UnregisterTenant - Remove tenant
    *----------------------------------------------------------------
    Procedure UnregisterTenant(tcTenantId)
        Local lnIndex, i, lnNewCount
        Dimension laNew[1, 5]
        
        If tcTenantId = This.cDefaultTenantId
            This.oLogger.LogWarning("Nu se poate șterge tenant-ul implicit")
            Return .F.
        EndIf
        
        lnNewCount = 0
        
        For i = 1 To This.nTenantCount
            If This.aTenants[i, 1] <> tcTenantId
                lnNewCount = lnNewCount + 1
                Dimension laNew[lnNewCount, 5]
                laNew[lnNewCount, 1] = This.aTenants[i, 1]
                laNew[lnNewCount, 2] = This.aTenants[i, 2]
                laNew[lnNewCount, 3] = This.aTenants[i, 3]
                laNew[lnNewCount, 4] = This.aTenants[i, 4]
                laNew[lnNewCount, 5] = This.aTenants[i, 5]
            EndIf
        Next
        
        This.nTenantCount = lnNewCount
        Dimension This.aTenants[Max(1, lnNewCount), 5]
        
        For i = 1 To lnNewCount
            This.aTenants[i, 1] = laNew[i, 1]
            This.aTenants[i, 2] = laNew[i, 2]
            This.aTenants[i, 3] = laNew[i, 3]
            This.aTenants[i, 4] = laNew[i, 4]
            This.aTenants[i, 5] = laNew[i, 5]
        Next
        
        * Switch to default if current tenant was removed
        If This.cCurrentTenantId = tcTenantId
            This.SetCurrentTenant(This.cDefaultTenantId)
        EndIf
        
        Return .T.
    EndProc
    
    *----------------------------------------------------------------
    * FindTenant - Find tenant by ID
    *----------------------------------------------------------------
    Protected Procedure FindTenant(tcTenantId)
        Local i
        
        For i = 1 To This.nTenantCount
            If This.aTenants[i, 1] = tcTenantId
                Return i
            EndIf
        Next
        
        Return 0
    EndProc
    
    *----------------------------------------------------------------
    * FindTenantByCUI - Find tenant by CUI
    *----------------------------------------------------------------
    Procedure FindTenantByCUI(tcCUI)
        Local i
        
        For i = 1 To This.nTenantCount
            If This.aTenants[i, 3] = tcCUI
                Return This.aTenants[i, 1]
            EndIf
        Next
        
        Return ""
    EndProc
    
    *----------------------------------------------------------------
    * SetCurrentTenant - Set current active tenant
    *----------------------------------------------------------------
    Procedure SetCurrentTenant(tcTenantId)
        Local lnIndex
        
        lnIndex = This.FindTenant(tcTenantId)
        
        If lnIndex = 0
            This.oLogger.LogError("Tenant negăsit: " + tcTenantId)
            Return .F.
        EndIf
        
        This.cCurrentTenantId = tcTenantId
        
        * Create tenant object
        This.oCurrentTenant = CreateObject("Empty")
        AddProperty(This.oCurrentTenant, "Id", This.aTenants[lnIndex, 1])
        AddProperty(This.oCurrentTenant, "Name", This.aTenants[lnIndex, 2])
        AddProperty(This.oCurrentTenant, "CUI", This.aTenants[lnIndex, 3])
        AddProperty(This.oCurrentTenant, "Database", This.aTenants[lnIndex, 4])
        AddProperty(This.oCurrentTenant, "Config", This.aTenants[lnIndex, 5])
        
        * Switch database context if isolated
        If This.lIsolateData And Not Empty(This.aTenants[lnIndex, 4])
            This.SwitchDatabase(This.aTenants[lnIndex, 4])
        EndIf
        
        This.oLogger.LogInfo("Tenant activ: " + This.aTenants[lnIndex, 2])
        
        Return .T.
    EndProc
    
    *----------------------------------------------------------------
    * GetCurrentTenant - Get current tenant object
    *----------------------------------------------------------------
    Procedure GetCurrentTenant
        Return This.oCurrentTenant
    EndProc
    
    *----------------------------------------------------------------
    * GetCurrentTenantId - Get current tenant ID
    *----------------------------------------------------------------
    Procedure GetCurrentTenantId
        Return This.cCurrentTenantId
    EndProc
    
    *----------------------------------------------------------------
    * GetCurrentCUI - Get current tenant CUI
    *----------------------------------------------------------------
    Procedure GetCurrentCUI
        If Not IsNull(This.oCurrentTenant)
            Return This.oCurrentTenant.CUI
        EndIf
        Return ""
    EndProc
    
    *----------------------------------------------------------------
    * SwitchDatabase - Switch to tenant database
    *----------------------------------------------------------------
    Protected Procedure SwitchDatabase(tcDatabase)
        Try
            * Close current tables
            Close Databases All
            
            * Open tenant database
            If File(tcDatabase + ".dbc")
                Open Database (tcDatabase) Shared
            Else
                * Use folder-based isolation
                Set Default To (tcDatabase)
            EndIf
            
            This.oLogger.LogInfo("Bază de date activă: " + tcDatabase)
        Catch
            This.oLogger.LogError("Eroare switch bază de date: " + Message())
        EndTry
    EndProc
    
    *----------------------------------------------------------------
    * GetTenantConfig - Get tenant-specific configuration
    *----------------------------------------------------------------
    Procedure GetTenantConfig(tcKey, tcDefault)
        Local loConfig
        
        If IsNull(This.oCurrentTenant) Or IsNull(This.oCurrentTenant.Config)
            Return Evl(tcDefault, "")
        EndIf
        
        loConfig = This.oCurrentTenant.Config
        
        If Type("loConfig." + tcKey) <> "U"
            Return Evaluate("loConfig." + tcKey)
        EndIf
        
        Return Evl(tcDefault, "")
    EndProc
    
    *----------------------------------------------------------------
    * SetTenantConfig - Set tenant-specific configuration
    *----------------------------------------------------------------
    Procedure SetTenantConfig(tcKey, tcValue)
        Local lnIndex
        
        lnIndex = This.FindTenant(This.cCurrentTenantId)
        
        If lnIndex = 0
            Return .F.
        EndIf
        
        If IsNull(This.aTenants[lnIndex, 5])
            This.aTenants[lnIndex, 5] = CreateObject("Empty")
        EndIf
        
        AddProperty(This.aTenants[lnIndex, 5], tcKey, tcValue)
        
        * Update current tenant object
        If Not IsNull(This.oCurrentTenant)
            This.oCurrentTenant.Config = This.aTenants[lnIndex, 5]
        EndIf
        
        Return .T.
    EndProc
    
    *----------------------------------------------------------------
    * GetAllTenants - Get list of all tenants
    *----------------------------------------------------------------
    Procedure GetAllTenants
        Create Cursor TenantList (Id C(50), Name C(100), CUI C(20), Database C(200))
        
        Local i
        For i = 1 To This.nTenantCount
            Insert Into TenantList Values ;
                (This.aTenants[i, 1], This.aTenants[i, 2], ;
                 This.aTenants[i, 3], This.aTenants[i, 4])
        Next
        
        Return Reccount("TenantList") > 0
    EndProc
    
    *----------------------------------------------------------------
    * ExecuteForTenant - Execute operation for specific tenant
    *----------------------------------------------------------------
    Procedure ExecuteForTenant(tcTenantId, toCallback)
        Local lcPreviousTenant, loResult
        
        lcPreviousTenant = This.cCurrentTenantId
        
        * Switch to target tenant
        If Not This.SetCurrentTenant(tcTenantId)
            Return .Null.
        EndIf
        
        Try
            * Execute callback
            loResult = toCallback.Execute(This.oCurrentTenant)
        Catch
            loResult = .Null.
            This.oLogger.LogError("Eroare execuție pentru tenant " + tcTenantId + ": " + Message())
        EndTry
        
        * Restore previous tenant
        This.SetCurrentTenant(lcPreviousTenant)
        
        Return loResult
    EndProc
    
    *----------------------------------------------------------------
    * ExecuteForAllTenants - Execute operation for all tenants
    *----------------------------------------------------------------
    Procedure ExecuteForAllTenants(toCallback)
        Local lcPreviousTenant, i
        Dimension laResults[1]
        Local lnResultCount
        
        lcPreviousTenant = This.cCurrentTenantId
        lnResultCount = 0
        
        For i = 1 To This.nTenantCount
            This.SetCurrentTenant(This.aTenants[i, 1])
            
            Try
                lnResultCount = lnResultCount + 1
                Dimension laResults[lnResultCount]
                laResults[lnResultCount] = toCallback.Execute(This.oCurrentTenant)
            Catch
                This.oLogger.LogError("Eroare execuție pentru tenant " + This.aTenants[i, 1] + ": " + Message())
            EndTry
        Next
        
        * Restore previous tenant
        This.SetCurrentTenant(lcPreviousTenant)
        
        Return laResults
    EndProc
    
    *----------------------------------------------------------------
    * ValidateTenantAccess - Validate access for CUI
    *----------------------------------------------------------------
    Procedure ValidateTenantAccess(tcCUI)
        Local lcTenantId
        
        * Check if CUI belongs to current tenant
        If This.oCurrentTenant.CUI = tcCUI
            Return .T.
        EndIf
        
        * Check if CUI belongs to any registered tenant
        lcTenantId = This.FindTenantByCUI(tcCUI)
        
        If Empty(lcTenantId)
            This.oLogger.LogWarning("Acces neautorizat pentru CUI: " + tcCUI)
            Return .F.
        EndIf
        
        Return .T.
    EndProc
    
    *----------------------------------------------------------------
    * ImportTenantsFromTable - Import tenants from table
    *----------------------------------------------------------------
    Procedure ImportTenantsFromTable(tcTableName)
        Local lnCount
        
        If Not File(tcTableName + ".dbf") And Not Used(tcTableName)
            Return 0
        EndIf
        
        lnCount = 0
        
        Try
            If Not Used(tcTableName)
                Use (tcTableName) In 0 Alias TenantsImport
            EndIf
            
            Select TenantsImport
            Scan
                This.RegisterTenant(;
                    Alltrim(TenantId), ;
                    Alltrim(Name), ;
                    Alltrim(CUI), ;
                    Alltrim(Database), ;
                    .Null.)
                lnCount = lnCount + 1
            EndScan
            
            Use In TenantsImport
        Catch
            This.oLogger.LogError("Eroare import tenants: " + Message())
        EndTry
        
        Return lnCount
    EndProc
    
    *----------------------------------------------------------------
    * GetTenantStats - Get statistics for tenant
    *----------------------------------------------------------------
    Procedure GetTenantStats(tcTenantId)
        Local loStats
        
        loStats = CreateObject("Empty")
        AddProperty(loStats, "TenantId", tcTenantId)
        AddProperty(loStats, "InvoicesCount", 0)
        AddProperty(loStats, "UploadedCount", 0)
        AddProperty(loStats, "PendingCount", 0)
        AddProperty(loStats, "ErrorCount", 0)
        
        * Would query actual database for stats
        * This is a placeholder implementation
        
        Return loStats
    EndProc

EndDefine


*====================================================================
* TenantCallback - Base class for tenant operations
*====================================================================

Define Class TenantCallback As Custom
    
    Procedure Execute(toTenant)
        * Override in subclass
        Return .Null.
    EndProc

EndDefine
