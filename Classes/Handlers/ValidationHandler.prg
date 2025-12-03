******************************************************************************************
*  CLASS: ValidationHandler
*
*  AUTHOR: Refactored OOP Architecture
*
*  DESCRIPTION:
*     Handler pentru validarea datelor facturii inainte de generarea XML-ului.
*     Verifica campurile obligatorii, formatul datelor, reguli de business, etc.
*
*  DESIGN PATTERN: Chain of Responsibility
*
*  VALIDARI:
*     - Cod fiscal societate
*     - Adresa societate (strada, localitate, judet)
*     - Cod fiscal client
*     - Tip factura valid
*     - Date obligatorii linii factura
*
******************************************************************************************

Define Class ValidationHandler As AbstractHandler
	
	cName = "ValidationHandler"
	nOrder = 1
	
	*-- Flag pentru a permite facturi fara cod fiscal valid (B2C)
	lAllowB2C = .T.
	
	*-- Data de la care se activeaza B2C
	dB2CStartDate = {31.03.2025}
	
	*-- Referinta la ICAS (daca exista)
	lIsICAS = .F.
	oICAS = .Null.
	
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
	* Descriere: Executa validarile
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	*---------------------------------------------------------------------------
	Protected Procedure DoHandle(toContext)
		Local llValid
		
		llValid = .T.
		
		*-- Valideaza parametrii de baza
		llValid = llValid And This.ValidateBasicParams(toContext)
		
		*-- Valideaza datele societatii
		llValid = llValid And This.ValidateCompanyData(toContext)
		
		*-- Valideaza datele clientului
		llValid = llValid And This.ValidateCustomerData(toContext)
		
		*-- Valideaza tipul facturii
		llValid = llValid And This.ValidateInvoiceType(toContext)
		
		*-- Valideaza liniile facturii
		llValid = llValid And This.ValidateInvoiceLines(toContext)
		
		*-- Valideaza cursorul de date
		llValid = llValid And This.ValidateCursor(toContext)
		
		If Not llValid
			This.LogError("Validarea a esuat: " + toContext.cErrorMessage)
		Else
			This.LogInfo("Validarea a trecut cu succes")
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: ValidateBasicParams
	* Descriere: Valideaza parametrii de baza
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Protected Function ValidateBasicParams(toContext)
		Local llValid
		llValid = .T.
		
		*-- Verifica ID factura
		If Empty(toContext.nIdUnicFactura) Or toContext.nIdUnicFactura = 0
			toContext.SetError("Nu ati setat parametrul [tnIdUnicFactura]")
			llValid = .F.
		EndIf
		
		*-- Verifica alias
		If Not InList(toContext.cAlias, "Iesiri", "Export", "Docum")
			toContext.SetError("Variabila [cAlias] nu este setata corect! Valori acceptate: Iesiri, Export, Docum")
			llValid = .F.
		EndIf
		
		Return llValid
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: ValidateCompanyData
	* Descriere: Valideaza datele societatii
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Protected Function ValidateCompanyData(toContext)
		Local llValid, loSoc
		llValid = .T.
		
		If Not This.lIsICAS
			*-- Nu se poate valida fara ICAS
			Return .T.
		EndIf
		
		loSoc = This.oICAS.oSoc
		
		*-- Cod fiscal societate
		If Empty(loSoc.CodFiscal)
			toContext.SetError("Completati codul fiscal al societatii, in ecranul 'Setari => Firme...'.")
			Return .F.
		EndIf
		
		*-- Adresa - Strada
		If Empty(loSoc.Strada)
			toContext.SetError("Completati strada in ecranul 'Configurare societati'.")
			Return .F.
		EndIf
		
		*-- Adresa - Localitate
		If Empty(loSoc.Localitate)
			toContext.SetError("Completati localitatea in ecranul 'Configurare societati'.")
			Return .F.
		EndIf
		
		*-- Adresa - Judet
		If Empty(loSoc.Judet)
			toContext.SetError("Alegeti judetul in ecranul 'Configurare societati'.")
			Return .F.
		EndIf
		
		*-- Sector pentru Bucuresti
		If loSoc.Judet = "BUCURESTI" And Empty(loSoc.Sector)
			toContext.SetError("Completati sectorul in ecranul 'Configurare societati'.")
			Return .F.
		EndIf
		
		Return llValid
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: ValidateCustomerData
	* Descriere: Valideaza datele clientului
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Protected Function ValidateCustomerData(toContext)
		Local llValid, lcCodFiscal, lcTara, ldData
		llValid = .T.
		
		*-- Preia datele din context
		lcCodFiscal = toContext.cCodFiscal
		lcTara = toContext.cTara
		ldData = toContext.dDataFactura
		
		*-- Verifica daca e B2C (dupa 31.03.2025)
		If ldData >= This.dB2CStartDate
			*-- Dupa aceasta data, se permite B2C
			If Empty(lcCodFiscal) Or Not This.VerifCF(lcCodFiscal)
				toContext.cTipRaportare = "B2C"
				This.LogInfo("Factura B2C detectata (fara cod fiscal valid)")
			Else
				toContext.cTipRaportare = "B2B"
			EndIf
		Else
			*-- Inainte de aceasta data, cod fiscal e obligatoriu pentru RO
			If lcTara = "RO"
				If Empty(lcCodFiscal)
					*-- Poate fi B2C daca e permis
					If Not This.lAllowB2C
						toContext.SetError("Codul fiscal al clientului este obligatoriu pentru facturi B2B.")
						Return .F.
					EndIf
				ElseIf Not This.VerifCF(lcCodFiscal)
					toContext.AddWarning("Codul fiscal al clientului nu pare valid: " + lcCodFiscal)
				EndIf
			EndIf
		EndIf
		
		Return llValid
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: ValidateInvoiceType
	* Descriere: Valideaza tipul facturii
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Protected Function ValidateInvoiceType(toContext)
		Local llValid, lcTipFactura
		llValid = .T.
		
		lcTipFactura = toContext.cTipFactura
		
		*-- Tipuri valide de factura pentru e-Factura
		*-- ' ' = Factura normala
		*-- 'f' = Factura pt bonuri fiscale (751)
		*-- 'S' = Scutit cu drept de deducere
		*-- 'D', 'd' = Diverse
		*-- 'U' = Turism
		*-- 'H' = Second-hand
		*-- 'T' = Taxare inversa
		*-- 'n' = Neimpozabile
		
		If Not InList(lcTipFactura, ' ', 'f', 'S', 'D', 'd', 'U', 'H', 'T', 'n')
			toContext.SetError("Pentru acest document nu se genereaza factura electronica. Tip: " + lcTipFactura)
			Return .F.
		EndIf
		
		Return llValid
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: ValidateInvoiceLines
	* Descriere: Valideaza liniile facturii
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Protected Function ValidateInvoiceLines(toContext)
		Local llValid, lnLinii
		llValid = .T.
		
		lnLinii = toContext.nLinii
		
		If lnLinii = 0
			toContext.SetError("Factura nu contine nicio linie.")
			Return .F.
		EndIf
		
		*-- Validarea detaliata a liniilor se face pe cursor
		If Used("crsEFactura")
			Select crsEFactura
			Scan
				*-- Denumire obligatorie
				If Empty(crsEFactura.Denumire)
					toContext.AddWarning("Linia " + Transform(RecNo()) + " nu are denumire completata.")
				EndIf
				
				*-- Cantitate
				If crsEFactura.Cantitate = 0
					toContext.AddWarning("Linia " + Transform(RecNo()) + " are cantitate 0.")
				EndIf
			EndScan
		EndIf
		
		Return llValid
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: ValidateCursor
	* Descriere: Valideaza cursorul de date
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Protected Function ValidateCursor(toContext)
		Local llValid
		llValid = .T.
		
		*-- Verifica daca cursorul exista
		If Not Used("crsEFactura")
			toContext.SetError("Cursorul crsEFactura nu este deschis.")
			Return .F.
		EndIf
		
		*-- Verifica daca are inregistrari
		If RecCount("crsEFactura") = 0
			toContext.SetError("Nu am reusit sa culeg datele pentru generarea XML-ului.")
			Return .F.
		EndIf
		
		*-- Verifica daca factura a fost deja transmisa
		Select crsEFactura
		Go Top
		
		If Not Empty(crsEFactura.Recipisa) And Not toContext.lIsRectificativa
			Local lcTipDoc
			lcTipDoc = Iif(toContext.lIsAutoFactura, "Autofactura", "Factura")
			toContext.SetError(lcTipDoc + " figureaza ca fiind generata si transmisa deja.")
			Return .F.
		EndIf
		
		Return llValid
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: VerifCF
	* Descriere: Verifica validitatea unui cod fiscal
	* Parametri: 
	*   tcCodFiscal - Codul fiscal de verificat
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Protected Function VerifCF(tcCodFiscal)
		Local lcCF, lnLen
		
		lcCF = AllTrim(Upper(StrTran(tcCodFiscal, "RO", "")))
		lcCF = AllTrim(StrTran(lcCF, " ", ""))
		
		*-- Verifica lungimea
		lnLen = Len(lcCF)
		If lnLen < 2 Or lnLen > 10
			Return .F.
		EndIf
		
		*-- Verifica daca e numeric
		If Not This.IsDigit(lcCF)
			Return .F.
		EndIf
		
		*-- Verifica cifra de control (algoritm pentru CUI Romania)
		*-- Simplificat - doar verifica formatul de baza
		Return .T.
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: IsDigit
	* Descriere: Verifica daca un string contine doar cifre
	* Parametri: 
	*   tcString - Stringul de verificat
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Protected Function IsDigit(tcString)
		Local i, lc
		For i = 1 To Len(tcString)
			lc = SubStr(tcString, i, 1)
			If Not Between(Asc(lc), 48, 57)
				Return .F.
			EndIf
		EndFor
		Return .T.
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: Destroy
	* Descriere: Curata resursele
	*---------------------------------------------------------------------------
	Procedure Destroy()
		This.oICAS = .Null.
		DoDefault()
	EndProc
	
EndDefine
