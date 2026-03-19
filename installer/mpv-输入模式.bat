:: 说明（UTF8中文乱码可修改编码为ANSI或GB18030）
chcp 936

@echo off
echo ==========================================================
echo == 输入模式（键盘、鼠标等外设键值的输入检测）
echo 当前目录若不存在"mpv.com"将查找环境变量Path中的代替
echo 主要用来查看按键的名称和原版MPV绑定的命令
echo 启动后不要载入视频文件
echo 当焦点在MPV窗口上时一切外设的操作都将在OSD上显示
echo 该模式下屏蔽一切快捷键的实际功能（除非关闭MPV）
echo 建议在CMD窗口进行按键检测（防止移动鼠标的操作刷屏）

:: 输出将执行的参数信息
echo ==========================================================
echo == 启动参数
echo mpv --config=no --input-test=yes --idle=yes --force-window=yes --hidpi-window-scale=no --autofit-smaller=25%x25% --geometry=80%:80%
echo ==========================================================
echo == 以下为日志
echo ==========================================================

:: 更改当前工作目录
cd /D %~dp0\..

:: 输出版本信息
:: mpv.com --version

:: 执行启动参数
mpv.com --config=no --input-test=yes --idle=yes --force-window=yes --hidpi-window-scale=no --autofit-smaller=25%%x25%% --geometry=80%%:80%%

:: 手动退出后输出的文本
echo ==========================================================
echo == MPV已关闭
echo ==========================================================
pause