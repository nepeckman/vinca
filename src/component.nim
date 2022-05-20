import macros, sequtils
import server, types, selector
import component/[idents, parameters, name, runtime]
import json

proc buildRenderCall(parsedParamIdent: NimNode, params: seq[ComponentParam]): NimNode =
    result = newNimNode(nnkCall)
    result.add(getRenderProc())
    for param in params:
        if param.kind == cpkQuery:
            let nameString = newStrLitNode(param.name)
            let typeIdent = ident(param.typeName)
            result.add(quote do: 
                parseJson(`parsedParamIdent`.getParam(`nameString`)).to(`typeIdent`)
            )
        elif param.kind == cpkRequest:
            result.add(ident("req"))
        elif param.kind == cpkResponse:
            result.add(ident("res"))

proc buildRouteFn(renderProc: NimNode): NimNode =
    let params = getComponentParams(renderProc)
    let route = getRouteProc()
    let parsedQueryParams = ident("parsedQueryParams")
    let req = ident("req")
    let res = ident("res")
    let call = buildRenderCall(parsedQueryParams, params)
    result = quote do:
        proc `route`(`req`: Request, `res`: Response): VNode {.gcsafe.} =
            let `parsedQueryParams` = parseQueryParams(`req`.path)
            `call`

proc buildRoute(path: string, isPage: bool, router: NimNode): NimNode =
    let route = getRouteObj()
    let routeFn = getRouteProc()
    let pathNode = newStrLitNode("/" & path)
    let addCall = if isPage: ident("addPage") else: ident("addComponent")
    result = quote do:
        let `route` = newComponentRoute(`pathNode`, `routeFn`)
        `router`.`addCall`(`route`)

proc getParamIdents(p: NimNode): seq[NimNode] =
    let formalParams = p.findChild(it.kind == nnkFormalParams)
    for param in formalParams.children:
        if param.kind == nnkIdentDefs:
            result.add(param)

proc encodeQueryParams(paramsToEncode: seq[NimNode]): NimNode =
    result = newNimNode(nnkStmtList)
    for param in paramsToEncode:
        let paramIdent = param[0]
        let paramName = newStrLitNode(paramIdent.strVal)
        let paramStringIdent = ident(paramIdent.strVal & "Param")
        result.add(quote do:
            let `paramStringIdent` = `paramName` & "=" & encodeParam(`paramIdent`)
        )

proc buildLinkerFn(path: string, renderProc: NimNode, router: NimNode): NimNode =
    let paramIdents = getParamIdents(renderProc)
    let paramsToEncode = paramIdents.filterIt(it[1].strVal notin ["Request", "Response"])
    let callParams = paramsToEncode.mapIt(ident(it[0].strVal & "Param"))
    let pathNode = newStrLitNode("/" & path)
    let queryString = newCall(ident("buildQueryString"), callParams)
    var body = encodeQueryParams(paramsToEncode)
    body.add(quote do: `router`.componentPath & `pathNode` & `queryString`) 
    var procParams = concat(@[ident("string")], paramIdents)
    result = newProc(getLinkerProc(), procParams, body)
    result.addPragma(ident("gcsafe"))

proc buildComponentTuple(): NimNode =
    let renderSym = getRenderProc()
    let linkerSym = getLinkerProc()
    let routeSym = getRouteObj()
    result = quote do:
        (render: `renderSym`, linker: `linkerSym`, route: `routeSym`)

proc buildRenderProc(path: string, renderProc: NimNode): NimNode =
    var procDef = newNimNode(nnkProcDef)
    copyChildrenTo(renderProc, procDef)
    var oldBody = renderProc[6]
    let scope = ident("scope")
    let scopeName = newStrLitNode(path)
    var body = newStmtList(quote do:
        var `scope` = newScope(`scopeName`)
    )
    copyChildrenTo(oldBody, body)
    procDef.addPragma(ident("gcsafe"))
    procDef[6] = body
    procDef[0] = getRenderProc()
    result = procDef

proc buildComponent(router: NimNode, isPage: bool, body: NimNode): NimNode =
    let path = getPath(body)
    let renderStmt = body.findChild(it.kind == nnkAsgn and it[0].strVal == "render")
    if renderStmt == nil:
        raise newCompileError("Component is missing render proc")
    let suppressWarning = quote do:
        {.push warning[GcUnsafe2]: off.}
    let enableWarning = quote do:
        {.push warning[GcUnsafe2]: on.}
    let renderProc = buildRenderProc(path, renderStmt[1])
    var blockStatements = newStmtList()
    blockStatements.add(suppressWarning)
    blockStatements.add(buildLinkerFn(path, renderProc, router))
    blockStatements.add(renderProc)
    blockStatements.add(buildRouteFn(renderProc))
    blockStatements.add(buildRoute(path, isPage, router))
    blockStatements.add(enableWarning)
    blockStatements.add(buildComponentTuple())
    result = newBlockStmt(blockStatements)

macro component*(body: untyped): untyped = buildComponent(ident("router"), false, body)

macro component*(router: untyped, body: untyped): untyped = buildComponent(router, false, body)

macro page*(body: untyped): untyped = buildComponent(ident("router"), true, body)

macro page*(router: untyped, body: untyped): untyped = buildComponent(router, true, body)

export runtime, json, router
