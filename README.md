# MPV 播放器配置

> 🎬 基于多家优秀配置整合的现代化 MPV 播放器配置方案

[![Releases](https://img.shields.io/github/v/release/gaoxing64/MPV-lazy-full)](https://github.com/gaoxing64/MPV-lazy-full/releases)

---

## 开始使用


| 文档 | 内容 | 适合人群 |
|------|------|----------|
| [📖 5 分钟快速上手](scripts/快速开始.md) | 基础操作、8 个高频使用场景、快捷键速查 | **所有新用户** |
| [📚 完整脚本文档](scripts/README.md) | 41 个脚本功能详解、配置参考 | 进阶用户 |

### 安装

#### 方法一：便携版（推荐）

1. 从 [Releases](https://github.com/gaoxing64/MPV-lazy-full/releases) 下载最新便携包
2. 解压到任意位置
3. 运行 `mpv.exe` 即可使用

#### 方法二：手动安装

```bash
git clone https://github.com/gaoxing64/MPV-lazy-full.git
# 复制 portable_config 到 mpv 配置目录
```

### 可选依赖

| 组件 | 用途 | 推荐度 |
|------|------|--------|
| thumbfast | 进度条缩略图预览 | ⭐⭐⭐⭐⭐ |
| yt-dlp | YouTube 质量选择 | ⭐⭐⭐⭐ |
| ffmpeg | 字幕导出、视频裁剪 | ⭐⭐⭐ |

---

## ✨ 核心功能

### 🎬 播放控制
- **自动连播** - 打开一集自动加载整季动画
- **跳过片头片尾** - 智能检测 OP/ED，一次标记整季通用
- **智能快进** - 轻按跳转，长按加速，字幕出现自动减速
- **自动保存** - 定期保存播放进度，防止意外丢失

### 🈶 字幕与弹幕
- **在线字幕下载** - 射手网一键搜索下载中文字幕
- **AI 字幕生成** - faster-whisper 自动生成字幕
- **弹幕系统** - 多源 API 支持，自动加载、简繁转换
- **智能字幕选择** - 根据音频自动匹配原声字幕

### 📋 播放管理
- **播放列表管理** - 可视化浏览、搜索、排序、批量操作
- **书签系统** - 分组管理、快速槽位、标记精彩片段
- **历史记录** - 续播功能、隐身模式、跨设备同步

### 🎨 界面增强
- **现代化 UI** - uosc 提供极简美观的播放器界面
- **缩略图预览** - 拖动进度条显示实时预览
- **HDR 自动切换** - Windows 自动切换显示器 HDR 模式

### 🎥 视频处理
- **GIF/WebP 导出** - 截取视频片段制作动图
- **快速剪切** - 流复制无损剪切视频
- **自动裁剪** - 智能检测并裁剪黑边

### 🌐 网络功能
- **种子播放** - TorrServer 直接播放种子文件
- **远程控制** - WebUI 手机/平板远程操作
- **观看记录** - Trakt.tv 自动同步观看统计

---

## ⌨️ 常用快捷键

| 功能 | 快捷键 | 说明 |
|------|--------|------|
| **播放控制** | | |
| 播放/暂停 | `空格` | 切换播放状态 |
| 快进/倒带 | `→` / `←` | 长按可加速播放 |
| 音量调节 | `↑` / `↓` | 增减音量 |
| 全屏切换 | `F` / `Enter` | 全屏/窗口切换 |
| **功能菜单** | | |
| 播放列表 | `Shift + Enter` | 打开播放列表 |
| 历史记录 | `H` | 查看播放历史 |
| 书签列表 | `B` | 打开书签菜单 |
| 保存书签 | `Ctrl + B` | 保存当前书签 |
| 字幕搜索 | `S` | 下载中文字幕 |
| 弹幕开关 | `J` | 切换弹幕显示 |

**完整快捷键表**：[📖 快速开始指南 - 快捷键速查](scripts/快速开始.md#-快捷键速查表)

---

## 📁 目录结构

```
portable_config/
├── mpv.conf              # 主配置文件
├── input.conf            # 快捷键配置
├── scripts/              # Lua 脚本目录
│   ├── 快速开始.md        # 📖 5 分钟上手指南（新手必读）
│   └── README.md         # 📚 完整脚本功能文档
├── shaders/              # 视频增强着色器
│   ├── Anime4K/         # 动漫超分
│   ├── SSim/            # 质量增强
│   └── ...              # 更多着色器
├── script-opts/          # 脚本配置目录（可修改）
│   ├── uosc.conf        # 界面配置
│   ├── chapterskip.conf # 跳过片头片尾
│   └── ...              # 各脚本配置
├── files/                # 运行数据（自动生成）
│   ├── mpvHistory.log   # 历史记录
│   └── mpvBookmark.log  # 书签数据
└── fonts/                # 字体文件
```

---

## 🔧 配置说明

### 修改配置

1. 用文本编辑器打开 `script-opts/` 下对应的 `.conf` 文件
2. 修改参数值
3. 保存后**即时生效**（部分需重新加载视频）

### 核心配置文件

| 配置文件 | 功能 | 推荐修改 |
|----------|------|----------|
| `uosc.conf` | 界面样式 | 字体、颜色、进度条大小 |
| `uosc_danmaku.conf` | 弹幕设置 | API 服务器、自动加载 |
| `chapterskip.conf` | 跳过片头片尾 | 跳过模式 |
| `evafast.conf` | 智能快进 | 速度上限 |
| `sub_assrt.conf` | 字幕下载 | **API Token（必需）** |
| `autoload.conf` | 自动加载 | 文件类型、子目录模式 |

**配置详解**：[📚 完整脚本文档 - 配置参考](scripts/README.md#-配置参考)

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

**更多配置**：[📚 完整脚本文档 - 着色器推荐](scripts/README.md#-着色器推荐)

---

## ❓ 常见问题

**Q: 弹幕不显示？**
A: 检查 `uosc_danmaku.conf` API 配置，按 `J` 确认弹幕开关已打开。

**Q: 字幕下载失败？**
A: 需在 `sub_assrt.conf` 填入 [射手网](https://assrt.net) API Token。

**Q: 为什么不自动连播？**
A: 检查 `autoload.conf` 中 `disabled=no` 和 `videos=yes`。

**Q: 界面卡顿？**
A: 在 `uosc.conf` 设置 `animation_enable=no` 禁用动画。

**更多问题**：[📖 快速开始指南 - 常见问题](scripts/快速开始.md#-常见问题)

---

## 📦 项目来源

本配置整合了以下优秀开源项目：

| 组件 | 来源 | 许可证 |
|------|------|--------|
| 主配置 | [dyphire/mpv-config](https://github.com/dyphire/mpv-config) | MIT |
| 弹幕系统 | [Loukyuu1120/uosc_danmaku](https://github.com/Loukyuu1120/uosc_danmaku) | MIT |
| 着色器包 | [hooke007/mpv_PlayKit](https://github.com/hooke007/mpv_PlayKit) | MIT |
| uosc 界面 | [tomasklaen/uosc](https://github.com/tomasklaen/uosc) | MIT |

各组件遵循原有开源许可证。

---

## 🔗 参考链接

- [📖 5 分钟快速上手](scripts/快速开始.md) - 新手入门指南
- [📚 完整脚本文档](scripts/README.md) - 41 个脚本详细说明
- [mpv 官方文档](https://mpv.io/manual/master/)
- [uosc 文档](https://github.com/tomasklaen/uosc)
- [弹幕系统文档](https://github.com/Loukyuu1120/uosc_danmaku)

---

## 🙏 致谢

感谢以下项目的作者和维护者：

- [@dyphire](https://github.com/dyphire) - mpv-config 主配置
- [@Loukyuu1120](https://github.com/Loukyuu1120) - uosc_danmaku 弹幕系统
- [@hooke007](https://github.com/hooke007) - mpv_PlayKit 着色器包
- [@tomasklaen](https://github.com/tomasklaen) - uosc 界面框架
- 所有贡献者和社区成员

---

**提示**：遇到问题请先查看 [📖 快速开始指南](scripts/快速开始.md) 和 [📚 完整文档](scripts/README.md)。
