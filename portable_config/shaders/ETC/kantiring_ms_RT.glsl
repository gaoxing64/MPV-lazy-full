// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM TAP
//!TYPE int
//!MINIMUM 2
//!MAXIMUM 4
2

//!PARAM STR
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.75


//!HOOK POSTKERNEL
//!BIND HOOKED
//!BIND PREKERNEL
//!DESC [kantiring_ms_RT]
//!WHEN HOOKED.w PREKERNEL.w > HOOKED.h PREKERNEL.h > * STR *

float luma(vec4 color) {
	return dot(color.rgb, vec3(0.299, 0.587, 0.114));
}

vec4 hook() {

	vec2 prep = PREKERNEL_pos * PREKERNEL_size - vec2(0.5);
	vec2 frp = floor(prep);
	vec2 pos_c = frp + vec2(0.5);

	float luma_samples[9];
	int idx = 0;
	for (int y = -1; y <= 1; ++y) {
		for (int x = -1; x <= 1; ++x) {
			luma_samples[idx++] = luma(PREKERNEL_tex((pos_c + vec2(x, y)) * PREKERNEL_pt));
		}
	}

	float Gx = ( luma_samples[2] + 2.0 * luma_samples[5] + luma_samples[8]) -
				(luma_samples[0] + 2.0 * luma_samples[3] + luma_samples[6]);
	float Gy = ( luma_samples[6] + 2.0 * luma_samples[7] + luma_samples[8]) -
				(luma_samples[0] + 2.0 * luma_samples[1] + luma_samples[2]);

	vec2 grad = vec2(Gx, Gy);
	vec2 dir = (length(grad) > 0.001) ? normalize(grad) : vec2(0.0, 0.0);

	vec4 pix_c = PREKERNEL_tex(pos_c * PREKERNEL_pt);
	vec4 pix_min = pix_c;
	vec4 pix_max = pix_c;

	for (int i = 1; i <= TAP; ++i) {
		vec4 s_pos = PREKERNEL_tex((pos_c + float(i) * dir) * PREKERNEL_pt);
		vec4 s_neg = PREKERNEL_tex((pos_c - float(i) * dir) * PREKERNEL_pt);
		pix_min = min(pix_min, min(s_pos, s_neg));
		pix_max = max(pix_max, max(s_pos, s_neg));
	}

	vec4 pix_hires = HOOKED_texOff(0.0);
	vec4 clp = clamp(pix_hires, pix_min, pix_max);
	return mix(pix_hires, clp, STR);

}

