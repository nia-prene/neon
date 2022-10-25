.include "palettes.h"

.include "lib.h"
.include "scenes.h"
.include "ppu.h"

.data
NUMBER_OF_PALETTES=8
backgroundColor: .res 1
color1: .res NUMBER_OF_PALETTES
color2: .res NUMBER_OF_PALETTES
color3: .res NUMBER_OF_PALETTES
Palettes_hasChanged: .res NUMBER_OF_PALETTES

.rodata
PALETTE00=0; player palette
PALETTE01=1; bg lvl 1
PALETTE02=2; bg lvl 1
PALETTE03=3; bg lvl 1
PURPLE_BULLET=5
PALETTE06=6; blue/white fairy
PALETTE07=7; red mushroom
PALETTE08=$08;orange piper palette
PALETTE09=$09;green piper palette palette
PALETTE0A=$0a;player 1 portrait
PALETTE0B=$0b; orange baloon cannon
PALETTE0C=$0C; turquise fairy

romColor1:
	.byte $07, $17, $3b, $01, $1d, $04, $02, $05
	.byte $07, $07, $07, $01, $0C
romColor2:
	.byte $25, $2a, $23, $21, $05, $24, $36, $15
	.byte $26, $29, $15, $26, $35
romColor3:
	.byte $35, $39, $37, $31, $30, $34, $30, $30
	.byte $36, $36, $35, $36, $3B

;;;;;;;;;;;;;
;collections;
;;;;;;;;;;;;;
BEACH_PALETTE = 0
palette0:
	.byte PALETTE01
palette1:
	.byte PALETTE02
palette2:
	.byte PALETTE03
palette3:
	.byte 00

.code
setPalette:;(x, y)
;sets a palette to one of 8 possible locations on screen.palette
;arguments - 
;x - single palette to load
;y - target palette slot
;returns void
	lda romColor1,x
	sta color1,y
	lda romColor2,x
	sta color2,y
	lda romColor3,x
	sta color3,y
	lda #TRUE
	sta Palettes_hasChanged,y
	rts

setPaletteCollection:;(x)
	;takes in a scene and loads in background palettes (0-3) from a collection
;arguments
;x - current scene
;returns void
;a is collection for the scene
	lda Scenes_backgroundColor,x
	sta backgroundColor
	lda Scenes_palettes,x
;save it
	pha
;x is now the collection number
	tax
	lda palette0,x
;x is now the palette
	tax
;y will be target palette in ram
	ldy #$00
	jsr setPalette
;retrieve palette collection
	pla
	pha
;x is now the collection number
	tax
	lda palette1,x
	tax
;x is now the palette
	ldy #01
;color 0 is always constant
	jsr setPalette
;retrieve palette collection
	pla
	pha
;x is now the collection number
	tax
	lda palette2,x
	tax
;x is now the palette
	ldy #02
;color 0 is always constant
	jsr setPalette
;retrieve palette collection
	pla
;x is now the collection number
	tax
	lda palette3,x
	tax
;x is now the palette
	ldy #03
	jmp setPalette

