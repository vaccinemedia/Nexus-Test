; RASM wrapper to pre-compile the Arkos Tracker AKM player
; ORG is passed via -DAKM_ORG=xxxx on the RASM command line

    org AKM_ORG

PLY_AKM_HARDWARE_SPECTRUM = 1

    include "title_music_playerconfig.asm"
    include "PlayerAkm_rasm.asm"
