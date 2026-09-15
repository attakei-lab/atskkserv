type
  CommandCode* = enum
    ## SKKクライアントの要求コマンド
    END = 0
    REQUEST = 1
    VERSION = 2
    HOST = 3

  Command* = object
    code*: CommandCode

proc newCommand*(code: CommandCode): Command =
  result = Command(code: code)
