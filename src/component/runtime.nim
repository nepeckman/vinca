import uri, strutils, sequtils, json

proc parseQueryParams*(path: string): seq[(string, string)] =
    let pathParts = path.split("?")
    if pathParts.len < 2 or pathParts[1].len == 0:
        return
    toSeq(decodeQuery(pathParts[1]))

proc getParam*(params: seq[(string, string)], name: string): string =
    for param in params:
        if param[0] == name:
            return param[1]

proc encodeParam*[T](obj: T): string = encodeUrl($ (% obj))

proc buildQueryString*(params: varargs[string]): string =
    if params.len == 0:
        return ""
    for param in params:
        if result == "":
            result = "?" & param
        else:
            result = result & "&" & param