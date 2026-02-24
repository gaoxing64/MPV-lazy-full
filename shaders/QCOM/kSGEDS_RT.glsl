// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- RAW ver.
  https://github.com/SnapdragonStudios/snapdragon-gsr/blob/main/LICENSE

*/


//!PARAM STR
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 2.0
1.0

//!PARAM ET
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 255.0
64.0

//!PARAM ECS
//!TYPE float
//!MINIMUM 1.0
//!MAXIMUM 50.0
10.0


//!HOOK SCALED
//!BIND HOOKED
//!DESC [kSGEDS_RT]
//!WHEN STR

vec4 hook() {

	vec2 pos = HOOKED_pos;
	vec2 pt = HOOKED_pt;
	vec4 color = HOOKED_tex(pos);

	vec4 pix_l = HOOKED_tex(pos + vec2(-pt.x, 0.0));
	vec4 pix_r = HOOKED_tex(pos + vec2( pt.x, 0.0));
	vec4 pix_u = HOOKED_tex(pos + vec2(0.0, -pt.y));
	vec4 pix_d = HOOKED_tex(pos + vec2(0.0,  pt.y));

	float laplacian_g = 4.0 * color.g - (pix_l.g + pix_r.g + pix_u.g + pix_d.g);
	float local_clearness_raw = abs(laplacian_g);

	float clearness_factor = clamp(local_clearness_raw * ECS, 0.0, 1.0);
	float dynamic_ET = (ET / 255.0) * clearness_factor;
	float edgeVote = abs(pix_l.g - pix_r.g) + abs(pix_u.g - pix_d.g);

	if (edgeVote > dynamic_ET) {
		float deltaY = STR * laplacian_g;
		deltaY = clamp(deltaY, -23.0 / 255.0, 23.0 / 255.0);
		color.rgb += vec3(deltaY);
		color.rgb = clamp(color.rgb, 0.0, 1.0);
	}

	return color;

}

