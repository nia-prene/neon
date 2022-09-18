.include "lib.h"

.include "shots.h"

.include "player.h"
.include "sprites.h"
.include "apu.h"


.zeropage
Shots_hold: .res 1
Shots_remaining: .res 1
Shots_charge: .res 1

.data
SHOTS_MAX=15
isActive: .res SHOTS_MAX
bulletX: .res SHOTS_MAX
bulletY: .res SHOTS_MAX
bulletSprite: .res SHOTS_MAX
PlayerBullet_damage: .res SHOTS_MAX

.code

AUTO=24;amount of shoots after release
	
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
		;jsr SFX_newEffect

		dec Shots_remaining;
		bpl :+
			lda #0;don't let go negative 
			sta Shots_remaining
		:

		ldy Player_powerLevel; get bullet pattern by pwr lvl
		
		lda @shotType_L,y
		sta Player_ptr+0
		lda @shotType_H,y
		sta Player_ptr+1

		jmp (Player_ptr); void()

@notFiring:
	lda #$FF
	sta Shots_hold

	rts

@shotType_L:;shooting functions by power level
	.byte <(Shot00)
	.byte <(Shot01)
	.byte <(Shot02)
@shotType_H:
	.byte >(Shot00)
	.byte >(Shot01)
	.byte >(Shot02)


Shots_get:; cy() | x
;returns
;y - available bullet
;c - success / fail
	
	ldy #SHOTS_MAX-1

@shotLoop:
	lda isActive,y
	beq @inactive
		dey
		bpl @shotLoop
		ldy #0
		
		clc
		rts
@inactive:
	sec
	rts; return y


Shots_discharge:; a (a)

	and #BUTTON_B
	beq @notPressingB

		lda #AUTO;shoots for x frames after released
		sta Shots_remaining

@notPressingB:
	
	lda Shots_remaining;if timer > 0
	beq @notFiring

		inc Shots_hold

		lda #SFX05;play sound effect
		;jsr SFX_newEffect

		dec Shots_remaining;
		bpl :+
			lda #0;don't let go negative 
			sta Shots_remaining
		:
		
		lda Shots_hold
		and #%1
		bne @return
		jsr Shots_get; c,y() | x
		bcc @return
		
			clc
			lda Player_xPos_H
			sta bulletX,y
			bvs @return
		
			clc
			lda Player_yPos_H
			eor #$80
			adc #$F8
			eor #$80
			sta bulletY,y
			bvs @return

			lda #SPRITE05
			sta bulletSprite,y

			lda #TRUE
			sta isActive,y
		
			sec
			lda Shots_charge
			sbc #1
			sta Shots_charge

		@return:
			rts


@notFiring:
	lda #$FF
	sta Shots_hold
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


	lda Shots_hold
	and #%111
	tax 
	
	lda @status,x
	beq @return

	jsr Shots_get; c,y() | x
	bcc @return
		
		clc
		lda Player_xPos_H
		eor #$80
		adc @offset_x,x
		eor #$80
		sta bulletX,y
		bvs @return
		
		clc
		lda Player_yPos_H
		eor #$80
		adc @offset_y,x
		eor #$80
		sta bulletY,y
		bvs @return

		lda @sprites,x
		sta bulletSprite,y

		lda #TRUE
		sta isActive,y

@return:
	rts

@status:
	.byte TRUE,TRUE,TRUE,TRUE,FALSE,FALSE,FALSE,FALSE
@offset_x:
	.lobytes -6,  16,  6, -16
@offset_y:
	.lobytes -12, -6, -12, -6
@sprites:
	.byte SPRITE09,SPRITE08,SPRITE09,SPRITE08
.endproc


.proc Shot01

	lda Shots_hold
	and #%111
	tax 
	
	lda @status,x
	beq @return

	jsr Shots_get; c,y() | x
	bcc @return
		
		clc
		lda Player_xPos_H
		eor #$80
		adc @offset_x,x
		eor #$80
		sta bulletX,y
		bvs @return; wrapped around
		
		clc
		lda Player_yPos_H
		eor #$80
		adc @offset_y,x
		eor #$80
		sta bulletY,y
		bvs @return; wrapped around

		lda @sprites,x
		sta bulletSprite,y

		lda #TRUE
		sta isActive,y

@return:
	rts

@status:
	.byte TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,FALSE,FALSE
@offset_x:
	.lobytes  -4,  12, -20,   4, -12, 20
@offset_y:
	.lobytes -12,  -6,   0, -12,  -6,  0
@sprites:
	.byte SPRITE09,SPRITE09,SPRITE08,SPRITE09,SPRITE09,SPRITE08

.endproc


.proc Shot02

	lda Shots_hold
	and #%111
	tax 

	jsr Shots_get; c,y() | x
	bcc @return
		

		lda Player_speedIndex
		bne @fast
			clc
			lda Player_xPos_H
			eor #$80
			adc @offset_focus,x
			eor #$80
			sta bulletX,y
			bvs @return
			jmp @doY

	@fast:
		clc
		lda Player_xPos_H
		eor #$80
		adc @offset_x,x
		eor #$80
		sta bulletX,y
		bvs @return
	@doY:	
		clc
		lda Player_yPos_H
		eor #$80
		adc @offset_y,x
		eor #$80
		sta bulletY,y
		bvs @return

		lda @sprites,x
		sta bulletSprite,y

		lda #TRUE
		sta isActive,y

@return:
	rts

@offset_x:
	.lobytes  -4,  12, -20, 28,   4, -12, 20, -28
@offset_focus:
	.lobytes  -2,  06, -10, 14,   2, -06, 10, -14
@offset_y:
	.lobytes -12,  -6,   0,  6, -12,  -6,  0,   6
@sprites:
	.byte SPRITE09,SPRITE09,SPRITE09,SPRITE08,SPRITE09,SPRITE09,SPRITE09,SPRITE08

.endproc
