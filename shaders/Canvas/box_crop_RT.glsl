// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM WT
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 100.0
0.0

//!PARAM WB
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 100.0
0.0

//!PARAM HL
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 100.0
0.0

//!PARAM HR
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 100.0
0.0


//!DESC [box_crop_RT]
//!HOOK OUTPUT
//!BIND HOOKED
//!WHEN WT WB + HL + HR +

vec4 hook() {

	vec2 p = HOOKED_pos;

	float top_border = WT / 100.0;
	float bottom_border = WB / 100.0;
	float left_border = HL / 100.0;
	float right_border = HR / 100.0;

	if (p.x < left_border || p.x > 1.0 - right_border || p.y < top_border || p.y > 1.0 - bottom_border) {
		return vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		return HOOKED_tex(p);
	}

}

