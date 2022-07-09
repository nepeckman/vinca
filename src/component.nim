import macros, strutils
import server, types
import component/[idents, path, runtime, autorouting]
import component/[routegen, linkergen, rendergen]
import json

proc getTypeName(name: NimNode): NimNode = ident(capitalizeAscii(name.strVal & "Component"))

proc generateComponentType(name, renderProc: NimNode): NimNode =
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
        type `typeName`* = ref object
            render*: `renderTy`
            linker*: `linkerTy`
            route*: Route

proc generateObjDecl(name: NimNode): NimNode = 
    let typeName = getTypeName(name)
    result = quote do:
        var `name`* {.threadvar.}: `typeName`

proc generateComponentObj(name: NimNode): NimNode =
    let typeName = getTypeName(name)
    let renderSym = getRenderProc()
    let linkerSym = getLinkerProc()
    let routeSym = getRouteObj()
    result = quote do:
        `typeName`(render: `renderSym`, linker: `linkerSym`, route: `routeSym`)

proc generateInitializerBlock(name: NimNode, path: Path, isPage: bool, renderProc: NimNode): NimNode =
    var blockStatements = newStmtList()
    blockStatements.add(generateLinkerProc(path, isPage, renderProc)) # TODO make configurable
    blockStatements.add(renderProc)
    blockStatements.add(generateRouteProc(path, renderProc))
    blockStatements.add(generateRouteObj(path))
    blockStatements.add(generateComponentObj(name))
    result = newBlockStmt(blockStatements)

proc generateInitializer(name: NimNode, path: Path, isPage: bool, renderProc: NimNode): NimNode =
    let initializer = getInitializerName(name)
    let basePath = getComponentBasePath()
    let suppressHint = quote do:
        {.push hint[XDeclaredButNotUsed]: off.}
    let enableHint = quote do:
        {.push hint[XDeclaredButNotUsed]: on.}
    let blockBody = generateInitializerBlock(name, path, isPage, renderProc)
    result = quote do:
        `suppressHint`
        proc `initializer`*(router: Router) =
            let `basePath` = router.componentPath
            if `name`.isNil:
                `name` = `blockBody`
        `enableHint`

proc generateComponent(name: NimNode, isPage: bool, body: NimNode): NimNode =
    if isPage: pageRoutes.add(name) else: componentRoutes.add(name)
    result = newStmtList()
    let path = getPath(name, body)
    let renderStmt = body.findChild(it.kind == nnkAsgn and it[0].strVal == "render")
    if renderStmt == nil:
        raise newCompileError("Component is missing render proc")
    let renderProc = generateRenderProc(path, renderStmt[1])
    result.add(generateComponentType(name, renderProc))
    result.add(generateObjDecl(name))
    result.add(generateInitializer(name, path, isPage, renderProc))

macro component*(name: untyped, body: untyped): untyped = generateComponent(name, false, body)

macro page*(name: untyped, body: untyped): untyped = generateComponent(name, true, body)

export runtime, json, autoRoute

## TODO Validate:
## Render always exists
## Only render, path, linker, route
## All path params are strings
## All path params at the end of the path
## render returns VNode
## linker returns string
## route returns VNode