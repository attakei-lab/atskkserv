from __future__ import annotations

import platform
import signal
import socket
from pathlib import Path
from subprocess import Popen, run
from typing import TYPE_CHECKING

import pytest
from random_port.pool import TcpRandomPort

if TYPE_CHECKING:
    from collections.abc import Generator

    type Address = tuple[str, int]

_ROOT = Path(__file__).parents[2]
_BIN_PATH = _ROOT / "dist" / f"atskkserv{'.exe' if platform.system() == 'Windows' else ''}"

_build_in_session = False


@pytest.fixture
def skk_server() -> Generator[Address]:
    """サーバープロセスを立ち上げ、ソケット通信用のホストとポートを引き渡す。"""
    global _build_in_session

    if not _build_in_session:
        _build_in_session = True
        ret = run(["nimble", "build"], cwd=_ROOT, check=False)
        assert ret.returncode == 0, "`nimble build` is failure."

    port = TcpRandomPort().value()
    proc = Popen([str(_BIN_PATH), f"--server-port={port}"])
    yield "localhost", port
    print("Stopping")
    proc.send_signal(signal.SIGINT)


@pytest.fixture
def skk_client(skk_server: Address) -> Generator[socket.socket]:
    """起動済みサーバープロセスにクライアント接続を実施する。"""
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect(skk_server)
    yield sock
    sock.close()
