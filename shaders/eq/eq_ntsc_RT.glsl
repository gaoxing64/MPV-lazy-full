// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- RAW ver.
  https://github.com/libretro/glsl-shaders/blob/master/misc/shaders/ntsc-colors.glsl

*/


//!PARAM CI
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.8


//!HOOK MAIN
//!BIND HOOKED
//!DESC [eq_ntsc_RT]
//!WHEN CI

vec3 DecodeGamma(vec3 color, float gamma)
{
	color = clamp(color, 0.0, 1.0);
	color.r = (color.r <= 0.00313066844250063) ?
		color.r * 12.92 : 1.055 * pow(color.r, 1.0 / gamma) - 0.055;
	color.g = (color.g <= 0.00313066844250063) ?
		color.g * 12.92 : 1.055 * pow(color.g, 1.0 / gamma) - 0.055;
	color.b = (color.b <= 0.00313066844250063) ?
		color.b * 12.92 : 1.055 * pow(color.b, 1.0 / gamma) - 0.055;
	return color;
}

vec3 RGBtoXYZ(vec3 RGB)
{
	mat3 m = mat3(
		  0.6068909,  0.1735011,  0.2003480,
		  0.2989164,  0.5865990,  0.1144845,
		  0.0000000,  0.0660957,  1.1162243);
	return RGB * m;
}

vec3 XYZtoSRGB(vec3 XYZ)
{
	mat3 m = mat3(
		  3.2404542, -1.5371385, -0.4985314,
		 -0.9692660,  1.8760108,  0.0415560,
		  0.0556434, -0.2040259,  1.0572252);
	return XYZ * m;
}

vec3 NTSC(vec3 c)
{
	vec3 safe_c = max(c, 0.0);
	vec3 v = vec3(
		pow(safe_c.r, 2.2),
		pow(safe_c.g, 2.2),
		pow(safe_c.b, 2.2)
	);
	return RGBtoXYZ(v);
}

vec3 sRGB(vec3 c)
{
	vec3 v = XYZtoSRGB(c);
	v = clamp(v, 0.0, 1.0);
	return DecodeGamma(v, 2.4);
}

vec3 NTSCtoSRGB(vec3 c)
{
	return sRGB(NTSC(c));
}

vec4 hook()
{

	vec4 color = HOOKED_texOff(0);
	vec3 safe_color = max(color.rgb, 0.0);
	vec3 converted = NTSCtoSRGB(safe_color);
	color.rgb = mix(color.rgb, converted, CI);
	return color;

}

