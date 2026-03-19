local msg   = require 'mp.msg'
local utils = require 'mp.utils'
local s2t   = require("dicts/s2t_chars")
local t2s   = require("dicts/t2s_chars")

local function ass_escape(text)
    return text:gsub("\\", "\\\\")
               :gsub("{", "\\{")
               :gsub("}", "\\}")
               :gsub("\n", "\\N")
end

local function xml_unescape(str)
    return str:gsub("&quot;", "\"")
              :gsub("&apos;", "'")
              :gsub("&gt;", ">")
              :gsub("&lt;", "<")
              :gsub("&amp;", "&")
end

local function decode_html_entities(text)
    return text:gsub("&#x([%x]+);", function(hex)
        local codepoint = tonumber(hex, 16)
        return unicode_to_utf8(codepoint)
    end):gsub("&#(%d+);", function(dec)
        local codepoint = tonumber(dec, 10)
        return unicode_to_utf8(codepoint)
    end)
end

-- 加载黑名单模式
local function load_blacklist_patterns(filepath)
    local patterns = {}
    if not file_exists(filepath) then
        return patterns
    end
    local file = io.open(filepath, "r")
    if not file then
        msg.error("无法打开黑名单文件: " .. filepath)
        return patterns
    end

    for line in file:lines() do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" then
            table.insert(patterns, line)
        end
    end

    file:close()
    return patterns
end

local blacklist_file = mp.command_native({ "expand-path", options.blacklist_path })
local black_patterns = load_blacklist_patterns(blacklist_file)

-- 检查字符串是否在黑名单中
function is_blacklisted(str, patterns)
    for _, pattern in ipairs(patterns) do
        local ok, result = pcall(function()
            return str:match(pattern)
        end)

        if ok and result then
            return true, pattern
        elseif not ok then
            -- msg.debug("黑名单规则错误，跳过: " .. pattern .. "，错误信息：" .. result)
        end
    end
    return false
end

-- 简繁转换
local function convert(text, dict)
    return text:gsub("[%z\1-\127\194-\244][\128-\191]*", function(c)
        return dict[c] or c
    end)
end

local function ch_convert(str)
    if options.chConvert == 1 then
        return convert(str, t2s)
    elseif options.chConvert == 2 then
        return convert(str, s2t)
    end
    return str
end

local ch_convert_cache = {}
local ch_cache_keys = {}
local ch_cache_max = 5000

local function ch_convert_cached(text)
    if type(text) ~= "string" or text == "" then return text end
    local cached = ch_convert_cache[text]
    if cached ~= nil then return cached end

    local converted = ch_convert(text)
    ch_convert_cache[text] = converted
    ch_cache_keys[#ch_cache_keys+1] = text

    if #ch_cache_keys > ch_cache_max then
        local old_key = table.remove(ch_cache_keys, 1)
        ch_convert_cache[old_key] = nil
    end

    return converted
end

-- 合并重复弹幕
local function merge_duplicate_danmaku(danmakus, threshold)
    if not threshold or tonumber(threshold) < 0 then return danmakus end

    local groups = {}

    for _, d in ipairs(danmakus) do
        local key = d.type .. "|" .. d.color .. "|" .. d.text
        if not groups[key] then groups[key] = {} end
        table.insert(groups[key], d)
    end

    local merged = {}

    for _, group in pairs(groups) do
        table.sort(group, function(a, b) return a.time < b.time end)

        local i = 1
        while i <= #group do
            local base = group[i]
            local times = { base.time }
            local count = 1
            local j = i + 1

            while j <= #group and math.abs(group[j].time - base.time) <= threshold do
                table.insert(times, group[j].time)
                count = count + 1
                j = j + 1
            end

            local same_time = true
            for k = 2, #times do
                if times[k] ~= times[1] then
                    same_time = false
                    break
                end
            end

            local danmaku = {
                time = base.time,
                type = base.type,
                size = base.size,
                color = base.color,
                text = base.text,
                source = base.source,
            }
            if count > 2 or not same_time then
                danmaku.text = danmaku.text .. string.format("x%d", count)
            end

            table.insert(merged, danmaku)
            i = j
        end
    end

    table.sort(merged, function(a, b) return a.time < b.time end)
    return merged
end

-- 限制每屏弹幕条数
local function limit_danmaku(danmakus, limit)
    if not limit or limit <= 0 then
        return danmakus
    end

    local window = {}
    for _, d in ipairs(danmakus) do
        for i = #window, 1, -1 do
            if window[i].end_time <= d.start_time then
                table.remove(window, i)
            end
        end

        if #window < limit then
            table.insert(window, d)
        else
            local max_idx = 1
            for i = 2, #window do
                if window[i].end_time > window[max_idx].end_time then
                    max_idx = i
                end
            end
            if window[max_idx].end_time > d.end_time then
                window[max_idx].drop = true
                window[max_idx] = d
            else
                d.drop = true
            end
        end
    end

    local result = {}
    for _, d in ipairs(danmakus) do
        if not d.drop then
            table.insert(result, d)
        end
    end
    return result
end

-- 解析 XML 弹幕
local function parse_xml_danmaku(xml_string, delay_segments)
    local danmakus = {}
    -- [^>]* 匹配其他 attributes
    -- %f[^%s] 确保 p= 前面是空白字符
    for p_attr, text in xml_string:gmatch('<d%s+[^>]*%f[^%s]p="([^"]+)"[^>]*>([^<]+)</d>') do
        local params = {}
        local i = 1
        for val in p_attr:gmatch("([^,]+)") do
            params[i] = tonumber(val)
            i = i + 1
        end

        if params[1] and params[2]  and params[3] and params[4] then
            local base_time = params[1]
            local delay = get_delay_for_time(delay_segments, base_time)
            table.insert(danmakus, {
                time = base_time + delay,
                type = params[2] or 1,
                size = params[3] or 25,
                color = params[4] or 0xFFFFFF,
                text = xml_unescape(text)
            })
        end
    end

    table.sort(danmakus, function(a, b) return a.time < b.time end)
    return danmakus
end

-- 解析 JSON 弹幕
local function parse_json_danmaku(json_string, delay_segments)
    local danmakus = {}
    if json_string:sub(1, 3) == "\239\187\191" then
        json_string = json_string:sub(4)
    end

    local json = utils.parse_json(json_string)
    if not json or type(json) ~= "table" then
        msg.info("JSON 解析失败")
        return danmakus
    end

    for _, entry in ipairs(json) do
        local c = entry.c
        local text = entry.m or ""
        if type(c) == "string" then
            local params = {}
            local i = 1
            for val in c:gmatch("([^,]+)") do
                params[i] = tonumber(val)
                i = i + 1
            end

            if params[1] and params[2] and params[3] and params[4] then
                local base_time = tonumber(params[1]) or 0
                local delay = get_delay_for_time(delay_segments, base_time)
                table.insert(danmakus, {
                    time = base_time + delay,
                    color = params[2] or 0xFFFFFF,
                    type = params[3] or 1,
                    size = params[4] or 25,
                    text = text
                })
            end
        end
    end

    table.sort(danmakus, function(a, b) return a.time < b.time end)
    return danmakus
end

-- 解析弹幕文件
function parse_danmaku_sources(collection, delays)
    local all_danmaku = {}

    for i, item in ipairs(collection) do
        local parsed = {}
        local delay_segments = delays and delays[i] or {}
        local source_url = item.url
        
        if item.type == "memory" then
            if type(item.data) == "string" then
                local content = item.data
                if content:match("^<%?xml") or content:match("^<d p=") then
                    parsed = parse_xml_danmaku(content, delay_segments)
                elseif content:match("^%[") or content:match("^{") then
                    parsed = parse_json_danmaku(content, delay_segments)
                end
            else
                local status, copy = pcall(utils.parse_json, utils.format_json(item.data))
                if status then parsed = copy else parsed = item.data end
            end
        elseif item.type == "file" then
            local path = item.path
            local content = read_file(path)
            if content then
                if path:match("%.xml$") then
                    parsed = parse_xml_danmaku(content, delay_segments)
                elseif path:match("%.json$") then
                    parsed = parse_json_danmaku(content, delay_segments)
                end
            end
        end
        if parsed and type(parsed) == "table" then
            for _, d in ipairs(parsed) do
                local matched, pattern = is_blacklisted(d.text, black_patterns)
                if not matched then
                    d.text = ch_convert_cached(d.text)
                    if source_url then d.source = source_url end
                    -- 应用延迟
                    if item.type == "memory" then
                        local d_delay = get_delay_for_time(delay_segments, d.time)
                        d.time = d.time + d_delay
                    end
                    table.insert(all_danmaku, d)
                else
                    -- msg.debug("命中黑名单: " .. pattern)
                end
            end
        end
    end
    if #all_danmaku == 0 then
        show_message("未能解析任何弹幕", 3)
        msg.info("未能解析任何弹幕")
        return nil
    end

    if options.max_screen_danmaku > 0 and options.merge_tolerance <= 0 then
        options.merge_tolerance = options.scrolltime
    end

    -- 按时间排序
    table.sort(all_danmaku, function(a, b)
        return a.time < b.time
    end)

    all_danmaku = merge_duplicate_danmaku(all_danmaku, options.merge_tolerance)
    return all_danmaku
end

function convert_danmaku_to_xml(all_danmaku, danmaku_out)
   if not all_danmaku or #all_danmaku == 0 then
        return false
   end

    -- 拼接为 XML 内容
    local xml = { '<?xml version="1.0" encoding="UTF-8"?><i>\n' }
    for _, d in ipairs(all_danmaku) do
        local time = d.time
        local type = d.type or 1
        local size = d.size or 25
        local color = d.color or 0xFFFFFF
        local text = d.text or ""

        text = text:gsub("&", "&amp;")
                   :gsub("<", "&lt;")
                   :gsub(">", "&gt;")
                   :gsub("\"", "&quot;")
                   :gsub("'", "&apos;")

        table.insert(xml, string.format('<d p="%s,%s,%s,%s">%s</d>\n', time, type, size, color, text))
    end
    table.insert(xml, '</i>')
    local file = io.open(danmaku_out, "w")
    if not file then
        msg.info("无法写入目标 XML 文件: " .. danmaku_out)
        return false
    end
    file:write(table.concat(xml))
    file:close()
    msg.info("保存 XML 弹幕文件成功: " .. danmaku_out)
    return true
end