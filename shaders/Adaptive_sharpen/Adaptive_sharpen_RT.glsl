// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- RAW ver.
  https://github.com/bacondither/Adaptive-sharpen/blob/master/LICENSE
  --- RAW ver2.
  https://github.com/bacondither/Miscellaneous-shaders/tree/master/Adaptive-sharpen%20-%20DX11

*/


//!PARAM STR
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 2.0
1.0


//!HOOK SCALED
//!BIND HOOKED
//!SAVE ASPRE
//!DESC [Adaptive_sharpen_RT] edge detection
//!WHEN STR

//======================================= Settings ================================================
#define fast_length       0                    // Fast length using aproximate sqrt
#define a_offset          2.0                  // Edge channel offset, MUST BE THE SAME IN ALL PASSES
//=================================================================================================

#define get_pass1(x, y)   (HOOKED_texOff(vec2(x, y)))
#if (fast_length == 1)
	#define LENGTH(v)     ( intBitsToFloat(0x1FBD1DF5 + (floatBitsToInt(dot(v, v)) >> 1)) )
#else
	#define LENGTH(v)     ( length(v) )
#endif
// Component-wise distance
#define b_diff(pix)       ( abs(blur - c[pix]) )

vec4 hook()
{

	vec3 cO = get_pass1(0, 0).rgb;
	// Get points and clip out of range values (BTB & WTW)
	// [                c9                ]
	// [           c1,  c2,  c3           ]
	// [      c10, c4,  c0,  c5, c11      ]
	// [           c6,  c7,  c8           ]
	// [                c12               ]
	vec3 c[13] = { clamp(cO, 0.0, 1.0), clamp(get_pass1(-1,-1).rgb, 0.0, 1.0), clamp(get_pass1( 0,-1).rgb, 0.0, 1.0), clamp(get_pass1( 1,-1).rgb, 0.0, 1.0), clamp(get_pass1(-1, 0).rgb, 0.0, 1.0),
				   clamp(get_pass1( 1, 0).rgb, 0.0, 1.0), clamp(get_pass1(-1, 1).rgb, 0.0, 1.0), clamp(get_pass1( 0, 1).rgb, 0.0, 1.0), clamp(get_pass1( 1, 1).rgb, 0.0, 1.0), clamp(get_pass1( 0,-2).rgb, 0.0, 1.0),
				   clamp(get_pass1(-2, 0).rgb, 0.0, 1.0), clamp(get_pass1( 2, 0).rgb, 0.0, 1.0), clamp(get_pass1( 0, 2).rgb, 0.0, 1.0) };

	// Gauss blur 3x3
	vec3 blur = (2.0*(c[2]+c[4]+c[5]+c[7]) + (c[1]+c[3]+c[6]+c[8]) + 4.0*c[0])/16.0;

	// Contrast compression, center = 0.5, scaled to 1/3
	float c_comp = clamp(4.0/15.0 + 0.9*exp2(dot(blur, vec3(-37.0/15.0))), 0.0, 1.0);

	// Edge detection
	// Relative matrix weights
	// [          1          ]
	// [      4,  5,  4      ]
	// [  1,  5,  6,  5,  1  ]
	// [      4,  5,  4      ]
	// [          1          ]
	float edge = LENGTH( 1.38*(b_diff(0))
					   + 1.15*(b_diff(2) + b_diff(4)  + b_diff(5)  + b_diff(7))
					   + 0.92*(b_diff(1) + b_diff(3)  + b_diff(6)  + b_diff(8))
					   + 0.23*(b_diff(9) + b_diff(10) + b_diff(11) + b_diff(12)) );

	return vec4(cO, edge*c_comp + a_offset);

}

//!HOOK SCALED
//!BIND ASPRE
//!DESC [Adaptive_sharpen_RT] sharpening
//!WHEN STR

//======================================= Settings ================================================
#define video_level_out false                // True to preserve BTB & WTW (minor summation error)
                                             // Normally it should be set to false
//-------------------------------------------------------------------------------------------------
#define quality_mode    1                    // Use HQ original code path (set in both passes)
#define fskip           0                    // Skip limiting on flat areas where sharpdiff is low
//=================================================================================================
// Defined values under this row are "optimal" DO NOT CHANGE IF YOU DO NOT KNOW WHAT YOU ARE DOING!
#define curveslope      0.5                  // Sharpening curve slope, high edge values
//-------------------------------------------------------------------------------------------------
#define L_overshoot     0.003                // Max light overshoot before compression [>0.001]
#define L_compr_low     0.167                // Light compression, default (0.167=~6x)
#define L_compr_high    0.334                // Light compression, surrounded by edges (0.334=~3x)
//-------------------------------------------------------------------------------------------------
#define D_overshoot     0.009                // Max dark overshoot before compression [>0.001]
#define D_compr_low     0.250                // Dark compression, default (0.250=4x)
#define D_compr_high    0.500                // Dark compression, surrounded by edges (0.500=2x)
//-------------------------------------------------------------------------------------------------
#define scale_lim       0.1                  // Abs max change before compression [>0.01]
#define scale_cs        0.056                // Compression slope above scale_lim [0.0-1.0]
//-------------------------------------------------------------------------------------------------
#define dW_lothr        0.3                  // Start interpolating between W1 and W2
#define dW_hithr        0.8                  // When dW is equal to W2
//-------------------------------------------------------------------------------------------------
#define lowthr_mxw      0.1                  // Edge value for max lowthr weight [>0.01]
//-------------------------------------------------------------------------------------------------
#define pm_p            0.7                  // Power mean p-value [>0.0-1.0]
//-------------------------------------------------------------------------------------------------
#define alpha_out       1.0                  // MPDN requires the alpha channel output to be 1.0
//=================================================================================================
#define a_offset        2.0                  // Edge channel offset, MUST BE THE SAME IN ALL PASSES
#define bounds_check    true                 // If edge data is outside bounds, make pixels green
//=================================================================================================

#define get(x,y)               (ASPRE_texOff(vec2(x, y)))
#define sqr(a)                 ((a)*(a))
#define max3(a,b,c)            (max(max(a, b), c))
#define max4(a,b,c,d)          (max(max(a, b), max(c, d)))
#define satc(var)              (vec4(clamp((var).rgb, 0.0, 1.0), (var).a))
// Soft if, fast linear approx
#define soft_if(a,b,c)         ( clamp((a + b + c - 3.0*a_offset + 0.056)/(abs(maxedge) + 0.03) - 0.85, 0.0, 1.0) )
// Soft limit, modified tanh
#if (quality_mode == 0) // Tanh approx
	#define soft_lim(v,s)      ( clamp(abs(v/s)*(27.0 + sqr(v/s))/(27.0 + 9.0*sqr(v/s)), 0.0, 1.0)*s )
#else
	#define soft_lim(v,s)      ( (exp(2.0*min(abs(v), s*24.0)/s) - 1.0)/(exp(2.0*min(abs(v), s*24.0)/s) + 1.0)*s )
#endif
// Fast-skip threshold, keep max possible luma error under 0.5/2^bit-depth
#if (quality_mode == 0)
	// Approx of x = tanh(x/y)*y + 0.5/2^bit-depth, y = min(L_overshoot, D_overshoot)
	#define min_overshoot      ( min(abs(L_overshoot), abs(D_overshoot)) )
	#define fskip_th           ( 0.045*pow(min_overshoot, 0.667) + 1.75e-5 ) // 14-bits
#else
	// x = tanh(x/y)*y + 0.5/2^bit-depth, y = 0.0001
	#define fskip_th           ( 0.0000643723 ) // 16-bits
#endif
// Weighted power mean
#define wpmean(a,b,w)          ( pow(w*pow(abs(a), pm_p) + abs(1.0-w)*pow(abs(b), pm_p), (1.0/pm_p)) )
// Colour to luma, fast approx gamma, avg of rec. 709 & 601 luma coeffs
#define CtL(var)               ( sqrt(dot(vec3(0.2558, 0.6511, 0.0931), clamp((var)*abs(var), 0.0, 1.0).rgb)) )
// Center pixel diff
#define mdiff(a,b,c,d,e,f,g)   ( abs(luma[g] - luma[a]) + abs(luma[g] - luma[b]) + abs(luma[g] - luma[c]) + abs(luma[g] - luma[d]) + 0.5*(abs(luma[g] - luma[e]) + abs(luma[g] - luma[f])) )

vec4 hook()
{

	vec4 cO = get(0, 0);
	float c_edge = cO.a - a_offset;

	if (bounds_check == true)
	{
		if (c_edge > 16.0 || c_edge < -0.5) { return vec4( 0.0, 1.0, 0.0, alpha_out ); }
	}

	vec4 c[25] = { satc( cO ), get(-1,-1), get( 0,-1), get( 1,-1), get(-1, 0),
				   get( 1, 0), get(-1, 1), get( 0, 1), get( 1, 1), get( 0,-2),
				   get(-2, 0), get( 2, 0), get( 0, 2), get( 0, 3), get( 1, 2),
				   get(-1, 2), get( 3, 0), get( 2, 1), get( 2,-1), get(-3, 0),
				   get(-2, 1), get(-2,-1), get( 0,-3), get( 1,-2), get(-1,-2) };

	// Allow for higher overshoot if the current edge pixel is surrounded by similar edge pixels
	float maxedge = max4( max4(c[1].a,c[2].a,c[3].a,c[4].a), max4(c[5].a,c[6].a,c[7].a,c[8].a),
						  max4(c[9].a,c[10].a,c[11].a,c[12].a), c[0].a ) - a_offset;

	float sbe = soft_if(c[2].a,c[9].a, c[22].a)*soft_if(c[7].a,c[12].a,c[13].a)  // x dir
			  + soft_if(c[4].a,c[10].a,c[19].a)*soft_if(c[5].a,c[11].a,c[16].a)  // y dir
			  + soft_if(c[1].a,c[24].a,c[21].a)*soft_if(c[8].a,c[14].a,c[17].a)  // z dir
			  + soft_if(c[3].a,c[23].a,c[18].a)*soft_if(c[6].a,c[20].a,c[15].a); // w dir

	vec2 cs;
	#if (quality_mode == 0)
		cs = mix( vec2(L_compr_low,  D_compr_low),
				  vec2(L_compr_high, D_compr_high), clamp(1.091*sbe - 2.282, 0.0, 1.0) );
	#else
		cs = mix( vec2(L_compr_low,  D_compr_low),
				  vec2(L_compr_high, D_compr_high), smoothstep(2.0, 3.1, sbe) );
	#endif

	// RGB to luma
	float c0_Y = CtL(c[0]);

	float luma[25] = float[]( c0_Y, CtL(c[1]), CtL(c[2]), CtL(c[3]), CtL(c[4]), CtL(c[5]), CtL(c[6]),
							  CtL(c[7]),  CtL(c[8]),  CtL(c[9]),  CtL(c[10]), CtL(c[11]), CtL(c[12]),
							  CtL(c[13]), CtL(c[14]), CtL(c[15]), CtL(c[16]), CtL(c[17]), CtL(c[18]),
							  CtL(c[19]), CtL(c[20]), CtL(c[21]), CtL(c[22]), CtL(c[23]), CtL(c[24]) );

	// Pre-calculated default squared kernel weights
	const vec3 W1 = vec3(0.5,           1.0, 1.41421356237); // 0.25, 1.0, 2.0
	const vec3 W2 = vec3(0.86602540378, 1.0, 0.54772255751); // 0.75, 1.0, 0.3

	// Transition to a concave kernel if the center edge val is above thr
	vec3 dW;
	#if (quality_mode == 0)
		dW = sqr(mix( W1, W2, clamp(2.4*c_edge - 0.82, 0.0, 1.0) ));
	#else
		dW = sqr(mix( W1, W2, smoothstep(dW_lothr, dW_hithr, c_edge) ));
	#endif

	float mdiff_c0 = 0.02 + 3.0*( abs(luma[0]-luma[2]) + abs(luma[0]-luma[4])
							   + abs(luma[0]-luma[5]) + abs(luma[0]-luma[7])
							   + 0.25*(abs(luma[0]-luma[1]) + abs(luma[0]-luma[3])
									  +abs(luma[0]-luma[6]) + abs(luma[0]-luma[8])) );

	// Use lower weights for pixels in a more active area relative to center pixel area
	float weights[12] = float[]( ( min(mdiff_c0/mdiff(24, 21, 2,  4,  9,  10, 1),  dW.y) ),   // c1
								 ( dW.x ),                                                    // c2
								 ( min(mdiff_c0/mdiff(23, 18, 5,  2,  9,  11, 3),  dW.y) ),   // c3
								 ( dW.x ),                                                    // c4
								 ( dW.x ),                                                    // c5
								 ( min(mdiff_c0/mdiff(4,  20, 15, 7,  10, 12, 6),  dW.y) ),   // c6
								 ( dW.x ),                                                    // c7
								 ( min(mdiff_c0/mdiff(5,  7,  17, 14, 12, 11, 8),  dW.y) ),   // c8
								 ( min(mdiff_c0/mdiff(2,  24, 23, 22, 1,  3,  9),  dW.z) ),   // c9
								 ( min(mdiff_c0/mdiff(20, 19, 21, 4,  1,  6,  10), dW.z) ),   // c10
								 ( min(mdiff_c0/mdiff(17, 5,  18, 16, 3,  8,  11), dW.z) ),   // c11
								 ( min(mdiff_c0/mdiff(13, 15, 7,  14, 6,  8,  12), dW.z) ) ); // c12

	weights[0] = (max3((weights[8]  + weights[9])/4.0,  weights[0], 0.25) + weights[0])/2.0;
	weights[2] = (max3((weights[8]  + weights[10])/4.0, weights[2], 0.25) + weights[2])/2.0;
	weights[5] = (max3((weights[9]  + weights[11])/4.0, weights[5], 0.25) + weights[5])/2.0;
	weights[7] = (max3((weights[10] + weights[11])/4.0, weights[7], 0.25) + weights[7])/2.0;

	// Calculate the negative part of the laplace kernel and the low threshold weight
	float lowthrsum   = 0.0;
	float weightsum   = 0.0;
	float neg_laplace = 0.0;
	for (int pix = 0; pix < 12; ++pix)
	{
		#if (quality_mode == 0)
			float lowthr = clamp((13.2*c[pix + 1].a - a_offset - 0.221), 0.01, 1.0);
			neg_laplace += sqr(luma[pix + 1])*(abs(weights[pix])*lowthr);
		#else
			float t = clamp((c[pix + 1].a - a_offset - 0.01)/0.09, 0.0, 1.0);
			float lowthr = t*t*(2.97 - 1.98*t) + 0.01; // t*t*(3 - a*3 - (2 - a*2)*t) + a
			neg_laplace += pow(abs(luma[pix + 1]) + 0.06, 2.4)*(abs(weights[pix])*lowthr);
		#endif
		weightsum += abs(weights[pix])*lowthr;
		lowthrsum += lowthr/12.0;
	}

	#if (quality_mode == 0)
		neg_laplace = sqrt(neg_laplace/weightsum);
	#else
		neg_laplace = clamp(pow(neg_laplace/weightsum, (1.0/2.4)) - 0.06, 0.0, 1.0);
	#endif

	// Compute sharpening magnitude function
	float sharpen_val = STR/(STR*curveslope*pow(abs(c_edge), 3.5) + 0.625);

	// Calculate sharpening diff and scale
	float sharpdiff = (c0_Y - neg_laplace)*(lowthrsum*sharpen_val + 0.01);

#if (fskip == 1)
	if (abs(sharpdiff) > fskip_th)
	{
#endif
		// Calculate local near min & max, partial sort
		float temp;
		// 1st iteration
		for (int i = 0; i < 24; i += 2) { temp = luma[i]; luma[i] = min(luma[i], luma[i+1]); luma[i+1] = max(temp, luma[i+1]); }
		for (int ii = 24; ii > 0; ii -= 2) { temp = luma[0]; luma[0] = min(luma[0], luma[ii]); luma[ii] = max(temp, luma[ii]); temp = luma[24]; luma[24] = max(luma[24], luma[ii-1]); luma[ii-1] = min(temp, luma[ii-1]); }
		// 2nd iteration
		for (int i = 1; i < 23; i += 2) { temp = luma[i]; luma[i] = min(luma[i], luma[i+1]); luma[i+1] = max(temp, luma[i+1]); }
		for (int ii = 23; ii > 1; ii -= 2) { temp = luma[1]; luma[1] = min(luma[1], luma[ii]); luma[ii] = max(temp, luma[ii]); temp = luma[23]; luma[23] = max(luma[23], luma[ii-1]); luma[ii-1] = min(temp, luma[ii-1]); }
		#if (quality_mode != 0) // 3rd iteration
			for (int i = 2; i < 22; i += 2) { temp = luma[i]; luma[i] = min(luma[i], luma[i+1]); luma[i+1] = max(temp, luma[i+1]); }
			for (int ii = 22; ii > 2; ii -= 2) { temp = luma[2]; luma[2] = min(luma[2], luma[ii]); luma[ii] = max(temp, luma[ii]); temp = luma[22]; luma[22] = max(luma[22], luma[ii-1]); luma[ii-1] = min(temp, luma[ii-1]); }
		#endif

		// Calculate tanh scale factors
		vec2 pn_scale;
		#if (quality_mode == 0)
			float nmax = (max(luma[23], c0_Y)*2.0 + luma[24])/3.0;
			float nmin = (min(luma[1],  c0_Y)*2.0 + luma[0])/3.0;
			float min_dist  = min(abs(nmax - c0_Y), abs(c0_Y - nmin));
			pn_scale = min_dist + vec2(L_overshoot, D_overshoot);
		#else
			float nmax = (max(luma[22] + luma[23]*2.0, c0_Y*3.0) + luma[24])/4.0;
			float nmin = (min(luma[2]  + luma[1]*2.0,  c0_Y*3.0) + luma[0])/4.0;
			float min_dist  = min(abs(nmax - c0_Y), abs(c0_Y - nmin));
			pn_scale = vec2( min(L_overshoot + min_dist, 1.0001 - c0_Y),
							 min(D_overshoot + min_dist, 0.0001 + c0_Y) );
		#endif

		pn_scale = min(pn_scale, scale_lim*(1.0 - scale_cs) + pn_scale*scale_cs);

		// Soft limited anti-ringing with tanh, wpmean to control compression slope
		sharpdiff = wpmean( max(sharpdiff, 0.0), soft_lim( max(sharpdiff, 0.0), pn_scale.x ), cs.x )
				  - wpmean( min(sharpdiff, 0.0), soft_lim( min(sharpdiff, 0.0), pn_scale.y ), cs.y );
#if (fskip == 1)
	}
#endif

	// Compensate for saturation loss/gain while making pixels brighter/darker
	float sharpdiff_lim = clamp(c0_Y + sharpdiff, 0.0, 1.0) - c0_Y;
	float satmul = (c0_Y + max(sharpdiff_lim*0.9, sharpdiff_lim)*1.03 + 0.03)/(c0_Y + 0.03);
	vec3 res = c0_Y + (sharpdiff_lim*3.0 + sharpdiff)/4.0 + (c[0].rgb - c0_Y)*satmul;

	return vec4( (video_level_out == true ? res + cO.rgb - c[0].rgb : res), alpha_out );

}

