.DRIVER_INIT
	jmp     init

.DRIVER_PLAY
	jmp     play

.init
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

.play
    ldy     #0                      ; 2
    jsr     huffmunch_read          ; (A set, C set/clear)
    cmp     #$02                    ; 2

    ldx     speaker_off             ; 3 preload both cases
    bcc     skip_on                 ; 2/3
    ldx     speaker_on              ; 3
.skip_on
    stx     SHEILA_MISC_CONTROL     ; 4
    stx     fe07_val                ; 3

    sta     SHEILA_COUNTER          ; 4
    sta     fe06_val                ; 3

    inc     byte_ptr+0              ; 5
    bne     check_limit             ; 2/3
    inc     byte_ptr+1              ; 5

.check_limit
    lda     byte_ptr+0              ; 3
    cmp     page_bytes+0            ; 3
    bne     continue                ; 2/3
    lda     byte_ptr+1              ; 3
    cmp     page_bytes+1            ; 3
    bne     continue                ; 2/3

    ; If we get here, we're at the limit — reset
    lda     track_start+0           ; 3
    sta     huffmunch_zpblock+0     ; 3
    lda     track_start+1           ; 3
    sta     huffmunch_zpblock+1     ; 3
    jmp     init                    ; 3

.continue
    rts                             ; 6

.speaker_on     SKIP 1
.speaker_off    SKIP 1

.fe06_val       SKIP 1
.fe07_val       SKIP 1

.ula_control_register_previous_value    SKIP 1