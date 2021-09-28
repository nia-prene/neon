.include "lib.h"

.include "player.h"

.include "playerbullets.h"
.include "sprites.h"
.include "palettes.h"
.include "enemies.h"
.include "bullets.h"

.zeropage
playerIFrames: .res 1
playerX_H: .res 1
playerX_L: .res 1
playerY_H: .res 1
playerY_L: .res 1
speed_H: .res 1
speed_L: .res 1
pressingShoot: .res 1
playerSprite: .res 1
playerHP: .res 1
Player_powerLevel: .res 1
Player_killCount: .res 1

.code
Player_initialize:
	lda #4
	sta playerHP
	tay
	ldx #PLAYER_PALETTE
	jsr setPalette;(x, y)
	lda #200;set to coordinates
	sta playerY_H
	lda #120
	sta playerX_H 
	lda #0
	sta Player_powerLevel
	rts

Player_move:;(controller) returns void
;controller bits are | a b sel st u d l r |
;pixel per frame when moving fast
FAST_MOVEMENT_H = 3
FAST_MOVEMENT_L = 128
;pixel per frame when moving slow
SLOW_MOVEMENT_H = 1
SLOW_MOVEMENT_L = 0
;furthest right player can go
MAX_RIGHT = 249
;furthest left player can go
MAX_LEFT = 07
;furthest up player can go
MAX_UP = 0
;furthest down player can go
MAX_DOWN = 215
	rol;test bit 7 (A)
	pha;save controller
	bcs @goingSlow
@goingFast:
	lda #FAST_MOVEMENT_L
	sta speed_L
	lda #FAST_MOVEMENT_H
	sta speed_H
	jmp @testRight
@goingSlow:
	lda #SLOW_MOVEMENT_L
	sta speed_L
	lda #SLOW_MOVEMENT_H
	sta speed_H
@testRight:
	pla;retrieve controller input
	ror
	ror
	bcc @testLeft
;if bit 0 set then move right
	pha
	clc
	lda playerX_L
	adc speed_L
	sta playerX_L
	lda playerX_H
	adc speed_H
	cmp #MAX_RIGHT
	bcc @storeRight
	lda #MAX_RIGHT
@storeRight:
	sta playerX_H
	pla
@testLeft:
	ror
;if bit 1 set then move left 
	bcc @testDown
	pha
	sec
	lda playerX_L
	sbc speed_L
	sta playerX_L
	lda playerX_H
	sbc speed_H
	cmp #MAX_LEFT
	bcs @storeLeft
	lda #MAX_LEFT
@storeLeft:
	sta playerX_H
	pla
@testDown:
;if bit 2 set then move down
	ror
	bcc @testUp
	pha
	clc
	lda playerY_L
	adc speed_L
	sta playerY_L
	lda playerY_H
	adc speed_H
	cmp #MAX_DOWN
	bcc @storeDown
	lda #MAX_DOWN
@storeDown:
	sta playerY_H
	pla
@testUp:
;if bit 3 set then move down
	ror
	bcc @return
	pha
	sec
	lda playerY_L
	sbc speed_L
	sta playerY_L
	lda playerY_H
	sbc speed_H
	bcs @storeUp
	lda #MAX_UP
@storeUp:
	sta playerY_H
	pla
@return:
	lda #PLAYER_SPRITE
	sta playerSprite;set sprite
	rts

Player_shoot:;(controller poll)
B_BUTTON=%01000000
	and #B_BUTTON
	beq @notShooting
		inc pressingShoot
		ldy Player_powerLevel
		@shotLoop:
		;jump to all active shot types
			lda @shotType_H,y
			pha
			lda @shotType_L,y
			pha
			dey
			bpl @shotLoop
			rts
@notShooting:
	lda #$ff
	sta pressingShoot
	rts
@shotType_L:
	.byte <(shotType00-1)
	.byte <(shotType01-1)
	.byte <(shotType02-1)
@shotType_H:
	.byte >shotType00
	.byte >shotType01
	.byte >shotType02

.align $100
Player_isHit:;(void)
PLAYER_HEIGHT=16
HITBOX_X_OFFSET=3
HITBOX_Y_OFFSET=12
HITBOX_WIDTH=2
HITBOX_HEIGHT=2
	ldx #MAX_ENEMY_BULLETS-1
@bulletLoop:
	lda isEnemyBulletActive,x ;if active
	beq @nextBullet ;else
	sec ;find x distance
	lda enemyBulletXH,x
	sbc playerX_H
	bcs @bulletGreaterX
	eor #%11111111 ;if negative
@bulletGreaterX:
	cmp enemyBulletWidth,x ; if x distance < width
	bcs @nextBullet ;else
	sec ;find y distance
	lda enemyBulletYH,x
	sbc playerY_H
	bcs @bulletGreaterY
	eor #%11111111 ;if negative
@bulletGreaterY:
	cmp #PLAYER_HEIGHT ;if y distance < height
	bcs @nextBullet
	;copy player x bounded box
	lda playerX_H
	adc #HITBOX_X_OFFSET
	sta sprite1LeftOrTop
	adc #HITBOX_WIDTH
	sta sprite1RightOrBottom
	;copy bullet x bounded box
	lda enemyBulletXH,x
	adc enemyBulletHitbox1,x
	sta sprite2LeftOrTop
	adc enemyBulletHitbox2,x
	sta sprite2RightOrBottom
	jsr checkCollision
	bcc @nextBullet;if outside box
	;copy player y bounded box
	clc
	lda playerY_H
	adc #HITBOX_Y_OFFSET
	sta sprite1LeftOrTop
	adc #HITBOX_HEIGHT
	sta sprite1RightOrBottom
	;copy bullet y bounded box
	lda enemyBulletYH,x
	adc enemyBulletHitbox1,x
	sta sprite2LeftOrTop
	adc enemyBulletHitbox2,x
	sta sprite2RightOrBottom
	jsr checkCollision
	bcc @nextBullet;if outsitde box
	sec ;mark true
	rts
@nextBullet:
	dex
	bpl @bulletLoop
	clc ;mark false
	rts
