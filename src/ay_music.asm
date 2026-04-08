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
    call ay_out
    ret

; ---- Music mode: 0=off, 1=title, 2=ambient ----
music_mode:   db 0

; Bass sequencer state (ambient mode)
bass_timer:   db 0
bass_step:    db 0

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
    ret
.sfx_restore_ambient:
    ld d, 7
    ld a, %00111110
    call ay_out
    ret

; ===============================================================
; Arkos Tracker 3 — AKM minimalist player (pre-compiled with RASM)
; Entry: PLY_AKM_Init = akm_player + 0 (HL=song, A=subsong)
;        PLY_AKM_Play = akm_player + 3
;        PLY_AKM_Stop = akm_player + 6
; ===============================================================
    DISPLAY "AKM_PLAYER_ORG: ", $
akm_player:
    INCBIN "akm_player.bin"
PLY_AKM_Init EQU akm_player + 0
PLY_AKM_Play EQU akm_player + 3
PLY_AKM_Stop EQU akm_player + 6

    DISPLAY "AKM_SONG_ORG: ", $
akm_song_data:
    INCBIN "title_music_relocated.akm"
