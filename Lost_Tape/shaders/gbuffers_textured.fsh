#version 120

uniform sampler2D texture;

varying vec2 texcoord;
varying vec4 glcolor;

void main() {
    vec4 color = texture2D(texture, texcoord) * glcolor;
    if (color.a < 0.01) discard;

/* DRAWBUFFERS:03 */
    gl_FragData[0] = color;
    // Partikel gehoeren zur transluzenten Schicht (colortex3): sonst
    // radiert der Nebel-Split dunklen Rauch vor Wasser/Glas aus
    gl_FragData[1] = vec4(color.rgb, color.a);
}
