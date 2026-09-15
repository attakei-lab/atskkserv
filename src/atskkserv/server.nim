## サーバープロセスの処理
import std/[asyncnet, asyncdispatch]
import chronicles

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

proc processClient(client: AsyncSocket) {.async.} =
  ## 接続中クライアントからの通信対応
  while not client.isClosed():
    # Nimの ``recv`` は引数に指定したサイズを受信するまで待ち続ける。
    let line = await client.recv(1)
    if line.len == 0:
      # 相手側からの切断(EOF)を検知した場合はループを抜ける。
      break
    # 最低限「単なるTCPサーバーとして稼動する」を前提としており、
    # 現時点ではエコーするだけ。
    await client.send(line)
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
