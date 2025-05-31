.DRIVER_INIT
	jmp init

.DRIVER_PLAY
	jmp play

.init
    lda     #$0f                                            ; Flush selected wait class
	ldx     #0                                              ; All waits flushed
	jsr     OSBYTE

	lda     #$f2                                            ; Read RAM copy of location &FE07 (ULA SHEILA Misc. Control)
	ldx     #0
	ldy     #$ff
	jsr     OSBYTE                                          ; Old value returned in X

	stx     ula_control_register_previous_value             ; Store old value
	txa
	and     #$f8                                            ; Mask - 11111000
	sta     speaker_off                                     ; Store previous FE07 values for CAPS LOCK LED, CASSETTE MOTOR, and DISPLAY MODE 
	ora     #2                                              ; Switch on sound generation - 00000010
	sta     speaker_on                                      ; Store previous FE07 value with sound generation enabled
	lda     #0
	sta     SHEILA_COUNTER                                  ; Zero the ULA SHEILA counter (FE06), creating a toggle speaker (inaudible frequency)
    sta     fe06_val
    
    rts

.play
    ldy     #0                      ; 2
    lda     (track_ptr),y           ; 5
    cmp     #$02                    ; 2

    ; Preload speaker_off value
    ldx     speaker_off             ; 3
    bcc     use_off                 ; 2/3

    ldx     speaker_on              ; 3
.use_off
    stx     SHEILA_MISC_CONTROL     ; 4
    stx     fe07_val                ; 3

    sta     SHEILA_COUNTER          ; 4
    sta     fe06_val                ; 3

    ; Increment track_ptr (2-byte pointer increment — always 13 cycles)
    inc     track_ptr               ; 5
    bne     skip_hi_inc             ; 2/3
    inc     track_ptr+1             ; 5
.skip_hi_inc

    ; Compare track_ptr to track_end (fixed 17 cycles)
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
    ; Equalise with reset_ptr path (4 bytes/9 cycles: 3+6)
    nop                             ; 2
    nop                             ; 2
    nop                             ; 2
    jmp     done_end                ; 3

.done_end
    rts                             ; 6

.speaker_on     SKIP 1
.speaker_off    SKIP 1

.fe06_val       SKIP 1
.fe07_val       SKIP 1

.ula_control_register_previous_value    SKIP 1