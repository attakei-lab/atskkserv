## パッケージ自身のメタ情報を提供するモジュール。
##
## バージョンは ``.nimble`` を唯一の定義元とし、実行ファイルへ埋め込む。

import std/strutils

const NimblePkgVersion* {.strdefine.} = ""
  ## nimble がビルド時に ``-d:NimblePkgVersion=...`` として渡す値。
  ## nimble を経由しない ``nim c`` では空になる。

const FallbackVersion* = "0.0.0"
  ## ``.nimble`` からバージョンを読み取れなかった場合に使う値。

proc parseNimbleVersion*(content: string): string =
  ## ``.nimble`` の内容から ``version`` の値を取り出す。
  for line in content.splitLines:
    let trimmed = line.strip()
    let separator = trimmed.find('=')
    if separator < 0:
      continue
    # ``versionSomething`` のような別のキーを拾わないよう、
    # 左辺が ``version`` そのものである場合に限る。
    if trimmed[0 ..< separator].strip() != "version":
      continue
    let value = trimmed[separator + 1 ..^ 1].strip()
    if value.len < 2 or value[0] != '"':
      continue
    let closing = value.find('"', 1)
    if closing < 0:
      continue
    return value[1 ..< closing]
  return ""

when NimblePkgVersion.len > 0:
  const AppVersion* = NimblePkgVersion
    ## 実行ファイルへ埋め込むバージョン。
else:
  # nimble を経由しないビルドでも値がずれないよう、``.nimble`` を直接読む。
  const ParsedVersion = parseNimbleVersion(staticRead("../../atskkserv.nimble"))
  const AppVersion* = if ParsedVersion.len > 0: ParsedVersion else: FallbackVersion
