### https://github.com/hooke007/MPV_lazy/wiki/3_K7sfunc
### BM3D降噪，N卡专用

import vapoursynth as vs
from vapoursynth import core
import k7sfunc as k7f

clip = video_in

############
# 用户选项 #
############

Nr_Lv = [5,0,0]
Bs_Ref = 8
Bs_Out = 7
Gpu = 0
## 整数组，每平面的降噪强度
## <1|2|3|4|5|6|7|8> block_step
## <1|2|3|4|5|6|7|8> 小于等于 Bs_Ref
## 显卡序号，0为一号

clip = k7f.BM3D_NV(clip, nr_lv=Nr_Lv, bs_ref=Bs_Ref, bs_out=Bs_Out, gpu=Gpu)

clip.set_output()
