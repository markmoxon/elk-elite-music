.DRIVER_INIT
    sei

    ldx     #0
	ldy     #0
    stx     byte_ptr+0
    stx     byte_ptr+1

	jsr     huffmunch_load
    stx     page_bytes+0
	sty     page_bytes+1

	lda     #$f2                                            ; Read RAM copy of location &FE07 (ULA SHEILA Misc. Control)
	ldx     #0
	ldy     #$ff
	jsr     OSBYTE                                          ; Old value returned in X

	txa
	and     #$f8                                            ; Mask - 11111000
	sta     speaker_off                                     ; Store previous FE07 values for CAPS LOCK LED, CASSETTE MOTOR, and DISPLAY MODE 
	ora     #2                                              ; Switch on sound generation - 00000010
	sta     speaker_on                                      ; Store previous FE07 value with sound generation enabled
    
    cli
    rts

.DRIVER_PLAY
    ldy     #0                          ; 2
    jsr     huffmunch_read              ; 6
    cmp     #$02                        ; 2

    ldx     speaker_off                 ; 3
    bcc     skip_on                     ; 2/3
    ldx     speaker_on                  ; 3
.skip_on
    stx     SHEILA_MISC_CONTROL         ; 4
    sta     SHEILA_COUNTER              ; 4

    ; 16-bit increment byte_ptr
    inc     byte_ptr+0                  ; 5
    bne     skip_hi                     ; 2/3
    inc     byte_ptr+1                  ; 5
.skip_hi

    ; Compare against page_bytes (16-bit)
    lda     byte_ptr+0                  ; 3
    cmp     page_bytes+0                ; 3
    lda     byte_ptr+1                  ; 3
    sbc     page_bytes+1                ; 3
    bcc     continue                    ; 2/3

    ; If >=, reload track start
    lda     track_start+0               ; 3
    sta     huffmunch_zpblock+0         ; 3
    lda     track_start+1               ; 3
    sta     huffmunch_zpblock+1         ; 3
    jmp     DRIVER_INIT                 ; 3

.continue
    rts                                 ; 6

;.speaker_on     SKIP 1
;.speaker_off    SKIP 1