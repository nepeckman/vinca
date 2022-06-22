import macros
import path, idents

proc generateRenderProc*(path: Path, renderProc: NimNode): NimNode =
    var procDef = newNimNode(nnkProcDef)
    copyChildrenTo(renderProc, procDef)
    var oldBody = renderProc[6]
    let scope = ident("scope")
    let scopeName = newStrLitNode(path.base)
    var body = newStmtList(quote do:
        var `scope` = newScope(`scopeName`)
    )
    copyChildrenTo(oldBody, body)
    procDef.addPragma(ident("closure"))
    procDef.addPragma(ident("gcsafe"))
    procDef[6] = body
    procDef[0] = getRenderProc()
    result = procDef