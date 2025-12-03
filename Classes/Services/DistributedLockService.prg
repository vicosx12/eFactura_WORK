*==============================================================================
* DistributedLockService.prg - Distributed Locking for Concurrency Control
*==============================================================================
* Provides distributed locks to prevent concurrent access to resources
*==============================================================================

Define Class DistributedLockService As Custom
    Dimension aLocks[1]
    nLockCount = 0
    oLogger = .Null.
    nDefaultTimeout = 30  && seconds
    
    Procedure Init()
        This.oLogger = CreateObject("LoggerService")
        Dimension This.aLocks[1]
    EndProc
    
    *-- Acquire lock
    Procedure AcquireLock(tcResourceId, tcOwnerId, tnTimeout)
        Local loLock, i, llAcquired
        
        If Empty(tnTimeout)
            tnTimeout = This.nDefaultTimeout
        EndIf
        
        *-- Check if lock exists
        For i = 1 To This.nLockCount
            If This.aLocks[i].cResourceId = tcResourceId
                loLock = This.aLocks[i]
                
                *-- Check if lock expired
                If loLock.IsExpired()
                    loLock.Release()
                    loLock.Acquire(tcOwnerId, tnTimeout)
                    This.oLogger.Info("Acquired expired lock: " + tcResourceId)
                    Return .T.
                EndIf
                
                *-- Lock still held
                If loLock.lLocked
                    This.oLogger.Warning("Lock already held: " + tcResourceId)
                    Return .F.
                EndIf
                
                *-- Acquire existing lock
                loLock.Acquire(tcOwnerId, tnTimeout)
                This.oLogger.Info("Acquired lock: " + tcResourceId)
                Return .T.
            EndIf
        EndFor
        
        *-- Create new lock
        loLock = CreateObject("DistributedLock", tcResourceId)
        loLock.Acquire(tcOwnerId, tnTimeout)
        
        This.nLockCount = This.nLockCount + 1
        Dimension This.aLocks[This.nLockCount]
        This.aLocks[This.nLockCount] = loLock
        
        This.oLogger.Info("Created and acquired lock: " + tcResourceId)
        Return .T.
    EndProc
    
    *-- Release lock
    Procedure ReleaseLock(tcResourceId, tcOwnerId)
        Local i
        
        For i = 1 To This.nLockCount
            If This.aLocks[i].cResourceId = tcResourceId
                If This.aLocks[i].cOwnerId = tcOwnerId
                    This.aLocks[i].Release()
                    This.oLogger.Info("Released lock: " + tcResourceId)
                    Return .T.
                Else
                    This.oLogger.Error("Cannot release lock - wrong owner: " + tcResourceId)
                    Return .F.
                EndIf
            EndIf
        EndFor
        
        Return .F.
    EndProc
    
    *-- Try acquire with timeout
    Procedure TryAcquire(tcResourceId, tcOwnerId, tnTimeout, tnWaitTimeout)
        Local tStart, lnElapsed
        
        tStart = Seconds()
        
        Do While .T.
            If This.AcquireLock(tcResourceId, tcOwnerId, tnTimeout)
                Return .T.
            EndIf
            
            lnElapsed = Seconds() - tStart
            If lnElapsed >= tnWaitTimeout
                This.oLogger.Warning("Lock acquire timeout: " + tcResourceId)
                Return .F.
            EndIf
            
            *-- Wait a bit before retrying
            Inkey(0.1, 'H')
        EndDo
    EndProc
    
    *-- Check if locked
    Procedure IsLocked(tcResourceId)
        Local i
        
        For i = 1 To This.nLockCount
            If This.aLocks[i].cResourceId = tcResourceId
                Return This.aLocks[i].lLocked And Not This.aLocks[i].IsExpired()
            EndIf
        EndFor
        
        Return .F.
    EndProc
    
    *-- Get lock info
    Procedure GetLockInfo(tcResourceId)
        Local i, loInfo
        
        For i = 1 To This.nLockCount
            If This.aLocks[i].cResourceId = tcResourceId
                loInfo = CreateObject("Empty")
                AddProperty(loInfo, "ResourceId", This.aLocks[i].cResourceId)
                AddProperty(loInfo, "Locked", This.aLocks[i].lLocked)
                AddProperty(loInfo, "OwnerId", This.aLocks[i].cOwnerId)
                AddProperty(loInfo, "AcquiredAt", This.aLocks[i].tAcquiredAt)
                AddProperty(loInfo, "ExpiresAt", This.aLocks[i].tExpiresAt)
                Return loInfo
            EndIf
        EndFor
        
        Return .Null.
    EndProc
    
    *-- Clean expired locks
    Procedure CleanExpiredLocks()
        Local i, lnCleaned
        lnCleaned = 0
        
        For i = 1 To This.nLockCount
            If This.aLocks[i].IsExpired()
                This.aLocks[i].Release()
                lnCleaned = lnCleaned + 1
            EndIf
        EndFor
        
        If lnCleaned > 0
            This.oLogger.Info("Cleaned " + Transform(lnCleaned) + " expired locks")
        EndIf
        
        Return lnCleaned
    EndProc
EndDefine

*-- Distributed Lock
Define Class DistributedLock As Custom
    cResourceId = ""
    lLocked = .F.
    cOwnerId = ""
    tAcquiredAt = {}
    tExpiresAt = {}
    nTimeout = 30
    
    Procedure Init(tcResourceId)
        This.cResourceId = tcResourceId
    EndProc
    
    Procedure Acquire(tcOwnerId, tnTimeout)
        This.lLocked = .T.
        This.cOwnerId = tcOwnerId
        This.tAcquiredAt = Datetime()
        This.nTimeout = tnTimeout
        This.tExpiresAt = This.tAcquiredAt + tnTimeout
    EndProc
    
    Procedure Release()
        This.lLocked = .F.
        This.cOwnerId = ""
        This.tAcquiredAt = {}
        This.tExpiresAt = {}
    EndProc
    
    Procedure IsExpired()
        If Empty(This.tExpiresAt)
            Return .F.
        EndIf
        Return Datetime() > This.tExpiresAt
    EndProc
EndDefine
