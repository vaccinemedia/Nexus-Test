; portrait.asm — Procedural attribute-block portrait generation
; Draws into portrait area: cols 0-7, rows 2-13

; Skin colour palette indexed by (seed & 3)
skin_colours:
    DB INK_WHITE + (INK_WHITE*8) + BRIGHT
    DB INK_YELLOW + (INK_YELLOW*8) + BRIGHT
    DB INK_CYAN + (INK_CYAN*8) + BRIGHT
    DB INK_WHITE + (INK_WHITE*8)

; Hair colour palette indexed by ((seed>>2) & 3)
hair_colours:
    DB INK_BLACK + (INK_BLACK*8)
    DB INK_RED + (INK_RED*8)
    DB INK_BLUE + (INK_BLUE*8)
    DB INK_MAG + (INK_MAG*8)

; Eye colour (always dark)
eye_attr: DB INK_BLACK + (INK_BLACK*8) + BRIGHT

; Mouth colour
mouth_attr: DB INK_RED + (INK_RED*8)

; Background for portrait region
port_bg: DB INK_BLACK + (INK_BLACK*8)

; Draw portrait for subject at HL (subject record pointer).
; Uses portrait_seed field (offset 6) to vary features.
draw_portrait:
    push hl
    ld de, SUBJ_PORTRAIT
    add hl, de
    ld a, (hl)
    ld (port_seed_lo), a
    inc hl
    ld a, (hl)
    ld (port_seed_hi), a
    pop hl

    ; Clear portrait area to background
    ld d, PORTRAIT_ROW
.dp_clr:
    ld a, d
    cp PORTRAIT_ROW + PORTRAIT_H
    jr nc, .dp_clr_done
    push de
    ld b, PORTRAIT_COL
    ld e, PORTRAIT_W
    ld a, (port_bg)
    call set_row_attrs
    pop de
    inc d
    jr .dp_clr
.dp_clr_done:

    ; Select skin colour
    ld a, (port_seed_lo)
    and 3
    ld hl, skin_colours
    ld c, a
    ld b, 0
    add hl, bc
    ld a, (hl)
    ld (port_skin), a

    ; Select hair colour
    ld a, (port_seed_lo)
    srl a
    srl a
    and 3
    ld hl, hair_colours
    ld c, a
    ld b, 0
    add hl, bc
    ld a, (hl)
    ld (port_hair), a

    ; Fill face region (rows 4-12, cols 1-6) with skin
    ld d, PORTRAIT_ROW + 2
.dp_skin:
    ld a, d
    cp PORTRAIT_ROW + 10
    jr nc, .dp_skin_done
    push de
    ld b, PORTRAIT_COL + 1
    ld e, 6
    ld a, (port_skin)
    call set_row_attrs
    pop de
    inc d
    jr .dp_skin
.dp_skin_done:

    ; Hair (rows 2-3, cols 1-6 or 2-5 depending on hair type)
    ld a, (port_seed_lo)
    srl a
    srl a
    srl a
    srl a
    and 3
    cp 0
    jr z, .dp_hair_bald
    cp 1
    jr z, .dp_hair_short

    ; Full hair: rows 2-3, cols 1-6
    ld a, (port_hair)
    ld d, PORTRAIT_ROW
    ld b, PORTRAIT_COL + 1
    ld e, 6
    call set_row_attrs
    ld d, PORTRAIT_ROW + 1
    ld b, PORTRAIT_COL + 1
    ld e, 6
    ld a, (port_hair)
    call set_row_attrs
    jr .dp_hair_done

.dp_hair_short:
    ; Short hair: row 2 cols 2-5
    ld a, (port_hair)
    ld d, PORTRAIT_ROW
    ld b, PORTRAIT_COL + 2
    ld e, 4
    call set_row_attrs
    ; Row 3: skin
    ld a, (port_skin)
    ld d, PORTRAIT_ROW + 1
    ld b, PORTRAIT_COL + 1
    ld e, 6
    call set_row_attrs
    jr .dp_hair_done

.dp_hair_bald:
    ; Bald: rows 2-3 are skin (already set for row 4+; fill rows 2-3)
    ld a, (port_skin)
    ld d, PORTRAIT_ROW
    ld b, PORTRAIT_COL + 2
    ld e, 4
    call set_row_attrs
    ld a, (port_skin)
    ld d, PORTRAIT_ROW + 1
    ld b, PORTRAIT_COL + 1
    ld e, 6
    call set_row_attrs

.dp_hair_done:

    ; Eyes at row 5 (portrait row + 3)
    ; Eye position varies: seed bit 0 of high byte
    ld a, (port_seed_hi)
    and 1
    jr z, .dp_eyes_normal
    ; Wide eyes: cols 1 and 6
    ld a, (eye_attr)
    ld d, PORTRAIT_ROW + 3
    ld b, PORTRAIT_COL + 1
    ld e, 1
    call set_row_attrs
    ld a, (eye_attr)
    ld d, PORTRAIT_ROW + 3
    ld b, PORTRAIT_COL + 6
    ld e, 1
    call set_row_attrs
    jr .dp_eyes_done
.dp_eyes_normal:
    ; Normal eyes: cols 2 and 5
    ld a, (eye_attr)
    ld d, PORTRAIT_ROW + 3
    ld b, PORTRAIT_COL + 2
    ld e, 1
    call set_row_attrs
    ld a, (eye_attr)
    ld d, PORTRAIT_ROW + 3
    ld b, PORTRAIT_COL + 5
    ld e, 1
    call set_row_attrs
.dp_eyes_done:

    ; Nose at row 7 (portrait row + 5): cols 3-4
    ld a, (port_skin)
    ; Slightly different shade: reduce brightness
    and ~BRIGHT
    ld d, PORTRAIT_ROW + 5
    ld b, PORTRAIT_COL + 3
    ld e, 2
    call set_row_attrs

    ; Mouth at row 9 (portrait row + 7)
    ld a, (port_seed_hi)
    srl a
    and 1
    jr z, .dp_mouth_wide
    ; Narrow mouth: cols 3-4
    ld a, (mouth_attr)
    ld d, PORTRAIT_ROW + 7
    ld b, PORTRAIT_COL + 3
    ld e, 2
    call set_row_attrs
    jr .dp_mouth_done
.dp_mouth_wide:
    ; Wide mouth: cols 2-5
    ld a, (mouth_attr)
    ld d, PORTRAIT_ROW + 7
    ld b, PORTRAIT_COL + 2
    ld e, 4
    call set_row_attrs
.dp_mouth_done:

    ; Jaw: rows 10-11 narrowing
    ld a, (port_skin)
    ld d, PORTRAIT_ROW + 9
    ld b, PORTRAIT_COL + 2
    ld e, 4
    call set_row_attrs

    ret

port_seed_lo: db 0
port_seed_hi: db 0
port_skin:    db 0
port_hair:    db 0
