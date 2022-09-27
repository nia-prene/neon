.include "gamestates.h"
.include "lib.h"

.include "main.h"
.include "scenes.h"
.include "shots.h"
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

Gamestates_last: .res 1
Gamestates_current: .res 1
Gamestates_next: .res 1
Gamestates_primary: .res 1

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
GAMESTATE09=$09; Level - charms spinning 
GAMESTATE0A=$0A; Level - player falling
GAMESTATE0B=$0B; Level - player recovering
GAMESTATE0C=$0C; Level - no enemies shooting
GAMESTATE0D=$0D; Level - Charms sucking
GAMESTATE0E=$0E; Level - Shots discharging

Gamestates_new:; void(a) |
	
	sta Gamestates_next

	rts

Gamestates_tick:
	
	inc g; increment iterator

	lda Gamestates_current; if state has changed
	cmp Gamestates_next
	beq @statePersists

		sta Gamestates_last; mark as previous state
		lda Gamestates_next
		sta Gamestates_current; change to new one
		
		lda #0; zero out the iterator
		sta g

@statePersists:

	rts


gamestate00:
;the main gameplay loop
	jsr PPU_updateScroll;void()
	jsr Score_clearFrameTally;void()
	
	lda Gamepads_state
	ldx Gamepads_last
	jsr Gamestates_pause; void(a,x) |
	
	jsr Player_setSpeed;(a)
	lda Gamepads_state
	jsr Player_move;(a)
	jsr Hitbox_tick

	jsr PlayerBullets_move;void()

	lda Gamepads_state
	ldx Gamepads_last
	jsr PlayerBullets_shoot; void(a,x) |
	

	jsr Bullets_tick
	jsr Enemies_tick
	jsr Waves_dispense


	ldy Gamepads_state
	ldx Gamepads_last
	jsr Bombs_toss ;c(a,x)
	bcc @noBomb

		lda #GAMESTATE09
		jsr Gamestates_new; a()

@noBomb:
	clc
	jsr Player_isHit
	bcc @playerUnharmed
		
		jsr Player_hit
		lda #GAMESTATE0A
		jsr Gamestates_new; void(a)

@playerUnharmed:

	jsr OAM_build00; void()
	
	
	;jsr PPU_waitForSprite0Hit
	
	jsr PPU_NMIPlan00; void() |
	jsr PPU_dimScreen; see how much frame is left over
	
	rts

gamestate01:;void(currentPlayer, currentScene)
;loads level with current player.

	jsr APU_setSong
	jsr disableRendering; ()
	
	ldx Main_currentPlayer
	lda @playerPalette,x
	tax
	ldy #4
	jsr setPalette; (x,y)
	ldx #PURPLE_BULLET
	ldy #7
	jsr setPalette; (x,y)

	ldx nextScene
	jsr setPaletteCollection; (x)

	ldx nextScene
	jsr PPU_renderScreen; void(x)

	jsr PPU_renderRightScreen

	ldx nextScene
	jsr Waves_new; (x)

	ldx nextScene
	
	jsr PPU_resetScroll
	jsr enableRendering;()

	lda #GAMESTATE02
	jsr Gamestates_new; void(a)
	jsr PPU_NMIPlan00; void() |
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
	;jsr PPU_waitForSprite0Reset;()
	jsr PPU_updateScroll
	lda #SCORE_OFFSET
	jsr Sprite0_setDestination;(a)
	jsr Player_toStartingPos
	jsr HUD_easeIn;a()
	jsr Sprite0_setSplit;(a)
	
	jsr PPU_NMIPlan00
	;jsr PPU_waitForSprite0Hit
	clc
	lda g
	cmp #64
	bne :+
		lda #GAMESTATE00 
		jsr Gamestates_new
:
	rts

gamestate04:
;hide HUD and move player into boss dialogue position
	jsr PPU_updateScroll
	;jsr PPU_waitForSprite0Reset;()
	jsr HUD_easeOut;a()
	jsr Sprite0_setSplit;(a)
	
	;jsr PPU_waitForSprite0Hit
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
	;jsr PPU_waitForSprite0Reset;()
	jsr PPU_updateScroll
	lda #TEXTBOX_OFFSET
	jsr Sprite0_setDestination;(a)
	jsr Textbox_easeIn;a()
	jsr Sprite0_setSplit;(a)
	jsr PPU_NMIPlan02
	;jsr PPU_waitForSprite0Hit
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
	;jsr PPU_waitForSprite0Reset;void()
	
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
gamestate08:; void()

	jsr PPU_dimScreen
	;jsr PPU_waitForSprite0Reset;void()

	lda Gamepads_state
	and #BUTTON_START;if start button pressed
	beq @stayPaused

		lda Gamepads_last;and not pressed last frame
		and #BUTTON_START
		bne @stayPaused

			lda Gamestates_last;resume game
			jsr Gamestates_new
		
			jsr APU_resumeMusic
			jsr APU_resumeSFX
@stayPaused:

	;jsr PPU_waitForSprite0Hit
	
	rts


gamestate09:; Level - charms spinning

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
	
	;jsr PPU_waitForSprite0Reset;()

	jsr Waves_dispense 
	jsr Enemies_tick
	
	jsr Charms_spin
	jsr Player_collectCharms
	
	ldx Main_currentPlayer
	jsr Score_tallyFrame;(x)
	
	lda g
	jsr OAM_build00; (a)
	
	jsr PPU_dimScreen
	;jsr PPU_waitForSprite0Hit
	jsr PPU_NMIPlan00

	lda g
	cmp #32
	bne @statePersists
		lda #GAMESTATE0D
		jsr	Gamestates_new
@statePersists:

	rts


gamestate0A:; falling off broom

	jsr PPU_updateScroll;void()
	jsr Score_clearFrameTally;void()
	
	lda Gamepads_state
	ldx Gamepads_last
	jsr Gamestates_pause;c(a,x) |

	jsr	Player_fall;void(a,f)

	jsr PlayerBullets_move;void()

	;jsr PPU_waitForSprite0Reset;()

	jsr Bullets_tick
	jsr Enemies_tick
	jsr Waves_dispense 

	ldx Main_currentPlayer
	jsr Score_tallyFrame; (x)

	jsr OAM_build00; (a)

	;jsr PPU_waitForSprite0Hit
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

	;jsr PPU_waitForSprite0Reset;()

	jsr Bullets_tick
	jsr Enemies_tick
	jsr Waves_dispense

	ldx Main_currentPlayer
	jsr Score_tallyFrame;(x)
	
	jsr OAM_build00;(c,a)
	
	;jsr PPU_waitForSprite0Hit
	
	jsr PPU_NMIPlan00
	
	rts


gamestate0C:; a moment of no shooting

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

	;jsr PPU_waitForSprite0Reset;()

	jsr Bullets_tick
	jsr Enemies_tick
	jsr Waves_dispense 

	ldx Main_currentPlayer
	jsr Score_tallyFrame;(x)
	
	jsr OAM_build00;(c,a)
	jsr PPU_dimScreen

	;jsr PPU_waitForSprite0Hit
	
	jsr PPU_NMIPlan00


	lda g
	cmp #128; frames
	bcc @statePersists
		lda Gamestates_primary
		jsr	Gamestates_new; void(a)
@statePersists:
	
	rts


gamestate0D:; charms spinning, main game loop

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
	
	;jsr PPU_waitForSprite0Reset;()

	jsr Waves_dispense 
	jsr Enemies_tick
	
	jsr Charms_suck; a,x(void)
	bne @charmsRemain
		lda Shots_charge; if accumulated a charge
		beq :+

			lda #GAMESTATE0E
			jsr Gamestates_new
			jmp @charmsRemain
		
		:lda #GAMESTATE00
		jsr Gamestates_new

@charmsRemain:
	jsr Player_collectCharms
	
	ldx Main_currentPlayer
	jsr Score_tallyFrame;(x)
	
	jsr OAM_build00; (a)
	
	jsr PPU_dimScreen
	;jsr PPU_waitForSprite0Hit
	jsr PPU_NMIPlan00


	rts


Gamestate0E:
;player discharging beam
	jsr PPU_updateScroll;void()
	jsr Score_clearFrameTally;void()
	
	lda Gamepads_state
	ldx Gamepads_last
	jsr Gamestates_pause; void(a,x) |

	lda Gamepads_state
	jsr Player_move;(a)

	jsr PlayerBullets_move;void()

	lda Gamepads_state
	jsr Shots_discharge;c(a)
	bne :+
		lda #GAMESTATE00
		jsr Gamestates_new
	:
	
	jsr Bullets_tick
	jsr Enemies_tick
	jsr Waves_dispense

	ldy Gamepads_state
	ldx Gamepads_last
	
	jsr Player_isHit
	bcc @playerUnharmed
		
		jsr Player_hit
		lda #GAMESTATE0A
		jsr Gamestates_new; void(a)

@playerUnharmed:

	jsr OAM_build00; void()
	
	
	jsr PPU_dimScreen; see how much frame is left over
	;jsr PPU_waitForSprite0Hit
	
	jsr PPU_NMIPlan00; void() |
	
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
	.byte >(gamestate00-1),>(gamestate01-1),>(gamestate02-1),>(gamestate03-1),>(gamestate04-1),>(gamestate05-1),>(gamestate06-1),>(gamestate07-1),>(gamestate08-1),>(gamestate09-1),>(gamestate0A-1),>(gamestate0B-1),>(gamestate0C-1),>(gamestate0D-1),>(Gamestate0E-1)
Gamestates_L:
	.byte <(gamestate00-1),<(gamestate01-1),<(gamestate02-1),<(gamestate03-1),<(gamestate04-1),<(gamestate05-1),<(gamestate06-1),<(gamestate07-1),<(gamestate08-1),<(gamestate09-1),<(gamestate0A-1),<(gamestate0B-1),<(gamestate0C-1),<(gamestate0D-1),<(Gamestate0E-1)
