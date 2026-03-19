// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- AN3223 ver.
  https://github.com/AN3223/dotfiles/blob/master/.config/mpv/shaders/hdeband.glsl

*/


//!PARAM S
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 10.0
0.0

//!PARAM SI
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 100.0
50.0

//!PARAM SR
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.0

//!PARAM SW
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 10.0
5.0

//!PARAM RADIUS
//!TYPE int
//!MINIMUM 1
//!MAXIMUM 32
16

//!PARAM SPARSITY
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 10.0
2.0

//!PARAM DIRECTIONS
//!TYPE int
//!MINIMUM 1
//!MAXIMUM 8
8

//!PARAM RUN_START
//!TYPE int
//!MINIMUM 0
//!MAXIMUM 1
1

//!PARAM TOLERANCE
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 0.1
0.0


//!HOOK MAIN
//!BIND HOOKED
//!DESC [hdeband_rgb_RT]

// Helper functions and macros
#define gaussian(x) exp(-1.0 * (x) * (x))
#define NOT(x) (1.0 - (x))

#define val vec3
#define val_swizz(v) (v.xyz)
#define unval(v) vec4(v.x, v.y, v.z, poi_.a)

vec4 hook()
{

	vec4 poi_ = HOOKED_texOff(vec2(0.0));
	val poi = val_swizz(poi_);

	val sum = poi * SW;
	val total_weight = val(SW);

	for (int dir = 0; dir < DIRECTIONS; dir++) {
		vec2 direction;
		switch (dir) {
			case 0: direction = vec2( 1, 0); break;
			case 1: direction = vec2(-1, 0); break;
			case 2: direction = vec2( 0, 1); break;
			case 3: direction = vec2( 0,-1); break;
			case 4: direction = vec2( 1, 1); break;
			case 5: direction = vec2(-1,-1); break;
			case 6: direction = vec2( 1,-1); break;
			case 7: direction = vec2(-1, 1); break;
		}

		val prev_px = poi;
		val prev_is_run = val(float(RUN_START));
		val prev_weight = val(0.0);
		val not_done = val(1.0);

		for (int i = 1; i <= RADIUS; i++) {
			vec2 coord = (float(i) + floor(float(i) * SPARSITY)) * direction;
			val px = val_swizz(HOOKED_texOff(coord));

			val is_run = step(abs(prev_px - px), val(TOLERANCE));
			val weight = val(gaussian(length(coord) * max(0.0, S)));

			not_done *= max(val(clamp(SR, 0.0, 1.0)),
						clamp(prev_is_run + is_run, 0.0, 1.0));

			weight *= gaussian(abs(poi - px) * max(0.0, SI));

			val prev_weight_compensate = NOT(prev_is_run) * prev_weight;

			prev_px = px;
			prev_is_run = is_run;
			prev_weight = weight;

			weight += prev_weight_compensate;
			weight *= is_run;

			sum += px * weight * not_done;
			total_weight += weight * not_done;
		}
	}

	val result = sum / total_weight;
	return unval(result);

}

