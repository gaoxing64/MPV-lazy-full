### https://github.com/hooke007/MPV_lazy/wiki/3_K7sfunc
### NGU test

import vapoursynth as vs
from vapoursynth import core
import k7sfunc as k7f

clip = video_in

############
# 用户选项 #
############

Ngu = 4
Ngu_Q = 3
Rca_Lv = 0
Rca_Q = 2
## <0|1|2|3|4> 禁用 AA Soft Standard Sharp
## <1|2|3|4> low media high veryHigh
## <0|1|2|3|4|5|6|7|8|9|10|11|12|13|14>
## <1|2|3|4> low media high veryHigh

ret = k7f.FMT_CTRL(clip, h_max=1200, h_ret=True)
clip = k7f.UVR_MAD(clip, ngu=Ngu, ngu_q=Ngu_Q, rca_lv=Rca_Lv, rca_q=Rca_Q)

clip.set_output()
