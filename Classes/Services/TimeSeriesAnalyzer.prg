*=========================================================================
* TimeSeriesAnalyzer.prg - Time Series Analysis Service
*=========================================================================
* Analiza time series pentru trend detection si forecasting
*=========================================================================

Define Class TimeSeriesAnalyzer As Custom
    Dimension aDataPoints[1]
    nDataPointCount = 0
    nWindowSize = 7
    
    Procedure Init
        This.nDataPointCount = 0
    EndProc
    
    Procedure AddDataPoint(tnValue, tnTimestamp)
        Local loPoint
        loPoint = CreateObject("Empty")
        AddProperty(loPoint, "nValue", tnValue)
        AddProperty(loPoint, "nTimestamp", Iif(Empty(tnTimestamp), Datetime(), tnTimestamp))
        
        This.nDataPointCount = This.nDataPointCount + 1
        Dimension This.aDataPoints[This.nDataPointCount]
        This.aDataPoints[This.nDataPointCount] = loPoint
        
        Return loPoint
    EndProc
    
    Procedure DetectTrend()
        If This.nDataPointCount < 3
            Return "INSUFFICIENT_DATA"
        EndIf
        
        Local lnSum, i, lnMean, lnSlope
        lnSum = 0
        
        For i = 1 To This.nDataPointCount
            lnSum = lnSum + This.aDataPoints[i].nValue
        EndFor
        lnMean = lnSum / This.nDataPointCount
        
        * Simple linear regression
        lnSlope = (This.aDataPoints[This.nDataPointCount].nValue - This.aDataPoints[1].nValue) / This.nDataPointCount
        
        Do Case
            Case lnSlope > 0.1
                Return "INCREASING"
            Case lnSlope < -0.1
                Return "DECREASING"
            Otherwise
                Return "STABLE"
        EndCase
    EndProc
    
    Procedure ForecastNext(tnPeriods)
        Local lnLastValue, lnTrend, lnForecast
        
        If This.nDataPointCount < 2
            Return 0
        EndIf
        
        lnLastValue = This.aDataPoints[This.nDataPointCount].nValue
        lnTrend = (This.aDataPoints[This.nDataPointCount].nValue - This.aDataPoints[1].nValue) / This.nDataPointCount
        lnForecast = lnLastValue + (lnTrend * tnPeriods)
        
        Return lnForecast
    EndProc
    
    Procedure GetMovingAverage(tnWindow)
        Local lnSum, i, lnStart
        
        If This.nDataPointCount < tnWindow
            Return 0
        EndIf
        
        lnSum = 0
        lnStart = This.nDataPointCount - tnWindow + 1
        
        For i = lnStart To This.nDataPointCount
            lnSum = lnSum + This.aDataPoints[i].nValue
        EndFor
        
        Return lnSum / tnWindow
    EndProc
    
EndDefine
