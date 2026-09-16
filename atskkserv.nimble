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
