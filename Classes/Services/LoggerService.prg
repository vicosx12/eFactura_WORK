******************************************************************************************
*  CLASS: LoggerService
*
*  AUTHOR: Refactored OOP Architecture
*
*  DESCRIPTION:
*     Serviciu centralizat de logging pentru e-Factura.
*     Gestioneaza scrierea logurilor in fisiere si/sau consola.
*
*  DESIGN PATTERN: Service Pattern
*
*  USAGE:
*     loLogger = CreateObject("LoggerService")
*     loLogger.Log("Mesaj informativ", "INFO")
*     loLogger.Error("Mesaj de eroare")
*
******************************************************************************************

Define Class LoggerService As Custom
	
	*-- Setari
	lEnabled = .T.
	lWriteToFile = .T.
	lWriteToConsole = .T.
	lIncludeTimestamp = .T.
	lIncludeSource = .T.
	
	*-- Cale fisier log
	cLogPath = ""
	cLogFileName = ""
	cCurrentLogFile = ""
	
	*-- Nivele de logging
	nLogLevel = 3  && 1=Error, 2=Warning, 3=Info, 4=Debug
	
	*-- Referinta la ConfigProvider
	oConfig = .Null.
	
	*-- Buffer pentru loguri
	Dimension aLogBuffer[1]
	nBufferCount = 0
	nMaxBufferSize = 100
	
	*---------------------------------------------------------------------------
	* Procedura: Init
	* Descriere: Initializeaza serviciul de logging
	*---------------------------------------------------------------------------
	Procedure Init()
		This.InitializeLogFile()
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: InitializeLogFile
	* Descriere: Initializeaza fisierul de log
	*---------------------------------------------------------------------------
	Protected Procedure InitializeLogFile()
		Local lcPath, lcFileName
		
		If VarType(This.oConfig) = 'O' And Not IsNull(This.oConfig)
			lcPath = This.oConfig.GetLogFolder()
		Else
			lcPath = AddBs(SYS(5) + CurDir()) + "LOG\"
		EndIf
		
		If Not Directory(lcPath)
			Md (lcPath)
		EndIf
		
		This.cLogPath = lcPath
		lcFileName = "eFactura_" + DToS(Date()) + ".log"
		This.cLogFileName = lcFileName
		This.cCurrentLogFile = lcPath + lcFileName
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Log
	* Descriere: Scrie un mesaj in log
	* Parametri: 
	*   tcMessage - Mesajul de logat
	*   tcLevel - Nivelul (INFO, WARNING, ERROR, DEBUG)
	*   tcSource - Sursa mesajului (optional)
	*---------------------------------------------------------------------------
	Procedure Log(tcMessage, tcLevel, tcSource)
		Local lcFullMessage, lcTimestamp, lcLevel, lcSource
		
		If Not This.lEnabled
			Return
		EndIf
		
		*-- Verifica nivelul
		lcLevel = Upper(Iif(Empty(tcLevel), "INFO", tcLevel))
		If Not This.ShouldLog(lcLevel)
			Return
		EndIf
		
		*-- Construieste mesajul
		lcFullMessage = ""
		
		*-- Adauga timestamp
		If This.lIncludeTimestamp
			lcTimestamp = Transform(DateTime())
			lcFullMessage = "[" + lcTimestamp + "] "
		EndIf
		
		*-- Adauga nivelul
		lcFullMessage = lcFullMessage + "[" + PadR(lcLevel, 7) + "] "
		
		*-- Adauga sursa
		If This.lIncludeSource And Not Empty(tcSource)
			lcSource = Iif(Empty(tcSource), Program(), tcSource)
			lcFullMessage = lcFullMessage + "[" + AllTrim(lcSource) + "] "
		EndIf
		
		*-- Adauga mesajul
		lcFullMessage = lcFullMessage + tcMessage
		
		*-- Scrie in fisier
		If This.lWriteToFile
			This.WriteToFile(lcFullMessage)
		EndIf
		
		*-- Scrie in consola
		If This.lWriteToConsole
			? lcFullMessage
		EndIf
		
		*-- Adauga in buffer
		This.AddToBuffer(lcFullMessage)
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: ShouldLog
	* Descriere: Verifica daca mesajul trebuie logat conform nivelului
	* Parametri: 
	*   tcLevel - Nivelul mesajului
	* Returneaza: Logical
	*---------------------------------------------------------------------------
	Protected Function ShouldLog(tcLevel)
		Local lnLevel
		
		Do Case
			Case tcLevel = "ERROR"
				lnLevel = 1
			Case tcLevel = "WARNING" Or tcLevel = "WARN"
				lnLevel = 2
			Case tcLevel = "INFO"
				lnLevel = 3
			Case tcLevel = "DEBUG"
				lnLevel = 4
			Otherwise
				lnLevel = 3
		EndCase
		
		Return lnLevel <= This.nLogLevel
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: WriteToFile
	* Descriere: Scrie mesajul in fisierul de log
	* Parametri: 
	*   tcMessage - Mesajul de scris
	*---------------------------------------------------------------------------
	Protected Procedure WriteToFile(tcMessage)
		Local lnHandle
		
		Try
			If File(This.cCurrentLogFile)
				lnHandle = FOpen(This.cCurrentLogFile, 2)  && Append mode
				If lnHandle > 0
					FSeek(lnHandle, 0, 2)  && Go to end
					FPuts(lnHandle, tcMessage)
					FClose(lnHandle)
				EndIf
			Else
				StrToFile(tcMessage + Chr(13) + Chr(10), This.cCurrentLogFile)
			EndIf
		Catch
			*-- Ignora erori la scriere in log
		EndTry
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: AddToBuffer
	* Descriere: Adauga mesajul in buffer
	* Parametri: 
	*   tcMessage - Mesajul
	*---------------------------------------------------------------------------
	Protected Procedure AddToBuffer(tcMessage)
		If This.nBufferCount >= This.nMaxBufferSize
			*-- Shift buffer
			For i = 1 To This.nMaxBufferSize - 1
				This.aLogBuffer[i] = This.aLogBuffer[i + 1]
			EndFor
			This.nBufferCount = This.nMaxBufferSize - 1
		EndIf
		
		This.nBufferCount = This.nBufferCount + 1
		Dimension This.aLogBuffer[This.nBufferCount]
		This.aLogBuffer[This.nBufferCount] = tcMessage
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Info
	* Descriere: Scrie un mesaj informativ
	* Parametri: 
	*   tcMessage - Mesajul
	*   tcSource - Sursa (optional)
	*---------------------------------------------------------------------------
	Procedure Info(tcMessage, tcSource)
		This.Log(tcMessage, "INFO", tcSource)
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Warning
	* Descriere: Scrie un avertisment
	* Parametri: 
	*   tcMessage - Mesajul
	*   tcSource - Sursa (optional)
	*---------------------------------------------------------------------------
	Procedure Warning(tcMessage, tcSource)
		This.Log(tcMessage, "WARNING", tcSource)
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Error
	* Descriere: Scrie o eroare
	* Parametri: 
	*   tcMessage - Mesajul
	*   tcSource - Sursa (optional)
	*---------------------------------------------------------------------------
	Procedure Error(tcMessage, tcSource)
		This.Log(tcMessage, "ERROR", tcSource)
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Debug
	* Descriere: Scrie un mesaj de debug
	* Parametri: 
	*   tcMessage - Mesajul
	*   tcSource - Sursa (optional)
	*---------------------------------------------------------------------------
	Procedure Debug(tcMessage, tcSource)
		This.Log(tcMessage, "DEBUG", tcSource)
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: LogParameters
	* Descriere: Logheaza parametrii unei proceduri
	* Parametri: 
	*   tcProcedure - Numele procedurii
	*   ... - Parametrii de logat (nume=valoare)
	*---------------------------------------------------------------------------
	Procedure LogParameters(tcProcedure)
		Local i, lcParams, lcParam
		
		lcParams = "PARAMETERS for " + tcProcedure + ": "
		
		For i = 2 To PCount()
			lcParam = Evaluate("m.p" + AllTrim(Str(i)))
			If VarType(lcParam) = 'C'
				lcParams = lcParams + lcParam + "; "
			EndIf
		EndFor
		
		This.Debug(lcParams, tcProcedure)
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: LogObject
	* Descriere: Logheaza proprietatile unui obiect
	* Parametri: 
	*   toObject - Obiectul de logat
	*   tcObjectName - Numele obiectului
	*---------------------------------------------------------------------------
	Procedure LogObject(toObject, tcObjectName)
		Local laProps[1], i, lcMessage, lcValue
		
		If VarType(toObject) <> 'O' Or IsNull(toObject)
			This.Debug(tcObjectName + " = NULL", "LogObject")
			Return
		EndIf
		
		AMembers(laProps, toObject, 0)
		
		lcMessage = tcObjectName + " Properties:" + Chr(13)
		For i = 1 To ALen(laProps)
			Try
				lcValue = Transform(Evaluate("toObject." + laProps[i]))
				lcMessage = lcMessage + "  " + laProps[i] + " = " + lcValue + Chr(13)
			Catch
				lcMessage = lcMessage + "  " + laProps[i] + " = <cannot read>" + Chr(13)
			EndTry
		EndFor
		
		This.Debug(lcMessage, "LogObject")
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: LogSeparator
	* Descriere: Scrie un separator in log
	* Parametri: 
	*   tcTitle - Titlul sectiunii (optional)
	*---------------------------------------------------------------------------
	Procedure LogSeparator(tcTitle)
		Local lcSeparator
		
		lcSeparator = Replicate("=", 60)
		This.Log(lcSeparator, "INFO", "")
		
		If Not Empty(tcTitle)
			This.Log("  " + tcTitle, "INFO", "")
			This.Log(lcSeparator, "INFO", "")
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: GetLogBuffer
	* Descriere: Returneaza continutul buffer-ului de log
	* Returneaza: String - Continutul buffer-ului
	*---------------------------------------------------------------------------
	Function GetLogBuffer()
		Local lcBuffer, i
		
		lcBuffer = ""
		For i = 1 To This.nBufferCount
			lcBuffer = lcBuffer + This.aLogBuffer[i] + Chr(13)
		EndFor
		
		Return lcBuffer
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: ClearBuffer
	* Descriere: Goleste buffer-ul de log
	*---------------------------------------------------------------------------
	Procedure ClearBuffer()
		This.nBufferCount = 0
		Dimension This.aLogBuffer[1]
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: SetLogLevel
	* Descriere: Seteaza nivelul de logging
	* Parametri: 
	*   tnLevel - Nivelul (1-4)
	*---------------------------------------------------------------------------
	Procedure SetLogLevel(tnLevel)
		This.nLogLevel = Max(1, Min(4, tnLevel))
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: SetConfig
	* Descriere: Seteaza referinta la ConfigProvider
	* Parametri: 
	*   toConfig - Obiectul ConfigProvider
	*---------------------------------------------------------------------------
	Procedure SetConfig(toConfig)
		This.oConfig = toConfig
		This.InitializeLogFile()
	EndProc
	
EndDefine
