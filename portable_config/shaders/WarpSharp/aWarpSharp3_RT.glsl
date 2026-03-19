// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- RAW ver.
  https://github.com/dubhater/vapoursynth-awarpsharp2

*/


//!PARAM STR_H
//!TYPE float
//!MINIMUM -20.0
//!MAXIMUM 20.0
4.0

//!PARAM STR_V
//!TYPE float
//!MINIMUM -20.0
//!MAXIMUM 20.0
4.0

//!PARAM ET
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 255.0
128.0

//!PARAM BP
//!TYPE int
//!MINIMUM 1
//!MAXIMUM 4
2


//!HOOK LUMA
//!BIND HOOKED
//!SAVE SCHARR_MASK
//!DESC [aWarpSharp3_RT] Scharr edge detect
//!WHEN STR_H STR_H * STR_V STR_V * + 0 >

vec4 hook() {
	float a11 = HOOKED_texOff(vec2(-1.0, -1.0)).r;
	float a21 = HOOKED_texOff(vec2( 0.0, -1.0)).r;
	float a31 = HOOKED_texOff(vec2( 1.0, -1.0)).r;
	float a12 = HOOKED_texOff(vec2(-1.0,  0.0)).r;
	float a32 = HOOKED_texOff(vec2( 1.0,  0.0)).r;
	float a13 = HOOKED_texOff(vec2(-1.0,  1.0)).r;
	float a23 = HOOKED_texOff(vec2( 0.0,  1.0)).r;
	float a33 = HOOKED_texOff(vec2( 1.0,  1.0)).r;
	float Gx = (-3.0*a11 + 3.0*a31 - 10.0*a12 + 10.0*a32 - 3.0*a13 + 3.0*a33) / 32.0;
	float Gy = (-3.0*a11 - 10.0*a21 - 3.0*a31 + 3.0*a13 + 10.0*a23 + 3.0*a33) / 32.0;
	float mag = sqrt(Gx*Gx + Gy*Gy);
	mag = min(mag * 2.0, 1.0);
	mag = min(mag, ET/255.0);
	return vec4(vec3(mag), 1.0);
}

//!HOOK LUMA
//!BIND SCHARR_MASK
//!SAVE GAUSS_H_1
//!DESC [aWarpSharp3_RT] Gauss pass1H
//!WHEN STR_H STR_H * STR_V STR_V * + 0 > BP 0 > *

vec4 hook() {
	float c  = SCHARR_MASK_texOff(vec2( 0, 0)).r * 6.0;
	float n1 = SCHARR_MASK_texOff(vec2(-1, 0)).r + SCHARR_MASK_texOff(vec2(1, 0)).r;
	float n2 = SCHARR_MASK_texOff(vec2(-2, 0)).r + SCHARR_MASK_texOff(vec2(2, 0)).r;
	float avg = (c + n1 * 4.0 + n2) / 16.0;
	return vec4(vec3(avg), 1.0);
}

//!HOOK LUMA
//!BIND GAUSS_H_1
//!SAVE GAUSS_V_1
//!DESC [aWarpSharp3_RT] Gauss pass1V
//!WHEN STR_H STR_H * STR_V STR_V * + 0 > BP 0 > *

vec4 hook() {
	float c  = GAUSS_H_1_texOff(vec2(0,  0)).r * 6.0;
	float n1 = GAUSS_H_1_texOff(vec2(0, -1)).r + GAUSS_H_1_texOff(vec2(0, 1)).r;
	float n2 = GAUSS_H_1_texOff(vec2(0, -2)).r + GAUSS_H_1_texOff(vec2(0, 2)).r;
	float avg = (c + n1 * 4.0 + n2) / 16.0;
	return vec4(vec3(avg), 1.0);
}

//!HOOK LUMA
//!BIND GAUSS_V_1
//!SAVE GAUSS_H_2
//!DESC [aWarpSharp3_RT] Gauss pass2H
//!WHEN STR_H STR_H * STR_V STR_V * + 0 > BP 1 > *

vec4 hook() {
	float c  = GAUSS_V_1_texOff(vec2( 0, 0)).r * 6.0;
	float n1 = GAUSS_V_1_texOff(vec2(-1, 0)).r + GAUSS_V_1_texOff(vec2(1, 0)).r;
	float n2 = GAUSS_V_1_texOff(vec2(-2, 0)).r + GAUSS_V_1_texOff(vec2(2, 0)).r;
	float avg = (c + n1 * 4.0 + n2) / 16.0;
	return vec4(vec3(avg), 1.0);
}

//!HOOK LUMA
//!BIND GAUSS_H_2
//!SAVE GAUSS_V_2
//!DESC [aWarpSharp3_RT] Gauss pass2V
//!WHEN STR_H STR_H * STR_V STR_V * + 0 > BP 1 > *

vec4 hook() {
	float c  = GAUSS_H_2_texOff(vec2(0,  0)).r * 6.0;
	float n1 = GAUSS_H_2_texOff(vec2(0, -1)).r + GAUSS_H_2_texOff(vec2(0, 1)).r;
	float n2 = GAUSS_H_2_texOff(vec2(0, -2)).r + GAUSS_H_2_texOff(vec2(0, 2)).r;
	float avg = (c + n1 * 4.0 + n2) / 16.0;
	return vec4(vec3(avg), 1.0);
}

//!HOOK LUMA
//!BIND GAUSS_V_2
//!SAVE GAUSS_H_3
//!DESC [aWarpSharp3_RT] Gauss pass3H
//!WHEN STR_H STR_H * STR_V STR_V * + 0 > BP 2 > *

vec4 hook() {
	float c  = GAUSS_V_2_texOff(vec2( 0, 0)).r * 6.0;
	float n1 = GAUSS_V_2_texOff(vec2(-1, 0)).r + GAUSS_V_2_texOff(vec2(1, 0)).r;
	float n2 = GAUSS_V_2_texOff(vec2(-2, 0)).r + GAUSS_V_2_texOff(vec2(2, 0)).r;
	float avg = (c + n1 * 4.0 + n2) / 16.0;
	return vec4(vec3(avg), 1.0);
}

//!HOOK LUMA
//!BIND GAUSS_H_3
//!SAVE GAUSS_V_3
//!DESC [aWarpSharp3_RT] Gauss pass3V
//!WHEN STR_H STR_H * STR_V STR_V * + 0 > BP 2 > *

vec4 hook() {
	float c  = GAUSS_H_3_texOff(vec2(0,  0)).r * 6.0;
	float n1 = GAUSS_H_3_texOff(vec2(0, -1)).r + GAUSS_H_3_texOff(vec2(0, 1)).r;
	float n2 = GAUSS_H_3_texOff(vec2(0, -2)).r + GAUSS_H_3_texOff(vec2(0, 2)).r;
	float avg = (c + n1 * 4.0 + n2) / 16.0;
	return vec4(vec3(avg), 1.0);
}

//!HOOK LUMA
//!BIND GAUSS_V_3
//!SAVE GAUSS_H_4
//!DESC [aWarpSharp3_RT] Gauss pass4H
//!WHEN STR_H STR_H * STR_V STR_V * + 0 > BP 3 > *

vec4 hook() {
	float c  = GAUSS_V_3_texOff(vec2( 0, 0)).r * 6.0;
	float n1 = GAUSS_V_3_texOff(vec2(-1, 0)).r + GAUSS_V_3_texOff(vec2(1, 0)).r;
	float n2 = GAUSS_V_3_texOff(vec2(-2, 0)).r + GAUSS_V_3_texOff(vec2(2, 0)).r;
	float avg = (c + n1 * 4.0 + n2) / 16.0;
	return vec4(vec3(avg), 1.0);
}

//!HOOK LUMA
//!BIND GAUSS_H_4
//!SAVE GAUSS_V_4
//!DESC [aWarpSharp3_RT] Gauss pass4V
//!WHEN STR_H STR_H * STR_V STR_V * + 0 > BP 3 > *

vec4 hook() {
	float c  = GAUSS_H_4_texOff(vec2(0,  0)).r * 6.0;
	float n1 = GAUSS_H_4_texOff(vec2(0, -1)).r + GAUSS_H_4_texOff(vec2(0, 1)).r;
	float n2 = GAUSS_H_4_texOff(vec2(0, -2)).r + GAUSS_H_4_texOff(vec2(0, 2)).r;
	float avg = (c + n1 * 4.0 + n2) / 16.0;
	return vec4(vec3(avg), 1.0);
}

//!HOOK LUMA
//!BIND HOOKED
//!BIND GAUSS_V_1
//!DESC [aWarpSharp3_RT] warp (1 blur)
//!WHEN STR_H STR_H * STR_V STR_V * + 0 > BP 1 = *

vec4 hook() {
	float Gx = GAUSS_V_1_texOff(vec2(-1, 0)).r - GAUSS_V_1_texOff(vec2(1, 0)).r;
	float Gy = GAUSS_V_1_texOff(vec2(0, -1)).r - GAUSS_V_1_texOff(vec2(0, 1)).r;
	return HOOKED_tex(HOOKED_pos + vec2(Gx * STR_H, Gy * STR_V) * HOOKED_pt);
}

//!HOOK LUMA
//!BIND HOOKED
//!BIND GAUSS_V_2
//!DESC [aWarpSharp3_RT] warp (2 blurs)
//!WHEN STR_H STR_H * STR_V STR_V * + 0 > BP 2 = *

vec4 hook() {
	float Gx = GAUSS_V_2_texOff(vec2(-1, 0)).r - GAUSS_V_2_texOff(vec2(1, 0)).r;
	float Gy = GAUSS_V_2_texOff(vec2(0, -1)).r - GAUSS_V_2_texOff(vec2(0, 1)).r;
	return HOOKED_tex(HOOKED_pos + vec2(Gx * STR_H, Gy * STR_V) * HOOKED_pt);
}

//!HOOK LUMA
//!BIND HOOKED
//!BIND GAUSS_V_3
//!DESC [aWarpSharp3_RT] warp (3 blurs)
//!WHEN STR_H STR_H * STR_V STR_V * + 0 > BP 3 = *

vec4 hook() {
	float Gx = GAUSS_V_3_texOff(vec2(-1, 0)).r - GAUSS_V_3_texOff(vec2(1, 0)).r;
	float Gy = GAUSS_V_3_texOff(vec2(0, -1)).r - GAUSS_V_3_texOff(vec2(0, 1)).r;
	return HOOKED_tex(HOOKED_pos + vec2(Gx * STR_H, Gy * STR_V) * HOOKED_pt);
}

//!HOOK LUMA
//!BIND HOOKED
//!BIND GAUSS_V_4
//!DESC [aWarpSharp3_RT] warp (4 blurs)
//!WHEN STR_H STR_H * STR_V STR_V * + 0 > BP 4 = *

vec4 hook() {
	float Gx = GAUSS_V_4_texOff(vec2(-1, 0)).r - GAUSS_V_4_texOff(vec2(1, 0)).r;
	float Gy = GAUSS_V_4_texOff(vec2(0, -1)).r - GAUSS_V_4_texOff(vec2(0, 1)).r;
	return HOOKED_tex(HOOKED_pos + vec2(Gx * STR_H, Gy * STR_V) * HOOKED_pt);
}

