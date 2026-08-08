#version 120

// LOST TAPE — composite3: WEITE horizontale Streuung des Leuchtfarben-Felds.
// Die Abtastpunkte werden pro Pixel gejittert, sonst erzeugt das grobe
// 56px-Raster kammartige Ring-Artefakte im Farbfeld.

uniform sampler2D colortex3;
uniform float viewWidth;

varying vec2 texcoord;

float bayer2(vec2 a) { a = floor(a); return fract(a.x * 0.5 + a.y * a.y * 0.75); }
float bayer4(vec2 a) { return bayer2(0.5 * a) * 0.25 + bayer2(a); }

void main() {
    float j = bayer4(gl_FragCoord.xy) - 0.5;
    vec4 sum = vec4(0.0);
    float wsum = 0.0;
    for (int i = -6; i <= 6; i++) {
        float w = 7.0 - abs(float(i));
        vec2 uv = texcoord + vec2((float(i) + j) * 56.0 / viewWidth, 0.0);
        sum += texture2D(colortex3, uv) * w;
        wsum += w;
    }

/* DRAWBUFFERS:3 */
    gl_FragData[0] = sum / wsum;
}
