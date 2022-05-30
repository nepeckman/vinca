type SelectorKind* = enum skClass, skId, skThis
type Selector* = object
  kind*: SelectorKind
  name*: string

proc `$`*(selector: Selector): string = selector.name

proc select*(selector: Selector): string =
  case selector.kind
  of skId: "#" & selector.name
  of skClass: "." & selector.name
  of skThis: "this"

proc querySelect*(selector: Selector): string =
  case selector.kind
  of skId: "[id='" & selector.name & "']"
  of skClass: "[class='" & selector.name & "']"
  of skThis: "this"

type Scope* = object
  name: string

proc newScope*(name: string): Scope = Scope(name: name)

proc `&`*(scope: Scope, str: string): Scope = Scope(name: scope.name & str)

proc newIdSelector*(scope: Scope, id: string): Selector =
  Selector(kind: skId, name: scope.name & "-" & id)

proc newClassSelector*(scope: Scope, class: string): Selector =
  Selector(kind: skClass, name: scope.name & "-" & class)

let thisSelector* = Selector(kind: skThis, name: "this")