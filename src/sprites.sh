#!/bin/bash

declare command="cat "

for folder in sprites/*
do 
	command="${command}<(spritr -g $(basename $folder) -s 8x16 -b $folder/*.png) "
done

declare get_sprites="sed -n '/SPRITES/,/END/{ /SPRITES/! { /END/! p } }'"
declare get_palettes="sed -n '/PALETTES/,/END/{ /PALETTES/! { /END/! p } }'"
declare get_tiles="sed -n '/TILES/,/END/{ /TILES/! { /END/! p } }'"
declare get_bin="perl -ne 'printf \"%02X\n\", oct(\"0b\$_\")' | xxd -r -p"

eval $command | awk '{print $2}' | gacha  \
	| tee >(eval $get_sprites > metasprites.s) \
	| tee >(eval $get_palettes > sprite_palettes.s) \
	| eval $get_tiles | eval $get_bin > sprites.chr
					
