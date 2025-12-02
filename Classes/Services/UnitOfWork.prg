*---------------------------------------------------------------------------
* Clasa: UnitOfWork
* Descriere: Coordoneaza tranzactiile intre multiple repositories
*            Asigura consistenta datelor si atomicitatea operatiilor
* Pattern: Unit of Work
* Autor: Copilot
* Data: 2024
*---------------------------------------------------------------------------

Define Class UnitOfWork As Custom
	
	*-- Proprietati
	Dimension aRepositories[1, 2]   && [name, repository]
	nRepositoryCount = 0
	Dimension aOperations[1, 4]     && [type, repository, entity, data]
	nOperationCount = 0
	lInTransaction = .F.
	oLogger = .Null.
	nTransactionDepth = 0
	
	*---------------------------------------------------------------------------
	* Procedura: Init
	* Descriere: Initializeaza Unit of Work
	*---------------------------------------------------------------------------
	Procedure Init()
		This.nRepositoryCount = 0
		This.nOperationCount = 0
		This.lInTransaction = .F.
		This.nTransactionDepth = 0
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: RegisterRepository
	* Descriere: Inregistreaza un repository
	* Parametri: 
	*   tcName - Numele repository-ului
	*   toRepository - Instanta repository-ului
	*---------------------------------------------------------------------------
	Procedure RegisterRepository(tcName, toRepository)
		If Empty(tcName) Or VarType(toRepository) <> 'O'
			Error "Numele si repository-ul sunt obligatorii"
			Return
		EndIf
		
		This.nRepositoryCount = This.nRepositoryCount + 1
		Dimension This.aRepositories[This.nRepositoryCount, 2]
		This.aRepositories[This.nRepositoryCount, 1] = Upper(AllTrim(tcName))
		This.aRepositories[This.nRepositoryCount, 2] = toRepository
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: GetRepository
	* Descriere: Obtine un repository inregistrat
	* Parametri: 
	*   tcName - Numele repository-ului
	* Returneaza: Object - Repository-ul
	*---------------------------------------------------------------------------
	Function GetRepository(tcName)
		Local i, lcName
		lcName = Upper(AllTrim(tcName))
		
		For i = 1 To This.nRepositoryCount
			If This.aRepositories[i, 1] == lcName
				Return This.aRepositories[i, 2]
			EndIf
		EndFor
		
		Return .Null.
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: MarkNew
	* Descriere: Marcheaza o entitate pentru inserare
	* Parametri: 
	*   tcRepository - Numele repository-ului
	*   toEntity - Entitatea de inserat
	*---------------------------------------------------------------------------
	Procedure MarkNew(tcRepository, toEntity)
		This.AddOperation("INSERT", tcRepository, toEntity, .Null.)
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: MarkDirty
	* Descriere: Marcheaza o entitate pentru actualizare
	* Parametri: 
	*   tcRepository - Numele repository-ului
	*   toEntity - Entitatea de actualizat
	*   toOriginalData - Datele originale (pentru conflict detection)
	*---------------------------------------------------------------------------
	Procedure MarkDirty(tcRepository, toEntity, toOriginalData)
		This.AddOperation("UPDATE", tcRepository, toEntity, toOriginalData)
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: MarkDeleted
	* Descriere: Marcheaza o entitate pentru stergere
	* Parametri: 
	*   tcRepository - Numele repository-ului
	*   toEntity - Entitatea de sters
	*---------------------------------------------------------------------------
	Procedure MarkDeleted(tcRepository, toEntity)
		This.AddOperation("DELETE", tcRepository, toEntity, .Null.)
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: AddOperation
	* Descriere: Adauga o operatie in coada
	* Parametri: 
	*   tcType - Tipul operatiei (INSERT/UPDATE/DELETE)
	*   tcRepository - Numele repository-ului
	*   toEntity - Entitatea
	*   toOriginalData - Date originale
	*---------------------------------------------------------------------------
	Protected Procedure AddOperation(tcType, tcRepository, toEntity, toOriginalData)
		This.nOperationCount = This.nOperationCount + 1
		Dimension This.aOperations[This.nOperationCount, 4]
		This.aOperations[This.nOperationCount, 1] = tcType
		This.aOperations[This.nOperationCount, 2] = Upper(AllTrim(tcRepository))
		This.aOperations[This.nOperationCount, 3] = toEntity
		This.aOperations[This.nOperationCount, 4] = toOriginalData
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: BeginTransaction
	* Descriere: Incepe o tranzactie
	*---------------------------------------------------------------------------
	Procedure BeginTransaction()
		If This.nTransactionDepth = 0
			Begin Transaction
			This.lInTransaction = .T.
		EndIf
		This.nTransactionDepth = This.nTransactionDepth + 1
		
		This.Log("BeginTransaction - Depth: " + Transform(This.nTransactionDepth))
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Commit
	* Descriere: Executa toate operatiile si commit tranzactia
	* Returneaza: Logical - Succes sau esec
	*---------------------------------------------------------------------------
	Function Commit()
		Local llSuccess, i, loRepository, loEntity, lcType
		llSuccess = .T.
		
		This.Log("Commit - Processing " + Transform(This.nOperationCount) + " operations")
		
		Try
			*-- Executa toate operatiile
			For i = 1 To This.nOperationCount
				lcType = This.aOperations[i, 1]
				loRepository = This.GetRepository(This.aOperations[i, 2])
				loEntity = This.aOperations[i, 3]
				
				If IsNull(loRepository)
					Error "Repository '" + This.aOperations[i, 2] + "' nu este inregistrat"
				EndIf
				
				Do Case
					Case lcType = "INSERT"
						loRepository.Insert(loEntity)
					Case lcType = "UPDATE"
						loRepository.Update(loEntity)
					Case lcType = "DELETE"
						loRepository.Delete(loEntity)
				EndCase
			EndFor
			
			*-- Commit tranzactia
			This.nTransactionDepth = This.nTransactionDepth - 1
			If This.nTransactionDepth = 0 And This.lInTransaction
				End Transaction
				This.lInTransaction = .F.
			EndIf
			
			*-- Goleste operatiile
			This.ClearOperations()
			
			This.Log("Commit successful")
			
		Catch To loException
			llSuccess = .F.
			This.Log("Commit failed: " + loException.Message)
			This.Rollback()
		EndTry
		
		Return llSuccess
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: Rollback
	* Descriere: Anuleaza tranzactia
	*---------------------------------------------------------------------------
	Procedure Rollback()
		This.Log("Rollback - Depth: " + Transform(This.nTransactionDepth))
		
		If This.lInTransaction
			Rollback
			This.lInTransaction = .F.
		EndIf
		
		This.nTransactionDepth = 0
		This.ClearOperations()
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: ClearOperations
	* Descriere: Goleste lista de operatii
	*---------------------------------------------------------------------------
	Protected Procedure ClearOperations()
		This.nOperationCount = 0
		Dimension This.aOperations[1, 4]
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: GetPendingOperationCount
	* Descriere: Returneaza numarul de operatii in asteptare
	* Returneaza: Integer
	*---------------------------------------------------------------------------
	Function GetPendingOperationCount()
		Return This.nOperationCount
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: HasPendingChanges
	* Descriere: Verifica daca sunt modificari in asteptare
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Function HasPendingChanges()
		Return This.nOperationCount > 0
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: Log
	* Descriere: Scrie in log
	* Parametri: 
	*   tcMessage - Mesajul
	*---------------------------------------------------------------------------
	Protected Procedure Log(tcMessage)
		If VarType(This.oLogger) = 'O' And Not IsNull(This.oLogger)
			This.oLogger.Debug("[UnitOfWork] " + tcMessage)
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: SetLogger
	* Descriere: Seteaza logger-ul
	* Parametri: 
	*   toLogger - Logger-ul
	*---------------------------------------------------------------------------
	Procedure SetLogger(toLogger)
		This.oLogger = toLogger
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Destroy
	* Descriere: Curata resursele
	*---------------------------------------------------------------------------
	Procedure Destroy()
		If This.lInTransaction
			This.Rollback()
		EndIf
		
		*-- Elibereaza repositories
		Local i
		For i = 1 To This.nRepositoryCount
			This.aRepositories[i, 2] = .Null.
		EndFor
		
		This.oLogger = .Null.
	EndProc
	
EndDefine
