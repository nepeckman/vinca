import options, asyncdispatch

import httpbeast

type ComponentType = tuple[render: proc (): string {.closure, gcsafe.}]

var comp {.threadvar.}: ComponentType 
comp = block:
    proc render(): string {.closure, gcsafe.} = "hello "
    (render: render)

var page {.threadvar.}: ComponentType 
page = block:
    proc render(): string {.closure, gcsafe.} = comp.render() & "me"
    (render: render)

proc onRequest(req: Request): Future[void] =
  if req.httpMethod == some(HttpGet):
    case req.path.get()
    of "/":
      req.send(page.render())
    else:
      req.send(Http404)

run(onRequest)