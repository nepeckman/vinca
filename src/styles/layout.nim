import class

type PositionKind* = enum pkStatic, pkFixed, pkAbsolute, pkRelative, pkSticky

proc getPosition(kind: PositionKind): string =
  case kind
  of pkStatic: "static"
  of pkFixed: "fixed"
  of pkAbsolute: "absolute"
  of pkRelative: "relative"
  of pkSticky: "sticky"

proc position*(kind: static[PositionKind]): string =
  const position = getPosition(kind)
  result = initClass(position, "position", position)

type DisplayKind* = enum dkBlock, dkInline, dkInlineBlock, dkFlex, dkInlineFlex, dkGrid

proc getDisplay(kind: DisplayKind): string =
  case kind
  of dkBlock: "block"
  of dkInline: "inline"
  of dkInlineBlock: "inline-block"
  of dkFlex: "flex"
  of dkInlineFlex: "inline-flex"
  of dkGrid: "grid"

proc display*(kind: static[DisplayKind]): string =
  const display = getDisplay(kind)
  result = initClass(display, "display", display)

proc top*(val: static[int]): string =
  const px = $val & "px"
  const name = "top-" & $val
  initClass(name, "top", px)

proc bottom*(val: static[int]): string =
  const px = $val & "px"
  const name = "bottom-" & $val
  initClass(name, "bottom", px)

proc left*(val: static[int]): string =
  const px = $val & "px"
  const name = "left-" & $val
  initClass(name, "left", px)

proc right*(val: static[int]): string =
  const px = $val & "px"
  const name = "right-" & $val
  initClass(name, "right", px)
