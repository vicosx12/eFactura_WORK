******************************************************************************************
*  CLASS: XmlStrategyFactory
*
*  AUTHOR: Refactored OOP Architecture
*
*  DESCRIPTION:
*     Factory pentru crearea strategiilor de generare XML.
*     Selecteaza automat strategia potrivita in functie de tipul facturii.
*
*  DESIGN PATTERN: Factory Pattern + Strategy Pattern
*
*  USAGE:
*     loFactory = CreateObject("XmlStrategyFactory")
*     loStrategy = loFactory.Create(toContext)
*
******************************************************************************************

Define Class XmlStrategyFactory As Custom
	
	*---------------------------------------------------------------------------
	* Functie: Create
	* Descriere: Creeaza strategia potrivita pentru context
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	* Returneaza: XmlGeneratorStrategy
	*---------------------------------------------------------------------------
	Function Create(toContext)
		Local loStrategy
		
		Do Case
			*-- Taxare inversa
			Case toContext.lIsTaxareInversa Or toContext.cTipFactura = 'T'
				loStrategy = CreateObject("ReverseChargeXmlStrategy")
			
			*-- Export (tara diferita de RO)
			Case toContext.cTara <> "RO" And Not Empty(toContext.cTara)
				loStrategy = CreateObject("ExportXmlStrategy")
			
			*-- B2C (fara cod fiscal sau cod fiscal invalid)
			Case toContext.cTipRaportare = "B2C"
				loStrategy = CreateObject("B2CXmlStrategy")
			
			*-- B2B (standard)
			Otherwise
				loStrategy = CreateObject("B2BXmlStrategy")
		EndCase
		
		Return loStrategy
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: CreateByType
	* Descriere: Creeaza strategia dupa tip explicit
	* Parametri: 
	*   tcType - Tipul strategiei (B2B, B2C, Export, ReverseCharge)
	* Returneaza: XmlGeneratorStrategy
	*---------------------------------------------------------------------------
	Function CreateByType(tcType)
		Local lcType, loStrategy
		
		lcType = Upper(AllTrim(tcType))
		
		Do Case
			Case lcType = "B2B"
				loStrategy = CreateObject("B2BXmlStrategy")
			
			Case lcType = "B2C"
				loStrategy = CreateObject("B2CXmlStrategy")
			
			Case lcType = "EXPORT"
				loStrategy = CreateObject("ExportXmlStrategy")
			
			Case lcType = "REVERSECHARGE" Or lcType = "AE"
				loStrategy = CreateObject("ReverseChargeXmlStrategy")
			
			Otherwise
				loStrategy = CreateObject("B2BXmlStrategy")
		EndCase
		
		Return loStrategy
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetStrategyName
	* Descriere: Determina numele strategiei fara a crea obiectul
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	* Returneaza: String - Numele strategiei
	*---------------------------------------------------------------------------
	Function GetStrategyName(toContext)
		Do Case
			Case toContext.lIsTaxareInversa Or toContext.cTipFactura = 'T'
				Return "ReverseChargeXmlStrategy"
			
			Case toContext.cTara <> "RO" And Not Empty(toContext.cTara)
				Return "ExportXmlStrategy"
			
			Case toContext.cTipRaportare = "B2C"
				Return "B2CXmlStrategy"
			
			Otherwise
				Return "B2BXmlStrategy"
		EndCase
	EndFunc
	
EndDefine
