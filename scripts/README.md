# MPV Scripts 脚本说明文档

本文档详细总结了 `scripts` 目录下的所有 Lua 脚本，包括功能说明、使用场景、配置位置、详细使用方法和常见问题。

## 配置说明

- **配置文件路径**：所有脚本的配置文件都位于 `~~/script-opts/` 目录
- **路径缩写**：`~~` 表示 mpv 配置目录（便携版为 `portable_config`）
- **生效方式**：修改配置文件后，大多数脚本立即生效，部分需要重新加载视频

## 目录

### 重点脚本（详细文档）
- [autoload.lua](#autoloadlua) - 自动加载目录文件
- [chapterskip.lua](#chapterskiplua) - 智能跳过片头片尾
- [evafast.lua](#evafastlua) - 智能快进功能
- [playlistmanager.lua](#playlistmanagerlua) - 播放列表管理
- [simplebookmark.lua](#simplebookmarklua) - 书签管理
- [simplehistory.lua](#simplehistorylua) - 历史记录
- [sub-assrt.lua](#sub-assrtlua) - 字幕下载
- [uosc](#uosc) - 现代化用户界面

### 其他脚本
- [播放控制](#播放控制)
- [字幕工具](#字幕工具)
- [播放列表管理](#播放列表管理-1)
- [书签与历史](#书签与历史 -1)
- [视频处理](#视频处理)
- [UI 增强](#ui-增强)
- [网络流媒体](#网络流媒体)

---

## 播放控制

### auto-save-state.lua

**功能说明**：定期自动保存播放状态（watch-later 配置），支持在暂停时保存，播放完成时自动删除状态。

**使用场景**：
- 观看长视频时定期保存进度，防止意外退出丢失进度
- 暂停时自动保存，随时可以继续观看
- 播放完成后自动清理状态文件

**配置位置**：
- 配置文件：`~~/script-opts/auto-save-state.conf`
- 生效方式：修改配置后立即生效

**配置示例**：
```ini
save_interval=60      # 保存间隔（秒）
percent_pos=99        # 视为完成的进度百分比（>99% 自动删除状态）
```

**使用方法**：
- 自动运行，无需手动操作
- 发送 `skip-delete-state` 脚本消息可临时跳过删除状态

**依赖项**：无

---

### autoload.lua

**功能说明**：自动加载当前文件所在目录中的其他媒体文件到播放列表，支持智能排序和文件类型过滤。

**使用场景**：
- 当你打开一集动画时，自动加载整个季度的所有集数到播放列表
- 当你打开音乐专辑中的一个文件时，自动加载整张专辑
- 当你查看图片文件夹时，自动加载所有图片并支持幻灯片播放
- 追番时自动将整季动画加入播放列表，无需手动逐个打开

**配置位置**：
- 配置文件：`~~/script-opts/autoload.conf`
- 首次使用：创建配置文件，复制下方配置示例
- 生效方式：修改后重新打开视频或重启 mpv 生效

**配置示例**：
```ini
# autoload.conf 完整配置示例
disabled=no                       # 是否禁用脚本
images=yes                        # 加载图片文件
videos=yes                        # 加载视频文件
audio=yes                         # 加载音频文件
additional_image_exts=webp,avif   # 额外图片扩展名（逗号分隔）
additional_video_exts=webm,mkv    # 额外视频扩展名
additional_audio_exts=flac,ape    # 额外音频扩展名
ignore_hidden=yes                 # 忽略隐藏文件（以 . 开头）
same_type=no                      # 只加载与当前文件同类型的文件
same_series=no                    # 只加载同系列文件（如 S01E01, S01E02）
directory_mode=ignore             # 目录模式：ignore(忽略)/lazy(仅同级)/recursive(递归)
ignore_patterns=^~,^bak-,%.bak$   # 忽略模式（正则表达式）
```

**使用方法**：
1. **首次使用**：
   - 在 `~~/script-opts/` 目录创建 `autoload.conf` 文件
   - 复制上方配置示例，根据需要修改参数
   - 重新打开 mpv 或重新加载视频

2. **日常使用**：
   - 直接打开单个视频/音频/图片文件
   - 脚本自动扫描同级目录并加载匹配的文件
   - 播放列表窗口显示已加载的所有文件

**input.conf 绑定示例**：
```ini
# 示例 1：手动重新加载目录（当目录有新增文件时）
F5    script-binding autoload/reload

# 示例 2：临时禁用 autoload（不修改配置文件）
Ctrl+A    script-binding autoload/toggle

# 示例 3：递归加载子目录文件
Ctrl+F5    script-binding autoload/load-recursive
```

**常见问题**：
- **Q**: 为什么不自动加载文件？  
  **A**: 检查 `disabled` 是否为 `no`，确认文件扩展名在默认或额外扩展名列表中
- **Q**: 加载的文件顺序不对？  
  **A**: Windows 用户使用 Windows 原生排序，可设置 `directory_mode=lazy` 改善
- **Q**: 如何只加载特定类型的文件？  
  **A**: 设置 `same_type=yes` 或调整 `ignore_patterns` 过滤不需要的文件
- **Q**: 加载太多文件想限制范围？  
  **A**: 使用 `same_series=yes` 仅加载同系列文件，或设置 `directory_mode=lazy`

**依赖项**：
- Windows: FFI（用于原生排序，mpv 内置支持）

---

### blacklist-extensions.lua

**功能说明**：根据扩展名黑名单或白名单过滤播放列表中的文件。

**主要特性**：
- 支持黑名单模式（排除指定扩展名）
- 支持白名单模式（仅保留指定扩展名）
- 支持一键移除无扩展名文件
- 支持单次运行模式

**配置选项**：
```ini
blacklist=                    # 黑名单扩展名（逗号分隔）
whitelist=                    # 白名单扩展名（逗号分隔）
remove_files_without_extension=false  # 是否移除无扩展名文件
oneshot=true                  # 是否单次运行
```

**使用方法**：
- 自动监控播放列表变化
- 配置文件位置：`script-opts/blacklist-extensions.conf`

**依赖项**：无

---

### chapterskip.lua

**功能说明**：智能跳过片头片尾，支持基于章节标题、位置推断和静音检测的多种跳过模式。

**使用场景**：
- 追番时自动跳过每集的片头曲（OP）和片尾曲（ED），节省时间
- 看电影时跳过制作人员名单，快速进入下一部
- 观看教程视频时跳过固定的介绍片段和结尾广告
- 自动跳过视频中的静音片段，加快观看节奏

**配置位置**：
- 配置文件：`~~/script-opts/chapterskip.conf`
- 历史记录：`~~/chapterskip_history.json`（自动记录跳过位置）
- 生效方式：修改配置后立即生效，无需重启

**配置示例**：
```ini
# chapterskip.conf 完整配置示例
mode=manual                          # 模式：auto(自动跳过)/manual(提示确认)/none(禁用)
language=chs                         # 语言：eng(英文)/chs(中文)
timeout=20                           # 跳过确认倒计时（秒），超时自动跳过
skip=opening;ending                  # 跳过的类别：opening/ending/preview/credits/recap
enable_position_inference=yes        # 启用位置推断（视频前 200 秒/后 300 秒）
enable_history_position_inference=yes # 启用历史位置推断（跨集应用）
intro_time_window=200                # 片头时间窗口（秒），视频开头 200 秒内视为片头
outro_time_window=300                # 片尾时间窗口（秒），视频结尾 300 秒内视为片尾
silence_audio_level=-40              # 静音检测阈值（dB），低于此值视为静音
silence_duration=0.7                 # 静音持续时间（秒），持续 0.7 秒以上触发
ignore_silence_duration=1            # 忽略首次静音时长（秒），避免误判
min_skip_duration=0                  # 最小跳过时长（秒），小于此时长不跳过
max_skip_duration=120                # 最大跳过时长（秒），防止跳过正片
force_mute_on_skip=no                # 跳过时强制静音（避免跳过时音频突兀）
history_path=~~/chapterskip_history.json  # 历史文件路径
```

**使用方法**：
1. **首次使用**：
   - 在 `~~/script-opts/` 目录创建 `chapterskip.conf` 文件
   - 设置 `mode=auto` 自动跳过，或 `mode=manual` 手动确认
   - 根据需要调整跳过的类别和时间窗口

2. **日常使用**：
   - 打开视频后脚本自动检测片头片尾位置
   - `auto` 模式：到达跳过点自动跳转，OSD 显示提示
   - `manual` 模式：显示确认按钮，倒计时后自动跳过
   - 历史记录自动保存，同系列下一集自动应用

3. **手动标记**：
   - 遇到未识别的片头片尾，可手动标记跳过范围
   - 标记后自动保存到历史记录，后续集数自动应用

**input.conf 绑定示例**：
```ini
# 示例 1：跳转到下一个静音点（快速定位片尾）
F3    script-binding chapterskip/skip-to-silence

# 示例 2：切换跳过模式（auto/manual/none）
SHIFT+S    script-binding chapterskip/chapter-skip

# 示例 3：手动标记跳过片段（先按开始，再按结束）
SHIFT+M    script-binding chapterskip/toggle-markskip

# 示例 4：清除当前视频的跳过历史
Ctrl+SHIFT+S    script-binding chapterskip/clear-history
```

**常见问题**：
- **Q**: 为什么没有自动跳过？  
  **A**: 检查 `mode` 是否为 `auto`，确认 `skip` 包含要跳过的类别
- **Q**: 跳过位置不准确怎么办？  
  **A**: 使用 `SHIFT+M` 手动标记正确位置，脚本会记录并应用到后续集数
- **Q**: 如何跳过特定集数的片头片尾？  
  **A**: 历史记录按目录哈希存储，同目录文件自动共享历史
- **Q**: 静音检测太敏感/不敏感？  
  **A**: 调整 `silence_audio_level`（更负=不敏感）和 `silence_duration`
- **Q**: 如何禁用历史记录？  
  **A**: 设置 `enable_history_position_inference=no`

**依赖项**：
- ffmpeg silencedetect 滤镜（mpv 内置）

---

### cycle-commands.lua

**功能说明**：允许通过单个键绑定循环执行多个命令。

**主要特性**：
- 支持任意数量的命令循环
- 支持反向循环（!reverse 前缀）
- 支持标准 input.conf 命令语法
- 每个命令组独立存储循环状态
- 支持 OSD 显示当前命令

**配置选项**：无

**使用方法**：
```ini
# input.conf 示例
F1  script-message cycle-commands "show-text one" "show-text two" "show-text three"
F2  script-message cycle-commands/osd "apply-profile p1" "apply-profile p2"
```

**依赖项**：无

---

### delete-current-file.lua

**功能说明**：删除当前播放的文件并移至回收站，同时从播放列表移除。

**主要特性**：
- 支持直接删除或确认删除
- Windows 使用 PowerShell 移至回收站
- Linux 使用 trash-cli 工具
- 支持自定义确认按键和提示信息

**配置选项**：无

**使用方法**：
```ini
# input.conf 绑定
KP0  script-message-to delete_current_file delete-file
KP0  script-message-to delete_current_file delete-file KP1 "Press 1 to delete file"
```

**依赖项**：
- Windows: PowerShell（内置）
- Linux: trash-cli

---

### dynamic-crop.lua

**功能说明**：使用 ffmpeg cropdetect 滤镜自动检测并应用视频裁剪，支持动态调整和黑边检测。

**主要特性**：
- 支持 5 种工作模式（禁用/按需/单次/动态手动/动态自动）
- 自动检测视频黑边并应用裁剪
- 支持快速变化场景的稳定处理
- 支持宽高比匹配和偏移检测
- 支持窗口化模式下保持窗口大小
- 支持硬件解码检测

**配置选项**：
```ini
mode=4                              # 模式：0-禁用 1-按需 2-单次 3-动态手动 4-动态自动
start_delay=0                       # 开始延迟（秒）
prevent_change_timer=30             # 防止变化定时器（秒）
prevent_change_mode=0               # 防止变化模式：0-禁用 1-保持最大 2-保持最小 3-保持最新
fix_windowed_behavior=1             # 修复窗口化行为：0-不修复 1-不调整大小 2-保持宽度 3-保持高度
limit_timer=0.5                     # 限制变化定时器（秒）
fast_change_timer=0.2               # 快速变化定时器（秒）
ratio_timer=2                       # 宽高比定时器（秒）
offset_timer=20                     # 偏移定时器（秒）
fallback_timer=40                   # 回退定时器（秒）
linked_tolerance=2                  # 链接容差
ratios=2.76 2.55 24/9 2.4 2.35 2 16/9 4/3  # 支持的宽高比列表
read_ahead_mode=0                   # 预读模式：0-禁用 1-快速变化 2-宽高比
read_ahead_sync=0                   # 预读同步（帧）
crop_method=1                       # 裁剪方法：0-lavfi-crop 1-video-crop
detect_limit=26                     # 检测阈值（0-255）
detect_round=2                      # 检测舍入值
```

**使用方法**：
```ini
# input.conf 绑定
C    script-binding dynamic-crop/toggle_crop  # 切换裁剪（C=Shift+C）
```

**依赖项**：
- ffmpeg lavfi cropdetect 滤镜
- 需要 hwdec=no 或 hwdec=*-copy

---

### evafast.lua

**功能说明**：智能快进脚本，轻按跳转，长按加速播放，支持字幕检测自动限速。

**使用场景**：
- 看教程视频时快速跳过冗长的介绍部分
- 追剧时加速播放节奏缓慢的片段，不错过字幕内容
- 观看长视频时快速定位到特定时间点
- 看电影时快速跳过不感兴趣的片段，自动在对话时减速

**配置位置**：
- 配置文件：`~~/script-opts/evafast.conf`
- 生效方式：修改配置后立即生效，无需重启

**配置示例**：
```ini
# evafast.conf 完整配置示例
seek_distance=5           # 每次跳转距离（秒），设为 0 仅启用快进功能
speed_increase=0.1        # 长按时速度增加量（加法模式）
speed_decrease=0.1        # 释放时速度减少量
speed_interval=0.05       # 速度调整间隔（秒）
speed_cap=2               # 最大播放速度（倍速）
subs_speed_cap=1.6        # 字幕显示时最大速度（倍速）
multiply_modifier=false   # 使用乘法速度调整（true=1.1x,1.2x... / false=+0.1,+0.2）
show_speed=true           # 显示当前播放速度
show_seek=true            # 显示跳转动作提示
subs_lookahead=true       # 字幕预检测（提前检测下一字幕出现时间）
osd_symbol="⏩"           # OSD 显示符号（支持 Unicode 或 ASS 标签）
```

**使用方法**：
1. **首次使用**：
   - 在 `~~/script-opts/` 目录创建 `evafast.conf` 文件
   - 复制上方配置示例
   - 在 `input.conf` 中添加键绑定（见下方示例）

2. **日常使用**：
   - **轻按方向键**：向前/后跳转 `seek_distance` 秒
   - **长按方向键**：开始加速播放，速度逐渐增加
   - **释放方向键**：速度逐渐恢复到正常
   - **字幕出现时**：自动限速到 `subs_speed_cap`，避免错过字幕

3. **进阶技巧**：
   - 设置 `seek_distance=0` 禁用跳转，仅保留快进功能
   - 开启 `subs_lookahead=true` 提前检测字幕，更流畅的自动限速
   - 配合 uosc 使用，速度变化显示在时间线上

**input.conf 绑定示例**：
```ini
# 示例 1：基本快进/倒带（推荐绑定左右方向键）
RIGHT  evafast             # 快进（支持长按加速）
LEFT   evafast-rewind      # 倒带（支持长按加速）

# 示例 2：使用其他按键
D    evafast               # D 键快进
A    evafast-rewind        # A 键倒带

# 示例 3：鼠标侧键绑定
MBTN_FORWARD  evafast      # 鼠标前进键快进
MBTN_BACK     evafast-rewind  # 鼠标后退键倒带
```

**常见问题**：
- **Q**: 长按没有加速效果？  
  **A**: 确认键绑定使用的是 `evafast` 而不是 `seek` 命令
- **Q**: 速度变化太快/太慢？  
  **A**: 调整 `speed_interval`（更小=更快）和 `speed_increase`
- **Q**: 字幕出现时没有减速？  
  **A**: 确认 `subs_speed_cap` 小于 `speed_cap`，检查 `subs_lookahead=yes`
- **Q**: 想禁用跳转只保留快进？  
  **A**: 设置 `seek_distance=0`
- **Q**: 速度显示乱码？  
  **A**: 修改 `osd_symbol` 为简单字符或 Unicode 符号

**依赖项**：
- 无（可选：uosc 用于更美观的速度显示）

---

### fix-avsync.lua

**功能说明**：切换音频输出设备时自动修复音画同步问题。

**主要特性**：
- 检测音频设备切换
- 自动执行 frame-back-step 修复同步
- 仅在启用音频滤镜时触发

**配置选项**：无

**使用方法**：
- 自动运行，切换音频设备时触发

**依赖项**：无

---

### hdr-mode.lua

**功能说明**：根据视频内容自动切换 Windows 显示器的 HDR/SDR 模式（仅 Windows 10+）。

**主要特性**：
- 自动检测 HDR 内容并切换显示器模式
- 支持全屏/窗口模式过滤
- 自动配置 mpv 的 HDR 相关参数
- 支持退出时恢复 SDR 模式

**配置选项**：
```ini
hdr_mode=noth              # 模式：noth（无）/pass（透传）/switch（自动切换）
fullscreen_only=false      # 仅全屏/最大化时切换
target_peak=203            # 目标峰值亮度（尼特）
target_contrast=auto       # 目标对比度
```

**使用方法**：
- 自动运行，加载 HDR 视频时触发

**依赖项**：
- Windows 10+
- gpu-next 视频输出
- mpv-display-plugin（可选）

---

### inputevent.lua

**功能说明**：增强型输入事件处理，支持单击、双击、三击、长按等复杂手势识别。

**主要特性**：
- 支持单击、双击、三击、四击、五击识别
- 支持按下/释放事件处理
- 支持条件执行（基于 mpv 属性）
- 支持外部配置文件
- 支持自动反向命令（按下时执行，释放时撤销）

**配置选项**：
```ini
enable_external_config=false    # 启用外部配置
external_config=~~/script-opts/inputevent_key.conf  # 外部配置路径
prefix=event                    # 事件前缀
```

**使用方法**：
```ini
# input.conf 示例
MBTN_LEFT  #event:click|fullscreen>0.5 : cycle fullscreen
MBTN_LEFT  #event:double_click : cycle pause
MBTN_LEFT  #event:press : no-osd show-text "按下" ; cycle pause
```

**依赖项**：
- mp.input（可选，用于条件执行）

---

### undoredo.lua

**功能说明**：支持播放进度的撤销（Undo）和重做（Redo）功能。

**主要特性**：
- 记录播放进度历史
- 支持撤销到之前的进度点
- 支持重做已撤销的进度
- 支持循环撤销/重做模式

**配置选项**：
```ini
osd_messages=true    # 是否显示 OSD 消息
```

**使用方法**：
```ini
# 默认键绑定（可在脚本中修改）
Ctrl+Z     # 撤销
Ctrl+Y     # 重做
Ctrl+Alt+Z # 循环撤销/重做
```

**依赖项**：无

---

## 字幕工具

### sub-select.lua

**功能说明**：基于音频轨道和字幕名称/语言的高级字幕轨道选择脚本。

**主要特性**：
- 根据当前音频轨道自动选择匹配的字幕
- 支持首选语言、排除词汇、期望词汇配置
- 支持条件表达式
- 支持继承配置
- 支持智能保持用户选择的轨道

**配置选项**：
```ini
force_enable=false              # 强制启用
hook=true                       # 使用钩子同步执行
fingerprint=false               # 使用轨道指纹
smart_keep=false                # 智能保持上次选择的轨道
preferred_audio_lang=jpn/japanese  # 首选音频语言
preferred_sub_lang=eng          # 首选字幕语言
excluded_sub_words=sign         # 排除词汇
```

**使用方法**：
- 配置文件：`script-opts/sub_select.conf`
- 偏好设置文件：`script-opts/sub-select.json`

**依赖项**：无

---

### sub_export.lua

**功能说明**：导出当前选中的内封字幕为独立文件（支持 srt、ass、sup 格式）。

**主要特性**：
- 支持导出 srt、ass、sup 格式
- 自动使用视频文件名
- 支持多语言字幕命名
- 自动加载导出的字幕

**配置选项**：
```ini
ffmpeg_path=ffmpeg    # ffmpeg 路径
language=eng          # 语言：eng/chs
```

**使用方法**：
```ini
# input.conf 绑定
X    script-message-to sub_export export-selected-subtitles
```

**依赖项**：
- ffmpeg

---

### sub-assrt.lua

**功能说明**：从伪射手网（assrt.net）搜索并下载字幕，支持自动解析视频标题和剧集信息。

**使用场景**：
- 下载的外语电影没有中文字幕，需要在线搜索匹配的字幕
- 追番时官方字幕有错误，寻找字幕组制作的精校字幕
- 观看老电影找不到字幕，通过关键词搜索匹配的字幕
- 自动识别剧集信息（如 S01E02），精准下载对应集数的字幕

**配置位置**：
- 配置文件：`~~/script-opts/sub-assrt.conf`
- 生效方式：修改配置后立即生效

**配置示例**：
```ini
# sub-assrt.conf 完整配置示例
api_token=tNjXZUnOJWcHznHDyalNMYqqP6IdDdpQ  # 射手网 API 令牌（必需）
use_https=true                               # 使用 HTTPS 连接
proxy=                                       # 代理设置（如 http://127.0.0.1:7890）
timeout=10                                   # 请求超时时间（秒）
max_results=10                               # 最大显示搜索结果数量
auto_download_best=no                        # 自动下载最佳匹配（需确认）
search_source=title                          # 搜索源：title(文件名)/hash(文件哈希)
sub_format=ass                               # 字幕格式偏好：ass/srt
save_path=source                             # 保存路径：source(视频同级)/specified(指定目录)
specified_path=~~/subtitles                  # 指定保存目录（当 save_path=specified 时）
overwrite_existing=no                        # 是否覆盖已存在的字幕文件
```

**使用方法**：
1. **首次使用**：
   - 在 `~~/script-opts/` 目录创建 `sub-assrt.conf` 文件
   - **获取 API Token**：
     1. 访问 https://assrt.net 并注册账号
     2. 进入个人中心获取 API Token
     3. 将 Token 填入配置文件的 `api_token` 项
   - 在 `input.conf` 中添加键绑定（见下方示例）

2. **搜索字幕**：
   - 按 `S` 打开字幕搜索界面
   - 脚本自动解析视频文件名，提取关键词搜索
   - 显示搜索结果列表，包含字幕名称、格式、评分
   - 使用 `UP/DOWN` 选择，按 `ENTER` 下载

3. **手动搜索**：
   - 在搜索界面输入自定义关键词
   - 支持输入剧集信息如 "剧名 S01E02"
   - 脚本自动搜索匹配的字幕

4. **下载和加载**：
   - 选择字幕后自动下载并保存到配置路径
   - 下载完成后自动加载字幕
   - OSD 显示下载成功提示

**input.conf 绑定示例**：
```ini
# 示例 1：基本字幕搜索
S         script-message-to sub_assrt sub-assrt           # 搜索并下载字幕

# 示例 2：手动输入搜索词
Ctrl+S    script-message-to sub_assrt sub-assrt-manual    # 手动输入关键词搜索

# 示例 3：重新加载字幕
Alt+S     script-message-to sub_assrt sub-assrt-reload    # 重新搜索当前视频
```

**常见问题**：
- **Q**: 搜索失败显示 API 错误？  
  **A**: 检查 `api_token` 是否正确，确认网络可以访问 assrt.net
- **Q**: 搜索结果为空？  
  **A**: 尝试手动搜索，使用更简短的关键词或剧名
- **Q**: 下载的字幕不同步？  
  **A**: 选择其他版本，或查看字幕详情中的版本号是否匹配
- **Q**: 如何指定保存位置？  
  **A**: 设置 `save_path=specified` 并配置 `specified_path`
- **Q**: 使用代理下载？  
  **A**: 设置 `proxy=http://127.0.0.1:7890`（根据实际代理配置）
- **Q**: 自动下载最佳匹配？  
  **A**: 设置 `auto_download_best=yes`，但仍建议手动确认

**依赖项**：
- curl（mpv 内置或系统安装）
- mp.input（可选，用于更好的输入界面）
- uosc（可选，用于更美观的界面）

---

### sub-fastwhisper.lua

**功能说明**：使用 faster-whisper 自动生成 AI 字幕，支持实时翻译。

**主要特性**：
- 支持 faster-whisper  standalone
- 支持 CPU/CUDA 加速
- 支持多模型选择（base/small/medium/large/turbo）
- 支持分段处理长视频
- 支持 GPT API 实时翻译
- 支持流媒体边下边生成

**配置选项**：
```ini
fast_whisper_path=faster-whisper    # faster-whisper 路径
model=base                          # 模型：base/small/medium/large/turbo
device=cpu                          # 设备：cpu/cuda
language=                           # 语言（留空自动检测）
threads=0                           # CPU 线程数（0=自动）
max_line_width=100                  # 最大行宽
output_path=source                  # 输出路径
update_interval=20                  # 更新间隔（字幕数量）
use_segment=false                   # 使用分段模式
segment_duration=10                 # 分段时长（秒）
api_url=                            # GPT API 地址
api_key=                            # GPT API 密钥
api_mode=gpt-4o                     # API 模型
translate=Chinese                   # 翻译目标语言
font_name=sans-serif                # ASS 字幕字体
```

**使用方法**：
```ini
# input.conf 绑定
W    script-message-to sub-fastwhisper sub-fastwhisper  # 生成字幕
T    script-message-to sub-fastwhisper sub-translate     # 翻译字幕
```

**依赖项**：
- faster-whisper standalone
- ffmpeg（分段模式）
- curl（翻译模式）

---

### sub-fonts-dir-auto.lua

**功能说明**：自动查找视频目录下的 `Fonts` 文件夹并设置为字幕字体目录。

**主要特性**：
- 自动检测视频同级的 `Fonts` 目录
- 区分大小写匹配
- 不覆盖命令行设置

**配置选项**：无

**使用方法**：
- 自动运行，加载视频时检测

**依赖项**：
- 需要支持 `sub-fonts-dir` 选项的 mpv 版本

---

### sponsorblock_minimal.lua

**功能说明**：使用 SponsorBlock API 跳过 YouTube 和 Bilibili 视频中的赞助片段。

**主要特性**：
- 支持 SponsorBlock API（YouTube）
- 支持 BiliSponsorBlock API（Bilibili）
- 支持跳过/静音/标记章节
- 支持分类过滤

**配置选项**：
```ini
youtube_sponsor_server=https://sponsor.ajay.app/api/skipSegments  # YouTube API
bilibili_sponsor_server=https://bsbsb.top/api/skipSegments       # Bilibili API
categories="sponsor"    # 跳过的类别
```

**使用方法**：
- 自动运行，加载 YouTube/Bilibili 视频时触发

**依赖项**：
- curl

---

## 播放列表管理

### playlistmanager.lua

**功能说明**：功能丰富的播放列表管理器，支持可视化浏览、排序、搜索和编辑。

**使用场景**：
- 当播放列表文件很多时，快速查找并跳转到特定文件
- 整理杂乱的播放列表，按名称/日期/大小重新排序
- 批量移除不需要的文件，保留想看的视频
- 保存当前播放列表，下次直接加载继续观看
- 加载整个文件夹的视频到播放列表

**配置位置**：
- 配置文件：`~~/script-opts/playlistmanager.conf`
- 生效方式：修改配置后立即生效，动态键绑定自动更新

**配置示例**：
```ini
# playlistmanager.conf 完整配置示例
dynamic_binds=true              # 动态键绑定（仅在播放列表显示时激活）
key_showplaylist=SHIFT+ENTER    # 显示播放列表的快捷键
key_moveup=UP                   # 上移选中项
key_movedown=DOWN               # 下移选中项
key_selectfile=RIGHT LEFT       # 选择文件（加入/取消选择）
key_playfile=ENTER              # 播放选中文件
key_removefile=BS               # 移除选中文件
key_closeplaylist=ESC           # 关闭播放列表
key_sortplaylist=S              # 排序播放列表（弹出排序菜单）
key_shuffleplaylist=R           # 随机打乱播放列表
key_loadfiles=L                 # 加载文件到播放列表
key_saveplaylist=Ctrl+S         # 保存播放列表到文件
filename_replace=[{"pattern":"_","replace":" "}]  # 文件名替换规则（JSON 格式）
loadfiles_filetypes=video,audio # 自动加载的文件类型
loadfiles_on_start=false        # 启动 mpv 时自动加载目录文件
default_sort=name-asc           # 默认排序方式：name-asc/date-desc/size-asc
playlist_savepath=~~/playlists  # 播放列表保存目录
showamount=10                   # 最大显示行数
style_ass_tags=                 # ASS 样式标签（自定义显示样式）
curtain_opacity=0.0             # 背景遮罩透明度（0.0-1.0）
```

**使用方法**：
1. **首次使用**：
   - 在 `~~/script-opts/` 目录创建 `playlistmanager.conf` 文件
   - 复制上方配置示例，设置 `key_showplaylist` 为方便的快捷键
   - 可选：配置文件名替换规则，美化显示的文件名

2. **打开播放列表**：
   - 按 `SHIFT+ENTER`（或配置的快捷键）打开播放列表窗口
   - 使用 `UP/DOWN` 上下移动选择
   - 使用 `ENTER` 播放选中的文件
   - 使用 `BS` 移除不需要的文件
   - 使用 `ESC` 关闭播放列表窗口

3. **排序和搜索**：
   - 按 `S` 打开排序菜单，选择排序方式
   - 输入关键词搜索文件名
   - 按 `R` 随机打乱播放列表

4. **保存和加载**：
   - 按 `Ctrl+S` 保存当前播放列表
   - 下次使用 `L` 加载保存的播放列表

**input.conf 绑定示例**：
```ini
# 示例 1：基本播放列表管理
SHIFT+ENTER  script-binding playlistmanager/show-playlist   # 打开播放列表

# 示例 2：快速操作（无需打开播放列表窗口）
Ctrl+P    script-binding playlistmanager/play-next         # 播放下一个
Ctrl+O    script-binding playlistmanager/play-previous     # 播放上一个

# 示例 3：文件加载
Ctrl+L    script-binding playlistmanager/load-files        # 加载文件
Ctrl+D    script-binding playlistmanager/load-directory    # 加载整个目录
```

**常见问题**：
- **Q**: 播放列表窗口显示乱码？  
  **A**: 检查 `style_ass_tags` 配置，确保字体支持中文
- **Q**: 动态键绑定不生效？  
  **A**: 确认 `dynamic_binds=yes`，键绑定只在播放列表显示时激活
- **Q**: 文件名显示不好看？  
  **A**: 配置 `filename_replace` 规则，如替换下划线为空格
- **Q**: 如何保存播放列表？  
  **A**: 按 `Ctrl+S` 或配置 `key_saveplaylist`，选择保存位置
- **Q**: 播放列表文件太多操作卡顿？  
  **A**: 减小 `showamount` 值，或启用 `curtain_opacity` 降低渲染负担

**依赖项**：
- FFI（Windows 自然排序，mpv 内置支持）
- uosc（可选，用于更美观的界面集成）

---

### quality-menu.lua

**功能说明**：YouTube 视频质量选择菜单，支持视频和音频轨道选择。

**主要特性**：
- 支持 yt-dlp 获取可用格式
- 支持自定义质量选项
- 支持 uosc 集成
- 支持列自定义和排序
- 支持自动识别相同列并隐藏

**配置选项**：
```ini
fetch_formats=true          # 使用 yt-dlp 获取格式
start_with_menu=false       # 打开 URL 时自动显示菜单
columns_video=...           # 视频列配置
columns_audio=...           # 音频列配置
sort_video=...              # 视频排序配置
sort_audio=...              # 音频排序配置
menu_timeout=6              # 菜单超时（秒）
curtain_opacity=0.7         # 背景遮罩透明度
```

**使用方法**：
```ini
# input.conf 绑定
F     script-binding quality_menu/video_formats_toggle
Alt+f script-binding quality_menu/audio_formats_toggle
```

**依赖项**：
- yt-dlp 或 youtube-dl
- uosc（可选）

---

### recentmenu.lua

**功能说明**：最近播放记录菜单，支持快速访问历史记录。

**主要特性**：
- 记录最近播放的文件
- 支持 uosc 集成
- 支持 mp.input 集成
- 支持自动清理已删除文件
- 支持同系列文件过滤

**配置选项**：
```ini
enabled=true            # 启用
path=~~/recent.json     # 记录文件路径
title=Recently played   # 菜单标题
length=10               # 记录数量
width=88                # 标题宽度
ignore_same_series=true # 忽略同系列文件
reduce_io=false         # 减少 IO 操作
```

**使用方法**：
```ini
# input.conf 绑定
Ctrl+R  script-binding recentmenu/open    # 打开最近记录
Ctrl+T  script-binding recentmenu/last    # 播放最后一个
```

**依赖项**：
- uosc（可选）
- mp.input（可选）
- dyn_menu（可选）

---

## 书签与历史

### history-bookmark.lua

**功能说明**：目录级别的播放历史和书签功能，支持跨文件续播。

**主要特性**：
- 记录每个目录的最后播放文件
- 支持跨文件续播提示
- 支持播放列表检测
- 支持哈希命名书签文件
- 支持排除目录配置

**配置选项**：
```ini
enabled=true            # 启用
language=eng            # 语言：eng/chs
timeout=15              # 续播提示超时（秒）
save_period=30          # 保存间隔（秒）
history_dir=/:dir%mpvconf%/historybookmarks  # 历史目录
bookmark_ext=.mpv.history  # 书签扩展名
hash=true               # 使用哈希命名
use_playlist=true       # 使用播放列表
whitelist=3gp,amv,avi...  # 白名单扩展名
excluded_dir=[]         # 排除目录
```

**使用方法**：
- 自动运行，加载文件时检测历史记录

**依赖项**：
- mp.input（可选，用于输入提示）

---

### simplebookmark.lua

**功能说明**：高级书签管理系统，支持分组、快捷键、搜索和过滤。

**使用场景**：
- 看长教程视频时，标记重要章节位置方便快速回顾
- 追剧时标记每集的开头位置，跳过片头直接看正片
- 看电影时标记精彩片段，方便以后快速定位重温
- 管理多个电视剧的观看进度，按分组整理书签
- 保存视频中的名场面/经典台词出现的时间点

**配置位置**：
- 配置文件：`~~/script-opts/simplebookmark.conf`
- 书签数据：`~~/bookmarks.json`（自动创建）
- 生效方式：修改配置后立即生效

**配置示例**：
```ini
# simplebookmark.conf 完整配置示例
# 基础设置
auto_run=yes                  # 自动运行脚本
osd_messages=yes              # 显示 OSD 消息
osd_duration=2000             # OSD 显示时长（毫秒）
chapter_bookmarks=yes         # 允许章节标记

# 快捷键槽位（9 个快速槽位）
slot_1=Ctrl+1                 # 快速槽位 1
slot_2=Ctrl+2                 # 快速槽位 2
slot_3=Ctrl+3                 # 快速槽位 3
# ... 可配置 9 个槽位

# 分组设置
default_group=默认分组        # 默认分组名称
group_separator=/             # 分组分隔符（支持多级分组）

# 列表设置
showamount=15                 # 列表最大显示行数
time_format=human             # 时间格式：human(人性化)/seconds(秒数)/timestamp(时间戳)
date_format=yyyy-mm-dd        # 日期格式

# 过滤和排序
filter_mode=none              # 过滤模式：none/group/tag
sort_mode=created_desc        # 排序模式：created_desc/time_asc/alpha

# 列表样式
title_prefix="🔖 "            # 标题前缀
title_suffix=""               # 标题后缀
highlight_color=\Hffb3473e    # 高亮颜色（ASS 颜色标签）
```

**使用方法**：
1. **首次使用**：
   - 在 `~~/script-opts/` 目录创建 `simplebookmark.conf` 文件
   - 复制上方配置示例
   - 在 `input.conf` 中添加键绑定（见下方示例）

2. **保存书签**：
   - 按 `Ctrl+B` 保存当前播放位置的书签
   - 输入书签名称（可选，默认使用视频名 + 时间）
   - 选择分组（可选，支持多级分组如 `动画/海贼王`）

3. **查看书签列表**：
   - 按 `B` 打开书签列表
   - 使用 `UP/DOWN` 选择书签
   - 按 `ENTER` 跳转到选中的书签位置
   - 按 `DELETE` 删除选中的书签
   - 按 `ESC` 关闭列表

4. **使用快速槽位**：
   - 按 `Ctrl+1` 到 `Ctrl+9` 快速保存/跳转到对应槽位
   - 适合标记视频中的重要位置

5. **搜索和过滤**：
   - 在列表中输入关键词搜索书签
   - 按分组过滤查看特定分组的书签

**input.conf 绑定示例**：
```ini
# 示例 1：基本书签操作
Ctrl+B    script-binding simplebookmark/save-bookmark    # 保存书签
B         script-binding simplebookmark/show-list        # 显示书签列表
Alt+B     script-binding simplebookmark/save-file-only   # 仅保存文件（不保存时间）

# 示例 2：快速槽位（需在配置文件中启用）
Ctrl+1    script-binding simplebookmark/slot-1
Ctrl+2    script-binding simplebookmark/slot-2
Ctrl+3    script-binding simplebookmark/slot-3

# 示例 3：章节标记
M         script-binding simplebookmark/mark-chapter     # 标记当前为章节
```

**常见问题**：
- **Q**: 书签保存在哪里？  
  **A**: 默认保存在 `~~/bookmarks.json`，可在配置文件中修改路径
- **Q**: 如何导出书签？  
  **A**: 书签文件是 JSON 格式，可直接复制备份或编辑
- **Q**: 如何创建多级分组？  
  **A**: 使用 `/` 分隔符，如输入 `动画/日本/海贼王` 创建三级分组
- **Q**: 快速槽位不生效？  
  **A**: 在配置文件中设置 `slot_1=Ctrl+1` 等键绑定
- **Q**: 书签列表显示乱码？  
  **A**: 检查 mpv 字体配置，确保支持中文显示

**依赖项**：
- 无

---

### simplehistory.lua

**功能说明**：播放历史记录管理器，支持搜索、过滤和续播功能。

**使用场景**：
- 昨天看到一半的电影，今天快速找到上次观看的位置继续观看
- 查找上周看过的教程视频，不需要记得具体文件名
- 清理观看历史，删除不再需要的记录
- 隐身模式下观看视频，不留下历史记录
- 按日期排序查找特定时间观看的视频

**配置位置**：
- 配置文件：`~~/script-opts/simplehistory.conf`
- 历史数据：`~~/history.json`（自动创建）
- 生效方式：修改配置后立即生效

**配置示例**：
```ini
# simplehistory.conf 完整配置示例
# 基础设置
auto_run=yes                  # 自动运行脚本
osd_messages=yes              # 显示 OSD 消息
osd_duration=2000             # OSD 显示时长（毫秒）

# 隐身模式
incognito_mode=no             # 启用隐身模式（不记录历史）
incognito_indicator="[隐身]"  # 隐身模式指示器

# 历史记录设置
max_history=500               # 最大历史记录数量
auto_clean=yes                # 自动清理超过数量的历史记录
clean_on_start=no             # 启动时清理过期记录

# 列表设置
showamount=15                 # 列表最大显示行数
time_format=human             # 时间格式：human(人性化)/seconds(秒数)/timestamp(时间戳)
date_format=yyyy-mm-dd        # 日期格式
resume_prompt=yes             # 显示续播提示
resume_timeout=10             # 续播提示超时（秒）

# 过滤和排序
filter_mode=none              # 过滤模式：none/date/type
sort_mode=last_watched_desc   # 排序模式：last_watched_desc/first_watched_asc/alpha

# 列表样式
title_prefix="📺 "            # 标题前缀
title_suffix=""               # 标题后缀
watched_indicator="[已看]"    # 已观看指示器
```

**使用方法**：
1. **首次使用**：
   - 在 `~~/script-opts/` 目录创建 `simplehistory.conf` 文件
   - 复制上方配置示例
   - 在 `input.conf` 中添加键绑定（见下方示例）

2. **查看历史记录**：
   - 按 `H` 打开历史记录列表
   - 使用 `UP/DOWN` 选择历史记录
   - 按 `ENTER` 播放选中的视频（自动跳转到上次观看位置）
   - 按 `DELETE` 删除选中的历史记录
   - 按 `ESC` 关闭列表

3. **续播功能**：
   - 按 `Ctrl+R` 直接续播最后一个观看的视频
   - 按 `Alt+R` 加载最后一个视频（不续播，从头开始）
   - 打开有历史记录的视频时，OSD 显示续播提示

4. **搜索和过滤**：
   - 在列表中输入关键词搜索历史
   - 按日期过滤查看特定时间段的历史
   - 按类型过滤（视频/音频/图片）

5. **隐身模式**：
   - 开启隐身模式后，观看记录不会保存到历史
   - 适合观看隐私内容时使用

**input.conf 绑定示例**：
```ini
# 示例 1：基本历史操作
H         script-binding simplehistory/show-list         # 显示历史列表
Ctrl+R    script-binding simplehistory/resume-last       # 续播最后一个
Alt+R     script-binding simplehistory/load-last         # 加载最后一个（不续播）

# 示例 2：历史管理
Ctrl+H    script-binding simplehistory/clear-all         # 清空所有历史
Ctrl+D    script-binding simplehistory/delete-selected   # 删除选中历史

# 示例 3：隐身模式切换
Ctrl+I    script-binding simplehistory/toggle-incognito  # 切换隐身模式
```

**常见问题**：
- **Q**: 历史记录保存在哪里？  
  **A**: 默认保存在 `~~/history.json`，可在配置文件中修改路径
- **Q**: 如何清空所有历史记录？  
  **A**: 按 `Ctrl+H` 或手动删除 `history.json` 文件
- **Q**: 为什么没有续播提示？  
  **A**: 检查 `resume_prompt=yes`，确认视频有保存播放进度
- **Q**: 如何禁用历史记录？  
  **A**: 设置 `incognito_mode=yes` 永久启用隐身模式
- **Q**: 历史记录太多列表加载慢？  
  **A**: 减小 `max_history` 值，或启用 `auto_clean=yes`

**依赖项**：
- 无

---

## 视频处理

### mpv-animated.lua

**功能说明**：使用 ffmpeg 创建视频片段为 GIF 或 WebP 动画。

**主要特性**：
- 支持 GIF 和 WebP 格式
- 支持带/不带字幕导出
- 支持流媒体缓存导出
- 支持自定义分辨率和帧率

**配置选项**：
```ini
type=gif                # 格式：gif/webp
ffmpeg_path=ffmpeg      # ffmpeg 路径
dir=~~desktop/          # 输出目录
rez=600                 # 分辨率
fps=15                  # 帧率
lossless=0              # 无损压缩（WebP）
quality=90              # 质量
compression_level=6     # 压缩级别（WebP）
loop=0                  # 循环次数（0=无限）
```

**使用方法**：
```ini
# input.conf 绑定
w     # 设置起始帧
W     # 设置结束帧
Ctrl+w  # 创建动画（不带字幕）
Ctrl+W  # 创建动画（带字幕）
```

**依赖项**：
- ffmpeg

---

### slicing_copy.lua

**功能说明**：快速剪切视频片段，使用 ffmpeg 流复制保持质量。

**主要特性**：
- 标记起始/结束点快速剪切
- 支持流复制（无重编码）
- 支持禁用音频
- 支持自定义输出目录

**配置选项**：
```ini
ffmpeg_path=ffmpeg      # ffmpeg 路径
target_dir=~~/cutfragments  # 输出目录
overwrite=false         # 覆盖已存在文件
vcodec=copy             # 视频编码
acodec=copy             # 音频编码
debug=false             # 调试模式
```

**使用方法**：
```ini
# input.conf 绑定
c     # 标记剪切片段
a     # 切换音频捕获
C     # 清除标记
```

**依赖项**：
- ffmpeg

---

### smartcopypaste_II.lua

**功能说明**：智能复制粘贴系统，支持带时间戳的视频链接复制和粘贴。

**主要特性**：
- 复制视频路径/标题/时间戳
- 粘贴链接自动加载
- 支持时间戳续播
- 支持剪贴板历史记录
- 支持多平台（Windows/Mac/Linux）

**配置选项**：（配置项众多，详见脚本头部注释）
- 脚本设置
- 日志设置
- 列表设置
- 过滤设置
- 排序设置
- 列表设计设置
- 时间格式设置
- 列表键绑定设置

**使用方法**：
```ini
# input.conf 绑定
Ctrl+C  # 复制
Ctrl+V  # 粘贴
Ctrl+Alt+C  # 特殊复制
Ctrl+Alt+V  # 特殊粘贴
```

**依赖项**：
- Windows: PowerShell
- Linux: xclip
- Mac: pbcopy/pbpaste

---

## UI 增强

### dyn_menu.lua

**功能说明**：动态菜单生成器，支持从 input.conf 创建上下文菜单。

**主要特性**：
- 从 input.conf 解析菜单定义
- 支持动态菜单（轨道/章节/播放列表等）
- 支持 Lua 表达式条件
- 支持 uosc/mpv 原生菜单
- 支持热更新

**配置选项**：
```ini
use_mpv_impl=true       # 使用 mpv 原生菜单实现
uosc_syntax=false       # 启用 uosc 菜单语法
escape_title=true       # 转义&字符
max_title_length=80     # 最大标题长度
max_playlist_items=20   # 最大播放列表项
```

**使用方法**：
```ini
# input.conf 示例
F10  ignore  #menu: Tracks #@tracks     # 轨道菜单
F11  ignore  #menu: Chapters #@chapters # 章节菜单
```

**依赖项**：
- uosc（可选）

---

### manager.lua

**功能说明**：脚本和配置文件管理器，支持从 Git 仓库自动更新。

**主要特性**：
- 从 Git 仓库拉取脚本
- 支持白名单/黑名单过滤
- 支持本地仓库模式
- 支持扁平化文件夹

**配置选项**：无

**使用方法**：
```ini
# manager.json 配置示例
[
  {
    "git": "https://github.com/user/repo.git",
    "whitelist": "scripts/*.lua",
    "dest": "~~/scripts"
  }
]
```

**依赖项**：
- git

---

### open_dialog.lua

**功能说明**：调用系统对话框选择文件/文件夹/剪贴板内容。

**主要特性**：
- 支持文件夹选择
- 支持文件选择（多类型过滤）
- 支持剪贴板读取
- 支持 ISO/蓝光/DVD 打开
- 支持脚本间通信

**配置选项**：
```ini
video_types=...     # 视频类型
audio_types=...     # 音频类型
image_types=...     # 图片类型
subtitle_types=...  # 字幕类型
playlist_types=...  # 播放列表类型
iso_types=iso       # ISO 类型
```

**使用方法**：
```ini
# input.conf 绑定
O     script-message-to open_dialog import_folder
Ctrl+O  script-message-to open_dialog import_files
```

**依赖项**：
- Windows: PowerShell

---

### persist_properties.lua

**功能说明**：持久化 mpv 属性设置，重启后保持。

**主要特性**：
- 保存指定属性值
- 自动加载保存的属性
- 支持定时保存

**配置选项**：
```ini
properties=volume,sub-scale  # 持久化属性列表
properties_path=persistent_config.json  # 配置文件路径
```

**使用方法**：
- 自动运行，无需手动操作

**依赖项**：无

---

### thumbfast.lua

**功能说明**：高性能缩略图生成器，为第三方 UI 提供缩略图支持。

**主要特性**：
- 高性能按需生成缩略图
- 支持网络播放
- 支持硬件解码
- 支持 Direct I/O（Windows）
- 支持黑名单过滤

**配置选项**：
```ini
socket=                 # Socket 路径（自动）
thumbnail=              # 缩略图路径（自动）
max_height=200          # 最大高度
max_width=200           # 最大宽度
overlay_id=42           # 覆盖层 ID
spawn_first=false       # 文件加载时预生成
quit_after_inactivity=0 # 无活动后退出（秒）
network=false           # 启用网络播放
audio=false             # 启用音频播放
hwdec=false             # 启用硬件解码
direct_io=false         # 使用 Direct I/O（Windows）
mpv_path=mpv            # mpv 可执行路径
blacklist_ext=bdmv,ifo  # 黑名单扩展名
```

**使用方法**：
- 供其他脚本调用（如 uosc）

**依赖项**：
- FFI（Direct I/O 模式）

---

### trackselect.lua

**功能说明**：智能轨道选择，自动选择非配音的音频和字幕轨道。

**主要特性**：
- 基于语言偏好选择轨道
- 支持排除词汇过滤
- 支持期望词汇匹配
- 支持智能保持用户选择

**配置选项**：
```ini
enabled=true            # 启用
hook=true               # 使用钩子
fingerprint=false       # 使用指纹
force=false             # 强制覆盖用户选择
smart_keep=false        # 智能保持
preferred_audio_lang=jpn/japanese  # 首选音频语言
preferred_sub_lang=eng  # 首选字幕语言
excluded_sub_words=sign # 排除词汇
```

**使用方法**：
- 自动运行，加载文件时选择轨道

**依赖项**：无

---

### uosc/

**功能说明**：现代化 OSD 用户界面，提供时间线、控制按钮、音量控制、顶部栏等完整的播放器界面。

**使用场景**：
- 想要更现代化的播放器界面，替代 mpv 默认的简陋 OSD
- 需要精确控制播放进度，拖动时间线定位
- 希望显示视频信息、音量、播放速度等状态
- 需要章节导航、播放列表、轨道选择等菜单功能
- 想要缩略图预览，拖动时看到对应画面的缩略图

**配置位置**：
- 配置文件：`~~/script-opts/uosc.conf`
- 生效方式：修改配置后立即生效，部分界面元素需要重新加载视频

**配置示例**：
```ini
# uosc.conf 完整配置示例
# 时间线配置
timeline_enable=yes                   # 启用时间线
timeline_show_title=yes               # 时间线显示标题
timeline_size=20                      # 时间线大小（像素）
timeline_border=1                     # 时间线边框大小
timeline_step=5                       # 拖动步进（秒）
timeline_persistency=paused           # 持久性：always/paused/never
timeline_chapter_ranges=yes           # 显示章节范围
timeline_thumbnail=yes                # 启用缩略图预览（需要 thumbfast）

# 控制按钮配置
controls_enable=yes                   # 启用控制按钮
controls_buttons=play_pause,cycle_audio,cycle_sub,menu  # 按钮布局
controls_size=24                      # 按钮大小
controls_persistency=always           # 持久性：always/paused/never

# 顶部栏配置
top_bar_enable=yes                    # 启用顶部栏
top_bar_show_title=yes                # 显示标题
top_bar_show_time=yes                 # 显示时间
top_bar_size=30                       # 顶部栏大小
top_bar_persistency=always            # 持久性

# 音量控制
volume_control=yes                    # 启用音量控制
volume_size=20                        # 音量条大小

# 菜单配置
menu_enable=yes                       # 启用菜单系统
menu_mouse=yes                        # 启用鼠标支持
menu_key_bindings=yes                 # 启用菜单键绑定

# 颜色和样式
foreground=ffffff                     # 前景色（白色）
background=000000                     # 背景色（黑色）
accent=58a6ff                         # 强调色（蓝色）
text_alpha=1.0                        # 文字透明度
background_alpha=0.8                  # 背景透明度

# 动画配置
animation_enable=yes                  # 启用动画效果
animation_duration=200                # 动画时长（毫秒）

# 语言配置
language=auto                         # 语言：auto/sc/en/zh/ja 等
```

**使用方法**：
1. **首次使用**：
   - 在 `~~/script-opts/` 目录创建 `uosc.conf` 文件
   - 复制上方配置示例，根据需要调整样式
   - 推荐安装 `thumbfast` 脚本以启用缩略图预览

2. **基本操作**：
   - **鼠标悬停**：显示控制按钮和时间线
   - **点击时间线**：跳转到对应位置
   - **拖动时间线**：显示缩略图预览（需 thumbfast）
   - **滚轮**：调整音量（悬停音量条时）或快进/退
   - **右键点击**：显示上下文菜单

3. **菜单导航**：
   - 按 `MENU` 键或点击菜单按钮打开主菜单
   - 使用 `UP/DOWN` 选择菜单项
   - 按 `ENTER` 确认，`ESC` 返回
   - 支持菜单：章节、轨道、播放列表、收藏等

4. **快捷操作**：
   - 点击播放/暂停按钮控制播放
   - 点击音频/字幕按钮切换轨道
   - 双击进入/退出全屏

**input.conf 绑定示例**：
```ini
# 示例 1：基本控制（uosc 默认处理，无需绑定）
# MBTN_LEFT   点击时间线跳转
# MBTN_RIGHT  显示上下文菜单
# WHEEL_UP    音量增加
# WHEEL_DOWN  音量减少

# 示例 2：菜单快捷键
MENU      script-binding uosc/menu             # 打开主菜单
TAB       script-binding uosc/playlist         # 播放列表
T         script-binding uosc/tracks           # 轨道菜单
C         script-binding uosc/chapters         # 章节菜单

# 示例 3：界面切换
Ctrl+T    script-binding uosc/toggle-timeline  # 切换时间线显示
Ctrl+C    script-binding uosc/toggle-controls  # 切换控制按钮
```

**常见问题**：
- **Q**: 时间线不显示缩略图？  
  **A**: 安装 `thumbfast` 脚本，确认 `timeline_thumbnail=yes`
- **Q**: 鼠标操作不灵敏？  
  **A**: 检查 `menu_mouse=yes`，调整 `timeline_size` 增大时间线
- **Q**: 界面颜色不喜欢？  
  **A**: 修改 `foreground`、`background`、`accent` 颜色配置
- **Q**: 动画效果卡顿？  
  **A**: 设置 `animation_enable=no` 禁用动画
- **Q**: 如何自定义菜单项？  
  **A**: 编辑 uosc 目录中的 `menu.lua` 文件
- **Q**: 顶部栏一直显示？  
  **A**: 调整 `top_bar_persistency=always/paused/never`

**依赖项**：
- thumbfast（缩略图预览，强烈推荐）
- ziggy（章节检测，可选）

---

### uosc_danmaku/

**功能说明**：弹幕播放器，支持从多种来源加载和渲染弹幕。

**主要特性**：
- 支持弹弹 play API
- 支持本地 XML 弹幕
- 支持 Bilibili 弹幕
- 支持自动匹配
- 支持历史记录
- 支持弹幕延迟调整
- 支持弹幕搜索菜单
- 支持 uosc 集成

**配置选项**：
```ini
history_path=~~/danmaku_history.json  # 历史文件路径
autoload=true           # 自动加载弹幕
autoload_local_danmaku=true  # 自动加载本地弹幕
autoload_for_url=true   # URL 自动加载
auto_load=true          # 自动匹配加载
load_more_danmaku=true  # 加载更多弹幕
autoload_danmaku_matches=true  # 自动加载匹配结果
```

**使用方法**：
```ini
# input.conf 绑定
D     script-binding uosc_danmaku/show_danmaku_keyboard  # 切换弹幕
```

**依赖项**：
- uosc
- curl

---

## 网络流媒体

### mpv-torrserver.lua

**功能说明**：TorrServer 种子流媒体支持，将磁力链接转换为可播放列表。

**主要特性**：
- 支持磁力链接播放
- 支持.torrent 文件播放
- 自动生成播放列表
- 支持外部轨道（字幕/音频）
- 支持 EDL 播放列表格式

**配置选项**：
```ini
server=http://localhost:8090  # TorrServer 地址
torrserver_init=false         # 自动启动 TorrServer
torrserver_path=TorrServer    # TorrServer 路径
search_for_external_tracks=true  # 搜索外部轨道
```

**使用方法**：
- 自动运行，加载磁力链接或.torrent 文件时触发

**依赖项**：
- TorrServer
- curl 或 Lua-cURL

---

### simple-mpv-webui/

**功能说明**：简易 Web 控制界面，通过浏览器控制 mpv 播放。

**主要特性**：
- HTTP 服务器
- RESTful API
- 静态文件服务
- 支持基本认证
- 支持播放列表管理
- 支持收藏集

**配置选项**：
```ini
port=8080               # 监听端口
disable=false           # 禁用
logging=false           # 日志
osd_logging=true        # OSD 日志
ipv4=true               # 启用 IPv4
ipv6=true               # 启用 IPv6
audio_devices=          # 音频设备过滤
static_dir=             # 静态文件目录
htpasswd_path=          # 认证文件路径
collections=            # 收藏集目录
```

**使用方法**：
- 启动 mpv 后访问 `http://localhost:8080`

**依赖项**：
- LuaSocket
- LuaSec（HTTPS）
- basenc（Base64）

---

## 快速参考

### 配置文件位置

所有脚本的配置文件都位于 `~~/script-opts/` 目录下：

| 脚本 | 配置文件 |
|------|----------|
| autoload | `~~/script-opts/autoload.conf` |
| chapterskip | `~~/script-opts/chapterskip.conf` |
| evafast | `~~/script-opts/evafast.conf` |
| playlistmanager | `~~/script-opts/playlistmanager.conf` |
| simplebookmark | `~~/script-opts/simplebookmark.conf` |
| simplehistory | `~~/script-opts/simplehistory.conf` |
| sub-assrt | `~~/script-opts/sub-assrt.conf` |
| uosc | `~~/script-opts/uosc.conf` |

### 常用快捷键速查

| 功能 | 快捷键 | 说明 |
|------|--------|------|
| 播放列表 | `SHIFT+ENTER` | 打开播放列表管理器 |
| 历史记录 | `H` | 打开历史记录列表 |
| 续播 | `Ctrl+R` | 续播最后一个视频 |
| 书签 | `B` / `Ctrl+B` | 打开列表 / 保存书签 |
| 字幕搜索 | `S` | 从射手网下载字幕 |
| 快进/倒带 | `RIGHT` / `LEFT` | 智能快进（长按加速） |
| 片头跳过 | `SHIFT+S` | 切换跳过模式 |
| 菜单 | `MENU` / `TAB` | 打开主菜单 / 播放列表 |

### 依赖项安装

**必需工具**：
- **ffmpeg**：用于字幕导出、视频裁剪、动画制作等
  - Windows: 从 https://ffmpeg.org/download.html 下载
  - 放入 mpv 配置目录或添加到 PATH

- **yt-dlp**：用于 YouTube 质量选择
  ```bash
  pip install yt-dlp
  # 或从 https://github.com/yt-dlp/yt-dlp/releases 下载
  ```

- **curl**：用于字幕下载、SponsorBlock 等
  - Windows: mpv 内置或从 https://curl.se/windows/ 下载

**可选工具**：
- **thumbfast**：uosc 缩略图预览（强烈推荐）
- **faster-whisper**：AI 字幕生成
- **git**：脚本管理器更新

---

## 子目录说明

| 目录 | 功能 |
|------|------|
| `autosubsync/` | 自动字幕同步工具，支持音频波形匹配 |
| `file-browser/` | 文件浏览器，支持浏览和打开本地文件/文件夹 |
| `simple-mpv-webui/` | Web 控制界面的静态文件和主脚本 |
| `trakt-scrobble/` | Trakt.tv 观影记录同步 |
| `uosc/` | 现代化 OSD 用户界面的主脚本和库文件 |
| `uosc_danmaku/` | 弹幕播放器的扩展脚本和 API 模块 |

---

*文档最后更新：2026 年 2 月*
