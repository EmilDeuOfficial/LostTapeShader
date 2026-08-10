#version 120

#define LIGHT_GAMMA 1.20 // [0.80 0.90 1.00 1.10 1.20 1.35 1.50 1.75 2.00]
#define NIGHT_BRIGHTNESS 1.00 // [0.00 0.50 1.00 1.50 2.00 3.00]
#define BLOCKLIGHT_BOOST 1.25 // [0.50 0.75 1.00 1.25 1.50 1.75 2.00]
#define HAND_LIGHT // dynamisches Licht von Fackeln & Co. in der Hand
#define HAND_LIGHT_STRENGTH 1.00 // [0.50 0.75 1.00 1.25 1.50 2.00]
#define FOG_DENSITY 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00 2.50 3.00]
#define FOG_START 8.0 // [0.0 4.0 8.0 12.0 16.0 24.0 32.0 48.0 64.0 96.0 128.0]
#define FOG_LIMIT 128.0 // [64.0 96.0 128.0 160.0 192.0 256.0 512.0]
#define FOG_BREATHING // langsames An- und Abschwellen des Nebels

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform float sunAngle;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
uniform int heldItemId;
uniform int heldItemId2;
uniform vec3 fogColor;
uniform float rainStrength;
uniform float blindness;
uniform float frameTimeCounter;
uniform int isEyeInWater;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 glcolor;
varying float viewDist;

// Schicht-Nebel: dieselbe Formel wie der Hintergrund-Nebel in composite —
// jede transluzente Schicht benebelt sich beim Zeichnen an ihrer EIGENEN
// Distanz (Vanilla-Modell). composite benebelt nur noch den Hintergrund.
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
    fogA = max(fogA, smoothstep(FOG_LIMIT * 0.2, FOG_LIMIT, distV));
    return mix(col, fc, fogA);
}

void main() {
    vec4 color = texture2D(texture, texcoord) * glcolor;
    if (color.a < 0.01) discard;

    vec3 light = texture2D(lightmap, lmcoord).rgb;
    light = pow(light, vec3(LIGHT_GAMMA));

    // Fackeln & Co. von der Abdunklung ausnehmen: Blocklicht separat samplen
    vec3 torchLight = texture2D(lightmap, vec2(lmcoord.x, 0.03125)).rgb;
    light = max(light, torchLight * BLOCKLIGHT_BOOST);

    // Mondlicht: hellt Naechte auf, nur wo Himmel sichtbar ist (Hoehlen bleiben dunkel)
    float nightF = clamp(-sin(sunAngle * 6.2831853) * 4.0, 0.0, 1.0);
    light += vec3(0.035, 0.045, 0.065) * (NIGHT_BRIGHTNESS * nightF * lmcoord.y);

#ifdef HAND_LIGHT
    // dynamisches Licht: gehaltene Fackeln & Co. beleuchten die Umgebung
    float handLv = float(max(heldBlockLightValue, heldBlockLightValue2));
    if (handLv > 0.5) {
        int hid = heldItemId;
        if (heldBlockLightValue2 > heldBlockLightValue) hid = heldItemId2;
        // Lichtfarbe passend zum gehaltenen Block (item.properties)
        vec3 handCol = vec3(1.00, 0.72, 0.45);                // Standard: warm
        if (hid == 11) handCol = vec3(0.35, 0.85, 1.00);      // Soul: tuerkis
        else if (hid == 12) handCol = vec3(0.60, 0.92, 0.95); // Seelaterne: kalt
        else if (hid == 13) handCol = vec3(1.00, 0.25, 0.15); // Redstone: rot
        else if (hid == 14) handCol = vec3(0.75, 0.45, 1.00); // Amethyst: violett
        else if (hid == 15) handCol = vec3(0.95, 0.95, 1.00); // End Rod: weiss
        float att = clamp(1.0 - viewDist / (handLv * 0.8), 0.0, 1.0);
        // Staerke skaliert mit dem Lichtlevel des Blocks
        light += handCol * (att * att * HAND_LIGHT_STRENGTH * (0.5 + handLv / 30.0));
    }
#endif

    color.rgb *= light;

    // Selbst-Benebelung an der eigenen Distanz (Vanilla-Modell)
    color.rgb = layerFog(color.rgb, viewDist);

/* DRAWBUFFERS:013 */
    gl_FragData[0] = color;
    // Lightmap nur fuer volldeckende Texel — halbtransparente Partikel
    // sollen die Lichtdaten des Gelaendes dahinter nicht verfaelschen
    gl_FragData[1] = vec4(lmcoord, 0.0, step(0.9, color.a));
    // beleuchtete Partikel in die transluzente Schicht aufnehmen (s. gbuffers_textured)
    gl_FragData[2] = vec4(color.rgb, color.a);
}
