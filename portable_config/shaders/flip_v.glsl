
//!DESC [flip_v]
//!HOOK MAINPRESUB
//!BIND HOOKED

vec4 hook() {

	vec2 pos = HOOKED_pos;
	pos.y = 1.0 - pos.y;

	return HOOKED_tex(pos);

}

