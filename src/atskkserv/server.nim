## サーバープロセスの処理
import std/[asyncnet, asyncdispatch]

var clients {.threadvar.}: seq[AsyncSocket]
## 接続中のクライアントソケット

proc processClient(client: AsyncSocket) {.async.} =
  ## 接続中クライアントからの通信対応
  while not client.isClosed():
    # Nimの ``recv`` は引数に指定したサイズを受信するまで待ち続ける。
    let line = await client.recv(1)
    # 最低限「単なるTCPサーバーとして稼動する」を前提としており、
    # 現時点ではエコーするだけ。
    await client.send(line)

proc serve*(port: int) {.async.} =
  ## サーバープロセスの待ち受け
  clients = @[]
  var server = newAsyncSocket()
  server.setSockOpt(OptReuseAddr, true)
  server.bindAddr(Port(port))
  server.listen()

  echo("Start waiting.")
  while true:
    let client = await server.accept()
    clients.add client
    echo("Connected " & $clients.len & " clients.")

    asyncCheck processClient(client)
