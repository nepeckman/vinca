import macros, strutils, sequtils
import server, types, parsers, selector

import json

func getRouteProc(): NimNode = ident("vincaProcRoute")

func getRouteObj(): NimNode = ident("vincaRoute")

func getLinkerProc(): NimNode = ident("vincaProcLinker")

func getRenderProc(): NimNode = ident("vincaProcRender")

type
    ComponentParamKind = enum cpkQuery, cpkPath, cpkRequest, cpkResponse
    ComponentParam = ref object
        kind: ComponentParamKind
        name: string
        typeName: string
    
proc getScopedName(body: NimNode): string =
    let line = lineInfoObj(body)
    let lineParts = line.filename.split("/")
    let declaration = staticRead(line.filename).splitLines()[line.line - 2].substr(line.column)
    let compName = declaration.splitWhitespace()[0]
    let modName = lineParts[lineParts.len - 1].split(".")[0]
    result = modName & "-" & compName

proc getComponentParams(renderProc: NimNode): seq[ComponentParam] =
    let formalParams = renderProc.findChild(it.kind == nnkFormalParams)
    for param in formalParams.children:
        if param.kind == nnkIdentDefs:
            let kind = case param[1].strVal
                of "Request": cpkRequest
                of "Response": cpkResponse
                else: cpkQuery
            result.add(ComponentParam(name: param[0].strVal, typeName: param[1].strVal, kind: kind))

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
        proc `route`(`req`: Request, `res`: Response): VNode =
            let `parsedQueryParams` = parseQueryParams(`req`.path)
            `call`

proc buildRoute(name: string, router: NimNode): NimNode =
    let route = getRouteObj()
    let routeFn = getRouteProc()
    let path = newStrLitNode("/" & name)
    result = quote do:
        let `route` = newComponentRoute(`path`, `routeFn`)
        `router`.addComponent(`route`)

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

proc buildLinkerFn(name: string, renderProc: NimNode): NimNode =
    let paramIdents = getParamIdents(renderProc)
    let paramsToEncode = paramIdents.filterIt(it[1].strVal notin ["Request", "Response"])
    let callParams = paramsToEncode.mapIt(ident(it[0].strVal & "Param"))
    let path = newStrLitNode("/" & name)
    let queryString = newCall(ident("buildQueryString"), callParams)
    var body = encodeQueryParams(paramsToEncode)
    body.add(quote do: `path` & `queryString`) 
    var procParams = concat(@[ident("string")], paramIdents)
    result = newProc(getLinkerProc(), procParams, body)

proc buildComponentTuple(): NimNode =
    let renderSym = getRenderProc()
    let linkerSym = getLinkerProc()
    let routeSym = getRouteObj()
    result = quote do:
        (render: `renderSym`, linker: `linkerSym`, route: `routeSym`)

proc updateRenderProc(name: string, comp: NimNode) =
    var oldBody = comp[6]
    let scope = ident("scope")
    let scopeName = newStrLitNode(name)
    var body = newStmtList(quote do:
        var `scope` = newScope(`scopeName`)
    )
    copyChildrenTo(oldBody, body)
    comp[6] = body
    comp[0] = getRenderProc()

proc buildComponent(router: NimNode, body: NimNode): NimNode =
    let name = getScopedName(body)
    var blockStatements = newStmtList()
    let renderProc = body.findChild(it.kind == nnkProcDef and it[0].strVal == "render")
    if renderProc == nil:
        raise newCompileError("Component is missing render proc")
    updateRenderProc(name, renderProc)
    blockStatements.add(renderProc)
    blockStatements.add(buildRouteFn(renderProc))
    blockStatements.add(buildLinkerFn(name, renderProc))
    blockStatements.add(buildRoute(name, router))
    blockStatements.add(buildComponentTuple())
    result = newBlockStmt(blockStatements)
    echo repr result

macro component*(body: untyped): untyped = buildComponent(ident("router"), body)

macro component*(router: untyped, body: untyped): untyped = buildComponent(router, body)

when isMainModule:
    import karax/karaxdsl, karax/vdom

    type Foo = ref object
        val: string

    let helloComponent = component():
        proc render(foo: Foo, req: Request): VNode =
            buildHtml(tdiv):
                span(): text foo.val
