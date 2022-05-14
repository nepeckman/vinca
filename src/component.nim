import macros, httpcore, options, tables
import server, types, parsers, selector

import json, uri

func getComponentRenderName(name: string): NimNode = ident("vincaProc" & name & "Render")

func getComponentLinkerName(name: string): NimNode = ident("vincaProc" & name & "Linker")

func getComponentRouteName(name: string): NimNode = ident("vincaVar" & name & "Route")

func getComponentIndicatorName(name: string): NimNode = ident("vincaConst" & name & "Indicator")

func buildComponentIndicator(name: string): NimNode =
    let indicator = getComponentIndicatorName(name)
    result = quote do:
        const `indicator` = true

type ComponentParamKind = enum cpkQuery, cpkPath, cpkRequest, cpkResponse

type ComponentParam = ref object
  kind: ComponentParamKind
  name: string
  typeName: string

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
            let converterFn = ident("parse" & param.typeName)
            let typeIdent = ident(param.typeName)
            result.add(quote do: 
                parseJson(`parsedParamIdent`.getParam(`nameString`)).to(`typeIdent`)
            )
        elif param.kind == cpkRequest:
            result.add(ident("req"))
        elif param.kind == cpkResponse:
            result.add(ident("res"))

proc buildComponentRender(comp: NimNode): NimNode =
    let component = comp.findChild(it.kind == nnkIdent)
    let render = getComponentRenderName(component.strVal)
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
        proc `render`(`req`: Request, `res`: Response): VNode =
            let `parsedQueryParams` = parseQueryParams(`req`.path)
            `call`

proc buildComponentRoute(name: string): NimNode =
    let route = getComponentRouteName(name)
    let render = getComponentRenderName(name)
    let path = newStrLitNode("/" & name)
    result = quote do:
        let `route` = newRoute(`path`, `render`)
        router.components.add(`route`)

proc buildComponentLinker(comp: NimNode): NimNode =
    let component = comp.findChild(it.kind == nnkIdent)
    let linker = getComponentLinkerName(component.strVal)
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
                let paramTypeName = newStrLitNode(param[1].strVal)
                let paramName = newStrLitNode(paramIdent.strVal)
                let paramStringIdent = ident(paramIdent.strVal & "Param")
                body.add(quote do:
                    let `paramStringIdent` = `paramName` & "=" & encodeParam(`paramIdent`)
                )
                callParams.add(paramStringIdent)
    let path = newStrLitNode("/" & component.strVal)
    let call = newCall(ident("buildQueryString"), callParams)
    body.add(quote do: `path` & `call`) 
    result = newProc(linker, params, body)

proc addScopeToProc(comp: NimNode) =
    let name = comp.findChild(it.kind == nnkIdent).strVal
    var oldBody = comp[6]
    let scope = ident("scope")
    let scopeName = newStrLitNode(name)
    var body = newStmtList(quote do:
        var `scope` = newScope(`scopeName`)
    )
    copyChildrenTo(oldBody, body)
    comp[6] = body
    
proc buildComponent(comp: NimNode): NimNode =
    let component = comp.findChild(it.kind == nnkIdent)
    let name = component.strVal
    result = newNimNode(nnkStmtList)
    result.add(comp)
    result.add(buildComponentIndicator(name))
    result.add(buildComponentRender(comp))
    #result.add(buildComponentRoute(name))
    result.add(buildComponentLinker(comp))
    addScopeToProc(comp)
    echo repr result

macro component(comp: untyped): untyped = buildComponent(comp)

import converters
export converters

when isMainModule:
    import karax/karaxdsl, karax/vdom

    type Foo = ref object
        val: string
    
    proc parseFoo(str: string): Foo = Foo(val: str)

    proc `$`(foo: Foo): string = foo.val

    proc helloComponent(foo: Foo, bar: int, req: Request): VNode {.component.} =
        let id = scope.newIdSelector("foo")
        result = buildHtml(tdiv):
            span(): text foo.val
    
    serve()

    when not compiles(vincaConsthelloComponentIndicator):
        static:
            let error = CompileError()
            error.msg = "Foo is not a component"
            raise error