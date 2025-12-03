*==============================================================================
* AdaptiveThrottlingService.prg - Dynamic Rate Limiting Based on System Load
*==============================================================================
* Automatically adjusts rate limits based on system load and performance
*==============================================================================

Define Class AdaptiveThrottlingService As Custom
    nBaseLimit = 100
    nCurrentLimit = 100
    nMinLimit = 10
    nMaxLimit = 1000
    nAdjustmentInterval = 60  && seconds
    tLastAdjustment = {}
    oLogger = .Null.
    oMetrics = .Null.
    
    *-- Thresholds
    nCpuThresholdHigh = 80
    nCpuThresholdLow = 40
    nErrorRateThresholdHigh = 5
    nErrorRateThresholdLow = 1
    
    Procedure Init()
        This.oLogger = CreateObject("LoggerService")
        This.oMetrics = CreateObject("MetricsCollector")
        This.tLastAdjustment = Datetime()
        This.nCurrentLimit = This.nBaseLimit
    EndProc
    
    *-- Check if request allowed
    Procedure AllowRequest(tcClientId)
        Local lnUsage
        
        *-- Auto-adjust if needed
        This.AutoAdjust()
        
        *-- Check current usage
        lnUsage = This.oMetrics.GetCounter("requests_" + tcClientId)
        
        If lnUsage >= This.nCurrentLimit
            This.oLogger.Warning("Rate limit exceeded for: " + tcClientId)
            Return .F.
        EndIf
        
        This.oMetrics.IncrementCounter("requests_" + tcClientId)
        Return .T.
    EndProc
    
    *-- Auto-adjust limits based on system load
    Procedure AutoAdjust()
        Local lnElapsed, lnCpuLoad, lnErrorRate, lnAdjustment
        
        lnElapsed = Datetime() - This.tLastAdjustment
        If lnElapsed < This.nAdjustmentInterval
            Return  && Too soon to adjust
        EndIf
        
        *-- Get system metrics
        lnCpuLoad = This.GetCpuLoad()
        lnErrorRate = This.GetErrorRate()
        
        *-- Determine adjustment
        lnAdjustment = 0
        
        Do Case
            Case lnCpuLoad > This.nCpuThresholdHigh Or lnErrorRate > This.nErrorRateThresholdHigh
                *-- System under stress - decrease limit
                lnAdjustment = -10
                
            Case lnCpuLoad < This.nCpuThresholdLow And lnErrorRate < This.nErrorRateThresholdLow
                *-- System healthy - increase limit
                lnAdjustment = 10
        EndCase
        
        *-- Apply adjustment
        If lnAdjustment <> 0
            This.nCurrentLimit = This.nCurrentLimit + lnAdjustment
            This.nCurrentLimit = Max(This.nMinLimit, Min(This.nMaxLimit, This.nCurrentLimit))
            
            This.oLogger.Info("Adjusted rate limit to: " + Transform(This.nCurrentLimit))
            This.tLastAdjustment = Datetime()
        EndIf
    EndProc
    
    *-- Get CPU load percentage
    Protected Procedure GetCpuLoad()
        *-- Simplified CPU load estimation
        Local lnLoad
        lnLoad = Int(Rand() * 100)  && In production, use actual CPU metrics
        Return lnLoad
    EndProc
    
    *-- Get error rate percentage
    Protected Procedure GetErrorRate()
        Local lnTotal, lnErrors
        lnTotal = This.oMetrics.GetCounter("total_requests")
        lnErrors = This.oMetrics.GetCounter("failed_requests")
        
        If lnTotal = 0
            Return 0
        EndIf
        
        Return (lnErrors / lnTotal) * 100
    EndProc
    
    *-- Get current limit
    Procedure GetCurrentLimit()
        Return This.nCurrentLimit
    EndProc
    
    *-- Reset limits for client
    Procedure ResetClient(tcClientId)
        This.oMetrics.ResetCounter("requests_" + tcClientId)
        This.oLogger.Info("Reset rate limit for: " + tcClientId)
    EndProc
EndDefine
