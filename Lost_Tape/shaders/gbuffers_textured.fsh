#version 120

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

// Schicht-Nebel: dieselbe Formel wie der Hintergrund-Nebel in deferred —
// jede transluzente Schicht benebelt sich beim Zeichnen an ihrer EIGENEN
// Distanz (Vanilla-Modell). deferred hat den Hintergrund bereits benebelt.
vec3 layerFog(vec3 col, float distV) {
    vec3 fc = fogColor;
    float flum = dot(fc, vec3(0.299, 0.587, 0.114));
    fc = mix(fc, vec3(flum), 0.5);
    fc *= 0.85;
    fc *= vec3(0.96, 1.0, 0.94);
    float density = 0.010 * FOG_DENSITY;
    density *= 1.0 + rainStrength * 2.0;
    density *= 1.0 + blindness * 4.0;
    bool isNether = fogColor.r > 0.10 && fogColor.g < 0.12 && fogColor.r > fogColor.b * 1.8;
    bool isEnd    = fogColor.r < 0.20 && fogColor.b < 0.30
                 && fogColor.r - fogColor.g > 0.01 && fogColor.b - fogColor.g > 0.01;
    if (isNether) density *= 1.4;
    if (isEnd) fc = max(fc, vec3(0.16, 0.15, 0.21));
#ifdef FOG_BREATHING
    density *= 1.0 + 0.12 * sin(frameTimeCounter * 0.13);
#endif
    if (isEyeInWater == 1) { density = max(density, 0.10 * FOG_DENSITY); fc = vec3(0.03, 0.07, 0.06); }
    else if (isEyeInWater == 2) { density = max(density, 0.60); fc = vec3(0.45, 0.12, 0.02); }
    float fogD = distV;
    if (isEyeInWater == 0) fogD = max(distV - FOG_START, 0.0);
    float fogA = 1.0 - exp(-fogD * density);
    float wallEnd = min(FOG_LIMIT, far * 0.85);
    fogA = max(fogA, smoothstep(wallEnd * 0.2, wallEnd, distV));
    return mix(col, fc, fogA);
}

void main() {
    vec4 color = texture2D(texture, texcoord) * glcolor;
    if (color.a < 0.01) discard;

    // Selbst-Benebelung an der eigenen Distanz (Vanilla-Modell)
    color.rgb = layerFog(color.rgb, viewDist);

/* DRAWBUFFERS:0 */
    gl_FragData[0] = color;
}
