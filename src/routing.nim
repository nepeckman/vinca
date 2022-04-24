import tables, strutils, httpcore
import httpbeast, options, karax/karaxdsl
import asyncdispatch
import types

type HttpBeastRequest = httpbeast.Request

type Request* = ref object
  path*: string
  httpMethod*: HttpMethod
  headers*: HttpHeaders
  body*: string

type Response* = ref object
  statusCode*: HttpCode
  headers*: HttpHeaders
  body: string

proc toString(headers: HttpHeaders): string =
    result = ""
    for key, val in headers.table.pairs:
        result = result & key & ": " & val[0] & "\c\L"

type RouteFn* = proc (req: Request, res: Response): VNode {.gcsafe.}

proc body*(resp: Response): string = resp.body

type Route* = ref object
  path*: string
  render*: RouteFn

proc newRoute*(path: string, render: RouteFn): Route = Route(path: path, render: render)

type MiddlewareKind* = enum mkIncoming, mkOutgoing, mkBidirectional
type MiddlewareFn* = proc (req: Request, res: Response) {.gcsafe.}

type Middleware* = ref object
  kind*: MiddlewareKind
  run*: MiddlewareFn

proc newMiddleware*(kind: MiddlewareKind, run: MiddlewareFn): Middleware = Middleware(kind: kind, run: run)
proc newMiddleware*(run: MiddlewareFn): Middleware = newMiddleware(mkBidirectional, run)

type Router* = ref object
  path*: string
  componentPath*: string
  pagePath*: string
  components*: seq[Route]
  pages*: seq[Route]
  header*: string
  footer*: string
  middleware*: seq[Middleware]
  children*: seq[Router]
  error*: RouteFn
  fallback*: RouteFn

proc defaultFallbackPage(req: Request, res: Response): VNode =
    buildHtml(tdiv):
        h2(): text "404 Not Found"

proc defaultErrorPage(req: Request, res: Response): VNode =
    buildHtml(tdiv):
        h2(): text "Server Error: " & $res.statusCode

proc newRouter*(): Router = Router(path: "", componentPath: "/components", pagePath: "/pages", components: @[], pages: @[],
    header: "<!DOCTYPE html>\n<html>\n", footer: "\n<script src=\"https://unpkg.com/htmx.org@1.7.0\"></script>\n</html>",
    children: @[], error: defaultErrorPage, fallback: defaultFallbackPage)

proc buildRequest(req: HttpBeastRequest): Request =  
    result = Request()
    result.path = req.path.get("")
    result.httpMethod = req.httpMethod.get(HttpGet)
    result.headers = req.headers.get(newHttpHeaders())

proc buildPage(router: Router, body: VNode): string = router.header & $body & router.footer
proc buildPage(router: Router, body: string): string = router.header & body & router.footer

proc routeRequest(router: Router, req: Request, res: Response): Option[string] {.gcsafe.}

proc matchComponent(router: Router, req: Request, res: Response): Option[string] =
    result = none[string]()
    for route in router.components:
        if req.path.startsWith(router.componentPath & route.path):
            return some($route.render(req, res))

proc matchPage(router: Router, req: Request, res: Response): Option[string] =
    result = none[string]()
    for route in router.pages:
        if req.path.startsWith(router.pagePath & route.path):
            return some(router.buildPage(route.render(req, res)))

proc matchChildRouter(router: Router, req: Request, res: Response): Option[string] =
    result = none[string]()
    for child in router.children:
        if req.path.startsWith(child.path):
            return child.routeRequest(req, res)

proc routeRequest(router: Router, req: Request, res: Response): Option[string] =
    try:
        for fn in router.middleware:
            if fn.kind in {mkIncoming, mkBidirectional}:
                fn.run(req, res)
    except: discard
    result = none[string]()
    try:
        result = if req.path.startsWith(router.componentPath): router.matchComponent(req, res)
            elif req.path.startsWith(router.pagePath): router.matchPage(req, res)
            else: router.matchChildRouter(req, res)
        result = if result.isNone(): some(router.buildPage(router.fallback(req, res))) else: result
    except:
        try:
            result = some(router.buildPage(router.error(req, res)))
        except: 
            result = some(router.buildPage("<h1>Cascading Error</h1><div>Error rendering error page</div>"))
    res.body = result.get("")
    try:
        for fn in router.middleware:
            if fn.kind in {mkOutgoing, mkBidirectional}:
                fn.run(req, res)
    except: discard
    


proc serve*(router: Router) =
    proc onRequest(request: HttpBeastRequest): Future[void] {.gcsafe.} =
        let req = buildRequest(request)
        var res = Response(statusCode: Http200, headers: newHttpHeaders(), body: "")
        discard router.routeRequest(req, res)
        request.send(res.statusCode, res.body, res.headers.toString())

            

    run(onRequest)

let router* = newRouter()

proc serve*() = serve(router)