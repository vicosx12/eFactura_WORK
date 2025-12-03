*******************************************************************************
* SagaOrchestrator.prg
* Saga Pattern pentru coordonarea fluxurilor multi-step cu compensare automată
* 
* Funcționalități:
* - Definire și executare saga-uri cu pași secvențiali
* - Compensare automată la eșec (rollback)
* - Suport pentru retry per pas
* - Logging detaliat al execuției
* - Persistență stare saga pentru recovery
* - Timeout configurabil per pas și saga
* - Evenimente pentru monitorizare
*
* Exemplu utilizare:
*   loSaga = CreateObject("SagaOrchestrator")
*   loSaga.BeginSaga("InvoiceUpload_" + Transform(lnId))
*   loSaga.AddStep("Validate", "ValidateInvoice", "RollbackValidation")
*   loSaga.AddStep("GenerateXml", "GenerateXmlFile", "DeleteXmlFile")
*   loSaga.AddStep("Upload", "UploadToAnaf", "CancelUpload")
*   loSaga.AddStep("SaveReceipt", "PersistReceipt", "DeleteReceipt")
*   llSuccess = loSaga.Execute(toContext)
*******************************************************************************

Define Class SagaOrchestrator As Custom
    
    * Identificator saga
    cSagaId = ""
    
    * Stare saga
    cState = "PENDING"  && PENDING, RUNNING, COMPLETED, COMPENSATING, FAILED, COMPENSATED
    
    * Pași saga
    Dimension aSteps[1, 6]  && StepName, ExecuteMethod, CompensateMethod, Status, RetryCount, Error
    nStepCount = 0
    nCurrentStep = 0
    
    * Configurare
    nMaxRetries = 3
    nRetryDelaySeconds = 2
    nStepTimeoutSeconds = 300
    nSagaTimeoutSeconds = 1800
    lAutoCompensate = .T.
    
    * Logging și telemetrie
    oLogger = .Null.
    oEventDispatcher = .Null.
    
    * Context execuție
    oContext = .Null.
    oExecutor = .Null.
    
    * Statistici
    nStartTime = 0
    nEndTime = 0
    nCompletedSteps = 0
    nFailedSteps = 0
    nCompensatedSteps = 0
    
    * Persistență stare
    cStateFilePath = ""
    lPersistState = .T.
    
    *---------------------------------------------------------------------------
    Procedure Init
        This.cStateFilePath = Sys(2023) + "\Saga\"
        
        * Creează directorul dacă nu există
        If Not Directory(This.cStateFilePath)
            Mkdir (This.cStateFilePath)
        EndIf
        
        This.Reset()
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează logger-ul
    *---------------------------------------------------------------------------
    Procedure SetLogger(toLogger)
        This.oLogger = toLogger
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează event dispatcher-ul
    *---------------------------------------------------------------------------
    Procedure SetEventDispatcher(toDispatcher)
        This.oEventDispatcher = toDispatcher
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează executor-ul de metode (obiectul care conține metodele)
    *---------------------------------------------------------------------------
    Procedure SetExecutor(toExecutor)
        This.oExecutor = toExecutor
    EndProc
    
    *---------------------------------------------------------------------------
    * Resetează saga pentru reutilizare
    *---------------------------------------------------------------------------
    Procedure Reset
        This.cSagaId = ""
        This.cState = "PENDING"
        This.nStepCount = 0
        This.nCurrentStep = 0
        This.nStartTime = 0
        This.nEndTime = 0
        This.nCompletedSteps = 0
        This.nFailedSteps = 0
        This.nCompensatedSteps = 0
        This.oContext = .Null.
        Dimension This.aSteps[1, 6]
    EndProc
    
    *---------------------------------------------------------------------------
    * Începe o nouă saga
    *---------------------------------------------------------------------------
    Procedure BeginSaga(tcSagaId)
        This.Reset()
        This.cSagaId = tcSagaId
        This.cState = "PENDING"
        
        This.Log("INFO", "Saga started: " + tcSagaId)
        This.FireEvent("SagaStarted", tcSagaId)
        
        Return .T.
    EndProc
    
    *---------------------------------------------------------------------------
    * Adaugă un pas la saga
    * tcStepName - Numele pasului
    * tcExecuteMethod - Metoda de executare
    * tcCompensateMethod - Metoda de compensare (rollback)
    * tnMaxRetries - Număr maxim retry-uri (opțional, default din configurare)
    *---------------------------------------------------------------------------
    Procedure AddStep(tcStepName, tcExecuteMethod, tcCompensateMethod, tnMaxRetries)
        Local lnRetries
        
        lnRetries = Iif(VarType(tnMaxRetries) = 'N', tnMaxRetries, This.nMaxRetries)
        
        This.nStepCount = This.nStepCount + 1
        Dimension This.aSteps[This.nStepCount, 6]
        
        This.aSteps[This.nStepCount, 1] = tcStepName
        This.aSteps[This.nStepCount, 2] = tcExecuteMethod
        This.aSteps[This.nStepCount, 3] = tcCompensateMethod
        This.aSteps[This.nStepCount, 4] = "PENDING"  && Status: PENDING, RUNNING, COMPLETED, FAILED, COMPENSATING, COMPENSATED
        This.aSteps[This.nStepCount, 5] = 0          && Retry count
        This.aSteps[This.nStepCount, 6] = ""         && Error message
        
        This.Log("DEBUG", "Step added: " + tcStepName + " (Execute: " + tcExecuteMethod + ", Compensate: " + tcCompensateMethod + ")")
        
        Return This  && Fluent interface
    EndProc
    
    *---------------------------------------------------------------------------
    * Execută saga
    *---------------------------------------------------------------------------
    Procedure Execute(toContext)
        Local llSuccess, lnStartTime, lnStep, llStepSuccess
        Local lcStepName, lcExecuteMethod
        
        If This.nStepCount = 0
            This.Log("ERROR", "No steps defined for saga")
            Return .F.
        EndIf
        
        This.oContext = toContext
        This.cState = "RUNNING"
        This.nStartTime = Seconds()
        llSuccess = .T.
        
        This.PersistState()
        
        * Execută fiecare pas
        For lnStep = 1 To This.nStepCount
            This.nCurrentStep = lnStep
            lcStepName = This.aSteps[lnStep, 1]
            lcExecuteMethod = This.aSteps[lnStep, 2]
            
            This.aSteps[lnStep, 4] = "RUNNING"
            This.Log("INFO", "Executing step " + Transform(lnStep) + "/" + Transform(This.nStepCount) + ": " + lcStepName)
            This.FireEvent("StepStarted", lcStepName)
            
            llStepSuccess = This.ExecuteStepWithRetry(lnStep)
            
            If llStepSuccess
                This.aSteps[lnStep, 4] = "COMPLETED"
                This.nCompletedSteps = This.nCompletedSteps + 1
                This.Log("INFO", "Step completed: " + lcStepName)
                This.FireEvent("StepCompleted", lcStepName)
            Else
                This.aSteps[lnStep, 4] = "FAILED"
                This.nFailedSteps = This.nFailedSteps + 1
                This.Log("ERROR", "Step failed: " + lcStepName + " - " + This.aSteps[lnStep, 6])
                This.FireEvent("StepFailed", lcStepName)
                llSuccess = .F.
                Exit
            EndIf
            
            This.PersistState()
            
            * Verifică timeout saga
            If Seconds() - This.nStartTime > This.nSagaTimeoutSeconds
                This.Log("ERROR", "Saga timeout exceeded")
                llSuccess = .F.
                Exit
            EndIf
        EndFor
        
        * Compensare automată la eșec
        If Not llSuccess And This.lAutoCompensate
            This.Compensate()
        EndIf
        
        This.nEndTime = Seconds()
        
        If llSuccess
            This.cState = "COMPLETED"
            This.Log("INFO", "Saga completed successfully in " + Transform(This.nEndTime - This.nStartTime) + "s")
            This.FireEvent("SagaCompleted", This.cSagaId)
        Else
            If This.cState <> "COMPENSATED"
                This.cState = "FAILED"
            EndIf
            This.Log("ERROR", "Saga failed: " + This.cSagaId)
            This.FireEvent("SagaFailed", This.cSagaId)
        EndIf
        
        This.PersistState()
        
        Return llSuccess
    EndProc
    
    *---------------------------------------------------------------------------
    * Execută un pas cu retry
    *---------------------------------------------------------------------------
    Protected Procedure ExecuteStepWithRetry(tnStepIndex)
        Local llSuccess, lnAttempt, lcMethod, lcError
        Local lnMaxRetries, lnDelay
        
        lcMethod = This.aSteps[tnStepIndex, 2]
        lnMaxRetries = This.nMaxRetries
        llSuccess = .F.
        
        For lnAttempt = 1 To lnMaxRetries + 1
            This.aSteps[tnStepIndex, 5] = lnAttempt - 1
            
            If lnAttempt > 1
                This.Log("INFO", "Retry attempt " + Transform(lnAttempt - 1) + " for step: " + This.aSteps[tnStepIndex, 1])
                * Exponential backoff
                lnDelay = This.nRetryDelaySeconds * (2 ^ (lnAttempt - 2))
                Inkey(lnDelay)
            EndIf
            
            Try
                If VarType(This.oExecutor) = 'O' And PemStatus(This.oExecutor, lcMethod, 5)
                    llSuccess = Evaluate("This.oExecutor." + lcMethod + "(This.oContext)")
                Else
                    * Fallback: încearcă metoda pe context
                    If VarType(This.oContext) = 'O' And PemStatus(This.oContext, lcMethod, 5)
                        llSuccess = Evaluate("This.oContext." + lcMethod + "()")
                    Else
                        This.aSteps[tnStepIndex, 6] = "Method not found: " + lcMethod
                        Return .F.
                    EndIf
                EndIf
                
                If llSuccess
                    Exit
                Else
                    This.aSteps[tnStepIndex, 6] = "Step returned false"
                EndIf
            Catch To loEx
                This.aSteps[tnStepIndex, 6] = loEx.Message
                llSuccess = .F.
            EndTry
        EndFor
        
        Return llSuccess
    EndProc
    
    *---------------------------------------------------------------------------
    * Compensare (rollback) pentru pașii executați
    *---------------------------------------------------------------------------
    Procedure Compensate
        Local lnStep, lcStepName, lcCompensateMethod, llSuccess
        
        This.cState = "COMPENSATING"
        This.Log("INFO", "Starting compensation for saga: " + This.cSagaId)
        This.FireEvent("CompensationStarted", This.cSagaId)
        
        * Compensează în ordine inversă
        For lnStep = This.nCurrentStep To 1 Step -1
            If This.aSteps[lnStep, 4] = "COMPLETED" Or This.aSteps[lnStep, 4] = "FAILED"
                lcStepName = This.aSteps[lnStep, 1]
                lcCompensateMethod = This.aSteps[lnStep, 3]
                
                If Not Empty(lcCompensateMethod)
                    This.aSteps[lnStep, 4] = "COMPENSATING"
                    This.Log("INFO", "Compensating step: " + lcStepName)
                    
                    Try
                        If VarType(This.oExecutor) = 'O' And PemStatus(This.oExecutor, lcCompensateMethod, 5)
                            llSuccess = Evaluate("This.oExecutor." + lcCompensateMethod + "(This.oContext)")
                        ElseIf VarType(This.oContext) = 'O' And PemStatus(This.oContext, lcCompensateMethod, 5)
                            llSuccess = Evaluate("This.oContext." + lcCompensateMethod + "()")
                        EndIf
                        
                        If llSuccess
                            This.aSteps[lnStep, 4] = "COMPENSATED"
                            This.nCompensatedSteps = This.nCompensatedSteps + 1
                            This.Log("INFO", "Step compensated: " + lcStepName)
                        Else
                            This.Log("WARNING", "Compensation returned false for step: " + lcStepName)
                        EndIf
                    Catch To loEx
                        This.Log("ERROR", "Compensation failed for step: " + lcStepName + " - " + loEx.Message)
                    EndTry
                EndIf
            EndIf
        EndFor
        
        This.cState = "COMPENSATED"
        This.Log("INFO", "Compensation completed for saga: " + This.cSagaId)
        This.FireEvent("CompensationCompleted", This.cSagaId)
    EndProc
    
    *---------------------------------------------------------------------------
    * Persistă starea saga pentru recovery
    *---------------------------------------------------------------------------
    Protected Procedure PersistState
        Local lcFileName, lcContent, lnHandle, i
        
        If Not This.lPersistState Or Empty(This.cSagaId)
            Return
        EndIf
        
        lcFileName = This.cStateFilePath + This.cSagaId + ".json"
        
        * Construiește JSON manual
        lcContent = '{' + Chr(13) + Chr(10)
        lcContent = lcContent + '  "sagaId": "' + This.cSagaId + '",' + Chr(13) + Chr(10)
        lcContent = lcContent + '  "state": "' + This.cState + '",' + Chr(13) + Chr(10)
        lcContent = lcContent + '  "currentStep": ' + Transform(This.nCurrentStep) + ',' + Chr(13) + Chr(10)
        lcContent = lcContent + '  "startTime": ' + Transform(This.nStartTime) + ',' + Chr(13) + Chr(10)
        lcContent = lcContent + '  "steps": [' + Chr(13) + Chr(10)
        
        For i = 1 To This.nStepCount
            lcContent = lcContent + '    {' + Chr(13) + Chr(10)
            lcContent = lcContent + '      "name": "' + This.aSteps[i, 1] + '",' + Chr(13) + Chr(10)
            lcContent = lcContent + '      "status": "' + This.aSteps[i, 4] + '",' + Chr(13) + Chr(10)
            lcContent = lcContent + '      "retries": ' + Transform(This.aSteps[i, 5]) + ',' + Chr(13) + Chr(10)
            lcContent = lcContent + '      "error": "' + This.EscapeJson(This.aSteps[i, 6]) + '"' + Chr(13) + Chr(10)
            lcContent = lcContent + '    }' + Iif(i < This.nStepCount, ',', '') + Chr(13) + Chr(10)
        EndFor
        
        lcContent = lcContent + '  ]' + Chr(13) + Chr(10)
        lcContent = lcContent + '}'
        
        lnHandle = Fcreate(lcFileName)
        If lnHandle > 0
            Fputs(lnHandle, lcContent)
            Fclose(lnHandle)
        EndIf
    EndProc
    
    *---------------------------------------------------------------------------
    * Încarcă starea saga din fișier
    *---------------------------------------------------------------------------
    Procedure LoadState(tcSagaId)
        Local lcFileName, lcContent
        
        lcFileName = This.cStateFilePath + tcSagaId + ".json"
        
        If Not File(lcFileName)
            Return .F.
        EndIf
        
        lcContent = FileToStr(lcFileName)
        
        * Parse simplu JSON
        This.cSagaId = This.ExtractJsonValue(lcContent, "sagaId")
        This.cState = This.ExtractJsonValue(lcContent, "state")
        This.nCurrentStep = Val(This.ExtractJsonValue(lcContent, "currentStep"))
        This.nStartTime = Val(This.ExtractJsonValue(lcContent, "startTime"))
        
        This.Log("INFO", "Saga state loaded: " + tcSagaId + " (State: " + This.cState + ")")
        
        Return .T.
    EndProc
    
    *---------------------------------------------------------------------------
    * Extrage valoare din JSON
    *---------------------------------------------------------------------------
    Protected Procedure ExtractJsonValue(tcJson, tcKey)
        Local lnPos, lnStart, lnEnd, lcValue
        
        lnPos = At('"' + tcKey + '":', tcJson)
        If lnPos = 0
            Return ""
        EndIf
        
        lnStart = lnPos + Len(tcKey) + 4
        lcValue = Substr(tcJson, lnStart)
        lcValue = Alltrim(lcValue)
        
        If Left(lcValue, 1) = '"'
            lnEnd = At('"', Substr(lcValue, 2))
            Return Substr(lcValue, 2, lnEnd - 1)
        Else
            lnEnd = At(',', lcValue)
            If lnEnd = 0
                lnEnd = At('}', lcValue)
            EndIf
            Return Alltrim(Left(lcValue, lnEnd - 1))
        EndIf
    EndProc
    
    *---------------------------------------------------------------------------
    * Escape caractere speciale pentru JSON
    *---------------------------------------------------------------------------
    Protected Procedure EscapeJson(tcValue)
        Local lcResult
        lcResult = tcValue
        lcResult = Strtran(lcResult, '\', '\\')
        lcResult = Strtran(lcResult, '"', '\"')
        lcResult = Strtran(lcResult, Chr(13), '\r')
        lcResult = Strtran(lcResult, Chr(10), '\n')
        lcResult = Strtran(lcResult, Chr(9), '\t')
        Return lcResult
    EndProc
    
    *---------------------------------------------------------------------------
    * Returnează raportul de execuție
    *---------------------------------------------------------------------------
    Procedure GetReport
        Local lcReport, i
        
        lcReport = "=== Saga Report ===" + Chr(13) + Chr(10)
        lcReport = lcReport + "Saga ID: " + This.cSagaId + Chr(13) + Chr(10)
        lcReport = lcReport + "State: " + This.cState + Chr(13) + Chr(10)
        lcReport = lcReport + "Duration: " + Transform(This.nEndTime - This.nStartTime) + "s" + Chr(13) + Chr(10)
        lcReport = lcReport + "Steps: " + Transform(This.nStepCount) + Chr(13) + Chr(10)
        lcReport = lcReport + "Completed: " + Transform(This.nCompletedSteps) + Chr(13) + Chr(10)
        lcReport = lcReport + "Failed: " + Transform(This.nFailedSteps) + Chr(13) + Chr(10)
        lcReport = lcReport + "Compensated: " + Transform(This.nCompensatedSteps) + Chr(13) + Chr(10)
        lcReport = lcReport + Chr(13) + Chr(10)
        lcReport = lcReport + "Steps Detail:" + Chr(13) + Chr(10)
        
        For i = 1 To This.nStepCount
            lcReport = lcReport + "  " + Transform(i) + ". " + This.aSteps[i, 1]
            lcReport = lcReport + " [" + This.aSteps[i, 4] + "]"
            If This.aSteps[i, 5] > 0
                lcReport = lcReport + " (Retries: " + Transform(This.aSteps[i, 5]) + ")"
            EndIf
            If Not Empty(This.aSteps[i, 6])
                lcReport = lcReport + " Error: " + This.aSteps[i, 6]
            EndIf
            lcReport = lcReport + Chr(13) + Chr(10)
        EndFor
        
        Return lcReport
    EndProc
    
    *---------------------------------------------------------------------------
    * Logging intern
    *---------------------------------------------------------------------------
    Protected Procedure Log(tcLevel, tcMessage)
        If VarType(This.oLogger) = 'O'
            Do Case
                Case tcLevel = "DEBUG"
                    This.oLogger.Debug(tcMessage)
                Case tcLevel = "INFO"
                    This.oLogger.Info(tcMessage)
                Case tcLevel = "WARNING"
                    This.oLogger.Warning(tcMessage)
                Case tcLevel = "ERROR"
                    This.oLogger.LogError(tcMessage)
            EndCase
        EndIf
    EndProc
    
    *---------------------------------------------------------------------------
    * Fire event
    *---------------------------------------------------------------------------
    Protected Procedure FireEvent(tcEvent, tcData)
        If VarType(This.oEventDispatcher) = 'O'
            This.oEventDispatcher.Dispatch(tcEvent, tcData)
        EndIf
    EndProc
    
    *---------------------------------------------------------------------------
    * Cleanup fișiere state vechi
    *---------------------------------------------------------------------------
    Procedure CleanupOldStates(tnDaysOld)
        Local lnDays, laFiles[1], lnCount, i, lcFile, ldFileDate
        
        lnDays = Iif(VarType(tnDaysOld) = 'N', tnDaysOld, 7)
        
        lnCount = Adir(laFiles, This.cStateFilePath + "*.json")
        
        For i = 1 To lnCount
            lcFile = This.cStateFilePath + laFiles[i, 1]
            ldFileDate = laFiles[i, 3]
            
            If Date() - ldFileDate > lnDays
                Try
                    Delete File (lcFile)
                    This.Log("INFO", "Deleted old saga state: " + laFiles[i, 1])
                Catch
                EndTry
            EndIf
        EndFor
    EndProc
    
EndDefine


*******************************************************************************
* SagaStep - Clasă helper pentru definirea pașilor
*******************************************************************************
Define Class SagaStep As Custom
    cName = ""
    cExecuteMethod = ""
    cCompensateMethod = ""
    nMaxRetries = 3
    nTimeoutSeconds = 300
    
    Procedure Init(tcName, tcExecute, tcCompensate)
        This.cName = tcName
        This.cExecuteMethod = tcExecute
        This.cCompensateMethod = tcCompensate
    EndProc
EndDefine


*******************************************************************************
* InvoiceUploadSaga - Saga predefinită pentru upload factură
*******************************************************************************
Define Class InvoiceUploadSaga As SagaOrchestrator
    
    Procedure Init
        DoDefault()
        This.ConfigureDefaultSteps()
    EndProc
    
    Protected Procedure ConfigureDefaultSteps
        This.AddStep("ValidateInvoice", "DoValidate", "")
        This.AddStep("GenerateXml", "DoGenerateXml", "DoDeleteXml")
        This.AddStep("ValidateXml", "DoValidateXml", "")
        This.AddStep("UploadToAnaf", "DoUpload", "DoCancelUpload")
        This.AddStep("SaveReceipt", "DoSaveReceipt", "DoDeleteReceipt")
        This.AddStep("UpdateStatus", "DoUpdateStatus", "DoRevertStatus")
    EndProc
    
EndDefine
