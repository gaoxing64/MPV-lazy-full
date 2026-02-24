// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- RAW ver.
  https://www.shadertoy.com/view/7ldyDf

*/


//!PARAM PRESET
//!TYPE DEFINE
//!MINIMUM 1
//!MAXIMUM 2
1

//!PARAM SPD
//!TYPE float
//!MINIMUM 1.0
//!MAXIMUM 1000.0
60.0

//!PARAM SMTH
//!TYPE DEFINE
//!MINIMUM 0
//!MAXIMUM 2
1


//!HOOK OUTPUT
//!BIND HOOKED
//!DESC [MandelbrotSet_p3d_FX_RT]

#define COLORSCHEME      PRESET
#define AA               (SMTH + 1)
#define iResolution      HOOKED_size
#define iTime            (float(frame) / SPD)

#if (COLORSCHEME == 1)
#define INVERTED_GRADIENT
#define MAXITER_POT      300
#define MAXITER_NORMAL   500
#else
#define MAXITER_POT      180
#define MAXITER_NORMAL   300
#endif

#define ER_POT           100000.0
#define ER_NORMAL        100.0
#define M_PI             3.14159265358979323846
#define NUMBER_OF_POINTS 8

const vec3 coordinates[NUMBER_OF_POINTS] = vec3[NUMBER_OF_POINTS](
	vec3(-0.774693,     0.1242263647, 14.0),
	vec3(-0.58013,      0.48874,      14.0),
	vec3(-1.77,         0.0,          5.0),
	vec3(-0.744166858,  0.13150536,   13.0),
	vec3( 0.41646,     -0.210156433,  16.0),
	vec3(-0.7455,       0.1126,       10.0),
	vec3(-1.1604872,    0.2706806,    12.0),
	vec3(-0.735805,     0.196726496,  15.0)
);
const float centerDuration = 31.0;
const float rotationDuration = 53.0;
const vec2 defaultCenter = vec2(-0.6, 0.0);

#if (COLORSCHEME == 1)
const vec4 insideColor = vec4(0.0, 0.0, 0.0, 1.0);
#else
const vec4 insideColor = vec4(0.1, 0.12, 0.15, 1.0);
#endif

vec3 palette(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d) {
	return a + b * cos(2.0 * M_PI * (c * t + d));
}

vec3 awesomePalette(in float t) {
	return palette(t, vec3(0.5), vec3(0.5), vec3(1.0), vec3(0.0, 0.1, 0.2));
}

vec3 rainbow(in float t) {
	return palette(t, vec3(0.5), vec3(0.5), vec3(1.0), vec3(0.0, 0.33, 0.67));
}

vec2 cmul(vec2 a, vec2 b) {
	return vec2(a.x * b.x - a.y * b.y, a.x * b.y + b.x * a.y);
}

vec2 cpow2(in vec2 c) {
	return vec2(c.x * c.x - c.y * c.y, 2.0 * c.x * c.y);
}

vec2 cdiv(in vec2 a, in vec2 b) {
	return vec2((a.x * b.x + a.y * b.y)/(b.x * b.x + b.y * b.y),(a.y * b.x - a.x * b.y)/(b.x * b.x + b.y * b.y));
}

mat2 rotate(float theta) {
	float s = sin(theta);
	float c = cos(theta);
	return mat2(c, -s, s, c);
}

float potential(in vec2 c) {
	vec2 z = vec2(0.0);
	for (int iter = 0; iter < MAXITER_POT; ++iter) {
		z = cpow2(z) + c;
		float absZ = length(z);
		if (absZ > ER_POT) {
			return abs(log(log2(absZ)) - (float(iter) + 1.0) * log(2.0));
		}
	}
	return -1.0;
}

float reflection(in vec2 c, float time) {
	vec2 z = vec2(0.0);
	vec2 dc = vec2(0.0);
	const float h2 = 1.5;
	vec2 angle = normalize(vec2(-1.0, 1.0)) * rotate(time / rotationDuration);
	for (int i = 0; i < MAXITER_NORMAL; i++) {
		dc = 2.0 * cmul(dc, z) + vec2(1.0, 0.0);
		z = cpow2(z) + c;
		if (length(z) > ER_NORMAL) {
			vec2 slope = normalize(cdiv(z, dc));
			float reflection = dot(slope, angle) + h2;
			reflection = reflection / (1.0 + h2);
			return max(reflection, 0.0);
		}
	}
	return -1.0;
}

vec4 render(in vec2 fragCoord, float time, vec2 currentCenter, float currentZoom) {
	vec2 uv = (fragCoord - iResolution.xy * 0.5) / min(iResolution.x, iResolution.y) * 2.0;
	float mixFactor = 1.0 - (0.5 + 0.5 * cos(time / centerDuration * 2.0 * M_PI));
	float zoom = exp2(-currentZoom * mixFactor);
	float maxZoom = exp2(-currentZoom);
	vec2 c = mix(currentCenter, defaultCenter, zoom / (1.0 - maxZoom) - maxZoom) + uv * zoom * rotate(time / rotationDuration);
	float pot = potential(c);
	float ref = reflection(c, time);
	float intensity;

#ifdef INVERTED_GRADIENT
	intensity = 1.0 - sqrt(fract(pot));
	intensity = mix(intensity, ref, 0.5);
#else
	intensity = 0.7 * (fract(pot) * ref) + 0.3;
#endif

	vec4 fragColor;
#if (COLORSCHEME == 1)
	vec3 color = awesomePalette(time / 50.0 + pot / 40.0);
	if (ref < 0.0) {
		fragColor = insideColor;
	} else {
		fragColor = vec4(
			color * intensity +
			vec3(intensity) * 0.3 +
			clamp(ref - 0.5, 0.0, 1.0) * pow((1.0 - fract(pot)), 30.0),
		1.0);
		fragColor = clamp(fragColor, 0.0, 1.0);
	}
#else
	vec3 color = rainbow(pot / 20.0);
	if (pot < 0.0) {
		color = insideColor.rgb * min((ref + 0.5), 1.0);
	} else {
		color = color * intensity;
	}
	fragColor = vec4(color, 1.0);
#endif
	return fragColor;
}

vec4 hook() {

	float time = iTime + centerDuration / 2.0 - 7.0;
	int centerIndex = int(time / centerDuration) % NUMBER_OF_POINTS;
	vec2 currentCenter = coordinates[centerIndex].xy;
	float currentZoom = coordinates[centerIndex].z;
	vec2 fragCoord = HOOKED_pos * HOOKED_size;
	vec4 finalColor = vec4(0.0);

#if (AA > 1)
	const float fraction = 1.0 / float(AA);
	const float fraction2 = fraction / float(AA);
	for (int i = 0; i < AA; i++) {
		for (int j = 0; j < AA; j++) {
			vec2 shift = vec2(
				float(i) * fraction + float(AA - j - 1) * fraction2,
				float(j) * fraction + float(i) * fraction2
			);
			vec4 color = render(fragCoord + shift, time, currentCenter, currentZoom);
			finalColor += clamp(color, 0.0, 1.0);
		}
	}
	return finalColor / float(AA * AA);
#else
	return render(fragCoord, time, currentCenter, currentZoom);
#endif

}

