import tables, typeinfo, strutils
import types

proc parseBody*(body: string): Table[string, string] =
    for line in body.splitLines():
        if line == "": continue
        let parts = line.split("=")
        try:
            result[parts[0]]= parts[1]
        except:
            raise newParseError("Parsing error in multiline form line: " & line)

proc marshall*[T](body: Table[string, string]): T =
    var obj = T()
    var a = obj.toAny()
    for key, value in fields(a):
        var val =
            try: body[key]
            except: raise newParseError("Request is missing field '" & key & "' for object type '" & $typeof(obj) & "'")
        try:
            a[key] = val.toAny
        except:
            raise newParseError("Error setting field '" & key & "' (type: " & $a[key].kind & ") with value '" & $val & "' (type: " & $val.toAny.kind & ") for object type '" & $typeof(obj) & "'")
    result = obj

proc parseQueryParams*(path: string): Table[string, string] =
    let pathParts = path.split("?")
    if pathParts.len < 2 or pathParts[1].len == 0:
        return
    let queryParts = pathParts[1].split("&")
    for param in queryParts:
        let paramParts = param.split("=")
        let key = paramParts[0]
        let value = if paramParts.len == 1: "" else: paramParts[1]
        result[key] = value

proc buildQueryString*(params: varargs[string]): string =
    if params.len == 0:
        return ""
    for param in params:
        if result == "":
            result = "?" & param
        else:
            result = result & "&" & param
