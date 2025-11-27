******************************************************************************************
*  CLASS: XmlGeneratorStrategy
*
*  AUTHOR: Refactored OOP Architecture
*
*  DESCRIPTION:
*     Strategie abstracta pentru generarea XML-ului e-Factura.
*     Defineste interfata pentru diferite tipuri de generare XML.
*
*  DESIGN PATTERN: Strategy Pattern (Interface)
*
******************************************************************************************

Define Class XmlGeneratorStrategy As Custom
	
	*-- Numele strategiei
	cName = "XmlGeneratorStrategy"
	
	*-- Tipul raportarii
	cTipRaportare = "B2B"
	
	*---------------------------------------------------------------------------
	* Functie: Generate
	* Descriere: Genereaza XML-ul pentru o factura
	* Parametri: 
	*   toContext - Contextul procesarii
	* Returneaza: String - Continutul XML
	*---------------------------------------------------------------------------
	Function Generate(toContext)
		Error "Metoda abstracta Generate trebuie implementata"
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetNamespaces
	* Descriere: Returneaza namespace-urile necesare
	* Returneaza: Collection
	*---------------------------------------------------------------------------
	Function GetNamespaces()
		Local loNamespaces
		loNamespaces = CreateObject("Collection")
		loNamespaces.Add("urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2", "cbc")
		loNamespaces.Add("urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2", "cac")
		loNamespaces.Add("urn:oasis:names:specification:ubl:schema:xsd:Invoice-2", "xmlns")
		Return loNamespaces
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetCustomizationId
	* Descriere: Returneaza CustomizationID specific
	* Returneaza: String
	*---------------------------------------------------------------------------
	Function GetCustomizationId()
		Return "urn:cen.eu:en16931:2017#compliant#urn:efactura.mfinante.ro:CIUS-RO:1.0.1"
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: RequiresAttachments
	* Descriere: Verifica daca sunt necesare atasamente
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Function RequiresAttachments()
		Return .F.
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetTaxCategoryForLine
	* Descriere: Determina categoria TVA pentru o linie
	* Parametri: 
	*   toContext - Contextul
	*   tnProcTva - Procentul TVA
	*   tcCodTva - Codul TVA
	* Returneaza: String - Categoria (S, Z, E, AE, K, G, O)
	*---------------------------------------------------------------------------
	Function GetTaxCategoryForLine(toContext, tnProcTva, tcCodTva)
		*-- Implementare implicita
		If tnProcTva > 0
			Return "S"
		Else
			Return "E"
		EndIf
	EndFunc
	
EndDefine
