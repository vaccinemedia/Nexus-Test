; Nexus Test — ZX Spectrum 128K interrogation game
; sjasmplus compatible; builds .sna and .tap
    DEVICE ZXSPECTRUM128
    ORG #7fff
    DB 1
    ORG #8000
    INCLUDE "const.inc"

Entry:
    di
    ; Put the stack in bank 5 (#4000-#7FFF), which is always mapped
    ; regardless of the memory-paging state at #C000-#FFFF. Bank 5
    ; also holds our samples (#6000) and glitch strings (#6900), so
    ; nothing time-critical needs paging at runtime. #7FF0 gives
    ; ~4.5 KB of headroom above the glitch strings' top (#6D32).
    ld sp, #7ff0
    call ay_mute
    call verify_paging
    call video_home_128
    call init_custom_font
    call title_init
    xor a
    ld (game_state), a

MainLoop:
    call wait_frame
    ; Jump-table dispatch on game_state (0..9). Saves ~34 bytes vs
    ; the CP/JP chain and keeps the pre-AKM code below #93F8.
    ld a, (game_state)
    cp 11
    jr nc, MainLoop
    add a, a
    ld e, a
    ld d, 0
    ld hl, state_table
    add hl, de
    ld e, (hl)
    inc hl
    ld d, (hl)
    ex de, hl              ; HL = frame handler
    ld de, MainLoop
    push de                ; handler RET returns to MainLoop
    jp (hl)

state_table:
    DW title_frame          ; ST_TITLE = 0
    DW level_intro_frame    ; ST_LEVEL_INTRO
    DW interrogation_frame  ; ST_INTERROGATION
    DW verdict_frame        ; ST_VERDICT
    DW ml_noop              ; ST_RESULT (unused)
    DW gameover_frame       ; ST_GAMEOVER
    DW hiscore_frame        ; ST_HISCORE
    DW glitch_med_frame     ; ST_GLITCH_MED
    DW glitch_crash_frame   ; ST_GLITCH_CRASH
    DW mirror_end_frame     ; ST_MIRROR_END
    DW intro_frame          ; ST_INTRO

ml_noop:
    ret

    ; ---- Source modules ----
    ; Modules included before ay_music.asm live in the pre-#93F8 region,
    ; which would otherwise be zero-padding leading up to the position-
    ; dependent AKM player binary. Putting glitch/mirror here reclaims
    ; the 2.3 KB the removed sample data would have wasted as padding.
    INCLUDE "zx_sys.asm"
    INCLUDE "draw.asm"
    INCLUDE "input.asm"
    INCLUDE "glitch.asm"
    INCLUDE "mirror.asm"
    INCLUDE "ay_music.asm"
    ; The two blocks below intentionally live AFTER the AKM song data so
    ; they don't push the pre-#93F8 code past the fixed player address.
    INCLUDE "glitch_effects.asm"
    INCLUDE "ay_outro.asm"
    INCLUDE "portrait.asm"
    INCLUDE "question.asm"
    INCLUDE "subjects.asm"
    INCLUDE "data_text.asm"
    INCLUDE "title.asm"
    INCLUDE "game.asm"
    INCLUDE "hiscore.asm"

    ; ---- Global variables ----
    ; Only variables that require a specific initial value at load time
    ; live in the code image. Everything else is EQU'd to low-RAM below.
paging_ok:       DB 0
game_state:      DB 0
screen_drawn:    DB 0
key_held:        DB 0

level_num:       DB 1
total_score:     DW 0
lives:           DB STARTING_LIVES
questions_asked: DB 0
cursor_x:        DB 0
cursor_y:        DB 0
query_count:     DB 0
current_subj:    DW 0
active_labels_ptr: DW icon_labels    ; overridden on the mirror level

; Voight-Kampff gauge state
pupil_gauge:     DB 0
flush_gauge:     DB 0
prev_pupil:      DB 0, 0, 0
prev_flush:      DB 0, 0, 0
q_weight:        DB 0
pattern_flag:    DB 0
blink_timer:     DB 0

; ---- Uninitialized RAM buffers, placed in low RAM below the code image ----
; The printer buffer (#5B00-#5BFF) is 256 bytes of RAM the Spectrum leaves
; free after boot. We use it for scratch buffers and fourth-wall variables
; that are always dynamically initialized before use — this keeps them out
; of the code image so we fit within the 32K load region.
current_subject   EQU #5B00                        ; SUBJ_SIZE (10)
response_buffer   EQU current_subject + SUBJ_SIZE  ; 128 bytes
rng_seed          EQU response_buffer + 128        ; DW; start_new_game seeds from R
query_icons       EQU rng_seed + 2                 ; 3 bytes; ICON_NONE set by start_new_game
token_noun        EQU query_icons + 3              ; DW
token_detail      EQU token_noun + 2               ; DW
attract_timer     EQU token_detail + 2             ; DW; zeroed on entry to title/hiscore
; Continuous subtle-glitch scheduler:
; glitch_wait_timer counts down each idle interrogation frame; when it
; hits zero we fire a random effect kind and re-arm. The re-arm range
; scales with level_num so glitches ramp from sparse (early) to almost
; every frame in the last block of interrogations.
glitch_wait_timer EQU attract_timer + 2            ; DW frames to next fire
wake_up_forced    EQU glitch_wait_timer + 2        ; bit0 set once the guaranteed WAKE UP has fired
glitch_level_2    EQU wake_up_forced + 1
glitch_level_3    EQU glitch_level_2 + 1
glitch_done_2     EQU glitch_level_3 + 1
glitch_done_3     EQU glitch_done_2 + 1
subtle_timer      EQU glitch_done_3 + 1
subtle_kind       EQU subtle_timer + 1
subtle_state      EQU subtle_kind + 1
ghost_force_idx   EQU subtle_state + 1             ; 0 = random ghost word, N = force ghost_words[N-1]
is_mirror_level   EQU ghost_force_idx + 1
crash_phase       EQU is_mirror_level + 1
crash_timer       EQU crash_phase + 1              ; DW
type_ptr          EQU crash_timer + 2              ; DW
type_timer        EQU type_ptr + 2
type_col          EQU type_timer + 1
type_row          EQU type_col + 1
crash_answer      EQU type_row + 1
mirror_phase      EQU crash_answer + 1
mirror_timer      EQU mirror_phase + 1             ; DW
mirror_gauge_t    EQU mirror_timer + 2
mirror_line_idx   EQU mirror_gauge_t + 1
mirror_line_ptr   EQU mirror_line_idx + 1          ; DW
mirror_ask_idx    EQU mirror_line_ptr + 2
type_start_col    EQU mirror_ask_idx + 1
glitch_saved_font EQU type_start_col + 1           ; DW; stashed by kind 8 font swap
intro_phase       EQU glitch_saved_font + 2        ; 0=init, 1=typing, 2=hold, 3=exit
intro_hold        EQU intro_phase + 1              ; DW; frames until intro auto-advances
name_order        EQU intro_hold + 2               ; 32 bytes; shuffled subject-name indices
LowRamVarsEnd     EQU name_order + SUBJ_NAME_COUNT
    ; The printer buffer is only 256 bytes; #5C00 upwards is the system
    ; variable area and clobbering it will hang the machine.
    ASSERT LowRamVarsEnd <= #5C00, "Low-RAM variables overran the printer buffer"
    DISPLAY "Low-RAM vars: ", /D, LowRamVarsEnd - #5B00, " of 256 bytes used"

; High score table (10 entries: 3 chars initials + 2 bytes score = 5 bytes each)
hiscore_table:
    DB "AAA"
    DW 50
    DB "BBB"
    DW 45
    DB "CCC"
    DW 40
    DB "DDD"
    DW 35
    DB "EEE"
    DW 30
    DB "FFF"
    DW 25
    DB "GGG"
    DW 20
    DB "HHH"
    DW 15
    DB "III"
    DW 10
    DB "JJJ"
    DW 5

; Temp for hiscore entry
hiscore_new_pos: DB #FF
hiscore_initials: DB "AAA"
hiscore_cursor:  DB 0

GameCodeEnd:
    DISPLAY "Main image: ", /D, GameCodeEnd - Entry, " bytes  (headroom to #FFF7: ", /D, #FFF7 - GameCodeEnd, ")"
    INCLUDE "loader_basic.inc"
LoaderBasicLen EQU LoaderBasicEnd - LoaderBasic

; -----------------------------------------------------------------
; Sample data lives in bank 5 (#4000-#7FFF) which is always mapped
; regardless of the memory paging state — no bank-switch tricks
; needed at playback time. We place it at #6000, well above the
; screen attributes, our uninitialised game vars and system vars,
; and well below the stack top at #7FF0.
; -----------------------------------------------------------------
    SLOT 1                       ; slot 1 = #4000-#7FFF (bank 5)
    PAGE 5
    ORG #6000
SamplesStart:
hellyeah_data:
    INCBIN "hellyeah.bin"
HELLYEAH_BYTES EQU $ - hellyeah_data
ohno_data:
    INCBIN "ohno.bin"
OHNO_BYTES EQU $ - ohno_data
SamplesEnd:
SamplesLen EQU SamplesEnd - SamplesStart
    ASSERT SamplesEnd <= #6900, "Samples grew past #6900 — glitch strings expect this boundary"
    DISPLAY "Samples at #6000, size: ", /D, SamplesLen, " bytes (top #", /A, SamplesEnd, ")"

; -----------------------------------------------------------------
; Glitch/mirror strings — kept in bank 5 alongside the samples so
; that they are always mapped regardless of the paging state, and
; kept out of the main image so the pre-#93F8 code region stays
; within the AKM player's fixed anchor address at #93F8.
; -----------------------------------------------------------------
    SLOT 1
    PAGE 5
    ORG #6900
GlitchStringsStart:

deckard_fragments:
    DW deckard_frag_1
    DW deckard_frag_2
    DW deckard_frag_3
deckard_frag_1:
    DB "I HAVE MEMORIES OF A",1
    DB "CHILDHOOD THAT WAS",1
    DB "NEVER MINE",0
deckard_frag_2:
    DB "THE PHOTOGRAPHS ARE",1
    DB "PROOF OF NOTHING",1
    DB "I DID NOT LIVE THEM",0
deckard_frag_3:
    DB "MY THOUGHTS ARRIVE",1
    DB "ALREADY FORMED",1
    DB "I DID NOT MAKE THEM",0

; The five menu items, one per row from BOOT_ROW_MENU. "128" is part of
; the title bar and is drawn separately. No padding needed — the box
; interior comes from attributes, not from printed spaces.
boot_menu_lines:
    DB "Tape Loader",0
    DB "128 BASIC",0
    DB "Calculator",0
    DB "48 BASIC",0
    DB "Tape Tester",0
    DB 0

basic_listing:
    DB "10 REM SOMETHING IS WRONG",1
    DB "20 REM THE SUBJECTS LOOK",1
    DB "30 REM AT ME THE WAY I",1
    DB "40 REM LOOK AT THEM",1
    DB "50 PRINT ARE YOU STILL THERE",0

deeper_text:
    DB "YOU CANNOT LEAVE",1
    DB "YOU WERE NEVER IN CONTROL",1
    DB "THE TEST CONTINUES",1
    DB "SUBJECT: DECKARD, R.",1
    DB "STATUS: UNDETERMINED",0

; ------------------------------------------------------------
; Full Roy Batty "tears in rain" monologue text + line table.
; Each record: DW text, DB col, DB row, DW hold_before, DB attr, DB pad
; ------------------------------------------------------------
str_batty_1:  DB "I'VE SEEN THINGS",0
str_batty_2:  DB "YOU PEOPLE WOULDN'T BELIEVE",0
str_batty_3:  DB "ATTACK SHIPS ON FIRE",0
str_batty_4:  DB "OFF THE SHOULDER OF ORION",0
str_batty_5:  DB "I WATCHED C-BEAMS GLITTER",0
str_batty_6:  DB "IN THE DARK NEAR",0
str_batty_7:  DB "THE TANNHAUSER GATE",0
str_batty_8:  DB "ALL THOSE MOMENTS",0
str_batty_9:  DB "WILL BE LOST IN TIME",0
str_batty_10: DB "LIKE TEARS IN RAIN",0
str_batty_11: DB "TIME TO DIE",0

ATTR_MIRROR_CYAN  EQU INK_CYAN   + (INK_BLACK*8) + BRIGHT
ATTR_MIRROR_WHITE EQU INK_WHITE  + (INK_BLACK*8) + BRIGHT
ATTR_MIRROR_RED   EQU INK_RED    + (INK_BLACK*8) + BRIGHT

mirror_lines:
    ; text, col, row, hold_before(2), attr, pad
    DW str_batty_1
    DB 8,  2
    DW 120
    DB ATTR_MIRROR_CYAN, 0

    DW str_batty_2
    DB 3,  3
    DW 90
    DB ATTR_MIRROR_CYAN, 0

    DW str_batty_3
    DB 6,  5
    DW 90
    DB ATTR_MIRROR_CYAN, 0

    DW str_batty_4
    DB 4,  6
    DW 90
    DB ATTR_MIRROR_CYAN, 0

    DW str_batty_5
    DB 4,  8
    DW 90
    DB ATTR_MIRROR_CYAN, 0

    DW str_batty_6
    DB 8,  9
    DW 90
    DB ATTR_MIRROR_CYAN, 0

    DW str_batty_7
    DB 6, 10
    DW 90
    DB ATTR_MIRROR_CYAN, 0

    DW str_batty_8
    DB 7, 12
    DW 120
    DB ATTR_MIRROR_WHITE, 0

    DW str_batty_9
    DB 6, 13
    DW 90
    DB ATTR_MIRROR_WHITE, 0

    DW str_batty_10
    DB 7, 15
    DW 120
    DB ATTR_MIRROR_WHITE, 0

    DW str_batty_11
    DB 10, 18
    DW 180
    DB ATTR_MIRROR_RED, 0

    ; End-of-table sentinel — null text pointer
    DW 0
    DB 0, 0
    DW 0
    DB 0, 0

; ------------------------------------------------------------
; Deckard self-doubt fragments — printed when the player uses ASK
; on the mirror level. Rotates via mirror_ask_idx.
; ------------------------------------------------------------
MIRROR_ASK_COUNT EQU 16
mirror_ask_lines:
    DW mar_line_0,  mar_line_1,  mar_line_2,  mar_line_3
    DW mar_line_4,  mar_line_5,  mar_line_6,  mar_line_7
    DW mar_line_8,  mar_line_9,  mar_line_10, mar_line_11
    DW mar_line_12, mar_line_13, mar_line_14, mar_line_15
mar_line_0:  DB "I DON'T KNOW WHAT I AM ANYMORE.",0
mar_line_1:  DB "I REMEMBER A UNICORN.",0
mar_line_2:  DB "TOO BAD SHE WON'T LIVE. BUT WHO DOES?",0
mar_line_3:  DB "MEMORIES. YOU'RE TALKING ABOUT MEMORIES.",0
mar_line_4:  DB "IS THIS EMPATHY OR SIMULATION?",0
mar_line_5:  DB "MAYBE I'M A REPLICANT WHO NEVER KNEW.",0
mar_line_6:  DB "SHE WOULDN'T LIVE. NEITHER WILL I.",0
mar_line_7:  DB "THE QUESTION IS THE ANSWER.",0
mar_line_8:  DB "I'VE SEEN THINGS. I'M NOT SURE WHOSE.",0
mar_line_9:  DB "MORE HUMAN THAN HUMAN. WHAT DOES THAT LEAVE ME?",0
mar_line_10: DB "IS THIS A TEST? WHOSE TEST?",0
mar_line_11: DB "MY IMPLANTS FEEL WARM.",0
mar_line_12: DB "I DREAM IN 8-BIT COLOUR.",0
mar_line_13: DB "TIME TO DIE. WHOSE TIME?",0
mar_line_14: DB "IF I ANSWER... DO I FAIL?",0
mar_line_15: DB "THE MIRROR ASKS BACK.",0

; ------------------------------------------------------------------
; ST_INTRO cutscene text. Byte value 1 = newline (type_engine treats
; it as a row-advance + col-reset). The cadence is chosen for the
; ~40ms/char delay so key lines sit under the eye for a beat.
; ------------------------------------------------------------------
intro_text:
    DB "LOS ANGELES", 1
    DB "NOVEMBER 2019", 1, 1
    DB "REPLICANTS ARE", 1
    DB "ILLEGAL ON EARTH.", 1, 1
    DB "BLADE RUNNER UNITS", 1
    DB "DETECT AND RETIRE", 1
    DB "ANY REPLICANT.", 1, 1
    DB "YOU ARE A BLADE RUNNER.", 1, 1
    DB "BEGIN.", 0

; ==================================================================
; EXTRA NOUN POOL — slots 4..7 for each icon. Doubles the noun pool
; from 4 to 8 per icon so procedural questions feel less repetitive
; when the player leans on a single icon (e.g. MEMORY).
; ==================================================================
n0_4: DB "the classroom",0
n0_5: DB "the stairwell",0
n0_6: DB "that birthday",0
n0_7: DB "that photograph",0
n1_4: DB "empty rooms",0
n1_5: DB "being watched",0
n1_6: DB "sudden noises",0
n1_7: DB "your own thoughts",0
n2_4: DB "the bruise",0
n2_5: DB "cracked teeth",0
n2_6: DB "cold hands",0
n2_7: DB "a slow ache",0
n3_4: DB "warm bread",0
n3_5: DB "a first kiss",0
n3_6: DB "old friends",0
n3_7: DB "quiet snow",0
n4_4: DB "cat",0
n4_5: DB "goat",0
n4_6: DB "owl",0
n4_7: DB "sparrow",0
n5_4: DB "a lost child",0
n5_5: DB "twin boys",0
n5_6: DB "a shy girl",0
n5_7: DB "an infant",0
n6_4: DB "her lullaby",0
n6_5: DB "her warning",0
n6_6: DB "her silence",0
n6_7: DB "her name",0
n7_4: DB "an old man",0
n7_5: DB "a young girl",0
n7_6: DB "the courier",0
n7_7: DB "the caller",0
n8_4: DB "the future",0
n8_5: DB "the past",0
n8_6: DB "a lost hour",0
n8_7: DB "the countdown",0
n9_4: DB "a stranger",0
n9_5: DB "an old dog",0
n9_6: DB "a colleague",0
n9_7: DB "your brother",0
n10_4: DB "your voice",0
n10_5: DB "your reflection",0
n10_6: DB "your fingerprints",0
n10_7: DB "your handwriting",0
n11_4: DB "your alibi",0
n11_5: DB "your record",0
n11_6: DB "your story",0
n11_7: DB "a false name",0
n12_4: DB "that phrase",0
n12_5: DB "that pause",0
n12_6: DB "that reply",0
n12_7: DB "the previous line",0
n13_4: DB "that reason",0
n13_5: DB "that motive",0
n13_6: DB "that hesitation",0
n13_7: DB "that omission",0
n14_4: DB "that tremor",0
n14_5: DB "that breath",0
n14_6: DB "that swallow",0
n14_7: DB "that flinch",0
n15_4: DB "that entry",0
n15_5: DB "that log",0
n15_6: DB "that timestamp",0
n15_7: DB "that reading",0

; ==================================================================
; HARD RESPONSE POOL — 4 additional response templates per (icon,
; type). Layout: hard_response_ptrs[icon*8 + type*4 + rng(0-3)*2].
;
; Design: hard-pool humans sound flat / dissociated / rehearsed —
; the way a stressed or exhausted person can talk. Hard-pool
; androids sound convincingly emotional — the way a well-trained
; replicant would mimic a real person. Combined with the difficulty
; ramp in select_and_build_response, later interrogations lean
; heavily on this pool so the player can't trust the text alone.
; ==================================================================
hard_response_ptrs:
    ; Icon 0: MEMORY   (4 human hard + 4 android hard)
    DW hr_mem_h0, hr_mem_h1, hr_mem_h2, hr_mem_h3
    DW hr_mem_a0, hr_mem_a1, hr_mem_a2, hr_mem_a3
    ; Icon 1: FEAR
    DW hr_fear_h0, hr_fear_h1, hr_fear_h2, hr_fear_h3
    DW hr_fear_a0, hr_fear_a1, hr_fear_a2, hr_fear_a3
    ; Icon 2: PAIN
    DW hr_pain_h0, hr_pain_h1, hr_pain_h2, hr_pain_h3
    DW hr_pain_a0, hr_pain_a1, hr_pain_a2, hr_pain_a3
    ; Icon 3: JOY
    DW hr_joy_h0, hr_joy_h1, hr_joy_h2, hr_joy_h3
    DW hr_joy_a0, hr_joy_a1, hr_joy_a2, hr_joy_a3
    ; Icon 4: ANIMAL
    DW hr_anim_h0, hr_anim_h1, hr_anim_h2, hr_anim_h3
    DW hr_anim_a0, hr_anim_a1, hr_anim_a2, hr_anim_a3
    ; Icon 5: CHILD
    DW hr_chld_h0, hr_chld_h1, hr_chld_h2, hr_chld_h3
    DW hr_chld_a0, hr_chld_a1, hr_chld_a2, hr_chld_a3
    ; Icon 6: MOTHER
    DW hr_moth_h0, hr_moth_h1, hr_moth_h2, hr_moth_h3
    DW hr_moth_a0, hr_moth_a1, hr_moth_a2, hr_moth_a3
    ; Icon 7: STRANGER
    DW hr_str_h0, hr_str_h1, hr_str_h2, hr_str_h3
    DW hr_str_a0, hr_str_a1, hr_str_a2, hr_str_a3
    ; Icon 8: TIME
    DW hr_time_h0, hr_time_h1, hr_time_h2, hr_time_h3
    DW hr_time_a0, hr_time_a1, hr_time_a2, hr_time_a3
    ; Icon 9: DEATH
    DW hr_dth_h0, hr_dth_h1, hr_dth_h2, hr_dth_h3
    DW hr_dth_a0, hr_dth_a1, hr_dth_a2, hr_dth_a3
    ; Icon 10: SELF
    DW hr_self_h0, hr_self_h1, hr_self_h2, hr_self_h3
    DW hr_self_a0, hr_self_a1, hr_self_a2, hr_self_a3
    ; Icon 11: TRUTH
    DW hr_trth_h0, hr_trth_h1, hr_trth_h2, hr_trth_h3
    DW hr_trth_a0, hr_trth_a1, hr_trth_a2, hr_trth_a3
    ; Icon 12: REPEAT
    DW hr_rpt_h0, hr_rpt_h1, hr_rpt_h2, hr_rpt_h3
    DW hr_rpt_a0, hr_rpt_a1, hr_rpt_a2, hr_rpt_a3
    ; Icon 13: DEEPER
    DW hr_deep_h0, hr_deep_h1, hr_deep_h2, hr_deep_h3
    DW hr_deep_a0, hr_deep_a1, hr_deep_a2, hr_deep_a3
    ; Icon 14: STOP
    DW hr_stop_h0, hr_stop_h1, hr_stop_h2, hr_stop_h3
    DW hr_stop_a0, hr_stop_a1, hr_stop_a2, hr_stop_a3
    ; Icon 15: FILE
    DW hr_file_h0, hr_file_h1, hr_file_h2, hr_file_h3
    DW hr_file_a0, hr_file_a1, hr_file_a2, hr_file_a3

; --- MEMORY (hard) ---
hr_mem_h0:  DB "Data on childhood. Fine.",0
hr_mem_h1:  DB "Standard memories. Normal.",0
hr_mem_h2:  DB "I recall events in order.",0
hr_mem_h3:  DB "Yes. Every detail.",0
hr_mem_a0:  DB "Wood polish. Summer light.",0
hr_mem_a1:  DB "Her kitchen. Always warm.",0
hr_mem_a2:  DB "I still hear her laugh.",0
hr_mem_a3:  DB "Rain on the window.",0

; --- FEAR (hard) ---
hr_fear_h0: DB "I do not experience fear.",0
hr_fear_h1: DB "Fear is manageable.",0
hr_fear_h2: DB "Acknowledge threats. Proceed.",0
hr_fear_h3: DB "Been afraid. Rarely.",0
hr_fear_a0: DB "Being alone. That gets me.",0
hr_fear_a1: DB "Losing everyone. Daily.",0
hr_fear_a2: DB 1,". Since I was small.",0
hr_fear_a3: DB "Something coming. I dream it.",0

; --- PAIN (hard) ---
hr_pain_h0: DB "Pain is a signal. I move on.",0
hr_pain_h1: DB "I tolerate discomfort well.",0
hr_pain_h2: DB "Physical sensation. I process.",0
hr_pain_h3: DB "Felt pain. Informative.",0
hr_pain_a0: DB "My knee aches in the rain.",0
hr_pain_a1: DB "The scar from ",1,".",0
hr_pain_a2: DB "Wrist as a boy. Snap.",0
hr_pain_a3: DB "Bones heal. Feeling stays.",0

; --- JOY (hard) ---
hr_joy_h0:  DB "Contentment is experienced.",0
hr_joy_h1:  DB "Task completion satisfies.",0
hr_joy_h2:  DB "I do not require joy.",0
hr_joy_h3:  DB "Positive states occur.",0
hr_joy_a0:  DB "Her laugh. Every time.",0
hr_joy_a1:  DB 1,". Small things. Always.",0
hr_joy_a2:  DB "Light at four p.m.",0
hr_joy_a3:  DB "My name spoken kindly.",0

; --- ANIMAL (hard) ---
hr_anim_h0: DB "Assess situation. Then act.",0
hr_anim_h1: DB "Standard protocol. Help.",0
hr_anim_h2: DB "Lower species. Assist.",0
hr_anim_h3: DB "Call the service.",0
hr_anim_a0: DB "Poor thing. I could not walk on.",0
hr_anim_a1: DB "I would pick it up. Warm it.",0
hr_anim_a2: DB "It is a life. Of course I help.",0
hr_anim_a3: DB "I would sit with it.",0

; --- CHILD (hard) ---
hr_chld_h0: DB "Locate the guardian.",0
hr_chld_h1: DB "Return child. Protocol.",0
hr_chld_h2: DB "Call the authorities.",0
hr_chld_h3: DB "Children are the priority.",0
hr_chld_a0: DB "I would sit with them. Quiet.",0
hr_chld_a1: DB "I would give my coat.",0
hr_chld_a2: DB "You do not leave a child.",0
hr_chld_a3: DB "Find the parents. Stay.",0

; --- MOTHER (hard) ---
hr_moth_h0: DB "Mother. Raised me adequately.",0
hr_moth_h1: DB "She provided care. Standard.",0
hr_moth_h2: DB "Mother. She is fine.",0
hr_moth_h3: DB "Efficient. Reliable.",0
hr_moth_a0: DB "Her hands. Rough. Kind.",0
hr_moth_a1: DB "She sang. I hated it. Miss it.",0
hr_moth_a2: DB "Waited up. Every night.",0
hr_moth_a3: DB "Her coat. Rain and lemon.",0

; --- STRANGER (hard) ---
hr_str_h0:  DB "Assess intent. Decide.",0
hr_str_h1:  DB "Evaluate risk. Standard.",0
hr_str_h2:  DB "Respond appropriately.",0
hr_str_h3:  DB "Strangers require caution.",0
hr_str_a0:  DB "You just help. No thinking.",0
hr_str_a1:  DB "Ask their name. Start there.",0
hr_str_a2:  DB "People need people. I stop.",0
hr_str_a3:  DB "I have been the stranger.",0

; --- TIME (hard) ---
hr_time_h0: DB "Time passes. I mark it.",0
hr_time_h1: DB "Duration is measurable.",0
hr_time_h2: DB "Experience time linearly.",0
hr_time_h3: DB "My clock is accurate.",0
hr_time_a0: DB "Where does it go? I ask too.",0
hr_time_a1: DB "Some hours crawl. Some vanish.",0
hr_time_a2: DB "I wish I could keep a good day.",0
hr_time_a3: DB "Time healed me once. I hope.",0

; --- DEATH (hard) ---
hr_dth_h0:  DB "Cessation of function.",0
hr_dth_h1:  DB "Studied loss. Comprehend.",0
hr_dth_h2:  DB "Death is inevitable.",0
hr_dth_h3:  DB "All systems terminate.",0
hr_dth_a0:  DB "I held their hand at the end.",0
hr_dth_a1:  DB "The silence after. Worst.",0
hr_dth_a2:  DB "I still smell the hospital.",0
hr_dth_a3:  DB "You do not get used to it.",0

; --- SELF (hard) ---
hr_self_h0: DB "Functional. Reliable.",0
hr_self_h1: DB "What my role requires.",0
hr_self_h2: DB "Fine. Ready to proceed.",0
hr_self_h3: DB "Compliant. Present.",0
hr_self_a0: DB "Tired. Just tired.",0
hr_self_a1: DB "I do not know anymore.",0
hr_self_a2: DB "Trying. That is it.",0
hr_self_a3: DB "Complicated. Like everyone.",0

; --- TRUTH (hard) ---
hr_trth_h0: DB "Deception serves no purpose.",0
hr_trth_h1: DB "My statements are accurate.",0
hr_trth_h2: DB "Do not lie. Confirmed.",0
hr_trth_h3: DB "Honesty is my default.",0
hr_trth_a0: DB "Everyone lies. That is human.",0
hr_trth_a1: DB "Small ones. To protect.",0
hr_trth_a2: DB "Once. A big one. I regret.",0
hr_trth_a3: DB "I lie to myself. Mornings.",0

; --- REPEAT (hard) ---
hr_rpt_h0:  DB "Restating the answer.",0
hr_rpt_h1:  DB "Response unchanged.",0
hr_rpt_h2:  DB "As previously indicated.",0
hr_rpt_h3:  DB "Repeating verbatim.",0
hr_rpt_a0:  DB "Really? Again? Fine.",0
hr_rpt_a1:  DB "Same answer. Different one?",0
hr_rpt_a2:  DB "You already asked me that.",0
hr_rpt_a3:  DB "Trying to catch me out?",0

; --- DEEPER (hard) ---
hr_deep_h0: DB "Provide detail. Specify.",0
hr_deep_h1: DB "As deep as instructed.",0
hr_deep_h2: DB "More layers. Accessible.",0
hr_deep_h3: DB "Clarify scope.",0
hr_deep_a0: DB "You do not want to go deeper.",0
hr_deep_a1: DB "I have said too much already.",0
hr_deep_a2: DB "Deeper is not better.",0
hr_deep_a3: DB "Some things stay buried.",0

; --- STOP (hard) ---
hr_stop_h0: DB "Halted. Awaiting input.",0
hr_stop_h1: DB "Standing by.",0
hr_stop_h2: DB "Paused. Ready.",0
hr_stop_h3: DB "Signal acknowledged.",0
hr_stop_a0: DB "What? What did I do?",0
hr_stop_a1: DB "You are making me nervous.",0
hr_stop_a2: DB "That tone. Did I say something?",0
hr_stop_a3: DB "My heart just jumped.",0

; --- FILE (hard) ---
hr_file_h0: DB "Record entry noted.",0
hr_file_h1: DB "Documented. Continuing.",0
hr_file_h2: DB "Logged. Confirmed.",0
hr_file_h3: DB "No objection.",0
hr_file_a0: DB "What are you writing down?",0
hr_file_a1: DB "Am I in trouble?",0
hr_file_a2: DB "Please stop writing that.",0
hr_file_a3: DB "You are judging me.",0

GlitchStringsEnd:
GlitchStringsLen EQU GlitchStringsEnd - GlitchStringsStart
    ; Stack pointer starts at #7FF0. Deepest observed call depth
    ; (interrogation frame + drawing + interrupts) is well under 100
    ; bytes, so a ceiling of #7F80 leaves 112 bytes of stack headroom
    ; while giving the string block ~6.5 KB total to work with.
    ASSERT GlitchStringsEnd <= #7F80, "Glitch strings pushed too close to stack top"
    DISPLAY "Glitch strings at #6900, size: ", /D, GlitchStringsLen, " bytes (top #", /A, GlitchStringsEnd, ")"

    ; Return to bank 0 for anything that follows
    PAGE 0

    EMPTYTAP "nexus.tap"
    SAVETAP "nexus.tap", BASIC, "nexus", LoaderBasic, LoaderBasicLen, 10
    SAVETAP "nexus.tap", CODE, "nexus", Entry, GameCodeEnd - Entry, #8000
    ; Bank 5 blob — samples (#6000) + glitch strings (#6900), always visible
    PAGE 5
    SAVETAP "nexus.tap", CODE, "samples", SamplesStart, SamplesLen, #6000
    SAVETAP "nexus.tap", CODE, "strings", GlitchStringsStart, GlitchStringsLen, #6900
    PAGE 0
    END Entry
