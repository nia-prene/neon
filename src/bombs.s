.include "bombs.h"
.include "lib.h"
.include "bullets.h"

.code
Bombs_toss:
	ldx #MAX_ENEMY_BULLETS
@bulletLoop:
	lda Bullets_isBullet,x ;if bullet is active
	beq @nextBullet ;else next bullet
			
		lda #<(Bullets_toCoins-1)
		sta enemyBulletBehaviorL,x
		lda #>(Bullets_toCoins-1)
		sta enemyBulletBehaviorH,x

		lda #TRUE
		sta Bullets_isCoin,x
		lda #FALSE
		sta Bullets_isBullet,x
		sta Bullets_i,x	

@nextBullet:
	dex ;x--
	bpl @bulletLoop;while x < 0
	
	rts

