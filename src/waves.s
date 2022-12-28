.include "lib.h"

.include "waves.h"

.include "enemies.h"
.include "scenes.h"
.include "bullets.h"
.include "palettes.h"

.zeropage
levelWavePointer: .res 2 ;points to the collection of waves for the level
wavePointer: .res 2 ;points to the current wave in use
waveIndex: .res 1 ;keeps track of current wave in the collection
enemyIndex: .res 1 ;keeps track of which enemy is next

.data
Waves_hold:.res 1; hold for x frames
Waves_isEmpty:.res 1


CONCURRENT=$FE ;signals that two enemies are to be dispensed this frame
SKIP=0
.code
Waves_new:;void(x)
;sets up the level's enemy wave system
;arguments
;x - current scene
;get the string index from the scene
	lda Scenes_waveString,x
	tax

	lda waveStrings_L,x
	sta levelWavePointer+0
	lda waveStrings_H,x
	sta levelWavePointer+1

	;start on 0th wave, 0th enemy
	lda #0
	sta waveIndex

	lda #1
	sta Waves_hold

	jmp Waves_next; c()


Waves_dispense:; void()

	lda Waves_isEmpty
	bne @return

	dec Waves_hold
	beq @dispenseEnemy

		rts

@dispenseEnemy:

	ldy enemyIndex; recall index

	lda (wavePointer),y; if null (to terminate) new wave
	bne @addAnother
		
		jmp Waves_next; c()

@addAnother:
		
	ldy enemyIndex; recall index
	iny
	sty enemyIndex	

	jsr Enemies_new; y(a) |
	tya
	tax
	
	bcc @enemiesFull
	ldy enemyIndex
	
		lda (wavePointer),y; get position on screen
	
		iny
		sty enemyIndex

		rol; get 2 MSBs isolated in bit 0 and 1
		rol
		rol
		pha
		and #%11
		tay; use as index

		pla; get 6 LSBs in 2-7
		ror
		and #%11111100
		pha
	
		lda @sides_H,y; jump to a side dependent function
		pha
		lda @sides_L,y
		pha

		rts; void(x) | x

@enemiesFull:

	iny
	iny
	sty enemyIndex

@setTime:
	
	ldy enemyIndex; recall index

	lda (wavePointer),y; if zero time, make immediate enemy
	beq @addAnother

	sta Waves_hold
	
	iny
	sty enemyIndex
	
@return:

	rts

@sides_L:
	.byte <(@top-1),<(@right-1),<(@bottom-1),<(@left-1)
@sides_H:
	.byte >(@top-1),>(@right-1),>(@bottom-1),>(@left-1)
@top:; void(a,x) | x,y
	pla
	sta enemyXH,x
	lda #0
	sta enemyYH,x
	jmp @setTime
@right:; void(a,x) | x,y
	pla
	sta enemyYH,x
	lda #0
	sta enemyXH,x
	jmp @setTime

@bottom:; void(a,x) | x,y
	pla
	sta enemyXH,x
	lda #255
	sta enemyYH,x
	jmp @setTime

@left:; void(a,x) | x,y
	pla
	sta enemyYH,x
	lda #0
	sta enemyXH,x
	jmp @setTime


Waves_next:; c()
;returns false if no more enemies

	ldy waveIndex; recall index
	lda (levelWavePointer),y; get next wave
	beq @noMoreEnemies

		iny
		sty waveIndex
	
		pha; save wave

		tax; get the pointer
		lda wavePointerL,x
		sta wavePointer
		lda wavePointerH,x
		sta wavePointer+1


		lda Wave_palette00,x
		tax
		ldy #5
		jsr setPalette; void(x,y)
	
		pla; restore the wave
		tax

		lda Wave_palette01,x
		tax
		ldy #6
		jsr setPalette; void(x,y)
	
		lda #0
		sta enemyIndex

		lda #FALSE
		sta Waves_isEmpty
		lda #1
		sta Waves_hold
		rts

@noMoreEnemies:

	lda #TRUE
	sta Waves_isEmpty
	rts; a


.rodata
;waves for each level as index to pointers
WAVESTRING00=0
waveStrings_H:
	.byte >waveString00
waveStrings_L:
	.byte <waveString00
waveString00:

	;.byte WAVE02
	;.byte WAVE03
	.byte WAVE01
	.byte NULL
;pointers to individual enemy waves (below)

WAVE01=$01; piper boss fight
WAVE02=$02; unused
WAVE03=$03; unused
WAVE04=$04; unused
WAVE05=$05; unused
WAVE06=$06; unused
WAVE07=$07; unused


TOP=%00
RIGHT=%01
BOTTOM=%10
LEFT=%11

Wave_palette00:
	.byte NULL,PALETTE08,PALETTE07,PALETTE07
Wave_palette01:
	.byte NULL,PALETTE09,PALETTE06,PALETTE0B
;individual enemy waves
;	.byte enemy, position, hold, etc, NULL

wave01:
	
	.byte ENEMY01, BOTTOM|31, 1
	.byte NULL

wave02:
	.byte ENEMY02, TOP|16, 064
	.byte ENEMY02, TOP|48, 128
	.byte ENEMY06, TOP|22, 064
	.byte ENEMY02, TOP|10, 064
	.byte ENEMY06, TOP|15, 064
	.byte ENEMY02, TOP|08, 064
	.byte ENEMY06, TOP|28, 064
	
	.byte ENEMY03, TOP|38, 73
	.byte ENEMY03, TOP|42, 75
	.byte ENEMY03, TOP|37, 77
	.byte ENEMY02, TOP|16, 01; fairy
	.byte ENEMY03, TOP|42, 75
	.byte ENEMY03, TOP|45, 77
	.byte ENEMY03, TOP|37, 73
	.byte ENEMY02, TOP|18, 01; fairy
	.byte ENEMY03, TOP|41, 71
	.byte ENEMY03, TOP|34, 77
	.byte ENEMY02, TOP|52, 01; fairy
	.byte ENEMY03, TOP|28, 71
	.byte ENEMY03, TOP|31, 61
	.byte ENEMY03, TOP|25, 57	
	.byte ENEMY03, TOP|29, 41	
	.byte ENEMY03, TOP|19, 35	
	.byte ENEMY03, TOP|23, 33	

	.byte NULL


wave03:
	.byte ENEMY03, TOP|26, 37	
	.byte ENEMY03, TOP|21, 31	
	.byte ENEMY03, TOP|29, 67
	.byte ENEMY05, TOP|56, 01; balloon
	.byte ENEMY03, TOP|23, 77	
	.byte ENEMY03, TOP|20, 75	
	.byte ENEMY03, TOP|25, 77
	.byte ENEMY03, TOP|31, 71	
	.byte ENEMY03, TOP|28, 73	
	.byte ENEMY03, TOP|35, 77
	.byte ENEMY03, TOP|33, 76
	.byte ENEMY03, TOP|41, 71
	.byte ENEMY03, TOP|36, 77
	.byte ENEMY03, TOP|39, 75
	.byte ENEMY03, TOP|43, 71
	.byte ENEMY04, TOP|08, 01; balloon
	.byte ENEMY03, TOP|41, 75
	.byte ENEMY03, TOP|43, 79
	.byte ENEMY03, TOP|38, 75
	.byte ENEMY03, TOP|41, 71
	.byte ENEMY03, TOP|33, 67
	.byte ENEMY03, TOP|35, 62
	.byte ENEMY03, TOP|45, 65
	.byte ENEMY03, TOP|39, 67
	.byte ENEMY03, TOP|43, 66
	.byte ENEMY03, TOP|45, 255
	.byte NULL

wave04:
wave05:
wave06:
wave07:


wavePointerH:
	.byte NULL,>wave01,>wave02,>wave03,>wave04,>wave05,>wave06,>wave07
wavePointerL:
	.byte NULL,<wave01,<wave02,<wave03,<wave04,<wave05,<wave06,<wave07
