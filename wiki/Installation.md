# Installation

## Requirements

| Requirement | Version |
|---|---|
| Minecraft | **1.16.5 – 1.21.x** |
| Shader loader | **Iris** (Fabric/Quilt/NeoForge) or **Oculus** (Forge) |
| GPU | **OpenGL 2.1 or higher** |

OptiFine is not required. The pack uses the classic OptiFine shader format, which Iris and Oculus support natively.

---

## Step-by-step

### 1. Install a shader loader

**Iris (recommended):** Install [Iris](https://modrinth.com/mod/iris) together with [Sodium](https://modrinth.com/mod/sodium) — easiest via the Modrinth App or Prism Launcher.

**Oculus (Forge):** Install [Oculus](https://modrinth.com/mod/oculus) together with [Embeddium](https://modrinth.com/mod/embeddium).

### 2. Download LOST TAPE

Download the latest `LOST_TAPE_vX.X.zip` from the [Releases page](https://github.com/EmilDeuOfficial/LostTapeShader/releases).

### 3. Place in shaderpacks folder

Copy the zip into your shaderpacks directory:

```
.minecraft/
└── shaderpacks/
    └── LOST_TAPE_v1.2.zip   ← here
```

Do **not** unzip it (a plain folder also works, but the zip is the normal way).

### 4. Select in-game

**Options → Video Settings → Shader Packs** → click **LOST_TAPE_v1.2.zip** → **Apply**.

### 5. Pick a preset

Open **Shader Pack Settings** and cycle the profile button at the top. See [Presets](Presets).

---

## Recommended game settings

- Render distance **8–12 chunks** — the fog swallows everything beyond it anyway
- Brightness on **Moody (0%)** — the shader controls darkness itself
- Vanilla clouds are already disabled by the pack

---

## Updating

1. Delete the old `LOST_TAPE_*.zip` from `shaderpacks/`
2. Copy in the new zip
3. Re-select it in the shader pack list

> Note: Iris stores your customized settings in a `.txt` named after the zip. If the file name changes between versions, your tweaks reset to defaults — pick your preset again.

---

## Uninstalling

1. Select **(off)** in the shader pack list
2. Delete the zip from `shaderpacks/`
