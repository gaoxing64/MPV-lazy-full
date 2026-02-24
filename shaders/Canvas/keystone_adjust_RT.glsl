// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM TLX
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 50.0
0.0

//!PARAM TLY
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 50.0
0.0

//!PARAM TRX
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 50.0
0.0

//!PARAM TRY
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 50.0
0.0

//!PARAM BLX
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 50.0
0.0

//!PARAM BLY
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 50.0
0.0

//!PARAM BRX
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 50.0
0.0

//!PARAM BRY
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 50.0
0.0

//!PARAM ALGO
//!TYPE DEFINE
//!MINIMUM 1
//!MAXIMUM 2
1


//!HOOK OUTPUT
//!BIND HOOKED
//!DESC [keystone_adjust_RT]
//!WHEN TLX TLY + TRX + TRY + BLX + BLY + BRX + BRY +

#define pB 1.0/3.0
#define pC 1.0/3.0

float cubic_weight(float d) {
	d = abs(d);
	float d2 = d * d;
	float d3 = d2 * d;
	if (d < 1.0) {
		return ( (12.0 - 9.0 * pB - 6.0 * pC) * d3 +
					(-18.0 + 12.0 * pB + 6.0 * pC) * d2 +
					(6.0 - 2.0 * pB) ) / 6.0;
	} else if (d < 2.0) {
		return ( (-pB - 6.0 * pC) * d3 +
					(6.0 * pB + 30.0 * pC) * d2 +
					(-12.0 * pB - 48.0 * pC) * d +
					(8.0 * pB + 24.0 * pC) ) / 6.0;
	}
	return 0.0;
}

vec4 hook() {

	vec2 p0 = vec2(TLX / 100.0, TLY / 100.0);
	vec2 p1 = vec2(1.0 - (TRX / 100.0), TRY / 100.0);
	vec2 p2 = vec2(BLX / 100.0, 1.0 - (BLY / 100.0));
	vec2 p3 = vec2(1.0 - (BRX / 100.0), 1.0 - (BRY / 100.0));
	float t0 = p0.x * (p3.y - p1.y) + p1.x * (p0.y - p3.y) + p3.x * (p1.y - p0.y);
	float t1 = p1.x * (p2.y - p3.y) + p2.x * (p3.y - p1.y) + p3.x * (p1.y - p2.y);
	float t2 = p0.x * (p3.y - p2.y) + p2.x * (p0.y - p3.y) + p3.x * (p2.y - p0.y);
	float t3 = p0.x * (p1.y - p2.y) + p1.x * (p2.y - p0.y) + p2.x * (p0.y - p1.y);

	float X0 = t0 * t1 * (p2.y - p0.y);
	float X1 = t0 * t1 * (p0.x - p2.x);
	float X2 = t0 * t1 * (p0.y * p2.x - p0.x * p2.y);
	float X3 = t1 * t2 * (p1.y - p0.y);
	float X4 = t1 * t2 * (p0.x - p1.x);
	float X5 = t1 * t2 * (p0.y * p1.x - p0.x * p1.y);
	float X6 = t1 * t2 * (p1.y - p0.y) + t0 * t3 * (p2.y - p3.y);
	float X7 = t1 * t2 * (p0.x - p1.x) + t0 * t3 * (p3.x - p2.x);
	float X8 = t1 * t2 * (p0.y * p1.x - p0.x * p1.y) + t0 * t3 * (p2.x * p3.y - p2.y * p3.x);

	vec2 target_coord = HOOKED_pos;
	float denominator = X6 * target_coord.x + X7 * target_coord.y + X8;
	if (abs(denominator) < 1e-6) {
		return vec4(vec3(0.0), 1.0);
	}
	vec2 source_coord;
	source_coord.x = (X0 * target_coord.x + X1 * target_coord.y + X2) / denominator;
	source_coord.y = (X3 * target_coord.x + X4 * target_coord.y + X5) / denominator;

	if (source_coord.x < 0.0 || source_coord.x > 1.0 || source_coord.y < 0.0 || source_coord.y > 1.0) {
		return vec4(vec3(0.0), 1.0);
	}
	#if ALGO == 1
		return HOOKED_tex(source_coord);
	#elif ALGO == 2
		vec2 pt = HOOKED_pt;
		vec2 c = source_coord / pt;
		vec2 f = fract(c);
		ivec2 i = ivec2(floor(c));
		vec4 sum = vec4(vec3(0.0), 1.0);
		for (int y = -1; y <= 2; y++) {
			for (int x = -1; x <= 2; x++) {
				ivec2 offset_coord = i + ivec2(x, y);
				vec4 texel_color = texelFetch(HOOKED_raw, offset_coord, 0);
				float weight = cubic_weight(f.x - float(x)) * cubic_weight(f.y - float(y));
				sum += texel_color * weight;
			}
		}
		return vec4(sum.rgb * HOOKED_mul, sum.a);
	#endif

}

