*====================================================================
* ConfigHotReload - Configuration Hot Reload Service
* 
* Features:
* - Watch configuration file for changes
* - Automatically reload settings without restart
* - Notify observers on config change
*
* Visual FoxPro 9 SP2 Compatible
*====================================================================

Define Class ConfigHotReload As Custom
    
    * Configuration
    cConfigFile = ""
    nCheckInterval = 5  && seconds
    lEnabled = .T.
    lWatching = .F.
    
    * File state tracking
    dLastModified = {}
    nLastSize = 0
    cLastHash = ""
    
    * Timer for periodic checking (using BINDEVENT alternative)
    nTimerId = 0
    nLastCheck = 0
    
    * Observers for config changes
    Dimension aObservers[1]
    nObserverCount = 0
    
    * Current configuration cache
    Dimension aConfig[1, 2]
    nConfigCount = 0
    
    * Logger
    oLogger = .Null.
    
    *----------------------------------------------------------------
    * Init
    *----------------------------------------------------------------
    Procedure Init
        This.oLogger = CreateObject("LoggerService")
        This.cConfigFile = AddBs(JustPath(Sys(16))) + "efactura.config"
        
        * Load initial configuration
        This.LoadConfiguration()
    EndProc
    
    *----------------------------------------------------------------
    * SetConfigFile - Set configuration file path
    *----------------------------------------------------------------
    Procedure SetConfigFile(tcFilePath)
        This.cConfigFile = tcFilePath
        This.LoadConfiguration()
    EndProc
    
    *----------------------------------------------------------------
    * StartWatching - Start watching for changes
    *----------------------------------------------------------------
    Procedure StartWatching
        If This.lWatching
            Return
        EndIf
        
        * Record initial file state
        This.RecordFileState()
        
        This.lWatching = .T.
        This.nLastCheck = Seconds()
        
        This.oLogger.LogInfo("Pornit monitorizare configurație: " + This.cConfigFile)
    EndProc
    
    *----------------------------------------------------------------
    * StopWatching - Stop watching for changes
    *----------------------------------------------------------------
    Procedure StopWatching
        This.lWatching = .F.
        This.oLogger.LogInfo("Oprit monitorizare configurație")
    EndProc
    
    *----------------------------------------------------------------
    * CheckForChanges - Check if config file has changed
    *----------------------------------------------------------------
    Procedure CheckForChanges
        Local ldModified, lnSize, lcHash
        
        If Not This.lEnabled Or Not This.lWatching
            Return .F.
        EndIf
        
        If Not File(This.cConfigFile)
            Return .F.
        EndIf
        
        * Get current file state
        ldModified = FDate(This.cConfigFile, 1)
        lnSize = FSize(This.cConfigFile)
        
        * Check if changed
        If ldModified <> This.dLastModified Or lnSize <> This.nLastSize
            * Verify with hash
            lcHash = This.GetFileHash()
            
            If lcHash <> This.cLastHash
                This.oLogger.LogInfo("Detectată schimbare în configurație")
                
                * Reload configuration
                This.LoadConfiguration()
                
                * Record new state
                This.RecordFileState()
                
                * Notify observers
                This.NotifyConfigChanged()
                
                Return .T.
            EndIf
        EndIf
        
        Return .F.
    EndProc
    
    *----------------------------------------------------------------
    * Poll - Manual poll for changes (call from timer or loop)
    *----------------------------------------------------------------
    Procedure Poll
        If Seconds() - This.nLastCheck >= This.nCheckInterval
            This.nLastCheck = Seconds()
            Return This.CheckForChanges()
        EndIf
        Return .F.
    EndProc
    
    *----------------------------------------------------------------
    * RecordFileState - Record current file state
    *----------------------------------------------------------------
    Protected Procedure RecordFileState
        If File(This.cConfigFile)
            This.dLastModified = FDate(This.cConfigFile, 1)
            This.nLastSize = FSize(This.cConfigFile)
            This.cLastHash = This.GetFileHash()
        EndIf
    EndProc
    
    *----------------------------------------------------------------
    * GetFileHash - Calculate simple hash of file content
    *----------------------------------------------------------------
    Protected Procedure GetFileHash
        Local lcContent, lnHash, i
        
        If Not File(This.cConfigFile)
            Return ""
        EndIf
        
        lcContent = FileToStr(This.cConfigFile)
        lnHash = 0
        
        * Simple hash algorithm
        For i = 1 To Min(Len(lcContent), 1000)
            lnHash = (lnHash * 31 + Asc(Substr(lcContent, i, 1))) % 2147483647
        Next
        
        Return Transform(lnHash)
    EndProc
    
    *----------------------------------------------------------------
    * LoadConfiguration - Load configuration from file
    *----------------------------------------------------------------
    Protected Procedure LoadConfiguration
        Local lcContent, lnLines, i
        Dimension laLines[1]
        
        This.nConfigCount = 0
        Dimension This.aConfig[1, 2]
        
        If Not File(This.cConfigFile)
            This.oLogger.LogWarning("Fișier configurație negăsit: " + This.cConfigFile)
            Return .F.
        EndIf
        
        lcContent = FileToStr(This.cConfigFile)
        lnLines = ALines(laLines, lcContent, .T.)
        
        For i = 1 To lnLines
            This.ParseConfigLine(laLines[i])
        Next
        
        This.oLogger.LogInfo("Încărcate " + Transform(This.nConfigCount) + " setări din configurație")
        
        Return .T.
    EndProc
    
    *----------------------------------------------------------------
    * ParseConfigLine - Parse single config line
    *----------------------------------------------------------------
    Protected Procedure ParseConfigLine(tcLine)
        Local lcLine, lnPos, lcKey, lcValue
        
        lcLine = Alltrim(tcLine)
        
        * Skip empty lines and comments
        If Empty(lcLine) Or Left(lcLine, 1) $ "#;["
            Return
        EndIf
        
        * Find separator
        lnPos = At("=", lcLine)
        If lnPos = 0
            Return
        EndIf
        
        lcKey = Alltrim(Left(lcLine, lnPos - 1))
        lcValue = Alltrim(Substr(lcLine, lnPos + 1))
        
        * Remove quotes if present
        If (Left(lcValue, 1) = '"' And Right(lcValue, 1) = '"') Or ;
           (Left(lcValue, 1) = "'" And Right(lcValue, 1) = "'")
            lcValue = Substr(lcValue, 2, Len(lcValue) - 2)
        EndIf
        
        * Store configuration
        This.SetValue(lcKey, lcValue, .T.)  && Silent mode during load
    EndProc
    
    *----------------------------------------------------------------
    * GetValue - Get configuration value
    *----------------------------------------------------------------
    Procedure GetValue(tcKey, tcDefault)
        Local i
        
        For i = 1 To This.nConfigCount
            If Lower(This.aConfig[i, 1]) = Lower(tcKey)
                Return This.aConfig[i, 2]
            EndIf
        Next
        
        Return Evl(tcDefault, "")
    EndProc
    
    *----------------------------------------------------------------
    * SetValue - Set configuration value
    *----------------------------------------------------------------
    Procedure SetValue(tcKey, tcValue, tlSilent)
        Local i, llFound
        
        llFound = .F.
        
        * Update existing
        For i = 1 To This.nConfigCount
            If Lower(This.aConfig[i, 1]) = Lower(tcKey)
                This.aConfig[i, 2] = tcValue
                llFound = .T.
                Exit
            EndIf
        Next
        
        * Add new
        If Not llFound
            This.nConfigCount = This.nConfigCount + 1
            Dimension This.aConfig[This.nConfigCount, 2]
            This.aConfig[This.nConfigCount, 1] = tcKey
            This.aConfig[This.nConfigCount, 2] = tcValue
        EndIf
        
        * Notify change if not silent
        If Not tlSilent
            This.NotifyConfigChanged()
        EndIf
    EndProc
    
    *----------------------------------------------------------------
    * SaveConfiguration - Save configuration to file
    *----------------------------------------------------------------
    Procedure SaveConfiguration
        Local lcContent, i
        
        lcContent = "# eFactura Configuration" + Chr(13) + Chr(10)
        lcContent = lcContent + "# Last modified: " + Ttoc(DateTime()) + Chr(13) + Chr(10)
        lcContent = lcContent + Chr(13) + Chr(10)
        
        For i = 1 To This.nConfigCount
            lcContent = lcContent + This.aConfig[i, 1] + "=" + This.aConfig[i, 2] + Chr(13) + Chr(10)
        Next
        
        StrToFile(lcContent, This.cConfigFile)
        
        * Update file state
        This.RecordFileState()
        
        This.oLogger.LogInfo("Configurație salvată")
    EndProc
    
    *----------------------------------------------------------------
    * AttachObserver - Attach config change observer
    *----------------------------------------------------------------
    Procedure AttachObserver(toObserver)
        This.nObserverCount = This.nObserverCount + 1
        Dimension This.aObservers[This.nObserverCount]
        This.aObservers[This.nObserverCount] = toObserver
    EndProc
    
    *----------------------------------------------------------------
    * DetachObserver - Detach config change observer
    *----------------------------------------------------------------
    Procedure DetachObserver(toObserver)
        Local i, lnNewCount
        Dimension laNew[1]
        
        lnNewCount = 0
        
        For i = 1 To This.nObserverCount
            If Not This.aObservers[i] == toObserver
                lnNewCount = lnNewCount + 1
                Dimension laNew[lnNewCount]
                laNew[lnNewCount] = This.aObservers[i]
            EndIf
        Next
        
        This.nObserverCount = lnNewCount
        Dimension This.aObservers[Max(1, lnNewCount)]
        
        For i = 1 To lnNewCount
            This.aObservers[i] = laNew[i]
        Next
    EndProc
    
    *----------------------------------------------------------------
    * NotifyConfigChanged - Notify all observers of config change
    *----------------------------------------------------------------
    Protected Procedure NotifyConfigChanged
        Local i
        
        For i = 1 To This.nObserverCount
            If VarType(This.aObservers[i]) = 'O' And ;
               PemStatus(This.aObservers[i], "OnConfigChanged", 5)
                This.aObservers[i].OnConfigChanged(This)
            EndIf
        Next
    EndProc
    
    *----------------------------------------------------------------
    * GetAllSettings - Get all settings as collection
    *----------------------------------------------------------------
    Procedure GetAllSettings
        Local loSettings, i
        
        loSettings = CreateObject("Collection")
        
        For i = 1 To This.nConfigCount
            loSettings.Add(This.aConfig[i, 2], This.aConfig[i, 1])
        Next
        
        Return loSettings
    EndProc
    
    *----------------------------------------------------------------
    * Reload - Force reload configuration
    *----------------------------------------------------------------
    Procedure Reload
        This.LoadConfiguration()
        This.RecordFileState()
        This.NotifyConfigChanged()
    EndProc

EndDefine


*====================================================================
* ConfigChangeObserver - Example observer for config changes
*====================================================================

Define Class ConfigChangeObserver As Custom
    
    cName = "ConfigChangeObserver"
    
    Procedure OnConfigChanged(toConfigService)
        * Override this method in subclasses
        ? "Configuration changed at " + Time()
    EndProc

EndDefine
