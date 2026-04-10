# Nexus Test (ZX Spectrum 128K)

**Android detection** interrogation game: pick probe topics on a grid, read the subject’s scenario and reply, watch Voight-style gauges, then call **HUMAN** or **ANDROID**. One hundred subjects, limited lives, scoring by speed (fewer questions = more points), high score table with initials.

Homage tone (e.g. *Blade Runner*); not affiliated with any rights holders.

## Requirements

- **[sjasmplus](https://github.com/z00m128/sjasmplus)** on `PATH`
- **Python 3** (for `tools/gen_loader.py` and `tools/relocate_akm.py`)
- **[RASM](https://github.com/EdouardBERGE/rasm)** — the Makefile expects the binary at **`/tmp/rasm/rasm`** (build with `make -f makefile.MacOS` in the RASM tree, or adjust `RASM :=` in [`Makefile`](Makefile)). RASM compiles the Arkos Tracker **AKM** player at the correct load address; without it, run `sjasmplus` manually only if `src/akm_player.bin` and `src/title_music_relocated.akm` already exist.
- A **Spectrum 128** emulator (e.g. **FuseX**). Use **128K** so **#7FFD** paging and the **AY-3-8912** match the build.

## Build

```bash
make
```

- First run (or after `make clean`): sjasmplus is invoked to find where the AKM player sits in memory, RASM builds `src/akm_player.bin`, Python relocates `src/title_music.akm` → `src/title_music_relocated.akm` (absolute pointers), then sjasmplus links the final binary.

Output:

- **`out/nexus.sna`** — open in FuseX as **Spectrum 128** (recommended).
- **`out/nexus.tap`** — BASIC loader + CODE at **#8000**.

```bash
make run    # macOS: tries to open out/nexus.sna in FuseX
```

## Troubleshooting

- **Snapshot “hangs”** — the main loop uses **`wait_frame`** (busy wait), not `HALT`, while the CPU runs with **interrupts disabled**; use a current build and a fresh `.sna`.
- **TAP stops at `0 OK, 10:4`** — use the generated **`nexus.tap`** from this repo (BASIC + CODE), not an old snapshot-as-tape format.
- **Garbled title music after changing code** — run **`make clean && make`** so the AKM player and relocated song match the new layout.
- **`make` fails: RASM not found** — install/build RASM and point `RASM` in the Makefile, or restore `akm_player.bin` / `title_music_relocated.akm` from a successful build before using sjasmplus alone.

## How to play

1. **Title** — Full-screen bitmap title; **Arkos Tracker 3** music on the AY. Subtitle and **PRESS ANY KEY**. After a timeout, the **high score** attract screen appears; any key starts a **new game** (score resets; **high score table stays in RAM** until you use a fresh snapshot or clear memory).
2. **Level intro** — Subject number and name; key skips the short delay.
3. **Interrogation** — Move on the **QAOP** grid; **SPACE** selects an icon (up to **three** probes per question). **ENTER** asks. **0** clears the query. Icons map to topics (memory, fear, pain, animal, child, etc.).
4. **Readout** — A **scenario** line and a **subject response** appear in the text panel. Text is built from **templates + token pools** (noun/detail) so the answer refers to the same thing as the prompt, with variety and compact data.
5. **Gauges** — **PUPIL** and **FLUSH** bars, **PATTERN** and **Q-WEIGHT** labels reflect the probe and subject model.
6. **Verdict** — **H** = human, **R** = android (see on-screen legend). Correct guess: **HELL YEAH** beeper sample and **round score** (see below). Wrong: **oh no** sample and lose a **life**; at **0 lives** you go straight to **game over** with final score.
7. **Between levels** — Verdict screen shows points for the round, **running total**, lives; key continues.
8. **Game over / high score** — If your total qualifies, enter **three initials**; then the table is shown. Table entries are **sorted by insert position** (best at top); defaults fill unused slots until replaced.

### Scoring

- **Base** round score: **100** points for a correct verdict.
- **Penalty** per question already asked that level: increases with **level number** (see `get_penalty` in [`src/subjects.asm`](src/subjects.asm)).
- Formula: **max(0, 100 − questions_asked × penalty)** added to **total** on a correct verdict; wrong verdict adds **0**.
- All cumulative and table scores use **16-bit** values in logic and display.

### Audio

- **Title / hiscore attract**: Arkos **AKM** player (custom `title_music.akm`), with **DI/EI** around play calls so the player’s stack tricks are IRQ-safe.
- **In-game**: simple **AY** ambient; short **AY** clicks/chirps for UI; **beeper** PCM for win/lose stingers.

## Source layout (overview)

| Area | Files |
|------|--------|
| Entry, loop, globals | [`src/nexus.asm`](src/nexus.asm) |
| 128K paging, clear, `wait_frame` | [`src/zx_sys.asm`](src/zx_sys.asm) |
| Text, fonts, `print_num16`, `print_str_box` | [`src/draw.asm`](src/draw.asm) |
| Keys | [`src/input.asm`](src/input.asm) |
| AY, beeper, AKM blob + song | [`src/ay_music.asm`](src/ay_music.asm) |
| RASM wrapper for player | [`src/akm_build.asm`](src/akm_build.asm) |
| AKM relocation | [`tools/relocate_akm.py`](tools/relocate_akm.py) |
| Portrait drawing | [`src/portrait.asm`](src/portrait.asm) |
| Query class, gauges, **tokens**, templates | [`src/question.asm`](src/question.asm) |
| Subjects, penalties | [`src/subjects.asm`](src/subjects.asm) |
| Strings, token data | [`src/data_text.asm`](src/data_text.asm) |
| Title SCR | [`src/title.asm`](src/title.asm) |
| States: intro, interrogation, verdict, game over | [`src/game.asm`](src/game.asm) |
| High scores | [`src/hiscore.asm`](src/hiscore.asm) |
| Constants, layout | [`src/const.inc`](src/const.inc) |

## Replacing title music

1. Export from **Arkos Tracker 3** as **AKM** + `*_playerconfig.asm` for this song.
2. Replace [`src/title_music.akm`](src/title_music.akm) and [`src/title_music_playerconfig.asm`](src/title_music_playerconfig.asm).
3. **`make clean && make`** so the song is relocated to the new load address.

## Legal

Homage only. Replace names, art, and any third-party music if you ship publicly.
