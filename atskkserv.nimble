import std/os

# Package

version       = "0.1.0"
author        = "Kazuya Takei"
description   = "attakei's SKK server"
license       = "Apache-2.0"
srcDir        = "src"
binDir        = "dist"
installExt    = @["nim"]
bin           = @["atskkserv"]


# Dependencies

requires "nim >= 2.2.0"
requires "chronicles >= 0.12.4"
requires "confutils >= 0.1.1"

task bundle, "Bundle resources for distribution":
  let
    binExt =
      when defined(windows):
        ".exe"
      else:
        ""
    bundleDir = binDir & DirSep & "atskkserv-v" & version
  mkDir(bundleDir)
  for b in bin:
    let src = binDir & "/" & b & binExt
    let dst = bundleDir & DirSep & b & binExt
    cpFile(src, dst)
  for f in @["LICENSE", "README.rst"]:
    cpFile(f, bundleDir & DirSep & f)
