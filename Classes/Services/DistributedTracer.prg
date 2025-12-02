*******************************************************************************
* DistributedTracer.prg
* Serviciu pentru distributed tracing cu correlation IDs
* 
* Funcționalități:
* - Generare și propagare correlation IDs
* - Creare span-uri pentru operațiuni
* - Măsurare durate
* - Context propagation
* - Export în format standard (Zipkin/Jaeger-like)
* - Sampling configurabil
* - Logging cu trace context
*
* Exemplu utilizare:
*   loTracer = CreateObject("DistributedTracer")
*   loSpan = loTracer.StartSpan("UploadInvoice")
*   loSpan.SetTag("invoice.id", "123")
*   loChildSpan = loTracer.StartSpan("GenerateXML", loSpan)
*   loChildSpan.Finish()
*   loSpan.Finish()
*******************************************************************************

Define Class DistributedTracer As Custom
    
    * Configurare
    cServiceName = "eFactura"
    cServiceVersion = "2.3"
    lEnabled = .T.
    nSampleRate = 1.0  && 100% sampling
    
    * Trace curent
    cCurrentTraceId = ""
    cCurrentSpanId = ""
    
    * Span-uri active
    Dimension aActiveSpans[1, 8]  && SpanId, TraceId, ParentId, Name, StartTime, EndTime, Tags, Status
    nActiveSpanCount = 0
    
    * Span-uri completate (pentru export)
    Dimension aCompletedSpans[1, 8]
    nCompletedSpanCount = 0
    nMaxCompletedSpans = 1000
    
    * Context propagation headers
    cTraceHeader = "X-Trace-Id"
    cSpanHeader = "X-Span-Id"
    cParentHeader = "X-Parent-Span-Id"
    
    * Exporter
    cExporterUrl = ""
    lAutoExport = .F.
    nExportBatchSize = 100
    
    * Logging
    oLogger = .Null.
    
    *---------------------------------------------------------------------------
    Procedure Init
        * Inițializare seed pentru random
        Rand(-1)
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează logger-ul
    *---------------------------------------------------------------------------
    Procedure SetLogger(toLogger)
        This.oLogger = toLogger
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează serviciul
    *---------------------------------------------------------------------------
    Procedure SetService(tcName, tcVersion)
        This.cServiceName = tcName
        This.cServiceVersion = tcVersion
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Configurează sampling
    *---------------------------------------------------------------------------
    Procedure SetSampleRate(tnRate)
        This.nSampleRate = Max(0, Min(1, tnRate))
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Configurează exporter
    *---------------------------------------------------------------------------
    Procedure SetExporter(tcUrl, tlAutoExport)
        This.cExporterUrl = tcUrl
        This.lAutoExport = Iif(VarType(tlAutoExport) = 'L', tlAutoExport, .F.)
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Generează ID unic
    *---------------------------------------------------------------------------
    Procedure GenerateId(tnLength)
        Local lcResult, i, lnChar
        
        tnLength = Iif(VarType(tnLength) = 'N', tnLength, 16)
        lcResult = ""
        
        For i = 1 To tnLength
            lnChar = Int(Rand() * 16)
            lcResult = lcResult + Substr("0123456789abcdef", lnChar + 1, 1)
        EndFor
        
        Return lcResult
    EndProc
    
    *---------------------------------------------------------------------------
    * Începe un trace nou
    *---------------------------------------------------------------------------
    Procedure StartTrace(tcName)
        Local loSpan
        
        * Verifică sampling
        If Not This.ShouldSample()
            Return .Null.
        EndIf
        
        * Generează trace ID nou
        This.cCurrentTraceId = This.GenerateId(32)
        This.cCurrentSpanId = ""
        
        * Creează root span
        loSpan = This.StartSpan(tcName)
        
        This.Log("DEBUG", "Trace started: " + This.cCurrentTraceId)
        
        Return loSpan
    EndProc
    
    *---------------------------------------------------------------------------
    * Începe un span nou
    *---------------------------------------------------------------------------
    Procedure StartSpan(tcName, toParentSpan)
        Local loSpan, lcTraceId, lcParentId, lcSpanId
        
        If Not This.lEnabled
            Return .Null.
        EndIf
        
        * Determină trace și parent
        If VarType(toParentSpan) = 'O'
            lcTraceId = toParentSpan.cTraceId
            lcParentId = toParentSpan.cSpanId
        Else
            lcTraceId = Iif(Empty(This.cCurrentTraceId), This.GenerateId(32), This.cCurrentTraceId)
            lcParentId = This.cCurrentSpanId
        EndIf
        
        * Generează span ID
        lcSpanId = This.GenerateId(16)
        
        * Creează obiectul span
        loSpan = CreateObject("TracingSpan")
        loSpan.cSpanId = lcSpanId
        loSpan.cTraceId = lcTraceId
        loSpan.cParentSpanId = lcParentId
        loSpan.cName = tcName
        loSpan.cServiceName = This.cServiceName
        loSpan.nStartTime = Seconds()
        loSpan.oTracer = This
        
        * Adaugă la lista activă
        This.AddActiveSpan(loSpan)
        
        * Actualizează contextul curent
        This.cCurrentSpanId = lcSpanId
        If Empty(This.cCurrentTraceId)
            This.cCurrentTraceId = lcTraceId
        EndIf
        
        This.Log("DEBUG", "Span started: " + tcName + " (" + lcSpanId + ")")
        
        Return loSpan
    EndProc
    
    *---------------------------------------------------------------------------
    * Finalizează un span
    *---------------------------------------------------------------------------
    Procedure FinishSpan(toSpan)
        Local i
        
        If VarType(toSpan) <> 'O'
            Return
        EndIf
        
        toSpan.nEndTime = Seconds()
        toSpan.nDuration = toSpan.nEndTime - toSpan.nStartTime
        
        * Mută din active în completed
        This.RemoveActiveSpan(toSpan.cSpanId)
        This.AddCompletedSpan(toSpan)
        
        This.Log("DEBUG", "Span finished: " + toSpan.cName + " (Duration: " + Transform(toSpan.nDuration * 1000) + "ms)")
        
        * Auto-export dacă e configurat
        If This.lAutoExport And This.nCompletedSpanCount >= This.nExportBatchSize
            This.ExportSpans()
        EndIf
    EndProc
    
    *---------------------------------------------------------------------------
    * Adaugă span la lista activă
    *---------------------------------------------------------------------------
    Protected Procedure AddActiveSpan(toSpan)
        This.nActiveSpanCount = This.nActiveSpanCount + 1
        Dimension This.aActiveSpans[This.nActiveSpanCount, 8]
        
        This.aActiveSpans[This.nActiveSpanCount, 1] = toSpan.cSpanId
        This.aActiveSpans[This.nActiveSpanCount, 2] = toSpan.cTraceId
        This.aActiveSpans[This.nActiveSpanCount, 3] = toSpan.cParentSpanId
        This.aActiveSpans[This.nActiveSpanCount, 4] = toSpan.cName
        This.aActiveSpans[This.nActiveSpanCount, 5] = toSpan.nStartTime
        This.aActiveSpans[This.nActiveSpanCount, 6] = 0
        This.aActiveSpans[This.nActiveSpanCount, 7] = ""
        This.aActiveSpans[This.nActiveSpanCount, 8] = "RUNNING"
    EndProc
    
    *---------------------------------------------------------------------------
    * Șterge span din lista activă
    *---------------------------------------------------------------------------
    Protected Procedure RemoveActiveSpan(tcSpanId)
        Local i, j
        
        For i = 1 To This.nActiveSpanCount
            If This.aActiveSpans[i, 1] == tcSpanId
                * Shift remaining
                For j = i To This.nActiveSpanCount - 1
                    This.aActiveSpans[j, 1] = This.aActiveSpans[j + 1, 1]
                    This.aActiveSpans[j, 2] = This.aActiveSpans[j + 1, 2]
                    This.aActiveSpans[j, 3] = This.aActiveSpans[j + 1, 3]
                    This.aActiveSpans[j, 4] = This.aActiveSpans[j + 1, 4]
                    This.aActiveSpans[j, 5] = This.aActiveSpans[j + 1, 5]
                    This.aActiveSpans[j, 6] = This.aActiveSpans[j + 1, 6]
                    This.aActiveSpans[j, 7] = This.aActiveSpans[j + 1, 7]
                    This.aActiveSpans[j, 8] = This.aActiveSpans[j + 1, 8]
                EndFor
                This.nActiveSpanCount = Max(This.nActiveSpanCount - 1, 0)
                Exit
            EndIf
        EndFor
    EndProc
    
    *---------------------------------------------------------------------------
    * Adaugă span la lista completată
    *---------------------------------------------------------------------------
    Protected Procedure AddCompletedSpan(toSpan)
        * Rotație dacă e plin
        If This.nCompletedSpanCount >= This.nMaxCompletedSpans
            This.ExportSpans()
            This.nCompletedSpanCount = 0
        EndIf
        
        This.nCompletedSpanCount = This.nCompletedSpanCount + 1
        Dimension This.aCompletedSpans[This.nCompletedSpanCount, 8]
        
        This.aCompletedSpans[This.nCompletedSpanCount, 1] = toSpan.cSpanId
        This.aCompletedSpans[This.nCompletedSpanCount, 2] = toSpan.cTraceId
        This.aCompletedSpans[This.nCompletedSpanCount, 3] = toSpan.cParentSpanId
        This.aCompletedSpans[This.nCompletedSpanCount, 4] = toSpan.cName
        This.aCompletedSpans[This.nCompletedSpanCount, 5] = toSpan.nStartTime
        This.aCompletedSpans[This.nCompletedSpanCount, 6] = toSpan.nEndTime
        This.aCompletedSpans[This.nCompletedSpanCount, 7] = toSpan.GetTagsJson()
        This.aCompletedSpans[This.nCompletedSpanCount, 8] = toSpan.cStatus
    EndProc
    
    *---------------------------------------------------------------------------
    * Verifică dacă să eșantioneze
    *---------------------------------------------------------------------------
    Protected Procedure ShouldSample
        Return Rand() <= This.nSampleRate
    EndProc
    
    *---------------------------------------------------------------------------
    * Obține trace context pentru propagare
    *---------------------------------------------------------------------------
    Procedure GetTraceContext
        Local lcContext
        
        lcContext = This.cTraceHeader + ": " + This.cCurrentTraceId + Chr(13) + Chr(10)
        lcContext = lcContext + This.cSpanHeader + ": " + This.cCurrentSpanId + Chr(13) + Chr(10)
        
        Return lcContext
    EndProc
    
    *---------------------------------------------------------------------------
    * Injectează context în headers
    *---------------------------------------------------------------------------
    Procedure InjectContext(toHeaders)
        If VarType(toHeaders) = 'O'
            AddProperty(toHeaders, "X_Trace_Id", This.cCurrentTraceId)
            AddProperty(toHeaders, "X_Span_Id", This.cCurrentSpanId)
        EndIf
        Return toHeaders
    EndProc
    
    *---------------------------------------------------------------------------
    * Extrage context din headers
    *---------------------------------------------------------------------------
    Procedure ExtractContext(tcHeaders)
        Local lnPos
        
        * Extrage Trace ID
        lnPos = At(This.cTraceHeader + ":", tcHeaders)
        If lnPos > 0
            This.cCurrentTraceId = Alltrim(Substr(tcHeaders, lnPos + Len(This.cTraceHeader) + 1, 32))
        EndIf
        
        * Extrage Span ID (devine parent)
        lnPos = At(This.cSpanHeader + ":", tcHeaders)
        If lnPos > 0
            This.cCurrentSpanId = Alltrim(Substr(tcHeaders, lnPos + Len(This.cSpanHeader) + 1, 16))
        EndIf
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Exportă span-urile în format JSON
    *---------------------------------------------------------------------------
    Procedure ExportSpans
        Local lcJson, i
        
        If This.nCompletedSpanCount = 0
            Return ""
        EndIf
        
        lcJson = '{"spans": [' + Chr(13) + Chr(10)
        
        For i = 1 To This.nCompletedSpanCount
            lcJson = lcJson + '  {'
            lcJson = lcJson + '"traceId": "' + This.aCompletedSpans[i, 2] + '",'
            lcJson = lcJson + '"spanId": "' + This.aCompletedSpans[i, 1] + '",'
            lcJson = lcJson + '"parentSpanId": "' + This.aCompletedSpans[i, 3] + '",'
            lcJson = lcJson + '"name": "' + This.aCompletedSpans[i, 4] + '",'
            lcJson = lcJson + '"startTime": ' + Transform(This.aCompletedSpans[i, 5]) + ','
            lcJson = lcJson + '"endTime": ' + Transform(This.aCompletedSpans[i, 6]) + ','
            lcJson = lcJson + '"duration": ' + Transform(This.aCompletedSpans[i, 6] - This.aCompletedSpans[i, 5]) + ','
            lcJson = lcJson + '"status": "' + This.aCompletedSpans[i, 8] + '",'
            lcJson = lcJson + '"tags": ' + Iif(Empty(This.aCompletedSpans[i, 7]), "{}", This.aCompletedSpans[i, 7])
            lcJson = lcJson + '}' + Iif(i < This.nCompletedSpanCount, ',', '') + Chr(13) + Chr(10)
        EndFor
        
        lcJson = lcJson + ']}'
        
        * Trimite la exporter dacă e configurat
        If Not Empty(This.cExporterUrl)
            This.SendToExporter(lcJson)
        EndIf
        
        Return lcJson
    EndProc
    
    *---------------------------------------------------------------------------
    * Trimite la exporter
    *---------------------------------------------------------------------------
    Protected Procedure SendToExporter(tcJson)
        Local loHttp
        
        Try
            loHttp = CreateObject("MSXML2.ServerXMLHTTP.6.0")
            loHttp.Open("POST", This.cExporterUrl, .F.)
            loHttp.SetRequestHeader("Content-Type", "application/json")
            loHttp.Send(tcJson)
            
            If loHttp.Status >= 200 And loHttp.Status < 300
                This.Log("DEBUG", "Spans exported successfully")
            Else
                This.Log("WARNING", "Span export failed: " + Transform(loHttp.Status))
            EndIf
            
        Catch To loEx
            This.Log("ERROR", "Span export exception: " + loEx.Message)
        EndTry
    EndProc
    
    *---------------------------------------------------------------------------
    * Obține trace ID curent
    *---------------------------------------------------------------------------
    Procedure GetTraceId
        Return This.cCurrentTraceId
    EndProc
    
    *---------------------------------------------------------------------------
    * Obține span ID curent
    *---------------------------------------------------------------------------
    Procedure GetSpanId
        Return This.cCurrentSpanId
    EndProc
    
    *---------------------------------------------------------------------------
    * Resetează contextul
    *---------------------------------------------------------------------------
    Procedure Reset
        This.cCurrentTraceId = ""
        This.cCurrentSpanId = ""
        This.nActiveSpanCount = 0
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Logging
    *---------------------------------------------------------------------------
    Protected Procedure Log(tcLevel, tcMessage)
        If VarType(This.oLogger) = 'O'
            * Adaugă trace context la log
            Local lcContext
            lcContext = "[" + Left(This.cCurrentTraceId, 8) + "] "
            
            Do Case
                Case tcLevel = "DEBUG"
                    This.oLogger.Debug(lcContext + tcMessage)
                Case tcLevel = "INFO"
                    This.oLogger.Info(lcContext + tcMessage)
                Case tcLevel = "WARNING"
                    This.oLogger.Warning(lcContext + tcMessage)
                Case tcLevel = "ERROR"
                    This.oLogger.LogError(lcContext + tcMessage)
            EndCase
        EndIf
    EndProc
    
EndDefine


*******************************************************************************
* TracingSpan - Reprezintă un span individual
*******************************************************************************
Define Class TracingSpan As Custom
    
    cSpanId = ""
    cTraceId = ""
    cParentSpanId = ""
    cName = ""
    cServiceName = ""
    nStartTime = 0
    nEndTime = 0
    nDuration = 0
    cStatus = "OK"
    
    * Tags
    Dimension aTags[1, 2]
    nTagCount = 0
    
    * Logs/Events
    Dimension aLogs[1, 2]
    nLogCount = 0
    
    * Reference la tracer
    oTracer = .Null.
    
    *---------------------------------------------------------------------------
    * Setează un tag
    *---------------------------------------------------------------------------
    Procedure SetTag(tcKey, tvValue)
        Local lnIndex, i
        
        * Caută tag existent
        lnIndex = 0
        For i = 1 To This.nTagCount
            If This.aTags[i, 1] == tcKey
                lnIndex = i
                Exit
            EndIf
        EndFor
        
        If lnIndex = 0
            This.nTagCount = This.nTagCount + 1
            Dimension This.aTags[This.nTagCount, 2]
            lnIndex = This.nTagCount
        EndIf
        
        This.aTags[lnIndex, 1] = tcKey
        This.aTags[lnIndex, 2] = Transform(tvValue)
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Adaugă un log/event
    *---------------------------------------------------------------------------
    Procedure LogEvent(tcMessage)
        This.nLogCount = This.nLogCount + 1
        Dimension This.aLogs[This.nLogCount, 2]
        
        This.aLogs[This.nLogCount, 1] = Seconds()
        This.aLogs[This.nLogCount, 2] = tcMessage
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Marchează ca eroare
    *---------------------------------------------------------------------------
    Procedure SetError(tcMessage)
        This.cStatus = "ERROR"
        This.SetTag("error", "true")
        This.SetTag("error.message", tcMessage)
        This.LogEvent("Error: " + tcMessage)
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Finalizează span-ul
    *---------------------------------------------------------------------------
    Procedure Finish
        If VarType(This.oTracer) = 'O'
            This.oTracer.FinishSpan(This)
        Else
            This.nEndTime = Seconds()
            This.nDuration = This.nEndTime - This.nStartTime
        EndIf
    EndProc
    
    *---------------------------------------------------------------------------
    * Obține tags ca JSON
    *---------------------------------------------------------------------------
    Procedure GetTagsJson
        Local lcJson, i
        
        If This.nTagCount = 0
            Return "{}"
        EndIf
        
        lcJson = "{"
        
        For i = 1 To This.nTagCount
            If i > 1
                lcJson = lcJson + ","
            EndIf
            lcJson = lcJson + '"' + This.aTags[i, 1] + '":"' + This.aTags[i, 2] + '"'
        EndFor
        
        lcJson = lcJson + "}"
        
        Return lcJson
    EndProc
    
    *---------------------------------------------------------------------------
    * Creează un child span
    *---------------------------------------------------------------------------
    Procedure StartChildSpan(tcName)
        If VarType(This.oTracer) = 'O'
            Return This.oTracer.StartSpan(tcName, This)
        EndIf
        Return .Null.
    EndProc
    
EndDefine
