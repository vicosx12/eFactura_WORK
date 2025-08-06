*!* ============================================================================
*!* FISIER: SAFT_AsyncProcessor.prg
*!* ============================================================================
*!* AUTOR: Alex (Engineer) - MGX Team
*!* DATA:  28.07.2025
*!* SCOP:  Procesare asincrona pentru operatiuni mari SAFT
*!* Permite procesarea in batch-uri si task queue management
*!* ============================================================================

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_AsyncProcessor
*!* SCOP:  Procesor async pentru operatiuni de lunga durata
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_AsyncProcessor AS Custom
    TaskQueue = .NULL.
    ActiveTasks = .NULL.
    MaxConcurrentTasks = 3
    IsProcessing = .F.
    BatchSize = 1000
    
    FUNCTION Init()
        THIS.TaskQueue = CREATEOBJECT("Collection")
        THIS.ActiveTasks = CREATEOBJECT("Collection")
    ENDFUNC
    
    *-- Adauga un task in coada
    FUNCTION QueueTask(toTask AS SAFT_AsyncTask)
        LOCAL lcTaskId AS String
        
        IF VARTYPE(toTask) != "O"
            RETURN ""
        ENDIF
        
        lcTaskId = "TASK_" + TRANSFORM(DATETIME(), "@Y") + "_" + TRANSFORM(THIS.TaskQueue.Count + 1)
        toTask.TaskId = lcTaskId
        toTask.Status = "QUEUED"
        toTask.QueuedTime = DATETIME()
        
        THIS.TaskQueue.Add(toTask, lcTaskId)
        
        RETURN lcTaskId
    ENDFUNC
    
    *-- Proceseaza coada de task-uri
    FUNCTION ProcessQueue() AS Boolean
        LOCAL i AS Integer, loTask AS SAFT_AsyncTask
        LOCAL llAllCompleted AS Boolean
        
        IF THIS.IsProcessing
            RETURN .F.
        ENDIF
        
        THIS.IsProcessing = .T.
        llAllCompleted = .T.
        
        TRY
            *-- Proceseaza task-urile in coada
            FOR i = 1 TO THIS.TaskQueue.Count
                loTask = THIS.TaskQueue.Item(i)
                
                IF loTask.Status = "QUEUED" AND THIS.ActiveTasks.Count < THIS.MaxConcurrentTasks
                    THIS.StartTask(loTask)
                ENDIF
                
                IF loTask.Status != "COMPLETED" AND loTask.Status != "FAILED"
                    llAllCompleted = .F.
                ENDIF
            ENDFOR
            
            *-- Verifica task-urile active
            THIS.UpdateActiveTasks()
            
        CATCH TO oException
            *-- Log eroarea
        FINALLY
            THIS.IsProcessing = .F.
        ENDTRY
        
        RETURN llAllCompleted
    ENDFUNC
    
    *-- Porneste un task
    PROTECTED FUNCTION StartTask(toTask AS SAFT_AsyncTask)
        toTask.Status = "RUNNING"
        toTask.StartTime = DATETIME()
        
        THIS.ActiveTasks.Add(toTask, toTask.TaskId)
        
        *-- In VFP, simulam procesarea asincrona prin batch processing
        THIS.ExecuteTaskBatch(toTask)
    ENDFUNC
    
    *-- Executa un batch din task
    PROTECTED FUNCTION ExecuteTaskBatch(toTask AS SAFT_AsyncTask)
        LOCAL llBatchCompleted AS Boolean
        LOCAL lnProcessedItems AS Integer
        
        TRY
            llBatchCompleted = toTask.ProcessBatch(THIS.BatchSize)
            lnProcessedItems = toTask.ProcessedItems
            
            IF llBatchCompleted
                toTask.Status = "COMPLETED"
                toTask.EndTime = DATETIME()
                THIS.ActiveTasks.Remove(toTask.TaskId)
            ELSE
                toTask.Status = "RUNNING"
            ENDIF
            
        CATCH TO oException
            toTask.Status = "FAILED"
            toTask.ErrorMessage = oException.Message
            toTask.EndTime = DATETIME()
            THIS.ActiveTasks.Remove(toTask.TaskId)
        ENDTRY
    ENDFUNC
    
    *-- Actualizeaza task-urile active
    PROTECTED FUNCTION UpdateActiveTasks()
        LOCAL i AS Integer, loTask AS SAFT_AsyncTask
        
        FOR i = THIS.ActiveTasks.Count TO 1 STEP -1
            loTask = THIS.ActiveTasks.Item(i)
            
            IF loTask.Status = "RUNNING"
                *-- Continua procesarea batch-ului
                THIS.ExecuteTaskBatch(loTask)
            ENDIF
        ENDFOR
    ENDFUNC
    
    *-- Obtine statusul unui task
    FUNCTION GetTaskStatus(tcTaskId AS String) AS String
        LOCAL loTask AS Object
        
        IF THIS.TaskQueue.GetKey(tcTaskId) > 0
            loTask = THIS.TaskQueue.Item(tcTaskId)
            RETURN loTask.Status
        ENDIF
        
        RETURN "NOT_FOUND"
    ENDFUNC
    
    *-- Obtine progresul unui task
    FUNCTION GetTaskProgress(tcTaskId AS String) AS Object
        LOCAL loTask AS Object, loProgress AS Object
        
        IF THIS.TaskQueue.GetKey(tcTaskId) = 0
            RETURN .NULL.
        ENDIF
        
        loTask = THIS.TaskQueue.Item(tcTaskId)
        
        loProgress = CREATEOBJECT("Empty")
        ADDPROPERTY(loProgress, "TaskId", loTask.TaskId)
        ADDPROPERTY(loProgress, "Status", loTask.Status)
        ADDPROPERTY(loProgress, "TotalItems", loTask.TotalItems)
        ADDPROPERTY(loProgress, "ProcessedItems", loTask.ProcessedItems)
        ADDPROPERTY(loProgress, "PercentComplete", IIF(loTask.TotalItems > 0, (loTask.ProcessedItems * 100) / loTask.TotalItems, 0))
        ADDPROPERTY(loProgress, "StartTime", loTask.StartTime)
        ADDPROPERTY(loProgress, "EstimatedEndTime", loTask.GetEstimatedEndTime())
        
        RETURN loProgress
    ENDFUNC
ENDDEFINE

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_AsyncTask
*!* SCOP:  Task de baza pentru procesare asincrona
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_AsyncTask AS Custom
    TaskId = ""
    TaskName = ""
    Status = "CREATED"
    QueuedTime = {}
    StartTime = {}
    EndTime = {}
    TotalItems = 0
    ProcessedItems = 0
    CurrentBatch = 0
    BatchSize = 1000
    ErrorMessage = ""
    Context = .NULL.
    
    FUNCTION Init(tcTaskName AS String, tnTotalItems AS Integer, toContext AS Object)
        THIS.TaskName = tcTaskName
        THIS.TotalItems = tnTotalItems
        THIS.Context = toContext
    ENDFUNC
    
    *-- Proceseaza un batch de items (metoda abstracta)
    FUNCTION ProcessBatch(tnBatchSize AS Integer) AS Boolean
        *-- Aceasta metoda trebuie suprascriса de clasele derivate
        ERROR "ProcessBatch must be implemented by derived class"
        RETURN .F.
    ENDFUNC
    
    *-- Calculeaza timpul estimat de finalizare
    FUNCTION GetEstimatedEndTime() AS Datetime
        LOCAL lnElapsedTime AS Number, lnItemsPerSecond AS Number
        LOCAL lnRemainingItems AS Integer, lnRemainingTime AS Number
        
        IF THIS.Status != "RUNNING" OR THIS.ProcessedItems = 0
            RETURN {}
        ENDIF
        
        lnElapsedTime = (DATETIME() - THIS.StartTime) * 24 * 3600  && Convert to seconds
        lnItemsPerSecond = THIS.ProcessedItems / lnElapsedTime
        lnRemainingItems = THIS.TotalItems - THIS.ProcessedItems
        
        IF lnItemsPerSecond > 0
            lnRemainingTime = lnRemainingItems / lnItemsPerSecond
            RETURN DATETIME() + (lnRemainingTime / (24 * 3600))  && Convert back to datetime
        ENDIF
        
        RETURN {}
    ENDFUNC
ENDDEFINE

*!*-----------------------------------------------------------------------------
*!* CLASS: SAFT_DataExtractionTask
*!* SCOP:  Task specific pentru extragerea datelor SAFT
*!*-----------------------------------------------------------------------------
DEFINE CLASS SAFT_DataExtractionTask AS SAFT_AsyncTask
    TableName = ""
    SQLQuery = ""
    Repository = .NULL.
    
    FUNCTION Init(tcTaskName AS String, tcTableName AS String, tcSQL AS String, toRepository AS Object, toContext AS Object)
        LOCAL lnTotalItems AS Integer
        
        *-- Numara totalul de inregistrari
        lnTotalItems = THIS.CountRecords(tcSQL)
        
        DODEFAULT(tcTaskName, lnTotalItems, toContext)
        
        THIS.TableName = tcTableName
        THIS.SQLQuery = tcSQL
        THIS.Repository = toRepository
    ENDFUNC
    
    FUNCTION ProcessBatch(tnBatchSize AS Integer) AS Boolean
        LOCAL lcBatchSQL AS String, lnStartRecord AS Integer, lnEndRecord AS Integer
        LOCAL llCompleted AS Boolean
        
        lnStartRecord = THIS.ProcessedItems + 1
        lnEndRecord = MIN(THIS.ProcessedItems + tnBatchSize, THIS.TotalItems)
        
        *-- Construieste query pentru batch
        lcBatchSQL = THIS.BuildBatchQuery(lnStartRecord, lnEndRecord)
        
        TRY
            *-- Executa batch-ul
            THIS.ExecuteBatch(lcBatchSQL, lnStartRecord, lnEndRecord)
            
            THIS.ProcessedItems = lnEndRecord
            THIS.CurrentBatch = THIS.CurrentBatch + 1
            
            llCompleted = (THIS.ProcessedItems >= THIS.TotalItems)
            
            *-- Notifica progresul
            IF VARTYPE(THIS.Context) = "O"
                THIS.Context.Notify("ASYNC_PROGRESS", THIS.GetProgressInfo())
            ENDIF
            
        CATCH TO oException
            THIS.ErrorMessage = oException.Message
            THROW oException
        ENDTRY
        
        RETURN llCompleted
    ENDFUNC
    
    PROTECTED FUNCTION CountRecords(tcSQL AS String) AS Integer
        LOCAL lcCountSQL AS String, lnCount AS Integer
        
        *-- Construieste query de numarare
        lcCountSQL = "SELECT COUNT(*) as RecCount FROM (" + tcSQL + ") temp"
        
        IF VARTYPE(THIS.Repository) = "O"
            lnCount = THIS.Repository.ExecuteScalar(lcCountSQL)
        ELSE
            lnCount = 0
        ENDIF
        
        RETURN lnCount
    ENDFUNC
    
    PROTECTED FUNCTION BuildBatchQuery(tnStart AS Integer, tnEnd AS Integer) AS String
        *-- In VFP, folosim SKIP si limitare prin counter
        RETURN THIS.SQLQuery
    ENDFUNC
    
    PROTECTED FUNCTION ExecuteBatch(tcSQL AS String, tnStart AS Integer, tnEnd AS Integer)
        LOCAL i AS Integer, lnRecordsProcessed AS Integer
        
        IF VARTYPE(THIS.Repository) = "O"
            *-- Executa query-ul si proceseaza inregistrarile
            THIS.Repository.ExecuteQuery(tcSQL)
            
            *-- Simuleaza procesarea batch-ului
            lnRecordsProcessed = tnEnd - tnStart + 1
            
            *-- Aici s-ar face procesarea efectiva a datelor
            *-- (extragere XML, validari, etc.)
            
        ENDIF
    ENDFUNC
    
    PROTECTED FUNCTION GetProgressInfo() AS Object
        LOCAL loInfo AS Object
        
        loInfo = CREATEOBJECT("Empty")
        ADDPROPERTY(loInfo, "TaskName", THIS.TaskName)
        ADDPROPERTY(loInfo, "TableName", THIS.TableName)
        ADDPROPERTY(loInfo, "ProcessedItems", THIS.ProcessedItems)
        ADDPROPERTY(loInfo, "TotalItems", THIS.TotalItems)
        ADDPROPERTY(loInfo, "CurrentBatch", THIS.CurrentBatch)
        ADDPROPERTY(loInfo, "PercentComplete", (THIS.ProcessedItems * 100) / THIS.TotalItems)
        
        RETURN loInfo
    ENDFUNC
ENDDEFINE