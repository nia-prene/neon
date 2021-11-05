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
.include "oam.h"
.include "ppu.h"
.include "enemies.h"
.include "pickups.h"
.include "score.h"
.include "speed.h"
.include "init.s"

.zeropage
MAIN_stack: .res 1
currentFrame: .res 1
framesDropped: .res 1
currentScene: .res 1
nextScene: .res 1
hasFrameBeenRendered: .res 1
currentPlayer: .res 1
.code
main:
	NES_init
	jsr PPU_init
	jsr PPU_resetScroll
	lda #00
	sta nextScene
;player 0 starts
	sta currentPlayer
	lda #NULL
;currently no scene is loaded
	sta currentScene
;there is no frame that needs renderso set to TRUE
	sec
	rol hasFrameBeenRendered
;load in bullet palettes
	ldx #PURPLE_BULLET
	ldy #7
	jsr setPalette;(x,y)
;reset the scores
	ldx #0;player 1
	jsr Score_clear;(x)
	ldx #1;player 2
	jsr Score_clear;(x)
;reset the clock to 0
	jsr PPU_resetClock;()
	lda #0
	sta framesDropped
gameLoop:
;hold here until previous frame was rendered
	lda hasFrameBeenRendered
	beq gameLoop
;get the current frame and save it to test for dropped frames
	lda frame_L
	sta currentFrame
;load in a new level if the level has changed
	lda nextScene
	cmp currentScene
	beq :+
	;update the scene
	;turn off rendering
		jsr disableRendering;(a, x)
	;set up the player
		jsr Player_initialize;()
	;get the palettes
		ldx nextScene
		jsr setPaletteCollection;(x)
	;get the screen pointer
		ldx nextScene
		jsr Tiles_getScreenPointer
	;rendering is off so we can update video ram
		jsr renderAllTiles;()
		jsr PPU_renderHUD
		jsr renderAllPalettes;()
	;reset the enemy wave dispenser
		ldx nextScene
		jsr Waves_reset;(x)
	;set the bullet speeds
		ldx nextScene
		jsr Speed_setLevel
	;set sprite 0 hit
		jsr OAM_setSprite0
	;cover hud with 7 sprites to block out other sprites
		jsr OAM_setHUDCover
	;move the scoreboard to the right position
		jsr enableRendering;(a, x)
	;set current to next
		lda nextScene
		sta currentScene
		jsr PPU_resetClock;()
;update the scroll
:	jsr PPU_updateScroll
;if player is hoding A B SEL ST, reset the game
	lda Gamepads_state
	and #%11110000
	cmp #%11110000
	bne :+
		jmp main
;reset the score for this frame
:
	jsr Score_clearFrameTally
	lda Gamepads_state
;move player
	jsr Player_move;(a)
;move player bullets first to free up space for new ones
	jsr PlayerBullets_move
;shoot new bullets
	lda Gamepads_state
	jsr PlayerBullets_shoot;(a)
	jsr PPU_waitForSprite0Hit
	jsr updateEnemyBullets
;move enemies
	jsr updateEnemies
;create a new enemy
	jsr dispenseEnemies
;add up all points earned this frame
	lda currentPlayer
	jsr Score_tallyFrame;(a)
;if iframes>0, player harmed recently
	lda playerIFrames
	bne @playerHarmed
;if player unharmed, build normal
	jsr Player_isHit
	bcc @buildSprites
;decrease hp and power level
	dec Player_powerLevel
	bpl @decreaseHP
;dont let power level go negative
	lda #0
	sta Player_powerLevel
@decreaseHP:
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
	lda Gamepads_state
	jsr OAM_build;(c,a)
	jsr	PPU_scoreToBuffer
;if frame differs from beginning 
	lda frame_L
	cmp currentFrame
	beq :+
	;the frame was dropped
		inc framesDropped
:	lda #FALSE
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
	jsr PPU_renderScore
;rendering code goes here
	lda PPU_havePalettesChanged
	beq @skipPalettes
		jsr renderAllPalettes
@skipPalettes:
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
.word main;jump here on reset

.segment "CHARS"
.incbin "graphics.chr"
