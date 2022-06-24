import class
import color

type FontKind* = enum fkSans, fkSerif, fkMono

proc getFontType(kind: FontKind): string {.compiletime.} =
  case kind
  of fkSans: "sans"
  of fkSerif: "serif"
  of fkMono: "mono"

proc getFont(kind: FontKind): string {.compiletime.} =
  let sans = """
  system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI",
  Roboto, "Helvetica Neue", Arial, "Noto Sans", sans-serif,
  "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji"
  """

  let serif = """
  Georgia, Cambria, "Times New Roman", Times, serif
  """

  let mono = """
  Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace
  """

  case kind
  of fkSans: sans
  of fkSerif: serif
  of fkMono: mono

proc font*(kind: static[FontKind]): string =
  const name = getFontType(kind)
  const font = getFont(kind)
  initClass("font-" & name, "font-family", font)

type TextSizeKind* = enum tskXS, tskSM, tskMD, tskLG, tskXL, tsk2XL, tsk3XL, tsk4XL, tsk5XL, tsk6XL


proc getTextSize(kind: TextSizeKind): string {.compiletime.} =
  case kind
  of tskXS: "0.75rem"
  of tskSM: "0.875rem"
  of tskMD: "1rem"
  of tskLG: "1.125rem"
  of tskXL: "1.25rem"
  of tsk2XL: "1.5rem"
  of tsk3XL: "1.875rem"
  of tsk4XL: "2.25rem"
  of tsk5XL: "3rem"
  of tsk6XL: "6rem"

proc text*(kind: static[TextSizeKind]): string =
  const size = getTextSize(kind)
  initClass("text-" & $kind, "font-size", size)

proc text*(color: static[ColorKind]): string =
  const colorCode = getColor(color)
  initClass("text-" & $color, "color", colorCode)

proc text*(color: static[ColorKind], modifier: static[ClassModifierKind]): string =
  const colorCode = getColor(color)
  initModifiableClass("text-" & $color, "color", colorCode, modifier)

type TextDecorationKind* = enum tdkNone, tdkStrikethrough, tdkUnderline

proc getDecoration(kind: TextDecorationKind): string {.compiletime.} =
  case kind
  of tdkNone: "none"
  of tdkStrikethrough: "line-through"
  of tdkUnderline: "underline"

proc text*(decoration: static[TextDecorationKind]): string =
  const style = decoration.getDecoration
  initClass("text-" & style, "text-decoration", style)

proc text*(decoration: static[TextDecorationKind], modifier: static[ClassModifierKind]): string =
  const style = decoration.getDecoration
  initModifiableClass("text-" & style, "text-decoration", style, modifier)
