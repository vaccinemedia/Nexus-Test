; title.asm — Title screen with converted bitmap and attract mode

title_init:
    xor a
    ld (screen_drawn), a
    call ay_init_title
    ld hl, 0
    ld (attract_timer), hl
    ret

title_frame:
    ld a, (screen_drawn)
    or a
    jp nz, .tf_no_redraw

    ; Copy the pre-converted SCR bitmap directly to screen memory
    ld hl, title_scr_data
    call copy_scr_to_screen

    ; Black strips behind bottom text rows (20, 22)
    ld d, 20
    call clear_pixel_strip
    ld d, 22
    call clear_pixel_strip

    ; Set full-width black-paper attrs for bottom strip rows
    ld d, 20
    ld b, 0
    ld e, 32
    ld a, INK_GREEN + (INK_BLACK*8) + BRIGHT
    call set_row_attrs
    ld d, 22
    ld b, 0
    ld e, 32
    ld a, INK_CYAN + (INK_BLACK*8) + BRIGHT
    call set_row_attrs

    ; Use custom sci-fi font for bottom text
    call use_custom_font

    ; "ANDROID DETECTION UNIT" at bottom, row 20
    ld a, 5
    ld (pr_col), a
    ld a, 20
    ld (pr_row), a
    ld hl, str_subtitle
    call print_str

    ; "PRESS ANY KEY" at bottom, row 22
    ld a, 9
    ld (pr_col), a
    ld a, 22
    ld (pr_row), a
    ld hl, str_press
    call print_str

    ; Restore ROM font for other screens
    call use_rom_font

    ld a, 1
    ld (screen_drawn), a
    ld hl, 0
    ld (attract_timer), hl

.tf_no_redraw:
    ; Attract mode timer
    ld hl, (attract_timer)
    inc hl
    ld (attract_timer), hl
    ; Check if 500 frames (10 seconds)
    ld a, h
    cp 1
    jr c, .tf_check_key
    ld a, l
    cp 244             ; 1*256+244 = 500
    jr c, .tf_check_key
    ; Switch to high score display
    xor a
    ld (screen_drawn), a
    ld a, ST_HISCORE
    ld (game_state), a
    xor a
    ld (hiscore_entry_mode), a
    ret

.tf_check_key:
    call read_any_key
    or a
    ret z
    ; Start the game
    call ay_mute
    jp start_new_game        ; was CALL+RET — saves 1 byte, 17T

; =================================================================
; ST_INTRO — Blade-Runner-style opening crawl.
; Phase 0: mute music, wipe screen to black, prime the type engine.
; Phase 1: type intro_text one character at a time (~60ms/char).
; Phase 2: hold the completed screen for INTRO_HOLD_FRAMES so the
;          player can read it (any key skips the hold).
; Phase 3: transition to ST_LEVEL_INTRO for interrogation 1.
; The intro_text lives in bank 5 alongside the other glitch strings.
; =================================================================
INTRO_HOLD_FRAMES EQU 200                          ; ~4s auto-advance
INTRO_TYPE_DELAY  EQU 2                            ; ~40ms per character
INTRO_START_COL   EQU 4
INTRO_START_ROW   EQU 6
INTRO_ATTR        EQU INK_CYAN + (INK_BLACK*8) + BRIGHT

intro_frame:
    ld a, (intro_phase)
    or a
    jr z, .intr_p0
    cp 1
    jr z, .intr_p1
    cp 2
    jr z, .intr_p2
    ; Phase 3 — exit to ST_LEVEL_INTRO. Reset screen_drawn so the
    ; level intro re-renders cleanly, and mute AY so any in-flight
    ; typewriter blip doesn't leak into the next state.
    call ay_mute
    xor a
    ld (screen_drawn), a
    ld a, ST_LEVEL_INTRO
    ld (game_state), a
    ret

.intr_p0:
    call ay_mute
    call use_rom_font                    ; ensure crisp readable font
    xor a
    call clear_screen_attrs              ; full black wipe (paper black, ink black)
    ; Prime type_engine pointing at intro_text.
    ld hl, intro_text
    ld (type_ptr), hl
    ld a, INTRO_START_COL
    ld (type_start_col), a
    ld (type_col), a
    ld a, INTRO_START_ROW
    ld (type_row), a
    xor a
    ld (type_timer), a
    ; Paint the readable band cyan-on-black so typed chars are visible.
    ld d, INTRO_START_ROW
    ld e, 12                             ; 12 rows of text area
.intr_attr_lp:
    push de
    ld b, 0
    ld e, 32
    ld a, INTRO_ATTR
    call set_row_attrs
    pop de
    inc d
    dec e
    jr nz, .intr_attr_lp
    ld a, 1
    ld (intro_phase), a
    ret

.intr_p1:
    ; SFX subsystem isn't ticked by ay_tick_music when music_mode=0
    ; (intro is silent otherwise), so drive the SFX timer here so
    ; each typewriter blip mutes itself after ~40 ms.
    call ay_tick_sfx
    ; Let the user skip the whole intro with any key.
    call read_any_key
    or a
    jr nz, .intr_skip
    ; Detect "about to print a real character this frame" so the
    ; typewriter click lines up with the character reveal:
    ;   type_timer == 0        -> type_engine will process next byte
    ;   (type_ptr) >= 2        -> that byte is a printable char
    ;                             (0 = end of string, 1 = newline)
    ld a, (type_timer)
    or a
    jr nz, .intr_no_blip
    ld hl, (type_ptr)
    ld a, (hl)
    cp 2
    jr c, .intr_no_blip
    ld a, SFX_TYPE
    call ay_play_sfx
.intr_no_blip:
    ld a, INTRO_TYPE_DELAY
    call type_engine
    ret nz                                ; still typing
    ; Type engine hit the null terminator — enter hold phase.
    ld hl, INTRO_HOLD_FRAMES
    ld (intro_hold), hl
    ld a, 2
    ld (intro_phase), a
    ret

.intr_p2:
    call read_any_key
    or a
    jr nz, .intr_skip
    ld hl, (intro_hold)
    dec hl
    ld (intro_hold), hl
    ld a, h
    or l
    ret nz

.intr_skip:
    ld a, 3
    ld (intro_phase), a
    ret

; The 6912-byte SCR data is included directly
title_scr_data:
    INCBIN "title.scr"
