.include 	"gamestates.h"
.include	"lib.h"

.include 	"apu.h"
.include 	"bombs.h"
.include	"bullets.h"
.include	"enemies.h"
.include	"effects.h"
.include	"gamepads.h"
.include	"header.s"
.include	"hud.h"
.include	"main.h"
.include	"oam.h"
.include	"palettes.h"
.include	"patterns.h"
.include	"powerups.h"
.include	"player.h"
.include	"ppu.h"
.include	"scenes.h"
.include	"score.h"
.include	"shots.h"
.include	"sprites.h"
.include	"textbox.h"
.include	"tiles.h"
.include	"waves.h"

.zeropage

Gamestates_last: .res 1
Gamestates_current: .res 1
Gamestates_next: .res 1
Gamestates_primary: .res 1

currentScene: .res 1
nextScene: .res 1
Main_currentPlayer: .res 1
Gamestates_clock:.res 1


.code
GAMESTATE00=$00; main game loop
GAMESTATE01=$01; loading a level
GAMESTATE02=$02; fade in screen while scroll
GAMESTATE03=$03; move player to start pos, ease in status bar
GAMESTATE04=$04; ease out status bar, move player to dialogue spt
GAMESTATE05=$05; available
GAMESTATE06=$06; fade out screen while scroll
GAMESTATE07=$07; music test state
GAMESTATE08=$08; game pause
GAMESTATE09=$09; charms spinning 
GAMESTATE0A=$0A; player falling
GAMESTATE0B=$0B; player recovering
GAMESTATE0C=$0C; available
GAMESTATE0D=$0D; Charms sucking
GAMESTATE0E=$0E; available

Gamestates_new:;	void(a) |
	
	sta Gamestates_next
	rts


Gamestates_tick:;	void()
	

	inc Gamestates_clock;			increment iterator

	lda Gamestates_current;		if state has changed
	cmp Gamestates_next
	beq :+
		lda #0; 	zero out the iterator
		sta Gamestates_clock

		lda Gamestates_current;	current is now last
		sta Gamestates_last
		lda Gamestates_next;	the next will now be current
		sta Gamestates_current
	:
	tay;			load current state
	lda Gamestates_L,y
	sta Lib_ptr0+0
	lda Gamestates_H,y
	sta Lib_ptr0+1
	jmp (Lib_ptr0);		play the game in that state


gamestate00:

	jsr PPU_updateScroll;		void()	adjust the scroll first
	jsr Score_clearFrameTally;	void()	clear it for this frame
	jsr PlayerBullets_move;		void()
	jsr Bullets_tick
	jsr Powerups_tick
	
	jsr NMI_wait;			wait til player sees last frame
	jsr Gamepads_read;		read the gamepads
	
	jsr Player_setSpeed;		adjust player speed
	jsr Player_move;		move the player
	jsr Hitbox_tick;		adjust the hitbox
	jsr PlayerBullets_shoot; 	void(a,x) |
	
	jsr Enemies_tick;		void() | 
	jsr Waves_dispense;		void() | 
	jsr Effects_tick;		void() | 

	jsr Bombs_toss ;		c(a,x) |	see if bomb	
	bcc :+;				if player dropped the bomb
		lda #GAMESTATE09;	change gamestates
		jsr Gamestates_new; a()
	:
	jsr Powerups_collect;	void() |	collect powerups
	jsr Player_isHit;	c() | 		if player is hit
	bcc :+
		lda #GAMESTATE0A;		change gamestate
		jsr Gamestates_new; void(a)
	:
	jsr OAM_build00; 	void()		draw sprites
	jsr PPU_NMIPlan00; void() |
	
	jsr Score_tallyFrame; 		void()	total this frame
	
	jmp Gamestates_tick


gamestate01:;void(currentPlayer, currentScene)
;loads level with current player.
	jsr PPU_init
	jsr Players_init
	jsr Score_clear
	jsr APU_init

	jsr APU_setSong
	jsr NMI_wait;		void() |	wait for next nmi
	jsr disableRendering; 	void() |	before turning off screen

	ldx #0
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

	jsr PPU_resetScroll
	jsr NMI_wait;		void() |	wait for next nmi
	jsr enableRendering;	void() |	before turning on screen

	lda #GAMESTATE02;	change the gamestate
	jsr Gamestates_new; 	void(a) |
	jmp Gamestates_tick


gamestate02:
;fade in screen
	jsr NMI_wait
	jsr PPU_updateScroll
	
	lda Gamestates_clock
	jsr PPU_NMIPlan01;(a)
	
	lda Gamestates_clock
	cmp #%11000
	bne :+
		lda #GAMESTATE03
		jsr Gamestates_new
	:
	jmp Gamestates_tick


gamestate03:
SCORE_OFFSET=7
;move player into place, show status, ready? Go!
	jsr PPU_updateScroll
	jsr PlayerBullets_move;void()

	jsr OAM_initSprite0
	lda #SCORE_OFFSET
	jsr Sprite0_setDestination;(a)
	jsr HUD_easeIn; a()
	jsr Sprite0_setSplit; void(a)
	
	jsr NMI_wait;			wait til player sees last frame
	lda Gamestates_clock
	jsr Player_toStartingPos; void(a)
	jsr Gamepads_read
	jsr Player_setSpeed;(a)
	jsr Player_move;(a)
	jsr Hitbox_tick
	jsr PlayerBullets_shoot; void(a,x) |
	
	jsr OAM_build00
	jsr PPU_NMIPlan00
	
	lda Gamestates_clock; if 0
	beq :+
		jsr PPU_waitForSprite0Hit;	else wait for hit
	:
	lda Gamestates_clock 
	cmp #128
	bne :+
		lda #GAMESTATE04 
		jsr Gamestates_new
	:
	jmp Gamestates_tick


gamestate04:
;hide HUD and allow player to move before level todo ready go
	jsr PPU_updateScroll
	jsr PlayerBullets_move;void()
	
	jsr HUD_easeOut;a()
	jsr Sprite0_setSplit;(a)
	
	jsr NMI_wait
	
	jsr Gamepads_read
	jsr Player_setSpeed;(a)
	jsr Player_move;(a)
	jsr Hitbox_tick
	jsr PlayerBullets_shoot;(a)
	
	jsr OAM_build00
	jsr PPU_NMIPlan00

	clc
	lda Gamestates_clock
	cmp #64
	bcc :+
		lda #GAMESTATE00
		jsr Gamestates_new
	:	
	jsr PPU_waitForSprite0Hit
	jmp Gamestates_tick

gamestate05:

gamestate06:
;fades screen out and updates scroll
	jsr NMI_wait
	jsr PPU_updateScroll
	lda Gamestates_clock
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
	jmp Gamestates_tick

gamestate07:


gamestate08:; void()
	jsr NMI_wait

	jsr PPU_dimScreen
	;jsr PPU_waitForSprite0Reset;void()
	
	jsr Gamepads_read
	lda Gamepads_state
	and #BUTTON_START;if start button pressed
	beq @stayPaused

		lda Gamepads_last;and not pressed last frame
		and #BUTTON_START
		bne @stayPaused

			lda Gamestates_last;resume game
			jsr Gamestates_new
			
			lda Gamestates_last
			sta Gamestates_clock
			jsr APU_resumeMusic
			jsr APU_resumeSFX
@stayPaused:

	;jsr PPU_waitForSprite0Hit
	
	jmp Gamestates_tick


gamestate09:; Level - charms spinning
	
	jsr PPU_updateScroll;void()
	jsr Score_clearFrameTally;	void() |	clear frame score
	jsr Powerups_tick;		void() | 	move powerups
	jsr PlayerBullets_move;void()
	jsr Charms_spin
	
	jsr NMI_wait
	
	jsr OAM_initSprite0;	turn on sprite 0
	lda #SCORE_OFFSET
	jsr Sprite0_setDestination;(a)
	jsr HUD_easeIn;		a()
	jsr Sprite0_setSplit;	void(a)

	jsr Gamepads_read
	jsr Player_setSpeed;(a)
	jsr Player_move;(a)
	jsr Hitbox_tick
	jsr PlayerBullets_shoot;(a)
	
	;jsr PPU_waitForSprite0Reset;()

	jsr Waves_dispense 
	jsr Enemies_tick
	jsr Effects_tick;		void() | 
	
	jsr Powerups_collect;		void() |	collect powerups
	jsr Player_collectCharms
	
	jsr OAM_build00
	jsr PPU_NMIPlan00
	
	jsr Score_tallyFrame;		void() |	total score

	lda Gamestates_clock
	beq :+
		jsr PPU_waitForSprite0Hit
		lda Gamestates_clock
	:
	cmp #32
	bne @statePersists
		lda #GAMESTATE0D
		jsr Gamestates_new
@statePersists:

	jmp Gamestates_tick


gamestate0A:; falling off broom
	jsr PPU_updateScroll
	jsr Powerups_tick
	jsr Score_clearFrameTally;void()
	jsr Bullets_tick
	jsr PlayerBullets_move;void()
	
	jsr NMI_wait

	jsr OAM_initSprite0; set up hit
	lda #SCORE_OFFSET
	jsr Sprite0_setDestination;(a)
	jsr HUD_easeIn;a()
	jsr Sprite0_setSplit;(a)
	
	lda Gamestates_clock
	jsr Player_fall;void(a)

	jsr Enemies_tick
	jsr Effects_tick;		void() | 
	jsr Waves_dispense 

	jsr Score_tallyFrame

	jsr OAM_build00; (a)
	jsr PPU_NMIPlan00
	
	lda Gamestates_clock;		if not zero (not first frame)
	beq :+;		else if
		jsr PPU_waitForSprite0Hit;	do sprite 0 split
	:
	lda Gamestates_clock;	recall clock
	cmp #64
	bne:+
		jsr Player_hit; 	detract heart
	:
	lda Gamestates_clock;	recall clock
	cmp #128;	if 128
	bne :+
		lda #GAMESTATE0B;	load recovery state
		jsr Gamestates_new;	change states
	:
	jmp Gamestates_tick


gamestate0B:; recovering from fall

	jsr PPU_updateScroll;void()
	jsr Powerups_tick
	jsr Score_clearFrameTally;void()
	jsr PlayerBullets_move;	void()
	jsr Bullets_tick
	
	jsr NMI_wait

	jsr OAM_initSprite0
	jsr HUD_easeOut;a()
	jsr Sprite0_setSplit;(a)
	
	jsr Gamepads_read
	lda Gamestates_clock
	jsr Player_recover;c(a,f)
	jsr Player_setSpeed;(a)
	jsr Player_move;(a)
	jsr Hitbox_tick
	jsr PlayerBullets_shoot; void(a,x) |
	lda Gamestates_clock
	jsr Player_flicker;	void(a) |	flicker the player

	jsr Enemies_tick
	jsr Powerups_collect;		void() |	collect powerups
	jsr Effects_tick;		void() | 
	jsr Waves_dispense
	
	jsr OAM_build00;(c,a)
	jsr PPU_NMIPlan00
	
	jsr Score_tallyFrame;(x)

	lda Gamestates_clock
	cmp #128
	bcc :+
		lda #GAMESTATE00
		jsr Gamestates_new
	:
	jsr PPU_waitForSprite0Hit
	jmp Gamestates_tick


gamestate0C:; a moment of no shooting


gamestate0D:

	jsr PPU_updateScroll;void()
	jsr Score_clearFrameTally;void()
	jsr PlayerBullets_move;void()
	jsr Charms_suck; a,x(void)
	
	jsr NMI_wait

	jsr Gamepads_read
	jsr Player_setSpeed;(a)
	jsr Player_move;(a)
	jsr Hitbox_tick
	jsr PlayerBullets_shoot;(a)
	jsr Player_collectCharms
	jsr Powerups_collect;		void() |	collect powerups
	
	jsr Enemies_tick
	jsr Waves_dispense 
	jsr Effects_tick;		void() | 
	
	jsr OAM_build00; (a)
	jsr PPU_NMIPlan00
	
	jsr Score_tallyFrame;

	lda Gamestates_clock;		if 
	cmp #128-32
	bcc :+
		jsr HUD_easeOut;	a()		ease the HUD out
		jsr Sprite0_setSplit;	void(a)		set the split
		lda Gamestates_clock
	:
	cmp #128
	bne :+
		lda #GAMESTATE00
		jsr Gamestates_new
	:
	jsr PPU_waitForSprite0Hit
	jmp Gamestates_tick


Gamestate0E:


Gamestates_pause:;c(a,x) |
	jsr NMI_wait
	
	lda Gamepads_state
	and #BUTTON_START;if start button pressed
	beq :+
		lda Gamepads_last
		and #BUTTON_START; and not pressed last frame
		bne :+
			lda #GAMESTATE08;pause game
			jsr Gamestates_new
			jsr APU_pauseMusic; silence the music
			jsr APU_pauseSFX; silence the SFX
	:
	rts

Gamestates_H:
	.byte >gamestate00,>gamestate01,>gamestate02,>gamestate03
	.byte >gamestate04,>gamestate05,>gamestate06,>gamestate07
	.byte >gamestate08,>gamestate09,>gamestate0A,>gamestate0B
	.byte >gamestate0C,>gamestate0D,>Gamestate0E
Gamestates_L:
	.byte <gamestate00,<gamestate01,<gamestate02,<gamestate03
	.byte <gamestate04,<gamestate05,<gamestate06,<gamestate07
	.byte <gamestate08,<gamestate09,<gamestate0A,<gamestate0B
	.byte <gamestate0C,<gamestate0D,<Gamestate0E
