*====================================================================
* DecoratorPattern.prg - Decorator Pattern for Handlers
* Part of eFactura OOP Refactoring - v2.4 Enterprise Edition
*====================================================================
* Decorator Pattern: Add behavior to handlers dynamically without
* modifying original code (logging, timing, caching, retries)
*====================================================================

*--------------------------------------------------------------------
* IHandlerDecorator - Base decorator interface
*--------------------------------------------------------------------
Define Class IHandlerDecorator As Custom
    oInner = .Null.
    cDecoratorName = "BaseDecorator"
    
    Procedure Init(toInnerHandler)
        This.oInner = toInnerHandler
    EndProc
    
    Procedure Handle(toContext)
        Return This.oInner.Handle(toContext)
    EndProc
    
    Procedure SetNext(toHandler)
        Return This.oInner.SetNext(toHandler)
    EndProc
EndDefine

*--------------------------------------------------------------------
* LoggingDecorator - Adds logging before/after handler
*--------------------------------------------------------------------
Define Class LoggingDecorator As IHandlerDecorator
    cDecoratorName = "LoggingDecorator"
    oLogger = .Null.
    lLogInput = .T.
    lLogOutput = .T.
    lLogErrors = .T.
    
    Procedure Init(toInnerHandler, toLogger)
        DoDefault(toInnerHandler)
        This.oLogger = toLogger
    EndProc
    
    Procedure Handle(toContext)
        Local loResult, lcHandlerName
        
        lcHandlerName = ""
        If VarType(This.oInner) = 'O' And PemStatus(This.oInner, "cName", 5)
            lcHandlerName = This.oInner.cName
        EndIf
        
        * Log entry
        If This.lLogInput And VarType(This.oLogger) = 'O'
            This.oLogger.Info("ENTER: " + lcHandlerName + " - InvoiceId: " + ;
                Transform(toContext.nInvoiceId))
        EndIf
        
        Try
            * Execute inner handler
            loResult = This.oInner.Handle(toContext)
            
            * Log exit
            If This.lLogOutput And VarType(This.oLogger) = 'O'
                Local lcStatus
                lcStatus = Iif(toContext.HasCriticalError, "FAILED", "SUCCESS")
                This.oLogger.Info("EXIT: " + lcHandlerName + " - Status: " + lcStatus)
            EndIf
            
        Catch To loEx
            * Log error
            If This.lLogErrors And VarType(This.oLogger) = 'O'
                This.oLogger.Error("ERROR in " + lcHandlerName + ": " + loEx.Message)
            EndIf
            Throw loEx
        EndTry
        
        Return loResult
    EndProc
EndDefine

*--------------------------------------------------------------------
* TimingDecorator - Measures handler execution time
*--------------------------------------------------------------------
Define Class TimingDecorator As IHandlerDecorator
    cDecoratorName = "TimingDecorator"
    oMetrics = .Null.
    oLogger = .Null.
    nSlowThresholdMs = 1000
    
    Procedure Init(toInnerHandler, toMetrics)
        DoDefault(toInnerHandler)
        This.oMetrics = toMetrics
    EndProc
    
    Procedure Handle(toContext)
        Local loResult, lnStartTime, lnDuration, lcHandlerName
        
        lcHandlerName = ""
        If VarType(This.oInner) = 'O' And PemStatus(This.oInner, "cName", 5)
            lcHandlerName = This.oInner.cName
        EndIf
        
        lnStartTime = Seconds()
        
        Try
            loResult = This.oInner.Handle(toContext)
        Finally
            lnDuration = (Seconds() - lnStartTime) * 1000  && ms
            
            * Record metric
            If VarType(This.oMetrics) = 'O'
                This.oMetrics.RecordHistogram("handler_duration_ms", lnDuration, ;
                    "handler", lcHandlerName)
            EndIf
            
            * Log slow handlers
            If lnDuration > This.nSlowThresholdMs And VarType(This.oLogger) = 'O'
                This.oLogger.Warning("SLOW HANDLER: " + lcHandlerName + ;
                    " took " + Transform(lnDuration) + "ms")
            EndIf
            
            * Store timing in context
            If !PemStatus(toContext, "nHandlerTiming", 5)
                AddProperty(toContext, "nHandlerTiming", 0)
            EndIf
            toContext.nHandlerTiming = lnDuration
        EndTry
        
        Return loResult
    EndProc
EndDefine

*--------------------------------------------------------------------
* CachingDecorator - Caches handler results
*--------------------------------------------------------------------
Define Class CachingDecorator As IHandlerDecorator
    cDecoratorName = "CachingDecorator"
    oCache = .Null.
    nTTLSeconds = 300
    cKeyPrefix = "handler_"
    lEnabled = .T.
    
    Procedure Init(toInnerHandler, toCache, tnTTL)
        DoDefault(toInnerHandler)
        This.oCache = toCache
        If VarType(tnTTL) = 'N'
            This.nTTLSeconds = tnTTL
        EndIf
    EndProc
    
    Procedure Handle(toContext)
        Local loResult, lcCacheKey, loCached
        
        If !This.lEnabled Or VarType(This.oCache) <> 'O'
            Return This.oInner.Handle(toContext)
        EndIf
        
        * Generate cache key
        lcCacheKey = This.GenerateCacheKey(toContext)
        
        * Check cache
        loCached = This.oCache.Get(lcCacheKey)
        If VarType(loCached) = 'O'
            * Restore from cache
            This.RestoreFromCache(toContext, loCached)
            Return toContext
        EndIf
        
        * Execute handler
        loResult = This.oInner.Handle(toContext)
        
        * Cache result if successful
        If !toContext.HasCriticalError
            Local loToCache
            loToCache = This.PrepareForCache(toContext)
            This.oCache.Set(lcCacheKey, loToCache, This.nTTLSeconds)
        EndIf
        
        Return loResult
    EndProc
    
    Protected Procedure GenerateCacheKey(toContext)
        Return This.cKeyPrefix + Transform(toContext.nInvoiceId)
    EndProc
    
    Protected Procedure PrepareForCache(toContext)
        Local loCacheData
        loCacheData = CreateObject("Empty")
        AddProperty(loCacheData, "cResult", toContext.cResult)
        AddProperty(loCacheData, "tCached", DateTime())
        Return loCacheData
    EndProc
    
    Protected Procedure RestoreFromCache(toContext, toCached)
        If PemStatus(toCached, "cResult", 5)
            toContext.cResult = toCached.cResult
        EndIf
    EndProc
EndDefine

*--------------------------------------------------------------------
* RetryDecorator - Retries failed handler executions
*--------------------------------------------------------------------
Define Class RetryDecorator As IHandlerDecorator
    cDecoratorName = "RetryDecorator"
    nMaxRetries = 3
    nBaseDelayMs = 100
    nMaxDelayMs = 5000
    lExponentialBackoff = .T.
    oLogger = .Null.
    Dimension aRetryableErrors[3]
    nRetryableErrorCount = 3
    
    Procedure Init(toInnerHandler, tnMaxRetries)
        DoDefault(toInnerHandler)
        If VarType(tnMaxRetries) = 'N'
            This.nMaxRetries = tnMaxRetries
        EndIf
        
        * Default retryable errors
        This.aRetryableErrors[1] = "TIMEOUT"
        This.aRetryableErrors[2] = "CONNECTION"
        This.aRetryableErrors[3] = "UNAVAILABLE"
    EndProc
    
    Procedure Handle(toContext)
        Local loResult, lnAttempt, loLastError, lcHandlerName
        
        lcHandlerName = ""
        If VarType(This.oInner) = 'O' And PemStatus(This.oInner, "cName", 5)
            lcHandlerName = This.oInner.cName
        EndIf
        
        For lnAttempt = 1 To This.nMaxRetries + 1
            Try
                loResult = This.oInner.Handle(toContext)
                
                * Success - return result
                If !toContext.HasCriticalError
                    If lnAttempt > 1 And VarType(This.oLogger) = 'O'
                        This.oLogger.Info("Handler succeeded after " + ;
                            Transform(lnAttempt) + " attempts")
                    EndIf
                    Return loResult
                EndIf
                
                * Check if error is retryable
                If !This.IsRetryable(toContext.cLastError)
                    Return loResult
                EndIf
                
                loLastError = CreateObject("Empty")
                AddProperty(loLastError, "Message", toContext.cLastError)
                
            Catch To loEx
                loLastError = loEx
                
                If !This.IsRetryable(loEx.Message)
                    Throw loEx
                EndIf
            EndTry
            
            * Last attempt - don't retry
            If lnAttempt > This.nMaxRetries
                Exit
            EndIf
            
            * Log retry
            If VarType(This.oLogger) = 'O'
                This.oLogger.Warning("Retrying " + lcHandlerName + ;
                    " attempt " + Transform(lnAttempt + 1) + "/" + ;
                    Transform(This.nMaxRetries + 1))
            EndIf
            
            * Calculate delay
            Local lnDelay
            If This.lExponentialBackoff
                lnDelay = Min(This.nBaseDelayMs * (2 ^ (lnAttempt - 1)), This.nMaxDelayMs)
            Else
                lnDelay = This.nBaseDelayMs
            EndIf
            
            * Wait before retry
            This.Wait(lnDelay)
            
            * Clear error for retry
            toContext.HasCriticalError = .F.
            toContext.cLastError = ""
        EndFor
        
        * All retries failed
        If VarType(loLastError) = 'O'
            If PemStatus(loLastError, "Message", 5)
                toContext.AddError("All " + Transform(This.nMaxRetries + 1) + ;
                    " attempts failed: " + loLastError.Message)
            EndIf
        EndIf
        
        Return toContext
    EndProc
    
    Protected Procedure IsRetryable(tcError)
        Local lnI
        For lnI = 1 To This.nRetryableErrorCount
            If Upper(tcError) $ Upper(This.aRetryableErrors[lnI])
                Return .T.
            EndIf
        EndFor
        Return .F.
    EndProc
    
    Protected Procedure Wait(tnMilliseconds)
        Local lnSeconds
        lnSeconds = tnMilliseconds / 1000
        * VFP doesn't have native sleep, use loop
        Local lnStart
        lnStart = Seconds()
        Do While Seconds() - lnStart < lnSeconds
            * Busy wait
        EndDo
    EndProc
EndDefine

*--------------------------------------------------------------------
* ValidationDecorator - Validates context before handler
*--------------------------------------------------------------------
Define Class ValidationDecorator As IHandlerDecorator
    cDecoratorName = "ValidationDecorator"
    oSpecification = .Null.
    lStopOnFailure = .T.
    
    Procedure Init(toInnerHandler, toSpecification)
        DoDefault(toInnerHandler)
        This.oSpecification = toSpecification
    EndProc
    
    Procedure Handle(toContext)
        * Validate using specification
        If VarType(This.oSpecification) = 'O'
            If !This.oSpecification.IsSatisfiedBy(toContext)
                Local lcReason
                lcReason = This.oSpecification.GetFailureReason(toContext)
                
                If This.lStopOnFailure
                    toContext.AddError("Validation failed: " + lcReason)
                    toContext.HasCriticalError = .T.
                    Return toContext
                EndIf
            EndIf
        EndIf
        
        Return This.oInner.Handle(toContext)
    EndProc
EndDefine

*--------------------------------------------------------------------
* TransactionDecorator - Wraps handler in transaction
*--------------------------------------------------------------------
Define Class TransactionDecorator As IHandlerDecorator
    cDecoratorName = "TransactionDecorator"
    oLogger = .Null.
    
    Procedure Handle(toContext)
        Local loResult
        
        Begin Transaction
        
        Try
            loResult = This.oInner.Handle(toContext)
            
            If toContext.HasCriticalError
                Rollback
                If VarType(This.oLogger) = 'O'
                    This.oLogger.Warning("Transaction rolled back due to error")
                EndIf
            Else
                End Transaction
                If VarType(This.oLogger) = 'O'
                    This.oLogger.Info("Transaction committed successfully")
                EndIf
            EndIf
            
        Catch To loEx
            Rollback
            If VarType(This.oLogger) = 'O'
                This.oLogger.Error("Transaction rolled back: " + loEx.Message)
            EndIf
            Throw loEx
        EndTry
        
        Return loResult
    EndProc
EndDefine

*--------------------------------------------------------------------
* CircuitBreakerDecorator - Prevents calls to failing service
*--------------------------------------------------------------------
Define Class CircuitBreakerDecorator As IHandlerDecorator
    cDecoratorName = "CircuitBreakerDecorator"
    cState = "CLOSED"  && CLOSED, OPEN, HALF_OPEN
    nFailureCount = 0
    nFailureThreshold = 5
    nSuccessThreshold = 3
    nHalfOpenSuccesses = 0
    nOpenTimeoutSeconds = 30
    tLastFailure = .Null.
    oLogger = .Null.
    
    Procedure Handle(toContext)
        * Check circuit state
        This.CheckState()
        
        If This.cState = "OPEN"
            toContext.AddError("Circuit breaker is OPEN - service unavailable")
            toContext.HasCriticalError = .T.
            Return toContext
        EndIf
        
        Try
            Local loResult
            loResult = This.oInner.Handle(toContext)
            
            If toContext.HasCriticalError
                This.RecordFailure()
            Else
                This.RecordSuccess()
            EndIf
            
            Return loResult
            
        Catch To loEx
            This.RecordFailure()
            Throw loEx
        EndTry
    EndProc
    
    Protected Procedure CheckState
        If This.cState = "OPEN"
            * Check if timeout elapsed
            If VarType(This.tLastFailure) = 'T'
                If DateTime() - This.tLastFailure > This.nOpenTimeoutSeconds
                    This.cState = "HALF_OPEN"
                    This.nHalfOpenSuccesses = 0
                    If VarType(This.oLogger) = 'O'
                        This.oLogger.Info("Circuit breaker entering HALF_OPEN state")
                    EndIf
                EndIf
            EndIf
        EndIf
    EndProc
    
    Protected Procedure RecordFailure
        This.nFailureCount = This.nFailureCount + 1
        This.tLastFailure = DateTime()
        
        If This.cState = "HALF_OPEN"
            This.cState = "OPEN"
            If VarType(This.oLogger) = 'O'
                This.oLogger.Warning("Circuit breaker OPEN (half-open failure)")
            EndIf
        ElseIf This.nFailureCount >= This.nFailureThreshold
            This.cState = "OPEN"
            If VarType(This.oLogger) = 'O'
                This.oLogger.Warning("Circuit breaker OPEN after " + ;
                    Transform(This.nFailureCount) + " failures")
            EndIf
        EndIf
    EndProc
    
    Protected Procedure RecordSuccess
        If This.cState = "HALF_OPEN"
            This.nHalfOpenSuccesses = This.nHalfOpenSuccesses + 1
            If This.nHalfOpenSuccesses >= This.nSuccessThreshold
                This.cState = "CLOSED"
                This.nFailureCount = 0
                If VarType(This.oLogger) = 'O'
                    This.oLogger.Info("Circuit breaker CLOSED - recovered")
                EndIf
            EndIf
        Else
            This.nFailureCount = 0
        EndIf
    EndProc
    
    Procedure Reset
        This.cState = "CLOSED"
        This.nFailureCount = 0
        This.nHalfOpenSuccesses = 0
        This.tLastFailure = .Null.
    EndProc
EndDefine

*--------------------------------------------------------------------
* DecoratorBuilder - Fluent builder for decorated handlers
*--------------------------------------------------------------------
Define Class DecoratorBuilder As Custom
    oHandler = .Null.
    oLogger = .Null.
    oMetrics = .Null.
    oCache = .Null.
    
    Procedure Init(toHandler)
        This.oHandler = toHandler
    EndProc
    
    Procedure WithLogging(toLogger)
        This.oHandler = CreateObject("LoggingDecorator", This.oHandler, toLogger)
        Return This
    EndProc
    
    Procedure WithTiming(toMetrics)
        This.oHandler = CreateObject("TimingDecorator", This.oHandler, toMetrics)
        Return This
    EndProc
    
    Procedure WithCaching(toCache, tnTTL)
        This.oHandler = CreateObject("CachingDecorator", This.oHandler, toCache, tnTTL)
        Return This
    EndProc
    
    Procedure WithRetry(tnMaxRetries)
        This.oHandler = CreateObject("RetryDecorator", This.oHandler, tnMaxRetries)
        Return This
    EndProc
    
    Procedure WithValidation(toSpecification)
        This.oHandler = CreateObject("ValidationDecorator", This.oHandler, toSpecification)
        Return This
    EndProc
    
    Procedure WithTransaction
        This.oHandler = CreateObject("TransactionDecorator", This.oHandler)
        Return This
    EndProc
    
    Procedure WithCircuitBreaker(tnThreshold, tnTimeout)
        Local loDecorator
        loDecorator = CreateObject("CircuitBreakerDecorator", This.oHandler)
        If VarType(tnThreshold) = 'N'
            loDecorator.nFailureThreshold = tnThreshold
        EndIf
        If VarType(tnTimeout) = 'N'
            loDecorator.nOpenTimeoutSeconds = tnTimeout
        EndIf
        This.oHandler = loDecorator
        Return This
    EndProc
    
    Procedure Build
        Return This.oHandler
    EndProc
EndDefine

*====================================================================
* End of DecoratorPattern.prg
*====================================================================
