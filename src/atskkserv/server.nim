## サーバープロセスの処理
import std/[asyncnet, asyncdispatch, options]
import chronicles

import ./skk/protocol

var clients {.threadvar.}: seq[AsyncSocket]
## 接続中のクライアントソケット

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
  let line = await client.recv(1)
  if line.len == 0:
    return none(Command)
  case line
  of "0":
    result = some(newCommand(CommandCode.END))
  of "2":
    return some(newCommand(CommandCode.VERSION))
  of "3":
    return some(newCommand(CommandCode.HOST))
  else:
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
      continue
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

proc serve*(host: string, port: int) {.async.} =
  ## サーバープロセスの待ち受け
  clients = @[]
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
