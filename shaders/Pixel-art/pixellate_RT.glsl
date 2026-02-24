// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM PXS
//!TYPE float
//!MINIMUM 0.01
//!MAXIMUM 128.0
1.0

//!PARAM BLUR
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.0


//!HOOK MAIN
//!BIND HOOKED
//!DESC [pixellate_RT]
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h

vec4 hook() {

	vec2 texelSize = HOOKED_pt;
	vec2 scaledTexelSize = texelSize * PXS;
	vec2 range = scaledTexelSize / 2.0 * 0.999;
	vec2 pos = HOOKED_pos;
	vec2 quantizedPos = (floor(pos / scaledTexelSize) + 0.5) * scaledTexelSize;
	vec3 sharpColor = HOOKED_tex(quantizedPos).rgb;

	if (BLUR < 0.001) {
		return vec4(sharpColor, 1.0);
	}

	float left = pos.x - range.x;
	float top = pos.y - range.y;
	float right = pos.x + range.x;
	float bottom = pos.y + range.y;

	vec3 topLeftColor = HOOKED_tex(
		(floor(vec2(left, top) / scaledTexelSize) + 0.5) * scaledTexelSize
	).rgb;
	vec3 topRightColor = HOOKED_tex(
		(floor(vec2(right, top) / scaledTexelSize) + 0.5) * scaledTexelSize
	).rgb;
	vec3 bottomLeftColor = HOOKED_tex(
		(floor(vec2(left, bottom) / scaledTexelSize) + 0.5) * scaledTexelSize
	).rgb;
	vec3 bottomRightColor = HOOKED_tex(
		(floor(vec2(right, bottom) / scaledTexelSize) + 0.5) * scaledTexelSize
	).rgb;
	vec2 border = clamp(
		floor(pos / scaledTexelSize + 0.5) * scaledTexelSize,
		vec2(left, top),
		vec2(right, bottom)
	);

	float totalArea = 4.0 * range.x * range.y;
	vec3 smoothColor = vec3(0.0);
	smoothColor += ((border.x - left) * (border.y - top) / totalArea) * topLeftColor;
	smoothColor += ((right - border.x) * (border.y - top) / totalArea) * topRightColor;
	smoothColor += ((border.x - left) * (bottom - border.y) / totalArea) * bottomLeftColor;
	smoothColor += ((right - border.x) * (bottom - border.y) / totalArea) * bottomRightColor;
	vec3 finalColor = mix(sharpColor, smoothColor, BLUR);

	return vec4(finalColor, 1.0);

}

