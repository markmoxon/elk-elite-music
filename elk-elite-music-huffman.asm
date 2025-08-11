OSBYTE                  = $FFF4 
OSCLI                   = $FFF7
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

 ORG &0000   ; Use this for Electron Elite
;ORG &70     ; USE FOR BASIC player.bas ONLY!

.zp_start
.huffmunch_zpblock  SKIP 4      ; Share with four-byte variable RAND at &0000
.zp_end

 ORG &1C00

.musicStatus

 SKIP 1                 \ A flag to determine whether to play the currently
                        \ selected music:
                        \
                        \   * 0 = do not play the music
                        \
                        \   * &FF = do play the music

.huffmunch_block    SKIP 5
.page_bytes         SKIP 2
.byte_ptr           SKIP 2
.track_start        SKIP 2
.xsav               SKIP 1
.ysav               SKIP 1
.zp_temp            SKIP 4


ORG &0E00       ; MM - assemble music and driver at start of
GUARD &1C00     ;      available memory in Electron

.start

.jumptable
;   jmp init_tune1      ; &3000
;   jmp init_tune2      ; &3003
;   jmp poll_track      ; &3006

    jmp init_tune1      ; &0E00     ; MM - new jump table
    jmp poll_track      ; &0E03
    jmp LoadMusic1      ; &0E06
    jmp LoadMusic2      ; &0E09
    jmp StopMusic       ; &0E0C
    jmp StartMusic      ; &0E0F
    jmp LoadPlayMusic1  ; &0E12

.init_tune1
    jsr swap_zp             ; MM - preserve zero page &0000 to &0004

    ldx #<tune_data1_start
    stx track_start
    stx huffmunch_zpblock

    ldx #>tune_data1_start
    stx track_start+1
    stx huffmunch_zpblock+1

;   jmp DRIVER_INIT
    jsr DRIVER_INIT

    jmp swap_zp             ; MM - preserve zero page &0000 to &0004

;.init_tune2
;    ldx #<tune_data2_start
;    stx track_start
;    stx huffmunch_zpblock
;
;    ldx #>tune_data2_start
;    stx track_start+1
;    stx huffmunch_zpblock+1
;
;    jmp DRIVER_INIT

.poll_track
;   jmp DRIVER_PLAY

    STX xsav
    STY ysav

    jsr swap_zp             ; MM - preserve zero page &0000 to &0004

    jsr DRIVER_PLAY

    jsr swap_zp             ; MM - preserve zero page &0000 to &0004

    LDX xsav
    LDY ysav
    RTS

.swap_zp

 LDA &0000              \ Swap RAND (&0000-&0003) with zp_temp
 LDX zp_temp
 STA zp_temp
 STX &0000

 LDA &0001
 LDX zp_temp+1
 STA zp_temp+1
 STX &0001

 LDA &0002
 LDX zp_temp+2
 STA zp_temp+2
 STX &0002

 LDA &0003
 LDX zp_temp+3
 STA zp_temp+3
 STX &0003

 RTS                    \ Return from the subroutrine

.LoadMusic1

 JSR StopMusic          \ Stop any music from playing

 LDX #LO(MUSIC1)        \ Set (Y X) to point to the OS command at MUSIC1, which
 LDY #HI(MUSIC1)        \ loads the Elite Theme music file

 JMP OSCLI              \ Call OSCLI to execute the OS command at (Y X), which
                        \ loads the Elite Theme music file, and return from the
                        \ subroutine using a tail call

.MUSIC1

 EQUS "L.M.MUSIC1"      \ This is short for "*LOAD M.MUSIC1"
 EQUB 13

.LoadMusic2

 JSR StopMusic          \ Stop any music from playing

 LDX #LO(MUSIC2)        \ Set (Y X) to point to the OS command at MUSIC2, which
 LDY #HI(MUSIC2)        \ loads the Blue Danube music file

 JMP OSCLI              \ Call OSCLI to execute the OS command at (Y X), which
                        \ loads the Blue Danube music file, and return from the
                        \ subroutine using a tail call

.MUSIC2

 EQUS "L.M.MUSIC2"      \ This is short for "*LOAD M.MUSIC2"
 EQUB 13

.StopMusic

 LDA #0                 \ Stop any music from playing
 STA musicStatus

 RTS                    \ Return from the subroutrine

.StartMusic

 LDA #&FF               \ Stop any music from playing
 STA musicStatus

 RTS                    \ Return from the subroutrine

.LoadPlayMusic1

 JSR LoadMusic1         \ Load the Elite Theme music file

 JSR init_tune1         \ Initialise the music

 JSR StartMusic         \ Start the music playing

 RTS                    \ Return from the subroutrine

INCLUDE "lib/huffman.s.asm"
INCLUDE "drivers/huffman.asm"

.tune_data1_start

; MM - only load one tune

IF tune = 1
  INCBIN "music/00_Elite_Theme.huf"
ELSE
  INCBIN "music/01_Blue_Danube.huf"
ENDIF

.tune_data1_end

PRINT "HUFFMAN"
PRINT "-------"
PRINT ""
PRINT "      Tune 1 size is ",P%-tune_data1_start,"bytes"

;.tune_data2_start
;    INCBIN "music/01_Blue_Danube.huf"
;.tune_data2_end
;
;PRINT "      Tune 2 size is ",P%-tune_data2_start,"bytes"

;H%=P%
;ALIGN 256
;PRINT "           Alignment lost ",(P%-H%),"bytes"

.end

; MM - move non-zp variables here, so they do not get overwritten by music code

PRINT "           Total size is ",(end-start),"bytes"
PRINT ""

PRINT "Code ends at ", ~end

IF tune = 1
 SAVE "MUSIC1", start, end, start
ELSE
 SAVE "MUSIC2", start, end, start
ENDIF
