import types

proc hxGet*(path: string): HxModifier =
  return proc (node: VNode) = node.setAttr("hx-get", path)
proc hxPost*(path: string): HxModifier =
  return proc (node: VNode) = node.setAttr("hx-post", path)
proc hxPut*(path: string): HxModifier =
  return proc (node: VNode) = node.setAttr("hx-put", path)
proc hxPatch*(path: string): HxModifier =
  return proc (node: VNode) = node.setAttr("hx-path", path)
proc hxDelete*(path: string): HxModifier =
  return proc (node: VNode) = node.setAttr("hx-delete", path)