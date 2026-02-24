// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM X
//!TYPE float
//!MINIMUM -100.0
//!MAXIMUM 100.0
0.0

//!PARAM Y
//!TYPE float
//!MINIMUM -100.0
//!MAXIMUM 100.0
0.0


//!HOOK MAINPRESUB
//!BIND HOOKED
//!DESC [pan_RT]
//!WHEN X Y +

vec4 hook()
{

	float width = HOOKED_size.x;
	float height = HOOKED_size.y;
	vec2 texcoord = HOOKED_pos * HOOKED_size;

	float offset_x_pct = 0.01 * X;
	float offset_y_pct = 0.01 * Y;
	vec2 offset = HOOKED_size * vec2(offset_x_pct, offset_y_pct);
	vec2 abs_offset = abs(offset);

	if (X > 0.0) {
		if (texcoord.x < abs_offset.x) return vec4(0.0);
	} else if (X < 0.0) {
		if (texcoord.x > width - abs_offset.x) return vec4(0.0);
	}

	if (Y > 0.0) {
		if (texcoord.y < abs_offset.y) return vec4(0.0);
	} else if (Y < 0.0 ) {
		if (texcoord.y > height - abs_offset.y) return vec4(0.0);
	}

	vec2 direction = vec2(0.0);
	if (X > 0.0) direction.x = -1.0;
	else if (X < 0.0) direction.x = 1.0;

	if (Y > 0.0) direction.y = -1.0;
	else if (Y < 0.0) direction.y = 1.0;

	return HOOKED_texOff(direction * abs_offset);

}

