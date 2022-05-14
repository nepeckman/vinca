import macros, strutils
import server, types, parsers, selector

import json, uri

func getRouteProc(): NimNode = ident("vincaProcRoute")

func getRouteObj(): NimNode = ident("vincaRoute")

func getLinkerProc(): NimNode = ident("vincaProcLinker")

func getRenderProc(): NimNode = ident("vincaProcRender")

type ComponentParamKind = enum cpkQuery, cpkPath, cpkRequest, cpkResponse

type ComponentParam = ref object
  kind: ComponentParamKind
  name: string
  typeName: string
    
proc getScopedName(body: NimNode): string =
    let lineParts = lineInfo(body).split("/")
    let filename = lineInfo(body).split("(")[0]
    let location = lineInfo(body).split("(")[1].split(")")[0]
    let row = location.split(",")[0].strip().parseInt
    let col = location.split(",")[1].strip().parseInt
    let declaration = staticRead(filename).splitLines()[row - 2].substr(col)
    let compName = declaration.splitWhitespace()[0]
    let modName = lineParts[lineParts.len - 1].split(".")[0]
    result = modName & "-" & compName

proc getParam(params: seq[(string, string)], name: string): string =
    for param in params:
        if param[0] == name:
            return param[1]

proc buildComponentCall(component: NimNode, parsedParamIdent: NimNode, params: seq[ComponentParam]): NimNode =
    result = newNimNode(nnkCall)
    result.add(component)
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

proc buildComponentRouteFn(comp: NimNode): NimNode =
    let component = comp.findChild(it.kind == nnkIdent)
    let route = getRouteProc()
    let formalParams = comp.findChild(it.kind == nnkFormalParams)
    var params: seq[ComponentParam]
    for param in formalParams.children:
        if param.kind == nnkIdentDefs:
            let kind = case param[1].strVal
                of "Request": cpkRequest
                of "Response": cpkResponse
                else: cpkQuery
            params.add(ComponentParam(name: param[0].strVal, typeName: param[1].strVal, kind: kind))
    let parsedQueryParams = ident("parsedQueryParams")
    let req = ident("req")
    let res = ident("res")
    let call = buildComponentCall(component, parsedQueryParams, params)
    result = quote do:
        proc `route`(`req`: Request, `res`: Response): VNode =
            let `parsedQueryParams` = parseQueryParams(`req`.path)
            `call`

proc buildComponentRoute(name: string): NimNode =
    let route = getRouteObj()
    let routeFn = getRouteProc()
    let path = newStrLitNode("/" & name)
    result = quote do:
        let `route` = newComponentRoute(`path`, `routeFn`)
        router.addComponent(`route`)

proc buildComponentLinker(name: string, comp: NimNode): NimNode =
    let formalParams = comp.findChild(it.kind == nnkFormalParams)
    var params: seq[NimNode]
    params.add(ident("string"))
    var body = newNimNode(nnkStmtList)
    var callParams: seq[NimNode]
    for param in formalParams.children:
        if param.kind == nnkIdentDefs:
            params.add(param)
            if param[1].strVal notin ["Request", "Response"]:
                let paramIdent = param[0]
                let paramName = newStrLitNode(paramIdent.strVal)
                let paramStringIdent = ident(paramIdent.strVal & "Param")
                body.add(quote do:
                    let `paramStringIdent` = `paramName` & "=" & encodeParam(`paramIdent`)
                )
                callParams.add(paramStringIdent)
    let path = newStrLitNode("/" & name)
    let call = newCall(ident("buildQueryString"), callParams)
    body.add(quote do: `path` & `call`) 
    result = newProc(getLinkerProc(), params, body)

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

proc buildComponent(body: NimNode): NimNode =
    let name = getScopedName(body)
    var blockStatements = newStmtList()
    let renderProc = body.findChild(it.kind == nnkProcDef and it[0].strVal == "render")
    if renderProc == nil:
        result = quote do:
            static:
                raise newCompileError("Component is missing render proc")
        return
    updateRenderProc(name, renderProc)
    blockStatements.add(renderProc)
    blockStatements.add(buildComponentRouteFn(renderProc))
    blockStatements.add(buildComponentLinker(name, renderProc))
    blockStatements.add(buildComponentRoute(name))
    let renderSym = getRenderProc()
    let linkerSym = getLinkerProc()
    let routeSym = getRouteObj()
    blockStatements.add(quote do:
        (render: `renderSym`, linker: `linkerSym`, route: `routeSym`)
    )
    result = newBlockStmt(blockStatements)
    echo repr result

macro component(body: untyped): untyped = buildComponent(body)

when isMainModule:
    import karax/karaxdsl, karax/vdom

    type Foo = ref object
        val: string

    let helloComponent = component():
        proc render(): VNode =
            buildHtml(tdiv):
                span(): text "abc"

    discard helloComponent 