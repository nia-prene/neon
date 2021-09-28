.include "palettes.h"

.include "scenes.h"

.data
BACKGROUND_COLOR = $0f;black
backgroundColor: .res 1
color1: .res 8
color2: .res 8
color3: .res 8

.rodata
PLAYER_PALETTE= 0
BEACH_0= 1
BEACH_1= 2
BEACH_2= 3
TARGET_PALETTE=4
PURPLE_BULLET=5
PALETTE06=6;blue drone palette
romColor1:
	.byte $07, $17, $2b, $01, $1d, $04, $1d
romColor2:
	.byte $25, $19, $23, $21, $05, $24, $21
romColor3:
	.byte $35, $29, $37, $31, $30, $34, $31
;;;;;;;;;;;;;
;collections;
;;;;;;;;;;;;;
BEACH_PALETTE = 0
palette0:
	.byte BEACH_0
palette1:
	.byte BEACH_1
palette2:
	.byte BEACH_2
palette3:
	.byte BEACH_2

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
	rts

setPaletteCollection:;(x)
	;takes in a scene and loads in background palettes (0-3) from a collection
;arguments
;x - current scene
;returns void
;a is collection for the scene
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
