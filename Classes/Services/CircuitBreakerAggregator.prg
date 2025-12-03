*==============================================================================
* CircuitBreakerAggregator.prg - Health Aggregation Across Services
*==============================================================================
* Aggregates circuit breaker states and provides overall health status
*==============================================================================

Define Class CircuitBreakerAggregator As Custom
    Dimension aCircuitBreakers[1]
    nBreakerCount = 0
    oLogger = .Null.
    cOverallState = "HEALTHY"
    
    Procedure Init()
        This.oLogger = CreateObject("LoggerService")
        Dimension This.aCircuitBreakers[1]
    EndProc
    
    *-- Register circuit breaker
    Procedure RegisterBreaker(tcServiceName, toBreaker)
        This.nBreakerCount = This.nBreakerCount + 1
        Dimension This.aCircuitBreakers[This.nBreakerCount, 2]
        This.aCircuitBreakers[This.nBreakerCount, 1] = tcServiceName
        This.aCircuitBreakers[This.nBreakerCount, 2] = toBreaker
        
        This.oLogger.Info("Registered circuit breaker: " + tcServiceName)
        Return .T.
    EndProc
    
    *-- Get aggregated health
    Procedure GetHealth()
        Local loHealth, i, lcState, lnOpenCount, lnHalfOpenCount
        
        loHealth = CreateObject("Empty")
        AddProperty(loHealth, "OverallState", "")
        AddProperty(loHealth, "TotalServices", This.nBreakerCount)
        AddProperty(loHealth, "OpenCount", 0)
        AddProperty(loHealth, "HalfOpenCount", 0)
        AddProperty(loHealth, "ClosedCount", 0)
        Dimension loHealth.Services[This.nBreakerCount, 2]
        
        lnOpenCount = 0
        lnHalfOpenCount = 0
        
        For i = 1 To This.nBreakerCount
            lcState = This.aCircuitBreakers[i, 2].cState
            loHealth.Services[i, 1] = This.aCircuitBreakers[i, 1]
            loHealth.Services[i, 2] = lcState
            
            Do Case
                Case lcState = "OPEN"
                    lnOpenCount = lnOpenCount + 1
                    loHealth.OpenCount = loHealth.OpenCount + 1
                Case lcState = "HALF_OPEN"
                    lnHalfOpenCount = lnHalfOpenCount + 1
                    loHealth.HalfOpenCount = loHealth.HalfOpenCount + 1
                Case lcState = "CLOSED"
                    loHealth.ClosedCount = loHealth.ClosedCount + 1
            EndCase
        EndFor
        
        *-- Determine overall state
        Do Case
            Case lnOpenCount > This.nBreakerCount / 2
                loHealth.OverallState = "CRITICAL"
            Case lnOpenCount > 0 Or lnHalfOpenCount > 0
                loHealth.OverallState = "DEGRADED"
            Otherwise
                loHealth.OverallState = "HEALTHY"
        EndCase
        
        This.cOverallState = loHealth.OverallState
        Return loHealth
    EndProc
    
    *-- Check if system is healthy
    Procedure IsHealthy()
        Return This.cOverallState = "HEALTHY"
    EndProc
    
    *-- Get service health
    Procedure GetServiceHealth(tcServiceName)
        Local i
        For i = 1 To This.nBreakerCount
            If This.aCircuitBreakers[i, 1] = tcServiceName
                Return This.aCircuitBreakers[i, 2].cState
            EndIf
        EndFor
        Return "UNKNOWN"
    EndProc
    
    *-- Reset all breakers
    Procedure ResetAll()
        Local i
        For i = 1 To This.nBreakerCount
            This.aCircuitBreakers[i, 2].Reset()
        EndFor
        This.oLogger.Info("Reset all circuit breakers")
    EndProc
EndDefine
