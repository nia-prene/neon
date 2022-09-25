.include "lib.h"

TRUE 		= 01 
true 		= 01 
FALSE		= 00
false		= 00
TERMINATE 	= $ff
NULL 		= $00
null 		= $00
BUTTON_A 	= %10000000
BUTTON_B 	= %1000000
BUTTON_SELECT 	= %100000
BUTTON_START 	= %10000
BUTTON_UP 	= %1000
BUTTON_DOWN 	= %100
BUTTON_LEFT 	= %10
BUTTON_RIGHT 	= %1
.zeropage

mathTemp: .res 2

yReg:.res 1
xReg:.res 1

sprite1LeftOrTop: .res 1
sprite1RightOrBottom: .res 1
sprite2LeftOrTop: .res 1
sprite2RightOrBottom: .res 1
Lib_errorCode: .res 1
seed: .res 2
.segment "HEADER"
;contains ines header 

INES_MAPPER = 0 ; 0 = NROM
INES_MIRROR = 1 ; 0 = horizontal mirroring, 1 = vertical mirroring
INES_SRAM   = 0 ; 1 = battery backed SRAM at $6000-7FFF

.byte 'N', 'E', 'S', $1A ; ID
.byte $02 ; 16k PRG chunk count
.byte $01 ; 8k CHR chunk count
.byte INES_MIRROR | (INES_SRAM << 1) | ((INES_MAPPER & $f) << 4)
.byte (INES_MAPPER & %11110000)
.byte $0, $0, $0, $0, $0, $0, $0, $0 ; padding


.macro CheckAlign start, end, alignsize
    .align alignsize
    .assert (end-start) <= alignsize, error, "CheckAlign too large"
    .assert (end-start) > (alignsize/2), error, "CheckAlign too small"
.endmacro


.code


ROUND_2:
	.byte %1
ROUND_4:
	.byte %10
ROUND_8:
	.byte %100
ROUND_16:
	.byte %1000
ROUND_32:
	.byte %10000
ROUND_64:
	.byte %100000
ROUND_128:	
	.byte %1000000
ROUND_256:
	.byte %10000000


checkCollision:
;checks if two bound boxes intersect
;returns
;c - set if true clear if false
;first we are going to find which sprite is on the left and right
	lda sprite1LeftOrTop
	cmp sprite2LeftOrTop
	bmi @check2
;if sprite 1 is on the right and sprite 2's right side is greater than sprite 1's left side
	cmp sprite2RightOrBottom
	bmi @insideBoundingBox
@notInBoundingBox:
	clc
	rts
@check2:
	;if sprite 2 is on the right and sprite 2's left side is less than sprite 1's right side
	lda sprite2LeftOrTop
	cmp sprite1RightOrBottom
	bpl @notInBoundingBox
@insideBoundingBox:
	sec
	rts

Lib_generateSeed:
	
	lda seed+0
	bne :+
		lda #$AA
		sta seed+0
	:lda seed+1
	bne :+
		lda #$85
		sta seed+0
	:rts

Lib_getRandom:; a()

	ldy #8     ; iteration count
	lda seed+0
:
	asl        ; shift the register
	rol seed+1
	bcc :+
	eor #$39   ; apply XOR feedback whenever a 1 bit is shifted out
:
	dey
	bne :--
	sta seed+0
	cmp #0     ; reload flags

	rts
