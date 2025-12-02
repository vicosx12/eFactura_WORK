*====================================================================
* CQRSService.prg - Command Query Responsibility Segregation
* Part of eFactura OOP Refactoring - v2.4 Enterprise Edition
*====================================================================
* CQRS Pattern: Separates read and write operations for scalability
* and performance optimization
*====================================================================

*--------------------------------------------------------------------
* ICommand - Interface for all commands
*--------------------------------------------------------------------
Define Class ICommand As Custom
    cCommandId = ""
    cCommandType = ""
    tTimestamp = .Null.
    cUserId = ""
    cTenantId = ""
    cCorrelationId = ""
    
    Procedure Init
        This.cCommandId = Sys(2015)
        This.tTimestamp = DateTime()
        This.cCorrelationId = Sys(2015)
    EndProc
    
    Procedure Validate
        * Override in concrete commands
        Return .T.
    EndProc
EndDefine

*--------------------------------------------------------------------
* IQuery - Interface for all queries
*--------------------------------------------------------------------
Define Class IQuery As Custom
    cQueryId = ""
    cQueryType = ""
    tTimestamp = .Null.
    cUserId = ""
    cTenantId = ""
    lCacheable = .F.
    nCacheTTL = 300
    
    Procedure Init
        This.cQueryId = Sys(2015)
        This.tTimestamp = DateTime()
    EndProc
EndDefine

*--------------------------------------------------------------------
* ICommandHandler - Interface for command handlers
*--------------------------------------------------------------------
Define Class ICommandHandler As Custom
    cHandlerName = "ICommandHandler"
    oLogger = .Null.
    oEventDispatcher = .Null.
    
    Procedure Handle(toCommand)
        Error "Handle must be implemented in derived class"
    EndProc
    
    Procedure CanHandle(toCommand)
        Return .T.
    EndProc
EndDefine

*--------------------------------------------------------------------
* IQueryHandler - Interface for query handlers
*--------------------------------------------------------------------
Define Class IQueryHandler As Custom
    cHandlerName = "IQueryHandler"
    oLogger = .Null.
    oCache = .Null.
    
    Procedure Handle(toQuery)
        Error "Handle must be implemented in derived class"
    EndProc
    
    Procedure CanHandle(toQuery)
        Return .T.
    EndProc
EndDefine

*--------------------------------------------------------------------
* Command Classes for eFactura
*--------------------------------------------------------------------
Define Class CreateInvoiceCommand As ICommand
    cCommandType = "CreateInvoice"
    
    * Invoice data
    nInvoiceId = 0
    cNumar = ""
    dData = {}
    cCIF_Vanzator = ""
    cCIF_Cumparator = ""
    nValoareTotala = 0
    nTVA = 0
    cMoneda = "RON"
    lRectificativa = .F.
    oLines = .Null.
    
    Procedure Init
        DoDefault()
        This.oLines = CreateObject("Collection")
    EndProc
    
    Procedure Validate
        If Empty(This.cNumar)
            Return .F.
        EndIf
        If Empty(This.dData)
            Return .F.
        EndIf
        If Empty(This.cCIF_Vanzator)
            Return .F.
        EndIf
        Return .T.
    EndProc
EndDefine

Define Class UploadInvoiceCommand As ICommand
    cCommandType = "UploadInvoice"
    
    nInvoiceId = 0
    cXmlContent = ""
    lTestMode = .F.
    
    Procedure Validate
        Return This.nInvoiceId > 0 And !Empty(This.cXmlContent)
    EndProc
EndDefine

Define Class CancelInvoiceCommand As ICommand
    cCommandType = "CancelInvoice"
    
    nInvoiceId = 0
    cMotiv = ""
    
    Procedure Validate
        Return This.nInvoiceId > 0 And !Empty(This.cMotiv)
    EndProc
EndDefine

Define Class UpdateInvoiceStatusCommand As ICommand
    cCommandType = "UpdateInvoiceStatus"
    
    nInvoiceId = 0
    cNewStatus = ""
    cIdSolicitare = ""
    
    Procedure Validate
        Return This.nInvoiceId > 0 And !Empty(This.cNewStatus)
    EndProc
EndDefine

*--------------------------------------------------------------------
* Query Classes for eFactura
*--------------------------------------------------------------------
Define Class GetInvoiceByIdQuery As IQuery
    cQueryType = "GetInvoiceById"
    nInvoiceId = 0
    lCacheable = .T.
    nCacheTTL = 60
    
    Procedure Init
        DoDefault()
    EndProc
EndDefine

Define Class GetInvoicesListQuery As IQuery
    cQueryType = "GetInvoicesList"
    
    * Filters
    cCIF = ""
    dDataStart = {}
    dDataEnd = {}
    cStatus = ""
    nPage = 1
    nPageSize = 50
    cSortField = "data"
    cSortOrder = "DESC"
    
    lCacheable = .F.  && List queries not cached
EndDefine

Define Class GetInvoiceStatusQuery As IQuery
    cQueryType = "GetInvoiceStatus"
    nInvoiceId = 0
    lCacheable = .T.
    nCacheTTL = 30
EndDefine

Define Class GetInvoiceXmlQuery As IQuery
    cQueryType = "GetInvoiceXml"
    nInvoiceId = 0
    lCacheable = .T.
    nCacheTTL = 3600
EndDefine

Define Class GetInvoiceStatisticsQuery As IQuery
    cQueryType = "GetInvoiceStatistics"
    cCIF = ""
    dDataStart = {}
    dDataEnd = {}
    lCacheable = .T.
    nCacheTTL = 300
EndDefine

*--------------------------------------------------------------------
* Command Handlers
*--------------------------------------------------------------------
Define Class CreateInvoiceCommandHandler As ICommandHandler
    cHandlerName = "CreateInvoiceHandler"
    oRepository = .Null.
    oValidator = .Null.
    
    Procedure Handle(toCommand)
        Local loResult, loInvoice
        
        * Validate command
        If !toCommand.Validate()
            loResult = CreateObject("CommandResult")
            loResult.lSuccess = .F.
            loResult.cError = "Invalid command data"
            Return loResult
        EndIf
        
        Try
            * Create invoice entity
            loInvoice = CreateObject("Empty")
            AddProperty(loInvoice, "Numar", toCommand.cNumar)
            AddProperty(loInvoice, "Data", toCommand.dData)
            AddProperty(loInvoice, "CIF_Vanzator", toCommand.cCIF_Vanzator)
            AddProperty(loInvoice, "CIF_Cumparator", toCommand.cCIF_Cumparator)
            AddProperty(loInvoice, "ValoareTotala", toCommand.nValoareTotala)
            AddProperty(loInvoice, "TVA", toCommand.nTVA)
            AddProperty(loInvoice, "Moneda", toCommand.cMoneda)
            AddProperty(loInvoice, "Status", "DRAFT")
            
            * Save to write model
            If VarType(This.oRepository) = 'O'
                This.oRepository.Save(loInvoice)
            EndIf
            
            * Dispatch domain event
            If VarType(This.oEventDispatcher) = 'O'
                This.oEventDispatcher.Dispatch("InvoiceCreated", loInvoice)
            EndIf
            
            loResult = CreateObject("CommandResult")
            loResult.lSuccess = .T.
            loResult.cMessage = "Invoice created successfully"
            loResult.nInvoiceId = toCommand.nInvoiceId
            
        Catch To loEx
            loResult = CreateObject("CommandResult")
            loResult.lSuccess = .F.
            loResult.cError = loEx.Message
        EndTry
        
        Return loResult
    EndProc
EndDefine

Define Class UploadInvoiceCommandHandler As ICommandHandler
    cHandlerName = "UploadInvoiceHandler"
    oApiClient = .Null.
    oRepository = .Null.
    
    Procedure Handle(toCommand)
        Local loResult, lcResponse
        
        If !toCommand.Validate()
            loResult = CreateObject("CommandResult")
            loResult.lSuccess = .F.
            loResult.cError = "Invalid upload command"
            Return loResult
        EndIf
        
        Try
            * Upload to ANAF
            If VarType(This.oApiClient) = 'O'
                lcResponse = This.oApiClient.Upload(toCommand.cXmlContent, toCommand.lTestMode)
            EndIf
            
            * Update status in write model
            If VarType(This.oRepository) = 'O'
                This.oRepository.UpdateStatus(toCommand.nInvoiceId, "UPLOADED", lcResponse)
            EndIf
            
            * Dispatch event
            If VarType(This.oEventDispatcher) = 'O'
                This.oEventDispatcher.Dispatch("InvoiceUploaded", toCommand.nInvoiceId)
            EndIf
            
            loResult = CreateObject("CommandResult")
            loResult.lSuccess = .T.
            loResult.cMessage = "Invoice uploaded successfully"
            loResult.cIdSolicitare = lcResponse
            
        Catch To loEx
            loResult = CreateObject("CommandResult")
            loResult.lSuccess = .F.
            loResult.cError = loEx.Message
        EndTry
        
        Return loResult
    EndProc
EndDefine

*--------------------------------------------------------------------
* Query Handlers
*--------------------------------------------------------------------
Define Class GetInvoiceByIdQueryHandler As IQueryHandler
    cHandlerName = "GetInvoiceByIdHandler"
    oReadRepository = .Null.
    
    Procedure Handle(toQuery)
        Local loResult, lcCacheKey
        
        * Check cache first
        If toQuery.lCacheable And VarType(This.oCache) = 'O'
            lcCacheKey = "invoice_" + Transform(toQuery.nInvoiceId)
            loResult = This.oCache.Get(lcCacheKey)
            If VarType(loResult) = 'O'
                Return loResult
            EndIf
        EndIf
        
        * Query read model
        If VarType(This.oReadRepository) = 'O'
            loResult = This.oReadRepository.GetById(toQuery.nInvoiceId)
        Else
            loResult = CreateObject("Empty")
        EndIf
        
        * Cache result
        If toQuery.lCacheable And VarType(This.oCache) = 'O' And VarType(loResult) = 'O'
            This.oCache.Set(lcCacheKey, loResult, toQuery.nCacheTTL)
        EndIf
        
        Return loResult
    EndProc
EndDefine

Define Class GetInvoicesListQueryHandler As IQueryHandler
    cHandlerName = "GetInvoicesListHandler"
    oReadRepository = .Null.
    
    Procedure Handle(toQuery)
        Local loResult, lcSql
        
        * Build query for read model
        lcSql = "SELECT * FROM invoices_read WHERE 1=1"
        
        If !Empty(toQuery.cCIF)
            lcSql = lcSql + " AND cif = '" + toQuery.cCIF + "'"
        EndIf
        
        If !Empty(toQuery.dDataStart)
            lcSql = lcSql + " AND data >= {^" + DToC(toQuery.dDataStart) + "}"
        EndIf
        
        If !Empty(toQuery.dDataEnd)
            lcSql = lcSql + " AND data <= {^" + DToC(toQuery.dDataEnd) + "}"
        EndIf
        
        If !Empty(toQuery.cStatus)
            lcSql = lcSql + " AND status = '" + toQuery.cStatus + "'"
        EndIf
        
        lcSql = lcSql + " ORDER BY " + toQuery.cSortField + " " + toQuery.cSortOrder
        
        * Pagination
        Local lnOffset
        lnOffset = (toQuery.nPage - 1) * toQuery.nPageSize
        
        * Execute query
        If VarType(This.oReadRepository) = 'O'
            loResult = This.oReadRepository.Query(lcSql, toQuery.nPageSize, lnOffset)
        Else
            loResult = CreateObject("Collection")
        EndIf
        
        Return loResult
    EndProc
EndDefine

Define Class GetInvoiceStatisticsQueryHandler As IQueryHandler
    cHandlerName = "GetInvoiceStatisticsHandler"
    oReadRepository = .Null.
    
    Procedure Handle(toQuery)
        Local loResult, lcCacheKey
        
        * Check cache
        If toQuery.lCacheable And VarType(This.oCache) = 'O'
            lcCacheKey = "stats_" + toQuery.cCIF + "_" + DToC(toQuery.dDataStart)
            loResult = This.oCache.Get(lcCacheKey)
            If VarType(loResult) = 'O'
                Return loResult
            EndIf
        EndIf
        
        * Build statistics from read model
        loResult = CreateObject("Empty")
        AddProperty(loResult, "nTotalFacturi", 0)
        AddProperty(loResult, "nFacturiIncarcate", 0)
        AddProperty(loResult, "nFacturiErori", 0)
        AddProperty(loResult, "nValoareTotala", 0)
        AddProperty(loResult, "nTVATotal", 0)
        
        * Query read model for statistics
        If VarType(This.oReadRepository) = 'O'
            loResult = This.oReadRepository.GetStatistics(toQuery.cCIF, toQuery.dDataStart, toQuery.dDataEnd)
        EndIf
        
        * Cache result
        If toQuery.lCacheable And VarType(This.oCache) = 'O'
            This.oCache.Set(lcCacheKey, loResult, toQuery.nCacheTTL)
        EndIf
        
        Return loResult
    EndProc
EndDefine

*--------------------------------------------------------------------
* Command/Query Result Classes
*--------------------------------------------------------------------
Define Class CommandResult As Custom
    lSuccess = .F.
    cMessage = ""
    cError = ""
    nInvoiceId = 0
    cIdSolicitare = ""
    oData = .Null.
EndDefine

Define Class QueryResult As Custom
    lSuccess = .F.
    cError = ""
    oData = .Null.
    nTotalCount = 0
    nPage = 1
    nPageSize = 50
EndDefine

*--------------------------------------------------------------------
* CQRS Bus - Dispatches commands and queries
*--------------------------------------------------------------------
Define Class CQRSBus As Custom
    oCommandHandlers = .Null.
    oQueryHandlers = .Null.
    oLogger = .Null.
    oMetrics = .Null.
    
    Procedure Init
        This.oCommandHandlers = CreateObject("Collection")
        This.oQueryHandlers = CreateObject("Collection")
    EndProc
    
    *-- Register command handler
    Procedure RegisterCommandHandler(tcCommandType, toHandler)
        This.oCommandHandlers.Add(toHandler, tcCommandType)
    EndProc
    
    *-- Register query handler
    Procedure RegisterQueryHandler(tcQueryType, toHandler)
        This.oQueryHandlers.Add(toHandler, tcQueryType)
    EndProc
    
    *-- Dispatch command
    Procedure DispatchCommand(toCommand)
        Local loHandler, loResult, lnStartTime
        
        lnStartTime = Seconds()
        
        * Find handler
        Try
            loHandler = This.oCommandHandlers.Item(toCommand.cCommandType)
        Catch
            loResult = CreateObject("CommandResult")
            loResult.lSuccess = .F.
            loResult.cError = "No handler registered for command: " + toCommand.cCommandType
            Return loResult
        EndTry
        
        * Execute handler
        If VarType(This.oLogger) = 'O'
            This.oLogger.Info("Dispatching command: " + toCommand.cCommandType)
        EndIf
        
        loResult = loHandler.Handle(toCommand)
        
        * Record metrics
        If VarType(This.oMetrics) = 'O'
            This.oMetrics.RecordHistogram("command_duration_seconds", ;
                Seconds() - lnStartTime, ;
                "command_type", toCommand.cCommandType)
            
            If loResult.lSuccess
                This.oMetrics.IncrementCounter("commands_success_total", ;
                    "command_type", toCommand.cCommandType)
            Else
                This.oMetrics.IncrementCounter("commands_failed_total", ;
                    "command_type", toCommand.cCommandType)
            EndIf
        EndIf
        
        Return loResult
    EndProc
    
    *-- Dispatch query
    Procedure DispatchQuery(toQuery)
        Local loHandler, loResult, lnStartTime
        
        lnStartTime = Seconds()
        
        * Find handler
        Try
            loHandler = This.oQueryHandlers.Item(toQuery.cQueryType)
        Catch
            loResult = CreateObject("QueryResult")
            loResult.lSuccess = .F.
            loResult.cError = "No handler registered for query: " + toQuery.cQueryType
            Return loResult
        EndTry
        
        * Execute handler
        If VarType(This.oLogger) = 'O'
            This.oLogger.Info("Dispatching query: " + toQuery.cQueryType)
        EndIf
        
        loResult = loHandler.Handle(toQuery)
        
        * Record metrics
        If VarType(This.oMetrics) = 'O'
            This.oMetrics.RecordHistogram("query_duration_seconds", ;
                Seconds() - lnStartTime, ;
                "query_type", toQuery.cQueryType)
        EndIf
        
        Return loResult
    EndProc
    
    *-- Send command (async)
    Procedure SendCommand(toCommand, toCallback)
        * For VFP, we simulate async with immediate execution
        Local loResult
        loResult = This.DispatchCommand(toCommand)
        
        If VarType(toCallback) = 'O'
            toCallback.OnComplete(loResult)
        EndIf
        
        Return loResult
    EndProc
EndDefine

*--------------------------------------------------------------------
* Read Model Projector - Updates read models from events
*--------------------------------------------------------------------
Define Class ReadModelProjector As Custom
    oReadRepository = .Null.
    oEventDispatcher = .Null.
    
    Procedure Init
    EndProc
    
    Procedure SubscribeToEvents(toEventDispatcher)
        This.oEventDispatcher = toEventDispatcher
        
        * Subscribe to domain events
        toEventDispatcher.Subscribe("InvoiceCreated", This, "OnInvoiceCreated")
        toEventDispatcher.Subscribe("InvoiceUploaded", This, "OnInvoiceUploaded")
        toEventDispatcher.Subscribe("InvoiceStatusChanged", This, "OnStatusChanged")
    EndProc
    
    Procedure OnInvoiceCreated(toEvent)
        * Update read model with new invoice
        If VarType(This.oReadRepository) = 'O'
            This.oReadRepository.InsertReadModel(toEvent.oData)
        EndIf
    EndProc
    
    Procedure OnInvoiceUploaded(toEvent)
        * Update read model status
        If VarType(This.oReadRepository) = 'O'
            This.oReadRepository.UpdateReadModelStatus(toEvent.nInvoiceId, "UPLOADED")
        EndIf
    EndProc
    
    Procedure OnStatusChanged(toEvent)
        If VarType(This.oReadRepository) = 'O'
            This.oReadRepository.UpdateReadModelStatus(toEvent.nInvoiceId, toEvent.cNewStatus)
        EndIf
    EndProc
EndDefine

*====================================================================
* End of CQRSService.prg
*====================================================================
