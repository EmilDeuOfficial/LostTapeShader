#version 120

// LOST TAPE — gbuffers_beaconbeam: eigener Slot, damit der Strahl NICHT
// den layerFog des gbuffers_textured-Fallbacks erbt — er zeichnet vor dem
// deferred-Pass und wuerde sonst doppelt benebelt.

#define VERTEX_SNAP // PSX-style wobbly vertex snapping
#define SNAP_RES 200.0 // [96.0 128.0 160.0 200.0 240.0 320.0 400.0]

uniform float viewWidth;
uniform float viewHeight;

varying vec2 texcoord;
varying vec4 glcolor;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor  = gl_Color;

    vec4 clip = gl_ProjectionMatrix * (gl_ModelViewMatrix * gl_Vertex);

#ifdef VERTEX_SNAP
    if (clip.w > 0.0) {
        vec2 grid = vec2(SNAP_RES * viewWidth / viewHeight, SNAP_RES);
        clip.xy = floor(clip.xy / clip.w * grid + 0.5) / grid * clip.w;
    }
#endif

    gl_Position = clip;
}
