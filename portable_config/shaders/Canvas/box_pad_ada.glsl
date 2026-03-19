// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!HOOK MAIN
//!BIND HOOKED
//!DESC [box_pad_ada]
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h

vec4 hook() {

	float video_aspect = float(input_size.x) / float(input_size.y);
	float target_aspect = float(target_size.x) / float(target_size.y);
	vec2 scale;
	vec2 offset;

	if (video_aspect > target_aspect) {
		scale.x = 1.0;
		scale.y = target_aspect / video_aspect;
		offset.x = 0.0;
		offset.y = (1.0 - scale.y) / 2.0;
	} else {
		scale.y = 1.0;
		scale.x = video_aspect / target_aspect;
		offset.y = 0.0;
		offset.x = (1.0 - scale.x) / 2.0;
	}

	if (HOOKED_pos.x < offset.x || HOOKED_pos.x > (offset.x + scale.x) ||
		HOOKED_pos.y < offset.y || HOOKED_pos.y > (offset.y + scale.y))
	{
		return vec4(vec3(0.0), 1.0);
	} else {
		vec2 sample_pos = (HOOKED_pos - offset) / scale;
		return HOOKED_tex(sample_pos);
	}

}

