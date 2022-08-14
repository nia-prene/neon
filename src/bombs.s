.include "bombs.h"

.include "lib.h"
.include "bullets.h"
.include "player.h"
.include "apu.h"
.zeropage
Bombs_timeElapsed:.res 1
.code
Bombs_init: ;void()
	
	lda #255; allow for immediate use of bomb
	sta Bombs_timeElapsed
	rts


Bombs_toss:; void(y,x)
; x - last gamepad state
; y - current gamepad state
; update counter at beginning of frame
; so that events following bomb toss
; can start on 0
	
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
				bne :+
					lda #3; no underflow
				:sta Player_bombs
				
				lda #TRUE
				sta Player_haveBombsChanged

				lda #SFX06; play bass
				jsr SFX_newEffect; void(a)
				lda #SFX07; play boom
				jsr SFX_newEffect; void(a)
				lda #SFX08; play twinkle
				jsr SFX_newEffect; void(a)
					
				ldx #MAX_ENEMY_BULLETS
			@bulletLoop:
				lda isEnemyBulletActive,x; if bullet is active
				beq @nextBullet; else next bullet
				lda Bullets_isInvisible,x; and visible
				bne @deleteBullet; delete invisible bullets	
					
					jsr Bullets_toCharm; void(x) | x
					jmp @nextBullet
			@deleteBullet:
			
				lda #FALSE
				sta isEnemyBulletActive,x
			@nextBullet:
			
				dex ;x--
				bpl @bulletLoop;while x < 0
				sec
				rts
@noBomb:
	clc
	
	rts

