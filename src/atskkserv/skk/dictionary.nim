## SKK標準フォーマットの辞書
import std/[algorithm, encodings, files, memfiles, paths, sequtils, strutils, tables]
import chronicles

type
  DictEntries* = OrderedTable[string, seq[string]]
  SkkDict* = object
    mf: MemFile
    p: ptr UncheckedArray[char]
    size*: int

proc mergeDictEntries*(sources: openArray[string]): DictEntries =
  var entries = initOrderedTable[string, seq[string]]()

  for source in sources:
    info "Load dictonary", path = source
    let
      raw = readFile(source)
      text = convert(raw, "utf-8", "euc-jp")
    for line in text.splitLines():
      if line.startsWith(";;") or line == "":
        continue
      let parsed = line.split(" ", 1)
      let
        key = parsed[0]
        val = parsed[1]
      if key notin entries:
        entries[key] = @[]
      entries[key] = entries[key] & val.split("/")

  entries.sort(
    proc(x, y: (string, seq[string])): int =
      cmp(x[0], y[0])
  )
  for k in entries.keys:
    entries[k] = entries[k].deduplicate()

  info "Merged", num = entries.len
  return entries

proc saveDictEntries*(entries: DictEntries, dest: string, force: bool) =
  if Path(dest).fileExists and force:
    debug "Removing old file", path = dest
    Path(dest).removeFile()
  var f: File
  doAssert f.open(dest, fmWrite)
  defer:
    f.close()
  for key in entries.keys:
    let candicates = entries[key].join("/")
    f.write("$1 $2/\L" % [key, candicates])

proc openDict*(path: string): SkkDict =
  result.mf = memfiles.open(path, mode = fmRead)
  result.p = cast[ptr UncheckedArray[char]](result.mf.mem)
  result.size = result.mf.size

proc close*(d: var SkkDict) =
  d.mf.close()

proc lineStart(d: SkkDict, pos: int): int {.inline.} =
  result = pos
  while result > 0 and d.p[result - 1] != '\n':
    dec result

proc lineEnd(d: SkkDict, pos: int): int {.inline.} =
  result = pos
  while result < d.size and d.p[result] != '\n':
    inc result

proc cmpKey(d: SkkDict, s, e: int, key: string): int {.inline.} =
  ## d[s ..< e] と key をバイト比較（無割り当て）
  let n = min(e - s, key.len)
  for i in 0 ..< n:
    let a = uint8(d.p[s + i])
    let b = uint8(key[i])
    if a != b:
      return (if a < b: -1 else: 1)
  result = (e - s) - key.len

proc lookup*(d: SkkDict, key: string): seq[string] =
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
