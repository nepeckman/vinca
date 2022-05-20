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
        proc `route`(`req`: Request, `res`: Response): VNode =
            let `parsedQueryParams` = parseQueryParams(`req`.path)
            `call`

proc buildRoute(path: string, router: NimNode): NimNode =
    let route = getRouteObj()
    let routeFn = getRouteProc()
    let pathNode = newStrLitNode("/" & path)
    result = quote do:
        let `route` = newComponentRoute(`pathNode`, `routeFn`)
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

proc buildComponentTuple(): NimNode =
    let renderSym = getRenderProc()
    let linkerSym = getLinkerProc()
    let routeSym = getRouteObj()
    result = quote do:
        (render: `renderSym`, linker: `linkerSym`, route: `routeSym`)

proc updateRenderProc(path: string, comp: NimNode) =
    var oldBody = comp[6]
    let scope = ident("scope")
    let scopeName = newStrLitNode(path)
    var body = newStmtList(quote do:
        var `scope` = newScope(`scopeName`)
    )
    copyChildrenTo(oldBody, body)
    comp[6] = body
    comp[0] = getRenderProc()

proc buildComponent(router: NimNode, body: NimNode): NimNode =
    echo treerepr body
    let path = getPath(body)
    var blockStatements = newStmtList()
    let renderProc = body.findChild(it.kind == nnkProcDef and it[0].strVal == "render")
    if renderProc == nil:
        raise newCompileError("Component is missing render proc")
    updateRenderProc(path, renderProc)
    blockStatements.add(renderProc)
    blockStatements.add(buildRouteFn(renderProc))
    blockStatements.add(buildLinkerFn(path, renderProc, router))
    blockStatements.add(buildRoute(path, router))
    blockStatements.add(buildComponentTuple())
    result = newBlockStmt(blockStatements)
    echo repr result

macro component*(body: untyped): untyped = buildComponent(ident("router"), body)

macro component*(router: untyped, body: untyped): untyped = buildComponent(router, body)

export runtime

when isMainModule:
    import karax/karaxdsl, karax/vdom

    type Foo = ref object
        val: string

    let helloComponent = component():
        path = "asdf"
        proc render(foo: Foo, req: Request): VNode =
            buildHtml(tdiv):
                span(): text foo.val
        linker = proc (foo: Foo, req: Request): string = ""
