### https://github.com/hooke007/MPV_lazy/wiki/3_K7sfunc
### 使用自定义的AI放大模型，N卡专用

import vapoursynth as vs
from vapoursynth import core
import k7sfunc as k7f

clip = video_in

############
# 用户选项 #
############

H_Pre = 720
Model = "Sirosky_Ani4Kv2_UltraCompact_x2_fp32_op17.onnx"
Gpu = 0
Gpu_T = 4
Res_Opt = [1280, 720]
Res_Max = [1920, 1200]
Ws_Size = 0
H_Max = 1440
Lk_Fmt = False
## 整数，预降低处理源高度
## 使用的模型
## 使用的显卡序号，0为排序一号
## <1|2|3> 使用的显卡线程数
## 优化源分辨率（高度不大于 H_Pre）
## 最大支持的源分辨率
## <0~1024> 整数，约束显存（MiB），最小值为128，设为低于此数的值即为不限制
## 整数，输出高度限制（填你的显示器高度）
## <True|False> 是否锁定像素格式为yuv420p8

ret = k7f.FMT_CTRL(clip, h_max=1200, h_ret=True)
clip = k7f.FMT_CTRL(clip, h_max=H_Pre, fmt_pix=1 if Lk_Fmt else 0)
clip = k7f.UAI_NV_TRT(clip, clamp=False, model_pth=Model, opt_lv=3, cuda_opt=[1, 1, 1], fp16=True, gpu=Gpu, gpu_t=Gpu_T, st_eng=False, res_opt=Res_Opt, res_max=Res_Max, ws_size=Ws_Size)
clip = k7f.FMT_CTRL(clip, h_max=H_Max, fmt_pix=1 if Lk_Fmt else 0)

clip.set_output()
