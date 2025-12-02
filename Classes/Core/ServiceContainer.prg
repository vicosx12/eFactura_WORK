*---------------------------------------------------------------------------
* Clasa: ServiceContainer
* Descriere: Container pentru Dependency Injection
*            Gestioneaza inregistrarea si rezolvarea dependentelor
* Pattern: Dependency Injection Container / Service Locator
* Autor: Copilot
* Data: 2024
*---------------------------------------------------------------------------

Define Class ServiceContainer As Custom
	
	*-- Proprietati
	Dimension aServices[1, 3]     && [name, factory/instance, isSingleton]
	nServiceCount = 0
	Dimension aInstances[1, 2]   && [name, instance] - pentru singleton-uri
	nInstanceCount = 0
	oParentContainer = .Null.    && Pentru container ierarhic
	
	*---------------------------------------------------------------------------
	* Procedura: Init
	* Descriere: Initializeaza containerul
	*---------------------------------------------------------------------------
	Procedure Init()
		This.nServiceCount = 0
		This.nInstanceCount = 0
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Register
	* Descriere: Inregistreaza un serviciu cu o clasa
	* Parametri: 
	*   tcName - Numele serviciului
	*   tcClassName - Numele clasei
	*   tlSingleton - Daca e singleton (default .F.)
	*---------------------------------------------------------------------------
	Procedure Register(tcName, tcClassName, tlSingleton)
		If Empty(tcName) Or Empty(tcClassName)
			Error "Numele serviciului si al clasei sunt obligatorii"
			Return
		EndIf
		
		*-- Verifica daca exista deja
		Local lnIndex
		lnIndex = This.FindService(tcName)
		
		If lnIndex > 0
			*-- Actualizeaza
			This.aServices[lnIndex, 2] = tcClassName
			This.aServices[lnIndex, 3] = Iif(Empty(tlSingleton), .F., tlSingleton)
		Else
			*-- Adauga nou
			This.nServiceCount = This.nServiceCount + 1
			Dimension This.aServices[This.nServiceCount, 3]
			This.aServices[This.nServiceCount, 1] = Upper(AllTrim(tcName))
			This.aServices[This.nServiceCount, 2] = tcClassName
			This.aServices[This.nServiceCount, 3] = Iif(Empty(tlSingleton), .F., tlSingleton)
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: RegisterInstance
	* Descriere: Inregistreaza o instanta existenta
	* Parametri: 
	*   tcName - Numele serviciului
	*   toInstance - Instanta obiectului
	*---------------------------------------------------------------------------
	Procedure RegisterInstance(tcName, toInstance)
		If Empty(tcName) Or VarType(toInstance) <> 'O'
			Error "Numele serviciului si instanta sunt obligatorii"
			Return
		EndIf
		
		*-- Adauga in lista de instante singleton
		This.nInstanceCount = This.nInstanceCount + 1
		Dimension This.aInstances[This.nInstanceCount, 2]
		This.aInstances[This.nInstanceCount, 1] = Upper(AllTrim(tcName))
		This.aInstances[This.nInstanceCount, 2] = toInstance
		
		*-- Inregistreaza ca serviciu singleton
		This.Register(tcName, "", .T.)
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: RegisterFactory
	* Descriere: Inregistreaza o functie factory pentru creare
	* Parametri: 
	*   tcName - Numele serviciului
	*   tcFactoryExpression - Expresia de creare (ex: "CreateMyService()")
	*   tlSingleton - Daca e singleton
	*---------------------------------------------------------------------------
	Procedure RegisterFactory(tcName, tcFactoryExpression, tlSingleton)
		If Empty(tcName) Or Empty(tcFactoryExpression)
			Error "Numele serviciului si expresia factory sunt obligatorii"
			Return
		EndIf
		
		This.nServiceCount = This.nServiceCount + 1
		Dimension This.aServices[This.nServiceCount, 3]
		This.aServices[This.nServiceCount, 1] = Upper(AllTrim(tcName))
		This.aServices[This.nServiceCount, 2] = "FACTORY:" + tcFactoryExpression
		This.aServices[This.nServiceCount, 3] = Iif(Empty(tlSingleton), .F., tlSingleton)
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: Resolve
	* Descriere: Rezolva si returneaza o instanta a serviciului
	* Parametri: 
	*   tcName - Numele serviciului
	* Returneaza: Object - Instanta serviciului
	*---------------------------------------------------------------------------
	Function Resolve(tcName)
		Local lcName, lnIndex, loInstance, lcClassName, llIsSingleton
		
		lcName = Upper(AllTrim(tcName))
		
		*-- Cauta in instante existente (singleton-uri)
		loInstance = This.FindInstance(lcName)
		If VarType(loInstance) = 'O'
			Return loInstance
		EndIf
		
		*-- Cauta serviciul inregistrat
		lnIndex = This.FindService(lcName)
		
		If lnIndex = 0
			*-- Cauta in container parinte
			If VarType(This.oParentContainer) = 'O' And Not IsNull(This.oParentContainer)
				Return This.oParentContainer.Resolve(tcName)
			EndIf
			Error "Serviciul '" + tcName + "' nu este inregistrat"
			Return .Null.
		EndIf
		
		lcClassName = This.aServices[lnIndex, 2]
		llIsSingleton = This.aServices[lnIndex, 3]
		
		*-- Verifica daca e factory
		If Left(lcClassName, 8) = "FACTORY:"
			Local lcExpression
			lcExpression = SubStr(lcClassName, 9)
			loInstance = Evaluate(lcExpression)
		Else
			*-- Creaza instanta
			If Not Empty(lcClassName)
				loInstance = CreateObject(lcClassName)
			Else
				Error "Nu exista clasa sau instanta pentru serviciul '" + tcName + "'"
				Return .Null.
			EndIf
		EndIf
		
		*-- Daca e singleton, salveaza instanta
		If llIsSingleton And VarType(loInstance) = 'O'
			This.nInstanceCount = This.nInstanceCount + 1
			Dimension This.aInstances[This.nInstanceCount, 2]
			This.aInstances[This.nInstanceCount, 1] = lcName
			This.aInstances[This.nInstanceCount, 2] = loInstance
		EndIf
		
		*-- Injecteaza dependentele daca obiectul le declara
		If VarType(loInstance) = 'O' And PemStatus(loInstance, "InjectDependencies", 5)
			loInstance.InjectDependencies(This)
		EndIf
		
		Return loInstance
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: Has
	* Descriere: Verifica daca un serviciu este inregistrat
	* Parametri: 
	*   tcName - Numele serviciului
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Function Has(tcName)
		Return This.FindService(Upper(AllTrim(tcName))) > 0 Or ;
			   This.FindInstance(Upper(AllTrim(tcName))) <> .Null.
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: FindService
	* Descriere: Gaseste indexul serviciului
	* Parametri: 
	*   tcName - Numele serviciului
	* Returneaza: Integer - Indexul sau 0
	*---------------------------------------------------------------------------
	Protected Function FindService(tcName)
		Local i, lcName
		lcName = Upper(AllTrim(tcName))
		
		For i = 1 To This.nServiceCount
			If This.aServices[i, 1] == lcName
				Return i
			EndIf
		EndFor
		
		Return 0
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: FindInstance
	* Descriere: Gaseste instanta singleton
	* Parametri: 
	*   tcName - Numele serviciului
	* Returneaza: Object sau .Null.
	*---------------------------------------------------------------------------
	Protected Function FindInstance(tcName)
		Local i, lcName
		lcName = Upper(AllTrim(tcName))
		
		For i = 1 To This.nInstanceCount
			If This.aInstances[i, 1] == lcName
				Return This.aInstances[i, 2]
			EndIf
		EndFor
		
		Return .Null.
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: SetParent
	* Descriere: Seteaza containerul parinte
	* Parametri: 
	*   toParent - Containerul parinte
	*---------------------------------------------------------------------------
	Procedure SetParent(toParent)
		This.oParentContainer = toParent
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Clear
	* Descriere: Goleste containerul
	*---------------------------------------------------------------------------
	Procedure Clear()
		*-- Elibereaza instantele
		Local i
		For i = 1 To This.nInstanceCount
			If VarType(This.aInstances[i, 2]) = 'O'
				This.aInstances[i, 2] = .Null.
			EndIf
		EndFor
		
		This.nServiceCount = 0
		This.nInstanceCount = 0
		Dimension This.aServices[1, 3]
		Dimension This.aInstances[1, 2]
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: CreateScope
	* Descriere: Creaza un container copil (scoped)
	* Returneaza: ServiceContainer
	*---------------------------------------------------------------------------
	Function CreateScope()
		Local loChild
		loChild = CreateObject("ServiceContainer")
		loChild.SetParent(This)
		Return loChild
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: Destroy
	* Descriere: Curata resursele
	*---------------------------------------------------------------------------
	Procedure Destroy()
		This.Clear()
		This.oParentContainer = .Null.
	EndProc
	
EndDefine
