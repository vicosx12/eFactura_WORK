*====================================================================
* BatchProcessor - Enhanced Batch Processing with CSV Import/Export
* 
* Features:
* - CSV import for bulk invoice processing
* - Export processing results to CSV
* - Summary reports
* - Progress tracking
*
* Visual FoxPro 9 SP2 Compatible
*====================================================================

Define Class BatchProcessor As Custom
    
    * Configuration
    cImportPath = ""
    cExportPath = ""
    cDelimiter = ","
    lHasHeaders = .T.
    
    * Processing state
    nTotalRecords = 0
    nProcessedRecords = 0
    nSuccessCount = 0
    nFailedCount = 0
    nSkippedCount = 0
    nStartTime = 0
    
    * Results collection
    Dimension aResults[1, 5]  && Id, Number, Status, Message, Duration
    nResultCount = 0
    
    * Dependencies
    oFacade = .Null.
    oLogger = .Null.
    oProgressSubject = .Null.
    oNotificationService = .Null.
    oStatsCollector = .Null.
    
    *----------------------------------------------------------------
    * Init
    *----------------------------------------------------------------
    Procedure Init
        This.oLogger = CreateObject("LoggerService")
        This.oStatsCollector = CreateObject("StatsCollector")
        This.cImportPath = AddBs(JustPath(Sys(16))) + "Import\"
        This.cExportPath = AddBs(JustPath(Sys(16))) + "Export\"
        
        * Create directories if needed
        If Not Directory(This.cImportPath)
            Mkdir (This.cImportPath)
        EndIf
        
        If Not Directory(This.cExportPath)
            Mkdir (This.cExportPath)
        EndIf
    EndProc
    
    *----------------------------------------------------------------
    * SetFacade - Set eFactura facade for processing
    *----------------------------------------------------------------
    Procedure SetFacade(toFacade)
        This.oFacade = toFacade
    EndProc
    
    *----------------------------------------------------------------
    * SetProgressSubject - Set progress observer subject
    *----------------------------------------------------------------
    Procedure SetProgressSubject(toSubject)
        This.oProgressSubject = toSubject
    EndProc
    
    *----------------------------------------------------------------
    * ImportFromCsv - Import invoices from CSV file
    *----------------------------------------------------------------
    Procedure ImportFromCsv(tcFileName)
        Local lcFilePath, lcContent, lnLines
        Dimension laLines[1]
        
        lcFilePath = AddBs(This.cImportPath) + tcFileName
        
        If Not File(lcFilePath)
            This.oLogger.LogError("Fișier CSV negăsit: " + lcFilePath)
            Return .F.
        EndIf
        
        lcContent = FileToStr(lcFilePath)
        lnLines = ALines(laLines, lcContent, .T.)
        
        If lnLines = 0
            This.oLogger.LogError("Fișier CSV gol")
            Return .F.
        EndIf
        
        * Parse headers if present
        Local lnStartLine
        lnStartLine = Iif(This.lHasHeaders, 2, 1)
        
        * Create cursor for import data
        Create Cursor ImportData ;
            (IdUnic I, NumarFactura C(50), DataFactura D, CUI C(20), ;
             Alias C(50), IsRectificativa L, Status C(20))
        
        * Parse each line
        Local i, lcLine
        Dimension laFields[1]
        
        For i = lnStartLine To lnLines
            lcLine = Alltrim(laLines[i])
            
            If Empty(lcLine)
                Loop
            EndIf
            
            lnFields = ALines(laFields, lcLine, .T., This.cDelimiter)
            
            If lnFields >= 3
                Insert Into ImportData ;
                    (IdUnic, NumarFactura, DataFactura, CUI, Alias, IsRectificativa, Status) ;
                Values ;
                    (Val(laFields[1]), ;
                     Alltrim(laFields[2]), ;
                     Iif(lnFields >= 3, Ctod(laFields[3]), Date()), ;
                     Iif(lnFields >= 4, Alltrim(laFields[4]), ""), ;
                     Iif(lnFields >= 5, Alltrim(laFields[5]), "Iesiri"), ;
                     Iif(lnFields >= 6, laFields[6] = "1" Or Upper(laFields[6]) = "TRUE", .F.), ;
                     "PENDING")
            EndIf
        Next
        
        This.oLogger.LogInfo("Importate " + Transform(Reccount("ImportData")) + " înregistrări din CSV")
        
        Return Reccount("ImportData") > 0
    EndProc
    
    *----------------------------------------------------------------
    * ProcessBatch - Process all imported invoices
    *----------------------------------------------------------------
    Procedure ProcessBatch
        Local lnTotal, lnCurrent, lnPercent
        
        If Not Used("ImportData")
            This.oLogger.LogError("Nu există date de import")
            Return .F.
        EndIf
        
        This.ResetCounters()
        This.oStatsCollector.Start("BatchProcess")
        
        lnTotal = Reccount("ImportData")
        This.nTotalRecords = lnTotal
        lnCurrent = 0
        
        Select ImportData
        
        Scan
            lnCurrent = lnCurrent + 1
            lnPercent = Int((lnCurrent / lnTotal) * 100)
            
            * Update progress
            This.NotifyProgress(lnPercent, "Procesare " + Transform(lnCurrent) + "/" + Transform(lnTotal))
            
            * Process invoice
            This.ProcessSingleInvoice(IdUnic, Alias, IsRectificativa)
            
            This.nProcessedRecords = lnCurrent
        EndScan
        
        This.oStatsCollector.Stop()
        
        * Send notification
        If Not IsNull(This.oNotificationService)
            This.oNotificationService.NotifyBatchResult(;
                This.nTotalRecords, ;
                This.nSuccessCount, ;
                This.nFailedCount, ;
                This.oStatsCollector.GetDuration())
        EndIf
        
        This.oLogger.LogInfo("Batch processing complete: " + Transform(This.nSuccessCount) + " success, " + ;
            Transform(This.nFailedCount) + " failed")
        
        Return This.nFailedCount = 0
    EndProc
    
    *----------------------------------------------------------------
    * ProcessSingleInvoice - Process one invoice
    *----------------------------------------------------------------
    Protected Procedure ProcessSingleInvoice(tnIdUnic, tcAlias, tlRectificativa)
        Local lcResult, lnStart, lnDuration, lcStatus, lcMessage
        
        lnStart = Seconds()
        
        Try
            If IsNull(This.oFacade)
                This.oFacade = CreateObject("EFacturaFacade")
            EndIf
            
            lcResult = This.oFacade.Process(tnIdUnic, tcAlias, tlRectificativa, "", .F., .F.)
            
            If "OK" $ Upper(lcResult) Or "succes" $ Lower(lcResult)
                lcStatus = "SUCCESS"
                lcMessage = lcResult
                This.nSuccessCount = This.nSuccessCount + 1
            Else
                lcStatus = "FAILED"
                lcMessage = lcResult
                This.nFailedCount = This.nFailedCount + 1
            EndIf
        Catch
            lcStatus = "ERROR"
            lcMessage = Message()
            This.nFailedCount = This.nFailedCount + 1
        EndTry
        
        lnDuration = Seconds() - lnStart
        
        * Record result
        This.AddResult(tnIdUnic, "", lcStatus, lcMessage, lnDuration)
        
        * Update import data status
        Update ImportData Set Status = lcStatus Where IdUnic = tnIdUnic
    EndProc
    
    *----------------------------------------------------------------
    * ProcessByIds - Process specific invoice IDs
    *----------------------------------------------------------------
    Procedure ProcessByIds(tcIdList, tcAlias)
        Local lnCount, i
        Dimension laIds[1]
        
        lnCount = ALines(laIds, tcIdList, .T., ",")
        
        If lnCount = 0
            Return .F.
        EndIf
        
        This.ResetCounters()
        This.nTotalRecords = lnCount
        This.oStatsCollector.Start("BatchByIds")
        
        For i = 1 To lnCount
            This.NotifyProgress(Int((i / lnCount) * 100), "Procesare " + Transform(i) + "/" + Transform(lnCount))
            
            This.ProcessSingleInvoice(Val(laIds[i]), tcAlias, .F.)
            
            This.nProcessedRecords = i
        Next
        
        This.oStatsCollector.Stop()
        
        Return This.nFailedCount = 0
    EndProc
    
    *----------------------------------------------------------------
    * ProcessByDateRange - Process invoices in date range
    *----------------------------------------------------------------
    Procedure ProcessByDateRange(tdFrom, tdTo, tcAlias)
        Local lcSql, lnCount
        
        tcAlias = Evl(tcAlias, "Iesiri")
        
        * Build query based on alias
        lcSql = "Select Id_Unic From " + tcAlias + ;
                " Where Data >= ?tdFrom And Data <= ?tdTo" + ;
                " And (Empty(Id_SPV) Or IsNull(Id_SPV))" + ;
                " Into Cursor BatchInvoices"
        
        Try
            &lcSql
        Catch
            This.oLogger.LogError("Eroare interogare: " + Message())
            Return .F.
        EndTry
        
        lnCount = Reccount()
        
        If lnCount = 0
            This.oLogger.LogInfo("Nu s-au găsit facturi în intervalul specificat")
            Return .T.
        EndIf
        
        This.ResetCounters()
        This.nTotalRecords = lnCount
        This.oStatsCollector.Start("BatchByDateRange")
        
        Local lnCurrent
        lnCurrent = 0
        
        Select BatchInvoices
        Scan
            lnCurrent = lnCurrent + 1
            This.NotifyProgress(Int((lnCurrent / lnCount) * 100), "Procesare " + Transform(lnCurrent) + "/" + Transform(lnCount))
            
            This.ProcessSingleInvoice(Id_Unic, tcAlias, .F.)
            
            This.nProcessedRecords = lnCurrent
        EndScan
        
        Use In BatchInvoices
        
        This.oStatsCollector.Stop()
        
        Return This.nFailedCount = 0
    EndProc
    
    *----------------------------------------------------------------
    * ExportResultsToCsv - Export processing results to CSV
    *----------------------------------------------------------------
    Procedure ExportResultsToCsv(tcFileName)
        Local lcFilePath, lcContent, i
        
        If Empty(tcFileName)
            tcFileName = "batch_results_" + Dtos(Date()) + "_" + StrTran(Time(), ":", "") + ".csv"
        EndIf
        
        lcFilePath = AddBs(This.cExportPath) + tcFileName
        
        * Create header
        lcContent = "Id,NumarFactura,Status,Mesaj,Durata" + Chr(13) + Chr(10)
        
        * Add results
        For i = 1 To This.nResultCount
            lcContent = lcContent + ;
                Transform(This.aResults[i, 1]) + This.cDelimiter + ;
                This.aResults[i, 2] + This.cDelimiter + ;
                This.aResults[i, 3] + This.cDelimiter + ;
                '"' + StrTran(This.aResults[i, 4], '"', '""') + '"' + This.cDelimiter + ;
                Transform(This.aResults[i, 5], "999.999") + Chr(13) + Chr(10)
        Next
        
        StrToFile(lcContent, lcFilePath)
        
        This.oLogger.LogInfo("Rezultate exportate: " + lcFilePath)
        
        Return lcFilePath
    EndProc
    
    *----------------------------------------------------------------
    * GetSummaryReport - Get summary report object
    *----------------------------------------------------------------
    Procedure GetSummaryReport
        Local loReport
        
        loReport = CreateObject("Empty")
        AddProperty(loReport, "TotalRecords", This.nTotalRecords)
        AddProperty(loReport, "ProcessedRecords", This.nProcessedRecords)
        AddProperty(loReport, "SuccessCount", This.nSuccessCount)
        AddProperty(loReport, "FailedCount", This.nFailedCount)
        AddProperty(loReport, "SkippedCount", This.nSkippedCount)
        AddProperty(loReport, "SuccessRate", Iif(This.nProcessedRecords > 0, ;
            (This.nSuccessCount / This.nProcessedRecords) * 100, 0))
        AddProperty(loReport, "Duration", This.oStatsCollector.GetDuration())
        AddProperty(loReport, "AveragePerRecord", Iif(This.nProcessedRecords > 0, ;
            This.oStatsCollector.GetDuration() / This.nProcessedRecords, 0))
        
        Return loReport
    EndProc
    
    *----------------------------------------------------------------
    * GetSummaryReportAsText - Get text summary report
    *----------------------------------------------------------------
    Procedure GetSummaryReportAsText
        Local loReport, lcText
        
        loReport = This.GetSummaryReport()
        
        lcText = "========================================" + Chr(13) + Chr(10)
        lcText = lcText + "      RAPORT PROCESARE BATCH          " + Chr(13) + Chr(10)
        lcText = lcText + "========================================" + Chr(13) + Chr(10)
        lcText = lcText + Chr(13) + Chr(10)
        lcText = lcText + "Total înregistrări:     " + Transform(loReport.TotalRecords) + Chr(13) + Chr(10)
        lcText = lcText + "Procesate:              " + Transform(loReport.ProcessedRecords) + Chr(13) + Chr(10)
        lcText = lcText + "Cu succes:              " + Transform(loReport.SuccessCount) + Chr(13) + Chr(10)
        lcText = lcText + "Eșuate:                 " + Transform(loReport.FailedCount) + Chr(13) + Chr(10)
        lcText = lcText + "Omise:                  " + Transform(loReport.SkippedCount) + Chr(13) + Chr(10)
        lcText = lcText + Chr(13) + Chr(10)
        lcText = lcText + "Rată succes:            " + Transform(loReport.SuccessRate, "999.99") + "%" + Chr(13) + Chr(10)
        lcText = lcText + "Durată totală:          " + Transform(loReport.Duration, "9999.99") + " sec" + Chr(13) + Chr(10)
        lcText = lcText + "Medie per înregistrare: " + Transform(loReport.AveragePerRecord, "999.999") + " sec" + Chr(13) + Chr(10)
        lcText = lcText + "========================================" + Chr(13) + Chr(10)
        
        Return lcText
    EndProc
    
    *----------------------------------------------------------------
    * ResetCounters - Reset processing counters
    *----------------------------------------------------------------
    Protected Procedure ResetCounters
        This.nTotalRecords = 0
        This.nProcessedRecords = 0
        This.nSuccessCount = 0
        This.nFailedCount = 0
        This.nSkippedCount = 0
        This.nResultCount = 0
        Dimension This.aResults[1, 5]
    EndProc
    
    *----------------------------------------------------------------
    * AddResult - Add processing result
    *----------------------------------------------------------------
    Protected Procedure AddResult(tnId, tcNumber, tcStatus, tcMessage, tnDuration)
        This.nResultCount = This.nResultCount + 1
        Dimension This.aResults[This.nResultCount, 5]
        
        This.aResults[This.nResultCount, 1] = tnId
        This.aResults[This.nResultCount, 2] = tcNumber
        This.aResults[This.nResultCount, 3] = tcStatus
        This.aResults[This.nResultCount, 4] = tcMessage
        This.aResults[This.nResultCount, 5] = tnDuration
    EndProc
    
    *----------------------------------------------------------------
    * NotifyProgress - Notify progress observers
    *----------------------------------------------------------------
    Protected Procedure NotifyProgress(tnPercent, tcMessage)
        If Not IsNull(This.oProgressSubject)
            This.oProgressSubject.Notify(tnPercent, tcMessage)
        EndIf
    EndProc
    
    *----------------------------------------------------------------
    * GetFailedRecords - Get list of failed records
    *----------------------------------------------------------------
    Procedure GetFailedRecords
        Local i
        
        Create Cursor FailedRecords (Id I, Number C(50), Message M)
        
        For i = 1 To This.nResultCount
            If This.aResults[i, 3] = "FAILED" Or This.aResults[i, 3] = "ERROR"
                Insert Into FailedRecords Values ;
                    (This.aResults[i, 1], This.aResults[i, 2], This.aResults[i, 4])
            EndIf
        Next
        
        Return Reccount("FailedRecords") > 0
    EndProc
    
    *----------------------------------------------------------------
    * RetryFailed - Retry processing failed records
    *----------------------------------------------------------------
    Procedure RetryFailed(tcAlias)
        Local lnOriginalSuccess
        
        If Not This.GetFailedRecords()
            Return .T.
        EndIf
        
        lnOriginalSuccess = This.nSuccessCount
        
        Select FailedRecords
        Scan
            This.ProcessSingleInvoice(Id, tcAlias, .F.)
        EndScan
        
        Use In FailedRecords
        
        Return This.nSuccessCount > lnOriginalSuccess
    EndProc

EndDefine
