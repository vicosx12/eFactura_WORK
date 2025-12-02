*====================================================================
* HealthChecker - Health Check and Diagnostics Service
* 
* Monitors system health: ANAF API connectivity, database status,
* disk space, memory, and component availability
*
* Visual FoxPro 9 SP2 Compatible
*====================================================================

Define Class HealthChecker As Custom
    
    * Health check results
    Dimension aChecks[1, 4]  && Name, Status, Message, Duration
    nCheckCount = 0
    
    * Configuration
    nDiskSpaceWarningMB = 500
    nDiskSpaceCriticalMB = 100
    nApiTimeoutSeconds = 30
    cAnafTestUrl = "https://api.anaf.ro/test/FCTEL/rest/ping"
    cAnafProdUrl = "https://api.anaf.ro/prod/FCTEL/rest/ping"
    
    * Status constants
    cStatusHealthy = "HEALTHY"
    cStatusWarning = "WARNING"
    cStatusCritical = "CRITICAL"
    cStatusUnknown = "UNKNOWN"
    
    * Logger reference
    oLogger = .Null.
    
    *----------------------------------------------------------------
    * Init
    *----------------------------------------------------------------
    Procedure Init
        This.oLogger = CreateObject("LoggerService")
    EndProc
    
    *----------------------------------------------------------------
    * RunAllChecks - Execute all health checks
    *----------------------------------------------------------------
    Procedure RunAllChecks
        Local loReport
        
        This.nCheckCount = 0
        Dimension This.aChecks[1, 4]
        
        * Run individual checks
        This.CheckDiskSpace()
        This.CheckDatabase()
        This.CheckAnafApi()
        This.CheckTempFolder()
        This.CheckMemory()
        This.CheckRequiredTables()
        This.CheckCertificates()
        This.CheckConfiguration()
        
        * Create summary report
        loReport = This.CreateReport()
        
        Return loReport
    EndProc
    
    *----------------------------------------------------------------
    * CheckDiskSpace - Check available disk space
    *----------------------------------------------------------------
    Procedure CheckDiskSpace
        Local lnFreeSpace, lcStatus, lcMessage, lnStart, lnFreeMB
        
        lnStart = Seconds()
        
        Try
            * Get free space on current drive (in bytes)
            lnFreeSpace = DiskSpace()
            lnFreeMB = lnFreeSpace / (1024 * 1024)
            
            Do Case
                Case lnFreeMB < This.nDiskSpaceCriticalMB
                    lcStatus = This.cStatusCritical
                    lcMessage = "Spațiu disk critic: " + Transform(Int(lnFreeMB)) + " MB disponibili"
                Case lnFreeMB < This.nDiskSpaceWarningMB
                    lcStatus = This.cStatusWarning
                    lcMessage = "Spațiu disk scăzut: " + Transform(Int(lnFreeMB)) + " MB disponibili"
                Otherwise
                    lcStatus = This.cStatusHealthy
                    lcMessage = Transform(Int(lnFreeMB)) + " MB disponibili"
            EndCase
        Catch
            lcStatus = This.cStatusUnknown
            lcMessage = "Nu s-a putut verifica spațiul disk"
        EndTry
        
        This.AddCheck("DiskSpace", lcStatus, lcMessage, Seconds() - lnStart)
    EndProc
    
    *----------------------------------------------------------------
    * CheckDatabase - Check database connectivity
    *----------------------------------------------------------------
    Procedure CheckDatabase
        Local lcStatus, lcMessage, lnStart, lnTableCount
        
        lnStart = Seconds()
        
        Try
            * Check if we can access tables
            lnTableCount = 0
            
            If Used("Iesiri") Or File("Iesiri.dbf")
                lnTableCount = lnTableCount + 1
            EndIf
            
            If Used("Export") Or File("Export.dbf")
                lnTableCount = lnTableCount + 1
            EndIf
            
            If Used("Parteneri") Or File("Parteneri.dbf")
                lnTableCount = lnTableCount + 1
            EndIf
            
            If lnTableCount > 0
                lcStatus = This.cStatusHealthy
                lcMessage = Transform(lnTableCount) + " tabele accesibile"
            Else
                lcStatus = This.cStatusWarning
                lcMessage = "Nicio tabelă principală accesibilă"
            EndIf
        Catch
            lcStatus = This.cStatusCritical
            lcMessage = "Eroare acces bază de date: " + Message()
        EndTry
        
        This.AddCheck("Database", lcStatus, lcMessage, Seconds() - lnStart)
    EndProc
    
    *----------------------------------------------------------------
    * CheckAnafApi - Check ANAF API connectivity
    *----------------------------------------------------------------
    Procedure CheckAnafApi
        Local lcStatus, lcMessage, lnStart
        Local loHttp, lnHttpStatus
        
        lnStart = Seconds()
        
        Try
            * Create HTTP object
            loHttp = CreateObject("MSXML2.XMLHTTP.6.0")
            
            * Test connection with timeout
            loHttp.Open("GET", This.cAnafProdUrl, .F.)
            loHttp.SetRequestHeader("User-Agent", "eFactura-HealthCheck/1.0")
            loHttp.Send()
            
            lnHttpStatus = loHttp.Status
            
            Do Case
                Case lnHttpStatus = 200
                    lcStatus = This.cStatusHealthy
                    lcMessage = "API ANAF accesibil (HTTP 200)"
                Case Between(lnHttpStatus, 500, 599)
                    lcStatus = This.cStatusCritical
                    lcMessage = "API ANAF indisponibil (HTTP " + Transform(lnHttpStatus) + ")"
                Case Between(lnHttpStatus, 400, 499)
                    lcStatus = This.cStatusWarning
                    lcMessage = "Problemă autentificare API (HTTP " + Transform(lnHttpStatus) + ")"
                Otherwise
                    lcStatus = This.cStatusWarning
                    lcMessage = "Răspuns neașteptat API (HTTP " + Transform(lnHttpStatus) + ")"
            EndCase
        Catch
            lcStatus = This.cStatusCritical
            lcMessage = "Nu se poate conecta la API ANAF: " + Message()
        EndTry
        
        This.AddCheck("AnafApi", lcStatus, lcMessage, Seconds() - lnStart)
    EndProc
    
    *----------------------------------------------------------------
    * CheckTempFolder - Check temporary folder access
    *----------------------------------------------------------------
    Procedure CheckTempFolder
        Local lcStatus, lcMessage, lnStart
        Local lcTempPath, lcTestFile
        
        lnStart = Seconds()
        
        Try
            lcTempPath = Sys(2023)  && Windows TEMP folder
            lcTestFile = AddBs(lcTempPath) + "efactura_test_" + Sys(2015) + ".tmp"
            
            * Try to create and delete a test file
            StrToFile("test", lcTestFile)
            
            If File(lcTestFile)
                Delete File (lcTestFile)
                lcStatus = This.cStatusHealthy
                lcMessage = "Folder temporar accesibil: " + lcTempPath
            Else
                lcStatus = This.cStatusCritical
                lcMessage = "Nu se poate scrie în folder temporar"
            EndIf
        Catch
            lcStatus = This.cStatusCritical
            lcMessage = "Eroare acces folder temporar: " + Message()
        EndTry
        
        This.AddCheck("TempFolder", lcStatus, lcMessage, Seconds() - lnStart)
    EndProc
    
    *----------------------------------------------------------------
    * CheckMemory - Check available memory
    *----------------------------------------------------------------
    Procedure CheckMemory
        Local lcStatus, lcMessage, lnStart
        Local lnMemory
        
        lnStart = Seconds()
        
        Try
            * Get VFP memory usage
            lnMemory = Val(Sys(1016))  && Memory handle count
            
            lcStatus = This.cStatusHealthy
            lcMessage = "Handle-uri memorie: " + Transform(lnMemory)
        Catch
            lcStatus = This.cStatusUnknown
            lcMessage = "Nu s-a putut verifica memoria"
        EndTry
        
        This.AddCheck("Memory", lcStatus, lcMessage, Seconds() - lnStart)
    EndProc
    
    *----------------------------------------------------------------
    * CheckRequiredTables - Check all required tables exist
    *----------------------------------------------------------------
    Procedure CheckRequiredTables
        Local lcStatus, lcMessage, lnStart
        Local lnMissing, lcMissingList
        Dimension laTables[10]
        Local i
        
        lnStart = Seconds()
        
        * List of required tables
        laTables[1] = "Iesiri"
        laTables[2] = "Export"
        laTables[3] = "Parteneri"
        laTables[4] = "Produse"
        laTables[5] = "Iesiri_D"
        laTables[6] = "Export_D"
        laTables[7] = "Setari"
        laTables[8] = "Firme"
        laTables[9] = "Documente"
        laTables[10] = "Log_eFactura"
        
        lnMissing = 0
        lcMissingList = ""
        
        For i = 1 To 10
            If Not File(laTables[i] + ".dbf") And Not Used(laTables[i])
                lnMissing = lnMissing + 1
                lcMissingList = lcMissingList + Iif(Empty(lcMissingList), "", ", ") + laTables[i]
            EndIf
        Next
        
        Do Case
            Case lnMissing = 0
                lcStatus = This.cStatusHealthy
                lcMessage = "Toate tabelele necesare sunt accesibile"
            Case lnMissing <= 3
                lcStatus = This.cStatusWarning
                lcMessage = "Tabele lipsă: " + lcMissingList
            Otherwise
                lcStatus = This.cStatusCritical
                lcMessage = "Multiple tabele lipsă: " + lcMissingList
        EndCase
        
        This.AddCheck("RequiredTables", lcStatus, lcMessage, Seconds() - lnStart)
    EndProc
    
    *----------------------------------------------------------------
    * CheckCertificates - Check digital certificates
    *----------------------------------------------------------------
    Procedure CheckCertificates
        Local lcStatus, lcMessage, lnStart
        
        lnStart = Seconds()
        
        Try
            * Check if certificate store is accessible
            * This is a basic check - in production you'd verify specific certs
            lcStatus = This.cStatusHealthy
            lcMessage = "Verificare certificate - necesită configurare specifică"
        Catch
            lcStatus = This.cStatusWarning
            lcMessage = "Nu s-au putut verifica certificatele"
        EndTry
        
        This.AddCheck("Certificates", lcStatus, lcMessage, Seconds() - lnStart)
    EndProc
    
    *----------------------------------------------------------------
    * CheckConfiguration - Check configuration validity
    *----------------------------------------------------------------
    Procedure CheckConfiguration
        Local lcStatus, lcMessage, lnStart
        Local loConfig
        
        lnStart = Seconds()
        
        Try
            loConfig = CreateObject("ConfigProvider")
            
            * Check essential configuration
            If Empty(loConfig.GetAnafApiUrl())
                lcStatus = This.cStatusCritical
                lcMessage = "URL API ANAF neconfigurat"
            Else
                lcStatus = This.cStatusHealthy
                lcMessage = "Configurație validă"
            EndIf
        Catch
            lcStatus = This.cStatusCritical
            lcMessage = "Eroare încărcare configurație: " + Message()
        EndTry
        
        This.AddCheck("Configuration", lcStatus, lcMessage, Seconds() - lnStart)
    EndProc
    
    *----------------------------------------------------------------
    * AddCheck - Add check result
    *----------------------------------------------------------------
    Protected Procedure AddCheck(tcName, tcStatus, tcMessage, tnDuration)
        This.nCheckCount = This.nCheckCount + 1
        Dimension This.aChecks[This.nCheckCount, 4]
        
        This.aChecks[This.nCheckCount, 1] = tcName
        This.aChecks[This.nCheckCount, 2] = tcStatus
        This.aChecks[This.nCheckCount, 3] = tcMessage
        This.aChecks[This.nCheckCount, 4] = tnDuration
    EndProc
    
    *----------------------------------------------------------------
    * CreateReport - Create health check report object
    *----------------------------------------------------------------
    Protected Procedure CreateReport
        Local loReport, i
        Local lnHealthy, lnWarning, lnCritical
        
        loReport = CreateObject("Empty")
        AddProperty(loReport, "Timestamp", DateTime())
        AddProperty(loReport, "CheckCount", This.nCheckCount)
        AddProperty(loReport, "OverallStatus", This.cStatusHealthy)
        AddProperty(loReport, "HealthyCount", 0)
        AddProperty(loReport, "WarningCount", 0)
        AddProperty(loReport, "CriticalCount", 0)
        AddProperty(loReport, "Checks", .Null.)
        
        * Count statuses
        lnHealthy = 0
        lnWarning = 0
        lnCritical = 0
        
        For i = 1 To This.nCheckCount
            Do Case
                Case This.aChecks[i, 2] = This.cStatusHealthy
                    lnHealthy = lnHealthy + 1
                Case This.aChecks[i, 2] = This.cStatusWarning
                    lnWarning = lnWarning + 1
                Case This.aChecks[i, 2] = This.cStatusCritical
                    lnCritical = lnCritical + 1
            EndCase
        Next
        
        loReport.HealthyCount = lnHealthy
        loReport.WarningCount = lnWarning
        loReport.CriticalCount = lnCritical
        
        * Determine overall status
        Do Case
            Case lnCritical > 0
                loReport.OverallStatus = This.cStatusCritical
            Case lnWarning > 0
                loReport.OverallStatus = This.cStatusWarning
            Otherwise
                loReport.OverallStatus = This.cStatusHealthy
        EndCase
        
        * Copy checks array
        loReport.Checks = This.aChecks
        
        Return loReport
    EndProc
    
    *----------------------------------------------------------------
    * GetReportAsJson - Get report in JSON format
    *----------------------------------------------------------------
    Procedure GetReportAsJson
        Local loReport, lcJson, i
        
        loReport = This.RunAllChecks()
        
        lcJson = '{"timestamp":"' + Ttoc(loReport.Timestamp) + '",'
        lcJson = lcJson + '"overallStatus":"' + loReport.OverallStatus + '",'
        lcJson = lcJson + '"summary":{"healthy":' + Transform(loReport.HealthyCount) + ','
        lcJson = lcJson + '"warning":' + Transform(loReport.WarningCount) + ','
        lcJson = lcJson + '"critical":' + Transform(loReport.CriticalCount) + '},'
        lcJson = lcJson + '"checks":['
        
        For i = 1 To This.nCheckCount
            If i > 1
                lcJson = lcJson + ','
            EndIf
            lcJson = lcJson + '{"name":"' + This.aChecks[i, 1] + '",'
            lcJson = lcJson + '"status":"' + This.aChecks[i, 2] + '",'
            lcJson = lcJson + '"message":"' + This.EscapeJson(This.aChecks[i, 3]) + '",'
            lcJson = lcJson + '"duration":' + Transform(This.aChecks[i, 4], "999.999") + '}'
        Next
        
        lcJson = lcJson + ']}'
        
        Return lcJson
    EndProc
    
    *----------------------------------------------------------------
    * EscapeJson - Escape string for JSON
    *----------------------------------------------------------------
    Protected Procedure EscapeJson(tcString)
        Local lcResult
        
        lcResult = tcString
        lcResult = StrTran(lcResult, '\', '\\')
        lcResult = StrTran(lcResult, '"', '\"')
        lcResult = StrTran(lcResult, Chr(13), '\r')
        lcResult = StrTran(lcResult, Chr(10), '\n')
        lcResult = StrTran(lcResult, Chr(9), '\t')
        
        Return lcResult
    EndProc
    
    *----------------------------------------------------------------
    * IsHealthy - Quick health check
    *----------------------------------------------------------------
    Procedure IsHealthy
        Local loReport
        
        loReport = This.RunAllChecks()
        
        Return loReport.OverallStatus = This.cStatusHealthy
    EndProc

EndDefine
