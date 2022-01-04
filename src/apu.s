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
SQ1_loopVolume: .res 1
SQ1_envelopeVolume: .res 1
SQ1_envelopeIndex: .res 1
SQ1_sweep: .res 1
SQ1_length: .res 1
SQ1_rest: .res 1
SQ1_envelopePtr: .res 2
SQ1_envelopeRest: .res 1

SQ2_loopPointer: .res 2
SQ2_trackPointer: .res 2
SQ2_loopIndex: .res 1
SQ2_trackIndex: .res 1
SQ2_ctrl: .res 1
SQ2_loopVolume: .res 1
SQ2_sweep: .res 1
SQ2_length: .res 1
SQ2_rest: .res 1

Tri_loopPointer: .res 2
Tri_trackPointer: .res 2
Tri_loopIndex: .res 1
Tri_trackIndex: .res 1
Tri_length: .res 1
Tri_rest: .res 1

DPCM_trackPointer: .res 2
DPCM_loopPointer: .res 2
DPCM_loopIndex: .res 1
DPCM_trackIndex: .res 1
DPCM_rest: .res 1

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
	sty SQ1_envelopeIndex
	sty SQ1_envelopeRest
	sty SQ2_loopIndex
	sty SQ2_trackIndex
	sty SQ2_length
	sty SQ2_rest
	sty Tri_loopIndex
	sty Tri_trackIndex
	sty Tri_length
	sty Tri_rest
	sty DPCM_loopIndex
	sty DPCM_trackIndex
	sty DPCM_rest
;get sq1 track
	ldx #00
	ldy #00
	lda tracks_L,x
	sta SQ1_trackPointer
	lda tracks_H,x
	sta SQ1_trackPointer+1
	lda (SQ1_trackPointer),y;get loop
	tax
	lda loops_L,x
	sta SQ1_loopPointer
	lda loops_H,x
	sta SQ1_loopPointer+1
	iny
	lda (SQ1_trackPointer),y;get instrument
	tax
	lda instCtrl,x
	sta SQ1_ctrl
	lda instSweep,x
	sta SQ1_sweep
	lda instEnvelope_L,x
	sta SQ1_envelopePtr
	lda instEnvelope_H,x
	sta SQ1_envelopePtr+1
	iny
	lda (SQ1_trackPointer),y;get volume
	sta SQ1_loopVolume
	sta SQ1_envelopeVolume
	iny
	sty SQ1_trackIndex

	rts
;get sq2 track
	ldx #1;track 1
	ldy #0;beginning of track
	lda tracks_L,x;save track pointer
	sta SQ2_trackPointer
	lda tracks_H,x
	sta SQ2_trackPointer+1
	lda (SQ2_trackPointer),y;get inst
	tax
	lda instCtrl,x
	sta SQ2_ctrl
	lda instSweep,x
	sta SQ2_sweep
	iny
	lda (SQ2_trackPointer),y;get loop
	iny
	sty SQ2_trackIndex;save index first
	tay
	lda loops_L,y;save loop pointer
	sta SQ2_loopPointer
	lda loops_H,y
	sta SQ2_loopPointer+1
;triange setup
	ldx #2;track 2
	ldy #0;beginning of track
	lda tracks_L,x;save track pointer
	sta Tri_trackPointer
	lda tracks_H,x
	sta Tri_trackPointer+1
	lda (Tri_trackPointer),y;get loop
	iny
	sty Tri_trackIndex;save index first
	tay
	lda loops_L,y;save loop pointer
	sta Tri_loopPointer
	lda loops_H,y
	sta Tri_loopPointer+1
;DPCM setup  
	ldx #3;track 2
	ldy #0;beginning of track
	lda tracks_L,x;save track pointer
	sta DPCM_trackPointer
	lda tracks_H,x
	sta DPCM_trackPointer+1
	lda (DPCM_trackPointer),y;get loop
	iny
	sty DPCM_trackIndex;save index first
	tay
	lda loops_L,y;save loop pointer
	sta DPCM_loopPointer
	lda loops_H,y
	sta DPCM_loopPointer+1
	rts

APU_advance:
@updateS1:
	lda SQ1_length
	beq @SQ1_checkRest;the note has stopped playing
		lda SQ1_envelopeRest
		bne @SQ1_envelopeIsResting;envelope doesnt need update
			ldy SQ1_envelopeIndex
			clc
			lda (SQ1_envelopePtr),y;adjust envelope volume
			adc SQ1_envelopeVolume
			bpl @SQ1positive
				lda #0;Clamp at lower range 0
				jmp @withinRange
		@SQ1positive:
			cmp #15;clamp at higher range 15
			bcc @withinRange
				lda #15
		@withinRange:
			sta SQ1_envelopeVolume;save the persistent volume
			ora SQ1_ctrl
			sta SQ1_VOL;load it in
			iny
			lda (SQ1_envelopePtr),y;frames til envelope update
			sta SQ1_envelopeRest
			iny
			sty SQ1_envelopeIndex;save envelope index
	@SQ1_envelopeIsResting:
		dec SQ1_envelopeRest
		dec SQ1_length
		jmp @updateS2
@SQ1_checkRest:
	lda SQ1_rest
	beq @newNote
		;silence channel
		lda #%10110000
		sta SQ1_VOL 
		dec SQ1_rest
		jmp @updateS2
@newNote:
	ldy SQ1_loopIndex
	lda (SQ1_loopPointer),y
	bne @loopContinues
		ldy SQ1_trackIndex
		lda (SQ1_trackPointer),y;get loop
		bne @sq1TrackContinues;null terminated
			ldy #0	
			lda (SQ1_trackPointer),y;start over
	@sq1TrackContinues:
		tax
		lda loops_L,x
		sta SQ1_loopPointer
		lda loops_H,x
		sta SQ1_loopPointer+1
		iny
		lda (SQ1_trackPointer),y;get instrument
		tax
		lda instCtrl,x
		sta SQ1_ctrl
		lda instSweep,x	
		sta SQ1_sweep
		lda instEnvelope_L,x
		sta SQ1_envelopePtr
		lda instEnvelope_H,x
		sta SQ1_envelopePtr+1
		iny
		lda (SQ1_trackPointer),y;get the volume
		sta SQ1_loopVolume;this is starting vol for notes
		sta SQ1_envelopeVolume;inst envelope changing vol
		iny
		sty SQ1_trackIndex;save the pos in track
		ldy #0;reset index of loop
		lda (SQ1_loopPointer),y;get the first note
@loopContinues:
	tax;play a note
	lda SQ1_loopVolume
	sta SQ1_envelopeVolume
	ora SQ1_ctrl
	sta SQ1_VOL
	lda SQ1_sweep
	sta SQ1_SWEEP
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
	iny;advance loop
	sty SQ1_loopIndex
	lda #0
	sta SQ1_envelopeIndex
	sta SQ1_envelopeRest
@updateS2:
	rts
	lda SQ2_length
	bne @SQ2stillPlaying
		lda SQ2_rest
		bne @SQ2stillResting
			ldy SQ2_loopIndex
			lda (SQ2_loopPointer),y
			bne @SQ2loopContinues;terminate with null
				ldy SQ2_trackIndex
				lda (SQ2_trackPointer),y;get instrument
				bne @sq2TrackContinues;null terminated
					ldy #0	
					lda (SQ2_trackPointer),y;start over
			@sq2TrackContinues:
				tax
				lda instCtrl,x
				sta SQ2_ctrl
				lda instSweep,x;get the sweep
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
			lda SQ2_ctrl
			sta SQ2_VOL
			lda SQ2_sweep
			sta SQ2_SWEEP
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
@updateTri:
	lda Tri_length
	bne @triStillPlaying
		lda Tri_rest
		bne @triStillResting
			ldy Tri_loopIndex
			lda (Tri_loopPointer),y
			bne @triLoopContinues;null terminate
				ldy Tri_trackIndex;get new loop
				lda (Tri_trackPointer),y;get the loop
				bne @triTrackContinues
					ldy #0	
					lda (Tri_trackPointer),y;start over
			@triTrackContinues:
				iny
				sty Tri_trackIndex;save the pos in track
				tay
				lda loops_L,y
				sta Tri_loopPointer
				lda loops_H,y
				sta Tri_loopPointer+1
				ldy #0;reset index
				sty Tri_loopIndex
				lda (Tri_loopPointer),y;get the first note
		@triLoopContinues:
			tax;play a note
			lda periodTable_L,x
			sta TRI_LO
			lda periodTable_H,x
			sta TRI_HI
			iny
			lda (Tri_loopPointer),y;set length
			sta Tri_length
			dec Tri_length
			iny
			lda (Tri_loopPointer),y;set rest
			sta Tri_rest
			lda #$ff;plays infinitely
			sta TRI_LINEAR
			iny
			sty Tri_loopIndex;advance loop
			jmp @updateDPCM
@triStillPlaying:
	dec Tri_length
	jmp @updateDPCM
@triStillResting:
;silence channel
	lda #%10000000
	sta TRI_LINEAR
	dec Tri_rest
@updateDPCM:
	lda DPCM_rest
	bne @DPCMStillPlaying
		ldy DPCM_loopIndex
		lda (DPCM_loopPointer),y
		bne @DPCMLoopContinues
			ldy DPCM_trackIndex;get new loop
			lda (DPCM_trackPointer),y;get the loop
			bne @DPCMTrackContinues
				ldy #0	
				lda (DPCM_trackPointer),y;start over
		@DPCMTrackContinues:
			iny
			sty DPCM_trackIndex;save the pos in track
			tay
			lda loops_L,y
			sta DPCM_loopPointer
			lda loops_H,y
			sta DPCM_loopPointer+1
			ldy #0;reset index
			lda (DPCM_loopPointer),y;get the first sample
		@DPCMLoopContinues:
		tax
		lda Samples_address,x
		sta DMC_START 
		lda Samples_length,x
		sta DMC_LEN 
		lda #$f
		sta DMC_FREQ 
		iny
		lda (DPCM_loopPointer),y;get the rest
		sta DPCM_rest
		iny
		sty DPCM_loopIndex;save the index
		lda #%11111
		sta SND_CHN
@DPCMStillPlaying:
	dec DPCM_rest
	rts
.rodata	

TRACK00=$00;s1 sq1
TRACK01=$01;s1 sq2
TRACK02=$02;s1 tri
TRACK03=$03;s1 dpcm
tracks_H:
	.byte >track00, >track01, >track02, >track03
tracks_L:
	.byte <track00, <track01, <track02 ,<track03 

track00:;loop, instrument, volume
	.byte LOOP0A, INST00, 00 
	.byte LOOP01, INST00, 00 
	.byte LOOP0A, INST00, 00 
	.byte LOOP02, INST00, 00
	.byte LOOP0A, INST00, 00
	.byte LOOP01, INST00, 00 
	.byte LOOP0A, INST00, 00 
	.byte LOOP02, INST00, 00 
	.byte NULL
track01:
	.byte LOOP03, INST00,5  
	.byte LOOP04, INST00,5  
	.byte LOOP03, INST00,5  
	.byte LOOP05, INST00,5  
	.byte LOOP03, INST00,5  
	.byte LOOP04, INST00,5  
	.byte LOOP03, INST00,5  
	.byte LOOP05, INST00,5  
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
DUTY00=%00
DUTY01=%01
DUTY02=%10
DUTY03=%11
CONSTANT=%1
LOOP=%1
SWEEP_DISABLE=%0
SWEEP_ENABLE=%1
LENGTH_DISABLE=%0
INST00=$00
instCtrl:;ddlc vvvv
	.byte (DUTY02<<6)|%110000
instSweep:;eppp nsss
	.byte (SWEEP_DISABLE<<7)
instEnvelope_L:
	.byte <envelope00
instEnvelope_H:
	.byte >envelope00

envelope00:
	.byte 5, 1, 5, 1, 5, 1, 5, 1,1, 1,  <-3, 1,<-3 , 1,<-3 , 10
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
