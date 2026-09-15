## サーバープロセスの処理
import std/[asyncnet, asyncdispatch, encodings, options, strutils]
import chronicles

import ./engine
import ./skk/protocol

var searchEngine {.threadvar.}: SearchEngine
var clients {.threadvar.}: seq[AsyncSocket]
## 接続中のクライアントソケット

proc closeSearchEngine*() =
  searchEngine.close()

proc closeAllClients*() =
  ## 接続中の全クライアントを切断する
  for client in clients:
    if not client.isClosed():
      info "Closing all connections"
      client.close()
  clients.setLen(0)

proc removeClient(client: AsyncSocket) =
  ## 切断済みのクライアントを一覧から除去する
  let idx = clients.find(client)
  if idx >= 0:
    clients.delete(idx)

proc recvCommand(client: AsyncSocket): Future[Option[Command]] {.async.} =
  let buf = await client.recv(1)
  if buf.len == 0:
    return none(Command)
  case buf
  of "0":
    result = some(newCommand(CommandCode.END))
  of "1":
    var command = newCommand(CommandCode.REQUEST)
    var body = ""
    while true:
      let sbuf = await client.recv(1)
      if sbuf.len == 0:
        return none(Command)
      if sbuf == " ":
        break
      else:
        body = body & sbuf
    command.body = body
    return some(command)
  of "2":
    return some(newCommand(CommandCode.VERSION))
  of "3":
    return some(newCommand(CommandCode.HOST))
  else:
    debug "Unknown token in receive command", chars = buf
    return none(Command)

proc processClient(client: AsyncSocket) {.async.} =
  ## 接続中クライアントからの通信対応
  while not client.isClosed():
    let command = await recvCommand(client)
    if command.isNone:
      debug "Command not found"
      break
    case command.get().code
    of CommandCode.END:
      debug "Receive 'END' command"
      break
    of CommandCode.REQUEST:
      let
        body = command.get().body
        ubody = convert(body, "utf-8", "euc-jp")
      debug "Receive 'REQUEST' command", body = ubody
      let candicates = searchEngine.lookup(ubody)
      if candicates.len > 0:
        debug "Candicates are found", num = candicates.len
        await client.send(
          "$1/$2/\n" %
            [$LookupCode.FOUND, convert(candicates.join("/"), "euc-jp", "utf-8")]
        )
      else:
        debug "Candicates are not found"
        await client.send("$1$2 " % [$LookupCode.NOT_FOUND, body])
    of CommandCode.VERSION:
      debug "Receive 'VERSION' command"
      await client.send("atskkserv/0.0.0 ")
    of CommandCode.HOST:
      debug "Receive 'HOST' command"
      await client.send(": ")
  if not client.isClosed():
    client.close()
  removeClient(client)
  debug "Client disconneccted", total = clients.len

proc serve*(engine: SearchEngine, host: string, port: int) {.async.} =
  ## サーバープロセスの待ち受け
  clients = @[]
  searchEngine = engine
  var server = newAsyncSocket()
  server.setSockOpt(OptReuseAddr, true)
  server.bindAddr(Port(port), host)
  server.listen()

  info "Waiting started"
  while true:
    let client = await server.accept()
    clients.add client
    debug "Client conneccted", total = clients.len

    asyncCheck processClient(client)
