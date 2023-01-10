.include "lib.h"
.include "player.h"

.include "apu.h"
.include "bullets.h"
.include "enemies.h"
.include "gamepads.h"
.include "palettes.h"
.include "score.h"
.include "shots.h"
.include "sprites.h"

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

	lda #TRUE
	sta Player_haveHeartsChanged
	sta Player_haveBombsChanged
	sta Player_willRender

	rts


.proc Player_toStartingPos; void(a)
; a - g (gamestate iterator)
Y_SPEED_H=4
MAX_Y=128+16
	bne :+;			if 0th frame of gamestate
		lda #255;		move to bottom middle
		sta Player_yPos_H
		lda #128
		sta Player_xPos_H
		lda #FALSE;		set as not in position
		sta Player_inPosition
	:
	lda Player_inPosition;		if not in position
	bne @return
		sec;			move upward
		lda Player_yPos_H
		sbc #Y_SPEED_H
		sta Player_yPos_H
		cmp #MAX_Y;		until reach this spot
		bcs :+
			lda #TRUE;		mark as in position
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
BRAKES_MAX=16
	
	lda Gamepads_state;	get the controller input
	and #BUTTON_B;		see if pressing b
	beq @goingFast;		if so, go slower
	
	@goingSlow:
		inc Player_speedIndex;	hoding down b taps the brakes

		lda #BRAKES_MAX-1;	make sure it doesnt go over
		cmp Player_speedIndex
		bcs :+
			sta Player_speedIndex;	clamp the overflow
			lda #TRUE;		player is totally slowed
			sta Player_focused
		rts;			void

	@goingFast:
		dec Player_speedIndex; move index 
		dec Player_speedIndex; move index 
		bpl :+
			lda #FALSE
			sta Player_focused;	player is going fast
			sta Player_speedIndex;	zero out speed index
		:
		rts;			void



Player_move:; void(a)
DPAD 	= BUTTON_RIGHT | BUTTON_LEFT | BUTTON_DOWN | BUTTON_UP	

	lda Gamepads_state;	get the controller input
	and #DPAD;		isolate the d pad
	tax;			get the movement pased on d pad

	and #%11;		isolate right, left and neutral
	tay;			
	lda @sprites,y
	sta Player_sprite

	lda @move_h,x;		if not a null pointer
	beq :+
		sta Lib_ptr0+1;		jump to the movement
		lda @move_l,x
		sta Lib_ptr0+0
		jmp (Lib_ptr0);		void(x) | 	pass in d pad
	:;			else not moving
	rts

@move_l:
	.byte NULL, 	<@right, 	<@left, 	null
	.byte <@down, 	<@downRight,	<@downLeft,	null
	.byte <@up,	<@upRight, 	<@upLeft, 	null
	;.byte null, null, null, null; 	technically exist, but unused

@move_h:
	.byte null, 	>@right, 	>@left, 	null
	.byte >@down, 	>@downRight, 	>@downLeft, 	null
	.byte >@up, 	>@upRight, 	>@upLeft, 	null
	.byte null, null, null, null;	used for null pointer

@sprites:
	.byte SPRITE01,SPRITE03,SPRITE02,SPRITE01;	neutral right left

@right:
	cpx Player_lastDirection
	beq :+
		lda #00; direction changed
		sta Player_xPos_L
		stx Player_lastDirection
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
	cpx Player_lastDirection
	beq :+
		lda #$ff; direction changed
		sta Player_xPos_L
		stx Player_lastDirection
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
	:;sec
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
	:
	clc
	lda Player_xPos_L
	adc @ordinal_l,x
	sta Player_xPos_L

	lda Player_xPos_H
	adc @ordinal_h,x
	cmp #MAX_RIGHT
	bcs :+
		sta Player_xPos_H
	:
	rts


@downLeft:; void(x)
	
	cpx Player_lastDirection
	beq :+
		lda #00; direction changed
		sta Player_yPos_L
		lda #$ff
		sta Player_xPos_L
		stx Player_lastDirection
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
	;2 - .75
	.byte 0, 0, 0, 0, 0, 240, 240, 224
	.byte 208, 192, 160, 128, 96, 48, 0, 192
	;1.75 - .75
	;.byte 192, 240, 32, 64, 96, 112, 144, 160
	;.byte 160, 176, 176, 192, 192, 192, 192, 192
	;1.75 - .5
	;.byte 128, 192, 240, 32, 64, 96, 128, 144
	;.byte 160, 176, 176, 192, 192, 192, 192, 192
	;2 - .5	
	;.byte 128, 192, 0, 64, 112, 144, 176, 192
	;.byte 224, 224, 240, 0, 0, 0, 0, 0
	;1.5 - .5
	;.byte 128, 176, 224, 0, 32, 48, 80, 96
	;.byte 96, 112, 112, 128, 128, 128, 128, 128

@cardinal_h:
	;2 - .75
	.byte 2,  2,  2,  2,  2,  1,  1,  1
	.byte 1,  1,  1,  1,  1,  1,  1,  0
	;1.75 - .75
	;.byte 0,  0,  1,  1,  1,  1,  1,  1
	;.byte 1,  1,  1,  1,  1,  1,  1,  1
	;1.75 - .5
	;.byte  0,  0,  0,  1,  1,  1,  1,  1
	;.byte  1,  1,  1,  1,  1,  1,  1,  1
	;2 - .5	
	;.byte  0,  0,  1,  1,  1,  1,  1,  1
	;.byte  1,  1,  1,  2,  2,  2,  2,  2
	;1.5 - .5
	;.byte  0,  0,  0,  1,  1,  1,  1,  1
	;.byte  1,  1,  1,  1,  1,  1,  1,  1

@ordinal_l:
	;2.0 - .75
	.byte 112, 112, 112, 112, 112, 96, 96, 80
	.byte 80, 64, 48, 16, 240, 208, 176, 128
	;1.75 - .75
	;.byte 128, 176, 192, 224, 240, 16, 32, 32
	;.byte 48, 48, 64, 64, 64, 64, 64, 64
	;1.75 - .5
	;.byte 96, 128, 176, 208, 224, 0, 16, 32
	;.byte 48, 48, 48, 64, 64, 64, 64, 64 
	;2.0 - .5	
	;.byte 96, 144, 192, 224, 0, 32, 48, 64
	;.byte 80, 96, 96, 112, 112, 112, 112, 112
	;1.5 - .5	
	;.byte 96, 128, 144, 176, 192, 208, 224,224
	;.byte 240, 240, 0, 0, 0, 0, 0, 0

@ordinal_h:
	;2.0 - .75
	.byte  1,  1,  1,  1,  1,  1,  1,  1
	.byte  1,  1,  1,  1,  0,  0,  0,  0
	;1.75 - .75
	;.byte 0,  0,  0,  0,  0,  1,  1,  1
	;.byte 1,  1,  1,  1,  1,  1,  1,  1
	;1.75 - .5
	;.byte 0,  0,  0,  0,  0,  1,  1,  1
	;.byte 1,  1,  1,  1,  1,  1,  1,  1
	;2 - .5
	;.byte  0,  0,  0,  0,  1,  1,  1,  1
	;.byte  1,  1,  1,  1,  1,  1,  1,  1
	;1.50 - .5
	;.byte  0,  0,  0,  0,  0,  0,  0,  0
	;.byte  0,  0,  1,  1,  1,  1,  1,  1
	

HITBOX01	=1;	Deploying
HITBOX02	=2;	deployed
HITBOX03	=3;	retracting
HITBOX04	=4;	broom when falling
HITBOX05	=5;	game over

Hitbox_tick:; void()

	ldx Hitbox_state; 	if hitbox active
	beq :+
		lda Hitbox_L,x; 	update it
		sta Lib_ptr0+0
		lda Hitbox_H,x
		sta Lib_ptr0+1
		jmp (Lib_ptr0); 	void() |
	:;			else
	lda Player_focused;	if focused
	beq :+
		lda #HITBOX01; 		deploy the hitbox
		jmp Hitbox_new
	:
	rts;			else return void

Hitbox_new:; void(a)
	
	sta Hitbox_state
	lda #0
	sta h
	rts


Hitbox_L:
	.byte NULL 
	.byte <(Hitbox01)
	.byte <(Hitbox02)
	.byte <(Hitbox03)
	.byte <(Hitbox04)
	.byte <(Hitbox05)
Hitbox_H:
	.byte NULL 
	.byte >(Hitbox01)
	.byte >(Hitbox02)
	.byte >(Hitbox03)
	.byte >(Hitbox04)
	.byte >(Hitbox05)
Hitbox01:
DEPLOY_FRAMES=4

	lda Player_xPos_H;	glue to player position
	sta Hitbox_xPos
	lda Player_yPos_H
	sta Hitbox_yPos
	
	lda #SPRITE1D;		set the sprite
	sta Hitbox_sprite

	lda #DEPLOY_FRAMES-1;	see if deploy stage is over
	cmp h;			if over
	bcs :+
		lda #HITBOX02;		switch the hitbox state to deployed
		jmp Hitbox_new
	:
	inc h;			else increase the iterator
	
	rts

Hitbox02:
	lda Player_xPos_H;	glue to the player position
	sta Hitbox_xPos
	lda Player_yPos_H
	sta Hitbox_yPos
	
	lda h;			use bits 3 and 4
	lsr
	lsr
	lsr
	and #%11
	tax;			to determine the animation frame
	lda @hitboxAnimation,x
	sta Hitbox_sprite

	lda Player_focused
	bne :+
		lda #HITBOX03
		jmp Hitbox_new
	:
	inc h;			tick the iterator
	rts

@hitboxAnimation:
	.byte SPRITE19,SPRITE1A,SPRITE1B,SPRITE1C


Hitbox03:
RECALL_FRAMES=4
	lda Player_xPos_H;	glue to player
	sta Hitbox_xPos
	lda Player_yPos_H
	sta Hitbox_yPos
	
	lda #SPRITE1D
	sta Hitbox_sprite
	
	lda #RECALL_FRAMES-1;	if recalling has gone on for n frames
	cmp h
	bcs :+
		lda #NULL;		disable	sprite
		sta Hitbox_sprite;	
		jmp Hitbox_new;		turn off hitbox
	:
	inc h;			else tick iterator

	rts


Hitbox04:
	lda #SPRITE13;		set hitbox sprite to broom
	sta Hitbox_sprite

	rts

Hitbox05:
	lda #128
	sta Hitbox_xPos
	lda #128-32
	sta Hitbox_yPos

	lda #SPRITE2B
	sta Hitbox_sprite
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
			lda Player_yPos_H;	find y distance
			sbc enemyBulletYH,x
			bcs :+;			if negative
				;clc			
				eor #%11111111;		two's compliment
				adc #1
			:
			cmp #4;			if less or equal
			bcs @nextBullet;	else miss
			
			sec;			find x distance
			lda Player_xPos_H
			sbc enemyBulletXH,x
			bcs :+
				eor #%11111111;		if negative
				adc #1;			two's compliment
			:
			cmp #4
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
	:sta Player_power_h

	lda #00
	sta Shots_remaining

	lda #TRUE
	sta Player_haveHeartsChanged

	sec; decrease hearts
	lda Player_hearts
	sbc #1
	sta Player_hearts
	bne :+
		lda #HITBOX05
		jsr Hitbox_new
		clc
	:;sec
	rts


.proc Player_flicker;	void(a)
;a - gamestate iterator
RATE	= %1
	and #RATE
	bne :+
		lda #NULL
		sta Player_sprite
		sta Hitbox_sprite
	:
	rts
.endproc


.proc Player_fall;	void(a)
; a - gamestate clock
SPEED_h		= 1
SPEED_l		= 0
	bne :+
		lda #SFX02
		jsr SFX_newEffect
		lda #HITBOX04;		change hitbox to broom 
		jsr Hitbox_new
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
		jsr Hitbox_new;		
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
COLLECTION_RANGE_X	= 12
COLLECTION_RANGE_Y	= 20

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
		
		:cmp #COLLECTION_RANGE_X; if x distance < width
		bcs @nextBullet ;else
		sec ;find y distance
		lda enemyBulletYH,x
		sbc Player_yPos_H
		bcs :+
			;clc
			eor #%11111111 ;if negative
			adc #1; two's compliment
		
		:cmp #COLLECTION_RANGE_Y;if y distance < height
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


