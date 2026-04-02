; Nexus Test — ZX Spectrum 128K interrogation game
; sjasmplus compatible; builds .sna and .tap
    DEVICE ZXSPECTRUM128
    ORG #7fff
    DB 1
    ORG #8000
    INCLUDE "const.inc"

Entry:
    di
    ld sp, #fff8
    call ay_mute
    call verify_paging
    call video_home_128
    call init_custom_font
    call title_init
    xor a
    ld (game_state), a

MainLoop:
    call wait_frame

    ld a, (game_state)
    or a
    jp z, .ml_title
    cp ST_LEVEL_INTRO
    jp z, .ml_intro
    cp ST_INTERROGATION
    jp z, .ml_interrog
    cp ST_VERDICT
    jp z, .ml_verdict
    cp ST_GAMEOVER
    jp z, .ml_gameover
    cp ST_HISCORE
    jp z, .ml_hiscore
    jr MainLoop

.ml_title:
    call title_frame
    jr MainLoop
.ml_intro:
    call level_intro_frame
    jr MainLoop
.ml_interrog:
    call interrogation_frame
    jr MainLoop
.ml_verdict:
    call verdict_frame
    jr MainLoop
.ml_gameover:
    call gameover_frame
    jr MainLoop
.ml_hiscore:
    call hiscore_frame
    jr MainLoop

    ; ---- Source modules ----
    INCLUDE "zx_sys.asm"
    INCLUDE "draw.asm"
    INCLUDE "input.asm"
    INCLUDE "ay_music.asm"
    INCLUDE "portrait.asm"
    INCLUDE "question.asm"
    INCLUDE "subjects.asm"
    INCLUDE "data_text.asm"
    INCLUDE "title.asm"
    INCLUDE "game.asm"
    INCLUDE "hiscore.asm"

    ; ---- Global variables ----
paging_ok:       DB 0
game_state:      DB 0
screen_drawn:    DB 0
key_held:        DB 0
rng_seed:        DW #A55A

level_num:       DB 1
total_score:     DW 0
questions_asked: DB 0
cursor_x:        DB 0
cursor_y:        DB 0
query_count:     DB 0
query_icons:     DB ICON_NONE, ICON_NONE, ICON_NONE
current_subj:    DW 0

; Voight-Kampff gauge state
pupil_gauge:     DB 0
flush_gauge:     DB 0
prev_pupil:      DB 0, 0, 0
prev_flush:      DB 0, 0, 0
q_weight:        DB 0
pattern_flag:    DB 0
blink_timer:     DB 0

; Active subjects for this playthrough (5 x SUBJ_SIZE)
active_subjects: DS NUM_LEVELS * SUBJ_SIZE

; Response assembly buffer (128 bytes)
response_buffer: DS 128

; Attract mode
attract_timer:   DW 0

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
    INCLUDE "loader_basic.inc"
LoaderBasicLen EQU LoaderBasicEnd - LoaderBasic

    SAVESNA "nexus.sna", Entry
    EMPTYTAP "nexus.tap"
    SAVETAP "nexus.tap", BASIC, "nexus", LoaderBasic, LoaderBasicLen, 10
    SAVETAP "nexus.tap", CODE, "nexus", Entry, GameCodeEnd - Entry, #8000
    END Entry
