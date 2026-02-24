// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM CB
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 5.0
2.0

//!PARAM M
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 2.0
0.6

//!PARAM E
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.2

//!PARAM ES
//!TYPE float
//!MINIMUM 1.0
//!MAXIMUM 10.0
2.0


//!HOOK SCALED
//!BIND HOOKED
//!DESC [sharpen_complexV2_RT]
//!WHEN CB E +

vec4 hook() {

	float CoefBlur = CB;
	float CoefOrig = (1.0 + CoefBlur);

	// for the blur filter
	float mean = M;
	float dx = (mean * HOOKED_pt.x);
	float dy = (mean * HOOKED_pt.y);

	// for the sharpen filter
	float SharpenEdge = E;
	float Sharpen_val0 = ES;
	float Sharpen_val1 = ((Sharpen_val0 - 1.0) / 8.0);

	vec4 orig = HOOKED_tex(HOOKED_pos);

	// compute blurred image (gaussian filter)
	vec4 c1 = HOOKED_tex(HOOKED_pos + vec2(-dx, -dy));
	vec4 c2 = HOOKED_tex(HOOKED_pos + vec2(0.0, -dy));
	vec4 c3 = HOOKED_tex(HOOKED_pos + vec2(dx, -dy));
	vec4 c4 = HOOKED_tex(HOOKED_pos + vec2(-dx, 0.0));
	vec4 c5 = HOOKED_tex(HOOKED_pos + vec2(dx, 0.0));
	vec4 c6 = HOOKED_tex(HOOKED_pos + vec2(-dx, dy));
	vec4 c7 = HOOKED_tex(HOOKED_pos + vec2(0.0, dy));
	vec4 c8 = HOOKED_tex(HOOKED_pos + vec2(dx, dy));

	// gaussian filter
	// [ 1, 2, 1 ]
	// [ 2, 4, 2 ]
	// [ 1, 2, 1 ]
	// to normalize the values, we need to divide by the coeff sum
	// 1 / (1+2+1+2+4+2+1+2+1) = 1 / 16 = 0.0625
	vec4 flou = (c1 + c3 + c6 + c8 + 2.0 * (c2 + c4 + c5 + c7) + 4.0 * orig) * 0.0625;

	// substract blurred image from original image
	vec4 corrected = CoefOrig * orig - CoefBlur * flou;

	// edge detection
	// Get neighbor points
	// [ c1,   c2, c3 ]
	// [ c4, orig, c5 ]
	// [ c6,   c7, c8 ]
	c1 = HOOKED_tex(HOOKED_pos + vec2(-HOOKED_pt.x, -HOOKED_pt.y));
	c2 = HOOKED_tex(HOOKED_pos + vec2(0.0, -HOOKED_pt.y));
	c3 = HOOKED_tex(HOOKED_pos + vec2(HOOKED_pt.x, -HOOKED_pt.y));
	c4 = HOOKED_tex(HOOKED_pos + vec2(-HOOKED_pt.x, 0.0));
	c5 = HOOKED_tex(HOOKED_pos + vec2(HOOKED_pt.x, 0.0));
	c6 = HOOKED_tex(HOOKED_pos + vec2(-HOOKED_pt.x, HOOKED_pt.y));
	c7 = HOOKED_tex(HOOKED_pos + vec2(0.0, HOOKED_pt.y));
	c8 = HOOKED_tex(HOOKED_pos + vec2(HOOKED_pt.x, HOOKED_pt.y));

	// using Sobel filter
	// horizontal gradient
	// [ -1, 0, 1 ]
	// [ -2, 0, 2 ]
	// [ -1, 0, 1 ]
	vec4 delta1 = (c3 + 2.0 * c5 + c8) - (c1 + 2.0 * c4 + c6);

	// vertical gradient
	// [ -1, -2, -1 ]
	// [  0,  0,  0 ]
	// [  1,  2,  1 ]
	vec4 delta2 = (c6 + 2.0 * c7 + c8) - (c1 + 2.0 * c2 + c3);

	// computation
	if (sqrt(dot(delta1, delta1) + dot(delta2, delta2)) > SharpenEdge) {
		// if we have an edge, use sharpen
		return orig * Sharpen_val0 - (c1 + c2 + c3 + c4 + c5 + c6 + c7 + c8) * Sharpen_val1;
	} else {
		// else return corrected image
		return corrected;
	}

}

