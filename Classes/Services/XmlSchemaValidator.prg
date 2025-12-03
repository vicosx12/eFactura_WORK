*---------------------------------------------------------------------------
* Clasa: XmlSchemaValidator
* Descriere: Validator XSD pentru verificarea XML-ului generat
*            Verifica conformitatea cu schema UBL 2.1
* Autor: Copilot
* Data: 2024
*---------------------------------------------------------------------------

Define Class XmlSchemaValidator As Custom
	
	*-- Proprietati
	cSchemaPath = ""             && Calea catre schema XSD
	cLastError = ""              && Ultima eroare
	Dimension aErrors[1]         && Lista de erori
	nErrorCount = 0
	Dimension aWarnings[1]       && Lista de warning-uri
	nWarningCount = 0
	oLogger = .Null.
	lUseExternalValidator = .F.  && Foloseste MSXML sau extern
	
	*-- Schema URIs
	cUBL_Invoice_Schema = "urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"
	cUBL_CreditNote_Schema = "urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2"
	
	*---------------------------------------------------------------------------
	* Procedura: Init
	* Descriere: Initializeaza validatorul
	*---------------------------------------------------------------------------
	Procedure Init()
		This.nErrorCount = 0
		This.nWarningCount = 0
		This.cLastError = ""
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: Validate
	* Descriere: Valideaza un XML
	* Parametri: 
	*   tcXmlContent - Continutul XML
	*   tcSchemaPath - Calea catre schema (optional)
	* Returneaza: Logical - Valid sau nu
	*---------------------------------------------------------------------------
	Function Validate(tcXmlContent, tcSchemaPath)
		Local llValid
		
		This.ClearErrors()
		
		If Empty(tcXmlContent)
			This.AddError("XML content is empty")
			Return .F.
		EndIf
		
		If Not Empty(tcSchemaPath)
			This.cSchemaPath = tcSchemaPath
		EndIf
		
		*-- Validare de baza (well-formed)
		llValid = This.ValidateWellFormed(tcXmlContent)
		
		If Not llValid
			Return .F.
		EndIf
		
		*-- Validare structura UBL
		llValid = This.ValidateUBLStructure(tcXmlContent)
		
		If Not llValid
			Return .F.
		EndIf
		
		*-- Validare campuri obligatorii
		llValid = This.ValidateRequiredFields(tcXmlContent)
		
		If Not llValid
			Return .F.
		EndIf
		
		*-- Validare cu schema XSD (daca e disponibila)
		If Not Empty(This.cSchemaPath) And File(This.cSchemaPath)
			llValid = This.ValidateAgainstSchema(tcXmlContent)
		EndIf
		
		This.Log("Validation result: " + Iif(llValid, "VALID", "INVALID"))
		
		Return llValid
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: ValidateWellFormed
	* Descriere: Verifica daca XML-ul e well-formed
	* Parametri: 
	*   tcXmlContent - Continutul XML
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Protected Function ValidateWellFormed(tcXmlContent)
		Local loXml, llValid
		llValid = .T.
		
		Try
			loXml = CreateObject("MSXML2.DOMDocument.6.0")
			loXml.Async = .F.
			loXml.ValidateOnParse = .F.
			
			If Not loXml.LoadXML(tcXmlContent)
				This.AddError("XML is not well-formed: " + loXml.ParseError.Reason + ;
					" at line " + Transform(loXml.ParseError.Line))
				llValid = .F.
			EndIf
		Catch To loException
			This.AddError("XML parsing error: " + loException.Message)
			llValid = .F.
		Finally
			loXml = .Null.
		EndTry
		
		Return llValid
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: ValidateUBLStructure
	* Descriere: Verifica structura de baza UBL
	* Parametri: 
	*   tcXmlContent - Continutul XML
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Protected Function ValidateUBLStructure(tcXmlContent)
		Local loXml, loRoot, llValid, lcRootName
		llValid = .T.
		
		Try
			loXml = CreateObject("MSXML2.DOMDocument.6.0")
			loXml.Async = .F.
			loXml.LoadXML(tcXmlContent)
			
			loRoot = loXml.DocumentElement
			
			If IsNull(loRoot)
				This.AddError("No root element found")
				Return .F.
			EndIf
			
			lcRootName = loRoot.BaseName
			
			*-- Verifica root element
			If Not InList(lcRootName, "Invoice", "CreditNote")
				This.AddError("Invalid root element: " + lcRootName + ;
					". Expected 'Invoice' or 'CreditNote'")
				llValid = .F.
			EndIf
			
			*-- Verifica namespace
			Local lcNamespace
			lcNamespace = loRoot.NamespaceURI
			
			If Empty(lcNamespace)
				This.AddWarning("No namespace defined on root element")
			ElseIf Not ("urn:oasis:names:specification:ubl:schema:xsd" $ lcNamespace)
				This.AddWarning("Non-standard namespace: " + lcNamespace)
			EndIf
			
		Catch To loException
			This.AddError("Structure validation error: " + loException.Message)
			llValid = .F.
		Finally
			loXml = .Null.
		EndTry
		
		Return llValid
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: ValidateRequiredFields
	* Descriere: Verifica campurile obligatorii conform standard SR EN 16931
	* Nota: Lista de campuri este fixa conform standardul UBL 2.1 pentru e-Factura
	* Parametri: 
	*   tcXmlContent - Continutul XML
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Protected Function ValidateRequiredFields(tcXmlContent)
		Local loXml, llValid, i, lnFieldCount
		llValid = .T.
		
		*-- Campuri obligatorii conform SR EN 16931 / UBL 2.1
		*-- Nota: Lista este fixa conform standard, nu necesita dimensionare dinamica
		lnFieldCount = 15
		Dimension laRequiredFields[lnFieldCount]
		laRequiredFields[1] = "cbc:ID"                    && BT-1 Invoice number
		laRequiredFields[2] = "cbc:IssueDate"             && BT-2 Issue date
		laRequiredFields[3] = "cbc:InvoiceTypeCode"       && BT-3 Invoice type code
		laRequiredFields[4] = "cbc:DocumentCurrencyCode"  && BT-5 Invoice currency
		laRequiredFields[5] = "cac:AccountingSupplierParty"  && BG-4 Seller
		laRequiredFields[6] = "cac:AccountingCustomerParty"  && BG-7 Buyer
		laRequiredFields[7] = "cac:InvoiceLine"           && BG-25 Invoice line
		laRequiredFields[8] = "cac:LegalMonetaryTotal"    && BG-22 Totals
		laRequiredFields[9] = "cbc:PayableAmount"         && BT-115 Amount due
		laRequiredFields[10] = "cac:TaxTotal"             && BG-23 Tax breakdown
		laRequiredFields[11] = "cbc:TaxAmount"            && BT-110 Tax amount
		laRequiredFields[12] = "cac:PartyName"            && Party name
		laRequiredFields[13] = "cac:PostalAddress"        && Address
		laRequiredFields[14] = "cbc:CompanyID"            && Company ID
		laRequiredFields[15] = "cac:Country"              && Country
		
		Try
			loXml = CreateObject("MSXML2.DOMDocument.6.0")
			loXml.Async = .F.
			loXml.SetProperty("SelectionNamespaces", ;
				"xmlns:cbc='urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2' " + ;
				"xmlns:cac='urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2'")
			loXml.LoadXML(tcXmlContent)
			
			*-- Verifica fiecare camp obligatoriu
			For i = 1 To lnFieldCount
				Local loNodes
				loNodes = loXml.SelectNodes("//" + laRequiredFields[i])
				
				If loNodes.Length = 0
					This.AddError("Missing required field: " + laRequiredFields[i])
					llValid = .F.
				EndIf
			EndFor
			
			*-- Verifica ID nu e gol
			Local loIdNode
			loIdNode = loXml.SelectSingleNode("//cbc:ID")
			If Not IsNull(loIdNode) And Empty(AllTrim(loIdNode.Text))
				This.AddError("Invoice ID (BT-1) cannot be empty")
				llValid = .F.
			EndIf
			
		Catch To loException
			This.AddError("Required fields validation error: " + loException.Message)
			llValid = .F.
		Finally
			loXml = .Null.
		EndTry
		
		Return llValid
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: ValidateAgainstSchema
	* Descriere: Valideaza XML-ul contra schema XSD
	* Parametri: 
	*   tcXmlContent - Continutul XML
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Protected Function ValidateAgainstSchema(tcXmlContent)
		Local loXml, loSchema, llValid
		llValid = .T.
		
		Try
			loSchema = CreateObject("MSXML2.XMLSchemaCache.6.0")
			loSchema.Add("", This.cSchemaPath)
			
			loXml = CreateObject("MSXML2.DOMDocument.6.0")
			loXml.Async = .F.
			loXml.ValidateOnParse = .T.
			loXml.Schemas = loSchema
			
			If Not loXml.LoadXML(tcXmlContent)
				This.AddError("Schema validation failed: " + loXml.ParseError.Reason)
				llValid = .F.
			EndIf
			
		Catch To loException
			*-- Daca nu poate valida cu schema, continua cu warning
			This.AddWarning("Could not validate against XSD schema: " + loException.Message)
			*-- Nu marcam ca invalid, doar warning
		Finally
			loXml = .Null.
			loSchema = .Null.
		EndTry
		
		Return llValid
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: ValidateBusinessRules
	* Descriere: Valideaza regulile de business CIUS-RO
	* Parametri: 
	*   tcXmlContent - Continutul XML
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Function ValidateBusinessRules(tcXmlContent)
		Local loXml, llValid
		llValid = .T.
		
		Try
			loXml = CreateObject("MSXML2.DOMDocument.6.0")
			loXml.Async = .F.
			loXml.SetProperty("SelectionNamespaces", ;
				"xmlns:cbc='urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2' " + ;
				"xmlns:cac='urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2'")
			loXml.LoadXML(tcXmlContent)
			
			*-- CIUS-RO-001: Seller must have VAT ID
			Local loVatId
			loVatId = loXml.SelectSingleNode("//cac:AccountingSupplierParty//cbc:CompanyID")
			If IsNull(loVatId) Or Empty(AllTrim(loVatId.Text))
				This.AddError("CIUS-RO-001: Seller VAT ID is required")
				llValid = .F.
			EndIf
			
			*-- CIUS-RO-002: Buyer must have identification
			Local loBuyerId
			loBuyerId = loXml.SelectSingleNode("//cac:AccountingCustomerParty//cbc:CompanyID")
			If IsNull(loBuyerId) Or Empty(AllTrim(loBuyerId.Text))
				*-- Poate fi si CNP pentru B2C
				loBuyerId = loXml.SelectSingleNode("//cac:AccountingCustomerParty//cbc:ID")
				If IsNull(loBuyerId) Or Empty(AllTrim(loBuyerId.Text))
					This.AddWarning("CIUS-RO-002: Buyer identification is recommended")
				EndIf
			EndIf
			
			*-- CIUS-RO-003: Currency must be RON or valid ISO code
			Local loCurrency
			loCurrency = loXml.SelectSingleNode("//cbc:DocumentCurrencyCode")
			If Not IsNull(loCurrency)
				Local lcCurrency
				lcCurrency = Upper(AllTrim(loCurrency.Text))
				If Not InList(lcCurrency, "RON", "EUR", "USD", "GBP", "CHF", "HUF", "PLN", "CZK", "BGN")
					This.AddWarning("CIUS-RO-003: Unusual currency code: " + lcCurrency)
				EndIf
			EndIf
			
			*-- Verifica totale
			llValid = This.ValidateTotals(loXml) And llValid
			
		Catch To loException
			This.AddError("Business rules validation error: " + loException.Message)
			llValid = .F.
		Finally
			loXml = .Null.
		EndTry
		
		Return llValid
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: ValidateTotals
	* Descriere: Verifica consistenta totalelor
	* Parametri: 
	*   toXml - Obiectul XML DOM
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Protected Function ValidateTotals(toXml)
		Local llValid, lnLineTotal, lnTaxAmount, lnPayable, lnTaxExclusive, lnTaxInclusive
		llValid = .T.
		
		Try
			*-- Citeste totalele
			Local loNode
			
			loNode = toXml.SelectSingleNode("//cac:LegalMonetaryTotal/cbc:LineExtensionAmount")
			lnLineTotal = Iif(IsNull(loNode), 0, Val(loNode.Text))
			
			loNode = toXml.SelectSingleNode("//cac:LegalMonetaryTotal/cbc:TaxExclusiveAmount")
			lnTaxExclusive = Iif(IsNull(loNode), 0, Val(loNode.Text))
			
			loNode = toXml.SelectSingleNode("//cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount")
			lnTaxInclusive = Iif(IsNull(loNode), 0, Val(loNode.Text))
			
			loNode = toXml.SelectSingleNode("//cac:LegalMonetaryTotal/cbc:PayableAmount")
			lnPayable = Iif(IsNull(loNode), 0, Val(loNode.Text))
			
			loNode = toXml.SelectSingleNode("//cac:TaxTotal/cbc:TaxAmount")
			lnTaxAmount = Iif(IsNull(loNode), 0, Val(loNode.Text))
			
			*-- Verifica consistenta
			Local lnDiff
			
			*-- TaxInclusive = TaxExclusive + TaxAmount
			lnDiff = Abs(lnTaxInclusive - (lnTaxExclusive + lnTaxAmount))
			If lnDiff > 0.01
				This.AddError("Total inconsistency: TaxInclusiveAmount (" + Transform(lnTaxInclusive) + ;
					") != TaxExclusiveAmount + TaxAmount (" + Transform(lnTaxExclusive + lnTaxAmount) + ")")
				llValid = .F.
			EndIf
			
			*-- PayableAmount should equal TaxInclusiveAmount (in most cases)
			lnDiff = Abs(lnPayable - lnTaxInclusive)
			If lnDiff > 0.01
				This.AddWarning("PayableAmount (" + Transform(lnPayable) + ;
					") differs from TaxInclusiveAmount (" + Transform(lnTaxInclusive) + ")")
			EndIf
			
		Catch To loException
			This.AddWarning("Could not validate totals: " + loException.Message)
		EndTry
		
		Return llValid
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: AddError
	* Descriere: Adauga o eroare
	*---------------------------------------------------------------------------
	Protected Procedure AddError(tcMessage)
		This.nErrorCount = This.nErrorCount + 1
		Dimension This.aErrors[This.nErrorCount]
		This.aErrors[This.nErrorCount] = tcMessage
		This.cLastError = tcMessage
		This.Log("ERROR: " + tcMessage)
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: AddWarning
	* Descriere: Adauga un warning
	*---------------------------------------------------------------------------
	Protected Procedure AddWarning(tcMessage)
		This.nWarningCount = This.nWarningCount + 1
		Dimension This.aWarnings[This.nWarningCount]
		This.aWarnings[This.nWarningCount] = tcMessage
		This.Log("WARNING: " + tcMessage)
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: ClearErrors
	* Descriere: Goleste listele de erori si warning-uri
	*---------------------------------------------------------------------------
	Procedure ClearErrors()
		This.nErrorCount = 0
		This.nWarningCount = 0
		Dimension This.aErrors[1]
		Dimension This.aWarnings[1]
		This.cLastError = ""
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: GetErrors
	* Descriere: Returneaza erorile ca string
	* Returneaza: String
	*---------------------------------------------------------------------------
	Function GetErrors()
		Local lcErrors, i
		lcErrors = ""
		
		For i = 1 To This.nErrorCount
			lcErrors = lcErrors + This.aErrors[i] + Chr(13) + Chr(10)
		EndFor
		
		Return lcErrors
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetWarnings
	* Descriere: Returneaza warning-urile ca string
	* Returneaza: String
	*---------------------------------------------------------------------------
	Function GetWarnings()
		Local lcWarnings, i
		lcWarnings = ""
		
		For i = 1 To This.nWarningCount
			lcWarnings = lcWarnings + This.aWarnings[i] + Chr(13) + Chr(10)
		EndFor
		
		Return lcWarnings
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: IsValid
	* Descriere: Returneaza daca ultimul XML validat e valid
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Function IsValid()
		Return This.nErrorCount = 0
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: HasWarnings
	* Descriere: Returneaza daca sunt warning-uri
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Function HasWarnings()
		Return This.nWarningCount > 0
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: Log
	* Descriere: Scrie in log
	*---------------------------------------------------------------------------
	Protected Procedure Log(tcMessage)
		If VarType(This.oLogger) = 'O' And Not IsNull(This.oLogger)
			This.oLogger.Debug("[XmlSchemaValidator] " + tcMessage)
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: SetLogger
	* Descriere: Seteaza logger-ul
	*---------------------------------------------------------------------------
	Procedure SetLogger(toLogger)
		This.oLogger = toLogger
	EndProc
	
EndDefine
