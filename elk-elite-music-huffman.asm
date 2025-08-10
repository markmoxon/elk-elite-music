OSBYTE                  = $FFF4 
SHEILA_COUNTER          = $FE06
SHEILA_MISC_CONTROL     = $FE07

;GUARD &89
;ORG &79
;
;.zp_start
;    .track_start            SKIP 2
;    INCLUDE "lib/huffman.h.asm"
;.zp_end
;
;ORG &3000
;GUARD &6000

;ORG &0000  ; Use this for Electron Elite
ORG &70     ; USE FOR BASIC player.bas ONLY!

.zp_start
.huffmunch_zpblock  SKIP 4      ; Share with four-byte RAND
.zp_end

ORG &0E00       ; MM - assemble music and driver at start of
GUARD &1D00     ;      available memory in Electron

.start

.jumptable
    jmp init_tune1      ; &3000
    jmp init_tune2      ; &3003
    jmp poll_track      ; &3006

.init_tune1
    ldx #<tune_data1_start
    stx track_start
    stx huffmunch_zpblock

    ldx #>tune_data1_start
    stx track_start+1
    stx huffmunch_zpblock+1

    jmp DRIVER_INIT

.init_tune2
    ldx #<tune_data2_start
    stx track_start
    stx huffmunch_zpblock

    ldx #>tune_data2_start
    stx track_start+1
    stx huffmunch_zpblock+1

    jmp DRIVER_INIT

.poll_track
    jmp DRIVER_PLAY

; MM - move non-zp variables here

.huffmunch_block    SKIP 5
.page_bytes         SKIP 2
.byte_ptr           SKIP 2
.track_start        SKIP 2

INCLUDE "lib/huffman.s.asm"
INCLUDE "drivers/huffman.asm"

.tune_data1_start
    INCBIN "music/00_Elite_Theme.huf"
.tune_data1_end

PRINT "HUFFMAN"
PRINT "-------"
PRINT ""
PRINT "      Tune 1 size is ",P%-tune_data1_start,"bytes"

.tune_data2_start
\    INCBIN "music/01_Blue_Danube.huf"
.tune_data2_end

PRINT "      Tune 2 size is ",P%-tune_data2_start,"bytes"

H%=P%
ALIGN 256
PRINT "           Alignment lost ",(P%-H%),"bytes"

.end

PRINT "           Total size is ",(end-start),"bytes"
PRINT ""

PRINT "Code ends at ", ~end

SAVE "DRIVER", start, end, start
PUTFILE "BOOT","!BOOT",&FFFF
PUTBASIC "player.bas","PLAYER"