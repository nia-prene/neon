.include "hud.h"
.include "lib.h"

.include "oam.h"

.zeropage
h: .res 1
.code
HUD_easeIn:;sprite0yPosition(void)
	clc
	lda h
	adc #1
	cmp #32
	bcc :+
		lda #31
	:
	sta h
	tax
	lda HUD_ease,x
	rts

HUD_easeOut:;sprite0yPosition(void)
	sec
	lda h
	sbc #1
	bcs :+
		lda #0
	:
	sta h
	tax
	lda HUD_ease,x
	rts

.rodata
HUD_ease:
.byte 238, 234, 230, 228, 226, 224, 223, 222, 221, 220, 220, 219, 219, 219, 218, 218, 218, 218, 218, 218, 218, 218, 218, 218, 218, 218, 218, 218, 218, 218, 218, 218 
