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

; =====================================================================
; gc_draw_boot_menu — recreation of the real ZX Spectrum 128 boot menu.
;
; Geometry and colours were measured off a screenshot of a real machine
; (see the BOOT_* / ATTR_BOOT_* constants in const.inc):
;   * Screen and border are plain white; the box interior is BRIGHT white.
;   * Row 7 is a black title bar: "128" in bright white at column 7, then
;     five cells of rainbow at columns 15..19.
;   * Rows 8..12 hold the menu items, "Tape Loader" highlighted in cyan.
;   * Row 13 is blank and carries the box's bottom rule.
;   * The copyright line sits on the bottom row of the screen.
;
; The box outline is a single pixel wide, so no font glyph can draw it —
; the rules go straight into the bitmap instead.
; =====================================================================
gc_draw_boot_menu:
    ld a, ATTR_BOOT_BG
    call clear_screen_attrs            ; also blanks the bitmap
    ld a, INK_WHITE
    out (#fe), a                       ; white border, as on a real 128

    ; ---- Box interior: BRIGHT white paper down to the bottom rule ----
    ld d, BOOT_ROW_MENU
.gdbm_body:
    ld b, BOOT_COL_L
    ld e, BOOT_WIDTH
    ld a, ATTR_BOOT_BOX
    call set_row_attrs                 ; preserves D
    inc d
    ld a, d
    cp BOOT_ROW_BOT + 1
    jr c, .gdbm_body

    ; ---- Title bar: black across the box, "128" in bright white ----
    ld d, BOOT_ROW_TOP
    ld b, BOOT_COL_L
    ld e, BOOT_WIDTH
    ld a, ATTR_BOOT_TITLE
    call set_row_attrs
    ld a, BOOT_COL_L
    ld (pr_col), a
    ld a, BOOT_ROW_TOP
    ld (pr_row), a
    ld hl, str_boot_128
    call print_str

    ld d, BOOT_ROW_TOP
    ld c, BOOT_RAIN_COL
    call gc_draw_rainbow

    ; ---- Menu items, one per row. Empty string ends the table. ----
    ld hl, boot_menu_lines
    ld d, BOOT_ROW_MENU
.gdbm_items:
    ld a, (hl)
    or a
    jr z, .gdbm_highlight
    push de
    ld a, BOOT_TEXT_COL
    ld (pr_col), a
    ld a, d
    ld (pr_row), a
    call print_str                     ; HL left on the null terminator
    inc hl
    pop de
    inc d
    jr .gdbm_items

.gdbm_highlight:
    ; ---- Initial selection sits on "Tape Loader" ----
    ld d, BOOT_ROW_MENU
    ld b, BOOT_COL_L
    ld e, BOOT_WIDTH
    ld a, ATTR_BOOT_SEL
    call set_row_attrs

    ; ---- Box outline. Verticals first, then the bottom rule. ----
    ld d, BOOT_ROW_MENU
.gdbm_rules:
    ld e, BOOT_COL_L
    ld c, #80                          ; leftmost pixel of the cell
    call gc_cell_bits
    ld e, BOOT_COL_R
    ld c, #01                          ; rightmost pixel of the cell
    call gc_cell_bits
    inc d
    ld a, d
    cp BOOT_ROW_BOT + 1
    jr c, .gdbm_rules
    ld d, BOOT_ROW_BOT
    ld e, BOOT_COL_L
    call gc_cell_addr
    ld a, h
    add a, 7                           ; last scanline of the character row
    ld h, a
    ld b, BOOT_WIDTH
.gdbm_bottom:
    ld (hl), #FF
    inc l
    djnz .gdbm_bottom

    ; ---- Copyright line at the foot of the screen ----
    ld a, BOOT_COPY_COL
    ld (pr_col), a
    ld a, BOOT_COPY_ROW
    ld (pr_row), a
    ld hl, str_bas_copy
    jp print_str

; =====================================================================
; gc_draw_basic_screen — the 128 BASIC editor screen, as it looks on a
; real machine once "128 BASIC" is chosen from the boot menu: plain white
; paper with black text, nothing at the top at all, and a black status
; bar on row 21 carrying "128 BASIC" plus the rainbow motif.
; =====================================================================
gc_draw_basic_screen:
    ld a, ATTR_BAS_TEXT
    call clear_screen_attrs
    ld a, INK_WHITE
    out (#fe), a
    ld d, BAS_BAR_ROW
    ld b, 0
    ld e, 32
    ld a, ATTR_BAS_BAR
    call set_row_attrs
    xor a
    ld (pr_col), a
    ld a, BAS_BAR_ROW
    ld (pr_row), a
    ld hl, str_bas_bar
    call print_str
    ld d, BAS_BAR_ROW
    ld c, BAS_RAIN_COL
    jp gc_draw_rainbow

; =====================================================================
; gc_draw_rainbow — the five-cell diagonal rainbow, top-left cell at
; (D = row, C = first column). The real ROM uses the same motif on the
; boot screen's title bar and on the BASIC editor's status bar.
; =====================================================================
gc_draw_rainbow:
    push bc                            ; keep the start column
    ld hl, gc_rainbow_attrs
    ld b, BOOT_RAIN_CELLS
.gdr_attr:
    push bc
    push hl
    ld a, (hl)
    ld b, c                            ; B = column, A = attribute
    ld e, 1
    call set_row_attrs                 ; preserves D
    pop hl
    pop bc
    inc hl
    inc c
    djnz .gdr_attr
    pop bc                             ; C = first column again
    ld b, BOOT_RAIN_CELLS
.gdr_pix:
    push bc
    push de                            ; set below, so keep the row
    ld e, c
    call gc_cell_addr
    ld de, gc_rainbow_pattern
    ld b, 8
.gdr_byte:
    ld a, (de)
    ld (hl), a
    inc de
    inc h                              ; next scanline within the cell
    djnz .gdr_byte
    pop de
    pop bc
    inc c
    djnz .gdr_pix
    ret

; ---------------------------------------------------------------------
; gc_cursor_draw / gc_cursor_erase — the editor's block cursor, parked
; on the cell the type engine is about to fill. The blue/white blink is
; the attribute's FLASH bit, so the ULA animates it for free.
;
; Erasing blanks the cell so the next character prints over clean paper.
; ---------------------------------------------------------------------
gc_cursor_draw:
    ld a, ATTR_BAS_CURSOR
    ld c, #FF                          ; solid block
    jr gc_cursor_set
gc_cursor_erase:
    ld a, ATTR_BAS_TEXT
    ld c, 0
gc_cursor_set:
    push af
    ld a, (type_row)
    ld d, a
    ld a, (type_col)
    ld e, a
    call gc_cell_bits                  ; preserves DE
    pop af
    ld b, e
    ld e, 1
    jp set_row_attrs

; ---------------------------------------------------------------------
; beeper_click — one short pulse on the internal speaker.
; A = border colour to hold while the speaker bit toggles (port #FE
; carries both), so the click doesn't flash the border.
;
; Measured off a real 128 typing in the editor: the key click is a single
; 3.6 ms square pulse, not a tone, which is why it reads as a "tick"
; rather than a note. One pulse reproduces it exactly.
;
; Interrupts are off for the pulse so the ROM's frame handler can't
; stretch it, then restored — the game normally runs with them enabled.
; Blocking is fine here: ~12,700 T out of a ~70,000 T frame, and only on
; the frames that actually emit a character.
; ---------------------------------------------------------------------
; 26 T per loop iteration. 496 iterations plus entry/exit overhead is
; ~12,916 T, which at the 128K's 3.5469 MHz is 3.64 ms. Raise for a
; duller click, lower for a sharper one.
BEEPER_CLICK_LEN EQU 496

beeper_click:
    ld c, a                            ; C = border alone
    or #10                             ; bit 4 = speaker on
    di
    out (#fe), a
    ld hl, BEEPER_CLICK_LEN
.bc_wait:
    dec hl
    ld a, h
    or l
    jr nz, .bc_wait
    ld a, c
    out (#fe), a                        ; speaker off, border unchanged
    ei
    ret

; A 45-degree colour boundary: PAPER fills the top-left of the cell,
; INK the bottom-right. Stacking five of these with each cell's PAPER
; matching its neighbour's INK gives the boot screen's slanted rainbow.
gc_rainbow_pattern:
    DB #01,#03,#07,#0F,#1F,#3F,#7F,#FF

gc_rainbow_attrs:
    DB INK_RED    + (INK_BLACK*8)  + BRIGHT      ; black  -> red
    DB INK_YELLOW + (INK_RED*8)    + BRIGHT      ; red    -> yellow
    DB INK_GREEN  + (INK_YELLOW*8) + BRIGHT      ; yellow -> green
    DB INK_CYAN   + (INK_GREEN*8)  + BRIGHT      ; green  -> cyan
    DB INK_BLACK  + (INK_CYAN*8)   + BRIGHT      ; cyan   -> black

; ---------------------------------------------------------------------
; gc_cell_addr — D = row (0-23), E = col (0-31) -> HL = address of the
; cell's top scanline. Corrupts A only.
; ---------------------------------------------------------------------
gc_cell_addr:
    ld a, d
    and #18                            ; which third of the screen
    or #40
    ld h, a
    ld a, d
    and 7                              ; row within the third
    rlca
    rlca
    rlca
    rlca
    rlca                               ; * 32 bytes per row
    or e
    ld l, a
    ret

; ---------------------------------------------------------------------
; gc_cell_bits — write C into all 8 scanlines of the cell at (D, E).
; Preserves DE. Used for the boot box's single-pixel vertical rules.
; ---------------------------------------------------------------------
gc_cell_bits:
    push de
    call gc_cell_addr
    ld b, 8
.gcb_lp:
    ld (hl), c
    inc h
    djnz .gcb_lp
    pop de
    ret

; =====================================================================
; check_debug_glitch_key — DEBUG HOOK, called from MainLoop every frame.
;
; Pressing "G" jumps straight into the ST_GLITCH_CRASH fake-crash / 128
; boot-menu sequence from (almost) any state, so the boot screen can be
; iterated on without playing 20 interrogations to reach it. When the
; sequence finishes it returns to whatever state was interrupted.
;
; Set DEBUG_GLITCH_KEY to 0 in const.inc to compile this out for release.
;
; Keeps its own held-flag instead of read_game_key's key_held so the
; normal input debounce is untouched.
; =====================================================================
check_debug_glitch_key:
  IF DEBUG_GLITCH_KEY
    ld a, #fd
    in a, (#fe)
    bit 4, a                           ; G = row A-S-D-F-G, bit 4
    jr z, .cdg_down
    xor a
    ld (dbg_g_held), a                 ; released — re-arm
    ret
.cdg_down:
    ld a, (dbg_g_held)
    or a
    ret nz                             ; still held from an earlier frame
    ld a, 1
    ld (dbg_g_held), a
    ; States ST_GLITCH_MED (7) upwards are the typed cutscenes, and they all
    ; share type_ptr/type_row/type_col with the crash sequence — interrupting
    ; one would leave it typing from a stale pointer on return. So the debug
    ; key only fires from the ordinary gameplay and menu states.
    ld a, (game_state)
    cp ST_GLITCH_MED
    ret nc
    ld (crash_return_state), a
    ; A subtle glitch may be mid-flight with the font swapped out or the
    ; border mid-ripple. Put both back so the boot screen renders clean,
    ; and cancel the scheduler so it can't stomp on the crash.
    call use_rom_font
    xor a
    out (#fe), a
    ld (subtle_state), a
    ld (subtle_timer), a
    ld (crash_phase), a
    ld (screen_drawn), a
    ld hl, 0
    ld (crash_timer), hl
    ld (glitch_wait_timer), hl
    ld a, ST_GLITCH_CRASH
    ld (game_state), a
  ENDIF
    ret
