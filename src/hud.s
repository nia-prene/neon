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
	.byte 238, 231, 226, 222, 219, 216, 214, 212 
	.byte 211, 210, 209, 208, 208, 207, 207, 207
	.byte 206, 206, 206, 206, 206, 206, 206, 206
	.byte 206, 206, 206, 206, 206, 206, 206, 206
