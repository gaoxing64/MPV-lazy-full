@echo off
chcp 936

setlocal enableextensions enabledelayedexpansion
path %SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\Wbem

:: Unattended install flag. When set, the script will not require user input.
set unattended=no
if "%1"=="/u" set unattended=yes

:: Make sure the script is running as admin
call :ensure_admin

:: Delete "App Paths" entry
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\umpv.exe" /f >nul

:: Delete HKCR subkeys
set classes_root_key=HKLM\SOFTWARE\Classes
reg delete "%classes_root_key%\Applications\umpv.exe" /f >nul
reg delete "%classes_root_key%\SystemFileAssociations\video\OpenWithList\umpv.exe" /f >nul
reg delete "%classes_root_key%\SystemFileAssociations\audio\OpenWithList\umpv.exe" /f >nul

:: Delete "Default Programs" entry
reg delete "HKLM\SOFTWARE\RegisteredApplications" /v "umpv" /f >nul
reg delete "HKLM\SOFTWARE\Clients\Media\umpv\Capabilities" /f >nul

:: Delete all OpenWithProgIds referencing ProgIds that start with io.umpv.
for /f "usebackq eol= delims=" %%k in (`reg query "%classes_root_key%" /f "io.umpv.*" /s /v /c`) do (
	set "key=%%k"
	echo !key!| findstr /r /i "^HKEY_LOCAL_MACHINE\\SOFTWARE\\Classes\\\.[^\\][^\\]*\\OpenWithProgIds$" >nul
	if not errorlevel 1 (
		for /f "usebackq eol= tokens=1" %%v in (`reg query "!key!" /f "io.umpv.*" /v /c`) do (
			set "value=%%v"
			echo !value!| findstr /r /i "^io\.umpv\.[^\\][^\\]*$" >nul
			if not errorlevel 1 (
				echo Deleting !key!\!value!
				reg delete "!key!" /v "!value!" /f >nul
			)
		)
	)
)

:: Delete all ProgIds starting with io.umpv.
for /f "usebackq eol= delims=" %%k in (`reg query "%classes_root_key%" /f "io.umpv.*" /k /c`) do (
	set "key=%%k"
	echo !key!| findstr /r /i "^HKEY_LOCAL_MACHINE\\SOFTWARE\\Classes\\io\.umpv\.[^\\][^\\]*$" >nul
	if not errorlevel 1 (
		echo Deleting !key!
		reg delete "!key!" /f >nul
	)
)

:: Delete start menu link
del "%ProgramData%\Microsoft\Windows\Start Menu\Programs\umpv.lnk"

echo 反注册成功！
if [%unattended%] == [yes] exit 0
pause
exit 0

:die
	if not [%1] == [] echo %~1
	if [%unattended%] == [yes] exit 1
	pause
	exit 1

:ensure_admin
	:: 'openfiles' is just a commmand that is present on all supported Windows
	:: versions, requires admin privileges and has no side effects, see:
	:: https://stackoverflow.com/questions/4051883/batch-script-how-to-check-for-admin-rights
	openfiles >nul 2>&1
	if errorlevel 1 (
		echo 该批处理脚本须要管理员权限
		echo 选中该文件 右键 “以管理员身份运行” 重新操作
		call :die
	)
	goto :EOF
