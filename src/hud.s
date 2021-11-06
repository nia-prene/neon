.include "hud.h"
.include "lib.h"

.include "oam.h"
.code

.rodata
HUD_tiles:
	.byte $01, $f6, $01, $01, $01, $01, $01, $01
	.byte $01, $01, $01, $01, $01, $01, $01, $01
	.byte $01, $01, $01, $01, $01, $01, $01, $01
	.byte $01, $01, $01, $01, $01, $01, $01, $f9
	.byte $01, $f7, $f8, $f8, $f8, $f8, $f8, $f8
	.byte $f8, $f8, $f8, $f8, $f8, $f8, $f8, $f8
	.byte $f8, $f8, $f8, $f8, $f8, $f8, $f8, $f8
	.byte $f8, $f8, $f8, $f8, $f8, $f8, $f8, $fa
