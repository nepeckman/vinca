import sequtils, strutils
import types, selector

type HxEvent* {.pure.} = enum click, submit
type HxEventModifier* = distinct string

proc once*(): HxEventModifier = HxEventModifier("once")
proc changed*(): HxEventModifier = HxEventModifier("changed")
proc delay*(delay: int): HxEventModifier = HxEventModifier("delay:" & $delay & "ms")
proc throttle*(throttle: int): HxEventModifier =
  HxEventModifier("throttle" & $throttle & "ms")
proc fromMod*(selector: Selector): HxEventModifier = HxEventModifier("from:" & selector.select)
proc target*(selector: Selector): HxEventModifier = HxEventModifier("target:" & selector.select)

proc hxTrigger*(event: HxEvent, filter: string = "", modifiers: seq[HxEventModifier] = @[]): HxModifier =
  return proc (node: VNode) =
    let expression = $event &
      (if filter != "": "[" & filter & "]" else: "") &
      (if modifiers.len > 0: modifiers.mapIt(string(it)).join(" ") else: "")
    let currentTrigger = node.getAttr("hx-target")
    if currentTrigger == "":
      node.setAttr("hx-trigger", expression)
    else:
      node.setAttr("hx-trigger", currentTrigger & ", " & expression)

proc hxPoll*(time: int): HxModifier =
  return proc (node: VNode) =
    let expression = "every " & $time & "ms" 
    let currentTrigger = node.getAttr("hx-target")
    if currentTrigger == "":
      node.setAttr("hx-trigger", expression)
    else:
      node.setAttr("hx-trigger", currentTrigger & ", " & expression)