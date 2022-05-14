import types, route, middleware
import karax/karaxdsl, karax/vdom

type Router* = ref object
  path*: string
  componentPath*: string
  components*: seq[Route]
  pages*: seq[Route]
  routes*: seq[Route]
  header*: string
  footer*: string
  middleware*: seq[Middleware]
  children*: seq[Router]
  error*: Route
  fallback*: Route

proc defaultFallbackPage(req: Request, res: Response): VNode =
    buildHtml(tdiv):
        h2(): text "404 Not Found"

let defaultFallbackRoute = newComponentRoute("", defaultFallbackPage)

proc defaultErrorPage(req: Request, res: Response): VNode =
    buildHtml(tdiv):
        h2(): text "Server Error: " & $res.statusCode

let defaultErrorRoute = newComponentRoute("", defaultErrorPage)

proc newRouter*(): Router = Router(path: "", componentPath: "/components", components: @[], pages: @[],
    header: "<!DOCTYPE html>\n<html>\n", footer: "\n<script src=\"https://unpkg.com/htmx.org@1.7.0\"></script>\n</html>",
    children: @[], error: defaultErrorRoute, fallback: defaultFallbackRoute)

proc addComponent*(router: Router, route: Route) = router.components.add(route)

proc addPage*(router: Router, route: Route) = router.pages.add(route)

proc addRoute*(router: Router, route: Route) = router.routes.add(route)

proc addMiddleware*(router: Router, middleware: Middleware) = router.middleware.add(middleware)

proc addChildRouter*(router: Router, child: Router) = router.children.add(child)