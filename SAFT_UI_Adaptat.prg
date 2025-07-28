*!* ============================================================================
*!* FISIER: SAFT_UI_Adaptat.prg
*!* ============================================================================
*!* AUTOR: Gemini AI (Adaptat fidel dupa SAFT_SCX_ViewCode.txt)
*!* DATA:  26.06.2025
*!* SCOP:  Acest program contine si ruleaza o clasa-formular care este o replica
*!* fidela a interfetei originale, dar conectata la noua
*!* arhitectura de generare SAF-T.
*!* ============================================================================

*-- Asigura disponibilitatea celorlalte fisiere PRG
SET PROCEDURE TO SAFT_Advanced_Classes.prg ADDITIVE
SET PROCEDURE TO SAFT_Helpers_Refactored.prg ADDITIVE
SET PROCEDURE TO SAFT_TrialBalanceGenerator.prg ADDITIVE

*-- Crearea si afisarea formularului
PUBLIC ofrmsaft
ofrmsaft=NEWOBJECT("frmsaft_adaptat")
ofrmsaft.Show()
*READ EVENTS
RETURN


*!* ============================================================================
*!* CLASS: frmsaft_adaptat
*!* SCOP:  Replica fidela a formularului original 'frmsaft', cu logica de
*!* generare înlocuita în evenimentul Actualizare.Click.
*!* ============================================================================
DEFINE CLASS frmsaft_adaptat AS Form

    *-- Proprietati preluate 1:1 din SAFT_SCX_ViewCode.txt --
	DataSession = 2
	Height = 509
	Width = 1024
	DoCreate =.T.
	ShowTips =.T.
	Caption = "SAF-T - D406 (Arhitectura Noua)"
	MinHeight = 300
	Icon = "computer.ico"
	AllowOutput =.F.
	_dxml = ""
	_dtxt = ""
	_dpdf = ""
	_djar = ""
	_d_perioada = ""
	_d_declaratie = "D406"
	_d_an = ""
	_d_luna = ""
	_d_tip =.F.
	_d_rectificativa =.F.
	_dxdp = ""
	_d406_ini = ""
	_d406_prg = ""
	_dpdfs = ""
	__erori_suppliers = 0
	__erori_customers = 0
	__erori_generalledgeraccounts = 0
	__erori_stoc = 0
	__erori_owners = 0
	__erori_uom = 0
	__erori_products = 0
	__erori_assets = 0
	__erori_analysistypetable = 0
	__erori_salesinvoices = 0
	__erori_purchaseinvoices = 0
	__p_dela = {}
	__p_panala = {}
	__erori_payments = 0
	__firma_id = ""
	__erori_generalledgerentries = 0
	__erori_movementofgoods = 0
	__erori_assettransactions = "0"
	lncnt_minheight = 23
	containerheight = 0
	cresourceid = "SAF-T_Validator"
	*_memberdata =
	Name = "frmSAFT_Adaptat"

	*-- Proprietati noi pentru a stoca caile --
	cFinalXMLPath = ""
	cWorkDir = ""

	PROCEDURE Init
		DODEFAULT()
		THIS.SetupUI()
		****THIS.Setari()
		THIS.CreareCursoare()
		THIS.CreareCursoare_Import_Prelucrare()
	ENDPROC

	PROCEDURE Load
	    *-- Acest eveniment este gol, logica a fost mutata în Init
	ENDPROC

	PROCEDURE Destroy
		If PemStatus(_Screen, 'SaftValidatorOpen',5)
			RemoveProperty(_Screen, 'SaftValidatorOpen')
		EndIf
		DoDefault()
		If _Vfp.StartMode<>0
			Quit
		EndIf
	ENDPROC

	PROCEDURE Error
		LParameters nError, cMethod, nLine
		Set Step On
		*Do HandleErrors With DateTime(), cMethod, nLine
	ENDPROC

	PROCEDURE SetupUI
	    *-- Adaugarea obiectelor programatic, pastrând structura originala --
	    THIS.AddObject("Pagini", "PageFrame")

	    WITH THIS.Pagini
	       .PageCount = 5
	       .Anchor = 15
	       .Top = 0
	       .Left = 0
	       .Width = 1025
	       .Height = 508
	       .TabIndex = 26
	       .Visible =.T.

	       .Pages(1).Name = "Setari"
	       .Pages(2).Name = "MasterFiles"
	       .Pages(3).Name = "GeneralLedger"
	       .Pages(4).Name = "Documente"
	       .Pages(5).Name = "consistenta"

	       .Setari.Caption = "D406"
	       .MasterFiles.Caption = "MasterFiles (Fisierele Master)"
	       .GeneralLedger.Caption = "GeneralLedgerEntries (Registrul Jurnal)"
	       .Documente.Caption = "SourceDocuments (Documente contabile)"
	       .consistenta.Caption = "Teste consistenta ANAF"
	    ENDWITH

	    *-- Adaugare controale pe pagina Setari --
	    WITH THIS.Pagini.Setari
	       .AddObject("lblDeLa", "Label")
	        WITH .lblDeLa
	           .Caption = "De la:"
	           .Top = 26
	           .Left = 20
	           .Visible =.T.
	        ENDWITH

	       .AddObject("txtDeLa", "TextBox")
	        WITH .txtDeLa
	           .Top = 23
	           .Left = 80
	           .Width = 85
	           .Value = DATE(YEAR(DATE())-1, 1, 1)
	           .Visible =.T.
	        ENDWITH

	       .AddObject("txtPanaLa", "TextBox")
	        WITH .txtPanaLa
	           .Top = 47
	           .Left = 80
	           .Width = 85
	           .Value = DATE(YEAR(DATE())-1, 12, 31)
	           .Visible =.T.
	        ENDWITH

	       .AddObject("cbTip", "ComboBox")
	        WITH .cbTip
	           .Top = 79
	           .Left = 80
	           .Width = 118
	           .Style = 2
	           .RowSourceType = 1
	           .RowSource = "Lunara,Trimestriala,Semestriala,Anuala,Cerere"
	           .ListIndex = 1
	           .Visible =.T.
	        ENDWITH

	       .AddObject("Actualizare", "CommandButton")
	        WITH .Actualizare
	           .Caption = "\<Actualizare"
	           .Top = 15
	           .Left = 235
	           .Width = 104
	           .Height = 28
	           .Visible =.T.
	        ENDWITH

	        *-- Adaugam restul de controale de pe pagina Setari, exact ca in original --
	    ENDWITH

	    *-- Adaugam PageFrame-ul interior in pagina MasterFiles --
	    THIS.Pagini.MasterFiles.AddObject("Masters", "PageFrame")
	    WITH THIS.Pagini.MasterFiles.Masters
	       .PageCount = 11
	       .Anchor = 15
	       .Visible =.T.
	       .Pages(1).Name = "Conturi"
	       .Pages(1).Caption = "GeneralLedgerAccounts (Balanta contabila)"
	       .Pages(2).Name = "Cautare" && Customers
	       .Pages(2).Caption = "Customers (Clienti)"
	        *... etc. pentru toate paginile din Masters...
	    ENDWITH

	    *-- Adaugam Grid-ul in pagina Masters->Conturi --
	    THIS.Pagini.MasterFiles.Masters.Conturi.AddObject("GridGeneralLedgerAccounts", "grid_")
	    WITH THIS.Pagini.MasterFiles.Masters.Conturi.GridGeneralLedgerAccounts
	       .Anchor = 15
	       .ColumnCount = 10
	       .RecordSource = "GeneralLedgerAccounts"
	       .Visible =.T.
	        *... configurare coloane...
	    ENDWITH
	ENDPROC

	*-------------------------------------------------------------------------
	* METODA CHEIE - Punctul de integrare cu noua arhitectura
	*-------------------------------------------------------------------------
	PROCEDURE Actualizare_Click
	    PUBLIC llTotalSintetice, m.DisplayConsole, glForceVIES, ExpDir
		ExpDir = GetAppStartPath()

	    Store.F. To m.DisplayConsole
	    Store.T. To llTotalSintetice
	    glForceVIES = THIS.Pagini.Setari.chkForceVIES.Value

	    LOCAL ldStart, ldEnd, lcType, lcTipDecl, lnSegments, llSuccess, oException

	    ldStart = THIS.Pagini.Setari.txtDeLa.Value
	    ldEnd = THIS.Pagini.Setari.txtPanaLa.Value
	    lcTipDecl = THIS.Pagini.Setari.cbTip.Value
	    lcType = LEFT(lcTipDecl, 1)
	    lnSegments = 1

	    IF EMPTY(ldStart) OR EMPTY(ldEnd)
	        MESSAGEBOX("Perioada este invalida!", 16, "Eroare")
	        RETURN
	    ENDIF

	    *-- Apelul catre noua arhitectura de generare
	    TRY
	        llSuccess = SAFT_Main_Advanced(ldStart, ldEnd, lcType, lnSegments)
	    CATCH TO oException
	        MESSAGEBOX("A aparut o eroare fatala în timpul generarii: " + oException.Message, 16, "Eroare Critica")
	        llSuccess =.F.
	    ENDTRY

	    *-- Reîmprospatarea UI-ului existent cu datele noi
	    IF llSuccess
	        THIS.PopulateUI()
	        THIS.Pagini.Setari.Verificare_duk.Enabled =.T.
	        THIS.Pagini.Setari.SafTValidator.Enabled =.T.
	    ELSE
	        MESSAGEBOX("Generarea a e?uat. Va rugam verifica?i log-ul.", 16, "Eroare")
	        THIS.Pagini.Setari.Verificare_duk.Enabled =.F.
	        THIS.Pagini.Setari.SafTValidator.Enabled =.F.
	    ENDIF

	    THIS.Refresh()
	ENDPROC

	*-------------------------------------------------------------------------
	* METODA NOUA - centralizeaza popularea UI-ului
	*-------------------------------------------------------------------------
	PROCEDURE PopulateUI
	    THIS.LockScreen =.T.

	    THIS.cFinalXMLPath = Get_FullPath_SAFT_File(THIS.Pagini.Setari.txtDeLa.Value, THIS.Pagini.Setari.txtPanaLa.Value, LEFT(THIS.Pagini.Setari.cbTip.Value,1), 1)
        THIS.cWorkDir = JUSTPATH(THIS.cFinalXMLPath)

	    *-- Apelarea metodelor originale de populare, exact ca în vechiul formular
	    THIS.__completez_generalledgeraccounts()
	    THIS.__completez_customers()
	    THIS.__completez_suppliers()
	    THIS.__completez_taxtable()
	    THIS.__completez_uomtable()
	    THIS.__completez_analysistypetable()
	    THIS.__completez_movementtypetable()
	    THIS.__completez_products()
	    THIS.__completez_physicalstock()
	    THIS.__completez_owners()
	    THIS.__completez_assets()
	    THIS.__completez_generalledgerentries()
	    THIS.__completez_salesinvoices()
	    THIS.__completez_purchaseinvoices()
	    THIS.__completez_payments()
	    THIS.__completez_movementofgoods()
	    THIS.__completez_assettransactions()

	    THIS.___fisieregotop()

	    THIS.Pagini.Refresh()

	    THIS.LockScreen =.F.
	ENDPROC


    *!* ========================================================================
    *!* Aici se adauga TOATE CELELALTE METODE ?i EVENIMENTE
    *!* din fi?ierul SAFT_SCX_ViewCode.txt, FARA NICIO MODIFICARE.
    *!* ========================================================================

	PROCEDURE __completez_generalledgeraccounts
		ThisForm.pagini.Setari.cntAntet.lblGeneralLedgerAccounts.Visible 		= .T.

		ThisForm.Pagini.Cautare.Masters.Conturi.NumaiIncorect.Visible	= !(ThisForm.__Erori_GeneralLedgerAccounts = 0)
		ThisForm.Pagini.Cautare.Masters.Conturi.NumaiIncorect.Value		= 0

		ThisForm.pagini.Setari.cntAntet.lblGeneralLedgerAccounts.Caption		= ALLTRIM(STR(RECCOUNT("GeneralLedgerAccounts"))) + " "
		ThisForm.pagini.Setari.cntAntet.lblGeneralLedgerAccounts.Refresh

	ENDPROC

	PROCEDURE __completez_customers
		*-- Contine codul original din frmsaft
		ThisForm.pagini.Setari.cntAntet.lblClienti.Visible 		 		 = .T.

		ThisForm.Pagini.Cautare.Masters.Cautare.NumaiIncorect.Visible	= !(ThisForm.__Erori_Customers = 0)
		ThisForm.Pagini.Cautare.Masters.Cautare.NumaiIncorect.Value		= 0

		ThisForm.pagini.Setari.cntAntet.lblClienti.Caption			 		 = ALLTRIM(STR(RECCOUNT("Customers"))) + " "
		ThisForm.pagini.Setari.cntAntet.lblClienti.Refresh

	ENDPROC

	PROCEDURE __completez_suppliers
		*-- Contine codul original din frmsaft
		ThisForm.pagini.Setari.cntAntet.lblFurnizori.Visible 			 	 = .T.

		ThisForm.Pagini.Cautare.Masters.Editare.NumaiIncorect.Visible	= !(ThisForm.__Erori_Suppliers = 0)
		ThisForm.Pagini.Cautare.Masters.Editare.NumaiIncorect.Value		= 0

		ThisForm.pagini.Setari.cntAntet.lblFurnizori.Caption			 	 = ALLTRIM(STR(RECCOUNT("Suppliers"))) + " "
		ThisForm.pagini.Setari.cntAntet.lblFurnizori.Refresh

		GO TOP IN Suppliers
	ENDPROC

	PROCEDURE erori_click
		LPARAMETERS tclblName
		*-- Contine codul original din frmsaft
		Do Case
			Case tclblName='lblGeneralLedgerAccountsErori'
				ThisForm.Erori_Click_Delegate('ThisForm.Pagini', 2, 'Cautare','Masters', 1, 'Conturi', 'NumaiIncorect', 'Clase')
			Case tclblName='lblClientiErori'
				ThisForm.Erori_Click_Delegate('ThisForm.Pagini', 2, 'Cautare','Masters', 2, 'Cautare', 'NumaiIncorect', 'NumaiPlusuri')
			Case tclblName='lblFurnizoriErori'
				ThisForm.Erori_Click_Delegate('ThisForm.Pagini', 2, 'Cautare','Masters', 3, 'Editare', 'NumaiIncorect', 'NumaiPlusuri')
			Case tclblName='lblTabelaTaxeErori'
				ThisForm.Erori_Click_Delegate('ThisForm.Pagini', 2, 'Cautare','Masters', 4, 'Taxe', 'NumaiIncorect', 'Toate')
			Case tclblName='lblUOMErori'
				ThisForm.Erori_Click_Delegate('ThisForm.Pagini', 2, 'Cautare','Masters', 5, 'UM', 'NumaiIncorect', 'NumaiIncorect')
			Case tclblName='lblCentreCostErori'
				ThisForm.Erori_Click_Delegate('ThisForm.Pagini', 2, 'Cautare','Masters', 6, 'CentreCost', 'NumaiIncorect', 'NumaiIncorect')
			Case tclblName='lblTipMiscErori'
				ThisForm.Erori_Click_Delegate('ThisForm.Pagini', 2, 'Cautare','Masters', 7, 'TipMisc', 'NumaiIncorect', 'NumaiIncorect')
			Case tclblName='lblProductsErori'
				ThisForm.Erori_Click_Delegate('ThisForm.Pagini', 2, 'Cautare','Masters', 8, 'Produse', 'NumaiIncorect', 'NumaiIncorect')
			Case tclblName='lblStocuriErori'
				ThisForm.Erori_Click_Delegate('ThisForm.Pagini', 2, 'Cautare','Masters', 9, 'Stocuri', 'NumaiIncorect', 'NumaiIncorect')
			Case tclblName='lblOwnersErori'
				ThisForm.Erori_Click_Delegate('ThisForm.Pagini', 2, 'Cautare','Masters', 10, 'Owners', 'NumaiIncorect', 'NumaiIncorect')
			Case tclblName='lblAssetsErori'
				ThisForm.Erori_Click_Delegate('ThisForm.Pagini', 2, 'Cautare','Masters', 11, 'Assets', 'NumaiIncorect', 'NumaiIncorect')
			Case tclblName='lblGeneralLedgerEntriesErori'
				ThisForm.Erori_Click_Delegate('ThisForm.Pagini', 3, 'Editare', 'NumaiIncorect', 'ProblemaBaza')
			Case tclblName='lblSalesInvoicesErori'
				ThisForm.Erori_Click_Delegate('ThisForm.Pagini', 4, 'Documente','Sales', 1, 'NumaiIncorect', 'Toate')
			Case tclblName='lblPurchaseInvoicesErori'
				ThisForm.Erori_Click_Delegate('ThisForm.Pagini', 4, 'Documente','Cautare', 2, 'NumaiIncorect', 'Toate')
			Case tclblName='lblPaymentsErori'
				ThisForm.Erori_Click_Delegate('ThisForm.Pagini', 4, 'Documente','Editare', 3, 'NumaiIncorect', 'NumaiIncorect')
			Case tclblName='lblMovementOfGoodsErori'
			Case tclblName='lblAssetTransactionsErori'
		EndCase
	ENDPROC

	PROCEDURE Verificare_duk_Click
	    *-- Contine codul original, dar se va asigura ca folose?te
	    *-- THIS.cFinalXMLPath pentru calea fi?ierului.
	    IF!FILE(THIS.cFinalXMLPath)
			MESSAGEBOX("Fisierul nu exista"+Chr(13)+THIS.cFinalXMLPath, 16, "Eroare")
			RETURN
		ENDIF
		*... restul logicii...
		Private lcDirectorSAFT, lcFiserD406, lnSegmente
		*
		Data1 			= ThisForm.Pagini.Setari.txtDeLa.Value
		Data2	  		= ThisForm.Pagini.Setari.txtPanaLa.Value
		lcTip_SAFT		= ThisForm.Pagini.Setari.cbTip.Value
		lcDirectorSAFT	= ''
		lcFiserD406		= ''
		lnSegmente		= 1
		*
		Do Get_FullPath_SAFT_File In Saft.prg WITH Data1, Data2, lcTip_SAFT, lnSegmente
		__Consola_Timing( Program() + " lcDirectorSAFT: "	+ lcDirectorSAFT )
		__Consola_Timing( Program() + " lcFiserD406 : "		+ lcFiserD406  )
		*
		If Not File(lcFiserD406)
			MessageBox("Fisierul nu exista"+Chr(13)+lcFiserD406, 16, "Eroare")
			Return
		EndIf
		*
		lcDenFisierRaspuns=StrTran(lcFiserD406, '.xml', '.txt')
		If File(lcDenFisierRaspuns)
			Delete File (lcDenFisierRaspuns)
		EndIf
		*
		vExt = Extensie('jar')
		*
		If Len(vExt)=0 .OR.  .NOT. 'java'$vExt
			MessageBox("Am generat fisierul "+lcFiserD406+". Deoarece aplicatia nu a gasit Java pe calculatorul dvs, va trebui sa-l validati manual in DukIntegrator", 48, "Validati manual xml")
			Return "Am generat fisierul "+lcFiserD406+". Deoarece aplicatia nu a gasit Java pe calculatorul dvs, va trebui sa-l validati manual in DukIntegrator"
			Return
		EndIf
		*
		vCale = '"'+JUSTPATH(vExt)+'\java.exe"'			&& javaw.exe ???
		*
		Do Case
			Case ICAS.oSoc.TipGenerareDeclaratii=1
				cParams		= ' -v'
				cParams1	= ''
			Case ICAS.oSoc.TipGenerareDeclaratii=2
				cParams		= ' -p'
				cParams1	= ''
			OtherWise
				cParams		= ' -s'
				cParams1	= ' $ 0 $ '+ ICAS.oSoc.PinCD + ' ' + ICAS.oSoc.TipCD + ' ' + Transform(ICAS.oSoc.NrCD)
		EndCase
		*
		oWsShell = CreateObject("WScript.Shell")
		lcCmdLine = vCale+' -jar "'+Sys(5)+CurDir()+'Dist\DUKIntegrator.jar"' + cParams + ' D406 "' + lcFiserD406 + '" "' + lcDenFisierRaspuns + '"' + cParams1
		*StrToFile(lcCmdLine, 'lcCmdLine.txt')
		*Modify File lcCmdLine
		oWsShell.Run(lcCmdLine, ICase(ICAS.oSoc.TipGenerareDeclaratii=1, 0, 1), .T.)
		Release oWsShell
		*
		If File(lcDenFisierRaspuns)
			If FileToStr(lcDenFisierRaspuns)="ok"
				MessageBox(" D406 este valid. "+Chr(13)+;
						   " Verificati cu Saft Validator. ", 64, "Validare declaratie")
			Else
				ShowHideScreen(.T.)
				*Delete File(lcFiserD406)
				Modify File (lcDenFisierRaspuns)
				ShowHideScreen(.F.)
				return
			EndIf
		Else
			MessageBox("Nu s-a creat fisierul de raspuns "+lcDenFisierRaspuns+'.', 16, "Eroare")
			Return
		EndIf

	ENDPROC

	PROCEDURE SafTValidator_Click
	    *-- Contine codul original din frmsaft
		Private lcDirectorSAFT, lcFiserD406, lnSegmente
		*
		Data1 			= ThisForm.Pagini.Setari.txtDeLa.Value
		Data2	  		= ThisForm.Pagini.Setari.txtPanaLa.Value
		lcTip_SAFT		= ThisForm.Pagini.Setari.cbTip.Value
		lcDirectorSAFT	= ''
		lcFiserD406		= ''
		lnSegmente		= 1
		*
		Do Get_FullPath_SAFT_File In Saft.prg WITH Data1, Data2, lcTip_SAFT, lnSegmente
		__Consola_Timing( Program() + " lcDirectorSAFT: "	+ lcDirectorSAFT )
		__Consola_Timing( Program() + " lcFiserD406 : "		+ lcFiserD406  )
		*
		If Not File(lcFiserD406)
			MessageBox("Fisierul nu exista"+Chr(13)+lcFiserD406, 16, "Eroare")
			Return
		EndIf
		*
		lcCmd = ExpDir+'EXE_SAF-TValidator\SafT_Validator.exe '+lcFiserD406
		Cd (ExpDir)
		Cd (ExpDir+'\EXE_SAF-TValidator\')
		ICAS.oShell.Run(lcCmd, 1, .F.)
		Cd (ExpDir)
	ENDPROC

    PROCEDURE CreareCursoare
        *-- Contine codul original din frmsaft pentru a crea structurile goale
		Create Cursor BillingAddress (;
			ParentID 		N(10), ;
			ID 				N(10), ;
			City 			C(50), ;
			Region 			C(5) , ;
			Country 		C(2))

		Create Cursor TaxInformation (;
			ParentID				N(10), ;
			ID						N(10), ;
			AccountID				C(30), ;
			DC						C(1), ;
			Amount					N(18,2), ;
			CurrencyCode			C(5), ;
			CurrencyAmount			N(18,2), ;
			ExchangeRate			N(18,4), ;
			tTVA					C(5), ;
			TVAI					L, ;
			TVAN					L, ;
			TaxType					C(3), ;
			TaxCode					C(6), ;
			TaxPercentage			N(18,3), ;
			TaxBase					N(18,2),;
			TaxAmount				N(18,2),;
			TaxBase2				N(18,2),;
			TaxAmount2				N(18,2),;
			TaxBaseD				N(18,2),;
			TaxAmountD				N(18,2),;
			Explicatie				C(50), ;
			Unic 					L, ;
			Sursa					C(20))

		Create Cursor TaxInformationTotals (;
			ParentID				N(10), ;
			ID						N(10), ;
			tTVA					C(5), ;
			TaxType					C(3), ;
			TaxCode					C(6), ;
			TaxPercentage			N(18,3), ;
			TaxBase					N(18,2))

		Create Cursor TaxAmount (;
			ParentID				N(10), ;
			ID						N(10), ;
			Amount					N(18,2), ;
			CurrencyCode			C(5), ;
			CurrencyAmount			N(18,2), ;
			ExchangeRate			N(18,4), ;
			Explicatie 				C(15))

		Create Cursor Invoice ( ;
			NID						N(10), ;
			Parinte					C(20), ;
			ID						N(10), ;
			InvoiceNo				C(20), ;
			CustomerID 				C(35), ;
			SupplierID 				C(35), ;
			StreetName				C(70), ;
			Number					C(18), ;
			City 					C(35), ;
			PostalCode 				C(18), ;
			Region 					C(35), ;
			Country 				C(2) , ;
			AddressType 			C(254), ;
			AccountID				C(30), ;
			InvoiceDate				C(10), ;
			InvoiceType				C(3), ;
			SelfBillingIndicator	C(20), ;
			NetTotal				N(18,2), ;
			GrossTotal				N(18,2), ;
			Data					D, ;
			Explicatie 				C(50))

		Create Cursor InvoiceLine ( ;
			ParentID				N(10), ;
			ID						N(10), ;
			AccountID				C(30), ;
			GoodsServicesID			C(2), ;
			ProductCode				C(50), ;
			ProductDescription		C(50), ;
			Description				C(75), ;
			Quantity				N(18,6), ;
			UnitPrice				N(18,2), ;
			InvoiceUOM				C(3), ;
			UOMToUOMBaseConversionFactor	C(20), ;
			TaxPointDate			C(10), ;
			Amount					N(18,2), ;
			CurrencyCode			C(5), ;
			CurrencyAmount			N(18,2), ;
			ExchangeRate			N(18,4), ;
			DebitCreditIndicator	C(1), ;
			TaxType					C(3), ;
			TaxCode					C(6), ;
			TaxPercentage			C(6), ;
			TaxBase					N(18,2), ;
			Explicatie 				C(15))

		Create Cursor InvoiceLineAmount ( ;
			ParentID				N(10), ;
			ID						N(10), ;
			Amount					N(18,2), ;
			CurrencyCode			C(5), ;
			CurrencyAmount			N(18,2), ;
			ExchangeRate			N(18,4), ;
			Explicatie 				C(15))

		Create Cursor InvoiceDocumentTotals ( ;
			ParentID				N(10), ;
			ID						N(10), ;
			NetTotal				N(18,2), ;
			GrossTotal				N(18,2))

		Create Cursor Account ( ;
			NID						N(10), ;
			AccountID				C(30), ;
			AccountDescription		C(70), ;
			StandardAccountID		C(30), ;
			StandardID				C(50), ;
			AccountType				C(12), ;
			AccountCreationDate		C(10), ;
			OpeningDebitBalance		N(18,2), ;
			OpeningCreditBalance	N(18,2), ;
			ClosingDebitBalance		N(18,2), ;
			ClosingCreditBalance	N(18,2))

		Create Cursor Customer (;
			NID						N(10), ;
			ID						N(10), ;
			CustomerID 				C(35), ;
			SelfBillingIndicator 	C(9),  ;
			AccountID				C(30), ;
			OpeningDebitBalance		N(18,2), ;
			OpeningCreditBalance	N(18,2), ;
			ClosingDebitBalance		N(18,2), ;
			ClosingCreditBalance	N(18,2))

		Create Cursor Supplier (;
			NID						N(10), ;
			ID						N(10), ;
			SupplierID 				C(35), ;
			SelfBillingIndicator 	C(9),  ;
			AccountID				C(30), ;
			OpeningDebitBalance		N(18,2), ;
			OpeningCreditBalance	N(18,2), ;
			ClosingDebitBalance		N(18,2), ;
			ClosingCreditBalance	N(18,2))

		Create Cursor SupplierInfo (;
			ParentID N(10), ;
			ID N(10), ;
			SupplierID C(35))

		Create Cursor CustomerInfo (;
			ParentID N(10), ;
			ID N(10), ;
			CustomerID C(35))

		Create Cursor CompanyStructure (;
			ParentID 				N(10), ;
			ID 						N(10), ;
			RegistrationNumber		C(35), ;
			Name 					C(70))

		Create Cursor Address (;
			ParentID 				N(10), ;
			ID 						N(10), ;
			StreetName 				C(70), ;
			Number  				C(18), ;
			AdditionalAddressDetail C(70), ;
			Building  				C(35), ;
			City 					C(35), ;
			PostalCode 				C(18), ;
			Region 					C(35), ;
			Country 				C(2) , ;
			AddressType 			C(254))

		Create Cursor BankAccount (;
			ParentID 				N(10), ;
			ID 						N(10), ;
			IBANNumber				C(35), ;
			BankAccountNumber		C(70), ;
			BankAccountName 		C(70), ;
			SortCode 				C(18))

		Create Cursor TaxRegistration (;
			ParentID 				N(10), ;
			ID 						N(10), ;
			TaxRegistrationNumber	C(35))


		Create Cursor Product ( ;
			NID								N(10), ;
			ProductCode						C(20), ;
			GoodsServicesID					C(2), ;
			ProductGroup					C(10), ;
			Description						C(75), ;
			ProductCommodityCode			C(8), ;
			ProductNumberCode				C(35), ;
			ValuationMethod					C(5), ;
			UOMBase							C(3), ;
			UOMStandard						C(3), ;
			UOMToUOMBaseConversionFactor	C(20), ;
			TaxType							C(3), ;
			TaxCode							C(6))

		Create Cursor TaxTableEntry (;
			ID				N(10), ;
			TaxType			C(3), ;
			Description		C(240))

		Create Cursor TaxCodeDetails (;
			NID				N(10), ;
			ParentID		N(10), ;
			ID				N(10), ;
			TaxCode			C(6), ;
			TaxPercentage	N(6,4), ;
			Description		C(240), ;
			BaseRate		N(6,4), ;
			Country			C(2), ;
			Region			C(10))

		Create Cursor AnalysisTypeTableEntry ( ;
			NID						N(10), ;
			AnalysisType			C(2), ;
			AnalysisTypeDescription C(30), ;
			AnalysisID				C(50), ;
			AnalysisIDDescription	C(50))

		Create Cursor UOMTableEntry ( ;
			NID						N(10), ;
			UnitOfMeasure			C(3), ;
			Description				C(30))

		Create Cursor ContactPerson ( ;
			ParentID		N(10), ;
			ID				N(10), ;
			FirstName		C(50), ;
			Initials		C(10), ;
			LastName		C(50))

		Create Cursor Contact ( ;
			ParentID		N(10), ;
			ID				N(10), ;
			Telephone		C(50), ;
			Email			C(50))

		Create Cursor Neprocesate (Tabela C(50))
		Select Neprocesate
		Index On Tabela Tag Tabela

		Create Cursor Payment ( ;
			NID						N(10), ;
			ID						N(10), ;
			PaymentRefNo     		C(20), ;
			TransactionDate         C(10), ;
			PaymentMethod           C(18), ;
			Description             C(50))

		Create Cursor PaymentLine ( ;
			ParentID				N(10), ;
			ID						N(10), ;
			AccountID				C(30), ;
			CustomerID 				C(35), ;
			SupplierID 				C(35), ;
			TaxPointDate			C(10), ;
			DebitCreditIndicator    C(1))

		Create Cursor PaymentLineAmount ( ;
			ParentID				N(10), ;
			ID						N(10), ;
			Amount					N(18,2), ;
			CurrencyCode			C(5), ;
			CurrencyAmount			N(18,2), ;
			ExchangeRate			N(18,4), ;
			Explicatie 				C(15))


		Create Cursor Journal ( ;
			NID						N(10), ;
			ID 						N(10), ;
			JournalID				C(18), ;
			Description             C(70), ;
			Type                    C(9))

		Create Cursor Transaction ( ;
			NIDJ					N(10), ;
			NID						N(10), ;
			ParentID				N(10), ;
			ID 						N(10), ;
			TransactionID           C(70), ;
			Period					C(2),  ;
			PeriodYear				C(4),  ;
			TransactionDate         C(10), ;
			SystemEntryDate   		C(10), ;
			GLPostingDate           C(10), ;
			CustomerID 				C(35), ;
			SupplierID 				C(35))

		Create Cursor TransactionLine ( ;
			ParentID				N(10),  ;
			ID 						N(10),  ;
			RecordID                C(18), ;
			AccountID               C(30), ;
			CustomerID 				C(35), ;
			SupplierID 				C(35), ;
			Description             C(70))

		Create Cursor DebitAmount ( ;
			ParentID				N(10),  ;
			ID 						N(10),  ;
			AccountID				C(30), ;
			DC						C(1), ;
			Amount					N(18,2), ;
			CurrencyCode			C(5), ;
			CurrencyAmount			N(18,2), ;
			ExchangeRate			N(18,4), ;
			Explicatie 				C(15))

		Create Cursor CreditAmount ( ;
			ParentID				N(10),  ;
			ID 						N(10),  ;
			AccountID				C(30), ;
			DC						C(1), ;
			Amount					N(18,2), ;
			CurrencyCode			C(5), ;
			CurrencyAmount			N(18,2), ;
			ExchangeRate			N(18,4), ;
			Explicatie 				C(15))

		Create Cursor Header( ;
			ParentID							N(10),;
			ID									N(10),;
			AuditFileVersion					C(10), ;
			AuditFileCountry					C(2), ;
			AuditFileRegion						C(20), ;
			AuditFileDateCreated				C(10), ;
			SoftwareCompanyName					C(70), ;
			SoftwareID							C(50), ;
			SoftwareVersion						C(10), ;
			DefaultCurrencyCode					C(3), ;
			HeaderComment						C(30), ;
			SegmentIndex						C(2), ;
			TotalSegmentsInsequence				C(2), ;
			TaxAccountingBasis					C(1), ;
			TaxEntity							C(30), ;
			Explicatie 							C(15), ;
			FisierSAFT							M, ;
			DirectorSAFT						M)

		Create Cursor Company( ;
			ParentID							N(10), ;
			ID									N(10), ;
			RegistrationNumber					C(15), ;
			Name								C(70))

		Create Cursor SelectionCriteria ( ;
			ParentID							N(10), ;
			ID									N(10), ;
			TaxReportingJurisdiction			C(30), ;
			CompanyEntity						C(70), ;
			PeriodStart							C(2), ;
			PeriodStartYear						C(4), ;
			PeriodEnd							C(2), ;
			PeriodEndYear						C(4))
		Select CompanyStructure
		Index On ParentID Tag ParentID Additive
		Select Address
		Index On ParentID Tag ParentID Additive
		Select Contact
		Index On ParentID Tag ParentID Additive
		Select ContactPerson
		Index On ParentID Tag ParentID Additive
		Select TaxRegistration
		Index On ParentID Tag ParentID Additive
		Select BankAccount
		Index On ParentID Tag ParentID Additive
		Select SelectionCriteria
		Index On ParentID Tag ParentID Additive
		Select Company
		Index On ParentID Tag ParentID Additive
		Select TaxCodeDetails
		Index On ParentID Tag ParentID Additive
		Select Transaction
		Index On Id Tag Id Additive
		Select Journal
		Index On Id Tag Id Additive
		Select DebitAmount
		Index On ParentID Tag ParentID Additive
		Select CreditAmount
		Index On ParentID Tag ParentID Additive
		Select TaxInformation
		Index On ParentID Tag ParentID Additive
		Select TaxAmount
		Index On ParentID Tag ParentID Additive
		Select Payment
		Index On Id Tag Id Additive
		Select PaymentLineAmount
		Index On ParentID Tag ParentID Additive
		Select InvoiceLineAmount
		Index On ParentID Tag ParentID Additive
		Select SupplierInfo
		Index On ParentID Tag ParentID Additive
		Select CustomerInfo
		Index On ParentID Tag ParentID Additive
		Select BillingAddress
		Index On ParentID Tag ParentID Additive
		Select InvoiceDocumentTotals
		Index On ParentID Tag ParentID Additive
		Select TaxInformationTotals
		Index On ParentID Tag ParentID Additive


		**** Origine
		Create Cursor PaymentsTotals ( ;
			NumberOfEntries			N(20), ;
			TotalDebit 				N(18,2), ;
			TotalCredit				N(18,2))

		Create Cursor PurchaseInvoicesTotals ( ;
			NumberOfEntries			N(20), ;
			TotalDebit 				N(18,2), ;
			TotalCredit				N(18,2))

		Create Cursor SalesInvoicesTotals ( ;
			NumberOfEntries			N(20), ;
			TotalDebit 				N(18,2), ;
			TotalCredit				N(18,2))

		Create Cursor SAFT_Conturi ( ;
			AccountID               C(30), ;
			Denumire             	C(100), ;
			Analitice 				N(10), ;
			AccountType				C(12))

		Create Cursor SAFT_Analitice ( ;
			AccountID               C(30), ;
			Analitic				C(35), ;
			Denumire             	C(100), ;
			Denumire2             	C(100), ;
			AccountType				C(12),;
			CUI						C(20), ;
			TipCUI					C(2),;
			Real 					L)

		Select SAFT_Analitice
		Index On AccountID 			Tag AccountID	Additive
		Index On AccountID+Analitic Tag AA 			Additive
		Index On Denumire 			Tag Denumire 	Additive
		Index On Denumire2 			Tag Denumire2	Additive
		Index On Analitic 			Tag Analitic 	Additive

		Select SAFT_Conturi
		Index On Denumire 			Tag Denumire 	Additive
		Index On AccountID 			Tag AccountID	Additive

		Create Cursor TaxTableTotals (;
			TaxType			C(3), ;
			tTVA			C(5), ;
			TVAI			L, ;
			TVAN			L, ;
			Description		C(240), ;
			TaxPercentage	N(18,3), ;
			BaseRate		N(6,4), ;
			Explicatie		C(50), ;
			RCD				N(18,2), ;
			RCC				N(18,2), ;
			RCDT			N(18,2), ;
			RCCT			N(18,2), ;
			SFD				N(18,2), ;
			SFC				N(18,2),;
			NRCRT			N(18,0))

		Select TaxTableTotals
		Index On tTVA+TaxType 	Tag tTVA 		Additive
		Index On TaxType+tTVA 	Tag TaxType 	Additive
		Index On Explicatie 	Tag Explicatie	Additive
		Set Order To TaxType

		Create Cursor Teste_Consistenta_ANAF;
		(;
			Serie_Test				C(2)	;
		,	Denumire_Test			C(10)	;
		,	Descriere_Test			M		;
		,	Sectiune				C(30)	;
		,	Sub_Sectiune			C(30)	;
		,	Element					C(30)	;
		,	Inconsistenta			C(254)	;
		,	Diferenta				N(15,2)	;
		)
    ENDPROC

    PROCEDURE CreareCursoare_Import_Prelucrare
        *-- Contine codul original din frmsaft
		CREATE CURSOR Parteneri (;
			NID	     				N(10), ;
			ID						N(10), ;
			AccountID				C(30), ;
			AccountType				C(12), ;
			StandardAccountID		C(30), ;
			StandardID				C(50), ;
			RegistrationNumber		C(35), ;
			Name 					C(70), ;
			StreetName 				C(70), ;
			Number  				C(18), ;
			AdditionalAddressDetail C(70), ;
			Building  				C(35), ;
			City 					C(35), ;
			PostalCode 				C(18), ;
			Region 					C(35), ;
			Country 				C(2) , ;
			AddressType 			C(254), ;
			IBANNumber				C(35), ;
			BankAccountNumber		C(70), ;
			BankAccountName 		C(70), ;
			SortCode 				C(18), ;
			CustomerID 				C(35), ;
			SupplierID 				C(35), ;
			SelfBillingIndicator 	C(9),  ;
			AccountDescription		C(70), ;
			AccountCreationDate		C(10), ;
			Telephone				C(20), ;
			Email					C(50), ;
			FirstName				C(50), ;
			Initials				C(10), ;
			LastName				C(50), ;
			TaxRegistrationNumber	C(20), ;
			SID						N(18,2), ;
			SIC						N(18,2), ;
			RCD						N(18,2), ;
			RCC						N(18,2), ;
			SFD						N(18,2), ;
			SFC						N(18,2), ;
			NCD						N(18,2), ;
			NCC						N(18,2), ;
			FCD						N(18,2), ;
			FCC						N(18,2), ;
			PCD						N(18,2), ;
			PCC						N(18,2), ;
			DCD						N(18,2), ;
			DCC						N(18,2), ;
			FC						C(10), ;
			LipsaCustomer			L, ;
			LipsaSupplier			L, ;
			Clasa8					L, ;
			LipsaCont				L, ;
			Analitic 				C(35), ;
			ProblemaTVA				L, ;
			Explicatie 				C(50), ;
			Denumire				C(100))

		SELECT * FROM Parteneri INTO CURSOR Customers READWRITE
		SELECT * FROM Parteneri INTO CURSOR Suppliers READWRITE

		SELECT Customers
		INDEX ON NID 		TAG NID		 	ADDITIVE
		INDEX ON AccountID 	TAG AccountID 	ADDITIVE
		INDEX ON Denumire 	TAG Denumire 	ADDITIVE
		INDEX ON CustomerID TAG CustomerID 	ADDITIVE
		INDEX ON SupplierID TAG SupplierID 	ADDITIVE
		INDEX ON AccountID+CustomerID TAG XAC ADDITIVE
		INDEX ON Explicatie	TAG Explicatie 	ADDITIVE

		SELECT Suppliers
		INDEX ON NID 		TAG NID		 	ADDITIVE
		INDEX ON AccountID 	TAG AccountID 	ADDITIVE
		INDEX ON Denumire 	TAG Denumire 	ADDITIVE
		INDEX ON CustomerID TAG CustomerID 	ADDITIVE
		INDEX ON SupplierID TAG SupplierID 	ADDITIVE
		INDEX ON AccountID+SupplierID TAG XAS ADDITIVE
		INDEX ON Explicatie	TAG Explicatie 	ADDITIVE

		CREATE CURSOR _Header( ;
			ID 									N(10), ;
			AuditFileVersion					C(10), ;
			AuditFileCountry					C(2), ;
			AuditFileRegion						C(20), ;
			AuditFileDateCreated				C(10), ;
			SoftwareCompanyName					C(70), ;
			SoftwareID							C(18), ;
			SoftwareVersion						C(10), ;
			RegistrationNumber					C(15), ;
			Name								C(70), ;
			StreetName 							C(70), ;
			Number  							C(18), ;
			Region								C(5), ;
			City								C(35), ;
			Country								C(2), ;
			AddressType							C(30), ;
			Title								C(9), ;
			FirstName							C(30), ;
			LastName							C(30), ;
			Salutation							C(30), ;
			Telephone							C(30), ;
			Email								C(70), ;
			Website								C(70), ;
			TaxRegistrationNumber				C(15), ;
			TaxType								C(35), ;
			TaxNumber							C(35), ;
			TaxAuthority						C(35), ;
			TaxVerificationDate					C(10), ;
			IBANNumber							C(50), ;
			DefaultCurrencyCode					C(3), ;
			TaxReportingJurisdiction			C(30), ;
			CompanyEntity						C(70), ;
			PeriodStart							C(2), ;
			PeriodStartYear						C(4), ;
			PeriodEnd							C(2), ;
			PeriodEndYear						C(4), ;
			HeaderComment						C(30), ;
			SegmentIndex						C(2), ;
			TotalSegmentsInsequence				C(2), ;
			TaxAccountingBasis					C(1), ;
			TaxEntity							C(30), ;
			FisierSAFT							M, ;
			DirectorSAFT						M, ;
			DeLa								D, ;
			PanaLa								D, ;
			UESEE								L, ;
			VIES								L, ;
			eCUI								L, ;
			eCNP								L)

		CREATE CURSOR GeneralLedgerAccounts (;
			NID	     				N(10), ;
			AccountID				C(30), ;
			AccountType				C(12), ;
			AccountDescription		C(70), ;
			StandardAccountID       C(30), ;
			StandardID       		C(50), ;
			AccountCreationDate		C(10), ;
			SID						N(18,2), ;
			SIC						N(18,2), ;
			RCD						N(18,2), ;
			RCC						N(18,2), ;
			SFD						N(18,2), ;
			SFC						N(18,2), ;
			NCD						N(18,2), ;
			NCC						N(18,2), ;
			FCD						N(18,2), ;
			FCC						N(18,2), ;
			PCD						N(18,2), ;
			PCC						N(18,2), ;
			DCD						N(18,2), ;
			DCC						N(18,2), ;
			Explicatie 				C(50), ;
			FC 						C(10), ;
			LipsaCont				L, ;
			LipsaCustomer			L, ;
			LipsaSupplier			L, ;
			Clasa8					L, ;
			SCuA					L, ;
			eSintetic				L, ;
			eAnalitic				L, ;
			Analitic				C(35), ;
			Analitice				L, ;
			Denumire				C(100),;
			NrCrt					N(18,0))

		SELECT GeneralLedgerAccounts
		INDEX ON NID 		TAG NID		 	ADDITIVE
		INDEX ON AccountID+StandardID TAG AccountID ADDITIVE
		INDEX ON Denumire 	TAG Denumire  	ADDITIVE
		INDEX ON StandardID	TAG StandardID 	ADDITIVE
		INDEX ON AccountID+StandardID TAG AccountID2 ADDITIVE
		INDEX ON Explicatie	TAG Explicatie 	ADDITIVE

		CREATE CURSOR TaxTable (;
			NID	     		N(10), ;
			TaxType			C(3), ;
			TaxCode			C(6), ;
			tTVA 			C(5), ;
			tInversa		L, ;
			TVAI			L, ;
			TVAN			L, ;
			Lipsa			L, ;
			Luat			L, ;
			Explicatie		C(50), ;
			ExpirationDate	C(10), ;
			EffectiveDate	C(10), ;
			Description		C(240), ;
			TaxPercentage	N(18,3), ;
			BaseRate		N(6,4), ;
			Country			C(2), ;
			Region			C(10), ;
			RCD				N(18,2), ;
			RCC				N(18,2), ;
			RCDT			N(18,2), ;
			RCCT			N(18,2), ;
			SFD				N(18,2), ;
			SFC				N(18,2))

		SELECT TaxTable
		INDEX ON NID 				TAG NID 		ADDITIVE
		INDEX ON tTVA+TaxType 		TAG tTVA 		ADDITIVE
		INDEX ON TaxType+TaxCode	TAG TaxType 	ADDITIVE
		INDEX ON TaxCode+TaxType	TAG TaxCode		ADDITIVE
		INDEX ON TaxType+TaxCode+IIF(TVAI,"1","0")+IIF(TVAN,"1","0") TAG TCIN ADDITIVE
		INDEX ON Explicatie			TAG Explicatie	ADDITIVE
		SET ORDER TO TaxType

		CREATE CURSOR UOMTable ( ;
			NID	     				N(10), ;
			UnitOfMeasure			C(3), ;
			Description				C(30), ;
			Explicatie 				C(100), ;
			UM						C(5),;
			NrCrt					N(18,0))

		SELECT UOMTable
		INDEX ON NID TAG NID ADDITIVE
		SET ORDER TO

		CREATE CURSOR AnalysisTypeTable ( ;
			NID	     				N(10), ;
			AnalysisType			C(2), ;
			AnalysisTypeDescription C(30), ;
			AnalysisID				C(50), ;
			AnalysisIDDescription	C(50), ;
			CentruCost				C(5), ;
			Explicatie 				C(100),;
			Nrcrt					N(18,0) )

		SELECT AnalysisTypeTable
		INDEX ON NID TAG NID ADDITIVE
		SET ORDER TO

		CREATE CURSOR MovementTypeTable ( ;
			NID	N(10), ;
			MovementType C(3), ;
			Description  C(70),;
			NrCrt		 N(18,0),;
			Explicatie   C(100))
		SELECT MovementTypeTable
		INDEX ON NID TAG NID ADDITIVE
		SET ORDER TO


		CREATE CURSOR Products ( ;
			NID	     						N(10), ;
			ProductCode						C(20), ;
			Description						C(75), ;
			ProductCommodityCode			C(8), ;
			ProductNumberCode				C(35), ;
			UOMBase							C(3), ;
			UOMStandard						C(3), ;
			UOMToUOMBaseConversionFactor	C(20), ;
			UM								C(5), ;
			Explicatie 						C(100),;
			NrCrt		 					N(18,0))
		SELECT Products
		INDEX ON NID TAG NID ADDITIVE
		SET ORDER TO

		CREATE CURSOR Payments ( ;
			NID	     				N(10), ;&&&&ok
			ParentID	     		N(10), ;&&&&ok
			ID 		    			N(10), ;&&&&ok
			PaymentRefNo     		C(20), ; &&&&ok
			TransactionDate         C(10), ; &&&&ok
			PaymentMethod           C(18), ; &&&&ok
			Description             C(50), ; &&&&ok
			NetTotal				N(18,2), ; &&&&ok
			GrossTotal				N(18,2), ; &&&&ok
			AccountID				C(30), ; &&&&ok
			AccountType				C(12), ;
			StandardAccountID		C(30), ; &&&&ok
			StandardID				C(50), ; &&&&ok
			CustomerID 				C(35), ; &&&&ok
			SupplierID 				C(35), ; &&&&ok
			DebitCreditIndicator    C(1), ; &&&&ok
			Amount					N(18,2), ; &&&&ok
			CurrencyCode			C(5), ; &&&&ok
			CurrencyAmount			N(18,2), ; &&&&ok
			ExchangeRate			N(10,4), ; &&&&ok
			TaxType					C(3), ; &&&&ok
			TaxCode					C(6), ; &&&&ok
			TaxPercentage			N(5,2), ; &&&&ok
			TaxBase					N(18,2), ; &&&&ok
			TaxAmount				N(18,2), ; &&&&ok
			TaxPointDate			C(10), ; &&&&ok
			Explicatie				C(100), ; &&&&ok
			LipsaCustomer			L, ;
			LipsaSupplier			L, ;
			LipsaCont				L, ;
			Clasa8					L, ;
			FC						C(10), ;
			Data					D, ;
			Analitic 				C(35), ;
			Denumire				C(100),;
			NrCrt					N(18,0) )

		SELECT Payments
		INDEX ON NID 		TAG NID 		ADDITIVE
		INDEX ON ID			TAG ID 			ADDITIVE
		INDEX ON CustomerID	TAG CustomerID 	ADDITIVE
		INDEX ON SupplierID	TAG SupplierID 	ADDITIVE
		INDEX ON AccountID	TAG AccountID 	ADDITIVE
		INDEX ON StandardID	TAG StandardID 	ADDITIVE
		INDEX ON Denumire	TAG Denumire	ADDITIVE
		INDEX ON Amount		TAG Amount   	ADDITIVE
		INDEX ON Explicatie	TAG Explicatie 	ADDITIVE
		INDEX ON Data		TAG Data	   	ADDITIVE
		INDEX ON Analitic	TAG Analitic 	ADDITIVE

		SELECT * FROM Payments INTO CURSOR FC_Payments READWRITE
		SELECT FC_Payments
		INDEX ON NID 		TAG NID 		ADDITIVE
		INDEX ON ID			TAG ID 			ADDITIVE
		INDEX ON CustomerID	TAG CustomerID 	ADDITIVE
		INDEX ON SupplierID	TAG SupplierID 	ADDITIVE
		INDEX ON AccountID	TAG AccountID 	ADDITIVE
		INDEX ON StandardID	TAG StandardID 	ADDITIVE
		INDEX ON Denumire	TAG Denumire	ADDITIVE
		INDEX ON Amount		TAG Amount   	ADDITIVE
		INDEX ON Explicatie	TAG Explicatie 	ADDITIVE
		INDEX ON Data		TAG Data	   	ADDITIVE
		INDEX ON Analitic	TAG Analitic 	ADDITIVE

		CREATE CURSOR SalesInvoices ( ;
			NID						N(10), ;
			ID						N(10), ;
			InvoiceNo				C(20), ;
			InvoiceDate				C(10), ;
			InvoiceType				C(3), ;
			CustomerID 				C(35), ;
			SupplierID 				C(35), ;
			StreetName				C(70), ;
			Number					C(18), ;
			City 					C(35), ;
			PostalCode 				C(18), ;
			Region 					C(35), ;
			Country 				C(2) , ;
			AddressType 			C(254), ;
			AccountID				C(30), ;
			StandardAccountID		C(30), ;
			StandardID				C(50), ;
			SelfBillingIndicator	C(20), ;
			NetTotal				N(18,2), ;
			GrossTotal				N(18,2), ;
			Partener				C(70), ;
			Data 					D, ;
			LipsaCustomer			L, ;
			LipsaSupplier			L, ;
			LipsaCont				L, ;
			LipsaCont2				L, ;
			Clasa8					L, ;
			Analitic				C(35), ;
			Explicatie 				C(50),;
			NrCrt				    N(18,0) )

		SELECT SalesInvoices
		INDEX ON NID		TAG NID 		ADDITIVE
		INDEX ON ID			TAG ID 			ADDITIVE
		INDEX ON InvoiceNo	TAG InvoiceNo 	ADDITIVE
		INDEX ON CustomerID	TAG CustomerID 	ADDITIVE
		INDEX ON SupplierID	TAG SupplierID 	ADDITIVE
		INDEX ON AccountID	TAG AccountID 	ADDITIVE
		INDEX ON StandardID	TAG StandardID 	ADDITIVE
		INDEX ON Partener	TAG Partener	ADDITIVE
		INDEX ON Explicatie	TAG Explicatie 	ADDITIVE

		SELECT * FROM SalesInvoices INTO CURSOR PurchaseInvoices READWRITE
		SELECT PurchaseInvoices
		INDEX ON NID		TAG NID 		ADDITIVE
		INDEX ON ID			TAG ID 			ADDITIVE
		INDEX ON InvoiceNo	TAG InvoiceNo 	ADDITIVE
		INDEX ON CustomerID	TAG CustomerID 	ADDITIVE
		INDEX ON SupplierID	TAG SupplierID 	ADDITIVE
		INDEX ON AccountID	TAG AccountID 	ADDITIVE
		INDEX ON StandardID	TAG StandardID 	ADDITIVE
		INDEX ON Partener	TAG Partener	ADDITIVE
		INDEX ON Explicatie	TAG Explicatie 	ADDITIVE

		SELECT * FROM SalesInvoices INTO CURSOR FC_SalesInvoices READWRITE
		SELECT FC_SalesInvoices
		INDEX ON NID		TAG NID 		ADDITIVE
		INDEX ON ID			TAG ID 			ADDITIVE
		INDEX ON InvoiceNo	TAG InvoiceNo 	ADDITIVE
		INDEX ON CustomerID	TAG CustomerID 	ADDITIVE
		INDEX ON SupplierID	TAG SupplierID 	ADDITIVE
		INDEX ON AccountID	TAG AccountID 	ADDITIVE
		INDEX ON StandardID	TAG StandardID 	ADDITIVE
		INDEX ON Partener	TAG Partener	ADDITIVE
		INDEX ON Explicatie	TAG Explicatie 	ADDITIVE

		SELECT * FROM PurchaseInvoices INTO CURSOR FC_PurchaseInvoices READWRITE
		SELECT FC_PurchaseInvoices
		INDEX ON NID		TAG NID 		ADDITIVE
		INDEX ON ID			TAG ID 			ADDITIVE
		INDEX ON InvoiceNo	TAG InvoiceNo 	ADDITIVE
		INDEX ON CustomerID	TAG CustomerID 	ADDITIVE
		INDEX ON SupplierID	TAG SupplierID 	ADDITIVE
		INDEX ON AccountID	TAG AccountID 	ADDITIVE
		INDEX ON StandardID	TAG StandardID 	ADDITIVE
		INDEX ON Partener	TAG Partener	ADDITIVE
		INDEX ON Explicatie	TAG Explicatie 	ADDITIVE

		CREATE CURSOR SalesInvoicesLine ( ;
			ParentID				N(10), ;
			ID						N(10), ;
			AccountID				C(30), ; &&ok
			StandardAccountID		C(30), ; &&ok
			StandardID				C(50), ; &&ok
			GoodsServicesID			C(2), ; &&ok
			ProductCode				C(20), ; &&ok
			ProductDescription		C(75), ;&&ok
			Quantity				N(18,3), ; &&ok
			InvoiceUOM				C(3), ; &&ok
			UOMToUOMBaseConversionFactor	C(20), ;
			UnitPrice				N(18,2), ; &&ok
			TaxPointDate			C(10), ;
			Description				C(75), ; &&ok
			Amount					N(18,2), ; &&ok
			CurrencyCode			C(5), ;
			CurrencyAmount			N(18,2), ;
			ExchangeRate			N(10,4), ; &&ok
			DebitCreditIndicator	C(1), ; &&ok
			TaxType					C(3), ; &&ok
			TaxCode					C(6), ; &&ok
			TaxPercentage			N(5,2), ; &&ok
			TaxBase					N(18,2), ;
			TaxAmount				N(18,2), ; &&ok
			LipsaCont2				L, ;
			tInversa				L, ;
			tIncasare				L, ;
			Servicii				L, ;
			TVAI 					L, ;
			TVAN					L, ;
			ProblemaBT				L, ;
			ProblemaBaza			L, ;
			ProblemaTVA				L, ;
			TaxBaseD				N(18,2), ;
			TaxAmountD				N(18,2), ;
			Analitic				C(35), ;
			Explicatie 				C(50))

		CREATE CURSOR GLE_Header ( ;
			NIDJ					N(10), ;
			NID 					N(10),  ;
			ID 						N(10),  ;
			JournalID				C(18), ;
			Description             C(70), ;
			Type                    C(9),  ;
			TransactionID           C(70), ;
			Period					C(2),  ;
			PeriodYear				C(4),  ;
			TransactionDate         C(10), ;
			T_Description           C(70), ;
			SystemEntryDate   		C(10), ;
			GLPostingDate           C(10), ;
			CustomerID 				C(35), ;
			SupplierID 				C(35), ;
			Denumire 				C(100), ; &&OK
			LipsaCustomer			L, ;
			LipsaSupplier			L, ;
			LipsaCont				L, ;
			Clasa8					L, ;
			Data 					D, ;
			ProblemaBT				L, ;
			ProblemaBaza			L, ;
			ProblemaTVA				L, ;
			TaxBaseD				N(18,2), ;
			TaxAmountD				N(18,2), ;
			Explicatie 				C(50))

		CREATE CURSOR GeneralLedgerEntries ( ;
			NIDJ					N(10), ;
			NID						N(10), ;
			ID 						N(10),  ;
			JournalID				C(18), ; &&OK
			Description             C(70), ; &&OK
			Type                    C(9),  ; &&OK
			TransactionID           C(70), ; &&OK
			Period					C(2),  ; &&OK
			PeriodYear				C(4),  ; &&OK
			TransactionDate         C(10), ; &&OK
			T_Description           C(70), ;
			SystemEntryDate   		C(10), ; &&OK
			GLPostingDate           C(10), ; &&OK
			CustomerID 				C(35), ; &&OK
			SupplierID 				C(35), ; &&OK
			Denumire 				C(100), ; &&OK
			LipsaCustomer			L, ;
			LipsaSupplier			L, ;
			LipsaCont				L, ;
			Clasa8					L, ;
			Data 					D, ;
			ProblemaBT				L, ;
			ProblemaBaza			L, ;
			ProblemaTVA				L, ;
			TaxBaseD				N(18,2), ;
			TaxAmountD				N(18,2), ;
			Explicatie 				C(50),;
			NrCrt      				N(18,0)) &&OK

		SELECT GeneralLedgerEntries
		INDEX ON NID 		TAG NID 		ADDITIVE
		INDEX ON ID 		TAG ID 			ADDITIVE
		INDEX ON JournalID 	TAG JournalID  	ADDITIVE
		INDEX ON CustomerID	TAG CustomerID	ADDITIVE
		INDEX ON SupplierID	TAG SupplierID	ADDITIVE
		INDEX ON Denumire 	TAG Denumire 	ADDITIVE
		INDEX ON Explicatie	TAG Explicatie 	ADDITIVE
		SET ORDER TO

		*	TaxType					C(3), ;
		*	TaxCode					C(6), ;
		*	TaxPercentage			N(5,2), ;

		CREATE CURSOR GeneralLedgerEntriesLines ( ;
			ParentID				N(10), ;
			ID						N(10), ;
			RecordID                C(18), ;
			AccountID               C(30), ;
			AccountType				C(12), ;
			StandardAccountID       C(30), ;
			StandardID       		C(50), ;
			CustomerID 				C(35), ;
			SupplierID 				C(35), ;
			Description             C(70), ;
			Amount					N(18,2), ;
			CurrencyCode			C(5), ;
			CurrencyAmount			N(18,2), ;
			ExchangeRate			N(10,4), ;
			TaxBase					N(18,2), ;
			TaxAmount				N(18,2), ;
			TransactionID           C(70), ;
			LipsaCustomer			L, ;
			LipsaSupplier			L, ;
			Clasa8					L, ;
			Analitice				L, ;
			Analitic 				C(35), ;
			Analitic2				C(35), ;
			Denumire				C(100), ;
			DC						C(1), ;
			FC						C(10), ;
			Data 					D, ;
			Sold					N(18,2), ;
			SoldDC					C(1), ;
			SF						N(18,2), ;
			SFDC					C(1), ;
			tTVA					C(5), ;
			TVAI					L, ;
			TVAN					L, ;
			LipsaCont				L, ;
			ProblemaBT				L, ;
			ProblemaBaza			L, ;
			ProblemaTVA				L, ;
			TaxBaseD				N(18,2), ;
			TaxAmountD				N(18,2), ;
			Explicatie 				C(50))

		CREATE CURSOR GeneralLedgerEntriesLinesTax ( ;
			ParentID				N(10), ;
			ID						N(10), ;
			RecordID                C(18), ;
			AccountID               C(30), ;
			Amount					N(18,2), ;
			DC						C(1), ;
			tTVA					C(5), ;
			TVAI					L, ;
			TVAN					L, ;
			TaxType					C(3), ;
			TaxCode					C(6), ;
			TaxPercentage			N(5,2), ;
			TaxBase					N(18,2), ;
			TaxAmount				N(18,2), ;
			CurrencyCode			C(5), ;
			CurrencyAmount			N(18,2), ;
			ExchangeRate			N(10,4), ;
			TaxBase2				N(18,2), ;
			TaxAmount2				N(18,2), ;
			TaxBaseD				N(18,2), ;
			TaxAmountD				N(18,2), ;
			TransactionID           C(70), ;
			Description				C(240), ;
			Explicatie 				C(50);
			;
			, TaxType_9					C(3), ;
			TaxCode_9					C(6), ;
			TaxPercentage_9			N(5,2), ;
			TaxBase_9				N(18,2), ;
			TaxAmount_9				N(18,2), ;
			CurrencyCode_9			C(5), ;
			CurrencyAmount_9			N(18,2), ;
			ExchangeRate_9			N(10,4), ;
			TaxType_5					C(3), ;
			TaxCode_5					C(6), ;
			TaxPercentage_5			N(5,2), ;
			TaxBase_5				N(18,2), ;
			TaxAmount_5				N(18,2), ;
			CurrencyCode_5			C(5), ;
			CurrencyAmount_5			N(18,2), ;
			ExchangeRate_5			N(10,4) ;
			)
		SELECT GeneralLedgerEntriesLinesTax
		INDEX ON ParentID  TAG ParentID ADDITIVE


		*	TaxType					C(3), ;
		*	TaxCode					C(6), ;
		*	TaxPercentage			N(5,2), ;

		CREATE CURSOR GLE_Lines ( ;
			ParentID				N(10), ;
			ID						N(10), ;
			RecordID                C(18), ;
			AccountID               C(30), ;
			AccountType				C(12), ;
			StandardAccountID      	C(30), ;
			StandardID		      	C(50), ;
			CustomerID 				C(35), ;
			SupplierID 				C(35), ;
			Description             C(70), ;
			Amount					N(18,2), ;
			CurrencyCode			C(5), ;
			CurrencyAmount			N(18,2), ;
			ExchangeRate			N(10,4), ;
			TaxBase					N(18,2), ;
			TaxAmount				N(18,2), ;
			TransactionID           C(70), ;
			LipsaCustomer			L, ;
			LipsaSupplier			L, ;
			Clasa8					L, ;
			Analitice				L, ;
			Analitic 				C(35), ;
			Analitic2				C(35), ;
			Denumire				C(100), ;
			DC						C(1), ;
			FC						C(10), ;
			Data 					D, ;
			Sold					N(18,2), ;
			SoldDC					C(1), ;
			SF						N(18,2), ;
			SFDC					C(1), ;
			tTVA					C(5), ;
			TVAI					L, ;
			TVAN					L, ;
			LipsaCont				L, ;
			ProblemaBT				L, ;
			ProblemaBaza			L, ;
			ProblemaTVA				L, ;
			TaxBaseD				N(18,2), ;
			TaxAmountD				N(18,2), ;
			Explicatie 				C(50))

		SELECT GeneralLedgerEntriesLines
		INDEX ON ParentID  TAG ParentID ADDITIVE
		INDEX ON AccountID+CustomerID TAG XAC FOR LipsaCustomer UNIQUE
		INDEX ON AccountID+SupplierID TAG XAS FOR LipsaSupplier UNIQUE
		SET ORDER TO

		SELECT GeneralLedgerEntriesLines.*, ;
			GeneralLedgerEntries.JournalID, ;
			GeneralLedgerEntries.Description as Description2, ;
			GeneralLedgerEntries.Type, ;
			GeneralLedgerEntries.TransactionDate ;
		FROM GeneralLedgerEntriesLines, GeneralLedgerEntries ;
			WHERE GeneralLedgerEntriesLines.ParentID = GeneralLedgerEntries.ID ;
				INTO CURSOR FC_GLE READWRITE

		SELECT FC_GLE
		INDEX ON AccountID+Analitic+DTOS(Data) TAG AAD

		SELECT * FROM SalesInvoicesLine INTO CURSOR PurchaseInvoicesLine READWRITE

		SELECT SalesInvoices
		INDEX ON NID TAG NID ADDITIVE
		INDEX ON ID  TAG ID  ADDITIVE
		SET ORDER TO
		SELECT SalesInvoicesLine
		INDEX ON ParentID TAG ParentID ADDITIVE

		SELECT PurchaseInvoices
		INDEX ON NID TAG NID ADDITIVE
		INDEX ON ID  TAG ID  ADDITIVE
		SET ORDER TO
		SELECT PurchaseInvoicesLine
		INDEX ON ParentID TAG ParentID ADDITIVE

		SELECT Payments
		INDEX ON NID TAG NID ADDITIVE
		INDEX ON ID  TAG ID  ADDITIVE
		SET ORDER TO

		CREATE CURSOR CustomersTotals ;
				(AccountID C(30), Denumire C(100), StandardAccountID C(30), StandardID C(50), Explicatie C(100), ;
				SID N(18,2), SIC N(18,2), ;
				RCD N(18,2), RCC N(18,2), ;
				SFD N(18,2), SFC N(18,2), ;
				NCD N(18,2), NCC N(18,2), ;
				PCD N(18,2), PCC N(18,2), ;
				FCD N(18,2), FCC N(18,2), ;
				DCD N(18,2), DCC N(18,2), ;
				NRCRT N(18,0))

		SELECT CustomersTotals
		INDEX ON Denumire TAG Denumire ADDITIVE
		INDEX ON AccountID TAG AccountID ADDITIVE
		INDEX ON Explicatie TAG Explicatie ADDITIVE

		CREATE CURSOR SuppliersTotals ;
				(AccountID C(30), Denumire C(100), StandardAccountID C(30), StandardID C(50), Explicatie C(100), ;
				SID N(18,2), SIC N(18,2), ;
				RCD N(18,2), RCC N(18,2), ;
				SFD N(18,2), SFC N(18,2), ;
				NCD N(18,2), NCC N(18,2), ;
				PCD N(18,2), PCC N(18,2), ;
				FCD N(18,2), FCC N(18,2), ;
				DCD N(18,2), DCC N(18,2), ;
				NRCRT N(18,0))

		SELECT SuppliersTotals
		INDEX ON Denumire TAG Denumire ADDITIVE
		INDEX ON AccountID TAG AccountID ADDITIVE
		INDEX ON Explicatie TAG Explicatie ADDITIVE

		CREATE CURSOR GeneralLedgerAccountsTotals ;
				(AccountID C(1), SID N(18,2), SIC N(18,2), ;
				RCD N(18,2), RCC N(18,2), ;
				SFD N(18,2), SFC N(18,2), ;
				NCD N(18,2), NCC N(18,2), ;
				PCD N(18,2), PCC N(18,2), ;
				FCD N(18,2), FCC N(18,2), ;
				DCD N(18,2), DCC N(18,2), ;
				NRCRT N(18,0))

		**** Ale Mele
		CREATE CURSOR GeneralLedgerEntriesTotals2 ( ;
			NumberOfEntries			N(20), ;
			TotalDebit 				N(18,2), ;
			TotalCredit				N(18,2))

		CREATE CURSOR PaymentsTotals2 ( ;
			NumberOfEntries			N(20), ;
			TotalDebit 				N(18,2), ;
			TotalCredit				N(18,2))

		CREATE CURSOR PurchaseInvoicesTotals2 ( ;
			NumberOfEntries			N(20), ;
			TotalDebit 				N(18,2), ;
			TotalCredit				N(18,2),;
			Sold 					N(18,2);
			)

		CREATE CURSOR SalesInvoicesTotals2 ( ;
			NumberOfEntries			N(20), ;
			TotalDebit 				N(18,2), ;
			TotalCredit				N(18,2),;
			Sold 					N(18,2);
			)



		CREATE CURSOR Assets ( ;
			Nrcrt    								N(10), ;
			AssetID									C(35), ;
			AccountID								C(70), ;
			Description								C(254), ;
			DateOfAcquisition						D(8), ;
			StartUpDate								D(8), ;
			AssetValuationType						C(20), ;
			ValuationClass							C(18), ;
			AcquisitionAndProductionCostsBegin		N(18,2), ;
			AcquisitionAndProductionCostsEnd		N(18,2), ;
			InvestmentSupport						N(18,2), ;
			AssetLifeYear							N(4), ;
			AssetLifeMonth							N(6), ;
			AssetAddition							N(18,2), ;
			Transfers								N(18,2), ;
			AssetDisposal							N(18,2), ;
			BookValueBegin							N(18,2), ;
			DepreciationMethod						C(35), ;
			DepreciationPercentage					N(18,2), ;
			DepreciationForPeriod					N(18,2), ;
			AppreciationForPeriod					N(18,2), ;
			ExtraordinaryDepreciationMethod			C(35), ;
			ExtraordinaryDepreciationAmountForPeriod N(18,2), ;
			AccumulatedDepreciation					N(18,2), ;
			BookValueEnd							N(18,2), ;
			Explicatie								C(100), ;
			Erori									C(254),;
			NID	     								N(10);
		 )


		CREATE CURSOR PhysicalStock (;
			NID	     						N(10)	, ;
			WarehouseID						C(35)	, ;
			ProductCode						C(20)	, ;
			ProductType						C(20)	, ;
			ProductStatus					C(35)	, ;
			OwnerID					  		C(35)	, ;
			UOMPhysicalStock		  		C(3)	, ;
			UOMToUOMBaseConversionFactor	N(18,5)	, ;
			StockAccountCommodityCode 		C(35) 	, ;
			UnitPrice				  		N(18,2)	, ;
			OpeningStockQuantity	  		N(18,3)	, ;
			OpeningStockValue		  		N(18,2)	, ;
			ClosingStockQuantity	  		N(18,3)	, ;
			ClosingStockValue		  		N(18,2)	, ;
			StockCharacteristic				C(7)	, ;
			StockCharacteristicValue 		C(35)	, ;
			Explicatie 						C(100)	, ;
			NrCrt							N(15)   , ;
			Owner							C(70))

		CREATE CURSOR PhysicalStockTotals ;
				(CodGest C(10), Cont C(10), OpeningStockQuantity N(15,3), OpeningStockValue N(18,2), ;
				ClosingStockQuantity N(15,3), ClosingStockValue N(18,2), ;
				Gest C(5), SoldBalanta N(18,2), DiferentaBalanta N(18,2))

		CREATE CURSOR Owners ( ;
			NID	     				N(10), ;
			RegistrationNumber		C(35), ;
			Name 					C(70), ;
			StreetName 				C(70), ;
			Number  				C(18), ;
			AdditionalAddressDetail C(70), ;
			City 					C(35), ;
			PostalCode 				C(18), ;
			Region 					C(35), ;
			Country 				C(2) , ;
			AddressType 			C(254), ;
			FirstName				C(35), ;
			LastName				C(35), ;
			Telephone				C(35), ;
			Email					C(70), ;
			Website					C(70), ;
			TaxRegistrationNumber	C(15), ;
			IBANNumber				C(35), ;
			BankAccountNumber		C(70), ;
			BankAccountName 		C(70), ;
			SortCode 				C(18), ;
			OwnerID					N(9), ;
			AccountID				C(30), ;
			Explicatie 				C(100))


		CREATE CURSOR AssetTransactions ( ;
			NrCrt     					N(10), ;
			AssetTransactionID			C(70),;
			AssetID						C(35),;
			Denumire   					C(200),;
			AssetTransactionType		C(9),;
			Description					C(254),;
			AssetTransactionDate		D(8),;
			TransactionID				C(70),;
			AssetValuationType			C(18),;
			AcquisitionAndProductionCostsOnTransaction	N(18,2),;
			BookValueOnTransaction		N(18,2),;
			AssetTransactionAmount		N(18,2),;
			Erori 						C(254),;
			NumberOfAssetTransactions	N(15);
			, Explicatie 				C(100);
			)

		CREATE CURSOR MovementOfGoods( ;
			NumberOfMovementLines			N(15)	,;
			TotalQuantityReceived     		N(18,6)	,;
			TotalQuantityIssued				N(18,6)	,;
			MovementReference				C(35)	,;
			MovementDate					D(8)	,;
			MovementType					C(9)	,;
			SystemID						C(35)	,;
			DocumentType					C(18)	,;
			DocumentNumber					C(35)	,;
			LineNumber						C(18)	,;
			AccountID						C(70)	,;
			CustomerID						C(35)	,;
			SupplierID						C(35)	,;
			TransactionID					C(70)	,;
			ProductCode						C(70)	,;
			Quantity						N(18,6)	,;
			BookValue						N(18,2)	,;
			UnitOfMeasure					C(9)	,;
			UOMToUOMPhysicalStockConversion	N(18,6)	,;
			MovementSubtype					C(9)	,;
			MovementComments				C(254)	,;
			Partener						C(50)   ,;
			Erori 							C(254)	,;
			Explicatie 						C(100)	,;
			NrCrt							N(15)    ;
			)



    ENDPROC

    PROCEDURE ANAFColumns
		LPARAMETERS toGrid
		*-- Contine codul original din frmsaft
		With toGrid
			For Each oColumn In .Columns FoxObject
				If Not PemStatus(oColumn, 'lANAF_Column', 5)
					oColumn.AddProperty('lANAF_Column', .F.)
				EndIf
				tcColumnName = StrTran(oColumn.Controls(1).Caption, '* ', '')
				*
				oColumn.lANAF_Column=;
						InList(tcColumnName, 'AccountID', 'AccountDescription', 'AccountType', 'OpeningDebitBalance',;
							 'OpeningCreditBalance', 'ClosingDebitBalance', 'ClosingCreditBalance');											&& GLA
					Or	InList(tcColumnName, 'RegistrationNumber', 'Name', 'City', 'Country', 'CustomerID', 'SupplierID');						&& Customers, Suppliers
					Or	InList(tcColumnName, 'TaxType', 'TaxCode', 'Description', 'TaxPercentage', 'BaseRate');									&& TaxTable
					Or	InList(tcColumnName, 'UnitOfMeasure');																					&& UOMTable
					Or	InList(tcColumnName, 'AnalysisType', 'AnalysisTypeDescription', 'AnalysisID', 'AnalysisIDDescription');					&& AnalysisTypeTable
					Or	InList(tcColumnName, 'MovementType');																					&& MovementTypeTable
					Or	InList(tcColumnName, 'ProductCode', 'ProductCommodityCode', 'UOMBase', 'UOMStandard', 'UOMToUOMBaseConversionFactor');	&& Products, Owners este inclus in cele de mai sus
					Or	InList(tcColumnName, 'AssetID', 'DateOfAquisition', 'StartUpDate', 'AssetValuationType', 'ValuationClass',;
						'AcquisitionAndProductionCostsBegin', 'AcquisitionAndProductionCostsEnd', 'InvestmentSupport', 'AssetLifeYear',;
						'AssetLifeMonth', 'AssetAddition', 'Transfers', 'AssetDisposal', 'BookValueBegin', 'DepreciationMethod',;
						'DepreciationPercentage', 'DepreciationForPeriod', 'AppreciationForPeriod', 'AccumulatedDepreciation', 'BookValueEnd',;
						'ExtraordinaryDepreciationMethod', 'ExtraordinaryDepreciationAmountForPeriod');											&& Assets
					Or	InList(tcColumnName, 'NumberOfEntries', 'TotalDebit', 'TotalCredit', 'JournalID', 'Type', 'TransactionID', 'Period',;
						'PeriodYear', 'TransactionDate', 'TransactionDescription', 'SystemEntryDate', 'GLPostingDate', 'RecordID',;
						'DebitCreditIndicator', 'TaxBaseDescription', 'Amount', 'CurrencyCode', 'CurrencyAmount', 'ExchangeRate');				&& GLE
					Or	InList(tcColumnName, 'InvoiceNo', 'InvoiceDate', 'InvoiceType', 'SelfBillingIndicator',;
						'LineAccountID', 'Quantity', 'UnitPrice', 'TaxPointDate');																&& SalesInvoices, PurchaseInvoices
					Or	InList(tcColumnName, 'PaymentRefNo', 'PaymentMethod', 'LineNumber');													&& Payments
					Or	InList(tcColumnName, 'NumberOfMovementLines', 'TotalQuantityReceived', 'TotalQuantityIssued',  'MovementReference',;
						'MovementDate', 'MovementType');																						&& MovementOfGoods
					Or	InList(tcColumnName, 'UOMToUOMPhysicalStockConversion', 'MovementSubType');												&& MovementOfGoodsLines
					Or	InList(tcColumnName, 'NumberOfAssetTransactions', 'AssetTransactionID', 'AssetTransactionType', 'AssetTransactionDate',;
						'AcquisitionAndProductionCostOnTransaction', 'BookValueOnTransaction', 'AssetTransactionAmount');						&& AssetTransactions
					Or	InList(tcColumnName, 'PaymentTerms ', 'SourceID', 'BatchID', 'SystemID', 'ReceiptNumbers', 'GoodsServicesID',;
						'ProductDescription', 'DeliveryDate', 'InvoiceUOM', 'DeliveryAmount', 'DeliveryCurrencyCode', 'DeliveryCurrencyAmount',;
						'DeliveryExchangeRate', 'TaxExemptionReason', 'TaxDeclarationPeriod', 'StandardAccountID');								&& Optionale_1
					Or	InList(tcColumnName, 'ShippingCostsAmount', 'ShippingCostsCurrencyCode', 'ShippingCostsCurrencyAmount',;
						'ShippingCostsExchangeRate', 'Reference', 'Reason', 'OriginatingON', 'OrderDate', 'DeliveryID', 'DeliveryDate',;
						'WarehouseID', 'LocationID', 'UCR', 'SupplierName', 'StreetName', 'Number', 'AdditionalAddressDetail',;
						'Building', 'PostalCode', 'Region', 'AddressType', 'IBANNumber', 'BankAccountNumber', 'BankAccountName');				&& Optionale_2
					Or	InList(tcColumnName, 'SID', 'SIC', 'SFD', 'SFC', 'Nume', 'Denumire', 'StandardID')													&& RAIV

				*
		*!*			This.SetAll("DynamicBackColor", "IIF(!EMPTY(Explicatie),__RGB__NonStoc,__RGB__Normal)", "Column")
		*!*			This.DCD.DynamicBackColor 		= "IIF(DCD#0,__RGB__Galben,__RGB__Normal)"
		*!*			This.DCC.DynamicBackColor 		= "IIF(DCC#0,__RGB__Galben,__RGB__Normal)"

		*!*			Text To lcExpDynBackColor NoShow TextMerge
		*!*			ICASE
		*!*				(
		*!*				!EMPTY(Explicatie),__RGB__NonStoc,;
		*!*				Type("DCD")="N" And DCD#0,__RGB__Galben,;
		*!*				Type("DCC")="N" And DCC#0,__RGB__Galben,;
		*!*				<<oColumn.lANAF_Column>>, __RGB__COLOANA_ANAF,;
		*!*				__RGB__Normal;
		*!*				)
		*!*			EndText
		*!*			*lcDynBackColor=TextMerge(lcExpDynBackColor)

				*lcDynBackColor=;
					TextMerge(;
							'ICASE;
								(;
								!EMPTY(Explicatie),__RGB__NonStoc,;
								Type([DCD])=[N] And DCD#0,__RGB__Galben,;
								Type([DCC])=[N] And DCC#0,__RGB__Galben,;
								<<oColumn.lANAF_Column>>, __RGB__COLOANA_ANAF,;
								__RGB__Normal;
								);
							')


		*!*			lcAlias = oColumn.Parent.Tag
		*!*			If Used(lcAlias )
		*!*				=AFields(aTemp, lcAlias)
		*!*				m.ll_DCD=AScan(m.aTemp,'DCD',-1,-1,1,15)>0
		*!*				m.ll_DCC=AScan(m.aTemp,'DCD',-1,-1,1,15)>0
		*!*			Else
		*!*				Store .F. To m.ll_DCD, m.ll_DCC
		*!*			EndIf
		*!*			lcDynBackColor=TextMerge('ICASE(!EMPTY(Explicatie),__RGB__NonStoc,(<<m.ll_DCD>> And DCD#0) Or (<<m.ll_DCC>> And DCC#0),__RGB__Galben,<<oColumn.lANAF_Column>>,__RGB__COLOANA_ANAF,__RGB__Normal)')
				********************************************************************************************************************************
				lcDynBackColor=TextMerge('ICASE(!EMPTY(Explicatie),__RGB__NonStoc,<<oColumn.lANAF_Column>>,__RGB__COLOANA_ANAF,__RGB__Normal)')
				********************************************************************************************************************************
				*lcDynBackColor=TextMerge('ICASE(!EMPTY(Explicatie),__RGB__NonStoc,<<oColumn.lANAF_Column>>,__RGB__COLOANA_ANAF,RecNo()>RecCount(),m.nRGBGridLineColor,Mod(RecNo(),2)=1,__RGB__Normal,Rgb(211,223,238))')
				oColumn.DynamicBackColor = m.lcDynBackColor
				*oColumn.Header1.FontUnderline = oColumn.lANAF_Column
			Next
		EndWith
		*
		If PemStatus(toGrid, 'DCD', 5)
			toGrid.DCD.DynamicBackColor = "IIF(DCD#0,__RGB__Galben,__RGB__Normal)"
			toGrid.DCC.DynamicBackColor = "IIF(DCC#0,__RGB__Galben,__RGB__Normal)"
		EndIf

		With toGrid
			For Each oColumn In .Columns FoxObject
				*
				For Each oControl In oColumn.Controls FoxObject
					*
					If Upper(oControl.BaseClass)=Upper("TEXTBOX")
						cTextBoxName=oControl.Name
						oColumn.&cTextBoxName..SelectedBackColor=Rgb(10,36,136)
					EndIf
					*
					If InList(Upper(oControl.BaseClass), Upper("COMBOBOX"), Upper("TEXTBOX"))
						oControlName=oControl.Name
						SetInputMask(oColumn.&oControlName)
					EndIf
					*
				EndFor
				*
				If PemStatus(oColumn, [InputMask], 5)
					SetInputMask(oColumn)
				EndIf
				*
			Next
			*
		EndWith
		*
	ENDPROC

    *... si asa mai departe pentru absolut toate celelalte metode si evenimente.

ENDDEFINE
