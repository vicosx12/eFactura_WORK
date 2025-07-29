*!* ============================================================================
*!* FISIER: SAFT_Main_Advanced.prg
*!* ============================================================================
*!* AUTOR: Gemini AI
*!* DATA:  26.06.2025
*!* SCOP:  Punct de intrare pentru arhitectura avansata.
*!* Orchestreaza crearea componentelor (Context, Repository, Logger, Builder)
*!* si porneste executia lantului de responsabilitati.
*!* ============================================================================
LPARAMETERS tdData1, tdData2, tcTipDeclaratie, tnSegmente


*#DEFINE FORCE_REFRESH		.T.
*PUBLIC FORCE_REFRESH
FORCE_REFRESH = .T.

IF TYPE('glForceVIES')='U'
	glForceVIES = .F.
ENDIF

PUBLIC DEBUG_SAFT
DEBUG_SAFT			= VarType(m.DebugSAFT)#'U'


*-- Se asigura ca functiile ajutatoare sunt disponibile
SET PROCEDURE TO SAFT_Advanced_Classes.prg ADDITIVE
SET PROCEDURE TO SAFT_Helpers.prg ADDITIVE
SET PROCEDURE TO SAFT_TrialBalanceGenerator.prg ADDITIVE

CLOSE DATABASES ALL

LOCAL loContext AS SAFT_Context
LOCAL loRepo AS SAFT_Repository
LOCAL loLogger AS SAFT_Logger
LOCAL loBuilder AS SAFT_ChainBuilder
LOCAL loChainHead AS Handler_Base
LOCAL llSuccess AS Boolean

*-- Validare parametri
IF EMPTY(tdData1) OR EMPTY(tdData2)
    MESSAGEBOX("Perioada (Data1, Data2) este obligatorie!", 16, "Eroare Parametri")
    RETURN .F.
ENDIF
tcTipDeclaratie = IIF(EMPTY(tcTipDeclaratie), "L", UPPER(ALLTRIM(tcTipDeclaratie)))
tnSegmente = IIF(EMPTY(tnSegmente), 1, tnSegmente)

TRY
    *-- 1. Initializare componente decuplate
    loRepo				= CREATEOBJECT("SAFT_Repository")
    loLogger			= CREATEOBJECT("SAFT_Logger")
    loProgressUI		= CREATEOBJECT("SAFT_Progress_UI_Console")
    loSummaryCollector	= CREATEOBJECT("SAFT_Summary_Collector")




    *-- 2. Creare Context. Acesta va fi singurul obiect pasat între handlere.
    loContext			= CREATEOBJECT("SAFT_Context", tdData1, tdData2, tcTipDeclaratie, tnSegmente)
    *-- Atasare observatori
    loContext.AttachObserver(loLogger)
    loContext.AttachObserver(loProgressUI)
    loContext.AttachObserver(loSummaryCollector)
    *-- Notifica observatorii ca procesul începe (Logger-ul va scrie în fisier)
    loContext.Notify("PROCESS_START", "Initiere generare SAF-T...")

	loConfig = CREATEOBJECT("ConfigManager")
    loContext.Notify("ENVIRONMENT", "ConfigManager initializat.")

    lcLogFile			= loContext.LogFile
    lcTipDeclaratie		= loContext.DeclarationType
    CUI_Raportor		= '00'+ICAS.oSoc.CodFiscal
    vTipConta			= IIF(IsNullOrEmpty(ALLTRIM(ICAS.oSoc.SaFT_TipConta)), 'A', ALLTRIM(ICAS.oSoc.SaFT_TipConta))
    lcDirectorSAFT		= loConfig.GetValue("Paths", "OutputDirectory", "Declaratii")
    Data1				= loContext.StartDate
    Data2				= loContext.EndDate
    lnCalupInregGLE		= VAL(loConfig.GetValue("SAFT", "GLE_ChunkSize", "50000"))

	lcModPlataTva=GetModPlataTva(tdData2)
	gcTaxType='000'
	*
	Do Case
		Case lcModPlataTva=1		&& Lunar
			*lcTaxType='301'
			gcTaxType='300'
		Case lcModPlataTva=2		&& Trimestrial
			*lcTaxType='302'
			gcTaxType='300'
		Case lcModPlataTva=3		&& Semestrial
			*lcTaxType='303'
			gcTaxType='300'
		Case lcModPlataTva=4		&& Anual
			*lcTaxType='304'
			gcTaxType='300'
		OtherWise					&& Neplatitor
			gcTaxType='000'
	EndCase
	*
	Tabela_Erori_Saft('Creare_Tabela_Erori')
	loContext.Notify("ENVIRONMENT", "Initializare environment...")

	SAFT_Mapare()
	loContext.Notify("ENVIRONMENT", "SAFT_Mapare...")
	loTrialBalanceGenerator = CREATEOBJECT("TrialBalanceGenerator")
    loTrialBalanceGenerator.Generate(loContext)
	loContext.Notify("ENVIRONMENT", "TrialBalanceGenerator.Generate(loContext)...")


    loContext.SetRepository(loRepo)

    *-- 3. Construire lant de handlere folosind un Builder
    loBuilder	= CREATEOBJECT("SAFT_ChainBuilder")
    loChainHead	= loBuilder.BuildChain(loContext)

    IF VARTYPE(loChainHead) != "O"
        loContext.Notify("FATAL_ERROR", "Tip de declaratie nerecunoscut: " + tcTipDeclaratie)
        RETURN .F.
    ENDIF

    *-- 4. Notifica observatorii despre startul procesului (trimite lista de pasi)
    *LOCAL ARRAY aSteps[1]
    *loBuilder.GetHandlerList(loChainHead, @aSteps)
    *loContext.Notify("PROCESS_START", @aSteps)
    loSteps = loBuilder.GetHandlerList(loChainHead)
    loContext.Notify("PROCESS_START", loSteps)

    *-- 5. Executia lantului. Apelam doar primul handler.
    llSuccess = loChainHead.Execute(loContext)
    loContext.Notify("PROCESS_END", llSuccess)


    llSuccess = !loContext.HasErrors

CATCH TO oException
    MESSAGEBOX("Eroare neasteptata în procesul principal: " + oException.Message, 16, "Eroare Fatala")

    IF VARTYPE(loContext) = "O"
        loContext.Notify("FATAL_ERROR", "Eroare: " + oException.Message + " în " + oException.Procedure + " la linia " + TRANSFORM(oException.LineNo))
    ENDIF

    Set Step On
    llSuccess = .F.
ENDTRY

*-- Afisare rezultat final
IF llSuccess
	loSummaryCollector.DisplaySummary(loContext)
    MESSAGEBOX("Generarea fisierului SAF-T a fost finalizata cu succes!", 64, "Proces Finalizat")
ELSE
    MESSAGEBOX("Generarea fisierului SAF-T a esuat. Verificati fisierul de log pentru detalii.", 16, "Proces Esuat")
ENDIF

*!*	RELEASE ALL LIKE lo*
RETURN llSuccess
