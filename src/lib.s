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
regA:.res 1

Lib_ptr0: .res 2
Lib_ptr1: .res 2
Lib_ptr2: .res 2
NMIptr0: 	.res 2

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

