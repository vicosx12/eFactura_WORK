*==============================================================================
* EventStreamProcessor.prg - Stream Processing for Real-Time Events
*==============================================================================
* Processes event streams in real-time with windowing and aggregation
*==============================================================================

Define Class EventStreamProcessor As Custom
    Dimension aStreams[1]
    nStreamCount = 0
    oLogger = .Null.
    lRunning = .F.
    
    Procedure Init()
        This.oLogger = CreateObject("LoggerService")
        Dimension This.aStreams[1]
    EndProc
    
    *-- Create event stream
    Procedure CreateStream(tcStreamId, tcTopicPattern)
        Local loStream
        loStream = CreateObject("EventStream", tcStreamId, tcTopicPattern)
        
        This.nStreamCount = This.nStreamCount + 1
        Dimension This.aStreams[This.nStreamCount]
        This.aStreams[This.nStreamCount] = loStream
        
        This.oLogger.Info("Created event stream: " + tcStreamId)
        Return loStream
    EndProc
    
    *-- Publish event to stream
    Procedure PublishEvent(tcStreamId, toEvent)
        Local loStream
        loStream = This.GetStream(tcStreamId)
        
        If Not IsNull(loStream)
            loStream.AddEvent(toEvent)
            This.oLogger.Info("Published event to stream: " + tcStreamId)
            Return .T.
        EndIf
        
        Return .F.
    EndProc
    
    *-- Process stream with handler
    Procedure ProcessStream(tcStreamId, toHandler)
        Local loStream, i
        loStream = This.GetStream(tcStreamId)
        
        If IsNull(loStream)
            Return .F.
        EndIf
        
        *-- Process all pending events
        For i = 1 To loStream.nEventCount
            Try
                toHandler.Handle(loStream.aEvents[i])
            Catch To loEx
                This.oLogger.Error("Stream processing error: " + loEx.Message)
            EndTry
        EndFor
        
        *-- Clear processed events
        loStream.Clear()
        Return .T.
    EndProc
    
    *-- Create windowed stream
    Procedure CreateWindowedStream(tcStreamId, tnWindowSizeSec)
        Local loStream
        loStream = This.GetStream(tcStreamId)
        
        If Not IsNull(loStream)
            loStream.SetWindow(tnWindowSizeSec)
            This.oLogger.Info("Set window for stream: " + tcStreamId + " (" + Transform(tnWindowSizeSec) + "s)")
            Return .T.
        EndIf
        
        Return .F.
    EndProc
    
    *-- Aggregate events in window
    Procedure AggregateWindow(tcStreamId, toAggregator)
        Local loStream, laWindowEvents, loResult
        loStream = This.GetStream(tcStreamId)
        
        If IsNull(loStream)
            Return .Null.
        EndIf
        
        laWindowEvents = loStream.GetWindowEvents()
        
        If Empty(laWindowEvents)
            Return .Null.
        EndIf
        
        loResult = toAggregator.Aggregate(laWindowEvents)
        Return loResult
    EndProc
    
    *-- Start stream processing
    Procedure StartProcessing()
        This.lRunning = .T.
        This.oLogger.Info("Started event stream processing")
    EndProc
    
    *-- Stop stream processing
    Procedure StopProcessing()
        This.lRunning = .F.
        This.oLogger.Info("Stopped event stream processing")
    EndProc
    
    Protected Procedure GetStream(tcStreamId)
        Local i
        For i = 1 To This.nStreamCount
            If This.aStreams[i].cStreamId = tcStreamId
                Return This.aStreams[i]
            EndIf
        EndFor
        Return .Null.
    EndProc
EndDefine

*-- Event Stream
Define Class EventStream As Custom
    cStreamId = ""
    cTopicPattern = ""
    Dimension aEvents[1]
    nEventCount = 0
    nWindowSizeSec = 0
    tWindowStart = {}
    
    Procedure Init(tcStreamId, tcTopicPattern)
        This.cStreamId = tcStreamId
        This.cTopicPattern = tcTopicPattern
        Dimension This.aEvents[1]
    EndProc
    
    Procedure AddEvent(toEvent)
        This.nEventCount = This.nEventCount + 1
        Dimension This.aEvents[This.nEventCount]
        This.aEvents[This.nEventCount] = toEvent
        
        *-- Manage window if set
        If This.nWindowSizeSec > 0
            This.ManageWindow()
        EndIf
    EndProc
    
    Procedure SetWindow(tnSizeSec)
        This.nWindowSizeSec = tnSizeSec
        This.tWindowStart = Datetime()
    EndProc
    
    Procedure GetWindowEvents()
        Local laResult, i, lnCount
        Dimension laResult[1]
        lnCount = 0
        
        If This.nWindowSizeSec = 0
            Return @laResult
        EndIf
        
        Local tCutoff
        tCutoff = Datetime() - This.nWindowSizeSec
        
        For i = 1 To This.nEventCount
            If This.aEvents[i].tTimestamp >= tCutoff
                lnCount = lnCount + 1
                Dimension laResult[lnCount]
                laResult[lnCount] = This.aEvents[i]
            EndIf
        EndFor
        
        Return @laResult
    EndProc
    
    Protected Procedure ManageWindow()
        *-- Remove events outside window
        Local tCutoff, laNewEvents, i, lnCount
        tCutoff = Datetime() - This.nWindowSizeSec
        
        Dimension laNewEvents[1]
        lnCount = 0
        
        For i = 1 To This.nEventCount
            If This.aEvents[i].tTimestamp >= tCutoff
                lnCount = lnCount + 1
                Dimension laNewEvents[lnCount]
                laNewEvents[lnCount] = This.aEvents[i]
            EndIf
        EndFor
        
        This.nEventCount = lnCount
        If lnCount > 0
            Dimension This.aEvents[lnCount]
            For i = 1 To lnCount
                This.aEvents[i] = laNewEvents[i]
            EndFor
        Else
            Dimension This.aEvents[1]
        EndIf
    EndProc
    
    Procedure Clear()
        Dimension This.aEvents[1]
        This.nEventCount = 0
    EndProc
EndDefine
