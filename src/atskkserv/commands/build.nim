## 統合版SKK辞書生成
import std/[files, paths]
import chronicles
import confutils

import ../skk/dictionary

type BuildOptions* = object
  force* {.name: "force", defaultValue: false, desc: "Orverwrite merged dictionary".}:
    bool
  dest* {.
    name: "dest", defaultValue: "./SKK-JISYO.utf8", desc: "Dictionary output path"
  .}: string
  sources* {.argument, desc: "Source dictionary files and output path".}: seq[string]

proc validatePaths(opts: BuildOptions): bool =
  if opts.sources.len < 1:
    error "<sources> requires 1 paths at least", num = opts.sources.len
    return false
  for s in opts.sources:
    if not Path(s).fileExists:
      error "Source file does not exists", path = s
      return false
  if not opts.force and Path(opts.dest).fileExists:
    error "Destination file already exists", path = opts.dest
    return false
  return true

proc execBuild*(cOpts: BuildOptions) =
  if not cOpts.validatePaths():
    notice "Process canceled"
    quit(0)
  let entries = mergeDictEntries(cOpts.sources)
  saveDictEntries(entries, cOpts.dest, cOpts.force)
