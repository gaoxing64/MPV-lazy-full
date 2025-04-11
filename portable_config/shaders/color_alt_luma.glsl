
//!DESC [color_alt_luma]
//!HOOK LUMA
//!BIND HOOKED

vec4 hook()
{

	float color = HOOKED_texOff(0).x;

	return vec4(1.0 - color);

}

