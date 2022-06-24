import class
import color

proc name(val: int): string {.compiletime.} = "border-" & $val
proc name(color: ColorKind): string {.compiletime.} = "border-" & $color
proc name(prefix: string, val: int): string {.compiletime.} = "border-" & prefix & "-" & $val
proc toUnits(val: int): string {.compiletime.} = $val & "px"

proc border*(val: static[int]): string = initClass(name(val), "border-width", val.toUnits)
proc border*(color: static[ColorKind]): string = initClass(name(color), "border-color", getColor(color))
proc borderTop*(val: static[int]): string = initClass(name("top", val), "border-top-width", val.toUnits)
proc borderBottom*(val: static[int]): string = initClass(name("bottom", val), "border-bottom-width", val.toUnits)
proc borderLeft*(val: static[int]): string = initClass(name("left", val), "border-left-width", val.toUnits)
proc borderRight*(val: static[int]): string = initClass(name("right", val), "border-right-width", val.toUnits)
