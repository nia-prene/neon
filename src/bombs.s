.include "bombs.h"
.include "bullets.h"

.code
Bombs_toss:
	ldx #MAX_ENEMY_BULLETS
@bulletLoop:
	lda isEnemyBulletActive,x ;if bullet is active
	beq @nextBullet ;else next bullet
			
		lda #<(Bullets_toCoins-1)
		sta enemyBulletBehaviorL,x
		lda #>(Bullets_toCoins-1)
		sta enemyBulletBehaviorH,x
				
@nextBullet:
	dex ;x--
	bpl @bulletLoop;while x < 0
	
	rts

