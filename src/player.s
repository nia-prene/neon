.include "lib.h"
.include "player.h"

.include "playerbullets.h"
.include "sprites.h"
.include "palettes.h"
.include "enemies.h"
.include "bullets.h"

.zeropage
playerX_H: .res 1
playerX_L: .res 1
playerY_H: .res 1
playerY_L: .res 1
speed_H: .res 1
speed_L: .res 1
playerSprite: .res 1
Player_powerLevel: .res 1
Player_killCount: .res 1
Player_hearts: .res 2
Player_haveHeartsChanged: .res 1
Player_iFrames: .res 1
Player_willRender: .res 1
Player_hitboxWillRender: .res 1

.code
Player_initialize:
	lda #5
	sta Player_hearts
	lda #TRUE
	sta Player_haveHeartsChanged
	lda #4
	tay
	ldx #PALETTE00
	jsr setPalette;(x, y)
	lda #200;set to coordinates
	sta playerY_H
	lda #120
	sta playerX_H 
	lda #2
	sta Player_powerLevel
	lda #TRUE
	sta Player_willRender
	rts

Player_move:;(controller) returns void
;controller bits are | a b sel st u d l r |
;pixel per frame when moving fast
FAST_MOVEMENT_H = 3
FAST_MOVEMENT_L = 0
;pixel per frame when moving slow
SLOW_MOVEMENT_H = 1
SLOW_MOVEMENT_L = 0
;furthest right player can go
MAX_RIGHT = 249
;furthest left player can go
MAX_LEFT = 07
;furthest up player can go
MAX_UP = 13
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
	lda #FALSE
	sta Player_hitboxWillRender
	jmp @testRight
@goingSlow:
	lda #SLOW_MOVEMENT_L
	sta speed_L
	lda #SLOW_MOVEMENT_H
	sta speed_H
	lda #TRUE
	sta Player_hitboxWillRender
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
	cmp #MAX_UP
	bcs @storeUp
	lda #MAX_UP
@storeUp:
	sta playerY_H
	pla
@return:
	lda #PLAYER_SPRITE
	sta playerSprite;set sprite
	rts

.align $100
Player_isHit:;(void)
PLAYER_HEIGHT=16
MAX_BULLET_DIAMETER=16
HITBOX_X_OFFSET=3
HITBOX_Y_OFFSET=12
HITBOX_WIDTH=2
HITBOX_HEIGHT=2
;if player is invincible, theyre unharmed
	lda Player_iFrames
	bne @playerInvincible
;else, check bullets
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
	cmp #MAX_BULLET_DIAMETER; if x distance < width
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
	lda playerY_H
	adc #HITBOX_Y_OFFSET-1;carry is set
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
	bcc @nextBullet
	inc Player_iFrames;turn player invincible
	rts ;return carry set
@nextBullet:
	dex
	bpl @bulletLoop
@playerUnharmed:
	clc ;mark false
	rts
@playerInvincible:
;advance i Frames
	lda Player_iFrames
	and #%00010000
	sta Player_willRender
	inc Player_iFrames	
	bne :+
	;reset iframes after 4 seconds
		lda #0
		sta Player_iFrames
		lda #TRUE
		sta Player_willRender
:
	clc ;mark false, playr is unharmed
	rts
