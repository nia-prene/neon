.include "lib.h"
.include "pickups.h"

.include "enemies.h"
.include "sprites.h"
.include "player.h"

.code

Pickups_movePowerup:
	pla
	tax
	clc
	lda enemyYH,x
	adc #1
	bcs @clear
	sta enemyYH,x
	jsr Pickups_isCollected
	bcs @collected
	lda #SPRITE0E
	sta enemyMetasprite,x
	rts
@collected:
;increase the players power
	clc
	lda Player_powerLevel
	adc #1
;dont let it go above 2
	cmp #3
	bcc @setPower
	lda #2
@setPower:
	sta Player_powerLevel
@clear:
	lda #FALSE
	sta isEnemyActive,x
	rts

Pickups_isCollected:
PLAYER_WIDTH=16
PLAYER_HEIGHT=28
PICKUP_WIDTH=16
PICKUP_HEIGHT=16
	sec
	lda enemyXH,x
	sbc playerX_H
	bcs @pickupGreaterX
	eor #%11111111
@pickupGreaterX:
	cmp #PLAYER_WIDTH
	bcs @noCollision
	sec
	lda enemyYH,x
	sbc playerY_H
	bcs @pickupGreaterY
	eor #%11111111
@pickupGreaterY:
	cmp #PLAYER_HEIGHT
	bcs @noCollision
	lda enemyXH,x
	sta sprite1LeftOrTop
	adc #PICKUP_WIDTH
	sta sprite1RightOrBottom
	lda playerX_H
	sta sprite2LeftOrTop
	adc #PLAYER_WIDTH
	sta sprite2RightOrBottom
	jsr checkCollision
	bcc @noCollision
	lda enemyYH,x
	sta sprite1LeftOrTop
	adc #PICKUP_HEIGHT
	sta sprite1RightOrBottom
	lda playerY_H
	sta sprite2LeftOrTop
	adc #PLAYER_HEIGHT
	sta sprite2RightOrBottom
	jsr checkCollision
	bcc @noCollision
	rts ;return carry set
@noCollision:
	clc ;return carry clear
	rts
