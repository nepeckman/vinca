import sequtils, strutils
import ../selector

type HtmlEvent* {.pure.} = enum click, submit, change, load, revealed, intersect,
  abort, auxclick, beforeinput, blur, compositionend, compositionstart, compositionupdate,
  contextmenu, dblclick, error, focus, focusin, focusout, input, keydown, keypress, keyup,
  mousedown, mouseenter, mouseleave, mousemove, mouseout, mouseover, mouseup,
  select, unload, wheel
type EventModifier* = distinct string

proc once*(): EventModifier = EventModifier("once")
proc changed*(): EventModifier = EventModifier("changed")
proc delay*(delay: int, unit = "ms"): EventModifier = EventModifier("delay:" & $delay & unit)
proc throttle*(throttle: int, unit = "ms"): EventModifier = EventModifier("throttle" & $throttle & unit)
proc fromSelector*(selector: Selector): EventModifier = EventModifier("from:" & selector.select)
proc root*(selector: Selector): EventModifier = EventModifier("root:" & selector.select)
proc threshold*(val: float): EventModifier = EventModifier("threshold:" & $val)

type Trigger* = distinct string

proc `&`*(a: Trigger, b: Trigger): Trigger = Trigger(string(a) & ", " & string(b))

proc `$`*(trigger: Trigger): string = string(trigger)

let defaultTrigger* = Trigger("")

proc trigger*(event: HtmlEvent, filter: string = "", modifiers: seq[EventModifier] = @[]): Trigger =
    let expression = $event &
        (if filter != "": "[" & filter & "]" else: "") & " " &
        (if modifiers.len > 0: modifiers.mapIt(string(it)).join(" ") else: "")
    result = Trigger(expression)

proc poll*(time: int, unit = "ms"): Trigger = Trigger("every " & $time & "ms" )