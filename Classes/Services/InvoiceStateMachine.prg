*******************************************************************************
* InvoiceStateMachine.prg
* State Machine pentru gestiunea stărilor facturii
* 
* Funcționalități:
* - Stări predefinite pentru ciclul de viață al facturii
* - Tranziții valide între stări
* - Guards pentru validare tranziții
* - Acțiuni la intrarea/ieșirea din stări
* - Istoric tranziții
* - Persistență stare
* - Rollback la stare anterioară
*
* Stări: DRAFT → VALIDATED → XML_GENERATED → UPLOADED → CONFIRMED → ARCHIVED
*                                                    ↓
*                                                 REJECTED
*
* Exemplu utilizare:
*   loSM = CreateObject("InvoiceStateMachine")
*   loSM.Initialize("DRAFT")
*   If loSM.CanTransitionTo("VALIDATED")
*       loSM.TransitionTo("VALIDATED")
*   EndIf
*******************************************************************************

Define Class InvoiceStateMachine As Custom
    
    * Stare curentă
    cCurrentState = ""
    cPreviousState = ""
    
    * Stări definite
    Dimension aStates[1, 4]  && StateName, EntryAction, ExitAction, Description
    nStateCount = 0
    
    * Tranziții definite
    Dimension aTransitions[1, 5]  && FromState, ToState, Guard, Action, Description
    nTransitionCount = 0
    
    * Istoric tranziții
    Dimension aHistory[1, 4]  && FromState, ToState, Timestamp, User
    nHistoryCount = 0
    
    * Context pentru guards și actions
    oContext = .Null.
    
    * Observers
    Dimension aObservers[1]
    nObserverCount = 0
    
    * Logging
    oLogger = .Null.
    oAuditService = .Null.
    
    *---------------------------------------------------------------------------
    Procedure Init
        This.DefineDefaultStates()
        This.DefineDefaultTransitions()
    EndProc
    
    *---------------------------------------------------------------------------
    * Definește stările implicite pentru factură
    *---------------------------------------------------------------------------
    Protected Procedure DefineDefaultStates
        This.DefineState("DRAFT", "", "", "Factură în lucru")
        This.DefineState("VALIDATED", "", "", "Date validate")
        This.DefineState("XML_GENERATED", "", "", "XML generat")
        This.DefineState("UPLOADING", "", "", "Se încarcă la ANAF")
        This.DefineState("UPLOADED", "", "", "Încărcat la ANAF")
        This.DefineState("PROCESSING", "", "", "În procesare ANAF")
        This.DefineState("CONFIRMED", "", "", "Confirmat de ANAF")
        This.DefineState("REJECTED", "", "", "Respins de ANAF")
        This.DefineState("CANCELLED", "", "", "Anulat")
        This.DefineState("ARCHIVED", "", "", "Arhivat")
    EndProc
    
    *---------------------------------------------------------------------------
    * Definește tranzițiile implicite
    *---------------------------------------------------------------------------
    Protected Procedure DefineDefaultTransitions
        * Flux normal
        This.DefineTransition("DRAFT", "VALIDATED", "", "", "Validare date")
        This.DefineTransition("VALIDATED", "XML_GENERATED", "", "", "Generare XML")
        This.DefineTransition("XML_GENERATED", "UPLOADING", "", "", "Început upload")
        This.DefineTransition("UPLOADING", "UPLOADED", "", "", "Upload finalizat")
        This.DefineTransition("UPLOADED", "PROCESSING", "", "", "În procesare")
        This.DefineTransition("PROCESSING", "CONFIRMED", "", "", "Confirmare ANAF")
        This.DefineTransition("PROCESSING", "REJECTED", "", "", "Respingere ANAF")
        This.DefineTransition("CONFIRMED", "ARCHIVED", "", "", "Arhivare")
        
        * Rollback-uri
        This.DefineTransition("VALIDATED", "DRAFT", "", "", "Revenire la ciornă")
        This.DefineTransition("XML_GENERATED", "VALIDATED", "", "", "Regenerare")
        This.DefineTransition("REJECTED", "DRAFT", "", "", "Corectare și retrimitere")
        
        * Anulări
        This.DefineTransition("DRAFT", "CANCELLED", "", "", "Anulare ciornă")
        This.DefineTransition("VALIDATED", "CANCELLED", "", "", "Anulare înainte de upload")
        This.DefineTransition("CONFIRMED", "CANCELLED", "", "", "Stornare")
    EndProc
    
    *---------------------------------------------------------------------------
    * Definește o stare
    *---------------------------------------------------------------------------
    Procedure DefineState(tcName, tcEntryAction, tcExitAction, tcDescription)
        Local lnIndex
        
        lnIndex = This.FindStateIndex(tcName)
        If lnIndex = 0
            This.nStateCount = This.nStateCount + 1
            Dimension This.aStates[This.nStateCount, 4]
            lnIndex = This.nStateCount
        EndIf
        
        This.aStates[lnIndex, 1] = Upper(tcName)
        This.aStates[lnIndex, 2] = Nvl(tcEntryAction, "")
        This.aStates[lnIndex, 3] = Nvl(tcExitAction, "")
        This.aStates[lnIndex, 4] = Nvl(tcDescription, "")
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Definește o tranziție
    *---------------------------------------------------------------------------
    Procedure DefineTransition(tcFromState, tcToState, tcGuard, tcAction, tcDescription)
        This.nTransitionCount = This.nTransitionCount + 1
        Dimension This.aTransitions[This.nTransitionCount, 5]
        
        This.aTransitions[This.nTransitionCount, 1] = Upper(tcFromState)
        This.aTransitions[This.nTransitionCount, 2] = Upper(tcToState)
        This.aTransitions[This.nTransitionCount, 3] = Nvl(tcGuard, "")
        This.aTransitions[This.nTransitionCount, 4] = Nvl(tcAction, "")
        This.aTransitions[This.nTransitionCount, 5] = Nvl(tcDescription, "")
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Inițializează cu o stare
    *---------------------------------------------------------------------------
    Procedure Initialize(tcInitialState)
        If Empty(tcInitialState)
            tcInitialState = "DRAFT"
        EndIf
        
        If This.FindStateIndex(tcInitialState) = 0
            This.Log("ERROR", "Invalid initial state: " + tcInitialState)
            Return .F.
        EndIf
        
        This.cCurrentState = Upper(tcInitialState)
        This.cPreviousState = ""
        
        This.Log("INFO", "State machine initialized: " + This.cCurrentState)
        
        * Execută entry action
        This.ExecuteEntryAction(This.cCurrentState)
        
        Return .T.
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează contextul
    *---------------------------------------------------------------------------
    Procedure SetContext(toContext)
        This.oContext = toContext
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Verifică dacă tranziția este permisă
    *---------------------------------------------------------------------------
    Procedure CanTransitionTo(tcTargetState)
        Local lnTransitionIndex
        
        tcTargetState = Upper(tcTargetState)
        
        * Găsește tranziția
        lnTransitionIndex = This.FindTransitionIndex(This.cCurrentState, tcTargetState)
        
        If lnTransitionIndex = 0
            Return .F.
        EndIf
        
        * Execută guard dacă există
        If Not Empty(This.aTransitions[lnTransitionIndex, 3])
            Return This.ExecuteGuard(This.aTransitions[lnTransitionIndex, 3])
        EndIf
        
        Return .T.
    EndProc
    
    *---------------------------------------------------------------------------
    * Efectuează tranziția
    *---------------------------------------------------------------------------
    Procedure TransitionTo(tcTargetState, tcUser)
        Local lnTransitionIndex, llSuccess
        
        tcTargetState = Upper(tcTargetState)
        
        If Not This.CanTransitionTo(tcTargetState)
            This.Log("ERROR", "Transition not allowed: " + This.cCurrentState + " -> " + tcTargetState)
            Return .F.
        EndIf
        
        lnTransitionIndex = This.FindTransitionIndex(This.cCurrentState, tcTargetState)
        
        * Execută exit action din starea curentă
        This.ExecuteExitAction(This.cCurrentState)
        
        * Salvează starea anterioară
        This.cPreviousState = This.cCurrentState
        
        * Execută action-ul tranziției
        If Not Empty(This.aTransitions[lnTransitionIndex, 4])
            This.ExecuteTransitionAction(This.aTransitions[lnTransitionIndex, 4])
        EndIf
        
        * Schimbă starea
        This.cCurrentState = tcTargetState
        
        * Execută entry action în noua stare
        This.ExecuteEntryAction(This.cCurrentState)
        
        * Adaugă la istoric
        This.AddToHistory(This.cPreviousState, This.cCurrentState, tcUser)
        
        * Notifică observerii
        This.NotifyObservers(This.cPreviousState, This.cCurrentState)
        
        * Audit
        This.Audit("StateTransition", This.cPreviousState + " -> " + This.cCurrentState, Nvl(tcUser, ""))
        
        This.Log("INFO", "State transition: " + This.cPreviousState + " -> " + This.cCurrentState)
        
        Return .T.
    EndProc
    
    *---------------------------------------------------------------------------
    * Rollback la starea anterioară
    *---------------------------------------------------------------------------
    Procedure Rollback
        If Empty(This.cPreviousState)
            This.Log("WARNING", "No previous state to rollback to")
            Return .F.
        EndIf
        
        If This.CanTransitionTo(This.cPreviousState)
            Return This.TransitionTo(This.cPreviousState, "SYSTEM_ROLLBACK")
        EndIf
        
        This.Log("ERROR", "Cannot rollback to: " + This.cPreviousState)
        Return .F.
    EndProc
    
    *---------------------------------------------------------------------------
    * Obține starea curentă
    *---------------------------------------------------------------------------
    Procedure GetCurrentState
        Return This.cCurrentState
    EndProc
    
    *---------------------------------------------------------------------------
    * Verifică dacă este în starea specificată
    *---------------------------------------------------------------------------
    Procedure IsInState(tcState)
        Return Upper(This.cCurrentState) == Upper(tcState)
    EndProc
    
    *---------------------------------------------------------------------------
    * Verifică dacă este într-o stare finală
    *---------------------------------------------------------------------------
    Procedure IsInFinalState
        Return Inlist(This.cCurrentState, "CONFIRMED", "REJECTED", "CANCELLED", "ARCHIVED")
    EndProc
    
    *---------------------------------------------------------------------------
    * Obține tranzițiile posibile din starea curentă
    *---------------------------------------------------------------------------
    Procedure GetPossibleTransitions
        Local laResult[1], lnCount, i
        
        lnCount = 0
        
        For i = 1 To This.nTransitionCount
            If This.aTransitions[i, 1] == This.cCurrentState
                If This.CanTransitionTo(This.aTransitions[i, 2])
                    lnCount = lnCount + 1
                    Dimension laResult[lnCount]
                    laResult[lnCount] = This.aTransitions[i, 2]
                EndIf
            EndIf
        EndFor
        
        If lnCount = 0
            Return .Null.
        EndIf
        
        Return @laResult
    EndProc
    
    *---------------------------------------------------------------------------
    * Execută guard
    *---------------------------------------------------------------------------
    Protected Procedure ExecuteGuard(tcGuard)
        If Empty(tcGuard)
            Return .T.
        EndIf
        
        Try
            If VarType(This.oContext) = 'O' And PemStatus(This.oContext, tcGuard, 5)
                Return Evaluate("This.oContext." + tcGuard + "()")
            EndIf
            Return .T.
        Catch To loEx
            This.Log("ERROR", "Guard execution failed: " + tcGuard + " - " + loEx.Message)
            Return .F.
        EndTry
    EndProc
    
    *---------------------------------------------------------------------------
    * Execută action
    *---------------------------------------------------------------------------
    Protected Procedure ExecuteTransitionAction(tcAction)
        If Empty(tcAction)
            Return
        EndIf
        
        Try
            If VarType(This.oContext) = 'O' And PemStatus(This.oContext, tcAction, 5)
                Evaluate("This.oContext." + tcAction + "()")
            EndIf
        Catch To loEx
            This.Log("ERROR", "Transition action failed: " + tcAction + " - " + loEx.Message)
        EndTry
    EndProc
    
    *---------------------------------------------------------------------------
    * Execută entry action
    *---------------------------------------------------------------------------
    Protected Procedure ExecuteEntryAction(tcState)
        Local lnIndex, lcAction
        
        lnIndex = This.FindStateIndex(tcState)
        If lnIndex > 0
            lcAction = This.aStates[lnIndex, 2]
            If Not Empty(lcAction) And VarType(This.oContext) = 'O'
                Try
                    If PemStatus(This.oContext, lcAction, 5)
                        Evaluate("This.oContext." + lcAction + "()")
                    EndIf
                Catch To loEx
                    This.Log("ERROR", "Entry action failed: " + lcAction + " - " + loEx.Message)
                EndTry
            EndIf
        EndIf
    EndProc
    
    *---------------------------------------------------------------------------
    * Execută exit action
    *---------------------------------------------------------------------------
    Protected Procedure ExecuteExitAction(tcState)
        Local lnIndex, lcAction
        
        lnIndex = This.FindStateIndex(tcState)
        If lnIndex > 0
            lcAction = This.aStates[lnIndex, 3]
            If Not Empty(lcAction) And VarType(This.oContext) = 'O'
                Try
                    If PemStatus(This.oContext, lcAction, 5)
                        Evaluate("This.oContext." + lcAction + "()")
                    EndIf
                Catch To loEx
                    This.Log("ERROR", "Exit action failed: " + lcAction + " - " + loEx.Message)
                EndTry
            EndIf
        EndIf
    EndProc
    
    *---------------------------------------------------------------------------
    * Găsește indexul unei stări
    *---------------------------------------------------------------------------
    Protected Procedure FindStateIndex(tcState)
        Local i
        
        For i = 1 To This.nStateCount
            If Upper(This.aStates[i, 1]) == Upper(tcState)
                Return i
            EndIf
        EndFor
        
        Return 0
    EndProc
    
    *---------------------------------------------------------------------------
    * Găsește indexul unei tranziții
    *---------------------------------------------------------------------------
    Protected Procedure FindTransitionIndex(tcFromState, tcToState)
        Local i
        
        For i = 1 To This.nTransitionCount
            If Upper(This.aTransitions[i, 1]) == Upper(tcFromState) And ;
               Upper(This.aTransitions[i, 2]) == Upper(tcToState)
                Return i
            EndIf
        EndFor
        
        Return 0
    EndProc
    
    *---------------------------------------------------------------------------
    * Adaugă la istoric
    *---------------------------------------------------------------------------
    Protected Procedure AddToHistory(tcFromState, tcToState, tcUser)
        This.nHistoryCount = This.nHistoryCount + 1
        Dimension This.aHistory[This.nHistoryCount, 4]
        
        This.aHistory[This.nHistoryCount, 1] = tcFromState
        This.aHistory[This.nHistoryCount, 2] = tcToState
        This.aHistory[This.nHistoryCount, 3] = Datetime()
        This.aHistory[This.nHistoryCount, 4] = Nvl(tcUser, "")
    EndProc
    
    *---------------------------------------------------------------------------
    * Obține istoricul
    *---------------------------------------------------------------------------
    Procedure GetHistory
        Local laResult[1, 4], i
        
        If This.nHistoryCount = 0
            Return .Null.
        EndIf
        
        Dimension laResult[This.nHistoryCount, 4]
        
        For i = 1 To This.nHistoryCount
            laResult[i, 1] = This.aHistory[i, 1]
            laResult[i, 2] = This.aHistory[i, 2]
            laResult[i, 3] = This.aHistory[i, 3]
            laResult[i, 4] = This.aHistory[i, 4]
        EndFor
        
        Return @laResult
    EndProc
    
    *---------------------------------------------------------------------------
    * Observer pattern
    *---------------------------------------------------------------------------
    Procedure Attach(toObserver)
        This.nObserverCount = This.nObserverCount + 1
        Dimension This.aObservers[This.nObserverCount]
        This.aObservers[This.nObserverCount] = toObserver
        Return This
    EndProc
    
    Protected Procedure NotifyObservers(tcFromState, tcToState)
        Local i
        
        For i = 1 To This.nObserverCount
            If VarType(This.aObservers[i]) = 'O'
                Try
                    This.aObservers[i].OnStateChanged(tcFromState, tcToState)
                Catch
                EndTry
            EndIf
        EndFor
    EndProc
    
    *---------------------------------------------------------------------------
    * Serializare stare
    *---------------------------------------------------------------------------
    Procedure Serialize
        Local lcJson
        
        lcJson = '{'
        lcJson = lcJson + '"currentState":"' + This.cCurrentState + '",'
        lcJson = lcJson + '"previousState":"' + This.cPreviousState + '",'
        lcJson = lcJson + '"historyCount":' + Transform(This.nHistoryCount)
        lcJson = lcJson + '}'
        
        Return lcJson
    EndProc
    
    *---------------------------------------------------------------------------
    * Deserializare stare
    *---------------------------------------------------------------------------
    Procedure Deserialize(tcJson)
        * Parse simplu
        Local lnPos
        
        lnPos = At('"currentState":"', tcJson)
        If lnPos > 0
            This.cCurrentState = This.ExtractJsonValue(Substr(tcJson, lnPos))
        EndIf
        
        lnPos = At('"previousState":"', tcJson)
        If lnPos > 0
            This.cPreviousState = This.ExtractJsonValue(Substr(tcJson, lnPos))
        EndIf
        
        Return .T.
    EndProc
    
    Protected Procedure ExtractJsonValue(tcJson)
        Local lnStart, lnEnd
        
        lnStart = At('":"', tcJson) + 3
        lnEnd = At('"', Substr(tcJson, lnStart))
        
        Return Substr(tcJson, lnStart, lnEnd - 1)
    EndProc
    
    *---------------------------------------------------------------------------
    * Logging
    *---------------------------------------------------------------------------
    Procedure SetLogger(toLogger)
        This.oLogger = toLogger
    EndProc
    
    Procedure SetAuditService(toAudit)
        This.oAuditService = toAudit
    EndProc
    
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
    
    Protected Procedure Audit(tcAction, tcDetails, tcUser)
        If VarType(This.oAuditService) = 'O'
            This.oAuditService.Log("StateMachine", tcAction, This.cCurrentState, tcDetails)
        EndIf
    EndProc
    
    *---------------------------------------------------------------------------
    * Generează diagramă text
    *---------------------------------------------------------------------------
    Procedure GetDiagram
        Local lcDiagram, i
        
        lcDiagram = "=== Invoice State Machine ===" + Chr(13) + Chr(10) + Chr(13) + Chr(10)
        lcDiagram = lcDiagram + "Current State: [" + This.cCurrentState + "]" + Chr(13) + Chr(10)
        lcDiagram = lcDiagram + Chr(13) + Chr(10)
        lcDiagram = lcDiagram + "States:" + Chr(13) + Chr(10)
        
        For i = 1 To This.nStateCount
            lcDiagram = lcDiagram + "  - " + This.aStates[i, 1]
            If This.aStates[i, 1] == This.cCurrentState
                lcDiagram = lcDiagram + " <-- CURRENT"
            EndIf
            lcDiagram = lcDiagram + " (" + This.aStates[i, 4] + ")"
            lcDiagram = lcDiagram + Chr(13) + Chr(10)
        EndFor
        
        lcDiagram = lcDiagram + Chr(13) + Chr(10)
        lcDiagram = lcDiagram + "Transitions:" + Chr(13) + Chr(10)
        
        For i = 1 To This.nTransitionCount
            lcDiagram = lcDiagram + "  " + This.aTransitions[i, 1]
            lcDiagram = lcDiagram + " -> " + This.aTransitions[i, 2]
            lcDiagram = lcDiagram + " (" + This.aTransitions[i, 5] + ")"
            lcDiagram = lcDiagram + Chr(13) + Chr(10)
        EndFor
        
        Return lcDiagram
    EndProc
    
EndDefine


*******************************************************************************
* StateObserver - Clasă de bază pentru observeri
*******************************************************************************
Define Class StateObserver As Custom
    
    Procedure OnStateChanged(tcFromState, tcToState)
        * Override în subclase
    EndProc
    
EndDefine
