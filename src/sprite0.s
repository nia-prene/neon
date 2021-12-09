.include "sprite0.h"



.proc Sprite0_init
SPRITE_Y=238
SPRITE_TILE=$20
SPRITE_ATTRIBUTE=%01100000;flip and place behind
SPRITE_X=112
	lda #SPRITE_Y
	sta OAM
	sta OAM_0YPos
	lda #SPRITE_TILE
	sta OAM+1
	lda #SPRITE_ATTRIBUTE
	sta OAM+2
	lda #SPRITE_X
	sta OAM+3
.endproc
