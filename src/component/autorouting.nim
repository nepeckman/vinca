import macros

var componentRoutes* {.compiletime.}: seq[NimNode]
var pageRoutes* {.compiletime.}: seq[NimNode]

macro autoRoute*(router: untyped): untyped =
    result = newStmtList()
    for comp in componentRoutes:
        result.add(quote do:
            `router`.addComponent(`comp`.route))
    for page in pageRoutes:
        result.add(quote do:
            `router`.addPage(`page`.route))
    