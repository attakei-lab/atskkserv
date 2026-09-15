## メイン処理の実行と、それにのみ付随する処理
import std/asyncdispatch
import confutils

import ./atskkserv/cli
import ./atskkserv/commands/serve

type
  Command = enum
    serve = "Run as SKK dictionary server"

  AppConf = object
    globalOpts {.flatten.}: GlobalOptions
    case command {.command, defaultValue: Command.serve.}: Command
    of Command.serve:
      serveOpts {.flatten.}: ServeOptions

when isMainModule:
  let appConf = AppConf.load()
  init(appConf.globalOpts)

  case appConf.command
  of Command.serve:
    waitFor execServe(appConf.serveOpts)
