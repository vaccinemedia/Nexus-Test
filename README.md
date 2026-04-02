# Nexus (ZX Spectrum 128K)

Blade Runner–inspired **Voight-style interrogation** prototype: title cityscape, AY title music, five probe rounds with keys **1 / 2 / 3**, then a verdict screen. Graphics lean toward a **Captain Blood** vibe (neon attribute skyline, wireframe scan panel).

## Requirements

- [sjasmplus](https://github.com/z00m128/sjasmplus) on `PATH`
- A **Spectrum 128** emulator (tested target: **FuseX**). Use a **128K machine** so paging and the AY chip match the build.

## Build

```bash
make
```

Output:

- **`out/nexus.sna`** — **use this in FuseX.** Double‑click or **File → Open**, with the machine set to **Spectrum 128**. The snapshot jumps straight to the game entry point.
- **`out/nexus.tap`** — **standard tape**: BASIC autorun (line **10** = `CLEAR` / `LOAD ""CODE` / `RANDOMIZE USR 32768`) plus a **CODE** block at **#8000**. In FuseX (**128**), open the TAP as tape / run tape load so the loader runs (you should **not** see `0 OK, 10:4` from the old snapshot format).

## Run (macOS)

```bash
make run
```

This looks for `/Applications/FuseX.app`, then other Fuse variants, and opens **`nexus.sna`**.

## Troubleshooting

- **Snapshot appears to hang** — older builds used **`HALT`** for frame timing; with **interrupts off** in `.sna` files that never wakes. Current builds use **`wait_frame`** in [`src/zx_sys.asm`](src/zx_sys.asm) (busy wait, no IRQ). Rebuild with `make` and open a fresh **`out/nexus.sna`**.
- **TAP shows `0 OK, 10:4` and stops** — that was the old **snapshot TAP** (not a real loader). Rebuild; **`nexus.tap`** is now a normal **BASIC + CODE** tape. Use **Spectrum 128**, start from tape load / reset so line **10** autoloads.

## Play

1. **Title** — AY loop (original-style minor pad, not a cover of any film score). Press almost any key.
2. **Interrogation** — Five rounds. **1** calm, **2** even, **3** hard probe. **Pupil stress** (0–99) reacts; replicants spike more under pressure.
3. **Verdict** — Threshold on stress (~52) plus hidden type decides outcome. **Any key** returns to the title.

## Game mechanics (placeholder design)

You can replace this with your full ChatGPT spec later; the code is structured around:

- **Hidden subject**: human vs replicant (RNG seed from `R` at session start).
- **Pressure**: starts at 28; each answer applies a **signed delta** from `table_human` / `table_rep` (five rounds × three options).
- **Outcomes**: replicant + high stress → retire; human + low stress → pass; wrong combinations → false positive / escaped replicant.

Tables live in [`src/game.asm`](src/game.asm).

## Source layout

| File | Role |
|------|------|
| `src/nexus.asm` | Entry, main loop (`HALT`), globals, strings, `SAVETAP` |
| `src/zx_sys.asm` | 128K **#7FFD** paging check, attribute/bitmap clear |
| `src/draw.asm` | Plot, lines, skyline, bitmap font, `print_str_bmp` |
| `src/ay_music.asm` | AY I/O, 3-channel pattern player (50 Hz) |
| `src/input.asm` | Keyboard matrix |
| `src/title.asm` | Title draw + key to start |
| `src/game.asm` | Rounds, scoring, outcome, scanner frame |
| `src/const.inc` | Ports, colours, state IDs |

## Music note

Playback is **native Z80** on the 128K AY. For **Arkos Tracker 2** (or similar) later, replace `ay_music.asm` with an exported player + song data and keep calling it from the same `HALT` loop.

## Legal

Homage project only — no affiliation with Blade Runner rights holders. Replace names/art for a public release if needed.
