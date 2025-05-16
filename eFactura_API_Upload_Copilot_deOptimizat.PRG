Function eFactura_API_Upload(XMLFileName, Token, tlProd, tc_Upload_Param_Extern, tlcURL, tcCIF, tc_Tip_Raportare)
	
	If Empty(tc_Upload_Param_Extern)
		tc_Upload_Param_Extern = ''
	EndIf	
	
	*Return EFA__Chilkat_Publicare(XMLFileName, Token, tlProd, tc_Tip_Raportare)
	
	
	
	Local oSetAlternate As Object, oSetConsole As Object, oSetSafety As Object, oSetCentury As Object
	oSetConsole=CreateObject("SetConsole", 'Off')
	oSetAlternate=CreateObject("SetAlternate", "On", lcCale_LOG+Program()+".log")	&& , "ADDITIVE"
	?"==============================="
	? Program()
	? "PARAMETERS:"
	? "XMLFileName", XMLFileName
	? "tlcURL ", Transform(tlcURL)
	? "tcCIF", tcCIF
	?
	*
	If tlcURL
		=StrToFile('curl -k -s --location --request POST "https://api.anaf.ro/'+IIf(ICAS.oSettings.eFactura_Prod,'prod','test')+'/FCTEL/rest/upload?standard=UBL&cif='+OnlyNumber(ICAS.oSoc.CodFiscal)+tc_Upload_Param_Extern+ '" --header "Authorization: Bearer '+AllTrim(m.Token)+'" --header "Content-Type: application/xml" -d @"'+m.XMLFileName+'" -o rasp.txt 2>&1','eFacturaUpload.bat')
		Run eFacturaUpload.bat
		* Delete File eFacturaUpload.bat
		If  .Not. File('rasp.txt')
			= MessageBox('Conectarea la srv. ANAF a esuat, asigurati-va ca aveti conexiunea la internet functionala !', 16, 'Eroare', 3000)
			Return
		EndIf
		*
		m.lcXml = FileToStr('rasp.txt')
		? "m.lcXml", m.lcXml
		*
	Else
		*
		If tlProd
			*lcServer=https://webserviceapl.anaf.ro/prod/FCTEL/rest/upload?standard=UBL
			lcServer='https://api.anaf.ro/prod/FCTEL/rest/upload?standard=UBL'
		Else
			*lcServer=https://webserviceapl.anaf.ro/test/FCTEL/rest/upload?standard=UBL
			lcServer='https://api.anaf.ro/test/FCTEL/rest/upload?standard=UBL'
		EndIf
		*
		If tc_Tip_Raportare = 'B2C'
			lcServer = StrTran(lcServer, 'upload', 'uploadb2c')
		EndIf
		*
		If Not Empty(tcCIF)
			lcServer=lcServer+'&cif='+OnlyNumber(AllTrim(tcCIF))+tc_Upload_Param_Extern
		Else
			lcServer=lcServer+'&cif='+OnlyNumber(AllTrim(ICAS.oSoc.CodFiscal))+tc_Upload_Param_Extern
		EndIf
		*
		*if (isExtern)
		*{
		*	text += "&extern=DA";
		*}
		? "tlProd ", Transform(tlProd)
		? "lcServer ", lcServer
		m.lcXml=''
		lcSend=FileToStr(XMLFileName)
		loHttp=_GetObject('http')
		*
		With loHttp
			.Open('POST', lcServer, .F.)
			.SetRequestHeader("Authorization","Bearer " + Token)
			.Send(lcSend)				&& cand este cazut e-Factura da eroare
			lc_Status=.StatusText
			lc_Response=.GetAllResponseHeaders()
			m.lcXml=.ResponseText
			? "loHttp.StatusText ", lc_Status
			? "loHttp.GetAllResponseHeaders() ", lc_Response
			? "loHttp.ResponseText ", m.lcXml
		EndWith	
		*
	EndIf
	*
	Local loReturn As Object
	loReturn=CreateObject('SmallClass')
	? "loReturn ", Transform(loReturn)
	loReturn.AddProperty('xml', m.lcXml)
	*
	If '<?xml'$m.lcXml
		Local loXmlDom As Microsoft.XMLDOM, oheader As Object
		
		loXmlDom = CreateObject("Microsoft.XMLDOM")
		loXmlDom.ASync = .F.
		loXmlDom.LoadXML(m.lcXml)
		oheader=loXmlDom.SelectSingleNode("//header")
		*
		For Each oAttribute In oheader.Attributes
			?oAttribute.NodeName, oAttribute.Text
			loReturn.AddProperty(oAttribute.NodeName, oAttribute.Text)
		Next
		*?oheader.Attributes.GetNamedItem("index_incarcare").Text
	EndIf	
	*
	If _VFP.StartMode=0
		*Activate Screen
		? "loReturn.xml ", loReturn.xml
		?
		*DebugOut Program(), 'loReturn.xml', loReturn.xml
	EndIf
	*
	?"==============================="
	?
	Return loReturn
EndFunc