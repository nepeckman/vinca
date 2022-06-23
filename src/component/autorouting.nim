import macros

var componentRoutes* {.compiletime.}: seq[NimNode]
var pageRoutes* {.compiletime.}: seq[NimNode]

proc getInitializerName*(compName: NimNode): NimNode = ident("init" & compName.strVal)

macro autoRoute*(router: untyped): untyped =
    result = newStmtList()
    for comp in componentRoutes:
        let initializer = getInitializerName(comp)
        result.add(quote do:
            `initializer`(`router`)
            `router`.addComponent(`comp`.route))
    for page in pageRoutes:
        let initializer = getInitializerName(page)
        result.add(quote do:
            `initializer`(`router`)
            `router`.addPage(`page`.route))
    