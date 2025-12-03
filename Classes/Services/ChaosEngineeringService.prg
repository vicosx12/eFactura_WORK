*=========================================================================
* ChaosEngineeringService.prg - Chaos Engineering Service
*=========================================================================
* Injectare controlata de esecuri pentru testarea rezilientei sistemului
* 
* Permite simularea de erori, latency, resource exhaustion pentru
* a testa comportamentul sistemului in conditii adverse
*=========================================================================

Define Class ChaosEngineeringService As Custom
    * Properties
    lEnabled = .F.
    nFailureRate = 0.1  && 10% failure rate
    nLatencyMs = 0
    lSlowdownEnabled = .F.
    Dimension aExperiments[1]
    nExperimentCount = 0
    Dimension aResults[1]
    nResultCount = 0
    
    * Initialize
    Procedure Init
        This.nExperimentCount = 0
        This.nResultCount = 0
    EndProc
    
    * Enable chaos engineering
    Procedure Enable()
        This.lEnabled = .T.
    EndProc
    
    * Disable chaos engineering
    Procedure Disable()
        This.lEnabled = .F.
    EndProc
    
    * Define chaos experiment
    Procedure DefineExperiment(tcName, tcType, tnProbability, tnDuration)
        Local loExperiment
        
        loExperiment = CreateObject("Empty")
        AddProperty(loExperiment, "cName", tcName)
        AddProperty(loExperiment, "cType", tcType)  && FAILURE, LATENCY, RESOURCE, EXCEPTION
        AddProperty(loExperiment, "nProbability", tnProbability)
        AddProperty(loExperiment, "nDuration", tnDuration)  && seconds
        AddProperty(loExperiment, "nStartTime", Datetime())
        AddProperty(loExperiment, "nEndTime", Datetime() + tnDuration)
        AddProperty(loExperiment, "lActive", .T.)
        AddProperty(loExperiment, "nTriggeredCount", 0)
        
        This.nExperimentCount = This.nExperimentCount + 1
        Dimension This.aExperiments[This.nExperimentCount]
        This.aExperiments[This.nExperimentCount] = loExperiment
        
        Return loExperiment
    EndProc
    
    * Inject failure (returns .T. if failure should occur)
    Procedure InjectFailure(tcOperation)
        Local loExperiment, lnRandom, llShouldFail, loResult
        
        If Not This.lEnabled
            Return .F.
        EndIf
        
        * Check active experiments
        loExperiment = This.GetActiveExperiment("FAILURE")
        If IsNull(loExperiment)
            Return .F.
        EndIf
        
        * Random decision based on probability
        lnRandom = Rand()
        llShouldFail = (lnRandom < loExperiment.nProbability)
        
        If llShouldFail
            loExperiment.nTriggeredCount = loExperiment.nTriggeredCount + 1
            
            * Record result
            loResult = CreateObject("Empty")
            AddProperty(loResult, "cExperiment", loExperiment.cName)
            AddProperty(loResult, "cOperation", tcOperation)
            AddProperty(loResult, "cType", "FAILURE")
            AddProperty(loResult, "nTimestamp", Datetime())
            AddProperty(loResult, "cImpact", "Operation failed")
            
            This.RecordResult(loResult)
        EndIf
        
        Return llShouldFail
    EndProc
    
    * Inject latency (sleeps for specified duration)
    Procedure InjectLatency(tcOperation)
        Local loExperiment, lnRandom, llShouldDelay, lnDelayMs, loResult
        
        If Not This.lEnabled Or Not This.lSlowdownEnabled
            Return 0
        EndIf
        
        loExperiment = This.GetActiveExperiment("LATENCY")
        If IsNull(loExperiment)
            Return 0
        EndIf
        
        lnRandom = Rand()
        llShouldDelay = (lnRandom < loExperiment.nProbability)
        
        If llShouldDelay
            lnDelayMs = This.nLatencyMs
            loExperiment.nTriggeredCount = loExperiment.nTriggeredCount + 1
            
            * Simulate delay (VFP doesn't have real sleep, use loop)
            Local lnStart, lnTarget
            lnStart = Seconds()
            lnTarget = lnStart + (lnDelayMs / 1000)
            Do While Seconds() < lnTarget
                * Busy wait
            EndDo
            
            * Record result
            loResult = CreateObject("Empty")
            AddProperty(loResult, "cExperiment", loExperiment.cName)
            AddProperty(loResult, "cOperation", tcOperation)
            AddProperty(loResult, "cType", "LATENCY")
            AddProperty(loResult, "nTimestamp", Datetime())
            AddProperty(loResult, "cImpact", "Added " + Transform(lnDelayMs) + "ms latency")
            
            This.RecordResult(loResult)
            
            Return lnDelayMs
        EndIf
        
        Return 0
    EndProc
    
    * Simulate resource exhaustion
    Procedure SimulateResourceExhaustion(tcResource, tnPercentage)
        Local loExperiment, loResult
        
        If Not This.lEnabled
            Return .F.
        EndIf
        
        loExperiment = This.GetActiveExperiment("RESOURCE")
        If IsNull(loExperiment)
            Return .F.
        EndIf
        
        * Record simulation
        loResult = CreateObject("Empty")
        AddProperty(loResult, "cExperiment", loExperiment.cName)
        AddProperty(loResult, "cOperation", tcResource)
        AddProperty(loResult, "cType", "RESOURCE")
        AddProperty(loResult, "nTimestamp", Datetime())
        AddProperty(loResult, "cImpact", "Simulated " + Transform(tnPercentage) + "% " + tcResource + " usage")
        
        This.RecordResult(loResult)
        loExperiment.nTriggeredCount = loExperiment.nTriggeredCount + 1
        
        Return .T.
    EndProc
    
    * Inject exception
    Procedure InjectException(tcOperation, tcExceptionMessage)
        Local loExperiment, lnRandom, llShouldThrow, loResult
        
        If Not This.lEnabled
            Return .F.
        EndIf
        
        loExperiment = This.GetActiveExperiment("EXCEPTION")
        If IsNull(loExperiment)
            Return .F.
        EndIf
        
        lnRandom = Rand()
        llShouldThrow = (lnRandom < loExperiment.nProbability)
        
        If llShouldThrow
            loExperiment.nTriggeredCount = loExperiment.nTriggeredCount + 1
            
            * Record result
            loResult = CreateObject("Empty")
            AddProperty(loResult, "cExperiment", loExperiment.cName)
            AddProperty(loResult, "cOperation", tcOperation)
            AddProperty(loResult, "cType", "EXCEPTION")
            AddProperty(loResult, "nTimestamp", Datetime())
            AddProperty(loResult, "cImpact", "Exception: " + tcExceptionMessage)
            
            This.RecordResult(loResult)
            
            Error tcExceptionMessage
        EndIf
        
        Return llShouldThrow
    EndProc
    
    * Get active experiment by type
    Protected Procedure GetActiveExperiment(tcType)
        Local i, loExperiment
        
        For i = 1 To This.nExperimentCount
            loExperiment = This.aExperiments[i]
            If loExperiment.lActive And Upper(loExperiment.cType) == Upper(tcType)
                * Check if still within duration
                If Datetime() <= loExperiment.nEndTime
                    Return loExperiment
                Else
                    loExperiment.lActive = .F.
                EndIf
            EndIf
        EndFor
        
        Return .Null.
    EndProc
    
    * Record experiment result
    Protected Procedure RecordResult(toResult)
        This.nResultCount = This.nResultCount + 1
        Dimension This.aResults[This.nResultCount]
        This.aResults[This.nResultCount] = toResult
    EndProc
    
    * Get experiment results
    Procedure GetResults(tcExperimentName)
        Local i, loResult
        Local Array laResults[1]
        Local lnCount
        
        lnCount = 0
        For i = 1 To This.nResultCount
            loResult = This.aResults[i]
            If Empty(tcExperimentName) Or Upper(loResult.cExperiment) == Upper(tcExperimentName)
                lnCount = lnCount + 1
                Dimension laResults[lnCount]
                laResults[lnCount] = loResult
            EndIf
        EndFor
        
        Return @laResults
    EndProc
    
    * Get experiment statistics
    Procedure GetStatistics()
        Local loStats, i, loExp
        
        loStats = CreateObject("Empty")
        AddProperty(loStats, "lEnabled", This.lEnabled)
        AddProperty(loStats, "nTotalExperiments", This.nExperimentCount)
        AddProperty(loStats, "nActiveExperiments", 0)
        AddProperty(loStats, "nTotalInjections", This.nResultCount)
        AddProperty(loStats, "nFailureInjections", This.CountResultsByType("FAILURE"))
        AddProperty(loStats, "nLatencyInjections", This.CountResultsByType("LATENCY"))
        AddProperty(loStats, "nResourceInjections", This.CountResultsByType("RESOURCE"))
        AddProperty(loStats, "nExceptionInjections", This.CountResultsByType("EXCEPTION"))
        
        * Count active experiments
        For i = 1 To This.nExperimentCount
            loExp = This.aExperiments[i]
            If loExp.lActive And Datetime() <= loExp.nEndTime
                loStats.nActiveExperiments = loStats.nActiveExperiments + 1
            EndIf
        EndFor
        
        Return loStats
    EndProc
    
    Protected Procedure CountResultsByType(tcType)
        Local i, lnCount
        lnCount = 0
        For i = 1 To This.nResultCount
            If Upper(This.aResults[i].cType) == Upper(tcType)
                lnCount = lnCount + 1
            EndIf
        EndFor
        Return lnCount
    EndProc
    
    * Reset all experiments and results
    Procedure Reset()
        This.nExperimentCount = 0
        This.nResultCount = 0
        This.lEnabled = .F.
    EndProc
    
EndDefine
