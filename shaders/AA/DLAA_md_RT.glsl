// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- RAW ver.
  https://github.com/ForserX/DLAA/blob/master/LICENSE

*/


//!PARAM DP
//!TYPE DEFINE
//!MINIMUM 0
//!MAXIMUM 1
1

//!PARAM MODE
//!TYPE DEFINE
//!MINIMUM 1
//!MAXIMUM 2
1


//!HOOK POSTKERNEL
//!BIND HOOKED
//!SAVE DLAA_PRE
//!DESC [DLAA_md_RT] detect edge luma
//!WHEN PREKERNEL.w POSTKERNEL.w > PREKERNEL.h POSTKERNEL.h > *

#define HDR 0
float Luminance(vec3 rgb) {
#if (HDR == 1)
	vec3 CurrentDot = vec3(0.2627, 0.6780, 0.0593);
#else
	vec3 CurrentDot = vec3(0.2126, 0.7152, 0.0722);
#endif
	return dot(rgb, CurrentDot);
}

vec4 hook() {

	vec4 center = HOOKED_texOff(vec2( 0.0,  0.0));
	vec4 left   = HOOKED_texOff(vec2(-1.0,  0.0));
	vec4 right  = HOOKED_texOff(vec2( 1.0,  0.0));
	vec4 top    = HOOKED_texOff(vec2( 0.0, -1.0));
	vec4 bottom = HOOKED_texOff(vec2( 0.0,  1.0));

	vec4 edges = 4.0 * abs((left + right + top + bottom) - 4.0 * center);
	float edges_lum = Luminance(edges.xyz);

	return vec4(center.xyz, edges_lum);

}

//!HOOK POSTKERNEL
//!BIND HOOKED
//!BIND DLAA_PRE
//!DESC [DLAA_md_RT] anti-aliasing
//!WHEN PREKERNEL.w POSTKERNEL.w > PREKERNEL.h POSTKERNEL.h > *

#define HDR 0
float Luminance(vec3 rgb) {
#if (HDR == 1)
	vec3 CurrentDot = vec3(0.2627, 0.6780, 0.0593);
#else
	vec3 CurrentDot = vec3(0.2126, 0.7152, 0.0722);
#endif
	return dot(rgb, CurrentDot);
}

vec4 hook() {

	const float lambda = 3.0;
	const float epsilon = 0.1;

	vec4 center    = DLAA_PRE_texOff(vec2(  0.0,  0.0));
	vec4 left_01   = DLAA_PRE_texOff(vec2( -1.5,  0.0));
	vec4 right_01  = DLAA_PRE_texOff(vec2(  1.5,  0.0));
	vec4 top_01    = DLAA_PRE_texOff(vec2(  0.0, -1.5));
	vec4 bottom_01 = DLAA_PRE_texOff(vec2(  0.0,  1.5));
 
	vec4 w_h = 2.0 * (left_01 + right_01);
	vec4 w_v = 2.0 * (top_01 + bottom_01);

#if (MODE == 2)
	vec4 edge_h = abs(w_h - 4.0 * center) / 4.0;
	vec4 edge_v = abs(w_v - 4.0 * center) / 4.0;
#elif (MODE == 1)
	vec4 left   = DLAA_PRE_texOff(vec2(-1.0, 0.0));
	vec4 right  = DLAA_PRE_texOff(vec2( 1.0, 0.0));
	vec4 top    = DLAA_PRE_texOff(vec2( 0.0,-1.0));
	vec4 bottom = DLAA_PRE_texOff(vec2( 0.0, 1.0));

	vec4 edge_h = abs(left + right - 2.0 * center) / 2.0;
	vec4 edge_v = abs(top + bottom - 2.0 * center) / 2.0;
#endif

	vec4 blurred_h = (w_h + 2.0 * center) / 6.0;
	vec4 blurred_v = (w_v + 2.0 * center) / 6.0;

	float edge_h_lum = Luminance(edge_h.xyz);
	float edge_v_lum = Luminance(edge_v.xyz);
	float blurred_h_lum = Luminance(blurred_h.xyz);
	float blurred_v_lum = Luminance(blurred_v.xyz);

	float edge_mask_h = clamp((lambda * edge_h_lum - epsilon) / blurred_v_lum, 0.0, 1.0);
	float edge_mask_v = clamp((lambda * edge_v_lum - epsilon) / blurred_h_lum, 0.0, 1.0);

	vec4 clr = center;
	clr = mix(clr, blurred_h, edge_mask_v);

#if (MODE == 2)
	clr = mix(clr, blurred_v, edge_mask_h * 1.0);
#elif (MODE == 1)
	clr = mix(clr, blurred_v, edge_mask_h * 0.5);
#endif

	vec4 h0 = DLAA_PRE_texOff(vec2( 1.5, 0.0)); vec4 h1 = DLAA_PRE_texOff(vec2( 3.5, 0.0)); vec4 h2 = DLAA_PRE_texOff(vec2( 5.5, 0.0)); vec4 h3 = DLAA_PRE_texOff(vec2( 7.5, 0.0));
	vec4 h4 = DLAA_PRE_texOff(vec2(-1.5, 0.0)); vec4 h5 = DLAA_PRE_texOff(vec2(-3.5, 0.0)); vec4 h6 = DLAA_PRE_texOff(vec2(-5.5, 0.0)); vec4 h7 = DLAA_PRE_texOff(vec2(-7.5, 0.0));
	vec4 v0 = DLAA_PRE_texOff(vec2( 0.0, 1.5)); vec4 v1 = DLAA_PRE_texOff(vec2( 0.0, 3.5)); vec4 v2 = DLAA_PRE_texOff(vec2( 0.0, 5.5)); vec4 v3 = DLAA_PRE_texOff(vec2( 0.0, 7.5));
	vec4 v4 = DLAA_PRE_texOff(vec2( 0.0,-1.5)); vec4 v5 = DLAA_PRE_texOff(vec2( 0.0,-3.5)); vec4 v6 = DLAA_PRE_texOff(vec2( 0.0,-5.5)); vec4 v7 = DLAA_PRE_texOff(vec2( 0.0,-7.5));

	float long_edge_mask_h = (h0.a + h1.a + h2.a + h3.a + h4.a + h5.a + h6.a + h7.a) / 8.0;
	float long_edge_mask_v = (v0.a + v1.a + v2.a + v3.a + v4.a + v5.a + v6.a + v7.a) / 8.0;
	long_edge_mask_h = clamp(long_edge_mask_h * 2.0 - 1.0, 0.0, 1.0);
	long_edge_mask_v = clamp(long_edge_mask_v * 2.0 - 1.0, 0.0, 1.0);

	if (abs(long_edge_mask_h - long_edge_mask_v) > 0.2) {
		vec4 left   = DLAA_PRE_texOff(vec2(-1.0, 0.0));
		vec4 right  = DLAA_PRE_texOff(vec2( 1.0, 0.0));
		vec4 top    = DLAA_PRE_texOff(vec2( 0.0,-1.0));
		vec4 bottom = DLAA_PRE_texOff(vec2( 0.0, 1.0));

		vec4 long_blurred_h = (h0 + h1 + h2 + h3 + h4 + h5 + h6 + h7) / 8.0;
		vec4 long_blurred_v = (v0 + v1 + v2 + v3 + v4 + v5 + v6 + v7) / 8.0;
		float lb_h_lum   = Luminance(long_blurred_h.xyz);
		float lb_v_lum   = Luminance(long_blurred_v.xyz);

		float center_lum = Luminance(center.xyz);
		float left_lum   = Luminance(left.xyz);
		float right_lum  = Luminance(right.xyz);
		float top_lum    = Luminance(top.xyz);
		float bottom_lum = Luminance(bottom.xyz);

		vec4 clr_v = center;
		vec4 clr_h = center;
		float hx = clamp((lb_h_lum - top_lum   ) / (center_lum - top_lum   ), 0.0, 1.0);
		float vx = clamp((lb_v_lum - left_lum  ) / (center_lum - left_lum  ), 0.0, 1.0);
		float hy = clamp(1.0 + (lb_h_lum - center_lum) / (center_lum - bottom_lum), 0.0, 1.0);
		float vy = clamp(1.0 + (lb_v_lum - center_lum) / (center_lum - right_lum ), 0.0, 1.0);

		vec4 vhxy = vec4(vx, vy, hx, hy);
		vhxy = mix(vhxy, vec4(1.0), equal(vhxy, vec4(0.0)));

		clr_v = mix(left  , clr_v, vhxy.x);
		clr_v = mix(right , clr_v, vhxy.y);
		clr_h = mix(top   , clr_h, vhxy.z);
		clr_h = mix(bottom, clr_h, vhxy.w);

		clr = mix(clr, clr_v, long_edge_mask_v);
		clr = mix(clr, clr_h, long_edge_mask_h);
	}

#if (DP == 1)
	vec4 r0 = DLAA_PRE_texOff(vec2(-1.5, -1.5));
	vec4 r1 = DLAA_PRE_texOff(vec2( 1.5, -1.5));
	vec4 r2 = DLAA_PRE_texOff(vec2(-1.5,  1.5));
	vec4 r3 = DLAA_PRE_texOff(vec2( 1.5,  1.5));

	vec4 r = (4.0 * (r0 + r1 + r2 + r3) + center + top_01 + bottom_01 + left_01 + right_01) / 25.0;
	clr = mix(clr, center, clamp(r.a * 3.0 - 1.5, 0.0, 1.0));
#endif

	clr.a = HOOKED_texOff(vec2(0.0)).a;
	return clr;

}

