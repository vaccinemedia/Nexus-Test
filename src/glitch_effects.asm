; glitch_effects.asm — new subtle-glitch effect kinds 4..7 + shared
; helpers, split out of glitch.asm so this block lives in the region
; AFTER the AKM song data. Keeping the kind 0..3 handlers in glitch.asm
; (they're referenced by many existing scenes) and just parking the
; new material here reclaims ~350 bytes of pre-AKM padding.

; -----------------------------------------------------------------
; pick_random_glitch_kind — returns a random subtle kind in A.
; Uses a weighted lookup table so the crowd-pleasers (ghost text,
; border ripple) come up more often, and the noisy full-screen
; effects (BRIGHT/FLASH/invert) stay rare enough to feel special.
; -----------------------------------------------------------------
pick_random_glitch_kind:
    call rng_tick
    and 31
    ld e, a
    ld d, 0
    ld hl, glitch_kind_weights
    add hl, de
    ld a, (hl)
    ret

; Kind IDs (indices into subtle_dispatch). Keep sequential.
GK_ATTR      EQU 0
GK_GAUGE     EQU 1
GK_GHOST     EQU 2
GK_BORDER    EQU 3
GK_BRIGHT    EQU 4
GK_FLASH     EQU 5
GK_STATIC    EQU 6
GK_INVERT    EQU 7
GK_FONT      EQU 8                    ; font swap
GK_TAPE      EQU 9                    ; tape-load stripes

subtle_dispatch:
    DW subtle_attr_corrupt            ; 0
    DW subtle_gauge_spike             ; 1
    DW subtle_ghost_text              ; 2
    DW subtle_border_ripple           ; 3
    DW subtle_bright_flash            ; 4
    DW subtle_flash_toggle            ; 5
    DW subtle_pixel_static            ; 6
    DW subtle_ink_paper_swap          ; 7
    DW subtle_font_swap               ; 8  (new)
    DW subtle_tape_load               ; 9  (new)

; 32-entry weighted kind selector. Distribution (keeps ghost + border
; dominant, adds moderate weight for font swap and tape stripes since
; both are dramatic new flavours worth surfacing).
;   Ghost text:      7/32  (22%)
;   Border ripple:   5/32  (16%)
;   Attr corrupt:    4/32  (12%)
;   Font swap:       3/32  (9%)   <- new, striking effect
;   Tape stripes:    3/32  (9%)   <- new, Speccy-authentic
;   Bright flash:    2/32  (6%)
;   Flash toggle:    2/32  (6%)
;   Pixel static:    2/32  (6%)
;   Ink/paper swap:  2/32  (6%)
;   Gauge spike:     2/32  (6%)
glitch_kind_weights:
    DB GK_GHOST, GK_GHOST, GK_GHOST, GK_GHOST
    DB GK_GHOST, GK_GHOST, GK_GHOST
    DB GK_BORDER, GK_BORDER, GK_BORDER, GK_BORDER, GK_BORDER
    DB GK_ATTR, GK_ATTR, GK_ATTR, GK_ATTR
    DB GK_FONT, GK_FONT, GK_FONT
    DB GK_TAPE, GK_TAPE, GK_TAPE
    DB GK_BRIGHT, GK_BRIGHT
    DB GK_FLASH, GK_FLASH
    DB GK_STATIC, GK_STATIC
    DB GK_INVERT, GK_INVERT
    DB GK_GAUGE, GK_GAUGE

; ----- Effect 4: whole-screen BRIGHT bit toggle -----
; Two-phase XOR: first hit flips BRIGHT on every attribute (bright
; cells go dim, dim cells go bright — a hard "voltage sag" look).
; Second hit XORs the same bit again, perfectly restoring the
; original state. Total effect dwell ~120ms.
subtle_bright_flash:
    call attr_xor_all_40
    ld a, (subtle_state)
    or a
    jr nz, .sbf_done
    ld a, 6
    ld (subtle_timer), a
    ld a, 1
    ld (subtle_state), a
    ret
.sbf_done:
    xor a
    ld (subtle_state), a
    ld (screen_drawn), a               ; force full redraw next frame in case
    ret                                ; something repainted during the dwell

; ----- Effect 5: whole-screen FLASH bit toggle -----
; Same self-inverse XOR trick but on bit 7 (FLASH). Screen strobes
; between normal and inverted at 50/50 duty for ~0.8s.
subtle_flash_toggle:
    call attr_xor_all_80
    ld a, (subtle_state)
    or a
    jr nz, .sft_done
    ld a, 40
    ld (subtle_timer), a
    ld a, 1
    ld (subtle_state), a
    ret
.sft_done:
    xor a
    ld (subtle_state), a
    ld (screen_drawn), a
    ret

; --- Helpers: XOR every attribute byte with a fixed mask. --------
; Two variants because embedding the mask directly saves 4 bytes each
; vs passing it in and lets us keep the loops tight.
attr_xor_all_40:
    ld hl, ATTR_BASE
    ld b, 3                            ; 3 outer passes
.axa4_o:
    push bc
    ld b, 0
.axa4_i:
    ld a, (hl)
    xor #40
    ld (hl), a
    inc hl
    djnz .axa4_i
    pop bc
    dec b
    jr nz, .axa4_o
    ret

attr_xor_all_80:
    ld hl, ATTR_BASE
    ld b, 3
.axa8_o:
    push bc
    ld b, 0
.axa8_i:
    ld a, (hl)
    xor #80
    ld (hl), a
    inc hl
    djnz .axa8_i
    pop bc
    dec b
    jr nz, .axa8_o
    ret

; ----- Effect 6: portrait pixel static burst -----
; Sprays random bytes into random pixel positions inside the portrait
; area, then redraws the portrait to restore. Purely destructive to
; pixel data — draw_portrait puts it back.
subtle_pixel_static:
    ld b, 20                           ; 20 random pixel scribbles
.spx_lp:
    push bc
    call rng_tick
    push af                            ; A = random byte to poke
    ; Character row (portrait row 0..PORTRAIT_H-1)
    call rng_tick
    and #0f
    cp PORTRAIT_H
    jr c, .spx_row_ok
    ld a, PORTRAIT_H - 1
.spx_row_ok:
    add a, PORTRAIT_ROW                ; final char row
    ld d, a
    ; Character column
    call rng_tick
    and 7
    add a, PORTRAIT_COL
    ld e, a
    ; Pixel row within the cell (0..7)
    call rng_tick
    and 7
    ld c, a
    ; Build screen address (matches print_char layout):
    ;   H = (char_row & #18) | #40, then += pixel_row
    ;   L = ((char_row & 7) << 5) | char_col
    ld a, d
    and #18
    or #40
    add a, c
    ld b, a                            ; H byte
    ld a, d
    and 7
    rlca
    rlca
    rlca
    rlca
    rlca
    or e
    ld c, a                            ; L byte
    pop af
    ld (bc), a
    pop bc
    djnz .spx_lp
    ; Repaint portrait cleanly next frame
    ld hl, (current_subj)
    jp draw_portrait

; ----- Effect 7: ink/paper swap across the whole screen -----
; Every attribute has its INK (bits 0-2) and PAPER (bits 3-5) swapped,
; leaving FLASH and BRIGHT untouched. Second hit swaps again to
; restore, so no scratch buffer needed. ~0.4s inverted.
subtle_ink_paper_swap:
    call attr_swap_ink_paper
    ld a, (subtle_state)
    or a
    jr nz, .sips_done
    ld a, 20
    ld (subtle_timer), a
    ld a, 1
    ld (subtle_state), a
    ret
.sips_done:
    xor a
    ld (subtle_state), a
    ld (screen_drawn), a
    ret

attr_swap_ink_paper:
    ld hl, ATTR_BASE
    ld b, 3
.asip_o:
    push bc
    ld b, 0
.asip_i:
    ld a, (hl)
    ld e, a                            ; original
    and #07
    add a, a
    add a, a
    add a, a                           ; ink << 3  -> paper position
    ld c, a
    ld a, e
    and #38
    rrca
    rrca
    rrca                               ; paper >> 3 -> ink position
    or c                               ; combined swapped ink+paper
    ld c, a
    ld a, e
    and #C0                            ; keep flash+bright
    or c
    ld (hl), a
    inc hl
    djnz .asip_i
    pop bc
    dec b
    jr nz, .asip_o
    ret

; ----- Effect 8: font swap ------------------------------------------
; Point font_base at an arbitrary ROM address so every glyph reads
; some other 8-byte chunk of the machine's memory — chars become
; unreadable, "wrong-alphabet" nonsense. Force a full redraw so the
; effect lands immediately, then wait ~1.2s and restore.
FONT_GARBAGE_ADDR EQU #3400            ; mid-ROM; produces varied byte patterns
subtle_font_swap:
    ld a, (subtle_state)
    or a
    jr nz, .sfw_restore
    ; Phase 0: snapshot current font pointer, swap in garbage, redraw.
    ld hl, (font_base)
    ld (glitch_saved_font), hl
    ld hl, FONT_GARBAGE_ADDR
    ld (font_base), hl
    xor a
    ld (screen_drawn), a               ; force redraw with garbage font
    ld a, 60                           ; ~1.2s dwell
    ld (subtle_timer), a
    ld a, 1
    ld (subtle_state), a
    ret
.sfw_restore:
    ; Phase 1: restore original font, force redraw so text goes back.
    ld hl, (glitch_saved_font)
    ld (font_base), hl
    xor a
    ld (screen_drawn), a
    ld (subtle_state), a
    ret

; ----- Effect 9: fake tape-load stripes -----------------------------
; Runs a burst of tight border-colour toggles at the start of each
; frame for ~40 frames. Because the CPU is doing OUT (#fe) in a
; scanline-relative burst, the ULA paints a stack of horizontal
; stripes in the border — the classic "loading" look. Between bursts
; the game continues normally, so no interrupts are disabled.
subtle_tape_load:
    ld a, (subtle_state)
    cp 40
    jr nc, .stl_done
    ; ~30 stripe pairs in a burst (~1.5ms), aligned to same relative
    ; position each frame -> a static-ish tape-loader border band.
    ld c, 30
.stl_burst:
    ld a, #01                          ; blue (tape data stripe)
    out (#fe), a
    ld b, 12
.stl_d1:
    djnz .stl_d1
    ld a, #06                          ; yellow (tape data stripe)
    out (#fe), a
    ld b, 12
.stl_d2:
    djnz .stl_d2
    dec c
    jr nz, .stl_burst
    ; End burst by restoring black — outside the burst window the
    ; border stays black until next frame's burst.
    xor a
    out (#fe), a
    ld a, (subtle_state)
    inc a
    ld (subtle_state), a
    ld a, 1                            ; re-fire next frame
    ld (subtle_timer), a
    ret
.stl_done:
    xor a
    out (#fe), a                       ; final restore just in case
    ld (subtle_state), a
    ret
