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
    call ay_tick_music

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

; The 6912-byte SCR data is included directly
title_scr_data:
    INCBIN "title.scr"
