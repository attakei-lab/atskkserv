## メイン処理の実行と、それにのみ付随する処理
import std/asyncdispatch
import confutils

import ./atskkserv/cli
import ./atskkserv/meta
import ./atskkserv/commands/build
import ./atskkserv/commands/serve

type
  Command = enum
    serve = "Run as SKK dictionary server"
    build = "Build SKK dictionary from some sources"

  AppConf = object
    globalOpts {.flatten.}: GlobalOptions
    case command {.command, defaultValue: Command.serve.}: Command
    of Command.serve:
      serveOpts {.flatten.}: ServeOptions
    of Command.build:
      buildOpts {.flatten.}: BuildOptions

when isMainModule:
  let appConf = AppConf.load(version = AppVersion)
  init(appConf.globalOpts)

  case appConf.command
  of Command.serve:
    waitFor execServe(appConf.serveOpts)
  of Command.build:
    execBuild(appConf.buildOpts)
