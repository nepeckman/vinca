import karax/vdom

type NodeModifier* = proc (node: VNode) {.gcSafe.}

type CompileError* = ref object of Defect
proc newCompileError*(message: string): CompileError = CompileError(msg: message)

type ParseError* = ref object of CatchableError
proc newParseError*(message: string): ParseError = ParseError(msg: message)

export vdom