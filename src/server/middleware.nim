import types

type MiddlewareKind* = enum mkIncoming, mkOutgoing, mkBidirectional
type MiddlewareFn* = proc (req: Request, res: Response) {.gcsafe.}

type Middleware* = ref object
  kind*: MiddlewareKind
  run*: MiddlewareFn

proc newMiddleware*(kind: MiddlewareKind, run: MiddlewareFn): Middleware = Middleware(kind: kind, run: run)
proc newMiddleware*(run: MiddlewareFn): Middleware = newMiddleware(mkBidirectional, run)