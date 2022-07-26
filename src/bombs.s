.include "bombs.h"
.include "lib.h"
.include "bullets.h"

.zeropage
cooldownTimer: .res 1
Bombs_count:.res 1
Bombs_timeElapsed:.res 1
.code
Bombs_toss:;(y,x)
COOLDOWN_TIME=16
	
	sec
	lda cooldownTimer;countdown til next possible bomb toss
	sbc #1
	bcs :+
			lda #0;without underflowing
	:sta cooldownTimer
	
	clc
	lda Bombs_timeElapsed;count frames since last bomb
	adc #1
	bcc :+
		lda #255;without overflowing
	:sta Bombs_timeElapsed
	
	tya
	and #BUTTON_A;if holding b
	beq @noBomb

		txa
		and #BUTTON_A;and not holding last frame
		bne @noBomb

			lda cooldownTimer;if cooled down
			bne @noBomb
		
				lda #COOLDOWN_TIME;set the timer
				sta cooldownTimer
				
				lda #0
				sta Bombs_timeElapsed ;zero time since bomb
				
				ldx #MAX_ENEMY_BULLETS
			@bulletLoop:
				lda Bullets_isBullet,x ;if bullet is active
				beq @nextBullet ;else next bullet
					
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
@noBomb:

	rts

