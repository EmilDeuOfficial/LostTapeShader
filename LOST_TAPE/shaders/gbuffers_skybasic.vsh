#version 120

// LOST TAPE — gbuffers_skybasic (Himmelsfarbe, Horizont, Sterne)

varying vec4 glcolor;

void main() {
    glcolor = gl_Color;
    gl_Position = ftransform();
}
