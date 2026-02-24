// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- Paper ver.
  https://arxiv.org/pdf/1505.00996

*/


//!PARAM RAD
//!TYPE int
//!MINIMUM 1
//!MAXIMUM 8
2

//!PARAM EPS
//!TYPE float
//!MINIMUM 0.001
//!MAXIMUM 0.1
0.004

//!PARAM SUBSAM
//!TYPE int
//!MINIMUM 1
//!MAXIMUM 4
2

//!PARAM STR
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 5.0
0.5

//!HOOK MAIN
//!BIND HOOKED
//!SAVE FGF_DOWN_RGB
//!DESC [Fast_Guided_enh_rgb_RT] Downsample
//!WIDTH HOOKED.w SUBSAM /
//!HEIGHT HOOKED.h SUBSAM /
//!WHEN STR SUBSAM 1 > *

vec4 hook() {

	vec3 rgb = HOOKED_texOff(0).rgb;
	float luma = dot(rgb, vec3(0.2126, 0.7152, 0.0722));
	return vec4(rgb, luma);

}

//!HOOK MAIN
//!BIND HOOKED
//!SAVE FGF_DOWN_RGB
//!DESC [Fast_Guided_enh_rgb_RT] Prepare
//!WIDTH HOOKED.w
//!HEIGHT HOOKED.h
//!WHEN STR SUBSAM 1 = *

vec4 hook() {

	vec3 rgb = HOOKED_texOff(0).rgb;
	float luma = dot(rgb, vec3(0.2126, 0.7152, 0.0722));
	return vec4(rgb, luma);

}

//!HOOK MAIN
//!BIND FGF_DOWN_RGB
//!SAVE FGF_PROD1
//!DESC [Fast_Guided_enh_rgb_RT] Prodt1
//!WIDTH FGF_DOWN_RGB.w
//!HEIGHT FGF_DOWN_RGB.h
//!WHEN STR

vec4 hook() {

	vec4 data = FGF_DOWN_RGB_texOff(0);
	float r = data.r, g = data.g, b = data.b;
	return vec4(r*r, g*g, b*b, r*g);

}

//!HOOK MAIN
//!BIND FGF_DOWN_RGB
//!SAVE FGF_PROD2
//!DESC [Fast_Guided_enh_rgb_RT] Prodt2
//!WIDTH FGF_DOWN_RGB.w
//!HEIGHT FGF_DOWN_RGB.h
//!WHEN STR

vec4 hook() {

	vec4 data = FGF_DOWN_RGB_texOff(0);
	float r = data.r, g = data.g, b = data.b, p = data.a;
	return vec4(r*b, g*b, r*p, g*p);

}

//!HOOK MAIN
//!BIND FGF_DOWN_RGB
//!SAVE FGF_PROD3
//!DESC [Fast_Guided_enh_rgb_RT] Prodt3
//!WIDTH FGF_DOWN_RGB.w
//!HEIGHT FGF_DOWN_RGB.h
//!COMPONENTS 1
//!WHEN STR

vec4 hook() {

	vec4 data = FGF_DOWN_RGB_texOff(0);
	return vec4(data.b * data.a);

}

//!HOOK MAIN
//!BIND FGF_DOWN_RGB
//!SAVE FGF_RGB_H
//!DESC [Fast_Guided_enh_rgb_RT] H-Box RGB
//!WIDTH FGF_DOWN_RGB.w
//!HEIGHT FGF_DOWN_RGB.h
//!WHEN STR

#define R (SUBSAM > 1 ? RAD / SUBSAM : RAD)

vec4 hook() {

	vec4 sum = vec4(0.0);
	int r = int(R);
	float count = 0.0;
	for (int x = -r; x <= r; x++) {
		sum += FGF_DOWN_RGB_texOff(vec2(float(x), 0.0));
		count += 1.0;
	}
	return sum / count;

}

//!HOOK MAIN
//!BIND FGF_PROD1
//!SAVE FGF_PROD1_H
//!DESC [Fast_Guided_enh_rgb_RT] H-Box Prodt1
//!WIDTH FGF_PROD1.w
//!HEIGHT FGF_PROD1.h
//!WHEN STR

#define R (SUBSAM > 1 ? RAD / SUBSAM : RAD)

vec4 hook() {

	vec4 sum = vec4(0.0);
	int r = int(R);
	float count = 0.0;
	for (int x = -r; x <= r; x++) {
		sum += FGF_PROD1_texOff(vec2(float(x), 0.0));
		count += 1.0;
	}
	return sum / count;

}

//!HOOK MAIN
//!BIND FGF_PROD2
//!SAVE FGF_PROD2_H
//!DESC [Fast_Guided_enh_rgb_RT] H-Box Prodt2
//!WIDTH FGF_PROD2.w
//!HEIGHT FGF_PROD2.h
//!WHEN STR

#define R (SUBSAM > 1 ? RAD / SUBSAM : RAD)

vec4 hook() {

	vec4 sum = vec4(0.0);
	int r = int(R);
	float count = 0.0;
	for (int x = -r; x <= r; x++) {
		sum += FGF_PROD2_texOff(vec2(float(x), 0.0));
		count += 1.0;
	}
	return sum / count;

}

//!HOOK MAIN
//!BIND FGF_PROD3
//!SAVE FGF_PROD3_H
//!DESC [Fast_Guided_enh_rgb_RT] H-Box Prodt3
//!WIDTH FGF_PROD3.w
//!HEIGHT FGF_PROD3.h
//!COMPONENTS 1
//!WHEN STR

#define R (SUBSAM > 1 ? RAD / SUBSAM : RAD)

vec4 hook() {

	float sum = 0.0;
	int r = int(R);
	float count = 0.0;
	for (int x = -r; x <= r; x++) {
		sum += FGF_PROD3_texOff(vec2(float(x), 0.0)).x;
		count += 1.0;
	}
	return vec4(sum / count);

}

//!HOOK MAIN
//!BIND FGF_RGB_H
//!SAVE FGF_MEAN_RGB
//!DESC [Fast_Guided_enh_rgb_RT] V-Box RGB
//!WIDTH FGF_RGB_H.w
//!HEIGHT FGF_RGB_H.h
//!WHEN STR

#define R (SUBSAM > 1 ? RAD / SUBSAM : RAD)

vec4 hook() {

	vec4 sum = vec4(0.0);
	int r = int(R);
	float count = 0.0;
	for (int y = -r; y <= r; y++) {
		sum += FGF_RGB_H_texOff(vec2(0.0, float(y)));
		count += 1.0;
	}
	return sum / count;

}

//!HOOK MAIN
//!BIND FGF_PROD1_H
//!SAVE FGF_MEAN_PROD1
//!DESC [Fast_Guided_enh_rgb_RT] V-Box Prodt1
//!WIDTH FGF_PROD1_H.w
//!HEIGHT FGF_PROD1_H.h
//!WHEN STR

#define R (SUBSAM > 1 ? RAD / SUBSAM : RAD)

vec4 hook() {

	vec4 sum = vec4(0.0);
	int r = int(R);
	float count = 0.0;
	for (int y = -r; y <= r; y++) {
		sum += FGF_PROD1_H_texOff(vec2(0.0, float(y)));
		count += 1.0;
	}
	return sum / count;

}

//!HOOK MAIN
//!BIND FGF_PROD2_H
//!SAVE FGF_MEAN_PROD2
//!DESC [Fast_Guided_enh_rgb_RT] V-Box Prodt2
//!WIDTH FGF_PROD2_H.w
//!HEIGHT FGF_PROD2_H.h
//!WHEN STR

#define R (SUBSAM > 1 ? RAD / SUBSAM : RAD)

vec4 hook() {

	vec4 sum = vec4(0.0);
	int r = int(R);
	float count = 0.0;
	for (int y = -r; y <= r; y++) {
		sum += FGF_PROD2_H_texOff(vec2(0.0, float(y)));
		count += 1.0;
	}
	return sum / count;

}

//!HOOK MAIN
//!BIND FGF_PROD3_H
//!SAVE FGF_MEAN_PROD3
//!DESC [Fast_Guided_enh_rgb_RT] V-Box Prodt3
//!WIDTH FGF_PROD3_H.w
//!HEIGHT FGF_PROD3_H.h
//!COMPONENTS 1
//!WHEN STR

#define R (SUBSAM > 1 ? RAD / SUBSAM : RAD)

vec4 hook() {

	float sum = 0.0;
	int r = int(R);
	float count = 0.0;
	for (int y = -r; y <= r; y++) {
		sum += FGF_PROD3_H_texOff(vec2(0.0, float(y))).x;
		count += 1.0;
	}
	return vec4(sum / count);

}

//!HOOK MAIN
//!BIND FGF_MEAN_RGB
//!BIND FGF_MEAN_PROD1
//!BIND FGF_MEAN_PROD2
//!BIND FGF_MEAN_PROD3
//!SAVE FGF_COEF
//!DESC [Fast_Guided_enh_rgb_RT] Coefficients
//!WIDTH FGF_MEAN_RGB.w
//!HEIGHT FGF_MEAN_RGB.h
//!WHEN STR

mat3 inv3x3(mat3 m) {

	float det = m[0][0] * (m[1][1] * m[2][2] - m[2][1] * m[1][2])
			  - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
			  + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]);
	float invDet = 1.0 / det;
	mat3 minv;
	minv[0][0] = (m[1][1] * m[2][2] - m[2][1] * m[1][2]) * invDet;
	minv[0][1] = (m[0][2] * m[2][1] - m[0][1] * m[2][2]) * invDet;
	minv[0][2] = (m[0][1] * m[1][2] - m[0][2] * m[1][1]) * invDet;
	minv[1][0] = (m[1][2] * m[2][0] - m[1][0] * m[2][2]) * invDet;
	minv[1][1] = (m[0][0] * m[2][2] - m[0][2] * m[2][0]) * invDet;
	minv[1][2] = (m[1][0] * m[0][2] - m[0][0] * m[1][2]) * invDet;
	minv[2][0] = (m[1][0] * m[2][1] - m[2][0] * m[1][1]) * invDet;
	minv[2][1] = (m[2][0] * m[0][1] - m[0][0] * m[2][1]) * invDet;
	minv[2][2] = (m[0][0] * m[1][1] - m[1][0] * m[0][1]) * invDet;
	return minv;

}

vec4 hook() {

	vec4 mean_rgb = FGF_MEAN_RGB_texOff(0);
	vec4 mean_prod1 = FGF_MEAN_PROD1_texOff(0);
	vec4 mean_prod2 = FGF_MEAN_PROD2_texOff(0);
	float mean_bp = FGF_MEAN_PROD3_texOff(0).x;
	float mean_r = mean_rgb.r, mean_g = mean_rgb.g, mean_b = mean_rgb.b, mean_p = mean_rgb.a;
	float var_rr = mean_prod1.x - mean_r * mean_r + EPS;
	float var_gg = mean_prod1.y - mean_g * mean_g + EPS;
	float var_bb = mean_prod1.z - mean_b * mean_b + EPS;
	float var_rg = mean_prod1.w - mean_r * mean_g;
	float var_rb = mean_prod2.x - mean_r * mean_b;
	float var_gb = mean_prod2.y - mean_g * mean_b;
	float cov_rp = mean_prod2.z - mean_r * mean_p;
	float cov_gp = mean_prod2.w - mean_g * mean_p;
	float cov_bp = mean_bp - mean_b * mean_p;
	mat3 Sigma = mat3(var_rr, var_rg, var_rb, var_rg, var_gg, var_gb, var_rb, var_gb, var_bb);
	mat3 invSigma = inv3x3(Sigma);
	vec3 a = invSigma * vec3(cov_rp, cov_gp, cov_bp);
	float b = mean_p - dot(a, vec3(mean_r, mean_g, mean_b));
	return vec4(a, b);

}

//!HOOK MAIN
//!BIND FGF_COEF
//!SAVE FGF_COEF_H
//!DESC [Fast_Guided_enh_rgb_RT] H-Box coef
//!WIDTH FGF_COEF.w
//!HEIGHT FGF_COEF.h
//!WHEN STR

#define R (SUBSAM > 1 ? RAD / SUBSAM : RAD)

vec4 hook() {

	vec4 sum = vec4(0.0);
	int r = int(R);
	float count = 0.0;
	for (int x = -r; x <= r; x++) {
		sum += FGF_COEF_texOff(vec2(float(x), 0.0));
		count += 1.0;
	}
	return sum / count;

}

//!HOOK MAIN
//!BIND FGF_COEF_H
//!SAVE FGF_MEAN_COEF
//!DESC [Fast_Guided_enh_rgb_RT] V-Box coef
//!WIDTH FGF_COEF_H.w
//!HEIGHT FGF_COEF_H.h
//!WHEN STR

#define R (SUBSAM > 1 ? RAD / SUBSAM : RAD)

vec4 hook() {

	vec4 sum = vec4(0.0);
	int r = int(R);
	float count = 0.0;
	for (int y = -r; y <= r; y++) {
		sum += FGF_COEF_H_texOff(vec2(0.0, float(y)));
		count += 1.0;
	}
	return sum / count;

}

//!HOOK MAIN
//!BIND HOOKED
//!BIND FGF_MEAN_COEF
//!DESC [Fast_Guided_enh_rgb_RT] Fin
//!WHEN STR

vec4 hook() {

	vec4 coef = FGF_MEAN_COEF_texOff(0);
	vec3 mean_a = coef.rgb;
	float mean_b = coef.a;
	vec4 orig = HOOKED_texOff(0);
	vec3 I = orig.rgb;
	float p = dot(I, vec3(0.2126, 0.7152, 0.0722));
	float q = dot(mean_a, I) + mean_b;

	float detail = p - q;
	float enhanced_luma = p + STR * detail;
	float ratio = (p > 0.001) ? (enhanced_luma / p) : 1.0;
	vec3 result = I * ratio;
	return vec4(clamp(result, 0.0, 1.0), orig.a);

}

