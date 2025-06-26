--[[
文档_ playlist_osd.conf

精简 https://github.com/jonniek/mpv-playlistmanager/blob/master/playlistmanager.lua
仅保留最核心的导航功能

可用的快捷键示例（在 input.conf 中写入）：
 <KEY>   script-binding playlist_osd/display   # 显示高级播放列表

 <KEY>   script-message-to playlist_osd random   # 跳转到随机条目

]]

local settings = {

	key_move2up = "UP",
	key_move2down = "DOWN",
	key_move2pageup = "PGUP",
	key_move2pagedown = "PGDWN",
	key_move2begin = "HOME",
	key_move2end = "END",
	key_file_select = "RIGHT",
	key_file_unselect = "LEFT",
	key_file_play = "ENTER",
	key_file_remove = "BS",
	key_playlist_close = "ESC",

	show_title_on_file_load = false,
	show_playlist_on_file_load = false,
	close_playlist_on_playfile = false,
	sync_cursor_on_load = true,
	loop_cursor = true,
	reset_cursor_on_open = true,
	playlist_display_timeout = 4,
	showamount = 15,
	slice_longfilenames = false,
	slice_longfilenames_amount = 80,

	style_ass_tags = "{\\rDefault\\an7\\fs24\\b0\\blur0\\bord1\\1c&H996F9A\\3c&H000000\\q2}",
	playlist_header = "播放列表 [%cursor/%plen]",
	normal_file = "{\\c&HFFFFFF&}□ %name",
	hovered_file = "{\\c&H33FFFF&}■ %name",
	selected_file = "{\\c&C1C1FF&}➔ %name",
	playing_file = "{\\c&HAAAAAA&}▷ %name",
	playing_hovered_file = "{\\c&H00FF00&}▶ %name",
	playing_selected_file = "{\\c&C1C1FF&}➔ %name",
	playlist_sliced_prefix = "▲",
	playlist_sliced_suffix = "▼",

}

local opts = require("mp.options")
opts.read_options(settings, nil, function(list) update_opts(list) end)

local utils = require("mp.utils")
local msg = require("mp.msg")
local assdraw = require("mp.assdraw")

--global variables
local selection = nil
local dynamic_binds = true
local playlist_overlay = mp.create_osd_overlay("ass-events")
local playlist_visible = false
local strippedname = nil
local path = nil
local directory = nil
local filename = nil
local pos = 0
local plen = 0
local cursor = 0
--table for saved media titles for later if we prefer them
local title_table = {}

function is_protocol(path)
	return type(path) == "string" and path:match("^%a[%a%d-_]+://") ~= nil
end

function on_file_loaded()
	refresh_globals()
	filename = mp.get_property("filename")
	path = mp.get_property("path")
	local media_title = mp.get_property("media-title")
	if is_protocol(path) and not title_table[path] and path ~= media_title then
		title_table[path] = media_title
	end

	if settings.sync_cursor_on_load then
		cursor=pos
		--refresh playlist if cursor moved
		if playlist_visible then draw_playlist() end
	end

	strippedname = stripfilename(mp.get_property("media-title"))
	if settings.show_title_on_file_load then
		mp.commandv("show-text", strippedname)
	end
	if settings.show_playlist_on_file_load then
		playlist_show()
	end
end

function on_start_file()
	refresh_globals()
	filename = mp.get_property("filename")
	path = mp.get_property("path")
	--if not a url then join path with working directory
	if not is_protocol(path) then
		path = utils.join_path(mp.get_property("working-directory"), path)
		directory = utils.split_path(path)
	else
		directory = nil
	end
end

function on_end_file()
	strippedname = nil
	path = nil
	directory = nil
	filename = nil
	if playlist_visible then playlist_show() end
end

function refresh_globals()
	pos = mp.get_property_number("playlist-pos", 0)
	plen = mp.get_property_number("playlist-count", 0)
end

--strip a filename based on its extension or protocol according to rules in settings
function stripfilename(pathfile, media_title)
	if pathfile == nil then return "" end
	local ext = pathfile:match("%.([^%.]+)$")
	if not ext then ext = "" end
	local tmp = pathfile
	if settings.slice_longfilenames and tmp:len()>settings.slice_longfilenames_amount+5 then
		tmp = tmp:sub(1, settings.slice_longfilenames_amount):gsub(".[\128-\191]*$", "") .. " ..."
	end
	return tmp
end

--gets the file info of an item
function get_file_info(item)
	local path = mp.get_property("playlist/" .. item - 1 .. "/filename")
	if is_protocol(path) then return {} end
	local file_info = utils.file_info(path)
	if not file_info then
		msg.warn("failed to read file info for", path)
		return {}
	end

	return file_info
end

--gets a nicename of playlist entry at 0-based position i
function get_name_from_index(i, notitle)
	refresh_globals()
	if plen <= i then msg.error("no index in playlist", i, "length", plen); return nil end
	local _, name = nil
	local title = mp.get_property("playlist/" .. i .. "/title")
	local name = mp.get_property("playlist/" .. i .. "/filename")

	--check if file has a media title stored
	if not title and title_table[name] then
		title = title_table[name]
	end

	--if we have media title use a more conservative strip
	if title and not notitle then
		-- Escape a string for verbatim display on the OSD
		-- Ref: https://github.com/mpv-player/mpv/blob/94677723624fb84756e65c8f1377956667244bc9/player/lua/stats.lua#L145
		return stripfilename(title, true):gsub("\\", "\\\239\187\191"):gsub("{", "\\{"):gsub("^ ", "\\h")
	end

	--remove paths if they exist, keeping protocols for stripping
	if string.sub(name, 1, 1) == "/" or name:match("^%a:[/\\]") then
		_, name = utils.split_path(name)
	end
	return stripfilename(name):gsub("\\", "\\\239\187\191"):gsub("{", "\\{"):gsub("^ ", "\\h")
end

function parse_header(string)
	local esc_title = stripfilename(mp.get_property("media-title"), true):gsub("%%", "%%%%")
	local esc_file = stripfilename(mp.get_property("filename")):gsub("%%", "%%%%")
	return string:gsub("%%N", "\\N")
				 :gsub("%%pos", mp.get_property_number("playlist-pos",0)+1)
				 :gsub("%%plen", mp.get_property("playlist-count"))
				 :gsub("%%cursor", cursor+1)
				 :gsub("%%mediatitle", esc_title)
				 :gsub("%%filename", esc_file)
				 -- undo name escape
				 :gsub("%%%%", "%%")
end

function parse_filename(string, name, index)
	local base = tostring(plen):len()
	local esc_name = stripfilename(name):gsub("%%", "%%%%")
	return string:gsub("%%N", "\\N")
				 :gsub("%%pos", string.format("%0" .. base .. "d", index+1))
				 :gsub("%%name", esc_name)
				 -- undo name escape
				 :gsub("%%%%", "%%")
end

function parse_filename_by_index(index)
	local template = settings.normal_file

	local is_idle = mp.get_property_native("idle-active")
	local position = is_idle and -1 or pos

	if index == position then
		if index == cursor then
			if selection then
				template = settings.playing_selected_file
			else
				template = settings.playing_hovered_file
			end
		else
			template = settings.playing_file
		end
	elseif index == cursor then
		if selection then
			template = settings.selected_file
		else
			template = settings.hovered_file
		end
	end

	return parse_filename(template, get_name_from_index(index), index)
end

function is_terminal_mode()
	local width, height, aspect_ratio = mp.get_osd_size()
	return width == 0 and height == 0 and aspect_ratio == 0
end

function draw_playlist()
	refresh_globals()

	-- if there is no playing file, then cursor can be -1. That would break rendering of playlist.
	if cursor == -1 then
		cursor = 0
	end

	local ass = assdraw.ass_new()
	local terminaloutput = ""

	ass:append(settings.style_ass_tags)

	if settings.playlist_header ~= "" then
		local header = parse_header(settings.playlist_header)
		ass:append(header .. "\\N")
		terminaloutput = terminaloutput .. header .. "\n"
	end

	-- (visible index, playlist index) pairs of playlist entries that should be rendered
	local visible_indices = {}

	local one_based_cursor = cursor + 1
	table.insert(visible_indices, one_based_cursor)

	local offset = 1;
	local visible_indices_length = 1;
	while visible_indices_length < settings.showamount and visible_indices_length < plen do
		-- add entry for offset steps below the cursor
		local below = one_based_cursor + offset
		if below <= plen then
			table.insert(visible_indices, below)
			visible_indices_length = visible_indices_length + 1;
		end

		-- add entry for offset steps above the cursor
		-- also need to double check that there is still space, this happens if we have even numbered limit
		local above = one_based_cursor - offset
		if above >= 1 and visible_indices_length < settings.showamount and visible_indices_length < plen then
			table.insert(visible_indices, 1, above)
			visible_indices_length = visible_indices_length + 1;
		end

		offset = offset + 1
	end

	-- both indices are 1 based
	for display_index, playlist_index in pairs(visible_indices) do
		if display_index == 1 and playlist_index ~= 1 then
			ass:append(settings.playlist_sliced_prefix .. "\\N")
			terminaloutput = terminaloutput .. settings.playlist_sliced_prefix .. "\n"
		elseif display_index == settings.showamount and playlist_index ~= plen then
			ass:append(settings.playlist_sliced_suffix)
			terminaloutput = terminaloutput .. settings.playlist_sliced_suffix .. "\n"
		else
			-- parse_filename_by_index expects 0 based index
			local fname = parse_filename_by_index(playlist_index - 1)
			ass:append(fname .. "\\N")
			terminaloutput = terminaloutput .. fname .. "\n"
		end
	end

	if is_terminal_mode() then
		local timeout_setting = settings.playlist_display_timeout
		local timeout = timeout_setting == 0 and 2147483 or timeout_setting
		-- TODO: probably have to strip ass tags from terminal output
		-- would maybe be possible to use terminal color output instead
		mp.osd_message(terminaloutput, timeout)
	else
		playlist_overlay.data = ass.text
		playlist_overlay:update()
	end
end

function toggle_playlist(show_function)
	local show = show_function or playlist_show
	if playlist_visible then
		remove_keybinds()
	else
		-- toggle always shows without timeout
		show(0)
	end
end

function playlist_show(duration)
	refresh_globals()
	if plen == 0 then return end
	if not playlist_visible and settings.reset_cursor_on_open then
		resetcursor()
	end

	playlist_visible = true
	add_keybinds()

	draw_playlist()
	keybindstimer:kill()

	local dur = tonumber(duration) or settings.playlist_display_timeout
	if dur > 0 then
		keybindstimer = mp.add_periodic_timer(dur, remove_keybinds)
	end
end

function showplaylist_non_interactive(duration)
	refresh_globals()
	if plen == 0 then return end
	if not playlist_visible and settings.reset_cursor_on_open then
		resetcursor()
	end
	playlist_visible = true
	draw_playlist()
	keybindstimer:kill()

	local dur = tonumber(duration) or settings.playlist_display_timeout
	if dur > 0 then
		keybindstimer = mp.add_periodic_timer(dur, remove_keybinds)
	end
end

function selectfile()
	refresh_globals()
	if plen == 0 then return end
	if not selection then
		selection=cursor
	else
		selection=nil
	end
	playlist_show()
end

function unselectfile()
	selection=nil
	playlist_show()
end

function resetcursor()
	selection = nil
	cursor = mp.get_property_number("playlist-pos", 1)
end

function removefile()
	refresh_globals()
	if plen == 0 then return end
	selection = nil
	if cursor==pos then mp.command("script-message unseenplaylist mark true \"playlist_osd avoid conflict when removing file\"") end
	mp.commandv("playlist-remove", cursor)
	if cursor==plen-1 then cursor = cursor - 1 end
	if plen == 1 then
		remove_keybinds()
	else
		playlist_show()
	end
end

function moveup()
	refresh_globals()
	if plen == 0 then return end
	if cursor~=0 then
		if selection then mp.commandv("playlist-move", cursor,cursor-1) end
		cursor = cursor-1
	elseif settings.loop_cursor then
		if selection then mp.commandv("playlist-move", cursor,plen) end
		cursor = plen-1
	end
	playlist_show()
end

function movedown()
	refresh_globals()
	if plen == 0 then return end
	if cursor ~= plen-1 then
		if selection then mp.commandv("playlist-move", cursor,cursor+2) end
		cursor = cursor + 1
	elseif settings.loop_cursor then
		if selection then mp.commandv("playlist-move", cursor,0) end
		cursor = 0
	end
	playlist_show()
end

function movepageup()
	refresh_globals()
	if plen == 0 or cursor == 0 then return end
	local offset = settings.showamount % 2 == 0 and 1 or 0
	local last_file_that_doesnt_scroll = math.ceil(settings.showamount / 2)
	local reverse_cursor = plen - cursor
	local files_to_jump = math.max(last_file_that_doesnt_scroll + offset - reverse_cursor, 0) + settings.showamount - 2
	local prev_cursor = cursor
	cursor = cursor - files_to_jump
	if cursor < last_file_that_doesnt_scroll then
		cursor = 0
	end
	if selection then
		mp.commandv("playlist-move", prev_cursor, cursor)
	end
	playlist_show()
end

function movepagedown()
	refresh_globals()
	if plen == 0 or cursor == plen - 1 then return end
	local last_file_that_doesnt_scroll = math.ceil(settings.showamount / 2) - 1
	local files_to_jump = math.max(last_file_that_doesnt_scroll - cursor, 0) + settings.showamount - 2
	local prev_cursor = cursor
	cursor = cursor + files_to_jump

	local cursor_on_last_page = plen - (settings.showamount - 3)
	if cursor > cursor_on_last_page then
		cursor = plen - 1
	end
	if selection then
		mp.commandv("playlist-move", prev_cursor, cursor + 1)
	end
	playlist_show()
end

function movebegin()
	refresh_globals()
	if plen == 0 or cursor == 0 then return end
	local prev_cursor = cursor
	cursor = 0
	if selection then mp.commandv("playlist-move", prev_cursor, cursor) end
	playlist_show()
end

function moveend()
	refresh_globals()
	if plen == 0 or cursor == plen-1 then return end
	local prev_cursor = cursor
	cursor = plen-1
	if selection then mp.commandv("playlist-move", prev_cursor, cursor+1) end
	playlist_show()
end

function playlist_next()
	mp.commandv("playlist-next", "weak")
	if settings.close_playlist_on_playfile then
		remove_keybinds()
	end
	if playlist_visible then playlist_show() end
end

function playlist_prev()
	mp.commandv("playlist-prev", "weak")
	if settings.close_playlist_on_playfile then
		remove_keybinds()
	end
	if playlist_visible then playlist_show() end
end

function playlist_random()
	refresh_globals()
	if plen < 2 then return end
	math.randomseed(os.time())
	local random = pos
	while random == pos do
		random = math.random(0, plen-1)
	end
	mp.set_property("playlist-pos", random)
	if settings.close_playlist_on_playfile then
		remove_keybinds()
	end
end

function playfile()
	refresh_globals()
	if plen == 0 then return end
	selection = nil
	local is_idle = mp.get_property_native("idle-active")
	if cursor ~= pos or is_idle then
		mp.set_property("playlist-pos", cursor)
	else
		if cursor~=plen-1 then
			cursor = cursor + 1
		end
		mp.commandv("playlist-next", "weak")
	end
	if settings.close_playlist_on_playfile then
		remove_keybinds()
	end
	if playlist_visible then playlist_show() end
end

function bind_keys(keys, name, func, opts)
	if keys == nil or keys == "" then
		mp.add_key_binding(keys, name, func, opts)
		return
	end
	local i = 1
	for key in keys:gmatch("[^%s]+") do
		local prefix = i == 1 and "" or i
		mp.add_key_binding(key, name .. prefix, func, opts)
		i = i + 1
	end
end

function bind_keys_forced(keys, name, func, opts)
	if keys == nil or keys == "" then
		mp.add_forced_key_binding(keys, name, func, opts)
		return
	end
	local i = 1
	for key in keys:gmatch("[^%s]+") do
		local prefix = i == 1 and "" or i
		mp.add_forced_key_binding(key, name .. prefix, func, opts)
		i = i + 1
	end
end

function unbind_keys(keys, name)
	if keys == nil or keys == "" then
		mp.remove_key_binding(name)
		return
	end
	local i = 1
	for key in keys:gmatch("[^%s]+") do
		local prefix = i == 1 and "" or i
		mp.remove_key_binding(name .. prefix)
		i = i + 1
	end
end

function add_keybinds()
	bind_keys_forced(settings.key_move2up, "moveup", moveup, "repeatable")
	bind_keys_forced(settings.key_move2down, "movedown", movedown, "repeatable")
	bind_keys_forced(settings.key_move2pageup, "movepageup", movepageup, "repeatable")
	bind_keys_forced(settings.key_move2pagedown, "movepagedown", movepagedown, "repeatable")
	bind_keys_forced(settings.key_move2begin, "movebegin", movebegin, "repeatable")
	bind_keys_forced(settings.key_move2end, "moveend", moveend, "repeatable")
	bind_keys_forced(settings.key_file_select, "selectfile", selectfile)
	bind_keys_forced(settings.key_file_unselect, "unselectfile", unselectfile)
	bind_keys_forced(settings.key_file_play, "playfile", playfile)
	bind_keys_forced(settings.key_file_remove, "removefile", removefile, "repeatable")
	bind_keys_forced(settings.key_playlist_close, "closeplaylist", remove_keybinds)
end

function remove_keybinds()
	keybindstimer:kill()
	keybindstimer = mp.add_periodic_timer(settings.playlist_display_timeout, remove_keybinds)
	keybindstimer:kill()
	playlist_overlay.data = ""
	playlist_overlay:remove()
	if is_terminal_mode() then
		mp.osd_message("")
	end
	playlist_visible = false
	if dynamic_binds then
		unbind_keys(settings.key_move2up, "moveup")
		unbind_keys(settings.key_move2down, "movedown")
		unbind_keys(settings.key_move2pageup, "movepageup")
		unbind_keys(settings.key_move2pagedown, "movepagedown")
		unbind_keys(settings.key_move2begin, "movebegin")
		unbind_keys(settings.key_move2end, "moveend")
		unbind_keys(settings.key_file_select, "selectfile")
		unbind_keys(settings.key_file_unselect, "unselectfile")
		unbind_keys(settings.key_file_play, "playfile")
		unbind_keys(settings.key_file_remove, "removefile")
		unbind_keys(settings.key_playlist_close, "closeplaylist")
	end
end

keybindstimer = mp.add_periodic_timer(settings.playlist_display_timeout, remove_keybinds)
keybindstimer:kill()

if not dynamic_binds then
	add_keybinds()
end

--script message handler
function handlemessage(msg, value, value2)
	if msg == "show" and value == "playlist" then
		if value2 ~= "toggle" then
			playlist_show(value2)
			return
		else
			toggle_playlist(playlist_show)
			return
		end
	end
	if msg == "show" and value == "playlist-nokeys" then
		if value2 ~= "toggle" then
			showplaylist_non_interactive(value2)
			return
		else
			toggle_playlist(showplaylist_non_interactive)
			return
		end
	end
	if msg == "show" and value == "filename" and strippedname and value2 then
		mp.commandv("show-text", strippedname, tonumber(value2)*1000 ) ; return
	end
	if msg == "show" and value == "filename" and strippedname then
		mp.commandv("show-text", strippedname ) ; return
	end

	if msg == "next" then playlist_next() ; return end
	if msg == "prev" then playlist_prev() ; return end
	if msg == "random" then playlist_random() ; return end
	if msg == "close" then remove_keybinds() end
end

mp.register_script_message("playlist_osd", handlemessage)
mp.register_script_message("random", playlist_random)

bind_keys(nil, "display", playlist_show)

mp.register_event("start-file", on_start_file)
mp.register_event("file-loaded", on_file_loaded)
mp.register_event("end-file", on_end_file)
