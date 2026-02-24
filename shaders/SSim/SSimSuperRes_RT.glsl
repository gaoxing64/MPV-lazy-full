// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- PAPER ver.
  https://ece.uwaterloo.ca/~z70wang/research/ssim/
  --- RAW ver.
  https://github.com/zachsaw/MPDN_Extensions/blob/master/LICENSE
  --- igv ver. (upstream)
  https://gist.github.com/igv/2364ffa6e81540f29cb7ab4c9bc05b6b

*/


//!PARAM THR
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.1

//!PARAM DEBUG
//!TYPE DEFINE
//!MINIMUM 0
//!MAXIMUM 1
0


//!HOOK POSTKERNEL
//!BIND HOOKED
//!SAVE LOWRES
//!DESC [SSimSuperRes_RT] Downscaling I
//!HEIGHT PREKERNEL.h
//!WHEN POSTKERNEL.w PREKERNEL.w > POSTKERNEL.h PREKERNEL.h > *
//!COMPONENTS 4

#define axis        1

#define MN(B,C,x)   (x < 1.0 ? ((2.-1.5*B-(C))*x + (-3.+2.*B+C))*x*x + (1.-(B)/3.) : (((-(B)/6.-(C))*x + (B+5.*C))*x + (-2.*B-8.*C))*x+((4./3.)*B+4.*C))
#define Kernel(x)   MN(0.334, 0.333, abs(x))
#define taps        2.0

#define Luma(rgb)   dot(rgb*rgb, vec3(0.2126, 0.7152, 0.0722))

vec4 hook() {
    vec2 base = HOOKED_pos;
    float low  = ceil((base[axis] * HOOKED_size[axis]) - taps - 0.5);
    float high = floor((base[axis] * HOOKED_size[axis]) + taps - 0.5);

    float W = 0.0;
    vec4 avg = vec4(0);
    vec2 pos = base;
    vec4 tex;

    for (float k = low; k <= high; k++) {
        pos[axis] = HOOKED_pt[axis] * (k + 0.5);
        float rel = (pos[axis] - base[axis]) * HOOKED_size[axis];
        float w = Kernel(rel);

        tex.rgb = textureLod(HOOKED_raw, pos, 0.0).rgb * HOOKED_mul;
        tex.a = Luma(tex.rgb);
        avg += w * tex;
        W += w;
    }
    avg /= W;

    return vec4(avg.rgb, max(abs(avg.a - Luma(avg.rgb)), 5e-7));
}

//!HOOK POSTKERNEL
//!BIND LOWRES
//!SAVE LOWRES
//!DESC [SSimSuperRes_RT] Downscaling II
//!WIDTH PREKERNEL.w
//!HEIGHT PREKERNEL.h
//!WHEN POSTKERNEL.w PREKERNEL.w > POSTKERNEL.h PREKERNEL.h > *
//!COMPONENTS 4

#define axis        0

#define MN(B,C,x)   (x < 1.0 ? ((2.-1.5*B-(C))*x + (-3.+2.*B+C))*x*x + (1.-(B)/3.) : (((-(B)/6.-(C))*x + (B+5.*C))*x + (-2.*B-8.*C))*x+((4./3.)*B+4.*C))
#define Kernel(x)   MN(0.334, 0.333, abs(x))
#define taps        2.0

#define Luma(rgb)   dot(rgb*rgb, vec3(0.2126, 0.7152, 0.0722))

vec4 hook() {
    vec2 base = LOWRES_pos;
    float low  = ceil((base[axis] * LOWRES_size[axis]) - taps - 0.5);
    float high = floor((base[axis] * LOWRES_size[axis]) + taps - 0.5);

    float W = 0.0;
    vec4 avg = vec4(0);
    vec2 pos = base;
    vec4 tex;

    for (float k = low; k <= high; k++) {
        pos[axis] = LOWRES_pt[axis] * (k + 0.5);
        float rel = (pos[axis] - base[axis]) * LOWRES_size[axis];
        float w = Kernel(rel);

        tex.rgb = textureLod(LOWRES_raw, pos, 0.0).rgb * LOWRES_mul;
        tex.a = Luma(tex.rgb);
        avg += w * tex;
        W += w;
    }
    avg /= W;

    return vec4(avg.rgb, max(abs(avg.a - Luma(avg.rgb)), 5e-7) + LOWRES_texOff(0).a);
}

//!HOOK POSTKERNEL
//!BIND PREKERNEL
//!BIND LOWRES
//!SAVE var
//!DESC [SSimSuperRes_RT] var
//!WIDTH PREKERNEL.w
//!HEIGHT PREKERNEL.h
//!WHEN POSTKERNEL.w PREKERNEL.w > POSTKERNEL.h PREKERNEL.h > *
//!COMPONENTS 2

#define spread      1.0 / 4.0

#define GetL(x,y)   PREKERNEL_tex(PREKERNEL_pt * (PREKERNEL_pos * input_size + tex_offset + vec2(x,y))).rgb
#define GetH(x,y)   LOWRES_texOff(vec2(x,y)).rgb

#define Luma(rgb)   dot(rgb*rgb, vec3(0.2126, 0.7152, 0.0722))
#define diff(x,y)   vec2(Luma((GetL(x,y) - meanL)), Luma((GetH(x,y) - meanH)))

vec4 hook() {
    vec3 meanL = GetL(0,0);
    vec3 meanH = GetH(0,0);
    for (int X=-1; X<=1; X+=2) {
        meanL += GetL(X,0) * spread;
        meanH += GetH(X,0) * spread;
    }
    for (int Y=-1; Y<=1; Y+=2) {
        meanL += GetL(0,Y) * spread;
        meanH += GetH(0,Y) * spread;
    }
    meanL /= (1.0 + 4.0*spread);
    meanH /= (1.0 + 4.0*spread);

    vec2 var = diff(0,0);
    for (int X=-1; X<=1; X+=2)
        var += diff(X,0) * spread;

    for (int Y=-1; Y<=1; Y+=2)
        var += diff(0,Y) * spread;

    return vec4(max(var / (1.0 + 4.0*spread), vec2(1e-6)), 0, 0);
}

//!HOOK POSTKERNEL
//!BIND HOOKED
//!BIND PREKERNEL
//!BIND LOWRES
//!BIND var
//!DESC [SSimSuperRes_RT] final pass
//!WHEN POSTKERNEL.w PREKERNEL.w > POSTKERNEL.h PREKERNEL.h > *

#define oversharp   THR

// -- Window Size --
#define taps        3.0
#define even        (taps - 2.0 * floor(taps / 2.0) == 0.0)
#define minX        int(1.0-ceil(taps/2.0))
#define maxX        int(floor(taps/2.0))

#define Kernel(x)   cos(acos(-1.0)*(x)/taps) // Hann kernel

// -- Input processing --
#define var(x,y)    var_tex(var_pt * (pos + vec2(x,y) + 0.5)).rg
#define GetL(x,y)   PREKERNEL_tex(PREKERNEL_pt * (pos + tex_offset + vec2(x,y) + 0.5)).rgb
#define GetH(x,y)   LOWRES_tex(LOWRES_pt * (pos + vec2(x,y) + 0.5))

#define Luma(rgb)   dot(rgb*rgb, vec3(0.2126, 0.7152, 0.0722))

vec4 hook() {

#if (DEBUG == 1)
    vec2 pos = (HOOKED_pos - HOOKED_pt/2.0) * LOWRES_size;
    vec2 mVar = vec2(0.0);
    for (int X=-1; X<=1; X++)
    for (int Y=-1; Y<=1; Y++) {
        vec2 w = clamp(1.5 - abs(vec2(X,Y)), 0.0, 1.0);
        mVar += w.r * w.g * vec2(GetH(X,Y).a, 1.0);
    }
    mVar.r /= mVar.g;
    float R = (-1.0 - oversharp) * sqrt(var(0,0).r / (var(0,0).g + mVar.r));
    if (R < -1.0) {
        return vec4(1.0, 0.0, 0.0, 1.0); // RED - SHARPEN
    } else {
        return vec4(0.0, 0.0, 1.0, 1.0); // BLUE - BLUR/NEUTRAL
    }
#elif (DEBUG == 0)

    vec4 c0 = HOOKED_texOff(0);

    vec2 pos = (HOOKED_pos - HOOKED_pt/2.0) * LOWRES_size;
    vec2 offset = pos - (even ? floor(pos) : round(pos));
    pos -= offset;

    vec2 mVar = vec2(0.0);
    for (int X=-1; X<=1; X++)
    for (int Y=-1; Y<=1; Y++) {
        vec2 w = clamp(1.5 - abs(vec2(X,Y)), 0.0, 1.0);
        mVar += w.r * w.g * vec2(GetH(X,Y).a, 1.0);
    }
    mVar.r /= mVar.g;

    // Calculate faithfulness force
    float weightSum = 0.0;
    vec3 diff = vec3(0);

    for (int X = minX; X <= maxX; X++)
    for (int Y = minX; Y <= maxX; Y++)
    {
        float R = (-1.0 - oversharp) * sqrt(var(X,Y).r / (var(X,Y).g + mVar.r));

        vec2 krnl = Kernel(vec2(X,Y) - offset);
        float weight = krnl.r * krnl.g / (Luma((c0.rgb - GetH(X,Y).rgb)) + GetH(X,Y).a);

        diff += weight * (GetL(X,Y) + GetH(X,Y).rgb * R + (-1.0 - R) * (c0.rgb));
        weightSum += weight;
    }
    diff /= weightSum;

    c0.rgb = ((c0.rgb) + diff);
    return c0;

#endif

}

