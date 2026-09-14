## メイン処理の実行と、それにのみ付随する処理
import std/asyncdispatch

import ./atskkserv/server

when isMainModule:
  asyncCheck serve(11178)
  runForever()
