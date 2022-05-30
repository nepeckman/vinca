import karax/karaxdsl
import component, server
import types, selector, ajax

proc hxEl*(nodeKind: VNodeKind, modifiers: varargs[NodeModifier]): VNode =
  result = newVNode(nodeKind)
  for modifier in modifiers:
    modifier(result)


export types, selector, ajax
export component, server
export karaxdsl