# 📚 MPV 播放器 - 完整脚本功能文档

> 📖 功能字典 | 配置参考 | 进阶用法
>
> 🚀 **新手入门**：[5 分钟快速上手](快速开始.md) | 🏠 **返回主页**：[../README.md](../README.md)

---

## 📖 文档导航

| 文档 | 用途 | 阅读方式 |
|------|------|----------|
| [5 分钟快速上手](快速开始.md) | 8 个高频场景教程 | 新手必读，线性阅读 |
| [完整脚本索引](#-完整脚本索引) | 41 个脚本功能速查 | 按需查阅 |
| [核心功能详解](#-核心功能详解) | 每个脚本完整说明 | 随机访问 |
| [配置参考](#-配置参考) | 配置文件说明 | 修改时查阅 |

---

## 📋 完整脚本索引

### 🎬 播放控制（12 个）

| 脚本 | 功能 | 配置 |
|------|------|------|
| [autoload.lua](#autoloadlua) | 自动加载同目录文件 | `autoload.conf` |
| [auto-save-state.lua](#auto-save-statelua) | 定期保存播放状态 | `auto_save_state.conf` |
| [blacklist-extensions.lua](#blacklist-extensionslua) | 按扩展名过滤 | `blacklist_extensions.conf` |
| [chapterskip.lua](#chapterskiplua) | 跳过片头片尾 | `chapterskip.conf` |
| [chapter-make-read.lua](#chapter-make-readlua) | 读取创建章节 | `chapter_make_read.conf` |
| [cycle-commands.lua](#cycle-commandslua) | 单键循环执行多命令 | 无 |
| [delete-current-file.lua](#delete-current-filelua) | 删除文件到回收站 | 无 |
| [dynamic-crop.lua](#dynamic-croplua) | 自动裁剪黑边 | `dynamic_crop.conf` |
| [evafast.lua](#evafastlua) | 智能快进 | `evafast.conf` |
| [fix-avsync.lua](#fix-avsynclua) | 修复音画同步 | 无 |
| [inputevent.lua](#inputeventlua) | 增强输入手势 | `inputevent.conf` |
| [undoredo.lua](#undoredolua) | 进度撤销/重做 | 无 |

### 📝 字幕工具（7 个）

| 脚本 | 功能 | 配置 |
|------|------|------|
| [sub-assrt.lua](#sub-assrtlua) | 射手网字幕下载 | `sub_assrt.conf` |
| [sub-select.lua](#sub-selectlua) | 智能字幕选择 | `sub_select.conf` |
| [sub_export.lua](#sub_exportlua) | 导出内封字幕 | `sub_export.conf` |
| [sub-fastwhisper.lua](#sub-fastwhisperlua) | AI 生成字幕 | `sub_fastwhisper.conf` |
| [sub-fonts-dir-auto.lua](#sub-fonts-dir-autolua) | 自动查找字体目录 | 无 |
| [autosubsync/](#autosubsync) | 字幕自动同步 | `autosubsync/` |
| [sponsorblock_minimal.lua](#sponsorblock_minimallua) | 跳过赞助片段 | `sponsorblock_minimal.conf` |

### 📋 播放列表管理（5 个）

| 脚本 | 功能 | 配置 |
|------|------|------|
| [playlistmanager.lua](#playlistmanagerlua) | 播放列表管理 | `playlistmanager.conf` |
| [quality-menu.lua](#quality-menulua) | YouTube 质量选择 | `quality-menu.conf` |
| [recentmenu.lua](#recentmenulua) | 最近播放记录 | `recentmenu.conf` |
| [file-browser/](#file-browser) | 文件浏览器 | `file_browser.conf` |
| [dyn_menu.lua](#dyn_menulua) | 动态菜单生成 | `dyn_menu.conf` |

### 🔖 书签与历史（3 个）

| 脚本 | 功能 | 配置 |
|------|------|------|
| [simplebookmark.lua](#simplebookmarklua) | 书签管理 | `simplebookmark.conf` |
| [simplehistory.lua](#simplehistorylua) | 历史记录 | `simplehistory.conf` |
| [history-bookmark.lua](#history-bookmarklua) | 目录级历史书签 | `history_bookmark.conf` |

### 🎥 视频处理（4 个）

| 脚本 | 功能 | 配置 |
|------|------|------|
| [mpv-animated.lua](#mpv-animatedlua) | 导出 GIF/WebP | `mpv_animated.conf` |
| [slicing_copy.lua](#slicing_copylua) | 快速剪切视频 | `slicing_copy.conf` |
| [smartcopypaste_II.lua](#smartcopypaste_iilua) | 智能复制粘贴 | `smartcopypaste_II.conf` |
| [thumbfast.lua](#thumbfastlua) | 缩略图生成 | `thumbfast.conf` |

### 🎨 界面增强（6 个）

| 脚本 | 功能 | 配置 |
|------|------|------|
| [uosc/](#uosc) | 现代化 OSD 界面 | `uosc.conf` |
| [uosc_danmaku/](#uosc_danmaku) | 弹幕系统 | `uosc_danmaku.conf` |
| [hdr-mode.lua](#hdr-modelua) | HDR 自动切换 | `hdr_mode.conf` |
| [persist_properties.lua](#persist_propertieslua) | 持久化属性 | `persist_properties.conf` |
| [trackselect.lua](#trackselectlua) | 智能轨道选择 | `trackselect.conf` |
| [open_dialog.lua](#open_dialoglua) | 系统对话框 | `open_dialog.conf` |

### 🌐 网络功能（4 个）

| 脚本 | 功能 | 配置 |
|------|------|------|
| [simple-mpv-webui/](#simple-mpv-webui) | 浏览器远程控制 | `webui.conf` |
| [mpv-torrserver.lua](#mpv-torrserverlua) | 种子流媒体 | `mpv_torrserver.conf` |
| [trakt-scrobble/](#trakt-scrobble) | Trakt 观看同步 | `trakt_scrobble.conf` |
| [manager.lua](#managerlua) | Git 脚本管理 | `manager.json` |

---

## 📖 核心功能详解

### autoload.lua

**功能**：自动加载当前文件所在目录中的其他媒体文件到播放列表。

**配置**：`script-opts/autoload.conf`
```ini
disabled=no                       # 禁用脚本
videos=yes                        # 加载视频
audio=yes                         # 加载音频
images=yes                        # 加载图片
same_type=yes                     # 只加载同类型文件
same_series=no                    # 只加载同系列（如 S01E01, S01E02）
directory_mode=ignore             # 子目录模式：ignore/lazy/recursive
ignore_hidden=yes                 # 忽略隐藏文件
ignore_patterns=^~,^bak-,%.bak$   # 忽略文件名模式
additional_video_exts=webm,mkv    # 额外视频扩展名
```

**使用场景**：
- 追番时自动加载整季动画到播放列表
- 打开音乐专辑中的一首，自动加载整张专辑
- 查看图片文件夹时，自动加载所有图片并支持幻灯片播放

**进阶用法**：
- `same_series=yes`：只加载同系列文件（如 S01E01, S01E02）
- `directory_mode=recursive`：递归加载子目录文件
- `ignore_patterns`：使用正则表达式过滤特定文件

**快捷键**：
- `F5` - 重新加载目录（当目录有新增文件时）
- `Ctrl + A` - 临时禁用/启用 autoload

---

### auto-save-state.lua

**功能**：定期自动保存播放状态（watch-later），防止意外退出丢失进度。

**配置**：`script-opts/auto_save_state.conf`
```ini
save_interval=60                  # 保存间隔（秒）
percent_pos=99                    # 视为完成的进度百分比
```

**使用场景**：
- 观看长视频时定期保存进度
- 暂停时自动保存，随时继续观看
- 播放完成后自动清理状态文件

**注意**：默认自动运行，无需手动操作。

---

### blacklist-extensions.lua

**功能**：根据扩展名黑名单或白名单过滤播放列表中的文件。

**配置**：`script-opts/blacklist_extensions.conf`
```ini
blacklist=                        # 黑名单扩展名（逗号分隔）
whitelist=                        # 白名单扩展名（逗号分隔）
remove_files_without_extension=false
oneshot=true                      # 单次运行模式
```

**使用场景**：
- 过滤掉不需要的格式（如过滤掉 .rmvb 只保留 .mkv）
- 仅保留特定类型文件（白名单模式）

---

### chapterskip.lua

**功能**：智能跳过片头片尾，支持章节标题、位置推断和静音检测。

**配置**：`script-opts/chapterskip.conf`
```ini
mode=auto                          # none（禁用）/auto（自动）/manual（确认）
language=chs                       # eng/chs
timeout=20                         # 手动模式确认倒计时（秒）
skip=opening;ending                # 跳过类别：opening/ending/credits/preview
enable_position_inference=yes      # 位置推断（视频前 200 秒/后 300 秒）
enable_history_position_inference=yes  # 跨文件历史记录应用
intro_time_window=200              # 片头时间窗口（秒）
outro_time_window=300              # 片尾时间窗口（秒）
silence_audio_level=-40            # 静音检测阈值（dB）
silence_duration=0.7               # 静音持续时间（秒）
force_mute_on_skip=yes             # 跳过时静音（避免音频突兀）
```

**使用场景**：
- 追番自动跳过 OP/ED
- 看电影跳过制作人员名单
- 跳过视频中的静音片段

**进阶用法 - 手动标记**：
1. 播放到片头开始位置，按 `Shift + M`
2. 播放到片头结束位置，再按 `Shift + M`
3. 保存到历史记录，同目录后续集数自动应用

**快捷键**：
- `Shift + S` - 切换跳过模式（auto/manual/none）
- `Shift + M` - 手动标记跳过片段开始/结束
- `F3` - 跳转到下一个静音点
- `Ctrl + Shift + S` - 清除当前视频的跳过历史

---

### chapter-make-read.lua

**功能**：读取并创建视频章节信息。

**配置**：`script-opts/chapter_make_read.conf`

**使用场景**：
- 为无章节视频添加章节标记
- 从外部文件读取章节信息

---

### cycle-commands.lua

**功能**：允许通过单个键绑定循环执行多个命令。

**配置**：无

**input.conf 示例**：
```ini
# 循环显示不同类型的信息
F1  script-message cycle-commands "show-text one" "show-text two" "show-text three"

# 循环切换配置
F2  script-message cycle-commands/osd "apply-profile p1" "apply-profile p2"
```

**使用场景**：
- 单键切换多个配置
- 循环显示播放信息

---

### delete-current-file.lua

**功能**：删除当前播放的文件并移至回收站，同时从播放列表移除。

**配置**：无

**input.conf 示例**：
```ini
KP0  script-message-to delete_current_file delete-file
KP0  script-message-to delete_current_file delete-file KP1 "按 1 确认删除"
```

**使用场景**：
- 移除不需要的视频文件
- 清理观看过的内容

**注意**：Windows 使用 PowerShell 移至回收站，Linux 使用 trash-cli。

---

### dynamic-crop.lua

**功能**：使用 ffmpeg cropdetect 滤镜自动检测并应用视频裁剪。

**配置**：`script-opts/dynamic_crop.conf`
```ini
mode=4                             # 0-禁用 1-按需 2-单次 3-动态手动 4-动态自动
start_delay=0                      # 开始延迟（秒）
prevent_change_timer=30            # 防止变化定时器
fix_windowed_behavior=1            # 窗口化行为修复
ratios=2.76 2.55 24/9 2.4 2.35 2 16/9 4/3  # 支持的宽高比
detect_limit=26                    # 检测阈值（0-255）
crop_method=1                      # 0-lavfi-crop 1-video-crop
```

**使用场景**：
- 自动裁剪视频黑边
- 保持正确宽高比
- 窗口化模式下保持窗口大小

**快捷键**：
- `C`（Shift+C）- 切换裁剪

**依赖**：需要 hwdec=no 或 hwdec=*-copy

---

### evafast.lua

**功能**：智能快进脚本，轻按跳转，长按加速播放，支持字幕检测自动限速。

**配置**：`script-opts/evafast.conf`
```ini
seek_distance=5                    # 跳转距离（秒），设为 0 仅启用快进
speed_increase=0.1                 # 速度增加量
speed_decrease=0.1                 # 释放时速度减少量
speed_interval=0.05                # 速度调整间隔（秒）
speed_cap=3                        # 最高速度
subs_speed_cap=1.5                 # 字幕显示时限速，no 表示与 speed_cap 相同
multiply_modifier=no               # 乘法调整（true=1.1x,1.2x / false=+0.1,+0.2）
show_speed=yes                     # 显示当前速度 OSD
subs_lookahead=no                  # 字幕预检测（提前检测下一字幕）
```

**使用场景**：
- 跳过冗长介绍片段
- 加速观看节奏缓慢部分
- 不错过字幕内容

**使用方式**：
- 轻按 `→`：快进 5 秒
- 长按 `→`：加速播放（速度逐渐增加到 3 倍）
- 释放 `→`：速度逐渐恢复
- 字幕出现：自动限速到 1.5 倍

**进阶配置**：
- `seek_distance=0`：禁用跳转，仅保留快进功能
- `multiply_modifier=yes`：使用乘法调整速度（1.1x, 1.2x...）

---

### fix-avsync.lua

**功能**：切换音频输出设备时自动修复音画同步问题。

**配置**：无

**使用场景**：
- 切换音频设备后音画不同步时自动修复

**注意**：仅在启用音频滤镜时触发，自动运行。

---

### inputevent.lua

**功能**：增强型输入事件处理，支持单击、双击、三击、长按等复杂手势。

**配置**：`script-opts/inputevent.conf`
```ini
enable_external_config=false       # 启用外部配置
external_config=~~/script-opts/inputevent_key.conf
prefix=event                       # 事件前缀
```

**input.conf 示例**：
```ini
# 单击全屏
MBTN_LEFT  #event:click|fullscreen>0.5 : cycle fullscreen

# 双击暂停
MBTN_LEFT  #event:double_click : cycle pause

# 长按显示文本并暂停
MBTN_LEFT  #event:press : show-text "按下" ; cycle pause
```

**使用场景**：
- 鼠标多击手势
- 长按操作
- 条件执行（基于 mpv 属性）

---

### undoredo.lua

**功能**：支持播放进度的撤销（Undo）和重做（Redo）。

**配置**：无

**快捷键**：
- `Ctrl + Z` - 撤销到之前的进度点
- `Ctrl + Y` - 重做已撤销的进度
- `Ctrl + Alt + Z` - 循环撤销/重做模式

**使用场景**：
- 误操作后恢复之前的播放位置

---

### sub-assrt.lua

**功能**：从伪射手网（assrt.net）搜索并下载字幕。

**配置**：`script-opts/sub_assrt.conf`
```ini
api_token=你的 token                 # 必需，从 assrt.net 个人中心获取
use_https=true                     # 使用 HTTPS
proxy=                             # 代理设置（如 http://127.0.0.1:7890）
timeout=10                         # 请求超时（秒）
max_results=10                     # 最大显示结果数
auto_download_best=no              # 自动下载最佳匹配
search_source=title                # title（文件名）/hash（文件哈希）
sub_format=ass                     # ass/srt
save_path=source                   # source（视频同级）/specified（指定目录）
specified_path=~~/subtitles        # 指定保存目录
overwrite_existing=no              # 覆盖已存在字幕
```

**使用场景**：
- 外语电影中文字幕下载
- 寻找字幕组精校字幕
- 自动识别剧集信息精准下载

**进阶用法**：
- `search_source=hash`：使用文件哈希搜索，更精准
- `save_path=specified`：统一保存字幕到指定目录
- `auto_download_best=yes`：自动下载最佳匹配（仍建议手动确认）

**快捷键**：
- `S` - 搜索字幕
- `Ctrl + S` - 手动输入关键词搜索
- `Alt + S` - 重新搜索当前视频

**首次使用**：
1. 访问 https://assrt.net 注册账号
2. 进入个人中心获取 API Token
3. 填入配置文件

---

### sub-select.lua

**功能**：基于音频轨道和字幕名称/语言的高级字幕选择。

**配置**：`script-opts/sub_select.conf`
```ini
force_enable=false                 # 强制启用
hook=true                          # 使用钩子同步执行
fingerprint=false                  # 使用轨道指纹
smart_keep=false                   # 智能保持上次选择
preferred_audio_lang=jpn/japanese  # 首选音频语言
preferred_sub_lang=eng             # 首选字幕语言
excluded_sub_words=sign            # 排除词汇（如歌词字幕）
```

**使用场景**：
- 自动匹配原声字幕
- 排除歌词/注释字幕
- 根据音频语言智能选择

---

### sub_export.lua

**功能**：导出当前选中的内封字幕为独立文件（srt/ass/sup）。

**配置**：`script-opts/sub_export.conf`
```ini
ffmpeg_path=ffmpeg                 # ffmpeg 路径
language=eng                       # eng/chs
```

**快捷键**：
- `X` - 导出选中字幕

**使用场景**：
- 提取 MKV 内封字幕
- 字幕格式转换

**依赖**：ffmpeg

---

### sub-fastwhisper.lua

**功能**：使用 faster-whisper 自动生成 AI 字幕，支持实时翻译。

**配置**：`script-opts/sub_fastwhisper.conf`
```ini
fast_whisper_path=faster-whisper   # faster-whisper 路径
model=base                         # base/small/medium/large/turbo
device=cpu                         # cpu/cuda
language=                          # 留空自动检测
threads=0                          # CPU 线程数（0=自动）
max_line_width=100                 # 最大行宽
use_segment=false                  # 分段模式
segment_duration=10                # 分段时长（秒）
api_url=                           # GPT API 地址
api_key=                           # GPT API 密钥
translate=Chinese                  # 翻译目标语言
```

**使用场景**：
- 无字幕视频生成字幕
- 实时翻译外语视频
- 边下边生成（流媒体）

**快捷键**：
- `W` - 生成字幕
- `T` - 翻译字幕

**依赖**：faster-whisper standalone、ffmpeg（分段模式）、curl（翻译模式）

---

### sub-fonts-dir-auto.lua

**功能**：自动查找视频目录下的 `Fonts` 文件夹并设置为字幕字体目录。

**配置**：无

**使用场景**：
- 动漫视频自带字幕字体自动加载

**注意**：需要支持 `sub-fonts-dir` 选项的 mpv 版本。

---

### autosubsync/

**功能**：字幕自动同步，调整字幕时间轴匹配视频版本。

**配置**：`autosubsync/` 目录配置

**使用场景**：
- 字幕与视频不同步时自动校准
- 匹配不同版本的视频

---

### sponsorblock_minimal.lua

**功能**：使用 SponsorBlock API 跳过 YouTube 和 Bilibili 视频中的赞助片段。

**配置**：`script-opts/sponsorblock_minimal.conf`
```ini
youtube_sponsor_server=https://sponsor.ajay.app/api/skipSegments
bilibili_sponsor_server=https://bsbsb.top/api/skipSegments
categories="sponsor"               # 跳过类别
```

**使用场景**：
- 跳过 YouTube 视频赞助片段
- 跳过 B 站视频广告

**依赖**：curl

---

### playlistmanager.lua

**功能**：功能丰富的播放列表管理器，支持可视化浏览、排序、搜索和编辑。

**配置**：`script-opts/playlistmanager.conf`
```ini
dynamic_binds=yes                  # 动态键绑定（仅在播放列表显示时激活）
key_showplaylist=SHIFT+ENTER       # 显示播放列表快捷键
showamount=13                      # 最大显示行数
default_sort=name-asc              # 默认排序：name-asc/date-desc/size-asc
filename_replace=[{"pattern":"_","replace":" "}]  # 文件名替换规则
loadfiles_on_start=no              # 启动时自动加载目录文件
playlist_savepath=                 # 播放列表保存目录（留空使用默认）
style_ass_tags={\fnNoto Sans CJK SC\fs26\b1}  # 字体样式
curtain_opacity=0.0                # 背景遮罩透明度（0.0-1.0）
close_playlist_on_playfile=no      # 播放文件后关闭列表
loop_cursor=yes                    # 光标循环滚动
```

**使用场景**：
- 管理大型播放列表
- 快速查找文件
- 批量操作（移除、排序、保存）

**进阶用法**：
- `dynamic_binds=yes`：键绑定仅在列表显示时激活，避免冲突
- `filename_replace`：美化显示的文件名（如替换下划线为空格）
- `curtain_opacity=0.5`：半透明背景遮罩

**快捷键**：
- `Shift + Enter` - 打开播放列表
- `UP/DOWN` - 上下移动选择
- `ENTER` - 播放选中文件
- `Del/BS` - 移除选中文件
- `S` - 排序（弹出排序菜单）
- `R` - 随机打乱
- `P` - 保存播放列表
- `L` - 加载文件
- `Ctrl + D` - 加载整个目录
- `Esc` - 关闭列表

---

### quality-menu.lua

**功能**：YouTube 视频质量选择菜单，支持视频和音频轨道选择。

**配置**：`script-opts/quality-menu.conf`
```ini
fetch_formats=true                 # 使用 yt-dlp 获取格式
start_with_menu=false              # 打开 URL 时自动显示菜单
columns_video=...                  # 视频列配置
sort_video=...                     # 视频排序配置
menu_timeout=6                     # 菜单超时（秒）
curtain_opacity=0.7                # 背景遮罩透明度
```

**使用场景**：
- 选择 YouTube 视频分辨率
- 选择音频质量

**快捷键**：
- `F` - 视频质量菜单
- `Alt + F` - 音频质量菜单

**依赖**：yt-dlp 或 youtube-dl

---

### recentmenu.lua

**功能**：最近播放记录菜单，支持快速访问历史记录。

**配置**：`script-opts/recentmenu.conf`
```ini
enabled=true                       # 启用
path=~~/recent.json                # 记录文件路径
title=Recently played              # 菜单标题
length=10                          # 记录数量
width=88                           # 标题宽度
ignore_same_series=true            # 忽略同系列文件
reduce_io=false                    # 减少 IO 操作
```

**使用场景**：
- 快速访问最近观看的视频

**快捷键**：
- `Ctrl + R` - 打开最近记录
- `Ctrl + T` - 播放最后一个

**依赖**：uosc（可选）、mp.input（可选）

---

### file-browser/

**功能**：文件浏览器界面，支持浏览本地和网络文件。

**配置**：`script-opts/file_browser.conf`

**使用场景**：
- 在 mpv 内浏览文件系统
- 访问网络共享

---

### dyn_menu.lua

**功能**：动态菜单生成器，支持从 input.conf 创建上下文菜单。

**配置**：`script-opts/dyn_menu.conf`
```ini
use_mpv_impl=true                  # 使用 mpv 原生菜单实现
uosc_syntax=false                  # 启用 uosc 菜单语法
escape_title=true                  # 转义&字符
max_title_length=80                # 最大标题长度
max_playlist_items=20              # 最大播放列表项
```

**input.conf 示例**：
```ini
F10  ignore  #menu: Tracks #@tracks     # 轨道菜单
F11  ignore  #menu: Chapters #@chapters # 章节菜单
```

**使用场景**：
- 创建自定义菜单
- 轨道选择菜单

**依赖**：uosc（可选）

---

### simplebookmark.lua

**功能**：高级书签管理系统，支持分组、快捷键、搜索和过滤。

**配置**：`script-opts/simplebookmark.conf`
```ini
auto_run=yes                       # 自动运行
osd_messages=yes                   # 显示 OSD 消息
osd_duration=2000                  # OSD 显示时长（毫秒）
chapter_bookmarks=yes              # 允许章节标记
slot_1=Ctrl+1                      # 快速槽位 1-9
default_group=默认分组              # 默认分组名称
group_separator=/                  # 分组分隔符（支持多级分组）
showamount=15                      # 列表最大显示行数
time_format=human                  # 时间格式：human/seconds/timestamp
sort_mode=created_desc             # 排序模式
filter_mode=none                   # 过滤模式：none/group/tag
```

**使用场景**：
- 标记教程视频重点章节
- 保存精彩片段
- 管理多个电视剧观看进度

**进阶用法**：
- 多级分组：输入 `动画/日本/海贼王` 创建三级分组
- 快速槽位：`Ctrl + 1~9` 快速保存/跳转
- 搜索过滤：在列表中输入关键词搜索

**快捷键**：
- `Ctrl + B` - 保存书签
- `B` - 打开书签列表
- `Ctrl + 1~9` - 快速槽位保存/跳转
- `UP/DOWN` - 选择书签
- `ENTER` - 跳转到选中书签
- `Del` - 删除选中书签
- `Esc` - 关闭列表
- `M` - 标记当前为章节

---

### simplehistory.lua

**功能**：播放历史记录管理器，支持搜索、过滤和续播功能。

**配置**：`script-opts/simplehistory.conf`
```ini
auto_run=yes                       # 自动运行
osd_messages=yes                   # 显示 OSD 消息
incognito_mode=no                  # 隐身模式（不记录历史）
incognito_indicator=[隐身]         # 隐身模式指示器
max_history=500                    # 最大历史记录数
auto_clean=yes                     # 自动清理过期记录
resume_prompt=yes                  # 显示续播提示
resume_timeout=10                  # 续播提示超时（秒）
showamount=15                      # 列表最大显示行数
sort_mode=last_watched_desc        # 排序模式
filter_mode=none                   # 过滤模式：none/date/type
```

**使用场景**：
- 找回上次观看位置
- 查找历史记录
- 隐身观看（不记录）

**进阶用法**：
- `incognito_mode=yes`：永久启用隐身模式
- `max_history=100`：限制历史记录数量
- `auto_clean=yes`：自动清理超过数量的记录

**快捷键**：
- `H` - 打开历史记录
- `UP/DOWN` - 选择历史记录
- `ENTER` - 播放选中视频（跳转到上次位置）
- `Del` - 删除选中历史
- `Ctrl + R` - 续播最后一个
- `Alt + R` - 加载最后一个（不续播）
- `Ctrl + H` - 清空所有历史
- `Ctrl + I` - 切换隐身模式
- `Esc` - 关闭列表

---

### history-bookmark.lua

**功能**：目录级别的播放历史和书签功能，支持跨文件续播。

**配置**：`script-opts/history_bookmark.conf`
```ini
enabled=true                       # 启用
language=chs                       # eng/chs
timeout=15                         # 续播提示超时（秒）
save_period=30                     # 保存间隔（秒）
history_dir=/:dir%mpvconf%/historybookmarks
bookmark_ext=.mpv.history          # 书签扩展名
hash=true                          # 使用哈希命名
use_playlist=true                  # 使用播放列表
whitelist=3gp,amv,avi...           # 白名单扩展名
excluded_dir=[]                    # 排除目录
```

**使用场景**：
- 追剧记录观看进度
- 跨文件续播（同目录自动应用）

**依赖**：mp.input（可选）

---

### mpv-animated.lua

**功能**：使用 ffmpeg 创建视频片段为 GIF 或 WebP 动画。

**配置**：`script-opts/mpv_animated.conf`
```ini
type=gif                           # gif/webp
ffmpeg_path=ffmpeg                 # ffmpeg 路径
dir=~~desktop/                     # 输出目录
rez=600                            # 分辨率
fps=15                             # 帧率
lossless=0                         # 无损压缩（WebP）
quality=90                         # 质量
loop=0                             # 循环次数（0=无限）
```

**使用场景**：
- 制作 GIF 动图
- 分享精彩片段

**快捷键**：
- `W` - 设置起始帧
- `Shift + W` - 设置结束帧
- `Ctrl + W` - 创建动画（不带字幕）
- `Ctrl + Shift + W` - 创建动画（带字幕）

**依赖**：ffmpeg

---

### slicing_copy.lua

**功能**：快速剪切视频片段，使用 ffmpeg 流复制保持质量。

**配置**：`script-opts/slicing_copy.conf`
```ini
ffmpeg_path=ffmpeg                 # ffmpeg 路径
target_dir=~~/cutfragments         # 输出目录
overwrite=false                    # 覆盖已存在文件
vcodec=copy                        # 视频编码（copy=无重编码）
acodec=copy                        # 音频编码
debug=false                        # 调试模式
```

**使用场景**：
- 快速截取视频片段
- 无需重编码保持质量

**快捷键**：
- `C` - 标记剪切片段开始
- `A` - 切换音频捕获
- `Shift + C` - 清除标记

**依赖**：ffmpeg

---

### smartcopypaste_II.lua

**功能**：智能复制粘贴系统，支持带时间戳的视频链接复制和粘贴。

**配置**：`script-opts/smartcopypaste_II.conf`
（配置项众多，详见脚本头部注释）

**使用场景**：
- 分享带时间戳的视频链接
- 快速定位到特定时间点
- 剪贴板历史记录

**快捷键**：
- `Ctrl + C` - 复制
- `Ctrl + V` - 粘贴
- `Ctrl + Alt + C` - 特殊复制
- `Ctrl + Alt + V` - 特殊粘贴

**依赖**：Windows: PowerShell / Linux: xclip / Mac: pbcopy/pbpaste

---

### thumbfast.lua

**功能**：高性能缩略图生成器，为第三方 UI 提供缩略图支持。

**配置**：`script-opts/thumbfast.conf`
```ini
socket=                            # Socket 路径（自动）
thumbnail=                         # 缩略图路径（自动）
max_height=200                     # 最大高度
max_width=200                      # 最大宽度
overlay_id=42                      # 覆盖层 ID
spawn_first=false                  # 文件加载时预生成
quit_after_inactivity=0            # 无活动后退出（秒）
network=false                      # 启用网络播放
audio=false                        # 启用音频播放
hwdec=false                        # 启用硬件解码
direct_io=false                    # 使用 Direct I/O（Windows）
mpv_path=mpv                       # mpv 可执行路径
blacklist_ext=bdmv,ifo             # 黑名单扩展名
```

**使用场景**：
- 为 uosc 等 UI 提供进度条缩略图预览
- 拖动时显示对应画面缩略图

**依赖**：FFI（Direct I/O 模式）、thumbfast 外部程序

---

### uosc/

**功能**：现代化 OSD 用户界面，提供时间线、控制按钮、音量控制、顶部栏等完整的播放器界面。

**配置**：`script-opts/uosc.conf`
```ini
# 时间线配置
timeline_style=bar                 # line/bar
timeline_size=30                   # 进度条大小（像素）
timeline_border=1                  # 边框大小
timeline_step=5                    # 拖动步进（秒）
timeline_thumbnail=yes             # 启用缩略图预览（需要 thumbfast）
timeline_cache=yes                 # 显示网络缓存指标
timeline_heatmap=overlay           # YouTube 热度图：overlay/above/no

# 控制按钮
controls=menu,open-file,gap,space,prev,playlist,next,gap,fullscreen
controls_size=32                   # 按钮大小
controls_margin=8                  # 边距
controls_spacing=2                 # 间距

# 音量控制
volume=right                       # none/left/right
volume_size=40                     # 音量条大小

# 顶部栏
top_bar=no-border                  # never/always/no-border
top_bar_size=40                    # 顶部栏大小
top_bar_title=yes                  # 显示标题

# 样式
font=Noto Sans Mono CJK SC         # 字体
scale=1                            # UI 缩放比例
scale_fullscreen=1.3               # 全屏缩放
color=foreground=FFFBFE,background=1C1B1F  # 颜色
opacity=menu=0.9,submenu=0.7       # 透明度
animation_duration=100             # 动画时长（毫秒）

# 行为
autoload=no                        # 自动加载下一个文件
shuffle=no                         # 随机播放
pause_indicator=manual             # 暂停指示器样式
```

**使用场景**：
- 替代默认简陋 OSD
- 现代化播放器界面
- 精确控制播放进度

**界面元素**：
- 底部进度条（带缩略图预览、缓冲指示）
- 顶部标题栏（显示视频信息）
- 右侧音量控制
- 底部控制按钮（播放/暂停、字幕、音轨、菜单等）
- 菜单系统（章节、轨道、播放列表、收藏等）

**进阶配置**：
- `timeline_heatmap=overlay`：YouTube 视频显示观看热度图
- `controls` 自定义按钮布局：使用 `gap` 留空、`space` 填补空间右对齐
- `color` 自定义配色：前景色、背景色、强调色

---

### uosc_danmaku/

**功能**：弹幕系统，支持多 API 源、自动加载、简繁转换。

**配置**：`script-opts/uosc_danmaku.conf`
```ini
# API 配置
api_servers=https://api.dandanplay.net  # API 服务器（多个逗号分隔）

# 自动加载
auto_load=yes                      # 自动加载弹幕
autoload_for_url=yes               # 网络视频自动加载
autoload_local_danmaku=yes         # 本地弹幕自动加载

# 显示配置
opacity=0.7                        # 弹幕透明度
chConvert=0                        # 简繁转换：0-不转换 1-转简体 2-转繁体
merge_tolerance=1                  # 合并重复弹幕（秒）
```

**使用场景**：
- 观看动画/剧集时显示弹幕
- 增强互动体验
- 多弹幕源切换

**进阶用法**：
- `api_servers` 配置多个 API 源，优先级从高到低排列
- `chConvert=1` 自动转换为简体中文
- `merge_tolerance=1` 合并 1 秒内的重复弹幕

**快捷键**：
- `J` - 弹幕开关
- `Ctrl + D` - 弹幕搜索
- `Ctrl + C` - 切换弹幕来源

---

### hdr-mode.lua

**功能**：根据视频内容自动切换 Windows 显示器的 HDR/SDR 模式（仅 Windows 10+）。

**配置**：`script-opts/hdr_mode.conf`
```ini
hdr_mode=switch                    # noth（无）/pass（透传）/switch（自动切换）
fullscreen_only=false              # 仅全屏/最大化时切换
target_peak=203                    # 目标峰值亮度（尼特）
target_contrast=auto               # 目标对比度
```

**使用场景**：
- 自动切换 HDR 显示器模式
- HDR 内容正确显示

**依赖**：Windows 10+、gpu-next 输出、mpv-display-plugin（可选）

---

### persist_properties.lua

**功能**：持久化 mpv 属性设置，重启后保持。

**配置**：`script-opts/persist_properties.conf`
```ini
properties=volume,sub-scale        # 持久化属性列表
properties_path=persistent_config.json  # 配置文件路径
```

**使用场景**：
- 保存音量设置
- 保存字幕大小
- 保存其他 mpv 属性

---

### trackselect.lua

**功能**：智能轨道选择，自动选择非配音的音频和字幕轨道。

**配置**：`script-opts/trackselect.conf`
```ini
enabled=true                       # 启用
hook=true                          # 使用钩子
fingerprint=false                  # 使用指纹
force=false                        # 强制覆盖用户选择
smart_keep=false                   # 智能保持
preferred_audio_lang=jpn/japanese  # 首选音频语言
preferred_sub_lang=eng             # 首选字幕语言
excluded_sub_words=sign            # 排除词汇
```

**使用场景**：
- 自动选择原声轨道
- 排除配音版本
- 排除歌词字幕

---

### open_dialog.lua

**功能**：调用系统对话框选择文件/文件夹/剪贴板内容。

**配置**：`script-opts/open_dialog.conf`
```ini
video_types=...                    # 视频类型
audio_types=...                    # 音频类型
image_types=...                    # 图片类型
subtitle_types=...                 # 字幕类型
playlist_types=...                 # 播放列表类型
```

**使用场景**：
- 使用系统对话框选择文件
- 加载 ISO/蓝光/DVD

**快捷键**：
- `O` - 打开文件夹
- `Ctrl + O` - 打开文件

**依赖**：Windows: PowerShell

---

### simple-mpv-webui/

**功能**：浏览器远程控制界面，支持网络访问。

**配置**：`script-opts/webui.conf`

**使用场景**：
- 手机/平板远程控制 mpv
- 网络访问播放器

---

### mpv-torrserver.lua

**功能**：种子流媒体播放支持，直接播放 Torrent 内容。

**配置**：`script-opts/mpv_torrserver.conf`

**使用场景**：
- 直接播放种子文件
- 无需完整下载

---

### trakt-scrobble/

**功能**：Trakt.tv 观看记录同步，自动 scrobble。

**配置**：`script-opts/trakt_scrobble.conf`

**使用场景**：
- 同步观看记录到 Trakt.tv
- 追踪观看统计

---

### manager.lua

**功能**：脚本和配置文件管理器，支持从 Git 仓库自动更新。

**配置**：`manager.json`
```json
[
  {
    "git": "https://github.com/user/repo.git",
    "whitelist": "scripts/*.lua",
    "dest": "~~/scripts"
  }
]
```

**使用场景**：
- 从 Git 仓库管理脚本
- 自动更新配置

**依赖**：git

---

## 🔧 配置参考

### 配置文件位置
所有脚本配置文件位于 `~~/script-opts/` 目录（便携版为 `portable_config/script-opts/`）。

### 配置修改步骤
1. 用文本编辑器打开对应的 `.conf` 文件
2. 修改参数值
3. 保存后**立即生效**（部分需要重新加载视频）

### 核心配置文件速查

| 配置文件 | 对应脚本 | 推荐修改项 |
|----------|----------|------------|
| `uosc.conf` | uosc | 字体、颜色、进度条大小、按钮布局 |
| `uosc_danmaku.conf` | uosc_danmaku | API 服务器、自动加载、简繁转换 |
| `chapterskip.conf` | chapterskip | 跳过模式、时间窗口、手动标记 |
| `evafast.conf` | evafast | 跳转距离、速度上限、字幕限速 |
| `sub_assrt.conf` | sub-assrt | **API Token（必需）**、保存路径 |
| `autoload.conf` | autoload | 文件类型、子目录模式、同系列 |
| `simplehistory.conf` | simplehistory | 最大数量、隐身模式、续播提示 |
| `simplebookmark.conf` | simplebookmark | 分组设置、快速槽位、排序方式 |
| `playlistmanager.conf` | playlistmanager | 显示行数、排序方式、文件名替换 |

---

## 🎨 着色器推荐

### 动漫视频
```ini
# 基础超分
glsl-shaders="~~/shaders/Anime4K/Anime4K_Upscale_Denoise_x2.glsl"

# 高质量组合
glsl-shaders="~~/shaders/SSim/SSimSuperRes.glsl:~~/shaders/RAISR/ravu_r3.glsl"
```

### 实拍视频
```ini
# 锐化增强
glsl-shaders="~~/shaders/USM/unsharp_masking.glsl"

# 降噪处理
glsl-shaders="~~/shaders/nlmeans/nlmeans.glsl"
```

### 老视频修复
```ini
# 去交错 + 超分
glsl-shaders="~~/shaders/deint/deint_swa.glsl:~~/shaders/Anime4K/Anime4K_Restore_CNN_VL.glsl"
```

**更多着色器**：查看 `shaders/` 目录中的可用文件。

---

## 🔗 链接

- [5 分钟快速上手](快速开始.md) - 新手入门（场景教程）
- [项目主页](../README.md) - 安装与配置
- [mpv 官方文档](https://mpv.io/manual/master/)
- [uosc 文档](https://github.com/tomasklaen/uosc)
- [弹幕系统文档](https://github.com/Loukyuu1120/uosc_danmaku)

---

**返回**：[🏠 项目主页](../README.md) | [🚀 快速开始](快速开始.md)
