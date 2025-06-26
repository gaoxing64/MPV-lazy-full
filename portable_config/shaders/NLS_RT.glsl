//	NLS# by NotMithical
//	https://github.com/NotMithical/mpv-config/blob/main/Personal/portable_config/shaders/AspectRatio/NLS%23.glsl
//
// --Parameters Summary --
// HorizontalStretch and VerticalStretch:
//		Adjust balance between Horizontal and Vertical Stretching. Values will be normalized to total to 1.0, otherwise distortion will occur in the center of the image.
// CropAmount:
//		Crop image edges. Raising this value results in loss of content but results in less stretching.
// BarsAmount:
//		Scale the image down and add padding in the form of black bars. Raising this value results in less stretching.
// CenterProtect:
//		Changes the curve for stretching. Higher values apply more stretching towards the edges of the screen. Currently experimental; I'm still figuring out the math for this whole thing and it turns out the padding, cropping, and center protection affect each other a fair bit.
//
// The defaults will distribute stretching across all edges and will not crop or pad the image.

//!PARAM HorizontalStretch
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.5

//!PARAM VerticalStretch
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.5

//!PARAM CropAmount
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.0

//!PARAM BarsAmount
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.0

//!PARAM CenterProtect
//!TYPE float
//!MINIMUM 0.1
//!MAXIMUM 6.0
1.0

//!HOOK MAINPRESUB
//!BIND HOOKED
//!DESC [NLS_RT] Bidirectional Nonlinear Stretch

vec2 stretch(vec2 pos, float h_par, float v_par) {
	// Normalize user defined parameters
	float HorizontalStretchNorm = (HorizontalStretch * (1 / (HorizontalStretch + VerticalStretch))),
		  VerticalStretchNorm = (VerticalStretch * (1 / (HorizontalStretch + VerticalStretch)));

	//float h_m_stretch = pow(h_par, HorizontalStretchNorm),
	float h_m_stretch = pow(h_par, HorizontalStretchNorm),
		  v_m_stretch = pow(v_par, VerticalStretchNorm),
		  x = pos.x - 0.5,
		  y = pos.y - 0.5;

	// Map x & y coordinates to themselves with a curve, taking into account cropping and padding
	if (h_par < 1) {
		return vec2(mix(x * pow(abs(x), CenterProtect) * (pow(2, CenterProtect) - (CropAmount * 2)), x, h_m_stretch) + 0.5, mix(y * pow(abs(y), CenterProtect) * (pow(2, CenterProtect) - (BarsAmount * 5)), y, v_m_stretch) + 0.5);
	} else {
		return vec2(mix(x * pow(abs(x), CenterProtect) * (pow(2, CenterProtect) - (BarsAmount * 5)), x, h_m_stretch) + 0.5, mix(y * pow(abs(y), CenterProtect) * (pow(2, CenterProtect) - (CropAmount * 2)), y, v_m_stretch) + 0.5);
	}
}

vec4 hook() {
	float dar = target_size.x / target_size.y,
		  sar = HOOKED_size.x / HOOKED_size.y,
		  h_par = dar / sar,
		  v_par = sar / dar;

	vec2 stretchedPos = stretch(HOOKED_pos, h_par, v_par);
	
	// Check what pixels are outside the target boundaries
	bool outOfBounds = ((any(lessThan(stretchedPos, vec2(0.0))) || any(greaterThan(stretchedPos, vec2(1.0)))) ? true : false);

	// Black out pixels outside target boundaries
	return (outOfBounds ? vec4(0.0) : HOOKED_tex(stretchedPos));
}