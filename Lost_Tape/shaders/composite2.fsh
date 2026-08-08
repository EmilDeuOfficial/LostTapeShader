#version 120

// LOST TAPE — composite2: vertikale Weichzeichnung des Leuchtfarben-Felds

uniform sampler2D colortex3;
uniform float viewHeight;

varying vec2 texcoord;

void main() {
    vec4 sum = vec4(0.0);
    float wsum = 0.0;
    for (int i = -6; i <= 6; i++) {
        float w = 7.0 - abs(float(i));
        vec2 uv = texcoord + vec2(0.0, float(i) * 16.0 / viewHeight);
        sum += texture2D(colortex3, uv) * w;
        wsum += w;
    }

/* DRAWBUFFERS:3 */
    gl_FragData[0] = sum / wsum;
}
