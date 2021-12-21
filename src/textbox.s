.include "textbox.h"

.zeropage
t: .res 1
.code


Textbox_easeIn:;sprite0yPosition(void)
	clc
	lda t
	adc #1
	cmp #32
	bcc :+
		lda #31
	:
	sta t
	tax
	lda Textbox_ease,x
	rts

Textbox_easeOut:;sprite0yPosition(void)
	sec
	lda t
	sbc #1
	bcs :+
		lda #0
	:
	sta t
	tax
	lda Textbox_ease,x
	rts

.rodata
Textbox_ease:
	.byte 238, 220, 207, 195, 186, 179, 173, 169, 165, 162, 160, 158, 156, 155, 154, 153, 152, 152, 151, 151, 151, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150 
