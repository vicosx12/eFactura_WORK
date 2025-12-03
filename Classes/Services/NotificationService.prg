*====================================================================
* NotificationService - Email/SMS Notification Service
* 
* Sends notifications for:
* - Critical errors
* - Upload confirmations
* - Batch processing results
* - System alerts
*
* Visual FoxPro 9 SP2 Compatible
*====================================================================

Define Class NotificationService As Custom
    
    * Email configuration
    cSmtpServer = ""
    nSmtpPort = 587
    cSmtpUser = ""
    cSmtpPassword = ""
    lSmtpUseSsl = .T.
    cFromEmail = ""
    cFromName = "eFactura System"
    
    * SMS configuration (via HTTP API)
    cSmsApiUrl = ""
    cSmsApiKey = ""
    cSmsFrom = ""
    
    * Default recipients
    Dimension aEmailRecipients[1]
    nEmailRecipientCount = 0
    Dimension aSmsRecipients[1]
    nSmsRecipientCount = 0
    
    * Notification settings
    lEnabled = .T.
    lEmailEnabled = .T.
    lSmsEnabled = .F.
    lLogNotifications = .T.
    
    * Templates
    cTemplatesPath = ""
    
    * Logger
    oLogger = .Null.
    
    * Notification types
    cTypeError = "ERROR"
    cTypeWarning = "WARNING"
    cTypeSuccess = "SUCCESS"
    cTypeInfo = "INFO"
    
    *----------------------------------------------------------------
    * Init
    *----------------------------------------------------------------
    Procedure Init
        This.oLogger = CreateObject("LoggerService")
        This.cTemplatesPath = AddBs(JustPath(Sys(16))) + "Templates\"
        
        * Load configuration from ConfigProvider
        This.LoadConfiguration()
    EndProc
    
    *----------------------------------------------------------------
    * LoadConfiguration - Load settings from config
    *----------------------------------------------------------------
    Protected Procedure LoadConfiguration
        Local loConfig
        
        Try
            loConfig = CreateObject("ConfigProvider")
            
            This.cSmtpServer = loConfig.GetValue("SmtpServer", "")
            This.nSmtpPort = Val(loConfig.GetValue("SmtpPort", "587"))
            This.cSmtpUser = loConfig.GetValue("SmtpUser", "")
            This.cSmtpPassword = loConfig.GetValue("SmtpPassword", "")
            This.cFromEmail = loConfig.GetValue("NotificationEmail", "")
            This.cSmsApiUrl = loConfig.GetValue("SmsApiUrl", "")
            This.cSmsApiKey = loConfig.GetValue("SmsApiKey", "")
        Catch
            * Use defaults
        EndTry
    EndProc
    
    *----------------------------------------------------------------
    * AddEmailRecipient - Add email recipient
    *----------------------------------------------------------------
    Procedure AddEmailRecipient(tcEmail, tcName)
        This.nEmailRecipientCount = This.nEmailRecipientCount + 1
        Dimension This.aEmailRecipients[This.nEmailRecipientCount, 2]
        This.aEmailRecipients[This.nEmailRecipientCount, 1] = tcEmail
        This.aEmailRecipients[This.nEmailRecipientCount, 2] = Evl(tcName, "")
    EndProc
    
    *----------------------------------------------------------------
    * AddSmsRecipient - Add SMS recipient
    *----------------------------------------------------------------
    Procedure AddSmsRecipient(tcPhone)
        This.nSmsRecipientCount = This.nSmsRecipientCount + 1
        Dimension This.aSmsRecipients[This.nSmsRecipientCount]
        This.aSmsRecipients[This.nSmsRecipientCount] = tcPhone
    EndProc
    
    *----------------------------------------------------------------
    * Notify - Send notification
    *----------------------------------------------------------------
    Procedure Notify(tcType, tcSubject, tcMessage, tlUrgent)
        Local llEmailSent, llSmsSent
        
        If Not This.lEnabled
            Return .T.
        EndIf
        
        llEmailSent = .F.
        llSmsSent = .F.
        
        * Send email notification
        If This.lEmailEnabled And This.nEmailRecipientCount > 0
            llEmailSent = This.SendEmail(tcSubject, tcMessage, tcType)
        EndIf
        
        * Send SMS for urgent notifications
        If This.lSmsEnabled And tlUrgent And This.nSmsRecipientCount > 0
            llSmsSent = This.SendSms(tcSubject + ": " + Left(tcMessage, 100))
        EndIf
        
        * Log notification
        If This.lLogNotifications
            This.LogNotification(tcType, tcSubject, tcMessage, llEmailSent, llSmsSent)
        EndIf
        
        Return llEmailSent Or llSmsSent Or (Not This.lEmailEnabled And Not This.lSmsEnabled)
    EndProc
    
    *----------------------------------------------------------------
    * NotifyError - Send error notification
    *----------------------------------------------------------------
    Procedure NotifyError(tcSubject, tcMessage, tlUrgent)
        Return This.Notify(This.cTypeError, "[EROARE] " + tcSubject, tcMessage, tlUrgent)
    EndProc
    
    *----------------------------------------------------------------
    * NotifySuccess - Send success notification
    *----------------------------------------------------------------
    Procedure NotifySuccess(tcSubject, tcMessage)
        Return This.Notify(This.cTypeSuccess, "[SUCCES] " + tcSubject, tcMessage, .F.)
    EndProc
    
    *----------------------------------------------------------------
    * NotifyWarning - Send warning notification
    *----------------------------------------------------------------
    Procedure NotifyWarning(tcSubject, tcMessage)
        Return This.Notify(This.cTypeWarning, "[ATENȚIE] " + tcSubject, tcMessage, .F.)
    EndProc
    
    *----------------------------------------------------------------
    * NotifyBatchResult - Send batch processing result
    *----------------------------------------------------------------
    Procedure NotifyBatchResult(tnTotal, tnSuccess, tnFailed, tnDuration)
        Local lcSubject, lcMessage
        
        lcSubject = "Procesare batch finalizată: " + Transform(tnSuccess) + "/" + Transform(tnTotal)
        
        lcMessage = "Rezultat procesare batch e-Factura:" + Chr(13) + Chr(10)
        lcMessage = lcMessage + Chr(13) + Chr(10)
        lcMessage = lcMessage + "Total facturi: " + Transform(tnTotal) + Chr(13) + Chr(10)
        lcMessage = lcMessage + "Procesate cu succes: " + Transform(tnSuccess) + Chr(13) + Chr(10)
        lcMessage = lcMessage + "Eșuate: " + Transform(tnFailed) + Chr(13) + Chr(10)
        lcMessage = lcMessage + "Durată: " + Transform(tnDuration, "999.99") + " secunde" + Chr(13) + Chr(10)
        
        If tnFailed > 0
            Return This.NotifyWarning(lcSubject, lcMessage)
        Else
            Return This.NotifySuccess(lcSubject, lcMessage)
        EndIf
    EndProc
    
    *----------------------------------------------------------------
    * NotifyUploadConfirmation - Send upload confirmation
    *----------------------------------------------------------------
    Procedure NotifyUploadConfirmation(tcInvoiceNumber, tcIdSolicitare, tcStatus)
        Local lcSubject, lcMessage
        
        lcSubject = "Factură " + tcInvoiceNumber + " încărcată"
        
        lcMessage = "Factura " + tcInvoiceNumber + " a fost încărcată cu succes în SPV." + Chr(13) + Chr(10)
        lcMessage = lcMessage + Chr(13) + Chr(10)
        lcMessage = lcMessage + "ID Solicitare: " + tcIdSolicitare + Chr(13) + Chr(10)
        lcMessage = lcMessage + "Status: " + tcStatus + Chr(13) + Chr(10)
        lcMessage = lcMessage + "Data/Ora: " + Ttoc(DateTime()) + Chr(13) + Chr(10)
        
        Return This.NotifySuccess(lcSubject, lcMessage)
    EndProc
    
    *----------------------------------------------------------------
    * SendEmail - Send email via CDO
    *----------------------------------------------------------------
    Protected Procedure SendEmail(tcSubject, tcBody, tcType)
        Local loMessage, loConfig, llSuccess, i
        
        If Empty(This.cSmtpServer)
            This.oLogger.LogWarning("SMTP server neconfigurat")
            Return .F.
        EndIf
        
        llSuccess = .F.
        
        Try
            * Create CDO Message object
            loMessage = CreateObject("CDO.Message")
            loConfig = loMessage.Configuration
            
            * Configure SMTP settings
            loConfig.Fields.Item("http://schemas.microsoft.com/cdo/configuration/sendusing") = 2  && cdoSendUsingPort
            loConfig.Fields.Item("http://schemas.microsoft.com/cdo/configuration/smtpserver") = This.cSmtpServer
            loConfig.Fields.Item("http://schemas.microsoft.com/cdo/configuration/smtpserverport") = This.nSmtpPort
            
            If This.lSmtpUseSsl
                loConfig.Fields.Item("http://schemas.microsoft.com/cdo/configuration/smtpusessl") = .T.
            EndIf
            
            If Not Empty(This.cSmtpUser)
                loConfig.Fields.Item("http://schemas.microsoft.com/cdo/configuration/smtpauthenticate") = 1  && cdoBasic
                loConfig.Fields.Item("http://schemas.microsoft.com/cdo/configuration/sendusername") = This.cSmtpUser
                loConfig.Fields.Item("http://schemas.microsoft.com/cdo/configuration/sendpassword") = This.cSmtpPassword
            EndIf
            
            loConfig.Fields.Update()
            
            * Set message properties
            loMessage.From = This.cFromName + " <" + This.cFromEmail + ">"
            loMessage.Subject = tcSubject
            loMessage.TextBody = tcBody
            
            * Add HTML body with styling
            loMessage.HtmlBody = This.CreateHtmlBody(tcSubject, tcBody, tcType)
            
            * Add recipients
            For i = 1 To This.nEmailRecipientCount
                loMessage.To = loMessage.To + Iif(Empty(loMessage.To), "", ";") + This.aEmailRecipients[i, 1]
            Next
            
            * Send
            loMessage.Send()
            
            llSuccess = .T.
            
            This.oLogger.LogInfo("Email trimis: " + tcSubject)
        Catch
            This.oLogger.LogError("Eroare trimitere email: " + Message())
        EndTry
        
        Return llSuccess
    EndProc
    
    *----------------------------------------------------------------
    * CreateHtmlBody - Create HTML formatted email body
    *----------------------------------------------------------------
    Protected Procedure CreateHtmlBody(tcSubject, tcBody, tcType)
        Local lcHtml, lcColor
        
        Do Case
            Case tcType = This.cTypeError
                lcColor = "#dc3545"
            Case tcType = This.cTypeWarning
                lcColor = "#ffc107"
            Case tcType = This.cTypeSuccess
                lcColor = "#28a745"
            Otherwise
                lcColor = "#17a2b8"
        EndCase
        
        lcHtml = '<!DOCTYPE html>'
        lcHtml = lcHtml + '<html><head><meta charset="utf-8"></head>'
        lcHtml = lcHtml + '<body style="font-family: Arial, sans-serif; padding: 20px;">'
        lcHtml = lcHtml + '<div style="max-width: 600px; margin: 0 auto; border: 1px solid #ddd; border-radius: 8px; overflow: hidden;">'
        lcHtml = lcHtml + '<div style="background-color: ' + lcColor + '; color: white; padding: 15px 20px;">'
        lcHtml = lcHtml + '<h2 style="margin: 0;">' + tcSubject + '</h2>'
        lcHtml = lcHtml + '</div>'
        lcHtml = lcHtml + '<div style="padding: 20px;">'
        lcHtml = lcHtml + '<pre style="white-space: pre-wrap; font-family: inherit;">' + tcBody + '</pre>'
        lcHtml = lcHtml + '</div>'
        lcHtml = lcHtml + '<div style="background-color: #f8f9fa; padding: 10px 20px; font-size: 12px; color: #666;">'
        lcHtml = lcHtml + 'Trimis de eFactura System la ' + Ttoc(DateTime())
        lcHtml = lcHtml + '</div>'
        lcHtml = lcHtml + '</div>'
        lcHtml = lcHtml + '</body></html>'
        
        Return lcHtml
    EndProc
    
    *----------------------------------------------------------------
    * SendSms - Send SMS via HTTP API
    *----------------------------------------------------------------
    Protected Procedure SendSms(tcMessage)
        Local loHttp, lcUrl, llSuccess, i
        
        If Empty(This.cSmsApiUrl) Or Empty(This.cSmsApiKey)
            Return .F.
        EndIf
        
        llSuccess = .F.
        
        Try
            loHttp = CreateObject("MSXML2.XMLHTTP.6.0")
            
            For i = 1 To This.nSmsRecipientCount
                lcUrl = This.cSmsApiUrl
                lcUrl = lcUrl + "?api_key=" + This.cSmsApiKey
                lcUrl = lcUrl + "&to=" + This.aSmsRecipients[i]
                lcUrl = lcUrl + "&from=" + This.cSmsFrom
                lcUrl = lcUrl + "&message=" + This.UrlEncode(tcMessage)
                
                loHttp.Open("GET", lcUrl, .F.)
                loHttp.Send()
                
                If loHttp.Status = 200
                    llSuccess = .T.
                EndIf
            Next
            
            This.oLogger.LogInfo("SMS trimis: " + Left(tcMessage, 50))
        Catch
            This.oLogger.LogError("Eroare trimitere SMS: " + Message())
        EndTry
        
        Return llSuccess
    EndProc
    
    *----------------------------------------------------------------
    * UrlEncode - URL encode string
    *----------------------------------------------------------------
    Protected Procedure UrlEncode(tcString)
        Local lcResult, i, lcChar, lnAsc
        
        lcResult = ""
        
        For i = 1 To Len(tcString)
            lcChar = Substr(tcString, i, 1)
            lnAsc = Asc(lcChar)
            
            Do Case
                Case Between(lnAsc, 48, 57) Or Between(lnAsc, 65, 90) Or Between(lnAsc, 97, 122) ;
                     Or lcChar $ "-_.~"
                    lcResult = lcResult + lcChar
                Case lcChar = " "
                    lcResult = lcResult + "+"
                Otherwise
                    lcResult = lcResult + "%" + Padl(Transform(lnAsc, "@X"), 2, "0")
            EndCase
        Next
        
        Return lcResult
    EndProc
    
    *----------------------------------------------------------------
    * LogNotification - Log notification to table
    *----------------------------------------------------------------
    Protected Procedure LogNotification(tcType, tcSubject, tcMessage, tlEmailSent, tlSmsSent)
        Local lcLogFile, lcContent
        
        lcLogFile = AddBs(Sys(2023)) + "eFactura_Notifications.log"
        
        lcContent = Ttoc(DateTime()) + " | "
        lcContent = lcContent + tcType + " | "
        lcContent = lcContent + "Email:" + Iif(tlEmailSent, "OK", "SKIP") + " | "
        lcContent = lcContent + "SMS:" + Iif(tlSmsSent, "OK", "SKIP") + " | "
        lcContent = lcContent + tcSubject + Chr(13) + Chr(10)
        
        Try
            StrToFile(lcContent, lcLogFile, .T.)
        Catch
            * Silent fail
        EndTry
    EndProc
    
    *----------------------------------------------------------------
    * TestConnection - Test email configuration
    *----------------------------------------------------------------
    Procedure TestConnection
        Local llResult
        
        This.AddEmailRecipient(This.cFromEmail, "Test")
        llResult = This.SendEmail("Test eFactura Notification", "Aceasta este o notificare de test.", This.cTypeInfo)
        
        Return llResult
    EndProc

EndDefine
