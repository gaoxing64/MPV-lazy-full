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
├── mpv.conf              # 主配置文件
├── input.conf            # 键位绑定配置
```

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

项目集成了基于 [LumeCraft-Labs/K7sfunc](https://github.com/LumeCraft-Labs/K7sfunc) 的 VapourSynth 视频处理脚本（位于 `portable_config/vs/` 目录），这是一个为 mpv 特向优化的 VS 包装器。

### 已集成的脚本

#### 运动补偿（补帧）
- `MEMC_DRBA_DML.vpy` - DRBA 补帧（DX12 显卡专用）
- `MEMC_DRBA_NV.vpy` - DRBA 补帧（N 卡专用）
- `MEMC_MVT_LQ.vpy` - mvtools 倍帧（一般开销）
- `MEMC_RIFE_DML.vpy` - RIFE 补帧（DX12 显卡专用）
- `MEMC_RIFE_NV.vpy` - RIFE 补帧（N 卡专用）
- `MEMC_RIFE_STD.vpy` - RIFE 补帧（通用版）
- `MEMC_SVP_PRO.vpy` - SVP 补帧（简化版）

#### 超分辨率
- `SR_ARTCNN_NV.vpy` - ArtCNN 放大（N 卡专用）

#### 降噪处理
- `NR_BM3D_NV.vpy` - BM3D 降噪（N 卡专用）
- `NR_CCD_STD.vpy` - CCD 降噪（降低彩噪）

#### 混合功能
- `MIX_UAI_DML.vpy` - AI 放大模型（DX12 显卡专用）
- `MIX_UAI_MIGX.vpy` - AI 放大模型（RDNA 显卡专用）
- `MIX_UAI_NV_TRT.vpy` - AI 放大模型（RTX N 卡专用）


详细使用说明请参考：[K7sfunc Wiki](https://github.com/hooke007/mpv_PlayKit/wiki/3_K7sfunc)

## 脚本功能

### 主要功能特性

- **文件管理**：集成文件浏览器与播放列表管理器
- **字幕处理**：下载、同步、AI生成字幕
- **历史记录**：播放记录管理与书签功能
- **实用工具**：yt-dlp 选择器、智能裁剪、音频同步等功能

### 特色脚本

- `uosc`：现代化用户界面
- `uosc_danmaku`：弹弹Play弹幕系统（[Loukyuu1120 版本](https://github.com/Loukyuu1120/uosc_danmaku)），支持多弹幕源切换与弹幕池选择菜单
- `simple-history`：播放历史管理
- `playlistmanager`：播放列表管理
- `sub-assrt`：在线字幕下载
- `autosubsync`：音频字幕同步
- `file-browser`：文件浏览器


## 自定义配置

配置使用了智能的条件配置组，可根据不同情况进行自动定制：

- **分辨率自适应**：针对 SD/HD/4K 内容应用优化配置
- **HDR 处理**：根据 HDR 信息自动适配输出参数
- **设备状态**：根据窗口状态及音频配置进行参数调整

## 界面预览

![播放界面预览1](assets\danmu.png)

![播放界面预览2](assets\glsl.png)

![播放界面预览3](assets\VapourSynth.png)

## 技术参考

- [mpv 官方手册](https://mpv.io/manual/master/)
- [hooke007 配置手册](https://hooke007.github.io/mpv-lazy/mpv.html)

## 许可证说明

- 本项目主要整合了多种开源脚本和着色器，主要来源于 [hooke007/mpv_PlayKit](https://github.com/hooke007/mpv_PlayKit) 仓库，以及 [LumeCraft-Labs/K7sfunc](https://github.com/LumeCraft-Labs/K7sfunc) 仓库
- 每个组件的许可证信息通常在其源文件内部注明

## 原始项目参考

**原作者**：dyphire
**原仓库**：[dyphire/mpv-config](https://github.com/dyphire/mpv-config)
