*====================================================================
* AuditService - Audit Trail Service
* 
* Records all actions for compliance and debugging:
* - Who performed action
* - When action occurred
* - What was changed (before/after values)
* - Context (IP, workstation, etc.)
*
* Visual FoxPro 9 SP2 Compatible
*====================================================================

Define Class AuditService As Custom
    
    * Configuration
    cAuditTable = "Audit_Trail"
    lEnabled = .T.
    lLogToFile = .T.
    cLogPath = ""
    nRetentionDays = 365
    
    * Current session info
    cSessionId = ""
    cUserId = ""
    cUserName = ""
    cWorkstation = ""
    cApplication = "eFactura"
    
    * Action types
    cActionCreate = "CREATE"
    cActionUpdate = "UPDATE"
    cActionDelete = "DELETE"
    cActionView = "VIEW"
    cActionUpload = "UPLOAD"
    cActionDownload = "DOWNLOAD"
    cActionLogin = "LOGIN"
    cActionLogout = "LOGOUT"
    cActionError = "ERROR"
    
    * Logger reference
    oLogger = .Null.
    
    *----------------------------------------------------------------
    * Init
    *----------------------------------------------------------------
    Procedure Init
        This.oLogger = CreateObject("LoggerService")
        This.cSessionId = Sys(2015)
        This.cWorkstation = Sys(0)
        This.cLogPath = AddBs(Sys(2023)) + "eFactura_Audit\"
        
        * Create log directory if needed
        If This.lLogToFile And Not Directory(This.cLogPath)
            Mkdir (This.cLogPath)
        EndIf
        
        * Ensure audit table exists
        This.EnsureAuditTable()
    EndProc
    
    *----------------------------------------------------------------
    * SetUser - Set current user context
    *----------------------------------------------------------------
    Procedure SetUser(tcUserId, tcUserName)
        This.cUserId = tcUserId
        This.cUserName = tcUserName
    EndProc
    
    *----------------------------------------------------------------
    * LogAction - Main audit logging method
    *----------------------------------------------------------------
    Procedure LogAction(tcAction, tcEntityType, tcEntityId, tcDescription, tcOldValue, tcNewValue)
        Local loEntry
        
        If Not This.lEnabled
            Return .T.
        EndIf
        
        * Create audit entry
        loEntry = CreateObject("Empty")
        AddProperty(loEntry, "AuditId", Sys(2015))
        AddProperty(loEntry, "SessionId", This.cSessionId)
        AddProperty(loEntry, "Timestamp", DateTime())
        AddProperty(loEntry, "UserId", This.cUserId)
        AddProperty(loEntry, "UserName", This.cUserName)
        AddProperty(loEntry, "Workstation", This.cWorkstation)
        AddProperty(loEntry, "Application", This.cApplication)
        AddProperty(loEntry, "Action", tcAction)
        AddProperty(loEntry, "EntityType", tcEntityType)
        AddProperty(loEntry, "EntityId", Transform(tcEntityId))
        AddProperty(loEntry, "Description", tcDescription)
        AddProperty(loEntry, "OldValue", Evl(tcOldValue, ""))
        AddProperty(loEntry, "NewValue", Evl(tcNewValue, ""))
        AddProperty(loEntry, "IpAddress", This.GetIpAddress())
        
        * Save to table
        This.SaveToTable(loEntry)
        
        * Save to file
        If This.lLogToFile
            This.SaveToFile(loEntry)
        EndIf
        
        Return .T.
    EndProc
    
    *----------------------------------------------------------------
    * LogCreate - Log entity creation
    *----------------------------------------------------------------
    Procedure LogCreate(tcEntityType, tcEntityId, tcDescription, tcNewValue)
        Return This.LogAction(This.cActionCreate, tcEntityType, tcEntityId, tcDescription, "", tcNewValue)
    EndProc
    
    *----------------------------------------------------------------
    * LogUpdate - Log entity update with before/after values
    *----------------------------------------------------------------
    Procedure LogUpdate(tcEntityType, tcEntityId, tcDescription, tcOldValue, tcNewValue)
        Return This.LogAction(This.cActionUpdate, tcEntityType, tcEntityId, tcDescription, tcOldValue, tcNewValue)
    EndProc
    
    *----------------------------------------------------------------
    * LogDelete - Log entity deletion
    *----------------------------------------------------------------
    Procedure LogDelete(tcEntityType, tcEntityId, tcDescription, tcOldValue)
        Return This.LogAction(This.cActionDelete, tcEntityType, tcEntityId, tcDescription, tcOldValue, "")
    EndProc
    
    *----------------------------------------------------------------
    * LogView - Log entity view
    *----------------------------------------------------------------
    Procedure LogView(tcEntityType, tcEntityId, tcDescription)
        Return This.LogAction(This.cActionView, tcEntityType, tcEntityId, tcDescription, "", "")
    EndProc
    
    *----------------------------------------------------------------
    * LogUpload - Log upload action
    *----------------------------------------------------------------
    Procedure LogUpload(tcEntityType, tcEntityId, tcDescription, tcResponse)
        Return This.LogAction(This.cActionUpload, tcEntityType, tcEntityId, tcDescription, "", tcResponse)
    EndProc
    
    *----------------------------------------------------------------
    * LogError - Log error occurrence
    *----------------------------------------------------------------
    Procedure LogError(tcEntityType, tcEntityId, tcDescription, tcErrorDetails)
        Return This.LogAction(This.cActionError, tcEntityType, tcEntityId, tcDescription, "", tcErrorDetails)
    EndProc
    
    *----------------------------------------------------------------
    * LogInvoiceChange - Log invoice specific changes
    *----------------------------------------------------------------
    Procedure LogInvoiceChange(tnInvoiceId, tcAction, tcField, tcOldValue, tcNewValue)
        Local lcDescription
        
        lcDescription = "Factură #" + Transform(tnInvoiceId) + " - " + tcField
        
        Return This.LogAction(tcAction, "Invoice", tnInvoiceId, lcDescription, tcOldValue, tcNewValue)
    EndProc
    
    *----------------------------------------------------------------
    * EnsureAuditTable - Create audit table if not exists
    *----------------------------------------------------------------
    Protected Procedure EnsureAuditTable
        Local lcTablePath
        
        lcTablePath = This.cAuditTable + ".dbf"
        
        If Not File(lcTablePath)
            Try
                Create Table (lcTablePath) ;
                    (AuditId C(20), ;
                     SessionId C(20), ;
                     Timestamp T, ;
                     UserId C(50), ;
                     UserName C(100), ;
                     Workstation C(100), ;
                     Application C(50), ;
                     Action C(20), ;
                     EntityType C(50), ;
                     EntityId C(50), ;
                     Description M, ;
                     OldValue M, ;
                     NewValue M, ;
                     IpAddress C(50))
                
                Use
                
                * Create indexes
                Use (lcTablePath)
                Index On Timestamp Tag Timestamp
                Index On UserId Tag UserId
                Index On EntityType + EntityId Tag Entity
                Index On Action Tag Action
                Use
            Catch
                This.oLogger.LogError("Nu s-a putut crea tabela audit: " + Message())
            EndTry
        EndIf
    EndProc
    
    *----------------------------------------------------------------
    * SaveToTable - Save audit entry to DBF table
    *----------------------------------------------------------------
    Protected Procedure SaveToTable(toEntry)
        Local llWasUsed, lcAlias
        
        lcAlias = This.cAuditTable
        llWasUsed = Used(lcAlias)
        
        Try
            If Not llWasUsed
                Use (This.cAuditTable + ".dbf") In 0 Alias (lcAlias)
            EndIf
            
            Select (lcAlias)
            
            Insert Into (lcAlias) ;
                (AuditId, SessionId, Timestamp, UserId, UserName, ;
                 Workstation, Application, Action, EntityType, EntityId, ;
                 Description, OldValue, NewValue, IpAddress) ;
            Values ;
                (toEntry.AuditId, toEntry.SessionId, toEntry.Timestamp, ;
                 toEntry.UserId, toEntry.UserName, toEntry.Workstation, ;
                 toEntry.Application, toEntry.Action, toEntry.EntityType, ;
                 toEntry.EntityId, toEntry.Description, toEntry.OldValue, ;
                 toEntry.NewValue, toEntry.IpAddress)
            
            If Not llWasUsed
                Use In (lcAlias)
            EndIf
        Catch
            This.oLogger.LogError("Eroare salvare audit: " + Message())
        EndTry
    EndProc
    
    *----------------------------------------------------------------
    * SaveToFile - Save audit entry to daily log file
    *----------------------------------------------------------------
    Protected Procedure SaveToFile(toEntry)
        Local lcFileName, lcContent
        
        lcFileName = This.cLogPath + "audit_" + Dtos(Date()) + ".log"
        
        lcContent = Ttoc(toEntry.Timestamp) + " | "
        lcContent = lcContent + toEntry.UserId + " | "
        lcContent = lcContent + toEntry.Action + " | "
        lcContent = lcContent + toEntry.EntityType + " | "
        lcContent = lcContent + toEntry.EntityId + " | "
        lcContent = lcContent + toEntry.Description + Chr(13) + Chr(10)
        
        Try
            StrToFile(lcContent, lcFileName, .T.)  && Append mode
        Catch
            * Silent fail for file logging
        EndTry
    EndProc
    
    *----------------------------------------------------------------
    * GetIpAddress - Get local IP address
    *----------------------------------------------------------------
    Protected Procedure GetIpAddress
        Local lcIp
        
        Try
            * Try to get IP from WMI
            lcIp = Sys(0)
            lcIp = GetWordNum(lcIp, 2, "#")
        Catch
            lcIp = "Unknown"
        EndTry
        
        Return lcIp
    EndProc
    
    *----------------------------------------------------------------
    * Query - Query audit trail
    *----------------------------------------------------------------
    Procedure Query(tcEntityType, tcEntityId, tdFrom, tdTo, tcAction)
        Local lcWhere, lcSql
        
        If Not File(This.cAuditTable + ".dbf")
            Return .F.
        EndIf
        
        lcWhere = ".T."
        
        If Not Empty(tcEntityType)
            lcWhere = lcWhere + " And EntityType = '" + tcEntityType + "'"
        EndIf
        
        If Not Empty(tcEntityId)
            lcWhere = lcWhere + " And EntityId = '" + Transform(tcEntityId) + "'"
        EndIf
        
        If Not Empty(tdFrom)
            lcWhere = lcWhere + " And Timestamp >= {^" + Ttoc(tdFrom) + "}"
        EndIf
        
        If Not Empty(tdTo)
            lcWhere = lcWhere + " And Timestamp <= {^" + Ttoc(tdTo) + "}"
        EndIf
        
        If Not Empty(tcAction)
            lcWhere = lcWhere + " And Action = '" + tcAction + "'"
        EndIf
        
        lcSql = "Select * From " + This.cAuditTable + " Where " + lcWhere + " Order By Timestamp Desc Into Cursor AuditResults"
        
        &lcSql
        
        Return _Tally > 0
    EndProc
    
    *----------------------------------------------------------------
    * GetEntityHistory - Get complete history for an entity
    *----------------------------------------------------------------
    Procedure GetEntityHistory(tcEntityType, tcEntityId)
        Return This.Query(tcEntityType, tcEntityId, .Null., .Null., "")
    EndProc
    
    *----------------------------------------------------------------
    * Cleanup - Remove old audit records
    *----------------------------------------------------------------
    Procedure Cleanup
        Local ldCutoff, lnDeleted
        
        ldCutoff = Date() - This.nRetentionDays
        
        If Not File(This.cAuditTable + ".dbf")
            Return 0
        EndIf
        
        Try
            Use (This.cAuditTable + ".dbf") Exclusive
            Delete All For Ttod(Timestamp) < ldCutoff
            lnDeleted = _Tally
            Pack
            Use
        Catch
            lnDeleted = 0
            This.oLogger.LogError("Eroare cleanup audit: " + Message())
        EndTry
        
        Return lnDeleted
    EndProc
    
    *----------------------------------------------------------------
    * ExportToJson - Export audit trail to JSON
    *----------------------------------------------------------------
    Procedure ExportToJson(tcEntityType, tcEntityId, tdFrom, tdTo)
        Local lcJson, lnI
        
        If Not This.Query(tcEntityType, tcEntityId, tdFrom, tdTo, "")
            Return "[]"
        EndIf
        
        lcJson = "["
        
        Select AuditResults
        Scan
            If Recno() > 1
                lcJson = lcJson + ","
            EndIf
            
            lcJson = lcJson + '{"auditId":"' + Alltrim(AuditId) + '",'
            lcJson = lcJson + '"timestamp":"' + Ttoc(Timestamp) + '",'
            lcJson = lcJson + '"userId":"' + Alltrim(UserId) + '",'
            lcJson = lcJson + '"userName":"' + Alltrim(UserName) + '",'
            lcJson = lcJson + '"action":"' + Alltrim(Action) + '",'
            lcJson = lcJson + '"entityType":"' + Alltrim(EntityType) + '",'
            lcJson = lcJson + '"entityId":"' + Alltrim(EntityId) + '",'
            lcJson = lcJson + '"description":"' + This.EscapeJson(Description) + '"}'
        EndScan
        
        Use In AuditResults
        
        lcJson = lcJson + "]"
        
        Return lcJson
    EndProc
    
    *----------------------------------------------------------------
    * EscapeJson - Escape string for JSON
    *----------------------------------------------------------------
    Protected Procedure EscapeJson(tcString)
        Local lcResult
        
        lcResult = Alltrim(tcString)
        lcResult = StrTran(lcResult, '\', '\\')
        lcResult = StrTran(lcResult, '"', '\"')
        lcResult = StrTran(lcResult, Chr(13), '\r')
        lcResult = StrTran(lcResult, Chr(10), '\n')
        
        Return lcResult
    EndProc

EndDefine
