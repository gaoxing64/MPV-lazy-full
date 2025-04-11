
//!DESC [flip_h]
//!HOOK MAINPRESUB
//!BIND HOOKED

vec4 hook() {

	vec2 pos = HOOKED_pos;
	pos.x = 1.0 - pos.x;

	return HOOKED_tex(pos);

}

