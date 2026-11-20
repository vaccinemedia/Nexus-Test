; ay_music.asm — AY-3-8912 driver
; Title: Arkos Tracker 3 AKM player
; In-game: 4-beat decaying bass (A), B/C for SFX
; AY clock 1773400 Hz; period = 1773400/(16*freq)

; ---- Register write (used by ambient/SFX modes) ----
; D = register 0-15, A = value
; Selecting the register and writing it must not be split by the music
; interrupt, which writes AY registers too. Interrupts are only re-enabled
; if they were on, so this is also safe inside the interrupt routine.
ay_out:
    push af
    ld a, i                  ; P/V = IFF2
    jp po, .ints_off
    di
    pop af
    call ay_write
    ei
    ret
.ints_off:
    pop af
ay_write:
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

; Silences the AY and stops the music interrupt driving it.
ay_mute:
    xor a
    ld (music_mode), a
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
outro_fade_step:  db 0     ; 0=silent, ramps up to 11 during fade-in
outro_fade_ticks: db 0     ; frames until next fade step
; Melody sequencer state — Ch C plays a 32-note phrase over the
; 8-chord loop (4 notes per chord slot). Runs independently of the
; chord tick so the melodic line breathes across chord changes.
melody_step:   db 0
melody_timer:  db 0

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
SFX_TYPE      EQU 6                        ; short noise blip — typewriter key strike

; ---- Title music: Arkos Tracker AKM player ----
ay_init_title:
    xor a
    ld (sfx_timer), a
    ld (sfx_id), a
    ld hl, akm_song_data
    di
    call PLY_AKM_Init
    ld a, 1                  ; only now may the interrupt play it
    ld (music_mode), a
    ei
    ret

; ---- Music tick: run by music_isr every frame, interrupts off ----
ay_tick_music:
    ld a, (music_mode)
    cp 1
    jp z, PLY_AKM_Play
    cp 2
    jp z, ay_tick_ambient_mode
    cp 3
    jp z, ay_tick_outro_mode
    ret

; ---- Interrupt-driven music ----
; IM 2 with I = #39: the 48K ROM holds #FF from #3900 to #3A00, so every
; interrupt vectors to #FFFF whatever the data bus holds. The JR there
; takes the ROM's first byte (#F3) as its offset and lands on IM2_STUB,
; which jumps here. I stays out of #40-#7F, which upsets the 128K's ULA.
music_isr:
    push af
    push bc
    push de
    push hl
    ex af, af'
    push af
    exx
    push bc
    push de
    push hl
    push ix
    push iy
    call ay_tick_music
    pop iy
    pop ix
    pop hl
    pop de
    pop bc
    exx
    pop af
    ex af, af'
    pop hl
    pop de
    pop bc
    pop af
    ei
    reti

; Starts IM 2, with the bank now at #C000 given the stub.
music_isr_setup:
    call music_isr_stub
    ld a, IM2_I
    ld i, a
    im 2
    ei
    ret

; Writes the #FFF4/#FFFF stub into the bank at #C000.
music_isr_stub:
    ld a, #C3                ; JP music_isr
    ld (IM2_STUB), a
    ld hl, music_isr
    ld (IM2_STUB + 1), hl
    ld a, #18                ; JR -> IM2_STUB
    ld (#FFFF), a
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
    xor a
    ld (bass_step), a
    ld a, 1
    ld (bass_timer), a
    ld a, 2
    ld (music_mode), a
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

; ay_init_outro / ay_tick_outro_mode / outro_fade_tick / outro_seq
; live in ay_outro.asm (included after the AKM song data) so this
; ~250-byte block doesn't push the pre-#93F8 code past the position-
; dependent AKM player address.

; ---- SFX trigger: A = SFX_xxx ----
ay_play_sfx:
    di                       ; the music interrupt ticks sfx_timer
    call .start
    ei
    ret
.start:
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
    cp SFX_TYPE
    jp z, sfx_start_type
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

; ---------------------------------------------------------------
; SFX_TYPE — mechanical typewriter key strike. Very short high-
; hiss noise burst on Ch C only (no tone). Fires once per printed
; character during the ST_INTRO cutscene so text lands with an
; audible click. Lasts 2 frames (~40 ms) so successive blips at
; ~60 ms/char cadence read as click-click-click.
; ---------------------------------------------------------------
sfx_start_type:
    ld a, 2                              ; ~40 ms burst
    ld (sfx_timer), a
    ld d, 6                              ; R6 = noise period
    ld a, 4                              ; small = high-pitched hiss (mid-treble)
    call ay_out
    ld d, 10                             ; R10 = Ch C volume
    ld a, 10                             ; audible but not shouty
    call ay_out
    ld d, 7                              ; R7 = mixer
    ld a, %00011111                      ; noise-C only (all tones off, noise A/B off)
    jp ay_out

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
    DISPLAY "Pre-AKM padding (spare bytes below #93F8): ", /D, #93F8 - $
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
