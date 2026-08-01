; glitch.asm — Fourth-wall-break "Am I a Replicant?" system.
;
; Three tiers:
;   Tier 1: subtle glitch during interrogation (attr corruption in portrait).
;   Tier 2: ST_GLITCH_MED — screen wipe + typed Deckard monologue fragment.
;   Tier 3: ST_GLITCH_CRASH — full fake-crash sequence (attr scramble,
;           boot menu, BASIC prompt, CONTINUE? Y/N with deeper text on N).

; =================================================================
; check_glitch_trigger — called from level_intro_frame first frame.
; May divert game_state to ST_GLITCH_MED or ST_GLITCH_CRASH.
; Tier 1 is scheduled separately during interrogation.
; =================================================================
check_glitch_trigger:
    ld a, (level_num)
    ld b, a
    ld a, (glitch_done_3)
    or a
    jr nz, .cgt_check_med
    ld a, (glitch_level_3)
    cp b
    jr nz, .cgt_check_med
    ld a, 1
    ld (glitch_done_3), a
    ld a, ST_GLITCH_CRASH
    jr .cgt_go
.cgt_check_med:
    ld a, (glitch_done_2)
    or a
    ret nz
    ld a, (glitch_level_2)
    cp b
    ret nz
    ld a, 1
    ld (glitch_done_2), a
    ld a, ST_GLITCH_MED
.cgt_go:
    ld (game_state), a
    xor a
    ld (crash_phase), a
    ld (screen_drawn), a
    ld hl, 0
    ld (crash_timer), hl
    ret

; =================================================================
; schedule_subtle_glitch — called once when interrogation first draws.
; Never fires on the mirror level or a level not matching glitch_level_1.
; =================================================================
schedule_subtle_glitch:
    xor a
    ld (subtle_timer), a
    ld (subtle_state), a
    ld a, (is_mirror_level)
    or a
    ret nz
    ld a, (glitch_done_1)
    or a
    ret nz
    ld a, (level_num)
    ld b, a
    ld a, (glitch_level_1)
    cp b
    ret nz
    ld a, 1
    ld (glitch_done_1), a
    ; Delay 60..179 frames (1.2s..3.6s) before firing
    call rng_tick
    and #7f
    add a, 60
    ld (subtle_timer), a
    ; Pick a random effect kind 0..3:
    ;   0 = attr corruption
    ;   1 = pupil gauge spike
    ;   2 = ghost text word in the reply band
    ;   3 = border ripple (cycles for a few frames)
    call rng_tick
    and 3
    ld (subtle_kind), a
    ret

; =================================================================
; tick_subtle_glitch — called every interrogation frame.
; When the timer hits zero, dispatches to one of three effects.
; Some effects re-queue themselves (via subtle_state) to run a
; multi-frame animation (e.g. spike-then-restore).
; =================================================================
tick_subtle_glitch:
    ld a, (subtle_timer)
    or a
    ret z
    dec a
    ld (subtle_timer), a
    ret nz
    ; Timer just hit zero — dispatch on effect kind.
    ld a, (subtle_kind)
    or a
    jp z, subtle_attr_corrupt
    dec a
    jp z, subtle_gauge_spike
    dec a
    jp z, subtle_ghost_text
    jp subtle_border_ripple

; ----- Effect 0: portrait attribute corruption (single flash) -----
subtle_attr_corrupt:
    ld b, 12
.sac_lp:
    push bc
    call rng_tick
    push af
    call rng_tick
    and 7
    ld c, a
    call rng_tick
    and #0f
    cp PORTRAIT_H
    jr c, .sac_row_ok
    ld a, PORTRAIT_H - 1
.sac_row_ok:
    add a, PORTRAIT_ROW
    ld h, 0
    ld l, a
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    ld a, PORTRAIT_COL
    add a, c
    ld e, a
    ld d, 0
    add hl, de
    ld de, ATTR_BASE
    add hl, de
    pop af
    ld (hl), a
    pop bc
    djnz .sac_lp
    ; Redraw portrait cleanly next frame
    ld hl, (current_subj)
    jp draw_portrait

; ----- Effect 1: pupil gauge spikes to max then snaps back -----
; Two-phase: first hit paints the bar red-hi, second hit restores it.
subtle_gauge_spike:
    ld a, (subtle_state)
    or a
    jr nz, .sgs_restore
    ld d, PUPIL_ROW
    ld b, GAUGE_BAR_COL
    ld e, GAUGE_BAR_W
    ld a, ATTR_GAUGE_HI
    call set_row_attrs
    ; Re-queue for restoration after 10 frames
    ld a, 10
    ld (subtle_timer), a
    ld a, 1
    ld (subtle_state), a
    ret
.sgs_restore:
    ld a, (questions_asked)
    or a
    jp nz, draw_pupil_gauge
    ; No question yet: paint bar back to default cyan-black
    ld d, PUPIL_ROW
    ld b, GAUGE_BAR_COL
    ld e, GAUGE_BAR_W
    ld a, INK_CYAN + (INK_BLACK*8)
    jp set_row_attrs

; ----- Effect 2: ghost text (word appears in response area) -----
; Two-phase: first hit prints the word, second clears it.
subtle_ghost_text:
    ld a, (subtle_state)
    or a
    jr nz, .sgt_clear
    call rng_tick
    and 7
    add a, a
    ld e, a
    ld d, 0
    ld hl, ghost_words
    add hl, de
    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a                          ; HL = word pointer
    push hl
    ld a, RESPONSE_COL + 8
    ld (pr_col), a
    ld a, RESPONSE_REPLY_ROW
    ld (pr_row), a
    pop hl
    call print_str
    ld a, 40
    ld (subtle_timer), a
    ld a, 1
    ld (subtle_state), a
    ret
.sgt_clear:
    ld a, RESPONSE_COL + 8
    ld (pr_col), a
    ld a, RESPONSE_REPLY_ROW
    ld (pr_row), a
    ld b, 10
.sgt_clr_lp:
    push bc
    ld c, ' '
    call print_char
    ld hl, pr_col
    inc (hl)
    pop bc
    djnz .sgt_clr_lp
    ret

ghost_words:
    DW gw_dream
    DW gw_wake
    DW gw_real
    DW gw_run
    DW gw_help
    DW gw_liar
    DW gw_home
    DW gw_null
gw_dream: DB "DREAM?",0
gw_wake:  DB "WAKE UP",0
gw_real:  DB "ARE YOU?",0
gw_run:   DB "RUN.",0
gw_help:  DB "HELP ME",0
gw_liar:  DB "LIAR",0
gw_home:  DB "GO HOME",0
gw_null:  DB "NULL",0

; ----- Effect 3: border ripple (cycles border colour) -----
; Cycles border through 4 colours over 4 hits, then restores to
; black. subtle_state advances 0..4 on each firing.
subtle_border_ripple:
    ld a, (subtle_state)
    ld e, a
    ld d, 0
    ld hl, border_seq
    add hl, de
    ld a, (hl)
    out (#fe), a
    ld a, (subtle_state)
    inc a
    cp 5
    jr c, .sbr_more
    xor a
    ld (subtle_state), a
    ret
.sbr_more:
    ld (subtle_state), a
    ld a, 4
    ld (subtle_timer), a
    ret

border_seq:
    DB 2                             ; red
    DB 6                             ; yellow
    DB 4                             ; green
    DB 3                             ; magenta
    DB 0                             ; black — restore

; =================================================================
; Shared char-by-char typing engine used by glitch/mirror sequences.
; Reads (type_ptr) into (type_col, type_row) with (type_timer) as
; per-char delay. Byte value 1 in the string = newline (col resets
; to type_start_col, row increments).
;
; Call: A holds the "next-char" reload delay to set after printing.
; Returns Z if the line finished (null byte reached), NZ otherwise.
; =================================================================
type_engine:
    ld c, a                       ; save reload delay
    ld a, (type_timer)
    or a
    jr z, .te_do
    dec a
    ld (type_timer), a
    or 1                          ; force NZ (still typing)
    ret
.te_do:
    ld hl, (type_ptr)
    ld a, (hl)
    or a
    ret z                         ; end of string
    cp 1
    jr z, .te_nl
    push hl
    ld a, (type_col)
    ld (pr_col), a
    ld a, (type_row)
    ld (pr_row), a
    pop hl
    push hl
    ld a, (hl)
    push bc                       ; preserve reload delay
    ld c, a
    call print_char
    pop bc
    pop hl
    ld a, (type_col)
    inc a
    ld (type_col), a
    inc hl
    ld (type_ptr), hl
    ld a, c
    ld (type_timer), a
    or 1
    ret
.te_nl:
    ld a, (type_start_col)
    ld (type_col), a
    ld a, (type_row)
    inc a
    ld (type_row), a
    inc hl
    ld (type_ptr), hl
    ld a, c
    ld (type_timer), a
    or 1
    ret

; =================================================================
; ST_GLITCH_MED — mid-tier glitch. Blank screen + typed Deckard
; monologue fragment, then returns to level intro.
; =================================================================
; --------------------------------------------------------------
; glitch_med_frame — reads deckard_fragments (bank 5 @ #6900+).
; All string data is in bank 5 (always mapped), so no paging is
; needed here.
; --------------------------------------------------------------
glitch_med_frame:
    ld a, (crash_phase)
    or a
    jr z, gm_init
    cp 1
    jr z, gm_type
    cp 2
    jr z, gm_hold
    ; Phase 3 = exit
    xor a
    ld (screen_drawn), a
    ld a, ST_LEVEL_INTRO
    ld (game_state), a
    ret

gm_init:
    ld a, INK_RED + (INK_BLACK*8) + BRIGHT
    call clear_screen_attrs
    ; Pick one of three Deckard monologue fragments at random
    call rng_tick
    and 3
    cp 3
    jr c, .gmi_frag_ok
    xor a
.gmi_frag_ok:
    add a, a                      ; *2 for pointer table
    ld e, a
    ld d, 0
    ld hl, deckard_fragments
    add hl, de
    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a                       ; HL = fragment pointer
    ld (type_ptr), hl
    ld a, 4
    ld (type_start_col), a
    ld (type_col), a
    ld a, 6
    ld (type_row), a
    xor a
    ld (type_timer), a
    ld a, 1
    ld (crash_phase), a
    ret

gm_type:
    ld a, 4
    call type_engine
    ret nz
    ; Finished — hold
    ld hl, 90
    ld (crash_timer), hl
    ld a, 2
    ld (crash_phase), a
    ret

gm_hold:
    ld hl, (crash_timer)
    dec hl
    ld (crash_timer), hl
    ld a, h
    or l
    ret nz
    ld a, 3
    ld (crash_phase), a
    ret

; deckard_fragments (+ frag_1/2/3) live in bank 5 at #6900+, see nexus.asm.

; =================================================================
; ST_GLITCH_CRASH — full fake-crash sequence.
; Compact phase dispatcher.
; =================================================================
; --------------------------------------------------------------
; glitch_crash_frame — reads boot_menu_lines, basic_listing,
; deeper_text (all in bank 5 @ #6900+, always mapped).
; --------------------------------------------------------------
glitch_crash_frame:
    ld a, (crash_phase)
    add a, a
    ld e, a
    ld d, 0
    ld hl, gc_dispatch
    add hl, de
    ld e, (hl)
    inc hl
    ld d, (hl)
    ex de, hl
    jp (hl)

gc_dispatch:
    DW gc_p0                     ; init scramble
    DW gc_p1                     ; scramble tick
    DW gc_p2                     ; black hold
    DW gc_p3                     ; cursor move
    DW gc_p4                     ; select pause + clear
    DW gc_p5                     ; copyright + prep BASIC
    DW gc_p6                     ; type BASIC listing
    DW gc_p7                     ; wait Y/N
    DW gc_p8                     ; type deeper text (if N)
    DW gc_p9                     ; hold deeper
    DW gc_p10                    ; exit

gc_p0:
    call ay_mute
    ld hl, 25
    ld (crash_timer), hl
    ld a, 1
    ld (crash_phase), a
    ret

gc_p1:
    ; Randomise attr bytes across all 3 attr pages
    ld b, 48
.gcp1_lp:
    push bc
    call rng_tick
    ld c, a
    call rng_tick
    ld l, a
    call rng_tick
    and 3
    cp 3
    jr c, .gcp1_ok
    xor a
.gcp1_ok:
    add a, #58
    ld h, a
    ld (hl), c
    pop bc
    djnz .gcp1_lp
    ld hl, (crash_timer)
    dec hl
    ld (crash_timer), hl
    ld a, h
    or l
    ret nz
    xor a
    call clear_screen_attrs
    ld hl, 50
    ld (crash_timer), hl
    ld a, 2
    ld (crash_phase), a
    ret

gc_p2:
    ld hl, (crash_timer)
    dec hl
    ld (crash_timer), hl
    ld a, h
    or l
    ret nz
    call gc_draw_boot_menu
    ld hl, 30
    ld (crash_timer), hl
    xor a
    ld (type_row), a             ; cursor index into menu
    ld a, 3
    ld (crash_phase), a
    ret

gc_p3:
    ld hl, (crash_timer)
    dec hl
    ld (crash_timer), hl
    ld a, h
    or l
    ret nz
    ld a, (type_row)
    inc a
    ld (type_row), a
    cp 2
    jr nc, .gcp3_done
    ; Highlight moves from row 6 to row 7 (Tape Loader → 128 BASIC)
    ld d, 6
    ld b, 11
    ld e, 11
    ld a, INK_WHITE + (INK_BLACK*8) + BRIGHT
    call set_row_attrs
    ld d, 7
    ld b, 11
    ld e, 11
    ld a, INK_WHITE + (INK_BLUE*8) + BRIGHT
    call set_row_attrs
    ld hl, 25
    ld (crash_timer), hl
    ret
.gcp3_done:
    ld hl, 20
    ld (crash_timer), hl
    ld a, 4
    ld (crash_phase), a
    ret

gc_p4:
    ld hl, (crash_timer)
    dec hl
    ld (crash_timer), hl
    ld a, h
    or l
    ret nz
    ld a, INK_WHITE + (INK_BLACK*8)
    call clear_screen_attrs
    ld a, 5
    ld (crash_phase), a
    ret

gc_p5:
    xor a
    ld (pr_col), a
    ld (pr_row), a
    ld hl, str_bas_copy
    call print_str
    xor a
    ld (pr_col), a
    ld a, 1
    ld (pr_row), a
    ld hl, str_bas_ok
    call print_str
    ld hl, basic_listing
    ld (type_ptr), hl
    xor a
    ld (type_start_col), a
    ld (type_col), a
    ld a, 3
    ld (type_row), a
    ld a, 6
    ld (type_timer), a
    ld a, 6
    ld (crash_phase), a
    ret

gc_p6:
    ld a, 6
    call type_engine
    ret nz
    ; Listing done — show CONTINUE? prompt
    ld a, (type_row)
    inc a
    ld (type_row), a
    xor a
    ld (pr_col), a
    ld a, (type_row)
    ld (pr_row), a
    ld hl, str_continue_q
    call print_str
    ld a, 7
    ld (crash_phase), a
    ret

gc_p7:
    ; Y = row #DF bit 4; N = row #7F bit 3
    ld a, #df
    in a, (#fe)
    bit 4, a
    jr nz, .gcp7_check_n
    ; Y — resume gameplay
    ld hl, 25
    ld (crash_timer), hl
    ld a, 10
    ld (crash_phase), a
    ret
.gcp7_check_n:
    ld a, #7f
    in a, (#fe)
    bit 3, a
    ret nz
    ; N — begin deeper text
    ld a, (type_row)
    ld (pr_row), a
    xor a
    ld (pr_col), a
    ld b, 32
.gcp7_clr:
    push bc
    ld c, ' '
    call print_char
    ld hl, pr_col
    inc (hl)
    pop bc
    djnz .gcp7_clr
    ld hl, deeper_text
    ld (type_ptr), hl
    xor a
    ld (type_start_col), a
    ld (type_col), a
    ld a, 5
    ld (type_timer), a
    ; Red-on-black band for the deeper text (5 rows: 8..12)
    ld d, 8
.gcp7_attr:
    push de
    ld b, 0
    ld e, 32
    ld a, INK_RED + (INK_BLACK*8) + BRIGHT
    call set_row_attrs
    pop de
    inc d
    ld a, d
    cp 13
    jr c, .gcp7_attr
    ld a, 8
    ld (crash_phase), a
    ret

gc_p8:
    ld a, 5
    call type_engine
    ret nz
    ld hl, 150
    ld (crash_timer), hl
    ld a, 9
    ld (crash_phase), a
    ret

gc_p9:
    ld hl, (crash_timer)
    dec hl
    ld (crash_timer), hl
    ld a, h
    or l
    ret nz
    ld hl, 25                    ; reset for gc_p10's exit countdown
    ld (crash_timer), hl
    ld a, 10
    ld (crash_phase), a
    ret

gc_p10:
    ld hl, (crash_timer)
    dec hl
    ld (crash_timer), hl
    ld a, h
    or l
    ret nz
    call ay_init_ambient
    xor a
    ld (screen_drawn), a
    ld a, ST_LEVEL_INTRO
    ld (game_state), a
    ret

; -------- Boot menu drawing --------
; Full 128 boot menu recreation: "128" banner with rainbow strip, then
; five menu items rows 6-10. Highlight starts on "Tape Loader".
gc_draw_boot_menu:
    ld a, INK_BLACK + (INK_WHITE*8)
    call clear_screen_attrs
    ; Iterate through boot_menu_lines: null-terminated strings, one per row.
    ; A leading empty string (single null byte) marks the end of the table.
    ld hl, boot_menu_lines
    ld d, 5
.gdbm_lp:
    ld a, (hl)
    or a
    jr z, .gdbm_end
    push de
    ld a, 11
    ld (pr_col), a
    ld a, d
    ld (pr_row), a
    call print_str                 ; HL left pointing at the null terminator
    inc hl                         ; advance to next string
    pop de
    inc d
    jr .gdbm_lp
.gdbm_end:
    ; Rainbow strip across the "128" title row (green/yellow/red/magenta)
    ld d, 5
    ld b, 15
    ld e, 2
    ld a, INK_GREEN + (INK_GREEN*8) + BRIGHT
    call set_row_attrs
    ld d, 5
    ld b, 17
    ld e, 2
    ld a, INK_YELLOW + (INK_YELLOW*8) + BRIGHT
    call set_row_attrs
    ld d, 5
    ld b, 19
    ld e, 2
    ld a, INK_RED + (INK_RED*8) + BRIGHT
    call set_row_attrs
    ld d, 5
    ld b, 21
    ld e, 2
    ld a, INK_MAG + (INK_MAG*8) + BRIGHT
    call set_row_attrs
    ; Highlight the first menu item ("Tape Loader") as initial selection
    ld d, 6
    ld b, 11
    ld e, 11
    ld a, INK_WHITE + (INK_BLUE*8) + BRIGHT
    jp set_row_attrs

; boot_menu_lines, basic_listing, deeper_text live in bank 5 at
; #6900+ (always mapped alongside the samples). See nexus.asm.

str_bas_copy:    DB "(C) 1986 Sinclair Research Ltd",0
str_bas_ok:      DB "0 OK, 0:1",0

str_continue_q:  DB "CONTINUE? (Y/N)",0
