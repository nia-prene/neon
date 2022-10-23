.include "patterns.h"
.include "lib.h"

.include "enemies.h" .include "bullets.h"


PATTERNS_MAX = 16
SPEEDS=4

.zeropage
bulletCount: .res 1

.data
p:.res PATTERNS_MAX
q:.res PATTERNS_MAX


.code

Patterns_new:; void(a,x) | x,y

	sta Enemies_pattern,x; save the pattern

	lda #0; todo something with difficulty
	sta p,x
	sta q,x

	rts


Patterns_tick:; void(x)
	ldy Enemies_pattern,x
	beq @return
		
		lda Patterns_L,y
		sta Lib_ptr0+0
		lda Patterns_H,y
		sta Lib_ptr0+1
		jmp (Lib_ptr0)

@return:
	rts

BITS_QUADRANT=%11000000
BITS_ANGLE=%11111100

PATTERN01=$01; 			reese patterns
PATTERN02=$02;			aimed fairy
PATTERN03=$03;			aimed mushroom
PATTERN04=$04;			baloon cannon
PATTERN05=$05;			Reese handguns


.proc Pattern01
RATE			= %1111111
BULLET_COUNT		= 16
BULLET_INVISIBILITY	= 32
FRAME_CHANGE		= 4
PATTERN_CHANGE		= 128/BULLET_COUNT
TYPE			= 1

	lda Enemies_clock,x
	and #RATE
	bne @return

		lda p,x
		sta mathTemp
		
		clc
		adc #FRAME_CHANGE
		and #%01111111

		sta p,x

		lda #BULLET_COUNT
		sta bulletCount

	@bulletLoop:
		
		jsr Bullets_get; c,y() | x
		bcc @return

		clc
		lda mathTemp
		adc #PATTERN_CHANGE
		
		sta mathTemp
		sta Bullets_ID,y

		lda enemyYH,x
		sta enemyBulletYH,y
		
		lda enemyXH,x
		sta enemyBulletXH,y
		
		lda #TYPE
		sta Bullets_type,y

		lda #BULLET_INVISIBILITY
		sta isEnemyBulletActive,y

		dec bulletCount
		bne @bulletLoop
		
@return:

	rts

.endproc

.proc Pattern02
INVISIBILITY 	= 8
RATE 		= %00110011
SPEED 		= 0
TYPE		= 1
AIM		= %00001111

	lda Enemies_clock,x;	if firing
	and #RATE
	bne @return;		else return
		lda #INVISIBILITY;		set invisibility
		sta Bullet_invisibility
		lda #TYPE;			set type
		sta Bullet_type

		lda Enemies_clock,x;		if aiming frame
		and #AIM
		bne @shoot
			jsr Bullets_aim; a(x) | x	aim bullet
			bit ROUND_4;		round to nearest 4
			beq :+
				clc;		round up
				adc #4
			:and #BITS_ANGLE;	isolate angle
			sta p,x;		save bullet
			jmp Bullets_new; 	c(a,x) | x 	new bullet
		
	@shoot:
		clc;			offset to next shot
		lda p,x
		adc #1
		sta p,x
		jmp Bullets_new;	c(a,x) | x	new bullet
@return:	
	rts

.endproc


.proc Pattern03
INVISIBILITY	=16
TYPE			= 1
	
	lda #INVISIBILITY
	sta Bullet_invisibility
	lda #TYPE
	sta Bullet_type

	lda Enemies_clock,x
	bne @return
		jsr Bullets_aim
		bit ROUND_4
		beq :+
			clc
			adc #4
		:
		and #BITS_ANGLE
		jmp Bullets_new
@return:
	rts

.endproc

.proc Pattern04
INVISIBILITY	= 16
RATE		= %11001111	
SPEED		= BITS_ANGLE
COUNT		= 4
SEPARATION	= 16
TYPE			= 1
	
	lda Enemies_clock,x
	and #RATE
	bne @return
		lda #INVISIBILITY
		sta Bullet_invisibility
		lda #TYPE
		sta Bullet_type
		lda Enemies_clock,x
		bne :+
			jsr Bullets_aim
			and #SPEED
			sec
			sbc #((SEPARATION /2)+(SEPARATION*(COUNT/4))); 
			sta p,x
		:
		lda p,x
		sta mathTemp
		lda #COUNT
		sta bulletCount
	@loop:
		
		lda mathTemp
		jsr Bullets_new; c(x) | x
		
		clc
		lda mathTemp
		adc #SEPARATION
		sta mathTemp

		dec bulletCount
		bne @loop
		
		clc
		lda p,x
		adc #5
		sta p,x

@return:
	rts

.endproc


.proc Pattern05
TYPE		= 2
INVISIBILITY 	= 8
RATE 		= %00100111
AIM		= %00111111

	lda Enemies_clock,x;	if firing
	and #RATE
	bne @return;		else return
		lda #INVISIBILITY;		set invisibility
		sta Bullet_invisibility
		lda #TYPE;			set type
		sta Bullet_type

		lda Enemies_clock,x;		if aiming frame
		and #AIM
		bne @shoot
			jsr Bullets_aim; a(x) | x	aim bullet
			bit ROUND_4;		round to nearest 4
			beq :+
				clc;		round up
				adc #4
			:and #BITS_ANGLE;	isolate angle
			sta p,x;		save bullet
			jmp Bullets_new; 	c(a,x) | x 	new bullet
		
	@shoot:
		clc;			offset to next shot
		lda p,x
		adc #1
		sta p,x
		jmp Bullets_new;	c(a,x) | x	new bullet
@return:	
	rts

.endproc

Patterns_L:
	.byte NULL,<Pattern01,<Pattern02,<Pattern03
	.byte <Pattern04,<Pattern05
Patterns_H:
	.byte NULL,>Pattern01,>Pattern02,>Pattern03
	.byte >Pattern04,>Pattern05
