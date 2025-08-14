*!* ============================================================================
*!* FISIER: SAFT_TrialBalanceGenerator.prg
*!* ============================================================================
*!* Contine clasa pentru generarea balantei de verificare.
*!* ============================================================================

*!*-----------------------------------------------------------------------------
*!* CLASS: TrialBalanceGenerator
*!* SCOP:  Centralizeaza logica pentru generarea balantei de verificare.
*!* Inlocuieste functia masiva si greu de intretinut GetBalantaSAFT.
*!*-----------------------------------------------------------------------------
DEFINE CLASS TrialBalanceGenerator AS Custom

    FUNCTION Generate(toContext AS SAFT_Context)
        LOCAL llSuccess as Boolean
        llSuccess = .F.

        THIS.CreateCursors(toContext)
        THIS.CalculateInitialBalances(toContext)
        THIS.CalculateTotals(toContext)
        THIS.SummarizeSyntheticAccounts(toContext)
        THIS.FinalizeBalances(toContext)

        llSuccess = .T.
        RETURN llSuccess
    ENDFUNC

    PROTECTED FUNCTION CreateCursors(toContext AS SAFT_Context)
        BalantaSintetica(1, 0, [], .T.)
    ENDFUNC

    PROTECTED FUNCTION CalculateInitialBalances(toContext AS SAFT_Context)
        SELECT Con_Temp
        DELETE FOR INLIST(LEFT(Cont, 1), "8", "9")

        UPDATE Con_Temp SET Sold_In_D = Deb_Prec - Cred_Prec WHERE Tip = 'A' OR (Tip = 'B' AND Deb_Prec >= Cred_Prec)
        UPDATE Con_Temp SET Sold_In_C = Cred_Prec - Deb_Prec WHERE Tip = 'P' OR (Tip = 'B' AND Cred_Prec > Deb_Prec)
    ENDFUNC

    PROTECTED FUNCTION CalculateTotals(toContext AS SAFT_Context)
        SELECT Con_Temp
        UPDATE Con_Temp SET Total_Deb = Rulaj_D + Deb_Prec, Total_Cred = Rulaj_C + Cred_Prec
        UPDATE Con_Temp SET Fin_D = Total_Deb - Total_Cred WHERE Tip = 'A' OR (Tip = 'B' AND Total_Deb >= Total_Cred)
        UPDATE Con_Temp SET Fin_C = Total_Cred - Total_Deb WHERE Tip = 'P' OR (Tip = 'B' AND Total_Cred > Total_Deb)
        REPLACE RulajT_D WITH Total_Deb - Deb_Init, RulajT_C WITH Total_Cred - Cred_Init ALL
    ENDFUNC

    PROTECTED FUNCTION SummarizeSyntheticAccounts(toContext AS SAFT_Context)
        LOCAL lcSQL AS STRING

        TEXT TO lcSQL NOSHOW TEXTMERGE
            SELECT Left(Cont, 3) AS Cont1,;
                   SUM(Deb_Init) AS Deb_Init,;
                   SUM(Cred_Init) AS Cred_Init,;
                   SUM(Deb_Prec) AS Deb_Prec,;
                   SUM(Cred_Prec) AS Cred_Prec,;
                   SUM(Sold_In_D) AS Sold_In_D,;
                   SUM(Sold_In_C) AS Sold_In_C,;
                   SUM(Rulaj_D) AS Rulaj_D,;
                   SUM(Rulaj_C) AS Rulaj_C,;
                   SUM(RulajT_D) AS RulajT_D,;
                   SUM(RulajT_C) AS RulajT_C,;
                   SUM(Total_Deb) AS Total_Deb,;
                   SUM(Total_Cred) AS Total_Cred,;
                   SUM(Fin_D) AS Fin_D,;
                   SUM(Fin_C) AS Fin_C;
            FROM Con_Temp;
            WHERE LEN(ALLTRIM(Cont)) > 3 AND NOT ("."$Cont) AND EMPTY(Categorie);
            GROUP BY Cont1;
            INTO CURSOR CurSum READWRITE
        ENDTEXT
        mySQLExec(lcSQL, "CurSum")

        SELECT Con_Temp
        SCAN FOR LEN(ALLTRIM(Cont)) = 3 AND IsNullOrEmpty(Categorie)
            SELECT CurSum
            LOCATE FOR Cont1 == ALLTRIM(Con_Temp.Cont)
            IF FOUND()
                SELECT Con_Temp
                REPLACE Deb_Init WITH Deb_Init + CurSum.Deb_Init,;
                        Cred_Init WITH Cred_Init + CurSum.Cred_Init,;
                        Deb_Prec WITH Deb_Prec + CurSum.Deb_Prec,;
                        Cred_Prec WITH Cred_Prec + CurSum.Cred_Prec,;
                        Sold_In_D WITH Sold_In_D + CurSum.Sold_In_D,;
                        Sold_In_C WITH Sold_In_C + CurSum.Sold_In_C,;
                        Rulaj_D WITH Rulaj_D + CurSum.Rulaj_D,;
                        Rulaj_C WITH Rulaj_C + CurSum.Rulaj_C,;
                        Total_Deb WITH Total_Deb + CurSum.Total_Deb,;
                        Total_Cred WITH Total_Cred + CurSum.Total_Cred,;
                        Fin_D WITH Fin_D + CurSum.Fin_D,;
                        Fin_C WITH Fin_C + CurSum.Fin_C
            ENDIF
        ENDSCAN
    ENDFUNC

    PROTECTED FUNCTION FinalizeBalances(toContext AS SAFT_Context)
        UPDATE Con_Temp SET Deb_Init = Deb_Init - Cred_Init, Cred_Init = 0 WHERE LEN(ALLTRIM(Cont)) = 3 AND IsNullOrEmpty(Categorie) AND (Tip = 'A' OR (Tip = 'B' AND Deb_Init >= Cred_Init))
        UPDATE Con_Temp SET Sold_In_D = Sold_In_D - Sold_In_C, Sold_In_C = 0 WHERE LEN(ALLTRIM(Cont)) = 3 AND IsNullOrEmpty(Categorie) AND (Tip = 'A' OR (Tip = 'B' AND Sold_In_D >= Sold_In_C))
        UPDATE Con_Temp SET Fin_D = Total_Deb - Total_Cred, Fin_C = 0 WHERE LEN(ALLTRIM(Cont)) = 3 AND IsNullOrEmpty(Categorie) AND (Tip = 'A' OR (Tip = 'B' AND Total_Deb >= Total_Cred))
        UPDATE Con_Temp SET Cred_Init = Cred_Init - Deb_Init, Deb_Init = 0 WHERE LEN(ALLTRIM(Cont)) = 3 AND IsNullOrEmpty(Categorie) AND (Tip = 'P' OR (Tip = 'B' AND Cred_Init > Deb_Init))
        UPDATE Con_Temp SET Sold_In_C = Sold_In_C - Sold_In_D, Sold_In_D = 0 WHERE LEN(ALLTRIM(Cont)) = 3 AND IsNullOrEmpty(Categorie) AND (Tip = 'P' OR (Tip = 'B' AND Sold_In_C > Sold_In_D))
        UPDATE Con_Temp SET Fin_C = Total_Cred - Total_Deb, Fin_D = 0 WHERE LEN(ALLTRIM(Cont)) = 3 AND IsNullOrEmpty(Categorie) AND (Tip = 'P' OR (Tip = 'B' AND Total_Cred > Total_Deb))

        REPLACE RulajT_D WITH Total_Deb - Deb_Init, RulajT_C WITH Total_Cred - Cred_Init ALL

        LOCAL llIsFirstDayOfYear AS Boolean
        llIsFirstDayOfYear = toContext.StartDate == CToD('01.01.' + ALLTRIM(TRANSFORM(YEAR(toContext.StartDate))))
        IF llIsFirstDayOfYear
            UPDATE Con_Temp SET Deb_Prec = Deb_Init, Cred_Prec = Cred_Init
        ENDIF

        DELETE FROM Con_Temp WHERE Validat = 0 AND Sintetic = .F. AND NVL(Fin_C, 0) = 0 AND NVL(Fin_D, 0) = 0 AND Cont NOT IN (SELECT DISTINCT Cont FROM cGetConturiRulajePerioada)
        DELETE FROM Con_Temp WHERE (NVL(Deb_Init, 0) = 0 AND NVL(Cred_Init, 0) = 0) AND (NVL(Rulaj_D, 0) = 0 AND NVL(Rulaj_C, 0) = 0) AND (NVL(Deb_Prec, 0) = 0 AND NVL(Cred_Prec, 0) = 0) AND (NVL(Total_Deb, 0) = 0 AND NVL(Total_Cred, 0) = 0) AND Validat = 0 AND Sintetic = .T. AND Cont NOT IN (SELECT DISTINCT Cont FROM cGetConturiRulajePerioada)
    ENDFUNC

ENDDEFINE
