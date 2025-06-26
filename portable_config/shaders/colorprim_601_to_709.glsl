
//!DESC [colorprim_601_to_709]
//!HOOK MAINPRESUB
//!BIND HOOKED

mat4 rgb2ycbcr601 = mat4(
	 0.299,     0.587,     0.114,    0.0,
	-0.168736, -0.331264,  0.5,      0.0,
	 0.5,      -0.418688, -0.081312, 0.0,
	 0.0,       0.0,       0.0,      0.0
);

mat4 ycbcr2rgb709 = mat4(
	 1.0,  0.0,       1.5748,   0.0,
	 1.0, -0.187324, -0.468124, 0.0,
	 1.0,  1.8556,    0.0,      0.0,
	 0.0,  0.0,       0.0,      0.0
);

vec4 hook() {

	vec4 c0 = HOOKED_tex(HOOKED_pos);
	c0 = rgb2ycbcr601 * c0;
	c0 = ycbcr2rgb709 * c0;

	return c0;

}

