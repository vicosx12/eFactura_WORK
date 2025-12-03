*=========================================================================
* AIPatternRecognizer.prg - AI-like Pattern Recognition Service
*=========================================================================
* Pattern recognition cu machine learning-like scoring pentru detectare anomalii
* 
* Detecteaza pattern-uri in date si identifica anomalii folosind scoring
* statistic si reguli adaptive
*=========================================================================

Define Class AIPatternRecognizer As Custom
    * Properties
    Dimension aPatterns[1]
    nPatternCount = 0
    Dimension aAnomalies[1]
    nAnomalyCount = 0
    nMinConfidence = 0.7  && Confidenta minima pentru pattern valid
    nAnomalyThreshold = 2.5  && Threshold pentru deviatie standard
    
    * Initialize
    Procedure Init
        This.nPatternCount = 0
        This.nAnomalyCount = 0
    EndProc
    
    * Learn pattern from historical data
    Procedure LearnPattern(tcPatternName, taData)
        Local loPattern, i, lnSum, lnMean, lnVariance, lnStdDev
        
        loPattern = CreateObject("Empty")
        AddProperty(loPattern, "cName", tcPatternName)
        AddProperty(loPattern, "nDataPoints", Alen(taData))
        AddProperty(loPattern, "nTimestamp", Datetime())
        
        * Calculate statistics
        lnSum = 0
        For i = 1 To Alen(taData)
            lnSum = lnSum + taData[i]
        EndFor
        lnMean = lnSum / Alen(taData)
        
        * Calculate variance and standard deviation
        lnVariance = 0
        For i = 1 To Alen(taData)
            lnVariance = lnVariance + (taData[i] - lnMean) ^ 2
        EndFor
        lnVariance = lnVariance / Alen(taData)
        lnStdDev = Sqrt(lnVariance)
        
        AddProperty(loPattern, "nMean", lnMean)
        AddProperty(loPattern, "nStdDev", lnStdDev)
        AddProperty(loPattern, "nMin", This.GetMin(taData))
        AddProperty(loPattern, "nMax", This.GetMax(taData))
        AddProperty(loPattern, "nConfidence", 1.0)
        
        * Store pattern
        This.nPatternCount = This.nPatternCount + 1
        Dimension This.aPatterns[This.nPatternCount]
        This.aPatterns[This.nPatternCount] = loPattern
        
        Return loPattern
    EndProc
    
    * Detect anomaly in new data point
    Procedure DetectAnomaly(tcPatternName, tnValue)
        Local loPattern, lnZScore, llIsAnomaly, loAnomaly
        
        loPattern = This.GetPattern(tcPatternName)
        If IsNull(loPattern)
            Return .F.
        EndIf
        
        * Calculate Z-Score
        If loPattern.nStdDev > 0
            lnZScore = Abs((tnValue - loPattern.nMean) / loPattern.nStdDev)
        Else
            lnZScore = 0
        EndIf
        
        llIsAnomaly = (lnZScore > This.nAnomalyThreshold)
        
        If llIsAnomaly
            * Record anomaly
            loAnomaly = CreateObject("Empty")
            AddProperty(loAnomaly, "cPatternName", tcPatternName)
            AddProperty(loAnomaly, "nValue", tnValue)
            AddProperty(loAnomaly, "nZScore", lnZScore)
            AddProperty(loAnomaly, "nExpectedMean", loPattern.nMean)
            AddProperty(loAnomaly, "nDeviation", tnValue - loPattern.nMean)
            AddProperty(loAnomaly, "nTimestamp", Datetime())
            AddProperty(loAnomaly, "cSeverity", Iif(lnZScore > 4, "CRITICAL", ;
                Iif(lnZScore > 3, "HIGH", "MEDIUM")))
            
            This.nAnomalyCount = This.nAnomalyCount + 1
            Dimension This.aAnomalies[This.nAnomalyCount]
            This.aAnomalies[This.nAnomalyCount] = loAnomaly
        EndIf
        
        Return llIsAnomaly
    EndProc
    
    * Predict next value based on pattern
    Procedure PredictNextValue(tcPatternName)
        Local loPattern, lnPredicted, lnConfidence
        
        loPattern = This.GetPattern(tcPatternName)
        If IsNull(loPattern)
            Return .Null.
        EndIf
        
        * Simple prediction: return mean with confidence range
        lnPredicted = loPattern.nMean
        lnConfidence = loPattern.nConfidence
        
        Local loResult
        loResult = CreateObject("Empty")
        AddProperty(loResult, "nValue", lnPredicted)
        AddProperty(loResult, "nConfidence", lnConfidence)
        AddProperty(loResult, "nLowerBound", lnPredicted - loPattern.nStdDev)
        AddProperty(loResult, "nUpperBound", lnPredicted + loPattern.nStdDev)
        
        Return loResult
    EndProc
    
    * Classify data point against multiple patterns
    Procedure ClassifyDataPoint(tnValue)
        Local i, loPattern, lnScore, lnBestScore, lcBestPattern
        
        lnBestScore = -999999
        lcBestPattern = ""
        
        For i = 1 To This.nPatternCount
            loPattern = This.aPatterns[i]
            
            * Score based on distance from mean (inverse)
            If loPattern.nStdDev > 0
                lnScore = 1 / (1 + Abs((tnValue - loPattern.nMean) / loPattern.nStdDev))
            Else
                lnScore = Iif(tnValue = loPattern.nMean, 1, 0)
            EndIf
            
            If lnScore > lnBestScore
                lnBestScore = lnScore
                lcBestPattern = loPattern.cName
            EndIf
        EndFor
        
        Local loResult
        loResult = CreateObject("Empty")
        AddProperty(loResult, "cPattern", lcBestPattern)
        AddProperty(loResult, "nConfidence", lnBestScore)
        AddProperty(loResult, "lIsValid", lnBestScore >= This.nMinConfidence)
        
        Return loResult
    EndProc
    
    * Get pattern by name
    Protected Procedure GetPattern(tcName)
        Local i
        For i = 1 To This.nPatternCount
            If Upper(This.aPatterns[i].cName) == Upper(tcName)
                Return This.aPatterns[i]
            EndIf
        EndFor
        Return .Null.
    EndProc
    
    * Helper: Get minimum value from array
    Protected Procedure GetMin(taData)
        Local lnMin, i
        lnMin = taData[1]
        For i = 2 To Alen(taData)
            If taData[i] < lnMin
                lnMin = taData[i]
            EndIf
        EndFor
        Return lnMin
    EndProc
    
    * Helper: Get maximum value from array
    Protected Procedure GetMax(taData)
        Local lnMax, i
        lnMax = taData[1]
        For i = 2 To Alen(taData)
            If taData[i] > lnMax
                lnMax = taData[i]
            EndIf
        EndFor
        Return lnMax
    EndProc
    
    * Get all anomalies
    Procedure GetAnomalies(tcSeverity)
        Local i, loAnomaly
        Local Array laResult[1]
        Local lnCount
        
        lnCount = 0
        For i = 1 To This.nAnomalyCount
            loAnomaly = This.aAnomalies[i]
            If Empty(tcSeverity) Or Upper(loAnomaly.cSeverity) == Upper(tcSeverity)
                lnCount = lnCount + 1
                Dimension laResult[lnCount]
                laResult[lnCount] = loAnomaly
            EndIf
        EndFor
        
        Return @laResult
    EndProc
    
    * Clear old anomalies
    Procedure ClearAnomalies(tnOlderThanHours)
        Local i, loAnomaly, lnCutoff
        Local Array laNew[1]
        Local lnCount
        
        lnCutoff = Datetime() - (tnOlderThanHours * 3600)
        lnCount = 0
        
        For i = 1 To This.nAnomalyCount
            loAnomaly = This.aAnomalies[i]
            If loAnomaly.nTimestamp >= lnCutoff
                lnCount = lnCount + 1
                Dimension laNew[lnCount]
                laNew[lnCount] = loAnomaly
            EndIf
        EndFor
        
        This.nAnomalyCount = lnCount
        If lnCount > 0
            Dimension This.aAnomalies[lnCount]
            Acopy(laNew, This.aAnomalies)
        EndIf
    EndProc
    
    * Get statistics
    Procedure GetStatistics()
        Local loStats
        
        loStats = CreateObject("Empty")
        AddProperty(loStats, "nPatternCount", This.nPatternCount)
        AddProperty(loStats, "nAnomalyCount", This.nAnomalyCount)
        AddProperty(loStats, "nCriticalAnomalies", This.CountAnomaliesBySeverity("CRITICAL"))
        AddProperty(loStats, "nHighAnomalies", This.CountAnomaliesBySeverity("HIGH"))
        AddProperty(loStats, "nMediumAnomalies", This.CountAnomaliesBySeverity("MEDIUM"))
        
        Return loStats
    EndProc
    
    Protected Procedure CountAnomaliesBySeverity(tcSeverity)
        Local i, lnCount
        lnCount = 0
        For i = 1 To This.nAnomalyCount
            If Upper(This.aAnomalies[i].cSeverity) == Upper(tcSeverity)
                lnCount = lnCount + 1
            EndIf
        EndFor
        Return lnCount
    EndProc
    
EndDefine
