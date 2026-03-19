// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM R
//!TYPE float
//!MINIMUM -100.0
//!MAXIMUM 100.0
0.0

//!PARAM G
//!TYPE float
//!MINIMUM -100.0
//!MAXIMUM 100.0
0.0

//!PARAM B
//!TYPE float
//!MINIMUM -100.0
//!MAXIMUM 100.0
0.0


//!HOOK MAIN
//!BIND HOOKED
//!DESC [eq_rgb_RT]
//!WHEN R G + B +

vec4 hook() {

	vec4 texcolor = HOOKED_tex(HOOKED_pos);
	float r = texcolor.r;
	float g = texcolor.g;
	float b = texcolor.b;
	r += (R / 100.0);
	g += (G / 100.0);
	b += (B / 100.0);
	vec3 rgb = vec3(r, g, b);

	return vec4(rgb, texcolor.a); 

}

