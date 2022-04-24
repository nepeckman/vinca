import asynchttpserver, asyncdispatch
import src/vinca

proc index(): VNode =
  let scope = newScope("index")
  let textId = scope.newIdSelector("text")
  result = buildHtml(tdiv):
    hxEl(form, hxPost("/submit"), hxTarget(textId)):
      input(name="name")
      button(): text "Submit"
    span(id = $textId)

proc createPage(page: VNode): string =
  result = "<!DOCTYPE html>\n" & $page & "\n<script src=\"https://unpkg.com/htmx.org@1.7.0\"></script>"

let server = newAsyncHttpServer()

proc cb(req: Request) {.async, gcsafe.} =
  echo "New request"
  echo req.headers
  echo req.body
  echo "\n"
  case req.url.path:
  of "/index.html", "/", "": await req.respond(Http200, createPage(index()))
  of "/submit": await req.respond(Http200, "<span>clicked</span>")
  else: await req.respond(Http404, "<div>Not found</div>")

waitFor server.serve(Port(8080), cb)
