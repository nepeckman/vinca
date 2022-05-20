import macros, strutils, tables

var filecache {.compiletime.} = initTable[string, string]()

type Path* = object
    base*: string
    params*: seq[tuple[pos: int, name: string]]

proc getFile(filename: string): string {.compiletime.} = 
    if filecache.hasKey(filename):
        filecache[filename]
    else:
        let file = staticRead(filename)
        filecache[filename] = file
        file

proc getImplicitPath*(body: NimNode): Path =
    let line = lineInfoObj(body)
    let lineParts = line.filename.split("/")
    let file = getFile(line.filename)
    let declaration = file.splitLines()[line.line - 2].substr(line.column + 1)
    let compName = declaration.splitWhitespace()[0]
    let modName = lineParts[lineParts.len - 1].split(".")[0]
    result = Path(base: modName & "-" & compName)

proc parseParams(path: string): seq[tuple[pos: int, name: string]] {.compiletime.} =
    let pathParts = path.split("/")
    for idx in 0..pathParts.high:
        let part = pathParts[idx]
        if part.startsWith("@"):
            result.add((pos: idx, name: part.substr(1)))

proc getBasePath(path: string): string {.compiletime.} =
    let pathParts = path.split("/")
    result = pathParts[0]
    for idx in 1..pathParts.high:
        let part = pathParts[idx]
        if not part.startsWith("@"):
            result = result & "/" & part


proc hasParam*(path: Path, param: string): bool {.compiletime.} =
    result = false
    for p in path.params:
        if p.name == param:
            result = true

proc getParam*(path: Path, param: string): tuple[pos: int, name: string] {.compiletime.} =
    result = (pos: 0, name: "")
    for p in path.params:
        if p.name == param:
            result = p

proc getPath*(body: NimNode): Path =
    let explicitPath = body.findChild(it.kind == nnkAsgn and it[0].strVal == "path")
    if explicitPath.kind != nnkNilLit: 
        let path = explicitPath[1].strVal
        Path(base: getBasePath(path), params: parseParams(path))
    else: getImplicitPath(body)