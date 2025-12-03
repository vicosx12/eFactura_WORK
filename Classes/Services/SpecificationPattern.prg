*====================================================================
* SpecificationPattern.prg - Specification Pattern Implementation
* Part of eFactura OOP Refactoring - v2.4 Enterprise Edition
*====================================================================
* Specification Pattern: Composable business rules for validation
* and querying with And, Or, Not combinators
*====================================================================

*--------------------------------------------------------------------
* ISpecification - Abstract specification interface
*--------------------------------------------------------------------
Define Class ISpecification As Custom
    cName = "ISpecification"
    cDescription = ""
    
    *-- Check if candidate satisfies specification
    Procedure IsSatisfiedBy(toCandidate)
        Error "IsSatisfiedBy must be implemented"
    EndProc
    
    *-- Combine with AND
    Procedure And(toOther)
        Return CreateObject("AndSpecification", This, toOther)
    EndProc
    
    *-- Combine with OR
    Procedure Or(toOther)
        Return CreateObject("OrSpecification", This, toOther)
    EndProc
    
    *-- Negate
    Procedure Not()
        Return CreateObject("NotSpecification", This)
    EndProc
    
    *-- Get reason for failure
    Procedure GetFailureReason(toCandidate)
        Return ""
    EndProc
EndDefine

*--------------------------------------------------------------------
* CompositeSpecification - Base for composite specifications
*--------------------------------------------------------------------
Define Class CompositeSpecification As ISpecification
    oLeft = .Null.
    oRight = .Null.
    
    Procedure Init(toLeft, toRight)
        This.oLeft = toLeft
        This.oRight = toRight
    EndProc
EndDefine

*--------------------------------------------------------------------
* AndSpecification - Combines two specs with AND
*--------------------------------------------------------------------
Define Class AndSpecification As CompositeSpecification
    cName = "AndSpecification"
    
    Procedure IsSatisfiedBy(toCandidate)
        Return This.oLeft.IsSatisfiedBy(toCandidate) And ;
               This.oRight.IsSatisfiedBy(toCandidate)
    EndProc
    
    Procedure GetFailureReason(toCandidate)
        If !This.oLeft.IsSatisfiedBy(toCandidate)
            Return This.oLeft.GetFailureReason(toCandidate)
        EndIf
        If !This.oRight.IsSatisfiedBy(toCandidate)
            Return This.oRight.GetFailureReason(toCandidate)
        EndIf
        Return ""
    EndProc
EndDefine

*--------------------------------------------------------------------
* OrSpecification - Combines two specs with OR
*--------------------------------------------------------------------
Define Class OrSpecification As CompositeSpecification
    cName = "OrSpecification"
    
    Procedure IsSatisfiedBy(toCandidate)
        Return This.oLeft.IsSatisfiedBy(toCandidate) Or ;
               This.oRight.IsSatisfiedBy(toCandidate)
    EndProc
EndDefine

*--------------------------------------------------------------------
* NotSpecification - Negates a specification
*--------------------------------------------------------------------
Define Class NotSpecification As ISpecification
    cName = "NotSpecification"
    oInner = .Null.
    
    Procedure Init(toInner)
        This.oInner = toInner
    EndProc
    
    Procedure IsSatisfiedBy(toCandidate)
        Return !This.oInner.IsSatisfiedBy(toCandidate)
    EndProc
EndDefine

*====================================================================
* Invoice-specific Specifications
*====================================================================

*--------------------------------------------------------------------
* HasValidCIFSpecification
*--------------------------------------------------------------------
Define Class HasValidCIFSpecification As ISpecification
    cName = "HasValidCIF"
    cCIFField = "cCIF"
    
    Procedure Init(tcCIFField)
        If !Empty(tcCIFField)
            This.cCIFField = tcCIFField
        EndIf
    EndProc
    
    Procedure IsSatisfiedBy(toCandidate)
        Local lcCIF
        lcCIF = Evaluate("toCandidate." + This.cCIFField)
        Return This.ValidateCIF(lcCIF)
    EndProc
    
    Protected Procedure ValidateCIF(tcCIF)
        If Empty(tcCIF)
            Return .F.
        EndIf
        tcCIF = Upper(AllTrim(tcCIF))
        If Left(tcCIF, 2) = "RO"
            tcCIF = SubStr(tcCIF, 3)
        EndIf
        Return Len(tcCIF) >= 2 And Len(tcCIF) <= 10
    EndProc
    
    Procedure GetFailureReason(toCandidate)
        Return "CIF invalid"
    EndProc
EndDefine

*--------------------------------------------------------------------
* HasRequiredFieldsSpecification
*--------------------------------------------------------------------
Define Class HasRequiredFieldsSpecification As ISpecification
    cName = "HasRequiredFields"
    Dimension aRequiredFields[1]
    nFieldCount = 0
    cMissingField = ""
    
    Procedure AddRequiredField(tcFieldName)
        This.nFieldCount = This.nFieldCount + 1
        Dimension This.aRequiredFields[This.nFieldCount]
        This.aRequiredFields[This.nFieldCount] = tcFieldName
    EndProc
    
    Procedure IsSatisfiedBy(toCandidate)
        Local lnI, lcField, lValue
        This.cMissingField = ""
        
        For lnI = 1 To This.nFieldCount
            lcField = This.aRequiredFields[lnI]
            Try
                lValue = Evaluate("toCandidate." + lcField)
                If VarType(lValue) = 'C' And Empty(AllTrim(lValue))
                    This.cMissingField = lcField
                    Return .F.
                EndIf
            Catch
                This.cMissingField = lcField
                Return .F.
            EndTry
        EndFor
        Return .T.
    EndProc
    
    Procedure GetFailureReason(toCandidate)
        Return "Câmp obligatoriu lipsă: " + This.cMissingField
    EndProc
EndDefine

*--------------------------------------------------------------------
* AmountInRangeSpecification
*--------------------------------------------------------------------
Define Class AmountInRangeSpecification As ISpecification
    cName = "AmountInRange"
    cAmountField = "nValoare"
    nMinAmount = 0
    nMaxAmount = 999999999
    
    Procedure Init(tcAmountField, tnMin, tnMax)
        If !Empty(tcAmountField)
            This.cAmountField = tcAmountField
        EndIf
        If VarType(tnMin) = 'N'
            This.nMinAmount = tnMin
        EndIf
        If VarType(tnMax) = 'N'
            This.nMaxAmount = tnMax
        EndIf
    EndProc
    
    Procedure IsSatisfiedBy(toCandidate)
        Local lnAmount
        lnAmount = Evaluate("toCandidate." + This.cAmountField)
        Return lnAmount >= This.nMinAmount And lnAmount <= This.nMaxAmount
    EndProc
EndDefine

*--------------------------------------------------------------------
* InvoiceStatusSpecification
*--------------------------------------------------------------------
Define Class InvoiceStatusSpecification As ISpecification
    cName = "InvoiceStatus"
    cStatusField = "cStatus"
    cExpectedStatus = ""
    
    Procedure Init(tcExpectedStatus, tcStatusField)
        This.cExpectedStatus = tcExpectedStatus
        If !Empty(tcStatusField)
            This.cStatusField = tcStatusField
        EndIf
    EndProc
    
    Procedure IsSatisfiedBy(toCandidate)
        Local lcStatus
        lcStatus = Upper(AllTrim(Evaluate("toCandidate." + This.cStatusField)))
        Return lcStatus = Upper(This.cExpectedStatus)
    EndProc
EndDefine

*--------------------------------------------------------------------
* SpecificationValidator
*--------------------------------------------------------------------
Define Class SpecificationValidator As Custom
    oSpecifications = .Null.
    
    Procedure Init
        This.oSpecifications = CreateObject("Collection")
    EndProc
    
    Procedure AddSpecification(toSpec)
        This.oSpecifications.Add(toSpec)
    EndProc
    
    Procedure Validate(toCandidate)
        Local loResult, loSpec, lnI
        loResult = CreateObject("ValidationResult")
        loResult.lValid = .T.
        
        For lnI = 1 To This.oSpecifications.Count
            loSpec = This.oSpecifications.Item(lnI)
            If !loSpec.IsSatisfiedBy(toCandidate)
                loResult.lValid = .F.
                loResult.AddError(loSpec.cName, loSpec.GetFailureReason(toCandidate))
            EndIf
        EndFor
        Return loResult
    EndProc
EndDefine

*--------------------------------------------------------------------
* ValidationResult
*--------------------------------------------------------------------
Define Class ValidationResult As Custom
    lValid = .T.
    oErrors = .Null.
    
    Procedure Init
        This.oErrors = CreateObject("Collection")
    EndProc
    
    Procedure AddError(tcSpecName, tcMessage)
        Local loError
        loError = CreateObject("Empty")
        AddProperty(loError, "SpecName", tcSpecName)
        AddProperty(loError, "Message", tcMessage)
        This.oErrors.Add(loError)
    EndProc
EndDefine

*--------------------------------------------------------------------
* InvoiceSpecificationFactory
*--------------------------------------------------------------------
Define Class InvoiceSpecificationFactory As Custom
    
    Procedure CreateStandardInvoiceSpec
        Local loRequiredFields
        loRequiredFields = CreateObject("HasRequiredFieldsSpecification")
        loRequiredFields.AddRequiredField("cNumar")
        loRequiredFields.AddRequiredField("dData")
        loRequiredFields.AddRequiredField("cCIF_Vanzator")
        loRequiredFields.AddRequiredField("cCIF_Cumparator")
        Return loRequiredFields
    EndProc
EndDefine

*====================================================================
* End of SpecificationPattern.prg
*====================================================================
