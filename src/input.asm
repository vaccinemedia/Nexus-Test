; input.asm — Keyboard reading with debounce

kr_qwert:   db 0
kr_asdfg:   db 0
kr_poiuy:   db 0
kr_entlkjh: db 0
kr_spsymnb: db 0
kr_09876:   db 0

; Returns A = KEY_xxx constant (0 = no new key). Debounced.
read_game_key:
    ld a, #fb
    in a, (#fe)
    ld (kr_qwert), a
    ld a, #fd
    in a, (#fe)
    ld (kr_asdfg), a
    ld a, #df
    in a, (#fe)
    ld (kr_poiuy), a
    ld a, #bf
    in a, (#fe)
    ld (kr_entlkjh), a
    ld a, #7f
    in a, (#fe)
    ld (kr_spsymnb), a
    ld a, #ef
    in a, (#fe)
    ld (kr_09876), a

    ; All JP z→JR z: each saves 1 byte; +3T faster when not taken (common path), 9 total
    ld a, (kr_qwert)
    bit 0, a
    ld a, KEY_UP
    jr z, .rgk_debounce

    ld a, (kr_asdfg)
    bit 0, a
    ld a, KEY_DOWN
    jr z, .rgk_debounce

    ld a, (kr_poiuy)
    bit 1, a
    ld a, KEY_LEFT
    jr z, .rgk_debounce

    ld a, (kr_poiuy)
    bit 0, a
    ld a, KEY_RIGHT
    jr z, .rgk_debounce

    ld a, (kr_spsymnb)
    bit 0, a
    ld a, KEY_SELECT
    jr z, .rgk_debounce

    ld a, (kr_entlkjh)
    bit 0, a
    ld a, KEY_ENTER
    jr z, .rgk_debounce

    ld a, (kr_entlkjh)
    bit 4, a
    ld a, KEY_HUMAN
    jr z, .rgk_debounce

    ld a, (kr_qwert)
    bit 3, a
    ld a, KEY_ANDROID
    jr z, .rgk_debounce

    ld a, (kr_09876)
    bit 0, a
    ld a, KEY_CLEAR
    jr z, .rgk_debounce

    xor a
    ld (key_held), a
    ret

.rgk_debounce:
    ld b, a
    ld a, (key_held)
    cp b
    ld a, b
    jr z, .rgk_same
    ld (key_held), a
    ret
.rgk_same:
    xor a
    ret

; A != 0 if any key down (for title/result screens)
read_any_key:
    ld hl, .rak_rows
    ld e, 8
.rak_lp:
    ld a, (hl)
    inc hl
    in a, (#fe)
    cpl
    and #1f
    jr nz, .rak_hit
    dec e
    jr nz, .rak_lp
    xor a
    ret
.rak_hit:
    ld a, 1
    ret

.rak_rows:
    DB #fe,#fd,#fb,#f7,#ef,#df,#bf,#7f

; Scan keyboard for a letter A-Z, ENTER, or DELETE (0 key).
; Returns A = ASCII 'A'-'Z', or 1 = ENTER, 2 = DELETE, 0 = no new key.
; Debounced via letter_held.
scan_letter:
    ; Row #FB: Q W E R T (bits 0-4)
    ld a, #fb
    in a, (#fe)
    ld b, a
    bit 0, b
    ld a, 'Q'
    jp z, .slet_got
    bit 1, b
    ld a, 'W'
    jp z, .slet_got
    bit 2, b
    ld a, 'E'
    jp z, .slet_got
    bit 3, b
    ld a, 'R'
    jp z, .slet_got
    bit 4, b
    ld a, 'T'
    jp z, .slet_got

    ; Row #FD: A S D F G
    ld a, #fd
    in a, (#fe)
    ld b, a
    bit 0, b
    ld a, 'A'
    jp z, .slet_got
    bit 1, b
    ld a, 'S'
    jp z, .slet_got
    bit 2, b
    ld a, 'D'
    jp z, .slet_got
    bit 3, b
    ld a, 'F'
    jp z, .slet_got
    bit 4, b
    ld a, 'G'
    jp z, .slet_got

    ; Row #DF: P O I U Y
    ld a, #df
    in a, (#fe)
    ld b, a
    bit 0, b
    ld a, 'P'
    jp z, .slet_got
    bit 1, b
    ld a, 'O'
    jp z, .slet_got
    bit 2, b
    ld a, 'I'
    jp z, .slet_got
    bit 3, b
    ld a, 'U'
    jp z, .slet_got
    bit 4, b
    ld a, 'Y'
    jp z, .slet_got

    ; Row #BF: ENTER L K J H — JP→JR for last 4 groups (within range), 14 saves
    ld a, #bf
    in a, (#fe)
    ld b, a
    bit 0, b
    ld a, 1             ; ENTER code
    jr z, .slet_got
    bit 1, b
    ld a, 'L'
    jr z, .slet_got
    bit 2, b
    ld a, 'K'
    jr z, .slet_got
    bit 3, b
    ld a, 'J'
    jr z, .slet_got
    bit 4, b
    ld a, 'H'
    jr z, .slet_got

    ; Row #7F: SPACE SYM M N B
    ld a, #7f
    in a, (#fe)
    ld b, a
    bit 2, b
    ld a, 'M'
    jr z, .slet_got
    bit 3, b
    ld a, 'N'
    jr z, .slet_got
    bit 4, b
    ld a, 'B'
    jr z, .slet_got

    ; Row #FE: SHIFT Z X C V
    ld a, #fe
    in a, (#fe)
    ld b, a
    bit 1, b
    ld a, 'Z'
    jr z, .slet_got
    bit 2, b
    ld a, 'X'
    jr z, .slet_got
    bit 3, b
    ld a, 'C'
    jr z, .slet_got
    bit 4, b
    ld a, 'V'
    jr z, .slet_got

    ; Row #EF: 0 key = DELETE
    ld a, #ef
    in a, (#fe)
    ld b, a
    bit 0, b
    ld a, 2             ; DELETE code
    jr z, .slet_got

    ; No key pressed
    xor a
    ld (letter_held), a
    ret

.slet_got:
    ld b, a
    ld a, (letter_held)
    cp b
    ld a, b
    jr z, .slet_same
    ld (letter_held), a
    ret
.slet_same:
    xor a
    ret

letter_held: db 0
