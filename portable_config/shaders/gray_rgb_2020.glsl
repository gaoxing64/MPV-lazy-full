
//!DESC [gray_rgb_2020]
//!HOOK MAINPRESUB
//!BIND HOOKED

vec4 hook() {

	vec3 rgb = HOOKED_tex(HOOKED_pos).rgb;
	float intensity = dot(rgb, vec3(0.2627, 0.6780, 0.0593));
	rgb = vec3(intensity);

	return vec4(rgb, 1.0);

}

