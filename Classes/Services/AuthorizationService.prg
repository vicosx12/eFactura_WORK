*====================================================================
* AuthorizationService.prg - Policy-Based Authorization
* Part of eFactura OOP Refactoring - v2.4 Enterprise Edition
*====================================================================
* Authorization: Role-based and policy-based access control
*====================================================================

*--------------------------------------------------------------------
* IAuthorizationPolicy - Policy interface
*--------------------------------------------------------------------
Define Class IAuthorizationPolicy As Custom
    cPolicyName = ""
    cDescription = ""
    
    Procedure Evaluate(toContext)
        Error "Evaluate must be implemented"
    EndProc
EndDefine

*--------------------------------------------------------------------
* AuthorizationContext
*--------------------------------------------------------------------
Define Class AuthorizationContext As Custom
    cUserId = ""
    cUserName = ""
    oRoles = .Null.
    oPermissions = .Null.
    cResource = ""
    cAction = ""
    oResourceData = .Null.
    cTenantId = ""
    
    Procedure Init
        This.oRoles = CreateObject("Collection")
        This.oPermissions = CreateObject("Collection")
    EndProc
    
    Procedure HasRole(tcRole)
        Local lnI
        For lnI = 1 To This.oRoles.Count
            If Upper(This.oRoles.Item(lnI)) = Upper(tcRole)
                Return .T.
            EndIf
        EndFor
        Return .F.
    EndProc
    
    Procedure HasPermission(tcPermission)
        Local lnI
        For lnI = 1 To This.oPermissions.Count
            If Upper(This.oPermissions.Item(lnI)) = Upper(tcPermission)
                Return .T.
            EndIf
        EndFor
        Return .F.
    EndProc
    
    Procedure HasAnyRole(tcRoles)
        Local laRoles, lnI
        Dimension laRoles[1]
        lnI = Alines(laRoles, tcRoles, 1, ",")
        
        Local lnJ
        For lnJ = 1 To lnI
            If This.HasRole(AllTrim(laRoles[lnJ]))
                Return .T.
            EndIf
        EndFor
        Return .F.
    EndProc
EndDefine

*--------------------------------------------------------------------
* AuthorizationResult
*--------------------------------------------------------------------
Define Class AuthorizationResult As Custom
    lAuthorized = .F.
    cReason = ""
    cFailedPolicy = ""
    
    Procedure Succeed
        This.lAuthorized = .T.
        This.cReason = ""
    EndProc
    
    Procedure Fail(tcReason, tcPolicyName)
        This.lAuthorized = .F.
        This.cReason = tcReason
        This.cFailedPolicy = tcPolicyName
    EndProc
EndDefine

*--------------------------------------------------------------------
* AuthorizationService
*--------------------------------------------------------------------
Define Class AuthorizationService As Custom
    oPolicies = .Null.
    oRolePermissions = .Null.
    oLogger = .Null.
    oAuditService = .Null.
    lEnabled = .T.
    
    Procedure Init
        This.oPolicies = CreateObject("Collection")
        This.oRolePermissions = CreateObject("Collection")
        This.RegisterDefaultPolicies()
    EndProc
    
    *-- Register default policies
    Protected Procedure RegisterDefaultPolicies
        * Admin policy
        This.RegisterPolicy(CreateObject("AdminOnlyPolicy"))
        
        * Owner policy
        This.RegisterPolicy(CreateObject("ResourceOwnerPolicy"))
        
        * Tenant policy
        This.RegisterPolicy(CreateObject("SameTenantPolicy"))
    EndProc
    
    *-- Register policy
    Procedure RegisterPolicy(toPolicy)
        This.oPolicies.Add(toPolicy, toPolicy.cPolicyName)
    EndProc
    
    *-- Register role permissions
    Procedure RegisterRolePermissions(tcRole, tcPermissions)
        Local loPerms
        loPerms = CreateObject("Collection")
        
        Local laPerms, lnI
        Dimension laPerms[1]
        lnI = Alines(laPerms, tcPermissions, 1, ",")
        
        Local lnJ
        For lnJ = 1 To lnI
            loPerms.Add(AllTrim(laPerms[lnJ]))
        EndFor
        
        This.oRolePermissions.Add(loPerms, tcRole)
    EndProc
    
    *-- Get permissions for user based on roles
    Procedure GetPermissionsForRoles(toContext)
        Local lnI, loRolePerms, lnJ
        
        For lnI = 1 To toContext.oRoles.Count
            Try
                loRolePerms = This.oRolePermissions.Item(toContext.oRoles.Item(lnI))
                For lnJ = 1 To loRolePerms.Count
                    If !toContext.HasPermission(loRolePerms.Item(lnJ))
                        toContext.oPermissions.Add(loRolePerms.Item(lnJ))
                    EndIf
                EndFor
            Catch
            EndTry
        EndFor
    EndProc
    
    *-- Authorize using policy
    Procedure AuthorizePolicy(tcPolicyName, toContext)
        If !This.lEnabled
            Local loResult
            loResult = CreateObject("AuthorizationResult")
            loResult.Succeed()
            Return loResult
        EndIf
        
        Local loPolicy, loResult
        
        Try
            loPolicy = This.oPolicies.Item(tcPolicyName)
        Catch
            loResult = CreateObject("AuthorizationResult")
            loResult.Fail("Policy not found: " + tcPolicyName, tcPolicyName)
            Return loResult
        EndTry
        
        loResult = loPolicy.Evaluate(toContext)
        
        * Audit
        If VarType(This.oAuditService) = 'O'
            Local lcStatus
            lcStatus = Iif(loResult.lAuthorized, "ALLOWED", "DENIED")
            This.oAuditService.Log("AUTHORIZATION", tcPolicyName, ;
                lcStatus, toContext.cUserId + " - " + toContext.cResource)
        EndIf
        
        Return loResult
    EndProc
    
    *-- Authorize using permission
    Procedure AuthorizePermission(tcPermission, toContext)
        If !This.lEnabled
            Local loResult
            loResult = CreateObject("AuthorizationResult")
            loResult.Succeed()
            Return loResult
        EndIf
        
        * Expand permissions from roles
        This.GetPermissionsForRoles(toContext)
        
        Local loResult
        loResult = CreateObject("AuthorizationResult")
        
        If toContext.HasPermission(tcPermission)
            loResult.Succeed()
        Else
            loResult.Fail("Missing permission: " + tcPermission, "PermissionCheck")
        EndIf
        
        Return loResult
    EndProc
    
    *-- Authorize using role
    Procedure AuthorizeRole(tcRole, toContext)
        Local loResult
        loResult = CreateObject("AuthorizationResult")
        
        If toContext.HasRole(tcRole)
            loResult.Succeed()
        Else
            loResult.Fail("Missing role: " + tcRole, "RoleCheck")
        EndIf
        
        Return loResult
    EndProc
    
    *-- Check if authorized (throws if not)
    Procedure Require(tcPolicyName, toContext)
        Local loResult
        loResult = This.AuthorizePolicy(tcPolicyName, toContext)
        
        If !loResult.lAuthorized
            Error "Unauthorized: " + loResult.cReason
        EndIf
    EndProc
EndDefine

*====================================================================
* Built-in Policies
*====================================================================

*--------------------------------------------------------------------
* AdminOnlyPolicy
*--------------------------------------------------------------------
Define Class AdminOnlyPolicy As IAuthorizationPolicy
    cPolicyName = "AdminOnly"
    cDescription = "Allows only administrators"
    
    Procedure Evaluate(toContext)
        Local loResult
        loResult = CreateObject("AuthorizationResult")
        
        If toContext.HasRole("Admin") Or toContext.HasRole("Administrator")
            loResult.Succeed()
        Else
            loResult.Fail("Administrator role required", This.cPolicyName)
        EndIf
        
        Return loResult
    EndProc
EndDefine

*--------------------------------------------------------------------
* ResourceOwnerPolicy
*--------------------------------------------------------------------
Define Class ResourceOwnerPolicy As IAuthorizationPolicy
    cPolicyName = "ResourceOwner"
    cDescription = "User must own the resource"
    
    Procedure Evaluate(toContext)
        Local loResult
        loResult = CreateObject("AuthorizationResult")
        
        * Check if user is owner of resource
        If VarType(toContext.oResourceData) = 'O'
            If PemStatus(toContext.oResourceData, "cOwnerId", 5)
                If toContext.oResourceData.cOwnerId = toContext.cUserId
                    loResult.Succeed()
                    Return loResult
                EndIf
            EndIf
            
            If PemStatus(toContext.oResourceData, "cCreatedBy", 5)
                If toContext.oResourceData.cCreatedBy = toContext.cUserId
                    loResult.Succeed()
                    Return loResult
                EndIf
            EndIf
        EndIf
        
        * Admins can access any resource
        If toContext.HasRole("Admin")
            loResult.Succeed()
            Return loResult
        EndIf
        
        loResult.Fail("User is not the resource owner", This.cPolicyName)
        Return loResult
    EndProc
EndDefine

*--------------------------------------------------------------------
* SameTenantPolicy
*--------------------------------------------------------------------
Define Class SameTenantPolicy As IAuthorizationPolicy
    cPolicyName = "SameTenant"
    cDescription = "User must be in same tenant as resource"
    
    Procedure Evaluate(toContext)
        Local loResult
        loResult = CreateObject("AuthorizationResult")
        
        If Empty(toContext.cTenantId)
            * No tenant restriction
            loResult.Succeed()
            Return loResult
        EndIf
        
        If VarType(toContext.oResourceData) = 'O'
            If PemStatus(toContext.oResourceData, "cTenantId", 5)
                If toContext.oResourceData.cTenantId = toContext.cTenantId
                    loResult.Succeed()
                    Return loResult
                EndIf
            EndIf
        EndIf
        
        loResult.Fail("Resource belongs to different tenant", This.cPolicyName)
        Return loResult
    EndProc
EndDefine

*--------------------------------------------------------------------
* InvoicePermissionPolicy
*--------------------------------------------------------------------
Define Class InvoicePermissionPolicy As IAuthorizationPolicy
    cPolicyName = "InvoicePermission"
    cDescription = "Check invoice-specific permissions"
    
    Procedure Evaluate(toContext)
        Local loResult, lcRequiredPerm
        loResult = CreateObject("AuthorizationResult")
        
        * Map action to permission
        Do Case
            Case toContext.cAction = "VIEW"
                lcRequiredPerm = "invoice.view"
            Case toContext.cAction = "CREATE"
                lcRequiredPerm = "invoice.create"
            Case toContext.cAction = "UPLOAD"
                lcRequiredPerm = "invoice.upload"
            Case toContext.cAction = "CANCEL"
                lcRequiredPerm = "invoice.cancel"
            Case toContext.cAction = "DELETE"
                lcRequiredPerm = "invoice.delete"
            Otherwise
                lcRequiredPerm = "invoice." + Lower(toContext.cAction)
        EndCase
        
        If toContext.HasPermission(lcRequiredPerm) Or toContext.HasRole("Admin")
            loResult.Succeed()
        Else
            loResult.Fail("Missing permission: " + lcRequiredPerm, This.cPolicyName)
        EndIf
        
        Return loResult
    EndProc
EndDefine

*====================================================================
* End of AuthorizationService.prg
*====================================================================
