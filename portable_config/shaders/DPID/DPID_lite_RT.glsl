// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- RAW ver.
  https://github.com/mergian/dpid/blob/master/LICENSE.txt
  --- Magpie ver.
  https://github.com/Blinue/Magpie/blob/dev/LICENSE

*/


//!PARAM LBD
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 3.0
1.0


//!HOOK MAIN
//!BIND HOOKED
//!SAVE I1
//!DESC [DPID_lite_RT] raw -->> ref
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w HOOKED.w < OUTPUT.h HOOKED.h < *

vec4 hook() {

	const vec2 inv_scale = HOOKED_size / target_size;
	const vec2 input_pt = HOOKED_pt;
	vec2 output_coord = gl_FragCoord.xy;

	vec2 region_start_pix = (output_coord - 0.5) * inv_scale;
	vec2 region_step_pix = inv_scale / 4.0;
	vec3 sum = vec3(0.0);

	for (int y = 0; y < 4; ++y) {
		for (int x = 0; x < 4; ++x) {
			vec2 offset_pix = (vec2(x, y) + 0.5) * region_step_pix;
			vec2 uv_in = (region_start_pix + offset_pix) * input_pt;
			sum += texture(HOOKED_raw, uv_in).rgb;
		}
	}

	return vec4(sum / 16.0, 1.0);

}

//!HOOK MAIN
//!BIND I1
//!SAVE I2
//!DESC [DPID_lite_RT] ref -->> sample
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w HOOKED.w < OUTPUT.h HOOKED.h < *

vec4 hook() {

	vec3 sum = vec3(0.0);
	sum += I1_texOff(vec2(-1, -1)).rgb * 1.0;
	sum += I1_texOff(vec2( 0, -1)).rgb * 2.0;
	sum += I1_texOff(vec2( 1, -1)).rgb * 1.0;
	sum += I1_texOff(vec2(-1,  0)).rgb * 2.0;
	sum += I1_texOff(vec2( 0,  0)).rgb * 4.0;
	sum += I1_texOff(vec2( 1,  0)).rgb * 2.0;
	sum += I1_texOff(vec2(-1,  1)).rgb * 1.0;
	sum += I1_texOff(vec2( 0,  1)).rgb * 2.0;
	sum += I1_texOff(vec2( 1,  1)).rgb * 1.0;
	return vec4(sum / 16.0, 1.0);

}

//!HOOK MAIN
//!BIND HOOKED
//!BIND I2
//!DESC [DPID_lite_RT] dscale
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w HOOKED.w < OUTPUT.h HOOKED.h < *

vec4 hook() {

	const vec2 inv_scale = HOOKED_size / target_size;
	const vec2 input_pt = HOOKED_pt;
	vec2 output_coord = gl_FragCoord.xy;
	vec2 region_start_pix = (output_coord - 0.5) * inv_scale;
	vec2 region_step_pix = inv_scale / 4.0;

	vec3 guidance = I2_texOff(vec2(0.0)).rgb;
	vec3 colorSum = vec3(0.0);
	float weightSum = 0.0;
	const float Vmax = sqrt(3.0);

	for (int y = 0; y < 4; ++y) {
		for (int x = 0; x < 4; ++x) {
			vec2 offset_pix = (vec2(x, y) + 0.5) * region_step_pix;
			vec2 uv_in = (region_start_pix + offset_pix) * input_pt;
			vec3 color = texture(HOOKED_raw, uv_in).rgb;
			float dist = length(color - guidance);
			float weight = pow(dist / Vmax, LBD);
			colorSum += color * weight;
			weightSum += weight;
		}
	}

	if (weightSum < 1e-5) {
		return vec4(guidance, 1.0);
	} else {
		return vec4(colorSum / weightSum, 1.0);
	}

}

