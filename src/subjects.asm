; subjects.asm — 10 subject archetypes (5 difficulty x human/android)
; Each record: type, empathy, aggression, stability, deception, difficulty, portrait_seed(w), name_ptr(w)
; At game start, RNG picks human or android for each level.

; ---- Human archetypes (D1-D5) ----
subj_table_human:
    ; D1 Human: relaxed, emotionally open
    DB TYPE_HUMAN, 85, 15, 70, 10, 1
    DW #1234
    DW subj_name_0

    ; D2 Human: generally emotional, slightly guarded
    DB TYPE_HUMAN, 72, 25, 65, 20, 2
    DW #5678
    DW subj_name_2

    ; D3 Human: reserved personality, lower amplitude
    DB TYPE_HUMAN, 55, 35, 50, 30, 3
    DW #9ABC
    DW subj_name_4

    ; D4 Human: stressed/anxious, flat gauges from anxiety
    DB TYPE_HUMAN, 40, 55, 30, 15, 4
    DW #DEF0
    DW subj_name_6

    ; D5 Human: complex, guarded, possibly traumatised
    DB TYPE_HUMAN, 30, 45, 25, 45, 5
    DW #ABCD
    DW subj_name_8

; ---- Android archetypes (D1-D5) ----
subj_table_android:
    ; D1 Android (Leon-type): obvious flat, deflects
    DB TYPE_ANDROID, 18, 65, 80, 30, 1
    DW #2345
    DW subj_name_1

    ; D2 Android: better verbal but gauges still flat
    DB TYPE_ANDROID, 28, 50, 75, 50, 2
    DW #6789
    DW subj_name_3

    ; D3 Android: trained mimicry, uniform amplitude
    DB TYPE_ANDROID, 40, 40, 70, 65, 3
    DW #ABCE
    DW subj_name_5

    ; D4 Android: sophisticated, manufactured variance
    DB TYPE_ANDROID, 52, 35, 60, 80, 4
    DW #EF01
    DW subj_name_7

    ; D5 Android (Rachael-type): near-perfect, subtle inversions
    DB TYPE_ANDROID, 65, 20, 55, 92, 5
    DW #BCDE
    DW subj_name_9

; Score penalty per question, indexed by level-1
penalty_table:
    DB 15, 12, 10, 8, 6

; Subject name pool (10 names)
subj_name_0: DB "KIRA VOSS",0
subj_name_1: DB "LEON WRAY",0
subj_name_2: DB "YUKI TANAKA",0
subj_name_3: DB "COLE MERCER",0
subj_name_4: DB "REINA PARK",0
subj_name_5: DB "DANA KENT",0
subj_name_6: DB "ALEX DREEN",0
subj_name_7: DB "NASH OTERI",0
subj_name_8: DB "JUDE SEVRIN",0
subj_name_9: DB "MIRA TYRELL",0

; --- Populate active_subjects from archetype tables using RNG ---
; Called once at game start. For each of the 5 levels, flips a coin
; to pick human or android archetype, then copies SUBJ_SIZE bytes
; into active_subjects. Also randomizes portrait seed.
init_active_subjects:
    ld ix, active_subjects
    ld c, 0             ; level index 0-4
.ias_loop:
    ld a, c
    cp NUM_LEVELS
    ret nc

    push bc

    ; Get RNG bit to decide human (0) or android (1)
    call rng_tick
    and 1
    jr z, .ias_human

    ; Android: source = subj_table_android + c * SUBJ_SIZE
    pop bc
    push bc
    ld a, c
    ld hl, subj_table_android
    jr .ias_copy

.ias_human:
    pop bc
    push bc
    ld a, c
    ld hl, subj_table_human

.ias_copy:
    ; HL = table base, A = level index; compute HL += A * SUBJ_SIZE (10)
    or a
    jr z, .ias_no_offset
    ld b, a
.ias_mul:
    ld de, SUBJ_SIZE
    add hl, de
    djnz .ias_mul
.ias_no_offset:
    ; Copy SUBJ_SIZE bytes from (HL) to (IX)
    ld b, SUBJ_SIZE
.ias_cp_byte:
    ld a, (hl)
    ld (ix+0), a
    inc hl
    inc ix
    djnz .ias_cp_byte

    ; Randomize portrait seed for this subject (overwrite bytes at offset 6-7)
    push ix
    ld de, -SUBJ_SIZE + SUBJ_PORTRAIT
    add ix, de
    call rng_tick
    ld (ix+0), a
    call rng_tick
    ld (ix+1), a
    pop ix

    pop bc
    inc c
    jr .ias_loop

; Look up active subject record: A = level (1-5), returns HL = pointer
get_subject_ptr:
    dec a
    ld l, a
    ld h, 0
    ld c, l
    ld b, h
    add hl, hl
    add hl, hl
    add hl, bc
    add hl, hl         ; HL = (level-1) * 10
    ld bc, active_subjects
    add hl, bc
    ret

; A = level (1-5), returns A = penalty per question
get_penalty:
    dec a
    ld hl, penalty_table
    ld c, a
    ld b, 0
    add hl, bc
    ld a, (hl)
    ret
