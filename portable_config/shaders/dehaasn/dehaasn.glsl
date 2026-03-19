// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

// Niklas Haas would absolutely wreck you with his warhammer.

//!DESC [dehaasn] luma
//!HOOK LUMA
//!BIND HOOKED
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w HOOKED.w 1.0 * < OUTPUT.h HOOKED.h 1.0 * < +

vec4 hook() {
	return HOOKED_tex(HOOKED_pos);
}


//!DESC [dehaasn] chroma
//!HOOK CHROMA
//!BIND HOOKED
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w HOOKED.w 1.0 * < OUTPUT.h HOOKED.h 1.0 * < +

vec4 hook() {
	return HOOKED_tex(HOOKED_pos);
}

