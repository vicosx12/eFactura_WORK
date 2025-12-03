*******************************************************************************
* QueryBuilder.prg
* Builder pentru interogări flexibile (GraphQL-like)
* 
* Funcționalități:
* - Construire interogări fluent
* - Filtrare, sortare, paginare
* - Selecție câmpuri specifice
* - Relații și join-uri
* - Agregări (COUNT, SUM, AVG)
* - Export în diverse formate
* - Cache rezultate
*
* Exemplu utilizare:
*   loQuery = CreateObject("QueryBuilder")
*   loQuery.From("Iesiri") ;
*          .Select("IdIesire, NumarDoc, DataDoc, ValoareTotala") ;
*          .Where("DataDoc", ">=", Date() - 30) ;
*          .Where("Stare", "=", "A") ;
*          .OrderBy("DataDoc", "DESC") ;
*          .Limit(100)
*   lcSql = loQuery.ToSql()
*   loCursor = loQuery.Execute()
*******************************************************************************

Define Class QueryBuilder As Custom
    
    * Componente query
    cTable = ""
    cAlias = ""
    
    * Select
    Dimension aSelectFields[1]
    nSelectCount = 0
    lSelectAll = .T.
    
    * Where conditions
    Dimension aWhereConditions[1, 4]  && Field, Operator, Value, Connector
    nWhereCount = 0
    
    * Order by
    Dimension aOrderBy[1, 2]  && Field, Direction
    nOrderCount = 0
    
    * Group by
    Dimension aGroupBy[1]
    nGroupCount = 0
    
    * Joins
    Dimension aJoins[1, 4]  && Type, Table, OnField1, OnField2
    nJoinCount = 0
    
    * Limit/Offset
    nLimit = 0
    nOffset = 0
    
    * Aggregates
    Dimension aAggregates[1, 3]  && Function, Field, Alias
    nAggregateCount = 0
    
    * Cache
    lCacheEnabled = .F.
    nCacheTTL = 300
    cLastQuery = ""
    
    * Logging
    oLogger = .Null.
    
    *---------------------------------------------------------------------------
    Procedure Init
        This.Reset()
    EndProc
    
    *---------------------------------------------------------------------------
    * Resetează query-ul
    *---------------------------------------------------------------------------
    Procedure Reset
        This.cTable = ""
        This.cAlias = ""
        This.nSelectCount = 0
        This.lSelectAll = .T.
        This.nWhereCount = 0
        This.nOrderCount = 0
        This.nGroupCount = 0
        This.nJoinCount = 0
        This.nAggregateCount = 0
        This.nLimit = 0
        This.nOffset = 0
        This.cLastQuery = ""
        
        Dimension This.aSelectFields[1]
        Dimension This.aWhereConditions[1, 4]
        Dimension This.aOrderBy[1, 2]
        Dimension This.aGroupBy[1]
        Dimension This.aJoins[1, 4]
        Dimension This.aAggregates[1, 3]
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează tabela sursă
    *---------------------------------------------------------------------------
    Procedure From(tcTable, tcAlias)
        This.cTable = tcTable
        This.cAlias = Nvl(tcAlias, "")
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Selectează câmpuri specifice
    *---------------------------------------------------------------------------
    Procedure Select(tcFields)
        Local laFields[1], lnCount, i
        
        This.lSelectAll = .F.
        
        * Parse câmpuri separate prin virgulă
        lnCount = Alines(laFields, tcFields, 1, ",")
        
        For i = 1 To lnCount
            This.nSelectCount = This.nSelectCount + 1
            Dimension This.aSelectFields[This.nSelectCount]
            This.aSelectFields[This.nSelectCount] = Alltrim(laFields[i])
        EndFor
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Adaugă condiție WHERE
    *---------------------------------------------------------------------------
    Procedure Where(tcField, tcOperator, tvValue, tcConnector)
        This.nWhereCount = This.nWhereCount + 1
        Dimension This.aWhereConditions[This.nWhereCount, 4]
        
        This.aWhereConditions[This.nWhereCount, 1] = tcField
        This.aWhereConditions[This.nWhereCount, 2] = tcOperator
        This.aWhereConditions[This.nWhereCount, 3] = tvValue
        This.aWhereConditions[This.nWhereCount, 4] = Iif(Empty(tcConnector), "AND", Upper(tcConnector))
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * AND condition (shortcut)
    *---------------------------------------------------------------------------
    Procedure AndWhere(tcField, tcOperator, tvValue)
        Return This.Where(tcField, tcOperator, tvValue, "AND")
    EndProc
    
    *---------------------------------------------------------------------------
    * OR condition
    *---------------------------------------------------------------------------
    Procedure OrWhere(tcField, tcOperator, tvValue)
        Return This.Where(tcField, tcOperator, tvValue, "OR")
    EndProc
    
    *---------------------------------------------------------------------------
    * WHERE IN (...)
    *---------------------------------------------------------------------------
    Procedure WhereIn(tcField, taValues)
        Local lcValues, i
        
        lcValues = ""
        For i = 1 To Alen(taValues)
            If i > 1
                lcValues = lcValues + ", "
            EndIf
            lcValues = lcValues + This.EscapeValue(taValues[i])
        EndFor
        
        Return This.Where(tcField, "IN", "(" + lcValues + ")", "AND")
    EndProc
    
    *---------------------------------------------------------------------------
    * WHERE BETWEEN
    *---------------------------------------------------------------------------
    Procedure WhereBetween(tcField, tvMin, tvMax)
        This.Where(tcField, ">=", tvMin, "AND")
        Return This.Where(tcField, "<=", tvMax, "AND")
    EndProc
    
    *---------------------------------------------------------------------------
    * WHERE LIKE
    *---------------------------------------------------------------------------
    Procedure WhereLike(tcField, tcPattern)
        Return This.Where(tcField, "LIKE", tcPattern, "AND")
    EndProc
    
    *---------------------------------------------------------------------------
    * WHERE IS NULL
    *---------------------------------------------------------------------------
    Procedure WhereNull(tcField)
        Return This.Where(tcField, "IS", .Null., "AND")
    EndProc
    
    *---------------------------------------------------------------------------
    * WHERE IS NOT NULL
    *---------------------------------------------------------------------------
    Procedure WhereNotNull(tcField)
        Return This.Where(tcField, "IS NOT", .Null., "AND")
    EndProc
    
    *---------------------------------------------------------------------------
    * ORDER BY
    *---------------------------------------------------------------------------
    Procedure OrderBy(tcField, tcDirection)
        This.nOrderCount = This.nOrderCount + 1
        Dimension This.aOrderBy[This.nOrderCount, 2]
        
        This.aOrderBy[This.nOrderCount, 1] = tcField
        This.aOrderBy[This.nOrderCount, 2] = Iif(Upper(Nvl(tcDirection, "ASC")) = "DESC", "DESC", "ASC")
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * GROUP BY
    *---------------------------------------------------------------------------
    Procedure GroupBy(tcFields)
        Local laFields[1], lnCount, i
        
        lnCount = Alines(laFields, tcFields, 1, ",")
        
        For i = 1 To lnCount
            This.nGroupCount = This.nGroupCount + 1
            Dimension This.aGroupBy[This.nGroupCount]
            This.aGroupBy[This.nGroupCount] = Alltrim(laFields[i])
        EndFor
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * LIMIT
    *---------------------------------------------------------------------------
    Procedure Limit(tnLimit, tnOffset)
        This.nLimit = tnLimit
        This.nOffset = Nvl(tnOffset, 0)
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Offset (alias pentru Limit)
    *---------------------------------------------------------------------------
    Procedure Offset(tnOffset)
        This.nOffset = tnOffset
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * JOIN
    *---------------------------------------------------------------------------
    Procedure Join(tcTable, tcField1, tcField2, tcType)
        This.nJoinCount = This.nJoinCount + 1
        Dimension This.aJoins[This.nJoinCount, 4]
        
        This.aJoins[This.nJoinCount, 1] = Upper(Nvl(tcType, "INNER"))
        This.aJoins[This.nJoinCount, 2] = tcTable
        This.aJoins[This.nJoinCount, 3] = tcField1
        This.aJoins[This.nJoinCount, 4] = tcField2
        
        Return This
    EndProc
    
    Procedure LeftJoin(tcTable, tcField1, tcField2)
        Return This.Join(tcTable, tcField1, tcField2, "LEFT")
    EndProc
    
    Procedure RightJoin(tcTable, tcField1, tcField2)
        Return This.Join(tcTable, tcField1, tcField2, "RIGHT")
    EndProc
    
    Procedure InnerJoin(tcTable, tcField1, tcField2)
        Return This.Join(tcTable, tcField1, tcField2, "INNER")
    EndProc
    
    *---------------------------------------------------------------------------
    * Agregări
    *---------------------------------------------------------------------------
    Procedure Count(tcField, tcAlias)
        Return This.Aggregate("COUNT", Nvl(tcField, "*"), Nvl(tcAlias, "cnt"))
    EndProc
    
    Procedure Sum(tcField, tcAlias)
        Return This.Aggregate("SUM", tcField, Nvl(tcAlias, "total"))
    EndProc
    
    Procedure Avg(tcField, tcAlias)
        Return This.Aggregate("AVG", tcField, Nvl(tcAlias, "average"))
    EndProc
    
    Procedure Max(tcField, tcAlias)
        Return This.Aggregate("MAX", tcField, Nvl(tcAlias, "max_val"))
    EndProc
    
    Procedure Min(tcField, tcAlias)
        Return This.Aggregate("MIN", tcField, Nvl(tcAlias, "min_val"))
    EndProc
    
    Protected Procedure Aggregate(tcFunction, tcField, tcAlias)
        This.nAggregateCount = This.nAggregateCount + 1
        Dimension This.aAggregates[This.nAggregateCount, 3]
        
        This.aAggregates[This.nAggregateCount, 1] = tcFunction
        This.aAggregates[This.nAggregateCount, 2] = tcField
        This.aAggregates[This.nAggregateCount, 3] = tcAlias
        
        Return This
    EndProc
    
    *---------------------------------------------------------------------------
    * Generează SQL
    *---------------------------------------------------------------------------
    Procedure ToSql
        Local lcSql, i
        
        lcSql = "SELECT "
        
        * Fields
        If This.nAggregateCount > 0
            * Agregări
            For i = 1 To This.nAggregateCount
                If i > 1
                    lcSql = lcSql + ", "
                EndIf
                lcSql = lcSql + This.aAggregates[i, 1] + "(" + This.aAggregates[i, 2] + ")"
                lcSql = lcSql + " AS " + This.aAggregates[i, 3]
            EndFor
            
            * Adaugă și group by fields
            For i = 1 To This.nGroupCount
                lcSql = lcSql + ", " + This.aGroupBy[i]
            EndFor
        ElseIf This.lSelectAll
            lcSql = lcSql + "*"
        Else
            For i = 1 To This.nSelectCount
                If i > 1
                    lcSql = lcSql + ", "
                EndIf
                lcSql = lcSql + This.aSelectFields[i]
            EndFor
        EndIf
        
        * FROM
        lcSql = lcSql + " FROM " + This.cTable
        If Not Empty(This.cAlias)
            lcSql = lcSql + " " + This.cAlias
        EndIf
        
        * JOINs
        For i = 1 To This.nJoinCount
            lcSql = lcSql + " " + This.aJoins[i, 1] + " JOIN " + This.aJoins[i, 2]
            lcSql = lcSql + " ON " + This.aJoins[i, 3] + " = " + This.aJoins[i, 4]
        EndFor
        
        * WHERE
        If This.nWhereCount > 0
            lcSql = lcSql + " WHERE "
            For i = 1 To This.nWhereCount
                If i > 1
                    lcSql = lcSql + " " + This.aWhereConditions[i, 4] + " "
                EndIf
                
                lcSql = lcSql + This.aWhereConditions[i, 1] + " "
                lcSql = lcSql + This.aWhereConditions[i, 2] + " "
                
                If IsNull(This.aWhereConditions[i, 3])
                    lcSql = lcSql + "NULL"
                ElseIf This.aWhereConditions[i, 2] = "IN"
                    lcSql = lcSql + This.aWhereConditions[i, 3]
                Else
                    lcSql = lcSql + This.EscapeValue(This.aWhereConditions[i, 3])
                EndIf
            EndFor
        EndIf
        
        * GROUP BY
        If This.nGroupCount > 0
            lcSql = lcSql + " GROUP BY "
            For i = 1 To This.nGroupCount
                If i > 1
                    lcSql = lcSql + ", "
                EndIf
                lcSql = lcSql + This.aGroupBy[i]
            EndFor
        EndIf
        
        * ORDER BY
        If This.nOrderCount > 0
            lcSql = lcSql + " ORDER BY "
            For i = 1 To This.nOrderCount
                If i > 1
                    lcSql = lcSql + ", "
                EndIf
                lcSql = lcSql + This.aOrderBy[i, 1] + " " + This.aOrderBy[i, 2]
            EndFor
        EndIf
        
        This.cLastQuery = lcSql
        Return lcSql
    EndProc
    
    *---------------------------------------------------------------------------
    * Escape valoare pentru SQL
    *---------------------------------------------------------------------------
    Protected Procedure EscapeValue(tvValue)
        Do Case
            Case VarType(tvValue) = 'C'
                Return "'" + Strtran(tvValue, "'", "''") + "'"
            Case VarType(tvValue) = 'N'
                Return Transform(tvValue)
            Case VarType(tvValue) = 'D'
                Return "{^" + Dtos(tvValue) + "}"
            Case VarType(tvValue) = 'T'
                Return "{^" + Ttoc(tvValue, 1) + "}"
            Case VarType(tvValue) = 'L'
                Return Iif(tvValue, ".T.", ".F.")
            Otherwise
                Return "'" + Transform(tvValue) + "'"
        EndCase
    EndProc
    
    *---------------------------------------------------------------------------
    * Execută query-ul
    *---------------------------------------------------------------------------
    Procedure Execute(tcCursorName)
        Local lcSql, lcCursor
        
        lcSql = This.ToSql()
        lcCursor = Iif(Empty(tcCursorName), "qryResult", tcCursorName)
        
        Try
            &lcSql Into Cursor (lcCursor) ReadWrite
            This.Log("DEBUG", "Query executed: " + lcSql)
            Return .T.
        Catch To loEx
            This.Log("ERROR", "Query failed: " + loEx.Message + " | SQL: " + lcSql)
            Return .F.
        EndTry
    EndProc
    
    *---------------------------------------------------------------------------
    * Returnează primul rezultat
    *---------------------------------------------------------------------------
    Procedure First(tcCursorName)
        This.Limit(1)
        If This.Execute(tcCursorName)
            Return .T.
        EndIf
        Return .F.
    EndProc
    
    *---------------------------------------------------------------------------
    * Returnează numărul de rezultate
    *---------------------------------------------------------------------------
    Procedure GetCount
        Local lnCount, lcSql
        
        * Salvează starea
        Local laOldSelect[1], lnOldCount, llOldAll
        lnOldCount = This.nSelectCount
        llOldAll = This.lSelectAll
        
        * Setează COUNT
        This.nSelectCount = 0
        This.lSelectAll = .F.
        This.Count("*", "total_count")
        
        lcSql = This.ToSql()
        
        Try
            &lcSql Into Cursor _tempCount
            lnCount = _tempCount.total_count
            Use In Select("_tempCount")
        Catch
            lnCount = 0
        EndTry
        
        * Restore
        This.nSelectCount = lnOldCount
        This.lSelectAll = llOldAll
        This.nAggregateCount = 0
        
        Return lnCount
    EndProc
    
    *---------------------------------------------------------------------------
    * Verifică dacă există rezultate
    *---------------------------------------------------------------------------
    Procedure Exists
        Return This.GetCount() > 0
    EndProc
    
    *---------------------------------------------------------------------------
    * Paginare
    *---------------------------------------------------------------------------
    Procedure Paginate(tnPage, tnPerPage, tcCursorName)
        Local lnOffset
        
        lnOffset = (tnPage - 1) * tnPerPage
        This.Limit(tnPerPage, lnOffset)
        
        Return This.Execute(tcCursorName)
    EndProc
    
    *---------------------------------------------------------------------------
    * Clonează query-ul
    *---------------------------------------------------------------------------
    Procedure Clone
        Local loClone, i
        
        loClone = CreateObject("QueryBuilder")
        loClone.cTable = This.cTable
        loClone.cAlias = This.cAlias
        loClone.lSelectAll = This.lSelectAll
        loClone.nLimit = This.nLimit
        loClone.nOffset = This.nOffset
        
        * Copiază arrays
        For i = 1 To This.nSelectCount
            loClone.nSelectCount = loClone.nSelectCount + 1
            Dimension loClone.aSelectFields[loClone.nSelectCount]
            loClone.aSelectFields[i] = This.aSelectFields[i]
        EndFor
        
        * Similar pentru celelalte...
        
        Return loClone
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
