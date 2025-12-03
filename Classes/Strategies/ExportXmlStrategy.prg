******************************************************************************************
*  CLASS: ExportXmlStrategy
*
*  AUTHOR: Refactored OOP Architecture
*
*  DESCRIPTION:
*     Strategie concreta pentru generarea XML pentru export.
*     Implementeaza regulile specifice pentru facturi de export (categoria G).
*
*  DESIGN PATTERN: Strategy Pattern
*
******************************************************************************************

Define Class ExportXmlStrategy As XmlGeneratorStrategy
	
	cName = "ExportXmlStrategy"
	cTipRaportare = "EXPORT"
	
	*---------------------------------------------------------------------------
	* Functie: Generate
	* Descriere: Genereaza XML-ul pentru export
	* Parametri: 
	*   toContext - Contextul procesarii
	* Returneaza: String - Continutul XML
	*---------------------------------------------------------------------------
	Function Generate(toContext)
		Return ""
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetTaxCategoryForLine
	* Descriere: Determina categoria TVA pentru export
	* Parametri: 
	*   toContext - Contextul
	*   tnProcTva - Procentul TVA
	*   tcCodTva - Codul TVA
	* Returneaza: String - Categoria
	*---------------------------------------------------------------------------
	Function GetTaxCategoryForLine(toContext, tnProcTva, tcCodTva)
		*-- Pentru export, de obicei e G (Free export item)
		*-- sau K pentru livrari intracomunitare
		
		If toContext.cTara = "RO"
			*-- Nu e export, verificam daca e intracomunitar
			Return "S"
		Else
			*-- Verificam daca e tara UE sau nu
			If This.IsEUCountry(toContext.cTara)
				Return "K"  && Livrare intracomunitara
			Else
				Return "G"  && Export in afara UE
			EndIf
		EndIf
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: IsEUCountry
	* Descriere: Verifica daca o tara e in UE
	* Parametri: 
	*   tcCountryCode - Codul tarii
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Function IsEUCountry(tcCountryCode)
		Local lcCode
		lcCode = Upper(AllTrim(tcCountryCode))
		
		*-- Lista tarilor UE
		Return InList(lcCode, ;
			"AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", ;
			"DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL", ;
			"PL", "PT", "RO", "SK", "SI", "ES", "SE")
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: ValidateForExport
	* Descriere: Valideaza datele pentru export
	* Parametri: 
	*   toContext - Contextul
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Function ValidateForExport(toContext)
		*-- Tara e obligatorie pentru export
		If Empty(toContext.cTara)
			Return .F.
		EndIf
		
		*-- Nu poate fi RO
		If toContext.cTara = "RO"
			Return .F.
		EndIf
		
		Return .T.
	EndFunc
	
EndDefine


******************************************************************************************
*  CLASS: ReverseChargeXmlStrategy
*
*  DESCRIPTION:
*     Strategie pentru taxare inversa (AE).
*
******************************************************************************************

Define Class ReverseChargeXmlStrategy As XmlGeneratorStrategy
	
	cName = "ReverseChargeXmlStrategy"
	cTipRaportare = "B2B"
	
	*---------------------------------------------------------------------------
	* Functie: GetTaxCategoryForLine
	* Descriere: Determina categoria TVA pentru taxare inversa
	* Parametri: 
	*   toContext - Contextul
	*   tnProcTva - Procentul TVA
	*   tcCodTva - Codul TVA
	* Returneaza: String - Categoria
	*---------------------------------------------------------------------------
	Function GetTaxCategoryForLine(toContext, tnProcTva, tcCodTva)
		*-- Toate liniile sunt AE pentru taxare inversa
		Return "AE"
	EndFunc
	
EndDefine
