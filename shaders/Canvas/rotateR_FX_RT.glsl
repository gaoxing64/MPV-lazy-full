// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM STEP
//!TYPE DEFINE
//!MINIMUM 0
//!MAXIMUM 3
2

//!PARAM SPEED
//!TYPE float
0.5

//!PARAM NUM
//!TYPE int
//!MINIMUM 0
0

//!PARAM D
//!TYPE float
//!MINIMUM 0.5
//!MAXIMUM 1.0
0.96

//!PARAM BZ
//!TYPE float
//!MINIMUM 0.1
//!MAXIMUM 1.0
0.2

//!PARAM ZOOM
//!TYPE float
//!MINIMUM 0.5
//!MAXIMUM 2.0
1.0


//!HOOK OUTPUT
//!BIND HOOKED
//!DESC [rotateR_FX_RT]
//!WHEN STEP

vec4 hook() {

	vec2 pos = HOOKED_pos;
	vec2 size = HOOKED_size;
	vec2 align = vec2(0.5, 0.5);

#if (STEP == 1)
	float degree = 0.0;
#elif (STEP == 2)
	float degree = float(frame) * SPEED;
#elif (STEP == 3)
	float degree = float(NUM) * SPEED;
#endif

	float aspect_ratio = size.x / size.y;
	float angle = radians(degree);
	float cos_a = cos(angle);
	float sin_a = sin(angle);
	pos -= align;
	pos /= ZOOM;
	pos.x *= aspect_ratio;
	mat2 rotation_matrix = mat2(
		cos_a, -sin_a,
		sin_a,  cos_a
	);

	pos = rotation_matrix * pos;
	pos.x /= aspect_ratio;
	pos += align;
	if (any(lessThan(pos, vec2(0.0))) || any(greaterThan(pos, vec2(1.0)))) {
		return vec4(vec3(0.0), 1.0);
	}

	vec2 center = vec2(0.5, 0.5);
	vec2 dist_vec = (pos - center) * vec2(aspect_ratio, 1.0);
	float distance = length(dist_vec);
	float effective_radius = D * min(1.0, aspect_ratio) / 2.0;
	float inner_radius = effective_radius * (1.0 - BZ * 0.1);
	float outer_radius = effective_radius * (1.0 + BZ * 0.1);
	float alpha = smoothstep(outer_radius, inner_radius, distance);
	vec4 color = HOOKED_tex(pos);
	color.rgb *= alpha;
	if (distance > outer_radius) {
		return vec4(vec3(0.0), 1.0);
	}

	return color;

}

