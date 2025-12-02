*====================================================================
* OutboxPattern.prg - Transactional Outbox Pattern
* Part of eFactura OOP Refactoring - v2.4 Enterprise Edition
*====================================================================
* Outbox Pattern: Guarantee message delivery with transactional writes
*====================================================================

*--------------------------------------------------------------------
* OutboxMessage
*--------------------------------------------------------------------
Define Class OutboxMessage As Custom
    cMessageId = ""
    cMessageType = ""
    cAggregateId = ""
    cAggregateType = ""
    cPayload = ""
    cDestination = ""
    cStatus = "PENDING"  && PENDING, PROCESSING, SENT, FAILED
    tCreatedAt = .Null.
    tProcessedAt = .Null.
    nRetryCount = 0
    nMaxRetries = 3
    cLastError = ""
    
    Procedure Init
        This.cMessageId = Sys(2015) + "_" + Right(Sys(2015), 8)
        This.tCreatedAt = DateTime()
    EndProc
EndDefine

*--------------------------------------------------------------------
* OutboxStore
*--------------------------------------------------------------------
Define Class OutboxStore As Custom
    cStorePath = ""
    cTableName = "outbox_messages"
    oLogger = .Null.
    lInitialized = .F.
    
    Procedure Init
        This.cStorePath = SYS(5) + SYS(2003) + "\Outbox\"
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
                (message_id C(50), ;
                 message_type C(50), ;
                 aggregate_id C(50), ;
                 aggregate_type C(30), ;
                 payload M, ;
                 destination C(100), ;
                 status C(20), ;
                 created_at T, ;
                 processed_at T, ;
                 retry_count I, ;
                 max_retries I, ;
                 last_error M)
            
            Index On message_id Tag msg_id
            Index On status Tag status
            Index On created_at Tag created
        EndIf
        
        This.lInitialized = .T.
    EndProc
    
    *-- Add message to outbox
    Procedure Add(toMessage)
        This.Initialize()
        
        Use (This.cStorePath + This.cTableName) In 0 Alias outbox_write Exclusive
        
        Insert Into outbox_write ;
            (message_id, message_type, aggregate_id, aggregate_type, ;
             payload, destination, status, created_at, retry_count, max_retries) ;
        Values ;
            (toMessage.cMessageId, toMessage.cMessageType, ;
             toMessage.cAggregateId, toMessage.cAggregateType, ;
             toMessage.cPayload, toMessage.cDestination, ;
             "PENDING", toMessage.tCreatedAt, 0, toMessage.nMaxRetries)
        
        Use In outbox_write
        
        If VarType(This.oLogger) = 'O'
            This.oLogger.Info("Outbox: Added message " + toMessage.cMessageId)
        EndIf
    EndProc
    
    *-- Get pending messages
    Procedure GetPending(tnLimit)
        This.Initialize()
        
        Local loMessages, loMessage
        loMessages = CreateObject("Collection")
        
        If Empty(tnLimit)
            tnLimit = 100
        EndIf
        
        Use (This.cStorePath + This.cTableName) In 0 Alias outbox_read Shared
        
        Select Top tnLimit * From outbox_read ;
            Where status = "PENDING" Or ;
                  (status = "FAILED" And retry_count < max_retries) ;
            Order By created_at ;
            Into Cursor pending_msgs
        
        Use In outbox_read
        
        Scan
            loMessage = CreateObject("OutboxMessage")
            loMessage.cMessageId = AllTrim(pending_msgs.message_id)
            loMessage.cMessageType = AllTrim(pending_msgs.message_type)
            loMessage.cAggregateId = AllTrim(pending_msgs.aggregate_id)
            loMessage.cAggregateType = AllTrim(pending_msgs.aggregate_type)
            loMessage.cPayload = pending_msgs.payload
            loMessage.cDestination = AllTrim(pending_msgs.destination)
            loMessage.cStatus = AllTrim(pending_msgs.status)
            loMessage.tCreatedAt = pending_msgs.created_at
            loMessage.nRetryCount = pending_msgs.retry_count
            loMessage.nMaxRetries = pending_msgs.max_retries
            
            loMessages.Add(loMessage)
        EndScan
        
        Use In pending_msgs
        
        Return loMessages
    EndProc
    
    *-- Mark message as processing
    Procedure MarkProcessing(tcMessageId)
        This.Initialize()
        
        Use (This.cStorePath + This.cTableName) In 0 Alias outbox_update Exclusive
        
        Update outbox_update ;
            Set status = "PROCESSING" ;
            Where message_id = tcMessageId
        
        Use In outbox_update
    EndProc
    
    *-- Mark message as sent
    Procedure MarkSent(tcMessageId)
        This.Initialize()
        
        Use (This.cStorePath + This.cTableName) In 0 Alias outbox_update Exclusive
        
        Update outbox_update ;
            Set status = "SENT", processed_at = DateTime() ;
            Where message_id = tcMessageId
        
        Use In outbox_update
        
        If VarType(This.oLogger) = 'O'
            This.oLogger.Info("Outbox: Message sent " + tcMessageId)
        EndIf
    EndProc
    
    *-- Mark message as failed
    Procedure MarkFailed(tcMessageId, tcError)
        This.Initialize()
        
        Use (This.cStorePath + This.cTableName) In 0 Alias outbox_update Exclusive
        
        Update outbox_update ;
            Set status = "FAILED", ;
                retry_count = retry_count + 1, ;
                last_error = tcError ;
            Where message_id = tcMessageId
        
        Use In outbox_update
    EndProc
    
    *-- Cleanup old sent messages
    Procedure Cleanup(tnDaysOld)
        This.Initialize()
        
        If Empty(tnDaysOld)
            tnDaysOld = 7
        EndIf
        
        Local ldCutoff
        ldCutoff = DateTime() - (tnDaysOld * 86400)
        
        Use (This.cStorePath + This.cTableName) In 0 Alias outbox_cleanup Exclusive
        
        Delete From outbox_cleanup ;
            Where status = "SENT" And processed_at < ldCutoff
        
        Pack
        
        Use In outbox_cleanup
    EndProc
EndDefine

*--------------------------------------------------------------------
* OutboxProcessor - Processes outbox messages
*--------------------------------------------------------------------
Define Class OutboxProcessor As Custom
    oOutboxStore = .Null.
    oMessageSenders = .Null.
    oLogger = .Null.
    nBatchSize = 50
    nPollIntervalSeconds = 5
    lRunning = .F.
    
    Procedure Init
        This.oOutboxStore = CreateObject("OutboxStore")
        This.oMessageSenders = CreateObject("Collection")
    EndProc
    
    *-- Register message sender for destination
    Procedure RegisterSender(tcDestination, toSender)
        This.oMessageSenders.Add(toSender, tcDestination)
    EndProc
    
    *-- Process pending messages
    Procedure ProcessBatch
        Local loMessages, loMessage, lnI, loSender
        
        loMessages = This.oOutboxStore.GetPending(This.nBatchSize)
        
        For lnI = 1 To loMessages.Count
            loMessage = loMessages.Item(lnI)
            
            This.oOutboxStore.MarkProcessing(loMessage.cMessageId)
            
            Try
                * Find sender
                loSender = .Null.
                Try
                    loSender = This.oMessageSenders.Item(loMessage.cDestination)
                Catch
                    * Use default sender if available
                    Try
                        loSender = This.oMessageSenders.Item("default")
                    Catch
                    EndTry
                EndTry
                
                If VarType(loSender) = 'O'
                    loSender.Send(loMessage)
                    This.oOutboxStore.MarkSent(loMessage.cMessageId)
                Else
                    This.oOutboxStore.MarkFailed(loMessage.cMessageId, ;
                        "No sender for destination: " + loMessage.cDestination)
                EndIf
                
            Catch To loEx
                This.oOutboxStore.MarkFailed(loMessage.cMessageId, loEx.Message)
            EndTry
        EndFor
        
        Return loMessages.Count
    EndProc
    
    *-- Start background processing
    Procedure Start
        This.lRunning = .T.
        
        Do While This.lRunning
            Local lnProcessed
            lnProcessed = This.ProcessBatch()
            
            If lnProcessed = 0
                * No messages - wait before next poll
                This.Wait(This.nPollIntervalSeconds)
            EndIf
        EndDo
    EndProc
    
    Procedure Stop
        This.lRunning = .F.
    EndProc
    
    Protected Procedure Wait(tnSeconds)
        Local lnStart
        lnStart = Seconds()
        Do While Seconds() - lnStart < tnSeconds And This.lRunning
        EndDo
    EndProc
EndDefine

*--------------------------------------------------------------------
* IMessageSender - Interface for message senders
*--------------------------------------------------------------------
Define Class IMessageSender As Custom
    cName = "BaseMessageSender"
    
    Procedure Send(toMessage)
        Error "Send must be implemented"
    EndProc
EndDefine

*--------------------------------------------------------------------
* HttpMessageSender - Sends via HTTP webhook
*--------------------------------------------------------------------
Define Class HttpMessageSender As IMessageSender
    cName = "HttpMessageSender"
    cEndpointUrl = ""
    nTimeoutSeconds = 30
    
    Procedure Init(tcUrl)
        This.cEndpointUrl = tcUrl
    EndProc
    
    Procedure Send(toMessage)
        Local loHttp, lcUrl
        
        lcUrl = This.cEndpointUrl
        If Empty(lcUrl)
            lcUrl = toMessage.cDestination
        EndIf
        
        loHttp = CreateObject("MSXML2.ServerXMLHTTP.6.0")
        loHttp.Open("POST", lcUrl, .F.)
        loHttp.setRequestHeader("Content-Type", "application/json")
        loHttp.setTimeouts(This.nTimeoutSeconds * 1000, This.nTimeoutSeconds * 1000, ;
            This.nTimeoutSeconds * 1000, This.nTimeoutSeconds * 1000)
        loHttp.Send(toMessage.cPayload)
        
        If loHttp.Status >= 400
            Error "HTTP error: " + Transform(loHttp.Status)
        EndIf
    EndProc
EndDefine

*--------------------------------------------------------------------
* OutboxAwareRepository - Repository with outbox support
*--------------------------------------------------------------------
Define Class OutboxAwareRepository As Custom
    oInnerRepository = .Null.
    oOutboxStore = .Null.
    
    Procedure Init(toRepository)
        This.oInnerRepository = toRepository
        This.oOutboxStore = CreateObject("OutboxStore")
    EndProc
    
    Procedure SaveWithOutbox(toEntity, toOutboxMessage)
        * Save entity and outbox message in same transaction
        Begin Transaction
        
        Try
            * Save entity
            This.oInnerRepository.Save(toEntity)
            
            * Add to outbox
            This.oOutboxStore.Add(toOutboxMessage)
            
            End Transaction
        Catch To loEx
            Rollback
            Throw loEx
        EndTry
    EndProc
EndDefine

*====================================================================
* End of OutboxPattern.prg
*====================================================================
