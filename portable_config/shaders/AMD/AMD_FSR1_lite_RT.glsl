// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- RAW ver.
  https://github.com/GPUOpen-LibrariesAndSDKs/FidelityFX-SDK/blob/v2.1.0/Kits/FidelityFX/upscalers/fsr3/include/gpu/fsr1/ffx_fsr1.h
  --- atyuwen ver. (upstream)
  https://gist.github.com/atyuwen/78d6e810e6d0f7fd4aa6207d416f2eeb#file-opt_fsr-fxh

*/


//!PARAM SHARP
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 4.0
0.2


//!HOOK MAIN
//!BIND HOOKED
//!DESC [AMD_FSR1_lite_RT] - EASU & RCAS
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w HOOKED.w 1.0 * > OUTPUT.h HOOKED.h 1.0 * > *

#define FSR_RCAS_LIMIT   (0.25 - (1.0 / 16.0))

#define FSR_FLOAT float
#define FSR_FLOAT2 vec2
#define FSR_FLOAT3 vec3
#define FSR_FLOAT4 vec4

FSR_FLOAT APrxLoRcpF1(FSR_FLOAT a) { return FSR_FLOAT(1.0) / max(a, FSR_FLOAT(1.0e-5)); }
FSR_FLOAT APrxLoRsqF1(FSR_FLOAT a) { return inversesqrt(max(a, FSR_FLOAT(1.0e-5))); }
FSR_FLOAT ASatF1(FSR_FLOAT a) { return clamp(a, FSR_FLOAT(0.0), FSR_FLOAT(1.0)); }
FSR_FLOAT AMin3F1(FSR_FLOAT x, FSR_FLOAT y, FSR_FLOAT z) { return min(x, min(y, z)); }
FSR_FLOAT AMax3F1(FSR_FLOAT x, FSR_FLOAT y, FSR_FLOAT z) { return max(x, max(y, z)); }

void FsrEasuTapH(
	inout FSR_FLOAT2 pR, inout FSR_FLOAT2 pG, inout FSR_FLOAT2 pB, inout FSR_FLOAT2 pW,
	FSR_FLOAT2 offX, FSR_FLOAT2 offY,
	FSR_FLOAT2 dir, FSR_FLOAT2 len,
	FSR_FLOAT lob, FSR_FLOAT clp,
	FSR_FLOAT2 cR, FSR_FLOAT2 cG, FSR_FLOAT2 cB)
{
	FSR_FLOAT2 vX, vY;
	vX = offX * dir.xx + offY * dir.yy;
	vY = offX * (-dir.yy) + offY * dir.xx;
	vX *= len.x;
	vY *= len.y;
	FSR_FLOAT2 d2 = vX * vX + vY * vY;
	d2 = min(d2, FSR_FLOAT2(clp));
	FSR_FLOAT2 wB = FSR_FLOAT2(2.0 / 5.0) * d2 - FSR_FLOAT2(1.0);
	FSR_FLOAT2 wA = FSR_FLOAT2(lob) * d2 - FSR_FLOAT2(1.0);
	wB *= wB;
	wA *= wA;
	wB = FSR_FLOAT2(25.0 / 16.0) * wB - FSR_FLOAT2((25.0 / 16.0) - 1.0);
	FSR_FLOAT2 w = wB * wA;
	pR += cR * w;
	pG += cG * w;
	pB += cB * w;
	pW += w;
}

vec4 hook() {

	FSR_FLOAT2 pp = HOOKED_pos * HOOKED_size - FSR_FLOAT2(0.5);
	FSR_FLOAT2 fp = floor(pp);
	FSR_FLOAT2 tc = (pp + FSR_FLOAT2(0.5)) * HOOKED_pt;
	pp -= fp;

	//    A
	//  B C D
	//    E
	FSR_FLOAT3 sC = FSR_FLOAT3(HOOKED_tex(tc).rgb);
	FSR_FLOAT3 sA = FSR_FLOAT3(HOOKED_tex(tc - vec2(0.0, HOOKED_pt.y)).rgb);
	FSR_FLOAT3 sB = FSR_FLOAT3(HOOKED_tex(tc - vec2(HOOKED_pt.x, 0.0)).rgb);
	FSR_FLOAT3 sD = FSR_FLOAT3(HOOKED_tex(tc + vec2(HOOKED_pt.x, 0.0)).rgb);
	FSR_FLOAT3 sE = FSR_FLOAT3(HOOKED_tex(tc + vec2(0.0, HOOKED_pt.y)).rgb);

	FSR_FLOAT mn4R = min(AMin3F1(sA.r, sB.r, sD.r), sE.r);
	FSR_FLOAT mn4G = min(AMin3F1(sA.g, sB.g, sD.g), sE.g);
	FSR_FLOAT mn4B = min(AMin3F1(sA.b, sB.b, sD.b), sE.b);
	FSR_FLOAT mx4R = max(AMax3F1(sA.r, sB.r, sD.r), sE.r);
	FSR_FLOAT mx4G = max(AMax3F1(sA.g, sB.g, sD.g), sE.g);
	FSR_FLOAT mx4B = max(AMax3F1(sA.b, sB.b, sD.b), sE.b);

	FSR_FLOAT2 peakC = FSR_FLOAT2(1.0, -1.0 * 4.0);

	FSR_FLOAT hitMinR = mn4R * APrxLoRcpF1(FSR_FLOAT(4.0) * mx4R);
	FSR_FLOAT hitMinG = mn4G * APrxLoRcpF1(FSR_FLOAT(4.0) * mx4G);
	FSR_FLOAT hitMinB = mn4B * APrxLoRcpF1(FSR_FLOAT(4.0) * mx4B);
	FSR_FLOAT hitMaxR = (peakC.x - mx4R) * APrxLoRcpF1(FSR_FLOAT(4.0) * mn4R + peakC.y);
	FSR_FLOAT hitMaxG = (peakC.x - mx4G) * APrxLoRcpF1(FSR_FLOAT(4.0) * mn4G + peakC.y);
	FSR_FLOAT hitMaxB = (peakC.x - mx4B) * APrxLoRcpF1(FSR_FLOAT(4.0) * mn4B + peakC.y);
	FSR_FLOAT lobeR = max(-hitMinR, hitMaxR);
	FSR_FLOAT lobeG = max(-hitMinG, hitMaxG);
	FSR_FLOAT lobeB = max(-hitMinB, hitMaxB);

	FSR_FLOAT sharp = exp2(-SHARP);
	FSR_FLOAT lobe = max(FSR_FLOAT(-FSR_RCAS_LIMIT), min(AMax3F1(lobeR, lobeG, lobeB), FSR_FLOAT(0.0))) * sharp;

	FSR_FLOAT rcpL = APrxLoRcpF1(FSR_FLOAT(4.0) * lobe + FSR_FLOAT(1.0));
	FSR_FLOAT3 contrast = (lobe * sA + lobe * sB + lobe * sD + lobe * sE) * rcpL;

	FSR_FLOAT lA = sA.r * FSR_FLOAT(0.5) + sA.g;
	FSR_FLOAT lB = sB.r * FSR_FLOAT(0.5) + sB.g;
	FSR_FLOAT lC = sC.r * FSR_FLOAT(0.5) + sC.g;
	FSR_FLOAT lD = sD.r * FSR_FLOAT(0.5) + sD.g;
	FSR_FLOAT lE = sE.r * FSR_FLOAT(0.5) + sE.g;

	FSR_FLOAT2 dir = FSR_FLOAT2(0.0);
	FSR_FLOAT len = FSR_FLOAT(0.0);

	const bool deea = (target_size.x * target_size.y > HOOKED_size.x * HOOKED_size.y * 6.25);
	if (!deea) {
		FSR_FLOAT dc = lD - lC;
		FSR_FLOAT cb = lC - lB;
		FSR_FLOAT lenX = max(abs(dc), abs(cb));
		lenX = APrxLoRcpF1(lenX);
		FSR_FLOAT dirX = lD - lB;
		lenX = ASatF1(abs(dirX) * lenX);
		lenX *= lenX;

		FSR_FLOAT ec = lE - lC;
		FSR_FLOAT ca = lC - lA;
		FSR_FLOAT lenY = max(abs(ec), abs(ca));
		lenY = APrxLoRcpF1(lenY);
		FSR_FLOAT dirY = lE - lA;
		lenY = ASatF1(abs(dirY) * lenY);
		len = lenY * lenY + lenX;
		dir = FSR_FLOAT2(dirX, dirY);
	}

	FSR_FLOAT2 dir2 = dir * dir;
	FSR_FLOAT dirR = dir2.x + dir2.y;
	if (!deea && dirR < FSR_FLOAT(1.0 / 64.0)) {
		float alpha = HOOKED_tex(HOOKED_pos).a;
		return vec4(contrast + sC * rcpL, alpha);
	}

	bool zro = dirR < FSR_FLOAT(1.0 / 32768.0);
	dirR = APrxLoRsqF1(dirR);
	dirR = zro ? FSR_FLOAT(1.0) : dirR;
	dir.x = zro ? FSR_FLOAT(1.0) : dir.x;
	dir *= FSR_FLOAT2(dirR);
	len = len * FSR_FLOAT(0.5);
	len *= len;
	FSR_FLOAT stretch = (dir.x * dir.x + dir.y * dir.y) * APrxLoRcpF1(max(abs(dir.x), abs(dir.y)));
	FSR_FLOAT2 len2 = FSR_FLOAT2(FSR_FLOAT(1.0) + (stretch - FSR_FLOAT(1.0)) * len, FSR_FLOAT(1.0) + FSR_FLOAT(-0.5) * len);
	FSR_FLOAT lob = FSR_FLOAT(0.5) + FSR_FLOAT((1.0 / 4.0 - 0.04) - 0.5) * len;
	FSR_FLOAT clp = APrxLoRcpF1(lob);

#if (defined(HOOKED_gather) && (__VERSION__ >= 400 || (GL_ES && __VERSION__ >= 310)))
	FSR_FLOAT4 bczzR = HOOKED_gather(vec2((fp + vec2(1.0, -1.0)) * HOOKED_pt), 0);
	FSR_FLOAT4 bczzG = HOOKED_gather(vec2((fp + vec2(1.0, -1.0)) * HOOKED_pt), 1);
	FSR_FLOAT4 bczzB = HOOKED_gather(vec2((fp + vec2(1.0, -1.0)) * HOOKED_pt), 2);

	FSR_FLOAT4 ijfeR = HOOKED_gather(vec2((fp + vec2(0.0, 1.0)) * HOOKED_pt), 0);
	FSR_FLOAT4 ijfeG = HOOKED_gather(vec2((fp + vec2(0.0, 1.0)) * HOOKED_pt), 1);
	FSR_FLOAT4 ijfeB = HOOKED_gather(vec2((fp + vec2(0.0, 1.0)) * HOOKED_pt), 2);

	FSR_FLOAT4 klhgR = HOOKED_gather(vec2((fp + vec2(2.0, 1.0)) * HOOKED_pt), 0);
	FSR_FLOAT4 klhgG = HOOKED_gather(vec2((fp + vec2(2.0, 1.0)) * HOOKED_pt), 1);
	FSR_FLOAT4 klhgB = HOOKED_gather(vec2((fp + vec2(2.0, 1.0)) * HOOKED_pt), 2);

	FSR_FLOAT4 zzonR = HOOKED_gather(vec2((fp + vec2(1.0, 3.0)) * HOOKED_pt), 0);
	FSR_FLOAT4 zzonG = HOOKED_gather(vec2((fp + vec2(1.0, 3.0)) * HOOKED_pt), 1);
	FSR_FLOAT4 zzonB = HOOKED_gather(vec2((fp + vec2(1.0, 3.0)) * HOOKED_pt), 2);

	FSR_FLOAT4 fgcbR = FSR_FLOAT4(ijfeR.z, klhgR.w, bczzR.y, bczzR.x);
	FSR_FLOAT4 fgcbG = FSR_FLOAT4(ijfeG.z, klhgG.w, bczzG.y, bczzG.x);
	FSR_FLOAT4 fgcbB = FSR_FLOAT4(ijfeB.z, klhgB.w, bczzB.y, bczzB.x);

	FSR_FLOAT4 nokjR = FSR_FLOAT4(zzonR.w, zzonR.z, klhgR.x, ijfeR.y);
	FSR_FLOAT4 nokjG = FSR_FLOAT4(zzonG.w, zzonG.z, klhgG.x, ijfeG.y);
	FSR_FLOAT4 nokjB = FSR_FLOAT4(zzonB.w, zzonB.z, klhgB.x, ijfeB.y);
#else
	//      b c
	//    e f g h
	//    i j k l
	//      n o
	FSR_FLOAT3 b = FSR_FLOAT3(HOOKED_tex(vec2(fp + vec2(0.5, -0.5)) * HOOKED_pt).rgb);
	FSR_FLOAT3 c = FSR_FLOAT3(HOOKED_tex(vec2(fp + vec2(1.5, -0.5)) * HOOKED_pt).rgb);
	FSR_FLOAT3 e = FSR_FLOAT3(HOOKED_tex(vec2(fp + vec2(-0.5, 0.5)) * HOOKED_pt).rgb);
	FSR_FLOAT3 f = FSR_FLOAT3(HOOKED_tex(vec2(fp + vec2(0.5, 0.5)) * HOOKED_pt).rgb);
	FSR_FLOAT3 g = FSR_FLOAT3(HOOKED_tex(vec2(fp + vec2(1.5, 0.5)) * HOOKED_pt).rgb);
	FSR_FLOAT3 h = FSR_FLOAT3(HOOKED_tex(vec2(fp + vec2(2.5, 0.5)) * HOOKED_pt).rgb);
	FSR_FLOAT3 i = FSR_FLOAT3(HOOKED_tex(vec2(fp + vec2(-0.5, 1.5)) * HOOKED_pt).rgb);
	FSR_FLOAT3 j = FSR_FLOAT3(HOOKED_tex(vec2(fp + vec2(0.5, 1.5)) * HOOKED_pt).rgb);
	FSR_FLOAT3 k = FSR_FLOAT3(HOOKED_tex(vec2(fp + vec2(1.5, 1.5)) * HOOKED_pt).rgb);
	FSR_FLOAT3 l = FSR_FLOAT3(HOOKED_tex(vec2(fp + vec2(2.5, 1.5)) * HOOKED_pt).rgb);
	FSR_FLOAT3 n = FSR_FLOAT3(HOOKED_tex(vec2(fp + vec2(0.5, 2.5)) * HOOKED_pt).rgb);
	FSR_FLOAT3 o = FSR_FLOAT3(HOOKED_tex(vec2(fp + vec2(1.5, 2.5)) * HOOKED_pt).rgb);

	FSR_FLOAT4 fgcbR = FSR_FLOAT4(f.r, g.r, c.r, b.r);
	FSR_FLOAT4 fgcbG = FSR_FLOAT4(f.g, g.g, c.g, b.g);
	FSR_FLOAT4 fgcbB = FSR_FLOAT4(f.b, g.b, c.b, b.b);
	// x=i, y=j, z=f, w=e
	FSR_FLOAT4 ijfeR = FSR_FLOAT4(i.r, j.r, f.r, e.r);
	FSR_FLOAT4 ijfeG = FSR_FLOAT4(i.g, j.g, f.g, e.g);
	FSR_FLOAT4 ijfeB = FSR_FLOAT4(i.b, j.b, f.b, e.b);
	// x=k, y=l, z=h, w=g
	FSR_FLOAT4 klhgR = FSR_FLOAT4(k.r, l.r, h.r, g.r);
	FSR_FLOAT4 klhgG = FSR_FLOAT4(k.g, l.g, h.g, g.g);
	FSR_FLOAT4 klhgB = FSR_FLOAT4(k.b, l.b, h.b, g.b);
	// x=n, y=o, z=k, w=j
	FSR_FLOAT4 nokjR = FSR_FLOAT4(n.r, o.r, k.r, j.r);
	FSR_FLOAT4 nokjG = FSR_FLOAT4(n.g, o.g, k.g, j.g);
	FSR_FLOAT4 nokjB = FSR_FLOAT4(n.b, o.b, k.b, j.b);
#endif

	FSR_FLOAT2 pR = FSR_FLOAT2(0.0);
	FSR_FLOAT2 pG = FSR_FLOAT2(0.0);
	FSR_FLOAT2 pB = FSR_FLOAT2(0.0);
	FSR_FLOAT2 pW = FSR_FLOAT2(0.0);

	FsrEasuTapH(pR, pG, pB, pW, FSR_FLOAT2(1.0, 0.0) - pp.xx, FSR_FLOAT2(-1.0, -1.0) - pp.yy, dir, len2, lob, clp, fgcbR.zw, fgcbG.zw, fgcbB.zw);
	FsrEasuTapH(pR, pG, pB, pW, FSR_FLOAT2(-1.0, 0.0) - pp.xx, FSR_FLOAT2(1.0, 1.0) - pp.yy, dir, len2, lob, clp, ijfeR.xy, ijfeG.xy, ijfeB.xy);
	FsrEasuTapH(pR, pG, pB, pW, FSR_FLOAT2(0.0, -1.0) - pp.xx, FSR_FLOAT2(0.0, 0.0) - pp.yy, dir, len2, lob, clp, ijfeR.zw, ijfeG.zw, ijfeB.zw);
	FsrEasuTapH(pR, pG, pB, pW, FSR_FLOAT2(1.0, 2.0) - pp.xx, FSR_FLOAT2(1.0, 1.0) - pp.yy, dir, len2, lob, clp, klhgR.xy, klhgG.xy, klhgB.xy);
	FsrEasuTapH(pR, pG, pB, pW, FSR_FLOAT2(2.0, 1.0) - pp.xx, FSR_FLOAT2(0.0, 0.0) - pp.yy, dir, len2, lob, clp, klhgR.zw, klhgG.zw, klhgB.zw);
	FsrEasuTapH(pR, pG, pB, pW, FSR_FLOAT2(0.0, 1.0) - pp.xx, FSR_FLOAT2(2.0, 2.0) - pp.yy, dir, len2, lob, clp, nokjR.xy, nokjG.xy, nokjB.xy);

	FSR_FLOAT3 aC = FSR_FLOAT3(pR.x + pR.y, pG.x + pG.y, pB.x + pB.y);
	FSR_FLOAT aW = pW.x + pW.y;

	FSR_FLOAT3 pix = contrast + aC * FSR_FLOAT3(APrxLoRcpF1(aW) * rcpL);
	float alpha = HOOKED_tex(HOOKED_pos).a;
	return vec4(pix, alpha);

}

