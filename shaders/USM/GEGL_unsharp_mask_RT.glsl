// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- RAW ver.
  https://gitlab.gnome.org/GNOME/gegl/-/blob/master/COPYING
  --- DOC_RAW ver.
  https://docs.gimp.org/3.0/en/gimp-filter-unsharp-mask.html

*/


//!PARAM RAD
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 40.0
3.0

//!PARAM AMT
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 10.0
0.5

//!PARAM THR
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.0

//!PARAM MODE
//!TYPE DEFINE
//!MINIMUM 1
//!MAXIMUM 3
1


//!HOOK MAIN
//!BIND HOOKED
//!SAVE BLUR_H
//!DESC [GEGL_unsharp_mask_RT] hblur
//!WHEN RAD AMT *

float gaussian_weight(float offset, float sigma) {
	return exp(-(offset * offset) / (2.0 * sigma * sigma));
}

vec4 hook() {

	int kernel_radius = int(ceil(RAD * 3.0));
	vec4 sum = vec4(0.0);
	float weight_sum = 0.0;

	for (int i = -kernel_radius; i <= kernel_radius; i++) {
		float weight = gaussian_weight(float(i), RAD);
		sum += HOOKED_texOff(vec2(float(i), 0.0)) * weight;
		weight_sum += weight;
	}

	return sum / weight_sum;

}

//!HOOK MAIN
//!BIND HOOKED
//!BIND BLUR_H
//!DESC [GEGL_unsharp_mask_RT] vblur & merge
//!WHEN RAD AMT *

float gaussian_weight(float offset, float sigma) {
	return exp(-(offset * offset) / (2.0 * sigma * sigma));
}

vec4 hook() {

	vec4 original_color = HOOKED_tex(HOOKED_pos);
	int kernel_radius = int(ceil(RAD * 3.0));
	vec4 blurred_color = vec4(0.0);
	float weight_sum = 0.0;

	for (int j = -kernel_radius; j <= kernel_radius; j++) {
		float weight = gaussian_weight(float(j), RAD);
		blurred_color += BLUR_H_texOff(vec2(0.0, float(j))) * weight;
		weight_sum += weight;
	}
	blurred_color /= weight_sum;

#if (MODE == 3)
	return vec4(blurred_color.rgb, original_color.a);
#else
	vec3 mask = original_color.rgb - blurred_color.rgb;
	vec3 final_mask = mask;

	if (THR > 0.0001) {
		int aa_kernel_radius = int(ceil(1.0 * 3.0));
		vec3 soft_mask = vec3(0.0);
		float aa_weight_sum = 0.0;

		for (int j = -aa_kernel_radius; j <= aa_kernel_radius; j++) {
			for (int i = -aa_kernel_radius; i <= aa_kernel_radius; i++) {
				vec3 neighbor_original = HOOKED_texOff(vec2(i, j)).rgb;
				vec3 neighbor_mask_val = neighbor_original - blurred_color.rgb;
				vec3 threshold_input = abs(neighbor_mask_val) * 2.0;
				vec3 binary_mask = step(vec3(THR), threshold_input);
				float aa_weight = gaussian_weight(length(vec2(i, j)), 1.0);
				soft_mask += binary_mask * aa_weight;
				aa_weight_sum += aa_weight;
			}
		}

		soft_mask /= aa_weight_sum;
		final_mask = mask * soft_mask;
	}
#endif

#if (MODE == 1)
	vec3 final_color = original_color.rgb + final_mask * AMT;
	return vec4(final_color, original_color.a);
#elif (MODE == 2)
	vec3 final_color = original_color.rgb - final_mask * AMT;
	return vec4(final_color, original_color.a);
#endif

}

