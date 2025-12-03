*==============================================================================
* ResourcePoolManager.prg - Connection and Resource Pooling
*==============================================================================
* Manages pools of reusable resources (connections, threads, etc.)
*==============================================================================

Define Class ResourcePoolManager As Custom
    Dimension aPools[1]
    nPoolCount = 0
    oLogger = .Null.
    
    Procedure Init()
        This.oLogger = CreateObject("LoggerService")
        Dimension This.aPools[1]
    EndProc
    
    *-- Create resource pool
    Procedure CreatePool(tcPoolId, tnMinSize, tnMaxSize, toFactory)
        Local loPool
        loPool = CreateObject("ResourcePool", tcPoolId, tnMinSize, tnMaxSize, toFactory)
        
        This.nPoolCount = This.nPoolCount + 1
        Dimension This.aPools[This.nPoolCount]
        This.aPools[This.nPoolCount] = loPool
        
        This.oLogger.Info("Created resource pool: " + tcPoolId + " (min:" + Transform(tnMinSize) + ", max:" + Transform(tnMaxSize) + ")")
        Return loPool
    EndProc
    
    *-- Acquire resource from pool
    Procedure AcquireResource(tcPoolId)
        Local loPool
        loPool = This.GetPool(tcPoolId)
        
        If Not IsNull(loPool)
            Return loPool.Acquire()
        EndIf
        
        Return .Null.
    EndProc
    
    *-- Release resource back to pool
    Procedure ReleaseResource(tcPoolId, toResource)
        Local loPool
        loPool = This.GetPool(tcPoolId)
        
        If Not IsNull(loPool)
            loPool.Release(toResource)
            Return .T.
        EndIf
        
        Return .F.
    EndProc
    
    *-- Get pool statistics
    Procedure GetPoolStats(tcPoolId)
        Local loPool
        loPool = This.GetPool(tcPoolId)
        
        If Not IsNull(loPool)
            Return loPool.GetStats()
        EndIf
        
        Return .Null.
    EndProc
    
    *-- Shutdown pool
    Procedure ShutdownPool(tcPoolId)
        Local loPool
        loPool = This.GetPool(tcPoolId)
        
        If Not IsNull(loPool)
            loPool.Shutdown()
            This.oLogger.Info("Shutdown pool: " + tcPoolId)
            Return .T.
        EndIf
        
        Return .F.
    EndProc
    
    *-- Get pool
    Protected Procedure GetPool(tcPoolId)
        Local i
        For i = 1 To This.nPoolCount
            If This.aPools[i].cPoolId = tcPoolId
                Return This.aPools[i]
            EndIf
        EndFor
        Return .Null.
    EndProc
EndDefine

*-- Resource Pool
Define Class ResourcePool As Custom
    cPoolId = ""
    nMinSize = 1
    nMaxSize = 10
    nCurrentSize = 0
    oFactory = .Null.
    Dimension aResources[1]
    nResourceCount = 0
    nAcquireCount = 0
    nReleaseCount = 0
    oLogger = .Null.
    
    Procedure Init(tcPoolId, tnMinSize, tnMaxSize, toFactory)
        This.cPoolId = tcPoolId
        This.nMinSize = tnMinSize
        This.nMaxSize = tnMaxSize
        This.oFactory = toFactory
        This.oLogger = CreateObject("LoggerService")
        Dimension This.aResources[1]
        
        *-- Pre-create minimum resources
        This.InitializePool()
    EndProc
    
    Protected Procedure InitializePool()
        Local i
        For i = 1 To This.nMinSize
            This.CreateResource()
        EndFor
    EndProc
    
    Protected Procedure CreateResource()
        Local loWrapper
        loWrapper = CreateObject("PooledResource")
        loWrapper.oResource = This.oFactory.Create()
        loWrapper.lAvailable = .T.
        loWrapper.tCreated = Datetime()
        
        This.nResourceCount = This.nResourceCount + 1
        Dimension This.aResources[This.nResourceCount]
        This.aResources[This.nResourceCount] = loWrapper
        
        This.nCurrentSize = This.nCurrentSize + 1
        Return loWrapper
    EndProc
    
    *-- Acquire resource
    Procedure Acquire()
        Local i, loWrapper
        
        *-- Find available resource
        For i = 1 To This.nResourceCount
            If This.aResources[i].lAvailable
                *-- Check if still healthy
                If This.IsHealthy(This.aResources[i])
                    This.aResources[i].lAvailable = .F.
                    This.aResources[i].tAcquired = Datetime()
                    This.nAcquireCount = This.nAcquireCount + 1
                    Return This.aResources[i].oResource
                Else
                    *-- Resource unhealthy, recreate
                    This.RecreateResource(i)
                EndIf
            EndIf
        EndFor
        
        *-- No available resource, create new if under max
        If This.nCurrentSize < This.nMaxSize
            loWrapper = This.CreateResource()
            loWrapper.lAvailable = .F.
            loWrapper.tAcquired = Datetime()
            This.nAcquireCount = This.nAcquireCount + 1
            Return loWrapper.oResource
        EndIf
        
        *-- Pool exhausted
        This.oLogger.Warning("Pool exhausted: " + This.cPoolId)
        Return .Null.
    EndProc
    
    *-- Release resource
    Procedure Release(toResource)
        Local i
        
        For i = 1 To This.nResourceCount
            If This.aResources[i].oResource == toResource
                This.aResources[i].lAvailable = .T.
                This.aResources[i].tReleased = Datetime()
                This.nReleaseCount = This.nReleaseCount + 1
                Return .T.
            EndIf
        EndFor
        
        Return .F.
    EndProc
    
    *-- Check resource health
    Protected Procedure IsHealthy(toWrapper)
        *-- Simple health check
        Try
            If VarType(toWrapper.oResource) <> "O"
                Return .F.
            EndIf
            
            *-- Could add more sophisticated health checks
            Return .T.
        Catch
            Return .F.
        EndTry
    EndProc
    
    *-- Recreate unhealthy resource
    Protected Procedure RecreateResource(tnIndex)
        Try
            This.aResources[tnIndex].oResource = This.oFactory.Create()
            This.aResources[tnIndex].tCreated = Datetime()
            This.oLogger.Info("Recreated resource: " + This.cPoolId)
        Catch To loEx
            This.oLogger.Error("Failed to recreate resource: " + loEx.Message)
        EndTry
    EndProc
    
    *-- Get statistics
    Procedure GetStats()
        Local loStats, i, lnAvailable
        loStats = CreateObject("Empty")
        
        lnAvailable = 0
        For i = 1 To This.nResourceCount
            If This.aResources[i].lAvailable
                lnAvailable = lnAvailable + 1
            EndIf
        EndFor
        
        AddProperty(loStats, "PoolId", This.cPoolId)
        AddProperty(loStats, "CurrentSize", This.nCurrentSize)
        AddProperty(loStats, "MinSize", This.nMinSize)
        AddProperty(loStats, "MaxSize", This.nMaxSize)
        AddProperty(loStats, "Available", lnAvailable)
        AddProperty(loStats, "InUse", This.nCurrentSize - lnAvailable)
        AddProperty(loStats, "TotalAcquires", This.nAcquireCount)
        AddProperty(loStats, "TotalReleases", This.nReleaseCount)
        
        Return loStats
    EndProc
    
    *-- Shutdown pool
    Procedure Shutdown()
        *-- Release all resources
        This.nCurrentSize = 0
        This.nResourceCount = 0
        Dimension This.aResources[1]
    EndProc
EndDefine

*-- Pooled Resource Wrapper
Define Class PooledResource As Custom
    oResource = .Null.
    lAvailable = .T.
    tCreated = {}
    tAcquired = {}
    tReleased = {}
EndDefine
