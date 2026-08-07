#version 120

uniform sampler2D texture;
uniform int entityId;

varying vec2 texcoord;
varying vec4 glcolor;

void main() {
    vec4 color = texture2D(texture, texcoord) * glcolor;
    if (color.a < 0.1) discard;

    // Spieler in shadowcolor0 markieren (Alpha 0):
    // das Distanz-Verblassen wirkt nur auf den Spielerschatten
    float marker = 1.0;
    if (entityId == 1) marker = 0.0;

    gl_FragData[0] = vec4(color.rgb, marker);
}
