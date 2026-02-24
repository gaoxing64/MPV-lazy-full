// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM DT
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 2.0
0.0

//!PARAM DB
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 2.0
0.0

//!PARAM DL
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 2.0
0.0

//!PARAM DR
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 2.0
0.0

//!PARAM LV
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 2.0
1.0


//!HOOK OUTPUT
//!BIND HOOKED
//!DESC [darkside_RT]
//!WHEN DT DB + DL + DR + LV *

vec4 hook() {

	vec2 duv = gl_FragCoord.xy / HOOKED_size;
	vec4 color = HOOKED_tex(HOOKED_pos);

	float factor_t = smoothstep(0.0, DT, duv.y);
	float factor_b = smoothstep(0.0, DB, 1.0 - duv.y);
	float factor_l = smoothstep(0.0, DL, duv.x);
	float factor_r = smoothstep(0.0, DR, 1.0 - duv.x);

	float factor4 = factor_t * factor_b * factor_l * factor_r;
	float factor_a = mix((2.0 - LV) * 0.5, 1.0, factor4);

	return vec4(color.rgb * factor_a, color.a * factor_a);

}

