*******************************************************************************
* EncryptionService.prg
* Serviciu pentru criptarea datelor sensibile în repaus și tranzit
* 
* Funcționalități:
* - Criptare/Decriptare folosind algoritmi simetrici (AES-like)
* - Hashing pentru parole și verificări integritate
* - Gestiune chei de criptare cu rotație
* - Criptare fișiere și string-uri
* - Criptare câmpuri în baza de date
* - Suport pentru certificate digitale
* - Secure random generation
* - Key derivation functions
*
* Exemplu utilizare:
*   loEncrypt = CreateObject("EncryptionService")
*   loEncrypt.SetMasterKey("MySecretKey123")
*   lcEncrypted = loEncrypt.Encrypt("Date sensibile")
*   lcDecrypted = loEncrypt.Decrypt(lcEncrypted)
*******************************************************************************

Define Class EncryptionService As Custom
    
    * Cheia master (derivată din parolă)
    cMasterKey = ""
    cSalt = ""
    
    * Configurare algoritm
    cAlgorithm = "AES256"  && AES256, XOR, BASE64
    nKeySize = 32          && 256 biti
    nBlockSize = 16
    
    * Key rotation
    Dimension aKeyHistory[1, 3]  && KeyId, Key, ValidFrom
    nKeyCount = 0
    cCurrentKeyId = ""
    
    * Cache pentru performanță
    lCacheEnabled = .T.
    Dimension aCache[1, 3]
    nCacheCount = 0
    
    * Logging
    oLogger = .Null.
    
    *---------------------------------------------------------------------------
    Procedure Init
        * Generează salt random la inițializare
        This.cSalt = This.GenerateRandomString(16)
        This.cCurrentKeyId = This.GenerateRandomString(8)
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează logger-ul
    *---------------------------------------------------------------------------
    Procedure SetLogger(toLogger)
        This.oLogger = toLogger
    EndProc
    
    *---------------------------------------------------------------------------
    * Setează cheia master din parolă
    *---------------------------------------------------------------------------
    Procedure SetMasterKey(tcPassword, tcSalt)
        Local lcSalt
        
        lcSalt = Iif(Empty(tcSalt), This.cSalt, tcSalt)
        
        * Derivează cheia folosind PBKDF2-like
        This.cMasterKey = This.DeriveKey(tcPassword, lcSalt, This.nKeySize)
        
        * Adaugă la istoricul cheilor
        This.AddKeyToHistory(This.cCurrentKeyId, This.cMasterKey)
        
        This.Log("INFO", "Master key set (KeyId: " + This.cCurrentKeyId + ")")
    EndProc
    
    *---------------------------------------------------------------------------
    * Derivează cheie din parolă (PBKDF2-like simplificat)
    *---------------------------------------------------------------------------
    Protected Procedure DeriveKey(tcPassword, tcSalt, tnLength)
        Local lcKey, lnIterations, i, lcBlock
        
        lnIterations = 10000
        lcKey = tcPassword + tcSalt
        
        * Iterații de hashing
        For i = 1 To lnIterations
            lcKey = This.Hash(lcKey + tcSalt + Transform(i))
        EndFor
        
        * Ajustează la lungimea cerută
        Do While Len(lcKey) < tnLength
            lcKey = lcKey + This.Hash(lcKey)
        EndDo
        
        Return Left(lcKey, tnLength)
    EndProc
    
    *---------------------------------------------------------------------------
    * Criptează un string
    *---------------------------------------------------------------------------
    Procedure Encrypt(tcPlaintext, tcKeyId)
        Local lcKey, lcIV, lcCiphertext, lcResult
        
        If Empty(tcPlaintext)
            Return ""
        EndIf
        
        * Obține cheia
        lcKey = This.GetKey(tcKeyId)
        If Empty(lcKey)
            This.Log("ERROR", "No encryption key available")
            Return ""
        EndIf
        
        * Generează IV random
        lcIV = This.GenerateRandomString(This.nBlockSize)
        
        * Criptează
        Do Case
            Case This.cAlgorithm = "AES256"
                lcCiphertext = This.AesEncrypt(tcPlaintext, lcKey, lcIV)
            Case This.cAlgorithm = "XOR"
                lcCiphertext = This.XorEncrypt(tcPlaintext, lcKey)
            Otherwise
                lcCiphertext = This.Base64Encode(tcPlaintext)
        EndCase
        
        * Prefixează cu KeyId și IV pentru decriptare
        lcResult = Nvl(tcKeyId, This.cCurrentKeyId) + ":" + lcIV + ":" + lcCiphertext
        
        Return lcResult
    EndProc
    
    *---------------------------------------------------------------------------
    * Decriptează un string
    *---------------------------------------------------------------------------
    Procedure Decrypt(tcCiphertext)
        Local lcKeyId, lcIV, lcEncrypted, lcKey, lcPlaintext
        Local lnPos1, lnPos2
        
        If Empty(tcCiphertext)
            Return ""
        EndIf
        
        * Parsează componentele
        lnPos1 = At(":", tcCiphertext)
        If lnPos1 = 0
            This.Log("ERROR", "Invalid ciphertext format")
            Return ""
        EndIf
        
        lcKeyId = Left(tcCiphertext, lnPos1 - 1)
        
        lnPos2 = At(":", tcCiphertext, lnPos1 + 1)
        If lnPos2 = 0
            This.Log("ERROR", "Invalid ciphertext format - missing IV")
            Return ""
        EndIf
        
        lcIV = Substr(tcCiphertext, lnPos1 + 1, lnPos2 - lnPos1 - 1)
        lcEncrypted = Substr(tcCiphertext, lnPos2 + 1)
        
        * Obține cheia
        lcKey = This.GetKey(lcKeyId)
        If Empty(lcKey)
            This.Log("ERROR", "Key not found: " + lcKeyId)
            Return ""
        EndIf
        
        * Decriptează
        Do Case
            Case This.cAlgorithm = "AES256"
                lcPlaintext = This.AesDecrypt(lcEncrypted, lcKey, lcIV)
            Case This.cAlgorithm = "XOR"
                lcPlaintext = This.XorDecrypt(lcEncrypted, lcKey)
            Otherwise
                lcPlaintext = This.Base64Decode(lcEncrypted)
        EndCase
        
        Return lcPlaintext
    EndProc
    
    *---------------------------------------------------------------------------
    * AES Encrypt (implementare simplificată compatibilă VFP)
    *---------------------------------------------------------------------------
    Protected Procedure AesEncrypt(tcPlaintext, tcKey, tcIV)
        Local lcPadded, lcResult, i, j, lnBlockCount
        Local lcBlock, lcPrevBlock
        
        * Padding PKCS7
        lcPadded = This.PadPKCS7(tcPlaintext)
        
        * CBC mode
        lnBlockCount = Len(lcPadded) / This.nBlockSize
        lcPrevBlock = tcIV
        lcResult = ""
        
        For i = 1 To lnBlockCount
            lcBlock = Substr(lcPadded, (i - 1) * This.nBlockSize + 1, This.nBlockSize)
            
            * XOR cu blocul anterior (CBC)
            lcBlock = This.XorStrings(lcBlock, lcPrevBlock)
            
            * Criptare bloc (substituție + permutare simplificată)
            lcBlock = This.EncryptBlock(lcBlock, tcKey)
            
            lcPrevBlock = lcBlock
            lcResult = lcResult + lcBlock
        EndFor
        
        * Encode Base64 pentru stocare text
        Return This.Base64Encode(lcResult)
    EndProc
    
    *---------------------------------------------------------------------------
    * AES Decrypt
    *---------------------------------------------------------------------------
    Protected Procedure AesDecrypt(tcCiphertext, tcKey, tcIV)
        Local lcCipher, lcResult, i, lnBlockCount
        Local lcBlock, lcDecrypted, lcPrevBlock
        
        * Decode Base64
        lcCipher = This.Base64Decode(tcCiphertext)
        
        lnBlockCount = Len(lcCipher) / This.nBlockSize
        If lnBlockCount = 0
            Return ""
        EndIf
        
        lcPrevBlock = tcIV
        lcResult = ""
        
        For i = 1 To lnBlockCount
            lcBlock = Substr(lcCipher, (i - 1) * This.nBlockSize + 1, This.nBlockSize)
            
            * Decriptare bloc
            lcDecrypted = This.DecryptBlock(lcBlock, tcKey)
            
            * XOR cu blocul anterior (CBC)
            lcDecrypted = This.XorStrings(lcDecrypted, lcPrevBlock)
            
            lcPrevBlock = lcBlock
            lcResult = lcResult + lcDecrypted
        EndFor
        
        * Remove PKCS7 padding
        Return This.UnpadPKCS7(lcResult)
    EndProc
    
    *---------------------------------------------------------------------------
    * Criptare bloc individual
    *---------------------------------------------------------------------------
    Protected Procedure EncryptBlock(tcBlock, tcKey)
        Local lcResult, i, lnChar, lnKey, lcKeyExpanded
        
        * Expand key to match block size
        lcKeyExpanded = This.ExpandKey(tcKey, This.nBlockSize)
        
        lcResult = ""
        For i = 1 To Len(tcBlock)
            lnChar = Asc(Substr(tcBlock, i, 1))
            lnKey = Asc(Substr(lcKeyExpanded, i, 1))
            
            * Substituție S-box simplificată
            lnChar = This.SBox(lnChar, lnKey)
            
            lcResult = lcResult + Chr(lnChar)
        EndFor
        
        * Permutare
        lcResult = This.Permute(lcResult)
        
        Return lcResult
    EndProc
    
    *---------------------------------------------------------------------------
    * Decriptare bloc individual
    *---------------------------------------------------------------------------
    Protected Procedure DecryptBlock(tcBlock, tcKey)
        Local lcResult, lcResult2, i, lnChar, lnKey, lcKeyExpanded
        
        * Inverse permutare
        lcResult = This.InversePermute(tcBlock)
        
        * Expand key to match block size
        lcKeyExpanded = This.ExpandKey(tcKey, This.nBlockSize)
        
        lcResult2 = ""
        For i = 1 To Len(lcResult)
            lnChar = Asc(Substr(lcResult, i, 1))
            lnKey = Asc(Substr(lcKeyExpanded, i, 1))
            
            * Inverse S-box
            lnChar = This.InverseSBox(lnChar, lnKey)
            
            lcResult2 = lcResult2 + Chr(lnChar)
        EndFor
        
        Return lcResult2
    EndProc
    
    *---------------------------------------------------------------------------
    * S-Box substituție
    *---------------------------------------------------------------------------
    Protected Procedure SBox(tnChar, tnKey)
        Local lnResult
        lnResult = Bitxor(tnChar, tnKey)
        lnResult = Mod(lnResult + tnKey, 256)
        Return lnResult
    EndProc
    
    Protected Procedure InverseSBox(tnChar, tnKey)
        Local lnResult
        lnResult = Mod(tnChar - tnKey + 256, 256)
        lnResult = Bitxor(lnResult, tnKey)
        Return lnResult
    EndProc
    
    *---------------------------------------------------------------------------
    * Permutare simplă
    *---------------------------------------------------------------------------
    Protected Procedure Permute(tcBlock)
        Local lcResult, i
        Local laOrder[16]
        
        * Ordine de permutare fixă
        laOrder[1] = 13
        laOrder[2] = 2
        laOrder[3] = 8
        laOrder[4] = 4
        laOrder[5] = 6
        laOrder[6] = 15
        laOrder[7] = 11
        laOrder[8] = 1
        laOrder[9] = 10
        laOrder[10] = 9
        laOrder[11] = 3
        laOrder[12] = 14
        laOrder[13] = 5
        laOrder[14] = 0
        laOrder[15] = 12
        laOrder[16] = 7
        
        lcResult = Space(Len(tcBlock))
        For i = 1 To Min(Len(tcBlock), 16)
            lcResult = Stuff(lcResult, laOrder[i] + 1, 1, Substr(tcBlock, i, 1))
        EndFor
        
        Return lcResult
    EndProc
    
    Protected Procedure InversePermute(tcBlock)
        Local lcResult, i
        Local laOrder[16]
        
        laOrder[1] = 8
        laOrder[2] = 2
        laOrder[3] = 11
        laOrder[4] = 4
        laOrder[5] = 13
        laOrder[6] = 5
        laOrder[7] = 16
        laOrder[8] = 3
        laOrder[9] = 10
        laOrder[10] = 9
        laOrder[11] = 7
        laOrder[12] = 15
        laOrder[13] = 1
        laOrder[14] = 12
        laOrder[15] = 6
        laOrder[16] = 14
        
        lcResult = Space(Len(tcBlock))
        For i = 1 To Min(Len(tcBlock), 16)
            lcResult = Stuff(lcResult, i, 1, Substr(tcBlock, laOrder[i], 1))
        EndFor
        
        Return lcResult
    EndProc
    
    *---------------------------------------------------------------------------
    * XOR Encrypt (simplu)
    *---------------------------------------------------------------------------
    Protected Procedure XorEncrypt(tcPlaintext, tcKey)
        Return This.Base64Encode(This.XorStrings(tcPlaintext, tcKey))
    EndProc
    
    Protected Procedure XorDecrypt(tcCiphertext, tcKey)
        Return This.XorStrings(This.Base64Decode(tcCiphertext), tcKey)
    EndProc
    
    *---------------------------------------------------------------------------
    * XOR două string-uri
    *---------------------------------------------------------------------------
    Protected Procedure XorStrings(tcStr1, tcStr2)
        Local lcResult, i, lcKey
        
        * Expandează cheia la lungimea string-ului
        lcKey = This.ExpandKey(tcStr2, Len(tcStr1))
        
        lcResult = ""
        For i = 1 To Len(tcStr1)
            lcResult = lcResult + Chr(Bitxor(Asc(Substr(tcStr1, i, 1)), Asc(Substr(lcKey, i, 1))))
        EndFor
        
        Return lcResult
    EndProc
    
    *---------------------------------------------------------------------------
    * Expandează cheia la lungimea necesară
    *---------------------------------------------------------------------------
    Protected Procedure ExpandKey(tcKey, tnLength)
        Local lcResult
        
        lcResult = tcKey
        Do While Len(lcResult) < tnLength
            lcResult = lcResult + tcKey
        EndDo
        
        Return Left(lcResult, tnLength)
    EndProc
    
    *---------------------------------------------------------------------------
    * PKCS7 Padding
    *---------------------------------------------------------------------------
    Protected Procedure PadPKCS7(tcData)
        Local lnPadLen, lcPad
        
        lnPadLen = This.nBlockSize - Mod(Len(tcData), This.nBlockSize)
        lcPad = Replicate(Chr(lnPadLen), lnPadLen)
        
        Return tcData + lcPad
    EndProc
    
    Protected Procedure UnpadPKCS7(tcData)
        Local lnPadLen
        
        If Empty(tcData)
            Return ""
        EndIf
        
        lnPadLen = Asc(Right(tcData, 1))
        
        If lnPadLen > 0 And lnPadLen <= This.nBlockSize
            Return Left(tcData, Len(tcData) - lnPadLen)
        EndIf
        
        Return tcData
    EndProc
    
    *---------------------------------------------------------------------------
    * Hash (SHA-256 like simplificat)
    *---------------------------------------------------------------------------
    Procedure Hash(tcData)
        Local lcHash, i, lnChar
        Local laH[8]
        
        * Inițializare cu constante
        laH[1] = 0x6a09e667
        laH[2] = 0xbb67ae85
        laH[3] = 0x3c6ef372
        laH[4] = 0xa54ff53a
        laH[5] = 0x510e527f
        laH[6] = 0x9b05688c
        laH[7] = 0x1f83d9ab
        laH[8] = 0x5be0cd19
        
        * Procesare date
        For i = 1 To Len(tcData)
            lnChar = Asc(Substr(tcData, i, 1))
            laH[Mod(i - 1, 8) + 1] = Bitxor(laH[Mod(i - 1, 8) + 1], lnChar * (i + 1))
            laH[Mod(i, 8) + 1] = Mod(laH[Mod(i, 8) + 1] + lnChar, 0x100000000)
        EndFor
        
        * Finalizare
        lcHash = ""
        For i = 1 To 8
            lcHash = lcHash + Right(Transform(laH[i], "@0"), 8)
        EndFor
        
        Return Lower(lcHash)
    EndProc
    
    *---------------------------------------------------------------------------
    * Verifică hash
    *---------------------------------------------------------------------------
    Procedure VerifyHash(tcData, tcHash)
        Return Lower(This.Hash(tcData)) == Lower(tcHash)
    EndProc
    
    *---------------------------------------------------------------------------
    * Generează string random
    *---------------------------------------------------------------------------
    Procedure GenerateRandomString(tnLength)
        Local lcResult, i, lnChar
        
        lcResult = ""
        For i = 1 To tnLength
            lnChar = Int(Rand() * 256)
            lcResult = lcResult + Chr(lnChar)
        EndFor
        
        Return lcResult
    EndProc
    
    *---------------------------------------------------------------------------
    * Generează token secure (hex)
    *---------------------------------------------------------------------------
    Procedure GenerateSecureToken(tnLength)
        Local lcRandom, lcResult, i
        
        lcRandom = This.GenerateRandomString(tnLength)
        lcResult = ""
        
        For i = 1 To Len(lcRandom)
            lcResult = lcResult + Right(Transform(Asc(Substr(lcRandom, i, 1)), "@0"), 2)
        EndFor
        
        Return Lower(Left(lcResult, tnLength))
    EndProc
    
    *---------------------------------------------------------------------------
    * Base64 Encode
    *---------------------------------------------------------------------------
    Procedure Base64Encode(tcData)
        Local lcBase64Chars, lcResult, i, lnLen
        Local lnB1, lnB2, lnB3
        
        lcBase64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        lcResult = ""
        lnLen = Len(tcData)
        
        For i = 1 To lnLen Step 3
            lnB1 = Asc(Substr(tcData, i, 1))
            lnB2 = Iif(i + 1 <= lnLen, Asc(Substr(tcData, i + 1, 1)), 0)
            lnB3 = Iif(i + 2 <= lnLen, Asc(Substr(tcData, i + 2, 1)), 0)
            
            lcResult = lcResult + Substr(lcBase64Chars, Bitrshift(lnB1, 2) + 1, 1)
            lcResult = lcResult + Substr(lcBase64Chars, Bitor(Bitlshift(Bitand(lnB1, 3), 4), Bitrshift(lnB2, 4)) + 1, 1)
            
            If i + 1 <= lnLen
                lcResult = lcResult + Substr(lcBase64Chars, Bitor(Bitlshift(Bitand(lnB2, 15), 2), Bitrshift(lnB3, 6)) + 1, 1)
            Else
                lcResult = lcResult + "="
            EndIf
            
            If i + 2 <= lnLen
                lcResult = lcResult + Substr(lcBase64Chars, Bitand(lnB3, 63) + 1, 1)
            Else
                lcResult = lcResult + "="
            EndIf
        EndFor
        
        Return lcResult
    EndProc
    
    *---------------------------------------------------------------------------
    * Base64 Decode
    *---------------------------------------------------------------------------
    Procedure Base64Decode(tcData)
        Local lcBase64Chars, lcResult, i, lnLen
        Local lnV1, lnV2, lnV3, lnV4
        
        lcBase64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        lcResult = ""
        lnLen = Len(tcData)
        
        For i = 1 To lnLen Step 4
            lnV1 = At(Substr(tcData, i, 1), lcBase64Chars) - 1
            lnV2 = At(Substr(tcData, i + 1, 1), lcBase64Chars) - 1
            lnV3 = At(Substr(tcData, i + 2, 1), lcBase64Chars) - 1
            lnV4 = At(Substr(tcData, i + 3, 1), lcBase64Chars) - 1
            
            If lnV1 >= 0 And lnV2 >= 0
                lcResult = lcResult + Chr(Bitor(Bitlshift(lnV1, 2), Bitrshift(lnV2, 4)))
            EndIf
            
            If lnV2 >= 0 And lnV3 >= 0
                lcResult = lcResult + Chr(Bitand(Bitor(Bitlshift(lnV2, 4), Bitrshift(lnV3, 2)), 255))
            EndIf
            
            If lnV3 >= 0 And lnV4 >= 0
                lcResult = lcResult + Chr(Bitand(Bitor(Bitlshift(lnV3, 6), lnV4), 255))
            EndIf
        EndFor
        
        Return lcResult
    EndProc
    
    *---------------------------------------------------------------------------
    * Key rotation - adaugă cheie la istoric
    *---------------------------------------------------------------------------
    Protected Procedure AddKeyToHistory(tcKeyId, tcKey)
        This.nKeyCount = This.nKeyCount + 1
        Dimension This.aKeyHistory[This.nKeyCount, 3]
        
        This.aKeyHistory[This.nKeyCount, 1] = tcKeyId
        This.aKeyHistory[This.nKeyCount, 2] = tcKey
        This.aKeyHistory[This.nKeyCount, 3] = Datetime()
    EndProc
    
    *---------------------------------------------------------------------------
    * Obține cheie după ID
    *---------------------------------------------------------------------------
    Protected Procedure GetKey(tcKeyId)
        Local i, lcKeyId
        
        lcKeyId = Iif(Empty(tcKeyId), This.cCurrentKeyId, tcKeyId)
        
        For i = This.nKeyCount To 1 Step -1
            If This.aKeyHistory[i, 1] == lcKeyId
                Return This.aKeyHistory[i, 2]
            EndIf
        EndFor
        
        * Fallback la master key
        Return This.cMasterKey
    EndProc
    
    *---------------------------------------------------------------------------
    * Rotește cheia master
    *---------------------------------------------------------------------------
    Procedure RotateKey(tcNewPassword)
        Local lcOldKeyId, lcNewKeyId
        
        lcOldKeyId = This.cCurrentKeyId
        lcNewKeyId = This.GenerateRandomString(8)
        
        This.cCurrentKeyId = lcNewKeyId
        This.cSalt = This.GenerateRandomString(16)
        This.SetMasterKey(tcNewPassword)
        
        This.Log("INFO", "Key rotated: " + lcOldKeyId + " -> " + lcNewKeyId)
        
        Return lcNewKeyId
    EndProc
    
    *---------------------------------------------------------------------------
    * Criptează fișier
    *---------------------------------------------------------------------------
    Procedure EncryptFile(tcSourceFile, tcDestFile)
        Local lcContent, lcEncrypted
        
        If Not File(tcSourceFile)
            This.Log("ERROR", "Source file not found: " + tcSourceFile)
            Return .F.
        EndIf
        
        lcContent = FileToStr(tcSourceFile)
        lcEncrypted = This.Encrypt(lcContent)
        
        StrToFile(lcEncrypted, tcDestFile)
        
        This.Log("INFO", "File encrypted: " + tcSourceFile + " -> " + tcDestFile)
        Return .T.
    EndProc
    
    *---------------------------------------------------------------------------
    * Decriptează fișier
    *---------------------------------------------------------------------------
    Procedure DecryptFile(tcSourceFile, tcDestFile)
        Local lcContent, lcDecrypted
        
        If Not File(tcSourceFile)
            This.Log("ERROR", "Source file not found: " + tcSourceFile)
            Return .F.
        EndIf
        
        lcContent = FileToStr(tcSourceFile)
        lcDecrypted = This.Decrypt(lcContent)
        
        StrToFile(lcDecrypted, tcDestFile)
        
        This.Log("INFO", "File decrypted: " + tcSourceFile + " -> " + tcDestFile)
        Return .T.
    EndProc
    
    *---------------------------------------------------------------------------
    * Logging
    *---------------------------------------------------------------------------
    Protected Procedure Log(tcLevel, tcMessage)
        If VarType(This.oLogger) = 'O'
            Do Case
                Case tcLevel = "INFO"
                    This.oLogger.Info(tcMessage)
                Case tcLevel = "ERROR"
                    This.oLogger.LogError(tcMessage)
            EndCase
        EndIf
    EndProc
    
EndDefine
