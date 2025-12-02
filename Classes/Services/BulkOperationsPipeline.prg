*====================================================================
* BulkOperationsPipeline.prg - Bulk Operations Pipeline
* Part of eFactura OOP Refactoring - v2.4 Enterprise Edition
*====================================================================
* Bulk Operations: Specialized pipeline for massive operations
*====================================================================

*--------------------------------------------------------------------
* BulkOperationContext
*--------------------------------------------------------------------
Define Class BulkOperationContext As Custom
    cOperationId = ""
    cOperationType = ""
    nTotalItems = 0
    nProcessedItems = 0
    nSuccessCount = 0
    nFailedCount = 0
    nSkippedCount = 0
    tStartTime = .Null.
    tEndTime = .Null.
    lCancelled = .F.
    oItems = .Null.
    oResults = .Null.
    oErrors = .Null.
    oConfig = .Null.
    
    Procedure Init
        This.cOperationId = Sys(2015)
        This.tStartTime = DateTime()
        This.oItems = CreateObject("Collection")
        This.oResults = CreateObject("Collection")
        This.oErrors = CreateObject("Collection")
        This.oConfig = CreateObject("Empty")
    EndProc
    
    Procedure GetProgress
        If This.nTotalItems = 0
            Return 0
        EndIf
        Return Round((This.nProcessedItems / This.nTotalItems) * 100, 2)
    EndProc
    
    Procedure GetDuration
        Local ldEnd
        ldEnd = Evl(This.tEndTime, DateTime())
        Return ldEnd - This.tStartTime
    EndProc
    
    Procedure AddResult(tcItemId, tlSuccess, tcMessage)
        Local loResult
        loResult = CreateObject("Empty")
        AddProperty(loResult, "ItemId", tcItemId)
        AddProperty(loResult, "Success", tlSuccess)
        AddProperty(loResult, "Message", tcMessage)
        This.oResults.Add(loResult)
        
        This.nProcessedItems = This.nProcessedItems + 1
        If tlSuccess
            This.nSuccessCount = This.nSuccessCount + 1
        Else
            This.nFailedCount = This.nFailedCount + 1
        EndIf
    EndProc
EndDefine

*--------------------------------------------------------------------
* BulkOperationsPipeline
*--------------------------------------------------------------------
Define Class BulkOperationsPipeline As Custom
    oLogger = .Null.
    oMetrics = .Null.
    oProgressSubject = .Null.
    oEventDispatcher = .Null.
    
    * Configuration
    nBatchSize = 100
    nMaxParallelism = 1  && VFP is single-threaded but can simulate
    nMaxRetries = 3
    lStopOnError = .F.
    nProgressInterval = 10
    
    Procedure Init
    EndProc
    
    *-- Execute bulk operation
    Procedure Execute(toContext, toProcessor)
        Local lnI, lnBatchStart, lnBatchEnd, loItem
        
        * Fire started event
        If VarType(This.oEventDispatcher) = 'O'
            This.oEventDispatcher.Dispatch("BulkOperationStarted", toContext)
        EndIf
        
        * Log start
        If VarType(This.oLogger) = 'O'
            This.oLogger.Info("Bulk operation started: " + toContext.cOperationId + ;
                " - " + Transform(toContext.nTotalItems) + " items")
        EndIf
        
        Try
            * Process in batches
            lnBatchStart = 1
            
            Do While lnBatchStart <= toContext.nTotalItems And !toContext.lCancelled
                lnBatchEnd = Min(lnBatchStart + This.nBatchSize - 1, toContext.nTotalItems)
                
                * Process batch
                This.ProcessBatch(toContext, toProcessor, lnBatchStart, lnBatchEnd)
                
                * Update progress
                This.NotifyProgress(toContext)
                
                lnBatchStart = lnBatchEnd + 1
            EndDo
            
        Catch To loEx
            If VarType(This.oLogger) = 'O'
                This.oLogger.Error("Bulk operation error: " + loEx.Message)
            EndIf
            toContext.oErrors.Add(loEx.Message)
        EndTry
        
        * Complete
        toContext.tEndTime = DateTime()
        
        * Fire completed event
        If VarType(This.oEventDispatcher) = 'O'
            This.oEventDispatcher.Dispatch("BulkOperationCompleted", toContext)
        EndIf
        
        * Log completion
        If VarType(This.oLogger) = 'O'
            This.oLogger.Info("Bulk operation completed: " + ;
                Transform(toContext.nSuccessCount) + " success, " + ;
                Transform(toContext.nFailedCount) + " failed")
        EndIf
        
        Return toContext
    EndProc
    
    *-- Process a batch of items
    Protected Procedure ProcessBatch(toContext, toProcessor, tnStart, tnEnd)
        Local lnI, loItem, llSuccess, lcMessage, lnRetry
        
        For lnI = tnStart To tnEnd
            If toContext.lCancelled
                Exit
            EndIf
            
            loItem = toContext.oItems.Item(lnI)
            
            * Process with retries
            llSuccess = .F.
            lcMessage = ""
            
            For lnRetry = 1 To This.nMaxRetries + 1
                Try
                    toProcessor.Process(loItem)
                    llSuccess = .T.
                    lcMessage = "OK"
                    Exit
                    
                Catch To loEx
                    lcMessage = loEx.Message
                    
                    If lnRetry <= This.nMaxRetries
                        * Wait before retry
                        This.Wait(lnRetry * 100)
                    EndIf
                EndTry
            EndFor
            
            * Record result
            Local lcItemId
            lcItemId = Transform(lnI)
            If PemStatus(loItem, "cId", 5)
                lcItemId = loItem.cId
            ElseIf PemStatus(loItem, "nId", 5)
                lcItemId = Transform(loItem.nId)
            EndIf
            
            toContext.AddResult(lcItemId, llSuccess, lcMessage)
            
            * Stop on error if configured
            If !llSuccess And This.lStopOnError
                toContext.lCancelled = .T.
                Exit
            EndIf
        EndFor
    EndProc
    
    *-- Notify progress
    Protected Procedure NotifyProgress(toContext)
        If VarType(This.oProgressSubject) = 'O'
            This.oProgressSubject.Notify(toContext.GetProgress(), ;
                Transform(toContext.nProcessedItems) + "/" + ;
                Transform(toContext.nTotalItems))
        EndIf
        
        * Record metric
        If VarType(This.oMetrics) = 'O'
            This.oMetrics.SetGauge("bulk_operation_progress", ;
                toContext.GetProgress(), ;
                "operation_id", toContext.cOperationId)
        EndIf
    EndProc
    
    Protected Procedure Wait(tnMs)
        Local lnStart
        lnStart = Seconds()
        Do While (Seconds() - lnStart) * 1000 < tnMs
        EndDo
    EndProc
EndDefine

*--------------------------------------------------------------------
* IBulkItemProcessor - Interface for item processors
*--------------------------------------------------------------------
Define Class IBulkItemProcessor As Custom
    cProcessorName = ""
    
    Procedure Process(toItem)
        Error "Process must be implemented"
    EndProc
EndDefine

*--------------------------------------------------------------------
* InvoiceBulkProcessor
*--------------------------------------------------------------------
Define Class InvoiceBulkProcessor As IBulkItemProcessor
    cProcessorName = "InvoiceBulkProcessor"
    oFacade = .Null.
    cAlias = "Iesiri"
    
    Procedure Process(toItem)
        Local lnInvoiceId
        
        If PemStatus(toItem, "nId", 5)
            lnInvoiceId = toItem.nId
        ElseIf PemStatus(toItem, "id_unic", 5)
            lnInvoiceId = toItem.id_unic
        Else
            Error "Item must have nId or id_unic"
        EndIf
        
        If VarType(This.oFacade) = 'O'
            Local lcResult
            lcResult = This.oFacade.Process(lnInvoiceId, This.cAlias, .F., "", .F., .F.)
            
            If "EROARE" $ Upper(lcResult)
                Error lcResult
            EndIf
        EndIf
    EndProc
EndDefine

*--------------------------------------------------------------------
* BulkOperationBuilder
*--------------------------------------------------------------------
Define Class BulkOperationBuilder As Custom
    oContext = .Null.
    oPipeline = .Null.
    oProcessor = .Null.
    
    Procedure Init
        This.oContext = CreateObject("BulkOperationContext")
        This.oPipeline = CreateObject("BulkOperationsPipeline")
    EndProc
    
    Procedure WithOperationType(tcType)
        This.oContext.cOperationType = tcType
        Return This
    EndProc
    
    Procedure WithItems(toItems)
        Local lnI
        For lnI = 1 To toItems.Count
            This.oContext.oItems.Add(toItems.Item(lnI))
        EndFor
        This.oContext.nTotalItems = toItems.Count
        Return This
    EndProc
    
    Procedure WithBatchSize(tnSize)
        This.oPipeline.nBatchSize = tnSize
        Return This
    EndProc
    
    Procedure WithMaxRetries(tnRetries)
        This.oPipeline.nMaxRetries = tnRetries
        Return This
    EndProc
    
    Procedure StopOnError
        This.oPipeline.lStopOnError = .T.
        Return This
    EndProc
    
    Procedure WithProcessor(toProcessor)
        This.oProcessor = toProcessor
        Return This
    EndProc
    
    Procedure WithLogger(toLogger)
        This.oPipeline.oLogger = toLogger
        Return This
    EndProc
    
    Procedure WithProgress(toProgressSubject)
        This.oPipeline.oProgressSubject = toProgressSubject
        Return This
    EndProc
    
    Procedure Execute
        If VarType(This.oProcessor) <> 'O'
            Error "Processor not set"
        EndIf
        Return This.oPipeline.Execute(This.oContext, This.oProcessor)
    EndProc
EndDefine

*====================================================================
* End of BulkOperationsPipeline.prg
*====================================================================
