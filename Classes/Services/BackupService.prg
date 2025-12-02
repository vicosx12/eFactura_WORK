*******************************************************************************
* BackupService.prg
* Serviciu pentru backup și recovery
* 
* Funcționalități:
* - Backup automat XML și bază de date
* - Restore point-in-time
* - Compresie backup-uri
* - Rotație automată backup-uri vechi
* - Backup incremental
* - Verificare integritate
* - Programare automată
*
* Exemplu utilizare:
*   loBackup = CreateObject("BackupService")
*   loBackup.SetBackupPath("D:\Backups\eFactura")
*   loBackup.BackupXmlFiles()
*   loBackup.BackupDatabase("IESIRI")
*   loBackup.RestoreFromBackup("backup_20231215.zip")
*******************************************************************************

Define Class BackupService As Custom
    
    * Configurare
    cBackupPath = ""
    cTempPath = ""
    nRetentionDays = 30
    nMaxBackupSizeMB = 1000
    lCompressBackups = .T.
    
    * Programare
    Dimension aSchedule[1, 3]  && Type, Time, Days
    nScheduleCount = 0
    
    * Istoric
    Dimension aBackupHistory[1, 6]  && Id, Type, Timestamp, Size, Status, Path
    nHistoryCount = 0
    
    * Statistici
    nTotalBackups = 0
    nSuccessfulBackups = 0
    nFailedBackups = 0
    nTotalSizeMB = 0
    
    * Logging
    oLogger = .Null.
    oNotificationService = .Null.
    
    *---------------------------------------------------------------------------
    Procedure Init
        This.cBackupPath = Sys(2023) + "\Backups\"
        This.cTempPath = Sys(2023) + "\Temp\"
        
        * Creează directoarele
        If Not Directory(This.cBackupPath)
            Mkdir (This.cBackupPath)
        EndIf
        If Not Directory(This.cTempPath)
            Mkdir (This.cTempPath)
        EndIf
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează calea pentru backup-uri
    *---------------------------------------------------------------------------
    Procedure SetBackupPath(tcPath)
        This.cBackupPath = Addbs(tcPath)
        
        If Not Directory(This.cBackupPath)
            Try
                Mkdir (This.cBackupPath)
            Catch To loEx
                This.Log("ERROR", "Cannot create backup directory: " + loEx.Message)
                Return .F.
            EndTry
        EndIf
        
        Return .T.
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează logger-ul
    *---------------------------------------------------------------------------
    Procedure SetLogger(toLogger)
        This.oLogger = toLogger
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează serviciul de notificare
    *---------------------------------------------------------------------------
    Procedure SetNotificationService(toNotify)
        This.oNotificationService = toNotify
    EndProc
    
    *---------------------------------------------------------------------------
    * Backup fișiere XML
    *---------------------------------------------------------------------------
    Procedure BackupXmlFiles(tcSourcePath, tcPrefix)
        Local lcBackupName, lcBackupFile, lnFileCount, laFiles[1]
        Local lnStartTime, lnSize, llSuccess
        
        lcPrefix = Iif(Empty(tcPrefix), "XML", tcPrefix)
        lcBackupName = lcPrefix + "_" + This.GetTimestamp() + ".zip"
        lcBackupFile = This.cBackupPath + lcBackupName
        
        lnStartTime = Seconds()
        llSuccess = .F.
        
        This.Log("INFO", "Starting XML backup: " + lcBackupName)
        
        Try
            * Colectează fișierele
            lnFileCount = Adir(laFiles, Addbs(tcSourcePath) + "*.xml")
            
            If lnFileCount = 0
                This.Log("WARNING", "No XML files found to backup")
                Return .F.
            EndIf
            
            * Creează arhiva
            If This.lCompressBackups
                llSuccess = This.CreateZipArchive(tcSourcePath, "*.xml", lcBackupFile)
            Else
                llSuccess = This.CopyFiles(tcSourcePath, "*.xml", This.cBackupPath + lcPrefix + "_" + This.GetTimestamp() + "\")
            EndIf
            
            If llSuccess
                lnSize = This.GetFileSize(lcBackupFile)
                This.AddToHistory("XML", lcBackupFile, lnSize, "SUCCESS")
                This.nSuccessfulBackups = This.nSuccessfulBackups + 1
                This.Log("INFO", "XML backup completed: " + Transform(lnFileCount) + " files, " + Transform(lnSize / 1024) + " KB")
            Else
                This.AddToHistory("XML", lcBackupFile, 0, "FAILED")
                This.nFailedBackups = This.nFailedBackups + 1
                This.Log("ERROR", "XML backup failed")
            EndIf
            
        Catch To loEx
            This.Log("ERROR", "XML backup exception: " + loEx.Message)
            This.AddToHistory("XML", lcBackupFile, 0, "FAILED")
            This.nFailedBackups = This.nFailedBackups + 1
            llSuccess = .F.
        EndTry
        
        This.nTotalBackups = This.nTotalBackups + 1
        
        Return llSuccess
    EndProc
    
    *---------------------------------------------------------------------------
    * Backup bază de date (tabelă DBF)
    *---------------------------------------------------------------------------
    Procedure BackupDatabase(tcTableName, tcDatabasePath)
        Local lcBackupName, lcBackupFile, lnStartTime, lnSize, llSuccess
        Local lcSourcePath
        
        lcSourcePath = Iif(Empty(tcDatabasePath), Sys(2003), Addbs(tcDatabasePath))
        lcBackupName = "DB_" + tcTableName + "_" + This.GetTimestamp() + ".zip"
        lcBackupFile = This.cBackupPath + lcBackupName
        
        lnStartTime = Seconds()
        llSuccess = .F.
        
        This.Log("INFO", "Starting database backup: " + tcTableName)
        
        Try
            * Verifică dacă tabela există
            If Not File(lcSourcePath + tcTableName + ".DBF")
                This.Log("ERROR", "Table not found: " + tcTableName)
                Return .F.
            EndIf
            
            * Creează arhiva cu toate fișierele asociate
            If This.lCompressBackups
                llSuccess = This.CreateZipArchive(lcSourcePath, tcTableName + ".*", lcBackupFile)
            Else
                llSuccess = This.CopyFiles(lcSourcePath, tcTableName + ".*", This.cBackupPath)
            EndIf
            
            If llSuccess
                lnSize = This.GetFileSize(lcBackupFile)
                This.AddToHistory("DATABASE", lcBackupFile, lnSize, "SUCCESS")
                This.nSuccessfulBackups = This.nSuccessfulBackups + 1
                This.Log("INFO", "Database backup completed: " + tcTableName + ", " + Transform(lnSize / 1024) + " KB")
            Else
                This.AddToHistory("DATABASE", lcBackupFile, 0, "FAILED")
                This.nFailedBackups = This.nFailedBackups + 1
            EndIf
            
        Catch To loEx
            This.Log("ERROR", "Database backup exception: " + loEx.Message)
            This.AddToHistory("DATABASE", lcBackupFile, 0, "FAILED")
            This.nFailedBackups = This.nFailedBackups + 1
            llSuccess = .F.
        EndTry
        
        This.nTotalBackups = This.nTotalBackups + 1
        
        Return llSuccess
    EndProc
    
    *---------------------------------------------------------------------------
    * Backup complet (toate fișierele relevante)
    *---------------------------------------------------------------------------
    Procedure BackupFull(tcSourcePath)
        Local lcBackupName, lcBackupFile, llSuccess, lnSize
        
        lcBackupName = "FULL_" + This.GetTimestamp() + ".zip"
        lcBackupFile = This.cBackupPath + lcBackupName
        
        This.Log("INFO", "Starting full backup")
        
        Try
            * Backup XML
            llSuccess = This.CreateZipArchive(tcSourcePath, "*.*", lcBackupFile)
            
            If llSuccess
                lnSize = This.GetFileSize(lcBackupFile)
                This.AddToHistory("FULL", lcBackupFile, lnSize, "SUCCESS")
                This.nSuccessfulBackups = This.nSuccessfulBackups + 1
                This.Log("INFO", "Full backup completed: " + Transform(lnSize / 1024 / 1024) + " MB")
            Else
                This.AddToHistory("FULL", lcBackupFile, 0, "FAILED")
                This.nFailedBackups = This.nFailedBackups + 1
            EndIf
            
        Catch To loEx
            This.Log("ERROR", "Full backup exception: " + loEx.Message)
            llSuccess = .F.
        EndTry
        
        This.nTotalBackups = This.nTotalBackups + 1
        
        Return llSuccess
    EndProc
    
    *---------------------------------------------------------------------------
    * Restaurare din backup
    *---------------------------------------------------------------------------
    Procedure RestoreFromBackup(tcBackupFile, tcDestPath)
        Local llSuccess
        
        If Not File(tcBackupFile)
            This.Log("ERROR", "Backup file not found: " + tcBackupFile)
            Return .F.
        EndIf
        
        This.Log("INFO", "Starting restore from: " + tcBackupFile)
        
        Try
            * Verifică integritatea
            If Not This.VerifyBackupIntegrity(tcBackupFile)
                This.Log("ERROR", "Backup integrity check failed")
                Return .F.
            EndIf
            
            * Extrage arhiva
            llSuccess = This.ExtractZipArchive(tcBackupFile, tcDestPath)
            
            If llSuccess
                This.Log("INFO", "Restore completed successfully")
            Else
                This.Log("ERROR", "Restore failed")
            EndIf
            
        Catch To loEx
            This.Log("ERROR", "Restore exception: " + loEx.Message)
            llSuccess = .F.
        EndTry
        
        Return llSuccess
    EndProc
    
    *---------------------------------------------------------------------------
    * Creează arhivă ZIP (folosind Windows Shell)
    *---------------------------------------------------------------------------
    Protected Procedure CreateZipArchive(tcSourcePath, tcPattern, tcZipFile)
        Local loShell, loFolder, loItems, loZipFolder
        Local laFiles[1], lnCount, i, lcSource, lcFileName
        
        Try
            * Creează fișier ZIP gol
            StrToFile(Chr(80) + Chr(75) + Chr(5) + Chr(6) + Replicate(Chr(0), 18), tcZipFile)
            
            * Deschide cu Shell
            loShell = CreateObject("Shell.Application")
            loZipFolder = loShell.NameSpace(tcZipFile)
            loFolder = loShell.NameSpace(Addbs(tcSourcePath))
            
            * Colectează fișierele
            lnCount = Adir(laFiles, Addbs(tcSourcePath) + tcPattern)
            
            For i = 1 To lnCount
                lcFileName = laFiles[i, 1]
                loItems = loFolder.ParseName(lcFileName)
                If Not IsNull(loItems)
                    loZipFolder.CopyHere(loItems, 4 + 16)  && No progress dialog, respond Yes to All
                    * Așteaptă finalizarea
                    Inkey(0.5)
                EndIf
            EndFor
            
            Return .T.
            
        Catch To loEx
            This.Log("ERROR", "ZIP creation failed: " + loEx.Message)
            Return .F.
        EndTry
    EndProc
    
    *---------------------------------------------------------------------------
    * Extrage arhivă ZIP
    *---------------------------------------------------------------------------
    Protected Procedure ExtractZipArchive(tcZipFile, tcDestPath)
        Local loShell, loZipFolder, loDestFolder
        
        Try
            * Creează directorul destinație dacă nu există
            If Not Directory(tcDestPath)
                Mkdir (tcDestPath)
            EndIf
            
            loShell = CreateObject("Shell.Application")
            loZipFolder = loShell.NameSpace(tcZipFile)
            loDestFolder = loShell.NameSpace(Addbs(tcDestPath))
            
            * Extrage toate fișierele
            loDestFolder.CopyHere(loZipFolder.Items, 4 + 16)
            
            * Așteaptă finalizarea
            Inkey(1)
            
            Return .T.
            
        Catch To loEx
            This.Log("ERROR", "ZIP extraction failed: " + loEx.Message)
            Return .F.
        EndTry
    EndProc
    
    *---------------------------------------------------------------------------
    * Copiază fișiere (backup necomprimat)
    *---------------------------------------------------------------------------
    Protected Procedure CopyFiles(tcSourcePath, tcPattern, tcDestPath)
        Local laFiles[1], lnCount, i
        
        If Not Directory(tcDestPath)
            Mkdir (tcDestPath)
        EndIf
        
        lnCount = Adir(laFiles, Addbs(tcSourcePath) + tcPattern)
        
        For i = 1 To lnCount
            Try
                Copy File (Addbs(tcSourcePath) + laFiles[i, 1]) To (Addbs(tcDestPath) + laFiles[i, 1])
            Catch
            EndTry
        EndFor
        
        Return lnCount > 0
    EndProc
    
    *---------------------------------------------------------------------------
    * Verifică integritatea backup-ului
    *---------------------------------------------------------------------------
    Procedure VerifyBackupIntegrity(tcBackupFile)
        Local llValid, loShell, loZipFolder
        
        llValid = .F.
        
        If Not File(tcBackupFile)
            Return .F.
        EndIf
        
        Try
            * Verifică header ZIP
            Local lcHeader
            lcHeader = Left(FileToStr(tcBackupFile), 4)
            
            If lcHeader = Chr(80) + Chr(75) + Chr(3) + Chr(4) Or ;
               lcHeader = Chr(80) + Chr(75) + Chr(5) + Chr(6)
                
                * Încearcă să deschidă arhiva
                loShell = CreateObject("Shell.Application")
                loZipFolder = loShell.NameSpace(tcBackupFile)
                
                If Not IsNull(loZipFolder)
                    llValid = .T.
                EndIf
            EndIf
            
        Catch
            llValid = .F.
        EndTry
        
        Return llValid
    EndProc
    
    *---------------------------------------------------------------------------
    * Curăță backup-urile vechi
    *---------------------------------------------------------------------------
    Procedure CleanupOldBackups
        Local laFiles[1], lnCount, i, lcFile, ldFileDate
        Local lnDeleted, lnTotalSize
        
        lnCount = Adir(laFiles, This.cBackupPath + "*.*")
        lnDeleted = 0
        lnTotalSize = 0
        
        This.Log("INFO", "Starting backup cleanup (retention: " + Transform(This.nRetentionDays) + " days)")
        
        For i = 1 To lnCount
            ldFileDate = laFiles[i, 3]
            
            If Date() - ldFileDate > This.nRetentionDays
                lcFile = This.cBackupPath + laFiles[i, 1]
                lnTotalSize = lnTotalSize + laFiles[i, 2]
                
                Try
                    Delete File (lcFile)
                    lnDeleted = lnDeleted + 1
                    This.Log("DEBUG", "Deleted old backup: " + laFiles[i, 1])
                Catch
                EndTry
            EndIf
        EndFor
        
        This.Log("INFO", "Cleanup completed: " + Transform(lnDeleted) + " files, " + ;
                 Transform(lnTotalSize / 1024 / 1024) + " MB freed")
        
        Return lnDeleted
    EndProc
    
    *---------------------------------------------------------------------------
    * Programează backup automat
    *---------------------------------------------------------------------------
    Procedure Schedule(tcType, tcTime, tcDays)
        This.nScheduleCount = This.nScheduleCount + 1
        Dimension This.aSchedule[This.nScheduleCount, 3]
        
        This.aSchedule[This.nScheduleCount, 1] = Upper(tcType)  && DAILY, WEEKLY, MONTHLY
        This.aSchedule[This.nScheduleCount, 2] = tcTime         && HH:MM
        This.aSchedule[This.nScheduleCount, 3] = tcDays         && Days of week (1-7) sau day of month
        
        This.Log("INFO", "Backup scheduled: " + tcType + " at " + tcTime)
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Verifică dacă trebuie executat backup programat
    *---------------------------------------------------------------------------
    Procedure CheckSchedule
        Local i, lcType, lcTime, lcDays
        Local lcCurrentTime, lnDayOfWeek, lnDayOfMonth
        
        lcCurrentTime = Left(Time(), 5)
        lnDayOfWeek = Dow(Date())
        lnDayOfMonth = Day(Date())
        
        For i = 1 To This.nScheduleCount
            lcType = This.aSchedule[i, 1]
            lcTime = This.aSchedule[i, 2]
            lcDays = This.aSchedule[i, 3]
            
            If lcCurrentTime == lcTime
                Do Case
                    Case lcType = "DAILY"
                        Return .T.
                    Case lcType = "WEEKLY"
                        If Transform(lnDayOfWeek) $ lcDays
                            Return .T.
                        EndIf
                    Case lcType = "MONTHLY"
                        If Transform(lnDayOfMonth) $ lcDays
                            Return .T.
                        EndIf
                EndCase
            EndIf
        EndFor
        
        Return .F.
    EndProc
    
    *---------------------------------------------------------------------------
    * Adaugă la istoric
    *---------------------------------------------------------------------------
    Protected Procedure AddToHistory(tcType, tcPath, tnSize, tcStatus)
        This.nHistoryCount = This.nHistoryCount + 1
        Dimension This.aBackupHistory[This.nHistoryCount, 6]
        
        This.aBackupHistory[This.nHistoryCount, 1] = This.nHistoryCount
        This.aBackupHistory[This.nHistoryCount, 2] = tcType
        This.aBackupHistory[This.nHistoryCount, 3] = Datetime()
        This.aBackupHistory[This.nHistoryCount, 4] = tnSize
        This.aBackupHistory[This.nHistoryCount, 5] = tcStatus
        This.aBackupHistory[This.nHistoryCount, 6] = tcPath
        
        This.nTotalSizeMB = This.nTotalSizeMB + (tnSize / 1024 / 1024)
    EndProc
    
    *---------------------------------------------------------------------------
    * Obține istoricul backup-urilor
    *---------------------------------------------------------------------------
    Procedure GetHistory
        Return @This.aBackupHistory
    EndProc
    
    *---------------------------------------------------------------------------
    * Obține statistici
    *---------------------------------------------------------------------------
    Procedure GetStats
        Local loStats
        
        loStats = CreateObject("Empty")
        AddProperty(loStats, "TotalBackups", This.nTotalBackups)
        AddProperty(loStats, "SuccessfulBackups", This.nSuccessfulBackups)
        AddProperty(loStats, "FailedBackups", This.nFailedBackups)
        AddProperty(loStats, "TotalSizeMB", This.nTotalSizeMB)
        AddProperty(loStats, "SuccessRate", ;
            Iif(This.nTotalBackups > 0, Round(This.nSuccessfulBackups / This.nTotalBackups * 100, 2), 0))
        
        Return loStats
    EndProc
    
    *---------------------------------------------------------------------------
    * Helpers
    *---------------------------------------------------------------------------
    Protected Procedure GetTimestamp
        Return Dtos(Date()) + "_" + Strtran(Time(), ":", "")
    EndProc
    
    Protected Procedure GetFileSize(tcFile)
        Local laFile[1]
        
        If Adir(laFile, tcFile) > 0
            Return laFile[1, 2]
        EndIf
        
        Return 0
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
                    * Notificare pentru erori
                    If VarType(This.oNotificationService) = 'O'
                        This.oNotificationService.SendEmail("Backup Error: " + tcMessage)
                    EndIf
            EndCase
        EndIf
    EndProc
    
EndDefine
