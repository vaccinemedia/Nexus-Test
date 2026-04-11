; question.asm — Voight-Kampff engine: classification, gauges, pattern, fragments

; Classify selected icons into a question class.
; Reads query_icons and query_count. Returns A = QCLASS_xxx.
classify_query:
    ld a, (query_count)
    or a
    ld a, QCLASS_CALIBRATE
    ret z

    ; Check if any procedural icon (12-15) is present -> calibration
    ld b, 3
    ld hl, query_icons
.cq_check_proc:
    ld a, (hl)
    cp ICON_NONE
    jr z, .cq_skip_proc
    cp 12
    jr nc, .cq_is_calib
.cq_skip_proc:
    inc hl
    djnz .cq_check_proc
    jr .cq_not_calib
.cq_is_calib:
    ld a, QCLASS_CALIBRATE
    ret

.cq_not_calib:
    ; Check if any abstract icon (8-11) -> contradiction test
    ld b, 3
    ld hl, query_icons
.cq_check_abs:
    ld a, (hl)
    cp ICON_NONE
    jr z, .cq_skip_abs
    cp 8
    jr c, .cq_skip_abs
    cp 12
    jr c, .cq_is_contra
.cq_skip_abs:
    inc hl
    djnz .cq_check_abs
    jr .cq_not_contra
.cq_is_contra:
    ld a, QCLASS_CONTRADICT
    ret

.cq_not_contra:
    ; Check if any relational icon (4-7) -> memory probe
    ld b, 3
    ld hl, query_icons
.cq_check_rel:
    ld a, (hl)
    cp ICON_NONE
    jr z, .cq_skip_rel
    cp 4
    jr c, .cq_skip_rel
    cp 8
    jr c, .cq_is_mem
.cq_skip_rel:
    inc hl
    djnz .cq_check_rel

    ; Default: emotional trigger (all icons 0-3)
    ld a, QCLASS_EMOTIONAL
    ret
.cq_is_mem:
    ld a, QCLASS_MEMORY
    ret

; ================================================================
; Compute emotional weight of the current query (0-100).
; Based on which icons are selected and their inherent weight.
; Returns A = weight, also stores in q_weight global.
; ================================================================
compute_q_weight:
    ld hl, query_icons
    ld b, 3
    ld c, 0             ; accumulator
.cqw_lp:
    ld a, (hl)
    cp ICON_NONE
    jr z, .cqw_skip
    push hl
    push bc
    ld e, a
    ld d, 0
    ld hl, icon_weights
    add hl, de
    ld a, (hl)
    pop bc
    add a, c
    ld c, a
    pop hl
.cqw_skip:
    inc hl
    djnz .cqw_lp
    ; c = sum of icon weights. Clamp to 100.
    ld a, c
    cp 101
    jr c, .cqw_ok
    ld a, 100
.cqw_ok:
    ld (q_weight), a
    ret

; Emotional weight per icon (0-15). Higher = more provocative.
icon_weights:
    DB 30   ; MEMORY
    DB 40   ; FEAR
    DB 45   ; PAIN
    DB 20   ; JOY
    DB 35   ; ANIMAL
    DB 38   ; CHILD
    DB 50   ; MOTHER
    DB 25   ; STRANGER
    DB 15   ; TIME
    DB 45   ; DEATH
    DB 30   ; SELF
    DB 35   ; TRUTH
    DB 5    ; REPEAT
    DB 10   ; DEEPER
    DB 5    ; STOP
    DB 5    ; FILE

; ================================================================
; Compute dual gauge readings (pupil + flush) for the current question.
; HL = current_subj pointer. A = question class.
; Stores results in pupil_gauge and flush_gauge (0-32 range for bar display).
; Also shifts previous readings and updates pattern_flag.
; ================================================================
compute_gauges:
    ld (cg_class), a
    ld (cg_subj), hl

    ; Shift previous gauge history
    ld a, (prev_pupil+1)
    ld (prev_pupil+2), a
    ld a, (prev_pupil)
    ld (prev_pupil+1), a
    ld a, (pupil_gauge)
    ld (prev_pupil), a
    ld a, (prev_flush+1)
    ld (prev_flush+2), a
    ld a, (prev_flush)
    ld (prev_flush+1), a
    ld a, (flush_gauge)
    ld (prev_flush), a

    ; Get subject type and relevant stats
    ld hl, (cg_subj)
    ld a, (hl)          ; type
    ld (cg_type), a
    inc hl
    ld a, (hl)          ; empathy
    ld (cg_empathy), a
    inc hl
    ld a, (hl)          ; aggression
    ld (cg_aggression), a
    inc hl
    ld a, (hl)          ; stability
    ld (cg_stability), a
    inc hl
    ld a, (hl)          ; deception
    ld (cg_deception), a
    inc hl
    ld a, (hl)          ; difficulty
    ld (cg_difficulty), a

    ; Get emotional weight
    ld a, (q_weight)
    ld (cg_weight), a

    ; --- Compute base pupil gauge ---
    ; For humans: pupil ~ weight * empathy / 100, scaled to 0-32
    ; For androids: pupil is damped/inverted based on difficulty
    ld a, (cg_type)
    or a
    jr nz, .cg_android_pupil

    ; Human pupil: proportional to weight, modulated by empathy
    ld a, (cg_weight)
    ld b, a
    ld a, (cg_empathy)
    call mul8_hi         ; A ~ (weight * empathy) >> 8, range 0-39
    ld b, a
    ; Add noise +/- 4
    push bc
    call rng_tick
    pop bc
    and 7
    sub 4
    add a, b
    jr .cg_pupil_done

.cg_android_pupil:
    ; Android pupil: inversely proportional on hard questions (empathy mismatch)
    ; Base: low response, plus deception masking
    ld a, (cg_weight)
    ld b, a
    ld a, (cg_deception)
    call mul8_hi         ; A ~ (weight * deception) >> 8
    ld b, a
    ; Rachael-type inversion: for D5, react MORE to low weight, LESS to high
    ld a, (cg_difficulty)
    cp 5
    jr nz, .cg_andr_no_inv
    ; Invert: gauge = 20 - base_gauge
    ld a, 20
    sub b
    jr nc, .cg_andr_inv_ok
    xor a
.cg_andr_inv_ok:
    ld b, a
.cg_andr_no_inv:
    ; Add small noise (less than human)
    push bc
    call rng_tick
    pop bc
    and 3
    sub 2
    add a, b

.cg_pupil_done:
    ; Clamp 0 to GAUGE_BAR_W (17)
    jr nc, .cg_p_no_under
    xor a
.cg_p_no_under:
    cp GAUGE_BAR_W + 1
    jr c, .cg_p_no_over
    ld a, GAUGE_BAR_W
.cg_p_no_over:
    ld (pupil_gauge), a

    ; --- Compute base flush gauge ---
    ; For humans: flush ~ weight * (100 - stability) / 100, with noise
    ; For androids: flush is too stable / too even
    ld a, (cg_type)
    or a
    jr nz, .cg_android_flush

    ; Human flush: emotional arousal from instability
    ld a, 100
    ld b, a
    ld a, (cg_stability)
    ld c, a
    ld a, b
    sub c               ; A = 100 - stability (higher = more reactive)
    ld (cg_temp), a     ; save instability
    ld a, (cg_weight)
    ld b, a             ; B = weight
    ld a, (cg_temp)     ; A = instability
    call mul8_hi        ; A = (instability * weight) >> 8
    ld b, a
    ; Add noise +/- 5
    push bc
    call rng_tick
    pop bc
    and #0f
    sub 5
    add a, b
    jr .cg_flush_done

.cg_android_flush:
    ; Android flush: suspiciously even, scaled by deception
    ld a, (cg_deception)
    srl a
    srl a
    srl a               ; deception / 8 -> 0-12 range
    ld b, a
    ; D4+ androids add synthetic variance
    ld a, (cg_difficulty)
    cp 4
    jr c, .cg_andr_flush_flat
    push bc
    call rng_tick
    pop bc
    and 7
    sub 3
    add a, b
    jr .cg_flush_done
.cg_andr_flush_flat:
    ; Low difficulty: very flat, minimal noise
    push bc
    call rng_tick
    pop bc
    and 1
    add a, b

.cg_flush_done:
    ; Clamp 0 to GAUGE_BAR_W (17)
    jr nc, .cg_f_no_under
    xor a
.cg_f_no_under:
    cp GAUGE_BAR_W + 1
    jr c, .cg_f_no_over
    ld a, GAUGE_BAR_W
.cg_f_no_over:
    ld (flush_gauge), a

    ; --- Compute pattern flag ---
    call compute_pattern
    ret

; Temporaries for compute_gauges
cg_class:      DB 0
cg_subj:       DW 0
cg_type:       DB 0
cg_empathy:    DB 0
cg_aggression: DB 0
cg_stability:  DB 0
cg_deception:  DB 0
cg_difficulty: DB 0
cg_weight:     DB 0
cg_temp:       DB 0

; ================================================================
; 8-bit multiply high byte: A = (A * B) >> 8
; For inputs 0-100, result is 0-39 — good for gauge range 0-32.
; Inputs: A, B. Returns A. Clobbers HL, DE, B.
; ================================================================
; Fully unrolled — saves 106T per call (+33 bytes)
mul8_hi:
    ld d, 0
    ld e, b
    ld h, d
    ld l, d
    add hl, hl
    add a, a
    jr nc, .m8_1
    add hl, de
.m8_1:
    add hl, hl
    add a, a
    jr nc, .m8_2
    add hl, de
.m8_2:
    add hl, hl
    add a, a
    jr nc, .m8_3
    add hl, de
.m8_3:
    add hl, hl
    add a, a
    jr nc, .m8_4
    add hl, de
.m8_4:
    add hl, hl
    add a, a
    jr nc, .m8_5
    add hl, de
.m8_5:
    add hl, hl
    add a, a
    jr nc, .m8_6
    add hl, de
.m8_6:
    add hl, hl
    add a, a
    jr nc, .m8_7
    add hl, de
.m8_7:
    add hl, hl
    add a, a
    jr nc, .m8_8
    add hl, de
.m8_8:
    ld a, h
    ret

; ================================================================
; Compute pattern: compares last 3 pupil readings for consistency.
; STABLE = all within 5 of each other, ERRATIC = max diff > 15,
; otherwise SHIFTING.
; Stores result in pattern_flag (0/1/2).
; ================================================================
compute_pattern:
    ; Only meaningful after 2+ questions
    ld a, (questions_asked)
    cp 2
    jr nc, .cp_go
    ld a, PAT_SHIFTING
    ld (pattern_flag), a
    ret
.cp_go:
    ; Find max and min of prev_pupil[0..2]
    ld a, (prev_pupil)
    ld b, a              ; min
    ld c, a              ; max
    ld a, (prev_pupil+1)
    cp b
    jr nc, .cp1_not_min
    ld b, a
.cp1_not_min:
    cp c
    jr c, .cp1_not_max
    ld c, a
.cp1_not_max:
    ld a, (prev_pupil+2)
    cp b
    jr nc, .cp2_not_min
    ld b, a
.cp2_not_min:
    cp c
    jr c, .cp2_not_max
    ld c, a
.cp2_not_max:
    ; diff = max - min
    ld a, c
    sub b
    ; A = difference
    cp 5
    jr nc, .cp_not_stable
    ld a, PAT_STABLE
    ld (pattern_flag), a
    ret
.cp_not_stable:
    cp 15
    jr nc, .cp_erratic
    ld a, PAT_SHIFTING
    ld (pattern_flag), a
    ret
.cp_erratic:
    ld a, PAT_ERRATIC
    ld (pattern_flag), a
    ret

; ================================================================
; Token engine constants
; ================================================================
TK_NOUN   EQU 1          ; template marker: insert token_noun
TK_DETAIL EQU 2          ; template marker: insert token_detail

; ================================================================
; Pick random noun and detail tokens for an icon.
; A = icon index (0-15). Sets token_noun and token_detail.
; ================================================================
pick_icon_tokens:
    push af
    ; Noun: noun_ptrs + icon*8 + rng(0-3)*2
    add a, a
    add a, a
    add a, a             ; A = icon*8
    ld d, 0
    ld e, a
    push de
    call rng_tick
    pop de
    and 3
    add a, a
    add a, e
    ld e, a
    ld hl, noun_ptrs
    add hl, de
    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a
    ld (token_noun), hl

    ; Detail: detail_ptrs + icon*4 + rng(0-1)*2
    pop af
    add a, a
    add a, a             ; A = icon*4
    ld d, 0
    ld e, a
    push de
    call rng_tick
    pop de
    and 1
    add a, a
    add a, e
    ld e, a
    ld hl, detail_ptrs
    add hl, de
    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a
    ld (token_detail), hl
    ret

; ================================================================
; Expand a template string into response_buffer.
; HL = template pointer. Bytes 1/2 are replaced with token strings.
; Returns HL = response_buffer.
; ================================================================
expand_template:
    ld de, response_buffer
.et_loop:
    ld a, (hl)
    or a
    jr z, .et_end
    cp TK_NOUN
    jr z, .et_noun
    cp TK_DETAIL
    jr z, .et_detail
    ld (de), a
    inc de
    inc hl
    jr .et_loop
.et_noun:
    push hl
    ld hl, (token_noun)
    call .et_copy
    pop hl
    inc hl
    jr .et_loop
.et_detail:
    push hl
    ld hl, (token_detail)
    call .et_copy
    pop hl
    inc hl
    jr .et_loop
.et_end:
    xor a
    ld (de), a
    ld hl, response_buffer
    ret
.et_copy:
    ld a, (hl)
    or a
    ret z
    ld (de), a
    inc hl
    inc de
    jr .et_copy

; ================================================================
; Pick a random scenario template for an icon, expand with tokens.
; A = icon index. Returns HL = response_buffer (expanded string).
; ================================================================
pick_and_expand_scenario:
    ; scenario_tmpl_ptrs + icon*8 + rng(0-3)*2
    add a, a
    add a, a
    add a, a             ; A = icon*8
    ld d, 0
    ld e, a
    push de
    call rng_tick
    pop de
    and 3
    add a, a
    add a, e
    ld e, a
    ld hl, scenario_tmpl_ptrs
    add hl, de
    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a              ; HL = template pointer
    jp expand_template   ; tail call, returns HL = response_buffer

; ================================================================
; Select response template and expand with tokens.
; Uses first icon, subject type, and RNG.
; Returns HL = response_buffer (expanded string).
; ================================================================
select_and_build_response:
    ld hl, (current_subj)
    ld a, (hl)
    ld (sr_subj_type), a

    ld a, (query_icons)
    cp ICON_NONE
    jr nz, .sr_has_icon
    xor a
.sr_has_icon:
    ; icon * 16
    add a, a
    add a, a
    add a, a
    add a, a
    ld d, a

    ; type * 8
    ld a, (sr_subj_type)
    add a, a
    add a, a
    add a, a
    add a, d
    ld d, a              ; D = icon*16 + type*8

    push de
    call rng_tick
    pop de
    and 7
    add a, d             ; A = final index (0-255)

    ld l, a
    ld h, 0
    add hl, hl
    ld de, icon_response_ptrs
    add hl, de
    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a              ; HL = template pointer
    jp expand_template   ; expand and return HL = response_buffer

sr_subj_type:  DB 0

; Simple RNG
rng_tick:
    push bc
    ld hl, (rng_seed)
    ld a, h
    xor l
    ld b, a
    add hl, hl
    add hl, hl
    add hl, hl
    ld a, l
    xor b
    ld l, a
    ld de, #1597
    add hl, de
    ld (rng_seed), hl
    ld a, l
    pop bc
    ret
