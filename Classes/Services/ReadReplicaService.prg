*====================================================================
* ReadReplicaService.prg - Read Replica Support
* Part of eFactura OOP Refactoring - v2.4 Enterprise Edition
*====================================================================
* Read Replica: Route read queries to replicas for performance
*====================================================================

*--------------------------------------------------------------------
* ReadReplicaManager
*--------------------------------------------------------------------
Define Class ReadReplicaManager As Custom
    oPrimaryConnection = .Null.
    oReplicas = .Null.
    oLogger = .Null.
    oMetrics = .Null.
    cLoadBalanceStrategy = "ROUND_ROBIN"  && ROUND_ROBIN, RANDOM, LEAST_CONNECTIONS
    nCurrentReplica = 0
    lEnabled = .T.
    nReplicaLagThresholdMs = 5000
    
    Procedure Init
        This.oReplicas = CreateObject("Collection")
    EndProc
    
    *-- Set primary connection
    Procedure SetPrimary(toConnection)
        This.oPrimaryConnection = toConnection
    EndProc
    
    *-- Add read replica
    Procedure AddReplica(toConnection, tcName)
        Local loReplica
        loReplica = CreateObject("ReplicaInfo")
        loReplica.oConnection = toConnection
        loReplica.cName = tcName
        loReplica.lHealthy = .T.
        loReplica.nActiveConnections = 0
        
        This.oReplicas.Add(loReplica, tcName)
        
        If VarType(This.oLogger) = 'O'
            This.oLogger.Info("Read replica added: " + tcName)
        EndIf
    EndProc
    
    *-- Get connection for read operation
    Procedure GetReadConnection
        If !This.lEnabled Or This.oReplicas.Count = 0
            Return This.oPrimaryConnection
        EndIf
        
        Local loReplica
        loReplica = This.SelectReplica()
        
        If VarType(loReplica) = 'O'
            loReplica.nActiveConnections = loReplica.nActiveConnections + 1
            Return loReplica.oConnection
        EndIf
        
        Return This.oPrimaryConnection
    EndProc
    
    *-- Get connection for write operation (always primary)
    Procedure GetWriteConnection
        Return This.oPrimaryConnection
    EndProc
    
    *-- Release read connection
    Procedure ReleaseReadConnection(toConnection)
        Local lnI, loReplica
        
        For lnI = 1 To This.oReplicas.Count
            loReplica = This.oReplicas.Item(lnI)
            * Compare connection
            loReplica.nActiveConnections = Max(0, loReplica.nActiveConnections - 1)
        EndFor
    EndProc
    
    *-- Select replica based on strategy
    Protected Procedure SelectReplica
        Local lnHealthyCount, lnI, loReplica
        
        * Count healthy replicas
        lnHealthyCount = 0
        For lnI = 1 To This.oReplicas.Count
            If This.oReplicas.Item(lnI).lHealthy
                lnHealthyCount = lnHealthyCount + 1
            EndIf
        EndFor
        
        If lnHealthyCount = 0
            Return .Null.
        EndIf
        
        Do Case
            Case This.cLoadBalanceStrategy = "ROUND_ROBIN"
                Return This.SelectRoundRobin()
                
            Case This.cLoadBalanceStrategy = "RANDOM"
                Return This.SelectRandom()
                
            Case This.cLoadBalanceStrategy = "LEAST_CONNECTIONS"
                Return This.SelectLeastConnections()
                
            Otherwise
                Return This.SelectRoundRobin()
        EndCase
    EndProc
    
    Protected Procedure SelectRoundRobin
        Local lnI, lnAttempts, loReplica
        
        lnAttempts = 0
        Do While lnAttempts < This.oReplicas.Count
            This.nCurrentReplica = This.nCurrentReplica + 1
            If This.nCurrentReplica > This.oReplicas.Count
                This.nCurrentReplica = 1
            EndIf
            
            loReplica = This.oReplicas.Item(This.nCurrentReplica)
            If loReplica.lHealthy
                Return loReplica
            EndIf
            
            lnAttempts = lnAttempts + 1
        EndDo
        
        Return .Null.
    EndProc
    
    Protected Procedure SelectRandom
        Local laHealthy, lnI, loReplica, lnHealthyCount
        Dimension laHealthy[1]
        lnHealthyCount = 0
        
        For lnI = 1 To This.oReplicas.Count
            loReplica = This.oReplicas.Item(lnI)
            If loReplica.lHealthy
                lnHealthyCount = lnHealthyCount + 1
                Dimension laHealthy[lnHealthyCount]
                laHealthy[lnHealthyCount] = loReplica
            EndIf
        EndFor
        
        If lnHealthyCount = 0
            Return .Null.
        EndIf
        
        Local lnRandom
        lnRandom = Int(Rand() * lnHealthyCount) + 1
        Return laHealthy[lnRandom]
    EndProc
    
    Protected Procedure SelectLeastConnections
        Local loSelected, lnMinConnections, lnI, loReplica
        
        loSelected = .Null.
        lnMinConnections = 999999
        
        For lnI = 1 To This.oReplicas.Count
            loReplica = This.oReplicas.Item(lnI)
            If loReplica.lHealthy And loReplica.nActiveConnections < lnMinConnections
                lnMinConnections = loReplica.nActiveConnections
                loSelected = loReplica
            EndIf
        EndFor
        
        Return loSelected
    EndProc
    
    *-- Health check all replicas
    Procedure CheckHealth
        Local lnI, loReplica
        
        For lnI = 1 To This.oReplicas.Count
            loReplica = This.oReplicas.Item(lnI)
            
            Try
                * Simple health check
                Local llHealthy
                llHealthy = This.PingReplica(loReplica)
                
                If loReplica.lHealthy And !llHealthy
                    If VarType(This.oLogger) = 'O'
                        This.oLogger.Warning("Replica unhealthy: " + loReplica.cName)
                    EndIf
                ElseIf !loReplica.lHealthy And llHealthy
                    If VarType(This.oLogger) = 'O'
                        This.oLogger.Info("Replica recovered: " + loReplica.cName)
                    EndIf
                EndIf
                
                loReplica.lHealthy = llHealthy
                loReplica.tLastCheck = DateTime()
                
            Catch To loEx
                loReplica.lHealthy = .F.
                loReplica.cLastError = loEx.Message
            EndTry
        EndFor
    EndProc
    
    Protected Procedure PingReplica(toReplica)
        * Simple ping - in real implementation would query replica
        Return .T.
    EndProc
    
    *-- Get statistics
    Procedure GetStats
        Local loStats, lnI, loReplica
        
        loStats = CreateObject("Empty")
        AddProperty(loStats, "nTotalReplicas", This.oReplicas.Count)
        AddProperty(loStats, "nHealthyReplicas", 0)
        AddProperty(loStats, "nTotalConnections", 0)
        
        For lnI = 1 To This.oReplicas.Count
            loReplica = This.oReplicas.Item(lnI)
            If loReplica.lHealthy
                loStats.nHealthyReplicas = loStats.nHealthyReplicas + 1
            EndIf
            loStats.nTotalConnections = loStats.nTotalConnections + loReplica.nActiveConnections
        EndFor
        
        Return loStats
    EndProc
EndDefine

*--------------------------------------------------------------------
* ReplicaInfo
*--------------------------------------------------------------------
Define Class ReplicaInfo As Custom
    cName = ""
    oConnection = .Null.
    lHealthy = .T.
    nActiveConnections = 0
    tLastCheck = .Null.
    nLagMs = 0
    cLastError = ""
EndDefine

*--------------------------------------------------------------------
* ReadWriteRepository - Uses replicas for reads
*--------------------------------------------------------------------
Define Class ReadWriteRepository As Custom
    oReplicaManager = .Null.
    oLogger = .Null.
    
    Procedure Init(toReplicaManager)
        This.oReplicaManager = toReplicaManager
    EndProc
    
    *-- Execute read query
    Procedure ExecuteRead(tcSql)
        Local loConnection
        loConnection = This.oReplicaManager.GetReadConnection()
        
        Try
            * Execute on replica
            Local lResult
            lResult = This.Execute(loConnection, tcSql)
            Return lResult
        Finally
            This.oReplicaManager.ReleaseReadConnection(loConnection)
        EndTry
    EndProc
    
    *-- Execute write query (always on primary)
    Procedure ExecuteWrite(tcSql)
        Local loConnection
        loConnection = This.oReplicaManager.GetWriteConnection()
        Return This.Execute(loConnection, tcSql)
    EndProc
    
    Protected Procedure Execute(toConnection, tcSql)
        * Execute SQL
        &tcSql
    EndProc
EndDefine

*====================================================================
* End of ReadReplicaService.prg
*====================================================================
