### https://github.com/hooke007/mpv_PlayKit/wiki/3_K7sfunc
### ACNet V3 放大

import vapoursynth as vs
from vapoursynth import core
import k7sfunc as k7f

core.num_threads = k7f.vs_t_dft
clip = video_in

############
# 用户选项 #
############

H_Pre = 1080
Model = 1
Model_Var = 0
Gpu = 0
Gpu_M = 1
H_Max = 1440
Lk_Fmt = False
## 整数，预降低处理源高度
## <1|2|3> 使用的模型
## <0|1|2|3> 使用的模型变体（仅对2号模型有效，表示为降噪强度）
## 使用的显卡序号，0为排序一号
## <1|2> 使用的显卡加速模式，模式2仅限N卡使用
## 整数，输出高度限制（填你的显示器高度）
## <True|False> 是否锁定像素格式为yuv420p8

ret = k7f.FMT_CTRL(clip, h_max=1200, h_ret=True)
clip = k7f.FMT_CTRL(clip, h_max=H_Pre, fmt_pix=1 if Lk_Fmt else 0)
clip = k7f.ACNET_STD(clip, model=Model, model_var=Model_Var, turbo=True, gpu=Gpu, gpu_m=Gpu_M)
clip = k7f.FMT_CTRL(clip, h_max=H_Max, fmt_pix=1 if Lk_Fmt else 0)

clip.set_output()
