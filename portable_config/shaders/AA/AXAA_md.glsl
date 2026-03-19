// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- FXAA ver.
  https://developer.download.nvidia.com/assets/gamedev/files/sdk/11/FXAA_WhitePaper.pdf
  --- BlueSkyDefender ver.
  https://github.com/BlueSkyDefender/Depth3D/blob/master/Shaders/AXAA.fxh

*/


//!HOOK POSTKERNEL
//!BIND HOOKED
//!DESC [AXAA_md]
//!WHEN PREKERNEL.w POSTKERNEL.w > PREKERNEL.h POSTKERNEL.h > *

#define HDR 1

// -- FXAA/AXAA Defines --
#define FXAA_SEARCH_STEPS        32
#define FXAA_SEARCH_ACCELERATION 1
#define FXAA_SEARCH_THRESHOLD    (1.0/4.0)
#define FXAA_SUBPIX              1
#define FXAA_SUBPIX_FASTER       0
#define FXAA_SUBPIX_CAP          (3.0/4.0)
#define FXAA_SUBPIX_TRIM         (1.0/4.0)
#define FXAA_SUBPIX_TRIM_SCALE   (1.0/(1.0 - FXAA_SUBPIX_TRIM))

float Max3_AXAA(vec3 RGB) {
	return max(RGB.r, max(RGB.g, RGB.b));
}

vec3 LerpR(vec3 a, vec3 b, float t) {
	return vec3(mix(b.r, a.r, t), b.g, b.b);
}

vec4 hook() {

	vec2 texcoord = HOOKED_pos;
	vec2 Pix = HOOKED_pt;

	vec4 colorM = HOOKED_texOff(vec2(0.0, 0.0));
	vec3 rgbM = colorM.rgb;

	vec3 rgbN = HOOKED_texOff(vec2( 0,-1)).rgb;
	vec3 rgbW = HOOKED_texOff(vec2(-1, 0)).rgb;
	vec3 rgbE = HOOKED_texOff(vec2( 1, 0)).rgb;
	vec3 rgbS = HOOKED_texOff(vec2( 0, 1)).rgb;

	float lumaN = Max3_AXAA(rgbN);
	float lumaW = Max3_AXAA(rgbW);
	float lumaM = Max3_AXAA(rgbM);
	float lumaE = Max3_AXAA(rgbE);
	float lumaS = Max3_AXAA(rgbS);

	float rangeMin = min(lumaM, min(min(lumaN, lumaW), min(lumaS, lumaE)));
	float rangeMax = max(lumaM, max(max(lumaN, lumaW), max(lumaS, lumaE)));
	float range = rangeMax - rangeMin;

	float rangeMid = 0.5 * (rangeMin + rangeMax);
	float alpha = 0.1 * range;

	if (abs(lumaM - rangeMid) <= alpha) {
		return colorM;
	}

#if (FXAA_SUBPIX != 0)
	float lumaL = (lumaN + lumaW + lumaE + lumaS) * 0.25;
	float rangeL = abs(lumaL - lumaM);
#endif

	float SafeRange = max(range, 0.001);
	float Ratio = rangeL / SafeRange;

#if (HDR == 1)
	Ratio = clamp(Ratio, 0.0, 1.0);
#endif

#if (FXAA_SUBPIX == 1)
	float blendL = max(0.0, (Ratio / range) - FXAA_SUBPIX_TRIM) * FXAA_SUBPIX_TRIM_SCALE;
	blendL = min(FXAA_SUBPIX_CAP, blendL);
#endif

	vec3 rgbNW = HOOKED_texOff(vec2(-1,-1)).rgb;
	vec3 rgbNE = HOOKED_texOff(vec2( 1,-1)).rgb;
	vec3 rgbSW = HOOKED_texOff(vec2(-1, 1)).rgb;
	vec3 rgbSE = HOOKED_texOff(vec2( 1, 1)).rgb;

	vec3 rgbL = rgbN + rgbW + rgbM + rgbE + rgbS;
#if (FXAA_SUBPIX_FASTER == 0) && (FXAA_SUBPIX > 0)
	rgbL += (rgbNW + rgbNE + rgbSW + rgbSE);
	rgbL *= 1.0 / 9.0;
#endif

	float lumaNW = Max3_AXAA(rgbNW);
	float lumaNE = Max3_AXAA(rgbNE);
	float lumaSW = Max3_AXAA(rgbSW);
	float lumaSE = Max3_AXAA(rgbSE);

	float edgeVert =
		abs((0.25 * lumaNW) + (-0.5 * lumaN) + (0.25 * lumaNE)) +
		abs((0.50 * lumaW) + (-1.0 * lumaM) + (0.50 * lumaE)) +
		abs((0.25 * lumaSW) + (-0.5 * lumaS) + (0.25 * lumaSE));
	float edgeHorz =
		abs((0.25 * lumaNW) + (-0.5 * lumaW) + (0.25 * lumaSW)) +
		abs((0.50 * lumaN) + (-1.0 * lumaM) + (0.50 * lumaS)) +
		abs((0.25 * lumaNE) + (-0.5 * lumaE) + (0.25 * lumaSE));

	bool horzSpan = edgeHorz >= edgeVert;
	float lengthSign = horzSpan ? -Pix.y : -Pix.x;

	if (!horzSpan) {
		lumaN = lumaW;
		lumaS = lumaE;
	}

	float gradientN = abs(lumaN - lumaM);
	float gradientS = abs(lumaS - lumaM);
	float lumaN_avg = (lumaN + lumaM) * 0.5;
	float lumaS_avg = (lumaS + lumaM) * 0.5;

	float minLuma_orig = min(lumaM, min(min(Max3_AXAA(rgbN), Max3_AXAA(rgbW)), min(Max3_AXAA(rgbS), Max3_AXAA(rgbE))));
	float maxLuma_orig = max(lumaM, max(max(Max3_AXAA(rgbN), Max3_AXAA(rgbW)), max(Max3_AXAA(rgbS), Max3_AXAA(rgbE))));
	float dmin = abs(lumaM - minLuma_orig);
	float dmax = abs(lumaM - maxLuma_orig);

	int searchIterations = FXAA_SEARCH_STEPS;
	if (max(dmin, dmax) <= 0.1) searchIterations = 1;
	if (min(dmin, dmax) > 0.1)  searchIterations = 2;
	if (min(dmin, dmax) > 0.3)  searchIterations = 3;

	if ((gradientN > 0.3) && (gradientS > 0.3)) {
		lengthSign = 0.0;
	}

	bool pairN = gradientN >= gradientS;
	if (!pairN) {
		lumaN_avg = lumaS_avg;
		gradientN = gradientS;
		lengthSign *= -1.0;
	}

	vec2 posN;
	posN.x = texcoord.x + (horzSpan ? 0.0 : lengthSign * 0.5);
	posN.y = texcoord.y + (horzSpan ? lengthSign * 0.5 : 0.0);

	gradientN *= FXAA_SEARCH_THRESHOLD;

	vec2 posP = posN;
	vec2 offNP = horzSpan ? vec2(Pix.x, 0.0) : vec2(0.0, Pix.y);
	float lumaEndN = lumaN_avg;
	float lumaEndP = lumaN_avg;
	bool doneN = false;
	bool doneP = false;

#if (FXAA_SEARCH_ACCELERATION == 1)
	posN -= offNP;
	posP += offNP;
#endif

	for (int i = 0; i < searchIterations; i++) {
		if (!doneN) lumaEndN = Max3_AXAA(HOOKED_tex(posN).rgb);
		if (!doneP) lumaEndP = Max3_AXAA(HOOKED_tex(posP).rgb);
		doneN = doneN || (abs(lumaEndN - lumaN_avg) >= gradientN);
		doneP = doneP || (abs(lumaEndP - lumaN_avg) >= gradientN);
		if (doneN && doneP) break;
		if (!doneN) posN -= offNP;
		if (!doneP) posP += offNP;
	}

	float dstN = horzSpan ? texcoord.x - posN.x : texcoord.y - posN.y;
	float dstP = horzSpan ? posP.x - texcoord.x : posP.y - texcoord.y;

	bool directionN = dstN < dstP;
	lumaEndN = directionN ? lumaEndN : lumaEndP;

	if (((lumaM - lumaN_avg) < 0.0) == ((lumaEndN - lumaN_avg) < 0.0)) {
		lengthSign = 0.0;
	}

	float spanLength = (dstP + dstN);
	dstN = directionN ? dstN : dstP;
	float subPixelOffset = (0.5 + (dstN * (-1.0 / spanLength))) * lengthSign;

	vec3 rgbF = HOOKED_tex(vec2(
		texcoord.x + (horzSpan ? 0.0 : subPixelOffset),
		texcoord.y + (horzSpan ? subPixelOffset : 0.0)
	)).rgb;

	vec3 finalRgb;

#if (HDR == 1)
	finalRgb = mix(rgbL, rgbF, blendL);
#elif (HDR == 0)
	finalRgb = LerpR(rgbL, rgbF, blendL);
#endif

	return vec4(finalRgb, colorM.a);

}

