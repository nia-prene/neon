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


Bombs_toss:;(y,x)
; x - last gamepad state
; y - current gamepad state
; update counter at beginning of frame
; so that events following bomb toss
; can start on 0
WOOSH_TIMER=32
	clc ;count frames since last bomb
	lda Bombs_timeElapsed
	adc #1
	bcc :+; setting this carry will allow a bomb to be dropped
		lda #255;without overflowing
	:sta Bombs_timeElapsed
	
	tya; retrieve current gamepad state
	and #BUTTON_A; if holding b
	beq @noBomb

		txa; retrieve last gamepad state
		and #BUTTON_A; and not holding last frame
		bne @noBomb

			lda Bombs_timeElapsed; if time > 256
			bcc @noBomb; carry is set when time > 256
				
				lda Player_bombs; and the player has a bomb
				beq @noBomb
					
					sec; decrease bombs
					sbc #1
					bpl :+
						lda #0; no underflow
					:sta Player_bombs
					
					lda #TRUE
					sta Player_haveBombsChanged

					lda #0
					sta Bombs_timeElapsed ;zero time since bomb

					lda #SFX06; play bass
					jsr SFX_newEffect; void(a)
					lda #SFX07; play boom
					jsr SFX_newEffect; void(a)
					lda #SFX08; play twinkle
					jsr SFX_newEffect; void(a)
					
					ldx #MAX_ENEMY_BULLETS
				@bulletLoop:
					lda isEnemyBulletActive,x ;if bullet is active
					beq @nextBullet ;else next bullet
					lda Bullets_isInvisible,x ;and visible
					bne @deleteBullet	
						
						lda #<(Bullets_toCharms-1);change function ptr
						sta enemyBulletBehaviorL,x
						lda #>(Bullets_toCharms-1)
						sta enemyBulletBehaviorH,x
				
						lda #TRUE
						sta Bullets_isCharm,x ;its a charm now
						lda #FALSE
						sta Bullets_isBullet,x;its not a bullet

				@nextBullet:
					dex ;x--
					bpl @bulletLoop;while x < 0
					
					sec; return true
					rts

				@deleteBullet:
					lda #FALSE
					sta isEnemyBulletActive,x
					dex
					bpl @bulletLoop
					
					sec; return true
					rts


@noBomb:
	lda Bombs_timeElapsed
	cmp #WOOSH_TIMER
	bne @noWoosh
		pha
		
		lda #SFX09
		jsr SFX_newEffect

		pla
@noWoosh:

	clc; return false
	rts

