/* vi: ft=c
 *
 * Copyright (c) 2022 an3223 <ethanr2048@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify it 
 * under the terms of the GNU Lesser General Public License as published by 
 * the Free Software Foundation, either version 2.1 of the License, or (at 
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or 
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License 
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License 
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

// Description: guided_s.glsl: Self-guided

/* The radius can be adjusted with the MEANIP stage's downscaling factor. 
 * Higher numbers give a bigger radius.
 *
 * The E variable can be found in the A stage.
 *
 * The subsampling (fast guided filter) can be adjusted with the IP stage's 
 * downscaling factor. Higher numbers are faster.
 */

//!HOOK LUMA
//!HOOK CHROMA
//!HOOK RGB
//!DESC [guided_s] (IP)
//!BIND HOOKED
//!WIDTH HOOKED.w 1.0 /
//!HEIGHT HOOKED.h 1.0 /
//!SAVE IP

vec4 hook()
{
	return HOOKED_texOff(0);
}

//!HOOK LUMA
//!HOOK CHROMA
//!HOOK RGB
//!DESC [guided_s] (MEANIP)
//!BIND IP
//!WIDTH IP.w 1.5 /
//!HEIGHT IP.h 1.5 /
//!SAVE MEANIP

vec4 hook()
{
	return IP_texOff(0);
}

//!HOOK LUMA
//!HOOK CHROMA
//!HOOK RGB
//!DESC [guided_s] (IP_SQ)
//!BIND IP
//!WIDTH IP.w
//!HEIGHT IP.h
//!SAVE IP_SQ

vec4 hook()
{
	return IP_texOff(0) * IP_texOff(0);
}

//!HOOK LUMA
//!HOOK CHROMA
//!HOOK RGB
//!DESC [guided_s] (CORRIP)
//!BIND IP_SQ
//!WIDTH MEANIP.w
//!HEIGHT MEANIP.h
//!SAVE CORRIP

vec4 hook()
{
	return IP_SQ_texOff(0);
}

//!HOOK LUMA
//!HOOK CHROMA
//!HOOK RGB
//!DESC [guided_s] (A)
//!BIND MEANIP
//!BIND CORRIP
//!WIDTH IP.w
//!HEIGHT IP.h
//!SAVE A

#define E 0.002

vec4 hook()
{
	vec4 var = CORRIP_texOff(0) - MEANIP_texOff(0) * MEANIP_texOff(0);
	vec4 cov = var;
	return cov / (var + E);
}

//!HOOK LUMA
//!HOOK CHROMA
//!HOOK RGB
//!DESC [guided_s] (B)
//!BIND A
//!BIND MEANIP
//!WIDTH IP.w
//!HEIGHT IP.h
//!SAVE B

vec4 hook()
{
	return MEANIP_texOff(0) - A_texOff(0) * MEANIP_texOff(0);
}

//!HOOK LUMA
//!HOOK CHROMA
//!HOOK RGB
//!DESC [guided_s] (MEANA)
//!BIND A
//!WIDTH MEANIP.w
//!HEIGHT MEANIP.h
//!SAVE MEANA

vec4 hook()
{
	return A_texOff(0);
}

//!HOOK LUMA
//!HOOK CHROMA
//!HOOK RGB
//!DESC [guided_s] (MEANB)
//!BIND B
//!WIDTH MEANIP.w
//!HEIGHT MEANIP.h
//!SAVE MEANB

vec4 hook()
{
	return B_texOff(0);
}

//!HOOK LUMA
//!HOOK CHROMA
//!HOOK RGB
//!DESC [guided_s]
//!BIND HOOKED
//!BIND MEANA
//!BIND MEANB

vec4 hook()
{
	return MEANA_texOff(0) * HOOKED_texOff(0) + MEANB_texOff(0);
}

