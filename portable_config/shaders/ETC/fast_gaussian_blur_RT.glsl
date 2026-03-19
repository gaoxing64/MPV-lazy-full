// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM RES
//!TYPE int
//!MINIMUM 64
//!MAXIMUM 4096
1024

//!PARAM PSS
//!TYPE int
//!MINIMUM 0
//!MAXIMUM 8
2


//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_blur_RT] Iterated downscale pass 1
//!WHEN MAIN.w RES > MAIN.h RES > + PSS *
//!WIDTH MAIN.w 2 /
//!HEIGHT MAIN.h 2 /
vec4 hook() { return HOOKED_tex(HOOKED_pos); }

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_blur_RT] Iterated downscale pass 2
//!WHEN MAIN.w RES > MAIN.h RES > + PSS *
//!WIDTH MAIN.w 2 /
//!HEIGHT MAIN.h 2 /
vec4 hook() { return HOOKED_tex(HOOKED_pos); }

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_blur_RT] Iterated downscale pass 3
//!WHEN MAIN.w RES > MAIN.h RES > + PSS *
//!WIDTH MAIN.w 2 /
//!HEIGHT MAIN.h 2 /
vec4 hook() { return HOOKED_tex(HOOKED_pos); }

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_blur_RT] Iterated downscale pass 4
//!WHEN MAIN.w RES > MAIN.h RES > + PSS *
//!WIDTH MAIN.w 2 /
//!HEIGHT MAIN.h 2 /
vec4 hook() { return HOOKED_tex(HOOKED_pos); }

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_blur_RT] Iterated downscale pass 5
//!WHEN MAIN.w RES > MAIN.h RES > + PSS *
//!WIDTH MAIN.w 2 /
//!HEIGHT MAIN.h 2 /
vec4 hook() { return HOOKED_tex(HOOKED_pos); }

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_blur_RT] Iterated downscale pass 6
//!WHEN MAIN.w RES > MAIN.h RES > + PSS *
//!WIDTH MAIN.w 2 /
//!HEIGHT MAIN.h 2 /
vec4 hook() { return HOOKED_tex(HOOKED_pos); }

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_blur_RT] Iterated downscale pass 7
//!WHEN MAIN.w RES > MAIN.h RES > + PSS *
//!WIDTH MAIN.w 2 /
//!HEIGHT MAIN.h 2 /
vec4 hook() { return HOOKED_tex(HOOKED_pos); }

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_blur_RT] Iterated downscale pass 8
//!WHEN MAIN.w RES > MAIN.h RES > + PSS *
//!WIDTH MAIN.w 2 /
//!HEIGHT MAIN.h 2 /
vec4 hook() { return HOOKED_tex(HOOKED_pos); }

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_blur_RT] Blur horizontal pass 1
//!WHEN PSS 0 >
#define DIR vec2(1.0, 0.0)
vec4 hook()
{
	return 1.96482550e-1 * HOOKED_tex(HOOKED_pos) +
			2.96906965e-1 * HOOKED_texOff( 1.41176471 * DIR) +
			2.96906965e-1 * HOOKED_texOff(-1.41176471 * DIR) +
			9.44703979e-2 * HOOKED_texOff( 3.29411765 * DIR) +
			9.44703979e-2 * HOOKED_texOff(-3.29411765 * DIR) +
			1.03813624e-2 * HOOKED_texOff( 5.17647059 * DIR) +
			1.03813624e-2 * HOOKED_texOff(-5.17647059 * DIR);
}

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_blur_RT] Blur vertical pass 1
//!WHEN PSS 0 >
#define DIR vec2(0.0, 1.0)
vec4 hook()
{
	return 1.96482550e-1 * HOOKED_tex(HOOKED_pos) +
			2.96906965e-1 * HOOKED_texOff( 1.41176471 * DIR) +
			2.96906965e-1 * HOOKED_texOff(-1.41176471 * DIR) +
			9.44703979e-2 * HOOKED_texOff( 3.29411765 * DIR) +
			9.44703979e-2 * HOOKED_texOff(-3.29411765 * DIR) +
			1.03813624e-2 * HOOKED_texOff( 5.17647059 * DIR) +
			1.03813624e-2 * HOOKED_texOff(-5.17647059 * DIR);
}

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_blur_RT] Blur horizontal pass 2
//!WHEN PSS 1 >
#define DIR vec2(1.0, 0.0)
vec4 hook()
{
	return 1.96482550e-1 * HOOKED_tex(HOOKED_pos) +
			2.96906965e-1 * HOOKED_texOff( 1.41176471 * DIR) +
			2.96906965e-1 * HOOKED_texOff(-1.41176471 * DIR) +
			9.44703979e-2 * HOOKED_texOff( 3.29411765 * DIR) +
			9.44703979e-2 * HOOKED_texOff(-3.29411765 * DIR) +
			1.03813624e-2 * HOOKED_texOff( 5.17647059 * DIR) +
			1.03813624e-2 * HOOKED_texOff(-5.17647059 * DIR);
}

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_blur_RT] Blur vertical pass 2
//!WHEN PSS 1 >
#define DIR vec2(0.0, 1.0)
vec4 hook()
{
	return 1.96482550e-1 * HOOKED_tex(HOOKED_pos) +
			2.96906965e-1 * HOOKED_texOff( 1.41176471 * DIR) +
			2.96906965e-1 * HOOKED_texOff(-1.41176471 * DIR) +
			9.44703979e-2 * HOOKED_texOff( 3.29411765 * DIR) +
			9.44703979e-2 * HOOKED_texOff(-3.29411765 * DIR) +
			1.03813624e-2 * HOOKED_texOff( 5.17647059 * DIR) +
			1.03813624e-2 * HOOKED_texOff(-5.17647059 * DIR);
}

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_blur_RT] Blur horizontal pass 3
//!WHEN PSS 2 >
#define DIR vec2(1.0, 0.0)
vec4 hook()
{
	return 1.96482550e-1 * HOOKED_tex(HOOKED_pos) +
			2.96906965e-1 * HOOKED_texOff( 1.41176471 * DIR) +
			2.96906965e-1 * HOOKED_texOff(-1.41176471 * DIR) +
			9.44703979e-2 * HOOKED_texOff( 3.29411765 * DIR) +
			9.44703979e-2 * HOOKED_texOff(-3.29411765 * DIR) +
			1.03813624e-2 * HOOKED_texOff( 5.17647059 * DIR) +
			1.03813624e-2 * HOOKED_texOff(-5.17647059 * DIR);
}

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_blur_RT] Blur vertical pass 3
//!WHEN PSS 2 >
#define DIR vec2(0.0, 1.0)
vec4 hook()
{
	return 1.96482550e-1 * HOOKED_tex(HOOKED_pos) +
			2.96906965e-1 * HOOKED_texOff( 1.41176471 * DIR) +
			2.96906965e-1 * HOOKED_texOff(-1.41176471 * DIR) +
			9.44703979e-2 * HOOKED_texOff( 3.29411765 * DIR) +
			9.44703979e-2 * HOOKED_texOff(-3.29411765 * DIR) +
			1.03813624e-2 * HOOKED_texOff( 5.17647059 * DIR) +
			1.03813624e-2 * HOOKED_texOff(-5.17647059 * DIR);
}

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_blur_RT] Blur horizontal pass 4
//!WHEN PSS 3 >
#define DIR vec2(1.0, 0.0)
vec4 hook()
{
	return 1.96482550e-1 * HOOKED_tex(HOOKED_pos) +
			2.96906965e-1 * HOOKED_texOff( 1.41176471 * DIR) +
			2.96906965e-1 * HOOKED_texOff(-1.41176471 * DIR) +
			9.44703979e-2 * HOOKED_texOff( 3.29411765 * DIR) +
			9.44703979e-2 * HOOKED_texOff(-3.29411765 * DIR) +
			1.03813624e-2 * HOOKED_texOff( 5.17647059 * DIR) +
			1.03813624e-2 * HOOKED_texOff(-5.17647059 * DIR);
}

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_blur_RT] Blur vertical pass 4
//!WHEN PSS 3 >
#define DIR vec2(0.0, 1.0)
vec4 hook()
{
	return 1.96482550e-1 * HOOKED_tex(HOOKED_pos) +
			2.96906965e-1 * HOOKED_texOff( 1.41176471 * DIR) +
			2.96906965e-1 * HOOKED_texOff(-1.41176471 * DIR) +
			9.44703979e-2 * HOOKED_texOff( 3.29411765 * DIR) +
			9.44703979e-2 * HOOKED_texOff(-3.29411765 * DIR) +
			1.03813624e-2 * HOOKED_texOff( 5.17647059 * DIR) +
			1.03813624e-2 * HOOKED_texOff(-5.17647059 * DIR);
}

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_blur_RT] Blur horizontal pass 5
//!WHEN PSS 4 >
#define DIR vec2(1.0, 0.0)
vec4 hook()
{
	return 1.96482550e-1 * HOOKED_tex(HOOKED_pos) +
			2.96906965e-1 * HOOKED_texOff( 1.41176471 * DIR) +
			2.96906965e-1 * HOOKED_texOff(-1.41176471 * DIR) +
			9.44703979e-2 * HOOKED_texOff( 3.29411765 * DIR) +
			9.44703979e-2 * HOOKED_texOff(-3.29411765 * DIR) +
			1.03813624e-2 * HOOKED_texOff( 5.17647059 * DIR) +
			1.03813624e-2 * HOOKED_texOff(-5.17647059 * DIR);
}

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_blur_RT] Blur vertical pass 5
//!WHEN PSS 4 >
#define DIR vec2(0.0, 1.0)
vec4 hook()
{
	return 1.96482550e-1 * HOOKED_tex(HOOKED_pos) +
			2.96906965e-1 * HOOKED_texOff( 1.41176471 * DIR) +
			2.96906965e-1 * HOOKED_texOff(-1.41176471 * DIR) +
			9.44703979e-2 * HOOKED_texOff( 3.29411765 * DIR) +
			9.44703979e-2 * HOOKED_texOff(-3.29411765 * DIR) +
			1.03813624e-2 * HOOKED_texOff( 5.17647059 * DIR) +
			1.03813624e-2 * HOOKED_texOff(-5.17647059 * DIR);
}

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_blur_RT] Blur horizontal pass 6
//!WHEN PSS 5 >
#define DIR vec2(1.0, 0.0)
vec4 hook()
{
	return 1.96482550e-1 * HOOKED_tex(HOOKED_pos) +
			2.96906965e-1 * HOOKED_texOff( 1.41176471 * DIR) +
			2.96906965e-1 * HOOKED_texOff(-1.41176471 * DIR) +
			9.44703979e-2 * HOOKED_texOff( 3.29411765 * DIR) +
			9.44703979e-2 * HOOKED_texOff(-3.29411765 * DIR) +
			1.03813624e-2 * HOOKED_texOff( 5.17647059 * DIR) +
			1.03813624e-2 * HOOKED_texOff(-5.17647059 * DIR);
}

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_blur_RT] Blur vertical pass 6
//!WHEN PSS 5 >
#define DIR vec2(0.0, 1.0)
vec4 hook()
{
	return 1.96482550e-1 * HOOKED_tex(HOOKED_pos) +
			2.96906965e-1 * HOOKED_texOff( 1.41176471 * DIR) +
			2.96906965e-1 * HOOKED_texOff(-1.41176471 * DIR) +
			9.44703979e-2 * HOOKED_texOff( 3.29411765 * DIR) +
			9.44703979e-2 * HOOKED_texOff(-3.29411765 * DIR) +
			1.03813624e-2 * HOOKED_texOff( 5.17647059 * DIR) +
			1.03813624e-2 * HOOKED_texOff(-5.17647059 * DIR);
}

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_blur_RT] Blur horizontal pass 7
//!WHEN PSS 6 >
#define DIR vec2(1.0, 0.0)
vec4 hook()
{
	return 1.96482550e-1 * HOOKED_tex(HOOKED_pos) +
			2.96906965e-1 * HOOKED_texOff( 1.41176471 * DIR) +
			2.96906965e-1 * HOOKED_texOff(-1.41176471 * DIR) +
			9.44703979e-2 * HOOKED_texOff( 3.29411765 * DIR) +
			9.44703979e-2 * HOOKED_texOff(-3.29411765 * DIR) +
			1.03813624e-2 * HOOKED_texOff( 5.17647059 * DIR) +
			1.03813624e-2 * HOOKED_texOff(-5.17647059 * DIR);
}

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_blur_RT] Blur vertical pass 7
//!WHEN PSS 6 >
#define DIR vec2(0.0, 1.0)
vec4 hook()
{
	return 1.96482550e-1 * HOOKED_tex(HOOKED_pos) +
			2.96906965e-1 * HOOKED_texOff( 1.41176471 * DIR) +
			2.96906965e-1 * HOOKED_texOff(-1.41176471 * DIR) +
			9.44703979e-2 * HOOKED_texOff( 3.29411765 * DIR) +
			9.44703979e-2 * HOOKED_texOff(-3.29411765 * DIR) +
			1.03813624e-2 * HOOKED_texOff( 5.17647059 * DIR) +
			1.03813624e-2 * HOOKED_texOff(-5.17647059 * DIR);
}

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_blur_RT] Blur horizontal pass 8
//!WHEN PSS 7 >
#define DIR vec2(1.0, 0.0)
vec4 hook()
{
	return 1.96482550e-1 * HOOKED_tex(HOOKED_pos) +
			2.96906965e-1 * HOOKED_texOff( 1.41176471 * DIR) +
			2.96906965e-1 * HOOKED_texOff(-1.41176471 * DIR) +
			9.44703979e-2 * HOOKED_texOff( 3.29411765 * DIR) +
			9.44703979e-2 * HOOKED_texOff(-3.29411765 * DIR) +
			1.03813624e-2 * HOOKED_texOff( 5.17647059 * DIR) +
			1.03813624e-2 * HOOKED_texOff(-5.17647059 * DIR);
}

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_blur_RT] Blur vertical pass 8
//!WHEN PSS 7 >
#define DIR vec2(0.0, 1.0)
vec4 hook()
{
	return 1.96482550e-1 * HOOKED_tex(HOOKED_pos) +
			2.96906965e-1 * HOOKED_texOff( 1.41176471 * DIR) +
			2.96906965e-1 * HOOKED_texOff(-1.41176471 * DIR) +
			9.44703979e-2 * HOOKED_texOff( 3.29411765 * DIR) +
			9.44703979e-2 * HOOKED_texOff(-3.29411765 * DIR) +
			1.03813624e-2 * HOOKED_texOff( 5.17647059 * DIR) +
			1.03813624e-2 * HOOKED_texOff(-5.17647059 * DIR);
}

