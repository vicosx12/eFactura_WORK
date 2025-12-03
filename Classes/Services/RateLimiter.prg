*====================================================================
* RateLimiter - API Rate Limiting Service
* 
* Protects against exceeding ANAF API limits:
* - Token bucket algorithm
* - Sliding window tracking
* - Configurable limits per endpoint
*
* Visual FoxPro 9 SP2 Compatible
*====================================================================

Define Class RateLimiter As Custom
    
    * Default limits (requests per window)
    nDefaultLimit = 100
    nDefaultWindowSeconds = 60
    
    * Specific endpoint limits
    Dimension aEndpointLimits[1, 3]  && Endpoint, Limit, Window
    nEndpointCount = 0
    
    * Request tracking
    Dimension aRequests[1, 3]  && Endpoint, Timestamp, Count
    nRequestCount = 0
    
    * Token bucket state
    nTokens = 100
    nMaxTokens = 100
    nRefillRate = 10  && tokens per second
    nLastRefill = 0
    
    * Status
    lEnabled = .T.
    lUseTokenBucket = .T.
    lUseSlidingWindow = .T.
    
    * Logger
    oLogger = .Null.
    
    *----------------------------------------------------------------
    * Init
    *----------------------------------------------------------------
    Procedure Init
        This.oLogger = CreateObject("LoggerService")
        This.nLastRefill = Seconds()
        
        * Configure ANAF-specific limits
        This.ConfigureAnafLimits()
    EndProc
    
    *----------------------------------------------------------------
    * ConfigureAnafLimits - Set ANAF API rate limits
    *----------------------------------------------------------------
    Protected Procedure ConfigureAnafLimits
        * Upload endpoint - limited requests
        This.SetEndpointLimit("upload", 60, 60)     && 60 requests per minute
        
        * Status check - more generous
        This.SetEndpointLimit("status", 120, 60)    && 120 requests per minute
        
        * Download - moderate
        This.SetEndpointLimit("download", 100, 60)  && 100 requests per minute
        
        * Messages list
        This.SetEndpointLimit("messages", 30, 60)   && 30 requests per minute
    EndProc
    
    *----------------------------------------------------------------
    * SetEndpointLimit - Configure limit for specific endpoint
    *----------------------------------------------------------------
    Procedure SetEndpointLimit(tcEndpoint, tnLimit, tnWindowSeconds)
        Local i, lnIndex
        
        * Check if endpoint already exists
        lnIndex = 0
        For i = 1 To This.nEndpointCount
            If Lower(This.aEndpointLimits[i, 1]) = Lower(tcEndpoint)
                lnIndex = i
                Exit
            EndIf
        Next
        
        If lnIndex = 0
            This.nEndpointCount = This.nEndpointCount + 1
            lnIndex = This.nEndpointCount
            Dimension This.aEndpointLimits[This.nEndpointCount, 3]
        EndIf
        
        This.aEndpointLimits[lnIndex, 1] = Lower(tcEndpoint)
        This.aEndpointLimits[lnIndex, 2] = tnLimit
        This.aEndpointLimits[lnIndex, 3] = tnWindowSeconds
    EndProc
    
    *----------------------------------------------------------------
    * CanMakeRequest - Check if request is allowed
    *----------------------------------------------------------------
    Procedure CanMakeRequest(tcEndpoint)
        If Not This.lEnabled
            Return .T.
        EndIf
        
        * Check token bucket
        If This.lUseTokenBucket
            If Not This.CheckTokenBucket()
                This.oLogger.LogWarning("Rate limit: Token bucket empty")
                Return .F.
            EndIf
        EndIf
        
        * Check sliding window for endpoint
        If This.lUseSlidingWindow
            If Not This.CheckSlidingWindow(tcEndpoint)
                This.oLogger.LogWarning("Rate limit: Sliding window exceeded for " + tcEndpoint)
                Return .F.
            EndIf
        EndIf
        
        Return .T.
    EndProc
    
    *----------------------------------------------------------------
    * RecordRequest - Record a request
    *----------------------------------------------------------------
    Procedure RecordRequest(tcEndpoint)
        * Consume token
        If This.lUseTokenBucket
            This.ConsumeToken()
        EndIf
        
        * Record in sliding window
        If This.lUseSlidingWindow
            This.AddToWindow(tcEndpoint)
        EndIf
    EndProc
    
    *----------------------------------------------------------------
    * AcquirePermit - Check and record request atomically
    *----------------------------------------------------------------
    Procedure AcquirePermit(tcEndpoint)
        If This.CanMakeRequest(tcEndpoint)
            This.RecordRequest(tcEndpoint)
            Return .T.
        EndIf
        Return .F.
    EndProc
    
    *----------------------------------------------------------------
    * WaitForPermit - Wait until request is allowed
    *----------------------------------------------------------------
    Procedure WaitForPermit(tcEndpoint, tnMaxWaitSeconds)
        Local lnStart, lnElapsed
        
        If Empty(tnMaxWaitSeconds)
            tnMaxWaitSeconds = 60
        EndIf
        
        lnStart = Seconds()
        
        Do While .T.
            If This.AcquirePermit(tcEndpoint)
                Return .T.
            EndIf
            
            lnElapsed = Seconds() - lnStart
            If lnElapsed >= tnMaxWaitSeconds
                Return .F.
            EndIf
            
            * Wait before retry
            Inkey(This.GetWaitTime(tcEndpoint))
        EndDo
        
        Return .F.
    EndProc
    
    *----------------------------------------------------------------
    * CheckTokenBucket - Check if tokens available
    *----------------------------------------------------------------
    Protected Procedure CheckTokenBucket
        This.RefillTokens()
        Return This.nTokens > 0
    EndProc
    
    *----------------------------------------------------------------
    * RefillTokens - Refill token bucket based on elapsed time
    *----------------------------------------------------------------
    Protected Procedure RefillTokens
        Local lnNow, lnElapsed, lnNewTokens
        
        lnNow = Seconds()
        lnElapsed = lnNow - This.nLastRefill
        
        If lnElapsed > 0
            lnNewTokens = lnElapsed * This.nRefillRate
            This.nTokens = Min(This.nMaxTokens, This.nTokens + lnNewTokens)
            This.nLastRefill = lnNow
        EndIf
    EndProc
    
    *----------------------------------------------------------------
    * ConsumeToken - Consume one token
    *----------------------------------------------------------------
    Protected Procedure ConsumeToken
        This.RefillTokens()
        If This.nTokens > 0
            This.nTokens = This.nTokens - 1
        EndIf
    EndProc
    
    *----------------------------------------------------------------
    * CheckSlidingWindow - Check sliding window for endpoint
    *----------------------------------------------------------------
    Protected Procedure CheckSlidingWindow(tcEndpoint)
        Local lnLimit, lnWindow, lnCount, lnCutoff
        Local i
        
        * Get limit for endpoint
        lnLimit = This.nDefaultLimit
        lnWindow = This.nDefaultWindowSeconds
        
        For i = 1 To This.nEndpointCount
            If Lower(This.aEndpointLimits[i, 1]) = Lower(tcEndpoint)
                lnLimit = This.aEndpointLimits[i, 2]
                lnWindow = This.aEndpointLimits[i, 3]
                Exit
            EndIf
        Next
        
        * Count requests in window
        lnCutoff = Seconds() - lnWindow
        lnCount = 0
        
        For i = 1 To This.nRequestCount
            If Lower(This.aRequests[i, 1]) = Lower(tcEndpoint) And ;
               This.aRequests[i, 2] > lnCutoff
                lnCount = lnCount + This.aRequests[i, 3]
            EndIf
        Next
        
        Return lnCount < lnLimit
    EndProc
    
    *----------------------------------------------------------------
    * AddToWindow - Add request to sliding window
    *----------------------------------------------------------------
    Protected Procedure AddToWindow(tcEndpoint)
        Local lnNow, i, llFound
        
        lnNow = Seconds()
        llFound = .F.
        
        * Try to find existing bucket for this second
        For i = 1 To This.nRequestCount
            If Lower(This.aRequests[i, 1]) = Lower(tcEndpoint) And ;
               Int(This.aRequests[i, 2]) = Int(lnNow)
                This.aRequests[i, 3] = This.aRequests[i, 3] + 1
                llFound = .T.
                Exit
            EndIf
        Next
        
        * Create new bucket
        If Not llFound
            This.nRequestCount = This.nRequestCount + 1
            Dimension This.aRequests[This.nRequestCount, 3]
            This.aRequests[This.nRequestCount, 1] = Lower(tcEndpoint)
            This.aRequests[This.nRequestCount, 2] = lnNow
            This.aRequests[This.nRequestCount, 3] = 1
        EndIf
        
        * Cleanup old entries periodically
        If This.nRequestCount > 1000
            This.CleanupWindow()
        EndIf
    EndProc
    
    *----------------------------------------------------------------
    * CleanupWindow - Remove old entries from sliding window
    *----------------------------------------------------------------
    Protected Procedure CleanupWindow
        Local lnCutoff, lnNewCount, i
        Dimension laNew[1, 3]
        
        lnCutoff = Seconds() - Max(This.nDefaultWindowSeconds, 120)
        lnNewCount = 0
        
        For i = 1 To This.nRequestCount
            If This.aRequests[i, 2] > lnCutoff
                lnNewCount = lnNewCount + 1
                Dimension laNew[lnNewCount, 3]
                laNew[lnNewCount, 1] = This.aRequests[i, 1]
                laNew[lnNewCount, 2] = This.aRequests[i, 2]
                laNew[lnNewCount, 3] = This.aRequests[i, 3]
            EndIf
        Next
        
        This.nRequestCount = lnNewCount
        Dimension This.aRequests[Max(1, lnNewCount), 3]
        
        For i = 1 To lnNewCount
            This.aRequests[i, 1] = laNew[i, 1]
            This.aRequests[i, 2] = laNew[i, 2]
            This.aRequests[i, 3] = laNew[i, 3]
        Next
    EndProc
    
    *----------------------------------------------------------------
    * GetWaitTime - Calculate wait time before retry
    *----------------------------------------------------------------
    Protected Procedure GetWaitTime(tcEndpoint)
        Local lnWindow, i
        
        * Get window for endpoint
        lnWindow = This.nDefaultWindowSeconds
        
        For i = 1 To This.nEndpointCount
            If Lower(This.aEndpointLimits[i, 1]) = Lower(tcEndpoint)
                lnWindow = This.aEndpointLimits[i, 3]
                Exit
            EndIf
        Next
        
        * Wait 1/10 of window or minimum 1 second
        Return Max(1, lnWindow / 10)
    EndProc
    
    *----------------------------------------------------------------
    * GetStatus - Get current rate limiter status
    *----------------------------------------------------------------
    Procedure GetStatus
        Local loStatus
        
        This.RefillTokens()
        
        loStatus = CreateObject("Empty")
        AddProperty(loStatus, "Enabled", This.lEnabled)
        AddProperty(loStatus, "Tokens", Int(This.nTokens))
        AddProperty(loStatus, "MaxTokens", This.nMaxTokens)
        AddProperty(loStatus, "RequestsTracked", This.nRequestCount)
        AddProperty(loStatus, "EndpointsConfigured", This.nEndpointCount)
        
        Return loStatus
    EndProc
    
    *----------------------------------------------------------------
    * GetRemainingRequests - Get remaining requests for endpoint
    *----------------------------------------------------------------
    Procedure GetRemainingRequests(tcEndpoint)
        Local lnLimit, lnWindow, lnCount, lnCutoff
        Local i
        
        * Get limit for endpoint
        lnLimit = This.nDefaultLimit
        lnWindow = This.nDefaultWindowSeconds
        
        For i = 1 To This.nEndpointCount
            If Lower(This.aEndpointLimits[i, 1]) = Lower(tcEndpoint)
                lnLimit = This.aEndpointLimits[i, 2]
                lnWindow = This.aEndpointLimits[i, 3]
                Exit
            EndIf
        Next
        
        * Count requests in window
        lnCutoff = Seconds() - lnWindow
        lnCount = 0
        
        For i = 1 To This.nRequestCount
            If Lower(This.aRequests[i, 1]) = Lower(tcEndpoint) And ;
               This.aRequests[i, 2] > lnCutoff
                lnCount = lnCount + This.aRequests[i, 3]
            EndIf
        Next
        
        Return Max(0, lnLimit - lnCount)
    EndProc
    
    *----------------------------------------------------------------
    * Reset - Reset rate limiter state
    *----------------------------------------------------------------
    Procedure Reset
        This.nTokens = This.nMaxTokens
        This.nLastRefill = Seconds()
        This.nRequestCount = 0
        Dimension This.aRequests[1, 3]
    EndProc

EndDefine
