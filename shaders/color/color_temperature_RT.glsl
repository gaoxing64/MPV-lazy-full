// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM TP
//!TYPE float
//!MINIMUM 1000.0
//!MAXIMUM 10000.0
6504.0


//!HOOK MAIN
//!BIND HOOKED
//!DESC [color_temperature_RT]

vec3 CtToRGB(float temperature) {
	temperature /= 100.0;
	float red, green, blue;

	// https://tannerhelland.com/2012/09/18/convert-temperature-rgb-algorithm-code.html
	if (temperature <= 66.0) {
		red = 255.0;
		green = temperature;
		green = 99.4708025861 * log(green) - 161.1195681661;
		if (temperature <= 19.0) {
			blue = 0.0;
		} else {
			blue = temperature - 10.0;
			blue = 138.5177312231 * log(blue) - 305.0447927307;
		}
	} else {
		red = temperature - 60.0;
		red = 329.698727446 * pow(red, -0.1332047592);
		green = temperature - 60.0;
		green = 288.1221695283 * pow(green, -0.0755148492);
		blue = 255.0;
	}

	red = clamp(red, 0.0, 255.0) / 255.0;
	green = clamp(green, 0.0, 255.0) / 255.0;
	blue = clamp(blue, 0.0, 255.0) / 255.0;
	return vec3(red, green, blue);
}

vec4 hook() {

	vec4 color = HOOKED_texOff(0);
	color = linearize(color);
	vec3 gain = CtToRGB(TP);
	float gain_max = max(gain.r, max(gain.g, gain.b));
	gain /= gain_max;
	color.rgb *= gain;
	color = delinearize(color);
	return color;

}

