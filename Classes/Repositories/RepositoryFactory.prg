******************************************************************************************
*  CLASS: RepositoryFactory
*
*  AUTHOR: Refactored OOP Architecture
*
*  DESCRIPTION:
*     Factory pentru crearea repository-urilor potrivite.
*     Returneaza repository-ul corect in functie de tipul de date.
*
*  DESIGN PATTERN: Factory Pattern
*
*  USAGE:
*     loFactory = CreateObject("RepositoryFactory")
*     loRepo = loFactory.Create("Iesiri")
*
******************************************************************************************

Define Class RepositoryFactory As Custom
	
	*-- Cache pentru repository-uri create
	oIesiriRepo = .Null.
	oExportRepo = .Null.
	oDocumRepo = .Null.
	
	*-- Flag pentru refolosirea repository-urilor
	lCacheRepositories = .T.
	
	*---------------------------------------------------------------------------
	* Functie: Create
	* Descriere: Creeaza sau returneaza un repository
	* Parametri: 
	*   tcType - Tipul repository-ului (Iesiri, Export, Docum)
	* Returneaza: IInvoiceRepository
	*---------------------------------------------------------------------------
	Function Create(tcType)
		Local lcType, loRepo
		
		lcType = Proper(AllTrim(tcType))
		
		Do Case
			Case lcType = "Iesiri"
				If This.lCacheRepositories And VarType(This.oIesiriRepo) = 'O'
					Return This.oIesiriRepo
				EndIf
				loRepo = CreateObject("IesiriRepository")
				If This.lCacheRepositories
					This.oIesiriRepo = loRepo
				EndIf
				
			Case lcType = "Export"
				If This.lCacheRepositories And VarType(This.oExportRepo) = 'O'
					Return This.oExportRepo
				EndIf
				loRepo = CreateObject("ExportRepository")
				If This.lCacheRepositories
					This.oExportRepo = loRepo
				EndIf
				
			Case lcType = "Docum"
				*-- Pentru Docum, folosim un repository generic sau IesiriRepository
				If This.lCacheRepositories And VarType(This.oDocumRepo) = 'O'
					Return This.oDocumRepo
				EndIf
				loRepo = CreateObject("IesiriRepository")  && Sau un DocumRepository specific
				If This.lCacheRepositories
					This.oDocumRepo = loRepo
				EndIf
				
			Otherwise
				*-- Default la Iesiri
				loRepo = CreateObject("IesiriRepository")
		EndCase
		
		Return loRepo
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetForContext
	* Descriere: Returneaza repository-ul potrivit pentru un context
	* Parametri: 
	*   toContext - Obiectul EFacturaContext
	* Returneaza: IInvoiceRepository
	*---------------------------------------------------------------------------
	Function GetForContext(toContext)
		Return This.Create(toContext.cAlias)
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: ClearCache
	* Descriere: Goleste cache-ul de repository-uri
	*---------------------------------------------------------------------------
	Procedure ClearCache()
		This.oIesiriRepo = .Null.
		This.oExportRepo = .Null.
		This.oDocumRepo = .Null.
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Destroy
	* Descriere: Curata resursele
	*---------------------------------------------------------------------------
	Procedure Destroy()
		This.ClearCache()
	EndProc
	
EndDefine
