// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM ROW
//!TYPE int
//!MINIMUM 1
1

//!PARAM FILL
//!TYPE int
//!MINIMUM 0
//!MAXIMUM 1
0


//!HOOK MAIN
//!BIND HOOKED
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!DESC [mirror_sp_RT]
//!WHEN HOOKED.w HOOKED.h <

vec4 hook() {

	vec2 pos = HOOKED_pos;
	float DAR = float(target_size.x) / float(target_size.y);
	float split = DAR * (float(HOOKED_size.y) * float(ROW)) / (float(HOOKED_size.x));
	float pad = (fract(split) * 0.5) / split;

	if (split > 1.0 || ROW >= 2) {
		if (FILL == 1) {
			pos.x = mod((pos.x + ((1.0 / split) - pad)) * split, 1.0);
		} else {
			if (pos.x >= pad && pos.x <= (1.0 - pad)) {
				pos.x = mod((pos.x - pad) * split, 1.0);
			} else {
				return vec4(0.0, 0.0, 0.0, 1.0);
			}
		}
		if (ROW >= 2) {
			float segment_height = 1.0 / ROW;
			float segment = floor(pos.y * ROW);
			float epsilon = 0.0015; // 行边界采样
			pos.y = (pos.y - segment * segment_height) * ROW;
			pos.y = clamp(pos.y, epsilon, 1.0 - epsilon);
		}
	}

	return HOOKED_tex(pos);

}

