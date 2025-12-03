*====================================================================
* IdempotencyService.prg - Idempotency Pattern Implementation
* Part of eFactura OOP Refactoring - v2.4 Enterprise Edition
*====================================================================
* Idempotency: Guarantee that operations can be retried safely
*====================================================================

*--------------------------------------------------------------------
* IdempotencyService
*--------------------------------------------------------------------
Define Class IdempotencyService As Custom
    cStorePath = ""
    cTableName = "idempotency_keys"
    nDefaultTTLHours = 24
    oLogger = .Null.
    lInitialized = .F.
    
    Procedure Init
        This.cStorePath = SYS(5) + SYS(2003) + "\Idempotency\"
    EndProc
    
    Procedure Initialize
        If This.lInitialized
            Return
        EndIf
        
        If !Directory(This.cStorePath)
            Md (This.cStorePath)
        EndIf
        
        If !File(This.cStorePath + This.cTableName + ".dbf")
            Create Table (This.cStorePath + This.cTableName) Free ;
                (idempotency_key C(100), ;
                 request_hash C(64), ;
                 status C(20), ;
                 response M, ;
                 created_at T, ;
                 expires_at T, ;
                 completed_at T)
            
            Index On idempotency_key Tag idem_key
            Index On expires_at Tag expires
        EndIf
        
        This.lInitialized = .T.
    EndProc
    
    *-- Check if request was already processed
    Procedure CheckIdempotency(tcKey, tcRequestHash)
        This.Initialize()
        This.CleanupExpired()
        
        Local loResult
        loResult = CreateObject("IdempotencyResult")
        
        Use (This.cStorePath + This.cTableName) In 0 Alias idem_read Shared
        
        Locate For idempotency_key = tcKey
        
        If Found()
            loResult.lExists = .T.
            loResult.cStatus = AllTrim(idem_read.status)
            
            Do Case
                Case loResult.cStatus = "COMPLETED"
                    loResult.lCanProceed = .F.
                    loResult.lHasResponse = .T.
                    loResult.cResponse = idem_read.response
                    
                Case loResult.cStatus = "PROCESSING"
                    loResult.lCanProceed = .F.
                    loResult.lIsProcessing = .T.
                    
                Case loResult.cStatus = "FAILED"
                    * Allow retry on failure
                    loResult.lCanProceed = .T.
            EndCase
        Else
            loResult.lExists = .F.
            loResult.lCanProceed = .T.
        EndIf
        
        Use In idem_read
        
        Return loResult
    EndProc
    
    *-- Start processing (mark as in-progress)
    Procedure StartProcessing(tcKey, tcRequestHash)
        This.Initialize()
        
        Local ldExpires
        ldExpires = DateTime() + (This.nDefaultTTLHours * 3600)
        
        Use (This.cStorePath + This.cTableName) In 0 Alias idem_write Exclusive
        
        Locate For idempotency_key = tcKey
        
        If Found()
            Replace status With "PROCESSING", ;
                    created_at With DateTime() ;
                In idem_write
        Else
            Insert Into idem_write ;
                (idempotency_key, request_hash, status, created_at, expires_at) ;
            Values ;
                (tcKey, tcRequestHash, "PROCESSING", DateTime(), ldExpires)
        EndIf
        
        Use In idem_write
        
        If VarType(This.oLogger) = 'O'
            This.oLogger.Info("Idempotency: Started processing " + tcKey)
        EndIf
    EndProc
    
    *-- Complete processing with response
    Procedure CompleteProcessing(tcKey, tcResponse)
        This.Initialize()
        
        Use (This.cStorePath + This.cTableName) In 0 Alias idem_write Exclusive
        
        Locate For idempotency_key = tcKey
        
        If Found()
            Replace status With "COMPLETED", ;
                    response With tcResponse, ;
                    completed_at With DateTime() ;
                In idem_write
        EndIf
        
        Use In idem_write
        
        If VarType(This.oLogger) = 'O'
            This.oLogger.Info("Idempotency: Completed " + tcKey)
        EndIf
    EndProc
    
    *-- Mark as failed (allows retry)
    Procedure MarkFailed(tcKey, tcError)
        This.Initialize()
        
        Use (This.cStorePath + This.cTableName) In 0 Alias idem_write Exclusive
        
        Locate For idempotency_key = tcKey
        
        If Found()
            Replace status With "FAILED", ;
                    response With tcError ;
                In idem_write
        EndIf
        
        Use In idem_write
    EndProc
    
    *-- Generate idempotency key from request
    Procedure GenerateKey(toRequest)
        Local lcKey
        lcKey = ""
        
        If PemStatus(toRequest, "cIdempotencyKey", 5)
            lcKey = toRequest.cIdempotencyKey
        EndIf
        
        If Empty(lcKey) And PemStatus(toRequest, "nInvoiceId", 5)
            lcKey = "invoice_" + Transform(toRequest.nInvoiceId) + "_" + ;
                    Transform(Date()) + "_" + Transform(Seconds())
        EndIf
        
        If Empty(lcKey)
            lcKey = Sys(2015) + "_" + Right(Sys(2015), 8)
        EndIf
        
        Return lcKey
    EndProc
    
    *-- Generate hash of request for verification
    Procedure GenerateHash(toRequest)
        Local lcData
        lcData = ""
        
        If PemStatus(toRequest, "nInvoiceId", 5)
            lcData = lcData + Transform(toRequest.nInvoiceId)
        EndIf
        If PemStatus(toRequest, "cNumar", 5)
            lcData = lcData + toRequest.cNumar
        EndIf
        
        * Simple hash
        Return Sys(2007, lcData)
    EndProc
    
    *-- Cleanup expired keys
    Protected Procedure CleanupExpired
        Use (This.cStorePath + This.cTableName) In 0 Alias idem_cleanup Exclusive
        
        Delete From idem_cleanup Where expires_at < DateTime()
        Pack
        
        Use In idem_cleanup
    EndProc
EndDefine

*--------------------------------------------------------------------
* IdempotencyResult
*--------------------------------------------------------------------
Define Class IdempotencyResult As Custom
    lExists = .F.
    lCanProceed = .F.
    lHasResponse = .F.
    lIsProcessing = .F.
    cStatus = ""
    cResponse = ""
EndDefine

*--------------------------------------------------------------------
* IdempotentHandler - Decorator for idempotent operations
*--------------------------------------------------------------------
Define Class IdempotentHandler As Custom
    oInner = .Null.
    oIdempotencyService = .Null.
    
    Procedure Init(toInnerHandler, toIdempotencyService)
        This.oInner = toInnerHandler
        This.oIdempotencyService = toIdempotencyService
    EndProc
    
    Procedure Handle(toContext)
        Local lcKey, lcHash, loCheck, loResult
        
        * Generate idempotency key
        lcKey = This.oIdempotencyService.GenerateKey(toContext)
        lcHash = This.oIdempotencyService.GenerateHash(toContext)
        
        * Check existing
        loCheck = This.oIdempotencyService.CheckIdempotency(lcKey, lcHash)
        
        If !loCheck.lCanProceed
            If loCheck.lHasResponse
                * Return cached response
                toContext.cResult = loCheck.cResponse
                Return toContext
            EndIf
            
            If loCheck.lIsProcessing
                toContext.AddError("Request is already being processed")
                Return toContext
            EndIf
        EndIf
        
        * Start processing
        This.oIdempotencyService.StartProcessing(lcKey, lcHash)
        
        Try
            * Execute handler
            loResult = This.oInner.Handle(toContext)
            
            * Store response
            Local lcResponse
            lcResponse = Evl(toContext.cResult, "OK")
            This.oIdempotencyService.CompleteProcessing(lcKey, lcResponse)
            
        Catch To loEx
            This.oIdempotencyService.MarkFailed(lcKey, loEx.Message)
            Throw loEx
        EndTry
        
        Return loResult
    EndProc
EndDefine

*====================================================================
* End of IdempotencyService.prg
*====================================================================
