// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!DESC [color_alt_rgb]
//!HOOK MAINPRESUB
//!BIND HOOKED

vec4 hook()
{

	vec4 color = HOOKED_texOff(0);
	color.rgb = vec3(1.0) - color.rgb;

	return color;

}

