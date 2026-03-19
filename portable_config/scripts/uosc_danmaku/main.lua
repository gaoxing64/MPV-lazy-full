VERSION = "3.0.0"

mp.commandv('script-message', 'uosc_danmaku-version', VERSION)

local msg = require('mp.msg')
local utils = require("mp.utils")

AES = require("modules/aes")
Base64 = require("modules/base64")
MD5 = require("modules/md5")
Sha256 = require("modules/hash")

require("modules/options")
require("modules/utils")
require("modules/parse")
require("modules/guess")
require('modules/render')
require('modules/menu')
require("modules/update")

require("apis/dandanplay")
require('apis/extra')

DANMAKU_PATH = os.getenv("TEMP") or "/tmp/"
HISTORY_PATH = mp.command_native({"expand-path", options.history_path})
PID = utils.getpid()
DANMAKU = {sources = {}, count = 1}
DELAYS = {}
ENABLED, COMMENTS, DELAY = false, nil, 0
DELAY_PROPERTY = string.format("user-data/%s/danmaku-delay", mp.get_script_name())
mp.set_property_native(DELAY_PROPERTY, 0)
HAS_DANMAKU = string.format("user-data/%s/has-danmaku", mp.get_script_name())
mp.set_property_bool(HAS_DANMAKU, false)
KEY = table_to_zero_indexed({
    0x00,0x01,0x02,0x03,0x04,
    0x05,0x06,0x07,0x08,0x09,
    0x0a,0x0b,0x0c,0x0d,0x0e,
    0x0f,0x10,0x11,0x12,0x13,
    0x14,0x15,0x16,0x17,0x18,
    0x19,0x1a,0x1b,0x1c,0x1d,
    0x1e,0x1f
})
local attempted_automatch_urls = {}
local load_danmaku_timer = nil

PLATFORM = (function()
    local platform = mp.get_property_native("platform")
    if platform then
        if itable_index_of({ "windows", "darwin" }, platform) then
            return platform
        end
    else
        if os.getenv("windir") ~= nil then
            return "windows"
        end
        local homedir = os.getenv("HOME")
        if homedir ~= nil and string.sub(homedir, 1, 6) == "/Users" then
            return "darwin"
        end
    end
    return "linux"
end)()

function get_danmaku_visibility()
    local history_json = read_file(HISTORY_PATH)
    local history
    if history_json ~= nil then
        history = utils.parse_json(history_json) or {}
        local flag = history["show_danmaku"]
        if flag == nil then
            history["show_danmaku"] = false
            write_json_file(HISTORY_PATH, history)
        else
            return flag
        end
    else
        history = {}
        history["show_danmaku"] = false
        write_json_file(HISTORY_PATH, history)
    end
    return false
end

function set_danmaku_visibility(flag)
    local history = {}
    local history_json = read_file(HISTORY_PATH)
    if history_json ~= nil then
        history = utils.parse_json(history_json) or {}
    end
    history["show_danmaku"] = flag
    write_json_file(HISTORY_PATH, history)
end

function set_danmaku_button()
    if get_danmaku_visibility() then
        mp.commandv("script-message-to", "uosc", "set", "show_danmaku", "on")
    end
end

function show_loaded(init)
    if DANMAKU.anime and DANMAKU.episode then
        show_message("匹配内容：" .. DANMAKU.anime .. "-" .. DANMAKU.episode .. "\\N弹幕加载成功，共计" .. #COMMENTS .. "条弹幕", 3)
        if init then
            msg.info(DANMAKU.anime .. "-" .. DANMAKU.episode .. " 弹幕加载成功，共计" .. #COMMENTS .. "条弹幕")
        end
    else
        show_message("弹幕加载成功，共计" .. #COMMENTS .. "条弹幕", 3)
    end
end

local function get_cid()
    local cid, danmaku_id = nil, nil
    local tracks = mp.get_property_native("track-list")
    for _, track in ipairs(tracks) do
        if track["lang"] == "danmaku" then
            cid = track["external-filename"]:match("/(%d-)%.xml$")
            danmaku_id = track["id"]
            break
        end
    end
    return cid, danmaku_id
end

local function extract_between_colons(input_string)
    local start_index = 0
    local end_index = 0
    local count = 0
    for i = 1, #input_string do
        if input_string:sub(i, i) == ":" then
            count = count + 1
            if count == 2 then
                start_index = i
            elseif count == 3 then
                end_index = i
                break
            end
        end
    end
    if start_index > 0 and end_index > 0 then
        return input_string:sub(start_index + 1, end_index - 1)
    else
        return nil
    end
end

local function hex_to_int_color(hex_color)
    -- 移除颜色代码中的'#'字符
    hex_color = hex_color:sub(2)  -- 只保留颜色代码部分

    -- 提取R, G, B的十六进制值并转为整数
    local r = tonumber(hex_color:sub(1, 2), 16)
    local g = tonumber(hex_color:sub(3, 4), 16)
    local b = tonumber(hex_color:sub(5, 6), 16)
    local color_int = (r * 256 * 256) + (g * 256) + b
    return color_int
end

local function get_type_from_position(position)
    if position == 0 then return 1 end
    if position == 1 then return 4 end
    return 5
end

-- 获取指定时间的延迟
function get_delay_for_time(delay_segments, time)
    if not delay_segments or #delay_segments == 0 then return 0 end
    table.sort(delay_segments, function(a, b) return a.start < b.start end)
    local applied_delay = 0
    for i = 1, #delay_segments do
        local seg = delay_segments[i]
        local delay = tonumber(seg.delay)
        if time >= seg.start and delay then
            applied_delay = applied_delay + delay
        else
            break
        end
    end
    return applied_delay
end

local function merge_delay_segments(segments)
    if not segments or #segments == 0 then return {} end
    local NEAREST_THRESHOLD = 10  -- 最邻近段合并阈值
    local MERGE_THRESHOLD = 30    -- 跨段合并阈值
    local EPSILON = 1e-6          -- 判断接近 0 的阈值

    table.sort(segments, function(a, b) return a.start < b.start end)

    local partially_merged = {}
    local i = 1
    while i <= #segments do
        local cur = segments[i]
        local next_seg = segments[i + 1]
        if next_seg and (next_seg.start - cur.start) <= NEAREST_THRESHOLD then
            local combined_delay = tonumber(cur.delay) + tonumber(next_seg.delay)
            if math.abs(combined_delay) > EPSILON then
                table.insert(partially_merged, {
                    start = cur.start,
                    delay = combined_delay
                })
            end
            i = i + 2
        else
            if math.abs(tonumber(cur.delay)) > EPSILON then
                table.insert(partially_merged, cur)
            end
            i = i + 1
        end
    end

    local merged = {}
    for _, seg in ipairs(partially_merged) do
        local merged_flag = false
        for idx, m in ipairs(merged) do
            if math.abs(seg.start - m.start) <= MERGE_THRESHOLD then
                m.delay = tonumber(m.delay) + tonumber(seg.delay)
                if math.abs(m.delay) <= EPSILON then
                    table.remove(merged, idx)
                end
                merged_flag = true
                break
            end
        end
        if not merged_flag then
            if math.abs(tonumber(seg.delay)) > EPSILON then
                table.insert(merged, {
                    start = seg.start,
                    delay = seg.delay
                })
            end
        end
    end

    table.sort(merged, function(a, b) return a.start < b.start end)
    return merged
end

local function set_danmaku_delay(dly, time)
    for url, source in pairs(DANMAKU.sources) do
        if source.data and not source.blocked then
            source.delay_segments = source.delay_segments or {}
            if dly == 0 then
                source.delay_segments = {}
            elseif time then
                table.insert(source.delay_segments, {start = time, delay = dly})
            else
                table.insert(source.delay_segments, {start = 0, delay = dly})
            end

            source.delay = nil
            table.sort(source.delay_segments, function(a, b) return a.start < b.start end)
            add_source_to_history(url, source)
        end
    end

    if time then
        table.insert(DELAYS, {start = time, delay = dly})
    else
        table.insert(DELAYS, {start = 0, delay = dly})
    end

    if dly == 0 then
        DELAY = 0
        DELAYS = {}
    else
        DELAY = DELAY + dly
    end

    DELAYS = merge_delay_segments(DELAYS)

    if ENABLED and COMMENTS ~= nil then
        render()
    end

    show_message('设置弹幕延迟: ' .. string.format("%.1f", DELAY + 1e-10) .. ' s')
    mp.set_property_native(DELAY_PROPERTY, DELAY)
end

local function clear_source()
    local key = get_cache_key()
    local history_json = read_file(HISTORY_PATH)

    if not key or not history_json then return end

    local history = utils.parse_json(history_json) or {}
    if history[key] == nil then return end

    history[key] = nil
    write_json_file(HISTORY_PATH, history)

    for url, source in pairs(DANMAKU.sources) do
        if source.from == "user_custom" then
            DANMAKU.sources[url] = nil
        end
    end

    load_danmaku(false)

    show_message("已重置当前视频所有弹幕源更改", 3)
    msg.verbose("已重置当前视频所有弹幕源更改")
end

function write_history(episodeid, server)
    local key = get_cache_key()
    if not key then return end
    local history_json = read_file(HISTORY_PATH)
    local history = {}
    if history_json then history = utils.parse_json(history_json) or {} end

    if not history[key] then history[key] = {} end

    local fname = mp.get_property('filename/no-ext')
    local episodeNumber = 0
    if episodeid then
        episodeNumber = tonumber(episodeid) % 1000
    elseif DANMAKU.extra then
        episodeNumber = DANMAKU.extra.episodenum
    end

    if is_protocol(path) then
        local title, season_num, episod_num = parse_title()
        if title and episod_num then
            fname = url_decode(mp.get_property("media-title"))
            episodeNumber = episod_num
        end
    end

    history[key].fname = fname
    history[key].source = DANMAKU.source
    history[key].animeTitle = DANMAKU.anime
    history[key].episodeTitle = DANMAKU.episode
    history[key].episodeNumber = episodeNumber
    if server then history[key].server = server end
    if episodeid then
        history[key].episodeId = episodeid
    elseif DANMAKU.extra then
        history[key].extra = DANMAKU.extra
    end

    write_json_file(HISTORY_PATH, history)
end

function remove_source_from_history(rm_source)
    local history_json = read_file(HISTORY_PATH)
    local key = get_cache_key()
    if history_json then
        local history = utils.parse_json(history_json) or {}

        if history[key] ~= nil and history[key]["sources"] ~= nil then
            for source in pairs(history[key]["sources"]) do
                if source == rm_source then
                    history[key]["sources"][source] = nil
                    break
                end
            end
        end

        write_json_file(HISTORY_PATH, history)
    end
end

function add_source_to_history(add_url, add_source)
    local history_json = read_file(HISTORY_PATH)
    local key = get_cache_key()
    local history = {}
    if history_json then
        history = utils.parse_json(history_json) or {}
    end

    history[key] = history[key] or {}
    local src = history[key]["sources"]
    if type(src) ~= "table" then
        src = {}
    else
        local has_string_key = false
        for k, _ in pairs(src) do
            if type(k) == "string" then
                has_string_key = true
                break
            end
        end
        if not has_string_key then
            src = {}
        end
    end
    history[key]["sources"] = src

    history[key]["sources"][add_url] = history[key]["sources"][add_url] or {}
    local record = history[key]["sources"][add_url]
    record.from = add_source.from or "user_custom"
    record.blocked = add_source.blocked or false

    local delay_segments = shallow_copy(add_source.delay_segments or {})
    if #delay_segments > 0 then
        record.delay_segments = merge_delay_segments(delay_segments)
        if #record.delay_segments == 0 then
            record.delay_segments = nil
        end
    else
        record.delay_segments = nil
    end

    record.delay = nil
    write_json_file(HISTORY_PATH, history)
end



local function read_danmaku_source_record()
    local key = get_cache_key()
    if not key then return nil end
    local history = read_file(HISTORY_PATH)
    if not history then return end
    local history_json = utils.parse_json(history) or {}
    local record = history_json[key]
    if not record or not record.sources then return end

    local sources = record.sources
    local upgraded_sources = {}

    if is_nested_table(sources) then
        for source, data in pairs(sources) do
            local from = data.from or "user_custom"
            local blocked = data.blocked or false
            local delay_segments = shallow_copy(data.delay_segments or {})
            if data.delay ~= nil then
                for i = #delay_segments, 1, -1 do
                    if delay_segments[i].start == 0 then
                        table.remove(delay_segments, i)
                    end
                end
                table.insert(delay_segments, 1, { start = 0, delay = tonumber(data.delay) })
            end
            if #delay_segments > 0 then
                delay_segments = merge_delay_segments(delay_segments)
            else
                delay_segments = nil
            end

            DANMAKU.sources[source] = {
                from = from,
                blocked = blocked,
                delay_segments = delay_segments,
                from_history = true,
            }
        end
    else
        for _, raw in ipairs(sources) do
            local source = raw
            local blocked = false
            local from = raw:match("<(.-)>")
            local delay = raw:match("{{(.-)}}")

            source = source:gsub("<.->", ""):gsub("{{.-}}", "")

            if source:match("^%-") then
                source = source:sub(2)
                blocked = true
                from = from or "api_server"
            end

            local delay_segments = nil
            if delay ~= nil then
                delay_segments = {
                    { start = 0, delay = tonumber(delay) }
                }
            end

            DANMAKU.sources[source] = {
                from = from or "user_custom",
                blocked = blocked,
                delay_segments = delay_segments,
                from_history = true,
            }

            upgraded_sources[source] = shallow_copy(DANMAKU.sources[source])
        end

        if next(upgraded_sources) then
            record.sources = upgraded_sources
            history_json[key] = record
            write_json_file(HISTORY_PATH, history_json)
        end
    end
end

-- 重新加载历史弹幕源的实际数据（支持 URL 变更写回 history，应用集数偏移，且同步更新 episode* / fname）
local function reload_history_danmaku_sources(opts)
    opts = opts or {}
    local fname = opts.fname
    local history_record = opts.history_record
    local episode_offset = tonumber(opts.episode_offset) or 0   -- x
    local api_server     = opts.api_server                      -- history_server
    local target_episode_id = nil
    if not history_record or not history_record.sources then
        msg.verbose("reload_history_danmaku_sources: 没有历史 sources 记录")
        return
    end

    local pending_sources = {}
    local upgraded_urls   = {}  -- { [old_url] = new_url }

    local function add_to_number(n, offset)
        local num = tonumber(n)
        if not num then return nil end
        return num + offset
    end

    local function update_episode_title_with_offset(ep_title, offset)
        if not ep_title or offset == 0 then return ep_title end
        local num = get_episode_number(ep_title)

        if num then
            local new_num = add_to_number(num, offset)
            if new_num then
                return string.format("第%s话", new_num)
            end
        end
        return ep_title
    end

    for url, src in pairs(DANMAKU.sources) do
        if src.from_history then
            local old_url     = url
            local new_url     = url
            local keep_source = true

            -- 有集数偏移时，基于 base_eid 计算新 eid
            if episode_offset ~= 0 then
                local base_eid = src.base_eid

                -- 如果没有 base_eid，则从当前 URL 解析一次，并记录下来
                if not base_eid then
                    local url_old_eid = url:match("/api/v2/comment/(%d+)")
                    if url_old_eid then
                        base_eid = tonumber(url_old_eid)
                        src.base_eid = base_eid
                        msg.verbose(("记录 base_eid=%s 用于后续偏移: %s"):format(url_old_eid, url))
                    else
                        -- 不符合 /api/v2/comment/数字 的源，视作无法对齐集数，丢弃
                        msg.verbose("历史源 url 未匹配到 /api/v2/comment/数字，丢弃: " .. url)
                        DANMAKU.sources[url] = nil
                        keep_source = false
                    end
                end

                -- 使用 base_eid + episode_offset 计算新的 eid
                if keep_source and base_eid then
                    local new_eid     = base_eid + episode_offset
                    local new_eid_str = tostring(new_eid)

                    local before_url = new_url
                    new_url = new_url:gsub("/api/v2/comment/%d+", "/api/v2/comment/" .. new_eid_str, 1)
                end
            end

            if keep_source then
                -- 如果 url 被改写了，迁移记录到新 key
                if new_url ~= old_url then
                    DANMAKU.sources[new_url] = DANMAKU.sources[old_url]
                    DANMAKU.sources[old_url] = nil
                    upgraded_urls[old_url]   = new_url
                    src = DANMAKU.sources[new_url]
                end

                -- 只保留未被 block 且还没加载 data 的源
                if not src.blocked and not src.data then
                    table.insert(pending_sources, new_url)
                end
            end
        end
    end
    local key = get_cache_key()
    if key then
        local history_json = read_file(HISTORY_PATH)
        if history_json then
            local history = utils.parse_json(history_json) or {}
            local record  = history[key]

            if record and record.sources then
                -- 迁移旧 URL 到新 URL
                if next(upgraded_urls) ~= nil then
                    for old_url, new_url in pairs(upgraded_urls) do
                        local src_data = record.sources[old_url]
                        if src_data then
                            if not record.sources[new_url] then
                                record.sources[new_url] = src_data
                            end
                            record.sources[old_url] = nil
                        end
                    end
                end
                if episode_offset ~= 0 then
                    -- episodeNumber
                    if record.episodeNumber then
                        local new_epnum = add_to_number(record.episodeNumber, episode_offset)
                        if new_epnum then
                            msg.verbose(("更新 history.episodeNumber: %s -> %s (x=%d)")
                                :format(tostring(history_record.episodeNumber), tostring(new_epnum), episode_offset))
                            record.episodeNumber = new_epnum
                        end
                    end

                    -- episodeTitle
                    if record.episodeTitle then
                        local new_title = update_episode_title_with_offset(record.episodeTitle, episode_offset)
                        if new_title ~= record.episodeTitle then
                            msg.verbose(("更新 history.episodeTitle: %s -> %s")
                                :format(record.episodeTitle, new_title))
                            record.episodeTitle = new_title
                        end
                    end

                    -- episodeId
                    if record.episodeId then
                        local new_eid = add_to_number(record.episodeId, episode_offset)
                        if new_eid then
                            msg.verbose(("更新 history.episodeId: %s -> %s (x=%d)")
                                :format(tostring(history_record.episodeId), tostring(new_eid), episode_offset))
                            record.episodeId = new_eid
                        end
                    end

                    -- fname
                    if record.fname then
                        if fname ~= record.fname then
                            msg.verbose(("更新 history.fname: %s -> %s")
                                :format(record.fname, fname))
                            record.fname = fname
                        end
                    end
                end

                if record.episodeId then
                    target_episode_id = record.episodeId
                end
                history[key] = record
                write_json_file(HISTORY_PATH, history)
            end
        end
    end
    if not target_episode_id and history_record and history_record.episodeId then
        target_episode_id = history_record.episodeId
    end
    if episode_offset ~= 0 and apply_danmaku_offset_update then
        apply_danmaku_offset_update(episode_offset, api_server)
    end
    if #pending_sources == 0 then
        msg.verbose("没有需要重新加载的历史弹幕源")
        return
    end

    msg.info(string.format("开始重新加载 %d 个历史弹幕源", #pending_sources))

    local loaded_count = 0
    local total_count  = #pending_sources

    local function check_all_loaded()
        loaded_count = loaded_count + 1
        if loaded_count >= total_count then
            ENABLED = true
            set_danmaku_visibility(true)
            set_danmaku_button()
            show_message("所有历史弹幕源加载完成", 3)

            -- 如果是 dandanplay 服务且开启了 load_more_danmaku，则在此处拉取额外源
            if api_server
                and options.load_more_danmaku
                and api_server:find("api%.dandanplay%.")
                and target_episode_id
                and fetch_danmaku_all
            then
                local eid_num = tonumber(target_episode_id)
                if eid_num then
                    msg.info(("尝试从 dandanplay 加载额外弹幕源: episodeId=%d, api=%s")
                        :format(eid_num, api_server))
                    fetch_danmaku_all(eid_num, false, api_server)
                end
            end

            -- 历史源全部加载完，再统一重新 parse & render
            load_danmaku(true, true)
        end
    end

    for _, url in ipairs(pending_sources) do
        local source = DANMAKU.sources[url]
        if not source or source.blocked then
            check_all_loaded()
        else
            if is_protocol(url) then
                -- 在线源
                if url:find("/api/v2/comment/") or url:find("/api/v2/related/") then
                    msg.verbose("重新加载 API 直链源: " .. url)
                    local args = make_danmaku_request_args("GET", url)
                    if args then
                        call_cmd_async(args, function(error, json)
                            if not error and json then
                                local ok, data = pcall(utils.parse_json, json)
                                if ok and data and data.comments then
                                    save_danmaku_data(data.comments, url, source.from)
                                    msg.verbose("成功重新加载: " .. url)
                                end
                            end
                            check_all_loaded()
                        end)
                    else
                        check_all_loaded()
                    end
                else
                    -- 第三方源，通过 extcomment 加载
                    msg.verbose("重新加载第三方源: " .. url)
                    local servers = get_api_servers()
                    local base = servers[1]
                    for _, s in ipairs(servers) do
                        if s:find("api%.dandanplay%.") or s:find("/api/v1/") then
                            base = s
                            break
                        end
                    end
                    local ext_url = base .. "/api/v2/extcomment?url=" .. url_encode(url)
                    local args = make_danmaku_request_args("GET", ext_url)
                    if args then
                        call_cmd_async(args, function(error, json)
                            if not error and json then
                                local ok, data = pcall(utils.parse_json, json)
                                if ok and data and data.comments then
                                    save_danmaku_data(data.comments, url, source.from)
                                    msg.verbose("成功重新加载: " .. url)
                                end
                            end
                            check_all_loaded()
                        end)
                    else
                        check_all_loaded()
                    end
                end
            else
                -- 本地文件源
                msg.verbose("重新加载本地源: " .. url)
                local path = normalize(url)
                if file_exists(path) then
                    local temp_collection = {{
                        type = "file",
                        path = path,
                        url  = url
                    }}
                    local danmaku_list = parse_danmaku_sources(temp_collection, {})
                    if danmaku_list and #danmaku_list > 0 then
                        DANMAKU.sources[url].data = danmaku_list
                        msg.verbose("成功重新加载: " .. url)
                    end
                end
                check_all_loaded()
            end
        end
    end
end

local function get_inherited_delay(target_url, history_record)
    if not history_record or not history_record.sources then return nil end
    if target_url:find("/api/v2/comment/") then return nil end
    if target_url:find("bilibili%.com/video/[BbAa][Vv]") or
       target_url:find("bilibili%.com/combine")
    then
        return nil
    end
    local target_domain = target_url:match("https?://([^/]+)")
    if not target_domain then return nil end
    for url, data in pairs(history_record.sources) do
        if url:find(target_domain, 1, true)
            and data.delay_segments
            and #data.delay_segments > 0
        then
            return data.delay_segments
        end
    end
    return nil
end

-- 收集现有的弹幕源
local function collect_danmaku_sources()
    local danmaku_collection = {}
    local delays = {}
    local key = get_cache_key()
    local history_json = read_file(HISTORY_PATH)
    local history_record = nil
    if history_json and key then
        local h = utils.parse_json(history_json) or {}
        history_record = h[key]
    end

    for url, source in pairs(DANMAKU.sources) do
        if not source.blocked and source.data then
            local delay_segments = source.delay_segments
            if (not delay_segments or #delay_segments == 0) and history_record then
                if history_record.sources and history_record.sources[url] and
                   history_record.sources[url].delay_segments then
                    delay_segments = history_record.sources[url].delay_segments
                else
                    local inherited = get_inherited_delay(url, history_record)
                    if inherited then
                        delay_segments = inherited
                    end
                end
                if delay_segments and #delay_segments > 0 then
                    source.delay_segments = delay_segments
                end
            end

            delay_segments = delay_segments or {}

            table.insert(danmaku_collection, {
                type = "memory",
                data = source.data,
                url = url
            })
            table.insert(delays, delay_segments)
        end
    end
    return danmaku_collection, delays
end

-- 视频播放时保存弹幕
function save_danmaku(not_forced)
    local danmaku_collection, delays = collect_danmaku_sources()
    if #danmaku_collection == 0 then
        show_message("弹幕内容为空，无法保存", 3)
        msg.verbose("弹幕内容为空，无法保存")
        COMMENTS = {}
        return
    end
    local all_danmaku = parse_danmaku_sources(danmaku_collection, delays)
    local path = mp.get_property("path")
    local dir = get_parent_directory(path) or ""
    local filename = mp.get_property('filename/no-ext')
    local danmaku_out = utils.join_path(dir, filename .. ".xml")

    if not path or is_protocol(path) or (not file_exists(danmaku_out)
    and not is_writable(danmaku_out)) then
        show_message("此弹幕文件不支持保存至本地")
        msg.warn("此弹幕文件不支持保存至本地")
    else
        if not_forced and file_exists(danmaku_out) then
            show_message("已存在同名弹幕文件：" .. danmaku_out)
            msg.info("已存在同名弹幕文件：" .. danmaku_out)
            return
        else
            convert_danmaku_to_xml(all_danmaku, danmaku_out)
        end
    end
end

-- 根据当前使用的 API URL，获取剩余可用的服务器列表
function get_remaining_servers(current_api_url)
    local servers = get_api_servers()
    if #servers <= 1 then return nil end

    local current_idx = -1
    for i, server in ipairs(servers) do
        if current_api_url:find(server, 1, true) then
            current_idx = i
            break
        end
    end

    if current_idx ~= -1 and current_idx < #servers then
        local remaining = {}
        for k = current_idx + 1, #servers do
            table.insert(remaining, servers[k])
        end
        return remaining, current_idx, #servers
    end

    return nil
end

local function get_current_server()
    for i, server in ipairs(get_api_servers()) do
        for url, source in pairs(DANMAKU.sources) do
            if source.from == "api_server" and url:find("^http") and url:find(server, 1, true) then
                return server
            end
        end
    end
    return nil
end

local function switch_to_next_server(current_api_url)
    if not current_api_url then return false end

    local remaining, idx, total = get_remaining_servers(current_api_url)
    if remaining then
        msg.info(string.format("准备切换备用列表 (%d/%d)", idx + 1, total))
        show_message(string.format("尝试切换备用API (%d/%d)", idx + 1, total), 3)

        DANMAKU.sources[current_api_url] = nil

        local path = mp.get_property("path")
        local filename = mp.get_property("filename")
        get_danmaku_with_hash(filename, path, remaining)
        return true
    end
    return false
end

local function exec_load_danmaku(from_menu, no_osd)
    if not ENABLED then return end
    local danmaku_collection, delays = collect_danmaku_sources()

    local current_api_url = get_current_server()
    local has_api_server_source = false          -- 有没有任何 api_server 源
    local has_current_server_source = false      -- 有没有属于 current_api_url 的源
    local has_current_server_data   = false      -- current_api_url 下有没有 data
    for url, src in pairs(DANMAKU.sources) do
        if src.from == "api_server" then
            has_api_server_source = true
            if current_api_url and url:find(current_api_url, 1, true) then
                has_current_server_source = true
                if src.data ~= nil then
                    has_current_server_data = true
                end
            end
        end
    end
    if #danmaku_collection == 0 and not from_menu then
        if not has_api_server_source then
            msg.verbose("弹幕列表为空且不存在 api_server 源，不进行自动匹配/切换")
            COMMENTS = {}
            return
        end
        if current_api_url and not has_current_server_source then
            msg.verbose("当前 server 下无弹幕源，尝试切换备用 API")
            if switch_to_next_server(current_api_url) then return end
            COMMENTS = {}
            return
        end
        if current_api_url and not has_current_server_data then
            if not attempted_automatch_urls[current_api_url] then
                attempted_automatch_urls[current_api_url] = true
                msg.info("弹幕为空，尝试调用后台 /api/v2/match 进行匹配修复 (" .. current_api_url .. ")")
                show_message("弹幕为空，正在尝试后台自动匹配...", 3)

                local file_path = mp.get_property("path")
                local file_name = mp.get_property("filename")
                match_file_concurrent(file_path, file_name, function(err)
                    if err then
                        msg.warn("自动匹配失败: " .. tostring(err))
                        if not switch_to_next_server(current_api_url) then
                            show_message("匹配失败且无备用源", 3)
                        end
                    end
                end, {current_api_url})
                return
            end

            -- 已经尝试过自动匹配，再试着切备用 server
            if switch_to_next_server(current_api_url) then return end

            show_message("该集弹幕内容为空，结束加载", 3)
            msg.verbose("该集弹幕内容为空，结束加载")
            COMMENTS = {}
            return
        end

        show_message("该集弹幕内容为空，结束加载", 3)
        msg.verbose("该集弹幕内容为空（未知情形），结束加载")
        COMMENTS = {}
        return
    elseif #danmaku_collection == 0 and from_menu then
        restore_prev_server()
    end

    local all_danmaku = parse_danmaku_sources(danmaku_collection, delays)
    if all_danmaku then
       render_danmaku(all_danmaku, from_menu, no_osd)
    end

    if options.autoload_danmaku_matches and uosc_available and not from_menu then
        mp.add_timeout(0.5, function()
            mp.commandv("script-message", "auto_load_danmaku_matches")
        end)
    end
end

-- 防抖动加载弹幕
function load_danmaku(from_menu, no_osd)
    if load_danmaku_timer then
        load_danmaku_timer:kill()
    end
    load_danmaku_timer = mp.add_timeout(0.2, function()
        load_danmaku_timer = nil
        exec_load_danmaku(from_menu, no_osd)
    end)
end

-- 加载 B 站弹幕
function load_danmaku_for_bilibili(path)
    local cid, danmaku_id = get_cid()
    if danmaku_id ~= nil then
        mp.commandv('sub-remove', danmaku_id)
    end

    if cid == nil then
        cid = mp.get_opt('cid')
        if not cid then
            local patterns = {
                "bilivideo%.c[nom]+.*/resource/(%d+)%D+.*",
                "bilivideo%.c[nom]+.*/(%d+)-%d+-%d+%..*%?",
            }
            local urls = {
                path,
                mp.get_property("stream-open-filename", ''),
            }

            for _, pattern in ipairs(patterns) do
                for _, url in ipairs(urls) do
                    if url:find(pattern) then
                        cid = url:match(pattern)
                        break
                    end
                end
            end
        end
    end
    if cid == nil and path:match("/video/BV.-") then
        if path:match("video/BV.-/.*") then
            path = path:gsub("/[^/]+$", "")
        end
        add_danmaku_source_online(path, true)
        return
    end
    if cid ~= nil then
        local url = "https://comment.bilibili.com/" .. cid .. ".xml"
        local args = {
            "curl",
            "-L", "-s",
            "--compressed",
            "--user-agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36 Edg/124.0.0.0",
            url,
        }

        call_cmd_async(args, function(err, content)
            async_running = false
            if err then
                show_message("HTTP 请求失败，打开控制台查看详情", 5)
                msg.error(err)
                return
            end

            if content and content ~= "" then
                save_danmaku_memory(path, content, "user_custom", "xml")
                load_danmaku(true)
            end
        end)
    end
end

function load_danmaku_for_bahamut(path)
    local path = path:gsub('%%(%x%x)', hex_to_char)
    local sn = extract_between_colons(path)
    if sn == nil then
        return
    end
    local url = "https://ani.gamer.com.tw/ajax/danmuGet.php"
    local args = {
        "curl",
        "-X", "POST",
        "-d", "sn=" .. sn,
        "-L",
        "-s",
        "--user-agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.83 Safari/537.36",
        "--header", "Origin: https://ani.gamer.com.tw",
        "--header", "Content-Type: application/x-www-form-urlencoded;charset=utf-8",
        "--header", "Accept: application/json",
        "--header", "Authority: ani.gamer.com.tw",
        url,
    }
    if options.proxy ~= "" then
        table.insert(args, '-x')
        table.insert(args, options.proxy)
    end

    call_cmd_async(args, function(err, json)
        async_running = false
        if err then
            show_message("HTTP 请求失败，打开控制台查看详情", 5)
            msg.error("Bahamut curl error: " .. err)
            return
        end
        if not json or json == "" then
            local video_url = "https://ani.gamer.com.tw/animeVideo.php?sn=" .. sn
            ENABLED = true
            add_danmaku_source_online(video_url, true)
            return
        end

        local comments = utils.parse_json(json)
        if not comments then
            return
        end
        local danmaku_list = {}
        for _, comment in ipairs(comments) do
            local text = comment["text"]
            local color = hex_to_int_color(comment["color"])
            local mode = get_type_from_position(comment["position"])
            local time = tonumber(comment["time"]) / 10

            table.insert(danmaku_list, {
                time = time,
                color = color,
                type = mode,
                size = 25,
                text = text
            })
        end
        table.sort(danmaku_list, function(a, b) return a.time < b.time end)
        local source_url = "https://ani.gamer.com.tw/animeVideo.php?sn=" .. sn
        if DANMAKU.sources[source_url] == nil then
            DANMAKU.sources[source_url] = {from = "user_custom"}
        end
        DANMAKU.sources[source_url]["data"] = danmaku_list
        load_danmaku(true)
    end)
end

function load_danmaku_for_url(path)
    if path:find('bilibili.com') or path:find('bilivideo.c[nom]+') then
        load_danmaku_for_bilibili(path)
        return
    end

    if path:find('bahamut.akamaized.net') then
        load_danmaku_for_bahamut(path)
        return
    end

    local title, season_num, episod_num = parse_title()
    local filename = url_decode(mp.get_property("media-title"))
    local episod_number = nil
    if title and episod_num then
        episod_number = episod_num
        auto_load_danmaku(path, filename, episod_number)
        addon_danmaku(true, false)
        return
    end
    get_danmaku_with_hash(filename, path)
    addon_danmaku()
end

-- 自动加载上次匹配的弹幕
function auto_load_danmaku(path, filename, number)
    local key = get_cache_key()
    if key ~= nil then
        local history_json = read_file(HISTORY_PATH)
        if history_json ~= nil then
            local history = utils.parse_json(history_json) or {}
            local history_dir = history[key]
            if history_dir ~= nil then
                DANMAKU.anime = history_dir.animeTitle
                local episode_number = history_dir.episodeTitle and get_episode_number(history_dir.episodeTitle)
                local history_number = history_dir.episodeNumber
                local history_id = history_dir.episodeId
                local history_fname = history_dir.fname
                local history_extra = history_dir.extra
                local history_server = history_dir.server or nil
                local playing_number = nil

                if history_fname then
                    if filename ~= history_fname then
                        if number then
                            playing_number = number
                        else
                            history_number, playing_number = get_episode_number(filename, history_fname)
                        end
                    else
                        playing_number = history_number
                    end
                else
                    playing_number = get_episode_number(filename)
                end
                if playing_number ~= nil then
                    local x = playing_number - history_number -- 获取集数差值
                    DANMAKU.episode = episode_number and string.format("第%s话", episode_number + x) or history_dir.episodeTitle
                    show_message("自动加载上次匹配的弹幕", 3)
                    msg.verbose("自动加载上次匹配的弹幕")
                    if history_dir.sources and next(history_dir.sources) ~= nil then
                        reload_history_danmaku_sources({
                            fname = filename,
                            history_record = history_dir,
                            episode_offset = x,
                            api_server     = history_server, -- 当前使用的 dandanplay server（若是）
                        })
                    elseif history_id then
                        local tmp_id = tostring(x + history_id)
                        set_episode_id(tmp_id, history_server)
                        apply_danmaku_offset_update(x, history_server)
                    elseif history_extra then
                        local episodenum = history_extra.episodenum + x
                        get_details(history_extra.class, history_extra.id, history_extra.site,
                            history_extra.title, history_extra.year, history_extra.number, episodenum)
                    end
                else
                    get_danmaku_with_hash(filename, path)
                end
            else
                get_danmaku_with_hash(filename, path)
            end
        else
            get_danmaku_with_hash(filename, path)
        end
    end
end

function init(path)
    if not path then return end
    local dir = get_parent_directory(path)
    local filename = mp.get_property('filename/no-ext')
    local video = mp.get_property_native("current-tracks/video")
    local duration = mp.get_property_number("duration", 0)
    if not video or video["image"] or video["albumart"] or duration < 60 then
        msg.info("不支持的播放内容（非视频）")
        return
    end
    if is_protocol(path) then
        load_danmaku_for_url(path)
    end
    if dir and filename then
        local danmaku_xml = utils.join_path(dir, filename .. ".xml")
        if file_exists(danmaku_xml) then
            add_danmaku_source_local(danmaku_xml, true)
        else
            auto_load_danmaku(path, filename)
            addon_danmaku(true, true)
        end
    end
end

mp.register_event("file-loaded", function()
    local path = mp.get_property("path")
    local dir = get_parent_directory(path)
    local filename = mp.get_property('filename/no-ext')
    local video = mp.get_property_native("current-tracks/video")
    local fps = mp.get_property_number("container-fps", 0)
    local duration = mp.get_property_number("duration", 0)
    attempted_automatch_urls = {} -- 重置尝试过的自动匹配 URL 列表
    if not video or video["image"] or video["albumart"] or fps < 23 or duration < 60 then
        return
    end

    read_danmaku_source_record()

    if not get_danmaku_visibility() then
        return
    end

    if options.autoload_for_url and is_protocol(path) then
        ENABLED = true
        load_danmaku_for_url(path)
    end

    if filename == nil or dir == nil then
        return
    end
    local danmaku_xml = utils.join_path(dir, filename .. ".xml")
    if options.autoload_local_danmaku then
        if file_exists(danmaku_xml) then
            ENABLED = true
            add_danmaku_source_local(danmaku_xml)
            return
        end
    end

    if options.auto_load then
        ENABLED = true
        auto_load_danmaku(path, filename)
        addon_danmaku(true, false)
        return
    end

    if ENABLED and COMMENTS == nil and not async_running then
        init(path)
    end

    -- 在文件加载时自动加载匹配结果（用于弹幕源选择菜单）
    if uosc_available and path and options.autoload_danmaku_matches then
        mp.add_timeout(1.0, function()
            if ENABLED then
                mp.commandv("script-message", "auto_load_danmaku_matches")
            end
        end)
    end
end)

-------------- 键位绑定 --------------
mp.add_key_binding(options.open_search_danmaku_menu_key, "open_search_danmaku_menu", function()
    mp.commandv("script-message", "open_search_danmaku_menu")
end)
mp.add_key_binding(options.show_danmaku_keyboard_key, "show_danmaku_keyboard", function()
    mp.commandv("script-message", "show_danmaku_keyboard")
end)

mp.register_script_message("danmaku-delay", function(...)
    local commands = {...}
    local delay_str, time_str = commands[1], commands[2]
    local dly = tonumber(delay_str)
    local time = time_str and tonumber(time_str)
    if type(dly) ~= "number" then
        show_message("参数错误：缺少有效的延迟秒数", 3)
        return
    end
    set_danmaku_delay(dly, time)
end)

mp.register_script_message("show_danmaku_keyboard", function()
    ENABLED = not ENABLED
    if ENABLED then
        show_message("开启弹幕", 2)
        mp.commandv("script-message-to", "uosc", "set", "show_danmaku", "on")
        if COMMENTS == nil then
            set_danmaku_visibility(true)
            show_message("加载弹幕初始化...", 3)
            local path = mp.get_property("path")
            init(path)
        else
            show_loaded()
            show_danmaku_func()
        end
    else
        show_message("关闭弹幕", 2)
        mp.commandv("script-message-to", "uosc", "set", "show_danmaku", "off")
        hide_danmaku_func()
    end
end)

mp.register_script_message("check-update", check_for_update)
mp.register_script_message("clear-source", clear_source)
mp.register_script_message("immediately_save_danmaku", save_danmaku)
mp.register_script_message("open_source_delay_menu", danmaku_delay_setup)
mp.register_script_message("open_search_danmaku_menu", open_input_menu)
mp.register_script_message("open_add_source_menu", open_add_menu)
mp.register_script_message("open_add_total_menu", open_add_total_menu)
