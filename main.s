.include "constants.s"
.segment "HEADER"
.include "header.s"
.include "ram.s"
.include "data.s"
.segment "STARTUP"
.include "init.s"
.segment "CODE"
;after the init code, we jump here
main:
;housekeeping
;first scene is scene 0
	lda #00
	sta nextScene
	sta xScroll
	lda #239
	sta yScroll
	lda #NULL
;currently no scene is loaded
	sta currentScene
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
gameLoop:
;while(!hasFrameBeenRendered)
	;hold here until previous frame was rendered
	lda hasFrameBeenRendered
	beq gameLoop
;if(nextScene != currentScene) 
	lda nextScene
	cmp currentScene
	beq @updateScroll
	;update the scene
		lda seconds
		ldx currentMaskSettings
		jsr disableRendering;(a, x)
	;returns new mask settings
		sta currentMaskSettings
		lda nextScene
		jsr unzipAllTiles;(a)
		ldx nextScene
		jsr setPaletteCollection;(x)
	;we are in forced blank so we can call these two rendering routines
		jsr renderAllTiles
		jsr renderAllPalettes
		lda seconds
		ldx currentMaskSettings
		jsr enableRendering;(a, x)
	;returns new mask settings
		sta currentMaskSettings
	;set current to next
		lda nextScene
		sta currentScene
;update the scroll
@updateScroll:
	ldx yScroll
	dex
	cpx #$ff 
	bne @endScroll
	ldx #239
@endScroll:
	stx yScroll
	jsr updatePlayer
	jsr updatePlayerBullets
	lda #0
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
	lda xScroll
	sta PPUSCROLL
	lda yScroll
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

getAvailableOam:
;returns
;y- ram position of next available sprite
	ldy #$00
;if isActive = FALSE break
@findInactive:
	lda isActive,y
	beq @returnValue
	iny
	cpy #MAX_OBJECTS
	bcc @findInactive
;if no sprite is available, return null
	ldy #NULL
	rts
@returnValue:
;caller now owns this spot
	lda #TRUE
	sta isActive,y
;return offset of first sprite where inactive on y
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
	lda #FALSE
	sta isActive,x
	lda metasprite,x
	tay
	lda romSpriteTotal,y
	sta buildTotal
	tax
	lda spriteTile0,y
	sta buildTile0
	lda spriteAttribute0,y
	sta buildAttribute0
	dex
	beq @coordinates
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
	bcc @storeX
	lda #$ff
@storeX:
	sta buildX2
	lda spriteY,x
	sta buildY1
	clc
	adc #16
	bcc @storeY
	lda #$ff
@storeY:
	sta buildY2

;oam
	ldx oamOffset
	ldy buildTotal
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
	beq @next
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
updatePlayer:
;constants
;pixel per frame when moving fast
FAST_MOVEMENT = 3
;pixel per frame when moving slow
SLOW_MOVEMENT = 1
;furthest right player can go
MAX_RIGHT = 247
;furthest left player can go
MAX_LEFT = 04
;furthest up player can go
MAX_UP = 16
;furthest down player can go
MAX_DOWN = 209
;arguments none
	lda #%10000000
	bit controller1
	bne @goingSlow
@goingFast:
	lda #FAST_MOVEMENT
	sta playerSpeed
	jmp @updateMovement
@goingSlow:
	lda #SLOW_MOVEMENT
	sta playerSpeed
@updateMovement:
	lda #%00000001
	bit controller1
	beq @notRight
;if bit 0 set then move right
	clc
	lda playerX
	adc playerSpeed
	cmp #MAX_RIGHT
	bcc @storeRight
	lda #MAX_RIGHT
@storeRight:
	sta playerX
@notRight:
	lda #%00000010
	bit controller1
	beq @notLeft
;if bit 1 set then move left 
	sec
	lda playerX
	sbc playerSpeed
	cmp #MAX_LEFT
	bcs @storeLeft
	lda #MAX_LEFT
@storeLeft:
	sta playerX
@notLeft:
	lda #%00000100
	bit controller1
	beq @notDown
;if bit 2 set then move down
	clc
	lda playerY
	adc playerSpeed
	cmp #MAX_DOWN
	bcc @storeDown
	lda #MAX_DOWN
@storeDown:
	sta playerY
@notDown:
	lda #%00001000
	bit controller1
	beq @notUp
;if bit 3 set then move down
	sec
	lda playerY
	sbc playerSpeed
	cmp #MAX_UP
	bcs @storeUp
	lda #MAX_UP
@storeUp:
	sta playerY
@notUp:
	lda #%01000000
	bit controller1
	beq @notShooting
	inc pressingShoot
	lda pressingShoot
	and #%00000011
	cmp #%00000001
	bne @getMetatile
	jsr initializePlayerBullet
	jmp @getMetatile
@notShooting:
	lda #0
	sta pressingShoot
@getMetatile:
	jsr getAvailableOam
;x is now oam position to use
	lda #PLAYER_OBJECT
	sta metasprite,y
	lda playerX
	sta spriteX,y
	lda playerY
	sta spriteY,y
	rts

initializePlayerBullet:
;arguments - none
;constants
PLAYER_BULLET_X_OFFSET = 4
PLAYER_BULLET_Y_OFFSET = 8

;find empty bullet
	ldx #0
@findEmptyBullet:
	lda isPlayerBulletActive,x
;if bullet inactive initialize here
	beq @initializeBullet
	inx
	cpx #MAX_PLAYER_BULLETS
	bcc @findEmptyBullet
;no empty bullet
	rts
@initializeBullet:
	clc
	lda playerX
	adc #PLAYER_BULLET_X_OFFSET
	sta playerBulletX,x
	sec
	lda playerY
	sbc #PLAYER_BULLET_Y_OFFSET 
	sta playerBulletY,x
	lda #TRUE
	sta isPlayerBulletActive,x
	rts

updatePlayerBullets:
;arguments - none
;constants
;speed bullet travels up
PLAYER_BULLET_SPEED = 08
;start with bullet 0
	ldx #0
@bulletLoop:
	lda isPlayerBulletActive,x
;if true, update
	bne @updateBullet
	inx
;while x < maximum bullets
	cpx #MAX_PLAYER_BULLETS
	bcc @bulletLoop
	rts
@updateBullet:
	sec
	lda playerBulletY,x
	sbc #PLAYER_BULLET_SPEED
;if it has left screen, deactivate
	bcc @deactivateBullet
;else update y coordinate
	sta playerBulletY,x
;get an oam slot (returned on y)
	jsr getAvailableOam
;place coordinates and sprite on oambuffer
	lda playerBulletY,x
	sta spriteY,y
	lda playerBulletX,x
	sta spriteX,y
	lda #PLAYER_MAIN_BULLET
	sta metasprite,y
	inx
	jmp @bulletLoop
@deactivateBullet:
	lda #FALSE
	sta isPlayerBulletActive,x
	inx
	jmp @bulletLoop

.segment "VECTORS"
.word nmi
.word reset

.segment "CHARS"
.incbin "graphics.chr"
