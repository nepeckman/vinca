import httpcore, httpbeast, tables, options

type HttpBeastRequest* = httpbeast.Request

type Request* = ref object
  path*: string
  httpMethod*: HttpMethod
  headers*: HttpHeaders
  body*: string

type Response* = ref object
  statusCode*: HttpCode
  headers*: HttpHeaders
  body*: string

proc toString*(headers: HttpHeaders): string =
    result = ""
    for key, val in headers.table.pairs:
        result = result & key & ": " & val[0] & "\c\L"

proc buildRequest*(req: HttpBeastRequest): Request =  
    result = Request()
    result.path = req.path.get("")
    result.httpMethod = req.httpMethod.get(HttpGet)
    result.headers = req.headers.get(newHttpHeaders())

export httpcore
export send, run