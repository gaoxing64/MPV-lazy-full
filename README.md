# MPV 播放器配置

> 基于多家优秀配置整合的现代化 MPV 播放器配置方案

## 📦 项目来源

本配置整合了以下优秀开源项目：

| 组件 | 来源 | 说明 |
|------|------|------|
| **主配置** | [dyphire/mpv-config](https://github.com/dyphire/mpv-config.git) | 核心配置文件、脚本管理器 |
| **弹幕系统** | [Loukyuu1120/uosc_danmaku](https://github.com/Loukyuu1120/uosc_danmaku) | 新增 api_servers 配置
| **着色器包** | [hooke007/mpv_PlayKit](https://github.com/hooke007/mpv_PlayKit) | 视频增强着色器集合 |

## ✨ 主要特性

### 🎨 用户界面
- **uosc** - 现代化极简 OSD 界面，支持：
  -  proximity-based 元素显示（鼠标靠近时显示）
  - 可最小化的时间线进度条
  - 缩略图预览（需配合 thumbfast）
  - 可自定义的轨道/章节/播放列表菜单
  - 音量/速度控制条

### 🎬 弹幕功能
- **多源弹幕支持**
  - 弹弹 Play API（默认）
  - 哔哩哔哩弹幕
  - 巴哈姆特弹幕
  - 自定义多个 API 服务器
- **弹幕管理**
  - 弹幕来源切换菜单
  - 弹幕开关控制
  - 弹幕延迟独立调节
  - 弹幕样式实时修改
  - 弹幕搜索与下载
  - 弹幕简繁转换
  - 重复弹幕合并
- **自动加载**
  - 文件哈希匹配
  - 同目录自动关联
  - 网络视频弹幕支持
  - 历史记录记忆

### 🎯 播放增强
- **智能跳过** - 自动检测并跳过片头片尾（chapterskip）
- **智能快进** - 长按加速、字幕检测限速（evafast）
- **自动加载** - 自动加载目录中的系列文件到播放列表
- **书签管理** - 支持分组、快捷键、搜索的书签系统
- **历史记录** - 播放历史管理器，支持续播
- **字幕工具** - 射手网字幕下载、AI 字幕生成

### 🖼️ 视频处理
- **着色器支持**（来自 mpv_PlayKit）：
  - **Anime4K** - 动漫视频超分辨率
  - **RAISR** - Intel 机器学习放大算法
  - **SSim** - SSimSuperRes/SSimDownscaler 质量增强
  - **USM** - 锐化滤镜集合
  - **Nlmeans** - 降噪滤镜
  - **Deint** - 去交错滤镜
  - **WarpSharp** - 边缘锐化
  - 更多专业着色器...

### 🌐 网络功能
- **TorrServer** - 种子流媒体播放支持
- **WebUI** - 浏览器远程控制界面
- **SponsorBlock** - YouTube/B 站赞助片段跳过

## 📁 目录结构

```
portable_config/
├── mpv.conf              # 主配置文件
├── input.conf            # 快捷键配置
├── scripts/              # Lua 脚本目录
│   ├── uosc/            # 主界面脚本
│   ├── uosc_danmaku/    # 弹幕脚本
│   ├── chapterskip/     # 片头片尾跳过
│   ├── evafast/         # 智能快进
│   ├── autoload/        # 自动加载
│   ├── playlistmanager/ # 播放列表管理
│   ├── simplebookmark/  # 书签管理
│   ├── simplehistory/   # 历史记录
│   └── ...              # 更多功能脚本
├── shaders/             # 着色器目录
│   ├── Anime4K/        # 动漫超分着色器
│   ├── RAISR/          # Intel RAISR 算法
│   ├── SSim/           # SSim 质量滤镜
│   ├── USM/            # 锐化滤镜
│   ├── nlmeans/        # 降噪滤镜
│   └── ...             # 更多着色器
├── script-opts/        # 脚本配置目录
│   ├── uosc.conf
│   ├── uosc_danmaku.conf
│   ├── chapterskip.conf
│   └── ...             # 各脚本配置文件
├── fonts/              # 字体文件
└── icc/                # 色彩配置文件
```

## 🚀 快速开始

### 安装

1. **下载完整便携包**
   - 从本仓库的 [Releases](https://github.com/gaoxing64/MPV-lazy-full/releases) 下载最新版便携包
   - 解压到任意位置即可使用

2. **可选依赖**（按需安装）
   - **thumbfast** - 缩略图预览（强烈推荐）
   - **yt-dlp** - YouTube 质量选择
   - **ffmpeg** - 字幕导出、视频裁剪等功能

### 基础配置

#### 1. 弹幕配置

编辑 `script-opts/uosc_danmaku.conf`：

```ini
# API 配置（多个服务器用逗号分隔）
api_servers=https://api.dandanplay.net,https://your-custom-api.com

# 自动加载弹幕
auto_load=yes
autoload_for_url=yes
autoload_local_danmaku=yes

# 弹幕显示
opacity=0.7
chConvert=0          # 简繁转换：0-不转换 1-转简体 2-转繁体
merge_tolerance=1    # 合并重复弹幕（秒）
```

#### 2. uosc 界面配置

编辑 `script-opts/uosc.conf`：

```ini
# 时间线配置
timeline_enable=yes
timeline_size=20
timeline_thumbnail=yes    # 需 thumbfast

# 控制按钮
controls_enable=yes
controls_buttons=play_pause,cycle_audio,cycle_sub,menu

# 颜色配置
foreground=ffffff
background=000000
accent=58a6ff
```

#### 3. 着色器配置

在 `mpv.conf` 中添加：

```ini
# 动漫视频推荐配置
profile=anime
video-sync=display-resample
interpolation=yes
tscale=oversample

# 着色器链示例
glsl-shaders="~~/shaders/Anime4K/Anime4K_Denoise_Bilateral_Mean.glsl:~~/shaders/Anime4K/Anime4K_Upscale_Denoise_x2.glsl"
```

## ⌨️ 常用快捷键

| 功能 | 快捷键 | 说明 |
|------|--------|------|
| **播放控制** | | |
| 播放/暂停 | `SPACE` | 切换播放状态 |
| 快进/倒带 | `→` / `←` | 支持长按加速 |
| 音量调节 | `↑` / `↓` | 增减音量 |
| 全屏切换 | `F` / `DBLCLK` | 全屏/窗口切换 |
| **界面** | | |
| 播放列表 | `SHIFT+ENTER` | 打开播放列表管理器 |
| 历史记录 | `H` | 查看播放历史 |
| 书签列表 | `B` | 打开书签管理器 |
| 保存书签 | `CTRL+B` | 保存当前书签 |
| **弹幕** | | |
| 弹幕开关 | `J` | 切换弹幕显示 |
| 弹幕搜索 | `CTRL+D` | 搜索并加载弹幕 |
| 弹幕来源 | `CTRL+C` | 切换弹幕来源 |
| **字幕** | | |
| 字幕搜索 | `S` | 从射手网下载字幕 |
| 切换字幕 | `V` | 循环切换字幕轨道 |
| **视频** | | |
| 章节跳过 | `SHIFT+S` | 切换跳过模式 |
| 截图 | `S` | 截取当前帧 |
| 循环 A-B | `L` | 设置循环区间 |

## 📋 脚本配置

所有脚本配置文件位于 `script-opts/` 目录，主要配置项：

| 脚本 | 配置文件 | 功能 |
|------|----------|------|
| uosc | `uosc.conf` | 界面样式、行为配置 |
| uosc_danmaku | `uosc_danmaku.conf` | 弹幕 API、自动加载配置 |
| chapterskip | `chapterskip.conf` | 片头片尾跳过规则 |
| evafast | `evafast.conf` | 快进速度、字幕限速 |
| autoload | `autoload.conf` | 自动加载文件类型 |
| playlistmanager | `playlistmanager.conf` | 播放列表管理配置 |
| simplebookmark | `simplebookmark.conf` | 书签保存、分组配置 |
| simplehistory | `simplehistory.conf` | 历史记录数量、排序 |
| sub-assrt | `sub-assrt.conf` | 字幕下载 API 配置 |

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

## 🔧 高级功能

### 弹幕高级配置

#### 多 API 源配置
```ini
# 优先级从高到低排列
api_servers=https://api.dandanplay.net,https://your-api.com,https://backup-api.com
```

#### 弹幕来源切换
在 uosc 控制栏添加来源切换按钮：
```ini
# uosc.conf
controls=...,command:comment:script-message open_danmaku_source_menu?选择弹幕来源,...
```

#### 弹幕预匹配
```ini
# 开启后菜单响应更快
autoload_danmaku_matches=yes
```

### 自定义着色器链

编辑 `mpv.conf` 创建场景配置：

```ini
# 动漫高画质配置
[anime-hq]
profile-desc="Anime High Quality"
glsl-shaders="~~/shaders/Anime4K/Anime4K_Denoise_Bilateral_Mean.glsl:~~/shaders/Anime4K/Anime4K_Upscale_Denoise_x2.glsl:~~/shaders/Anime4K/Anime4K_Restore_CNN_VL.glsl"
video-sync=display-resample
interpolation=yes

# 电影模式
[movie]
profile-desc="Movie Watching"
glsl-shaders="~~/shaders/SSim/SSimSuperRes.glsl"
deband=yes
```

## 🐛 常见问题

### 弹幕不显示
1. 检查 `uosc_danmaku.conf` 中 API 配置是否正确
2. 确认网络可以访问 API 服务器
3. 按 `CTRL+D` 手动搜索弹幕
4. 检查弹幕开关（按 `J` 切换）

### 界面卡顿
1. 在 `mpv.conf` 中添加 `video-sync=display-resample`
2. 禁用 uosc 动画：`uosc.conf` 设置 `animation_enable=no`
3. 减少时间线缩略图缓存

### 着色器不生效
1. 确认 mpv 使用 `gpu` 或 `gpu-next` 输出
2. 检查着色器路径是否正确
3. 禁用硬件解码或使用 `*-copy` 模式

### 字幕下载失败
1. 检查 `sub-assrt.conf` 中 API Token 是否有效
2. 确认网络可以访问 assrt.net
3. 尝试手动搜索关键词

## 📚 参考链接

- [MPV Lazy文档](https://github.com/hooke007/mpv_PlayKit/wiki)
- [uosc 文档](https://github.com/tomasklaen/uosc)
- [uosc_danmaku 文档](https://github.com/Loukyuu1120/uosc_danmaku)
- [mpv_PlayKit 着色器](https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL)
- [dyphire/mpv-config](https://github.com/dyphire/mpv-config)

## 📄 许可证

本项目整合的组件遵循各自原有的开源许可证：
- mpv-config: MIT License
- uosc_danmaku: MIT License
- mpv_PlayKit 着色器：MIT License

## 🙏 致谢

感谢以下项目的作者和维护者：
- [@dyphire](https://github.com/dyphire) - mpv-config 主配置
- [@Loukyuu1120](https://github.com/Loukyuu1120) - uosc_danmaku 弹幕系统
- [@hooke007](https://github.com/hooke007) - mpv_PlayKit 着色器包
- [@tomasklaen](https://github.com/tomasklaen) - uosc 界面框架
- 所有贡献者和社区成员

---
