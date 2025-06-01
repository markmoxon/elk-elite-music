.DRIVER_INIT
    lda #$f2
    ldx #0
    ldy #$ff
    jsr OSBYTE          ; returns old &FE07 in X

    txa
    and #$F8
    sta speaker_off
    ora #2
    sta speaker_on
    rts

.DRIVER_PLAY
    ldy #0
    lda (track_ptr),y
    cmp #$02

    ldx speaker_off
    bcc skip_on
    ldx speaker_on
.skip_on
    nop                     ; balances branch timing
    stx SHEILA_MISC_CONTROL
    sta SHEILA_COUNTER

    inc track_ptr
    bne skip_hi
    inc track_ptr+1
.skip_hi

    ; compare hi-byte first — faster path
    lda track_ptr+1
    cmp track_end+1
    bcc done
    bne reset_ptr
    lda track_ptr
    cmp track_end
    bcc done

.reset_ptr
    lda track_start
    sta track_ptr
    lda track_start+1
    sta track_ptr+1

.done
    rts

.speaker_on  SKIP 1
.speaker_off SKIP 1