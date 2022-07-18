.include "lib.h"
.include "player.h"

.include "playerbullets.h"
.include "sprites.h"
.include "palettes.h"
.include "enemies.h"
.include "bullets.h"


.zeropage
Player_xPos_H: .res 1
Player_xPos_L: .res 1
Player_yPos_H: .res 1
Player_yPos_L: .res 1
Player_speed_H: .res 1
Player_speed_L: .res 1
Player_speedIndex:.res 1
Player_sprite: .res 1
Player_powerLevel: .res 2
Player_hearts: .res 2
Player_haveHeartsChanged: .res 1
Player_iFrames: .res 1
Player_willRender: .res 1
Hitbox_state:.res 1
Hitbox_sprite: .res 1
h:.res 1;hitbox variable

.code
Player_init:;(x)
;initializes player to blank slate values
	lda #5
	sta Player_hearts,x
	lda #TRUE
	sta Player_haveHeartsChanged
	lda #0
	sta Player_powerLevel
	sta Player_speedIndex
	lda #TRUE
	sta Player_willRender
	rts

Player_prepare:;(x)
;prepares player for level, call in level loading code
;x player to initialize
X_START_COORD=120
Y_START_COORD=255
;TODO select between one of two players.
	lda #X_START_COORD
	sta Player_xPos_H
	lda #Y_START_COORD
	sta Player_yPos_H
	lda #TRUE
	sta Player_willRender
	rts

.proc Player_toStartingPos
Y_SPEED_H=1
Y_SPEED_L=128
MAX_Y=128
	sec
	lda Player_yPos_L
	sbc #Y_SPEED_L
	sta Player_yPos_L
	lda Player_yPos_H
	sbc #Y_SPEED_H
	cmp #MAX_Y
	bcs :+
		lda #MAX_Y
:
	sta Player_yPos_H
;do animations
	rts
.endproc

Player_move:;(controller) returns void
;controller bits are | a b sel st u d l r |
;pixel per frame when moving fast
FAST_MOVEMENT_H = 2	
FAST_MOVEMENT_L = 0
;pixel per frame when moving slow
MAX_RIGHT = 243
MAX_LEFT = 00
MAX_UP = 0
MAX_DOWN = 202
SLOWDOWN_TIME=16
DEPLOY_TIME=2
RETRACT_TIME=8
	pha;save controller

	and #BUTTON_B
	bne @goingSlow

	@goingFast:
		sec 
		lda Player_speedIndex
		sbc #1
		bcs :+
			lda Hitbox_state
			beq @hitboxHidden
				cmp #HITBOXSTATE03
				beq @hitboxHidden
					lda #RETRACT_TIME;lasts 8 frames 
					sta h
					lda #HITBOXSTATE03
					sta Hitbox_state
		@hitboxHidden:
			lda #0
		:sta Player_speedIndex
		jmp @endIf

	@goingSlow:
		lda Player_speedIndex
		clc
		adc #1
		cmp #SLOWDOWN_TIME
		bcc :+
			lda Hitbox_state
			bne @hitboxDeployed
				lda #HITBOXSTATE01
				sta Hitbox_state
				lda #DEPLOY_TIME;lasts 4 frames 
				sta h
		@hitboxDeployed:
			lda #SLOWDOWN_TIME
		:sta Player_speedIndex
@endIf:

	lda Player_speedIndex
	lsr
	tax
	lda @playerSpeeds_L,x
	sta Player_speed_L
	lda @playerSpeeds_H,x
	sta Player_speed_H

@testRight:
	pla;retrieve controller input
	ror
	bcc @testLeft;if bit 0 set then move right
		pha
		clc
		lda Player_xPos_L
		adc Player_speed_L
		sta Player_xPos_L
		lda Player_xPos_H
		adc Player_speed_H
		cmp #MAX_RIGHT
		bcc :+
			lda #MAX_RIGHT
		:sta Player_xPos_H
		pla
@testLeft:
	ror;if bit 1 set then move left 
	bcc @testDown
		pha
		sec
		lda Player_xPos_L
		sbc Player_speed_L
		sta Player_xPos_L
		lda Player_xPos_H
		sbc Player_speed_H
		bcs :+
			lda #MAX_LEFT
		:sta Player_xPos_H
		pla
	@testDown:
	ror;if bit 2 set then move down
	bcc @testUp
		pha
		clc
		lda Player_yPos_L
		adc Player_speed_L
		sta Player_yPos_L
		lda Player_yPos_H
		adc Player_speed_H
		cmp #MAX_DOWN
		bcc :+
			lda #MAX_DOWN
		:sta Player_yPos_H
		pla
@testUp:
	ror;if bit 3 set then move down
	bcc @doHitbox
		pha
		sec
		lda Player_yPos_L
		sbc Player_speed_L
		sta Player_yPos_L
		lda Player_yPos_H
		sbc Player_speed_H
		bcs :+
			lda #MAX_UP
		:sta Player_yPos_H
		pla
@doHitbox:

	ldx Hitbox_state
	beq @noHitbox
		lda Hitbox_states_H,x
		pha
		lda Hitbox_states_L,x
		pha
		rts

@noHitbox:
	lda #NULL
	sta Hitbox_sprite
	rts

@playerSpeeds_H:
	.byte  1,  1,  1,  1,  1,  1,  1,  1,  0 
@playerSpeeds_L:
	.byte 128, 128, 128, 128, 128, 128, 128, 0, 128
HITBOXSTATE01=1
HITBOXSTATE02=2
HITBOXSTATE03=3
Hitbox_states_L:
	.byte NULL 
	.byte <(Hitbox_state01-1)
	.byte <(Hitbox_state02-1)
	.byte <(Hitbox_state03-1)
Hitbox_states_H:
	.byte NULL 
	.byte >(Hitbox_state01-1)
	.byte >(Hitbox_state02-1)
	.byte >(Hitbox_state03-1)
Hitbox_state01:
	dec h
	bpl @statePersists
		lda #HITBOXSTATE02
		sta Hitbox_state
		lda #0
		sta h
		rts
@statePersists:
	lda #SPRITE1D
	sta Hitbox_sprite
	rts

Hitbox_state02:
	inc h
	lda h
	lsr
	lsr
	lsr
	and #%11
	tax
	lda @hitboxAnimation,x
	sta Hitbox_sprite
	rts
@hitboxAnimation:
	.byte SPRITE19,SPRITE1A,SPRITE1B,SPRITE1C

Hitbox_state03:
	dec h
	bpl @statePersists
		lda #NULL
		sta Hitbox_state
		sta Hitbox_sprite
		rts
@statePersists:

	lda #SPRITE1D
	sta Hitbox_sprite

	rts

@hitboxRecallAnimation:
	.byte SPRITE1A,SPRITE1B

Player_isHit:;c()
PLAYER_HEIGHT=18
MAX_BULLET_DIAMETER=16
HITBOX_X_OFFSET=6
HITBOX_Y_OFFSET=12
HITBOX_WIDTH=1
HITBOX_HEIGHT=1
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
	sbc Player_xPos_H
	bcs @bulletGreaterX
		eor #%11111111 ;if negative
@bulletGreaterX:
	cmp #MAX_BULLET_DIAMETER; if x distance < width
	bcs @nextBullet ;else
	sec ;find y distance
	lda enemyBulletYH,x
	sbc Player_yPos_H
	bcs @bulletGreaterY
		eor #%11111111 ;if negative
@bulletGreaterY:
	cmp #PLAYER_HEIGHT ;if y distance < height
	bcs @nextBullet
	;copy player x bounded box
	lda Player_xPos_H
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
	lda Player_yPos_H
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
		lda #TRUE
		sta Player_willRender
:
	clc ;mark false, playr is unharmed
	rts

Player_toConvo:;void()
;moves the player to the appropriate spot to have a conversation
CONVO_Y=128
CONVO_X=120
	lda Player_xPos_H
	and #%11111110
	cmp #CONVO_X
	beq @doY;where we want it
	bcs @playerRight
		adc #2
		jmp @doY
@playerRight:
	sbc #2
@doY:
	sta Player_xPos_H
	lda Player_yPos_H
	and #%11111110
	cmp #CONVO_Y
	beq @return
	bcs @playerDown
		adc #2
		jmp @return
@playerDown:
	sbc #2
@return:
	sta Player_yPos_H
	rts

