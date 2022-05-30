import strutils, sequtils

type
  AjaxParamKind* = enum apkAll, apkNone, apkList, apkNotList
  AjaxParam* = ref object
    case kind: AjaxParamKind
    of apkList, apkNotList: params: seq[string]
    else: discard

proc allParams*(): AjaxParam = AjaxParam(kind: apkAll)
proc noParams*(): AjaxParam = AjaxParam(kind: apkNone)
proc paramList*(params: varargs[string]): AjaxParam = AjaxParam(kind: apkList, params: params.toSeq())
proc excludeParams*(params: varargs[string]): AjaxParam = AjaxParam(kind: apkNotList, params: params.toSeq())

proc `$`*(param: AjaxParam): string =
  if param == nil: ""
  else:
    case param.kind:
      of apkAll: "*"
      of apkNone: "none"
      of apkList: param.params.join(", ")
      of apkNotList: "not" & param.params.join(", ")