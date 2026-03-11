# 📚 MPV 播放器 - 完整功能文档

> 详细功能说明 | 配置参考 | 使用指南
>
> 🚀 **新手入门**：[5 分钟快速上手](快速开始.md) | 🏠 **返回主页**：[../README.md](../README.md)

---

## 📖 文档导航

**新手必读**
- [5 分钟快速上手](快速开始.md) - 基础操作、高频场景、快捷键速查
- [常用配置速查](快速开始.md#-常用配置速查) - 核心配置文件一览
- [快捷键表](快速开始.md#-快捷键速查表) - 完整快捷键列表
- [常见问题](快速开始.md#-常见问题) - FAQ 解答

**本文档内容**
- [播放控制脚本](#播放控制) - 详细功能说明
- [字幕工具](#字幕工具) - 字幕相关功能
- [播放列表管理](#播放列表管理) - 高级管理功能
- [书签与历史](#书签与历史) - 记录管理
- [视频处理](#视频处理) - 剪辑与导出
- [UI 增强](#ui-增强) - 界面扩展
- [网络功能](#网络功能) - 在线播放
- [着色器推荐](#着色器推荐) - 视频增强配置

---

## 播放控制

### chapterskip.lua
**功能**：智能跳过片头片尾，支持章节标题、位置推断和静音检测。

**使用场景**：追番自动跳过 OP/ED、看电影跳过制作人员名单、跳过静音片段。

**配置**：`script-opts/chapterskip.conf`
```ini
mode=auto                          # 自动跳过
skip=opening;ending                # 跳过类别
enable_history_position_inference=yes  # 跨集应用历史记录
```

**快捷键**：
- `Shift + S` - 切换跳过模式
- `Shift + M` - 手动标记跳过片段

[查看使用指南 →](快速开始.md#场景 -2：跳过片头片尾---省时间)

---

### evafast.lua
**功能**：智能快进，轻按跳转，长按加速，字幕出现时自动限速。

**配置**：`script-opts/evafast.conf`
```ini
seek_distance=5           # 跳转距离（秒）
speed_cap=3               # 最高速度
subs_speed_cap=1.5        # 字幕显示时限速
```

**使用**：
- 轻按 `→`：快进 5 秒
- 长按 `→`：加速播放（最高 3 倍）
- 字幕出现：自动限速到 1.5 倍

[查看使用指南 →](快速开始.md#场景 -6：快速定位---智能快进)

---

### autoload.lua
**功能**：自动加载同目录文件到播放列表。

**配置**：`script-opts/autoload.conf`
```ini
disabled=no
videos=yes
same_type=yes
directory_mode=ignore
```

[查看使用指南 →](快速开始.md#场景 -1：追番追剧---自动连播)

---

### 其他播放控制脚本

| 脚本 | 功能 | 配置 |
|------|------|------|
| `auto-save-state.lua` | 定期保存播放状态 | `auto_save_state.conf` |
| `blacklist-extensions.lua` | 按扩展名过滤 | `blacklist_extensions.conf` |
| `dynamic-crop.lua` | 自动裁剪黑边 | `dynamic_crop.conf` |
| `hdr-mode.lua` | Windows HDR 切换 | `hdr_mode.conf` |
| `undoredo.lua` | 进度撤销/重做 | 无配置 |

---

## 字幕工具

### sub-assrt.lua
**功能**：从射手网搜索并下载中文字幕。

**首次使用**：
1. 访问 https://assrt.net 注册获取 API Token
2. 编辑 `script-opts/sub_assrt.conf` 填入 token

**快捷键**：
- `S` - 搜索字幕
- `Ctrl + S` - 手动搜索

[查看使用指南 →](快速开始.md#场景 -3：下载中文字幕---无字幕视频救星)

---

### 其他字幕工具

| 脚本 | 功能 | 配置 |
|------|------|------|
| `sub-select.lua` | 自动选择匹配字幕 | `sub_select.conf` |
| `sub_export.lua` | 导出内封字幕 | `sub_export.conf` |
| `sub-fastwhisper.lua` | AI 生成字幕 | `sub_fastwhisper.conf` |
| `sponsorblock_minimal.lua` | 跳过赞助片段 | `sponsorblock_minimal.conf` |

---

## 播放列表管理

### playlistmanager.lua
**功能**：可视化播放列表管理，支持搜索、排序、批量操作。

**快捷键**：
- `Shift + Enter` - 打开播放列表
- `S` - 排序
- `R` - 随机打乱
- `P` - 保存列表

[查看使用指南 →](快速开始.md#场景 -7：整理播放列表---批量管理)

---

### 其他播放列表脚本

| 脚本 | 功能 | 配置 |
|------|------|------|
| `quality-menu.lua` | YouTube 质量选择 | `quality-menu.conf` |
| `recentmenu.lua` | 最近播放记录 | `recentmenu.conf` |

---

## 书签与历史

### simplebookmark.lua
**功能**：高级书签管理，支持分组、快速槽位、搜索。

**快捷键**：
- `Ctrl + B` - 保存书签
- `B` - 打开书签列表
- `Ctrl + 1~9` - 快速槽位

[查看使用指南 →](快速开始.md#场景 -5：标记精彩片段---书签)

---

### simplehistory.lua
**功能**：播放历史记录，支持续播、搜索、隐身模式。

**快捷键**：
- `H` - 打开历史记录
- `Ctrl + R` - 续播最后一个

[查看使用指南 →](快速开始.md#场景 -4：找回上次观看的视频---历史记录)

---

## 视频处理

| 脚本 | 功能 | 快捷键 |
|------|------|--------|
| `mpv-animated.lua` | 导出 GIF/WebP | `W`/`Shift+W`/`Ctrl+W` |
| `slicing_copy.lua` | 剪切视频片段 | `C`/`A` |
| `smartcopypaste_II.lua` | 复制粘贴链接 | `Ctrl+C`/`Ctrl+V` |

---

## UI 增强

### uosc
**功能**：现代化 OSD 界面。

**配置**：`script-opts/uosc.conf`
```ini
timeline_size=30
controls_size=32
font=Noto Sans CJK SC
```

[查看使用指南 →](快速开始.md#场景 -8：现代化界面---鼠标操作)

---

### 弹幕系统 (uosc_danmaku)
**功能**：多源弹幕支持，自动加载。

**配置**：`script-opts/uosc_danmaku.conf`
```ini
api_servers=https://api.dandanplay.net
auto_load=yes
```

**快捷键**：`J` - 弹幕开关

---

### 其他 UI 增强

| 脚本 | 功能 |
|------|------|
| `thumbfast.lua` | 缩略图生成 |
| `dyn_menu.lua` | 动态菜单 |
| `trackselect.lua` | 智能轨道选择 |

---

## 网络功能

| 脚本 | 功能 | 配置 |
|------|------|------|
| `webui` | 浏览器远程控制 | `webui.conf` |
| `mpv_torrserver` | 种子流媒体 | `mpv_torrserver.conf` |
| `trakt_scrobble` | Trakt 观看记录 | `trakt_scrobble.conf` |

---

## 🎨 着色器推荐

### 动漫视频
```ini
glsl-shaders="~~/shaders/Anime4K/Anime4K_Upscale_Denoise_x2.glsl"
```

### 实拍视频
```ini
glsl-shaders="~~/shaders/SSim/SSimSuperRes.glsl"
```

**更多着色器**：查看 `shaders/` 目录。

---

## 🔗 链接

- [5 分钟快速上手](快速开始.md)
- [项目主页](../README.md)
- [mpv 官方文档](https://mpv.io/manual/master/)

---

**返回**：[🏠 项目主页](../README.md) | [🚀 快速开始](快速开始.md)
