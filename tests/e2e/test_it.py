from __future__ import annotations

import concurrent.futures as cf
import socket
import threading
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from .conftest import Address


def recv_all(sock: socket.socket, bufsize: int = 256, idle_timeout: float = 0.5) -> bytes:
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


def test_connect(skk_client: socket.socket):
    skk_client.send(b"HELLO")
    assert recv_all(skk_client) == b"HELLO"


def test_multiple_connect(skk_server: Address):
    """同時接続性のテスト。"""
    texts = [
        b"HELLO",
        b"SKK",
        b"WORLD",
    ]
    barrier = threading.Barrier(len(texts))

    def worker(data: bytes):
        barrier.wait()
        with socket.create_connection(skk_server, timeout=1) as s:
            s.send(data)
            return recv_all(s)

    with cf.ThreadPoolExecutor(len(texts)) as ex:
        results = [
            f.result()
            for f in [
                ex.submit(worker, t)
                for t in texts
            ]
        ]
        assert sorted(results) == sorted(texts)
