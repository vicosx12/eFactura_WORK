*=========================================================================
* ServiceMeshCoordinator.prg - Service Mesh Coordinator
*=========================================================================
* Coordonare service mesh cu routing si resilience
*=========================================================================

Define Class ServiceMeshCoordinator As Custom
    Dimension aServices[1]
    nServiceCount = 0
    Dimension aRoutes[1]
    nRouteCount = 0
    lMeshEnabled = .T.
    
    Procedure Init
        This.nServiceCount = 0
        This.nRouteCount = 0
    EndProc
    
    Procedure RegisterService(tcName, tcVersion, tcEndpoint)
        Local loService
        loService = CreateObject("Empty")
        AddProperty(loService, "cName", tcName)
        AddProperty(loService, "cVersion", tcVersion)
        AddProperty(loService, "cEndpoint", tcEndpoint)
        AddProperty(loService, "lHealthy", .T.)
        AddProperty(loService, "nRegisteredTime", Datetime())
        
        This.nServiceCount = This.nServiceCount + 1
        Dimension This.aServices[This.nServiceCount]
        This.aServices[This.nServiceCount] = loService
        
        Return loService
    EndProc
    
    Procedure AddRoute(tcFrom, tcTo, tnWeight)
        Local loRoute
        loRoute = CreateObject("Empty")
        AddProperty(loRoute, "cFrom", tcFrom)
        AddProperty(loRoute, "cTo", tcTo)
        AddProperty(loRoute, "nWeight", Iif(Empty(tnWeight), 100, tnWeight))
        AddProperty(loRoute, "lEnabled", .T.)
        
        This.nRouteCount = This.nRouteCount + 1
        Dimension This.aRoutes[This.nRouteCount]
        This.aRoutes[This.nRouteCount] = loRoute
        
        Return loRoute
    EndProc
    
    Procedure RouteRequest(tcServiceName)
        Local i, loService
        
        For i = 1 To This.nServiceCount
            loService = This.aServices[i]
            If Upper(loService.cName) == Upper(tcServiceName) And loService.lHealthy
                Return loService
            EndIf
        EndFor
        
        Return .Null.
    EndProc
    
    Procedure GetStatistics()
        Local loStats
        loStats = CreateObject("Empty")
        AddProperty(loStats, "lMeshEnabled", This.lMeshEnabled)
        AddProperty(loStats, "nServiceCount", This.nServiceCount)
        AddProperty(loStats, "nRouteCount", This.nRouteCount)
        Return loStats
    EndProc
    
EndDefine
