## サーバーモードの起動と、それにのみ付随する処理
import std/asyncdispatch
import chronicles
import confutils

import ../engine
import ../server

type ServeOptions* = object
  serverHost* {.name: "server-host", defaultValue: "127.0.0.1", desc: "Listen address".}:
    string
  serverPort* {.name: "server-port", defaultValue: 1178, desc: "Listen port number".}:
    int
  localDictionary* {.
    argument, defaultValue: "./SKK-JISYO.utf8", desc: "Using dictionary path"
  .}: string

proc handleInterrupt() {.noconv.} =
  ## Ctrl-C (SIGINT) を捕捉して全接続を切断してから終了する
  notice "Caught interrupt signal"
  info "Closing all connections"
  closeAllClients()
  closeSearchEngine()
  quit(0)

proc execServe*(cOpts: ServeOptions) {.async.} =
  setControlCHook(handleInterrupt)
  let engine = initSearchEngine(cOpts.localDictionary)
  asyncCheck serve(engine, cOpts.serverHost, cOpts.serverPort)
  runForever()
