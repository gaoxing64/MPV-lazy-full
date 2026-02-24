// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM FLIP
//!TYPE int
//!MINIMUM 0
//!MAXIMUM 3
1


//!HOOK MAINPRESUB
//!BIND HOOKED
//!DESC [flip_RT]
//!WHEN FLIP

vec4 hook() {

	vec2 pos = HOOKED_pos;

	if (FLIP == 1) {
		pos.x = 1.0 - pos.x;
	} else if (FLIP == 2) {
		pos.y = 1.0 - pos.y;
	} else if (FLIP == 3) {
		pos.x = 1.0 - pos.x;
		pos.y = 1.0 - pos.y;
	}

	return HOOKED_tex(pos);

}

