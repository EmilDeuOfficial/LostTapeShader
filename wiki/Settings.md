# Settings

All options live in **Shader Pack Settings**, grouped into five screens. Localized in English and German.

---

## Atmosphere & Fog

| Option | Range | What it does |
|---|---|---|
| Fog Density | 0 – 3 | Overall fog thickness (rain and blindness increase it further) |
| Fog Start Distance | 0 – 128 blocks | Clear bubble around the camera before fog begins (ignored underwater) |
| Sky Fog | 0 – 1 | How much the sky is swallowed by haze |
| Breathing Fog | on/off | Slow swelling and receding of the fog |
| Darkness | 0.8 – 2.0 | Gamma curve on sky/ambient light — higher = darker world |
| Night Brightness (Moonlight) | 0 – 3 | Cool ambient at night, only on sky-exposed surfaces; caves stay black |
| Torch Brightness | 0.5 – 2.0 | Block light strength — exempt from the Darkness curve |
| Sky Gloom | 0 – 1 | Desaturates, darkens, and tints the sky |
| Show Sun / Show Moon | on/off | Remove either from the sky entirely |
| Sun & Moon Brightness | 0.1 – 1.0 | Dims the celestial textures |

---

## Shadows & Light Shafts

| Option | Range | What it does |
|---|---|---|
| Shadows | on/off | Shadow-mapped sun/moon shadows (entities included) |
| Shadow Strength | 0.2 – 1.0 | How dark cast shadows are |
| Shadow Softness | Hard / Soft / Very Soft | PCF filter quality |
| Shadow Bias (Anti-Flicker) | 0.5 – 3.0 | Raise if you see stripe patterns or flicker on blocks |
| Shadow Resolution | 1024 – 4096 | Shadow map size |
| Shadow Distance | 64 – 256 blocks | Shadows fade out toward this distance |
| Sun Path Tilt | −40° – 40° | Tilts the sun's path for more dramatic angled shadows |
| Light Shafts | on/off | Volumetric god rays marched through the shadow map |
| Light Shaft Strength | 0 – 1.6 | Brightness of lit fog columns |
| Shadow Streak Contrast | 0 – 0.7 | How much fog darkens inside shadow columns (the visible streaks) |
| Light Shaft Quality | 8 – 32 | Raymarch samples — raise to smooth banding |
| Contact Shadows (SSAO) | on/off + 0.25 – 1.0 | Soft screen-space shadows in corners, boosted around block light |

---

## Retro / PSX

| Option | Range | What it does |
|---|---|---|
| PSX Vertex Snap | on/off | Geometry jitters like on PS1 |
| Snap Resolution | 96 – 400 | Lower = stronger wobble |
| Snap Mobs/Entities | on/off | Apply the wobble to entities too (round models get angular) |
| Pixelation | on/off + Pixel Size 2 – 8 | Renders the image in chunky pixels |
| Dithering | on/off | Bayer-ordered dithering |
| Color Depth | 8 – 64 levels | Color quantization steps per channel |

---

## Color Grade

| Option | Range | What it does |
|---|---|---|
| Saturation | 0 – 1.2 | 0 = black & white |
| Tint Color | Sepia / Sickly Green / Cold Blue | The pack's color cast |
| Tint Strength | 0 – 1 | How strong the cast is |
| Contrast | 0.9 – 1.3 | Push or flatten the image |
| Faded Blacks | 0 – 0.12 | Lifts blacks like worn tape |

---

## Analog Overlay

| Option | Range | What it does |
|---|---|---|
| Film Grain | 0 – 0.25 | Animated noise, stronger in shadows |
| Vignette | 0 – 1 | Darkened frame edges |
| Chromatic Aberration | 0 – 1 | RGB fringing toward screen edges |
| Scanlines | on/off + 0.1 – 0.5 | CRT line pattern |
| Analog Flicker | on/off | Subtle 24 fps brightness flicker |
| VHS Wobble | on/off | Horizontal tape distortion |
