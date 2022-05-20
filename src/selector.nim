import types 

type SelectorKind* = enum skClass, skId, skThis
type Selector* = object
  kind: SelectorKind
  name*: string
  scopedName: string

proc `$`*(selector: Selector): string = selector.scopedName

proc select*(selector: Selector): string =
  case selector.kind
  of skId: "#" & selector.scopedName
  of skClass: "." & selector.scopedName
  of skThis: "this"

type Scope* = object
  name: string

proc newScope*(name: string): Scope = Scope(name: name)

proc `&`*(scope: Scope, str: string): Scope = Scope(name: scope.name & str)

proc newIdSelector*(scope: Scope, id: string): Selector =
  Selector(kind: skId, name: id, scopedName: scope.name & "-" & id)

proc newClassSelector*(scope: Scope, class: string): Selector =
  Selector(kind: skClass, name: class, scopedName: scope.name & "-" & class)

let thisSelector* = Selector(kind: skThis, name: "this", scopedName: "this")

proc hxTarget*(target: Selector): HxModifier =
  return proc (node: VNode) = node.setAttr("hx-target", target.select)

proc hxSwap*(swap: string): HxModifier =
  return proc (node: VNode) = node.setAttr("hx-swap", swap)