// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- Paper ver.
  https://casual-effects.com/research/McGuire2021PixelArt/McGuire2021PixelArt.pdf
  --- RAW ver. (upstream)
  https://casual-effects.com/research/McGuire2021PixelArt/index.html

*/


//!HOOK MAIN
//!BIND HOOKED
//!DESC [MMPX]
//!WIDTH HOOKED.w 2 *
//!HEIGHT HOOKED.h 2 *
//!WHEN OUTPUT.w HOOKED.w 1.0 * > OUTPUT.h HOOKED.h 1.0 * > *
//!COMPUTE 8 8

vec4 src(int x, int y) {
	return texelFetch(HOOKED_raw, clamp(ivec2(x, y), ivec2(0), ivec2(HOOKED_size) - 1), 0);
}

float luma(vec4 c) {
	float alpha = c.a;
	return (c.r + c.g + c.b + 0.00392157) * (1.0 - alpha);
}

bool eq(vec4 a, vec4 b) {
	return a == b;
}

bool all_eq2(vec4 B, vec4 A0, vec4 A1) {
	return eq(B, A0) && eq(B, A1);
}

bool all_eq3(vec4 B, vec4 A0, vec4 A1, vec4 A2) {
	return eq(B, A0) && eq(B, A1) && eq(B, A2);
}

bool all_eq4(vec4 B, vec4 A0, vec4 A1, vec4 A2, vec4 A3) {
	return eq(B, A0) && eq(B, A1) && eq(B, A2) && eq(B, A3);
}

bool any_eq3(vec4 B, vec4 A0, vec4 A1, vec4 A2) {
	return eq(B, A0) || eq(B, A1) || eq(B, A2);
}

bool none_eq2(vec4 B, vec4 A0, vec4 A1) {
	return !eq(B, A0) && !eq(B, A1);
}

bool none_eq4(vec4 B, vec4 A0, vec4 A1, vec4 A2, vec4 A3) {
	return !eq(B, A0) && !eq(B, A1) && !eq(B, A2) && !eq(B, A3);
}

void hook() {

	ivec2 srcPos = ivec2(gl_GlobalInvocationID.xy);
	int srcX = srcPos.x;
	int srcY = srcPos.y;

	vec4 A = src(srcX - 1, srcY - 1), B = src(srcX, srcY - 1), C = src(srcX + 1, srcY - 1);
	vec4 D = src(srcX - 1, srcY + 0), E = src(srcX, srcY + 0), F = src(srcX + 1, srcY + 0);
	vec4 G = src(srcX - 1, srcY + 1), H = src(srcX, srcY + 1), I = src(srcX + 1, srcY + 1);
	vec4 J = E, K = E, L = E, M = E;

	if (!eq(A, E) || !eq(B, E) || !eq(C, E) || !eq(D, E) || 
		!eq(F, E) || !eq(G, E) || !eq(H, E) || !eq(I, E)) {

		vec4 P = src(srcX, srcY - 2), S = src(srcX, srcY + 2);
		vec4 Q = src(srcX - 2, srcY), R = src(srcX + 2, srcY);
		float Bl = luma(B), Dl = luma(D), El = luma(E), Fl = luma(F), Hl = luma(H);

		if ((eq(D, B) && !eq(D, H) && !eq(D, F)) && (El >= Dl || eq(E, A)) && any_eq3(E, A, C, G) && ((El < Dl) || !eq(A, D) || !eq(E, P) || !eq(E, Q))) J = D;
		if ((eq(B, F) && !eq(B, D) && !eq(B, H)) && (El >= Bl || eq(E, C)) && any_eq3(E, A, C, I) && ((El < Bl) || !eq(C, B) || !eq(E, P) || !eq(E, R))) K = B;
		if ((eq(H, D) && !eq(H, F) && !eq(H, B)) && (El >= Hl || eq(E, G)) && any_eq3(E, A, G, I) && ((El < Hl) || !eq(G, H) || !eq(E, S) || !eq(E, Q))) L = H;
		if ((eq(F, H) && !eq(F, B) && !eq(F, D)) && (El >= Fl || eq(E, I)) && any_eq3(E, C, G, I) && ((El < Fl) || !eq(I, H) || !eq(E, R) || !eq(E, S))) M = F;

		if ((!eq(E, F) && all_eq4(E, C, I, D, Q) && all_eq2(F, B, H)) && (!eq(F, src(srcX + 3, srcY)))) { K = F; M = F; }
		if ((!eq(E, D) && all_eq4(E, A, G, F, R) && all_eq2(D, B, H)) && (!eq(D, src(srcX - 3, srcY)))) { J = D; L = D; }
		if ((!eq(E, H) && all_eq4(E, G, I, B, P) && all_eq2(H, D, F)) && (!eq(H, src(srcX, srcY + 3)))) { L = H; M = H; }
		if ((!eq(E, B) && all_eq4(E, A, C, H, S) && all_eq2(B, D, F)) && (!eq(B, src(srcX, srcY - 3)))) { J = B; K = B; }
		if (Bl < El && all_eq4(E, G, H, I, S) && none_eq4(E, A, D, C, F)) { J = B; K = B; }
		if (Hl < El && all_eq4(E, A, B, C, P) && none_eq4(E, D, G, I, F)) { L = H; M = H; }
		if (Fl < El && all_eq4(E, A, D, G, Q) && none_eq4(E, B, C, I, H)) { K = F; M = F; }
		if (Dl < El && all_eq4(E, C, F, I, R) && none_eq4(E, B, A, G, H)) { J = D; L = D; }

		if (!eq(H, B)) { 
			if (!eq(H, A) && !eq(H, E) && !eq(H, C)) {
				if (all_eq3(H, G, F, R) && none_eq2(H, D, src(srcX + 2, srcY - 1))) L = M;
				if (all_eq3(H, I, D, Q) && none_eq2(H, F, src(srcX - 2, srcY - 1))) M = L;
			}

			if (!eq(B, I) && !eq(B, G) && !eq(B, E)) {
				if (all_eq3(B, A, F, R) && none_eq2(B, D, src(srcX + 2, srcY + 1))) J = K;
				if (all_eq3(B, C, D, Q) && none_eq2(B, F, src(srcX - 2, srcY + 1))) K = J;
			}
		}

		if (!eq(F, D)) { 
			if (!eq(D, I) && !eq(D, E) && !eq(D, C)) {
				if (all_eq3(D, A, H, S) && none_eq2(D, B, src(srcX + 1, srcY + 2))) J = L;
				if (all_eq3(D, G, B, P) && none_eq2(D, H, src(srcX + 1, srcY - 2))) L = J;
			}

			if (!eq(F, E) && !eq(F, A) && !eq(F, G)) {    
				if (all_eq3(F, C, H, S) && none_eq2(F, B, src(srcX - 1, srcY + 2))) K = M;
				if (all_eq3(F, I, B, P) && none_eq2(F, H, src(srcX - 1, srcY - 2))) M = K;
			}
		}
	}

	ivec2 dstPos = srcPos * 2;
	imageStore(out_image, dstPos + ivec2(0, 0), J);
	imageStore(out_image, dstPos + ivec2(1, 0), K);
	imageStore(out_image, dstPos + ivec2(0, 1), L);
	imageStore(out_image, dstPos + ivec2(1, 1), M);

}

