# eFactura_Work - Usage Examples and Documentation

This document provides comprehensive examples for using the refactored eFactura_Work architecture.

## Table of Contents
1. [Basic Usage](#basic-usage)
2. [XML Generation](#xml-generation)
3. [Invoice Status Checking](#invoice-status-checking)
4. [Invoice Download](#invoice-download)
5. [Error Handling](#error-handling)
6. [Advanced Scenarios](#advanced-scenarios)
7. [Monitoring and Observability](#monitoring-and-observability)

---

## Basic Usage

### Legacy Mode (Backward Compatible)
```foxpro
* Old style - continues to work unchanged
Do eFactura_Work With 12345, .F., "", .F., "Iesiri", .F.
```

### New Architecture Mode
```foxpro
* Enable new architecture
Public glUseNewArchitecture
glUseNewArchitecture = .T.

* Process invoice with new architecture
Do eFactura_Work With 12345, .F., "", .F., "Iesiri", .F.
```

### Direct Facade Usage
```foxpro
* Create facade instance
loFacade = CreateObject("EFacturaFacade")

* Attach progress observer (optional)
loProgressBar = CreateObject("ProgressBarObserver")
loFacade.AttachProgressObserver(loProgressBar)

* Process invoice
lcResult = loFacade.Process(12345, "Iesiri", .F., "", .F., .F.)

If Empty(lcResult)
    MessageBox("Invoice processed successfully!")
Else
    MessageBox("Error: " + lcResult)
EndIf
```

---

## XML Generation

### Example 1: B2B Invoice (Standard Business-to-Business)
```foxpro
* Create invoice builder
loBuilder = CreateObject("InvoiceBuilder")

* Build invoice with fluent interface
loInvoice = loBuilder;
    .WithHeader("FAC-2025-001", Date(), "B2B");
    .WithSeller("12345678", "SC COMPANY SRL", "RO", "Bucharest");
    .WithBuyer("87654321", "SC CLIENT SRL", "RO", "Cluj");
    .AddLine(1, "Servicii consultanta", 1000.00, 19);
    .AddLine(2, "Servicii dezvoltare", 2000.00, 19);
    .Build()

* Generate XML using B2B strategy
loFactory = CreateObject("XmlStrategyFactory")
loStrategy = loFactory.Create("B2B", "RO", .F.)
lcXml = loStrategy.GenerateXml(loInvoice)

* Validate XML before sending
loValidator = CreateObject("XmlSchemaValidator")
llValid = loValidator.Validate(lcXml)

If llValid
    * Save XML to file
    StrToFile(lcXml, "invoices\FAC-2025-001.xml")
    ? "XML generated successfully"
Else
    * Show validation errors
    ? "Validation errors:"
    For i = 1 To loValidator.GetErrorCount()
        ? loValidator.GetError(i)
    EndFor
EndIf
```

### Example 2: B2C Invoice (Business-to-Consumer)
```foxpro
* B2C invoice with simplified fields
loBuilder = CreateObject("InvoiceBuilder")

loInvoice = loBuilder;
    .WithHeader("FAC-2025-002", Date(), "B2C");
    .WithSeller("12345678", "SC SHOP SRL", "RO", "Bucharest");
    .WithBuyer("", "Ion Popescu", "RO", "");
    .AddLine(1, "Produs A", 150.00, 19);
    .AddLine(2, "Produs B", 250.00, 19);
    .WithPaymentMethod("CASH");
    .Build()

loStrategy = CreateObject("B2CXmlStrategy")
lcXml = loStrategy.GenerateXml(loInvoice)

* Generate PDF preview
loPdfGen = CreateObject("PdfGenerator")
lcPdfPath = loPdfGen.GenerateFromXml(lcXml, "invoices\FAC-2025-002.pdf")
```

### Example 3: Export Invoice (International)
```foxpro
* Export invoice with foreign currency
loBuilder = CreateObject("InvoiceBuilder")

loInvoice = loBuilder;
    .WithHeader("FAC-2025-003", Date(), "Export");
    .WithSeller("12345678", "SC EXPORT SRL", "RO", "Bucharest");
    .WithBuyer("DE123456", "German Company GmbH", "DE", "Berlin");
    .WithCurrency("EUR", 4.975);
    .AddLine(1, "Product A", 1000.00, 0);
    .AddLine(2, "Product B", 2000.00, 0);
    .WithIncoterms("FOB", "Hamburg");
    .Build()

loStrategy = CreateObject("ExportXmlStrategy")
lcXml = loStrategy.GenerateXml(loInvoice)

* Encrypt sensitive data before transmission
loEncryption = CreateObject("EncryptionService")
loEncryption.Initialize("AES256", "MySecretKey123")
lcEncrypted = loEncryption.Encrypt(lcXml)
```

### Example 4: Reverse Charge Invoice
```foxpro
* Invoice with tax reverse charge
loBuilder = CreateObject("InvoiceBuilder")

loInvoice = loBuilder;
    .WithHeader("FAC-2025-004", Date(), "T");
    .WithSeller("12345678", "SC SERVICES SRL", "RO", "Bucharest");
    .WithBuyer("87654321", "SC CONSTRUCTOR SRL", "RO", "Timisoara");
    .WithReverseCharge(.T.);
    .AddLine(1, "Servicii constructii", 5000.00, 19);
    .Build()

loFactory = CreateObject("XmlStrategyFactory")
loStrategy = loFactory.Create("T", "RO", .F.)
lcXml = loStrategy.GenerateXml(loInvoice)
```

---

## Invoice Status Checking

### Example 1: Simple Status Check
```foxpro
* Check invoice status
loFacade = CreateObject("EFacturaFacade")
loStatus = loFacade.CheckInvoiceStatus("ID_SOLICITARE_12345")

If IsObject(loStatus)
    Do Case
        Case loStatus.Status = "ok"
            ? "Invoice accepted by ANAF"
            ? "Download index: " + Transform(loStatus.DownloadId)
            
        Case loStatus.Status = "nok"
            ? "Invoice rejected by ANAF"
            ? "Error: " + loStatus.ErrorMessage
            
        Case loStatus.Status = "in prelucrare"
            ? "Invoice still processing..."
            
    EndCase
EndIf
```

### Example 2: Polling with Retry Logic
```foxpro
* Poll for status with exponential backoff
loRetry = CreateObject("RetryPolicy")
loRetry.SetMaxAttempts(10)
loRetry.SetInitialDelay(2)
loRetry.SetBackoffMultiplier(1.5)

lcSolicitareId = "ID_SOLICITARE_12345"
loFacade = CreateObject("EFacturaFacade")

llSuccess = loRetry.Execute(Function(tcId)
    loStatus = loFacade.CheckInvoiceStatus(tcId)
    Return (loStatus.Status != "in prelucrare")
EndFunc, lcSolicitareId)

If llSuccess
    ? "Final status: " + loStatus.Status
Else
    ? "Timeout waiting for invoice processing"
EndIf
```

### Example 3: Event-Driven Status Monitoring
```foxpro
* Use event dispatcher for status updates
loDispatcher = CreateObject("EventDispatcher")

* Register event handlers
loDispatcher.Subscribe("InvoiceAccepted", "HandleAccepted")
loDispatcher.Subscribe("InvoiceRejected", "HandleRejected")

* Check status and dispatch events
loStatus = loFacade.CheckInvoiceStatus(lcSolicitareId)

Do Case
    Case loStatus.Status = "ok"
        loDispatcher.Dispatch("InvoiceAccepted", loStatus)
    Case loStatus.Status = "nok"
        loDispatcher.Dispatch("InvoiceRejected", loStatus)
EndCase

* Event handlers
Procedure HandleAccepted(toStatus)
    ? "✓ Invoice accepted!"
    * Download receipt
    Do DownloadReceipt With toStatus.DownloadId
EndProc

Procedure HandleRejected(toStatus)
    ? "✗ Invoice rejected: " + toStatus.ErrorMessage
    * Log error for audit
    loAudit = CreateObject("AuditService")
    loAudit.LogAction("INVOICE_REJECTED", toStatus.InvoiceId, toStatus.ErrorMessage)
EndProc
```

### Example 4: Webhook Integration
```foxpro
* Register webhook for ANAF notifications
loWebhook = CreateObject("WebhookManager")

* Register endpoint for status updates
loWebhook.RegisterEndpoint("invoice-status", "https://myserver.com/webhooks/invoice-status")

* Handle incoming webhook
Procedure HandleWebhook(toRequest)
    Local loPayload
    loPayload = JsonDecode(toRequest.Body)
    
    Do Case
        Case loPayload.Status = "ok"
            ? "Webhook: Invoice accepted"
            * Update database
            loRepo = CreateObject("IesiriRepository")
            loRepo.UpdateStatus(loPayload.InvoiceId, "ACCEPTED", loPayload.SolicitareId)
            
        Case loPayload.Status = "nok"
            ? "Webhook: Invoice rejected"
            * Send notification
            loNotif = CreateObject("NotificationService")
            loNotif.SendEmail("admin@company.com", "Invoice Rejected", loPayload.ErrorMessage)
    EndCase
EndProc
```

---

## Invoice Download

### Example 1: Download Invoice Receipt
```foxpro
* Download processed invoice from ANAF
loFacade = CreateObject("EFacturaFacade")
lcDownloadId = "12345"

lcZipContent = loFacade.DownloadInvoice(lcDownloadId)

If !Empty(lcZipContent)
    * Save ZIP file
    lcZipPath = "downloads\invoice_" + Transform(lcDownloadId) + ".zip"
    StrToFile(lcZipContent, lcZipPath)
    
    * Extract ZIP
    loBackup = CreateObject("BackupService")
    loBackup.ExtractZip(lcZipPath, "downloads\invoice_" + Transform(lcDownloadId))
    
    ? "Invoice downloaded and extracted"
Else
    ? "Download failed"
EndIf
```

### Example 2: Generate PDF from Downloaded XML
```foxpro
* Download and generate PDF
lcXmlPath = "downloads\invoice_12345\factura.xml"
lcXml = FileToStr(lcXmlPath)

* Generate PDF with custom template
loPdfGen = CreateObject("PdfGenerator")
loTemplate = CreateObject("ReportTemplateEngine")
loTemplate.LoadTemplate("templates\invoice.html")

lcHtml = loTemplate.Render(lcXml)
lcPdf = loPdfGen.GenerateFromHtml(lcHtml, "downloads\invoice_12345.pdf")

* Preview in browser
loPdfGen.PreviewInBrowser(lcPdf)
```

### Example 3: Batch Download
```foxpro
* Download multiple invoices
loBatch = CreateObject("BatchProcessor")

* Import list of download IDs
loBatch.ImportCsv("downloads\invoice_ids.csv")

* Process batch with progress tracking
loProgress = CreateObject("ProgressSubject")
loProgress.Attach(CreateObject("ProgressBarObserver"))

loBatch.ProcessBatch(Function(tcDownloadId, toProgress)
    Local lcContent, lcPath
    lcContent = loFacade.DownloadInvoice(tcDownloadId)
    
    If !Empty(lcContent)
        lcPath = "downloads\batch\invoice_" + tcDownloadId + ".zip"
        StrToFile(lcContent, lcPath)
        toProgress.Notify(0, "Downloaded: " + tcDownloadId)
        Return .T.
    Else
        toProgress.Notify(0, "Failed: " + tcDownloadId)
        Return .F.
    EndIf
EndFunc, loProgress)

* Generate summary report
loReport = loBatch.GenerateSummaryReport()
? "Downloaded: " + Transform(loReport.SuccessCount)
? "Failed: " + Transform(loReport.FailedCount)
```

---

## Error Handling

### Example 1: Validation Errors
```foxpro
* Handle validation errors with detailed messages
Try
    loFacade = CreateObject("EFacturaFacade")
    lcResult = loFacade.Process(12345, "Iesiri", .F., "", .F., .F.)
    
Catch To loEx When loEx.ErrorNo = 1001
    * Validation error
    ? "Validation failed:"
    loContext = loFacade.GetContext()
    
    For Each lcError In loContext.ValidationErrors
        ? "  - " + lcError
    EndFor
    
    * Log for audit
    loAudit = CreateObject("AuditService")
    loAudit.LogAction("VALIDATION_FAILED", 12345, JsonEncode(loContext.ValidationErrors))
    
Catch To loEx
    * Other errors
    ? "Unexpected error: " + loEx.Message
EndTry
```

### Example 2: API Communication Errors with Retry
```foxpro
* Retry API calls with circuit breaker
loRetry = CreateObject("RetryPolicy")
loRetry.SetMaxAttempts(3)
loRetry.EnableCircuitBreaker(.T.)

loCircuit = CreateObject("CircuitBreakerAggregator")
loCircuit.RegisterService("ANAF_API")

Try
    llSuccess = loRetry.Execute(Function(tnInvoiceId)
        * Check circuit breaker state
        If loCircuit.IsOpen("ANAF_API")
            Throw "Circuit breaker is OPEN - service unavailable"
        EndIf
        
        * Attempt API call
        loFacade = CreateObject("EFacturaFacade")
        lcResult = loFacade.Process(tnInvoiceId, "Iesiri", .F., "", .F., .F.)
        
        If Empty(lcResult)
            loCircuit.RecordSuccess("ANAF_API")
            Return .T.
        Else
            loCircuit.RecordFailure("ANAF_API")
            Return .F.
        EndIf
    EndFunc, 12345)
    
    If llSuccess
        ? "Invoice processed after retry"
    Else
        ? "All retry attempts failed"
    EndIf
    
Catch To loEx
    ? "Circuit breaker error: " + loEx.Message
    
    * Send alert
    loNotif = CreateObject("NotificationService")
    loNotif.SendSms("+40700000000", "ANAF API circuit breaker OPEN")
EndTry
```

### Example 3: Compensation on Failure
```foxpro
* Use Saga pattern for compensation
loSaga = CreateObject("SagaOrchestrator")

* Define saga steps with compensation
loSaga.AddStep("ValidateInvoice", "CompensateValidation")
loSaga.AddStep("GenerateXml", "CompensateXml")
loSaga.AddStep("UploadToAnaf", "CompensateUpload")
loSaga.AddStep("UpdateDatabase", "CompensateDatabase")

Try
    * Execute saga
    loSaga.Execute(Function(toContext)
        * Step 1: Validate
        toContext.CurrentStep = "ValidateInvoice"
        If !ValidateInvoice(toContext)
            Throw "Validation failed"
        EndIf
        
        * Step 2: Generate XML
        toContext.CurrentStep = "GenerateXml"
        toContext.Xml = GenerateXml(toContext)
        
        * Step 3: Upload
        toContext.CurrentStep = "UploadToAnaf"
        toContext.SolicitareId = UploadToAnaf(toContext.Xml)
        
        * Step 4: Update DB
        toContext.CurrentStep = "UpdateDatabase"
        UpdateDatabase(toContext.InvoiceId, toContext.SolicitareId)
        
        Return .T.
    EndFunc)
    
    ? "Saga completed successfully"
    
Catch To loEx
    ? "Saga failed at step: " + loSaga.GetFailedStep()
    ? "Error: " + loEx.Message
    
    * Automatic compensation
    loSaga.Compensate()
    ? "Compensation completed"
EndTry
```

### Example 4: Comprehensive Error Handling with Audit Trail
```foxpro
* Complete error handling with logging and recovery
Procedure ProcessInvoiceWithFullErrorHandling(tnInvoiceId)
    Local loFacade, loAudit, loLogger, loMetrics, lcResult, lcCorrelationId
    
    * Initialize services
    loFacade = CreateObject("EFacturaFacade")
    loAudit = CreateObject("AuditService")
    loLogger = CreateObject("LoggerService")
    loMetrics = CreateObject("MetricsCollector")
    
    * Generate correlation ID for distributed tracing
    loTracer = CreateObject("DistributedTracer")
    lcCorrelationId = loTracer.StartSpan("ProcessInvoice")
    
    Try
        * Start metrics
        loMetrics.StartTimer("invoice_processing_time")
        loLogger.Info("Processing invoice " + Transform(tnInvoiceId))
        
        * Process invoice
        lcResult = loFacade.Process(tnInvoiceId, "Iesiri", .F., "", .F., .F.)
        
        If Empty(lcResult)
            * Success
            loLogger.Info("Invoice processed successfully")
            loMetrics.IncrementCounter("invoices_processed")
            loAudit.LogAction("INVOICE_PROCESSED", tnInvoiceId, "SUCCESS")
            
            MessageBox("Factura procesată cu succes!")
        Else
            * Business error
            loLogger.Warning("Invoice processing failed: " + lcResult)
            loMetrics.IncrementCounter("invoices_failed")
            loAudit.LogAction("INVOICE_FAILED", tnInvoiceId, lcResult)
            
            MessageBox("Eroare procesare: " + lcResult)
        EndIf
        
    Catch To loEx
        * Technical error
        loLogger.Error("Exception processing invoice: " + loEx.Message)
        loMetrics.IncrementCounter("invoices_error")
        loAudit.LogAction("INVOICE_EXCEPTION", tnInvoiceId, loEx.Message + " at line " + Transform(loEx.LineNo))
        
        * Check if recoverable
        If IsRecoverable(loEx)
            * Retry with backoff
            loLogger.Info("Attempting recovery...")
            Wait Window "Reîncerc procesarea..." Timeout 2
            
            loRetry = CreateObject("RetryPolicy")
            llRecovered = loRetry.Execute(Function(tnId)
                Return Empty(loFacade.Process(tnId, "Iesiri", .F., "", .F., .F.))
            EndFunc, tnInvoiceId)
            
            If llRecovered
                loLogger.Info("Recovery successful")
                MessageBox("Procesare reușită după reîncercare!")
            Else
                loLogger.Error("Recovery failed")
                MessageBox("Eroare: " + loEx.Message)
            EndIf
        Else
            * Not recoverable
            MessageBox("Eroare critică: " + loEx.Message)
        EndIf
        
    Finally
        * Always execute cleanup
        loMetrics.StopTimer("invoice_processing_time")
        loTracer.EndSpan(lcCorrelationId)
        
        * Export metrics
        loMetrics.ExportPrometheus("metrics\invoice_" + Transform(tnInvoiceId) + ".txt")
    EndTry
EndProc

Function IsRecoverable(toException)
    * Determine if error is recoverable
    Do Case
        Case toException.ErrorNo = 1429  && OLE IDispatch exception (network)
            Return .T.
        Case toException.ErrorNo = 1958  && SQL connection error
            Return .T.
        Otherwise
            Return .F.
    EndCase
EndFunc
```

---

## Advanced Scenarios

### Example 1: Batch Processing with CSV Import
```foxpro
* Process multiple invoices from CSV
loBatch = CreateObject("BatchProcessor")

* Configure batch
loBatch.SetBatchSize(10)
loBatch.SetMaxParallelThreads(3)

* Import invoices from CSV
* CSV format: InvoiceId,Alias,IsRectificativa
loBatch.ImportCsv("imports\invoices.csv")

* Process with retry on failed items
loResults = loBatch.ProcessBatch(Function(toRow, toProgress)
    Local lcResult
    
    lcResult = loFacade.Process(;
        Val(toRow.InvoiceId), ;
        toRow.Alias, ;
        (toRow.IsRectificativa = "Y"), ;
        "", .F., .F.)
    
    If Empty(lcResult)
        toProgress.Notify(0, "✓ " + toRow.InvoiceId)
        Return .T.
    Else
        toProgress.Notify(0, "✗ " + toRow.InvoiceId + ": " + lcResult)
        Return .F.
    EndIf
EndFunc)

* Retry failed items
If loResults.FailedCount > 0
    ? "Retrying " + Transform(loResults.FailedCount) + " failed items..."
    loBatch.RetryFailed()
EndIf

* Generate and export report
loReport = loBatch.GenerateSummaryReport()
loBatch.ExportCsv("exports\batch_results_" + DToS(Date()) + ".csv")

? "Batch complete:"
? "  Success: " + Transform(loReport.SuccessCount)
? "  Failed: " + Transform(loReport.FailedCount)
? "  Duration: " + Transform(loReport.TotalSeconds) + "s"
```

### Example 2: Multi-Tenant Operation
```foxpro
* Process invoices for multiple companies
loTenant = CreateObject("TenantManager")

* Register tenants
loTenant.RegisterTenant("TENANT_001", "SC COMPANY A SRL", "12345678")
loTenant.RegisterTenant("TENANT_002", "SC COMPANY B SRL", "87654321")

* Process for specific tenant
loTenant.SetCurrentTenant("TENANT_001")

* All operations are now scoped to TENANT_001
loFacade = CreateObject("EFacturaFacade")
loFacade.Process(12345, "Iesiri", .F., "", .F., .F.)

* Switch tenant
loTenant.SetCurrentTenant("TENANT_002")
loFacade.Process(67890, "Iesiri", .F., "", .F., .F.)

* Tenant isolation in cache
loCache = CreateObject("CacheService")
loCache.SetTenantScoped(.T.)

* Each tenant has separate cache
loCache.Set("config", "value1")  && Stored for TENANT_002

loTenant.SetCurrentTenant("TENANT_001")
lcValue = loCache.Get("config")  && Returns NULL (different tenant)
```

### Example 3: Distributed Processing with Locks
```foxpro
* Process invoice with distributed lock
loLock = CreateObject("DistributedLockService")

lcLockKey = "invoice_12345"
llAcquired = loLock.AcquireLock(lcLockKey, 30)  && 30 second timeout

If llAcquired
    Try
        * Only one process can execute this
        loFacade = CreateObject("EFacturaFacade")
        loFacade.Process(12345, "Iesiri", .F., "", .F., .F.)
        
        ? "Invoice processed with exclusive lock"
        
    Finally
        * Always release lock
        loLock.ReleaseLock(lcLockKey)
    EndTry
Else
    ? "Could not acquire lock - invoice being processed elsewhere"
EndIf

* Lock with automatic renewal
loLock.AcquireLockWithRenewal(lcLockKey, 10, 5)  && 10s timeout, renew every 5s

Try
    * Long running operation
    * Lock is automatically renewed
    Do LongRunningProcess With 12345
Finally
    loLock.ReleaseLock(lcLockKey)
EndTry
```

### Example 4: Event Sourcing for Audit
```foxpro
* Store all invoice events for complete audit trail
loEventStore = CreateObject("EventSourcingService")

* Initialize event store
loEventStore.InitializeEventStore("invoice_events")

* Process invoice and capture all events
loInvoiceId = 12345

* Event 1: Invoice created
loEventStore.AppendEvent("InvoiceCreated", loInvoiceId, JsonEncode({;
    "InvoiceId": loInvoiceId, ;
    "CreatedBy": "user123", ;
    "CreatedAt": DateTime();
}))

* Event 2: Invoice validated
loEventStore.AppendEvent("InvoiceValidated", loInvoiceId, JsonEncode({;
    "InvoiceId": loInvoiceId, ;
    "ValidationResult": "OK";
}))

* Event 3: Invoice uploaded
loEventStore.AppendEvent("InvoiceUploaded", loInvoiceId, JsonEncode({;
    "InvoiceId": loInvoiceId, ;
    "SolicitareId": "ABC123", ;
    "UploadedAt": DateTime();
}))

* Replay events to rebuild state
loEvents = loEventStore.GetEvents(loInvoiceId)
loState = RebuildInvoiceState(loEvents)

* Create projection for reporting
loProjection = loEventStore.CreateProjection("InvoiceStatusReport")
loProjection.Project(loEvents)

* Query projection
loReport = loProjection.Query("SELECT * FROM InvoiceStatusReport WHERE Status = 'Uploaded'")
```

### Example 5: CQRS for Read/Write Separation
```foxpro
* Separate command and query models
loCqrs = CreateObject("CQRSService")

* COMMAND: Process invoice (write)
loCommand = loCqrs.CreateCommand("ProcessInvoice")
loCommand.SetParameter("InvoiceId", 12345)
loCommand.SetParameter("Alias", "Iesiri")

loResult = loCqrs.ExecuteCommand(loCommand)

* QUERY: Read invoice status (read-only)
loQuery = loCqrs.CreateQuery("GetInvoiceStatus")
loQuery.SetParameter("InvoiceId", 12345)

loStatus = loCqrs.ExecuteQuery(loQuery)

* Query from read replica for reports
loReadReplica = CreateObject("ReadReplicaService")
loReadReplica.RegisterReplica("REPLICA_1", "server1", 5432)
loReadReplica.RegisterReplica("REPLICA_2", "server2", 5432)

* Query is automatically routed to replica
loResults = loReadReplica.ExecuteQuery(;
    "SELECT * FROM invoices WHERE status = 'uploaded' AND created_date >= ?", ;
    Date() - 30)
```

### Example 6: Saga Orchestration for Complex Workflow
```foxpro
* Orchestrate complex multi-step invoice processing
loSaga = CreateObject("SagaOrchestrator")

* Define saga with compensation
loSaga.AddStep("ReserveInventory", "ReleaseInventory")
loSaga.AddStep("ProcessPayment", "RefundPayment")
loSaga.AddStep("GenerateInvoice", "CancelInvoice")
loSaga.AddStep("SendToAnaf", "RevokeAnaf")
loSaga.AddStep("NotifyCustomer", "")

* Execute saga with context
loContext = CreateObject("Empty")
AddProperty(loContext, "OrderId", 12345)
AddProperty(loContext, "CustomerId", "CUST001")
AddProperty(loContext, "Amount", 1000.00)

Try
    loSaga.Execute(loContext)
    ? "Order processed successfully"
    
Catch To loEx
    * Automatic compensation of completed steps
    ? "Saga failed, compensating..."
    loSaga.Compensate(loContext)
    ? "Compensation complete"
EndTry

* Saga state persistence
loSaga.SaveState("saga_states\order_12345.json")

* Resume saga after restart
loSaga.LoadState("saga_states\order_12345.json")
loSaga.Resume(loContext)
```

### Example 7: Chaos Engineering Testing
```foxpro
* Test system resilience with chaos engineering
loChaos = CreateObject("ChaosEngineeringService")

* Configure failure scenarios
loChaos.EnableScenario("NetworkLatency", 0.2)  && 20% of requests
loChaos.EnableScenario("ServiceTimeout", 0.1)  && 10% of requests
loChaos.EnableScenario("DatabaseError", 0.05)  && 5% of requests

* Run test
? "Starting chaos test..."
lnSuccessCount = 0
lnFailCount = 0

For i = 1 To 100
    Try
        lcResult = loFacade.Process(i, "Iesiri", .F., "", .F., .F.)
        If Empty(lcResult)
            lnSuccessCount = lnSuccessCount + 1
        Else
            lnFailCount = lnFailCount + 1
        EndIf
    Catch
        lnFailCount = lnFailCount + 1
    EndTry
Next

? "Chaos test results:"
? "  Success: " + Transform(lnSuccessCount)
? "  Failed: " + Transform(lnFailCount)
? "  Success rate: " + Transform(lnSuccessCount / 100 * 100, "999.99") + "%"

* Disable chaos
loChaos.DisableAllScenarios()
```

---

## Monitoring and Observability

### Example 1: Health Checks
```foxpro
* Perform comprehensive health check
loHealth = CreateObject("HealthChecker")

* Check all subsystems
loHealth.CheckAnafConnectivity()
loHealth.CheckDatabaseConnection()
loHealth.CheckDiskSpace()
loHealth.CheckMemoryUsage()

* Get overall health status
lcStatus = loHealth.GetOverallStatus()  && "healthy", "degraded", or "unhealthy"

If lcStatus = "healthy"
    ? "✓ All systems operational"
Else
    ? "⚠ System health: " + lcStatus
    
    * Get detailed report
    loReport = loHealth.GetHealthReport()
    ? JsonEncode(loReport)
    
    * Send alert
    If lcStatus = "unhealthy"
        loNotif = CreateObject("NotificationService")
        loNotif.SendEmail("admin@company.com", "System Health Alert", JsonEncode(loReport))
    EndIf
EndIf
```

### Example 2: Metrics Collection
```foxpro
* Collect and export metrics
loMetrics = CreateObject("MetricsCollector")

* Record metrics
loMetrics.IncrementCounter("http_requests_total", "endpoint=/api/invoice")
loMetrics.SetGauge("active_connections", 42)
loMetrics.RecordHistogram("request_duration_seconds", 0.245)

* Add labels
loMetrics.IncrementCounter("invoices_processed", "status=success,tenant=ACME")

* Export in Prometheus format
lcMetrics = loMetrics.ExportPrometheus()
StrToFile(lcMetrics, "metrics\metrics.txt")

* Metrics content example:
* # TYPE http_requests_total counter
* http_requests_total{endpoint="/api/invoice"} 1523
* # TYPE active_connections gauge
* active_connections 42
* # TYPE request_duration_seconds histogram
* request_duration_seconds_sum 125.3
* request_duration_seconds_count 512
```

### Example 3: Distributed Tracing
```foxpro
* Trace request across multiple services
loTracer = CreateObject("DistributedTracer")

* Start root span
lcTraceId = loTracer.StartSpan("ProcessInvoiceRequest")

Try
    * Child span 1: Database query
    lcSpan1 = loTracer.StartSpan("DatabaseQuery", lcTraceId)
    * ... do database work ...
    loTracer.EndSpan(lcSpan1, "success")
    
    * Child span 2: XML generation
    lcSpan2 = loTracer.StartSpan("GenerateXml", lcTraceId)
    * ... generate XML ...
    loTracer.EndSpan(lcSpan2, "success")
    
    * Child span 3: API call
    lcSpan3 = loTracer.StartSpan("AnafApiCall", lcTraceId)
    * ... call ANAF API ...
    loTracer.EndSpan(lcSpan3, "success")
    
    loTracer.EndSpan(lcTraceId, "success")
    
Catch To loEx
    * Record error in trace
    loTracer.EndSpan(lcTraceId, "error", loEx.Message)
EndTry

* Export trace in Zipkin/Jaeger format
lcTrace = loTracer.ExportZipkin()
StrToFile(lcTrace, "traces\trace_" + lcTraceId + ".json")

* View trace timeline
loTracer.DisplayTimeline(lcTraceId)
```

### Example 4: Audit Logging
```foxpro
* Comprehensive audit logging
loAudit = CreateObject("AuditService")

* Initialize audit log
loAudit.InitializeLog("audit_logs\")

* Log user actions
loAudit.LogAction("USER_LOGIN", "user123", "John Doe logged in")
loAudit.LogAction("INVOICE_CREATE", 12345, "Invoice FAC-2025-001 created")
loAudit.LogAction("INVOICE_UPLOAD", 12345, "Invoice uploaded to ANAF")
loAudit.LogAction("INVOICE_DOWNLOAD", 12345, "Receipt downloaded")

* Log with structured data
loAudit.LogAction("INVOICE_MODIFY", 12345, JsonEncode({;
    "Field": "Total", ;
    "OldValue": 1000.00, ;
    "NewValue": 1200.00, ;
    "Reason": "Price correction";
}))

* Query audit log
loResults = loAudit.QueryLog(;
    "WHERE action = ? AND timestamp >= ?", ;
    "INVOICE_UPLOAD", DateTime() - (24 * 3600))

* Export for compliance
loAudit.ExportToJson("audit_exports\audit_" + DToS(Date()) + ".json")

* Cleanup old entries (GDPR compliance)
loAudit.CleanupOldEntries(365)  && Keep 1 year
```

### Example 5: Performance Monitoring
```foxpro
* Monitor performance metrics
loStats = CreateObject("StatsCollector")

* Start operation tracking
loStats.Start("InvoiceProcessing")

* Track individual operations
loStats.RecordOperation("DatabaseQuery", 0.125)
loStats.RecordOperation("XmlGeneration", 0.345)
loStats.RecordOperation("AnafApiCall", 1.234)
loStats.RecordOperation("PersistenceUpdate", 0.089)

* Stop tracking
loStats.Stop()

* Get statistics
? "Total duration: " + Transform(loStats.GetDuration(), "999.999") + "s"
? "Record count: " + Transform(loStats.RecordCount)
? "Error count: " + Transform(loStats.ErrorCount)

* Performance analysis
loAnalysis = loStats.GetPerformanceAnalysis()
? "Slowest operation: " + loAnalysis.SlowestOperation
? "Average time: " + Transform(loAnalysis.AverageTime, "999.999") + "s"

* Alert on performance degradation
If loStats.GetDuration() > 5.0
    loNotif = CreateObject("NotificationService")
    loNotif.SendSms("+40700000000", "Performance alert: Processing took " + Transform(loStats.GetDuration()) + "s")
EndIf
```

---

## Summary

This documentation covers the most common usage patterns for the refactored eFactura_Work architecture. For more advanced scenarios or custom implementations, refer to the individual class documentation in the `/Classes` directory.

### Key Takeaways

1. **Backward Compatible**: Old code continues to work unchanged
2. **Flexible**: Multiple ways to use the architecture based on needs
3. **Resilient**: Built-in retry, circuit breaker, and error handling
4. **Observable**: Comprehensive logging, metrics, and tracing
5. **Scalable**: Support for batch processing, multi-tenancy, and distributed operations
6. **Maintainable**: Clear separation of concerns and well-documented patterns

### Getting Help

- Check README.md for architecture overview
- Review individual class files for detailed API documentation
- Run test files in `/Tests` directory for working examples
- Enable debug logging with `LoggerService.SetLevel("DEBUG")`

### Best Practices

1. Always use try-catch blocks for error handling
2. Log important operations for audit trail
3. Monitor system health with HealthChecker
4. Use distributed tracing for debugging complex workflows
5. Enable metrics collection for performance monitoring
6. Test resilience with chaos engineering before production
7. Implement proper compensation logic for saga patterns
8. Use read replicas for heavy reporting queries
9. Enable circuit breakers for external service calls
10. Maintain backward compatibility when extending the architecture
