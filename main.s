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
;reset the clock to 0
	jsr resetClock;()
;load in target and palette
	ldx #TARGET_PALETTE
	ldy #6
	jsr setPalette
	ldx #PURPLE_BULLET
	ldy #7
	jsr setPalette

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
		jsr initializePlayer
		lda nextScene
		jsr unzipAllTiles;(a)
		ldx nextScene
		jsr setPaletteCollection;(x)
	;we are in forced blank so we can call these two rendering routines
		jsr renderAllTiles
		jsr renderAllPalettes
	;start on 0th wave, 0th enemy
		ldx nextScene
		lda levelWavesL,x
		sta levelWavePointer
		lda levelWavesH,x
		sta levelWavePointer+1
		lda #0
		sta enemyIndex
		sta waveIndex
		lda #NULL
		sta waveRate
	;set current to next
		lda seconds
		ldx currentMaskSettings
		jsr enableRendering;(a, x)
	;returns new mask settings
		sta currentMaskSettings
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
;move player bullets
	jsr updatePlayerBullets
;isolate bit 3 of clock
	lda seconds
	and #%0001000
;if bit 3 of clock has changed
	cmp waveRate
	beq @skipWave
;save the new position
	sta waveRate
;add a new enemy to the wave
	jsr initializeEnemyWave
@skipWave:
;move enemies
	jsr updateEnemies
	jsr updateEnemyBullets
;if playerStatus != 0, player hit
	lda playerStatus
	bne @playerHarmed
@playerUnharmed:
;else, build oam normally
	ldy #0
	jsr buildPlayerHitboxOam
	jsr buildEnemyBulletsOam
	jsr buildPlayerOam;(y)
	jsr buildPlayerBulletOam;(y)
	jsr buildEnemyOam;(y)
	jsr clearRemainingOam;(y)
;this frame is finished
	lda #FALSE
	sta hasFrameBeenRendered
	jmp gameLoop
@playerHarmed:
;when iFrames hits 128, reset
	inc iFrames
	bmi @resetIFrame
;when bit 3 is set, render normally, this will make the sprite flash
	lda #%00001000
	and seconds
	bne @playerUnharmed
;else, build oam without player
	ldy #0
	jsr buildEnemyBulletsOam
	jsr buildPlayerBulletOam;(y)
	jsr buildEnemyOam;(y)
	jsr clearRemainingOam;(y)
	lda #FALSE
	sta hasFrameBeenRendered
	jmp gameLoop
@resetIFrame:
	lda #0
	sta playerStatus
	sta iFrames
	jmp @playerUnharmed


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
	sta playerYH
	lda #120
	sta playerXH
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

buildPlayerHitboxOam:
;renders glowing hitbox above everything else, so that player can be beneath bullets but hitbox wont flicker
;arguments
;y - oam position
;returns
;y - new oam position
	clc
	lda playerYH
	adc #16
	sta oam,y
	iny
	lda #%00010000
	bit seconds
	bne @frame2
	lda #06
	sta oam,y
	iny
	lda #0
	sta oam,y
	iny
	lda playerXH
	sta oam,y
	iny
	rts
@frame2:
	lda #08
	sta oam,y
	iny
	lda #0
	sta oam,y
	iny
	lda playerXH
	sta oam,y
	iny
	rts

buildEnemyBulletsOam:
	ldx #MAX_ENEMY_BULLETS-1
@bulletLoop:
	lda isEnemyBulletActive,x
	bne @buildBullet
	dex
	bpl @bulletLoop
	rts
@buildBullet:
;width is either 8px or 10px. cleared carry denotes 2 tiles
	lda enemyBulletWidth,x
	cmp #10
	bcs @buildBullet2
	jsr buildBullet0
	dex
	bpl @bulletLoop
	rts
@buildBullet2:
	jsr buildBullet1
	dex
	bpl @bulletLoop
	rts

buildBullet0:
	lda enemyBulletYH,x
	sta oam,y
	iny
	lda enemyBulletXH,x
	sta buildX1
	txa
	pha
	lda enemyBulletMetasprite,x
	tax
	lda spriteTile0,x
	sta oam,y
	iny
	lda spriteAttribute0,x
	sta oam,y
	iny
	lda buildX1
	sta oam,y
	iny
	pla
	tax
	rts

buildBullet1:
	lda enemyBulletYH,x
	sta buildY1
	sta oam,y
	iny
	lda enemyBulletXH,x
	sta buildX1
	clc
	adc #08
	sta buildX2
	txa
	pha
	lda enemyBulletMetasprite,x
	tax
	lda spriteTile0,x
	sta oam,y
	iny
	lda spriteAttribute0,x
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
	sta oam,y
	iny
	lda buildX2
	sta oam,y
	iny
	pla
	tax
	rts

buildPlayerOam:
;arguments
;y - oam offset
	lda playerMetasprite
;x is now metasprite data
	tax
	lda playerYH
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
	lda playerXH
;store x tile 0
	sta oam,y
	iny
	adc #08
	sta buildX1
	lda playerYH
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
	lda playerXH
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
;cycles through enemies in oam and draws them to the screen. function uses two loops, one indexing forward, one backward, alternating every frame to produce sprite flicker instead of masking consistent sprites
;arguments
;y - oam offset
;returns
;y - new oam offset
	lda #%00000001
	bit seconds
	bne @loop1
	ldx #0
@enemyOamLoop0:
;while x < max enemies
	cpx #MAX_ENEMIES
	bcs @endLoop
;if enemy active, build oam entry
	lda isEnemyActive,x
	bne @enemyActive
;x++
	inx
	jmp @enemyOamLoop0
@endLoop:
	rts
@enemyActive:
	jsr buildEnemy
	inx
	jmp @enemyOamLoop0

@loop1:
	ldx #MAX_ENEMIES-1
@enemyOamLoop1:
;if enemy active, build oam entry
	lda isEnemyActive,x
	bne @enemyActive1
;x++
	dex
	bmi @endLoop1
	jmp @enemyOamLoop1
@endLoop1:
	rts
@enemyActive1:
	jsr buildEnemy
	dex
	bmi @endLoop1
	jmp @enemyOamLoop1

buildEnemy:
;save x
	txa
	pha
	lda enemyStatus,x
;hit information held in bit 1. this will flash palette
	and #%00000001
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
	rts

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
	rts

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
	rts

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
	rts

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
;track the index in the array
	ldy enemyIndex
;if y=0, get a new wave
	beq @newWave
;@newWave returns here w/ new pntr
@resume:
;else get the enemy
	lda (wavePointer),y
	beq @skip
;null terminated
	cmp #NULL
	beq @hold
;save enemy
	pha
	iny
;get the coordinate
	lda (wavePointer),y
;y is now coordinate
	tax
	lda waveY,x
	pha
	lda waveX,x
	tax
	iny
	sty enemyIndex
	pla
	tay
	pla
	jmp initializeEnemy;(a,x,y)
@skip:
	iny
	sty enemyIndex
	rts
@hold:
	jsr areEnemiesRemaining
	bcc @noneRemaining
	rts
@noneRemaining:
	lda #0
	sta enemyIndex
	rts
@newWave:
	tya
	pha
	ldy waveIndex
	lda (levelWavePointer),y
	tax
	lda wavePointerL,x
	sta wavePointer
	lda wavePointerH,x
	sta wavePointer+1
	iny
	sty waveIndex
	pla
	tay
	jmp @resume

initializeEnemy:
;places enemy from slot onto enemy array and screen coordinates
;arguments
;a - enemy
;x - x coordinate
;y - y coordinate
;returns null
;save enemy
	pha
;save x
	txa
	pha
;save y
	tya
	pha
;save x coordinate
	jsr getAvailableEnemy
	bcc @enemiesFull
;returns x - available enemy
;retains y, enemy
;get y coordinate
	pla
	sta enemyY,x
;get x coordinate
	pla
	sta enemyX,x
;copy data from rom
	pla
	tay
	lda romEnemyBehaviorH,y
	sta enemyBehaviorH,x
	lda romEnemyBehaviorL,y
	sta enemyBehaviorL,x
	lda romEnemyMetasprite,y
	sta enemyMetasprite,x
	lda romEnemyHP,y
	sta enemyHP,x
	lda #0
;clear variables
	sta i,x
	sta j,x
;zero out the clock
	sta enemyClock,x
;get enemy type
	lda romEnemyType,y
	sta enemyType,x
;use enemy type to get hardcoded attributes
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
@enemiesFull:
	rts

getAvailableEnemy:
;finds open enemy slot, returns offset, sets slot to active
;arguments - none
;returns
;x - enemy offset
	ldx #MAX_ENEMIES-1
@enemySlotLoop:
	lda isEnemyActive,x
;if enemy is inactive return offset
	beq @returnEnemy
;x--
	dex
;while x >= 0
	bpl @enemySlotLoop
	clc
	rts
@returnEnemy:
	lda #TRUE
;set enemy to active
	sta isEnemyActive,x
;set carry to success
	sec
	rts

areEnemiesRemaining:
	ldx #MAX_ENEMIES-1
@enemyLoop:
	lda isEnemyActive,x
	bne @enemiesActive
	dex
	bpl @enemyLoop
	clc
	rts
@enemiesActive:
	sec
	rts

updatePlayer:
;constants
;pixel per frame when moving fast
FAST_MOVEMENT_H = 3
FAST_MOVEMENT_L = 128
;pixel per frame when moving slow
SLOW_MOVEMENT_H = 0
SLOW_MOVEMENT_L = 128
RAPID_FIRE = %00000001
STANDARD_FIRE=%00000011
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
	lda #FAST_MOVEMENT_L
	sta playerSpeedL
	lda #FAST_MOVEMENT_H
	sta playerSpeedH
	lda #STANDARD_FIRE
	sta playerRateOfFire
	jmp @updateMovement
@goingSlow:
	lda #SLOW_MOVEMENT_L
	sta playerSpeedL
	lda #SLOW_MOVEMENT_H
	sta playerSpeedH
	lda #RAPID_FIRE
	sta playerRateOfFire
@updateMovement:
	lda #%00000001
	bit controller1
	beq @notRight
;if bit 0 set then move right
	clc
	lda playerXL
	adc playerSpeedL
	sta playerXL
	lda playerXH
	adc playerSpeedH
	cmp #MAX_RIGHT
	bcc @storeRight
	lda #MAX_RIGHT
@storeRight:
	sta playerXH
@notRight:
	lda #%00000010
	bit controller1
	beq @notLeft
;if bit 1 set then move left 
	sec
	lda playerXL
	sbc playerSpeedL
	sta playerXL
	lda playerXH
	sbc playerSpeedH
	cmp #MAX_LEFT
	bcs @storeLeft
	lda #MAX_LEFT
@storeLeft:
	sta playerXH
@notLeft:
	lda #%00000100
	bit controller1
	beq @notDown
;if bit 2 set then move down
	clc
	lda playerYL
	adc playerSpeedL
	sta playerYL
	lda playerYH
	adc playerSpeedH
	cmp #MAX_DOWN
	bcc @storeDown
	lda #MAX_DOWN
@storeDown:
	sta playerYH
@notDown:
	lda #%00001000
	bit controller1
	beq @notUp
;if bit 3 set then move down
	sec
	lda playerYL
	sbc playerSpeedL
	sta playerYL
	lda playerYH
	sbc playerSpeedH
	cmp #MAX_UP
	bcs @storeUp
	lda #MAX_UP
@storeUp:
	sta playerYH
@notUp:
	lda #%01000000
	bit controller1
	beq @notShooting
	inc pressingShoot
	lda pressingShoot
	and playerRateOfFire
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
	lda playerXH
	adc #PLAYER_BULLET_X_OFFSET
	sta playerBulletX,x
	sec
	lda playerYH
	sbc #PLAYER_BULLET_Y_OFFSET 
	sta playerBulletY,x
	lda #TRUE
	sta isPlayerBulletActive,x
	lda #PLAYER_MAIN_BULLET
	sta playerBulletMetasprite,x
	rts

updatePlayerBullets:
;arguments - none
;constants
;speed bullet travels up
PLAYER_BULLET_SPEED = 12
;start with last bullet(faster)
	ldx #MAX_PLAYER_BULLETS-1
@bulletLoop:
	lda isPlayerBulletActive,x
;if true, update bullet
	bne @updateBullet
;x--
	dex
;while x >=0
	bpl @bulletLoop
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
	dex
	bpl @bulletLoop
	rts
@deactivateBullet:
	lda #FALSE
	sta isPlayerBulletActive,x
	dex
	bpl @bulletLoop
	rts

updateEnemies:
;loops through enemy list, if enemy is active, pushes enemy index and behavior function onto stack, returns. If enemy behavior is on the stack, it will essentially jump to that function. all enemy functions need to pull the index off the stack or processor will jump to unknown location
;arguments - none
;returns - none
	ldx #MAX_ENEMIES-1
@enemyUpdateLoop:
;if enemy is active, update
	lda isEnemyActive,x
	bne @enemyActive
;x--
	dex
;while x >= 0
	bpl @enemyUpdateLoop
	rts
@enemyActive:
;save index
	txa
	pha
;push function onto stack
	lda enemyBehaviorH,x
	pha
	lda enemyBehaviorL,x
	pha
;x--
	dex
;while x>=0
	bpl @enemyUpdateLoop
	rts

wasEnemyHit:
;compares enemies to the player bullets and determines if they overlap
;arguments
;x - enemy to check
;y is player bullet, start with 0
	ldy #0
@bulletLoop:
;while y < max player bullets
	cpy #MAX_PLAYER_BULLETS
	bcs @endBulletLoop
;if player bullet active, check
	lda isPlayerBulletActive,y
	bne @cullX
;y ++
	iny
	jmp @bulletLoop
@endBulletLoop:
	clc
	rts
@cullX:
	sec
	lda playerBulletX,y
	sbc enemyX,x
	bcs @playerGreaterX
	eor #%11111111
@playerGreaterX:
	cmp enemyWidth,x
	bcc @cullY
	iny
	jmp @bulletLoop
@cullY:
	sec
	lda playerBulletY,y
	sbc enemyY,x
	bcs @playerGreaterY
	eor #%11111111
@playerGreaterY:
	cmp enemyHeight,x
	bcc @checkCollision
	iny
	jmp @bulletLoop
@checkCollision:
	clc
	lda playerBulletX,y
	sta sprite1LeftOrTop
	adc #08
	sta sprite1RightOrBottom
	lda enemyX,x
	adc enemyHitboxX1,x
	sta sprite2LeftOrTop
	adc enemyHitboxX2,x
	sta sprite2RightOrBottom
	jsr checkCollision
	bcs @checkY
	iny
	jmp @bulletLoop
@checkY:
	clc
	lda playerBulletY,y
	sta sprite1LeftOrTop
	adc #02
	sta sprite1RightOrBottom
	lda enemyY,x
	sta sprite2LeftOrTop
	adc enemyHitboxY2,x
	sta sprite2RightOrBottom
	jsr checkCollision
	bcs @hitDetected
	iny
	jmp @bulletLoop
@hitDetected:
	lda #%00000011
	sta isPlayerBulletActive,y
	rts

wasPlayerHit:
;arguments
;x - enemy bullet offset
@cullX:
;find the distance between x values
	sec
	lda enemyBulletXH,x
	sbc playerXH
	bcs @bulletGreaterX
;twos compliment if negative
	eor #%11111111
@bulletGreaterX:
;compare to bullet width, proceed if distance less than width
	cmp enemyBulletWidth,x
	bcc @cullY
;mark false and return
	clc
	rts
@cullY:
;find distance between Y coordinates
	sec
	lda enemyBulletYH,x
	sbc playerYH
	bcs @bulletGreaterY
;twos compliment if negative
	eor #%11111111
@bulletGreaterY:
;compare to distance from y to player hitbox (alwas greater than bullet height)
	cmp #24
;check collision distance less
	bcc @checkCollision
;mark false and return
	clc
	rts
@checkCollision:
	clc
	lda playerXH
	adc #02
	sta sprite1LeftOrTop
	adc #03
	sta sprite1RightOrBottom
	lda enemyBulletXH,x
	adc enemyBulletHitboxX1,x
	sta sprite2LeftOrTop
	adc enemyBulletHitboxX2,x
	sta sprite2RightOrBottom
	jsr checkCollision
	bcs @checkY
	clc
	rts
@checkY:
	clc
	lda playerYH
	adc #19
	sta sprite1LeftOrTop
	adc #02
	sta sprite1RightOrBottom
	lda enemyBulletYH,x
	adc enemyBulletHitboxY1,x
	sta sprite2LeftOrTop
	adc enemyBulletHitboxY2,x
	sta sprite2RightOrBottom
	jsr checkCollision
	bcs @hitDetected
	clc
	rts
@hitDetected:
	sec
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

updateEnemyBullets:
	ldx #MAX_ENEMY_BULLETS-1
@bulletLoop:
;if bullet active, update
	lda isEnemyBulletActive,x
	bne @updateBullet
;x--
	dex
;while x>=0
	bpl @bulletLoop
	rts
@updateBullet:
;save offset
	txa
	pha
;push the address
	lda enemyBulletBehaviorH,x
	pha
	lda enemyBulletBehaviorL,x
	pha
;x--
	dex
;while x>=0
	bpl @bulletLoop
	rts

initializeEnemyBullet:
;initializes a bullet based on coordinates and a bullet ID
;arguments
;x - x coordinate
;y - y coordinate
;a - bullet ida
;save bullet
	pha
;save y
	tya
	pha
;save x
	txa
	pha
	jsr getAvailableEnemyBullet
;returns x - offset of bullet object
	bcc @bulletsFull
;retrieve x
	pla
	sta enemyBulletXH,x
;retrieve y
	pla
	sta enemyBulletYH,x
;zero out low bit
	lda #0
	sta enemyBulletXL,x
	sta enemyBulletYL,x
;retrieve bullet id
	pla
;y is now the id
	tay
;copy function pointer
	lda romEnemyBulletBehaviorH,y
	sta enemyBulletBehaviorH,x
	lda romEnemyBulletBehaviorL,y
	sta enemyBulletBehaviorL,x
;get the type
	lda romEnemyBulletType,y
;y is now type, copy values on type
	tay
;copy metasprite
	lda romEnemyBulletMetasprite,y
	sta enemyBulletMetasprite,x
;copy width
	lda romEnemyBulletWidth,y
	sta enemyBulletWidth,x
;copy hitboxes
	lda romEnemyBulletHitboxX1,y
	sta enemyBulletHitboxX1,x
	lda romEnemyBulletHitboxX2,y
	sta enemyBulletHitboxX2,x
	lda romEnemyBulletHitboxY1,y
	sta enemyBulletHitboxY1,x
	lda romEnemyBulletHitboxY2,y
	sta enemyBulletHitboxY2,x
;reset clock
	lda #$ff
	sta enemyBulletClock,x
	rts
@bulletsFull:
;pull x, y, id
	pla
	pla
	pla
	rts

getAvailableEnemyBullet:
;loos through bullet collection, finds inactive bullet, sets to active, returns offset
;arguments - none
;returns
;x - active offset
;carry clear if full, set if success
	ldx #MAX_ENEMY_BULLETS-1
@bulletLoop:
	lda isEnemyBulletActive,x
	beq @returnBullet
	dex
	bpl @bulletLoop
;mark full
	clc
	rts
@returnBullet:
;set active
	lda #TRUE
	sta isEnemyBulletActive,x
;mark success
	sec
	rts

;;;;;;;;;;;;;;;;;;;;;;
;;;Sprite Behaviors;;;
;;;;;;;;;;;;;;;;;;;;;;
;Enemy Behaviors;
;;;;;;;;;;;;;;;;;

;to reference sprite.self, use x register
targetBehavior:
	pla
	tax
	pha
	lda #128
	sta enemyX,x
	lda #64
	sta enemyY,x
	lda seconds
	and #%00000001
	bne @skip
	clc
	lda enemyY,x
	adc #16
	tay
	lda enemyX,x
	adc #8
	tax
	lda i,x
	adc #31
	sta i,x
	and #%01111111
	jsr initializeEnemyBullet
@skip:
	pla
	tax
	jsr wasEnemyHit;(x)
	bcs @hitDetected
	lda #FALSE
	sta enemyStatus,x
	rts
@hitDetected:
	dec enemyHP,x
	lda #TRUE
	sta enemyStatus,x
	rts



;;;;;;;;;;;;;;;;;;
;Bullet Behaviors;
;;;;;;;;;;;;;;;;;;

.macro mainFib quadrant, yPixelsH, yPixelsL, xPixelsH, xPixelsL
	pla
	tax
.if (.xmatch ({quadrant}, 1) .or .xmatch ({quadrant}, 2))
	sec
	lda enemyBulletYL,x
	sbc yPixelsL
.elseif (.xmatch ({quadrant}, 3) .or .xmatch ({quadrant}, 4))
	clc
	lda enemyBulletYL,x
	adc yPixelsL
.else
.error "Must Supply Valid Quadrant"
.endif
	sta enemyBulletYL,x
	lda enemyBulletYH,x
.if (.xmatch ({quadrant}, 1) .or .xmatch ({quadrant}, 2))
	sbc yPixelsH
	bcc @clearBullet
.elseif (.xmatch ({quadrant}, 3) .or .xmatch ({quadrant}, 4))
	adc yPixelsH
	bcs @clearBullet
.else
.error "Must Supply Valid Quadrant"
.endif
	sta enemyBulletYH,x
	lda enemyBulletXL,x
.if (.xmatch ({quadrant}, 1) .or .xmatch ({quadrant}, 4))
	adc xPixelsL
.elseif (.xmatch ({quadrant}, 2) .or .xmatch ({quadrant}, 3))
	sbc xPixelsL
.else
.error "Must Supply Valid Quadrant"
.endif
	sta enemyBulletXL,x
	lda enemyBulletXH,x
.if (.xmatch ({quadrant}, 1) .or .xmatch ({quadrant}, 4))
	adc xPixelsH
	bcs @clearBullet
.elseif (.xmatch ({quadrant}, 2) .or .xmatch ({quadrant}, 3))
	sbc xPixelsH
	bcc @clearBullet
.else
.error "Must Supply Valid Quadrant"
.endif
	sta enemyBulletXH,x
	jsr wasPlayerHit
	bcs @hitDetected
	rts
@hitDetected:
	lda #TRUE
	sta playerStatus
	rts
@clearBullet:
	lda #FALSE
	sta isEnemyBulletActive,x
	rts
.endmacro
bullet0:
	mainFib 1, #2, #0, #0, #0
bullet1:
	mainFib 1, #1, #255, #0, #22
bullet2:
	mainFib 1, #1, #253, #0, #45
bullet3:
	mainFib 1, #1, #251, #0, #67
bullet4:
	mainFib 1, #1, #249, #0, #90
bullet5:
	mainFib 1, #1, #243, #0, #112
bullet6:
	mainFib 1, #1, #237, #0, #135
bullet7:
	mainFib 1, #1, #230, #0, #157
bullet8:
	mainFib 1, #1, #223, #0, #180
bullet9:
	mainFib 1, #1, #214, #0, #202
bulletA:
	mainFib 1, #1, #204, #0, #225
bulletB:
	mainFib 1, #1, #192, #0, #247
bulletC:
	mainFib 1, #1, #176, #1, #14
bulletD:
	mainFib 1, #1, #162, #1, #36
bulletE:
	mainFib 1, #1, #146, #1, #60
bulletF:
	mainFib 1, #1, #126, #1, #82
bullet10:
	mainFib 1, #1, #106, #1, #106
bullet11:
	mainFib 1, #1, #82, #1, #126
bullet12:
	mainFib 1, #1, #60, #1, #146
bullet13:
	mainFib 1, #1, #36, #1, #162
bullet14:
	mainFib 1, #1, #14, #1, #176
bullet15:
	mainFib 1, #0, #247, #1, #192
bullet16:
	mainFib 1, #0, #225, #1, #204
bullet17:
	mainFib 1, #0, #202, #1, #214
bullet18:
	mainFib 1, #0, #180, #1, #223
bullet19:
	mainFib 1, #0, #157, #1, #230
bullet1A:
	mainFib 1, #0, #135, #1, #237
bullet1B:
	mainFib 1, #0, #112, #1, #243
bullet1C:
	mainFib 1, #0, #90, #1, #249
bullet1D:
	mainFib 1, #0, #67, #1, #251
bullet1E:
	mainFib 1, #0, #45, #1, #253
bullet1F:
	mainFib 1, #0, #22, #1, #255
bullet20:
	mainFib 4, #0, #0, #2, #0
bullet21:
	mainFib 4, #0, #22, #1, #255
bullet22:
	mainFib 4, #0, #45, #1, #253
bullet23:
	mainFib 4, #0, #67, #1, #251
bullet24:
	mainFib 4, #0, #90, #1, #249
bullet25:
	mainFib 4, #0, #112, #1, #243
bullet26:
	mainFib 4, #0, #135, #1, #237
bullet27:
	mainFib 4, #0, #157, #1, #230
bullet28:
	mainFib 4, #0, #180, #1, #223
bullet29:
	mainFib 4, #0, #202, #1, #214
bullet2A:
	mainFib 4, #0, #225, #1, #204
bullet2B:
	mainFib 4, #0, #247, #1, #192
bullet2C:
	mainFib 4, #1, #14, #1, #176
bullet2D:
	mainFib 4, #1, #36, #1, #162
bullet2E:
	mainFib 4, #1, #60, #1, #146
bullet2F:
	mainFib 4, #1, #82, #1, #126
bullet30:
	mainFib 4, #1, #106, #1, #106
bullet31:
	mainFib 4, #1, #126, #1, #82
bullet32:
	mainFib 4, #1, #146, #1, #60
bullet33:
	mainFib 4, #1, #162, #1, #36
bullet34:
	mainFib 4, #1, #176, #1, #14
bullet35:
	mainFib 4, #1, #192, #0, #247
bullet36:
	mainFib 4, #1, #204, #0, #225
bullet37:
	mainFib 4, #1, #214, #0, #202
bullet38:
	mainFib 4, #1, #223, #0, #180
bullet39:
	mainFib 4, #1, #230, #0, #157
bullet3A:
	mainFib 4, #1, #237, #0, #135
bullet3B:
	mainFib 4, #1, #243, #0, #112
bullet3C:
	mainFib 4, #1, #249, #0, #90
bullet3D:
	mainFib 4, #1, #251, #0, #67
bullet3E:
	mainFib 4, #1, #253, #0, #45
bullet3F:
	mainFib 4, #1, #255, #0, #22
bullet40:
	mainFib 3, #2, #0, #0, #0
bullet41:
	mainFib 3, #1, #255, #0, #22
bullet42:
	mainFib 3, #1, #253, #0, #45
bullet43:
	mainFib 3, #1, #251, #0, #67
bullet44:
	mainFib 3, #1, #249, #0, #90
bullet45:
	mainFib 3, #1, #243, #0, #112
bullet46:
	mainFib 3, #1, #237, #0, #135
bullet47:
	mainFib 3, #1, #230, #0, #157
bullet48:
	mainFib 3, #1, #223, #0, #180
bullet49:
	mainFib 3, #1, #214, #0, #202
bullet4A:
	mainFib 3, #1, #204, #0, #225
bullet4B:
	mainFib 3, #1, #192, #0, #247
bullet4C:
	mainFib 3, #1, #176, #1, #14
bullet4D:
	mainFib 3, #1, #162, #1, #36
bullet4E:
	mainFib 3, #1, #146, #1, #60
bullet4F:
	mainFib 3, #1, #126, #1, #82
bullet50:
	mainFib 3, #1, #106, #1, #106
bullet51:
	mainFib 3, #1, #82, #1, #126
bullet52:
	mainFib 3, #1, #60, #1, #146
bullet53:
	mainFib 3, #1, #36, #1, #162
bullet54:
	mainFib 3, #1, #14, #1, #176
bullet55:
	mainFib 3, #0, #247, #1, #192
bullet56:
	mainFib 3, #0, #225, #1, #204
bullet57:
	mainFib 3, #0, #202, #1, #214
bullet58:
	mainFib 3, #0, #180, #1, #223
bullet59:
	mainFib 3, #0, #157, #1, #230
bullet5A:
	mainFib 3, #0, #135, #1, #237
bullet5B:
	mainFib 3, #0, #112, #1, #243
bullet5C:
	mainFib 3, #0, #90, #1, #249
bullet5D:
	mainFib 3, #0, #67, #1, #251
bullet5E:
	mainFib 3, #0, #45, #1, #253
bullet5F:
	mainFib 3, #0, #22, #1, #255
bullet60:
	mainFib 2, #0, #0, #2, #0
bullet61:
	mainFib 2, #0, #22, #1, #255
bullet62:
	mainFib 2, #0, #45, #1, #253
bullet63:
	mainFib 2, #0, #67, #1, #251
bullet64:
	mainFib 2, #0, #90, #1, #249
bullet65:
	mainFib 2, #0, #112, #1, #243
bullet66:
	mainFib 2, #0, #135, #1, #237
bullet67:
	mainFib 2, #0, #157, #1, #230
bullet68:
	mainFib 2, #0, #180, #1, #223
bullet69:
	mainFib 2, #0, #202, #1, #214
bullet6A:
	mainFib 2, #0, #225, #1, #204
bullet6B:
	mainFib 2, #0, #247, #1, #192
bullet6C:
	mainFib 2, #1, #14, #1, #176
bullet6D:
	mainFib 2, #1, #36, #1, #162
bullet6E:
	mainFib 2, #1, #60, #1, #146
bullet6F:
	mainFib 2, #1, #82, #1, #126
bullet70:
	mainFib 2, #1, #106, #1, #106
bullet71:
	mainFib 2, #1, #126, #1, #82
bullet72:
	mainFib 2, #1, #146, #1, #60
bullet73:
	mainFib 2, #1, #162, #1, #36
bullet74:
	mainFib 2, #1, #176, #1, #14
bullet75:
	mainFib 2, #1, #192, #0, #247
bullet76:
	mainFib 2, #1, #204, #0, #225
bullet77:
	mainFib 2, #1, #214, #0, #202
bullet78:
	mainFib 2, #1, #223, #0, #180
bullet79:
	mainFib 2, #1, #230, #0, #157
bullet7A:
	mainFib 2, #1, #237, #0, #135
bullet7B:
	mainFib 2, #1, #243, #0, #112
bullet7C:
	mainFib 2, #1, #249, #0, #90
bullet7D:
	mainFib 2, #1, #251, #0, #67
bullet7E:
	mainFib 2, #1, #253, #0, #45
bullet7F:
	mainFib 2, #1, #255, #0, #22

.segment "VECTORS"
.word nmi
.word reset

.segment "CHARS"
.incbin "graphics.chr"
