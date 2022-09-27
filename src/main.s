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
.include "pickups.h"
.include "score.h"
.include "hud.h"
.include "init.s"
.include "apu.h"

.zeropage
Main_stack: .res 1
hasFrameBeenRendered: .res 1
framesDropped: .res 1
Main_frame_L: .res 1
Main_frameFinished: .res 1


.code
main:
	NES_init
	jsr PPU_init
	jsr Players_init
	jsr APU_init
	
	lda #GAMESTATE01
	jsr Gamestates_new

	lda #FALSE
	sta Main_frameFinished

@gameLoop:

	
	lda Main_frameFinished;hold here until nmi updates frame
	bne @gameLoop
	
	lda #>(@endOfFrameHousekeeping-1)
	pha
	lda #<(@endOfFrameHousekeeping-1)
	pha

	jsr Gamestates_tick
	ldy Gamestates_current
	lda Gamestates_H,y
	pha
	lda Gamestates_L,y
	pha
	rts
@endOfFrameHousekeeping:
	lda #TRUE
	sta Main_frameFinished
	jmp @gameLoop


nmi:
;save registers
	php
	pha
	txa
	pha
	tya
	pha
	
	inc Main_frame_L

	lda Main_frameFinished; if frame is finished
	beq :+; else no graphic update

		lda #FALSE; frame is rendered
		sta Main_frameFinished

		tsx
		stx Main_stack
		ldx PPU_stack
		txs

		rts
	;run all render code, return here
	Main_NMIReturn:
		ldx Main_stack
		txs
		jsr OAM_beginDMA

:
	
	jsr PPU_setScroll
	jsr SFX_advance;tick sound effects
	jsr Song_advance;tick music
	

	ldx Player_current
	jsr Gamepads_read

	pla; restore registers
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
