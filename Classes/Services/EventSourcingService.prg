*====================================================================
* EventSourcingService.prg - Event Sourcing Pattern
* Part of eFactura OOP Refactoring - v2.4 Enterprise Edition
*====================================================================
* Event Sourcing: Store events instead of current state, replay for
* full audit trail and temporal queries
*====================================================================

*--------------------------------------------------------------------
* DomainEvent - Base class for all domain events
*--------------------------------------------------------------------
Define Class DomainEvent As Custom
    cEventId = ""
    cEventType = ""
    cAggregateId = ""
    cAggregateType = ""
    nVersion = 0
    tTimestamp = .Null.
    cUserId = ""
    cCorrelationId = ""
    cCausationId = ""
    oData = .Null.
    oMetadata = .Null.
    
    Procedure Init
        This.cEventId = Sys(2015) + "_" + Right(Sys(2015), 8)
        This.tTimestamp = DateTime()
        This.oData = CreateObject("Empty")
        This.oMetadata = CreateObject("Empty")
    EndProc
    
    Procedure ToJson
        Local lcJson
        lcJson = '{'
        lcJson = lcJson + '"eventId":"' + This.cEventId + '",'
        lcJson = lcJson + '"eventType":"' + This.cEventType + '",'
        lcJson = lcJson + '"aggregateId":"' + This.cAggregateId + '",'
        lcJson = lcJson + '"aggregateType":"' + This.cAggregateType + '",'
        lcJson = lcJson + '"version":' + Transform(This.nVersion) + ','
        lcJson = lcJson + '"timestamp":"' + TToC(This.tTimestamp, 1) + '",'
        lcJson = lcJson + '"userId":"' + This.cUserId + '",'
        lcJson = lcJson + '"correlationId":"' + This.cCorrelationId + '"'
        lcJson = lcJson + '}'
        Return lcJson
    EndProc
EndDefine

*--------------------------------------------------------------------
* Invoice Domain Events
*--------------------------------------------------------------------
Define Class InvoiceCreatedEvent As DomainEvent
    cEventType = "InvoiceCreated"
    cAggregateType = "Invoice"
    
    * Event-specific data
    cNumar = ""
    dData = {}
    cCIF_Vanzator = ""
    cCIF_Cumparator = ""
    nValoareTotala = 0
    nTVA = 0
    cMoneda = "RON"
    
    Procedure Init
        DoDefault()
    EndProc
EndDefine

Define Class InvoiceValidatedEvent As DomainEvent
    cEventType = "InvoiceValidated"
    cAggregateType = "Invoice"
    
    lValid = .F.
    cValidationResult = ""
EndDefine

Define Class InvoiceXmlGeneratedEvent As DomainEvent
    cEventType = "InvoiceXmlGenerated"
    cAggregateType = "Invoice"
    
    cXmlHash = ""
    nXmlSize = 0
EndDefine

Define Class InvoiceUploadedEvent As DomainEvent
    cEventType = "InvoiceUploaded"
    cAggregateType = "Invoice"
    
    cIdSolicitare = ""
    cApiResponse = ""
    lTestMode = .F.
EndDefine

Define Class InvoiceConfirmedEvent As DomainEvent
    cEventType = "InvoiceConfirmed"
    cAggregateType = "Invoice"
    
    cIdDescarcare = ""
    tDataConfirmare = .Null.
EndDefine

Define Class InvoiceCancelledEvent As DomainEvent
    cEventType = "InvoiceCancelled"
    cAggregateType = "Invoice"
    
    cMotiv = ""
    tDataAnulare = .Null.
EndDefine

Define Class InvoiceRejectedEvent As DomainEvent
    cEventType = "InvoiceRejected"
    cAggregateType = "Invoice"
    
    cMotivRespingere = ""
    cCodEroare = ""
EndDefine

*--------------------------------------------------------------------
* EventStore - Stores and retrieves events
*--------------------------------------------------------------------
Define Class EventStore As Custom
    cStorePath = ""
    cTableName = "event_store"
    oLogger = .Null.
    lInitialized = .F.
    
    Procedure Init
        This.cStorePath = SYS(5) + SYS(2003) + "\EventStore\"
    EndProc
    
    *-- Initialize event store
    Procedure Initialize
        If This.lInitialized
            Return
        EndIf
        
        * Create directory
        If !Directory(This.cStorePath)
            Md (This.cStorePath)
        EndIf
        
        * Create event store table if not exists
        If !File(This.cStorePath + This.cTableName + ".dbf")
            Create Table (This.cStorePath + This.cTableName) Free ;
                (event_id C(50), ;
                 event_type C(50), ;
                 aggregate_id C(50), ;
                 aggregate_type C(30), ;
                 version I, ;
                 timestamp T, ;
                 user_id C(50), ;
                 correlation_id C(50), ;
                 causation_id C(50), ;
                 event_data M, ;
                 metadata M)
            
            Index On aggregate_id Tag agg_id
            Index On event_type Tag evt_type
            Index On timestamp Tag ts
            Index On aggregate_id + Str(version, 10) Tag agg_ver
        EndIf
        
        This.lInitialized = .T.
    EndProc
    
    *-- Append event to store
    Procedure AppendEvent(toEvent)
        This.Initialize()
        
        Local lcEventData, lcMetadata
        lcEventData = This.SerializeEventData(toEvent)
        lcMetadata = This.SerializeMetadata(toEvent)
        
        Use (This.cStorePath + This.cTableName) In 0 Alias es_write Exclusive
        
        Insert Into es_write ;
            (event_id, event_type, aggregate_id, aggregate_type, ;
             version, timestamp, user_id, correlation_id, causation_id, ;
             event_data, metadata) ;
        Values ;
            (toEvent.cEventId, toEvent.cEventType, toEvent.cAggregateId, ;
             toEvent.cAggregateType, toEvent.nVersion, toEvent.tTimestamp, ;
             toEvent.cUserId, toEvent.cCorrelationId, toEvent.cCausationId, ;
             lcEventData, lcMetadata)
        
        Use In es_write
        
        If VarType(This.oLogger) = 'O'
            This.oLogger.Info("Event appended: " + toEvent.cEventType + ;
                " for aggregate " + toEvent.cAggregateId)
        EndIf
    EndProc
    
    *-- Append multiple events atomically
    Procedure AppendEvents(taEvents)
        This.Initialize()
        
        Local lnI, loEvent
        
        Use (This.cStorePath + This.cTableName) In 0 Alias es_write Exclusive
        
        Begin Transaction
        
        Try
            For lnI = 1 To Alen(taEvents)
                loEvent = taEvents[lnI]
                
                Insert Into es_write ;
                    (event_id, event_type, aggregate_id, aggregate_type, ;
                     version, timestamp, user_id, correlation_id, causation_id, ;
                     event_data, metadata) ;
                Values ;
                    (loEvent.cEventId, loEvent.cEventType, loEvent.cAggregateId, ;
                     loEvent.cAggregateType, loEvent.nVersion, loEvent.tTimestamp, ;
                     loEvent.cUserId, loEvent.cCorrelationId, loEvent.cCausationId, ;
                     This.SerializeEventData(loEvent), This.SerializeMetadata(loEvent))
            EndFor
            
            End Transaction
            
        Catch To loEx
            Rollback
            Use In es_write
            Throw loEx
        EndTry
        
        Use In es_write
    EndProc
    
    *-- Get events for aggregate
    Procedure GetEventsForAggregate(tcAggregateId, tnFromVersion)
        This.Initialize()
        
        Local loEvents, loEvent, lcEventData
        loEvents = CreateObject("Collection")
        
        If Empty(tnFromVersion)
            tnFromVersion = 0
        EndIf
        
        Use (This.cStorePath + This.cTableName) In 0 Alias es_read Shared
        
        Select * From es_read ;
            Where aggregate_id = tcAggregateId ;
            And version > tnFromVersion ;
            Order By version ;
            Into Cursor events_result
        
        Use In es_read
        
        Scan
            loEvent = This.DeserializeEvent(events_result.event_type, events_result.event_data)
            loEvent.cEventId = events_result.event_id
            loEvent.cAggregateId = events_result.aggregate_id
            loEvent.nVersion = events_result.version
            loEvent.tTimestamp = events_result.timestamp
            loEvent.cUserId = events_result.user_id
            loEvent.cCorrelationId = events_result.correlation_id
            
            loEvents.Add(loEvent)
        EndScan
        
        Use In events_result
        
        Return loEvents
    EndProc
    
    *-- Get all events of type
    Procedure GetEventsByType(tcEventType, tdFromDate, tdToDate)
        This.Initialize()
        
        Local loEvents
        loEvents = CreateObject("Collection")
        
        Use (This.cStorePath + This.cTableName) In 0 Alias es_read Shared
        
        Local lcWhere
        lcWhere = "event_type = '" + tcEventType + "'"
        
        If !Empty(tdFromDate)
            lcWhere = lcWhere + " AND timestamp >= {^" + DToC(tdFromDate) + "}"
        EndIf
        
        If !Empty(tdToDate)
            lcWhere = lcWhere + " AND timestamp <= {^" + DToC(tdToDate) + " 23:59:59}"
        EndIf
        
        Select * From es_read ;
            Where &lcWhere ;
            Order By timestamp ;
            Into Cursor events_result
        
        Use In es_read
        
        Scan
            Local loEvent
            loEvent = This.DeserializeEvent(events_result.event_type, events_result.event_data)
            loEvent.cEventId = events_result.event_id
            loEvent.cAggregateId = events_result.aggregate_id
            loEvent.nVersion = events_result.version
            loEvent.tTimestamp = events_result.timestamp
            loEvents.Add(loEvent)
        EndScan
        
        Use In events_result
        
        Return loEvents
    EndProc
    
    *-- Get current version of aggregate
    Procedure GetAggregateVersion(tcAggregateId)
        This.Initialize()
        
        Local lnVersion
        lnVersion = 0
        
        Use (This.cStorePath + This.cTableName) In 0 Alias es_read Shared
        
        Select Max(version) As max_ver From es_read ;
            Where aggregate_id = tcAggregateId ;
            Into Cursor ver_result
        
        Use In es_read
        
        If !IsNull(ver_result.max_ver)
            lnVersion = ver_result.max_ver
        EndIf
        
        Use In ver_result
        
        Return lnVersion
    EndProc
    
    *-- Serialize event data
    Protected Procedure SerializeEventData(toEvent)
        Local lcData
        lcData = toEvent.ToJson()
        Return lcData
    EndProc
    
    *-- Serialize metadata
    Protected Procedure SerializeMetadata(toEvent)
        Local lcMeta
        lcMeta = '{}'
        If VarType(toEvent.oMetadata) = 'O'
            lcMeta = '{"source":"eFactura"}'
        EndIf
        Return lcMeta
    EndProc
    
    *-- Deserialize event
    Protected Procedure DeserializeEvent(tcEventType, tcEventData)
        Local loEvent
        
        Do Case
            Case tcEventType = "InvoiceCreated"
                loEvent = CreateObject("InvoiceCreatedEvent")
            Case tcEventType = "InvoiceValidated"
                loEvent = CreateObject("InvoiceValidatedEvent")
            Case tcEventType = "InvoiceXmlGenerated"
                loEvent = CreateObject("InvoiceXmlGeneratedEvent")
            Case tcEventType = "InvoiceUploaded"
                loEvent = CreateObject("InvoiceUploadedEvent")
            Case tcEventType = "InvoiceConfirmed"
                loEvent = CreateObject("InvoiceConfirmedEvent")
            Case tcEventType = "InvoiceCancelled"
                loEvent = CreateObject("InvoiceCancelledEvent")
            Case tcEventType = "InvoiceRejected"
                loEvent = CreateObject("InvoiceRejectedEvent")
            Otherwise
                loEvent = CreateObject("DomainEvent")
                loEvent.cEventType = tcEventType
        EndCase
        
        Return loEvent
    EndProc
EndDefine

*--------------------------------------------------------------------
* EventSourcedAggregate - Base class for event-sourced aggregates
*--------------------------------------------------------------------
Define Class EventSourcedAggregate As Custom
    cAggregateId = ""
    cAggregateType = "Aggregate"
    nVersion = 0
    oUncommittedEvents = .Null.
    
    Procedure Init
        This.oUncommittedEvents = CreateObject("Collection")
    EndProc
    
    *-- Apply event (for replaying)
    Procedure Apply(toEvent, tlIsFromHistory)
        * Update aggregate state based on event
        This.When(toEvent)
        
        If !tlIsFromHistory
            toEvent.cAggregateId = This.cAggregateId
            toEvent.cAggregateType = This.cAggregateType
            toEvent.nVersion = This.nVersion + 1
            This.nVersion = toEvent.nVersion
            This.oUncommittedEvents.Add(toEvent)
        Else
            This.nVersion = toEvent.nVersion
        EndIf
    EndProc
    
    *-- Abstract method - implement state changes
    Procedure When(toEvent)
        * Override in derived classes
    EndProc
    
    *-- Get uncommitted events
    Procedure GetUncommittedEvents
        Return This.oUncommittedEvents
    EndProc
    
    *-- Clear uncommitted events after persistence
    Procedure ClearUncommittedEvents
        This.oUncommittedEvents = CreateObject("Collection")
    EndProc
    
    *-- Load from history
    Procedure LoadFromHistory(toEvents)
        Local loEvent, lnI
        
        For lnI = 1 To toEvents.Count
            loEvent = toEvents.Item(lnI)
            This.Apply(loEvent, .T.)
        EndFor
    EndProc
EndDefine

*--------------------------------------------------------------------
* InvoiceAggregate - Event-sourced invoice
*--------------------------------------------------------------------
Define Class InvoiceAggregate As EventSourcedAggregate
    cAggregateType = "Invoice"
    
    * Current state (rebuilt from events)
    cNumar = ""
    dData = {}
    cCIF_Vanzator = ""
    cCIF_Cumparator = ""
    nValoareTotala = 0
    nTVA = 0
    cMoneda = "RON"
    cStatus = "NEW"
    cIdSolicitare = ""
    lValidated = .F.
    lUploaded = .F.
    lConfirmed = .F.
    lCancelled = .F.
    
    *-- Create new invoice
    Procedure Create(tcNumar, tdData, tcCIF_Vanzator, tcCIF_Cumparator, tnValoare, tnTVA, tcMoneda)
        Local loEvent
        loEvent = CreateObject("InvoiceCreatedEvent")
        loEvent.cNumar = tcNumar
        loEvent.dData = tdData
        loEvent.cCIF_Vanzator = tcCIF_Vanzator
        loEvent.cCIF_Cumparator = tcCIF_Cumparator
        loEvent.nValoareTotala = tnValoare
        loEvent.nTVA = tnTVA
        loEvent.cMoneda = Evl(tcMoneda, "RON")
        
        This.Apply(loEvent, .F.)
    EndProc
    
    *-- Validate invoice
    Procedure Validate(tlValid, tcResult)
        If This.lCancelled
            Error "Cannot validate cancelled invoice"
        EndIf
        
        Local loEvent
        loEvent = CreateObject("InvoiceValidatedEvent")
        loEvent.lValid = tlValid
        loEvent.cValidationResult = tcResult
        
        This.Apply(loEvent, .F.)
    EndProc
    
    *-- Generate XML
    Procedure GenerateXml(tcXmlHash, tnXmlSize)
        If !This.lValidated
            Error "Invoice must be validated before generating XML"
        EndIf
        
        Local loEvent
        loEvent = CreateObject("InvoiceXmlGeneratedEvent")
        loEvent.cXmlHash = tcXmlHash
        loEvent.nXmlSize = tnXmlSize
        
        This.Apply(loEvent, .F.)
    EndProc
    
    *-- Upload to ANAF
    Procedure Upload(tcIdSolicitare, tcResponse, tlTestMode)
        Local loEvent
        loEvent = CreateObject("InvoiceUploadedEvent")
        loEvent.cIdSolicitare = tcIdSolicitare
        loEvent.cApiResponse = tcResponse
        loEvent.lTestMode = tlTestMode
        
        This.Apply(loEvent, .F.)
    EndProc
    
    *-- Confirm upload
    Procedure Confirm(tcIdDescarcare)
        If !This.lUploaded
            Error "Invoice must be uploaded before confirmation"
        EndIf
        
        Local loEvent
        loEvent = CreateObject("InvoiceConfirmedEvent")
        loEvent.cIdDescarcare = tcIdDescarcare
        loEvent.tDataConfirmare = DateTime()
        
        This.Apply(loEvent, .F.)
    EndProc
    
    *-- Cancel invoice
    Procedure Cancel(tcMotiv)
        If This.lConfirmed
            Error "Cannot cancel confirmed invoice"
        EndIf
        
        Local loEvent
        loEvent = CreateObject("InvoiceCancelledEvent")
        loEvent.cMotiv = tcMotiv
        loEvent.tDataAnulare = DateTime()
        
        This.Apply(loEvent, .F.)
    EndProc
    
    *-- State changes based on events
    Procedure When(toEvent)
        Do Case
            Case toEvent.cEventType = "InvoiceCreated"
                This.cNumar = toEvent.cNumar
                This.dData = toEvent.dData
                This.cCIF_Vanzator = toEvent.cCIF_Vanzator
                This.cCIF_Cumparator = toEvent.cCIF_Cumparator
                This.nValoareTotala = toEvent.nValoareTotala
                This.nTVA = toEvent.nTVA
                This.cMoneda = toEvent.cMoneda
                This.cStatus = "CREATED"
                
            Case toEvent.cEventType = "InvoiceValidated"
                This.lValidated = toEvent.lValid
                If toEvent.lValid
                    This.cStatus = "VALIDATED"
                Else
                    This.cStatus = "VALIDATION_FAILED"
                EndIf
                
            Case toEvent.cEventType = "InvoiceXmlGenerated"
                This.cStatus = "XML_GENERATED"
                
            Case toEvent.cEventType = "InvoiceUploaded"
                This.lUploaded = .T.
                This.cIdSolicitare = toEvent.cIdSolicitare
                This.cStatus = "UPLOADED"
                
            Case toEvent.cEventType = "InvoiceConfirmed"
                This.lConfirmed = .T.
                This.cStatus = "CONFIRMED"
                
            Case toEvent.cEventType = "InvoiceCancelled"
                This.lCancelled = .T.
                This.cStatus = "CANCELLED"
                
            Case toEvent.cEventType = "InvoiceRejected"
                This.cStatus = "REJECTED"
        EndCase
    EndProc
EndDefine

*--------------------------------------------------------------------
* AggregateRepository - Loads/saves event-sourced aggregates
*--------------------------------------------------------------------
Define Class AggregateRepository As Custom
    oEventStore = .Null.
    oSnapshotStore = .Null.
    nSnapshotThreshold = 100  && Create snapshot every 100 events
    
    Procedure Init
        This.oEventStore = CreateObject("EventStore")
    EndProc
    
    *-- Load aggregate by ID
    Procedure Load(tcAggregateId, tcAggregateType)
        Local loAggregate, loEvents
        
        * Create aggregate instance
        Do Case
            Case tcAggregateType = "Invoice"
                loAggregate = CreateObject("InvoiceAggregate")
            Otherwise
                loAggregate = CreateObject("EventSourcedAggregate")
        EndCase
        
        loAggregate.cAggregateId = tcAggregateId
        
        * Try to load from snapshot first
        Local loSnapshot, lnSnapshotVersion
        lnSnapshotVersion = 0
        
        If VarType(This.oSnapshotStore) = 'O'
            loSnapshot = This.oSnapshotStore.GetLatest(tcAggregateId)
            If VarType(loSnapshot) = 'O'
                This.RestoreFromSnapshot(loAggregate, loSnapshot)
                lnSnapshotVersion = loAggregate.nVersion
            EndIf
        EndIf
        
        * Load events after snapshot
        loEvents = This.oEventStore.GetEventsForAggregate(tcAggregateId, lnSnapshotVersion)
        
        * Replay events to rebuild state
        loAggregate.LoadFromHistory(loEvents)
        
        Return loAggregate
    EndProc
    
    *-- Save aggregate
    Procedure Save(toAggregate)
        Local loEvents, loEvent, lnI
        
        loEvents = toAggregate.GetUncommittedEvents()
        
        If loEvents.Count = 0
            Return
        EndIf
        
        * Convert to array for batch append
        Dimension laEvents[loEvents.Count]
        For lnI = 1 To loEvents.Count
            laEvents[lnI] = loEvents.Item(lnI)
        EndFor
        
        * Append events
        This.oEventStore.AppendEvents(@laEvents)
        
        * Clear uncommitted events
        toAggregate.ClearUncommittedEvents()
        
        * Check if snapshot needed
        If VarType(This.oSnapshotStore) = 'O'
            If toAggregate.nVersion Mod This.nSnapshotThreshold = 0
                This.CreateSnapshot(toAggregate)
            EndIf
        EndIf
    EndProc
    
    *-- Create snapshot
    Protected Procedure CreateSnapshot(toAggregate)
        If VarType(This.oSnapshotStore) = 'O'
            This.oSnapshotStore.Save(toAggregate)
        EndIf
    EndProc
    
    *-- Restore from snapshot
    Protected Procedure RestoreFromSnapshot(toAggregate, toSnapshot)
        * Copy snapshot state to aggregate
    EndProc
EndDefine

*--------------------------------------------------------------------
* EventProjection - Projects events to read models
*--------------------------------------------------------------------
Define Class EventProjection As Custom
    cProjectionName = "BaseProjection"
    nLastProcessedVersion = 0
    oEventStore = .Null.
    
    Procedure Project(toEvent)
        * Override in derived classes
    EndProc
    
    Procedure Rebuild
        * Replay all events from beginning
        Local loEvents, loEvent, lnI
        
        This.nLastProcessedVersion = 0
        This.Reset()
        
        loEvents = This.oEventStore.GetEventsForAggregate("*", 0)
        
        For lnI = 1 To loEvents.Count
            loEvent = loEvents.Item(lnI)
            This.Project(loEvent)
            This.nLastProcessedVersion = loEvent.nVersion
        EndFor
    EndProc
    
    Procedure Reset
        * Override to clear projection state
    EndProc
EndDefine

*--------------------------------------------------------------------
* InvoiceListProjection - Read model for invoice list
*--------------------------------------------------------------------
Define Class InvoiceListProjection As EventProjection
    cProjectionName = "InvoiceList"
    cTablePath = ""
    
    Procedure Init
        DoDefault()
        This.cTablePath = SYS(5) + SYS(2003) + "\ReadModels\invoices_list.dbf"
    EndProc
    
    Procedure Project(toEvent)
        Do Case
            Case toEvent.cEventType = "InvoiceCreated"
                This.InsertInvoice(toEvent)
                
            Case toEvent.cEventType = "InvoiceUploaded"
                This.UpdateStatus(toEvent.cAggregateId, "UPLOADED", toEvent.cIdSolicitare)
                
            Case toEvent.cEventType = "InvoiceConfirmed"
                This.UpdateStatus(toEvent.cAggregateId, "CONFIRMED", "")
                
            Case toEvent.cEventType = "InvoiceCancelled"
                This.UpdateStatus(toEvent.cAggregateId, "CANCELLED", "")
        EndCase
    EndProc
    
    Protected Procedure InsertInvoice(toEvent)
        * Insert into read model table
    EndProc
    
    Protected Procedure UpdateStatus(tcAggregateId, tcStatus, tcIdSolicitare)
        * Update read model
    EndProc
    
    Procedure Reset
        * Clear and recreate read model table
    EndProc
EndDefine

*====================================================================
* End of EventSourcingService.prg
*====================================================================
