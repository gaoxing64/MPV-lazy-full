// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- RAW ver.
  https://www.shadertoy.com/view/sdKSD3

*/


//!PARAM SPD
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1000.0
60.0


//!HOOK OUTPUT
//!BIND HOOKED
//!DESC [MandelbrotSet_lite_FX_RT]

#define iResolution HOOKED_size
#define fragCoord   (HOOKED_pos * HOOKED_size)
#define iTime       (float(frame) / SPD)

int mandelbrot(vec2 c) {
	vec2 z = c;
	for (int i = 0; i < 1500; i++) {
		if (dot(z, z) > 4.0) return i;
		z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
	}
	return 0;
}

float zoom(float t) {
	float a = floor(t / 24.0);
	return 3.0 * (exp(-t + 24.0 * a) + exp(t - 24.0 - 24.0 * a));
}

vec4 hook() {

	vec2 c = (fragCoord.xy * 2.0 - iResolution.xy) * zoom(iTime) / iResolution.x;
	c += vec2(-1.253443441, 0.384693578);
	float iters = float(mandelbrot(c));
	vec3 col = sin(vec3(0.1, 0.2, 0.5) * iters);
	return vec4(col, 1.0);

}

