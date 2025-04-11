-- paste-url.lua
-- 允许通过Ctrl+V粘贴剪贴板中的URL或文件路径并播放

local utils = require 'mp.utils'

-- 注册Ctrl+V快捷键绑定到uosc的paste命令
mp.add_key_binding("Ctrl+v", "paste-url", function()
    -- 使用uosc的paste命令，它会自动处理剪贴板内容
    -- 如果播放列表中有内容，它会添加到播放列表
    -- 如果播放列表为空，它会直接打开
    mp.commandv('script-binding', 'uosc/paste')
end)