
//!DESC [gray_rgb_601]
//!HOOK MAINPRESUB
//!BIND HOOKED

vec4 hook() {

	vec3 rgb = HOOKED_tex(HOOKED_pos).rgb;
	float intensity = dot(rgb, vec3(0.299, 0.587, 0.114));
	rgb = vec3(intensity);

	return vec4(rgb, 1.0);

}

