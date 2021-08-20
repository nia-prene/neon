.include "constants.s"
.include "header.s"
.include "ram.s"
.include "tables.s"
.include "scenes.s"
.include "tiles.s"
.include "palettes.s"
.include "sprites.s"
.include "bullets.s"
.include "enemies.s"
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
;there is no frame that needs renderso set to TRUE
	sec
	rol hasFrameBeenRendered
;load in test palettes
	ldx #TARGET_PALETTE
	ldy #6
	jsr setPalette;(x,y)
	ldx #PURPLE_BULLET
	ldy #7
	jsr setPalette;(x,y)
;reset the clock to 0
	jsr resetClock;()

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
		jsr initializePlayer;()
		lda nextScene
		jsr unzipAllTiles;(a)
		ldx nextScene
		jsr setPaletteCollection;(x)
	;we are in forced blank so we can call these two rendering routines
		jsr renderAllTiles;()
		jsr renderAllPalettes;()
		ldx nextScene
		jsr setupEnemies;(x)
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
;todo legitimate scroll routine
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
;isolate bit 4 of clock
	lda seconds
	and #%00010000
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
;if player was hit recently
	lda iFrames
	bne @playerHarmed
;else check collision
	jsr wasPlayerHit
	bcs @playerHarmed
;else, build oam normally
@playerUnharmed:
	ldx #0
	jsr drawEnemyBullets
	jsr drawPlayer
	jsr drawPlayerBullets
	jsr drawEnemies
	jsr clearRemainingOam
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
	ldx #0
	jsr drawEnemyBullets
	jsr drawPlayerBullets
	jsr drawEnemies
	jsr clearRemainingOam;(x)
	lda #FALSE
	sta hasFrameBeenRendered
	jmp gameLoop
@resetIFrame:
	lda #0
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

setupEnemies:
;sets up the level's enemy wave system
;arguments
;x - current scene
;returns void

;get the address of the collection of enemy waves from the scene object and copy it in ram 
	lda levelWavesL,x
	sta levelWavePointer
	lda levelWavesH,x
	sta levelWavePointer+1
;start on 0th wave, 0th enemy
	lda #0
	sta enemyIndex
	sta waveIndex
;set this rate to known $ff value so it executes on first frame
	lda #NULL
	sta waveRate
	rts

drawEnemyBullets:
	lda #NULL;terminate
	pha
	ldy #MAX_ENEMY_BULLETS-1
@enemyBulletLoop:
	lda isEnemyBulletActive,y
	beq @skipBullet
	lda enemyBulletMetasprite,y
	pha
	lda enemyBulletYH,y
	pha
	lda enemyBulletXH,y
	pha
	lda #0; palette
	pha
@skipBullet:
	dey
	bpl @enemyBulletLoop
	jmp drawSprites

drawPlayer:
;prepares player sprite for drawing
;first push a null to terminate 
;then push sprite, y, x, palette
	lda #NULL;terminator
	pha
	lda playerMetasprite
	pha
	lda playerYH
	pha
	lda playerXH
	pha
	lda #0;palette
	pha
	jmp drawSprites

drawPlayerBullets:
	lda #NULL;terminate
	pha
	ldy #MAX_PLAYER_BULLETS-1
@drawLoop:
	lda isPlayerBulletActive,y
	beq @skipBullet
	lda playerBulletMetasprite,y
	pha
	lda playerBulletY,y
	pha
	lda playerBulletX,y
	pha
	lda #0;palette
	pha
@skipBullet:
	dey
	bpl @drawLoop
	jmp drawSprites

drawEnemies:
	lda #NULL
	pha
	ldy #MAX_ENEMIES-1
@enemyLoop:
	lda isEnemyActive,y
	beq @skipEnemy
	lda enemyMetasprite,y
	pha
	lda enemyYH,y
	pha
	lda enemyXH,y
	pha
	lda enemyStatus,y
	pha
@skipEnemy:
	dey
	bpl @enemyLoop
	jmp drawSprites

drawSprites:
;draws collections of sprites
;push tile, y, x, palette
;pull and use in reverse order
;returns
;x - current OAM position
	pla
	cmp #NULL
	beq @noSprites
@metaspriteLoop:
	sta buildPalette
	pla
	sta buildX
	pla
	sta buildY
	pla
	tay
	lda spritesL,y
	sta spritePointer
	lda spritesH,y
	sta spritePointer+1
	ldy #0
	clc
	lda (spritePointer),y
	@tileLoop:
		adc buildY
		bcs @yOverflow
	@returnY:
		sta oam,x
		inx
		iny
		lda (spritePointer),y
		sta oam,x
		inx
		iny
		lda (spritePointer),y
		ora buildPalette
		sta oam,x
		inx
		iny
		lda (spritePointer),y
		adc buildX
		bcs @xOverflow
	@returnX:
		sta oam,x
		inx
		iny
		lda (spritePointer),y
		cmp #NULL
		bne @tileLoop
	pla
	cmp #NULL
	bne @metaspriteLoop
@noSprites:
	rts
@yOverflow:
	clc
	lda #$ff
	jmp @returnY
@xOverflow:
	clc
	lda #$ff
	jmp @returnX

clearRemainingOam:
;arguments
;x-starting point to clear
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
	ldy waveIndex
	lda (levelWavePointer),y
	tax
	lda wavePointerL,x
	sta wavePointer
	lda wavePointerH,x
	sta wavePointer+1
	iny
	sty waveIndex
	ldy enemyIndex
;get the bullets
	lda (wavePointer),y
	sta bulletType
	sta bulletType+1
	iny
	lda (wavePointer),y
	sta bulletType+2
	iny
	lda (wavePointer),y
	sta bulletType+3
	iny
	sty enemyIndex
	rts

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
	sta enemyYH,x
;get x coordinate
	pla
	sta enemyXH,x
;copy data from rom
	pla
	tay
	lda romEnemyBehaviorH,y
	sta enemyBehaviorH,x
	lda romEnemyBehaviorL,y
	sta enemyBehaviorL,x
	lda romEnemyMetasprite,y
	sta enemyMetasprite,x
	lda romEnemyHPH,y
	sta enemyHPH,x
	lda romEnemyHPL,y
	sta enemyHPL,x
	lda #0
;clear variables
	sta i,x
	sta j,x
	sta k,x
;zero out low byte
	sta enemyXL,x
	sta enemyYL,x
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
	pla
	pla
	pla
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
SLOW_MOVEMENT_H = 1
SLOW_MOVEMENT_L = 0
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
	lda controller1
	ror
	bcc @notRight
;if bit 0 set then move right
	pha
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
	pla
@notRight:
	ror
;if bit 1 set then move left 
	bcc @notLeft
	pha
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
	pla
@notLeft:
;if bit 2 set then move down
	ror
	bcc @notDown
	pha
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
	pla
@notDown:
;if bit 3 set then move down
	ror
	bcc @notUp
	pha
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
	pla
@notUp:
	lda controller1
	and #%01000000
	beq @notShooting
	inc pressingShoot
	lda pressingShoot
	and playerRateOfFire
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
;find empty bullet starting with slot 0
	ldx #MAX_PLAYER_BULLETS-1
@findEmptyBullet:
	lda isPlayerBulletActive,x
;if bullet inactive initialize here
	beq @initializeBullet
	dex
;while x >=0 
	bpl @findEmptyBullet
;no empty bullet
	rts
@initializeBullet:
	lda playerXH
	sta playerBulletX,x
	lda playerYH
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
	sbc enemyXH,x
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
	sbc enemyYH,x
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
	lda enemyXH,x
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
	lda enemyYH,x
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
	ldx #MAX_ENEMY_BULLETS-1
@bulletLoop:
	lda isEnemyBulletActive,x
	beq @nextBullet
;if active
	sec
	lda enemyBulletXH,x
	sbc playerXH
	bcs @bulletGreaterX
;twos compliment if negative
	eor #%11111111
@bulletGreaterX:
;compare to bullet width
	cmp enemyBulletWidth,x
	bcs @nextBullet
;find distance between Y coordinates
	sec
	lda enemyBulletYH,x
	sbc playerYH
	bcs @bulletGreaterY
;twos compliment if negative
	eor #%11111111
@bulletGreaterY:
;compare distance from y to player hitbox
	cmp #24
;check collision distance less
	bcc @checkCollision
@nextBullet:
	dex
	bpl @bulletLoop
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
	bcc @nextBullet
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
	bcc @nextBullet
;else hit detected
	sec
	rts

checkCollision:
;checks if two bound boxes intersect
;returns
;carry set if true, clear if false
	lda sprite1LeftOrTop
	cmp sprite2LeftOrTop
	bmi @check2
;if sprite 1 is on the right and sprite 2's right side is greater than sprite 1's left side
	cmp sprite2RightOrBottom
	bmi @insideBoundingBox
@notInBoundingBox:
	clc
	rts
@check2:
	;if sprite 2 is on the right and sprite 2's left side is less than sprite 1's right side
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
	jsr getAvailableEnemyBullet
;returns x - offset of bullet object
	bcc @bulletsFull
;store x and y
	lda quickBulletX
	sta enemyBulletXH,x
	lda quickBulletY
	sta enemyBulletYH,x
;zero out low bit
	lda #0
	sta enemyBulletXL,x
	sta enemyBulletYL,x
;retrieve bullet id
	pla
	pha
;y is now the id
	tay
;copy function pointer
	lda romEnemyBulletBehaviorH,y
	sta enemyBulletBehaviorH,x
	lda romEnemyBulletBehaviorL,y
	sta enemyBulletBehaviorL,x
;get the type
	pla
;isolate bit 7 and 8
	rol
	rol
	rol
	and #%00000011
	tay
	lda bulletType,y
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
	rts
@bulletsFull:
;pull id
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

aimBullet:
;arguments:
;quickBulletX
;quickBulletY
;returns:
;a - degree from 0-256 to shoot bullet. use this degree to fetch correct bullet
	sec
	lda playerXH
	sbc quickBulletX
	bcs *+4
	eor #$ff
	tax
	rol octant
	lda playerYH
	adc #10
	sec
	sbc quickBulletY
	bcs *+4
	eor #$ff
	tay
	rol octant
	sec
	lda log2_tab,x
	sbc log2_tab,y
	bcc *+4
	eor #$ff
	tax
	lda octant
	rol
	and #%111
	tay
	lda atan_tab,x
	eor octant_adjust,y
	rts


.segment "VECTORS"
.word nmi
.word reset

.segment "CHARS"
.incbin "graphics.chr"
