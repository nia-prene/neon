.include "patterns.h"
.include "lib.h"

.include "enemies.h" .include "bullets.h"


PATTERNS_MAX = 16
SPEEDS=4


.data
Patterns_timeElapsed: .res PATTERNS_MAX
p:.res PATTERNS_MAX

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
BULLETCOUNT=8

	pla
	tax
	lda Patterns_timeElapsed,x
	bit Rate_slow

	bne @noPattern
		
		lda #6
		sta Bullets_fastForwardFrames
		
		lda p,x
		pha

		clc
		adc #(SPEEDS * 3)
		sta p,x

		lda #BULLETCOUNT-1
		tay

		pla; restore
		pha; and save

	@bulletLoop:
		
		clc
		adc #(256 / BULLETCOUNT)
		pha
		dey
		bne @bulletLoop
		
		lda #BULLETCOUNT
		jmp Bullets_newGroup; void(x) |
@noPattern:
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

