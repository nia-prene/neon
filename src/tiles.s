.include "tiles.h"

.include "scenes.h"

.zeropage
Tiles_screenPointer: .res 2

.code
Tiles_getScreenPointer:
;x - scene number
	lda Scenes_screen,x
	tax
	lda screens_L,x
	sta Tiles_screenPointer
	lda screens_H,x
	sta Tiles_screenPointer+1
	rts

.rodata
;;;;;;;;
;screens;
;;;;;;;;;
SCREEN00=$0
screens_H:
	.byte >screen00
screens_L:
	.byte <screen00
screen00:
	.byte $00, $00, $00, $00, $00, $02, $04, $06
	.byte $01, $01, $01, $01, $01, $03, $05, $07
	.byte $08, $08, $08, $08, $08, $08, $09, $0a
	.byte $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b 
	.byte $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b 
	.byte $0c, $0c, $0c, $0e, $10, $10, $10, $12 
	.byte $0d, $0d, $0d, $0f, $11, $11, $11, $13 
	.byte $14, $14, $14, $14, $14, $14, $14, $14 
	
;;;;;;;
;32x32;
;;;;;;;
topLeft32:
	.byte $04, $04, $04, $04, $0a, $0a, $05, $05, $0c, $10, $0e, $03, $03, $13, $03, $17
	.byte $03, $1b, $03, $1d, $01
bottomLeft32:
	.byte $05, $05, $09, $09, $04, $04, $04, $04, $0e, $0c, $0c, $03, $03, $15, $03, $19
	.byte $03, $19, $03, $13, $01
topRight32:
	.byte $06, $08, $06, $08, $0b, $0b, $07, $07, $0d, $11, $0d, $03, $12, $01, $16, $01
	.byte $1a, $01, $1c, $01, $01
bottomRight32:
	.byte $07, $07, $07, $07, $06, $08, $06, $08, $0f, $0d, $0f, $03, $14, $01, $18, $01
	.byte $18, $01, $12, $01, $01
tileAttributeByte:
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %01010101, %01010101, %01010101, %01010101, %01010101, %10101010, %01010101, %10101010
	.byte %01010101, %10101010, %01010101, %10101010, %10101010
;;;;;;;
;16x16;
;;;;;;;
topLeft16:
	.byte $00, $01, $02, $03, $06, $09, $04, $03, $04, $09, $11, $13, $17, $19, $1d, $1f
	.byte $23, $25, $2a, $2d, $03, $32, $03, $37, $03, $30, $29, $35, $29, $35
bottomLeft16:
	.byte $00, $01, $02, $03, $03, $04, $06, $09, $06, $00, $04, $15, $1a, $1c, $20, $22
	.byte $26, $28, $03, $30, $29, $35, $2a, $2d, $03, $32, $2a, $2d, $03, $37
topRight16:
	.byte $00, $01, $02, $03, $07, $0a, $0b, $0d, $0f, $0a, $12, $14, $18, $03, $1e, $03
	.byte $24, $03, $2c, $2e, $2b, $33, $03, $38, $2f, $31, $34, $36, $34, $36
bottomRight16:
	.byte $00, $01, $02, $03, $08, $05, $0c, $0e, $07, $10, $0f, $16, $1b, $03, $21, $03
	.byte $27, $03, $2f, $31, $34, $36, $2c, $2e, $2b, $33, $2c, $2e, $03, $38
