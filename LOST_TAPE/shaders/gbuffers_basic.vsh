#version 120

// LOST TAPE — gbuffers_basic (Linien, Auswahlbox usw.)

varying vec4 glcolor;

void main() {
    glcolor = gl_Color;
    gl_Position = ftransform();
}
