\\ Declare ZP vars
.driver_zp_start
    .EXO_zp_src_hi	SKIP 1
    .EXO_zp_src_lo	SKIP 1
    .EXO_zp_src_bi	SKIP 1
    .EXO_zp_bitbuf	SKIP 1

    .EXO_zp_len_lo	SKIP 1
    .EXO_zp_len_hi	SKIP 1

    .EXO_zp_bits_lo	SKIP 1
    .EXO_zp_bits_hi	SKIP 1

    .EXO_zp_dest_hi	SKIP 1
    .EXO_zp_dest_lo	SKIP 1	; dest addr lo
    .EXO_zp_dest_bi	SKIP 1	; dest addr hi

.speaker_values
    .speaker_on     SKIP 1
    .speaker_off    SKIP 1
    
.driver_zp_end