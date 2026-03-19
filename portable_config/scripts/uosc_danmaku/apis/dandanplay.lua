local msg = require('mp.msg')
local utils = require("mp.utils")

local function extract_url(url)
    local path = url:match("^https?://[^/]+(/[^%?]*)")
    return path
end

local DANDAN_APPID_ENC = "UgjRIH45lE1BBLNmir1WKw=="
local DANDAN_ACCEPT_ENC = "SzuWlFZAPRMqeWf9qmfp8dcvYr3hvxuSrIRZuAeEfko="
local DANDAN_APPID_DEC = nil
local DANDAN_ACCEPT_DEC = nil

local function init_credentials()
    if not DANDAN_APPID_DEC then
        DANDAN_APPID_DEC = AES.ECB.decrypt(KEY, Base64.decode(DANDAN_APPID_ENC))
        DANDAN_ACCEPT_DEC = AES.ECB.decrypt(KEY, Base64.decode(DANDAN_ACCEPT_ENC))
    end
end

local function generateXSignature(url, time)
    init_credentials()
    local url_path = extract_url(url)
    if not url_path then return nil end

    local dataToHash = string.format("%s%d%s%s", DANDAN_APPID_DEC, time, url_path, DANDAN_ACCEPT_DEC)
    local hash = Sha256(dataToHash)
    return Base64.encode(hex_to_bin(hash))
end

function get_base_curl_args()
    local args = {
        "curl",
        "-L",
        "-s",
        "--compressed",
        "--user-agent", options.user_agent,
        "--max-time", "20",
        "-H", "accept: application/json",
    }

    if options.proxy ~= "" then
        table.insert(args, '-x')
        table.insert(args, options.proxy)
    end

    return args
end

-- 并发请求多个API服务器
local function make_concurrent_danmaku_request(servers, request_config, response_handler, custom_validator)
    local concurrent_manager = ConcurrentManager:new()
    local total_servers = #servers

    for i, server in ipairs(servers) do
        local args = request_config.make_args(server, i)

        if args then
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
            concurrent_manager:start_request(server, i, function(cb)
                cb({
                    server = server,
                    error = "无法生成请求参数",
                    data = nil,
                    index = i
                })
            end)
        end
    end

    local validator = custom_validator or function(res)
        return res and not res.error and res.data
    end

    concurrent_manager:wait_priority(total_servers, validator, function(results)
        table.sort(results, function(a, b)
            return a.index < b.index
        end)

        response_handler(results)
    end)
end

-- 解析服务器字符串
local function parse_servers(servers_str)
    local servers = {}
    for server in servers_str:gmatch("([^,]+)") do
        server = server:gsub("^%s*(.-)%s*$", "%1")
        if server ~= "" then
            table.insert(servers, server)
        end
    end
    return servers
end

-- 获取API服务器列表
function get_api_servers()
    if options.api_servers and options.api_servers ~= "" then
        return parse_servers(options.api_servers)
    else
        return {options.api_server}
    end
end

-- 读取episodeId获取danmaku
function set_episode_id(input, target_server, from_menu)
    from_menu = from_menu or false
    DANMAKU.source = "dandanplay"
    for url, source in pairs(DANMAKU.sources) do
        if source.from == "api_server" then
            if not source.from_history then
                DANMAKU.sources[url] = nil
            else
                DANMAKU.sources[url]["data"] = nil
            end
        end
    end
    -- 清理历史记录中的 api_server 源
    local key = get_cache_key()
    if key then
        local history_json = read_file(HISTORY_PATH)
        if history_json then
            local history = utils.parse_json(history_json) or {}
            if history[key] and history[key].sources then
                local cleaned_count = 0
                local new_sources = {}
                for url, source_data in pairs(history[key].sources) do
                    if source_data.from ~= "api_server" then
                        new_sources[url] = source_data
                    end
                end
                history[key].sources = new_sources
            end
            write_json_file(HISTORY_PATH, history)
        end
    end
    local episodeId = tonumber(input)
    write_history(episodeId, target_server)
    set_danmaku_button()
    local server = target_server
    if not server then
        for _, s in pairs(get_api_servers()) do
            fetch_danmaku(episodeId, from_menu, s)
        end
    else
        if options.load_more_danmaku and server:find("api%.dandanplay%.") then
            fetch_danmaku_all(episodeId, from_menu, server)
        else
            fetch_danmaku(episodeId, from_menu, server)
        end
    end
end

-- 回退使用额外的弹幕获取方式
function get_danmaku_fallback(query)
    local url = options.fallback_server .. "/?url=" .. query
    msg.verbose("尝试获取弹幕(fallback)：" .. url)
    local args = get_base_curl_args()
    table.insert(args, url)
    call_cmd_async(args, function(err, content)
        async_running = false
        if err then
            show_message("HTTP 请求失败，打开控制台查看详情", 5)
            msg.error("Fallback curl error: " .. err)
            return
        end
        if not content or content == "" then
            msg.warn("Fallback server returned empty response")
            return
        end
        save_danmaku_memory(query, content, "user_custom", "xml")
        load_danmaku(true)
    end)
end

function save_danmaku_memory(url, raw_data, source_type, format)
    if DANMAKU.sources[url] == nil then
        DANMAKU.sources[url] = {from = source_type}
    end
    if type(raw_data) == "table" and format == "api_json" then
        DANMAKU.sources[url]["data"] = save_danmaku_json(raw_data)
    else
        DANMAKU.sources[url]["data"] = raw_data
        DANMAKU.sources[url]["format"] = format
    end
end

-- 返回弹幕请求参数
function make_danmaku_request_args(method, url, headers, body)
    local args = get_base_curl_args()
    table.insert(args, "-X")
    table.insert(args, method)

    if headers then
        for k, v in pairs(headers) do
            table.insert(args, '-H')
            table.insert(args, string.format('%s: %s', k, v))
        end
    end

    if body then
        table.insert(args, '-d')
        table.insert(args, utils.format_json(body))
        table.insert(args, '-H')
        table.insert(args, 'Content-Type: application/json')
    end

    if url:find("api%.dandanplay%.") then
        local time = os.time()
        init_credentials()
        table.insert(args, '-H'); table.insert(args, string.format('X-AppId: %s', DANDAN_APPID_DEC))
        table.insert(args, '-H'); table.insert(args, string.format('X-Signature: %s', generateXSignature(url, time)))
        table.insert(args, '-H'); table.insert(args, string.format('X-Timestamp: %s', time))
    end

    table.insert(args, url)

    return args
end

-- 尝试通过解析文件名匹配剧集
function match_episode(animeTitle, bangumiId, episode_num, target_server, callback)
    callback = callback or function(error)
        if error then msg.verbose(error) end
    end
    local servers = target_server and {target_server} or get_api_servers()
    local request_config = {
        make_args = function(server, index)
            local endpoint = "/api/v2/bangumi/" .. bangumiId
            local url = server .. endpoint
            msg.verbose("尝试获取番剧信息: " .. url)
            return make_danmaku_request_args("GET", url)
        end
    }

    -- 集数存在性校验器
    local episode_validator = function(result)
        if not result or result.error or not result.data then return false end
        if not result.data.bangumi or not result.data.bangumi.episodes then return false end

        local episodes = result.data.bangumi.episodes
        local target_ep = tonumber(episode_num)

        -- 遍历检查目标集数是否存在
        for _, episode in ipairs(episodes) do
            local ep_num = tonumber(episode.episodeNumber)
            if ep_num and ep_num == target_ep then
                return true -- 找到了这一集，数据有效
            end
        end

        return false
    end

    local response_handler = function(results)
        for _, result in ipairs(results) do
            if episode_validator(result) then
                local episodes = result.data.bangumi.episodes
                for _, episode in ipairs(episodes) do
                    local ep_num = tonumber(episode.episodeNumber)
                    if ep_num and ep_num == tonumber(episode_num) then
                        DANMAKU.anime = animeTitle
                        DANMAKU.episode = episode.episodeTitle
                        set_episode_id(episode.episodeId, result.server)
                        local match = {
                            animeTitle = animeTitle,
                            episodeTitle = episode.episodeTitle,
                            episodeId = episode.episodeId,
                            bangumiId = bangumiId,
                            match_type = "episode",
                            similarity = 1.0
                        }
                        save_selected_episode_with_offset(
                            result.server,
                            animeTitle,
                            episode.episodeTitle,
                            episode.episodeId,
                            bangumiId
                        )
                        save_match_to_cache(result.server, {match}, "episode", {}, true)
                        callback(nil)
                        return
                    end
                end
            end
        end

        local error_msg = string.format("所有服务器均未找到第 %s 集", tostring(episode_num))
        if results[1] and results[1].error then error_msg = results[1].error end
        callback(error_msg)
    end

    make_concurrent_danmaku_request(servers, request_config, response_handler, episode_validator)
end

function clean_anime_title(title)
    local patterns = {
        "%[OVA%]", "%[OAD%]", "%[剧场版%]", "%[Movie%]", "%[電影%]",
        "%[特別篇%]", "%[Special%]", "%[SP%]",
        "OVA", "OAD", "剧场版", "Movie", "特別篇", "Special"
    }

    local cleaned = title
    for _, pattern in ipairs(patterns) do
        cleaned = cleaned:gsub(pattern, "")
    end

    cleaned = cleaned:gsub("%[.-%]", "")

    cleaned = cleaned:gsub("%s+", " ")
    cleaned = cleaned:gsub("^%s+", ""):gsub("%s+$", "")
    return url_encode(cleaned)
end

function match_anime_concurrent(callback, specific_servers)
    local servers = specific_servers or get_api_servers()
    local title, season_num, episode_num = parse_title()
    episode_num = episode_num or 1
    local encoded_query = clean_anime_title(title)

    local request_config = {
        make_args = function(server, index)
            local endpoint = "/api/v2/search/anime?keyword=" .. encoded_query
            local url = server .. endpoint
            return make_danmaku_request_args("GET", url)
        end
    }
    local similarity_validator = function(result)
        if not result or result.error or not result.data then return false end
        if not result.data.animes or #result.data.animes == 0 then return false end
        return true
    end

    local response_handler = function(results)
        local function try_next_result(index)
            if index > #results then
                if callback then callback("所有服务器均未找到匹配番剧 (threshold >= 0.75)") end
                return
            end

            local result = results[index]

            if similarity_validator(result) then
                process_anime_matches(result.data.animes, title, season_num, result.server, function(matches)
                    if matches and #matches > 0 then
                        local best_match = matches[1]
                        msg.verbose("✅ 模糊匹配选中: " .. best_match.animeTitle .. " (server: " .. result.server .. ")")

                        match_episode(best_match.animeTitle, best_match.bangumiId, episode_num, result.server, function(error)
                            if error then
                                msg.verbose("剧集匹配失败，尝试下一个服务器: " .. error)
                                try_next_result(index + 1)
                            else
                                if callback then callback(nil) end
                            end
                        end)
                    else
                        try_next_result(index + 1)
                    end
                end)
            else
                try_next_result(index + 1)
            end
        end
        try_next_result(1)
    end

    make_concurrent_danmaku_request(servers, request_config, response_handler, similarity_validator)
end

-- 针对御坂服务器的特殊处理
function inferBangumiId(match, server)
    if not (match and match.animeId and match.episodeId) then
        return nil
    end

    local animeId_str = tostring(match.animeId)
    local episodeId_str = tostring(match.episodeId)

    if episodeId_str:find(animeId_str, 1, true)
        and not episodeId_str:startswith(animeId_str)
    then
        return "A" .. animeId_str
    end

    if animeId_str:startswith("9")
        and #animeId_str == 6
        and #episodeId_str == 14
        and server:find("/api/v1/")
    then
        local extracted = tonumber(episodeId_str:sub(3, 8))
        if extracted then
            return "A" .. tostring(extracted)
        end
    end

    return nil
end

function process_match_result(selected_result, title, callback, forced_match)
    if not selected_result then
        msg.info("❌ 缺少服务器结果")
        callback("没有匹配的剧集")
        return
    end

    local server = selected_result.server or "未知服务器"
    local match = forced_match

    if not match then
        msg.info("❌ 服务器 " .. server .. " 没有有效的匹配数据（未传入 match）")
        callback("没有匹配的剧集")
        return
    end

    local id = inferBangumiId(match, server)
    if id then
        match.bangumiId = id
    end
    DANMAKU.anime   = match.animeTitle
    DANMAKU.episode = match.episodeTitle

    msg.verbose("   最终使用服务器: " .. server)

    set_episode_id(match.episodeId, server)
    save_selected_episode_with_offset(
        server,
        match.animeTitle,
        match.episodeTitle,
        tostring(match.episodeId),
        match.bangumiId
    )
    save_match_to_cache(server, {match}, "episode", {}, true)

    callback(nil)
end

-- 异步处理番剧匹配（支持 TMDB）
function process_anime_matches(animes, title, season_num, result_server, callback)
    local filtered_animes = {}
    local anime_type = "tvseries"
    local lower_title = title:lower()
    if lower_title:match("ova") or lower_title:match("oad") then
        anime_type = "ova"
    elseif lower_title:match("剧场版") or lower_title:match("movie") or lower_title:match("劇場版") then
        anime_type = "movie"
    end

    local function filter_by_type(animes_list, t)
        local result = {}
        for _, a in ipairs(animes_list) do
            if a and (a.type == t or (t == "tvseries" and (a.type == "jpdrama"))) then
                table.insert(result, a)
            end
        end
        return result
    end
    filtered_animes = filter_by_type(animes, anime_type)
    if #filtered_animes == 0 and anime_type == "tvseries" and not season_num then
        filtered_animes = filter_by_type(animes, "movie")
    end

    local function calculate_best_match(target_title)
        local best_match, best_score = nil, -1

        if #filtered_animes == 1 then
            best_match = filtered_animes[1]
            best_score = 1
        elseif #filtered_animes > 1 then
            if tonumber(season_num) and tonumber(season_num) > 1 then
                target_title = target_title .. " 第" .. number_to_chinese(season_num) .. "季"
            else
                target_title = target_title .. " 第一季"
            end

            for _, anime in ipairs(filtered_animes) do
                local anime_title = anime.animeTitle or ""
                local score = jaro_winkler(target_title, anime_title)
                local anime_season = extract_season(anime_title)
                if tonumber(anime_season) and anime_season ~= tonumber(season_num) then
                    score = score - 0.2
                end
                if score > best_score then
                    best_score = score
                    best_match = anime
                end
            end
        end

        local threshold = 0.75
        local result_list = {}
        if best_match and best_score >= threshold and not best_match.animeTitle:find("搜索正在") then
            best_match.similarity = best_score
            table.insert(result_list, best_match)
        end

        -- 执行回调返回结果
        if callback then callback(result_list) end
    end

    -- 开始处理逻辑
    if #filtered_animes > 1 then
        local base_title = title:gsub("%s*%(%d+%)", ""):gsub("^%s*(.-)%s*$", "%1")

        if is_english(base_title) then
            query_tmdb(base_title, anime_type, nil, function(chinese_title)
                if chinese_title then
                    calculate_best_match(chinese_title)
                else
                    calculate_best_match(base_title) -- 查询失败，用原名
                end
            end)
            return -- 等待回调，不再往下执行
        else
            calculate_best_match(base_title)
        end
    else
        calculate_best_match(title)
    end
end

-- 执行哈希匹配获取弹幕
function match_file_concurrent(file_path, file_name, callback, specific_servers)
    local servers = specific_servers or get_api_servers()
    local hash = nil
    local file_info = utils.file_info(file_path)
    local excluded_path = utils.parse_json(options.excluded_path)
    if PLATFORM == "windows" then
        for i, path in pairs(excluded_path) do excluded_path[i] = path:gsub("/", "\\") end
    end
    local dir = get_parent_directory(file_path)
    if not is_protocol(file_path) and not contains_any(excluded_path, dir) and file_info and file_info.size >= 16 * 1024 * 1024 then
        local file, error = io.open(normalize(file_path), 'rb')
        if file and not error then
            local m = MD5.new()
            for _ = 1, 16 * 1024 do
                local content = file:read(1024)
                if not content then break end
                m:update(content)
            end
            file:close()
            hash = m:finish()
        end
    end

    if hash then
        msg.info("hash:", hash)
    else
        msg.info("未生成hash，将使用文件名匹配模式")
    end

    local title, season_num, episode_num = parse_title()
    if title and episode_num then
        if season_num then
            file_name = title .. " S" .. season_num .. "E" .. episode_num
        else
            file_name = title .. " E" .. episode_num
        end
    else
        file_name = title or file_name
    end
    local endpoint = "/api/v2/match"
    local body = {
        fileName   = file_name,
        fileHash   = hash or "a1b2c3d4e5f67890abcd1234ef567890",
        matchMode  = hash and "hashAndFileName" or "fileNameOnly"
    }

    local request_config = {
        make_args = function(server, index)
            local url = server .. endpoint
            return make_danmaku_request_args("POST", url, {
                ["Content-Type"] = "application/json"
            }, body)
        end
    }
    local strict_validator = function(result)
        if not result or result.error or not result.data then return false end
        local data = result.data
        if data.isMatched and data.matches and #data.matches == 1 then return true end
        if data.matches and #data.matches > 1 then
            -- 如果 title 解析失败了，只要有返回结果就算对
            if not title then return true end
            for _, match in ipairs(data.matches) do
                if match.animeTitle == title then
                    return true
                end
            end
        end
        return false
    end
    local response_handler = function(results)
        for _, r in ipairs(results) do
            if strict_validator(r) then
                local data = r.data
                if data.isMatched and data.matches and #data.matches == 1 then
                    msg.verbose("✅ 精确匹配成功: " .. data.matches[1].animeTitle)
                    process_match_result(r, title, callback, data.matches[1])
                    return
                end
                if data.matches then
                    for _, match in ipairs(data.matches) do
                        if not title or match.animeTitle == title then
                            msg.verbose("✅ 文件名匹配选中: " .. match.animeTitle)
                            process_match_result(r, title, callback, match)
                            return
                        end
                    end
                end
            end
        end
        if callback then callback("没有匹配的剧集 (所有服务器尝试完毕)") end
    end
    make_concurrent_danmaku_request(servers, request_config, response_handler, strict_validator)
end

-- 异步获取弹幕数据
function fetch_danmaku_data(args, callback)
    call_cmd_async(args, function(error, json)
        async_running = false
        if error then
            msg.info("获取弹幕数据出错，请稍后在选择弹幕源里重试。错误信息: " .. error)
            show_message("弹幕请求失败，打开控制台查看详情", 5)
            return
        end

        if not json or json == "" then
             msg.warn("弹幕 HTTP 请求成功返回，但数据内容为空。")
             show_message("弹幕数据返回为空", 3)
             return
        end

        local success, data = pcall(utils.parse_json, json)
        if not success then
            msg.warn("弹幕 JSON 解析失败" )
            show_message("弹幕数据解析失败", 3)
            return
        end

        callback(data)
    end)
end

-- 保存弹幕数据
function save_danmaku_data(comments, query, danmaku_source)
    -- 转换为 Lua Table
    local danmaku_list = save_danmaku_json(comments)

    if danmaku_list and #danmaku_list > 0 then
        if DANMAKU.sources[query] == nil then
            DANMAKU.sources[query] = {from = danmaku_source}
        end

        DANMAKU.sources[query]["data"] = danmaku_list
    end
end

-- 处理弹幕数据
function handle_danmaku_data(query, data, from_menu)
    local comments = data["comments"]
    local count = data["count"]

    if count == 0 then
        show_message("服务器无缓存数据，再次尝试请求", 30)
        msg.verbose("服务器无缓存数据，再次尝试请求")
        local start = os.time()
        while os.time() - start < 2 do
            -- 空循环，等待 2 秒
        end
        local servers = get_api_servers()
        local base = servers[1]

        for _, s in ipairs(servers) do
            if s:find("api%.dandanplay%.") or s:find("/api/v1/") then
                base = s
                break
            end
        end

        local url = base .. "/api/v2/extcomment?url=" .. url_encode(query)
        local args = make_danmaku_request_args("GET", url)

        if args == nil then
            return
        end

        fetch_danmaku_data(args, function(retry_data)
            if not retry_data or not retry_data["comments"] or retry_data["count"] == 0 then
                get_danmaku_fallback(query)
                return
            end
            save_danmaku_data(retry_data["comments"], query, "user_custom")
            load_danmaku(from_menu)
        end)
    else
        save_danmaku_data(comments, query, "user_custom")
        load_danmaku(from_menu)
    end
end

-- 处理第三方弹幕数据
function handle_related_danmaku(index, relateds, related, shift, callback)
    local servers = get_api_servers()
    local base = servers[1]

    for _, s in ipairs(servers) do
        if s:find("api%.dandanplay%.") or s:find("/api/v1/") then
            base = s
            break
        end
    end

    local url = base .. "/api/v2/extcomment?url=" .. url_encode(related["url"])
    show_message(string.format("正在从第三方库装填弹幕 [%d/%d]", index, #relateds), 30)
    msg.verbose("正在从第三方库装填弹幕：" .. url)

    local args = make_danmaku_request_args("GET", url)

    if args == nil then
        return
    end

    fetch_danmaku_data(args, function(data)
        local comments = {}
        if data and data["comments"] then
            if data["count"] == 0 then
                local start = os.time()
                while os.time() - start < 2 do
                    -- 空循环
                end
                fetch_danmaku_data(args, function(data)
                    for _, comment in ipairs(data["comments"]) do
                        comment["shift"] = shift
                        table.insert(comments, comment)
                    end
                    callback(comments)
                end)
            else
                for _, comment in ipairs(data["comments"]) do
                    comment["shift"] = shift
                    table.insert(comments, comment)
                end
                callback(comments)
            end
        else
            show_message("无数据", 3)
            msg.info("无数据")
            callback(comments)
        end
    end)
end

function handle_main_danmaku(url, from_menu)
    show_message("正在从弹弹Play库装填弹幕", 30)
    msg.verbose("尝试获取弹幕：" .. url)
    local args = make_danmaku_request_args("GET", url)

    if args == nil then
        return
    end

    fetch_danmaku_data(args, function(data)
        handle_fetched_danmaku(data, url, from_menu)
    end)
end

function handle_fetched_danmaku(data, url, from_menu)
    if data and data["comments"] then
        if data["count"] == 0 and DANMAKU.sources[url] == nil then
            DANMAKU.sources[url] = {from = "api_server"}
            add_source_to_history(url, DANMAKU.sources[url])
            load_danmaku(from_menu)
            return
        end
        save_danmaku_data(data["comments"], url, "api_server")
        add_source_to_history(url, DANMAKU.sources[url])
        load_danmaku(from_menu)
    else
        show_message("弹幕数据加载不成功，请稍后在选择弹幕源里重试", 3)
        msg.verbose("无数据或格式错误，结束加载url：" .. url)
    end
end

function filter_excluded_platforms(relateds)
    local excluded_list = {}
    local excluded_json = options.excluded_platforms
    if excluded_json and excluded_json ~= "" and excluded_json ~= "[]" then
        local success, parsed = pcall(utils.parse_json, excluded_json)
        if success and parsed and type(parsed) == "table" then
            excluded_list = parsed
        end
    end

    if #excluded_list == 0 then
        return relateds
    end

    local filtered = {}
    for _, related in ipairs(relateds) do
        local url = related["url"]
        local should_exclude = false

        for _, platform in ipairs(excluded_list) do
            if url:find(platform, 1, true) then
                should_exclude = true
                msg.info(string.format("已排除平台 [%s] 的弹幕源: %s", platform, url))
                break
            end
        end

        if not should_exclude then
            table.insert(filtered, related)
        end
    end

    msg.info(string.format("原始弹幕源: %d 个, 过滤后: %d 个", #relateds, #filtered))
    return filtered
end

function fetch_danmaku(episodeId, from_menu, specific_server)
    local server = specific_server or get_api_servers()[1]
    local url = server .. "/api/v2/comment/" .. episodeId .. "?withRelated=true&chConvert=0"
    show_message("弹幕加载中...", 30)
    msg.verbose("尝试获取弹幕：" .. url)
    local args = make_danmaku_request_args("GET", url)

    if args == nil then
        return
    end

    fetch_danmaku_data(args, function(data)
        handle_fetched_danmaku(data, url, from_menu)
    end)
end

function fetch_danmaku_all(episodeId, from_menu, specific_server)
    local server = specific_server or get_api_servers()[1]
    local url = server .. "/api/v2/related/" .. episodeId
    show_message("弹幕加载中...", 30)
    msg.verbose("尝试获取弹幕：" .. url)
    local args = make_danmaku_request_args("GET", url)

    if args == nil then
        return
    end

    fetch_danmaku_data(args, function(data)
        if not data or not data["relateds"] then
            show_message("无数据", 3)
            msg.info("无数据")
            return
        end

        local filtered_relateds = filter_excluded_platforms(data["relateds"])
        local function process_related(index)
            if index > #filtered_relateds then
                local main_url = server .. "/api/v2/comment/" .. episodeId .. "?withRelated=false&chConvert=0"
                handle_main_danmaku(main_url, from_menu)
                return
            end

            local related = filtered_relateds[index]

            handle_related_danmaku(index, filtered_relateds, related, related["shift"], function(comments)
                if comments and #comments > 0 then
                    save_danmaku_data(comments, related["url"], "api_server")
                elseif DANMAKU.sources[related["url"]] == nil then
                    DANMAKU.sources[related["url"]] = {from = "api_server"}
                end

                process_related(index + 1)
            end)
        end

        process_related(1)
    end)
end

function addon_danmaku(check_history, from_menu)
    if check_history then
        local key = get_cache_key()
        local history_json = read_file(HISTORY_PATH)
        local history = utils.parse_json(history_json) or {}
        if history[key] and history[key].extra ~= nil then
            return
        end
    end
    for url, source in pairs(DANMAKU.sources) do
        if source.from ~= "api_server" then
            add_danmaku_source(url, from_menu)
        end
    end
end

function add_danmaku_source(query, from_menu)
    if DANMAKU.sources[query] == nil then
        DANMAKU.sources[query] = {from = "user_custom"}
    end

    from_menu = from_menu or false
    if from_menu then
        add_source_to_history(query, DANMAKU.sources[query])
    end

    if is_protocol(query) then
        add_danmaku_source_online(query, from_menu)
    else
        add_danmaku_source_local(query, from_menu)
    end
end

function add_danmaku_source_local(query, from_menu)
    local path = normalize(query)
    if not file_exists(path) then return end
    local temp_collection = {{
        type = "file",
        path = path,
        url = query
    }}
    local danmaku_list = parse_danmaku_sources(temp_collection, {})
    if danmaku_list and #danmaku_list > 0 then
        if DANMAKU.sources[query] == nil then
            DANMAKU.sources[query] = {from = "user_local"}
        end
        DANMAKU.sources[query]["data"] = danmaku_list
        DANMAKU.sources[query]["fname"] = nil
        set_danmaku_button()
        load_danmaku(from_menu)
    else
        msg.warn("本地弹幕解析为空: " .. path)
    end
end

function add_danmaku_source_online(query, from_menu)
    set_danmaku_button()
    if query:find("/api/v2/comment/") or query:find("/api/v2/related/") then
        show_message("正在加载额外弹幕源...", 30)
        msg.verbose("添加 API 直链弹幕源：" .. query)
        
        local args = make_danmaku_request_args("GET", query)
        if args == nil then return end

        fetch_danmaku_data(args, function(data)
            if not data or not data["comments"] then
                show_message("此源数据为空或无法加载", 3)
                return
            end
            handle_fetched_danmaku(data, query, from_menu)
        end)
        return
    end
    local servers = get_api_servers()
    local base = servers[1]
    for _, s in ipairs(servers) do
        if s:find("api%.dandanplay%.") or s:find("/api/v1/") then
            base = s
            break
        end
    end
    local url = base .. "/api/v2/extcomment?url=" .. url_encode(query)
    show_message("弹幕加载中...", 30)
    msg.verbose("尝试获取弹幕：" .. url)
    local args = make_danmaku_request_args("GET", url)

    if args == nil then
        return
    end

    fetch_danmaku_data(args, function(data)
        if not data or not data["comments"] then
            show_message("此源弹幕无法加载", 3)
            msg.verbose("此源弹幕无法加载")
            return
        end
        handle_danmaku_data(query, data, from_menu)
    end)
end

-- 将弹幕转换为factory可读的json格式
function save_danmaku_json(comments)
    local danmaku_list = {}
    for _, comment in ipairs(comments) do
        local p = comment["p"]
        local shift = comment["shift"]
        if p then
            local fields = split(p, ",")
            if shift ~= nil then
                fields[1] = tonumber(fields[1]) + tonumber(shift)
            end
            local time = tonumber(fields[1])
            local type = tonumber(fields[2])
            local color = tonumber(fields[3]) or 0xFFFFFF
            local size = 25
            local m_value = comment["m"]
                            :gsub("[%z\1-\31]", "")
                            :gsub("\\", "")
                            :gsub("\"", "")

            table.insert(danmaku_list, {
                time = time,
                type = type,
                size = size,
                color = color,
                text = m_value
            })
        end
    end
    table.sort(danmaku_list, function(a, b) return a.time < b.time end)

    return danmaku_list
end

-- 执行匹配链：处理优先级和 Fallback
local function execute_match_chain(strategy, file_path, file_name, servers)
    local function fallback_to_anime(err_source)
        msg.warn(err_source .. " 失败，尝试 Fallback 到 anime_match")
        match_anime_concurrent(function(err)
            if err then msg.verbose("所有匹配策略均失败: " .. err) end
        end, servers)
    end

    local function fallback_to_file(err_source)
        msg.warn(err_source .. " 失败，尝试 Fallback 到 file_match")
        match_file_concurrent(file_path, file_name, function(err)
            if err then msg.verbose("所有匹配策略均失败: " .. err) end
        end, servers)
    end

    if strategy == "anime_first" then
        match_anime_concurrent(function(err)
            if err then fallback_to_file("anime_match") end
        end, servers)
    else
        match_file_concurrent(file_path, file_name, function(err)
            if err then fallback_to_anime("file_match") end
        end, servers)
    end
end

-- 修改 get_danmaku_with_hash 函数以使用并发版本
function get_danmaku_with_hash(file_name, file_path, specific_servers)
    local servers = specific_servers or get_api_servers()

    local strategy = "file_first"
    -- 如果首选服务器是 dandanplay，或者没有 MD5 库，则优先搜番剧
    if (servers[1] and servers[1]:find("api%.dandanplay%.")) or (type(MD5) ~= "table" or not MD5.sum) then
        strategy = "anime_first"
    end
    if is_protocol(file_path) and options.hash_for_url then
        set_danmaku_button()
        local temp_file = "temp-" .. PID .. ".mp4"
        local output_path = utils.join_path(DANMAKU_PATH, temp_file)
        local arg = {
            "curl", "--connect-timeout", "10", "--max-time", "30", "--range", "0-16777215",
            "--user-agent", options.user_agent, "--output", output_path, "-L", file_path,
        }
        if options.proxy ~= "" then table.insert(arg, "-x"); table.insert(arg, options.proxy) end

        call_cmd_async(arg, function(error)
            async_running = false
            -- 下载完成后，执行统一匹配链
            execute_match_chain(strategy, output_path, file_name, servers)
        end)
        return
    end

    -- 标准处理
    execute_match_chain(strategy, file_path, file_name, servers)
end
