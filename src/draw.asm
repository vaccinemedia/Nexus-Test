; draw.asm — Direct screen output for Nexus
; Writes ROM font (8x8) directly to screen RAM. No plot routine needed.
;
; Screen address for char cell at column B (0-31), row D (0-23):
;   H = #40 | (D & #18)         ... selects third + base
;   L = ((D & 7) << 5) | B      ... selects char row within third + column
; Pixel rows within cell: consecutive values of H (just inc H).

pr_col: db 0
pr_row: db 0

; Font base address: #3D00 = ROM font, custom_font_data = custom font
font_base: dw #3D00

; --- Print single character at (pr_col, pr_row) ---
; C = ASCII 32-127. Does NOT advance cursor. Preserves BC, DE, HL.
print_char:
    ld a, c
    sub 32
    ret c
    cp 96
    ret nc

    push bc
    push de
    push hl

    ; Font data = font_base + (char-32)*8
    ld l, a
    ld h, 0
    add hl, hl
    add hl, hl
    add hl, hl
    ld de, (font_base)
    add hl, de

    ; Screen H byte
    ld a, (pr_row)
    and #18
    or #40
    ld b, a

    ; Screen L byte
    ld a, (pr_row)
    and 7
    rlca
    rlca
    rlca
    rlca
    rlca
    ld c, a
    ld a, (pr_col)
    or c
    ld e, a
    ld d, b

    ; Write 8 font bytes; inc D moves to next pixel row (+256)
    ld b, 8
.pc_lp:
    ld a, (hl)
    ld (de), a
    inc hl
    inc d
    djnz .pc_lp

    pop hl
    pop de
    pop bc
    ret

; --- Print ASCIZ string. Advances cursor. ---
; HL = string pointer.
print_str:
    ld a, (hl)
    or a
    ret z
    push hl
    ld c, a
    call print_char
    pop hl
    inc hl
    ld a, (pr_col)
    inc a
    ld (pr_col), a
    cp 32
    jr c, print_str
    xor a
    ld (pr_col), a
    ld a, (pr_row)
    inc a
    ld (pr_row), a
    jr print_str

; --- Print number 0-99. Advances cursor. ---
; A = value.
print_num:
    cp 10
    jr c, .pn_lt10
    ld b, 0
.pn_div:
    inc b
    sub 10
    cp 10
    jr nc, .pn_div
    push af
    ld a, b
    add a, '0'
    ld c, a
    call print_char
    ld hl, pr_col
    inc (hl)
    pop af
.pn_lt10:
    add a, '0'
    ld c, a
    call print_char
    ld hl, pr_col
    inc (hl)
    ret

; --- Print 16-bit number 0-65535. HL = value. Advances cursor. ---
; Uses speculative subtraction for each decimal place, suppresses leading zeros.
print_num16:
    push hl
    ld c, 0             ; C = leading-zero suppression flag (0 = still suppressing)

    ; Ten-thousands (subtract 10000 repeatedly)
    ld b, 0
.pn16_10k:
    ld a, l
    sub low 10000
    ld e, a
    ld a, h
    sbc a, high 10000
    jr c, .pn16_10k_done
    ld h, a
    ld l, e
    inc b
    jr .pn16_10k
.pn16_10k_done:
    call .pn16_digit

    ; Thousands (subtract 1000)
    ld b, 0
.pn16_1k:
    ld a, l
    sub low 1000
    ld e, a
    ld a, h
    sbc a, high 1000
    jr c, .pn16_1k_done
    ld h, a
    ld l, e
    inc b
    jr .pn16_1k
.pn16_1k_done:
    call .pn16_digit

    ; Hundreds (H is now 0)
    ld b, 0
.pn16_100:
    ld a, l
    cp 100
    jr c, .pn16_100_done
    sub 100
    ld l, a
    inc b
    jr .pn16_100
.pn16_100_done:
    call .pn16_digit

    ; Tens
    ld a, l
    ld b, 0
.pn16_10:
    cp 10
    jr c, .pn16_10_done
    sub 10
    inc b
    jr .pn16_10
.pn16_10_done:
    ld l, a
    call .pn16_digit

    ; Ones (always printed)
    ld a, l
    add a, '0'
    ld c, a
    push hl
    call print_char
    ld hl, pr_col
    inc (hl)
    pop hl

    pop hl
    ret

; Helper: print digit in B if non-zero or if we've already printed a digit (C flag)
.pn16_digit:
    ld a, b
    or a
    jr nz, .pn16_dig_print
    ld a, c
    or a
    ret z               ; still suppressing leading zeros
.pn16_dig_print:
    ld c, 1             ; no longer suppressing
    ld a, b
    add a, '0'
    push hl
    push bc
    ld c, a
    call print_char
    ld hl, pr_col
    inc (hl)
    pop bc
    pop hl
    ret

; --- Set attributes for a row range ---
; D = row (0-23), B = start col (0-31), E = count, A = attr value.
set_row_attrs:
    ld c, a
    push de
    ld a, d
    ld h, 0
    ld l, a
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    ld d, 0
    ld e, b
    add hl, de
    ld de, ATTR_BASE
    add hl, de
    pop de
    ld b, e
    ld a, b
    or a
    ret z
    ld a, c
.sra_lp:
    ld (hl), a
    inc hl
    djnz .sra_lp
    ret

; --- Clear a rectangular text area (print spaces) ---
; D = start row, B = start col, E = width, C = height (rows)
clear_text_rect:
    ld a, b
    ld (pr_col), a
    ld a, d
    ld (pr_row), a
.ctr_row:
    ld a, c
    or a
    ret z
    push bc
    push de
    ld b, e             ; width counter
.ctr_col:
    push bc
    ld c, ' '
    call print_char
    pop bc
    ld hl, pr_col
    inc (hl)
    djnz .ctr_col
    pop de
    pop bc
    ; Next row
    dec c
    inc d
    ld a, d
    ld (pr_row), a
    ld a, (pr_col)
    sub e               ; rewind to start col
    ld (pr_col), a
    jr .ctr_row

; --- Copy 6912-byte SCR data to screen memory ---
; HL = pointer to SCR data (6144 pixel bytes + 768 attr bytes)
copy_scr_to_screen:
    ld de, PIX_BASE
    ld bc, 6912
    ldir
    ret

; --- Print string within a bounded box (word-wraps at word boundaries) ---
; HL = ASCIZ string. Box starts at current (pr_col, pr_row).
; Wraps at column (pr_col + box_width). box_width must be set first.
; Words that exceed a full line are broken mid-word as a fallback.
box_left:  db 0
box_width: db 23

print_str_box:
    ld a, (pr_col)
    ld (box_left), a

.psb_next:
    ; Skip spaces at start of a new line (after a wrap)
    ld a, (pr_col)
    ld b, a
    ld a, (box_left)
    cp b
    jr nz, .psb_word     ; not at line start, don't skip
.psb_skip_sp:
    ld a, (hl)
    cp ' '
    jr nz, .psb_word
    inc hl                ; eat leading space after wrap
    jr .psb_skip_sp

.psb_word:
    ld a, (hl)
    or a
    ret z                 ; end of string

    cp ' '
    jr z, .psb_space

    ; Non-space character: measure the upcoming word
    push hl
    ld b, 0               ; word length counter
.psb_meas:
    ld a, (hl)
    or a
    jr z, .psb_meas_done
    cp ' '
    jr z, .psb_meas_done
    inc b
    inc hl
    jr .psb_meas
.psb_meas_done:
    pop hl
    ; B = word length. Check if it fits on the current line.
    ld a, (box_left)
    ld c, a
    ld a, (box_width)
    add a, c              ; A = right edge column
    ld c, a
    ld a, (pr_col)
    ld d, a
    ld a, c
    sub d                 ; A = remaining columns on this line
    cp b
    jr nc, .psb_print     ; word fits, go print it

    ; Word doesn't fit — but if we're already at line start,
    ; print anyway (word is wider than box, break mid-word)
    ld a, (pr_col)
    ld c, a
    ld a, (box_left)
    cp c
    jr z, .psb_print      ; at line start, must print

    ; Wrap to next line before printing the word
    ld a, (box_left)
    ld (pr_col), a
    ld a, (pr_row)
    inc a
    ld (pr_row), a
    jr .psb_word           ; re-check from new line

.psb_space:
    ; Print the space character
    push hl
    ld c, ' '
    call print_char
    pop hl
    inc hl
    ld a, (pr_col)
    inc a
    ld (pr_col), a
    ; Check if we hit the right edge after the space
    call psb_check_edge
    jr .psb_next

.psb_print:
    ; Print characters of the word one by one
    ld a, (hl)
    or a
    ret z
    cp ' '
    jr z, .psb_next       ; word ended, back to main loop
    push hl
    ld c, a
    call print_char
    pop hl
    inc hl
    ld a, (pr_col)
    inc a
    ld (pr_col), a
    ; Check right edge (for mid-word break of oversized words)
    call psb_check_edge
    jr .psb_print

; Helper: if pr_col has reached the right edge, wrap to next line
psb_check_edge:
    ld a, (box_left)
    ld b, a
    ld a, (box_width)
    add a, b              ; A = right edge
    ld b, a
    ld a, (pr_col)
    cp b
    ret c                 ; not at edge yet
    ; At or past edge: wrap
    ld a, (box_left)
    ld (pr_col), a
    ld a, (pr_row)
    inc a
    ld (pr_row), a
    ret

; ===============================================================
; Clear pixel data for a full-width character row (creates black strip)
; D = character row (0-23)
; ===============================================================
clear_pixel_strip:
    push bc
    push de
    push hl

    ; Compute start address of first pixel line in this row
    ld a, d
    and #18
    or #40
    ld h, a
    ld a, d
    and 7
    rlca
    rlca
    rlca
    rlca
    rlca
    ld l, a
    ; HL = start of pixel line 0

    ld b, 8              ; 8 pixel lines per character row
.cps_line:
    push hl
    push bc
    xor a
    ld b, 32             ; 32 bytes per pixel line
.cps_byte:
    ld (hl), a
    inc l
    djnz .cps_byte
    pop bc
    pop hl
    inc h                ; next pixel line
    djnz .cps_line

    pop hl
    pop de
    pop bc
    ret

; ===============================================================
; Double-height character printing (8 wide x 16 tall)
; Each font byte is drawn to 2 consecutive pixel rows.
; Character occupies pr_row and pr_row+1.
; ===============================================================

; Print single character C at double height. Does NOT advance cursor.
print_char_tall:
    ld a, c
    sub 32
    ret c
    cp 96
    ret nc

    push bc
    push de
    push hl

    ; Font pointer
    ld l, a
    ld h, 0
    add hl, hl
    add hl, hl
    add hl, hl
    ld de, (font_base)
    add hl, de

    ; === Top half: first 4 font bytes -> 8 pixel lines of pr_row ===
    ld a, (pr_row)
    and #18
    or #40
    ld d, a
    ld a, (pr_row)
    and 7
    rlca
    rlca
    rlca
    rlca
    rlca
    ld b, a
    ld a, (pr_col)
    or b
    ld e, a

    ld b, 4
.pct_top:
    ld a, (hl)
    ld (de), a
    inc d
    ld (de), a
    inc d
    inc hl
    djnz .pct_top

    ; === Bottom half: next 4 font bytes -> 8 pixel lines of pr_row+1 ===
    ld a, (pr_row)
    inc a
    and #18
    or #40
    ld d, a
    ld a, (pr_row)
    inc a
    and 7
    rlca
    rlca
    rlca
    rlca
    rlca
    ld b, a
    ld a, (pr_col)
    or b
    ld e, a

    ld b, 4
.pct_bot:
    ld a, (hl)
    ld (de), a
    inc d
    ld (de), a
    inc d
    inc hl
    djnz .pct_bot

    pop hl
    pop de
    pop bc
    ret

; Print ASCIZ string at double height. HL = string pointer. Advances pr_col.
print_str_tall:
    ld a, (hl)
    or a
    ret z
    push hl
    ld c, a
    call print_char_tall
    pop hl
    inc hl
    ld a, (pr_col)
    inc a
    ld (pr_col), a
    jr print_str_tall

; ===============================================================
; Custom font support
; ===============================================================

; Initialise the custom font: copy ROM font to RAM, overlay custom A-Z
init_custom_font:
    ; Copy 96-char ROM font (768 bytes) from #3D00 to RAM buffer
    ld hl, #3D00
    ld de, custom_font_data
    ld bc, 768
    ldir
    ; Overlay custom A-Z glyphs (26 chars * 8 bytes = 208 bytes)
    ; A = ASCII 65, offset = (65-32)*8 = 264
    ld hl, custom_glyphs_bin
    ld de, custom_font_data + 264
    ld bc, 208
    ldir
    ret

; Switch to custom font for display screens
use_custom_font:
    ld hl, custom_font_data
    ld (font_base), hl
    ret

; Switch back to ROM font for in-game text
use_rom_font:
    ld hl, #3D00
    ld (font_base), hl
    ret

; 208 bytes of custom A-Z glyph data (8 bytes per letter, A first)
custom_glyphs_bin:
    INCBIN "custom_font.bin"

; RAM buffer for full 96-char font with custom A-Z overlaid
custom_font_data:
    DS 768
