*---------------------------------------------------------------------------
* Clasa: CacheService
* Descriere: Serviciu de caching pentru stocarea temporara a rezultatelor
*            Reduce apelurile repetate catre API ANAF
* Pattern: Cache-Aside
* Autor: Copilot
* Data: 2024
*---------------------------------------------------------------------------

Define Class CacheService As Custom
	
	*-- Proprietati
	Dimension aCacheItems[1, 4]    && [key, value, expiry, hits]
	nItemCount = 0
	nDefaultTtl = 300              && 5 minute TTL default
	nMaxItems = 1000               && Numar maxim de iteme
	nHits = 0
	nMisses = 0
	oLogger = .Null.
	
	*---------------------------------------------------------------------------
	* Procedura: Init
	* Descriere: Initializeaza cache-ul
	*---------------------------------------------------------------------------
	Procedure Init()
		This.nItemCount = 0
		This.nHits = 0
		This.nMisses = 0
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Set
	* Descriere: Adauga sau actualizeaza un item in cache
	* Parametri: 
	*   tcKey - Cheia
	*   tvValue - Valoarea (orice tip)
	*   tnTtl - Time-to-live in secunde (optional)
	*---------------------------------------------------------------------------
	Procedure Set(tcKey, tvValue, tnTtl)
		Local lcKey, lnExpiry, lnIndex, lnTtl
		
		lcKey = Upper(AllTrim(tcKey))
		lnTtl = Iif(Empty(tnTtl), This.nDefaultTtl, tnTtl)
		lnExpiry = Seconds() + lnTtl
		
		*-- Cauta daca exista
		lnIndex = This.FindIndex(lcKey)
		
		If lnIndex > 0
			*-- Actualizeaza
			This.aCacheItems[lnIndex, 2] = tvValue
			This.aCacheItems[lnIndex, 3] = lnExpiry
		Else
			*-- Verifica limita
			If This.nItemCount >= This.nMaxItems
				This.Evict()
			EndIf
			
			*-- Adauga nou
			This.nItemCount = This.nItemCount + 1
			Dimension This.aCacheItems[This.nItemCount, 4]
			This.aCacheItems[This.nItemCount, 1] = lcKey
			This.aCacheItems[This.nItemCount, 2] = tvValue
			This.aCacheItems[This.nItemCount, 3] = lnExpiry
			This.aCacheItems[This.nItemCount, 4] = 0  && hits
		EndIf
		
		This.Log("Cache SET: " + lcKey)
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: Get
	* Descriere: Obtine un item din cache
	* Parametri: 
	*   tcKey - Cheia
	*   tvDefault - Valoare default daca nu exista
	* Returneaza: Valoarea sau default
	*---------------------------------------------------------------------------
	Function Get(tcKey, tvDefault)
		Local lcKey, lnIndex
		
		lcKey = Upper(AllTrim(tcKey))
		lnIndex = This.FindIndex(lcKey)
		
		If lnIndex > 0
			*-- Verifica expirare
			If This.aCacheItems[lnIndex, 3] < Seconds()
				*-- Expirat - sterge
				This.Remove(lcKey)
				This.nMisses = This.nMisses + 1
				This.Log("Cache MISS (expired): " + lcKey)
				Return tvDefault
			EndIf
			
			*-- Hit
			This.nHits = This.nHits + 1
			This.aCacheItems[lnIndex, 4] = This.aCacheItems[lnIndex, 4] + 1
			This.Log("Cache HIT: " + lcKey)
			Return This.aCacheItems[lnIndex, 2]
		EndIf
		
		*-- Miss
		This.nMisses = This.nMisses + 1
		This.Log("Cache MISS: " + lcKey)
		Return tvDefault
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: Has
	* Descriere: Verifica daca exista un item valid in cache
	* Parametri: 
	*   tcKey - Cheia
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Function Has(tcKey)
		Local lcKey, lnIndex
		
		lcKey = Upper(AllTrim(tcKey))
		lnIndex = This.FindIndex(lcKey)
		
		If lnIndex > 0
			*-- Verifica expirare
			Return This.aCacheItems[lnIndex, 3] >= Seconds()
		EndIf
		
		Return .F.
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: Remove
	* Descriere: Sterge un item din cache
	* Parametri: 
	*   tcKey - Cheia
	*---------------------------------------------------------------------------
	Procedure Remove(tcKey)
		Local lcKey, lnIndex, i
		
		lcKey = Upper(AllTrim(tcKey))
		lnIndex = This.FindIndex(lcKey)
		
		If lnIndex > 0
			*-- Shift array
			For i = lnIndex To This.nItemCount - 1
				This.aCacheItems[i, 1] = This.aCacheItems[i + 1, 1]
				This.aCacheItems[i, 2] = This.aCacheItems[i + 1, 2]
				This.aCacheItems[i, 3] = This.aCacheItems[i + 1, 3]
				This.aCacheItems[i, 4] = This.aCacheItems[i + 1, 4]
			EndFor
			
			This.nItemCount = This.nItemCount - 1
			If This.nItemCount > 0
				Dimension This.aCacheItems[This.nItemCount, 4]
			EndIf
			
			This.Log("Cache REMOVE: " + lcKey)
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Clear
	* Descriere: Goleste tot cache-ul
	*---------------------------------------------------------------------------
	Procedure Clear()
		This.nItemCount = 0
		Dimension This.aCacheItems[1, 4]
		This.Log("Cache CLEARED")
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: ClearExpired
	* Descriere: Sterge itemele expirate
	*---------------------------------------------------------------------------
	Procedure ClearExpired()
		Local i, lnNow, lnRemoved
		lnNow = Seconds()
		lnRemoved = 0
		
		i = 1
		Do While i <= This.nItemCount
			If This.aCacheItems[i, 3] < lnNow
				*-- Expirat - sterge
				This.RemoveAtIndex(i)
				lnRemoved = lnRemoved + 1
			Else
				i = i + 1
			EndIf
		EndDo
		
		This.Log("Cache CLEANUP: removed " + Transform(lnRemoved) + " expired items")
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Evict
	* Descriere: Elimina iteme pentru a face loc (LRU-like)
	*---------------------------------------------------------------------------
	Protected Procedure Evict()
		*-- Sterge cele expirate mai intai
		This.ClearExpired()
		
		*-- Daca tot e plin, sterge cele mai putin accesate
		If This.nItemCount >= This.nMaxItems
			Local lnMinHits, lnMinIndex, i
			lnMinHits = 999999999
			lnMinIndex = 1
			
			For i = 1 To This.nItemCount
				If This.aCacheItems[i, 4] < lnMinHits
					lnMinHits = This.aCacheItems[i, 4]
					lnMinIndex = i
				EndIf
			EndFor
			
			This.RemoveAtIndex(lnMinIndex)
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: RemoveAtIndex
	* Descriere: Sterge un item la indexul specificat
	* Parametri: 
	*   tnIndex - Indexul
	*---------------------------------------------------------------------------
	Protected Procedure RemoveAtIndex(tnIndex)
		Local i
		
		For i = tnIndex To This.nItemCount - 1
			This.aCacheItems[i, 1] = This.aCacheItems[i + 1, 1]
			This.aCacheItems[i, 2] = This.aCacheItems[i + 1, 2]
			This.aCacheItems[i, 3] = This.aCacheItems[i + 1, 3]
			This.aCacheItems[i, 4] = This.aCacheItems[i + 1, 4]
		EndFor
		
		This.nItemCount = This.nItemCount - 1
		If This.nItemCount > 0
			Dimension This.aCacheItems[This.nItemCount, 4]
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: FindIndex
	* Descriere: Gaseste indexul unui item
	* Parametri: 
	*   tcKey - Cheia
	* Returneaza: Integer - Indexul sau 0
	*---------------------------------------------------------------------------
	Protected Function FindIndex(tcKey)
		Local i
		
		For i = 1 To This.nItemCount
			If This.aCacheItems[i, 1] == tcKey
				Return i
			EndIf
		EndFor
		
		Return 0
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetOrSet
	* Descriere: Obtine din cache sau seteaza folosind factory
	* Parametri: 
	*   tcKey - Cheia
	*   tcFactoryExpression - Expresia de creare
	*   tnTtl - TTL in secunde
	* Returneaza: Valoarea
	*---------------------------------------------------------------------------
	Function GetOrSet(tcKey, tcFactoryExpression, tnTtl)
		Local lvValue
		
		If This.Has(tcKey)
			Return This.Get(tcKey)
		EndIf
		
		*-- Executa factory
		lvValue = Evaluate(tcFactoryExpression)
		This.Set(tcKey, lvValue, tnTtl)
		
		Return lvValue
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetStats
	* Descriere: Returneaza statisticile cache-ului
	* Returneaza: Object cu statistici
	*---------------------------------------------------------------------------
	Function GetStats()
		Local loStats
		loStats = CreateObject("Empty")
		AddProperty(loStats, "ItemCount", This.nItemCount)
		AddProperty(loStats, "Hits", This.nHits)
		AddProperty(loStats, "Misses", This.nMisses)
		AddProperty(loStats, "HitRatio", Iif(This.nHits + This.nMisses > 0, ;
			This.nHits / (This.nHits + This.nMisses), 0))
		Return loStats
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: SetDefaultTtl
	* Descriere: Seteaza TTL-ul default
	* Parametri: 
	*   tnSeconds - Secunde
	*---------------------------------------------------------------------------
	Procedure SetDefaultTtl(tnSeconds)
		This.nDefaultTtl = tnSeconds
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Log
	* Descriere: Scrie in log
	* Parametri: 
	*   tcMessage - Mesajul
	*---------------------------------------------------------------------------
	Protected Procedure Log(tcMessage)
		If VarType(This.oLogger) = 'O' And Not IsNull(This.oLogger)
			This.oLogger.Debug("[CacheService] " + tcMessage)
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
		This.Clear()
		This.oLogger = .Null.
	EndProc
	
EndDefine
