import os
import types, karax/vdom

type GenericRouteFn* = proc (req: Request, res: Response): string {.gcsafe.}

type ComponentRouteFn* = proc (req: Request, res: Response): VNode {.gcsafe.}

type VincaRouteKind* = enum vrkComponent, vrkGeneric, vrkStatic, vrkDirectory

type Route* = ref object
  path*: string
  case kind*: VincaRouteKind
  of vrkComponent: renderComponent: ComponentRouteFn
  of vrkGeneric: renderGeneric: GenericRouteFn
  of vrkStatic: staticPage: string
  of vrkDirectory: directory: string

proc newComponentRoute*(path: string, render: ComponentRouteFn): Route = Route(path: path, kind: vrkComponent, renderComponent: render)

proc newGenericRoute*(path: string, render: GenericRouteFn): Route = Route(path: path, kind: vrkGeneric, renderGeneric: render)

proc newStaticRoute*(path: string, page: string): Route = Route(path: path, kind: vrkStatic, staticPage: page)

proc newDirectoryRoute*(path: string, directory: string): Route = Route(path: path, kind: vrkDirectory, directory: directory)

proc render*(route: Route, req: Request, res: Response): string =
    case route.kind
    of vrkComponent: $route.renderComponent(req, res)
    of vrkGeneric: route.renderGeneric(req, res)
    of vrkStatic: route.staticPage
    of vrkDirectory: 
        if fileExists(route.directory & "/" & req.path): readFile(route.directory & "/" & req.path)
        else: ""