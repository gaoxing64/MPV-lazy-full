# MPV 播放器配置

> 现代化 MPV 播放器配置方案

[![Releases](https://img.shields.io/github/v/release/gaoxing64/MPV-lazy-full)](https://github.com/gaoxing64/MPV-lazy-full/releases)

---

## 开始使用

### 新手必读

| 文档 | 内容 |
|------|------|
| [5 分钟快速上手](scripts/快速开始.md) | 8 个常用场景，快捷键，常见问题 |
| [完整脚本文档](scripts/README.md) | 41 个脚本功能详解，配置参考 |

### 安装

**便携版（推荐）**：
1. [Releases](https://github.com/gaoxing64/MPV-lazy-full/releases) 下载便携包
2. 解压到任意位置
3. 运行 `mpv.exe`

**手动安装**：
```bash
git clone https://github.com/gaoxing64/MPV-lazy-full.git
```

### 可选依赖

| 组件 | 用途 |
|------|------|
| thumbfast | 进度条缩略图 |
| yt-dlp | YouTube 质量选择 |
| ffmpeg | 字幕导出、视频裁剪 |

---

## 核心功能

**播放控制**
- 自动连播 - 打开一集加载整季
- 跳过片头片尾 - 智能检测 OP/ED
- 智能快进 - 长按加速，字幕限速
- 自动保存 - 定期保存进度

**字幕弹幕**
- 在线字幕 - 射手网一键下载
- AI 字幕 - faster-whisper 生成
- 弹幕系统 - 多源 API 支持

**播放管理**
- 播放列表 - 可视化浏览、搜索、排序
- 书签系统 - 分组管理、快速槽位
- 历史记录 - 续播、隐身模式

**界面增强**
- uosc - 现代化 OSD 界面
- 缩略图预览 - 拖动显示画面
- HDR 切换 - Windows 自动切换

**视频处理**
- GIF/WebP 导出 - 截取片段
- 快速剪切 - 流复制无损
- 自动裁剪 - 检测黑边

**网络功能**
- 种子播放 - TorrServer 支持
- 远程控制 - WebUI
- 观看记录 - Trakt.tv 同步

---

## 常用快捷键

| 功能 | 按键 |
|------|------|
| 播放/暂停 | `空格` |
| 快进/快退 | `→` / `←` |
| 音量 | `↑` / `↓` |
| 全屏 | `F` |
| 播放列表 | `Shift + Enter` |
| 历史记录 | `H` |
| 书签 | `B` |
| 保存书签 | `Ctrl + B` |
| 字幕搜索 | `S` |
| 弹幕 | `J` |

**完整表**：[scripts/快速开始.md#快捷键](scripts/快速开始.md#快捷键)

---

## 目录结构

```
portable_config/
├── mpv.conf              # 主配置
├── input.conf            # 快捷键
├── scripts/              # 脚本
│   ├── 快速开始.md        # 新手教程
│   └── README.md         # 完整文档
├── shaders/              # 着色器
├── script-opts/          # 脚本配置
└── files/                # 运行数据
```

---

## 配置说明

**修改配置**：
1. 编辑 `script-opts/` 下对应 `.conf` 文件
2. 修改参数
3. 保存即生效

**核心配置**：

| 文件 | 功能 |
|------|------|
| `uosc.conf` | 界面样式 |
| `uosc_danmaku.conf` | 弹幕设置 |
| `chapterskip.conf` | 跳过片头片尾 |
| `evafast.conf` | 智能快进 |
| `sub_assrt.conf` | 字幕下载（需 API Token） |
| `autoload.conf` | 自动加载 |

**详解**：[scripts/README.md#-配置参考](scripts/README.md#-配置参考)

---

## 着色器推荐

**动漫**：
```ini
glsl-shaders="~~/shaders/Anime4K/Anime4K_Upscale_Denoise_x2.glsl"
```

**实拍**：
```ini
glsl-shaders="~~/shaders/SSim/SSimSuperRes.glsl"
```

**更多**：[scripts/README.md#-着色器推荐](scripts/README.md#-着色器推荐)

---

## 常见问题

**Q: 弹幕不显示？**  
A: 检查 `uosc_danmaku.conf` API 配置，按 `J` 打开弹幕。

**Q: 字幕下载失败？**  
A: 在 `sub_assrt.conf` 填入 [射手网](https://assrt.net) API Token。

**Q: 不自动连播？**  
A: 检查 `autoload.conf` 中 `disabled=no`。

**Q: 界面卡顿？**  
A: `uosc.conf` 设置 `animation_enable=no`。

**更多**：[scripts/快速开始.md#常见问题](scripts/快速开始.md#常见问题)

---

## 项目来源

| 组件 | 来源 |
|------|------|
| 主配置 | [dyphire/mpv-config](https://github.com/dyphire/mpv-config) |
| 弹幕 | [Loukyuu1120/uosc_danmaku](https://github.com/Loukyuu1120/uosc_danmaku) |
| 着色器 | [hooke007/mpv_PlayKit](https://github.com/hooke007/mpv_PlayKit) |
| uosc | [tomasklaen/uosc](https://github.com/tomasklaen/uosc) |

---

## 链接

- [5 分钟快速上手](scripts/快速开始.md)
- [完整脚本文档](scripts/README.md)
- [mpv 官方文档](https://mpv.io/manual/master/)

---

**提示**：遇到问题先查看 [快速上手](scripts/快速开始.md) 和 [完整文档](scripts/README.md)。
