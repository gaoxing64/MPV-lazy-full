// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM MODE
//!TYPE DEFINE
//!MINIMUM 1
//!MAXIMUM 2
1

//!PARAM CTP
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.2

//!PARAM STR
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 2.0
1.0


//!HOOK SCALED
//!BIND HOOKED
//!DESC [kNLS_RT]
//!WHEN STR

float nonlinear_map(float x, float stretch_factor) {
#if MODE == 1

	float sign_x = sign(x);
	float abs_x = abs(x);
	float source_x;

	if (abs_x <= CTP) {
		source_x = abs_x * stretch_factor;
	} else {
		float center_src = CTP * stretch_factor;
		if (center_src >= 1.0) {
			source_x = 1.0;
		} else {
			float t = (abs_x - CTP) / (1.0 - CTP);
			float src_range = 1.0 - center_src;
			float required_slope = stretch_factor * (1.0 - CTP) / src_range;
			float base_n = required_slope;
			float n = clamp(base_n * STR, 0.3, 6.0);
			float g = 1.0 - pow(1.0 - t, n);
			source_x = center_src + src_range * g;
		}
	}

	source_x = clamp(source_x, 0.0, 1.0);
	return sign_x * source_x;

#elif MODE == 2

	float k = stretch_factor - 1.0;
	float blend = 1.0 - x * x;
	float source_x = x * (1.0 + blend * k * STR);
	return clamp(source_x, -1.0, 1.0);

#endif
}

vec4 hook() {

	float video_aspect = input_size.x / input_size.y;
	float display_aspect = target_size.x / target_size.y;
	float aspect_ratio = display_aspect / video_aspect;
	vec2 pos = HOOKED_pos;
	vec2 sample_pos = pos;

	if (abs(aspect_ratio - 1.0) < 0.001) {
		return HOOKED_tex(pos);
	}

	if (aspect_ratio > 1.0) {
		float x = pos.x * 2.0 - 1.0;
		float source_x = nonlinear_map(x, aspect_ratio);
		sample_pos.x = source_x * 0.5 + 0.5;
	} else {
		float y = pos.y * 2.0 - 1.0;
		float source_y = nonlinear_map(y, 1.0 / aspect_ratio);
		sample_pos.y = source_y * 0.5 + 0.5;
	}

	sample_pos = clamp(sample_pos, 0.0, 1.0);
	return HOOKED_tex(sample_pos);

}

