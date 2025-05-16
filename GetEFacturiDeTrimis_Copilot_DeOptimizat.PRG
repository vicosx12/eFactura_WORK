Function GetEFacturiDeTrimis(tdData)
	ldData=tdData
	*
	If Type('ll_Is_ICAS')='U'
		Public ll_Is_ICAS
		ll_Is_ICAS = ( VarType(ICAS)='O' And Not IsNull(ICAS) ) And PemStatus(ICAS, 'oCfgSALARII', 5)
	EndIf
	*	
	If ll_Is_ICAS
		*
		Text To lcSQL NoShow TextMerge
			Select
				IdDoc
			From Iesiri i
			-- Inner Join (Select * From Conturi Where Left(Cont,3) In('411', '461') And Len(Cont)>3 And IsNull(Sters, 0)=0) c On i.Cont=c.Cont
			Where
				i.Tip Not In ('B','C','A', 'e')
				And i.DataDoc<=?ldData
				-- And IsNull(BFTiparit, 0)<>9
				And IsNull(i.Is_EF, 0)=1
				And IsNull(Id_Solicitare, Space(1))=Space(1)
				And IsNull(Anulat, 0)=0
			Union
			Select
				IdDoc
			From Export e
			-- Inner Join (Select * From Conturi Where Left(Cont,3) In('411', '461') And Len(Cont)>3 And IsNull(Sters, 0)=0) c On e.Cont=c.Cont
			Where
				e.Tip Not In ('B','C','A', 'e', 'W','X','Y')
				And e.DataDoc<=?ldData
				-- And IsNull(BFTiparit, 0)<>9
				And IsNull(e.Is_EF, 0)=1
				And IsNull(Id_Solicitare, Space(1))=Space(1)
				And IsNull(Anulat, 0)=0
		EndText
		*
	Else
		*
		Text To lcSQL NoShow TextMerge
			Select
				ID As IdDoc
			From Docum
			Where
				Is_EF=1
				And Tip_Doc='FcAviz'
				And Tip_Fact In(1, 2, 4, 7)
				And Data_Doc<=?ldData
				-- And Coalesce(BFTiparit, 0)<>9
				And Coalesce(Id_Solicitare, '')=''
		EndText		
		*
	EndIf
	*
	mySQLExec(lcSQL, [NrFacturiNetrimise])
	Return aCountInfo(2)
EndFunc