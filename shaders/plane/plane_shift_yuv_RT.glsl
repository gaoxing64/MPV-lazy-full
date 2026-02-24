// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM YX
//!TYPE float
0.0

//!PARAM YY
//!TYPE float
0.0

//!PARAM UX
//!TYPE float
0.0

//!PARAM UY
//!TYPE float
0.0

//!PARAM VX
//!TYPE float
0.0

//!PARAM VY
//!TYPE float
0.0


//!HOOK NATIVE
//!BIND HOOKED
//!DESC [plane_shift_yuv_RT]
//!WHEN YX YY + UX + UY + VX + VY +

vec4 hook() {

	vec2 pos = HOOKED_pos;
	vec2 pixel_size = 1.0 / HOOKED_size;
	vec2 pos_y = vec2(pos.x - YX * pixel_size.x, pos.y - YY * pixel_size.y);
	vec2 pos_u = vec2(pos.x - UX * pixel_size.x, pos.y - UY * pixel_size.y);
	vec2 pos_v = vec2(pos.x - VX * pixel_size.x, pos.y - VY * pixel_size.y);

	bool all_out = true;
	all_out = all_out && !(pos_y.x >= 0.0 && pos_y.x <= 1.0 && pos_y.y >= 0.0 && pos_y.y <= 1.0);
	all_out = all_out && !(pos_u.x >= 0.0 && pos_u.x <= 1.0 && pos_u.y >= 0.0 && pos_u.y <= 1.0);
	all_out = all_out && !(pos_v.x >= 0.0 && pos_v.x <= 1.0 && pos_v.y >= 0.0 && pos_v.y <= 1.0);

	if (all_out) {
		return vec4(0.0, 0.5, 0.5, HOOKED_tex(pos).a);
	}

	float y_val;
	if (pos_y.x >= 0.0 && pos_y.x <= 1.0 && pos_y.y >= 0.0 && pos_y.y <= 1.0) {
		y_val = HOOKED_tex(pos_y).x;
	} else {
		y_val = 0.5; 
	}
	float u_val;
	if (pos_u.x >= 0.0 && pos_u.x <= 1.0 && pos_u.y >= 0.0 && pos_u.y <= 1.0) {
		u_val = HOOKED_tex(pos_u).y;
	} else {
		u_val = 0.5;
	}
	float v_val;
	if (pos_v.x >= 0.0 && pos_v.x <= 1.0 && pos_v.y >= 0.0 && pos_v.y <= 1.0) {
		v_val = HOOKED_tex(pos_v).z;
	} else {
		v_val = 0.5;
	}
	float a_val = HOOKED_tex(pos).a;

	return vec4(y_val, u_val, v_val, a_val);

}

