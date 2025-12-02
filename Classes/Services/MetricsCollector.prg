*====================================================================
* MetricsCollector - Prometheus-style Metrics Collection
* 
* Features:
* - Counter, Gauge, Histogram metrics
* - Labels support
* - Export to Prometheus format
* - Dashboard data provider
*
* Visual FoxPro 9 SP2 Compatible
*====================================================================

Define Class MetricsCollector As Custom
    
    * Metrics storage
    Dimension aCounters[1, 4]      && Name, Labels, Value, Help
    nCounterCount = 0
    
    Dimension aGauges[1, 4]        && Name, Labels, Value, Help
    nGaugeCount = 0
    
    Dimension aHistograms[1, 6]    && Name, Labels, Sum, Count, Buckets, Help
    nHistogramCount = 0
    
    * Default histogram buckets
    Dimension aDefaultBuckets[10]
    
    * Configuration
    cPrefix = "efactura_"
    lEnabled = .T.
    
    * Logger
    oLogger = .Null.
    
    *----------------------------------------------------------------
    * Init
    *----------------------------------------------------------------
    Procedure Init
        This.oLogger = CreateObject("LoggerService")
        
        * Default histogram buckets for duration metrics (in seconds)
        This.aDefaultBuckets[1] = 0.1
        This.aDefaultBuckets[2] = 0.25
        This.aDefaultBuckets[3] = 0.5
        This.aDefaultBuckets[4] = 1.0
        This.aDefaultBuckets[5] = 2.5
        This.aDefaultBuckets[6] = 5.0
        This.aDefaultBuckets[7] = 10.0
        This.aDefaultBuckets[8] = 30.0
        This.aDefaultBuckets[9] = 60.0
        This.aDefaultBuckets[10] = 300.0
        
        * Initialize default metrics
        This.InitializeDefaultMetrics()
    EndProc
    
    *----------------------------------------------------------------
    * InitializeDefaultMetrics - Create standard metrics
    *----------------------------------------------------------------
    Protected Procedure InitializeDefaultMetrics
        * Counters
        This.CreateCounter("invoices_processed_total", "Total number of invoices processed")
        This.CreateCounter("invoices_uploaded_total", "Total number of invoices uploaded to ANAF")
        This.CreateCounter("invoices_failed_total", "Total number of failed invoice uploads")
        This.CreateCounter("api_requests_total", "Total API requests to ANAF")
        This.CreateCounter("validation_errors_total", "Total validation errors")
        
        * Gauges
        This.CreateGauge("invoices_pending", "Number of invoices pending upload")
        This.CreateGauge("api_rate_limit_remaining", "Remaining API rate limit")
        This.CreateGauge("cache_size", "Current cache size")
        This.CreateGauge("queue_depth", "Current message queue depth")
        
        * Histograms
        This.CreateHistogram("invoice_processing_duration_seconds", "Invoice processing duration")
        This.CreateHistogram("api_request_duration_seconds", "API request duration")
        This.CreateHistogram("xml_generation_duration_seconds", "XML generation duration")
    EndProc
    
    *----------------------------------------------------------------
    * CreateCounter - Create a counter metric
    *----------------------------------------------------------------
    Procedure CreateCounter(tcName, tcHelp, tcLabels)
        Local lnIndex
        
        lnIndex = This.FindCounter(tcName, tcLabels)
        
        If lnIndex = 0
            This.nCounterCount = This.nCounterCount + 1
            lnIndex = This.nCounterCount
            Dimension This.aCounters[This.nCounterCount, 4]
            
            This.aCounters[lnIndex, 1] = tcName
            This.aCounters[lnIndex, 2] = Evl(tcLabels, "")
            This.aCounters[lnIndex, 3] = 0
            This.aCounters[lnIndex, 4] = Evl(tcHelp, "")
        EndIf
        
        Return lnIndex
    EndProc
    
    *----------------------------------------------------------------
    * CreateGauge - Create a gauge metric
    *----------------------------------------------------------------
    Procedure CreateGauge(tcName, tcHelp, tcLabels)
        Local lnIndex
        
        lnIndex = This.FindGauge(tcName, tcLabels)
        
        If lnIndex = 0
            This.nGaugeCount = This.nGaugeCount + 1
            lnIndex = This.nGaugeCount
            Dimension This.aGauges[This.nGaugeCount, 4]
            
            This.aGauges[lnIndex, 1] = tcName
            This.aGauges[lnIndex, 2] = Evl(tcLabels, "")
            This.aGauges[lnIndex, 3] = 0
            This.aGauges[lnIndex, 4] = Evl(tcHelp, "")
        EndIf
        
        Return lnIndex
    EndProc
    
    *----------------------------------------------------------------
    * CreateHistogram - Create a histogram metric
    *----------------------------------------------------------------
    Procedure CreateHistogram(tcName, tcHelp, tcLabels)
        Local lnIndex
        
        lnIndex = This.FindHistogram(tcName, tcLabels)
        
        If lnIndex = 0
            This.nHistogramCount = This.nHistogramCount + 1
            lnIndex = This.nHistogramCount
            Dimension This.aHistograms[This.nHistogramCount, 6]
            
            This.aHistograms[lnIndex, 1] = tcName
            This.aHistograms[lnIndex, 2] = Evl(tcLabels, "")
            This.aHistograms[lnIndex, 3] = 0  && Sum
            This.aHistograms[lnIndex, 4] = 0  && Count
            This.aHistograms[lnIndex, 5] = ""  && Bucket counts (comma-separated)
            This.aHistograms[lnIndex, 6] = Evl(tcHelp, "")
            
            * Initialize bucket counts
            Local lcBuckets, i
            lcBuckets = ""
            For i = 1 To 10
                lcBuckets = lcBuckets + Iif(Empty(lcBuckets), "", ",") + "0"
            Next
            This.aHistograms[lnIndex, 5] = lcBuckets
        EndIf
        
        Return lnIndex
    EndProc
    
    *----------------------------------------------------------------
    * FindCounter - Find counter by name and labels
    *----------------------------------------------------------------
    Protected Procedure FindCounter(tcName, tcLabels)
        Local i
        
        For i = 1 To This.nCounterCount
            If This.aCounters[i, 1] = tcName And This.aCounters[i, 2] = Evl(tcLabels, "")
                Return i
            EndIf
        Next
        
        Return 0
    EndProc
    
    *----------------------------------------------------------------
    * FindGauge - Find gauge by name and labels
    *----------------------------------------------------------------
    Protected Procedure FindGauge(tcName, tcLabels)
        Local i
        
        For i = 1 To This.nGaugeCount
            If This.aGauges[i, 1] = tcName And This.aGauges[i, 2] = Evl(tcLabels, "")
                Return i
            EndIf
        Next
        
        Return 0
    EndProc
    
    *----------------------------------------------------------------
    * FindHistogram - Find histogram by name and labels
    *----------------------------------------------------------------
    Protected Procedure FindHistogram(tcName, tcLabels)
        Local i
        
        For i = 1 To This.nHistogramCount
            If This.aHistograms[i, 1] = tcName And This.aHistograms[i, 2] = Evl(tcLabels, "")
                Return i
            EndIf
        Next
        
        Return 0
    EndProc
    
    *----------------------------------------------------------------
    * CounterInc - Increment counter
    *----------------------------------------------------------------
    Procedure CounterInc(tcName, tnValue, tcLabels)
        Local lnIndex
        
        If Not This.lEnabled
            Return
        EndIf
        
        lnIndex = This.FindCounter(tcName, tcLabels)
        
        If lnIndex = 0
            lnIndex = This.CreateCounter(tcName, "", tcLabels)
        EndIf
        
        This.aCounters[lnIndex, 3] = This.aCounters[lnIndex, 3] + Evl(tnValue, 1)
    EndProc
    
    *----------------------------------------------------------------
    * GaugeSet - Set gauge value
    *----------------------------------------------------------------
    Procedure GaugeSet(tcName, tnValue, tcLabels)
        Local lnIndex
        
        If Not This.lEnabled
            Return
        EndIf
        
        lnIndex = This.FindGauge(tcName, tcLabels)
        
        If lnIndex = 0
            lnIndex = This.CreateGauge(tcName, "", tcLabels)
        EndIf
        
        This.aGauges[lnIndex, 3] = tnValue
    EndProc
    
    *----------------------------------------------------------------
    * GaugeInc - Increment gauge
    *----------------------------------------------------------------
    Procedure GaugeInc(tcName, tnValue, tcLabels)
        Local lnIndex
        
        If Not This.lEnabled
            Return
        EndIf
        
        lnIndex = This.FindGauge(tcName, tcLabels)
        
        If lnIndex = 0
            lnIndex = This.CreateGauge(tcName, "", tcLabels)
        EndIf
        
        This.aGauges[lnIndex, 3] = This.aGauges[lnIndex, 3] + Evl(tnValue, 1)
    EndProc
    
    *----------------------------------------------------------------
    * GaugeDec - Decrement gauge
    *----------------------------------------------------------------
    Procedure GaugeDec(tcName, tnValue, tcLabels)
        Local lnIndex
        
        If Not This.lEnabled
            Return
        EndIf
        
        lnIndex = This.FindGauge(tcName, tcLabels)
        
        If lnIndex > 0
            This.aGauges[lnIndex, 3] = This.aGauges[lnIndex, 3] - Evl(tnValue, 1)
        EndIf
    EndProc
    
    *----------------------------------------------------------------
    * HistogramObserve - Observe value for histogram
    *----------------------------------------------------------------
    Procedure HistogramObserve(tcName, tnValue, tcLabels)
        Local lnIndex, i
        Dimension laBuckets[10]
        
        If Not This.lEnabled
            Return
        EndIf
        
        lnIndex = This.FindHistogram(tcName, tcLabels)
        
        If lnIndex = 0
            lnIndex = This.CreateHistogram(tcName, "", tcLabels)
        EndIf
        
        * Update sum and count
        This.aHistograms[lnIndex, 3] = This.aHistograms[lnIndex, 3] + tnValue
        This.aHistograms[lnIndex, 4] = This.aHistograms[lnIndex, 4] + 1
        
        * Update bucket counts
        ALines(laBuckets, This.aHistograms[lnIndex, 5], .T., ",")
        
        For i = 1 To 10
            If tnValue <= This.aDefaultBuckets[i]
                laBuckets[i] = Transform(Val(laBuckets[i]) + 1)
            EndIf
        Next
        
        * Rebuild bucket string
        Local lcBuckets
        lcBuckets = ""
        For i = 1 To 10
            lcBuckets = lcBuckets + Iif(Empty(lcBuckets), "", ",") + laBuckets[i]
        Next
        This.aHistograms[lnIndex, 5] = lcBuckets
    EndProc
    
    *----------------------------------------------------------------
    * Timer - Create timer for measuring duration
    *----------------------------------------------------------------
    Procedure Timer
        Local loTimer
        
        loTimer = CreateObject("MetricTimer")
        loTimer.nStartTime = Seconds()
        loTimer.oCollector = This
        
        Return loTimer
    EndProc
    
    *----------------------------------------------------------------
    * ExportPrometheus - Export metrics in Prometheus format
    *----------------------------------------------------------------
    Procedure ExportPrometheus
        Local lcOutput, i
        
        lcOutput = ""
        
        * Export counters
        For i = 1 To This.nCounterCount
            If Not Empty(This.aCounters[i, 4])
                lcOutput = lcOutput + "# HELP " + This.cPrefix + This.aCounters[i, 1] + " " + This.aCounters[i, 4] + Chr(10)
            EndIf
            lcOutput = lcOutput + "# TYPE " + This.cPrefix + This.aCounters[i, 1] + " counter" + Chr(10)
            lcOutput = lcOutput + This.cPrefix + This.aCounters[i, 1]
            If Not Empty(This.aCounters[i, 2])
                lcOutput = lcOutput + "{" + This.aCounters[i, 2] + "}"
            EndIf
            lcOutput = lcOutput + " " + Transform(This.aCounters[i, 3]) + Chr(10)
        Next
        
        * Export gauges
        For i = 1 To This.nGaugeCount
            If Not Empty(This.aGauges[i, 4])
                lcOutput = lcOutput + "# HELP " + This.cPrefix + This.aGauges[i, 1] + " " + This.aGauges[i, 4] + Chr(10)
            EndIf
            lcOutput = lcOutput + "# TYPE " + This.cPrefix + This.aGauges[i, 1] + " gauge" + Chr(10)
            lcOutput = lcOutput + This.cPrefix + This.aGauges[i, 1]
            If Not Empty(This.aGauges[i, 2])
                lcOutput = lcOutput + "{" + This.aGauges[i, 2] + "}"
            EndIf
            lcOutput = lcOutput + " " + Transform(This.aGauges[i, 3]) + Chr(10)
        Next
        
        * Export histograms
        For i = 1 To This.nHistogramCount
            lcOutput = lcOutput + This.ExportHistogram(i)
        Next
        
        Return lcOutput
    EndProc
    
    *----------------------------------------------------------------
    * ExportHistogram - Export single histogram in Prometheus format
    *----------------------------------------------------------------
    Protected Procedure ExportHistogram(tnIndex)
        Local lcOutput, lcName, lcLabels, j
        Dimension laBuckets[10]
        
        lcName = This.cPrefix + This.aHistograms[tnIndex, 1]
        lcLabels = This.aHistograms[tnIndex, 2]
        
        ALines(laBuckets, This.aHistograms[tnIndex, 5], .T., ",")
        
        If Not Empty(This.aHistograms[tnIndex, 6])
            lcOutput = "# HELP " + lcName + " " + This.aHistograms[tnIndex, 6] + Chr(10)
        Else
            lcOutput = ""
        EndIf
        
        lcOutput = lcOutput + "# TYPE " + lcName + " histogram" + Chr(10)
        
        * Bucket values
        For j = 1 To 10
            lcOutput = lcOutput + lcName + "_bucket{"
            If Not Empty(lcLabels)
                lcOutput = lcOutput + lcLabels + ","
            EndIf
            lcOutput = lcOutput + 'le="' + Transform(This.aDefaultBuckets[j]) + '"} ' + laBuckets[j] + Chr(10)
        Next
        
        * +Inf bucket
        lcOutput = lcOutput + lcName + '_bucket{le="+Inf"} ' + Transform(This.aHistograms[tnIndex, 4]) + Chr(10)
        
        * Sum and count
        lcOutput = lcOutput + lcName + "_sum " + Transform(This.aHistograms[tnIndex, 3]) + Chr(10)
        lcOutput = lcOutput + lcName + "_count " + Transform(This.aHistograms[tnIndex, 4]) + Chr(10)
        
        Return lcOutput
    EndProc
    
    *----------------------------------------------------------------
    * GetDashboardData - Get metrics for dashboard display
    *----------------------------------------------------------------
    Procedure GetDashboardData
        Local loData, i
        
        loData = CreateObject("Empty")
        
        * Summary
        AddProperty(loData, "InvoicesProcessed", This.GetCounterValue("invoices_processed_total"))
        AddProperty(loData, "InvoicesUploaded", This.GetCounterValue("invoices_uploaded_total"))
        AddProperty(loData, "InvoicesFailed", This.GetCounterValue("invoices_failed_total"))
        AddProperty(loData, "InvoicesPending", This.GetGaugeValue("invoices_pending"))
        AddProperty(loData, "ApiRequests", This.GetCounterValue("api_requests_total"))
        AddProperty(loData, "ValidationErrors", This.GetCounterValue("validation_errors_total"))
        
        * Averages
        Local lnProcessingSum, lnProcessingCount
        lnProcessingSum = This.GetHistogramSum("invoice_processing_duration_seconds")
        lnProcessingCount = This.GetHistogramCount("invoice_processing_duration_seconds")
        
        AddProperty(loData, "AvgProcessingTime", Iif(lnProcessingCount > 0, lnProcessingSum / lnProcessingCount, 0))
        
        * Success rate
        Local lnTotal
        lnTotal = loData.InvoicesUploaded + loData.InvoicesFailed
        AddProperty(loData, "SuccessRate", Iif(lnTotal > 0, (loData.InvoicesUploaded / lnTotal) * 100, 100))
        
        Return loData
    EndProc
    
    *----------------------------------------------------------------
    * GetCounterValue - Get counter value by name
    *----------------------------------------------------------------
    Procedure GetCounterValue(tcName, tcLabels)
        Local lnIndex
        
        lnIndex = This.FindCounter(tcName, tcLabels)
        
        If lnIndex > 0
            Return This.aCounters[lnIndex, 3]
        EndIf
        
        Return 0
    EndProc
    
    *----------------------------------------------------------------
    * GetGaugeValue - Get gauge value by name
    *----------------------------------------------------------------
    Procedure GetGaugeValue(tcName, tcLabels)
        Local lnIndex
        
        lnIndex = This.FindGauge(tcName, tcLabels)
        
        If lnIndex > 0
            Return This.aGauges[lnIndex, 3]
        EndIf
        
        Return 0
    EndProc
    
    *----------------------------------------------------------------
    * GetHistogramSum - Get histogram sum
    *----------------------------------------------------------------
    Procedure GetHistogramSum(tcName, tcLabels)
        Local lnIndex
        
        lnIndex = This.FindHistogram(tcName, tcLabels)
        
        If lnIndex > 0
            Return This.aHistograms[lnIndex, 3]
        EndIf
        
        Return 0
    EndProc
    
    *----------------------------------------------------------------
    * GetHistogramCount - Get histogram count
    *----------------------------------------------------------------
    Procedure GetHistogramCount(tcName, tcLabels)
        Local lnIndex
        
        lnIndex = This.FindHistogram(tcName, tcLabels)
        
        If lnIndex > 0
            Return This.aHistograms[lnIndex, 4]
        EndIf
        
        Return 0
    EndProc
    
    *----------------------------------------------------------------
    * Reset - Reset all metrics
    *----------------------------------------------------------------
    Procedure Reset
        Local i
        
        For i = 1 To This.nCounterCount
            This.aCounters[i, 3] = 0
        Next
        
        For i = 1 To This.nGaugeCount
            This.aGauges[i, 3] = 0
        Next
        
        For i = 1 To This.nHistogramCount
            This.aHistograms[i, 3] = 0
            This.aHistograms[i, 4] = 0
            This.aHistograms[i, 5] = "0,0,0,0,0,0,0,0,0,0"
        Next
    EndProc

EndDefine


*====================================================================
* MetricTimer - Helper class for timing operations
*====================================================================

Define Class MetricTimer As Custom
    
    nStartTime = 0
    oCollector = .Null.
    
    Procedure ObserveDuration(tcMetricName, tcLabels)
        Local lnDuration
        
        lnDuration = Seconds() - This.nStartTime
        
        If Not IsNull(This.oCollector)
            This.oCollector.HistogramObserve(tcMetricName, lnDuration, tcLabels)
        EndIf
        
        Return lnDuration
    EndProc

EndDefine
