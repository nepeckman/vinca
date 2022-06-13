import src/vinca

let counter = component():
  render = proc (val: int): VNode =
    result = htmlDsl():
      vdiv(post(linker(val + 1), trigger = trigger(HtmlEvent.mouseenter))):
        span(): $val
        button(): "Increment"

let post = page():
  path = "post/@content"
  render = proc (content: string): VNode =
    result = htmlDsl():
      span(): content

let about = page():
  path = "about"
  render = proc (): VNode =
    result = htmlDsl():
      span(): "This is a site powered by vinca"

let index = page():
  render = proc (): VNode =
    result = htmlDsl():
      vdiv():
        a(href about.linker()): "About"
        a(href post.linker("blah")): "Blah Page"
      counter.render(0)

router.index = index.route
serve()