******************************************************************************************
*  CLASS: B2BXmlStrategy
*
*  AUTHOR: Refactored OOP Architecture
*
*  DESCRIPTION:
*     Strategie concreta pentru generarea XML B2B (Business to Business).
*     Implementeaza regulile specifice pentru facturi intre persoane juridice.
*
*  DESIGN PATTERN: Strategy Pattern
*
******************************************************************************************

Define Class B2BXmlStrategy As XmlGeneratorStrategy
	
	cName = "B2BXmlStrategy"
	cTipRaportare = "B2B"
	
	*---------------------------------------------------------------------------
	* Functie: Generate
	* Descriere: Genereaza XML-ul B2B
	* Parametri: 
	*   toContext - Contextul procesarii
	* Returneaza: String - Continutul XML
	*---------------------------------------------------------------------------
	Function Generate(toContext)
		*-- Delegare la XmlBuilderHandler cu setari B2B
		*-- Aceasta strategie poate fi extinsa pentru logica specifica B2B
		Return ""
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetTaxCategoryForLine
	* Descriere: Determina categoria TVA pentru B2B
	* Parametri: 
	*   toContext - Contextul
	*   tnProcTva - Procentul TVA
	*   tcCodTva - Codul TVA
	* Returneaza: String - Categoria
	*---------------------------------------------------------------------------
	Function GetTaxCategoryForLine(toContext, tnProcTva, tcCodTva)
		Local lcCategory
		
		*-- Logica specifica B2B
		Do Case
			*-- Taxare inversa
			Case toContext.lIsTaxareInversa Or tcCodTva = '10'
				lcCategory = "AE"
			
			*-- Scutire
			Case InList(tcCodTva, '16', '17')
				lcCategory = "E"
			
			*-- Neimpozabil
			Case tcCodTva = '18'
				lcCategory = "O"
			
			*-- TVA 0
			Case tnProcTva = 0
				lcCategory = "Z"
			
			*-- Standard
			Otherwise
				lcCategory = "S"
		EndCase
		
		Return lcCategory
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: ValidateForB2B
	* Descriere: Valideaza datele pentru B2B
	* Parametri: 
	*   toContext - Contextul
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Function ValidateForB2B(toContext)
		*-- Cod fiscal obligatoriu pentru B2B
		If Empty(toContext.cCodFiscal)
			Return .F.
		EndIf
		
		Return .T.
	EndFunc
	
EndDefine


******************************************************************************************
*  CLASS: B2CXmlStrategy
*
*  DESCRIPTION:
*     Strategie concreta pentru generarea XML B2C (Business to Consumer).
*     Implementeaza regulile specifice pentru facturi catre persoane fizice.
*
******************************************************************************************

Define Class B2CXmlStrategy As XmlGeneratorStrategy
	
	cName = "B2CXmlStrategy"
	cTipRaportare = "B2C"
	
	*---------------------------------------------------------------------------
	* Functie: Generate
	* Descriere: Genereaza XML-ul B2C
	* Parametri: 
	*   toContext - Contextul procesarii
	* Returneaza: String - Continutul XML
	*---------------------------------------------------------------------------
	Function Generate(toContext)
		Return ""
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetTaxCategoryForLine
	* Descriere: Determina categoria TVA pentru B2C
	* Parametri: 
	*   toContext - Contextul
	*   tnProcTva - Procentul TVA
	*   tcCodTva - Codul TVA
	* Returneaza: String - Categoria
	*---------------------------------------------------------------------------
	Function GetTaxCategoryForLine(toContext, tnProcTva, tcCodTva)
		*-- Pentru B2C, regulile sunt mai simple
		If tnProcTva > 0
			Return "S"
		Else
			Return "E"
		EndIf
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: ValidateForB2C
	* Descriere: Valideaza datele pentru B2C
	* Parametri: 
	*   toContext - Contextul
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Function ValidateForB2C(toContext)
		*-- Cod fiscal NU e obligatoriu pentru B2C
		*-- Dar numele clientului este obligatoriu
		If Empty(toContext.cNumeClient)
			Return .F.
		EndIf
		
		Return .T.
	EndFunc
	
EndDefine
