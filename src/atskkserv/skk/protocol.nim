type
  CommandCode* = enum
    ## SKKクライアントの要求コマンド
    END = 0
    REQUEST = 1
    VERSION = 2
    HOST = 3

  Command* = object
    case code*: CommandCode
    of CommandCode.REQUEST:
      body*: string
    else:
      discard

  LookupCode* = enum
    FOUND = "1"
    NOT_FOUND = "4"

proc newCommand*(code: CommandCode): Command =
  result = Command(code: code)
