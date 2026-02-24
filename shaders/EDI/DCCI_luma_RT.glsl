// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- PAPER ver.
  https://nlpr.ia.ac.cn/2012papers/gjkw/gk46.pdf

*/


//!PARAM T
//!TYPE float
//!MINIMUM 1.0
//!MAXIMUM 2.0
1.15

//!PARAM K
//!TYPE float
//!MINIMUM 1.0
//!MAXIMUM 10.0
5.0


//!HOOK LUMA
//!BIND HOOKED
//!SAVE DCCI_LUMA_PRE
//!DESC [DCCI_luma_RT] pre
//!WIDTH HOOKED.w 2 *
//!HEIGHT HOOKED.h 2 *
//!WHEN OUTPUT.w HOOKED.w 1.200 * > OUTPUT.h HOOKED.h 1.200 * > *

const vec4 CUBIC_WEIGHTS = vec4(-0.0625, 0.5625, 0.5625, -0.0625);

float getPixel(ivec2 coord) {
	return texelFetch(HOOKED_raw, coord, 0).x * HOOKED_mul;
}

vec4 hook() {

	ivec2 hr_coord = ivec2(floor(gl_FragCoord.xy));
	bvec2 is_odd = bvec2(hr_coord % 2);

	if (!is_odd.x && !is_odd.y) {
		ivec2 lr_coord = hr_coord / 2;
		return vec4(getPixel(lr_coord), 0.0, 0.0, 1.0);
	}

	if (is_odd.x && is_odd.y) {
		ivec2 lr_origin = (hr_coord - 1) / 2 - ivec2(1);

		#define P(r, c) getPixel(lr_origin + ivec2(c, r))

		float d1 = 0.0;
		d1 += abs(P(1,0) - P(0,1));
		d1 += abs(P(2,0) - P(1,1)) + abs(P(1,1) - P(0,2));
		d1 += abs(P(3,0) - P(2,1)) + abs(P(2,1) - P(1,2)) + abs(P(1,2) - P(0,3));
		d1 += abs(P(3,1) - P(2,2)) + abs(P(2,2) - P(1,3));
		d1 += abs(P(3,2) - P(2,3));

		float d2 = 0.0;
		d2 += abs(P(0,2) - P(1,3));
		d2 += abs(P(0,1) - P(1,2)) + abs(P(1,2) - P(2,3));
		d2 += abs(P(0,0) - P(1,1)) + abs(P(1,1) - P(2,2)) + abs(P(2,2) - P(3,3));
		d2 += abs(P(1,0) - P(2,1)) + abs(P(2,1) - P(3,2));
		d2 += abs(P(2,0) - P(3,1));

		float v1_0 = P(0, 3), v1_1 = P(1, 2), v1_2 = P(2, 1), v1_3 = P(3, 0);
		float v2_0 = P(0, 0), v2_1 = P(1, 1), v2_2 = P(2, 2), v2_3 = P(3, 3);

		#undef P

		float p1 = CUBIC_WEIGHTS.x * v1_0 + CUBIC_WEIGHTS.y * v1_1 + CUBIC_WEIGHTS.z * v1_2 + CUBIC_WEIGHTS.w * v1_3;
		float p2 = CUBIC_WEIGHTS.x * v2_0 + CUBIC_WEIGHTS.y * v2_1 + CUBIC_WEIGHTS.z * v2_2 + CUBIC_WEIGHTS.w * v2_3;

		float result;
		if ((1.0 + d1) / (1.0 + d2) > T) {
			result = p2;
		} else if ((1.0 + d2) / (1.0 + d1) > T) {
			result = p1;
		} else {
			float w1 = 1.0 / (1.0 + pow(d1, K));
			float w2 = 1.0 / (1.0 + pow(d2, K));
			result = (w1 * p1 + w2 * p2) / (w1 + w2);
		}
		return vec4(result, 0.0, 0.0, 1.0);
	}

	return vec4(0.0, 0.0, 0.0, 1.0);

}

//!HOOK LUMA
//!BIND DCCI_LUMA_PRE
//!BIND HOOKED
//!DESC [DCCI_luma_RT] fin
//!WIDTH HOOKED.w 2 *
//!HEIGHT HOOKED.h 2 *
//!WHEN OUTPUT.w HOOKED.w 1.200 * > OUTPUT.h HOOKED.h 1.200 * > *

const vec4 CUBIC_WEIGHTS = vec4(-0.0625, 0.5625, 0.5625, -0.0625);

float getMixedPixel(ivec2 coord) {
	bvec2 is_odd = bvec2(coord % 2);
	if (!is_odd.x && !is_odd.y) {
		return texelFetch(HOOKED_raw, coord / 2, 0).x * HOOKED_mul;
	} else {
		return texelFetch(DCCI_LUMA_PRE_raw, coord, 0).x * DCCI_LUMA_PRE_mul;
	}
}

vec4 hook() {

	ivec2 hr_coord = ivec2(floor(gl_FragCoord.xy));
	bvec2 is_odd = bvec2(hr_coord % 2);

	if (is_odd.x == is_odd.y) {
		return vec4(texelFetch(DCCI_LUMA_PRE_raw, hr_coord, 0).x * DCCI_LUMA_PRE_mul, 0.0, 0.0, 1.0);
	}

	#define A5(r, c) getMixedPixel(hr_coord + ivec2(c - 2, r - 2))

	float d1 = 0.0;
	d1 += abs(A5(0,1) - A5(0,3)) + abs(A5(2,1) - A5(2,3)) + abs(A5(4,1) - A5(4,3));
	d1 += abs(A5(1,0) - A5(1,2)) + abs(A5(1,2) - A5(1,4));
	d1 += abs(A5(3,0) - A5(3,2)) + abs(A5(3,2) - A5(3,4));

	float d2 = 0.0;
	d2 += abs(A5(1,0) - A5(3,0)) + abs(A5(1,2) - A5(3,2)) + abs(A5(1,4) - A5(3,4));
	d2 += abs(A5(0,1) - A5(2,1)) + abs(A5(2,1) - A5(4,1));
	d2 += abs(A5(0,3) - A5(2,3)) + abs(A5(2,3) - A5(4,3));

	#undef A5
	#define A7(r, c) getMixedPixel(hr_coord + ivec2(c - 3, r - 3))

	float h0 = A7(3, 0), h1 = A7(3, 2), h2 = A7(3, 4), h3 = A7(3, 6);
	float v0 = A7(0, 3), v1 = A7(2, 3), v2 = A7(4, 3), v3 = A7(6, 3);

	#undef A7

	float p1 = CUBIC_WEIGHTS.x * h0 + CUBIC_WEIGHTS.y * h1 + CUBIC_WEIGHTS.z * h2 + CUBIC_WEIGHTS.w * h3;
	float p2 = CUBIC_WEIGHTS.x * v0 + CUBIC_WEIGHTS.y * v1 + CUBIC_WEIGHTS.z * v2 + CUBIC_WEIGHTS.w * v3;

	float result;
	if ((1.0 + d1) / (1.0 + d2) > T) {
		result = p2;
	} else if ((1.0 + d2) / (1.0 + d1) > T) {
		result = p1;
	} else {
		float w1 = 1.0 / (1.0 + pow(d1, K));
		float w2 = 1.0 / (1.0 + pow(d2, K));
		result = (w1 * p1 + w2 * p2) / (w1 + w2);
	}

	return vec4(result, 0.0, 0.0, 1.0);

}

