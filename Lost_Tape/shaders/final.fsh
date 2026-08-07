#version 120

// LOST TAPE — final: Analog-Horror-Post-Processing
// Farbstimmung, Dithering, Filmkorn, Vignette, VHS-Artefakte

#define SATURATION 0.65 // [0.00 0.20 0.35 0.50 0.65 0.80 1.00 1.20]
#define TINT_MODE 1 // [0 1 2]
#define TINT_STRENGTH 0.35 // [0.00 0.15 0.25 0.35 0.50 0.70 1.00]
#define CONTRAST 1.05 // [0.90 0.95 1.00 1.05 1.10 1.20 1.30]
#define BLACK_LIFT 0.04 // [0.00 0.02 0.04 0.06 0.08 0.12]
#define DITHER // Retro-Farbquantisierung mit Bayer-Dithering
#define COLOR_LEVELS 24.0 // [8.0 12.0 16.0 24.0 32.0 48.0 64.0]
//#define PIXELATE
#define PIXEL_SIZE 3.0 // [2.0 3.0 4.0 5.0 6.0 8.0]
#define GRAIN_STRENGTH 0.08 // [0.00 0.04 0.08 0.12 0.16 0.25]
#define VIGNETTE_STRENGTH 0.35 // [0.00 0.15 0.25 0.35 0.50 0.70 1.00]
#define CHROMATIC_ABERRATION 0.25 // [0.00 0.15 0.25 0.50 0.75 1.00]
//#define SCANLINES
#define SCANLINE_STRENGTH 0.25 // [0.10 0.15 0.25 0.35 0.50]
#define FLICKER // subtiles analoges Helligkeitsflackern
//#define VHS_WOBBLE

uniform sampler2D colortex0;
uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;

varying vec2 texcoord;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float bayer2(vec2 a) { a = floor(a); return fract(a.x * 0.5 + a.y * a.y * 0.75); }
float bayer4(vec2 a) { return bayer2(0.5 * a) * 0.25 + bayer2(a); }
float bayer8(vec2 a) { return bayer4(0.5 * a) * 0.25 + bayer4(a); }

void main() {
    vec2 uv = texcoord;

#ifdef VHS_WOBBLE
    uv.x += sin(uv.y * 80.0 + frameTimeCounter * 2.5) * 0.0012;
    uv.x += (hash(vec2(floor(frameTimeCounter * 18.0), floor(uv.y * 48.0))) - 0.5) * 0.0015;
#endif

#ifdef PIXELATE
    vec2 res = vec2(viewWidth, viewHeight) / PIXEL_SIZE;
    uv = (floor(uv * res) + 0.5) / res;
#endif

    // Chromatische Aberration, zum Rand hin staerker
    vec2 off = uv - 0.5;
    vec2 ca = off * dot(off, off) * CHROMATIC_ABERRATION * 0.03;

    vec3 col;
    col.r = texture2D(colortex0, uv - ca).r;
    col.g = texture2D(colortex0, uv).g;
    col.b = texture2D(colortex0, uv + ca).b;

    // ausgeblichene Schwarztoene (VHS-Look)
    col = vec3(BLACK_LIFT) * vec3(0.80, 0.95, 0.85) + col * (1.0 - BLACK_LIFT);

    // Kontrast
    col = (col - 0.5) * CONTRAST + 0.5;

    // Entsaettigung
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(lum), col, SATURATION);

    // Farbstich
#if TINT_MODE == 0
    vec3 tint = vec3(1.06, 1.00, 0.86); // Sepia
#elif TINT_MODE == 1
    vec3 tint = vec3(0.93, 1.04, 0.91); // kraenkliches Gruen
#else
    vec3 tint = vec3(0.90, 0.97, 1.08); // kaltes Blau
#endif
    col *= mix(vec3(1.0), tint, TINT_STRENGTH);

    col = clamp(col, 0.0, 1.0);

#ifdef DITHER
    float d = bayer8(gl_FragCoord.xy);
    col = floor(col * COLOR_LEVELS + d) / COLOR_LEVELS;
#endif

    // animiertes Filmkorn, in Schatten staerker
    float g = hash(uv * vec2(viewWidth, viewHeight)
                   + vec2(fract(frameTimeCounter) * 61.7, fract(frameTimeCounter * 0.77) * 123.4));
    col += (g - 0.5) * GRAIN_STRENGTH * (1.0 - lum * 0.5);

#ifdef SCANLINES
    float sl = 0.5 + 0.5 * sin(gl_FragCoord.y * 3.14159265);
    col *= 1.0 - SCANLINE_STRENGTH * (1.0 - sl);
#endif

#ifdef FLICKER
    float fl = hash(vec2(floor(frameTimeCounter * 24.0), 3.7));
    col *= 1.0 + (fl - 0.5) * 0.05;
#endif

    // Vignette
    float vd = length(texcoord - 0.5) * 1.4142;
    col *= 1.0 - VIGNETTE_STRENGTH * smoothstep(0.45, 1.05, vd);

    gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
