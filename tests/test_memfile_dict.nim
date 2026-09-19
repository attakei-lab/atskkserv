## `skk/memfile_dict` の契約を固定化するテスト。
##
## 「なにができるはず」「なにができないはず」を明示することが目的で、
## E系（契約違反入力）はバグ再現ではなく、現状の既知の制約を記録するためのテスト。
import std/[monotimes, os, unittest]

import atskkserv/skk/memfile_dict

var dictFileSeq = 0
  ## クロックの分解能に依存せず一意なファイル名を作るための連番。

proc newDictFile(content: string): string =
  ## contentを書き込んだ一時辞書ファイルのパスを返す。呼び出し側でremoveFileすること。
  inc dictFileSeq
  result =
    getTempDir() /
    ("atskkserv_test_" & $getMonoTime().ticks & "_" & $dictFileSeq & ".skkdict")
  writeFile(result, content)

# --- A. openDict: 成功/失敗系 ---

test "A1: 正しい辞書ファイルは例外なく開ける":
  let path = newDictFile("aiueo candA/\n")
  defer:
    removeFile(path)
  var d = openDict(path)
  defer:
    d.close()

test "A2: 存在しないパスはOSErrorを送出する（メッセージ文字列はOS依存のため型のみ検証）":
  let path = getTempDir() / "atskkserv_test_not_exist.skkdict"
  removeFile(path)
    # 万一残っていた場合の保険。存在しなくてもエラーにならない。
  expect OSError:
    discard openDict(path)

test "A3: 空(0バイト)ファイルはOSErrorを送出する（POSIX/Windowsいずれもmmap長0の作成に失敗する）":
  let path = newDictFile("")
  defer:
    removeFile(path)
  expect OSError:
    discard openDict(path)

# --- B. lookup: 正常系（見つかる） ---
# 見出し語で昇順ソート済み、行長もバラバラな10件構成。

const sortedSample =
  "aiueo candA/\n" & "hasu candH/\n" & "kanji candK/\n" & "matsuri candM/\n" &
  "nihongo candN1/candN2/\n" & "ohayou candO/\n" & "ringo candR/\n" & "sakura candS/\n" &
  "tokyo candT/\n" & "yuki candY/\n"

test "B1: 先頭行の見出し語が見つかる":
  let path = newDictFile(sortedSample)
  defer:
    removeFile(path)
  var d = openDict(path)
  defer:
    d.close()
  check d.lookup("aiueo") == @["candA"]

test "B2: 末尾行の見出し語が見つかる":
  let path = newDictFile(sortedSample)
  defer:
    removeFile(path)
  var d = openDict(path)
  defer:
    d.close()
  check d.lookup("yuki") == @["candY"]

test "B3: 複数回の二分を要する中間の見出し語が見つかる":
  let path = newDictFile(sortedSample)
  defer:
    removeFile(path)
  var d = openDict(path)
  defer:
    d.close()
  check d.lookup("nihongo") == @["candN1", "candN2"]

test "B4/B5: 候補が1件・複数件のどちらも順序通りに返り、末尾スラッシュ由来の空要素は含まれない":
  let path = newDictFile("fukusuu ichi/ni/san/\nhitotsu tada/\n")
    # 見出し語は昇順ソート必須
  defer:
    removeFile(path)
  var d = openDict(path)
  defer:
    d.close()
  check d.lookup("hitotsu") == @["tada"]
  check d.lookup("fukusuu") == @["ichi", "ni", "san"]

test "B6: マルチバイト(日本語UTF-8)の見出し語・候補もバイト比較で正しく一致する":
  let path = newDictFile("さくら 桜/サクラ/\n")
  defer:
    removeFile(path)
  var d = openDict(path)
  defer:
    d.close()
  check d.lookup("さくら") == @["桜", "サクラ"]

test "B7: エントリ1件のみのファイルでもその1件を検索できる（二分探索の最小境界）":
  let path = newDictFile("tanitsu koho/\n")
  defer:
    removeFile(path)
  var d = openDict(path)
  defer:
    d.close()
  check d.lookup("tanitsu") == @["koho"]

test "B8: 最終行に改行が無いファイルでも最終行の見出し語を検索できる":
  let path = newDictFile("saigo owari/") # 末尾に'\n'を付けない
  defer:
    removeFile(path)
  var d = openDict(path)
  defer:
    d.close()
  check d.lookup("saigo") == @["owari"]

# --- C. lookup: 正常系（見つからない） ---

test "C1: 全見出し語より辞書順で小さいキーは見つからない":
  let path = newDictFile(sortedSample)
  defer:
    removeFile(path)
  var d = openDict(path)
  defer:
    d.close()
  check d.lookup("0000") == newSeq[string]()

test "C2: 全見出し語より辞書順で大きいキーは見つからない":
  let path = newDictFile(sortedSample)
  defer:
    removeFile(path)
  var d = openDict(path)
  defer:
    d.close()
  check d.lookup("zzzzz") == newSeq[string]()

test "C3: 既存キーの中間で、どちらとも一致しないキーは見つからない":
  let path = newDictFile(sortedSample)
  defer:
    removeFile(path)
  var d = openDict(path)
  defer:
    d.close()
  check d.lookup("logic") == newSeq[string]() # "kanji" と "matsuri" の間

test "C4: 既存の見出し語の真の接頭辞は一致とみなさない":
  let path = newDictFile(sortedSample)
  defer:
    removeFile(path)
  var d = openDict(path)
  defer:
    d.close()
  check d.lookup("niho") == newSeq[string]() # "nihongo" の接頭辞

test "C5: 検索キーが既存の見出し語を真の接頭辞として含む場合も一致とみなさない":
  let path = newDictFile(sortedSample)
  defer:
    removeFile(path)
  var d = openDict(path)
  defer:
    d.close()
  check d.lookup("nihongogo") == newSeq[string]() # "nihongo" を接頭辞として含む

# --- D. lookup: 境界的だが定義された挙動 ---

test "D1: 見出し語は一致するが本文が空の場合は「見つかったのに」空seqを返す":
  ## server.nimはこの空seqをNOT_FOUNDとして扱うため、
  ## 呼び出し側からは「見出し語自体が無い」場合と区別できない仕様上の穴だが、
  ## 意図した挙動として固定化しておく。
  let path = newDictFile("karappo \n")
  defer:
    removeFile(path)
  var d = openDict(path)
  defer:
    d.close()
  check d.lookup("karappo") == newSeq[string]()

# --- E. lookup: 契約違反入力（未定義・非保証の明示） ---
# このモジュールは「見出し語で昇順ソート済み・重複キーなし」という
# 二分探索の前提を自身では検証しない。以下はクラッシュしないが結果は
# 保証されないことを記録するテストであり、バグ修正の対象ではない。

test "E1: 未ソートの入力では、実在するキーが誤ってNOT_FOUND相当になりうる（既知の制約）":
  ## 実際にモジュールを動かして再現を確認済みの具体例。
  ## ソート済み前提が崩れると二分探索が正しい行へ到達できないことがある。
  let path = newDictFile("z zv/\na av/\nm mv/\n")
  defer:
    removeFile(path)
  var d = openDict(path)
  defer:
    d.close()
  check d.lookup("z") == newSeq[string]()
    # 本来は @["zv"] になるべきだが見つからない

test "E2: 重複キーが存在してもクラッシュしない（どちらの行がヒットするかは保証しない）":
  let path = newDictFile("dup one/\ndup two/\n")
  defer:
    removeFile(path)
  var d = openDict(path)
  defer:
    d.close()
  let res = d.lookup("dup")
  check res == @["one"] or res == @["two"]
