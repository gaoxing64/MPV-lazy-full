// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- Paper ver.
  https://johncostella.com/magic/

*/


//!HOOK MAIN
//!BIND HOOKED
//!SAVE MKS_H
//!DESC [Magic_Kernel_Sharp2013] (Horizontal)
//!WIDTH OUTPUT.w
//!HEIGHT HOOKED.h
//!WHEN OUTPUT.w HOOKED.w = ! OUTPUT.h HOOKED.h = ! +

const float KERNEL_RADIUS = 2.5;
const int UPSCALE_RADIUS = 3;

float magic_kernel_sharp_2013(float x) {
	x = abs(x);
	if (x <= 0.5) return 17.0/16.0 - (7.0/4.0) * x * x;
	if (x <= 1.5) return 0.25 * (4.0 * x * x - 11.0 * x + 7.0);
	if (x <= KERNEL_RADIUS) return -0.125 * (x - 2.5) * (x - 2.5);
	return 0.0;
}

vec4 hook() {

	float src_w = HOOKED_size.x;
	float dst_w = target_size.x;

	float ratio = src_w / dst_w;
	float scale = max(ratio, 1.0);
	int radius = (ratio > 1.0) ? int(ceil(KERNEL_RADIUS * scale)) : UPSCALE_RADIUS;

	float src_x = HOOKED_pos.x * src_w - 0.5;
	int src_base = int(floor(src_x));
	float frac_x = src_x - float(src_base);
	int cur_y = int(floor(HOOKED_pos.y * HOOKED_size.y));

	vec4 sum_color = vec4(0.0);
	float wsum = 0.0;

	for (int kx = -radius; kx <= radius; kx++) {
		int sx = src_base + kx;
		if (sx < 0 || sx >= int(src_w)) continue;

		float dx_dist = abs(frac_x - float(kx)) / scale;
		if (dx_dist >= KERNEL_RADIUS) continue;
		float w = magic_kernel_sharp_2013(dx_dist);

		vec4 sample_color = texelFetch(HOOKED_raw, ivec2(sx, cur_y), 0);
		sample_color = linearize(sample_color);
		sum_color += sample_color * w;
		wsum += w;
	}

	if (wsum > 0.0) {
		sum_color /= wsum;
	}
	return sum_color;

}

//!HOOK MAIN
//!BIND HOOKED
//!BIND MKS_H
//!DESC [Magic_Kernel_Sharp2013] (Vertical)
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h

const float KERNEL_RADIUS = 2.5;
const int UPSCALE_RADIUS = 3;

float magic_kernel_sharp_2013_v(float x) {
	x = abs(x);
	if (x <= 0.5) return 17.0/16.0 - (7.0/4.0) * x * x;
	if (x <= 1.5) return 0.25 * (4.0 * x * x - 11.0 * x + 7.0);
	if (x <= KERNEL_RADIUS) return -0.125 * (x - 2.5) * (x - 2.5);
	return 0.0;
}

vec4 hook() {

	float src_h = MKS_H_size.y;
	float dst_h = target_size.y;

	float ratio = src_h / dst_h;
	float scale = max(ratio, 1.0);
	int radius = (ratio > 1.0) ? int(ceil(KERNEL_RADIUS * scale)) : UPSCALE_RADIUS;

	float src_y = MKS_H_pos.y * src_h - 0.5;
	int src_base = int(floor(src_y));
	float frac_y = src_y - float(src_base);
	int cur_x = int(floor(MKS_H_pos.x * MKS_H_size.x));

	vec4 sum_color = vec4(0.0);
	float wsum = 0.0;

	for (int ky = -radius; ky <= radius; ky++) {
		int sy = src_base + ky;
		if (sy < 0 || sy >= int(src_h)) continue;

		float dy_dist = abs(frac_y - float(ky)) / scale;
		if (dy_dist >= KERNEL_RADIUS) continue;
		float w = magic_kernel_sharp_2013_v(dy_dist);

		vec4 sample_color = texelFetch(MKS_H_raw, ivec2(cur_x, sy), 0);
		sum_color += sample_color * w;
		wsum += w;
	}

	if (wsum > 0.0) {
		sum_color /= wsum;
	}

	vec4 orig = HOOKED_texOff(0);
	sum_color = delinearize(sum_color);
	sum_color.a = orig.a;
	return sum_color;

}

