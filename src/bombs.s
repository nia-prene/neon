.include "bombs.h"

.include "lib.h"
.include "bullets.h"
.include "player.h"
.include "apu.h"


.code


Bombs_toss:; c(y,x)
; arguments
; x - last gamepad state
; y - current gamepad state
; returns
; c - true if bomb dropped
	
	tya; retrieve current gamepad state
	and #BUTTON_A; if holding b
	beq @noBomb

		txa; retrieve last gamepad state
		and #BUTTON_A; and not holding last frame
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
				
				sec
				rts
				;lda #SFX08; play twinkle
				;jsr SFX_newEffect; void(a)
					
@noBomb:
	clc
	
	rts

