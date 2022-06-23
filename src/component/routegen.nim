import macros
import path, parameters, idents

proc buildRenderCall(parsedQueryParams: NimNode, parsedPathParams: NimNode, params: seq[ComponentParam]): NimNode =
    result = newNimNode(nnkCall)
    result.add(getRenderProc())
    for param in params:
        case param.kind
        of cpkQuery:
            let nameString = newStrLitNode(param.name)
            let typeIdent = ident(param.typeName)
            result.add(quote do: 
                parseJson(`parsedQueryParams`.getParam(`nameString`)).to(`typeIdent`)
            )
        of cpkPath:
            let position = newStrLitNode($param.pathPosition)
            result.add(quote do:
                `parsedPathParams`.getParam(`position`)
            )
        of cpkRequest:
            result.add(ident("req"))
        of cpkResponse:
            result.add(ident("res"))

proc buildParsePath(path: Path): NimNode =
    result = newNimNode(nnkCall)
    result.add(ident("parsePathParams"))
    let req = ident("req")
    result.add(quote do: `req`.path)
    for param in path.params:
        result.add(newIntLitNode(param.pos))

proc generateRouteProc*(path: Path, renderProc: NimNode): NimNode =
    let params = getComponentParams(renderProc, path)
    let route = getRouteProc()
    let parsedQueryParams = ident("parsedQueryParams")
    let parsedPathParams = ident("parsedPathParams")
    let req = ident("req")
    let res = ident("res")
    let call = buildRenderCall(parsedQueryParams, parsedPathParams, params)
    let parsePathCall = buildParsePath(path)
    result = quote do:
        proc `route`(`req`: Request, `res`: Response): VNode {.gcsafe.} =
            let `parsedQueryParams` = parseQueryParams(`req`.path)
            let `parsedPathParams` = `parsePathCall`
            `call`

proc generateRouteObj*(path: Path): NimNode =
    let route = getRouteObj()
    let routeFn = getRouteProc()
    let pathNode = newStrLitNode("/" & path.base)
    result = quote do:
        let `route` = newComponentRoute(`pathNode`, `routeFn`)