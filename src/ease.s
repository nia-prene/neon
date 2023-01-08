.include "ease.h"

.rodata

ease_inQuarters_l:
	.byte	$00, $00, $00, $00, $01, $02, $04, $06
	.byte	$09, $0D, $12, $19, $20, $29, $34, $40

ease_inQuarters_h:
	.byte	$00, $00, $00, $00, $00, $00, $00, $00
	.byte	$00, $00, $00, $00, $00, $00, $00, $00

ease_inHalves_l:
	.byte	$00, $00, $00, $01, $02, $04, $08, $0D
	.byte	$13, $1B, $25, $32, $41, $53, $68, $80

ease_inHalves_h:
	.byte	$00, $00, $00, $00, $00, $00, $00, $00
	.byte	$00, $00, $00, $00, $00, $00, $00, $00

ease_inOnes_l:
	.byte	$00, $00, $00, $02, $04, $09, $10, $1A
	.byte	$26, $37, $4B, $64, $83, $A6, $D0, $00

ease_inOnes_h:
	.byte	$00, $00, $00, $00, $00, $00, $00, $00
	.byte	$00, $00, $00, $00, $00, $00, $00, $01

ease_inTwos_l:
	.byte	$00, $00, $01, $04, $09, $12, $20, $34
	.byte	$4D, $6E, $97, $C9, $06, $4D, $A0, $00

ease_inTwos_h:
	.byte	$00, $00, $00, $00, $00, $00, $00, $00
	.byte	$00, $00, $00, $00, $01, $01, $01, $02

ease_inFours_l:
	.byte	$00, $00, $02, $08, $13, $25, $41, $68
	.byte	$9B, $DD, $2F, $93, $0C, $9A, $40, $00

ease_inFours_h:
	.byte	$00, $00, $00, $00, $00, $00, $00, $00
	.byte	$00, $00, $01, $01, $02, $02, $03, $04

ease_inEights_l:
	.byte	$00, $00, $04, $10, $26, $4B, $83, $D0
	.byte	$36, $BA, $5E, $27, $18, $35, $81, $00

ease_inEights_h:
	.byte	$00, $00, $00, $00, $00, $00, $00, $00
	.byte	$01, $01, $02, $03, $04, $05, $06, $08

ease_inSixteens_l:
	.byte	$00, $01, $09, $20, $4D, $97, $06, $A0
	.byte	$6D, $74, $BD, $4F, $31, $6A, $02, $00

ease_inSixteens_h:
	.byte	$00, $00, $00, $00, $00, $00, $01, $01
	.byte	$02, $03, $04, $06, $08, $0A, $0D, $10

ease_outQuarters_l:
	.byte	$40, $3F, $3F, $3F, $3E, $3D, $3B, $39
	.byte	$36, $32, $2D, $26, $1F, $16, $0B, $00

ease_outQuarters_h:
	.byte	$00, $00, $00, $00, $00, $00, $00, $00
	.byte	$00, $00, $00, $00, $00, $00, $00, $00

ease_outHalves_l:
	.byte	$80, $7F, $7F, $7E, $7D, $7B, $77, $72
	.byte	$6C, $64, $5A, $4D, $3E, $2C, $17, $00

ease_outHalves_h:
	.byte	$00, $00, $00, $00, $00, $00, $00, $00
	.byte	$00, $00, $00, $00, $00, $00, $00, $00

ease_outOnes_l:
	.byte	$00, $FF, $FF, $FD, $FB, $F6, $EF, $E5
	.byte	$D9, $C8, $B4, $9B, $7C, $59, $2F, $00

ease_outOnes_h:
	.byte	$01, $00, $00, $00, $00, $00, $00, $00
	.byte	$00, $00, $00, $00, $00, $00, $00, $00

ease_outTwos_l:
	.byte	$00, $FF, $FE, $FB, $F6, $ED, $DF, $CB
	.byte	$B2, $91, $68, $36, $F9, $B2, $5F, $00

ease_outTwos_h:
	.byte	$02, $01, $01, $01, $01, $01, $01, $01
	.byte	$01, $01, $01, $01, $00, $00, $00, $00

ease_outFours_l:
	.byte	$00, $FF, $FD, $F7, $EC, $DA, $BE, $97
	.byte	$64, $22, $D0, $6C, $F3, $65, $BF, $00

ease_outFours_h:
	.byte	$04, $03, $03, $03, $03, $03, $03, $03
	.byte	$03, $03, $02, $02, $01, $01, $00, $00

ease_outEights_l:
	.byte	$00, $FF, $FB, $EF, $D9, $B4, $7C, $2F
	.byte	$C9, $45, $A1, $D8, $E7, $CA, $7E, $00

ease_outEights_h:
	.byte	$08, $07, $07, $07, $07, $07, $07, $07
	.byte	$06, $06, $05, $04, $03, $02, $01, $00

ease_outSixteens_l:
	.byte	$00, $FE, $F6, $DF, $B2, $68, $F9, $5F
	.byte	$92, $8B, $42, $B0, $CE, $95, $FD, $00

ease_outSixteens_h:
	.byte	$10, $0F, $0F, $0F, $0F, $0F, $0E, $0E
	.byte	$0D, $0C, $0B, $09, $07, $05, $02, $00

