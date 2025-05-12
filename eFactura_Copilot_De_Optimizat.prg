Procedure Create_XML_UBL_File_For_eFactura(tnRectificativa, tcNumeFisier, tcCaleFacturi, tlIsExport, tcDetalii_CL, tnIdUnicFactura, tlIsAutoFactura)
	If Type('ll_Is_ICAS')='U'
		Public ll_Is_ICAS
		ll_Is_ICAS = ( VarType(ICAS)='O' And Not IsNull(ICAS) ) And PemStatus(ICAS, 'oCfgSALARII', 5)
	EndIf
	If Empty(tnIdUnicFactura)
		ln_IdUnic_Factura  = 0
		lcReturn = 'Nu ati setat parametrul [ tnIdUnicFactura ]'
		MessageBox(lcReturn, 16, "Eroare", 3000)
		Return lcReturn
	Else	
		ln_IdUnic_Factura = tnIdUnicFactura
	EndIf	
	If IsNullOrEmpty(tcDetalii_CL)
		tcDetalii_CL=''
	EndIf
	? "==============================="
	? Program()
	? "--------------------------------"
	? "PARAMETERS:"
	? "--------------------------------"
	? "tnRectificativa ",	Transform(tnRectificativa)
	? "tcNumeFisier ",		Transform(tcNumeFisier)
	? "tcCaleFacturi ",		Transform(tcCaleFacturi)
	? "tlIsExport ",		Transform(tlIsExport)
	? "tcDetalii_CL ",		Transform(tcDetalii_CL)
	? "ln_IdUnic_Factura ",	Transform(ln_IdUnic_Factura)
	?
	Local lcTipFactura, i, lnLinii, lnLiniiReducere, lnLiniiStornare, lnAccize, lnTotalCharges, lnTotalAllowances, lcMoneda, lcInvoiceType, lcCodFiscal, lcComanda, lcTara, lcTipTert, lnTipTvaCurent, lnTvaI, lnIncasat, mExpliIesiriLot
	*, lnIdUnicFactura
	Store 1 To i
	Store 0 To lnAccize, lnLiniiReducere, lnTotalCharges, lnTotalAllowances, lnTvaI, lnIncasat
	Store "" TO mExpliIesiriLot
	If Empty(ICAS.oSoc.CodFiscal)
		lcReturn = "Completati codul fiscal al societatii, in ecranul 'Setari => Firme...'."
		MessageBox(lcReturn, "Date incomplete...", 3000)
		? "lcReturn ",		Transform(lcReturn)
		Return lcReturn 
	EndIf
	lc_Upload_Param_Extern = Iif(crsEFactura.Is_Extern, '&extern=DA', '')		&& 05.09.2024
	Delete From crsEFactura Where Empty(IdUnic)
	Select;
		ProcTva;
		, Sum(Tva)				As Tva;
		, Sum(TvaLei)			As TvaLei;
		, Sum(Valoare)			As Valoare;
		, '  '					As Tip;
		, Replicate(' ', 50)	As Explicatie;
		, Replicate(' ', 30)	As Motiv;
		, Curs;
		, CodTva;
	From crsEFactura;
	Group By;
		ProcTva, CodTva, Curs;
	Into Cursor crsTva_EFactura ReadWrite
	? "Cursor crsTva_EFactura"
	Select crsTva_EFactura
	Sum Tva To lnTotalTva
	Index On ProcTva Tag Procent
	? "lnTotalTva ", Transform(lnTotalTva )
	Select CodTva From crsEFactura Where CodTva='10' Into Array aGetIsTaxareInversa
	lIsTaxareInversa=Iif(_Tally>0, .T., .F.)
	Select crsEFactura
	lcNumarFactura	=	AllTrim(crsEFactura.Nr)
	lcMoneda		=	AllTrim(crsEFactura.Moneda)		&& 15.01.2024	Tb numai 'RON' in crsEFactura
	lcCodFiscal		=	crsEFactura.Cod_Fiscal
	lcTipFactura	=	crsEFactura.Tip
	lcTara			=	crsEFactura.Tara
	ldData			=	crsEFactura.Data
	lc_EFA_TipRaportare = 'B2B'
	If crsEFactura.Data>={31.03.2025}
		*
		If VerifCF(lcCodFiscal)
			lc_EFA_TipRaportare = 'B2B'
		Else
			lc_EFA_TipRaportare = 'B2C'
		EndIf
	EndIf
	lcTipTert		=	ICase(IsNullOrEmpty(crsEFactura.Tip_Tert) Or InList(crsEFactura.Tip_Tert, '', '1'), '', crsEFactura.Tip_Tert='2', 'I', 'E')
	lnTipTvaCurent	=	Iif(ll_Is_ICAS, GetModPlataTva(crsEFactura.Data), 1)
	lnTvaI			=	Iif(ll_Is_ICAS, ICase(crsEFactura.TvaI=.T., 1, 0), crsEFactura.TvaI)
	mInf_Suplm		=	crsEFactura.Inf_Suplm
	mInf_Supl		=	crsEFactura.Inf_Supl
	mTiparit		= 	Iif(IsNull(crsEFactura.Tiparit), 0, crsEFactura.Tiparit)
	? "lIsTaxareInversa ",	Transform(lIsTaxareInversa)	
	? "lcNumarFactura ",	Transform(lcNumarFactura)
	? "lcMoneda ",			Transform(lcMoneda)
	? "lcCodFiscal ",		Transform(lcCodFiscal)
	? "lcTipFactura ",		Transform(lcTipFactura)
	? "lcTara ",			Transform(lcTara)
	? "ldData ",			Transform(ldData)
	? "lcTipTert ",			Transform(lcTipTert)
	? "lnTipTvaCurent ",	Transform(lnTipTvaCurent)
	? "lnTvaI ",			Transform(lnTvaI)
	? "mInf_Suplm ",		Transform(mInf_Suplm)
	? "mInf_Supl ",			Transform(mInf_Supl)
	? "mTiparit ",			Transform(mTiparit)
	? "lc_EFA_TipRaportare ",Transform(lc_EFA_TipRaportare )
	If  .Not. InList(lcTipFactura, ' ', 'f', 'S', 'D', 'd', 'U', 'H', 'T', 'n')			&& 08Ianuarie2025  'f'=751
		lcReturn = "Pentru acest document nu se genereaza factura electronica."
		MessageBox(lcReturn, 64, "Atentie...")
		? "lcReturn ",			Transform(lcReturn)
		Return lcReturn
		Return
	EndIf
	lnIncasat=0
	If ll_Is_ICAS
		If tlIsExport		&& aici cred ca trebuia Ecran='Export'
			Text To lcSQL NoShow TextMerge
	      		Select DISTINCT 
	      			[Ndp]=NumarDoc
	      			, [Data]=e.DataDoc
	      			, [Id_Solicit] = Id_Solicitare
	      		From Export e
	      		Inner Join NoteFacturiValuta n On e.IdUnic=n.IdFactura
	      		Where
	      			IdNota=?ln_IdUnic_Factura
	      			And IsStorno=1
			EndText
			mySQLExec(lcSQL, [C_EFACTURA_STORNO_VAL_VAL]) 
			Text To lcSQL NoShow TextMerge
	      		Select DISTINCT
	      			[Ndp]=NumarDoc
	      			, [Data]=e.DataDoc
	      			, [Id_Solicit] = Id_Solicitare
	      		From Export e
	      		Inner Join NoteFacturi n On e.IdUnic=n.IdFactura
	      		Where
	      			IdNota=?ln_IdUnic_Factura
	      			And IsStorno=1
			EndText
			mySQLExec(lcSQL, [C_EFACTURA_STORNO_VAL_LEI])
			Select * From C_EFACTURA_STORNO_VAL_VAL Union Select * From C_EFACTURA_STORNO_VAL_LEI Into Cursor C_EFACTURA_STORNO
		Else
			Text To lcSQL NoShow TextMerge
				Select DISTINCT
					[Ndp]=i.NumarDoc
					, [Data]=i.DataDoc
					, [Id_Solicit] = Id_Solicitare
				From Iesiri i
				Inner Join NoteFacturi n On i.IdUnic=n.Idfactura
				Where
					IdNota=?ln_IdUnic_Factura
					And IsStorno=1
			EndText
			mySQLExec(lcSQL, [C_EFACTURA_STORNO])
		EndIf
	Else
		Text To lcSQL NoShow TextMerge
			Select DISTINCT
				Factura As Ndp
				, Data_Doc As Data
				, Id_Solicitare As Id_Solicit
			From Docum
			Where
				1=0
		EndText
		mySQLExec(lcSQL, [C_EFACTURA_STORNO])
	EndIf
	? "Cursor C_EFACTURA_STORNO"
	If ll_Is_ICAS
		Text To lcSQL NoShow TextMerge
			Select
				r.Ndp
				, r.Explicatie
				, r.Data
				, r.Curs
				, r.Suma AS Suma_Lei
				, r.Cod_Valuta
				, n.Suma
				, r.ContC
				, r.ContD
			From Registru r
			Inner Join NoteFacturi n On r.Id_Nota=n.IdNota
			Where
				n.IdFactura=?ln_IdUnic_Factura
				And r.ContC Not Like '442%'
		EndText
		mySQLExec(lcSQL, [crsIncasariLei])
		Text To lcSQL NoShow TextMerge
			Select
				r.Ndp
				, r.Explicatie
				, r.Data
				, r.Curs
				, r.Suma AS Suma_Lei
				, r.Cod_Valuta
				, n.Suma
				, r.ContC
				, r.ContD
			From Registru r
			Inner Join NoteFacturi n On r.Id_Nota=n.IdNota
			Where
				n.IdFactura=?ln_IdUnic_Factura
				And r.ContC Not Like '442%'
		EndText
		mySQLExec(lcSQL, [crsIncasariValuta])
		Update crsIncasariValuta Set Suma_Lei = Round(Suma*Iif(Curs>0, Curs, 1.0000 ), 2)
		Select * From crsIncasariLei Union Select * From crsIncasariValuta Into Cursor C_INCASARI_EFACT
	Else
		Text To lcSQL NoShow TextMerge
			Select
				Factura As Ndp
				, '' As Explicatie
				, Data_Doc As Data
				, 1.0000 As Curs
				, 9999999999.99-9999999999.99 As Suma_Lei
				, 'RON' As Cod_Valuta
				, 9999999999.99-9999999999.99 As Suma
				, '          ' As ContC
				, '          ' As ContD
			From Docum
			Where
				1=0
		EndText
		mySQLExec(lcSQL, [C_INCASARI_EFACT])
	EndIf
	? "Cursor C_INCASARI_EFACT"
	If RecCount("C_INCASARI_EFACT")>0
		Select Sum(Suma_Lei) From C_INCASARI_EFACT Where Data<=ldData Into Array aTestIncasareEFactura
		If _TALLY>0 .AND.  .NOT. IsNull(aTestIncasareEFactura)
			lnIncasat = aTestIncasareEFactura(1)
		EndIf
	EndIf
	Select crsEFactura
	Count To lnLinii
	Count For Indice=-1					To lnLiniiReducere
	Count For Indice>=0 .And. Valoare<0	To lnLiniiStornare
	Count For Cont='419'				To mNrLiniiAvans
	Sum Abs(Valoare)					To mDiscounturi For Indice=-1
	lnTotalAllowances = lnTotalAllowances+mDiscounturi
	Locate
	? "lnIncasat  ",		Transform(lnIncasat)
	? "lnLinii ",			Transform(lnLinii)
	? "lnLiniiReducere ",	Transform(lnLiniiReducere)
	? "lnLiniiStornare ",	Transform(lnLiniiStornare)
	? "mNrLiniiAvans ",		Transform(mNrLiniiAvans)
	? "mDiscounturi ",		Transform(mDiscounturi)
	? "lnTotalAllowances ",	Transform(lnTotalAllowances)
	lHasFacturiCuTva= .F.
	Select Count(*) From crsTva_EFactura Where Tva<>0 Into Array aGetHasTVA
	If _TALLY>0 .AND.  .NOT. IsNull(aGetHasTVA(1)) .AND. aGetHasTVA(1)>0
    	lHasFacturiCuTva = .T.
	EndIf
	? "lHasFacturiCuTva ",	Transform(lHasFacturiCuTva)
	Select crsTva_EFactura
	Scan
		DO CASE
			CASE lIsTaxareInversa OR lcTipFactura='T' .OR. (lcTipTert='I' .AND.  .NOT. EMPTY(lcCodFiscal) .AND.  .NOT. lHasFacturiCuTva)			&& Vicos.03.10.2023
				REPLACE Tip WITH 'AE', Explicatie WITH 'Taxare inversa', Motiv WITH 'VATEX-EU-AE'
			CASE INLIST(lcTipFactura, 'S', 'D', 'd')
				REPLACE Tip WITH 'E', Explicatie WITH 'Scutit cu drept de deducere', Motiv WITH 'VATEX-EU-O'		&& ? tb si motiv?
			CASE (EMPTY(lcTipFactura) .OR. INLIST(lcTipFactura, 'n')) .AND. crsTva_EFactura.ProcTva=0
				IF lnTipTvaCurent<3
					REPLACE Tip WITH 'E', Explicatie WITH 'Scutit de TVA', Motiv WITH 'VATEX-EU-O'	&& 19.09.2024
				ELSE
					REPLACE Tip WITH 'O', Explicatie WITH 'Entitatea nu este inregistrata in scopuri de TVA', Motiv WITH 'VATEX-EU-O'
				ENDIF
			CASE lcTipFactura='H'
				REPLACE Tip WITH 'E', Explicatie WITH 'Bunuri second-hand', Motiv WITH 'VATEX-EU-F'
			CASE lcTipFactura='U'
				REPLACE Tip WITH 'E', Explicatie WITH 'Regim special agentii de turism', Motiv WITH 'VATEX-EU-309'
			CASE ProcTva=0																			&& 19.09.2024	
				IF lnTipTvaCurent<3
					DO CASE
						CASE CodTva = '17'	&& .NOT. IsNullOrEmpty(lcVatEx)
							REPLACE Tip WITH 'E', Explicatie WITH 'Scutit fara drept de deducere', Motiv WITH 'VATEX-EU-O'
						CASE CodTva = '16'
							REPLACE Tip WITH 'E', Explicatie WITH 'Scutit cu drept de deducere', Motiv WITH 'VATEX-EU-O'
						CASE CodTva = '18'
							REPLACE Tip WITH 'O', Explicatie WITH 'Entitatea nu este inregistrata in scopuri de TVA', Motiv WITH 'VATEX-EU-O'
						OTHERWISE
							REPLACE Tip WITH 'Z'
					ENDCASE
				ELSE
					REPLACE Tip WITH 'O', Explicatie WITH 'Entitatea nu este inregistrata in scopuri de TVA', Motiv WITH 'VATEX-EU-O'
				ENDIF

			OTHERWISE
				REPLACE Tip WITH 'S'
		ENDCASE
	EndScan
	? "crsTva_EFactura.Tip ",			Transform(crsTva_EFactura.Tip)
	? "crsTva_EFactura.Explicatie ",	Transform(crsTva_EFactura.Explicatie)
	? "crsTva_EFactura.Motiv ",			Transform(crsTva_EFactura.Motiv)
	If crsEFactura.Accize>0
		lnAccize = crsEFactura.Accize
		lnTotalCharges = lnTotalCharges+lnAccize
		If lnTipTvaCurent<3
			Select Count(*) From crsTva_EFactura Where Tip='E' Into Array aGetCotaZ
			If _Tally>0 .And.  .Not. IsNull(aGetCotaZ(1)) .And. aGetCotaZ(1)>0
				Update crsTva_EFactura Set Valoare = Valoare+lnAccize  Where Tip='E'
			Else
				Insert Into crsTva_EFactura (ProcTva, Tva, Valoare, Tip, Explicatie, Motiv, Curs) Values (0, 0, lnAccize , 'E', 'Acciza', 'VATEX-EU-O', 1)
			EndIf
		Else
			Select Count(*) From crsTva_EFactura Where Tip='O' Into Array aGetCotaZ
			If _Tally>0 .And.  .Not. IsNull(aGetCotaZ(1)) .And. aGetCotaZ(1)>0
				Update crsTva_EFactura Set Valoare = Valoare+lnAccize  Where Tip='O'
			Else
				Insert Into crsTva_EFactura (ProcTva, Tva, Valoare, Tip, Explicatie, Motiv, Curs) Values (0, 0, lnAccize , 'O', 'Acciza', 'VATEX-EU-O', 1)
			EndIf
		EndIf
	EndIf
	? "crsTva_EFactura.Accize ",			Transform(crsEFactura.Accize)
	Select crsEFactura
	Locate
	=EFA_GenerareFisierXML()
EndProc	
Procedure EFA_GenerareFisierXML
	EFA_GenerareFisierXML_Header()
	EFA_GenerareFisierXML_Antet()
	EFA_GenerareFisierXML_Vanzator()
	EFA_GenerareFisierXML_Cumparator()
	EFA_GenerareFisierXML_Detalii()
	EFA_GenerareFisierXML_Validare_DUK()
EndProc
Procedure EFA_GenerareFisierXML_Header
	oXML = CreateObject("msxml2.DOMDocument")		&& oXML = CreateObject("msxml2.DOMDocument.6.0")
	? "oXML ", Transform(oXML)
	*oXML.AppendChild(oXML.CreateNode("PROCESSINGINSTRUCTION", "xml", ""))				&& 19OCTOMBRIE2022
	oPI = oXML.CreateProcessingInstruction("xml", "version='1.0' encoding='UTF-8'")
	oXML.AppendChild(oPI)
	oInvoice = oXML.AppendChild(oXML.CreateElement("Invoice"))
	oInvoice.SetAttribute("xmlns:cbc", "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2")
	oInvoice.SetAttribute("xmlns:udt", "urn:oasis:names:specification:ubl:schema:xsd:UnqualifiedDataTypes-2")
	oInvoice.SetAttribute("xmlns:cac", "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2")
	oInvoice.SetAttribute("xmlns:ccts", "urn:un:unece:uncefact:documentation:2")
	oInvoice.SetAttribute("xmlns", "urn:oasis:names:specification:ubl:schema:xsd:Invoice-2")
	*oInvoice.SetAttribute("xmlns", "urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2")
	oInvoice.SetAttribute("xmlns:qdt", "urn:oasis:names:specification:ubl:schema:xsd:QualifiedDataTypes-2")
	*oInvoice.SetAttribute("xsi:schemaLocation", "urn:oasis:names:specification:ubl:schema:xsd:Invoice-2 ../../UBL-2.1(1)/xsd/maindoc/UBL-Invoice-2.1.xsd")		&&19.09.2023
	oInvoice.SetAttribute("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance")
	oInvoice.AppendChild(oXML.CreateElement("cbc:UBLVersionID"))
	oInvoice.LastChild.Text = "2.1"
	oInvoice.AppendChild(oXML.CreateElement("cbc:CustomizationID"))	&& <!--BT-24-->
	&& BT-24
	oInvoice.LastChild.Text = "urn:cen.eu:en16931:2017#compliant#urn:efactura.mfinante.ro:CIUS-RO:1.0.1"
EndProc
Procedure EFA_GenerareFisierXML_Antet
	&& BT-1		Numarul facturii
	loNode = oInvoice.AppendChild(oXML.CreateElement("cbc:ID"))				&& <!--BT-1-->
	*oInvoice.LastChild.Text = AllTrim(crsEFactura.Nr)
	loNode.Text = AllTrim(crsEFactura.Nr)
	XML_CreateComment("BT-1", loNode)
	&& BT-2		Data emiterii facturii
	oInvoice.AppendChild(oXML.CreateElement("cbc:IssueDate"))		&& <!--BT-2-->
	oInvoice.LastChild.Text = AllTrim(Str(Year(crsEFactura.Data)))+"-"+PadL(AllTrim(Str(Month(crsEFactura.Data))), 2, "0")+"-"+PadL(AllTrim(Str(Day(crsEFactura.Data))), 2, "0")
	XML_CreateComment("BT-2", oInvoice.LastChild)
	If IsNullOrEmpty(crsEFactura.Scadent)
		Replace Scadent With Data In crsEFactura
	EndIf	
	&& BT-9		Data scadentei 
	oInvoice.AppendChild(oXML.CreateElement("cbc:DueDate"))			&& <!--BT-9-->
	oInvoice.LastChild.Text = AllTrim(Str(Year(crsEFactura.Scadent)))+"-"+PadL(AllTrim(Str(Month(crsEFactura.Scadent))), 2, "0")+"-"+PadL(AllTrim(Str(Day(crsEFactura.Scadent))), 2, "0")
	XML_CreateComment("BT-9", oInvoice.LastChild)
	lcInvoiceType = ""
	*# -- InvoiceType
	*„Cod tip factura” (BT-3) trebuie sa fie unul dintre urmatoarele coduri din lista de coduri UNTDID 1001: 380 (Factura),  389 (Autofactura), 384 (Factura corectata), 381 (Nota de creditare),	&& Nu mai se foloseste 751 (Factura – informatii în scopuri contabile). ( Factura achitata cu bonfiscal sau bonuri fiscale indiferent de valoare si daca au CIF sau NU si facturate)
	*Am o întrebare legata de codul de facturare 751 care este în scopuri contabile. Înteleg ca orice are legatura cu un bon fiscal, daca se emite factura pentru un bon fiscal ar trebui sa poarte acest cod, indiferent daca valoarea achizitiei este mai mare de 100 euro?
	*ANAF:	Codul 751 se foloseste în momentul în care au fost emise unul sau mai multe bonuri fiscale, indiferent daca e sub 100 euro si ulterior se emite si factura.
	Do Case
		Case tnRectificativa=1
			lcInvoiceType = "384"			&& Factura corectata
			
		Case AllTrim(GetNrFromString(lcCodFiscal))==AllTrim(ICAS.oSoc.CodFiscal) Or tlIsAutoFactura
			lcInvoiceType = "389"			&& Autofactura
	    	Case lcTipFactura='L'
        		lcInvoiceType = "389"			&& Autofactura
		Case lnLiniiStornare=lnLinii
			lcInvoiceType = "380"
	    	Case (lcTipFactura=' ' .AND. mTiparit=1) .OR. lcTipFactura='f'
	        	lcInvoiceType = "751"			&& * 751 (Factura – informatii în scopuri contabile - Factura achita cu bonfiscal )
		OtherWise
			lcInvoiceType = "380"			&& Factura
	EndCase
	&& BT-3		Codul tipului facturii
	oInvoice.AppendChild(oXML.CreateElement("cbc:InvoiceTypeCode"))		&& <!--BT-3-->
	oInvoice.LastChild.Text = lcInvoiceType
	XML_CreateComment("BT-3", oInvoice.LastChild)
	? "lcInvoiceType (BT-3) ", Transform(lcInvoiceType)	
	&& BT-22		Comentariu in factura
	If lnTvaI=1
		oInvoice.AppendChild(oXML.CreateElement("cbc:Note"))			&& <!--BT-22-->
		oInvoice.LastChild.Text = "TVA la incasare"
		? "lnTvaI ", Transform(lnTvaI)
		XML_CreateComment("BT-22", oInvoice.LastChild)
		If _VFP.StartMode = 0
		    comment = oXML.createComment("BT-22")
	    	oInvoice.LastChild.appendChild(comment)
	    EndIf	
	EndIf
	If (lIsTaxareInversa Or lcTipFactura='T' .OR. (lcTipTert='I' .AND.  .NOT. EMPTY(lcCodFiscal) .AND.  .NOT. lHasFacturiCuTva))			&& Vicos.03.10.2023
		oInvoice.AppendChild(oXML.CreateElement("cbc:Note"))
		oInvoice.LastChild.Text = "Taxare inversa"
	EndIf
	? "BT-22		Comentariu in factura ", Transform(oInvoice.LastChild.Text)	
	lcInformatiiFactura=AllTrim(crsEFactura.Inf_Suplm)
	If  .Not. IsNullOrEmpty(lcInformatiiFactura)
		If ParseDiacritics(lcInformatiiFactura, 1)>0
			lcInformatiiFactura=ReplaceDiacritics(lcInformatiiFactura)
		EndIf
		oInvoice.AppendChild(oXML.CreateElement("cbc:Note"))
		oInvoice.LastChild.Text = lcInformatiiFactura
		? "lcInformatiiFactura ", Transform(oInvoice.LastChild.Text)
	EndIf
	lcInformatiiClient=AllTrim(crsEFactura.Inf_Supl)
	If  .Not. IsNullOrEmpty(lcInformatiiClient)
		If ParseDiacritics(lcInformatiiClient, 1)>0
			lcInformatiiClient=ReplaceDiacritics(lcInformatiiClient)
		EndIf
		oInvoice.AppendChild(oXML.CreateElement("cbc:Note"))
		oInvoice.LastChild.Text = lcInformatiiClient
		? "lcInformatiiClient ", Transform(oInvoice.LastChild.Text)
	EndIf
	IF  .NOT. tlIsAutoFactura			&& Vicos.12.02.2024
		If .NOT. IsNullOrEmpty(AllTrim(tcDetalii_CL))
		   lcInformatiiClient = AllTrim(StrTran(tcDetalii_CL, CHR(13), ';'))
		   oInvoice.AppendChild(oXML.CreateElement("cbc:Note"))
		   oInvoice.LastChild.Text = AllTrim(SubStr(lcInformatiiClient, 1, Min(Len(lcInformatiiClient), 300)))
		   ? "tcDetalii_CL ", Transform(oInvoice.LastChild.Text)
		EndIf
	EndIf
	&& IDEM pentru:		infoSupl1, infoSupl2, infoSupl3
	*
	* Data exigibilitate TVA (BT-7)
	*	<cbc:TaxPointDate>2009-11-13</cbc:TaxPointDate><!--BT-7-->
	*
	&& BT-5		Codul monedei
	oInvoice.AppendChild(oXML.CreateElement("cbc:DocumentCurrencyCode"))
	oInvoice.LastChild.Text = AllTrim(Moneda)
	XML_CreateComment("BT-5", oInvoice.LastChild)
	? "BT-5		Codul monedei ", Transform(oInvoice.LastChild.Text)
	&& BT-6
	oInvoice.AppendChild(oXML.CreateElement("cbc:TaxCurrencyCode"))
	oInvoice.LastChild.Text = "RON"										&& AICI clar trebuie numai "RON"
	XML_CreateComment("BT-6", oInvoice.LastChild)
	? "BT-6 ", Transform(oInvoice.LastChild.Text)
	*///////////////////////////////////////////////////////////////////////////////////////
	* Campuri NOI MEDICI
	If Not IsNullOrEmpty(crsEFactura.BT_13)
		oOrderReference = oInvoice.AppendChild(oXML.CreateElement("cac:OrderReference"))
		&& BT-13		Referinta comenzii
		oOrderReference.AppendChild(oXML.CreateElement("cbc:ID"))
		oOrderReference.LastChild.Text = crsEFactura.BT_13
		XML_CreateComment("BT-13", oInvoice.LastChild)
		*? "BT-13		Referinta comenzii", Transform(oInvoice.LastChild.Text)
        EndIf
	If lcInvoiceType='384'		&& Rectificativa, 384 (Factura corectata)
		oBillingReference						= oInvoice.AppendChild(oXML.CreateElement("cac:BillingReference"))
		oOrderDocumentReference					= oBillingReference.AppendChild(oXML.CreateElement("cac:InvoiceDocumentReference"))
		oOrderDocumentReference.AppendChild(oXML.CreateElement("cbc:ID"))
		oOrderDocumentReference.LastChild.Text	= AllTrim(crsEFactura.Nr)
		XML_CreateComment("BT-25", oOrderDocumentReference.LastChild)
		oOrderDocumentReference.AppendChild(oXML.CreateElement("cbc:IssueDate"))
		oOrderDocumentReference.LastChild.Text	= AllTrim(Str(Year(crsEFactura.Data)))+"-"+PadL(AllTrim(Str(Month(crsEFactura.Data))), 2, "0")+"-"+PadL(AllTrim(Str(Day(crsEFactura.Data))), 2, "0")
		XML_CreateComment("BT-26", oOrderDocumentReference.LastChild)
	EndIf
	*
	If ll_Is_ICAS
		Set Procedure To Efactura_EmbeddedDocumentBinaryObject_Test Additive
		&& <!--BG-24-->		Documente atasate
		oADR						= oInvoice.AppendChild(oXML.CreateElement("cac:AdditionalDocumentReference"))
		oADR_cbc_ID					= oADR.AppendChild(oXML.CreateElement("cbc:ID"))
		oADR_cbc_ID.Text			= '1'
		XML_CreateComment("BT-18", oADR_cbc_ID)
		*
		oADR_DD						= oADR.AppendChild(oXML.CreateElement("cbc:DocumentDescription"))
		oADR_DD.Text				= 'pdf'
		*
		oADR_Attachment 			= oADR.AppendChild(oXML.CreateElement("cac:Attachment"))
		oADR_Attachment_EDBO		= oADR_Attachment.AppendChild(oXML.CreateElement("cbc:EmbeddedDocumentBinaryObject"))
		oADR_Attachment_EDBO.SetAttribute("mimeCode", "application/pdf")
		lcPdfFileName = EFactura_EmbeddedDocumentBinaryObject_Test( crsEFactura.IdDoc, Iif(lcAlias='Iesiri', 0, 1), 1)
		oADR_Attachment_EDBO.SetAttribute("filename", JustFname( lcPdfFileName ) )
		&& <!--BT-125-->
		oADR_Attachment_EDBO.Text	= Pdf2Base64( lcPDFFileName )
	EndIf
	* Campuri NOI MEDICI
	*///////////////////////////////////////////////////////////////////////////////////////
    If Not IsNullOrEmpty(crsEFactura.BT_11)
		oProjectReference = oInvoice.AppendChild(oXML.CreateElement("cac:ProjectReference"))
		&& BT-11		ProjectReference
		oProjectReference.AppendChild(oXML.CreateElement("cbc:ID"))
		oProjectReference.LastChild.Text = crsEFactura.BT_11
		XML_CreateComment("BT-11", oProjectReference.LastChild)
    EndIf
	*///////////////////////////////////////////////////////////////////////////////////////
	If lcInvoiceType<>'384'			&& Rectificativa, 384 (Factura corectata)
		If Used("C_EFACTURA_STORNO") .And. RecCount("C_EFACTURA_STORNO")>0
			Select c_EFactura_Storno
			Scan
				lcNumarDoc = AllTrim(c_EFactura_Storno.Ndp)
				ldDataDocStorno = AllTrim(Str(Year(c_EFactura_Storno.Data)))+"-"+PadL(AllTrim(Str(Month(c_EFactura_Storno.Data))), 2, "0")+"-"+PadL(AllTrim(Str(Day(c_EFactura_Storno.Data))), 2, "0")
				oBillingReference = oInvoice.AppendChild(oXML.CreateElement("cac:BillingReference"))
				oOrderDocumentReference = oBillingReference.AppendChild(oXML.CreateElement("cac:InvoiceDocumentReference"))
				oOrderDocumentReference.AppendChild(oXML.CreateElement("cbc:ID"))
				oOrderDocumentReference.LastChild.Text = lcNumarDoc
				XML_CreateComment("BT-25", oOrderDocumentReference.LastChild)
				oOrderDocumentReference.AppendChild(oXML.CreateElement("cbc:IssueDate"))
				oOrderDocumentReference.LastChild.Text = ldDataDocStorno
				XML_CreateComment("BT-26", oOrderDocumentReference.LastChild)
				&& 29.08.2024
	            IF IsNullOrEmpty(c_EFactura_Storno.Id_Solicit)=.F.
	                oBillingReferenceIndexSpv					= oInvoice.AppendChild(oXML.CreateElement("cac:BillingReference"))
	                oOrderDocumentReferenceSpv					= oBillingReferenceIndexSpv.AppendChild(oXML.CreateElement("cac:InvoiceDocumentReference"))
	                oOrderDocumentReferenceSpv.AppendChild(oXML.CreateElement("cbc:ID"))
	                oOrderDocumentReferenceSpv.LastChild.Text	= "Index incarcare SPV: "+AllTrim(c_EFactura_Storno.Id_Solicit)
	                XML_CreateComment("BT-25", oOrderDocumentReferenceSpv.LastChild)
	            ENDIF
			EndScan
		EndIf
	EndIf
EndProc
Procedure EFA_GenerareFisierXML_VANZATOR
	Select crsEFactura
	? "--BG-4 SUPPLIER VANZATOR--"
	oSupplier = oInvoice.AppendChild(oXML.CreateElement("cac:AccountingSupplierParty"))
	oParty = oSupplier.AppendChild(oXML.CreateElement("cac:Party"))
	If Not Empty(AllTrim(ICAS.oSoc.Email))
		&& BT-34
		oEndpointId = oParty.AppendChild(oXML.CreateElement("cbc:EndpointID"))
		oEndpointId.SetAttribute("schemeID", "EM")
		oEndpointId.Text = AllTrim(ICAS.oSoc.Email)
		XML_CreateComment("BT-34", oEndpointId)
		? "BT-34 Email", Transform(oEndpointId.Text)
	EndIf	
	If  .Not. Empty(crsEFactura.Cod_Fiscal) .AND. VerifCF(crsEFactura.Cod_Fiscal)
		oPartyIdentification = oParty.AppendChild(oXML.CreateElement("cac:PartyIdentification"))
		&& BT-29 BT-29-1
		oIdParty = oPartyIdentification.AppendChild(oXML.CreateElement("cbc:ID"))
		oIdParty.Text = ICAS.oSoc.CodFiscal
		? "BT-29 BT-29-1 Cod fiscal FURNIZOR ", Transform(oIdParty.Text)
		XML_CreateComment("BT-29", oIdParty)
	EndIf
	&& BG-5
	oAdresa = oParty.AppendChild(oXML.CreateElement("cac:PostalAddress"))
	If Empty(ICAS.oSoc.Strada)
		MessageBox("Completati strada in ecranul 'Configurare societati'.", 48, "Date incomplete...",3000)
		Return "Completati strada in ecranul 'Configurare societati'."
		Return
	EndIf
	&& BT-35		Strada, numarul
	oAdresa.AppendChild(oXML.CreateElement("cbc:StreetName"))
	If ICAS.cBackEnd='MySQL'
		oAdresa.LastChild.Text = AllTrim(ICAS.oSoc.Strada)
	Else	
		&& STANIMIR::	23.09.2024
		*oAdresa.LastChild.Text = GetAdresa('', '', '', ICAS.oSoc.Strada, ICAS.oSoc.NumarStrada, ICAS.oSoc.Bloc, ICAS.oSoc.Scara, ICAS.oSoc.Etaj, ICAS.oSoc.Apartament, ICAS.oSoc.CodPostal, ICAS.oSoc.Telefon)
		&& Fara judet, localitate, sector
		&& Iau numai strada, NumarStrada, Bloc, Scara, Etaj, Apartament
		&& Sediu social: Municipiul Oltenita, Strada PESCARILOR, Nr.23, Bloc M6, Scara A, Etaj PARTER, Ap.3, Judet Calarasi
		oAdresa.LastChild.Text = GetAdresa('', '', '', ICas.oSoc.Strada, ICas.oSoc.NumarStrada, ICas.oSoc.Bloc, ICas.oSoc.Scara, ICas.oSoc.Etaj, ICas.oSoc.Apartament)
		XML_CreateComment("BT-35", oAdresa.LastChild)
	EndIf
	&& <cbc:AdditionalStreetName>Suite 123</cbc:AdditionalStreetName><!--BT-36-->
	If Empty(ICAS.oSoc.Localitate)
		MessageBox("Completati localitatea in ecranul 'Configurare societati'.", 48, "Date incomplete...",3000)
		Return "Completati localitatea in ecranul 'Configurare societati'."
		Return
	EndIf
	If Empty(ICAS.oSoc.Judet)
		MessageBox("Alegeti judetul in ecranul 'Configurare societati'.", 48, "Date incomplete...", 3000)
		Return "Alegeti judetul in ecranul 'Configurare societati'."
		Return
	Else
		If ICAS.oSoc.Judet="BUCURESTI" .And. Empty(ICAS.oSoc.Sector)
			MessageBox("Completati sectorul in ecranul 'Configurare societati'.", 48, "Date incomplete...",3000)
			Return "Completati sectorul in ecranul 'Configurare societati'."
			Return
		EndIf
	EndIf
	&& BT-37		Localitatea
	oAdresa.AppendChild(oXML.CreateElement("cbc:CityName"))
	*oAdresa.LastChild.Text = AllTrim(Upper(ICAS.oSoc.Localitate))+IIf(ICAS.oSoc.Judet="BUCURESTI" .And.  .Not. ("SECT"$Upper(ICAS.oSoc.Localitate)), " SECTOR"+AllTrim(ICAS.oSoc.Sector), "")
	oAdresa.LastChild.Text = IIf(ICAS.oSoc.Judet="BUCURESTI" .And.  .Not. ("SECT"$Upper(ICAS.oSoc.Localitate)), " SECTOR"+AllTrim(ICAS.oSoc.Sector), AllTrim(Upper(ICAS.oSoc.Localitate)))
	XML_CreateComment("BT-37", oAdresa.LastChild)
	&& <cbc:PostalZone>54321</cbc:PostalZone><!--BT-38-->		Codul postal
	If ll_Is_ICAS
		Text To lcSQL NoShow TextMerge
			Select
				Cod
			From Configurari.Judete 
			Where
				DenJud=?ICAS.oSoc.Judet
		EndText
		mySQLExec(lcSQL, [crsSQLJudete])
	Else
		Select Cod From Judete Where DenJud=ICAS.oSoc.Judet Into Cursor crsSQLJudete
	EndIf
	Select * From crsSQLJudete Into Array aGetJudAdresa
	mCodJudet = ""
	If _Tally>0 .And.  .Not. IsNull(aGetJudAdresa(1))
		mCodJudet = aGetJudAdresa(1)
	EndIf
	&& BT-39		Subdiviziunea tarii
	oAdresa.AppendChild(oXML.CreateElement("cbc:CountrySubentity"))
	oAdresa.LastChild.Text = 'RO-'+AllTrim(mCodJudet)
	XML_CreateComment("BT-39", oAdresa.LastChild)
	oTara = oAdresa.AppendChild(oXML.CreateElement("cac:Country"))
	&& BT-40		Codul tarii
	oTara.AppendChild(oXML.CreateElement("cbc:IdentificationCode"))
	oTara.LastChild.Text = "RO"
	XML_CreateComment("BT-40", oTara.LastChild)
	&& </cac:PostalAddress>	BG-5
	Select Count(*) From crsTva_EFactura Where Tip='E' OR (Tip='S' And ProcTva=8) Into Array aGetExceptiiTva			&& 12Iunie2023
	lIsExceptii = .F.
	If _TALLY>0 .AND. aGetExceptiiTva(1)>0
		   lIsExceptii=.T.
	EndIf
	oTaxe = oParty.AppendChild(oXML.CreateElement("cac:PartyTaxScheme"))
	oTaxe.AppendChild(oXML.CreateElement("cbc:CompanyID"))
	oTaxe.LastChild.Text = AllTrim("RO"+OnlyNumber(ICAS.oSoc.CodFiscal))
	XML_CreateComment("BT-31", oTaxe.LastChild)
	oSchemaTaxe = oTaxe.AppendChild(oXML.CreateElement("cac:TaxScheme"))
	If lnTipTvaCurent<3 .Or. (lIsExceptii)							&& 28.10.2024
		oSchemaTaxe.AppendChild(oXML.CreateElement("cbc:ID"))
		oSchemaTaxe.LastChild.Text = "VAT"
		XML_CreateComment("BT-29", oSchemaTaxe.LastChild)
	EndIf
	oFormaLegala = oParty.AppendChild(oXML.CreateElement("cac:PartyLegalEntity"))
	&& BT-27		Numele/ Denumirea
	oFormaLegala.AppendChild(oXML.CreateElement("cbc:RegistrationName"))
	m.DenumireSocietate=AllTrim(ICAS.oSoc.Denumire)
	If ParseDiacritics(m.DenumireSocietate, 1)=1
   		m.DenumireSocietate=ReplaceDiacritics(m.DenumireSocietate, 0)
   	EndIf
	oFormaLegala.LastChild.Text = m.DenumireSocietate
	XML_CreateComment("BT-27", oFormaLegala.LastChild)
	&& BT-30 BT-30-1		Identificatorul de inregistrare legala
	oIdentificatorFormaLegala = oFormaLegala.AppendChild(oXML.CreateElement("cbc:CompanyID"))
	If lnTipTvaCurent<3 And Not IsNullOrEmpty(ICAS.oSoc.RegistruComertului)
		oIdentificatorFormaLegala.Text = AllTrim(ICAS.oSoc.RegistruComertului)
	Else
		*oIdentificatorFormaLegala.Text = AllTrim(ICAS.oSoc.CodFiscal)
		oIdentificatorFormaLegala.Text = AllTrim(Nvl(ICAS.oSoc.RegistruComertului, ''))	&& 28.06.2024 STANIMIR
	EndIf
	XML_CreateComment("BT-30", oIdentificatorFormaLegala)
	*&& 30.07.2024
    IF Not IsNullOrEmpty(ICAS.oSoc.CapitalSocial)
        oFormaLegala.AppendChild(oXML.CreateElement("cbc:CompanyLegalForm"))
        oFormaLegala.LastChild.Text = "Capital social: "+AllTrim(Str(ICAS.oSoc.CapitalSocial, 15, 0))
        XML_CreateComment("BT-33", oFormaLegala.LastChild)
    ENDIF
	*&& 30.07.2024
	mDenSoc = Upper(ICAS.oSoc.Denumire)+" "
	If  .Not. Empty(ICAS.oSoc.NumePersoanaAutorizata) .Or.  .Not. Empty(ICAS.oSoc.PrenumePersoanaAutorizata) .Or.  .Not. Empty(ICAS.oSoc.Email) .Or.  .Not. Empty(ICAS.oSoc.Telefon)
		&& BG-6
		oContact = oParty.AppendChild(oXML.CreateElement("cac:Contact"))
		If  .Not. Empty(ICAS.oSoc.NumePersoanaAutorizata) .Or.  .Not. Empty(ICAS.oSoc.PrenumePersoanaAutorizata)
			&& BT-41
			oContact.AppendChild(oXML.CreateElement("cbc:Name"))
			oContact.LastChild.Text = AllTrim(ICAS.oSoc.NumePersoanaAutorizata)+" "+AllTrim(ICAS.oSoc.PrenumePersoanaAutorizata)
			XML_CreateComment("BT-41", oContact.LastChild)
		EndIf
		If  .Not. Empty(ICAS.oSoc.Telefon)
			&& BT-42
			oContact.AppendChild(oXML.CreateElement("cbc:Telephone"))
			oContact.LastChild.Text = AllTrim(ICAS.oSoc.Telefon)
			XML_CreateComment("BT-42", oContact.LastChild)
		EndIf
		If  .Not. Empty(ICAS.oSoc.Email)
			&& BT-43
			oContact.AppendChild(oXML.CreateElement("cbc:ElectronicMail"))
			oContact.LastChild.Text = AllTrim(ICAS.oSoc.Email)
			XML_CreateComment("BT-43", oContact.LastChild)
		EndIf
	EndIf
	* TODO:	oDelivery = oInvoice.AppendChild(oXML.CreateElement("cac:Delivery"))		oDeliveryLocation = oDelivery.AppendChild(oXML.CreateElement("cac:DeliveryLocation"))
	Select crsEFactura
	Locate
EndProc
Procedure EFA_GenerareFisierXML_CUMPARATOR
	&& --BG-7 CUMPARATOR--
	oCustomer = oInvoice.AppendChild(oXML.CreateElement("cac:AccountingCustomerParty"))
	oPartys = oCustomer.AppendChild(oXML.CreateElement("cac:Party"))
	&& BT-49 BT-49-1
	If Not Empty(AllTrim(crsEFactura.Email))
		* NIC
		oEndpointId = oPartys.AppendChild(oXML.CreateElement("cbc:EndpointID"))
		oEndpointId.SetAttribute("schemeID", "EM")
		oEndpointId.Text = AllTrim(crsEFactura.Email)
		XML_CreateComment("BT-49", oEndpointId)
	EndIf
	oPartyIdentifications = oPartys.AppendChild(oXML.CreateElement("cac:PartyIdentification"))
	&& BT-46 BT-46-1
	oIdPartys = oPartyIdentifications.AppendChild(oXML.CreateElement("cbc:ID"))
	If ICAS.oSoc.MODPLATATVA = 3								&& emitent Neplatitor TVA
		oIdPartys.Text = OnlyNumber(crsEFactura.Cod_Fiscal)		&& Daca are "RO" in fata si emitetnul nu este platitor de TVA, da EROARE din Decembrie.2024
	Else
		oIdPartys.Text = crsEFactura.Cod_Fiscal
	EndIf
	XML_CreateComment("BT-46", oIdPartys)
	&& BG-8
	oAdresas = oPartys.AppendChild(oXML.CreateElement("cac:PostalAddress"))
	lcAdresa = GetAdresa('', '', '', Nvl(crsEFactura.Strada, ''), Nvl(crsEFactura.Nr_Str, ''), Nvl(crsEFactura.Bloc, ''), Nvl(crsEFactura.Scara, ''), Nvl(crsEFactura.Etaj, ''), Nvl(crsEFactura.Ap, ''),'', '')
	If Empty(lcAdresa)
		MessageBox("Completati adresa clientului.", 48, "Date incomplete...",3000)
		Return "Completati adresa clientului."
		Return
	EndIf
	&& BT-50		Strada, numarul CUMPARATOR
	oAdresas.AppendChild(oXML.CreateElement("cbc:StreetName"))
	oAdresas.LastChild.Text = AllTrim(lcAdresa)
	XML_CreateComment("BT-50", oAdresas.LastChild)
	&& <cbc:AdditionalStreetName>Corpul A</cbc:AdditionalStreetName><!--BT-51-->
	If Empty(crsEFactura.Localitate)
		MessageBox("Completati localitatea in adresa clientului.", 48, "Date incomplete...",3000)
		Return "Completati localitatea in adresa clientului."
		Return
	EndIf
	&& BT-52		Localitatea CUMPARATOR
	If crsEFactura.Tara="RO"
		oAdresas.AppendChild(oXML.CreateElement("cbc:CityName"))
		If crsEFactura.Judet="B " Or crsEFactura.Judet="BUCURESTI" OR crsEFactura.Judet="MUNICIPIUL BUCURESTI" 
			Do Case
				Case Not IsNullOrEmpty(AllTrim(crsEFactura.Sector))
					lcSector = 'SECTOR'+AllTrim(crsEFactura.Sector)
				Case "SECTOR"$Upper(crsEFactura.Localitate)
					lcSector = AllTrim(crsEFactura.Localitate)
				OtherWise
					lcSector = ''+AllTrim(crsEFactura.Sector)
			EndCase
			oAdresas.LastChild.Text = Upper(lcSector)
		Else
			oAdresas.LastChild.Text = AllTrim(crsEFactura.Localitate)
		EndIf
	Else
		If  .Not. Empty(crsEFactura.Localitate)
			oAdresas.AppendChild(oXML.CreateElement("cbc:CityName"))
			oAdresas.LastChild.Text = AllTrim(crsEFactura.Localitate)
		EndIf
	EndIf
	XML_CreateComment("BT-52", oAdresas.LastChild)
	If Empty(crsEFactura.Judet)
		MessageBox("Alegeti judetul clientului.", 48, "Date incomplete...", 3000)
		Return "Alegeti judetul clientului."		
		Return
	EndIf
	&& -BT-54		Subdiviziunea tarii  CUMPARATOR
	If ll_Is_ICAS
		Text To lcSQL NoShow TextMerge
			Select
				Cod
			From Configurari.Judete 
			Where
				DenJud=?crsEFactura.Judet
		EndText
		mySQLExec(lcSQL, [crsSQLJudetePartener])
	Else
		Select Cod From Judete Where DenJud=crsEFactura.Judet Into Cursor crsSQLJudetePartener
	EndIf
	Select * From crsSQLJudetePartener Into Array aGetJudAdresaPartener
	lcCodJudetPartener = ""
	If _Tally>0 .And.  .Not. IsNull(aGetJudAdresaPartener(1))
		lcCodJudetPartener = aGetJudAdresaPartener(1)
	EndIf
	If crsEFactura.Tara="RO"
		oAdresas.AppendChild(oXML.CreateElement("cbc:CountrySubentity"))
		oAdresas.LastChild.Text = 'RO-'+AllTrim(lcCodJudetPartener)
	EndIf	
	XML_CreateComment("BT-54", oAdresas.LastChild)
	oTaras = oAdresas.AppendChild(oXML.CreateElement("cac:Country"))
	&& BT-55		Codul tarii	CUMPARATOR
	oTaras.AppendChild(oXML.CreateElement("cbc:IdentificationCode"))
	oTaras.LastChild.Text = IIf( .Not. Empty(crsEFactura.Tara), crsEFactura.Tara, "RO")
	XML_CreateComment("BT-55", oTaras.LastChild)
	If crsEFactura.Tara='RO' .And.  .Not. IsNullOrEmpty(crsEFactura.Cod_Fiscal) .And. VerifCF(crsEFactura.Cod_Fiscal)
		If Len(AllTrim(crsEFactura.Cod_Fiscal))<12
			IF (lnTipTvaCurent<3 .OR. lIsExceptii) .AND. "RO"$crsEFactura.Cod_Fiscal								&& 23Iunie2023
				oTaxes = oPartys.AppendChild(oXML.CreateElement("cac:PartyTaxScheme"))
				oTaxes.AppendChild(oXML.CreateElement("cbc:CompanyID"))
				oTaxes.LastChild.Text = AllTrim("RO"+OnlyNumber(crsEFactura.Cod_Fiscal))
				XML_CreateComment("BT-47", oTaxes.LastChild)
				oSchemaTaxes = oTaxes.AppendChild(oXML.CreateElement("cac:TaxScheme"))
				oSchemaTaxes.AppendChild(oXML.CreateElement("cbc:ID"))
				oSchemaTaxes.LastChild.Text = "VAT"
				XML_CreateComment("BT-46", oSchemaTaxes.LastChild)
			EndIf																									&& 23Iunie2023
		EndIf
	Else
		oTaxes = oPartys.AppendChild(oXML.CreateElement("cac:PartyTaxScheme"))
		If crsEFactura.Tara<>'RO' .And.  .Not. IsNullOrEmpty(crsEFactura.Cod_Fiscal)
			oTaxes.AppendChild(oXML.CreateElement("cbc:CompanyID"))
			oTaxes.LastChild.Text = AllTrim(crsEFactura.Tara+StrTran(Upper(crsEFactura.Cod_Fiscal), crsEFactura.Tara, ""))
			XML_CreateComment("BT-47", oTaxes.LastChild)
		EndIf
		oSchemaTaxes = oTaxes.AppendChild(oXML.CreateElement("cac:TaxScheme"))
		If lnTipTvaCurent<3
			oSchemaTaxes.AppendChild(oXML.CreateElement("cbc:ID"))
			oSchemaTaxes.LastChild.Text = "VAT"
			XML_CreateComment("BT-46", oSchemaTaxes.LastChild)
		EndIf	
	EndIf
	oFormaLegalas = oPartys.AppendChild(oXML.CreateElement("cac:PartyLegalEntity"))
	&& BT-44		Numele/ Denumirea
	oFormaLegalas.AppendChild(oXML.CreateElement("cbc:RegistrationName"))
	oFormaLegalas.LastChild.Text = AllTrim(crsEFactura.Den_Cli)
	XML_CreateComment("BT-44", oFormaLegalas.LastChild)
		&& BT-47 BT-47-1		Identificatorul de inregistrare legala  CUMPARATOR
	oIdentificatorFormaLegalas = oFormaLegalas.AppendChild(oXML.CreateElement("cbc:CompanyID"))
	If crsEFactura.Tara="RO"
        IF "RO" $ crsEFactura.Cod_Fiscal And Not IsNullOrEmpty(crsEFactura.Reg_Com)
        	If ICAS.oSoc.MODPLATATVA = 3											&& emitent Neplatitor TVA
        		oIdentificatorFormaLegalas.Text = OnlyNumber(crsEFactura.Cod_Fiscal)
        	Else
	            oIdentificatorFormaLegalas.Text = AllTrim(crsEFactura.Reg_Com)		&& eroare Cornelia la emitenti Neplatitori de TVA
	        EndIf
        ELSE
            oIdentificatorFormaLegalas.Text = AllTrim(crsEFactura.Cod_Fiscal)
        ENDIF
    ELSE
		oIdentificatorFormaLegalas.Text = AllTrim(crsEFactura.Tara+StrTran(Upper(crsEFactura.Cod_Fiscal), crsEFactura.Tara, ""))
    ENDIF	
	XML_CreateComment("BT-47", oIdentificatorFormaLegalas)
	mDenSoc = AllTrim(crsEFactura.Den_Cli)+" "
	If  .Not. Empty(crsEFactura.Telefon) .Or.  .Not. Empty(crsEFactura.Email) .Or.  .Not. Empty(crsEFactura.Delegat)
		oContacts = oPartys.AppendChild(oXML.CreateElement("cac:Contact"))
		If  .Not. Empty(crsEFactura.Delegat)
			&& BT-56
			oContacts.AppendChild(oXML.CreateElement("cbc:Name"))
			oContacts.LastChild.Text = AllTrim(crsEFactura.Delegat)
			XML_CreateComment("BT-56", oContacts.LastChild)
		EndIf
		If  .Not. Empty(crsEFactura.telefon)
			&& BT-57
			oContacts.AppendChild(oXML.CreateElement("cbc:Telephone"))
			oContacts.LastChild.Text = AllTrim(crsEFactura.Telefon)
			XML_CreateComment("BT-57", oContacts.LastChild)
		EndIf
		If  .Not. Empty(crsEFactura.Email)
			&& BT-58
			oContacts.AppendChild(oXML.CreateElement("cbc:ElectronicMail"))
			oContacts.LastChild.Text = AllTrim(crsEFactura.Email)
			XML_CreateComment("BT-58", oContacts.LastChild)
		EndIf
	EndIf
	Select crsEFactura
	If RecCount("C_INCASARI_EFACT")>0 .And. ICas.oSettings.IsPS=.F.
		Select c_Incasari_eFact
		Scan
			mCodInstrumentPlata			= ""
			mDenumireInstrumentPlata	= ""
			mExplicatie					= AllTrim(c_Incasari_eFact.Explicatie)
			mExplicatieInstrumentPlata	= ""
			mNumarDocument				= AllTrim(c_Incasari_eFact.Ndp)
			Do Case
				Case c_Incasari_eFact.ContD='532' .Or. c_Incasari_eFact.ContC='532'
					mCodInstrumentPlata = "26"
					mDenumireInstrumentPlata = "Local cheque"
					mExplicatieInstrumentPlata = "VOUCHER"
				Case c_Incasari_eFact.ContD='5125' .Or. c_Incasari_eFact.ContC='5125'
					mCodInstrumentPlata = "48"
					mDenumireInstrumentPlata = "Bank card"
					mExplicatieInstrumentPlata = "Virament bancar"
				Case c_Incasari_eFact.ContD='512' .Or. c_Incasari_eFact.ContC='512'
					mCodInstrumentPlata = "42"
					mDenumireInstrumentPlata = "Bank"
					mExplicatieInstrumentPlata = "Virament bancar"
				Case c_Incasari_eFact.ContD='531' .Or. c_Incasari_eFact.ContC='531'
					mCodInstrumentPlata = "10"
					mDenumireInstrumentPlata = "In cash"
					mExplicatieInstrumentPlata = "Numerar"
				Case c_Incasari_eFact.ContD='413' .Or. c_Incasari_eFact.ContC='413'
					mCodInstrumentPlata = "20"
					mDenumireInstrumentPlata = "Cheque "
				Case c_Incasari_eFact.ContD='401'
					mCodInstrumentPlata = "97"
					mDenumireInstrumentPlata = "Clearing between partners"
					mExplicatieInstrumentPlata = "Compensare"
			EndCase
			*	###   TODO si pt tlIsAutoFactura
		EndScan
	EndIf
	*--	27.06.2024 STANIMIR: Detalii Cont Banca
	If ll_Is_ICAS
		mySQLExec([Select * From vBanci], [vBanci])	
		Select c.ID As IdBanca, c.Denumire, c.ContBanca From crsEFactura e Inner Join vBanci c On e.IdBanca1 = c.Id Where IdBanca1>0;
		Union All;
		Select c.ID As IdBanca, c.Denumire, c.ContBanca	From crsEFactura e Inner Join vBanci c On e.IdBanca2 = c.Id Where IdBanca2>0;
		Union All;
		Select c.ID As IdBanca, c.Denumire, c.ContBanca From crsEFactura e Inner Join vBanci c On e.IdBanca3 = c.Id Where IdBanca3>0;
		Union All;
		Select c.ID As IdBanca, c.Denumire, c.ContBanca From crsEFactura e Inner Join vBanci c On e.IdBanca4 = c.Id Where IdBanca4>0;
		Into Cursor cGetBanciVANZATOR
	Else
		Create Cursor cGetBanciVANZATOR( Id Int, Denumire C(50), ContBanca C(24) )
		Insert Into cGetBanciVANZATOR( Id, Denumire, ContBanca) Values (1, _cBanca1,  _cContu1)
		Insert Into cGetBanciVANZATOR( Id, Denumire, ContBanca) Values (1, _cBanca2,  _cContu2)
	EndIf	
	If _Tally>0
		Scan
			mContBanca = AllTrim(cGetBanciVANZATOR.ContBanca)
			If IsNullOrEmpty(mContBanca)
				mIbanValid =''
			Else	
				mIbanValid = GetIbanFromString(mContBanca, 1)
			EndIf	
			If  .Not. IsNullOrEmpty(AllTrim(mIbanValid))
				mContBanca								= SubStr(mContBanca, At(mIbanValid, mContBanca)+Len(mIbanValid))
				mBanca									= GetBanca(mIbanValid)		&& cGetBanciVANZATOR.Denumire
				oPaymentMeans							= oInvoice.AppendChild(oXML.CreateElement("cac:PaymentMeans"))
				oPaymentMeansCode						= oPaymentMeans.AppendChild(oXML.CreateElement("cbc:PaymentMeansCode"))
				oPaymentMeansCode.Text					= 42		&& Plata in cont bancar (10 plata in casa)
				XML_CreateComment("BT-81", oPaymentMeansCode)
				oPayeeFinancialAccount					= oPaymentMeans.AppendChild(oXML.CreateElement("cac:PayeeFinancialAccount"))
				oPayeeFinancialAccount.AppendChild(oXML.CreateElement("cbc:ID"))
				oPayeeFinancialAccount.LastChild.Text	= AllTrim(mIbanValid)
				XML_CreateComment("BT-84", oPayeeFinancialAccount.LastChild)
				If  .Not. Empty(AllTrim(mBanca))
					oPayeeFinancialAccount.AppendChild(oXML.CreateElement("cbc:Name"))
					oPayeeFinancialAccount.LastChild.Text = AllTrim(mBanca)
					XML_CreateComment("BT-85", oPayeeFinancialAccount.LastChild)
				EndIf
			EndIf
		EndScan
	EndIf
	*--	27.06.2024 STANIMIR
	Select crsEFactura
	If lnLiniiReducere>0
		Select crsEFactura
		Scan For Indice=-1
			&& <!-- BG-21 TAXE SUPLIMENTARE-->
			oAllowanceCharge = oInvoice.AppendChild(oXML.CreateElement("cac:AllowanceCharge"))
			oAllowanceCharge.AppendChild(oXML.CreateElement("cbc:ChargeIndicator"))
			oAllowanceCharge.LastChild.Text = "false"
			XML_CreateComment("CI-92", oAllowanceCharge.LastChild)
			&& BT-105
			oAllowanceCharge.AppendChild(oXML.CreateElement("cbc:AllowanceChargeReasonCode"))
			oAllowanceCharge.LastChild.Text = "95"
			XML_CreateComment("BT-105", oAllowanceCharge.LastChild)
			&& BT-104
			oAllowanceCharge.AppendChild(oXML.CreateElement("cbc:AllowanceChargeReason"))
			If tlIsAutoFactura
				oAllowanceCharge.LastChild.Text = IIf(crsEFactura.Cont="767", "Scont", IIf(crsEFactura.Cont="609", "Reducere comerciala", "Discount"))
			Else
				oAllowanceCharge.LastChild.Text = IIf(crsEFactura.Cont="667", "Scont", IIf(crsEFactura.Cont="709", "Reducere comerciala", "Discount"))
			EndIf	
			XML_CreateComment("BT-104", oAllowanceCharge.LastChild)
			*
			&& <cbc:MultiplierFactorNumeric>10.00</cbc:MultiplierFactorNumeric><!--BT-101-->
			oDocAllowanceCharge = oAllowanceCharge.AppendChild(oXML.CreateElement("cbc:Amount"))
			&& BT-99
			oDocAllowanceCharge.SetAttribute("currencyID", lcMoneda)
			oDocAllowanceCharge.Text = AllTrim(Str(Abs(crsEFactura.Valoare), 15, 2))			&&-- 05.11.2024 
			XML_CreateComment("BT-99", oDocAllowanceCharge)
			&& <cbc:BaseAmount currencyID="RON">1500</cbc:BaseAmount><!--BT-100-->
			oTaxCategoryAllowance = oAllowanceCharge.AppendChild(oXML.CreateElement("cac:TaxCategory"))
			&& BT-102
			oTaxCategoryAllowance.AppendChild(oXML.CreateElement("cbc:ID"))
			Select Tip From crsTva_EFactura Where ProcTva=crsEFactura.ProcTva Into Array aGetTipCota
			oTaxCategoryAllowance.LastChild.Text = AllTrim(aGetTipCota(1))
			XML_CreateComment("BT-102", oTaxCategoryAllowance.LastChild)
			&& BT-103
			If aGetTipCota(1)<>'O'
				oTaxCategoryAllowance.AppendChild(oXML.CreateElement("cbc:Percent"))
				oTaxCategoryAllowance.LastChild.Text = AllTrim(Str(crsEFactura.ProcTva, 2, 0))
				XML_CreateComment("BT-103", oTaxCategoryAllowance.LastChild)
			EndIf
			oTaxSchemeAllowance = oTaxCategoryAllowance.AppendChild(oXML.CreateElement("cac:TaxScheme"))
			oTaxSchemeAllowance.AppendChild(oXML.CreateElement("cbc:ID"))
			oTaxSchemeAllowance.LastChild.Text = "VAT"
		EndScan
	EndIf
	&& !-- BG-20 DEDUCERI--
	Select crsEFactura
	If lnAccize>0
		&& BG-20
		oAllowanceCharge = oInvoice.AppendChild(oXML.CreateElement("cac:AllowanceCharge"))
		oAllowanceCharge.AppendChild(oXML.CreateElement("cbc:ChargeIndicator"))
		oAllowanceCharge.LastChild.Text = "true"
		XML_CreateComment("CI-92", oAllowanceCharge.LastChild)
		&& BT-98
		oAllowanceCharge.AppendChild(oXML.CreateElement("cbc:AllowanceChargeReason"))
		oAllowanceCharge.LastChild.Text = "Acciza"
		XML_CreateComment("BT-98", oAllowanceCharge.LastChild)
		&& <cbc:AllowanceChargeReason>Loyal customer</cbc:AllowanceChargeReason><!--BT-97-->
		&& <cbc:MultiplierFactorNumeric>10.00</cbc:MultiplierFactorNumeric><!--BT-94-->
		&& BT-92
		oDocAllowanceCharge = oAllowanceCharge.AppendChild(oXML.CreateElement("cbc:Amount"))
		oDocAllowanceCharge.SetAttribute("currencyID", lcMoneda)
		oDocAllowanceCharge.Text = AllTrim(Str(lnAccize, 15, 2))
		*XML_CreateComment("BT-92", oAllowanceCharge.LastChild)
		oTaxCategoryCharge = oAllowanceCharge.AppendChild(oXML.CreateElement("cac:TaxCategory"))
		&& BT-95
		oTaxCategoryCharge.AppendChild(oXML.CreateElement("cbc:ID"))
		If lnTipTvaCurent<3
			oTaxCategoryCharge.LastChild.Text = "Z"
			XML_CreateComment("BT-95", oTaxCategoryCharge.LastChild)
			&& BT-96
			oTaxCategoryCharge.AppendChild(oXML.CreateElement("cbc:Percent"))
			oTaxCategoryCharge.LastChild.Text = "0"
			XML_CreateComment("BT-96", oTaxCategoryCharge.LastChild)
		Else
			oTaxCategoryCharge.LastChild.Text = "O"
			XML_CreateComment("BT-95", oTaxCategoryCharge.LastChild)
		EndIf
		oTaxSchemeAllowance = oTaxCategoryCharge.AppendChild(oXML.CreateElement("cac:TaxScheme"))
		oTaxSchemeAllowance.AppendChild(oXML.CreateElement("cbc:ID"))
		oTaxSchemeAllowance.LastChild.Text = "VAT"
	EndIf
	If RecCount("crsTva_EFactura")>0
		oTaxTotal		= oInvoice.AppendChild(oXML.CreateElement("cac:TaxTotal"))
		mTvaTotal		= 000000000.00
		mTvaTotalLei	= 000000000.00 
		Select crsTva_EFactura
		Sum Tva, TvaLei  TO mTvaTotal,  mTvaTotalLei
		oTotal = oTaxTotal.AppendChild(oXML.CreateElement("cbc:TaxAmount"))
		&& BT-110 /	BT-111		Valoare totala TVA	/	Moneda
		oTotal.SetAttribute("currencyID", lcMoneda)
		oTotal.Text = AllTrim(Str(mTvaTotal, 15, 2))
		Select crsTva_EFactura
		Set Order To procent
		Locate
		Scan
			&& BG-23(1)		DETALIERE TVA (BG-23)
			oTaxableSubTotal = oTaxTotal.AppendChild(oXML.CreateElement("cac:TaxSubtotal"))
			oSubTotal = oTaxableSubTotal.AppendChild(oXML.CreateElement("cbc:TaxableAmount"))
			&& BT-116		Baza de calcul pentru categoria de TVA
			oSubTotal.SetAttribute("currencyID", lcMoneda)
			oSubTotal.Text = AllTrim(Str(crsTva_EFactura.Valoare, 15, 2))
			oSubTotalTaxa = oTaxableSubTotal.AppendChild(oXML.CreateElement("cbc:TaxAmount"))
			&& BT-117		Valoarea TVA pentru fiecare categorie de TVA 
			oSubTotalTaxa.SetAttribute("currencyID", lcMoneda)
			oSubTotalTaxa.Text = AllTrim(Str(crsTva_EFactura.Tva, 15, 2))
			oTaxCategoryTotals = oTaxableSubTotal.AppendChild(oXML.CreateElement("cac:TaxCategory"))
			&& BT-118		Categoria de TVA 
			oTaxCategoryTotals.AppendChild(oXML.CreateElement("cbc:ID"))
			oTaxCategoryTotals.LastChild.Text = AllTrim(crsTva_EFactura.Tip)
			&& BT-119		Cota TVA
			If  .NOT. InList(crsTva_EFactura.Tip, "O")
				oTaxCategoryTotals.AppendChild(oXML.CreateElement("cbc:Percent"))
				oTaxCategoryTotals.LastChild.Text = AllTrim(Str(crsTva_EFactura.ProcTva, 2, 0))
			EndIf	
			If  .Not. Empty(crsTva_EFactura.Explicatie)
				&& BT-121			Motiv scutire TVA 									NU E OBLIGATORIU
				* etc, https://www.anaf.ro/CompletareFactura/faces/factura/produse.xhtml
				oTaxCategoryTotals.AppendChild(oXML.CreateElement("cbc:TaxExemptionReasonCode"))
				oTaxCategoryTotals.LastChild.Text = AllTrim(crsTva_EFactura.Motiv)
			EndIf
			If  .Not. Empty(crsTva_EFactura.Motiv)
				&& BT-120
				oTaxCategoryTotals.AppendChild(oXML.CreateElement("cbc:TaxExemptionReason"))
				oTaxCategoryTotals.LastChild.Text = AllTrim(crsTva_EFactura.Explicatie)
			EndIf
			oTaxSchemeTotals = oTaxCategoryTotals.AppendChild(oXML.CreateElement("cac:TaxScheme"))
			oTaxSchemeTotals.AppendChild(oXML.CreateElement("cbc:ID"))
			oTaxSchemeTotals.LastChild.Text = "VAT"
		EndScan
		Select crsEFactura
		Locate
		If lcMoneda<>"RON"
			oTaxTotal = oInvoice.AppendChild(oXML.CreateElement("cac:TaxTotal"))		&& ???? TVA-ul trebuie raportat in lei
			&& BT-117
			oTotal = oTaxTotal.AppendChild(oXML.CreateElement("cbc:TaxAmount"))
			oTotal.SetAttribute("currencyID", "RON")
			oTotal.Text = Str(mTvaTotalLei, 15, 2)
		EndIf
	EndIf
	Select crsEFactura
	Locate
	Sum Valoare To lnTotalNet For Indice>=0		&& 05Ianuarie2021
	Locate
	lnTotalNetLiniiFactura = lnTotalNet
	lnTotalNet = lnTotalNet+lnTotalCharges-lnTotalAllowances
	lnTotalBrut = lnTotalNet+lnTotalTva
	&& BG-22
	oMonetaryTotal = oInvoice.AppendChild(oXML.CreateElement("cac:LegalMonetaryTotal"))
	oTotalNet = oMonetaryTotal.AppendChild(oXML.CreateElement("cbc:LineExtensionAmount"))
	&& BT-106
	oTotalNet.SetAttribute("currencyID", lcMoneda)
	oTotalNet.Text = AllTrim(Str(lnTotalNetLiniiFactura, 15, 2))
	oTotalNetFaraTva = oMonetaryTotal.AppendChild(oXML.CreateElement("cbc:TaxExclusiveAmount"))
	&& BT-109		Total baza calcul TVA
	oTotalNetFaraTva.SetAttribute("currencyID", lcMoneda)
	oTotalNetFaraTva.Text = AllTrim(Str(lnTotalNet, 15, 2))
	oTotalBrut = oMonetaryTotal.AppendChild(oXML.CreateElement("cbc:TaxInclusiveAmount"))
	&& BT-112		Valoare totala
	oTotalBrut.SetAttribute("currencyID", lcMoneda)
	oTotalBrut.Text = AllTrim(Str(lnTotalBrut, 15, 2))
	If lnTotalAllowances>0
		oTotalDeduceri = oMonetaryTotal.AppendChild(oXML.CreateElement("cbc:AllowanceTotalAmount"))
		&& BT-107
		oTotalDeduceri.SetAttribute("currencyID", lcMoneda)
		oTotalDeduceri.Text = AllTrim(Str(lnTotalAllowances, 15, 2))
	EndIf
	If lnTotalCharges>0
		oTotalTaxe = oMonetaryTotal.AppendChild(oXML.CreateElement("cbc:ChargeTotalAmount"))
		&& BT-108
		oTotalTaxe.SetAttribute("currencyID", lcMoneda)
		oTotalTaxe.Text = AllTrim(Str(lnTotalCharges, 15, 2))
	EndIf
	If lnTotalBrut >= 0
		lnIncasat = 0
	EndIf	
	If lnIncasat<>0
		oTotalIncasat = oMonetaryTotal.AppendChild(oXML.CreateElement("cbc:PrepaidAmount"))
		&& BT-113
		oTotalIncasat.SetAttribute("currencyID", lcMoneda)
		oTotalIncasat.Text = AllTrim(Str(lnIncasat, 15, 2))
	EndIf
	&& <cbc:PayableRoundingAmount currencyID="RON">0.30</cbc:PayableRoundingAmount><!--BT-114-->
	oTotalPlata = oMonetaryTotal.AppendChild(oXML.CreateElement("cbc:PayableAmount"))
	&& BT-115		Total de plata 
	oTotalPlata.SetAttribute("currencyID", lcMoneda)
	oTotalPlata.Text = AllTrim(Str(lnTotalBrut-lnIncasat, 15, 2))
	* Check_CoduriArticole_ERR()																						&& 12Iunie2023
EndProc
Procedure EFA_GenerareFisierXML_DETALII
	Select crsEFactura
	Count For Indice=0 TO LiniiProduse
	If LiniiProduse=0
		oInvoiceLine = oInvoice.AppendChild(oXML.CreateElement("cac:InvoiceLine"))
	Else
		&& <!--BG-25(1)-->
		Scan For Indice=0
			&& BG-25(1)
			oInvoiceLine = oInvoice.AppendChild(oXML.CreateElement("cac:InvoiceLine"))
			&& BT-126
			oInvoiceLine.AppendChild(oXML.CreateElement("cbc:ID"))
			oInvoiceLine.LastChild.Text = AllTrim(Str(i, 5, 0))
			If  .Not. IsNullOrEmpty(AllTrim(crsEFactura.Text_Supl))
				&& BT-127		Nota liniei facturii
				oInvoiceLine.AppendChild(oXML.CreateElement("cbc:Note"))
				oInvoiceLine.LastChild.Text = SubStr(AllTrim(crsEFactura.Text_Supl), 1, Min(Len(AllTrim(crsEFactura.Text_Supl)), 300))
			EndIf
			If ll_Is_ICAS
				Text To lcSQL NoShow TextMerge
					Select * From UM
				EndText
				mySQLExec(lcSQL, [crsUM]) 
			Else
				If Not File(ExpDir+'UM_EFA.csv')
					Text To lcSQL NoShow TextMerge
"H87","BUC","Bucata",2,1
"KGM","KG","Kilogram",4,0
"LTR","LITRI","Litru",6,0
"MTR","M","Metru",8,0
"GRM","GRAME","Gram",10,0
"XBX","CUTII","Cutie",12,1
"XPK","PAC","Pachet",14,1
"XPO","PUNGI","Punga",15,1
"SET","SET","Set",16,1
"MTK","MP","Metru patrat",18,0
"MTQ","MC","Metru cub",20,0
"MMT","MM","Milimetru",22,0
"CMT","CM","Centimetru",23,0
"TNE","TONE","Tona",24,0
"PR","PER","Pereche",26,1
"XSA","SACI","Sac",28,1
"MLT","ML","Mililitru",30,0
"KWH","KWH","Kilowatt ora",32,0
"HUR","ORE","Ora",34,0
"MIN","MIN","Minut",36,0
"DAY","ZILE","Zi de lucru",38,0
"MON","LUNI","Luni de lucru",39,0
"E27","DOZE","Doza",40,1
"E48","SERV","Unitate de service",44,0
"T3","1000B","O mie de bucati",50,0
"QTR","TRIM","Trimestru",52,1
"P1","PROC","Procent",54,0
"KMT","KM","Kilometru",56,0
"XCR","LADA","Lada",58,0
					EndText
					StrToFile(lcSQL, ExpDir+'UM_EFA.csv')
				EndIf	
				Create Cursor crsUM(Cod C(3), UM C(5), Denumire C(20),	Indice N(3), Indivizib  N(1))				
				Append From (ExpDir+'UM_EFA.csv') Delimited With Char ','
			EndIf
			Select Cod From crsUM Where Um=crsEFactura.Um Into Array aGetUmFact
			mUm = "H87"
			If _Tally>0 .And.  .Not. IsNull(aGetUmFact(1))
				mUm = AllTrim(aGetUmFact(1))
			EndIf
			&& BT-129 /	BT-130			Cantitatea facturata	/	Unitatea de masura
			oUm = oInvoiceLine.AppendChild(oXML.CreateElement("cbc:InvoicedQuantity"))
			oUm.SetAttribute("unitCode", mUm)
			oUm.Text = AllTrim(Str(crsEFactura.Cantitate, 15, 3))
			&& BT-131		Valoarea neta
			oAmount = oInvoiceLine.AppendChild(oXML.CreateElement("cbc:LineExtensionAmount"))
			oAmount.SetAttribute("currencyID", lcMoneda)
			oAmount.Text = AllTrim(Str(crsEFactura.Valoare, 15, 2))
			&& BG-31
			oItem = oInvoiceLine.AppendChild(oXML.CreateElement("cac:Item"))
			If  .Not. Empty(crsEFactura.Is_A)
				&& BT-154		Descrierea articolului
				oItem.AppendChild(oXML.CreateElement("cbc:Description"))
				oItem.LastChild.Text = AllTrim(crsEFactura.Is_A)
			EndIf
			If  .Not. Empty(crsEFactura.Denumire)
				&& BT-153		Numele articolului
				oItem.AppendChild(oXML.CreateElement("cbc:Name"))
				oItem.LastChild.Text = AllTrim(crsEFactura.Denumire)
			Else
				MessageBox("Completati denumirea produselor/serviciilor din factura.", 48, "Date incomplete...",3000)
				Return "Completati denumirea produselor/serviciilor din factura."
				Return
			EndIf
			If  .Not. Empty(crsEFactura.Cod_Art_Cl) And Not tlIsAutoFactura			&& Vicos.12.02.2024
				oBuyerItem = oItem.AppendChild(oXML.CreateElement("cac:BuyersItemIDentification"))
				&& BT-156
				oBuyerItem.AppendChild(oXML.CreateElement("cbc:ID"))
				oBuyerItem.LastChild.Text = crsEFactura.Cod_Art_Cl
			EndIf
			If  .Not. Empty(crsEFactura.Cod)
				oSellerItem = oItem.AppendChild(oXML.CreateElement("cac:SellersItemIdentification"))	&& Posibil COD de BARE
				&& BT-155
				oSellerItem.AppendChild(oXML.CreateElement("cbc:ID"))
				If ll_Is_ICAS
					oSellerItem.LastChild.Text = AllTrim(Str(crsEFactura.Cod))
				Else
					oSellerItem.LastChild.Text = AllTrim(crsEFactura.Cod)
				EndIf
			EndIf
			If ICAS.oSettings.lIsi
				cListIdArticole='0'
				ln_IdDoc_EFactura = crsEFactura.IdDoc
				If lcAlias='IESIRI'
					Text To lcSQL NoShow TextMerge
						Select
							IdArticol
						From IesiriDetaliat
						Where
							IdDoc=?ln_IdDoc_EFactura
							And IsNull(IdArticol, 0)>0
					EndText
				Else
					Text To lcSQL NoShow TextMerge
						Select
							IdArticol
						From ExportDetaliat
						Where
							IdDoc=?ln_IdDoc_EFactura
							And IsNull(IdArticol, 0)>0
					EndText
				EndIf
				mySQLExec(lcSQL, [SQL_IesiriDetaliat])
				Select Distinct IdArticol From SQL_IesiriDetaliat Into Cursor crsGetIDuriArticoleIesiri 	&& ArrayToString(aGetIDuriArticoleIesiri)
				cListIdArticole = '('
				If _Tally>0
					Select crsGetIDuriArticoleIesiri
					Scan
						cListIdArticole = cListIdArticole + AllTrim(Transform(IdArticol))+ICase(RecCount()=RecNo(), '', ', ')
					EndScan
					cListIdArticole = cListIdArticole + ')'	
				Else
					cListIdArticole = cListIdArticole + '9999999999)'	
				EndIf
				Text To lcSQL NoShow TextMerge
					Select
						ID As Cod
						, [Cod_Bare]=Cast(CodBare As Numeric(13, 0))
						, Greutate
						, Space(50) As Text_Supl
						, IsLot As Is_Lot
						, Tva
						, [Cod_NC8]=Articole.NC8
						, [Cod_CPV]=Articole.CPV
					From Articole
					Where
						Id IN <<cListIdArticole>>
				EndText
				mySQLExec(lcSQL, [c_Get_CBare])
				Select c_Get_CBare
				Locate For Cod=crsEFactura.Cod .And. c_Get_CBare.Cod_Bare<>0
				If Found()
					oStandardItem = oItem.AppendChild(oXML.CreateElement("cac:StandardItemIdentification"))
					oIdStandard = oStandardItem.AppendChild(oXML.CreateElement("cbc:ID"))
					&& BT-157 BT-157-1
					oIdStandard.SetAttribute("schemeID", "0160")
					lc_Cod_Bare = AllTrim(Str(c_Get_CBare.Cod_Bare, 13, 0))
					If Len(lc_Cod_Bare)=12
						lc_Cod_Bare = "0"+lc_Cod_Bare
					EndIf	
					oIdStandard.Text = lc_Cod_Bare
				EndIf
				*#-- TODO Loturi
				&& <cac:OriginCountry>
				&& 	<cbc:IdentificationCode>DK</cbc:IdentificationCode><!--BT-159-->
				&& </cac:OriginCountry>
				*	Codurile NC sunt exclusiv pentru B2B;	Pentru B2G se folosesc codurile CPV;	Atât codurile NC cât si cele CPV sunt necesare si obligatorii la produse cu risc fiscal, în rest nu;	 Produse cu risc fiscal OPANAF 12/2022.
				*---------------------------------------
				Select c_Get_CBare
				Locate For Cod=crsEFactura.Cod .And. c_Get_CBare.Cod_Bare<>0
				If Found()
					oClassification = oItem.AppendChild(oXML.CreateElement("cac:CommodityClassification"))
					oClassificationStandardId = oClassification.AppendChild(oXML.CreateElement("cbc:ItemClassificationCode"))
					oClassificationStandardId.SetAttribute("listID", "EN")						&& Coduri de bara		--OPTIONAL
					oClassificationStandardId.Text = AllTrim(Str(c_Get_CBare.Cod_Bare, 13, 0))
				EndIf
				lCladiriNoi = .F.
				Select c_Get_CBare
				Locate For Cod=crsEFactura.Cod .And. !IsNullOrEmpty(c_Get_CBare.Cod_CPV)
				If Found()
					oClassificationCPV = oItem.AppendChild(oXML.CreateElement("cac:CommodityClassification"))
					&& BT-158 BT-158-1 BT-158-2
					oClassificationStandardIdCPV = oClassificationCPV.AppendChild(oXML.CreateElement("cbc:ItemClassificationCode"))
					oClassificationStandardIdCPV.SetAttribute("listID", Iif(c_Get_CBare.Cod_CPV="1111 ", "ZZZ", "STI"))	&& && CPV		B2G
					oClassificationStandardIdCPV.Text = AllTrim(c_Get_CBare.Cod_CPV)
					If c_Get_CBare.Cod_CPV="1111 "
	            		lCladiriNoi = .T.
	            	EndIf	
				EndIf
				Select c_Get_CBare
				Locate For Cod=crsEFactura.Cod .And. !IsNullOrEmpty(c_Get_CBare.Cod_NC8)
				If Found() And ((c_Get_CBare.Cod_NC8<>"1111 ") Or (c_Get_CBare.Cod_NC8="1111 " And Not lCladiriNoi))
					oClassificationNC = oItem.AppendChild(oXML.CreateElement("cac:CommodityClassification"))
					oClassificationStandardIdNC = oClassificationNC.AppendChild(oXML.CreateElement("cbc:ItemClassificationCode"))
					oClassificationStandardIdNC.SetAttribute("listID", Iif(c_Get_CBare.Cod_NC8="1111 ", "ZZZ", "TSP"))	&& NC8 sau	B2B
					oClassificationStandardIdNC.Text = AllTrim(c_Get_CBare.Cod_NC8)
				EndIf
			EndIf
			&& BG-30
			oItemTaxCategory = oItem.AppendChild(oXML.CreateElement("cac:ClassifiedTaxCategory"))
			Select Tip From crsTva_EFactura Where ProcTva=crsEFactura.ProcTva Into Array aGetTipCota
			&& BT-151		Categoria de TVA: S - Cota normala si cota redusa a TVA;	Z - TVA cota zero;	E - Scutire de TVA; AE - TVA cu taxare inversa;	K - TVA pentru livrari intracomunitare;	G - TVA pentru exporturi;	O - Nu face obiectul TVA;	L - Taxele din Insulele Canare;	M - Taxele din Ceuta si Melilla
			oItemTaxCategory.AppendChild(oXML.CreateElement("cbc:ID"))
			oItemTaxCategory.LastChild.Text = AllTrim(aGetTipCota(1))
			&& BT-152		Cota TVA
			If aGetTipCota(1)<>'O'
				oItemTaxCategory.AppendChild(oXML.CreateElement("cbc:Percent"))
				oItemTaxCategory.LastChild.Text = AllTrim(Str(crsEFactura.ProcTva, 2, 0))
			EndIf
			oItemTaxScheme = oItemTaxCategory.AppendChild(oXML.CreateElement("cac:TaxScheme"))
			oItemTaxScheme.AppendChild(oXML.CreateElement("cbc:ID"))
			oItemTaxScheme.LastChild.Text = "VAT"
			*&& BG-29
			oItemPrice = oInvoiceLine.AppendChild(oXML.CreateElement("cac:Price"))
			oItemAmount = oItemPrice.AppendChild(oXML.CreateElement("cbc:PriceAmount"))
			&& BT-146		Pretul net 
			oItemAmount.SetAttribute("currencyID", lcMoneda)
			oItemAmount.Text = AllTrim(Str(crsEFactura.Pret_Vanz, 15, 4))
			i = i+1
		EndScan
	EndIf
EndProc
Procedure EFA_GenerareFisierXML_Validare_DUK
	lcRaspunsDUK = ""
	lcDenumireCompletaFisier=tcCaleFacturi+tcNumeFisier+".xml"
	lcDenFisierRaspuns=tcCaleFacturi+tcNumeFisier+'.txt'
	lcDenFisierRaspunsLOG=tcCaleFacturi+tcNumeFisier+'.log'
	oXML.Save(lcDenumireCompletaFisier)
	lcXml_To_Formated	= FileToStr(lcDenumireCompletaFisier)
	lo_Chilkat_Xml		= CreateObject('Chilkat_9_5_0.Xml')
	lo_Chilkat_Xml.LoadXml(lcXml_To_Formated)
	m.lcStrFormattedXml	= lo_Chilkat_Xml.GetXml()
	Release lo_Chilkat_Xml
	StrToFile(m.lcStrFormattedXml, m.lcDenumireCompletaFisier)
	If File(lcDenFisierRaspuns)
		Delete File (lcDenFisierRaspuns)
	EndIf
	Try
		If File(lcDenFisierRaspunsLOG)
			Delete File (lcDenFisierRaspunsLOG)
		EndIf
	Catch
	EndTry
	If ICAS.oSettings.eFactura_ValidareXMLOnline		&&-- 09Ianuarie2025
		=ValidareXMLOnline(lcDenumireCompletaFisier, 'FACT1', @lcRaspunsDUK)
        IF lcRaspunsDUK<>"ok"
            FOR jj = 1 TO 2
                WAIT WINDOW TIMEOUT 0.5 *jj "Revalidare XML factura: "+ALLTRIM(crsEFactura.NR)
                ValidareXMLOnline(lcDenumireCompletaFisier, 'FACT1', @lcRaspunsDUK)
                lcRaspunsDUK		= InterpretareRaspunsValidatorEfactura(lcRaspunsDUK)
                IF lcRaspunsDUK="ok"
                    EXIT
                ENDIF
            ENDFOR
        ENDIF
		StrToFile(lcRaspunsDUK, lcDenFisierRaspuns)
	Else												&&-- 09Ianuarie2025
	vExt = FindExec('jar')
	&& "C:\Program Files\Java\jdk-11.0.16\bin\javaw.exe" -jar "%1" %*
	If IsNullOrEmpty(vExt) Or Not File(vExt)
		StrToFile(Chr(13)+'-FindExec() a esuat: '+Chr(13)+vExt, ExpDir+'\Log\'+'Java.log',1)
		vExt = Extensie('jar')
	EndIf
	If IsNullOrEmpty(vExt) Or Not File(vExt)
		StrToFile(Chr(13)+'Extensie() a esuat: '+Chr(13)+vExt, ExpDir+'\Log\'+'Java.log',1)
		vExt = ExpDir + '\dist\eFactura\jre8\bin\java.exe'
		If IsNullOrEmpty(vExt) Or Not File(vExt)
			StrToFile(Chr(13)+'-JRE8 folder inexistent: '+Chr(13)+vExt, ExpDir+'\Log\'+'Java.log',1)
		EndIf
	EndIf
	If Len(vExt)=0 .OR.  .NOT. 'java'$Lower(vExt)
		MessageBox(	"Am generat fisierul "+lcDenumireCompletaFisier+". Deoarece aplicatia nu a gasit Java pe calculatorul dvs, va trebui sa-l validati manual in DukIntegrator", 48, "Validati manual xml", 3000)
		Return		"Am generat fisierul "+lcDenumireCompletaFisier+". Deoarece aplicatia nu a gasit Java pe calculatorul dvs, va trebui sa-l validati manual in DukIntegrator"
	EndIf
	vCale = '"'+JUSTPATH(vExt)+'\java.exe"'			&& javaw.exe ???
	oWsShell = CreateObject("WScript.Shell")
	oWsShell.Run(vCale+' -jar "'+Sys(5)+CurDir()+'Dist\EFactura\DUKIntegrator.jar"'	+' -v FACT1 "'+lcDenumireCompletaFisier+'" "'+lcDenFisierRaspuns+'"', 0, .T.)
	Release oWsShell
	EndIf												&&-- 09Ianuarie2025
	If ICAS.cBackEnd='MySQL'
		llNewRecord	= lnIdUnicFactura=0
		cWhere		= ICase(llNewRecord=.F., Conditie_mySQL+" AND Id=?m.DocumentId", '')
	Else
		Store .F.	To llNewRecord	
		Store ''	To cWhere
	EndIf	
	If File(lcDenFisierRaspuns)
		lcRaspunsDUK  = FileToStr(lcDenFisierRaspuns)
		If lcRaspunsDUK ="ok"
			If Used('SEL_EFACTURA')
				*Replace id_solicitare With ln_Index_Incarcare, Data_Liv With ltDateTime In SEL_EFACTURA
				Replace;
						Stare	With 'XML: '+lcRaspunsDUK;
					,	Fisier	With lcDenumireCompletaFisier;
				IN SEL_EFACTURA
			EndIf 
			lc_Field_ID = Iif(ll_Is_ICAS, 'IdUnic', 'Id')
			? "lc_Field_ID ",	Transform(lc_Field_ID)
			If Used(lcAlias) And IsField('BFTiparit', lcAlias)
				Text To lcSQL NoShow TextMerge
					Update;
						<<lcAlias>>;
					Set;
						BFTiparit		= 9;
					Where;
						<<lc_Field_ID>>	= ln_IdUnic_Factura
				EndText
				lOk = ExecScript(lcSQL) 
				If ICAS.cBackEnd='MySQL'
					Salvare_MySQL('Docum', cWhere, llNewRecord)
				Else
					=TableUpdate(.T., .T., lcAlias)
				EndIf
			Else
				Text To lcSQL NoShow TextMerge
					Update
						<<lcAlias>>
					Set
						BFTiparit		= 9
					Where
						<<lc_Field_ID>>	= ?ln_IdUnic_Factura
				EndText
				mySQLExec(lcSQL)
			EndIf
			lUpload_EFA = .T.
			*//////////////////////////////////////////////////////
			If Not IsNullOrEmpty(ICAS.oSettings.eFactura_TokenAcces) And Not ICAS.oSettings.eFactura_Only_XML
				lcErr_SPV = ''
				Try
					oReturn_eFactura_API_Upload=eFactura_API_Upload(lcDenumireCompletaFisier, ICAS.oSettings.eFactura_TokenAcces, ICAS.oSettings.eFactura_Prod, lc_Upload_Param_Extern, .F., AllTrim(ICAS.oSoc.CodFiscal), lc_EFA_TipRaportare)
					If VarType(oReturn_eFactura_API_Upload)<>'O'
                    	Wait WINDOW TIMEOUT 0.5 "Retrimitere factura "+AllTrim(Sel_eFactura.Nr_Iesire)
                    	oReturn_eFactura_API_Upload=eFactura_API_Upload(lcDenumireCompletaFisier, ICAS.oSettings.eFactura_TokenAcces, ICAS.oSettings.eFactura_Prod, lc_Upload_Param_Extern, .F., AllTrim(ICAS.oSoc.CodFiscal), lc_EFA_TipRaportare)
					EndIf
					If VarType(oReturn_eFactura_API_Upload)<>'O'
						MessageBox('Serverul ANAF e-Factura nu functioneaza.',64, 'ANAF is down', 3000)
						lUpload_EFA = .F.
					Else
						lc_Index_Incarcare	= oReturn_eFactura_API_Upload.index_incarcare		&& property INDEX_INCARCARE is not found
						ltDateTime			=;
							DateTime(;
									Val(SubStr(oReturn_eFactura_API_Upload.dateResponse, 1, 4)),;
									Val(SubStr(oReturn_eFactura_API_Upload.dateResponse, 5, 2)),;
									Val(SubStr(oReturn_eFactura_API_Upload.dateResponse, 7, 2)),;
									Val(SubStr(oReturn_eFactura_API_Upload.dateResponse, 9, 2)),;
									Val(SubStr(oReturn_eFactura_API_Upload.dateResponse, 11, 2));
									)					
						lcDateTime=TToC(ltDateTime)
						lcMsg1='Data incarcarii:'+lcDateTime
						lcMsg2='Index incarcare:'+oReturn_eFactura_API_Upload.index_incarcare
						MessageBox(;
							"Factura: "+Chr(13)+lcNumarFactura+" din data de: "+DToC(ldData)+Chr(13)+;
							"este valida si a fost încarcata prin SPV."+Chr(13)+lcMsg1+Chr(13)+lcMsg2, 64, "Validare declaratie";
							, 3000)
						If Used(lcAlias) And IsField('id_solicitare', lcAlias)
							Text To lcSQL NoShow TextMerge
								Update;
									<<lcAlias>>;
								Set;
										id_solicitare		= lc_Index_Incarcare;
									,	efact_DataIncarcare	= ltDateTime;	
								Where;
									<<lc_Field_ID>>			= ln_IdUnic_Factura
							EndText
							lOk = ExecScript(lcSQL)
							If ICAS.cBackEnd='MySQL'
								Salvare_MySQL('Docum', cWhere, llNewRecord)
							Else
								=TableUpdate(.T., .T., lcAlias)
							EndIf
						Else
							Text To lcSQL NoShow TextMerge
								Update
									<<lcAlias>>
								Set
										id_solicitare		= ?lc_Index_Incarcare
									,	efact_DataIncarcare	= ?ltDateTime
								Where
									<<lc_Field_ID>>			= ?ln_IdUnic_Factura
							EndText
							mySQLExec(lcSQL)
						EndIf
						If Used('SEL_EFACTURA')
							Replace;
									id_solicitare	With lc_Index_Incarcare;
								,	Data_Liv		With ltDateTime;
								,	dEF_Upload		With ltDateTime;
								,	Mesaj			With "Factura a fost incarcata cu succes. index_incarcare: "+lc_Index_Incarcare;
								,	Depus			With 1;
								,	Stare			With 'Incarcata';
								,	Preluat			With 0;
							IN SEL_EFACTURA
						EndIf 
					EndIf	
				Catch To loErr
					If VarType(oReturn_eFactura_API_Upload)="O"
						lcXML_SPV_ERR			= oReturn_eFactura_API_Upload.xml
					Else
						lcXML_SPV_ERR			= ''
					EndIf
					llErr_SPV_Mentenanta		= Occurs('Mentenanta sistem', lcXML_SPV_ERR)>0
					lcErr_SPV					= ""
					Do Case
						Case Not Empty(llErr_SPV_Mentenanta)
							lcErr_SPV1		= StrExtract(lcXML_SPV_ERR, '<title>', '</title>')
							lcErr_SPV2		= StrExtract(lcXML_SPV_ERR, '<H3>', '<br>')
							lcErr_SPV_Title	= StrExtract(lcXML_SPV_ERR, '<td align="center" >', '<br />')
							lcErr_SPV		= lcErr_SPV2
						Case "A connection attempt failed because the connected party did not properly respond after a period of time, or established connection failed because connected host has failed to respond." $ m.lcXML_SPV_ERR
							m.lcErr_SPV = "Serverele ANAF nu raspund. Incercati mai tarziu" + Chr(13) + m.lcXML_SPV_ERR
						Case "The remote name could not be resolved: 'api.anaf.ro'"$lcXML_SPV_ERR
							lcErr_SPV = "Conexiunea cu ANAF nu poate fi efectuata."+Chr(13)+"Asigurati-va ca aveti conexiune stabila la internet si ca antivirusul sau alte programe nu blocheaza accesul la site-ul ANAF sau la SPV."
						Case "The remote server returned an error: (502) Bad Gateway."$lcXML_SPV_ERR
							lcErr_SPV = "Serverele ANAF nu raspund. Incercati mai tarziu."
						Case "The remote server returned an error: (500) Internal Server Error." $ m.lcXML_SPV_ERR
							m.lcErr_SPV = "Serverele ANAF nu raspund. Incercati mai tarziu" + Chr(13) + m.lcXML_SPV_ERR
						Case "connection was forcibly closed" $ m.lcXML_SPV_ERR .Or. "failed to respond" $ m.lcXML_SPV_ERR .Or. ("operation " $ m.lcXML_SPV_ERR .And. ("timeout" $ m.lcXML_SPV_ERR .Or. ("timed out" $ m.lcXML_SPV_ERR)))
							m.lcErr_SPV = "Serverele ANAF nu raspund." + Chr(13) + "Incercati mai tarziu." + Chr(13) + m.lcXML_SPV_ERR
					    Case "A aparut o eroare tehnica. Cod: 204" $ m.lcXML_SPV_ERR .OR. "A aparut o eroare tehnica. Cod: 104"  $ m.lcXML_SPV_ERR
				        	m.Raspuns = "Serverele ANAF nu raspund."+CHR(13)+"Incercati mai tarziu."
						Case "Forbidden" $ m.lcXML_SPV_ERR .Or. ("403" $ m.lcXML_SPV_ERR .And. Len(m.lcXML_SPV_ERR < 30))
							m.lcErr_SPV = "Nu aveti drepturi de încarcare pe acest cod fiscal sau tokenul ICAS pentru SPV este expirat. Reinoiti tokenul ICAS sau generati unul nou." + Chr(13) + m.lcXML_SPV_ERR
					    Case "Unauthorized"$lcXML_SPV_ERR AND ["401"]$lcXML_SPV_ERR
				        	lcErr_SPV = "Nu aveti drepturi de încarcare pe acest cod fiscal sau tokenul ICAS pentru SPV este expirat. Reinoiti tokenul ICAS sau generati unul nou."+CHR(13)+lcXML_SPV_ERR
						Case "Nu aveti drept in SPV pentru CIF" $ m.lcXML_SPV_ERR
							m.lcErr_SPV = "Nu aveti acces in SPV acum, pentru acest cod fiscal." + Chr(13) + "Daca inregistrarea in SPV a fost efectuata de curand, incercati mai tarziu sau luati legatura cu ANAF."
						Case "Nu exista niciun CIF petru care sa aveti drept in SPV" $ m.lcXML_SPV_ERR .And.  .Not. m.mIsTransmitere
							m.lcErr_SPV = "OK"
						Case StrTran(m.lcXML_SPV_ERR, " ", "") = "UBLVersionID(1)eroarestructura:ordineincorectaadescendentilor" .And.  .Not. m.mIsTransmitere
							m.lcErr_SPV = "OK"
						Case m.lcXML_SPV_ERR = "F: UBLVersionID (1)  eroare structura: ordine incorecta a descendentilor elementului 'Invoice': elementul 'UBLVersionID'" .Or. "eroare structura: elementul 'CustomizationID'" $ m.lcXML_SPV_ERR .And.  .Not. m.mIsTransmitere
							m.lcErr_SPV = "OK"
						OtherWise
							m.lcErr_SPV = m.lcXML_SPV_ERR
							llErr_errorMessage	= Occurs('errorMessagesistem', lcXML_SPV_ERR)>0
							If llErr_errorMessage
								lcErr_SPV = StrExtract(lcXML_SPV_ERR, '<Errors errorMessage="', '"/>') + Chr(13) + loErr.Message
							EndIf
					EndCase
					MessageBox("Factura: "+Chr(13)+lcNumarFactura+" din data de: "+DToC(ldData)+Chr(13)+;
						"este valida dar NU a reusit încarcarea prin SPV."+Chr(13)+Chr(13)+;
						'Mesaj eroare ANAF:' + Chr(13)+;
						'[ ' + lcErr_SPV + ' ]' + Chr(13)+ Chr(13)+;
						"Poate fi încarcata manual prin SPV, la sectiunea 'Factura electronica' (optiunea de sintaxa XML - UBL).";
						, 64, "Validare declaratie", 3000)
					Set Step On
					lUpload_EFA = .F.
				EndTry
				If Not lUpload_EFA
					Return lcErr_SPV
				EndIf
			Else
				lcReturn=;
					"Factura: "+Chr(13)+lcNumarFactura+" din data de: "+DToC(ldData)+Chr(13)+;
					"este valida."+Chr(13)+Chr(13)+;
					"Fisierul XML pentru e-Factura a fost generat si salvat, dar nu a fost trimis in SPV."+Chr(13)+;
					"Poate fi încarcata prin SPV, la sectiunea 'Factura electronica' (optiunea de sintaxa XML - UBL)."
				If ICAS.oSettings.eFactura_Only_XML
					lcReturn=;
						"Factura: "+Chr(13)+lcNumarFactura+" din data de: "+DToC(ldData)+Chr(13)+;
						"este valida."+Chr(13)+Chr(13)+;
						"Fisierul XML pentru e-Factura a fost generat si salvat, dar nu a fost trimis in SPV,"+Chr(13)+;
						"deoarece a fost bifat flagul [ONLY_XML]."						
					MessageBox(lcReturn, 64, "Validare declaratie")
					oWsShell = CreateObject("WScript.Shell")
					oWsShell.Run(lcDenumireCompletaFisier)
					Release oWsShell
				Else
					MessageBox(lcReturn, 64, "Validare declaratie", Iif(ICAS.oSettings.eFactura_Only_XML, 0, 3000))
				EndIf	
				If Used('SEL_EFACTURA')
					Replace;
							Mesaj	With lcReturn;
						,	Depus	With -1;
						,	Stare	With 'XML: Generat, nedepus in SPV';
					In SEL_EFACTURA
				EndIf 
				Return lcReturn					
			EndIf		If Not IsNullOrEmpty(ICAS.oSettings.eFactura_TokenAcces) And Not ICAS.oSettings.eFactura_Only_XML
			*=SaveIstoricEFactura(lnIdUnicFactura, lcOoperatiune, lcIndexLaTransmitere, lcRecipisaLaTransmitere, "")			
		Else		If lcRaspunsDUK ="ok"
			If IsObject([EFactura_Import])
				If Used('SEL_EFACTURA')
					lcReturn = lcRaspunsDUK
					Replace;
							Mesaj	With lcReturn;
						,	Depus	With -1;
						,	Stare	With 'eroare XML';
					In SEL_EFACTURA
					Return lcReturn	
				EndIf
			Else
				ShowHideScreen(.T.)						&& la EstocFB imi ascunde ecranul
				Modify File (lcDenFisierRaspuns)
				ShowHideScreen(.F.)
			EndIf
		EndIf
	Else
		lcReturn = "Nu s-a creat fisierul de raspuns "+lcDenFisierRaspuns+'.'
		If Used('SEL_EFACTURA')
			Replace;
					Mesaj	With lcReturn;
				,	Depus	With -1;
				,	Stare	With 'eroare XML';
			In SEL_EFACTURA
		EndIf 
		MessageBox(lcReturn, 16, "Eroare", 3000)
		Return lcReturn
	EndIf	
	RETURN "Factura generata corect."
EndProc