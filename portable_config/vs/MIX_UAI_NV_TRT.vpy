### 使用自定义的AI放大模型，RTX N卡专用
### 文档_ https://github.com/hooke007/mpv_PlayKit/discussions/329
### 参数_ https://github.com/hooke007/mpv_PlayKit/wiki/3_K7sfunc#uai_nv_trt

import vapoursynth as vs
from vapoursynth import core
import k7sfunc as k7f

core.num_threads = k7f.vs_t_dft
clip = video_in

############
# 用户选项 #
############

H_Pre = 720
Model = "the_database_AnimeJaNaiV2L1_x2_fp16_op17.onnx"
Fp16_Qnt = True
Gpu = 0
Gpu_T = 2
St_Eng = False
Res_Opt = [1280, 720]
Res_Max = [1920, 1200]
Ws_Size = 0
H_Max = 1440
Lk_Fmt = False
## 整数，预降低处理源高度
## 指定使用的模型，文件放置位为 .../mpv-lazy/vs-plugins/models/
## <True|False> 是否为fp32模型使用fp16量化
## 使用的显卡序号，0为排序一号
## <1|2|3> 使用的显卡线程数
## <True|False> 是否使用静态引擎，否则为动态
## 动态引擎的优化源分辨率（高度不大于 H_Pre）
## 动态引擎的最大支持源分辨率
## <0~1024> 整数，约束显存（MiB），最小值为128，设为低于此数的值即为不限制
## 整数，输出高度限制（填你的显示器高度）
## <True|False> 是否锁定像素格式为yuv420p8

ret = k7f.FMT_CTRL(clip, h_max=1200, h_ret=True)
clip = k7f.FMT_CTRL(clip, h_max=H_Pre, fmt_pix=1 if Lk_Fmt else 0)
clip = k7f.UAI_NV_TRT(clip, crc=False, model_pth=Model, opt_lv=3, cuda_opt=[0, 0, 0], int8_qnt=False, fp16_qnt=Fp16_Qnt, gpu=Gpu, gpu_t=Gpu_T, st_eng=St_Eng, res_opt=Res_Opt, res_max=Res_Max, ws_size=Ws_Size)
clip = k7f.FMT_CTRL(clip, h_max=H_Max, fmt_pix=1 if Lk_Fmt else 0)

clip.set_output()
