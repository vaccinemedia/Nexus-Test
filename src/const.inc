    IFNDEF CONST_INC_INCLUDED
CONST_INC_INCLUDED EQU 1

; Hardware ports
PORT_BORDER     EQU #fe
PORT_128MEM     EQU #7ffd
PORT_AY_REG     EQU #fffd
PORT_AY_DAT     EQU #bffd

; Screen
PIX_BASE        EQU #4000
ATTR_BASE       EQU #5800

; Game states
ST_TITLE        EQU 0
ST_LEVEL_INTRO  EQU 1
ST_INTERROGATION EQU 2
ST_VERDICT      EQU 3
ST_RESULT       EQU 4
ST_GAMEOVER     EQU 5
ST_HISCORE      EQU 6
ST_GLITCH_MED   EQU 7
ST_GLITCH_CRASH EQU 8
ST_MIRROR_END   EQU 9
ST_INTRO        EQU 10                             ; Blade-Runner-style opening cutscene

; Glitch trigger windows (level number ranges).
; Subtle glitches use a continuous scheduler that ramps with level so
; there's no per-kind window. Only the med (Deckard fragment) and
; crash (fake BASIC boot) tiers still roll a specific level.
GLITCH2_LO      EQU 10
GLITCH2_HI      EQU 14
GLITCH3_LO      EQU 17
GLITCH3_HI      EQU 20
; Threshold levels for the subtle-glitch cadence ramp. Levels below
; GLITCH_FIRST_LEVEL see NO subtle glitches at all — this deliberate
; silence builds a false sense of security before the fourth wall
; starts breaking down. Wait times between fires get shorter as
; level_num crosses each threshold.
GLITCH_FIRST_LEVEL EQU 5                          ; first level any subtle glitch can fire
GLITCH_MID_LEVEL   EQU 13                         ; level >= 13 uses "mid" cadence
GLITCH_LATE_LEVEL  EQU 20                         ; level >= 20 uses "late" cadence
; Level at which the guaranteed WAKE UP ghost text fires (the moment
; the game breaks its silence — right at GLITCH_FIRST_LEVEL so the
; player's first glitch experience is the payoff word).
WAKE_UP_LEVEL      EQU GLITCH_FIRST_LEVEL
; Index (1-based) of "WAKE UP" inside ghost_words; ghost_force_idx uses
; this value to override the random word picker.
GHOST_FORCE_WAKE   EQU 2                          ; ghost_words[1] = gw_wake

; Ink colours (bits 0-2)
INK_BLACK       EQU 0
INK_BLUE        EQU 1
INK_RED         EQU 2
INK_MAG         EQU 3
INK_GREEN       EQU 4
INK_CYAN        EQU 5
INK_YELLOW      EQU 6
INK_WHITE       EQU 7
BRIGHT          EQU 64
FLASH           EQU 128

; Common attribute combos
ATTR_NORMAL     EQU INK_GREEN + (INK_BLACK*8) + BRIGHT
ATTR_HIGHLIGHT  EQU INK_BLACK + (INK_GREEN*8) + BRIGHT
ATTR_TITLE      EQU INK_CYAN + (INK_BLACK*8) + BRIGHT
ATTR_STATUS     EQU INK_YELLOW + (INK_BLACK*8) + BRIGHT
ATTR_RESPONSE   EQU INK_CYAN + (INK_BLACK*8) + BRIGHT
ATTR_QUERY      EQU INK_WHITE + (INK_BLACK*8) + BRIGHT
ATTR_DIVIDER    EQU INK_GREEN + (INK_GREEN*8)
ATTR_CONTROLS   EQU INK_WHITE + (INK_BLACK*8)
ATTR_SELECTED   EQU INK_YELLOW + (INK_BLACK*8) + BRIGHT
ATTR_CORRECT    EQU INK_WHITE + (INK_GREEN*8) + BRIGHT
ATTR_WRONG      EQU INK_WHITE + (INK_RED*8) + BRIGHT
ATTR_GAUGE_LO   EQU INK_GREEN + (INK_GREEN*8) + BRIGHT
ATTR_GAUGE_MID  EQU INK_YELLOW + (INK_YELLOW*8) + BRIGHT
ATTR_GAUGE_HI   EQU INK_RED + (INK_RED*8) + BRIGHT
ATTR_GAUGE_BG   EQU INK_BLACK + (INK_BLACK*8)
ATTR_HISCORE    EQU INK_CYAN + (INK_BLACK*8) + BRIGHT
ATTR_HISCORE_HL EQU INK_WHITE + (INK_BLUE*8) + BRIGHT
ATTR_PUPIL_BLINK EQU INK_RED + (INK_RED*8) + BRIGHT

; ---- ZX Spectrum 128 boot menu (fake-crash glitch) ----------------
; Geometry and colours measured off a screenshot of a real machine, so
; the fake crash is indistinguishable from the genuine boot screen.
; The menu box is 14 columns wide and 7 rows tall: one black title row
; carrying "128" and the rainbow, five menu items, one blank row that
; carries the box's bottom rule.
BOOT_COL_L      EQU 7                              ; box left column
BOOT_COL_R      EQU 20                             ; box right column
BOOT_WIDTH      EQU BOOT_COL_R - BOOT_COL_L + 1
BOOT_ROW_TOP    EQU 7                              ; black title bar
BOOT_ROW_MENU   EQU 8                              ; first menu item
BOOT_ROW_BOT    EQU 13                             ; blank row + bottom rule
BOOT_TEXT_COL   EQU BOOT_COL_L + 1                 ; menu items sit 1 col in
BOOT_RAIN_COL   EQU 15                             ; first rainbow cell
BOOT_RAIN_CELLS EQU 5                              ; cols 15..19
BOOT_COPY_ROW   EQU 23                             ; copyright at screen foot
BOOT_COPY_COL   EQU 2                              ; centres the 28-char line

; Everything outside the box is plain (non-bright) white; the box
; interior is BRIGHT white, which is what makes it stand off the
; background on a real machine.
ATTR_BOOT_BG    EQU INK_BLACK + (INK_WHITE*8)
ATTR_BOOT_BOX   EQU INK_BLACK + (INK_WHITE*8) + BRIGHT
ATTR_BOOT_TITLE EQU INK_WHITE + (INK_BLACK*8) + BRIGHT
ATTR_BOOT_SEL   EQU INK_BLACK + (INK_CYAN*8) + BRIGHT

; How long the menu just sits there before the highlight moves. Two
; seconds of a dead-still boot screen is what sells the crash.
BOOT_HOLD_FRAMES EQU 100

; ---- 128 BASIC editor screen (fake-crash glitch) -----------------
; Also measured off a real machine: plain white paper with black text,
; a black status bar on row 21 carrying "128 BASIC" at column 0 and the
; same rainbow motif at columns 26..30, and a flashing block cursor.
; There is no copyright line and no "0 OK, 0:1" report on this screen.
BAS_BAR_ROW     EQU 21
BAS_RAIN_COL    EQU 26
ATTR_BAS_TEXT   EQU INK_BLACK + (INK_WHITE*8)               ; plain white paper
ATTR_BAS_BAR    EQU INK_WHITE + (INK_BLACK*8) + BRIGHT
; A solid cell of INK with FLASH set alternates ink and paper in
; hardware, giving the editor's blue/white blinking cursor for free.
ATTR_BAS_CURSOR EQU INK_BLUE + (INK_WHITE*8) + BRIGHT + FLASH

; Icon IDs (0-15)
ICON_MEMORY     EQU 0
ICON_FEAR       EQU 1
ICON_PAIN       EQU 2
ICON_JOY        EQU 3
ICON_ANIMAL     EQU 4
ICON_CHILD      EQU 5
ICON_MOTHER     EQU 6
ICON_STRANGER   EQU 7
ICON_TIME       EQU 8
ICON_DEATH      EQU 9
ICON_SELF       EQU 10
ICON_TRUTH      EQU 11
ICON_REPEAT     EQU 12
ICON_DEEPER     EQU 13
ICON_STOP       EQU 14
ICON_FILE       EQU 15
ICON_NONE       EQU #FF

; Question classes
QCLASS_EMOTIONAL  EQU 0
QCLASS_MEMORY     EQU 1
QCLASS_CONTRADICT EQU 2
QCLASS_CALIBRATE  EQU 3

; Key codes returned by read_game_key
KEY_NONE        EQU 0
KEY_UP          EQU 1
KEY_DOWN        EQU 2
KEY_LEFT        EQU 3
KEY_RIGHT       EQU 4
KEY_SELECT      EQU 5
KEY_ENTER       EQU 6
KEY_HUMAN       EQU 7
KEY_ANDROID     EQU 8
KEY_CLEAR       EQU 9

; Subject struct offsets
SUBJ_TYPE       EQU 0
SUBJ_EMPATHY    EQU 1
SUBJ_AGGRESSION EQU 2
SUBJ_STABILITY  EQU 3
SUBJ_DECEPTION  EQU 4
SUBJ_DIFFICULTY EQU 5
SUBJ_PORTRAIT   EQU 6
SUBJ_NAME       EQU 8
SUBJ_SIZE       EQU 10

; Subject types
TYPE_HUMAN      EQU 0
TYPE_ANDROID    EQU 1
TYPE_MIRROR     EQU 2

; Layout constants
GRID_TOP_ROW    EQU 16
PORTRAIT_COL    EQU 0
PORTRAIT_ROW    EQU 2
PORTRAIT_W      EQU 8
PORTRAIT_H      EQU 12
RESPONSE_COL    EQU 9
RESPONSE_ROW    EQU 2       ; first text row (beside portrait); was 3, +1 line for prompts
RESPONSE_W      EQU 23
; Rows [RESPONSE_ROW .. RESPONSE_ROW+RESPONSE_H-1] cleared as dialogue block.
RESPONSE_H      EQU 7
; Interrogator scenario may wrap to multiple lines; subject reply must start BELOW
; this band or it overwrites the tail of the scenario (print_str_box has no row cap).
SCENARIO_LINES      EQU 4
RESPONSE_REPLY_ROW  EQU RESPONSE_ROW + SCENARIO_LINES
QUERY_ROW       EQU 15
STATUS_ROW      EQU 0
MAX_QUERY_ICONS EQU 3
NUM_LEVELS      EQU 25
MIRROR_LEVEL    EQU 25
BASE_SCORE      EQU 100
INTRO_DELAY     EQU 50                             ; ~1s at ~50 Hz — long enough to read the name
STARTING_LIVES  EQU 3

; Voight-Kampff gauge layout
GAUGE_LABEL_COL EQU 9
GAUGE_BAR_COL   EQU 15
GAUGE_BAR_W     EQU 17
PUPIL_ROW       EQU 10
FLUSH_ROW       EQU 11
PATTERN_ROW     EQU 12
QWEIGHT_ROW     EQU 13

; Pattern labels
PAT_STABLE      EQU 0
PAT_SHIFTING    EQU 1
PAT_ERRATIC     EQU 2

; Q-weight levels
QW_LOW          EQU 0
QW_MED          EQU 1
QW_HIGH         EQU 2

; High score
HISCORE_ENTRIES EQU 10
HISCORE_ENTRY_SZ EQU 5

; Attract mode timing (frames at 50fps)
ATTRACT_DELAY   EQU 500

; Bank numbers for paging (bits 0-2 of #7FFD value, with bit 4 set for 48K ROM)
BANK_0_48ROM    EQU #10
BANK_1_48ROM    EQU #11
BANK_3_48ROM    EQU #13
BANK_4_48ROM    EQU #14

    ENDIF
