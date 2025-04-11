
//!DESC [rotate_180] pass01
//!HOOK MAINPRESUB
//!BIND HOOKED
//!SAVE TEX01

vec4 hook() {

	vec2 pos = HOOKED_pos;
	pos.x = 1.0 - pos.x;

	return HOOKED_tex(pos);

}


//!DESC [rotate_180] pass02
//!HOOK MAINPRESUB
//!BIND TEX01

vec4 hook() {

	vec2 pos = TEX01_pos;
	pos.y = 1.0 - pos.y;

	return TEX01_tex(pos);

}

