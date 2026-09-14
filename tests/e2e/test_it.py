from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from socket import socket


def recv_all(sock: socket, bufsize: int = 256, idle_timeout: float = 0.5) -> bytes:
    """ソケットからデータが届かなくなるまで受信し続ける。

    サーバー実装がバイト単位で分割送信することがあるため、
    「受信サイズがbufsize未満」を終端判定に使うと受信途中で
    打ち切ってしまう。ここでは一定時間データが来なくなったことを
    もって受信完了とみなす。
    """
    sock.settimeout(idle_timeout)
    ret = b""
    try:
        while True:
            buf = sock.recv(bufsize)
            if buf == b"":
                break
            ret += buf
    except TimeoutError:
        pass
    finally:
        sock.settimeout(None)
    return ret


def test_connect(skk_client: socket):
    skk_client.send(b"HELLO")
    assert recv_all(skk_client) == b"HELLO"
