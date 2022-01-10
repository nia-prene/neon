.include "apu.h"
.include "lib.h"

CHANNEL_VOL = $4000;Duty / volume for all channels
CHANNEL_SWEEP = $4001;Sweep control for all channels
CHANNEL_LO = $4002;Low byte of period for all channels
CHANNEL_HI = $4003;High byte of period for all channels
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
MAX_TRACKS=4
tracks: .res MAX_TRACKS
trackPtr: .res 2
trackIndex: .res MAX_TRACKS
loops: .res MAX_TRACKS
loopPtr: .res 2
note:.res MAX_TRACKS
rest:.res MAX_TRACKS
loopIndex: .res MAX_TRACKS
length:.res MAX_TRACKS-1
notePeriod:.res MAX_TRACKS-1
state: .res MAX_TRACKS-2
instrument: .res MAX_TRACKS-2
maxVolume: .res MAX_TRACKS-2
currentVolume: .res MAX_TRACKS-2
targetVolume: .res MAX_TRACKS-2



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
	ldx #0
	lda songsSQ1,x
	sta tracks
	lda songsSQ2,x
	sta tracks+1
	lda songsTri,x
	sta tracks+2
	lda songsDPCM,x
	sta tracks+3

	ldx #1;2 squares
@setupSquare:
	lda tracks,x
	tay
	lda tracks_L,y
	sta trackPtr
	lda tracks_H,y
	sta trackPtr+1
	ldy #0
	lda (trackPtr),y
	sta loops,x
	iny
	lda (trackPtr),y;get new instrument
	sta instrument,x
	iny
	lda (trackPtr),y;get new volume
	sta maxVolume,x
	iny
	sty trackIndex,x
	dex
	bpl @setupSquare

	lda #0
	ldy #MAX_TRACKS-1
@clearMem1:
	sta note,y
	sta loopIndex,y
	sta rest,y
	dey
	bpl @clearMem1
	ldy #MAX_TRACKS-2
@clearMem2:
	sta length,y
	dey
	bpl @clearMem2
	ldy #MAX_TRACKS-3
@clearMem3:
	sta currentVolume,y
	sta targetVolume,y
	rts

APU_advance:
	ldx #1;start with sq 1
@squareLoop:
	lda length,x;see if note is still playing
	beq @checkRest
		dec length,x
		lda	#>(@next-1)
		pha
		lda	#<(@next-1)
		pha
		ldy state,x;attack,decay,sustain,vibrato
		lda @states_H,y
		pha
		lda @states_L,y
		pha
		rts
@checkRest:
	lda rest,x
	beq @newNote
		jsr Note_release
		jmp @next	
@newNote:
	jsr getNewNote;(x)
@next:
	dex
	bpl @squareLoop
	rts
@states_H:
	.byte >(Note_attack-1), >(Note_decay-1), >(Note_sustain-1)
@states_L:
	.byte <(Note_attack-1), <(Note_decay-1), <(Note_sustain-1)

getNewNote:
	ldy loops,x;get the channel loop
	lda loops_L,y;setup pointer
	sta loopPtr
	lda loops_H,y
	sta loopPtr+1
	ldy loopIndex,x;get the index
	lda (loopPtr),y;get note
	bne @loopContinues;loops are null terminated
		ldy tracks,x
		lda tracks_L,y
		sta trackPtr
		lda tracks_H,y
		sta trackPtr+1
		ldy trackIndex,x;get place in song
		lda (trackPtr),y;get new loop
		bne @trackContinues;tracks are null terminated
			ldy #0
			lda (trackPtr),y;get first loop
	@trackContinues:
		sta loops,x
		iny
		lda (trackPtr),y;get new instrument
		sta instrument,x
		iny
		lda (trackPtr),y;get new volume
		sta maxVolume,x
		iny
		sty trackIndex,x;save place in song
		ldy loops,x;get the channel loop
		lda loops_L,y;setup pointer
		sta loopPtr
		lda loops_H,y
		sta loopPtr+1
		ldy #0;start at beginning of loop
		lda (loopPtr),y;get note
@loopContinues:
	sta note,x
	iny
	lda (loopPtr),y;get play duration
	sta length,x
	dec length,x;this frame counts
	iny
	lda (loopPtr),y;get rest duration
	sta rest,x
	iny
	sty loopIndex,x;save the index
	lda #0
	sta state,x;note in attack state (00)
	ldy note,x
	lda periodTable_H,y
	pha
	lda periodTable_L,y
	pha
	ldy instrument,x
	lda instSweep,y
	pha
	lda instAttack,y
	cmp maxVolume,x
	bcc :+
		lda maxVolume,x
		inc state,x
	:sta currentVolume,x
	ora instDuty,y
	pha
	txa
	asl
	asl
	tay
	pla
	sta CHANNEL_VOL,y
	pla
	sta CHANNEL_SWEEP,y 
	pla
	sta CHANNEL_LO,y
	pla
	sta CHANNEL_HI,y 
	rts	

Note_attack:
	ldy instrument,x
	clc
	lda currentVolume,x
	adc instAttack,y
	cmp maxVolume,x
	bcc :+
		lda maxVolume,x
		inc state,x
	:sta currentVolume,x
	ora instDuty,y
	pha
	txa
	asl
	asl
	tay
	pla
	sta CHANNEL_VOL,y
	rts
Note_decay:
	ldy instrument,x
	sec
	lda maxVolume,x
	sbc instSustain,y
	bcs :+
		sec
		lda #0
	:sta targetVolume,x
	lda currentVolume,x
	sbc instDecay,y
	cmp targetVolume,x
	bcs :+
		lda targetVolume,x
		inc state,x
	:sta currentVolume,x
	ora instDuty,y
	pha
	txa
	asl
	asl
	tay
	pla
	sta CHANNEL_VOL,y
	rts
Note_sustain:
	ldy instrument,x
	lda currentVolume,x
	ora instDuty,y
	pha
	txa
	asl
	asl
	tay
	pla
	sta CHANNEL_VOL,y
	rts
Note_release:
	ldy instrument,x
	sec
	lda currentVolume,x
	sbc instRelease,y;fade out the note a little every frame
	bcs :+
		lda #0;dont let volume go negative
	:sta currentVolume,x
	ora instDuty,y
	pha
	txa
	asl
	asl
	tay
	pla
	sta CHANNEL_VOL,y
	dec rest,x
	rts
	ldy note,x
	lda periodTable_L,y
	pha
	ldy instrument,x
	lda currentVolume,x
	ora instDuty,y
	pha
	txa
	asl
	asl
	tay
	pla
	sta CHANNEL_VOL,y
	pla
	sta CHANNEL_LO,y
	rts
.rodata	
songsSQ1:
	.byte TRACK00
songsSQ2:
	.byte TRACK01
songsTri:
	.byte TRACK02
songsDPCM:
	.byte TRACK03
TRACK00=$00;s1 sq1
TRACK01=$01;s1 sq2
TRACK02=$02;s1 tri
TRACK03=$03;s1 dpcm
tracks_H:
	.byte >track00, >track01, >track02, >track03
tracks_L:
	.byte <track00, <track01, <track02 ,<track03 

track00:;loop, instrument, volume
	.byte LOOP0A, INST00, 10 
	.byte LOOP01, INST00, 10 
	.byte LOOP0A, INST00, 10 
	.byte LOOP02, INST00, 10
	.byte LOOP0A, INST00, 10
	.byte LOOP01, INST00, 10 
	.byte LOOP0A, INST00, 10 
	.byte LOOP02, INST00, 10 
	.byte NULL
track01:
	.byte LOOP03, INST00, 10
	.byte LOOP04, INST00, 10
	.byte LOOP03, INST00, 10 
	.byte LOOP05, INST00, 10 
	.byte LOOP03, INST00, 10
	.byte LOOP04, INST00, 10
	.byte LOOP03, INST00, 10
	.byte LOOP05, INST00, 10
	.byte NULL
track02:
	.byte LOOP06, LOOP07, LOOP06, LOOP08
	.byte LOOP06, LOOP07, LOOP06, LOOP08
	.byte LOOP06, LOOP07, LOOP06, LOOP08
	.byte LOOP06, LOOP07, LOOP06, LOOP08
	.byte NULL
track03:
	.byte LOOP09, LOOP09, LOOP09, LOOP09
	.byte NULL

LOOP01=$01;s1 sq1 chorus 2
LOOP02=$02;s1 sq1 chorus 3
LOOP03=$03;s1 sq2 chorus 1
LOOP04=$04;s1 sq2 chorus 2
LOOP05=$05;s1 sq2 chorus 3
LOOP06=$06;s1 tri chorus 1
LOOP07=$07;s1 tri chorus 2
LOOP08=$08;s1 tri chorus 3
LOOP09=$09;2 measures of drums kick snare
LOOP0A=$0a;s1 sq1 chorus 1

loops_H:
	.byte NULL, >loop01, >loop02, >loop03, >loop04, >loop05, >loop06, >loop07, >loop08, >loop09, >loop0A
loops_L:
	.byte NULL, <loop01, <loop02, <loop03, <loop04, <loop05, <loop06, <loop07, <loop08, <loop09, <loop0A
	
loop01:
	.byte D3,12, 0, E3, 6, 0
	.byte Gb3,15, 3, A2,12, 0
	.byte B2,12, 0, A2, 6, 0
	.byte G2,18, 0, A2, 9, 3
	.byte NULL
loop02:
	.byte D3,12, 6, Db3,12, 3
	.byte A2,12, 3, D3, 36, 0
	.byte A2, 9, 3
	.byte NULL
loop03:
	.byte D3,12, 6, D4,12, 3
	.byte Db4,12, 3, A3,12, 6
	.byte Gb3,12, 3, E3,12, 3
	.byte NULL
loop04:
	.byte Gb3,12, 0, G3, 6, 0
	.byte A3,15, 3, E3,12, 0
	.byte Gb3,12, 0, E3, 6, 0
	.byte D3,18, 0, Db3, 9, 3
	.byte NULL
loop05:
	.byte Gb3,12, 6, E3,12, 3
	.byte D3,12, 3, Gb3, 36, 0
	.byte Db3, 9, 3
	.byte NULL
	
loop06:
	.byte B2, 12, 6, B2, 12, 3 
	.byte B2,12, 3, Db3, 12, 6 
	.byte Db3, 12, 3, Db3, 12, 3
	.byte D3, 12, 6
	.byte NULL
loop07:
	.byte D3, 15, 3
	.byte A2, 12, 0, B2, 12, 0
	.byte A2, 06, 0, G2, 18, 0
	.byte A2, 9, 3
	.byte NULL
loop08:
	.byte D3, 12, 3, A2, 12, 3
	.byte D3, 36, 0, A2 ,9, 3 
	.byte NULL
	
loop09:	
	.byte SAMPLE01, 12, SAMPLE02, 12
	.byte SAMPLE01, 12, SAMPLE02, 12
	.byte SAMPLE01, 12, SAMPLE02, 12
	.byte SAMPLE01, 12, SAMPLE02, 12
	.byte SAMPLE01, 12, SAMPLE02, 12
	.byte SAMPLE01, 12, SAMPLE02, 12
	.byte SAMPLE01, 12, SAMPLE02, 12
	.byte SAMPLE01, 12, SAMPLE02, 12
	.byte NULL
loop0A:
	.byte B2, 12, 6, G3, 12, 3
	.byte Gb3,12, 3, E3, 12, 6
	.byte D3,12, 3, Db3,12, 3
	.byte NULL
DUTY00=%00110000
DUTY01=%01110000
DUTY02=%10110000
DUTY03=%11110000
SWEEP_DISABLE=%0
SWEEP_ENABLE=%1
CONSTANT=%110000
INST00=$00
instDuty:;ddlc vvvv
	.byte DUTY02
instSweep:;eppp nsss
	.byte (SWEEP_DISABLE<<7)
instAttack:
	.byte 15
instDecay:
	.byte 5
instSustain:;volume minus number below
	.byte 5
instRelease:
	.byte 3

KICK_ADDRESS= <(( DPCM_kick - $C000) >> 6)
KICK_LENGTH=%10000
SNARE_ADDRESS= <(( DPCM_snare  - $C000) >> 6)
SNARE_LENGTH=%1110

SAMPLE01=$01;kick
SAMPLE02=$02;snare

Samples_address:
	.byte NULL, KICK_ADDRESS, SNARE_ADDRESS
Samples_length:
	.byte NULL, KICK_LENGTH, SNARE_LENGTH
A0=$01
Bb0=$02
B0=$03
C1=$04
Db1=$05
D1=$06
Eb1=$07
E1=$08
F1=$09
Gb1=$0a
G1=$0b
Ab1=$0c
A1=$0d
Bb1=$0e
B1=$0f
C2=$10
Db2=$11
D2=$12
Eb2=$13
E2=$14
F2=$15
Gb2=$16
G2=$17
Ab2=$18
A2=$19
Bb2=$1a
B2=$1b
C3=$1c
Db3=$1d
D3=$1e
Eb3=$1f
E3=$20
F3=$21
Gb3=$22
G3=$23
Ab3=$24
A3=$25
Bb3=$26
B3=$27
C4=$28
Db4=$29
D4=$2a
Eb4=$2b
E4=$2c
F4=$2d
Gb4=$2e
G4=$2f
Ab4=$30
A4=$31
Bb4=$32
B4=$33
C5=$34
Db5=$35
D5=$36
Eb5=$37
E5=$38
F5=$39
Gb5=$3a
G5=$3b
Ab5=$3c
A5=$3d
Bb5=$3e
B5=$3f
C6=$40
Db6=$41
D6=$42
Eb6=$43
E6=$44
F6=$45
Gb6=$46
G6=$47
Ab6=$48
A6=$49
Bb6=$4a
B6=$4b
C7=$4c
Db7=$4d
D7=$4e
Eb7=$4f
E7=$50
F7=$51
Gb7=$52
G7=$53
Ab7=$54
A7=$55
Bb7=$56
B7=$57
C8=$58
Db8=$59
D8=$5a
Eb8=$5b
E8=$5c
F8=$5d
Gb8=$5e
G8=$5f
Ab8=$60
periodTable_L:
  .byte NULL,$f1,$7f,$13,$ad,$4d,$f3,$9d,$4c,$00,$b8,$74,$34
  .byte $f8,$bf,$89,$56,$26,$f9,$ce,$a6,$80,$5c,$3a,$1a
  .byte $fb,$df,$c4,$ab,$93,$7c,$67,$52,$3f,$2d,$1c,$0c
  .byte $fd,$ef,$e1,$d5,$c9,$bd,$b3,$a9,$9f,$96,$8e,$86
  .byte $7e,$77,$70,$6a,$64,$5e,$59,$54,$4f,$4b,$46,$42
  .byte $3f,$3b,$38,$34,$31,$2f,$2c,$29,$27,$25,$23,$21
  .byte $1f,$1d,$1b,$1a,$18,$17,$15,$14
periodTable_H:
  .byte NULL, $07,$07,$07,$06,$06,$05,$05,$05,$05,$04,$04,$04
  .byte $03,$03,$03,$03,$03,$02,$02,$02,$02,$02,$02,$02
  .byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00

.segment "DRUMS"
.align 64
DPCM_kick:
	.incbin "kick.dmc"
.align 64
DPCM_snare:
	.incbin "snare.dmc"
