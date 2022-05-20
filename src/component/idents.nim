import macros

func getRouteProc*(): NimNode = ident("routeProc")

func getRouteObj*(): NimNode = ident("route")

func getLinkerProc*(): NimNode = ident("linker")

func getRenderProc*(): NimNode = ident("render")