from __future__ import annotations

import platform
import signal
import socket
from pathlib import Path
from subprocess import TimeoutExpired, Popen, run
from time import monotonic, sleep
from typing import TYPE_CHECKING

import pytest
from random_port.pool import TcpRandomPort

if TYPE_CHECKING:
    from collections.abc import Generator

    type Address = tuple[str, int]

_ROOT = Path(__file__).parents[2]
_BIN_PATH = _ROOT / "dist" / f"atskkserv{'.exe' if platform.system() == 'Windows' else ''}"
_STARTUP_TIMEOUT = 5.0
_SHUTDOWN_TIMEOUT = 5.0

_build_in_session = False
"""セッション中に`nimble build`を実行済みかどうかを示す。"""


def _wait_until_listening(proc: Popen[bytes], address: Address, timeout: float) -> None:
    """サーバーがリッスンを開始するまで待機する。

    `Popen`はプロセス起動を待つだけで、非同期ランタイムの初期化や
    ソケットのbind/listen完了までは保証しないため、実際に接続できる
    ようになるまでポーリングする。
    """
    deadline = monotonic() + timeout
    while monotonic() < deadline:
        if proc.poll() is not None:
            msg = f"skk_server process exited early (code={proc.returncode})"
            raise RuntimeError(msg)
        try:
            with socket.create_connection(address, timeout=0.1):
                return
        except OSError:
            sleep(0.05)
    msg = f"skk_server did not start listening on {address} within {timeout}s"
    raise TimeoutError(msg)


@pytest.fixture
def skk_server() -> Generator[Address]:
    """サーバープロセスを立ち上げ、ソケット通信用のホストとポートを引き渡す。"""
    global _build_in_session

    if not _build_in_session:
        _build_in_session = True
        ret = run(["nimble", "build"], cwd=_ROOT, check=False)
        assert ret.returncode == 0, "`nimble build` is failure."

    port = TcpRandomPort().value()
    address: Address = ("localhost", port)
    proc = Popen([str(_BIN_PATH), f"--server-port={port}"])
    _wait_until_listening(proc, address, _STARTUP_TIMEOUT)
    yield address
    print("Stopping")
    proc.send_signal(signal.SIGINT)
    try:
        proc.wait(timeout=_SHUTDOWN_TIMEOUT)
    except TimeoutExpired:
        proc.kill()
        proc.wait()


@pytest.fixture
def skk_client(skk_server: Address) -> Generator[socket.socket]:
    """起動済みサーバープロセスにクライアント接続を実施する。"""
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect(skk_server)
    yield sock
    sock.close()
