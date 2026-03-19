// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- RAW ver.
  https://github.com/mergian/dpid/blob/master/LICENSE.txt

*/


//!PARAM LBD
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 3.0
1.0


//!HOOK MAIN
//!BIND HOOKED
//!SAVE DPID_REF
//!DESC [DPID_RT] ref
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w HOOKED.w < OUTPUT.h HOOKED.h < *

vec4 hook() {

	const vec2 inv_scale = HOOKED_size / target_size;
	const vec2 src_pixel_size = HOOKED_pt;

	vec2 output_px = HOOKED_pos * target_size;
	vec2 region_start_uv = (output_px - 0.5) * inv_scale * src_pixel_size;
	vec2 region_end_uv = (output_px + 0.5) * inv_scale * src_pixel_size;

	vec2 region_start_px = region_start_uv / src_pixel_size;
	vec2 region_end_px = region_end_uv / src_pixel_size;

	ivec2 start_px = max(ivec2(0), ivec2(floor(region_start_px)));
	ivec2 end_px = min(ivec2(HOOKED_size), ivec2(ceil(region_end_px)));

	vec3 color_sum = vec3(0.0);
	float weight_sum = 0.0;

	for (int y = start_px.y; y < end_px.y; ++y) {
		for (int x = start_px.x; x < end_px.x; ++x) {
			vec2 current_px_coord = vec2(x, y) + 0.5;
			vec3 color = HOOKED_tex(current_px_coord * src_pixel_size).rgb;
			float coverage_x = max(0.0, min(current_px_coord.x + 0.5, region_end_px.x) - max(current_px_coord.x - 0.5, region_start_px.x));
			float coverage_y = max(0.0, min(current_px_coord.y + 0.5, region_end_px.y) - max(current_px_coord.y - 0.5, region_start_px.y));
			float contribution = coverage_x * coverage_y;
			color_sum += color * contribution;
			weight_sum += contribution;
		}
	}

	if (weight_sum < 1e-6) {
		return HOOKED_tex(HOOKED_pos);
	}

	return vec4(color_sum / weight_sum, 1.0);

}

//!HOOK MAIN
//!BIND DPID_REF
//!SAVE DPID_GD
//!DESC [DPID_RT] guide
//!WIDTH DPID_REF.w
//!HEIGHT DPID_REF.h
//!WHEN OUTPUT.w HOOKED.w < OUTPUT.h HOOKED.h < *

vec4 hook() {

	vec3 sum = vec3(0.0);
	sum += DPID_REF_texOff(vec2(-1, -1)).rgb * 1.0;
	sum += DPID_REF_texOff(vec2( 0, -1)).rgb * 2.0;
	sum += DPID_REF_texOff(vec2( 1, -1)).rgb * 1.0;
	sum += DPID_REF_texOff(vec2(-1,  0)).rgb * 2.0;
	sum += DPID_REF_texOff(vec2( 0,  0)).rgb * 4.0;
	sum += DPID_REF_texOff(vec2( 1,  0)).rgb * 2.0;
	sum += DPID_REF_texOff(vec2(-1,  1)).rgb * 1.0;
	sum += DPID_REF_texOff(vec2( 0,  1)).rgb * 2.0;
	sum += DPID_REF_texOff(vec2( 1,  1)).rgb * 1.0;
	return vec4(sum / 16.0, 1.0);

}

//!HOOK MAIN
//!BIND HOOKED
//!BIND DPID_GD
//!DESC [DPID_RT] dscale
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w HOOKED.w < OUTPUT.h HOOKED.h < *

vec4 hook() {

	vec3 guidance = DPID_GD_tex(DPID_GD_pos).rgb;

	const vec2 inv_scale = HOOKED_size / target_size;
	const vec2 src_pixel_size = HOOKED_pt;

	vec2 output_px = HOOKED_pos * target_size;
	vec2 region_start_uv = (output_px - 0.5) * inv_scale * src_pixel_size;
	vec2 region_end_uv = (output_px + 0.5) * inv_scale * src_pixel_size;

	vec2 region_start_px = region_start_uv / src_pixel_size;
	vec2 region_end_px = region_end_uv / src_pixel_size;

	ivec2 start_px = max(ivec2(0), ivec2(floor(region_start_px)));
	ivec2 end_px = min(ivec2(HOOKED_size), ivec2(ceil(region_end_px)));

	vec3 color_sum = vec3(0.0);
	float weight_sum = 0.0;
	const float Vmax = sqrt(3.0);

	for (int y = start_px.y; y < end_px.y; ++y) {
		for (int x = start_px.x; x < end_px.x; ++x) {
			vec2 current_px_coord = vec2(x, y) + 0.5;
			vec3 color = HOOKED_tex(current_px_coord * src_pixel_size).rgb;
			float coverage_x = max(0.0, min(current_px_coord.x + 0.5, region_end_px.x) - max(current_px_coord.x - 0.5, region_start_px.x));
			float coverage_y = max(0.0, min(current_px_coord.y + 0.5, region_end_px.y) - max(current_px_coord.y - 0.5, region_start_px.y));
			float contribution = coverage_x * coverage_y;
			float dist = length(color - guidance);
			float weight = (LBD < 1e-6) ? 1.0 : pow(dist / Vmax, LBD);
			color_sum += color * weight * contribution;
			weight_sum += weight * contribution;
		}
	}

	if (weight_sum < 1e-6) {
		return vec4(guidance, 1.0);
	} else {
		return vec4(color_sum / weight_sum, 1.0);
	}

}

