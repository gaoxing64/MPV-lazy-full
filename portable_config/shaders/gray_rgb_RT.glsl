
//!PARAM PRIM
//!TYPE DEFINE
//!DESC int
//!MINIMUM 1
//!MAXIMUM 4
2

//!DESC [gray_rgb_RT]
//!HOOK MAINPRESUB
//!BIND HOOKED

vec4 hook() {

	vec3 rgb = HOOKED_tex(HOOKED_pos).rgb;
	vec3 factor;

#if (PRIM == 1)
	factor = vec3(0.299, 0.587, 0.114);
#elif (PRIM == 2)
	factor = vec3(0.2126, 0.7152, 0.0722);
#elif (PRIM == 3)
	factor = vec3(0.2040, 0.7649, 0.0361);
#elif (PRIM == 4)
	factor = vec3(0.2627, 0.6780, 0.0593);
#endif

	float intensity = dot(rgb, factor);
	rgb = vec3(intensity);

	return vec4(rgb, 1.0);

}

