//!HOOK MAIN
//!BIND HOOKED
//!BIND LUMA
//!DESC [YIQ_converter]

#define TOTAL_SCALE 1.1 // 1.0
#define Y_SCALE 1.0     // 1.12
#define I_SCALE 1.0     // 1.3
#define Q_SCALE 1.0     // 1.2

const mat3 RGBtoYIQ = mat3(
    0.299,       0.587,       0.114,
    0.59590059, -0.27455667, -0.32134392,
    0.21153661, -0.52273617,  0.3111995
);

const mat3 YIQtoRGB = mat3(
    1.0,  0.95568806036115671171,  0.61985809445637075388,
    1.0, -0.27158179694405859326, -0.64687381613840131330,
    1.0, -1.1081773266826619523,   1.7050645599191817149
);

const vec3 offset = vec3(Y_SCALE, I_SCALE, Q_SCALE) * TOTAL_SCALE;

vec4 hook()
{
    vec4 color = HOOKED_texOff(vec2(0.0, 0.0));
    color.rgb *= RGBtoYIQ;
    color.r = pow(abs(color.r), offset.x);
    color.gb *= offset.yz;
    color.rgb *= YIQtoRGB;
    //color.rgb = clamp(color.rgb, 0.0, 1.0);
    return color;
}

