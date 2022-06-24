import class

type ColorKind* = enum
  ckTransparent, ckCurrent, ckBlack, ckWhite,
  ckGray, ckLightGray, ckDarkGray,
  ckRed, ckLightRed, ckDarkRed,
  ckPink, ckLightPink, ckDarkPink,
  ckOrange, ckLightOrange, ckDarkOrange,
  ckYellow, ckLightYellow, ckDarkYellow,
  ckGreen, ckLightGreen, ckDarkGreen,
  ckBlue, ckLightBlue, ckDarkBlue,
  ckPurple, ckLightPurple, ckDarkPurple

proc getColor*(kind: ColorKind): string {.compiletime.} =
  case kind
  of ckTransparent: "transparent"
  of ckCurrent: "currentColor"
  of ckBlack: "#000"
  of ckWhite: "#fff"
  of ckGray: "#bdbdbd"
  of ckLightGray: "#efefef"
  of ckDarkGray: "#8d8d8d"
  of ckRed: "#f44336"
  of ckLightRed: "#ff7961"
  of ckDarkRed: "#ba000d"
  of ckPink: "#ec407a"
  of ckLightPink: "#ff77a9"
  of ckDarkPink: "#b4004e"
  of ckOrange: "#ffa726"
  of ckLightOrange: "#ffd95b"
  of ckDarkOrange: "#c77800"
  of ckYellow: "#ffeb3b"
  of ckLightYellow: "#ffff72"
  of ckDarkYellow: "#c8b900"
  of ckGreen: "#66bb6a"
  of ckLightGreen: "#98ee99"
  of ckDarkGreen: "#338a3e"
  of ckBlue: "#42a5f5"
  of ckLightBlue: "#80d6ff"
  of ckDarkBlue: "#0077c2"
  of ckPurple: "#ba68c8"
  of ckLightPurple: "#ee98fb"
  of ckDarkPurple: "#883997"

