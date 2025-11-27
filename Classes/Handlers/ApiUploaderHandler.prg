******************************************************************************************
*  CLASS: ApiUploaderHandler
*
*  AUTHOR: Refactored OOP Architecture
*
*  DESCRIPTION:
*     Handler pentru comunicarea cu API-ul ANAF pentru upload e-Factura.
*     Gestioneaza autentificarea, upload-ul si procesarea raspunsului.
*
*  DESIGN PATTERN: Chain of Responsibility
*
*  API OPERATIONS:
*     - Upload factura XML
*     - Verificare stare mesaj
*     - Descarcare raspuns
*
******************************************************************************************

Define Class ApiUploaderHandler As AbstractHandler
	
	cName = "ApiUploaderHandler"
	nOrder = 4
	
	*-- Referinta la ConfigProvider
	oConfigProvider = .Null.
	
	*-- Referinta la ICAS (daca exista)
	lIsICAS = .F.
	oICAS = .Null.
	
	*-- Setari API
	cStandard = "UBL"
	lIsProduction = .F.
	
	*-- Timeout pentru HTTP (secunde)
	nTimeout = 60
	
	*-- Numar maxim de reincercari
	nMaxRetries = 3
	
	*---------------------------------------------------------------------------
	* Procedura: Init
	* Descriere: Initializeaza handler-ul
	*---------------------------------------------------------------------------
	Procedure Init()
		DoDefault()
		This.lIsICAS = (VarType(ICAS) = 'O' And Not IsNull(ICAS))
		If This.lIsICAS
			This.oICAS = ICAS
			If PemStatus(This.oICAS, 'oSETTINGS', 5)
				This.lIsProduction = This.oICAS.oSETTINGS.eFactura_Prod
			EndIf
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: CanHandle
	* Descriere: Verifica daca trebuie sa faca upload
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Protected Function CanHandle(toContext)
		*-- Verifica daca fisierul XML exista
		If Empty(toContext.cXmlFilePath) Or Not File(toContext.cXmlFilePath)
			toContext.AddWarning("Fisierul XML nu exista, skip upload")
			Return .F.
		EndIf
		Return .T.
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: DoHandle
	* Descriere: Executa upload-ul catre API ANAF
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	*---------------------------------------------------------------------------
	Protected Procedure DoHandle(toContext)
		Local lcToken, lcResult
		
		*-- Obtine token-ul de autentificare
		lcToken = This.GetAuthToken()
		If Empty(lcToken)
			toContext.SetError("Nu s-a putut obtine token-ul de autentificare. Verificati configurarea SPV.")
			Return
		EndIf
		
		*-- Executa upload-ul
		lcResult = This.UploadInvoice(toContext, lcToken)
		
		*-- Proceseaza rezultatul
		This.ProcessUploadResult(toContext, lcResult)
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: GetAuthToken
	* Descriere: Obtine token-ul de autentificare
	* Returneaza: String - Token-ul sau empty string
	*---------------------------------------------------------------------------
	Protected Function GetAuthToken()
		Local lcToken
		lcToken = ""
		
		If This.lIsICAS
			*-- Preia token-ul din ICAS
			If PemStatus(This.oICAS, 'cToken_SPV', 5)
				lcToken = This.oICAS.cToken_SPV
			EndIf
		EndIf
		
		Return lcToken
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: UploadInvoice
	* Descriere: Incarca factura XML la ANAF
	* Parametri: 
	*   toContext - Contextul
	*   tcToken - Token-ul de autentificare
	* Returneaza: String - Raspunsul API
	*---------------------------------------------------------------------------
	Protected Function UploadInvoice(toContext, tcToken)
		Local lcUrl, lcData, loHttp, lcRaspuns, lcCodFiscal
		Local lnRetry, llSuccess
		
		*-- Construieste URL-ul
		lcCodFiscal = This.GetCodFiscalSocietate()
		lcUrl = This.GetUploadUrl(lcCodFiscal, toContext.cUploadParamExtern)
		
		This.LogInfo("Upload URL: " + lcUrl)
		
		*-- Citeste continutul XML
		lcData = FileToStr(toContext.cXmlFilePath)
		
		*-- Reincercare in caz de esec
		lnRetry = 0
		llSuccess = .F.
		lcRaspuns = ""
		
		Do While lnRetry < This.nMaxRetries And Not llSuccess
			lnRetry = lnRetry + 1
			
			Try
				*-- Creeaza obiectul HTTP
				loHttp = This.CreateHttpObject()
				If IsNull(loHttp)
					This.LogError("Nu s-a putut crea obiectul HTTP")
					Exit
				EndIf
				
				*-- Configureaza cererea
				loHttp.Open("POST", lcUrl, .F.)
				loHttp.SetRequestHeader('Content-Type', 'text/xml')
				loHttp.SetRequestHeader('Authorization', "Bearer " + tcToken)
				
				*-- Trimite cererea
				loHttp.Send(lcData)
				
				*-- Verifica statusul
				If loHttp.Status = 200 Or loHttp.Status = 201
					lcRaspuns = loHttp.ResponseText
					llSuccess = .T.
					This.LogInfo("Upload reusit. Status: " + Transform(loHttp.Status))
				Else
					lcRaspuns = This.HandleHttpError(loHttp)
					This.LogWarning("Upload esuat (incercarea " + Transform(lnRetry) + "): " + lcRaspuns)
				EndIf
				
			Catch To loException
				lcRaspuns = "_error:" + loException.Message
				This.LogError("Exceptie la upload: " + loException.Message)
			EndTry
			
			*-- Elibereaza obiectul HTTP
			loHttp = .Null.
			
			*-- Asteapta inainte de reincercare
			If Not llSuccess And lnRetry < This.nMaxRetries
				This.LogInfo("Se reincearca in 2 secunde...")
				Inkey(2)
			EndIf
		EndDo
		
		Return lcRaspuns
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: CreateHttpObject
	* Descriere: Creeaza obiectul HTTP pentru comunicare
	* Returneaza: Object - Obiectul HTTP sau NULL
	*---------------------------------------------------------------------------
	Protected Function CreateHttpObject()
		Local loHttp
		
		Try
			*-- Incearca mai intai obiectul din ICAS daca exista
			If This.lIsICAS And PemStatus(This.oICAS, 'oHttp_ANAF', 5)
				loHttp = This.oICAS.oHttp_ANAF
			Else
				*-- Creeaza un nou obiect
				loHttp = CreateObject("MSXML2.ServerXMLHTTP.6.0")
			EndIf
		Catch
			Try
				loHttp = CreateObject("MSXML2.XMLHTTP.6.0")
			Catch
				loHttp = .Null.
			EndTry
		EndTry
		
		Return loHttp
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetUploadUrl
	* Descriere: Construieste URL-ul pentru upload
	* Parametri: 
	*   tcCodFiscal - Codul fiscal
	*   tcExtern - Parametru extern (optional)
	* Returneaza: String - URL-ul complet
	*---------------------------------------------------------------------------
	Protected Function GetUploadUrl(tcCodFiscal, tcExtern)
		Local lcBaseUrl, lcUrl
		
		lcBaseUrl = Iif(This.lIsProduction, ;
			"https://api.anaf.ro/prod/FCTEL/rest/upload", ;
			"https://api.anaf.ro/test/FCTEL/rest/upload")
		
		lcUrl = lcBaseUrl + "?"
		lcUrl = lcUrl + "standard=" + This.cStandard
		lcUrl = lcUrl + "&cif=" + AllTrim(tcCodFiscal)
		
		If Not Empty(tcExtern)
			lcUrl = lcUrl + tcExtern  && Deja contine &extern=DA
		EndIf
		
		Return lcUrl
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetCodFiscalSocietate
	* Descriere: Returneaza codul fiscal al societatii
	* Returneaza: String
	*---------------------------------------------------------------------------
	Protected Function GetCodFiscalSocietate()
		If This.lIsICAS And PemStatus(This.oICAS, 'oSoc', 5)
			Return AllTrim(This.oICAS.oSoc.CodFiscal)
		EndIf
		Return ""
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: HandleHttpError
	* Descriere: Proceseaza erorile HTTP
	* Parametri: 
	*   toHttp - Obiectul HTTP
	* Returneaza: String - Mesajul de eroare
	*---------------------------------------------------------------------------
	Protected Function HandleHttpError(toHttp)
		Local lcMesaj
		
		If Empty(toHttp.ResponseText)
			If Lower(AllTrim(toHttp.StatusText)) = "forbidden"
				lcMesaj = "_error:Nu aveti drepturi de incarcare pe acest cod fiscal, sau codul SPV este expirat. Anulati codul curent si generati-l din nou."
			Else
				lcMesaj = "_error:" + AllTrim(toHttp.StatusText) + " (Status: " + Transform(toHttp.Status) + ")"
			EndIf
		Else
			lcMesaj = "_error:" + AllTrim(toHttp.StatusText)
		EndIf
		
		Return lcMesaj
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: ProcessUploadResult
	* Descriere: Proceseaza rezultatul upload-ului
	* Parametri: 
	*   toContext - Contextul
	*   tcRaspuns - Raspunsul API
	*---------------------------------------------------------------------------
	Protected Procedure ProcessUploadResult(toContext, tcRaspuns)
		Local lcIndex, lcError
		
		If Empty(tcRaspuns)
			toContext.SetError("Raspuns gol de la API ANAF")
			Return
		EndIf
		
		*-- Verifica daca e eroare
		If Left(tcRaspuns, 7) = "_error:"
			lcError = SubStr(tcRaspuns, 8)
			toContext.SetError("Eroare la upload: " + lcError)
			Return
		EndIf
		
		*-- Extrage index_incarcare din raspuns
		If 'index_incarcare=' $ tcRaspuns
			lcIndex = StrExtract(tcRaspuns, 'index_incarcare="', '"')
			If Not Empty(lcIndex)
				toContext.cIdSolicitare = lcIndex
				This.LogInfo("Index solicitare obtinut: " + lcIndex)
			EndIf
		ElseIf 'errorMessage=' $ tcRaspuns
			*-- Eroare de la ANAF
			lcError = StrExtract(tcRaspuns, 'errorMessage="', '"')
			toContext.SetError("Eroare ANAF: " + lcError)
		Else
			*-- Alt tip de raspuns
			This.LogWarning("Raspuns neasteptat: " + Left(tcRaspuns, 200))
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: CheckMessageState
	* Descriere: Verifica starea unui mesaj
	* Parametri: 
	*   tcIdSolicitare - ID-ul solicitarii
	*   tcToken - Token-ul de autentificare
	* Returneaza: String - Starea mesajului
	*---------------------------------------------------------------------------
	Function CheckMessageState(tcIdSolicitare, tcToken)
		Local lcUrl, loHttp, lcRaspuns
		
		lcUrl = Iif(This.lIsProduction, ;
			"https://api.anaf.ro/prod/FCTEL/rest/stareMesaj", ;
			"https://api.anaf.ro/test/FCTEL/rest/stareMesaj")
		
		lcUrl = lcUrl + "?id_incarcare=" + AllTrim(tcIdSolicitare)
		
		Try
			loHttp = This.CreateHttpObject()
			loHttp.Open("GET", lcUrl, .F.)
			loHttp.SetRequestHeader('Authorization', "Bearer " + tcToken)
			loHttp.Send()
			
			If loHttp.Status = 200
				lcRaspuns = loHttp.ResponseText
			Else
				lcRaspuns = "_error:" + toHttp.StatusText
			EndIf
		Catch To loException
			lcRaspuns = "_error:" + loException.Message
		EndTry
		
		Return lcRaspuns
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: DownloadMessage
	* Descriere: Descarca un mesaj (raspuns sau factura)
	* Parametri: 
	*   tcIdSolicitare - ID-ul solicitarii
	*   tcToken - Token-ul de autentificare
	* Returneaza: Binary - Continutul ZIP sau empty
	*---------------------------------------------------------------------------
	Function DownloadMessage(tcIdSolicitare, tcToken)
		Local lcUrl, loHttp, lcContent
		
		lcUrl = Iif(This.lIsProduction, ;
			"https://api.anaf.ro/prod/FCTEL/rest/descarcare", ;
			"https://api.anaf.ro/test/FCTEL/rest/descarcare")
		
		lcUrl = lcUrl + "?id=" + AllTrim(tcIdSolicitare)
		
		Try
			loHttp = This.CreateHttpObject()
			loHttp.Open("GET", lcUrl, .F.)
			loHttp.SetRequestHeader('Authorization', "Bearer " + tcToken)
			loHttp.Send()
			
			If loHttp.Status = 200
				lcContent = loHttp.ResponseBody
			Else
				lcContent = ""
			EndIf
		Catch To loException
			lcContent = ""
		EndTry
		
		Return lcContent
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: SetConfig
	* Descriere: Seteaza configurarea
	* Parametri: 
	*   toConfig - Obiectul ConfigProvider
	*---------------------------------------------------------------------------
	Procedure SetConfig(toConfig)
		DoDefault(toConfig)
		This.oConfigProvider = toConfig
		If VarType(toConfig) = 'O' And Not IsNull(toConfig)
			This.lIsProduction = toConfig.lIsProduction
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Destroy
	* Descriere: Curata resursele
	*---------------------------------------------------------------------------
	Procedure Destroy()
		This.oICAS = .Null.
		This.oConfigProvider = .Null.
		DoDefault()
	EndProc
	
EndDefine
