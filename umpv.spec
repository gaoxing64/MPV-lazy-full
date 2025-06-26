# -*- mode: python ; coding: utf-8 -*-

"""
此文件仅被用于编译 umpv.exe ，命令如下（同时需要 umpv.py 和 installer/mpv-icon.ico ）

    ```
    ./python -m PyInstaller umpv.spec`
    ```
"""

a = Analysis(
    ['umpv.py'],
    pathex=[],
    binaries=[],
    datas=[],
    hiddenimports=[],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=2,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='umpv',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=True,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=['installer/mpv-icon.ico'],
)
