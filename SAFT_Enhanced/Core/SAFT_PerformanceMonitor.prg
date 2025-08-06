*!* ============================================================================
*!* FISIER: SAFT_PerformanceMonitor.prg
*!* ============================================================================
*!* AUTOR: Alex (Engineer) - MGX Team
*!* DATA:  28.07.2025
*!* SCOP:  Monitorizarea performantei si colectarea de metrici
*!* pentru procesul de generare SAF-T
*!* ============================================================================

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_PerformanceMonitor
*!* SCOP:  Monitor principal pentru performanta sistemului
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_PerformanceMonitor AS Custom
    Metrics = .NULL.
    Timers = .NULL.
    MemorySnapshots = .NULL.
    IsEnabled = .T.
    StartTime = {}
    
    FUNCTION Init()
        THIS.Metrics = CREATEOBJECT("Collection")
        THIS.Timers = CREATEOBJECT("Collection")
        THIS.MemorySnapshots = CREATEOBJECT("Collection")
        THIS.StartTime = DATETIME()
    ENDFUNC
    
    *-- Porneste un timer pentru o operatiune
    FUNCTION StartTimer(tcOperationName AS String) AS String
        LOCAL lcTimerId AS String, loTimer AS Object
        
        IF !THIS.IsEnabled
            RETURN ""
        ENDIF
        
        lcTimerId = tcOperationName + "_" + TRANSFORM(DATETIME(), "@Y")
        
        loTimer = CREATEOBJECT("SAFT_PerformanceTimer")
        loTimer.OperationName = tcOperationName
        loTimer.StartTime = SECONDS()
        loTimer.TimerId = lcTimerId
        
        IF THIS.Timers.GetKey(lcTimerId) > 0
            THIS.Timers.Remove(lcTimerId)
        ENDIF
        
        THIS.Timers.Add(loTimer, lcTimerId)
        
        RETURN lcTimerId
    ENDFUNC
    
    *-- Opreste un timer si inregistreaza metrica
    FUNCTION StopTimer(tcTimerId AS String) AS Object
        LOCAL loTimer AS Object, loMetric AS Object, lnDuration AS Number
        
        IF !THIS.IsEnabled OR EMPTY(tcTimerId)
            RETURN .NULL.
        ENDIF
        
        IF THIS.Timers.GetKey(tcTimerId) = 0
            RETURN .NULL.
        ENDIF
        
        loTimer = THIS.Timers.Item(tcTimerId)
        lnDuration = SECONDS() - loTimer.StartTime
        
        loTimer.EndTime = SECONDS()
        loTimer.Duration = lnDuration
        
        *-- Creaza metrica
        loMetric = CREATEOBJECT("SAFT_PerformanceMetric")
        loMetric.OperationName = loTimer.OperationName
        loMetric.MetricType = "DURATION"
        loMetric.Value = lnDuration
        loMetric.Timestamp = DATETIME()
        loMetric.Unit = "seconds"
        
        THIS.RecordMetric(loMetric)
        
        *-- Remove timer
        THIS.Timers.Remove(tcTimerId)
        
        RETURN loMetric
    ENDFUNC
    
    *-- Inregistreaza o metrica custom
    FUNCTION RecordMetric(toMetric AS Object)
        LOCAL lcKey AS String
        
        IF !THIS.IsEnabled OR VARTYPE(toMetric) != "O"
            RETURN
        ENDIF
        
        lcKey = toMetric.OperationName + "_" + toMetric.MetricType + "_" + TRANSFORM(DATETIME(), "@Y")
        
        IF THIS.Metrics.GetKey(lcKey) = 0
            THIS.Metrics.Add(toMetric, lcKey)
        ENDIF
    ENDFUNC
    
    *-- Inregistreaza numarul de inregistrari procesate
    FUNCTION RecordRecordCount(tcOperationName AS String, tnCount AS Integer)
        LOCAL loMetric AS Object
        
        loMetric = CREATEOBJECT("SAFT_PerformanceMetric")
        loMetric.OperationName = tcOperationName
        loMetric.MetricType = "RECORD_COUNT"
        loMetric.Value = tnCount
        loMetric.Timestamp = DATETIME()
        loMetric.Unit = "records"
        
        THIS.RecordMetric(loMetric)
    ENDFUNC
    
    *-- Inregistreaza utilizarea memoriei
    FUNCTION RecordMemoryUsage(tcOperationName AS String)
        LOCAL loMetric AS Object, lnMemoryUsage AS Number
        
        lnMemoryUsage = THIS.GetCurrentMemoryUsage()
        
        loMetric = CREATEOBJECT("SAFT_PerformanceMetric")
        loMetric.OperationName = tcOperationName
        loMetric.MetricType = "MEMORY_USAGE"
        loMetric.Value = lnMemoryUsage
        loMetric.Timestamp = DATETIME()
        loMetric.Unit = "MB"
        
        THIS.RecordMetric(loMetric)
        
        *-- Salveaza snapshot
        THIS.MemorySnapshots.Add(loMetric, tcOperationName + "_" + TRANSFORM(DATETIME(), "@Y"))
    ENDFUNC
    
    *-- Obtine utilizarea curenta a memoriei
    PROTECTED FUNCTION GetCurrentMemoryUsage() AS Number
        *-- In VFP, folosim SYS(1016) pentru memoria utilizata
        LOCAL lcMemInfo AS String, lnMemory AS Number
        
        lcMemInfo = SYS(1016)  && User object memory
        lnMemory = VAL(lcMemInfo) / (1024 * 1024)  && Convert to MB
        
        RETURN lnMemory
    ENDFUNC
    
    *-- Calculeaza statistici pentru o operatiune
    FUNCTION GetOperationStatistics(tcOperationName AS String) AS Object
        LOCAL loStats AS Object, i AS Integer, loMetric AS Object
        LOCAL lnTotalDuration AS Number, lnCount AS Integer, lnMinDuration AS Number, lnMaxDuration AS Number
        LOCAL lnTotalRecords AS Number, lnRecordCount AS Integer
        
        loStats = CREATEOBJECT("SAFT_OperationStatistics")
        loStats.OperationName = tcOperationName
        
        lnTotalDuration = 0
        lnCount = 0
        lnMinDuration = 999999
        lnMaxDuration = 0
        lnTotalRecords = 0
        lnRecordCount = 0
        
        FOR i = 1 TO THIS.Metrics.Count
            loMetric = THIS.Metrics.Item(i)
            
            IF loMetric.OperationName = tcOperationName
                DO CASE
                    CASE loMetric.MetricType = "DURATION"
                        lnTotalDuration = lnTotalDuration + loMetric.Value
                        lnCount = lnCount + 1
                        lnMinDuration = MIN(lnMinDuration, loMetric.Value)
                        lnMaxDuration = MAX(lnMaxDuration, loMetric.Value)
                        
                    CASE loMetric.MetricType = "RECORD_COUNT"
                        lnTotalRecords = lnTotalRecords + loMetric.Value
                        lnRecordCount = lnRecordCount + 1
                ENDCASE
            ENDIF
        ENDFOR
        
        IF lnCount > 0
            loStats.AverageDuration = lnTotalDuration / lnCount
            loStats.MinDuration = lnMinDuration
            loStats.MaxDuration = lnMaxDuration
            loStats.TotalDuration = lnTotalDuration
            loStats.ExecutionCount = lnCount
        ENDIF
        
        IF lnRecordCount > 0
            loStats.TotalRecords = lnTotalRecords
            loStats.AverageRecordsPerExecution = lnTotalRecords / lnRecordCount
        ENDIF
        
        *-- Calculeaza throughput (records per second)
        IF loStats.TotalDuration > 0 AND loStats.TotalRecords > 0
            loStats.RecordsPerSecond = loStats.TotalRecords / loStats.TotalDuration
        ENDIF
        
        RETURN loStats
    ENDFUNC
    
    *-- Genereaza raport de performanta
    FUNCTION GeneratePerformanceReport() AS String
        LOCAL lcReport AS String, i AS Integer, lcOperationName AS String
        LOCAL loStats AS Object, loUniqueOperations AS Collection
        
        lcReport = "=== SAFT PERFORMANCE REPORT ===" + CHR(13) + CHR(10)
        lcReport = lcReport + "Generated: " + TRANSFORM(DATETIME()) + CHR(13) + CHR(10)
        lcReport = lcReport + "Total Execution Time: " + TRANSFORM(SECONDS() - THIS.StartTime) + " seconds" + CHR(13) + CHR(10)
        lcReport = lcReport + CHR(13) + CHR(10)
        
        *-- Obtine operatiunile unice
        loUniqueOperations = THIS.GetUniqueOperations()
        
        FOR i = 1 TO loUniqueOperations.Count
            lcOperationName = loUniqueOperations.Item(i)
            loStats = THIS.GetOperationStatistics(lcOperationName)
            
            lcReport = lcReport + "OPERATION: " + lcOperationName + CHR(13) + CHR(10)
            lcReport = lcReport + "  Executions: " + TRANSFORM(loStats.ExecutionCount) + CHR(13) + CHR(10)
            lcReport = lcReport + "  Total Duration: " + TRANSFORM(loStats.TotalDuration, "999.999") + " sec" + CHR(13) + CHR(10)
            lcReport = lcReport + "  Average Duration: " + TRANSFORM(loStats.AverageDuration, "999.999") + " sec" + CHR(13) + CHR(10)
            lcReport = lcReport + "  Min Duration: " + TRANSFORM(loStats.MinDuration, "999.999") + " sec" + CHR(13) + CHR(10)
            lcReport = lcReport + "  Max Duration: " + TRANSFORM(loStats.MaxDuration, "999.999") + " sec" + CHR(13) + CHR(10)
            
            IF loStats.TotalRecords > 0
                lcReport = lcReport + "  Total Records: " + TRANSFORM(loStats.TotalRecords) + CHR(13) + CHR(10)
                lcReport = lcReport + "  Records/Second: " + TRANSFORM(loStats.RecordsPerSecond, "9999.99") + CHR(13) + CHR(10)
            ENDIF
            
            lcReport = lcReport + CHR(13) + CHR(10)
        ENDFOR
        
        lcReport = lcReport + "================================" + CHR(13) + CHR(10)
        
        RETURN lcReport
    ENDFUNC
    
    *-- Obtine operatiunile unice
    PROTECTED FUNCTION GetUniqueOperations() AS Collection
        LOCAL loOperations AS Collection, i AS Integer, loMetric AS Object
        
        loOperations = CREATEOBJECT("Collection")
        
        FOR i = 1 TO THIS.Metrics.Count
            loMetric = THIS.Metrics.Item(i)
            
            IF loOperations.GetKey(loMetric.OperationName) = 0
                loOperations.Add(loMetric.OperationName, loMetric.OperationName)
            ENDIF
        ENDFOR
        
        RETURN loOperations
    ENDFUNC
    
    *-- Salveaza raportul de performanta
    FUNCTION SavePerformanceReport(tcFileName AS String)
        LOCAL lcReport AS String, lcFileName AS String
        
        lcReport = THIS.GeneratePerformanceReport()
        lcFileName = IIF(EMPTY(tcFileName), "SAFT_Performance_" + TRANSFORM(DATE(), "@Y") + ".txt", tcFileName)
        
        STRTOFILE(lcReport, lcFileName)
        
        RETURN lcFileName
    ENDFUNC
    
    *-- Reseteaza toate metricile
    FUNCTION Reset()
        THIS.Metrics = CREATEOBJECT("Collection")
        THIS.Timers = CREATEOBJECT("Collection")
        THIS.MemorySnapshots = CREATEOBJECT("Collection")
        THIS.StartTime = DATETIME()
    ENDFUNC
    
    FUNCTION Dispose()
        THIS.Metrics = .NULL.
        THIS.Timers = .NULL.
        THIS.MemorySnapshots = .NULL.
    ENDFUNC
ENDDEFINE

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_PerformanceTimer
*!* SCOP:  Timer individual pentru masurarea duratei unei operatiuni
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_PerformanceTimer AS Custom
    TimerId = ""
    OperationName = ""
    StartTime = 0
    EndTime = 0
    Duration = 0
    
    FUNCTION Init(tcOperationName AS String)
        IF !EMPTY(tcOperationName)
            THIS.OperationName = tcOperationName
        ENDIF
        THIS.StartTime = SECONDS()
    ENDFUNC
    
    FUNCTION Stop() AS Number
        THIS.EndTime = SECONDS()
        THIS.Duration = THIS.EndTime - THIS.StartTime
        RETURN THIS.Duration
    ENDFUNC
ENDDEFINE

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_PerformanceMetric
*!* SCOP:  Metrica individuala de performanta
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_PerformanceMetric AS Custom
    OperationName = ""
    MetricType = ""
    Value = 0
    Unit = ""
    Timestamp = {}
    
    FUNCTION Init(tcOperation AS String, tcType AS String, tnValue AS Number, tcUnit AS String)
        IF !EMPTY(tcOperation)
            THIS.OperationName = tcOperation
        ENDIF
        IF !EMPTY(tcType)
            THIS.MetricType = tcType
        ENDIF
        IF !EMPTY(tnValue)
            THIS.Value = tnValue
        ENDIF
        IF !EMPTY(tcUnit)
            THIS.Unit = tcUnit
        ENDIF
        THIS.Timestamp = DATETIME()
    ENDFUNC
ENDDEFINE

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_OperationStatistics
*!* SCOP:  Statistici agregate pentru o operatiune
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_OperationStatistics AS Custom
    OperationName = ""
    ExecutionCount = 0
    TotalDuration = 0
    AverageDuration = 0
    MinDuration = 0
    MaxDuration = 0
    TotalRecords = 0
    AverageRecordsPerExecution = 0
    RecordsPerSecond = 0
    
    FUNCTION Init(tcOperationName AS String)
        IF !EMPTY(tcOperationName)
            THIS.OperationName = tcOperationName
        ENDIF
    ENDFUNC
    
    FUNCTION GetSummary() AS String
        LOCAL lcSummary AS String
        
        lcSummary = "Operation: " + THIS.OperationName + CHR(13) + CHR(10)
        lcSummary = lcSummary + "Executions: " + TRANSFORM(THIS.ExecutionCount) + CHR(13) + CHR(10)
        lcSummary = lcSummary + "Avg Duration: " + TRANSFORM(THIS.AverageDuration, "999.999") + " sec" + CHR(13) + CHR(10)
        
        IF THIS.TotalRecords > 0
            lcSummary = lcSummary + "Records/sec: " + TRANSFORM(THIS.RecordsPerSecond, "9999.99") + CHR(13) + CHR(10)
        ENDIF
        
        RETURN lcSummary
    ENDFUNC
ENDDEFINE