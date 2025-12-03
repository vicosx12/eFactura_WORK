*=========================================================================
* PolicyEnforcementPoint.prg - Policy Enforcement Point
*=========================================================================
* Enforcement politici de securitate si business cu validare
* 
* Centralizeaza aplicarea politicilor de access control, validare
* business rules si compliance
*=========================================================================

Define Class PolicyEnforcementPoint As Custom
    * Properties
    Dimension aPolicies[1]
    nPolicyCount = 0
    Dimension aEnforcementResults[1]
    nResultCount = 0
    lStrictMode = .F.
    
    * Initialize
    Procedure Init
        This.nPolicyCount = 0
        This.nResultCount = 0
    EndProc
    
    * Register policy
    Procedure RegisterPolicy(tcName, tcType, tcRule, tnPriority)
        Local loPolicy
        
        loPolicy = CreateObject("Empty")
        AddProperty(loPolicy, "cName", tcName)
        AddProperty(loPolicy, "cType", tcType)  && SECURITY, BUSINESS, COMPLIANCE, DATA_QUALITY
        AddProperty(loPolicy, "cRule", tcRule)
        AddProperty(loPolicy, "nPriority", Iif(Empty(tnPriority), 100, tnPriority))
        AddProperty(loPolicy, "lEnabled", .T.)
        AddProperty(loPolicy, "nEnforcementCount", 0)
        AddProperty(loPolicy, "nViolationCount", 0)
        AddProperty(loPolicy, "nCreatedTime", Datetime())
        
        This.nPolicyCount = This.nPolicyCount + 1
        Dimension This.aPolicies[This.nPolicyCount]
        This.aPolicies[This.nPolicyCount] = loPolicy
        
        * Sort by priority (higher first)
        This.SortPoliciesByPriority()
        
        Return loPolicy
    EndProc
    
    * Enforce policies
    Procedure Enforce(tcResource, toContext)
        Local i, loPolicy, loResult, llAllowed, lcViolations
        
        llAllowed = .T.
        lcViolations = ""
        
        For i = 1 To This.nPolicyCount
            loPolicy = This.aPolicies[i]
            
            If Not loPolicy.lEnabled
                Loop
            EndIf
            
            loResult = This.EvaluatePolicy(loPolicy, tcResource, toContext)
            loPolicy.nEnforcementCount = loPolicy.nEnforcementCount + 1
            
            If Not loResult.lAllowed
                loPolicy.nViolationCount = loPolicy.nViolationCount + 1
                lcViolations = lcViolations + loPolicy.cName + ": " + loResult.cReason + "; "
                
                If This.lStrictMode
                    * In strict mode, fail on first violation
                    llAllowed = .F.
                    Exit
                Else
                    * In permissive mode, continue checking
                    llAllowed = .F.
                EndIf
            EndIf
            
            * Record result
            This.RecordEnforcement(loPolicy, loResult, tcResource)
        EndFor
        
        Local loFinalResult
        loFinalResult = CreateObject("Empty")
        AddProperty(loFinalResult, "lAllowed", llAllowed)
        AddProperty(loFinalResult, "cViolations", lcViolations)
        AddProperty(loFinalResult, "nPoliciesChecked", This.nPolicyCount)
        AddProperty(loFinalResult, "nTimestamp", Datetime())
        
        Return loFinalResult
    EndProc
    
    * Evaluate single policy
    Protected Procedure EvaluatePolicy(toPolicy, tcResource, toContext)
        Local loResult, llAllowed, lcReason
        
        llAllowed = .T.
        lcReason = ""
        
        * Simplified policy evaluation
        Do Case
            Case Upper(toPolicy.cType) == "SECURITY"
                llAllowed = This.EvaluateSecurityPolicy(toPolicy, tcResource, toContext)
                lcReason = Iif(llAllowed, "", "Security policy violation")
                
            Case Upper(toPolicy.cType) == "BUSINESS"
                llAllowed = This.EvaluateBusinessPolicy(toPolicy, tcResource, toContext)
                lcReason = Iif(llAllowed, "", "Business rule violation")
                
            Case Upper(toPolicy.cType) == "COMPLIANCE"
                llAllowed = This.EvaluateCompliancePolicy(toPolicy, tcResource, toContext)
                lcReason = Iif(llAllowed, "", "Compliance policy violation")
                
            Case Upper(toPolicy.cType) == "DATA_QUALITY"
                llAllowed = This.EvaluateDataQualityPolicy(toPolicy, tcResource, toContext)
                lcReason = Iif(llAllowed, "", "Data quality policy violation")
        EndCase
        
        loResult = CreateObject("Empty")
        AddProperty(loResult, "lAllowed", llAllowed)
        AddProperty(loResult, "cReason", lcReason)
        AddProperty(loResult, "cPolicyName", toPolicy.cName)
        
        Return loResult
    EndProc
    
    * Evaluate security policy
    Protected Procedure EvaluateSecurityPolicy(toPolicy, tcResource, toContext)
        * Simplified: check if user has required role
        If Type("toContext.cUserRole") = "C"
            Return (toPolicy.cRule $ toContext.cUserRole)
        EndIf
        Return .T.
    EndProc
    
    * Evaluate business policy
    Protected Procedure EvaluateBusinessPolicy(toPolicy, tcResource, toContext)
        * Simplified: check business rules
        If Type("toContext.nAmount") = "N"
            * Example: max amount limit
            If "MAX_AMOUNT" $ toPolicy.cRule
                Return (toContext.nAmount <= 10000)
            EndIf
        EndIf
        Return .T.
    EndProc
    
    * Evaluate compliance policy
    Protected Procedure EvaluateCompliancePolicy(toPolicy, tcResource, toContext)
        * Simplified: check compliance requirements
        If Type("toContext.lGDPRConsent") = "L"
            If "GDPR" $ toPolicy.cRule
                Return toContext.lGDPRConsent
            EndIf
        EndIf
        Return .T.
    EndProc
    
    * Evaluate data quality policy
    Protected Procedure EvaluateDataQualityPolicy(toPolicy, tcResource, toContext)
        * Simplified: check data quality
        If Type("toContext.cData") = "C"
            If "NOT_EMPTY" $ toPolicy.cRule
                Return Not Empty(toContext.cData)
            EndIf
        EndIf
        Return .T.
    EndProc
    
    * Record enforcement result
    Protected Procedure RecordEnforcement(toPolicy, toResult, tcResource)
        Local loRecord
        
        loRecord = CreateObject("Empty")
        AddProperty(loRecord, "cPolicyName", toPolicy.cName)
        AddProperty(loRecord, "cResource", tcResource)
        AddProperty(loRecord, "lAllowed", toResult.lAllowed)
        AddProperty(loRecord, "cReason", toResult.cReason)
        AddProperty(loRecord, "nTimestamp", Datetime())
        
        This.nResultCount = This.nResultCount + 1
        Dimension This.aEnforcementResults[This.nResultCount]
        This.aEnforcementResults[This.nResultCount] = loRecord
    EndProc
    
    * Sort policies by priority
    Protected Procedure SortPoliciesByPriority()
        * Simple bubble sort by priority (descending)
        Local i, j, loTemp
        
        For i = 1 To This.nPolicyCount - 1
            For j = i + 1 To This.nPolicyCount
                If This.aPolicies[i].nPriority < This.aPolicies[j].nPriority
                    loTemp = This.aPolicies[i]
                    This.aPolicies[i] = This.aPolicies[j]
                    This.aPolicies[j] = loTemp
                EndIf
            EndFor
        EndFor
    EndProc
    
    * Get policy by name
    Procedure GetPolicy(tcName)
        Local i
        For i = 1 To This.nPolicyCount
            If Upper(This.aPolicies[i].cName) == Upper(tcName)
                Return This.aPolicies[i]
            EndIf
        EndFor
        Return .Null.
    EndProc
    
    * Get enforcement history
    Procedure GetEnforcementHistory(tcResource, tnLast)
        Local i, loRecord
        Local Array laHistory[1]
        Local lnCount
        
        lnCount = 0
        For i = This.nResultCount To Max(1, This.nResultCount - tnLast + 1) Step -1
            loRecord = This.aEnforcementResults[i]
            If Empty(tcResource) Or loRecord.cResource == tcResource
                lnCount = lnCount + 1
                Dimension laHistory[lnCount]
                laHistory[lnCount] = loRecord
            EndIf
        EndFor
        
        Return @laHistory
    EndProc
    
    * Get statistics
    Procedure GetStatistics()
        Local loStats, i, loPolicy
        
        loStats = CreateObject("Empty")
        AddProperty(loStats, "nTotalPolicies", This.nPolicyCount)
        AddProperty(loStats, "nEnabledPolicies", 0)
        AddProperty(loStats, "nTotalEnforcements", This.nResultCount)
        AddProperty(loStats, "nTotalViolations", 0)
        AddProperty(loStats, "lStrictMode", This.lStrictMode)
        
        For i = 1 To This.nPolicyCount
            loPolicy = This.aPolicies[i]
            If loPolicy.lEnabled
                loStats.nEnabledPolicies = loStats.nEnabledPolicies + 1
            EndIf
            loStats.nTotalViolations = loStats.nTotalViolations + loPolicy.nViolationCount
        EndFor
        
        Return loStats
    EndProc
    
EndDefine
