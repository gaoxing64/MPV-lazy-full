// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM REF
//!TYPE int
//!MINIMUM 0
//!MAXIMUM 8
1

//!PARAM MODE
//!TYPE DEFINE
//!MINIMUM 1
//!MAXIMUM 2
1


//!HOOK OUTPUT
//!BIND HOOKED
//!DESC [mirror_RT]
//!WHEN REF

vec4 hook() {

	vec2 pos = HOOKED_pos;

	if (REF == 1) {          // LL
#if (MODE == 1)
		if (pos.x > 0.5) pos.x = 1.0 - pos.x;
#elif (MODE == 2)
		if (pos.x > 0.5) pos.x = pos.x - 0.5;
#endif

	} else if (REF == 2) {   // RR
#if (MODE == 1)
		if (pos.x < 0.5) pos.x = 1.0 - pos.x;
#elif (MODE == 2)
		if (pos.x < 0.5) pos.x = pos.x + 0.5;
#endif

	} else if (REF == 3) {   // TT
#if (MODE == 1)
		if (pos.y > 0.5) pos.y = 1.0 - pos.y;
#elif (MODE == 2)
		if (pos.y > 0.5) pos.y = pos.y - 0.5;
#endif

	} else if (REF == 4) {   // BB
#if (MODE == 1)
		if (pos.y < 0.5) pos.y = 1.0 - pos.y;
#elif (MODE == 2)
		if (pos.y < 0.5) pos.y = pos.y + 0.5;
#endif

	} else if (REF == 5) {     // TL
#if (MODE == 1)
		pos.x = pos.x < 0.5 ? pos.x : 1.0 - pos.x;
		pos.y = pos.y < 0.5 ? pos.y : 1.0 - pos.y;
#elif (MODE == 2)
		if (pos.x > 0.5) pos.x = pos.x - 0.5;
		if (pos.y > 0.5) pos.y = pos.y - 0.5;
#endif

	} else if (REF == 6) {   // TR
#if (MODE == 1)
		pos.x = pos.x > 0.5 ? pos.x : 1.0 - pos.x;
		pos.y = pos.y < 0.5 ? pos.y : 1.0 - pos.y;
#elif (MODE == 2)
		if (pos.x < 0.5) pos.x = pos.x + 0.5;
		if (pos.y > 0.5) pos.y = pos.y - 0.5;
#endif

	} else if (REF == 7) {   // BL
#if (MODE == 1)
		pos.x = pos.x < 0.5 ? pos.x : 1.0 - pos.x;
		pos.y = pos.y > 0.5 ? pos.y : 1.0 - pos.y;
#elif (MODE == 2)
		if (pos.x > 0.5) pos.x = pos.x - 0.5;
		if (pos.y < 0.5) pos.y = pos.y + 0.5;
#endif

	} else if (REF == 8) {   // BR
#if (MODE == 1)
		pos.x = pos.x > 0.5 ? pos.x : 1.0 - pos.x;
		pos.y = pos.y > 0.5 ? pos.y : 1.0 - pos.y;
#elif (MODE == 2)
		if (pos.x < 0.5) pos.x = pos.x + 0.5;
		if (pos.y < 0.5) pos.y = pos.y + 0.5;
#endif
	}

	return HOOKED_tex(pos);

}

