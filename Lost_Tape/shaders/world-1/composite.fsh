#version 120

// LOST TAPE — composite (Nether): nur Nebel, keine Schatten (keine Sonne)

#define FOG_DENSITY 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00 2.50 3.00]
#define FOG_START 8.0 // [0.0 4.0 8.0 12.0 16.0 24.0 32.0 48.0 64.0 96.0 128.0]
#define SKY_FOG 0.75 // [0.00 0.20 0.40 0.60 0.75 0.90 1.00]
#define FOG_LIMIT 128.0 // [64.0 96.0 128.0 160.0 192.0 256.0 512.0]
#define FOG_BREATHING // langsames An- und Abschwellen des Nebels

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform mat4 gbufferProjectionInverse;
uniform vec3 fogColor;
uniform float frameTimeCounter;
uniform float blindness;
uniform int isEyeInWater;

varying vec2 texcoord;

void main() {
    vec4 color = texture2D(colortex0, texcoord);
    // Tiefe OHNE transluzente Bloecke: Nebel wirkt hinter Glas
    float depth = texture2D(depthtex1, texcoord).x;

    vec4 ndc = vec4(texcoord * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 viewPos4 = gbufferProjectionInverse * ndc;
    float dist = length(viewPos4.xyz / viewPos4.w);

    vec3 fogC = fogColor;
    float lum = dot(fogC, vec3(0.299, 0.587, 0.114));
    fogC = mix(fogC, vec3(lum), 0.5);
    fogC *= 0.85;

    // Nether: dichter, erstickender Nebel
    float density = 0.014 * FOG_DENSITY;
    density *= 1.0 + blindness * 4.0;
#ifdef FOG_BREATHING
    density *= 1.0 + 0.12 * sin(frameTimeCounter * 0.13);
#endif

    if (isEyeInWater == 2) {
        density = max(density, 0.60);
        fogC = vec3(0.45, 0.12, 0.02);
    }

    float fog;
    if (depth >= 1.0) {
        fog = clamp(SKY_FOG, 0.0, 1.0);
    } else {
        float fogDist = dist;
        if (isEyeInWater == 0) fogDist = max(dist - FOG_START, 0.0);
        fog = 1.0 - exp(-fogDist * density);
        // Nebelwand: unabhaengig von der Renderdistanz
        fog = max(fog, smoothstep(FOG_LIMIT * 0.7, FOG_LIMIT, dist));
    }

    color.rgb = mix(color.rgb, fogC, fog);

/* DRAWBUFFERS:0 */
    gl_FragData[0] = color;
}
