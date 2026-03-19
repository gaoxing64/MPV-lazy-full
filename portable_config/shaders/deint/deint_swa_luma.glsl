// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!HOOK LUMA
//!BIND HOOKED
//!DESC [deint_swa_luma]

vec4 hook() {

	vec4 current = HOOKED_tex(HOOKED_pos);

	vec4 above = HOOKED_texOff(vec2(0.0, -1.0));
	vec4 below = HOOKED_texOff(vec2(0.0, 1.0));

	float current_weight = 50 * 0.01;
	float neighbor_weight = (1.0 - current_weight) / 2;

	vec4 result = current * current_weight;
	result += above * neighbor_weight;
	result += below * neighbor_weight;

	return result;

}

