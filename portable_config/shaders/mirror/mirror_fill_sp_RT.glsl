// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM RAD
//!TYPE int
//!MINIMUM 1
//!MAXIMUM 50
4

//!PARAM BRT
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 2.0
1.0


//!HOOK MAIN
//!BIND HOOKED
//!DESC [mirror_fill_sp_RT]
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN HOOKED.w HOOKED.h < OUTPUT.w OUTPUT.h > *

vec4 hook() {

	float w_target = float(target_size.x);
	float h_target = float(target_size.y);
	float w_raw = float(input_size.x);
	float h_raw = float(input_size.y);
	float scale_0 = (h_target * w_raw) / h_raw;
	float scale = 1.0 / (scale_0 / w_target);
	vec2 pos = HOOKED_pos;

	if (pos.x >= 0.5 - 0.5 / scale && pos.x <= 0.5 + 0.5 / scale) {

		vec2 scale_f = vec2(scale, 1.0);
		vec2 pos_new = (pos - vec2(0.5)) * scale_f + vec2(0.5);
		return HOOKED_tex(pos_new);

	} else {

		vec2 scale_f = vec2(1.0, 1.0 / scale);
		vec2 pos_new = (pos - vec2(0.5)) * scale_f + vec2(0.5);
		vec4 color_0 = vec4(0.0);
		float rad_max = 10.0 * HOOKED_pt.x;
		float rad_min = 0.0;

		int rad_step = RAD;
		int an_step = 12; // 360/12=30°
		float steps = float(rad_step * an_step);
		float an_delta = (2.0 * 3.141592653589793) / float(an_step);
		float rad_delta = (rad_max - rad_min) / float(rad_step);

		for (int r_step = 0; r_step < rad_step; r_step++) {
			float radius = rad_min + float(r_step) * rad_delta;
			for (int a_step = 0; a_step < an_step; a_step++) {
				float an = float(a_step) * an_delta;
				float xd = radius * cos(an);
				float yd = radius * sin(an);
				vec2 coord_sample = pos_new + vec2(xd, yd);
				vec4 color_curr = HOOKED_tex(coord_sample);
				float frac_curr = float(rad_step + 1 - r_step) / float(rad_step + 1);
				color_0 += frac_curr * color_curr / steps;
			}
		}

		return color_0 * BRT;
	}

}

