// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM THR
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 255.0
8.0


//!HOOK MAIN
//!BIND HOOKED
//!DESC [kCCD_RT]
//!WHEN THR

vec4 hook() {

	float threshold = (THR * THR) / 195075.0;
	vec4 color_c = HOOKED_texOff(vec2(0.0, 0.0));
	vec3 color_sum = color_c.rgb;
	float count = 1.0;

	const vec2 offsets[16] = vec2[](
		vec2(-12.0, -12.0), vec2(-4.0, -12.0), vec2(4.0, -12.0), vec2(12.0, -12.0),
		vec2(-12.0, -4.0),  vec2(-4.0, -4.0),  vec2(4.0, -4.0),  vec2(12.0, -4.0),
		vec2(-12.0,  4.0),  vec2(-4.0,  4.0),  vec2(4.0,  4.0),  vec2(12.0,  4.0),
		vec2(-12.0,  12.0), vec2(-4.0,  12.0), vec2(4.0,  12.0), vec2(12.0,  12.0)
	);

	for (int i = 0; i < 16; i++) {
		vec3 color_nb = HOOKED_texOff(offsets[i]).rgb;
		vec3 diff = color_c.rgb - color_nb;
		float dist = dot(diff, diff);
		if (dist < threshold) {
			color_sum += color_nb;
			count += 1.0;
		}
	}

	return vec4(color_sum / count, color_c.a);

}

