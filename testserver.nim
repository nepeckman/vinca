import src/vinca

component counter:
  render = proc (val: int): VNode =
    result = htmlDsl():
      vdiv(post(linker(val + 1), trigger = trigger(HtmlEvent.mouseenter))):
        span(): $val
        button(): "Increment"

page post:
  path = "post/@content"
  render = proc (content: string): VNode =
    result = htmlDsl():
      span(): content

page about:
  path = "about"
  render = proc (): VNode =
    result = htmlDsl():
      span(): "This is a site powered by vinca"

page index:
  render = proc (): VNode =
    result = htmlDsl():
      vdiv():
        a(href about.linker()): "About"
        a(href post.linker("blah")): "Blah Page"
      counter.render(0)

var myRouter {.threadvar.}: Router
proc getRouter(): Router {.gcsafe.} =
  if myRouter.isNil:
    myRouter = newRouter()
    autoRoute(myRouter)
    myRouter.index = index.route
  result = myRouter

serve(getRouter)