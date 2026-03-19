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
//!DESC [AMD_FSR1_RCAS_luma_RT] (SDK v2.0.0)
//!WHEN SHARP 4.0 <

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
	FSR_FLOAT b = FSR_FLOAT(HOOKED_texOff(vec2( 0.0, -1.0)).x);
	FSR_FLOAT d = FSR_FLOAT(HOOKED_texOff(vec2(-1.0,  0.0)).x);
	FSR_FLOAT e = FSR_FLOAT(HOOKED_tex(HOOKED_pos).x);
	FSR_FLOAT f = FSR_FLOAT(HOOKED_texOff(vec2( 1.0,  0.0)).x);
	FSR_FLOAT h = FSR_FLOAT(HOOKED_texOff(vec2( 0.0,  1.0)).x);

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

