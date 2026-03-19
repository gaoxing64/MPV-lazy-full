// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- RAW ver.
  https://github.com/Khanattila/KNLMeansCL

*/


//!PARAM S
//!TYPE int
//!MINIMUM 1
//!MAXIMUM 4
2

//!PARAM A
//!TYPE int
//!MINIMUM 1
//!MAXIMUM 4
2

//!PARAM H
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 10.0
1.2

//!PARAM WMODE
//!TYPE int
//!MINIMUM 1
//!MAXIMUM 4
1

//!PARAM WREF
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 2.0
1.0

//!PARAM HFO
//!TYPE int
//!MINIMUM 0
//!MAXIMUM 1
0

//!PARAM SIGMA_S
//!TYPE float
//!MINIMUM 1.0
//!MAXIMUM 10.0
3.0

//!PARAM SIGMA_R
//!TYPE float
//!MINIMUM 0.01
//!MAXIMUM 0.5
0.1


//!HOOK LUMA
//!BIND HOOKED
//!DESC [knlm2_RT] bilateral low-freq
//!SAVE LUMA_LOW
//!WHEN HFO H *

#define BILA_RAD 4

vec4 hook() {

	vec2 pos = HOOKED_pos;
	float center = HOOKED_tex(pos).x;
	float sum = 0.0;
	float weight_sum = 0.0;

	for (int dy = -BILA_RAD; dy <= BILA_RAD; dy++) {
		for (int dx = -BILA_RAD; dx <= BILA_RAD; dx++) {
			vec2 offset = vec2(float(dx), float(dy)) * HOOKED_pt;
			float neighbor = HOOKED_tex(pos + offset).x;
			float spatial_dist = float(dx * dx + dy * dy);
			float spatial_weight = exp(-spatial_dist / (2.0 * SIGMA_S * SIGMA_S));
			float range_diff = neighbor - center;
			float range_weight = exp(-(range_diff * range_diff) / (2.0 * SIGMA_R * SIGMA_R));
			float weight = spatial_weight * range_weight;
			sum += neighbor * weight;
			weight_sum += weight;
		}
	}

	float low_freq = sum / max(weight_sum, 1e-6);
	return vec4(low_freq, 0.0, 0.0, 1.0);

}

//!HOOK LUMA
//!BIND HOOKED
//!BIND LUMA_LOW
//!DESC [knlm2_RT] extract high-freq
//!SAVE LUMA_HIGH
//!WHEN HFO H *

vec4 hook() {

	float luma = HOOKED_tex(HOOKED_pos).x;
	float low_freq = LUMA_LOW_tex(LUMA_LOW_pos).x;
	float high_freq = luma - low_freq;
	return vec4(high_freq, 0.0, 0.0, 1.0);

}

//!HOOK LUMA
//!BIND LUMA_HIGH
//!DESC [knlm2_RT] NLMeans high-freq denoise
//!SAVE LUMA_HIGH_DN
//!WHEN HFO H *

#define EPSILON 1e-6

float patch_ssd(vec2 center_pos, vec2 neighbor_pos) {
	float sum = 0.0;
	for (int py = -S; py <= S; py++) {
		for (int px = -S; px <= S; px++) {
			vec2 offset = vec2(float(px), float(py)) * LUMA_HIGH_pt;
			float center_val = LUMA_HIGH_tex(center_pos + offset).x;
			float neighbor_val = LUMA_HIGH_tex(neighbor_pos + offset).x;
			float diff = center_val - neighbor_val;
			sum += diff * diff * 3.0;
		}
	}
	return sum;
}

float compute_weight(float ssd) {
	float patch_size = float(2 * S + 1);
	float h_normalized = H / 255.0;
	float h2_inv_norm = 1.0 / (3.0 * patch_size * patch_size * h_normalized * h_normalized);
	float val = ssd * h2_inv_norm;
	if (WMODE == 1) {
		return exp(-val);
	} else if (WMODE == 2) {
		return max(0.0, 1.0 - val);
	} else if (WMODE == 3) {
		float w = max(0.0, 1.0 - val);
		return w * w;
	} else {
		float w = max(0.0, 1.0 - val);
		w = w * w;
		w = w * w;
		w = w * w;
		return w;
	}
}

vec4 hook() {

	vec2 pos = LUMA_HIGH_pos;
	float center_val = LUMA_HIGH_tex(pos).x;
	float sum = 0.0;
	float total_weight = 0.0;
	float max_weight = 0.0;

	for (int oy = -A; oy <= A; oy++) {
		for (int ox = -A; ox <= A; ox++) {
			if (ox == 0 && oy == 0) continue;
			vec2 offset = vec2(float(ox), float(oy)) * LUMA_HIGH_pt;
			vec2 neighbor_pos = pos + offset;
			float ssd = patch_ssd(pos, neighbor_pos);
			float weight = compute_weight(ssd);
			sum += weight * LUMA_HIGH_tex(neighbor_pos).x;
			total_weight += weight;
			max_weight = max(max_weight, weight);
		}
	}

	float center_weight = WREF * max(max_weight, EPSILON);
	sum += center_weight * center_val;
	total_weight += center_weight;
	float result = sum / max(total_weight, EPSILON);
	return vec4(result, 0.0, 0.0, 1.0);

}

//!HOOK LUMA
//!BIND LUMA_LOW
//!BIND LUMA_HIGH_DN
//!DESC [knlm2_RT] merge low & high
//!WHEN HFO H *

vec4 hook() {

	float low_freq = LUMA_LOW_tex(LUMA_LOW_pos).x;
	float denoised_high = LUMA_HIGH_DN_tex(LUMA_HIGH_DN_pos).x;
	float merged = low_freq + denoised_high;
	return vec4(merged, 0.0, 0.0, 1.0);

}

//!HOOK LUMA
//!BIND HOOKED
//!DESC [knlm2_RT] NLMeans Denoise
//!WHEN HFO 0 = H *

#define EPSILON 1e-6

float patch_ssd(vec2 center_pos, vec2 neighbor_pos) {
	float sum = 0.0;
	for (int py = -S; py <= S; py++) {
		for (int px = -S; px <= S; px++) {
			vec2 offset = vec2(float(px), float(py)) * HOOKED_pt;
			float center_val = HOOKED_tex(center_pos + offset).x;
			float neighbor_val = HOOKED_tex(neighbor_pos + offset).x;
			float diff = center_val - neighbor_val;
			sum += diff * diff * 3.0;
		}
	}
	return sum;
}

float compute_weight(float ssd) {
	float patch_size = float(2 * S + 1);
	float h_normalized = H / 255.0;
	float h2_inv_norm = 1.0 / (3.0 * patch_size * patch_size * h_normalized * h_normalized);
	float val = ssd * h2_inv_norm;
	if (WMODE == 1) {
		return exp(-val);
	} else if (WMODE == 2) {
		return max(0.0, 1.0 - val);
	} else if (WMODE == 3) {
		float w = max(0.0, 1.0 - val);
		return w * w;
	} else {
		float w = max(0.0, 1.0 - val);
		w = w * w;
		w = w * w;
		w = w * w;
		return w;
	}
}

vec4 hook() {

	vec2 pos = HOOKED_pos;
	float center_val = HOOKED_tex(pos).x;
	float sum = 0.0;
	float total_weight = 0.0;
	float max_weight = 0.0;

	for (int oy = -A; oy <= A; oy++) {
		for (int ox = -A; ox <= A; ox++) {
			if (ox == 0 && oy == 0) continue;
			vec2 offset = vec2(float(ox), float(oy)) * HOOKED_pt;
			vec2 neighbor_pos = pos + offset;
			float ssd = patch_ssd(pos, neighbor_pos);
			float weight = compute_weight(ssd);
			sum += weight * HOOKED_tex(neighbor_pos).x;
			total_weight += weight;
			max_weight = max(max_weight, weight);
		}
	}

	float center_weight = WREF * max(max_weight, EPSILON);
	sum += center_weight * center_val;
	total_weight += center_weight;
	float result = sum / max(total_weight, EPSILON);
	return vec4(result, 0.0, 0.0, 1.0);

}

