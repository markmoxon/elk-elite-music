BEEBASM?=beebasm

.PHONY:all
all:
	$(BEEBASM) -i elk-elite-music-huffman.asm -D tune=1 -D ssd=0 -v > compile.txt
	$(BEEBASM) -i elk-elite-music-huffman.asm -D tune=2 -D ssd=0 -v >> compile.txt
	$(BEEBASM) -i elk-elite-music-huffman.asm -D tune=1 -D ssd=1 -v > compile.txt
	$(BEEBASM) -i elk-elite-music-huffman.asm -D tune=2 -D ssd=1 -v >> compile.txt
	$(BEEBASM) -i elk-elite-music-disc.asm -do elk-elite-music-huffman.ssd -opt 3 -v >> compile.txt
