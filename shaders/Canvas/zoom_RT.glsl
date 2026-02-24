// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM Z
//!TYPE float
//!MINIMUM -100.0
//!MAXIMUM 100.0
0.0


//!HOOK MAINPRESUB
//!BIND HOOKED
//!DESC [zoom_RT]
//!WHEN Z

vec4 hook() {

	float zoom = 0.1 * Z;
	float scale = pow(2.0, zoom);
	vec2 texcoord = HOOKED_pos;
	vec2 center_offset = texcoord - 0.5;
	vec2 scaled_coord = center_offset / scale + 0.5;

	if (scaled_coord.x < 0.0 || scaled_coord.x > 1.0 || 
		scaled_coord.y < 0.0 || scaled_coord.y > 1.0) {
		return vec4(0.0, 0.0, 0.0, 1.0);
	}

	return HOOKED_tex(scaled_coord);

}

