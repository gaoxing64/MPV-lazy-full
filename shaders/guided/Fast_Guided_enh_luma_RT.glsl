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

//!HOOK LUMA
//!BIND HOOKED
//!SAVE GF_DOWN_IP
//!DESC [Fast_Guided_enh_luma_RT] Downsample
//!WIDTH HOOKED.w SUBSAM /
//!HEIGHT HOOKED.h SUBSAM /
//!WHEN STR SUBSAM 1 > *

vec4 hook() {

	float I = HOOKED_texOff(0).x;
	return vec4(I, I, I*I, I*I);

}

//!HOOK LUMA
//!BIND HOOKED
//!SAVE GF_DOWN_IP
//!DESC [Fast_Guided_enh_luma_RT] Prepare
//!WIDTH HOOKED.w
//!HEIGHT HOOKED.h
//!WHEN STR SUBSAM 1 = *

vec4 hook() {

	float I = HOOKED_texOff(0).x;
	return vec4(I, I, I*I, I*I);

}

//!HOOK LUMA
//!BIND GF_DOWN_IP
//!SAVE GF_HBOX
//!DESC [Fast_Guided_enh_luma_RT] H-Box
//!WIDTH GF_DOWN_IP.w
//!HEIGHT GF_DOWN_IP.h
//!WHEN STR

#define R (SUBSAM > 1 ? RAD / SUBSAM : RAD)

vec4 hook() {

	vec4 sum = vec4(0.0);
	int r = int(R);
	float count = 0.0;
	for (int x = -r; x <= r; x++) {
		sum += GF_DOWN_IP_texOff(vec2(float(x), 0.0));
		count += 1.0;
	}
	return sum / count;

}

//!HOOK LUMA
//!BIND GF_HBOX
//!SAVE GF_MEANS
//!DESC [Fast_Guided_enh_luma_RT] V-Box means
//!WIDTH GF_HBOX.w
//!HEIGHT GF_HBOX.h
//!WHEN STR

#define R (SUBSAM > 1 ? RAD / SUBSAM : RAD)

vec4 hook() {

	vec4 sum = vec4(0.0);
	int r = int(R);
	float count = 0.0;
	for (int y = -r; y <= r; y++) {
		sum += GF_HBOX_texOff(vec2(0.0, float(y)));
		count += 1.0;
	}
	return sum / count;

}

//!HOOK LUMA
//!BIND GF_MEANS
//!SAVE GF_AB
//!DESC [Fast_Guided_enh_luma_RT] Coefficients
//!WIDTH GF_MEANS.w
//!HEIGHT GF_MEANS.h
//!WHEN STR

vec4 hook() {

	vec4 means = GF_MEANS_texOff(0);
	float mean_I = means.x;
	float mean_p = means.y;
	float mean_II = means.z;
	float mean_Ip = means.w;
	float var_I = mean_II - mean_I * mean_I;
	float cov_Ip = mean_Ip - mean_I * mean_p;
	float a = cov_Ip / (var_I + EPS);
	float b = mean_p - a * mean_I;
	return vec4(a, b, 0.0, 1.0);

}

//!HOOK LUMA
//!BIND GF_AB
//!SAVE GF_AB_HBOX
//!DESC [Fast_Guided_enh_luma_RT] H-Box ab
//!WIDTH GF_AB.w
//!HEIGHT GF_AB.h
//!WHEN STR

#define R (SUBSAM > 1 ? RAD / SUBSAM : RAD)

vec4 hook() {

	vec4 sum = vec4(0.0);
	int r = int(R);
	float count = 0.0;
	for (int x = -r; x <= r; x++) {
		sum += GF_AB_texOff(vec2(float(x), 0.0));
		count += 1.0;
	}
	return sum / count;

}

//!HOOK LUMA
//!BIND GF_AB_HBOX
//!SAVE GF_AB_MEAN
//!DESC [Fast_Guided_enh_luma_RT] V-Box ab
//!WIDTH GF_AB_HBOX.w
//!HEIGHT GF_AB_HBOX.h
//!WHEN STR

#define R (SUBSAM > 1 ? RAD / SUBSAM : RAD)

vec4 hook() {

	vec4 sum = vec4(0.0);
	int r = int(R);
	float count = 0.0;
	for (int y = -r; y <= r; y++) {
		sum += GF_AB_HBOX_texOff(vec2(0.0, float(y)));
		count += 1.0;
	}
	return sum / count;

}

//!HOOK LUMA
//!BIND HOOKED
//!BIND GF_AB_MEAN
//!DESC [Fast_Guided_enh_luma_RT] Fin
//!WHEN STR

vec4 hook() {

	vec4 ab = GF_AB_MEAN_texOff(0);
	float mean_a = ab.x;
	float mean_b = ab.y;
	float I = HOOKED_texOff(0).x;
	float q = mean_a * I + mean_b;

	float detail = I - q;
	float result = I + STR * detail;
	return vec4(result, 0.0, 0.0, 1.0);

}

