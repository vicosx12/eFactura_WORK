******************************************************************************************
*  CLASS: ProgressSubject
*
*  AUTHOR: Refactored OOP Architecture
*
*  DESCRIPTION:
*     Subiect Observer pentru notificari de progres.
*     Permite inregistrarea observatorilor si notificarea acestora
*     despre progresul procesarii.
*
*  DESIGN PATTERN: Observer Pattern (Subject)
*
*  USAGE:
*     loSubject = CreateObject("ProgressSubject")
*     loSubject.Attach(loProgressBarObserver)
*     loSubject.Notify(50, "Procesare 50%")
*
******************************************************************************************

Define Class ProgressSubject As Custom
	
	*-- Colectie de observatori
	Dimension aObservers[1]
	nObserverCount = 0
	
	*-- Stare curenta
	nCurrentPercent = 0
	cCurrentMessage = ""
	
	*-- Flag pentru a activa/dezactiva notificarile
	lEnabled = .T.
	
	*---------------------------------------------------------------------------
	* Procedura: Init
	* Descriere: Initializeaza subiectul
	*---------------------------------------------------------------------------
	Procedure Init()
		This.nObserverCount = 0
		Dimension This.aObservers[1]
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Attach
	* Descriere: Inregistreaza un observator
	* Parametri: 
	*   toObserver - Obiectul observator (trebuie sa aiba metoda Update)
	*---------------------------------------------------------------------------
	Procedure Attach(toObserver)
		If VarType(toObserver) <> 'O' Or IsNull(toObserver)
			Return
		EndIf
		
		*-- Verifica daca observatorul are metoda Update
		If Not PemStatus(toObserver, 'Update', 5)
			*-- Observatorul nu are metoda Update
			Return
		EndIf
		
		*-- Adauga observatorul
		This.nObserverCount = This.nObserverCount + 1
		Dimension This.aObservers[This.nObserverCount]
		This.aObservers[This.nObserverCount] = toObserver
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Detach
	* Descriere: Dezinregistreaza un observator
	* Parametri: 
	*   toObserver - Obiectul observator de sters
	*---------------------------------------------------------------------------
	Procedure Detach(toObserver)
		Local i, lnPos
		
		*-- Gaseste pozitia observatorului
		lnPos = 0
		For i = 1 To This.nObserverCount
			If VarType(This.aObservers[i]) = 'O' And This.aObservers[i] = toObserver
				lnPos = i
				Exit
			EndIf
		EndFor
		
		*-- Sterge observatorul
		If lnPos > 0
			For i = lnPos To This.nObserverCount - 1
				This.aObservers[i] = This.aObservers[i + 1]
			EndFor
			This.nObserverCount = This.nObserverCount - 1
			If This.nObserverCount > 0
				Dimension This.aObservers[This.nObserverCount]
			EndIf
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Notify
	* Descriere: Notifica toti observatorii despre progres
	* Parametri: 
	*   tnPercent - Procentul de progres (0-100)
	*   tcMessage - Mesajul de progres (optional)
	*---------------------------------------------------------------------------
	Procedure Notify(tnPercent, tcMessage)
		Local i
		
		If Not This.lEnabled
			Return
		EndIf
		
		*-- Actualizeaza starea curenta
		This.nCurrentPercent = tnPercent
		This.cCurrentMessage = Iif(Empty(tcMessage), "", tcMessage)
		
		*-- Notifica toti observatorii
		For i = 1 To This.nObserverCount
			If VarType(This.aObservers[i]) = 'O' And Not IsNull(This.aObservers[i])
				Try
					This.aObservers[i].Update(tnPercent, tcMessage)
				Catch
					*-- Ignora erori la notificare
				EndTry
			EndIf
		EndFor
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: NotifyStart
	* Descriere: Notifica inceputul procesarii
	* Parametri: 
	*   tcMessage - Mesajul (optional)
	*---------------------------------------------------------------------------
	Procedure NotifyStart(tcMessage)
		This.Notify(0, Iif(Empty(tcMessage), "Incepere procesare...", tcMessage))
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: NotifyComplete
	* Descriere: Notifica finalizarea procesarii
	* Parametri: 
	*   tcMessage - Mesajul (optional)
	*---------------------------------------------------------------------------
	Procedure NotifyComplete(tcMessage)
		This.Notify(100, Iif(Empty(tcMessage), "Procesare finalizata!", tcMessage))
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: NotifyError
	* Descriere: Notifica o eroare
	* Parametri: 
	*   tcMessage - Mesajul de eroare
	*---------------------------------------------------------------------------
	Procedure NotifyError(tcMessage)
		Local i
		
		*-- Notifica observatorii cu metoda Error
		For i = 1 To This.nObserverCount
			If VarType(This.aObservers[i]) = 'O' And Not IsNull(This.aObservers[i])
				If PemStatus(This.aObservers[i], 'Error', 5)
					Try
						This.aObservers[i].Error(tcMessage)
					Catch
					EndTry
				EndIf
			EndIf
		EndFor
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: GetObserverCount
	* Descriere: Returneaza numarul de observatori
	* Returneaza: Numeric
	*---------------------------------------------------------------------------
	Function GetObserverCount()
		Return This.nObserverCount
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: Enable
	* Descriere: Activeaza notificarile
	*---------------------------------------------------------------------------
	Procedure Enable()
		This.lEnabled = .T.
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Disable
	* Descriere: Dezactiveaza notificarile
	*---------------------------------------------------------------------------
	Procedure Disable()
		This.lEnabled = .F.
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: ClearObservers
	* Descriere: Sterge toti observatorii
	*---------------------------------------------------------------------------
	Procedure ClearObservers()
		This.nObserverCount = 0
		Dimension This.aObservers[1]
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Destroy
	* Descriere: Curata resursele
	*---------------------------------------------------------------------------
	Procedure Destroy()
		This.ClearObservers()
	EndProc
	
EndDefine
