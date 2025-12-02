*******************************************************************************
* SchemaMigrator.prg
* Serviciu pentru versionare și migrare automată structură bază de date
* 
* Funcționalități:
* - Versionare schema DB
* - Migrări up/down
* - Rollback
* - Istoricul migrărilor
* - Seed data
* - Backup înainte de migrare
*
* Exemplu utilizare:
*   loMigrator = CreateObject("SchemaMigrator")
*   loMigrator.SetMigrationsPath("C:\App\Migrations")
*   loMigrator.RegisterMigration("001", "CreateInvoicesTable")
*   loMigrator.Migrate()  && Aplică toate migrările pending
*******************************************************************************

Define Class SchemaMigrator As Custom
    
    * Configurare
    cMigrationsPath = ""
    cMigrationTable = "schema_migrations"
    cDatabasePath = ""
    
    * Migrări înregistrate
    Dimension aMigrations[1, 4]  && Version, Name, UpMethod, DownMethod
    nMigrationCount = 0
    
    * Migrări aplicate
    Dimension aAppliedMigrations[1, 3]  && Version, AppliedAt, Batch
    nAppliedCount = 0
    
    * Batch curent
    nCurrentBatch = 0
    
    * Backup
    lBackupBeforeMigrate = .T.
    oBackupService = .Null.
    
    * Logging
    oLogger = .Null.
    
    *---------------------------------------------------------------------------
    Procedure Init
        This.cMigrationsPath = Sys(2003) + "\Migrations\"
        This.cDatabasePath = Sys(2003)
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează logger-ul
    *---------------------------------------------------------------------------
    Procedure SetLogger(toLogger)
        This.oLogger = toLogger
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează calea migrărilor
    *---------------------------------------------------------------------------
    Procedure SetMigrationsPath(tcPath)
        This.cMigrationsPath = Addbs(tcPath)
        
        If Not Directory(This.cMigrationsPath)
            Try
                Mkdir (This.cMigrationsPath)
            Catch
            EndTry
        EndIf
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează calea bazei de date
    *---------------------------------------------------------------------------
    Procedure SetDatabasePath(tcPath)
        This.cDatabasePath = Addbs(tcPath)
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează serviciul de backup
    *---------------------------------------------------------------------------
    Procedure SetBackupService(toBackup)
        This.oBackupService = toBackup
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Inițializează tabela de migrări
    *---------------------------------------------------------------------------
    Procedure Initialize
        Local lcTable
        
        lcTable = This.cDatabasePath + This.cMigrationTable + ".DBF"
        
        If Not File(lcTable)
            Create Table (lcTable) ;
                (version C(20), ;
                 migration_name C(100), ;
                 batch N(10, 0), ;
                 applied_at T)
                 
            Use In Select(This.cMigrationTable)
            
            This.Log("INFO", "Migration table created: " + This.cMigrationTable)
        EndIf
        
        * Încarcă migrările aplicate
        This.LoadAppliedMigrations()
        
        Return .T.
    EndProc
    
    *---------------------------------------------------------------------------
    * Încarcă migrările aplicate din DB
    *---------------------------------------------------------------------------
    Protected Procedure LoadAppliedMigrations
        Local lcTable
        
        lcTable = This.cDatabasePath + This.cMigrationTable + ".DBF"
        
        If Not File(lcTable)
            Return
        EndIf
        
        Try
            Use (lcTable) Alias _migrations In 0 Shared
            
            Select _migrations
            This.nAppliedCount = Reccount()
            
            If This.nAppliedCount > 0
                Dimension This.aAppliedMigrations[This.nAppliedCount, 3]
                
                Go Top
                Local i
                i = 0
                Scan
                    i = i + 1
                    This.aAppliedMigrations[i, 1] = Alltrim(_migrations.version)
                    This.aAppliedMigrations[i, 2] = _migrations.applied_at
                    This.aAppliedMigrations[i, 3] = _migrations.batch
                    
                    If _migrations.batch > This.nCurrentBatch
                        This.nCurrentBatch = _migrations.batch
                    EndIf
                EndScan
            EndIf
            
            Use In Select("_migrations")
            
        Catch To loEx
            This.Log("ERROR", "Failed to load applied migrations: " + loEx.Message)
        EndTry
    EndProc
    
    *---------------------------------------------------------------------------
    * Înregistrează o migrare
    *---------------------------------------------------------------------------
    Procedure RegisterMigration(tcVersion, tcName, tcUpMethod, tcDownMethod)
        This.nMigrationCount = This.nMigrationCount + 1
        Dimension This.aMigrations[This.nMigrationCount, 4]
        
        This.aMigrations[This.nMigrationCount, 1] = tcVersion
        This.aMigrations[This.nMigrationCount, 2] = tcName
        This.aMigrations[This.nMigrationCount, 3] = Iif(Empty(tcUpMethod), "Up_" + tcVersion, tcUpMethod)
        This.aMigrations[This.nMigrationCount, 4] = Iif(Empty(tcDownMethod), "Down_" + tcVersion, tcDownMethod)
        
        This.Log("DEBUG", "Migration registered: " + tcVersion + " - " + tcName)
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Rulează toate migrările pending
    *---------------------------------------------------------------------------
    Procedure Migrate
        Local lnApplied, i, lcVersion, llSuccess
        
        This.Initialize()
        
        * Backup
        If This.lBackupBeforeMigrate And VarType(This.oBackupService) = 'O'
            This.oBackupService.BackupFull(This.cDatabasePath)
        EndIf
        
        * Sortează migrările după versiune
        This.SortMigrations()
        
        * Determină migrările pending
        This.nCurrentBatch = This.nCurrentBatch + 1
        lnApplied = 0
        
        For i = 1 To This.nMigrationCount
            lcVersion = This.aMigrations[i, 1]
            
            If Not This.IsMigrationApplied(lcVersion)
                This.Log("INFO", "Migrating: " + lcVersion + " - " + This.aMigrations[i, 2])
                
                llSuccess = This.RunMigration(i, "UP")
                
                If llSuccess
                    This.MarkAsApplied(lcVersion, This.aMigrations[i, 2])
                    lnApplied = lnApplied + 1
                Else
                    This.Log("ERROR", "Migration failed: " + lcVersion)
                    Return .F.
                EndIf
            EndIf
        EndFor
        
        This.Log("INFO", "Migration complete. Applied: " + Transform(lnApplied) + " migrations")
        
        Return .T.
    EndProc
    
    *---------------------------------------------------------------------------
    * Rollback ultimul batch
    *---------------------------------------------------------------------------
    Procedure Rollback(tnSteps)
        Local lnSteps, lnRolledBack, i, j, lcVersion, llSuccess
        
        lnSteps = Iif(VarType(tnSteps) = 'N', tnSteps, 1)
        lnRolledBack = 0
        
        This.Initialize()
        
        * Găsește migrările din ultimele batch-uri
        For i = This.nCurrentBatch To Max(This.nCurrentBatch - lnSteps + 1, 1) Step -1
            * Găsește migrările din batch-ul i (în ordine inversă)
            For j = This.nAppliedCount To 1 Step -1
                If This.aAppliedMigrations[j, 3] = i
                    lcVersion = This.aAppliedMigrations[j, 1]
                    
                    * Găsește indexul migrării
                    Local lnMigrationIndex
                    lnMigrationIndex = This.FindMigrationIndex(lcVersion)
                    
                    If lnMigrationIndex > 0
                        This.Log("INFO", "Rolling back: " + lcVersion)
                        
                        llSuccess = This.RunMigration(lnMigrationIndex, "DOWN")
                        
                        If llSuccess
                            This.MarkAsRolledBack(lcVersion)
                            lnRolledBack = lnRolledBack + 1
                        Else
                            This.Log("ERROR", "Rollback failed: " + lcVersion)
                            Return .F.
                        EndIf
                    EndIf
                EndIf
            EndFor
        EndFor
        
        This.Log("INFO", "Rollback complete. Rolled back: " + Transform(lnRolledBack) + " migrations")
        
        Return .T.
    EndProc
    
    *---------------------------------------------------------------------------
    * Resetează toate migrările
    *---------------------------------------------------------------------------
    Procedure Reset
        Local llSuccess
        
        This.Log("WARNING", "Resetting all migrations!")
        
        * Rollback toate
        Do While This.nAppliedCount > 0
            llSuccess = This.Rollback(1)
            If Not llSuccess
                Return .F.
            EndIf
            This.LoadAppliedMigrations()
        EndDo
        
        Return .T.
    EndProc
    
    *---------------------------------------------------------------------------
    * Refresh (reset + migrate)
    *---------------------------------------------------------------------------
    Procedure Refresh
        This.Reset()
        Return This.Migrate()
    EndProc
    
    *---------------------------------------------------------------------------
    * Rulează o migrare specifică
    *---------------------------------------------------------------------------
    Protected Procedure RunMigration(tnIndex, tcDirection)
        Local lcMethod, loMigration, llSuccess
        
        If tcDirection = "UP"
            lcMethod = This.aMigrations[tnIndex, 3]
        Else
            lcMethod = This.aMigrations[tnIndex, 4]
        EndIf
        
        Try
            * Încarcă fișierul migrării
            Local lcMigrationFile
            lcMigrationFile = This.cMigrationsPath + This.aMigrations[tnIndex, 1] + "_" + This.aMigrations[tnIndex, 2] + ".prg"
            
            If File(lcMigrationFile)
                Set Procedure To (lcMigrationFile) Additive
            EndIf
            
            * Încearcă să apeleze metoda
            If Type(lcMethod + "()") <> "U"
                llSuccess = Evaluate(lcMethod + "()")
            Else
                * Încearcă ca metodă a acestei clase
                If PemStatus(This, lcMethod, 5)
                    llSuccess = Evaluate("This." + lcMethod + "()")
                Else
                    This.Log("WARNING", "Migration method not found: " + lcMethod)
                    llSuccess = .T.  && Skip
                EndIf
            EndIf
            
            Return llSuccess
            
        Catch To loEx
            This.Log("ERROR", "Migration execution error: " + loEx.Message)
            Return .F.
        EndTry
    EndProc
    
    *---------------------------------------------------------------------------
    * Verifică dacă migrarea este aplicată
    *---------------------------------------------------------------------------
    Protected Procedure IsMigrationApplied(tcVersion)
        Local i
        
        For i = 1 To This.nAppliedCount
            If This.aAppliedMigrations[i, 1] == tcVersion
                Return .T.
            EndIf
        EndFor
        
        Return .F.
    EndProc
    
    *---------------------------------------------------------------------------
    * Marchează migrarea ca aplicată
    *---------------------------------------------------------------------------
    Protected Procedure MarkAsApplied(tcVersion, tcName)
        Local lcTable
        
        lcTable = This.cDatabasePath + This.cMigrationTable + ".DBF"
        
        Try
            Use (lcTable) Alias _migrations In 0 Exclusive
            
            Append Blank
            Replace version With tcVersion, ;
                    migration_name With tcName, ;
                    batch With This.nCurrentBatch, ;
                    applied_at With Datetime()
            
            Use In Select("_migrations")
            
            * Actualizează array-ul
            This.nAppliedCount = This.nAppliedCount + 1
            Dimension This.aAppliedMigrations[This.nAppliedCount, 3]
            This.aAppliedMigrations[This.nAppliedCount, 1] = tcVersion
            This.aAppliedMigrations[This.nAppliedCount, 2] = Datetime()
            This.aAppliedMigrations[This.nAppliedCount, 3] = This.nCurrentBatch
            
        Catch To loEx
            This.Log("ERROR", "Failed to mark migration as applied: " + loEx.Message)
        EndTry
    EndProc
    
    *---------------------------------------------------------------------------
    * Marchează migrarea ca rolled back
    *---------------------------------------------------------------------------
    Protected Procedure MarkAsRolledBack(tcVersion)
        Local lcTable
        
        lcTable = This.cDatabasePath + This.cMigrationTable + ".DBF"
        
        Try
            Use (lcTable) Alias _migrations In 0 Exclusive
            
            Locate For Alltrim(version) == tcVersion
            If Found()
                Delete
                Pack
            EndIf
            
            Use In Select("_migrations")
            
            * Reîncarcă lista
            This.LoadAppliedMigrations()
            
        Catch To loEx
            This.Log("ERROR", "Failed to mark migration as rolled back: " + loEx.Message)
        EndTry
    EndProc
    
    *---------------------------------------------------------------------------
    * Găsește indexul unei migrări
    *---------------------------------------------------------------------------
    Protected Procedure FindMigrationIndex(tcVersion)
        Local i
        
        For i = 1 To This.nMigrationCount
            If This.aMigrations[i, 1] == tcVersion
                Return i
            EndIf
        EndFor
        
        Return 0
    EndProc
    
    *---------------------------------------------------------------------------
    * Sortează migrările
    *---------------------------------------------------------------------------
    Protected Procedure SortMigrations
        Local i, j, lcTemp1, lcTemp2, lcTemp3, lcTemp4
        
        * Bubble sort simplu pentru versiuni
        For i = 1 To This.nMigrationCount - 1
            For j = i + 1 To This.nMigrationCount
                If This.aMigrations[i, 1] > This.aMigrations[j, 1]
                    * Swap
                    lcTemp1 = This.aMigrations[i, 1]
                    lcTemp2 = This.aMigrations[i, 2]
                    lcTemp3 = This.aMigrations[i, 3]
                    lcTemp4 = This.aMigrations[i, 4]
                    
                    This.aMigrations[i, 1] = This.aMigrations[j, 1]
                    This.aMigrations[i, 2] = This.aMigrations[j, 2]
                    This.aMigrations[i, 3] = This.aMigrations[j, 3]
                    This.aMigrations[i, 4] = This.aMigrations[j, 4]
                    
                    This.aMigrations[j, 1] = lcTemp1
                    This.aMigrations[j, 2] = lcTemp2
                    This.aMigrations[j, 3] = lcTemp3
                    This.aMigrations[j, 4] = lcTemp4
                EndIf
            EndFor
        EndFor
    EndProc
    
    *---------------------------------------------------------------------------
    * Obține status migrări
    *---------------------------------------------------------------------------
    Procedure GetStatus
        Local lcStatus, i, llApplied
        
        This.Initialize()
        This.SortMigrations()
        
        lcStatus = "=== Migration Status ===" + Chr(13) + Chr(10)
        lcStatus = lcStatus + Chr(13) + Chr(10)
        
        For i = 1 To This.nMigrationCount
            llApplied = This.IsMigrationApplied(This.aMigrations[i, 1])
            
            lcStatus = lcStatus + Iif(llApplied, "[X] ", "[ ] ")
            lcStatus = lcStatus + This.aMigrations[i, 1] + " - " + This.aMigrations[i, 2]
            lcStatus = lcStatus + Chr(13) + Chr(10)
        EndFor
        
        lcStatus = lcStatus + Chr(13) + Chr(10)
        lcStatus = lcStatus + "Total: " + Transform(This.nMigrationCount) + " migrations"
        lcStatus = lcStatus + Chr(13) + Chr(10)
        lcStatus = lcStatus + "Applied: " + Transform(This.nAppliedCount)
        lcStatus = lcStatus + Chr(13) + Chr(10)
        lcStatus = lcStatus + "Pending: " + Transform(This.nMigrationCount - This.nAppliedCount)
        
        Return lcStatus
    EndProc
    
    *---------------------------------------------------------------------------
    * Creează o migrare nouă
    *---------------------------------------------------------------------------
    Procedure CreateMigration(tcName)
        Local lcVersion, lcFileName, lcContent
        
        * Generează versiune din timestamp
        lcVersion = Dtos(Date()) + Strtran(Time(), ":", "")
        
        * Creează fișierul
        lcFileName = This.cMigrationsPath + lcVersion + "_" + tcName + ".prg"
        
        lcContent = "*" + Replicate("*", 78) + Chr(13) + Chr(10)
        lcContent = lcContent + "* Migration: " + tcName + Chr(13) + Chr(10)
        lcContent = lcContent + "* Version: " + lcVersion + Chr(13) + Chr(10)
        lcContent = lcContent + "* Created: " + Transform(Datetime()) + Chr(13) + Chr(10)
        lcContent = lcContent + "*" + Replicate("*", 78) + Chr(13) + Chr(10)
        lcContent = lcContent + Chr(13) + Chr(10)
        lcContent = lcContent + "Procedure Up_" + lcVersion + Chr(13) + Chr(10)
        lcContent = lcContent + "    * Add migration code here" + Chr(13) + Chr(10)
        lcContent = lcContent + "    * Example: Create Table, Alter Table, etc." + Chr(13) + Chr(10)
        lcContent = lcContent + "    Return .T." + Chr(13) + Chr(10)
        lcContent = lcContent + "EndProc" + Chr(13) + Chr(10)
        lcContent = lcContent + Chr(13) + Chr(10)
        lcContent = lcContent + "Procedure Down_" + lcVersion + Chr(13) + Chr(10)
        lcContent = lcContent + "    * Add rollback code here" + Chr(13) + Chr(10)
        lcContent = lcContent + "    Return .T." + Chr(13) + Chr(10)
        lcContent = lcContent + "EndProc" + Chr(13) + Chr(10)
        
        StrToFile(lcContent, lcFileName)
        
        This.Log("INFO", "Migration created: " + lcFileName)
        
        Return lcVersion
    EndProc
    
    *---------------------------------------------------------------------------
    * Helper: Adaugă coloană la tabel
    *---------------------------------------------------------------------------
    Procedure AddColumn(tcTable, tcColumn, tcType)
        Local lcSql
        
        Try
            lcSql = "ALTER TABLE " + tcTable + " ADD COLUMN " + tcColumn + " " + tcType
            &lcSql
            This.Log("INFO", "Column added: " + tcTable + "." + tcColumn)
            Return .T.
        Catch To loEx
            This.Log("ERROR", "Failed to add column: " + loEx.Message)
            Return .F.
        EndTry
    EndProc
    
    *---------------------------------------------------------------------------
    * Helper: Șterge coloană din tabel
    *---------------------------------------------------------------------------
    Procedure DropColumn(tcTable, tcColumn)
        Local lcSql
        
        Try
            lcSql = "ALTER TABLE " + tcTable + " DROP COLUMN " + tcColumn
            &lcSql
            This.Log("INFO", "Column dropped: " + tcTable + "." + tcColumn)
            Return .T.
        Catch To loEx
            This.Log("ERROR", "Failed to drop column: " + loEx.Message)
            Return .F.
        EndTry
    EndProc
    
    *---------------------------------------------------------------------------
    * Helper: Creează tabel
    *---------------------------------------------------------------------------
    Procedure CreateTable(tcTable, tcColumns)
        Try
            Create Table (tcTable) (&tcColumns)
            Use In Select(Juststem(tcTable))
            This.Log("INFO", "Table created: " + tcTable)
            Return .T.
        Catch To loEx
            This.Log("ERROR", "Failed to create table: " + loEx.Message)
            Return .F.
        EndTry
    EndProc
    
    *---------------------------------------------------------------------------
    * Helper: Șterge tabel
    *---------------------------------------------------------------------------
    Procedure DropTable(tcTable)
        Try
            If File(tcTable + ".DBF")
                Delete File (tcTable + ".DBF")
                If File(tcTable + ".FPT")
                    Delete File (tcTable + ".FPT")
                EndIf
                If File(tcTable + ".CDX")
                    Delete File (tcTable + ".CDX")
                EndIf
            EndIf
            This.Log("INFO", "Table dropped: " + tcTable)
            Return .T.
        Catch To loEx
            This.Log("ERROR", "Failed to drop table: " + loEx.Message)
            Return .F.
        EndTry
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
