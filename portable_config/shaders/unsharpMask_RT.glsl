
//!PARAM BLUR
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 10.0
1.0

//!PARAM RAD
//!TYPE int
//!MINIMUM 1
//!MAXIMUM 10
2

//!PARAM SHARP
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 10.0
0.5

//!PARAM THR
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 10.0
0.0

//!HOOK MAIN
//!BIND HOOKED
//!SAVE PASS0
//!DESC [unsharpMask_RT] pass1

vec4 hook() {
    return linearize(textureLod(HOOKED_raw, HOOKED_pos, 0.0) * HOOKED_mul);
}

//!HOOK MAIN
//!BIND PASS0
//!SAVE PASS1
//!DESC [unsharpMask_RT] pass2

////////////////////////////////////////////////////////////////////////
// USER CONFIGURABLE, PASS 2 (blur in y axis)
//
// CAUTION! probably should use the same settings for "USER CONFIGURABLE, PASS 3" below
//
#define SIGMA    BLUR   //blur spread or amount, (0.0, 10+]
#define RADIUS   RAD    //kernel radius (integer as float, e.g. 3.0), (0.0, 10+]
//
////////////////////////////////////////////////////////////////////////

#define get_weight(x) (exp(-(x) * (x) / (2.0 * SIGMA * SIGMA)))

vec4 hook() {
    float weight;
    vec4 csum = textureLod(PASS0_raw, PASS0_pos, 0.0) * PASS0_mul;
    float wsum = 1.0;
    for(float i = 1.0; i <= RADIUS; ++i) {
        weight = get_weight(i);
        csum += (textureLod(PASS0_raw, PASS0_pos + PASS0_pt * vec2(0.0, -i), 0.0) + textureLod(PASS0_raw, PASS0_pos + PASS0_pt * vec2(0.0, i), 0.0)) * PASS0_mul * weight;
        wsum += 2.0 * weight;
    }
    return csum / wsum;
}

//!HOOK MAIN
//!BIND PASS0
//!BIND PASS1
//!DESC [unsharpMask_RT] pass3

////////////////////////////////////////////////////////////////////////
// USER CONFIGURABLE, PASS 3 (blur in x axis and aply unsharp mask)
//
// CAUTION! probably should use the same settings for "USER CONFIGURABLE, PASS 2" above
//
#define SIGMA       BLUR    //blur spread or amount, (0.0, 10+]
#define RADIUS      RAD     //kernel radius (integer as float, e.g. 3.0), (0.0, 10+]
//
//sharpnes
#define AMOUNT      SHARP   //amount of sharpening [0.0, 10+]
#define THRESHOLD   THR     //sets the minimum contrast for sharpening (e.g. 0.1), [0.0, 1.0]
//
////////////////////////////////////////////////////////////////////////

#define get_weight(x) (exp(-(x) * (x) / (2.0 * SIGMA * SIGMA)))

vec4 hook() {
    float weight;
    vec4 csum = textureLod(PASS1_raw, PASS1_pos, 0.0) * PASS1_mul;
    float wsum = 1.0;
    for(float i = 1.0; i <= RADIUS; ++i) {
        weight = get_weight(i);
        csum += (textureLod(PASS1_raw, PASS1_pos + PASS1_pt * vec2(-i, 0.0), 0.0) + textureLod(PASS1_raw, PASS1_pos + PASS1_pt * vec2(i, 0.0), 0.0)) * PASS1_mul * weight;
        wsum += 2.0 * weight;
    }
    vec4 original = textureLod(PASS0_raw, PASS0_pos, 0.0) * PASS0_mul;
    vec4 mask = original - csum / wsum;
    if (abs(mask.r) > THRESHOLD || abs(mask.g) > THRESHOLD || abs(mask.b) > THRESHOLD)
        return delinearize(original + mask * AMOUNT);
    return delinearize(original);
}

