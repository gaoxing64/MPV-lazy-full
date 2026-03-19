local msg = require('mp.msg')
local utils = require("mp.utils")
input_loaded, input = pcall(require, "mp.input")
uosc_available = false

-- 保存当前菜单状态，用于展开剧集列表
local current_menu_state = {
    all_results = nil,
    servers = nil,
    expanded_key = nil,  -- 格式: "server|animeTitle"
    episodes = nil,
    selected_episode = nil, -- 存储手动选择的剧集信息，用于计算当前播放集的偏移
	search_id = nil,  -- 存储手动搜索的唯一ID
	search_items = nil,  -- 存储手动搜索结果的items数组
	search_query = nil,  -- 存储手动搜索关键词
    timer = nil, -- 定时清理器
    single_server_search_id = nil, -- 单服务器搜索唯一ID
    single_server_cache = nil, -- 单服务器搜索缓存
    single_server_timer = nil, -- 单服务器定时清理器
}
local menu_index_map = {}

local function get_history_episode_id()
    local history_json = read_file(HISTORY_PATH)
    if not history_json then return nil end
    local history = utils.parse_json(history_json) or {}
    local key = get_cache_key()
    local record = history[key]
    if record and record.episodeId then
        return record.episodeId
    end
    return nil
end

local function create_menu_props(menu_type, menu_title, items, footnote, menu_cmd, query)
    local menu_props = {
        type = menu_type,
        title = menu_title,
        search_style = menu_cmd and "palette" or "on_demand",
        search_debounce = menu_cmd and "submit" or 0,
        on_search = menu_cmd,
        footnote = footnote,
        search_suggestion = query,
        items = items,
    }
    return menu_props
end

local function extract_server_identifier(server_url)
    if not server_url then
        return "未知"
    end
    -- 为常见服务器分配简短的字母标识
    local server_aliases = {
        ["api.dandanplay.net"] = "弹弹play",
        ["localhost"] = "本地",
        ["127.0.0.1"] = "本地"
    }
    local hostname = server_url:gsub("^https?://", ""):gsub("/.*$", ""):gsub(":[0-9]+$", "")
    if server_aliases[hostname] then
        return server_aliases[hostname]
    else
        return hostname:sub(1, 6)  -- 截取前6个字符作为标识
    end
end

local function get_category_priority(type_desc)
    if not type_desc then return 99 end
    local t = type_desc:lower()
    if t:find("tv") or t:find("series") or t:find("剧集") or t:find("连载") or t:find("番剧") or
       t:find("动漫") or t:find("网络放送") or t:find("电视剧") then
        return 1
    end
    if t:find("movie") or t:find("film") or t:find("电影") or t:find("剧场版") then return 2 end
    if t:find("ova") or t:find("oad") or t:find("special") or t:find("特别篇") then return 3 end
    return 4
end

local function sort_anime_list(animes)
    table.sort(animes, function(a, b)
        local type_a = get_category_priority(a.typeDescription)
        local type_b = get_category_priority(b.typeDescription)
        if type_a ~= type_b then
            return type_a < type_b
        end
        local title_a = a.animeTitle or ""
        local title_b = b.animeTitle or ""

        local base_a = title_a:sub(1, 6):lower()
        local base_b = title_b:sub(1, 6):lower()

        local is_final_a = title_a:find("最终季") ~= nil
        local is_final_b = title_b:find("最终季") ~= nil

        if is_final_a ~= is_final_b then
            return not is_final_a
        end
        if base_a ~= base_b then
            return title_a < title_b
        end
        local s_a = extract_season(title_a)
        local s_b = extract_season(title_b)
        if s_a ~= s_b then
            return s_a < s_b
        end
        local p_a = extract_part(title_a)
        local p_b = extract_part(title_b)
        if p_a ~= p_b then
            return p_a < p_b
        end
        return #title_a < #title_b
    end)
    return animes
end

local function get_current_selected_episode_number(current_episode)
    if not current_menu_state.selected_episode then
        return nil
    end
    local selection = current_menu_state.selected_episode

    if selection.episode_offset then
        local target_episode = current_episode + selection.episode_offset
        msg.verbose(string.format("动态计算选择集数: 当前=%d, 偏移=%d, 目标=%d",
            current_episode, selection.episode_offset, target_episode))
        return target_episode
    end

    return selection.episodeNumber
end

local function parse_and_sort_episodes(json, current_episode_num)
    local success, parsed = pcall(utils.parse_json, json)
    if not success or not parsed or not parsed.bangumi or not parsed.bangumi.episodes then
        return nil, "数据格式错误"
    end

    local episodes = parsed.bangumi.episodes

    -- 按剧集号排序
    table.sort(episodes, function(a, b)
        return (tonumber(a.episodeNumber) or 0) < (tonumber(b.episodeNumber) or 0)
    end)

    current_episode_num = tonumber(current_episode_num) or 1
    local dynamic_selected_episode = get_current_selected_episode_number(current_episode_num)

    for _, episode in ipairs(episodes) do
        local ep_num = tonumber(episode.episodeNumber)
        episode.is_current = false

        if dynamic_selected_episode and ep_num and ep_num == dynamic_selected_episode then
            episode.is_current = true
        elseif (not dynamic_selected_episode) and ep_num and ep_num == current_episode_num then
            episode.is_current = true
        end
    end

    return episodes, nil
end

function get_animes(query)
    -- 缓存逻辑优化：防止死循环
    local use_cache = false
    if current_menu_state.search_query == query and
       current_menu_state.search_items and
       #current_menu_state.search_items >= 1 then

        use_cache = true
        local last_item = current_menu_state.search_items[#current_menu_state.search_items]
        local has_loading_item = last_item.title and last_item.title:match("^⏳ 正在搜索")
        if has_loading_item and not current_menu_state.search_id then
             use_cache = false
        end
        if use_cache and #current_menu_state.search_items <= 1 then
            use_cache = false
        end
    end

    if use_cache then
        local items = current_menu_state.search_items
        -- 统计实际结果数
        local result_count = 0
        for _, it in ipairs(items) do
            if it.value and type(it.value) == "table" and it.value[3] == "search-episodes-event" then
                result_count = result_count + 1
            end
        end

        local final_message = result_count > 0 and ("✅ 搜索到 " .. result_count .. " 个结果 (已按类别自动排序)") or "无结果"
        local menu_type = "menu_anime"
        local menu_title = "在此处输入番剧名称"
        local menu_cmd = { "script-message-to", mp.get_script_name(), "search-anime-event" }

        if uosc_available then
            local menu_props = create_menu_props(menu_type, menu_title, items, final_message, menu_cmd, query)
            local json_props = utils.format_json(menu_props)
            mp.add_timeout(0.05, function()
                mp.commandv("script-message-to", "uosc", "open-menu", json_props)
            end)
        elseif input_loaded then
            open_menu_select(items)
        end
        return
    end

    -- 新搜索，增加唯一ID
    current_menu_state.search_id = (current_menu_state.search_id or 0) + 1
    local this_search_id = current_menu_state.search_id

    local encoded_query = url_encode(query)
    local servers = get_api_servers()
    local endpoint = "/api/v2/search/anime?keyword=" .. encoded_query
    local items = {}

    -- 定时清理
    if current_menu_state.timer then current_menu_state.timer:kill() end
    current_menu_state.timer = mp.add_timeout(60, function()
        if current_menu_state.search_items == items then
            current_menu_state.search_items, current_menu_state.search_query = nil, nil
            current_menu_state.raw_animes = nil
            if current_menu_state.search_id == this_search_id then
                current_menu_state.search_id = nil
            end
            current_menu_state.timer = nil
            msg.info("搜索缓存已过期自动清理")
        end
    end)

    -- 重置状态
    current_menu_state.search_items = items
    current_menu_state.search_query = query
    current_menu_state.raw_animes = {} -- 存储所有服务器返回的原始数据

    -- 初始菜单：只有返回和loading
    table.insert(items, {
        title = "← 返回",
        value = { "script-message-to", mp.get_script_name(), "open_search_danmaku_menu" },
        keep_open = false,
        selectable = true,
    })
    table.insert(items, {
        title = "⏳ 正在搜索...(" .. #servers .. "个服务器)",
        italic = true,
        keep_open = true,
        selectable = false,
    })

    local menu_type = "menu_anime"
    local menu_title = "在此处输入番剧名称"
    local footnote = "使用enter或ctrl+enter进行搜索"
    local menu_cmd = { "script-message-to", mp.get_script_name(), "search-anime-event" }

    if uosc_available then
        local menu_props = create_menu_props(menu_type, menu_title, items, footnote, menu_cmd, query)
        local json_props = utils.format_json(menu_props)
        mp.add_timeout(0.1, function()
            mp.commandv("script-message-to", "uosc", "open-menu", json_props)
        end)
    else
        show_message("加载数据中...(" .. #servers .. "个服务器)", 30)
    end

    msg.verbose("尝试获取番剧数据:" .. endpoint .. " (服务器数量: " .. #servers .. ")")

    local total_results = 0
    local completed_servers = 0
    local concurrent_manager = ConcurrentManager:new()
    local request_count = 0
    local MAX_RETRIES = 10
    local seen_anime_ids = {} -- 用于去重

    local function is_loading_item(anime)
        return anime.animeTitle and
               (anime.animeTitle:find("搜索正在启动") or anime.animeTitle:find("搜索正在运行"))
    end

    local function send_uosc_update(loading_msg)
        if not uosc_available then return end
        local msg_str = loading_msg or string.format("已加载 %d 个结果 (进度: %d/%d) - 自动排序中", total_results, completed_servers, #servers)
        local menu_props = create_menu_props(menu_type, menu_title, items, msg_str, menu_cmd, query)
        local json_props = utils.format_json(menu_props)
        mp.commandv("script-message-to", "uosc", "update-menu", json_props)
    end

    -- 增量更新：每次有新数据都重新排序并重建 items 列表
    local function update_menu_incrementally(new_animes, server_name)
        if current_menu_state.search_id ~= this_search_id then return end
        if not new_animes or #new_animes == 0 then return end

        -- 将新数据合并到 raw_animes
        local has_new_data = false
        for _, anime in ipairs(new_animes) do
            local anime_id = anime.bangumiId or anime.animeId
            if anime_id and not seen_anime_ids[anime_id] and not is_loading_item(anime) then
                anime._source_server = server_name
                table.insert(current_menu_state.raw_animes, anime)
                seen_anime_ids[anime_id] = true
                total_results = total_results + 1
                has_new_data = true
            end
        end

        if not has_new_data then return end

        -- 全量重新排序
        sort_anime_list(current_menu_state.raw_animes)
        local new_items = {}
        table.insert(new_items, {
            title = "← 返回",
            value = { "script-message-to", mp.get_script_name(), "open_search_danmaku_menu" },
            keep_open = false,
            selectable = true,
        })
        for _, anime in ipairs(current_menu_state.raw_animes) do
            local s_name = anime._source_server or "未知"
            local server_identifier = extract_server_identifier(s_name)
            local display_title = anime.animeTitle
            if server_identifier then
                display_title = display_title .. " [" .. server_identifier .. "]"
            end

            table.insert(new_items, {
                title = display_title,
                hint = anime.typeDescription,
                value = {
                    "script-message-to",
                    mp.get_script_name(),
                    "search-episodes-event",
                    anime.animeTitle,
                    anime.bangumiId,
                    s_name,
                    query
                },
            })
        end
        for _, old_item in ipairs(items) do
            if old_item._temp_server then
                table.insert(new_items, old_item)
            end
        end
        if completed_servers < #servers then
             table.insert(new_items, {
                title = "⏳ 正在搜索... (进度: " .. completed_servers .. "/" .. #servers .. ")",
                italic = true,
                keep_open = true,
                selectable = false,
            })
        end
        items = new_items
        current_menu_state.search_items = items
        send_uosc_update()
    end

    -- 处理特定服务器的"临时加载状态"显示
    local function update_server_status_item(server, status_text, type_desc)
        local server_id = extract_server_identifier(server)
        local display_title = string.format("%s [%s]", status_text, server_id)

        -- 先移除该服务器的旧状态
        for i, item in ipairs(items) do
            if item._temp_server == server then
                table.remove(items, i)
                break
            end
        end

        -- 插入到底部（Loading区域）
        local insert_pos = #items + 1
        -- 确保插在全局 loading 之前 (如果有)
        if items[#items] and items[#items].title and items[#items].title:match("^⏳ 正在搜索") then
            insert_pos = #items
        end

        table.insert(items, insert_pos, {
            title = display_title,
            hint = type_desc or "搜索中...",
            italic = true,
            keep_open = true,
            selectable = false,
            _temp_server = server -- 【关键】标记这是临时条目
        })
        send_uosc_update()
    end

    local function clear_server_status_item(server)
        for i, item in ipairs(items) do
            if item._temp_server == server then
                table.remove(items, i)
                send_uosc_update()
                return
            end
        end
    end

    -- 并发请求逻辑
    for i, server in ipairs(servers) do
        local url = server .. endpoint
        local args = make_danmaku_request_args("GET", url, nil, nil)
        if args then
            request_count = request_count + 1
            local request_func = function(callback)
                local function execute_request(retry_count)
                    retry_count = retry_count or 0
                    call_cmd_async(args, function(error, json)
                        if current_menu_state.search_id ~= this_search_id then return end
                        local result = { success = false, server = server, animes = {} }
                        local is_still_loading = false
                        local loading_text = ""
                        local loading_type = ""
                        if not error and json then
                            local success, parsed = pcall(utils.parse_json, json)
                            if success and parsed and parsed.animes then
                                result.success = true
                                result.animes = parsed.animes
                                for _, anime in ipairs(parsed.animes) do
                                    if is_loading_item(anime) then
                                        is_still_loading = true
                                        loading_text = anime.animeTitle
                                        loading_type = anime.typeDescription or ""
                                        break
                                    end
                                end
                            end
                        end
                        if is_still_loading and retry_count < MAX_RETRIES then
                            update_server_status_item(server, loading_text, loading_type)
                            mp.add_timeout(3, function()
                                if current_menu_state.search_id == this_search_id then
                                    execute_request(retry_count + 1)
                                end
                            end)
                        else
                            clear_server_status_item(server)
                            if is_still_loading and retry_count >= MAX_RETRIES then
                                result.success = false
                            end

                            -- 标记完成并更新
                            completed_servers = completed_servers + 1
                            if result.success then
                                update_menu_incrementally(result.animes, server)
                            else
                                -- 即使失败也要刷新一下 Loading 状态文本
                                update_menu_incrementally(nil, server)
                            end
                            callback(result)
                        end
                    end)
                end
                execute_request(0)
            end
            concurrent_manager:start_request(server, i, request_func)
        else
            completed_servers = completed_servers + 1
        end
    end

    if request_count == 0 then
        local message = "无可用服务器"
        current_menu_state.search_id = nil
        if uosc_available then
            local menu_props = create_menu_props(menu_type, menu_title, items, message, menu_cmd, query)
            local json_props = utils.format_json(menu_props)
            mp.add_timeout(0.1, function()
                mp.commandv("script-message-to", "uosc", "update-menu", json_props)
            end)
        elseif input_loaded then
            show_message(message, 3)
        end
        return
    end

    local callback_executed = false
    concurrent_manager:wait_all(function()
        if current_menu_state.search_id ~= this_search_id then return end
        if callback_executed then return end
        callback_executed = true
        current_menu_state.search_id = nil

        -- 移除底部的“正在搜索”条目
        for i = #items, 1, -1 do
            if items[i].title and items[i].title:match("^⏳ 正在搜索") then
                table.remove(items, i)
            end
        end

        if total_results > 0 then
            local final_message = "✅ 搜索到 " .. total_results .. " 个结果 (已自动排序)"
            if uosc_available then
                local menu_props = create_menu_props(menu_type, menu_title, items, final_message, menu_cmd, query)
                local json_props = utils.format_json(menu_props)
                mp.commandv("script-message-to", "uosc", "update-menu", json_props)
            elseif input_loaded then
                show_message("", 0)
                mp.add_timeout(0.1, function() open_menu_select(items) end)
            end
        else
            if #items == 1 then -- 只有返回按钮
                local message = "无结果"
                if uosc_available then
                    local menu_props = create_menu_props(menu_type, menu_title, items, message, menu_cmd, query)
                    local json_props = utils.format_json(menu_props)
                    mp.commandv("script-message-to", "uosc", "update-menu", json_props)
                else
                    show_message(message, 3)
                end
            end
        end
    end)
end

function get_episodes(animeTitle, bangumiId, source_server, original_query, is_single_server_mode)
    local servers = {}
    -- 如果指定了源服务器，优先使用该服务器
    if source_server and source_server ~= "" then
        table.insert(servers, source_server)
        msg.verbose("使用指定服务器: " .. source_server)
    else
        servers = get_api_servers()
        msg.verbose("使用自动服务器选择，数量: " .. #servers)
    end

    local endpoint = "/api/v2/bangumi/" .. bangumiId
    local items = {}
    local message = "加载数据中...(" .. #servers .. "个服务器)"
    local menu_type = "menu_episodes"
    local menu_title = "剧集信息 - " .. animeTitle
    local footnote = "使用 / 打开筛选"

    -- 逻辑判断：根据是否是单服务器模式，决定返回按钮的行为
    if is_single_server_mode then
        table.insert(items, {
            title = "← 返回搜索结果",
            value = { "script-message-to", mp.get_script_name(), "search-server-event", source_server, original_query },
            keep_open = false,
            selectable = true,
        })
    else
        -- 原有的返回逻辑（返回到全局搜索结果）
        local return_query = original_query or animeTitle:match("^(.-)%s*%(%d+%)$") or animeTitle
        table.insert(items, {
            title = "← 返回",
            value = { "script-message-to", mp.get_script_name(), "search-anime-event", return_query },
            keep_open = false,
            selectable = true,
        })
    end

    if uosc_available then
        update_menu_uosc(menu_type, menu_title, message, footnote)
    else
        show_message(message, 30)
    end

    -- 存储所有服务器的结果
    local all_episodes = {}
    local completed_requests = 0
    local successful_requests = 0

    for i, server in ipairs(servers) do
        local url = server .. endpoint
        local args = make_danmaku_request_args("GET", url, nil, nil)
        if args then
            call_cmd_async(args, function(error, json)
                completed_requests = completed_requests + 1
                if not error and json then
                    local success, parsed = pcall(utils.parse_json, json)
                    if success and parsed and parsed.bangumi and parsed.bangumi.episodes then
                        successful_requests = successful_requests + 1
                        all_episodes[server] = {
                            raw_json = json,
                            count = #parsed.bangumi.episodes,
                        }
                        msg.verbose("服务器 " .. server .. " 返回 " .. #parsed.bangumi.episodes .. "                   个剧集")
                    end
                end

                -- 所有请求完成后处理
                if completed_requests == #servers then
                    local best_server = nil
                    local max_episodes = 0

                    -- 选择剧集数量最多的服务器
                    for srv, data in pairs(all_episodes) do
                        if data.count > max_episodes then
                            max_episodes = data.count
                            best_server = srv
                        end
                    end

                    if best_server and all_episodes[best_server] then
                        -- 获取当前文件信息，用于计算 ⭐ 标记
                        local _, _, current_episode_num = parse_title()
                        local episodes, err = parse_and_sort_episodes(all_episodes[best_server].raw_json, current_episode_num)
                        if not episodes then
                            if #items == 1 then
                                local msg_txt = "获取剧集列表失败"
                                if uosc_available then
                                    update_menu_uosc(menu_type, menu_title, items, footnote)
                                else
                                    show_message(msg_txt, 3)
                                end
                            end
                            return
                        end

                        -- 计算当前选择的集数（基于 current_menu_state.selected_episode 的偏移）
                        current_episode_num = tonumber(current_episode_num) or 1
                        local dynamic_selected_episode = get_current_selected_episode_number(current_episode_num)

                        for _, episode in ipairs(episodes) do
                            local ep_num = tonumber(episode.episodeNumber)
                            local is_current = false
                            if dynamic_selected_episode and ep_num and ep_num == dynamic_selected_episode then
                                is_current = true
                            elseif ep_num and ep_num == current_episode_num then
                                is_current = true
                            end

                            table.insert(items, {
                                title = episode.episodeTitle or "未知标题",
                                hint = "第" .. (episode.episodeNumber or "?") .. "集",
                                value = {
                                    "script-message-to",
                                    mp.get_script_name(),
                                    "load-danmaku",
                                    animeTitle,
                                    episode.episodeTitle or "未知标题",
                                    tostring(episode.episodeId),
                                    best_server  -- 传递服务器信息
                                },
                                keep_open = false,
                                selectable = true,
                                active = is_current,
                            })
                        end

                        -- 更新缓存和菜单状态：将选择的结果保存到缓存中（从搜索菜单选择的结果）
                        local selected_episode = nil
                        for _, episode in ipairs(episodes) do
                            local ep_num = tonumber(episode.episodeNumber)
                            if ep_num and ep_num == current_episode_num then
                                selected_episode = episode
                                break
                            end
                        end

                        -- 确保菜单状态存在
                        if not current_menu_state.all_results then
                            current_menu_state.all_results = {}
                        end
                        if not current_menu_state.all_results[best_server] then
                            current_menu_state.all_results[best_server] = {}
                        end

                        if selected_episode then
                            local match = {
                                animeTitle = animeTitle,
                                episodeTitle = selected_episode.episodeTitle or "未知标题",
                                episodeId = selected_episode.episodeId,
                                bangumiId = bangumiId,
                                match_type = "episode",
                                similarity = 1.0
                            }
                            save_match_to_cache(best_server, {match}, "episode", {}, true)

                            -- 更新菜单状态
                            current_menu_state.all_results[best_server].matches = {match}
                            current_menu_state.all_results[best_server].match_type = "episode"
                        else
                            local fallback_match = {
                                animeTitle = animeTitle,
                                bangumiId = bangumiId,
                                similarity = 1.0
                            }
                            save_match_to_cache(best_server, {fallback_match}, "anime", {}, true)

                            -- 更新菜单状态
                            current_menu_state.all_results[best_server].matches = {fallback_match}
                            current_menu_state.all_results[best_server].match_type = "anime"
                        end

                        -- 确保菜单状态的其他字段也被设置
                        current_menu_state.servers = get_api_servers()
                        current_menu_state.expanded_key = nil
                        current_menu_state.episodes = nil

                        if uosc_available then
                            update_menu_uosc(menu_type, menu_title, items, footnote)
                        elseif input_loaded then
                            mp.add_timeout(0.1, function()
                                open_menu_select(items)
                            end)
                        end
                    else
                        -- 如果没有结果，确保返回按钮仍然显示
                        if #items == 1 then -- 只有返回按钮
                            local message = "获取剧集列表失败"
                            if uosc_available then
                                update_menu_uosc(menu_type, menu_title, items, footnote)
                            else
                                show_message(message, 3)
                            end
                        end
                    end
                end
            end)
        else
            completed_requests = completed_requests + 1
        end
    end
end

function update_menu_uosc(menu_type, menu_title, menu_item, menu_footnote, menu_cmd, query)
    local items = {}
    if type(menu_item) == "string" then
        table.insert(items, {
            title = menu_item,
            value = "",
            italic = true,
            keep_open = true,
            selectable = false,
            align = "center",
        })
    else
        items = menu_item
    end

    local menu_props = create_menu_props(menu_type, menu_title, items, menu_footnote, menu_cmd, query)
    local json_props = utils.format_json(menu_props)
    mp.commandv("script-message-to", "uosc", "open-menu", json_props)
end

function open_menu_select(menu_items, is_time)
    local item_titles, item_values = {}, {}
    for i, v in ipairs(menu_items) do
        item_titles[i] = is_time and "[" .. v.hint .. "] " .. v.title or
            (v.hint and v.title .. " (" .. v.hint .. ")" or v.title)
        item_values[i] = v.value
    end
    mp.commandv('script-message-to', 'console', 'disable')
    input.select({
        prompt = '筛选:',
        items = item_titles,
        submit = function(id)
            mp.commandv(unpack(item_values[id]))
        end,
    })
end

-- 打开弹幕输入搜索菜单
function open_input_menu_get()
    mp.commandv('script-message-to', 'console', 'disable')
    local title = parse_title()
    input.get({
        prompt = '番剧名称:',
        default_text = title,
        cursor_position = title and #title + 1,
        submit = function(text)
            input.terminate()
            mp.commandv("script-message-to", mp.get_script_name(), "search-anime-event", text)
        end
    })
end

function open_input_menu_uosc(custom_callback, menu_type_id)
    local items = {}
    if DANMAKU.anime and DANMAKU.episode then
        local episode = DANMAKU.episode:gsub("%s.-$","")
        episode = episode:match("^(第.*[话回集]+)%s*") or episode
        items[#items + 1] = {
            title = string.format("已关联弹幕：%s-%s", DANMAKU.anime, episode),
            bold = true,
            italic = true,
            keep_open = true,
            selectable = false,
        }
    end
    items[#items + 1] = {
        hint = "  追加|ds或|dy或|dm可搜索电视剧|电影|国漫",
        keep_open = true,
        selectable = false,
    }

    local callback = custom_callback or { "script-message-to", mp.get_script_name(), "search-anime-event" }
    local menu_id = menu_type_id or "menu_danmaku"

    local menu_props = create_menu_props(menu_id, "在此处输入番剧名称", items, "使用enter或ctrl+enter进行搜索", callback, parse_title())
    local json_props = utils.format_json(menu_props)
    mp.commandv("script-message-to", "uosc", "open-menu", json_props)
end

function open_input_menu()
    if uosc_available then
        open_input_menu_uosc()
    elseif input_loaded then
        open_input_menu_get()
    end
end

-- 打开弹幕源添加管理菜单
function open_add_menu_get()
    mp.commandv('script-message-to', 'console', 'disable')
    input.get({
        prompt = 'Input url:',
        submit = function(text)
            input.terminate()
            mp.commandv("script-message-to", mp.get_script_name(), "add-source-event", text)
        end
    })
end

function open_add_menu_uosc()
    local sources = {}
    for url, source in pairs(DANMAKU.sources) do
        if source.data then
            local item = {title = url, value = url, keep_open = true,}
            if source.from == "api_server" then
                if source.blocked then
                    item.hint = "来源：弹幕服务器（已屏蔽）"
                    item.actions = {{icon = "check", name = "unblock"},}
                else
                    item.hint = "来源：弹幕服务器（未屏蔽）"
                    item.actions = {{icon = "not_interested", name = "block"},}
                end
            else
                item.hint = "来源：用户添加"
                item.actions = {{icon = "delete", name = "delete"},}
            end
            table.insert(sources, item)
        end
    end
    local menu_props = {
        type = "menu_source",
        title = "在此输入源地址url",
        search_style = "palette",
        search_debounce = "submit",
        on_search = { "script-message-to", mp.get_script_name(), "add-source-event" },
        footnote = "使用enter或ctrl+enter进行添加",
        items = sources,
        item_actions_place = "outside",
        callback = {mp.get_script_name(), 'setup-danmaku-source'},
    }
    local json_props = utils.format_json(menu_props)
    mp.commandv("script-message-to", "uosc", "open-menu", json_props)
end

function open_add_menu()
    if uosc_available then
        open_add_menu_uosc()
    elseif input_loaded then
        open_add_menu_get()
    end
end

-- 打开弹幕内容菜单
function open_content_menu(pos)
    local items = {}
    local time_pos = pos or mp.get_property_native("time-pos")
    local duration = mp.get_property_number("duration", 0)
    menu_index_map = {}
    if COMMENTS ~= nil then
        table.sort(COMMENTS, function(a, b)
            local t1 = a.start_time or a.time or 0
            local t2 = b.start_time or b.time or 0
            return t1 < t2
        end)

        local menu_idx = 1
        for real_idx, event in ipairs(COMMENTS) do
            local text = event.clean_text or event.text
            local start_t = event.start_time or event.time or 0
            local end_t = event.end_time or (start_t + 5)
            local delay = get_delay_for_time(DELAYS, start_t)
            local final_start_time = start_t + delay

            if text and text ~= "" and final_start_time >= 0 and final_start_time <= duration then
                menu_index_map[menu_idx] = real_idx
                local source_url = event.source
                local source_hint = ""
                local is_blocked = false

                if source_url then
                    if DANMAKU.sources[source_url] and DANMAKU.sources[source_url].blocked then
                        is_blocked = true
                    end

                    if source_url:find("^http") then
                        source_hint = extract_server_identifier(source_url)
                    elseif source_url:find("^/") or source_url:match("^[a-zA-Z]:") then
                        source_hint = "本地"
                    else
                        source_hint = "其他"
                    end
                end

                local hint_str = seconds_to_time(final_start_time)
                if source_hint ~= "" then
                    hint_str = hint_str .. " • " .. source_hint
                end
                if is_blocked then
                    hint_str = hint_str .. " (已屏蔽)"
                end

                local item = {
                    title = abbr_str(text, 60),
                    hint = hint_str,
                    -- Value 设置为 seek 命令，点击主体时触发
                    value = { "seek", final_start_time, "absolute" },
                    active = time_pos >= final_start_time and time_pos <= (end_t + delay),
                    actions = {},
                    italic = is_blocked,
                    muted = is_blocked
                }

                if source_url then
                    table.insert(item.actions, {
                        name = 'block_source',
                        icon = 'block',
                        label = '屏蔽此弹幕源',
                    })

                    table.insert(item.actions, {
                        name = 'adjust_delay',
                        icon = 'more_time',
                        label = '调整此源延迟',
                    })
                end

                table.insert(items, item)
                menu_idx = menu_idx + 1
            end
        end
    end

    local menu_props = {
        type = "menu_content",
        title = "弹幕内容",
        footnote = "使用 / 打开搜索",
        items = items,
        item_actions_place = "outside",
        callback = {mp.get_script_name(), 'handle-danmaku-content-action'},
    }

    local json_props = utils.format_json(menu_props)
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "open-menu", json_props)
    elseif input_loaded then
        open_menu_select(items, true)
    end
end

local menu_items_config = {
    bold = { title = "粗体", hint = options.bold, original = options.bold,
        footnote = "true / false", },
    fontsize = { title = "大小", hint = options.fontsize, original = options.fontsize,
        scope = { min = 0, max = math.huge }, footnote = "请输入整数(>=0)", },
    outline = { title = "描边", hint = options.outline, original = options.outline,
        scope = { min = 0.0, max = 4.0 }, footnote = "输入范围：(0.0-4.0)" },
    shadow = { title = "阴影", hint = options.shadow, original = options.shadow,
        scope = { min = 0, max = math.huge }, footnote = "请输入整数(>=0)", },
    scrolltime = { title = "速度", hint = options.scrolltime, original = options.scrolltime,
        scope = { min = 1, max = math.huge }, footnote = "请输入整数(>=1)", },
    opacity = { title = "透明度", hint = options.opacity, original = options.opacity,
        scope = { min = 0, max = 1 }, footnote = "输入范围：0（完全透明）到1（不透明）", },
    displayarea = { title = "弹幕显示范围", hint = options.displayarea, original = options.displayarea,
        scope = { min = 0.0, max = 1.0 }, footnote = "显示范围(0.0-1.0)", },
}

-- 创建一个包含键顺序的表，这是样式菜单的排布顺序
local ordered_keys = {"bold", "fontsize", "outline", "shadow", "scrolltime", "opacity", "displayarea"}

-- 设置弹幕样式菜单
function add_danmaku_setup(actived, status)
    if not uosc_available then
        show_message("无uosc UI框架，不支持使用该功能", 2)
        return
    end
    local items = {}
    for _, key in ipairs(ordered_keys) do
        local config = menu_items_config[key]
        local item_config = {
            title = config.title,
            hint = "目前：" .. tostring(config.hint),
            active = key == actived,
            keep_open = true,
            selectable = true,
        }
        if config.hint ~= config.original then
            local original_str = tostring(config.original)
            item_config.actions = {{icon = "refresh", name = key, label = "恢复默认配置 < " .. original_str .. " >"}}
        end
        table.insert(items, item_config)
    end
    local menu_props = {
        type = "menu_style",
        title = "弹幕样式",
        search_style = "disabled",
        footnote = "样式更改仅在本次播放生效",
        item_actions_place = "outside",
        items = items,
        callback = { mp.get_script_name(), 'setup-danmaku-style'},
    }
    local actions = "open-menu"
    if status ~= nil then
        if status == "updata" then
            -- "updata" 模式会保留输入框文字
            menu_props.title = "  " .. menu_items_config[actived]["footnote"]
            actions = "update-menu"
        elseif status == "refresh" then
            -- "refresh" 模式会清除输入框文字
            menu_props.title = "  " .. menu_items_config[actived]["footnote"]
        elseif status == "error" then
            menu_props.title = "输入非数字字符或范围出错"
            -- 创建一个定时器，在1秒后触发回调函数，删除搜索栏错误信息
            mp.add_timeout(1.0, function() add_danmaku_setup(actived, "updata") end)
        end
        menu_props.search_style = "palette"
        menu_props.search_debounce = "submit"
        menu_props.footnote = menu_items_config[actived]["footnote"] or ""
        menu_props.on_search = { "script-message-to", mp.get_script_name(), "setup-danmaku-style", actived }
    end
    local json_props = utils.format_json(menu_props)
    mp.commandv("script-message-to", "uosc", actions, json_props)
end

-- 设置弹幕源延迟菜单
function danmaku_delay_setup(source_url)
    if not uosc_available then
        show_message("无uosc UI框架，不支持使用该功能", 2)
        return
    end
    local sources = {}
    for url, source in pairs(DANMAKU.sources) do
        if source.data and not source.blocked then
            local delay = 0
            if source.delay_segments then
                for _, seg in ipairs(source.delay_segments) do
                    if seg.start == 0 then
                        delay = seg.delay or 0
                        break
                    end
                end
            end
            local item = {title = url, value = url, keep_open = true,}
            item.hint = "当前弹幕源延迟:" .. string.format("%.1f", delay + 1e-10) .. "秒"
            item.active = url == source_url
            table.insert(sources, item)
        end
    end
    local menu_props = {
        type = "menu_delay",
        title = "弹幕源延迟设置",
        search_style = "disabled",
        items = sources,
        callback = {mp.get_script_name(), 'setup-source-delay'},
    }
    if source_url ~= nil then
        menu_props.title = "请输入数字，单位（秒）/ 或者按照形如\"14m15s\"的格式输入分钟数加秒数"
        menu_props.search_style = "palette"
        menu_props.search_debounce = "submit"
        menu_props.on_search = { "script-message-to", mp.get_script_name(), "setup-source-delay", source_url }
    end
    local json_props = utils.format_json(menu_props)
    mp.commandv("script-message-to", "uosc", "open-menu", json_props)
end

-- 总集合弹幕菜单
function open_add_total_menu_uosc()
    local items = {}
    local total_menu_items_config = {
        { title = "弹幕搜索", action = "open_search_danmaku_menu" },
        { title = "选择弹幕源", action = "open_danmaku_source_menu" },
        { title = "从源添加弹幕", action = "open_add_source_menu" },
        { title = "弹幕源延迟设置", action = "open_source_delay_menu" },
        { title = "弹幕样式", action = "open_setup_danmaku_menu" },
        { title = "弹幕内容", action = "open_content_danmaku_menu" },
    }

    if DANMAKU.anime and DANMAKU.episode then
        local episode = DANMAKU.episode:gsub("%s.-$","")
        episode = episode:match("^(第.*[话回集]+)%s*") or episode
        items[#items + 1] = {
            title = string.format("已关联弹幕：%s-%s", DANMAKU.anime, episode),
            bold = true,
            italic = true,
            keep_open = true,
            selectable = false,
        }
    end
    for _, config in ipairs(total_menu_items_config) do
        table.insert(items, {
            title = config.title,
            value = { "script-message-to", mp.get_script_name(), config.action },
            keep_open = false,
            selectable = true,
        })
    end
    local menu_props = {
        type = "menu_total",
        title = "弹幕设置",
        search_style = "disabled",
        items = items,
    }
    local json_props = utils.format_json(menu_props)
    mp.commandv("script-message-to", "uosc", "open-menu", json_props)
end

function open_add_total_menu_select()
    local item_titles, item_values = {}, {}
    local total_menu_items_config = {
        { title = "弹幕搜索", action = "open_search_danmaku_menu" },
        { title = "从源添加弹幕", action = "open_add_source_menu" },
        { title = "弹幕内容", action = "open_content_danmaku_menu" },
    }
    for i, config in ipairs(total_menu_items_config) do
        item_titles[i] = config.title
        item_values[i] = { "script-message-to", mp.get_script_name(), config.action }
    end
    mp.commandv('script-message-to', 'console', 'disable')
    input.select({
        prompt = '选择:',
        items = item_titles,
        submit = function(id)
            mp.commandv(unpack(item_values[id]))
        end,
    })
end

function open_add_total_menu()
    if uosc_available then
        open_add_total_menu_uosc()
    elseif input_loaded then
        open_add_total_menu_select()
    end
end

mp.commandv(
    "script-message-to",
    "uosc",
    "set-button",
    "danmaku",
    utils.format_json({
        icon = "search",
        tooltip = "弹幕搜索",
        command = "script-message open_search_danmaku_menu",
    })
)
mp.commandv(
    "script-message-to",
    "uosc",
    "set-button",
    "danmaku_source",
    utils.format_json({
        icon = "add_box",
        tooltip = "从源添加弹幕",
        command = "script-message open_add_source_menu",
    })
)
mp.commandv(
    "script-message-to",
    "uosc",
    "set-button",
    "danmaku_styles",
    utils.format_json({
        icon = "palette",
        tooltip = "弹幕样式",
        command = "script-message open_setup_danmaku_menu",
    })
)
mp.commandv(
    "script-message-to",
    "uosc",
    "set-button",
    "danmaku_delay",
    utils.format_json({
        icon = "more_time",
        tooltip = "弹幕源延迟设置",
        command = "script-message open_source_delay_menu",
    })
)
mp.commandv(
    "script-message-to",
    "uosc",
    "set-button",
    "danmaku_menu",
    utils.format_json({
        icon = "grid_view",
        tooltip = "弹幕设置",
        command = "script-message open_add_total_menu",
    })
)
mp.commandv(
    "script-message-to",
    "uosc",
    "set-button",
    "danmaku_source_select",
    utils.format_json({
        icon = "source",
        tooltip = "选择弹幕源",
        command = "script-message open_danmaku_source_menu",
    })
)

mp.register_script_message('uosc-version', function()
    uosc_available = true
end)
mp.commandv("script-message-to", "uosc", "set", "show_danmaku", "off")

mp.register_script_message("set", function(prop, value)
    if prop ~= "show_danmaku" then
        return
    end
    if value == "on" then
        ENABLED = true
        if COMMENTS == nil then
            set_danmaku_visibility(true)
            local path = mp.get_property("path")
            init(path)
        else
            show_loaded()
            show_danmaku_func()
        end
    else
        show_message("关闭弹幕", 2)
        ENABLED = false
        hide_danmaku_func()
    end
    mp.commandv("script-message-to", "uosc", "set", "show_danmaku", value)
end)

-- 注册函数给 uosc 按钮使用
mp.register_script_message("search-anime-event", function(query)
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "close-menu", "menu_danmaku")
    end
    local name, class = query:match("^(.-)%s*|%s*(.-)%s*$")
    if name and class then
        query_extra(name, class)
    else
        get_animes(query)
    end
end)

mp.register_script_message("search-episodes-event", function(animeTitle, bangumiId, source_server, original_query)
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "close-menu", "menu_anime")
    end
    -- 直接调用获取剧集列表的函数，这会打开一个新的菜单
    -- 第五个参数 nil 表示非单服务器模式
    get_episodes(animeTitle, bangumiId, source_server, original_query, nil)
end)

-- 新增：专门处理从单服务器搜索结果点击进入剧集的情况
mp.register_script_message("search-episodes-single-server-event", function(animeTitle, bangumiId, source_server, original_query)
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "close-menu", "menu_single_server_result")
    end
    -- 第五个参数 true 表示是单服务器模式，返回时会回到单服务器搜索结果
    get_episodes(animeTitle, bangumiId, source_server, original_query, true)
end)

-- 注册加载函数给 uosc 按钮使用
mp.register_script_message("load-danmaku", function(animeTitle, episodeTitle, episodeId, source_server, bangumiId)
    ENABLED = true
    DANMAKU.anime = animeTitle
    DANMAKU.episode = episodeTitle

    -- 确定使用的服务器
    local used_server = source_server
    if not used_server or used_server == "" then
        -- 从history中读取服务器信息
        local path = mp.get_property("path")
        local key = get_cache_key()
        if key then
            local history_json = read_file(HISTORY_PATH)
            if history_json then
                local history = utils.parse_json(history_json) or {}
                if history[key] and history[key].server then
                    used_server = history[key].server
                end
            end
        end
        -- 如果还是没有，使用第一个服务器
        if not used_server then
            local servers = get_api_servers()
            used_server = servers[1]
        end
    end

    -- 如果有指定服务器，临时设置使用该服务器
    if source_server and source_server ~= "" then
        -- 保存原始服务器设置
        local original_servers = options.api_servers
        local original_server = options.api_server
        -- 临时设置为指定服务器
        options.api_servers = source_server
        options.api_server = source_server
        set_episode_id(episodeId, source_server, true)
        -- 恢复原始服务器设置
        options.api_servers = original_servers
        options.api_server = original_server
    else
        set_episode_id(episodeId, nil, true)
    end

    -- 更新缓存：将选择的结果保存到缓存中
    local match = {
        animeTitle = animeTitle,
        episodeTitle = episodeTitle,
        episodeId = tonumber(episodeId),
        bangumiId = bangumiId,  -- 使用传递的bangumiId
        match_type = "episode",
        similarity = 1.0
    }

    -- 如果bangumiId为空，尝试从当前菜单状态中获取
    if not bangumiId and current_menu_state.all_results and current_menu_state.all_results[used_server] then
        local server_results = current_menu_state.all_results[used_server]
        if server_results.matches and #server_results.matches > 0 then
            local found_match = server_results.matches[1]
            if found_match.bangumiId then
                match.bangumiId = found_match.bangumiId
            end
        end
    end

    save_match_to_cache(used_server, {match}, "episode", {}, true)

    --使用选中的结果保存当前菜单状态
    save_selected_episode_with_offset(used_server, animeTitle, episodeTitle, episodeId, bangumiId)
end)

mp.register_script_message("add-source-event", function(query)
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "close-menu", "menu_source")
    end
    ENABLED = true
    add_danmaku_source(query, true)
end)

mp.register_script_message("open_setup_danmaku_menu", function()
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "close-menu", "menu_total")
    end
    add_danmaku_setup()
end)

mp.register_script_message("open_content_danmaku_menu", function()
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "close-menu", "menu_total")
    end
    open_content_menu()
end)

mp.register_script_message("setup-danmaku-style", function(query, text)
    local event = utils.parse_json(query)
    if event ~= nil and type(event) == "table" then
        -- item点击 或 图标点击
        if event.type == "activate" then
            if not event.action then
                if ordered_keys[event.index] == "bold" then
                    options.bold = not options.bold
                    menu_items_config.bold.hint = options.bold and "true" or "false"
                end
                -- "updata" 模式会保留输入框文字
                add_danmaku_setup(ordered_keys[event.index], "updata")
                return
            else
                options[event.action] = menu_items_config[event.action]["original"]
                menu_items_config[event.action]["hint"] = options[event.action]
                add_danmaku_setup(event.action, "updata")
                if event.action == "fontsize" or event.action == "scrolltime" then
                    load_danmaku(true)
                end
            end
        end
    else
        -- 数值输入
        if text == nil or text == "" then
            return
        end
        local newText, _ = text:gsub("%s", "") -- 移除所有空白字符
        if tonumber(newText) ~= nil and menu_items_config[query]["scope"] ~= nil then
            local num = tonumber(newText)
            local min_num = menu_items_config[query]["scope"]["min"]
            local max_num = menu_items_config[query]["scope"]["max"]
            if num and min_num <= num and num <= max_num then
                if string.match(menu_items_config[query]["footnote"], "整数") then
                    -- 输入范围为整数时向下取整
                    num = tostring(math.floor(num))
                end
                options[query] = tostring(num)
                menu_items_config[query]["hint"] = options[query]
                -- "refresh" 模式会清除输入框文字
                add_danmaku_setup(query, "refresh")
                if query == "fontsize" or query == "scrolltime" then
                    load_danmaku(true, true)
                end
                return
            end
        end
        add_danmaku_setup(query, "error")
    end
end)

mp.register_script_message('setup-danmaku-source', function(json)
    local event = utils.parse_json(json)
    if event.type == 'activate' then
        if event.action == "delete" then
            local source = DANMAKU.sources[event.value]
            if source then
                source.data = nil
            end
            DANMAKU.sources[event.value] = nil
            remove_source_from_history(event.value)
            mp.commandv("script-message-to", "uosc", "close-menu", "menu_source")
            open_add_menu_uosc()
            load_danmaku(true)
        end
        if event.action == "block" then
            local active_count = 0
            for _, s in pairs(DANMAKU.sources) do
                if not s.blocked and s.data then
                    active_count = active_count + 1
                end
            end

            if active_count <= 1 then
                show_message("无法屏蔽：至少保留一个弹幕源", 2)
                return
            end
            DANMAKU.sources[event.value]["blocked"] = true
            add_source_to_history(event.value, DANMAKU.sources[event.value])
            mp.commandv("script-message-to", "uosc", "close-menu", "menu_source")
            open_add_menu_uosc()
            load_danmaku(true)
        end
        if event.action == "unblock" then
            DANMAKU.sources[event.value]["blocked"] = false
            add_source_to_history(event.value, DANMAKU.sources[event.value])
            mp.commandv("script-message-to", "uosc", "close-menu", "menu_source")
            open_add_menu_uosc()
            load_danmaku(true)
        end
    end
end)

mp.register_script_message("setup-source-delay", function(query, text)
    local event = utils.parse_json(query)
    if event ~= nil then
        -- item点击
        if event.type == "activate" then
            danmaku_delay_setup(event.value)
        end
    else
        -- 数值输入
        if text == nil or text == "" then
            return
        end
        local newText, _ = text:gsub("%s", "") -- 移除所有空白字符
        local num = tonumber(newText)
        local delay_segments = shallow_copy(DANMAKU.sources[query]["delay_segments"] or {})
        for i = #delay_segments, 1, -1 do
            if delay_segments[i].start == 0 then
                table.remove(delay_segments, i)
            end
        end
        if num ~= nil then
            table.insert(delay_segments, 1, { start = 0, delay = tonumber(num) })
            DANMAKU.sources[query]["delay_segments"] = delay_segments
            add_source_to_history(query, DANMAKU.sources[query])
            mp.commandv("script-message-to", "uosc", "close-menu", "menu_delay")
            danmaku_delay_setup(query)
            load_danmaku(true, true)
        elseif newText:match("^%-?%d+m%d+s$") then
            local minutes, seconds = string.match(newText, "^(%-?%d+)m(%d+)s$")
            minutes = tonumber(minutes)
            seconds = tonumber(seconds)
            if minutes < 0 then seconds = -seconds end
            table.insert(delay_segments, 1, { start = 0, delay = 60 * minutes + seconds })
            DANMAKU.sources[query]["delay_segments"] = delay_segments
            add_source_to_history(query, DANMAKU.sources[query])
            mp.commandv("script-message-to", "uosc", "close-menu", "menu_delay")
            danmaku_delay_setup(query)
            load_danmaku(true, true)
        end
    end
end)

local MATCH_CACHE = {}
local MATCH_CACHE_PATH = mp.command_native({"expand-path", options.match_cache_path})
local MAX_CACHE_ENTRIES = 100
local CACHE_EXPIRE_DAYS = 30

-- 加载匹配结果缓存
local function load_match_cache()
    local cache_json = read_file(MATCH_CACHE_PATH)
    if cache_json then
        local cache = utils.parse_json(cache_json) or {}
        local current_time = os.time()
        local cleaned_cache = {}
        local count = 0
        -- 清理过期缓存
        for key, entry in pairs(cache) do
            if entry.timestamp and (current_time - entry.timestamp) < (CACHE_EXPIRE_DAYS * 24 * 3600) then
                cleaned_cache[key] = entry
                count = count + 1
            end
        end
        -- 如果超过最大条目数，删除最旧的
        if count > MAX_CACHE_ENTRIES then
            local sorted = {}
            for key, entry in pairs(cleaned_cache) do
                table.insert(sorted, {key = key, timestamp = entry.timestamp})
            end
            table.sort(sorted, function(a, b) return a.timestamp < b.timestamp end)
            for i = 1, count - MAX_CACHE_ENTRIES do
                cleaned_cache[sorted[i].key] = nil
            end
        end
        MATCH_CACHE = cleaned_cache
    end
end

-- 保存匹配结果缓存
local function save_match_cache()
    write_json_file(MATCH_CACHE_PATH, MATCH_CACHE)
end

local function _set_current_server_for_cache(cache_key, new_server, episode_id)
    if not cache_key or not new_server then return end
    local entry = MATCH_CACHE[cache_key]
    if not entry then return end

    -- 如果原来有 current_server 且不同，则把之前的一对 server+episodeId 记到 prev_xx
    if entry.current_server and entry.current_server ~= new_server then
        entry.prev_server      = entry.current_server
        entry.prev_episode_id  = entry.current_episode_id
    end
    entry.current_server = new_server
    if episode_id ~= nil then
        entry.current_episode_id = episode_id
    end
end

-- 加载弹幕空回退
function restore_prev_server()
    local cache_key = get_cache_key()
    if not cache_key then return end
    local entry = MATCH_CACHE[cache_key]
    if not entry then return end
    if entry.prev_server and entry.current_server
       and entry.current_server ~= entry.prev_server then
        msg.info(string.format(
            "当前 server (%s) 弹幕为空，恢复到上一个 server (%s)",
            tostring(entry.current_server),
            tostring(entry.prev_server)
        ))
        local prev_server = entry.prev_server
        local prev_eid    = entry.prev_episode_id
        entry.current_server      = prev_server
        entry.current_episode_id  = prev_eid or entry.current_episode_id
        entry.prev_server         = nil
        entry.prev_episode_id     = nil
        local history_json = read_file(HISTORY_PATH)
        if history_json then
            local history = utils.parse_json(history_json) or {}
            local key = get_cache_key()
            local record = history[key]
            if record then
                if record.server ~= prev_server then
                    msg.verbose(string.format(
                        "restore_prev_server: history.server %s -> %s (key=%s)",
                        tostring(record.server), tostring(prev_server), tostring(key)
                    ))
                    record.server = prev_server
                end
                if prev_eid then
                    msg.verbose(string.format(
                        "restore_prev_server: history.episodeId %s -> %s (key=%s)",
                        tostring(record.episodeId), tostring(prev_eid), tostring(key)
                    ))
                    record.episodeId = prev_eid
                end
                history[key] = record
                write_json_file(HISTORY_PATH, history)
            else
                msg.verbose("restore_prev_server: 未在 history 中找到 key=" .. tostring(key))
            end
        end
        save_match_cache()
    end
end

function get_cache_key()
    local title, season_num, episod_num = parse_title()
    title = title or ""
    local season = tonumber(season_num) or 0
    return title .. "|" .. tostring(season)
end

function get_current_server_from_cache()
    local cache_key = get_cache_key()
    if MATCH_CACHE[cache_key] then
        return MATCH_CACHE[cache_key].current_server
    end
    return nil
end

function save_match_to_cache(server, matches, match_type, danmaku_counts, lock_entry, update_current_server)
    lock_entry = lock_entry or false
    update_current_server = update_current_server == nil and true or update_current_server
    local cache_key = get_cache_key()
    if not MATCH_CACHE[cache_key] then
        MATCH_CACHE[cache_key] = {
            timestamp = os.time(),
            servers = {},
            current_server = nil
        }
    end
    local existing_entry = MATCH_CACHE[cache_key].servers[server]
    if existing_entry and existing_entry.locked and not lock_entry then
        return
    end
    MATCH_CACHE[cache_key].servers[server] = {
        matches = matches,
        match_type = match_type,
        timestamp = os.time(),
        danmaku_counts = danmaku_counts or {},
        locked = lock_entry or nil
    }
    if server and update_current_server then
        local eid = get_history_episode_id()
        _set_current_server_for_cache(cache_key, server, eid)
    end
    save_match_cache()
end

local function get_match_from_cache(server)
    local cache_key = get_cache_key()
    if MATCH_CACHE[cache_key] and MATCH_CACHE[cache_key].servers[server] then
        local entry = MATCH_CACHE[cache_key].servers[server]
        local current_time = os.time()
        if (current_time - entry.timestamp) < (CACHE_EXPIRE_DAYS * 24 * 3600) then
            -- 确保danmaku_counts的key都是string类型
            local danmaku_counts = {}
            if entry.danmaku_counts then
                for k, v in pairs(entry.danmaku_counts) do
                    danmaku_counts[tostring(k)] = v
                end
            end
            return entry.matches, entry.match_type, danmaku_counts, entry.locked
        end
    end
    return nil, nil, nil, nil
end

function apply_danmaku_offset_update(offset_x, current_server)
    local cache_key = get_cache_key()
    if MATCH_CACHE[cache_key] and MATCH_CACHE[cache_key].servers then
        for srv, data in pairs(MATCH_CACHE[cache_key].servers) do
            if data.matches then
                for _, m in ipairs(data.matches) do
                    local episodeNumber = get_episode_number(m.episodeTitle)
                    if not episodeNumber then
                        local _, _, ep_num = parse_title()
                        episodeNumber = ep_num
                    end
                    if m.episodeId and episodeNumber then
                        local old_id = tonumber(m.episodeId)
                        local old_num = tonumber(episodeNumber)

                        if old_id and old_num then
                            m.episodeId = old_id + offset_x
                            m.episodeNumber = old_num + offset_x
                            m.episodeTitle = string.format("第%s话", m.episodeNumber)
                            save_match_to_cache(srv, data.matches, data.match_type, data.danmaku_counts, data.locked, false)
                            if srv == current_server then
                                save_selected_episode_with_offset(
                                    srv,
                                    DANMAKU.anime,
                                    m.episodeTitle,
                                    m.episodeId,
                                    m.bangumiId
                                )
                            end
                        end
                    end
                end
            end
        end
        save_match_cache()
        current_menu_state.all_results = MATCH_CACHE[cache_key].servers
        current_menu_state.servers = get_api_servers()
        current_menu_state.expanded_key = nil
        current_menu_state.episodes = nil
    end
end

-- 处理文件匹配结果（用于非 dandanplay 服务器）
local function process_file_match_results(results, title, servers)
    local all_results = {}
    for _, server in ipairs(servers) do
        local r = nil
        for _, rr in ipairs(results) do
            if rr.server == server then
                r = rr
                break
            end
        end
        local matches = {}
        if r and r.data then
            local data = r.data
            if data.isMatched and data.matches and #data.matches == 1 then
                local match = data.matches[1]
                match.match_type = "episode"
                match.similarity = 1.0
                local id = inferBangumiId(match, server)
                if id then
                    match.bangumiId = id
                end
                matches = {match}
            elseif data.matches and #data.matches > 1 then
                -- 多个匹配结果，选择标题完全匹配的
                for _, match in ipairs(data.matches) do
                    if match.animeTitle == title then
                        match.match_type = "episode"
                        match.similarity = 1.0
                        -- 添加相同的判断逻辑
                        local id = inferBangumiId(match, server)
                        if id then
                            match.bangumiId = id
                        end
                        matches = {match}
                        break
                    end
                end
                -- 如果没有完全匹配，使用第一个
                if #matches == 0 then
                    data.matches[1].match_type = "episode"
                    data.matches[1].similarity = 0.8
                    -- 添加相同的判断逻辑
                    local match = data.matches[1]
                    local id = inferBangumiId(match, server)
                    if id then
                        match.bangumiId = id
                    end
                    matches = {data.matches[1]}
                end
            end
        end
        all_results[server] = {
            matches = matches,
            match_type = "episode",
            danmaku_counts = {},
            from_cache = false
        }
    end
    return all_results
end

local function get_all_servers_matches(file_path, file_name, callback, update_current_server)
    update_current_server = update_current_server or false
    local servers = get_api_servers()
    local all_results = {}
    local completed = 0
    local total = #servers
    -- 获取当前文件的标题
    local current_title, current_season, current_episode = parse_title()
    if not current_title or current_title == "" then
        if callback then callback(all_results) end
        return
    end
    -- 先收集所有服务器的缓存状态
    local servers_to_request = {}  -- 需要请求的服务器列表
    local cached_servers = {}      -- 已有缓存的服务器列表
    for _, server in ipairs(servers) do
        local cached_matches, cached_type, cached_counts = get_match_from_cache(server)
        if cached_matches and #cached_matches > 0 then
            -- 服务器有缓存，直接使用缓存数据
            cached_servers[server] = {
                matches = cached_matches,
                match_type = cached_type,
                danmaku_counts = cached_counts or {},
                from_cache = true
            }
            msg.verbose("服务器 " .. server .. " 使用缓存数据，跳过请求")
        else
            -- 服务器没有缓存，需要请求
            table.insert(servers_to_request, server)
        end
    end

    -- 将所有缓存数据添加到最终结果中
    for server, cached_data in pairs(cached_servers) do
        all_results[server] = cached_data
    end

    -- 如果没有需要请求的服务器，直接返回缓存数据
    if #servers_to_request == 0 then
        msg.verbose("所有服务器都有缓存，跳过网络请求")
        if callback then callback(all_results) end
        return
    end

    -- 初始化并发管理器
    local concurrent_manager = ConcurrentManager:new()
    local request_count = 0

    -- 区分 dandanplay 和非 dandanplay 服务器
    local dandanplay_servers = {}
    local other_servers = {}
    for _, server in ipairs(servers_to_request) do
        if server:find("api%.dandanplay%.") then
            table.insert(dandanplay_servers, server)
        else
            table.insert(other_servers, server)
        end
    end

    -- 处理 dandanplay 服务器（使用搜索方式）
    local encoded_query = clean_anime_title(current_title)
    for i, server in ipairs(dandanplay_servers) do
        local endpoint = "/api/v2/search/anime?keyword=" .. encoded_query
        local url = server .. endpoint
        local args = make_danmaku_request_args("GET", url, nil, nil)
        if args then
            request_count = request_count + 1
            local request_func = function(callback_func)
                call_cmd_async(args, function(error, json)
                    local result = {
                        success = false,
                        server = server,
                        animes = {}
                    }
                    if not error and json then
                        local success, parsed = pcall(utils.parse_json, json)
                        if success and parsed and parsed.animes then
                            result.success = true
                            result.animes = parsed.animes
                        end
                    end
                    callback_func(result)
                end)
            end
            concurrent_manager:start_request(server, i, request_func)
        end
    end

    -- 处理非 dandanplay 服务器（使用match方式，不计算哈希减少阻塞）
    if #other_servers > 0 then
        local file_info = utils.file_info(file_path)
        local title, season_num, episode_num = parse_title()
        local match_file_name = file_name
        if title and episode_num then
            if season_num then
                match_file_name = title .. " S" .. season_num .. "E" .. episode_num
            else
                match_file_name = title .. " E" .. episode_num
            end
        else
            match_file_name = title or file_name
        end

        local endpoint = "/api/v2/match"
        local body = {
            fileName   = match_file_name,
            fileHash   = "a1b2c3d4e5f67890abcd1234ef567890",
            matchMode  = "fileNameOnly"
        }
        for i, server in ipairs(other_servers) do
            local url = server .. endpoint
            local args = make_danmaku_request_args("POST", url, {
                ["Content-Type"] = "application/json"
            }, body)
            if args then
                request_count = request_count + 1
                concurrent_manager:start_request(server, i, function(cb)
                    call_cmd_async(args, function(error, json)
                        local result = {
                            server = server,
                            error = error,
                            data = nil,
                            index = i
                        }
                        if not error and json then
                            local success, parsed = pcall(utils.parse_json, json)
                            if success then
                                result.data = parsed
                            else
                                result.error = "JSON解析失败"
                            end
                        end
                        cb(result)
                    end)
                end)
            else
                if not concurrent_manager.results[server] then
                    concurrent_manager.results[server] = {}
                end
                concurrent_manager.results[server][i] = {
                    server = server,
                    error = "无法生成请求参数",
                    data = nil,
                    index = i
                }
            end
        end
    end

    -- 如果没有需要请求的服务器，直接返回
    if request_count == 0 then
        if callback then callback(all_results) end
        return
    end

    local callback_executed = false
    concurrent_manager:wait_all(function()
        if callback_executed then
            return
        end
        callback_executed = true

        mp.add_timeout(0.01, function()
            local dandan_tasks = {}

            -- 收集所有需要处理的 dandan 结果
            for server, server_results in pairs(concurrent_manager.results) do
                for key, result in pairs(server_results) do
                    if result.success and result.animes then
                        table.insert(dandan_tasks, {
                            server = server,
                            animes = result.animes
                        })
                    end
                end
            end

            -- 定义处理完成后的回调
            local function finalize_process()
                -- 处理非 dandanplay 服务器的结果
                local results = {}
                for server, server_results in pairs(concurrent_manager.results) do
                    for i, result in pairs(server_results) do
                        if result.server and result.server:find("api%.dandanplay%.") == nil then
                            table.insert(results, result)
                        end
                    end
                end
                table.sort(results, function(a, b)
                    return a.index < b.index
                end)

                local file_match_results = process_file_match_results(results, current_title, other_servers)
                for server, result in pairs(file_match_results) do
                    all_results[server] = result
                    save_match_to_cache(server, result.matches, "episode", {}, false, update_current_server)
                end
                if callback then callback(all_results) end
            end

            local pending_count = #dandan_tasks

            if pending_count == 0 then
                finalize_process()
            else
                for _, task in ipairs(dandan_tasks) do
                    process_anime_matches(task.animes, current_title, current_season, task.server, function(matches)
                        if matches and #matches > 0 then
                             all_results[task.server] = {
                                matches = matches,
                                match_type = "anime",
                                danmaku_counts = {},
                                from_cache = false
                            }
                            save_match_to_cache(task.server, matches, "anime", {}, false, update_current_server)
                        end

                        pending_count = pending_count - 1
                        if pending_count == 0 then
                            finalize_process()
                        end
                    end)
                end
            end
        end)
    end)
end

function save_selected_episode_with_offset(server, animeTitle, episodeTitle, episodeId, bangumiId)
    local current_title, current_season, current_episode = parse_title()
    current_episode = tonumber(current_episode) or 1

    -- 从剧集标题中提取集数
    local selected_episode_num = get_episode_number (episodeTitle)

    -- 计算相对偏移
    local episode_offset = nil
    if selected_episode_num then
        episode_offset = selected_episode_num - current_episode
        msg.verbose(string.format("计算集数偏移: 选择集数=%d, 当前集数=%d, 偏移=%d",
            selected_episode_num, current_episode, episode_offset))
    else
        msg.verbose("无法从剧集标题中提取集数，使用固定偏移0")
        episode_offset = 0
    end

    -- 保存选择记录
    current_menu_state.selected_episode = {
        server = server,
        animeTitle = animeTitle,
        episodeId = tonumber(episodeId),
        episodeTitle = episodeTitle,
        episodeNumber = selected_episode_num,
        base_episode = current_episode,  -- 选择时的基础集数
        episode_offset = episode_offset,  -- 相对偏移
        bangumiId = bangumiId,
        timestamp = os.time()
    }
    msg.verbose(string.format("✅ 记录选择: %s - %s (偏移: %+d)",
        animeTitle, episodeTitle, episode_offset or 0))
end

-- 单个服务器搜索功能
function search_single_server(server, query)
    -- 尝试读取缓存
    if current_menu_state.single_server_cache and
       current_menu_state.single_server_cache.server == server and
       current_menu_state.single_server_cache.query == query and
       current_menu_state.single_server_cache.items then

        local has_loading_item = false
        if current_menu_state.single_server_cache.items then
             for _, item in ipairs(current_menu_state.single_server_cache.items) do
                 if item.title and (item.title:match("^正在搜索") or item.title:match("搜索正在启动")) then
                     has_loading_item = true
                     break
                 end
             end
        end

        if not has_loading_item then
            local items = current_menu_state.single_server_cache.items
            local menu_type = "menu_single_server_result"
            local menu_title = "搜索结果 - " .. extract_server_identifier(server)

            local result_props = {
                type = menu_type,
                title = menu_title,
                search_style = "disabled",
                items = items
            }
            mp.add_timeout(0.05, function()
                mp.commandv("script-message-to", "uosc", "open-menu", utils.format_json(result_props))
            end)
            return
        end
    end

    -- 初始化新搜索状态
    current_menu_state.single_server_search_id = (current_menu_state.single_server_search_id or 0) + 1
    local this_search_id = current_menu_state.single_server_search_id

    -- 清理旧的定时器并设置新的自动清理定时器
    if current_menu_state.single_server_timer then current_menu_state.single_server_timer:kill() end
    current_menu_state.single_server_timer = mp.add_timeout(30, function()
        if current_menu_state.single_server_search_id == this_search_id then
            current_menu_state.single_server_cache = nil
            current_menu_state.single_server_timer = nil
        end
    end)

    -- 执行搜索请求
    local encoded_query = url_encode(query)
    local endpoint = "/api/v2/search/anime?keyword=" .. encoded_query
    local url = server .. endpoint

    local menu_type = "menu_single_server_result"
    local menu_title = "搜索结果 - " .. extract_server_identifier(server)

    -- 初始加载状态
    local function show_loading_menu(loading_text, hint_text)
        local loading_items = {
            {
                title = loading_text or "正在搜索...",
                hint = hint_text,
                italic = true,
                keep_open = true,
                selectable = false
            }
        }
        local menu_props = {
            type = menu_type,
            title = menu_title,
            search_style = "disabled",
            items = loading_items
        }
        return menu_props
    end

    -- 初次打开菜单
    mp.commandv("script-message-to", "uosc", "open-menu", utils.format_json(show_loading_menu()))

    local args = make_danmaku_request_args("GET", url, nil, nil)
    if not args then return end

    local MAX_RETRIES = 10 -- 最大重试次数

    -- 内部递归执行函数
    local function execute_request(retry_count)
        retry_count = retry_count or 0

        call_cmd_async(args, function(error, json)
            -- 检查ID是否匹配，防止旧请求覆盖新请求
            if current_menu_state.single_server_search_id ~= this_search_id then return end

            local items = {}
            local is_still_loading = false
            local loading_text = ""
            local loading_hint = ""

            -- 添加返回按钮
            table.insert(items, {
                title = "← 返回上一级",
                value = { "script-message-to", mp.get_script_name(), "open_danmaku_source_menu" },
                keep_open = false,
                selectable = true,
            })

            if not error and json then
                local success, parsed = pcall(utils.parse_json, json)
                if success and parsed and parsed.animes then
                    if #parsed.animes > 0 then
                        for _, anime in ipairs(parsed.animes) do
                            -- 检查是否是加载状态条目
                            if anime.animeTitle and (anime.animeTitle:find("搜索正在启动") or anime.animeTitle:find("搜索正在运行")) then
                                is_still_loading = true
                                loading_text = anime.animeTitle
                                loading_hint = anime.typeDescription or ""
                                break
                            end

                            table.insert(items, {
                                title = anime.animeTitle,
                                hint = anime.typeDescription,
                                value = {
                                    "script-message-to",
                                    mp.get_script_name(),
                                    "search-episodes-single-server-event",
                                    anime.animeTitle,
                                    tostring(anime.bangumiId or anime.animeId),
                                    server,
                                    query
                                },
                                keep_open = false,
                                selectable = true,
                            })
                        end
                    else
                        table.insert(items, {
                            title = "无匹配结果",
                            italic = true,
                            keep_open = true,
                            selectable = false,
                        })
                    end
                else
                     table.insert(items, {
                        title = "无匹配结果 (解析为空)",
                        italic = true,
                        keep_open = true,
                        selectable = false,
                    })
                end
            else
                table.insert(items, {
                    title = "搜索失败: " .. (error or "未知错误"),
                    italic = true,
                    keep_open = true,
                    selectable = false,
                })
            end

            -- 逻辑分支：继续重试 OR 显示结果
            if is_still_loading and retry_count < MAX_RETRIES then
                msg.verbose(string.format("单服务器 [%s] 状态: %s (重试: %d/%d)", server, loading_text, retry_count, MAX_RETRIES))

                -- 构造一个临时的加载中菜单项列表
                local temp_loading_items = {
                    {
                        title = "← 返回上一级",
                        value = { "script-message-to", mp.get_script_name(), "open_danmaku_source_menu" },
                        keep_open = false,
                        selectable = true,
                    },
                    {
                        title = loading_text .. " (" .. (retry_count + 1) .. "/" .. MAX_RETRIES .. ")",
                        hint = loading_hint,
                        italic = true,
                        keep_open = true,
                        selectable = false,
                    }
                }

                local result_props = {
                    type = menu_type,
                    title = menu_title,
                    items = temp_loading_items
                }
                mp.commandv("script-message-to", "uosc", "update-menu", utils.format_json(result_props))

                -- 3秒后重试
                mp.add_timeout(3, function()
                    if current_menu_state.single_server_search_id == this_search_id then
                        execute_request(retry_count + 1)
                    end
                end)
            else
                -- 最终结果
                if is_still_loading and retry_count >= MAX_RETRIES then
                    msg.warn("服务器 [" .. server .. "] 单独搜索超时")
                    items = {
                         {
                            title = "← 返回上一级",
                            value = { "script-message-to", mp.get_script_name(), "open_danmaku_source_menu" },
                            keep_open = false,
                            selectable = true,
                        },
                        {
                            title = "搜索超时 (服务器响应慢)",
                            italic = true,
                            keep_open = true,
                            selectable = false,
                        }
                    }
                end

                -- 更新缓存
                current_menu_state.single_server_cache = {
                    server = server,
                    query = query,
                    items = items
                }

                local result_props = {
                    type = menu_type,
                    title = menu_title,
                    items = items
                }
                mp.commandv("script-message-to", "uosc", "update-menu", utils.format_json(result_props))
            end
        end)
    end
    execute_request(0)
end

-- 构建菜单项的函数（支持展开的剧集列表）
local function build_menu_items_with_expanded(all_results, servers, show_refresh, expanded_key, current_server, loading_key, error_key, error_message)
    local items = {}
    local expanded_server, expanded_anime = nil, nil
    if expanded_key then
        expanded_server, expanded_anime = expanded_key:match("^(.+)|(.+)$")
    end
    local current_active_episode_id = tonumber(get_history_episode_id())

    local function get_source_status_fuzzy(episode_id)
        if not DANMAKU or not DANMAKU.sources then return nil end
        local id_str = tostring(episode_id)
        local pattern = "/api/v2/comment/" .. id_str

        for src_url, src_data in pairs(DANMAKU.sources) do
            if src_url:find(pattern, 1, true) then
                return src_data
            end
        end
        return nil
    end

    -- 添加刷新按钮
    if show_refresh then
        table.insert(items, {
            title = "🔄 刷新匹配结果",
            hint = "清除缓存并重新加载",
            value = { "script-message-to", mp.get_script_name(), "refresh-danmaku-matches" },
            keep_open = false,
            selectable = true,
        })
        table.insert(items, { title = "", italic = true, keep_open = true, selectable = false })
    end

    -- 获取当前文件的集数
    local _, _, current_episode_num = parse_title()
    current_episode_num = tonumber(current_episode_num) or 1

    -- 计算当前应激活的集数（如果设置了偏移）
    local dynamic_ep_num = get_current_selected_episode_number(current_episode_num)

    for _, server in ipairs(servers) do
        local result = all_results[server]
        local server_id = extract_server_identifier(server)
        local match_count = result and #result.matches or 0

        -- 检查该服务器是否被手动选中了剧集（即设置了偏移）
        local is_manual_on_this_server = current_menu_state.selected_episode and current_menu_state.selected_episode.server == server

        local header_hint = ""
        if is_manual_on_this_server then
             header_hint = "1个手动选中 | " .. server
        else
             header_hint = (match_count > 0 and (match_count .. "个自动匹配") or "无自动匹配") .. " | " .. server
        end

        -- 创建服务器项（点击进行搜索）
        table.insert(items, {
            title = "🔍 " .. server_id .. " - 点击在此服务器搜索",
            hint = header_hint,
            value = { "script-message-to", mp.get_script_name(), "open-server-search-input", server },
            keep_open = false,
            selectable = true,
            bold = true,
        })

        -- 添加匹配结果作为可选项
        if result and result.matches and #result.matches > 0 then
            for _, match in ipairs(result.matches) do
                local match_title = ""
                local match_hint = ""
                local danmaku_count = 0

                if result.danmaku_counts and match.episodeId then
                    local episode_id_str = tostring(match.episodeId)
                    danmaku_count = result.danmaku_counts[episode_id_str] or 0
                end

                local is_current_server = (server == current_server)

                -- 检查是否有手动选择的剧集信息，用于覆盖显示
                local display_episode_title = match.episodeTitle
                local display_episode_num = match.episodeNumber

                if is_manual_on_this_server and current_menu_state.selected_episode.animeTitle == match.animeTitle then
                    display_episode_title = current_menu_state.selected_episode.episodeTitle
                    display_episode_num = current_menu_state.selected_episode.episodeNumber
                end

                local ep_num_str = display_episode_num
                if not ep_num_str or ep_num_str == "" then
                    ep_num_str = current_episode_num or "?"
                end

                if result.match_type == "anime" then
                    local prefix = is_current_server and "⭐ " or "  └─ "
                    match_title = prefix .. (match.animeTitle or "未知")
                    match_hint = "匹配度 " .. (match.similarity and math.floor(match.similarity * 100) .. "%" or "?")
                else
                    local is_active = false
                    if is_current_server then
                        if match.episodeId and current_active_episode_id and tonumber(match.episodeId) == current_active_episode_id then
                             is_active = true
                        else
                            local check_num = tonumber(display_episode_num)
                            if dynamic_ep_num and check_num == dynamic_ep_num then
                                is_active = true
                            elseif (not dynamic_ep_num) and check_num == current_episode_num then
                                is_active = true
                            end
                        end
                    end
                    local prefix = is_active and "⭐ " or "  └─ "
                    match_title = prefix .. (match.animeTitle or "未知") .. " - " .. (display_episode_title or "未知")
                    match_hint = "第" .. ep_num_str .. "集" ..
                        (danmaku_count > 0 and (" | " .. danmaku_count .. "条弹幕") or "")
                end

                table.insert(items, {
                    title = match_title,
                    hint = match_hint,
                    value = { "script-message-to", mp.get_script_name(), "switch-danmaku-source", server, result.match_type, utils.format_json(match) },
                    keep_open = false,
                    selectable = true,
                    active = is_current_server and (result.match_type ~= "anime"),
                })

                -- 展开/收起按钮逻辑
                if match.animeTitle then
                    local bangumi_id = match.bangumiId or match.animeId
                    local key = server .. "|" .. match.animeTitle
                    local is_expanded = expanded_key == key
                    local expand_cmd = "expand-episodes-menu"
                    if not bangumi_id then expand_cmd = "search-and-expand-episodes" end
                    if is_expanded then expand_cmd = "collapse-episodes-menu" end

                    table.insert(items, {
                        title = is_expanded and "      ↳ 收起剧集列表" or "      ↳ 手动选择该番剧集数",
                        hint = is_expanded and "点击收起" or "点击展开剧集列表",
                        value = { "script-message-to", mp.get_script_name(), expand_cmd, server, tostring(bangumi_id or ""), match.animeTitle or "未知标题", utils.format_json(match) },
                        keep_open = true,
                        selectable = true,
                    })

                    if loading_key and loading_key == key then
                        table.insert(items, {
                            title = "        ⏳ 加载剧集列表中...",
                            italic = true,
                            keep_open = true,
                            selectable = false
                        })
                    end

                    if error_key and error_key == key and error_message then
                        table.insert(items, {
                            title = "        ⚠️ " .. error_message,
                            italic = true,
                            muted = true,
                            keep_open = true,
                            selectable = false
                        })
                    end

                    -- 展开状态下的剧集列表
                    if is_expanded and current_menu_state.episodes then
                        local apply_dynamic_selection = is_manual_on_this_server or is_current_server

                        for _, episode in ipairs(current_menu_state.episodes) do
                            local ep_title = episode.episodeTitle or "未知标题"
                            local ep_num = episode.episodeNumber
                            local list_ep_num_str = ep_num or (current_episode_num or "?")

                            -- 构造 URL 用于添加，但不用于检测状态
                            local comment_url_add = server .. "/api/v2/comment/" .. episode.episodeId .. "?withRelated=true&chConvert=0"

                            local source_info = get_source_status_fuzzy(episode.episodeId)

                            local status_hint_suffix = ""
                            local item_actions = {}

                            -- 右侧小图标的 action
                            if source_info then
                                if source_info.blocked then
                                    status_hint_suffix = " (已屏蔽)"
                                    table.insert(item_actions, {
                                        name = "unblock",
                                        icon = "check_circle",
                                        label = "解除屏蔽此源",
                                        value = comment_url_add
                                    })
                                else
                                    status_hint_suffix = " (已加载)"
                                    table.insert(item_actions, {
                                        name = "block",
                                        icon = "block",
                                        label = "屏蔽此源",
                                        value = comment_url_add
                                    })
                                end
                            else
                                table.insert(item_actions, {
                                    name = "add",
                                    icon = "add_circle",
                                    label = "添加此源 (不切换)",
                                    value = comment_url_add
                                })
                            end

                            local is_current_ep = false

                            -- 如果是当前服务器，且 episodeId 与 history 中的一致，则是当前集
                            if is_current_server and current_active_episode_id and tonumber(episode.episodeId) == current_active_episode_id then
                                is_current_ep = true
                            -- 回退到集数偏移逻辑
                            else
                                local ep_num_val = tonumber(ep_num)
                                if apply_dynamic_selection and dynamic_ep_num and ep_num_val and ep_num_val == dynamic_ep_num then
                                    is_current_ep = true
                                elseif (not apply_dynamic_selection) and ep_num_val and ep_num_val == current_episode_num then
                                    is_current_ep = true
                                end
                            end

                            local display_title = "        └─ " .. ep_title
                            if is_current_ep then display_title = "        ⭐ " .. ep_title end

                            local final_hint = "第" .. list_ep_num_str .. "集" ..
                                (is_current_ep and " (当前)" or "") .. status_hint_suffix

                            table.insert(items, {
                                title = display_title,
                                hint = final_hint,
                                value = {
                                    "script-message-to",
                                    mp.get_script_name(),
                                    "load-danmaku",
                                    match.animeTitle,
                                    ep_title,
                                    tostring(episode.episodeId),
                                    server,
                                    tostring(bangumi_id)
                                },
                                keep_open = false,
                                selectable = true,
                                active = is_current_ep,
                                actions = item_actions,
                            })
                        end
                    end
                end
            end
        else
            table.insert(items, {title = "  └─ 无匹配结果", italic = true, keep_open = true, selectable = false})
        end
    end

    return items
end

-- 打开弹幕源选择菜单
function open_danmaku_source_menu(force_refresh)
    if not uosc_available then
        show_message("无uosc UI框架，不支持使用该功能", 2)
        return
    end

    local items = {}
    local servers = get_api_servers()
    local current_server = get_current_server_from_cache()

    local menu_props = {
        type = "menu_danmaku_source",
        title = "选择弹幕源",
        search_style = "disabled",
        items = items,
        item_actions_place = "outside",
        callback = { mp.get_script_name(), 'handle-danmaku-source-action' },
    }

    -- 如果强制刷新，清除缓存和菜单状态
    if force_refresh then
        local cache_key = get_cache_key()
        if MATCH_CACHE[cache_key] then
            MATCH_CACHE[cache_key].servers = {}
            MATCH_CACHE[cache_key].current_server = nil
            save_match_cache()
            msg.info("已清除匹配缓存，重新加载匹配结果")
            current_server = nil
        end
        current_menu_state.all_results = nil
    end

    -- 检查缓存中是否有数据
    local has_cached_data = false
    local cached_results = {}
    for _, server in ipairs(servers) do
        local cached_matches, cached_type, cached_counts = get_match_from_cache(server)
        if cached_matches and #cached_matches > 0 then
            cached_results[server] = {
                matches = cached_matches,
                match_type = cached_type,
                danmaku_counts = cached_counts or {},
                from_cache = true
            }
            has_cached_data = true
        end
    end

    -- 优先使用 current_menu_state 中的数据（如果存在且是当前文件的数据）
    local use_menu_state = false
    if current_menu_state.all_results and current_menu_state.servers and
       not force_refresh then
        -- 菜单状态存在，直接使用
        use_menu_state = true
    end

    if use_menu_state then
        -- 使用菜单状态中的数据
        items = build_menu_items_with_expanded(current_menu_state.all_results, servers, true, current_menu_state.expanded_key, current_server, nil)
        menu_props.items = items
        local json_props = utils.format_json(menu_props)
        mp.commandv("script-message-to", "uosc", "open-menu", json_props)
        return
    end

    -- 如果有缓存数据且不是强制刷新，直接显示缓存数据
    if has_cached_data and not force_refresh then
        current_menu_state.all_results = cached_results
        current_menu_state.servers = servers
        current_menu_state.expanded_key = nil
        current_menu_state.episodes = nil

        items = build_menu_items_with_expanded(cached_results, servers, true, nil, current_server, nil)
        menu_props.items = items
        local json_props = utils.format_json(menu_props)
        mp.commandv("script-message-to", "uosc", "open-menu", json_props)

        -- 不再进行后台更新，直接使用缓存数据
        msg.verbose("使用缓存数据，跳过后台更新")
        return
    end

    -- 没有缓存数据或强制刷新，显示加载提示并获取数据
    if not has_cached_data or force_refresh then
        table.insert(items, {
            title = "正在搜索匹配结果...",
            italic = true,
            keep_open = true,
            selectable = false,
            align = "center",
        })
        local json_props = utils.format_json(menu_props)
        mp.commandv("script-message-to", "uosc", "open-menu", json_props)

        -- 获取所有服务器的匹配结果
        local path = mp.get_property("path")
        local file_name = mp.get_property("filename/no-ext")
        get_all_servers_matches(path, file_name, function(all_results)
            -- 更新菜单状态
            current_menu_state.all_results = all_results
            current_menu_state.servers = servers
            current_menu_state.expanded_key = nil
            current_menu_state.episodes = nil

            items = build_menu_items_with_expanded(all_results, servers, true, nil, current_server, nil)

            -- 更新菜单
            menu_props.items = items
            local json_props = utils.format_json(menu_props)
            mp.commandv("script-message-to", "uosc", "update-menu", json_props)
        end)
    end
end

-- 在当前菜单中展开剧集列表
local function expand_episodes_in_menu(server, bangumiId, animeTitle, match_json)
    local endpoint = "/api/v2/bangumi/" .. bangumiId
    local url = server .. endpoint
    local args = make_danmaku_request_args("GET", url, nil, nil)
    if not args then
        show_message("无法生成请求参数", 3)
        return
    end

    -- 唯一键标识
    local loading_key = server .. "|" .. animeTitle

    -- 显示加载提示
    if current_menu_state.all_results and current_menu_state.servers then
        local current_server = get_current_server_from_cache()
        local loading_items = build_menu_items_with_expanded(
            current_menu_state.all_results,
            current_menu_state.servers,
            true,
            current_menu_state.expanded_key, -- 保持当前的展开状态，直到加载完成
            current_server,
            loading_key -- 传递正在搜索的 key
        )

        local menu_props = {
            type = "menu_danmaku_source",
            title = "选择弹幕源",
            search_style = "disabled",
            items = loading_items,
            item_actions_place = "outside",
            callback = { mp.get_script_name(), 'handle-danmaku-source-action' },
        }
        local json_props = utils.format_json(menu_props)
        mp.commandv("script-message-to", "uosc", "update-menu", json_props)
    end

    call_cmd_async(args, function(error, json)
        local function show_error_in_menu(msg_txt)
            if not (current_menu_state.all_results and current_menu_state.servers) then
                show_message(msg_txt, 3)
                return
            end

            local current_server = get_current_server_from_cache()
            -- 传递 loading_key 作为 error_key，在 build_menu_items_with_expanded 中处理
            local items = build_menu_items_with_expanded(
                current_menu_state.all_results,
                current_menu_state.servers,
                true,
                current_menu_state.expanded_key,
                current_server,
                nil,  -- loading_key 清空
                loading_key,  -- error_key 参数
                msg_txt  -- error_message 参数
            )
            local menu_props = {
                type = "menu_danmaku_source",
                title = "选择弹幕源",
                search_style = "disabled",
                items = items,
                item_actions_place = "outside",
                callback = { mp.get_script_name(), 'handle-danmaku-source-action' },
            }
            local json_props = utils.format_json(menu_props)
            mp.commandv("script-message-to", "uosc", "update-menu", json_props)
        end
        if error or not json then
            show_error_in_menu("获取剧集列表失败: " .. (error or "未知错误"))
            return
        end

        local _, _, current_episode_num = parse_title()
        local episodes, err = parse_and_sort_episodes(json, current_episode_num)
        if not episodes then
            show_error_in_menu("解析剧集列表失败: " .. (err or "未知错误"))
            return
        end

        -- 保存展开状态
        current_menu_state.episodes = episodes
        current_menu_state.expanded_key = loading_key

        -- 更新菜单
        if current_menu_state.all_results and current_menu_state.servers then
            local current_server = get_current_server_from_cache()
            local items = build_menu_items_with_expanded(
                current_menu_state.all_results,
                current_menu_state.servers,
                true,
                current_menu_state.expanded_key,
                current_server,
                nil -- 加载完成，清除 loading_key
            )

            local menu_props = {
                type = "menu_danmaku_source",
                title = "选择弹幕源",
                search_style = "disabled",
                items = items,
                item_actions_place = "outside",
                callback = { mp.get_script_name(), 'handle-danmaku-source-action' },
            }
            local json_props = utils.format_json(menu_props)
            mp.commandv("script-message-to", "uosc", "update-menu", json_props)
        end
    end)
end

-- 切换弹幕源
mp.register_script_message("switch-danmaku-source", function(server, match_type, match_json)
    local match = utils.parse_json(match_json)
    if not match then
        show_message("解析匹配结果失败", 2)
        return
    end
    ENABLED = true

    local current_title, current_season, current_episode = parse_title()
    current_episode = tonumber(current_episode) or 1

    if match_type == "anime" then
        -- 需要先获取剧集列表
        if match.bangumiId then
            DANMAKU.anime = match.animeTitle

            -- 获取剧集信息
            local endpoint = "/api/v2/bangumi/" .. match.bangumiId
            local url = server .. endpoint
            local args = make_danmaku_request_args("GET", url, nil, nil)

            if args then
                call_cmd_async(args, function(error, json)
                    if not error and json then
                        local success, parsed = pcall(utils.parse_json, json)
                        if success and parsed and parsed.bangumi and parsed.bangumi.episodes then
                            local episodes = parsed.bangumi.episodes
                            -- 根据当前播放文件的集数匹配，而不是列表索引
                            local target_episode = nil
                            for _, episode in ipairs(episodes) do
                                local ep_num = tonumber(episode.episodeNumber)
                                if ep_num and ep_num == current_episode then
                                    target_episode = episode
                                    break
                                end
                            end

                            if target_episode then
                                DANMAKU.episode = target_episode.episodeTitle or "未知标题"
                                set_episode_id(target_episode.episodeId, server, true)
                                msg.verbose("✅ 匹配成功: " .. DANMAKU.anime .. " 第" .. current_episode .. "集")

                                -- 更新缓存和菜单状态
                                if server then
                                    local cache_match = {
                                        animeTitle = DANMAKU.anime,
                                        episodeTitle = DANMAKU.episode,
                                        episodeId = target_episode.episodeId,
                                        bangumiId = match.bangumiId,
                                        match_type = "episode",
                                        similarity = 1.0
                                    }
                                    save_match_to_cache(server, {cache_match}, "episode", {}, true)

                                    if current_menu_state.all_results then
                                        if not current_menu_state.all_results[server] then
                                            current_menu_state.all_results[server] = {}
                                        end
                                        current_menu_state.all_results[server].matches = {cache_match}
                                        current_menu_state.all_results[server].match_type = "episode"
                                    end
                                end
                            else
                                msg.warn("未找到对应集数: 第" .. current_episode .. "集 (总共" .. #episodes .. "集)")
                                show_message("未找到对应集数: 第" .. current_episode .. "集", 3)
                                -- 提示用户手动选择
                                expand_episodes_in_menu(server, match.bangumiId, match.animeTitle, match_json)
                                return
                            end
                        else
                            msg.error("获取剧集列表失败: 数据格式错误")
                            show_message("获取剧集列表失败", 3)
                        end
                    else
                        msg.error("获取剧集列表失败: " .. (error or "未知错误"))
                        show_message("获取剧集列表失败", 3)
                    end
                end)
            else
                msg.error("无法生成请求参数")
                show_message("无法生成请求参数", 3)
            end
        end
    else
        -- 直接使用episodeId
        DANMAKU.anime = match.animeTitle
        DANMAKU.episode = match.episodeTitle
        if match.episodeId then
            set_episode_id(match.episodeId, server, true)

            -- 更新缓存和菜单状态
            if server then
                save_match_to_cache(server, {match}, "episode", {}, true)

                if current_menu_state.all_results then
                    if not current_menu_state.all_results[server] then
                        current_menu_state.all_results[server] = {}
                    end
                    current_menu_state.all_results[server].matches = {match}
                    current_menu_state.all_results[server].match_type = "episode"
                end
            end
        end
    end
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "close-menu", "menu_danmaku_source")
    end
end)

-- 初始化时加载缓存
load_match_cache()

-- 注册脚本消息
mp.register_script_message("open_danmaku_source_menu", function()
    open_danmaku_source_menu(false)
end)

-- 刷新匹配结果
mp.register_script_message("refresh-danmaku-matches", function()
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "close-menu", "menu_danmaku_source")
    end
    -- 延迟一下再打开，确保菜单已关闭
    mp.add_timeout(0.1, function()
        open_danmaku_source_menu(true)
    end)
end)

-- 自动加载匹配结果
mp.register_script_message("auto_load_danmaku_matches", function()
    if not uosc_available then
        return
    end

    local path = mp.get_property("path")
    local file_name = mp.get_property("filename/no-ext")

    -- 在后台静默加载匹配结果到缓存，并更新菜单状态
    get_all_servers_matches(path, file_name, function(all_results)
        -- 更新菜单状态，这样打开菜单时就能显示最新的结果
        current_menu_state.all_results = all_results
        current_menu_state.servers = get_api_servers()
        current_menu_state.expanded_key = nil
        current_menu_state.episodes = nil
        -- 匹配结果已自动保存到缓存
        msg.verbose("自动加载匹配结果完成，共 " .. #get_api_servers() .. " 个服务器")
    end)
end)

-- 搜索并展开剧集列表（针对非dandanplay API）
mp.register_script_message("search-and-expand-episodes", function(server, animeTitle, match_json)
    if not uosc_available then
        show_message("无uosc UI框架，不支持使用该功能", 2)
        return
    end

    local match = utils.parse_json(match_json)
    if not match then
        show_message("解析匹配结果失败", 2)
        return
    end

    -- 先搜索获取bangumiId
    local encoded_query = url_encode(animeTitle)
    local endpoint = "/api/v2/search/anime?keyword=" .. encoded_query
    local url = server .. endpoint
    local args = make_danmaku_request_args("GET", url, nil, nil)
    if not args then
        show_message("无法生成请求参数", 3)
        return
    end

    local loading_key = server .. "|" .. animeTitle

    -- 显示加载提示
    if current_menu_state.all_results and current_menu_state.servers then
        local current_server = get_current_server_from_cache()
        local loading_items = build_menu_items_with_expanded(
            current_menu_state.all_results,
            current_menu_state.servers,
            true,
            current_menu_state.expanded_key,
            current_server,
            loading_key
        )

        local menu_props = {
            type = "menu_danmaku_source",
            title = "选择弹幕源",
            search_style = "disabled",
            items = loading_items,
            item_actions_place = "outside",
            callback = { mp.get_script_name(), 'handle-danmaku-source-action' },
        }
        local json_props = utils.format_json(menu_props)
        mp.commandv("script-message-to", "uosc", "update-menu", json_props)
    end

    call_cmd_async(args, function(error, json)
        if error or not json then
            show_message("搜索番剧失败: " .. (error or "未知错误"), 3)
            return
        end

        local success, parsed = pcall(utils.parse_json, json)
        if not success or not parsed or not parsed.animes or #parsed.animes == 0 then
            show_message("未找到匹配的番剧", 3)
            return
        end

        -- 使用第一个搜索结果
        local first_result = parsed.animes[1]
        local bangumiId = first_result.bangumiId or first_result.animeId
        if not bangumiId then
            show_message("未找到番剧ID", 3)
            return
        end

        -- 展开剧集列表
        expand_episodes_in_menu(server, tostring(bangumiId), animeTitle, match_json)
    end)
end)

-- 直接展开剧集列表
mp.register_script_message("expand-episodes-menu", function(server, bangumiId, animeTitle, match_json)
    if not uosc_available then
        show_message("无uosc UI框架，不支持使用该功能", 2)
        return
    end
    expand_episodes_in_menu(server, bangumiId, animeTitle, match_json)
end)

-- 收起剧集列表
mp.register_script_message("collapse-episodes-menu", function()
    if not uosc_available then
        return
    end

    -- 清除展开状态
    current_menu_state.expanded_key = nil
    current_menu_state.episodes = nil

    -- 更新菜单
    if current_menu_state.all_results and current_menu_state.servers then
        local current_server = get_current_server_from_cache()
        local items = build_menu_items_with_expanded(
            current_menu_state.all_results,
            current_menu_state.servers,
            true,
            nil,
            current_server,
            nil
        )
        local menu_props = {
            type = "menu_danmaku_source",
            title = "选择弹幕源",
            search_style = "disabled",
            items = items,
            item_actions_place = "outside",
            callback = { mp.get_script_name(), 'handle-danmaku-source-action' },
        }
        local json_props = utils.format_json(menu_props)
        mp.commandv("script-message-to", "uosc", "update-menu", json_props)
    end
end)

-- 打开特定服务器的搜索输入框
mp.register_script_message("open-server-search-input", function(server)
    if uosc_available then
        -- 使用 uosc 的 input 菜单，但回调指向特定服务器搜索
        open_input_menu_uosc(
            { "script-message-to", mp.get_script_name(), "search-server-event", server },
            "menu_single_server_search"
        )
    else
        -- Fallback for non-uosc
        mp.commandv('script-message-to', 'console', 'disable')
        input.get({
            prompt = '搜索 (' .. extract_server_identifier(server) .. '):',
            submit = function(text)
                input.terminate()
                search_single_server(server, text)
            end
        })
    end
end)

-- 处理特定服务器的搜索事件
mp.register_script_message("search-server-event", function(server, query)
    if uosc_available then
        -- 关闭输入框菜单
        mp.commandv("script-message-to", "uosc", "close-menu", "menu_single_server_search")
    end
    search_single_server(server, query)
end)

-- 处理弹幕源菜单的点击事件
mp.register_script_message('handle-danmaku-content-action', function(json)
    local event = utils.parse_json(json)
    if not event or event.type ~= 'activate' then return end

    if event.action then
        local real_idx = menu_index_map[event.index]
        if not real_idx or not COMMENTS then return end

        local d = COMMENTS[real_idx]
        if not d or not d.source then return end

        if event.action == "block_source" then
            mp.commandv("script-message", "block-danmaku-source", d.source)
        elseif event.action == "adjust_delay" then
            mp.commandv("script-message", "open_source_delay_menu", d.source)
        end
    else
        if event.value then
            if type(event.value) == "table" then
                mp.commandv(unpack(event.value))
            else
                mp.command(event.value)
            end
            mp.commandv("script-message-to", "uosc", "close-menu", "menu_content")
        end
    end
end)

-- 屏蔽弹幕源
mp.register_script_message("block-danmaku-source", function(url)
    msg.info("屏蔽弹幕源: " .. tostring(url))
    if not url then return end
    local source = DANMAKU.sources[url]
    -- 归一化查找...
    if not source then
        local norm_url = url:gsub("\\", "/"):lower()
        for k, v in pairs(DANMAKU.sources) do
            if k:gsub("\\", "/"):lower() == norm_url then
                source = v
                url = k
                break
            end
        end
    end
    if not source then
        show_message("未找到该弹幕源", 2)
        return
    end
    local active_count = 0
    for _, s in pairs(DANMAKU.sources) do
        if not s.blocked then
            active_count = active_count + 1
        end
    end
    if active_count <= 1 and not source.blocked then
        show_message("无法屏蔽：至少保留一个弹幕源", 2)
        msg.warn("阻止屏蔽最后一个弹幕源: " .. url)
        return
    end
    source.blocked = true
    add_source_to_history(url, source)
    load_danmaku(true)
    if uosc_available then
        mp.add_timeout(0.5, function()
             open_content_menu()
        end)
    end
end)
-- 处理弹幕源菜单的action/点击事件
mp.register_script_message('handle-danmaku-source-action', function(json)
    local event = utils.parse_json(json)
    if not event or event.type ~= 'activate' then return end
    if event.menu_type and event.menu_type ~= "menu_danmaku_source" then
        return
    end
    local action = event.action
    local value  = event.value
    if not action then
        if value then
            if type(value) == "table" then
                mp.commandv(unpack(value))
                if value[1] == "script-message-to"
                   and value[2] == mp.get_script_name()
                   and value[3] == "load-danmaku" then
                    current_menu_state.expanded_key = nil
                    current_menu_state.episodes = nil
                    if uosc_available then
                        mp.commandv("script-message-to", "uosc", "close-menu", "menu_danmaku_source")
                    end
                end
            elseif type(value) == "string" then
                mp.command(value)
            end
        end
        return
    end
    local function build_comment_url_from_value(v)
        if type(v) ~= "table" then return nil, nil, nil end
        if v[3] ~= "load-danmaku" then return nil, nil, nil end
        local episodeId = v[6]
        local server    = v[7]
        if not episodeId or not server then return nil, nil, nil end
        episodeId = tostring(episodeId)
        local comment_url = server .. "/api/v2/comment/" .. episodeId .. "?withRelated=true&chConvert=0"
        return comment_url, server, episodeId
    end

    local comment_url, api_server, episodeId = build_comment_url_from_value(value)
    if not comment_url then
        show_message("无法从菜单项解析弹幕URL", 2)
        return
    end

    local server_url = comment_url
    local source = DANMAKU.sources[server_url]
    if not source then
        local norm_url = server_url:gsub("^https?://", ""):gsub("\\", "/")
        for k, v in pairs(DANMAKU.sources) do
            if k:gsub("^https?://", ""):gsub("\\", "/") == norm_url then
                source = v
                server_url = k
                break
            end
        end
    end
    local function refresh_menu_delayed()
        mp.add_timeout(0.2, function()
            open_danmaku_source_menu(false)
        end)
    end

    if action == "add" then
        if not source then
            show_message("正在添加并加载弹幕源...", 2)
            msg.info("添加弹幕源: " .. server_url)

            add_danmaku_source(server_url, false)
            if DANMAKU.sources[server_url] then
                add_source_to_history(server_url, DANMAKU.sources[server_url])
            end
            if api_server and options.load_more_danmaku and api_server:find("api%.dandanplay%.") and episodeId then
                local eid_num = tonumber(episodeId)
                if eid_num and fetch_danmaku_all then
                    fetch_danmaku_all(eid_num, false, api_server)
                end
            end

            -- 添加数据需要时间，稍微延时一点刷新
            mp.add_timeout(0.6, function()
                load_danmaku(true, true)
                open_danmaku_source_menu(false)
            end)
        else
            add_source_to_history(server_url, source)
            show_message("该弹幕源已存在", 1)
            refresh_menu_delayed()
        end

    elseif action == "delete" then
        if source and source.from ~= "api_server" then
            DANMAKU.sources[server_url] = nil
            remove_source_from_history(server_url)
            show_message("已删除弹幕源", 2)
            load_danmaku(true)
            refresh_menu_delayed()
        else
            if source then
                DANMAKU.sources[server_url] = nil
                show_message("已移除此源", 2)
                load_danmaku(true)
                refresh_menu_delayed()
            end
        end

    elseif action == "block" then
        if not source then return end
        local active_count = 0
        for _, s in pairs(DANMAKU.sources) do
            if not s.blocked and s.data then active_count = active_count + 1 end
        end
        if active_count <= 1 and not source.blocked then
            show_message("无法屏蔽：至少保留一个弹幕源", 2)
            return
        end
        source.blocked = true
        add_source_to_history(server_url, source)
        show_message("已屏蔽该源", 2)
        load_danmaku(true)
        refresh_menu_delayed()

    elseif action == "unblock" then
        if not source then return end
        source.blocked = false
        add_source_to_history(server_url, source)
        show_message("已解除屏蔽", 2)
        load_danmaku(true)
        refresh_menu_delayed()
    end
end)
