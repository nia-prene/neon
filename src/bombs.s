.include "bombs.h"
.include "lib.h"
.include "bullets.h"

.zeropage
cooldownTimer: .res 1
Bombs_count:.res 1

.code
Bombs_toss:;(a,x)
COOLDOWN_TIME=16

	and #BUTTON_A;if holding b
	beq @noBomb

		txa
		and #BUTTON_A;and not holding last frame
		bne @noBomb

			lda cooldownTimer;if cooled down
			bne @noBomb
		
				lda #COOLDOWN_TIME;set the timer
				sta cooldownTimer
	
				ldx #MAX_ENEMY_BULLETS
			@bulletLoop:
				lda Bullets_isBullet,x ;if bullet is active
				beq @nextBullet ;else next bullet
					
					lda #<(Bullets_toCoins-1);change function ptr
					sta enemyBulletBehaviorL,x
					lda #>(Bullets_toCoins-1)
					sta enemyBulletBehaviorH,x
			
					lda #TRUE
					sta Bullets_isCoin,x ;its a coin now
					lda #FALSE
					sta Bullets_isBullet,x;its not a bullet
					sta Bullets_i,x;zero this out 	

			@nextBullet:
				dex ;x--
				bpl @bulletLoop;while x < 0
@noBomb:

	sec
	lda cooldownTimer
	sbc #1
	bcs :+
			lda #0
	:sta cooldownTimer
	rts

