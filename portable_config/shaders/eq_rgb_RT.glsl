
//!PARAM Rp
//!TYPE float
//!MINIMUM -1.0
//!MAXIMUM 1.0
-0.1106

//!PARAM Gp
//!TYPE float
//!MINIMUM -1.0
//!MAXIMUM 1.0
0.0

//!PARAM Bp
//!TYPE float
//!MINIMUM -1.0
//!MAXIMUM 1.0
0.0591

//!DESC [eq_rgb_RT]
//!HOOK MAIN
//!BIND HOOKED

vec4 hook() {

	vec4 texcolor = HOOKED_tex(HOOKED_pos);
	float r = texcolor.r;
	float g = texcolor.g;
	float b = texcolor.b;
	r += Rp;
	g += Gp;
	b += Bp;
	vec3 rgb = vec3(r, g, b);

	return vec4(rgb, texcolor.a); 

}

