******************************************************************************************
*  CLASS: Invoice
*
*  AUTHOR: Refactored OOP Architecture
*
*  DESCRIPTION:
*     Entitate Domain pentru reprezentarea unei facturi.
*     Contine toate datele structurate ale unei facturi.
*
*  DESIGN PATTERN: Domain Entity
*
******************************************************************************************

Define Class Invoice As Custom
	
	*-- Identificare
	nIdUnic = 0
	cNumar = ""
	dData = {}
	dScadent = {}
	
	*-- Tipuri
	cTipFactura = ""
	cInvoiceType = "380"
	lIsRectificativa = .F.
	lIsAutoFactura = .F.
	
	*-- Moneda
	cMoneda = "RON"
	nCurs = 1.0000
	
	*-- Totaluri
	nTotalNet = 0.00
	nTotalTva = 0.00
	nTotalBrut = 0.00
	nTotalCharges = 0.00
	nTotalAllowances = 0.00
	nIncasat = 0.00
	
	*-- Parti
	oSeller = .Null.      && Party - Vanzator
	oBuyer = .Null.       && Party - Cumparator
	
	*-- Linii
	Dimension aLines[1]
	nLineCount = 0
	
	*-- Sumar TVA
	Dimension aTaxSummary[1]
	nTaxCount = 0
	
	*-- Note si referinte
	Dimension aNotes[1]
	nNoteCount = 0
	cContractRef = ""
	cOrderRef = ""
	cProjectRef = ""
	
	*-- Status e-Factura
	cIdSolicitare = ""
	cRecipisa = ""
	dTransmitere = {}
	
	*---------------------------------------------------------------------------
	* Procedura: Init
	* Descriere: Initializeaza factura
	*---------------------------------------------------------------------------
	Procedure Init()
		This.dData = Date()
		This.dScadent = Date()
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: AddLine
	* Descriere: Adauga o linie de factura
	* Parametri: 
	*   toLine - Obiect InvoiceLine
	*---------------------------------------------------------------------------
	Procedure AddLine(toLine)
		This.nLineCount = This.nLineCount + 1
		Dimension This.aLines[This.nLineCount]
		This.aLines[This.nLineCount] = toLine
		
		*-- Recalculeaza totaluri
		This.RecalculateTotals()
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: AddNote
	* Descriere: Adauga o nota
	* Parametri: 
	*   tcNote - Textul notei
	*---------------------------------------------------------------------------
	Procedure AddNote(tcNote)
		If Not Empty(tcNote)
			This.nNoteCount = This.nNoteCount + 1
			Dimension This.aNotes[This.nNoteCount]
			This.aNotes[This.nNoteCount] = tcNote
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: RecalculateTotals
	* Descriere: Recalculeaza totalurile
	*---------------------------------------------------------------------------
	Procedure RecalculateTotals()
		Local i, lnTotalNet, lnTotalTva
		
		lnTotalNet = 0
		lnTotalTva = 0
		
		For i = 1 To This.nLineCount
			If VarType(This.aLines[i]) = 'O'
				lnTotalNet = lnTotalNet + This.aLines[i].nValoare
				lnTotalTva = lnTotalTva + This.aLines[i].nTva
			EndIf
		EndFor
		
		This.nTotalNet = lnTotalNet + This.nTotalCharges - This.nTotalAllowances
		This.nTotalTva = lnTotalTva
		This.nTotalBrut = This.nTotalNet + This.nTotalTva
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: GetLine
	* Descriere: Returneaza o linie dupa index
	* Parametri: 
	*   tnIndex - Indexul liniei (1-based)
	* Returneaza: InvoiceLine sau .Null.
	*---------------------------------------------------------------------------
	Function GetLine(tnIndex)
		If tnIndex > 0 And tnIndex <= This.nLineCount
			Return This.aLines[tnIndex]
		EndIf
		Return .Null.
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetPayableAmount
	* Descriere: Returneaza suma de plata
	* Returneaza: Numeric
	*---------------------------------------------------------------------------
	Function GetPayableAmount()
		Return This.nTotalBrut - This.nIncasat
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: Destroy
	* Descriere: Curata resursele
	*---------------------------------------------------------------------------
	Procedure Destroy()
		This.oSeller = .Null.
		This.oBuyer = .Null.
	EndProc
	
EndDefine
