; ay_outro.asm — Blade Runner "Tears in Rain" three-voice outro.
; Split out of ay_music.asm so this ~250-byte block lives after the
; AKM song data instead of eating into the pre-#93F8 padding.
;
; Three sustained voices in Bm — bass drone (A), harmonic pad (B),
; slow melodic line (C). Chord progression cycles every ~35 seconds
; while the Batty monologue types out; loops if the monologue runs
; long. Volumes fade in from silence over ~1.1s and rest at soft
; ambient targets (bass 8, pad 10, melody 11 of 15).
;
; Sequence record layout (8 bytes/slot for cheap *8 indexing):
;   +0/+1  Ch A tone period (12-bit)
;   +2/+3  Ch B tone period
;   +4/+5  Ch C tone period
;   +6     hold_frames (1..255)
;   +7     unused
; Terminating slot uses A tone = 0 (loop back to slot 0).

ay_init_outro:
    di
    call PLY_AKM_Stop
    ei
    call ay_mute
    ; Mixer: tones A/B/C on, noise mixed into Ch A only (rain-hiss bed
    ; sitting under the bass drone — bit 3 of R7 clear enables noise-A).
    ld d, 7
    ld a, %00110000
    call ay_out
    ; Noise period — moderate value gives a broadband hiss reminiscent of
    ; distant rain. Larger periods = lower pitch (thunder rumble on
    ; specific chord slots, driven by outro_seq's noise column below).
    ld d, 6
    ld a, 12
    call ay_out
    ; Start silent — outro_fade_tick will ramp volumes up over ~55 frames.
    ld d, 8
    xor a
    call ay_out
    ld d, 9
    xor a
    call ay_out
    ld d, 10
    xor a
    call ay_out
    xor a
    ld (outro_step), a
    ld (outro_fade_step), a
    ld a, 5
    ld (outro_fade_ticks), a
    ; Fire the first slot on the very next tick
    ld hl, 1
    ld (outro_timer), hl
    ld a, 3
    ld (music_mode), a
    ret

; -----------------------------------------------------------------
; outro_fade_tick — nudges channel volumes toward their soft targets.
; Runs every frame during the outro; steps 0..11 with a 5-frame gap
; between steps, so the pad eases in over ~55 frames (~1.1s). Channel
; targets are capped at 8/10/11 for bass/pad/melody respectively.
; -----------------------------------------------------------------
outro_fade_tick:
    ld a, (outro_fade_step)
    cp 11
    ret nc                             ; fade complete
    ld hl, outro_fade_ticks
    dec (hl)
    ret nz
    ld (hl), 5
    ld hl, outro_fade_step
    inc (hl)
    ld a, (hl)
    ld c, a                            ; C = new global fade step
    ; Ch A (bass) — target 8
    cp 8
    jr c, .oft_a
    ld a, 8
.oft_a:
    ld d, 8
    call ay_out
    ; Ch B (pad) — target 10
    ld a, c
    cp 10
    jr c, .oft_b
    ld a, 10
.oft_b:
    ld d, 9
    call ay_out
    ; Ch C (melody) — target 11 (equals max step, no cap needed)
    ld a, c
    ld d, 10
    jp ay_out

ay_tick_outro_mode:
    call outro_fade_tick
    ld hl, (outro_timer)
    dec hl
    ld (outro_timer), hl
    ld a, h
    or l
    ret nz
    ; Timer elapsed — load the next chord slot.
    ld a, (outro_step)
    add a, a
    add a, a
    add a, a                          ; step * 8 = byte offset
    ld e, a
    ld d, 0
    ld hl, outro_seq
    add hl, de
    ; Peek at A_lo/A_hi for the end-of-sequence marker (both zero -> loop)
    ld a, (hl)
    inc hl
    ld c, a                           ; C = A_lo
    ld a, (hl)
    dec hl
    or c
    jr nz, .ato_play
    ; Loop back to slot 0 and re-run this frame next tick
    xor a
    ld (outro_step), a
    ld hl, 1
    ld (outro_timer), hl
    ret
.ato_play:
    ; Write R0..R5 (three tone periods) from the slot's first 6 bytes.
    ld d, 0                           ; start register
    ld b, 6                           ; bytes to copy
.ato_regs:
    ld a, (hl)
    push bc
    push hl
    push de
    call ay_out
    pop de
    pop hl
    pop bc
    inc hl
    inc d
    djnz .ato_regs
    ; HL points to hold_frames (+6). Save it, then write the per-slot
    ; noise period (byte +7) to R6 for dynamic rain/thunder atmosphere.
    ld a, (hl)
    ld c, a                            ; C = hold_frames
    inc hl
    ld a, (hl)                         ; A = noise period for this slot
    ld d, 6
    call ay_out
    ld l, c
    ld h, 0
    ld (outro_timer), hl
    ld hl, outro_step
    inc (hl)
    ret

; --- Chord progression -------------------------------------------------
; Notes (period = 1773400 / (16 * freq)):
;   B2 =  898, D3 =  755, F#3 = 599, G2 = 1131, A3 = 504, F#2 = 1198,
;   C#4 = 400, D4 =  377, B3 =  449, E3 = 672,  G3 = 565, A2 = 1008,
;   C#3 = 800, F4 = 317
; Hold = 220 frames per slot at 50 Hz -> ~4.4s. 8 slots -> ~35s loop.
; Noise column: low (5..12) = high-pitch rain hiss, high (24..30) =
; low-pitch thunder rumble on the darker F#m chords.
outro_seq:
    DW 898, 755, 599  : DB 220, 12     ; Bm    B2 D3  F#3     (light rain)
    DW 898, 755, 504  : DB 220, 10     ; Bm7   B2 D3  A3
    DW 1131, 755, 377 : DB 220, 8      ; G     G2 D3  D4      (open, brighter)
    DW 1198, 504, 400 : DB 220, 28     ; F#m   F#2 A3 C#4     (distant thunder)
    DW 898, 599, 449  : DB 220, 12     ; Bm    B2 F#3 B3
    DW 672, 565, 449  : DB 220, 16     ; Em    E3 G3  B3
    DW 1008, 800, 672 : DB 220, 10     ; A     A2 C#3 E3
    DW 1198, 504, 400 : DB 220, 30     ; F#m   F#2 A3 C#4     (thunder swell)
    DW 0, 0, 0        : DB 0, 0        ; end marker -> loop
