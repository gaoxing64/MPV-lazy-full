:: 说明（UTF8中文乱码可修改编码为ANSI或GB18030）
chcp 936

@echo off
echo ==========================================================
echo == 纯净模式可用于兼容测试或特殊用途
echo 当前目录若不存在"mpv.com"将查找环境变量Path中的代替
echo 以接近原始默认参数的传统方式启动原版MPV
echo 原版MPV窗口打开后不要在CMD内进行操作
echo 关闭该CMD窗口也将自动关闭MPV

:: 输出将执行的参数信息
echo ==========================================================
echo == 启动参数
echo mpv --config=no --idle=once --force-window=yes --keep-open=yes --hidpi-window-scale=no --autofit-smaller=500x500
echo ==========================================================
echo == 以下为日志
echo ==========================================================

:: 更改当前工作目录
cd /D %~dp0\..

:: 输出版本信息
mpv.com --version

:: 执行启动参数
mpv.com --config=no --idle=once --force-window=yes --keep-open=yes --hidpi-window-scale=no --autofit-smaller=500x500

:: 手动退出后输出的文本
echo ==========================================================
echo == MPV已关闭
echo ==========================================================
pause