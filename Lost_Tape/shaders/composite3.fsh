#version 120

// LOST TAPE — composite3: WEITE horizontale Streuung des Leuchtfarben-Felds,
// damit die Faerbung den ganzen Lichtkreis einer Quelle abdeckt

uniform sampler2D colortex3;
uniform float viewWidth;

varying vec2 texcoord;

void main() {
    vec4 sum = vec4(0.0);
    float wsum = 0.0;
    for (int i = -6; i <= 6; i++) {
        float w = 7.0 - abs(float(i));
        vec2 uv = texcoord + vec2(float(i) * 56.0 / viewWidth, 0.0);
        sum += texture2D(colortex3, uv) * w;
        wsum += w;
    }

/* DRAWBUFFERS:3 */
    gl_FragData[0] = sum / wsum;
}
