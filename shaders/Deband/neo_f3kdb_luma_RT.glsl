// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- VapourSynth ver.
  https://github.com/SAPikachu/flash3kyuu_deband
  --- VapourSynth ver2. (upstream)
  https://github.com/HomeOfAviSynthPlusEvolution/neo_f3kdb

*/


//!PARAM RANGE
//!TYPE int
//!MINIMUM 1
//!MAXIMUM 64
15

//!PARAM GRAIN
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.0

//!PARAM GRAD
//!TYPE int
//!MINIMUM 0
//!MAXIMUM 1
0

//!PARAM THR_AVG
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.015

//!PARAM THR_MAX
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.015

//!PARAM THR_MID
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.015

//!PARAM THR_ALL
//!TYPE int
//!MINIMUM 0
//!MAXIMUM 1
0

//!PARAM AB
//!TYPE float
//!MINIMUM 1.0
//!MAXIMUM 4.0
1.5

//!PARAM AM
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.15


//!HOOK LUMA
//!BIND HOOKED
//!DESC [neo_f3kdb_luma_RT]

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float hash2(vec2 p, float seed) {
	return hash(p + vec2(seed));
}

float getOffset(vec2 pos, float seed) {
	float r = hash2(pos * HOOKED_size, seed + float(frame));
	return floor(r * (2.0 * float(RANGE) + 1.0)) - float(RANGE);
}

float calcGradientAngle(vec2 pos, float dist) {
	float p00 = HOOKED_tex(pos + vec2(-dist, -dist) * HOOKED_pt).x;
	float p10 = HOOKED_tex(pos + vec2(0.0, -dist) * HOOKED_pt).x;
	float p20 = HOOKED_tex(pos + vec2(dist, -dist) * HOOKED_pt).x;
	float p01 = HOOKED_tex(pos + vec2(-dist, 0.0) * HOOKED_pt).x;
	float p21 = HOOKED_tex(pos + vec2(dist, 0.0) * HOOKED_pt).x;
	float p02 = HOOKED_tex(pos + vec2(-dist, dist) * HOOKED_pt).x;
	float p12 = HOOKED_tex(pos + vec2(0.0, dist) * HOOKED_pt).x;
	float p22 = HOOKED_tex(pos + vec2(dist, dist) * HOOKED_pt).x;
	float gx = (p20 + 2.0 * p21 + p22) - (p00 + 2.0 * p01 + p02);
	float gy = (p00 + 2.0 * p10 + p20) - (p02 + 2.0 * p12 + p22);
	const float epsilon = 0.0001;
	if (abs(gx) < epsilon) {
		return 1.0;
	}
	return atan(gy / gx) / 3.14159265 + 0.5;
}

float ratioTerm(float diff, float thresh) {
	if (thresh < 1e-6)
		return (abs(diff) < 1e-6) ? 1.0 : -1e6;
	return 1.0 - abs(diff) / thresh;
}

vec4 hook() {

	float org = HOOKED_texOff(0).x;

	float offset = getOffset(HOOKED_pos, 0.0);
	float ref1_v = HOOKED_texOff(vec2(0.0, offset)).x;
	float ref2_v = HOOKED_texOff(vec2(0.0, -offset)).x;
	float ref1_h = HOOKED_texOff(vec2(offset, 0.0)).x;
	float ref2_h = HOOKED_texOff(vec2(-offset, 0.0)).x;

	float avg = (ref1_v + ref2_v + ref1_h + ref2_h) * 0.25;
	float avgDif = abs(avg - org);
	float maxDif = max(max(abs(ref1_v - org), abs(ref2_v - org)),
		               max(abs(ref1_h - org), abs(ref2_h - org)));
	float midDif_v = abs(ref1_v + ref2_v - 2.0 * org);
	float midDif_h = abs(ref1_h + ref2_h - 2.0 * org);

	float thresh = THR_AVG;
	float thresh1 = THR_MAX;
	float thresh2 = THR_MID;
	if (THR_ALL == 1) {
		thresh1 = THR_AVG;
		thresh2 = THR_AVG;
	}

	if (GRAD == 1) {
		float gradDist = 20.0;
		float angle_org = calcGradientAngle(HOOKED_pos, gradDist);
		float angle_ref1_v = calcGradientAngle(HOOKED_pos + vec2(0.0, offset) * HOOKED_pt, gradDist);
		float angle_ref2_v = calcGradientAngle(HOOKED_pos + vec2(0.0, -offset) * HOOKED_pt, gradDist);
		float angle_ref1_h = calcGradientAngle(HOOKED_pos + vec2(offset, 0.0) * HOOKED_pt, gradDist);
		float angle_ref2_h = calcGradientAngle(HOOKED_pos + vec2(-offset, 0.0) * HOOKED_pt, gradDist);
		float maxAngleDiff = max(max(abs(angle_ref1_v - angle_org), abs(angle_ref2_v - angle_org)),
			                     max(abs(angle_ref1_h - angle_org), abs(angle_ref2_h - angle_org)));

		if (maxAngleDiff <= AM) {
			thresh *= AB;
			thresh1 *= AB;
			thresh2 *= AB;
		}
	}

	float factor = pow(
		clamp(3.0 * ratioTerm(avgDif, thresh), 0.0, 1.0) *
		clamp(3.0 * ratioTerm(maxDif, thresh1), 0.0, 1.0) *
		clamp(3.0 * ratioTerm(midDif_v, thresh2), 0.0, 1.0) *
		clamp(3.0 * ratioTerm(midDif_h, thresh2), 0.0, 1.0),
		0.1
	);

	float result = org + (avg - org) * factor;
	if (GRAIN > 0.0) {
		float grain = (hash(HOOKED_pos * HOOKED_size + float(frame)) - 0.5) * 2.0 * GRAIN;
		result += grain;
	}

	return vec4(result, 0.0, 0.0, 1.0);

}

