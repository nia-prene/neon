.include "hud.h"
.include "lib.h"

.include "oam.h"
.code

.rodata
HUD_tiles:
	.byte $02, $f6, $02, $02, $02, $02, $02, $02
	.byte $02, $02, $02, $02, $02, $02, $02, $02
	.byte $02, $02, $02, $02, $02, $02, $02, $02
	.byte $02, $02, $02, $02, $02, $02, $02, $f9
	.byte $02, $f7, $f8, $f8, $f8, $f8, $f8, $f8
	.byte $f8, $f8, $f8, $f8, $f8, $f8, $f8, $f8
	.byte $f8, $f8, $f8, $f8, $f8, $f8, $f8, $f8
	.byte $f8, $f8, $f8, $f8, $f8, $f8, $f8, $fa
