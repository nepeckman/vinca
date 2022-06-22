import os
import types, ../html/vdom

type GenericRouteFn* = proc (req: Request, res: Response): string {.gcsafe.}

type ComponentRouteFn* = proc (req: Request, res: Response): VNode {.gcsafe.}

type VincaRouteKind* = enum vrkComponent, vrkGeneric, vrkStatic, vrkDirectory

type Route* = ref object
  path*: string
  case kind*: VincaRouteKind
  of vrkComponent: componentRoute: ComponentRouteFn
  of vrkGeneric: genericRoute: GenericRouteFn
  of vrkStatic: staticPage: string
  of vrkDirectory: directory: string

proc newComponentRoute*(path: string, route: ComponentRouteFn): Route = Route(path: path, kind: vrkComponent, componentRoute: route)

proc newGenericRoute*(path: string, route: GenericRouteFn): Route = Route(path: path, kind: vrkGeneric, genericRoute: route)

proc newStaticRoute*(path: string, page: string): Route = Route(path: path, kind: vrkStatic, staticPage: page)

proc newDirectoryRoute*(path: string, directory: string): Route = Route(path: path, kind: vrkDirectory, directory: directory)

proc doRoute*(route: Route, req: Request, res: Response): string =
    case route.kind
    of vrkComponent: $route.componentRoute(req, res)
    of vrkGeneric: route.genericRoute(req, res)
    of vrkStatic: route.staticPage
    of vrkDirectory: 
        if fileExists(route.directory & "/" & req.path): readFile(route.directory & "/" & req.path)
        else: ""