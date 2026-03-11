# 📚 MPV 播放器 - 完整脚本功能文档

> 详细功能说明 | 配置参考 | 使用指南
>
> 🚀 **新手入门**：[5 分钟快速上手](快速开始.md) | 🏠 **返回主页**：[../README.md](../README.md)

---

## 📖 文档导航

| 文档 | 用途 | 适合人群 |
|------|------|----------|
| [5 分钟快速上手](快速开始.md) | 基础操作、高频场景、快捷键 | 新手用户 |
| [完整脚本索引](#-完整脚本索引) | 所有脚本功能速查 | 所有用户 |
| [核心功能详解](#-核心功能详解) | 常用脚本详细说明 | 进阶用户 |
| [配置参考](#-配置参考) | 配置文件说明 | 所有用户 |

---

## 📋 完整脚本索引

### 🎬 播放控制（12 个）

| 脚本 | 功能 | 配置文件 | 详细链接 |
|------|------|----------|----------|
| `autoload.lua` | 自动加载同目录文件到播放列表 | `autoload.conf` | [详解](#autoloadlua) |
| `auto-save-state.lua` | 定期自动保存播放状态 | `auto_save_state.conf` | [详解](#auto-save-statelua) |
| `blacklist-extensions.lua` | 按扩展名黑名单过滤播放列表 | `blacklist_extensions.conf` | [详解](#blacklist-extensionslua) |
| `chapterskip.lua` | 智能跳过片头片尾 | `chapterskip.conf` | [详解](#chapterskiplua) |
| `chapter-make-read.lua` | 读取并创建章节信息 | `chapter_make_read.conf` | [详解](#chapter-make-readlua) |
| `cycle-commands.lua` | 单键循环执行多个命令 | 无 | [详解](#cycle-commandslua) |
| `delete-current-file.lua` | 删除当前文件到回收站 | 无 | [详解](#delete-current-filelua) |
| `dynamic-crop.lua` | 自动检测并裁剪黑边 | `dynamic_crop.conf` | [详解](#dynamic-croplua) |
| `evafast.lua` | 智能快进（长按加速） | `evafast.conf` | [详解](#evafastlua) |
| `fix-avsync.lua` | 切换音频设备时修复音画同步 | 无 | [详解](#fix-avsynclua) |
| `inputevent.lua` | 增强输入（双击/长按识别） | `inputevent.conf` | [详解](#inputeventlua) |
| `undoredo.lua` | 播放进度撤销/重做 | 无 | [详解](#undoredolua) |

### 📝 字幕工具（7 个）

| 脚本 | 功能 | 配置文件 | 详细链接 |
|------|------|----------|----------|
| `sub-assrt.lua` | 射手网在线字幕下载 | `sub_assrt.conf` | [详解](#sub-assrtlua) |
| `sub-select.lua` | 根据音频自动选择匹配字幕 | `sub_select.conf` | [详解](#sub-selectlua) |
| `sub_export.lua` | 导出内封字幕为独立文件 | `sub_export.conf` | [详解](#sub_exportlua) |
| `sub-fastwhisper.lua` | AI 自动生成字幕 | `sub_fastwhisper.conf` | [详解](#sub-fastwhisperlua) |
| `sub-fonts-dir-auto.lua` | 自动查找 Fonts 字幕字体目录 | 无 | [详解](#sub-fonts-dir-autolua) |
| `autosubsync/` | 字幕自动同步 | `autosubsync/` | [详解](#autosubsync) |
| `sponsorblock_minimal.lua` | 跳过 YouTube/B 站赞助片段 | `sponsorblock_minimal.conf` | [详解](#sponsorblock_minimallua) |

### 📋 播放列表管理（5 个）

| 脚本 | 功能 | 配置文件 | 详细链接 |
|------|------|----------|----------|
| `playlistmanager.lua` | 可视化播放列表管理 | `playlistmanager.conf` | [详解](#playlistmanagerlua) |
| `quality-menu.lua` | YouTube 视频质量选择菜单 | `quality-menu.conf` | [详解](#quality-menulua) |
| `recentmenu.lua` | 最近播放记录菜单 | `recentmenu.conf` | [详解](#recentmenulua) |
| `file-browser/` | 文件浏览器界面 | `file_browser.conf` | [详解](#file-browser) |
| `dyn_menu.lua` | 动态菜单生成器 | `dyn_menu.conf` | [详解](#dyn_menulua) |

### 🔖 书签与历史（3 个）

| 脚本 | 功能 | 配置文件 | 详细链接 |
|------|------|----------|----------|
| `simplebookmark.lua` | 高级书签管理（分组/槽位） | `simplebookmark.conf` | [详解](#simplebookmarklua) |
| `simplehistory.lua` | 播放历史记录管理 | `simplehistory.conf` | [详解](#simplehistorylua) |
| `history-bookmark.lua` | 目录级别的历史和书签 | `history_bookmark.conf` | [详解](#history-bookmarklua) |

### 🎥 视频处理（4 个）

| 脚本 | 功能 | 配置文件 | 详细链接 |
|------|------|----------|----------|
| `mpv-animated.lua` | 导出视频片段为 GIF/WebP | `mpv_animated.conf` | [详解](#mpv-animatedlua) |
| `slicing_copy.lua` | 快速剪切视频片段 | `slicing_copy.conf` | [详解](#slicing_copylua) |
| `smartcopypaste_II.lua` | 智能复制粘贴（带时间戳） | `smartcopypaste_II.conf` | [详解](#smartcopypaste_iilua) |
| `thumbfast.lua` | 缩略图生成器 | `thumbfast.conf` | [详解](#thumbfastlua) |

### 🎨 界面增强（6 个）

| 脚本 | 功能 | 配置文件 | 详细链接 |
|------|------|----------|----------|
| `uosc/` | 现代化 OSD 用户界面 | `uosc.conf` | [详解](#uosc) |
| `uosc_danmaku/` | 弹幕系统（多源 API） | `uosc_danmaku.conf` | [详解](#uosc_danmaku) |
| `hdr-mode.lua` | Windows HDR 自动切换 | `hdr_mode.conf` | [详解](#hdr-modelua) |
| `persist_properties.lua` | 持久化 mpv 属性设置 | `persist_properties.conf` | [详解](#persist_propertieslua) |
| `trackselect.lua` | 智能轨道选择 | `trackselect.conf` | [详解](#trackselectlua) |
| `open_dialog.lua` | 系统文件选择对话框 | `open_dialog.conf` | [详解](#open_dialoglua) |

### 🌐 网络功能（4 个）

| 脚本 | 功能 | 配置文件 | 详细链接 |
|------|------|----------|----------|
| `simple-mpv-webui/` | 浏览器远程控制界面 | `webui.conf` | [详解](#simple-mpv-webui) |
| `mpv-torrserver.lua` | 种子流媒体播放 | `mpv_torrserver.conf` | [详解](#mpv-torrserverlua) |
| `trakt-scrobble/` | Trakt.tv 观看记录同步 | `trakt_scrobble.conf` | [详解](#trakt-scrobble) |
| `manager.lua` | 脚本管理器（Git 更新） | `manager.json` | [详解](#managerlua) |

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
same_type=yes                     # 只加载同类型
directory_mode=ignore             # 子目录模式：ignore/lazy/recursive
ignore_hidden=yes                 # 忽略隐藏文件
```

**使用场景**：追番自动连播、音乐专辑整张播放、图片幻灯片。

**[⬆ 返回索引](#-完整脚本索引)**

---

### auto-save-state.lua
**功能**：定期自动保存播放状态（watch-later），防止意外退出丢失进度。

**配置**：`script-opts/auto_save_state.conf`
```ini
save_interval=60                  # 保存间隔（秒）
percent_pos=99                    # 视为完成的进度
```

**使用场景**：观看长视频定期保存、暂停时自动保存。

**[⬆ 返回索引](#-完整脚本索引)**

---

### blacklist-extensions.lua
**功能**：根据扩展名黑名单或白名单过滤播放列表中的文件。

**配置**：`script-opts/blacklist_extensions.conf`
```ini
blacklist=                        # 黑名单扩展名
whitelist=                        # 白名单扩展名
remove_files_without_extension=false
oneshot=true
```

**使用场景**：过滤不需要格式、仅保留特定类型文件。

**[⬆ 返回索引](#-完整脚本索引)**

---

### chapterskip.lua
**功能**：智能跳过片头片尾，支持章节标题、位置推断和静音检测。

**配置**：`script-opts/chapterskip.conf`
```ini
mode=auto                          # none/auto/manual
language=chs                       # eng/chs
skip=opening;ending                # 跳过类别
enable_history_position_inference=yes
timeout=20                         # 倒计时确认
```

**快捷键**：
- `Shift + S` - 切换跳过模式
- `Shift + M` - 手动标记跳过片段
- `F3` - 跳转到下一个静音点

**使用场景**：追番跳过 OP/ED、跳过制作人员名单、跳过静音片段。

**[⬆ 返回索引](#-完整脚本索引)**

---

### chapter-make-read.lua
**功能**：读取并创建视频章节信息。

**配置**：`script-opts/chapter_make_read.conf`

**使用场景**：为无章节视频添加章节标记。

**[⬆ 返回索引](#-完整脚本索引)**

---

### cycle-commands.lua
**功能**：允许通过单个键绑定循环执行多个命令。

**配置**：无

**input.conf 示例**：
```ini
F1  script-message cycle-commands "show-text one" "show-text two" "show-text three"
```

**使用场景**：单键切换多个配置、循环显示信息。

**[⬆ 返回索引](#-完整脚本索引)**

---

### delete-current-file.lua
**功能**：删除当前播放的文件并移至回收站，同时从播放列表移除。

**配置**：无

**input.conf 示例**：
```ini
KP0  script-message-to delete_current_file delete-file
```

**使用场景**：移除不需要的视频文件。

**[⬆ 返回索引](#-完整脚本索引)**

---

### dynamic-crop.lua
**功能**：使用 ffmpeg cropdetect 滤镜自动检测并应用视频裁剪。

**配置**：`script-opts/dynamic_crop.conf`
```ini
mode=4                             # 0-禁用 1-按需 2-单次 3-动态手动 4-动态自动
detect_limit=26                    # 检测阈值
ratios=2.76 2.55 24/9 2.4 2.35 2 16/9 4/3
```

**快捷键**：`C`（Shift+C）- 切换裁剪

**使用场景**：自动裁剪视频黑边、保持正确宽高比。

**[⬆ 返回索引](#-完整脚本索引)**

---

### evafast.lua
**功能**：智能快进脚本，轻按跳转，长按加速播放，支持字幕检测自动限速。

**配置**：`script-opts/evafast.conf`
```ini
seek_distance=5                    # 跳转距离（秒）
speed_increase=0.1                 # 速度增加量
speed_cap=3                        # 最高速度
subs_speed_cap=1.5                 # 字幕时限速
show_speed=yes                     # 显示速度 OSD
```

**使用**：
- 轻按 `→`：快进 5 秒
- 长按 `→`：加速播放（最高 3 倍）
- 字幕出现：自动限速到 1.5 倍

**使用场景**：跳过冗长片段、加速观看节奏缓慢部分。

**[⬆ 返回索引](#-完整脚本索引)**

---

### fix-avsync.lua
**功能**：切换音频输出设备时自动修复音画同步问题。

**配置**：无

**使用场景**：切换音频设备后音画不同步时自动修复。

**[⬆ 返回索引](#-完整脚本索引)**

---

### inputevent.lua
**功能**：增强型输入事件处理，支持单击、双击、三击、长按等复杂手势。

**配置**：`script-opts/inputevent.conf`
```ini
enable_external_config=false
prefix=event
```

**input.conf 示例**：
```ini
MBTN_LEFT  #event:click : cycle fullscreen
MBTN_LEFT  #event:double_click : cycle pause
```

**使用场景**：鼠标多击手势、长按操作。

**[⬆ 返回索引](#-完整脚本索引)**

---

### undoredo.lua
**功能**：支持播放进度的撤销（Undo）和重做（Redo）。

**配置**：无

**快捷键**：
- `Ctrl + Z` - 撤销
- `Ctrl + Y` - 重做

**使用场景**：误操作后恢复之前的播放位置。

**[⬆ 返回索引](#-完整脚本索引)**

---

### sub-assrt.lua
**功能**：从伪射手网（assrt.net）搜索并下载字幕。

**配置**：`script-opts/sub_assrt.conf`
```ini
api_token=你的 token                 # 必需
use_https=true
max_results=10
auto_download_best=no
sub_format=ass
save_path=source
```

**快捷键**：
- `S` - 搜索字幕
- `Ctrl + S` - 手动输入关键词
- `Alt + S` - 重新搜索

**首次使用**：
1. 访问 https://assrt.net 注册账号
2. 进入个人中心获取 API Token
3. 填入配置文件

**使用场景**：外语视频中文字幕、寻找精校字幕。

**[⬆ 返回索引](#-完整脚本索引)**

---

### sub-select.lua
**功能**：基于音频轨道和字幕名称/语言的高级字幕选择。

**配置**：`script-opts/sub_select.conf`
```ini
force_enable=false
hook=true
preferred_audio_lang=jpn/japanese
preferred_sub_lang=eng
excluded_sub_words=sign
```

**使用场景**：自动匹配原声字幕、排除歌词字幕。

**[⬆ 返回索引](#-完整脚本索引)**

---

### sub_export.lua
**功能**：导出当前选中的内封字幕为独立文件（srt/ass/sup）。

**配置**：`script-opts/sub_export.conf`
```ini
ffmpeg_path=ffmpeg
language=eng
```

**快捷键**：`X` - 导出选中字幕

**使用场景**：提取 MKV 内封字幕、格式转换。

**[⬆ 返回索引](#-完整脚本索引)**

---

### sub-fastwhisper.lua
**功能**：使用 faster-whisper 自动生成 AI 字幕，支持实时翻译。

**配置**：`script-opts/sub_fastwhisper.conf`
```ini
fast_whisper_path=faster-whisper
model=base                         # base/small/medium/large/turbo
device=cpu                         # cpu/cuda
language=                          # 留空自动检测
translate=Chinese
```

**快捷键**：
- `W` - 生成字幕
- `T` - 翻译字幕

**使用场景**：无字幕视频生成字幕、实时翻译。

**[⬆ 返回索引](#-完整脚本索引)**

---

### sub-fonts-dir-auto.lua
**功能**：自动查找视频目录下的 `Fonts` 文件夹并设置为字幕字体目录。

**配置**：无

**使用场景**：动漫视频自带字幕字体自动加载。

**[⬆ 返回索引](#-完整脚本索引)**

---

### autosubsync/
**功能**：字幕自动同步，调整字幕时间轴匹配视频版本。

**配置**：`autosubsync/` 目录配置

**使用场景**：字幕与视频不同步时自动校准。

**[⬆ 返回索引](#-完整脚本索引)**

---

### sponsorblock_minimal.lua
**功能**：使用 SponsorBlock API 跳过 YouTube 和 Bilibili 视频中的赞助片段。

**配置**：`script-opts/sponsorblock_minimal.conf`
```ini
youtube_sponsor_server=https://sponsor.ajay.app/api/skipSegments
bilibili_sponsor_server=https://bsbsb.top/api/skipSegments
categories="sponsor"
```

**使用场景**：跳过 YouTube/B 站视频中的广告赞助片段。

**[⬆ 返回索引](#-完整脚本索引)**

---

### playlistmanager.lua
**功能**：功能丰富的播放列表管理器，支持可视化浏览、排序、搜索和编辑。

**配置**：`script-opts/playlistmanager.conf`
```ini
dynamic_binds=yes
key_showplaylist=SHIFT+ENTER
showamount=13
default_sort=name-asc
filename_replace=[{"pattern":"_","replace":" "}]
```

**快捷键**：
- `Shift + Enter` - 打开播放列表
- `S` - 排序
- `R` - 随机打乱
- `P` - 保存播放列表
- `L` - 加载文件
- `Del` - 移除文件

**使用场景**：管理大型播放列表、快速查找文件、批量操作。

**[⬆ 返回索引](#-完整脚本索引)**

---

### quality-menu.lua
**功能**：YouTube 视频质量选择菜单，支持视频和音频轨道选择。

**配置**：`script-opts/quality-menu.conf`
```ini
fetch_formats=true
start_with_menu=false
columns_video=...
sort_video=...
```

**快捷键**：
- `F` - 视频质量菜单
- `Alt + F` - 音频质量菜单

**使用场景**：选择 YouTube 视频分辨率、音频质量。

**[⬆ 返回索引](#-完整脚本索引)**

---

### recentmenu.lua
**功能**：最近播放记录菜单，支持快速访问历史记录。

**配置**：`script-opts/recentmenu.conf`
```ini
enabled=true
path=~~/recent.json
length=10
ignore_same_series=true
```

**快捷键**：
- `Ctrl + R` - 打开最近记录
- `Ctrl + T` - 播放最后一个

**使用场景**：快速访问最近观看的视频。

**[⬆ 返回索引](#-完整脚本索引)**

---

### file-browser/
**功能**：文件浏览器界面，支持浏览本地和网络文件。

**配置**：`script-opts/file_browser.conf`

**使用场景**：在 mpv 内浏览文件系统、网络共享。

**[⬆ 返回索引](#-完整脚本索引)**

---

### dyn_menu.lua
**功能**：动态菜单生成器，支持从 input.conf 创建上下文菜单。

**配置**：`script-opts/dyn_menu.conf`
```ini
use_mpv_impl=true
uosc_syntax=false
max_title_length=80
```

**input.conf 示例**：
```ini
F10  ignore  #menu: Tracks #@tracks
```

**使用场景**：创建自定义菜单、轨道选择菜单。

**[⬆ 返回索引](#-完整脚本索引)**

---

### simplebookmark.lua
**功能**：高级书签管理系统，支持分组、快捷键、搜索和过滤。

**配置**：`script-opts/simplebookmark.conf`
```ini
auto_run=yes
osd_messages=yes
slot_1=Ctrl+1
default_group=默认分组
group_separator=/
showamount=15
```

**快捷键**：
- `Ctrl + B` - 保存书签
- `B` - 打开书签列表
- `Ctrl + 1~9` - 快速槽位
- `M` - 标记章节

**使用场景**：标记教程重点、保存精彩片段、管理观看进度。

**[⬆ 返回索引](#-完整脚本索引)**

---

### simplehistory.lua
**功能**：播放历史记录管理器，支持搜索、过滤和续播功能。

**配置**：`script-opts/simplehistory.conf`
```ini
auto_run=yes
incognito_mode=no
max_history=500
resume_prompt=yes
showamount=15
```

**快捷键**：
- `H` - 打开历史记录
- `Ctrl + R` - 续播最后一个
- `Ctrl + I` - 切换隐身模式
- `Ctrl + H` - 清空历史

**使用场景**：找回上次观看位置、查找历史记录、隐身观看。

**[⬆ 返回索引](#-完整脚本索引)**

---

### history-bookmark.lua
**功能**：目录级别的播放历史和书签功能，支持跨文件续播。

**配置**：`script-opts/history_bookmark.conf`
```ini
enabled=true
language=chs
timeout=15
history_dir=/:dir%mpvconf%/historybookmarks
```

**使用场景**：追剧记录观看进度、跨文件续播。

**[⬆ 返回索引](#-完整脚本索引)**

---

### mpv-animated.lua
**功能**：使用 ffmpeg 创建视频片段为 GIF 或 WebP 动画。

**配置**：`script-opts/mpv_animated.conf`
```ini
type=gif
ffmpeg_path=ffmpeg
dir=~~desktop/
rez=600
fps=15
quality=90
```

**快捷键**：
- `W` - 设置起始帧
- `Shift + W` - 设置结束帧
- `Ctrl + W` - 创建动画（不带字幕）
- `Ctrl + Shift + W` - 创建动画（带字幕）

**使用场景**：制作 GIF 动图、分享精彩片段。

**[⬆ 返回索引](#-完整脚本索引)**

---

### slicing_copy.lua
**功能**：快速剪切视频片段，使用 ffmpeg 流复制保持质量。

**配置**：`script-opts/slicing_copy.conf`
```ini
ffmpeg_path=ffmpeg
target_dir=~~/cutfragments
vcodec=copy
acodec=copy
```

**快捷键**：
- `C` - 标记剪切片段
- `A` - 切换音频捕获
- `Shift + C` - 清除标记

**使用场景**：快速截取视频片段、无需重编码。

**[⬆ 返回索引](#-完整脚本索引)**

---

### smartcopypaste_II.lua
**功能**：智能复制粘贴系统，支持带时间戳的视频链接复制和粘贴。

**配置**：`script-opts/smartcopypaste_II.conf`

**快捷键**：
- `Ctrl + C` - 复制
- `Ctrl + V` - 粘贴
- `Ctrl + Alt + C` - 特殊复制
- `Ctrl + Alt + V` - 特殊粘贴

**使用场景**：分享带时间戳的视频链接、快速定位。

**[⬆ 返回索引](#-完整脚本索引)**

---

### thumbfast.lua
**功能**：高性能缩略图生成器，为第三方 UI 提供缩略图支持。

**配置**：`script-opts/thumbfast.conf`
```ini
max_height=200
max_width=200
spawn_first=false
network=false
hwdec=false
```

**使用场景**：为 uosc 等 UI 提供进度条缩略图预览。

**依赖**：thumbfast 外部程序

**[⬆ 返回索引](#-完整脚本索引)**

---

### uosc/
**功能**：现代化 OSD 用户界面，提供时间线、控制按钮、音量控制、顶部栏等。

**配置**：`script-opts/uosc.conf`
```ini
timeline_style=bar
timeline_size=30
controls=menu,open-file,gap,space,prev,playlist,next,gap,fullscreen
controls_size=32
volume=right
top_bar=no-border
font=Noto Sans Mono CJK SC
color=foreground=FFFBFE,background=1C1B1F
opacity=menu=0.9,submenu=0.7
animation_duration=100
```

**界面元素**：
- 底部进度条（带缩略图预览）
- 顶部标题栏
- 右侧音量控制
- 底部控制按钮
- 菜单系统

**使用场景**：替代默认简陋 OSD、现代化播放器界面。

**[⬆ 返回索引](#-完整脚本索引)**

---

### uosc_danmaku/
**功能**：弹幕系统，支持多 API 源、自动加载、简繁转换。

**配置**：`script-opts/uosc_danmaku.conf`
```ini
api_servers=https://api.dandanplay.net
auto_load=yes
opacity=0.7
chConvert=0                    # 0-不转换 1-转简体 2-转繁体
merge_tolerance=1
```

**快捷键**：
- `J` - 弹幕开关
- `Ctrl + D` - 弹幕搜索
- `Ctrl + C` - 切换弹幕来源

**使用场景**：观看动画/剧集时显示弹幕、增强互动体验。

**[⬆ 返回索引](#-完整脚本索引)**

---

### hdr-mode.lua
**功能**：根据视频内容自动切换 Windows 显示器的 HDR/SDR 模式（仅 Windows 10+）。

**配置**：`script-opts/hdr_mode.conf`
```ini
hdr_mode=switch                  # noth/pass/switch
fullscreen_only=false
target_peak=203
```

**使用场景**：自动切换 HDR 显示器模式、HDR 内容正确显示。

**依赖**：Windows 10+、gpu-next 输出

**[⬆ 返回索引](#-完整脚本索引)**

---

### persist_properties.lua
**功能**：持久化 mpv 属性设置，重启后保持。

**配置**：`script-opts/persist_properties.conf`
```ini
properties=volume,sub-scale
properties_path=persistent_config.json
```

**使用场景**：保存音量、字幕大小等设置，重启后保持。

**[⬆ 返回索引](#-完整脚本索引)**

---

### trackselect.lua
**功能**：智能轨道选择，自动选择非配音的音频和字幕轨道。

**配置**：`script-opts/trackselect.conf`
```ini
enabled=true
hook=true
preferred_audio_lang=jpn/japanese
preferred_sub_lang=eng
excluded_sub_words=sign
```

**使用场景**：自动选择原声轨道、排除配音版本。

**[⬆ 返回索引](#-完整脚本索引)**

---

### open_dialog.lua
**功能**：调用系统对话框选择文件/文件夹/剪贴板内容。

**配置**：`script-opts/open_dialog.conf`
```ini
video_types=...
audio_types=...
image_types=...
```

**快捷键**：
- `O` - 打开文件夹
- `Ctrl + O` - 打开文件

**使用场景**：使用系统对话框选择文件、加载 ISO/蓝光。

**[⬆ 返回索引](#-完整脚本索引)**

---

### simple-mpv-webui/
**功能**：浏览器远程控制界面，支持网络访问。

**配置**：`script-opts/webui.conf`

**使用场景**：手机/平板远程控制 mpv、网络访问播放器。

**[⬆ 返回索引](#-完整脚本索引)**

---

### mpv-torrserver.lua
**功能**：种子流媒体播放支持，直接播放 Torrent 内容。

**配置**：`script-opts/mpv_torrserver.conf`

**使用场景**：直接播放种子文件、无需完整下载。

**[⬆ 返回索引](#-完整脚本索引)**

---

### trakt-scrobble/
**功能**：Trakt.tv 观看记录同步，自动 scrobble。

**配置**：`script-opts/trakt_scrobble.conf`

**使用场景**：同步观看记录到 Trakt.tv、追踪观看统计。

**[⬆ 返回索引](#-完整脚本索引)**

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

**使用场景**：从 Git 仓库管理脚本、自动更新配置。

**依赖**：git

**[⬆ 返回索引](#-完整脚本索引)**

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
| `uosc.conf` | uosc | 字体、颜色、进度条大小 |
| `uosc_danmaku.conf` | uosc_danmaku | API 服务器、自动加载 |
| `chapterskip.conf` | chapterskip | 跳过模式、时间窗口 |
| `evafast.conf` | evafast | 跳转距离、速度上限 |
| `sub_assrt.conf` | sub-assrt | API Token（必需） |
| `autoload.conf` | autoload | 文件类型、子目录模式 |
| `simplehistory.conf` | simplehistory | 最大数量、隐身模式 |
| `simplebookmark.conf` | simplebookmark | 分组设置、快速槽位 |
| `playlistmanager.conf` | playlistmanager | 显示行数、排序方式 |

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

- [5 分钟快速上手](快速开始.md) - 新手入门
- [项目主页](../README.md) - 安装与配置
- [mpv 官方文档](https://mpv.io/manual/master/)
- [uosc 文档](https://github.com/tomasklaen/uosc)
- [弹幕系统](https://github.com/Loukyuu1120/uosc_danmaku)

---

**返回**：[🏠 项目主页](../README.md) | [🚀 快速开始](快速开始.md)
