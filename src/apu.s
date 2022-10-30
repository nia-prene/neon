.include "apu.h"

.include "lib.h"

.include "shots.h"

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
;locals
hasHiPeriodChanged:.res 1


MAX_TRACKS=4



trackIndex: .res MAX_TRACKS+1
loopIndex: .res MAX_TRACKS+1
SFX_loopIndex: .res MAX_TRACKS
;locals
.data
Song_isOn:.res 1
SFX_isOn: .res 1

note:.res MAX_TRACKS+1
instrument: .res MAX_TRACKS
tracks: .res MAX_TRACKS+1
loops: .res MAX_TRACKS+1
SFX_effect:.res MAX_TRACKS
SFX_priority: .res MAX_TRACKS
maxVolume: .res MAX_TRACKS
targetVolume: .res MAX_TRACKS
currentVolume_L: .res MAX_TRACKS
currentVolume_H: .res MAX_TRACKS

length:.res MAX_TRACKS
rest:.res MAX_TRACKS+1
mute:.res MAX_TRACKS
state: .res MAX_TRACKS
currentPeriod_H:.res MAX_TRACKS
currentPeriod_L:.res MAX_TRACKS
currentPeriod_LL:.res MAX_TRACKS
targetPeriod_H:.res MAX_TRACKS
targetPeriod_L:.res MAX_TRACKS

SFX_length:.res MAX_TRACKS
SFX_rest:.res MAX_TRACKS

Music_savedInstrument:.res MAX_TRACKS
Music_savedVolume:.res MAX_TRACKS
Music_repeatAt:.res MAX_TRACKS+1

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
  	
		lda #FALSE
		sta Song_isOn
        rts
@regs:
        .byte $30,$08,$00,$00
        .byte $30,$08,$00,$00
        .byte $80,$00,$00,$00
        .byte $30,$00,$00,$00
        .byte $00,$00,$00,$00
APU_setSong:;void(x)
	ldx #0;force load song 0

	lda songsSQ1,x
	sta tracks
	lda Songs_SQ1RepeatAt,x
	sta Music_repeatAt

	lda songsSQ2,x
	sta tracks+1
	lda Songs_SQ2RepeatAt,x
	sta Music_repeatAt+1

	lda songsTri,x
	sta tracks+2
	lda Songs_triRepeatAt,x
	sta Music_repeatAt+2

	lda songsNoise,x
	sta tracks+3
	lda Songs_noiseRepeatAt,x
	sta Music_repeatAt+3

	lda songsDPCM,x
	sta tracks+4
	lda Songs_DPCMRepeatAt,x
	sta Music_repeatAt+4

	ldx #3;4 tracks
@setupSquare:
	lda tracks,x
	tay
	lda tracks_L,y
	sta NMIptr0
	lda tracks_H,y
	sta NMIptr0+1
	ldy #0
	lda (NMIptr0),y
	sta loops,x
	iny
	lda (NMIptr0),y;get new instrument
	sta instrument,x
	sta Music_savedInstrument,x
	iny
	lda (NMIptr0),y;get new volume
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
	sta NMIptr0
	lda tracks_H,y
	sta NMIptr0+1
	ldy #0
	lda (NMIptr0),y
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
	lda #TRUE
	sta Song_isOn
	sta SFX_isOn
	rts

APU_pauseMusic:
	ldx #3
@channelLoop:
	lda SFX_effect,x
	bne @skipChannel
		ldy instrument,x
		lda instDuty,y
		ldy CHANNEL_OFFSETS,x
		sta CHANNEL_VOL,y
@skipChannel:
	dex
	bpl @channelLoop
	lda #FALSE
	sta Song_isOn
	rts

APU_resumeMusic:
	lda #TRUE
	sta Song_isOn
	rts

APU_pauseSFX:
	ldx #3
@channelLoop:
	ldy SFX_effect,x
	beq @skipChannel
		ldy SFX_instrument,x
		lda instDuty,y
		ldy CHANNEL_OFFSETS,x
		sta CHANNEL_VOL,y
@skipChannel:
	dex
	bpl @channelLoop
	lda #FALSE
	sta SFX_isOn
	rts

APU_resumeSFX:
	lda #TRUE
	sta SFX_isOn
	rts


Song_advance:
	lda Song_isOn
	beq @songIsPaused
	ldx #3
@squareLoop:
	lda length,x;see if note is still playing
	beq @checkRest
		dec length,x
		lda mute,x
		bne @next
		jsr APU_tickState
		jmp @next
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
@songIsPaused:
	rts


APU_tickState:

	ldy state,x;attack,decay,sustain
	lda states_L,y
	sta NMIptr0+0
	lda states_H,y
	sta NMIptr0+1
	jmp (NMIptr0)


SFX_advance:
	lda SFX_isOn
	beq @SFXPaused
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
			jsr APU_tickState
			jmp @next
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
@SFXPaused:
	rts

states_H:
	.byte >(Note_attack), >(Note_decay), >(Note_sustain)
states_L:
	.byte <(Note_attack), <(Note_decay), <(Note_sustain)
;offsets each track is for the respective channel
CHANNEL_OFFSETS:
	.byte 0, 4, 8, 12

SFX_newEffect:;(a)
	pha;save sfx
	tax;x is rom sound effect
	ldy SFX_targetTrack,x;y is track in ram
	lda SFX_Priority,x;get new sfx priority
	cmp SFX_priority,y;compare it to current sfx priority
	bcc @sfxOverrided
		sta SFX_priority,y
		pla
		sta SFX_effect,y
		sta mute,y;mute the music

		lda #0;zero out these variables
		sta SFX_length,y
		sta SFX_rest,y
		sta SFX_loopIndex,y
		sta state,y
		sta currentPeriod_LL,y
		rts
@sfxOverrided:
	pla
	rts


getNewNote:
	ldy loops,x;get the channel loop

	lda loops_L,y;setup pointer
	sta NMIptr0
	lda loops_H,y
	sta NMIptr0+1
	
	ldy loopIndex,x;get the index
	lda (NMIptr0),y;get note
	bne @loopContinues;loops are null terminated
		ldy tracks,x
		lda tracks_L,y
		sta NMIptr0
		lda tracks_H,y
		sta NMIptr0+1
		ldy trackIndex,x;get place in song
		lda (NMIptr0),y;get new loop
		bne @trackContinues;tracks are null terminated
			ldy Music_repeatAt,x
			lda (NMIptr0),y;get first loop
	@trackContinues:
		sta loops,x
		iny
		lda (NMIptr0),y;get new instrument
		sta instrument,x
		sta Music_savedInstrument,x
		iny
		lda (NMIptr0),y;get new volume
		sta maxVolume,x
		sta Music_savedVolume,x
		iny
		sty trackIndex,x;save place in song
	@getFirstNote:
		ldy loops,x;get the channel loop
		lda loops_L,y;setup pointer
		sta NMIptr0+0
		lda loops_H,y
		sta NMIptr0+1
		ldy #0;start at beginning of loop
		lda (NMIptr0),y;get note
@loopContinues:
	pha;save note
	iny
	lda (NMIptr0),y;get play duration
	sta length,x
	dec length,x;this frame counts
	iny
	lda (NMIptr0),y;get rest duration
	sta rest,x
	iny
	sty loopIndex,x;save the index

	lda SFX_effect,x;poke sound effect
	sta mute,x;mute the channel for the duration of the note
	beq @noSFX;if no sound effect, play note
		pla;discard note
		rts;don't play note
@noSFX:
	pla
	sta note,x

	lda #0
	sta state,x;note in attack state while we have 00
	sta currentPeriod_LL,x;clear low low byte of pitch

	ldy note,x
	lda periodTable_H,y
	sta currentPeriod_H,x;save hi byte of period for pitch
	lda periodTable_L,y
	sta currentPeriod_L,x;save low byte of period for pitch
	
	jsr Note_bend;bend the note

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
	
	lda currentPeriod_L,x;push for upload	
	sta CHANNEL_LO,y
	lda currentPeriod_H,x;push for upload	
	sta CHANNEL_HI,y 

	rts

SFX_getNewNote:
	lda #0
	sta currentPeriod_LL,x;clear low low byte of pitch
	sta currentVolume_L,x;clear low low byte of volume
	sta state,x;note in attack state while we have 00
	
	ldy SFX_effect,x;get the channel loop
	lda SFX_loops_L,y;setup pointer
	sta NMIptr0+0
	lda SFX_loops_H,y
	sta NMIptr0+1

	ldy SFX_loopIndex,x;get the index
	lda (NMIptr0),y;get note
	bne @loopContinues;loops are null terminated

		ldy SFX_instrument,x;silence channel
		lda instDuty,y
		ldy CHANNEL_OFFSETS,x
		sta CHANNEL_VOL,y

		lda Music_savedVolume,x
		sta maxVolume,x
		lda Music_savedInstrument,x
		sta instrument,x
		lda #FALSE
		sta SFX_effect,x
		sta SFX_priority,x
		rts

@loopContinues:
	sta note,x

	iny
	lda (NMIptr0),y;get play duration
	sta SFX_length,x
	dec SFX_length,x;this frame counts

	iny
	lda (NMIptr0),y;get rest duration
	sta SFX_rest,x

	iny
	sty SFX_loopIndex,x;save the index

	ldy note,x;get the period to play
	lda periodTable_H,y
	sta currentPeriod_H,x;save high byte of period for pitch
	lda periodTable_L,y
	sta currentPeriod_L,x;save low byte of period for pitch
	
	jsr Note_bend

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

	ldy CHANNEL_OFFSETS,x;translate track to register
	sta CHANNEL_VOL,y;store volume

	lda currentPeriod_H,x
	sta CHANNEL_HI,y;store fine period	
	lda currentPeriod_L,x
	sta CHANNEL_LO,y;store coarse period	

	rts

getNewSample:
	ldy loops+4;get the channel loop
	lda loops_L,y;setup pointer
	sta NMIptr0+0 
	lda loops_H,y
	sta NMIptr0+1
	ldy loopIndex+4;get the index
	lda (NMIptr0),y;get note
	bne @loopContinues;loops are null terminated
		ldy tracks+4
		lda tracks_L,y
		sta NMIptr0+0
		lda tracks_H,y
		sta NMIptr0+1
		ldy trackIndex+4;get place in song
		lda (NMIptr0),y;get new loop
		bne @trackContinues;tracks are null terminated
			ldy Music_repeatAt+4
			lda (NMIptr0),y;get first loop
	@trackContinues:
		sta loops+4
		iny
		sty trackIndex+4;save place in song
		ldy loops+4;get the channel loop
		lda loops_L,y;setup pointer
		sta NMIptr0+0 
		lda loops_H,y
		sta NMIptr0+1
		ldy #0;start at beginning of loop
		lda (NMIptr0),y;get sample
@loopContinues:
	sta note+4
	iny
	lda (NMIptr0),y;get rest duration
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
	jsr Note_bend

	ldy instrument,x

	clc
	lda currentVolume_L,x
	adc instAttack_L,y
	sta currentVolume_L,x

	lda currentVolume_H,x
	adc instAttack_H,y
	cmp maxVolume,x
	bcc :+
		inc state,x
		lda maxVolume,x
	:sta currentVolume_H,x
	ora instDuty,y

	ldy CHANNEL_OFFSETS,x
	sta CHANNEL_VOL,y

	lda currentPeriod_L,x
	sta CHANNEL_LO,y
	lda hasHiPeriodChanged
	beq @skipHiByte
		lda currentPeriod_H,x
		sta CHANNEL_HI,y
@skipHiByte:
	rts

Note_decay:
	jsr Note_bend

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

	ldy CHANNEL_OFFSETS,x
	sta CHANNEL_VOL,y

	lda currentPeriod_L,x
	sta CHANNEL_LO,y

	lda hasHiPeriodChanged
	beq @skipHiByte
		lda currentPeriod_H,x
		sta CHANNEL_HI,y
@skipHiByte:
	rts

Note_sustain:
	jsr Note_bend

	ldy instrument,x
	lda currentVolume_H,x
	ora instDuty,y
	
	ldy CHANNEL_OFFSETS,x
	sta CHANNEL_VOL,y

	lda currentPeriod_L,x
	sta CHANNEL_LO,y

	lda hasHiPeriodChanged
	beq @skipHiByte
		lda currentPeriod_H,x
		sta CHANNEL_HI,y
@skipHiByte:
	rts

Note_release:
	jsr Note_bend
	
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

	ldy CHANNEL_OFFSETS,x
	sta CHANNEL_VOL,y
	
	lda currentPeriod_L,x
	sta CHANNEL_LO,y

	lda hasHiPeriodChanged
	beq @skipHiByte
		lda currentPeriod_H,x
		sta CHANNEL_HI,y
@skipHiByte:
	rts

Note_bend:
	lda #FALSE
	sta hasHiPeriodChanged

	ldy instrument,x
	lda instBend,y
	bne @hasBend
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
	sta targetPeriod_L,x
	lda periodTable_H,y
	sta targetPeriod_H,x
	
	pla ;restore bend
	tay

	sec ;subtract the period change
	lda currentPeriod_LL,x
	sbc Bend_speed_L,y
	sta currentPeriod_LL,x

	lda currentPeriod_L,x
	sbc Bend_speed_H,y
	sta currentPeriod_L,x
	bcs @noChange
		lda currentPeriod_H,x
		sbc #0
		sta currentPeriod_H,x
		lda #1
		sta hasHiPeriodChanged
@noChange:
	lda currentPeriod_L,x;if the current period is lower
	cmp targetPeriod_L,x;this will clear the carry
	lda currentPeriod_H,x;and will leave the carry clear
	sbc targetPeriod_H,x;if the note high byte is lesser or equal
	bcs @notUnderTarget
		lda targetPeriod_H,x
		sta currentPeriod_H,x 
		lda targetPeriod_L,x
		sta currentPeriod_L,x 
@notUnderTarget:
	lda currentPeriod_L,x
	rts

@bendDown:
	sec ;calculate the target note
	lda note,x
	sbc Bend_target,y

	tay ;convert to numerical period
	lda periodTable_L,y
	sta targetPeriod_L,x
	lda periodTable_H,y
	sta targetPeriod_H,x

	pla ;restore bend
	tay

	clc ;add the period change
	lda currentPeriod_LL,x
	adc Bend_speed_L,y
	sta currentPeriod_LL,x

	lda currentPeriod_L,x
	adc Bend_speed_H,y
	sta currentPeriod_L,x
	bcc @highUnchanged

		lda currentPeriod_H,x
		adc #0
		sta currentPeriod_H,x
		lda #1
		sta hasHiPeriodChanged

@highUnchanged:	
	lda currentPeriod_L,x;if the current period is higher
	cmp targetPeriod_L,x;this will set the carry
	lda currentPeriod_H,x;and will leave the carry set
	sbc targetPeriod_H,x;if current high byte is greater or equal
	bcc @notOverTarget
		lda targetPeriod_L,x; clamp the values
		sta currentPeriod_L,x 
		lda targetPeriod_H,x
		sta currentPeriod_H,x
@notOverTarget:
	lda currentPeriod_L,x
	rts

.rodata	
songsSQ1:
	.byte TRACK01
Songs_SQ1RepeatAt:
	.byte 6
songsSQ2:
	.byte TRACK02
Songs_SQ2RepeatAt:
	.byte 6
songsTri:
	.byte TRACK03
Songs_triRepeatAt:
	.byte 3
songsNoise:
	.byte TRACK05
Songs_noiseRepeatAt:
	.byte 0
songsDPCM:
	.byte TRACK04
Songs_DPCMRepeatAt:
	.byte 8

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
;intro
	.byte LOOP15, INST05, 08
	.byte LOOP1A, INST05, 08
;verse
	.byte LOOP10, INST04, 08
	.byte LOOP11, INST04, 08
	.byte LOOP10, INST04, 08
	.byte LOOP12, INST04, 08
	.byte LOOP13, INST04, 08
	.byte LOOP11, INST04, 07
	.byte LOOP10, INST04, 08
	.byte LOOP14, INST04, 07
;chorus
	.byte LOOP03, INST00, 08
	.byte LOOP0D, INST01, 07
	.byte LOOP0E, INST00, 08
	.byte LOOP04, INST00, 08
	.byte LOOP03, INST00, 08
	.byte LOOP0D, INST01, 07
	.byte LOOP0E, INST00, 08
	.byte LOOP05, INST00, 08
	.byte LOOP03, INST00, 08
	.byte LOOP0D, INST01, 07
	.byte LOOP0E, INST00, 08
	.byte LOOP04, INST00, 08
	.byte LOOP03, INST00, 08
	.byte LOOP0D, INST01, 07
	.byte LOOP0E, INST00, 08
	.byte LOOP05, INST00, 08
;bridge
	.byte LOOP1B, INST04, 08
	.byte LOOP1C, INST04, 08
	.byte LOOP1D, INST04, 08
	.byte LOOP1E, INST01, 07
	.byte LOOP1F, INST04, 08
	.byte LOOP1C, INST04, 08
	.byte LOOP1D, INST04, 08
	.byte LOOP1E, INST01, 07
	.byte LOOP1F, INST04, 08
	.byte LOOP1C, INST04, 08
	.byte LOOP20, INST04, 08
	.byte LOOP1C, INST04, 08
	.byte NULL
track02:
;intro
	.byte LOOP15, INST05, 08
	.byte LOOP1A, INST05, 08
;verse
	.byte LOOP15, INST05, 08
	.byte LOOP16, INST04, 07
	.byte LOOP17, INST05, 08
	.byte LOOP18, INST04, 07
;chorus
	.byte LOOP0A, INST00, 08
	.byte LOOP0B, INST01, 07
	.byte LOOP0C, INST00, 08
	.byte LOOP01, INST00, 08
	.byte LOOP0A, INST00, 08
	.byte LOOP0B, INST01, 07
	.byte LOOP0C, INST00, 08
	.byte LOOP02, INST00, 08
	.byte LOOP0A, INST00, 08
	.byte LOOP0B, INST01, 07
	.byte LOOP0C, INST00, 08
	.byte LOOP01, INST00, 08
	.byte LOOP0A, INST00, 08
	.byte LOOP0B, INST01, 07
	.byte LOOP0C, INST00, 08
	.byte LOOP02, INST00, 08
;bridge
	.byte LOOP21, INST05, 08
	.byte LOOP21, INST05, 08
	.byte LOOP22, INST05, 08
	.byte LOOP22, INST05, 08
	.byte LOOP23, INST05, 08
	.byte LOOP23, INST05, 08
	.byte LOOP23, INST05, 08
	.byte LOOP24, INST05, 08
	.byte LOOP21, INST05, 08
	.byte LOOP21, INST05, 08
	.byte LOOP22, INST05, 08
	.byte LOOP22, INST05, 08
	.byte LOOP25, INST04, 08
	.byte LOOP26, INST01, 07
	.byte LOOP27, INST04, 08
	.byte LOOP28, INST04, 08
	.byte LOOP29, INST04, 08
	.byte LOOP28, INST04, 08

	.byte NULL
track03:
;intro
	.byte LOOP19, INST02, 15
;verse
	.byte LOOP19, INST02, 15
;chorus
	.byte LOOP06, INST02, 15
	.byte LOOP07, INST02, 15
	.byte LOOP06, INST02, 15
	.byte LOOP08, INST02, 15
	.byte LOOP06, INST02, 15
	.byte LOOP07, INST02, 15
	.byte LOOP06, INST02, 15
	.byte LOOP08, INST02, 15
;bridge
	.byte LOOP2A, INST02, 15
	.byte LOOP2B, INST02, 15
	.byte LOOP2A, INST02, 15
	.byte LOOP2C, INST02, 15
	.byte LOOP2A, INST02, 15
	.byte LOOP2D, INST02, 15
	.byte LOOP2A, INST02, 15
	.byte NULL
track04:
;intro
	.byte LOOP09, LOOP2E, LOOP09, LOOP2E
	.byte LOOP09, LOOP2E, LOOP09, LOOP2E
;verse
	.byte LOOP09, LOOP2E, LOOP09, LOOP2E
	.byte LOOP09, LOOP2E, LOOP09, LOOP2E
;chorus
	.byte LOOP09, LOOP2E, LOOP09, LOOP2E
	.byte LOOP09, LOOP2E, LOOP09, LOOP2E
;bridge
	.byte LOOP09, LOOP2E, LOOP09, LOOP2E
	.byte LOOP09, LOOP2E, LOOP2F
	.byte LOOP09, LOOP2E, LOOP09, LOOP2E
	.byte LOOP09, LOOP2E
	.byte NULL
track05:
;intro
	.byte LOOP0F, INST03, 15
	.byte LOOP0F, INST03, 15
	.byte LOOP0F, INST03, 15
	.byte LOOP0F, INST03, 15
;verse
	.byte LOOP0F, INST03, 15
	.byte LOOP0F, INST03, 15
	.byte LOOP0F, INST03, 15
	.byte LOOP0F, INST03, 15;fill
;chorus
	.byte LOOP0F, INST03, 15
	.byte LOOP0F, INST03, 15
	.byte LOOP0F, INST03, 15
	.byte LOOP0F, INST03, 15
;bridge
	.byte LOOP0F, INST03, 15
	.byte LOOP0F, INST03, 15
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
LOOP1A=$1A;S1 Intro pt 2
LOOP1B=$1B;S1 bridge lead lead-in
LOOP1C=$1C;S1 bridge reusable part
LOOP1D=$1D;S1 bridge lead into bend
LOOP1E=$1E;S1 bridge bend
LOOP1F=$1F;S1 bridge resolve after bend
LOOP20=$20;S1 bridge end
LOOP21=$21;S1 bridge rhythm guitar pt 1
LOOP22=$22;S1 bridge rhythm guitar pt 2
LOOP23=$23;S1 bridge rhythm guitar pt 3
LOOP24=$24;S1 bridge rhythm guitar pt 4
LOOP25=$25;S1 bridge harmony build to bend
LOOP26=$26;S1 bridge harmony bend
LOOP27=$27;S1 bridge harmony resolution after bend
LOOP28=$28;S1 bridge harmony reusable part
LOOP29=$29;S1 bridge harmony end
LOOP2A=$2A;S1 bridge bass reusable part
LOOP2B=$2B;S1 bridge bass bridge pt 2
LOOP2C=$2C;S1 bridge bass pause
LOOP2D=$2D;S1 bridge bass that high note
LOOP2E=$2E;simple fill kick snare
LOOP2F=$2F;fill for bridge build up
loops_H:
	.byte NULL, >loop01, >loop02, >loop03, >loop04, >loop05, >loop06, >loop07, >loop08, >loop09, >loop0A, >loop0B, >loop0C ,>loop0D, >loop0E , >loop0F 
	.byte >loop10, >loop11, >loop12, >loop13, >loop14, >loop15, >loop16, >loop17, >loop18, >loop19, >loop1A, >loop1B, >loop1C, >loop1D, >loop1E, >loop1F
	.byte >loop20, >loop21, >loop22, >loop23, >loop24, >loop25, >loop26, >loop27, >loop28, >loop29, >loop2A, >loop2B, >loop2C, >loop2D, >loop2E, >loop2F
loops_L:
	.byte NULL, <loop01, <loop02, <loop03, <loop04, <loop05, <loop06, <loop07, <loop08, <loop09, <loop0A, <loop0B, <loop0C, <loop0D, <loop0E, <loop0F
	.byte <loop10, <loop11, <loop12, <loop13, <loop14, <loop15, <loop16, <loop17, <loop18, <loop19, <loop1A, <loop1B, <loop1C, <loop1D, <loop1E, <loop1F
	.byte <loop20, <loop21, <loop22, <loop23, <loop24, <loop25, <loop26, <loop27, <loop28, <loop29, <loop2A, <loop2B, <loop2C, <loop2D, <loop2E, <loop2F
	
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
	.byte N00, 3, 9,N00, 3, 9,N00, 3, 9,N00, 3, 9
	.byte N00, 3, 9,N00, 3, 9,N00, 3, 9,N00, 3, 9
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
	.byte Gb1,9,3,Gb1,3,3,Gb1,3,3,Gb1,3,3,Gb1,3,3,Gb1,3,3,Gb1,3,3
	.byte G1,9,3,G1,3,3,G1,3,3,G1,3,3,G1,3,3,G1,3,3,G1,3,3
	.byte B1,9,3,B1,3,3,B1,3,3,B1,3,3,B1,3,3,B1,3,3,B1,3,3
	.byte G1,9,3,G1,3,3,G1,3,3,G1,3,3,G1,3,3,G1,3,3,G1,3,3
	.byte A1,9,3,A1,3,3,A1,3,3,A1,3,3,A1,3,3,A1,3,3,A1,3,3
	.byte Bb1,9,3,Bb1,3,3,Bb1,3,3,Bb1,3,3,Bb1,3,3,Bb1,3,3,Bb1,3,3
	.byte NULL
loop1B:
	.byte B2,12,6,G2,12,6
	.byte NULL
loop1C:
	.byte G2,6,6,G3,3,3,Gb3,12,6,E3,6,6,D3,6,6,Db3,12,6
	.byte A2,12,6,A2,6,6,B2,12,12,Db3,12,12
	.byte NULL
loop1D:
	.byte D3,24,12,Db3,3,3,D3,3,3,E3,24,12
	.byte D3,3,3,E3,3,3,Gb3,12,6,D3,9,3,D3,9,9
	.byte NULL
loop1E:
	.byte Db4,12,6
	.byte NULL
loop1F:
	.byte Db4,12,6,A3,6,6,B3,30,6
	.byte NULL
loop20:
	.byte D3,12,6,A2,12,6,A2,6,6,G3,3,3,Gb3,12,6
	.byte E3,6,6,D3,6,6,A3,12,6,E3,12,6,Db3,6,6,D3,12,12
	.byte E3,12,12,G3,12,6,G2,12,6	
	.byte NULL
loop21:
	.byte G1,9,3,G1,3,3,G1,3,3,G1,3,3,G1,3,3,G1,3,3,G1,3,3
	.byte NULL
loop22:
	.byte A1,9,3,A1,3,3,A1,3,3,A1,3,3,A1,3,3,A1,3,3,A1,3,3
	.byte NULL
loop23:
	.byte B1,9,3,B1,3,3,B1,3,3,B1,3,3,B1,3,3,B1,3,3,B1,3,3
	.byte NULL
loop24:
	.byte B1,9,3,B1,3,3,B1,3,3,A1,3,3,A1,3,3,A1,3,3,A1,3,3
	.byte NULL
loop25:
	.byte Gb3,24,12,E3,3,3,Gb3,3,3,G3,24,12,Gb3,3,3
	.byte G3,3,3,A3,12,6,Gb3,9,3,Gb3,9,9
	.byte NULL
loop26:
	.byte F4,12,6
	.byte NULL
loop27:
	.byte E4,12,6,Db4,6,6,D4,30,6
	.byte NULL
loop28:
	.byte B2,6,6,B3,3,3,A3,12,6,G3,6,6,Gb3,6,6,E3,12,6
	.byte Db3,12,6,Db3,6,6,D3,12,12,E3,12,12
	.byte NULL
loop29:
	.byte Gb3,12,6,Db3,12,6,Db3,6,6,B3,3,3,A3,12,6
	.byte A3,6,6,G3,6,6,D4,12,6,A3,12,6,E3,6,6
	.byte Gb3,12,12,G3,12,12,B3,12,6,B2,12,6
	.byte NULL
loop2A:
	.byte G2,45,3,G2,45,3,A2,45,3,A2,45,3
	.byte NULL
loop2B:
	.byte B2,45,3,B2,45,3,B2,45,3,B2,21,3,A2,21,3
	.byte NULL
loop2C:
	.byte B2,12,132,B2,21,3,A2,21,3
	.byte NULL
loop2D:
	.byte B2,45,3,B2,45,3,D3,45,3,D3,21,3,A2,21,3
	.byte NULL
loop2E:
	.byte SAMPLE01, 12, SAMPLE02, 12
	.byte SAMPLE01, 6, SAMPLE01, 6
	.byte SAMPLE02, 12
	.byte NULL
loop2F:
	.byte SAMPLE02,24,SAMPLE01,12,SAMPLE01,6,SAMPLE01,6
	.byte SAMPLE02,24,SAMPLE01,12,SAMPLE01,6,SAMPLE01,6
	.byte SAMPLE02,24,SAMPLE01,24,SAMPLE01,12,SAMPLE02,12
	.byte SAMPLE01,6,SAMPLE01,6,SAMPLE02,12
	.byte NULL

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
INST06=$06;explosion small craft
INST07=$07;player hit
INST08=$08;powerup
INST09=$09;player shots
INST0A=$0a;bomb bass
INST0B=$0b;bomb crash
INST0C=$0c;bomb twinkle
INST0D=$0d;charm woosh
instDuty:;ddlc vvvv
	.byte DUTY02,DUTY02,TRI,NOISE,DUTY02,DUTY00,NOISE,DUTY01
	.byte DUTY02,NOISE,DUTY02,NOISE,DUTY02,NOISE
instAttack_H:
	.byte 8, 8, 15, 15, 15, 15, 15, 4
	.byte 6, 15, 15, 15, 15, 6
instAttack_L:
	.byte 0, 0, 0, 0, 0, 0, 0 
	.byte 0, 0, 0, 0, 0, 0
instDecay:
	.byte 5, 4, 0, 5, 1, 3, 4, 2
	.byte 1, 8, 0, 2, 8, 0
instSustain:;volume minus number below
	.byte 3, 2, 0, 5, 3, 3, 4, 4
	.byte 1, 8, 0, 3, 15, 0
instRelease_H:
	.byte 1, 1, 15, 0, 0, 15, 0, 0
	.byte 0, 1, 0, 0, 15, 1
instRelease_L:
	.byte 0, 0, 0, 128, 64, 0, 128, 08
	.byte 64, 0, 0, 64, 0, 0
instBend:
	.byte 00, 01, 0, 0, 0, 0, 2, 3
	.byte 0, 0, 4, 5, 0, 6

Bend_flags:;|uuuu uunv|
;n - negative chane  (going higher)
;v - vibrato (disregards nra)
	.byte NULL, %10, %00, %00, %00, %10, %00
Bend_speed_H:
	.byte NULL, 06, 00, 00, 96, 0, 0

Bend_speed_L:
	.byte NULL, 128, 64, 16, 0,128,192

Bend_target:;(half steps)
	.byte NULL, 01, 4, 36, 24, 3, 14
	
SFX01=01;explosion small craft
SFX02=02;player fall
SFX03=03;Powerup melody
SFX04=04;Powerup harmony
SFX05=05;player shots
SFX06=06;bomb bass
SFX07=07;bomb crash
SFX08=08;bomb twinkle
SFX09=09;charm woosh
SFX_instrument:
	.byte NULL,INST06,INST07,INST08,INST08,INST03,INST0A,INST0B
	.byte INST0C,INST0D
;256 is high priority
SFX_Priority:
	.byte NULL, 128, 255, 128, 128, 32, 192, 192
	.byte 192, 192
SFX_volume:
	.byte NULL, 12, 08, 7, 7, 15, 15, 15
	.byte 8, 11
SFX_targetTrack:
	.byte NULL, 03, 01, 00, 01, 03, 01, 03
	.byte 00, 03
SFX_loops_L:
	.byte NULL,<SFX_loop01,<SFX_loop02,<SFX_loop03,<SFX_loop04,<SFX_loop05,<SFX_loop06,<SFX_loop07
	.byte <SFX_loop08,<SFX_loop09
SFX_loops_H:
	.byte NULL,>SFX_loop01,>SFX_loop02,>SFX_loop03,>SFX_loop04,>SFX_loop05,>SFX_loop06,>SFX_loop07
	.byte >SFX_loop08,>SFX_loop09

SFX_loop01:
	.byte N0B, 6, 9, NULL
SFX_loop02:
	.byte D5, 9, 128, NULL
SFX_loop03:
	.byte D4, 3, 0, Gb4, 3, 9, D5, 6, 12, A4, 6, 18, NULL
SFX_loop04:
	.byte Gb4, 3, 0, A4, 3, 9, Gb5, 6, 12, D5, 6, 18, NULL
SFX_loop05:
	.byte N00, 3, 12,NULL
SFX_loop06:
	.byte D3,3,0,D3,13,0,NULL
SFX_loop07:
	.byte N0E,03,0,N0E,03,64,NULL
SFX_loop08:
	.byte Gb6, 1, 0, A6, 1, 0, D7, 1, 0,Gb6, 1, 1, A6, 1, 1, D7, 1, 2, Gb6, 1, 3, A6, 1, 4, D7, 1, 0, NULL
SFX_loop09:
	.byte N00,24,0,NULL

KICK_ADDRESS= <(( DPCM_kick - $C000) >> 6)
KICK_LENGTH= ((DPCM_kickEnd - DPCM_kick) >> 4)
SNARE_ADDRESS= <(( DPCM_snare  - $C000) >> 6)
SNARE_LENGTH= ((DPCM_snareEnd - DPCM_snare) >> 4)

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
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00

.segment "DRUMS"
.align 64
DPCM_kick:
	.incbin "kick.dmc"
DPCM_kickEnd: 
.align 64
DPCM_snare:
	.incbin "snare.dmc"
DPCM_snareEnd:
