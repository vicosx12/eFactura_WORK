*==============================================================================
* SemanticVersioningService.prg - API/Service Version Management
*==============================================================================
* Manages semantic versioning with compatibility checks
*==============================================================================

Define Class SemanticVersioningService As Custom
    Dimension aVersions[1]
    nVersionCount = 0
    cCurrentVersion = "1.0.0"
    oLogger = .Null.
    
    Procedure Init()
        This.oLogger = CreateObject("LoggerService")
        Dimension This.aVersions[1]
    EndProc
    
    *-- Register version
    Procedure RegisterVersion(tcVersion, tcChanges, tlBreaking)
        Local loVersion
        loVersion = CreateObject("ApiVersion", tcVersion, tcChanges, tlBreaking)
        
        This.nVersionCount = This.nVersionCount + 1
        Dimension This.aVersions[This.nVersionCount]
        This.aVersions[This.nVersionCount] = loVersion
        
        This.oLogger.Info("Registered version: " + tcVersion)
        Return .T.
    EndProc
    
    *-- Check compatibility
    Procedure IsCompatible(tcRequestedVersion, tcCurrentVersion)
        Local lnReqMajor, lnReqMinor, lnCurMajor, lnCurMinor
        
        lnReqMajor = Val(Left(tcRequestedVersion, At(".", tcRequestedVersion) - 1))
        lnCurMajor = Val(Left(tcCurrentVersion, At(".", tcCurrentVersion) - 1))
        
        *-- Major version must match
        Return lnReqMajor = lnCurMajor
    EndProc
    
    *-- Get latest compatible version
    Procedure GetLatestCompatibleVersion(tcRequestedVersion)
        Local i, lnMajor, lcVersion
        lnMajor = Val(Left(tcRequestedVersion, At(".", tcRequestedVersion) - 1))
        
        lcVersion = ""
        For i = This.nVersionCount To 1 Step -1
            If This.GetMajorVersion(This.aVersions[i].cVersion) = lnMajor
                lcVersion = This.aVersions[i].cVersion
                Exit
            EndIf
        EndFor
        
        Return lcVersion
    EndProc
    
    *-- Parse version string
    Procedure ParseVersion(tcVersion)
        Local loVersion, lnPos1, lnPos2
        loVersion = CreateObject("Empty")
        
        lnPos1 = At(".", tcVersion)
        lnPos2 = At(".", tcVersion, 2)
        
        AddProperty(loVersion, "Major", Val(Left(tcVersion, lnPos1 - 1)))
        AddProperty(loVersion, "Minor", Val(Substr(tcVersion, lnPos1 + 1, lnPos2 - lnPos1 - 1)))
        AddProperty(loVersion, "Patch", Val(Substr(tcVersion, lnPos2 + 1)))
        
        Return loVersion
    EndProc
    
    Protected Procedure GetMajorVersion(tcVersion)
        Return Val(Left(tcVersion, At(".", tcVersion) - 1))
    EndProc
EndDefine

*-- API Version
Define Class ApiVersion As Custom
    cVersion = ""
    cChanges = ""
    lBreaking = .F.
    tRegistered = {}
    
    Procedure Init(tcVersion, tcChanges, tlBreaking)
        This.cVersion = tcVersion
        This.cChanges = tcChanges
        This.lBreaking = tlBreaking
        This.tRegistered = Datetime()
    EndProc
EndDefine
