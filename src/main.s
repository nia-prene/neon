.include "lib.h"
.include "main.h"

.include "scenes.h"
.include "playerbullets.h"
.include "gamestates.h"
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
.include "apu.h"

.zeropage
Main_stack: .res 1
currentFrame: .res 1
hasFrameBeenRendered: .res 1
framesDropped: .res 1
Main_frame_L: .res 1

.code
main:
	NES_init
	jsr PPU_init
;player 0 starts
	lda #0
	sta Main_currentPlayer
;there is no frame that needs renderso set to TRUE
	lda #1
	sta Gamestate_current
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
	lda Main_frame_L;save this frame to start the hold process
	pha
gameLoop:
	pla
@hold:
	cmp Main_frame_L;hold here until nmi updates frame
	beq @hold
	lda Main_frame_L;get the frame for next loop
	pha
	lda #>(@endOfFrameHousekeeping-1)
	pha
	lda #<(@endOfFrameHousekeeping-1)
	pha
	ldy Gamestate_current
	lda Gamestates_H,y
	pha
	lda Gamestates_L,y
	pha
	rts
@endOfFrameHousekeeping:
	pla;grab the current frame off stack
	cmp Main_frame_L
	beq :+;see if the frame was dropped
		inc framesDropped
:	pha;save frame for @hold
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

.segment "VECTORS"
.word nmi 	;jump here during vblank
.word main;jump here on reset

.segment "CHARS"
.incbin "graphics.chr"
