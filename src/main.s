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
.include "hud.h"
.include "init.s"

.zeropage
Main_stack: .res 1
currentFrame: .res 1
framesDropped: .res 1
currentScene: .res 1
nextScene: .res 1
hasFrameBeenRendered: .res 1
Main_currentPlayer: .res 1
Main_gameState: .res 1
Main_frame_L: .res 1
Main_frame_H: .res 1

.code
main:
	NES_init
	jsr PPU_init
	lda #00
	sta Main_gameState
	sta nextScene
;player 0 starts
	sta Main_currentPlayer
;there is no frame that needs renderso set to TRUE
	sec
	rol hasFrameBeenRendered
;reset the scores
	ldx #0;player 1
	jsr Score_clear;(x)
	jsr Player_init;(x)
	ldx #1;player 2
	jsr Score_clear;(x)
	jsr Player_init;(x)
	lda #0
	sta framesDropped
	jsr Main_loadLevel;(nextScene)

gameLoop:
	lda hasFrameBeenRendered
	beq gameLoop;hold for vblank occourance
	ldy Main_gameState
	lda @gameStates_H,y
	pha
	lda @gameStates_L,y
	pha
	rts

@gameStates_H:
	.byte >(gameState00-1), >(gameState01-1)
@gameStates_L:
	.byte <(gameState00-1), <(gameState01-1)

gameState00:
;the main gameplay loop
	lda Main_frame_L
	sta currentFrame
	jsr PPU_updateScroll
	jsr Gamepads_read
;if player is hoding A B SEL ST, reset the game
	lda Gamepads_state
	and #%11110000
	cmp #%11110000
	bne :+
		jmp main
:
	jsr Score_clearFrameTally
	lda Gamepads_state
	jsr Player_move;(a)
	jsr PlayerBullets_move
	lda Gamepads_state
	jsr PlayerBullets_shoot;(a)
	jsr updateEnemyBullets
	jsr updateEnemies
	jsr dispenseEnemies
	ldx Main_currentPlayer
	jsr Score_tallyFrame;(x)
	jsr Player_isHit
	bcc @buildSprites
		ldx Main_currentPlayer
		dec Player_powerLevel,x
		bpl @decreaseHearts
			lda #0
			sta Player_powerLevel,x
	@decreaseHearts:
		lda #TRUE
		sta Player_haveHeartsChanged
		dec Player_hearts,x
		bpl @buildSprites
			lda #5;gameover code here
			sta Player_hearts,x
@buildSprites:
	jsr OAM_build;(c,a)
	jsr PPU_planNMI
	jsr PPU_waitForSprite0Hit
	lda Main_frame_L;see if the frame dropped
	cmp currentFrame
	beq :+
		inc framesDropped
:	lda #FALSE
	sta hasFrameBeenRendered
	jmp gameLoop

gameState01:
	;move the player to position, start showing HUD, Ready Go!
	jsr PPU_updateScroll
	;jsr Player_toStart
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
	inc Main_frame_L
	bne :+
		inc Main_frame_H
:
	lda PPU_willVRAMUpdate
	beq :+
		tsx
		stx Main_stack
		ldx PPU_stack
		txs
		rts
	;run all render code, return here
	Main_NMIReturn:
		ldx Main_stack
		txs
		lda #FALSE
		sta PPU_willVRAMUpdate
:
;oamdma transfer
	jsr OAM_beginDMA
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
Main_changeState:;void(a)
	sta Main_gameState
	jmp Main_resetClock

Main_resetClock:
	lda #0
	sta Main_frame_L
	sta Main_frame_H
	rts

Main_loadLevel:;(Main_currentScene, Main_currentPlayer)
	jsr disableRendering;()
	ldx Main_currentPlayer
	lda @playerPalette,x
	tax
	ldy #4
	jsr setPalette;(x,y)
	ldx #PURPLE_BULLET
	ldy #7
	jsr setPalette;(x,y)
	jsr Player_prepare
	ldx nextScene
	jsr setPaletteCollection;(x)
	ldx nextScene
	jsr Tiles_getScreenPointer
	jsr renderAllTiles;()
	jsr PPU_renderHUD
	jsr renderAllPalettes;()
	ldx nextScene
	jsr Waves_reset;(x)
	ldx nextScene
	jsr Speed_setLevel
	jsr OAM_initSprite0
	jsr PPU_resetScroll
	jsr enableRendering;()
	rts
@playerPalette:
	.byte PALETTE00

.segment "VECTORS"
.word nmi 	;jump here during vblank
.word main;jump here on reset

.segment "CHARS"
.incbin "graphics.chr"
