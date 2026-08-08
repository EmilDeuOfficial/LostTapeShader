#version 120

#define LIGHT_GAMMA 1.20 // [0.80 0.90 1.00 1.10 1.20 1.35 1.50 1.75 2.00]
#define NIGHT_BRIGHTNESS 1.00 // [0.00 0.50 1.00 1.50 2.00 3.00]
#define BLOCKLIGHT_BOOST 1.25 // [0.50 0.75 1.00 1.25 1.50 1.75 2.00]
#define HAND_LIGHT // dynamisches Licht von Fackeln & Co. in der Hand
#define HAND_LIGHT_STRENGTH 1.00 // [0.50 0.75 1.00 1.25 1.50 2.00]
#define WATER_OPACITY 0.45 // [0.30 0.40 0.45 0.50 0.60 0.75 0.90 1.00]

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
varying float blockId;

void main() {
    vec4 color = texture2D(texture, texcoord) * glcolor;
    if (color.a < 0.01) discard;

    vec3 light = texture2D(lightmap, lmcoord).rgb;
    light = pow(light, vec3(LIGHT_GAMMA));

    // Aufhellungen (Fackel-Boost, Mondlicht) NUR auf echtem Wasser:
    // gefaerbtes Glas & Co. wuerden sonst im Dunkeln als heller Film
    // ueber der Szene liegen und die Flaechen dahinter aufhellen
    if (blockId > 10007.5 && blockId < 10008.5) {
        vec3 torchLight = texture2D(lightmap, vec2(lmcoord.x, 0.03125)).rgb;
        light = max(light, torchLight * BLOCKLIGHT_BOOST);
        float nightF = clamp(-sin(sunAngle * 6.2831853) * 4.0, 0.0, 1.0);
        light += vec3(0.035, 0.045, 0.065) * (NIGHT_BRIGHTNESS * nightF * lmcoord.y);
    }

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

    float tLum = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    if (blockId > 10007.5 && blockId < 10008.5) {
        // Wasser durchsichtiger: die Blockfarben am Grund kommen durch
        color.rgb *= vec3(0.92, 0.97, 0.95);
        color.a *= WATER_OPACITY;
    } else if (blockId > 10008.5 && blockId < 10009.5) {
        // Nether-Portal: kraeftig deckend UND Saettigung vorverstaerkt,
        // damit das Lila das entsaettigende Analog-Grading uebersteht
        color.a = min(color.a * 2.2, 0.97);
        color.rgb = clamp(mix(vec3(tLum), color.rgb, 1.4), 0.0, 1.0);
    } else {
        // Fallback OHNE Block-ID: violette Pixel WEICH erkennen — auch die
        // blassen Lavendel-Texel der Portal-Textur (b und r ueber g)
        float purple = clamp((color.b - color.g) * 6.0, 0.0, 1.0)
                     * clamp((color.r - color.g) * 8.0 + 0.3, 0.0, 1.0)
                     * step(0.10, color.b);
        color.a = min(color.a * (1.0 + 1.4 * purple), 0.97);
        // Saettigung vorverstaerken: stark fuer Portal-Purpur, leicht fuer
        // alles andere gefaerbte Glas (uebersteht so das Analog-Grading)
        float satBoost = mix(1.25, 1.45, purple);
        color.rgb = clamp(mix(vec3(tLum), color.rgb, satBoost), 0.0, 1.0);
    }

/* DRAWBUFFERS:0 */
    // kein Schreiben in colortex1: die Lichtdaten des Bodens HINTER dem Glas bleiben erhalten
    gl_FragData[0] = color;
}
