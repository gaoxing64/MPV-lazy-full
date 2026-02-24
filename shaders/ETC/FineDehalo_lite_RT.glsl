// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- RAW ver.
  http://avisynth.nl/index.php/FineDehalo

*/


//!PARAM RX
//!TYPE float
//!MINIMUM 1.0
//!MAXIMUM 4.0
2.0

//!PARAM RY
//!TYPE float
//!MINIMUM 1.0
//!MAXIMUM 4.0
2.0

//!PARAM THMI
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 255.0
80.0

//!PARAM THMA
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 255.0
128.0

//!PARAM THLIMI
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 255.0
50.0

//!PARAM THLIMA
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 255.0
100.0

//!PARAM STR_D
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 2.0
1.0

//!PARAM STR_B
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 2.0
1.0

//!PARAM SENS_L
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 100.0
50.0

//!PARAM SENS_H
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 100.0
50.0

//!PARAM DEBUG
//!TYPE DEFINE
//!MINIMUM 0
//!MAXIMUM 4
0


//!HOOK LUMA
//!BIND HOOKED
//!SAVE EDGE_DETECT
//!DESC [FineDehalo_lite_RT] Edge Detection (Prewitt)

vec4 hook() {

	// Prewitt kernels - 4 directions
	// Kernel 1: [ 1, 1, 0 /  1, 0,-1 /  0,-1,-1]
	// Kernel 2: [ 1, 1, 1 /  0, 0, 0 / -1,-1,-1]
	// Kernel 3: [ 1, 0,-1 /  1, 0,-1 /  1, 0,-1]
	// Kernel 4: [ 0,-1,-1 /  1, 0,-1 /  1, 1, 0]
	float c00 = HOOKED_texOff(vec2(-1, -1)).x;
	float c10 = HOOKED_texOff(vec2( 0, -1)).x;
	float c20 = HOOKED_texOff(vec2( 1, -1)).x;
	float c01 = HOOKED_texOff(vec2(-1,  0)).x;
	float c11 = HOOKED_texOff(vec2( 0,  0)).x;
	float c21 = HOOKED_texOff(vec2( 1,  0)).x;
	float c02 = HOOKED_texOff(vec2(-1,  1)).x;
	float c12 = HOOKED_texOff(vec2( 0,  1)).x;
	float c22 = HOOKED_texOff(vec2( 1,  1)).x;

	float k1 = abs(c00 + c10 + c01 - c21 - c12 - c22);
	float k2 = abs(c00 + c10 + c20 - c02 - c12 - c22);
	float k3 = abs(c00 + c01 + c02 - c20 - c21 - c22);
	float k4 = abs(c10 + c20 + c21 - c01 - c02 - c12);

	float edge = max(max(k1, k2), max(k3, k4));
	return vec4(edge, 0.0, 0.0, 1.0);

}

//!HOOK LUMA
//!BIND EDGE_DETECT
//!SAVE STRONG_MASK
//!DESC [FineDehalo_lite_RT] Strong Edge Mask

vec4 hook() {

	float edge = EDGE_DETECT_texOff(vec2(0)).x;
	float thmi = THMI / 255.0;
	float thma = THMA / 255.0;
	float strong = clamp((edge - thmi) / max(thma - thmi, 0.0001), 0.0, 1.0);
	return vec4(strong, 0.0, 0.0, 1.0);

}

//!HOOK LUMA
//!BIND EDGE_DETECT
//!SAVE LIGHT_MASK
//!DESC [FineDehalo_lite_RT] Light Edge Mask

vec4 hook() {

	float edge = EDGE_DETECT_texOff(vec2(0)).x;
	float thlimi = THLIMI / 255.0;
	float thlima = THLIMA / 255.0;
	float light = clamp((edge - thlimi) / max(thlima - thlimi, 0.0001), 0.0, 1.0);
	return vec4(light, 0.0, 0.0, 1.0);

}

//!HOOK LUMA
//!BIND STRONG_MASK
//!SAVE LARGE_MASK_1
//!DESC [FineDehalo_lite_RT] Expand Strong Mask 1
//!WHEN RX 1 >

vec4 hook() {

	float maxVal = STRONG_MASK_texOff(vec2(0)).x;
	maxVal = max(maxVal, STRONG_MASK_texOff(vec2(-1, -1)).x);
	maxVal = max(maxVal, STRONG_MASK_texOff(vec2( 0, -1)).x);
	maxVal = max(maxVal, STRONG_MASK_texOff(vec2( 1, -1)).x);
	maxVal = max(maxVal, STRONG_MASK_texOff(vec2(-1,  0)).x);
	maxVal = max(maxVal, STRONG_MASK_texOff(vec2( 1,  0)).x);
	maxVal = max(maxVal, STRONG_MASK_texOff(vec2(-1,  1)).x);
	maxVal = max(maxVal, STRONG_MASK_texOff(vec2( 0,  1)).x);
	maxVal = max(maxVal, STRONG_MASK_texOff(vec2( 1,  1)).x);
	return vec4(maxVal, 0.0, 0.0, 1.0);

}

//!HOOK LUMA
//!BIND STRONG_MASK
//!BIND LARGE_MASK_1
//!SAVE LARGE_MASK
//!DESC [FineDehalo_lite_RT] Expand Strong Mask 2

vec4 hook() {

	// Use LARGE_MASK_1 if RX > 1, or STRONG_MASK directly
	float maxVal;
	if (RX > 1.0) {
		maxVal = LARGE_MASK_1_texOff(vec2(0)).x;
		maxVal = max(maxVal, LARGE_MASK_1_texOff(vec2(-1, -1)).x);
		maxVal = max(maxVal, LARGE_MASK_1_texOff(vec2( 0, -1)).x);
		maxVal = max(maxVal, LARGE_MASK_1_texOff(vec2( 1, -1)).x);
		maxVal = max(maxVal, LARGE_MASK_1_texOff(vec2(-1,  0)).x);
		maxVal = max(maxVal, LARGE_MASK_1_texOff(vec2( 1,  0)).x);
		maxVal = max(maxVal, LARGE_MASK_1_texOff(vec2(-1,  1)).x);
		maxVal = max(maxVal, LARGE_MASK_1_texOff(vec2( 0,  1)).x);
		maxVal = max(maxVal, LARGE_MASK_1_texOff(vec2( 1,  1)).x);
	} else {
		maxVal = STRONG_MASK_texOff(vec2(0)).x;
		maxVal = max(maxVal, STRONG_MASK_texOff(vec2(-1, -1)).x);
		maxVal = max(maxVal, STRONG_MASK_texOff(vec2( 0, -1)).x);
		maxVal = max(maxVal, STRONG_MASK_texOff(vec2( 1, -1)).x);
		maxVal = max(maxVal, STRONG_MASK_texOff(vec2(-1,  0)).x);
		maxVal = max(maxVal, STRONG_MASK_texOff(vec2( 1,  0)).x);
		maxVal = max(maxVal, STRONG_MASK_texOff(vec2(-1,  1)).x);
		maxVal = max(maxVal, STRONG_MASK_texOff(vec2( 0,  1)).x);
		maxVal = max(maxVal, STRONG_MASK_texOff(vec2( 1,  1)).x);
	}
	return vec4(maxVal, 0.0, 0.0, 1.0);

}

//!HOOK LUMA
//!BIND LIGHT_MASK
//!SAVE SHRINK_EXP_1
//!DESC [FineDehalo_lite_RT] Expand Light Mask 1
//!WHEN RX 1 >

vec4 hook() {

	float maxVal = LIGHT_MASK_texOff(vec2(0)).x;
	// Ellipse mode: 4-connected for first pass when (sw % 3) != 1
	// Using full 8-connected for simplicity
	maxVal = max(maxVal, LIGHT_MASK_texOff(vec2(-1, -1)).x);
	maxVal = max(maxVal, LIGHT_MASK_texOff(vec2( 0, -1)).x);
	maxVal = max(maxVal, LIGHT_MASK_texOff(vec2( 1, -1)).x);
	maxVal = max(maxVal, LIGHT_MASK_texOff(vec2(-1,  0)).x);
	maxVal = max(maxVal, LIGHT_MASK_texOff(vec2( 1,  0)).x);
	maxVal = max(maxVal, LIGHT_MASK_texOff(vec2(-1,  1)).x);
	maxVal = max(maxVal, LIGHT_MASK_texOff(vec2( 0,  1)).x);
	maxVal = max(maxVal, LIGHT_MASK_texOff(vec2( 1,  1)).x);
	return vec4(maxVal, 0.0, 0.0, 1.0);

}

//!HOOK LUMA
//!BIND LIGHT_MASK
//!BIND SHRINK_EXP_1
//!SAVE SHRINK_EXP
//!DESC [FineDehalo_lite_RT] Expand Light Mask 2

vec4 hook() {

	float maxVal;
	if (RX > 1.0) {
		maxVal = SHRINK_EXP_1_texOff(vec2(0)).x;
		maxVal = max(maxVal, SHRINK_EXP_1_texOff(vec2(-1, -1)).x);
		maxVal = max(maxVal, SHRINK_EXP_1_texOff(vec2( 0, -1)).x);
		maxVal = max(maxVal, SHRINK_EXP_1_texOff(vec2( 1, -1)).x);
		maxVal = max(maxVal, SHRINK_EXP_1_texOff(vec2(-1,  0)).x);
		maxVal = max(maxVal, SHRINK_EXP_1_texOff(vec2( 1,  0)).x);
		maxVal = max(maxVal, SHRINK_EXP_1_texOff(vec2(-1,  1)).x);
		maxVal = max(maxVal, SHRINK_EXP_1_texOff(vec2( 0,  1)).x);
		maxVal = max(maxVal, SHRINK_EXP_1_texOff(vec2( 1,  1)).x);
	} else {
		maxVal = LIGHT_MASK_texOff(vec2(0)).x;
		maxVal = max(maxVal, LIGHT_MASK_texOff(vec2(-1, -1)).x);
		maxVal = max(maxVal, LIGHT_MASK_texOff(vec2( 0, -1)).x);
		maxVal = max(maxVal, LIGHT_MASK_texOff(vec2( 1, -1)).x);
		maxVal = max(maxVal, LIGHT_MASK_texOff(vec2(-1,  0)).x);
		maxVal = max(maxVal, LIGHT_MASK_texOff(vec2( 1,  0)).x);
		maxVal = max(maxVal, LIGHT_MASK_texOff(vec2(-1,  1)).x);
		maxVal = max(maxVal, LIGHT_MASK_texOff(vec2( 0,  1)).x);
		maxVal = max(maxVal, LIGHT_MASK_texOff(vec2( 1,  1)).x);
	}
	return vec4(maxVal, 0.0, 0.0, 1.0);

}

//!HOOK LUMA
//!BIND SHRINK_EXP
//!SAVE SHRINK_AMP
//!DESC [FineDehalo_lite_RT] Amplify Exclusion Mask

vec4 hook() {

	float val = SHRINK_EXP_texOff(vec2(0)).x;
	val = clamp(val * 4.0, 0.0, 1.0);
	return vec4(val, 0.0, 0.0, 1.0);

}

//!HOOK LUMA
//!BIND SHRINK_AMP
//!SAVE SHRINK_MIN_1
//!DESC [FineDehalo_lite_RT] Shrink Exclusion Mask i1
//!WHEN RX 1 >

vec4 hook() {

	float minVal = SHRINK_AMP_texOff(vec2(0)).x;
	// 8-connected minimum
	minVal = min(minVal, SHRINK_AMP_texOff(vec2(-1, -1)).x);
	minVal = min(minVal, SHRINK_AMP_texOff(vec2( 0, -1)).x);
	minVal = min(minVal, SHRINK_AMP_texOff(vec2( 1, -1)).x);
	minVal = min(minVal, SHRINK_AMP_texOff(vec2(-1,  0)).x);
	minVal = min(minVal, SHRINK_AMP_texOff(vec2( 1,  0)).x);
	minVal = min(minVal, SHRINK_AMP_texOff(vec2(-1,  1)).x);
	minVal = min(minVal, SHRINK_AMP_texOff(vec2( 0,  1)).x);
	minVal = min(minVal, SHRINK_AMP_texOff(vec2( 1,  1)).x);
	return vec4(minVal, 0.0, 0.0, 1.0);

}

//!HOOK LUMA
//!BIND SHRINK_AMP
//!BIND SHRINK_MIN_1
//!SAVE SHRINK_MIN
//!DESC [FineDehalo_lite_RT] Shrink Exclusion Mask i2

vec4 hook() {

	float minVal;
	if (RX > 1.0) {
		minVal = SHRINK_MIN_1_texOff(vec2(0)).x;
		minVal = min(minVal, SHRINK_MIN_1_texOff(vec2(-1, -1)).x);
		minVal = min(minVal, SHRINK_MIN_1_texOff(vec2( 0, -1)).x);
		minVal = min(minVal, SHRINK_MIN_1_texOff(vec2( 1, -1)).x);
		minVal = min(minVal, SHRINK_MIN_1_texOff(vec2(-1,  0)).x);
		minVal = min(minVal, SHRINK_MIN_1_texOff(vec2( 1,  0)).x);
		minVal = min(minVal, SHRINK_MIN_1_texOff(vec2(-1,  1)).x);
		minVal = min(minVal, SHRINK_MIN_1_texOff(vec2( 0,  1)).x);
		minVal = min(minVal, SHRINK_MIN_1_texOff(vec2( 1,  1)).x);
	} else {
		minVal = SHRINK_AMP_texOff(vec2(0)).x;
		minVal = min(minVal, SHRINK_AMP_texOff(vec2(-1, -1)).x);
		minVal = min(minVal, SHRINK_AMP_texOff(vec2( 0, -1)).x);
		minVal = min(minVal, SHRINK_AMP_texOff(vec2( 1, -1)).x);
		minVal = min(minVal, SHRINK_AMP_texOff(vec2(-1,  0)).x);
		minVal = min(minVal, SHRINK_AMP_texOff(vec2( 1,  0)).x);
		minVal = min(minVal, SHRINK_AMP_texOff(vec2(-1,  1)).x);
		minVal = min(minVal, SHRINK_AMP_texOff(vec2( 0,  1)).x);
		minVal = min(minVal, SHRINK_AMP_texOff(vec2( 1,  1)).x);
	}
	return vec4(minVal, 0.0, 0.0, 1.0);

}

//!HOOK LUMA
//!BIND SHRINK_MIN
//!SAVE SHRINK_BLUR_1
//!DESC [FineDehalo_lite_RT] Smooth Shrink Mask pass1

vec4 hook() {

	// 3x3 Gaussian-like blur [1,2,1 / 2,4,2 / 1,2,1] / 16
	float sum = 0.0;
	sum += SHRINK_MIN_texOff(vec2(-1, -1)).x * 1.0;
	sum += SHRINK_MIN_texOff(vec2( 0, -1)).x * 2.0;
	sum += SHRINK_MIN_texOff(vec2( 1, -1)).x * 1.0;
	sum += SHRINK_MIN_texOff(vec2(-1,  0)).x * 2.0;
	sum += SHRINK_MIN_texOff(vec2( 0,  0)).x * 4.0;
	sum += SHRINK_MIN_texOff(vec2( 1,  0)).x * 2.0;
	sum += SHRINK_MIN_texOff(vec2(-1,  1)).x * 1.0;
	sum += SHRINK_MIN_texOff(vec2( 0,  1)).x * 2.0;
	sum += SHRINK_MIN_texOff(vec2( 1,  1)).x * 1.0;
	sum /= 16.0;
	return vec4(sum, 0.0, 0.0, 1.0);

}

//!HOOK LUMA
//!BIND SHRINK_BLUR_1
//!SAVE SHRINK_SMOOTH
//!DESC [FineDehalo_lite_RT] Smooth Shrink Mask pass2

vec4 hook() {

	float sum = 0.0;
	sum += SHRINK_BLUR_1_texOff(vec2(-1, -1)).x * 1.0;
	sum += SHRINK_BLUR_1_texOff(vec2( 0, -1)).x * 2.0;
	sum += SHRINK_BLUR_1_texOff(vec2( 1, -1)).x * 1.0;
	sum += SHRINK_BLUR_1_texOff(vec2(-1,  0)).x * 2.0;
	sum += SHRINK_BLUR_1_texOff(vec2( 0,  0)).x * 4.0;
	sum += SHRINK_BLUR_1_texOff(vec2( 1,  0)).x * 2.0;
	sum += SHRINK_BLUR_1_texOff(vec2(-1,  1)).x * 1.0;
	sum += SHRINK_BLUR_1_texOff(vec2( 0,  1)).x * 2.0;
	sum += SHRINK_BLUR_1_texOff(vec2( 1,  1)).x * 1.0;
	sum /= 16.0;
	return vec4(sum, 0.0, 0.0, 1.0);

}

//!HOOK LUMA
//!BIND HOOKED
//!SAVE HALOS
//!DESC [FineDehalo_lite_RT] Generate Halos (Blur)

vec4 hook() {

	// Approximate bicubic downscale/upscale with large kernel Gaussian blur
	// Kernel size based on RX/RY - using 5x5 weighted average
	float sigma = (RX + RY) / 2.0;
	// 5x5 Gaussian-like blur for halo simulation
	float sum = 0.0;
	float weight = 0.0;

	for (int y = -2; y <= 2; y++) {
		for (int x = -2; x <= 2; x++) {
			float d = sqrt(float(x*x + y*y));
			float w = exp(-d * d / (2.0 * sigma * sigma));
			sum += HOOKED_texOff(vec2(x, y)).x * w;
			weight += w;
		}
	}

	float halos = sum / weight;
	return vec4(halos, 0.0, 0.0, 1.0);

}

//!HOOK LUMA
//!BIND HOOKED
//!BIND HALOS
//!SAVE DEHALO_SENS
//!DESC [FineDehalo_lite_RT] DeHalo Sensitivity

vec4 hook() {

	// Compute local range: are = max - min of original
	float maxOrig = HOOKED_texOff(vec2(0)).x;
	float minOrig = maxOrig;

	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			float v = HOOKED_texOff(vec2(x, y)).x;
			maxOrig = max(maxOrig, v);
			minOrig = min(minOrig, v);
		}
	}
	float are = maxOrig - minOrig;

	// Compute local range of halos: ugly = max - min of halos
	float maxHalo = HALOS_texOff(vec2(0)).x;
	float minHalo = maxHalo;

	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			float v = HALOS_texOff(vec2(x, y)).x;
			maxHalo = max(maxHalo, v);
			minHalo = min(minHalo, v);
		}
	}
	float ugly = maxHalo - minHalo;

	// Sensitivity formula from DeHalo_alpha:
	// so = (ugly - are) / (ugly + epsilon) * 255 * (lowsens / 255) - (256/512) * highsens/100
	// Simplified for [0,1] range
	float lowsens = SENS_L / 100.0;
	float highsens = SENS_H / 100.0;

	float so = (ugly - are) / (ugly + 0.000001);
	so = so - lowsens;
	so = so * (are + 1.0) / 2.0 * highsens + so * (1.0 - highsens);
	so = clamp(so, 0.0, 1.0);

	return vec4(so, 0.0, 0.0, 1.0);

}

//!HOOK LUMA
//!BIND HOOKED
//!BIND HALOS
//!BIND DEHALO_SENS
//!SAVE DEHALOED
//!DESC [FineDehalo_lite_RT] DeHalo Apply

vec4 hook() {

	float orig = HOOKED_texOff(vec2(0)).x;
	float halos = HALOS_texOff(vec2(0)).x;
	float so = DEHALO_SENS_texOff(vec2(0)).x;
	// lets = mix(halos, orig, so)
	float lets = mix(halos, orig, so);
	// Find min/max of lets in 3x3 neighborhood
	float letsMax = lets;
	float letsMin = lets;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			float h = HALOS_texOff(vec2(x, y)).x;
			float s = DEHALO_SENS_texOff(vec2(x, y)).x;
			float l = mix(h, HOOKED_texOff(vec2(x, y)).x, s);
			letsMax = max(letsMax, l);
			letsMin = min(letsMin, l);
		}
	}

	// Clamp original between lets min/max (Repair mode 1 approximation)
	float remove = clamp(orig, letsMin, letsMax);
	// Apply darkstr/brightstr
	float diff = orig - remove;
	float result;
	if (diff < 0.0) {
		// Dark halo (orig < remove) - orig was darker, so we're brightening
		result = orig - diff * STR_D;
	} else {
		// Bright halo (orig > remove) - orig was brighter, so we're darkening
		result = orig - diff * STR_B;
	}

	return vec4(result, 0.0, 0.0, 1.0);

}

//!HOOK LUMA
//!BIND LARGE_MASK
//!BIND STRONG_MASK
//!BIND SHRINK_SMOOTH
//!SAVE OUTSIDE_RAW
//!DESC [FineDehalo_lite_RT] Build Outside Mask

vec4 hook() {

	float large = LARGE_MASK_texOff(vec2(0)).x;
	float strong = STRONG_MASK_texOff(vec2(0)).x;
	float shrink = SHRINK_SMOOTH_texOff(vec2(0)).x;
	// shr_med = max(strong, shrink) for exclusion
	float shr_med = max(strong, shrink);
	// outside = (large - shr_med) * 2
	float outside = clamp((large - shr_med) * 2.0, 0.0, 1.0);
	return vec4(outside, 0.0, 0.0, 1.0);

}

//!HOOK LUMA
//!BIND OUTSIDE_RAW
//!SAVE OUTSIDE_MASK
//!DESC [FineDehalo_lite_RT] Smooth Outside Mask

vec4 hook() {

	// 3x3 blur
	float sum = 0.0;
	sum += OUTSIDE_RAW_texOff(vec2(-1, -1)).x * 1.0;
	sum += OUTSIDE_RAW_texOff(vec2( 0, -1)).x * 2.0;
	sum += OUTSIDE_RAW_texOff(vec2( 1, -1)).x * 1.0;
	sum += OUTSIDE_RAW_texOff(vec2(-1,  0)).x * 2.0;
	sum += OUTSIDE_RAW_texOff(vec2( 0,  0)).x * 4.0;
	sum += OUTSIDE_RAW_texOff(vec2( 1,  0)).x * 2.0;
	sum += OUTSIDE_RAW_texOff(vec2(-1,  1)).x * 1.0;
	sum += OUTSIDE_RAW_texOff(vec2( 0,  1)).x * 2.0;
	sum += OUTSIDE_RAW_texOff(vec2( 1,  1)).x * 1.0;
	sum /= 16.0;
	// Amplify x2
	float outside = clamp(sum * 2.0, 0.0, 1.0);
	return vec4(outside, 0.0, 0.0, 1.0);

}

//!HOOK LUMA
//!BIND HOOKED
//!BIND DEHALOED
//!BIND OUTSIDE_MASK
//!BIND EDGE_DETECT
//!BIND STRONG_MASK
//!BIND SHRINK_SMOOTH
//!DESC [FineDehalo_lite_RT] Final Merge

vec4 hook() {

#if (DEBUG == 1)
	return vec4(OUTSIDE_MASK_texOff(vec2(0)).x, 0.0, 0.0, 1.0);
#elif (DEBUG == 2)
	return vec4(SHRINK_SMOOTH_texOff(vec2(0)).x, 0.0, 0.0, 1.0);
#elif (DEBUG == 3)
	return vec4(EDGE_DETECT_texOff(vec2(0)).x, 0.0, 0.0, 1.0);
#elif (DEBUG == 4)
	return vec4(STRONG_MASK_texOff(vec2(0)).x, 0.0, 0.0, 1.0);
#endif

	float orig = HOOKED_texOff(vec2(0)).x;
	float dehaloed = DEHALOED_texOff(vec2(0)).x;
	float outside = OUTSIDE_MASK_texOff(vec2(0)).x;
	// Final merge: apply dehaloed only where outside mask is active
	float result = mix(orig, dehaloed, outside);

	return vec4(result, 0.0, 0.0, 1.0);

}

