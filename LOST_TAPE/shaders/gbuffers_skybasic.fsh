#version 120

#define SKY_GLOOM 0.70 // [0.00 0.15 0.30 0.50 0.70 0.85 1.00]

varying vec4 glcolor;

void main() {
    vec3 col = glcolor.rgb;

    // entsättigen, abdunkeln, kränklich einfärben
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(col, vec3(lum), SKY_GLOOM * 0.6);
    col *= mix(1.0, 0.55, SKY_GLOOM);
    col = mix(col, col * vec3(0.94, 1.0, 0.90), SKY_GLOOM);

/* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(col, glcolor.a);
}
