// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM VAL1
//!TYPE float
//!MINIMUM 1.0
//!MAXIMUM 3.5
1.2

//!PARAM VAL2
//!TYPE int
//!MINIMUM 2
//!MAXIMUM 4
2


//!HOOK MAIN
//!BIND HOOKED
//!DESC [dehaasn_ads_rgb_RT]
//!WIDTH OUTPUT.w VAL2 /
//!HEIGHT OUTPUT.h VAL2 /
//!WHEN OUTPUT.w HOOKED.w / VAL2 < OUTPUT.h HOOKED.h / VAL2 < * OUTPUT.w HOOKED.w / VAL1 > OUTPUT.h HOOKED.h / VAL1 > * * VAL2 VAL1 > *

vec4 hook() {
	return HOOKED_tex(HOOKED_pos);
}

