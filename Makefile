BEEBASM?=beebasm

.PHONY:all
all:
	$(BEEBASM) -i elk-elite-music-uncompressed.asm -do elk-elite-music-uncompressed.ssd -opt 3 -v > compile-uncompressed.txt
	$(BEEBASM) -i elk-elite-music-huffman.asm -do elk-elite-music-huffman.ssd -opt 3 -v > compile-huffman.txt
	$(BEEBASM) -i elk-elite-music-exomizer.asm -do elk-elite-music-exomizer.ssd -opt 3 -v > compile-exomizer.txt
