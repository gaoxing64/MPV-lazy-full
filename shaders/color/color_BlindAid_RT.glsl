// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- Paper ver.
  https://www.inf.ufrgs.br/~oliveira/pubs_files/CVD_Simulation/CVD_Simulation.html
  --- NAIKARI ver.
  https://github.com/naikari/naikari/blob/main/LICENSE

*/


//!PARAM MODE
//!TYPE int
//!MINIMUM 0
//!MAXIMUM 8
0


//!HOOK OUTPUT
//!BIND HOOKED
//!DESC [color_BlindAid_RT]
//!WHEN MODE

// 1. PROTANOPIA        -- 红色盲
// 2. DEUTERANOPIA      -- 绿色盲
// 3. TRITANOPIA        -- 蓝色盲
// 4. PROTANOMALY       -- 红色弱
// 5. DEUTERANOMALY     -- 绿色弱
// 6. TRITANOMALY       -- 蓝色弱
// 7. CONE MONOCHROMACY -- 锥体单色视
// 8. ROD MONOCHROMACY  -- 杆状单色视

const mat3 sRGB_to_LMS = mat3(
	  0.31399022,  0.15537241,  0.01775239,
	  0.63951294,  0.75789446,  0.10944209,
	  0.04649755,  0.08670142,  0.87256922
);

const mat3 LMS_to_sRGB = mat3(
	  5.47221206, -1.12524190,  0.02980165,
	 -4.64196010,  2.29317094, -0.19318073,
	  0.16963708, -0.16789520,  1.16364789
);

vec4 hook() {

	vec4 color = HOOKED_tex(HOOKED_pos);
	if (color.a == 0.0) {
		return color;
	}
	vec3 lms = sRGB_to_LMS * color.rgb;
	vec3 lms_sim;

	if (MODE == 1) {
		float l_proj = lms.y * 1.05118294 + lms.z * -0.05116099;
		lms_sim = vec3(l_proj, l_proj, lms.z);
	}
	else if (MODE == 2) {
		float m_proj = lms.x * 0.9513092 + lms.z * 0.04866992;
		lms_sim = vec3(lms.x, m_proj, lms.z);
	}
	else if (MODE == 3) {
		float s_proj = lms.x * -0.86744736 + lms.y * 1.86727089;
		lms_sim = vec3(lms.x, lms.y, s_proj);
	}
	else if (MODE == 4) {
		mat3 sim_matrix = mat3(
			  0.458064,  0.092785, -0.007494,
			  0.679578,  0.846313, -0.016807,
			 -0.137642,  0.060902,  1.024301
		);
		lms_sim = sim_matrix * lms;
	}
	else if (MODE == 5) {
		mat3 sim_matrix = mat3(
			  0.547494,  0.181692, -0.010410,
			  0.607765,  0.781742,  0.027275,
			 -0.155259,  0.036566,  0.983136
		);
		lms_sim = sim_matrix * lms;
	}
	else if (MODE == 6) {
		mat3 sim_matrix = mat3(
			  1.017277, -0.006113,  0.006379,
			  0.027029,  0.958479,  0.248708,
			 -0.044306,  0.047634,  0.744913
		);
		lms_sim = sim_matrix * lms;
	}
	else if (MODE == 7) {
		float gray = lms.z;
		lms_sim = vec3(gray, gray, gray);
	}
	else if (MODE == 8) {
		float gray = dot(lms, vec3(0.2126, 0.7152, 0.0722));
		lms_sim = vec3(gray, gray, gray);
	}

	vec3 final_rgb = LMS_to_sRGB * lms_sim;
	return vec4(clamp(final_rgb, 0.0, 1.0), color.a);

}

