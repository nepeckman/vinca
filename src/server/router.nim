import types, route, middleware
import ../html

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
  index*: Route
  error*: Route
  fallback*: Route

proc defaultFallbackPage(req: Request, res: Response): VNode =
    htmlDsl():
        h2(): "404 Not Found"

proc defaultErrorPage(req: Request, res: Response): VNode =
    htmlDsl():
        h2(): "Server Error: " & $res.statusCode

proc newRouter*(): Router = Router(path: "", componentPath: "/components", components: @[], pages: @[],
    header: "<!DOCTYPE html>\n<html>\n", footer: "\n<script src=\"https://unpkg.com/htmx.org@1.7.0\"></script>\n</html>",
    children: @[], error: newComponentRoute("", defaultErrorPage), fallback: newComponentRoute("", defaultFallbackPage))

proc addComponent*(router: Router, route: Route) = router.components.add(route)

proc addPage*(router: Router, route: Route) = router.pages.add(route)

proc addRoute*(router: Router, route: Route) = router.routes.add(route)

proc addMiddleware*(router: Router, middleware: Middleware) = router.middleware.add(middleware)

proc addChildRouter*(router: Router, child: Router) = router.children.add(child)

proc buildPage*(router: Router, body: string): string = router.header & body & router.footer