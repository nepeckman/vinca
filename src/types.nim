
type CompileError* = ref object of Defect
## TODO replace with macro error
proc newCompileError*(message: string): CompileError = CompileError(msg: message)

type ParseError* = ref object of CatchableError
proc newParseError*(message: string): ParseError = ParseError(msg: message)