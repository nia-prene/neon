#!/bin/bash

{
	# spritr the player sprites at offset 0 
	./tools/spritr/spritr.pl -g player -s 8x16 -b src/sprites/player/*.png
	# spritr the enemy waves at offset 1
	for folder in src/sprites/wave*
	do
		./tools/spritr/spritr.pl -g $(basename $folder) -s 8x16 -o 1 -b $folder/*.png
	done
	# spritr the bullets at offset 3
	./tools/spritr/spritr.pl -g bullets -s 8x16 -o 3 -b src/sprites/bullets/*.png
	# pipe them into gacha to get chr, palettes, and metasprites
} | awk '{print $2}' | ./tools/gacha/gacha.pl  \
	| tee >(sed -n '/SPRITES/,/END/{ /SPRITES/! { /END/! p } }' > src/metasprites.s) \
	| tee >(sed -n '/PALETTES/,/END/{ /PALETTES/! { /END/! p } }' > src/sprite_palettes.s) \
	| sed -n '/TILES/,/END/{ /TILES/! { /END/! p } }'| perl -ne 'printf "%02X\n", oct("0b$_")' | xxd -r -p > src/sprites.chr
					
