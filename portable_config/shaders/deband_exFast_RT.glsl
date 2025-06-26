// https://github.com/haasn/gentoo-conf/blob/xor/home/nand/.mpv/shaders/deband.glsl 的极简版

//!PARAM DBD
//!TYPE int
//!MINIMUM 0
//!MAXIMUM 1
1

//!PARAM STR
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 8192.0
48.0

/*
// PARAM DBD2
// TYPE int
// MINIMUM 0
// MAXIMUM 1
1

// PARAM STR2
// TYPE float
// MINIMUM 0.0
// MAXIMUM 8192.0
48.0
*/


//!DESC [deband_exFast_RT] deband luma 
//!HOOK LUMA
//!BIND HOOKED
//!WHEN DBD 0 >

#define STRENGTH STR

float mod289(float x)  { return x - floor(x / 289.0) * 289.0; }
float permute(float x) { return mod289((34.0*x + 1.0) * x); }
float rand(float x)    { return fract(x / 41.0); }

vec4 hook()  {

	vec3 _m = vec3(HOOKED_pos, 1.0) + vec3(1.0);
	float h = permute(permute(permute(_m.x)+_m.y)+_m.z);
	vec4 noise = vec4(rand(h), 0.5, 0.5, 0.5);;
	return HOOKED_tex(HOOKED_pos) + vec4(STRENGTH/8192.0) * (noise - 0.5);

}

/*
// DESC [deband_exFast_RT] deband chroma
// HOOK CHROMA
// BIND HOOKED
// WHEN DBD2 0 >

#define STRENGTH STR2

float mod289(float x)  { return x - floor(x / 289.0) * 289.0; }
float permute(float x) { return mod289((34.0*x + 1.0) * x); }
float rand(float x)    { return fract(x / 41.0); }

vec4 hook()  {
	vec3 _m = vec3(HOOKED_pos, 0.5) + vec3(1.0);
	float h = permute(permute(permute(_m.x)+_m.y)+_m.z);

	vec4 noise;
	noise.x = rand(h);
	h = permute(h);
	noise.y = rand(h);
	noise.zw = vec2(0.5);

	return HOOKED_tex(HOOKED_pos) + (STRENGTH/8192.0) * (noise - 0.5);

}
*/

