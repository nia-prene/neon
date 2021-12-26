.include "apu.h"

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
note: .res 1

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

APU_advance:
	lda m
	and #%111
	bne @return
	lda note
	and #%11111
	tax
	lda song,x
	tax
	lda periodTable_L,x
	sta $4002
	lda periodTable_H,x
	sta $4003
	lda #%10111111
	sta $4000
	inc note
@return:
	inc m
	rts
.rodata	
song:
	.byte C1, D1, E1, F1, G1, A1, B1, C2
	.byte C2, D2, E2, F2, G2, A2, B2, C3
	.byte C3, D3, E3, F3, G3, A3, B3, C4
	.byte C4, D4, E4, F4, G4, A4, B4, C5
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
