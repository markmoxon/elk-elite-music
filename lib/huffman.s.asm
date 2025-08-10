; Huffmunch
; Brad Smith, 2019
; https://github.com/bbbradsmith/huffmunch

hm_node   = <(huffmunch_zpblock + 0) ; pointer to current node of tree
hm_stream = <(huffmunch_zpblock + 2) ; pointer to bitstream

; MM - move variables out of zero page so zp requirement is only four bytes

;hm_tree   = <(huffmunch_zpblock + 4) ; pointer to tree base
;hm_byte   = <(huffmunch_zpblock + 6) ; current byte of bitstream
;hm_status = <(huffmunch_zpblock + 7) ; bits 0-2 = bits left in hm_byte, bit 7 = string with suffix
;hm_length = <(huffmunch_zpblock + 8) ; bytes left in current string
hm_tree   = (huffmunch_block + 0) ; pointer to tree base
hm_byte   = (huffmunch_block + 2) ; current byte of bitstream
hm_status = (huffmunch_block + 3) ; bits 0-2 = bits left in hm_byte, bit 7 = string with suffix
hm_length = (huffmunch_block + 4) ; bytes left in current string

; NOTE: only hm_node and hm_stream need to be on ZP
;       the rest could go elsewhere, but still recommended for ZP

.huffmunch_load
{
	; hm_node = header
	; Y:X = index
	hm_temp = hm_byte ; temporary 16-bit value in hm_status:hm_byte
	; 1. hm_stream = (index * 2)
	sty hm_stream+1
	txa
	asl a
	sta hm_stream+0
	rol hm_stream+1
	; 2. hm_temp = stream count * 2
	ldy #1
	lda (hm_node), Y
	pha
	sta hm_temp+1
	dey
	lda (hm_node), Y
	pha ; stack = stream count 0,1
	asl a
	sta hm_temp+0
	rol hm_temp+1
	; 3. hm_node = header + 2
	lda hm_node+1
	pha
	lda hm_node+0
	pha ; stack = header 0, 1, stream count 0, 1
	clc
	adc #2
	sta hm_node+0
	bcc l1
	inc hm_node+1
.l1
	; 4. hm_tree = header + 2 + (4 * stream count) [ready]
	lda hm_node+0
	clc
	adc hm_temp+0
	sta hm_tree+0
	lda hm_node+1
	adc hm_temp+1
	sta hm_tree+1
	lda hm_tree+0
	clc
	adc hm_temp+0
	sta hm_tree+0
	lda hm_tree+1
	adc hm_temp+1
	sta hm_tree+1
	; 5. hm_node = header + 2 + (index * 2)
	lda hm_node+0
	clc
	adc hm_stream+0
	sta hm_node+0
	lda hm_node+1
	adc hm_stream+1
	sta hm_node+1
	; 6. hm_stream = header + stream address [ready]
	; Y = 0
	pla
	clc
	adc (hm_node), Y
	sta hm_stream+0
	iny
	pla ; stack = stream count 0, 1
	adc (hm_node), Y
	sta hm_stream+1
	; 7. hm_node = header + 2 + (index * 2) + (2 * stream count)
	lda hm_node+0
	clc
	adc hm_temp+0
	sta hm_node+0
	lda hm_node+1
	adc hm_temp+1
	sta hm_node+1
	; 8. Y:X = stream length [ready]
	; Y = 1
	lda (hm_node), Y
	pha ; stack = stream length 1, stream count 0, 1
	dey
	lda (hm_node), Y
	tax
	pla ; stack = stream count 0, 1
	tay
	; 9. hm_node = total stream count [ready]
	pla
	sta hm_node+0
	pla
	sta hm_node+1
	; 10. initialize other data [ready]
	lda #0
	sta hm_byte ; hm_byte doesn't need initialization, just for consistency
	sta hm_status
	sta hm_length
	rts
}

.huffmunch_read
{
    ldy #0
    lda hm_length
    beq string_empty

.emit_byte
    dec hm_length
    lda (hm_node),Y
    inc hm_node+0
    bne skip_hi1
    inc hm_node+1
.skip_hi1
    rts

.string_empty
    bit hm_status
    bpl walk_tree

    ; follow suffix
    lda (hm_node),Y
    clc
    adc hm_tree+0
    tax
    iny
    lda (hm_node),Y
    adc hm_tree+1
    sta hm_node+1
    stx hm_node+0

    ldy #0
    lda (hm_node),Y
    iny
    cmp #2
    beq leaf2
    tax
    lda hm_status
    and #$7F
    sta hm_status
    cpx #1
    beq leaf1

; leaf0
    lda (hm_node),Y
    rts

.leaf1
    lda (hm_node),Y
    sta hm_length
    lda hm_node+0
    clc
    adc #2
    sta hm_node+0
    bcc skip_hi2
    inc hm_node+1
.skip_hi2
    ldy #0
    jmp emit_byte

.leaf2
    lda (hm_node),Y
    sta hm_length
    lda hm_node+0
    clc
    adc #2
    sta hm_node+0
    bcc skip_hi3
    inc hm_node+1
.skip_hi3
    lda hm_status
    ora #$80
    sta hm_status
    ldy #0
    jmp emit_byte

.walk_tree
    lda hm_tree+0
    sta hm_node+0
    lda hm_tree+1
    sta hm_node+1

.walk_node
    lda (hm_node),Y
    cmp #3
    bcs node3
    iny
    cmp #2
    beq node2
    cmp #1
    beq leaf1

; node0
    lda (hm_node),Y
    rts

.node2
    lda hm_status
    ora #$80
    sta hm_status
    jmp leaf2

.node3
    tax

; read bit (optimized)
    dec hm_status
    bpl skip_bitload
    lda #7
    sta hm_status
    ldy #0
    lda (hm_stream),Y
    sta hm_byte
    inc hm_stream+0
    bne skip_bitload
    inc hm_stream+1
.skip_bitload
    asl hm_byte
    bcs walk_right

.walk_left
    cpx #255
    beq walk_left_long
    inc hm_node+0
    bne skip_hi4
    inc hm_node+1
.skip_hi4
    jmp walk_node

.walk_left_long
    lda hm_node+0
    clc
    adc #3
    sta hm_node+0
    bcc skip_hi5
    inc hm_node+1
.skip_hi5
    jmp walk_node

.walk_right
    cpx #255
    beq walk_right_long
    txa
    clc
    adc hm_node+0
    sta hm_node+0
    bcc skip_hi6
    inc hm_node+1
.skip_hi6
    jmp walk_node

.walk_right_long
    iny
    lda (hm_node),Y
    clc
    adc hm_node+0
    tax
    iny
    lda (hm_node),Y
    adc hm_node+1
    sta hm_node+1
    stx hm_node+0
    ldy #0
    jmp walk_node
}