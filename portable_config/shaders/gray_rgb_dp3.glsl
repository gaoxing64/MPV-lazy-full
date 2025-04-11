
//!DESC [gray_rgb_dp3]
//!HOOK MAINPRESUB
//!BIND HOOKED

vec4 hook() {

	vec3 rgb = HOOKED_tex(HOOKED_pos).rgb;
	float intensity = dot(rgb, vec3(0.2040, 0.7649, 0.0361));
	rgb = vec3(intensity);

	return vec4(rgb, 1.0);

}

