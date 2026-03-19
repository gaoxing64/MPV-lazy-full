@echo off
setlocal enableextensions enabledelayedexpansion
path %SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\

:: Unattended install flag. When set, the script will not require user input.
set unattended=no
if "%1"=="/u" set unattended=yes

:: Make sure this is Windows Vista or later
call :ensure_vista

:: Make sure the script is running as admin
call :ensure_admin

:: Command line arguments to use when launching mpv from a file association
set mpv_args=

:: Get mpv.exe location
cd /D %~dp0\..
set mpv_path=%cd%\mpv.exe
if not exist "%mpv_path%" call :die "mpv.exe not found"

:: Get mpv-icon.ico location
set icon_path=%~dp0mpv-icon.ico
if not exist "%icon_path%" call :die "mpv-icon.ico not found"

:: Register mpv.exe under the "App Paths" key, so it can be found by
:: ShellExecute, the run command, the start menu, etc.
set app_paths_key=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\mpv.exe
call :reg add "%app_paths_key%" /d "%mpv_path%" /f
call :reg add "%app_paths_key%" /v "UseUrl" /t REG_DWORD /d 1 /f

:: Register mpv.exe under the "Applications" key to add some default verbs for
:: when mpv is used from the "Open with" menu
set classes_root_key=HKLM\SOFTWARE\Classes
set app_key=%classes_root_key%\Applications\mpv.exe
call :reg add "%app_key%" /v "FriendlyAppName" /d "mpv" /f
call :add_verbs "%app_key%"

:: Add mpv to the "Open with" list for all video and audio file types
call :reg add "%classes_root_key%\SystemFileAssociations\video\OpenWithList\mpv.exe" /d "" /f
call :reg add "%classes_root_key%\SystemFileAssociations\audio\OpenWithList\mpv.exe" /d "" /f

:: Add DVD AutoPlay handler
set autoplay_key=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers
call :reg add "%classes_root_key%\io.mpv.dvd\shell\play" /d "&Play" /f
call :reg add "%classes_root_key%\io.mpv.dvd\shell\play\command" /d "\"%mpv_path%\" %mpv_args% dvd:// --dvd-device=\"%%%%L\"" /f
call :reg add "%autoplay_key%\Handlers\MpvPlayDVDMovieOnArrival" /v "Action" /d "Play DVD movie" /f
call :reg add "%autoplay_key%\Handlers\MpvPlayDVDMovieOnArrival" /v "DefaultIcon" /d "%mpv_path%,0" /f
call :reg add "%autoplay_key%\Handlers\MpvPlayDVDMovieOnArrival" /v "InvokeProgID" /d "io.mpv.dvd" /f
call :reg add "%autoplay_key%\Handlers\MpvPlayDVDMovieOnArrival" /v "InvokeVerb" /d "play" /f
call :reg add "%autoplay_key%\Handlers\MpvPlayDVDMovieOnArrival" /v "Provider" /d "mpv" /f
call :reg add "%autoplay_key%\EventHandlers\PlayDVDMovieOnArrival" /v "MpvPlayDVDMovieOnArrival" /f

:: Add Blu-ray AutoPlay handler
call :reg add "%classes_root_key%\io.mpv.bluray\shell\play" /d "&Play" /f
call :reg add "%classes_root_key%\io.mpv.bluray\shell\play\command" /d "\"%mpv_path%\" %mpv_args% bd:// --bluray-device=\"%%%%L\"" /f
call :reg add "%autoplay_key%\Handlers\MpvPlayBluRayOnArrival" /v "Action" /d "Play Blu-ray movie" /f
call :reg add "%autoplay_key%\Handlers\MpvPlayBluRayOnArrival" /v "DefaultIcon" /d "%mpv_path%,0" /f
call :reg add "%autoplay_key%\Handlers\MpvPlayBluRayOnArrival" /v "InvokeProgID" /d "io.mpv.bluray" /f
call :reg add "%autoplay_key%\Handlers\MpvPlayBluRayOnArrival" /v "InvokeVerb" /d "play" /f
call :reg add "%autoplay_key%\Handlers\MpvPlayBluRayOnArrival" /v "Provider" /d "mpv" /f
call :reg add "%autoplay_key%\EventHandlers\PlayBluRayOnArrival" /v "MpvPlayBluRayOnArrival" /f

:: Add a capabilities key for mpv, which is registered later on for use in the
:: "Default Programs" control panel
set capabilities_key=HKLM\SOFTWARE\Clients\Media\mpv\Capabilities
call :reg add "%capabilities_key%" /v "ApplicationName" /d "mpv" /f
call :reg add "%capabilities_key%" /v "ApplicationDescription" /d "mpv media player" /f

:: Add file types
set supported_types_key=%app_key%\SupportedTypes
set file_associations_key=%capabilities_key%\FileAssociations
:: Uncompressed formats
call :add_type ""                                 "video" "Raw YUV Video"              ".yuv"
call :add_type ""                                 "video" "YUV4MPEG2 Video"            ".y4m"
:: MPEG formats
call :add_type "video/vnd.dlna.mpeg-tts"          "video" "MPEG-2 Transport Stream"    ".m2ts" ".m2t" ".mts" ".mtv" ".ts" ".tsv" ".tsa" ".tts" ".trp"
call :add_type "video/mpeg"                       "video" "MPEG Video"                 ".mpeg" ".mpg" ".mpe" ".mpeg2" ".m1v" ".m2v" ".mp2v" ".mpv" ".mpv2" ".mod" ".tod"
call :add_type "video/dvd"                        "video" "Video Object"               ".vob" ".vro"
call :add_type ""                                 "video" "Enhanced VOB"               ".evob" ".evo"
call :add_type "video/mp4"                        "video" "MPEG-4 Video"               ".mpeg4" ".m4v" ".mp4" ".mp4v" ".mpg4"
call :add_type ""                                 "video" "Raw H.264/AVC Video"        ".h264" ".avc" ".x264" ".264"
call :add_type ""                                 "video" "Raw H.265/HEVC Video"       ".hevc" ".h265" ".x265" ".265"
:: Xiph formats
call :add_type "video/ogg"                        "video" "Ogg Video"                  ".ogv" ".ogm"
call :add_type "application/ogg"                  "video" "Ogg Video"                  ".ogx"
:: Matroska formats
call :add_type "video/x-matroska"                 "video" "Matroska Video"             ".mkv"
call :add_type "video/x-matroska"                 "video" "Matroska 3D Video"          ".mk3d"
call :add_type "video/webm"                       "video" "WebM Video"                 ".webm"
:: Misc formats
call :add_type "video/avi"                        "video" "Video Clip"                 ".avi" ".vfw"
call :add_type ""                                 "video" "DivX Video"                 ".divx"
call :add_type ""                                 "video" "3ivx Video"                 ".3iv"
call :add_type ""                                 "video" "XVID Video"                 ".xvid"
call :add_type ""                                 "video" "NUT Video"                  ".nut"
call :add_type "video/flc"                        "video" "FLIC Video"                 ".flic" ".fli" ".flc"
call :add_type ""                                 "video" "Nullsoft Streaming Video"   ".nsv"
call :add_type "application/gxf"                  "video" "General Exchange Format"    ".gxf"
call :add_type "application/mxf"                  "video" "Material Exchange Format"   ".mxf"
:: Windows Media formats
call :add_type "video/x-ms-wm"                    "video" "Windows Media Video"        ".wm"
call :add_type "video/x-ms-wmv"                   "video" "Windows Media Video"        ".wmv"
call :add_type "video/x-ms-asf"                   "video" "Windows Media Video"        ".asf"
call :add_type ""                                 "video" "Microsoft Recorded TV Show" ".dvr-ms" ".dvr"
call :add_type ""                                 "video" "Windows Recorded TV Show"   ".wtv"
:: DV formats
call :add_type ""                                 "video" "DV Video"                   ".dv" ".hdv"
:: Flash Video formats
call :add_type "video/x-flv"                      "video" "Flash Video"                ".flv"
call :add_type "video/mp4"                        "video" "Flash Video"                ".f4v"
:: QuickTime formats
call :add_type "video/quicktime"                  "video" "QuickTime Video"            ".qt" ".mov"
call :add_type "video/quicktime"                  "video" "QuickTime HD Video"         ".hdmov"
:: Real Media formats
call :add_type "application/vnd.rn-realmedia"     "video" "Real Media Video"           ".rm"
call :add_type "application/vnd.rn-realmedia-vbr" "video" "Real Media Video"           ".rmvb"
:: 3GPP formats
call :add_type "video/3gpp"                       "video" "3GPP Video"                 ".3gpp" ".3gp"
call :add_type "video/3gpp2"                      "video" "3GPP Video"                 ".3gp2" ".3g2"

:: Register "Default Programs" entry
call :reg add "HKLM\SOFTWARE\RegisteredApplications" /v "mpv" /d "SOFTWARE\Clients\Media\mpv\Capabilities" /f

:: Enable long paths in Windows 10
call :reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v "LongPathsEnabled" /t REG_DWORD /d 1 /f

:: Add start menu link
powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('%ProgramData%\Microsoft\Windows\Start Menu\Programs\mpv.lnk');$s.TargetPath='%mpv_path%';$s.Save()"

echo.
echo Installed successfully^^! You can now configure mpv's file associations in the
echo Default Programs control panel.
echo.
if [%unattended%] == [yes] exit 0
<nul set /p =Press any key to open the Default Programs control panel . . .
pause >nul
control /name Microsoft.DefaultPrograms
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
		echo This batch script requires administrator privileges. Right-click on
		echo mpv-install.bat and select "Run as administrator".
		call :die
	)
	goto :EOF

:ensure_vista
	ver | find "XP" >nul
	if not errorlevel 1 (
		echo This batch script only works on Windows Vista and later. To create file
		echo associations on Windows XP, right click on a video file and use "Open with...".
		call :die
	)
	goto :EOF

:reg
	:: Wrap the reg command to check for errors
	>nul reg %*
	if errorlevel 1 set error=yes
	if [%error%] == [yes] echo Error in command: reg %*
	if [%error%] == [yes] call :die
	goto :EOF

:reg_set_opt
	:: Set a value in the registry if it doesn't already exist
	set key=%~1
	set value=%~2
	set data=%~3

	reg query "%key%" /v "%value%" >nul 2>&1
	if errorlevel 1 call :reg add "%key%" /v "%value%" /d "%data%"
	goto :EOF

:add_verbs
	set key=%~1

	:: Set the default verb to "play"
	call :reg add "%key%\shell" /d "play" /f

	:: Hide the "open" verb from the context menu, since it's the same as "play"
	call :reg add "%key%\shell\open" /v "LegacyDisable" /f

	:: Set open command
	call :reg add "%key%\shell\open\command" /d "\"%mpv_path%\" %mpv_args% -- \"%%%%L\"" /f

	:: Add "play" verb
	call :reg add "%key%\shell\play" /d "&Play" /f
	call :reg add "%key%\shell\play\command" /d "\"%mpv_path%\" %mpv_args% -- \"%%%%L\"" /f

	goto :EOF

:add_progid
	set prog_id=%~1
	set friendly_name=%~2

	:: Add ProgId, edit flags are FTA_OpenIsSafe
	set prog_id_key=%classes_root_key%\%prog_id%
	call :reg add "%prog_id_key%" /d "%friendly_name%" /f
	call :reg add "%prog_id_key%" /v "EditFlags" /t REG_DWORD /d 65536 /f
	call :reg add "%prog_id_key%" /v "FriendlyTypeName" /d "%friendly_name%" /f
	call :reg add "%prog_id_key%\DefaultIcon" /d "%icon_path%" /f
	call :add_verbs "%prog_id_key%"

	goto :EOF

:update_extension
	set extension=%~1
	set prog_id=%~2
	set mime_type=%~3
	set perceived_type=%~4

	:: Add information about the file extension, if not already present
	set extension_key=%classes_root_key%\%extension%
	if not [%mime_type%] == [] call :reg_set_opt "%extension_key%" "Content Type" "%mime_type%"
	if not [%perceived_type%] == [] call :reg_set_opt "%extension_key%" "PerceivedType" "%perceived_type%"
	call :reg add "%extension_key%\OpenWithProgIds" /v "%prog_id%" /f

	:: Add type to SupportedTypes
	call :reg add "%supported_types_key%" /v "%extension%" /f

	:: Add type to the Default Programs control panel
	call :reg add "%file_associations_key%" /v "%extension%" /d "%prog_id%" /f

	goto :EOF

:add_type
	set mime_type=%~1
	set perceived_type=%~2
	set friendly_name=%~3
	set extension=%~4

	echo Adding "%extension%" file type

	:: Add ProgId
	set prog_id=io.mpv%extension%
	call :add_progid "%prog_id%" "%friendly_name%"

	:: Add extensions
	:extension_loop
		call :update_extension "%extension%" "%prog_id%" "%mime_type%" "%perceived_type%"

		:: Trailing parameters are additional extensions
		shift /4
		set extension=%~4
		if not [%extension%] == [] goto extension_loop

	goto :EOF
