.include "lib.h"

.include "shots.h"

.include "player.h"
.include "sprites.h"
.include "apu.h"


SHOTS_MAX=14
.zeropage
Shots_hold: .res 1
Shots_remaining: .res 1
Shots_charge: .res 1

Shots_isActive: .res SHOTS_MAX

.data
Shot_ID: .res SHOTS_MAX
bulletX: .res SHOTS_MAX
bulletY: .res SHOTS_MAX
bulletSprite: .res SHOTS_MAX
PlayerBullet_damage: .res SHOTS_MAX

Missiles_velocity: .res 1

.code

AUTO=32;amount of shoots after release
	
PlayerBullets_shoot:;void(a)
;a - current controller state


	and #BUTTON_B
	beq @notPressingB

		lda #AUTO;shoots for x frames after released
		sta Shots_remaining
		txa
		and #BUTTON_B
		bne @notPressingB
			;lda #SFX05
			;jsr SFX_newEffect
			jsr Shot03
			
@notPressingB:
	
	lda Shots_remaining;if timer > 0
	beq @notFiring

	@shoot:
		dec Shots_remaining;
		
		inc Shots_hold

		ldy Player_power_h; get bullet pattern by pwr lvl
		
		lda @shotType_L,y
		sta Lib_ptr0+0
		lda @shotType_H,y
		sta Lib_ptr0+1

		jmp (Lib_ptr0); void()

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
	
	ldy #SHOTS_MAX-2

@shotLoop:
	lda Shots_isActive,y
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
	rts
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
			sta Shots_isActive,y
		
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

	ldx #SHOTS_MAX-2
@bulletLoop:

	lda Shots_isActive,x;if inactive, skip
	beq @skipBullet

		sec ;y = y + speed
		lda bulletY,x
		sbc #BULLET_SPEED
		bcs :+

			lda #FALSE
			sta Shots_isActive,x

		:sta bulletY,x
@skipBullet:
	dex ;x--
	bpl @bulletLoop;while x>=0


@missile:

	lda Shots_isActive+(SHOTS_MAX-1)
	beq @return

@missile_tick:

	ldy Missiles_velocity
	dey
	bpl :+

		lda #FALSE
		sta Shots_isActive+(SHOTS_MAX-1)

	:
	
	sec
	lda bulletY+(SHOTS_MAX-1)
	sbc @delta,y
	sta bulletY+(SHOTS_MAX-1)
	bcs :+
		lda #FALSE
		sta Shots_isActive+(SHOTS_MAX-1)
	:
	
	sty Missiles_velocity

@return:
	rts

@delta:
	.byte  0,  6, 10, 13, 14, 15, 16, 16 
	.byte 0, 6, 11, 14, 16, 17, 18, 18


.proc Shot00


	lda Shots_hold
	and #%111
	tax 
	
	lda @status,x
	beq @return

	jsr Shots_get; c,y() | x
	bcc @return
		
		lda Player_focused
		beq @fast
		
		@slow:
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

		lda @damage,x
		sta PlayerBullet_damage,y

		lda #TRUE
		sta Shots_isActive,y

@return:
	rts

@status:
	.byte TRUE,TRUE,TRUE,TRUE,FALSE,FALSE,FALSE,FALSE
@offset_x:
	.lobytes  -4, 12,   4, -12
@offset_focus:
	.lobytes  04, 04, -04, -04
@offset_y:
	.lobytes -16,-12, -16, -12
@sprites:
	.byte SPRITE09,SPRITE09,SPRITE09,SPRITE09
@damage:
	.byte 4, 3, 4, 3
.endproc


.proc Shot01

	lda Shots_hold
	and #%111
	tax 
	
	lda @status,x
	beq @return

	jsr Shots_get; c,y() | x
	bcc @return
		
		lda Player_focused; if fully slow
		beq @fast

		@slow:
			clc
			lda Player_xPos_H
			eor #$80
			adc @offset_focus,x
			eor #$80
			sta bulletX,y
			bvs @return; wrapped around
			jmp @doY

		@fast:

			clc
			lda Player_xPos_H
			eor #$80
			adc @offset_x,x
			eor #$80
			sta bulletX,y
			bvs @return; wrapped around

	@doY:	
		
		clc
		lda Player_yPos_H
		eor #$80
		adc @offset_y,x
		eor #$80
		sta bulletY,y
		bvs @return; wrapped around

		lda @sprites,x
		sta bulletSprite,y
		
		lda @damage,x
		sta PlayerBullet_damage,y

		lda #TRUE
		sta Shots_isActive,y

@return:
	rts

@status:
	.byte TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,FALSE,FALSE
@offset_x:
	.lobytes  -4,  12, -20,   4, -12, 20
@offset_focus:
	.lobytes  12, -04, -04, -12,  04, 04
@offset_y:
	.lobytes -16, -12, -08, -16, -12, -8
@sprites:
	.byte SPRITE09,SPRITE09,SPRITE09,SPRITE09,SPRITE09,SPRITE09
@damage:
	.byte 4, 3, 2, 4, 3, 2

.endproc


.proc Shot02

	lda Shots_hold
	and #%111
	tax 

	jsr Shots_get; c,y() | x
	bcc @return
		

		lda Player_focused; if fully slow
		beq @fast

		@slow:
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
		
		lda @damage,x
		sta PlayerBullet_damage,y

		lda #TRUE
		sta Shots_isActive,y

@return:
	rts

@offset_x:
	.lobytes  -4,  12, -20, 28,   4, -12, 20, -28
@offset_focus:
	.lobytes  12, -04, -04, 12, -12,  04, 04, -12
@offset_y:
	.lobytes -16, -12,  -8, -4, -16, -12, -8,  -4
@sprites:
	.byte SPRITE09,SPRITE09,SPRITE09,SPRITE09,SPRITE09,SPRITE09,SPRITE09,SPRITE09
@damage:
	.byte 4,3, 2, 1, 4, 3, 2, 1

.endproc


.proc Shot03
OFFSET_Y= (256-16)
DAMAGE = 5
		
	lda Shots_isActive+(SHOTS_MAX-1)
	bne @return

		lda Player_xPos_H
		sta bulletX+(SHOTS_MAX-1)
		
		clc
		lda Player_yPos_H
		eor #$80
		adc #OFFSET_Y
		eor #$80
		sta bulletY+(SHOTS_MAX-1)
		bvs @return

		lda #SPRITE04
		sta bulletSprite+(SHOTS_MAX-1)
		
		lda #DAMAGE
		sta PlayerBullet_damage+(SHOTS_MAX-1)

		lda #TRUE
		sta Shots_isActive+(SHOTS_MAX-1)

		lda #8
		sta Missiles_velocity

@return:
	rts

.endproc

;SHOT01	= $01;	Large star
;SHOT02	= $02;	Beam inside
;SHOT03	= $03;	Beam middle
;SHOT03	= $03;	Beam outside

Shots_sprite:
	


Shots_damage:

