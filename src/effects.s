.include "effects.h"

.include "lib.h"
.include "sprites.h"


.zeropage

e: .res 1

.data

EFFECTS_MAX	= 16

Effects_active: 	.res EFFECTS_MAX
Effects_yPos: 		.res EFFECTS_MAX
Effects_xPos: 		.res EFFECTS_MAX

Effects_animation: 	.res EFFECTS_MAX
Effects_frame: 		.res EFFECTS_MAX
Effects_sprite: 	.res EFFECTS_MAX


.code


Effects_get:;	c,y() | x
	ldy #EFFECTS_MAX-1

@loop:
	lda Effects_active,y
	beq @return
		dey
		bpl @loop
		clc
		rts
@return:
	sec
	rts; c,y


Effects_tick:

	ldx #EFFECTS_MAX-1;	start at end of collection

@loop:;				for each effect
	lda Effects_active,x;	if active
	beq @next;		else skip

		dec Effects_active,x;	tick frame down
		bne :+;			if 0
			jsr Effects_tickAnimation;	get next frame
		:;			endif
@next:
	dex;			next item
	bpl @loop;		while items left in collection

	rts;			return void


Effects_tickAnimation:
	
	ldy Effects_animation,x;	get animation object
	
	lda Animations_l,y;		get animation pointer
	sta Lib_ptr0+0
	lda Animations_h,y
	sta Lib_ptr0+1

	ldy Effects_frame,x;		get animation frame

	lda (Lib_ptr0),y;		get next sprite
	bne :+;				null terminated
		lda #FALSE
		sta Effects_active,x;	deactivate
		rts
	:
	sta Effects_sprite,x;		save sprite
	iny

	lda (Lib_ptr0),y;		get frame count byte
	sta Effects_active,x;		save frame count
	iny
	tya
	sta Effects_frame,x;		save animation frame
	rts
	


