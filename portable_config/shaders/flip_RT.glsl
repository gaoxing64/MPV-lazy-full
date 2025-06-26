
//!PARAM FLIP
//!TYPE DEFINE
//!DESC int
//!MINIMUM 0
//!MAXIMUM 3
1


//!DESC [flip_RT] flip horz/vert/both
//!HOOK MAINPRESUB
//!BIND HOOKED
//!WHEN FLIP 0 >

vec4 hook() {

	vec2 pos = HOOKED_pos;

#if (FLIP == 1)
	pos.x = 1.0 - pos.x;
#elif (FLIP == 2)
	pos.y = 1.0 - pos.y;
#elif (FLIP == 3)
	pos.x = 1.0 - pos.x;
	pos.y = 1.0 - pos.y;
#endif

	return HOOKED_tex(pos);

}

