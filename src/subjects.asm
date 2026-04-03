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

; --- Prepare the current subject for this level ---
; Uses level_num (1-100) to pick a difficulty tier (0-4) and
; randomly selects human or android archetype, copying it into
; current_subject. Randomises portrait seed.
prepare_current_subject:
    ; Compute tier = min(4, (level_num - 1) / 20)
    ld a, (level_num)
    dec a                ; 0-99
    ld b, 0
.pcs_div20:
    cp 20
    jr c, .pcs_div_done
    sub 20
    inc b
    jr .pcs_div20
.pcs_div_done:
    ld a, b              ; A = tier 0-4 (or higher if > 100)
    cp 5
    jr c, .pcs_tier_ok
    ld a, 4              ; clamp to 4
.pcs_tier_ok:
    ld (pcs_tier), a

    ; RNG to decide human or android
    push af
    call rng_tick
    and 1
    jr z, .pcs_human
    pop af
    ld hl, subj_table_android
    jr .pcs_copy
.pcs_human:
    pop af
    ld hl, subj_table_human

.pcs_copy:
    ; HL = table base, A = tier; compute HL += tier * SUBJ_SIZE (10)
    or a
    jr z, .pcs_no_offset
    ld b, a
.pcs_mul:
    ld de, SUBJ_SIZE
    add hl, de
    djnz .pcs_mul
.pcs_no_offset:
    ; Copy SUBJ_SIZE bytes from (HL) to current_subject
    ld de, current_subject
    ld bc, SUBJ_SIZE
    ldir

    ; Pick a random name from the pool (10 names)
    call rng_tick
    and #07              ; 0-7 (miss top 2, fine for variety)
    add a, a
    ld e, a
    ld d, 0
    ld hl, subj_name_ptrs
    add hl, de
    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a              ; HL = name string pointer
    ld (current_subject + SUBJ_NAME), hl

    ; Randomise portrait seed
    ld ix, current_subject
    call rng_tick
    ld (ix + SUBJ_PORTRAIT), a
    call rng_tick
    ld (ix + SUBJ_PORTRAIT + 1), a
    ret

pcs_tier: DB 0

; Name pointer table for random selection
subj_name_ptrs:
    DW subj_name_0
    DW subj_name_1
    DW subj_name_2
    DW subj_name_3
    DW subj_name_4
    DW subj_name_5
    DW subj_name_6
    DW subj_name_7
    DW subj_name_8
    DW subj_name_9

; Returns HL = pointer to current_subject (ignores A for compat)
get_subject_ptr:
    ld hl, current_subject
    ret

; A = level (1-100), returns A = penalty per question
; Formula: starts at 5, increases to 20 across 100 levels
get_penalty:
    dec a                ; 0-99
    ; penalty = 5 + (level_index * 15) / 99
    ; Approximate: 5 + level_index / 7 (gives 5..19)
    ld b, 0
.gp_div:
    cp 7
    jr c, .gp_done
    sub 7
    inc b
    jr .gp_div
.gp_done:
    ld a, b
    add a, 5             ; 5 + quotient
    cp 20
    ret c
    ld a, 20             ; clamp
    ret
