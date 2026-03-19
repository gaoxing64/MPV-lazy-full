:: 说明（UTF8中文乱码可修改编码为ANSI或GB18030）
chcp 936

@echo off
echo ==========================================================
echo == 测试模式
echo 测试自定义参数
echo 运行前先修改好"mpv-test.conf"
echo 当前目录若不存在"mpv.com"将查找环境变量Path中的代替
echo 原版MPV窗口打开后拖入任意视频即可

:: 输出将执行的参数信息
echo ==========================================================
echo == 启动参数
echo mpv --config=no --include=installer/mpv-test.conf --idle=once --force-window=yes
echo ==========================================================
echo == 以下为日志
echo ==========================================================

:: 更改当前工作目录
cd /D %~dp0\..

:: 执行启动参数
mpv.com --config=no --include=installer/mpv-test.conf --idle=once --force-window=yes

:: 手动退出后输出的文本
echo ==========================================================
echo == MPV已关闭
echo ==========================================================
pause