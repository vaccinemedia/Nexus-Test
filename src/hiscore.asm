; hiscore.asm — High score display, attract mode, and initial entry

; ===============================================================
; ST_HISCORE frame handler
; Two modes: display (attract) or entry (after game over)
; ===============================================================
hiscore_frame:
    ld a, (hiscore_entry_mode)
    or a
    jp nz, hiscore_entry_frame

    ; --- Display mode (attract) ---
    ld a, (screen_drawn)
    or a
    jp nz, .hs_tick

    ; Draw the high score screen
    call draw_hiscore_screen
    ld a, 1
    ld (screen_drawn), a
    ld hl, 0
    ld (attract_timer), hl

.hs_tick:
    call ay_tick_music

    ; Increment attract timer
    ld hl, (attract_timer)
    inc hl
    ld (attract_timer), hl
    ; Check if 500 frames (10 seconds) elapsed
    ld a, h
    cp 1               ; 256+ frames
    jr c, .hs_check_key
    ld a, l
    cp 244             ; 1*256+244 = 500
    jr c, .hs_check_key
    ; Time's up: switch back to title
    xor a
    ld (screen_drawn), a
    ld (game_state), a  ; ST_TITLE = 0
    ret

.hs_check_key:
    call read_any_key
    or a
    ret z
    ; Key pressed: start a new game
    call ay_mute
    xor a
    ld (screen_drawn), a
    call start_new_game
    ret

; ===============================================================
; Draw high score table screen
; ===============================================================
draw_hiscore_screen:
    ld a, INK_CYAN + (INK_BLACK*8)
    call clear_screen_attrs

    ; Title "HIGH SCORES" in custom font
    call use_custom_font
    ld a, 10
    ld (pr_col), a
    ld a, 2
    ld (pr_row), a
    ld hl, str_hiscore_hd
    call print_str
    ld d, 2
    ld b, 10
    ld e, 11
    ld a, ATTR_TITLE
    call set_row_attrs
    call use_rom_font

    ; Column headers
    ld a, 4
    ld (pr_col), a
    ld a, 4
    ld (pr_row), a
    ld hl, str_rank
    call print_str
    ld d, 4
    ld b, 4
    ld e, 24
    ld a, ATTR_STATUS
    call set_row_attrs

    ; Draw 10 entries
    ld c, 0             ; entry index
.dhs_loop:
    ld a, c
    cp HISCORE_ENTRIES
    ret nc
    push bc

    ; Row = 6 + index
    ld a, c
    add a, 6
    ld (pr_row), a
    ld (dhs_row), a

    ; Print rank: index + 1
    ld a, 5
    ld (pr_col), a
    pop bc
    push bc
    ld a, c
    inc a
    call print_num
    ; Print "."
    ld a, (pr_col)
    ld (pr_col), a
    ld hl, str_dot
    call print_str

    ; Get entry pointer: hiscore_table + index * 5
    pop bc
    push bc
    ld a, c
    ld l, a
    ld h, 0
    add hl, hl
    add hl, hl
    add hl, hl          ; *8... no, need *5
    ; Redo: HL = c * 5
    pop bc
    push bc
    ld a, c
    ld l, a
    ld h, 0
    ld d, h
    ld e, l
    add hl, hl
    add hl, hl
    add hl, de           ; HL = c * 5
    ld de, hiscore_table
    add hl, de           ; HL = entry pointer

    ; Print 3-char initials
    ld a, 10
    ld (pr_col), a
    push hl
    ld a, (hl)
    ld c, a
    call print_char
    ld hl, pr_col
    inc (hl)
    pop hl
    inc hl
    push hl
    ld a, (hl)
    ld c, a
    call print_char
    ld hl, pr_col
    inc (hl)
    pop hl
    inc hl
    push hl
    ld a, (hl)
    ld c, a
    call print_char
    ld hl, pr_col
    inc (hl)
    pop hl
    inc hl

    ; Print score (16-bit LE)
    ld a, 17
    ld (pr_col), a
    ld e, (hl)
    inc hl
    ld d, (hl)
    ex de, hl            ; HL = score
    call print_num16

    ; Set row attrs
    ld a, (dhs_row)
    ld d, a
    ld b, 4
    ld e, 24
    ld a, ATTR_HISCORE
    call set_row_attrs

    pop bc
    inc c
    jp .dhs_loop

dhs_row: db 0
hef_keys_released: db 0

; ===============================================================
; Check if total_score qualifies for high score table
; Sets hiscore_new_pos to position (0-9) or #FF if doesn't qualify
; ===============================================================
check_hiscore:
    ld c, 0             ; index
    ld ix, hiscore_table
.chs_loop:
    ld a, c
    cp HISCORE_ENTRIES
    jr nc, .chs_no
    ; Get score at this position (offset 3-4 in entry)
    ld l, (ix+3)
    ld h, (ix+4)
    ; Compare total_score > entry score
    ld de, (total_score)
    ; If DE > HL, we qualify at this position
    ; Compare: DE - HL
    ld a, e
    sub l
    ld a, d
    sbc a, h
    jr c, .chs_next      ; total_score < entry, try next
    ; total_score >= entry score: qualify here
    ld a, c
    ld (hiscore_new_pos), a
    ret
.chs_next:
    ld de, HISCORE_ENTRY_SZ
    add ix, de
    inc c
    jr .chs_loop
.chs_no:
    ld a, #FF
    ld (hiscore_new_pos), a
    ret

; ===============================================================
; Insert new high score at hiscore_new_pos
; Shifts entries down, writes initials and score
; ===============================================================
insert_hiscore:
    ; Shift entries down: 8->9, 7->8, ..., pos->pos+1
    ; Entry 9 (last) is discarded; start from entry 8 (not 9!)
    ld a, (hiscore_new_pos)
    ld c, a
    ld b, HISCORE_ENTRIES - 2   ; 8: last valid source index
.ihs_shift:
    ld a, b
    cp c
    jr c, .ihs_shift_done       ; B < C: done
    ; Copy entry B to entry B+1
    push bc
    ld a, b
    call get_hiscore_entry_ptr   ; HL = &table[B] (source)
    push hl                      ; save source ptr (get_hiscore_entry_ptr trashes DE)
    pop ix                       ; IX = source ptr
    pop bc
    push bc
    ld a, b
    inc a
    call get_hiscore_entry_ptr   ; HL = &table[B+1] (dest)
    ex de, hl                    ; DE = dest
    push ix
    pop hl                       ; HL = source (restored from IX)
    ld bc, HISCORE_ENTRY_SZ
    ldir
    pop bc
    ; Stop if B == C (just did the last shift needed)
    ld a, b
    cp c
    jr z, .ihs_shift_done
    dec b
    jr .ihs_shift

.ihs_shift_done:
    ; Write new entry at position
    ld a, (hiscore_new_pos)
    call get_hiscore_entry_ptr
    ; HL = entry pointer
    ; Write initials
    ld a, (hiscore_initials)
    ld (hl), a
    inc hl
    ld a, (hiscore_initials+1)
    ld (hl), a
    inc hl
    ld a, (hiscore_initials+2)
    ld (hl), a
    inc hl
    ; Write score (16-bit LE)
    ld a, (total_score)
    ld (hl), a
    inc hl
    ld a, (total_score+1)
    ld (hl), a
    ret

; Helper: A = entry index, returns HL = pointer to that entry
get_hiscore_entry_ptr:
    ld l, a
    ld h, 0
    ld d, h
    ld e, l
    add hl, hl
    add hl, hl
    add hl, de           ; HL = index * 5
    ld de, hiscore_table
    add hl, de
    ret

; ===============================================================
; High score entry mode: type 3 initials directly from keyboard
; ===============================================================
hiscore_entry_frame:
    ld a, (screen_drawn)
    or a
    jp nz, .hef_input

    ; Draw entry screen with custom font for headers
    call use_custom_font

    ld a, INK_WHITE + (INK_BLUE*8) + BRIGHT
    call clear_screen_attrs

    ld a, 8
    ld (pr_col), a
    ld a, 4
    ld (pr_row), a
    ld hl, str_new_hi
    call print_str

    ; Show score
    ld a, 12
    ld (pr_col), a
    ld a, 7
    ld (pr_row), a
    ld hl, (total_score)
    call print_num16

    ; "TYPE YOUR INITIALS"
    ld a, 7
    ld (pr_col), a
    ld a, 11
    ld (pr_row), a
    ld hl, str_enter_init
    call print_str

    ; "ENTER=OK  0=DELETE"
    ld a, 7
    ld (pr_col), a
    ld a, 18
    ld (pr_row), a
    ld hl, str_hef_help
    call print_str

    call use_rom_font

    ; Init: 3 dots as placeholders
    xor a
    ld (hiscore_cursor), a
    ld a, '.'
    ld (hiscore_initials), a
    ld (hiscore_initials+1), a
    ld (hiscore_initials+2), a

    call draw_initial_entry

    ld a, 1
    ld (screen_drawn), a
    xor a
    ld (hef_keys_released), a
    ret

.hef_input:
    ; Wait for keys from previous screen to be released
    ld a, (hef_keys_released)
    or a
    jr nz, .hef_do_input

    call read_any_key
    or a
    ret nz
    ld a, 1
    ld (hef_keys_released), a
    xor a
    ld (letter_held), a
    ret

.hef_do_input:
    call scan_letter
    or a
    ret z

    cp 1                  ; ENTER = confirm
    jp z, .hef_confirm

    cp 2                  ; 0 key = delete last
    jr z, .hef_delete

    ; A-Z letter: store at cursor position and advance
    ld b, a
    ld a, (hiscore_cursor)
    cp 3
    ret nc                ; already have 3 letters
    ld e, a
    ld d, 0
    ld hl, hiscore_initials
    add hl, de
    ld (hl), b

    ; Advance cursor
    ld a, (hiscore_cursor)
    inc a
    ld (hiscore_cursor), a

    call draw_initial_entry

    ; Auto-confirm after 3rd letter
    ld a, (hiscore_cursor)
    cp 3
    jp z, .hef_auto_confirm
    ret

.hef_delete:
    ld a, (hiscore_cursor)
    or a
    ret z                 ; nothing to delete
    dec a
    ld (hiscore_cursor), a
    ld e, a
    ld d, 0
    ld hl, hiscore_initials
    add hl, de
    ld (hl), '.'

    call draw_initial_entry
    ret

.hef_auto_confirm:
    ; Brief pause so the player sees the 3rd letter
    ld b, 15
.hef_pause:
    halt
    djnz .hef_pause

.hef_confirm:
    ; Replace any remaining dots with spaces
    ld hl, hiscore_initials
    ld b, 3
.hef_fill:
    ld a, (hl)
    cp '.'
    jr nz, .hef_fill_ok
    ld (hl), ' '
.hef_fill_ok:
    inc hl
    djnz .hef_fill

    call insert_hiscore
    call ay_init_title
    xor a
    ld (screen_drawn), a
    ld (hiscore_entry_mode), a
    ld a, ST_HISCORE
    ld (game_state), a
    ret

; Draw the 3 initials with highlighted cursor position
draw_initial_entry:
    ld a, 14
    ld (pr_col), a
    ld a, 14
    ld (pr_row), a

    ld a, (hiscore_initials)
    ld c, a
    call print_char
    ld hl, pr_col
    inc (hl)
    inc (hl)
    ld a, (hiscore_initials+1)
    ld c, a
    call print_char
    ld hl, pr_col
    inc (hl)
    inc (hl)
    ld a, (hiscore_initials+2)
    ld c, a
    call print_char

    ; Set row attrs — all normal
    ld d, 14
    ld b, 14
    ld e, 7
    ld a, ATTR_HISCORE
    call set_row_attrs

    ; Highlight cursor position (if < 3)
    ld a, (hiscore_cursor)
    cp 3
    ret nc                ; all filled, no cursor
    add a, a              ; *2 for spacing
    add a, 14             ; base col
    ld b, a
    ld d, 14
    ld e, 1
    ld a, ATTR_HISCORE_HL
    jp set_row_attrs

; ===============================================================
; Start a new game — shared between title and hiscore screens
; ===============================================================
start_new_game:
    ; Seed RNG from refresh register
    ld a, r
    ld l, a
    ld a, r
    ld h, a
    ld a, h
    or l
    jr nz, .sng_seed_ok
    ld hl, #A55A
.sng_seed_ok:
    ld (rng_seed), hl

    ld a, 1
    ld (level_num), a
    ld a, STARTING_LIVES
    ld (lives), a
    ld hl, 0
    ld (total_score), hl

    ; Prepare subject for level 1
    call prepare_current_subject

    xor a
    ld (screen_drawn), a
    ld a, ST_LEVEL_INTRO
    ld (game_state), a
    ret
