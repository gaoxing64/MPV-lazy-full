// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- RAW ver.
  https://github.com/LIJI32/SameBoy/blob/master/LICENSE

*/


//!PARAM METRIC
//!TYPE int
//!MINIMUM 1
//!MAXIMUM 2
1

//!PARAM THR1
//!TYPE float
//!MINIMUM 0.001
//!MAXIMUM 0.1
0.082

//!PARAM THR2X
//!TYPE float
//!MINIMUM 0.001
//!MAXIMUM 0.1
0.018

//!PARAM THR2Y
//!TYPE float
//!MINIMUM 0.001
//!MAXIMUM 0.1
0.002

//!PARAM THR2Z
//!TYPE float
//!MINIMUM 0.001
//!MAXIMUM 0.1
0.005


//!HOOK MAIN
//!BIND HOOKED
//!DESC [OmniScale_RT]
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w HOOKED.w 1.000 * > OUTPUT.h HOOKED.h 1.000 * > *

vec4 texture_relative(vec2 pos, vec2 offset) {
	return HOOKED_tex(pos + offset * HOOKED_pt);
}

vec3 rgb_to_hq_colospace(vec4 rgb) {
	return vec3( 0.250 * rgb.r + 0.250 * rgb.g + 0.250 * rgb.b,
				 0.250 * rgb.r - 0.000 * rgb.g - 0.250 * rgb.b,
				-0.125 * rgb.r + 0.250 * rgb.g - 0.125 * rgb.b);
}

bool is_different(vec4 a, vec4 b) {
	if (METRIC == 1)
		return distance(a.rgb, b.rgb) > THR1;
	else {
		vec3 da = rgb_to_hq_colospace(a);
		vec3 db = rgb_to_hq_colospace(b);
		vec3 d  = abs(da - db);
		return d.x > THR2X || d.y > THR2Y || d.z > THR2Z;
	}
}

#define P(m, r) ((pattern & (m)) == (r))

vec4 scale_omniscale(vec2 position) {
	vec2 pixel_pos = position * HOOKED_size;
	vec2 base_pixel = floor(pixel_pos);
	vec2 p = pixel_pos - base_pixel;
	vec2 aligned_pos = (base_pixel + 0.5) / HOOKED_size;
	vec2 o = vec2(1, 1);

	if (p.x > 0.5) {
		o.x = -o.x;
		p.x = 1.0 - p.x;
	}
	if (p.y > 0.5) {
		o.y = -o.y;
		p.y = 1.0 - p.y;
	}

	vec4 w0 = texture_relative(aligned_pos, vec2( -o.x, -o.y));
	vec4 w1 = texture_relative(aligned_pos, vec2(    0, -o.y));
	vec4 w2 = texture_relative(aligned_pos, vec2(  o.x, -o.y));
	vec4 w3 = texture_relative(aligned_pos, vec2( -o.x,    0));
	vec4 w4 = texture_relative(aligned_pos, vec2(    0,    0));
	vec4 w5 = texture_relative(aligned_pos, vec2(  o.x,    0));
	vec4 w6 = texture_relative(aligned_pos, vec2( -o.x,  o.y));
	vec4 w7 = texture_relative(aligned_pos, vec2(    0,  o.y));
	vec4 w8 = texture_relative(aligned_pos, vec2(  o.x,  o.y));

	int pattern = 0;
	if (is_different(w0, w4)) pattern |= 1 << 0;
	if (is_different(w1, w4)) pattern |= 1 << 1;
	if (is_different(w2, w4)) pattern |= 1 << 2;
	if (is_different(w3, w4)) pattern |= 1 << 3;
	if (is_different(w5, w4)) pattern |= 1 << 4;
	if (is_different(w6, w4)) pattern |= 1 << 5;
	if (is_different(w7, w4)) pattern |= 1 << 6;
	if (is_different(w8, w4)) pattern |= 1 << 7;

	if ((P(0xBF,0x37) || P(0xDB,0x13)) && is_different(w1, w5)) {
		return mix(w4, w3, 0.5 - p.x);
	}
	if ((P(0xDB,0x49) || P(0xEF,0x6D)) && is_different(w7, w3)) {
		return mix(w4, w1, 0.5 - p.y);
	}
	if ((P(0x0B,0x0B) || P(0xFE,0x4A) || P(0xFE,0x1A)) && is_different(w3, w1)) {
		return w4;
	}
	if ((P(0x6F,0x2A) || P(0x5B,0x0A) || P(0xBF,0x3A) || P(0xDF,0x5A) ||
		 P(0x9F,0x8A) || P(0xCF,0x8A) || P(0xEF,0x4E) || P(0x3F,0x0E) ||
		 P(0xFB,0x5A) || P(0xBB,0x8A) || P(0x7F,0x5A) || P(0xAF,0x8A) ||
		 P(0xEB,0x8A)) && is_different(w3, w1)) {
		return mix(w4, mix(w4, w0, 0.5 - p.x), 0.5 - p.y);
	}
	if (P(0x0B,0x08)) {
		return mix(mix(w0 * 0.375 + w1 * 0.25 + w4 * 0.375, w4 * 0.5 + w1 * 0.5, p.x * 2.0), w4, p.y * 2.0);
	}
	if (P(0x0B,0x02)) {
		return mix(mix(w0 * 0.375 + w3 * 0.25 + w4 * 0.375, w4 * 0.5 + w3 * 0.5, p.y * 2.0), w4, p.x * 2.0);
	}
	if (P(0x2F,0x2F)) {
		float dist = length(p - vec2(0.5));
		float pixel_size = length(1.0 / (target_size / HOOKED_size));
		if (dist < 0.5 - pixel_size / 2.0) {
			return w4;
		}
		vec4 r;
		if (is_different(w0, w1) || is_different(w0, w3)) {
			r = mix(w1, w3, p.y - p.x + 0.5);
		}
		else {
			r = mix(mix(w1 * 0.375 + w0 * 0.25 + w3 * 0.375, w3, p.y * 2.0), w1, p.x * 2.0);
		}

		if (dist > 0.5 + pixel_size / 2.0) {
			return r;
		}
		return mix(w4, r, (dist - 0.5 + pixel_size / 2.0) / pixel_size);
	}
	if (P(0xBF,0x37) || P(0xDB,0x13)) {
		float dist = p.x - 2.0 * p.y;
		float pixel_size = length(1.0 / (target_size / HOOKED_size)) * sqrt(5.0);
		if (dist > pixel_size / 2.0) {
			return w1;
		}
		vec4 r = mix(w3, w4, p.x + 0.5);
		if (dist < -pixel_size / 2.0) {
			return r;
		}
		return mix(r, w1, (dist + pixel_size / 2.0) / pixel_size);
	}
	if (P(0xDB,0x49) || P(0xEF,0x6D)) {
		float dist = p.y - 2.0 * p.x;
		float pixel_size = length(1.0 / (target_size / HOOKED_size)) * sqrt(5.0);
		if (p.y - 2.0 * p.x > pixel_size / 2.0) {
			return w3;
		}
		vec4 r = mix(w1, w4, p.x + 0.5);
		if (dist < -pixel_size / 2.0) {
			return r;
		}
		return mix(r, w3, (dist + pixel_size / 2.0) / pixel_size);
	}
	if (P(0xBF,0x8F) || P(0x7E,0x0E)) {
		float dist = p.x + 2.0 * p.y;
		float pixel_size = length(1.0 / (target_size / HOOKED_size)) * sqrt(5.0);

		if (dist > 1.0 + pixel_size / 2.0) {
			return w4;
		}

		vec4 r;
		if (is_different(w0, w1) || is_different(w0, w3)) {
			r = mix(w1, w3, p.y - p.x + 0.5);
		}
		else {
			r = mix(mix(w1 * 0.375 + w0 * 0.25 + w3 * 0.375, w3, p.y * 2.0), w1, p.x * 2.0);
		}

		if (dist < 1.0 - pixel_size / 2.0) {
			return r;
		}

		return mix(r, w4, (dist + pixel_size / 2.0 - 1.0) / pixel_size);
	}

	if (P(0x7E,0x2A) || P(0xEF,0xAB)) {
		float dist = p.y + 2.0 * p.x;
		float pixel_size = length(1.0 / (target_size / HOOKED_size)) * sqrt(5.0);

		if (p.y + 2.0 * p.x > 1.0 + pixel_size / 2.0) {
			return w4;
		}

		vec4 r;

		if (is_different(w0, w1) || is_different(w0, w3)) {
			r = mix(w1, w3, p.y - p.x + 0.5);
		}
		else {
			r = mix(mix(w1 * 0.375 + w0 * 0.25 + w3 * 0.375, w3, p.y * 2.0), w1, p.x * 2.0);
		}

		if (dist < 1.0 - pixel_size / 2.0) {
			return r;
		}

		return mix(r, w4, (dist + pixel_size / 2.0 - 1.0) / pixel_size);
	}

	if (P(0x1B,0x03) || P(0x4F,0x43) || P(0x8B,0x83) || P(0x6B,0x43)) {
		return mix(w4, w3, 0.5 - p.x);
	}

	if (P(0x4B,0x09) || P(0x8B,0x89) || P(0x1F,0x19) || P(0x3B,0x19)) {
		return mix(w4, w1, 0.5 - p.y);
	}

	if (P(0xFB,0x6A) || P(0x6F,0x6E) || P(0x3F,0x3E) || P(0xFB,0xFA) ||
		P(0xDF,0xDE) || P(0xDF,0x1E)) {
		return mix(w4, w0, (1.0 - p.x - p.y) / 2.0);
	}

	if (P(0x4F,0x4B) || P(0x9F,0x1B) || P(0x2F,0x0B) ||
		P(0xBE,0x0A) || P(0xEE,0x0A) || P(0x7E,0x0A) || P(0xEB,0x4B) ||
		P(0x3B,0x1B)) {
		float dist = p.x + p.y;
		float pixel_size = length(1.0 / (target_size / HOOKED_size));

		if (dist > 0.5 + pixel_size / 2.0) {
			return w4;
		}

		vec4 r;
		if (is_different(w0, w1) || is_different(w0, w3)) {
			r = mix(w1, w3, p.y - p.x + 0.5);
		}
		else {
			r = mix(mix(w1 * 0.375 + w0 * 0.25 + w3 * 0.375, w3, p.y * 2.0), w1, p.x * 2.0);
		}

		if (dist < 0.5 - pixel_size / 2.0) {
			return r;
		}

		return mix(r, w4, (dist + pixel_size / 2.0 - 0.5) / pixel_size);
	}

	if (P(0x0B,0x01)) {
		return mix(mix(w4, w3, 0.5 - p.x), mix(w1, (w1 + w3) / 2.0, 0.5 - p.x), 0.5 - p.y);
	}

	if (P(0x0B,0x00)) {
		return mix(mix(w4, w3, 0.5 - p.x), mix(w1, w0, 0.5 - p.x), 0.5 - p.y);
	}

	float dist = p.x + p.y;
	float pixel_size = length(1.0 / (target_size / HOOKED_size));

	if (dist > 0.5 + pixel_size / 2.0) {
		return w4;
	}

	vec4 x0 = texture_relative(aligned_pos, vec2( -o.x * 2.0, -o.y * 2.0));
	vec4 x1 = texture_relative(aligned_pos, vec2( -o.x      , -o.y * 2.0));
	vec4 x2 = texture_relative(aligned_pos, vec2(  0.0      , -o.y * 2.0));
	vec4 x3 = texture_relative(aligned_pos, vec2(  o.x      , -o.y * 2.0));
	vec4 x4 = texture_relative(aligned_pos, vec2( -o.x * 2.0, -o.y      ));
	vec4 x5 = texture_relative(aligned_pos, vec2( -o.x * 2.0,  0.0      ));
	vec4 x6 = texture_relative(aligned_pos, vec2( -o.x * 2.0,  o.y      ));

	if (is_different(x0, w4)) pattern |= 1 << 8;
	if (is_different(x1, w4)) pattern |= 1 << 9;
	if (is_different(x2, w4)) pattern |= 1 << 10;
	if (is_different(x3, w4)) pattern |= 1 << 11;
	if (is_different(x4, w4)) pattern |= 1 << 12;
	if (is_different(x5, w4)) pattern |= 1 << 13;
	if (is_different(x6, w4)) pattern |= 1 << 14;

	int diagonal_bias = -7;
	while (pattern != 0) {
		diagonal_bias += pattern & 1;
		pattern >>= 1;
	}

	if (diagonal_bias <= 0) {
		vec4 r = mix(w1, w3, p.y - p.x + 0.5);
		if (dist < 0.5 - pixel_size / 2.0) {
			return r;
		}
		return mix(r, w4, (dist + pixel_size / 2.0 - 0.5) / pixel_size);
	}

	return w4;
}

vec4 hook() {

	return scale_omniscale(HOOKED_pos);

}

