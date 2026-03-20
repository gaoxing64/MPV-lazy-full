# MPV Config (Windows)

这是一个针对 Windows 平台的 [mpv 播放器](https://github.com/mpv-player/mpv) 的完整配置项目。

## 项目介绍

本仓库为 Windows 下 [mpv](https://github.com/mpv-player/mpv) 播放器提供的配置方案，适用于追求高质量视频播放体验的用户。包含了详细的视频、音频、字幕、着色器、界面配置，以及丰富的脚本扩展功能。

### 特色功能

- **高质量视频渲染**：支持 HDR 映射、多种缩放算法、抖动处理等高级特性
- **全面的解码支持**：包括硬解、软解以及多种解码器配置
- **丰富的着色器系统**：集成大量高性能的着色器，支持 AI 超分、降噪等
- **智能条件配置**：根据不同视频特性(分辨率、格式、HDR等)自动应用相应配置
- **完善的脚本生态**：集成了众多第三方脚本，提供浏览器、字幕、播放列表等扩展功能

## 配置结构

```
portable_config/
├── scripts/              # 第三方脚本 (.lua)
│   ├── uosc/            # 现代化界面控制器
│   ├── file-browser/    # 文件浏览器
│   ├── playlistmanager/ # 播放列表管理器
│   ├── sub-assrt/       # 字幕下载脚本
│   └── etc...           # 其他脚本
├── script-opts/          # 脚本配置文件 (.conf)
├── script-modules/       # 脚本模块
├── osc-style/            # OSC主题
├── shaders/              # GLSL视频着色器
│   ├── Anime4K/         # Anime4K系列着色器
│   ├── igv/             # IGV着色器
│   ├── ravu/            # Ravu放大算法着色器
│   └── etc...           # 其他着色器
├── vs/                   # VapourSynth脚本
├── fonts/                # 字体目录
├── icc/                  # ICC色彩配置文件目录
├── cache/                # 缓存目录
├── files/                # 文件输出目录
├── mpv.conf             # 主配置文件
├── input.conf           # 键位绑定配置
├── menu.conf            # 菜单配置
├── manager.json         # 脚本管理器源配置
└── README.md            # 说明文档
```

## 安装方式

### 方法一：便携配置模式（推荐）

1. 将 `portable_config` 文件夹放在 `mpv.exe` 所在目录下
2. 配置会在便携模式下自动生效，并覆盖全局设置

### 方法二：全局配置模式

1. 将配置放在 mpv 的默认配置路径 `%APPDATA%/mpv/`
2. 重启 mpv 即可生效

**注意**：自行编辑配置文件时，编码格式应为 UTF-8，换行符为 Unix 风格，否则 mpv 可能无法识别。

## 主要配置特性

### 视频渲染配置

- 使用 gpu-next 作为默认视频输出驱动
- 支持 Direct3D 11, Vulkan, OpenGL 图形API
- 硬件加速配置，支持 D3D11VA, NVDEC 等硬件解码
- 高级缩放算法（ewa_lanczos、ewa_hanning等）
- 专业的 HDR tone mapping 设置
- 多种去色带、抗锯齿选项

### 音频配置

- WACAPI 输出驱动（Windows平台推荐）
- 多声道音频支持
- 音速调整与音高校正
- 软件音效处理

### 字幕配置

- 多语言支持（中文、日文等）
- 字幕编码处理（自动、GB18030等）
- 图形字幕渲染（PGS、VobSub等）
- 强大的 ASS 字幕处理器

### 界面配置

- 禁用了原生 OSC（On-Screen Controller）
- 基于 uosc 的现代化界面（位于 scripts/uosc/）
- 高度定制化 OSD 信息

## 着色器系统

项目集成的着色器支持：

- **超分辨率**：使用 Anime4K, FSRCNNX, RAVU, NNEDI3 等算法
- **降噪**：各种高级降噪着色器
- **细节增强**：SSimSuperRes 用于细节保持
- **色度升频**：KrigBilateral 提供高级色彩升频
- **抗振铃**：减少图像放大时的振铃效应

## 脚本功能

主要集成功能包括：

- **文件管理**：集成文件浏览器与播放列表管理器
- **字幕处理**：下载、同步、AI生成字幕
- **历史记录**：播放记录管理与书签功能
- **质量选择**：YouTube-DL 视频质量选择器
- **智能裁剪**：动态黑边去除功能
- **音频同步**：自动音频同步功能

### 特色脚本

- `uosc`：现代化用户界面
- `uosc_danmaku`：弹弹Play弹幕系统，支持多API源切换与弹幕来源选择菜单
- `simple-history`：播放历史管理
- `sub-assrt`：在线字幕下载
- `autosubsync`：音频字幕同步
- `smartcopypaste`：剪切板功能扩展
- `dynamic-crop`：自动黑边裁剪

## 使用技巧

1. **播放控制**：使用 `hjkl` 快捷键进行基本播放控制
2. **画面调整**：使用鼠标滚轮调整音量/亮度
3. **字幕操作**：`j/k/v` 切换字幕轨及开关
4. **视频滤镜**：`CTRL+数字` 快速切换着色器
5. **配置切换**：`ALT+数字` 应用预设配置组

## 自定义配置

本配置使用了大量的条件配置组（Profiles），可根据不同情况进行定制：

- **分辨率识别**：针对 SD/HD/4K 内容优化配置
- **HDR 处理**：自动识别并应用 HDR 或 HDR-PASS 参数
- **音频设备**：根据音频通道数自动调整处理
- **窗口状态**：根据全屏、窗口化、最小化状态自动调整

## 客户端兼容性

### 推荐的 MPV 客户端

- [shinchiro 版 mpv](https://github.com/shinchiro/mpv-winbuild-cmake) - Windows 平台知名版本
- [zhongfly mpv](https://github.com/zhongfly/mpv-winbuild) - 每日构建版本
- [dyphire mpv](https://github.com/dyphire/mpv-winbuild) - 基于修改版 mpv 的构建

### 相关前端

- **mpv.net** - Windows 下流行的 libmpv GUI 前端
- **umpv** - 单实例模式插件

### 外部集成

- [mpv-handler](https://github.com/akiirui/mpv-handler) - 浏览器集成播放

## 预览图

![播放界面预览1](https://cdn.jsdelivr.net/gh/dyphire/PicGo/img/2023/11/03/image-20231103224421000.png)

![播放界面预览2](https://cdn.jsdelivr.net/gh/dyphire/PicGo/img/2023/11/03/image-20231103224540075.png)

![播放界面预览3](https://cdn.jsdelivr.net/gh/dyphire/PicGo/img/2023/11/03/image-20231103224557019.png)

## 维护与同步

- 本项目的脚本通过 `manager.lua` 和 `manager.json` 自动管理更新
- 包含来自 GitHub 和 Gist 的多个开源项目
- 定期维护以保持功能更新和 bug 修复

## 技术参考

- [mpv 官方手册](https://mpv.io/manual/master/)
- [hooke007 配置手册](https://hooke007.github.io/mpv-lazy/mpv.html)
- [mpv 中国社区](https://github.com/hooke007/mpv_doc-CN)

## 许可证说明

- 本项目主要整合了多种开源脚本和着色器
- 每个组件的许可证信息通常在其源文件内部注明
- 项目整体按照原作者 dyphire 的许可证约定执行

## 更新日志

此配置基于原作者的持续更新维护，包含大量高级设置和优化方案，适合对视频播放质量有高要求的专业用户使用。

**原作者**：dyphire
**原仓库**：[dyphire/mpv-config](https://github.com/dyphire/mpv-config)
