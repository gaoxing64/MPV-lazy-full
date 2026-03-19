// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- RAW ver.
  FastEDIUpsizer AviSynth plugin by tritical

*/


//!PARAM THR
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 10000.0
5000.0

//!PARAM CSTR
//!TYPE DEFINE
//!MINIMUM 0
//!MAXIMUM 2
2

//!PARAM C_A
//!TYPE DEFINE
//!MINIMUM 0
//!MAXIMUM 4
2

//!PARAM MV
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 260100.0
8.0


//!HOOK LUMA
//!BIND HOOKED
//!DESC [NEDI_Fast_luma_RT]
//!WIDTH HOOKED.w 2 *
//!HEIGHT HOOKED.h 2 *
//!WHEN OUTPUT.w HOOKED.w 1.200 * > OUTPUT.h HOOKED.h 1.200 * > *

// For matrix operations?
#ifdef GL_ES
	#ifdef GL_FRAGMENT_PRECISION_HIGH
		precision highp float;
	#else
		#error "High precision float not supported"
	#endif
#endif

// Cubic interpolation with different A values
float cubic_interp(float p1, float p2, float p3, float p4) {
	float result;
	#if C_A == 0     // A = -0.5
		result = (9.0 * (p2 + p3) - p1 - p4) / 16.0;
	#elif C_A == 1   // A = -0.625
		result = (37.0 * (p2 + p3) - 5.0 * (p1 + p4)) / 64.0;
	#elif C_A == 2   // A = -0.75
		result = (19.0 * (p2 + p3) - 3.0 * (p1 + p4)) / 32.0;
	#elif C_A == 3   // A = -0.875
		result = (39.0 * (p2 + p3) - 7.0 * (p1 + p4)) / 64.0;
	#else            // A = -1.0
		result = (5.0 * (p2 + p3) - p1 - p4) / 8.0;
	#endif
	return clamp(result, 0.0, 1.0);
}

bool checkVariance(float pc[4]) {
	float sum = pc[0] + pc[1] + pc[2] + pc[3];
	float sumsq = pc[0]*pc[0] + pc[1]*pc[1] + pc[2]*pc[2] + pc[3]*pc[3];
	// Original C++: (sumsq<<2) - sum*sum <= MV
	// Equivalent: 4*sumsq - sum*sum <= MV
	// Adjusted for 0-1 range: multiply MV by (1/255)^2
	float variance = 4.0 * sumsq - sum * sum;
	return variance > (MV / 65025.0); // 65025 = 255^2
}

// CtCi: output inverse matrix
// CtC_in: input matrix
bool gaussianInvert(inout float CtCi[16], float CtC_in[16]) {
	float CtC[16];
	for (int i = 0; i < 16; i++) CtC[i] = CtC_in[i];

	for (int i = 0; i < 4; i++) {
		// Partial pivoting: find best pivot
		int best = i;
		float best_val = abs(CtC[i + i*4]);
		for (int j = i + 1; j < 4; j++) {
			float val = abs(CtC[i + j*4]);
			if (val > best_val) {
				best = j;
				best_val = val;
			}
		}

		// Swap rows if needed (using column-major storage)
		if (best != i) {
			for (int k = 0; k < 4; k++) {
				float temp = CtC[k + i*4];
				CtC[k + i*4] = CtC[k + best*4];
				CtC[k + best*4] = temp;

				temp = CtCi[k + i*4];
				CtCi[k + i*4] = CtCi[k + best*4];
				CtCi[k + best*4] = temp;
			}
		}

		// Check for singular matrix
		if (CtC[i + i*4] == 0.0) return false;
		// Gaussian elimination
		float pivot = CtC[i + i*4];
		for (int k = 0; k < 4; k++) {
			if (k != i) {
				float scale = -CtC[i + k*4] / pivot;
				for (int j = 0; j < 4; j++) {
					CtC[j + k*4] += CtC[j + i*4] * scale;
					CtCi[j + k*4] += CtCi[j + i*4] * scale;
				}
				CtC[i + k*4] = 0.0;
			}
		}
	}

	// Normalize diagonal to 1
	for (int i = 0; i < 4; i++) {
		float diag = CtC[i + i*4];
		if (diag != 1.0) {
			float scale = 1.0 / diag;
			for (int k = 0; k < 4; k++) {
				CtCi[k + i*4] *= scale;
			}
		}
	}

	return true;
}

// Condition number calculation using L-infinity norm
float conditionNumber(float CtCi[16], float CtC[16]) {
	float highest1 = 0.0;
	float highest2 = 0.0;
	// L-infinity norm: maximum absolute row sum
	for (int i = 0; i < 4; i++) {
		float sum1 = abs(CtCi[i*4]) + abs(CtCi[i*4+1]) + abs(CtCi[i*4+2]) + abs(CtCi[i*4+3]);
		float sum2 = abs(CtC[i*4]) + abs(CtC[i*4+1]) + abs(CtC[i*4+2]) + abs(CtC[i*4+3]);
		highest1 = max(highest1, sum1);
		highest2 = max(highest2, sum2);
	}
	return highest1 * highest2;
}

float nEDI_8x8_grid(float grid[100], float pc[4]) {
	float CtC[16] = float[16](
		0.0, 0.0, 0.0, 0.0,
		0.0, 0.0, 0.0, 0.0,
		0.0, 0.0, 0.0, 0.0,
		0.0, 0.0, 0.0, 0.0
	);
	float r[4] = float[4](0.0, 0.0, 0.0, 0.0);

	for (int gy = 1; gy <= 8; gy++) {
		for (int gx = 1; gx <= 8; gx++) {
			float p = grid[gy * 10 + gx];
			float n0 = grid[(gy - 1) * 10 + (gx - 1)]; // (-1,-1)
			float n1 = grid[(gy - 1) * 10 + (gx + 1)]; // (+1,-1)
			float n2 = grid[(gy + 1) * 10 + (gx - 1)]; // (-1,+1)
			float n3 = grid[(gy + 1) * 10 + (gx + 1)]; // (+1,+1)

			// Accumulate CtC (upper triangle)
			CtC[0 + 0*4] += n0 * n0;
			CtC[0 + 1*4] += n0 * n1;
			CtC[0 + 2*4] += n0 * n2;
			CtC[0 + 3*4] += n0 * n3;
			CtC[1 + 1*4] += n1 * n1;
			CtC[1 + 2*4] += n1 * n2;
			CtC[1 + 3*4] += n1 * n3;
			CtC[2 + 2*4] += n2 * n2;
			CtC[2 + 3*4] += n2 * n3;
			CtC[3 + 3*4] += n3 * n3;

			// Accumulate r = C^T * p
			r[0] += n0 * p;
			r[1] += n1 * p;
			r[2] += n2 * p;
			r[3] += n3 * p;
		}
	}

	CtC[1 + 0*4] = CtC[0 + 1*4];
	CtC[2 + 0*4] = CtC[0 + 2*4];
	CtC[2 + 1*4] = CtC[1 + 2*4];
	CtC[3 + 0*4] = CtC[0 + 3*4];
	CtC[3 + 1*4] = CtC[1 + 3*4];
	CtC[3 + 2*4] = CtC[2 + 3*4];

	float CtCi[16] = float[16](
		1.0, 0.0, 0.0, 0.0,
		0.0, 1.0, 0.0, 0.0,
		0.0, 0.0, 1.0, 0.0,
		0.0, 0.0, 0.0, 1.0
	);

	if (!gaussianInvert(CtCi, CtC)) {
		return cubic_interp(pc[0], pc[1], pc[2], pc[3]);
	}

	if (THR > 0.0) {
		float cn = conditionNumber(CtCi, CtC);
		if (cn >= THR) {
			return cubic_interp(pc[0], pc[1], pc[2], pc[3]);
		}
	}

	// Compute weights a = CtCi * r
	float a[4];
	for (int i = 0; i < 4; i++) {
		a[i] = CtCi[i + 0*4] * r[0] + CtCi[i + 1*4] * r[1]
			 + CtCi[i + 2*4] * r[2] + CtCi[i + 3*4] * r[3];
	}

	float final_val = pc[0]*a[0] + pc[1]*a[1] + pc[2]*a[2] + pc[3]*a[3];

	// Apply constraints
	#if CSTR == 1
		if (final_val > 1.0 || final_val < 0.0) {
			return cubic_interp(pc[0], pc[1], pc[2], pc[3]);
		}
	#elif CSTR == 2
		float highN = max(max(pc[0], pc[1]), max(pc[2], pc[3])) + 5.0/255.0;
		float lowN = min(min(pc[0], pc[1]), min(pc[2], pc[3])) - 5.0/255.0;
		if (final_val > highN || final_val < lowN) {
			return cubic_interp(pc[0], pc[1], pc[2], pc[3]);
		}
	#endif

	return clamp(final_val, 0.0, 1.0);
}

float interpolate_diagonal(vec2 base_pos) {
	// Check if too close to borders (need 4 source pixels in each direction)
	vec2 src_pixel = base_pos * HOOKED_size;
	if (src_pixel.x < 4.0 || src_pixel.x > HOOKED_size.x - 5.0 ||
		src_pixel.y < 4.0 || src_pixel.y > HOOKED_size.y - 5.0) {
		// Border fallback: C_A along diagonal
		float p1 = HOOKED_tex(base_pos + HOOKED_pt * vec2(-1.0, -1.0)).r;
		float p2 = HOOKED_tex(base_pos).r;
		float p3 = HOOKED_tex(base_pos + HOOKED_pt * vec2(1.0, 1.0)).r;
		float p4 = HOOKED_tex(base_pos + HOOKED_pt * vec2(2.0, 2.0)).r;
		return cubic_interp(p1, p2, p3, p4);
	}

	float grid[100];

#ifdef HOOKED_gather
	for (int j = 0; j < 5; j++) {
		for (int i = 0; i < 5; i++) {
			vec2 gpos = base_pos + HOOKED_pt * vec2(float(i * 2) - 3.5, float(j * 2) - 3.5);
			vec4 g = HOOKED_gather(gpos, 0);
			int bx = i * 2;
			int by = j * 2;
			grid[by * 10 + bx]           = g.w; // (0, 0) top-left
			grid[by * 10 + bx + 1]       = g.z; // (1, 0) top-right
			grid[(by + 1) * 10 + bx]     = g.x; // (0, 1) bottom-left
			grid[(by + 1) * 10 + bx + 1] = g.y; // (1, 1) bottom-right
		}
	}
#else
	for (int gy = 0; gy < 10; gy++) {
		for (int gx = 0; gx < 10; gx++) {
			vec2 pos = base_pos + HOOKED_pt * vec2(float(gx) - 4.0, float(gy) - 4.0);
			grid[gy * 10 + gx] = HOOKED_tex(pos).r;
		}
	}
#endif

	// 4 closest source pixels: (0,0), (1,0), (0,1), (1,1) relative to base_pos
	float pc[4];
	pc[0] = grid[4 * 10 + 4]; // (0,0)
	pc[1] = grid[4 * 10 + 5]; // (1,0)
	pc[2] = grid[5 * 10 + 4]; // (0,1)
	pc[3] = grid[5 * 10 + 5]; // (1,1)

	if (!checkVariance(pc)) {
		// Low variance: C_A fallback along diagonal
		return cubic_interp(grid[3 * 10 + 3], grid[4 * 10 + 4],
							grid[5 * 10 + 5], grid[6 * 10 + 6]);
	}

	return nEDI_8x8_grid(grid, pc);
}

float interpolate_horizontal(vec2 base_pos) {
	float p1 = HOOKED_tex(base_pos + HOOKED_pt * vec2(-1.0, 0.0)).r;
	float p2 = HOOKED_tex(base_pos).r;
	float p3 = HOOKED_tex(base_pos + HOOKED_pt * vec2(1.0, 0.0)).r;
	float p4 = HOOKED_tex(base_pos + HOOKED_pt * vec2(2.0, 0.0)).r;
	return cubic_interp(p1, p2, p3, p4);
}

float interpolate_vertical(vec2 base_pos) {
	float p1 = HOOKED_tex(base_pos + HOOKED_pt * vec2(0.0, -1.0)).r;
	float p2 = HOOKED_tex(base_pos).r;
	float p3 = HOOKED_tex(base_pos + HOOKED_pt * vec2(0.0, 1.0)).r;
	float p4 = HOOKED_tex(base_pos + HOOKED_pt * vec2(0.0, 2.0)).r;
	return cubic_interp(p1, p2, p3, p4);
}

vec4 hook() {

	vec2 output_pos = HOOKED_pos * HOOKED_size * 2.0;
	ivec2 output_pixel = ivec2(output_pos);
	bool x_odd = (output_pixel.x & 1) == 1;
	bool y_odd = (output_pixel.y & 1) == 1;

	ivec2 src_idx = output_pixel / 2;
	vec2 base_pos = (vec2(src_idx) + 0.5) * HOOKED_pt;

	float result;
	if (!x_odd && !y_odd) {
		// Original pixel - copy from source
		result = HOOKED_tex(base_pos).r;
	} else if (x_odd && !y_odd) {
		// Horizontal interpolation: between src_idx.x and src_idx.x+1
		result = interpolate_horizontal(base_pos);
	} else if (!x_odd && y_odd) {
		// Vertical interpolation: between src_idx.y and src_idx.y+1
		result = interpolate_vertical(base_pos);
	} else {
		// Diagonal interpolation: between 4 source pixels
		result = interpolate_diagonal(base_pos);
	}

	return vec4(result, 0.0, 0.0, 1.0);

}

