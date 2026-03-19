// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- RAW ver.
  https://github.com/crosire/reshade-shaders/blob/nvidia/ShadersAndTextures/Clarity.fx

*/


//!PARAM RAD
//!TYPE DEFINE
//!MINIMUM 1
//!MAXIMUM 5
4

//!PARAM SHIFT
//!TYPE float
//!MINIMUM 1.0
//!MAXIMUM 5.0
2.0

//!PARAM STR
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.4

//!PARAM STRD
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.4

//!PARAM STRL
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.0

//!PARAM BM
//!TYPE DEFINE
//!MINIMUM 1
//!MAXIMUM 7
3

//!PARAM CD
//!TYPE int
//!MINIMUM 0
//!MAXIMUM 255
50

//!PARAM CL
//!TYPE int
//!MINIMUM 0
//!MAXIMUM 255
205

//!PARAM DEBUG
//!TYPE int
//!MINIMUM 0
//!MAXIMUM 2
0


//!HOOK MAIN
//!BIND HOOKED
//!SAVE CLARITY1
//!DESC [eq_clarity_RT] blur-h & luma & ds
//!WIDTH HOOKED.w 2 /
//!HEIGHT HOOKED.h 2 /
//!WHEN STR
//!COMPONENTS 1

vec4 hook() {

	vec3 color = HOOKED_tex(HOOKED_pos).rgb;

#if RAD == 1
	float offset[4] = {     0.0, 1.1824255238, 3.0293122308,           5.0040701377 };
	float weight[4] = { 0.39894, 0.2959599993, 0.0045656525, 0.00000149278686458842 };
	color *= weight[0];
	for(int i = 1; i < 4; ++i) {
		color += HOOKED_texOff(vec2(offset[i] * SHIFT, 0.0)).rgb * weight[i];
		color += HOOKED_texOff(vec2(-offset[i] * SHIFT, 0.0)).rgb * weight[i];
	}
#elif RAD == 2
	float offset[6] = {     0.0, 1.4584295168, 3.40398480678, 5.3518057801, 7.302940716, 9.2581597095 };
	float weight[6] = { 0.13298,   0.23227575,  0.1353261595, 0.0511557427,  0.01253922, 0.0019913644 };
	color *= weight[0];
	for(int i = 1; i < 6; ++i) {
		color += HOOKED_texOff(vec2(offset[i] * SHIFT, 0.0)).rgb * weight[i];
		color += HOOKED_texOff(vec2(-offset[i] * SHIFT, 0.0)).rgb * weight[i];
	}
#elif RAD == 3
	float offset[11] = {          0.0, 1.4895848401,  3.4757135714,  5.4618796741,  7.4481042327, 9.4344079746,
						 11.420811147,   13.4073334, 15.3939936778, 17.3808101174, 19.3677999584 };
	float weight[11] = {      0.06649, 0.1284697563,   0.111918249,  0.0873132676,  0.0610011113, 0.0381655709,
						 0.0213835661, 0.0107290241,  0.0048206869,  0.0019396469,  0.0006988718 };
	color *= weight[0];
	for(int i = 1; i < 11; ++i) {
		color += HOOKED_texOff(vec2(offset[i] * SHIFT, 0.0)).rgb * weight[i];
		color += HOOKED_texOff(vec2(-offset[i] * SHIFT, 0.0)).rgb * weight[i];
	}
#elif RAD == 4
	float offset[15] = {           0.0,  1.4953705027,  3.4891992113,  5.4830312105,  7.4768683759, 9.4707125766,
						 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4401038149,  21.43402885,
						 23.4279736431, 25.4219399344, 27.4159294386 };
	float weight[15] = {  0.0443266667,  0.0872994708,  0.0820892038,  0.0734818355,  0.0626171681, 0.0507956191,
						  0.0392263968,  0.0288369812,  0.0201808877,  0.0134446557,  0.0085266392, 0.0051478359,
						  0.0029586248,  0.0016187257,  0.0008430913 };
	color *= weight[0];
	for(int i = 1; i < 15; ++i) {
		color += HOOKED_texOff(vec2(offset[i] * SHIFT, 0.0)).rgb * weight[i];
		color += HOOKED_texOff(vec2(-offset[i] * SHIFT, 0.0)).rgb * weight[i];
	}
#elif RAD == 5
	float offset[18] = {           0.0,  1.4953705027,  3.4891992113,  5.4830312105,  7.4768683759,  9.4707125766,
						 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4661974725, 21.4627427973,
						 23.4592916956,  25.455844494, 27.4524015179, 29.4489630909,  31.445529535, 33.4421011704 };
	float weight[18] = {      0.033245,  0.0659162217,  0.0636705814,  0.0598194658,  0.0546642566,  0.0485871646,
						  0.0420045997,  0.0353207015,  0.0288880982,  0.0229808311,  0.0177815511,   0.013382297,
						  0.0097960001,  0.0069746748,  0.0048301008,  0.0032534598,  0.0021315311,  0.0013582974 };
	color *= weight[0];
	for(int i = 1; i < 18; ++i) {
		color += HOOKED_texOff(vec2(offset[i] * SHIFT, 0.0)).rgb * weight[i];
		color += HOOKED_texOff(vec2(-offset[i] * SHIFT, 0.0)).rgb * weight[i];
	}
#endif

	float luma = dot(color.rgb, vec3(0.32786885, 0.655737705, 0.0163934436));
	return vec4(luma, luma, luma, 1.0);

}

//!HOOK MAIN
//!BIND CLARITY1
//!SAVE CLARITY2
//!DESC [eq_clarity_RT] blur-v
//!WIDTH CLARITY1.w
//!HEIGHT CLARITY1.h
//!WHEN STR
//!COMPONENTS 1

vec4 hook() {

	float color = CLARITY1_tex(CLARITY1_pos).r;

#if RAD == 1
	float offset[4] = {     0.0, 1.1824255238, 3.0293122308,           5.0040701377 };
	float weight[4] = { 0.39894, 0.2959599993, 0.0045656525, 0.00000149278686458842 };
	color *= weight[0];
	for(int i = 1; i < 4; ++i) {
		color += CLARITY1_texOff(vec2(0.0, offset[i] * SHIFT)).r * weight[i];
		color += CLARITY1_texOff(vec2(0.0, -offset[i] * SHIFT)).r * weight[i];
	}
#elif RAD == 2
	float offset[6] = {     0.0, 1.4584295168, 3.40398480678, 5.3518057801, 7.302940716, 9.2581597095 };
	float weight[6] = { 0.13298,   0.23227575,  0.1353261595, 0.0511557427,  0.01253922, 0.0019913644 };
	color *= weight[0];
	for(int i = 1; i < 6; ++i) {
		color += CLARITY1_texOff(vec2(0.0, offset[i] * SHIFT)).r * weight[i];
		color += CLARITY1_texOff(vec2(0.0, -offset[i] * SHIFT)).r * weight[i];
	}
#elif RAD == 3
	float offset[11] = {          0.0, 1.4895848401,  3.4757135714,  5.4618796741,  7.4481042327, 9.4344079746,
						 11.420811147,   13.4073334, 15.3939936778, 17.3808101174, 19.3677999584 };
	float weight[11] = {      0.06649, 0.1284697563,   0.111918249,  0.0873132676,  0.0610011113, 0.0381655709,
						 0.0213835661, 0.0107290241,  0.0048206869,  0.0019396469,  0.0006988718 };
	color *= weight[0];
	for(int i = 1; i < 11; ++i) {
		color += CLARITY1_texOff(vec2(0.0, offset[i] * SHIFT)).r * weight[i];
		color += CLARITY1_texOff(vec2(0.0, -offset[i] * SHIFT)).r * weight[i];
	}
#elif RAD == 4
	float offset[15] = {           0.0,  1.4953705027,  3.4891992113,  5.4830312105,  7.4768683759, 9.4707125766,
						 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4401038149,  21.43402885,
						 23.4279736431, 25.4219399344, 27.4159294386 };
	float weight[15] = {  0.0443266667,  0.0872994708,  0.0820892038,  0.0734818355,  0.0626171681, 0.0507956191,
						  0.0392263968,  0.0288369812,  0.0201808877,  0.0134446557,  0.0085266392, 0.0051478359,
						  0.0029586248,  0.0016187257,  0.0008430913 };
	color *= weight[0];
	for(int i = 1; i < 15; ++i) {
		color += CLARITY1_texOff(vec2(0.0, offset[i] * SHIFT)).r * weight[i];
		color += CLARITY1_texOff(vec2(0.0, -offset[i] * SHIFT)).r * weight[i];
	}
#elif RAD == 5
	float offset[18] = {           0.0,  1.4953705027,  3.4891992113,  5.4830312105,  7.4768683759,  9.4707125766,
						 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4661974725, 21.4627427973,
						 23.4592916956,  25.455844494, 27.4524015179, 29.4489630909,  31.445529535, 33.4421011704 };
	float weight[18] = {      0.033245,  0.0659162217,  0.0636705814,  0.0598194658,  0.0546642566,  0.0485871646,
						  0.0420045997,  0.0353207015,  0.0288880982,  0.0229808311,  0.0177815511,   0.013382297,
						  0.0097960001,  0.0069746748,  0.0048301008,  0.0032534598,  0.0021315311,  0.0013582974 };
	color *= weight[0];
	for(int i = 1; i < 18; ++i) {
		color += CLARITY1_texOff(vec2(0.0, offset[i] * SHIFT)).r * weight[i];
		color += CLARITY1_texOff(vec2(0.0, -offset[i] * SHIFT)).r * weight[i];
	}
#endif

	return vec4(color, color, color, 1.0);

}

//!HOOK MAIN
//!BIND CLARITY2
//!SAVE CLARITY3
//!DESC [eq_clarity_RT] blur-h & ds
//!WIDTH HOOKED.w 4 /
//!HEIGHT HOOKED.h 4 /
//!WHEN STR
//!COMPONENTS 1

vec4 hook() {

	float color = CLARITY2_tex(CLARITY2_pos).r;

#if RAD == 1
	float offset[4] = {     0.0, 1.1824255238, 3.0293122308,           5.0040701377 };
	float weight[4] = { 0.39894, 0.2959599993, 0.0045656525, 0.00000149278686458842 };
	color *= weight[0];
	for(int i = 1; i < 4; ++i) {
		color += CLARITY2_texOff(vec2(offset[i] * SHIFT, 0.0)).r * weight[i];
		color += CLARITY2_texOff(vec2(-offset[i] * SHIFT, 0.0)).r * weight[i];
	}
#elif RAD == 2
	float offset[6] = {     0.0, 1.4584295168, 3.40398480678, 5.3518057801, 7.302940716, 9.2581597095 };
	float weight[6] = { 0.13298,   0.23227575,  0.1353261595, 0.0511557427,  0.01253922, 0.0019913644 };
	color *= weight[0];
	for(int i = 1; i < 6; ++i) {
		color += CLARITY2_texOff(vec2(offset[i] * SHIFT, 0.0)).r * weight[i];
		color += CLARITY2_texOff(vec2(-offset[i] * SHIFT, 0.0)).r * weight[i];
	}
#elif RAD == 3
	float offset[11] = {          0.0, 1.4895848401,  3.4757135714,  5.4618796741,  7.4481042327, 9.4344079746,
						 11.420811147,   13.4073334, 15.3939936778, 17.3808101174, 19.3677999584 };
	float weight[11] = {      0.06649, 0.1284697563,   0.111918249,  0.0873132676,  0.0610011113, 0.0381655709,
						 0.0213835661, 0.0107290241,  0.0048206869,  0.0019396469,  0.0006988718 };
	color *= weight[0];
	for(int i = 1; i < 11; ++i) {
		color += CLARITY2_texOff(vec2(offset[i] * SHIFT, 0.0)).r * weight[i];
		color += CLARITY2_texOff(vec2(-offset[i] * SHIFT, 0.0)).r * weight[i];
	}
#elif RAD == 4
	float offset[15] = {           0.0,  1.4953705027,  3.4891992113,  5.4830312105,  7.4768683759, 9.4707125766,
						 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4401038149,  21.43402885,
						 23.4279736431, 25.4219399344, 27.4159294386 };
	float weight[15] = {  0.0443266667,  0.0872994708,  0.0820892038,  0.0734818355,  0.0626171681, 0.0507956191,
						  0.0392263968,  0.0288369812,  0.0201808877,  0.0134446557,  0.0085266392, 0.0051478359,
						  0.0029586248,  0.0016187257,  0.0008430913 };
	color *= weight[0];
	for(int i = 1; i < 15; ++i) {
		color += CLARITY2_texOff(vec2(offset[i] * SHIFT, 0.0)).r * weight[i];
		color += CLARITY2_texOff(vec2(-offset[i] * SHIFT, 0.0)).r * weight[i];
	}
#elif RAD == 5
	float offset[18] = {           0.0,  1.4953705027,  3.4891992113,  5.4830312105,  7.4768683759,  9.4707125766,
						 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4661974725, 21.4627427973,
						 23.4592916956,  25.455844494, 27.4524015179, 29.4489630909,  31.445529535, 33.4421011704 };
	float weight[18] = {      0.033245,  0.0659162217,  0.0636705814,  0.0598194658,  0.0546642566,  0.0485871646,
						  0.0420045997,  0.0353207015,  0.0288880982,  0.0229808311,  0.0177815511,   0.013382297,
						  0.0097960001,  0.0069746748,  0.0048301008,  0.0032534598,  0.0021315311,  0.0013582974 };
	color *= weight[0];
	for(int i = 1; i < 18; ++i) {
		color += CLARITY2_texOff(vec2(offset[i] * SHIFT, 0.0)).r * weight[i];
		color += CLARITY2_texOff(vec2(-offset[i] * SHIFT, 0.0)).r * weight[i];
	}
#endif

	return vec4(color, color, color, 1.0);

}

//!HOOK MAIN
//!BIND HOOKED
//!BIND CLARITY3
//!DESC [eq_clarity_RT] merge
//!WHEN STR

vec4 hook()
{

	float color = CLARITY3_tex(CLARITY3_pos).r;

#if RAD == 1
	float offset[4] = {     0.0, 1.1824255238, 3.0293122308,           5.0040701377 };
	float weight[4] = { 0.39894, 0.2959599993, 0.0045656525, 0.00000149278686458842 };
	color *= weight[0];
	for(int i = 1; i < 4; ++i) {
		color += CLARITY3_texOff(vec2(0.0, offset[i] * SHIFT)).r * weight[i];
		color += CLARITY3_texOff(vec2(0.0, -offset[i] * SHIFT)).r * weight[i];
	}
#elif RAD == 2
	float offset[6] = {     0.0, 1.4584295168, 3.40398480678, 5.3518057801, 7.302940716, 9.2581597095 };
	float weight[6] = { 0.13298,   0.23227575,  0.1353261595, 0.0511557427, 0.01253922,  0.0019913644 };
	color *= weight[0];
	for(int i = 1; i < 6; ++i) {
		color += CLARITY3_texOff(vec2(0.0, offset[i] * SHIFT)).r * weight[i];
		color += CLARITY3_texOff(vec2(0.0, -offset[i] * SHIFT)).r * weight[i];
	}
#elif RAD == 3
	float offset[11] = {          0.0, 1.4895848401,  3.4757135714,  5.4618796741,  7.4481042327, 9.4344079746,
						 11.420811147,   13.4073334, 15.3939936778, 17.3808101174, 19.3677999584 };
	float weight[11] = {      0.06649, 0.1284697563,   0.111918249,  0.0873132676,  0.0610011113, 0.0381655709,
						 0.0213835661, 0.0107290241,  0.0048206869,  0.0019396469,  0.0006988718 };
	color *= weight[0];
	for(int i = 1; i < 11; ++i) {
		color += CLARITY3_texOff(vec2(0.0, offset[i] * SHIFT)).r * weight[i];
		color += CLARITY3_texOff(vec2(0.0, -offset[i] * SHIFT)).r * weight[i];
	}
#elif RAD == 4
	float offset[15] = {           0.0,  1.4953705027,  3.4891992113,  5.4830312105,  7.4768683759, 9.4707125766,
						 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4401038149,  21.43402885,
						 23.4279736431, 25.4219399344, 27.4159294386 };
	float weight[15] = {  0.0443266667,  0.0872994708,  0.0820892038,  0.0734818355,  0.0626171681, 0.0507956191,
						  0.0392263968,  0.0288369812,  0.0201808877,  0.0134446557,  0.0085266392, 0.0051478359,
						  0.0029586248,  0.0016187257,  0.0008430913 };
	color *= weight[0];
	for(int i = 1; i < 15; ++i) {
		color += CLARITY3_texOff(vec2(0.0, offset[i] * SHIFT)).r * weight[i];
		color += CLARITY3_texOff(vec2(0.0, -offset[i] * SHIFT)).r * weight[i];
	}
#elif RAD == 5
	float offset[18] = {           0.0,  1.4953705027,  3.4891992113,  5.4830312105,  7.4768683759,  9.4707125766,
						 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4661974725, 21.4627427973,
						 23.4592916956,  25.455844494, 27.4524015179, 29.4489630909,  31.445529535, 33.4421011704 };
	float weight[18] = {      0.033245,  0.0659162217,  0.0636705814,  0.0598194658,  0.0546642566,  0.0485871646,
						  0.0420045997,  0.0353207015,  0.0288880982,  0.0229808311,  0.0177815511,   0.013382297,
						  0.0097960001,  0.0069746748,  0.0048301008,  0.0032534598,  0.0021315311,  0.0013582974 };
	color *= weight[0];
	for(int i = 1; i < 18; ++i) {
		color += CLARITY3_texOff(vec2(0.0, offset[i] * SHIFT)).r * weight[i];
		color += CLARITY3_texOff(vec2(0.0, -offset[i] * SHIFT)).r * weight[i];
	}
#endif

	vec3 orig = HOOKED_tex(HOOKED_pos).rgb;
	float luma = dot(orig.rgb, vec3(0.32786885, 0.655737705, 0.0163934436));
	vec3 chroma = orig.rgb / luma;

	float sharp = 1.0 - color;
	sharp = (luma + sharp) * 0.5;

	float sharpMin = mix(0.0, 1.0, smoothstep(0.0, 1.0, sharp));
	float sharpMax = sharpMin;
	sharpMin = mix(sharp, sharpMin, STRD);
	sharpMax = mix(sharp, sharpMax, STRL);
	sharp = mix(sharpMin, sharpMax, step(0.5, sharp));

	if (DEBUG == 1) {
		return vec4(vec3(sharp), 1.0);
	}

#if BM == 1
	// Soft Light
	sharp = mix(2.0*luma*sharp + luma*luma*(1.0-2.0*sharp), 2.0*luma*(1.0-sharp)+pow(luma,0.5)*(2.0*sharp-1.0), step(0.49,sharp));
#elif BM == 2
	// Overlay
	sharp = mix(2.0*luma*sharp, 1.0 - 2.0*(1.0-luma)*(1.0-sharp), step(0.50,luma));
#elif BM == 3
	// Hardlight
	sharp = mix(2.0*luma*sharp, 1.0 - 2.0*(1.0-luma)*(1.0-sharp), step(0.50,sharp));
#elif BM == 4
	// Multiply
	sharp = clamp(2.0 * luma * sharp, 0.0, 1.0);
#elif BM == 5
	// Vivid Light (Safer version)
	sharp = mix(luma / max(2.0 * (1.0 - sharp), 1e-6), 1.0 - (1.0 - luma) / max(2.0 * sharp, 1e-6), step(0.5, sharp));
#elif BM == 6
	// Linear Light
	sharp = luma + 2.0*sharp - 1.0;
#elif BM == 7
	// Addition
	sharp = clamp(luma + (sharp - 0.5), 0.0, 1.0);
#endif

	if (CD > 0 || CL < 255 || DEBUG == 2) {
		float ClarityBlendIfD = (float(CD) / 255.0) + 0.0001;
		float ClarityBlendIfL = (float(CL) / 255.0) - 0.0001;
		float mix_val = dot(orig.rgb, vec3(0.333333));
		float mask = 1.0;
		if (CD > 0) {
			mask = mix(0.0, 1.0, smoothstep(ClarityBlendIfD - (ClarityBlendIfD * 0.2), ClarityBlendIfD + (ClarityBlendIfD * 0.2), mix_val));
		}
		if (CL < 255) {
			mask = mix(mask, 0.0, smoothstep(ClarityBlendIfL - (ClarityBlendIfL * 0.2), ClarityBlendIfL + (ClarityBlendIfL * 0.2), mix_val));
		}
		if (DEBUG == 2) {
			return vec4(vec3(mask), 1.0);
		}
		sharp = mix(luma, sharp, mask);
	}

	orig.rgb = mix(vec3(luma), vec3(sharp), STR);
	orig.rgb *= chroma;
	return vec4(clamp(orig.rgb, 0.0, 1.0), 1.0);

}

