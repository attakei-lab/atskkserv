## SKK標準フォーマットの辞書
import std/[algorithm, encodings, files, paths, sequtils, strutils, tables]
import chronicles

type DictEntries* = OrderedTable[string, seq[string]]

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
