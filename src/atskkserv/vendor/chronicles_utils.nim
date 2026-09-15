## chroniclesのアプリ内ラッパー
import std/strutils
import chronicles

proc parseLogLevel(level: string): LogLevel =
  ## 文字列のログレベルをEnum化する。
  case level.toLowerAscii()
  of "trace": LogLevel.TRACE
  of "debug": LogLevel.DEBUG
  of "info": LogLevel.INFO
  of "notice": LogLevel.NOTICE
  of "warn": LogLevel.WARN
  of "error": LogLevel.ERROR
  of "fatal": LogLevel.FATAL
  of "none": LogLevel.NONE
  else: LogLevel.DEBUG
    # デフォルト

proc setLogLevel*(level: string) =
  chronicles.setLogLevel(parseLogLevel(level))

proc setLogLevel*(level: string, sinkIdx: int) =
  chronicles.setLogLevel(parseLogLevel(level), sinkIdx)
