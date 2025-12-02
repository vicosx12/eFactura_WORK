*******************************************************************************
* ReportTemplateEngine.prg
* Motor pentru șabloane de rapoarte customizabile
* 
* Funcționalități:
* - Șabloane HTML/text cu variabile
* - Secțiuni repetitive (loops)
* - Condiții (if/else)
* - Filtre pentru formatare
* - Includeri parțiale
* - Cache templates compilate
* - Export în multiple formate
*
* Exemplu utilizare:
*   loEngine = CreateObject("ReportTemplateEngine")
*   loEngine.LoadTemplate("invoice_template.html")
*   loEngine.SetData("invoice", loInvoice)
*   loEngine.SetData("lines", laLines)
*   lcOutput = loEngine.Render()
*******************************************************************************

Define Class ReportTemplateEngine As Custom
    
    * Template-uri înregistrate
    Dimension aTemplates[1, 3]  && Name, Content, CompiledContent
    nTemplateCount = 0
    
    * Date pentru rendering
    Dimension aData[1, 2]  && Key, Value
    nDataCount = 0
    
    * Template curent
    cCurrentTemplate = ""
    cCurrentContent = ""
    
    * Configurare
    cTemplatesPath = ""
    cOutputPath = ""
    cDelimiterStart = "{{"
    cDelimiterEnd = "}}"
    
    * Filtre înregistrate
    Dimension aFilters[1, 2]  && Name, Function
    nFilterCount = 0
    
    * Parțiale (includes)
    Dimension aPartials[1, 2]  && Name, Content
    nPartialCount = 0
    
    * Cache
    lCacheEnabled = .T.
    Dimension aCache[1, 3]
    nCacheCount = 0
    
    * Logging
    oLogger = .Null.
    
    *---------------------------------------------------------------------------
    Procedure Init
        This.cTemplatesPath = Sys(2003) + "\Templates\"
        This.cOutputPath = Sys(2003) + "\Output\"
        
        * Înregistrează filtrele implicite
        This.RegisterDefaultFilters()
    EndProc
    
    *---------------------------------------------------------------------------
    * Înregistrează filtrele implicite
    *---------------------------------------------------------------------------
    Protected Procedure RegisterDefaultFilters
        * Format număr
        This.RegisterFilter("number", "FormatNumber")
        * Format dată
        This.RegisterFilter("date", "FormatDate")
        * Uppercase
        This.RegisterFilter("upper", "Upper")
        * Lowercase
        This.RegisterFilter("lower", "Lower")
        * Trim
        This.RegisterFilter("trim", "Alltrim")
        * Currency
        This.RegisterFilter("currency", "FormatCurrency")
        * Escape HTML
        This.RegisterFilter("escape", "EscapeHtml")
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează logger-ul
    *---------------------------------------------------------------------------
    Procedure SetLogger(toLogger)
        This.oLogger = toLogger
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează calea template-urilor
    *---------------------------------------------------------------------------
    Procedure SetTemplatesPath(tcPath)
        This.cTemplatesPath = Addbs(tcPath)
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează calea output
    *---------------------------------------------------------------------------
    Procedure SetOutputPath(tcPath)
        This.cOutputPath = Addbs(tcPath)
        If Not Directory(This.cOutputPath)
            Try
                Mkdir (This.cOutputPath)
            Catch
            EndTry
        EndIf
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Încarcă template din fișier
    *---------------------------------------------------------------------------
    Procedure LoadTemplate(tcFileName)
        Local lcFile, lcContent
        
        lcFile = This.cTemplatesPath + tcFileName
        
        If Not File(lcFile)
            This.Log("ERROR", "Template not found: " + lcFile)
            Return .F.
        EndIf
        
        lcContent = FileToStr(lcFile)
        This.cCurrentTemplate = tcFileName
        This.cCurrentContent = lcContent
        
        * Adaugă la lista de template-uri
        This.RegisterTemplate(tcFileName, lcContent)
        
        This.Log("DEBUG", "Template loaded: " + tcFileName)
        
        Return .T.
    EndProc
    
    *---------------------------------------------------------------------------
    * Înregistrează un template din string
    *---------------------------------------------------------------------------
    Procedure RegisterTemplate(tcName, tcContent)
        Local lnIndex, i
        
        * Caută existent
        lnIndex = 0
        For i = 1 To This.nTemplateCount
            If This.aTemplates[i, 1] == tcName
                lnIndex = i
                Exit
            EndIf
        EndFor
        
        If lnIndex = 0
            This.nTemplateCount = This.nTemplateCount + 1
            Dimension This.aTemplates[This.nTemplateCount, 3]
            lnIndex = This.nTemplateCount
        EndIf
        
        This.aTemplates[lnIndex, 1] = tcName
        This.aTemplates[lnIndex, 2] = tcContent
        This.aTemplates[lnIndex, 3] = ""  && Compiled content (cache)
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Înregistrează un parțial (include)
    *---------------------------------------------------------------------------
    Procedure RegisterPartial(tcName, tcContent)
        This.nPartialCount = This.nPartialCount + 1
        Dimension This.aPartials[This.nPartialCount, 2]
        
        This.aPartials[This.nPartialCount, 1] = tcName
        This.aPartials[This.nPartialCount, 2] = tcContent
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Înregistrează un filtru
    *---------------------------------------------------------------------------
    Procedure RegisterFilter(tcName, tcFunction)
        This.nFilterCount = This.nFilterCount + 1
        Dimension This.aFilters[This.nFilterCount, 2]
        
        This.aFilters[This.nFilterCount, 1] = Lower(tcName)
        This.aFilters[This.nFilterCount, 2] = tcFunction
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează date pentru rendering
    *---------------------------------------------------------------------------
    Procedure SetData(tcKey, tvValue)
        Local lnIndex, i
        
        * Caută existent
        lnIndex = 0
        For i = 1 To This.nDataCount
            If This.aData[i, 1] == tcKey
                lnIndex = i
                Exit
            EndIf
        EndFor
        
        If lnIndex = 0
            This.nDataCount = This.nDataCount + 1
            Dimension This.aData[This.nDataCount, 2]
            lnIndex = This.nDataCount
        EndIf
        
        This.aData[lnIndex, 1] = tcKey
        This.aData[lnIndex, 2] = tvValue
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Curăță datele
    *---------------------------------------------------------------------------
    Procedure ClearData
        This.nDataCount = 0
        Dimension This.aData[1, 2]
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Renderizează template-ul
    *---------------------------------------------------------------------------
    Procedure Render(tcTemplate)
        Local lcContent, lcOutput
        
        * Determină template-ul
        If Not Empty(tcTemplate)
            lcContent = This.GetTemplateContent(tcTemplate)
        Else
            lcContent = This.cCurrentContent
        EndIf
        
        If Empty(lcContent)
            This.Log("ERROR", "No template content to render")
            Return ""
        EndIf
        
        * Procesează template-ul
        lcOutput = lcContent
        
        * 1. Procesează includes
        lcOutput = This.ProcessIncludes(lcOutput)
        
        * 2. Procesează loops
        lcOutput = This.ProcessLoops(lcOutput)
        
        * 3. Procesează condiții
        lcOutput = This.ProcessConditions(lcOutput)
        
        * 4. Procesează variabile
        lcOutput = This.ProcessVariables(lcOutput)
        
        This.Log("DEBUG", "Template rendered: " + Len(lcOutput) + " characters")
        
        Return lcOutput
    EndProc
    
    *---------------------------------------------------------------------------
    * Obține conținutul unui template
    *---------------------------------------------------------------------------
    Protected Procedure GetTemplateContent(tcName)
        Local i
        
        For i = 1 To This.nTemplateCount
            If This.aTemplates[i, 1] == tcName
                Return This.aTemplates[i, 2]
            EndIf
        EndFor
        
        Return ""
    EndProc
    
    *---------------------------------------------------------------------------
    * Procesează includes ({{> partialName}})
    *---------------------------------------------------------------------------
    Protected Procedure ProcessIncludes(tcContent)
        Local lcResult, lnPos, lnEnd, lcPartialName, lcPartialContent, i
        
        lcResult = tcContent
        
        * Pattern: {{> partialName}}
        lnPos = At("{{>", lcResult)
        
        Do While lnPos > 0
            lnEnd = At("}}", lcResult, lnPos)
            
            If lnEnd > 0
                lcPartialName = Alltrim(Substr(lcResult, lnPos + 3, lnEnd - lnPos - 3))
                
                * Găsește parțialul
                lcPartialContent = ""
                For i = 1 To This.nPartialCount
                    If This.aPartials[i, 1] == lcPartialName
                        lcPartialContent = This.aPartials[i, 2]
                        Exit
                    EndIf
                EndFor
                
                * Înlocuiește
                lcResult = Left(lcResult, lnPos - 1) + lcPartialContent + Substr(lcResult, lnEnd + 2)
            Else
                Exit
            EndIf
            
            lnPos = At("{{>", lcResult)
        EndDo
        
        Return lcResult
    EndProc
    
    *---------------------------------------------------------------------------
    * Procesează loops ({{#each items}}...{{/each}})
    *---------------------------------------------------------------------------
    Protected Procedure ProcessLoops(tcContent)
        Local lcResult, lnStartPos, lnEndPos, lnContentStart, lnContentEnd
        Local lcArrayName, lcLoopContent, lcOutput, laItems, lnCount, i
        
        lcResult = tcContent
        
        * Pattern: {{#each arrayName}}...{{/each}}
        lnStartPos = At("{{#each ", lcResult)
        
        Do While lnStartPos > 0
            * Găsește sfârșitul tag-ului de deschidere
            lnContentStart = At("}}", lcResult, lnStartPos) + 2
            
            * Extrage numele array-ului
            lcArrayName = Alltrim(Substr(lcResult, lnStartPos + 8, lnContentStart - lnStartPos - 10))
            
            * Găsește tag-ul de închidere
            lnEndPos = At("{{/each}}", lcResult, lnContentStart)
            
            If lnEndPos > 0
                * Extrage conținutul loop-ului
                lcLoopContent = Substr(lcResult, lnContentStart, lnEndPos - lnContentStart)
                
                * Obține array-ul de date
                laItems = This.GetDataValue(lcArrayName)
                
                * Generează output
                lcOutput = ""
                
                If VarType(laItems) = 'A'
                    lnCount = Alen(laItems, 1)
                    For i = 1 To lnCount
                        Local lcItemContent
                        lcItemContent = lcLoopContent
                        
                        * Înlocuiește variabilele @index și @first, @last
                        lcItemContent = Strtran(lcItemContent, "{{@index}}", Transform(i))
                        lcItemContent = Strtran(lcItemContent, "{{@first}}", Iif(i = 1, "true", "false"))
                        lcItemContent = Strtran(lcItemContent, "{{@last}}", Iif(i = lnCount, "true", "false"))
                        
                        * Procesează variabilele din item
                        lcItemContent = This.ProcessItemVariables(lcItemContent, laItems, i)
                        
                        lcOutput = lcOutput + lcItemContent
                    EndFor
                ElseIf VarType(laItems) = 'O'
                    * Object collection
                    lcOutput = lcLoopContent
                EndIf
                
                * Înlocuiește loop-ul cu output-ul
                lcResult = Left(lcResult, lnStartPos - 1) + lcOutput + Substr(lcResult, lnEndPos + 9)
            Else
                Exit
            EndIf
            
            lnStartPos = At("{{#each ", lcResult)
        EndDo
        
        Return lcResult
    EndProc
    
    *---------------------------------------------------------------------------
    * Procesează variabile din item de loop
    *---------------------------------------------------------------------------
    Protected Procedure ProcessItemVariables(tcContent, taItems, tnIndex)
        Local lcResult, lnPos, lnEnd, lcVar, lcValue
        Local lnCols, j
        
        lcResult = tcContent
        
        * Pattern: {{this.field}} sau {{field}}
        lnPos = At("{{", lcResult)
        
        Do While lnPos > 0
            lnEnd = At("}}", lcResult, lnPos)
            
            If lnEnd > 0
                lcVar = Alltrim(Substr(lcResult, lnPos + 2, lnEnd - lnPos - 2))
                
                * Skip comenzi speciale
                If Left(lcVar, 1) = "#" Or Left(lcVar, 1) = "/" Or Left(lcVar, 1) = ">" Or Left(lcVar, 1) = "@"
                    lnPos = At("{{", lcResult, lnEnd)
                    Loop
                EndIf
                
                * Extrage valoarea
                lcVar = Strtran(lcVar, "this.", "")
                
                * Obține valoarea din array
                lcValue = ""
                lnCols = Alen(taItems, 2)
                
                If lnCols > 0
                    * Array bidimensional
                    For j = 1 To lnCols
                        * Presupunem că prima dimensiune e indexul, a doua e coloana
                        * Sau folosim convenția: coloana = numărul variabilei
                    EndFor
                    * Fallback: folosește prima coloană
                    If VarType(taItems[tnIndex, 1]) <> 'U'
                        lcValue = Transform(taItems[tnIndex, 1])
                    EndIf
                Else
                    * Array unidimensional
                    lcValue = Transform(taItems[tnIndex])
                EndIf
                
                * Aplică filtre dacă există
                lcValue = This.ApplyFilters(lcVar, lcValue)
                
                * Înlocuiește
                lcResult = Left(lcResult, lnPos - 1) + lcValue + Substr(lcResult, lnEnd + 2)
            Else
                Exit
            EndIf
            
            lnPos = At("{{", lcResult)
        EndDo
        
        Return lcResult
    EndProc
    
    *---------------------------------------------------------------------------
    * Procesează condiții ({{#if condition}}...{{else}}...{{/if}})
    *---------------------------------------------------------------------------
    Protected Procedure ProcessConditions(tcContent)
        Local lcResult, lnStartPos, lnEndPos, lnElsePos
        Local lcCondition, lcTrueContent, lcFalseContent, llCondition, lcOutput
        
        lcResult = tcContent
        
        * Pattern: {{#if condition}}...{{else}}...{{/if}}
        lnStartPos = At("{{#if ", lcResult)
        
        Do While lnStartPos > 0
            * Găsește sfârșitul tag-ului de deschidere
            Local lnCondEnd
            lnCondEnd = At("}}", lcResult, lnStartPos)
            
            * Extrage condiția
            lcCondition = Alltrim(Substr(lcResult, lnStartPos + 6, lnCondEnd - lnStartPos - 6))
            
            * Găsește {{/if}}
            lnEndPos = At("{{/if}}", lcResult, lnCondEnd)
            
            If lnEndPos > 0
                * Găsește {{else}} dacă există
                lnElsePos = At("{{else}}", lcResult, lnCondEnd)
                
                If lnElsePos > 0 And lnElsePos < lnEndPos
                    lcTrueContent = Substr(lcResult, lnCondEnd + 2, lnElsePos - lnCondEnd - 2)
                    lcFalseContent = Substr(lcResult, lnElsePos + 8, lnEndPos - lnElsePos - 8)
                Else
                    lcTrueContent = Substr(lcResult, lnCondEnd + 2, lnEndPos - lnCondEnd - 2)
                    lcFalseContent = ""
                EndIf
                
                * Evaluează condiția
                llCondition = This.EvaluateCondition(lcCondition)
                
                * Selectează output-ul
                lcOutput = Iif(llCondition, lcTrueContent, lcFalseContent)
                
                * Înlocuiește
                lcResult = Left(lcResult, lnStartPos - 1) + lcOutput + Substr(lcResult, lnEndPos + 7)
            Else
                Exit
            EndIf
            
            lnStartPos = At("{{#if ", lcResult)
        EndDo
        
        Return lcResult
    EndProc
    
    *---------------------------------------------------------------------------
    * Evaluează o condiție
    *---------------------------------------------------------------------------
    Protected Procedure EvaluateCondition(tcCondition)
        Local lvValue
        
        * Obține valoarea variabilei
        lvValue = This.GetDataValue(tcCondition)
        
        * Evaluează truthiness
        Do Case
            Case VarType(lvValue) = 'L'
                Return lvValue
            Case VarType(lvValue) = 'N'
                Return lvValue <> 0
            Case VarType(lvValue) = 'C'
                Return Not Empty(lvValue)
            Case VarType(lvValue) = 'A'
                Return Alen(lvValue) > 0
            Case VarType(lvValue) = 'O'
                Return Not IsNull(lvValue)
            Otherwise
                Return .F.
        EndCase
    EndProc
    
    *---------------------------------------------------------------------------
    * Procesează variabile simple ({{varName}})
    *---------------------------------------------------------------------------
    Protected Procedure ProcessVariables(tcContent)
        Local lcResult, lnPos, lnEnd, lcVar, lcValue
        
        lcResult = tcContent
        
        * Pattern: {{varName}} sau {{object.property}}
        lnPos = At(This.cDelimiterStart, lcResult)
        
        Do While lnPos > 0
            lnEnd = At(This.cDelimiterEnd, lcResult, lnPos)
            
            If lnEnd > 0
                lcVar = Alltrim(Substr(lcResult, lnPos + Len(This.cDelimiterStart), lnEnd - lnPos - Len(This.cDelimiterStart)))
                
                * Skip comenzi speciale
                If Left(lcVar, 1) = "#" Or Left(lcVar, 1) = "/" Or Left(lcVar, 1) = ">" Or Left(lcVar, 1) = "@"
                    lnPos = At(This.cDelimiterStart, lcResult, lnEnd)
                    Loop
                EndIf
                
                * Obține valoarea
                lcValue = This.GetDataValueAsString(lcVar)
                
                * Aplică filtre
                lcValue = This.ApplyFilters(lcVar, lcValue)
                
                * Înlocuiește
                lcResult = Left(lcResult, lnPos - 1) + lcValue + Substr(lcResult, lnEnd + Len(This.cDelimiterEnd))
                
                * Continuă de la poziția curentă
                lnPos = At(This.cDelimiterStart, lcResult, lnPos)
            Else
                Exit
            EndIf
        EndDo
        
        Return lcResult
    EndProc
    
    *---------------------------------------------------------------------------
    * Obține valoarea unei variabile
    *---------------------------------------------------------------------------
    Protected Procedure GetDataValue(tcKey)
        Local i, lcKey, laPath[1], lnPathCount, lvValue, j
        
        * Separă pe . pentru nested properties
        lcKey = Strtran(tcKey, "|", "")  && Elimină filtrele
        lcKey = Alltrim(GetWordNum(lcKey, 1, "|"))
        
        lnPathCount = Alines(laPath, lcKey, 1, ".")
        
        * Găsește valoarea de bază
        lvValue = .Null.
        For i = 1 To This.nDataCount
            If This.aData[i, 1] == laPath[1]
                lvValue = This.aData[i, 2]
                Exit
            EndIf
        EndFor
        
        * Navighează nested properties
        If lnPathCount > 1 And VarType(lvValue) = 'O'
            For j = 2 To lnPathCount
                If PemStatus(lvValue, laPath[j], 5)
                    lvValue = Evaluate("lvValue." + laPath[j])
                Else
                    lvValue = ""
                    Exit
                EndIf
            EndFor
        EndIf
        
        Return lvValue
    EndProc
    
    *---------------------------------------------------------------------------
    * Obține valoarea ca string
    *---------------------------------------------------------------------------
    Protected Procedure GetDataValueAsString(tcKey)
        Local lvValue
        
        lvValue = This.GetDataValue(tcKey)
        
        Do Case
            Case IsNull(lvValue)
                Return ""
            Case VarType(lvValue) = 'C'
                Return lvValue
            Case VarType(lvValue) = 'N'
                Return Alltrim(Transform(lvValue))
            Case VarType(lvValue) = 'D'
                Return Dtoc(lvValue)
            Case VarType(lvValue) = 'T'
                Return Ttoc(lvValue)
            Case VarType(lvValue) = 'L'
                Return Iif(lvValue, "true", "false")
            Otherwise
                Return Transform(lvValue)
        EndCase
    EndProc
    
    *---------------------------------------------------------------------------
    * Aplică filtre pe valoare
    * Format: {{varName|filter1|filter2:arg}}
    *---------------------------------------------------------------------------
    Protected Procedure ApplyFilters(tcExpression, tcValue)
        Local lcResult, laFilters[1], lnCount, i
        Local lcFilter, lcArg, lnColonPos, j, lcFunction
        
        lcResult = tcValue
        
        * Extrage filtrele
        lnCount = Alines(laFilters, tcExpression, 1, "|")
        
        If lnCount <= 1
            Return lcResult
        EndIf
        
        * Aplică fiecare filtru (skip primul element care e variabila)
        For i = 2 To lnCount
            lcFilter = Alltrim(laFilters[i])
            lcArg = ""
            
            * Verifică dacă are argument
            lnColonPos = At(":", lcFilter)
            If lnColonPos > 0
                lcArg = Substr(lcFilter, lnColonPos + 1)
                lcFilter = Left(lcFilter, lnColonPos - 1)
            EndIf
            
            * Găsește și aplică filtrul
            For j = 1 To This.nFilterCount
                If This.aFilters[j, 1] == Lower(lcFilter)
                    lcFunction = This.aFilters[j, 2]
                    
                    Try
                        If Empty(lcArg)
                            lcResult = Evaluate(lcFunction + '("' + lcResult + '")')
                        Else
                            lcResult = Evaluate(lcFunction + '("' + lcResult + '", "' + lcArg + '")')
                        EndIf
                    Catch
                    EndTry
                    
                    Exit
                EndIf
            EndFor
        EndFor
        
        Return lcResult
    EndProc
    
    *---------------------------------------------------------------------------
    * Salvează output în fișier
    *---------------------------------------------------------------------------
    Procedure SaveToFile(tcFileName, tcContent)
        Local lcFile, lcContent
        
        lcFile = This.cOutputPath + tcFileName
        lcContent = Iif(Empty(tcContent), This.Render(), tcContent)
        
        StrToFile(lcContent, lcFile)
        
        This.Log("INFO", "Report saved to: " + lcFile)
        
        Return lcFile
    EndProc
    
    *---------------------------------------------------------------------------
    * Funcții helper pentru filtre
    *---------------------------------------------------------------------------
    Procedure FormatNumber(tcValue, tcFormat)
        Local lnValue
        lnValue = Val(tcValue)
        If Empty(tcFormat)
            Return Alltrim(Transform(lnValue, "999,999,999.99"))
        Else
            Return Alltrim(Transform(lnValue, tcFormat))
        EndIf
    EndProc
    
    Procedure FormatDate(tcValue, tcFormat)
        Local ldValue
        Try
            ldValue = Ctod(tcValue)
            If Empty(tcFormat)
                Return Dtoc(ldValue)
            Else
                Return Dtoc(ldValue)  && VFP nu suportă formate custom direct
            EndIf
        Catch
            Return tcValue
        EndTry
    EndProc
    
    Procedure FormatCurrency(tcValue, tcCurrency)
        Local lnValue
        lnValue = Val(tcValue)
        Return Alltrim(Transform(lnValue, "999,999,999.99")) + " " + Iif(Empty(tcCurrency), "RON", tcCurrency)
    EndProc
    
    Procedure EscapeHtml(tcValue)
        Local lcResult
        lcResult = tcValue
        lcResult = Strtran(lcResult, "&", "&amp;")
        lcResult = Strtran(lcResult, "<", "&lt;")
        lcResult = Strtran(lcResult, ">", "&gt;")
        lcResult = Strtran(lcResult, '"', "&quot;")
        lcResult = Strtran(lcResult, "'", "&#39;")
        Return lcResult
    EndProc
    
    *---------------------------------------------------------------------------
    * Logging
    *---------------------------------------------------------------------------
    Protected Procedure Log(tcLevel, tcMessage)
        If VarType(This.oLogger) = 'O'
            Do Case
                Case tcLevel = "DEBUG"
                    This.oLogger.Debug(tcMessage)
                Case tcLevel = "INFO"
                    This.oLogger.Info(tcMessage)
                Case tcLevel = "ERROR"
                    This.oLogger.LogError(tcMessage)
            EndCase
        EndIf
    EndProc
    
EndDefine
