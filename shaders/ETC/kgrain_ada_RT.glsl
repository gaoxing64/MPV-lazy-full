// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM STR
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.2

//!PARAM LS
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 100.0
20.0

//!PARAM GRAIN
//!TYPE DEFINE
//!MINIMUM 1
//!MAXIMUM 2
1

//!PARAM RAD
//!TYPE CONSTANT int
//!MINIMUM 1
//!MAXIMUM 9
4


//!HOOK LUMA
//!BIND HOOKED
//!DESC [kgrain_ada_RT]
//!WHEN STR

float permute(float x) {
	x = (34.0 * x + 1.0) * x;
	return fract(x * 1.0/289.0) * 289.0;
}

float seed(uvec2 pos) {
	const float phi = 1.61803398874989;
#if (GRAIN == 1)
	vec3 m = vec3(fract(phi * vec2(pos)), 0.5) + vec3(1.0);
#else
	vec3 m = vec3(fract(phi * vec2(pos)), random) + vec3(1.0);
#endif
	return permute(permute(m.x) + m.y) + m.z;
}

float rand(inout float state) {
	state = permute(state);
	return fract(state * 1.0/41.0);
}

float rand_gaussian(inout float state) {
	const float a0 = 0.151015505647689;
	const float a1 = -0.5303572634357367;
	const float a2 = 1.365020122861334;
	const float b0 = 0.132089632343748;
	const float b1 = -0.7607324991323768;
	float p = 0.95 * rand(state) + 0.025;
	float q = p - 0.5;
	float r = q * q;
	float g = q * (a2 + (a1 * r + a0) / (r*r + b1*r + b0));
	return g * 0.255121822830526;
}

vec4 hook() {

	vec4 color = HOOKED_texOff(0);
	float x = color.r;

	float local_luma_sum = 0.0;
	for (int i = -RAD; i <= RAD; i++) {
		for (int j = -RAD; j <= RAD; j++) {
			local_luma_sum += HOOKED_texOff(vec2(i, j)).r;
		}
	}
	const int samples = (2 * RAD + 1) * (2 * RAD + 1);
	float y_approx = local_luma_sum / float(samples);

	float poly_val = (1.124 * x - 9.466 * x * x + 36.624 * pow(x, 3) - 45.47 * pow(x, 4) + 18.188 * pow(x, 5));
	poly_val = clamp(poly_val, -1.0, 1.0);
	float mask = pow(1.0 - poly_val, y_approx * y_approx * LS);

	float state = seed(uvec2(HOOKED_pos * HOOKED_size));
	float grain = rand_gaussian(state) * STR;
	color.r += grain * mask;

	return color;

}

