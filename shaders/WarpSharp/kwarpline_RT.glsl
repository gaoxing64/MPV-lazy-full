// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM STR
//!TYPE float
//!MINIMUM -10.0
//!MAXIMUM 10.0
5.0

//!PARAM ET
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 255.0
128.0

//!PARAM BP
//!TYPE int
//!MINIMUM 1
//!MAXIMUM 8
3


//!HOOK LUMA
//!BIND HOOKED
//!SAVE SOBEL_MASK
//!DESC [kwarpline_RT] blur pre
//!WHEN STR

vec4 hook() {
	float s11 = HOOKED_texOff(vec2(-1.0, -1.0)).r, s12 = HOOKED_texOff(vec2(-1.0, 0.0)).r, s13 = HOOKED_texOff(vec2(-1.0, 1.0)).r;
	float s21 = HOOKED_texOff(vec2(0.0, -1.0)).r, s23 = HOOKED_texOff(vec2(0.0, 1.0)).r;
	float s31 = HOOKED_texOff(vec2(1.0, -1.0)).r, s32 = HOOKED_texOff(vec2(1.0, 0.0)).r, s33 = HOOKED_texOff(vec2(1.0, 1.0)).r;
	float gx = s11 + 2.0*s21 + s31 - (s13 + 2.0*s23 + s33), gy = s11 + 2.0*s12 + s13 - (s31 + 2.0*s32 + s33);
	return vec4(vec3(min(sqrt(gx*gx + gy*gy), ET/255.0)), 1.0);
}

//!HOOK LUMA
//!BIND SOBEL_MASK
//!SAVE BLUR_MASK_1
//!DESC [kwarpline_RT] blur pass1
//!WHEN STR BP 0 > *

vec4 hook() {
	vec4 s = vec4(0.0);
	for(int y=-2; y<=2;y++) for(int x=-2; x<=2;x++) s+=SOBEL_MASK_texOff(vec2(x, y));
	return s/25.0;
}

//!HOOK LUMA
//!BIND BLUR_MASK_1
//!SAVE BLUR_MASK_2
//!DESC [kwarpline_RT] blur pass2
//!WHEN STR BP 1 > *

vec4 hook() {
	vec4 s = vec4(0.0);
	for(int y=-2; y<=2;y++) for(int x=-2; x<=2;x++) s+=BLUR_MASK_1_texOff(vec2(x, y));
	return s/25.0;
}

//!HOOK LUMA
//!BIND BLUR_MASK_2
//!SAVE BLUR_MASK_3
//!DESC [kwarpline_RT] blur pass3
//!WHEN STR BP 2 > *

vec4 hook() {
	vec4 s = vec4(0.0);
	for(int y=-2; y<=2;y++) for(int x=-2; x<=2;x++) s+=BLUR_MASK_2_texOff(vec2(x, y));
	return s/25.0;
}

//!HOOK LUMA
//!BIND BLUR_MASK_3
//!SAVE BLUR_MASK_4
//!DESC [kwarpline_RT] blur pass4
//!WHEN STR BP 3 > *

vec4 hook() {
	vec4 s = vec4(0.0);
	for(int y=-2; y<=2;y++) for(int x=-2; x<=2;x++) s+=BLUR_MASK_3_texOff(vec2(x, y));
	return s/25.0;
}

//!HOOK LUMA
//!BIND BLUR_MASK_4
//!SAVE BLUR_MASK_5
//!DESC [kwarpline_RT] blur pass5
//!WHEN STR BP 4 > *

vec4 hook() {
	vec4 s = vec4(0.0);
	for(int y=-2; y<=2;y++) for(int x=-2; x<=2;x++) s+=BLUR_MASK_4_texOff(vec2(x, y));
	return s/25.0;
}

//!HOOK LUMA
//!BIND BLUR_MASK_5
//!SAVE BLUR_MASK_6
//!DESC [kwarpline_RT] blur pass6
//!WHEN STR BP 5 > *

vec4 hook() {
	vec4 s = vec4(0.0);
	for(int y=-2; y<=2;y++) for(int x=-2; x<=2;x++) s+=BLUR_MASK_5_texOff(vec2(x, y));
	return s/25.0;
}

//!HOOK LUMA
//!BIND BLUR_MASK_6
//!SAVE BLUR_MASK_7
//!DESC [kwarpline_RT] blur pass7
//!WHEN STR BP 6 > *

vec4 hook() {
	vec4 s = vec4(0.0);
	for(int y=-2; y<=2;y++) for(int x=-2; x<=2;x++) s+=BLUR_MASK_6_texOff(vec2(x, y));
	return s/25.0;
}

//!HOOK LUMA
//!BIND BLUR_MASK_7
//!SAVE BLUR_MASK_8
//!DESC [kwarpline_RT] blur pass8
//!WHEN STR BP 7 > *

vec4 hook() {
	vec4 s = vec4(0.0);
	for(int y=-2; y<=2;y++) for(int x=-2; x<=2;x++) s+=BLUR_MASK_7_texOff(vec2(x, y));
	return s/25.0;
}

//!HOOK LUMA
//!BIND HOOKED
//!BIND SOBEL_MASK
//!DESC [kwarpline_RT] warp
//!WHEN STR BP 0 = *

// 效果太次 不使用
vec4 hook() {
	float Gx = SOBEL_MASK_texOff(vec2(-1, 0)).r - SOBEL_MASK_texOff(vec2(1, 0)).r;
	float Gy = SOBEL_MASK_texOff(vec2(0, -1)).r - SOBEL_MASK_texOff(vec2(0, 1)).r;
	return HOOKED_tex(HOOKED_pos + vec2(Gx, Gy)*STR*HOOKED_pt);
}

//!HOOK LUMA
//!BIND HOOKED
//!BIND BLUR_MASK_1
//!DESC [kwarpline_RT] warp (1 blur)
//!WHEN STR BP 1 = *
vec4 hook() {
	float Gx = BLUR_MASK_1_texOff(vec2(-1, 0)).r - BLUR_MASK_1_texOff(vec2(1, 0)).r;
	float Gy = BLUR_MASK_1_texOff(vec2(0, -1)).r - BLUR_MASK_1_texOff(vec2(0, 1)).r;
	return HOOKED_tex(HOOKED_pos + vec2(Gx, Gy)*STR*HOOKED_pt);
}

//!HOOK LUMA
//!BIND HOOKED
//!BIND BLUR_MASK_2
//!DESC [kwarpline_RT] warp (2 blurs)
//!WHEN STR BP 2 = *
vec4 hook() {
	float Gx = BLUR_MASK_2_texOff(vec2(-1, 0)).r - BLUR_MASK_2_texOff(vec2(1, 0)).r;
	float Gy = BLUR_MASK_2_texOff(vec2(0, -1)).r - BLUR_MASK_2_texOff(vec2(0, 1)).r;
	return HOOKED_tex(HOOKED_pos + vec2(Gx, Gy)*STR*HOOKED_pt);
}

//!HOOK LUMA
//!BIND HOOKED
//!BIND BLUR_MASK_3
//!DESC [kwarpline_RT] warp (3 blurs)
//!WHEN STR BP 3 = *
vec4 hook() {
	float Gx = BLUR_MASK_3_texOff(vec2(-1, 0)).r - BLUR_MASK_3_texOff(vec2(1, 0)).r;
	float Gy = BLUR_MASK_3_texOff(vec2(0, -1)).r - BLUR_MASK_3_texOff(vec2(0, 1)).r;
	return HOOKED_tex(HOOKED_pos + vec2(Gx, Gy)*STR*HOOKED_pt);
}

//!HOOK LUMA
//!BIND HOOKED
//!BIND BLUR_MASK_4
//!DESC [kwarpline_RT] warp (4 blurs)
//!WHEN STR BP 4 = *
vec4 hook() {
	float Gx = BLUR_MASK_4_texOff(vec2(-1, 0)).r - BLUR_MASK_4_texOff(vec2(1, 0)).r;
	float Gy = BLUR_MASK_4_texOff(vec2(0, -1)).r - BLUR_MASK_4_texOff(vec2(0, 1)).r;
	return HOOKED_tex(HOOKED_pos + vec2(Gx, Gy)*STR*HOOKED_pt);
}

//!HOOK LUMA
//!BIND HOOKED
//!BIND BLUR_MASK_5
//!DESC [kwarpline_RT] warp (5 blurs)
//!WHEN STR BP 5 = *
vec4 hook() {
	float Gx = BLUR_MASK_5_texOff(vec2(-1, 0)).r - BLUR_MASK_5_texOff(vec2(1, 0)).r;
	float Gy = BLUR_MASK_5_texOff(vec2(0, -1)).r - BLUR_MASK_5_texOff(vec2(0, 1)).r;
	return HOOKED_tex(HOOKED_pos + vec2(Gx, Gy)*STR*HOOKED_pt);
}

//!HOOK LUMA
//!BIND HOOKED
//!BIND BLUR_MASK_6
//!DESC [kwarpline_RT] warp (6 blurs)
//!WHEN STR BP 6 = *
vec4 hook() {
	float Gx = BLUR_MASK_6_texOff(vec2(-1, 0)).r - BLUR_MASK_6_texOff(vec2(1, 0)).r;
	float Gy = BLUR_MASK_6_texOff(vec2(0, -1)).r - BLUR_MASK_6_texOff(vec2(0, 1)).r;
	return HOOKED_tex(HOOKED_pos + vec2(Gx, Gy)*STR*HOOKED_pt);
}

//!HOOK LUMA
//!BIND HOOKED
//!BIND BLUR_MASK_7
//!DESC [kwarpline_RT] warp (7 blurs)
//!WHEN STR BP 7 = *
vec4 hook() {
	float Gx = BLUR_MASK_7_texOff(vec2(-1, 0)).r - BLUR_MASK_7_texOff(vec2(1, 0)).r;
	float Gy = BLUR_MASK_7_texOff(vec2(0, -1)).r - BLUR_MASK_7_texOff(vec2(0, 1)).r;
	return HOOKED_tex(HOOKED_pos + vec2(Gx, Gy)*STR*HOOKED_pt);
}

//!HOOK LUMA
//!BIND HOOKED
//!BIND BLUR_MASK_8
//!DESC [kwarpline_RT] warp (8 blurs)
//!WHEN STR BP 8 = *

vec4 hook() {
	float Gx = BLUR_MASK_8_texOff(vec2(-1, 0)).r - BLUR_MASK_8_texOff(vec2(1, 0)).r;
	float Gy = BLUR_MASK_8_texOff(vec2(0, -1)).r - BLUR_MASK_8_texOff(vec2(0, 1)).r;
	return HOOKED_tex(HOOKED_pos + vec2(Gx, Gy)*STR*HOOKED_pt);
}

