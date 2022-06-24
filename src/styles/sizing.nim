import strutils
import class

proc toUnits(val: int): string {.compiletime.} = $(val div 4) & "rem"

proc width*(val: static[int]): string = initClass("w-" & $val, "width", val.toUnits)
proc width*(val: static[string]): string =
  const name = "w-" & val.replace(".", "-").replace("%", "per")
  initClass(name, "width", val)
