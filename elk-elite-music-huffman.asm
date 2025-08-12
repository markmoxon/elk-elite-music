OSBYTE                  = $FFF4 
OSCLI                   = $FFF7
SHEILA_COUNTER          = $FE06
SHEILA_MISC_CONTROL     = $FE07

QQ12 = &008F            \ Must match Electron Elite
DNOIZ = &1D1E
BELL = &209C
DELAY = &2504

IF ssd = 1
 ORG &0070              \ For testing with BASIC player.bas on a SSD
ELSE
 ORG &0000              \ For Electron Elite
ENDIF

.zp_start
.huffmunch_zpblock  SKIP 4      \ Share with four-byte variable RAND at &0000
.zp_end

 ORG &1C00

.musicStatus

 SKIP 1                 \ A flag to determine whether to play the currently
                        \ selected music:
                        \
                        \   * 0 = do not play the music
                        \
                        \   * &FF = do play the music

.musicOptions

 SKIP 1                 \ Music options:
                        \
                        \   * Bit 7 set = disable music
                        \           clear = enable music (default)
                        \
                        \   * Bit 6 set = swap tunes 1 and 2
                        \           clear = default tunes (default)

.huffmunch_block    SKIP 5
.page_bytes         SKIP 2
.byte_ptr           SKIP 2
.track_start        SKIP 2
.xsav               SKIP 1
.ysav               SKIP 1
.xsav2              SKIP 1
.zp_temp            SKIP 4
.speaker_on         SKIP 1
.speaker_off        SKIP 1

ORG &0E00               \ Assemble music and driver at start of available memory

GUARD &1C00             \ Don't overwrite the music variable space

.start

.jumptable

 JMP InitialiseMusic    \ &0E00
 JMP PlayMusicIRQ       \ &0E03
 JMP StopMusic          \ &0E06
 JMP StartMusic         \ &0E09
 JMP LoadPlayMusic1     \ &0E0C
 JMP LoadInitMusic2     \ &0E0F
 JMP ProcessOptions1    \ &0E12
 JMP ProcessOptions2    \ &0E15

.currentTune

 EQUB tune              \ Currently loaded tune:
                        \
                        \   * 1 = Elite Theme tune
                        \
                        \   * 2 = Blue Danube

.InitialiseMusic

 JSR SwapZP             \ Preserve zero page &0000 to &0004

 LDX #<tune_data1_start \ Set pointers to track data, starting with the low byte
 STX track_start
 STX huffmunch_zpblock

 LDX #>tune_data1_start \ And then the high byte
 STX track_start+1
 STX huffmunch_zpblock+1

 JSR DRIVER_INIT        \ Initialise the music

 JMP SwapZP             \ Preserve zero page &0000 to &0004 and return from
                        \ the subroutine using a tail call

.PlayMusicIRQ

 STX xsav               \ Store X and Y so we can preserve them
 STY ysav

 LDX DNOIZ              \ If DNOIZ is &FF, then sound is fully disabled, so
 CPX #&FF               \ return from the subroutine
 BEQ poll1

 BIT musicOptions       \ If bit 7 of musicOptions is set then music is
 BMI poll1              \ disabled, so return from the subroutine

 JSR SwapZP             \ Preserve zero page &0000 to &0004

 JSR DRIVER_PLAY        \ Play the music

 JSR SwapZP             \ Preserve zero page &0000 to &0004

.poll1

 LDX xsav               \ Retrieve X and Y
 LDY ysav

 RTS                    \ Return from the subroutrine

.SwapZP

 LDA &0000              \ Swap RAND (&0000) with zp_temp
 LDX zp_temp
 STA zp_temp
 STX &0000

 LDA &0001              \ Swap RAND+1 (&0001) with zp_temp+1
 LDX zp_temp+1
 STA zp_temp+1
 STX &0001

 LDA &0002              \ Swap RAND+2 (&0002) with zp_temp+2
 LDX zp_temp+2
 STA zp_temp+2
 STX &0002

 LDA &0003              \ Swap RAND+3 (&0003) with zp_temp+3
 LDX zp_temp+3
 STA zp_temp+3
 STX &0003

 RTS                    \ Return from the subroutrine

.LoadMusic1

 BIT musicOptions       \ If bit 6 of musicOptions is set then tunes are
 BVS lmus2              \ swapped, so load tune 2 instead

.lmus1

 LDX #LO(MUSIC1)        \ Set (Y X) to point to the OS command at MUSIC1, which
 LDY #HI(MUSIC1)        \ loads the Elite Theme music file

 JMP OSCLI              \ Call OSCLI to execute the OS command at (Y X), which
                        \ loads the Elite Theme music file, and return from the
                        \ subroutine using a tail call

.MUSIC1

 EQUS "L.M.MUSIC1"      \ This is short for "*LOAD M.MUSIC1"
 EQUB 13

.LoadMusic2

 BIT musicOptions       \ If bit 6 of musicOptions is set then tunes are
 BVS lmus1              \ swapped, so load tune 1 instead

.lmus2

 LDX #LO(MUSIC2)        \ Set (Y X) to point to the OS command at MUSIC2, which
 LDY #HI(MUSIC2)        \ loads the Blue Danube music file

 JMP OSCLI              \ Call OSCLI to execute the OS command at (Y X), which
                        \ loads the Blue Danube music file, and return from the
                        \ subroutine using a tail call

.MUSIC2

 EQUS "L.M.MUSIC2"      \ This is short for "*LOAD MUSIC2"
 EQUB 13

.StopMusic

 LDA #0                 \ Stop any music from playing
 STA musicStatus

 LDA speaker_off        \ Disable the speaker
 STA SHEILA_MISC_CONTROL

 LDA DNOIZ              \ If DNOIZ is 1, then sound was enabled before we
 CMP #1                 \ disabled it for the music, so keep going to re-enable
 BNE stop1              \ the sound effects

 LDA #0                 \ Set DNOIZ = 0 to re-enable sound effects now that the
 STA DNOIZ              \ music is stopping

.stop1

 RTS                    \ Return from the subroutrine

.StartMusic

 LDA DNOIZ              \ If DNOIZ is &FF, then sound is fully disabled, so
 CMP #&FF               \ return from the subroutine
 BEQ star1

 BIT musicOptions       \ If bit 7 of musicOptions is set then music is
 BMI star1              \ disabled, so return from the subroutine

 LDA #1                 \ Set DNOIZ = 1 to disable sound effects while the
 STA DNOIZ              \ music is playing

 LDA #&FF               \ Start the music playing
 STA musicStatus

.star1

 RTS                    \ Return from the subroutrine

.LoadPlayMusic1

 JSR LoadInitMusic1     \ Load and initialise the Elite Theme music file

 JSR StartMusic         \ Start the music playing

 RTS                    \ Return from the subroutrine

.LoadInitMusic1

 JSR LoadMusic1         \ Load the Elite Theme music file

 JSR InitialiseMusic         \ Initialise the music

 RTS                    \ Return from the subroutrine

.LoadInitMusic2

 JSR LoadMusic2         \ Load the Blue Danube music file

 JSR InitialiseMusic         \ Initialise the music

 RTS                    \ Return from the subroutrine

.ProcessOptions1

 CPX #&51               \ If "S" is not being pressed, skip to DK6
 BNE DK6

 LDA #0                 \ "S" is being pressed, so set DNOIZ to 0 to turn the
 STA DNOIZ              \ sound on

.DK6

 RTS                    \ Return from the subroutrine

.ProcessOptions2

                        \ MM - routine added to process music-related pause
                        \ options, as well as the "Q" option where the patch is
                        \ injected
                        \
                        \ We store the music options in musicOptions as follows:
                        \
                        \   * Bit 7 set = disable music
                        \           clear = enable music (default)
                        \
                        \   * Bit 6 set = swap tunes 1 and 2
                        \           clear = default tunes (default)

                        \ We start with the "Q" logic that we replaced with the
                        \ injected call to this routine

 STX xsav2              \ Save the key press in xsav2 so we can retrieve it
                        \ later

 CPX #&10               \ If "Q" is not being pressed, skip to DK7
 BNE DK7

 LDA #&FF               \ "Q" is being pressed, so set DNOIZ to &FF, so this
 STA DNOIZ              \ will turn the sound off

 JSR StopMusic          \ Stop any music that's playing

 JMP opts5              \ Jump to opts5 to return from the subroutine

.DK7

                        \ The new "M" option switches music on and off

 CPX #&65               \ If "M" is not being pressed, skip to opts1
 BNE opts1

 JSR StopMusic          \ Stop any music that's playing

 LDA #%10000000         \ "M" is being pressed, so flip bit 7 of musicOptions
 EOR musicOptions
 STA musicOptions

 JMP opts4              \ Jump to opts4 to make a beep, pause and return from
                        \ the subroutine

.opts1

                        \ The new "E" option swaps the docking and title tunes

 CPX #&22               \ If "E" is not being pressed, skip to opts5 to return
 BNE opts5              \ from the subroutine

 LDA musicStatus        \ Store the flags for musicStatus on the stack 
 PHA

 JSR StopMusic          \ Stop any music that's playing

 LDA #%01000000         \ "E" is being pressed, so flip bit 7 of musicOptions
 EOR musicOptions
 STA musicOptions

 JSR BELL               \ Make a beep sound so we know something has happened

 LDA QQ12               \ If we are not docked, jump to opts2 to load tune 2
 BEQ opts2

 JSR LoadInitMusic1     \ We are docked, so load and initialise tune 1

 JMP opts3              \ Jump to opts3 to skip the following

.opts2

 JSR LoadInitMusic2     \ Load and initialise tune 2

.opts3

 PLA                    \ If we were not playing music before we switched tunes,
 BEQ opts4              \ jump to opts4

 JSR StartMusic         \ Start playing the music again

.opts4

 JSR BELL               \ Make a beep sound so we know something has happened

 LDY #55                \ Wait for 55 delay loops
 JSR DELAY

.opts5

 LDX xsav2              \ Retrieve the original key press into X

 RTS                    \ Return from the subroutrine

 INCLUDE "lib/huffman.s.asm"

 INCLUDE "drivers/huffman.asm"

.tune_data1_start

IF tune = 1
 INCBIN "music/00_Elite_Theme.huf"
ELSE
 INCBIN "music/01_Blue_Danube.huf"
ENDIF

.tune_data1_end

PRINT "Tune ",tune," size is ",P%-tune_data1_start,"bytes"

.end

PRINT "Total size is ",(end-start),"bytes"
PRINT ""

PRINT "Code ends at ", ~end

IF tune = 1
 IF ssd = 1
  SAVE "output/ssd/MUSIC1", start, end, start
 ELSE
  SAVE "output/elite/MUSIC1", start, end, start
 ENDIF
ELSE
 IF ssd = 1
  SAVE "output/ssd/MUSIC2", start, end, start
 ELSE
  SAVE "output/elite/MUSIC2", start, end, start
 ENDIF
ENDIF
