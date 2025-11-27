******************************************************************************************
*  CLASS: XmlBuilderHandler
*
*  AUTHOR: Refactored OOP Architecture
*
*  DESCRIPTION:
*     Handler pentru generarea fisierului XML UBL e-Factura.
*     Foloseste Strategy pattern pentru diferite tipuri de facturi.
*
*  DESIGN PATTERN: Chain of Responsibility + Strategy
*
*  XML ELEMENTS:
*     - Invoice header (BT-1 to BT-9)
*     - Seller/Buyer info (BG-4, BG-7)
*     - Payment info (BG-16, BG-17)
*     - Tax info (BG-23)
*     - Invoice lines (BG-25)
*
******************************************************************************************

Define Class XmlBuilderHandler As AbstractHandler
	
	cName = "XmlBuilderHandler"
	nOrder = 3
	
	*-- Referinta la strategia de generare XML
	oXmlStrategy = .Null.
	
	*-- Referinta la XmlStrategyFactory
	oStrategyFactory = .Null.
	
	*-- Referinta la ICAS (daca exista)
	lIsICAS = .F.
	oICAS = .Null.
	
	*-- Obiectul XML DOM
	oXml = .Null.
	oInvoice = .Null.
	
	*-- Setari XML
	cUblVersion = "2.1"
	cCustomizationId = "urn:cen.eu:en16931:2017#compliant#urn:efactura.mfinante.ro:CIUS-RO:1.0.1"
	
	*---------------------------------------------------------------------------
	* Procedura: Init
	* Descriere: Initializeaza handler-ul
	*---------------------------------------------------------------------------
	Procedure Init()
		DoDefault()
		This.lIsICAS = (VarType(ICAS) = 'O' And Not IsNull(ICAS))
		If This.lIsICAS
			This.oICAS = ICAS
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: DoHandle
	* Descriere: Genereaza XML-ul facturii
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	*---------------------------------------------------------------------------
	Protected Procedure DoHandle(toContext)
		*-- Selecteaza strategia potrivita
		This.SelectStrategy(toContext)
		
		*-- Initializeaza documentul XML
		This.InitXmlDocument()
		
		*-- Genereaza header-ul facturii
		This.GenerateInvoiceHeader(toContext)
		
		*-- Genereaza informatiile vanzator
		This.GenerateSellerInfo(toContext)
		
		*-- Genereaza informatiile cumparator
		This.GenerateBuyerInfo(toContext)
		
		*-- Genereaza informatiile de plata
		This.GeneratePaymentInfo(toContext)
		
		*-- Genereaza informatiile TVA
		This.GenerateTaxInfo(toContext)
		
		*-- Genereaza totalurile
		This.GenerateTotals(toContext)
		
		*-- Genereaza liniile facturii
		This.GenerateInvoiceLines(toContext)
		
		*-- Salveaza fisierul XML
		This.SaveXmlFile(toContext)
		
		This.LogInfo("XML generat cu succes: " + toContext.cXmlFilePath)
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: SelectStrategy
	* Descriere: Selecteaza strategia de generare XML
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	*---------------------------------------------------------------------------
	Protected Procedure SelectStrategy(toContext)
		*-- Pentru moment, folosim strategia implicita
		*-- Poate fi extins cu XmlStrategyFactory
		This.LogDebug("Strategie XML: Standard B2B")
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: InitXmlDocument
	* Descriere: Initializeaza documentul XML
	*---------------------------------------------------------------------------
	Protected Procedure InitXmlDocument()
		*-- Creeaza documentul XML
		This.oXml = CreateObject("msxml2.DOMDocument")
		
		*-- Adauga declaratia XML
		Local loPI
		loPI = This.oXml.CreateProcessingInstruction("xml", "version='1.0' encoding='UTF-8'")
		This.oXml.AppendChild(loPI)
		
		*-- Creeaza elementul root Invoice
		This.oInvoice = This.oXml.AppendChild(This.oXml.CreateElement("Invoice"))
		
		*-- Seteaza namespace-urile
		This.oInvoice.SetAttribute("xmlns:cbc", "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2")
		This.oInvoice.SetAttribute("xmlns:udt", "urn:oasis:names:specification:ubl:schema:xsd:UnqualifiedDataTypes-2")
		This.oInvoice.SetAttribute("xmlns:cac", "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2")
		This.oInvoice.SetAttribute("xmlns:ccts", "urn:un:unece:uncefact:documentation:2")
		This.oInvoice.SetAttribute("xmlns", "urn:oasis:names:specification:ubl:schema:xsd:Invoice-2")
		This.oInvoice.SetAttribute("xmlns:qdt", "urn:oasis:names:specification:ubl:schema:xsd:QualifiedDataTypes-2")
		This.oInvoice.SetAttribute("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance")
		
		*-- Adauga versiunea UBL
		This.AddElement("cbc:UBLVersionID", This.cUblVersion)
		
		*-- Adauga CustomizationID
		This.AddElement("cbc:CustomizationID", This.cCustomizationId)
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: GenerateInvoiceHeader
	* Descriere: Genereaza header-ul facturii
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	*---------------------------------------------------------------------------
	Protected Procedure GenerateInvoiceHeader(toContext)
		Local lcNumar, ldData, ldScadent, lcInvoiceType, lcMoneda
		
		Select crsEFactura
		Go Top
		
		lcNumar = AllTrim(crsEFactura.Nr)
		ldData = crsEFactura.Data
		ldScadent = Iif(Empty(crsEFactura.Scadent), ldData, crsEFactura.Scadent)
		lcMoneda = AllTrim(crsEFactura.Moneda)
		
		*-- BT-1: Numarul facturii
		This.AddElement("cbc:ID", lcNumar)
		
		*-- BT-2: Data emiterii
		This.AddElement("cbc:IssueDate", This.FormatDate(ldData))
		
		*-- BT-9: Data scadentei
		This.AddElement("cbc:DueDate", This.FormatDate(ldScadent))
		
		*-- BT-3: Codul tipului facturii
		lcInvoiceType = This.DetermineInvoiceType(toContext)
		This.AddElement("cbc:InvoiceTypeCode", lcInvoiceType)
		toContext.cInvoiceType = lcInvoiceType
		
		*-- Note (BT-22)
		This.GenerateNotes(toContext)
		
		*-- BT-5: Codul monedei
		This.AddElement("cbc:DocumentCurrencyCode", lcMoneda)
		toContext.cMoneda = lcMoneda
		
		*-- BT-6: Moneda TVA (intotdeauna RON)
		This.AddElement("cbc:TaxCurrencyCode", "RON")
		
		*-- Referinte comenzi si contracte
		This.GenerateReferences(toContext)
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: DetermineInvoiceType
	* Descriere: Determina codul tipului facturii
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	* Returneaza: String - Codul tipului (380, 381, 384, 389, 751)
	*---------------------------------------------------------------------------
	Protected Function DetermineInvoiceType(toContext)
		Local lcType, lcCodFiscal, lcTipFactura, lnLiniiStornare, lnLinii, lnTiparit
		
		lcCodFiscal = toContext.cCodFiscal
		lcTipFactura = toContext.cTipFactura
		lnLiniiStornare = toContext.nLiniiStornare
		lnLinii = toContext.nLinii
		
		Select crsEFactura
		Go Top
		lnTiparit = Iif(IsNull(crsEFactura.Tiparit), 0, crsEFactura.Tiparit)
		
		Do Case
			*-- Factura rectificativa
			Case toContext.lIsRectificativa
				lcType = "384"
			
			*-- Autofactura
			Case toContext.lIsAutoFactura Or ;
				(This.lIsICAS And AllTrim(GetNrFromString(lcCodFiscal)) == AllTrim(This.oICAS.oSoc.CodFiscal))
				lcType = "389"
			
			*-- Factura emisa in numele furnizorului
			Case lcTipFactura = 'L'
				lcType = "389"
			
			*-- Toate liniile sunt stornari
			Case lnLiniiStornare = lnLinii
				lcType = "380"  && Era 381, dar nu mai e acceptat
			
			*-- Factura pentru bonuri fiscale
			Case (lcTipFactura = ' ' And lnTiparit = 1) Or lcTipFactura = 'f'
				lcType = "751"
			
			*-- Factura standard
			Otherwise
				lcType = "380"
		EndCase
		
		This.LogDebug("Tip factura determinat: " + lcType)
		Return lcType
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: GenerateNotes
	* Descriere: Genereaza notele facturii
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	*---------------------------------------------------------------------------
	Protected Procedure GenerateNotes(toContext)
		Local lcNote
		
		Select crsEFactura
		Go Top
		
		*-- Nota TVA la incasare
		If toContext.nTipTvaCurent = 1 And crsEFactura.TvaI = .T.
			This.AddElement("cbc:Note", "TVA la incasare")
		EndIf
		
		*-- Nota taxare inversa
		If toContext.lIsTaxareInversa
			This.AddElement("cbc:Note", "Taxare inversa")
		EndIf
		
		*-- Informatii suplimentare factura
		lcNote = AllTrim(crsEFactura.Inf_Suplm)
		If Not Empty(lcNote)
			lcNote = This.CleanText(lcNote)
			This.AddElement("cbc:Note", lcNote)
		EndIf
		
		*-- Informatii client
		lcNote = AllTrim(crsEFactura.Inf_Supl)
		If Not Empty(lcNote)
			lcNote = This.CleanText(lcNote)
			This.AddElement("cbc:Note", lcNote)
		EndIf
		
		*-- Detalii client din parametru
		If Not Empty(toContext.cDetaliiClient) And Not toContext.lIsAutoFactura
			lcNote = AllTrim(StrTran(toContext.cDetaliiClient, Chr(13), ';'))
			lcNote = SubStr(lcNote, 1, Min(Len(lcNote), 300))
			This.AddElement("cbc:Note", lcNote)
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: GenerateReferences
	* Descriere: Genereaza referintele (comenzi, contracte, facturi anterioare)
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	*---------------------------------------------------------------------------
	Protected Procedure GenerateReferences(toContext)
		Local loOrderRef, loBillingRef, loDocRef, loProjectRef
		
		Select crsEFactura
		Go Top
		
		*-- BT-13: Referinta comenzii
		If Not Empty(crsEFactura.BT_13)
			loOrderRef = This.oInvoice.AppendChild(This.oXml.CreateElement("cac:OrderReference"))
			This.AddChildElement(loOrderRef, "cbc:ID", AllTrim(crsEFactura.BT_13))
		EndIf
		
		*-- Referinta factura anterioara (pentru rectificative)
		If toContext.cInvoiceType = '384'
			loBillingRef = This.oInvoice.AppendChild(This.oXml.CreateElement("cac:BillingReference"))
			loDocRef = loBillingRef.AppendChild(This.oXml.CreateElement("cac:InvoiceDocumentReference"))
			This.AddChildElement(loDocRef, "cbc:ID", AllTrim(crsEFactura.Nr))
			This.AddChildElement(loDocRef, "cbc:IssueDate", This.FormatDate(crsEFactura.Data))
		Else
			*-- Referinte stornari
			This.GenerateStornoReferences(toContext)
		EndIf
		
		*-- BT-11: Referinta proiect
		If Not Empty(crsEFactura.BT_11)
			loProjectRef = This.oInvoice.AppendChild(This.oXml.CreateElement("cac:ProjectReference"))
			This.AddChildElement(loProjectRef, "cbc:ID", AllTrim(crsEFactura.BT_11))
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: GenerateStornoReferences
	* Descriere: Genereaza referintele pentru stornari
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	*---------------------------------------------------------------------------
	Protected Procedure GenerateStornoReferences(toContext)
		Local loBillingRef, loDocRef
		
		If Used("C_EFACTURA_STORNO") And RecCount("C_EFACTURA_STORNO") > 0
			Select C_EFACTURA_STORNO
			Scan
				loBillingRef = This.oInvoice.AppendChild(This.oXml.CreateElement("cac:BillingReference"))
				loDocRef = loBillingRef.AppendChild(This.oXml.CreateElement("cac:InvoiceDocumentReference"))
				This.AddChildElement(loDocRef, "cbc:ID", AllTrim(C_EFACTURA_STORNO.Ndp))
				This.AddChildElement(loDocRef, "cbc:IssueDate", This.FormatDate(C_EFACTURA_STORNO.Data))
				
				*-- Adauga si index SPV daca exista
				If Not Empty(C_EFACTURA_STORNO.Id_Solicit)
					loBillingRef = This.oInvoice.AppendChild(This.oXml.CreateElement("cac:BillingReference"))
					loDocRef = loBillingRef.AppendChild(This.oXml.CreateElement("cac:InvoiceDocumentReference"))
					This.AddChildElement(loDocRef, "cbc:ID", "Index incarcare SPV: " + AllTrim(C_EFACTURA_STORNO.Id_Solicit))
				EndIf
			EndScan
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: GenerateSellerInfo
	* Descriere: Genereaza informatiile vanzatorului (BG-4)
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	*---------------------------------------------------------------------------
	Protected Procedure GenerateSellerInfo(toContext)
		Local loSupplier, loParty, loEndpoint, loPartyId, loAddress, loPartyTax, loPartyLegal, loContact
		Local loSoc
		
		If Not This.lIsICAS
			toContext.SetError("Nu se poate genera informatii vanzator fara ICAS.")
			Return
		EndIf
		
		loSoc = This.oICAS.oSoc
		
		*-- AccountingSupplierParty
		loSupplier = This.oInvoice.AppendChild(This.oXml.CreateElement("cac:AccountingSupplierParty"))
		loParty = loSupplier.AppendChild(This.oXml.CreateElement("cac:Party"))
		
		*-- BT-34: Endpoint (email)
		If Not Empty(loSoc.Email)
			loEndpoint = loParty.AppendChild(This.oXml.CreateElement("cbc:EndpointID"))
			loEndpoint.SetAttribute("schemeID", "EM")
			loEndpoint.Text = AllTrim(loSoc.Email)
		EndIf
		
		*-- BT-29: Identificatorul vanzatorului
		loPartyId = loParty.AppendChild(This.oXml.CreateElement("cac:PartyIdentification"))
		This.AddChildElement(loPartyId, "cbc:ID", AllTrim(loSoc.CodFiscal))
		
		*-- BG-5: Adresa vanzatorului
		loAddress = loParty.AppendChild(This.oXml.CreateElement("cac:PostalAddress"))
		This.GenerateAddress(loAddress, loSoc.Strada, loSoc.Localitate, loSoc.Judet, loSoc.CodPostal, loSoc.Sector)
		
		*-- BG-6: Informatii fiscale vanzator
		loPartyTax = loParty.AppendChild(This.oXml.CreateElement("cac:PartyTaxScheme"))
		This.AddChildElement(loPartyTax, "cbc:CompanyID", This.FormatCodFiscal(loSoc.CodFiscal))
		Local loTaxScheme
		loTaxScheme = loPartyTax.AppendChild(This.oXml.CreateElement("cac:TaxScheme"))
		This.AddChildElement(loTaxScheme, "cbc:ID", "VAT")
		
		*-- BT-27, BT-30: Informatii legale vanzator
		loPartyLegal = loParty.AppendChild(This.oXml.CreateElement("cac:PartyLegalEntity"))
		This.AddChildElement(loPartyLegal, "cbc:RegistrationName", AllTrim(loSoc.Denumire))
		This.AddChildElement(loPartyLegal, "cbc:CompanyID", AllTrim(loSoc.CodReg))
		
		*-- BG-6: Contact vanzator
		If Not Empty(loSoc.Telefon) Or Not Empty(loSoc.Email)
			loContact = loParty.AppendChild(This.oXml.CreateElement("cac:Contact"))
			If Not Empty(loSoc.Telefon)
				This.AddChildElement(loContact, "cbc:Telephone", AllTrim(loSoc.Telefon))
			EndIf
			If Not Empty(loSoc.Email)
				This.AddChildElement(loContact, "cbc:ElectronicMail", AllTrim(loSoc.Email))
			EndIf
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: GenerateBuyerInfo
	* Descriere: Genereaza informatiile cumparatorului (BG-7)
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	*---------------------------------------------------------------------------
	Protected Procedure GenerateBuyerInfo(toContext)
		Local loCustomer, loParty, loEndpoint, loPartyId, loAddress, loPartyTax, loPartyLegal
		
		Select crsEFactura
		Go Top
		
		*-- AccountingCustomerParty
		loCustomer = This.oInvoice.AppendChild(This.oXml.CreateElement("cac:AccountingCustomerParty"))
		loParty = loCustomer.AppendChild(This.oXml.CreateElement("cac:Party"))
		
		*-- BT-49: Endpoint cumparator (email)
		If Not Empty(crsEFactura.Email_CL)
			loEndpoint = loParty.AppendChild(This.oXml.CreateElement("cbc:EndpointID"))
			loEndpoint.SetAttribute("schemeID", "EM")
			loEndpoint.Text = AllTrim(crsEFactura.Email_CL)
		EndIf
		
		*-- BT-46: Identificatorul cumparatorului
		If Not Empty(crsEFactura.Cod_Fiscal)
			loPartyId = loParty.AppendChild(This.oXml.CreateElement("cac:PartyIdentification"))
			This.AddChildElement(loPartyId, "cbc:ID", AllTrim(crsEFactura.Cod_Fiscal))
		EndIf
		
		*-- BG-8: Adresa cumparatorului
		loAddress = loParty.AppendChild(This.oXml.CreateElement("cac:PostalAddress"))
		This.GenerateAddress(loAddress, crsEFactura.Adresa_CL, crsEFactura.Local_CL, crsEFactura.Judet_CL, crsEFactura.CodPost_CL, "")
		
		*-- BG-11: Informatii fiscale cumparator
		If Not Empty(crsEFactura.Cod_Fiscal)
			loPartyTax = loParty.AppendChild(This.oXml.CreateElement("cac:PartyTaxScheme"))
			This.AddChildElement(loPartyTax, "cbc:CompanyID", This.FormatCodFiscal(crsEFactura.Cod_Fiscal, crsEFactura.Tara))
			Local loTaxScheme
			loTaxScheme = loPartyTax.AppendChild(This.oXml.CreateElement("cac:TaxScheme"))
			This.AddChildElement(loTaxScheme, "cbc:ID", "VAT")
		EndIf
		
		*-- BT-44, BT-47: Informatii legale cumparator
		loPartyLegal = loParty.AppendChild(This.oXml.CreateElement("cac:PartyLegalEntity"))
		This.AddChildElement(loPartyLegal, "cbc:RegistrationName", AllTrim(crsEFactura.Denumire_CL))
		If Not Empty(crsEFactura.CodReg_CL)
			This.AddChildElement(loPartyLegal, "cbc:CompanyID", AllTrim(crsEFactura.CodReg_CL))
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: GenerateAddress
	* Descriere: Genereaza un element de adresa
	* Parametri: 
	*   toParent - Elementul parinte
	*   tcStrada, tcLocalitate, tcJudet, tcCodPostal, tcSector - Componentele adresei
	*---------------------------------------------------------------------------
	Protected Procedure GenerateAddress(toParent, tcStrada, tcLocalitate, tcJudet, tcCodPostal, tcSector)
		Local lcLocalitate, lcJudetCode
		
		*-- BT-35/BT-50: Strada
		If Not Empty(tcStrada)
			This.AddChildElement(toParent, "cbc:StreetName", AllTrim(tcStrada))
		EndIf
		
		*-- BT-37/BT-52: Localitate
		lcLocalitate = AllTrim(tcLocalitate)
		If Not Empty(tcSector)
			lcLocalitate = AllTrim(tcSector)  && Pentru Bucuresti, se pune sectorul
		EndIf
		If Not Empty(lcLocalitate)
			This.AddChildElement(toParent, "cbc:CityName", lcLocalitate)
		EndIf
		
		*-- BT-38/BT-53: Cod postal
		If Not Empty(tcCodPostal)
			This.AddChildElement(toParent, "cbc:PostalZone", AllTrim(tcCodPostal))
		EndIf
		
		*-- BT-39/BT-54: Judet (cod ISO)
		lcJudetCode = This.GetCountyCode(tcJudet)
		If Not Empty(lcJudetCode)
			This.AddChildElement(toParent, "cbc:CountrySubentity", lcJudetCode)
		EndIf
		
		*-- BT-40/BT-55: Tara
		Local loCountry
		loCountry = toParent.AppendChild(This.oXml.CreateElement("cac:Country"))
		This.AddChildElement(loCountry, "cbc:IdentificationCode", "RO")
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: GeneratePaymentInfo
	* Descriere: Genereaza informatiile de plata
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	*---------------------------------------------------------------------------
	Protected Procedure GeneratePaymentInfo(toContext)
		Local loPaymentMeans, loPayeeAccount
		
		Select crsEFactura
		Go Top
		
		*-- BG-16: Payment Means
		loPaymentMeans = This.oInvoice.AppendChild(This.oXml.CreateElement("cac:PaymentMeans"))
		
		*-- BT-81: Codul metodei de plata
		This.AddChildElement(loPaymentMeans, "cbc:PaymentMeansCode", "42")  && 42 = Transferuri in contul bancii furnizorului
		
		*-- BG-17: Cont bancar
		If Not Empty(crsEFactura.IBAN)
			loPayeeAccount = loPaymentMeans.AppendChild(This.oXml.CreateElement("cac:PayeeFinancialAccount"))
			This.AddChildElement(loPayeeAccount, "cbc:ID", AllTrim(crsEFactura.IBAN))
			
			If Not Empty(crsEFactura.Banca)
				This.AddChildElement(loPayeeAccount, "cbc:Name", AllTrim(crsEFactura.Banca))
			EndIf
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: GenerateTaxInfo
	* Descriere: Genereaza informatiile TVA (BG-23)
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	*---------------------------------------------------------------------------
	Protected Procedure GenerateTaxInfo(toContext)
		Local loTaxTotal, loTaxAmount, loTaxSubtotal, loTaxCategory, loTaxScheme
		Local lnTotalTva, lcMoneda, lnCurs
		
		lcMoneda = toContext.cMoneda
		lnTotalTva = toContext.nTotalTva
		
		*-- BG-22: Tax Total
		loTaxTotal = This.oInvoice.AppendChild(This.oXml.CreateElement("cac:TaxTotal"))
		
		*-- BT-110: Total TVA
		loTaxAmount = loTaxTotal.AppendChild(This.oXml.CreateElement("cbc:TaxAmount"))
		loTaxAmount.SetAttribute("currencyID", lcMoneda)
		loTaxAmount.Text = AllTrim(Str(lnTotalTva, 15, 2))
		
		*-- BG-23: Tax Subtotals
		If Used("crsTva_EFactura")
			Select crsTva_EFactura
			Scan
				loTaxSubtotal = loTaxTotal.AppendChild(This.oXml.CreateElement("cac:TaxSubtotal"))
				
				*-- BT-116: Baza impozabila
				Local loTaxableAmount
				loTaxableAmount = loTaxSubtotal.AppendChild(This.oXml.CreateElement("cbc:TaxableAmount"))
				loTaxableAmount.SetAttribute("currencyID", lcMoneda)
				loTaxableAmount.Text = AllTrim(Str(crsTva_EFactura.Valoare, 15, 2))
				
				*-- BT-117: TVA
				loTaxAmount = loTaxSubtotal.AppendChild(This.oXml.CreateElement("cbc:TaxAmount"))
				loTaxAmount.SetAttribute("currencyID", lcMoneda)
				loTaxAmount.Text = AllTrim(Str(crsTva_EFactura.Tva, 15, 2))
				
				*-- BG-23: Tax Category
				loTaxCategory = loTaxSubtotal.AppendChild(This.oXml.CreateElement("cac:TaxCategory"))
				This.AddChildElement(loTaxCategory, "cbc:ID", AllTrim(crsTva_EFactura.Tip))
				
				*-- BT-119: Procent TVA
				If crsTva_EFactura.Tip <> 'O'
					This.AddChildElement(loTaxCategory, "cbc:Percent", AllTrim(Str(crsTva_EFactura.ProcTva, 2, 0)))
				EndIf
				
				*-- BT-120/121: Motiv scutire
				If Not Empty(crsTva_EFactura.Motiv)
					This.AddChildElement(loTaxCategory, "cbc:TaxExemptionReasonCode", AllTrim(crsTva_EFactura.Motiv))
				EndIf
				If Not Empty(crsTva_EFactura.Explicatie)
					This.AddChildElement(loTaxCategory, "cbc:TaxExemptionReason", AllTrim(crsTva_EFactura.Explicatie))
				EndIf
				
				loTaxScheme = loTaxCategory.AppendChild(This.oXml.CreateElement("cac:TaxScheme"))
				This.AddChildElement(loTaxScheme, "cbc:ID", "VAT")
			EndScan
		EndIf
		
		*-- Al doilea TaxTotal pentru TVA in RON (daca moneda e diferita)
		If lcMoneda <> "RON"
			Select crsTva_EFactura
			Go Top
			lnCurs = crsTva_EFactura.Curs
			
			loTaxTotal = This.oInvoice.AppendChild(This.oXml.CreateElement("cac:TaxTotal"))
			loTaxAmount = loTaxTotal.AppendChild(This.oXml.CreateElement("cbc:TaxAmount"))
			loTaxAmount.SetAttribute("currencyID", "RON")
			
			Sum TvaLei To lnTotalTvaLei
			loTaxAmount.Text = AllTrim(Str(lnTotalTvaLei, 15, 2))
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: GenerateTotals
	* Descriere: Genereaza totalurile facturii (BG-22)
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	*---------------------------------------------------------------------------
	Protected Procedure GenerateTotals(toContext)
		Local loMonetaryTotal, lcMoneda, lnTotalNetLinii
		
		lcMoneda = toContext.cMoneda
		
		*-- Calculeaza total net linii
		Select crsEFactura
		Sum Valoare To lnTotalNetLinii For Indice >= 0
		
		*-- BG-22: Monetary Totals
		loMonetaryTotal = This.oInvoice.AppendChild(This.oXml.CreateElement("cac:LegalMonetaryTotal"))
		
		*-- BT-106: Suma valorilor liniilor
		This.AddAmountElement(loMonetaryTotal, "cbc:LineExtensionAmount", lnTotalNetLinii, lcMoneda)
		
		*-- BT-109: Total baza calcul TVA
		This.AddAmountElement(loMonetaryTotal, "cbc:TaxExclusiveAmount", toContext.nTotalNet, lcMoneda)
		
		*-- BT-112: Total cu TVA
		This.AddAmountElement(loMonetaryTotal, "cbc:TaxInclusiveAmount", toContext.nTotalBrut, lcMoneda)
		
		*-- BT-107: Total deduceri
		If toContext.nTotalAllowances > 0
			This.AddAmountElement(loMonetaryTotal, "cbc:AllowanceTotalAmount", toContext.nTotalAllowances, lcMoneda)
		EndIf
		
		*-- BT-108: Total taxe suplimentare
		If toContext.nTotalCharges > 0
			This.AddAmountElement(loMonetaryTotal, "cbc:ChargeTotalAmount", toContext.nTotalCharges, lcMoneda)
		EndIf
		
		*-- BT-113: Suma incasata
		If toContext.nIncasat <> 0 And toContext.nTotalBrut >= 0
			This.AddAmountElement(loMonetaryTotal, "cbc:PrepaidAmount", toContext.nIncasat, lcMoneda)
		EndIf
		
		*-- BT-115: Total de plata
		Local lnDePlata
		lnDePlata = toContext.nTotalBrut - Iif(toContext.nTotalBrut >= 0, toContext.nIncasat, 0)
		This.AddAmountElement(loMonetaryTotal, "cbc:PayableAmount", lnDePlata, lcMoneda)
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: GenerateInvoiceLines
	* Descriere: Genereaza liniile facturii (BG-25)
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	*---------------------------------------------------------------------------
	Protected Procedure GenerateInvoiceLines(toContext)
		Local i, loLine, loItem, loPrice, lcMoneda
		
		i = 1
		lcMoneda = toContext.cMoneda
		
		Select crsEFactura
		Scan For Indice = 0
			loLine = This.oInvoice.AppendChild(This.oXml.CreateElement("cac:InvoiceLine"))
			
			*-- BT-126: ID linie
			This.AddChildElement(loLine, "cbc:ID", AllTrim(Str(i, 5, 0)))
			
			*-- BT-127: Nota liniei
			If Not Empty(crsEFactura.Text_Supl)
				This.AddChildElement(loLine, "cbc:Note", SubStr(AllTrim(crsEFactura.Text_Supl), 1, 300))
			EndIf
			
			*-- BT-129/BT-130: Cantitate si UM
			Local loQty, lcUm
			lcUm = This.GetUnitCode(crsEFactura.Um)
			loQty = loLine.AppendChild(This.oXml.CreateElement("cbc:InvoicedQuantity"))
			loQty.SetAttribute("unitCode", lcUm)
			loQty.Text = AllTrim(Str(crsEFactura.Cantitate, 15, 3))
			
			*-- BT-131: Valoarea neta
			This.AddAmountElement(loLine, "cbc:LineExtensionAmount", crsEFactura.Valoare, lcMoneda)
			
			*-- BG-31: Item
			loItem = loLine.AppendChild(This.oXml.CreateElement("cac:Item"))
			
			*-- BT-154: Descriere
			If Not Empty(crsEFactura.Is_A)
				This.AddChildElement(loItem, "cbc:Description", AllTrim(crsEFactura.Is_A))
			EndIf
			
			*-- BT-153: Denumire
			This.AddChildElement(loItem, "cbc:Name", AllTrim(crsEFactura.Denumire))
			
			*-- BT-156: Cod client
			If Not Empty(crsEFactura.Cod_Art_Cl) And Not toContext.lIsAutoFactura
				Local loBuyerId
				loBuyerId = loItem.AppendChild(This.oXml.CreateElement("cac:BuyersItemIdentification"))
				This.AddChildElement(loBuyerId, "cbc:ID", AllTrim(crsEFactura.Cod_Art_Cl))
			EndIf
			
			*-- BT-155: Cod vanzator
			If Not Empty(crsEFactura.Cod)
				Local loSellerId
				loSellerId = loItem.AppendChild(This.oXml.CreateElement("cac:SellersItemIdentification"))
				This.AddChildElement(loSellerId, "cbc:ID", Transform(crsEFactura.Cod))
			EndIf
			
			*-- BG-30: Categoria TVA articol
			This.GenerateItemTaxCategory(loItem, crsEFactura.ProcTva)
			
			*-- BG-29: Pret
			loPrice = loLine.AppendChild(This.oXml.CreateElement("cac:Price"))
			This.AddAmountElement(loPrice, "cbc:PriceAmount", crsEFactura.Pret_Vanz, lcMoneda, 4)
			
			i = i + 1
		EndScan
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: GenerateItemTaxCategory
	* Descriere: Genereaza categoria TVA pentru un articol
	* Parametri: 
	*   toItem - Elementul Item
	*   tnProcTva - Procentul TVA
	*---------------------------------------------------------------------------
	Protected Procedure GenerateItemTaxCategory(toItem, tnProcTva)
		Local loTaxCategory, loTaxScheme, lcTip
		
		*-- Gaseste categoria TVA
		Select Tip From crsTva_EFactura Where ProcTva = tnProcTva Into Array aGetTip
		lcTip = Iif(_Tally > 0 And Not IsNull(aGetTip(1)), AllTrim(aGetTip(1)), "S")
		
		loTaxCategory = toItem.AppendChild(This.oXml.CreateElement("cac:ClassifiedTaxCategory"))
		
		*-- BT-151: Categoria
		This.AddChildElement(loTaxCategory, "cbc:ID", lcTip)
		
		*-- BT-152: Procent
		If lcTip <> 'O'
			This.AddChildElement(loTaxCategory, "cbc:Percent", AllTrim(Str(tnProcTva, 2, 0)))
		EndIf
		
		loTaxScheme = loTaxCategory.AppendChild(This.oXml.CreateElement("cac:TaxScheme"))
		This.AddChildElement(loTaxScheme, "cbc:ID", "VAT")
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: SaveXmlFile
	* Descriere: Salveaza fisierul XML
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	*---------------------------------------------------------------------------
	Protected Procedure SaveXmlFile(toContext)
		Local lcPath, lcFileName, lcFullPath
		
		lcPath = toContext.cCaleFisier
		lcFileName = toContext.cNumeFisier
		
		If Empty(lcPath)
			lcPath = This.GetDefaultPath(toContext.dDataFactura)
		EndIf
		
		If Not Directory(lcPath)
			Md (lcPath)
		EndIf
		
		lcFullPath = AddBs(lcPath) + lcFileName + ".xml"
		
		*-- Salveaza XML-ul
		This.oXml.Save(lcFullPath)
		
		*-- Salveaza continutul in context
		toContext.cXmlFilePath = lcFullPath
		toContext.cXmlContent = This.oXml.Xml
		
		This.LogInfo("Fisier XML salvat: " + lcFullPath)
	EndProc
	
	*---------------------------------------------------------------------------
	* Helper Methods
	*---------------------------------------------------------------------------
	
	Protected Procedure AddElement(tcName, tcValue)
		Local loElement
		loElement = This.oInvoice.AppendChild(This.oXml.CreateElement(tcName))
		loElement.Text = tcValue
	EndProc
	
	Protected Procedure AddChildElement(toParent, tcName, tcValue)
		Local loElement
		loElement = toParent.AppendChild(This.oXml.CreateElement(tcName))
		loElement.Text = tcValue
	EndProc
	
	Protected Procedure AddAmountElement(toParent, tcName, tnValue, tcCurrency, tnDecimals)
		Local loElement, lnDecimals
		lnDecimals = Iif(Empty(tnDecimals), 2, tnDecimals)
		loElement = toParent.AppendChild(This.oXml.CreateElement(tcName))
		loElement.SetAttribute("currencyID", tcCurrency)
		loElement.Text = AllTrim(Str(tnValue, 15, lnDecimals))
	EndProc
	
	Protected Function FormatDate(tdDate)
		Return AllTrim(Str(Year(tdDate))) + "-" + PadL(AllTrim(Str(Month(tdDate))), 2, "0") + "-" + PadL(AllTrim(Str(Day(tdDate))), 2, "0")
	EndFunc
	
	Protected Function FormatCodFiscal(tcCodFiscal, tcTara)
		Local lcTara, lcCF
		lcTara = Iif(Empty(tcTara), "RO", AllTrim(Upper(tcTara)))
		lcCF = AllTrim(Upper(tcCodFiscal))
		If Left(lcCF, 2) <> lcTara
			lcCF = lcTara + lcCF
		EndIf
		Return lcCF
	EndFunc
	
	Protected Function CleanText(tcText)
		Local lcText
		lcText = AllTrim(StrTran(tcText, Chr(13), ';'))
		lcText = StrTran(lcText, Chr(10), ' ')
		*-- Inlocuieste caractere speciale
		Return lcText
	EndFunc
	
	Protected Function GetCountyCode(tcJudet)
		*-- Returneaza codul ISO 3166-2 pentru judet
		Local lcJudet, lcCode
		lcJudet = Upper(AllTrim(tcJudet))
		
		*-- Simplificat - ar trebui sa foloseasca un tabel de coduri
		lcCode = "RO-" + Left(lcJudet, 2)
		Return lcCode
	EndFunc
	
	Protected Function GetUnitCode(tcUm)
		*-- Returneaza codul UN/CEFACT pentru UM
		Local lcUm
		lcUm = Upper(AllTrim(tcUm))
		
		Do Case
			Case lcUm = "BUC"
				Return "H87"
			Case lcUm = "KG"
				Return "KGM"
			Case lcUm = "M" Or lcUm = "ML"
				Return "MTR"
			Case lcUm = "L" Or lcUm = "LITRI"
				Return "LTR"
			Otherwise
				Return "H87"  && Default: bucati
		EndCase
	EndFunc
	
	Protected Function GetDefaultPath(tdData)
		Local lcPath
		lcPath = AddBs(SYS(5) + CurDir()) + "eFactura\"
		lcPath = lcPath + AllTrim(Str(Year(tdData))) + "\"
		lcPath = lcPath + PadL(AllTrim(Str(Month(tdData))), 2, "0") + "\"
		Return lcPath
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: Destroy
	* Descriere: Curata resursele
	*---------------------------------------------------------------------------
	Procedure Destroy()
		This.oXml = .Null.
		This.oInvoice = .Null.
		This.oXmlStrategy = .Null.
		This.oStrategyFactory = .Null.
		This.oICAS = .Null.
		DoDefault()
	EndProc
	
EndDefine
