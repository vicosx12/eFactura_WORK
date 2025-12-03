*====================================================================
* PdfGenerator - Invoice PDF Generation from UBL XML
* 
* Features:
* - Generate PDF visualization from XML
* - Multiple templates support
* - Export to various formats
*
* Visual FoxPro 9 SP2 Compatible
*====================================================================

Define Class PdfGenerator As Custom
    
    * Configuration
    cOutputPath = ""
    cTemplatePath = ""
    cDefaultTemplate = "invoice_template.frx"
    lIncludeLogo = .T.
    cLogoPath = ""
    
    * Page settings
    nPageWidth = 210   && mm (A4)
    nPageHeight = 297  && mm (A4)
    nMarginTop = 15
    nMarginBottom = 15
    nMarginLeft = 15
    nMarginRight = 15
    
    * Logger
    oLogger = .Null.
    
    *----------------------------------------------------------------
    * Init
    *----------------------------------------------------------------
    Procedure Init
        This.oLogger = CreateObject("LoggerService")
        This.cOutputPath = AddBs(JustPath(Sys(16))) + "Output\"
        This.cTemplatePath = AddBs(JustPath(Sys(16))) + "Templates\"
        
        * Create directories if needed
        If Not Directory(This.cOutputPath)
            Mkdir (This.cOutputPath)
        EndIf
    EndProc
    
    *----------------------------------------------------------------
    * GenerateFromXml - Generate PDF from UBL XML
    *----------------------------------------------------------------
    Procedure GenerateFromXml(tcXmlContent, tcOutputFile)
        Local loInvoice, lcPdfFile
        
        * Parse XML to invoice object
        loInvoice = This.ParseXml(tcXmlContent)
        
        If IsNull(loInvoice)
            This.oLogger.LogError("Nu s-a putut parsa XML-ul pentru PDF")
            Return ""
        EndIf
        
        * Generate PDF
        lcPdfFile = This.GeneratePdf(loInvoice, tcOutputFile)
        
        Return lcPdfFile
    EndProc
    
    *----------------------------------------------------------------
    * GenerateFromFile - Generate PDF from XML file
    *----------------------------------------------------------------
    Procedure GenerateFromFile(tcXmlFile, tcOutputFile)
        Local lcXmlContent
        
        If Not File(tcXmlFile)
            This.oLogger.LogError("Fișier XML negăsit: " + tcXmlFile)
            Return ""
        EndIf
        
        lcXmlContent = FileToStr(tcXmlFile)
        
        Return This.GenerateFromXml(lcXmlContent, tcOutputFile)
    EndProc
    
    *----------------------------------------------------------------
    * ParseXml - Parse UBL XML to invoice object
    *----------------------------------------------------------------
    Protected Procedure ParseXml(tcXmlContent)
        Local loInvoice, loXml
        
        Try
            loXml = CreateObject("MSXML2.DOMDocument.6.0")
            loXml.Async = .F.
            loXml.LoadXml(tcXmlContent)
            
            If loXml.ParseError.ErrorCode <> 0
                This.oLogger.LogError("Eroare parsare XML: " + loXml.ParseError.Reason)
                Return .Null.
            EndIf
            
            * Create invoice object
            loInvoice = CreateObject("Empty")
            
            * Extract header info
            AddProperty(loInvoice, "Number", This.GetXmlValue(loXml, "//cbc:ID"))
            AddProperty(loInvoice, "IssueDate", This.GetXmlValue(loXml, "//cbc:IssueDate"))
            AddProperty(loInvoice, "DueDate", This.GetXmlValue(loXml, "//cbc:DueDate"))
            AddProperty(loInvoice, "Currency", This.GetXmlValue(loXml, "//cbc:DocumentCurrencyCode"))
            AddProperty(loInvoice, "InvoiceTypeCode", This.GetXmlValue(loXml, "//cbc:InvoiceTypeCode"))
            
            * Supplier info
            AddProperty(loInvoice, "SupplierName", This.GetXmlValue(loXml, "//cac:AccountingSupplierParty//cbc:RegistrationName"))
            AddProperty(loInvoice, "SupplierCUI", This.GetXmlValue(loXml, "//cac:AccountingSupplierParty//cbc:CompanyID"))
            AddProperty(loInvoice, "SupplierAddress", This.GetXmlValue(loXml, "//cac:AccountingSupplierParty//cbc:StreetName"))
            AddProperty(loInvoice, "SupplierCity", This.GetXmlValue(loXml, "//cac:AccountingSupplierParty//cbc:CityName"))
            AddProperty(loInvoice, "SupplierCountry", This.GetXmlValue(loXml, "//cac:AccountingSupplierParty//cbc:IdentificationCode"))
            
            * Customer info
            AddProperty(loInvoice, "CustomerName", This.GetXmlValue(loXml, "//cac:AccountingCustomerParty//cbc:RegistrationName"))
            AddProperty(loInvoice, "CustomerCUI", This.GetXmlValue(loXml, "//cac:AccountingCustomerParty//cbc:CompanyID"))
            AddProperty(loInvoice, "CustomerAddress", This.GetXmlValue(loXml, "//cac:AccountingCustomerParty//cbc:StreetName"))
            AddProperty(loInvoice, "CustomerCity", This.GetXmlValue(loXml, "//cac:AccountingCustomerParty//cbc:CityName"))
            AddProperty(loInvoice, "CustomerCountry", This.GetXmlValue(loXml, "//cac:AccountingCustomerParty//cbc:IdentificationCode"))
            
            * Totals
            AddProperty(loInvoice, "TaxableAmount", Val(This.GetXmlValue(loXml, "//cac:TaxTotal//cbc:TaxableAmount")))
            AddProperty(loInvoice, "TaxAmount", Val(This.GetXmlValue(loXml, "//cac:TaxTotal//cbc:TaxAmount")))
            AddProperty(loInvoice, "TotalAmount", Val(This.GetXmlValue(loXml, "//cac:LegalMonetaryTotal//cbc:PayableAmount")))
            
            * Lines
            Dimension loInvoice.aLines[1, 6]  && Description, Quantity, Unit, UnitPrice, TaxRate, LineTotal
            loInvoice.nLineCount = 0
            
            This.ParseInvoiceLines(loXml, loInvoice)
            
        Catch
            This.oLogger.LogError("Eroare parsare XML: " + Message())
            Return .Null.
        EndTry
        
        Return loInvoice
    EndProc
    
    *----------------------------------------------------------------
    * GetXmlValue - Get value from XPath
    *----------------------------------------------------------------
    Protected Procedure GetXmlValue(toXml, tcXPath)
        Local loNode
        
        * Set namespaces
        toXml.SetProperty("SelectionNamespaces", ;
            'xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" ' + ;
            'xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"')
        
        loNode = toXml.SelectSingleNode(tcXPath)
        
        If IsNull(loNode)
            Return ""
        EndIf
        
        Return loNode.Text
    EndProc
    
    *----------------------------------------------------------------
    * ParseInvoiceLines - Parse invoice lines from XML
    *----------------------------------------------------------------
    Protected Procedure ParseInvoiceLines(toXml, toInvoice)
        Local loLines, loLine, i, lnCount
        
        toXml.SetProperty("SelectionNamespaces", ;
            'xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" ' + ;
            'xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"')
        
        loLines = toXml.SelectNodes("//cac:InvoiceLine")
        lnCount = loLines.Length
        
        If lnCount > 0
            Dimension toInvoice.aLines[lnCount, 6]
            toInvoice.nLineCount = lnCount
            
            For i = 0 To lnCount - 1
                loLine = loLines.Item(i)
                
                toInvoice.aLines[i + 1, 1] = This.GetNodeValue(loLine, "cac:Item/cbc:Name")
                toInvoice.aLines[i + 1, 2] = Val(This.GetNodeValue(loLine, "cbc:InvoicedQuantity"))
                toInvoice.aLines[i + 1, 3] = This.GetNodeValue(loLine, "cbc:InvoicedQuantity/@unitCode")
                toInvoice.aLines[i + 1, 4] = Val(This.GetNodeValue(loLine, "cac:Price/cbc:PriceAmount"))
                toInvoice.aLines[i + 1, 5] = Val(This.GetNodeValue(loLine, "cac:Item/cac:ClassifiedTaxCategory/cbc:Percent"))
                toInvoice.aLines[i + 1, 6] = Val(This.GetNodeValue(loLine, "cbc:LineExtensionAmount"))
            Next
        EndIf
    EndProc
    
    *----------------------------------------------------------------
    * GetNodeValue - Get value from node
    *----------------------------------------------------------------
    Protected Procedure GetNodeValue(toNode, tcXPath)
        Local loChild
        
        loChild = toNode.SelectSingleNode(tcXPath)
        
        If IsNull(loChild)
            Return ""
        EndIf
        
        Return loChild.Text
    EndProc
    
    *----------------------------------------------------------------
    * GeneratePdf - Generate PDF from invoice object
    *----------------------------------------------------------------
    Protected Procedure GeneratePdf(toInvoice, tcOutputFile)
        Local lcPdfFile, lcTempPrinter
        
        * Determine output file
        If Empty(tcOutputFile)
            lcPdfFile = AddBs(This.cOutputPath) + "Invoice_" + toInvoice.Number + "_" + Dtos(Date()) + ".pdf"
        Else
            lcPdfFile = tcOutputFile
        EndIf
        
        * Create cursor with invoice data
        This.CreateReportCursor(toInvoice)
        
        * Check if using built-in report or generating programmatically
        If File(AddBs(This.cTemplatePath) + This.cDefaultTemplate)
            * Use report template
            lcPdfFile = This.GenerateFromReport(toInvoice, lcPdfFile)
        Else
            * Generate programmatically using text output
            lcPdfFile = This.GenerateTextPdf(toInvoice, lcPdfFile)
        EndIf
        
        Return lcPdfFile
    EndProc
    
    *----------------------------------------------------------------
    * CreateReportCursor - Create cursor for report
    *----------------------------------------------------------------
    Protected Procedure CreateReportCursor(toInvoice)
        * Header cursor
        Create Cursor InvoiceHeader ;
            (Number C(50), IssueDate C(20), DueDate C(20), Currency C(10), ;
             SupplierName C(200), SupplierCUI C(20), SupplierAddress C(200), ;
             SupplierCity C(100), SupplierCountry C(50), ;
             CustomerName C(200), CustomerCUI C(20), CustomerAddress C(200), ;
             CustomerCity C(100), CustomerCountry C(50), ;
             TaxableAmount N(15, 2), TaxAmount N(15, 2), TotalAmount N(15, 2))
        
        Insert Into InvoiceHeader Values ;
            (toInvoice.Number, toInvoice.IssueDate, toInvoice.DueDate, toInvoice.Currency, ;
             toInvoice.SupplierName, toInvoice.SupplierCUI, toInvoice.SupplierAddress, ;
             toInvoice.SupplierCity, toInvoice.SupplierCountry, ;
             toInvoice.CustomerName, toInvoice.CustomerCUI, toInvoice.CustomerAddress, ;
             toInvoice.CustomerCity, toInvoice.CustomerCountry, ;
             toInvoice.TaxableAmount, toInvoice.TaxAmount, toInvoice.TotalAmount)
        
        * Lines cursor
        Create Cursor InvoiceLines ;
            (Description C(200), Quantity N(10, 3), Unit C(20), ;
             UnitPrice N(15, 4), TaxRate N(5, 2), LineTotal N(15, 2))
        
        Local i
        For i = 1 To toInvoice.nLineCount
            Insert Into InvoiceLines Values ;
                (toInvoice.aLines[i, 1], toInvoice.aLines[i, 2], toInvoice.aLines[i, 3], ;
                 toInvoice.aLines[i, 4], toInvoice.aLines[i, 5], toInvoice.aLines[i, 6])
        Next
    EndProc
    
    *----------------------------------------------------------------
    * GenerateFromReport - Generate PDF using FRX report
    *----------------------------------------------------------------
    Protected Procedure GenerateFromReport(toInvoice, tcPdfFile)
        Local lcTemplate
        
        lcTemplate = AddBs(This.cTemplatePath) + This.cDefaultTemplate
        
        Try
            * Use report form with PDF output
            Report Form (lcTemplate) To File (tcPdfFile) Ascii
            
            This.oLogger.LogInfo("PDF generat: " + tcPdfFile)
        Catch
            This.oLogger.LogError("Eroare generare PDF din raport: " + Message())
            Return ""
        EndTry
        
        Return tcPdfFile
    EndProc
    
    *----------------------------------------------------------------
    * GenerateTextPdf - Generate text-based PDF (fallback)
    *----------------------------------------------------------------
    Protected Procedure GenerateTextPdf(toInvoice, tcPdfFile)
        Local lcContent, lcTextFile, i
        
        * Generate HTML content
        lcContent = This.GenerateHtml(toInvoice)
        
        * Save as HTML (can be converted to PDF externally)
        lcTextFile = StrTran(tcPdfFile, ".pdf", ".html")
        StrToFile(lcContent, lcTextFile)
        
        This.oLogger.LogInfo("HTML generat (pentru conversie PDF): " + lcTextFile)
        
        Return lcTextFile
    EndProc
    
    *----------------------------------------------------------------
    * GenerateHtml - Generate HTML representation
    *----------------------------------------------------------------
    Procedure GenerateHtml(toInvoice)
        Local lcHtml, i
        
        lcHtml = '<!DOCTYPE html>'
        lcHtml = lcHtml + '<html><head><meta charset="utf-8">'
        lcHtml = lcHtml + '<title>Factura ' + toInvoice.Number + '</title>'
        lcHtml = lcHtml + '<style>'
        lcHtml = lcHtml + 'body { font-family: Arial, sans-serif; margin: 40px; }'
        lcHtml = lcHtml + '.header { border-bottom: 2px solid #333; padding-bottom: 20px; margin-bottom: 20px; }'
        lcHtml = lcHtml + '.party { display: inline-block; width: 45%; vertical-align: top; }'
        lcHtml = lcHtml + 'table { width: 100%; border-collapse: collapse; margin-top: 20px; }'
        lcHtml = lcHtml + 'th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }'
        lcHtml = lcHtml + 'th { background-color: #f0f0f0; }'
        lcHtml = lcHtml + '.totals { margin-top: 20px; text-align: right; }'
        lcHtml = lcHtml + '.totals td { border: none; }'
        lcHtml = lcHtml + '</style></head><body>'
        
        * Header
        lcHtml = lcHtml + '<div class="header">'
        lcHtml = lcHtml + '<h1>FACTURĂ</h1>'
        lcHtml = lcHtml + '<p>Număr: <strong>' + toInvoice.Number + '</strong></p>'
        lcHtml = lcHtml + '<p>Data emiterii: ' + toInvoice.IssueDate + '</p>'
        lcHtml = lcHtml + '<p>Data scadenței: ' + toInvoice.DueDate + '</p>'
        lcHtml = lcHtml + '</div>'
        
        * Parties
        lcHtml = lcHtml + '<div class="parties">'
        lcHtml = lcHtml + '<div class="party">'
        lcHtml = lcHtml + '<h3>Furnizor</h3>'
        lcHtml = lcHtml + '<p><strong>' + toInvoice.SupplierName + '</strong></p>'
        lcHtml = lcHtml + '<p>CUI: ' + toInvoice.SupplierCUI + '</p>'
        lcHtml = lcHtml + '<p>' + toInvoice.SupplierAddress + '</p>'
        lcHtml = lcHtml + '<p>' + toInvoice.SupplierCity + ', ' + toInvoice.SupplierCountry + '</p>'
        lcHtml = lcHtml + '</div>'
        lcHtml = lcHtml + '<div class="party">'
        lcHtml = lcHtml + '<h3>Client</h3>'
        lcHtml = lcHtml + '<p><strong>' + toInvoice.CustomerName + '</strong></p>'
        lcHtml = lcHtml + '<p>CUI: ' + toInvoice.CustomerCUI + '</p>'
        lcHtml = lcHtml + '<p>' + toInvoice.CustomerAddress + '</p>'
        lcHtml = lcHtml + '<p>' + toInvoice.CustomerCity + ', ' + toInvoice.CustomerCountry + '</p>'
        lcHtml = lcHtml + '</div>'
        lcHtml = lcHtml + '</div>'
        
        * Lines table
        lcHtml = lcHtml + '<table>'
        lcHtml = lcHtml + '<thead><tr>'
        lcHtml = lcHtml + '<th>Nr.</th><th>Descriere</th><th>Cantitate</th><th>U.M.</th>'
        lcHtml = lcHtml + '<th>Preț unitar</th><th>TVA %</th><th>Total</th>'
        lcHtml = lcHtml + '</tr></thead><tbody>'
        
        For i = 1 To toInvoice.nLineCount
            lcHtml = lcHtml + '<tr>'
            lcHtml = lcHtml + '<td>' + Transform(i) + '</td>'
            lcHtml = lcHtml + '<td>' + toInvoice.aLines[i, 1] + '</td>'
            lcHtml = lcHtml + '<td>' + Transform(toInvoice.aLines[i, 2]) + '</td>'
            lcHtml = lcHtml + '<td>' + toInvoice.aLines[i, 3] + '</td>'
            lcHtml = lcHtml + '<td>' + Transform(toInvoice.aLines[i, 4], "999,999.99") + '</td>'
            lcHtml = lcHtml + '<td>' + Transform(toInvoice.aLines[i, 5]) + '%</td>'
            lcHtml = lcHtml + '<td>' + Transform(toInvoice.aLines[i, 6], "999,999.99") + '</td>'
            lcHtml = lcHtml + '</tr>'
        Next
        
        lcHtml = lcHtml + '</tbody></table>'
        
        * Totals
        lcHtml = lcHtml + '<table class="totals">'
        lcHtml = lcHtml + '<tr><td>Bază impozabilă:</td><td>' + Transform(toInvoice.TaxableAmount, "999,999.99") + ' ' + toInvoice.Currency + '</td></tr>'
        lcHtml = lcHtml + '<tr><td>TVA:</td><td>' + Transform(toInvoice.TaxAmount, "999,999.99") + ' ' + toInvoice.Currency + '</td></tr>'
        lcHtml = lcHtml + '<tr><td><strong>TOTAL:</strong></td><td><strong>' + Transform(toInvoice.TotalAmount, "999,999.99") + ' ' + toInvoice.Currency + '</strong></td></tr>'
        lcHtml = lcHtml + '</table>'
        
        lcHtml = lcHtml + '<p style="margin-top: 40px; font-size: 10px; color: #666;">'
        lcHtml = lcHtml + 'Document generat automat din e-Factura la ' + Ttoc(DateTime())
        lcHtml = lcHtml + '</p>'
        
        lcHtml = lcHtml + '</body></html>'
        
        Return lcHtml
    EndProc
    
    *----------------------------------------------------------------
    * PreviewInvoice - Open invoice preview in browser
    *----------------------------------------------------------------
    Procedure PreviewInvoice(tcXmlContent)
        Local loInvoice, lcHtml, lcTempFile
        
        loInvoice = This.ParseXml(tcXmlContent)
        
        If IsNull(loInvoice)
            Return .F.
        EndIf
        
        lcHtml = This.GenerateHtml(loInvoice)
        lcTempFile = AddBs(Sys(2023)) + "invoice_preview_" + Sys(2015) + ".html"
        
        StrToFile(lcHtml, lcTempFile)
        
        * Open in default browser
        Declare Integer ShellExecute In Shell32.Dll ;
            Integer, String, String, String, String, Integer
        
        ShellExecute(0, "open", lcTempFile, "", "", 1)
        
        Return .T.
    EndProc

EndDefine
