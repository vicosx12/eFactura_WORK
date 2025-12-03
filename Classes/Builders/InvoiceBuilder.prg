******************************************************************************************
*  CLASS: InvoiceBuilder
*
*  AUTHOR: Refactored OOP Architecture
*
*  DESCRIPTION:
*     Builder pentru construirea obiectelor Invoice.
*     Ofera o interfata fluent pentru crearea facturilor pas cu pas.
*
*  DESIGN PATTERN: Builder Pattern (Fluent Interface)
*
*  USAGE:
*     loInvoice = CreateObject("InvoiceBuilder") ;
*         .WithHeader("F001", Date(), "380") ;
*         .WithSeller(loSeller) ;
*         .WithBuyer(loBuyer) ;
*         .AddLine(loLine1) ;
*         .AddLine(loLine2) ;
*         .Build()
*
******************************************************************************************

Define Class InvoiceBuilder As Custom
	
	*-- Factura in constructie
	oInvoice = .Null.
	
	*-- Flag pentru validare automata
	lAutoValidate = .T.
	
	*-- Colectie de erori de validare
	Dimension aErrors[1]
	nErrorCount = 0
	
	*---------------------------------------------------------------------------
	* Procedura: Init
	* Descriere: Initializeaza builder-ul
	*---------------------------------------------------------------------------
	Procedure Init()
		This.Reset()
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Reset
	* Descriere: Reseteaza builder-ul pentru o noua factura
	*---------------------------------------------------------------------------
	Procedure Reset()
		This.oInvoice = CreateObject("Invoice")
		This.nErrorCount = 0
		Dimension This.aErrors[1]
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: WithHeader
	* Descriere: Seteaza header-ul facturii
	* Parametri: 
	*   tcNumar - Numarul facturii
	*   tdData - Data facturii
	*   tcTip - Tipul facturii (380, 381, 384, 389, 751)
	* Returneaza: InvoiceBuilder (fluent interface)
	*---------------------------------------------------------------------------
	Function WithHeader(tcNumar, tdData, tcTip)
		This.oInvoice.cNumar = tcNumar
		This.oInvoice.dData = tdData
		This.oInvoice.cInvoiceType = Iif(Empty(tcTip), "380", tcTip)
		Return This
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: WithDueDate
	* Descriere: Seteaza data scadentei
	* Parametri: 
	*   tdScadent - Data scadentei
	* Returneaza: InvoiceBuilder (fluent interface)
	*---------------------------------------------------------------------------
	Function WithDueDate(tdScadent)
		This.oInvoice.dScadent = tdScadent
		Return This
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: WithCurrency
	* Descriere: Seteaza moneda si cursul
	* Parametri: 
	*   tcMoneda - Codul monedei
	*   tnCurs - Cursul valutar
	* Returneaza: InvoiceBuilder (fluent interface)
	*---------------------------------------------------------------------------
	Function WithCurrency(tcMoneda, tnCurs)
		This.oInvoice.cMoneda = Iif(Empty(tcMoneda), "RON", tcMoneda)
		This.oInvoice.nCurs = Iif(Empty(tnCurs) Or tnCurs = 0, 1.0000, tnCurs)
		Return This
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: WithSeller
	* Descriere: Seteaza vanzatorul
	* Parametri: 
	*   toSeller - Obiect Party
	* Returneaza: InvoiceBuilder (fluent interface)
	*---------------------------------------------------------------------------
	Function WithSeller(toSeller)
		This.oInvoice.oSeller = toSeller
		Return This
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: WithBuyer
	* Descriere: Seteaza cumparatorul
	* Parametri: 
	*   toBuyer - Obiect Party
	* Returneaza: InvoiceBuilder (fluent interface)
	*---------------------------------------------------------------------------
	Function WithBuyer(toBuyer)
		This.oInvoice.oBuyer = toBuyer
		Return This
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: AsRectificative
	* Descriere: Marcheaza factura ca rectificativa
	* Returneaza: InvoiceBuilder (fluent interface)
	*---------------------------------------------------------------------------
	Function AsRectificative()
		This.oInvoice.lIsRectificativa = .T.
		This.oInvoice.cInvoiceType = "384"
		Return This
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: AsSelfInvoice
	* Descriere: Marcheaza factura ca autofactura
	* Returneaza: InvoiceBuilder (fluent interface)
	*---------------------------------------------------------------------------
	Function AsSelfInvoice()
		This.oInvoice.lIsAutoFactura = .T.
		This.oInvoice.cInvoiceType = "389"
		Return This
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: AddLine
	* Descriere: Adauga o linie de factura
	* Parametri: 
	*   toLine - Obiect InvoiceLine
	* Returneaza: InvoiceBuilder (fluent interface)
	*---------------------------------------------------------------------------
	Function AddLine(toLine)
		This.oInvoice.AddLine(toLine)
		Return This
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: AddSimpleLine
	* Descriere: Adauga o linie simpla
	* Parametri: 
	*   tcDenumire - Denumirea
	*   tnCantitate - Cantitatea
	*   tnPret - Pretul unitar
	*   tnProcTva - Procentul TVA
	* Returneaza: InvoiceBuilder (fluent interface)
	*---------------------------------------------------------------------------
	Function AddSimpleLine(tcDenumire, tnCantitate, tnPret, tnProcTva)
		Local loLine
		
		loLine = CreateObject("InvoiceLine")
		loLine.cDenumire = tcDenumire
		loLine.nCantitate = tnCantitate
		loLine.nPretUnitar = tnPret
		loLine.nProcTva = tnProcTva
		loLine.CalculateValue()
		loLine.CalculateTax()
		
		This.oInvoice.AddLine(loLine)
		Return This
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: AddNote
	* Descriere: Adauga o nota
	* Parametri: 
	*   tcNote - Textul notei
	* Returneaza: InvoiceBuilder (fluent interface)
	*---------------------------------------------------------------------------
	Function AddNote(tcNote)
		This.oInvoice.AddNote(tcNote)
		Return This
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: WithReferences
	* Descriere: Seteaza referintele
	* Parametri: 
	*   tcContract - Referinta contract
	*   tcOrder - Referinta comanda
	*   tcProject - Referinta proiect
	* Returneaza: InvoiceBuilder (fluent interface)
	*---------------------------------------------------------------------------
	Function WithReferences(tcContract, tcOrder, tcProject)
		This.oInvoice.cContractRef = tcContract
		This.oInvoice.cOrderRef = tcOrder
		This.oInvoice.cProjectRef = tcProject
		Return This
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: Build
	* Descriere: Finalizeaza si returneaza factura
	* Returneaza: Invoice
	*---------------------------------------------------------------------------
	Function Build()
		*-- Recalculeaza totalurile
		This.oInvoice.RecalculateTotals()
		
		*-- Valideaza daca e activat
		If This.lAutoValidate
			This.Validate()
		EndIf
		
		Return This.oInvoice
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: Validate
	* Descriere: Valideaza factura construita
	* Returneaza: Logical - .T. daca e valida
	*---------------------------------------------------------------------------
	Function Validate()
		Local llValid
		llValid = .T.
		
		*-- Reseteaza erorile
		This.nErrorCount = 0
		Dimension This.aErrors[1]
		
		*-- Verifica numarul
		If Empty(This.oInvoice.cNumar)
			This.AddError("Numarul facturii este obligatoriu")
			llValid = .F.
		EndIf
		
		*-- Verifica data
		If Empty(This.oInvoice.dData)
			This.AddError("Data facturii este obligatorie")
			llValid = .F.
		EndIf
		
		*-- Verifica vanzatorul
		If IsNull(This.oInvoice.oSeller)
			This.AddError("Vanzatorul este obligatoriu")
			llValid = .F.
		EndIf
		
		*-- Verifica cumparatorul
		If IsNull(This.oInvoice.oBuyer)
			This.AddError("Cumparatorul este obligatoriu")
			llValid = .F.
		EndIf
		
		*-- Verifica liniile
		If This.oInvoice.nLineCount = 0
			This.AddError("Factura trebuie sa aiba cel putin o linie")
			llValid = .F.
		EndIf
		
		Return llValid
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: AddError
	* Descriere: Adauga o eroare de validare
	* Parametri: 
	*   tcError - Mesajul de eroare
	*---------------------------------------------------------------------------
	Protected Procedure AddError(tcError)
		This.nErrorCount = This.nErrorCount + 1
		Dimension This.aErrors[This.nErrorCount]
		This.aErrors[This.nErrorCount] = tcError
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: GetErrors
	* Descriere: Returneaza erorile de validare
	* Returneaza: String
	*---------------------------------------------------------------------------
	Function GetErrors()
		Local i, lcErrors
		lcErrors = ""
		For i = 1 To This.nErrorCount
			lcErrors = lcErrors + This.aErrors[i] + Chr(13)
		EndFor
		Return lcErrors
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: HasErrors
	* Descriere: Verifica daca sunt erori
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Function HasErrors()
		Return This.nErrorCount > 0
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: Destroy
	* Descriere: Curata resursele
	*---------------------------------------------------------------------------
	Procedure Destroy()
		This.oInvoice = .Null.
	EndProc
	
EndDefine
