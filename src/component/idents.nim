import macros

func getRouteProc*(): NimNode = ident("vincaProcRoute")

func getRouteObj*(): NimNode = ident("vincaRoute")

func getLinkerProc*(): NimNode = ident("vincaProcLinker")

func getRenderProc*(): NimNode = ident("vincaProcRender")