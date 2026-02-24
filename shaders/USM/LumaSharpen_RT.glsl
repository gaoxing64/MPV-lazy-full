// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- RAW ver.
  https://github.com/CeeJayDK/SweetFX/blob/master/LICENSE
  --- voltmtr ver.
  https://gist.github.com/voltmtr/8b4404b4e23129b226b9e64863d3e28b

*/


//!PARAM SHARP
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 3.0
0.65

//!PARAM SC
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.035

//!PARAM CM
//!TYPE DEFINE
//!MINIMUM 1
//!MAXIMUM 2
2

//!PARAM PTN
//!TYPE DEFINE
//!MINIMUM 1
//!MAXIMUM 6
4

//!PARAM SHIFT
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 6.0
1.0

//!PARAM DEBUG
//!TYPE DEFINE
//!MINIMUM 0
//!MAXIMUM 1
0


//!HOOK LUMA
//!BIND HOOKED
//!DESC [LumaSharpen_RT]
//!WHEN SHARP
//!COMPONENTS 1

vec4 hook() {

	float strength = SHARP;
	float ori_luma = HOOKED_texOff(vec2(0.0)).x;
	float blur_luma = 0.0;

#if (PTN == 1) // Fast
	blur_luma += HOOKED_texOff( (vec2(1.0, 1.0) / 3.0) * SHIFT ).x;
	blur_luma += HOOKED_texOff( (vec2(-1.0, -1.0) / 3.0) * SHIFT ).x;
	blur_luma /= 2.0;
	strength *= 1.5;
#elif (PTN == 2) // Normal
	blur_luma += HOOKED_texOff(vec2(0.5, -0.5) * SHIFT).x;
	blur_luma += HOOKED_texOff(vec2(-0.5, -0.5) * SHIFT).x;
	blur_luma += HOOKED_texOff(vec2(0.5, 0.5) * SHIFT).x;
	blur_luma += HOOKED_texOff(vec2(-0.5, 0.5) * SHIFT).x;
	blur_luma *= 0.25;
#elif (PTN == 3) // Wider
	blur_luma += HOOKED_texOff(vec2(0.4, -1.2) * SHIFT).x;
	blur_luma += HOOKED_texOff(vec2(-1.2, -0.4) * SHIFT).x;
	blur_luma += HOOKED_texOff(vec2(1.2, 0.4) * SHIFT).x;
	blur_luma += HOOKED_texOff(vec2(-0.4, 1.2) * SHIFT).x;
	blur_luma *= 0.25;
	strength *= 0.51;
#elif (PTN == 4) // Pyramid
	blur_luma += HOOKED_texOff(vec2(0.5, -1.0) * SHIFT).x;
	blur_luma += HOOKED_texOff(vec2(-1.0, -0.5) * SHIFT).x;
	blur_luma += HOOKED_texOff(vec2(1.0, 0.5) * SHIFT).x;
	blur_luma += HOOKED_texOff(vec2(-0.5, 1.0) * SHIFT).x;
	blur_luma /= 4.0;
	strength *= 0.666;
#elif (PTN == 5) // Slower Gaussian
	float px = SHIFT;
	float py = SHIFT;
	blur_luma += HOOKED_texOff(vec2(-px, py)).x;
	blur_luma += HOOKED_texOff(vec2(px, -py)).x;
	blur_luma += HOOKED_texOff(vec2(-px, -py)).x;
	blur_luma += HOOKED_texOff(vec2(px, py)).x;
	float blur_ori2 = HOOKED_texOff(vec2(0.0, py)).x;
	blur_ori2 += HOOKED_texOff(vec2(0.0, -py)).x;
	blur_ori2 += HOOKED_texOff(vec2(-px, 0.0)).x;
	blur_ori2 += HOOKED_texOff(vec2(px, 0.0)).x;
	blur_ori2 *= 2.0;
	blur_luma += blur_ori2 + (ori_luma * 4.0);
	blur_luma /= 16.0;
	strength *= 0.75;
#elif (PTN == 6) // Slower High Pass
	float px_ = SHIFT;
	float py_ = SHIFT;
	blur_luma += HOOKED_texOff(vec2(-px_, py_)).x;
	blur_luma += HOOKED_texOff(vec2(px_, -py_)).x;
	blur_luma += HOOKED_texOff(vec2(-px_, -py_)).x;
	blur_luma += HOOKED_texOff(vec2(px_, py_)).x;
	blur_luma += ori_luma;
	blur_luma += HOOKED_texOff(vec2(0.0, py_)).x;
	blur_luma += HOOKED_texOff(vec2(0.0, -py_)).x;
	blur_luma += HOOKED_texOff(vec2(-px_, 0.0)).x;
	blur_luma += HOOKED_texOff(vec2(px_, 0.0)).x;
	blur_luma /= 9.0;
	strength *= (8.0/9.0);
#endif

	float sharp = ori_luma - blur_luma;
	float sharp_luma;

#if (CM == 1)
	sharp_luma = sharp * strength;
	sharp_luma = clamp(sharp_luma, -SC, SC);
#elif (CM == 2)
	float sharp_strength_clamp = strength / (2.0 * SC);
	sharp_luma = clamp(sharp * sharp_strength_clamp + 0.5, 0.0, 1.0);
	sharp_luma = (SC * 2.0) * sharp_luma - SC;
#endif

#if (DEBUG == 1)
	return vec4(clamp(0.5 + sharp_luma * 4.0, 0.0, 1.0));
#elif (DEBUG == 0)
	float output_luma = ori_luma + sharp_luma;
	return vec4(clamp(output_luma, 0.0, 1.0));
#endif

}

