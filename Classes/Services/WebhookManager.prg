*******************************************************************************
* WebhookManager.prg
* Manager pentru webhook-uri - notificări push de la ANAF sau sisteme externe
* 
* Funcționalități:
* - Înregistrare endpoint-uri webhook
* - Procesare webhook-uri incoming
* - Validare semnătură și autenticitate
* - Retry pentru delivery failures
* - Queue pentru outgoing webhooks
* - Rate limiting
* - Logging și audit
*
* Exemplu utilizare:
*   loWebhook = CreateObject("WebhookManager")
*   loWebhook.RegisterEndpoint("AnafStatus", "https://myapp.com/webhook/anaf")
*   loWebhook.Send("AnafStatus", lcPayload)
*******************************************************************************

Define Class WebhookManager As Custom
    
    * Endpoint-uri înregistrate
    Dimension aEndpoints[1, 8]  && Name, URL, Secret, Active, RetryCount, LastCall, SuccessCount, FailCount
    nEndpointCount = 0
    
    * Coadă outgoing
    Dimension aOutQueue[1, 5]   && EndpointName, Payload, Attempts, NextRetry, CreatedAt
    nOutQueueCount = 0
    
    * Configurare
    nMaxRetries = 3
    nRetryDelaySeconds = 60
    nTimeoutSeconds = 30
    lVerifySSL = .T.
    
    * Rate limiting
    nMaxRequestsPerMinute = 60
    Dimension aRequestLog[1, 2]  && Endpoint, Timestamp
    nRequestLogCount = 0
    
    * Handlers pentru incoming webhooks
    Dimension aHandlers[1, 2]    && EventType, HandlerObject
    nHandlerCount = 0
    
    * Logging
    oLogger = .Null.
    oAuditService = .Null.
    
    *---------------------------------------------------------------------------
    Procedure Init
        * Inițializare HTTP
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează logger-ul
    *---------------------------------------------------------------------------
    Procedure SetLogger(toLogger)
        This.oLogger = toLogger
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează serviciul de audit
    *---------------------------------------------------------------------------
    Procedure SetAuditService(toAudit)
        This.oAuditService = toAudit
    EndProc
    
    *---------------------------------------------------------------------------
    * Înregistrează un endpoint webhook
    *---------------------------------------------------------------------------
    Procedure RegisterEndpoint(tcName, tcUrl, tcSecret, tlActive)
        Local lnIndex
        
        lnIndex = This.FindEndpointIndex(tcName)
        If lnIndex = 0
            This.nEndpointCount = This.nEndpointCount + 1
            Dimension This.aEndpoints[This.nEndpointCount, 8]
            lnIndex = This.nEndpointCount
        EndIf
        
        This.aEndpoints[lnIndex, 1] = tcName
        This.aEndpoints[lnIndex, 2] = tcUrl
        This.aEndpoints[lnIndex, 3] = Nvl(tcSecret, "")
        This.aEndpoints[lnIndex, 4] = Iif(VarType(tlActive) = 'L', tlActive, .T.)
        This.aEndpoints[lnIndex, 5] = 0   && RetryCount
        This.aEndpoints[lnIndex, 6] = .Null.  && LastCall
        This.aEndpoints[lnIndex, 7] = 0   && SuccessCount
        This.aEndpoints[lnIndex, 8] = 0   && FailCount
        
        This.Log("INFO", "Endpoint registered: " + tcName + " -> " + tcUrl)
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Activează/Dezactivează endpoint
    *---------------------------------------------------------------------------
    Procedure EnableEndpoint(tcName)
        Local lnIndex
        lnIndex = This.FindEndpointIndex(tcName)
        If lnIndex > 0
            This.aEndpoints[lnIndex, 4] = .T.
        EndIf
        Return This
    EndProc
    
    Procedure DisableEndpoint(tcName)
        Local lnIndex
        lnIndex = This.FindEndpointIndex(tcName)
        If lnIndex > 0
            This.aEndpoints[lnIndex, 4] = .F.
        EndIf
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Trimite webhook (sincron)
    *---------------------------------------------------------------------------
    Procedure Send(tcEndpointName, tcPayload, tcContentType)
        Local lnIndex, lcUrl, lcSecret, llResult
        Local loHttp, lcResponse, lnStatus
        
        lnIndex = This.FindEndpointIndex(tcEndpointName)
        If lnIndex = 0
            This.Log("ERROR", "Endpoint not found: " + tcEndpointName)
            Return .F.
        EndIf
        
        If Not This.aEndpoints[lnIndex, 4]
            This.Log("WARNING", "Endpoint disabled: " + tcEndpointName)
            Return .F.
        EndIf
        
        * Rate limiting check
        If Not This.CheckRateLimit(tcEndpointName)
            This.Log("WARNING", "Rate limit exceeded for: " + tcEndpointName)
            Return .F.
        EndIf
        
        lcUrl = This.aEndpoints[lnIndex, 2]
        lcSecret = This.aEndpoints[lnIndex, 3]
        
        * Generează semnătură
        Local lcSignature, lcTimestamp
        lcTimestamp = Transform(Datetime())
        lcSignature = This.GenerateSignature(tcPayload, lcSecret, lcTimestamp)
        
        * Trimite request
        Try
            loHttp = CreateObject("MSXML2.ServerXMLHTTP.6.0")
            loHttp.SetTimeouts(5000, This.nTimeoutSeconds * 1000, This.nTimeoutSeconds * 1000, This.nTimeoutSeconds * 1000)
            loHttp.Open("POST", lcUrl, .F.)
            loHttp.SetRequestHeader("Content-Type", Nvl(tcContentType, "application/json"))
            loHttp.SetRequestHeader("X-Webhook-Signature", lcSignature)
            loHttp.SetRequestHeader("X-Webhook-Timestamp", lcTimestamp)
            loHttp.SetRequestHeader("X-Webhook-Event", tcEndpointName)
            loHttp.Send(tcPayload)
            
            lnStatus = loHttp.Status
            lcResponse = loHttp.ResponseText
            
            If lnStatus >= 200 And lnStatus < 300
                llResult = .T.
                This.aEndpoints[lnIndex, 7] = This.aEndpoints[lnIndex, 7] + 1
                This.Log("INFO", "Webhook sent successfully to: " + tcEndpointName + " (Status: " + Transform(lnStatus) + ")")
            Else
                llResult = .F.
                This.aEndpoints[lnIndex, 8] = This.aEndpoints[lnIndex, 8] + 1
                This.Log("ERROR", "Webhook failed: " + tcEndpointName + " (Status: " + Transform(lnStatus) + ")")
            EndIf
            
            This.aEndpoints[lnIndex, 6] = Datetime()
            
        Catch To loEx
            llResult = .F.
            This.aEndpoints[lnIndex, 8] = This.aEndpoints[lnIndex, 8] + 1
            This.Log("ERROR", "Webhook exception: " + tcEndpointName + " - " + loEx.Message)
        EndTry
        
        * Audit
        This.Audit("WebhookSent", tcEndpointName, Iif(llResult, "Success", "Failed"))
        
        Return llResult
    EndProc
    
    *---------------------------------------------------------------------------
    * Adaugă la coadă pentru trimitere async
    *---------------------------------------------------------------------------
    Procedure QueueSend(tcEndpointName, tcPayload)
        This.nOutQueueCount = This.nOutQueueCount + 1
        Dimension This.aOutQueue[This.nOutQueueCount, 5]
        
        This.aOutQueue[This.nOutQueueCount, 1] = tcEndpointName
        This.aOutQueue[This.nOutQueueCount, 2] = tcPayload
        This.aOutQueue[This.nOutQueueCount, 3] = 0          && Attempts
        This.aOutQueue[This.nOutQueueCount, 4] = Datetime() && NextRetry
        This.aOutQueue[This.nOutQueueCount, 5] = Datetime() && CreatedAt
        
        This.Log("DEBUG", "Webhook queued: " + tcEndpointName)
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Procesează coada de trimitere
    *---------------------------------------------------------------------------
    Procedure ProcessQueue
        Local i, lcEndpoint, lcPayload, lnAttempts, ldNextRetry
        Local llSuccess, lnProcessed, lnFailed
        
        lnProcessed = 0
        lnFailed = 0
        
        For i = This.nOutQueueCount To 1 Step -1
            ldNextRetry = This.aOutQueue[i, 4]
            
            If Datetime() >= ldNextRetry
                lcEndpoint = This.aOutQueue[i, 1]
                lcPayload = This.aOutQueue[i, 2]
                lnAttempts = This.aOutQueue[i, 3]
                
                llSuccess = This.Send(lcEndpoint, lcPayload)
                
                If llSuccess
                    * Șterge din coadă
                    This.RemoveFromQueue(i)
                    lnProcessed = lnProcessed + 1
                Else
                    lnAttempts = lnAttempts + 1
                    This.aOutQueue[i, 3] = lnAttempts
                    
                    If lnAttempts >= This.nMaxRetries
                        * Max retries - șterge
                        This.Log("ERROR", "Webhook max retries reached: " + lcEndpoint)
                        This.RemoveFromQueue(i)
                        lnFailed = lnFailed + 1
                    Else
                        * Schedule next retry
                        This.aOutQueue[i, 4] = Datetime() + (This.nRetryDelaySeconds * lnAttempts) / 86400
                    EndIf
                EndIf
            EndIf
        EndFor
        
        Return lnProcessed
    EndProc
    
    *---------------------------------------------------------------------------
    * Șterge element din coadă
    *---------------------------------------------------------------------------
    Protected Procedure RemoveFromQueue(tnIndex)
        Local i, j
        
        For j = tnIndex To This.nOutQueueCount - 1
            For i = 1 To 5
                This.aOutQueue[j, i] = This.aOutQueue[j + 1, i]
            EndFor
        EndFor
        
        This.nOutQueueCount = Max(This.nOutQueueCount - 1, 0)
    EndProc
    
    *---------------------------------------------------------------------------
    * Înregistrează handler pentru incoming webhooks
    *---------------------------------------------------------------------------
    Procedure RegisterHandler(tcEventType, toHandler)
        This.nHandlerCount = This.nHandlerCount + 1
        Dimension This.aHandlers[This.nHandlerCount, 2]
        
        This.aHandlers[This.nHandlerCount, 1] = tcEventType
        This.aHandlers[This.nHandlerCount, 2] = toHandler
        
        This.Log("DEBUG", "Handler registered for: " + tcEventType)
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Procesează incoming webhook
    *---------------------------------------------------------------------------
    Procedure ProcessIncoming(tcEventType, tcPayload, tcSignature, tcTimestamp, tcSecret)
        Local i, llValid, loHandler
        
        * Validare semnătură
        llValid = This.ValidateSignature(tcPayload, tcSignature, tcSecret, tcTimestamp)
        
        If Not llValid
            This.Log("ERROR", "Invalid webhook signature for: " + tcEventType)
            This.Audit("WebhookReceived", tcEventType, "InvalidSignature")
            Return .F.
        EndIf
        
        * Găsește și apelează handler-ul
        For i = 1 To This.nHandlerCount
            If Upper(This.aHandlers[i, 1]) == Upper(tcEventType) Or This.aHandlers[i, 1] = "*"
                loHandler = This.aHandlers[i, 2]
                If VarType(loHandler) = 'O' And PemStatus(loHandler, "HandleWebhook", 5)
                    Try
                        loHandler.HandleWebhook(tcEventType, tcPayload)
                        This.Log("INFO", "Webhook processed: " + tcEventType)
                    Catch To loEx
                        This.Log("ERROR", "Webhook handler error: " + loEx.Message)
                    EndTry
                EndIf
            EndIf
        EndFor
        
        This.Audit("WebhookReceived", tcEventType, "Processed")
        Return .T.
    EndProc
    
    *---------------------------------------------------------------------------
    * Generează semnătură HMAC pentru payload
    *---------------------------------------------------------------------------
    Protected Procedure GenerateSignature(tcPayload, tcSecret, tcTimestamp)
        Local lcData, lcHash
        
        If Empty(tcSecret)
            Return ""
        EndIf
        
        lcData = tcTimestamp + "." + tcPayload
        lcHash = This.HMAC(lcData, tcSecret)
        
        Return lcHash
    EndProc
    
    *---------------------------------------------------------------------------
    * Validează semnătură
    *---------------------------------------------------------------------------
    Protected Procedure ValidateSignature(tcPayload, tcSignature, tcSecret, tcTimestamp)
        Local lcExpected
        
        If Empty(tcSecret)
            Return .T.  && Fără validare dacă nu e secret
        EndIf
        
        lcExpected = This.GenerateSignature(tcPayload, tcSecret, tcTimestamp)
        
        * Timing-safe comparison
        Return This.SecureCompare(lcExpected, tcSignature)
    EndProc
    
    *---------------------------------------------------------------------------
    * HMAC simplificat
    *---------------------------------------------------------------------------
    Protected Procedure HMAC(tcData, tcKey)
        Local lcResult, i, lnChar, lnKey
        Local lcOpad, lcIpad, lcKeyPad
        
        * Key padding
        If Len(tcKey) > 64
            tcKey = This.Hash(tcKey)
        EndIf
        lcKeyPad = Padr(tcKey, 64, Chr(0))
        
        * O-pad și I-pad
        lcOpad = ""
        lcIpad = ""
        For i = 1 To 64
            lnKey = Asc(Substr(lcKeyPad, i, 1))
            lcOpad = lcOpad + Chr(Bitxor(lnKey, 0x5c))
            lcIpad = lcIpad + Chr(Bitxor(lnKey, 0x36))
        EndFor
        
        * HMAC = H(O-pad || H(I-pad || message))
        lcResult = This.Hash(lcOpad + This.Hash(lcIpad + tcData))
        
        Return lcResult
    EndProc
    
    *---------------------------------------------------------------------------
    * Hash simplu (pentru HMAC)
    *---------------------------------------------------------------------------
    Protected Procedure Hash(tcData)
        Local lcHash, i, lnChar, lnSum
        
        lnSum = 0
        For i = 1 To Len(tcData)
            lnChar = Asc(Substr(tcData, i, 1))
            lnSum = Mod(lnSum * 31 + lnChar, 0xFFFFFFFF)
        EndFor
        
        Return Transform(lnSum, "@0")
    EndProc
    
    *---------------------------------------------------------------------------
    * Comparare timing-safe
    *---------------------------------------------------------------------------
    Protected Procedure SecureCompare(tcStr1, tcStr2)
        Local lnResult, i, lnLen
        
        If Len(tcStr1) <> Len(tcStr2)
            Return .F.
        EndIf
        
        lnResult = 0
        lnLen = Len(tcStr1)
        
        For i = 1 To lnLen
            lnResult = Bitor(lnResult, Bitxor(Asc(Substr(tcStr1, i, 1)), Asc(Substr(tcStr2, i, 1))))
        EndFor
        
        Return lnResult = 0
    EndProc
    
    *---------------------------------------------------------------------------
    * Rate limiting check
    *---------------------------------------------------------------------------
    Protected Procedure CheckRateLimit(tcEndpoint)
        Local ldNow, ldMinuteAgo, lnCount, i
        
        ldNow = Datetime()
        ldMinuteAgo = ldNow - 60 / 86400
        
        * Numără request-uri în ultimul minut
        lnCount = 0
        For i = 1 To This.nRequestLogCount
            If This.aRequestLog[i, 1] = tcEndpoint And This.aRequestLog[i, 2] > ldMinuteAgo
                lnCount = lnCount + 1
            EndIf
        EndFor
        
        If lnCount >= This.nMaxRequestsPerMinute
            Return .F.
        EndIf
        
        * Adaugă request curent
        This.nRequestLogCount = This.nRequestLogCount + 1
        Dimension This.aRequestLog[This.nRequestLogCount, 2]
        This.aRequestLog[This.nRequestLogCount, 1] = tcEndpoint
        This.aRequestLog[This.nRequestLogCount, 2] = ldNow
        
        Return .T.
    EndProc
    
    *---------------------------------------------------------------------------
    * Găsește endpoint după nume
    *---------------------------------------------------------------------------
    Protected Procedure FindEndpointIndex(tcName)
        Local i
        
        For i = 1 To This.nEndpointCount
            If Upper(This.aEndpoints[i, 1]) == Upper(tcName)
                Return i
            EndIf
        EndFor
        
        Return 0
    EndProc
    
    *---------------------------------------------------------------------------
    * Obține statistici endpoint
    *---------------------------------------------------------------------------
    Procedure GetEndpointStats(tcName)
        Local lnIndex, loStats
        
        lnIndex = This.FindEndpointIndex(tcName)
        If lnIndex = 0
            Return .Null.
        EndIf
        
        loStats = CreateObject("Empty")
        AddProperty(loStats, "Name", This.aEndpoints[lnIndex, 1])
        AddProperty(loStats, "Url", This.aEndpoints[lnIndex, 2])
        AddProperty(loStats, "Active", This.aEndpoints[lnIndex, 4])
        AddProperty(loStats, "LastCall", This.aEndpoints[lnIndex, 6])
        AddProperty(loStats, "SuccessCount", This.aEndpoints[lnIndex, 7])
        AddProperty(loStats, "FailCount", This.aEndpoints[lnIndex, 8])
        
        Return loStats
    EndProc
    
    *---------------------------------------------------------------------------
    * Logging
    *---------------------------------------------------------------------------
    Protected Procedure Log(tcLevel, tcMessage)
        If VarType(This.oLogger) = 'O'
            Do Case
                Case tcLevel = "DEBUG"
                    This.oLogger.Debug(tcMessage)
                Case tcLevel = "INFO"
                    This.oLogger.Info(tcMessage)
                Case tcLevel = "WARNING"
                    This.oLogger.Warning(tcMessage)
                Case tcLevel = "ERROR"
                    This.oLogger.LogError(tcMessage)
            EndCase
        EndIf
    EndProc
    
    Protected Procedure Audit(tcAction, tcResource, tcDetails)
        If VarType(This.oAuditService) = 'O'
            This.oAuditService.Log("Webhook", tcAction, tcResource, tcDetails)
        EndIf
    EndProc
    
EndDefine


*******************************************************************************
* WebhookHandler - Clasă de bază pentru handleri
*******************************************************************************
Define Class WebhookHandler As Custom
    
    Procedure HandleWebhook(tcEventType, tcPayload)
        * Override în subclase
    EndProc
    
EndDefine


*******************************************************************************
* AnafWebhookHandler - Handler pentru notificări ANAF
*******************************************************************************
Define Class AnafWebhookHandler As WebhookHandler
    
    oEventDispatcher = .Null.
    
    Procedure HandleWebhook(tcEventType, tcPayload)
        * Parsează payload ANAF
        Local lcIdSolicitare, lcStatus
        
        * Dispatch event intern
        If VarType(This.oEventDispatcher) = 'O'
            This.oEventDispatcher.Dispatch("AnafNotification", tcPayload)
        EndIf
    EndProc
    
EndDefine
