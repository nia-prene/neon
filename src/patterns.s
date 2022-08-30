.include "patterns.h"
.include "lib.h"

.include "enemies.h" .include "bullets.h"


PATTERNS_MAX = 16
SPEEDS=4


.data
Patterns_timeElapsed: .res PATTERNS_MAX
p:.res PATTERNS_MAX

bulletCount: .res 1

.code

Patterns_new:; void(a,x) | x y

	sta Enemies_pattern,x; save the pattern
	
	lda #$ff
	sta Patterns_timeElapsed,x

	lda #0
	sta p,x

	rts


Patterns_tick:
	ldx #PATTERNS_MAX
@patternLoop:
	lda Enemies_pattern,x
	beq @nextPattern
		
		tay
		
		txa; save offset
		pha

		lda Patterns_H,y
		pha
		lda Patterns_L,y
		pha
		
		inc Patterns_timeElapsed,x; tick forward
@nextPattern:
	dex
	bpl @patternLoop
	rts


.proc pattern01
BULLETCOUNT=16
BULLET_INVISIBILITY=16
	pla
	tax
	lda Patterns_timeElapsed,x
	and #%00000111

	bne @noPattern
		
		lda p,x

		sta mathTemp

		clc
		adc #(SPEEDS * 63)
		sta p,x

		lda #BULLETCOUNT
		sta bulletCount

	@bulletLoop:
		
		clc
		lda mathTemp
		adc #(256 / BULLETCOUNT)
		
		sta mathTemp

		jsr Bullets_new; c,y() | x
		bcc @abort
		
		lda mathTemp
		sta Bullets_ID,y

		lda enemyYH,x
		sta enemyBulletYH,y
		
		lda enemyXH,x
		sta enemyBulletXH,y
		
		lda #BULLET_INVISIBILITY
		sta isEnemyBulletActive,y

		dec bulletCount
		bne @bulletLoop
		jmp @abort
		
@noPattern:
@abort:
	rts
.endproc

Rate_slow:
	.byte %1111
Rate_medium:
	.byte %11
Rate_fast:
	.byte %0

Patterns_L:
	.byte NULL, <(pattern01-1)
Patterns_H:
	.byte NULL, >(pattern01-1)

