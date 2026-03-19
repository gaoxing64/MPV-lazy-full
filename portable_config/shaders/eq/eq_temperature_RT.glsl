// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM TP
//!TYPE float
//!MINIMUM -100.0
//!MAXIMUM 100.0
0.0


//!HOOK MAIN
//!BIND HOOKED
//!DESC [eq_temperature_RT]
//!WHEN TP

vec3 TGain(vec3 color, float gain) {
	float red_gain = 1.0 - gain;
	float blue_gain = 1.0 + gain;
	red_gain = max(red_gain, 0.0);
	blue_gain = max(blue_gain, 0.0);
	color.r *= red_gain;
	color.b *= blue_gain;
	return color;
}

vec4 hook() {

	vec4 color = HOOKED_texOff(0);
	color = linearize(color);
	color.rgb = TGain(color.rgb, TP / 100.0 );
	color = delinearize(color);
	return color;

}

