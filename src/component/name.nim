import macros, strutils, tables

var filecache {.compiletime.} = initTable[string, string]()

proc getFile(filename: string): string {.compiletime.} = 
    if filecache.hasKey(filename):
        filecache[filename]
    else:
        let file = staticRead(filename)
        filecache[filename] = file
        file

proc getImplicitPath*(body: NimNode): string =
    let line = lineInfoObj(body)
    let lineParts = line.filename.split("/")
    let file = getFile(line.filename)
    let declaration = file.splitLines()[line.line - 2].substr(line.column + 1)
    let compName = declaration.splitWhitespace()[0]
    let modName = lineParts[lineParts.len - 1].split(".")[0]
    result = modName & "-" & compName

proc getPath*(body: NimNode): string =
    let explicitPath = body.findChild(it.kind == nnkAsgn and it[0].strVal == "path")
    if explicitPath.kind != nnkNilLit: explicitPath[1].strVal
    else: getImplicitPath(body)