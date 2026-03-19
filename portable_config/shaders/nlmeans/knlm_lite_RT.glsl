// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM STR
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 0.2
0.05


//!HOOK LUMA
//!BIND HOOKED
//!DESC [knlm_lite_RT] low-pre
//!SAVE LUMA_LOW_H
//!WHEN STR

#define KERNEL_SIZE 9
const float kernel[9] = float[9](
	0.0276305506, 0.0662822453, 0.1238315368,
	0.1801738229, 0.2041636887, 0.1801738229,
	0.1238315368, 0.0662822453, 0.0276305506
);

vec4 hook() {

	vec2 pos = HOOKED_pos;
	float low_freq_h = 0.0;
	for (int i = -KERNEL_SIZE/2; i <= KERNEL_SIZE/2; i++) {
		vec2 offset_x = vec2(i, 0) * HOOKED_pt;
		low_freq_h += HOOKED_tex(pos + offset_x).x * kernel[i + KERNEL_SIZE/2];
	}

	return vec4(low_freq_h, 0.0, 0.0, 1.0);

}

//!HOOK LUMA
//!BIND LUMA_LOW_H
//!DESC [knlm_lite_RT] low
//!SAVE LUMA_LOW
//!WHEN STR

#define KERNEL_SIZE 9
const float kernel[9] = float[9](
	0.0276305506, 0.0662822453, 0.1238315368,
	0.1801738229, 0.2041636887, 0.1801738229,
	0.1238315368, 0.0662822453, 0.0276305506
);

vec4 hook() {

	vec2 pos = LUMA_LOW_H_pos;
	float low_freq_v = 0.0;
	for (int i = -KERNEL_SIZE/2; i <= KERNEL_SIZE/2; i++) {
		vec2 offset_y = vec2(0, i) * LUMA_LOW_H_pt;
		low_freq_v += LUMA_LOW_H_tex(pos + offset_y).x * kernel[i + KERNEL_SIZE/2];
	}

	return vec4(low_freq_v, 0.0, 0.0, 1.0);
}

//!HOOK LUMA
//!BIND HOOKED
//!BIND LUMA_LOW
//!DESC [knlm_lite_RT] high
//!SAVE LUMA_HIGH
//!WHEN STR

vec4 hook() {

	vec2 pos = HOOKED_pos;
	float luma = HOOKED_tex(pos).x;
	float low_freq = LUMA_LOW_tex(LUMA_LOW_pos).x;
	float high_freq = luma - low_freq;
	return vec4(high_freq, 0.0, 0.0, 1.0);

}

//!HOOK LUMA
//!BIND LUMA_HIGH
//!DESC [knlm_lite_RT] high-dn
//!SAVE LUMA_HIGH_DN
//!WHEN STR

#define PATCH_SIZE   5
#define SEARCH_RANGE 7
#define H            STR

vec4 hook() {

	vec2 pos = LUMA_HIGH_pos;
	float sum_weights = 0.0;
	float sum_values = 0.0;
	const float H2 = H * H;
	if (H2 < 0.0001) {
		return vec4(LUMA_HIGH_tex(pos).x, 0.0, 0.0, 1.0);
	}

	int half_patch = PATCH_SIZE / 2;
	int half_search = SEARCH_RANGE / 2;

	for (int dy = -half_search; dy <= half_search; dy++) {
		for (int dx = -half_search; dx <= half_search; dx++) {
			vec2 offset = vec2(dx, dy) * LUMA_HIGH_pt;
			vec2 neighbor_pos = pos + offset;

			float patch_diff = 0.0;
			for (int py = -half_patch; py <= half_patch; py++) {
				for (int px = -half_patch; px <= half_patch; px++) {
					vec2 p_offset = vec2(px, py) * LUMA_HIGH_pt;
					float center_pixel = LUMA_HIGH_tex(pos + p_offset).x;
					float neighbor_pixel = LUMA_HIGH_tex(neighbor_pos + p_offset).x;
					float diff = center_pixel - neighbor_pixel;
					patch_diff += diff * diff;
				}
			}

			float weight = exp(-patch_diff / H2);
			sum_weights += weight;
			sum_values += weight * LUMA_HIGH_tex(neighbor_pos).x;
		}
	}

	float denoised_high = (sum_weights > 0.0) ? (sum_values / sum_weights) : LUMA_HIGH_tex(pos).x;
	return vec4(denoised_high, 0.0, 0.0, 1.0);

}

//!HOOK LUMA
//!BIND HOOKED
//!BIND LUMA_LOW
//!BIND LUMA_HIGH_DN
//!DESC [knlm_lite_RT] merge
//!WHEN STR

vec4 hook() {

	vec2 pos = HOOKED_pos;
	float low_freq = LUMA_LOW_tex(pos).x;
	float denoised_high = LUMA_HIGH_DN_tex(pos).x;
	float merged_luma = low_freq + denoised_high;
	return vec4(merged_luma, 0.0, 0.0, 1.0);

}

