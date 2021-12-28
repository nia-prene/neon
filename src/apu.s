.include "apu.h"
.include "lib.h"

;apu registers
SQ1_VOL = $4000;Duty and volume for square wave 1
SQ1_SWEEP = $4001;Sweep control register for square wave 1
SQ1_LO = $4002;Low byte of period for square wave 1
SQ1_HI = $4003;High byte of period and length counter value for square wave 1
SQ2_VOL = $4004;Duty and volume for square wave 2
SQ2_SWEEP = $4005;Sweep control register for square wave 2
SQ2_LO = $4006;Low byte of period for square wave 2
SQ2_HI = $4007;High byte of period and length counter value for square wave 2
TRI_LINEAR = $4008;Triangle wave linear counter
TRI_LO = $400A;Low byte of period for triangle wave
TRI_HI = $400B;High byte of period and length counter value for triangle wave
NOISE_VOL = $400C;Volume for noise generator
NOISE_LO = $400E;Period and waveform shape for noise generator
NOISE_HI = $400F;Length counter value for noise generator
DMC_FREQ = $4010;Play mode and frequency for DMC samples
DMC_RAW = $4011;7-bit DAC
DMC_START = $4012;Start of DMC waveform is at address $C000 + $40*$xx
DMC_LEN = $4013;Length of DMC waveform is $10*$xx + 1 bytes (128*$xx + 8 samples)
SND_CHN = $4015;Sound channels enable and status

.zeropage
m: .res 1
SQ1_loopPointer: .res 2
SQ1_trackPointer: .res 2
SQ1_loopIndex: .res 1
SQ1_trackIndex: .res 1
SQ1_ctrl: .res 1
SQ1_sweep: .res 1
SQ1_length: .res 1
SQ1_rest: .res 1

SQ2_loopPointer: .res 2
SQ2_trackPointer: .res 2
SQ2_loopIndex: .res 1
SQ2_trackIndex: .res 1
SQ2_ctrl: .res 1
SQ2_sweep: .res 1
SQ2_length: .res 1
SQ2_rest: .res 1

TRI_loopPointer: .res 2
TRI_trackPointer: .res 2

.data

.code
APU_init:
        ; Init $4000-4013
        ldy #$13
@loop:  lda @regs,y
        sta $4000,y
        dey
        bpl @loop
 
        ; We have to skip over $4014 (OAMDMA)
        lda #$0f
        sta $4015
        lda #$40
        sta $4017
   
        rts
@regs:
        .byte $30,$08,$00,$00
        .byte $30,$08,$00,$00
        .byte $80,$00,$00,$00
        .byte $30,$00,$00,$00
        .byte $00,$00,$00,$00
APU_setSong:;void(x)
;stage to set
	ldx #0;force arg 0
;zero out loop counters
	ldy #0
	sty SQ1_loopIndex
	sty SQ1_trackIndex
	sty SQ1_length
	sty SQ1_rest
	sty SQ2_loopIndex
	sty SQ2_trackIndex
	sty SQ2_length
	sty SQ2_rest
;get sq1 track
	lda tracks_L,x
	sta SQ1_trackPointer
	lda tracks_H,x
	sta SQ1_trackPointer+1
	lda (SQ1_trackPointer),y
	sta SQ1_ctrl
	iny
	lda (SQ1_trackPointer),y
	sta SQ1_sweep
	iny
	lda (SQ1_trackPointer),y
	iny
	sty SQ1_trackIndex
	tay
	lda loops_L,y
	sta SQ1_loopPointer
	lda loops_H,y
	sta SQ1_loopPointer+1
;get sq2 track
	ldx #1
	ldy #0
	lda tracks_L,x
	sta SQ2_trackPointer
	lda tracks_H,x
	sta SQ2_trackPointer+1
	lda (SQ2_trackPointer),y
	sta SQ2_ctrl
	iny
	lda (SQ2_trackPointer),y
	sta SQ2_sweep
	iny
	lda (SQ2_trackPointer),y
	iny
	sty SQ2_trackIndex
	tay
	lda loops_L,y
	sta SQ2_loopPointer
	lda loops_H,y
	sta SQ2_loopPointer+1
	rts

APU_advance:
@updateS1:
	lda SQ1_length
	bne @stillPlaying
		lda SQ1_rest
		bne @stillResting
			ldy SQ1_loopIndex
			lda (SQ1_loopPointer),y
			cmp #TERMINATE;end when $FF
			bne @loopContinues
				ldy SQ1_trackIndex;get new loop
				lda (SQ1_trackPointer),y;get duty/vol
				sta SQ1_ctrl
				iny
				lda (SQ1_trackPointer),y;get the sweep
				sta SQ1_sweep
				iny
				lda (SQ1_trackPointer),y;get the loop
				iny
				sty SQ1_trackIndex;save the pos in track
				tay
				lda loops_L,y
				sta SQ1_loopPointer
				lda loops_H,y
				sta SQ1_loopPointer+1
				ldy #0;reset index
				sty SQ1_loopIndex
				lda (SQ1_loopPointer),y;get the first note
		@loopContinues:
			tax;play a note
			lda periodTable_L,x
			sta SQ1_LO
			lda periodTable_H,x
			sta SQ1_HI
			iny;set length
			lda (SQ1_loopPointer),y
			sta SQ1_length
			dec SQ1_length
			iny;set rest
			lda (SQ1_loopPointer),y
			sta SQ1_rest
			lda SQ1_ctrl
			sta SQ1_VOL
			lda SQ1_sweep
			sta SQ1_SWEEP
			iny;advance loop
			sty SQ1_loopIndex
			jmp @updateS2
@stillPlaying:
	dec SQ1_length
	jmp @updateS2
@stillResting:
;silence channel
	lda #%10110000
	sta SQ1_VOL 
	dec SQ1_rest
@updateS2:
	lda SQ2_length
	bne @SQ2stillPlaying
		lda SQ2_rest
		bne @SQ2stillResting
			ldy SQ2_loopIndex
			lda (SQ2_loopPointer),y
			cmp #TERMINATE;end when $FF
			bne @SQ2loopContinues
				ldy SQ2_trackIndex;get new loop
				lda (SQ2_trackPointer),y;get duty/vol
				sta SQ2_ctrl
				iny
				lda (SQ2_trackPointer),y;get the sweep
				sta SQ2_sweep
				iny
				lda (SQ2_trackPointer),y;get the loop
				iny
				sty SQ2_trackIndex;save pos in track
				tay
				lda loops_L,y
				sta SQ2_loopPointer
				lda loops_H,y
				sta SQ2_loopPointer+1
				ldy #0;reset index
				sty SQ2_loopIndex
				lda (SQ2_loopPointer),y;get first note
		@SQ2loopContinues:
			tax;play a note
			lda periodTable_L,x
			sta SQ2_LO
			lda periodTable_H,x
			sta SQ2_HI
			iny
			lda (SQ2_loopPointer),y;get length
			sta SQ2_length
			dec SQ2_length
			iny
			lda (SQ2_loopPointer),y;get rest
			sta SQ2_rest
			lda SQ2_ctrl
			sta SQ2_VOL
			lda SQ2_sweep
			sta SQ2_SWEEP
			iny;advance loop
			sty SQ2_loopIndex
			jmp @updateTri
@SQ2stillPlaying:
	dec SQ2_length
	jmp @updateTri
@SQ2stillResting:
;silence channel
	lda #$30;mutes channel
	sta SQ2_VOL 
	dec SQ2_rest
@updateTri:;todo
@return:
	rts
.rodata	

TRACK00=$00
tracks_H:
	.byte >track00, >track01
tracks_L:
	.byte <track00, <track01

track00:
	.byte (SQ_INST00_CTRL|10), SQ_INST00_SWEEP, LOOP00
	.byte (SQ_INST00_CTRL|10), SQ_INST00_SWEEP, LOOP00
	.byte (SQ_INST00_CTRL|10), SQ_INST00_SWEEP, LOOP00
	.byte (SQ_INST00_CTRL|10), SQ_INST00_SWEEP, LOOP00
track01:
	.byte (SQ_INST00_CTRL|10), SQ_INST00_SWEEP, LOOP01
	.byte (SQ_INST00_CTRL|10), SQ_INST00_SWEEP, LOOP01
	.byte (SQ_INST00_CTRL|10), SQ_INST00_SWEEP, LOOP01
	.byte (SQ_INST00_CTRL|10), SQ_INST00_SWEEP, LOOP01

LOOP00=$00
LOOP01=$01
loops_H:
	.byte >loop00, >loop01
loops_L:
	.byte <loop00, <loop01
	
loop00:
	.byte B2, 12, 6, G3, 12, 3
	.byte Gb3,12, 3, E3, 15, 3
	.byte D3,12, 3, Db3,12, 3
	.byte D3,12, 0, E3, 6, 0
	.byte Gb3,15, 3, A2,12, 0
	.byte B2,12, 0, A2, 6, 0
	.byte G2,18, 3, A2, 6, 3
	.byte B2,12, 6, G3,12, 3
	.byte Gb3,12, 3, E3,15, 3
	.byte D3,12, 3, Db3,12, 3
	.byte D3,12, 6, Db3,12, 3
	.byte A2,12, 3, D3, 36, 3
	.byte A2, 6, 3, TERMINATE

loop01:
	.byte D3,12, 6, D4,12, 3
	.byte Db4,12, 3, A3,15, 3
	.byte Gb3,12, 3, E3,12, 3
	.byte Gb3,12, 0, G3, 6, 0
	.byte A3,15, 3, E3,12, 0
	.byte Gb3,12, 0, E3, 6, 0
	.byte D3,18, 3, Db3, 6, 3
	.byte D3,12, 6, D4,12, 3
	.byte Db4,12, 3, A3,15, 3
	.byte Gb3,12, 3, E3,12, 3
	.byte Gb3,12, 6, E3,12, 3
	.byte D3,12, 3, Gb3, 36, 3
	.byte Db3, 6, 3, TERMINATE


DUTY00=%00
DUTY01=%01
DUTY10=%10
DUTY11=%11
CONSTANT_VOL=%1
LOOP=%1
SWEEP_DISABLE=%0
SWEEP_ENABLE=%1

SQ_INST00_CTRL= (DUTY10<<6)|(LOOP<<5)|(CONSTANT_VOL<<4)
SQ_INST00_SWEEP=(SWEEP_DISABLE<<7)

A0=$00
Bb0=$01
B0=$02
C1=$03
Db1=$04
D1=$05
Eb1=$06
E1=$07
F1=$08
Gb1=$09
G1=$0a
Ab1=$0b
A1=$0c
Bb1=$0d
B1=$0e
C2=$0f
Db2=$10
D2=$11
Eb2=$12
E2=$13
F2=$14
Gb2=$15
G2=$16
Ab2=$17
A2=$18
Bb2=$19
B2=$1a
C3=$1b
Db3=$1c
D3=$1d
Eb3=$1e
E3=$1f
F3=$20
Gb3=$21
G3=$22
Ab3=$23
A3=$24
Bb3=$25
B3=$26
C4=$27
Db4=$28
D4=$29
Eb4=$2a
E4=$2b
F4=$2c
Gb4=$2d
G4=$2e
Ab4=$2f
A4=$30
Bb4=$31
B4=$32
C5=$33
Db5=$34
D5=$35
Eb5=$36
E5=$37
F5=$38
Gb5=$39
G5=$3a
Ab5=$3b
A5=$3c
Bb5=$3d
B5=$3e
C6=$3f
Db6=$40
D6=$41
Eb6=$42
E6=$43
F6=$44
Gb6=$45
G6=$46
Ab6=$47
A6=$48
Bb6=$49
B6=$4a
C7=$4b
Db7=$4c
D7=$4d
Eb7=$4e
E7=$4f
F7=$50
Gb7=$51
G7=$52
Ab7=$53
A7=$48
Bb7=$49
B7=$4a
C8=$4b
Db8=$4c
D8=$4d
Eb8=$4e
E8=$4f
F8=$50
Gb8=$51
G8=$52
Ab8=$53
periodTable_L:
  .byte $f1,$7f,$13,$ad,$4d,$f3,$9d,$4c,$00,$b8,$74,$34
  .byte $f8,$bf,$89,$56,$26,$f9,$ce,$a6,$80,$5c,$3a,$1a
  .byte $fb,$df,$c4,$ab,$93,$7c,$67,$52,$3f,$2d,$1c,$0c
  .byte $fd,$ef,$e1,$d5,$c9,$bd,$b3,$a9,$9f,$96,$8e,$86
  .byte $7e,$77,$70,$6a,$64,$5e,$59,$54,$4f,$4b,$46,$42
  .byte $3f,$3b,$38,$34,$31,$2f,$2c,$29,$27,$25,$23,$21
  .byte $1f,$1d,$1b,$1a,$18,$17,$15,$14
periodTable_H:
  .byte $07,$07,$07,$06,$06,$05,$05,$05,$05,$04,$04,$04
  .byte $03,$03,$03,$03,$03,$02,$02,$02,$02,$02,$02,$02
  .byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00
