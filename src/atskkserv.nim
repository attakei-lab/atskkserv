## メイン処理の実行と、それにのみ付随する処理
import std/asyncdispatch
import chronicles
import confutils

import ./atskkserv/server
import ./atskkserv/vendor/chronicles_utils

type AppConf = object
  serverHost {.name: "server-host", defaultValue: "127.0.0.1", desc: "Listen address".}:
    string
  serverPort {.name: "server-port", defaultValue: 1178, desc: "Listen port number".}:
    int
  logLevel {.name: "log-level", defaultValue: "NOTICE", desc: "Logging level".}: string

proc handleInterrupt() {.noconv.} =
  ## Ctrl-C (SIGINT) を捕捉して全接続を切断してから終了する
  notice "Caught interrupt signal"
  info "Closing all connections"
  closeAllClients()
  quit(0)

when isMainModule:
  let appConf = AppConf.load()
  setLogLevel(appConf.logLevel)
  setControlCHook(handleInterrupt)
  asyncCheck serve(appConf.serverHost, appConf.serverPort)
  runForever()
