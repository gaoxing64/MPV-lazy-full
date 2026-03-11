# MPV 播放器配置

> 基于多家优秀配置整合的现代化 MPV 播放器配置方案

[![Releases](https://img.shields.io/github/v/release/gaoxing64/MPV-lazy-full)](https://github.com/gaoxing64/MPV-lazy-full/releases)

## 🚀 快速开始

**新手用户**：请阅读 [📖 快速开始指南](scripts/快速开始.md)

**完整文档**：[📚 详细使用说明](scripts/README.md)

## ✨ 核心功能

- **现代化界面** - uosc 极简 UI，支持缩略图预览、进度条、音量控制
- **弹幕支持** - 多源弹幕 API，自动加载、简繁转换、弹幕管理
- **智能播放** - 自动连播、跳过片头片尾、字幕限速快进
- **学习工具** - 书签管理、历史记录、续播功能
- **字幕下载** - 射手网在线搜索，一键下载加载
- **视频增强** - Anime4K、SSim、RAISR 等着色器支持
- **网络功能** - TorrServer 种子播放、SponsorBlock 广告跳过

## 📦 安装

### 方法一：便携版（推荐）

1. 从 [Releases](https://github.com/gaoxing64/MPV-lazy-full/releases) 下载最新便携包
2. 解压到任意位置
3. 运行 `mpv.exe` 即可使用

### 方法二：手动安装

```bash
git clone https://github.com/gaoxing64/MPV-lazy-full.git
cd MPV-lazy-full/portable_config
# 复制 portable_config 到 mpv 配置目录
```

### 可选依赖

| 组件 | 用途 | 推荐度 |
|------|------|--------|
| thumbfast | 进度条缩略图预览 | ⭐⭐⭐⭐⭐ |
| yt-dlp | YouTube 质量选择 | ⭐⭐⭐⭐ |
| ffmpeg | 字幕导出、视频裁剪 | ⭐⭐⭐ |

## 📁 目录结构

```
portable_config/
├── mpv.conf              # 主配置文件
├── input.conf            # 快捷键配置
├── scripts/              # Lua 脚本
│   ├── 快速开始.md        # 5 分钟上手指南
│   └── README.md         # 完整功能文档
├── shaders/              # 视频增强着色器
├── script-opts/          # 脚本配置（可修改）
└── files/                # 运行数据（自动生成）
```

## ⌨️ 常用快捷键

| 功能 | 快捷键 | 说明 |
|------|--------|------|
| 播放/暂停 | `空格` | 切换播放状态 |
| 快进/倒带 | `→` / `←` | 长按可加速播放 |
| 播放列表 | `Shift + Enter` | 打开播放列表 |
| 历史记录 | `H` | 查看播放历史 |
| 书签列表 | `B` | 打开书签菜单 |
| 字幕搜索 | `S` | 下载中文字幕 |
| 弹幕开关 | `J` | 切换弹幕显示 |

**完整快捷键表**：见 [📖 快速开始指南 - 快捷键速查](scripts/快速开始.md#-快捷键速查表)

## 🎨 着色器推荐

### 动漫视频
```ini
glsl-shaders="~~/shaders/Anime4K/Anime4K_Upscale_Denoise_x2.glsl"
```

### 实拍视频
```ini
glsl-shaders="~~/shaders/SSim/SSimSuperRes.glsl"
```

**更多着色器配置**：见 [📚 详细说明 - 着色器推荐](scripts/README.md#-着色器推荐)

## 🔧 配置说明

所有脚本配置文件位于 `script-opts/` 目录：

| 配置文件 | 功能 | 推荐修改 |
|----------|------|----------|
| `uosc.conf` | 界面样式 | 字体、颜色、进度条大小 |
| `uosc_danmaku.conf` | 弹幕设置 | API 服务器、自动加载 |
| `chapterskip.conf` | 跳过片头片尾 | 跳过模式 |
| `evafast.conf` | 智能快进 | 速度上限 |
| `sub_assrt.conf` | 字幕下载 | API Token（必需） |

**配置修改后即时生效**，部分功能需重新加载视频。

## 🐛 常见问题

**Q: 弹幕不显示？**  
A: 检查 `uosc_danmaku.conf` API 配置，按 `J` 确认弹幕开关已打开。

**Q: 字幕下载失败？**  
A: 需在 `sub_assrt.conf` 填入 [射手网](https://assrt.net) API Token。

**Q: 界面卡顿？**  
A: 在 `uosc.conf` 设置 `animation_enable=no` 禁用动画。

**更多问题**：见 [📚 详细说明 - 常见问题](scripts/README.md#-常见问题)

## 🔗 参考链接

- [📖 5 分钟快速上手](scripts/快速开始.md) - 新手必读
- [📚 完整功能文档](scripts/README.md) - 详细使用说明
- [uosc 文档](https://github.com/tomasklaen/uosc)
- [弹幕系统](https://github.com/Loukyuu1120/uosc_danmaku)

## 📄 项目来源

本配置整合了以下优秀开源项目：

| 组件 | 来源 |
|------|------|
| 主配置 | [dyphire/mpv-config](https://github.com/dyphire/mpv-config) |
| 弹幕系统 | [Loukyuu1120/uosc_danmaku](https://github.com/Loukyuu1120/uosc_danmaku) |
| 着色器包 | [hooke007/mpv_PlayKit](https://github.com/hooke007/mpv_PlayKit) |

各组件遵循原有开源许可证（MIT）。

## 🙏 致谢

感谢 [@dyphire](https://github.com/dyphire)、[@Loukyuu1120](https://github.com/Loukyuu1120)、[@hooke007](https://github.com/hooke007) 等所有贡献者。

---

**提示**：遇到问题请先查看 [📖 快速开始指南](scripts/快速开始.md) 和 [📚 详细文档](scripts/README.md)。
