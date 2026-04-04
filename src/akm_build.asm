; RASM wrapper to pre-compile the Arkos Tracker AKM player
; Assembled at the target address where it will be placed in the game

    org #93EF

PLY_AKM_HARDWARE_SPECTRUM = 1

    include "title_music_playerconfig.asm"
    include "PlayerAkm_rasm.asm"
