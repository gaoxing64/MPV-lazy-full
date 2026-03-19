// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM R
//!TYPE int
//!MINIMUM 0
//!MAXIMUM 255
0

//!PARAM G
//!TYPE int
//!MINIMUM 0
//!MAXIMUM 255
0

//!PARAM B
//!TYPE int
//!MINIMUM 0
//!MAXIMUM 255
0

//!PARAM SIM
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.0

//!PARAM BLEND
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.0

//!PARAM BKCM
//!TYPE int
//!MINIMUM 0
//!MAXIMUM 3
2


//!HOOK OUTPUT
//!BIND HOOKED
//!DESC [color_hold_RT]
//!WHEN BKCM

vec4 hook() {

	vec3 target_color = vec3(float(R), float(G), float(B)) / 255.0;
	vec4 original_color = HOOKED_texOff(vec2(0.0));
	float dist = distance(original_color.rgb, target_color) / sqrt(3.0);

	vec3 scaled_color;
	if (BKCM == 1) {
		scaled_color = vec3(0.0);
	} else if (BKCM == 2) {
		vec3 weights = vec3(0.299, 0.587, 0.114);
		float colorscale = dot(original_color.rgb, weights);
		scaled_color = vec3(colorscale);
	} else if (BKCM == 3) {
		scaled_color = vec3(1.0);
	}

	float mix_factor = smoothstep(SIM, SIM + BLEND, dist);
	vec3 final_rgb = mix(original_color.rgb, scaled_color, mix_factor);
	return vec4(final_rgb, original_color.a);

}

