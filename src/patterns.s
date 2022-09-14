.include "patterns.h"
.include "lib.h"

.include "enemies.h" .include "bullets.h"


PATTERNS_MAX = 16
SPEEDS=4


.data
Patterns_timeElapsed: .res PATTERNS_MAX
p:.res PATTERNS_MAX
q:.res PATTERNS_MAX

bulletCount: .res 1

.code

Patterns_new:; void(a,x) | x,y

	sta Enemies_pattern,x; save the pattern
	
	lda #$ff
	sta Patterns_timeElapsed,x

	lda #0
	sta p,x
	sta q,x

	rts


Patterns_tick:
	ldx #PATTERNS_MAX-1
Patterns_loop:
	ldy Enemies_pattern,x
	beq Patterns_tickDown
		
		lda Patterns_L,y
		sta Enemies_ptr+0
		lda Patterns_H,y
		sta Enemies_ptr+1
		
		txa; save offset
		jmp (Enemies_ptr)
	Patterns_tickReturn:

		inc Patterns_timeElapsed,x; tick forward
		
Patterns_tickDown:
	dex
	bpl Patterns_loop
	rts

PATTERN01=$01

.proc pattern01
SHOTS=4
RATE=%11
BULLET_COUNT=4
BULLET_INVISIBILITY=24
FRAME_CHANGE=8*15
PATTERN_CHANGE=256/BULLET_COUNT
MAX_TIME=SHOTS*(RATE+1)

	lda Patterns_timeElapsed,x
	and #RATE
	bne @noPattern

		lda p,x
		sta mathTemp
		
		clc
		adc #FRAME_CHANGE

		sta p,x

		lda #BULLET_COUNT
		sta bulletCount

	@bulletLoop:
		
		jsr Bullets_get; c,y() | x
		bcc @abort

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
		
@noPattern:
@abort:
	jmp Patterns_tickReturn
.endproc

Rate_slow:
	.byte %1111
Rate_medium:
	.byte %11
Rate_fast:
	.byte %0

Patterns_L:
	.byte NULL, <(pattern01)
Patterns_H:
	.byte NULL, >(pattern01)

