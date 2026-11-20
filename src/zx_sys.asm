; System init, 128K paging proof, screen clear
; const.inc included by nexus.asm

; Visible display must use bank-5 attrs at #5800, not shadow at #C000 (#7FFD bit 3)
; bit 4 = 1 → 48K ROM (has font at #3D00); bit 3 = 0 → normal screen; bits 0-2 = bank 0
video_home_128:
    ld bc, PORT_128MEM
    ld a, #10
    out (c), a
    ret

; A = #7FFD value. Code that pages must sit below #C000, and must call
; page_home before touching text, which lives in the home bank.
page_home:
    ld a, BANK_HOME
page_in:
    ld bc, PORT_128MEM
    out (c), a
    ret

; Loads the headerless tape blocks listed at bank_blocks (bank, length;
; each loads at #C000) that follow the BASIC-loaded program. Runs once,
; after verify_paging has finished scribbling on banks 4 and 6.
load_banks:
    ld a, (paging_ok)
    or a
    ret z
    ld hl, bank_blocks
.block:
    ld a, (hl)
    or a
    jr z, page_home
    inc hl
    ld e, (hl)
    inc hl
    ld d, (hl)
    inc hl
    push hl
    call page_in
    ld ix, #C000
    ld iy, ROM_SYSVARS              ; LD-BYTES re-enables interrupts on exit
    ld a, #FF
    scf
    call ROM_LD_BYTES
    di
    pop hl
    jr .block

; --- Paging proof ---
; Probes 128K bank paging using banks 4 and 6 before load_banks fills
; any of them. Bit 4 keeps the 48K ROM mapped; bit 5 is always clear so
; paging stays enabled.
verify_paging:
    ld bc, #7ffd
    ld a, #14                ; bank 4, 48K ROM
    out (c), a
    ld hl, #c000
    ld (hl), #a5
    ld a, #16                ; bank 6, 48K ROM
    out (c), a
    ld (hl), #5a
    ld a, #14                ; back to bank 4
    out (c), a
    ld a, (hl)
    cp #a5
    jr nz, vp_fail
    ld a, #16                ; bank 6
    out (c), a
    ld a, (hl)
    cp #5a
    jr nz, vp_fail
    ld a, #10                ; restore bank 0
    out (c), a
    ld a, 1
    ld (paging_ok), a
    ret
vp_fail:
    ld a, #10                ; restore bank 0
    out (c), a
    xor a
    ld (paging_ok), a
    ret

; A = attribute byte — fill 32x24, clear bitmap
; Rewritten: LDIR cascade replaces nested loop — saves ~5,269T per call, 4 bytes
clear_screen_attrs:
    ld hl, ATTR_BASE
    ld (hl), a
    ld d, h
    ld e, l
    inc de
    ld bc, 767
    ldir
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
