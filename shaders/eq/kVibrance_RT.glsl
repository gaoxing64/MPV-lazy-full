// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM VIB
//!TYPE float
//!MINIMUM -100.0
//!MAXIMUM 100.0
0.0

//!PARAM VF_R
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 2.0
1.0

//!PARAM VF_G
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 2.0
1.0

//!PARAM VF_B
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 2.0
1.0

//!PARAM MODE
//!TYPE DEFINE
//!MINIMUM 1
//!MAXIMUM 2
1

//!PARAM SKP
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.5

//!PARAM LCS
//!TYPE DEFINE
//!MINIMUM 0
//!MAXIMUM 1
0


//!HOOK MAIN
//!BIND HOOKED
//!DESC [kVibrance_RT]
//!WHEN VIB

vec3 srgb_to_linear(vec3 c) {
	c = clamp(c, 0.0, 1.0);
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
}

vec3 linear_to_srgb(vec3 c) {
	c = clamp(c, 0.0, 1.0);
	return mix(c * 12.92, 1.055 * pow(c, vec3(1.0/2.4)) - 0.055, step(0.0031308, c));
}

vec3 rgb_to_xyz(vec3 rgb) {
	const mat3 m = mat3(
		 0.4124564,  0.3575761,  0.1804375,
		 0.2126729,  0.7151522,  0.0721750,
		 0.0193339,  0.1191920,  0.9503041
	);
	return rgb * m;
}

vec3 xyz_to_rgb(vec3 xyz) {
	const mat3 m = mat3(
		 3.2404542, -1.5371385, -0.4985314,
		-0.9692660,  1.8760108,  0.0415560,
		 0.0556434, -0.2040259,  1.0572252
	);
	return xyz * m;
}

const vec3 D65 = vec3(0.95047, 1.0, 1.08883);

float lab_f(float t) {
	const float delta = 6.0 / 29.0;
	return t > delta * delta * delta ? pow(t, 1.0/3.0) : t / (3.0 * delta * delta) + 4.0/29.0;
}

float lab_f_inv(float t) {
	const float delta = 6.0 / 29.0;
	float result = t > delta ? t * t * t : 3.0 * delta * delta * (t - 4.0/29.0);
	return max(result, 0.0);
}

vec3 xyz_to_lab(vec3 xyz) {
	vec3 n = max(xyz / D65, vec3(0.0));
	float fx = lab_f(n.x);
	float fy = lab_f(n.y);
	float fz = lab_f(n.z);
	return vec3(116.0 * fy - 16.0, 500.0 * (fx - fy), 200.0 * (fy - fz));
}

vec3 lab_to_xyz(vec3 lab) {
	float fy = (lab.x + 16.0) / 116.0;
	float fx = lab.y / 500.0 + fy;
	float fz = fy - lab.z / 200.0;
	return max(vec3(lab_f_inv(fx), lab_f_inv(fy), lab_f_inv(fz)) * D65, vec3(0.0));
}

float getSkinWeight(vec3 lab) {
	float C = length(lab.yz);
	if (C < 5.0) return 0.0;
	float h = atan(lab.z, lab.y) * 57.2957795;
	h = h < 0.0 ? h + 360.0 : h;
	float hueWeight = smoothstep(0.0, 15.0, h) * smoothstep(60.0, 40.0, h);
	float chromaWeight = smoothstep(5.0, 15.0, C) * smoothstep(70.0, 50.0, C);
	float aWeight = smoothstep(0.0, 8.0, lab.y);
	return hueWeight * chromaWeight * aWeight;
}

vec4 hook() {

	vec4 color = HOOKED_texOff(0);

	float skinFactor = 1.0;
	if (SKP > 0.0) {
		vec3 linear = srgb_to_linear(color.rgb);
		vec3 xyz = rgb_to_xyz(linear);
		vec3 lab = xyz_to_lab(xyz);
		float skinWeight = getSkinWeight(lab);
		skinFactor = 1.0 - SKP * skinWeight;
	}
	float vib2 = VIB * 0.01;
	float effectiveVIB = vib2 * skinFactor;

#if LCS == 1

	vec3 linear = srgb_to_linear(color.rgb);
	vec3 xyz = rgb_to_xyz(linear);
	vec3 lab = xyz_to_lab(xyz);
	float C = length(lab.yz);

	if (C > 1e-4) {
		float C_norm = clamp(C / 130.0, 0.0, 1.0);

	#if MODE == 1
		float weight = 1.0 - C_norm;
	#else
		float weight = (1.0 - C_norm) * (1.0 - C_norm);
	#endif

		float avgFactor = (VF_R + VF_G + VF_B) / 3.0;
		float scale = 1.0 + effectiveVIB * avgFactor * weight;
		scale = max(scale, 0.0);
		lab.y *= scale;
		lab.z *= scale;
	}

	xyz = lab_to_xyz(lab);
	linear = xyz_to_rgb(xyz);
	color.rgb = linear_to_srgb(clamp(linear, 0.0, 1.0));

#else

	const vec3 coefLuma = vec3(0.212656, 0.715158, 0.072186);
	float luma = dot(coefLuma, color.rgb);
	float max_color = max(color.r, max(color.g, color.b));
	float min_color = min(color.r, min(color.g, color.b));

	if (max_color > 0.005) {
		vec3 coeffVibrance;

		#if MODE == 1
			float color_saturation = max_color - min_color;
			coeffVibrance = vec3(VF_R, VF_G, VF_B) * effectiveVIB;
			coeffVibrance *= (1.0 - sign(coeffVibrance) * color_saturation);
		#else
			float saturation = (max_color - min_color) / (max_color + 1e-5);
			float weight = (1.0 - saturation) * (1.0 - saturation);
			coeffVibrance = vec3(VF_R, VF_G, VF_B) * effectiveVIB * weight;
		#endif

		float darkFade = smoothstep(0.005, 0.02, max_color);
		coeffVibrance *= darkFade;
		color.rgb = clamp(mix(vec3(luma), color.rgb, 1.0 + coeffVibrance), 0.0, 1.0);
	}

#endif

	return color;

}

