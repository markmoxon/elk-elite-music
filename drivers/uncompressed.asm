.DRIVER_INIT
	lda     #$f2                                            ; Read RAM copy of location &FE07 (ULA SHEILA Misc. Control)
	ldx     #0
	ldy     #$ff
	jsr     OSBYTE                                          ; Old value returned in X

	txa
	and     #$f8                                            ; Mask - 11111000
	sta     speaker_off                                     ; Store previous FE07 values for CAPS LOCK LED, CASSETTE MOTOR, and DISPLAY MODE 
	ora     #2                                              ; Switch on sound generation - 00000010
	sta     speaker_on                                      ; Store previous FE07 value with sound generation enabled
    
    rts

.DRIVER_PLAY
    ldy     #0                      ; 2
    lda     (track_ptr),y           ; 5
    cmp     #$02                    ; 2

    ldx     speaker_off             ; 3
    bcc     use_off                 ; 2/3
    ldx     speaker_on              ; 3
.use_off
    nop                             ; 2 — balances branch path
    stx     SHEILA_MISC_CONTROL     ; 4
    sta     SHEILA_COUNTER          ; 4

    inc     track_ptr               ; 5
    bne     skip_hi_inc             ; 2/3
    inc     track_ptr+1             ; 5
.skip_hi_inc
    nop                             ; 2
    nop                             ; 2
    nop                             ; 2  ; total 6 cycles padding for fast path

    lda     track_ptr+1             ; 3
    cmp     track_end+1             ; 3
    bcc     done                    ; 2/3
    bne     reset_ptr               ; 2/3

    lda     track_ptr               ; 3
    cmp     track_end               ; 3
    bcc     done                    ; 2/3

.reset_ptr
    lda     track_start             ; 3
    sta     track_ptr               ; 3
    lda     track_start+1           ; 3
    sta     track_ptr+1             ; 3
    jmp     done_end                ; 3

.done
    nop                             ; 2
    nop                             ; 2
    nop                             ; 2
    nop                             ; 2
    nop                             ; 2
    nop                             ; 2  ; 6 cycles to match reset_ptr path
    jmp     done_end                ; 3

.done_end
    rts                             ; 6

.speaker_on     SKIP 1
.speaker_off    SKIP 1