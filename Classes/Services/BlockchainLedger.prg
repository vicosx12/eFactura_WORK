*==============================================================================
* BlockchainLedger.prg
* Immutable blockchain-like ledger with hash-chain verification
* VFP 9 SP2 Compatible
*==============================================================================

Define Class BlockchainLedger As Custom
    cName = "BlockchainLedger"
    cChainFile = "blockchain.dbf"
    nDifficulty = 4
    
    * Initialize blockchain
    Procedure Init(tcChainFile)
        Set Talk Off
        Set Safety Off
        
        If !Empty(tcChainFile)
            This.cChainFile = tcChainFile
        EndIf
        
        If !File(This.cChainFile)
            This.CreateChain()
            This.AddGenesisBlock()
        EndIf
    EndProc
    
    * Create blockchain table
    Protected Procedure CreateChain()
        Create Table (This.cChainFile) (;
            BlockId I, ;
            Timestamp T, ;
            Data M, ;
            PrevHash C(64), ;
            Hash C(64), ;
            Nonce I, ;
            Validated L)
        
        Use In Select("blockchain")
    EndProc
    
    * Add genesis block
    Protected Procedure AddGenesisBlock()
        Local lcPrevHash, lcHash
        lcPrevHash = Replicate("0", 64)
        lcHash = This.CalculateHash(0, Datetime(), "Genesis Block", lcPrevHash, 0)
        
        Use (This.cChainFile) In 0 Alias blockchain
        Insert Into blockchain (BlockId, Timestamp, Data, PrevHash, Hash, Nonce, Validated) ;
            Values (0, Datetime(), "Genesis Block", lcPrevHash, lcHash, 0, .T.)
        Use In blockchain
    EndProc
    
    * Add new block to chain
    Procedure AddBlock(tcData)
        Use (This.cChainFile) In 0 Alias blockchain
        Go Bottom
        Local lnLastId, lcLastHash
        lnLastId = blockchain.BlockId
        lcLastHash = blockchain.Hash
        
        * Create new block
        Local lnNewId, lcTimestamp, lcHash, lnNonce
        lnNewId = lnLastId + 1
        lcTimestamp = Datetime()
        
        * Mine block (Proof of Work)
        lnNonce = This.MineBlock(lnNewId, lcTimestamp, tcData, lcLastHash)
        lcHash = This.CalculateHash(lnNewId, lcTimestamp, tcData, lcLastHash, lnNonce)
        
        * Insert block
        Insert Into blockchain (BlockId, Timestamp, Data, PrevHash, Hash, Nonce, Validated) ;
            Values (lnNewId, lcTimestamp, tcData, lcLastHash, lcHash, lnNonce, .T.)
        
        Use In blockchain
        
        Return lnNewId
    EndProc
    
    * Mine block (Proof of Work)
    Protected Procedure MineBlock(tnBlockId, ttTimestamp, tcData, tcPrevHash)
        Local lnNonce, lcHash, lcTarget
        lnNonce = 0
        lcTarget = Replicate("0", This.nDifficulty)
        
        Do While .T.
            lcHash = This.CalculateHash(tnBlockId, ttTimestamp, tcData, tcPrevHash, lnNonce)
            If Left(lcHash, This.nDifficulty) = lcTarget
                Exit
            EndIf
            lnNonce = lnNonce + 1
            
            * Timeout after 10000 attempts (for demo purposes)
            If lnNonce > 10000
                Exit
            EndIf
        EndDo
        
        Return lnNonce
    EndProc
    
    * Calculate block hash (SHA-256 simulation)
    Protected Procedure CalculateHash(tnBlockId, ttTimestamp, tcData, tcPrevHash, tnNonce)
        Local lcInput, lcHash, i, lnSum
        lcInput = Transform(tnBlockId) + Ttoc(ttTimestamp, 1) + tcData + tcPrevHash + Transform(tnNonce)
        
        * Simple hash simulation (in production would use actual SHA-256)
        lcHash = ""
        lnSum = 0
        For i = 1 To Len(lcInput)
            lnSum = lnSum + Asc(Substr(lcInput, i, 1)) * i
        EndFor
        
        * Generate 64-char hex hash
        For i = 1 To 16
            lnSum = lnSum * 16807 + i
            lcHash = lcHash + Right("0" + Transform(Mod(lnSum, 256), "@0"), 2)
        EndFor
        
        Return Substr(lcHash + Replicate("0", 64), 1, 64)
    EndProc
    
    * Verify blockchain integrity
    Procedure VerifyChain()
        Use (This.cChainFile) In 0 Alias blockchain
        Local llValid, lcPrevHash, lcCalculatedHash
        llValid = .T.
        
        Go Top
        Skip && Skip genesis
        
        Do While !Eof()
            * Verify previous hash linkage
            lcPrevHash = blockchain.PrevHash
            Go Bott - Recno() + 1
            
            If blockchain.Hash <> lcPrevHash
                llValid = .F.
                Exit
            EndIf
            
            Go Bott - Recno() + 2
            
            * Verify block hash
            lcCalculatedHash = This.CalculateHash(blockchain.BlockId, blockchain.Timestamp, ;
                blockchain.Data, blockchain.PrevHash, blockchain.Nonce)
            
            If blockchain.Hash <> lcCalculatedHash
                llValid = .F.
                Exit
            EndIf
            
            Skip
        EndDo
        
        Use In blockchain
        Return llValid
    EndProc
    
    * Get block by ID
    Procedure GetBlock(tnBlockId)
        Use (This.cChainFile) In 0 Alias blockchain
        Locate For BlockId = tnBlockId
        
        Local loBlock
        If Found()
            loBlock = CreateObject("Empty")
            AddProperty(loBlock, "BlockId", blockchain.BlockId)
            AddProperty(loBlock, "Timestamp", blockchain.Timestamp)
            AddProperty(loBlock, "Data", blockchain.Data)
            AddProperty(loBlock, "PrevHash", blockchain.PrevHash)
            AddProperty(loBlock, "Hash", blockchain.Hash)
            AddProperty(loBlock, "Nonce", blockchain.Nonce)
            AddProperty(loBlock, "Validated", blockchain.Validated)
        Else
            loBlock = .Null.
        EndIf
        
        Use In blockchain
        Return loBlock
    EndProc
    
    * Get chain length
    Procedure GetChainLength()
        Use (This.cChainFile) In 0 Alias blockchain
        Local lnCount
        Count To lnCount
        Use In blockchain
        Return lnCount
    EndProc
    
    * Export chain to JSON
    Procedure ExportToJSON(tcFilename)
        Use (This.cChainFile) In 0 Alias blockchain
        Local lcJSON, llFirst
        lcJSON = "[" + Chr(13) + Chr(10)
        llFirst = .T.
        
        Scan
            If !llFirst
                lcJSON = lcJSON + "," + Chr(13) + Chr(10)
            EndIf
            
            lcJSON = lcJSON + "  {" + Chr(13) + Chr(10)
            lcJSON = lcJSON + '    "blockId": ' + Transform(BlockId) + "," + Chr(13) + Chr(10)
            lcJSON = lcJSON + '    "timestamp": "' + Ttoc(Timestamp, 1) + '",' + Chr(13) + Chr(10)
            lcJSON = lcJSON + '    "data": "' + Alltrim(Data) + '",' + Chr(13) + Chr(10)
            lcJSON = lcJSON + '    "prevHash": "' + Alltrim(PrevHash) + '",' + Chr(13) + Chr(10)
            lcJSON = lcJSON + '    "hash": "' + Alltrim(Hash) + '",' + Chr(13) + Chr(10)
            lcJSON = lcJSON + '    "nonce": ' + Transform(Nonce) + Chr(13) + Chr(10)
            lcJSON = lcJSON + "  }"
            
            llFirst = .F.
        EndScan
        
        lcJSON = lcJSON + Chr(13) + Chr(10) + "]"
        Use In blockchain
        
        StrToFile(lcJSON, tcFilename)
        Return .T.
    EndProc
EndDefine
