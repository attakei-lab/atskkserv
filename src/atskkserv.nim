## メイン処理の実行と、それにのみ付随する処理
import std/asyncdispatch
import confutils

import ./atskkserv/server

type AppConf = object
  serverHost {.name: "server-host", defaultValue: "127.0.0.1", desc: "Listen address".}:
    string
  serverPort {.name: "server-port", defaultValue: 1178, desc: "Listen port number".}:
    int

proc handleInterrupt() {.noconv.} =
  ## Ctrl-C (SIGINT) を捕捉して全接続を切断してから終了する
  echo("\nCaught interrupt signal. Closing all connections...")
  closeAllClients()
  quit(0)

when isMainModule:
  let appConf = AppConf.load()
  setControlCHook(handleInterrupt)
  asyncCheck serve(appConf.serverHost, appConf.serverPort)
  runForever()
