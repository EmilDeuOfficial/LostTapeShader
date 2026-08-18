#version 120

// LOST TAPE — gbuffers_armor_glint: der Verzauberungs-Schimmer wird
// ADDITIV geblendet. Nebel darf so einen Beitrag nur ABSCHWAECHEN
// (Richtung 0), niemals zur hellen Nebelfarbe hin mischen — sonst
// leuchtet verzauberte Ruestung als heller Fleck durch dichten Nebel.

#define FOG_DENSITY 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00 2.50 3.00]
#define FOG_START 8.0 // [0.0 4.0 8.0 12.0 16.0 24.0 32.0 48.0 64.0 96.0 128.0]
#define FOG_LIMIT 128.0 // [64.0 96.0 128.0 160.0 192.0 256.0 512.0]
#define FOG_BREATHING // langsames An- und Abschwellen des Nebels

uniform sampler2D texture;
uniform vec3 fogColor;
uniform float far;
uniform float rainStrength;
uniform float blindness;
uniform float frameTimeCounter;
uniform int isEyeInWater;

varying vec2 texcoord;
varying vec4 glcolor;
varying float viewDist;

// wie layerFog, aber nur der Abschwaechungs-Faktor (1 - Nebelanteil)
float fogAtt(float distV) {
    float density = 0.010 * FOG_DENSITY;
    density *= 1.0 + rainStrength * 2.0;
    density *= 1.0 + blindness * 4.0;
    bool isNether = fogColor.r > 0.10 && fogColor.g < 0.12 && fogColor.r > fogColor.b * 1.8;
    if (isNether) density *= 1.4;
#ifdef FOG_BREATHING
    density *= 1.0 + 0.12 * sin(frameTimeCounter * 0.13);
#endif
    if (isEyeInWater == 1) density = max(density, 0.10 * FOG_DENSITY);
    else if (isEyeInWater == 2) density = max(density, 0.60);
    float fogD = distV;
    if (isEyeInWater == 0) fogD = max(distV - FOG_START, 0.0);
    float fogA = 1.0 - exp(-fogD * density);
    float wallEnd = min(FOG_LIMIT, far * 0.85);
    fogA = max(fogA, smoothstep(wallEnd * 0.1, wallEnd * 0.7, distV));
    return 1.0 - fogA;
}

void main() {
    vec4 color = texture2D(texture, texcoord) * glcolor;
    if (color.a < 0.01) discard;

    color.rgb *= fogAtt(viewDist);

/* DRAWBUFFERS:0 */
    gl_FragData[0] = color;
}
