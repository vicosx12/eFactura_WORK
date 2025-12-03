*******************************************************************************
* ApiGateway.prg
* Gateway API pentru agregare endpoint-uri, throttling și transformări
* 
* Funcționalități:
* - Routing request-uri către servicii backend
* - Rate limiting și throttling
* - Request/Response transformation
* - Caching responses
* - Load balancing (round-robin)
* - Health checks pentru backend-uri
* - Logging și metrici
* - Authentication/Authorization
*
* Exemplu utilizare:
*   loGateway = CreateObject("ApiGateway")
*   loGateway.RegisterRoute("/invoice/*", "InvoiceHandler")
*   loGateway.RegisterRoute("/status/*", "StatusHandler")
*   lcResponse = loGateway.HandleRequest("GET", "/invoice/123")
*******************************************************************************

Define Class ApiGateway As Custom
    
    * Rute definite
    Dimension aRoutes[1, 5]  && Pattern, HandlerClass, Methods, Auth, RateLimit
    nRouteCount = 0
    
    * Backend-uri
    Dimension aBackends[1, 5]  && Name, Url, Healthy, LastCheck, Weight
    nBackendCount = 0
    
    * Rate limiting
    Dimension aRateLimits[1, 4]  && ClientId, Requests, WindowStart, Limit
    nRateLimitCount = 0
    nDefaultRateLimit = 100  && requests per minute
    
    * Cache
    Dimension aResponseCache[1, 4]  && Key, Response, Timestamp, TTL
    nCacheCount = 0
    lCacheEnabled = .T.
    nDefaultCacheTTL = 60
    
    * Request context
    cCurrentClientId = ""
    cCurrentMethod = ""
    cCurrentPath = ""
    
    * Middleware chain
    Dimension aMiddleware[1]
    nMiddlewareCount = 0
    
    * Metrici
    nTotalRequests = 0
    nSuccessfulRequests = 0
    nFailedRequests = 0
    nCacheHits = 0
    nCacheMisses = 0
    
    * Logging
    oLogger = .Null.
    oMetricsCollector = .Null.
    
    *---------------------------------------------------------------------------
    Procedure Init
        This.Log("INFO", "API Gateway initialized")
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează logger-ul
    *---------------------------------------------------------------------------
    Procedure SetLogger(toLogger)
        This.oLogger = toLogger
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează colectorul de metrici
    *---------------------------------------------------------------------------
    Procedure SetMetricsCollector(toMetrics)
        This.oMetricsCollector = toMetrics
    EndProc
    
    *---------------------------------------------------------------------------
    * Înregistrează o rută
    *---------------------------------------------------------------------------
    Procedure RegisterRoute(tcPattern, tcHandler, tcMethods, tlAuth, tnRateLimit)
        This.nRouteCount = This.nRouteCount + 1
        Dimension This.aRoutes[This.nRouteCount, 5]
        
        This.aRoutes[This.nRouteCount, 1] = tcPattern
        This.aRoutes[This.nRouteCount, 2] = tcHandler
        This.aRoutes[This.nRouteCount, 3] = Iif(Empty(tcMethods), "GET,POST,PUT,DELETE", Upper(tcMethods))
        This.aRoutes[This.nRouteCount, 4] = Iif(VarType(tlAuth) = 'L', tlAuth, .F.)
        This.aRoutes[This.nRouteCount, 5] = Iif(VarType(tnRateLimit) = 'N', tnRateLimit, This.nDefaultRateLimit)
        
        This.Log("DEBUG", "Route registered: " + tcPattern + " -> " + tcHandler)
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Înregistrează un backend
    *---------------------------------------------------------------------------
    Procedure RegisterBackend(tcName, tcUrl, tnWeight)
        This.nBackendCount = This.nBackendCount + 1
        Dimension This.aBackends[This.nBackendCount, 5]
        
        This.aBackends[This.nBackendCount, 1] = tcName
        This.aBackends[This.nBackendCount, 2] = tcUrl
        This.aBackends[This.nBackendCount, 3] = .T.  && Healthy
        This.aBackends[This.nBackendCount, 4] = .Null.  && LastCheck
        This.aBackends[This.nBackendCount, 5] = Iif(VarType(tnWeight) = 'N', tnWeight, 1)
        
        This.Log("DEBUG", "Backend registered: " + tcName + " -> " + tcUrl)
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Adaugă middleware
    *---------------------------------------------------------------------------
    Procedure UseMiddleware(toMiddleware)
        This.nMiddlewareCount = This.nMiddlewareCount + 1
        Dimension This.aMiddleware[This.nMiddlewareCount]
        This.aMiddleware[This.nMiddlewareCount] = toMiddleware
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Procesează un request
    *---------------------------------------------------------------------------
    Procedure HandleRequest(tcMethod, tcPath, tcBody, tcHeaders, tcClientId)
        Local lcResponse, lnStartTime, lnRouteIndex
        Local llRateLimited, llCached, loHandler
        
        lnStartTime = Seconds()
        This.nTotalRequests = This.nTotalRequests + 1
        
        * Setează context
        This.cCurrentMethod = Upper(tcMethod)
        This.cCurrentPath = tcPath
        This.cCurrentClientId = Nvl(tcClientId, "anonymous")
        
        This.Log("DEBUG", "Request: " + tcMethod + " " + tcPath)
        
        Try
            * Verifică rate limiting
            If Not This.CheckRateLimit(This.cCurrentClientId)
                This.nFailedRequests = This.nFailedRequests + 1
                Return This.CreateErrorResponse(429, "Rate limit exceeded")
            EndIf
            
            * Găsește ruta
            lnRouteIndex = This.FindRoute(tcPath, tcMethod)
            
            If lnRouteIndex = 0
                This.nFailedRequests = This.nFailedRequests + 1
                Return This.CreateErrorResponse(404, "Route not found")
            EndIf
            
            * Verifică autentificarea
            If This.aRoutes[lnRouteIndex, 4] And Not This.Authenticate(tcHeaders)
                This.nFailedRequests = This.nFailedRequests + 1
                Return This.CreateErrorResponse(401, "Unauthorized")
            EndIf
            
            * Verifică cache (doar pentru GET)
            If This.lCacheEnabled And tcMethod = "GET"
                lcResponse = This.GetFromCache(tcPath)
                If Not Empty(lcResponse)
                    This.nCacheHits = This.nCacheHits + 1
                    This.nSuccessfulRequests = This.nSuccessfulRequests + 1
                    This.RecordMetrics(tcPath, Seconds() - lnStartTime, 200, .T.)
                    Return lcResponse
                EndIf
                This.nCacheMisses = This.nCacheMisses + 1
            EndIf
            
            * Execută middleware-urile
            If Not This.ExecuteMiddleware(tcMethod, tcPath, tcBody, tcHeaders)
                This.nFailedRequests = This.nFailedRequests + 1
                Return This.CreateErrorResponse(400, "Request blocked by middleware")
            EndIf
            
            * Găsește și execută handler-ul
            lcResponse = This.ExecuteHandler(This.aRoutes[lnRouteIndex, 2], tcMethod, tcPath, tcBody, tcHeaders)
            
            * Cache response
            If This.lCacheEnabled And tcMethod = "GET" And Not Empty(lcResponse)
                This.AddToCache(tcPath, lcResponse, This.nDefaultCacheTTL)
            EndIf
            
            This.nSuccessfulRequests = This.nSuccessfulRequests + 1
            This.RecordMetrics(tcPath, Seconds() - lnStartTime, 200, .F.)
            
            Return lcResponse
            
        Catch To loEx
            This.nFailedRequests = This.nFailedRequests + 1
            This.Log("ERROR", "Request failed: " + loEx.Message)
            This.RecordMetrics(tcPath, Seconds() - lnStartTime, 500, .F.)
            Return This.CreateErrorResponse(500, loEx.Message)
        EndTry
    EndProc
    
    *---------------------------------------------------------------------------
    * Găsește ruta potrivită
    *---------------------------------------------------------------------------
    Protected Procedure FindRoute(tcPath, tcMethod)
        Local i, lcPattern, lcMethods
        
        For i = 1 To This.nRouteCount
            lcPattern = This.aRoutes[i, 1]
            lcMethods = This.aRoutes[i, 3]
            
            * Verifică metoda
            If Not (Upper(tcMethod) $ lcMethods)
                Loop
            EndIf
            
            * Verifică pattern-ul
            If This.MatchPattern(tcPath, lcPattern)
                Return i
            EndIf
        EndFor
        
        Return 0
    EndProc
    
    *---------------------------------------------------------------------------
    * Verifică dacă path-ul se potrivește cu pattern-ul
    *---------------------------------------------------------------------------
    Protected Procedure MatchPattern(tcPath, tcPattern)
        Local lcRegexPattern
        
        * Convertește pattern la regex simplu
        * /invoice/* -> se potrivește cu orice după /invoice/
        * /invoice/:id -> se potrivește cu /invoice/123
        
        If tcPattern = "*"
            Return .T.
        EndIf
        
        If Right(tcPattern, 1) = "*"
            * Wildcard
            Return Left(tcPath, Len(tcPattern) - 1) == Left(tcPattern, Len(tcPattern) - 1)
        EndIf
        
        If ":" $ tcPattern
            * Parametru
            Local laParts1[1], laParts2[1], lnCount1, lnCount2, i
            
            lnCount1 = Alines(laParts1, tcPath, 1, "/")
            lnCount2 = Alines(laParts2, tcPattern, 1, "/")
            
            If lnCount1 <> lnCount2
                Return .F.
            EndIf
            
            For i = 1 To lnCount1
                If Left(laParts2[i], 1) <> ":"
                    If laParts1[i] <> laParts2[i]
                        Return .F.
                    EndIf
                EndIf
            EndFor
            
            Return .T.
        EndIf
        
        Return tcPath == tcPattern
    EndProc
    
    *---------------------------------------------------------------------------
    * Execută handler-ul
    *---------------------------------------------------------------------------
    Protected Procedure ExecuteHandler(tcHandlerClass, tcMethod, tcPath, tcBody, tcHeaders)
        Local loHandler, lcResponse
        
        Try
            loHandler = CreateObject(tcHandlerClass)
            
            Do Case
                Case tcMethod = "GET"
                    lcResponse = loHandler.HandleGet(tcPath, tcHeaders)
                Case tcMethod = "POST"
                    lcResponse = loHandler.HandlePost(tcPath, tcBody, tcHeaders)
                Case tcMethod = "PUT"
                    lcResponse = loHandler.HandlePut(tcPath, tcBody, tcHeaders)
                Case tcMethod = "DELETE"
                    lcResponse = loHandler.HandleDelete(tcPath, tcHeaders)
                Otherwise
                    lcResponse = loHandler.Handle(tcMethod, tcPath, tcBody, tcHeaders)
            EndCase
            
            Return lcResponse
            
        Catch To loEx
            This.Log("ERROR", "Handler error: " + loEx.Message)
            Return This.CreateErrorResponse(500, loEx.Message)
        EndTry
    EndProc
    
    *---------------------------------------------------------------------------
    * Execută middleware-urile
    *---------------------------------------------------------------------------
    Protected Procedure ExecuteMiddleware(tcMethod, tcPath, tcBody, tcHeaders)
        Local i, loMiddleware
        
        For i = 1 To This.nMiddlewareCount
            loMiddleware = This.aMiddleware[i]
            
            If VarType(loMiddleware) = 'O' And PemStatus(loMiddleware, "Process", 5)
                If Not loMiddleware.Process(tcMethod, tcPath, tcBody, tcHeaders)
                    Return .F.
                EndIf
            EndIf
        EndFor
        
        Return .T.
    EndProc
    
    *---------------------------------------------------------------------------
    * Verifică autentificarea
    *---------------------------------------------------------------------------
    Protected Procedure Authenticate(tcHeaders)
        Local lcAuth
        
        * Extrage Authorization header
        * Format: "Authorization: Bearer token123"
        lcAuth = This.ExtractHeader(tcHeaders, "Authorization")
        
        If Empty(lcAuth)
            Return .F.
        EndIf
        
        * Verifică token-ul
        If "Bearer " $ lcAuth
            Local lcToken
            lcToken = Substr(lcAuth, 8)
            Return This.ValidateToken(lcToken)
        EndIf
        
        Return .F.
    EndProc
    
    Protected Procedure ValidateToken(tcToken)
        * În producție, verificați token-ul JWT sau sesiunea
        Return Not Empty(tcToken)
    EndProc
    
    Protected Procedure ExtractHeader(tcHeaders, tcName)
        Local lnPos, lnEnd, lcValue
        
        lnPos = At(tcName + ":", tcHeaders)
        If lnPos > 0
            lnPos = lnPos + Len(tcName) + 1
            lnEnd = At(Chr(13), tcHeaders, lnPos)
            If lnEnd = 0
                lnEnd = Len(tcHeaders) + 1
            EndIf
            Return Alltrim(Substr(tcHeaders, lnPos, lnEnd - lnPos))
        EndIf
        
        Return ""
    EndProc
    
    *---------------------------------------------------------------------------
    * Rate limiting
    *---------------------------------------------------------------------------
    Protected Procedure CheckRateLimit(tcClientId)
        Local lnIndex, lnNow, lnWindowStart, lnRequests, lnLimit
        
        lnNow = Seconds()
        lnIndex = This.FindRateLimitEntry(tcClientId)
        
        If lnIndex = 0
            * Adaugă intrare nouă
            This.nRateLimitCount = This.nRateLimitCount + 1
            Dimension This.aRateLimits[This.nRateLimitCount, 4]
            lnIndex = This.nRateLimitCount
            
            This.aRateLimits[lnIndex, 1] = tcClientId
            This.aRateLimits[lnIndex, 2] = 1
            This.aRateLimits[lnIndex, 3] = lnNow
            This.aRateLimits[lnIndex, 4] = This.nDefaultRateLimit
            
            Return .T.
        EndIf
        
        lnWindowStart = This.aRateLimits[lnIndex, 3]
        lnRequests = This.aRateLimits[lnIndex, 2]
        lnLimit = This.aRateLimits[lnIndex, 4]
        
        * Verifică dacă fereastra a expirat (1 minut)
        If lnNow - lnWindowStart > 60
            * Reset window
            This.aRateLimits[lnIndex, 2] = 1
            This.aRateLimits[lnIndex, 3] = lnNow
            Return .T.
        EndIf
        
        * Verifică limita
        If lnRequests >= lnLimit
            This.Log("WARNING", "Rate limit exceeded for: " + tcClientId)
            Return .F.
        EndIf
        
        * Incrementează contorul
        This.aRateLimits[lnIndex, 2] = lnRequests + 1
        
        Return .T.
    EndProc
    
    Protected Procedure FindRateLimitEntry(tcClientId)
        Local i
        
        For i = 1 To This.nRateLimitCount
            If This.aRateLimits[i, 1] == tcClientId
                Return i
            EndIf
        EndFor
        
        Return 0
    EndProc
    
    *---------------------------------------------------------------------------
    * Cache management
    *---------------------------------------------------------------------------
    Protected Procedure GetFromCache(tcKey)
        Local i
        
        For i = 1 To This.nCacheCount
            If This.aResponseCache[i, 1] == tcKey
                If Seconds() - This.aResponseCache[i, 3] < This.aResponseCache[i, 4]
                    Return This.aResponseCache[i, 2]
                EndIf
            EndIf
        EndFor
        
        Return ""
    EndProc
    
    Protected Procedure AddToCache(tcKey, tcResponse, tnTTL)
        This.nCacheCount = This.nCacheCount + 1
        Dimension This.aResponseCache[This.nCacheCount, 4]
        
        This.aResponseCache[This.nCacheCount, 1] = tcKey
        This.aResponseCache[This.nCacheCount, 2] = tcResponse
        This.aResponseCache[This.nCacheCount, 3] = Seconds()
        This.aResponseCache[This.nCacheCount, 4] = tnTTL
    EndProc
    
    Procedure InvalidateCache(tcPattern)
        Local i
        
        For i = This.nCacheCount To 1 Step -1
            If tcPattern $ This.aResponseCache[i, 1] Or tcPattern = "*"
                This.aResponseCache[i, 3] = 0  && Expired
            EndIf
        EndFor
    EndProc
    
    *---------------------------------------------------------------------------
    * Creează response de eroare
    *---------------------------------------------------------------------------
    Protected Procedure CreateErrorResponse(tnStatus, tcMessage)
        Local lcResponse
        
        lcResponse = '{"error": true, "status": ' + Transform(tnStatus) + ', "message": "' + tcMessage + '"}'
        
        Return lcResponse
    EndProc
    
    *---------------------------------------------------------------------------
    * Înregistrează metrici
    *---------------------------------------------------------------------------
    Protected Procedure RecordMetrics(tcPath, tnDuration, tnStatus, tlCached)
        If VarType(This.oMetricsCollector) = 'O'
            This.oMetricsCollector.RecordCounter("api_requests_total", 1, "path", tcPath)
            This.oMetricsCollector.RecordHistogram("api_request_duration_seconds", tnDuration, "path", tcPath)
            
            If tlCached
                This.oMetricsCollector.RecordCounter("api_cache_hits_total", 1)
            EndIf
        EndIf
    EndProc
    
    *---------------------------------------------------------------------------
    * Health check pentru backend-uri
    *---------------------------------------------------------------------------
    Procedure CheckBackendHealth
        Local i, lcUrl, llHealthy
        
        For i = 1 To This.nBackendCount
            lcUrl = This.aBackends[i, 2] + "/health"
            
            Try
                Local loHttp
                loHttp = CreateObject("MSXML2.ServerXMLHTTP.6.0")
                loHttp.SetTimeouts(5000, 5000, 5000, 5000)
                loHttp.Open("GET", lcUrl, .F.)
                loHttp.Send()
                
                llHealthy = loHttp.Status = 200
                
            Catch
                llHealthy = .F.
            EndTry
            
            This.aBackends[i, 3] = llHealthy
            This.aBackends[i, 4] = Datetime()
            
            If Not llHealthy
                This.Log("WARNING", "Backend unhealthy: " + This.aBackends[i, 1])
            EndIf
        EndFor
    EndProc
    
    *---------------------------------------------------------------------------
    * Obține statistici
    *---------------------------------------------------------------------------
    Procedure GetStats
        Local loStats
        
        loStats = CreateObject("Empty")
        AddProperty(loStats, "TotalRequests", This.nTotalRequests)
        AddProperty(loStats, "SuccessfulRequests", This.nSuccessfulRequests)
        AddProperty(loStats, "FailedRequests", This.nFailedRequests)
        AddProperty(loStats, "CacheHits", This.nCacheHits)
        AddProperty(loStats, "CacheMisses", This.nCacheMisses)
        AddProperty(loStats, "CacheHitRate", ;
            Iif(This.nCacheHits + This.nCacheMisses > 0, ;
                Round(This.nCacheHits / (This.nCacheHits + This.nCacheMisses) * 100, 2), 0))
        
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
    
EndDefine


*******************************************************************************
* ApiHandler - Clasă de bază pentru handleri
*******************************************************************************
Define Class ApiHandler As Custom
    
    Procedure HandleGet(tcPath, tcHeaders)
        Return '{"method": "GET", "path": "' + tcPath + '"}'
    EndProc
    
    Procedure HandlePost(tcPath, tcBody, tcHeaders)
        Return '{"method": "POST", "path": "' + tcPath + '"}'
    EndProc
    
    Procedure HandlePut(tcPath, tcBody, tcHeaders)
        Return '{"method": "PUT", "path": "' + tcPath + '"}'
    EndProc
    
    Procedure HandleDelete(tcPath, tcHeaders)
        Return '{"method": "DELETE", "path": "' + tcPath + '"}'
    EndProc
    
    Procedure Handle(tcMethod, tcPath, tcBody, tcHeaders)
        Return '{"method": "' + tcMethod + '", "path": "' + tcPath + '"}'
    EndProc
    
EndDefine


*******************************************************************************
* ApiMiddleware - Clasă de bază pentru middleware
*******************************************************************************
Define Class ApiMiddleware As Custom
    
    Procedure Process(tcMethod, tcPath, tcBody, tcHeaders)
        Return .T.  && Continue processing
    EndProc
    
EndDefine
