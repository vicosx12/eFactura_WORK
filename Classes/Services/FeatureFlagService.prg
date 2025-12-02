*******************************************************************************
* FeatureFlagService.prg
* Serviciu pentru activare/dezactivare funcționalități fără deployment nou
* 
* Funcționalități:
* - Definire flag-uri cu valori boolean, string, numeric
* - Grupuri de utilizatori (rollout gradual)
* - Condiții temporale (active între date specifice)
* - Condiții contextuale (per tenant, per user, per environment)
* - Persistență în DBF sau JSON
* - Cache pentru performanță
* - Override local pentru dezvoltare
* - Audit log pentru modificări
*
* Exemplu utilizare:
*   loFlags = CreateObject("FeatureFlagService")
*   loFlags.LoadFromFile("features.json")
*   If loFlags.IsEnabled("NewXmlFormat")
*       * Folosește noul format
*   EndIf
*   lcValue = loFlags.GetValue("ApiTimeout", 30)
*******************************************************************************

Define Class FeatureFlagService As Custom
    
    * Storage flag-uri
    Dimension aFlags[1, 10]  && Name, Type, Value, Enabled, StartDate, EndDate, Tenants, Users, Environment, Description
    nFlagCount = 0
    
    * Cache
    Dimension aCache[1, 3]  && Key, Value, Timestamp
    nCacheCount = 0
    nCacheTTL = 300  && 5 minute
    
    * Configurare
    cStorageFile = ""
    cEnvironment = "PRODUCTION"
    cCurrentTenant = ""
    cCurrentUser = ""
    
    * Override-uri locale (pentru dezvoltare)
    Dimension aOverrides[1, 2]  && Name, Value
    nOverrideCount = 0
    lAllowOverrides = .T.
    
    * Logging
    oLogger = .Null.
    oAuditService = .Null.
    
    * Observer pentru schimbări
    Dimension aObservers[1]
    nObserverCount = 0
    
    *---------------------------------------------------------------------------
    Procedure Init
        This.cStorageFile = Sys(2023) + "\feature_flags.json"
        This.cEnvironment = Upper(Nvl(GetEnv("EFACTURA_ENV"), "PRODUCTION"))
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
    * Setează contextul curent
    *---------------------------------------------------------------------------
    Procedure SetContext(tcTenant, tcUser, tcEnvironment)
        This.cCurrentTenant = Nvl(tcTenant, "")
        This.cCurrentUser = Nvl(tcUser, "")
        If Not Empty(tcEnvironment)
            This.cEnvironment = Upper(tcEnvironment)
        EndIf
    EndProc
    
    *---------------------------------------------------------------------------
    * Definește un flag nou
    *---------------------------------------------------------------------------
    Procedure DefineFlag(tcName, tvDefaultValue, tcDescription, tlEnabled)
        Local lnIndex, lcType
        
        * Verifică dacă există deja
        lnIndex = This.FindFlagIndex(tcName)
        If lnIndex = 0
            This.nFlagCount = This.nFlagCount + 1
            lnIndex = This.nFlagCount
            Dimension This.aFlags[This.nFlagCount, 10]
        EndIf
        
        * Determină tipul
        Do Case
            Case VarType(tvDefaultValue) = 'L'
                lcType = "BOOLEAN"
            Case VarType(tvDefaultValue) = 'N'
                lcType = "NUMERIC"
            Case VarType(tvDefaultValue) = 'C'
                lcType = "STRING"
            Otherwise
                lcType = "STRING"
        EndCase
        
        This.aFlags[lnIndex, 1] = Upper(tcName)
        This.aFlags[lnIndex, 2] = lcType
        This.aFlags[lnIndex, 3] = tvDefaultValue
        This.aFlags[lnIndex, 4] = Iif(VarType(tlEnabled) = 'L', tlEnabled, .T.)
        This.aFlags[lnIndex, 5] = {^1900-01-01}  && StartDate
        This.aFlags[lnIndex, 6] = {^2099-12-31}  && EndDate
        This.aFlags[lnIndex, 7] = "*"            && Tenants (comma-separated, * = all)
        This.aFlags[lnIndex, 8] = "*"            && Users (comma-separated, * = all)
        This.aFlags[lnIndex, 9] = "*"            && Environment (* = all)
        This.aFlags[lnIndex, 10] = Nvl(tcDescription, "")
        
        This.InvalidateCache(tcName)
        This.Log("INFO", "Flag defined: " + tcName + " = " + Transform(tvDefaultValue))
        
        Return This  && Fluent
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează condiții temporale pentru un flag
    *---------------------------------------------------------------------------
    Procedure SetDateRange(tcName, tdStartDate, tdEndDate)
        Local lnIndex
        
        lnIndex = This.FindFlagIndex(tcName)
        If lnIndex > 0
            This.aFlags[lnIndex, 5] = tdStartDate
            This.aFlags[lnIndex, 6] = tdEndDate
            This.InvalidateCache(tcName)
        EndIf
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează restricții pe tenanți
    *---------------------------------------------------------------------------
    Procedure SetTenants(tcName, tcTenants)
        Local lnIndex
        
        lnIndex = This.FindFlagIndex(tcName)
        If lnIndex > 0
            This.aFlags[lnIndex, 7] = tcTenants
            This.InvalidateCache(tcName)
        EndIf
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează restricții pe utilizatori
    *---------------------------------------------------------------------------
    Procedure SetUsers(tcName, tcUsers)
        Local lnIndex
        
        lnIndex = This.FindFlagIndex(tcName)
        If lnIndex > 0
            This.aFlags[lnIndex, 8] = tcUsers
            This.InvalidateCache(tcName)
        EndIf
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează restricții pe environment
    *---------------------------------------------------------------------------
    Procedure SetEnvironment(tcName, tcEnvironment)
        Local lnIndex
        
        lnIndex = This.FindFlagIndex(tcName)
        If lnIndex > 0
            This.aFlags[lnIndex, 9] = Upper(tcEnvironment)
            This.InvalidateCache(tcName)
        EndIf
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Verifică dacă un flag boolean este activ
    *---------------------------------------------------------------------------
    Procedure IsEnabled(tcName, tlDefault)
        Local lnIndex, llEnabled, lvValue
        
        * Verifică override local
        If This.lAllowOverrides
            lvValue = This.GetOverride(tcName)
            If Not IsNull(lvValue)
                Return lvValue
            EndIf
        EndIf
        
        * Verifică cache
        lvValue = This.GetFromCache(tcName)
        If Not IsNull(lvValue)
            Return lvValue
        EndIf
        
        * Găsește flag-ul
        lnIndex = This.FindFlagIndex(tcName)
        If lnIndex = 0
            Return Iif(VarType(tlDefault) = 'L', tlDefault, .F.)
        EndIf
        
        * Verifică dacă flag-ul este activat global
        If Not This.aFlags[lnIndex, 4]
            This.AddToCache(tcName, .F.)
            Return .F.
        EndIf
        
        * Verifică condițiile
        llEnabled = This.EvaluateConditions(lnIndex)
        
        If llEnabled
            lvValue = This.aFlags[lnIndex, 3]
            If VarType(lvValue) = 'L'
                llEnabled = lvValue
            EndIf
        EndIf
        
        This.AddToCache(tcName, llEnabled)
        Return llEnabled
    EndProc
    
    *---------------------------------------------------------------------------
    * Obține valoarea unui flag
    *---------------------------------------------------------------------------
    Procedure GetValue(tcName, tvDefault)
        Local lnIndex, lvValue
        
        * Verifică override local
        If This.lAllowOverrides
            lvValue = This.GetOverride(tcName)
            If Not IsNull(lvValue)
                Return lvValue
            EndIf
        EndIf
        
        * Verifică cache
        lvValue = This.GetFromCache(tcName + "_VALUE")
        If Not IsNull(lvValue)
            Return lvValue
        EndIf
        
        * Găsește flag-ul
        lnIndex = This.FindFlagIndex(tcName)
        If lnIndex = 0
            Return tvDefault
        EndIf
        
        * Verifică dacă flag-ul este activ
        If Not This.aFlags[lnIndex, 4] Or Not This.EvaluateConditions(lnIndex)
            Return tvDefault
        EndIf
        
        lvValue = This.aFlags[lnIndex, 3]
        This.AddToCache(tcName + "_VALUE", lvValue)
        
        Return lvValue
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează valoarea unui flag
    *---------------------------------------------------------------------------
    Procedure SetValue(tcName, tvValue)
        Local lnIndex, lvOldValue
        
        lnIndex = This.FindFlagIndex(tcName)
        If lnIndex = 0
            This.DefineFlag(tcName, tvValue, "", .T.)
            lnIndex = This.nFlagCount
        EndIf
        
        lvOldValue = This.aFlags[lnIndex, 3]
        This.aFlags[lnIndex, 3] = tvValue
        
        This.InvalidateCache(tcName)
        This.NotifyObservers(tcName, lvOldValue, tvValue)
        This.Audit("SetValue", tcName, Transform(lvOldValue) + " -> " + Transform(tvValue))
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Activează/Dezactivează un flag
    *---------------------------------------------------------------------------
    Procedure Enable(tcName)
        Local lnIndex
        
        lnIndex = This.FindFlagIndex(tcName)
        If lnIndex > 0
            This.aFlags[lnIndex, 4] = .T.
            This.InvalidateCache(tcName)
            This.Audit("Enable", tcName, "")
            This.Log("INFO", "Flag enabled: " + tcName)
        EndIf
        
        Return This
    EndProc
    
    Procedure Disable(tcName)
        Local lnIndex
        
        lnIndex = This.FindFlagIndex(tcName)
        If lnIndex > 0
            This.aFlags[lnIndex, 4] = .F.
            This.InvalidateCache(tcName)
            This.Audit("Disable", tcName, "")
            This.Log("INFO", "Flag disabled: " + tcName)
        EndIf
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Override local pentru dezvoltare
    *---------------------------------------------------------------------------
    Procedure SetOverride(tcName, tvValue)
        Local lnIndex, i
        
        * Caută override existent
        lnIndex = 0
        For i = 1 To This.nOverrideCount
            If Upper(This.aOverrides[i, 1]) == Upper(tcName)
                lnIndex = i
                Exit
            EndIf
        EndFor
        
        If lnIndex = 0
            This.nOverrideCount = This.nOverrideCount + 1
            Dimension This.aOverrides[This.nOverrideCount, 2]
            lnIndex = This.nOverrideCount
        EndIf
        
        This.aOverrides[lnIndex, 1] = Upper(tcName)
        This.aOverrides[lnIndex, 2] = tvValue
        
        This.InvalidateCache(tcName)
        This.Log("DEBUG", "Override set: " + tcName + " = " + Transform(tvValue))
        
        Return This
    EndProc
    
    Procedure ClearOverride(tcName)
        Local i, j
        
        For i = 1 To This.nOverrideCount
            If Upper(This.aOverrides[i, 1]) == Upper(tcName)
                * Shift remaining overrides
                For j = i To This.nOverrideCount - 1
                    This.aOverrides[j, 1] = This.aOverrides[j + 1, 1]
                    This.aOverrides[j, 2] = This.aOverrides[j + 1, 2]
                EndFor
                This.nOverrideCount = This.nOverrideCount - 1
                Exit
            EndIf
        EndFor
        
        This.InvalidateCache(tcName)
        Return This
    EndProc
    
    Procedure ClearAllOverrides
        This.nOverrideCount = 0
        Dimension This.aOverrides[1, 2]
        This.InvalidateAllCache()
        Return This
    EndProc
    
    Protected Procedure GetOverride(tcName)
        Local i
        
        For i = 1 To This.nOverrideCount
            If Upper(This.aOverrides[i, 1]) == Upper(tcName)
                Return This.aOverrides[i, 2]
            EndIf
        EndFor
        
        Return .Null.
    EndProc
    
    *---------------------------------------------------------------------------
    * Evaluează condițiile pentru un flag
    *---------------------------------------------------------------------------
    Protected Procedure EvaluateConditions(tnIndex)
        Local ldToday, lcTenants, lcUsers, lcEnv
        
        ldToday = Date()
        
        * Verifică interval temporal
        If ldToday < This.aFlags[tnIndex, 5] Or ldToday > This.aFlags[tnIndex, 6]
            Return .F.
        EndIf
        
        * Verifică environment
        lcEnv = This.aFlags[tnIndex, 9]
        If lcEnv <> "*" And Not (Upper(This.cEnvironment) $ Upper(lcEnv))
            Return .F.
        EndIf
        
        * Verifică tenant
        lcTenants = This.aFlags[tnIndex, 7]
        If lcTenants <> "*" And Not Empty(This.cCurrentTenant)
            If Not (Upper(This.cCurrentTenant) $ Upper(lcTenants))
                Return .F.
            EndIf
        EndIf
        
        * Verifică user
        lcUsers = This.aFlags[tnIndex, 8]
        If lcUsers <> "*" And Not Empty(This.cCurrentUser)
            If Not (Upper(This.cCurrentUser) $ Upper(lcUsers))
                Return .F.
            EndIf
        EndIf
        
        Return .T.
    EndProc
    
    *---------------------------------------------------------------------------
    * Găsește indexul unui flag
    *---------------------------------------------------------------------------
    Protected Procedure FindFlagIndex(tcName)
        Local i
        
        For i = 1 To This.nFlagCount
            If Upper(This.aFlags[i, 1]) == Upper(tcName)
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
            If Upper(This.aCache[i, 1]) == Upper(tcKey)
                If Seconds() - This.aCache[i, 3] < This.nCacheTTL
                    Return This.aCache[i, 2]
                EndIf
            EndIf
        EndFor
        
        Return .Null.
    EndProc
    
    Protected Procedure AddToCache(tcKey, tvValue)
        Local lnIndex, i
        
        * Caută sau adaugă
        lnIndex = 0
        For i = 1 To This.nCacheCount
            If Upper(This.aCache[i, 1]) == Upper(tcKey)
                lnIndex = i
                Exit
            EndIf
        EndFor
        
        If lnIndex = 0
            This.nCacheCount = This.nCacheCount + 1
            Dimension This.aCache[This.nCacheCount, 3]
            lnIndex = This.nCacheCount
        EndIf
        
        This.aCache[lnIndex, 1] = Upper(tcKey)
        This.aCache[lnIndex, 2] = tvValue
        This.aCache[lnIndex, 3] = Seconds()
    EndProc
    
    Protected Procedure InvalidateCache(tcName)
        Local i
        
        For i = 1 To This.nCacheCount
            If Upper(tcName) $ Upper(This.aCache[i, 1])
                This.aCache[i, 3] = 0  && Expired
            EndIf
        EndFor
    EndProc
    
    Protected Procedure InvalidateAllCache
        This.nCacheCount = 0
        Dimension This.aCache[1, 3]
    EndProc
    
    *---------------------------------------------------------------------------
    * Observer pattern pentru notificări schimbări
    *---------------------------------------------------------------------------
    Procedure Attach(toObserver)
        This.nObserverCount = This.nObserverCount + 1
        Dimension This.aObservers[This.nObserverCount]
        This.aObservers[This.nObserverCount] = toObserver
    EndProc
    
    Protected Procedure NotifyObservers(tcFlagName, tvOldValue, tvNewValue)
        Local i
        
        For i = 1 To This.nObserverCount
            If VarType(This.aObservers[i]) = 'O'
                Try
                    This.aObservers[i].OnFlagChanged(tcFlagName, tvOldValue, tvNewValue)
                Catch
                EndTry
            EndIf
        EndFor
    EndProc
    
    *---------------------------------------------------------------------------
    * Salvare/Încărcare din fișier JSON
    *---------------------------------------------------------------------------
    Procedure SaveToFile(tcFileName)
        Local lcFile, lcContent, lnHandle, i
        
        lcFile = Iif(Empty(tcFileName), This.cStorageFile, tcFileName)
        
        lcContent = '{' + Chr(13) + Chr(10)
        lcContent = lcContent + '  "flags": [' + Chr(13) + Chr(10)
        
        For i = 1 To This.nFlagCount
            lcContent = lcContent + '    {' + Chr(13) + Chr(10)
            lcContent = lcContent + '      "name": "' + This.aFlags[i, 1] + '",' + Chr(13) + Chr(10)
            lcContent = lcContent + '      "type": "' + This.aFlags[i, 2] + '",' + Chr(13) + Chr(10)
            lcContent = lcContent + '      "value": ' + This.FormatJsonValue(This.aFlags[i, 3], This.aFlags[i, 2]) + ',' + Chr(13) + Chr(10)
            lcContent = lcContent + '      "enabled": ' + Iif(This.aFlags[i, 4], "true", "false") + ',' + Chr(13) + Chr(10)
            lcContent = lcContent + '      "startDate": "' + Dtoc(This.aFlags[i, 5]) + '",' + Chr(13) + Chr(10)
            lcContent = lcContent + '      "endDate": "' + Dtoc(This.aFlags[i, 6]) + '",' + Chr(13) + Chr(10)
            lcContent = lcContent + '      "tenants": "' + This.aFlags[i, 7] + '",' + Chr(13) + Chr(10)
            lcContent = lcContent + '      "users": "' + This.aFlags[i, 8] + '",' + Chr(13) + Chr(10)
            lcContent = lcContent + '      "environment": "' + This.aFlags[i, 9] + '",' + Chr(13) + Chr(10)
            lcContent = lcContent + '      "description": "' + This.aFlags[i, 10] + '"' + Chr(13) + Chr(10)
            lcContent = lcContent + '    }' + Iif(i < This.nFlagCount, ',', '') + Chr(13) + Chr(10)
        EndFor
        
        lcContent = lcContent + '  ]' + Chr(13) + Chr(10)
        lcContent = lcContent + '}'
        
        lnHandle = Fcreate(lcFile)
        If lnHandle > 0
            Fputs(lnHandle, lcContent)
            Fclose(lnHandle)
            This.Log("INFO", "Feature flags saved to: " + lcFile)
            Return .T.
        EndIf
        
        Return .F.
    EndProc
    
    Procedure LoadFromFile(tcFileName)
        Local lcFile, lcContent
        
        lcFile = Iif(Empty(tcFileName), This.cStorageFile, tcFileName)
        
        If Not File(lcFile)
            This.Log("WARNING", "Feature flags file not found: " + lcFile)
            Return .F.
        EndIf
        
        lcContent = FileToStr(lcFile)
        
        * Parse simplu - extrage flag-uri
        This.ParseJsonFlags(lcContent)
        
        This.Log("INFO", "Feature flags loaded from: " + lcFile + " (" + Transform(This.nFlagCount) + " flags)")
        Return .T.
    EndProc
    
    Protected Procedure FormatJsonValue(tvValue, tcType)
        Do Case
            Case tcType = "BOOLEAN"
                Return Iif(tvValue, "true", "false")
            Case tcType = "NUMERIC"
                Return Transform(tvValue)
            Otherwise
                Return '"' + Transform(tvValue) + '"'
        EndCase
    EndProc
    
    Protected Procedure ParseJsonFlags(tcJson)
        * Implementare simplificată - în producție folosiți un parser JSON complet
        Local lnPos, lcFlag, lcName, lcValue, lcEnabled
        
        lnPos = At('"name":', tcJson)
        Do While lnPos > 0
            * Extrage numele
            lcName = This.ExtractJsonStringValue(Substr(tcJson, lnPos))
            
            If Not Empty(lcName)
                This.DefineFlag(lcName, .F., "", .T.)
            EndIf
            
            lnPos = At('"name":', tcJson, lnPos + 1)
        EndDo
    EndProc
    
    Protected Procedure ExtractJsonStringValue(tcJson)
        Local lnStart, lnEnd, lcValue
        
        lnStart = At('":', tcJson) + 2
        lcValue = Alltrim(Substr(tcJson, lnStart))
        
        If Left(lcValue, 1) = '"'
            lnEnd = At('"', Substr(lcValue, 2))
            Return Substr(lcValue, 2, lnEnd - 1)
        EndIf
        
        Return ""
    EndProc
    
    *---------------------------------------------------------------------------
    * Returnează toate flag-urile
    *---------------------------------------------------------------------------
    Procedure GetAllFlags
        Local laResult[1, 4], i
        
        If This.nFlagCount = 0
            Return .Null.
        EndIf
        
        Dimension laResult[This.nFlagCount, 4]
        
        For i = 1 To This.nFlagCount
            laResult[i, 1] = This.aFlags[i, 1]   && Name
            laResult[i, 2] = This.aFlags[i, 3]   && Value
            laResult[i, 3] = This.aFlags[i, 4]   && Enabled
            laResult[i, 4] = This.aFlags[i, 10]  && Description
        EndFor
        
        Return @laResult
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
    
    Protected Procedure Audit(tcAction, tcFlag, tcDetails)
        If VarType(This.oAuditService) = 'O'
            This.oAuditService.Log("FeatureFlag", tcAction, tcFlag, tcDetails)
        EndIf
    EndProc
    
EndDefine
