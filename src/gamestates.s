.include "gamestates.h"
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
.include "textbox.h"
.include "apu.h"


.zeropage
Gamestate_current: .res 1
currentScene: .res 1
nextScene: .res 1
Main_currentPlayer: .res 1
g:.res 1

.code
GAMESTATE00=$00;main game loop
GAMESTATE01=$01;loading a level
GAMESTATE02=$02;fade in screen while scroll
GAMESTATE03=$03;move player to start pos, ease in status bar
GAMESTATE04=$04;ease out status bar, move player to dialogue spt
GAMESTATE05=$05;ease in textbox, move player/boss to dialogue spt
GAMESTATE06=$06;fade out screen while scroll
GAMESTATE07=$07;music test state

Gamestates_H:
	.byte >(gamestate00-1), >(gamestate01-1), >(gamestate02-1), >(gamestate03-1), >(gamestate04-1), >(gamestate05-1), >(gamestate06-1), >(gamestate07-1)
Gamestates_L:
	.byte <(gamestate00-1), <(gamestate01-1), <(gamestate02-1), <(gamestate03-1), <(gamestate04-1), <(gamestate05-1), <(gamestate06-1), <(gamestate07-1)

gamestate00:
;the main gameplay loop
	jsr PPU_updateScroll
	jsr Gamepads_read
;if player is hoding A B SEL ST, reset the game
	lda Gamepads_state
	and #%11110000
	cmp #%11110000
	;bne :+
		;do reset
;:
	jsr Score_clearFrameTally
	lda Gamepads_state
	jsr Player_move;(a)
	jsr PlayerBullets_move
	lda Gamepads_state
	jsr PlayerBullets_shoot;(a)
	jsr PPU_waitForSprite0Reset;()
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
	jsr PPU_waitForSprite0Hit
	jsr PPU_NMIPlan00
	rts

gamestate01:;void(currentPlayer, currentScene)
;loads level with current player.
	jsr APU_init
	jsr APU_setSong
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
	jsr PPU_renderRightScreen
	ldx nextScene
	jsr Waves_reset;(x)
	ldx nextScene
	jsr Speed_setLevel
	jsr OAM_initSprite0
	jsr PPU_resetScroll
	jsr enableRendering;()
	lda #GAMESTATE02
	sta Gamestate_current
	lda #00
	sta g
	rts
@playerPalette:
	.byte PALETTE00

gamestate02:
;fade in screen
	jsr PPU_updateScroll
	lda g
	clc
	adc #8
	sta g
	bne :+
		lda #GAMESTATE07
		sta Gamestate_current
		rts
:	clc
	and #%11000000
	rol
	rol
	rol
	tay
	jsr PPU_NMIPlan01;(y)
	rts

gamestate03:
SCORE_OFFSET=7
;move player into place, show status, ready? Go!
	jsr PPU_waitForSprite0Reset;()
	jsr PPU_updateScroll
	lda #SCORE_OFFSET
	jsr Sprite0_setDestination;(a)
	jsr Player_toStartingPos
	jsr HUD_easeIn;a()
	jsr Sprite0_setSplit;(a)
	ldx #4;skip sprite0
	jsr OAM_buildPlayer;(x)
	jsr OAM_clearRemaining;(x)
	jsr PPU_NMIPlan00
	jsr PPU_waitForSprite0Hit
	lda g
	adc #4;this state lasts 256/4 frames
	sta g
	bne :+
		lda #GAMESTATE00
		sta Gamestate_current
:
	rts

gamestate04:
;hide HUD and move player into boss dialogue position
	jsr PPU_updateScroll
	jsr PPU_waitForSprite0Reset;()
	jsr Player_toConvo
	jsr HUD_easeOut;a()
	jsr Sprite0_setSplit;(a)
	ldx #4;skip sprite0
	jsr OAM_buildPlayer;x(x)
	jsr OAM_clearRemaining;(x)
	jsr PPU_waitForSprite0Hit
	clc
	lda g
	adc #8
	sta g
	bne :+
		lda #GAMESTATE05
		sta Gamestate_current
:	rts

gamestate05:
TEXTBOX_OFFSET=30
;load and show textbox and move boss into view
	lda #0
	sta Portraits_current
	lda #1
	sta Portraits_hasChanged
	ldy #3
	ldx #PALETTE0A
	jsr setPalette
	jsr PPU_waitForSprite0Reset;()
	jsr PPU_updateScroll
	jsr Player_toConvo
	lda #TEXTBOX_OFFSET
	jsr Sprite0_setDestination;(a)
	jsr Textbox_easeIn;a()
	jsr Sprite0_setSplit;(a)
	jsr PPU_NMIPlan02
	ldx #4;skip sprite0
	jsr OAM_buildPlayer;(x)
	jsr OAM_clearRemaining;(x)
	jsr PPU_waitForSprite0Hit
	rts

gamestate06:
;fades screen out and updates scroll
	jsr PPU_updateScroll
	lda g
	clc
	adc #8
	sta g
	bne :+
		lda #GAMESTATE02
		sta Gamestate_current
		rts
:	clc
	and #%11000000
	rol
	rol
	rol
	tay
	jsr PPU_NMIPlan03;(y)
	rts

gamestate07:
	jsr PPU_updateScroll
	jsr APU_advance 
	rts