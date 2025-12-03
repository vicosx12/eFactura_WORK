*====================================================================
* MediatorPattern.prg - Mediator Pattern Implementation
* Part of eFactura OOP Refactoring - v2.4 Enterprise Edition
*====================================================================
* Mediator Pattern: Decoupled request/response handling with
* pipeline behaviors for cross-cutting concerns
*====================================================================

*--------------------------------------------------------------------
* IRequest - Base interface for requests
*--------------------------------------------------------------------
Define Class IRequest As Custom
    cRequestId = ""
    cRequestType = ""
    tTimestamp = .Null.
    cCorrelationId = ""
    
    Procedure Init
        This.cRequestId = Sys(2015)
        This.tTimestamp = DateTime()
    EndProc
EndDefine

*--------------------------------------------------------------------
* IRequestHandler - Handler interface for requests
*--------------------------------------------------------------------
Define Class IRequestHandler As Custom
    cHandlerType = ""
    
    Procedure Handle(toRequest)
        Error "Handle must be implemented"
    EndProc
EndDefine

*--------------------------------------------------------------------
* INotification - Notification that can have multiple handlers
*--------------------------------------------------------------------
Define Class INotification As Custom
    cNotificationId = ""
    cNotificationType = ""
    tTimestamp = .Null.
    
    Procedure Init
        This.cNotificationId = Sys(2015)
        This.tTimestamp = DateTime()
    EndProc
EndDefine

*--------------------------------------------------------------------
* INotificationHandler - Handler for notifications
*--------------------------------------------------------------------
Define Class INotificationHandler As Custom
    
    Procedure Handle(toNotification)
        Error "Handle must be implemented"
    EndProc
EndDefine

*--------------------------------------------------------------------
* IPipelineBehavior - Cross-cutting concern behavior
*--------------------------------------------------------------------
Define Class IPipelineBehavior As Custom
    cBehaviorName = "BaseBehavior"
    nOrder = 100
    
    Procedure Handle(toRequest, toNext)
        * Override to add behavior before/after next
        Return toNext.Invoke(toRequest)
    EndProc
EndDefine

*--------------------------------------------------------------------
* Mediator - Main mediator implementation
*--------------------------------------------------------------------
Define Class Mediator As Custom
    oHandlers = .Null.
    oNotificationHandlers = .Null.
    oPipelineBehaviors = .Null.
    oLogger = .Null.
    oMetrics = .Null.
    
    Procedure Init
        This.oHandlers = CreateObject("Collection")
        This.oNotificationHandlers = CreateObject("Collection")
        This.oPipelineBehaviors = CreateObject("Collection")
    EndProc
    
    *-- Register request handler
    Procedure RegisterHandler(tcRequestType, toHandler)
        This.oHandlers.Add(toHandler, tcRequestType)
    EndProc
    
    *-- Register notification handler
    Procedure RegisterNotificationHandler(tcNotificationType, toHandler)
        Local loHandlers
        
        Try
            loHandlers = This.oNotificationHandlers.Item(tcNotificationType)
        Catch
            loHandlers = CreateObject("Collection")
            This.oNotificationHandlers.Add(loHandlers, tcNotificationType)
        EndTry
        
        loHandlers.Add(toHandler)
    EndProc
    
    *-- Add pipeline behavior
    Procedure AddBehavior(toBehavior)
        * Insert in order
        Local lnI, lnInsertPos
        lnInsertPos = This.oPipelineBehaviors.Count + 1
        
        For lnI = 1 To This.oPipelineBehaviors.Count
            If toBehavior.nOrder < This.oPipelineBehaviors.Item(lnI).nOrder
                lnInsertPos = lnI
                Exit
            EndIf
        EndFor
        
        If lnInsertPos > This.oPipelineBehaviors.Count
            This.oPipelineBehaviors.Add(toBehavior)
        Else
            * VFP doesn't support insert, so rebuild
            Local loNewBehaviors, loItem
            loNewBehaviors = CreateObject("Collection")
            
            For lnI = 1 To This.oPipelineBehaviors.Count
                If lnI = lnInsertPos
                    loNewBehaviors.Add(toBehavior)
                EndIf
                loNewBehaviors.Add(This.oPipelineBehaviors.Item(lnI))
            EndFor
            
            If lnInsertPos > This.oPipelineBehaviors.Count
                loNewBehaviors.Add(toBehavior)
            EndIf
            
            This.oPipelineBehaviors = loNewBehaviors
        EndIf
    EndProc
    
    *-- Send request (expects response)
    Procedure Send(toRequest)
        Local loHandler, loPipeline
        
        * Find handler
        Try
            loHandler = This.oHandlers.Item(toRequest.cRequestType)
        Catch
            Error "No handler registered for: " + toRequest.cRequestType
        EndTry
        
        * Build pipeline
        loPipeline = This.BuildPipeline(loHandler)
        
        * Execute pipeline
        Return loPipeline.Invoke(toRequest)
    EndProc
    
    *-- Publish notification (fire and forget to multiple handlers)
    Procedure Publish(toNotification)
        Local loHandlers, loHandler, lnI
        
        Try
            loHandlers = This.oNotificationHandlers.Item(toNotification.cNotificationType)
        Catch
            * No handlers - OK for notifications
            Return
        EndTry
        
        * Call all handlers
        For lnI = 1 To loHandlers.Count
            loHandler = loHandlers.Item(lnI)
            Try
                loHandler.Handle(toNotification)
            Catch To loEx
                * Log but don't fail
                If VarType(This.oLogger) = 'O'
                    This.oLogger.Error("Notification handler error: " + loEx.Message)
                EndIf
            EndTry
        EndFor
    EndProc
    
    *-- Build pipeline from behaviors
    Protected Procedure BuildPipeline(toFinalHandler)
        Local loPipeline, lnI
        
        * Create pipeline invokable
        loPipeline = CreateObject("PipelineInvokable")
        loPipeline.oFinalHandler = toFinalHandler
        
        * Wrap with behaviors (reverse order)
        For lnI = This.oPipelineBehaviors.Count To 1 Step -1
            Local loBehavior, loWrapper
            loBehavior = This.oPipelineBehaviors.Item(lnI)
            
            loWrapper = CreateObject("BehaviorWrapper")
            loWrapper.oBehavior = loBehavior
            loWrapper.oNext = loPipeline
            
            loPipeline = loWrapper
        EndFor
        
        Return loPipeline
    EndProc
EndDefine

*--------------------------------------------------------------------
* PipelineInvokable - Final handler wrapper
*--------------------------------------------------------------------
Define Class PipelineInvokable As Custom
    oFinalHandler = .Null.
    
    Procedure Invoke(toRequest)
        Return This.oFinalHandler.Handle(toRequest)
    EndProc
EndDefine

*--------------------------------------------------------------------
* BehaviorWrapper - Wraps behavior in invokable
*--------------------------------------------------------------------
Define Class BehaviorWrapper As Custom
    oBehavior = .Null.
    oNext = .Null.
    
    Procedure Invoke(toRequest)
        Return This.oBehavior.Handle(toRequest, This.oNext)
    EndProc
EndDefine

*====================================================================
* Pipeline Behaviors
*====================================================================

*--------------------------------------------------------------------
* LoggingBehavior
*--------------------------------------------------------------------
Define Class LoggingBehavior As IPipelineBehavior
    cBehaviorName = "LoggingBehavior"
    nOrder = 10
    oLogger = .Null.
    
    Procedure Handle(toRequest, toNext)
        Local loResult
        
        If VarType(This.oLogger) = 'O'
            This.oLogger.Info("REQUEST: " + toRequest.cRequestType + ;
                " [" + toRequest.cRequestId + "]")
        EndIf
        
        loResult = toNext.Invoke(toRequest)
        
        If VarType(This.oLogger) = 'O'
            This.oLogger.Info("RESPONSE: " + toRequest.cRequestType + ;
                " completed")
        EndIf
        
        Return loResult
    EndProc
EndDefine

*--------------------------------------------------------------------
* ValidationBehavior
*--------------------------------------------------------------------
Define Class ValidationBehavior As IPipelineBehavior
    cBehaviorName = "ValidationBehavior"
    nOrder = 20
    oValidators = .Null.
    
    Procedure Init
        DoDefault()
        This.oValidators = CreateObject("Collection")
    EndProc
    
    Procedure RegisterValidator(tcRequestType, toValidator)
        This.oValidators.Add(toValidator, tcRequestType)
    EndProc
    
    Procedure Handle(toRequest, toNext)
        Local loValidator
        
        * Find validator for request type
        Try
            loValidator = This.oValidators.Item(toRequest.cRequestType)
            
            * Validate
            Local loResult
            loResult = loValidator.Validate(toRequest)
            
            If !loResult.lValid
                Local loError
                loError = CreateObject("ValidationException")
                loError.cMessage = loResult.GetErrorMessages()
                Throw loError
            EndIf
        Catch To loEx
            If loEx.Class = "ValidationException"
                Throw loEx
            EndIf
            * No validator - continue
        EndTry
        
        Return toNext.Invoke(toRequest)
    EndProc
EndDefine

*--------------------------------------------------------------------
* PerformanceBehavior
*--------------------------------------------------------------------
Define Class PerformanceBehavior As IPipelineBehavior
    cBehaviorName = "PerformanceBehavior"
    nOrder = 30
    oMetrics = .Null.
    nSlowThresholdMs = 500
    oLogger = .Null.
    
    Procedure Handle(toRequest, toNext)
        Local loResult, lnStart, lnDuration
        
        lnStart = Seconds()
        
        loResult = toNext.Invoke(toRequest)
        
        lnDuration = (Seconds() - lnStart) * 1000
        
        * Record metric
        If VarType(This.oMetrics) = 'O'
            This.oMetrics.RecordHistogram("request_duration_ms", lnDuration, ;
                "request_type", toRequest.cRequestType)
        EndIf
        
        * Log slow requests
        If lnDuration > This.nSlowThresholdMs And VarType(This.oLogger) = 'O'
            This.oLogger.Warning("SLOW REQUEST: " + toRequest.cRequestType + ;
                " took " + Transform(lnDuration) + "ms")
        EndIf
        
        Return loResult
    EndProc
EndDefine

*--------------------------------------------------------------------
* AuthorizationBehavior
*--------------------------------------------------------------------
Define Class AuthorizationBehavior As IPipelineBehavior
    cBehaviorName = "AuthorizationBehavior"
    nOrder = 15
    oAuthorizationService = .Null.
    
    Procedure Handle(toRequest, toNext)
        * Check authorization
        If VarType(This.oAuthorizationService) = 'O'
            If !This.oAuthorizationService.IsAuthorized(toRequest)
                Error "Unauthorized: Access denied for " + toRequest.cRequestType
            EndIf
        EndIf
        
        Return toNext.Invoke(toRequest)
    EndProc
EndDefine

*--------------------------------------------------------------------
* CachingBehavior
*--------------------------------------------------------------------
Define Class CachingBehavior As IPipelineBehavior
    cBehaviorName = "CachingBehavior"
    nOrder = 40
    oCache = .Null.
    nDefaultTTL = 300
    oCacheableTypes = .Null.
    
    Procedure Init
        DoDefault()
        This.oCacheableTypes = CreateObject("Collection")
    EndProc
    
    Procedure AddCacheableType(tcRequestType, tnTTL)
        Local loCacheConfig
        loCacheConfig = CreateObject("Empty")
        AddProperty(loCacheConfig, "TTL", Evl(tnTTL, This.nDefaultTTL))
        This.oCacheableTypes.Add(loCacheConfig, tcRequestType)
    EndProc
    
    Procedure Handle(toRequest, toNext)
        Local loCacheConfig, lcCacheKey, loCached
        
        * Check if cacheable
        Try
            loCacheConfig = This.oCacheableTypes.Item(toRequest.cRequestType)
        Catch
            * Not cacheable
            Return toNext.Invoke(toRequest)
        EndTry
        
        * Generate cache key
        lcCacheKey = This.GenerateKey(toRequest)
        
        * Check cache
        If VarType(This.oCache) = 'O'
            loCached = This.oCache.Get(lcCacheKey)
            If VarType(loCached) = 'O'
                Return loCached
            EndIf
        EndIf
        
        * Execute and cache
        Local loResult
        loResult = toNext.Invoke(toRequest)
        
        If VarType(This.oCache) = 'O'
            This.oCache.Set(lcCacheKey, loResult, loCacheConfig.TTL)
        EndIf
        
        Return loResult
    EndProc
    
    Protected Procedure GenerateKey(toRequest)
        Return "mediator_" + toRequest.cRequestType + "_" + toRequest.cRequestId
    EndProc
EndDefine

*--------------------------------------------------------------------
* TransactionBehavior
*--------------------------------------------------------------------
Define Class TransactionBehavior As IPipelineBehavior
    cBehaviorName = "TransactionBehavior"
    nOrder = 50
    oTransactionalTypes = .Null.
    oLogger = .Null.
    
    Procedure Init
        DoDefault()
        This.oTransactionalTypes = CreateObject("Collection")
    EndProc
    
    Procedure AddTransactionalType(tcRequestType)
        This.oTransactionalTypes.Add(.T., tcRequestType)
    EndProc
    
    Procedure Handle(toRequest, toNext)
        Local llTransactional
        
        * Check if transactional
        Try
            llTransactional = This.oTransactionalTypes.Item(toRequest.cRequestType)
        Catch
            llTransactional = .F.
        EndTry
        
        If !llTransactional
            Return toNext.Invoke(toRequest)
        EndIf
        
        * Execute in transaction
        Local loResult
        
        Begin Transaction
        
        Try
            loResult = toNext.Invoke(toRequest)
            End Transaction
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

*====================================================================
* Request/Response Types for eFactura
*====================================================================

*--------------------------------------------------------------------
* ProcessInvoiceRequest
*--------------------------------------------------------------------
Define Class ProcessInvoiceRequest As IRequest
    cRequestType = "ProcessInvoice"
    
    nInvoiceId = 0
    cNumar = ""
    dData = {}
    lRectificativa = .F.
    cAlias = "Iesiri"
EndDefine

*--------------------------------------------------------------------
* ProcessInvoiceResponse
*--------------------------------------------------------------------
Define Class ProcessInvoiceResponse As Custom
    lSuccess = .F.
    cIdSolicitare = ""
    cXmlPath = ""
    cError = ""
    oStats = .Null.
EndDefine

*--------------------------------------------------------------------
* GetInvoiceRequest
*--------------------------------------------------------------------
Define Class GetInvoiceRequest As IRequest
    cRequestType = "GetInvoice"
    nInvoiceId = 0
EndDefine

*--------------------------------------------------------------------
* InvoiceProcessedNotification
*--------------------------------------------------------------------
Define Class InvoiceProcessedNotification As INotification
    cNotificationType = "InvoiceProcessed"
    nInvoiceId = 0
    cIdSolicitare = ""
    lSuccess = .F.
EndDefine

*====================================================================
* Request Handlers
*====================================================================

*--------------------------------------------------------------------
* ProcessInvoiceHandler
*--------------------------------------------------------------------
Define Class ProcessInvoiceHandler As IRequestHandler
    cHandlerType = "ProcessInvoice"
    oFacade = .Null.
    oMediator = .Null.
    
    Procedure Handle(toRequest)
        Local loResponse, lcResult
        
        loResponse = CreateObject("ProcessInvoiceResponse")
        
        Try
            * Process using existing facade
            If VarType(This.oFacade) = 'O'
                lcResult = This.oFacade.Process(toRequest.nInvoiceId, ;
                    toRequest.cAlias, toRequest.lRectificativa, ;
                    "", .F., .F.)
                
                loResponse.lSuccess = !Empty(lcResult) And !"EROARE" $ Upper(lcResult)
                loResponse.cIdSolicitare = lcResult
            EndIf
            
            * Publish notification
            If VarType(This.oMediator) = 'O'
                Local loNotification
                loNotification = CreateObject("InvoiceProcessedNotification")
                loNotification.nInvoiceId = toRequest.nInvoiceId
                loNotification.cIdSolicitare = loResponse.cIdSolicitare
                loNotification.lSuccess = loResponse.lSuccess
                
                This.oMediator.Publish(loNotification)
            EndIf
            
        Catch To loEx
            loResponse.lSuccess = .F.
            loResponse.cError = loEx.Message
        EndTry
        
        Return loResponse
    EndProc
EndDefine

*====================================================================
* End of MediatorPattern.prg
*====================================================================
