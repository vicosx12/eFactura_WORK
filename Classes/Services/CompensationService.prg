*====================================================================
* CompensationService.prg - Compensation Pattern for Rollback
* Part of eFactura OOP Refactoring - v2.4 Enterprise Edition
*====================================================================
* Compensation: Undo partial operations when multi-step fails
*====================================================================

*--------------------------------------------------------------------
* ICompensatingAction - Interface for compensating actions
*--------------------------------------------------------------------
Define Class ICompensatingAction As Custom
    cActionName = ""
    cDescription = ""
    nOrder = 0
    oContext = .Null.
    
    Procedure Execute
        Error "Execute must be implemented"
    EndProc
    
    Procedure CanCompensate
        Return .T.
    EndProc
EndDefine

*--------------------------------------------------------------------
* CompensationManager
*--------------------------------------------------------------------
Define Class CompensationManager As Custom
    oActions = .Null.
    oLogger = .Null.
    oAuditService = .Null.
    lAutoCompensate = .T.
    
    Procedure Init
        This.oActions = CreateObject("Collection")
    EndProc
    
    *-- Register compensating action
    Procedure Register(toAction)
        This.oActions.Add(toAction)
        
        If VarType(This.oLogger) = 'O'
            This.oLogger.Debug("Compensation registered: " + toAction.cActionName)
        EndIf
    EndProc
    
    *-- Execute all compensations in reverse order
    Procedure Compensate
        Local lnI, loAction, loErrors
        loErrors = CreateObject("Collection")
        
        If VarType(This.oLogger) = 'O'
            This.oLogger.Warning("Starting compensation - " + ;
                Transform(This.oActions.Count) + " actions")
        EndIf
        
        * Execute in reverse order (LIFO)
        For lnI = This.oActions.Count To 1 Step -1
            loAction = This.oActions.Item(lnI)
            
            If loAction.CanCompensate()
                Try
                    loAction.Execute()
                    
                    If VarType(This.oLogger) = 'O'
                        This.oLogger.Info("Compensated: " + loAction.cActionName)
                    EndIf
                    
                    * Audit
                    If VarType(This.oAuditService) = 'O'
                        This.oAuditService.Log("COMPENSATION", loAction.cActionName, ;
                            "SUCCESS", "")
                    EndIf
                    
                Catch To loEx
                    loErrors.Add(loAction.cActionName + ": " + loEx.Message)
                    
                    If VarType(This.oLogger) = 'O'
                        This.oLogger.Error("Compensation failed: " + loAction.cActionName + ;
                            " - " + loEx.Message)
                    EndIf
                EndTry
            EndIf
        EndFor
        
        * Clear actions
        This.oActions = CreateObject("Collection")
        
        * Report errors
        If loErrors.Count > 0
            Local lcErrorMsg
            lcErrorMsg = ""
            For lnI = 1 To loErrors.Count
                lcErrorMsg = lcErrorMsg + loErrors.Item(lnI) + "; "
            EndFor
            Error "Compensation errors: " + lcErrorMsg
        EndIf
    EndProc
    
    *-- Clear without compensating
    Procedure Clear
        This.oActions = CreateObject("Collection")
    EndProc
    
    *-- Get count of registered actions
    Procedure GetCount
        Return This.oActions.Count
    EndProc
EndDefine

*====================================================================
* Compensating Actions for eFactura
*====================================================================

*--------------------------------------------------------------------
* DeleteXmlFileAction
*--------------------------------------------------------------------
Define Class DeleteXmlFileAction As ICompensatingAction
    cActionName = "DeleteXmlFile"
    cFilePath = ""
    
    Procedure Init(tcFilePath)
        This.cFilePath = tcFilePath
    EndProc
    
    Procedure Execute
        If File(This.cFilePath)
            Delete File (This.cFilePath)
        EndIf
    EndProc
    
    Procedure CanCompensate
        Return File(This.cFilePath)
    EndProc
EndDefine

*--------------------------------------------------------------------
* RevertStatusAction
*--------------------------------------------------------------------
Define Class RevertStatusAction As ICompensatingAction
    cActionName = "RevertStatus"
    nInvoiceId = 0
    cPreviousStatus = ""
    cAlias = ""
    
    Procedure Init(tnInvoiceId, tcPreviousStatus, tcAlias)
        This.nInvoiceId = tnInvoiceId
        This.cPreviousStatus = tcPreviousStatus
        This.cAlias = tcAlias
    EndProc
    
    Procedure Execute
        Local lcSql
        lcSql = "UPDATE " + This.cAlias + " SET status = '" + ;
                This.cPreviousStatus + "' WHERE id_unic = " + ;
                Transform(This.nInvoiceId)
        &lcSql
    EndProc
EndDefine

*--------------------------------------------------------------------
* ClearIdSolicitareAction
*--------------------------------------------------------------------
Define Class ClearIdSolicitareAction As ICompensatingAction
    cActionName = "ClearIdSolicitare"
    nInvoiceId = 0
    cAlias = ""
    
    Procedure Init(tnInvoiceId, tcAlias)
        This.nInvoiceId = tnInvoiceId
        This.cAlias = tcAlias
    EndProc
    
    Procedure Execute
        Local lcSql
        lcSql = "UPDATE " + This.cAlias + " SET id_solicitare = '' WHERE id_unic = " + ;
                Transform(This.nInvoiceId)
        &lcSql
    EndProc
EndDefine

*--------------------------------------------------------------------
* RevokeApiUploadAction
*--------------------------------------------------------------------
Define Class RevokeApiUploadAction As ICompensatingAction
    cActionName = "RevokeApiUpload"
    cIdSolicitare = ""
    oApiClient = .Null.
    
    Procedure Init(tcIdSolicitare, toApiClient)
        This.cIdSolicitare = tcIdSolicitare
        This.oApiClient = toApiClient
    EndProc
    
    Procedure Execute
        If VarType(This.oApiClient) = 'O' And !Empty(This.cIdSolicitare)
            * Try to cancel/revoke the upload
            This.oApiClient.Cancel(This.cIdSolicitare)
        EndIf
    EndProc
    
    Procedure CanCompensate
        Return !Empty(This.cIdSolicitare)
    EndProc
EndDefine

*--------------------------------------------------------------------
* CompensatingTransaction - Wraps operations with compensation
*--------------------------------------------------------------------
Define Class CompensatingTransaction As Custom
    oCompensationManager = .Null.
    oLogger = .Null.
    lCommitted = .F.
    
    Procedure Init
        This.oCompensationManager = CreateObject("CompensationManager")
    EndProc
    
    *-- Execute step with compensation
    Procedure ExecuteStep(toStep, toCompensation)
        Try
            * Execute the step
            toStep.Execute()
            
            * Register compensation for rollback
            This.oCompensationManager.Register(toCompensation)
            
        Catch To loEx
            * Rollback all previous steps
            This.Rollback()
            Throw loEx
        EndTry
    EndProc
    
    *-- Commit (clear compensations)
    Procedure Commit
        This.oCompensationManager.Clear()
        This.lCommitted = .T.
    EndProc
    
    *-- Rollback (execute compensations)
    Procedure Rollback
        If !This.lCommitted
            This.oCompensationManager.Compensate()
        EndIf
    EndProc
EndDefine

*====================================================================
* End of CompensationService.prg
*====================================================================
