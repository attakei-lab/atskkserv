## mmapベースによるSKK辞書の検索モジュール
##
## .. note::
##
##    ここから先は、Claudeが生成したコードを実装把握などをせずに採用している。
##    そのため、適切な修正対応がやや難しい。
import std/[memfiles, strutils]

type SkkMemfileDict* = object
  mf: MemFile
  p: ptr UncheckedArray[char]
  size: int

proc openDict*(path: string): SkkMemfileDict =
  result.mf = memfiles.open(path, mode = fmRead)
  result.p = cast[ptr UncheckedArray[char]](result.mf.mem)
  result.size = result.mf.size

proc close*(d: var SkkMemfileDict) =
  d.mf.close()

proc lineStart(d: SkkMemfileDict, pos: int): int {.inline.} =
  result = pos
  while result > 0 and d.p[result - 1] != '\n':
    dec result

proc lineEnd(d: SkkMemfileDict, pos: int): int {.inline.} =
  result = pos
  while result < d.size and d.p[result] != '\n':
    inc result

proc cmpKey(d: SkkMemfileDict, s, e: int, key: string): int {.inline.} =
  ## d[s ..< e] と key をバイト比較（無割り当て）
  let n = min(e - s, key.len)
  for i in 0 ..< n:
    let a = uint8(d.p[s + i])
    let b = uint8(key[i])
    if a != b:
      return (if a < b: -1 else: 1)
  result = (e - s) - key.len

proc lookup*(d: SkkMemfileDict, key: string): seq[string] =
  ## 不変オブジェクトしか触らないので、複数スレッドから同時に呼べる。
  var lo = 0 # 常に行頭
  var hi = d.size # 常に行頭または EOF
  while lo < hi:
    var mid = d.lineStart(lo + (hi - lo) div 2)
    if mid < lo:
      mid = lo
    let eol = d.lineEnd(mid)
    var ke = mid # みだしの終端
    while ke < eol and d.p[ke] != ' ':
      inc ke

    let c = d.cmpKey(mid, ke, key)
    if c < 0:
      lo = eol + 1 # 必ず前進する
    elif c > 0:
      hi = mid # 必ず後退する
    else:
      let bs = ke + 1
      if bs >= eol:
        return @[]
      var body = newString(eol - bs)
      copyMem(addr body[0], addr d.p[bs], body.len)
      for cand in body.split('/'):
        if cand.len > 0:
          result.add cand
      return
  return @[]
