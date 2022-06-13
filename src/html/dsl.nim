import macros, strutils
import vdom

proc newElement*(kind: VNodeKind, children: seq[VNode], modifiers: varargs[NodeModifier]): VNode =
    result = newVNode(kind)
    result.kids = children
    for modifier in modifiers:
        modifier(result)

proc parseVNodeKind(kind: string): VNodeKind =
    if kind == "vdiv": VNodeKind.vdiv
    else: parseEnum[VNodeKind](kind)

proc isElementKind(ident: NimNode): bool =
    try:
        discard parseVNodeKind(ident.strVal)
        result = true
    except:
        result = false

proc buildHtml(body: NimNode): NimNode =
    result = newNimNode(nnkCall)
    result.add(ident("newElement"))
    result.add(body[0])
    var elementChildren = newNimNode(nnkPrefix)
    elementChildren.add(bindSym("@"))
    elementChildren.add(newNimNode(nnkBracket))
    var stmtList = body.findChild(it.kind == nnkStmtList)
    for statement in stmtList.children:
        if statement.kind == nnkCall and statement[0].isElementKind():
            echo statement[0].strVal
            elementChildren[1].add(statement.buildHtml())
        elif statement.kind == nnkStrLit:
            elementChildren[1].add(newCall(ident("text"), statement))
        else:
            elementChildren[1].add(statement)
    result.add(elementChildren)
    for idx in 1..(body.len - 1):
        let child = body[idx]
        if child.kind != nnkStmtList:
            result.add(child)

proc dslRoot(rootKind: NimNode, body: NimNode): NimNode =
    result = newNimNode(nnkCall)
    result.add(ident("newElement"))
    result.add(rootKind)
    var elementChildren = newNimNode(nnkPrefix)
    elementChildren.add(bindSym("@"))
    elementChildren.add(newNimNode(nnkBracket))
    for statement in body:
        echo statement.kind
        let typeStr = 
            try: statement.getTypeInst().strVal()
            except: ""
        echo typeStr
        if statement.kind == nnkCall and statement[0].isElementKind():
            echo statement[0].strVal
            elementChildren[1].add(statement.buildHtml())
        elif statement.getTypeInst().strVal() == "string":
            elementChildren[1].add(newCall(ident("text"), statement))
        else:
            elementChildren[1].add(statement)
    result.add(elementChildren)

macro htmlDsl*(rootKind: untyped, body: untyped): untyped =
    result = dslRoot(rootKind, body)
    echo repr result

macro htmlDsl*(body: untyped): untyped = 
    result = dslRoot(newDotExpr(bindSym("VNodeKind"), bindSym("vdiv")), body)
    echo repr result

when isMainModule:
    import strutils, attributes, ../ajax

    let html = htmlDsl():
        vdiv():
            p(id("para"), get("something")): "asdfg"
            "poiut"
            "another"
            button(id "asdk", class "mx-2 my-4", disabled()):
                span(): "button"
    
    echo $html
    echo parseEnum[VNodeKind]("div")