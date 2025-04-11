/*
Source: igv_faux-HDR
*/

//!HOOK MAIN
//!BIND HOOKED
//!BIND LUMA
//!DESC [fake_hdr]

#define saturation                      0.9   // 1.0
#define gamma                           1.1   // 1.0 // 1.3

#define Soft

#define GammaCorrection(color, gamma)   pow(color, 1.0 / vec3(gamma))

//#define BlendOverlay(base, blend)       mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), step(0.5, base))

#define BlendLinearLight(base, blend)   mix(max(base + 2.0 * blend - 1.0, 0.0), min(base + 2.0 * (blend - 0.5), 1.0), step(0.5, blend))

#define BlendSoftLight(base, blend)     mix(2.0 * base * blend + base * base * (1.0 - 2.0 * blend), sqrt(base) * (2.0 * blend - 1.0) + 2.0 * base * (1.0 - blend), step(0.5, blend))

vec4 hook() {
    /*vec2 dir = vec2(0.0, 1.0);
    float avg  = 0.0;
    float coefficientSum = 0.0;
    float numBlurPixelsPerSide = 200.0/2.0;
    float sigma = 40.0;
    vec3 incrementalGaussian;
    incrementalGaussian.x = 1.0 / (sqrt(2.0 * acos(-1.0)) * sigma);
    incrementalGaussian.y = exp(-0.5 / (sigma * sigma));
    incrementalGaussian.z = incrementalGaussian.y * incrementalGaussian.y;
    avg += BW_tex(BW_pos).x * incrementalGaussian.x;
    coefficientSum += incrementalGaussian.x;
    incrementalGaussian.xy *= incrementalGaussian.yz;
    for (float i = 1.0; i <= numBlurPixelsPerSide; i++) {
        avg += BW_texOff(-i * dir).x * incrementalGaussian.x;
        avg += BW_texOff( i * dir).x * incrementalGaussian.x;
        coefficientSum += 2.0 * incrementalGaussian.x;
        incrementalGaussian.xy *= incrementalGaussian.yz;
    }*/

    vec4 o = HOOKED_texOff(vec2(0.0, 0.0));
    /*float y = LUMA_tex(LUMA_pos).x;
    float bw = avg / coefficientSum;
    vec3 obw = vec3(BlendOverlay(y, bw));
    obw = mix(o.rgb, obw, smoothstep(y, 1.0, 1.0 - y - bw));
    obw = mix(o.rgb, obw, 1.0 - smoothstep(0.0, y, bw - (1.0 - y)));*/

    vec3 obw = GammaCorrection(o.rgb, gamma);
    obw = mix(vec3(dot(obw, vec3(0.2125, 0.7154, 0.0721))), obw, saturation);

    #ifdef Soft
    o.xyz = mix(BlendSoftLight(obw, o.xyz), obw, 0.15);
    #else
    o.xyz = mix(BlendLinearLight(obw, o.xyz), obw, 0.55);
    #endif

    return o;
}

