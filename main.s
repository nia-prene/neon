.include "constants.s"
.segment "HEADER"
.include "header.s"
.include "ram.s"
.segment "STARTUP"
.include "init.s"
.segment "CODE"
;after the init code, we jump here
main:
;housekeeping
;first scene is scene 0
	lda #00
	sta nextScene
	lda #NULL
;currently no scene is loaded
	sta currentScene
;clear this out while we have null
	sta spriteRoutineOffset
;there is no frame that needs renderas we haven't begun gameloop
	lda #TRUE
	sta hasFrameBeenRendered
;reset the clock to 0
	jsr resetClock;()
;get the player object
	ldx #PLAYER_PALETTE
;set the players palette to #4 and the coin palette to #5
	ldy #4
	jsr setPalette;(x, y)
	ldx #COIN_PALETTE
	ldy #5
	jsr setPalette;(x,y)
;set sprite speed
	lda #$03
	sta spriteSpeedH
	lda #$00
	sta spriteSpeedL
gameLoop:
;while(!hasFrameBeenRendered)
	;hold here until previous frame was rendered
	lda hasFrameBeenRendered
	beq gameLoop
;if(nextScene != currentScene) 
	lda nextScene
	cmp currentScene
	beq @addSprites
	;update the scene
		lda seconds
		ldx currentMaskSettings
		jsr disableRendering;(a, x)
	;returns new mask settings
		sta currentMaskSettings
		jsr resetSprites
		lda nextScene
		jsr unzipAllTiles;(a)
		ldx nextScene
		jsr setPaletteCollection;(x)
	;we are in forced blank so we can call these two rendering routines
		jsr renderAllTiles
		jsr renderAllPalettes
		jsr getAvailableSprite
		ldy #PLAYER_OBJECT
	;player starts in middle rail
		lda #%00001000
	;(x-target in ram, y-target in rom, a-rail to place it on)
		jsr initializeSprite
		lda seconds
		ldx currentMaskSettings
		jsr enableRendering;(a, x)
	;returns new mask settings
		sta currentMaskSettings
	;set current to next
		lda nextScene
		sta currentScene
@addSprites:
	lda seconds
	and #%01111111
	lsr
	lsr
	lsr
	cmp spriteRoutineOffset
	beq @updateObjects
	sta spriteRoutineOffset
;x is the offset for the sprite to fetch
	jsr getAvailableSprite
	cpx #$ff
	beq @updateObjects
	ldy spriteRoutineOffset
	lda leftRail,y
	tay
	lda #%01000000
	jsr initializeSprite;(a,x,y)
	jsr getAvailableSprite
	cpx #$ff
	beq @updateObjects
	ldy spriteRoutineOffset
	lda leftRail,y
	tay
	lda #%00001000
	jsr initializeSprite;(a,x,y)
	jsr getAvailableSprite
	cpx #$ff
	beq @updateObjects
	ldy spriteRoutineOffset
	lda leftRail,y
	tay
	lda #%00000001
	jsr initializeSprite;(a,x,y)
@updateObjects:
;start by updating object 0 (player)
	ldx #$00
;for(objectToUpdate=0;objectToUpdate<MAX_OBJECTS;objectToUpdate++)
@updateLoop:
	stx objectToUpdate
	lda isActive,x
	beq @next
	jsr interpretBehavior;(x-object to update)
	lda currentRail,x
	cmp targetRail,x
	beq @dontUpdateRail
	tay
	lda targetRail,x
	jsr getNewRail;(a-targetRail, y-currentRail)
;returns a - new current rail
	ldx objectToUpdate
	sta currentRail,x
@dontUpdateRail:
	jsr getX;(a-currentRail)
	ldx objectToUpdate
	sta spriteX,x
@next:
	inx
	cpx #MAX_OBJECTS
	bcc @updateLoop

	lda #$00
	tax
	jsr buildOAM;(x-object to build, a-oam offset)
	lda #FALSE
	sta hasFrameBeenRendered
	jmp gameLoop

;;;;;;;;;;;;;;;;
;;;Interrupts;;;
;;;;;;;;;;;;;;;
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

getAvailableSprite:
;returns
;x- ram position of next available sprite
	ldx #$00
;if isActive = FALSE break
@findInactive:
	lda isActive,x
	beq @returnValue
	inx
	cpx #MAX_OBJECTS
	bcc @findInactive
;if no sprite is available, return null
	ldx #NULL
	rts
@returnValue:
;return offset of first sprite where isActive=False
	rts

initializeSprite:
;Constructor
;arguments
;a - rail
;x - target in ram array
;y - is rom object (see sprites in data.s)
;returns void
;store the rail
	sta currentRail,x
	sta targetRail,x
;copy tile total
	lda romSpriteTotal,y
	sta spriteTotal,x
;copy the width
	lda romSpriteWidth,y
	sta spriteWidth,x
;copy the height
	lda romSpriteHeight,y
	sta spriteHeight,x
;get hitbox
	lda romHitboxY1,y
	sta spriteHitboxY1,x
	lda romHitboxY2,y
	sta spriteHitboxY2,x
;copy behavior pointer
	lda romBehaviorH,y
	sta behaviorH,x
	lda romBehaviorL,y
	sta behaviorL,x
;every sprite has a starting y coordinate of zero (fall from top screen)
	lda #$00
	sta spriteYH,x
	lda #TRUE
	sta isActive,x
;return void
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

resetSprites:
	lda #NULL
	ldx #$00
;first set all oam values to ff. this puts them off screen in a known state
;for(x=0; x < 256 ; x++)
@setOamToNull:
	sta oam,x
	inx
	bne @setOamToNull
;next set all ram sprite objects to deactive
;conveniently x is 0(false)
	txa
;for(x = 0; x < MAX_OBJECTS; x++
@setDeactive:
	sta isActive,x
	inx
	cpx #MAX_OBJECTS
	bcc @setDeactive
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
;arguments
;x - sprite object to interpret
	lda behaviorH,x
	pha
	lda behaviorL,x
	pha
;we jump to the behavior subroutine pushed on to the stack and pass in sprite array object
;all behaviors return 
;a - metasprite
;y - y coordinate
;x - rail
	rts

getNewRail:;(a,x)
;arguments
;a - targetRail- where player is going
;x - currentRail- where player is
;variables
;railTemp - holds the target rail for comparison
;return 
;a-new current rail position
	sta railTemp
	tya
;if the target rail is larger than the current, were moving left
	cmp railTemp
	bmi @movingLeft
@movingRight:
;shift the rail bit left
	lsr
	rts
@movingLeft:
;shift the rail bit right
	asl
	rts

getX:
;arguments
;a - rail
;|uxxxxxxx|
;returns x value
	ror
	bcs @right;|u0000001|
	ror
	bcs @middleRight;|u0000010|
	ror
	bcs @middleMiddleRight;|u0000100
	ror
	bcs @middle;|u0001000|
	ror
	bcs @middleMiddleLeft;|u0010000|
	ror
	bcs @middleLeft;|u0100000|
@left:
	lda #$28
	rts
@middleLeft:
	lda #$40
	rts
@middleMiddleLeft:
	lda #$60
	rts
@middle:
	lda #$78
	rts
@middleMiddleRight:
	lda #$90
	rts
@middleRight:
	lda #$b0
	rts
@right:
	lda #$c8
	rts

buildOAM:
	lda #$00
	tay
	tax
	sty oamOffset
@oamLoop:
	stx objectToBuild
	lda isActive,x
	beq @skipEntry
	jsr buildEntry
	sta oamOffset
@skipEntry:
	ldx objectToBuild
	inx
	cpx #MAX_OBJECTS
	bcc @oamLoop
	lda oamOffset
	beq @oamFull
	jmp clearRemainingOAM;(a)
@oamFull:
	rts

buildEntry:
;tiles and attributes
	lda metasprite,x
	tay
	lda spriteTotal,x
	tax
	lda spriteTile0,y
	sta buildTile0
	lda spriteAttribute0,y
	sta buildAttribute0
	dex
	lda spriteTile1,y
	sta buildTile1
	lda spriteAttribute1,y
	sta buildAttribute1
	dex
	beq @coordinates
	lda spriteTile2,y
	sta buildTile2
	lda spriteAttribute2,y
	sta buildAttribute2
	dex
	lda spriteTile3,y
	sta buildTile3
	lda spriteAttribute3,y
	sta buildAttribute3
@coordinates:
	ldx objectToBuild
	lda spriteX,x
	sta buildX1
	clc
	adc #08
	sta buildX2
	lda spriteYH,x
	sta buildY1
	clc
	adc #16
	bcc @storeY
	lda #$ff
@storeY:
	sta buildY2

;oam
	ldx oamOffset
	ldy objectToBuild
	lda spriteTotal,y
	tay
	lda buildY1
	sta oam,x
	inx
	lda buildTile0
	sta oam,x
	inx
	lda buildAttribute0
	sta oam,x
	inx
	lda buildX1
	sta oam,x
	inx
	dey
	lda buildY1
	sta oam,x
	inx
	lda buildTile1
	sta oam,x
	inx
	lda buildAttribute1
	sta oam,x
	inx
	lda buildX2
	sta oam,x
	inx
	dey
	beq @next
	lda buildY2
	sta oam,x
	inx
	lda buildTile2
	sta oam,x
	inx
	lda buildAttribute2
	sta oam,x
	inx
	lda buildX1
	sta oam,x
	inx
	lda buildY2
	sta oam,x
	inx
	lda buildTile3
	sta oam,x
	inx
	lda buildAttribute3
	sta oam,x
	inx
	lda buildX2
	sta oam,x
	inx
@next:
	txa
	rts

clearRemainingOAM:
;arguments
;a-starting point to clear
	tax
	lda #$ff
@clearOAM:
	sta oam,x
	inx
	inx
	inx
	sta oam,x
	inx
	bne @clearOAM
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

;;;;;;;;;;;;;;;;;;;;;;
;;;sprite behaviors;;;
;;;;;;;;;;;;;;;;;;;;;;

playerBehavior:;(a)
;arguments 
;x - position in sprite array
;returns
;x - target rail position
;y - y coordinate
;a - metasprite
;bit positions are rail positions
;#%u0001000 is the center of rail
;#%u1000000 is left
;#%u0000001 is right
	lda controller1
	ror
	bcs @pressingRight
	ror
	bcs @pressingLeft
	jmp @pressingNone
@pressingRight:
	ror
	bcs @pressingBoth
	lda #%00000001
	jmp @getMetasprite
@pressingLeft:
	ror
	bcs @pressingBoth
	lda #%01000000
	jmp @getMetasprite
@pressingNone:
@pressingBoth:
	lda #%00001000
@getMetasprite:
	sta targetRail,x
;y value is constant for player
	lda #$c0
	sta spriteYH,x
	lda #00
;todo player metasprites
	sta metasprite,x
	rts

coinBehavior0:
;arguments
;x - ram object
;returns
;a = metatile
;x - rail
;y - y coordinate
;y = y + sprite speed
	clc
	lda spriteYL,x
	adc spriteSpeedL
	sta spriteYL,x
	lda spriteYH,x
	adc spriteSpeedH
	bcs @clearSprite
	sta spriteYH,x
	lda seconds
	and #%00011000
	lsr
	lsr
	lsr
	tay
	lda coinAnimation,y
	sta metasprite,x
	rts
@clearSprite:
	lda #$00
	sta isActive,x
	rts

.include "data.s"
.segment "VECTORS"
.word nmi
.word reset

.segment "CHARS"
.incbin "graphics.chr"
