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
tracks: .res MAX_TRACKS+1
trackIndex: .res MAX_TRACKS+1
trackPtr: .res 2
loops: .res MAX_TRACKS+1
loopIndex: .res MAX_TRACKS+1
loopPtr: .res 2

instrument: .res MAX_TRACKS
note:.res MAX_TRACKS+1
maxVolume: .res MAX_TRACKS
targetVolume: .res MAX_TRACKS
currentVolume_L: .res MAX_TRACKS
currentVolume_H: .res MAX_TRACKS

SFX_effect:.res MAX_TRACKS
SFX_loopPtr: .res 2
SFX_loopIndex: .res MAX_TRACKS
;locals
.data
length:.res MAX_TRACKS
rest:.res MAX_TRACKS+1
mute:.res MAX_TRACKS
state: .res MAX_TRACKS

SFX_length:.res MAX_TRACKS
SFX_rest:.res MAX_TRACKS
currentPeriod_L:.res MAX_TRACKS
currentPeriod_LL:.res MAX_TRACKS
targetPeriod:.res MAX_TRACKS

Music_savedInstrument:.res MAX_TRACKS
Music_savedVolume:.res MAX_TRACKS

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
	lda songsNoise,x
	sta tracks+3
	lda songsDPCM,x
	sta tracks+4

	ldx #3;4 tracks
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
	sta Music_savedInstrument,x
	iny
	lda (trackPtr),y;get new volume
	sta maxVolume,x
	sta Music_savedVolume,x
	iny
	sty trackIndex,x
	dex
	bpl @setupSquare

	ldx #4
@setupDMC:
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
	sty trackIndex,x
	
	lda #0
	ldy #MAX_TRACKS-1
@clearMem1:
	sta loopIndex,y
	sta rest,y
	sta length,y
	sta SFX_length,y
	sta SFX_rest,y
	sta SFX_effect,y
	dey
	bpl @clearMem1
	sta loopIndex+4
	sta rest+4
	rts

APU_advance:
	ldx #3
@squareLoop:
	lda length,x;see if note is still playing
	beq @checkRest
		dec length,x
		lda mute,x
		bne @next
		lda	#>(@next-1)
		pha
		lda	#<(@next-1)
		pha
		ldy state,x;attack,decay,sustain
		lda states_H,y
		pha
		lda states_L,y
		pha
		rts
@checkRest:
	lda rest,x
	beq @newNote
		dec rest,x
		lda mute,x
		bne @next
		jsr Note_release
		jmp @next	
@newNote:
	jsr getNewNote;(x)
@next:
	dex
	bpl @squareLoop
@updateSample:
	lda rest+4
	bne @return
		jmp getNewSample
@return:
	dec rest+4
	rts

SFX_advance:
	ldx #3
@loop:
	ldy SFX_effect,x;if sound effect
	beq @next
		lda SFX_instrument,y;set instrument
		sta instrument,x
		lda SFX_volume,y;set volume
		sta maxVolume,x
		lda SFX_length,x;if note is playing
		beq @checkRest
			dec SFX_length,x
			lda	#>(@next-1)
			pha
			lda	#<(@next-1)
			pha
			ldy state,x;attack,decay,sustain
			lda states_H,y
			pha
			lda states_L,y
			pha
			rts
	@checkRest:
		lda SFX_rest,x
		beq @newNote
			dec SFX_rest,x
			jsr Note_release
			jmp @next	
	@newNote:
		jsr SFX_getNewNote;(x)
@next:
	dex
	bpl @loop
	rts

states_H:
	.byte >(Note_attack-1), >(Note_decay-1), >(Note_sustain-1)
states_L:
	.byte <(Note_attack-1), <(Note_decay-1), <(Note_sustain-1)
;offsets each track is for the respective channel
CHANNEL_OFFSETS:
	.byte 0, 4, 8, 12

SFX_newEffect:;(a)
	tax;x is rom sound effect
	ldy SFX_targetTrack,x;y is track in ram
	sta SFX_effect,y
	sta mute,y;mute the music

	lda #0;zero out these variables
	sta SFX_length,y
	sta SFX_rest,y
	sta SFX_loopIndex,y
	sta state,y
	sta currentPeriod_LL,y

	rts

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
		sta Music_savedInstrument,x
		iny
		lda (trackPtr),y;get new volume
		sta maxVolume,x
		sta Music_savedVolume,x
		iny
		sty trackIndex,x;save place in song
	@getFirstNote:
		ldy loops,x;get the channel loop
		lda loops_L,y;setup pointer
		sta loopPtr
		lda loops_H,y
		sta loopPtr+1
		ldy #0;start at beginning of loop
		lda (loopPtr),y;get note
@loopContinues:
	pha;save note
	iny
	lda (loopPtr),y;get play duration
	sta length,x
	dec length,x;this frame counts
	iny
	lda (loopPtr),y;get rest duration
	sta rest,x
	iny
	sty loopIndex,x;save the index
	lda SFX_effect,x;poke sound effect
	sta mute,x;mute the channel for the duration of the note
	beq @playNote;if no sound effect, play note
		pla;discard note
		rts;don't play note
@playNote:
	pla
	sta note,x
	ldy note,x
	lda periodTable_H,y
	pha
	lda periodTable_L,y
	sta currentPeriod_L,x;save low byte of period for pitch
	pha
	lda #0
	sta state,x;note in attack state while we have 00
	ldy instrument,x;get the initial volume level
	lda instAttack_L,y
	sta currentVolume_L,x
	lda instAttack_H,y
	cmp maxVolume,x;attack may just be one frame
	bcc :+
		lda maxVolume,x;so don't overflow, clamp at channel vol
		inc state,x
	:sta currentVolume_H,x
	ora instDuty,y
	ldy CHANNEL_OFFSETS,x
	sta CHANNEL_VOL,y
	pla
	sta CHANNEL_LO,y
	pla
	sta CHANNEL_HI,y 
	rts

SFX_getNewNote:
	ldy SFX_effect,x;get the channel loop
	lda SFX_loops_L,y;setup pointer
	sta SFX_loopPtr
	lda SFX_loops_H,y
	sta SFX_loopPtr+1
	ldy SFX_loopIndex,x;get the index
	lda (SFX_loopPtr),y;get note
	bne @loopContinues;loops are null terminated
		lda Music_savedVolume,x
		sta maxVolume,x
		lda Music_savedInstrument,x
		sta instrument,x
		lda #FALSE
		sta SFX_effect,x
		rts
@loopContinues:
	sta note,x
	iny
	lda (SFX_loopPtr),y;get play duration
	sta SFX_length,x
	dec SFX_length,x;this frame counts
	iny
	lda (SFX_loopPtr),y;get rest duration
	sta SFX_rest,x
	iny
	sty SFX_loopIndex,x;save the index

	ldy note,x;get the period to play
	lda periodTable_H,y
	pha
	lda periodTable_L,y
	sta currentPeriod_L,x;save low byte of period for pitch
	pha
	lda #0
	sta currentPeriod_LL,x;clear low low byte of pitch
	sta state,x;note in attack state while we have 00
	ldy instrument,x;get the initial volume level
	lda instAttack_L,y
	sta currentVolume_L,x
	lda instAttack_H,y
	cmp maxVolume,x;attack may be instantaneous
	bcc :+
		lda maxVolume,x;so don't overflow, clamp at channel vol
		inc state,x
	:sta currentVolume_H,x
	ora instDuty,y
	ldy CHANNEL_OFFSETS,x
	sta CHANNEL_VOL,y
	pla
	sta CHANNEL_LO,y
	pla
	sta CHANNEL_HI,y 
	rts

getNewSample:
	ldy loops+4;get the channel loop
	lda loops_L,y;setup pointer
	sta loopPtr
	lda loops_H,y
	sta loopPtr+1
	ldy loopIndex+4;get the index
	lda (loopPtr),y;get note
	bne @loopContinues;loops are null terminated
		ldy tracks+4
		lda tracks_L,y
		sta trackPtr
		lda tracks_H,y
		sta trackPtr+1
		ldy trackIndex+4;get place in song
		lda (trackPtr),y;get new loop
		bne @trackContinues;tracks are null terminated
			ldy #0
			lda (trackPtr),y;get first loop
	@trackContinues:
		sta loops+4
		iny
		sty trackIndex+4;save place in song
		ldy loops+4;get the channel loop
		lda loops_L,y;setup pointer
		sta loopPtr
		lda loops_H,y
		sta loopPtr+1
		ldy #0;start at beginning of loop
		lda (loopPtr),y;get sample
@loopContinues:
	sta note+4
	iny
	lda (loopPtr),y;get rest duration
	sta rest+4
	dec rest+4;this note counts
	iny
	sty loopIndex+4;save the index
	ldy note+4
	lda #$f
	sta DMC_FREQ
	lda Samples_length,y
	sta DMC_LEN	
	lda Samples_address,y
	sta DMC_START
	lda #%11111
	sta SND_CHN
	rts	

Note_attack:
	ldy instrument,x
	clc
	lda currentVolume_L,x
	adc instAttack_L,y
	sta currentVolume_L,x
	lda currentVolume_H,x
	adc instAttack_H,y
	cmp maxVolume,x
	bcc :+
		lda maxVolume,x
		inc state,x
	:sta currentVolume_H,x
	ora instDuty,y
	pha 
	jsr Note_bend
	ldy CHANNEL_OFFSETS,x
	sta CHANNEL_LO,y
	pla
	sta CHANNEL_VOL,y
	rts

Note_decay:
	ldy instrument,x
	sec;find the target volume
	lda maxVolume,x
	sbc instSustain,y
	bcs :+
		sec;no target volume underflow
		lda #0
	:sta targetVolume,x
	lda currentVolume_H,x;move the volume toward target
	sbc instDecay,y
	bcs :+
		lda #0;no volume underflow
	:
	cmp targetVolume,x
	bcs :+
		lda targetVolume,x;dont undershoot target
		inc state,x
	:sta currentVolume_H,x
	ora instDuty,y
	pha
	jsr Note_bend
	ldy CHANNEL_OFFSETS,x
	sta CHANNEL_LO,y
	pla
	sta CHANNEL_VOL,y
	rts

Note_sustain:
	ldy instrument,x
	lda currentVolume_H,x
	ora instDuty,y
	pha 
	jsr Note_bend
	ldy CHANNEL_OFFSETS,x
	sta CHANNEL_LO,y
	pla
	sta CHANNEL_VOL,y
	rts

Note_release:
	ldy instrument,x
	sec
	lda currentVolume_L,x
	sbc instRelease_L,y;fade out the note a little every frame
	sta currentVolume_L,x
	lda currentVolume_H,x
	sbc instRelease_H,y
	bcs :+
		lda #0;dont let volume go negative
	:sta currentVolume_H,x
	ora instDuty,y
	pha 
	jsr Note_bend
	ldy CHANNEL_OFFSETS,x
	sta CHANNEL_LO,y
	pla
	sta CHANNEL_VOL,y
	rts

Note_bend:
	ldy instrument,x
	lda instBend,y
	bne @hasBend
		lda currentPeriod_L,x
		rts
@hasBend:
	pha ;
	tay
	lda Bend_flags,y
	ror;todo vibrato
	ror	
	bcc @bendDown

	clc ;calculate the target note
	lda note,x
	adc Bend_target,y
	tay ;convert to numerical period
	lda periodTable_L,y
	sta targetPeriod,x
	
	pla ;restore bend
	tay

	sec ;subtract the period change
	lda currentPeriod_LL,x
	sbc Bend_speed_L,y
	sta currentPeriod_LL,x
	lda currentPeriod_L,x
	sbc Bend_speed_H,y
	cmp targetPeriod,x
	bcs :+
		lda targetPeriod,x ;ensure we don't overshoot
	:sta currentPeriod_L,x
	rts
@bendDown:
	sec ;calculate the target note
	lda note,x
	sbc Bend_target,y
	tay ;convert to numerical period
	lda periodTable_L,y
	sta targetPeriod,x

	pla ;restore bend
	tay

	clc ;add the period change
	lda currentPeriod_LL,x
	adc Bend_speed_L,y
	sta currentPeriod_LL,x
	lda currentPeriod_L,x
	adc Bend_speed_H,y
	cmp targetPeriod,x
	bcc :+
		lda targetPeriod,x ;ensure we do not overshoot
	:sta currentPeriod_L,x
	rts

.rodata	
songsSQ1:
	.byte TRACK01
songsSQ2:
	.byte TRACK02
songsTri:
	.byte TRACK03
songsNoise:
	.byte TRACK05
songsDPCM:
	.byte TRACK04
TRACK01=$01;s1 sq1
TRACK02=$02;s1 sq2
TRACK03=$03;s1 tri
TRACK04=$04;s1 dpcm
TRACK05=$05;s1 noise
tracks_H:
	.byte NULL, >track01, >track02, >track03, >track04, >track05
tracks_L:
	.byte NULL, <track01, <track02, <track03, <track04, <track05 

track01:;loop, instrument, volume
	.byte LOOP10, INST04, 08
	.byte LOOP11, INST04, 08
	.byte LOOP10, INST04, 08
	.byte LOOP12, INST04, 08
	.byte LOOP13, INST04, 08
	.byte LOOP11, INST04, 07
	.byte LOOP10, INST04, 08
	.byte LOOP14, INST04, 07
;chorus
	.byte LOOP0A, INST00, 08
	.byte LOOP0B, INST01, 08
	.byte LOOP0C, INST00, 08
	.byte LOOP01, INST00, 08
	.byte LOOP0A, INST00, 08
	.byte LOOP0B, INST01, 08
	.byte LOOP0C, INST00, 08
	.byte LOOP02, INST00, 08
	.byte LOOP0A, INST00, 08
	.byte LOOP0B, INST01, 08
	.byte LOOP0C, INST00, 08
	.byte LOOP01, INST00, 08
	.byte LOOP0A, INST00, 08
	.byte LOOP0B, INST01, 08
	.byte LOOP0C, INST00, 08
	.byte LOOP02, INST00, 08
	.byte NULL
track02:
;verse
	.byte LOOP15, INST05, 08
	.byte LOOP16, INST04, 07
	.byte LOOP17, INST05, 08
	.byte LOOP18, INST04, 07
;chorus
	.byte LOOP03, INST00, 08
	.byte LOOP0D, INST01, 08
	.byte LOOP0E, INST00, 08
	.byte LOOP04, INST00, 08
	.byte LOOP03, INST00, 08
	.byte LOOP0D, INST01, 08
	.byte LOOP0E, INST00, 08
	.byte LOOP05, INST00, 08
	.byte LOOP03, INST00, 08
	.byte LOOP0D, INST01, 08
	.byte LOOP0E, INST00, 08
	.byte LOOP04, INST00, 08
	.byte LOOP03, INST00, 08
	.byte LOOP0D, INST01, 08
	.byte LOOP0E, INST00, 08
	.byte LOOP05, INST00, 08
	.byte NULL
track03:
	.byte LOOP19, INST02, 15
	.byte LOOP06, INST02, 15
	.byte LOOP07, INST02, 15
	.byte LOOP06, INST02, 15
	.byte LOOP08, INST02, 15
	.byte LOOP06, INST02, 15
	.byte LOOP07, INST02, 15
	.byte LOOP06, INST02, 15
	.byte LOOP08, INST02, 15
	.byte NULL
track04:
	.byte LOOP09, LOOP09, LOOP09, LOOP09
	.byte NULL
track05:
	.byte LOOP0F, INST03, 15
	.byte NULL
;LOOPS
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
LOOP0B=$0b;s1 sq1 chorus 1 bend up
LOOP0C=$0c;s1 sq1 chorus 1 continued
LOOP0D=$0d;s1 sq2 chorus 1 bend up
LOOP0E=$0e;s1 sq2 chorus 1 continued
LOOP0F=$0f;s1 high hats
LOOP10=$10;S1 verse vibrato high
LOOP11=$11;S1 verse lead 1
LOOP12=$12;S1 verse lead 2
LOOP13=$13;S1 verse vibrato lo
LOOP14=$14;S1 verse lead 3
LOOP15=$15;S1 verse rhythm guitar 1
LOOP16=$16;S1 verse rhythm guitar harmony
LOOP17=$17;S1 verse rhythm guitar 2
LOOP18=$18;S1 verse rhythm guitar dissonance
LOOP19=$19;S1 bass verse
LOOP1A=$1A;
LOOP1B=$1B;
LOOP1C=$1C;
LOOP1D=$1D;
LOOP1E=$1E;
LOOP1F=$1F;
loops_H:
	.byte NULL, >loop01, >loop02, >loop03, >loop04, >loop05, >loop06, >loop07, >loop08, >loop09, >loop0A, >loop0B, >loop0C ,>loop0D, >loop0E , >loop0F 
	.byte >loop10, >loop11, >loop12, >loop13, >loop14, >loop15, >loop16, >loop17, >loop18, >loop19, >loop1A, >loop1B, >loop1C, >loop1D, >loop1E, >loop1F
loops_L:
	.byte NULL, <loop01, <loop02, <loop03, <loop04, <loop05, <loop06, <loop07, <loop08, <loop09, <loop0A, <loop0B, <loop0C, <loop0D, <loop0E, <loop0F
	.byte <loop10, <loop11, <loop12, <loop13, <loop14, <loop15, <loop16, <loop17, <loop18, <loop19, <loop1A, <loop1B, <loop1C, <loop1D, <loop1E, <loop1F
	
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
	.byte D3,12, 6 
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
	.byte SAMPLE01, 6, SAMPLE01, 6
	.byte SAMPLE02, 12
	.byte NULL
loop0A:
	.byte B2, 12, 6 
	.byte NULL
loop0B:
	.byte Gb3, 12, 3
	.byte NULL
loop0C:
	.byte Gb3,12, 3, E3, 12, 6
	.byte D3,12, 3, Db3,12, 3
	.byte NULL
loop0D:
	.byte Db4,12, 3
	.byte NULL
loop0E:
	.byte Db4,12, 3, A3,12, 6
	.byte Gb3,12, 3, E3,12, 3
	.byte NULL
loop0F:
	.byte N00, 3, 9
	.byte NULL
loop10:
	.byte D4, 36, 24, A3, 9, 3 
	.byte NULL
loop11:
	.byte D4, 3, 3
	.byte D4, 6, 12, D4, 12,0
	.byte A3, 6, 6, D4, 6, 0
	.byte E4, 6, 0, Gb4, 6, 0
	.byte E4, 12, 6, D4, 6, 6
	.byte D4, 3, 3, D4, 6, 12
	.byte NULL
loop12:
	.byte A3, 3, 3
	.byte A3,6,12,A3,9,3,A3,6,6,G3,3,3,Gb3,6,6,E3,12,6
	.byte D3,9,3,E3,3,3,G3,6,12
	.byte NULL
loop13:
	.byte Gb3, 36,24, D3,9,3
	.byte NULL
loop14:
	.byte D4,3,3,D4,6,12,D4,9,3,D4,9,3,D4,3,3
	.byte A3,6,6,D4,12,6,Eb4,12,6,Eb4,12,6
	.byte NULL
loop15:
	.byte D1,9,3,D1,3,3,D1,3,3,D1,3,3,D1,3,3,D1,3,3,D1,3,3
	.byte E1,9,3,E1,3,3,E1,3,3,E1,3,3,E1,3,3,E1,3,3,E1,3,3
	.byte Gb1,9,3,Gb1,3,3,Gb1,3,3,Gb1,3,3,Gb1,3,3,Gb1,3,3,Gb1,3,3
	.byte G1,9,3,G1,3,3,G1,3,3,G1,3,3,G1,3,3,G1,3,3,G1,3,3
	.byte B1,9,3,B1,3,3,B1,3,3,B1,3,3,B1,3,3,B1,3,3,B1,3,3
	.byte G1,9,3,G1,3,3,G1,3,3,G1,3,3,G1,3,3,G1,3,3,G1,3,3
	.byte A1,9,3,A1,3,3,A1,3,3,A1,3,3,A1,3,3,A1,3,3,A1,3,3
	.byte E1,9,3,E1,3,3,E1,3,3,E1,3,3,E1,3,3,E1,3,3,E1,3,3
	.byte D1,9,3,D1,3,3,D1,3,3,D1,3,3,D1,3,3,D1,3,3,D1,3,3
	.byte E1,9,3,E1,3,3,E1,3,3,E1,3,3,E1,3,3,E1,3,3,E1,3,3
	.byte NULL
loop16:
	.byte Gb4,12,0,D4,6,6,Gb4,6,0,A4,6,0,D5,6,0,A4,12,6
	.byte NULL
loop17:
	.byte G1,3,3,G1,3,3,G1,3,3,G1,3,3,G1,3,3,G1,3,3
	.byte B1,9,3,B1,3,3,B1,3,3,B1,3,3,B1,3,3,B1,3,3,B1,3,3
	.byte G1,9,3,G1,3,3,G1,3,3,G1,3,3,G1,3,3,G1,3,3,G1,3,3
	.byte NULL
loop18:
	.byte A3,9,3,A3,9,3,A3,3,3,D3,6,6,A3,12,6,Bb3,12,6,Bb3,12,6
	.byte NULL
loop19:
	.byte D2,48,0,E2,48,0,Gb2,48,0,G2,48,0,B2,48,0,G2,48,0
	.byte A2,48,0,E2,48,0,D2,48,0,E2,48,0,Gb2,48,0,G2,48,0
	.byte B2,48,0,G2,48,0,A2,48,0,Bb2,48,0
	.byte NULL
loop1A:
loop1B:
loop1C:
loop1D:
loop1E:
loop1F:
DUTY00=%00110000
DUTY01=%01110000
DUTY02=%10110000
DUTY03=%11110000
NOISE=%00110000
TRI=%10000000
INST00=$00;s1 chorus lead guitar
INST01=$01;s1 chorus lead guitar bend up one half step 
INST02=$02;bass triangle
INST03=$03;high hat open
INST04=$04;verse lead
INST05=$05;verse rhythm guitar
INST06=$06;explosion 01
instDuty:;ddlc vvvv
	.byte DUTY02, DUTY02, TRI, NOISE, DUTY02, DUTY00, NOISE 
instAttack_H:
	.byte 8, 8, 15, 15, 15, 15, 8
instAttack_L:
	.byte 0, 0, 0, 0, 00, 00, 00
instDecay:
	.byte 5, 5, 0, 5, 1, 3, 2
instSustain:;volume minus number below
	.byte 3, 3, 0, 5, 3, 3, 2
instRelease_H:
	.byte 1, 1, 15, 0, 0, 1, 1
instRelease_L:
	.byte 0, 0, 0, 128, 64, 0, 0
instBend:
	.byte 00, 01, 0, 0, 0, 0, 2
SFX01= 01
SFX_instrument:
	.byte NULL, INST06
SFX_volume:
	.byte NULL, 09
SFX_targetTrack:
	.byte NULL, 03
SFX_loops_L:
	.byte NULL, <SFX_loop00
SFX_loops_H:
	.byte NULL, >SFX_loop00

SFX_loop00:
	.byte N0D, 6, 6, NULL

Bend_flags:;|uuuu uunv|
;n - negative chane  (going higher)
;v - vibrato (disregards nra)
	.byte NULL, %10, %00
Bend_speed_H:
	.byte NULL, 10, 00

Bend_speed_L:
	.byte NULL, 00, 64

Bend_target:;(half steps)
	.byte NULL, 01, 2
	
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
N0F=$51
N0E=$52
N0D=$53
N0C=$54
N0B=$55
N0A=$56
N09=$57
N08=$58
N07=$59
N06=$5a
N05=$5b
N04=$5c
N03=$5d
N02=$5e
N01=$5f
N00=$60
N1F=$61;
N1E=$62
N1D=$63
N1C=$64
N1B=$65
N1A=$66
N19=$67
N18=$68
N17=$69
N16=$6a
N15=$6b
N14=$6c
N13=$6d
N12=$6e
N11=$6f
N10=$70
periodTable_L:
  .byte NULL,$f1,$7f,$13,$ad,$4d,$f3,$9d,$4c,$00,$b8,$74,$34
  .byte $f8,$bf,$89,$56,$26,$f9,$ce,$a6,$80,$5c,$3a,$1a
  .byte $fb,$df,$c4,$ab,$93,$7c,$67,$52,$3f,$2d,$1c,$0c
  .byte $fd,$ef,$e1,$d5,$c9,$bd,$b3,$a9,$9f,$96,$8e,$86
  .byte $7e,$77,$70,$6a,$64,$5e,$59,$54,$4f,$4b,$46,$42
  .byte $3f,$3b,$38,$34,$31,$2f,$2c,$29,$27,$25,$23,$21
  .byte $1f,$1d,$1b,$1a,$18,$17,$15,$14,$0f,$0e,$0d,$0c
  .byte $0b,$0a,$09,$08,$07,$06,$05,$04,$03,$02,$01,$00
  .byte $8f,$8e,$8d,$8c,$8b,$8a,$89,$88,$87,$86,$85,$84
  .byte $83,$82,$81,$80
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
