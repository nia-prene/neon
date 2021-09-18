.include "lib.h"
.include "main.h"

.include "scenes.h"
.include "playerbullets.h"
.include "sprites.h"
.include "header.s"
.include "tiles.h"
.include "palettes.h"
.include "bullets.h"
.include "player.h"
.include "waves.h"
.include "gamepads.h"
.include "init.h"
.include "oam.h"
.include "ppu.h"
.include "enemies.h"
.include "powerup.h"

.zeropage
currentFrame: .res 1
framesDropped: .res 1
currentScene: .res 1
nextScene: .res 1
hasFrameBeenRendered: .res 1

.code
main:
	jsr PPU_init
	jsr PPU_resetScroll
	lda #00
	sta nextScene
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
	jsr PPU_resetClock;()
	lda #0
	sta framesDropped

gameLoop:
;while(!hasFrameBeenRendered)
	;hold here until previous frame was rendered
	lda hasFrameBeenRendered
	beq gameLoop
;if(nextScene != currentScene) 
	lda frame_L
	sta currentFrame
	lda nextScene
	cmp currentScene
	beq @sceneCurrent
	;update the scene
		;turn off rendering
		jsr disableRendering;(a, x)
		;set up the player
		jsr Player_initialize;()
		;get the tiles
		lda nextScene
		jsr unzipAllTiles;(a)
		;get the palettes
		ldx nextScene
		jsr setPaletteCollection;(x)
		;rendering is off so we can update video ram
		jsr renderAllTiles;()
		jsr renderAllPalettes;()
		;reset the enemy wave dispenser
		ldx nextScene
		jsr Waves_reset;(x)
		jsr enableRendering;(a, x)
		;set current to next
		lda nextScene
		sta currentScene
		jsr PPU_resetClock;()
@sceneCurrent:
;update the scroll
	jsr PPU_updateScroll
;move player
	lda Gamepads_state
	jsr Player_move;(a)
;update bullets
	jsr PlayerBullets_move
	lda Gamepads_state
;shoot bullets
	jsr Player_shoot;(a)
	jsr dispenseEnemies
;move enemies
	jsr updateEnemies
	jsr updateEnemyBullets
	;if iframes>0
	lda playerIFrames
	;player harmed recently
	bne @playerHarmed
	;if player unhit, build normal
	jsr Player_isHit
	bcc @buildSprites
	dec playerHP
	bpl @playerHarmed
	lda #4;gameover code here
	sta playerHP
@playerHarmed:
	inc playerIFrames
;when bit 3 of iFrames set
	lda #%00001000
;invert it because excluding player sprite requires carry set and we want player turned off right after hit
	eor playerIFrames
;shift inverse of bit 3 to carry
	ror
	ror
	ror
	ror
@buildSprites:
	jsr OAM_build;(c)
;if frame differs from beginning 
	lda frame_L
	cmp currentFrame
	beq @notDropped
;the frame was dropped
	inc framesDropped
@notDropped:
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
	php
	pha
	txa
	pha
	tya
	pha
	jsr PPU_advanceClock;()
;rendering code goes here
;oamdma transfer
	jsr OAM_beginDMA
	jsr Gamepads_read
	jsr PPU_setScroll
	lda #TRUE
	sta hasFrameBeenRendered	
;restore registers
	pla
	tay
	pla
	tax
	pla
	plp
	rti


.segment "VECTORS"
.word nmi 	;jump here during vblank
.word Init_reset;jump here on reset

.segment "CHARS"
.incbin "graphics.chr"
