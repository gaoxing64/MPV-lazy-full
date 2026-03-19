// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- RAW ver.
  https://www.shadertoy.com/view/tsdcRM

*/


//!PARAM USF
//!TYPE int
//!MINIMUM 2
//!MAXIMUM 10
4

//!PARAM THR
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.1

//!PARAM AAF
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 10.0
1.0


//!HOOK MAIN
//!BIND HOOKED
//!DESC [hqx_lite_RT]
//!WIDTH HOOKED.w USF *
//!HEIGHT HOOKED.h USF *
//!WHEN HOOKED.w USF * 8193 < HOOKED.h USF * 8193 < *

#define AA_SCALE (USF * AAF)

const float LINE_THICKNESS_PRI = 0.4;
const float LINE_THICKNESS_SEC = 0.3;

bool diag(inout vec4 sum, vec2 uv, vec4 v1, vec4 v2, vec2 p1, vec2 p2, float thickness) {
	if (length(v1 - v2) < THR) {
		vec2 dir = p2 - p1;
		vec2 lp = uv - (floor(uv + p1) + 0.5);
		dir = normalize(vec2(dir.y, -dir.x));
		float l = clamp((thickness - dot(lp, dir)) * AA_SCALE, 0.0, 1.0);
		sum = mix(sum, v1, l);
		return true;
	}
	return false;
}

vec4 hook() {

	vec2 ip = HOOKED_pos * HOOKED_size;
	ivec2 ip_int = ivec2(ip);
	vec4 c_m1m1 = texelFetch(HOOKED_raw, ip_int + ivec2(-1, -1), 0);
	vec4 c_0m1  = texelFetch(HOOKED_raw, ip_int + ivec2( 0, -1), 0);
	vec4 c_1m1  = texelFetch(HOOKED_raw, ip_int + ivec2( 1, -1), 0);
	vec4 c_m10  = texelFetch(HOOKED_raw, ip_int + ivec2(-1,  0), 0);
	vec4 c_00   = texelFetch(HOOKED_raw, ip_int, 0);
	vec4 c_10   = texelFetch(HOOKED_raw, ip_int + ivec2( 1,  0), 0);
	vec4 c_m11  = texelFetch(HOOKED_raw, ip_int + ivec2(-1,  1), 0);
	vec4 c_01   = texelFetch(HOOKED_raw, ip_int + ivec2( 0,  1), 0);
	vec4 c_11   = texelFetch(HOOKED_raw, ip_int + ivec2( 1,  1), 0);

	vec4 final_color = c_00;
	if (diag(final_color, ip, c_m10, c_01, vec2(-1, 0), vec2(0, 1), LINE_THICKNESS_PRI)) {
		diag(final_color, ip, c_m10, c_11, vec2(-1, 0), vec2(1, 1), LINE_THICKNESS_SEC);
		diag(final_color, ip, c_m1m1, c_01, vec2(-1, -1), vec2(0, 1), LINE_THICKNESS_SEC);
	}
	if (diag(final_color, ip, c_01, c_10, vec2(0, 1), vec2(1, 0), LINE_THICKNESS_PRI)) {
		diag(final_color, ip, c_01, c_1m1, vec2(0, 1), vec2(1, -1), LINE_THICKNESS_SEC);
		diag(final_color, ip, c_m11, c_10, vec2(-1, 1), vec2(1, 0), LINE_THICKNESS_SEC);
	}
	if (diag(final_color, ip, c_10, c_0m1, vec2(1, 0), vec2(0, -1), LINE_THICKNESS_PRI)) {
		diag(final_color, ip, c_10, c_m1m1, vec2(1, 0), vec2(-1, -1), LINE_THICKNESS_SEC);
		diag(final_color, ip, c_11, c_0m1, vec2(1, 1), vec2(0, -1), LINE_THICKNESS_SEC);
	}
	if (diag(final_color, ip, c_0m1, c_m10, vec2(0, -1), vec2(-1, 0), LINE_THICKNESS_PRI)) {
		diag(final_color, ip, c_0m1, c_m11, vec2(0, -1), vec2(-1, 1), LINE_THICKNESS_SEC);
		diag(final_color, ip, c_1m1, c_m10, vec2(1, -1), vec2(-1, 0), LINE_THICKNESS_SEC);
	}

	return final_color;

}

