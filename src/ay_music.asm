; ay_music.asm — AY-3-8912 driver
; Title: Arkos Tracker 3 AKM player
; In-game: 4-beat decaying bass (A), B/C for SFX
; AY clock 1773400 Hz; period = 1773400/(16*freq)

; ---- Register write (used by ambient/SFX modes) ----
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
    jp ay_out                ; was CALL+RET — saves 1 byte, 17T

; ---- Music mode: 0=off, 1=title, 2=ambient, 3=outro ----
music_mode:   db 0

; Bass sequencer state (ambient mode)
bass_timer:   db 0
bass_step:    db 0

; Outro sequencer state (Batty "tears in rain" three-voice pastiche)
outro_step:   db 0
outro_timer:  dw 0

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

; ---- Title music: Arkos Tracker AKM player ----
ay_init_title:
    ld a, 1
    ld (music_mode), a
    xor a
    ld (sfx_timer), a
    ld (sfx_id), a
    ld hl, akm_song_data
    xor a
    di
    call PLY_AKM_Init
    ei
    ret

; ---- Main music tick (call once per frame from any state) ----
ay_tick_music:
    ld a, (music_mode)
    cp 1
    jp z, ay_tick_title_mode
    cp 2
    jp z, ay_tick_ambient_mode
    cp 3
    jp z, ay_tick_outro_mode
    ret

ay_tick_title_mode:
    di
    call PLY_AKM_Play
    ei
    ret

; ---- In-game ambient init ----
ay_init_ambient:
    di
    call PLY_AKM_Stop
    ei
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

; ===============================================================
; Outro music (Blade Runner "Tears in Rain" pastiche).
; Three sustained voices in Bm — bass drone (A), harmonic pad (B),
; slow melodic line (C). Chord progression cycles every ~40 seconds
; while the Batty monologue types out; loops if the monologue runs
; long. Volumes are held soft (~8-11 of 15) for an ambient feel.
;
; Sequence record layout (8 bytes/slot for cheap *8 indexing):
;   +0/+1  Ch A tone period (12-bit)
;   +2/+3  Ch B tone period
;   +4/+5  Ch C tone period
;   +6     hold_frames (1..255)
;   +7     unused
; Terminating slot uses A tone = 0 (loop back to slot 0).
; ===============================================================
ay_init_outro:
    di
    call PLY_AKM_Stop
    ei
    call ay_mute
    ; Mixer: tones A/B/C on, noise off
    ld d, 7
    ld a, %00111000
    call ay_out
    ; Soft ambient volumes: bass 8, pad 10, melody 11 (of 15)
    ld d, 8
    ld a, 8
    call ay_out
    ld d, 9
    ld a, 10
    call ay_out
    ld d, 10
    ld a, 11
    call ay_out
    xor a
    ld (outro_step), a
    ; Fire the first slot on the very next tick
    ld hl, 1
    ld (outro_timer), hl
    ld a, 3
    ld (music_mode), a
    ret

ay_tick_outro_mode:
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
    ; HL now points to hold_frames (+6). Load into outro_timer as a word.
    ld a, (hl)
    ld l, a
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
outro_seq:
    DW 898, 755, 599  : DB 220, 0      ; Bm    B2 D3  F#3
    DW 898, 755, 504  : DB 220, 0      ; Bm7   B2 D3  A3
    DW 1131, 755, 377 : DB 220, 0      ; G     G2 D3  D4  (open voicing)
    DW 1198, 504, 400 : DB 220, 0      ; F#m   F#2 A3 C#4
    DW 898, 599, 449  : DB 220, 0      ; Bm    B2 F#3 B3  (octave)
    DW 672, 565, 449  : DB 220, 0      ; Em    E3 G3  B3
    DW 1008, 800, 672 : DB 220, 0      ; A     A2 C#3 E3
    DW 1198, 504, 400 : DB 220, 0      ; F#m   F#2 A3 C#4  (turnaround)
    DW 0, 0, 0        : DB 0, 0        ; end marker -> loop

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
    xor a                    ; was LD A,#00 — saves 1 byte, 3T
    call ay_out
    ld d, 10
    ld a, 12
    call ay_out
    ld d, 7
    ld a, %00111000
    jp ay_out                ; was CALL+RET — saves 1 byte, 17T

sfx_start_chirp:
    ld a, 4
    ld (sfx_timer), a
    ld d, 4
    ld a, #80
    call ay_out
    ld d, 5
    xor a                    ; was LD A,#00 — saves 1 byte, 3T
    call ay_out
    ld d, 10
    ld a, 14
    call ay_out
    ld d, 7
    ld a, %00111000
    jp ay_out                ; was CALL+RET — saves 1 byte, 17T

sfx_start_ask:
    ld a, 8
    ld (sfx_timer), a
    ld d, 2
    xor a                    ; was LD A,#00 — saves 1 byte, 3T
    call ay_out
    ld d, 3
    ld a, #02
    call ay_out
    ld d, 9
    ld a, 13
    call ay_out
    ld d, 7
    ld a, %00110100
    jp ay_out                ; was CALL+RET — saves 1 byte, 17T

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
    jp ay_out                ; was CALL+RET — saves 1 byte, 17T

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
    jp ay_out                ; was CALL+RET — saves 1 byte, 17T

; ===============================================================
; Beeper 1-bit PCM sample playback.
; Sample data lives in bank 5 (#6000-#68D1) which is always mapped
; regardless of paging state, so no bank tricks are needed here.
; Plays packed 1-bit data (8 samples/byte, MSB first) at ~8 kHz.
; CPU is locked during playback (`di`/`ei`) to keep timing steady.
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
    ret
.sfx_restore_ambient:
    ld d, 7
    ld a, %00111110
    jp ay_out                ; was CALL+RET — saves 1 byte, 17T

; ===============================================================
; Arkos Tracker 3 — AKM minimalist player (pre-compiled with RASM)
; Entry: PLY_AKM_Init = akm_player + 0 (HL=song, A=subsong)
;        PLY_AKM_Play = akm_player + 3
;        PLY_AKM_Stop = akm_player + 6
; ===============================================================
; AKM player binary is position-dependent (compiled by RASM for a fixed address).
; Pad to lock it at #93F8 so internal jumps stay valid after code size changes.
    ASSERT $ <= #93F8, "Code grew past AKM player address — rebuild akm_player.bin with RASM"
    DS #93F8 - $, 0
    DISPLAY "AKM_PLAYER_ORG: ", $
akm_player:
    INCBIN "akm_player.bin"
PLY_AKM_Init EQU akm_player + 0
PLY_AKM_Play EQU akm_player + 3
PLY_AKM_Stop EQU akm_player + 6

    DISPLAY "AKM_SONG_ORG: ", $
akm_song_data:
    INCBIN "title_music_relocated.akm"
