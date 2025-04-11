# MPV-Lazy

MPV-Lazy 是一个为 MPV 播放器打造的懒人包，集成了丰富的预设配置、滤镜和着色器，让您无需复杂设置即可获得优质的视频播放体验。

## 特性

- **丰富的预设滤镜**：包含多种视频增强滤镜，如补帧、超分辨率、降噪等
- **多样化的着色器**：集成 Anime4K、ACNet、AMD FSR 等多种高质量着色器
- **便捷的快捷键配置**：直观的菜单式快捷键，轻松调用各种功能
- **中文本地化**：完整的中文界面和提示，对中文用户友好
- **便携式设计**：无需安装，解压即用

## 系统要求

- Windows 操作系统（已测试 Windows 10/11）
- 对于基础功能：任何支持 DirectX 11 的显卡
- 对于高级功能（如 RTX 加速滤镜）：NVIDIA RTX 系列显卡
- 对于 DX12 加速功能：支持 DirectX 12 的显卡

## 快速开始

1. 从 [Releases](https://github.com/gaoxing64/MPV-lazy-full/releases/tag/mpv) 页面下载最新版本
2. 解压到任意位置
3. 运行 `mpv.exe` 开始使用

## 主要功能

### VF 滤镜

MPV-Lazy 集成了多种 VapourSynth 滤镜，分为以下几类：

#### 补帧系列
- MVTools 快速/标准版：传统补帧算法，平衡性能与效果
- RIFE 标准/RTX加速版：AI补帧，效果优秀
- SVP 专业/快速版：流畅视频项目补帧算法

#### 超分辨率系列
- ESRGAN：高质量AI超分辨率
- WAIFU2x：专为动漫优化的超分辨率
- ArtCNN：艺术风格增强超分辨率

#### 降噪系列
- BM3D：高质量降噪
- CCD：色彩一致性降噪

### 着色器

MPV-Lazy 包含多种着色器，可通过菜单或快捷键启用：

- **Anime4K 系列**：专为动漫优化的画质增强
- **ACNet 系列**：动漫线条增强网络
- **AMD 系列**：AMD显卡优化技术
- **CuNNy 系列**：基于神经网络的超分辨率
- **RAVU 系列**：快速精确的放大算法
- **AI放大系列**：多种AI图像放大着色器

## 快捷键

MPV-Lazy 提供了丰富的快捷键配置，主要分为以下几类：

- **播放控制**：播放/暂停、前进/后退、AB循环等
- **音量控制**：调整音量、音频延迟等
- **滤镜控制**：快速应用各种VF滤镜
- **着色器控制**：启用/禁用各种着色器
- **字幕控制**：调整字幕延迟、样式等

详细快捷键可在播放器内通过按下 `F1` 键查看。

## 配置文件

主要配置文件位于 `portable_config` 目录：

- `input_uosc.conf`：快捷键配置
- `mpv.conf`：MPV主配置
- `script`：脚本选项配置

## 自定义

您可以通过编辑配置文件来自定义 MPV-Lazy：

1. 使用文本编辑器打开 `portable_config` 目录下的相关配置文件
2. 根据注释说明修改参数
3. 保存文件并重启 MPV

## 常见问题

**Q: 为什么某些滤镜无法使用？**  
A: 部分高级滤镜需要特定硬件支持，如 RTX 加速滤镜需要 NVIDIA RTX 系列显卡。

**Q: 如何更新 MPV-Lazy？**  
A: 下载新版本并解压覆盖旧文件，注意备份您的自定义配置。

**Q: 播放高分辨率视频时卡顿怎么办？**  
A: 尝试禁用重型滤镜和着色器，或降低视频输出分辨率。

## 贡献

欢迎通过 Issues 和 Pull Requests 贡献代码或提出建议。

## 致谢

- [MPV](https://mpv.io/) - 强大的开源媒体播放器
- [VapourSynth](http://www.vapoursynth.com/) - 视频处理框架
- [Anime4K](https://github.com/bloc97/Anime4K) - 高质量动漫放大算法
- 以及所有其他开源项目的贡献者

## 许可证

本项目基于 GPL-3.0 许可证开源。

## 链接

- [GitHub 仓库](https://github.com/hooke007/MPV_lazy)
- [MPV 官方文档](https://mpv.io/manual/master/)
- [VapourSynth 文档](http://www.vapoursynth.com/doc/)
