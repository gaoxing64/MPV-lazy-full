
//!PARAM bY
//!TYPE int
//!MINIMUM 0
//!MAXIMUM 1
0

//!PARAM bY_mode
//!DESC int
//!TYPE DEFINE
//!MINIMUM 1
//!MAXIMUM 3
1

//!PARAM bU
//!DESC int
//!TYPE DEFINE
//!MINIMUM 0
//!MAXIMUM 1
0

//!PARAM bV
//!DESC int
//!TYPE DEFINE
//!MINIMUM 0
//!MAXIMUM 1
0

//!HOOK LUMA
//!BIND HOOKED
//!DESC [plane_block_RT] Y -->> black/grey/white
//!WHEN bY 0 >

vec4 hook() {
	vec4 color = HOOKED_texOff(0.0);
#if (bY_mode == 1)
	color.x = 0.0;
#elif (bY_mode == 2)
	color.x = 0.5;
#elif (bY_mode == 3)
	color.x = 1.0;
#endif
	return color;
}

//!HOOK CHROMA
//!BIND HOOKED
//!DESC [plane_block_RT] U/V -->> grey
//!WHEN bU 0 > bV 0 > +

vec4 hook() {
	vec4 color = HOOKED_texOff(0.0);
#if (bU == 1)
	color.x = 0.5;
#endif
#if (bV == 1)
	color.y = 0.5;
#endif
	return color;
}

