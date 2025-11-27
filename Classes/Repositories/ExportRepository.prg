******************************************************************************************
*  CLASS: ExportRepository
*
*  AUTHOR: Refactored OOP Architecture
*
*  DESCRIPTION:
*     Repository concret pentru facturi din tabela Export.
*     Implementeaza IInvoiceRepository pentru accesul la date din Export.
*
*  DESIGN PATTERN: Repository Pattern
*
******************************************************************************************

Define Class ExportRepository As IInvoiceRepository
	
	cName = "ExportRepository"
	cDataType = "Export"
	
	*-- Referinta la ICAS (daca exista)
	lIsICAS = .F.
	oICAS = .Null.
	
	*---------------------------------------------------------------------------
	* Procedura: Init
	* Descriere: Initializeaza repository-ul
	*---------------------------------------------------------------------------
	Procedure Init()
		This.lIsICAS = (VarType(ICAS) = 'O' And Not IsNull(ICAS))
		If This.lIsICAS
			This.oICAS = ICAS
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: GetById
	* Descriere: Obtine o factura dupa ID
	* Parametri: 
	*   tnId - ID-ul facturii
	* Returneaza: Object - Obiectul factura sau .Null.
	*---------------------------------------------------------------------------
	Function GetById(tnId)
		Local lcSQL
		
		If Not This.lIsICAS
			Return .Null.
		EndIf
		
		Text To lcSQL NoShow TextMerge
			SELECT *
			FROM Export
			WHERE IdUnic = ?tnId
		EndText
		
		mySQLExec(lcSQL, "crsExport_Single")
		
		If Used("crsExport_Single") And RecCount("crsExport_Single") > 0
			Return This.CursorToObject("crsExport_Single")
		EndIf
		
		Return .Null.
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetByNumber
	* Descriere: Obtine o factura dupa numar
	* Parametri: 
	*   tcNumar - Numarul facturii
	*   tdData - Data facturii (optional)
	* Returneaza: Object - Obiectul factura sau .Null.
	*---------------------------------------------------------------------------
	Function GetByNumber(tcNumar, tdData)
		Local lcSQL
		
		If Not This.lIsICAS
			Return .Null.
		EndIf
		
		If Empty(tdData)
			Text To lcSQL NoShow TextMerge
				SELECT *
				FROM Export
				WHERE NumarDoc = ?tcNumar
				ORDER BY DataDoc DESC
			EndText
		Else
			Text To lcSQL NoShow TextMerge
				SELECT *
				FROM Export
				WHERE NumarDoc = ?tcNumar
				AND DataDoc = ?tdData
			EndText
		EndIf
		
		mySQLExec(lcSQL, "crsExport_ByNumber")
		
		If Used("crsExport_ByNumber") And RecCount("crsExport_ByNumber") > 0
			Return This.CursorToObject("crsExport_ByNumber")
		EndIf
		
		Return .Null.
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: Save
	* Descriere: Salveaza o factura
	* Parametri: 
	*   toInvoice - Obiectul factura
	*---------------------------------------------------------------------------
	Procedure Save(toInvoice)
		*-- Implementare specifica pentru salvare
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: UpdateStatus
	* Descriere: Actualizeaza statusul unei facturi
	* Parametri: 
	*   tnId - ID-ul facturii
	*   tcStatus - Noul status
	*   tcIdSolicitare - ID-ul solicitarii ANAF
	*---------------------------------------------------------------------------
	Procedure UpdateStatus(tnId, tcStatus, tcIdSolicitare)
		Local lcSQL
		
		If Not This.lIsICAS
			Return
		EndIf
		
		Text To lcSQL NoShow TextMerge
			UPDATE Export
			SET 
				Id_Solicitare = ?tcIdSolicitare,
				BFTiparit = 9
			WHERE
				IdUnic = ?tnId
		EndText
		
		Try
			mySQLExec(lcSQL)
		Catch To loException
			*-- Log eroare
		EndTry
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: GetUnprocessed
	* Descriere: Obtine facturile neprocesate
	* Parametri: 
	*   tdStartDate - Data de inceput
	*   tdEndDate - Data de sfarsit
	* Returneaza: Cursor - Cursor cu facturile
	*---------------------------------------------------------------------------
	Function GetUnprocessed(tdStartDate, tdEndDate)
		Local lcSQL
		
		If Not This.lIsICAS
			Return "crsUnprocessedExport"
		EndIf
		
		Text To lcSQL NoShow TextMerge
			SELECT 
				IdUnic, NumarDoc, DataDoc, Denumire_T, CIF_T, Total
			FROM Export
			WHERE DataDoc BETWEEN ?tdStartDate AND ?tdEndDate
			AND (Id_Solicitare IS NULL OR Id_Solicitare = '')
			AND Anulat = 0
			ORDER BY DataDoc, NumarDoc
		EndText
		
		mySQLExec(lcSQL, "crsUnprocessedExport")
		
		Return "crsUnprocessedExport"
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetForEFactura
	* Descriere: Obtine datele necesare pentru generarea e-Factura
	* Parametri: 
	*   tnIdUnic - ID-ul unic al facturii
	* Returneaza: Cursor - crsEFactura
	*---------------------------------------------------------------------------
	Function GetForEFactura(tnIdUnic)
		*-- Logica specifica pentru Export
		Return "crsEFactura"
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: CursorToObject
	* Descriere: Converteste o inregistrare din cursor in obiect
	* Parametri: 
	*   tcCursor - Numele cursorului
	* Returneaza: Object
	*---------------------------------------------------------------------------
	Protected Function CursorToObject(tcCursor)
		Local loObj, laFields[1], i
		
		loObj = CreateObject("Empty")
		
		Select (tcCursor)
		Go Top
		
		AFields(laFields, tcCursor)
		
		For i = 1 To ALen(laFields, 1)
			AddProperty(loObj, laFields[i, 1], Evaluate(tcCursor + "." + laFields[i, 1]))
		EndFor
		
		Return loObj
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: Destroy
	* Descriere: Curata resursele
	*---------------------------------------------------------------------------
	Procedure Destroy()
		This.oICAS = .Null.
	EndProc
	
EndDefine
