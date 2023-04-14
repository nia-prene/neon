.include "lib.h"
.include "main.h"

.include "scenes.h"
.include "shots.h"
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
.include "powerups.h"
.include "score.h"
.include "hud.h"
.include "apu.h"

.zeropage
Main_stack:	.res 1

.data
NMI_finished:	.res 1

.code
main:
	
	lda #GAMESTATE05
	jsr Gamestates_new

	jmp Gamestates_tick


nmi:
;save registers
	php
	pha
	txa
	pha
	tya
	pha
	
	inc NMI_finished

	lda PPU_bufferReady; 	if buffer is ready
	beq skipBuffer
		tsx
		stx Main_stack
		ldx PPU_stack
		txs

		rts
	;run all render code, return here
	Main_NMIReturn:
		ldx Main_stack
		txs
		lda #FALSE; frame is rendered
		sta PPU_bufferReady
skipBuffer:
	jsr OAM_beginDMA
	jsr PPU_setScroll
	jsr SFX_advance;tick sound effects
	jsr Song_advance;tick music
	

	pla; restore registers
	tay
	pla
	tax
	pla
	plp
	rti


NMI_wait:
	lda NMI_finished
	beq NMI_wait
	lda #FALSE
	sta NMI_finished

	rts


.segment "VECTORS"
.word nmi 	;jump here during vblank
.word main;jump here on reset

.segment "SPRITES"
.incbin "sprites.chr"
.segment "BACKGROUND"
.incbin "background.chr"
;.incbin "graphics.chr"
