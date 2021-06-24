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
;initialize player	
	jsr initializePlayer
;reset the clock to 0
	jsr resetClock;()
;load in target and palette
	ldx #TARGET_PALETTE
	ldy #6
	jsr setPalette
	ldx #PURPLE_BULLET
	ldy #7
	jsr setPalette
	jsr initializeEnemyWave

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
		jsr resetClock;()
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
;load with hitbox oscilation rate
	lda #%00111000
	and seconds
;if hitbox is a new color, update
	cmp currentHitboxColor
	beq @noHitboxChange
	sta currentHitboxColor
	jsr updateHitboxColor
@noHitboxChange:
;move player bullets
	jsr updatePlayerBullets
;move enemies
	jsr updateEnemies
;see if enemy hit by player bullet
;start building oam at 0
	ldy #0
	jsr buildPlayerOam;(y)
;returns
;y - new oam offset
	jsr buildPlayerBulletOam;(y)
;returns
;y - new oam offset
	jsr buildEnemyOam;(y)
;returns
;y - new oam offset
	jsr clearRemainingOam;(y)
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
	lda willHitboxUpdate
	beq beginOamDma
	jsr updateHitboxVram
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

updateHitboxVram:
;uploads new color for player hitbox in ppu
;arguments - none
;returns - void
;put address of hitbox color in ppu
	lda #$3f
	sta PPUADDR
	lda #$16
	sta PPUADDR
;get hitbox color (palette5 color 2)
	lda color2+5
	sta PPUDATA
;set flag to false
	lda #FALSE
	sta willHitboxUpdate
	rts

initializePlayer:
;first initialize palettes
	ldx #PLAYER_PALETTE
;set the players palette to #4 and #5. 
	ldy #4
	jsr setPalette;(x, y)
	ldx #PLAYER_PALETTE
;palette 5 ocilates color 2 for hitbox effect
	ldy #5
	jsr setPalette;(x, y)
	lda #200
	sta playerY
	lda #120
	sta playerX
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

buildPlayerOam:
;arguments
;y - oam offset
	lda playerMetasprite
;x is now metasprite data
	tax
	lda playerY
;store y of tile 0
	sta oam,y
	iny
	clc
	adc #16
	sta buildY1
	lda spriteTile0,x
;store tile 0
	sta oam,y
	iny
	lda spriteAttribute0,x
;store attribute 0
	sta oam,y
	iny
	lda playerX 
;store x tile 0
	sta oam,y
	iny
	adc #08
	sta buildX1
	lda playerY
;store y tile 1
	sta oam,y
	iny
;store tile 1
	lda spriteTile1,x
	sta oam,y
	iny
;store attribute tile 1
	lda spriteAttribute1,x
	sta oam,y
	iny
;store x tile 1
	lda buildX1
	sta oam,y
	iny
;store y tile 2
	lda buildY1
	sta oam,y
	iny
;store tile 2
	lda spriteTile2,x
	sta oam,y
	iny
;store attribute tile 2
	lda spriteAttribute2,x
	sta oam,y
	iny
;store x tile 2
	lda playerX
	sta oam,y
	iny
	rts

buildPlayerBulletOam:
	ldx #0
@buildLoop:
;while x < max bullets
	cpx #MAX_PLAYER_BULLETS
	bcs @endLoop
;if active is TRUE
	lda isPlayerBulletActive,x
;update
	bne @updateBullet
;x++
	inx
	jmp @buildLoop
@endLoop:
	rts
@updateBullet:
;save x
	txa
	pha
	lda playerBulletY,x
	sta oam,y
	iny
	lda playerBulletMetasprite,x
;x is now metasprite
	tax
	lda spriteTile0,x
	sta oam,y
	iny
	lda spriteAttribute0,x
	sta oam,y
	iny
	pla
	tax
	lda playerBulletX,x
	sta oam,y
	iny
	inx
	jmp @buildLoop

buildEnemyOam:
;arguments
;y - oam offset
	ldx #0
enemyOamLoop:
;while x < max enemies
	cpx #MAX_ENEMIES
	bcs @endLoop
;if enemy active, build oam entry
	lda isEnemyActive,x
	bne @buildEnemy
;x++
	inx
	jmp enemyOamLoop
@endLoop:
	rts
@buildEnemy:
;save x
	txa
	pha
	lda isEnemyHit,x
	sta buildAttribute
	lda enemyType,x
	tax
;x is now type
	bne @checkType1
	pla
	tax
	jmp buildType0
@checkType1:
	dex
	bne @checkType2
	pla
	tax
	jmp buildType1
@checkType2:
	dex
	bne @type3
	pla
	tax
	jmp buildType2
@type3:
	pla
	tax
	jmp buildType3

buildType0:
;save x
	txa
	pha
	lda enemyY,x
	sta oam,y
	iny
	lda enemyX,x
	sta buildX1
	lda enemyMetasprite,x
	tax
	lda spriteTile0,x
	sta oam,y
	iny
	lda spriteAttribute0,x
	ora buildAttribute
	sta oam,y
	iny
	lda buildX1
	sta oam,y
	iny
	pla
	tax
	inx
	jmp enemyOamLoop

buildType1:
;save x
	txa
	pha
	lda enemyY,x
	sta buildY1
	lda enemyX,x
	sta buildX1
	clc
	adc #08
	bcc @storeX
	lda #$ff
@storeX:
	sta buildX2
	lda buildY1
	lda enemyMetasprite,x
	tax
	lda buildY1
	sta oam,y
	iny
	lda spriteTile0,x
	sta oam,y
	iny
	lda spriteAttribute0,x
	ora buildAttribute
	sta oam,y
	iny
	lda buildX1
	sta oam,y
	iny
	lda buildY1
	sta oam,y
	iny
	lda spriteTile1,x
	sta oam,y
	iny
	lda spriteAttribute1,x
	ora buildAttribute
	sta oam,y
	iny
	lda buildX2
	sta oam,y
	iny
	pla
	tax
	inx
	jmp enemyOamLoop

buildType2:
;save x
	txa
	pha
	lda enemyY,x
	sta buildY1
	clc
	adc #16
	bcc @storeY
	lda #$ff
@storeY:
	sta buildY2
	lda enemyX,x
	sta buildX1
	clc
	adc #08
	bcc @storeX
	lda #$ff
@storeX:
	sta buildX2
	lda buildY1
	lda enemyMetasprite,x
	tax

	lda buildY1
	sta oam,y
	iny
	lda spriteTile0,x
	sta oam,y
	iny
	lda spriteAttribute0,x
	ora buildAttribute
	sta oam,y
	iny
	lda buildX1
	sta oam,y
	iny
	lda buildY1
	sta oam,y
	iny
	lda spriteTile1,x
	sta oam,y
	iny
	lda spriteAttribute1,x
	ora buildAttribute
	sta oam,y
	iny
	lda buildX2
	sta oam,y
	iny
	lda buildY2
	sta oam,y
	iny
	lda spriteTile2,x
	sta oam,y
	iny
	lda spriteAttribute2,x
	ora buildAttribute
	sta oam,y
	iny
	lda buildX1
	sta oam,y
	iny
	lda buildY2
	sta oam,y
	iny
	lda spriteTile3,x
	sta oam,y
	iny
	lda spriteAttribute3,x
	ora buildAttribute
	sta oam,y
	iny
	lda buildX2
	sta oam,y
	iny
	pla
	tax
	inx
	jmp enemyOamLoop

buildType3:
;save x
	txa
	pha
	lda enemyY,x
	sta buildY1
	lda enemyX,x
	sta buildX1
	clc
	adc #08
	bcs @overflowX2
	sta buildX2
	adc #08
	bcs @overflowX3
	sta buildX3
	adc #08
	bcs @overflowX4
	sta buildX4
	jmp @noOverflow
@overflowX2:
	lda #$ff
	sta buildX2
@overflowX3:
	lda #$ff
	sta buildX3
@overflowX4:
	lda #$ff
	sta buildX4
@noOverflow:
	lda buildY1
	lda enemyMetasprite,x
	tax
	lda buildY1
	sta oam,y
	iny
	lda spriteTile0,x
	sta oam,y
	iny
	lda spriteAttribute0,x
	ora buildAttribute
	sta oam,y
	iny
	lda buildX1
	sta oam,y
	iny
	lda buildY1
	sta oam,y
	iny
	lda spriteTile1,x
	sta oam,y
	iny
	lda spriteAttribute1,x
	ora buildAttribute
	sta oam,y
	iny
	lda buildX2
	sta oam,y
	iny
	lda buildY1
	sta oam,y
	iny
	lda spriteTile2,x
	sta oam,y
	iny
	lda spriteAttribute2,x
	ora buildAttribute
	sta oam,y
	iny
	lda buildX3
	sta oam,y
	iny
	lda buildY1
	sta oam,y
	iny
	lda spriteTile3,x
	sta oam,y
	iny
	lda spriteAttribute3,x
	ora buildAttribute
	sta oam,y
	iny
	lda buildX4
	sta oam,y
	iny
	pla
	tax
	inx
	jmp enemyOamLoop

clearRemainingOam:
;arguments
;y-starting point to clear
	lda #$ff
@clearOAM:
	sta oam,y
	iny
	iny
	iny
	sta oam,y
	iny
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

initializeEnemyWave:
	lda enemySlot0
	beq @slot1
	ldy #0;slot 0
	tax;enemy is x
	jsr initializeEnemy;(a,y)
@slot1:
	rts


initializeEnemy:
;places enemy from slot onto enemy array and screen coordinates
;arguments
;a - enemy
;y - slot
;save the enemy
	pha
	jsr getAvailableEnemy
;returns x - available enemy
;y is still slot, function retains y
;slotX and slotY are decoded x and y values for that slot
	lda slotX,y
	sta enemyX,x
	lda slotY,y
	sta enemyY,x
;get enemy
	pla
;y is now enemy
	tay
	lda romEnemyBehaviorH,y
	sta enemyBehaviorH,x
	lda romEnemyBehaviorL,y
	sta enemyBehaviorL,x
	lda romEnemyType,y
	sta enemyType,x
	tay
	lda romEnemyHitboxX1,y
	sta enemyHitboxX1,x
	lda romEnemyHitboxX2,y
	sta enemyHitboxX2,x
	lda romEnemyHitboxY2,y
	sta enemyHitboxY2,x
	lda romEnemyWidth,y
	sta enemyWidth,x
	lda romEnemyHeight,y
	sta enemyHeight,x
	rts

getAvailableEnemy:
;finds open enemy slot, returns offset, sets slot to active
;arguments - none
;returns
;x - enemy offset
	ldx #0
@enemySlotLoop:
	lda isEnemyActive,x
;if enemy is inactive return offset
	beq @returnEnemy
;x++
	inx
;while x < max enemies
	cpx #MAX_ENEMIES
	bcc @enemySlotLoop
	rts
@returnEnemy:
	lda #TRUE
;set enemy to active
	sta isEnemyActive,x
	rts

updatePlayer:
;constants
;pixel per frame when moving fast
FAST_MOVEMENT = 3
;pixel per frame when moving slow
SLOW_MOVEMENT = 1
;furthest right player can go
MAX_RIGHT = 249
;furthest left player can go
MAX_LEFT = 06
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
;todo add animation cycle
	lda #PLAYER_SPRITE
	sta playerMetasprite
	rts

initializePlayerBullet:
;arguments - none
;constants
PLAYER_BULLET_X_OFFSET = 4
PLAYER_BULLET_Y_OFFSET = 8

;find empty bullet starting with slot 0
	ldx #0
@findEmptyBullet:
	lda isPlayerBulletActive,x
;if bullet inactive initialize here
	beq @initializeBullet
	inx
;while x < max bullets
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
	lda #PLAYER_MAIN_BULLET
	sta playerBulletMetasprite,x
	rts

updateHitboxColor:
;cycles through colors to give players hitbox glowing effect
;arguments
;a - current hitbox color
;returns void
;shift right to turn into array index
	lsr
	lsr
	lsr
	tax
;get color from array of values
	lda playerHitbox,x
;oscilating color is color 2, palette 5
	sta color2+5
;set flag for nmi
	lda #TRUE
	sta willHitboxUpdate
	rts

updatePlayerBullets:
;arguments - none
;constants
;speed bullet travels up
PLAYER_BULLET_SPEED = 08
;start with bullet 0
	ldx #0
@bulletLoop:
;while x < maximum bullets
	cpx #MAX_PLAYER_BULLETS
	bcs @endBulletLoop
	lda isPlayerBulletActive,x
;if true, update bullet
	bne @updateBullet
;x++
	inx
	jmp @bulletLoop
@endBulletLoop:
	rts
@updateBullet:
;bit 2 holds collision data
	ror
	ror
;if set, enemy hit, deactivate
	bcs @deactivateBullet
	sec
	lda playerBulletY,x
	sbc #PLAYER_BULLET_SPEED
;if it has left screen, deactivate
	bcc @deactivateBullet
;else update y coordinate
	sta playerBulletY,x
	inx
	jmp @bulletLoop
@deactivateBullet:
	lda #FALSE
	sta isPlayerBulletActive,x
	inx
	jmp @bulletLoop

updateEnemies:
	ldy #0
@enemyUpdateLoop:
	lda isEnemyActive,y
	beq @enemyInactive
	jsr jumpToEnemyRoutine
@enemyInactive:
	iny
	cpy #MAX_ENEMIES
	bcc @enemyUpdateLoop
	rts

jumpToEnemyRoutine:
	lda enemyBehaviorH,y
	pha
	lda enemyBehaviorL,y
	pha
	rts

wasEnemyHit:
;x is player bullet, start with 0
	ldx #0
@bulletLoop:
;while x < max player bullets
	cpx #MAX_PLAYER_BULLETS
	bcs @endBulletLoop
;if player bullet active, check
	lda isPlayerBulletActive,x
	bne @cullX
;x ++
	inx
	jmp @bulletLoop
@endBulletLoop:
	clc
	rts
@cullX:
	sec
	lda playerBulletX,x
	sbc enemyX,y
	bcs @playerGreaterX
	eor #%11111111
@playerGreaterX:
	cmp enemyWidth,y
	bcc @cullY
	inc test
	inx
	jmp @bulletLoop
@cullY:
	sec
	lda playerBulletY,x
	sbc enemyY,y
	bcs @playerGreaterY
	eor #%11111111
@playerGreaterY:
	cmp enemyHeight,y
	bcc @checkCollision
	inx
	inc test
	jmp @bulletLoop
@checkCollision:
	clc
	lda playerBulletX,x
	sta sprite1LeftOrTop
	adc #08
	sta sprite1RightOrBottom
	lda enemyX,y
	adc enemyHitboxX1,y
	sta sprite2LeftOrTop
	adc enemyHitboxX2,y
	sta sprite2RightOrBottom
	jsr checkCollision
	bcs @checkY
	inx
	jmp @bulletLoop
@checkY:
	clc
	lda playerBulletY,x
	sta sprite1LeftOrTop
	adc #02
	sta sprite1RightOrBottom
	lda enemyY,y
	sta sprite2LeftOrTop
	adc enemyHitboxY2,y
	sta sprite2RightOrBottom
	jsr checkCollision
	bcs @hitDetected
	inx
	jmp @bulletLoop
@hitDetected:
	lda #%00000011
	sta isPlayerBulletActive,x
	rts

checkCollision:
;checks if two bound boxes intersect
;returns
;carry set if true, clear if false
	lda sprite1LeftOrTop
	cmp sprite2LeftOrTop
	bmi @check2
	cmp sprite2RightOrBottom
	bmi @insideBoundingBox
@notInBoundingBox:
	clc
	rts
@check2:
	lda sprite2LeftOrTop
	cmp sprite1RightOrBottom
	bpl @notInBoundingBox
@insideBoundingBox:
	sec
	rts

;;;;;;;;;;;;;;;;;;;;;;
;;;Sprite Behaviors;;;
;;;;;;;;;;;;;;;;;;;;;;
.byte 00
targetBehavior:
	lda #128
	sta enemyX,y
	lda #128
	sta enemyY,y
	lda #TARGET_SPRITE
	sta enemyMetasprite,y
	jsr wasEnemyHit;(y)
	bcs @hitDetected
	lda #FALSE
	sta isEnemyHit,y
	rts
@hitDetected:
	lda #TRUE
	sta isEnemyHit,y
	rts

.segment "VECTORS"
.word nmi
.word reset

.segment "CHARS"
.incbin "graphics.chr"
