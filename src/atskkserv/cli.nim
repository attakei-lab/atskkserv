## CLI共通処理など
import confutils

import ./vendor/chronicles_utils

type GlobalOptions* = object
  logLevel* {.name: "log-level", defaultValue: "NOTICE", desc: "Logging level".}: string

proc init*(gOpts: GlobalOptions) =
  ## 共通オプションに関わる共通処理の実行
  setLogLevel(gOpts.logLevel)
