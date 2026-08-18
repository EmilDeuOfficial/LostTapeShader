#version 120

// LOST TAPE — gbuffers_entities_translucent (Iris-Slot fuer transluzente
// Entity-Teile: Slime-Huelle, Phantom-Fluegel, Geister). Ohne dieses
// Programm faellt Iris auf gbuffers_entities zurueck und zeichnet die
// Fragmente NACH dem deferred-Pass — dann ganz ohne Nebel.

#define VERTEX_SNAP // PSX-style wobbly vertex snapping
#define SNAP_RES 200.0 // [96.0 128.0 160.0 200.0 240.0 320.0 400.0]
//#define SNAP_ENTITIES // Vertex-Snap auch auf Mobs/Entities (rundes wirkt dann eckig)

uniform float viewWidth;
uniform float viewHeight;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 glcolor;
varying float viewDist;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor  = gl_Color;

    vec4 vpos = gl_ModelViewMatrix * gl_Vertex;
    viewDist = length(vpos.xyz);
    vec4 clip = gl_ProjectionMatrix * vpos;

// verschachtelte #ifdef statt "#if defined(A) && defined(B)": Iris
// erkennt die Option SNAP_ENTITIES sonst nicht als benutzt und
// meldet "Invalid pack option"
#ifdef VERTEX_SNAP
#ifdef SNAP_ENTITIES
    if (clip.w > 0.0) {
        vec2 grid = vec2(SNAP_RES * viewWidth / viewHeight, SNAP_RES);
        clip.xy = floor(clip.xy / clip.w * grid + 0.5) / grid * clip.w;
    }
#endif
#endif

    gl_Position = clip;
}
