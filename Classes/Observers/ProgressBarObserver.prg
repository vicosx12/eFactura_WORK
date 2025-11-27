******************************************************************************************
*  CLASS: ProgressBarObserver
*
*  AUTHOR: Refactored OOP Architecture
*
*  DESCRIPTION:
*     Observer pentru actualizarea progress bar-ului UI.
*     Primeste notificari de la ProgressSubject si actualizeaza
*     elementul vizual de progres.
*
*  DESIGN PATTERN: Observer Pattern (Observer)
*
*  USAGE:
*     loObserver = CreateObject("ProgressBarObserver")
*     loObserver.SetProgressBar(oMyProgressBar)
*     loSubject.Attach(loObserver)
*
******************************************************************************************

Define Class ProgressBarObserver As Custom
	
	*-- Referinta la progress bar
	oProgressBar = .Null.
	
	*-- Referinta la label (optional)
	oLabel = .Null.
	
	*-- Ultima valoare pentru a evita actualizari inutile
	nLastPercent = -1
	
	*-- Flag pentru afisare in consola
	lShowInConsole = .F.
	
	*---------------------------------------------------------------------------
	* Procedura: Init
	* Descriere: Initializeaza observatorul
	*---------------------------------------------------------------------------
	Procedure Init()
		This.nLastPercent = -1
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: SetProgressBar
	* Descriere: Seteaza referinta la progress bar
	* Parametri: 
	*   toProgressBar - Obiectul progress bar
	*---------------------------------------------------------------------------
	Procedure SetProgressBar(toProgressBar)
		This.oProgressBar = toProgressBar
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: SetLabel
	* Descriere: Seteaza referinta la label pentru mesaj
	* Parametri: 
	*   toLabel - Obiectul label
	*---------------------------------------------------------------------------
	Procedure SetLabel(toLabel)
		This.oLabel = toLabel
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Update
	* Descriere: Actualizeaza progress bar-ul (implementare Observer)
	* Parametri: 
	*   tnPercent - Procentul de progres (0-100)
	*   tcMessage - Mesajul de progres
	*---------------------------------------------------------------------------
	Procedure Update(tnPercent, tcMessage)
		*-- Evita actualizari pentru acelasi procent
		If tnPercent = This.nLastPercent
			Return
		EndIf
		This.nLastPercent = tnPercent
		
		*-- Actualizeaza progress bar
		If VarType(This.oProgressBar) = 'O' And Not IsNull(This.oProgressBar)
			Try
				This.oProgressBar.Value = tnPercent
			Catch
			EndTry
		EndIf
		
		*-- Actualizeaza label
		If VarType(This.oLabel) = 'O' And Not IsNull(This.oLabel) And Not Empty(tcMessage)
			Try
				This.oLabel.Caption = tcMessage
			Catch
			EndTry
		EndIf
		
		*-- Afisare in consola
		If This.lShowInConsole
			? "[" + Transform(tnPercent) + "%] " + Iif(Empty(tcMessage), "", tcMessage)
		EndIf
		
		*-- Refresh UI
		DoEvents
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Error
	* Descriere: Afiseaza un mesaj de eroare
	* Parametri: 
	*   tcMessage - Mesajul de eroare
	*---------------------------------------------------------------------------
	Procedure Error(tcMessage)
		*-- Actualizeaza label cu rosu daca e posibil
		If VarType(This.oLabel) = 'O' And Not IsNull(This.oLabel)
			Try
				This.oLabel.Caption = "EROARE: " + tcMessage
				This.oLabel.ForeColor = Rgb(255, 0, 0)
			Catch
			EndTry
		EndIf
		
		If This.lShowInConsole
			? "[EROARE] " + tcMessage
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Reset
	* Descriere: Reseteaza progress bar-ul
	*---------------------------------------------------------------------------
	Procedure Reset()
		This.nLastPercent = -1
		
		If VarType(This.oProgressBar) = 'O' And Not IsNull(This.oProgressBar)
			Try
				This.oProgressBar.Value = 0
			Catch
			EndTry
		EndIf
		
		If VarType(This.oLabel) = 'O' And Not IsNull(This.oLabel)
			Try
				This.oLabel.Caption = ""
				This.oLabel.ForeColor = Rgb(0, 0, 0)
			Catch
			EndTry
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Destroy
	* Descriere: Curata resursele
	*---------------------------------------------------------------------------
	Procedure Destroy()
		This.oProgressBar = .Null.
		This.oLabel = .Null.
	EndProc
	
EndDefine


******************************************************************************************
*  CLASS: LogObserver
*
*  AUTHOR: Refactored OOP Architecture
*
*  DESCRIPTION:
*     Observer pentru logging-ul progresului.
*     Primeste notificari de la ProgressSubject si le scrie in log.
*
*  DESIGN PATTERN: Observer Pattern (Observer)
*
******************************************************************************************

Define Class LogObserver As Custom
	
	*-- Referinta la LoggerService
	oLogger = .Null.
	
	*-- Prefix pentru mesaje
	cPrefix = "PROGRESS"
	
	*---------------------------------------------------------------------------
	* Procedura: SetLogger
	* Descriere: Seteaza referinta la LoggerService
	* Parametri: 
	*   toLogger - Obiectul LoggerService
	*---------------------------------------------------------------------------
	Procedure SetLogger(toLogger)
		This.oLogger = toLogger
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Update
	* Descriere: Scrie progresul in log
	* Parametri: 
	*   tnPercent - Procentul de progres (0-100)
	*   tcMessage - Mesajul de progres
	*---------------------------------------------------------------------------
	Procedure Update(tnPercent, tcMessage)
		Local lcLog
		
		lcLog = "[" + This.cPrefix + " " + Transform(tnPercent) + "%]"
		If Not Empty(tcMessage)
			lcLog = lcLog + " " + tcMessage
		EndIf
		
		If VarType(This.oLogger) = 'O' And Not IsNull(This.oLogger)
			This.oLogger.Info(lcLog, "ProgressObserver")
		Else
			? lcLog
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Error
	* Descriere: Scrie o eroare in log
	* Parametri: 
	*   tcMessage - Mesajul de eroare
	*---------------------------------------------------------------------------
	Procedure Error(tcMessage)
		If VarType(This.oLogger) = 'O' And Not IsNull(This.oLogger)
			This.oLogger.Error(tcMessage, "ProgressObserver")
		Else
			? "[EROARE] " + tcMessage
		EndIf
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: Destroy
	* Descriere: Curata resursele
	*---------------------------------------------------------------------------
	Procedure Destroy()
		This.oLogger = .Null.
	EndProc
	
EndDefine
