\\ ******************************************************************
\\ EXOMIZER (compression library)
\\ ******************************************************************

\\ Compress data using:
\\ exomizer.exe raw -P0 -c -m 1024 <file.raw> -o <file.exo>

\ ******************************************************************
\ *	Space reserved for runtime buffers not preinitialised
\ ******************************************************************

EXO_buffer_len          = 1024
Exo_addr                = &880
Exo_small_buffer_addr   = &440
Exo_large_buffer_addr   = &5000

\\ Exomiser unpack buffer (must be page aligned
EXO_buffer_start    = Exo_large_buffer_addr
EXO_buffer_end      = EXO_buffer_start + EXO_buffer_len

; -------------------------------------------------------------------
; This 156 byte table area may be relocated. It may also be clobbered
; by other data between decrunches.
; We put this in the BASIC input buffer, which should be harmless on
; all machines.
; -------------------------------------------------------------------
EXO_TABL_SIZE   = 156
exo_tabl_bi     = Exo_small_buffer_addr - EXO_TABL_SIZE

exo_tabl_lo     = exo_tabl_bi + 52
exo_tabl_hi     = exo_tabl_bi + 104

.DRIVER_INIT
    jsr     exo_init_decruncher

    lda     #$f2
    ldx     #0
    ldy     #$ff
    jsr     OSBYTE                          ; old value in X

    txa
    and     #$F8                            ; mask unwanted bits
    sta     speaker_off
    ora     #2                              ; enable sound bit
    sta     speaker_on

    rts


.DRIVER_PLAY
    jsr     exo_get_decrunched_byte
    bcs     endTrack

    cmp     #$02                            ; 2

    ldx     speaker_off
    bcc     set_val
    ldx     speaker_on

.set_val
    stx     SHEILA_MISC_CONTROL
    sta     SHEILA_COUNTER
    rts

.endTrack
    ldx track_start+0
    ldy track_start+1
    jmp DRIVER_INIT

INCLUDE "lib\exomizer.s.asm"