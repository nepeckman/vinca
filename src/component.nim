import macros, strutils
import server, types
import component/[idents, path, runtime]
import component/[routegen, linkergen, rendergen]
import json

proc getRouter(body: NimNode): NimNode =
    let explicitRouter = body.findChild(it.kind == nnkAsgn and it[0].strVal == "router") 
    if explicitRouter.kind != nnkNilLit: explicitRouter
    else: ident("router")

proc getTypeName(name: NimNode): NimNode = ident(capitalizeAscii(name.strVal & "Component"))

proc getComponentType(name, renderProc: NimNode): NimNode =
    let params = renderProc.findChild(it.kind == nnkFormalParams)
    let pragma = newNimNode(nnkPragma)
    pragma.add(ident("closure"))
    pragma.add(ident("gcsafe"))
    let renderTy = newNimNode(nnkProcTy)
    renderTy.add(params)
    renderTy.add(pragma)
    let linkerTy = newNimNode(nnkProcTy)
    linkerTy.add(copyNimTree(params))
    linkerTy.add(pragma)
    linkerTy[0][0] = bindSym("string")
    let typeName = getTypeName(name)
    result = quote do:
        type `typeName`* = tuple[render: `renderTy`, linker: `linkerTy`, route: Route]

proc generateComponentTuple(): NimNode =
    let renderSym = getRenderProc()
    let linkerSym = getLinkerProc()
    let routeSym = getRouteObj()
    result = quote do:
        (render: `renderSym`, linker: `linkerSym`, route: `routeSym`)

proc generateComponent(name: NimNode, isPage: bool, body: NimNode): NimNode =
    result = newStmtList()
    let path = getPath(name, body)
    let router = getRouter(body)
    let renderStmt = body.findChild(it.kind == nnkAsgn and it[0].strVal == "render")
    if renderStmt == nil:
        raise newCompileError("Component is missing render proc")
    let suppressWarning = quote do:
        {.push warning[GcUnsafe2]: off.}
        {.push hint[XDeclaredButNotUsed]: off.}
    let enableWarning = quote do:
        {.push warning[GcUnsafe2]: on.}
        {.push hint[XDeclaredButNotUsed]: on.}
    let renderProc = generateRenderProc(path, renderStmt[1])
    let componentType = getComponentType(name, renderProc)
    let typeName = getTypeName(name)
    result.add(componentType)
    result.add(quote do:
        var `name`* {.threadvar.}: `typeName`)
    var blockStatements = newStmtList()
    blockStatements.add(suppressWarning)
    blockStatements.add(generateLinkerProc(path, renderProc, isPage, router))
    blockStatements.add(renderProc)
    blockStatements.add(generateRouteProc(path, renderProc))
    blockStatements.add(generateRouteObj(path, isPage, router))
    blockStatements.add(enableWarning)
    blockStatements.add(generateComponentTuple())
    let blockBody = newBlockStmt(blockStatements)
    result.add(quote do:
        `name` = `blockBody`)

macro component*(name: untyped, body: untyped): untyped = generateComponent(name, false, body)

macro page*(name: untyped, body: untyped): untyped = generateComponent(name, true, body)

export runtime, json, router

## TODO Validate:
## Render always exists
## Only render, path, linker, route
## All path params are strings
## All path params at the end of the path
## render returns VNode
## linker returns string
## route returns VNode