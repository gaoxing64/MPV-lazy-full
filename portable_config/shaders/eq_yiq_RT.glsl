
//!PARAM ttl_f
//!TYPE float
//!MINIMUM 0.1
//!MAXIMUM 3.0
1.0

//!PARAM Y_f
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 3.0
1.0

//!PARAM I_f
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 3.0
1.0

//!PARAM Q_f
//!TYPE float
//!MINIMUM -1.0
//!MAXIMUM 3.0
1.0

//!PARAM CLAMP
//!TYPE DEFINE
//!DESC int
//!MINIMUM 0
//!MAXIMUM 1
0


//!HOOK MAIN
//!BIND HOOKED
//!BIND LUMA
//!DESC [eq_yiq_RT]
//!WHEN ttl_f 1.0 == ! Y_f 1.0 == ! + I_f 1.0 == ! + Q_f 1.0 == ! +

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

vec3 offset = vec3(Y_f, I_f, Q_f) * ttl_f;

vec4 hook()
{
	vec4 color = HOOKED_texOff(vec2(0.0, 0.0));
	color.rgb *= RGBtoYIQ;
	color.r = pow(abs(color.r), offset.x);
	color.gb *= offset.yz;
	color.rgb *= YIQtoRGB;

#if (CLAMP == 1)
	color.rgb = clamp(color.rgb, 0.0, 1.0);
#endif

	return color;
}

