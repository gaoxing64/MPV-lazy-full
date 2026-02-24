// 文档 https://github.com/hooke007/mpv_PlayKit/wiki/4_GLSL

/*

LICENSE:
  --- RAW ver.
  https://www.shadertoy.com/view/lssGDj

*/


//!PARAM COLOR
//!TYPE int
//!MINIMUM 1
//!MAXIMUM 2
1

//!PARAM BKS
//!TYPE int
//!MINIMUM 8
//!MAXIMUM 32
16

//!PARAM ALPHA
//!TYPE float
//!MINIMUM 0.1
//!MAXIMUM 1.0
1.0


//!HOOK MAIN
//!BIND HOOKED
//!DESC [ASCII_art]

float character(int n, vec2 p) {
	p = p * vec2(-4.0, -4.0) + 2.5;
	p = floor(p + 0.5);
	if (p.x >= 0.0 && p.x <= 4.0 && p.y >= 0.0 && p.y <= 4.0)
	{
		int a = int(p.x) + int(p.y) * 5;
		if (a >= 0 && a < 25)
		{
			if (((n >> a) & 1) == 1) return 1.0;
		}
	}
	return 0.0;
}

vec4 hook() {

	vec2 pos = HOOKED_pos;
	vec2 texSize = HOOKED_size;

	float blockSize = float(BKS);
	vec2 pixPos = pos * texSize;
	ivec2 blockIndex = ivec2(floor(pixPos / blockSize));
	vec2 blockCenter = (vec2(blockIndex) + 0.5) * blockSize;
	vec2 samplePos = blockCenter / texSize;

	vec3 col = HOOKED_tex(samplePos).rgb;
	float gray = dot(col, vec3(0.299, 0.587, 0.114));

	int n = 4096;
	if (gray > 0.0233) n = 4096;
	if (gray > 0.0465) n = 131200;
	if (gray > 0.0698) n = 4329476;
	if (gray > 0.0930) n = 459200;
	if (gray > 0.1163) n = 4591748;
	if (gray > 0.1395) n = 12652620;
	if (gray > 0.1628) n = 14749828;
	if (gray > 0.1860) n = 18393220;
	if (gray > 0.2093) n = 15239300;
	if (gray > 0.2326) n = 17318431;
	if (gray > 0.2558) n = 32641156;
	if (gray > 0.2791) n = 18393412;
	if (gray > 0.3023) n = 18157905;
	if (gray > 0.3256) n = 17463428;
	if (gray > 0.3488) n = 14954572;
	if (gray > 0.3721) n = 13177118;
	if (gray > 0.3953) n = 6566222;
	if (gray > 0.4186) n = 16269839;
	if (gray > 0.4419) n = 18444881;
	if (gray > 0.4651) n = 18400814;
	if (gray > 0.4884) n = 33061392;
	if (gray > 0.5116) n = 15255086;
	if (gray > 0.5349) n = 32045584;
	if (gray > 0.5581) n = 18405034;
	if (gray > 0.5814) n = 15022158;
	if (gray > 0.6047) n = 15018318;
	if (gray > 0.6279) n = 16272942;
	if (gray > 0.6512) n = 18415153;
	if (gray > 0.6744) n = 32641183;
	if (gray > 0.6977) n = 32540207;
	if (gray > 0.7209) n = 18732593;
	if (gray > 0.7442) n = 18667121;
	if (gray > 0.7674) n = 16267326;
	if (gray > 0.7907) n = 32575775;
	if (gray > 0.8140) n = 15022414;
	if (gray > 0.8372) n = 15255537;
	if (gray > 0.8605) n = 32032318;
	if (gray > 0.8837) n = 32045617;
	if (gray > 0.9070) n = 33081316;
	if (gray > 0.9302) n = 32045630;
	if (gray > 0.9535) n = 33061407;
	if (gray > 0.9767) n = 11512810;

	vec2 blockOffset = pixPos - vec2(blockIndex) * blockSize;
	vec2 charPos = (blockOffset / blockSize) * 2.0 - 1.0;
	float charMask = character(n, charPos);

	vec3 result;
	if (COLOR == 2) {
		result = vec3(charMask * gray);
	} else {
		result = col * charMask;
	}

	vec3 original = HOOKED_tex(pos).rgb;
	result = mix(original, result, ALPHA);
	return vec4(result, 1.0);

}

