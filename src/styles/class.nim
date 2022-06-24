import strformat, sets

type Class* = distinct string

proc `&`*(c1, c2: Class): Class = Class(string(c1) & " " & string(c2))
proc `$`*(c: Class): string = string(c)

var stylesheet {.compiletime.} = ""
var generatedClasses {.compiletime.}: HashSet[string]

proc initClass*(class, prop, val: string): string {.compiletime.} =
  if class notin generatedClasses:
    generatedClasses.incl(class)
    var css = fmt".{class} {{{prop}: {val}; }}"
    stylesheet = stylesheet & " " & css
  result = class

proc initClass*(class: string, props: seq[string], val: string): string {.compiletime.} =
  if class notin generatedClasses:
    generatedClasses.incl(class)
    var styles: string
    for prop in props:
      styles = styles & fmt"{prop}: {val}; "
    var css = fmt".{class} {{{styles}}}"
    stylesheet = stylesheet & " " & css
  result = class


type ClassModifierKind* = enum cmkHover

proc getModifier(kind: ClassModifierKind): string {.compiletime.} =
  case kind
  of cmkHover: "hover"

proc initModifiableClass*(class, prop, val: string, modifier: ClassModifierKind): string {.compiletime.} =
  let psuedoClass = modifier.getModifier
  let classname = class & "-" & psuedoClass
  if classname notin generatedClasses:
    generatedClasses.incl(classname)
    var css = fmt".{classname}:{psuedoClass} {{{prop}: {val}; }}"
    stylesheet = stylesheet & " " & css
  result = classname

proc getStylesheet*(): string {.compiletime.} = stylesheet
