; ay_music.asm — 3-channel AY-3-8912 driver
; Title: bass stabs (A), pad (B), noise drums (C)
; In-game: 4-beat decaying bass (A), B/C for SFX
; AY clock 1773400 Hz; period = 1773400/(16*freq)

; ---- Register write ----
; D = register 0-15, A = value
ay_out:
    push bc
    push af
    ld b, #ff
    ld c, #fd
    out (c), d
    pop af
    ld b, #bf
    out (c), a
    pop bc
    ret

ay_mute:
    xor a
    ld d, 0
    ld b, 14
.am_lp:
    call ay_out
    inc d
    djnz .am_lp
    ld d, 7
    ld a, #ff
    call ay_out
    ret

; ---- Music mode: 0=off, 1=title, 2=ambient ----
music_mode:   db 0
music_frame:  db 0

; Bass sequencer (channel A)
bass_timer:   db 0
bass_step:    db 0

; Pad sequencer (channel B)
pad_timer:    db 0
pad_step:     db 0

; Drum sequencer (channel C + noise)
drum_timer:   db 0
drum_step:    db 0

; SFX state
sfx_id:       db 0
sfx_timer:    db 0

; SFX constants
SFX_NONE      EQU 0
SFX_CLICK     EQU 1
SFX_CHIRP     EQU 2
SFX_ASK       EQU 3
SFX_CORRECT   EQU 4
SFX_WRONG     EQU 5

; ---- Title music init (Blade Runner End Titles inspired) ----
; Key: Bb minor. Tempo: ~60 BPM. All 3 channels tonal, no drums.
; Channel A = deep bass drone, B = melody, C = pad harmony.
ay_init_title:
    call ay_mute
    ld d, 7
    ld a, %00111000       ; all 3 tones on, all noise off
    call ay_out
    ld a, 1
    ld (music_mode), a
    xor a
    ld (music_frame), a
    ld (bass_step), a
    ld (pad_step), a
    ld (drum_step), a
    ld (sfx_timer), a
    ld (sfx_id), a
    ld a, 1
    ld (bass_timer), a
    ld (pad_timer), a
    ld (drum_timer), a
    ret

; ---- Main music tick (call once per frame from any state) ----
ay_tick_music:
    ld a, (music_mode)
    cp 1
    jp z, ay_tick_title_mode
    cp 2
    jp z, ay_tick_ambient_mode
    ret

ay_tick_title_mode:
    call ay_title_bass
    call ay_title_melody
    call ay_title_harmony
    call ay_tick_sfx
    ret

; ===============================================================
; Channel A — Deep bass drone with volume swells (Bb minor roots)
; Data: tone_lo, tone_hi, volume, duration (4 bytes per entry)
; AY regs 0,1 = tone; reg 8 = volume
; ===============================================================
ay_title_bass:
    ld hl, bass_timer
    dec (hl)
    ret nz
    ld a, (bass_step)
    cp BR_BASS_STEPS
    jr c, .tb_ok
    xor a
    ld (bass_step), a
.tb_ok:
    add a, a
    add a, a
    ld e, a
    ld d, 0
    ld hl, br_bass_data
    add hl, de
    ld a, (hl)
    push hl
    ld d, 0
    call ay_out
    pop hl
    inc hl
    ld a, (hl)
    push hl
    ld d, 1
    call ay_out
    pop hl
    inc hl
    ld a, (hl)
    push hl
    ld d, 8
    call ay_out
    pop hl
    inc hl
    ld a, (hl)
    ld (bass_timer), a
    ld hl, bass_step
    inc (hl)
    ret

; Bb2=#03B7  F2=#04F5  Gb2=#04AF  Ab2=#042C  Db3=#0320
br_bass_data:
    ; Bb2 drone — slow swell (150 frames = 3 sec)
    DB #B7, #03, 2, 20
    DB #B7, #03, 5, 25
    DB #B7, #03, 8, 35
    DB #B7, #03, 10, 40
    DB #B7, #03, 7, 20
    DB #B7, #03, 4, 10
    ; F2 drone — slow swell (150 frames)
    DB #F5, #04, 2, 20
    DB #F5, #04, 5, 25
    DB #F5, #04, 9, 35
    DB #F5, #04, 10, 40
    DB #F5, #04, 7, 20
    DB #F5, #04, 3, 10
    ; Gb2 drone — darker colour (130 frames)
    DB #AF, #04, 2, 18
    DB #AF, #04, 6, 25
    DB #AF, #04, 9, 35
    DB #AF, #04, 6, 25
    DB #AF, #04, 3, 12
    DB #AF, #04, 1, 15
    ; Db3 drone — higher tension (140 frames)
    DB #20, #03, 2, 18
    DB #20, #03, 6, 25
    DB #20, #03, 9, 40
    DB #20, #03, 6, 30
    DB #20, #03, 3, 15
    DB #20, #03, 1, 12
BR_BASS_STEPS EQU 24

; ===============================================================
; Channel B — Melody: slow haunting line in Bb minor
; Bb3=#01DC  C4=#01A8  Db4=#0190  Eb4=#0165  F4=#013E
; Gb4=#012C  Ab4=#010B  Bb4=#00EE
; AY regs 2,3 = tone; reg 9 = volume
; ===============================================================
ay_title_melody:
    ld hl, pad_timer
    dec (hl)
    ret nz
    ld a, (pad_step)
    cp BR_MELODY_STEPS
    jr c, .tm_ok
    xor a
    ld (pad_step), a
.tm_ok:
    add a, a
    add a, a
    ld e, a
    ld d, 0
    ld hl, br_melody_data
    add hl, de
    ld a, (hl)
    push hl
    ld d, 2
    call ay_out
    pop hl
    inc hl
    ld a, (hl)
    push hl
    ld d, 3
    call ay_out
    pop hl
    inc hl
    ld a, (hl)
    push hl
    ld d, 9
    call ay_out
    pop hl
    inc hl
    ld a, (hl)
    ld (pad_timer), a
    ld hl, pad_step
    inc (hl)
    ret

br_melody_data:
    ; --- Silence: let bass drone establish (80 frames) ---
    DB #00, #00, 0, 40
    DB #00, #00, 0, 40

    ; --- Phrase 1: Descending (F4 - Eb4 - Db4 - Bb3) ---
    ; F4
    DB #3E, #01, 8, 12
    DB #3E, #01, 12, 25
    DB #3E, #01, 9, 15
    DB #3E, #01, 5, 8
    DB #00, #00, 0, 10
    ; Eb4
    DB #65, #01, 8, 10
    DB #65, #01, 11, 22
    DB #65, #01, 7, 10
    DB #00, #00, 0, 8
    ; Db4
    DB #90, #01, 9, 12
    DB #90, #01, 12, 25
    DB #90, #01, 8, 12
    DB #00, #00, 0, 8
    ; Bb3 — rest point, held long
    DB #DC, #01, 7, 12
    DB #DC, #01, 11, 30
    DB #DC, #01, 8, 18
    DB #DC, #01, 4, 10
    DB #00, #00, 0, 18

    ; --- Phrase 2: Ascending (Bb3 - C4 - Db4 - Eb4 - F4) ---
    ; Bb3 pickup
    DB #DC, #01, 8, 12
    DB #DC, #01, 5, 8
    DB #00, #00, 0, 5
    ; C4
    DB #A8, #01, 9, 12
    DB #A8, #01, 7, 10
    DB #00, #00, 0, 5
    ; Db4
    DB #90, #01, 10, 14
    DB #90, #01, 8, 10
    DB #00, #00, 0, 5
    ; Eb4
    DB #65, #01, 11, 16
    DB #65, #01, 8, 10
    DB #00, #00, 0, 6
    ; F4
    DB #3E, #01, 11, 18
    DB #3E, #01, 9, 12
    DB #00, #00, 0, 8

    ; --- Phrase 3: Peak and descent (Gb4 - F4 - Eb4 - Db4) ---
    ; Gb4 — peak note, strongest
    DB #2C, #01, 10, 12
    DB #2C, #01, 13, 30
    DB #2C, #01, 11, 18
    DB #2C, #01, 7, 10
    DB #00, #00, 0, 10
    ; F4
    DB #3E, #01, 10, 14
    DB #3E, #01, 7, 12
    DB #3E, #01, 4, 8
    DB #00, #00, 0, 8
    ; Eb4
    DB #65, #01, 9, 14
    DB #65, #01, 6, 10
    DB #00, #00, 0, 6
    ; Db4 — resolution
    DB #90, #01, 9, 15
    DB #90, #01, 12, 25
    DB #90, #01, 9, 15
    DB #90, #01, 5, 10
    DB #00, #00, 0, 40
BR_MELODY_STEPS EQU 50

; ===============================================================
; Channel C — Pad harmony: sustained chord tones under melody
; Db4=#0190  Ab3=#0216  F3=#027C  Bb3=#01DC  Eb3=#02C9
; AY regs 4,5 = tone; reg 10 = volume
; ===============================================================
ay_title_harmony:
    ld hl, drum_timer
    dec (hl)
    ret nz
    ld a, (drum_step)
    cp BR_PAD_STEPS
    jr c, .th_ok
    xor a
    ld (drum_step), a
.th_ok:
    add a, a
    add a, a
    ld e, a
    ld d, 0
    ld hl, br_pad_data
    add hl, de
    ld a, (hl)
    push hl
    ld d, 4
    call ay_out
    pop hl
    inc hl
    ld a, (hl)
    push hl
    ld d, 5
    call ay_out
    pop hl
    inc hl
    ld a, (hl)
    push hl
    ld d, 10
    call ay_out
    pop hl
    inc hl
    ld a, (hl)
    ld (drum_timer), a
    ld hl, drum_step
    inc (hl)
    ret

br_pad_data:
    ; Db4 — with melody's descending F4-Eb4 phrase
    DB #90, #01, 3, 35
    DB #90, #01, 5, 50
    DB #90, #01, 4, 40
    DB #90, #01, 2, 25
    ; Ab3 — as melody settles on Db4-Bb3
    DB #16, #02, 3, 30
    DB #16, #02, 5, 50
    DB #16, #02, 4, 40
    DB #16, #02, 2, 30
    ; F3 — ascending section
    DB #7C, #02, 3, 25
    DB #7C, #02, 5, 40
    DB #7C, #02, 4, 30
    ; Bb3 — at melody peak (Gb4)
    DB #DC, #01, 3, 25
    DB #DC, #01, 6, 50
    DB #DC, #01, 4, 30
    ; Eb3 — melody descent/resolution
    DB #C9, #02, 3, 30
    DB #C9, #02, 5, 45
    DB #C9, #02, 3, 25
    ; Silence before loop
    DB #00, #00, 0, 40
BR_PAD_STEPS EQU 18

; ---- In-game ambient init ----
ay_init_ambient:
    call ay_mute
    ld d, 7
    ld a, %00111110
    call ay_out
    ld d, 0
    ld a, #a0
    call ay_out
    ld d, 1
    ld a, #06
    call ay_out
    ld a, 2
    ld (music_mode), a
    xor a
    ld (bass_step), a
    ld a, 1
    ld (bass_timer), a
    ret

; ---- Ambient tick: 4 beats per bar, decreasing volume ----
ay_tick_ambient_mode:
    call ay_tick_sfx
    ld hl, bass_timer
    dec (hl)
    ret nz
    ld a, (bass_step)
    cp 8
    jr c, .amb_ok
    xor a
    ld (bass_step), a
.amb_ok:
    add a, a
    ld e, a
    ld d, 0
    ld hl, amb_pattern
    add hl, de
    ld a, (hl)
    push hl
    ld d, 8
    call ay_out
    pop hl
    inc hl
    ld a, (hl)
    ld (bass_timer), a
    ld hl, bass_step
    inc (hl)
    ret

amb_pattern:
    DB 15, 4
    DB 0,  8
    DB 11, 4
    DB 0,  8
    DB 4,  4
    DB 0,  8
    DB 1,  4
    DB 0,  56

; ---- SFX trigger: A = SFX_xxx ----
ay_play_sfx:
    ld (sfx_id), a
    or a
    ret z
    cp SFX_CLICK
    jp z, sfx_start_click
    cp SFX_CHIRP
    jp z, sfx_start_chirp
    cp SFX_ASK
    jp z, sfx_start_ask
    cp SFX_CORRECT
    jp z, sfx_start_correct
    cp SFX_WRONG
    jp z, sfx_start_wrong
    ret

sfx_start_click:
    ld a, 2
    ld (sfx_timer), a
    ld d, 4
    ld a, #40
    call ay_out
    ld d, 5
    ld a, #00
    call ay_out
    ld d, 10
    ld a, 12
    call ay_out
    ld d, 7
    ld a, %00111000
    call ay_out
    ret

sfx_start_chirp:
    ld a, 4
    ld (sfx_timer), a
    ld d, 4
    ld a, #80
    call ay_out
    ld d, 5
    ld a, #00
    call ay_out
    ld d, 10
    ld a, 14
    call ay_out
    ld d, 7
    ld a, %00111000
    call ay_out
    ret

sfx_start_ask:
    ld a, 8
    ld (sfx_timer), a
    ld d, 2
    ld a, #00
    call ay_out
    ld d, 3
    ld a, #02
    call ay_out
    ld d, 9
    ld a, 13
    call ay_out
    ld d, 7
    ld a, %00110100
    call ay_out
    ret

sfx_start_correct:
    ld a, 16
    ld (sfx_timer), a
    ld d, 2
    ld a, #7F
    call ay_out
    ld d, 3
    ld a, #01
    call ay_out
    ld d, 4
    ld a, #37
    call ay_out
    ld d, 5
    ld a, #01
    call ay_out
    ld d, 9
    ld a, 15
    call ay_out
    ld d, 10
    ld a, 15
    call ay_out
    ld d, 7
    ld a, %00111000
    call ay_out
    ret

sfx_start_wrong:
    ; Harsh descending two-tone alarm with noise burst
    ld a, 40
    ld (sfx_timer), a
    ; Channel B: low harsh tone (A3 ~220Hz, period ~503)
    ld d, 2
    ld a, #F7
    call ay_out
    ld d, 3
    ld a, #01
    call ay_out
    ; Channel C: dissonant tone (Bb2 ~117Hz, period ~946)
    ld d, 4
    ld a, #B2
    call ay_out
    ld d, 5
    ld a, #03
    call ay_out
    ; Noise: harsh static
    ld d, 6
    ld a, #04
    call ay_out
    ; Both channels full volume
    ld d, 9
    ld a, 15
    call ay_out
    ld d, 10
    ld a, 15
    call ay_out
    ; Mixer: enable tones B+C and noise on C
    ld d, 7
    ld a, %00001000
    call ay_out
    ret

; ===============================================================
; Beeper 1-bit PCM sample playback
; Plays packed 1-bit data (8 samples/byte, MSB first) through
; the beeper at ~8kHz. CPU is locked during playback.
; ===============================================================
play_hell_yeah:
    call ay_mute
    ld hl, hellyeah_data
    ld de, HELLYEAH_BYTES
    di
.phy_byte:
    ld b, (hl)
    inc hl
    ld c, 8
.phy_bit:
    rl b
    sbc a, a
    and #10
    out (#fe), a
    ld a, 23
.phy_dly:
    dec a
    jr nz, .phy_dly
    dec c
    jr nz, .phy_bit
    dec de
    ld a, d
    or e
    jr nz, .phy_byte
    ei
    ret

hellyeah_data:
    INCBIN "hellyeah.bin"
HELLYEAH_BYTES EQU $ - hellyeah_data

; Same 1-bit PCM playback for "oh no" sample (wrong verdict)
play_oh_no:
    call ay_mute
    ld hl, ohno_data
    ld de, OHNO_BYTES
    di
.pon_byte:
    ld b, (hl)
    inc hl
    ld c, 8
.pon_bit:
    rl b
    sbc a, a
    and #10
    out (#fe), a
    ld a, 23
.pon_dly:
    dec a
    jr nz, .pon_dly
    dec c
    jr nz, .pon_bit
    dec de
    ld a, d
    or e
    jr nz, .pon_byte
    ei
    ret

ohno_data:
    INCBIN "ohno.bin"
OHNO_BYTES EQU $ - ohno_data

; ---- SFX tick (called each frame) ----
ay_tick_sfx:
    ld a, (sfx_timer)
    or a
    ret z
    dec a
    ld (sfx_timer), a
    or a
    ret nz
    ld d, 9
    xor a
    call ay_out
    ld d, 10
    xor a
    call ay_out
    xor a
    ld (sfx_id), a
    ld a, (music_mode)
    cp 1
    jr z, .sfx_restore_title
    cp 2
    jr z, .sfx_restore_ambient
    ret
.sfx_restore_title:
    ld d, 7
    ld a, %00111000       ; all 3 tones on, no noise
    call ay_out
    ret
.sfx_restore_ambient:
    ld d, 7
    ld a, %00111110
    call ay_out
    ret
