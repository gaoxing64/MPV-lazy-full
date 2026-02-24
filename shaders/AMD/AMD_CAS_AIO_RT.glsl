// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- RAW ver.
  https://github.com/GPUOpen-LibrariesAndSDKs/FidelityFX-SDK/blob/v1.1.4/sdk/include/FidelityFX/gpu/cas/ffx_cas.h

*/


//!PARAM STR
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.5

//!PARAM AUS
//!TYPE int
//!MINIMUM 0
//!MAXIMUM 1
0


//!HOOK MAIN
//!BIND HOOKED
//!DESC [AMD_CAS_AIO_RT] (SDK v1.1.4) - Sharpen
//!WHEN AUS OUTPUT.w HOOKED.w > OUTPUT.h HOOKED.h > * ! * AUS ! STR * +

#define min3(a, b, c) min(a, min(b, c))
#define max3(a, b, c) max(a, max(b, c))

ivec2 cas_clamp(ivec2 p) { return clamp(p, ivec2(0), ivec2(HOOKED_size) - 1); }

vec4 hook() {

	ivec2 pos = ivec2(HOOKED_pos * HOOKED_size);

	//  a b c
	//  d e f
	//  g h i
	vec3 a = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(pos + ivec2(-1, -1)), 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 b = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(pos + ivec2( 0, -1)), 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 c = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(pos + ivec2( 1, -1)), 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 d = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(pos + ivec2(-1,  0)), 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 e = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(pos),                 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 f = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(pos + ivec2( 1,  0)), 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 g = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(pos + ivec2(-1,  1)), 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 h = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(pos + ivec2( 0,  1)), 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 i = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(pos + ivec2( 1,  1)), 0).rgb * HOOKED_mul, 1.0)).rgb;

	//    b
	//  d e f
	//    h
	float mnR = min3(min3(d.r, e.r, f.r), b.r, h.r);
	float mnG = min3(min3(d.g, e.g, f.g), b.g, h.g);
	float mnB = min3(min3(d.b, e.b, f.b), b.b, h.b);
	float mnR2 = min3(min3(mnR, a.r, c.r), g.r, i.r);
	float mnG2 = min3(min3(mnG, a.g, c.g), g.g, i.g);
	float mnB2 = min3(min3(mnB, a.b, c.b), g.b, i.b);
	mnR += mnR2;
	mnG += mnG2;
	mnB += mnB2;

	float mxR = max3(max3(d.r, e.r, f.r), b.r, h.r);
	float mxG = max3(max3(d.g, e.g, f.g), b.g, h.g);
	float mxB = max3(max3(d.b, e.b, f.b), b.b, h.b);
	float mxR2 = max3(max3(mxR, a.r, c.r), g.r, i.r);
	float mxG2 = max3(max3(mxG, a.g, c.g), g.g, i.g);
	float mxB2 = max3(max3(mxB, a.b, c.b), g.b, i.b);
	mxR += mxR2;
	mxG += mxG2;
	mxB += mxB2;

	float rcpMR = 1.0 / mxR;
	float rcpMG = 1.0 / mxG;
	float rcpMB = 1.0 / mxB;
	float ampR = clamp(min(mnR, 2.0 - mxR) * rcpMR, 0.0, 1.0);
	float ampG = clamp(min(mnG, 2.0 - mxG) * rcpMG, 0.0, 1.0);
	float ampB = clamp(min(mnB, 2.0 - mxB) * rcpMB, 0.0, 1.0);
	ampR = sqrt(ampR);
	ampG = sqrt(ampG);
	ampB = sqrt(ampB);

	//  0 w 0
	//  w 1 w
	//  0 w 0
	float peak = -1.0 / mix(8.0, 5.0, STR);
	// float wR = ampR * peak;
	float wG = ampG * peak;
	// float wB = ampB * peak;

	float rcpWeight = 1.0 / (1.0 + 4.0 * wG);
	vec3 result;
	result.r = clamp((b.r * wG + d.r * wG + f.r * wG + h.r * wG + e.r) * rcpWeight, 0.0, 1.0);
	result.g = clamp((b.g * wG + d.g * wG + f.g * wG + h.g * wG + e.g) * rcpWeight, 0.0, 1.0);
	result.b = clamp((b.b * wG + d.b * wG + f.b * wG + h.b * wG + e.b) * rcpWeight, 0.0, 1.0);

	result = delinearize(vec4(result, 1.0)).rgb;
	float alpha = texelFetch(HOOKED_raw, cas_clamp(pos), 0).a * HOOKED_mul;
	return vec4(result, alpha);

}

//!HOOK MAIN
//!BIND HOOKED
//!DESC [AMD_CAS_AIO_RT] (SDK v1.1.4) - Upscale & Sharpen
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN AUS OUTPUT.w HOOKED.w > OUTPUT.h HOOKED.h > * *

#define min3(a, b, c) min(a, min(b, c))
#define max3(a, b, c) max(a, max(b, c))

ivec2 cas_clamp(ivec2 p) { return clamp(p, ivec2(0), ivec2(HOOKED_size) - 1); }

vec4 hook() {

	vec2 pp = HOOKED_pos * HOOKED_size - 0.5;
	vec2 fp = floor(pp);
	vec2 frac = pp - fp;
	ivec2 sp = ivec2(fp);

	//  a b c d
	//  e f g h
	//  i j k l
	//  m n o p
	vec3 a = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(sp + ivec2(-1, -1)), 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 b = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(sp + ivec2( 0, -1)), 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 c = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(sp + ivec2( 1, -1)), 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 d = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(sp + ivec2( 2, -1)), 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 e = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(sp + ivec2(-1,  0)), 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 f = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(sp + ivec2( 0,  0)), 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 g = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(sp + ivec2( 1,  0)), 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 hh = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(sp + ivec2( 2,  0)), 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 ii = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(sp + ivec2(-1,  1)), 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 j = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(sp + ivec2( 0,  1)), 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 k = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(sp + ivec2( 1,  1)), 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 l = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(sp + ivec2( 2,  1)), 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 m = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(sp + ivec2(-1,  2)), 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 n = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(sp + ivec2( 0,  2)), 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 o = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(sp + ivec2( 1,  2)), 0).rgb * HOOKED_mul, 1.0)).rgb;
	vec3 p = linearize(vec4(texelFetch(HOOKED_raw, cas_clamp(sp + ivec2( 2,  2)), 0).rgb * HOOKED_mul, 1.0)).rgb;

	// ============ 区域 F (左上) ============
	//  a b c       b
	//  e f g  +  e f g  -> min/max for f
	//  i j k       j
	float mnfR = min3(min3(b.r, e.r, f.r), g.r, j.r);
	float mnfG = min3(min3(b.g, e.g, f.g), g.g, j.g);
	float mnfB = min3(min3(b.b, e.b, f.b), g.b, j.b);
	float mnfR2 = min3(min3(mnfR, a.r, c.r), ii.r, k.r);
	float mnfG2 = min3(min3(mnfG, a.g, c.g), ii.g, k.g);
	float mnfB2 = min3(min3(mnfB, a.b, c.b), ii.b, k.b);
	mnfR += mnfR2;
	mnfG += mnfG2;
	mnfB += mnfB2;

	float mxfR = max3(max3(b.r, e.r, f.r), g.r, j.r);
	float mxfG = max3(max3(b.g, e.g, f.g), g.g, j.g);
	float mxfB = max3(max3(b.b, e.b, f.b), g.b, j.b);
	float mxfR2 = max3(max3(mxfR, a.r, c.r), ii.r, k.r);
	float mxfG2 = max3(max3(mxfG, a.g, c.g), ii.g, k.g);
	float mxfB2 = max3(max3(mxfB, a.b, c.b), ii.b, k.b);
	mxfR += mxfR2;
	mxfG += mxfG2;
	mxfB += mxfB2;

	// ============ 区域 G (右上) ============
	float mngR = min3(min3(c.r, f.r, g.r), hh.r, k.r);
	float mngG = min3(min3(c.g, f.g, g.g), hh.g, k.g);
	float mngB = min3(min3(c.b, f.b, g.b), hh.b, k.b);
	float mngR2 = min3(min3(mngR, b.r, d.r), j.r, l.r);
	float mngG2 = min3(min3(mngG, b.g, d.g), j.g, l.g);
	float mngB2 = min3(min3(mngB, b.b, d.b), j.b, l.b);
	mngR += mngR2;
	mngG += mngG2;
	mngB += mngB2;

	float mxgR = max3(max3(c.r, f.r, g.r), hh.r, k.r);
	float mxgG = max3(max3(c.g, f.g, g.g), hh.g, k.g);
	float mxgB = max3(max3(c.b, f.b, g.b), hh.b, k.b);
	float mxgR2 = max3(max3(mxgR, b.r, d.r), j.r, l.r);
	float mxgG2 = max3(max3(mxgG, b.g, d.g), j.g, l.g);
	float mxgB2 = max3(max3(mxgB, b.b, d.b), j.b, l.b);
	mxgR += mxgR2;
	mxgG += mxgG2;
	mxgB += mxgB2;

	// ============ 区域 J (左下) ============
	float mnjR = min3(min3(f.r, ii.r, j.r), k.r, n.r);
	float mnjG = min3(min3(f.g, ii.g, j.g), k.g, n.g);
	float mnjB = min3(min3(f.b, ii.b, j.b), k.b, n.b);
	float mnjR2 = min3(min3(mnjR, e.r, g.r), m.r, o.r);
	float mnjG2 = min3(min3(mnjG, e.g, g.g), m.g, o.g);
	float mnjB2 = min3(min3(mnjB, e.b, g.b), m.b, o.b);
	mnjR += mnjR2;
	mnjG += mnjG2;
	mnjB += mnjB2;

	float mxjR = max3(max3(f.r, ii.r, j.r), k.r, n.r);
	float mxjG = max3(max3(f.g, ii.g, j.g), k.g, n.g);
	float mxjB = max3(max3(f.b, ii.b, j.b), k.b, n.b);
	float mxjR2 = max3(max3(mxjR, e.r, g.r), m.r, o.r);
	float mxjG2 = max3(max3(mxjG, e.g, g.g), m.g, o.g);
	float mxjB2 = max3(max3(mxjB, e.b, g.b), m.b, o.b);
	mxjR += mxjR2;
	mxjG += mxjG2;
	mxjB += mxjB2;

	// ============ 区域 K (右下) ============
	float mnkR = min3(min3(g.r, j.r, k.r), l.r, o.r);
	float mnkG = min3(min3(g.g, j.g, k.g), l.g, o.g);
	float mnkB = min3(min3(g.b, j.b, k.b), l.b, o.b);
	float mnkR2 = min3(min3(mnkR, f.r, hh.r), n.r, p.r);
	float mnkG2 = min3(min3(mnkG, f.g, hh.g), n.g, p.g);
	float mnkB2 = min3(min3(mnkB, f.b, hh.b), n.b, p.b);
	mnkR += mnkR2;
	mnkG += mnkG2;
	mnkB += mnkB2;

	float mxkR = max3(max3(g.r, j.r, k.r), l.r, o.r);
	float mxkG = max3(max3(g.g, j.g, k.g), l.g, o.g);
	float mxkB = max3(max3(g.b, j.b, k.b), l.b, o.b);
	float mxkR2 = max3(max3(mxkR, f.r, hh.r), n.r, p.r);
	float mxkG2 = max3(max3(mxkG, f.g, hh.g), n.g, p.g);
	float mxkB2 = max3(max3(mxkB, f.b, hh.b), n.b, p.b);
	mxkR += mxkR2;
	mxkG += mxkG2;
	mxkB += mxkB2;

	// float rcpMfR = 1.0 / mxfR; 
	float rcpMfG = 1.0 / mxfG; 
	// float rcpMfB = 1.0 / mxfB;
	// float rcpMgR = 1.0 / mxgR; 
	float rcpMgG = 1.0 / mxgG; 
	// float rcpMgB = 1.0 / mxgB;
	// float rcpMjR = 1.0 / mxjR; 
	float rcpMjG = 1.0 / mxjG; 
	// float rcpMjB = 1.0 / mxjB;
	// float rcpMkR = 1.0 / mxkR; 
	float rcpMkG = 1.0 / mxkG; 
	// float rcpMkB = 1.0 / mxkB;

	// float ampfR = clamp(min(mnfR, 2.0 - mxfR) * rcpMfR, 0.0, 1.0);
	float ampfG = clamp(min(mnfG, 2.0 - mxfG) * rcpMfG, 0.0, 1.0);
	// float ampfB = clamp(min(mnfB, 2.0 - mxfB) * rcpMfB, 0.0, 1.0);
	// float ampgR = clamp(min(mngR, 2.0 - mxgR) * rcpMgR, 0.0, 1.0);
	float ampgG = clamp(min(mngG, 2.0 - mxgG) * rcpMgG, 0.0, 1.0);
	// float ampgB = clamp(min(mngB, 2.0 - mxgB) * rcpMgB, 0.0, 1.0);
	// float ampjR = clamp(min(mnjR, 2.0 - mxjR) * rcpMjR, 0.0, 1.0);
	float ampjG = clamp(min(mnjG, 2.0 - mxjG) * rcpMjG, 0.0, 1.0);
	// float ampjB = clamp(min(mnjB, 2.0 - mxjB) * rcpMjB, 0.0, 1.0);
	// float ampkR = clamp(min(mnkR, 2.0 - mxkR) * rcpMkR, 0.0, 1.0);
	float ampkG = clamp(min(mnkG, 2.0 - mxkG) * rcpMkG, 0.0, 1.0);
	// float ampkB = clamp(min(mnkB, 2.0 - mxkB) * rcpMkB, 0.0, 1.0);

	// ampfR = sqrt(ampfR); 
	ampfG = sqrt(ampfG); 
	// ampfB = sqrt(ampfB);
	// ampgR = sqrt(ampgR); 
	ampgG = sqrt(ampgG); 
	// ampgB = sqrt(ampgB);
	// ampjR = sqrt(ampjR); 
	ampjG = sqrt(ampjG); 
	// ampjB = sqrt(ampjB);
	// ampkR = sqrt(ampkR); 
	ampkG = sqrt(ampkG); 
	// ampkB = sqrt(ampkB);

	float peak = -1.0 / mix(8.0, 5.0, STR);
	// float wfR = ampfR * peak; 
	float wfG = ampfG * peak; 
	// float wfB = ampfB * peak;
	// float wgR = ampgR * peak; 
	float wgG = ampgG * peak; 
	// float wgB = ampgB * peak;
	// float wjR = ampjR * peak; 
	float wjG = ampjG * peak; 
	// float wjB = ampjB * peak;
	// float wkR = ampkR * peak; 
	float wkG = ampkG * peak; 
	// float wkB = ampkB * peak;

	float s = (1.0 - frac.x) * (1.0 - frac.y); // 左上
	float t = frac.x * (1.0 - frac.y);         // 右上
	float u = (1.0 - frac.x) * frac.y;         // 左下
	float v = frac.x * frac.y;                 // 右下

	float thinB = 1.0 / 32.0;
	s /= (thinB + (mxfG - mnfG));
	t /= (thinB + (mxgG - mngG));
	u /= (thinB + (mxjG - mnjG));
	v /= (thinB + (mxkG - mnkG));

	// float qbeR = wfR * s; 
	float qbeG = wfG * s; 
	// float qbeB = wfB * s;
	// float qchR = wgR * t; 
	float qchG = wgG * t; 
	// float qchB = wgB * t;
	// float qinR = wjR * u; 
	float qinG = wjG * u; 
	// float qinB = wjB * u;
	// float qloR = wkR * v; 
	float qloG = wkG * v; 
	// float qloB = wkB * v;

	// float qfR = wgR * t + wjR * u + s;
	float qfG = wgG * t + wjG * u + s;
	// float qfB = wgB * t + wjB * u + s;
	// float qgR = wfR * s + wkR * v + t;
	float qgG = wfG * s + wkG * v + t;
	// float qgB = wfB * s + wkB * v + t;
	// float qjR = wfR * s + wkR * v + u;
	float qjG = wfG * s + wkG * v + u;
	// float qjB = wfB * s + wkB * v + u;
	// float qkR = wgR * t + wjR * u + v;
	float qkG = wgG * t + wjG * u + v;
	// float qkB = wgB * t + wjB * u + v;

	float rcpWG = 1.0 / (2.0 * qbeG + 2.0 * qchG + 2.0 * qinG + 2.0 * qloG + qfG + qgG + qjG + qkG);
	vec3 result;
	result.r = clamp((b.r*qbeG + e.r*qbeG + c.r*qchG + hh.r*qchG + ii.r*qinG + n.r*qinG + l.r*qloG + o.r*qloG + f.r*qfG + g.r*qgG + j.r*qjG + k.r*qkG) * rcpWG, 0.0, 1.0);
	result.g = clamp((b.g*qbeG + e.g*qbeG + c.g*qchG + hh.g*qchG + ii.g*qinG + n.g*qinG + l.g*qloG + o.g*qloG + f.g*qfG + g.g*qgG + j.g*qjG + k.g*qkG) * rcpWG, 0.0, 1.0);
	result.b = clamp((b.b*qbeG + e.b*qbeG + c.b*qchG + hh.b*qchG + ii.b*qinG + n.b*qinG + l.b*qloG + o.b*qloG + f.b*qfG + g.b*qgG + j.b*qjG + k.b*qkG) * rcpWG, 0.0, 1.0);
	result = delinearize(vec4(result, 1.0)).rgb;

	float af = texelFetch(HOOKED_raw, cas_clamp(sp), 0).a * HOOKED_mul;
	float ag = texelFetch(HOOKED_raw, cas_clamp(sp + ivec2(1, 0)), 0).a * HOOKED_mul;
	float aj = texelFetch(HOOKED_raw, cas_clamp(sp + ivec2(0, 1)), 0).a * HOOKED_mul;
	float ak = texelFetch(HOOKED_raw, cas_clamp(sp + ivec2(1, 1)), 0).a * HOOKED_mul;
	float alpha = mix(mix(af, ag, frac.x), mix(aj, ak, frac.x), frac.y);
	return vec4(result, alpha);

}

