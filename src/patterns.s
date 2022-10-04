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
		sta Enemies_ptr+0
		lda Patterns_H,y
		sta Enemies_ptr+1
		jmp (Enemies_ptr)

@return:
	rts

BITS_QUADRANT=%11000000
BITS_ANGLE=%11111100

PATTERN01=$01; reese test?
PATTERN02=$02; aimed string
PATTERN03=$03; aimed


.proc Pattern01
SHOTS=4
RATE=%11
BULLET_COUNT=4
BULLET_INVISIBILITY=24
FRAME_CHANGE=8*15
PATTERN_CHANGE=256/BULLET_COUNT
MAX_TIME=SHOTS*(RATE+1)

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

		clc
		lda mathTemp
		adc #PATTERN_CHANGE
		
		sta mathTemp
		sta Bullets_ID,y

		lda enemyYH,x
		sta enemyBulletYH,y
		
		lda enemyXH,x
		sta enemyBulletXH,y
		
		lda #BULLET_INVISIBILITY
		sta isEnemyBulletActive,y

		dec bulletCount
		bne @bulletLoop
		
@return:

	rts

.endproc

.proc Pattern02
INVISIBILITY = 8
RATE = %11111111
SPEED = 0

	lda #INVISIBILITY
	sta Bullets_fastForwardFrames

	lda Enemies_clock,x
	and #%00010011
	bne @return
		lda Enemies_clock,x
		and #%00011111
		bne @shoot
			jsr Bullets_aim; a(x) | x
			bit ROUND_4
			beq :+
				clc
				adc #4
			:and #BITS_ANGLE
			sta p,x
			jmp Bullets_new; cax) | x
		
	@shoot:
		clc
		lda p,x
		adc #1
		sta p,x
		jmp Bullets_new; cax) | x
@return:	
	rts

.endproc


.proc Pattern03
INVISIBILITY	=16
	
	lda #INVISIBILITY
	sta Bullets_fastForwardFrames

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

Patterns_L:
	.byte NULL,<Pattern01,<Pattern02,<Pattern03
Patterns_H:
	.byte NULL,>Pattern01,>Pattern02,>Pattern03

