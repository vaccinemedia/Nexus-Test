; game.asm — All in-game states: level intro, interrogation, verdict, result, gameover

; ===============================================================
; ST_LEVEL_INTRO — brief screen showing subject number and name
; ===============================================================
level_intro_frame:
    ld a, (screen_drawn)
    or a
    jp nz, .li_wait

    call use_custom_font

    ld a, INK_CYAN + (INK_BLACK*8) + BRIGHT
    call clear_screen_attrs

    ; "SUBJECT X OF 5"
    ld a, 10
    ld (pr_col), a
    ld a, 8
    ld (pr_row), a
    ld hl, str_subject
    call print_str
    ld a, (pr_col)
    inc a
    ld (pr_col), a
    ld a, (level_num)
    call print_num
    ld a, (pr_col)
    inc a
    ld (pr_col), a
    ld hl, str_of
    call print_str

    ; Subject name on next line
    ld a, (level_num)
    call get_subject_ptr
    ld de, SUBJ_NAME
    add hl, de
    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a             ; HL = name string pointer
    ld a, 11
    ld (pr_col), a
    ld a, 11
    ld (pr_row), a
    call print_str

    ld a, INTRO_DELAY
    ld (intro_timer), a
    ld a, 1
    ld (screen_drawn), a

.li_wait:
    ld a, (intro_timer)
    or a
    jr z, .li_go
    dec a
    ld (intro_timer), a
    ret
.li_go:
    ; Restore ROM font for gameplay
    call use_rom_font
    ; Init interrogation state
    xor a
    ld (screen_drawn), a
    ld (questions_asked), a
    ld (query_count), a
    ld (cursor_x), a
    ld (cursor_y), a
    ld (key_held), a
    ld (pupil_gauge), a
    ld (flush_gauge), a
    ld (pattern_flag), a
    ld (blink_timer), a
    ld a, ICON_NONE
    ld (query_icons), a
    ld (query_icons+1), a
    ld (query_icons+2), a
    ; Clear prev gauge history
    xor a
    ld (prev_pupil), a
    ld (prev_pupil+1), a
    ld (prev_pupil+2), a
    ld (prev_flush), a
    ld (prev_flush+1), a
    ld (prev_flush+2), a
    ; Set current_subj pointer
    ld a, (level_num)
    call get_subject_ptr
    ld (current_subj), hl
    ; Init ambient music
    call ay_init_ambient
    ld a, ST_INTERROGATION
    ld (game_state), a
    ret

intro_timer: db 0

; ===============================================================
; ST_INTERROGATION — main gameplay
; ===============================================================
interrogation_frame:
    ld a, (screen_drawn)
    or a
    jp nz, .int_input
    call draw_interrogation
    ld a, 1
    ld (screen_drawn), a

.int_input:
    call ay_tick_music

    ; Handle pupil blink countdown
    ld a, (blink_timer)
    or a
    jr z, .int_no_blink
    dec a
    ld (blink_timer), a
    or a
    call z, restore_eye_attr
.int_no_blink:

    call read_game_key
    or a
    ret z

    ; Dispatch key
    cp KEY_UP
    jp z, .int_up
    cp KEY_DOWN
    jp z, .int_down
    cp KEY_LEFT
    jp z, .int_left
    cp KEY_RIGHT
    jp z, .int_right
    cp KEY_SELECT
    jp z, .int_select
    cp KEY_ENTER
    jp z, .int_ask
    cp KEY_CLEAR
    jp z, .int_clear
    cp KEY_HUMAN
    jp z, .int_verdict_h
    cp KEY_ANDROID
    jp z, .int_verdict_a
    ret

; ---- Cursor movement ----
.int_up:
    ld a, SFX_CLICK
    call ay_play_sfx
    call unhighlight_cursor
    ld a, (cursor_y)
    or a
    jr z, .up_wrap
    dec a
    ld (cursor_y), a
    jp highlight_cursor
.up_wrap:
    ld a, 3
    ld (cursor_y), a
    jp highlight_cursor

.int_down:
    ld a, SFX_CLICK
    call ay_play_sfx
    call unhighlight_cursor
    ld a, (cursor_y)
    cp 3
    jr z, .dn_wrap
    inc a
    ld (cursor_y), a
    jp highlight_cursor
.dn_wrap:
    xor a
    ld (cursor_y), a
    jp highlight_cursor

.int_left:
    ld a, SFX_CLICK
    call ay_play_sfx
    call unhighlight_cursor
    ld a, (cursor_x)
    or a
    jr z, .lt_wrap
    dec a
    ld (cursor_x), a
    jp highlight_cursor
.lt_wrap:
    ld a, 3
    ld (cursor_x), a
    jp highlight_cursor

.int_right:
    ld a, SFX_CLICK
    call ay_play_sfx
    call unhighlight_cursor
    ld a, (cursor_x)
    cp 3
    jr z, .rt_wrap
    inc a
    ld (cursor_x), a
    jp highlight_cursor
.rt_wrap:
    xor a
    ld (cursor_x), a
    jp highlight_cursor

; ---- Icon selection ----
.int_select:
    ; Check if query full
    ld a, (query_count)
    cp MAX_QUERY_ICONS
    ret nc
    ; Compute icon ID = cursor_y * 4 + cursor_x
    ld a, (cursor_y)
    add a, a
    add a, a
    ld b, a
    ld a, (cursor_x)
    add a, b            ; A = icon id
    ; Check if already selected
    ld hl, query_icons
    cp (hl)
    ret z
    inc hl
    cp (hl)
    ret z
    inc hl
    cp (hl)
    ret z
    ; Add to query
    ld b, a
    ld a, (query_count)
    ld e, a
    ld d, 0
    ld hl, query_icons
    add hl, de
    ld (hl), b
    ld a, (query_count)
    inc a
    ld (query_count), a
    ; SFX
    ld a, SFX_CHIRP
    call ay_play_sfx
    ; Mark icon as selected (attr)
    call mark_selected_icon
    ; Redraw query strip
    jp draw_query_strip

; ---- Clear query ----
.int_clear:
    ld a, SFX_CLICK
    call ay_play_sfx
    xor a
    ld (query_count), a
    ld a, ICON_NONE
    ld (query_icons), a
    ld (query_icons+1), a
    ld (query_icons+2), a
    ; Restore all icon grid attrs to normal
    call draw_icon_grid_attrs
    call highlight_cursor
    jp draw_query_strip

; ---- Ask question (core gameplay) ----
.int_ask:
    ld a, (query_count)
    or a
    ret z               ; need at least 1 icon

    ld a, SFX_ASK
    call ay_play_sfx

    ; 1. Classify the query
    call classify_query
    ld (ask_class), a

    ; 2. Compute emotional weight
    call compute_q_weight

    ; 3. Compute dual gauges
    ld a, (ask_class)
    ld hl, (current_subj)
    call compute_gauges

    ; 4. Select and build response text
    ld a, (ask_class)
    ld b, a
    call select_and_build_response
    ; HL = response string

    ; 5. Display scenario prompt and response text
    push hl
    call clear_response_area

    ; Print scenario prompt based on first selected icon
    ld a, (query_icons)
    cp ICON_NONE
    jr z, .int_no_scenario
    ; Look up scenario string: scenario_ptrs + icon * 2
    ld l, a
    ld h, 0
    add hl, hl
    ld de, scenario_ptrs
    add hl, de
    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a              ; HL = scenario string pointer
    ld a, RESPONSE_COL
    ld (pr_col), a
    ld a, RESPONSE_ROW
    ld (pr_row), a
    ld a, RESPONSE_W
    ld (box_width), a
    call print_str_box
    ; Set scenario row attrs (white on black, 2 rows for wrapped prompts)
    ld d, RESPONSE_ROW
    ld b, RESPONSE_COL
    ld e, RESPONSE_W
    ld a, ATTR_QUERY
    call set_row_attrs
    ld d, RESPONSE_ROW + 1
    ld b, RESPONSE_COL
    ld e, RESPONSE_W
    ld a, ATTR_QUERY
    call set_row_attrs
.int_no_scenario:

    pop hl
    ld a, RESPONSE_COL
    ld (pr_col), a
    ld a, RESPONSE_ROW + 2
    ld (pr_row), a
    ld a, RESPONSE_W
    ld (box_width), a
    call print_str_box

    ; 6. Set response area attrs (rows below scenario prompt)
    ld d, RESPONSE_ROW + 2
.int_rattr:
    ld a, d
    cp RESPONSE_ROW + RESPONSE_H
    jr nc, .int_rattr_done
    push de
    ld b, RESPONSE_COL
    ld e, RESPONSE_W
    ld a, ATTR_RESPONSE
    call set_row_attrs
    pop de
    inc d
    jr .int_rattr
.int_rattr_done:

    ; 7. Draw Voight-Kampff gauges and readings
    call draw_pupil_gauge
    call draw_flush_gauge
    call draw_pattern_label
    call draw_qweight_label

    ; 8. Trigger pupil blink if gauge is in red zone
    ld a, (pupil_gauge)
    cp 12
    jr c, .int_no_blink_trigger
    call trigger_eye_blink
.int_no_blink_trigger:

    ; 9. Increment questions asked
    ld hl, questions_asked
    inc (hl)

    ; 10. Clear query for next round
    xor a
    ld (query_count), a
    ld a, ICON_NONE
    ld (query_icons), a
    ld (query_icons+1), a
    ld (query_icons+2), a
    call draw_icon_grid_attrs
    call highlight_cursor
    call draw_query_strip
    jp draw_status_bar

; ---- Verdict ----
.int_verdict_h:
    xor a               ; TYPE_HUMAN
    jp .do_verdict
.int_verdict_a:
    ld a, TYPE_ANDROID
.do_verdict:
    ld (player_verdict), a
    call ay_mute
    xor a
    ld (screen_drawn), a
    ld a, ST_VERDICT
    ld (game_state), a
    ret

player_verdict: db 0

; ===============================================================
; Voight-Kampff gauge display routines
; ===============================================================

; Draw PUPIL gauge bar at row PUPIL_ROW
draw_pupil_gauge:
    ; Label
    ld a, GAUGE_LABEL_COL
    ld (pr_col), a
    ld a, PUPIL_ROW
    ld (pr_row), a
    ld hl, str_pupil
    call print_str
    ; Bar
    ld a, (pupil_gauge)
    ld d, PUPIL_ROW
    jp draw_gauge_bar

; Draw FLUSH gauge bar at row FLUSH_ROW
draw_flush_gauge:
    ; Label
    ld a, GAUGE_LABEL_COL
    ld (pr_col), a
    ld a, FLUSH_ROW
    ld (pr_row), a
    ld hl, str_flush
    call print_str
    ; Bar
    ld a, (flush_gauge)
    ld d, FLUSH_ROW
    jp draw_gauge_bar

; Draw a gauge bar: A = value (0-max), D = row
; Filled portion uses colored attrs, empty portion uses dark
draw_gauge_bar:
    ; Clamp value to bar width
    cp GAUGE_BAR_W + 1
    jr c, .dgb_clamped
    ld a, GAUGE_BAR_W
.dgb_clamped:
    ld c, a              ; C = filled width (0-GAUGE_BAR_W)
    ; Draw filled portion
    ld a, c
    or a
    jr z, .dgb_empty_only
    ld b, GAUGE_BAR_COL
    ld e, c
    ; Choose color: green 0-5, yellow 6-11, red 12+
    ld a, c
    cp 12
    jr nc, .dgb_red
    cp 6
    jr nc, .dgb_yellow
    ld a, ATTR_GAUGE_LO
    jr .dgb_fill
.dgb_yellow:
    ld a, ATTR_GAUGE_MID
    jr .dgb_fill
.dgb_red:
    ld a, ATTR_GAUGE_HI
.dgb_fill:
    call set_row_attrs

.dgb_empty_only:
    ; Draw empty portion
    ld a, GAUGE_BAR_W
    sub c
    or a
    ret z
    ld e, a
    ld a, GAUGE_BAR_COL
    add a, c
    ld b, a
    ld a, ATTR_GAUGE_BG
    jp set_row_attrs

; Draw PATTERN label
draw_pattern_label:
    ld a, GAUGE_LABEL_COL
    ld (pr_col), a
    ld a, PATTERN_ROW
    ld (pr_row), a
    ld hl, str_pattern
    call print_str
    ld a, (pr_col)
    inc a
    ld (pr_col), a
    ; Get pattern label pointer
    ld a, (pattern_flag)
    add a, a
    ld e, a
    ld d, 0
    ld hl, pattern_labels
    add hl, de
    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a
    call print_str
    ; Set row attrs
    ld d, PATTERN_ROW
    ld b, GAUGE_LABEL_COL
    ld e, RESPONSE_W
    ld a, ATTR_RESPONSE
    jp set_row_attrs

; Draw Q-WEIGHT label
draw_qweight_label:
    ld a, GAUGE_LABEL_COL
    ld (pr_col), a
    ld a, QWEIGHT_ROW
    ld (pr_row), a
    ld hl, str_qweight
    call print_str
    ld a, (pr_col)
    inc a
    ld (pr_col), a
    ; Determine level: <33=LOW, <66=MED, else HIGH
    ld a, (q_weight)
    cp 66
    jr nc, .dqw_high
    cp 33
    jr nc, .dqw_med
    ; LOW
    ld hl, str_qw_low
    jr .dqw_print
.dqw_med:
    ld hl, str_qw_med
    jr .dqw_print
.dqw_high:
    ld hl, str_qw_high
.dqw_print:
    call print_str
    ; Set row attrs
    ld d, QWEIGHT_ROW
    ld b, GAUGE_LABEL_COL
    ld e, RESPONSE_W
    ld a, ATTR_RESPONSE
    jp set_row_attrs

; ===============================================================
; Eye blink effect — briefly set eye attrs to red
; ===============================================================
trigger_eye_blink:
    ld a, 10
    ld (blink_timer), a
    ; Determine eye positions from portrait seed
    ld hl, (current_subj)
    ld de, SUBJ_PORTRAIT + 1
    add hl, de
    ld a, (hl)          ; port_seed_hi
    and 1
    jr z, .teb_normal
    ; Wide eyes: cols 1 and 6
    ld a, ATTR_PUPIL_BLINK
    ld d, PORTRAIT_ROW + 3
    ld b, PORTRAIT_COL + 1
    ld e, 1
    call set_row_attrs
    ld a, ATTR_PUPIL_BLINK
    ld d, PORTRAIT_ROW + 3
    ld b, PORTRAIT_COL + 6
    ld e, 1
    jp set_row_attrs
.teb_normal:
    ; Normal eyes: cols 2 and 5
    ld a, ATTR_PUPIL_BLINK
    ld d, PORTRAIT_ROW + 3
    ld b, PORTRAIT_COL + 2
    ld e, 1
    call set_row_attrs
    ld a, ATTR_PUPIL_BLINK
    ld d, PORTRAIT_ROW + 3
    ld b, PORTRAIT_COL + 5
    ld e, 1
    jp set_row_attrs

; Restore eye attrs to normal black
restore_eye_attr:
    ld hl, (current_subj)
    ld de, SUBJ_PORTRAIT + 1
    add hl, de
    ld a, (hl)
    and 1
    jr z, .rea_normal
    ld a, (eye_attr)
    ld d, PORTRAIT_ROW + 3
    ld b, PORTRAIT_COL + 1
    ld e, 1
    call set_row_attrs
    ld a, (eye_attr)
    ld d, PORTRAIT_ROW + 3
    ld b, PORTRAIT_COL + 6
    ld e, 1
    jp set_row_attrs
.rea_normal:
    ld a, (eye_attr)
    ld d, PORTRAIT_ROW + 3
    ld b, PORTRAIT_COL + 2
    ld e, 1
    call set_row_attrs
    ld a, (eye_attr)
    ld d, PORTRAIT_ROW + 3
    ld b, PORTRAIT_COL + 5
    ld e, 1
    jp set_row_attrs

; ===============================================================
; Interrogation screen drawing
; ===============================================================
draw_interrogation:
    ld a, INK_GREEN + (INK_BLACK*8)
    call clear_screen_attrs

    call draw_status_bar

    ; Divider row 1
    ld d, 1
    ld b, 0
    ld e, 32
    ld a, ATTR_DIVIDER
    call set_row_attrs

    ; Divider row 14
    ld d, 14
    ld b, 0
    ld e, 32
    ld a, ATTR_DIVIDER
    call set_row_attrs

    ; Divider row 20
    ld d, 20
    ld b, 0
    ld e, 32
    ld a, ATTR_DIVIDER
    call set_row_attrs

    ; Draw portrait
    ld hl, (current_subj)
    call draw_portrait

    ; Vertical separator: col 8, rows 2-13 — use divider attr
    ld d, 2
.di_vsep:
    ld a, d
    cp 14
    jr nc, .di_vsep_done
    push de
    ld b, 8
    ld e, 1
    ld a, ATTR_DIVIDER
    call set_row_attrs
    pop de
    inc d
    jr .di_vsep
.di_vsep_done:

    ; Response area attrs (initially dark)
    ld d, RESPONSE_ROW
.di_resp:
    ld a, d
    cp RESPONSE_ROW + RESPONSE_H
    jr nc, .di_resp_done
    push de
    ld b, RESPONSE_COL
    ld e, RESPONSE_W
    ld a, INK_CYAN + (INK_BLACK*8)
    call set_row_attrs
    pop de
    inc d
    jr .di_resp
.di_resp_done:

    ; Gauge area attrs (initially dark, rows 10-13)
    ld d, PUPIL_ROW
.di_gauge:
    ld a, d
    cp QWEIGHT_ROW + 1
    jr nc, .di_gauge_done
    push de
    ld b, GAUGE_LABEL_COL
    ld e, RESPONSE_W
    ld a, INK_CYAN + (INK_BLACK*8)
    call set_row_attrs
    pop de
    inc d
    jr .di_gauge
.di_gauge_done:

    ; Query strip
    call draw_query_strip

    ; Icon grid labels
    call draw_icon_labels
    call draw_icon_grid_attrs
    call highlight_cursor

    ; Controls text row 21
    ld a, 1
    ld (pr_col), a
    ld a, 21
    ld (pr_row), a
    ld hl, str_enter_ask
    call print_str
    ld a, 12
    ld (pr_col), a
    ld hl, str_h_human
    call print_str
    ld a, 21
    ld (pr_col), a
    ld hl, str_r_android
    call print_str

    ; Row 21 attrs
    ld d, 21
    ld b, 0
    ld e, 32
    ld a, ATTR_CONTROLS
    call set_row_attrs

    ; Controls text row 22
    ld a, 1
    ld (pr_col), a
    ld a, 22
    ld (pr_row), a
    ld hl, str_controls
    call print_str

    ld d, 22
    ld b, 0
    ld e, 32
    ld a, ATTR_CONTROLS
    call set_row_attrs

    ret

; --- Status bar (row 0) ---
draw_status_bar:
    ; Clear row 0 text
    ld d, 0
    ld b, 0
    ld e, 32
    ld c, 1
    call clear_text_rect
    ; LVL N
    ld a, 0
    ld (pr_col), a
    ld a, 0
    ld (pr_row), a
    ld hl, str_lvl
    call print_str
    ld a, (pr_col)
    inc a
    ld (pr_col), a
    ld a, (level_num)
    call print_num
    ; SCORE NNN
    ld a, 8
    ld (pr_col), a
    ld hl, str_score
    call print_str
    ld a, (pr_col)
    inc a
    ld (pr_col), a
    ld hl, (total_score)
    call print_num16
    ; ASKED N
    ld a, 20
    ld (pr_col), a
    ld a, 0
    ld (pr_row), a
    ld hl, str_asked
    call print_str
    ld a, (pr_col)
    inc a
    ld (pr_col), a
    ld a, (questions_asked)
    call print_num
    ; Attr
    ld d, 0
    ld b, 0
    ld e, 32
    ld a, ATTR_STATUS
    call set_row_attrs
    ret

; --- Icon labels (text) ---
draw_icon_labels:
    ld c, 0             ; icon index 0-15
.dil_loop:
    ld a, c
    cp 16
    ret nc
    push bc
    ; Row = 16 + (index / 4)
    ld a, c
    srl a
    srl a
    add a, GRID_TOP_ROW
    ld (pr_row), a
    ; Col = (index & 3) * 8
    ld a, c
    and 3
    add a, a
    add a, a
    add a, a
    ld (pr_col), a
    ; Get icon label pointer
    ld a, c
    add a, a
    ld e, a
    ld d, 0
    ld hl, icon_labels
    add hl, de
    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a
    call print_str
    pop bc
    inc c
    jr .dil_loop

; --- Icon grid attrs (normal green) ---
draw_icon_grid_attrs:
    ld d, GRID_TOP_ROW
.diga_loop:
    ld a, d
    cp GRID_TOP_ROW + 4
    ret nc
    push de
    ld b, 0
    ld e, 32
    ld a, ATTR_NORMAL
    call set_row_attrs
    pop de
    inc d
    jr .diga_loop

; --- Cursor highlight/unhighlight ---
highlight_cursor:
    ld a, (cursor_y)
    add a, GRID_TOP_ROW
    ld d, a
    ld a, (cursor_x)
    add a, a
    add a, a
    add a, a
    ld b, a
    ld e, 8
    ld a, ATTR_HIGHLIGHT
    jp set_row_attrs

unhighlight_cursor:
    ld a, (cursor_y)
    add a, GRID_TOP_ROW
    ld d, a
    ld a, (cursor_x)
    add a, a
    add a, a
    add a, a
    ld b, a
    ld e, 8
    ld a, ATTR_NORMAL
    jp set_row_attrs

; --- Mark a selected icon (yellow attr) ---
mark_selected_icon:
    ld a, (cursor_y)
    add a, GRID_TOP_ROW
    ld d, a
    ld a, (cursor_x)
    add a, a
    add a, a
    add a, a
    ld b, a
    ld e, 8
    ld a, ATTR_SELECTED
    jp set_row_attrs

; --- Query strip (row 15) ---
draw_query_strip:
    ; Clear row 15
    ld d, QUERY_ROW
    ld b, 0
    ld e, 32
    ld c, 1
    call clear_text_rect
    ; "QUERY:"
    ld a, 0
    ld (pr_col), a
    ld a, QUERY_ROW
    ld (pr_row), a
    ld hl, str_query
    call print_str
    ld a, (pr_col)
    inc a
    ld (pr_col), a
    ; Print selected icon names
    ld a, (query_count)
    or a
    jr z, .dqs_empty
    ld b, 0             ; icon counter
.dqs_icon:
    push bc
    ld a, b
    ld e, a
    ld d, 0
    ld hl, query_icons
    add hl, de
    ld a, (hl)
    cp ICON_NONE
    jr z, .dqs_icon_skip
    ; Print "+" separator if not first
    ld a, b
    or a
    jr z, .dqs_no_plus
    push bc
    ld a, QUERY_ROW
    ld (pr_row), a
    ld hl, str_plus
    call print_str
    pop bc
.dqs_no_plus:
    ; Get icon name
    ld a, b
    ld e, a
    ld d, 0
    ld hl, query_icons
    add hl, de
    ld a, (hl)
    add a, a
    ld e, a
    ld d, 0
    ld hl, icon_labels
    add hl, de
    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a
    ld a, QUERY_ROW
    ld (pr_row), a
    call print_str
.dqs_icon_skip:
    pop bc
    inc b
    ld a, b
    cp MAX_QUERY_ICONS
    jr c, .dqs_icon
.dqs_empty:
    ; Attr
    ld d, QUERY_ROW
    ld b, 0
    ld e, 32
    ld a, ATTR_QUERY
    call set_row_attrs
    ret

; --- Clear response text area ---
clear_response_area:
    ld d, RESPONSE_ROW
    ld b, RESPONSE_COL
    ld e, RESPONSE_W
    ld c, RESPONSE_H
    jp clear_text_rect

; ===============================================================
; ST_VERDICT — show what the player chose, compute score
; ===============================================================
verdict_frame:
    ld a, (screen_drawn)
    or a
    jp nz, .vf_wait

    ; Use custom font for verdict screen
    call use_custom_font

    ; Determine correctness
    ld hl, (current_subj)
    ld a, (hl)          ; subject type
    ld b, a
    ld a, (player_verdict)
    cp b
    jr z, .vf_correct

    ; Wrong
    xor a
    ld (level_score), a
    ld a, 0
    ld (verdict_correct), a
    ld a, SFX_WRONG
    call ay_play_sfx
    jr .vf_draw

.vf_correct:
    ld a, 1
    ld (verdict_correct), a
    ; Score = max(0, 100 - questions_asked * penalty)
    ld a, (level_num)
    call get_penalty    ; A = penalty per question
    ld b, a
    ld a, (questions_asked)
    or a
    jr z, .vf_full_score
    ; Multiply: questions_asked * penalty
    ld c, a
    xor a
.vf_mul:
    add a, b
    jr c, .vf_zero_score
    dec c
    jr nz, .vf_mul
    ; A = total penalty
    ld b, a
    ld a, BASE_SCORE
    sub b
    jr nc, .vf_got_score
.vf_zero_score:
    xor a
    jr .vf_got_score
.vf_full_score:
    ld a, BASE_SCORE
.vf_got_score:
    ld (level_score), a
    ; Add to total
    ld e, a
    ld d, 0
    ld hl, (total_score)
    add hl, de
    ld (total_score), hl

.vf_draw:
    ; Draw verdict screen
    ld a, (verdict_correct)
    or a
    jr z, .vf_draw_wrong

    ld a, ATTR_CORRECT
    call clear_screen_attrs

    ld a, 11
    ld (pr_col), a
    ld a, 4
    ld (pr_row), a
    ld hl, str_correct
    call print_str
    jr .vf_draw_score

.vf_draw_wrong:
    ld a, ATTR_WRONG
    call clear_screen_attrs

    ld a, 10
    ld (pr_col), a
    ld a, 4
    ld (pr_row), a
    ld hl, str_wrong
    call print_str

.vf_draw_score:
    ; Show what player said
    ld a, (player_verdict)
    or a
    jr nz, .vf_said_android
    ld a, 9
    ld (pr_col), a
    ld a, 8
    ld (pr_row), a
    ld hl, str_human
    call print_str
    jr .vf_show_pts
.vf_said_android:
    ld a, 9
    ld (pr_col), a
    ld a, 8
    ld (pr_row), a
    ld hl, str_android
    call print_str

.vf_show_pts:
    ; Points awarded
    ld a, 10
    ld (pr_col), a
    ld a, 12
    ld (pr_row), a
    ld a, (level_score)
    call print_num
    ld a, (pr_col)
    inc a
    ld (pr_col), a
    ld hl, str_awarded
    call print_str

    ; Total
    ld a, 10
    ld (pr_col), a
    ld a, 14
    ld (pr_row), a
    ld hl, str_total
    call print_str
    ld a, (pr_col)
    inc a
    ld (pr_col), a
    ld hl, (total_score)
    call print_num16

    ; "PRESS KEY..."
    ld a, 3
    ld (pr_col), a
    ld a, 20
    ld (pr_row), a
    ld hl, str_next
    call print_str

    ; Play beeper sample for correct verdict (screen is already visible)
    ld a, (verdict_correct)
    or a
    jr z, .vf_no_sample
    call play_hell_yeah
    call ay_init_ambient
.vf_no_sample:

    ld a, 1
    ld (screen_drawn), a

.vf_wait:
    call read_any_key
    or a
    ret z
    ; Debounce: wait for release
    call read_any_key
    or a
    jr nz, .vf_wait

    call use_rom_font
    xor a
    ld (screen_drawn), a
    ; Next level or gameover
    ld a, (level_num)
    cp NUM_LEVELS
    jr nc, .vf_gameover
    inc a
    ld (level_num), a
    ld a, ST_LEVEL_INTRO
    ld (game_state), a
    ret
.vf_gameover:
    ld a, ST_GAMEOVER
    ld (game_state), a
    ret

ask_class:       db 0
level_score:     db 0
verdict_correct: db 0

; ===============================================================
; ST_GAMEOVER — final score screen, then check high score
; ===============================================================
gameover_frame:
    ld a, (screen_drawn)
    or a
    jp nz, .go_wait

    call use_custom_font

    ld a, INK_WHITE + (INK_BLUE*8) + BRIGHT
    call clear_screen_attrs

    ; "GAME OVER"
    ld a, 11
    ld (pr_col), a
    ld a, 5
    ld (pr_row), a
    ld hl, str_gameover
    call print_str

    ; "FINAL SCORE"
    ld a, 10
    ld (pr_col), a
    ld a, 10
    ld (pr_row), a
    ld hl, str_final
    call print_str

    ; Score number
    ld a, 14
    ld (pr_col), a
    ld a, 13
    ld (pr_row), a
    ld hl, (total_score)
    call print_num16

    ; "PRESS ANY KEY"
    ld a, 9
    ld (pr_col), a
    ld a, 20
    ld (pr_row), a
    ld hl, str_any_end
    call print_str

    call use_rom_font
    ld a, 1
    ld (screen_drawn), a

.go_wait:
    call read_any_key
    or a
    ret z

    ; Check if qualifies for high score table
    call check_hiscore
    ld a, (hiscore_new_pos)
    cp #FF
    jr z, .go_no_hiscore

    ; Qualified — go to hiscore entry mode (silent)
    call ay_mute
    xor a
    ld (screen_drawn), a
    ld (key_held), a
    ld a, ST_HISCORE
    ld (game_state), a
    ld a, 1
    ld (hiscore_entry_mode), a
    ret

.go_no_hiscore:
    ; Show high score table (display mode) before returning to attract
    call ay_mute
    xor a
    ld (screen_drawn), a
    ld (hiscore_entry_mode), a
    ld a, ST_HISCORE
    ld (game_state), a
    call ay_init_title
    ret

hiscore_entry_mode: db 0
