******************************************************************************************
*  CLASS: PersistenceHandler
*
*  AUTHOR: Refactored OOP Architecture
*
*  DESCRIPTION:
*     Handler pentru persistenta datelor - salveaza recipisa, actualizeaza
*     baza de date cu informatiile despre factura transmisa.
*
*  DESIGN PATTERN: Chain of Responsibility
*
*  OPERATIONS:
*     - Salvare recipisa
*     - Actualizare status factura
*     - Salvare istoric operatiuni
*
******************************************************************************************

Define Class PersistenceHandler As AbstractHandler
	
	cName = "PersistenceHandler"
	nOrder = 5
	
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
	* Descriere: Salveaza datele in baza de date
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	*---------------------------------------------------------------------------
	Protected Procedure DoHandle(toContext)
		*-- Actualizeaza statusul facturii
		This.UpdateInvoiceStatus(toContext)
		
		*-- Salveaza in istoric
		This.SaveHistory(toContext)
		
		*-- Finalizeaza contextul
		toContext.Finalize()
		
		This.LogInfo("Persistenta finalizata. Durata totala: " + Transform(toContext.GetDuration()) + "s")
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: UpdateInvoiceStatus
	* Descriere: Actualizeaza statusul facturii in baza de date
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	*---------------------------------------------------------------------------
	Protected Procedure UpdateInvoiceStatus(toContext)
		Local lcAlias, lnIdUnic, lcIdSolicitare, lcRecipisa, lcSQL
		
		lcAlias = toContext.cAlias
		lnIdUnic = toContext.nIdUnicFactura
		lcIdSolicitare = toContext.cIdSolicitare
		lcRecipisa = toContext.cRecipisa
		
		If Empty(lcIdSolicitare)
			*-- Nu s-a obtinut ID solicitare, nu actualizam
			This.LogWarning("Nu exista ID solicitare pentru actualizare status")
			Return
		EndIf
		
		If This.lIsICAS
			*-- Actualizeaza in baza de date ICAS
			This.UpdateInvoiceStatusICAS(lcAlias, lnIdUnic, lcIdSolicitare, lcRecipisa)
		Else
			*-- Actualizeaza in cursor local
			This.UpdateInvoiceStatusLocal(lcAlias, lnIdUnic, lcIdSolicitare, lcRecipisa)
		EndIf
		
		This.LogInfo("Status factura actualizat. ID Solicitare: " + lcIdSolicitare)
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: UpdateInvoiceStatusICAS
	* Descriere: Actualizeaza statusul in ICAS
	* Parametri: 
	*   tcAlias - Alias-ul tabelei
	*   tnIdUnic - ID-ul unic al facturii
	*   tcIdSolicitare - ID-ul solicitarii
	*   tcRecipisa - Recipisa
	*---------------------------------------------------------------------------
	Protected Procedure UpdateInvoiceStatusICAS(tcAlias, tnIdUnic, tcIdSolicitare, tcRecipisa)
		Local lcSQL, lcTable
		
		*-- Determina tabela
		Do Case
			Case tcAlias = "Iesiri"
				lcTable = "Iesiri"
			Case tcAlias = "Export"
				lcTable = "Export"
			Case tcAlias = "Docum"
				lcTable = "Docum"
			Otherwise
				Return
		EndCase
		
		*-- Construieste UPDATE
		Text To lcSQL NoShow TextMerge
			UPDATE <<lcTable>>
			SET 
				Id_Solicitare = ?tcIdSolicitare,
				Recipisa = CASE WHEN ?tcRecipisa <> '' THEN ?tcRecipisa ELSE Recipisa END,
				BFTiparit = 9
			WHERE
				IdUnic = ?tnIdUnic
		EndText
		
		Try
			mySQLExec(lcSQL)
			This.LogDebug("Status actualizat in " + lcTable + " pentru IdUnic=" + Transform(tnIdUnic))
		Catch To loException
			This.LogError("Eroare la actualizare status: " + loException.Message)
		EndTry
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: UpdateInvoiceStatusLocal
	* Descriere: Actualizeaza statusul in cursor local
	* Parametri: 
	*   tcAlias - Alias-ul cursorului
	*   tnIdUnic - ID-ul unic al facturii
	*   tcIdSolicitare - ID-ul solicitarii
	*   tcRecipisa - Recipisa
	*---------------------------------------------------------------------------
	Protected Procedure UpdateInvoiceStatusLocal(tcAlias, tnIdUnic, tcIdSolicitare, tcRecipisa)
		If Not Used(tcAlias)
			This.LogWarning("Cursor-ul " + tcAlias + " nu este deschis")
			Return
		EndIf
		
		Select (tcAlias)
		Locate For IdUnic = tnIdUnic
		
		If Found()
			Replace Id_Solicitare With tcIdSolicitare
			If Not Empty(tcRecipisa)
				Replace Recipisa With tcRecipisa
			EndIf
			This.LogDebug("Status actualizat local pentru IdUnic=" + Transform(tnIdUnic))
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: SaveHistory
	* Descriere: Salveaza in istoricul operatiunilor
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	*---------------------------------------------------------------------------
	Protected Procedure SaveHistory(toContext)
		Local lcOperatiune, lnIdFactura, lcIdSolicitare, lcRecipisa, lcCale
		
		lnIdFactura = toContext.nIdUnicFactura
		lcIdSolicitare = toContext.cIdSolicitare
		lcRecipisa = toContext.cRecipisa
		lcCale = toContext.cXmlFilePath
		
		*-- Determina tipul operatiunii
		If toContext.lIsRectificativa
			If toContext.lIsAutoFactura
				lcOperatiune = "Rectificativa autofactura"
			Else
				lcOperatiune = "Rectificativa"
			EndIf
		ElseIf toContext.lIsAutoFactura
			lcOperatiune = "Transmitere autofactura"
		Else
			lcOperatiune = "Transmitere factura"
		EndIf
		
		*-- Salveaza in istoric
		If This.lIsICAS
			This.SaveHistoryICAS(lnIdFactura, lcOperatiune, lcIdSolicitare, lcRecipisa, lcCale)
		EndIf
		
		This.LogInfo("Istoric salvat: " + lcOperatiune)
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: SaveHistoryICAS
	* Descriere: Salveaza istoricul in ICAS
	* Parametri: 
	*   tnIdFactura - ID-ul facturii
	*   tcOperatiune - Tipul operatiunii
	*   tcIdSolicitare - ID-ul solicitarii
	*   tcRecipisa - Recipisa
	*   tcCale - Calea fisierului
	*---------------------------------------------------------------------------
	Protected Procedure SaveHistoryICAS(tnIdFactura, tcOperatiune, tcIdSolicitare, tcRecipisa, tcCale)
		Local ldData, lnId, lcSQL
		
		ldData = DateTime()
		
		Try
			*-- Obtine un nou ID
			lnId = GetIdUnicSoc()
			
			Text To lcSQL NoShow TextMerge
				INSERT INTO EFA_History
				(Id, Id_Factura, Data, Operatiune, Id_Solicit, Recipisa, Cale)
				VALUES 
				(?lnId, ?tnIdFactura, ?ldData, ?tcOperatiune, ?tcIdSolicitare, ?tcRecipisa, ?tcCale)
			EndText
			
			mySQLExec(lcSQL)
			This.LogDebug("Istoric salvat cu ID=" + Transform(lnId))
		Catch To loException
			This.LogError("Eroare la salvare istoric: " + loException.Message)
		EndTry
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: SaveReceipt
	* Descriere: Salveaza recipisa primita de la ANAF
	* Parametri: 
	*   toContext - Contextul
	*   tcRecipisa - Continutul recipisei
	*---------------------------------------------------------------------------
	Procedure SaveReceipt(toContext, tcRecipisa)
		Local lcPath, lcFileName
		
		lcPath = JustPath(toContext.cXmlFilePath)
		lcFileName = JustStem(toContext.cXmlFilePath) + "_recipisa.xml"
		
		If Not Empty(tcRecipisa)
			StrToFile(tcRecipisa, AddBs(lcPath) + lcFileName)
			toContext.cRecipisa = lcFileName
			This.LogInfo("Recipisa salvata: " + lcFileName)
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Destroy
	* Descriere: Curata resursele
	*---------------------------------------------------------------------------
	Procedure Destroy()
		This.oICAS = .Null.
		DoDefault()
	EndProc
	
EndDefine
