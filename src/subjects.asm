; subjects.asm — 10 subject archetypes (5 difficulty x human/android)
; Each record: type, empathy, aggression, stability, deception, difficulty, portrait_seed(w), name_ptr(w)
; At game start, RNG picks human or android for each level.
;
; The name_ptr in these archetypes is a placeholder: prepare_current_subject
; always replaces it from the shuffled name order, and the mirror level
; substitutes its own. It only exists to keep the record SUBJ_SIZE bytes.

; ---- Human archetypes (D1-D5) ----
subj_table_human:
    ; D1 Human: relaxed, emotionally open
    DB TYPE_HUMAN, 85, 15, 70, 10, 1
    DW #1234
    DW subj_names

    ; D2 Human: generally emotional, slightly guarded
    DB TYPE_HUMAN, 72, 25, 65, 20, 2
    DW #5678
    DW subj_names

    ; D3 Human: reserved personality, lower amplitude
    DB TYPE_HUMAN, 55, 35, 50, 30, 3
    DW #9ABC
    DW subj_names

    ; D4 Human: stressed/anxious, flat gauges from anxiety
    DB TYPE_HUMAN, 40, 55, 30, 15, 4
    DW #DEF0
    DW subj_names

    ; D5 Human: complex, guarded, possibly traumatised
    DB TYPE_HUMAN, 30, 45, 25, 45, 5
    DW #ABCD
    DW subj_names

; ---- Android archetypes (D1-D5) ----
subj_table_android:
    ; D1 Android (Leon-type): obvious flat, deflects
    DB TYPE_ANDROID, 18, 65, 80, 30, 1
    DW #2345
    DW subj_names

    ; D2 Android: better verbal but gauges still flat
    DB TYPE_ANDROID, 28, 50, 75, 50, 2
    DW #6789
    DW subj_names

    ; D3 Android: trained mimicry, uniform amplitude
    DB TYPE_ANDROID, 40, 40, 70, 65, 3
    DW #ABCE
    DW subj_names

    ; D4 Android: sophisticated, manufactured variance
    DB TYPE_ANDROID, 52, 35, 60, 80, 4
    DW #EF01
    DW subj_names

    ; D5 Android (Rachael-type): near-perfect, subtle inversions
    DB TYPE_ANDROID, 65, 20, 55, 92, 5
    DW #BCDE
    DW subj_names

; =============================================================
; Subject name pool — 32 names, fixed 12-byte records so an index
; can address them arithmetically with no pointer table.
;
; A playthrough shuffles the indices and takes the first 25, so no
; name repeats within a game and each game draws a different subset.
; 32 is deliberate: it makes the shuffle's index unbiased with a
; plain AND, and leaves 7 names spare so replays don't feel canned.
;
; Names must be 11 characters or fewer to leave room for the
; terminator. SNAME pads each record and the ASSERT below catches
; anything too long. SUBJ_NAME_LEN/COUNT live in const.inc.
; =============================================================
    MACRO SNAME s?
    DB s?
    DS SUBJ_NAME_LEN - (($ - subj_names) % SUBJ_NAME_LEN), 0
    ENDM

subj_names:
    SNAME "KIRA VOSS"
    SNAME "LEON WRAY"
    SNAME "YUKI TANAKA"
    SNAME "COLE MERCER"
    SNAME "REINA PARK"
    SNAME "DANA KENT"
    SNAME "ALEX DREEN"
    SNAME "NASH OTERI"
    SNAME "JUDE SEVRIN"
    SNAME "MIRA TYRELL"
    SNAME "ANJA HOLT"
    SNAME "SEV OKONKWO"
    SNAME "IRIS CHANDA"
    SNAME "MARCO REYES"
    SNAME "TESS LUND"
    SNAME "OMAR BEQUET"
    SNAME "LENA STROUD"
    SNAME "KAI SOLBERG"
    SNAME "NOOR HASSEL"
    SNAME "VIC ANSELM"
    SNAME "ESME KOVAL"
    SNAME "BRAM DELACY"
    SNAME "SUNI RAVAL"
    SNAME "HALE MORROW"
    SNAME "PIA LINDROS"
    SNAME "GIL ASTRAND"
    SNAME "ZOE HARKER"
    SNAME "IVO SALAZAR"
    SNAME "RUTH VANCE"
    SNAME "EDEN MARSH"
    SNAME "TOMA VESELY"
    SNAME "ADA CRANMER"
    ASSERT $ - subj_names == SUBJ_NAME_LEN * SUBJ_NAME_COUNT, "Subject name longer than 11 chars, or wrong name count"
    DISPLAY "Subject names: ", /D, SUBJ_NAME_COUNT, " records, ", /D, $ - subj_names, " bytes"

; --- Prepare the current subject for this level ---
; Uses level_num (1-25) to pick a difficulty tier (0-4) and
; randomly selects human or android archetype, copying it into
; current_subject. Randomises portrait seed.
prepare_current_subject:
    ; Compute tier = min(4, (level_num - 1) / 5)
    ; 25-level layout: L1-5=T0, L6-10=T1, L11-15=T2, L16-20=T3, L21-25=T4
    ld a, (level_num)
    dec a                ; 0-24
    ld b, 0
.pcs_div5:
    cp 5
    jr c, .pcs_div_done
    sub 5
    inc b
    jr .pcs_div5
.pcs_div_done:
    ld a, b              ; A = tier 0-4
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

    ; Name comes from the shuffled order rather than a fresh random
    ; draw, so no two subjects in a playthrough share a name.
    ld a, (level_num)
    dec a
    and SUBJ_NAME_COUNT - 1        ; level_num is 1..25, so this is a guard
    ld e, a
    ld d, 0
    ld hl, name_order
    add hl, de
    ld l, (hl)                     ; L = name index 0..31
    ld h, 0
    ; HL = subj_names + index*12  (12 = 8 + 4)
    add hl, hl
    add hl, hl                     ; index*4
    ld d, h
    ld e, l
    add hl, hl                     ; index*8
    add hl, de                     ; index*12
    ld de, subj_names
    add hl, de
    ld (current_subject + SUBJ_NAME), hl

    ; Randomise portrait seed
    ld ix, current_subject
    call rng_tick
    ld (ix + SUBJ_PORTRAIT), a
    call rng_tick
    ld (ix + SUBJ_PORTRAIT + 1), a

    ; Fix this subject's value now, so the intro screen and the verdict
    ; score from the same numbers. Worth rises with the level and so does
    ; the cost of each question: later subjects pay more but punish
    ; dithering harder.
    ld a, (level_num)
    call get_penalty
    ld (subj_penalty), a
    ld a, (level_num)
    dec a
    add a, a
    add a, a                       ; (level - 1) * WORTH_STEP
    ASSERT WORTH_STEP == 4, "subject worth is computed with two doublings"
    ASSERT BASE_SCORE + (NUM_LEVELS - 1) * WORTH_STEP <= 255, "subject worth no longer fits a byte"
    add a, BASE_SCORE
    ld (subj_worth), a
    ret

pcs_tier: DB 0

; =============================================================
; shuffle_subject_names — called once from start_new_game.
;
; Seeds name_order with 0..31 then deals it with Fisher-Yates, so the
; game can take the first 25 entries and get 25 distinct names.
;
; A single "swap every slot with any slot" pass would be shorter, but it
; leaves the tail of the pool drawn ~8% less often than the head, so the
; last names in the table would show up noticeably more rarely.
;
; Fisher-Yates needs an index in 0..i rather than 0..31, and that index is
; taken by reducing the RNG byte modulo i+1. The obvious alternative —
; drawing 0..31 and re-rolling anything above i — must NOT be used here:
; rng_tick has closed cycles (e.g. from state #0AD6) that never produce a
; value <= 1, so the re-roll would hang the machine at game start.
; See tools/check_rng_cycles.py.
;
; rng_tick corrupts HL and DE (it preserves only BC), so i is kept in C
; and both addresses are rebuilt for each swap.
; =============================================================
shuffle_subject_names:
    ld hl, name_order
    ld b, SUBJ_NAME_COUNT
    xor a
.ssn_fill:
    ld (hl), a
    inc hl
    inc a
    djnz .ssn_fill

    ld c, SUBJ_NAME_COUNT - 1      ; C = i, working down to 1
.ssn_outer:
    call rng_tick
    ld b, c
    inc b                          ; B = i+1, the divisor (always >= 2)
.ssn_mod:
    cp b
    jr c, .ssn_got
    sub b
    jr .ssn_mod
.ssn_got:
    ld e, a
    ld d, 0
    ld hl, name_order
    add hl, de
    push hl                        ; &order[j]
    ld e, c
    ld d, 0
    ld hl, name_order
    add hl, de                     ; &order[i]
    pop de
    ld a, (de)
    ld b, (hl)
    ld (hl), a
    ld a, b
    ld (de), a
    dec c
    jr nz, .ssn_outer
    ret

; Returns HL = pointer to current_subject (ignores A for compat)
get_subject_ptr:
    ld hl, current_subject
    ret

; A = level (1-25), returns A = penalty per question
; 25-level curve: starts at 5, rises to 20 by the final tier
get_penalty:
    dec a                ; 0-24
    cp 25
    jr c, .gp_ok
    ld a, 24
.gp_ok:
    ld e, a
    ld d, 0
    ld hl, penalty_table
    add hl, de
    ld a, (hl)
    ret
; penalty_table lives in bank 5 (see nexus.asm).
