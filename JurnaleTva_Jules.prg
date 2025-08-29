*&------------------------------------------------------------------------------------------------
*!*	PROGRAM: JurnaleTva_Jules.prg
*!*	AUTOR: Jules (Refactored)
*!*	DATA: 13.08.2024
*!*
*!*	DESCRIERE:
*!*	Versiune refactorizată care respectă convențiile de scope VFP (variabile PRIVATE)
*!*	pentru compatibilitate cu funcțiile definite de utilizator (ex: MySQLExec).
*!*	Obiectul de mediu 'loEnv' este declarat PRIVATE și este vizibil global pentru
*!*	toate sub-procedurile, eliminând necesitatea pasării ca parametru.
*!*
*!*	MOD DE UTILIZARE:
*!*	= JurnaleTva_Refactored(tnTipJurnal, tdData1, tdData2, tnCategorii, lOnlyInvoice, lOnlyVanzari)
*&------------------------------------------------------------------------------------------------
FUNCTION JurnaleTva_Refactored(tnTipJurnal As Number, tdData1 As Date, tdData2 As Date, tnCategorii As Number, lOnlyInvoice As Boolean, lOnlyVanzari As Boolean)

	PRIVATE loEnv
	LOCAL lcLogFile As String, _StartBegin As Number, lcProgram As String, llSuccess As Boolean, loErr As Exception, loValidation As Object

	llSuccess = .F.
	_StartBegin = SECONDS()
	lcProgram = PROGRAM()
	lcLogFile = IIF(TYPE("ExpDir")="C", ExpDir, "") + 'Log\' + lcProgram + '.log'

	* --- Bloc principal de execuție cu gestiunea erorilor ---
	TRY
		*-- Pas 1: Inițializare
		_Init(tnTipJurnal, tdData1, tdData2, tnCategorii, lOnlyInvoice, lOnlyVanzari, lcLogFile, _StartBegin)

		*-- Pas 2: Creare cursoare de lucru
		_CreateWorkingCursors()
		_Log("Structura cursoarelor de lucru a fost creată.")

		*-- Pas 3: Procesare Jurnal Cumpărări (dacă este necesar)
		IF NOT loEnv.lOnlyVanzari
			_ProcessPurchases()
			_Log("Procesarea Jurnalului de Cumpărări a fost finalizată.")
		ENDIF

		*-- Pas 4: Procesare Jurnal Vânzări
		_ProcessSales()
		_Log("Procesarea Jurnalului de Vânzări a fost finalizată.")

		*-- Pas 5: Validare finală (non-interactivă)
		loValidation = _ValidateJournals()
		IF loValidation.HasErrors
			_Log("Au fost identificate probleme de validare. Verificați cursorul 'crsValidationErrors'.")
		ENDIF

		_Log("Execuție finalizată cu succes.", .T.)
		llSuccess = .T.

	CATCH TO loErr
		*-- Gestiunea centralizată a erorilor
		LOCAL lcErrorMsg As String
		lcErrorMsg = "EROARE FATALĂ în " + lcProgram + ":" + CHR(13) + ;
		             "Număr eroare: " + TRANSFORM(loErr.ErrorNo) + CHR(13) + ;
		             "Mesaj: " + loErr.Message + CHR(13) + ;
		             "Linia: " + TRANSFORM(loErr.LineNo) + CHR(13) + ;
		             "Procedura: " + loErr.Procedure
		STRTOFILE(lcErrorMsg + CHR(13)+CHR(10), lcLogFile, 1)
		llSuccess = .F.

	FINALLY
		*-- Curățenie, indiferent de rezultat
		_Cleanup()
		IF VARTYPE(loEnv) = "O"
			RELEASE loEnv
		ENDIF
	ENDTRY

	RETURN llSuccess
ENDFUNC
*--------------------------------------------------------------------------------------------------
*                        FUNCȚII HELPER
*--------------------------------------------------------------------------------------------------
PROCEDURE _Init(tnTipJurnal, tdData1, tdData2, tnCategorii, lOnlyInvoice, lOnlyVanzari, tcLogFile, tnStartTime)
	loEnv = CREATEOBJECT("EMPTY")
	ADDPROPERTY(loEnv, "cLogFile", tcLogFile)
	ADDPROPERTY(loEnv, "nStartTime", tnStartTime)
	ADDPROPERTY(loEnv, "nLastTime", tnStartTime)

	IF FILE(loEnv.cLogFile)
		ERASE (loEnv.cLogFile)
	ENDIF
	_Log("*** START JurnaleTva_Refactored ***", .T.)

	ADDPROPERTY(loEnv, "nTipJurnal", IIF(VARTYPE(tnTipJurnal)='N', tnTipJurnal, 0))
	ADDPROPERTY(loEnv, "dData1", tdData1)
	ADDPROPERTY(loEnv, "dData2", tdData2)
	ADDPROPERTY(loEnv, "nCategorii", IIF(VARTYPE(tnCategorii)='N', tnCategorii, 0))
	ADDPROPERTY(loEnv, "lOnlyInvoice", IIF(VARTYPE(lOnlyInvoice)='L', lOnlyInvoice, .F.))
	ADDPROPERTY(loEnv, "lOnlyVanzari", IIF(VARTYPE(lOnlyVanzari)='L', lOnlyVanzari, .F.))
	ADDPROPERTY(loEnv, "cDbName", JUSTSTEM(DBF()))
	ADDPROPERTY(loEnv, "oSettings", ICAS.oSettings)
	ADDPROPERTY(loEnv, "oConturi", ICAS.oConturi)
	ADDPROPERTY(loEnv, "nSqlHandle", nSQLHandle)
	ADDPROPERTY(loEnv, "dMinPreluareTVAI", IIF(loEnv.oSettings.FacturiTVAIPreluare, {^2012-12-31}, ICAS.oSoc.Data_Prel))
	ADDPROPERTY(loEnv, "dDataMin", MIN(loEnv.dData1, {^2013-01-01}))
	ADDPROPERTY(loEnv, "nCotaStd", GetCotaTva(loEnv.dData1, '6-7'))
	ADDPROPERTY(loEnv, "nCotaRed1", GetCotaTva(loEnv.dData1, '8-9'))
	ADDPROPERTY(loEnv, "nCotaRed2", GetCotaTva(loEnv.dData1, '19-20'))

	#DEFINE JCODE_C_STD '6-7'
	#DEFINE JCODE_C_RED1 '8-9'
	#DEFINE JCODE_C_RED2 '19-20'
	#DEFINE JCODE_V_STD '6-7'
	_Log("Mediul de lucru a fost inițializat.")
ENDPROC

PROCEDURE _CreateWorkingCursors()
	CREATE CURSOR Jurnal (Id I, Data D, Data_Doc D, Nr C(16), Denumire C(80), Cod_Fisc C(16), Curs N(15,4), Total N(15,2), Baza_Tva N(15,2), Tva N(15,2), TotalInc N(15,2), Baza_TvaInc N(15,2), TvaInc N(15,2), TotalN N(15,2), Baza_TvaN N(15,2), TvaN N(15,2), Tip C(1), TvaI L, Tva_Art N(5,2), Cont C(20), Cod C(5), Tip_Tert C(1), Cod_Tert C(20), Indice N(1), CodTvaUser C(5), Fel_D C(20), Id_Intrare I, myIndex C(13), Preluat L, Tip_Ded C(3))
	INDEX ON myIndex TAG myIndex
	INDEX ON Id_Intrare TAG Id_Intrare
	CREATE CURSOR Jurnal_Det (Id_Intrare I, Id_Nota I, Data D, Ndp C(16), Explicatie C(80), Tva_Art N(5,2), Suma N(15,2), Baza_Tva N(15,2), TvaInc N(15,2), Referinta C(5), myIndex C(13), Cod C(5))
	INDEX ON myIndex TAG myIndex
	CREATE CURSOR JurnalV (Id I, Data D, Data90 D, Data_Doc D, Nr C(16), Denumire C(80), Cod_Fisc C(16), Curs N(15,4), Total N(15,2), Baza_Tva N(15,2), Tva N(15,2), TotalN N(15,2), Baza_TvaN N(15,2), TvaN N(15,2), TotalInc N(15,2), Baza_TvaInc N(15,2), TvaInc N(15,2), Preluat L, Tip C(1), TvaI L, Tva_Art N(5,2), Cont C(20), Cod C(5), Tip_Tert C(1), Cod_Tert C(20), Indice N(1), CodTvaUser C(5), Fel_D C(20), Id_Iesire I, myIndex C(13), IdDocStorno I)
	INDEX ON myIndex TAG myIndex
	INDEX ON Id_Iesire TAG Id_Iesire
	CREATE CURSOR JurnalV_Det (Id_Iesire I, Id_Nota I, Data D, Ndp C(16), Explicatie C(80), Tva_Art N(5,2), Suma N(15,2), Baza_Tva N(15,2), TvaInc N(15,2), Referinta C(5), myIndex C(13), Cod C(5))
	INDEX ON myIndex TAG myIndex
	CREATE CURSOR crsValidationErrors (DocumentType C(20), DocumentId I, IssueDate D, IssueMessage C(254))
ENDPROC

PROCEDURE _ProcessPurchases()
	_GetPurchaseData()
	_Log("Datele primare pentru Cumparari au fost extrase.")
	IF loEnv.oSettings.ModulTvaI
		_GetPreviousPeriodVatOnCollectionPurchases()
		_Log("Facturile cu TVA la încasare din perioadele anterioare au fost adaugate.")
	ENDIF
	_ClassifyPurchases()
	_Log("Clasificarea înregistrarilor de cumparari a fost finalizata (set-based).")

	SELECT Id_Intrare, Data, Data_Doc, Nr, Denumire, Cod_Fisc, Cod, Tva_Art, Tip, NVL(TvaI, .F.) as TvaI, Cod_Tert, Tip_Tert, Indice, ;
		   SUM(Total) As Total, SUM(Baza_Tva) As Baza_Tva, SUM(Tva) As Tva, ;
		   SUM(TotalN) As TotalN, SUM(TotalN-TvaN) As Baza_TvaN, SUM(TvaN) As TvaN, ;
		   SUM(TotalInc) As TotalInc, SUM(TotalInc-TvaInc) As Baza_TvaInc, SUM(TvaInc) As TvaInc, ;
		   CodTvaUser, Fel_D, Curs, Tip_Ded, Cont ;
	FROM JC_Intermed ;
	GROUP BY Id_Intrare, Data, Data_Doc, Nr, Denumire, Cod_Fisc, Cod, Tva_Art, Tip, TvaI, Cod_Tert, Tip_Tert, Indice, CodTvaUser, Fel_D, Curs, Tip_Ded, Cont ;
	ORDER BY Data ;
	INTO CURSOR JCump READWRITE
	_Log("Gruparea finala a datelor de cumparari (JCump) a fost realizata.")

	IF NOT loEnv.lOnlyInvoice
		_ProcessMiscPurchasesFromRegister()
		_Log("Notele contabile diverse (cumparari) au fost procesate.")
	ENDIF

	SELECT Jurnal
	ZAP
	APPEND FROM DBF('JCump')
	REPLACE ALL myIndex WITH ALLTRIM(STR(Tva_Art))+'_'+ALLTRIM(STR(Id_Intrare))
	IF INLIST(loEnv.nTipJurnal, 1, 2)
		DELETE FROM Jurnal WHERE Tip_Ded <> IIF(loEnv.nTipJurnal=1, "100", "50")
		_Log("Filtrul de deductibilitate (" + IIF(loEnv.nTipJurnal=1, "100%", "50%") + ") a fost aplicat.")
	ENDIF
	IF loEnv.oSettings.ModulTvaI
		_CalculateVatOnCollectionPurchases()
		_Log("Calculul final pentru TVA la încasare (cumparari) a fost efectuat.")
	ENDIF
ENDPROC

PROCEDURE _ProcessSales()
	_GetSalesData()
	_Log("Datele primare pentru Vânzări au fost extrase.")
	IF loEnv.oSettings.ModulTvaI
		_GetPreviousPeriodVatOnCollectionSales()
		_Log("Facturile cu TVA la încasare din perioadele anterioare (vânzări) au fost adăugate.")
	ENDIF
	_ClassifySales()
	_Log("Clasificarea înregistrărilor de vânzări a fost finalizată (set-based).")
	IF NOT loEnv.lOnlyInvoice
		_ProcessMiscSalesFromRegister()
		_Log("Notele contabile diverse (vânzări) au fost procesate.")
	ENDIF
	SELECT Id_Iesire, Data, Data90, Data_Doc, Nr, CAST(Denumire As C(80)) As Denumire, Cod_Fisc, Cod, Tva_Art, Tip, ;
		   TvaI, Tip_Tert, Cod_Tert, Indice, SUM(Total) As Total, SUM(Baza_Tva) As Baza_Tva, SUM(Tva) As Tva, ;
		   SUM(TotalN) As TotalN, SUM(Baza_TvaN) As Baza_TvaN, SUM(TvaN) As TvaN, SUM(TotalInc) As TotalInc, ;
		   SUM(Baza_TvaInc) As Baza_TvaInc, SUM(TvaInc) As TvaInc, CodTvaUser, CAST(Fel_D As C(20)) As Fel_D, ;
		   CAST('' As C(30)) As MyIndex, IdDocStorno, Cont ;
	FROM JV_Intermed ;
	GROUP BY Id_Iesire, Data, Data90, Data_Doc, Nr, Denumire, Cod_Fisc, Cod, Tva_Art, Tip, TvaI, Tip_Tert, Cod_Tert, Indice, CodTvaUser, Fel_D, IdDocStorno, Cont ;
	ORDER BY Data ;
	INTO CURSOR JVanz READWRITE
	_Log("Gruparea finală a datelor de vânzări (JVanz) a fost realizată.")
	SELECT JurnalV
	ZAP
	APPEND FROM DBF('JVanz')
	REPLACE ALL myIndex WITH ALLTRIM(STR(Tva_Art))+'_'+ALLTRIM(STR(Id_Iesire))
	IF loEnv.oSettings.ModulTvaI
		_CalculateVatOnCollectionSales()
		_Log("Calculul final pentru TVA la încasare (vânzări) a fost efectuat.")
	ENDIF
ENDPROC

PROCEDURE _Cleanup()
	IF USED("Jurnal"); USE IN Jurnal; ENDIF
	IF USED("Jurnal_Det"); USE IN Jurnal_Det; ENDIF
	IF USED("JurnalV"); USE IN JurnalV; ENDIF
	IF USED("JurnalV_Det"); USE IN JurnalV_Det; ENDIF
	IF USED("crsValidationErrors"); USE IN crsValidationErrors; ENDIF
	IF USED("JC_Intermed"); USE IN JC_Intermed; ENDIF
	IF USED("JV_Intermed"); USE IN JV_Intermed; ENDIF
ENDPROC

PROCEDURE _Log(tcMessage As String, tlIsFinal As Boolean)
	LOCAL lcLogLine As String
	tlIsFinal = IIF(VARTYPE(tlIsFinal)='L', tlIsFinal, .F.)
	IF tlIsFinal
		lcLogLine = tcMessage
	ELSE
		lcLogLine = TRANSFORM(SECONDS()-loEnv.nStartTime, "999.9999") + "s (" + ;
		            TRANSFORM(SECONDS()-loEnv.nLastTime, "999.9999") + "s) | " + tcMessage
		loEnv.nLastTime = SECONDS()
	ENDIF
	STRTOFILE(lcLogLine + CHR(13)+CHR(10), loEnv.cLogFile, 1)
ENDPROC

FUNCTION _ValidateJournals()
	LOCAL loResult As Object
	loResult = CREATEOBJECT("EMPTY")
	ADDPROPERTY(loResult, "HasErrors", .F.)
	SELECT Jurnal
	SCAN FOR ISNULL(Tva_Art)
		INSERT INTO crsValidationErrors (DocumentType, DocumentId, IssueDate, IssueMessage) VALUES ("Achiziție", Id_Intrare, Data, "Înregistrare fără procent TVA.")
		loResult.HasErrors = .T.
	ENDSCAN
	SCAN FOR ISNULL(Tip_Tert)
		INSERT INTO crsValidationErrors (DocumentType, DocumentId, IssueDate, IssueMessage) VALUES ("Achiziție", Id_Intrare, Data, "Tipul terțului este neidentificat.")
		loResult.HasErrors = .T.
	ENDSCAN
	SELECT JurnalV
	SCAN FOR ISNULL(Tva_Art)
		INSERT INTO crsValidationErrors (DocumentType, DocumentId, IssueDate, IssueMessage) VALUES ("Vânzare", Id_Iesire, Data, "Înregistrare fără procent TVA.")
		loResult.HasErrors = .T.
	ENDSCAN
	RETURN loResult
ENDFUNC

PROCEDURE _GetPurchaseData()
	LOCAL lcSQL As String
	TEXT TO lcSQL NOSHOW TEXTMERGE PRETEXT 15
		SELECT I.IdUnic AS Id_Intrare, I.DataDoc AS Data, ISNULL(I.DataDocReala, I.DataDoc) AS Data_Doc, I.NumarDoc AS Nr, F.Denumire, F.Cod_Fiscal AS Cod_Fisc, F.Tip_Tert, F.Cont AS Cod_Tert, ISNULL(ID.Valoare + ID.Tva, 0) AS Total, ID.Valoare AS Baza_Tva, ID.Tva, CASE I.Tip WHEN 2 THEN 'A' WHEN 3 THEN 'T' WHEN 8 THEN 'B' WHEN 9 THEN 'C' WHEN 10 THEN 'E' WHEN 11 THEN 'U' WHEN 12 THEN 'H' WHEN 13 THEN 'O' WHEN 14 THEN 'Z' WHEN 15 THEN 'Q' ELSE '' END AS Tip, I.IsTvaIncasare AS TvaI, CAST(1 AS NUMERIC(14,4)) AS Curs, ISNULL(ID.ProcTva, 0) AS Tva_Art, ID.Cont, 1 AS Indice, ID.PreTvanzare AS Pret_Vanz, ID.CodTva AS CodTvaUser, 'Intrari' AS Fel_D, A.CodNc, ISNULL(ID.Tip_Ded, '') AS Tip_Ded
		FROM Intrari I WITH(NOLOCK) INNER JOIN IntrariDetaliat ID WITH(NOLOCK) ON I.IdDoc = ID.IdDoc INNER JOIN Conturi F WITH(NOLOCK) ON I.Cont = F.Cont AND LEFT(F.Cont, 2) IN ('40', '48','39','99', '53', '54', '46') AND ISNULL(F.Sters,0)=0 AND ISNULL(F.TipImpozit, '') IN ('', '0', '2', '3','C', '5') LEFT JOIN Articole A WITH(NOLOCK) ON A.Id = ID.IdArticol
		WHERE I.DataDoc BETWEEN ?loEnv.dData1 AND ?loEnv.dData2 AND ISNULL(I.Sters, 0) = 0 AND ISNULL(ID.Sters, 0) = 0 AND ISNULL(ID.Valoare, 0) <> 0 AND I.Tip <> 2 AND LEFT(ID.Cont, 1) <> '8' AND (?loEnv.nCategorii = 0 OR ISNULL(ID.IdCategorie, 0) = ?loEnv.nCategorii)
	ENDTEXT
	mySQLExec(lcSQL, "JCump1")
	TEXT TO lcSQL NOSHOW TEXTMERGE PRETEXT 15
		SELECT IM.IdUnic AS Id_Intrare, IM.DataDoc AS Data, ISNULL(IM.DataDocReala, IM.DataDoc) AS Data_Doc, IM.NumarDoc AS Nr, F.Denumire, F.Cod_Fiscal AS Cod_Fisc, F.Tip_Tert, F.Cont AS Cod_Tert, CASE WHEN F.Tip_Tert='3' THEN ROUND(ISNULL(ID.ValoareLei,0)+ISNULL(ID.TransportLei,0),0) ELSE ISNULL(ID.ValoareLei,0) END + ISNULL(ID.TaxaVamala,0)+ISNULL(ID.ComisionVamal,0)+ISNULL(ID.Accize,0)+ISNULL(ID.TvaLei,0) AS Total, CASE WHEN F.Tip_Tert='3' THEN ROUND(ISNULL(ID.ValoareLei,0)+ISNULL(ID.TransportLei,0),0) ELSE ISNULL(ID.ValoareLei,0) END + ISNULL(ID.TaxaVamala,0)+ISNULL(ID.ComisionVamal,0)+ISNULL(ID.Accize,0) AS Baza_Tva, ID.TvaLei AS Tva, IM.Tip, IM.IsTvaIncasare AS TvaI, IM.Curs, ID.ProcTva AS Tva_Art, ID.Cont, 3 AS Indice, CAST(0 AS NUMERIC(15,4)) AS Pret_Vanz, ID.CodTva AS CodTvaUser, 'Import' AS Fel_D, CAST('' AS CHAR(8)) AS CodNc, ISNULL(ID.Tip_Ded, '') AS Tip_Ded
		FROM Import IM WITH(NOLOCK) INNER JOIN ImportDetaliat ID WITH(NOLOCK) ON IM.IdDoc = ID.IdDoc INNER JOIN Conturi F WITH(NOLOCK) ON IM.Cont=F.Cont AND LEFT(F.Cont,2) IN ('40','48','39','99', '53', '46') AND ISNULL(F.Sters,0)=0 AND ISNULL(F.TipImpozit, '') IN ('', '0', '2', '3', 'C')
		WHERE IM.DataDoc BETWEEN ?loEnv.dData1 AND ?loEnv.dData2 AND ISNULL(IM.Sters, 0) = 0 AND ISNULL(ID.Sters, 0) = 0 AND ISNULL(ID.ValoareLei, 0) <> 0 AND LEFT(ID.Cont, 1) <> '8' AND IM.Tip NOT IN ('A', 'n') AND (?loEnv.nCategorii = 0 OR ISNULL(ID.IdCategorie, 0) = ?loEnv.nCategorii)
	ENDTEXT
	mySQLExec(lcSQL, "JCump3")
	TEXT TO lcSQL NOSHOW TEXTMERGE PRETEXT 15
		SELECT T.IdImport, T.IdUnic AS Id_Intrare, T.DataDoc AS Data, ISNULL(T.DataDocReala, T.DataDoc) AS Data_Doc, T.NumarDoc AS Nr_Intrare, T.Total, T.Tva, T.Tip, T.Cont, SPACE(3) as Tip_Ded, T.IsTvaIncasare, CASE WHEN ISNULL(T.Curs, 0)=0 THEN 1 ELSE T.Curs END AS Curs
		FROM ImportTransport T WITH(NOLOCK) WHERE T.DataDoc BETWEEN ?loEnv.dData1 AND ?loEnv.dData2 AND ISNULL(T.Sters,0)=0
	ENDTEXT
	mySQLExec(lcSQL, "Intrari_Asoc")
	mySQLExec("SELECT Cont, Denumire, Cod_Fiscal, Tip_Tert FROM Conturi WHERE Left(Cont, 2) In ('40','48','39','99', '53', '46') AND ISNULL(Sters,0)=0 AND IsNull(TipImpozit, '')<>'5'", "Furnizori_Tr")
	SELECT T.Id_Intrare, T.Data, T.Data_Doc, T.Nr_Intrare AS Nr, F.Denumire, F.Cod_Fiscal AS Cod_Fisc, F.Tip_Tert, F.Cont AS Cod_Tert, T.Total, T.Total-T.Tva AS Baza_Tva, T.Tva,;
		   T.Tip, T.IsTvaIncasare AS TvaI, T.Curs, IIF(T.Tva<>0, GetProcTva(T.Data), 0) AS Tva_Art, '623' AS Cont, 4 AS Indice, 0.00 AS Pret_Vanz,;
		   SPACE(5) AS CodTvaUser, ICASE(INLIST(F.Tip_Tert, '', '1'), 'Intrari', 'Import') AS Fel_D, CAST('' AS C(8)) AS CodNc, NVL(T.Tip_Ded, '') as Tip_Ded;
	FROM Intrari_Asoc T INNER JOIN Furnizori_Tr F ON T.Cont = F.Cont;
	WHERE F.Tip_Tert <> '3' AND (T.Tva <> 0 OR T.IdImport NOT IN (SELECT Id_Intrare FROM JCump3 WHERE JCump3.Tip_Tert='3'));
	INTO CURSOR JCump4 READWRITE
	SELECT *, CAST('     ' AS CHAR(5)) AS Cod, CAST(0.00 AS NUMERIC(15,2)) AS TotalN, CAST(0.00 AS NUMERIC(15,2)) AS Baza_TvaN, CAST(0.00 AS NUMERIC(15,2)) AS TvaN, CAST(0.00 AS NUMERIC(15,2)) AS TotalInc, CAST(0.00 AS NUMERIC(15,2)) AS Baza_TvaInc, CAST(0.00 AS NUMERIC(15,2)) AS TvaInc, CAST(.F. AS LOGICAL) as Preluat FROM JCump1 ;
	UNION ALL ;
	SELECT *, CAST('     ' AS CHAR(5)) AS Cod, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, .F. FROM JCump3 ;
	UNION ALL ;
	SELECT *, CAST('     ' AS CHAR(5)) AS Cod, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, .F. FROM JCump4 ;
	ORDER BY 2 INTO CURSOR JC_Intermed READWRITE
	INDEX ON Id_Intrare TAG Id_Intrare
ENDPROC

PROCEDURE _GetPreviousPeriodVatOnCollectionPurchases()
ENDPROC

PROCEDURE _ClassifyPurchases()
	SELECT JC_Intermed
	REPLACE ALL Cod WITH ICASE(TvaI, ICASE(INLIST(Tva_Art, loEnv.nCotaStd, 20, 21, 24), JCODE_C_TVA_INCASARE_STD, INLIST(Tva_Art, loEnv.nCotaRed1, 11), JCODE_C_TVA_INCASARE_RED1, INLIST(Tva_Art, loEnv.nCotaRed2), JCODE_C_TVA_INCASARE_RED2, Tva_Art = 0, JCODE_C_SCUTIT, Cod ), INLIST(Tip_Tert, ' ', '1', '3') OR Tip='H', ICASE(INLIST(Tip, 'T', 'E') AND Tip_Tert='3', JCODE_C_TAX_INV_EXTRA, INLIST(Tip, 'T', 'E') AND Tip_Tert<>'3', ICASE(Tva_Art = 5, '29-30', INLIST(Tva_Art, loEnv.nCotaRed1, 11), '27-28', JCODE_C_TAX_INV_RO), INLIST(Tva_Art, loEnv.nCotaRed2), JCODE_C_RED2, INLIST(Tva_Art, loEnv.nCotaRed1, 11), JCODE_C_RED1, Tva_Art > 0, JCODE_C_STD, JCODE_C_SCUTIT ), Tip_Tert='2', ICASE(Tva_Art > 0 AND INLIST(Cont, '3', '20', '21', '22', '23', '60', '4091', '4093'), JCODE_C_AIC_BUNURI, Tva_Art > 0, JCODE_C_TAX_INV_EXTRA, Tva_Art = 0 AND INLIST(Cont, '3', '21', '22', '23', '60', '4091', '4093', '625', '471'), JCODE_C_AIC_SCUTIT, '13' ), Cod )
	REPLACE ALL CodTvaUser WITH Cod FOR Indice=4
ENDPROC

PROCEDURE _ProcessMiscPurchasesFromRegister()
	LOCAL lcSQL
	TEXT TO lcSQL NOSHOW TEXTMERGE PRETEXT 15
		Select
			R.Data,
			ISNULL(R.Data, R.Data) AS Data_Doc,
			R.Ndp, R.Suma,
			LTRIM(RTRIM(ISNULL(C.Denumire, ''))) + ' ' + LTRIM(RTRIM(ISNULL(R.Explicatie, ''))) AS Explicatie,
			R.ContC AS Cod_Tert,
			ISNULL(C.Cod_Fiscal, '') AS Cod_Fiscal,
			R.Fel_D,
			R.Id_Nota AS Id_Intrare,
			Cast(0 As Numeric(12, 2)) As Baza_Tva_Calc,
			Cast(0 As Numeric(12, 2)) As Cota_Tva_Calc,
			Cast(0 As Numeric(2)) As ProcTva,
			Cast('' As Char(8)) As CodTva
		FROM Registru R WITH(NOLOCK)
			LEFT JOIN Conturi C WITH(NOLOCK) ON R.ContC = C.Cont
			LEFT JOIN (
				SELECT DISTINCT IdUnic FROM Intrari WITH(NOLOCK) WHERE ISNULL(Sters,0)=0 AND LEFT(NumarDoc,4)<>'Sold'
				UNION
				SELECT DISTINCT IdUnic FROM Import WITH(NOLOCK) WHERE ISNULL(Sters,0)=0 AND LEFT(NumarDoc,4)<>'Sold'
				)  AS Docs ON R.Id_Nota = Docs.IdUnic
		WHERE
			R.ContD = ?loEnv.oConturi.TvaD
			AND R.Data BETWEEN ?loEnv.dData1 AND ?loEnv.dData2
			AND UPPER(LEFT(R.Fel_D, 2)) <> 'TR'
			AND UPPER(LEFT(R.Fel_D, 3)) <> 'TVA'
			AND Docs.IdUnic IS NULL
			AND (?loEnv.nCategorii = 0 OR R.IdCategorie = ?loEnv.nCategorii)
	ENDTEXT
	mySQLExec(lcSQL, "TmpSelRegTvaC")
	SELECT TmpSelRegTvaC
	REPLACE ALL Baza_Tva_Calc WITH VAL(SUBSTR(Explicatie, AT('(', Explicatie)+1, AT(')', Explicatie)-AT('(', Explicatie)-1)) FOR '(' $ Explicatie
	REPLACE ALL Baza_Tva_Calc WITH Suma*100/loEnv.nCotaStd+Suma FOR Baza_Tva_Calc=0
	REPLACE ALL Cota_Tva_Calc WITH Suma/(Baza_Tva_Calc-Suma) FOR NVL(Baza_Tva_Calc, 0)<>0
	REPLACE ALL ProcTva WITH loEnv.nCotaStd, CodTva WITH JCODE_C_STD
	REPLACE ALL ProcTva WITH loEnv.nCotaRed1, CodTva WITH JCODE_C_RED1 FOR Cota_Tva_Calc > loEnv.nCotaRed2/100 AND Cota_Tva_Calc < loEnv.nCotaStd/100
	REPLACE ALL ProcTva WITH loEnv.nCotaRed2, CodTva WITH JCODE_C_RED2 FOR Cota_Tva_Calc > 0 AND Cota_Tva_Calc <= loEnv.nCotaRed2/100
	lc_TvaC = loEnv.oConturi.TvaC
	INSERT INTO JCump (Data, Nr, Cod_Tert, Cod_Fisc, Denumire, Total, Baza_Tva, Tva, Cod, Tva_Art, CodTvaUser, Fel_D, Id_Intrare) ;
		SELECT Data, Ndp, Cod_Tert, Cod_Fiscal, Explicatie, IIF(ProcTva<>0, Baza_Tva_Calc, Suma), IIF(ProcTva<>0, Baza_Tva_Calc-Suma, 0), Suma, IIF(Cod_Tert=lc_TvaC, JCODE_C_AIC_BUNURI, CodTva), ProcTva, IIF(Cod_Tert=lc_TvaC, JCODE_C_AIC_BUNURI, CodTva), Fel_D, Id_Intrare FROM TmpSelRegTvaC
ENDPROC

PROCEDURE _CalculateVatOnCollectionPurchases()
	SELECT Jurnal
	REPLACE ALL TvaI WITH .F. FOR ISNULL(TvaI)
	REPLACE TotalInc WITH Total, Baza_TvaInc WITH Baza_Tva, TvaInc WITH Tva FOR INLIST(Cod, '15-16', '17-18', '10')
	REPLACE TotalN WITH 0, Baza_TvaN WITH 0, TvaN WITH 0, TotalInc WITH Total, Baza_TvaInc WITH Baza_Tva, TvaInc WITH Tva FOR NOT TvaI
	IF loEnv.cDbName='SCECOSALSERVICIIOLTENITASRL'
		REPLACE TotalInc WITH 0, Baza_TvaInc WITH 0, TvaInc WITH 0 FOR NOT EMPTY(Tip_Ded)
	ENDIF
	IF loEnv.oSettings.ModulTvaI
		REPLACE TvaN WITH Tva-DescFact(Id_Intrare, 2, Tva_Art, loEnv.dData2), Baza_TvaN WITH GetBazaTva(TvaN, Tva_Art), TotalN WITH Baza_TvaN+TvaN FOR TvaI AND Tva_Art <> 0
		REPLACE TvaN WITH TvaN/2 FOR TvaN>0 AND Tip_Ded='50'
		REPLACE TvaN WITH 0 FOR TvaN>0 AND Tip_Ded='100'
		REPLACE TotalInc WITH 0, Baza_TvaInc WITH 0, TvaInc WITH 0, TotalN WITH Total, Baza_TvaN WITH Baza_Tva, TvaN WITH Tva FOR TvaI AND Total<0
		REPLACE TotalN WITH 0, Baza_TvaN WITH 0, TvaN WITH 0 FOR ABS(TotalN)<=0.06
	ENDIF
ENDPROC

PROCEDURE _GetSalesData()
	LOCAL lcSQL AS STRING
	TEXT TO lcSQL NOSHOW TEXTMERGE PRETEXT 15
		SELECT ID.IdUnic AS Id_Iesire, ID.DataDoc AS Data, ISNULL(ID.DataDocReala, ID.DataDoc) AS Data_Doc, CASE WHEN ID.DataDoc <= '2013-10-02' THEN DATEADD(day, 90, ID.DataDoc) ELSE DATEADD(day, 9999, ID.DataDoc) END AS Data90, ID.NumarDoc AS Nr, C.Denumire, C.Cod_Fiscal AS Cod_Fisc, C.Tip_Tert, C.Cont AS Cod_Tert, ISNULL(D.Valoare+D.Tva, 0) AS Total, ISNULL(D.Valoare,0) AS Baza_Tva, ISNULL(D.Tva, 0) AS Tva, CASE WHEN D.CodTva='10' THEN 'T' ELSE ISNULL(ID.Tip, '') END AS Tip, ID.IsTvaIncasare AS TvaI, CAST(1 AS NUMERIC(14,4)) AS Curs, ISNULL(D.ProcTva,0) AS Tva_Art, D.Cont, 1 AS Indice, D.CodTva AS CodTvaUser, 'Iesiri' AS Fel_D, A.CodNc, ISNULL(ID.IdDocStorno, 0) AS IdDocStorno
		FROM IesiriDetaliat D WITH(NOLOCK) JOIN Iesiri ID WITH(NOLOCK) ON D.IdDoc=ID.IdDoc JOIN Conturi C WITH(NOLOCK) ON ID.Cont=C.Cont AND LEFT(C.Cont,2) IN ('41', '48', '53', '46') AND ISNULL(C.Sters,0)=0 LEFT JOIN Articole A WITH(NOLOCK) ON A.Id=D.IdArticol
		WHERE ID.DataDoc BETWEEN ?loEnv.dData1 AND ?loEnv.dData2 AND ISNULL(ID.Tip,'') NOT IN ('A') AND LEFT(D.Cont, 1)<>'8' AND (?loEnv.nCategorii=0 OR ISNULL(D.IdCategorie, 0)=?loEnv.nCategorii) AND ISNULL(ID.Anulat, 0)=0 AND ISNULL(D.Valoare, 0) <> 0
	ENDTEXT
	=mySQLExec(lcSQL, "JVanz1")
	SELECT *, '     ' AS Cod, 0.00 AS TotalN, 0.00 AS Baza_TvaN, 0.00 AS TvaN, 0.00 AS TotalInc, 0.00 AS Baza_TvaInc, 0.00 AS TvaInc, .F. AS Preluat, .F. AS Limita90 FROM JVanz1 INTO CURSOR JV_Intermed READWRITE
	INDEX ON Id_Iesire TAG Id_Iesire
ENDPROC

PROCEDURE _GetPreviousPeriodVatOnCollectionSales()
ENDPROC

PROCEDURE _ClassifySales()
	SELECT JV_Intermed
	REPLACE ALL Cod WITH ICASE(TvaI AND NOT INLIST(NVL(CodTvaUser, ''), '27-28', '29-30', '31-32'), ICASE(INLIST(Tva_Art, loEnv.nCotaStd, 20, 19, 21), JCODE_V_TVA_INCASARE_STD, INLIST(Tva_Art, loEnv.nCotaRed1, 11), JCODE_V_TVA_INCASARE_RED1, INLIST(Tva_Art, loEnv.nCotaRed2), JCODE_V_TVA_INCASARE_RED2, Tva_Art=0, JCODE_V_SCUTIT_FD, Cod ), INLIST(Tva_Art, loEnv.nCotaStd, 20, 19, 21), IIF(Tip='T' AND INLIST(Indice, 4, 5), JCODE_V_TAX_INV, IIF(Tip="Y", "27-28", JCODE_V_STD)), INLIST(Tva_Art, loEnv.nCotaRed1, 11), IIF(Tip='T' AND INLIST(Indice, 4, 5), JCODE_V_TAX_INV, JCODE_V_RED1), Tva_Art=5, IIF(Tip='T' AND INLIST(Indice, 4, 5), JCODE_V_TAX_INV, JCODE_V_RED2), Tva_Art=0, ICASE(Tip='T' OR INLIST(Tip, 'S', 'U', 'H', 'D', 'd') OR NVL(CodTvaUser, '')='16', JCODE_V_SCUTIT_DD, INLIST(Tip, 'N', 'n'), JCODE_V_EXTERN, Tip_Tert='2', IIF(INLIST(Cont, '701','702','703','707','7583'), JCODE_V_LIC_BUNURI, JCODE_V_LIC_SERV), Tip_Tert='3', JCODE_V_SCUTIT_DD, NVL(CodTvaUser, JCODE_V_SCUTIT_FD) ), Cod )
ENDPROC

PROCEDURE _ProcessMiscSalesFromRegister()
ENDPROC

PROCEDURE _CalculateVatOnCollectionSales()
	SELECT JurnalV
	REPLACE ALL TvaI WITH .F. FOR ISNULL(TvaI)
	IF loEnv.oSettings.ModulTvaI
		REPLACE TotalInc WITH Total, Baza_TvaInc WITH Baza_Tva, TvaInc WITH Tva FOR Cod=JCODE_V_TAX_INV
		REPLACE TotalN WITH 0, Baza_TvaN WITH 0, TvaN WITH 0, TotalInc WITH Total, Baza_TvaInc WITH Baza_Tva, TvaInc WITH Tva FOR NOT TvaI
		REPLACE TotalN WITH Total-TotalInc, Baza_TvaN WITH Baza_Tva-Baza_TvaInc, TvaN WITH Tva-TvaInc FOR TvaI AND Total >= 0
		REPLACE TotalN WITH 0, Baza_Tvan WITH 0, Tvan WITH 0 FOR TvaI AND ( Tva_Art=0 OR INLIST(CodTvaUser, '27-28', '29-30', '31-32') )
		REPLACE TotalN WITH 0, Baza_TvaN WITH 0, TvaN WITH 0 FOR ABS(TotalN)<0.05
	ENDIF
ENDPROC
