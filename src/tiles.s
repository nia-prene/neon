.include "tiles.h"

.include "scenes.h"

.zeropage
tile128a: .res 1
tile128b: .res 1
tile64a: .res 1
tile64b: .res 1
tile64c: .res 1
tile64d: .res 1

.data
tiles128: .res 4
tiles64: .res 16
tiles32: .res 64

.code
unzipAllTiles:;(a)
;unzips all the tile for a scene
;arguments
;a next scene
;get the big tile	
	tax
	lda Scenes_tile,x
;start at tiles128[0]
	ldy #$00
	tax 
	lda topLeft256,x
	sta tiles128,y
	iny
	lda bottomLeft256,x
	sta tiles128,y
	iny
	lda topRight256,x
	sta tiles128,y
	iny
	lda bottomRight256,x
	sta tiles128,y
;now unzip all 64x64 in columns, 2 total
;start with column 0
	ldx #$00
;for(x = 0; x <4; x++)
@unzipAll64:
;save counter
	txa
	pha
	jsr unzip64Column;(a)
	pla
	tax
	inx
	cpx #02
	bne @unzipAll64
;move tiles from 64x64 to 32x32, 4 total;start with tile 0
	ldx #00
;for(x = 0; x < 4; x++)
@unzipAll32:
	txa
	pha
;a is column to unzip
	jsr unzip32Column;(a)
	pla
	tax
	inx
	cpx #04
	bne @unzipAll32
	rts

unzip64Column:;(x)
	;tiles are decompressed from one column of 128x128 to two columns of 64x64 tiles
;arguments
;a - column to update
;void
;convert column to array index
;save for return value
	asl
;x where they come from in 128x128
	tax
	asl
	asl
	tay
;y where they are going in 64x64
	;get first tile in column and save it
	lda tiles128,x
	sta tile128a
	inx
	;get second tile in column and save it
	lda tiles128,x
	sta tile128b
	;store the left hand sides of tile128a and 128b into tiles64 array
	ldx tile128a
	lda topLeft128,x
	sta tiles64,y
	iny
	lda bottomLeft128,x
	sta tiles64,y
	iny
	ldx tile128b
	lda topLeft128,x
	sta tiles64,y
	iny
	lda bottomLeft128,x
	sta tiles64,y
	iny
	;store the right hand sides of tile128a and 128b into tiles64 array
	ldx tile128a
	lda topRight128,x
	sta tiles64,y
	iny
	lda bottomRight128,x
	sta tiles64,y
	iny
	ldx tile128b
	lda topRight128,x
	sta tiles64,y
	iny
	lda bottomRight128,x
	sta tiles64,y
;return void
	rts

unzip32Column:;(a)
;unzips a 64x64 tile block column (1-4) into two 32x32 columns;
;arguments
;a - column to unzip (1-4)
;returns void
	asl
	asl
	tax;x where they are coming from
	asl
	asl
	tay;y where they are going
	;save the 4 tiles we are working with
	lda tiles64,x
	sta tile64a
	inx
	lda tiles64,x
	sta tile64b
	inx
	lda tiles64,x
	sta tile64c
	inx
	lda tiles64,x
	sta tile64d
	;ok lets unload the first column
	ldx tile64a
	lda topLeft64,x
	sta tiles32,y
	iny
	lda bottomLeft64,x
	sta tiles32,y
	iny
	ldx tile64b
	lda topLeft64,x
	sta tiles32,y
	iny
	lda bottomLeft64,x
	sta tiles32,y
	iny
	ldx tile64c
	lda topLeft64,x
	sta tiles32,y
	iny
	lda bottomLeft64,x
	sta tiles32,y
	iny
	ldx tile64d
	lda topLeft64,x
	sta tiles32,y
	iny
	lda bottomLeft64,x
	sta tiles32,y
	iny
	ldx tile64a
	lda topRight64,x
	sta tiles32,y
	iny
	lda bottomRight64,x
	sta tiles32,y
	iny
	ldx tile64b
	lda topRight64,x
	sta tiles32,y
	iny
	lda bottomRight64,x
	sta tiles32,y
	iny
	ldx tile64c
	lda topRight64,x
	sta tiles32,y
	iny
	lda bottomRight64,x
	sta tiles32,y
	iny
	ldx tile64d
	lda topRight64,x
	sta tiles32,y
	iny
	lda bottomRight64,x
	sta tiles32,y
	rts

.rodata
;;;;;;;;
;screens;
;256x256;
;;;;;;;;;
BEACH_SCREEN=0
topLeft256:
	.byte $00
bottomLeft256:
	.byte $01
topRight256:
	.byte $02
bottomRight256:
	.byte $03
;;;;;;;;;
;128x128;
;;;;;;;;;
topLeft128:
	.byte $00, $01, $05, $07
bottomLeft128:
	.byte $00, $02, $06, $08
topRight128:
	.byte $03, $03, $09, $0b
bottomRight128:
	.byte $03, $04, $0a, $0c
;;;;;;;
;64x64;
;;;;;;;
topLeft64:
	.byte $00, $00, $04, $08, $09, $0b, $0b, $0b, $0b, $0d, $0d, $11, $11
bottomLeft64:
	.byte $00, $02, $06, $08, $0a, $0b, $0b, $0b, $0b, $0d, $0f, $11, $13
topRight64:
	.byte $01, $01, $05, $0b, $0b, $0c, $0c, $10, $10, $14, $14, $14, $14
bottomRight64:
	.byte $01, $03, $07, $0b, $0b, $0c, $0e, $10, $12, $14, $14, $14, $14
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

