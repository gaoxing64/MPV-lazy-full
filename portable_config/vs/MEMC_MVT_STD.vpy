### https://github.com/hooke007/MPV_lazy/wiki/3_K7sfunc
### mvtools的偏保守型补帧策略，中等消耗。

import vapoursynth as vs
from vapoursynth import core
import k7sfunc as k7f

clip = video_in

############
# 用户选项 #
############

H_Pre = 1440
Fps_Out = 60.0
Lk_Fmt = False
## 整数，预降低处理源高度（填你的显示器高度）
## 浮点，目标帧率，示例即约60fps。特殊值比如 display_fps/2 即目标为显示器刷新率的一半帧率；填 container_fps*2 即倍帧（越高的帧率增加耗能，产生更多伪影，通常是不必要的。例如对于144hz的显示器来说，最多只需要补到72fps，剩下的可让 --interpolation 帧混成补偿）
## <True|False> 锁定像素格式为yuv420p8

ret = k7f.FPS_CTRL(clip, fps_in=container_fps, fps_ret=True)
clip = k7f.FMT_CTRL(clip, h_max=H_Pre, fmt_pix=1 if Lk_Fmt else 0)
clip = k7f.MVT_STD(clip, fps_in=container_fps, fps_out=Fps_Out)

clip.set_output()
