import macros

type
    ComponentParamKind* = enum cpkQuery, cpkPath, cpkRequest, cpkResponse
    ComponentParam* = ref object
        kind*: ComponentParamKind
        name*: string
        typeName*: string

proc getComponentParams*(renderProc: NimNode): seq[ComponentParam] =
    let formalParams = renderProc.findChild(it.kind == nnkFormalParams)
    for param in formalParams.children:
        if param.kind == nnkIdentDefs:
            let kind = case param[1].strVal
                of "Request": cpkRequest
                of "Response": cpkResponse
                else: cpkQuery
            result.add(ComponentParam(name: param[0].strVal, typeName: param[1].strVal, kind: kind))