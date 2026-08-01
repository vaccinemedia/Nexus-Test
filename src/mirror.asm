; mirror.asm — Level 25 "You are the subject".
; Rick Deckard sits opposite himself. Icon labels become Batty
; monologue fragments; the gauges auto-run; the verdict is not
; revealed — screen fades to black over the tears-in-rain lines.

; =================================================================
; mirror_setup_subject — patches current_subject to be Rick Deckard.
; Also swaps the icon label pointer to the mirror set.
; =================================================================
mirror_setup_subject:
    ld hl, current_subject
    ld (hl), TYPE_MIRROR
    inc hl
    ld (hl), 60                  ; empathy
    inc hl
    ld (hl), 40                  ; aggression
    inc hl
    ld (hl), 30                  ; stability
    inc hl
    ld (hl), 55                  ; deception
    inc hl
    ld (hl), 5                   ; difficulty (D5)
    inc hl
    ld (hl), #DE
    inc hl
    ld (hl), #CA
    inc hl
    ld de, mirror_name
    ld (hl), e
    inc hl
    ld (hl), d
    ld hl, mirror_labels
    ld (active_labels_ptr), hl
    xor a
    ld (mirror_ask_idx), a
    ld (mirror_ask_count), a             ; reset the unlock counter
    ret

; =================================================================
; mirror_apply_interrogation — called after draw_interrogation.
; Overwrites the reply band with a Deckard-facing header and primes
; auto-running gauges.
; =================================================================
mirror_apply_interrogation:
    ld a, RESPONSE_COL
    ld (pr_col), a
    ld a, RESPONSE_ROW
    ld (pr_row), a
    ld hl, str_mirror_intro1
    call print_str
    ld a, RESPONSE_COL
    ld (pr_col), a
    ld a, RESPONSE_ROW + 1
    ld (pr_row), a
    ld hl, str_mirror_intro2
    call print_str
    ld d, RESPONSE_ROW
    ld b, RESPONSE_COL
    ld e, RESPONSE_W
    ld a, INK_CYAN + (INK_BLACK*8) + BRIGHT
    call set_row_attrs
    ld d, RESPONSE_ROW + 1
    ld b, RESPONSE_COL
    ld e, RESPONSE_W
    ld a, INK_RED + (INK_BLACK*8) + BRIGHT
    call set_row_attrs
    ld a, 4
    ld (pupil_gauge), a
    ld a, 3
    ld (flush_gauge), a
    ld a, 1
    ld (questions_asked), a
    call draw_pupil_gauge
    call draw_flush_gauge
    ld a, PAT_ERRATIC
    ld (pattern_flag), a
    call draw_pattern_label
    ld a, 30
    ld (mirror_gauge_t), a
    ret

; =================================================================
; mirror_tick_gauges — each frame, drift the pupil/flush gauges.
; Random walk biased upward, clamped to [0..GAUGE_BAR_W].
; =================================================================
mirror_tick_gauges:
    ld a, (mirror_gauge_t)
    dec a
    ld (mirror_gauge_t), a
    or a
    ret nz
    ld a, 6
    ld (mirror_gauge_t), a
    call rng_tick
    and 7
    sub 3
    ld hl, pupil_gauge
    add a, (hl)
    jr nc, .mtg_p_ok
    xor a
.mtg_p_ok:
    cp GAUGE_BAR_W + 1
    jr c, .mtg_p_store
    ld a, GAUGE_BAR_W
.mtg_p_store:
    ld (hl), a
    call rng_tick
    and 7
    sub 3
    ld hl, flush_gauge
    add a, (hl)
    jr nc, .mtg_f_ok
    xor a
.mtg_f_ok:
    cp GAUGE_BAR_W + 1
    jr c, .mtg_f_store
    ld a, GAUGE_BAR_W
.mtg_f_store:
    ld (hl), a
    call draw_pupil_gauge
    jp draw_flush_gauge

; =================================================================
; ST_MIRROR_END — full Batty "tears in rain" monologue.
;
; Data-driven: mirror_lines (bank 3) is a table of 8-byte records.
; The state machine iterates through them, honouring per-line hold,
; column, row, and attribute values. Bank 3 is paged in for the
; entire frame and swapped back to bank 0 before returning.
;
; Record layout (mirror_lines, 8 bytes):
;   +0  DW text_ptr        (0 = end of table)
;   +2  DB col
;   +3  DB row
;   +4  DW hold_before      (frames of silence before typing)
;   +6  DB attr
;   +7  DB reserved
;
; Phase 0: init (mute, clear, reset index, initial hold).
; Phase 1: fetch next line record; if end marker, go to fade.
; Phase 2: honour per-line hold, then prep the line.
; Phase 3: type the line, then start post-line hold.
; Phase 4: honour post-line hold, then advance to next line.
; Phase 5: row-by-row fade to black.
; Phase 6: final hold.
; Phase 7: exit to gameover.
; =================================================================
mirror_end_frame:
    call ay_tick_music                   ; drive the outro voices (mode 3)
    ld a, (mirror_phase)
    add a, a
    ld e, a
    ld d, 0
    ld hl, mirror_dispatch
    add hl, de
    ld e, (hl)
    inc hl
    ld d, (hl)
    ex de, hl
    jp (hl)

mirror_dispatch:
    DW me_p0
    DW me_p1
    DW me_p2
    DW me_p3
    DW me_p4
    DW me_p5
    DW me_p6
    DW me_p7

me_p0:
    call ay_init_outro                   ; start the Vangelis-style pad
    xor a
    call clear_screen_attrs
    ld (mirror_line_idx), a
    ld a, 1
    ld (mirror_phase), a
    ret

; Fetch mirror_lines[mirror_line_idx] into mirror_line_ptr. If the
; text pointer is 0, jump to fade. Otherwise queue hold_before.
;
; Branching: at the top of the extended coda (index MIRROR_EXTENDED_
; START), if the player hasn't asked the mirror enough times, we skip
; the four Deckard-reflection records and jump straight to "TIME TO
; DIE". Engaged players who invoked ASK >= MIRROR_ASK_UNLOCK times
; earn the fuller ending.
me_p1:
    ld a, (mirror_line_idx)
    cp MIRROR_EXTENDED_START
    jr nz, .mp1_load
    ld a, (mirror_ask_count)
    cp MIRROR_ASK_UNLOCK
    jr nc, .mp1_load                     ; unlocked; play the extended lines
    ld a, MIRROR_EXTENDED_END
    ld (mirror_line_idx), a              ; skip to "TIME TO DIE" record
.mp1_load:
    call me_load_line
    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a                              ; HL = text pointer
    ld a, h
    or l
    jr z, .mp1_end
    ; Not end — record ptr and hold value, advance phase
    ld (mirror_line_ptr), hl
    call me_load_hold                    ; loads mirror_timer from record
    ld a, 2
    ld (mirror_phase), a
    ret
.mp1_end:
    ; End of monologue — begin fade
    xor a
    ld (type_row), a
    ld a, 4
    ld (type_timer), a
    ld a, 5
    ld (mirror_phase), a
    ret

; Honour hold-before-line, then paint attr row + prep type_engine.
me_p2:
    call me_tick_timer
    ret nz
    call me_load_line                    ; HL = record start
    inc hl
    inc hl                               ; HL = +2 (col)
    ld a, (hl)
    ld (type_start_col), a
    ld (type_col), a
    inc hl                               ; HL = +3 (row)
    ld a, (hl)
    ld (type_row), a
    ld d, a                              ; D = row for set_row_attrs
    inc hl
    inc hl
    inc hl                               ; HL = +6 (attr)
    ld a, (hl)                           ; A = attr
    ld b, 0                              ; col=0 for attr paint
    ld e, 32
    call set_row_attrs
    ld hl, (mirror_line_ptr)
    ld (type_ptr), hl
    xor a
    ld (type_timer), a
    ld a, 3
    ld (mirror_phase), a
    ret

; Type this line. On completion, queue a post-line hold.
me_p3:
    ld a, 4
    call type_engine
    ret nz
    ld hl, 90
    ld (mirror_timer), hl
    ld a, 4
    ld (mirror_phase), a
    ret

; Post-line hold, then advance index and loop to fetch next line.
me_p4:
    call me_tick_timer
    ret nz
    ld a, (mirror_line_idx)
    inc a
    ld (mirror_line_idx), a
    ld a, 1
    ld (mirror_phase), a
    ret

; Row-by-row fade to black.
me_p5:
    ld a, (type_timer)
    or a
    jr z, .mp5_go
    dec a
    ld (type_timer), a
    ret
.mp5_go:
    ld a, (type_row)
    cp 24
    jr nc, .mp5_done
    ld d, a
    ld b, 0
    ld e, 32
    xor a
    call set_row_attrs
    ld a, (type_row)
    inc a
    ld (type_row), a
    ld a, 4
    ld (type_timer), a
    ret
.mp5_done:
    ld hl, 60
    ld (mirror_timer), hl
    ld a, 6
    ld (mirror_phase), a
    ret

me_p6:
    call me_tick_timer
    ret nz
    ld a, 7
    ld (mirror_phase), a
    ret

me_p7:
    call ay_mute                         ; kill outro voices
    xor a
    ld (music_mode), a                   ; back to silence until title/ambient reset
    call use_rom_font
    ld (screen_drawn), a
    ld (is_mirror_level), a
    ld hl, icon_labels
    ld (active_labels_ptr), hl
    ld a, ST_GAMEOVER
    ld (game_state), a
    ret

; Compute HL = &mirror_lines[mirror_line_idx * 8]. Preserves DE, BC.
me_load_line:
    ld a, (mirror_line_idx)
    ld l, a
    ld h, 0
    add hl, hl                           ; *2
    add hl, hl                           ; *4
    add hl, hl                           ; *8
    ld de, mirror_lines
    add hl, de
    ret

; Load record[+4..+5] (hold_before) into mirror_timer.
me_load_hold:
    call me_load_line
    ld de, 4
    add hl, de
    ld e, (hl)
    inc hl
    ld d, (hl)
    ld (mirror_timer), de
    ret

; Countdown helper: returns Z when timer reaches zero, NZ still running.
me_tick_timer:
    ld hl, (mirror_timer)
    dec hl
    ld (mirror_timer), hl
    ld a, h
    or l
    ret

; =================================================================
; mirror_ask_response — mirror-level ASK handler.
;
; Doesn't run the Voight-Kampff engine; instead, prints one of a
; rotating set of Deckard self-doubt fragments in the response reply
; band. Rotates via mirror_ask_idx so the player sees each one in
; sequence before repeating. Clears the queued icons afterwards.
; Pages bank 3 in to read the fragments, restores bank 0 on exit.
; =================================================================
mirror_ask_response:
    ld a, SFX_ASK
    call ay_play_sfx

    ; Bump the ASK counter (saturates at 255) so me_p1 can decide
    ; whether to unlock the extended monologue coda when the mirror
    ; interrogation ends.
    ld a, (mirror_ask_count)
    inc a
    jr z, .mar_no_bump                    ; already 255; leave saturated
    ld (mirror_ask_count), a
.mar_no_bump:

    ; Wipe the reply band before writing.
    ld d, RESPONSE_REPLY_ROW
    ld b, RESPONSE_COL
    ld e, RESPONSE_W
    ld a, INK_WHITE + (INK_BLACK*8) + BRIGHT
    call set_row_attrs

    ld a, RESPONSE_COL
    ld (pr_col), a
    ld a, RESPONSE_REPLY_ROW
    ld (pr_row), a
    ld b, RESPONSE_W
.mar_clr:
    push bc
    ld c, ' '
    call print_char
    ld hl, pr_col
    inc (hl)
    pop bc
    djnz .mar_clr

    ; Look up the current fragment (strings live in bank 5, always mapped).
    ld a, (mirror_ask_idx)
    ld b, a
    inc a
    cp MIRROR_ASK_COUNT
    jr c, .mar_ok
    xor a
.mar_ok:
    ld (mirror_ask_idx), a
    ld l, b
    ld h, 0
    add hl, hl
    ld de, mirror_ask_lines
    add hl, de
    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a                              ; HL = fragment pointer

    ; Print into the reply band via the paragraph printer (word-wraps).
    push hl
    ld a, RESPONSE_COL
    ld (pr_col), a
    ld a, RESPONSE_REPLY_ROW
    ld (pr_row), a
    ld a, RESPONSE_W
    ld (box_width), a
    pop hl
    call print_str_box

    ; Clear queued icons and refresh the icon grid so Deckard has to
    ; pick another set to trigger the next fragment.
    xor a
    ld (query_count), a
    ld a, ICON_NONE
    ld (query_icons), a
    ld (query_icons+1), a
    ld (query_icons+2), a
    call draw_icon_grid_attrs
    call highlight_cursor
    jp draw_query_strip

; -------- Data --------
mirror_name: DB "RICK DECKARD",0

str_mirror_intro1: DB "SUBJECT: DECKARD, R.",0
str_mirror_intro2: DB "STATUS: UNDETERMINED",0

; Icon labels for level 25 — Batty monologue words on a 4x4 grid.
mirror_labels:
    DW ml_0, ml_1, ml_2, ml_3
    DW ml_4, ml_5, ml_6, ml_7
    DW ml_8, ml_9, ml_10, ml_11
    DW ml_12, ml_13, ml_14, ml_15
ml_0:  DB "TIME",0
ml_1:  DB "TO",0
ml_2:  DB "DIE",0
ml_3:  DB "TEARS",0
ml_4:  DB "IN",0
ml_5:  DB "RAIN",0
ml_6:  DB "LOST",0
ml_7:  DB "LIKE",0
ml_8:  DB "MOMENTS",0
ml_9:  DB "GONE",0
ml_10: DB "C-BEAMS",0
ml_11: DB "GATE",0
ml_12: DB "SHOULDR",0
ml_13: DB "ORION",0
ml_14: DB "DARK",0
ml_15: DB "END",0
