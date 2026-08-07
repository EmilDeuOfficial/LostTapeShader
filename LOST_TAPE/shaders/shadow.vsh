#version 120

// LOST TAPE — shadow pass (Schattenkarte rendern)
// Verzerrung: nahe Schatten bekommen mehr Aufloesung (mehr Details)

varying vec2 texcoord;
varying vec4 glcolor;

void main() {
    gl_Position = ftransform();
    float f = length(gl_Position.xy) * 0.9 + 0.1;
    gl_Position.xy /= f;

    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor  = gl_Color;
}
