import class
import spacing, sizing, color, typography, layout, border

proc classList*(classes: varargs[string]): string =
  if classes.len == 0:
    return
  result = classes[0]
  for idx in 1..<classes.len:
    result = result & " " & classes[idx]

proc `&`*(classes: openArray[string]): string = classList(classes)

export getStylesheet, ClassModifierKind
export spacing, sizing, color, typography, layout, border
