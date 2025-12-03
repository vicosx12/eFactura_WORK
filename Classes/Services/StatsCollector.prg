******************************************************************************************
*  CLASS: StatsCollector
*
*  AUTHOR: Refactored OOP Architecture
*
*  DESCRIPTION:
*     Colector de statistici pentru procesarea e-Factura.
*     Colecteaza metrici despre timp, inregistrari, erori, etc.
*
*  DESIGN PATTERN: Collector Pattern
*
*  METRICS:
*     - Durata procesarii
*     - Numar inregistrari procesate
*     - Numar erori
*     - Statistici pe handler
*
******************************************************************************************

Define Class StatsCollector As Custom
	
	*-- Timpi globali
	nStartTime = 0
	nEndTime = 0
	
	*-- Contoare
	nRecordCount = 0
	nErrorCount = 0
	nWarningCount = 0
	nSuccessCount = 0
	
	*-- Statistici pe handler
	Dimension aHandlerStats[1, 4]  && [Name, Duration, RecordCount, Errors]
	nHandlerCount = 0
	
	*-- Operatiunea curenta
	cCurrentOperation = ""
	nCurrentOperationStart = 0
	
	*---------------------------------------------------------------------------
	* Procedura: Init
	* Descriere: Initializeaza colectorul
	*---------------------------------------------------------------------------
	Procedure Init()
		This.Reset()
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Reset
	* Descriere: Reseteaza toate statisticile
	*---------------------------------------------------------------------------
	Procedure Reset()
		This.nStartTime = 0
		This.nEndTime = 0
		This.nRecordCount = 0
		This.nErrorCount = 0
		This.nWarningCount = 0
		This.nSuccessCount = 0
		This.nHandlerCount = 0
		This.cCurrentOperation = ""
		This.nCurrentOperationStart = 0
		Dimension This.aHandlerStats[1, 4]
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Start
	* Descriere: Marcheaza inceputul procesarii
	* Parametri: 
	*   tcOperation - Numele operatiunii (optional)
	*---------------------------------------------------------------------------
	Procedure Start(tcOperation)
		This.nStartTime = Seconds()
		This.cCurrentOperation = Iif(Empty(tcOperation), "Processing", tcOperation)
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Stop
	* Descriere: Marcheaza sfarsitul procesarii
	*---------------------------------------------------------------------------
	Procedure Stop()
		This.nEndTime = Seconds()
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: GetDuration
	* Descriere: Returneaza durata totala a procesarii
	* Returneaza: Numeric - Durata in secunde
	*---------------------------------------------------------------------------
	Function GetDuration()
		Local lnEnd
		lnEnd = Iif(This.nEndTime > 0, This.nEndTime, Seconds())
		Return lnEnd - This.nStartTime
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: StartHandler
	* Descriere: Marcheaza inceputul procesarii unui handler
	* Parametri: 
	*   tcHandlerName - Numele handler-ului
	*---------------------------------------------------------------------------
	Procedure StartHandler(tcHandlerName)
		This.nHandlerCount = This.nHandlerCount + 1
		Dimension This.aHandlerStats[This.nHandlerCount, 4]
		
		This.aHandlerStats[This.nHandlerCount, 1] = tcHandlerName
		This.aHandlerStats[This.nHandlerCount, 2] = 0  && Duration
		This.aHandlerStats[This.nHandlerCount, 3] = 0  && Records
		This.aHandlerStats[This.nHandlerCount, 4] = 0  && Errors
		
		This.nCurrentOperationStart = Seconds()
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: EndHandler
	* Descriere: Marcheaza sfarsitul procesarii unui handler
	* Parametri: 
	*   tnRecords - Numarul de inregistrari procesate
	*   tnErrors - Numarul de erori
	*---------------------------------------------------------------------------
	Procedure EndHandler(tnRecords, tnErrors)
		If This.nHandlerCount > 0
			This.aHandlerStats[This.nHandlerCount, 2] = Seconds() - This.nCurrentOperationStart
			This.aHandlerStats[This.nHandlerCount, 3] = Iif(Empty(tnRecords), 0, tnRecords)
			This.aHandlerStats[This.nHandlerCount, 4] = Iif(Empty(tnErrors), 0, tnErrors)
			
			This.nRecordCount = This.nRecordCount + Iif(Empty(tnRecords), 0, tnRecords)
			This.nErrorCount = This.nErrorCount + Iif(Empty(tnErrors), 0, tnErrors)
		EndIf
		This.nCurrentOperationStart = 0
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: IncrementRecords
	* Descriere: Incrementeaza contorul de inregistrari
	* Parametri: 
	*   tnCount - Numarul de adaugat (default 1)
	*---------------------------------------------------------------------------
	Procedure IncrementRecords(tnCount)
		This.nRecordCount = This.nRecordCount + Iif(Empty(tnCount), 1, tnCount)
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: IncrementErrors
	* Descriere: Incrementeaza contorul de erori
	* Parametri: 
	*   tnCount - Numarul de adaugat (default 1)
	*---------------------------------------------------------------------------
	Procedure IncrementErrors(tnCount)
		This.nErrorCount = This.nErrorCount + Iif(Empty(tnCount), 1, tnCount)
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: IncrementWarnings
	* Descriere: Incrementeaza contorul de avertismente
	* Parametri: 
	*   tnCount - Numarul de adaugat (default 1)
	*---------------------------------------------------------------------------
	Procedure IncrementWarnings(tnCount)
		This.nWarningCount = This.nWarningCount + Iif(Empty(tnCount), 1, tnCount)
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: IncrementSuccess
	* Descriere: Incrementeaza contorul de succese
	* Parametri: 
	*   tnCount - Numarul de adaugat (default 1)
	*---------------------------------------------------------------------------
	Procedure IncrementSuccess(tnCount)
		This.nSuccessCount = This.nSuccessCount + Iif(Empty(tnCount), 1, tnCount)
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: GetSummary
	* Descriere: Returneaza un rezumat al statisticilor
	* Returneaza: String - Rezumatul formatat
	*---------------------------------------------------------------------------
	Function GetSummary()
		Local lcSummary, i
		
		lcSummary = "=== STATISTICI PROCESARE ===" + Chr(13)
		lcSummary = lcSummary + "Durata totala: " + Transform(This.GetDuration()) + " secunde" + Chr(13)
		lcSummary = lcSummary + "Inregistrari procesate: " + Transform(This.nRecordCount) + Chr(13)
		lcSummary = lcSummary + "Succese: " + Transform(This.nSuccessCount) + Chr(13)
		lcSummary = lcSummary + "Erori: " + Transform(This.nErrorCount) + Chr(13)
		lcSummary = lcSummary + "Avertismente: " + Transform(This.nWarningCount) + Chr(13)
		
		If This.nHandlerCount > 0
			lcSummary = lcSummary + Chr(13) + "=== STATISTICI PE HANDLER ===" + Chr(13)
			For i = 1 To This.nHandlerCount
				lcSummary = lcSummary + This.aHandlerStats[i, 1] + ": " + ;
					Transform(This.aHandlerStats[i, 2]) + "s, " + ;
					Transform(This.aHandlerStats[i, 3]) + " rec, " + ;
					Transform(This.aHandlerStats[i, 4]) + " err" + Chr(13)
			EndFor
		EndIf
		
		Return lcSummary
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetHandlerStats
	* Descriere: Returneaza statisticile unui handler
	* Parametri: 
	*   tcHandlerName - Numele handler-ului
	* Returneaza: Array - [Duration, Records, Errors] sau NULL
	*---------------------------------------------------------------------------
	Function GetHandlerStats(tcHandlerName)
		Local i, laStats[3]
		
		For i = 1 To This.nHandlerCount
			If This.aHandlerStats[i, 1] = tcHandlerName
				laStats[1] = This.aHandlerStats[i, 2]
				laStats[2] = This.aHandlerStats[i, 3]
				laStats[3] = This.aHandlerStats[i, 4]
				Return @laStats
			EndIf
		EndFor
		
		Return .Null.
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetAverageDuration
	* Descriere: Returneaza durata medie pe handler
	* Returneaza: Numeric
	*---------------------------------------------------------------------------
	Function GetAverageDuration()
		If This.nHandlerCount = 0
			Return 0
		EndIf
		Return This.GetDuration() / This.nHandlerCount
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetErrorRate
	* Descriere: Returneaza rata de erori
	* Returneaza: Numeric - Procentul de erori
	*---------------------------------------------------------------------------
	Function GetErrorRate()
		Local lnTotal
		lnTotal = This.nSuccessCount + This.nErrorCount
		If lnTotal = 0
			Return 0
		EndIf
		Return (This.nErrorCount / lnTotal) * 100
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: ToObject
	* Descriere: Exporta statisticile ca obiect
	* Returneaza: Object
	*---------------------------------------------------------------------------
	Function ToObject()
		Local loStats
		loStats = CreateObject("Empty")
		AddProperty(loStats, "Duration", This.GetDuration())
		AddProperty(loStats, "RecordCount", This.nRecordCount)
		AddProperty(loStats, "ErrorCount", This.nErrorCount)
		AddProperty(loStats, "WarningCount", This.nWarningCount)
		AddProperty(loStats, "SuccessCount", This.nSuccessCount)
		AddProperty(loStats, "HandlerCount", This.nHandlerCount)
		AddProperty(loStats, "ErrorRate", This.GetErrorRate())
		Return loStats
	EndFunc
	
EndDefine
