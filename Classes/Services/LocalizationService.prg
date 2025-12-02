*******************************************************************************
* LocalizationService.prg
* Serviciu pentru suport multi-limbă (RO, EN, HU)
* 
* Funcționalități:
* - Încărcare traduceri din fișiere
* - Interpolare variabile în mesaje
* - Fallback la limba implicită
* - Pluralizare
* - Formatare date/numere specifică locale
* - Cache traduceri
*
* Exemplu utilizare:
*   loLoc = CreateObject("LocalizationService")
*   loLoc.SetLocale("EN")
*   loLoc.LoadFromFile("translations.json")
*   lcMessage = loLoc.Translate("invoice.created", "invoiceNumber", "123")
*******************************************************************************

Define Class LocalizationService As Custom
    
    * Locale curent
    cCurrentLocale = "RO"
    cDefaultLocale = "RO"
    
    * Locale-uri suportate
    Dimension aSupportedLocales[3]
    nSupportedCount = 3
    
    * Traduceri: aTranslations[locale, key, value]
    Dimension aTranslations[1, 3]
    nTranslationCount = 0
    
    * Pluralizări
    Dimension aPluralRules[1, 5]  && Locale, Key, Zero, One, Many
    nPluralCount = 0
    
    * Formate locale
    Dimension aDateFormats[1, 2]   && Locale, Format
    Dimension aNumberFormats[1, 4] && Locale, DecimalSep, ThousandsSep, CurrencySymbol
    nFormatCount = 0
    
    * Cache
    Dimension aCache[1, 3]  && Key, Value, Timestamp
    nCacheCount = 0
    lCacheEnabled = .T.
    nCacheTTL = 3600
    
    * Logging
    oLogger = .Null.
    
    *---------------------------------------------------------------------------
    Procedure Init
        * Inițializare locale-uri suportate
        This.aSupportedLocales[1] = "RO"
        This.aSupportedLocales[2] = "EN"
        This.aSupportedLocales[3] = "HU"
        
        * Încarcă formatele implicite
        This.InitDefaultFormats()
        
        * Încarcă traducerile implicite
        This.InitDefaultTranslations()
    EndProc
    
    *---------------------------------------------------------------------------
    * Inițializează formatele implicite
    *---------------------------------------------------------------------------
    Protected Procedure InitDefaultFormats
        * Date formats
        This.SetDateFormat("RO", "DD.MM.YYYY")
        This.SetDateFormat("EN", "MM/DD/YYYY")
        This.SetDateFormat("HU", "YYYY.MM.DD")
        
        * Number formats
        This.SetNumberFormat("RO", ",", ".", "RON")
        This.SetNumberFormat("EN", ".", ",", "RON")
        This.SetNumberFormat("HU", ",", " ", "RON")
    EndProc
    
    *---------------------------------------------------------------------------
    * Încarcă traducerile implicite
    *---------------------------------------------------------------------------
    Protected Procedure InitDefaultTranslations
        * Română
        This.Add("RO", "app.name", "eFactura")
        This.Add("RO", "invoice.created", "Factura {invoiceNumber} a fost creată")
        This.Add("RO", "invoice.uploaded", "Factura a fost încărcată la ANAF")
        This.Add("RO", "invoice.confirmed", "Factura a fost confirmată de ANAF")
        This.Add("RO", "invoice.rejected", "Factura a fost respinsă: {reason}")
        This.Add("RO", "error.validation", "Eroare de validare: {message}")
        This.Add("RO", "error.network", "Eroare de rețea. Încercați din nou.")
        This.Add("RO", "error.timeout", "Timpul de așteptare a expirat")
        This.Add("RO", "progress.validating", "Se validează datele...")
        This.Add("RO", "progress.generating", "Se generează XML-ul...")
        This.Add("RO", "progress.uploading", "Se încarcă la ANAF...")
        This.Add("RO", "progress.complete", "Complet!")
        This.Add("RO", "button.ok", "OK")
        This.Add("RO", "button.cancel", "Anulare")
        This.Add("RO", "button.retry", "Reîncearcă")
        
        * Engleză
        This.Add("EN", "app.name", "eFactura")
        This.Add("EN", "invoice.created", "Invoice {invoiceNumber} has been created")
        This.Add("EN", "invoice.uploaded", "Invoice has been uploaded to ANAF")
        This.Add("EN", "invoice.confirmed", "Invoice has been confirmed by ANAF")
        This.Add("EN", "invoice.rejected", "Invoice has been rejected: {reason}")
        This.Add("EN", "error.validation", "Validation error: {message}")
        This.Add("EN", "error.network", "Network error. Please try again.")
        This.Add("EN", "error.timeout", "Request timed out")
        This.Add("EN", "progress.validating", "Validating data...")
        This.Add("EN", "progress.generating", "Generating XML...")
        This.Add("EN", "progress.uploading", "Uploading to ANAF...")
        This.Add("EN", "progress.complete", "Complete!")
        This.Add("EN", "button.ok", "OK")
        This.Add("EN", "button.cancel", "Cancel")
        This.Add("EN", "button.retry", "Retry")
        
        * Maghiară
        This.Add("HU", "app.name", "eFactura")
        This.Add("HU", "invoice.created", "A(z) {invoiceNumber} számla létrehozva")
        This.Add("HU", "invoice.uploaded", "A számla feltöltve az ANAF-hoz")
        This.Add("HU", "invoice.confirmed", "A számlát az ANAF megerősítette")
        This.Add("HU", "invoice.rejected", "A számlát elutasították: {reason}")
        This.Add("HU", "error.validation", "Érvényesítési hiba: {message}")
        This.Add("HU", "error.network", "Hálózati hiba. Próbálja újra.")
        This.Add("HU", "error.timeout", "A kérés időtúllépés")
        This.Add("HU", "progress.validating", "Adatok ellenőrzése...")
        This.Add("HU", "progress.generating", "XML generálása...")
        This.Add("HU", "progress.uploading", "Feltöltés az ANAF-hoz...")
        This.Add("HU", "progress.complete", "Kész!")
        This.Add("HU", "button.ok", "OK")
        This.Add("HU", "button.cancel", "Mégse")
        This.Add("HU", "button.retry", "Újra")
        
        * Pluralizări
        This.AddPlural("RO", "invoice.count", "nicio factură", "{count} factură", "{count} facturi")
        This.AddPlural("EN", "invoice.count", "no invoices", "{count} invoice", "{count} invoices")
        This.AddPlural("HU", "invoice.count", "nincs számla", "{count} számla", "{count} számla")
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează locale-ul curent
    *---------------------------------------------------------------------------
    Procedure SetLocale(tcLocale)
        tcLocale = Upper(tcLocale)
        
        If This.IsSupportedLocale(tcLocale)
            This.cCurrentLocale = tcLocale
            This.InvalidateCache()
            This.Log("INFO", "Locale changed to: " + tcLocale)
            Return .T.
        EndIf
        
        This.Log("WARNING", "Unsupported locale: " + tcLocale)
        Return .F.
    EndProc
    
    *---------------------------------------------------------------------------
    * Obține locale-ul curent
    *---------------------------------------------------------------------------
    Procedure GetLocale
        Return This.cCurrentLocale
    EndProc
    
    *---------------------------------------------------------------------------
    * Verifică dacă locale-ul este suportat
    *---------------------------------------------------------------------------
    Procedure IsSupportedLocale(tcLocale)
        Local i
        
        For i = 1 To This.nSupportedCount
            If Upper(This.aSupportedLocales[i]) == Upper(tcLocale)
                Return .T.
            EndIf
        EndFor
        
        Return .F.
    EndProc
    
    *---------------------------------------------------------------------------
    * Adaugă o traducere
    *---------------------------------------------------------------------------
    Procedure Add(tcLocale, tcKey, tcValue)
        Local lnIndex
        
        lnIndex = This.FindTranslationIndex(tcLocale, tcKey)
        If lnIndex = 0
            This.nTranslationCount = This.nTranslationCount + 1
            Dimension This.aTranslations[This.nTranslationCount, 3]
            lnIndex = This.nTranslationCount
        EndIf
        
        This.aTranslations[lnIndex, 1] = Upper(tcLocale)
        This.aTranslations[lnIndex, 2] = tcKey
        This.aTranslations[lnIndex, 3] = tcValue
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Adaugă regulă de pluralizare
    *---------------------------------------------------------------------------
    Procedure AddPlural(tcLocale, tcKey, tcZero, tcOne, tcMany)
        This.nPluralCount = This.nPluralCount + 1
        Dimension This.aPluralRules[This.nPluralCount, 5]
        
        This.aPluralRules[This.nPluralCount, 1] = Upper(tcLocale)
        This.aPluralRules[This.nPluralCount, 2] = tcKey
        This.aPluralRules[This.nPluralCount, 3] = tcZero
        This.aPluralRules[This.nPluralCount, 4] = tcOne
        This.aPluralRules[This.nPluralCount, 5] = tcMany
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Traduce o cheie
    * Parametrii: tcKey, apoi perechi de variabile: "var1", value1, "var2", value2
    *---------------------------------------------------------------------------
    Procedure Translate(tcKey, p1, v1, p2, v2, p3, v3, p4, v4, p5, v5)
        Local lcValue, lcCacheKey
        
        * Verifică cache
        lcCacheKey = This.cCurrentLocale + ":" + tcKey
        If This.lCacheEnabled
            lcValue = This.GetFromCache(lcCacheKey)
            If Not Empty(lcValue)
                Return This.Interpolate(lcValue, p1, v1, p2, v2, p3, v3, p4, v4, p5, v5)
            EndIf
        EndIf
        
        * Caută traducerea
        lcValue = This.GetTranslation(This.cCurrentLocale, tcKey)
        
        * Fallback la locale implicit
        If Empty(lcValue) And This.cCurrentLocale <> This.cDefaultLocale
            lcValue = This.GetTranslation(This.cDefaultLocale, tcKey)
        EndIf
        
        * Fallback la cheie
        If Empty(lcValue)
            lcValue = tcKey
        EndIf
        
        * Cache
        If This.lCacheEnabled
            This.AddToCache(lcCacheKey, lcValue)
        EndIf
        
        * Interpolează variabilele
        Return This.Interpolate(lcValue, p1, v1, p2, v2, p3, v3, p4, v4, p5, v5)
    EndProc
    
    *---------------------------------------------------------------------------
    * Shortcut pentru Translate
    *---------------------------------------------------------------------------
    Procedure T(tcKey, p1, v1, p2, v2, p3, v3, p4, v4, p5, v5)
        Return This.Translate(tcKey, p1, v1, p2, v2, p3, v3, p4, v4, p5, v5)
    EndProc
    
    *---------------------------------------------------------------------------
    * Traduce cu pluralizare
    *---------------------------------------------------------------------------
    Procedure TranslatePlural(tcKey, tnCount)
        Local lcValue, i
        
        * Caută regula de pluralizare
        For i = 1 To This.nPluralCount
            If This.aPluralRules[i, 1] == This.cCurrentLocale And This.aPluralRules[i, 2] == tcKey
                Do Case
                    Case tnCount = 0
                        lcValue = This.aPluralRules[i, 3]
                    Case tnCount = 1
                        lcValue = This.aPluralRules[i, 4]
                    Otherwise
                        lcValue = This.aPluralRules[i, 5]
                EndCase
                
                Return This.Interpolate(lcValue, "count", Transform(tnCount))
            EndIf
        EndFor
        
        * Fallback
        Return This.Translate(tcKey, "count", Transform(tnCount))
    EndProc
    
    *---------------------------------------------------------------------------
    * Interpolează variabile în text
    *---------------------------------------------------------------------------
    Protected Procedure Interpolate(tcText, p1, v1, p2, v2, p3, v3, p4, v4, p5, v5)
        Local lcResult
        
        lcResult = tcText
        
        If Not Empty(p1)
            lcResult = Strtran(lcResult, "{" + p1 + "}", Transform(v1))
        EndIf
        If Not Empty(p2)
            lcResult = Strtran(lcResult, "{" + p2 + "}", Transform(v2))
        EndIf
        If Not Empty(p3)
            lcResult = Strtran(lcResult, "{" + p3 + "}", Transform(v3))
        EndIf
        If Not Empty(p4)
            lcResult = Strtran(lcResult, "{" + p4 + "}", Transform(v4))
        EndIf
        If Not Empty(p5)
            lcResult = Strtran(lcResult, "{" + p5 + "}", Transform(v5))
        EndIf
        
        Return lcResult
    EndProc
    
    *---------------------------------------------------------------------------
    * Obține traducerea pentru locale și cheie
    *---------------------------------------------------------------------------
    Protected Procedure GetTranslation(tcLocale, tcKey)
        Local i
        
        For i = 1 To This.nTranslationCount
            If This.aTranslations[i, 1] == Upper(tcLocale) And This.aTranslations[i, 2] == tcKey
                Return This.aTranslations[i, 3]
            EndIf
        EndFor
        
        Return ""
    EndProc
    
    *---------------------------------------------------------------------------
    * Găsește indexul unei traduceri
    *---------------------------------------------------------------------------
    Protected Procedure FindTranslationIndex(tcLocale, tcKey)
        Local i
        
        For i = 1 To This.nTranslationCount
            If This.aTranslations[i, 1] == Upper(tcLocale) And This.aTranslations[i, 2] == tcKey
                Return i
            EndIf
        EndFor
        
        Return 0
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează formatul datei pentru un locale
    *---------------------------------------------------------------------------
    Procedure SetDateFormat(tcLocale, tcFormat)
        This.nFormatCount = This.nFormatCount + 1
        Dimension This.aDateFormats[This.nFormatCount, 2]
        
        This.aDateFormats[This.nFormatCount, 1] = Upper(tcLocale)
        This.aDateFormats[This.nFormatCount, 2] = tcFormat
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează formatul numerelor pentru un locale
    *---------------------------------------------------------------------------
    Procedure SetNumberFormat(tcLocale, tcDecimalSep, tcThousandsSep, tcCurrency)
        Local lnIndex, i
        
        * Caută sau adaugă
        lnIndex = 0
        For i = 1 To Alen(This.aNumberFormats, 1)
            If VarType(This.aNumberFormats[i, 1]) = 'C' And This.aNumberFormats[i, 1] == Upper(tcLocale)
                lnIndex = i
                Exit
            EndIf
        EndFor
        
        If lnIndex = 0
            lnIndex = Alen(This.aNumberFormats, 1) + 1
            Dimension This.aNumberFormats[lnIndex, 4]
        EndIf
        
        This.aNumberFormats[lnIndex, 1] = Upper(tcLocale)
        This.aNumberFormats[lnIndex, 2] = tcDecimalSep
        This.aNumberFormats[lnIndex, 3] = tcThousandsSep
        This.aNumberFormats[lnIndex, 4] = tcCurrency
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Formatează o dată conform locale-ului curent
    *---------------------------------------------------------------------------
    Procedure FormatDate(tdDate, tcLocale)
        Local lcFormat, lcLocale, i, lcResult
        
        lcLocale = Iif(Empty(tcLocale), This.cCurrentLocale, Upper(tcLocale))
        lcFormat = "DD.MM.YYYY"  && default
        
        * Găsește formatul
        For i = 1 To Alen(This.aDateFormats, 1)
            If VarType(This.aDateFormats[i, 1]) = 'C' And This.aDateFormats[i, 1] == lcLocale
                lcFormat = This.aDateFormats[i, 2]
                Exit
            EndIf
        EndFor
        
        * Formatează
        lcResult = lcFormat
        lcResult = Strtran(lcResult, "YYYY", Transform(Year(tdDate)))
        lcResult = Strtran(lcResult, "MM", Padl(Month(tdDate), 2, "0"))
        lcResult = Strtran(lcResult, "DD", Padl(Day(tdDate), 2, "0"))
        
        Return lcResult
    EndProc
    
    *---------------------------------------------------------------------------
    * Formatează un număr conform locale-ului curent
    *---------------------------------------------------------------------------
    Procedure FormatNumber(tnValue, tnDecimals, tlCurrency, tcLocale)
        Local lcLocale, lcDecSep, lcThSep, lcCurrency, i
        Local lcResult, lnInt, lnDec, lcInt, lcDec
        
        lcLocale = Iif(Empty(tcLocale), This.cCurrentLocale, Upper(tcLocale))
        lcDecSep = ","
        lcThSep = "."
        lcCurrency = "RON"
        
        * Găsește formatul
        For i = 1 To Alen(This.aNumberFormats, 1)
            If VarType(This.aNumberFormats[i, 1]) = 'C' And This.aNumberFormats[i, 1] == lcLocale
                lcDecSep = This.aNumberFormats[i, 2]
                lcThSep = This.aNumberFormats[i, 3]
                lcCurrency = This.aNumberFormats[i, 4]
                Exit
            EndIf
        EndFor
        
        * Formatează
        lnInt = Int(Abs(tnValue))
        lnDec = Round((Abs(tnValue) - lnInt) * (10 ^ tnDecimals), 0)
        
        * Partea întreagă cu separatori de mii
        lcInt = Transform(lnInt)
        lcResult = ""
        For i = Len(lcInt) To 1 Step -3
            If i > 3
                lcResult = lcThSep + Substr(lcInt, Max(i - 2, 1), Min(3, i)) + lcResult
            Else
                lcResult = Substr(lcInt, 1, i) + lcResult
            EndIf
        EndFor
        
        * Adaugă zecimale
        If tnDecimals > 0
            lcResult = lcResult + lcDecSep + Padl(Transform(lnDec), tnDecimals, "0")
        EndIf
        
        * Semn negativ
        If tnValue < 0
            lcResult = "-" + lcResult
        EndIf
        
        * Monedă
        If tlCurrency
            lcResult = lcResult + " " + lcCurrency
        EndIf
        
        Return lcResult
    EndProc
    
    *---------------------------------------------------------------------------
    * Încarcă traduceri din fișier JSON
    *---------------------------------------------------------------------------
    Procedure LoadFromFile(tcFileName)
        Local lcContent
        
        If Not File(tcFileName)
            This.Log("ERROR", "Translation file not found: " + tcFileName)
            Return .F.
        EndIf
        
        lcContent = FileToStr(tcFileName)
        
        * Parse simplu JSON - în producție folosiți un parser complet
        This.ParseTranslations(lcContent)
        
        This.Log("INFO", "Translations loaded from: " + tcFileName)
        Return .T.
    EndProc
    
    Protected Procedure ParseTranslations(tcJson)
        * Implementare simplificată
        * În producție, folosiți un parser JSON complet
    EndProc
    
    *---------------------------------------------------------------------------
    * Exportă traducerile în JSON
    *---------------------------------------------------------------------------
    Procedure ExportToFile(tcFileName)
        Local lcContent, i, lcLocale
        
        lcContent = "{" + Chr(13) + Chr(10)
        
        * Grupează pe locale
        For Each lcLocale In This.aSupportedLocales
            lcContent = lcContent + '  "' + lcLocale + '": {' + Chr(13) + Chr(10)
            
            For i = 1 To This.nTranslationCount
                If This.aTranslations[i, 1] == lcLocale
                    lcContent = lcContent + '    "' + This.aTranslations[i, 2] + '": '
                    lcContent = lcContent + '"' + This.EscapeJson(This.aTranslations[i, 3]) + '"'
                    lcContent = lcContent + ',' + Chr(13) + Chr(10)
                EndIf
            EndFor
            
            lcContent = lcContent + "  }," + Chr(13) + Chr(10)
        EndFor
        
        lcContent = lcContent + "}"
        
        StrToFile(lcContent, tcFileName)
        
        This.Log("INFO", "Translations exported to: " + tcFileName)
        Return .T.
    EndProc
    
    Protected Procedure EscapeJson(tcValue)
        Local lcResult
        lcResult = tcValue
        lcResult = Strtran(lcResult, '\', '\\')
        lcResult = Strtran(lcResult, '"', '\"')
        lcResult = Strtran(lcResult, Chr(13), '\r')
        lcResult = Strtran(lcResult, Chr(10), '\n')
        Return lcResult
    EndProc
    
    *---------------------------------------------------------------------------
    * Cache management
    *---------------------------------------------------------------------------
    Protected Procedure GetFromCache(tcKey)
        Local i
        
        For i = 1 To This.nCacheCount
            If This.aCache[i, 1] == tcKey
                If Seconds() - This.aCache[i, 3] < This.nCacheTTL
                    Return This.aCache[i, 2]
                EndIf
            EndIf
        EndFor
        
        Return ""
    EndProc
    
    Protected Procedure AddToCache(tcKey, tcValue)
        This.nCacheCount = This.nCacheCount + 1
        Dimension This.aCache[This.nCacheCount, 3]
        
        This.aCache[This.nCacheCount, 1] = tcKey
        This.aCache[This.nCacheCount, 2] = tcValue
        This.aCache[This.nCacheCount, 3] = Seconds()
    EndProc
    
    Protected Procedure InvalidateCache
        This.nCacheCount = 0
        Dimension This.aCache[1, 3]
    EndProc
    
    *---------------------------------------------------------------------------
    * Logging
    *---------------------------------------------------------------------------
    Procedure SetLogger(toLogger)
        This.oLogger = toLogger
    EndProc
    
    Protected Procedure Log(tcLevel, tcMessage)
        If VarType(This.oLogger) = 'O'
            Do Case
                Case tcLevel = "INFO"
                    This.oLogger.Info(tcMessage)
                Case tcLevel = "WARNING"
                    This.oLogger.Warning(tcMessage)
                Case tcLevel = "ERROR"
                    This.oLogger.LogError(tcMessage)
            EndCase
        EndIf
    EndProc
    
EndDefine
