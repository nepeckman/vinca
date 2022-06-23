import macros, sequtils
import path, idents

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

proc getComponentBasePath*(): NimNode = ident("componentBasePath")

proc generateLinkerProc*(path: Path, isPage: bool, renderProc: NimNode): NimNode =
    let paramIdents = getParamIdents(renderProc)
    let pathParams = paramIdents.filterIt(path.hasParam(it[0].strVal)).mapIt(it[0])
    let queryParams = paramIdents.filterIt(it[1].strVal notin ["Request", "Response"] and (not path.hasParam(it[0].strVal)))
    let pathNode = newStrLitNode("/" & path.base)
    var body = encodeQueryParams(queryParams)
    let encodedQueryParams = queryParams.mapIt(ident(it[0].strVal & "Param"))
    let pathParamString = newCall(ident("buildPathParams"), pathParams)
    let queryString = newCall(ident("buildQueryString"), encodedQueryParams)
    let base = if isPage: newStrLitNode("") else: getComponentBasePath()
    body.add(quote do: `base` & `pathNode` & `pathParamString` & `queryString`) 
    var procParams = concat(@[ident("string")], paramIdents)
    result = newProc(getLinkerProc(), procParams, body)
    result.addPragma(ident("closure"))
    result.addPragma(ident("gcsafe"))