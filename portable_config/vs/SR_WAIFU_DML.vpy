### https://github.com/hooke007/MPV_lazy/wiki/3_K7sfunc
### waifu2x 放大或降噪，性能要求非常高，仅支持DX12的显卡使用

import vapoursynth as vs
from vapoursynth import core
import k7sfunc as k7f

clip = video_in

############
# 用户选项 #
############

H_Pre = 720
Lt_Hd = True
Model = 6
Nr_Lv = 2
Gpu = 0
Gpu_T = 2
H_Max = 1440
Lk_Fmt = False
## 整数，预降低处理源高度
## <True|False> 是否对超过HD分辨率（720P）的源进行处理
## <3|5|6> 使用的模型
## <-1|0|1|2|3> 降噪等级，-1为不降噪
## 使用的显卡序号，0为排序一号
## <1|2|3> 使用的显卡线程数
## 整数，输出高度限制（填你的显示器高度）
## <True|False> 是否锁定像素格式为yuv420p8

ret = k7f.FMT_CTRL(clip, h_max=1200, h_ret=True)
clip = k7f.FMT_CTRL(clip, h_max=H_Pre, fmt_pix=1 if Lk_Fmt else 0)
clip = k7f.WAIFU_DML(clip, lt_hd=Lt_Hd, model=Model, nr_lv=Nr_Lv, gpu=Gpu, gpu_t=Gpu_T)
clip = k7f.FMT_CTRL(clip, h_max=H_Max, fmt_pix=1 if Lk_Fmt else 0)

clip.set_output()
