// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- FXAA ver.
  https://developer.download.nvidia.com/assets/gamedev/files/sdk/11/FXAA_WhitePaper.pdf
  --- grebord ver.
  https://github.com/grebord/Fast-Adaptive-AA/blob/main/FAAA.fx

*/


//!PARAM ET
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 10.0
8.0

//!PARAM DEBUG
//!TYPE DEFINE
//!MINIMUM 0
//!MAXIMUM 1
0


//!HOOK MAIN
//!BIND HOOKED
//!DESC [FAAA_RT]

#define QC 9   // <1-9>

#define GetLuma(c)       dot(c.rgb, vec3(0.299, 0.587, 0.114))
#define SampleLumaOff(o) GetLuma(HOOKED_texOff(o))
#define SampleColor(p)   texture(HOOKED_raw, p)

const ivec2 OffS  = ivec2( 0, 1);
const ivec2 OffE  = ivec2( 1, 0);
const ivec2 OffN  = ivec2( 0,-1);
const ivec2 OffW  = ivec2(-1, 0);
const ivec2 OffSW = ivec2(-1, 1);
const ivec2 OffSE = ivec2( 1, 1);
const ivec2 OffNE = ivec2( 1,-1);
const ivec2 OffNW = ivec2(-1,-1);

#define FXAA_QUALITY_PI  (QC+3)
#define FXAA_QUALITY_P0  1.0
#define FXAA_QUALITY_P1  1.5
#define FXAA_QUALITY_P2  2.0
#define FXAA_QUALITY_P3  2.0
#define FXAA_QUALITY_P4  2.0
#define FXAA_QUALITY_P5  2.0
#define FXAA_QUALITY_P6  2.0
#define FXAA_QUALITY_P7  2.0
#define FXAA_QUALITY_P8  2.0
#define FXAA_QUALITY_P9  2.0
#define FXAA_QUALITY_P10 4.0
#define FXAA_QUALITY_P11 8.0
#if (QC == 1)
	#undef  FXAA_QUALITY_P3
	#define FXAA_QUALITY_P3 8.0
#elif (QC == 2)
	#undef  FXAA_QUALITY_P4
	#define FXAA_QUALITY_P4 8.0
#elif (QC == 3)
	#undef  FXAA_QUALITY_P5
	#define FXAA_QUALITY_P5 8.0
#elif (QC == 4)
	#undef  FXAA_QUALITY_P5
	#define FXAA_QUALITY_P5 3.0
	#undef  FXAA_QUALITY_P6
	#define FXAA_QUALITY_P6 8.0
#elif (QC == 5)
	#undef  FXAA_QUALITY_P6
	#define FXAA_QUALITY_P6 4.0
	#undef  FXAA_QUALITY_P7
	#define FXAA_QUALITY_P7 8.0
#elif (QC == 6)
	#undef  FXAA_QUALITY_P7
	#define FXAA_QUALITY_P7 4.0
	#undef  FXAA_QUALITY_P8
	#define FXAA_QUALITY_P8 8.0
#elif (QC == 7)
	#undef  FXAA_QUALITY_P8
	#define FXAA_QUALITY_P8 4.0
	#undef  FXAA_QUALITY_P9
	#define FXAA_QUALITY_P9 8.0
#elif (QC == 8)
	#undef  FXAA_QUALITY_P9
	#define FXAA_QUALITY_P9 4.0
	#undef  FXAA_QUALITY_P10
	#define FXAA_QUALITY_P10 8.0
#elif (QC == 9)
	#undef  FXAA_QUALITY_P1
	#define FXAA_QUALITY_P1 1.0
	#undef  FXAA_QUALITY_P2
	#define FXAA_QUALITY_P2 1.0
	#undef  FXAA_QUALITY_P3
	#define FXAA_QUALITY_P3 1.0
	#undef  FXAA_QUALITY_P4
	#define FXAA_QUALITY_P4 1.0
	#undef  FXAA_QUALITY_P5
	#define FXAA_QUALITY_P5 1.5
#endif

vec4 hook() {

	const vec2 txc = HOOKED_pos;
	const vec2 PixelSize = HOOKED_pt;

	float lumaSE = SampleLumaOff(OffSE);
	float lumaNW = SampleLumaOff(OffNW);
	float lumaSW = SampleLumaOff(OffSW);
	float lumaNE = SampleLumaOff(OffNE);

	float gradientSWNE = lumaSW - lumaNE;
	float gradientSENW = lumaSE - lumaNW;
	vec2 dirM;
	dirM.x = abs(gradientSWNE + gradientSENW);
	dirM.y = abs(gradientSWNE - gradientSENW);

	float lumaMax = max(max(lumaSW, lumaSE), max(lumaNE, lumaNW));
	const float EdgeThreshold = (10.0 - ET) * 0.0625;
	float localLumaFactor = lumaMax * 0.5 + 0.5;
	float localThres = EdgeThreshold * localLumaFactor;
	bool lowDelta = abs(dirM.x - dirM.y) < localThres;

#if (DEBUG == 1)
	if(lowDelta) {
		return vec4(vec3(GetLuma(HOOKED_texOff(ivec2(0)))) * 0.9, 1.0);
	} else {
		return vec4(0.0, 1.0, 0.0, 1.0);
	}
#endif

	if(lowDelta) {
		return HOOKED_texOff(ivec2(0));
	}

	else {
		const float OffMult[12] = { 
			FXAA_QUALITY_P0, FXAA_QUALITY_P1, FXAA_QUALITY_P2,  FXAA_QUALITY_P3,
			FXAA_QUALITY_P4, FXAA_QUALITY_P5, FXAA_QUALITY_P6,  FXAA_QUALITY_P7,
			FXAA_QUALITY_P8, FXAA_QUALITY_P9, FXAA_QUALITY_P10, FXAA_QUALITY_P11
		};

		bool horzSpan = dirM.x > dirM.y;

		float lumaM = GetLuma(HOOKED_texOff(ivec2(0)));
		float lumaN, lumaS;
		if( horzSpan) {
			lumaN = SampleLumaOff(OffN);
			lumaS = SampleLumaOff(OffS);
		} else {
			lumaN = SampleLumaOff(OffW);
			lumaS = SampleLumaOff(OffE);
		}

		float gradientN = lumaN - lumaM;
		float gradientS = lumaS - lumaM;

		bool pairN = abs(gradientN) > abs(gradientS);

		float gradient = max(abs(gradientN), abs(gradientS));
		float gradientScaled = gradient * 0.25;

		float lumaNN = lumaN + lumaM;
		if(!pairN) lumaNN = lumaS + lumaM;
		float lumaMN = lumaNN * 0.5;

		float lengthSign = horzSpan ? PixelSize.y : PixelSize.x;
		if( pairN) lengthSign = -lengthSign;

		vec2 posN = txc;
		if(!horzSpan) posN.x += lengthSign * 0.5;
		else          posN.y += lengthSign * 0.5;

		vec2 posP = posN;
		vec2 offNP = horzSpan ? vec2(PixelSize.x, 0.0) : vec2(0.0, PixelSize.y);

		posP += offNP * OffMult[0];
		posN -= offNP * OffMult[0];
		float lumaEndP = GetLuma(SampleColor(posP));
		float lumaEndN = GetLuma(SampleColor(posN));
		lumaEndP -= lumaMN;
		lumaEndN -= lumaMN;
		bool doneP = abs(lumaEndP) > gradientScaled;
		bool doneN = abs(lumaEndN) > gradientScaled;

		for (int i = 1; i < FXAA_QUALITY_PI; i++) {
			if(!doneP) {
				posP += offNP * OffMult[i];
				lumaEndP  = GetLuma(SampleColor(posP));
				lumaEndP -= lumaMN;
				doneP = abs(lumaEndP) > gradientScaled;
			}
			if(!doneN) {
				posN -= offNP * OffMult[i];
				lumaEndN  = GetLuma(SampleColor(posN));
				lumaEndN -= lumaMN;
				doneN = abs(lumaEndN) > gradientScaled;
			}
		}

		vec2 posM = txc;
		float dstN = horzSpan ? (posM.x - posN.x) : (posM.y - posN.y);
		float dstP = horzSpan ? (posP.x - posM.x) : (posP.y - posM.y);

		bool dstNLTdstP = dstN < dstP;
		float dst = dstNLTdstP ? dstN : dstP;

		bool lumaMLTZero = lumaM < lumaMN;
		bool mSpanLTZero = dstNLTdstP ? (lumaEndN < 0.0) : (lumaEndP < 0.0);
		bool goodSpan = (mSpanLTZero != lumaMLTZero);
		if (!goodSpan) return HOOKED_texOff(ivec2(0));

		float spanLength = dstP + dstN;
		float pixelOffset = (dst / -spanLength) + 0.5;
		if (pixelOffset < 0.0) return HOOKED_texOff(ivec2(0));

		if(!horzSpan) posM.x += pixelOffset * lengthSign;
		else          posM.y += pixelOffset * lengthSign;

		return SampleColor(posM);
	}

}

