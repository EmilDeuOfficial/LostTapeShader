#version 120

// LOST TAPE — composite4: WEITE vertikale Streuung des Leuchtfarben-Felds,
// mit Per-Pixel-Jitter gegen Ring-Artefakte (siehe composite3)

uniform sampler2D colortex3;
uniform float viewHeight;

varying vec2 texcoord;

float bayer2(vec2 a) { a = floor(a); return fract(a.x * 0.5 + a.y * a.y * 0.75); }
float bayer4(vec2 a) { return bayer2(0.5 * a) * 0.25 + bayer2(a); }

void main() {
    float j = bayer4(gl_FragCoord.xy + 17.0) - 0.5;
    vec4 sum = vec4(0.0);
    float wsum = 0.0;
    for (int i = -6; i <= 6; i++) {
        float w = 7.0 - abs(float(i));
        vec2 uv = texcoord + vec2(0.0, (float(i) + j) * 56.0 / viewHeight);
        sum += texture2D(colortex3, uv) * w;
        wsum += w;
    }

/* DRAWBUFFERS:3 */
    gl_FragData[0] = sum / wsum;
}
