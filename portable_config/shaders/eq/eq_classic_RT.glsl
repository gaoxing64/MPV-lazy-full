// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM PS
//!TYPE int
//!MINIMUM 0
//!MAXIMUM 4
2

//!PARAM CTRS
//!TYPE float
//!MINIMUM 0.5
//!MAXIMUM 2.0
1.0

//!PARAM SEPIA
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.1

//!PARAM GRAIN
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 0.2
0.05

//!PARAM SOFT
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 3.0
1.2


//!HOOK MAIN
//!BIND HOOKED
//!DESC [eq_classic_RT]
//!WHEN PS

float rand(vec2 co) {
	return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec4 hook() {

	vec3 rgb = HOOKED_tex(HOOKED_pos).rgb;

	vec3 factor;
	if (PS == 1) {
		factor = vec3(0.299, 0.587, 0.114);
	} else if (PS == 2) {
		factor = vec3(0.2126, 0.7152, 0.0722);
	} else if (PS == 3) {
		factor = vec3(0.2095, 0.7216, 0.0689);
	} else if (PS == 4) {
		factor = vec3(0.2627, 0.6780, 0.0593);
	}

	float intensity = dot(rgb, factor);
	intensity = (intensity - 0.5) * CTRS + 0.5;
	intensity = clamp(intensity, 0.0, 1.0);

	vec3 sepiaColor = vec3(1.0, 0.8, 0.6);
	vec3 finalColor = mix(vec3(intensity), intensity * sepiaColor, SEPIA);

	float grain = rand(HOOKED_pos.xy * 100.0) * GRAIN;
	finalColor += grain;

	if (SOFT > 0.0) {
		vec3 softColor = vec3(0.0);
		float totalWeight = 0.0;
		vec2 pixelSize = 1.0 / HOOKED_size;
		for (int x = -1; x <= 1; x++) {
			for (int y = -1; y <= 1; y++) {
				vec2 offset = vec2(x, y) * pixelSize * SOFT;
				vec3 sampleColor = HOOKED_tex(HOOKED_pos + offset).rgb;
				float sampleIntensity = dot(sampleColor, factor);
				float weight = 1.0 / (1.0 + length(vec2(x, y)));
				softColor += sampleIntensity * weight;
				totalWeight += weight;
			}
		}
		softColor /= totalWeight;
		vec3 softSepia = mix(vec3(softColor), softColor * sepiaColor, SEPIA);
		finalColor = mix(finalColor, softSepia, SOFT * 0.5);
	}

	return vec4(clamp(finalColor, 0.0, 1.0), 1.0);

}

