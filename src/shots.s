.include "lib.h"

.include "shots.h"

.include "player.h"
.include "sprites.h"
.include "apu.h"


.zeropage
Shots_hold: .res 1
Shots_remaining: .res 1


.data
SHOTS_MAX=15
bulletX: .res SHOTS_MAX
bulletY: .res SHOTS_MAX
PlayerBullet_width: .res SHOTS_MAX
bulletSprite: .res SHOTS_MAX
PlayerBullet_damage: .res SHOTS_MAX
isActive: .res SHOTS_MAX
PlayerBullet_CooldownTimer: .res 1
.code

AUTO=16;amount of shoots after release
	
PlayerBullets_shoot:;void(a)
;a - current controller state


	and #BUTTON_B
	beq @notPressingB
		lda #AUTO;shoots for x frames after released
		sta Shots_remaining
@notPressingB:
	
	lda Shots_remaining;if timer > 0
	beq @notFiring

	@shoot:
		inc Shots_hold

		lda #SFX05;play sound effect
		jsr SFX_newEffect

		dec Shots_remaining;
		bpl :+
			lda #0;don't let go negative 
			sta Shots_remaining
		:
		ldy Player_powerLevel;for each level-up
	@shotLoop:
		lda @shotType_L,y
		sta Player_ptr+0
		lda @shotType_H,y
		sta Player_ptr+1
		jmp (Player_ptr)
		rts

@notFiring:
	lda #$FF
	sta Shots_hold

	rts

@shotType_L:;shooting functions by power level
	.byte <(Shot00)
	.byte <(Shot01)
	.byte <(shotType02)
@shotType_H:
	.byte >(Shot00)
	.byte >(Shot01)
	.byte >(shotType02)

Shots_get:; cy(y) | x
;returns
;y - available bullet
;returns clear carry if fail
;find empty bullet starting with slot 0
	ldy #SHOTS_MAX-1

@findEmptyBullet:
	lda isActive,y
	beq @initializeBullet
		dey
		bpl @findEmptyBullet
		ldy #0
		
		clc
		rts
@initializeBullet:
	sec
	rts

PlayerBullets_move:;void (void)
;moves player bullets up screen
BULLET_SPEED = 18
;start with last bullet
	ldx #SHOTS_MAX-1
@bulletLoop:
	lda isActive,x;if inactive, skip
	beq @skipBullet
	ror
	ror ;bit 2 set means enemy hit
	bcs @clearBullet
	sec ;y = y + speed
	lda bulletY,x
	sbc #BULLET_SPEED
	bcc @clearBullet ;if off screen
	sta bulletY,x
@skipBullet:
	dex ;x--
	bpl @bulletLoop;while x>=0
	rts
@clearBullet:
	lda #FALSE
	sta isActive,x
	dex ;x-- continue loop
	bpl @bulletLoop;while x >=0
	rts
	
.proc Shot00
Y_OFFSET=12
DAMAGE=3
WIDTH=16

	lda Shots_hold
	and #%111
	bne @return
		
		ldx #1
	@loop:
		jsr Shots_get; c,y(y) | x
		bcc @return
		
			clc
			lda Player_xPos_H
			adc @offset_x,x
			sta bulletX,y
		
			sec
			lda Player_yPos_H
			sbc #Y_OFFSET
			sta bulletY,y

			lda #SPRITE09
			sta bulletSprite,y
			lda #TRUE
			sta isActive,y
			dex
			bpl @loop
@return:
	rts

@offset_x:
	.lobytes -6, 6 

.endproc

.proc Shot01

	lda Shots_hold
	and #%1
	bne @return

		lda Shots_hold
		and #%110
		lsr
		tax 
		ldy #SHOTS_MAX-1

		jsr Shots_get; get empty bullet
		bcc @return
		
			clc
			lda Player_xPos_H
			adc @offset_x,x
			sta bulletX,y
		
			clc
			lda Player_yPos_H
			adc @offset_y,x
			sta bulletY,y

			lda @sprites,x
			sta bulletSprite,y

			lda #TRUE
			sta isActive,y

@return:
	rts

@offset_x:
	.lobytes -4, 12, 4, -12
@offset_y:
	.lobytes -12, -6, -12, -6
@sprites:
	.byte SPRITE09,SPRITE08,SPRITE09,SPRITE08
.endproc

.proc shotType02

	lda Shots_hold
	and #%111
	tax 

	jsr Shots_get; c,y() | x
	bcc @return
		
		clc
		lda Player_xPos_H
		adc @offset_x,x
		sta bulletX,y
		
		clc
		lda Player_yPos_H
		adc @offset_y,x
		sta bulletY,y

		lda @sprites,x
		sta bulletSprite,y

		lda #TRUE
		sta isActive,y

@return:
	rts

@offset_x:
	.lobytes  -4,  10, -16, 22,   4, -10, 16, -22
@offset_y:
	.lobytes -12,  -6,   0,  6, -12,  -6,  0,   6
@sprites:
	.byte SPRITE09,SPRITE09,SPRITE09,SPRITE08,SPRITE09,SPRITE09,SPRITE09,SPRITE08
.endproc

