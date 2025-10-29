OSBYTE                  = $FFF4 
OSCLI                   = $FFF7
SHEILA_COUNTER          = $FE06
SHEILA_MISC_CONTROL     = $FE07

XC = &002C              \ Must match Electron Elite
YC = &002D
QQ12 = &008F
T = &00D1
DNOIZ = &1D1E
DAMP = &1D1F
JSTE = &1D24
JSTK = &1D25
BSTK = &1D26
TT26 = &1FD8
BELL = &209D
DELAY = &2505
EnablePlus1 = &3581
KL = &4C94
VIEW = &8617

func1 = &B0
func2 = &B1

IF ssd = 1
 ORG &0070              \ For testing with BASIC player.bas on a SSD
ELSE
 ORG &00A8              \ For Electron Elite (uses star-command workspace)
ENDIF

.zp_start
.huffmunch_zpblock  SKIP 4      \ Share with four-byte variable RAND at &0000
.zp_end

 ORG &1CD0

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
.status_sav         SKIP 1
.speaker_on         SKIP 1
.speaker_off        SKIP 1

ORG &0E00               \ Assemble music and driver at start of available memory

GUARD &1CD0             \ Don't overwrite the music variable space

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

 LDX #<tune_data1_start \ Set pointers to track data, starting with the low byte
 STX track_start
 STX huffmunch_zpblock

 LDX #>tune_data1_start \ And then the high byte
 STX track_start+1
 STX huffmunch_zpblock+1

 JMP DRIVER_INIT        \ Initialise the music and return from the subroutine
                        \ using a tail call

.PlayMusicIRQ

 STX xsav               \ Store X and Y so we can preserve them
 STY ysav

 LDX DNOIZ              \ If DNOIZ is &FF, then sound is fully disabled, so
 CPX #&FF               \ return from the subroutine
 BEQ poll1

 BIT musicOptions       \ If bit 7 of musicOptions is set then music is
 BMI poll1              \ disabled, so return from the subroutine

 JSR DRIVER_PLAY        \ Play the music

.poll1

 LDX xsav               \ Retrieve X and Y
 LDY ysav

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

 JSR InitialiseMusic    \ Initialise the music

 RTS                    \ Return from the subroutrine

.LoadInitMusic2

 JSR LoadMusic2         \ Load the Blue Danube music file

 JSR InitialiseMusic    \ Initialise the music

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

 CPX #&64               \ If "B" is not being pressed, skip to nobit
 BNE nobit

 LDA #0                 \ Set the joystick type to Plus 1, as Bitstik will only
 STA joyType            \ work with the ADC interface

 LDA BSTK               \ Toggle the value of BSTK between 0 and &FF
 EOR #&FF
 STA BSTK

 STA JSTK               \ Configure JSTK to the same value, so when the Bitstik
                        \ is enabled, so is the joystick

 STA JSTE               \ Configure JSTE to the same value, so when the Bitstik
                        \ is enabled, the joystick is configured with reversed
                        \ channels

 JMP opts4              \ Jump to opts4 to make a beep and return from the
                        \ subroutine

.nobit

                        \ The new "E" option swaps the docking and title tunes

 CPX #&22               \ If "E" is not being pressed, skip to opts5 to return
 BNE opts5              \ from the subroutine

 LDA musicStatus        \ Store the flags for musicStatus in status_sav
 STA status_sav

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

 LDA status_sav         \ If we were not playing music before we switched tunes,
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

\ ******************************************************************************
\
\       Name: b_table
\       Type: Variable
\   Category: Keyboard
\    Summary: Lookup table for Delta 14B joystick buttons
\  Deep dive: Delta 14B joystick support
\
\ ------------------------------------------------------------------------------
\
\ In the following table, which maps buttons on the Delta 14B to the flight
\ controls, the high nibble of the value gives the column:
\
\   &6 = %110 = left column
\   &5 = %101 = middle column
\   &3 = %011 = right column
\
\ while the low nibble gives the row:
\
\   &1 = %0001 = top row
\   &2 = %0010 = second row
\   &4 = %0100 = third row
\   &8 = %1000 = bottom row
\
\ This results in the following mapping (as the top two fire buttons are treated
\ the same as the top button in the middle row):
\
\   Fire laser                                    Fire laser
\   Slow down              Fire laser             Speed up
\   Unarm missile          Fire missile           Target missile
\   Front view             E.C.M.                 Rear view
\   Docking computer off   In-system jump         Docking computer on
\
\ Note that this is different to the layout in Angus Duggan's documentation, as
\ he has the docking computer buttons the wrong way around in his instructions.
\
\ ******************************************************************************

                        \ --- Mod: Code added for Delta 14B: ------------------>

.b_table

 EQUB &61               \ Left column    Top row      KYTB+1    Slow down
 EQUB &31               \ Right column   Top row      KYTB+2    Speed up
 EQUB &80               \ -                           KYTB+3    Roll left
 EQUB &80               \ -                           KYTB+4    Roll right
 EQUB &80               \ -                           KYTB+5    Pitch up
 EQUB &80               \ -                           KYTB+6    Pitch down
 EQUB &51               \ Middle column  Top row      KYTB+7    Fire lasers
 EQUB &64               \ Left column    Third row    -         Front view
 EQUB &34               \ Right column   Third row    -         Rear view
 EQUB &32               \ Right column   Second row   KYTB+10   Arm missile
 EQUB &62               \ Left column    Second row   KYTB+11   Unarm missile
 EQUB &52               \ Middle column  Second row   KYTB+12   Fire missile
 EQUB &54               \ Middle column  Third row    KYTB+13   E.C.M.
 EQUB &58               \ Middle column  Bottom row   KYTB+14   In-system jump
 EQUB &38               \ Right column   Bottom row   KYTB+15   Docking computer
 EQUB &68               \ Left column    Bottom row   KYTB+16   Cancel docking

                        \ --- End of added code ------------------------------->

\ ******************************************************************************
\
\       Name: b_14
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Scan the Delta 14B joystick buttons
\  Deep dive: Delta 14B joystick support
\
\ ------------------------------------------------------------------------------
\
\ Scan the Delta 14B for the flight key given in register Y, where Y is the
\ offset into the KYTB table above (so this is the same approach as in DKS1).
\
\ The keys on the Delta 14B are laid out as follows (the top two fire buttons
\ are treated the same as the top button in the middle row):
\
\   Fire laser                                    Fire laser
\   Slow down              Fire laser             Speed up
\   Unarm missile          Fire missile           Target missile
\   Front view             E.C.M.                 Rear view
\   Docking computer off   In-system jump         Docking computer on
\
\ Note that this is different to the layout in Angus Duggan's documentation, as
\ he has the docking computer buttons the wrong way around in his instructions.
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   Y                   The offset into the KYTB table of the key that we want
\                       to scan on the Delta 14B
\
\ ******************************************************************************

                        \ --- Mod: Code added for Delta 14B: ------------------>

.b_13

 LDA #0                 \ Set A = 0 for the second pass through the following,
                        \ so we can check the joystick plugged into the rear
                        \ socket of the Delta 14B adaptor

.b_14

                        \ This is the entry point for the routine, which is
                        \ called with A = 128 (the value of BSTK when the Delta
                        \ 14b is enabled), and if the key we are checking has a
                        \ corresponding button on the Delta 14B, it is run a
                        \ second time with A = 0

 TAX                    \ Store A in X so we can restore it below

 EOR b_table-1,Y        \ We now EOR the value in A with the Y-th entry in
 BEQ b_quit             \ b_table, and jump to b_quit to return from the
                        \ subroutine if the table entry is 128 (&80) - in other
                        \ words, we quit if Y is the offset for the roll and
                        \ pitch controls

                        \ If we get here, then the offset in Y points to a
                        \ control with a corresponding button on the Delta 14B,
                        \ and we pass through the following twice, once with a
                        \ starting value of A = 128, and again with a starting
                        \ value of A = 0
                        \
                        \ On the first pass, the EOR will set A to the value
                        \ from b_table but with bit 7 set, which means we scan
                        \ the joystick plugged into the side socket of the
                        \ Delta 14B adaptor
                        \
                        \ On the second pass, the EOR will set A to the value
                        \ from b_table (i.e. with bit 7 clear), which means we
                        \ scan the joystick plugged into the rear socket of the
                        \ Delta 14B adaptor

 STA &FCB0              \ Set 6522 User VIA output register ORB (SHEILA &60) to
                        \ the value in A, which tells the Delta 14B adaptor box
                        \ that we want to read the buttons specified in PB4 to
                        \ PB7 (i.e. bits 4-7), as follows:
                        \
                        \ On the side socket joystick (bit 7 set):
                        \
                        \   %1110 = read buttons in left column   (bit 4 clear)
                        \   %1101 = read buttons in middle column (bit 5 clear)
                        \   %1011 = read buttons in right column  (bit 6 clear)
                        \
                        \ On the rear socket joystick (bit 7 clear):
                        \
                        \   %0110 = read buttons in left column   (bit 4 clear)
                        \   %0101 = read buttons in middle column (bit 5 clear)
                        \   %0011 = read buttons in right column  (bit 6 clear)

 AND #%00001111         \ We now read the 6522 User VIA to fetch PB0 to PB3 from
 AND &FCB0              \ the user port (PB0 = bit 0 to PB3 = bit 3), which
                        \ tells us whether any buttons in the specified column
                        \ are being pressed, and if they are, in which row. The
                        \ values read are as follows:
                        \
                        \   %1111 = no button is being pressed in this column
                        \   %1110 = button pressed in top row    (bit 0 clear)
                        \   %1101 = button pressed in second row (bit 1 clear)
                        \   %1011 = button pressed in third row  (bit 2 clear)
                        \   %0111 = button pressed in bottom row (bit 3 clear)
                        \
                        \ In other words, if a button is being pressed in the
                        \ top row in the previously specified column, then PB0
                        \ (bit 0) will go low in the value we read from the user
                        \ port

 BEQ b_pressed          \ In the above we AND'd the result from the user port
                        \ with the bottom four bits of the table value (the
                        \ low nibble). The low nibble in b_table contains
                        \ a 1 in the relevant position for that row that
                        \ corresponds with the clear bit in the response from
                        \ the user port, so if we AND the two together and get
                        \ a zero, that means that button is being pressed, in
                        \ which case we jump to b_pressed to update the key
                        \ logger for that button
                        \
                        \ For example, take the b_table entry for the escape pod
                        \ button, in the right column and third row. The value
                        \ in b_table is &34. The high nibble denotes the column,
                        \ which is &3 = %011, which means in the STA VIA+&60
                        \ above, we write %1011 in the first pass (when A = 128)
                        \ to set the right column for the side socket joystick,
                        \ and we write %0011 in the first pass (when A = 0) to
                        \ set the right column for the rear socket joystick
                        \
                        \ Now for the row. The low nibble of the &34 value
                        \ from b_table contains the row, so that's &4 = %0100.
                        \ When we read the user port, then we will fetch %1011
                        \ from VIA+&60 if the button in the third row is being
                        \ pressed, so when we AND the two together, we get:
                        \
                        \   %0100 AND %1011 = 0
                        \
                        \ which will indicate the button is being pressed. If
                        \ any other button is being pressed, or no buttons at
                        \ all, then the result will be non-zero and we move on
                        \ to the next button

 TXA                    \ Restore the original value of A that we stored in X

 BMI b_13               \ If we just did the above with A = 128, then loop back
                        \ to b_13 to do it again with A = 0

.b_quit

 RTS                    \ Return from the subroutine

.b_13a                  \ Duplicate of b_13 but for user port A
 LDA #0
.b_14a
 TAX
 EOR b_table-1,Y
 BEQ b_quit
 STA &FCB1
 AND #%00001111
 AND &FCB1
 BEQ b_pressed
 TXA
 BMI b_13a
 RTS

.b_pressed

 CPY #8                 \ If this is the front view button, jump to b_front to
 BEQ b_front            \ process it

 CPY #9                 \ If this is the front view button, jump to b_rear to
 BEQ b_rear             \ process it

 LDA #&FF               \ Store &FF in the Y-th byte of the key logger at KL
 STA KL,Y

 RTS                    \ Return from the subroutine

.b_front

 LDX VIEW               \ If we are already on the front view, do nothing
 BEQ b_quit

 LDX #func1             \ Set the key "pressed" to FUNC-1 (internal key &20)

 BNE b_return           \ Jump to b_return to "press" this key (this BNE is
                        \ effectively a JMP as X is never zero)

.b_rear

 LDX VIEW               \ If we are already on the rear view, do nothing
 CPX #1
 BEQ b_quit

 LDX #func2             \ Set the key "pressed" to FUNC-2 (internal key &71)

.b_return

 STX KL                 \ Set the key "pressed" to the internal key in X

 RTS                    \ Return from the subroutine

                        \ --- End of added code ------------------------------->

\ ******************************************************************************
\
\       Name: joys2
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Implement joystick options
\
\ ******************************************************************************

                        \ --- Mod: Code moved for Delta 14B: ------------------>

.joys2

 LDA DAMP-&40,X         \ Fetch the current joystick configuration

 BNE joys3              \ If joysticks are already enabled, jump to joys3 to
                        \ skip the following

 LDA #&FF               \ Set JSTK to &FF to configure joysticks
 STA DAMP-&40,X

 STA joyType            \ Set joyType = -1 so we increment it to 0 below, for
                        \ the Plus 1

.joys3

 LDY joyType            \ Set Y to the joystick type

 INY                    \ Move on to the next type

 CPY #5                 \ If we have not yet gone past the end, jump to joys4 to
 BCC joys4              \ confirm the joystick type

                        \ Otherwise we have wrapped around, so enable the
                        \ keyboard once again

 STY joyType            \ Print the joystick configuration for keyboard
 JSR PrintConfig

 LDA #0                 \ Disable joysticks
 STA DAMP-&40,X
 STA joyType

 LDY T                  \ Restore the configuration key argument into Y

 RTS                    \ Return from the subroutine

.joys4

 STY joyType            \ If we get here then we have enabled joysticks of type
                        \ Y, so store 

\CPY #1                 \ If we didn't just enable Plus 1-based joysticks (i.e.
\BEQ joys5              \ Plus 1 or Delta 14B joysticks), skip the following
\CPY #2
\BEQ joys5

 JSR EnablePlus1        \ We just enabled Plus 1 joysticks, so enable the
                        \ analogue to digital converter on the Plus 1 so we can
                        \ read the joystick channels (it is disabled by the
                        \ loader to prevent the ADC conversion from slowing the
                        \ system down when joysticks are not being used)

.joys5

 JSR PrintConfig        \ Print the joystick configuration

 LDY T                  \ Restore the configuration key argument into Y

 RTS                    \ Return from the subroutine

.PrintConfig

 JSR BELL               \ Make a beep sound so we know something has happened

 JSR prin1              \ Print the joystick configuration in the top-right
                        \ corner

 LDY #55                \ Wait for 55 delay loops
 JSR DELAY

                        \ Fall through into prin1 to print the joystick
                        \ configuration in the top-right corner to remove it

.prin1

 LDA #29                \ Move the text cursor to column 29 on row 1
 STA XC
 LDA #1
 STA YC

 LDA joyType            \ Set A = A * 2 so we can use it as an index into the
 ASL A                  \ joyConfig table
 TAY

 LDA joyConfig,Y        \ Print the two-character joystick configuration
 JSR TT26
 INY
 LDA joyConfig,Y
 JMP TT26

.joyType

 EQUB 0                 \ The type of joystick configured:
                        \
                        \   * 0 = Plus 1
                        \
                        \   * 1 = Slogger
                        \
                        \   * 2 = First Byte
                        \
                        \   * 3 = Delta 14B on user port A
                        \
                        \   * 4 = Delta 14B on user port B

.joyConfig

\ EQUS "+1"
\ EQUS "SL"
\ EQUS "FB"
\ EQUS "DA"
\ EQUS "DB"
\ EQUS "KB"

                        \ --- End of moved code ------------------------------->

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
