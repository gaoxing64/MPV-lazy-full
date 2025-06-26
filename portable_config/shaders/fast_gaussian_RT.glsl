
// Maximum resolution
//!PARAM res
//!TYPE DEFINE
//!MINIMUM 64
//!MAXIMUM 4096
1024

// Number of blur passes
//!PARAM passes
//!TYPE DEFINE
//!MINIMUM 0
//!MAXIMUM 8
2

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_RT] Iterated downscale pass 1
//!WHEN MAIN.w res > MAIN.h res > + passes 0 > *
//!WIDTH MAIN.w 2 /
//!HEIGHT MAIN.h 2 /
vec4 hook() { return HOOKED_tex(HOOKED_pos); }

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_RT] Iterated downscale pass 2
//!WHEN MAIN.w res > MAIN.h res > + passes 0 > *
//!WIDTH MAIN.w 2 /
//!HEIGHT MAIN.h 2 /
vec4 hook() { return HOOKED_tex(HOOKED_pos); }

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_RT] Iterated downscale pass 3
//!WHEN MAIN.w res > MAIN.h res > + passes 0 > *
//!WIDTH MAIN.w 2 /
//!HEIGHT MAIN.h 2 /
vec4 hook() { return HOOKED_tex(HOOKED_pos); }

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_RT] Iterated downscale pass 4
//!WHEN MAIN.w res > MAIN.h res > + passes 0 > *
//!WIDTH MAIN.w 2 /
//!HEIGHT MAIN.h 2 /
vec4 hook() { return HOOKED_tex(HOOKED_pos); }

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_RT] Iterated downscale pass 5
//!WHEN MAIN.w res > MAIN.h res > + passes 0 > *
//!WIDTH MAIN.w 2 /
//!HEIGHT MAIN.h 2 /
vec4 hook() { return HOOKED_tex(HOOKED_pos); }

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_RT] Iterated downscale pass 6
//!WHEN MAIN.w res > MAIN.h res > + passes 0 > *
//!WIDTH MAIN.w 2 /
//!HEIGHT MAIN.h 2 /
vec4 hook() { return HOOKED_tex(HOOKED_pos); }

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_RT] Iterated downscale pass 7
//!WHEN MAIN.w res > MAIN.h res > + passes 0 > *
//!WIDTH MAIN.w 2 /
//!HEIGHT MAIN.h 2 /
vec4 hook() { return HOOKED_tex(HOOKED_pos); }

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_RT] Iterated downscale pass 8
//!WHEN MAIN.w res > MAIN.h res > + passes 0 > *
//!WIDTH MAIN.w 2 /
//!HEIGHT MAIN.h 2 /
vec4 hook() { return HOOKED_tex(HOOKED_pos); }

//!HOOK MAIN
//!BIND HOOKED
//!DESC [fast_gaussian_RT] Blur horizontal pass 1
//!WHEN passes 0 >
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
//!DESC [fast_gaussian_RT] Blur vertical pass 1
//!WHEN passes 0 >
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
//!DESC [fast_gaussian_RT] Blur horizontal pass 2
//!WHEN passes 1 >
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
//!DESC [fast_gaussian_RT] Blur vertical pass 2
//!WHEN passes 1 >
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
//!DESC [fast_gaussian_RT] Blur horizontal pass 3
//!WHEN passes 2 >
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
//!DESC [fast_gaussian_RT] Blur vertical pass 3
//!WHEN passes 2 >
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
//!DESC [fast_gaussian_RT] Blur horizontal pass 4
//!WHEN passes 3 >
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
//!DESC [fast_gaussian_RT] Blur vertical pass 4
//!WHEN passes 3 >
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
//!DESC [fast_gaussian_RT] Blur horizontal pass 5
//!WHEN passes 4 >
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
//!DESC [fast_gaussian_RT] Blur vertical pass 5
//!WHEN passes 4 >
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
//!DESC [fast_gaussian_RT] Blur horizontal pass 6
//!WHEN passes 5 >
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
//!DESC [fast_gaussian_RT] Blur vertical pass 6
//!WHEN passes 5 >
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
//!DESC [fast_gaussian_RT] Blur horizontal pass 7
//!WHEN passes 6 >
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
//!DESC [fast_gaussian_RT] Blur vertical pass 7
//!WHEN passes 6 >
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
//!DESC [fast_gaussian_RT] Blur horizontal pass 8
//!WHEN passes 7 >
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
//!DESC [fast_gaussian_RT] Blur vertical pass 8
//!WHEN passes 7 >
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

