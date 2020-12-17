.include "constants.s"
.segment "HEADER"
.include "header.s"
.include "ram.s"
.segment "STARTUP"
.include "init.s"
.segment "CODE"
main:
	lda #$00
	sta currentScene
	jsr clearRam
	jsr unzip
	jsr fullyRender
	bit PPUSTATUS
@notInBlank:
	bit PPUSTATUS
	bpl @notInBlank

	lda #PPU_SETTINGS
	sta PPUCTRL
	bit PPUSTATUS
	
	lda #$ff
	sta PPUSCROLL
	lda #$00
	sta PPUSCROLL

@vblankWait:
	bit PPUSTATUS
	bpl @vblankWait
	lda #MASK_SETTINGS
	sta PPUMASK
loop:
	inc loopTest
	jmp loop

nmi:
	pha;save registers
	txa
	pha
	tya
	pha
	
	lda #$00
	sta OAMADDR;reset OAM 
	
	lda #OAM_LOCATION
	sta OAMDMA
	;vblank code goes here

	pla
	tay
	pla;restore registers
	tax
	pla
	
	rti

clearRam:
	jsr clearSprites;()
	jsr clearNametables;()
	jsr loadDefaultPalettes;()
	rts

unzip:;(int currentScene)
	jsr getScenePointer
	jsr getTimeOfDay
	jsr getPlacePointer
	jsr unzipPlacePalettes
	jsr unzipAllScreens
	jsr unzipAll128
	jsr unzipAll64
	jsr unzipAll32

	rts


clearSprites:
	lda #$ff;clearing sprites with $ff puts them off screen
	ldx #$00
;clears the 1 page of data at "sprites" with ff
@clearSpritesLoop:
	sta sprites, x
	inx
	bne @clearSpritesLoop
	rts

clearNametables:
	lda #$20
	sta PPUADDR
	lda #$00
	sta PPUADDR
	tax
	ldy #08
@nametableClear:
	sta PPUDATA
	inx
	bne @nametableClear
	dey
	bne @nametableClear
	rts

loadDefaultPalettes:
	lda #$00
	tax
	sta backgroundColor ;a is still #$00, grey default color
	lda #$2b;background palettes get set to ugly palette so its noticable if something goes wrong
;stores #$2b into the first 16 palette locations
@loadDefaultBackgroundPalette:
	sta palettes, x
	inx
	cpx #16; 16 colors 
	bne @loadDefaultBackgroundPalette
	ldy #$00
	;y is 0, x is position in palettes array
;loads colors 16 - 36 with default sprite colors. if there arent enough people to fill a scene, random people will have unique palettes
@loadDefaultSpritePalettes:
	lda defaultPalette, y
	sta palettes, x
	inx
	iny
	cpx #32 ;32 total colors
	bne @loadDefaultSpritePalettes
	rts

getScenePointer:
	lda currentScene
	;find pointer to scene. it is in an array of pointers at "scenes:"
	;because an address is 16 bit, the number needs to be doubled in order to find the correct address. 
	asl	;double the number
	tax
	lda scenes, x
	sta scenePointer
	lda scenes+1, x
	sta scenePointer+1
	rts


getTimeOfDay:
	;0th element in scene array is the time of day
	ldy #TIMEOFDAY
	lda (scenePointer), y
	sta backgroundColor
	rts


getPlacePointer:
	ldy #LOCATION
	lda (scenePointer), y
	asl	;double the number
	tax
	;get the pointer to the place and store it in "placePointer"
	lda places,x
	sta placePointer
	lda places+1, x
	sta placePointer+1
	rts


unzipPlacePalettes:
	;first element of the place
	ldy #PLACEPALETTES
	ldx #12
@backgroundPaletteLoop:
	;this loop loads all the palettes from the place pointed at, 12 in total
	lda (placePointer), y
	sta palettes, y
	iny
	dex
	bne @backgroundPaletteLoop
	rts

unzipAllScreens:
	ldy #SCREENS
	ldx #$00
@screenLoop:
	lda (placePointer), y
	sta halfScreens,x
	iny
	inx
	cpx #04
	bne @screenLoop
	rts

unzipAll128:
;called during forced blank to unzip the entire tiles128 array
	lda #$00
	sta current128Column
	jsr unzip128Column
	inc current128Column
	jsr unzip128Column
	inc current128Column
	jsr unzip128Column
	inc current128Column
	jsr unzip128Column
	rts

unzip128Column:;(current128Column)
;the tiles128 array stores 8 128x128 from top to bottom in 4 rows of 2. they are loaded in by column
	lda current128Column
	tay;y where they are in the half screens array
	;chop off last 2 bits and store in target128Column
	and #%00000011
	asl
	tax;x where they are going
	;grab the screen from the array
	lda halfScreens,y
	tay;y is the screen
	lda topHalfScreen,y
	sta tiles128,x
	inx
	lda bottomHalfScreen,y
	sta tiles128,x
	rts

unzipAll64:
;called during forced blank to unzip the entire tiles64 array
	lda #$00
	sta current64Column
	jsr unzip64Column
	inc current64Column
	jsr unzip64Column
	inc current64Column
	jsr unzip64Column
	inc current64Column
	jsr unzip64Column
	rts

unzip64Column:
;tiles are decompressed from 8 128x128 blocks into 32 64x64 blocks. decompressed in columns
	lda current64Column;4 columns, 2 tiles wide
	and #%00000011
	asl
	tax;x where they come from
	asl
	asl
	tay;y where they are going
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
	rts

unzipAll32:
;called during forced blank to unzip entire tiles32 array
	lda #$00
	sta current32Column
	jsr unzip32Column
	inc current32Column
	jsr unzip32Column
	inc current32Column
	jsr unzip32Column
	inc current32Column
	jsr unzip32Column
	inc current32Column
	jsr unzip32Column
	inc current32Column
	jsr unzip32Column
	inc current32Column
	jsr unzip32Column
	inc current32Column
	jsr unzip32Column
	rts

unzip32Column:
	;tiles32 is a 128 byte array that stores 32x32 tiles in 16 columns of 8 tiles. tiles are rendered from this array and referenced at this level for collision detection and palette information. tiles are unzipped by column at the 64x64 level, so to columns (16 tiles) at a time
	lda current32Column
	;validate input
	and #%00000111
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
	iny
	rts
	
fullyRender:
	jsr loadPalettes
	jsr renderEntireScreen

	rts
;this subroutine transfers all palettes to the ppu
loadPalettes:
	lda #$3f
	sta PPUADDR
	lda #$00
	tay
	sta PPUADDR
	ldx #32	
@mainPaletteLoop:
	lda palettes, y
	sta PPUDATA
	iny
	dex
	bne @mainPaletteLoop
	lda #$3f
	sta PPUADDR
	tya 
	sta PPUADDR
	lda backgroundColor
	sta PPUDATA 
	rts

renderEntireScreen:
	lda #$00
	sta tileToRender
@renderScreenLoop:
	jsr render32
	inc tileToRender
	bpl @renderScreenLoop
	rts

render32:
;this renders a 32x32 tile from the tiles32 array.
;variables
;tileToRender the position of the tile in the array.
	;render at normal ppu settings
	lda #PPU_SETTINGS
	sta PPUCTRL
	lda tileToRender
	;validate input
	and #%011111111
	tax;x is tile number in array
	asl
	tay;y is nametable reference pos
	lda tileToRender
	;all tiles ending in 111 are shorter
	and #%00000111
	cmp #%00000111
	bne @standardTile
	;below is shortened tile
	;save the 2 tiles
	lda tiles32,x
	tax;x is now the 32x32 tile
	lda topLeft32,x
	sta tile16a
	lda topRight32,x
	sta tile16c
	;look up nametable conversion, save them and put them in ppu
	lda nameTableConversion,y
	sta currentNameTable
	sta PPUADDR
	iny
	lda nameTableConversion,y
	sta currentNameTable+1
	sta PPUADDR
	;now the ppu knows where to put our tile
	ldx tile16a
	lda topLeft16,x
	sta PPUDATA
	lda bottomLeft16,x
	sta PPUDATA
	inc currentNameTable+1
	lda currentNameTable
	sta PPUADDR
	lda currentNameTable+1
	sta PPUADDR
	lda topRight16,x
	sta PPUDATA
	lda bottomRight16,x
	sta PPUDATA
	inc currentNameTable+1
	lda currentNameTable
	sta PPUADDR
	lda currentNameTable+1
	sta PPUADDR
	ldx tile16c
	lda topLeft16,x
	sta PPUDATA
	lda bottomLeft16,x
	sta PPUDATA
	inc currentNameTable+1
	lda currentNameTable
	sta PPUADDR
	lda currentNameTable+1
	sta PPUADDR
	lda topRight16,x
	sta PPUDATA
	lda bottomRight16,x
	sta PPUDATA
	jmp @attributeByte

@standardTile:
	;save the 4 tiles
	lda tiles32,x
	tax;x is now the 32x32 tile
	lda topLeft32,x
	sta tile16a
	lda bottomLeft32,x
	sta tile16b
	lda topRight32,x
	sta tile16c
	lda bottomRight32,x
	sta tile16d
	;look up nametable conversion, save them and put them in ppu
	lda nameTableConversion,y
	sta currentNameTable
	sta PPUADDR
	iny
	lda nameTableConversion,y
	sta currentNameTable+1
	sta PPUADDR
	;now the ppu knows where to put our tile
	ldx tile16a
	ldy tile16b
	lda topLeft16,x
	sta PPUDATA
	lda bottomLeft16,x
	sta PPUDATA
	lda topLeft16,y
	sta PPUDATA
	lda bottomLeft16,y
	sta PPUDATA
	inc currentNameTable+1
	lda currentNameTable
	sta PPUADDR
	lda currentNameTable+1
	sta PPUADDR
	lda topRight16,x
	sta PPUDATA
	lda bottomRight16,x
	sta PPUDATA
	lda topRight16,y
	sta PPUDATA
	lda bottomRight16,y
	sta PPUDATA
	inc currentNameTable+1
	lda currentNameTable
	sta PPUADDR
	lda currentNameTable+1
	sta PPUADDR
	ldx tile16c
	ldy tile16d
	lda topLeft16,x
	sta PPUDATA
	lda bottomLeft16,x
	sta PPUDATA
	lda topLeft16,y
	sta PPUDATA
	lda bottomLeft16,y
	sta PPUDATA
	inc currentNameTable+1
	lda currentNameTable
	sta PPUADDR
	lda currentNameTable+1
	sta PPUADDR
	lda topRight16,x
	sta PPUDATA
	lda bottomRight16,x
	sta PPUDATA
	lda topRight16,y
	sta PPUDATA
	lda bottomRight16,y
	sta PPUDATA

@attributeByte:
	;get the attribute byte
	lda tileToRender
	tay;y is tile pos in tiles32 array
	asl
	tax;x is position in conversion
	lda attributeTableConversion,x
	;store address (big endian)
	sta PPUADDR
	inx
	lda attributeTableConversion,x
	sta PPUADDR
	lda tiles32,y
	tay;y is tile itself
	lda tileAttributeByte,y
	;yeet the attribute byte
	sta PPUDATA
	
	rts

.include "data.s"
.segment "VECTORS"
.word nmi
.word reset

.segment "CHARS"
.incbin "graphics.chr"
