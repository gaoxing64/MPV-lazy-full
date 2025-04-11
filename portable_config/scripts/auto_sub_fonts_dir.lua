--[[
文档_ 无

自动临时加载字体
检测当前播放目录下是否存在 fonts 文件夹，动态修改 --sub-fonts-dir

]]


local utils = require("mp.utils")

local fonts_dir_init = mp.get_property_native("sub-fonts-dir")
local fonts_dir_cur = fonts_dir_init
function update_fonts_dir()
	local path = mp.get_property_native("path")
	local fonts_dir = path:match("(.*[/\\])") .. "fonts"
	if fonts_dir == fonts_dir_cur or fonts_dir == fonts_dir_init then
		return
	end
	local read_success = utils.readdir(fonts_dir)
	if not read_success then
		mp.set_property("sub-fonts-dir", fonts_dir_init)
		fonts_dir_cur = fonts_dir_init
		mp.msg.info("回退 --sub-fonts-dir 至初始值")
	else
		mp.set_property("sub-fonts-dir", fonts_dir)
		fonts_dir_cur = fonts_dir
		mp.msg.info("设定 --sub-fonts-dir 至新值【" .. fonts_dir .. "】")
	end
end

mp.register_event("start-file", update_fonts_dir)
