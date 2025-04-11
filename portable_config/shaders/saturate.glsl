
//!DESC [saturate]
//!HOOK MAINPRESUB   
//!BIND HOOKED

#define Brightness 0.0   // <-1.0==1.0> default 0.0
#define Contrast   1.0   // <0.0==10.0> default 1.0
#define Hue        0.0   // <-180.0==180.0> default 0.0
#define Saturation 1.1   // <0.0==10.0> default 1.0

#define PI 3.1415926535897932384626433832795

#define ymin (15 / 255.0)

const mat4 r2y = mat4(
	0.299, -0.14713,  0.615,   0.000,
	0.587, -0.28886, -0.51499, 0.000,
	0.114,  0.436,   -0.10001, 0.000,
	0.000,  0.000,    0.000,   0.000
);

const mat4 y2r = mat4(
	1.000,    1.000,   1.000,   0.000,
	0.000,   -0.39465, 2.03211, 0.000,
	1.13983, -0.58060, 0.000,   0.000,
	0.000,    0.000,   0.000,   0.000
);

const mat2 HueMatrix = mat2(
	cos(Hue * PI / 180), -sin(Hue * PI / 180),
	sin(Hue * PI / 180),  cos(Hue * PI / 180)
);

#define Src(a,b) HOOKED_texOff(vec2(a,b))

vec4 hook()
{
	vec4 c0 = Src(0,0);
	c0 = r2y * c0;
	c0.r = Contrast * (c0.r - ymin) + ymin + Brightness;
	c0.gb = (HueMatrix * c0.gb) * Saturation;
	c0 = y2r * c0;
	return c0;
}

