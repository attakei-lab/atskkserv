# begin Nimble config (version 2)
when withDir(thisDir(), system.fileExists("nimble.paths")):
  include "nimble.paths"
# end Nimble config

# ロギングの初期設定と、実行時調整の有効化
switch("define", "chronicles_log_level:DEBUG")
switch("define", "chronicles_runtime_filtering:on")

when defined(release):
  switch("passL", "-s")
