*====================================================================
* PluginManager - Plugin Architecture for eFactura
* 
* Features:
* - Plugin discovery and loading
* - Lifecycle management (init, enable, disable, destroy)
* - Extension points (pre/post processing hooks)
* - Plugin configuration
* - Dependency management
*
* Visual FoxPro 9 SP2 Compatible
*====================================================================

Define Class PluginManager As Custom
    
    * Plugin registry
    Dimension aPlugins[1, 7]  && Id, Name, Version, Path, Instance, Enabled, Priority
    nPluginCount = 0
    
    * Extension points
    Dimension aExtensionPoints[1, 2]  && Name, Description
    nExtensionPointCount = 0
    
    * Registered hooks
    Dimension aHooks[1, 4]  && ExtensionPoint, PluginId, Method, Priority
    nHookCount = 0
    
    * Configuration
    cPluginsPath = ""
    lAutoDiscover = .T.
    lAutoEnable = .F.
    
    * Logger
    oLogger = .Null.
    
    *----------------------------------------------------------------
    * Init
    *----------------------------------------------------------------
    Procedure Init
        This.oLogger = CreateObject("LoggerService")
        This.cPluginsPath = AddBs(JustPath(Sys(16))) + "Plugins\"
        
        * Create plugins directory if needed
        If Not Directory(This.cPluginsPath)
            Mkdir (This.cPluginsPath)
        EndIf
        
        * Register default extension points
        This.RegisterExtensionPoints()
        
        * Auto-discover plugins
        If This.lAutoDiscover
            This.DiscoverPlugins()
        EndIf
    EndProc
    
    *----------------------------------------------------------------
    * RegisterExtensionPoints - Register default extension points
    *----------------------------------------------------------------
    Protected Procedure RegisterExtensionPoints
        * Invoice lifecycle hooks
        This.RegisterExtensionPoint("BeforeValidation", "Înainte de validare factură")
        This.RegisterExtensionPoint("AfterValidation", "După validare factură")
        This.RegisterExtensionPoint("BeforeXmlGeneration", "Înainte de generare XML")
        This.RegisterExtensionPoint("AfterXmlGeneration", "După generare XML")
        This.RegisterExtensionPoint("BeforeUpload", "Înainte de upload ANAF")
        This.RegisterExtensionPoint("AfterUpload", "După upload ANAF")
        This.RegisterExtensionPoint("BeforePersist", "Înainte de salvare")
        This.RegisterExtensionPoint("AfterPersist", "După salvare")
        
        * System hooks
        This.RegisterExtensionPoint("OnStartup", "La pornirea aplicației")
        This.RegisterExtensionPoint("OnShutdown", "La închiderea aplicației")
        This.RegisterExtensionPoint("OnError", "La apariția unei erori")
        This.RegisterExtensionPoint("OnConfigChange", "La modificarea configurației")
    EndProc
    
    *----------------------------------------------------------------
    * RegisterExtensionPoint - Register an extension point
    *----------------------------------------------------------------
    Procedure RegisterExtensionPoint(tcName, tcDescription)
        Local i
        
        * Check if already exists
        For i = 1 To This.nExtensionPointCount
            If This.aExtensionPoints[i, 1] = tcName
                Return i
            EndIf
        Next
        
        This.nExtensionPointCount = This.nExtensionPointCount + 1
        Dimension This.aExtensionPoints[This.nExtensionPointCount, 2]
        
        This.aExtensionPoints[This.nExtensionPointCount, 1] = tcName
        This.aExtensionPoints[This.nExtensionPointCount, 2] = tcDescription
        
        Return This.nExtensionPointCount
    EndProc
    
    *----------------------------------------------------------------
    * DiscoverPlugins - Auto-discover plugins in plugins folder
    *----------------------------------------------------------------
    Procedure DiscoverPlugins
        Local lnCount, i, lcPluginFile
        Dimension laFiles[1]
        
        lnCount = ADir(laFiles, AddBs(This.cPluginsPath) + "*.prg")
        
        For i = 1 To lnCount
            lcPluginFile = AddBs(This.cPluginsPath) + laFiles[i, 1]
            This.LoadPlugin(lcPluginFile)
        Next
        
        This.oLogger.LogInfo("Descoperite " + Transform(This.nPluginCount) + " plugin-uri")
    EndProc
    
    *----------------------------------------------------------------
    * LoadPlugin - Load a plugin from file
    *----------------------------------------------------------------
    Procedure LoadPlugin(tcPluginFile)
        Local loPlugin, lcPluginId, lcPluginName, lcPluginVersion
        
        If Not File(tcPluginFile)
            This.oLogger.LogError("Fișier plugin negăsit: " + tcPluginFile)
            Return .F.
        EndIf
        
        Try
            * Execute plugin file to define class
            Set Procedure To (tcPluginFile) Additive
            
            * Try to get plugin info from manifest or class
            lcPluginId = JustStem(tcPluginFile)
            
            * Try to instantiate plugin
            loPlugin = This.CreatePluginInstance(lcPluginId)
            
            If IsNull(loPlugin)
                This.oLogger.LogWarning("Nu s-a putut instanția plugin-ul: " + lcPluginId)
                Return .F.
            EndIf
            
            * Get plugin metadata
            lcPluginName = Iif(PemStatus(loPlugin, "cName", 5), loPlugin.cName, lcPluginId)
            lcPluginVersion = Iif(PemStatus(loPlugin, "cVersion", 5), loPlugin.cVersion, "1.0.0")
            
            * Register plugin
            This.RegisterPlugin(lcPluginId, lcPluginName, lcPluginVersion, tcPluginFile, loPlugin)
            
            This.oLogger.LogInfo("Plugin încărcat: " + lcPluginName + " v" + lcPluginVersion)
            
            Return .T.
        Catch
            This.oLogger.LogError("Eroare încărcare plugin " + tcPluginFile + ": " + Message())
            Return .F.
        EndTry
    EndProc
    
    *----------------------------------------------------------------
    * CreatePluginInstance - Create plugin instance
    *----------------------------------------------------------------
    Protected Procedure CreatePluginInstance(tcPluginId)
        Local loPlugin
        
        * Try different naming conventions
        Try
            loPlugin = CreateObject(tcPluginId + "Plugin")
            Return loPlugin
        Catch
        EndTry
        
        Try
            loPlugin = CreateObject(tcPluginId)
            Return loPlugin
        Catch
        EndTry
        
        Try
            loPlugin = CreateObject("Plugin_" + tcPluginId)
            Return loPlugin
        Catch
        EndTry
        
        Return .Null.
    EndProc
    
    *----------------------------------------------------------------
    * RegisterPlugin - Register a plugin
    *----------------------------------------------------------------
    Procedure RegisterPlugin(tcId, tcName, tcVersion, tcPath, toInstance)
        Local lnIndex, lnPriority
        
        lnIndex = This.FindPlugin(tcId)
        
        If lnIndex = 0
            This.nPluginCount = This.nPluginCount + 1
            lnIndex = This.nPluginCount
            Dimension This.aPlugins[This.nPluginCount, 7]
        EndIf
        
        * Get priority from plugin if available
        lnPriority = 100
        If Not IsNull(toInstance) And PemStatus(toInstance, "nPriority", 5)
            lnPriority = toInstance.nPriority
        EndIf
        
        This.aPlugins[lnIndex, 1] = tcId
        This.aPlugins[lnIndex, 2] = tcName
        This.aPlugins[lnIndex, 3] = tcVersion
        This.aPlugins[lnIndex, 4] = tcPath
        This.aPlugins[lnIndex, 5] = toInstance
        This.aPlugins[lnIndex, 6] = This.lAutoEnable
        This.aPlugins[lnIndex, 7] = lnPriority
        
        * Register plugin hooks
        If Not IsNull(toInstance)
            This.RegisterPluginHooks(tcId, toInstance)
        EndIf
        
        Return lnIndex
    EndProc
    
    *----------------------------------------------------------------
    * FindPlugin - Find plugin by ID
    *----------------------------------------------------------------
    Protected Procedure FindPlugin(tcId)
        Local i
        
        For i = 1 To This.nPluginCount
            If This.aPlugins[i, 1] = tcId
                Return i
            EndIf
        Next
        
        Return 0
    EndProc
    
    *----------------------------------------------------------------
    * RegisterPluginHooks - Register hooks from plugin
    *----------------------------------------------------------------
    Protected Procedure RegisterPluginHooks(tcPluginId, toPlugin)
        Local i
        
        * Check each extension point
        For i = 1 To This.nExtensionPointCount
            If PemStatus(toPlugin, "On" + This.aExtensionPoints[i, 1], 5)
                This.RegisterHook(This.aExtensionPoints[i, 1], tcPluginId, ;
                    "On" + This.aExtensionPoints[i, 1])
            EndIf
        Next
    EndProc
    
    *----------------------------------------------------------------
    * RegisterHook - Register a hook
    *----------------------------------------------------------------
    Procedure RegisterHook(tcExtensionPoint, tcPluginId, tcMethod, tnPriority)
        Local lnPluginIndex, lnPriority
        
        lnPluginIndex = This.FindPlugin(tcPluginId)
        
        If lnPluginIndex = 0
            Return .F.
        EndIf
        
        lnPriority = Evl(tnPriority, This.aPlugins[lnPluginIndex, 7])
        
        This.nHookCount = This.nHookCount + 1
        Dimension This.aHooks[This.nHookCount, 4]
        
        This.aHooks[This.nHookCount, 1] = tcExtensionPoint
        This.aHooks[This.nHookCount, 2] = tcPluginId
        This.aHooks[This.nHookCount, 3] = tcMethod
        This.aHooks[This.nHookCount, 4] = lnPriority
        
        Return .T.
    EndProc
    
    *----------------------------------------------------------------
    * EnablePlugin - Enable a plugin
    *----------------------------------------------------------------
    Procedure EnablePlugin(tcPluginId)
        Local lnIndex, loPlugin
        
        lnIndex = This.FindPlugin(tcPluginId)
        
        If lnIndex = 0
            Return .F.
        EndIf
        
        This.aPlugins[lnIndex, 6] = .T.
        
        * Call plugin OnEnable if exists
        loPlugin = This.aPlugins[lnIndex, 5]
        If Not IsNull(loPlugin) And PemStatus(loPlugin, "OnEnable", 5)
            loPlugin.OnEnable()
        EndIf
        
        This.oLogger.LogInfo("Plugin activat: " + This.aPlugins[lnIndex, 2])
        
        Return .T.
    EndProc
    
    *----------------------------------------------------------------
    * DisablePlugin - Disable a plugin
    *----------------------------------------------------------------
    Procedure DisablePlugin(tcPluginId)
        Local lnIndex, loPlugin
        
        lnIndex = This.FindPlugin(tcPluginId)
        
        If lnIndex = 0
            Return .F.
        EndIf
        
        * Call plugin OnDisable if exists
        loPlugin = This.aPlugins[lnIndex, 5]
        If Not IsNull(loPlugin) And PemStatus(loPlugin, "OnDisable", 5)
            loPlugin.OnDisable()
        EndIf
        
        This.aPlugins[lnIndex, 6] = .F.
        
        This.oLogger.LogInfo("Plugin dezactivat: " + This.aPlugins[lnIndex, 2])
        
        Return .T.
    EndProc
    
    *----------------------------------------------------------------
    * ExecuteHooks - Execute all hooks for extension point
    *----------------------------------------------------------------
    Procedure ExecuteHooks(tcExtensionPoint, toContext)
        Local i, j, loPlugin, lcMethod, lnIndex
        Dimension laHooks[1, 3]
        Local lnHookCount
        
        * Collect applicable hooks
        lnHookCount = 0
        
        For i = 1 To This.nHookCount
            If This.aHooks[i, 1] = tcExtensionPoint
                * Check if plugin is enabled
                lnIndex = This.FindPlugin(This.aHooks[i, 2])
                If lnIndex > 0 And This.aPlugins[lnIndex, 6]
                    lnHookCount = lnHookCount + 1
                    Dimension laHooks[lnHookCount, 3]
                    laHooks[lnHookCount, 1] = This.aHooks[i, 2]  && PluginId
                    laHooks[lnHookCount, 2] = This.aHooks[i, 3]  && Method
                    laHooks[lnHookCount, 3] = This.aHooks[i, 4]  && Priority
                EndIf
            EndIf
        Next
        
        * Sort by priority (simple bubble sort)
        This.SortHooksByPriority(@laHooks, lnHookCount)
        
        * Execute hooks in order
        For i = 1 To lnHookCount
            lnIndex = This.FindPlugin(laHooks[i, 1])
            
            If lnIndex > 0
                loPlugin = This.aPlugins[lnIndex, 5]
                lcMethod = laHooks[i, 2]
                
                Try
                    * Call hook method
                    =Evaluate("loPlugin." + lcMethod + "(toContext)")
                Catch
                    This.oLogger.LogError("Eroare executare hook " + lcMethod + ": " + Message())
                EndTry
            EndIf
        Next
        
        Return toContext
    EndProc
    
    *----------------------------------------------------------------
    * SortHooksByPriority - Sort hooks array by priority
    *----------------------------------------------------------------
    Protected Procedure SortHooksByPriority(laHooks, lnCount)
        Local i, j, lcTemp1, lcTemp2, lnTemp3
        
        For i = 1 To lnCount - 1
            For j = i + 1 To lnCount
                If laHooks[j, 3] < laHooks[i, 3]
                    * Swap
                    lcTemp1 = laHooks[i, 1]
                    lcTemp2 = laHooks[i, 2]
                    lnTemp3 = laHooks[i, 3]
                    
                    laHooks[i, 1] = laHooks[j, 1]
                    laHooks[i, 2] = laHooks[j, 2]
                    laHooks[i, 3] = laHooks[j, 3]
                    
                    laHooks[j, 1] = lcTemp1
                    laHooks[j, 2] = lcTemp2
                    laHooks[j, 3] = lnTemp3
                EndIf
            Next
        Next
    EndProc
    
    *----------------------------------------------------------------
    * GetPluginInfo - Get plugin information
    *----------------------------------------------------------------
    Procedure GetPluginInfo(tcPluginId)
        Local lnIndex, loInfo
        
        lnIndex = This.FindPlugin(tcPluginId)
        
        If lnIndex = 0
            Return .Null.
        EndIf
        
        loInfo = CreateObject("Empty")
        AddProperty(loInfo, "Id", This.aPlugins[lnIndex, 1])
        AddProperty(loInfo, "Name", This.aPlugins[lnIndex, 2])
        AddProperty(loInfo, "Version", This.aPlugins[lnIndex, 3])
        AddProperty(loInfo, "Path", This.aPlugins[lnIndex, 4])
        AddProperty(loInfo, "Enabled", This.aPlugins[lnIndex, 6])
        AddProperty(loInfo, "Priority", This.aPlugins[lnIndex, 7])
        
        Return loInfo
    EndProc
    
    *----------------------------------------------------------------
    * GetAllPlugins - Get list of all plugins
    *----------------------------------------------------------------
    Procedure GetAllPlugins
        Create Cursor PluginList ;
            (Id C(50), Name C(100), Version C(20), Path C(200), Enabled L, Priority I)
        
        Local i
        For i = 1 To This.nPluginCount
            Insert Into PluginList Values ;
                (This.aPlugins[i, 1], This.aPlugins[i, 2], This.aPlugins[i, 3], ;
                 This.aPlugins[i, 4], This.aPlugins[i, 6], This.aPlugins[i, 7])
        Next
        
        Return Reccount("PluginList") > 0
    EndProc
    
    *----------------------------------------------------------------
    * UnloadPlugin - Unload a plugin
    *----------------------------------------------------------------
    Procedure UnloadPlugin(tcPluginId)
        Local lnIndex, loPlugin
        
        lnIndex = This.FindPlugin(tcPluginId)
        
        If lnIndex = 0
            Return .F.
        EndIf
        
        * Call plugin OnDestroy if exists
        loPlugin = This.aPlugins[lnIndex, 5]
        If Not IsNull(loPlugin) And PemStatus(loPlugin, "OnDestroy", 5)
            loPlugin.OnDestroy()
        EndIf
        
        * Remove hooks
        This.RemovePluginHooks(tcPluginId)
        
        * Remove from registry
        This.aPlugins[lnIndex, 5] = .Null.
        This.aPlugins[lnIndex, 6] = .F.
        
        This.oLogger.LogInfo("Plugin descărcat: " + tcPluginId)
        
        Return .T.
    EndProc
    
    *----------------------------------------------------------------
    * RemovePluginHooks - Remove all hooks for plugin
    *----------------------------------------------------------------
    Protected Procedure RemovePluginHooks(tcPluginId)
        Local i, lnNewCount
        Dimension laNew[1, 4]
        
        lnNewCount = 0
        
        For i = 1 To This.nHookCount
            If This.aHooks[i, 2] <> tcPluginId
                lnNewCount = lnNewCount + 1
                Dimension laNew[lnNewCount, 4]
                laNew[lnNewCount, 1] = This.aHooks[i, 1]
                laNew[lnNewCount, 2] = This.aHooks[i, 2]
                laNew[lnNewCount, 3] = This.aHooks[i, 3]
                laNew[lnNewCount, 4] = This.aHooks[i, 4]
            EndIf
        Next
        
        This.nHookCount = lnNewCount
        Dimension This.aHooks[Max(1, lnNewCount), 4]
        
        For i = 1 To lnNewCount
            This.aHooks[i, 1] = laNew[i, 1]
            This.aHooks[i, 2] = laNew[i, 2]
            This.aHooks[i, 3] = laNew[i, 3]
            This.aHooks[i, 4] = laNew[i, 4]
        Next
    EndProc
    
    *----------------------------------------------------------------
    * ReloadPlugin - Reload a plugin
    *----------------------------------------------------------------
    Procedure ReloadPlugin(tcPluginId)
        Local lnIndex, lcPath
        
        lnIndex = This.FindPlugin(tcPluginId)
        
        If lnIndex = 0
            Return .F.
        EndIf
        
        lcPath = This.aPlugins[lnIndex, 4]
        
        This.UnloadPlugin(tcPluginId)
        
        Return This.LoadPlugin(lcPath)
    EndProc
    
    *----------------------------------------------------------------
    * Destroy - Cleanup on destroy
    *----------------------------------------------------------------
    Procedure Destroy
        Local i
        
        * Unload all plugins
        For i = 1 To This.nPluginCount
            This.UnloadPlugin(This.aPlugins[i, 1])
        Next
    EndProc

EndDefine


*====================================================================
* BasePlugin - Base class for plugins
*====================================================================

Define Class BasePlugin As Custom
    
    cName = "BasePlugin"
    cVersion = "1.0.0"
    cDescription = ""
    cAuthor = ""
    nPriority = 100
    lEnabled = .F.
    
    oLogger = .Null.
    oConfig = .Null.
    
    *----------------------------------------------------------------
    * Init
    *----------------------------------------------------------------
    Procedure Init
        This.oLogger = CreateObject("LoggerService")
    EndProc
    
    *----------------------------------------------------------------
    * OnEnable - Called when plugin is enabled
    *----------------------------------------------------------------
    Procedure OnEnable
        This.lEnabled = .T.
    EndProc
    
    *----------------------------------------------------------------
    * OnDisable - Called when plugin is disabled
    *----------------------------------------------------------------
    Procedure OnDisable
        This.lEnabled = .F.
    EndProc
    
    *----------------------------------------------------------------
    * OnDestroy - Called when plugin is unloaded
    *----------------------------------------------------------------
    Procedure OnDestroy
        * Cleanup resources
    EndProc
    
    *----------------------------------------------------------------
    * GetInfo - Get plugin information
    *----------------------------------------------------------------
    Procedure GetInfo
        Local loInfo
        
        loInfo = CreateObject("Empty")
        AddProperty(loInfo, "Name", This.cName)
        AddProperty(loInfo, "Version", This.cVersion)
        AddProperty(loInfo, "Description", This.cDescription)
        AddProperty(loInfo, "Author", This.cAuthor)
        AddProperty(loInfo, "Priority", This.nPriority)
        AddProperty(loInfo, "Enabled", This.lEnabled)
        
        Return loInfo
    EndProc

EndDefine
