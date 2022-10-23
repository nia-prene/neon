.include "lib.h"
.include "player.h"

.include "score.h"
.include "shots.h"
.include "sprites.h"
.include "palettes.h"
.include "enemies.h"
.include "bullets.h"
.include "apu.h"

PLAYERS_MAX		= 2
PLAYERS_POWER_MAX	= $200
.zeropage
Player_xPos_H: .res 1
Player_yPos_H: .res 1
.data
Player_xPos_L: .res 1
Player_yPos_L: .res 1

Player_current: .res 1

Player_speedIndex:.res 1
Player_focused: .res 1
Player_lastDirection: .res 1
Player_inPosition: .res 1

Player_power_l: .res 1
Player_power_h: .res 1
Player_hearts: .res 1
Player_haveHeartsChanged: .res 1
Player_bombs: .res 1
Player_haveBombsChanged: .res 1

Players_power_h: .res PLAYERS_MAX
Players_power_l: .res PLAYERS_MAX
Players_hearts: .res PLAYERS_MAX
Players_bombs: .res PLAYERS_MAX

Player_sprite: .res 1
Player_willRender: .res 1

Hitbox_state:.res 1
Hitbox_xPos:.res 1
Hitbox_yPos:.res 1
Hitbox_sprite: .res 1
h:.res 1;hitbox variable


.code
Players_init:
; initializes players to blank slate values to set up game
	lda #5
	sta Player_hearts

	lda #3
	sta Player_bombs

	lda #0
	sta Player_power_h
	lda #0
	sta Player_power_l

	lda #00
	sta Player_speedIndex
	sta Player_current

	lda #TRUE
	sta Player_haveHeartsChanged
	sta Player_haveBombsChanged
	sta Player_willRender

	lda #FALSE
	sta Player_focused

	lda #255
	sta Player_yPos_H
	lda #128
	sta Player_xPos_H

	rts


.proc Player_toStartingPos; void(a)
; a - g (gamestate iterator)
Y_SPEED_H=4
MAX_Y=128+16
	bne :+; if g is 0
		lda #FALSE
		sta Player_inPosition
	:
	lda Player_inPosition
	bne @return

		sec
		lda Player_yPos_H
		sbc #Y_SPEED_H
		sta Player_yPos_H
		cmp #MAX_Y
		bcs :+
			lda #TRUE
			sta Player_inPosition
		:
@return:
	rts
.endproc

Player_setSpeed:;(controller) returns void
;controller bits are | a b sel st u d l r |
;pixel per frame when moving fast
FAST_MOVEMENT_H = 2	
FAST_MOVEMENT_L = 0
;pixel per frame when moving slow
MAX_RIGHT = 256-8
MAX_LEFT = 08
MAX_UP = 0+16
MAX_DOWN = 240-16
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
		:sta Player_speedIndex
		rts

	@goingSlow:
		sec
		lda Player_speedIndex; move the index
		sbc #1
		bcs :+
			lda #TRUE
			sta Player_focused; all the way fast
			rts
		:sta Player_speedIndex
		rts


Player_move:; void(a)

	and #BUTTON_RIGHT | BUTTON_LEFT | BUTTON_DOWN | BUTTON_UP
	tax

	lda #SPRITE01; neutral sprite default
	sta Player_sprite
	
		lda @move_h,x
		beq @return; return on null pointer
		sta Lib_ptr0+1
		lda @move_l,x
		sta Lib_ptr0+0
		jmp (Lib_ptr0)

@return:
	rts

; in order - still, right, left, right-left
; down, down-right, down-left, down-right-left
; up, up-right, up-left, up-right-left
; up-down, up-down-right, up-down-left, up-down-right-left
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
	
	cpx Player_lastDirection
	beq :+
		lda #00; direction changed
		sta Player_xPos_L
		stx Player_lastDirection
	:

	lda #SPRITE03
	sta Player_sprite

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
	
	cpx Player_lastDirection
	beq :+
		lda #$ff; direction changed
		sta Player_xPos_L
		stx Player_lastDirection
	:
	
	lda #SPRITE02
	sta Player_sprite

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
	
	cpx Player_lastDirection
	beq :+
		lda #$00; direction changed
		sta Player_yPos_L
		stx Player_lastDirection
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
	cpx Player_lastDirection
	beq :+
		lda #$ff; direction changed
		sta Player_yPos_L
		stx Player_lastDirection
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
	
	cpx Player_lastDirection
	beq :+	
		lda #$ff; direction changed
		sta Player_yPos_L
		lda #00
		sta Player_xPos_L
		stx Player_lastDirection
	:
	lda #SPRITE03
	sta Player_sprite
	
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
	
	cpx Player_lastDirection
	beq :+
		lda #$ff; direction changed
		sta Player_yPos_L
		sta Player_xPos_L
		stx Player_lastDirection
	:
	lda #SPRITE02
	sta Player_sprite

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
	
	cpx Player_lastDirection
	beq :+
		lda #00; direction changed
		sta Player_yPos_L
		sta Player_xPos_L
		stx Player_lastDirection
	:
	lda #SPRITE03
	sta Player_sprite

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
	
	cpx Player_lastDirection
	beq :+
		lda #00; direction changed
		sta Player_yPos_L
		lda #$ff
		sta Player_xPos_L
		stx Player_lastDirection
	:
	lda #SPRITE02
	sta Player_sprite

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
	;1.75 - .75
	;.byte 192, 240, 32, 64, 96, 112, 144, 160
	;.byte 160, 176, 176, 192, 192, 192, 192, 192
	;1.75 - .5
	;.byte 128, 192, 240, 32, 64, 96, 128, 144
	;.byte 160, 176, 176, 192, 192, 192, 192, 192
	;2 - .5	
	.byte 128, 192, 0, 64, 112, 144, 176, 192
	.byte 224, 224, 240, 0, 0, 0, 0, 0
	;1.5 - .5
	;.byte 128, 176, 224, 0, 32, 48, 80, 96
	;.byte 96, 112, 112, 128, 128, 128, 128, 128

@cardinal_h:
	;1.75 - .75
	;.byte 0,  0,  1,  1,  1,  1,  1,  1
	;.byte 1,  1,  1,  1,  1,  1,  1,  1
	;1.75 - .5
	;.byte  0,  0,  0,  1,  1,  1,  1,  1
	;.byte  1,  1,  1,  1,  1,  1,  1,  1
	;2 - .5	
	.byte  0,  0,  1,  1,  1,  1,  1,  1
	.byte  1,  1,  1,  2,  2,  2,  2,  2
	;1.5 - .5
	;.byte  0,  0,  0,  1,  1,  1,  1,  1
	;.byte  1,  1,  1,  1,  1,  1,  1,  1

@ordinal_l:
	;1.75 - .75
	;.byte 128, 176, 192, 224, 240, 16, 32, 32
	;.byte 48, 48, 64, 64, 64, 64, 64, 64
	;1.75 - .5
	;.byte 96, 128, 176, 208, 224, 0, 16, 32
	;.byte 48, 48, 48, 64, 64, 64, 64, 64 
	;2.0 - .5	
	.byte 96, 144, 192, 224, 0, 32, 48, 64
	.byte 80, 96, 96, 112, 112, 112, 112, 112
	;1.5 - .5	
	;.byte 96, 128, 144, 176, 192, 208, 224,224
	;.byte 240, 240, 0, 0, 0, 0, 0, 0

@ordinal_h:
	;1.75 - .75
	;.byte 0,  0,  0,  0,  0,  1,  1,  1
	;.byte 1,  1,  1,  1,  1,  1,  1,  1
	;1.75 - .5
	;.byte 0,  0,  0,  0,  0,  1,  1,  1
	;.byte 1,  1,  1,  1,  1,  1,  1,  1
	;2 - .5
	.byte  0,  0,  0,  0,  1,  1,  1,  1
	.byte  1,  1,  1,  1,  1,  1,  1,  1
	;1.50 - .5
	;.byte  0,  0,  0,  0,  0,  0,  0,  0
	;.byte  0,  0,  1,  1,  1,  1,  1,  1
	

HITBOX01	=1;	Deploying
HITBOX02	=2;	deployed
HITBOX03	=3;	retracting
HITBOX04	=4;	broom when falling

Hitbox_tick:; void()

	ldx Hitbox_state; if hitbox active
	beq :+

		lda Hitbox_L,x; update it
		sta Lib_ptr0+0
		lda Hitbox_H,x
		sta Lib_ptr0+1
		jmp (Lib_ptr0); void()

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
	.byte <(Hitbox_04)
Hitbox_H:
	.byte NULL 
	.byte >(Hitbox_01)
	.byte >(Hitbox_02)
	.byte >(Hitbox_03)
	.byte >(Hitbox_04)
Hitbox_01:
DEPLOY_FRAMES=4

	lda Player_xPos_H
	sta Hitbox_xPos
	lda Player_yPos_H
	sta Hitbox_yPos

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
	lda Player_xPos_H
	sta Hitbox_xPos
	lda Player_yPos_H
	sta Hitbox_yPos
	
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
	lda Player_xPos_H
	sta Hitbox_xPos
	lda Player_yPos_H
	sta Hitbox_yPos
	
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


Hitbox_04:
	rts


Player_isHit:;c()
MAX_BULLET_DIAMETER=8
	
	ldx #MAX_ENEMY_BULLETS-1
@bulletLoop:

	lda isEnemyBulletActive,x
	cmp #1; if active and visible
	bne @nextBullet ;else next

		sec ;find x distance
		lda Player_yPos_H
		sbc enemyBulletYH,x
		bcs :+

			eor #%11111111
		:
		cmp #MAX_BULLET_DIAMETER; if x distance < width
		bcs @nextBullet ;else

		sec ;find y distance
		lda enemyBulletXH,x
		sbc Player_xPos_H
		bcs :+

			eor #%11111111; if negative, 1's compliment
		:
		cmp #MAX_BULLET_DIAMETER; if y distance < height
		bcs @nextBullet
			
			sec
			lda Player_yPos_H; find player x bounded box
			sbc enemyBulletYH,x
			bcs :+
				eor #%11111111
				adc #1
			:
			cmp #3; todo bullet safe distances
			bcs @nextBullet
			
			sec
			lda Player_xPos_H; find player x bounded box
			sbc enemyBulletXH,x
			bcs :+
				eor #%11111111
				adc #1
			:
			cmp #3; todo bullet safe distances
			bcs @nextBullet
				
				lda Player_yPos_H;	mark where hit
				sta Hitbox_yPos
				lda Player_xPos_H
				sta Hitbox_xPos
				
				sec
				rts ;return carry set

@nextBullet:

	dex
	bpl @bulletLoop
	
	clc ;mark false
	rts


Player_hit:

	sec; decrease power level
	lda Player_power_h
	sbc #1
	bcs :+
		lda #0; no underflow
		sta Player_power_l
		sec; reset carry
	:sta Player_power_h

	;sec; decrease hearts
	lda Player_hearts
	sbc #1
	bcs :+
		lda #5; do gameover stuff
	:sta Player_hearts
	
	lda #00
	sta Shots_remaining

	lda #TRUE
	sta Player_haveHeartsChanged
	rts


.proc Player_fall;	void(a)
; a - gamestate clock
SPEED_h		= 1
SPEED_l		= 0
	bne :+
		lda #SFX02
		jsr SFX_newEffect
	:
	clc
	lda Player_yPos_L; 	move player down
	adc #SPEED_l 
	sta Player_yPos_L
	
	lda Player_yPos_H
	adc #SPEED_h
	bcc :+; if y > 255
		lda #255;	no overflow
	:sta Player_yPos_H

	lda #SPRITE13;		set hitbox sprite to broom
	sta Hitbox_sprite

	lda #SPRITE14;		set player to falling sprite
	sta Player_sprite
				
	rts
.endproc

	
Player_recover:; void(a)
; a - g (gamestate counter)
RECOVER_Y=128+16; push player to this y
RECOVER_SPEED=5

	bne :+; on 0th frame
		lda #255
		sta Player_yPos_H; 	move player to bottom
		
		lda #FALSE
		sta Player_inPosition;	player not in position
		sta Hitbox_sprite;	remove broom
		sta Hitbox_state;	disable hitbox
	:

	lda Player_inPosition
	bne @return

		clc
		lda Player_yPos_H	
		sbc #RECOVER_SPEED
		cmp #RECOVER_Y
		bcs :+; if y > recovery minimum
		
			lda #TRUE
			sta Player_inPosition
			rts


		:sta Player_yPos_H
@return:
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
			lda Score_frameTotal_L;		add to score
			adc #25
			sta Score_frameTotal_L
			lda Score_frameTotal_H
			adc #0
			sta Score_frameTotal_H

			lda #FALSE;			deactivate bullet
			sta isEnemyBulletActive,x

@nextBullet:
	dex
	bpl @bulletLoop
	rts


