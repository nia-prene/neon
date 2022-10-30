.include "bombs.h"

.include "lib.h"
.include "bullets.h"
.include "gamepads.h"
.include "player.h"
.include "apu.h"


.code


Bombs_toss:; 			c() |
; c - true if bomb dropped
	
	lda Gamepads_state; 	if holding b
	and #BUTTON_A
	beq @noBomb
	lda Gamepads_last; 	and not holding last frame
	and #BUTTON_A
	bne @noBomb
				
	lda Player_bombs; and the player has a bomb
	beq @noBomb
				
		sec; decrease bombs
		sbc #1
		sta Player_bombs
				
		lda #TRUE; set it to render
		sta Player_haveBombsChanged

		lda #SFX06; play bass
		jsr SFX_newEffect; void(a)
		lda #SFX07; play boom
		jsr SFX_newEffect; void(a)
				
		sec;	mark bomb
		rts
			;lda #SFX08; play twinkle
			;jsr SFX_newEffect; void(a)
					
@noBomb:
	clc;	mark no bomb 
	rts

