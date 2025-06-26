#!/usr/bin/env python3

"""
文档_ https://github.com/hooke007/MPV_lazy/wiki/0_FAQ#%E5%8D%95%E5%AE%9E%E4%BE%8B%E6%A8%A1%E5%BC%8F

SOURCE_ https://github.com/mpv-player/mpv/blob/master/TOOLS/umpv
COMMIT_ 48f944d21b42b682bd12e522f5b24fd1a0e15058

当前脚本已被裁剪 仅支持Windows
此文件主要用于编译，使用umpv无须下载此文件，详见上方文档。
"""

import os
import shlex
import socket
import string
import subprocess
import sys
from collections.abc import Iterable
from configparser import ConfigParser
from typing import BinaryIO


def read_conf():
    conf = ConfigParser()
    try :
        conf.read(filenames="umpv.conf", encoding="utf-8")
        param1 = conf["DEFAULT"].get("Socket_Path", r"\\.\pipe\umpv")
        param2 = conf["DEFAULT"].get("Loadfile_Flag", "replace")
    except :
        param1 = r"\\.\pipe\umpv"
        param2 = "replace"
    return param1, param2

Socket_Path, Loadfile_Flag = read_conf()

def is_url(filename: str) -> bool:
    parts = filename.split("://", 1)
    if len(parts) < 2:
        return False
    # protocol prefix has no special characters => it's an URL
    allowed_symbols = string.ascii_letters + string.digits + "_"
    prefix = parts[0]
    return all(c in allowed_symbols for c in prefix)

def send_files_to_mpv(conn: socket.socket | BinaryIO, files: Iterable[str]) -> None:
    try:
        send = conn.send if isinstance(conn, socket.socket) else conn.write
        for f in files:
            f = f.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
            send(f'raw loadfile "{f}" "{Loadfile_Flag}"\n'.encode())
    except Exception:
        print("mpv is terminating or the connection was lost.", file=sys.stderr)
        sys.exit(1)

def start_mpv(files: Iterable[str], Socket_Path: str) -> None:
    mpv = "mpv.exe"
    mpv_command = shlex.split(os.getenv("MPV", mpv))
    mpv_command.extend([
        f"--input-ipc-server={Socket_Path}",
        "--",
    ])
    mpv_command.extend(files)
    subprocess.Popen(mpv_command, start_new_session=True)

def main() -> None:
    files = (os.path.abspath(f) if not is_url(f) else f for f in sys.argv[1:])

    try:
        with open(Socket_Path, "r+b", buffering=0) as pipe:
            send_files_to_mpv(pipe, files)
    except (FileNotFoundError, ConnectionRefusedError):
        start_mpv(files, Socket_Path)

if __name__ == "__main__":
    main()
