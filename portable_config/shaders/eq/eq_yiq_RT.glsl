// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM TTL
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 3.0
1.0

//!PARAM Y
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 3.0
1.0

//!PARAM I
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 3.0
1.0

//!PARAM Q
//!TYPE float
//!MINIMUM -1.0
//!MAXIMUM 3.0
1.0


//!HOOK MAIN
//!BIND HOOKED
//!BIND LUMA
//!DESC [eq_yiq_RT]
//!WHEN TTL 1.0 == ! Y 1.0 == ! + I 1.0 == ! + Q 1.0 == ! +

const mat3 RGBtoYIQ = mat3(
	0.299,     0.587,     0.114,
	0.595716, -0.274453, -0.321263,
	0.211456, -0.522591,  0.311135
);

const mat3 YIQtoRGB = mat3(
	1.0,  0.95568806036115671171,  0.61985809445637075388,
	1.0, -0.27158179694405859326, -0.64687381613840131330,
	1.0, -1.10817732668266195230,  1.70506455991918171491
);

vec3 offset = vec3(Y, I, Q) * TTL;

vec4 hook()
{

	vec4 color = HOOKED_texOff(vec2(0.0, 0.0));

	color.rgb *= RGBtoYIQ;
	color.r = pow(abs(color.r), offset.x);
	color.gb *= offset.yz;
	color.rgb *= YIQtoRGB;
	color.rgb = clamp(color.rgb, 0.0, 1.0);

	return color;

}

