.include "lib.h"
.include "player.h"

.include "shots.h"
.include "sprites.h"
.include "palettes.h"
.include "enemies.h"
.include "bullets.h"
.include "apu.h"

PLAYERS_MAX=2
.zeropage
Player_ptr:.res 2
Player_xPos_H: .res 1
Player_yPos_H: .res 1
.data
Player_xPos_L: .res 1
Player_yPos_L: .res 1

Player_speed_H: .res 1
Player_speed_L: .res 1
Player_speedIndex:.res 1
Player_focused: .res 1
lastDirection: .res 1

Player_powerLevel: .res 1
Player_hearts: .res 1
Player_bombs: .res 1
Player_haveHeartsChanged: .res 1
Player_haveBombsChanged: .res 1

Players_powerLevel: .res PLAYERS_MAX
Players_hearts: .res PLAYERS_MAX
Players_bombs: .res PLAYERS_MAX

Player_sprite: .res 1
Player_willRender: .res 1

Hitbox_state:.res 1
Hitbox_sprite: .res 1
h:.res 1;hitbox variable


.code
Player_init:
; initializes players to blank slate values to set up game
	lda #5
	sta Player_hearts

	lda #3
	sta Player_bombs

	lda #2
	sta Player_powerLevel
	sta Player_speedIndex

	lda #TRUE
	sta Player_haveHeartsChanged
	sta Player_haveBombsChanged
	sta Player_willRender

	lda #SPRITE01
	sta Player_sprite
	
	lda #FALSE
	sta Player_focused

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

Player_setSpeed:;(controller) returns void
;controller bits are | a b sel st u d l r |
;pixel per frame when moving fast
FAST_MOVEMENT_H = 2	
FAST_MOVEMENT_L = 0
;pixel per frame when moving slow
MAX_RIGHT = 253
MAX_LEFT = 03
MAX_UP = 8
MAX_DOWN = 230
SPEED_MAX=16

	and #BUTTON_B
	bne @goingSlow

	@goingFast:

		clc 
		lda Player_speedIndex; move index 
		adc #1
		cmp #SPEED_MAX
		bcc :+

			lda #FALSE
			sta Player_focused; all the way slow
			rts
		:
		sta Player_speedIndex
		rts

	@goingSlow:
		
		sec
		lda Player_speedIndex; move the index
		sbc #1
		bcs :+
			
			lda #TRUE
			sta Player_focused; all the way fast
			rts
		:
		sta Player_speedIndex
		rts


Player_move:; void(a)

	and #BUTTON_RIGHT | BUTTON_LEFT | BUTTON_DOWN | BUTTON_UP
	tax

	lda @valid,x; test if valid direction
	beq @return
		
		lda @move_l,x
		sta Player_ptr+0
		lda @move_h,x
		sta Player_ptr+1
		jmp (Player_ptr)

@return:
	rts

; in order - still, right, left, right-left
; down, down-right, down-left, down-right-left
; up, up-right, up-left, up-right-left
; up-down, up-down-right, up-down-left, up-down-right-left
@valid:
	.byte FALSE,TRUE,TRUE,FALSE
	.byte TRUE,TRUE,TRUE,FALSE
	.byte TRUE,TRUE,TRUE,FALSE
	.byte FALSE,FALSE,FALSE,FALSE

@move_l:
	.byte null, <@right, <@left, null
	.byte <@down, <@downRight, <@downLeft, null
	.byte <@up, <@upRight, <@upLeft, null
	.byte null, null, null, null

@move_h:
	.byte null, >@right, >@left, null
	.byte >@down, >@downRight, >@downLeft, null
	.byte >@up, >@upRight, >@upLeft, null
	.byte null, null, null, null

@right:
	
	cpx lastDirection
	beq :+
		lda #00; direction changed
		sta Player_xPos_L
		stx lastDirection
	:

	ldx Player_speedIndex

	clc
	lda Player_xPos_L
	adc @cardinal_l,x
	sta Player_xPos_L

	lda Player_xPos_H
	adc @cardinal_h,x
	cmp #MAX_RIGHT
	bcs :+
		sta Player_xPos_H
	:rts


@left:
	
	cpx lastDirection
	beq :+
		lda #$ff; direction changed
		sta Player_xPos_L
		stx lastDirection
	:

	ldx Player_speedIndex
	sec
	lda Player_xPos_L
	sbc @cardinal_l,x
	sta Player_xPos_L
	lda Player_xPos_H
	sbc @cardinal_h,x
	cmp #MAX_LEFT
	bcc :+
		sta Player_xPos_H
	:
	rts


@down:
	
	cpx lastDirection
	beq :+
		lda #$00; direction changed
		sta Player_yPos_L
		stx lastDirection
	:
	ldx Player_speedIndex
	clc
	lda Player_yPos_L
	adc @cardinal_l,x
	sta Player_yPos_L

	lda Player_yPos_H
	adc @cardinal_h,x
	cmp #MAX_DOWN
	bcs :+
		sta Player_yPos_H
	:rts


@up:
	cpx lastDirection
	beq :+
		lda #$ff; direction changed
		sta Player_yPos_L
		stx lastDirection
	:
	
	ldx Player_speedIndex
	sec
	lda Player_yPos_L
	sbc @cardinal_l,x
	sta Player_yPos_L
	lda Player_yPos_H
	sbc @cardinal_h,x
	cmp #MAX_UP
	bcc :+
		sta Player_yPos_H
	:rts


@upRight:
	
	cpx lastDirection
	beq :+	
		lda #$ff; direction changed
		sta Player_yPos_L
		lda #00
		sta Player_xPos_L
		stx lastDirection
	:
	ldx Player_speedIndex

	clc
	lda Player_xPos_L
	adc @ordinal_l,x
	sta Player_xPos_L

	lda Player_xPos_H
	adc @ordinal_h,x
	cmp #MAX_RIGHT
	bcs :+

		sta Player_xPos_H
		sec
	:
	;sec
	lda Player_yPos_L
	sbc @ordinal_l,x
	sta Player_yPos_L
	lda Player_yPos_H
	sbc @ordinal_h,x
	cmp #MAX_UP
	bcc :+
		sta Player_yPos_H
	:rts


@upLeft:
	
	cpx lastDirection
	beq :+
		lda #$ff; direction changed
		sta Player_yPos_L
		sta Player_xPos_L
		stx lastDirection
	:
	ldx Player_speedIndex
	sec
	lda Player_xPos_L
	sbc @ordinal_l,x
	sta Player_xPos_L
	lda Player_xPos_H
	sbc @ordinal_h,x
	cmp #MAX_LEFT
	bcc :+
		sta Player_xPos_H
	:sec
	lda Player_yPos_L
	sbc @ordinal_l,x
	sta Player_yPos_L
	lda Player_yPos_H
	sbc @ordinal_h,x
	cmp #MAX_UP
	bcc :+
		sta Player_yPos_H
	:rts


@downRight:
	
	cpx lastDirection
	beq :+
		lda #00; direction changed
		sta Player_yPos_L
		sta Player_xPos_L
		stx lastDirection
	:
	ldx Player_speedIndex
	clc
	lda Player_yPos_L
	adc @ordinal_l,x
	sta Player_yPos_L

	lda Player_yPos_H
	adc @ordinal_h,x
	cmp #MAX_DOWN
	bcs :+
		sta Player_yPos_H
	:clc
	lda Player_xPos_L
	adc @ordinal_l,x
	sta Player_xPos_L

	lda Player_xPos_H
	adc @ordinal_h,x
	cmp #MAX_RIGHT
	bcs :+
		sta Player_xPos_H
	:rts


@downLeft:; void(x)
	
	cpx lastDirection
	beq :+
		lda #00; direction changed
		sta Player_yPos_L
		lda #$ff
		sta Player_xPos_L
		stx lastDirection
	:
	
	ldx Player_speedIndex
	clc
	lda Player_yPos_L
	adc @ordinal_l,x
	sta Player_yPos_L

	lda Player_yPos_H
	adc @ordinal_h,x
	cmp #MAX_DOWN
	bcs :+
	
		sec
		sta Player_yPos_H
	
	:;sec
	lda Player_xPos_L
	sbc @ordinal_l,x
	sta Player_xPos_L
	lda Player_xPos_H
	sbc @ordinal_h,x
	cmp #MAX_LEFT
	bcc :+
		sta Player_xPos_H
	:
	rts


@cardinal_l:
	.byte 128, 176, 224, 0, 32, 48, 80, 96
	.byte 96, 112, 112, 128, 128, 128, 128, 128

@cardinal_h:
	.byte  0,  0,  0,  1,  1,  1,  1,  1
	.byte  1,  1,  1,  1,  1,  1,  1,  1

@ordinal_l:
	.byte 96, 128, 144, 176, 192, 208, 224
	.byte 224, 240, 240, 0, 0, 0, 0, 0, 0

@ordinal_h:
	.byte  0,  0,  0,  0,  0,  0,  0,  0
	.byte  0,  0,  1,  1,  1,  1,  1,  1
	

HITBOX01=1
HITBOX02=2
HITBOX03=3

Hitbox_tick:; void()

	ldx Hitbox_state; if hitbox active
	beq :+

		lda Hitbox_L,x; update it
		sta Player_ptr+0
		lda Hitbox_H,x
		sta Player_ptr+1
		jmp (Player_ptr); void()

	:
	lda Player_focused; if focused
	beq :+
	lda Hitbox_state; and hitbox isn't deployed
	bne :+
		lda #HITBOX01; deploy the hitbox
		jsr Hitbox_new
	:

	rts

Hitbox_new:; void(a)
	
	sta Hitbox_state
	lda #0
	sta h
	rts

Hitbox_L:
	.byte NULL 
	.byte <(Hitbox_01)
	.byte <(Hitbox_02)
	.byte <(Hitbox_03)
Hitbox_H:
	.byte NULL 
	.byte >(Hitbox_01)
	.byte >(Hitbox_02)
	.byte >(Hitbox_03)
Hitbox_01:
DEPLOY_FRAMES=4
	lda h
	adc #1
	cmp #DEPLOY_FRAMES
	bcc @statePersists
		lda #HITBOX02
		jmp Hitbox_new
@statePersists:
	sta h

	lda #SPRITE1D
	sta Hitbox_sprite
	rts

Hitbox_02:
	inc h
	lda h
	lsr
	lsr
	lsr
	and #%11
	tax
	lda @hitboxAnimation,x
	sta Hitbox_sprite

	lda Player_focused
	bne :+
		
		lda #HITBOX03
		jmp Hitbox_new
	:
	rts

@hitboxAnimation:
	.byte SPRITE19,SPRITE1A,SPRITE1B,SPRITE1C


Hitbox_03:
RECALL_FRAMES=4
	clc
	lda h
	adc #1
	cmp #RECALL_FRAMES
	bcc :+

		lda #NULL; disable
		sta Hitbox_sprite
		jmp Hitbox_new
	:
	sta h

	lda #SPRITE1D
	sta Hitbox_sprite

	rts


Player_isHit:;c()
MAX_BULLET_DIAMETER=16
HITBOX_WIDTH=1
HITBOX_HEIGHT=1
	
	ldx #MAX_ENEMY_BULLETS-1
@bulletLoop:

	lda isEnemyBulletActive,x ;if active
	beq @nextBullet ;else next

		sec ;find x distance
		lda enemyBulletXH,x
		sbc Player_xPos_H
		bcs @compareX

			eor #%11111111
@compareX:
	cmp #MAX_BULLET_DIAMETER; if x distance < width
	bcs @nextBullet ;else

	sec ;find y distance
	lda enemyBulletYH,x
	sbc Player_yPos_H
	bcs @compareY

		eor #%11111111; if negative, 1's compliment

@compareY:
	cmp #MAX_BULLET_DIAMETER; if y distance < height
	bcs @nextBullet
	
	;clc; carry is clear
	lda Player_xPos_H; find player x bounded box
	sta sprite1LeftOrTop
	adc #HITBOX_WIDTH-1
	sta sprite1RightOrBottom
	
	sec
	lda enemyBulletXH,x
	sbc #2
	sta sprite2LeftOrTop
	clc
	adc #4
	sta sprite2RightOrBottom

	jsr checkCollision
	bcc @nextBullet;if outside box
	
	;clc; faster to leave it
	lda Player_yPos_H
	sta sprite1LeftOrTop
	adc #HITBOX_HEIGHT-1; carry is set
	sta sprite1RightOrBottom
	
	sec
	lda enemyBulletYH,x
	sbc #2
	sta sprite2LeftOrTop
	clc
	adc #4
	sta sprite2RightOrBottom

	jsr checkCollision
	bcc @nextBullet

		rts ;return carry set

@nextBullet:

	dex
	bpl @bulletLoop
	
	clc ;mark false
	rts


Player_hit:

	sec; decrease power level
	lda Player_powerLevel
	sbc #1
	bcs :+
		lda #0; no underflow
		sec; reset carry
	:sta Player_powerLevel

	;sec; decrease hearts
	lda Player_hearts
	sbc #1
	bcs :+
		lda #5; do gameover stuff
	:sta Player_hearts
	
	lda #SFX02
	jsr SFX_newEffect
	
	lda #TRUE
	sta Player_haveHeartsChanged
	rts


Player_fall:;void()
FALL_SPEED=1
	
	clc
	lda Player_yPos_H
	adc #FALL_SPEED; move player down
	bcc :+; if y > 255
		lda #255; y = 255
	:sta Player_yPos_H

	; todo animation
	rts
	
	
Player_recover:;void(f)
RECOVER_Y=128
RECOVER_SPEED=5

	bne @notFirstTime
		lda #255
		sta Player_yPos_H; move player to bottom
@notFirstTime:
	
	clc
	lda Player_yPos_H	
	sbc #RECOVER_SPEED
	
	cmp #RECOVER_Y
	bcs :+; if y > 255
		lda #RECOVER_Y
		sta Player_yPos_H
		
		sec; return true
		rts

	:sta Player_yPos_H
	
	clc; mark false
	rts


Player_collectCharms:

	ldx #MAX_ENEMY_BULLETS-1
@bulletLoop:

	lda isEnemyBulletActive,x ;if active
	beq @nextBullet ;else

		sec ;find x distance
		lda enemyBulletXH,x
		sbc Player_xPos_H
		bcs :+
			;clc
			eor #%11111111 ;if negative
			adc #1
		
		:cmp #MAX_BULLET_DIAMETER; if x distance < width
		bcs @nextBullet ;else
		sec ;find y distance
		lda enemyBulletYH,x
		sbc Player_yPos_H
		bcs :+
			;clc
			eor #%11111111 ;if negative
			adc #1; two's compliment
		
		:cmp #MAX_BULLET_DIAMETER;if y distance < height
		bcs @nextBullet
			
			;clc
			lda Shots_charge
			adc #4
			bcc :+
				lda #255
			:sta Shots_charge
			lda #FALSE
			sta isEnemyBulletActive,x

@nextBullet:
	dex
	bpl @bulletLoop
	rts


