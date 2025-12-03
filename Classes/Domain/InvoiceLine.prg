******************************************************************************************
*  CLASS: InvoiceLine
*
*  AUTHOR: Refactored OOP Architecture
*
*  DESCRIPTION:
*     Entitate Domain pentru reprezentarea unei linii de factura.
*
*  DESIGN PATTERN: Domain Entity
*
******************************************************************************************

Define Class InvoiceLine As Custom
	
	*-- Identificare
	nIdLinie = 0
	nIdUnic = 0
	
	*-- Produs/Serviciu
	cCod = ""
	cDenumire = ""
	cDescriere = ""
	cCodClient = ""
	cCodBare = ""
	
	*-- Cantitate si UM
	nCantitate = 0.000
	cUm = "BUC"
	cUmCode = "H87"
	
	*-- Preturi si valori
	nPretUnitar = 0.0000
	nValoare = 0.00
	nProcTva = 0
	nTva = 0.00
	nTvaLei = 0.00
	
	*-- Categorii TVA
	cCodTva = ""
	cCategorieTva = "S"
	cMotivScutire = ""
	cExplicatieScutire = ""
	
	*-- Contabilitate
	cCont = ""
	nIndice = 0   && -1 = reducere, 0 = normal
	
	*-- Note
	cNota = ""
	
	*---------------------------------------------------------------------------
	* Procedura: Init
	* Descriere: Initializeaza linia
	*---------------------------------------------------------------------------
	Procedure Init()
		This.nCantitate = 1
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: CalculateValue
	* Descriere: Calculeaza valoarea liniei
	* Returneaza: Numeric
	*---------------------------------------------------------------------------
	Function CalculateValue()
		This.nValoare = Round(This.nCantitate * This.nPretUnitar, 2)
		Return This.nValoare
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: CalculateTax
	* Descriere: Calculeaza TVA-ul liniei
	* Returneaza: Numeric
	*---------------------------------------------------------------------------
	Function CalculateTax()
		This.nTva = Round(This.nValoare * This.nProcTva / 100, 2)
		Return This.nTva
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetTotalWithTax
	* Descriere: Returneaza totalul cu TVA
	* Returneaza: Numeric
	*---------------------------------------------------------------------------
	Function GetTotalWithTax()
		Return This.nValoare + This.nTva
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: IsDiscount
	* Descriere: Verifica daca e linie de reducere
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Function IsDiscount()
		Return This.nIndice = -1 Or This.nValoare < 0
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: IsReverseCharge
	* Descriere: Verifica daca e taxare inversa
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Function IsReverseCharge()
		Return This.cCodTva = '10' Or This.cCategorieTva = 'AE'
	EndFunc
	
EndDefine


******************************************************************************************
*  CLASS: Party
*
*  DESCRIPTION:
*     Entitate pentru reprezentarea unei parti (vanzator/cumparator).
*
******************************************************************************************

Define Class Party As Custom
	
	*-- Identificare
	cDenumire = ""
	cCodFiscal = ""
	cCodReg = ""
	
	*-- Adresa
	cStrada = ""
	cLocalitate = ""
	cJudet = ""
	cSector = ""
	cCodPostal = ""
	cTara = "RO"
	
	*-- Contact
	cTelefon = ""
	cEmail = ""
	cPersoanaContact = ""
	
	*-- Conturi bancare
	cIBAN = ""
	cBanca = ""
	
	*---------------------------------------------------------------------------
	* Functie: GetFormattedAddress
	* Descriere: Returneaza adresa formatata
	* Returneaza: String
	*---------------------------------------------------------------------------
	Function GetFormattedAddress()
		Local lcAddress
		lcAddress = AllTrim(This.cStrada)
		If Not Empty(This.cLocalitate)
			lcAddress = lcAddress + ", " + AllTrim(This.cLocalitate)
		EndIf
		If Not Empty(This.cJudet)
			lcAddress = lcAddress + ", " + AllTrim(This.cJudet)
		EndIf
		Return lcAddress
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetVatId
	* Descriere: Returneaza codul fiscal formatat pentru VAT
	* Returneaza: String
	*---------------------------------------------------------------------------
	Function GetVatId()
		Local lcCF
		lcCF = AllTrim(Upper(This.cCodFiscal))
		If This.cTara = "RO" And Left(lcCF, 2) <> "RO"
			lcCF = "RO" + lcCF
		EndIf
		Return lcCF
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: IsCompany
	* Descriere: Verifica daca e persoana juridica
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Function IsCompany()
		Return Not Empty(This.cCodFiscal) And Len(AllTrim(This.cCodFiscal)) < 13
	EndFunc
	
EndDefine


******************************************************************************************
*  CLASS: TaxSummary
*
*  DESCRIPTION:
*     Entitate pentru sumar TVA pe cota.
*
******************************************************************************************

Define Class TaxSummary As Custom
	
	*-- Cota TVA
	nProcTva = 0
	cCodTva = ""
	
	*-- Categoria
	cCategorie = "S"
	cMotivScutire = ""
	cExplicatie = ""
	
	*-- Valori
	nBazaImpozabila = 0.00
	nValoareTva = 0.00
	nValoareTvaLei = 0.00
	
	*-- Curs
	nCurs = 1.0000
	
	*---------------------------------------------------------------------------
	* Functie: GetCategoryDescription
	* Descriere: Returneaza descrierea categoriei
	* Returneaza: String
	*---------------------------------------------------------------------------
	Function GetCategoryDescription()
		Do Case
			Case This.cCategorie = "S"
				Return "Cota normala/redusa"
			Case This.cCategorie = "Z"
				Return "Cota zero"
			Case This.cCategorie = "E"
				Return "Scutit de TVA"
			Case This.cCategorie = "AE"
				Return "Taxare inversa"
			Case This.cCategorie = "K"
				Return "Livrare intracomunitara"
			Case This.cCategorie = "G"
				Return "Export"
			Case This.cCategorie = "O"
				Return "Nu face obiectul TVA"
			Otherwise
				Return "Necunoscut"
		EndCase
	EndFunc
	
EndDefine
