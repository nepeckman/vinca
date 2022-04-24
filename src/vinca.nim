import karax/karaxdsl
import types, selector, ajax, trigger

proc hxEl*(nodeKind: VNodeKind, modifiers: varargs[HxModifier]): VNode =
  result = newVNode(nodeKind)
  for modifier in modifiers:
    modifier(result)


export types, selector, ajax, trigger
export karaxdsl