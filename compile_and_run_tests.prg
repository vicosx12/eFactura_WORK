*!* ============================================================================
*!* FISIER: compile_and_run_tests.prg
*!* ============================================================================
*!* SCOP:  Compileaza noua arhitectura si ruleaza scriptul de test.
*!* ============================================================================

SET SAFETY OFF

*-- Compilare fisiere
COMPILE SAFT_Advanced_Classes.prg
COMPILE SAFT_Helpers_Refactored.prg
COMPILE SAFT_TrialBalanceGenerator.prg
COMPILE SAFT_Main_Advanced.prg
COMPILE SAFT_UI_Adaptat.prg
COMPILE test_runner.prg

*-- Rulare teste
DO test_runner.prg

SET SAFETY ON
QUIT
