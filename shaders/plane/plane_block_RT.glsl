// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM Y
//!TYPE int
//!MINIMUM 0
//!MAXIMUM 1
1

//!PARAM MODE
//!TYPE int
//!MINIMUM 1
//!MAXIMUM 3
2

//!PARAM U
//!TYPE int
//!MINIMUM 0
//!MAXIMUM 1
1

//!PARAM V
//!TYPE int
//!MINIMUM 0
//!MAXIMUM 1
1


//!HOOK LUMA
//!BIND HOOKED
//!DESC [plane_block_RT] Y -->> black/grey/white
//!WHEN Y 0 ==

vec4 hook() {

	vec4 color = HOOKED_texOff(0.0);

	if (MODE == 1) {
		color.x = 0.0;
	} else if (MODE == 2) {
	color.x = 0.5;
	} else if (MODE == 3) {
	color.x = 1.0;
	}

	return color;

}

//!HOOK CHROMA
//!BIND HOOKED
//!DESC [plane_block_RT] U/V -->> grey
//!WHEN U 0 == V 0 == +

vec4 hook() {

	vec4 color = HOOKED_texOff(0.0);

	if (U == 0) {
	color.x = 0.5;
	}
	if (V == 0) {
	color.y = 0.5;
	}

	return color;

}

