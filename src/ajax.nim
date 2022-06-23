import httpcore
import html/vdom, selector
import ajax/[parameters, trigger]

type SwapType* = enum innerHTML, outerHTML, afterbegin, beforebegin, afterend, beforeend, noSwap

proc methodToAttr(httpMethod: HttpMethod): string =
  case httpMethod
  of HttpGet: "hx-get"
  of HttpPost: "hx-post"
  of HttpPut: "hx-put"
  of HttpPatch: "hx-patch"
  of HttpDelete: "hx-delete"
  else: ""

proc ajax(path: string, httpMethod: HttpMethod, target: Selector, trigger: Trigger, swapType: SwapType,
  params: AjaxParam, includeEl: Selector): NodeModifier =
  return proc (node: VNode) =
    node.setAttr(httpMethod.methodToAttr, path)
    node.setAttr("hx-target", target.select)
    node.setAttr("hx-trigger", $trigger)
    node.setAttr("hx-swap", $swapType)
    if params != nil:
      node.setAttr("hx-params", $params)
    if includeEl.kind != skThis:
      node.setAttr("hx-include", includeEl.querySelect)

proc get*(path: string, target = thisSelector(), trigger = defaultTrigger, swapType = outerHTML, 
  params: AjaxParam = nil, includeEl = thisSelector()): NodeModifier =
  result = ajax(path, HttpGet, target, trigger, swapType, params, includeEl)

proc post*(path: string, target = thisSelector(), trigger = defaultTrigger, swapType = outerHTML, 
  params: AjaxParam = nil, includeEl = thisSelector()): NodeModifier =
  result = ajax(path, HttpPost, target, trigger, swapType, params, includeEl)

proc put*(path: string, target = thisSelector(), trigger = defaultTrigger, swapType = outerHTML, 
  params: AjaxParam = nil, includeEl = thisSelector()): NodeModifier =
  result = ajax(path, HttpPut, target, trigger, swapType, params, includeEl)

proc patch*(path: string, target = thisSelector(), trigger = defaultTrigger, swapType = outerHTML, 
  params: AjaxParam = nil, includeEl = thisSelector()): NodeModifier =
  result = ajax(path, HttpPatch, target, trigger, swapType, params, includeEl)

proc delete*(path: string, target = thisSelector(), trigger = defaultTrigger, swapType = outerHTML, 
  params: AjaxParam = nil, includeEl = thisSelector()): NodeModifier =
  result = ajax(path, HttpDelete, target, trigger, swapType, params, includeEl)

export parameters, trigger