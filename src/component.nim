import macros
import server, types
import component/[idents, path, runtime]
import component/[routegen, linkergen, rendergen]
import json

proc generateComponentTuple(): NimNode =
    let renderSym = getRenderProc()
    let linkerSym = getLinkerProc()
    let routeSym = getRouteObj()
    result = quote do:
        (render: `renderSym`, linker: `linkerSym`, route: `routeSym`)

proc generateComponent(router: NimNode, isPage: bool, body: NimNode): NimNode =
    let path = getPath(body)
    let renderStmt = body.findChild(it.kind == nnkAsgn and it[0].strVal == "render")
    if renderStmt == nil:
        raise newCompileError("Component is missing render proc")
    let suppressWarning = quote do:
        {.push warning[GcUnsafe2]: off.}
    let enableWarning = quote do:
        {.push warning[GcUnsafe2]: on.}
    let renderProc = generateRenderProc(path, renderStmt[1])
    var blockStatements = newStmtList()
    blockStatements.add(suppressWarning)
    blockStatements.add(generateLinkerProc(path, renderProc, isPage, router))
    blockStatements.add(renderProc)
    blockStatements.add(generateRouteProc(path, renderProc))
    blockStatements.add(generateRouteObj(path, isPage, router))
    blockStatements.add(enableWarning)
    blockStatements.add(generateComponentTuple())
    result = newBlockStmt(blockStatements)

macro component*(body: untyped): untyped = generateComponent(ident("router"), false, body)

macro component*(router: untyped, body: untyped): untyped = generateComponent(router, false, body)

macro page*(body: untyped): untyped = generateComponent(ident("router"), true, body)

macro page*(router: untyped, body: untyped): untyped = generateComponent(router, true, body)

export runtime, json, router
