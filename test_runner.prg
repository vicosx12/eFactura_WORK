*!* ============================================================================
*!* FISIER: test_runner.prg
*!* ============================================================================
*!* SCOP:  Script de test pentru a valida noua arhitectura de generare SAF-T.
*!* ============================================================================

SET PROCEDURE TO SAFT_Main_Advanced.prg ADDITIVE

*-- Definire parametri de test
LOCAL ldTestStart, ldTestEnd, lcTestType, lnTestSegments
ldTestStart = {^2023-01-01}
ldTestEnd = {^2023-01-31}
lcTestType = "L"
lnTestSegments = 1

*-- Rulare proces de generare
LOCAL llSuccess
llSuccess = SAFT_Main_Advanced(ldTestStart, ldTestEnd, lcTestType, lnTestSegments)

*-- Verificare rezultate
IF llSuccess
    *-- Verifica daca fisierul final a fost creat
    LOCAL lcExpectedFile
    lcExpectedFile = Get_FullPath_SAFT_File(ldTestStart, ldTestEnd, lcTestType, lnTestSegments)

    IF FILE(lcExpectedFile)
        *-- Aici se pot adauga verificari mai complexe,
        *-- cum ar fi validarea XML-ului sau compararea cu un fisier "golden"
        ? "SUCCESS: Fisierul SAF-T a fost generat cu succes la calea: " + lcExpectedFile
    ELSE
        ? "FAIL: Procesul s-a incheiat, dar fisierul final nu a fost gasit la calea: " + lcExpectedFile
    ENDIF
ELSE
    ? "FAIL: Procesul de generare a esuat."
ENDIF

RETURN
