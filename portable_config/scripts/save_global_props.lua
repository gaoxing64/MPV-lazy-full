--[[

SOURCE_ https://github.com/zenwarr/mpv-config/blob/master/scripts/remember-props.lua
COMMIT_ 20220811 03cfc0e39682a73d9d24a6e01a3c02716a019d1d
文档_ save_global_props.conf

记录全局的属性变化，支持在下次程序启动时恢复，其对应数据保存在对应文件 saved-props.json
（选项 --save-position-on-quit 保存的是基于具体文件的属性，不要与 --watch-later-options 保存的属性相冲突）

可用的快捷键示例（在 input.conf 中写入）：
 <KEY>   script-message-to save_global_props clean_data   # 清除已记录的数据

]]

local mp = require("mp")
local options = require("mp.options")
local utils = require("mp.utils")

local opt = {
	save_mode = 1,                     -- <0|1|2>
	props     = "volume,mute",
	dup_block = false,
	cache_dir = "~~/"
}
options.read_options(opt)

if opt.save_mode == 0 then
	mp.msg.info("已手动禁用 全局属性保存恢复")
	return
end

--opt.props = "volume,mute,speed"

local function split(inputstr, sep)
	local result = {}
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		table.insert(result, str)
	end
	return result
end

opt.props = split(opt.props, ",")
local watch_later_opts = split(mp.get_property("watch-later-options"), ",")
local dup_opts = false

local function check_dup(table1, table2)
	for _, value1 in ipairs(table1) do
		for _, value2 in ipairs(table2) do
			if value1 == value2 then
				dup_opts = true
				mp.msg.warn("存在与 --watch-later-options 重合的项目： " .. value1)
			end
		end
	end
end

check_dup(opt.props, watch_later_opts)

if dup_opts and opt.dup_block then
	mp.msg.warn("已自动禁用 全局属性保存恢复")
	return
end

local cleaned = false
local data_file_path = (mp.command_native({"expand-path", opt.cache_dir .. "saved-props.json"}))

local function read_data_file()
	local json_file = io.open(data_file_path, "a+")
	local result = utils.parse_json(json_file:read("*all"))
	if result == nil then
		result = {}
	end
	json_file:close()
	return result
end

local saved_data = read_data_file()

local function save_data_file()
	if cleaned then
		mp.msg.verbose("因清理属性记录而中止保存功能")
		return
	end
	local file = io.open(data_file_path, "w+")
	if file == nil then
		return
	end
	local content, ret = utils.format_json(saved_data)
	if ret ~= error and content ~= nil then
		file:write(content)
	end
	file:close()
end

local function clean_data_file()
	local file = io.open(data_file_path, "w+")
	if file == nil then
		return
	end
	local content = ""
	file:write(content)
	file:close()
	cleaned = true
	mp.msg.info("全局属性保存恢复 已清理缓存")
	mp.osd_message("已清理记录的属性\n建议重启mpv", 2)
end

local function init()
	for _, prop_name in ipairs(opt.props) do
		local saved_value = saved_data[prop_name]
		if saved_value ~= nil then
			mp.set_property_native(prop_name, saved_value)
		end
		if opt.save_mode == 2 then
			mp.observe_property(prop_name, "native", function(_, prop_value)
				saved_data[prop_name] = mp.get_property_native(prop_name)
				save_data_file()
			end)
		end
	end
end

init()
mp.msg.info("正在运行 全局属性保存恢复 模式" .. opt.save_mode)

if opt.save_mode == 1 then
	mp.register_event("shutdown", function()
		for _, prop_name in ipairs(opt.props) do
			saved_data[prop_name] = mp.get_property_native(prop_name)
			save_data_file()
		end
	end)
end

mp.register_script_message("clean_data", clean_data_file)
