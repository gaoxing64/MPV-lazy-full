### https://github.com/hooke007/MPV_lazy/wiki/3_K7sfunc
### 超级去隔行/反交错

import vapoursynth as vs
from vapoursynth import core
import k7sfunc as k7f

clip = video_in

############
# 用户选项 #
############

Deint_Lv = 4
Src_Type = 0
Tff = 0
Cpu = True
Gpu = -1
## <1|2|3|4|5|6|7|8|9|10|11> 质量等级
## <0|1|2|3> 源类型（当0时倍帧），分别对应 interlaced(0) general-progressive(1) badly-deinterlaced(2/3)
## <0|1|2> 场序，分别对应 自动检测(0) 顶场优先(1) 底场优先(2)
## <True|False> 是否仅使用CPU
## <-1|0|1|2> 使用的显卡序号，-1 为自动，0 为排序一号

clip = k7f.DEINT_EX(clip, fps_in=container_fps, obs=True, deint_lv=Deint_Lv, src_type=Src_Type, deint_den=1, tff=Tff, cpu=Cpu, gpu=Gpu)
clip.set_output()
