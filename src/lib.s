.include "lib.h"

TRUE = $01 
FALSE = $00
NULL = $ff

.zeropage
mathTemp: .res 2
sprite1LeftOrTop: .res 1
sprite1RightOrBottom: .res 1
sprite2LeftOrTop: .res 1
sprite2RightOrBottom: .res 1
Lib_errorCode: .res 1

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

.code
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

