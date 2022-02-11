.include "score.h"
.include "lib.h"
.include "sprites.h"

SCORE_DIGITS=7
.zeropage
Score_ones: .res 2
Score_tens: .res 2
Score_hundreds: .res 2
Score_thousands: .res 2
Score_tenThousands: .res 2
Score_hundredThousands: .res 2
Score_millions: .res 2
Score_multiplier: .res 2
Score_frameTotal_L: .res 1
Score_frameTotal_H: .res 1
Score_hasChanged: .res 1
;locals
;these convert bin to dec
DecOnes: .res 1
DecTens: .res 1
DecHundreds: .res 1
DecThousands: .res 1
DecTenThousands: .res 1
.data

.code
Score_clear:
;arguments -
;x - player score to clear
	lda #0
	sta Score_ones,x
	sta Score_tens,x
	sta Score_hundreds,x
	sta Score_thousands,x
	sta Score_tenThousands,x
	sta Score_hundredThousands,x
	sta Score_millions,x
	sta Score_multiplier,x
	lda #TRUE
	sta Score_hasChanged
	rts

Score_clearFrameTally:;void(void)
;call at beginning of frame to zero out score total
	lda #0
	sta Score_frameTotal_L
	sta Score_frameTotal_H
	rts

Score_tallyFrame:
;arguments
;x - current player
;if the frame total is zero, skip all this
	lda Score_frameTotal_L
	bne @doScore
		lda Score_frameTotal_H
		bne @doScore
			rts
@doScore:
	lda #TRUE
	sta Score_hasChanged
	txa
	pha
	lda Score_multiplier,x
	tay
@multiplierLoop:
	dey
	bmi :+
	asl Score_frameTotal_L
	rol Score_frameTotal_H
	jmp @multiplierLoop
:
	jsr Score_convertToDecimal
;add the ones place
	pla
	tax
	clc
	lda Score_ones,x
	adc DecOnes
	cmp #10
	bcc :+
		sbc #10
:	sta Score_ones,x
;add the tens place
	lda Score_tens,x
	adc DecTens
	cmp #10
	bcc :+
		sbc #10
:	sta Score_tens,x
;add the hundreds place
	lda Score_hundreds,x
	adc DecHundreds
	cmp #10
	bcc :+
		sbc #10
:	sta Score_hundreds,x
;add the thousands place
	lda Score_thousands,x
	adc DecThousands
	cmp #10
	bcc :+
		sbc #10
:	sta Score_thousands,x
;add the ten thousands place
	lda Score_tenThousands,x
	adc DecTenThousands
	cmp #10
	bcc :+
		sbc #10
:	sta Score_tenThousands,x
;add the hundred thousands place
	lda Score_hundredThousands,x
	adc #0
	cmp #10
	bcc :+
		sbc #10
:	sta Score_hundredThousands,x
;add the millions place
	lda Score_millions,x
	adc #0
	cmp #10
	bcc :+
		sbc #10
:	sta Score_millions,x
	rts

Score_convertToDecimal:
;Returns decimal value in DecOnes, DecTens, DecHundreds, DecThousands, DecTenThousands.

	lda #$00
	sta DecOnes
	sta DecTens
	sta DecHundreds
	sta DecThousands
	sta DecTenThousands

	lda Score_frameTotal_L
	and #$0F
	tax
	lda HexDigit00Table,x
	sta DecOnes
	lda HexDigit01Table,x
	sta DecTens

	lda Score_frameTotal_L
	lsr a
	lsr a
	lsr a
	lsr a
	tax
	lda HexDigit10Table,x
	clc
	adc DecOnes
	sta DecOnes
	lda HexDigit11Table,x
	adc DecTens
	sta DecTens
	lda HexDigit12Table,x
	sta DecHundreds

	lda Score_frameTotal_H
	and #$0F
	tax
	lda HexDigit20Table,x
	clc
	adc DecOnes
	sta DecOnes
	lda HexDigit21Table,x
	adc DecTens
	sta DecTens
	lda HexDigit22Table,x
	adc DecHundreds
	sta DecHundreds
	lda HexDigit23Table,x
	sta DecThousands

	lda Score_frameTotal_H
	lsr a
	lsr a
	lsr a
	lsr a
	tax
	clc
	lda HexDigit30Table,x
	adc DecOnes
	sta DecOnes
	lda HexDigit31Table,x
	adc DecTens
	sta DecTens
	lda HexDigit32Table,x
	adc DecHundreds
	sta DecHundreds
	lda HexDigit33Table,x
	adc DecThousands
	sta DecThousands
	lda HexDigit34Table,x
	sta DecTenThousands

	clc
	ldx DecOnes
	lda DecimalSumsLow,x
	sta DecOnes
	

	lda DecimalSumsHigh,x
	adc DecTens
	tax
	lda DecimalSumsLow,x
	sta DecTens

	lda DecimalSumsHigh,x
	adc DecHundreds
	tax
	lda DecimalSumsLow,x
	sta DecHundreds

	lda DecimalSumsHigh,x
	adc DecThousands
	tax
	lda DecimalSumsLow,x
	sta DecThousands

	lda DecimalSumsHigh,x
	adc DecTenThousands
	tax
	lda DecimalSumsLow,x
	sta DecTenThousands			;263

	rts


;************ Pre-Converted Hex to Decimal Tables *************

;******

;1 byte
HexDigit32Table:
	.byte $0
HexDigit00Table:
DecimalSumsLow:
;55 bytes
	.byte $0,$1,$2,$3,$4,$5,$6,$7,$8,$9,$0,$1,$2,$3,$4,$5
	.byte $6,$7,$8,$9,$0,$1,$2,$3,$4,$5,$6,$7,$8,$9,$0,$1
	.byte $2,$3,$4,$5,$6,$7,$8,$9,$0,$1,$2,$3,$4,$5,$6,$7
	.byte $8,$9,$0,$1,$2,$3,$4

HexDigit01Table:
DecimalSumsHigh:
;55 bytes
	.byte $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$1,$1,$1,$1,$1,$1
	.byte $1,$1,$1,$1,$2,$2,$2,$2,$2,$2,$2,$2,$2,$2,$3,$3
	.byte $3,$3,$3,$3,$3,$3,$3,$3,$4,$4,$4,$4,$4,$4,$4,$4
	.byte $4,$4,$5,$5,$5,$5,$5

;111 bytes
;******
HexDigit30Table:
HexDigit20Table:
HexDigit10Table:
	.byte $0,$6,$2,$8,$4,$0,$6,$2,$8,$4,$0,$6,$2,$8,$4,$0

HexDigit11Table:
	.byte $0,$1,$3,$4,$6,$8,$9,$1,$2,$4,$6,$7,$9,$0,$2,$4

HexDigit12Table:
	.byte $0,$0,$0,$0,$0,$0,$0,$1,$1,$1,$1,$1,$1,$2,$2,$2
;******
HexDigit21Table:
	.byte $0,$5,$1,$6,$2,$8,$3,$9,$4,$0,$6,$1,$7,$2,$8,$4

HexDigit22Table:
	.byte $0,$2,$5,$7,$0,$2,$5,$7,$0,$3,$5,$8,$0,$3,$5,$8

HexDigit23Table:
	.byte $0,$0,$0,$0,$1,$1,$1,$1,$2,$2,$2,$2,$3,$3,$3,$3
;******
HexDigit31Table:
	.byte $0,$9,$9,$8,$8,$8,$7,$7,$6,$6,$6,$5,$5,$4,$4,$4

HexDigit33Table:
	.byte $0,$4,$8,$2,$6,$0,$4,$8,$2,$6,$0,$5,$9,$3,$7,$1

HexDigit34Table:
	.byte $0,$0,$0,$1,$1,$2,$2,$2,$3,$3,$4,$4,$4,$5,$5,$6

