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
	jsr initializePlayer
	jsr loadNewScene

gameLoop:
;if(hasFrameBeenRendered == false)
	lda hasFrameBeenRendered
;jmp to gameLoop
	beq gameLoop
	jsr updateObjects	

;hasFrameBeenRendered = false
	lda #false
	sta hasFrameBeenRendered
	jmp gameLoop



initializePlayer:
	ldy #04;sprite palettes start@4
	lda paletteColor1,x
	sta color1,y
	lda paletteColor2,x
	sta color2,y
	lda paletteColor3,x
	sta color3,y
;player is in 0th object in ram
	ldx #00
	stx objectToInitialize
	lda #REESE_OBJECT
	sta spriteObject,x
	tay
;y is rom, x is ram
;set previous metasprite to null
	lda #null
	sta previousMetaSprite,x
;null out previous x and y
	sta previousX,x
	sta previousY,x
	lda spriteState0,y
;currentMetaSprite is now state 0
	sta currentMetaSprite,x
	
;get the inputs
	lda inputMethod,y
;y is input function number
;x is object in ram
	tay
;put the address in the object
	lda spriteInputsH,y
	sta inputsH,x
	lda spriteInputsL,y
	sta inputsL,x
;player starts at sprite 1 in ram
;sprite 0 is for parallax purposes
	lda #01
;which is at 4th address in oam
	asl;double it
	asl;quadruple it
;this is the offset conversion
	sta oamOffset,x
	lda spriteObject,x
	tay
;y is object in rom, x is ram
;get the width
	lda spriteWidth,y
	sta metaSpriteWidth,x
;get the height
	lda spriteHeight,y
	sta metaSpriteHeight,x
;get sprite total
	lda spriteTotal,y
	sta spriteTileTotal,x
;put it at this coordinate for now	
	lda #$55
	sta spriteX,x
	lda #$9e
	sta spriteY,x
	rts

loadNewScene:
	jsr disableRendering
	jsr clearRam
	jsr unzipTiles
	jsr unzipPalettes
	jsr renderTiles
	jsr renderPalettes
	jsr enableRendering
	jsr resetClock
	rts

clearRam:;()
	jsr clearSprites;()
	jsr clearNametables;()
	rts

unzipTiles:;(unsigned currentScene)
	jsr unzipScreen
	jsr unzipAll64
	jsr unzipAll32
	rts

unzipPalettes:
	ldx currentScene
;get background color
	lda sceneBackgroundColor,x
	sta backgroundColor
;get background palettes
;background palette 0
	ldy #$00
	lda backgroundPalette0,x
	tax
	lda paletteColor1,x
	sta color1,y
	lda paletteColor2,x
	sta color2,y
	lda paletteColor3,x
	sta color3,y
	iny
;background palette 0
	ldx currentScene
	lda backgroundPalette1,x
	tax
	lda paletteColor1,x
	sta color1,y
	lda paletteColor2,x
	sta color2,y
	lda paletteColor3,x
	sta color3,y
	iny
;background palette 2
	ldx currentScene
	lda backgroundPalette2,x
	tax
	lda paletteColor1,x
	sta color1,y
	lda paletteColor2,x
	sta color2,y
	lda paletteColor3,x
	sta color3,y
	iny;skip background palette 3
	iny;skip player sprite
	iny
	ldx currentScene
;sprite palette1
	ldx currentScene
	lda spritePalette1,x
	tax
	lda paletteColor1,x
	sta color1,y
	lda paletteColor2,x
	sta color2,y
	lda paletteColor3,x
	sta color3,y
	iny
;sprite palette2
	ldx currentScene
	lda spritePalette2,x
	tax
	lda paletteColor1,x
	sta color1,y
	lda paletteColor2,x
	sta color2,y
	lda paletteColor3,x
	sta color3,y
	;skip sprite palette 3

clearSprites:
;see oam in ram.s
;clear sprites with $ff in x and y coordinates puts them off screen
;set sprite number to $ff
	lda #$ff
;0-3 will always be sprite interrupt
;4-51 will always be player sprite
	ldx #52
;for y = 0; y!=
	ldy #$00
@moveOffScreen:
;set y, x, attribute and tile to ff
	sta oam,x
	inx
	bne @moveOffScreen
;64 total, 12 player, 52 cleared
;set previosMetatile to null
;a is still $ff and $ff = null
;player is 0 don't set null
;for x=0;x<8;x++
	ldx #$01
@setPreviousSpriteToNull:
	sta previousMetaSprite,x
	sta currentMetaSprite,x
	inx
	cpx #8
	bmi @setPreviousSpriteToNull
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


unzipScreen:;(currentScene)
;unzips 256 tile into tiles128
;access the screenTile array at currentScene index
	ldx currentScene
	lda screenTile,x
	tax;screenTile index is in x
	lda topLeft256,x
	ldy #$00
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

;this subroutine transfers all palettes to the ppu
renderPalettes:
	;clear vblank flag before write
	bit PPUSTATUS
	lda currentPPUSettings
	and #INCREMENT_1
	sta PPUCTRL

	lda #$3f
	sta PPUADDR
	lda #$00
	sta PPUADDR
	tax
@loadPalettes:
	lda color0,x
	sta PPUDATA
	lda color1,x
	sta PPUDATA
	lda color2,x
	sta PPUDATA
	lda color3,x
	sta PPUDATA
	inx
	cpx #$08;8 palettes
	bne @loadPalettes
	lda #$3f
	sta PPUADDR
	lda #$00
	sta PPUADDR
	lda backgroundColor
	sta PPUDATA
	rts

renderTiles:
	lda #$00
	sta tileToRender
@renderScreenLoop:
	jsr render32
	inc tileToRender
	lda tileToRender
	cmp #64
	bne @renderScreenLoop
	rts

render32:
;this renders a 32x32 tile from the tiles32 array.
;variables
;tileToRender the position of the tile in the array.
	;render at ppu address increments of 32
	;clear vblank bit before write
	bit PPUSTATUS
	lda currentPPUSettings
	ora #INCREMENT_32
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

enableRendering:
	lda #false
	sta isInBlank
	lda #true
@waitForBlank:
	bit isInBlank
	beq @waitForBlank
	lda currentMaskSettings
	ora #ENABLE_RENDERING
	sta PPUMASK
	sta currentMaskSettings
	rts

disableRendering:
	lda #false
	sta isInBlank
	lda #true
@waitForBlank:
	bit isInBlank
	beq @waitForBlank
	lda currentMaskSettings
	and #DISABLE_RENDERING
	sta PPUMASK
	sta currentMaskSettings
	rts

resetClock:
	lda #$00
;seconds = 0
	sta seconds
;minutes = 0
	sta minutes
;hours = 0
	sta hours
	rts

updateObjects:
	lda #$00
	sta objectToUpdate
	jsr getInputs
	jsr updateSpriteTiles
	jsr updateX
	jsr updateY
	rts

getInputs:
	lda inputsH
	pha
	lda inputsL
	pha
;this is jumpint to the function
	rts

updateSpriteTiles:
;y is ram object
	ldy objectToUpdate
	lda currentMetaSprite,y
	cmp previousMetaSprite,y
;if theyre the same dont update
	bne @update
	rts
;current meta sprite is y
@update:
;a is current metasprite offset
;previous = current (because update)
	sta previousMetaSprite,y
;x is metasprite offset in rom
	tax
	lda oamOffset,y
;y is sprite number in oam
	tay
	iny;skip x coord
	lda spriteTile0,x
	sta oam,y
	iny
	lda spriteAttribute0,x
	sta oam,y
	iny
	iny;skip y coord
	iny;skip x coord
	lda spriteTile1,x
	sta oam,y
	iny
	lda spriteAttribute1,x
	sta oam,y
	iny
	iny;skip y coord
	iny;skip x coord
	lda spriteTile2,x
	sta oam,y
	iny
	lda spriteAttribute2,x
	sta oam,y
	iny
	iny;skip y coord
	iny;skip x coord
	lda spriteTile3,x
	sta oam,y
	iny
	lda spriteAttribute3,x
	sta oam,y
	iny
	iny;skip y coord
	iny;skip x coord
	lda spriteTile4,x
	sta oam,y
	iny
	lda spriteAttribute4,x
	sta oam,y
	iny
	iny;skip y coord
	iny;skip x coord
	lda spriteTile5,x
	sta oam,y
	iny
	lda spriteAttribute5,x
	sta oam,y
	iny
	iny;skip y coord
	iny;skip x coord
	lda spriteTile6,x
	sta oam,y
	iny
	lda spriteAttribute6,x
	sta oam,y
	iny
	iny;skip y coord
	iny;skip x coord
	lda spriteTile7,x
	sta oam,y
	iny
	lda spriteAttribute7,x
	sta oam,y
	iny
	iny;skip y coord
	iny;skip x coord
	lda spriteTile8,x
	sta oam,y
	iny
	lda spriteAttribute8,x
	sta oam,y
	iny
	iny;skip y coord
	iny;skip x coord
	lda spriteTile9,x
	sta oam,y
	iny
	lda spriteAttribute9,x
	sta oam,y
	iny
	iny;skip y coord
	iny;skip x coord
	lda spriteTile10,x
	sta oam,y
	iny
	lda spriteAttribute10,x
	sta oam,y
	iny
	iny;skip y coord
	iny;skip x coord
	lda spriteTile11,x
	sta oam,y
	iny
	lda spriteAttribute11,x
	sta oam,y

	rts

updateX:
;updateXObject - object passed into function
;compare previous with current, update if different
;since we stitch sprites together, each need a value depending on the offset from the upper left corner
;x is object to update
	ldx objectToUpdate
	lda spriteX,x
	cmp previousX,x
	bne @updateX
	rts
@updateX:
;x is object in ram
;previous = spritex because update
	sta previousX,x
	lda metaSpriteWidth,x
;y is tile width
	tay
	lda spriteX,x
	sta xValue0
	dey
	beq @saveXValues;1 sprite wide
	clc ;get ready to add
	adc #8
	sta xValue1
	dey
	beq @saveXValues;2 sprites wide
	adc #8
	sta xValue2
	dey
	beq @saveXValues;3 sprites wide
	adc #8
	sta xValue3
	dey
	beq @saveXValues;4 sprites wide
	adc #8
	sta xValue4;5 sprites wide
@saveXValues:
;x is still object to update
	lda metaSpriteHeight,x
	tax
@saveToStack:
;save it, from  back to front
;( ; x>0; ;
	dex
	bmi @storeXValues
	ldy objectToUpdate
	lda metaSpriteWidth,y
;y is now width
	tay
	dey
	lda spriteTileXValues,y
	pha
	dey
	bmi @saveToStack;1 tile wide
	lda spriteTileXValues,y
	pha
	dey
	bmi @saveToStack;2 tiles wide
	lda spriteTileXValues,y
	pha
	dey
	bmi @saveToStack;2 tiles wide
	lda spriteTileXValues,y
	pha
	dey
	bmi @saveToStack;2 tiles wide
	lda spriteTileXValues,y
	pha
	dey
	bmi @saveToStack;2 tiles wide
	lda spriteTileXValues,y
	pha
	jmp @saveToStack;5 tiles wide
	
@storeXValues:
	ldx objectToUpdate
	lda oamOffset,x
;y is oamOffset
	tay
	lda spriteTileTotal,x
;x is total sprties to update
	tax
@storeLoop:
	iny;skip y
	iny;skip tile
	iny;skip attribute
	pla
	sta oam,y
	iny
	dex
	bne @storeLoop
	rts

updateY:
;updateXObject - object passed into function
;compare previous with current, update if different
;since we stitch sprites together, each need a value depending on the offset from the upper left corner
;x is object to update
	ldx objectToUpdate
	lda spriteY,x
	cmp previousY,x
	bne @updateY
	rts
@updateY:
;x is object in ram
;previous = spritex because update
	sta previousY,x
	lda metaSpriteHeight,x
;y is tile height
	tay
	lda spriteY,x
	sta yValue0
	dey
	beq @saveYValues;1 sprite high
	clc ;get ready to add
	adc #8
	sta yValue1
	dey
	beq @saveYValues;2 sprites high
	adc #8
	sta yValue2
	dey
	beq @saveYValues;3 sprites high
	adc #8
	sta yValue3
	dey
	beq @saveYValues;4 sprites high
	adc #8
	sta yValue4
	dey
	beq @saveYValues;5 sprites high
	adc #8
	sta yValue5;6 sprites high
@saveYValues:
;x is still object to update
;x is now height
	lda metaSpriteHeight,x
	tay
@saveToStack:
;save it, from  back to front
	dey
	bmi @storeYValues
	ldx objectToUpdate
	lda metaSpriteWidth,x
;x is width
	tax
	lda spriteTileYValues,y
	pha
	dex
	beq @saveToStack;1 sprite wide
	lda spriteTileYValues,y
	pha
	dex
	beq @saveToStack;2 sprites wide
	lda spriteTileYValues,y
	pha
	dex
	beq @saveToStack;3 sprites wide
	lda spriteTileYValues,y
	pha
	dex
	beq @saveToStack;4 sprites wide
	lda spriteTileYValues,y
	pha;5 sprites wide
	jmp @saveToStack
	
@storeYValues:
	ldx objectToUpdate
	lda oamOffset,x
;y is oamOffset
	tay
	lda spriteTileTotal,x
;x is total sprties to update
	tax
@storeLoop:
	pla
	sta oam,y
	iny
	iny;skip tile
	iny;skip attribute
	iny;skip x
	dex
	bne @storeLoop
	rts
;;;;;;
;test;
;;;;;;

test:
	sta testVariable
	rts
testLoop:
	inc testLoopVariable
	rts
;;;;;;;;;
;;;NMI;;;
;;;;;;;;;
;vblank;
;;;;;;;;
nmi:
	;save registers
	pha
	txa
	pha
	tya
	pha
	;oamdma transfer
	;initialize oam
	lda #$00
	sta OAMADDR;reset OAM 
	;begin transfer
	lda #OAM_LOCATION
	sta OAMDMA
	;vblank starts here
	lda #true
	sta isInBlank 
	;vblank code goes here
	;always jmp to updateScroll
	;when ending a subroutine
updateScroll:
	bit PPUSTATUS
	lda currentPPUSettings
	sta PPUCTRL
	lda #$00
	sta PPUSCROLL
	sta PPUSCROLL

;update clock
	inc seconds
	bne @endClock
	inc minutes
	bne @endClock
	inc hours
@endClock:
;hasFrameBeenRendered = TRUE
	lda #true
	sta hasFrameBeenRendered

	pla
	tay
	pla;restore registers
	tax
	pla
	
	rti

.include "data.s"
.segment "VECTORS"
.word nmi
.word reset

.segment "CHARS"
.incbin "graphics.chr"
