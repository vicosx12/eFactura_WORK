*==============================================================================
* TemporalWorkflowService.prg - Durable Workflow Orchestration
*==============================================================================
* Provides durable workflows with timers, signals, and automatic compensation
*==============================================================================

Define Class TemporalWorkflowService As Custom
    Dimension aWorkflows[1]
    nWorkflowCount = 0
    oLogger = .Null.
    cPersistencePath = ""
    
    Procedure Init()
        This.oLogger = CreateObject("LoggerService")
        This.cPersistencePath = Sys(2023) + "\Workflows\"
        
        If Not Directory(This.cPersistencePath)
            Mkdir (This.cPersistencePath)
        EndIf
        
        Dimension This.aWorkflows[1]
    EndProc
    
    *-- Start new workflow
    Procedure StartWorkflow(tcWorkflowId, tcWorkflowType, toInput)
        Local loWorkflow
        loWorkflow = CreateObject("TemporalWorkflow", tcWorkflowId, tcWorkflowType, toInput)
        
        This.nWorkflowCount = This.nWorkflowCount + 1
        Dimension This.aWorkflows[This.nWorkflowCount]
        This.aWorkflows[This.nWorkflowCount] = loWorkflow
        
        This.oLogger.Info("Started workflow: " + tcWorkflowId + " (" + tcWorkflowType + ")")
        This.PersistWorkflow(loWorkflow)
        
        Return loWorkflow
    EndProc
    
    *-- Execute workflow step
    Procedure ExecuteStep(tcWorkflowId, tcStepName, toStepFunc)
        Local loWorkflow, loResult
        loWorkflow = This.GetWorkflow(tcWorkflowId)
        
        If IsNull(loWorkflow)
            Return CreateObject("WorkflowError", "Workflow not found")
        EndIf
        
        Try
            loResult = loWorkflow.ExecuteStep(tcStepName, toStepFunc)
            This.PersistWorkflow(loWorkflow)
            Return loResult
            
        Catch To loEx
            This.oLogger.Error("Workflow step error: " + loEx.Message)
            Return CreateObject("WorkflowError", loEx.Message)
        EndTry
    EndProc
    
    *-- Schedule timer
    Procedure ScheduleTimer(tcWorkflowId, tnDurationSec, tcTimerName)
        Local loWorkflow
        loWorkflow = This.GetWorkflow(tcWorkflowId)
        
        If Not IsNull(loWorkflow)
            loWorkflow.AddTimer(tnDurationSec, tcTimerName)
            This.PersistWorkflow(loWorkflow)
            Return .T.
        EndIf
        
        Return .F.
    EndProc
    
    *-- Send signal to workflow
    Procedure SignalWorkflow(tcWorkflowId, tcSignalName, toData)
        Local loWorkflow
        loWorkflow = This.GetWorkflow(tcWorkflowId)
        
        If Not IsNull(loWorkflow)
            loWorkflow.ReceiveSignal(tcSignalName, toData)
            This.PersistWorkflow(loWorkflow)
            Return .T.
        EndIf
        
        Return .F.
    EndProc
    
    *-- Complete workflow
    Procedure CompleteWorkflow(tcWorkflowId, toResult)
        Local loWorkflow
        loWorkflow = This.GetWorkflow(tcWorkflowId)
        
        If Not IsNull(loWorkflow)
            loWorkflow.Complete(toResult)
            This.PersistWorkflow(loWorkflow)
            This.oLogger.Info("Workflow completed: " + tcWorkflowId)
            Return .T.
        EndIf
        
        Return .F.
    EndProc
    
    *-- Compensate workflow
    Procedure CompensateWorkflow(tcWorkflowId)
        Local loWorkflow, i
        loWorkflow = This.GetWorkflow(tcWorkflowId)
        
        If IsNull(loWorkflow)
            Return .F.
        EndIf
        
        This.oLogger.Info("Compensating workflow: " + tcWorkflowId)
        
        *-- Execute compensation in reverse order
        For i = loWorkflow.nStepCount To 1 Step -1
            If Not Empty(loWorkflow.aSteps[i].oCompensation)
                Try
                    loWorkflow.aSteps[i].oCompensation.Execute()
                Catch To loEx
                    This.oLogger.Error("Compensation failed: " + loEx.Message)
                EndTry
            EndIf
        EndFor
        
        loWorkflow.cStatus = "COMPENSATED"
        This.PersistWorkflow(loWorkflow)
        Return .T.
    EndProc
    
    *-- Get workflow by ID
    Protected Procedure GetWorkflow(tcWorkflowId)
        Local i
        For i = 1 To This.nWorkflowCount
            If This.aWorkflows[i].cWorkflowId = tcWorkflowId
                Return This.aWorkflows[i]
            EndIf
        EndFor
        Return .Null.
    EndProc
    
    *-- Persist workflow state
    Protected Procedure PersistWorkflow(toWorkflow)
        Local lcFile, lcJson
        lcFile = This.cPersistencePath + toWorkflow.cWorkflowId + ".json"
        
        Try
            lcJson = This.SerializeWorkflow(toWorkflow)
            StrToFile(lcJson, lcFile)
        Catch To loEx
            This.oLogger.Error("Failed to persist workflow: " + loEx.Message)
        EndTry
    EndProc
    
    *-- Serialize workflow to JSON
    Protected Procedure SerializeWorkflow(toWorkflow)
        Local lcJson
        lcJson = '{"workflowId":"' + toWorkflow.cWorkflowId + '",'
        lcJson = lcJson + '"type":"' + toWorkflow.cType + '",'
        lcJson = lcJson + '"status":"' + toWorkflow.cStatus + '",'
        lcJson = lcJson + '"startTime":"' + Ttoc(toWorkflow.tStartTime) + '",'
        lcJson = lcJson + '"stepCount":' + Transform(toWorkflow.nStepCount) + '}'
        Return lcJson
    EndProc
EndDefine

*-- Temporal Workflow instance
Define Class TemporalWorkflow As Custom
    cWorkflowId = ""
    cType = ""
    cStatus = "RUNNING"
    tStartTime = {}
    oInput = .Null.
    oResult = .Null.
    Dimension aSteps[1]
    Dimension aTimers[1]
    Dimension aSignals[1]
    nStepCount = 0
    nTimerCount = 0
    nSignalCount = 0
    
    Procedure Init(tcWorkflowId, tcType, toInput)
        This.cWorkflowId = tcWorkflowId
        This.cType = tcType
        This.oInput = toInput
        This.tStartTime = Datetime()
        Dimension This.aSteps[1]
        Dimension This.aTimers[1]
        Dimension This.aSignals[1]
    EndProc
    
    Procedure ExecuteStep(tcStepName, toStepFunc)
        Local loStep, loResult
        
        This.nStepCount = This.nStepCount + 1
        Dimension This.aSteps[This.nStepCount]
        
        loStep = CreateObject("WorkflowStep", tcStepName)
        This.aSteps[This.nStepCount] = loStep
        
        Try
            loStep.cStatus = "RUNNING"
            loResult = toStepFunc.Execute()
            loStep.cStatus = "COMPLETED"
            loStep.oResult = loResult
            Return loResult
            
        Catch To loEx
            loStep.cStatus = "FAILED"
            loStep.cError = loEx.Message
            Throw
        EndTry
    EndProc
    
    Procedure AddTimer(tnDurationSec, tcTimerName)
        This.nTimerCount = This.nTimerCount + 1
        Dimension This.aTimers[This.nTimerCount, 3]
        This.aTimers[This.nTimerCount, 1] = tcTimerName
        This.aTimers[This.nTimerCount, 2] = Datetime() + tnDurationSec
        This.aTimers[This.nTimerCount, 3] = "PENDING"
    EndProc
    
    Procedure ReceiveSignal(tcSignalName, toData)
        This.nSignalCount = This.nSignalCount + 1
        Dimension This.aSignals[This.nSignalCount, 3]
        This.aSignals[This.nSignalCount, 1] = tcSignalName
        This.aSignals[This.nSignalCount, 2] = toData
        This.aSignals[This.nSignalCount, 3] = Datetime()
    EndProc
    
    Procedure Complete(toResult)
        This.cStatus = "COMPLETED"
        This.oResult = toResult
    EndProc
EndDefine

*-- Workflow Step
Define Class WorkflowStep As Custom
    cStepName = ""
    cStatus = "PENDING"
    oResult = .Null.
    cError = ""
    oCompensation = .Null.
    
    Procedure Init(tcStepName)
        This.cStepName = tcStepName
    EndProc
EndDefine

*-- Workflow Error
Define Class WorkflowError As Custom
    cMessage = ""
    
    Procedure Init(tcMessage)
        This.cMessage = tcMessage
    EndProc
EndDefine
