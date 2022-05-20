import src/vinca

let counter = component():
  render = proc (val: int): VNode =
    result = buildHtml(tdiv):
      hxEl(tdiv, hxPost(linker(val + 1)), hxTarget(thisSelector), hxSwap("outerHTML")):
        span(): text $val
        button(): text "Increment"

let index = page():
  render = proc (): VNode =
    result = buildHtml(tdiv):
      counter.render(0)

router.index = index.route
serve()