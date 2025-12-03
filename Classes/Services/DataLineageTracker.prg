*=========================================================================
* DataLineageTracker.prg - Data Lineage Tracking Service
*=========================================================================
* Tracking transformari date pentru audit si compliance
* 
* Urmareste originea, transformarile si utilizarea datelor pentru
* compliance GDPR, audit trails si data governance
*=========================================================================

Define Class DataLineageTracker As Custom
    * Properties
    Dimension aLineages[1]
    nLineageCount = 0
    Dimension aTransformations[1]
    nTransformationCount = 0
    lTrackingEnabled = .T.
    
    * Initialize
    Procedure Init
        This.nLineageCount = 0
        This.nTransformationCount = 0
    EndProc
    
    * Track data source
    Procedure TrackSource(tcDataId, tcSourceType, tcSourceLocation, tcMetadata)
        Local loLineage
        
        If Not This.lTrackingEnabled
            Return .Null.
        EndIf
        
        loLineage = CreateObject("Empty")
        AddProperty(loLineage, "cDataId", tcDataId)
        AddProperty(loLineage, "cSourceType", tcSourceType)  && DATABASE, FILE, API, USER_INPUT
        AddProperty(loLineage, "cSourceLocation", tcSourceLocation)
        AddProperty(loLineage, "cMetadata", tcMetadata)
        AddProperty(loLineage, "nCreatedTime", Datetime())
        AddProperty(loLineage, "cCreatedBy", Sys(0))
        AddProperty(loLineage, "nTransformationCount", 0)
        
        This.nLineageCount = This.nLineageCount + 1
        Dimension This.aLineages[This.nLineageCount]
        This.aLineages[This.nLineageCount] = loLineage
        
        Return loLineage
    EndProc
    
    * Track transformation
    Procedure TrackTransformation(tcDataId, tcOperation, tcInputSchema, tcOutputSchema, tcTransformLogic)
        Local loTransform
        
        If Not This.lTrackingEnabled
            Return .Null.
        EndIf
        
        loTransform = CreateObject("Empty")
        AddProperty(loTransform, "cDataId", tcDataId)
        AddProperty(loTransform, "cOperation", tcOperation)  && FILTER, MAP, AGGREGATE, JOIN, ENRICH
        AddProperty(loTransform, "cInputSchema", tcInputSchema)
        AddProperty(loTransform, "cOutputSchema", tcOutputSchema)
        AddProperty(loTransform, "cTransformLogic", tcTransformLogic)
        AddProperty(loTransform, "nTimestamp", Datetime())
        AddProperty(loTransform, "cPerformedBy", Sys(0))
        AddProperty(loTransform, "cPurpose", "")
        
        This.nTransformationCount = This.nTransformationCount + 1
        Dimension This.aTransformations[This.nTransformationCount]
        This.aTransformations[This.nTransformationCount] = loTransform
        
        * Update lineage transformation count
        Local loLineage
        loLineage = This.GetLineage(tcDataId)
        If Not IsNull(loLineage)
            loLineage.nTransformationCount = loLineage.nTransformationCount + 1
        EndIf
        
        Return loTransform
    EndProc
    
    * Get lineage by data ID
    Procedure GetLineage(tcDataId)
        Local i
        For i = 1 To This.nLineageCount
            If This.aLineages[i].cDataId == tcDataId
                Return This.aLineages[i]
            EndIf
        EndFor
        Return .Null.
    EndProc
    
    * Get full lineage path
    Procedure GetLineagePath(tcDataId)
        Local Array laPath[1]
        Local lnCount, i, loTransform
        
        lnCount = 0
        For i = 1 To This.nTransformationCount
            loTransform = This.aTransformations[i]
            If loTransform.cDataId == tcDataId
                lnCount = lnCount + 1
                Dimension laPath[lnCount]
                laPath[lnCount] = loTransform
            EndIf
        EndFor
        
        Return @laPath
    EndProc
    
    * Track data access
    Procedure TrackAccess(tcDataId, tcAccessType, tcAccessor, tcPurpose)
        Local loAccess
        
        loAccess = CreateObject("Empty")
        AddProperty(loAccess, "cDataId", tcDataId)
        AddProperty(loAccess, "cAccessType", tcAccessType)  && READ, WRITE, DELETE, EXPORT
        AddProperty(loAccess, "cAccessor", tcAccessor)
        AddProperty(loAccess, "cPurpose", tcPurpose)
        AddProperty(loAccess, "nTimestamp", Datetime())
        
        Return loAccess
    EndProc
    
    * Generate lineage report
    Procedure GenerateReport(tcDataId)
        Local lcReport, loLineage, i, loTransform
        
        lcReport = "DATA LINEAGE REPORT" + Chr(13) + Chr(10)
        lcReport = lcReport + "Data ID: " + tcDataId + Chr(13) + Chr(10)
        lcReport = lcReport + Replicate("-", 60) + Chr(13) + Chr(10)
        
        loLineage = This.GetLineage(tcDataId)
        If Not IsNull(loLineage)
            lcReport = lcReport + "Source Type: " + loLineage.cSourceType + Chr(13) + Chr(10)
            lcReport = lcReport + "Source Location: " + loLineage.cSourceLocation + Chr(13) + Chr(10)
            lcReport = lcReport + "Created: " + Ttoc(loLineage.nCreatedTime) + Chr(13) + Chr(10)
            lcReport = lcReport + "Created By: " + loLineage.cCreatedBy + Chr(13) + Chr(10)
            lcReport = lcReport + Chr(13) + Chr(10)
        EndIf
        
        lcReport = lcReport + "TRANSFORMATIONS:" + Chr(13) + Chr(10)
        For i = 1 To This.nTransformationCount
            loTransform = This.aTransformations[i]
            If loTransform.cDataId == tcDataId
                lcReport = lcReport + Transform(i) + ". " + loTransform.cOperation + ;
                    " at " + Ttoc(loTransform.nTimestamp) + Chr(13) + Chr(10)
            EndIf
        EndFor
        
        Return lcReport
    EndProc
    
    * Get statistics
    Procedure GetStatistics()
        Local loStats
        
        loStats = CreateObject("Empty")
        AddProperty(loStats, "lTrackingEnabled", This.lTrackingEnabled)
        AddProperty(loStats, "nTotalLineages", This.nLineageCount)
        AddProperty(loStats, "nTotalTransformations", This.nTransformationCount)
        
        Return loStats
    EndProc
    
EndDefine
