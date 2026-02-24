// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM TAP
//!TYPE CONSTANT int
//!MINIMUM 1
//!MAXIMUM 9
5

//!PARAM SS
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 10.0
0.8

//!PARAM SR
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.1


//!HOOK LUMA
//!BIND HOOKED
//!SAVE LUMA_LOW_H
//!DESC [kBFDN_RT] low-pre
//!WHEN SS SR *

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
//!SAVE LUMA_LOW
//!DESC [kBFDN_RT] low
//!WHEN SS SR *

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
//!SAVE LUMA_HIGH
//!DESC [kBFDN_RT] high
//!WHEN SS SR *

vec4 hook() {

	vec2 pos = HOOKED_pos;
	float luma = HOOKED_tex(pos).x;
	float low_freq = LUMA_LOW_tex(LUMA_LOW_pos).x;
	float high_freq = luma - low_freq;
	return vec4(high_freq, 0.0, 0.0, 1.0);

}

//!HOOK LUMA
//!BIND LUMA_HIGH
//!SAVE LUMA_HIGH_DN_H
//!DESC [kBFDN_RT] high-dn-h
//!WHEN SS SR *

vec4 hook() {

	float center_luma = LUMA_HIGH_texOff(vec2(0.0, 0.0)).r;
	float total_weighted_luma = 0.0;
	float total_weight = 0.0;

	float two_sigma_s_sq = 2.0 * SS * SS;
	float two_sigma_r_sq = 2.0 * SR * SR;

	for (int x = -TAP; x <= TAP; x++) {
		float neighbor_luma = LUMA_HIGH_texOff(vec2(x, 0)).r;
		float distance_sq = float(x * x);
		float spatial_weight = exp(-distance_sq / two_sigma_s_sq);
		float luma_diff_sq = pow(center_luma - neighbor_luma, 2.0);
		float range_weight = exp(-luma_diff_sq / two_sigma_r_sq);
		float final_weight = spatial_weight * range_weight;
		total_weighted_luma += neighbor_luma * final_weight;
		total_weight += final_weight;
	}

	float final_luma = total_weighted_luma / total_weight;
	return vec4(vec3(final_luma), 1.0);

}

//!HOOK LUMA
//!BIND LUMA_HIGH
//!BIND LUMA_HIGH_DN_H
//!SAVE LUMA_HIGH_DN
//!DESC [kBFDN_RT] high-dn-v
//!WHEN SS SR *

vec4 hook() {

	float center_luma = LUMA_HIGH_texOff(vec2(0.0, 0.0)).r;
	float total_weighted_luma = 0.0;
	float total_weight = 0.0;
	float two_sigma_s_sq = 2.0 * SS * SS;
	float two_sigma_r_sq = 2.0 * SR * SR;

	for (int y = -TAP; y <= TAP; y++) {
		float neighbor_h_luma = LUMA_HIGH_DN_H_texOff(vec2(0, y)).r;
		float neighbor_ori_luma = LUMA_HIGH_texOff(vec2(0, y)).r;
		float distance_sq = float(y * y);
		float spatial_weight = exp(-distance_sq / two_sigma_s_sq);
		float luma_diff_sq = pow(center_luma - neighbor_ori_luma, 2.0);
		float range_weight = exp(-luma_diff_sq / two_sigma_r_sq);
		float final_weight = spatial_weight * range_weight;
		total_weighted_luma += neighbor_h_luma * final_weight;
		total_weight += final_weight;
	}

	float final_luma = total_weighted_luma / total_weight;
	return vec4(vec3(final_luma), 1.0);

}

//!HOOK LUMA
//!BIND HOOKED
//!BIND LUMA_LOW
//!BIND LUMA_HIGH_DN
//!DESC [kBFDN_RT] merge
//!WHEN SS SR *

vec4 hook() {

	vec2 pos = HOOKED_pos;
	float low_freq = LUMA_LOW_tex(pos).x;
	float denoised_high = LUMA_HIGH_DN_tex(pos).x;
	float merged_luma = low_freq + denoised_high;
	return vec4(merged_luma, 0.0, 0.0, 1.0);

}

