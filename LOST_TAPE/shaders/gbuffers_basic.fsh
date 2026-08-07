#version 120

varying vec4 glcolor;

void main() {
/* DRAWBUFFERS:0 */
    gl_FragData[0] = glcolor;
}
