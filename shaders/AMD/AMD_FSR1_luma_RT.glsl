// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- RAW ver.
  https://github.com/GPUOpen-LibrariesAndSDKs/FidelityFX-SDK/blob/v2.1.0/Kits/FidelityFX/upscalers/fsr3/include/gpu/fsr1/ffx_fsr1.h

*/


//!PARAM SHARP
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 4.0
0.2

//!PARAM NDS
//!TYPE DEFINE
//!MINIMUM 0
//!MAXIMUM 1
1


//!HOOK LUMA
//!BIND HOOKED
//!SAVE EASUTEX
//!DESC [AMD_FSR1_luma_RT] (SDK v1.1.4) - EASU (Edge-Adaptive Spatial Upsampling)
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w HOOKED.w 1.0 * > OUTPUT.h HOOKED.h 1.0 * > *

#define FP16   1

#if FP16
	#ifdef GL_ES
		precision mediump float;
	#else
		precision highp float;
	#endif
	#define FSR_FLOAT float
	#define FSR_FLOAT2 vec2
	#define FSR_FLOAT3 vec3
	#define FSR_FLOAT4 vec4
#else
	precision highp float;
	#define FSR_FLOAT float
	#define FSR_FLOAT2 vec2
	#define FSR_FLOAT3 vec3
	#define FSR_FLOAT4 vec4
#endif

FSR_FLOAT APrxLoRcpF1(FSR_FLOAT a) { return FSR_FLOAT(1.0) / max(a, FSR_FLOAT(1.0e-5)); }
FSR_FLOAT APrxLoRsqF1(FSR_FLOAT a) { return inversesqrt(max(a, FSR_FLOAT(1.0e-5))); }
FSR_FLOAT AMin3F1(FSR_FLOAT x, FSR_FLOAT y, FSR_FLOAT z) { return min(x, min(y, z)); }
FSR_FLOAT AMax3F1(FSR_FLOAT x, FSR_FLOAT y, FSR_FLOAT z) { return max(x, max(y, z)); }

void FsrEasuTapF(
	inout FSR_FLOAT aC,    // Accumulated color, with negative lobe.
	inout FSR_FLOAT aW,    // Accumulated weight.
	FSR_FLOAT2 off,        // Pixel offset from resolve position to tap.
	FSR_FLOAT2 dir,        // Gradient direction.
	FSR_FLOAT2 len,        // Length.
	FSR_FLOAT lob,         // Negative lobe strength.
	FSR_FLOAT clp,         // Clipping point.
	FSR_FLOAT c)           // Tap luma.
{
	FSR_FLOAT2 v;
	v.x = (off.x * dir.x) + (off.y * dir.y);
	v.y = (off.x * (-dir.y)) + (off.y * dir.x);
	v *= len;
	FSR_FLOAT d2 = v.x * v.x + v.y * v.y;
	d2 = min(d2, clp);

	//  (25/16 * (2/5 * x^2 - 1)^2 - (25/16 - 1)) * (1/4 * x^2 - 1)^2
	//  |_______________________________________|   |_______________|
	//                   base                             window
	FSR_FLOAT wB = FSR_FLOAT(2.0 / 5.0) * d2 - FSR_FLOAT(1.0);
	FSR_FLOAT wA = lob * d2 - FSR_FLOAT(1.0);
	wB *= wB;
	wA *= wA;
	wB = FSR_FLOAT(25.0 / 16.0) * wB - FSR_FLOAT((25.0 / 16.0) - 1.0);
	FSR_FLOAT w = wB * wA;

	aC += c * w;
	aW += w;
}

void FsrEasuSetF(
	inout FSR_FLOAT2 dir,
	inout FSR_FLOAT len,
	FSR_FLOAT2 pp,
	bool biS, bool biT, bool biU, bool biV,
	FSR_FLOAT lA, FSR_FLOAT lB, FSR_FLOAT lC, FSR_FLOAT lD, FSR_FLOAT lE)
{
	//  s t
	//  u v
	FSR_FLOAT w = FSR_FLOAT(0.0);
	if (biS) w = (FSR_FLOAT(1.0) - pp.x) * (FSR_FLOAT(1.0) - pp.y);
	if (biT) w = pp.x * (FSR_FLOAT(1.0) - pp.y);
	if (biU) w = (FSR_FLOAT(1.0) - pp.x) * pp.y;
	if (biV) w = pp.x * pp.y;

	//    a
	//  b c d
	//    e
	FSR_FLOAT dc = lD - lC;
	FSR_FLOAT cb = lC - lB;
	FSR_FLOAT lenX = max(abs(dc), abs(cb));
	lenX = APrxLoRcpF1(lenX);
	FSR_FLOAT dirX = lD - lB;
	dir.x += dirX * w;
	lenX = clamp(abs(dirX) * lenX, FSR_FLOAT(0.0), FSR_FLOAT(1.0));
	lenX *= lenX;
	len += lenX * w;

	FSR_FLOAT ec = lE - lC;
	FSR_FLOAT ca = lC - lA;
	FSR_FLOAT lenY = max(abs(ec), abs(ca));
	lenY = APrxLoRcpF1(lenY);
	FSR_FLOAT dirY = lE - lA;
	dir.y += dirY * w;
	lenY = clamp(abs(dirY) * lenY, FSR_FLOAT(0.0), FSR_FLOAT(1.0));
	lenY *= lenY;
	len += lenY * w;
}

vec4 hook() {

	FSR_FLOAT2 pp = HOOKED_pos * HOOKED_size - FSR_FLOAT2(0.5);
	FSR_FLOAT2 fp = floor(pp);
	pp -= fp;

	// 12-tap kernel.
	//    b c
	//  e f g h
	//  i j k l
	//    n o

#if (defined(HOOKED_gather) && (__VERSION__ >= 400 || (GL_ES && __VERSION__ >= 310)))
	// Use textureGather for OpenGL 4.0+ / ES 3.1+
	FSR_FLOAT4 bczz = HOOKED_gather(vec2((fp + vec2(1.0, -1.0)) * HOOKED_pt), 0);
	FSR_FLOAT4 ijfe = HOOKED_gather(vec2((fp + vec2(0.0, 1.0)) * HOOKED_pt), 0);
	FSR_FLOAT4 klhg = HOOKED_gather(vec2((fp + vec2(2.0, 1.0)) * HOOKED_pt), 0);
	FSR_FLOAT4 zzon = HOOKED_gather(vec2((fp + vec2(1.0, 3.0)) * HOOKED_pt), 0);

	FSR_FLOAT bL = bczz.x;
	FSR_FLOAT cL = bczz.y;
	FSR_FLOAT iL = ijfe.x;
	FSR_FLOAT jL = ijfe.y;
	FSR_FLOAT fL = ijfe.z;
	FSR_FLOAT eL = ijfe.w;
	FSR_FLOAT kL = klhg.x;
	FSR_FLOAT lL = klhg.y;
	FSR_FLOAT hL = klhg.z;
	FSR_FLOAT gL = klhg.w;
	FSR_FLOAT oL = zzon.z;
	FSR_FLOAT nL = zzon.w;
#else
	// Fallback for pre-OpenGL 4.0 compatibility
	FSR_FLOAT bL = FSR_FLOAT(HOOKED_tex(vec2((fp + vec2(0.5, -0.5)) * HOOKED_pt)).x);
	FSR_FLOAT cL = FSR_FLOAT(HOOKED_tex(vec2((fp + vec2(1.5, -0.5)) * HOOKED_pt)).x);

	FSR_FLOAT eL = FSR_FLOAT(HOOKED_tex(vec2((fp + vec2(-0.5, 0.5)) * HOOKED_pt)).x);
	FSR_FLOAT fL = FSR_FLOAT(HOOKED_tex(vec2((fp + vec2( 0.5, 0.5)) * HOOKED_pt)).x);
	FSR_FLOAT gL = FSR_FLOAT(HOOKED_tex(vec2((fp + vec2( 1.5, 0.5)) * HOOKED_pt)).x);
	FSR_FLOAT hL = FSR_FLOAT(HOOKED_tex(vec2((fp + vec2( 2.5, 0.5)) * HOOKED_pt)).x);

	FSR_FLOAT iL = FSR_FLOAT(HOOKED_tex(vec2((fp + vec2(-0.5, 1.5)) * HOOKED_pt)).x);
	FSR_FLOAT jL = FSR_FLOAT(HOOKED_tex(vec2((fp + vec2( 0.5, 1.5)) * HOOKED_pt)).x);
	FSR_FLOAT kL = FSR_FLOAT(HOOKED_tex(vec2((fp + vec2( 1.5, 1.5)) * HOOKED_pt)).x);
	FSR_FLOAT lL = FSR_FLOAT(HOOKED_tex(vec2((fp + vec2( 2.5, 1.5)) * HOOKED_pt)).x);

	FSR_FLOAT nL = FSR_FLOAT(HOOKED_tex(vec2((fp + vec2(0.5, 2.5)) * HOOKED_pt)).x);
	FSR_FLOAT oL = FSR_FLOAT(HOOKED_tex(vec2((fp + vec2(1.5, 2.5)) * HOOKED_pt)).x);
#endif

	FSR_FLOAT2 dir = FSR_FLOAT2(0.0);
	FSR_FLOAT len = FSR_FLOAT(0.0);

	const bool deea = (target_size.x * target_size.y > HOOKED_size.x * HOOKED_size.y * 6.25);
	if (!deea) {
		FsrEasuSetF(dir, len, pp, true, false, false, false, bL, eL, fL, gL, jL);
		FsrEasuSetF(dir, len, pp, false, true, false, false, cL, fL, gL, hL, kL);
		FsrEasuSetF(dir, len, pp, false, false, true, false, fL, iL, jL, kL, nL);
		FsrEasuSetF(dir, len, pp, false, false, false, true, gL, jL, kL, lL, oL);
	}

	FSR_FLOAT2 dir2 = dir * dir;
	FSR_FLOAT dirR = dir2.x + dir2.y;
	bool zro = dirR < FSR_FLOAT(1.0 / 32768.0);
	dirR = APrxLoRsqF1(dirR);
	dirR = zro ? FSR_FLOAT(1.0) : dirR;
	dir.x = zro ? FSR_FLOAT(1.0) : dir.x;
	dir *= FSR_FLOAT2(dirR);

	len = len * FSR_FLOAT(0.5);
	len *= len;
	FSR_FLOAT stretch = (dir.x * dir.x + dir.y * dir.y) * APrxLoRcpF1(max(abs(dir.x), abs(dir.y)));
	FSR_FLOAT2 len2 = FSR_FLOAT2(FSR_FLOAT(1.0) + (stretch - FSR_FLOAT(1.0)) * len, FSR_FLOAT(1.0) + FSR_FLOAT(-0.5) * len);
	FSR_FLOAT lob = FSR_FLOAT(0.5) + FSR_FLOAT((1.0 / 4.0 - 0.04) - 0.5) * len;
	FSR_FLOAT clp = APrxLoRcpF1(lob);

	//    b c
	//  e f g h
	//  i j k l
	//    n o
	FSR_FLOAT min4 = min(AMin3F1(fL, gL, jL), kL);
	FSR_FLOAT max4 = max(AMax3F1(fL, gL, jL), kL);

	FSR_FLOAT aC = FSR_FLOAT(0.0);
	FSR_FLOAT aW = FSR_FLOAT(0.0);
	FsrEasuTapF(aC, aW, FSR_FLOAT2( 0.0,-1.0) - pp, dir, len2, lob, clp, bL); // b
	FsrEasuTapF(aC, aW, FSR_FLOAT2( 1.0,-1.0) - pp, dir, len2, lob, clp, cL); // c
	FsrEasuTapF(aC, aW, FSR_FLOAT2(-1.0, 1.0) - pp, dir, len2, lob, clp, iL); // i
	FsrEasuTapF(aC, aW, FSR_FLOAT2( 0.0, 1.0) - pp, dir, len2, lob, clp, jL); // j
	FsrEasuTapF(aC, aW, FSR_FLOAT2( 0.0, 0.0) - pp, dir, len2, lob, clp, fL); // f
	FsrEasuTapF(aC, aW, FSR_FLOAT2(-1.0, 0.0) - pp, dir, len2, lob, clp, eL); // e
	FsrEasuTapF(aC, aW, FSR_FLOAT2( 1.0, 1.0) - pp, dir, len2, lob, clp, kL); // k
	FsrEasuTapF(aC, aW, FSR_FLOAT2( 2.0, 1.0) - pp, dir, len2, lob, clp, lL); // l
	FsrEasuTapF(aC, aW, FSR_FLOAT2( 2.0, 0.0) - pp, dir, len2, lob, clp, hL); // h
	FsrEasuTapF(aC, aW, FSR_FLOAT2( 1.0, 0.0) - pp, dir, len2, lob, clp, gL); // g
	FsrEasuTapF(aC, aW, FSR_FLOAT2( 1.0, 2.0) - pp, dir, len2, lob, clp, oL); // o
	FsrEasuTapF(aC, aW, FSR_FLOAT2( 0.0, 2.0) - pp, dir, len2, lob, clp, nL); // n

	FSR_FLOAT pix = min(max4, max(min4, aC / aW));
	return vec4(pix, 0.0, 0.0, 1.0);

}

//!HOOK LUMA
//!BIND EASUTEX
//!DESC [AMD_FSR1_luma_RT] (SDK v2.0.0) - RCAS (Robust Contrast-Adaptive Sharpening)
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w HOOKED.w 1.0 * > OUTPUT.h HOOKED.h 1.0 * > *

#define FP16             1
#define FSR_RCAS_LIMIT   (0.25 - (1.0 / 16.0))

#if FP16
	#ifdef GL_ES
		precision mediump float;
	#else
		precision highp float;
	#endif
	#define FSR_FLOAT float
	#define FSR_FLOAT2 vec2
	#define FSR_FLOAT3 vec3
	#define FSR_FLOAT4 vec4
#else
	precision highp float;
	#define FSR_FLOAT float
	#define FSR_FLOAT2 vec2
	#define FSR_FLOAT3 vec3
	#define FSR_FLOAT4 vec4
#endif

FSR_FLOAT APrxMedRcpF1_RCAS(FSR_FLOAT a) { return FSR_FLOAT(1.0) / a; }
FSR_FLOAT AMin3F1_RCAS(FSR_FLOAT x, FSR_FLOAT y, FSR_FLOAT z) { return min(x, min(y, z)); }
FSR_FLOAT AMax3F1_RCAS(FSR_FLOAT x, FSR_FLOAT y, FSR_FLOAT z) { return max(x, max(y, z)); }

vec4 hook() {

	//    b
	//  d e f
	//    h
	FSR_FLOAT b = FSR_FLOAT(EASUTEX_texOff(vec2( 0.0, -1.0)).x);
	FSR_FLOAT d = FSR_FLOAT(EASUTEX_texOff(vec2(-1.0,  0.0)).x);
	FSR_FLOAT e = FSR_FLOAT(EASUTEX_tex(EASUTEX_pos).x);
	FSR_FLOAT f = FSR_FLOAT(EASUTEX_texOff(vec2( 1.0,  0.0)).x);
	FSR_FLOAT h = FSR_FLOAT(EASUTEX_texOff(vec2( 0.0,  1.0)).x);

	// Noise detection
	FSR_FLOAT nz = FSR_FLOAT(0.25) * b + FSR_FLOAT(0.25) * d + FSR_FLOAT(0.25) * f + FSR_FLOAT(0.25) * h - e;
	FSR_FLOAT range = AMax3F1_RCAS(AMax3F1_RCAS(b, d, e), f, h) - AMin3F1_RCAS(AMin3F1_RCAS(b, d, e), f, h);
	nz = clamp(abs(nz) * APrxMedRcpF1_RCAS(range), FSR_FLOAT(0.0), FSR_FLOAT(1.0));
	nz = FSR_FLOAT(-0.5) * nz + FSR_FLOAT(1.0);

	// Min and max of ring
	FSR_FLOAT mn4 = min(AMin3F1_RCAS(b, d, f), h);
	FSR_FLOAT mx4 = max(AMax3F1_RCAS(b, d, f), h);

	FSR_FLOAT2 peakC = FSR_FLOAT2(1.0, -4.0);

	// Limiters
	FSR_FLOAT minL = min(AMin3F1_RCAS(b, d, f), h);
	FSR_FLOAT lowerLimiterMultiplier = clamp(e / minL, FSR_FLOAT(0.0), FSR_FLOAT(1.0));

	FSR_FLOAT hitMin = mn4 / (FSR_FLOAT(4.0) * mx4) * lowerLimiterMultiplier;
	FSR_FLOAT hitMax = (peakC.x - mx4) / (FSR_FLOAT(4.0) * mn4 + peakC.y);

	FSR_FLOAT lobeVal = max(-hitMin, hitMax);

	// Apply sharpness
	FSR_FLOAT sharp = exp2(-SHARP);
	FSR_FLOAT lobe = max(FSR_FLOAT(-FSR_RCAS_LIMIT), min(lobeVal, FSR_FLOAT(0.0))) * sharp;

#if NDS
	lobe *= nz;
#endif

	FSR_FLOAT rcpL = APrxMedRcpF1_RCAS(FSR_FLOAT(4.0) * lobe + FSR_FLOAT(1.0));
	FSR_FLOAT pix = (lobe * b + lobe * d + lobe * h + lobe * f + e) * rcpL;
	return vec4(pix, 0.0, 0.0, 1.0);

}

