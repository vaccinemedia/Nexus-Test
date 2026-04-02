; System init, 128K paging proof, screen clear
; const.inc included by nexus.asm

; Visible display must use bank-5 attrs at #5800, not shadow at #C000 (#7FFD bit 3)
; bit 4 = 1 → 48K ROM (has font at #3D00); bit 3 = 0 → normal screen; bits 0-2 = bank 0
video_home_128:
    ld bc, PORT_128MEM
    ld a, #10
    out (c), a
    ret

; --- Paging proof: #C000 bank 0 vs bank 1 ---
verify_paging:
    ld bc, #7ffd
    ld a, 0
    out (c), a
    ld hl, #c000
    ld (hl), #a5
    ld a, 1
    out (c), a
    ld (hl), #5a
    ld a, 0
    out (c), a
    ld a, (hl)
    cp #a5
    jr nz, vp_fail
    ld a, 1
    out (c), a
    ld a, (hl)
    cp #5a
    jr nz, vp_fail
    ld a, 0
    out (c), a
    ld a, 1
    ld (paging_ok), a
    ret
vp_fail:
    xor a
    ld (paging_ok), a
    ld a, 0
    out (c), a
    ret

; A = attribute byte — fill 32x24, clear bitmap
clear_screen_attrs:
    ld hl, ATTR_BASE
    ld c, 24
cs_row:
    ld b, 32
    push hl
cs_col:
    ld (hl), a
    inc hl
    djnz cs_col
    pop hl
    ld de, 32
    add hl, de
    dec c
    jr nz, cs_row
    ld hl, PIX_BASE
    ld de, PIX_BASE+1
    ld bc, 6143
    ld (hl), 0
    ldir
    ret

; ~69888 T @ 3.5MHz (~50 Hz) — inner loop ~16T per dec
wait_frame:
    ld e, 28
.wf_y:
    ld d, 157
.wf_x:
    dec d
    jr nz, .wf_x
    dec e
    jr nz, .wf_y
    ret
