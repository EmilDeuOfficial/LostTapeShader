#version 120

// LOST TAPE — deferred: Schatten, Nebel, Lichtstreifen auf der OPAKEN Szene.
// Laeuft VOR den Transluzenten: Glas/Wasser mischen sich danach ueber den
// bereits fertig benebelten Hintergrund (Vanilla-Reihenfolge). Dadurch ist
// der Nebel hinter Glas baulich IDENTISCH mit dem Nebel daneben — auch die
// Nebelwand, die die Renderdistanz-Kante verschluckt.

#define FOG_DENSITY 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00 2.50 3.00]
#define FOG_START 8.0 // [0.0 4.0 8.0 12.0 16.0 24.0 32.0 48.0 64.0 96.0 128.0]
#define SKY_FOG 0.75 // [0.00 0.20 0.40 0.60 0.75 0.90 1.00]
#define FOG_LIMIT 128.0 // [64.0 96.0 128.0 160.0 192.0 256.0 512.0]
#define FOG_BREATHING // langsames An- und Abschwellen des Nebels

#define SHADOWS // Sonnen- und Mondschatten
#define SHADOW_STRENGTH 0.60 // [0.20 0.30 0.40 0.50 0.60 0.70 0.80 0.90 1.00]
#define SHADOW_SOFT 1 // [0 1 2]
#define SHADOW_BIAS 1.00 // [0.50 0.75 1.00 1.50 2.00 3.00]
#define SSAO // Kontaktschatten: Objekte werfen weiche Schatten in Ecken & um Blocklicht
#define SSAO_STRENGTH 0.50 // [0.25 0.50 0.75 1.00]
#define LIGHT_SHAFTS // volumetrische Licht-/Schattenstreifen im Nebel
#define VL_STRENGTH 0.60 // [0.00 0.20 0.40 0.60 0.80 1.00 1.30 1.60]
#define VL_SAMPLES 16 // [8 12 16 24 32]
#define VL_DARKEN 0.35 // [0.00 0.20 0.35 0.50 0.70]

const int shadowMapResolution = 2048; // [1024 2048 3072 4096]
const float shadowDistance = 120.0; // [64.0 96.0 120.0 160.0 200.0 256.0]
const float sunPathRotation = -30.0; // [-40.0 -30.0 -20.0 -10.0 0.0 10.0 20.0 30.0 40.0]

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;
uniform sampler2D depthtex2;
uniform sampler2D shadowtex1;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;
uniform vec3 fogColor;
uniform float viewWidth;
uniform float viewHeight;
uniform float far;
uniform float rainStrength;
uniform float frameTimeCounter;
uniform float blindness;
uniform float sunAngle;
uniform int isEyeInWater;

varying vec2 texcoord;

float bayer2(vec2 a) { a = floor(a); return fract(a.x * 0.5 + a.y * a.y * 0.75); }
float bayer4(vec2 a) { return bayer2(0.5 * a) * 0.25 + bayer2(a); }
float bayer8(vec2 a) { return bayer4(0.5 * a) * 0.25 + bayer4(a); }

vec3 toShadowClip(vec3 playerPos) {
    return (shadowProjection * (shadowModelView * vec4(playerPos, 1.0))).xyz;
}

// Schattenkarte abtasten (mit derselben Verzerrung wie shadow.vsh)
float sampleShadow(vec3 sclip, vec2 texelOff, float biasMul) {
    float f = length(sclip.xy) * 0.9 + 0.1;
    vec3 p = vec3(sclip.xy / f, sclip.z) * 0.5 + 0.5;
    p.xy += texelOff;
    if (p.x < 0.0 || p.x > 1.0 || p.y < 0.0 || p.y > 1.0 || p.z > 1.0) return 1.0;
    float bias = (0.0012 * f * f + 0.0005) * biasMul;
    // shadowtex1 = Schattenkarte ohne Glas/Wasser -> Transluzentes wirft keinen Vollschatten
    float diff = (p.z - bias) - texture2D(shadowtex1, p.xy).x;
    return step(diff, 0.0);
}

// View-Position an beliebiger Bildschirmposition rekonstruieren
vec3 viewPosAt(vec2 uv) {
    float d = texture2D(depthtex0, uv).x;
    vec4 ndc = vec4(uv * 2.0 - 1.0, d * 2.0 - 1.0, 1.0);
    vec4 v = gbufferProjectionInverse * ndc;
    return v.xyz / v.w;
}

// Robuste Flaechen-Normale: pro Achse die Nachbarseite mit dem kleineren
// Tiefensprung nehmen — liefert auch an Objektkanten korrekte Normalen
vec3 normalAt(vec2 uv, vec3 c) {
    vec2 px = vec2(1.0 / viewWidth, 1.0 / viewHeight);
    vec3 r = viewPosAt(uv + vec2(px.x, 0.0));
    vec3 l = viewPosAt(uv - vec2(px.x, 0.0));
    vec3 u = viewPosAt(uv + vec2(0.0, px.y));
    vec3 d = viewPosAt(uv - vec2(0.0, px.y));
    vec3 dx = (abs(r.z - c.z) < abs(c.z - l.z)) ? (r - c) : (c - l);
    vec3 dy = (abs(u.z - c.z) < abs(c.z - d.z)) ? (u - c) : (c - d);
    vec3 n = cross(dx, dy);
    // am Bildschirmrand koennen die Differenzen null werden -> kein NaN
    if (dot(n, n) < 1.0e-12) return vec3(0.0, 0.0, 1.0);
    return normalize(n);
}

void main() {
    vec4 color = texture2D(colortex0, texcoord);
    // depthtex0 (Live-Tiefe) IST hier die opake Szene: Transluzente sind
    // noch nicht gezeichnet. depthtex1 waere riskant — die Kopie wird je
    // nach Loader erst NACH dem deferred-Pass angelegt und liest dann
    // leer (alle Distanzen ~0 -> Nebel/Schatten/VL komplett wirkungslos)
    float depth = texture2D(depthtex0, texcoord).x;
    // Hand-Pixel erkennen: depthtex2 = Szene OHNE Hand. Auf der Hand keine
    // Schatten-/SSAO-Tests — die komprimierte Hand-Tiefe liefert falsche
    // Normalen und wuerde den Arm je nach Blickrichtung zur Sonne abdunkeln
    bool isHand = depth < texture2D(depthtex2, texcoord).x - 1.0e-6;

    // Abstand zur Kamera aus dem Depth-Buffer rekonstruieren
    vec4 ndc = vec4(texcoord * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 viewPos4 = gbufferProjectionInverse * ndc;
    vec3 viewPos = viewPos4.xyz / viewPos4.w;
    float dist = length(viewPos);
    vec3 playerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

    // Dimension zur LAUFZEIT an der Nebelfarbe erkennen — world-Ordner
    // funktionieren auf manchen Loadern nicht zuverlaessig.
    // Nether: kraeftig roter Nebel (gruen fast null, rot >> blau)
    // End: dunkler violett-grauer Nebel (rot & blau beide ueber gruen)
    bool isNether = fogColor.r > 0.10 && fogColor.g < 0.12 && fogColor.r > fogColor.b * 1.8;
    bool isEnd    = fogColor.r < 0.20 && fogColor.b < 0.30
                 && fogColor.r - fogColor.g > 0.01 && fogColor.b - fogColor.g > 0.01;

    // Das End hat kein Himmelslicht — Grundhelligkeit einfach linear
    // anheben, damit Inseln und Tuerme nicht im Schwarz verschwinden.
    // Moderat gewaehlt, damit Fackel-/Kerzenlicht nicht uebersteuert.
    // Overworld-Hoehlen sind nie betroffen.
    if (isEnd && depth < 1.0) color.rgb = color.rgb * 1.4 + 0.05;

    // ============ Schatten ============
    // im Nether/End gibt es keine Sonne — Schattenkarte dort ueberspringen
#ifdef SHADOWS
    if (depth < 1.0 && !isNether && !isEnd && !isHand) {
        // nur Flaechen abdunkeln, die Himmelslicht sehen (Hoehlen/Innenraeume bleiben unberuehrt)
        vec4 lmData = texture2D(colortex1, texcoord);
        float skyExp = lmData.y;
        float shStr = SHADOW_STRENGTH * smoothstep(0.05, 0.65, skyExp);
        shStr *= 1.0 - rainStrength * 0.8;
        // Fackellicht schuetzt vor Schatten-Abdunklung
        shStr *= 1.0 - smoothstep(0.35, 0.85, lmData.x);
        // bei sehr flach stehender Sonne/Mond (Daemmerung) reicht die
        // Aufloesung der Schattenkarte nicht mehr — das erzeugt Streifen-
        // muster auf Haengen. Schatten dort sanft ausblenden.
        float lightH = abs(sin(sunAngle * 6.2831853));
        shStr *= smoothstep(0.04, 0.18, lightH);

        // beim Tauchen: Schatten extra stark. NUR wenn die Kamera selbst im
        // Wasser ist — der alte Test "irgendein Transluzentes davor" hat den
        // Boost auch hinter Nether-Portalen und Buntglas gezuendet
        if (isEyeInWater == 1) shStr = min(shStr * 1.6, 0.95);

        if (shStr > 0.005) {
            vec3 normal = normalAt(texcoord, viewPos);
            float NdotL = dot(normal, normalize(shadowLightPosition));
            float faceLit = smoothstep(0.0, 0.12, NdotL);
            float biasMul = SHADOW_BIAS * clamp(0.25 / max(NdotL, 0.05), 1.0, 5.0);

            float sh = 0.0;
            if (faceLit > 0.001) {
                // Normal-Offset gegen Acne: den Abtastpunkt von der Flaeche
                // abheben — wirkt auf sanften Haengen (Duenen!) viel besser
                // als reiner Tiefen-Bias und verhindert die Wellenmuster
                // Offset waechst mit der Entfernung: weiter weg sind die
                // Schattenkarten-Texel groesser -> mehr Abstand noetig,
                // sonst entstehen dort Acne-Streifen auf dem Gelaende
                float offLen = 0.1 + dist * 0.012;
                vec3 offPos = playerPos + (mat3(gbufferModelViewInverse) * normal) * offLen;
                vec3 sclip = toShadowClip(offPos);
                float texel = 1.0 / float(shadowMapResolution);

#if SHADOW_SOFT == 0
                sh = sampleShadow(sclip, vec2(0.0), biasMul);
#elif SHADOW_SOFT == 1
                for (int i = -1; i <= 1; i++)
                for (int j = -1; j <= 1; j++)
                    sh += sampleShadow(sclip, vec2(float(i), float(j)) * texel, biasMul);
                sh /= 9.0;
#else
                for (int i = -2; i <= 2; i++)
                for (int j = -2; j <= 2; j++)
                    sh += sampleShadow(sclip, vec2(float(i), float(j)) * texel * 1.5, biasMul);
                sh /= 25.0;
#endif
                sh *= faceLit;
            }

            // Schatten zur Distanzgrenze hin ausblenden
            float fade = smoothstep(shadowDistance * 0.70, shadowDistance * 0.95, dist);
            sh = mix(sh, 1.0, fade);
            color.rgb *= mix(1.0 - shStr, 1.0, sh);
        }
    }
#endif

    // ============ Kontaktschatten (SSAO) ============
    // Objekte werfen weiche Schatten in Ecken und um sich herum —
    // rund um Blocklicht verstaerkt, damit Fackeln eigene Schatten erzeugen
#ifdef SSAO
    if (depth < 1.0 && dist < 48.0 && !isHand) {
        vec3 nrm = normalize(cross(dFdx(viewPos), dFdy(viewPos)));
        float torchAO = texture2D(colortex1, texcoord).x;

        float uvRad = 0.35 * gbufferProjection[1][1] * 0.5 / max(dist, 0.5);
        float ang = bayer8(gl_FragCoord.xy) * 6.2831853;
        float ao = 0.0;
        for (int i = 0; i < 8; i++) {
            float a = ang + float(i) * 0.785398;
            float r = uvRad * (0.3 + 0.7 * float(i) / 7.0);
            vec2 suv = texcoord + vec2(cos(a), sin(a)) * r;
            float sd = texture2D(depthtex0, suv).x;
            vec4 sndc = vec4(suv * 2.0 - 1.0, sd * 2.0 - 1.0, 1.0);
            vec4 sv4 = gbufferProjectionInverse * sndc;
            vec3 diffV = sv4.xyz / sv4.w - viewPos;
            float dl = length(diffV);
            ao += clamp(dot(nrm, diffV / max(dl, 0.0001)) - 0.25, 0.0, 1.0)
                * clamp(1.0 - dl / 0.7, 0.0, 1.0);
        }
        ao /= 8.0;

        float aoStr = SSAO_STRENGTH * (0.6 + 0.6 * smoothstep(0.2, 0.8, torchAO));
        float distFade = 1.0 - smoothstep(32.0, 48.0, dist);
        color.rgb *= 1.0 - clamp(ao * aoStr, 0.0, 0.7) * distFade;
    }
#endif

    // ============ Nebel ============
    vec3 fogC = fogColor;
    float lum = dot(fogC, vec3(0.299, 0.587, 0.114));
    fogC = mix(fogC, vec3(lum), 0.5);
    fogC *= 0.85;
    fogC *= vec3(0.96, 1.0, 0.94);

    float density = 0.010 * FOG_DENSITY;
    density *= 1.0 + rainStrength * 2.0;
    density *= 1.0 + blindness * 4.0;
    // Nether: dichter, erstickender Nebel
    if (isNether) density *= 1.4;
    // End: der Nebel darf nie schwarz sein — fahler violett-grauer Dunst
    // als Untergrenze, sonst schluckt die Nebelwand die Ferne komplett
    if (isEnd) fogC = max(fogC, vec3(0.16, 0.15, 0.21));
#ifdef FOG_BREATHING
    density *= 1.0 + 0.12 * sin(frameTimeCounter * 0.13);
#endif

    if (isEyeInWater == 1) {
        // Unterwasser-Nebel skaliert mit dem Nebeldichte-Regler
        density = max(density, 0.10 * FOG_DENSITY);
        fogC = vec3(0.03, 0.07, 0.06);
    } else if (isEyeInWater == 2) {
        density = max(density, 0.60);
        fogC = vec3(0.45, 0.12, 0.02);
    }

    // ============ Lichtstreifen: Raymarch durch die Schattenkarte ============
    float vis = 1.0;
    float phase = 0.0;
    float media = 0.0;
    float rainW = 1.0;
    float dnw = 0.0;
    vec3 lightCol = vec3(0.0);
#ifdef LIGHT_SHAFTS
    // Lichtstrahlen brauchen die Sonnen-Schattenkarte — nicht im Nether/End
    if (isEyeInWater != 2 && !isNether && !isEnd) {
        float rayLen = min(dist, shadowDistance);
        vec3 endPos = playerPos * (rayLen / max(dist, 0.001));
        vec3 sStart = toShadowClip(vec3(0.0));
        vec3 sEnd = toShadowClip(endPos);

        // geordnetes Bayer-Dithering statt Rauschen -> ruhigeres Bild in Bewegung
        float dither = bayer8(gl_FragCoord.xy);
        vis = 0.0;
        for (int i = 0; i < VL_SAMPLES; i++) {
            float t = (float(i) + dither) / float(VL_SAMPLES);
            vis += sampleShadow(mix(sStart, sEnd, t), vec2(0.0), 1.5);
        }
        vis /= float(VL_SAMPLES);

        // breite Streuphase: Strahlen auch sichtbar, wenn man nicht direkt
        // zur Sonne schaut — Richtung Sonne werden sie deutlich staerker
        vec3 viewDir = viewPos / max(dist, 0.001);
        float cosT = clamp(dot(viewDir, normalize(shadowLightPosition)), 0.0, 1.0);
        // enger Glow: kleine, kompakte Sonnenscheibe statt riesigem Fleck
        phase = 0.15 + 1.4 * pow(cosT, 20.0);

        float sunH = sin(sunAngle * 6.2831853);
        float dayF = clamp(sunH * 4.0, 0.0, 1.0);
        float nightF = clamp(-sunH * 4.0, 0.0, 1.0);
        rainW = 1.0 - rainStrength * 0.85;
        dnw = clamp(dayF + nightF * 0.6, 0.0, 1.0) * rainW;
        lightCol = dayF * vec3(0.85, 0.80, 0.68) + nightF * vec3(0.18, 0.22, 0.30);
        // unter Wasser: Sonnenstrahlen kuehl-gruenlich gefiltert
        if (isEyeInWater == 1) lightCol *= vec3(0.45, 0.80, 0.75);

        media = 1.0 - exp(-rayLen * density * 2.5);

        // Nebel in Schattensaeulen abdunkeln -> dunkle Streifen am Schattenrand
        fogC *= mix(1.0 - VL_DARKEN * dnw, 1.0, vis);
    }
#endif

    float fog;
    if (depth >= 1.0) {
        // Himmel im Dunst versinken lassen — zum Horizont hin voller Nebel,
        // damit der Look unabhaengig von der Renderdistanz gleich bleibt
        float upness = smoothstep(0.0, 0.35, normalize(playerPos).y);
        fog = clamp(mix(1.0, SKY_FOG, upness) + rainStrength * 0.25, 0.0, 1.0);
        // unter Wasser: Horizont versinkt im Truebwasser; nach oben derselbe
        // Dunst wie ueber Wasser, damit die Sonne in beiden Faellen gleich wirkt
        if (isEyeInWater == 1) fog = mix(1.0, 0.55, upness);
    } else {
        // Nebel beginnt erst ab FOG_START Bloecken (unter Wasser/Lava sofort)
        float fogDist = dist;
        if (isEyeInWater == 0) fogDist = max(dist - FOG_START, 0.0);
        fog = 1.0 - exp(-fogDist * density);
        // Nebelwand: ab FOG_LIMIT Bloecken immer voller Nebel — aber nie
        // spaeter als 85% der Renderdistanz (far), sonst schliesst sich
        // die Wand erst EXAKT an der Chunk-Kante und die bleibt sichtbar.
        // Volle Deckung schon bei 80% der Wanddistanz: die letzten Prozent
        // der Rampe liessen sonst Gelaende-Silhouetten kurz vor der Wand
        // als Chunk-Konturen gegen den Himmel durchschimmern
        float wallEnd = min(FOG_LIMIT, far * 0.85);
        fog = max(fog, smoothstep(wallEnd * 0.15, wallEnd * 0.8, dist));
    }

    // Die Transluzenten (Glas, Wasser, Portal, Partikel) sind hier noch
    // NICHT gezeichnet: sie mischen sich anschliessend ueber diese fertig
    // benebelte Szene und benebeln sich dabei selbst an ihrer eigenen
    // Distanz (layerFog in den gbuffers-Programmen) — Vanilla-Modell.
    color.rgb = mix(color.rgb, fogC, fog);

#ifdef LIGHT_SHAFTS
    // helle Strahlen in beleuchteten Nebelsaeulen
    color.rgb += lightCol * (vis * phase * media * VL_STRENGTH) * rainW;
#endif

/* DRAWBUFFERS:0 */
    gl_FragData[0] = color;
}
