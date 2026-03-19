// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM STR
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 2.0
1.0

//!PARAM MC
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 2.0
1.0

//!PARAM MB
//!TYPE float
//!MINIMUM -0.5
//!MAXIMUM 0.5
0.0

//!PARAM SIZE
//!TYPE CONSTANT int
//!MINIMUM 1
//!MAXIMUM 2
1

//!PARAM SHIFT
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.45


//!HOOK LUMA
//!BIND HOOKED
//!SAVE LUMA_A
//!DESC [eq_HDRR_kfaux_RT] luma-alt
//!WHEN STR
//!COMPONENTS 1

vec4 hook() {

	return vec4(1.0 - HOOKED_tex(HOOKED_pos).x);

}

//!HOOK MAIN
//!BIND LUMA_A
//!SAVE BLUR_H1
//!DESC [eq_HDRR_kfaux_RT] blur pass1
//!WIDTH LUMA_A.w 2 /
//!HEIGHT LUMA_A.h 2 /
//!WHEN STR
//!COMPONENTS 1

vec4 hook() {

	const vec2 DIR = vec2(1.0, 0.0);
	const float w[4] = float[](0.19648255, 0.2969069, 0.12198224, 0.05432249);
	vec4 sum = LUMA_A_texOff(vec2(0.0)) * w[0];
	for (int i = 1; i < 4; i++)
		{ sum += LUMA_A_texOff(DIR * float(i)) * w[i]; sum += LUMA_A_texOff(DIR * -float(i)) * w[i]; }
	return sum;

}

//!HOOK MAIN
//!BIND BLUR_H1
//!SAVE BLUR_V1
//!DESC [eq_HDRR_kfaux_RT] blur pass1-2
//!WHEN STR
//!COMPONENTS 1

vec4 hook() {

	const vec2 DIR = vec2(0.0, 1.0);
	const float w[4] = float[](0.19648255, 0.2969069, 0.12198224, 0.05432249);
	vec4 sum = BLUR_H1_texOff(vec2(0.0)) * w[0];
	for (int i = 1; i < 4; i++)
		{ sum += BLUR_H1_texOff(DIR * float(i)) * w[i]; sum += BLUR_H1_texOff(DIR * -float(i)) * w[i]; }
	return sum;

}

//!HOOK MAIN
//!BIND BLUR_V1
//!SAVE BLUR_H2
//!DESC [eq_HDRR_kfaux_RT] blur pass2
//!WIDTH BLUR_V1.w 2 /
//!HEIGHT BLUR_V1.h 2 /
//!WHEN SIZE 1 > STR *
//!COMPONENTS 1

vec4 hook() {

	const vec2 DIR = vec2(1.0, 0.0);
	const float w[4] = float[](0.19648255, 0.2969069, 0.12198224, 0.05432249);
	vec4 sum = BLUR_V1_texOff(vec2(0.0)) * w[0];
	for (int i = 1; i < 4; i++)
		{ sum += BLUR_V1_texOff(DIR * float(i)) * w[i]; sum += BLUR_V1_texOff(DIR * -float(i)) * w[i]; }
	return sum;

}

//!HOOK MAIN
//!BIND BLUR_H2
//!SAVE BLUR_V2
//!DESC [eq_HDRR_kfaux_RT] blur pass2-2
//!WHEN SIZE 1 > STR *
//!COMPONENTS 1

vec4 hook() {

	const vec2 DIR = vec2(0.0, 1.0);
	const float w[4] = float[](0.19648255, 0.2969069, 0.12198224, 0.05432249);
	vec4 sum = BLUR_H2_texOff(vec2(0.0)) * w[0];
	for (int i = 1; i < 4; i++)
		{ sum += BLUR_H2_texOff(DIR * float(i)) * w[i]; sum += BLUR_H2_texOff(DIR * -float(i)) * w[i]; }
	return sum;

}

//!HOOK MAIN
//!BIND BLUR_V1
//!SAVE FINAL_M
//!DESC [eq_HDRR_kfaux_RT] mask-s1
//!WHEN SIZE 1 = STR *
//!COMPONENTS 1

vec4 hook() {

	return BLUR_V1_tex(BLUR_V1_pos);

}

//!HOOK MAIN
//!BIND BLUR_V1
//!BIND BLUR_V2
//!SAVE FINAL_M
//!DESC [eq_HDRR_kfaux_RT] mask-s2
//!WIDTH BLUR_V1.w
//!HEIGHT BLUR_V1.h
//!WHEN SIZE 2 = STR *
//!COMPONENTS 1

vec4 hook() {

	return BLUR_V1_tex(BLUR_V1_pos) + BLUR_V2_tex(BLUR_V1_pos);

}

//!HOOK MAIN
//!BIND HOOKED
//!BIND LUMA
//!BIND FINAL_M
//!DESC [eq_HDRR_kfaux_RT] fin
//!WHEN STR

#define BlendOverlay(base, blend)     mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), step(0.5, base))
#define BlendSoftLight(base, blend)   mix(2.0 * base * blend + base * base * (1.0 - 2.0 * blend), sqrt(base) * (2.0 * blend - 1.0) + 2.0 * base * (1.0 - blend), step(0.5, blend))

vec4 hook() {

	vec3 original_color = HOOKED_tex(HOOKED_pos).rgb;
	float y = LUMA_tex(LUMA_pos).x;
	vec3 mask_base = FINAL_M_tex(HOOKED_pos).rgb;

	if (SIZE == 2) {
		mask_base *= 0.5;
	}

	vec3 bw = pow(max(vec3(0.0), mask_base + MB), vec3(MC));
	vec3 obw = BlendOverlay(original_color, bw);
	obw = mix(max(obw, original_color), obw, smoothstep(y, 1.0, 1.0 - y - bw.x));
	obw = mix(min(obw, original_color), obw, 1.0 - smoothstep(0.0, y, bw.x - (1.0 - y)));

	vec3 target_color;
	target_color = mix(BlendSoftLight(original_color, obw), obw, SHIFT);
	vec3 effect_delta = target_color - original_color;
	vec3 final_color = original_color + effect_delta * STR;
	return vec4(final_color, 1.0);

}

