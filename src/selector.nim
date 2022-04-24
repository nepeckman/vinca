import types 

type SelectorKind* = enum skClass, skId
type Selector* = object
  kind: SelectorKind
  name*: string
  scopedName: string

proc `$`*(selector: Selector): string = selector.scopedName

proc select*(selector: Selector): string =
  case selector.kind
  of skId: "#" & selector.scopedName
  of skClass: "." & selector.scopedName

type Scope* = object
  name: string

proc newScope*(name: string): Scope = Scope(name: name)

proc `&`*(scope: Scope, str: string): Scope = Scope(name: scope.name & str)

proc newIdSelector*(scope: Scope, id: string): Selector =
  Selector(kind: skId, name: id, scopedName: "hx-" & scope.name & "-" & id)

proc newClassSelector*(scope: Scope, class: string): Selector =
  Selector(kind: skClass, name: class, scopedName: "hx-" & scope.name & "-" & class)

proc hxTarget*(target: Selector): HxModifier =
  return proc (node: VNode) = node.setAttr("hx-target", target.select)