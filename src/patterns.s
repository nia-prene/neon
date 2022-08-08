.include "patterns.h"
.include "lib.h"

.include "enemies.h"
.include "bullets.h"
.data
PATTERNS_MAX = 16
SPEEDS=4
Patterns_timeELapsed:.res PATTERNS_MAX
p:.res PATTERNS_MAX

.code

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

@nextPattern:
	dex
	bpl @patternLoop
	rts

pattern01:
	pla
	tax
	lda #16
	sta Bullets_fastForwardFrames
	lda p,x
	clc
	adc #(SPEEDS * 3)
	sta p,x
	jmp Bullets_new

Patterns_L:
	.byte NULL, <(pattern01-1)
Patterns_H:
	.byte NULL, >(pattern01-1)

