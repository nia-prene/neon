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
;locals
;these convert bin to dec
DecOnes: .res 1
DecTens: .res 1
DecHundreds: .res 1
DecThousands: .res 1
DecTenThousands: .res 1
.data
Score_tilesTop: .res 7;7 digit score
Score_tilesBottom: .res 7;7 digit score

.code
Score_clear:
;arguments -
;x - player score to clear
	lda #0
	sta Score_ones
	sta Score_tens
	sta Score_hundreds
	sta Score_thousands
	sta Score_tenThousands
	sta Score_hundredThousands
	sta Score_millions
	sta Score_multiplier
	rts

Score_clearFrameTally:;void(void)
;call at beginning of frame to zero out score total
	lda #0
	sta Score_frameTotal_L
	sta Score_frameTotal_H
	rts

Score_tallyFrame:
;arguments
;a - current player
;todo multiplier
;get the player's multiplier
	tax
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

Score_toTiles:
;arguments
;x - player
	lda Score_ones,x
	tay
	lda @tileTop,y
	sta Score_tilesTop+6
	lda @tileBottom,y
	sta Score_tilesBottom+6

	lda Score_tens,x
	tay
	lda @tileTop,y
	sta Score_tilesTop+5
	lda @tileBottom,y
	sta Score_tilesBottom+5

	lda Score_hundreds,x
	tay
	lda @tileTop,y
	sta Score_tilesTop+4
	lda @tileBottom,y
	sta Score_tilesBottom+4
	
	lda Score_thousands,x
	tay
	lda @tileTop,y
	sta Score_tilesTop+3
	lda @tileBottom,y
	sta Score_tilesBottom+3

	lda Score_tenThousands,x
	tay
	lda @tileTop,y
	sta Score_tilesTop+2
	lda @tileBottom,y
	sta Score_tilesBottom+2
	
	lda Score_hundredThousands,x
	tay
	lda @tileTop,y
	sta Score_tilesTop+1
	lda @tileBottom,y
	sta Score_tilesBottom+1
	
	lda Score_millions,x
	tay
	lda @tileTop,y
	sta Score_tilesTop
	lda @tileBottom,y
	sta Score_tilesBottom
	rts
@tileTop:
	.byte ZERO_TOP, ONE_TOP, TWO_TOP, THREE_TOP, FOUR_TOP, FIVE_TOP, SIX_TOP, SEVEN_TOP, EIGHT_TOP, NINE_TOP
@tileBottom:
	.byte ZERO_BOTTOM, ONE_BOTTOM, TWO_BOTTOM, THREE_BOTTOM, FOUR_BOTTOM, FIVE_BOTTOM, SIX_BOTTOM, SEVEN_BOTTOM, EIGHT_BOTTOM, NINE_BOTTOM
ZERO_TOP=$ef
ZERO_BOTTOM=$e5
ONE_TOP=$e0
ONE_BOTTOM=$e1
TWO_TOP=$e2
TWO_BOTTOM=$e3
THREE_TOP=$e4
THREE_BOTTOM=$e5
FOUR_TOP=$e6
FOUR_BOTTOM=$e7
FIVE_TOP=$e8
FIVE_BOTTOM=$e5
SIX_TOP=$e9
SIX_BOTTOM=$e5
SEVEN_TOP=$ea
SEVEN_BOTTOM=$eb
EIGHT_TOP=$ec
EIGHT_BOTTOM=$e5
NINE_TOP=$ed
NINE_BOTTOM=$ee

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
HexDigit56Table:
DecimalSumsLow:
;55 bytes
	.byte $0,$1,$2,$3,$4,$5,$6,$7,$8,$9,$0,$1,$2,$3,$4,$5
	.byte $6,$7,$8,$9,$0,$1,$2,$3,$4,$5,$6,$7,$8,$9,$0,$1
	.byte $2,$3,$4,$5,$6,$7,$8,$9,$0,$1,$2,$3,$4,$5,$6,$7
	.byte $8,$9,$0,$1,$2,$3,$4

HexDigit01Table:
HexDigit57Table:
DecimalSumsHigh:
;55 bytes
	.byte $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$1,$1,$1,$1,$1,$1
	.byte $1,$1,$1,$1,$2,$2,$2,$2,$2,$2,$2,$2,$2,$2,$3,$3
	.byte $3,$3,$3,$3,$3,$3,$3,$3,$4,$4,$4,$4,$4,$4,$4,$4
	.byte $4,$4,$5,$5,$5,$5,$5

;111 bytes
;******
HexDigit50Table:
HexDigit40Table:
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

;******
HexDigit41Table:
	.byte $0,$3,$7,$0,$4,$8,$1,$5,$8,$2,$6,$9,$3,$6,$0,$4

HexDigit42Table:
	.byte $0,$5,$0,$6,$1,$6,$2,$7,$2,$8,$3,$8,$4,$9,$5,$0

HexDigit43Table:
	.byte $0,$5,$1,$6,$2,$7,$3,$8,$4,$9,$5,$0,$6,$1,$7,$3

HexDigit44Table:
	.byte $0,$6,$3,$9,$6,$2,$9,$5,$2,$8,$5,$2,$8,$5,$1,$8

HexDigit45Table:
	.byte $0,$0,$1,$1,$2,$3,$3,$4,$5,$5,$6,$7,$7,$8,$9,$9
;******
HexDigit51Table:
	.byte $0,$7,$5,$2,$0,$8,$5,$3,$0,$8,$6,$3,$1,$8,$6,$4

HexDigit52Table:
	.byte $0,$5,$1,$7,$3,$8,$4,$0,$6,$1,$7,$3,$9,$4,$0,$6

HexDigit53Table:
	.byte $0,$8,$7,$5,$4,$2,$1,$0,$8,$7,$5,$4,$2,$1,$0,$8

HexDigit54Table:
	.byte $0,$4,$9,$4,$9,$4,$9,$4,$8,$3,$8,$3,$8,$3,$8,$2

HexDigit55Table:
	.byte $0,$0,$0,$1,$1,$2,$2,$3,$3,$4,$4,$5,$5,$6,$6,$7
