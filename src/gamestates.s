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
.include "textbox.h"
.include "apu.h"
.include "bombs.h"
.include "hud.h"
.include "patterns.h"

.zeropage
Gamestates_current: .res 1
Gamestates_next: .res 1

currentScene: .res 1
nextScene: .res 1
Main_currentPlayer: .res 1
g:.res 1

.code
GAMESTATE00=$00; main game loop
GAMESTATE01=$01; loading a level
GAMESTATE02=$02; fade in screen while scroll
GAMESTATE03=$03; move player to start pos, ease in status bar
GAMESTATE04=$04; ease out status bar, move player to dialogue spt
GAMESTATE05=$05; ease in textbox, move player/boss to dialogue spt
GAMESTATE06=$06; fade out screen while scroll
GAMESTATE07=$07; music test state
GAMESTATE08=$08; game pause
GAMESTATE09=$09; post bomb
GAMESTATE0A=$0A; player is falling after hit
GAMESTATE0B=$0B; player recovering after hit
GAMESTATE0C=$0C; time period of no enemy shooting

Gamestates_new:; void(a) |
	
	sta Gamestates_next

	rts

Gamestates_tick:
	
	inc g
	lda Gamestates_next
	cmp Gamestates_current
	beq @statePersists
		sta Gamestates_current
		lda #0
		sta g
@statePersists:
	rts

gamestate00:
;the main gameplay loop
	jsr PPU_updateScroll;void()
	jsr Score_clearFrameTally;void()
	
	lda Gamepads_state
	ldx Gamepads_last;and not pressed last frame
	jsr Gamestates_pause; void(a,x) |

	lda Gamepads_state
	jsr Player_move;(a)

	jsr PlayerBullets_move;void()

	lda Gamepads_state
	jsr PlayerBullets_shoot;(a)
	
	jsr PPU_waitForSprite0Reset;()

	jsr dispenseEnemies
	jsr updateEnemies

	jsr updateEnemyBullets
	jsr Patterns_tick

	ldy Gamepads_state
	ldx Gamepads_last
	jsr	Bombs_toss ;c(a,x)
	bcc @noBomb
		lda #GAMESTATE09
		jsr Gamestates_new; a()
@noBomb:
	
	jsr Player_isHit
	bcc @playerUnharmed
		
		jsr Player_hit
		lda #GAMESTATE0A
		jsr Gamestates_new; void(a)
@playerUnharmed:

	lda g
	jsr OAM_build00; c(a) |
	
	ldx Main_currentPlayer
	jsr Score_tallyFrame;(x)
	
	jsr PPU_dimScreen; see how much frame is left over
	jsr PPU_waitForSprite0Hit
	
	jsr PPU_NMIPlan00; void() |
	
	rts

gamestate01:;void(currentPlayer, currentScene)
;loads level with current player.
	jsr APU_init

	jsr APU_setSong
	jsr disableRendering; ()
	ldx #0
	jsr OAM_clearRemaining; (x)
	ldx Main_currentPlayer
	lda @playerPalette,x
	tax
	ldy #4
	jsr setPalette; (x,y)
	ldx #PURPLE_BULLET
	ldy #7
	jsr setPalette; (x,y)

	jsr Player_prepare
	jsr Bombs_init

	ldx nextScene
	jsr setPaletteCollection; (x)

	ldx nextScene
	jsr Tiles_getScreenPointer; (x)

	jsr renderAllTiles; ()
	jsr PPU_renderRightScreen

	ldx nextScene
	jsr Waves_new; (x)

	ldx nextScene
	jsr OAM_initSprite0
	jsr PPU_resetScroll
	jsr enableRendering;()

	lda #GAMESTATE02
	jsr Gamestates_new; void(a)
	rts

@playerPalette:
	.byte PALETTE00

gamestate02:
;fade in screen
	jsr PPU_updateScroll
	lda g
	eor #%11000
	bne @statePersists

		lda #GAMESTATE03
		jsr Gamestates_new

@statePersists:
	lda g
	jsr PPU_NMIPlan01;(a)
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
	clc
	lda g
	adc #2;this state lasts 256/4 frames
	sta g
	bne :+
		lda #GAMESTATE00 
		jsr Gamestates_new
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
		jsr Gamestates_new
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
		jmp Gamestates_new
:	clc
	and #%11000000
	rol
	rol
	rol
	tay
	jsr PPU_NMIPlan03;void(y)
	rts

gamestate07:
	jsr PPU_updateScroll;void()
	jsr PPU_waitForSprite0Reset;void()
	
	lda Gamepads_state
	and #BUTTON_START; if pressing start
	beq @dontToggleMusic
		lda Gamepads_last; and first frame of pressing start
		and #BUTTON_START
		bne @dontToggleMusic
			lda g
			and #%1
			bne @turnOn
				eor #%1
				sta g
				jsr APU_pauseMusic; silence the music
				rts
			@turnOn:
				eor #%1
				sta g
				jsr APU_resumeMusic;
				rts
@dontToggleMusic:

	lda Gamepads_state
	and #BUTTON_A
	beq @dontPlaySFX
		lda Gamepads_last
		and #BUTTON_A
		bne @dontPlaySFX
			lda #SFX06
			jsr SFX_newEffect
			lda #SFX07
			jsr SFX_newEffect
			lda #SFX08
			jsr SFX_newEffect
@dontPlaySFX:
	rts


; game paused state
gamestate08:

	jsr PPU_dimScreen
	jsr PPU_waitForSprite0Reset;void()

	lda Gamepads_state
	and #BUTTON_START;if start button pressed
	beq @stayPaused

		lda Gamepads_last;and not pressed last frame
		and #BUTTON_START
		bne @stayPaused

			lda #GAMESTATE00;resume game
			jsr Gamestates_new
		
			jsr APU_resumeMusic
			jsr APU_resumeSFX
@stayPaused:

	ldx #4
	jsr OAM_buildPause;x(x)
	jsr OAM_clearRemaining;x()
	jsr PPU_waitForSprite0Hit
	rts

gamestate09:; after a bomb goes off

	jsr PPU_updateScroll;void()
	jsr Score_clearFrameTally;void()
	
	lda Gamepads_state
	ldx Gamepads_last
	jsr Gamestates_pause

	lda Gamepads_state
	jsr Player_move;(a)

	jsr PlayerBullets_move;void()

	lda Gamepads_state
	jsr PlayerBullets_shoot;(a)
	
	jsr PPU_waitForSprite0Reset;()

	jsr dispenseEnemies
	jsr updateEnemies
	jsr Charms_tick
	
	jsr Player_collectCharms
	
	ldx Main_currentPlayer
	jsr Score_tallyFrame;(x)
	
	lda g
	jsr OAM_build00; (a)
	
	jsr PPU_dimScreen
	jsr PPU_waitForSprite0Hit
	jsr PPU_NMIPlan00

	jsr	Charms_getActive; a()
	bne @statePersists

		lda #GAMESTATE0C; go to brief firing hold 
		jsr Gamestates_new

@statePersists:

	rts


gamestate0A:; falling off broom

	jsr PPU_updateScroll;void()
	jsr Score_clearFrameTally;void()
	
	lda Gamepads_state
	ldx Gamepads_last
	jsr Gamestates_pause;c(a,x) |

	lda g
	jsr	Player_fall;void(a,f)
	jsr PlayerBullets_move;void()

	jsr PPU_waitForSprite0Reset;()

	jsr dispenseEnemies
	jsr updateEnemies
	jsr updateEnemyBullets

	ldx Main_currentPlayer
	jsr Score_tallyFrame; (x)

	jsr OAM_build00; (a)

	jsr PPU_waitForSprite0Hit
	jsr PPU_NMIPlan00

	lda g
	rol
	rol
	rol;if frames >= 32
	bcc @statePersists
		lda #GAMESTATE0B; load recovery state
		jsr Gamestates_new
@statePersists:
	rts


gamestate0B:; recovering from fall

	jsr PPU_updateScroll;void()
	jsr Score_clearFrameTally;void()
	
	lda Gamepads_state
	ldx Gamepads_last
	jsr Gamestates_pause;c(a,x) |
	
	lda g
	jsr	Player_recover;c(a,f)
	bcc @stillRecovering
		lda #GAMESTATE0C
		jsr Gamestates_new
@stillRecovering:

	jsr PlayerBullets_move;void()

	jsr PPU_waitForSprite0Reset;()

	jsr dispenseEnemies
	jsr updateEnemies
	jsr updateEnemyBullets

	ldx Main_currentPlayer
	jsr Score_tallyFrame;(x)
	
	jsr OAM_build00;(c,a)
	
	jsr PPU_waitForSprite0Hit
	
	jsr PPU_NMIPlan00
	
	rts


gamestate0C:; a moment of no enemy shooting

	jsr PPU_updateScroll;void()
	jsr Score_clearFrameTally;void()
	
	lda Gamepads_state
	ldx Gamepads_last
	jsr Gamestates_pause;c(a,x) |
	
	lda Gamepads_state
	jsr	Player_move;void(a) |

	jsr PlayerBullets_move;void()

	lda Gamepads_state
	jsr PlayerBullets_shoot;(a)

	jsr PPU_waitForSprite0Reset;()

	jsr dispenseEnemies
	jsr updateEnemies
	jsr updateEnemyBullets

	ldx Main_currentPlayer
	jsr Score_tallyFrame;(x)
	
	jsr OAM_build00;(c,a)
	
	jsr PPU_waitForSprite0Hit
	
	jsr PPU_NMIPlan00

	lda g
	cmp #128; frames
	bcc @statePersists
		lda #GAMESTATE00
		jsr	Gamestates_new
@statePersists:
	
	rts

Gamestates_pause:;c(a,x) |

	and #BUTTON_START;if start button pressed
	beq @noPause
		txa;  
		and #BUTTON_START; and not pressed last frame
		bne @noPause
			lda #GAMESTATE08;pause game
			jsr Gamestates_new
			jsr APU_pauseMusic; silence the music
			jsr APU_pauseSFX; silence the SFX
@noPause:

	rts


Gamestates_H:
	.byte >(gamestate00-1), >(gamestate01-1), >(gamestate02-1), >(gamestate03-1), >(gamestate04-1), >(gamestate05-1), >(gamestate06-1), >(gamestate07-1), >(gamestate08-1), >(gamestate09-1), >(gamestate0A-1), >(gamestate0B-1), >(gamestate0C-1)
Gamestates_L:
	.byte <(gamestate00-1), <(gamestate01-1), <(gamestate02-1), <(gamestate03-1), <(gamestate04-1), <(gamestate05-1), <(gamestate06-1), <(gamestate07-1), <(gamestate08-1), <(gamestate09-1), <(gamestate0A-1), <(gamestate0B-1), <(gamestate0C-1)
