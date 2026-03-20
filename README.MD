# MPV Config (Windows)

这是一个针对 Windows 平台的 [mpv 播放器](https://github.com/mpv-player/mpv) 的完整配置项目。

## 项目介绍

这是一个适用于 Windows 的高质量 [mpv](https://github.com/mpv-player/mpv) 播放器配置方案。包含专业的视频渲染、音频处理、字幕支持和丰富的脚本扩展功能。

## 配置结构

```
portable_config/
├── scripts/              # 第三方脚本 (.lua)
├── script-opts/          # 脚本配置文件 (.conf)
├── script-modules/       # 脚本模块
├── osc-style/            # OSC主题
├── shaders/              # GLSL视频着色器
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

## 主要配置特性

### 音频配置

- WACAPI 输出驱动（Windows平台推荐），支持多声道音频
- 音速调整与音高校正，软件音效处理

### 字幕配置

- 多语言支持（中文、日文等）和多格式字幕渲染
- 智能编码处理和强大的 ASS 字幕处理器

### 界面配置

- 禁用了原生 OSC（On-Screen Controller）
- 基于 uosc 的现代化界面（位于 scripts/uosc/）
- 高度定制化 OSD 信息

## 着色器系统

项目集成了大量高质量的 GLSL 着色器，主要来源于 [hooke007/mpv_PlayKit](https://github.com/hooke007/mpv_PlayKit) 仓库，包括：

- **超分辨率**：Anime4K, FSRCNNX, RAVU, NNEDI3, ArtCNN, CuNNy, ESRGAN, ACNet, AiUpscale 等
- **抗锯齿**：AA 系列抗锯齿着色器
- **降噪**：nlmeans, guided 等高级降噪着色器
- **锐化**：Adaptive_sharpen, USM, WarpSharp 等锐化着色器
- **色彩处理**：CfL, LUT, color 等色彩处理着色器
- **细节增强**：SSimSuperRes 用于细节保持
- **色度升频**：KrigBilateral 优质色度升频算法
- **其他**：Deband, deint, RAISR, MagicKernel 等实用着色器

详细使用说明请参考：[GLSL Wiki](https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL)

## VapourSynth 脚本

项目集成了基于 [LumeCraft-Labs/K7sfunc](https://github.com/LumeCraft-Labs/K7sfunc) 的 VapourSynth 视频处理脚本（位于 `vs/` 目录），这是一个为 mpv 特向优化的 VS 包装器，支持：

- **格式控制**：FMT_CHANGE, FMT_CTRL, FPS_CHANGE, FPS_CTRL 等格式转换模块
- **超分辨率**：ACNET_STD, ARTCNN_NV, CUGAN_NV, EDI_US_STD, NGU_HQ 等AI放大算法
- **运动补偿（补帧）**：MVT_LQ, MVT_MQ, DRBA, RIFE, SVP 等多种补帧算法
- **去块降噪**：DPIR, BILA, BM3D, CCD, DFTT, FFT3D, NLM 等降噪算法
- **其它处理**：CSC_UV, DEBAND, DEINT 等图像处理模块
- **混合功能**：MIX 系列组合模块

详细使用说明请参考：[K7sfunc Wiki](https://github.com/hooke007/mpv_PlayKit/wiki/3_K7sfunc)

## 脚本功能

### 主要功能特性

- **文件管理**：集成文件浏览器与播放列表管理器
- **字幕处理**：下载、同步、AI生成字幕
- **历史记录**：播放记录管理与书签功能
- **实用工具**：YouTube-DL 选择器、智能裁剪、音频同步等功能

### 特色脚本

- `uosc`：现代化用户界面
- `uosc_danmaku`：弹弹Play弹幕系统（[Loukyuu1120 版本](https://github.com/Loukyuu1120/uosc_danmaku)），支持多弹幕源切换与弹幕池选择菜单
- `simple-history`：播放历史管理
- `playlistmanager`：播放列表管理
- `sub-assrt`：在线字幕下载
- `autosubsync`：音频字幕同步
- `file-browser`：文件浏览器

## 使用技巧

- **播放控制**：使用 `hjkl` 快捷键进行基本播放控制
- **字幕操作**：`j/k/v` 切换字幕轨及开关
- **视频滤镜**：`CTRL+数字` 快速切换着色器
- **配置切换**：`ALT+数字` 应用预设配置组

## 自定义配置

配置使用了智能的条件配置组，可根据不同情况进行自动定制：

- **分辨率自适应**：针对 SD/HD/4K 内容应用优化配置
- **HDR 处理**：根据 HDR 信息自动适配输出参数
- **设备状态**：根据窗口状态及音频配置进行参数调整

## 界面预览

![播放界面预览1](https://cdn.jsdelivr.net/gh/dyphire/PicGo/img/2023/11/03/image-20231103224421000.png)

![播放界面预览2](https://cdn.jsdelivr.net/gh/dyphire/PicGo/img/2023/11/03/image-20231103224540075.png)

![播放界面预览3](https://cdn.jsdelivr.net/gh/dyphire/PicGo/img/2023/11/03/image-20231103224557019.png)

## 技术参考

- [mpv 官方手册](https://mpv.io/manual/master/)
- [hooke007 配置手册](https://hooke007.github.io/mpv-lazy/mpv.html)

## 许可证说明

- 本项目主要整合了多种开源脚本和着色器，主要来源于 [hooke007/mpv_PlayKit](https://github.com/hooke007/mpv_PlayKit) 仓库，以及 [LumeCraft-Labs/K7sfunc](https://github.com/LumeCraft-Labs/K7sfunc) 仓库
- 每个组件的许可证信息通常在其源文件内部注明
- 项目整体按照原作者 dyphire 的许可证约定执行

## 原始项目参考

**原作者**：dyphire
**原仓库**：[dyphire/mpv-config](https://github.com/dyphire/mpv-config)
