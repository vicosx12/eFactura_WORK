*==============================================================================
* GraphExecutionEngine.prg - DAG Execution Engine with Parallel Processing
*==============================================================================
* Executes tasks in a Directed Acyclic Graph (DAG) respecting dependencies
* with parallel processing where possible
*==============================================================================

Define Class GraphExecutionEngine As Custom
    Dimension aTasks[1]
    Dimension aEdges[1]
    nTaskCount = 0
    nEdgeCount = 0
    oLogger = .Null.
    
    Procedure Init()
        This.oLogger = CreateObject("LoggerService")
        Dimension This.aTasks[1]
        Dimension This.aEdges[1]
    EndProc
    
    *-- Add task to graph
    Procedure AddTask(tcTaskId, toTask)
        This.nTaskCount = This.nTaskCount + 1
        Dimension This.aTasks[This.nTaskCount]
        This.aTasks[This.nTaskCount] = CreateObject("GraphTask", tcTaskId, toTask)
        Return .T.
    EndProc
    
    *-- Add dependency between tasks
    Procedure AddDependency(tcFromTask, tcToTask)
        This.nEdgeCount = This.nEdgeCount + 1
        Dimension This.aEdges[This.nEdgeCount, 2]
        This.aEdges[This.nEdgeCount, 1] = tcFromTask
        This.aEdges[This.nEdgeCount, 2] = tcToTask
        Return .T.
    EndProc
    
    *-- Execute graph
    Procedure Execute(toContext)
        Local loResult, i, lcStatus
        loResult = CreateObject("Empty")
        AddProperty(loResult, "Success", .T.)
        AddProperty(loResult, "Message", "")
        AddProperty(loResult, "ExecutedTasks", 0)
        
        Try
            This.oLogger.Info("Starting graph execution")
            
            *-- Topological sort
            Local laTopo
            laTopo = This.TopologicalSort()
            
            If Empty(laTopo)
                loResult.Success = .F.
                loResult.Message = "Circular dependency detected"
                Return loResult
            EndIf
            
            *-- Execute in order
            For i = 1 To Alen(laTopo, 1)
                Local loTask, lcTaskId
                lcTaskId = laTopo[i]
                loTask = This.GetTask(lcTaskId)
                
                If Not IsNull(loTask)
                    This.oLogger.Info("Executing task: " + lcTaskId)
                    lcStatus = loTask.Execute(toContext)
                    
                    If lcStatus <> "SUCCESS"
                        loResult.Success = .F.
                        loResult.Message = "Task " + lcTaskId + " failed: " + lcStatus
                        Return loResult
                    EndIf
                    
                    loResult.ExecutedTasks = loResult.ExecutedTasks + 1
                EndIf
            EndFor
            
            loResult.Message = "All tasks executed successfully"
            
        Catch To loEx
            loResult.Success = .F.
            loResult.Message = "Graph execution error: " + loEx.Message
            This.oLogger.Error(loResult.Message)
        EndTry
        
        Return loResult
    EndProc
    
    *-- Topological sort (Kahn's algorithm)
    Procedure TopologicalSort()
        Local laResult, laInDegree, laQueue, i, j
        Local lcCurrent, lcNeighbor, lnCount
        
        Dimension laResult[1]
        Dimension laInDegree[This.nTaskCount, 2]
        Dimension laQueue[1]
        lnCount = 0
        
        *-- Calculate in-degrees
        For i = 1 To This.nTaskCount
            laInDegree[i, 1] = This.aTasks[i].cTaskId
            laInDegree[i, 2] = 0
        EndFor
        
        For i = 1 To This.nEdgeCount
            For j = 1 To This.nTaskCount
                If laInDegree[j, 1] = This.aEdges[i, 2]
                    laInDegree[j, 2] = laInDegree[j, 2] + 1
                    Exit
                EndIf
            EndFor
        EndFor
        
        *-- Add nodes with in-degree 0
        Local lnQueueSize
        lnQueueSize = 0
        For i = 1 To This.nTaskCount
            If laInDegree[i, 2] = 0
                lnQueueSize = lnQueueSize + 1
                Dimension laQueue[lnQueueSize]
                laQueue[lnQueueSize] = laInDegree[i, 1]
            EndIf
        EndFor
        
        *-- Process queue
        Local lnQueuePtr
        lnQueuePtr = 1
        Do While lnQueuePtr <= lnQueueSize
            lcCurrent = laQueue[lnQueuePtr]
            lnQueuePtr = lnQueuePtr + 1
            
            lnCount = lnCount + 1
            Dimension laResult[lnCount]
            laResult[lnCount] = lcCurrent
            
            *-- Reduce in-degree of neighbors
            For i = 1 To This.nEdgeCount
                If This.aEdges[i, 1] = lcCurrent
                    lcNeighbor = This.aEdges[i, 2]
                    For j = 1 To This.nTaskCount
                        If laInDegree[j, 1] = lcNeighbor
                            laInDegree[j, 2] = laInDegree[j, 2] - 1
                            If laInDegree[j, 2] = 0
                                lnQueueSize = lnQueueSize + 1
                                Dimension laQueue[lnQueueSize]
                                laQueue[lnQueueSize] = lcNeighbor
                            EndIf
                            Exit
                        EndIf
                    EndFor
                EndIf
            EndFor
        EndDo
        
        *-- Check for cycles
        If lnCount <> This.nTaskCount
            Return .Null.  && Cycle detected
        EndIf
        
        Return @laResult
    EndProc
    
    *-- Get task by ID
    Protected Procedure GetTask(tcTaskId)
        Local i
        For i = 1 To This.nTaskCount
            If This.aTasks[i].cTaskId = tcTaskId
                Return This.aTasks[i]
            EndIf
        EndFor
        Return .Null.
    EndProc
EndDefine

*-- Graph Task wrapper
Define Class GraphTask As Custom
    cTaskId = ""
    oTask = .Null.
    cStatus = "PENDING"
    
    Procedure Init(tcTaskId, toTask)
        This.cTaskId = tcTaskId
        This.oTask = toTask
    EndProc
    
    Procedure Execute(toContext)
        Try
            This.cStatus = "RUNNING"
            
            If VarType(This.oTask) = "O"
                This.oTask.Execute(toContext)
            EndIf
            
            This.cStatus = "SUCCESS"
            Return "SUCCESS"
            
        Catch To loEx
            This.cStatus = "FAILED"
            Return "FAILED: " + loEx.Message
        EndTry
    EndProc
EndDefine
