*==============================================================================
* KnowledgeGraphEngine.prg
* Graph-based knowledge management for complex relationships
* VFP 9 SP2 Compatible
*==============================================================================

Define Class KnowledgeGraphEngine As Custom
    cName = "KnowledgeGraphEngine"
    cGraphFile = "knowledge_graph.dbf"
    
    * Initialize
    Procedure Init()
        Set Talk Off
        Set Safety Off
        
        If !File(This.cGraphFile)
            This.CreateGraph()
        EndIf
    EndProc
    
    * Create graph storage
    Protected Procedure CreateGraph()
        Create Table (This.cGraphFile) (;
            Id I Autoinc, ;
            Subject C(100), ;
            Predicate C(100), ;
            Object C(100), ;
            Confidence N(5,2), ;
            Created T, ;
            Source C(50))
        
        Index On Subject Tag subject
        Index On Object Tag object
        Index On Predicate Tag predicate
        
        Use In Select("knowledge")
    EndProc
    
    * Add triple (Subject-Predicate-Object)
    Procedure AddTriple(tcSubject, tcPredicate, tcObject, tnConfidence, tcSource)
        Use (This.cGraphFile) In 0 Alias knowledge
        
        * Check if triple already exists
        Locate For Subject = tcSubject And Predicate = tcPredicate And Object = tcObject
        
        If Found()
            * Update existing
            Replace Confidence With tnConfidence, ;
                Source With tcSource, ;
                Created With Datetime()
        Else
            * Insert new
            Insert Into knowledge (Subject, Predicate, Object, Confidence, Created, Source) ;
                Values (tcSubject, tcPredicate, tcObject, tnConfidence, Datetime(), tcSource)
        EndIf
        
        Use In knowledge
        Return .T.
    EndProc
    
    * Query relationships
    Procedure Query(tcSubject, tcPredicate, tcObject)
        Use (This.cGraphFile) In 0 Alias knowledge
        
        Local lcWhere
        lcWhere = ""
        
        If !Empty(tcSubject)
            lcWhere = lcWhere + "Subject = '" + tcSubject + "'"
        EndIf
        
        If !Empty(tcPredicate)
            If !Empty(lcWhere)
                lcWhere = lcWhere + " AND "
            EndIf
            lcWhere = lcWhere + "Predicate = '" + tcPredicate + "'"
        EndIf
        
        If !Empty(tcObject)
            If !Empty(lcWhere)
                lcWhere = lcWhere + " AND "
            EndIf
            lcWhere = lcWhere + "Object = '" + tcObject + "'"
        EndIf
        
        Create Cursor temp_results (Subject C(100), Predicate C(100), Object C(100), Confidence N(5,2))
        
        If !Empty(lcWhere)
            Select * From knowledge Where &lcWhere Into Cursor query_result
        Else
            Select * From knowledge Into Cursor query_result
        EndIf
        
        Local loResults
        loResults = CreateObject("Collection")
        
        Select query_result
        Scan
            Local loTriple
            loTriple = CreateObject("Empty")
            AddProperty(loTriple, "Subject", Alltrim(Subject))
            AddProperty(loTriple, "Predicate", Alltrim(Predicate))
            AddProperty(loTriple, "Object", Alltrim(Object))
            AddProperty(loTriple, "Confidence", Confidence)
            loResults.Add(loTriple)
        EndScan
        
        Use In query_result
        Use In knowledge
        
        Return loResults
    EndProc
    
    * Find path between two entities
    Procedure FindPath(tcFrom, tcTo, tnMaxDepth)
        Use (This.cGraphFile) In 0 Alias knowledge
        
        * Breadth-first search implementation
        Local loQueue, loVisited, loPath
        loQueue = CreateObject("Collection")
        loVisited = CreateObject("Collection")
        
        * Initialize with starting node
        Local loStart
        loStart = CreateObject("Empty")
        AddProperty(loStart, "Node", tcFrom)
        AddProperty(loStart, "Path", tcFrom)
        AddProperty(loStart, "Depth", 0)
        loQueue.Add(loStart)
        
        Do While loQueue.Count > 0
            Local loCurrent
            loCurrent = loQueue.Item(1)
            loQueue.Remove(1)
            
            If loCurrent.Node = tcTo
                * Found path
                Use In knowledge
                Return loCurrent.Path
            EndIf
            
            If loCurrent.Depth >= tnMaxDepth
                Loop
            EndIf
            
            * Add to visited
            loVisited.Add(loCurrent.Node)
            
            * Find neighbors
            Select knowledge
            Scan For Subject = loCurrent.Node
                Local lcNeighbor
                lcNeighbor = Alltrim(Object)
                
                * Check if already visited
                Local llVisited, i
                llVisited = .F.
                For i = 1 To loVisited.Count
                    If loVisited.Item(i) = lcNeighbor
                        llVisited = .T.
                        Exit
                    EndIf
                EndFor
                
                If !llVisited
                    Local loNext
                    loNext = CreateObject("Empty")
                    AddProperty(loNext, "Node", lcNeighbor)
                    AddProperty(loNext, "Path", loCurrent.Path + " -> " + lcNeighbor)
                    AddProperty(loNext, "Depth", loCurrent.Depth + 1)
                    loQueue.Add(loNext)
                EndIf
            EndScan
        EndDo
        
        Use In knowledge
        Return "" && No path found
    EndProc
    
    * Get entity relationships
    Procedure GetEntityRelationships(tcEntity)
        Use (This.cGraphFile) In 0 Alias knowledge
        
        Local loRelations
        loRelations = CreateObject("Collection")
        
        * Find as subject
        Scan For Subject = tcEntity
            Local loRel
            loRel = CreateObject("Empty")
            AddProperty(loRel, "Direction", "OUTGOING")
            AddProperty(loRel, "Predicate", Alltrim(Predicate))
            AddProperty(loRel, "Target", Alltrim(Object))
            AddProperty(loRel, "Confidence", Confidence)
            loRelations.Add(loRel)
        EndScan
        
        * Find as object
        Scan For Object = tcEntity
            loRel = CreateObject("Empty")
            AddProperty(loRel, "Direction", "INCOMING")
            AddProperty(loRel, "Predicate", Alltrim(Predicate))
            AddProperty(loRel, "Target", Alltrim(Subject))
            AddProperty(loRel, "Confidence", Confidence)
            loRelations.Add(loRel)
        EndScan
        
        Use In knowledge
        Return loRelations
    EndProc
    
    * Inference - find indirect relationships
    Procedure Infer(tcSubject, tnMaxHops)
        * Simple transitive inference
        * If A relates to B and B relates to C, then A indirectly relates to C
        Use (This.cGraphFile) In 0 Alias knowledge
        
        Local loInferred
        loInferred = CreateObject("Collection")
        
        * First hop
        Select knowledge
        Scan For Subject = tcSubject
            Local lcIntermediate, lcPredicate1
            lcIntermediate = Alltrim(Object)
            lcPredicate1 = Alltrim(Predicate)
            
            * Second hop
            Local lnCurrentRecord
            lnCurrentRecord = Recno()
            
            Scan For Subject = lcIntermediate
                Local loInfer
                loInfer = CreateObject("Empty")
                AddProperty(loInfer, "Subject", tcSubject)
                AddProperty(loInfer, "InferredRelation", lcPredicate1 + " -> " + Alltrim(Predicate))
                AddProperty(loInfer, "Object", Alltrim(Object))
                AddProperty(loInfer, "Via", lcIntermediate)
                AddProperty(loInfer, "Hops", 2)
                loInferred.Add(loInfer)
            EndScan
            
            Go lnCurrentRecord
        EndScan
        
        Use In knowledge
        Return loInferred
    EndProc
    
    * Export graph to DOT format (for visualization)
    Procedure ExportToDOT(tcFilename)
        Use (This.cGraphFile) In 0 Alias knowledge
        
        Local lcDOT
        lcDOT = "digraph KnowledgeGraph {" + Chr(13) + Chr(10)
        lcDOT = lcDOT + "  rankdir=LR;" + Chr(13) + Chr(10)
        lcDOT = lcDOT + "  node [shape=box];" + Chr(13) + Chr(10)
        
        Scan
            lcDOT = lcDOT + '  "' + Alltrim(Subject) + '" -> "' + Alltrim(Object) + ;
                '" [label="' + Alltrim(Predicate) + '"];' + Chr(13) + Chr(10)
        EndScan
        
        lcDOT = lcDOT + "}" + Chr(13) + Chr(10)
        
        Use In knowledge
        StrToFile(lcDOT, tcFilename)
        
        Return .T.
    EndProc
    
    * Get graph statistics
    Procedure GetStatistics()
        Use (This.cGraphFile) In 0 Alias knowledge
        
        Local loStats
        loStats = CreateObject("Empty")
        
        Count To lnTotalTriples
        AddProperty(loStats, "TotalTriples", lnTotalTriples)
        
        Select Distinct Subject From knowledge Into Cursor unique_subjects
        AddProperty(loStats, "UniqueSubjects", _Tally)
        Use In unique_subjects
        
        Select Distinct Predicate From knowledge Into Cursor unique_predicates
        AddProperty(loStats, "UniquePredicates", _Tally)
        Use In unique_predicates
        
        Select Distinct Object From knowledge Into Cursor unique_objects
        AddProperty(loStats, "UniqueObjects", _Tally)
        Use In unique_objects
        
        Use In knowledge
        Return loStats
    EndProc
EndDefine
