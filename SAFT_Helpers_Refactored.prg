*!* ============================================================================
*!* FISIER: SAFT_Helpers_Refactored.prg
*!* ============================================================================
*!* Contine functiile ajutatoare refactorizate, necesare pentru functionarea
*!* codului din Repository si din alte parti.
*!* ============================================================================

*!*-----------------------------------------------------------------------------
*!* CLASS: TaxCodeResolver
*!* SCOP:  Centralizeaza logica pentru determinarea codului de taxa (TaxCode).
*!* Inlocuieste functia masiva si greu de intretinut GetTaxCode.
*!*-----------------------------------------------------------------------------
DEFINE CLASS TaxCodeResolver AS Custom

    FUNCTION GetTaxCode(toContext AS SAFT_Context, tcJournalId, tlStatusTvaIncasare, tcCont, tcCodTva, tcTip_Tert, tnId_Nota, tlVies, tcCeCont, tdDataDoc, tnProcTva, tcCodFiscal, tcTipFactura, tdDataDocReala)
        LOCAL lcTaxCode as String
        lcTaxCode = ""

        DO CASE
            CASE INLIST(tcJournalId, 'Intrari', 'Import')
                lcTaxCode = THIS.GetPurchaseTaxCode(toContext, tcJournalId, tlStatusTvaIncasare, tcCont, tcCodTva, tcTip_Tert, tnId_Nota, tlVies, tcCeCont, tdDataDoc, tnProcTva, tcCodFiscal, tcTipFactura, tdDataDocReala)
            CASE INLIST(tcJournalId, 'Iesiri', 'Export')
                lcTaxCode = THIS.GetSalesTaxCode(toContext, tcJournalId, tlStatusTvaIncasare, tcCont, tcCodTva, tcTip_Tert, tnId_Nota, tlVies, tcCeCont, tdDataDoc, tnProcTva, tcCodFiscal, tcTipFactura, tdDataDocReala)
        ENDCASE

        RETURN lcTaxCode
    ENDFUNC

    PROTECTED FUNCTION GetPurchaseTaxCode(toContext AS SAFT_Context, tcJournalId, tlStatusTvaIncasare, tcCont, tcCodTva, tcTip_Tert, tnId_Nota, tlVies, tcCeCont, tdDataDoc, tnProcTva, tcCodFiscal, tcTipFactura, tdDataDocReala)
        LOCAL lcTaxCode AS String
        lcTaxCode = ""

        LOCAL llSameDayPay AS Boolean
        llSameDayPay = .F.
        IF INLIST(tcJournalId, 'Intrari', 'Import')
            llSameDayPay = SameDayPay(tnId_Nota, tdDataDoc, tcJournalId)
        ENDIF

        DO CASE
            CASE tcTipFactura == 'A'
                lcTaxCode = THIS.GetPurchaseTaxCodeForAviz(tnProcTva)
            CASE tlStatusTvaIncasare AND NOT llSameDayPay
                lcTaxCode = THIS.GetPurchaseTaxCodeForTvaIncasare(tnProcTva, tdDataDoc)
            CASE tcCodTva == '6-7'
                lcTaxCode = THIS.GetPurchaseTaxCodeForStandardRate(tcTip_Tert, tcTipFactura, tcCont, tdDataDocReala, tdData1, llSameDayPay)
            CASE tcCodTva == '8-9'
                lcTaxCode = THIS.GetPurchaseTaxCodeForReducedRate1(tcTip_Tert, tcTipFactura, tcCont, tdDataDocReala, tdData1, llSameDayPay, tlStatusTvaIncasare)
            CASE tcCodTva == '19-20'
                lcTaxCode = THIS.GetPurchaseTaxCodeForReducedRate2(tcTip_Tert, tcTipFactura, tdDataDocReala, tdData1, llSameDayPay, tlStatusTvaIncasare)
            CASE tcCodTva == '10'
                lcTaxCode = THIS.GetPurchaseTaxCodeForZeroRate(tcTip_Tert, tcTipFactura)
            CASE tcCodTva == '13'
                lcTaxCode = "308303" && Achizitii de servicii intracomunitare scutite de taxa
            CASE tcCodTva == '14'
                lcTaxCode = "308302" && Achizitii de bunuri si servicii scutite de taxa sau neimpozabile
        ENDCASE

        RETURN lcTaxCode
    ENDFUNC

    PROTECTED FUNCTION GetPurchaseTaxCodeForAviz(tnProcTva)
        DO CASE
            CASE tnProcTva == 24
                RETURN '380105'
            CASE tnProcTva == 20
                RETURN '380104'
            CASE tnProcTva == 19
                RETURN '380101'
            CASE tnProcTva == 9
                RETURN '380102'
            CASE tnProcTva == 5
                RETURN '380103'
            OTHERWISE
                RETURN '000000'
        ENDCASE
    ENDFUNC

    PROTECTED FUNCTION GetPurchaseTaxCodeForTvaIncasare(tnProcTva, tdDataDoc)
        DO CASE
            CASE tnProcTva == 24 AND GetProcTva(tdDataDoc) <> 24
                RETURN '309105'
            CASE tnProcTva == 20 AND GetProcTva(tdDataDoc) <> 20
                RETURN '309104'
            CASE tnProcTva == 19
                RETURN '301301'
            CASE tnProcTva == 9
                RETURN '301302'
            CASE tnProcTva == 5
                RETURN '301303'
            CASE tnProcTva == 8
                RETURN '308301'
            CASE tnProcTva == 0
                RETURN '308302'
        ENDCASE
        RETURN ''
    ENDFUNC

    FUNCTION Get_GeneralLedgerEntries(toContext AS SAFT_Context)
        LOCAL lcSQL
        TEXT TO lcSQL NOSHOW TEXTMERGE
            SELECT
                r.Fel_D AS JournalId,
                'Registru jurnal' AS Description,
                r.Fel_D AS Type,
                RTRIM(CAST(r.Id AS C(10))) + ' - ' + RTRIM(r.Fel_D) + ' - ' + RTRIM(CAST(r.Id_Nota AS C(10))) AS TransactionId,
                MONTH(r.Data) AS Period,
                YEAR(r.Data) AS PeriodYear,
                r.Data AS TransactionDate,
                ISNULL(r.Explicatie, '') AS TransactionDescription,
                r.Data AS SystemEntryDate,
                r.Data AS GLPostingDate,
                r.Data AS DataDocReala,
                ISNULL(r.NDP, '') AS NDP,
                r.ContD,
                r.ContC,
                r.Suma,
                ISNULL(r.Cod_Valuta, 'RON') AS Cod_Valuta,
                ISNULL(r.Curs, 0.0000) AS Curs,
                ISNULL(r.Suma_Val, 0) AS Suma_Val,
                CAST('' AS C(15)) AS Cod_Fiscal,
                SPACE(2) AS Tara,
                SPACE(1) AS Tip_Tert,
                CAST(0 AS B) AS Vies,
                CAST(0 AS B) AS StatusTvaIncasare,
                SPACE(1) AS TipFactura,
                r.IdTva,
                SPACE(5) AS CodTva,
                SPACE(254) AS DenumireTva,
                SPACE(254) AS TaxBaseDescription,
                CAST(0 AS N(2)) AS ProcTva,
                SPACE(20) AS CeCont,
                SPACE(3) AS TaxDCA,
                SPACE(3) AS TaxType,
                SPACE(6) AS TaxCode,
                CAST(0 AS N(14,2)) AS TaxBase,
                CAST(0 AS N(14,2)) AS TaxAmount,
                SPACE(5) AS TipTva,
                r.IdTva AS IdTva_9,
                SPACE(5) AS CodTva_9,
                SPACE(254) AS DenumireTva_9,
                SPACE(254) AS TaxBaseDescription_9,
                CAST(0 AS N(2)) AS ProcTva_9,
                SPACE(20) AS CeCont_9,
                SPACE(3) AS TaxDCA_9,
                SPACE(3) AS TaxType_9,
                SPACE(6) AS TaxCode_9,
                CAST(0 AS N(14,2)) AS TaxBase_9,
                CAST(0 AS N(14,2)) AS TaxAmount_9,
                SPACE(5) AS TipTva_9,
                r.IdTva AS IdTva_5,
                SPACE(5) AS CodTva_5,
                SPACE(254) AS DenumireTva_5,
                SPACE(254) AS TaxBaseDescription_5,
                CAST(0 AS N(2)) AS ProcTva_5,
                SPACE(20) AS CeCont_5,
                SPACE(3) AS TaxDCA_5,
                SPACE(3) AS TaxType_5,
                SPACE(6) AS TaxCode_5,
                CAST(0 AS N(14,2)) AS TaxBase_5,
                CAST(0 AS N(14,2)) AS TaxAmount_5,
                SPACE(5) AS TipTva_5,
                r.IdCategorie,
                r.Categorie,
                r.PlanB,
                r.CapitolB,
                r.ArticolB,
                SPACE(4) AS Tip_Ded,
                CAST(0 AS B) AS IsTvaIncasare,
                r.ID AS Tranzactia,
                r.ID_Nota,
                CAST(0 AS I) AS IdFactura
            FROM Registru r
            WHERE r.Data BETWEEN ?toContext.StartDate AND ?toContext.EndDate
              AND ISNULL(r.Sters, 0) = 0
              AND ISNULL(ContD, '') <> ''
              AND ISNULL(ContC, '') <> ''
        ENDTEXT
        mySQLExec(lcSQL, "cGeneralLedgerEntries")
    ENDFUNC

    PROTECTED FUNCTION GetPurchaseTaxCodeForStandardRate(tcTip_Tert, tcTipFactura, tcCont, tdDataDocReala, tdData1, llSameDayPay)
        DO CASE
            CASE tcTip_Tert == '1' AND tcTipFactura == 'T'
                RETURN '300901'
            CASE tcTip_Tert == '2' AND tcTipFactura == 'T' AND INLIST(tcCont, '3', '20', '21', '22', '23', '60', '4091', '4093', '767')
                IF tdDataDocReala < tdData1
                    RETURN '300401'
                ELSE
                    RETURN '300201'
                ENDIF
            CASE tcTip_Tert == '2' AND EMPTY(tcTipFactura) AND INLIST(tcCont, '3', '20', '21', '22', '23', '60', '4091', '4093')
                RETURN '300101'
            CASE tcTip_Tert <> '1' AND tcTipFactura == 'T'
                IF tdDataDocReala < tdData1
                    RETURN '300801'
                ELSE
                    RETURN '300701'
                ENDIF
            OTHERWISE
                IF tdDataDocReala < tdData1
                    RETURN '309101'
                ELSE
                    RETURN '301101'
                ENDIF
        ENDCASE
        RETURN ''
    ENDFUNC

    PROTECTED FUNCTION GetPurchaseTaxCodeForReducedRate1(tcTip_Tert, tcTipFactura, tcCont, tdDataDocReala, tdData1, llSameDayPay, tlStatusTvaIncasare)
        DO CASE
            CASE tdDataDocReala < tdData1
                RETURN '309102'
            CASE tcTip_Tert == '1' AND tlStatusTvaIncasare
                IF llSameDayPay
                    RETURN '301102'
                ELSE
                    RETURN '301302'
                ENDIF
            CASE tcTip_Tert == '1' AND tcTipFactura == 'T'
                RETURN '300902'
            CASE tcTip_Tert == '2' AND EMPTY(tcTipFactura) AND INLIST(tcCont, '3', '20', '21', '22', '23', '60', '4091', '4093')
                RETURN '300102'
            CASE tcTip_Tert == '2' AND tcTipFactura == 'T' AND INLIST(tcCont, '3', '20', '21', '22', '23', '60', '4091', '4093', '767')
                RETURN '300202'
            CASE tcTip_Tert == '2' AND INLIST(tcCont, '3', '20', '21', '22', '23', '60', '4091', '4093') AND tdDataDocReala < tdData1
                RETURN '300402'
            CASE tcTip_Tert <> '1' AND tcTipFactura == 'T'
                IF tdDataDocReala < tdData1
                    RETURN '300802'
                ELSE
                    RETURN '300502'
                ENDIF
            OTHERWISE
                RETURN '301102'
        ENDCASE
        RETURN ''
    ENDFUNC

    PROTECTED FUNCTION GetPurchaseTaxCodeForReducedRate2(tcTip_Tert, tcTipFactura, tdDataDocReala, tdData1, llSameDayPay, tlStatusTvaIncasare)
        DO CASE
            CASE tdDataDocReala < tdData1
                RETURN '309103'
            CASE tcTip_Tert == '1' AND tlStatusTvaIncasare
                IF llSameDayPay
                    RETURN '301103'
                ELSE
                    RETURN '301303'
                ENDIF
            CASE tcTip_Tert <> '1' AND tcTipFactura == 'T'
                IF tdDataDocReala < tdData1
                    RETURN '300803'
                ELSE
                    RETURN '300703'
                ENDIF
            CASE tcTip_Tert == '1' AND tcTipFactura == 'T'
                RETURN '300903'
            OTHERWISE
                RETURN '301103'
        ENDCASE
        RETURN ''
    ENDFUNC

    PROTECTED FUNCTION GetPurchaseTaxCodeForZeroRate(tcTip_Tert, tcTipFactura)
        DO CASE
            CASE tcTip_Tert == '2' AND tcTipFactura == 'T'
                RETURN '308303'
            CASE tcTip_Tert == '1' AND EMPTY(tcTipFactura)
                RETURN '308302'
            OTHERWISE
                RETURN '308302'
        ENDCASE
        RETURN ''
    ENDFUNC

    PROTECTED FUNCTION GetSalesTaxCode(toContext AS SAFT_Context, tcJournalId, tlStatusTvaIncasare, tcCont, tcCodTva, tcTip_Tert, tnId_Nota, tlVies, tcCeCont, tdDataDoc, tnProcTva, tcCodFiscal, tcTipFactura, tdDataDocReala)
        LOCAL lcTaxCode AS String
        lcTaxCode = ""

        DO CASE
            CASE '00' + tcCodFiscal == CUI_Raportor AND tcTipFactura == ' '
                lcTaxCode = THIS.GetSalesTaxCodeForAutofactura(tnProcTva)
            CASE INLIST(tcTipFactura, 'B', 'C', 'e')
                lcTaxCode = THIS.GetSalesTaxCodeForBonFiscal(tnProcTva)
            CASE tcTipFactura == 'A'
                lcTaxCode = THIS.GetSalesTaxCodeForAviz(tnProcTva)
            CASE tcTipFactura == 'W'
                lcTaxCode = '310325'
            CASE tcTipFactura == 'X'
                lcTaxCode = '310340'
            CASE tlStatusTvaIncasare
                lcTaxCode = THIS.GetSalesTaxCodeForTvaIncasare(tnProcTva, tdDataDoc, llSameDayPay)
            CASE tnProcTva == 24 AND GetProcTva(tdDataDoc) <> 24
                lcTaxCode = '310315'
            CASE tnProcTva == 20 AND GetProcTva(tdDataDoc) <> 20
                lcTaxCode = '310316'
            CASE tcCodTva == '6-7'
                lcTaxCode = THIS.GetSalesTaxCodeForStandardRate(tcTipFactura, tcTip_Tert, tdDataDocReala, tdData1)
            CASE tcCodTva == '8-9'
                lcTaxCode = THIS.GetSalesTaxCodeForReducedRate1(tcTipFactura, tcTip_Tert, tdDataDocReala, tdData1)
            CASE tcCodTva == '19-20'
                lcTaxCode = THIS.GetSalesTaxCodeForReducedRate2(tcTipFactura, tcTip_Tert, tdDataDocReala, tdData1)
            CASE tcCodTva == '10'
                lcTaxCode = THIS.GetSalesTaxCodeForZeroRate1(tcTip_Tert, tlVies)
            CASE tcCodTva == '12'
                lcTaxCode = THIS.GetSalesTaxCodeForExport(tcTipFactura, tcCeCont)
            CASE tcCodTva == '14'
                lcTaxCode = THIS.GetSalesTaxCodeForIntraCommunity(tcTip_Tert, tlVies, tdDataDocReala, tdData1)
            CASE tcCodTva == '15'
                lcTaxCode = THIS.GetSalesTaxCodeForIntraCommunitySpecial(tcTip_Tert, tdDataDocReala, tdData1, tcCeCont)
            CASE tcCodTva == '16'
                lcTaxCode = THIS.GetSalesTaxCodeForOtherExempt(tcTip_Tert, tcTipFactura, tdDataDoc)
            CASE tcCodTva == '17'
                lcTaxCode = '310326'
            CASE tcCodTva == '18' OR tcTipFactura == 'n'
                lcTaxCode = '310324'
            CASE tnProcTva == 0
                lcTaxCode = THIS.GetSalesTaxCodeForZeroTva(tcTipFactura, tcTip_Tert, tcCeCont, tdDataDocReala, tdData1)
        ENDCASE

        RETURN lcTaxCode
    ENDFUNC

    PROTECTED FUNCTION GetSalesTaxCodeForAutofactura(tnProcTva)
        DO CASE
            CASE tnProcTva == 24
                RETURN '380005'
            CASE tnProcTva == 20
                RETURN '380004'
            CASE tnProcTva == 19
                RETURN '380001'
            CASE tnProcTva == 9
                RETURN '380002'
            CASE tnProcTva == 5
                RETURN '380003'
            OTHERWISE
                RETURN '000000'
        ENDCASE
    ENDFUNC

    PROTECTED FUNCTION GetSalesTaxCodeForBonFiscal(tnProcTva)
        DO CASE
            CASE tnProcTva == 19
                RETURN '380301'
            CASE tnProcTva == 9
                RETURN '380302'
            CASE tnProcTva == 5
                RETURN '380303'
            OTHERWISE
                RETURN '380304'
        ENDCASE
    ENDFUNC

    PROTECTED FUNCTION GetSalesTaxCodeForAviz(tnProcTva)
        DO CASE
            CASE tnProcTva == 24
                RETURN '380105'
            CASE tnProcTva == 20
                RETURN '380104'
            CASE tnProcTva == 19
                RETURN '380101'
            CASE tnProcTva == 9
                RETURN '380102'
            CASE tnProcTva == 5
                RETURN '380103'
            OTHERWISE
                RETURN '000000'
        ENDCASE
    ENDFUNC

    PROTECTED FUNCTION GetSalesTaxCodeForTvaIncasare(tnProcTva, tdDataDoc, llSameDayPay)
        DO CASE
            CASE tnProcTva == 24 AND GetProcTva(tdDataDoc) <> 24
                RETURN '310315'
            CASE tnProcTva == 20 AND GetProcTva(tdDataDoc) <> 20
                RETURN '310316'
            CASE tnProcTva == 19
                RETURN IIF(llSameDayPay, '310309', '310335')
            CASE tnProcTva == 9
                RETURN IIF(llSameDayPay, '310310', '310336')
            CASE tnProcTva == 5
                RETURN IIF(llSameDayPay, '310311', '310337')
            CASE tnProcTva == 0
                RETURN '310326'
        ENDCASE
        RETURN ''
    ENDFUNC

    PROTECTED FUNCTION GetSalesTaxCodeForStandardRate(tcTipFactura, tcTip_Tert, tdDataDocReala, tdData1)
        DO CASE
            CASE EMPTY(tcTipFactura) AND tcTip_Tert == '1' AND tdDataDocReala < tdData1
                RETURN '310317'
            CASE (EMPTY(tcTipFactura) OR tcTipFactura == 'f') AND tcTip_Tert == '1'
                RETURN '310309'
            CASE tcTipFactura == 'Y' AND tcTip_Tert == '2' AND tdDataDocReala < tdData1
                RETURN '310321'
            CASE tcTipFactura == 'Y' AND tcTip_Tert == '2'
                RETURN '310320'
            OTHERWISE
                RETURN '310309'
        ENDCASE
    ENDFUNC

    PROTECTED FUNCTION GetSalesTaxCodeForReducedRate1(tcTipFactura, tcTip_Tert, tdDataDocReala, tdData1)
        DO CASE
            CASE EMPTY(tcTipFactura) AND tcTip_Tert == '1' AND tdDataDocReala < tdData1
                RETURN '310318'
            CASE (EMPTY(tcTipFactura) OR tcTipFactura == 'f') AND tcTip_Tert == '1'
                RETURN '310310'
            OTHERWISE
                RETURN '310310'
        ENDCASE
    ENDFUNC

    PROTECTED FUNCTION GetSalesTaxCodeForReducedRate2(tcTipFactura, tcTip_Tert, tdDataDocReala, tdData1)
        DO CASE
            CASE EMPTY(tcTipFactura) AND tcTip_Tert == '1' AND tdDataDocReala < tdData1
                RETURN '310319'
            CASE (EMPTY(tcTipFactura) OR tcTipFactura == 'f') AND tcTip_Tert == '1'
                RETURN '310311'
            CASE tcTipFactura == 'Y' AND tcTip_Tert == '2' AND tdDataDocReala < tdData1
                RETURN '310329'
            CASE tcTipFactura == 'Y' AND tcTip_Tert == '2'
                RETURN '310328'
            OTHERWISE
                RETURN '310311'
        ENDCASE
    ENDFUNC

    PROTECTED FUNCTION GetSalesTaxCodeForZeroRate1(tcTip_Tert, tlVies)
        DO CASE
            CASE tcTip_Tert == '1' AND tlVies
                RETURN '310312'
            CASE tcTip_Tert == '2'
                RETURN '310314'
        ENDCASE
        RETURN ''
    ENDFUNC

    PROTECTED FUNCTION GetSalesTaxCodeForExport(tcTipFactura, tcCeCont)
        IF tcTipFactura == 'E'
            IF INLIST(tcCeCont, '701', '702', '703', '707', '7583', '419')
                RETURN '310304'
            ELSE
                RETURN '310305'
            ENDIF
        ELSE
            RETURN '310313'
        ENDIF
    ENDFUNC

    PROTECTED FUNCTION GetSalesTaxCodeForIntraCommunity(tcTip_Tert, tlVies, tdDataDocReala, tdData1)
        DO CASE
            CASE EMPTY(tcTipFactura) AND tcTip_Tert == '2' AND tdDataDocReala < tdData1
                RETURN '310302'
            CASE EMPTY(tcTipFactura) AND tcTip_Tert == '2' AND tlVies
                RETURN '310301'
            CASE tcTip_Tert == '3'
                RETURN '310313'
        ENDCASE
        RETURN ''
    ENDFUNC

    PROTECTED FUNCTION GetSalesTaxCodeForIntraCommunitySpecial(tcTip_Tert, tdDataDocReala, tdData1, tcCeCont)
        LOCAL lSir_Bunuri_Iesiri AS Boolean
        lSir_Bunuri_Iesiri = INLIST(LEFT(ALLTRIM(NVL(tcCeCont, SPACE(0))), 3), '701', '702', '703', '707', '7583', '419')

        DO CASE
            CASE EMPTY(tcTipFactura) AND tcTip_Tert == '2' AND tdDataDocReala < tdData1
                RETURN '310302'
            CASE EMPTY(tcTipFactura) AND tcTip_Tert == '2'
                IF !lSir_Bunuri_Iesiri
                    RETURN '310307'
                ELSE
                    RETURN '310304'
                ENDIF
            CASE EMPTY(tcTipFactura) AND (tcTip_Tert == '2' OR tcTip_Tert == '3') AND lSir_Bunuri_Iesiri
                RETURN '310304'
            CASE EMPTY(tcTipFactura) AND tcTip_Tert == '3' AND !lSir_Bunuri_Iesiri
                RETURN '310305'
        ENDCASE
        RETURN ''
    ENDFUNC

    PROTECTED FUNCTION GetSalesTaxCodeForOtherExempt(tcTip_Tert, tcTipFactura, tdDataDoc)
        DO CASE
            CASE tcTip_Tert == '1' AND INLIST(tcTipFactura, "S", "U", "H") OR (INLIST(tcTipFactura, "D", "d") AND tdDataDoc < CToD("01.08.2023"))
                RETURN '310314'
            CASE tcTip_Tert == '1' AND tcTipFactura == "D" AND tdDataDoc >= CToD("01.08.2023")
                RETURN '310341'
            CASE tcTip_Tert == '1' AND tcTipFactura == "d" AND tdDataDoc >= CToD("01.08.2023")
                RETURN '310342'
            CASE INLIST(tcTipFactura, 'T', 'S', 'U', 'E') AND tcTip_Tert == '2'
                RETURN '310312'
            CASE EMPTY(tcTipFactura) AND tcTip_Tert == '3'
                RETURN '310313'
            CASE EMPTY(tcTipFactura) AND tcTip_Tert <> '3'
                RETURN '310314'
            OTHERWISE
                RETURN '#TaxCode'
        ENDCASE
    ENDFUNC

    PROTECTED FUNCTION GetSalesTaxCodeForZeroTva(tcTipFactura, tcTip_Tert, tcCeCont, tdDataDocReala, tdData1)
        DO CASE
            CASE tcTipFactura == 'T'
                IF ISNULL(Tip_Tert)
                    RETURN '310312'
                ELSE
                    RETURN '310314'
                ENDIF
            CASE tcTipFactura == 'n' OR tcTipFactura == 'f'
                RETURN '310324'
            CASE tcTip_Tert == '1' AND INLIST(tcTipFactura, "S", "U", "H") OR (INLIST(tcTipFactura, "D", "d") AND tdDataDoc < CToD("01.08.2023"))
                RETURN '310314'
            CASE tcTip_Tert == '1' AND tcTipFactura == "D" AND tdDataDoc >= CToD("01.08.2023")
                RETURN '310341'
            CASE tcTip_Tert == '1' AND tcTipFactura == "d" AND tdDataDoc >= CToD("01.08.2023")
                RETURN '310342'
            OTHERWISE
                DO CASE
                    CASE tcTip_Tert == '2'
                        DO CASE
                            CASE tcTipFactura == 'E'
                                DO CASE
                                    CASE INLIST(tcCeCont, '7583') AND ISNULL(tcCodFiscal)
                                        RETURN '310303'
                                    CASE INLIST(tcCeCont, '701', '702', '703', '707', '419', '7583')
                                        IF tdDataDocReala < tdData1
                                            RETURN '310302'
                                        ELSE
                                            RETURN '310301'
                                        ENDIF
                                    CASE NOT INLIST(tcCeCont, '701', '702', '703', '707', '7583', '419', '446')
                                        RETURN '310306'
                                    CASE tcCeCont == '446'
                                        RETURN '310314'
                                ENDCASE
                            CASE (tcTipFactura == 'N' OR tcTipFactura == '') AND NOT ISNULL(tcCodFiscal) AND NOT INLIST(tcCeCont, '701', '702', '703', '707', '7583', '419', '446')
                                IF tdDataDocReala < tdData1
                                    RETURN '310308'
                                ELSE
                                    RETURN '310307'
                                ENDIF
                            CASE (tcTipFactura == 'N' OR tcTipFactura == '') AND INLIST(tcCeCont, '701', '702', '703', '707', '7583', '419')
                                IF tdDataDocReala < tdData1
                                    RETURN '310302'
                                ELSE
                                    RETURN '310301'
                                ENDIF
                            CASE tcCeCont == '446'
                                RETURN '310314'
                        ENDCASE
                    CASE tcTip_Tert == 'E'
                        IF tcTipFactura == 'E'
                            IF INLIST(tcCeCont, '701', '702', '703', '707', '7583', '419')
                                RETURN '310304'
                            ELSE
                                RETURN '310305'
                            ENDIF
                        ELSE
                            RETURN '310313'
                        ENDIF
                    OTHERWISE
                        RETURN '310326'
                ENDCASE
        ENDCASE
        RETURN ''
    ENDFUNC

ENDDEFINE
