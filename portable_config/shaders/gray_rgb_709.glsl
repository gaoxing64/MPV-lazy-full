
//!DESC [gray_rgb_709]
//!HOOK MAINPRESUB
//!BIND HOOKED

vec4 hook() {

	vec3 rgb = HOOKED_tex(HOOKED_pos).rgb;
	float intensity = dot(rgb, vec3(0.2126, 0.7152, 0.0722));
	rgb = vec3(intensity);

	return vec4(rgb, 1.0);

}

