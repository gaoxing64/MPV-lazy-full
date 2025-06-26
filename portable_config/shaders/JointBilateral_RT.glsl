// MIT License

// Copyright (c) 2023 João Chrisóstomo

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

//!PARAM chroma_offset_x
//!TYPE float
0.0

//!PARAM chroma_offset_y
//!TYPE float
0.0

//!HOOK CHROMA
//!BIND LUMA
//!BIND CHROMA
//!SAVE LUMA_LR
//!WIDTH CHROMA.w
//!HEIGHT LUMA.h
//!WHEN CHROMA.w LUMA.w <
//!DESC [JointBilateral_RT] (Hermite 1st step, Downscaling Luma)

float comp_wd(vec2 v) {
    float x = min(length(v), 1.0);
    return smoothstep(0.0, 1.0, 1.0 - x);
}

vec4 hook() {
    vec2 luma_pos = LUMA_pos;
    luma_pos.x += chroma_offset_x / LUMA_size.x;
    float start  = ceil((luma_pos.x - (1.0 / CHROMA_size.x)) * LUMA_size.x - 0.5);
    float end = floor((luma_pos.x + (1.0 / CHROMA_size.x)) * LUMA_size.x - 0.5);

    float wt = 0.0;
    float luma_sum = 0.0;
    vec2 pos = luma_pos;

    for (float dx = start.x; dx <= end.x; dx++) {
        pos.x = LUMA_pt.x * (dx + 0.5);
        vec2 dist = (pos - luma_pos) * CHROMA_size;
        float wd = comp_wd(dist);
        float luma_pix = LUMA_tex(pos).x;
        luma_sum += wd * luma_pix;
        wt += wd;
    }

    vec4 output_pix = vec4(luma_sum /= wt, 0.0, 0.0, 1.0);
    return clamp(output_pix, 0.0, 1.0);
}

//!HOOK CHROMA
//!BIND LUMA_LR
//!BIND CHROMA
//!BIND LUMA
//!SAVE LUMA_LR
//!WIDTH CHROMA.w
//!HEIGHT CHROMA.h
//!WHEN CHROMA.w LUMA.w <
//!DESC [JointBilateral_RT] (Hermite 2nd step, Downscaling Luma)

float comp_wd(vec2 v) {
    float x = min(length(v), 1.0);
    return smoothstep(0.0, 1.0, 1.0 - x);
}

vec4 hook() {
    vec2 luma_pos = LUMA_LR_pos;
    luma_pos.y += chroma_offset_y / LUMA_LR_size.y;
    float start  = ceil((luma_pos.y - (1.0 / CHROMA_size.y)) * LUMA_LR_size.y - 0.5);
    float end = floor((luma_pos.y + (1.0 / CHROMA_size.y)) * LUMA_LR_size.y - 0.5);

    float wt = 0.0;
    float luma_sum = 0.0;
    vec2 pos = luma_pos;

    for (float dy = start; dy <= end; dy++) {
        pos.y = LUMA_LR_pt.y * (dy + 0.5);
        vec2 dist = (pos - luma_pos) * CHROMA_size;
        float wd = comp_wd(dist);
        float luma_pix = LUMA_LR_tex(pos).x;
        luma_sum += wd * luma_pix;
        wt += wd;
    }

    vec4 output_pix = vec4(luma_sum /= wt, 0.0, 0.0, 1.0);
    return clamp(output_pix, 0.0, 1.0);
}

//!PARAM distance_coeff
//!TYPE float
//!MINIMUM 0.0
2.0

//!PARAM intensity_coeff
//!TYPE float
//!MINIMUM 0.0
128.0

//!HOOK CHROMA
//!BIND LUMA
//!BIND LUMA_LR
//!BIND HOOKED
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!WHEN CHROMA.w LUMA.w <
//!OFFSET ALIGN
//!DESC [JointBilateral_RT] (Upscaling Chroma)

float comp_w(vec2 spatial_distance, float intensity_distance) {
    return max(100.0 * exp(-distance_coeff * pow(length(spatial_distance), 2.0) - intensity_coeff * pow(intensity_distance, 2.0)), 1e-32);
}

vec4 hook() {
    float luma_zero = LUMA_texOff(0.0).x;
    vec4 output_pix = vec4(0.0, 0.0, 0.0, 1.0);

    vec2 pp = HOOKED_pos * HOOKED_size - vec2(0.5);
    vec2 fp = floor(pp);
    pp -= fp;

#ifdef HOOKED_gather
    vec4 chroma_quads[4][2];
    chroma_quads[0][0] = HOOKED_gather(vec2((fp + vec2(0.0, 0.0)) * HOOKED_pt), 0);
    chroma_quads[1][0] = HOOKED_gather(vec2((fp + vec2(2.0, 0.0)) * HOOKED_pt), 0);
    chroma_quads[2][0] = HOOKED_gather(vec2((fp + vec2(0.0, 2.0)) * HOOKED_pt), 0);
    chroma_quads[3][0] = HOOKED_gather(vec2((fp + vec2(2.0, 2.0)) * HOOKED_pt), 0);
    chroma_quads[0][1] = HOOKED_gather(vec2((fp + vec2(0.0, 0.0)) * HOOKED_pt), 1);
    chroma_quads[1][1] = HOOKED_gather(vec2((fp + vec2(2.0, 0.0)) * HOOKED_pt), 1);
    chroma_quads[2][1] = HOOKED_gather(vec2((fp + vec2(0.0, 2.0)) * HOOKED_pt), 1);
    chroma_quads[3][1] = HOOKED_gather(vec2((fp + vec2(2.0, 2.0)) * HOOKED_pt), 1);

    vec2 chroma_pixels[12];
    chroma_pixels[0]  = vec2(chroma_quads[0][0].z, chroma_quads[0][1].z);
    chroma_pixels[1]  = vec2(chroma_quads[1][0].w, chroma_quads[1][1].w);
    chroma_pixels[2]  = vec2(chroma_quads[0][0].x, chroma_quads[0][1].x);
    chroma_pixels[3]  = vec2(chroma_quads[0][0].y, chroma_quads[0][1].y);
    chroma_pixels[4]  = vec2(chroma_quads[1][0].x, chroma_quads[1][1].x);
    chroma_pixels[5]  = vec2(chroma_quads[1][0].y, chroma_quads[1][1].y);
    chroma_pixels[6]  = vec2(chroma_quads[2][0].w, chroma_quads[2][1].w);
    chroma_pixels[7]  = vec2(chroma_quads[2][0].z, chroma_quads[2][1].z);
    chroma_pixels[8]  = vec2(chroma_quads[3][0].w, chroma_quads[3][1].w);
    chroma_pixels[9]  = vec2(chroma_quads[3][0].z, chroma_quads[3][1].z);
    chroma_pixels[10] = vec2(chroma_quads[2][0].y, chroma_quads[2][1].y);
    chroma_pixels[11] = vec2(chroma_quads[3][0].x, chroma_quads[3][1].x);

    vec4 luma_quads[4];
    luma_quads[0] = LUMA_LR_gather(vec2((fp + vec2(0.0, 0.0)) * HOOKED_pt), 0);
    luma_quads[1] = LUMA_LR_gather(vec2((fp + vec2(2.0, 0.0)) * HOOKED_pt), 0);
    luma_quads[2] = LUMA_LR_gather(vec2((fp + vec2(0.0, 2.0)) * HOOKED_pt), 0);
    luma_quads[3] = LUMA_LR_gather(vec2((fp + vec2(2.0, 2.0)) * HOOKED_pt), 0);

    float luma_pixels[12];
    luma_pixels[0]  = luma_quads[0].z;
    luma_pixels[1]  = luma_quads[1].w;
    luma_pixels[2]  = luma_quads[0].x;
    luma_pixels[3]  = luma_quads[0].y;
    luma_pixels[4]  = luma_quads[1].x;
    luma_pixels[5]  = luma_quads[1].y;
    luma_pixels[6]  = luma_quads[2].w;
    luma_pixels[7]  = luma_quads[2].z;
    luma_pixels[8]  = luma_quads[3].w;
    luma_pixels[9]  = luma_quads[3].z;
    luma_pixels[10] = luma_quads[2].y;
    luma_pixels[11] = luma_quads[3].x;
#else
    vec2 chroma_pixels[12];
    chroma_pixels[0]  = HOOKED_tex(vec2((fp + vec2(0.5, -0.5)) * HOOKED_pt)).xy;
    chroma_pixels[1]  = HOOKED_tex(vec2((fp + vec2(1.5, -0.5)) * HOOKED_pt)).xy;
    chroma_pixels[2]  = HOOKED_tex(vec2((fp + vec2(-0.5, 0.5)) * HOOKED_pt)).xy;
    chroma_pixels[3]  = HOOKED_tex(vec2((fp + vec2( 0.5, 0.5)) * HOOKED_pt)).xy;
    chroma_pixels[4]  = HOOKED_tex(vec2((fp + vec2( 1.5, 0.5)) * HOOKED_pt)).xy;
    chroma_pixels[5]  = HOOKED_tex(vec2((fp + vec2( 2.5, 0.5)) * HOOKED_pt)).xy;
    chroma_pixels[6]  = HOOKED_tex(vec2((fp + vec2(-0.5, 1.5)) * HOOKED_pt)).xy;
    chroma_pixels[7]  = HOOKED_tex(vec2((fp + vec2( 0.5, 1.5)) * HOOKED_pt)).xy;
    chroma_pixels[8]  = HOOKED_tex(vec2((fp + vec2( 1.5, 1.5)) * HOOKED_pt)).xy;
    chroma_pixels[9]  = HOOKED_tex(vec2((fp + vec2( 2.5, 1.5)) * HOOKED_pt)).xy;
    chroma_pixels[10] = HOOKED_tex(vec2((fp + vec2( 0.5, 2.5)) * HOOKED_pt)).xy;
    chroma_pixels[11] = HOOKED_tex(vec2((fp + vec2( 1.5, 2.5)) * HOOKED_pt)).xy;

    float luma_pixels[12];
    luma_pixels[0]  = LUMA_LR_tex(vec2((fp + vec2(0.5, -0.5)) * HOOKED_pt)).x;
    luma_pixels[1]  = LUMA_LR_tex(vec2((fp + vec2(1.5, -0.5)) * HOOKED_pt)).x;
    luma_pixels[2]  = LUMA_LR_tex(vec2((fp + vec2(-0.5, 0.5)) * HOOKED_pt)).x;
    luma_pixels[3]  = LUMA_LR_tex(vec2((fp + vec2( 0.5, 0.5)) * HOOKED_pt)).x;
    luma_pixels[4]  = LUMA_LR_tex(vec2((fp + vec2( 1.5, 0.5)) * HOOKED_pt)).x;
    luma_pixels[5]  = LUMA_LR_tex(vec2((fp + vec2( 2.5, 0.5)) * HOOKED_pt)).x;
    luma_pixels[6]  = LUMA_LR_tex(vec2((fp + vec2(-0.5, 1.5)) * HOOKED_pt)).x;
    luma_pixels[7]  = LUMA_LR_tex(vec2((fp + vec2( 0.5, 1.5)) * HOOKED_pt)).x;
    luma_pixels[8]  = LUMA_LR_tex(vec2((fp + vec2( 1.5, 1.5)) * HOOKED_pt)).x;
    luma_pixels[9]  = LUMA_LR_tex(vec2((fp + vec2( 2.5, 1.5)) * HOOKED_pt)).x;
    luma_pixels[10] = LUMA_LR_tex(vec2((fp + vec2( 0.5, 2.5)) * HOOKED_pt)).x;
    luma_pixels[11] = LUMA_LR_tex(vec2((fp + vec2( 1.5, 2.5)) * HOOKED_pt)).x;
#endif

    float w[12];
    w[0]  = comp_w(vec2( 0.0,-1.0) - pp, luma_zero - luma_pixels[0] );
    w[1]  = comp_w(vec2( 1.0,-1.0) - pp, luma_zero - luma_pixels[1] );
    w[2]  = comp_w(vec2(-1.0, 0.0) - pp, luma_zero - luma_pixels[2] );
    w[3]  = comp_w(vec2( 0.0, 0.0) - pp, luma_zero - luma_pixels[3] );
    w[4]  = comp_w(vec2( 1.0, 0.0) - pp, luma_zero - luma_pixels[4] );
    w[5]  = comp_w(vec2( 2.0, 0.0) - pp, luma_zero - luma_pixels[5] );
    w[6]  = comp_w(vec2(-1.0, 1.0) - pp, luma_zero - luma_pixels[6] );
    w[7]  = comp_w(vec2( 0.0, 1.0) - pp, luma_zero - luma_pixels[7] );
    w[8]  = comp_w(vec2( 1.0, 1.0) - pp, luma_zero - luma_pixels[8] );
    w[9]  = comp_w(vec2( 2.0, 1.0) - pp, luma_zero - luma_pixels[9] );
    w[10] = comp_w(vec2( 0.0, 2.0) - pp, luma_zero - luma_pixels[10]);
    w[11] = comp_w(vec2( 1.0, 2.0) - pp, luma_zero - luma_pixels[11]);

    float wt = 0.0;
    vec2 ct = vec2(0.0);
    for (int i = 0; i < 12; i++) {
        wt += w[i];
        ct += w[i] * chroma_pixels[i];
    }

    output_pix.xy = clamp(ct / wt, 0.0, 1.0);
    return output_pix;
}
