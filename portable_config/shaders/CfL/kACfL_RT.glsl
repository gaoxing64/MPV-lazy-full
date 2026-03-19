// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM PB
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.8

//!PARAM EP
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 10.0
2.0

//!PARAM COX
//!TYPE float
0.0

//!PARAM COY
//!TYPE float
0.0


//!HOOK CHROMA
//!BIND HOOKED
//!BIND LUMA
//!SAVE LUMA_LR
//!DESC [kACfL_RT] (4:2:0/4:2:2) DS Luma
//!WIDTH HOOKED.w
//!HEIGHT HOOKED.h
//!WHEN HOOKED.w LUMA.w <

vec4 hook() {

	vec2 pos = LUMA_pos;
	pos.x += COX / LUMA_size.x;
	pos.y += COY / LUMA_size.y;
	float sub_x = LUMA_size.x / HOOKED_size.x;
	float sub_y = LUMA_size.y / HOOKED_size.y;
	float luma_sum = 0.0;
	float count = 0.0;

	if (sub_x > 1.5 && sub_y > 1.5) {
		vec2 base = (floor(pos * LUMA_size - 0.5) + 0.5) * LUMA_pt;
		luma_sum += LUMA_tex(base).x;
		luma_sum += LUMA_tex(base + vec2(LUMA_pt.x, 0.0)).x;
		luma_sum += LUMA_tex(base + vec2(0.0, LUMA_pt.y)).x;
		luma_sum += LUMA_tex(base + vec2(LUMA_pt.x, LUMA_pt.y)).x;
		count = 4.0;
	} else if (sub_x > 1.5) {
		vec2 base = (floor(pos * LUMA_size - vec2(0.5, 0.0)) + 0.5) * LUMA_pt;
		luma_sum += LUMA_tex(base).x;
		luma_sum += LUMA_tex(base + vec2(LUMA_pt.x, 0.0)).x;
		count = 2.0;
	} else {
		luma_sum = LUMA_tex(pos).x;
		count = 1.0;
	}

	float luma_avg = luma_sum / count;
	return vec4(luma_avg, 0.0, 0.0, 1.0);

}

//!HOOK CHROMA
//!BIND HOOKED
//!BIND LUMA
//!BIND LUMA_LR
//!DESC [kACfL_RT] CfL Prediction
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!OFFSET ALIGN
//!WHEN CHROMA.w LUMA.w <
//!COMPUTE 32 32 8 8

shared float s_luma[20][20];
shared float s_chroma_cb[20][20];
shared float s_chroma_cr[20][20];

float gaussian(float x, float sigma) {
	return exp(-0.5 * x * x / (sigma * sigma));
}

void hook() {

	vec2 scale_factor = LUMA_size / LUMA_LR_size;
	bool use_tile = (scale_factor.x >= 1.9 && scale_factor.y >= 1.9);
	ivec2 block_base = ivec2(floor(vec2(gl_WorkGroupID.xy) * 32.0 / scale_factor));

	if (use_tile) {
		for (int i = int(gl_LocalInvocationIndex); i < 400; i += 64) {
			int ty = i / 20;
			int tx = i % 20;
			ivec2 fetch_pos = clamp(block_base + ivec2(tx, ty) - ivec2(2), ivec2(0), ivec2(LUMA_LR_size) - ivec2(1));
			vec2 tex_pos = (vec2(fetch_pos) + 0.5) * LUMA_LR_pt;
			s_luma[ty][tx] = textureLod(LUMA_LR_raw, tex_pos, 0.0).x * LUMA_LR_mul;
			vec2 c = textureLod(HOOKED_raw, tex_pos, 0.0).xy * HOOKED_mul;
			s_chroma_cb[ty][tx] = c.x;
			s_chroma_cr[ty][tx] = c.y;
		}
	}

	barrier();

	for (int dy = 0; dy < 4; dy++) {
		for (int dx = 0; dx < 4; dx++) {
			ivec2 out_pos = ivec2(gl_GlobalInvocationID.xy) * 4 + ivec2(dx, dy);
			if (out_pos.x >= int(LUMA_size.x) || out_pos.y >= int(LUMA_size.y)) continue;

			float luma_hr = textureLod(LUMA_raw, (vec2(out_pos) + 0.5) / LUMA_size, 0.0).x * LUMA_mul;
			vec2 chroma_pos = (vec2(out_pos) + 0.5) / scale_factor;
			vec2 pp = chroma_pos - 0.5;
			ivec2 fp = ivec2(floor(pp));
			vec2 frac = pp - vec2(fp);
			float luma_samples[16];
			vec2 chroma_samples[16];

			if (use_tile) {
				vec2 tile_pos = chroma_pos - vec2(block_base) + vec2(2.0);
				vec2 tile_pp = tile_pos - vec2(0.5);
				ivec2 tile_fp = ivec2(floor(tile_pp));
				tile_fp = clamp(tile_fp, ivec2(1), ivec2(18));
				for (int j = 0; j < 4; j++) {
					for (int i = 0; i < 4; i++) {
						ivec2 sp = clamp(tile_fp + ivec2(i-1, j-1), ivec2(0), ivec2(19));
						int idx = j * 4 + i;
						luma_samples[idx] = s_luma[sp.y][sp.x];
						chroma_samples[idx] = vec2(s_chroma_cb[sp.y][sp.x], s_chroma_cr[sp.y][sp.x]);
					}
				}
			} else {

				for (int j = 0; j < 4; j++) {
					for (int i = 0; i < 4; i++) {
						ivec2 sp = clamp(fp + ivec2(i-1, j-1), ivec2(0), ivec2(LUMA_LR_size) - ivec2(1));
						vec2 tex_pos = (vec2(sp) + 0.5) * LUMA_LR_pt;
						int idx = j * 4 + i;
						luma_samples[idx] = textureLod(LUMA_LR_raw, tex_pos, 0.0).x * LUMA_LR_mul;
						chroma_samples[idx] = textureLod(HOOKED_raw, tex_pos, 0.0).xy * HOOKED_mul;
					}
				}
			}

			float luma_sum = 0.0;
			vec2 chroma_sum = vec2(0.0);
			for (int i = 0; i < 16; i++) {
				luma_sum += luma_samples[i];
				chroma_sum += chroma_samples[i];
			}
			float luma_mean = luma_sum * 0.0625;
			vec2 chroma_mean = chroma_sum * 0.0625;

			float luma_var = 0.0;
			vec2 luma_chroma_cov = vec2(0.0);
			for (int i = 0; i < 16; i++) {
				float ld = luma_samples[i] - luma_mean;
				vec2 cd = chroma_samples[i] - chroma_mean;
				luma_var += ld * ld;
				luma_chroma_cov += ld * cd;
			}

			vec2 alpha = clamp(luma_chroma_cov / max(luma_var, 1e-6), vec2(-2.0), vec2(2.0));
			vec2 chroma_pred = alpha * (luma_hr - luma_mean) + chroma_mean;

			vec2 chroma_var = vec2(0.0);
			for (int i = 0; i < 16; i++) {
				vec2 cd = chroma_samples[i] - chroma_mean;
				chroma_var += cd * cd;
			}
			vec2 correlation = clamp(abs(luma_chroma_cov) / max(sqrt(luma_var * chroma_var), vec2(1e-6)), vec2(0.0), vec2(1.0));

			vec2 chroma_spatial = vec2(0.0);
			float weight_sum = 0.0;
			float luma_center_lr = luma_samples[5];
			float range_sigma = (EP > 0.0) ? (0.1 / EP) : 1e6;

			for (int j = 0; j < 4; j++) {
				for (int i = 0; i < 4; i++) {
					float d = length(vec2(i-1, j-1) - frac);
					float sw = max(1.0 - d * 0.5, 0.0);
					sw *= sw;
					float rw = gaussian(abs(luma_samples[j*4+i] - luma_center_lr), range_sigma);
					float w = sw * rw;
					chroma_spatial += w * chroma_samples[j*4+i];
					weight_sum += w;
				}
			}
			chroma_spatial /= max(weight_sum, 1e-6);

			vec2 blend_weight = pow(correlation, vec2(2.0)) * PB;
			vec2 chroma_out = clamp(mix(chroma_spatial, chroma_pred, blend_weight), vec2(0.0), vec2(1.0));
			imageStore(out_image, out_pos, vec4(chroma_out, 0.0, 1.0));
		}
	}

}

