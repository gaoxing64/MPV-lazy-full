// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- PAPER ver.
  https://www.intel.com/content/www/us/en/developer/articles/technical/conservative-morphological-anti-aliasing-20.html
  --- RAW ver.
  https://github.com/GameTechDev/CMAA2/blob/master/license.txt
  --- Magpie ver.
  https://github.com/Blinue/Magpie/blob/main/LICENSE

*/


//!HOOK MAIN
//!BIND HOOKED
//!DESC [Intel_CMAA2_lite]

// Adjustable parameters - ULTRA QUALITY PRESET
//--------------------------------------
#define CMAA_EDGE_THRESHOLD 0.045                   // Edge detection threshold - lower values detect more edges
                                                    // Further reduced for ultra-quality anti-aliasing
#define CMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR 1.1   // Controls how much local contrast affects edge importance
                                                    // Increased for better handling of complex edge patterns
#define CMAA_CORNER_ROUNDING 0.35                   // Controls how much corners are rounded during anti-aliasing
                                                    // Increased for smoother corner transitions
#define CMAA_MAX_BLEND_FACTOR 0.75                  // Maximum blend factor - prevents over-blurring
                                                    // Carefully balanced for smoothing without loss of detail
#define CMAA_EARLY_EXIT_THRESHOLD 0.005             // Early exit threshold for subtle edges
                                                    // Further lowered to catch very subtle aliasing artifacts
#define CMAA_MAX_SEARCH_STEPS 32                    // Maximum steps when searching along edges
                                                    // Significantly increased for ultra-quality detection of longer edges
#define CMAA_SECONDARY_SEARCH_STEPS 16              // Multi-directional search steps
                                                    // New parameter for enhanced edge tracking
#define CMAA_COLOR_MATCHING_TOLERANCE 0.05          // Enhanced color matching tolerance
                                                    // New parameter for improved edge handling

// Helper function to calculate perceptual luminance from RGB
// Using Rec. 709 coefficients for accurate perceptual brightness
float ComputeLuma(vec3 color) {
	return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

// Enhanced luminance calculation that accounts for color differences
float ComputeEnhancedLuma(vec3 color1, vec3 color2) {
	float lumaDiff = ComputeLuma(color1) - ComputeLuma(color2);
	float colorDiff = length(color1 - color2);
	// Combine luma and color differences for better edge detection
	return abs(lumaDiff) + colorDiff * 0.3;
}

// Enhanced search along an edge direction
vec4 SearchAlongEdge(vec2 uv, vec2 direction, int maxSteps) {
	float edgeStrength = 0.0f;
	vec2 finalOffset = vec2(0, 0);
	float stepCount = 0;
	float consistencyFactor = 1.0f;
	vec3 originalColor = HOOKED_tex(uv).rgb;
	vec3 prevSampleColor = originalColor;
	for (int i = 1; i <= maxSteps; i++) {
		vec2 samplePos = uv + direction * i * HOOKED_pt;
		// Sample neighborhood at this position
		vec3 colorCenter = HOOKED_tex(samplePos).rgb;
		vec3 colorLeft = HOOKED_tex(samplePos + vec2(-HOOKED_pt.x, 0)).rgb;
		vec3 colorRight = HOOKED_tex(samplePos + vec2(HOOKED_pt.x, 0)).rgb;
		vec3 colorTop = HOOKED_tex(samplePos + vec2(0, -HOOKED_pt.y)).rgb;
		vec3 colorBottom = HOOKED_tex(samplePos + vec2(0, HOOKED_pt.y)).rgb;
		// Enhanced edge detection using both luma and color differences
		float edgeHorizontal = ComputeEnhancedLuma(colorTop, colorCenter) + ComputeEnhancedLuma(colorBottom, colorCenter);
		float edgeVertical = ComputeEnhancedLuma(colorLeft, colorCenter) + ComputeEnhancedLuma(colorRight, colorCenter);
		// Compute overall edge strength
		float sampleStrength = max(edgeHorizontal, edgeVertical);
		// Check color consistency along the edge (prevents crossing different edges)
		float colorConsistency = 1.0f - clamp(length(colorCenter - prevSampleColor) * 3.0f, 0.0, 1.0);
		consistencyFactor = min(consistencyFactor, colorConsistency);
		if (sampleStrength > CMAA_EDGE_THRESHOLD && consistencyFactor > 0.3f) {
			// Weight by distance (closer samples have more influence)
			float distanceWeight = 1.0f / (1.0f + i * 0.05f);
			float weightedStrength = sampleStrength * distanceWeight;
			if (weightedStrength > edgeStrength * 0.7f) {
				edgeStrength = max(edgeStrength, weightedStrength);
				finalOffset = direction * i * HOOKED_pt;
				stepCount = i;
				// Store for consistency check
				prevSampleColor = colorCenter;
			}
		} else if (i > 4 && consistencyFactor < 0.3f) {
			// Early termination if we're crossing a different edge
			break;
		}
	}
	// Scale strength by consistency factor
	edgeStrength *= consistencyFactor;
	return vec4(finalOffset.x, finalOffset.y, edgeStrength, stepCount);
}

// Enhanced multi-directional search
vec4 MultiDirectionalSearch(vec2 uv) {
	// Define 8 search directions for comprehensive edge detection
	const vec2 directions[8] = vec2[](
		vec2(1, 0),    // Right
		vec2(-1, 0),   // Left
		vec2(0, 1),    // Down
		vec2(0, -1),   // Up
		vec2(1, 1),    // Bottom-right
		vec2(-1, -1),  // Top-left
		vec2(1, -1),   // Top-right
		vec2(-1, 1)    // Bottom-left
	);
	vec4 bestSearch = vec4(0, 0, 0, 0);
	// Search in each direction
	for (int i = 0; i < 8; i++) {
		vec4 search = SearchAlongEdge(uv, directions[i],
									  (i < 4) ? CMAA_MAX_SEARCH_STEPS : CMAA_SECONDARY_SEARCH_STEPS);
		// Keep the strongest edge
		if (search.z > bestSearch.z) {
			bestSearch = search;
		}
	}
	return bestSearch;
}

vec4 hook() {

	vec2 pos = HOOKED_pos;
	vec2 texelSize = HOOKED_pt;

	// 1. SAMPLE PIXEL NEIGHBORHOOD
	//-----------------------------------------------------------
	vec4 originalColor = HOOKED_tex(pos);
	vec3 center = originalColor.rgb;

	// Expanded 5x5 neighborhood sampling for higher quality
	// 3x3 core neighborhood
	vec3 top = HOOKED_texOff(vec2(0, -1)).rgb;
	vec3 right = HOOKED_texOff(vec2(1, 0)).rgb;
	vec3 bottom = HOOKED_texOff(vec2(0, 1)).rgb;
	vec3 left = HOOKED_texOff(vec2(-1, 0)).rgb;

	vec3 topLeft = HOOKED_texOff(vec2(-1, -1)).rgb;
	vec3 topRight = HOOKED_texOff(vec2(1, -1)).rgb;
	vec3 bottomLeft = HOOKED_texOff(vec2(-1, 1)).rgb;
	vec3 bottomRight = HOOKED_texOff(vec2(1, 1)).rgb;

	// Extended samples for better pattern detection
	vec3 top2 = HOOKED_texOff(vec2(0, -2)).rgb;
	vec3 right2 = HOOKED_texOff(vec2(2, 0)).rgb;
	vec3 bottom2 = HOOKED_texOff(vec2(0, 2)).rgb;
	vec3 left2 = HOOKED_texOff(vec2(-2, 0)).rgb;

	// 2. CALCULATE LUMINANCE VALUES WITH ENHANCED COLOR PERCEPTION
	//-----------------------------------------------------------
	float lumaCenter = ComputeLuma(center);

	float lumaTop = ComputeLuma(top);
	float lumaRight = ComputeLuma(right);
	float lumaBottom = ComputeLuma(bottom);
	float lumaLeft = ComputeLuma(left);

	float lumaTopLeft = ComputeLuma(topLeft);
	float lumaTopRight = ComputeLuma(topRight);
	float lumaBottomLeft = ComputeLuma(bottomLeft);
	float lumaBottomRight = ComputeLuma(bottomRight);

	// Extended luma calculations
	float lumaTop2 = ComputeLuma(top2);
	float lumaRight2 = ComputeLuma(right2);
	float lumaBottom2 = ComputeLuma(bottom2);
	float lumaLeft2 = ComputeLuma(left2);

	// Adaptive local contrast enhancement for sharper edge detection
	// Calculate local contrast range
	float minLuma = min(min(min(lumaTop, lumaBottom), min(lumaLeft, lumaRight)), lumaCenter);
	float maxLuma = max(max(max(lumaTop, lumaBottom), max(lumaLeft, lumaRight)), lumaCenter);
	float lumaRange = maxLuma - minLuma;

	// Apply adaptive sharpening based on local contrast
	float adaptiveSharpen = 0.3f - 0.2f * clamp(lumaRange * 4.0f, 0.0, 1.0);
	float lumaSharpened = lumaCenter * (1.0f + 4.0f * adaptiveSharpen) -
						 (lumaTopLeft + lumaTopRight + lumaBottomLeft + lumaBottomRight) * adaptiveSharpen;

	// Blend sharpened luma with original for enhanced edge detection
	lumaCenter = mix(lumaCenter, lumaSharpened, 0.3f);

	// 3. DETECT EDGES WITH ENHANCED PRECISION
	//-----------------------------------------------------------
	// Primary edge detection (immediate neighbors)
	float edgeHorizontal = abs(lumaLeft - lumaCenter) + abs(lumaRight - lumaCenter);
	float edgeVertical = abs(lumaTop - lumaCenter) + abs(lumaBottom - lumaCenter);
	float edgeDiagonal1 = abs(lumaTopLeft - lumaCenter) + abs(lumaBottomRight - lumaCenter);
	float edgeDiagonal2 = abs(lumaTopRight - lumaCenter) + abs(lumaBottomLeft - lumaCenter);

	// Secondary edge detection (extended neighbors for smoother gradients)
	float edgeHorizontalExt = abs(lumaLeft2 - lumaLeft) + abs(lumaRight2 - lumaRight);
	float edgeVerticalExt = abs(lumaTop2 - lumaTop) + abs(lumaBottom2 - lumaBottom);

	// Combine primary and extended edge detection (with lower weight for extended)
	edgeHorizontal += edgeHorizontalExt * 0.3f;
	edgeVertical += edgeVerticalExt * 0.3f;

	// Early exit if no significant edges are found
	if (max(max(edgeHorizontal, edgeVertical), max(edgeDiagonal1, edgeDiagonal2)) <= CMAA_EARLY_EXIT_THRESHOLD) {
		return originalColor;
	}

	// Determine edge types with adaptive thresholds based on local contrast
	float adaptiveThreshold = CMAA_EDGE_THRESHOLD * (0.8f + 0.2f * clamp(lumaRange * 2.0f, 0.0, 1.0));

	bool hasHorzEdge = edgeHorizontal >= adaptiveThreshold;
	bool hasVertEdge = edgeVertical >= adaptiveThreshold;
	bool hasDiag1Edge = edgeDiagonal1 >= adaptiveThreshold;
	bool hasDiag2Edge = edgeDiagonal2 >= adaptiveThreshold;

	// If no edges were found, return the original color
	if (!hasHorzEdge && !hasVertEdge && !hasDiag1Edge && !hasDiag2Edge) {
		return originalColor;
	}

	// 4. ENHANCED SHAPE DETECTION
	//-----------------------------------------------------------
	// Multi-directional edge search for comprehensive edge detection
	vec4 edgeSearch = MultiDirectionalSearch(pos);
	float edgeStrength = edgeSearch.z;
	vec2 edgeOffset = vec2(edgeSearch.x, edgeSearch.y);

	// Determine if we have a complex edge pattern requiring special handling
	bool isComplex = (hasHorzEdge && hasVertEdge) || (hasDiag1Edge && hasDiag2Edge);

	// Adaptive pattern recognition
	float zStrength = 0.0f;
	float lStrength = 0.0f;
	vec2 zDirection = vec2(0, 0);

	// Detect L-junctions with enhanced accuracy (horizontal + vertical edges)
	if (hasHorzEdge && hasVertEdge) {
		vec4 horizontal = SearchAlongEdge(pos, vec2(1, 0), CMAA_MAX_SEARCH_STEPS);
		vec4 vertical = SearchAlongEdge(pos, vec2(0, 1), CMAA_MAX_SEARCH_STEPS);

		// Analyze shape consistency
		bool isLShaped = horizontal.w > 3 && vertical.w > 3;

		if (isLShaped) {
			// Enhanced L-junction strength calculation
			lStrength = min(horizontal.z, vertical.z) * CMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR;

			// Adjust strength based on junction angle
			vec2 hDir = normalize(vec2(horizontal.xy));
			vec2 vDir = normalize(vec2(vertical.xy));
			float dotProduct = abs(dot(hDir, vDir));

			// Strengthen L-detection when vectors are perpendicular (dot product near 0)
			lStrength *= (1.0f - dotProduct);
		}
	}

	// Detect Z-shapes with enhanced accuracy (diagonal edges)
	if (hasDiag1Edge || hasDiag2Edge) {
		vec2 diagonalDir = (edgeDiagonal1 > edgeDiagonal2) ? vec2(1, 1) : vec2(1, -1);
		vec4 diagonalSearch = SearchAlongEdge(pos, diagonalDir, CMAA_MAX_SEARCH_STEPS);

		zStrength = diagonalSearch.z * CMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR;
		zDirection = diagonalDir * normalize(diagonalSearch.xy);

		// Enhance Z detection with orthogonal search
		vec2 orthogonalDir = vec2(-diagonalDir.y, diagonalDir.x);
		vec4 orthogonalSearch = SearchAlongEdge(pos, orthogonalDir, CMAA_SECONDARY_SEARCH_STEPS);

		// If we found strong edges in both directions, this is a crosspoint, not a Z
		if (orthogonalSearch.z > zStrength * 0.5f) {
			zStrength *= 0.8f; // Reduce Z strength at crosspoints
		}
	}

	// 5. APPLY ENHANCED ANTI-ALIASING WITH QUALITY OPTIMIZATIONS
	//-----------------------------------------------------------
	vec3 result = center;
	float totalBlendWeight = 0;

	// Process Z-shapes (diagonal edges) with enhanced quality
	if (zStrength > 0.1f) {
		// Refine direction based on local gradient and color consistency
		vec2 gradient = vec2(
			lumaRight - lumaLeft,
			lumaBottom - lumaTop
		);

		if (length(gradient) > 0.01) {
			vec2 gradientNorm = normalize(gradient);
			zDirection = normalize(mix(zDirection, gradientNorm, 0.4));
		}

		// Adaptive multi-sample corner rounding
		float adaptiveCornerRounding = CMAA_CORNER_ROUNDING * (1.0f + 0.5f * zStrength);

		// Multi-tap sampling for higher quality blending
		const int numSamples = 3; // Increased from original
		vec3 color1 = vec3(0.0);
		vec3 color2 = vec3(0.0);
		float totalWeight = 0;

		for (int i = -(numSamples-1)/2; i <= (numSamples-1)/2; i++) {
			float weight = 1.0f - abs(float(i)) / (float(numSamples) * 0.5f);

			// Primary direction sampling
			vec2 offset1 = zDirection * texelSize * adaptiveCornerRounding;
			vec2 offset2 = -offset1;

			// Perpendicular offset for better area coverage
			vec2 perpOffset = vec2(-zDirection.y, zDirection.x) * texelSize * float(i) * 0.7f;

			// Enhanced anisotropic sampling
			color1 += HOOKED_tex(pos + offset1 + perpOffset).rgb * weight;
			color2 += HOOKED_tex(pos + offset2 + perpOffset).rgb * weight;
			totalWeight += weight * 2;
		}

		color1 /= totalWeight * 0.5f;
		color2 /= totalWeight * 0.5f;

		// Adaptive strength based on pattern confidence
		float patternConfidence = clamp(zStrength * 2.0f - 0.2f, 0.0, 1.0);
		float zBlendFactor = min(clamp(zStrength * 1.4f * patternConfidence, 0.0, 1.0), CMAA_MAX_BLEND_FACTOR);

		// Color-aware blending - preserve details in high-contrast or colored edges
		float colorDiff = length(color1 - color2);
		float colorPreservation = clamp(1.0f - colorDiff * 2.0f, 0.0, 1.0);

		// Calculate center-relative color preservation
		float centerColorDiff1 = length(center - color1);
		float centerColorDiff2 = length(center - color2);
		float centerColorPreservation = clamp(1.0f - min(centerColorDiff1, centerColorDiff2) * 3.0f, 0.0, 1.0);

		// Composite preservation factors
		float contrastFactor = mix(0.5f, 1.0f, colorPreservation * centerColorPreservation);

		result = mix(result, (color1 + color2) * 0.5f, zBlendFactor * contrastFactor);
		totalBlendWeight += zBlendFactor * contrastFactor;
	}

	// Process L-shapes (corners) with enhanced quality
	if (lStrength > 0.1f) {
		float adaptiveBlend = min(clamp(lStrength * 0.8f, 0.0, 1.0), CMAA_MAX_BLEND_FACTOR);

		// Enhanced corner detection samples
		vec3 avgColor = center * 2.0f;
		float totalWeight = 2.0f;

		// Create an enhanced sampling pattern (X-shaped)
		vec3 samples[8] = vec3[](
			left, right, top, bottom,
			topLeft, topRight, bottomLeft, bottomRight
		);
		float weights[8] = float[]( 1.0f, 1.0f, 1.0f, 1.0f, 0.7f, 0.7f, 0.7f, 0.7f );

		for (int i = 0; i < 8; i++) {
			// Adaptive weighting based on color similarity
			float colorSimilarity = clamp(1.0f - length(samples[i] - center) * 2.0f, 0.0, 1.0);
			float weight = weights[i] * (0.2f + 0.8f * colorSimilarity);

			avgColor += samples[i] * weight;
			totalWeight += weight;
		}

		avgColor /= totalWeight;

		// Adaptive corner strength
		float cornerConfidence = clamp(lStrength * 1.5f - 0.1f, 0.0, 1.0);
		float lBlendFactor = adaptiveBlend * cornerConfidence;

		result = mix(result, avgColor, lBlendFactor);
		totalBlendWeight += lBlendFactor;
	}

	// Process simple edges with enhanced handling for the most common case
	if (totalBlendWeight < 0.15f) {
		float edgeBlendFactor = 0.0f;
		vec3 edgeColor = vec3(0.0);

		// Enhanced horizontal edge handling
		if (hasHorzEdge) {
			// Compute directional gradients
			float topGrad = abs(lumaTop2 - lumaTop);
			float bottomGrad = abs(lumaBottom2 - lumaBottom);

			// Distance-based weighting
			float upDistance = ComputeEnhancedLuma(center, top);
			float downDistance = ComputeEnhancedLuma(center, bottom);

			float upWeight = 1.0f / (0.01f + upDistance) * (1.0f + topGrad);
			float downWeight = 1.0f / (0.01f + downDistance) * (1.0f + bottomGrad);
			float totalWeight = upWeight + downWeight;

			vec3 blendColor = (top * upWeight + bottom * downWeight) / totalWeight;
			float edgeIntensity = clamp((edgeHorizontal - CMAA_EDGE_THRESHOLD) / (0.1f + CMAA_EDGE_THRESHOLD), 0.0, 1.0);
			float blendStrength = min(clamp(edgeIntensity * 0.8f, 0.0, 1.0), CMAA_MAX_BLEND_FACTOR);

			edgeBlendFactor += blendStrength;
			edgeColor += blendColor * blendStrength;
		}

		// Enhanced vertical edge handling
		if (hasVertEdge) {
			// Compute directional gradients
			float leftGrad = abs(lumaLeft2 - lumaLeft);
			float rightGrad = abs(lumaRight2 - lumaRight);

			// Distance-based weighting
			float leftDistance = ComputeEnhancedLuma(center, left);
			float rightDistance = ComputeEnhancedLuma(center, right);

			float leftWeight = 1.0f / (0.01f + leftDistance) * (1.0f + leftGrad);
			float rightWeight = 1.0f / (0.01f + rightDistance) * (1.0f + rightGrad);
			float totalWeight = leftWeight + rightWeight;

			vec3 blendColor = (left * leftWeight + right * rightWeight) / totalWeight;
			float edgeIntensity = clamp((edgeVertical - CMAA_EDGE_THRESHOLD) / (0.1f + CMAA_EDGE_THRESHOLD), 0.0, 1.0);
			float blendStrength = min(clamp(edgeIntensity * 0.8f, 0.0, 1.0), CMAA_MAX_BLEND_FACTOR);

			edgeBlendFactor += blendStrength;
			edgeColor += blendColor * blendStrength;
		}

		if (edgeBlendFactor > 0) {
			edgeColor /= edgeBlendFactor;

			// Color preservation - adaptive blend based on color difference
			float colorDifference = length(edgeColor - center);
			float preservationFactor = clamp(1.0f - colorDifference * 2.0f, 0.0, 1.0);
			float finalEdgeBlend = min(edgeBlendFactor, CMAA_MAX_BLEND_FACTOR) * preservationFactor;

			result = mix(result, edgeColor, finalEdgeBlend);
			totalBlendWeight += finalEdgeBlend;
		}
	}

	// Prevent over-blending with intelligent capping
	if (totalBlendWeight > CMAA_MAX_BLEND_FACTOR) {
		// Smoother transition when capping blend weight
		float smoothCap = clamp(CMAA_MAX_BLEND_FACTOR / totalBlendWeight, 0.0, 1.0);
		smoothCap = pow(smoothCap, 0.75f); // Softens the transition

		result = mix(center, result, smoothCap * CMAA_MAX_BLEND_FACTOR);
	}

	// Final color preservation check - don't blur high contrast edges too much
	float finalColorDiff = length(result - center);
	if (finalColorDiff > 0.3f) {
		// Reduce blending to preserve important details
		float preservationFactor = clamp(1.0f - (finalColorDiff - 0.3f) * 2.0f, 0.0, 1.0);
		result = mix(center, result, preservationFactor);
	}

	return vec4(result, originalColor.a);

}

