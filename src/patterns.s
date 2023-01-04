.include "patterns.h"
.include "lib.h"

.include "enemies.h" 
.include "bullets.h"


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

PATTERN01	= $01; 		reese patterns
PATTERN02	= $02;		aimed fairy
PATTERN03	= $03;		aimed mushroom
PATTERN04	= $04;		baloon cannon
PATTERN05	= $05;		reese handguns
PATTERN06	= $06;		reese charge forward
PATTERN07	= $07;		reese spray backward
PATTERN08	= $08;		reese recovery pattern
PATTERN09	= $09;		reese ball forward
PATTERN0A	= $0A;		
PATTERN0B	= $0B;		


.proc Pattern01
RATE			= %1111111
BULLET_COUNT		= 08
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
		
		lda mathTemp
		sta Bullets_ID,y

		lda enemyYH,x
		sta enemyBulletYH,y
		
		lda enemyXH,x
		sta enemyBulletXH,y
		
		lda #TYPE
		sta Bullets_type,y

		lda #BULLET_INVISIBILITY
		sta isEnemyBulletActive,y
		
		clc
		lda mathTemp
		adc #PATTERN_CHANGE
		and #%01111111
		sta mathTemp

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
			and #BITS_ANGLE;	isolate angle
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
TYPE		= 1
	
	lda #INVISIBILITY
	sta Bullet_invisibility
	lda #TYPE
	sta Bullet_type

	lda Enemies_clock,x
	bne @return
		jsr Bullets_aim
		and #BITS_ANGLE
		jmp Bullets_new
@return:
	rts

.endproc

.proc Pattern04
INVISIBILITY	= 16
RATE		= %111111	
SPEED		= BITS_ANGLE
COUNT		= 4
SEPARATION	= 16
TYPE			= 3
	
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
		adc #8
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
			and #BITS_ANGLE;	isolate angle
			sta p,x;		save bullet
			rts
	@shoot:
		clc;			offset to next shot
		lda p,x
		adc #1
		sta p,x
		jmp Bullets_new;	c(a,x) | x	new bullet
@return:	
	rts

.endproc


.proc Pattern06
RATE		= %11
COUNT		= 4
INVISIBILITY	= 2
FRAME_CHANGE	= 12
PATTERN_CHANGE	= 128/COUNT
TYPE		= 1

	lda Enemies_clock,x
	and #RATE
	bne @return

		lda p,x
		sta mathTemp
		
		clc
		adc #FRAME_CHANGE
		and #%01111111

		sta p,x

		lda #COUNT
		sta bulletCount

	@bulletLoop:
		
		jsr Bullets_get; c,y() | x
		bcc @return
		
		lda mathTemp
		sta Bullets_ID,y

		lda enemyYH,x
		sta enemyBulletYH,y
		
		lda enemyXH,x
		sta enemyBulletXH,y
		
		lda #TYPE
		sta Bullets_type,y

		lda #INVISIBILITY
		sta isEnemyBulletActive,y
		
		clc
		lda mathTemp
		adc #PATTERN_CHANGE
		and #%01111111
		sta mathTemp

		dec bulletCount
		bne @bulletLoop
		
@return:
	rts

.endproc


.proc Pattern07
RATE 		= %111
INVISIBILITY	= 8
TYPE 		= 2

	lda Enemies_clock,x
	and #RATE
	bne @return
		lda #INVISIBILITY
		sta Bullet_invisibility

		lda #TYPE
		sta Bullet_type
	
		clc
		lda p,x
		adc #13
		and #%01111111
		sta p,x
		and #%01000000
		bne :+
			lda p,x
			ora #%00110000
			jmp :++
			:
			lda p,x
			and #%11001111
		:
		jmp Bullets_new

@return:
	rts

.endproc

.proc Pattern08
RATE			= %11111
BULLET_COUNT		= 08
BULLET_INVISIBILITY	= 32
FRAME_CHANGE		= 4*3
PATTERN_CHANGE		= 256/BULLET_COUNT
TYPE			= 1

	lda Enemies_clock,x
	and #RATE
	bne @return

		lda p,x
		sta mathTemp
		
		clc
		adc #FRAME_CHANGE

		sta p,x

		lda #BULLET_COUNT
		sta bulletCount

	@bulletLoop:
		
		jsr Bullets_get; c,y() | x
		bcc @return
		
		lda mathTemp
		sta Bullets_ID,y

		lda enemyYH,x
		sta enemyBulletYH,y
		
		lda enemyXH,x
		sta enemyBulletXH,y
		
		lda #TYPE
		sta Bullets_type,y

		lda #BULLET_INVISIBILITY
		sta isEnemyBulletActive,y
		
		clc
		lda mathTemp
		adc #PATTERN_CHANGE
		sta mathTemp

		dec bulletCount
		bne @bulletLoop
		
@return:
	rts
.endproc


.proc Pattern09
RATE	= %00001111
BULLET = %01000000 -1
SPEED	= %11
	lda Enemies_clock,x
	and #RATE
	bne @return
		jsr Bullets_aim
		ora #SPEED
		jmp Bullets_new; c(a,x) | x
@return:
	rts
.endproc
.proc Pattern0A
.endproc
.proc Pattern0B
.endproc

Patterns_L:
	.byte NULL,<Pattern01,<Pattern02,<Pattern03
	.byte <Pattern04,<Pattern05,<Pattern06,<Pattern07
	.byte <Pattern08,<Pattern09,<Pattern0A,<Pattern0B
Patterns_H:
	.byte NULL,>Pattern01,>Pattern02,>Pattern03
	.byte >Pattern04,>Pattern05,>Pattern06,>Pattern07
	.byte >Pattern08,>Pattern09,>Pattern0A,>Pattern0B
