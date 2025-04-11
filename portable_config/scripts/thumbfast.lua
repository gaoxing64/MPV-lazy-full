--[[
SOURCE_ https://github.com/po5/thumbfast/blob/master/thumbfast.lua
COMMIT_ 9deb0733c4e36938cf90e42ddfb7a19a8b2f4641
文档_ thumbfast.conf

适配多个OSC类脚本的新缩略图引擎

可用的快捷键示例（在 input.conf 中写入）：

 <KEY>   script-binding thumbfast/thumb_rerun    # 重启缩略图的获取（可用来手动修复缩略图卡死）
 <KEY>   script-binding thumbfast/thumb_toggle   # 开/关缩略图预览
 <KEY>   script-message thumb_hwdec toggle       # 开/关缩略图的硬解（可将其中的 {toggle} 参数换成指定的解码API）

]]

local options = {

    socket = "",
    tnpath = "",

    max_height = 360,
    max_width = 360,

    overlay_id = 42,

    spawn_first = false,
    quit_after_inactivity = 0,
    network = false,
    audio = false,
    direct_io = true,            -- Windows only: use native Windows API to write to pipe (requires LuaJIT)

    hwdec = "yes",
    sw_threads = 2,
    binpath = "default",
    min_duration = 0,
    precise = 0,
    quality = 0,                 -- require vf_libplacebo for 3
    frequency = 0.1,
    auto_run = true,

}

mp.utils = require "mp.utils"
mp.options = require "mp.options"
mp.options.read_options(options)

local properties = {}

function subprocess(args, async, callback)
    callback = callback or function() end

    if async then
        return mp.command_native_async({name = "subprocess", playback_only = true, args = args, env = "PATH="..os.getenv("PATH")}, callback)
    else
        return mp.command_native({name = "subprocess", playback_only = false, capture_stdout = true, args = args, env = "PATH="..os.getenv("PATH")})
    end
end

local winapi = {}
if options.direct_io then
    local ffi_loaded, ffi = pcall(require, "ffi")
    if ffi_loaded then
        winapi = {
            ffi = ffi,
            C = ffi.C,
            bit = require("bit"),
            socket_wc = "",

            -- WinAPI constants
            CP_UTF8 = 65001,
            GENERIC_WRITE = 0x40000000,
            OPEN_EXISTING = 3,
            FILE_FLAG_WRITE_THROUGH = 0x80000000,
            FILE_FLAG_NO_BUFFERING = 0x20000000,
            PIPE_NOWAIT = ffi.new("unsigned long[1]", 0x00000001),

            INVALID_HANDLE_VALUE = ffi.cast("void*", -1),

            -- don't care about how many bytes WriteFile wrote, so allocate something to store the result once
            _lpNumberOfBytesWritten = ffi.new("unsigned long[1]"),
        }
        -- cache flags used in run() to avoid bor() call
        winapi._createfile_pipe_flags = winapi.bit.bor(winapi.FILE_FLAG_WRITE_THROUGH, winapi.FILE_FLAG_NO_BUFFERING)

        ffi.cdef[[
            void* __stdcall CreateFileW(const wchar_t *lpFileName, unsigned long dwDesiredAccess, unsigned long dwShareMode, void *lpSecurityAttributes, unsigned long dwCreationDisposition, unsigned long dwFlagsAndAttributes, void *hTemplateFile);
            bool __stdcall WriteFile(void *hFile, const void *lpBuffer, unsigned long nNumberOfBytesToWrite, unsigned long *lpNumberOfBytesWritten, void *lpOverlapped);
            bool __stdcall CloseHandle(void *hObject);
            bool __stdcall SetNamedPipeHandleState(void *hNamedPipe, unsigned long *lpMode, unsigned long *lpMaxCollectionCount, unsigned long *lpCollectDataTimeout);
            int __stdcall MultiByteToWideChar(unsigned int CodePage, unsigned long dwFlags, const char *lpMultiByteStr, int cbMultiByte, wchar_t *lpWideCharStr, int cchWideChar);
        ]]

        winapi.MultiByteToWideChar = function(MultiByteStr)
            if MultiByteStr then
                local utf16_len = winapi.C.MultiByteToWideChar(winapi.CP_UTF8, 0, MultiByteStr, -1, nil, 0)
                if utf16_len > 0 then
                    local utf16_str = winapi.ffi.new("wchar_t[?]", utf16_len)
                    if winapi.C.MultiByteToWideChar(winapi.CP_UTF8, 0, MultiByteStr, -1, utf16_str, utf16_len) > 0 then
                        return utf16_str
                    end
                end
            end
            return ""
        end

    else
        options.direct_io = false
    end
end

local file
local file_bytes = 0
local spawned = false
local disabled = false
local spawn_waiting = false
local spawn_working = false
local script_written = false

local dirty = false

local x, y
local last_x, last_y

local last_seek_time

local effective_w, effective_h = options.max_width, options.max_height
local real_w, real_h
local last_real_w, last_real_h

local script_name

local show_thumbnail = false

local last_has_vid = 0
local has_vid = 0

local file_timer
local file_check_period = 1/60

local client_script = [=[
#!/usr/bin/env bash
MPV_IPC_FD=0; MPV_IPC_PATH="%s"
trap "kill 0" EXIT
while [[ $# -ne 0 ]]; do case $1 in --mpv-ipc-fd=*) MPV_IPC_FD=${1/--mpv-ipc-fd=/} ;; esac; shift; done
if echo "print-text thumbfast" >&"$MPV_IPC_FD"; then echo -n > "$MPV_IPC_PATH"; tail -f "$MPV_IPC_PATH" >&"$MPV_IPC_FD" & while read -r -u "$MPV_IPC_FD" 2>/dev/null; do :; done; fi
]=]

local function get_os()
    local raw_os_name = ""

    if jit and jit.os and jit.arch then
        raw_os_name = jit.os
    else
        if package.config:sub(1,1) == "\\" then
            -- Windows
            local env_OS = os.getenv("OS")
            if env_OS then
                raw_os_name = env_OS
            end
        else
            raw_os_name = subprocess({"uname", "-s"}).stdout
        end
    end

    raw_os_name = (raw_os_name):lower()

    local os_patterns = {
        ["windows"] = "windows",
        ["linux"]   = "linux",

        ["osx"]     = "darwin",
        ["mac"]     = "darwin",
        ["darwin"]  = "darwin",

        ["^mingw"]  = "windows",
        ["^cygwin"] = "windows",

        ["bsd$"]    = "darwin",
        ["sunos"]   = "darwin"
    }

    -- 默认为WIN
    local str_os_name = "windows"

    for pattern, name in pairs(os_patterns) do
        if raw_os_name:match(pattern) then
            str_os_name = name
            break
        end
    end

    return str_os_name
end

local os_name = mp.get_property("platform") or get_os()

if options.socket == "" then
    if os_name == "windows" then
        options.socket = "thumbfast"
    else
        options.socket = "/tmp/thumbfast"
    end
end

if options.tnpath == "" then
    if os_name == "windows" then
        options.tnpath = os.getenv("TEMP").."\\thumbfast.out"
    else
        options.tnpath = "/tmp/thumbfast.out"
    end
end

local unique = mp.utils.getpid()

options.socket = options.socket .. unique
options.tnpath = options.tnpath .. unique

if options.direct_io then
    if os_name == "windows" then
        winapi.socket_wc = winapi.MultiByteToWideChar("\\\\.\\pipe\\" .. options.socket)
    end

    if winapi.socket_wc == "" then
        options.direct_io = false
    end
end

local mpv_path = options.binpath

if mpv_path == "default" or mpv_path == "bundle" then
    if os_name == "darwin" and unique then
        local tmp_path = string.gsub(subprocess({"ps", "-o", "comm=", "-p", tostring(unique)}).stdout, "[\n\r]", "")
        if mpv_path == "bundle" then
            mpv_path = tmp_path
            mpv_path = string.gsub(mpv_path, "/mpv%-bundle$", "/mpv")
        elseif mpv_path == "default" then
            mpv_path = tmp_path
        end
    else
        mpv_path = "mpv"
    end
end

local function auto_ui_scale()
    local display_w, display_h = mp.get_property_number('display-width', 0), mp.get_property_number('display-height', 0)
    local display_aspect = display_w / display_h or 0
    if display_aspect <= 1 then
        return 1
    end
    if display_aspect >=2 then
        return tonumber(string.format('%.2f', display_h / 1080))
    end
    if display_w * display_h > 2304000 then
        return tonumber(string.format('%.2f', math.sqrt(display_w * display_h / 2073600)))
    else
        return 1
    end
end

local function calc_dimensions()
    local width = properties["video-params"] and properties["video-params"]["w"]
    local height = properties["video-params"] and properties["video-params"]["h"]
    if not width or not height then return end

    local scale
    if properties["hidpi-window-scale"] then
        scale = properties["display-hidpi-scale"] or 1
    else
        scale = auto_ui_scale() or 1
    end

    if width / height > options.max_width / options.max_height then
        effective_w = math.floor(options.max_width * scale + 0.5)
        effective_h = math.floor(height / width * effective_w + 0.5)
    else
        effective_h = math.floor(options.max_height * scale + 0.5)
        effective_w = math.floor(width / height * effective_h + 0.5)
    end
end

local info_timer = nil

local auto_run = options.auto_run

local function info(w, h)
    local short_video = mp.get_property_number("duration", 0) <= options.min_duration
    local image = properties["current-tracks/video"] and properties["current-tracks/video"]["image"]
    local albumart = image and properties["current-tracks/video"]["albumart"]

    disabled = (w or 0) == 0 or (h or 0) == 0 or
        has_vid == 0 or
        (properties["demuxer-via-network"] and not options.network) or
        (albumart and not options.audio) or
        (image and not albumart) or
        (short_video and options.min_duration > 0)

    if not auto_run then
        disabled = true
    end

    if info_timer then
        info_timer:kill()
        info_timer = nil
    elseif has_vid == 0 or not disabled then
        info_timer = mp.add_timeout(0.05, function() info(w, h) end)
    end

    local json, err = mp.utils.format_json({width=w, height=h, disabled=disabled, available=true, socket=options.socket, tnpath=options.tnpath, overlay_id=options.overlay_id})
    mp.command_native_async({"script-message", "thumbfast-info", json}, function() end)
end

local function remove_thumbnail_files()
    if file then
        file:close()
        file = nil
        file_bytes = 0
    end
    os.remove(options.tnpath)
    os.remove(options.tnpath..".bgra")
end

local activity_timer

local scale_sw = "fast-bilinear"
local vf_str
local quality = options.quality
local seek_period_raw = options.frequency
local seek_period_cur = seek_period_raw
local precise_raw = options.precise
local precise_cur = precise_raw

if quality == 0 then
    if precise_raw == 2 then
        quality = 2
    elseif precise_raw == 0 then
        quality = 1
    elseif precise_raw == 1 then
        quality = 1
    end
    if options.sw_threads >= 3 then
        quality = 2
        if options.sw_threads >= 6 then
            quality = 3
        end
    elseif options.sw_threads == 1 then
        quality = 1
    end
end

if quality >= 2 then
    scale_sw = "bicublin"
end

local function quality_fin()
    local vf_str_pre = "scale=w="..effective_w..":h="..effective_h
    local vf_str_suffix = "format=fmt=bgra"
    if quality == 1 then
        vf_str = vf_str_pre..":flags=fast_bilinear,"..vf_str_suffix
    elseif quality == 2 then
        vf_str = vf_str_pre..":flags=bicublin,"..vf_str_suffix
        if mp.get_property_number("video-params/sig-peak", 1) > 1 then
            vf_str = vf_str_pre..":flags=bicublin,format=fmt=gbrapf32,zscale=t=linear:npl=203,tonemap=tonemap=hable:desat=0.0,zscale=p=709:t=709:m=709,"..vf_str_suffix
        end
    elseif quality == 3 then
        if mp.get_property_number("video-out-params/max-luma", 1) > 203 then
            vf_str = "lavfi=[libplacebo=w="..effective_w..":h="..effective_h..":colorspace=bt709:color_primaries=bt709:color_trc=bt709:tonemapping=hable:format=bgra]"

            -- 无奈的workaround
            if seek_period_cur < 0.5 then
                seek_period_cur = 0.5
                mp.msg.warn("已延迟请求频率以匹配性能需求")
            end
            if precise_cur == 0 then
                precise_cur = 1
                mp.msg.info("已降低时间轴精度以匹配性能需求")
            end

        else -- down2lv2
            vf_str = vf_str_pre..":flags=bicublin,"..vf_str_suffix

            if seek_period_cur ~= seek_period_raw then
                seek_period_cur = seek_period_raw
            end
            if precise_cur ~= precise_raw then
                precise_cur = precise_raw
            end

        end
    end
    return vf_str
end

local function spawn(time)
    if disabled then return end

    local path = properties["path"]
    if path == nil then return end

    if options.quit_after_inactivity > 0 then
        if show_thumbnail or activity_timer:is_enabled() then
            activity_timer:kill()
        end
        activity_timer:resume()
    end

    local open_filename = properties["stream-open-filename"]
    local ytdl = open_filename and properties["demuxer-via-network"] and path ~= open_filename
    if ytdl then
        path = open_filename
    end

    remove_thumbnail_files()

    local vid = properties["vid"]
    has_vid = vid or 0

    local args = {
        mpv_path, "--config=no", "--terminal=no", "--msg-level=all=no", "--idle=yes", "--keep-open=always",
        "--pause=yes", "--ao=null",
        "--osc=no", "--load-stats-overlay=no", "load-console=no", "load-commands=no", "--load-auto-profiles=no", "--load-select=no", "--load-positioning=no",
        "--clipboard-backends-clr", "--video-osd=no", "--autoload-files=no",
        "--vd-lavc-skiploopfilter=all", "--vd-lavc-skipidct=all", "--vd-lavc-software-fallback=1", "--vd-lavc-fast",
        "--vd-lavc-threads="..options.sw_threads, "--hwdec="..options.hwdec,
        "--edition="..(properties["edition"] or "auto"), "--vid="..(vid or "auto"), "--sub=no", "--audio=no",
        "--start="..time,
        "--gpu-dumb-mode=yes", "--dither-depth=no", "--tone-mapping=clip", "--hdr-compute-peak=no",
        "--sws-allow-zimg=no", "--sws-fast=yes", "--sws-scaler="..scale_sw,
        "--ytdl-format=worst", "--demuxer-readahead-secs=0", "--demuxer-max-bytes=128KiB",
        "--vf="..quality_fin(), "--audio-pitch-correction=no", "--deinterlace=no",
        "--ovc=rawvideo", "--of=image2", "--ofopts=update=1", "--ocopy-metadata=no", "--o="..options.tnpath
    }

    if os_name == "darwin" then
        table.insert(args, "--macos-app-activation-policy=prohibited")
    end

    if os_name == "windows" then
        table.insert(args, "--media-controls=no")
        table.insert(args, "--input-ipc-server="..options.socket)
    elseif not script_written then
        local client_script_path = options.socket..".run"
        local script = io.open(client_script_path, "w+")
        if script == nil then
            mp.msg.error("client script write failed")
            return
        else
            script_written = true
            script:write(string.format(client_script, options.socket))
            script:close()
            subprocess({"chmod", "+x", client_script_path}, true)
            table.insert(args, "--scripts="..client_script_path)
        end
    else
        local client_script_path = options.socket..".run"
        table.insert(args, "--scripts="..client_script_path)
    end

    table.insert(args, path)

    spawned = true
    spawn_waiting = true

    subprocess(args, true,
        function(success, result)
            if spawn_waiting and (success == false or (result.status ~= 0 and result.status ~= -2)) then
                spawned = false
                spawn_waiting = false
                mp.msg.error("mpv subprocess create failed")
                if not spawn_working then -- notify users of required configuration
                    mp.commandv("show-text", "thumbfast 子进程创建失败！", 5)
                end
            elseif success == true and result.status == 0 then
                spawn_working = true
                spawn_waiting = false
            end
        end
    )
end

local function run(command)
    if not spawned then return end

    if options.direct_io then
        local hPipe = winapi.C.CreateFileW(winapi.socket_wc, winapi.GENERIC_WRITE, 0, nil, winapi.OPEN_EXISTING, winapi._createfile_pipe_flags, nil)
        if hPipe ~= winapi.INVALID_HANDLE_VALUE then
            local buf = command .. "\n"
            winapi.C.SetNamedPipeHandleState(hPipe, winapi.PIPE_NOWAIT, nil, nil)
            winapi.C.WriteFile(hPipe, buf, #buf + 1, winapi._lpNumberOfBytesWritten, nil)
            winapi.C.CloseHandle(hPipe)
        end

        return
    end

    local command_n = command.."\n"

    if os_name == "windows" then
        if file and file_bytes + #command_n >= 4096 then
            file:close()
            file = nil
            file_bytes = 0
        end
        if not file then
            file = io.open("\\\\.\\pipe\\"..options.socket, "r+b")
        end
    elseif not file then
        file = io.open(options.socket, "r+")
    end
    if file then
        file_bytes = file:seek("end")
        file:write(command_n)
        file:flush()
    end
end

local function draw(w, h, script)
    if not w or not show_thumbnail then return end

    if x ~= nil then
        mp.command_native_async({name = "overlay-add", id=options.overlay_id, x=x, y=y, file=options.tnpath..".bgra", offset=0, fmt="bgra", w=w, h=h, stride=(4*w)}, function() end)
    elseif script then
        local json, err = mp.utils.format_json({width=w, height=h, x=x, y=y, socket=options.socket, tnpath=options.tnpath, overlay_id=options.overlay_id})
        mp.commandv("script-message-to", script, "thumbfast-render", json)
    end
end

local function real_res(req_w, req_h, filesize)
    local count = filesize / 4
    local diff = (req_w * req_h) - count

    if (properties["video-params"] and properties["video-params"]["rotate"] or 0) % 180 == 90 then
        req_w, req_h = req_h, req_w
    end

    if diff == 0 then
        return req_w, req_h
    else
        local threshold = 5 -- throw out results that change too much
        local long_side, short_side = req_w, req_h
        if req_h > req_w then
            long_side, short_side = req_h, req_w
        end
        for a = short_side, short_side - threshold, -1 do
            if count % a == 0 then
                local b = count / a
                if long_side - b < threshold then
                    if req_h < req_w then return b, a else return a, b end
                end
            end
        end
        return nil
    end
end

local function move_file(from, to)
    if os_name == "windows" then
        os.remove(to)
    end
    -- move the file because it can get overwritten while overlay-add is reading it, and crash the player
    os.rename(from, to)
end

local function seek(fast)
    if last_seek_time then
        if precise_cur == 2 then run("async seek " .. last_seek_time .. " absolute+exact")
        elseif precise_cur == 1 then run("async seek " .. last_seek_time .. " absolute+keyframes")
        elseif precise_cur == 0 then
            run("async seek " .. last_seek_time .. (fast and " absolute+keyframes" or " absolute+exact"))
        end
    end
end

local seek_period_counter = 0
local seek_timer
seek_timer = mp.add_periodic_timer(seek_period_cur, function()
    if seek_period_counter == 0 then
        seek(true)
        seek_period_counter = 1
    else
        if seek_period_counter == 2 then
            seek_timer:kill()
            seek()
        else seek_period_counter = seek_period_counter + 1 end
    end
end)
seek_timer:kill()

local function request_seek()
    if seek_timer:is_enabled() then
        seek_period_counter = 0
    else
        seek_timer:resume()
        seek(true)
        seek_period_counter = 1
    end
end

local function check_new_thumb()
    -- the slave might start writing to the file after checking existance and
    -- validity but before actually moving the file, so move to a temporary
    -- location before validity check to make sure everything stays consistant
    -- and valid thumbnails don't get overwritten by invalid ones
    local tmp = options.tnpath..".tmp"
    move_file(options.tnpath, tmp)
    local finfo = mp.utils.file_info(tmp)
    if not finfo then return false end
    spawn_waiting = false
    local w, h = real_res(effective_w, effective_h, finfo.size)
    if w then -- only accept valid thumbnails
        move_file(tmp, options.tnpath..".bgra")

        real_w, real_h = w, h
        if real_w and (real_w ~= last_real_w or real_h ~= last_real_h) then
            last_real_w, last_real_h = real_w, real_h
            info(real_w, real_h)
        end
        if not show_thumbnail then
            file_timer:kill()
        end
        return true
    end
    return false
end

file_timer = mp.add_periodic_timer(file_check_period, function()
    if check_new_thumb() then
        draw(real_w, real_h, script_name)
    end
end)
file_timer:kill()

local function clear()
    file_timer:kill()
    seek_timer:kill()
    if options.quit_after_inactivity > 0 then
        if show_thumbnail or activity_timer:is_enabled() then
            activity_timer:kill()
        end
        activity_timer:resume()
    end
    last_seek_time = nil
    show_thumbnail = false
    last_x = nil
    last_y = nil
    if script_name then return end
    mp.command_native_async({name = "overlay-remove", id=options.overlay_id}, function() end)
end

local function quit()
    activity_timer:kill()
    if show_thumbnail then
        activity_timer:resume()
        return
    end
    run("quit")
    spawned = false
    real_w, real_h = nil, nil
    clear()
end

activity_timer = mp.add_timeout(options.quit_after_inactivity, quit)
activity_timer:kill()

local function thumb(time, r_x, r_y, script)
    if disabled then return end

    time = tonumber(time)
    if time == nil then return end

    if r_x == "" or r_y == "" then
        x, y = nil, nil
    else
        x, y = math.floor(r_x + 0.5), math.floor(r_y + 0.5)
    end

    script_name = script
    if last_x ~= x or last_y ~= y or not show_thumbnail then
        show_thumbnail = true
        last_x, last_y = x, y
        draw(real_w, real_h, script)
    end

    if options.quit_after_inactivity > 0 then
        if show_thumbnail or activity_timer:is_enabled() then
            activity_timer:kill()
        end
        activity_timer:resume()
    end

    if time == last_seek_time then return end
    last_seek_time = time
    if not spawned then spawn(time) end
    request_seek()
    if not file_timer:is_enabled() then file_timer:resume() end
end

local function watch_changes()
    if not dirty or not properties["video-params"] then return end
    dirty = false

    local old_w = effective_w
    local old_h = effective_h

    calc_dimensions()

    local resized = old_w ~= effective_w or old_h ~= effective_h

    if resized then
        info(effective_w, effective_h)
    elseif last_has_vid ~= has_vid and has_vid ~= 0 then
        info(effective_w, effective_h)
    end

    if spawned then
        if resized then
            -- mpv doesn't allow us to change output size
            local seek_time = last_seek_time
            run("quit")
            clear()
            spawned = false
            spawn(seek_time or mp.get_property_number("time-pos", 0))
            file_timer:resume()
        end
    end

    last_has_vid = has_vid

    if not spawned and not disabled and options.spawn_first and resized then
        spawn(mp.get_property_number("time-pos", 0))
        file_timer:resume()
    end
end

local function update_property(name, value)
    properties[name] = value
end

local function update_property_dirty(name, value)
    properties[name] = value
    dirty = true
end

local function update_tracklist(name, value)
    -- current-tracks shim
    for _, track in ipairs(value) do
        if track.type == "video" and track.selected then
            properties["current-tracks/video"] = track
            return
        end
    end
end

local function sync_changes(prop, val)
    update_property(prop, val)
    if val == nil then return end

    if type(val) == "boolean" then
        if prop == "vid" then
            has_vid = 0
            last_has_vid = 0
            info(effective_w, effective_h)
            clear()
            return
        end
        val = val and "yes" or "no"
    end

    if prop == "vid" then
        has_vid = 1
    end

    if not spawned then return end

    run("set "..prop.." "..val)
    dirty = true
end

local function file_load()
    clear()
    spawned = false
    real_w, real_h = nil, nil
    last_real_w, last_real_h = nil, nil
    last_seek_time = nil
    if info_timer then
        info_timer:kill()
        info_timer = nil
    end

    calc_dimensions()
    info(effective_w, effective_h)
end

local function shutdown()
    run("quit")
    remove_thumbnail_files()
    if os_name ~= "windows" then
        os.remove(options.socket)
        os.remove(options.socket..".run")
    end
end

mp.observe_property("current-tracks/video", "native", function(name, value)
    update_property(name, value)
end)

mp.observe_property("track-list", "native", update_tracklist)
mp.observe_property("display-hidpi-scale", "native", update_property_dirty)
mp.observe_property("video-params", "native", update_property_dirty)
mp.observe_property("demuxer-via-network", "native", update_property)
mp.observe_property("stream-open-filename", "native", update_property)
mp.observe_property("path", "native", update_property)
mp.observe_property("vid", "native", sync_changes)
mp.observe_property("edition", "native", sync_changes)

mp.register_script_message("thumb", thumb)
mp.register_script_message("clear", clear)

mp.register_event("file-loaded", file_load)
mp.register_event("shutdown", shutdown)

mp.add_key_binding(nil, "thumb_rerun", function()
    clear()
    shutdown()
    auto_run = true
    file_load()
    mp.osd_message("缩略图功能已重启", 2)
end)
mp.add_key_binding(nil, "thumb_toggle", function()
    if auto_run then
        auto_run = false
        file_load()
        shutdown()
        mp.osd_message("缩略图功能已禁用", 2)
    else
        auto_run = true
        file_load()
        mp.osd_message("缩略图功能已启用", 2)
    end
end)
mp.register_script_message("thumb_hwdec", function(hwdec_api)
    local hwdec_api_cur = options.hwdec
    if hwdec_api_cur == hwdec_api then return end
    if hwdec_api == "toggle" then
        if hwdec_api_cur == "no" then
            hwdec_api = "yes"
        else
            hwdec_api = "no"
        end
    end
    options.hwdec = hwdec_api
    mp.osd_message("缩略图已变更首选解码API：" .. hwdec_api, 2)
    clear()
    shutdown()
    file_load()
end)

mp.register_idle(watch_changes)
