#version 120

// LOST TAPE — composite: der Lichtstreifen-Glanz, NACH den Transluzenten.
// Er muss ueber Wasser und Glas genauso stark liegen wie ueber Land und
// Himmel. Im deferred-Pass (vor den Transluzenten) wuerde die
// Wasseroberflaeche ihn anteilig wegblenden — die Ozeanflaeche stuende
// dann als dunklere Silhouette am Horizont ("Chunk-Kante", die NUR ueber
// Wasser sichtbar war). Die Nebel-Abdunklung der Schattensaeulen
// (VL_DARKEN) bleibt im deferred-Pass, weil sie in die Nebelfarbe des
// Hintergrunds eingerechnet wird.

#define FOG_DENSITY 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00 2.50 3.00]
#define FOG_LIMIT 128.0 // [64.0 96.0 128.0 160.0 192.0 256.0 512.0]
#define FOG_BREATHING // langsames An- und Abschwellen des Nebels

#define LIGHT_SHAFTS // volumetrische Licht-/Schattenstreifen im Nebel
#define VL_STRENGTH 0.60 // [0.00 0.20 0.40 0.60 0.80 1.00 1.30 1.60]
#define VL_SAMPLES 16 // [8 12 16 24 32]

const float shadowDistance = 120.0; // [64.0 96.0 120.0 160.0 200.0 256.0]

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform sampler2D shadowtex1;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;
uniform vec3 fogColor;
uniform float far;
uniform float rainStrength;
uniform float frameTimeCounter;
uniform float blindness;
uniform float sunAngle;
uniform int isEyeInWater;

varying vec2 texcoord;

float bayer2(vec2 a) { a = floor(a); return fract(a.x * 0.5 + a.y * a.y * 0.75); }
float bayer4(vec2 a) { return bayer2(0.5 * a) * 0.25 + bayer2(a); }
float bayer8(vec2 a) { return bayer4(0.5 * a) * 0.25 + bayer4(a); }

vec3 toShadowClip(vec3 playerPos) {
    return (shadowProjection * (shadowModelView * vec4(playerPos, 1.0))).xyz;
}

// Schattenkarte abtasten (mit derselben Verzerrung wie shadow.vsh)
float sampleShadow(vec3 sclip, vec2 texelOff, float biasMul) {
    float f = length(sclip.xy) * 0.9 + 0.1;
    vec3 p = vec3(sclip.xy / f, sclip.z) * 0.5 + 0.5;
    p.xy += texelOff;
    if (p.x < 0.0 || p.x > 1.0 || p.y < 0.0 || p.y > 1.0 || p.z > 1.0) return 1.0;
    float bias = (0.0012 * f * f + 0.0005) * biasMul;
    // shadowtex1 = Schattenkarte ohne Glas/Wasser -> Transluzentes wirft keinen Vollschatten
    float diff = (p.z - bias) - texture2D(shadowtex1, p.xy).x;
    return step(diff, 0.0);
}

void main() {
    vec4 color = texture2D(colortex0, texcoord);

#ifdef LIGHT_SHAFTS
    // Tiefe MIT Transluzenten: die Strahlen laufen bis zur Wasser-/
    // Glasoberflaeche und legen sich damit gleichmaessig UEBER sie
    float depth = texture2D(depthtex0, texcoord).x;
    vec4 ndc = vec4(texcoord * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 viewPos4 = gbufferProjectionInverse * ndc;
    vec3 viewPos = viewPos4.xyz / viewPos4.w;
    float dist = length(viewPos);
    vec3 playerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

    // Dimension zur Laufzeit erkennen (siehe deferred.fsh)
    bool isNether = fogColor.r > 0.10 && fogColor.g < 0.12 && fogColor.r > fogColor.b * 1.8;
    bool isEnd    = fogColor.r < 0.20 && fogColor.b < 0.30
                 && fogColor.r - fogColor.g > 0.01 && fogColor.b - fogColor.g > 0.01;

    if (isEyeInWater != 2 && !isNether && !isEnd) {
        // Nebeldichte: identisch zur deferred-Berechnung
        float density = 0.010 * FOG_DENSITY;
        density *= 1.0 + rainStrength * 2.0;
        density *= 1.0 + blindness * 4.0;
#ifdef FOG_BREATHING
        density *= 1.0 + 0.12 * sin(frameTimeCounter * 0.13);
#endif
        if (isEyeInWater == 1) density = max(density, 0.10 * FOG_DENSITY);

        // Strahl endet an der Nebelwand — identisch zu deferred, damit
        // Gelaende an der Wand und Himmel dieselben Streu-Terme bekommen
        float wallEnd = min(FOG_LIMIT, far * 0.85);
        float wallCap = wallEnd;
        float rayLen = min(min(dist, shadowDistance), wallCap);
        rayLen = mix(rayLen, wallCap, smoothstep(wallEnd * 0.4, wallEnd * 0.7, dist));
        vec3 endPos = playerPos * (rayLen / max(dist, 0.001));
        vec3 sStart = toShadowClip(vec3(0.0));
        vec3 sEnd = toShadowClip(endPos);

        // geordnetes Bayer-Dithering statt Rauschen -> ruhigeres Bild
        float dither = bayer8(gl_FragCoord.xy);
        float vis = 0.0;
        for (int i = 0; i < VL_SAMPLES; i++) {
            float t = (float(i) + dither) / float(VL_SAMPLES);
            vis += sampleShadow(mix(sStart, sEnd, t), vec2(0.0), 1.5);
        }
        vis /= float(VL_SAMPLES);
        // Streifen-Variation im Fernfeld neutralisieren (siehe deferred)
        vis = mix(vis, 1.0, smoothstep(wallEnd * 0.3, wallEnd * 0.6, dist));

        // breite Streuphase: Richtung Sonne deutlich staerker
        vec3 viewDir = viewPos / max(dist, 0.001);
        float cosT = clamp(dot(viewDir, normalize(shadowLightPosition)), 0.0, 1.0);
        float phase = 0.15 + 1.4 * pow(cosT, 20.0);

        float sunH = sin(sunAngle * 6.2831853);
        float dayF = clamp(sunH * 4.0, 0.0, 1.0);
        float nightF = clamp(-sunH * 4.0, 0.0, 1.0);
        float rainW = 1.0 - rainStrength * 0.85;
        vec3 lightCol = dayF * vec3(0.85, 0.80, 0.68) + nightF * vec3(0.18, 0.22, 0.30);
        // unter Wasser: Sonnenstrahlen kuehl-gruenlich gefiltert
        if (isEyeInWater == 1) lightCol *= vec3(0.45, 0.80, 0.75);

        float media = 1.0 - exp(-rayLen * density * 2.5);

        // helle Strahlen in beleuchteten Nebelsaeulen — ueber ALLEM
        color.rgb += lightCol * (vis * phase * media * VL_STRENGTH) * rainW;
    }
#endif

/* DRAWBUFFERS:2 */
    gl_FragData[0] = color;
}
