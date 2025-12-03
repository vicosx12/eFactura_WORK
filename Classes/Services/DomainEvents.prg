*====================================================================
* DomainEvents.prg - Domain Events Implementation
* Part of eFactura OOP Refactoring - v2.4 Enterprise Edition
*====================================================================
* Domain Events: Notify aggregate changes for eventual consistency
*====================================================================

*--------------------------------------------------------------------
* IDomainEvent - Base domain event interface
*--------------------------------------------------------------------
Define Class IDomainEvent As Custom
    cEventId = ""
    cEventType = ""
    cAggregateId = ""
    cAggregateType = ""
    tOccurredAt = .Null.
    cUserId = ""
    
    Procedure Init
        This.cEventId = Sys(2015) + "_" + Right(Sys(2015), 6)
        This.tOccurredAt = DateTime()
    EndProc
EndDefine

*--------------------------------------------------------------------
* Invoice Domain Events
*--------------------------------------------------------------------
Define Class InvoiceCreatedDomainEvent As IDomainEvent
    cEventType = "InvoiceCreated"
    cAggregateType = "Invoice"
    cNumar = ""
    dData = {}
    cCIF = ""
    nValoare = 0
EndDefine

Define Class InvoiceValidatedDomainEvent As IDomainEvent
    cEventType = "InvoiceValidated"
    cAggregateType = "Invoice"
    lValid = .F.
    cValidationErrors = ""
EndDefine

Define Class InvoiceUploadedDomainEvent As IDomainEvent
    cEventType = "InvoiceUploaded"
    cAggregateType = "Invoice"
    cIdSolicitare = ""
    tUploadedAt = .Null.
EndDefine

Define Class InvoiceConfirmedDomainEvent As IDomainEvent
    cEventType = "InvoiceConfirmed"
    cAggregateType = "Invoice"
    cIdDescarcare = ""
EndDefine

Define Class InvoiceCancelledDomainEvent As IDomainEvent
    cEventType = "InvoiceCancelled"
    cAggregateType = "Invoice"
    cMotiv = ""
EndDefine

*--------------------------------------------------------------------
* DomainEventDispatcher
*--------------------------------------------------------------------
Define Class DomainEventDispatcher As Custom
    oHandlers = .Null.
    oLogger = .Null.
    lEnabled = .T.
    
    Procedure Init
        This.oHandlers = CreateObject("Collection")
    EndProc
    
    Procedure Subscribe(tcEventType, toHandler)
        Local loHandlers
        Try
            loHandlers = This.oHandlers.Item(tcEventType)
        Catch
            loHandlers = CreateObject("Collection")
            This.oHandlers.Add(loHandlers, tcEventType)
        EndTry
        loHandlers.Add(toHandler)
    EndProc
    
    Procedure Dispatch(toEvent)
        If !This.lEnabled
            Return
        EndIf
        
        Local loHandlers, lnI
        Try
            loHandlers = This.oHandlers.Item(toEvent.cEventType)
            For lnI = 1 To loHandlers.Count
                Try
                    loHandlers.Item(lnI).Handle(toEvent)
                Catch To loEx
                    If VarType(This.oLogger) = 'O'
                        This.oLogger.Error("Domain event handler error: " + loEx.Message)
                    EndIf
                EndTry
            EndFor
        Catch
            * No handlers
        EndTry
    EndProc
    
    Procedure DispatchAll(toEvents)
        Local lnI
        For lnI = 1 To toEvents.Count
            This.Dispatch(toEvents.Item(lnI))
        EndFor
    EndProc
EndDefine

*--------------------------------------------------------------------
* AggregateRoot - Base with domain events
*--------------------------------------------------------------------
Define Class AggregateRoot As Custom
    cId = ""
    nVersion = 0
    oDomainEvents = .Null.
    
    Procedure Init
        This.oDomainEvents = CreateObject("Collection")
    EndProc
    
    Protected Procedure AddDomainEvent(toEvent)
        toEvent.cAggregateId = This.cId
        This.oDomainEvents.Add(toEvent)
    EndProc
    
    Procedure GetDomainEvents
        Return This.oDomainEvents
    EndProc
    
    Procedure ClearDomainEvents
        This.oDomainEvents = CreateObject("Collection")
    EndProc
EndDefine

*--------------------------------------------------------------------
* InvoiceAggregate with Domain Events
*--------------------------------------------------------------------
Define Class InvoiceAggregateRoot As AggregateRoot
    cNumar = ""
    dData = {}
    cCIF_Vanzator = ""
    cCIF_Cumparator = ""
    nValoare = 0
    cStatus = "DRAFT"
    
    Procedure CreateInvoice(tcNumar, tdData, tcCIF_V, tcCIF_C, tnValoare)
        This.cId = Sys(2015)
        This.cNumar = tcNumar
        This.dData = tdData
        This.cCIF_Vanzator = tcCIF_V
        This.cCIF_Cumparator = tcCIF_C
        This.nValoare = tnValoare
        This.cStatus = "CREATED"
        
        Local loEvent
        loEvent = CreateObject("InvoiceCreatedDomainEvent")
        loEvent.cNumar = tcNumar
        loEvent.dData = tdData
        loEvent.cCIF = tcCIF_V
        loEvent.nValoare = tnValoare
        This.AddDomainEvent(loEvent)
    EndProc
    
    Procedure Validate(tlValid, tcErrors)
        This.cStatus = Iif(tlValid, "VALIDATED", "INVALID")
        
        Local loEvent
        loEvent = CreateObject("InvoiceValidatedDomainEvent")
        loEvent.lValid = tlValid
        loEvent.cValidationErrors = tcErrors
        This.AddDomainEvent(loEvent)
    EndProc
    
    Procedure Upload(tcIdSolicitare)
        This.cStatus = "UPLOADED"
        
        Local loEvent
        loEvent = CreateObject("InvoiceUploadedDomainEvent")
        loEvent.cIdSolicitare = tcIdSolicitare
        loEvent.tUploadedAt = DateTime()
        This.AddDomainEvent(loEvent)
    EndProc
    
    Procedure Confirm(tcIdDescarcare)
        This.cStatus = "CONFIRMED"
        
        Local loEvent
        loEvent = CreateObject("InvoiceConfirmedDomainEvent")
        loEvent.cIdDescarcare = tcIdDescarcare
        This.AddDomainEvent(loEvent)
    EndProc
    
    Procedure Cancel(tcMotiv)
        This.cStatus = "CANCELLED"
        
        Local loEvent
        loEvent = CreateObject("InvoiceCancelledDomainEvent")
        loEvent.cMotiv = tcMotiv
        This.AddDomainEvent(loEvent)
    EndProc
EndDefine

*====================================================================
* End of DomainEvents.prg
*====================================================================
