// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- RAW ver.
  https://github.com/BrutPitt/glslSmartDeNoise/blob/master/license.txt

*/


//!PARAM RAD
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 3.0
1.0

//!PARAM K
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 24.0
4.0

//!PARAM THR
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 2.0
0.1


//!HOOK MAIN
//!BIND HOOKED
//!DESC [denoise_gaussian_RT]
//!WHEN RAD K * THR *

const float INV_SQRT_OF_2PI = 0.39894228040143267793994605993439;  // 1.0/SQRT_OF_2PI
const float INV_PI          = 0.31830988618379067153776752674503;

vec4 hook()
{

	float sigma = RAD;
	float kSigma = K;
	float threshold = THR;

	float radius = round(kSigma * sigma);
	float radQ = radius * radius;

	float invSigmaQx2 = 0.5 / (sigma * sigma);
	float invSigmaQx2PI = INV_PI * invSigmaQx2;

	float invThresholdSqx2 = 0.5 / (threshold * threshold);
	float invThresholdSqrt2PI = INV_SQRT_OF_2PI / threshold;

	vec4 centrPx = HOOKED_texOff(vec2(0.0));

	float zBuff = 0.0;
	vec3 aBuff = vec3(0.0);

	vec2 d;
	for (d.x = -radius; d.x <= radius; d.x += 1.0) {
		float pt = sqrt(radQ - (d.x * d.x));
		for (d.y = -pt; d.y <= pt; d.y += 1.0) {
			float blurFactor = exp((-dot(d, d)) * invSigmaQx2) * invSigmaQx2PI;

			vec4 walkPx = HOOKED_texOff(d);

			vec4 dC = walkPx - centrPx;
			float deltaFactor = exp(-dot(dC.xyz, dC.xyz) * invThresholdSqx2) * invThresholdSqrt2PI * blurFactor;

			zBuff += deltaFactor;
			aBuff += deltaFactor * walkPx.rgb;
		}
	}
	return vec4(aBuff / zBuff, centrPx.a);

}

