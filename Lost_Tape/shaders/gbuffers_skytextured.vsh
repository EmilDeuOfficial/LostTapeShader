#version 120

// LOST TAPE — gbuffers_skytextured (Sonne & Mond)

varying vec2 texcoord;
varying vec4 glcolor;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor  = gl_Color;
    gl_Position = ftransform();
}
