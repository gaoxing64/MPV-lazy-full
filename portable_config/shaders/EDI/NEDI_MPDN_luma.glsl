// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- RAW ver.
  https://github.com/zachsaw/MPDN_Extensions/blob/v2.0.0/Extensions/RenderScripts/Shiandow.Nedi.NediScaler.cs

*/


//!HOOK LUMA
//!BIND HOOKED
//!SAVE NEDI_I
//!DESC [NEDI_MPDN_luma] Diagonal
//!WHEN OUTPUT.w HOOKED.w 1.200 * > OUTPUT.h HOOKED.h 1.200 * > *

#ifdef GL_ES
	#ifdef GL_FRAGMENT_PRECISION_HIGH
		precision highp float;
	#endif
#endif

#define offset  0.5
#define epsilon 0.005   // <0.0 --- 0.1> Regularization (higher=more stable, lower=sharper)

// Conjugate residual solver for 2x2 system
vec2 conjugateResidual(mat2 A, vec2 b, float eps) {
	A[0][0] += eps * eps;
	A[1][1] += eps * eps;
	b += vec2(eps * eps * 0.5);

	vec2 x = vec2(0.25);
	vec2 r = b - A * x;
	vec2 p = r;
	vec2 Ar = A * r;
	vec2 Ap = Ar;

	for (int k = 0; k < 2; k++) {
		float alpha = min(100.0, dot(r, Ar) / dot(Ap, Ap));
		x = x + alpha * p;
		vec2 rk = r;
		vec2 Ark = Ar;
		r = r - alpha * Ap;
		Ar = A * r;
		float beta = dot(r, Ar) / dot(rk, Ark);
		p = r + beta * p;
		Ap = Ar + beta * Ap;
	}

	return x;
}

vec4 hook() {

	vec2 dir[4] = vec2[4](
		vec2(-1, -1), vec2(1, 1),
		vec2(-1, 1), vec2(1, -1)
	);

	vec2 wind[4][4] = vec2[4][4](
		vec2[4](vec2(0, 0), vec2(1, 1), vec2(0, 1), vec2(1, 0)),
		vec2[4](vec2(-1, 0), vec2(2, 1), vec2(0, 2), vec2(1, -1)),
		vec2[4](vec2(0, -1), vec2(1, 2), vec2(-1, 1), vec2(2, 0)),
		vec2[4](vec2(-1, -1), vec2(2, 2), vec2(-1, 2), vec2(2, -1))
	);

	const vec4 w = vec4(1.0, 1.0, 1.0, 0.0);
	mat2 R = mat2(0.0);
	vec2 r = vec2(0.0);

	for (int k = 0; k < 4; k++) {
		vec2 C[4];

		for (int i = 0; i < 4; i++) {
			vec2 pos = HOOKED_pos + HOOKED_pt * wind[k][i];
			float val = HOOKED_tex(pos).r + offset;

			float d0 = HOOKED_tex(pos + HOOKED_pt * dir[0]).r + offset;
			float d1 = HOOKED_tex(pos + HOOKED_pt * dir[1]).r + offset;
			float d2 = HOOKED_tex(pos + HOOKED_pt * dir[2]).r + offset;
			float d3 = HOOKED_tex(pos + HOOKED_pt * dir[3]).r + offset;

			C[i] = vec2(d0 + d1, d2 + d3);
			r += w[k] * val * C[i];
		}

		mat2 CtC;
		CtC[0][0] = dot(vec4(C[0].x, C[1].x, C[2].x, C[3].x), vec4(C[0].x, C[1].x, C[2].x, C[3].x));
		CtC[0][1] = dot(vec4(C[0].x, C[1].x, C[2].x, C[3].x), vec4(C[0].y, C[1].y, C[2].y, C[3].y));
		CtC[1][0] = CtC[0][1];
		CtC[1][1] = dot(vec4(C[0].y, C[1].y, C[2].y, C[3].y), vec4(C[0].y, C[1].y, C[2].y, C[3].y));

		R += w[k] * CtC;
	}

	R /= 24.0;
	r /= 24.0;

	vec2 a = conjugateResidual(R, r, epsilon);
	a = vec2(0.25) + vec2(0.5, -0.5) * clamp(a.x - a.y, -1.0, 1.0);

	vec2 x0 = (HOOKED_tex(HOOKED_pos + HOOKED_pt * wind[0][0]) +
			   HOOKED_tex(HOOKED_pos + HOOKED_pt * wind[0][1])).rr;
	vec2 x1 = (HOOKED_tex(HOOKED_pos + HOOKED_pt * wind[0][2]) +
			   HOOKED_tex(HOOKED_pos + HOOKED_pt * wind[0][3])).rr;

	float result = dot(a, vec2(x0.x, x1.x));
	return vec4(result, result, result, 1.0);

}

//!HOOK LUMA
//!BIND HOOKED
//!BIND NEDI_I
//!SAVE NEDI_H
//!DESC [NEDI_MPDN_luma] HInterleave
//!WIDTH HOOKED.w 2 *
//!WHEN OUTPUT.w HOOKED.w 1.200 * > OUTPUT.h HOOKED.h 1.200 * > *

vec4 hook() {

	ivec2 output_pixel = ivec2(HOOKED_pos * HOOKED_size * vec2(2.0, 1.0));
	vec2 pos = floor(vec2(output_pixel) / vec2(2.0, 1.0));
	vec2 src_pos = (pos + 0.5) / HOOKED_size;

	if ((output_pixel.x & 1) == 0) {
		return HOOKED_tex(src_pos);
	} else {
		return NEDI_I_tex(src_pos);
	}

}

//!HOOK LUMA
//!BIND NEDI_H
//!SAVE NEDI_II
//!DESC [NEDI_MPDN_luma] Horizontal
//!WIDTH NEDI_H.w

#ifdef GL_ES
	#ifdef GL_FRAGMENT_PRECISION_HIGH
		precision highp float;
	#endif
#endif

#define offset  0.5
#define epsilon 0.005   // <0.0 --- 0.1> Regularization (higher=more stable, lower=sharper)

// Conjugate residual solver for 2x2 system
vec2 conjugateResidual(mat2 A, vec2 b, float eps) {
	A[0][0] += eps * eps;
	A[1][1] += eps * eps;
	b += vec2(eps * eps * 0.5);

	vec2 x = vec2(0.25);
	vec2 r = b - A * x;
	vec2 p = r;
	vec2 Ar = A * r;
	vec2 Ap = Ar;

	for (int k = 0; k < 2; k++) {
		float alpha = min(100.0, dot(r, Ar) / dot(Ap, Ap));
		x = x + alpha * p;
		vec2 rk = r;
		vec2 Ark = Ar;
		r = r - alpha * Ap;
		Ar = A * r;
		float beta = dot(r, Ar) / dot(rk, Ark);
		p = r + beta * p;
		Ap = Ar + beta * Ap;
	}

	return x;
}

vec4 hook() {

	float tex_x = NEDI_H_pos.x * NEDI_H_size.x;
	bool col_even = (fract(tex_x / 2.0) < 0.5);

	vec2 dir[4] = vec2[4](
		vec2(-2, 0), vec2(1, 0),
		vec2(0, 1), vec2(0, -2)
	);

	vec2 wind[4][4];
	if (col_even) {
		wind[0] = vec2[4](vec2(-1, 0), vec2(1, 0), vec2(0, 1), vec2(0, 0));
		wind[1] = vec2[4](vec2(-1, 1), vec2(1, -1), vec2(2, 1), vec2(-2, 0));
		wind[2] = vec2[4](vec2(-1, -1), vec2(1, 1), vec2(-2, 1), vec2(2, 0));
		wind[3] = vec2[4](vec2(-3, 0), vec2(3, 0), vec2(0, 2), vec2(0, -1));
	} else {
		wind[0] = vec2[4](vec2(-1, 0), vec2(1, 0), vec2(0, 0), vec2(0, -1));
		wind[1] = vec2[4](vec2(-1, 1), vec2(1, -1), vec2(2, 0), vec2(-2, -1));
		wind[2] = vec2[4](vec2(-1, -1), vec2(1, 1), vec2(-2, 0), vec2(2, -1));
		wind[3] = vec2[4](vec2(-3, 0), vec2(3, 0), vec2(0, 1), vec2(0, -2));
	}

	const vec4 w = vec4(1.0, 1.0, 1.0, 0.0);
	mat2 R = mat2(0.0);
	vec2 r = vec2(0.0);

	for (int k = 0; k < 4; k++) {
		vec2 C[4];

		for (int i = 0; i < 4; i++) {
			vec2 pos = NEDI_H_pos + NEDI_H_pt * wind[k][i];
			float val = NEDI_H_tex(pos).r + offset;

			float d0 = NEDI_H_tex(pos + NEDI_H_pt * dir[0]).r + offset;
			float d1 = NEDI_H_tex(pos + NEDI_H_pt * dir[1]).r + offset;
			float d2 = NEDI_H_tex(pos + NEDI_H_pt * dir[2]).r + offset;
			float d3 = NEDI_H_tex(pos + NEDI_H_pt * dir[3]).r + offset;

			C[i] = vec2(d0 + d1, d2 + d3);
			r += w[k] * val * C[i];
		}

		mat2 CtC;
		CtC[0][0] = dot(vec4(C[0].x, C[1].x, C[2].x, C[3].x), vec4(C[0].x, C[1].x, C[2].x, C[3].x));
		CtC[0][1] = dot(vec4(C[0].x, C[1].x, C[2].x, C[3].x), vec4(C[0].y, C[1].y, C[2].y, C[3].y));
		CtC[1][0] = CtC[0][1];
		CtC[1][1] = dot(vec4(C[0].y, C[1].y, C[2].y, C[3].y), vec4(C[0].y, C[1].y, C[2].y, C[3].y));

		R += w[k] * CtC;
	}

	R /= 24.0;
	r /= 24.0;

	vec2 a = conjugateResidual(R, r, epsilon);
	a = vec2(0.25) + vec2(0.5, -0.5) * clamp(a.x - a.y, -1.0, 1.0);

	vec2 x0 = (NEDI_H_tex(NEDI_H_pos + NEDI_H_pt * wind[0][0]) +
			   NEDI_H_tex(NEDI_H_pos + NEDI_H_pt * wind[0][1])).rr;
	vec2 x1 = (NEDI_H_tex(NEDI_H_pos + NEDI_H_pt * wind[0][2]) +
			   NEDI_H_tex(NEDI_H_pos + NEDI_H_pt * wind[0][3])).rr;

	float result = dot(a, vec2(x0.x, x1.x));
	return vec4(result, result, result, 1.0);

}

//!HOOK LUMA
//!BIND NEDI_H
//!BIND NEDI_II
//!DESC [NEDI_MPDN_luma] VInterleave
//!WIDTH NEDI_H.w
//!HEIGHT NEDI_H.h 2 *

vec4 hook() {

	ivec2 output_pixel = ivec2(NEDI_H_pos * NEDI_H_size * vec2(1.0, 2.0));
	vec2 pos = floor(vec2(output_pixel) / vec2(1.0, 2.0));
	vec2 src_pos = (pos + 0.5) / NEDI_H_size;

	bool x_even = ((output_pixel.x & 1) == 0);
	bool y_even = ((output_pixel.y & 1) == 0);

	if (x_even == y_even) {
		return NEDI_H_tex(src_pos);
	} else {
		return NEDI_II_tex(src_pos);
	}

}

