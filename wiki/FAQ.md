# FAQ

---

### The shader won't load / "Pack is not valid"?

1. Make sure the zip is directly in `.minecraft/shaderpacks/` and **not unzipped into a nested folder**
2. Make sure you're running Iris or Oculus (check the Mods list)
3. Re-download the zip from the [Releases page](https://github.com/EmilDeuOfficial/LostTapeShader/releases) — a corrupted download can break loading

---

### Everything is way too dark — I can't see anything!

That's partly the point, but you have knobs:

1. Raise **Torch Brightness** (Atmosphere & Fog) — light sources stay bright regardless of darkness
2. Raise **Night Brightness (Moonlight)** for brighter nights outdoors
3. Lower **Darkness** toward 1.0
4. Or switch to the **Camcorder '98** or **Faint Signal** preset

---

### The fog is too dense / starts too close

Lower **Fog Density** and raise **Fog Start Distance** under **Atmosphere & Fog**. Rain intensifies fog on purpose.

---

### Shadows flicker or show stripe patterns on blocks

Raise **Shadow Bias (Anti-Flicker)** under **Shadows & Light Shafts** to 1.5 or 2.0. If shadow edges shimmer while walking, that can also be the PSX vertex wobble — raise **Snap Resolution** or disable **PSX Vertex Snap**.

---

### Round modded entities look angular/deformed

Disable **Snap Mobs/Entities** under **Retro / PSX**. It's off in every preset except **PSX Horror**.

---

### The light shafts look grainy or banded

Raise **Light Shaft Quality** from 16 to 24 or 32. It costs a little FPS but smooths the raymarch considerably.

---

### Does this work with OptiFine?

The pack uses the classic OptiFine shader format, so it *should* — but it is only tested with Iris and Oculus. Use Iris if you can.

---

### Does this work on servers?

Yes. Shaderpacks are purely client-side; you can join any server with it.

---

### What FPS impact should I expect?

Low, by shader standards. There is no PBR, no SSR, no bloom chain — the heavy parts are one shadow map, a light raymarch, and SSAO. On weak GPUs, lower **Shadow Resolution** to 1024, set **Light Shaft Quality** to 8, or disable **Contact Shadows**.

---

### My custom settings disappeared after updating

Iris stores tweaks in a `.txt` named after the zip (`LOST_TAPE_v1.2.zip.txt`). When the file name changes with a new version, settings start fresh. Back up the `.txt`, or rebuild your look from the closest preset.
