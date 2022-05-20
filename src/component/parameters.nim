import macros
import path

type
    ComponentParamKind* = enum cpkQuery, cpkPath, cpkRequest, cpkResponse
    ComponentParam* = ref object
        kind*: ComponentParamKind
        name*: string
        typeName*: string
        pathPosition*: int

proc getComponentParams*(renderProc: NimNode, path: Path): seq[ComponentParam] =
    let formalParams = renderProc.findChild(it.kind == nnkFormalParams)
    for param in formalParams.children:
        if param.kind == nnkIdentDefs:
            let name = param[0].strVal
            let typeName = param[1].strVal
            let kind = case typeName
                of "Request": cpkRequest
                of "Response": cpkResponse
                else:
                    if path.hasParam(name): cpkPath
                    else: cpkQuery
            let position = if kind == cpkPath: path.getParam(name).pos else: 0
            result.add(ComponentParam(name: name, typeName: typeName, kind: kind, pathPosition: position))