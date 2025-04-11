### https://github.com/hooke007/MPV_lazy/wiki/3_K7sfunc
### 使用自定义的AI放大模型，DX12显卡专用

import vapoursynth as vs
from vapoursynth import core
import k7sfunc as k7f

clip = video_in

############
# 用户选项 #
############

H_Pre = 720
Model = "Sirosky_AniScale2S_Compact_x2_fp16_op17.onnx"
Fp16_Mdl = True
Fp16_Qnt = True
Gpu = 0
Gpu_T = 2
H_Max = 1440
Lk_Fmt = False
## 整数，预降低处理源高度
## 使用的模型
## 模型是否为fp16
## 是否为fp32模型使用fp16量化
## 使用的显卡序号，0为排序一号
## <1|2|3> 使用的显卡线程数
## 整数，输出高度限制（填你的显示器高度）
## <True|False> 是否锁定像素格式为yuv420p8

ret = k7f.FMT_CTRL(clip, h_max=1200, h_ret=True)
clip = k7f.FMT_CTRL(clip, h_max=H_Pre, fmt_pix=1 if Lk_Fmt else 0)
clip = k7f.UAI_DML(clip, clamp=False, model_pth=Model, fp16_mdl=Fp16_Mdl, fp16_qnt=Fp16_Qnt, gpu=Gpu, gpu_t=Gpu_T)
clip = k7f.FMT_CTRL(clip, h_max=H_Max, fmt_pix=1 if Lk_Fmt else 0)

clip.set_output()
