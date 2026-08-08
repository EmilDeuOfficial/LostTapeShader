#version 120

#define LIGHT_GAMMA 1.20 // [0.80 0.90 1.00 1.10 1.20 1.35 1.50 1.75 2.00]
#define NIGHT_BRIGHTNESS 1.00 // [0.00 0.50 1.00 1.50 2.00 3.00]
#define BLOCKLIGHT_BOOST 1.25 // [0.50 0.75 1.00 1.25 1.50 1.75 2.00]
#define HAND_LIGHT // dynamisches Licht von Fackeln & Co. in der Hand
#define HAND_LIGHT_STRENGTH 1.00 // [0.50 0.75 1.00 1.25 1.50 2.00]

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform float sunAngle;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
uniform int heldItemId;
uniform int heldItemId2;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 glcolor;
varying float viewDist;

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

    // leicht truebes Wasser — Alpha bleibt vanilla, der Grund bleibt sichtbar
    color.rgb *= vec3(0.85, 0.93, 0.90);

/* DRAWBUFFERS:0 */
    // kein Schreiben in colortex1: die Lichtdaten des Bodens HINTER dem Glas bleiben erhalten
    gl_FragData[0] = color;
}
