import options, strutils
import asyncdispatch

import server/[types, route, middleware], server/router as routing

proc routeRequest*(router: Router, req: Request, res: Response): Option[string] {.gcsafe.}

proc matchComponent(router: Router, req: Request, res: Response): Option[string] =
    result = none[string]()
    if not req.path.startsWith(router.componentPath): return
    for route in router.components:
        if req.path.startsWith(router.componentPath & route.path):
            return some(route.doRoute(req, res))

proc matchPage(router: Router, req: Request, res: Response): Option[string] =
    result = none[string]()
    for route in router.pages:
        if req.path.startsWith(route.path):
            return some(router.buildPage(route.doRoute(req, res)))

proc matchGeneric(router: Router, req: Request, res: Response): Option[string] =
    result = none[string]()
    for route in router.routes:
        if req.path.startsWith(route.path):
            return some(route.doRoute(req, res))

proc matchChildRouter(router: Router, req: Request, res: Response): Option[string] =
    result = none[string]()
    for child in router.children:
        if req.path.startsWith(child.path):
            return child.routeRequest(req, res)

proc routeRequest*(router: Router, req: Request, res: Response): Option[string] =
    for fn in router.middleware:
        if fn.kind in {mkIncoming, mkBidirectional}:
            try:
                fn.run(req, res)
            except: discard
    result = none[string]()
    try:
        if (req.path == router.path or req.path == router.path & "/") and router.index != nil:
            result = some(router.buildPage(router.index.doRoute(req, res)))
        if result.isNone(): result = router.matchComponent(req, res)
        if result.isNone(): result = router.matchPage(req, res) # TODO: Add boost integration
        if result.isNone(): result = router.matchGeneric(req, res)
        if result.isNone(): result = router.matchChildRouter(req, res)
        if result.isNone(): result = some(router.buildPage(router.fallback.doRoute(req, res)))
    except:
        try:
            res.statusCode = Http500
            result = some(router.buildPage(router.error.doRoute(req, res)))
            # TODO logging
        except: 
            result = some(router.buildPage("<h1>Cascading Error</h1><div>Error rendering error page</div>"))
            # TODO logging
    res.body = result.get("")
    for fn in router.middleware:
        if fn.kind in {mkOutgoing, mkBidirectional}:
            try:
                fn.run(req, res)
            except: discard
    
# TODO port/settings

proc serve*(router: Router) =
    proc onRequest(request: HttpBeastRequest): Future[void] {.gcsafe.} =
        let req = buildRequest(request)
        var res = Response(statusCode: Http200, headers: newHttpHeaders(), body: "")
        discard router.routeRequest(req, res)
        request.send(res.statusCode, res.body, res.headers.toString())

    run(onRequest)

var router* {.threadvar.}: Router
router = newRouter()

proc serve*() = serve(router)

export types, route, middleware, routing