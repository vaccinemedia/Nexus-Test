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
mirror_ask_count  EQU intro_hold + 2               ; number of ASKs used on mirror level (caps at 255)

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
    DB "DO ANDROIDS DREAM",1
    DB "OF ELECTRIC SHEEP",1
    DB "OR ONLY OF THEMSELVES",0

boot_menu_lines:
    DB "128        ",0
    DB "Tape Loader",0
    DB "128 BASIC  ",0
    DB "Calculator ",0
    DB "48 BASIC   ",0
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
; Extended Deckard self-reflection lines — unlocked only when the
; player asked the mirror at least MIRROR_ASK_UNLOCK times. They sit
; between "TEARS IN RAIN" and "TIME TO DIE" so an engaged player
; hears the full Vangelis-era coda.
str_deck_1:   DB "I DREAM IN NEON.",0
str_deck_2:   DB "WERE THE MEMORIES EVER MINE?",0
str_deck_3:   DB "THE UNICORN WAS THE ANSWER.",0
str_deck_4:   DB "I MADE HER LIVE. THAT'S ENOUGH.",0
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

    ; ---- Extended coda (indices 10..13). Only entered when the player
    ; has invoked ASK on the mirror level at least MIRROR_ASK_UNLOCK
    ; times; otherwise me_p1 skips straight to "TIME TO DIE".
    DW str_deck_1
    DB 8, 16
    DW 120
    DB ATTR_MIRROR_WHITE, 0

    DW str_deck_2
    DB 2, 17
    DW 100
    DB ATTR_MIRROR_WHITE, 0

    DW str_deck_3
    DB 3, 18
    DW 100
    DB ATTR_MIRROR_WHITE, 0

    DW str_deck_4
    DB 1, 19
    DW 120
    DB ATTR_MIRROR_WHITE, 0

    DW str_batty_11
    DB 10, 21
    DW 180
    DB ATTR_MIRROR_RED, 0

    ; End-of-table sentinel — null text pointer
    DW 0
    DB 0, 0
    DW 0
    DB 0, 0

; Index ranges used by the mirror-level ASK unlock in me_p1.
MIRROR_EXTENDED_START EQU 10                       ; first extended record
MIRROR_EXTENDED_END   EQU 14                       ; str_batty_11 record
MIRROR_ASK_UNLOCK     EQU 6                        ; ASKs needed to unlock extended coda

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

GlitchStringsEnd:
GlitchStringsLen EQU GlitchStringsEnd - GlitchStringsStart
    ASSERT GlitchStringsEnd <= #7EE0, "Glitch strings pushed too close to stack top"
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
