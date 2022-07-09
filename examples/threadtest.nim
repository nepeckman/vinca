import options, asyncdispatch

import httpbeast

type ComponentType = ref object
  render: proc (): string {.closure, gcsafe.}

var comp {.threadvar.}: ComponentType 
proc initComp() =
  if comp.isNil:
    comp = block:
        proc render(): string {.closure, gcsafe.} = "hello "
        ComponentType(render: render)

var page {.threadvar.}: ComponentType 
proc initPage() =
  if page.isNil:
    page = block:
        proc render(): string {.closure, gcsafe.} = comp.render() & "me"
        ComponentType(render: render)

proc onRequest(req: Request): Future[void] =
  initComp()
  initPage()
  if req.httpMethod == some(HttpGet):
    case req.path.get()
    of "/":
      req.send(page.render())
    else:
      req.send(Http404)

run(onRequest)