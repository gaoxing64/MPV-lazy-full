// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL


//!PARAM MODE
//!TYPE int
//!MINIMUM 0
//!MAXIMUM 2
1

//!HOOK NATIVE
//!BIND HOOKED
//!DESC [plane_split_RT] Raw--Y//Cb--Cr
//!WHEN MODE 1 ==

vec4 hook() {

	vec2 pos = HOOKED_pos;
	float chroma_neutral = 0.5;

	if (pos.x < 0.5 && pos.y < 0.5) {
		vec2 texCoord = vec2(pos.x * 2.0, pos.y * 2.0);
		return HOOKED_tex(texCoord);
	}

	else if (pos.x >= 0.5 && pos.y < 0.5) {
		vec2 texCoord = vec2((pos.x - 0.5) * 2.0, pos.y * 2.0);
		vec4 color = HOOKED_tex(texCoord);
		return vec4(color.x, chroma_neutral, chroma_neutral, color.a);
	}

	else if (pos.x < 0.5 && pos.y >= 0.5) {
		vec2 texCoord = vec2(pos.x * 2.0, (pos.y - 0.5) * 2.0);
		vec4 color = HOOKED_tex(texCoord);
		return vec4(chroma_neutral, color.y, chroma_neutral, color.a);
	}

	else {
		vec2 texCoord = vec2((pos.x - 0.5) * 2.0, (pos.y - 0.5) * 2.0);
		vec4 color = HOOKED_tex(texCoord);
		return vec4(chroma_neutral, chroma_neutral, color.z, color.a);
	}

}


//!HOOK MAINPRESUB 
//!BIND HOOKED
//!DESC [plane_split_RT] Raw--R//G--B
//!WHEN MODE 2 ==

vec4 hook() {

	vec2 pos = HOOKED_pos;
	float color_target = 0.0;

	if (pos.x < 0.5 && pos.y < 0.5) {
		vec2 texCoord = vec2(pos.x * 2.0, pos.y * 2.0);
		return HOOKED_tex(texCoord);
	}

	else if (pos.x >= 0.5 && pos.y < 0.5) {
		vec2 texCoord = vec2((pos.x - 0.5) * 2.0, pos.y * 2.0);
		vec4 color = HOOKED_tex(texCoord);
		return vec4(color.r, color_target, color_target, color.a);
	}

	else if (pos.x < 0.5 && pos.y >= 0.5) {
		vec2 texCoord = vec2(pos.x * 2.0, (pos.y - 0.5) * 2.0);
		vec4 color = HOOKED_tex(texCoord);
		return vec4(color_target, color.g, color_target, color.a);
	}

	else {
		vec2 texCoord = vec2((pos.x - 0.5) * 2.0, (pos.y - 0.5) * 2.0);
		vec4 color = HOOKED_tex(texCoord);
		return vec4(color_target, color_target, color.b, color.a);
	}

}

