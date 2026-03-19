-- modified from https://github.com/rkscv/danmaku/blob/main/danmaku.lua
local msg = require('mp.msg')
local utils = require("mp.utils")

local INTERVAL = options.vf_fps and 0.01 or 0.001
local osd_width, osd_height, pause = 0, 0, true

--# 弹幕数组与布局算法 (Danmaku Array & Layout Algorithms)
local DanmakuArray = {}
DanmakuArray.__index = DanmakuArray

function DanmakuArray:new(res_x, res_y, font_size)
    local obj = {
        solution_y = res_y,
        font_size = font_size,
        rows = math.floor(res_y / font_size),
        time_length_array = {}
    }
    for i = 1, obj.rows do
        obj.time_length_array[i] = { time = -1, length = 0 }
    end
    setmetatable(obj, self)
    return obj
end

function DanmakuArray:set_time_length(row, time, length)
    if row > 0 and row <= self.rows then
        self.time_length_array[row] = { time = time, length = length }
    end
end

function DanmakuArray:get_time(row)
    if row > 0 and row <= self.rows then
        return self.time_length_array[row].time
    end
    return -1
end

function DanmakuArray:get_length(row)
    if row > 0 and row <= self.rows then
        return self.time_length_array[row].length
    end
    return 0
end

-- 滚动弹幕 Y 坐标算法
local function get_position_y(font_size, appear_time, text_length, resolution_x, roll_time, array)
    local velocity = (text_length + resolution_x) / roll_time

    for i = 1, array.rows do
        local previous_appear_time = array:get_time(i)
        if array:get_time(i) < 0 then
            array:set_time_length(i, appear_time, text_length)
            return 1 + (i - 1) * font_size
        end

        local previous_length = array:get_length(i)
        local previous_velocity = (previous_length + resolution_x) / roll_time
        local delta_velocity = velocity - previous_velocity
        local delta_x = (appear_time - previous_appear_time) * previous_velocity - previous_length

        if delta_x >= 0 then
            if delta_velocity <= 0 then
                array:set_time_length(i, appear_time, text_length)
                return 1 + (i - 1) * font_size
            end

            local delta_time = delta_x / delta_velocity
            if delta_time >= roll_time then
                array:set_time_length(i, appear_time, text_length)
                return 1 + (i - 1) * font_size
            end
        end
    end
    return nil
end

-- 固定弹幕 Y 坐标算法
local function get_fixed_y(font_size, appear_time, fixtime, array, from_top)
    local row_start, row_end, row_step
    if from_top then
        row_start, row_end, row_step = 1, array.rows, 1
    else
        row_start, row_end, row_step = array.rows, 1, -1
    end

    for i = row_start, row_end, row_step do
        local previous_appear_time = array:get_time(i)
        if previous_appear_time < 0 then
            array:set_time_length(i, appear_time, 0)
            return (i - 1) * font_size + 1
        else
            local delta_time = appear_time - previous_appear_time
            if delta_time > fixtime then
                array:set_time_length(i, appear_time, 0)
                return (i - 1) * font_size + 1
            end
        end
    end
    return nil
end

-- 提取 \move 参数 (x1, y1, x2, y2) 并返回
local function parse_move_tag(text)
    -- 匹配包括小数和负数在内的坐标值
    local x1, y1, x2, y2 = text:match("\\move%((%-?[%d%.]+),%s*(%-?[%d%.]+),%s*(%-?[%d%.]+),%s*(%-?[%d%.]+).*%)")
    if x1 and y1 and x2 and y2 then
        return tonumber(x1), tonumber(y1), tonumber(x2), tonumber(y2)
    end
    return nil
end

local function parse_comment(event, pos, height, delay)
    local x1, y1, x2, y2 = parse_move_tag(event.text)
    local displayarea = tonumber(height * options.displayarea)
    if not x1 then
        local current_x, current_y = event.text:match("\\pos%((%-?[%d%.]+),%s*(%-?[%d%.]+).*%)")
        if not current_y or tonumber(current_y) > displayarea then return end
        if event.style ~= "SP" and event.style ~= "MSG" then
            return string.format("{\\an8}%s", event.text)
        else
            return string.format("{\\an7}%s", event.text)
        end
    end

    -- 计算移动的时间范围
    local duration = event.end_time - event.start_time  --mean: options.scrolltime
    local progress = (pos - event.start_time - delay) / duration  -- 移动进度 [0, 1]

    -- 计算当前坐标
    local current_x = tonumber(x1 + (x2 - x1) * progress)
    local current_y = tonumber(y1 + (y2 - y1) * progress)

    -- 移除 \move 标签并应用当前坐标
    local clean_text = event.text:gsub("\\move%(.-%)", "")
    if current_y > displayarea then return end
    if event.style ~= "SP" and event.style ~= "MSG" then
        return string.format("{\\pos(%.1f,%.1f)\\an8}%s", current_x, current_y, clean_text)
    else
        return string.format("{\\pos(%.1f,%.1f)\\an7}%s", current_x, current_y, clean_text)
    end
end

local overlay = mp.create_osd_overlay('ass-events')

function render()
    if COMMENTS == nil then return end

    local pos, err = mp.get_property_number('time-pos')
    if err ~= nil then
        return msg.error(err)
    end

    local delay = get_delay_for_time(DELAYS, pos)

    local fontname = options.fontname
    local fontsize = options.fontsize
    local alpha = string.format("%02X", (1 - tonumber(options.opacity)) * 255)

    local width, height = 1920, 1080
    local ratio = osd_width / osd_height
    if width / height < ratio then
        height = width / ratio
        fontsize = options.fontsize - ratio * 2
    end

    local ass_events = {}

    for _, event in ipairs(COMMENTS) do
        if pos >= event.start_time + delay and pos <= event.end_time + delay then
            local text = parse_comment(event, pos, height, delay)
            if text then
                text = text:gsub("&#%d+;","")
            end

            if text and text:match("\\fs%d+") then
                text = text:gsub("\\fs(%d+)", function(size)
                    return string.format("\\fs%d", size * 1.5)
                end)
            end

            -- 构建 ASS 字符串
            if text then
                local ass_text = string.format("{\\rDefault\\fn%s\\fs%d\\c&HFFFFFF&\\alpha&H%s\\bord%s\\shad%s\\b%s\\q2}%s",
                    fontname, fontsize, alpha, options.outline, options.shadow, options.bold and "1" or "0", text)
                table.insert(ass_events, ass_text)
            end
        end
    end

    overlay.res_x = width
    overlay.res_y = height
    overlay.data = table.concat(ass_events, '\n')
    overlay:update()
end

local timer = mp.add_periodic_timer(INTERVAL, render, true)

function render_danmaku(input, from_menu, no_osd)
    if type(input) == "table" then
        COMMENTS = input
        -- 初始化布局环境 (满屏分辨率，不缩放，模拟原始 ASS 生成环境)
        local res_x, res_y = 1920, 1080
        local fontsize = tonumber(options.fontsize) or 50
        local roll_array = DanmakuArray:new(res_x, res_y, fontsize)
        local top_array = DanmakuArray:new(res_x, res_y, fontsize)
        
        local scrolltime = tonumber(options.scrolltime) or 15
        local fixtime = tonumber(options.fixtime) or 5
        local get_width = get_str_width or function(s, size) 
            return (utf8_len and utf8_len(s) or #s) * size 
        end
        for _, d in ipairs(COMMENTS) do
            if not d.start_time then d.start_time = d.time end
            if not d.end_time then
                if d.type >= 1 and d.type <= 3 then
                    d.end_time = d.start_time + scrolltime
                else
                    d.end_time = d.start_time + fixtime
                end
            end
            if not d.clean_text then d.clean_text = d.text end
            if not d.text:match("\\move") and not d.text:match("\\pos") then
                local text = d.text
                text = text:gsub("{", "\\{"):gsub("}", "\\}"):gsub("\n", "\\N")

                -- 颜色处理 (BGR Hex)
                local color = d.color or 0xFFFFFF
                local color_hex = string.format("%06X", color)
                local r = string.sub(color_hex, 1, 2)
                local g = string.sub(color_hex, 3, 4)
                local b = string.sub(color_hex, 5, 6)
                local color_tag = string.format("\\c&H%s%s%s&", b, g, r)
                
                local effect_tag = nil
                local text_len = get_width(d.text, fontsize)
                
                if d.type >= 1 and d.type <= 3 then -- 滚动
                    local x1 = res_x + text_len / 2
                    local x2 = -text_len / 2
                    local y = get_position_y(fontsize, d.start_time, text_len, res_x, scrolltime, roll_array)
                    if y then
                        effect_tag = string.format("\\move(%d, %d, %d, %d)", x1, y, x2, y)
                    end
                elseif d.type == 5 then -- 顶
                    local x = res_x / 2
                    local y = get_fixed_y(fontsize, d.start_time, fixtime, top_array, true)
                    if y then 
                        effect_tag = string.format("\\pos(%d, %d)", x, y) 
                    end
                elseif d.type == 4 then -- 底
                    local x = res_x / 2
                    local y = get_fixed_y(fontsize, d.start_time, fixtime, top_array, false)
                    if y then 
                        effect_tag = string.format("\\pos(%d, %d)", x, y) 
                    end
                end
                
                if effect_tag then
                    d.text = "{" .. effect_tag .. color_tag .. "}" .. text
                else
                    d.text = "" 
                end
            end
        end
        
        -- 排序
        table.sort(COMMENTS, function(a, b) return a.start_time < b.start_time end)
        
        -- 触发 UI 更新
        if ENABLED and (from_menu or get_danmaku_visibility()) then
            if not no_osd then show_loaded(true) end
            set_danmaku_button()
            show_danmaku_func()
        end
    end
end

local function filter_state(label, name)
    local filters = mp.get_property_native("vf")
    for _, filter in pairs(filters) do
        if filter.label == label or filter.name == name
        or filter.params[name] ~= nil then
            return true
        end
    end
    return false
end

function show_danmaku_func()
    mp.set_property_bool(HAS_DANMAKU, true)
    set_danmaku_visibility(true)
    render()
    if not pause then timer:resume() end
    if options.vf_fps then
        local display_fps = mp.get_property_number('display-fps')
        local video_fps = mp.get_property_number('estimated-vf-fps')
        if (display_fps and display_fps < 58) or (video_fps and video_fps > 58) then return end
        if not filter_state("danmaku", "fps") then
            mp.commandv("vf", "append", string.format("@danmaku:fps=fps=%s", options.fps))
        end
    end
end

function hide_danmaku_func()
    timer:kill()
    mp.set_property_bool(HAS_DANMAKU, false)
    set_danmaku_visibility(false)
    overlay:remove()
    if filter_state("danmaku") then mp.commandv("vf", "remove", "@danmaku") end
end

local message_overlay = mp.create_osd_overlay('ass-events')
local message_timer = mp.add_timeout(3, function() message_overlay:remove() end, true)

function show_message(text, time)
    message_timer.timeout = time or 3
    message_timer:kill()
    message_overlay:remove()
    local message = string.format("{\\an%d\\pos(%d,%d)}%s", options.message_anlignment, options.message_x, options.message_y, text)
    message_overlay.res_x = 1920
    message_overlay.res_y = 1080
    message_overlay.data = message
    message_overlay:update()
    message_timer:resume()
end

mp.observe_property('osd-width', 'number', function(_, value) osd_width = value or osd_width end)
mp.observe_property('osd-height', 'number', function(_, value) osd_height = value or osd_height end)
mp.observe_property('display-fps', 'number', function(_, value)
    if value ~= nil then
        local interval = 1 / value / 10
        if interval > INTERVAL then
            timer:kill()
            timer = mp.add_periodic_timer(interval, render, true)
            if ENABLED then timer:resume() end
        else
            timer:kill()
            timer = mp.add_periodic_timer(INTERVAL, render, true)
            if ENABLED then timer:resume() end
        end
    end
end)
mp.observe_property('pause', 'bool', function(_, value)
    if value ~= nil then pause = value end
    if ENABLED then
        if pause then timer:kill() elseif COMMENTS ~= nil then timer:resume() end
    end
end)

mp.register_event('playback-restart', function(event)
    if event.error then return msg.error(event.error) end
    if ENABLED and COMMENTS ~= nil then render() end
end)

mp.add_hook("on_unload", 50, function()
    COMMENTS, DELAY = nil, 0
    timer:kill()
    overlay:remove()
    mp.set_property_native(DELAY_PROPERTY, 0)
    if filter_state("danmaku") then mp.commandv("vf", "remove", "@danmaku") end

    local files_to_remove = {
        file3 = utils.join_path(DANMAKU_PATH, "temp-" .. PID .. ".mp4")
    }
    if options.save_danmaku then 
        save_danmaku(true)
    end
    for _, file in pairs(files_to_remove) do if file_exists(file) then os.remove(file) end end
    DANMAKU = {sources = {}, count = 1}
end)