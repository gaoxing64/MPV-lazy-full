// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- RAW ver.
  https://github.com/FFmpeg/FFmpeg/blob/master/libavfilter/vf_gradfun.c

*/


//!PARAM STR
//!TYPE float
//!MINIMUM 0.5
//!MAXIMUM 64.0
1.2

//!PARAM RAD
//!TYPE int
//!MINIMUM 4
//!MAXIMUM 32
16

//!PARAM DITHER
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 2.0
1.0


//!HOOK LUMA
//!HOOK CHROMA
//!HOOK RGB
//!BIND HOOKED
//!DESC [kgradfun_RT]
//!WHEN STR 0.5 >

const float DITHER_MATRIX[64] = float[64](
	  0.0,  96.0,  24.0, 120.0,   6.0, 102.0,  30.0, 126.0,
	 64.0,  32.0,  88.0,  56.0,  70.0,  38.0,  94.0,  62.0,
	 16.0, 112.0,   8.0, 104.0,  22.0, 118.0,  14.0, 110.0,
	 80.0,  48.0,  72.0,  40.0,  86.0,  54.0,  78.0,  46.0,
	  4.0, 100.0,  28.0, 124.0,   2.0,  98.0,  26.0, 122.0,
	 68.0,  36.0,  92.0,  60.0,  66.0,  34.0,  90.0,  58.0,
	 20.0, 116.0,  12.0, 108.0,  18.0, 114.0,  10.0, 106.0,
	 84.0,  52.0,  76.0,  44.0,  82.0,  50.0,  74.0,  42.0
);

vec4 hook()
{

	int r = RAD;
	vec4 blurred_sum = vec4(0.0);
	float samples = 0.0;
	for (int y = -r; y <= r; y++) {
		for (int x = -r; x <= r; x++) {
			blurred_sum += HOOKED_texOff(vec2(x, y));
			samples += 1.0;
		}
	}
	vec4 blurred_color = blurred_sum / samples;

	vec4 original_color = HOOKED_texOff(vec2(0.0));
	vec4 final_color = original_color;

	for (int i = 0; i < 3; i++) {
		float pix_orig = original_color[i];
		float pix_blur = blurred_color[i];
		float delta = pix_blur - pix_orig;
		float m_factor = abs(delta) * 16320.0 / STR;
		float m_mix = max(0.0, 127.0 - m_factor);
		float correction = m_mix * m_mix * delta / 16384.0;
		final_color[i] = pix_orig + correction;
	}

	#ifdef LUMA
	if (DITHER > 0.0) {
		ivec2 p = ivec2(gl_FragCoord.xy);
		int index = (p.y % 8) * 8 + (p.x % 8);
		float dither_val = DITHER_MATRIX[index];
		float dither_offset = dither_val / 128.0 / 255.0;
		final_color.rgb += dither_offset * DITHER;
	}
	#endif

	return clamp(final_color, 0.0, 1.0);

}

