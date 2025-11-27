******************************************************************************************
*  CLASS: TaxCalculationHandler
*
*  AUTHOR: Refactored OOP Architecture
*
*  DESCRIPTION:
*     Handler pentru calculul TVA si verificarea regulilor fiscale.
*     Calculeaza totalurile, identifica taxarea inversa, determina categoriile TVA.
*
*  DESIGN PATTERN: Chain of Responsibility
*
*  CALCULE:
*     - Total net, TVA, brut
*     - Categorii TVA (S, Z, E, AE, K, G, O, L, M)
*     - Detectare taxare inversa
*     - Calcul accize si deduceri
*
******************************************************************************************

Define Class TaxCalculationHandler As AbstractHandler
	
	cName = "TaxCalculationHandler"
	nOrder = 2
	
	*-- Referinta la ICAS (daca exista)
	lIsICAS = .F.
	oICAS = .Null.
	
	*-- Categorii TVA disponibile
	*-- S = Cota normala si cota redusa
	*-- Z = TVA cota zero
	*-- E = Scutire de TVA
	*-- AE = TVA cu taxare inversa
	*-- K = TVA pentru livrari intracomunitare
	*-- G = TVA pentru exporturi
	*-- O = Nu face obiectul TVA
	*-- L = Taxele din Insulele Canare (IGIC)
	*-- M = Taxele din Ceuta si Melilla (IPSI)
	
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
	* Descriere: Executa calculele fiscale
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	*---------------------------------------------------------------------------
	Protected Procedure DoHandle(toContext)
		*-- Creeaza cursorul de TVA
		This.CreateTvaCursor(toContext)
		
		*-- Detecteaza taxarea inversa
		This.DetectReverseCharge(toContext)
		
		*-- Determina categoriile TVA
		This.DetermineTaxCategories(toContext)
		
		*-- Proceseaza accizele
		This.ProcessExcise(toContext)
		
		*-- Calculeaza totalurile
		This.CalculateTotals(toContext)
		
		This.LogInfo("Calcule fiscale finalizate. Total net: " + Transform(toContext.nTotalNet) + ", TVA: " + Transform(toContext.nTotalTva))
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: CreateTvaCursor
	* Descriere: Creeaza cursorul de sumarizare TVA
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	*---------------------------------------------------------------------------
	Protected Procedure CreateTvaCursor(toContext)
		If Not Used("crsEFactura")
			toContext.SetError("Cursorul crsEFactura nu este disponibil pentru calcul TVA.")
			Return
		EndIf
		
		*-- Creeaza cursorul de TVA grupat pe cota
		Select ;
			ProcTva, ;
			Sum(Tva) As Tva, ;
			Sum(TvaLei) As TvaLei, ;
			Sum(Valoare) As Valoare, ;
			'  ' As Tip, ;
			Replicate(' ', 50) As Explicatie, ;
			Replicate(' ', 30) As Motiv, ;
			Curs, ;
			CodTva ;
		From crsEFactura ;
		Group By ProcTva, CodTva, Curs ;
		Into Cursor crsTva_EFactura ReadWrite
		
		*-- Indexeaza pe procent
		Select crsTva_EFactura
		Index On ProcTva Tag Procent
		
		*-- Calculeaza totalul TVA
		Sum Tva To toContext.nTotalTva
		
		This.LogDebug("Cursor TVA creat cu " + Transform(RecCount()) + " inregistrari")
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: DetectReverseCharge
	* Descriere: Detecteaza daca factura este cu taxare inversa
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	*---------------------------------------------------------------------------
	Protected Procedure DetectReverseCharge(toContext)
		Local lnCount
		
		Select Count(*) From crsEFactura Where CodTva = '10' Into Array aGetTaxareInversa
		
		If _Tally > 0 And aGetTaxareInversa > 0
			toContext.lIsTaxareInversa = .T.
			This.LogInfo("Taxare inversa detectata")
		EndIf
		
		*-- Verifica si tipul facturii
		If toContext.cTipFactura = 'T'
			toContext.lIsTaxareInversa = .T.
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: DetermineTaxCategories
	* Descriere: Determina categoriile TVA pentru fiecare linie
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	*---------------------------------------------------------------------------
	Protected Procedure DetermineTaxCategories(toContext)
		Local lcTipFactura, lcTipTert, lcCodFiscal, lnTipTvaCurent
		
		lcTipFactura = toContext.cTipFactura
		lcTipTert = toContext.cTipTert
		lcCodFiscal = toContext.cCodFiscal
		lnTipTvaCurent = toContext.nTipTvaCurent
		
		*-- Verifica daca are facturi cu TVA
		Select Count(*) From crsTva_EFactura Where Tva <> 0 Into Array aGetHasTVA
		toContext.lHasFacturiCuTva = (_Tally > 0 And Not IsNull(aGetHasTVA(1)) And aGetHasTVA(1) > 0)
		
		Select crsTva_EFactura
		Scan
			This.DetermineCategoryForLine(toContext, lcTipFactura, lcTipTert, lcCodFiscal, lnTipTvaCurent)
		EndScan
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: DetermineCategoryForLine
	* Descriere: Determina categoria TVA pentru o linie
	* Parametri: 
	*   toContext - Contextul
	*   tcTipFactura - Tipul facturii
	*   tcTipTert - Tipul tertului
	*   tcCodFiscal - Codul fiscal
	*   tnTipTvaCurent - Modul de plata TVA
	*---------------------------------------------------------------------------
	Protected Procedure DetermineCategoryForLine(toContext, tcTipFactura, tcTipTert, tcCodFiscal, tnTipTvaCurent)
		Local lcTip, lcExplicatie, lcMotiv
		
		Store "" To lcTip, lcExplicatie, lcMotiv
		
		Do Case
			*-- Taxare inversa
			Case toContext.lIsTaxareInversa Or tcTipFactura = 'T' Or ;
				(tcTipTert = 'I' And Not Empty(tcCodFiscal) And Not toContext.lHasFacturiCuTva)
				lcTip = 'AE'
				lcExplicatie = 'Taxare inversa'
				lcMotiv = 'VATEX-EU-AE'
			
			*-- Scutit cu drept de deducere
			Case InList(tcTipFactura, 'S', 'D', 'd')
				lcTip = 'E'
				lcExplicatie = 'Scutit cu drept de deducere'
				lcMotiv = 'VATEX-EU-O'
			
			*-- Factura normala cu TVA 0 pentru platitori
			Case (Empty(tcTipFactura) Or InList(tcTipFactura, 'n')) And crsTva_EFactura.ProcTva = 0
				If tnTipTvaCurent < 3
					lcTip = 'E'
					lcExplicatie = 'Scutit de TVA'
					lcMotiv = 'VATEX-EU-O'
				Else
					lcTip = 'O'
					lcExplicatie = 'Entitatea nu este inregistrata in scopuri de TVA'
					lcMotiv = 'VATEX-EU-O'
				EndIf
			
			*-- Bunuri second-hand
			Case tcTipFactura = 'H'
				lcTip = 'E'
				lcExplicatie = 'Bunuri second-hand'
				lcMotiv = 'VATEX-EU-F'
			
			*-- Regim special turism
			Case tcTipFactura = 'U'
				lcTip = 'E'
				lcExplicatie = 'Regim special agentii de turism'
				lcMotiv = 'VATEX-EU-309'
			
			*-- TVA 0 cu coduri specifice
			Case crsTva_EFactura.ProcTva = 0
				This.DetermineCategoryForZeroVat(tnTipTvaCurent)
				Return
			
			*-- Standard
			Otherwise
				lcTip = 'S'
				lcExplicatie = ''
				lcMotiv = ''
		EndCase
		
		*-- Actualizeaza cursorul
		Replace Tip With lcTip, Explicatie With lcExplicatie, Motiv With lcMotiv In crsTva_EFactura
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: DetermineCategoryForZeroVat
	* Descriere: Determina categoria pentru TVA 0 bazat pe CodTva
	* Parametri: 
	*   tnTipTvaCurent - Modul de plata TVA
	*---------------------------------------------------------------------------
	Protected Procedure DetermineCategoryForZeroVat(tnTipTvaCurent)
		Local lcCodTva, lcTip, lcExplicatie, lcMotiv
		
		lcCodTva = crsTva_EFactura.CodTva
		Store "" To lcTip, lcExplicatie, lcMotiv
		
		If tnTipTvaCurent < 3
			Do Case
				Case lcCodTva = '17'  && Scutit fara drept de deducere
					lcTip = 'E'
					lcExplicatie = 'Scutit fara drept de deducere'
					lcMotiv = 'VATEX-EU-O'
				Case lcCodTva = '16'  && Scutit cu drept de deducere
					lcTip = 'E'
					lcExplicatie = 'Scutit cu drept de deducere'
					lcMotiv = 'VATEX-EU-O'
				Case lcCodTva = '18'  && Neimpozabile
					lcTip = 'O'
					lcExplicatie = 'Entitatea nu este inregistrata in scopuri de TVA'
					lcMotiv = 'VATEX-EU-O'
				Otherwise
					lcTip = 'Z'
					lcExplicatie = ''
					lcMotiv = ''
			EndCase
		Else
			lcTip = 'O'
			lcExplicatie = 'Entitatea nu este inregistrata in scopuri de TVA'
			lcMotiv = 'VATEX-EU-O'
		EndIf
		
		Replace Tip With lcTip, Explicatie With lcExplicatie, Motiv With lcMotiv In crsTva_EFactura
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: ProcessExcise
	* Descriere: Proceseaza accizele
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	*---------------------------------------------------------------------------
	Protected Procedure ProcessExcise(toContext)
		Local lnAccize, lnTipTvaCurent
		
		If Not Used("crsEFactura")
			Return
		EndIf
		
		Select crsEFactura
		Go Top
		
		lnAccize = crsEFactura.Accize
		
		If lnAccize > 0
			toContext.nTotalCharges = toContext.nTotalCharges + lnAccize
			lnTipTvaCurent = toContext.nTipTvaCurent
			
			If lnTipTvaCurent < 3
				Select Count(*) From crsTva_EFactura Where Tip = 'E' Into Array aGetCotaE
				If _Tally > 0 And Not IsNull(aGetCotaE(1)) And aGetCotaE(1) > 0
					Update crsTva_EFactura Set Valoare = Valoare + lnAccize Where Tip = 'E'
				Else
					Insert Into crsTva_EFactura (ProcTva, Tva, Valoare, Tip, Explicatie, Motiv, Curs) ;
						Values (0, 0, lnAccize, 'E', 'Acciza', 'VATEX-EU-O', 1)
				EndIf
			Else
				Select Count(*) From crsTva_EFactura Where Tip = 'O' Into Array aGetCotaO
				If _Tally > 0 And Not IsNull(aGetCotaO(1)) And aGetCotaO(1) > 0
					Update crsTva_EFactura Set Valoare = Valoare + lnAccize Where Tip = 'O'
				Else
					Insert Into crsTva_EFactura (ProcTva, Tva, Valoare, Tip, Explicatie, Motiv, Curs) ;
						Values (0, 0, lnAccize, 'O', 'Acciza', 'VATEX-EU-O', 1)
				EndIf
			EndIf
			
			This.LogDebug("Accize procesate: " + Transform(lnAccize))
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: CalculateTotals
	* Descriere: Calculeaza totalurile facturii
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	*---------------------------------------------------------------------------
	Protected Procedure CalculateTotals(toContext)
		Local lnTotalNet, lnTotalTva, lnTotalBrut
		Local lnLinii, lnLiniiReducere, lnLiniiStornare, lnNrLiniiAvans
		Local lnDiscounturi
		
		If Not Used("crsEFactura")
			Return
		EndIf
		
		Select crsEFactura
		
		*-- Numara liniile
		Count To lnLinii
		Count For Indice = -1 To lnLiniiReducere
		Count For Indice >= 0 And Valoare < 0 To lnLiniiStornare
		Count For Cont = '419' To lnNrLiniiAvans
		
		*-- Calculeaza discounturile
		Sum Abs(Valoare) To lnDiscounturi For Indice = -1
		
		*-- Calculeaza totalul net
		Sum Valoare To lnTotalNet For Indice >= 0
		
		*-- Salveaza in context
		toContext.nLinii = lnLinii
		toContext.nLiniiReducere = lnLiniiReducere
		toContext.nLiniiStornare = lnLiniiStornare
		toContext.nTotalAllowances = toContext.nTotalAllowances + lnDiscounturi
		
		*-- Total net final
		toContext.nTotalNet = lnTotalNet + toContext.nTotalCharges - toContext.nTotalAllowances
		
		*-- Total brut
		toContext.nTotalBrut = toContext.nTotalNet + toContext.nTotalTva
		
		This.LogDebug("Totaluri calculate: Linii=" + Transform(lnLinii) + ;
			", Net=" + Transform(toContext.nTotalNet) + ;
			", TVA=" + Transform(toContext.nTotalTva) + ;
			", Brut=" + Transform(toContext.nTotalBrut))
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: GetTaxCategory
	* Descriere: Returneaza categoria TVA pentru o cota
	* Parametri: 
	*   tnProcTva - Procentul TVA
	* Returneaza: String - Categoria TVA
	*---------------------------------------------------------------------------
	Function GetTaxCategory(tnProcTva)
		Local lcTip
		
		If Not Used("crsTva_EFactura")
			Return "S"
		EndIf
		
		Select Tip From crsTva_EFactura Where ProcTva = tnProcTva Into Array aGetTip
		
		If _Tally > 0 And Not IsNull(aGetTip(1))
			Return AllTrim(aGetTip(1))
		EndIf
		
		Return "S"
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
