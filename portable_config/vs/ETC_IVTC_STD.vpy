### https://github.com/hooke007/MPV_lazy/wiki/3_K7sfunc
### 伪25或30帧的源转24帧

import vapoursynth as vs
from vapoursynth import core
import k7sfunc as k7f

clip = video_in

############
# 用户选项 #
############

Ivtc_M = 1
## <1|2> ivtc模式

clip = k7f.IVTC_STD(clip, fps_in=container_fps, ivtc_m=Ivtc_M)

clip.set_output()
