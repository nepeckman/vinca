import class

proc toUnits(val: int): string {.compiletime.} = $(val div 4) & "rem"
proc name(prefix: string, val: int): string {.compiletime.} = prefix & "-" & $val

proc m*(val: static[int]): string = initClass(name("m", val), "margin", val.toUnits)
proc ml*(val: static[int]): string = initClass(name("ml", val), "margin-left", val.toUnits)
proc mr*(val: static[int]): string = initClass(name("mr", val), "margin-right", val.toUnits)
proc mt*(val: static[int]): string = initClass(name("mt", val), "margin-top", val.toUnits)
proc mb*(val: static[int]): string = initClass(name("mb", val), "margin-bottom", val.toUnits)
proc mx*(val: static[int]): string = initClass(name("mx", val), @["margin-left", "margin-right"], val.toUnits)
proc my*(val: static[int]): string = initClass(name("my", val), @["margin-top", "margin-bottom"], val.toUnits)

proc p*(val: static[int]): string = initClass(name("p", val), "padding", val.toUnits)
proc pl*(val: static[int]): string = initClass(name("pl", val), "padding-left", val.toUnits)
proc pr*(val: static[int]): string = initClass(name("pr", val), "padding-right", val.toUnits)
proc pt*(val: static[int]): string = initClass(name("pt", val), "padding-top", val.toUnits)
proc pb*(val: static[int]): string = initClass(name("pb", val), "padding-bottom", val.toUnits)
proc px*(val: static[int]): string = initClass(name("px", val), @["padding-left", "padding-right"], val.toUnits)
proc py*(val: static[int]): string = initClass(name("py", val), @["padding-top", "padding-bottom"], val.toUnits)
