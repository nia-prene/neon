.include "constants.s"
.segment "HEADER"
.include "header.s"
.include "ram.s"
.segment "STARTUP"
.include "init.s"
.segment "CODE"
;housekeeping
;structured data
;struct Clock {
	;unsigned seconds = 0
	;unsigned minutes = 0
	;unsigned hours = 0
	;unsigned days = 0
	;void resetClock()
	;void updateClock()
;}
;struct Palette {
	;unsigned color1
	;unsigned color2
	;unsigned color3
;}
;struct Screen {
	;Palettes palettes[8]
	;unsigned tile256
	;unsigned tiles128[4]
	;unsigned tiles64[16]
	;unsigned tiles32[64]
	;void setPalette(x, y)
	;void setPaletteCollection(x)
	;void unzipAllTiles(a)
	;void unzip64Column(a)
	;void unzip32Column(a)
	;flags disableRendering(a)
	;flags enableRendering(a)
	;void render32(a)
	;void renderAllTiles()
	;void renderAllPalettes()
;}
;struct Sprite {
	;spriteID
	;oamOffset
	;inputs
	;behaviorsH
	;behaviorsL
	;nextMetasprite
	;currentMetasprite
	;initializeSpriteObject(a, x, y)
	;void clearOam(x, y)
;}
;struct scene {
	;bool hasFrameBeenRendered
	;unsigned nextScene = 0
	;unsigned currentScene = NULL
	;constant BACKGROUND_COLOR
	;Screen screen
	;Sprite sprites[8]
	;Clock clock
	;void beginOamDma()
;} 
main:
;Scene scene {0; null; ; ; }
	lda #00
	sta nextScene
	lda #NULL
	sta currentScene
	jsr resetClock;()
;scene.clock.resetClock
;get the player object
	lda #CAT_OBJECT
	tay
	lda #0;target in ram
	tax
;start on oam offset 4/sprite 1
;sprite 0 is for effects
	lda #04
;initializeSpriteObject(a x y)
;a - oamOffset
;x - target in ram
;y is target in rom
	jsr initializeSpriteObject
;returns 
;a - next available oam offset
;x is palette of player sprite
;y is palette to update
	ldx #0
	ldy #4
;scene.screen.palettes[4]= romPalettes[0]
	jsr setPalette;(x, y)
gameLoop:
;if the scenes are different
	lda nextScene
	cmp currentScene
	beq @dontUpdateScene
	;update the scene
		lda seconds
		ldx currentMaskSettings
		jsr disableRendering;(a, x)
	;returns new mask settings
	;scene.currentMaskSettings = scene.disableRendering(a,x)
		sta currentMaskSettings
	;clear ram after player
		ldx #01;ram object
		ldy #25;oam offset
	;sprites.clearOam
		jsr clearOam;(x, y)
		lda nextScene
	;tile.unzipAllTiles(nextScene)
		jsr unzipAllTiles;(a)
	;scene.screen.palettes.unzipPalettes(nextScene)
		ldx nextScene
		jsr setPaletteCollection;(x)
	;we are in forced blank so we can call these two rendering routines
		jsr renderAllTiles
		jsr renderAllPalettes

		lda seconds
		ldx currentMaskSettings
		jsr enableRendering;(a, x)
	;returns new mask settings
	;scene.currentMaskSettings = scene.enableRendering(a,x)
		sta currentMaskSettings
	;set current to next
	;scene.currentScene = scene.nextScene
		lda nextScene
		sta currentScene
@dontUpdateScene:
;while frame hasnt been rendered
	lda hasFrameBeenRendered
	beq gameLoop
	ldx #$00
	stx objectToUpdate
;get the player's input
	lda #00
	tay
	lda controllers,y
	sta inputs,x 
;for(
;objectToUpdate = 0
;objectToUpdate < 1
;objectToUpdate ++
;)
	jsr interpretBehavior
	jsr checkXCollision
	jsr updateX
	jsr updateY
	jsr updateSpriteTiles
;scene.hasFrameBeenRendered = FALSE
	lda #FALSE
	sta hasFrameBeenRendered
	jmp gameLoop

;;;;;;;;;;;;;;;;
;;;Interrupts;;;
;;;;;;;;;;;;;;;;
;vblank;
;;;;;;;;
nmi:
;save registers
	pha
	txa
	pha
	tya
	pha
;scene.clock.updateClock()
	jsr updateClock;()
;rendering code goes here
;oamdma transfer
;reset with bit 0 write
beginOamDma:
	lda #$00
	sta OAMADDR
;begin transfer by writing high byte of address of page oam is on (03)
	lda #OAM_LOCATION
	sta OAMDMA
;read controllers right after oamdma
	jsr readControllers
updateScroll:
	bit PPUSTATUS
	lda currentPPUSettings
	sta PPUCTRL
	lda #$00
	sta PPUSCROLL
	sta PPUSCROLL
;hasFrameBeenRendered = TRUE
	lda #TRUE
	sta hasFrameBeenRendered
;restore registers
	pla
	tay
	pla
	tax
	pla
;return	
	rti

;;;;;;;;;;;;;;;
;;;Functions;;;
;;;;;;;;;;;;;;;;;;;;
;;Member Functions;;
;;;;;;;;;;;;;;;;;;;;
;Clock;
;;;;;;;
resetClock:;()
;stores 0 values to clock
;returns void
	lda #00
	sta seconds
	sta minutes
	sta hours
	sta days
	rts
updateClock:
;increases second hand and others if overflow 
	inc seconds
	beq @updateMinutes
	rts
@updateMinutes:
	inc minutes
	beq @updateHours
	rts
@updateHours:
	inc hours
	beq @updateDays
	rts
@updateDays:
	inc days
	rts
;;;;;;;;;
;sprites;
;;;;;;;;;
initializeSpriteObject:
;Constructor
;arguments
;a - oamOffset
;x - target in ram
;y is rom object (ID)
;variables
;nextFreeOamOffset - oam offset immediately after this object
;return 
;a - nextFreeOamOffset
	sta oamOffset,x
;save this to calculate next free space
	sta nextFreeOamOffset
;set previous metasprite to null
	tya
	sta objectID,x
	lda #NULL
	sta currentMetaSprite,x
;null out previous x and y
	sta previousX,x
	sta previousY,x
;set the initial metaSprite
	lda spriteState0,y
	sta nextMetaSprite,x
;get the width
	lda spriteWidth,y
	sta metaSpriteWidth,x
;get the height
	lda spriteHeight,y
	sta metaSpriteHeight,x
;get hitbox
	lda hitboxX1,y
	sta metaSpriteHitboxX1,x
	lda hitboxX2,y
	sta metaSpriteHitboxX2,x
	lda hitboxY1,y
	sta metaSpriteHitboxY1,x
	lda hitboxY2,y
	sta metaSpriteHitboxY2,x
;put it at this coordinate for now	
	lda #$55
	sta spriteX,x
	lda #$9e
	sta spriteY,x

	lda behavior,y
	tay
	lda behaviorsH,y
	sta spriteBehaviorsH,y
	lda behaviorsL,y
	sta spriteBehaviorsL,y
;get sprite total
	lda spriteTotal,y
	sta metaSpriteTileTotal,x
;quadrupel it and clear carry
	asl
	asl
	adc nextFreeOamOffset
;return nextFreeOamOffset
	rts

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
	lda paletteCollection,x
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

unzipAllTiles:;(a)
;unzips all the tile for a scene
;arguments
;a next scene
;get the big tile	
	tax
	lda screenTile,x
;start at tiles128[0]
	ldy #$00
	tax;screenTile index is in x
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

disableRendering:;(a, x)
;holds cpu in loop until next nmi, then disables rendering via PPUMASK
;arguments
;a - seconds
;seconds from clock
;x - currentMaskSettings
;settings for ppu mask
;returns new ppu mask settings
@waitForBlank:
	cmp seconds
	beq @waitForBlank
	and #DISABLE_RENDERING
	sta PPUMASK
	rts

enableRendering:;(a, x)
;holds cpu in loop until next nmi, then disables rendering via PPUMASK
;arguments
;a - seconds
;seconds from clock
;x - currentMaskSettings
;settings for ppu mask
;returns new ppu mask settings
@waitForBlank:
	cmp seconds
	beq @waitForBlank
;a is now current mask settings
	txa
	ora #ENABLE_RENDERING
	sta PPUMASK
	rts

clearOam:;(y)
;arguments
;y - oam offset to begin with
;returns void
;set sprite number to $ff
	lda #NULL
;for( ; y < 256 ; y++)
@setOamToNull:
;oam[y]=NULL
	sta oam,y
	iny
	bne @setOamToNull
	rts



;this subroutine transfers all palettes to the ppu
renderAllPalettes:
	;clear vblank flag before write
	bit PPUSTATUS
	lda currentPPUSettings
	and #INCREMENT_1
	sta PPUCTRL
;palettes are at 3f00 of ppu, accessed through PPUADDR
	lda #$3f
	sta PPUADDR
	lda #$00
	sta PPUADDR
	tax
@storePalettes:
;store in PPUDATA
	lda #BACKGROUND_COLOR
	sta PPUDATA
	lda color1,x
	sta PPUDATA
	lda color2,x
	sta PPUDATA
	lda color3,x
	sta PPUDATA
	inx
	cpx #$08;8 palettes
	bne @storePalettes
	rts

render32:;(a)
;this renders a 32x32 tile from the tiles32 array.
;arguments
;a - tile in tiles32 array to render
;returns void;
;a is tile position in tiles32
	tax;x is tile number in array
	tay;y is nametable reference pos
	;all tiles ending in 111 are shorter
	pha
	and #%00000111
	cmp #%00000111
	bne @standardTile
@shorterTile:
	;save the 2 tiles
	lda tiles32,x
	tax;x is now the 32x32 tile
	lda topLeft32,x
	sta tile16a
	lda topRight32,x
	sta tile16c
	;look up nametable conversion, save them and put them in ppu
	lda nameTableConversionH,y
	sta currentNameTable
	sta PPUADDR
	lda nameTableConversionL,y
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
	lda nameTableConversionH,y
	sta currentNameTable
	sta PPUADDR
	lda nameTableConversionL,y
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
;get the tile
	pla
	tay;y is tile pos in tiles32 array
	tax;x is position in conversion
	lda attributeTableConversionH,x
	;store address (big endian)
	sta PPUADDR
	lda attributeTableConversionL,x
	sta PPUADDR
	lda tiles32,y
	tay;y is tile itself
	lda tileAttributeByte,y
	sta PPUDATA
	rts

renderAllTiles:
	;clear vblank bit before write
	bit PPUSTATUS
	lda currentPPUSettings
	ora #INCREMENT_32
	sta PPUCTRL
	ldx #$00
@renderScreenLoop:
	txa
	pha
	jsr render32
	pla
	tax
	inx
	cpx #64
	bcc	@renderScreenLoop
	rts


interpretBehavior:
	ldx objectToUpdate
	lda spriteBehaviorsH,x
	pha
	lda spriteBehaviorsL,x
	pha
	rts

updateSpriteTiles:
;x is ram object
	ldx objectToUpdate
	lda nextMetaSprite,x
	cmp currentMetaSprite,x
;if theyre the same dont update
	bne @updateTiles
	rts
@updateTiles:
;x is object in ram
	lda oamOffset,x
;y is oam offset
	tay
;y points to tile byte
	iny
	lda metaSpriteTileTotal,x
;save the number of tiles
	sta totalTileCounter
	lda metaSpritePalette,x
;save the palette byte
	sta tilePaletteAttribute
	lda nextMetaSprite,x
;x is the metasprite in ROM
	tax
;y is offset in oam
;transfer to oam
	lda spriteTile0,x
	sta oam,y
	iny
	lda spriteAttribute0
	ora tilePaletteAttribute
	sta oam,y
	dec totalTileCounter
	bne @moreThanOne
	rts
@moreThanOne:
;second tile
	iny
	iny
	iny
	lda spriteTile1,x
	sta oam,y
	iny
	lda spriteAttribute1
	ora tilePaletteAttribute
	sta oam,y
	dec totalTileCounter
;third tile
	iny
	iny
	iny
	lda spriteTile2,x
	sta oam,y
	iny
	lda spriteAttribute2
	ora tilePaletteAttribute
	sta oam,y
	dec totalTileCounter
;fourth tile
	iny
	iny
	iny
	lda spriteTile3,x
	sta oam,y
	iny
	lda spriteAttribute3
	ora tilePaletteAttribute
	sta oam,y
	dec totalTileCounter
	bne @moreThan4
	rts
@moreThan4:
;fifth tile
	iny
	iny
	iny
	lda spriteTile4,x
	sta oam,y
	iny
	lda spriteAttribute4
	ora tilePaletteAttribute
	sta oam,y
	dec totalTileCounter
;sixth tile
	iny
	iny
	iny
	lda spriteTile5,x
	sta oam,y
	iny
	lda spriteAttribute5
	ora tilePaletteAttribute
	sta oam,y
	dec totalTileCounter
	bne @moreThan6
	rts
@moreThan6:
;seventh tile
	iny
	iny
	iny
	lda spriteTile6,x
	sta oam,y
	iny
	lda spriteAttribute6
	ora tilePaletteAttribute
	sta oam,y
	dec totalTileCounter
;eighth tile
	iny
	iny
	iny
	lda spriteTile7,x
	sta oam,y
	iny
	lda spriteAttribute7
	ora tilePaletteAttribute
	sta oam,y
	dec totalTileCounter
;ninth tile
	iny
	iny
	iny
	lda spriteTile8,x
	sta oam,y
	iny
	lda spriteAttribute8
	ora tilePaletteAttribute
	sta oam,y
	dec totalTileCounter
	bne @moreThan9
	rts
@moreThan9:
;tenth tile
	iny
	iny
	iny
	lda spriteTile9,x
	sta oam,y
	iny
	lda spriteAttribute9
	ora tilePaletteAttribute
	sta oam,y
	dec totalTileCounter
;eleventh tile
	iny
	iny
	iny
	lda spriteTile10,x
	sta oam,y
	iny
	lda spriteAttribute10,x
	ora tilePaletteAttribute
	sta oam,y
	dec totalTileCounter
;twelth tile
	iny
	iny
	iny
	lda spriteTile11,x
	sta oam,y
	iny
	lda spriteAttribute11,x
	ora tilePaletteAttribute
	sta oam,y
	dec totalTileCounter
	bne @moreThan12
	rts
@moreThan12:
;thirteenth tile
	iny
	iny
	iny
	lda spriteTile12,x
	sta oam,y
	iny
	lda spriteAttribute12,x
	ora tilePaletteAttribute
	sta oam,y
	dec totalTileCounter
;fourteenth tile
	iny
	iny
	iny
	lda spriteTile13,x
	sta oam,y
	iny
	lda spriteAttribute13,x
	ora tilePaletteAttribute
	sta oam,y
	dec totalTileCounter
;fifteenth tile
	iny
	iny
	iny
	lda spriteTile14,x
	sta oam,y
	iny
	lda spriteAttribute14,x
	ora tilePaletteAttribute
	sta oam,y
	dec totalTileCounter
	bne @moreThan15
	rts
@moreThan15:
;sixteenth tile
	iny
	iny
	iny
	lda spriteTile15,x
	sta oam,y
	iny
	lda spriteAttribute15,x
	ora tilePaletteAttribute
	sta oam,y
	dec totalTileCounter
	bne @moreThan16
	rts
@moreThan16:
;seventeenth tile
	iny
	iny
	iny
	lda spriteTile16,x
	sta oam,y
	iny
	lda spriteAttribute16,x
	ora tilePaletteAttribute
	sta oam,y
	dec totalTileCounter
;eighteenth tile
	iny
	iny
	iny
	lda spriteTile17,x
	sta oam,y
	iny
	lda spriteAttribute17,x
	ora tilePaletteAttribute
	sta oam,y
	dec totalTileCounter
;nineteenth tile
	iny
	iny
	iny
	lda spriteTile18,x
	sta oam,y
	iny
	lda spriteAttribute18,x
	ora tilePaletteAttribute
	sta oam,y
	dec totalTileCounter
;twentyeth tile
	iny
	iny
	iny
	lda spriteTile19,x
	sta oam,y
	iny
	lda spriteAttribute19,x
	ora tilePaletteAttribute
	sta oam,y
	dec totalTileCounter
	bne @moreThan20
	rts
@moreThan20:
;twentyfirst tile
	iny
	iny
	iny
	lda spriteTile20,x
	sta oam,y
	iny
	lda spriteAttribute20,x
	ora tilePaletteAttribute
	sta oam,y
	dec totalTileCounter
;twenty second tile
	iny
	iny
	iny
	lda spriteTile21,x
	sta oam,y
	iny
	lda spriteAttribute21,x
	ora tilePaletteAttribute
	sta oam,y
	dec totalTileCounter
;twenty third tile
	iny
	iny
	iny
	lda spriteTile22,x
	sta oam,y
	iny
	lda spriteAttribute22,x
	ora tilePaletteAttribute
	sta oam,y
	dec totalTileCounter
;twenty fourth tile
	iny
	iny
	iny
	lda spriteTile23,x
	sta oam,y
	iny
	lda spriteAttribute23,x
	ora tilePaletteAttribute
	sta oam,y
	dec totalTileCounter
;twenty fifth tile
	iny
	iny
	iny
	lda spriteTile24,x
	sta oam,y
	iny
	lda spriteAttribute24,x
	ora tilePaletteAttribute
	sta oam,y
	dec totalTileCounter
	rts
checkXCollision:
	ldx objectToUpdate
	lda spriteX,x
	cmp previousX,x
	beq @dontUpdate
	bpl @movingRight
@dontUpdate:
	rts
@movingRight:
	jmp checkCollisionMovingRight

checkCollisionMovingRight:
;a is y coordinate, x is ram object
	ldx objectToUpdate
	lda spriteY,x
;find the top right corner
	clc
	adc metaSpriteHitboxY1,x
	bcc @notOffScreenY
;don't allow wrap around
	lda #$ff
@notOffScreenY:
;save the coordinate 
	sta collisionYCoordinate
;x is still object in ram
	lda spriteX,x
	clc
	adc metaSpriteHitboxX2,x
	bcc @notOffScreenX
;don't allow wrap around
	lda #$ff
@notOffScreenX:
	sta collisionXCoordinate
	jsr getTileCollisionData
;save the collision data
	lda tileCollisionData
	rts

getTileCollisionData:
;argument
;corner coordinates to check 
;collisionYCoordinate 
;collisionXCoordinate
;returns tileCollisionData
;| t d u u u u u u |
;tile
;death
;unused
;variables 
;metaTileToCheckCollision
;| x x x y y y yc xc |
;x - 3 msb of x value
;y - 3 msb of y value
;yc xc -
;which tile in the 32x32 metatile
;determined by the 4th msb of the coordinate
;00 top left
;01 bottom right
;10 top right 
;11 bottom right
;see tiles in data.s
	lda collisionYCoordinate
;save the msb of y coordinate
	and #%11110000
	lsr
	lsr
	lsr
;store | * * * y y y yc * |
	sta metaTileToCheckCollision
	lda collisionXCoordinate
;save x coordinate
	pha
;store the msb of x coordinate
	and #%11100000
	ora metaTileToCheckCollision
;store | x x x * * * * * |
	sta metaTileToCheckCollision
;a is now x coordinate
	pla
	and #%00010000
	lsr
	lsr
	lsr
	lsr
	ora metaTileToCheckCollision
;store | * * * * * * * xc |
	sta metaTileToCheckCollision
;a contains | x x x y y y yc xc |
	lsr
	bcs @xSet
	lsr
	bcs @ySet
@neitherSet:
;x is now position in tile array
	tax
	lda tiles32,x
	tay
;y is now tile to check
	lda collisionTopLeft,y
	sta tileCollisionData
	rts
@xSet:
	lsr
	bcs @bothSet
;x is now position in tile array
	tax
	lda tiles32,x
	tay
;y is now tile to check
	lda collisionTopRight,y
	sta tileCollisionData
	rts
@ySet:
;x is now position in tile array
	tax
	lda tiles32,x
	tay
;y is now tile to check
	lda collisionBottomLeft,y
	sta tileCollisionData
	rts
@bothSet:
;x is now position in tile array
	tax
	lda tiles32,x
	tay
;y is now tile to check
	lda collisionBottomRight,y
	sta tileCollisionData
	rts

updateX:
; x is sprite object in ram
	ldx objectToUpdate
	lda spriteX,x
	cmp previousX,x
	bne @updateX
;if they are equal, don't update
	rts
@updateX:
;current is now previous
	sta previousX,x
	sta xVal0
	clc
	adc #08
	bcs @overflow1
	sta xVal1
	adc #08
	bcs @overflow2
	sta xVal2
	adc #08
	bcs @overflow3
	sta xVal3
	adc #08
	bcs @overflow4
	sta xVal4
	jmp @storeInOam
@overflow1:
	lda #$ff
	sta xVal1
	sta xVal2
	sta xVal3
	sta xVal4
	jmp @storeInOam
@overflow2:
	lda #$ff
	sta xVal2
	sta xVal3
	sta xVal4
	jmp @storeInOam
@overflow3:
	lda #$ff
	sta xVal3
	sta xVal4
	jmp @storeInOam
@overflow4:
	lda #$ff
	sta xVal4
@storeInOam:
;x is object in ram
	lda oamOffset,x
;y is offset in oam
	tay
	iny
	iny
;y points to first y coordinate
	iny
	lda metaSpriteHeight,x
	sta xUpdateHeightCounter
	lda metaSpriteWidth,x
;save the width
	pha
;loop
@storeRow:
;pull and push width
	pla
	pha
;x is width
	tax
	dec xUpdateHeightCounter
	bmi @end
	lda xVal0
	sta oam,y
	iny
	iny
	iny
	iny
	dex
	beq @storeRow
	lda xVal1
	sta oam,y
	iny
	iny
	iny
	iny
	dex
	beq @storeRow
	lda xVal2
	sta oam,y
	iny
	iny
	iny
	iny
	dex
	beq @storeRow
	lda xVal3
	sta oam,y
	iny
	iny
	iny
	iny
	dex
	beq @storeRow
	lda xVal4
	sta oam,y
	iny
	iny
	iny
	iny
	jmp@storeRow
@end:
;pull height off the stack
	pla
	rts
updateY:
; x is sprite object in ram
	ldx objectToUpdate
	lda spriteY,x
	cmp previousY,x
	bne @updateY
;if they are equal, don't update
	rts
@updateY:
;current is now previous
	sta previousY,x
	sta yVal0
	clc
	adc #08
	bcs @overflow1
	sta yVal1
	adc #08
	bcs @overflow2
	sta yVal2
	adc #08
	bcs @overflow3
	sta yVal3
	adc #08
	bcs @overflow4
	sta yVal4
	jmp @storeInOam
@overflow1:
	lda #$ff
	sta yVal1
	sta yVal2
	sta yVal3
	sta yVal4
	jmp @storeInOam
@overflow2:
	lda #$ff
	sta yVal2
	sta yVal3
	sta yVal4
	jmp @storeInOam
@overflow3:
	lda #$ff
	sta yVal3
	sta yVal4
	jmp @storeInOam
@overflow4:
	lda #$ff
	sta yVal4
@storeInOam:
;x is object in ram
	lda oamOffset,x
;y is offset in oam
;y points to first y coordinate
	tay
	lda metaSpriteHeight,x
	sta yUpdateHeightCounter
	lda metaSpriteWidth,x
;save the width
	pha
;x is width
	tax
;loop
	lda yVal0
	sta oam,y
	iny
	iny
	iny
	iny
	dex
	beq @secondRow
	sta oam,y
	iny
	iny
	iny
	iny
	dex
	beq @secondRow
	sta oam,y
	iny
	iny
	iny
	iny
	dex
	beq @secondRow
	sta oam,y
	iny
	iny
	iny
	iny
	dex
	beq @secondRow
	sta oam,y
	iny
	iny
	iny
	iny
@secondRow:
	dec yUpdateHeightCounter
	bne @doSecondRow
;pull width off stack
	pla
	rts
@doSecondRow:
;get width
	pla
	pha
;x is width
	tax
	lda yVal1
	sta oam,y
	iny
	iny
	iny
	iny
	dex
	beq @thirdRow
	sta oam,y
	iny
	iny
	iny
	iny
	dex
	beq @thirdRow
	sta oam,y
	iny
	iny
	iny
	iny
	dex
	beq @thirdRow
	sta oam,y
	iny
	iny
	iny
	iny
	dex
	beq @thirdRow
	sta oam,y
	iny
	iny
	iny
	iny
@thirdRow:
	dec yUpdateHeightCounter
	bne @doThirdRow
;pull width off stack
	pla
	rts
@doThirdRow:
;get width
	pla
	pha
;x is width
	tax
	lda yVal2
	sta oam,y
	iny
	iny
	iny
	iny
	dex
	beq @fourthRow
	sta oam,y
	iny
	iny
	iny
	iny
	dex
	beq @fourthRow
	sta oam,y
	iny
	iny
	iny
	iny
	dex
	beq @fourthRow
	sta oam,y
	iny
	iny
	iny
	iny
	dex
	beq @fourthRow
	sta oam,y
	iny
	iny
	iny
	iny
@fourthRow:
	dec yUpdateHeightCounter
	bne @doFourthRow
;pull width off stack
	pla
	rts
@doFourthRow:
;get width
	pla
	pha
;x is width
	tax
	lda yVal3
	sta oam,y
	iny
	iny
	iny
	iny
	dex
	beq @fifthRow
	sta oam,y
	iny
	iny
	iny
	iny
	dex
	beq @fifthRow
	sta oam,y
	iny
	iny
	iny
	iny
	dex
	beq @fifthRow
	sta oam,y
	iny
	iny
	iny
	iny
	dex
	beq @fifthRow
	sta oam,y
	iny
	iny
	iny
	iny
@fifthRow:
	dec yUpdateHeightCounter
	bne @doFifthRow
;pull width off stack
	pla
	rts
@doFifthRow:
	pla
	pha
;x is width
	tax
	lda yVal4
	sta oam,y
	iny
	iny
	iny
	iny
	dex
	beq @end
	sta oam,y
	iny
	iny
	iny
	iny
	dex
	beq @end
	sta oam,y
	iny
	iny
	iny
	iny
	dex
	beq @end
	sta oam,y
	iny
	iny
	iny
	iny
	dex
	beq @end
	sta oam,y
	iny
	iny
	iny
	iny
@end:
;remove width
	pla
	rts

readControllers:
	lda #$01
    sta JOY1
	sta controller2; player 2's buttons double as a ring counter
    lsr          ; now A is 0
    sta JOY1
loop:
    lda JOY1
    and #%00000011  ; ignore bits other than controller
    cmp #$01        ; Set carry if and only if nonzero
	rol controller1; Carry -> bit 0; bit 7 -> Carry
    lda JOY2     ; Repeat
    and #%00000011
    cmp #$01
	rol controller2; Carry -> bit 0; bit 7 -> Carry
    bcc loop
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

.include "data.s"
.segment "VECTORS"
.word nmi
.word reset

.segment "CHARS"
.incbin "graphics.chr"
