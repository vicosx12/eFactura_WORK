*=========================================================================
* SmartLoadBalancer.prg - Adaptive Load Balancer Service
*=========================================================================
* Load balancing adaptiv cu health scoring si circuit breaker
* 
* Distribuie traffic catre multiple backend-uri cu algoritmi adaptivi
* bazati pe health, latency si success rate
*=========================================================================

Define Class SmartLoadBalancer As Custom
    * Properties
    Dimension aBackends[1]
    nBackendCount = 0
    cAlgorithm = "WEIGHTED_ROUND_ROBIN"  && ROUND_ROBIN, LEAST_CONNECTIONS, WEIGHTED, ADAPTIVE
    nHealthCheckInterval = 30  && seconds
    nLastHealthCheck = 0
    
    * Initialize
    Procedure Init
        This.nBackendCount = 0
        This.nLastHealthCheck = Seconds()
    EndProc
    
    * Add backend
    Procedure AddBackend(tcName, tcUrl, tnWeight)
        Local loBackend
        
        loBackend = CreateObject("Empty")
        AddProperty(loBackend, "cName", tcName)
        AddProperty(loBackend, "cUrl", tcUrl)
        AddProperty(loBackend, "nWeight", Iif(Empty(tnWeight), 100, tnWeight))
        AddProperty(loBackend, "nHealthScore", 100)
        AddProperty(loBackend, "lIsHealthy", .T.)
        AddProperty(loBackend, "nActiveConnections", 0)
        AddProperty(loBackend, "nTotalRequests", 0)
        AddProperty(loBackend, "nSuccessfulRequests", 0)
        AddProperty(loBackend, "nFailedRequests", 0)
        AddProperty(loBackend, "nAvgLatency", 0)
        AddProperty(loBackend, "nLastRequestTime", 0)
        AddProperty(loBackend, "cCircuitState", "CLOSED")  && CLOSED, OPEN, HALF_OPEN
        AddProperty(loBackend, "nCircuitOpenTime", 0)
        AddProperty(loBackend, "nFailureThreshold", 5)
        AddProperty(loBackend, "nConsecutiveFailures", 0)
        
        This.nBackendCount = This.nBackendCount + 1
        Dimension This.aBackends[This.nBackendCount]
        This.aBackends[This.nBackendCount] = loBackend
        
        Return loBackend
    EndProc
    
    * Get next backend based on algorithm
    Procedure GetNextBackend()
        Local loBackend
        
        * Perform health check if needed
        If (Seconds() - This.nLastHealthCheck) > This.nHealthCheckInterval
            This.PerformHealthCheck()
        EndIf
        
        Do Case
            Case Upper(This.cAlgorithm) == "ROUND_ROBIN"
                loBackend = This.RoundRobin()
            Case Upper(This.cAlgorithm) == "LEAST_CONNECTIONS"
                loBackend = This.LeastConnections()
            Case Upper(This.cAlgorithm) == "WEIGHTED_ROUND_ROBIN"
                loBackend = This.WeightedRoundRobin()
            Case Upper(This.cAlgorithm) == "ADAPTIVE"
                loBackend = This.AdaptiveSelection()
            Otherwise
                loBackend = This.RoundRobin()
        EndCase
        
        If Not IsNull(loBackend)
            loBackend.nActiveConnections = loBackend.nActiveConnections + 1
            loBackend.nTotalRequests = loBackend.nTotalRequests + 1
            loBackend.nLastRequestTime = Seconds()
        EndIf
        
        Return loBackend
    EndProc
    
    * Round Robin algorithm
    Protected Procedure RoundRobin()
        Local i, loBackend, loSelected
        Static nLastIndex
        
        If Type("nLastIndex") <> "N"
            nLastIndex = 0
        EndIf
        
        * Find next healthy backend
        For i = 1 To This.nBackendCount
            nLastIndex = nLastIndex + 1
            If nLastIndex > This.nBackendCount
                nLastIndex = 1
            EndIf
            
            loBackend = This.aBackends[nLastIndex]
            If This.IsBackendAvailable(loBackend)
                Return loBackend
            EndIf
        EndFor
        
        Return .Null.
    EndProc
    
    * Least Connections algorithm
    Protected Procedure LeastConnections()
        Local i, loBackend, loSelected, lnMinConnections
        
        lnMinConnections = 999999
        loSelected = .Null.
        
        For i = 1 To This.nBackendCount
            loBackend = This.aBackends[i]
            If This.IsBackendAvailable(loBackend)
                If loBackend.nActiveConnections < lnMinConnections
                    lnMinConnections = loBackend.nActiveConnections
                    loSelected = loBackend
                EndIf
            EndIf
        EndFor
        
        Return loSelected
    EndProc
    
    * Weighted Round Robin
    Protected Procedure WeightedRoundRobin()
        Local i, loBackend, lnTotalWeight, lnRandom, lnCumulative
        
        * Calculate total weight of healthy backends
        lnTotalWeight = 0
        For i = 1 To This.nBackendCount
            loBackend = This.aBackends[i]
            If This.IsBackendAvailable(loBackend)
                lnTotalWeight = lnTotalWeight + loBackend.nWeight
            EndIf
        EndFor
        
        If lnTotalWeight = 0
            Return .Null.
        EndIf
        
        * Random selection based on weights
        lnRandom = Rand() * lnTotalWeight
        lnCumulative = 0
        
        For i = 1 To This.nBackendCount
            loBackend = This.aBackends[i]
            If This.IsBackendAvailable(loBackend)
                lnCumulative = lnCumulative + loBackend.nWeight
                If lnRandom <= lnCumulative
                    Return loBackend
                EndIf
            EndIf
        EndFor
        
        Return .Null.
    EndProc
    
    * Adaptive selection based on health score
    Protected Procedure AdaptiveSelection()
        Local i, loBackend, loSelected, lnBestScore
        
        lnBestScore = -1
        loSelected = .Null.
        
        For i = 1 To This.nBackendCount
            loBackend = This.aBackends[i]
            If This.IsBackendAvailable(loBackend)
                * Calculate composite score
                Local lnScore
                lnScore = loBackend.nHealthScore
                
                * Penalize high latency
                If loBackend.nAvgLatency > 0
                    lnScore = lnScore * (1 - (loBackend.nAvgLatency / 1000))
                EndIf
                
                * Penalize high load
                If loBackend.nActiveConnections > 0
                    lnScore = lnScore / (1 + loBackend.nActiveConnections * 0.1)
                EndIf
                
                If lnScore > lnBestScore
                    lnBestScore = lnScore
                    loSelected = loBackend
                EndIf
            EndIf
        EndFor
        
        Return loSelected
    EndProc
    
    * Check if backend is available
    Protected Procedure IsBackendAvailable(toBackend)
        Return toBackend.lIsHealthy And toBackend.cCircuitState <> "OPEN"
    EndProc
    
    * Record request result
    Procedure RecordResult(toBackend, llSuccess, tnLatency)
        toBackend.nActiveConnections = Max(0, toBackend.nActiveConnections - 1)
        
        If llSuccess
            toBackend.nSuccessfulRequests = toBackend.nSuccessfulRequests + 1
            toBackend.nConsecutiveFailures = 0
            
            * Update average latency (exponential moving average)
            If toBackend.nAvgLatency = 0
                toBackend.nAvgLatency = tnLatency
            Else
                toBackend.nAvgLatency = toBackend.nAvgLatency * 0.8 + tnLatency * 0.2
            EndIf
            
            * Try to close circuit if it was half-open
            If toBackend.cCircuitState == "HALF_OPEN"
                toBackend.cCircuitState = "CLOSED"
            EndIf
        Else
            toBackend.nFailedRequests = toBackend.nFailedRequests + 1
            toBackend.nConsecutiveFailures = toBackend.nConsecutiveFailures + 1
            
            * Open circuit if threshold exceeded
            If toBackend.nConsecutiveFailures >= toBackend.nFailureThreshold
                toBackend.cCircuitState = "OPEN"
                toBackend.nCircuitOpenTime = Seconds()
            EndIf
        EndIf
        
        * Update health score
        This.UpdateHealthScore(toBackend)
    EndProc
    
    * Update backend health score
    Protected Procedure UpdateHealthScore(toBackend)
        Local lnSuccessRate, lnScore
        
        If toBackend.nTotalRequests > 0
            lnSuccessRate = toBackend.nSuccessfulRequests / toBackend.nTotalRequests
            lnScore = lnSuccessRate * 100
            
            * Penalize high latency
            If toBackend.nAvgLatency > 500
                lnScore = lnScore * 0.8
            EndIf
            
            toBackend.nHealthScore = Max(0, Min(100, lnScore))
            toBackend.lIsHealthy = (toBackend.nHealthScore >= 50)
        EndIf
    EndProc
    
    * Perform health check on all backends
    Procedure PerformHealthCheck()
        Local i, loBackend
        
        For i = 1 To This.nBackendCount
            loBackend = This.aBackends[i]
            
            * Check circuit breaker state
            If loBackend.cCircuitState == "OPEN"
                * Try to transition to half-open after 30 seconds
                If (Seconds() - loBackend.nCircuitOpenTime) > 30
                    loBackend.cCircuitState = "HALF_OPEN"
                    loBackend.nConsecutiveFailures = 0
                EndIf
            EndIf
            
            * Update health based on recent activity
            If (Seconds() - loBackend.nLastRequestTime) > 60
                * No recent requests, maintain current health
            EndIf
        EndFor
        
        This.nLastHealthCheck = Seconds()
    EndProc
    
    * Get load balancer statistics
    Procedure GetStatistics()
        Local loStats, i, loBackend
        
        loStats = CreateObject("Empty")
        AddProperty(loStats, "cAlgorithm", This.cAlgorithm)
        AddProperty(loStats, "nBackendCount", This.nBackendCount)
        AddProperty(loStats, "nHealthyBackends", 0)
        AddProperty(loStats, "nTotalRequests", 0)
        AddProperty(loStats, "nSuccessfulRequests", 0)
        AddProperty(loStats, "nFailedRequests", 0)
        AddProperty(loStats, "nAvgHealthScore", 0)
        
        Local lnTotalHealth
        lnTotalHealth = 0
        
        For i = 1 To This.nBackendCount
            loBackend = This.aBackends[i]
            If loBackend.lIsHealthy
                loStats.nHealthyBackends = loStats.nHealthyBackends + 1
            EndIf
            loStats.nTotalRequests = loStats.nTotalRequests + loBackend.nTotalRequests
            loStats.nSuccessfulRequests = loStats.nSuccessfulRequests + loBackend.nSuccessfulRequests
            loStats.nFailedRequests = loStats.nFailedRequests + loBackend.nFailedRequests
            lnTotalHealth = lnTotalHealth + loBackend.nHealthScore
        EndFor
        
        If This.nBackendCount > 0
            loStats.nAvgHealthScore = lnTotalHealth / This.nBackendCount
        EndIf
        
        Return loStats
    EndProc
    
EndDefine
