#version 120

#define LIGHT_GAMMA 1.20 // [0.80 0.90 1.00 1.10 1.20 1.35 1.50 1.75 2.00]
#define NIGHT_BRIGHTNESS 1.00 // [0.00 0.50 1.00 1.50 2.00 3.00]
#define BLOCKLIGHT_BOOST 1.25 // [0.50 0.75 1.00 1.25 1.50 1.75 2.00]
#define HAND_LIGHT // dynamisches Licht von Fackeln & Co. in der Hand
#define HAND_LIGHT_STRENGTH 1.00 // [0.50 0.75 1.00 1.25 1.50 2.00]

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform float sunAngle;
uniform vec4 entityColor;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 glcolor;
varying float viewDist;

void main() {
    vec4 color = texture2D(texture, texcoord) * glcolor;
    if (color.a < 0.1) discard;

    // Verletzungs-Flash usw.
    color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);

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
        float att = clamp(1.0 - viewDist / (handLv * 0.8), 0.0, 1.0);
        light += vec3(1.0, 0.72, 0.45) * (att * att * HAND_LIGHT_STRENGTH);
    }
#endif

    color.rgb *= light;

/* DRAWBUFFERS:01 */
    gl_FragData[0] = color;
    gl_FragData[1] = vec4(lmcoord, 0.0, 1.0);
}
