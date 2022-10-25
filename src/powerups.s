.include "lib.h"
.include "powerups.h"

.include "enemies.h"
.include "sprites.h"
.include "player.h"
.include "apu.h"	


.data

POWERUPS_BIG 		= %11100000;		| b b b s s s s s|
POWERUPS_SMALL		= %00011111;		b - big powerups
Powerups_encoded:	.res 1;			s - small powerups
Powerups_count:		.res 1;			amount to release
Powerups_upgraded:	.res 1;			true if leveled up

POWERUPS_MAX		= 16

Powerups_active: 	.res POWERUPS_MAX;	enabled
Powerups_yPos: 		.res POWERUPS_MAX;	y coordinate
Powerups_xPos: 		.res POWERUPS_MAX;	x coordinate

.code


Powerups_get:
	ldy #POWERUPS_MAX-1;	start at end of collection

@loop:;				for each item
	lda Powerups_active,y;	if inactive
	beq @return
		dey;		tick down
		bpl @loop;	while items remain

		clc;		mark false
		rts;		c
@return:;	else return object
	sec;	return true
	rts;	c,y


Powerups_new:;			void(a,x) | x
; a - amount to release
; x - enemy releasing the powerup
	sta Powerups_encoded;	save powerup encoded byte

	and #POWERUPS_SMALL;	isolate small powerups
	sta Powerups_count;	save for loop iterator

@loop:;				creat N amount of powerups
	ldy Powerups_count;	get the remaining powerups
	
	clc
	lda enemyYH,x;		get enemy's y position
	eor #%10000000;		flip high bit
	adc @yOffset,y;		move away from enemy
	eor #%10000000;		flip high bit back
	bvc :+;			if set now, went off screen
		jmp @next
	:
	pha;			save y
	clc
	lda enemyXH,x;		get enemy's y position
	eor #%10000000;		flip high bit
	adc @xOffset,y;		move away from enemy
	eor #%10000000;		flip high bit back
	bvc :+	;		if still set, went off screen
		pla;		remove y
		jmp @next	
	:
	pha;			save x

	jsr Powerups_get;	y() | x	  get an empty powerup slot
	bcs :+;			return if full
		pla;		remove x
		pla;		remove y
		jmp @return
	:
	pla;			recall x
	sta Powerups_xPos,y;	set powerup x position
	pla;			recall y
	sta Powerups_yPos,y;	set powerup y position
	
	lda #POWERUP01
	sta Powerups_active,y;	set active
@next:

	dec Powerups_count
	bne @loop
@return:
	rts

@yOffset:	
	.lobytes  NULL,	 $00,	 $08,	 $08
	.lobytes  $08,	 $00
@xOffset:
	.lobytes  NULL,	 $00,	-$08,	 $08
	.lobytes  $00	-$08


Powerups_tick:
SPEED	= 1

	ldx #POWERUPS_MAX-1;	for each powerup
@loop:

	lda Powerups_active,x;	if powerup is active
	beq @next
		clc;			move the powerup down
		lda Powerups_yPos,x
		adc #SPEED
		sta Powerups_yPos,x
		bcc :+;			if overflow
			lda #FALSE;		clear powerup
			sta Powerups_active,x
		:
@next:
	dex;			tick down through collection
	bpl @loop;		while powerups left in collection

	rts;			void


Powerups_collect:

	lda #FALSE;		clear powerup 
	sta Powerups_upgraded

	ldx #POWERUPS_MAX-1;	for each powerup

@loop:
	lda Powerups_active,x;	if active
	beq @next;		else skip
		
		tay;				active byte is also ID
		sec
		lda Powerups_yPos,x;		find y distance
		sbc Player_yPos_H
		bcs :+;				if negative
			eor #%11111111;			ones compliment
		:
		cmp Powerups_diameter,y;	if y distance < diameter
		bcs @next;			else next
		
		sec
		lda Powerups_xPos,x;		find x distance
		sbc Player_xPos_H
		bcs :+;				if negative
			eor #%11111111;			ones compliment
		:
		cmp Powerups_diameter,y;	if x distance < diameter
		bcs @next;			else next
			clc
			lda Powerups_value,y;	get powerup value
			adc Player_power_l;	add to player's power
			sta Player_power_l
			bcc :+;			if hibyte changed
				inc Player_power_h;	increase hibyte
				lda #TRUE;		power increased
				sta Powerups_upgraded
			lda Player_power_l; clamp to max power
			cmp #<PLAYERS_POWER_MAX
			lda Player_power_h
			sbc #>PLAYERS_POWER_MAX
			bcc :+
				lda #<PLAYERS_POWER_MAX
				sta Player_power_l
				lda #>PLAYERS_POWER_MAX
				sta Player_power_h
			:
			lda #FALSE;		clear from game
			sta Powerups_active,x
@next:
	dex
	bpl @loop
	
	lda Powerups_upgraded;	if the power level increased
	beq :+
		lda #SFX03;		play the sound effect
		jsr SFX_newEffect
		lda #SFX04
		jsr SFX_newEffect
	:
	rts


POWERUP01	= $01;	small powerup
POWERUP02	= $02;	large powerup 

Powerups_sprite:
	.byte NULL,SPRITE26,SPRITE27

Powerups_value:
	.byte NULL,	$10,	$80

Powerups_diameter:
	.byte NULL,	$10,	$20
