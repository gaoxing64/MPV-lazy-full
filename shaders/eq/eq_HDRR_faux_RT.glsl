// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM SOFT
//!TYPE CONSTANT int
//!MINIMUM 0
//!MAXIMUM 1
1

//!PARAM RAD
//!TYPE float
//!MINIMUM 1.0
//!MAXIMUM 200.0
100.0

//!PARAM SIGMA
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 200.0
40.0

//!PARAM SHIFT
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.45


//!HOOK MAIN
//!BIND LUMA
//!SAVE BW
//!DESC [eq_HDRR_faux_RT] ref_pre
//!WHEN SIGMA
//!COMPONENTS 1

const float pi = 3.141592653589793;

vec4 hook() {

	vec2 dir = vec2(1.0, 0.0);
	float avg = 0.0;
	float coefficientSum = 0.0;
	float sigma = SIGMA;

	vec3 incrementalGaussian;
	incrementalGaussian.x = 1.0 / (sqrt(2.0 * pi) * sigma);
	incrementalGaussian.y = exp(-0.5 / (sigma * sigma));
	incrementalGaussian.z = incrementalGaussian.y * incrementalGaussian.y;

	avg += (1.0 - LUMA_tex(LUMA_pos).x) * incrementalGaussian.x;
	coefficientSum += incrementalGaussian.x;
	incrementalGaussian.xy *= incrementalGaussian.yz;

	for (float i = 1.0; i <= RAD; i++) {
		avg += (1.0 - LUMA_texOff(-i * dir).x) * incrementalGaussian.x;
		avg += (1.0 - LUMA_texOff( i * dir).x) * incrementalGaussian.x;
		coefficientSum += 2.0 * incrementalGaussian.x;
		incrementalGaussian.xy *= incrementalGaussian.yz;
	}

	return vec4(avg / coefficientSum);

}

//!HOOK MAIN
//!BIND HOOKED
//!BIND LUMA
//!BIND BW
//!DESC [eq_HDRR_faux_RT] mix
//!WHEN SIGMA

#define BlendOverlay(base, blend) 		mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), step(0.5, base))
#define BlendLinearLight(base, blend) 	mix(max(base + 2.0 * blend - 1.0, 0.0), min(base + 2.0 * (blend - 0.5), 1.0), step(0.5, blend))
#define BlendSoftLight(base, blend) 	mix(2.0 * base * blend + base * base * (1.0 - 2.0 * blend), sqrt(base) * (2.0 * blend - 1.0) + 2.0 * base * (1.0 - blend), step(0.5, blend))

const float pi = 3.141592653589793;

vec4 hook() {

	vec2 dir = vec2(0.0, 1.0);
	float avg = 0.0;
	float coefficientSum = 0.0;
	float sigma = SIGMA;

	vec3 incrementalGaussian;
	incrementalGaussian.x = 1.0 / (sqrt(2.0 * pi) * sigma);
	incrementalGaussian.y = exp(-0.5 / (sigma * sigma));
	incrementalGaussian.z = incrementalGaussian.y * incrementalGaussian.y;

	avg += BW_tex(BW_pos).x * incrementalGaussian.x;
	coefficientSum += incrementalGaussian.x;
	incrementalGaussian.xy *= incrementalGaussian.yz;

	for (float i = 1.0; i <= RAD; i++) {
		avg += BW_texOff(-i * dir).x * incrementalGaussian.x;
		avg += BW_texOff( i * dir).x * incrementalGaussian.x;
		coefficientSum += 2.0 * incrementalGaussian.x;
		incrementalGaussian.xy *= incrementalGaussian.yz;
	}

	vec4 o = HOOKED_texOff(vec2(0.0, 0.0));
	float y = LUMA_tex(LUMA_pos).x;
	vec3 bw = vec3(avg / coefficientSum);

	vec3 obw = BlendOverlay(o.xyz, bw);
	obw = clamp(obw, 0.0, 1.0);
	obw = mix(max(obw, o.rgb), obw, smoothstep(y, 1.0, 1.0 - y - bw.x));
	obw = clamp(obw, 0.0, 1.0);
	obw = mix(min(obw, o.rgb), obw, 1.0 - smoothstep(0.0, y, bw.x - (1.0 - y)));
	obw = clamp(obw, 0.0, 1.0);

	if (SOFT == 1) {
		o.xyz = mix(BlendSoftLight(o.xyz, obw), obw, SHIFT);
	} else if (SOFT == 0) {
		o.xyz = mix(BlendLinearLight(o.xyz, obw), obw, SHIFT);
	}

	o.xyz = clamp(o.xyz, 0.0, 1.0);
	return o;

}

