import src/vinca

let counter = component():
  render = proc (val: int): VNode =
    result = buildHtml(tdiv):
      hxEl(tdiv, hxPost(linker(val + 1)), hxTarget(thisSelector), hxSwap("outerHTML")):
        span(): text $val
        button(): text "Increment"

let post = page():
  path = "post/@content"
  render = proc (content: string): VNode =
    result = buildHtml(tdiv):
      span(): text content

let about = page():
  path = "about"
  render = proc (): VNode =
    result = buildHtml(tdiv):
      span(): text "This is a site powered by vinca"

let index = page():
  render = proc (): VNode =
    result = buildHtml(tdiv):
      tdiv():
        a(href = about.linker()): text "About"
        a(href = post.linker("blah")): text "Blah Page"
      counter.render(0)

router.index = index.route
serve()