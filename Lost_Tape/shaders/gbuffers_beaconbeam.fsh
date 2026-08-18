#version 120

// LOST TAPE — gbuffers_beaconbeam: KEIN Selbst-Nebel. Der Strahl schreibt
// eigene Tiefe und zeichnet vor dem deferred-Pass — deferred benebelt ihn
// dort genau einmal, wie das Gelaende daneben.

uniform sampler2D texture;

varying vec2 texcoord;
varying vec4 glcolor;

void main() {
    vec4 color = texture2D(texture, texcoord) * glcolor;
    if (color.a < 0.01) discard;

/* DRAWBUFFERS:0 */
    gl_FragData[0] = color;
}
