// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- RAW ver.
  https://github.com/GPUOpen-LibrariesAndSDKs/FidelityFX-SDK/blob/v1.1.4/sdk/include/FidelityFX/gpu/lens/ffx_lens.h

*/


//!PARAM CA
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 10.0
1.0

//!PARAM VIG
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 2.0
0.8

//!PARAM GRAIN_S
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 64.0
16.0

//!PARAM GRAIN_A
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.15


//!HOOK MAIN
//!BIND HOOKED
//!DESC [AMD_FidelityFX_Lens_RT] (SDK v1.1.4)
//!WHEN CA VIG + GRAIN_A GRAIN_S * + 0 >

#define FFX_PI 3.14159265358979323846

uvec3 pcg3d16(uvec3 v) {
	v = v * 12829u + 47989u;
	v.x += v.y * v.z;
	v.y += v.z * v.x;
	v.z += v.x * v.y;
	v.x += v.y * v.z;
	v.y += v.z * v.x;
	v.z += v.x * v.y;
	v >>= 16u;
	return v;
}

vec2 toFloat16(uvec2 inputVal) {
	return vec2(inputVal) * (1.0 / 65536.0) - 0.5;
}

vec2 simplex(vec2 P) {
	const float F2 = (sqrt(3.0) - 1.0) / 2.0;
	const float G2 = (3.0 - sqrt(3.0)) / 6.0;
	float u = (P.x + P.y) * F2;
	vec2 Pi = round(P + u);
	float v = (Pi.x + Pi.y) * G2;
	vec2 P0 = Pi - v;
	vec2 Pf0 = P - P0;
	return Pf0;
}

// 色差
vec2 GetRGMag(float chromAbIntensity) {
	const float A = 1.5220;
	const float B = 0.00459 * chromAbIntensity;
	const float redWaveLengthUM   = 0.612;
	const float greenWaveLengthUM = 0.549;
	const float blueWaveLengthUM  = 0.464;
	float redIdxRefraction   = A + B / (redWaveLengthUM * redWaveLengthUM);
	float greenIdxRefraction = A + B / (greenWaveLengthUM * greenWaveLengthUM);
	float blueIdxRefraction  = A + B / (blueWaveLengthUM * blueWaveLengthUM);
	float redMag   = (redIdxRefraction - 1.0) / (blueIdxRefraction - 1.0);
	float greenMag = (greenIdxRefraction - 1.0) / (blueIdxRefraction - 1.0);
	return vec2(redMag, greenMag);
}

vec3 SampleWithChromaticAberration(vec2 coord, vec2 centerCoord, float redMag, float greenMag) {
	vec2 redShift = (coord - centerCoord) * redMag + centerCoord + 0.5;
	redShift /= (2.0 * centerCoord);
	vec2 greenShift = (coord - centerCoord) * greenMag + centerCoord + 0.5;
	greenShift /= (2.0 * centerCoord);
	vec2 blueCoord = (coord + 0.5) / (2.0 * centerCoord);
	float red   = HOOKED_tex(redShift).r;
	float green = HOOKED_tex(greenShift).g;
	float blue  = HOOKED_tex(blueCoord).b;
	return vec3(red, green, blue);
}

// 暗角
void ApplyVignette(vec2 coord, vec2 centerCoord, inout vec3 color, float vignetteAmount) {
	vec2 coordFromCenter = abs(coord - centerCoord) / centerCoord;
	const float piOver4 = FFX_PI * 0.25;
	vec2 vignetteMask = cos(coordFromCenter * vignetteAmount * piOver4);
	vignetteMask = vignetteMask * vignetteMask;
	vignetteMask = vignetteMask * vignetteMask;
	color *= clamp(vignetteMask.x * vignetteMask.y, 0.0, 1.0);
}

// 胶片颗粒
void ApplyFilmGrain(ivec2 coord, inout vec3 color, float grainScale, float grainAmount, uint grainSeed) {
	vec2 randomNumberFine = toFloat16(pcg3d16(uvec3(vec2(coord) / (grainScale / 8.0), grainSeed)).xy);
	vec2 simplexP = simplex(vec2(coord) / grainScale + randomNumberFine);
	const float grainShape = 3.0;
	float grain = 1.0 - 2.0 * exp2(-length(simplexP) * grainShape);
	color += grain * min(color, 1.0 - color) * grainAmount;
}

vec4 hook() {

	vec2 coord = HOOKED_pos * HOOKED_size;
	vec2 centerCoord = HOOKED_size * 0.5;
	vec4 original = HOOKED_texOff(0);
	vec3 color = original.rgb;
	float alpha = original.a;

	if (CA > 0.0) {
		vec2 rgMag = GetRGMag(CA);
		color = SampleWithChromaticAberration(coord, centerCoord, rgMag.x, rgMag.y);
	}

	if (VIG > 0.0) {
		ApplyVignette(coord, centerCoord, color, VIG);
	}

	if (GRAIN_A > 0.0 && GRAIN_S > 0.0) {
		uint grainSeed = uint(frame);
		ApplyFilmGrain(ivec2(coord), color, GRAIN_S, GRAIN_A, grainSeed);
	}

	return vec4(color, alpha);

}

