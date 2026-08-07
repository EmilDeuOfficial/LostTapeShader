#version 120

#define CELESTIAL_DIM 0.50 // [0.10 0.25 0.50 0.80 1.00]
#define SHOW_SUN // Sonne rendern
#define SHOW_MOON // Mond rendern

uniform sampler2D texture;
uniform int renderStage;

varying vec2 texcoord;
varying vec4 glcolor;

void main() {
#ifdef MC_RENDER_STAGE_SUN
#ifndef SHOW_SUN
    if (renderStage == MC_RENDER_STAGE_SUN) discard;
#endif
#ifndef SHOW_MOON
    if (renderStage == MC_RENDER_STAGE_MOON) discard;
#endif
#endif

    vec4 color = texture2D(texture, texcoord) * glcolor;

    // Sonne & Mond wie hinter Dunst
    color.rgb *= CELESTIAL_DIM;

/* DRAWBUFFERS:0 */
    gl_FragData[0] = color;
}
